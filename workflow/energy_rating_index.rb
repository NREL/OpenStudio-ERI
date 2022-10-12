# frozen_string_literal: true

start_time = Time.now

args = ARGV.dup
ARGV.clear

require 'optparse'
require 'csv'
require 'pathname'
require 'fileutils'
require 'parallel'
require 'oga'
require_relative 'design.rb'
require_relative 'util.rb'
require_relative '../rulesets/main'
require_relative '../rulesets/resources/constants'
require_relative '../hpxml-measures/HPXMLtoOpenStudio/resources/constants'
require_relative '../hpxml-measures/HPXMLtoOpenStudio/resources/hpxml'
require_relative '../hpxml-measures/HPXMLtoOpenStudio/resources/version'
require_relative '../hpxml-measures/HPXMLtoOpenStudio/resources/xmlhelper'

basedir = File.expand_path(File.dirname(__FILE__))

def get_program_versions(hpxml_doc)
  eri_version = XMLHelper.get_value(hpxml_doc, '/HPXML/SoftwareInfo/extension/ERICalculation/Version', :string)
  if eri_version == 'latest'
    eri_version = Constants.ERIVersions[-1]
  end
  es_version = XMLHelper.get_value(hpxml_doc, '/HPXML/SoftwareInfo/extension/EnergyStarCalculation/Version', :string)
  iecc_version = XMLHelper.get_value(hpxml_doc, '/HPXML/SoftwareInfo/extension/IECCERICalculation/Version', :string)
  zerh_version = XMLHelper.get_value(hpxml_doc, '/HPXML/SoftwareInfo/extension/ZERHCalculation/Version', :string)

  { [Constants.ERIVersions, 'ERICalculation/Version'] => eri_version,
    [ESConstants.AllVersions, 'EnergyStarCalculation/Version'] => es_version,
    [IECCConstants.AllVersions, 'IECCERICalculation/Version'] => iecc_version,
    [ZERHConstants.Ver1, 'ZERHCalculation/Version'] => zerh_version }.each do |values, version|
    all_versions, xpath = values
    if (not version.nil?) && (not all_versions.include? version)
      puts "Unexpected #{xpath}: '#{version}'"
      exit!
    end
    if not version.nil?
      puts "#{xpath}: #{version}"
    else
      puts "#{xpath}: None"
    end
  end

  return eri_version, es_version, iecc_version, zerh_version
end

def apply_rulesets_and_generate_hpxmls(designs, options)
  puts "Generating #{designs.size} HPXMLs..."

  success, errors, warnings, duplicates, _ = run_rulesets(options[:hpxml], designs)

  # Report warnings/errors
  run_log = File.join(options[:output_dir], 'run.log')
  File.delete(run_log) if File.exist? run_log
  File.open(run_log, 'a') do |f|
    warnings.each do |s|
      f << "Warning: #{s}\n"
    end
    errors.each do |s|
      f << "Error: #{s}\n"
    end
  end

  if not success
    puts "HPXMLs not successfully generated. See #{run_log} for details."
    exit!
  end

  return duplicates
end

def run_simulations(designs, options, duplicates)
  # Down-select to unique designs that need to be simulated
  unique_designs = designs.select { |d| !duplicates.keys.include?(d.hpxml_output_path) }

  puts "Running #{unique_designs.size} Simulations..."

  # Run simulations
  if Process.respond_to?(:fork) # e.g., most Unix systems

    # Code runs in forked child processes and makes direct calls. This is the fastest
    # approach but isn't available on, e.g., Windows.

    def kill
      raise Parallel::Kill
    end

    Parallel.map(unique_designs, in_processes: unique_designs.size) do |design|
      designdir = run_design_direct(design, options)
      kill unless File.exist? File.join(designdir, 'eplusout.end')
    end

  else # e.g., Windows

    # Fallback. Code runs in spawned child processes in order to take advantage of
    # multiple processors.

    def kill(pids)
      pids.values.each do |pid|
        begin
          Process.kill('KILL', pid)
        rescue
        end
      end
    end

    pids = {}
    Parallel.map(unique_designs, in_threads: unique_designs.size) do |design|
      designdir, pids[design] = run_design_spawn(design, options)
      Process.wait pids[design]

      if not File.exist? File.join(designdir, 'eplusout.end')
        kill(pids)
        next
      end
    end

  end
end

def duplicate_output_files(duplicates, designs, resultsdir)
  duplicates.each do |dest_hpxml_path, source_hpxml_path|
    source_design = designs.select { |d| d.hpxml_output_path == source_hpxml_path }[0]
    dest_design = designs.select { |d| d.hpxml_output_path == dest_hpxml_path }[0]

    # Duplicate E+ output directory
    FileUtils.cp_r(source_design.design_dir, dest_design.design_dir)

    # Duplicate results files
    source_filename = File.basename(source_design.hpxml_output_path, '.xml')
    dest_filename = File.basename(dest_design.hpxml_output_path, '.xml')
    Dir["#{resultsdir}/*.*"].each do |results_file|
      next unless File.basename(results_file).start_with? source_filename

      FileUtils.cp(results_file, results_file.gsub(source_filename, dest_filename))
    end
  end
end

def run_design_direct(design, options)
  # Calls design.rb methods directly. Should only be called from a forked
  # process. This is the fastest approach.
  run_design(design, options[:debug], options[:timeseries_output_freq], options[:timeseries_outputs],
             options[:add_comp_loads])

  return design.design_dir
end

def run_design_spawn(design, options)
  # Calls design.rb in a new spawned process in order to utilize multiple
  # processes. Not as efficient as calling design.rb methods directly in
  # forked processes for a couple reasons:
  # 1. There is overhead to using the CLI
  # 2. There is overhead to spawning processes vs using forked processes
  cli_path = OpenStudio.getOpenStudioCLI
  command = "\"#{cli_path}\" "
  command += "\"#{File.join(File.dirname(__FILE__), 'design.rb')}\" "
  command += "\"#{design.calc_type}\" "
  command += "\"#{design.init_calc_type}\" "
  command += "\"#{design.iecc_version}\" "
  command += "\"#{design.output_dir}\" "
  command += "\"#{options[:debug]}\" "
  command += "\"#{options[:timeseries_output_freq]}\" "
  command += "\"#{options[:timeseries_outputs].join('|')}\" "
  command += "\"#{options[:add_comp_loads]}\" "
  pid = Process.spawn(command)

  return design.design_dir, pid
end

def retrieve_eri_outputs(designs)
  # Retrieve outputs for ERI calculations
  design_outputs = {}
  designs.each do |design|
    csv_path = design.csv_output_path

    if not File.exist? csv_path
      puts 'Errors encountered. Aborting...'
      exit!
    end

    calc_type = design.calc_type

    design_outputs[calc_type] = {}

    CSV.foreach(csv_path) do |row|
      next if row.nil? || (row.size < 2) || row[1].nil?

      if row[1].include? ',' # Array of values
        begin
          design_outputs[calc_type][row[0]] = row[1].split(',').map { |v| Float(v) }
        rescue
          design_outputs[calc_type][row[0]] = row[1].split(',')
        end
      else # Single value
        begin
          design_outputs[calc_type][row[0]] = Float(row[1])
        rescue
          design_outputs[calc_type][row[0]] = row[1]
        end
        if (row[0].start_with? 'ERI:') && (not row[0].include? 'Building:')
          # Convert to array
          design_outputs[calc_type][row[0]] = [design_outputs[calc_type][row[0]]]
        end
      end
    end
  end
  return design_outputs
end

def _calculate_eri(rated_output, ref_output, results_iad: nil, opp_reduction_limit: nil)
  # opp_reduction_limit should be:
  #   - nil if a standard ERI calculation
  #   - zero if calculating the ENERGY STAR Rated Home ERI w/o OPP
  #   - non-zero if calculating the ENERGY STAR Rated Home ERI w OPP

  def get_heating_coefficients(fuel)
    if [HPXML::FuelTypeElectricity].include? fuel
      return 2.2561, 0.0
    elsif [HPXML::FuelTypeNaturalGas,
           HPXML::FuelTypeOil,
           HPXML::FuelTypePropane,
           HPXML::FuelTypeWoodCord,
           HPXML::FuelTypeWoodPellets].include? fuel
      return 1.0943, 0.4030
    end

    fail 'Could not identify EEC coefficients for heating system.'
  end

  def get_cooling_coefficients()
    return 3.8090, 0.0
  end

  def get_dhw_coefficients(fuel)
    if [HPXML::FuelTypeElectricity].include? fuel
      return 0.9200, 0.0
    elsif [HPXML::FuelTypeNaturalGas,
           HPXML::FuelTypeOil,
           HPXML::FuelTypePropane,
           HPXML::FuelTypeWoodCord,
           HPXML::FuelTypeWoodPellets].include? fuel
      return 1.1877, 1.0130
    end

    fail 'Could not identify EEC coefficients for water heating system.'
  end

  results = {}

  # ======== #
  # Building #
  # ======== #
  results[:rated_cfa] = rated_output['ERI: Building: CFA']
  results[:rated_nbr] = rated_output['ERI: Building: NumBedrooms']
  results[:rated_nst] = rated_output['ERI: Building: NumStories']
  results[:rated_facility_type] = rated_output['ERI: Building: Type']

  # =========================== #
  # Ventilation Preconditioning #
  # =========================== #

  # Calculate independent nMEUL for ventilation preconditioning

  reul_precond = 1.0 # Arbitrary; doesn't affect results

  results[:nmeul_vent_preheat] = []
  if not rated_output['ERI: Mech Vent Preheating: ID'].nil?
    for rated_idx in 0..rated_output['ERI: Mech Vent Preheating: ID'].size - 1
      ec_x_preheat = rated_output['ERI: Mech Vent Preheating: EC'][rated_idx]
      coeff_preheat_a, coeff_preheat_b = get_heating_coefficients(rated_output['ERI: Mech Vent Preheating: FuelType'][rated_idx])
      eec_x_preheat = rated_output['ERI: Mech Vent Preheating: EEC'][rated_idx]
      dse_r_preheat = 0.80 # DSE of Reference Home for space heating
      ec_r_preheat = reul_precond / eec_x_preheat / dse_r_preheat
      nEC_x_preheat = (coeff_preheat_a * eec_x_preheat - coeff_preheat_b) * (ec_x_preheat * ec_r_preheat * dse_r_preheat) / (eec_x_preheat * reul_precond)
      results[:nmeul_vent_preheat] << reul_precond * (nEC_x_preheat / ec_r_preheat)
    end
  end

  results[:nmeul_vent_precool] = []
  if not rated_output['ERI: Mech Vent Precooling: ID'].nil?
    for rated_idx in 0..rated_output['ERI: Mech Vent Precooling: ID'].size - 1
      ec_x_precool = rated_output['ERI: Mech Vent Precooling: EC'][rated_idx]
      coeff_precool_a, coeff_precool_b = get_cooling_coefficients()
      eec_x_precool = rated_output['ERI: Mech Vent Precooling: EEC'][rated_idx]
      dse_r_precool = 0.80 # DSE of Reference Home for space cooling
      ec_r_precool = reul_precond / eec_x_precool / dse_r_precool
      nEC_x_precool = (coeff_precool_a * eec_x_precool - coeff_precool_b) * (ec_x_precool * ec_r_precool * dse_r_precool) / (eec_x_precool * reul_precond)
      results[:nmeul_vent_precool] << reul_precond * (nEC_x_precool / ec_r_precool)
    end
  end

  # ======= #
  # Heating #
  # ======= #

  results[:reul_heat] = []
  results[:coeff_heat_a] = []
  results[:coeff_heat_b] = []
  results[:eec_x_heat] = []
  results[:eec_r_heat] = []
  results[:ec_x_heat] = []
  results[:ec_r_heat] = []
  results[:dse_r_heat] = []
  results[:nec_x_heat] = []
  results[:nmeul_heat] = []

  rated_output['ERI: Heating: ID'].each_with_index do |sys_id, rated_idx|
    ref_idx = ref_output['ERI: Heating: ID'].index(sys_id)
    reul_heat = ref_output['ERI: Heating: Load'][ref_idx]
    coeff_heat_a, coeff_heat_b = get_heating_coefficients(ref_output['ERI: Heating: FuelType'][ref_idx])
    eec_x_heat = rated_output['ERI: Heating: EEC'][rated_idx]
    eec_r_heat = ref_output['ERI: Heating: EEC'][ref_idx]
    ec_x_heat = rated_output['ERI: Heating: EC'][rated_idx]
    ec_r_heat = ref_output['ERI: Heating: EC'][ref_idx]
    dse_r_heat = reul_heat / ec_r_heat * eec_r_heat
    nec_x_heat = 0
    if eec_x_heat * reul_heat > 0
      nec_x_heat = (coeff_heat_a * eec_x_heat - coeff_heat_b) * (ec_x_heat * ec_r_heat * dse_r_heat) / (eec_x_heat * reul_heat)
    end
    nmeul_heat = 0
    if ec_r_heat > 0
      nmeul_heat = reul_heat * (nec_x_heat / ec_r_heat)
    end

    results[:reul_heat] << reul_heat
    results[:coeff_heat_a] << coeff_heat_a
    results[:coeff_heat_b] << coeff_heat_b
    results[:eec_x_heat] << eec_x_heat
    results[:eec_r_heat] << eec_r_heat
    results[:ec_x_heat] << ec_x_heat
    results[:ec_r_heat] << ec_r_heat
    results[:dse_r_heat] << dse_r_heat
    results[:nec_x_heat] << nec_x_heat
    results[:nmeul_heat] << nmeul_heat
  end

  # ======= #
  # Cooling #
  # ======= #

  results[:reul_cool] = []
  results[:coeff_cool_a] = []
  results[:coeff_cool_b] = []
  results[:eec_x_cool] = []
  results[:eec_r_cool] = []
  results[:ec_x_cool] = []
  results[:ec_r_cool] = []
  results[:dse_r_cool] = []
  results[:nec_x_cool] = []
  results[:nmeul_cool] = []

  tot_reul_cool = ref_output['ERI: Cooling: Load'].sum(0.0)
  rated_output['ERI: Cooling: ID'].each_with_index do |sys_id, rated_idx|
    ref_idx = ref_output['ERI: Cooling: ID'].index(sys_id)
    reul_cool = ref_output['ERI: Cooling: Load'][ref_idx]
    coeff_cool_a, coeff_cool_b = get_cooling_coefficients()
    eec_x_cool = rated_output['ERI: Cooling: EEC'][rated_idx]
    eec_r_cool = ref_output['ERI: Cooling: EEC'][ref_idx]
    ec_x_cool = rated_output['ERI: Cooling: EC'][rated_idx]
    ec_r_cool = ref_output['ERI: Cooling: EC'][ref_idx]
    dse_r_cool = reul_cool / ec_r_cool * eec_r_cool
    nec_x_cool = 0
    if eec_x_cool * reul_cool > 0
      nec_x_cool = (coeff_cool_a * eec_x_cool - coeff_cool_b) * (ec_x_cool * ec_r_cool * dse_r_cool) / (eec_x_cool * reul_cool)
      # Add whole-house fan energy to nec_x_cool per 301 (apportioned by load) and excluded from eul_la
      nec_x_cool += (rated_output['End Use: Electricity: Whole House Fan (MBtu)'] * reul_cool / tot_reul_cool)
    end
    nmeul_cool = 0
    if ec_r_cool > 0
      nmeul_cool = reul_cool * (nec_x_cool / ec_r_cool)
    end

    results[:reul_cool] << reul_cool
    results[:coeff_cool_a] << coeff_cool_a
    results[:coeff_cool_b] << coeff_cool_b
    results[:eec_x_cool] << eec_x_cool
    results[:eec_r_cool] << eec_r_cool
    results[:ec_x_cool] << ec_x_cool
    results[:ec_r_cool] << ec_r_cool
    results[:dse_r_cool] << dse_r_cool
    results[:nec_x_cool] << nec_x_cool
    results[:nmeul_cool] << nmeul_cool
  end

  # ======== #
  # HotWater #
  # ======== #

  results[:reul_dhw] = []
  results[:coeff_dhw_a] = []
  results[:coeff_dhw_b] = []
  results[:eec_x_dhw] = []
  results[:eec_r_dhw] = []
  results[:ec_x_dhw] = []
  results[:ec_r_dhw] = []
  results[:dse_r_dhw] = []
  results[:nec_x_dhw] = []
  results[:nmeul_dhw] = []

  # Used to accommodate multiple Reference Home water heaters if the Rated Home has multiple
  # water heaters. Now always just 1 Reference Home water heater.
  if ref_output['ERI: Hot Water: Load'].size != 1
    fail 'Unexpected Reference Home results; should only be 1 DHW system.'
  end

  rated_output['ERI: Hot Water: ID'].each_with_index do |_sys_id, rated_idx|
    # Apportion load/energy from single ref water heater to each rated water heater
    rated_dhw_frac_load_served = (rated_output['ERI: Hot Water: Load'][rated_idx] / rated_output['ERI: Hot Water: Load'].sum(0.0))

    reul_dhw = ref_output['ERI: Hot Water: Load'][0] * rated_dhw_frac_load_served
    coeff_dhw_a, coeff_dhw_b = get_dhw_coefficients(ref_output['ERI: Hot Water: FuelType'][0])
    eec_x_dhw = rated_output['ERI: Hot Water: EEC'][rated_idx]
    eec_r_dhw = ref_output['ERI: Hot Water: EEC'][0]
    ec_x_dhw = rated_output['ERI: Hot Water: EC'][rated_idx]
    ec_r_dhw = ref_output['ERI: Hot Water: EC'][0] * rated_dhw_frac_load_served
    dse_r_dhw = reul_dhw / ec_r_dhw * eec_r_dhw
    nec_x_dhw = 0
    if eec_x_dhw * reul_dhw > 0
      nec_x_dhw = (coeff_dhw_a * eec_x_dhw - coeff_dhw_b) * (ec_x_dhw * ec_r_dhw * dse_r_dhw) / (eec_x_dhw * reul_dhw)
    end
    nmeul_dhw = 0
    if ec_r_dhw > 0
      nmeul_dhw = reul_dhw * (nec_x_dhw / ec_r_dhw)
    end

    results[:reul_dhw] << reul_dhw
    results[:coeff_dhw_a] << coeff_dhw_a
    results[:coeff_dhw_b] << coeff_dhw_b
    results[:eec_x_dhw] << eec_x_dhw
    results[:eec_r_dhw] << eec_r_dhw
    results[:ec_x_dhw] << ec_x_dhw
    results[:ec_r_dhw] << ec_r_dhw
    results[:dse_r_dhw] << dse_r_dhw
    results[:nec_x_dhw] << nec_x_dhw
    results[:nmeul_dhw] << nmeul_dhw
  end

  # ===== #
  # Other #
  # ===== #

  # Total Energy Use
  # Fossil fuel site energy uses should be converted to equivalent electric energy use
  # in accordance with Equation 4.1-3. Note: Generator fuel consumption is included here.
  results[:teu] = rated_output['Fuel Use: Electricity: Total (MBtu)'] +
                  0.4 * (rated_output['Fuel Use: Natural Gas: Total (MBtu)'] +
                         rated_output['Fuel Use: Fuel Oil: Total (MBtu)'] +
                         rated_output['Fuel Use: Propane: Total (MBtu)'] +
                         rated_output['Fuel Use: Wood Cord: Total (MBtu)'] +
                         rated_output['Fuel Use: Wood Pellets: Total (MBtu)'])

  # On-Site Power Production
  # Electricity produced minus equivalent electric energy use calculated in accordance
  # with Equation 4.1-3 of any purchased fossil fuels used to produce the power.
  results[:opp] = -1 * (rated_output['End Use: Electricity: PV (MBtu)'] +
                        rated_output['End Use: Electricity: Generator (MBtu)']) -
                  0.4 * (rated_output['End Use: Natural Gas: Generator (MBtu)'] +
                         rated_output['End Use: Fuel Oil: Generator (MBtu)'] +
                         rated_output['End Use: Propane: Generator (MBtu)'] +
                         rated_output['End Use: Wood Cord: Generator (MBtu)'] +
                         rated_output['End Use: Wood Pellets: Generator (MBtu)'])

  results[:pefrac] = 1.0
  if results[:teu] > 0
    results[:pefrac] = (results[:teu] - results[:opp]) / results[:teu]
  end

  def calculate_la(output)
    return (output['End Use: Electricity: Lighting Interior (MBtu)'] +
            output['End Use: Electricity: Lighting Exterior (MBtu)'] +
            output['End Use: Electricity: Lighting Garage (MBtu)'] +
            output['End Use: Electricity: Refrigerator (MBtu)'] +
            output['End Use: Electricity: Dishwasher (MBtu)'] +
            output['End Use: Electricity: Clothes Washer (MBtu)'] +
            output['End Use: Electricity: Clothes Dryer (MBtu)'] +
            output['End Use: Electricity: Plug Loads (MBtu)'] +
            output['End Use: Electricity: Television (MBtu)'] +
            output['End Use: Electricity: Range/Oven (MBtu)'] +
            output['End Use: Electricity: Ceiling Fan (MBtu)'] +
            output['End Use: Electricity: Mech Vent (MBtu)'] +
            output['End Use: Natural Gas: Clothes Dryer (MBtu)'] +
            output['End Use: Natural Gas: Range/Oven (MBtu)'] +
            output['End Use: Fuel Oil: Clothes Dryer (MBtu)'] +
            output['End Use: Fuel Oil: Range/Oven (MBtu)'] +
            output['End Use: Propane: Clothes Dryer (MBtu)'] +
            output['End Use: Propane: Range/Oven (MBtu)'] +
            output['End Use: Wood Cord: Clothes Dryer (MBtu)'] +
            output['End Use: Wood Cord: Range/Oven (MBtu)'] +
            output['End Use: Wood Pellets: Clothes Dryer (MBtu)'] +
            output['End Use: Wood Pellets: Range/Oven (MBtu)'])
  end

  results[:eul_dh] = rated_output['End Use: Electricity: Dehumidifier (MBtu)']
  results[:eul_la] = calculate_la(rated_output)

  results[:reul_dh] = ref_output['End Use: Electricity: Dehumidifier (MBtu)']
  results[:reul_la] = calculate_la(ref_output)

  # === #
  # ERI #
  # === #

  results[:trl] = results[:reul_heat].sum(0.0) +
                  results[:reul_cool].sum(0.0) +
                  results[:reul_dhw].sum(0.0) +
                  results[:reul_la] + results[:reul_dh]
  results[:tnml] = results[:nmeul_heat].sum(0.0) +
                   results[:nmeul_cool].sum(0.0) +
                   results[:nmeul_dhw].sum(0.0) +
                   results[:nmeul_vent_preheat].sum(0.0) +
                   results[:nmeul_vent_precool].sum(0.0) +
                   results[:eul_la] + results[:eul_dh]

  results[:eri] = results[:tnml] / results[:trl] * 100.0

  if not results_iad.nil?

    # ANSI/RESNET/ICC 301-2014 Addendum E-2018 House Size Index Adjustment Factors (IAF)

    results[:iad_save] = (100.0 - results_iad[:eri]) / 100.0

    results[:iaf_cfa] = (2400.0 / results[:rated_cfa])**(0.304 * results[:iad_save])
    results[:iaf_nbr] = 1.0 + (0.069 * results[:iad_save] * (results[:rated_nbr] - 3.0))
    results[:iaf_ns] = (2.0 / results[:rated_nst])**(0.12 * results[:iad_save])
    results[:iaf_rh] = results[:iaf_cfa] * results[:iaf_nbr] * results[:iaf_ns]

    results[:eri] /= results[:iaf_rh]

  end

  opp_reduction = results[:eri] * (1.0 - results[:pefrac])
  if not opp_reduction_limit.nil?
    if opp_reduction > opp_reduction_limit
      opp_reduction = opp_reduction_limit
    end
  end
  results[:eri] -= opp_reduction

  return results
end

def _calculate_co2e_index(rated_output, ref_output, results)
  # Check that CO2e Reference Home doesn't have fossil fuel use.
  ['Natural Gas', 'Fuel Oil', 'Propane',
   'Wood Cord', 'Wood Pellets'].each do |fuel|
    next if ref_output["Fuel Use: #{fuel}: Total (MBtu)"].to_f == 0

    fail 'CO2e Reference Home found with fossil fuel energy use.'
  end

  results[:aco2e] = rated_output['Emissions: CO2e: RESNET: Total (lb)']
  results[:arco2e] = ref_output['Emissions: CO2e: RESNET: Total (lb)']

  if (not results[:aco2e].nil?) && (not results[:arco2e].nil?)
    # Check if any fuel consumption without corresponding CO2e emissions.
    # This would represent a fuel type (e.g., wood) not covered by 301
    # emissions factors.
    ['Electricity', 'Natural Gas', 'Fuel Oil',
     'Propane', 'Wood Cord', 'Wood Pellets'].each do |fuel|
      next unless rated_output["Fuel Use: #{fuel}: Total (MBtu)"].to_f > 0
      next unless rated_output["Emissions: CO2e: RESNET: #{fuel}: Total (lb)"].to_f == 0

      return results
    end

    # IAF was not in the initial calculation but has since been added
    results[:co2eindex] = results[:aco2e] / (results[:arco2e] * results[:iaf_rh]) * 100.0
  end
  return results
end

def calculate_eri(design_outputs, resultsdir, csv_filename_prefix: nil, opp_reduction_limit: nil, skip_csv: false)
  if design_outputs.keys.include? Constants.CalcTypeERIIndexAdjustmentDesign
    results_iad = _calculate_eri(design_outputs[Constants.CalcTypeERIIndexAdjustmentDesign],
                                 design_outputs[Constants.CalcTypeERIIndexAdjustmentReferenceHome],
                                 opp_reduction_limit: opp_reduction_limit)
  else
    results_iad = nil
  end

  results = _calculate_eri(design_outputs[Constants.CalcTypeERIRatedHome],
                           design_outputs[Constants.CalcTypeERIReferenceHome],
                           results_iad: results_iad,
                           opp_reduction_limit: opp_reduction_limit)

  if design_outputs.keys.include? Constants.CalcTypeCO2eRatedHome
    results = _calculate_co2e_index(design_outputs[Constants.CalcTypeCO2eRatedHome],
                                    design_outputs[Constants.CalcTypeCO2eReferenceHome],
                                    results)
  end

  if not skip_csv
    write_eri_results(results, resultsdir, design_outputs, results_iad, csv_filename_prefix)
  end

  return results
end

def write_eri_results(results, resultsdir, design_outputs, results_iad, csv_filename_prefix)
  ref_output = design_outputs[Constants.CalcTypeERIReferenceHome]

  csv_filename_prefix = "#{csv_filename_prefix}_" unless csv_filename_prefix.nil?

  # ERI Results file
  results_csv = File.join(resultsdir, "#{csv_filename_prefix}ERI_Results.csv")
  results_out = []
  results_out << ['ERI', results[:eri].round(2)]
  results_out << ['REUL Heating (MBtu)', results[:reul_heat].map { |x| x.round(2) }.join(',')]
  results_out << ['REUL Cooling (MBtu)', results[:reul_cool].map { |x| x.round(2) }.join(',')]
  results_out << ['REUL Hot Water (MBtu)', results[:reul_dhw].map { |x| x.round(2) }.join(',')]
  results_out << ['EC_r Heating (MBtu)', results[:ec_r_heat].map { |x| x.round(2) }.join(',')]
  results_out << ['EC_r Cooling (MBtu)', results[:ec_r_cool].map { |x| x.round(2) }.join(',')]
  results_out << ['EC_r Hot Water (MBtu)', results[:ec_r_dhw].map { |x| x.round(2) }.join(',')]
  results_out << ['EC_x Heating (MBtu)', results[:ec_x_heat].map { |x| x.round(2) }.join(',')]
  results_out << ['EC_x Cooling (MBtu)', results[:ec_x_cool].map { |x| x.round(2) }.join(',')]
  results_out << ['EC_x Hot Water (MBtu)', results[:ec_x_dhw].map { |x| x.round(2) }.join(',')]
  results_out << ['EC_x Dehumid (MBtu)', results[:eul_dh].round(2)]
  results_out << ['EC_x L&A (MBtu)', results[:eul_la].round(2)]
  if not results_iad.nil?
    results_out << ['IAD_Save (%)', results[:iad_save].round(5)]
  end
  # TODO: Heating Fuel, Heating MEPR, Cooling Fuel, Cooling MEPR, Hot Water Fuel, Hot Water MEPR
  CSV.open(results_csv, 'wb') { |csv| results_out.to_a.each { |elem| csv << elem } }

  # ERI Worksheet file
  worksheet_csv = File.join(resultsdir, "#{csv_filename_prefix}ERI_Worksheet.csv")
  worksheet_out = []
  worksheet_out << ['Coeff Heating a', results[:coeff_heat_a].map { |x| x.round(4) }.join(',')]
  worksheet_out << ['Coeff Heating b', results[:coeff_heat_b].map { |x| x.round(4) }.join(',')]
  worksheet_out << ['Coeff Cooling a', results[:coeff_cool_a].map { |x| x.round(4) }.join(',')]
  worksheet_out << ['Coeff Cooling b', results[:coeff_cool_b].map { |x| x.round(4) }.join(',')]
  worksheet_out << ['Coeff Hot Water a', results[:coeff_dhw_a].map { |x| x.round(4) }.join(',')]
  worksheet_out << ['Coeff Hot Water b', results[:coeff_dhw_b].map { |x| x.round(4) }.join(',')]
  worksheet_out << ['DSE_r Heating', results[:dse_r_heat].map { |x| x.round(4) }.join(',')]
  worksheet_out << ['DSE_r Cooling', results[:dse_r_cool].map { |x| x.round(4) }.join(',')]
  worksheet_out << ['DSE_r Hot Water', results[:dse_r_dhw].map { |x| x.round(4) }.join(',')]
  worksheet_out << ['EEC_x Heating', results[:eec_x_heat].map { |x| x.round(4) }.join(',')]
  worksheet_out << ['EEC_x Cooling', results[:eec_x_cool].map { |x| x.round(4) }.join(',')]
  worksheet_out << ['EEC_x Hot Water', results[:eec_x_dhw].map { |x| x.round(4) }.join(',')]
  worksheet_out << ['EEC_r Heating', results[:eec_r_heat].map { |x| x.round(4) }.join(',')]
  worksheet_out << ['EEC_r Cooling', results[:eec_r_cool].map { |x| x.round(4) }.join(',')]
  worksheet_out << ['EEC_r Hot Water', results[:eec_r_dhw].map { |x| x.round(4) }.join(',')]
  worksheet_out << ['nEC_x Heating', results[:nec_x_heat].map { |x| x.round(4) }.join(',')]
  worksheet_out << ['nEC_x Cooling', results[:nec_x_cool].map { |x| x.round(4) }.join(',')]
  worksheet_out << ['nEC_x Hot Water', results[:nec_x_dhw].map { |x| x.round(4) }.join(',')]
  worksheet_out << ['nMEUL Heating', results[:nmeul_heat].map { |x| x.round(4) }.join(',')]
  worksheet_out << ['nMEUL Cooling', results[:nmeul_cool].map { |x| x.round(4) }.join(',')]
  worksheet_out << ['nMEUL Hot Water', results[:nmeul_dhw].map { |x| x.round(4) }.join(',')]
  if results[:nmeul_vent_preheat].empty?
    worksheet_out << ['nMEUL Vent Preheat', 0.0]
  else
    worksheet_out << ['nMEUL Vent Preheat', results[:nmeul_vent_preheat].map { |x| x.round(4) }.join(',')]
  end
  if results[:nmeul_vent_precool].empty?
    worksheet_out << ['nMEUL Vent Precool', 0.0]
  else
    worksheet_out << ['nMEUL Vent Precool', results[:nmeul_vent_precool].map { |x| x.round(4) }.join(',')]
  end
  if not results_iad.nil?
    worksheet_out << ['IAF CFA', results[:iaf_cfa].round(4)]
    worksheet_out << ['IAF NBR', results[:iaf_nbr].round(4)]
    worksheet_out << ['IAF NS', results[:iaf_ns].round(4)]
    worksheet_out << ['IAF RH', results[:iaf_rh].round(4)]
  end
  worksheet_out << ['Total Loads TnML', results[:tnml].round(4)]
  worksheet_out << ['Total Loads TRL', results[:trl].round(4)]
  if not results_iad.nil?
    worksheet_out << ['Total Loads TRL*IAF', (results[:trl] * results[:iaf_rh]).round(4)]
  end
  worksheet_out << ['ERI', results[:eri].round(2)]
  worksheet_out << [nil] # line break
  worksheet_out << ['Ref Home CFA', ref_output['ERI: Building: CFA']]
  worksheet_out << ['Ref Home Nbr', ref_output['ERI: Building: NumBedrooms']]
  if not results_iad.nil?
    worksheet_out << ['Ref Home NS', ref_output['ERI: Building: NumStories']]
  end
  worksheet_out << ['Ref dehumid', results[:reul_dh].round(2)]
  worksheet_out << ['Ref L&A resMELs', ref_output['End Use: Electricity: Plug Loads (MBtu)'].round(2)]
  worksheet_out << ['Ref L&A intLgt', (ref_output['End Use: Electricity: Lighting Interior (MBtu)'] +
                                       ref_output['End Use: Electricity: Lighting Garage (MBtu)']).round(2)]
  worksheet_out << ['Ref L&A extLgt', ref_output['End Use: Electricity: Lighting Exterior (MBtu)'].round(2)]
  worksheet_out << ['Ref L&A Fridg', ref_output['End Use: Electricity: Refrigerator (MBtu)'].round(2)]
  worksheet_out << ['Ref L&A TVs', ref_output['End Use: Electricity: Television (MBtu)'].round(2)]
  worksheet_out << ['Ref L&A R/O', (ref_output['End Use: Electricity: Range/Oven (MBtu)'] +
                                    ref_output['End Use: Natural Gas: Range/Oven (MBtu)'] +
                                    ref_output['End Use: Fuel Oil: Range/Oven (MBtu)'] +
                                    ref_output['End Use: Propane: Range/Oven (MBtu)'] +
                                    ref_output['End Use: Wood Cord: Range/Oven (MBtu)'] +
                                    ref_output['End Use: Wood Pellets: Range/Oven (MBtu)']).round(2)]
  worksheet_out << ['Ref L&A cDryer', (ref_output['End Use: Electricity: Clothes Dryer (MBtu)'] +
                                       ref_output['End Use: Natural Gas: Clothes Dryer (MBtu)'] +
                                       ref_output['End Use: Fuel Oil: Clothes Dryer (MBtu)'] +
                                       ref_output['End Use: Propane: Clothes Dryer (MBtu)'] +
                                       ref_output['End Use: Wood Cord: Clothes Dryer (MBtu)'] +
                                       ref_output['End Use: Wood Pellets: Clothes Dryer (MBtu)']).round(2)]
  worksheet_out << ['Ref L&A dWash', ref_output['End Use: Electricity: Dishwasher (MBtu)'].round(2)]
  worksheet_out << ['Ref L&A cWash', ref_output['End Use: Electricity: Clothes Washer (MBtu)'].round(2)]
  worksheet_out << ['Ref L&A mechV', ref_output['End Use: Electricity: Mech Vent (MBtu)'].round(2)]
  worksheet_out << ['Ref L&A ceilFan', ref_output['End Use: Electricity: Ceiling Fan (MBtu)'].round(2)]
  worksheet_out << ['Ref L&A total', results[:reul_la].round(2)]
  CSV.open(worksheet_csv, 'wb') { |csv| worksheet_out.to_a.each { |elem| csv << elem } }

  # CO2e Results file
  if not results[:co2eindex].nil?
    results_csv = File.join(resultsdir, 'CO2e_Results.csv')
    results_out = []
    results_out << ['CO2e Rating Index', results[:co2eindex].round(2)]
    results_out << ['ACO2 (lb CO2e)', results[:aco2e].round(2)]
    results_out << ['ARCO2 (lb CO2e)', results[:arco2e].round(2)]
    results_out << ['IAF RH', results[:iaf_rh].round(4)]
    CSV.open(results_csv, 'wb') { |csv| results_out.to_a.each { |elem| csv << elem } }
  end
end

def write_es_zerh_results(ruleset, resultsdir, rd_eri_results, rated_eri_results, rated_eri_results_wo_opp, target_eri, saf, passes)
  rd_eri = rd_eri_results[:eri].round(0)
  target_eri = target_eri.round(0)
  rated_eri = rated_eri_results[:eri].round(0)
  rated_wo_opp_eri = rated_eri_results_wo_opp[:eri].round(0)

  if rated_wo_opp_eri - rated_eri > rd_eri - target_eri
    fail 'Unexpected error.'
  end

  if ESConstants.AllVersions.include? ruleset
    results_csv = File.join(resultsdir, 'ES_Results.csv')
    results_out = []
    results_out << ['Reference Home ERI', rd_eri]

    if saf.nil?
      results_out << ['SAF (Size Adjustment Factor)', 'N/A']
    else
      results_out << ['SAF (Size Adjustment Factor)', saf.round(3)]
    end
    results_out << ['SAF Adjusted ERI Target', target_eri]
    results_out << [nil] # line break
    results_out << ['Rated Home ERI', rated_eri]
    results_out << ['Rated Home ERI w/o OPP', rated_wo_opp_eri]
    results_out << [nil] # line break
    if passes
      results_out << ['ENERGY STAR Certification', 'PASS']
    else
      results_out << ['ENERGY STAR Certification', 'FAIL']
    end
    CSV.open(results_csv, 'wb') { |csv| results_out.to_a.each { |elem| csv << elem } }
  elsif ZERHConstants.AllVersions.include? ruleset
    results_csv = File.join(resultsdir, 'ZERH_Results.csv')
    results_out = []
    results_out << ['Reference Home ERI', rd_eri]

    if saf.nil?
      results_out << ['SAF (Size Adjustment Factor)', 'N/A']
    else
      results_out << ['SAF (Size Adjustment Factor)', saf.round(3)]
    end
    results_out << ['SAF Adjusted ERI Target', target_eri]
    results_out << [nil] # line break
    results_out << ['Rated Home ERI', rated_eri]
    results_out << ['Rated Home ERI w/o OPP', rated_wo_opp_eri]
    results_out << [nil] # line break
    if passes
      results_out << ['Zero Energy Ready Home Certification', 'PASS']
    else
      results_out << ['Zero Energy Ready Home Certification', 'FAIL']
    end
    CSV.open(results_csv, 'wb') { |csv| results_out.to_a.each { |elem| csv << elem } }
  end
end

def download_epws
  require_relative '../hpxml-measures/HPXMLtoOpenStudio/resources/util'

  require 'tempfile'
  tmpfile = Tempfile.new('epw')

  UrlResolver.fetch('https://data.nrel.gov/system/files/128/tmy3s-cache-csv.zip', tmpfile)

  puts 'Extracting weather files...'
  weather_dir = File.join(File.dirname(__FILE__), '..', 'weather')
  require 'zip'
  Zip.on_exists_proc = true
  Zip::File.open(tmpfile.path.to_s) do |zip_file|
    zip_file.each do |f|
      zip_file.extract(f, File.join(weather_dir, f.name))
    end
  end

  num_epws_actual = Dir[File.join(weather_dir, '*.epw')].count
  puts "#{num_epws_actual} weather files are available in the weather directory."
  puts 'Completed.'
  exit!
end

def cache_weather
  # Process all epw files through weather.rb and serialize objects
  require_relative '../hpxml-measures/HPXMLtoOpenStudio/resources/materials'
  require_relative '../hpxml-measures/HPXMLtoOpenStudio/resources/psychrometrics'
  require_relative '../hpxml-measures/HPXMLtoOpenStudio/resources/unit_conversions'
  require_relative '../hpxml-measures/HPXMLtoOpenStudio/resources/util'
  require_relative '../hpxml-measures/HPXMLtoOpenStudio/resources/weather'
  require_relative '../hpxml-measures/HPXMLtoOpenStudio/resources/schedules'

  # OpenStudio::Logger.instance.standardOutLogger.setLogLevel(OpenStudio::Fatal)
  weather_dir = File.join(File.dirname(__FILE__), '..', 'weather')
  OpenStudio::Logger.instance.standardOutLogger.setLogLevel(OpenStudio::Fatal)
  runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)
  puts 'Creating cache *.csv for weather files...'
  Dir["#{weather_dir}/*.epw"].each do |epw|
    next if File.exist? epw.gsub('.epw', '-cache.csv')

    puts "Processing #{epw}..."
    model = OpenStudio::Model::Model.new
    epw_file = OpenStudio::EpwFile.new(epw)
    OpenStudio::Model::WeatherFile.setWeatherFile(model, epw_file).get
    weather = WeatherProcess.new(model, runner)
    File.open(epw.gsub('.epw', '-cache.csv'), 'wb') do |file|
      weather.dump_to_csv(file)
    end
  end
  puts 'Completed.'
  exit!
end

def main(options)
  # Setup directories
  unless Dir.exist?(options[:output_dir])
    FileUtils.mkdir_p(options[:output_dir])
  end
  resultsdir = File.join(options[:output_dir], 'results')
  rm_path(resultsdir)
  Dir.mkdir(resultsdir)

  puts "HPXML: #{options[:hpxml]}"
  hpxml_doc = XMLHelper.parse_file(options[:hpxml])
  eri_version, es_version, iecc_version, zerh_version = get_program_versions(hpxml_doc)

  # Create list of designs
  designs = []
  if not eri_version.nil?
    # ERI designs
    designs << Design.new(calc_type: Constants.CalcTypeERIRatedHome, output_dir: options[:output_dir])
    if not options[:rated_home_only]
      designs << Design.new(calc_type: Constants.CalcTypeERIReferenceHome, output_dir: options[:output_dir])
      if Constants.ERIVersions.index(eri_version) >= Constants.ERIVersions.index('2014AE')
        # Add IAF designs
        designs << Design.new(calc_type: Constants.CalcTypeERIIndexAdjustmentDesign, output_dir: options[:output_dir])
        designs << Design.new(calc_type: Constants.CalcTypeERIIndexAdjustmentReferenceHome, output_dir: options[:output_dir])
      end
      if Constants.ERIVersions.index(eri_version) >= Constants.ERIVersions.index('2019ABCD')
        # Add CO2e designs
        designs << Design.new(calc_type: Constants.CalcTypeCO2eRatedHome, output_dir: options[:output_dir])
        designs << Design.new(calc_type: Constants.CalcTypeCO2eReferenceHome, output_dir: options[:output_dir])
      end
    end
  end
  if not es_version.nil?
    # ENERGY STAR designs
    designs << Design.new(init_calc_type: ESConstants.CalcTypeEnergyStarReference, calc_type: Constants.CalcTypeERIRatedHome, output_dir: options[:output_dir])
    designs << Design.new(init_calc_type: ESConstants.CalcTypeEnergyStarReference, calc_type: Constants.CalcTypeERIReferenceHome, output_dir: options[:output_dir])
    designs << Design.new(init_calc_type: ESConstants.CalcTypeEnergyStarReference, calc_type: Constants.CalcTypeERIIndexAdjustmentDesign, output_dir: options[:output_dir])
    designs << Design.new(init_calc_type: ESConstants.CalcTypeEnergyStarReference, calc_type: Constants.CalcTypeERIIndexAdjustmentReferenceHome, output_dir: options[:output_dir])
    designs << Design.new(init_calc_type: ESConstants.CalcTypeEnergyStarRated, calc_type: Constants.CalcTypeERIRatedHome, output_dir: options[:output_dir])
    designs << Design.new(init_calc_type: ESConstants.CalcTypeEnergyStarRated, calc_type: Constants.CalcTypeERIReferenceHome, output_dir: options[:output_dir])
    designs << Design.new(init_calc_type: ESConstants.CalcTypeEnergyStarRated, calc_type: Constants.CalcTypeERIIndexAdjustmentDesign, output_dir: options[:output_dir])
    designs << Design.new(init_calc_type: ESConstants.CalcTypeEnergyStarRated, calc_type: Constants.CalcTypeERIIndexAdjustmentReferenceHome, output_dir: options[:output_dir])
  end
  if not iecc_version.nil?
    # IECC ERI designs
    designs << Design.new(iecc_version: iecc_version, calc_type: Constants.CalcTypeERIRatedHome, output_dir: options[:output_dir])
    designs << Design.new(iecc_version: iecc_version, calc_type: Constants.CalcTypeERIReferenceHome, output_dir: options[:output_dir])
    designs << Design.new(iecc_version: iecc_version, calc_type: Constants.CalcTypeERIIndexAdjustmentDesign, output_dir: options[:output_dir])
    designs << Design.new(iecc_version: iecc_version, calc_type: Constants.CalcTypeERIIndexAdjustmentReferenceHome, output_dir: options[:output_dir])
  end
  if not zerh_version.nil?
    # ENERGY STAR designs
    designs << Design.new(init_calc_type: ZERHConstants.CalcTypeZERHReference, calc_type: Constants.CalcTypeERIRatedHome, output_dir: options[:output_dir])
    designs << Design.new(init_calc_type: ZERHConstants.CalcTypeZERHReference, calc_type: Constants.CalcTypeERIReferenceHome, output_dir: options[:output_dir])
    designs << Design.new(init_calc_type: ZERHConstants.CalcTypeZERHReference, calc_type: Constants.CalcTypeERIIndexAdjustmentDesign, output_dir: options[:output_dir])
    designs << Design.new(init_calc_type: ZERHConstants.CalcTypeZERHReference, calc_type: Constants.CalcTypeERIIndexAdjustmentReferenceHome, output_dir: options[:output_dir])
    designs << Design.new(init_calc_type: ZERHConstants.CalcTypeZERHRated, calc_type: Constants.CalcTypeERIRatedHome, output_dir: options[:output_dir])
    designs << Design.new(init_calc_type: ZERHConstants.CalcTypeZERHRated, calc_type: Constants.CalcTypeERIReferenceHome, output_dir: options[:output_dir])
    designs << Design.new(init_calc_type: ZERHConstants.CalcTypeZERHRated, calc_type: Constants.CalcTypeERIIndexAdjustmentDesign, output_dir: options[:output_dir])
    designs << Design.new(init_calc_type: ZERHConstants.CalcTypeZERHRated, calc_type: Constants.CalcTypeERIIndexAdjustmentReferenceHome, output_dir: options[:output_dir])
  end

  duplicates = apply_rulesets_and_generate_hpxmls(designs, options)

  if not options[:skip_simulation]

    run_simulations(designs, options, duplicates)

    # For duplicate designs that weren't simulated, populate their output
    duplicate_output_files(duplicates, designs, resultsdir)

    puts 'Calculating results...'

    if (not eri_version.nil?) && (not options[:rated_home_only])
      # Calculate ERI & CO2e Index
      eri_designs = designs.select { |d| d.init_calc_type.nil? && d.iecc_version.nil? }
      eri_outputs = retrieve_eri_outputs(eri_designs)

      # Calculate and write results
      eri_results = calculate_eri(eri_outputs, resultsdir)
      puts "ERI: #{eri_results[:eri].round(2)}"
      if not eri_results[:co2eindex].nil?
        puts "CO2e Index: #{eri_results[:co2eindex].round(2)}"
      end
    end

    if not iecc_version.nil?
      # Calculate IECC ERI
      iecc_eri_designs = designs.select { |d| !d.iecc_version.nil? }
      iecc_eri_outputs = retrieve_eri_outputs(iecc_eri_designs)

      # Calculate and write results
      iecc_eri_results = calculate_eri(iecc_eri_outputs, resultsdir, csv_filename_prefix: 'IECC')
      puts "IECC ERI: #{iecc_eri_results[:eri].round(2)}"
    end

    if not es_version.nil?
      # Calculate ES Reference ERI
      esrd_eri_designs = designs.select { |d| d.init_calc_type == ESConstants.CalcTypeEnergyStarReference }
      esrd_eri_outputs = retrieve_eri_outputs(esrd_eri_designs)
      esrd_eri_results = calculate_eri(esrd_eri_outputs, resultsdir, csv_filename_prefix: ESConstants.CalcTypeEnergyStarReference.gsub(' ', ''))

      # Calculate Size-Adjusted ERI for Energy Star Reference Homes
      saf = get_saf(esrd_eri_results, es_version, options[:hpxml])
      target_eri = esrd_eri_results[:eri] * saf

      # Calculate ES Rated ERI, w/ On-site Power Production (OPP) restriction as appropriate
      opp_reduction_limit = calc_opp_eri_limit(esrd_eri_results[:eri], saf, es_version)
      rated_eri_designs = designs.select { |d| d.init_calc_type == ESConstants.CalcTypeEnergyStarRated }
      rated_eri_outputs = retrieve_eri_outputs(rated_eri_designs)
      rated_eri_results = calculate_eri(rated_eri_outputs, resultsdir, csv_filename_prefix: ESConstants.CalcTypeEnergyStarRated.gsub(' ', ''),
                                                                       opp_reduction_limit: opp_reduction_limit)

      if rated_eri_results[:eri].round(0) <= target_eri.round(0)
        passes = true
      else
        passes = false
      end

      # Calculate ES Rated ERI w/o OPP for extra information
      rated_eri_results_wo_opp = calculate_eri(rated_eri_outputs, resultsdir, skip_csv: true, opp_reduction_limit: 0.0)

      write_es_zerh_results(es_version, resultsdir, esrd_eri_results, rated_eri_results, rated_eri_results_wo_opp, target_eri, saf, passes)

      if passes
        puts 'ENERGY STAR Certification: PASS'
      else
        puts 'ENERGY STAR Certification: FAIL'
      end
    end

    if not zerh_version.nil?
      # Calculate ZERH Reference ERI
      zerhrd_eri_designs = designs.select { |d| d.init_calc_type == ZERHConstants.CalcTypeZERHReference }
      zerhrd_eri_outputs = retrieve_eri_outputs(zerhrd_eri_designs)
      zerhrd_eri_results = calculate_eri(zerhrd_eri_outputs, resultsdir, csv_filename_prefix: ZERHConstants.CalcTypeZERHReference.gsub(' ', ''))

      # Calculate Size-Adjusted ERI for ZERH Reference Homes
      saf = get_saf(zerhrd_eri_results, zerh_version, options[:hpxml])
      target_eri = zerhrd_eri_results[:eri] * saf

      # Calculate ZERH Rated ERI
      rated_eri_designs = designs.select { |d| d.init_calc_type == ZERHConstants.CalcTypeZERHRated }
      rated_eri_outputs = retrieve_eri_outputs(rated_eri_designs)
      rated_eri_results = calculate_eri(rated_eri_outputs, resultsdir, csv_filename_prefix: ZERHConstants.CalcTypeZERHRated.gsub(' ', ''))

      if rated_eri_results[:eri].round(0) <= target_eri.round(0)
        passes = true
      else
        passes = false
      end

      # Calculate ZERH Rated ERI w/o OPP for extra information
      rated_eri_results_wo_opp = calculate_eri(rated_eri_outputs, resultsdir, skip_csv: true, opp_reduction_limit: 0.0)

      write_es_zerh_results(zerh_version, resultsdir, zerhrd_eri_results, rated_eri_results, rated_eri_results_wo_opp, target_eri, saf, passes)

      if passes
        puts 'Zero Energy Ready Home Certification: PASS'
      else
        puts 'Zero Energy Ready Home Certification: FAIL'
      end
    end

  end

  if Dir[resultsdir].length > 1
    puts "Output files written to #{resultsdir}"
  end
end

# Check for correct versions of OS
Version.check_openstudio_version()

timeseries_types = ['ALL', 'total', 'fuels', 'enduses', 'emissions', 'emissionfuels',
                    'emissionenduses', 'hotwater', 'loads', 'componentloads',
                    'unmethours', 'temperatures', 'airflows', 'weather']

options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: #{File.basename(__FILE__)} -x building.xml"

  opts.on('-x', '--xml <FILE.xml>', 'HPXML file') do |t|
    options[:hpxml] = t
  end

  opts.on('-o', '--output-dir <DIR>', 'Output directory') do |t|
    options[:output_dir] = t
  end

  options[:hourly_outputs] = []
  opts.on('--hourly TYPE', timeseries_types, "Request hourly output type (#{timeseries_types.join(', ')}); can be called multiple times") do |t|
    options[:hourly_outputs] << t
  end

  options[:daily_outputs] = []
  opts.on('--daily TYPE', timeseries_types, "Request daily output type (#{timeseries_types.join(', ')}); can be called multiple times") do |t|
    options[:daily_outputs] << t
  end

  options[:monthly_outputs] = []
  opts.on('--monthly TYPE', timeseries_types, "Request monthly output type (#{timeseries_types.join(', ')}); can be called multiple times") do |t|
    options[:monthly_outputs] << t
  end

  opts.on('-w', '--download-weather', 'Downloads all US TMY3 weather files') do |t|
    options[:epws] = t
  end

  opts.on('-c', '--cache-weather', 'Caches all weather files') do |t|
    options[:cache] = t
  end

  options[:add_comp_loads] = false
  opts.on('--add-component-loads', 'Add heating/cooling component loads calculation') do |_t|
    options[:add_comp_loads] = true
  end

  options[:skip_simulation] = false
  opts.on('--skip-simulation', 'Skip the EnergyPlus simulations') do |_t|
    options[:skip_simulation] = true
  end

  options[:rated_home_only] = false
  opts.on('--rated-home-only', 'Only run the ERI Rated Home') do |_t|
    options[:rated_home_only] = true
  end

  options[:debug] = false
  opts.on('-d', '--debug', 'Generate additional debug output/files') do |_t|
    options[:debug] = true
  end

  options[:version] = false
  opts.on('-v', '--version', 'Reports the workflow version') do |_t|
    options[:version] = true
  end

  opts.on_tail('-h', '--help', 'Display help') do
    puts opts
    exit!
  end
end.parse!(args)

options[:timeseries_output_freq] = 'none'
options[:timeseries_outputs] = []
n_freq = 0
if not options[:hourly_outputs].empty?
  n_freq += 1
  options[:timeseries_output_freq] = 'hourly'
  options[:timeseries_outputs] = options[:hourly_outputs]
end
if not options[:daily_outputs].empty?
  n_freq += 1
  options[:timeseries_output_freq] = 'daily'
  options[:timeseries_outputs] = options[:daily_outputs]
end
if not options[:monthly_outputs].empty?
  n_freq += 1
  options[:timeseries_output_freq] = 'monthly'
  options[:timeseries_outputs] = options[:monthly_outputs]
end

if n_freq > 1
  puts 'Multiple timeseries frequencies (hourly, daily, monthly) are not supported.'
  exit!
end

if options[:timeseries_outputs].include? 'ALL'
  options[:timeseries_outputs] = timeseries_types[1..-1]
end
if options[:version]
  require_relative 'version.rb'
  puts "OpenStudio-ERI v#{Version::OS_ERI_Version}"
  puts "OpenStudio v#{OpenStudio.openStudioLongVersion}"
  puts "EnergyPlus v#{OpenStudio.energyPlusVersion}.#{OpenStudio.energyPlusBuildSHA}"
  exit!
end

if options[:epws]
  download_epws
end

if options[:cache]
  cache_weather
end

if not options[:hpxml]
  puts "HPXML argument is required. Call #{File.basename(__FILE__)} -h for usage."
  exit!
end

unless (Pathname.new options[:hpxml]).absolute?
  options[:hpxml] = File.expand_path(options[:hpxml])
end
unless File.exist?(options[:hpxml]) && options[:hpxml].downcase.end_with?('.xml')
  puts "'#{options[:hpxml]}' does not exist or is not an .xml file."
  exit!
end

if options[:output_dir].nil?
  options[:output_dir] = basedir # default
end
options[:output_dir] = File.expand_path(options[:output_dir])

main(options)

puts "Completed in #{(Time.now - start_time).round(1)}s."
