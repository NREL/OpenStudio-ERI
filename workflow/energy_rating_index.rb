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

@fuel_map = { HPXML::FuelTypeElectricity => FT::Elec,
              HPXML::FuelTypeNaturalGas => FT::Gas,
              HPXML::FuelTypeOil => FT::Oil,
              HPXML::FuelTypePropane => FT::Propane,
              HPXML::FuelTypeWoodCord => FT::WoodCord,
              HPXML::FuelTypeWoodPellets => FT::WoodPellets }

def get_program_versions(hpxml_doc)
  versions = []

  { 'ERICalculation/Version' => Constants.ERIVersions,
    'CO2IndexCalculation/Version' => Constants.ERIVersions,
    'EnergyStarCalculation/Version' => ESConstants.AllVersions,
    'IECCERICalculation/Version' => IECCConstants.AllVersions,
    'ZERHCalculation/Version' => ZERHConstants.AllVersions }.each do |xpath, all_versions|
    version = XMLHelper.get_value(hpxml_doc, "/HPXML/SoftwareInfo/extension/#{xpath}", :string)
    if version == 'latest'
      version = all_versions[-1]
    end

    if (not version.nil?) && (not all_versions.include? version)
      puts "Unexpected #{xpath}: '#{version}'"
      exit!
    end
    if not version.nil?
      puts "#{xpath}: #{version}"
    else
      puts "#{xpath}: None"
    end

    versions << version
  end

  return versions
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
             options[:add_comp_loads], options[:output_format])

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
  command += "\"#{options[:output_format]}\" "
  pid = Process.spawn(command)

  return design.design_dir, pid
end

def retrieve_design_outputs(designs)
  # Retrieve outputs for ERI calculations
  design_outputs = {}
  designs.each do |design|
    if not File.exist? design.annual_output_path
      puts 'Errors encountered. Aborting...'
      exit!
    end

    calc_type = design.calc_type

    design_outputs[calc_type] = {}
    design_outputs[calc_type]['HPXML'] = HPXML.new(hpxml_path: design.hpxml_output_path)

    if design.annual_output_path.end_with? '.csv'
      CSV.foreach(design.annual_output_path) do |row|
        next if row.nil? || (row.size < 2) || row[1].nil?

        output_type = row[0].split(' (')[0].strip # Remove units
        design_outputs[calc_type][output_type] = Float(row[1])
      end
    elsif design.annual_output_path.end_with? '.json'
      require 'json'
      JSON.parse(File.read(design.annual_output_path)).each do |group, hash|
        hash.each do |var, val|
          output_type = "#{group}: #{var}".split(' (')[0].strip # Remove units
          design_outputs[calc_type][output_type] = Float(val)
        end
      end
    end
  end
  return design_outputs
end

class ERIComponent
  attr_accessor(:reul, :coeff_a, :coeff_b, :eec_x, :eec_r, :ec_x, :ec_r, :dse_r,
                :nec_x, :nmeul, :load_frac, :ref_id, :rated_id, :is_dual_fuel)
end

def _calculate_eri(rated_output, ref_output, results_iad: nil,
                   opp_reduction_limit: nil, renewable_energy_limit: nil)

  def get_coefficients(fuel, type)
    if (type == 'Heating') || (type == 'Mech Vent Preheating')
      if fuel == HPXML::FuelTypeElectricity
        return 2.2561, 0.0
      else
        return 1.0943, 0.4030
      end
    elsif (type == 'Cooling') || (type == 'Mech Vent Precooling')
      return 3.8090, 0.0
    elsif type == 'Hot Water'
      if fuel == HPXML::FuelTypeElectricity
        return 0.9200, 0.0
      else
        return 1.1877, 1.0130
      end
    end

    fail 'Could not identify EEC coefficients.'
  end

  def get_fuel(system, type, is_dfhp_primary = nil)
    if type == 'Heating'
      if is_dfhp_primary == false
        return system.backup_heating_fuel
      else
        if system.is_a? HPXML::HeatingSystem
          return system.heating_system_fuel
        elsif system.is_a? HPXML::HeatPump
          return system.heat_pump_fuel
        elsif system.is_a? HPXML::CoolingSystem
          return system.integrated_heating_system_fuel
        end
      end
    elsif type == 'Cooling'
      if system.is_a? HPXML::CoolingSystem
        return system.cooling_system_fuel
      else
        return system.heat_pump_fuel
      end
    elsif type == 'Hot Water'
      if not system.fuel_type.nil?
        return system.fuel_type
      else
        return system.related_hvac_system.heating_system_fuel
      end
    elsif type == 'Mech Vent Preheating'
      return system.preheating_fuel
    elsif type == 'Mech Vent Precooling'
      return system.precooling_fuel
    end
  end

  def get_eec_numerator(unit)
    # Newer metrics (SEER2, HSPF2, UEF, CEER) should be converted
    # to older metrics (SEER, HSPF, EF, EER)
    if ['HSPF', 'SEER', 'EER'].include? unit
      return 3.413
    elsif ['AFUE', 'COP', 'Percent', 'EF'].include? unit
      return 1.0
    end
  end

  def get_eec(system, type, is_dfhp_primary = nil)
    if type == 'Heating'
      if is_dfhp_primary == false
        if not system.backup_heating_efficiency_afue.nil?
          return get_eec_numerator('AFUE') / system.backup_heating_efficiency_afue
        elsif not system.backup_heating_efficiency_percent.nil?
          return get_eec_numerator('Percent') / system.backup_heating_efficiency_percent
        end
      elsif system.is_a? HPXML::CoolingSystem
        return get_eec_numerator('Percent') / system.integrated_heating_system_efficiency_percent
      else
        if system.respond_to?(:heating_efficiency_afue) && (not system.heating_efficiency_afue.nil?)
          return get_eec_numerator('AFUE') / system.heating_efficiency_afue
        elsif system.respond_to?(:heating_efficiency_percent) && (not system.heating_efficiency_percent.nil?)
          return get_eec_numerator('Percent') / system.heating_efficiency_percent
        elsif system.respond_to?(:heating_efficiency_hspf) && (not system.heating_efficiency_hspf.nil?)
          return get_eec_numerator('HSPF') / system.heating_efficiency_hspf
        elsif system.respond_to?(:heating_efficiency_hspf2) && (not system.heating_efficiency_hspf2.nil?)
          hspf = HVAC.calc_hspf_from_hspf2(system.heating_efficiency_hspf2, !system.distribution_system_idref.nil?)
          return get_eec_numerator('HSPF') / hspf
        elsif system.respond_to?(:heating_efficiency_cop) && (not system.heating_efficiency_cop.nil?)
          return get_eec_numerator('COP') / system.heating_efficiency_cop
        end
      end
    elsif type == 'Cooling'
      if system.respond_to?(:cooling_efficiency_seer) && (not system.cooling_efficiency_seer.nil?)
        return get_eec_numerator('SEER') / system.cooling_efficiency_seer
      elsif system.respond_to?(:cooling_efficiency_seer2) && (not system.cooling_efficiency_seer2.nil?)
        seer = HVAC.calc_seer_from_seer2(system.cooling_efficiency_seer2, !system.distribution_system_idref.nil?)
        return get_eec_numerator('SEER') / seer
      elsif system.respond_to?(:cooling_efficiency_eer) && (not system.cooling_efficiency_eer.nil?)
        return get_eec_numerator('EER') / system.cooling_efficiency_eer
      elsif system.respond_to?(:cooling_efficiency_ceer) && (not system.cooling_efficiency_ceer.nil?)
        eer = system.cooling_efficiency_ceer * 1.01 # FIXME: Move to hvac.rb
        return get_eec_numerator('EER') / eer
      elsif system.cooling_system_type == HPXML::HVACTypeEvaporativeCooler
        return get_eec_numerator('SEER') / 15.0 # Arbitrary
      end
    elsif type == 'Hot Water'
      if not system.energy_factor.nil?
        ef = system.energy_factor
      elsif not system.uniform_energy_factor.nil?
        ef = Waterheater.calc_ef_from_uef(system)
      end
      if ef.nil?
        # Get assumed EF for combi system

        eta_c = system.related_hvac_system.heating_efficiency_afue
        if system.water_heater_type == HPXML::WaterHeaterTypeCombiTankless
          ef = eta_c
        elsif system.water_heater_type == HPXML::WaterHeaterTypeCombiStorage
          # Calculates the energy factor based on UA of the tank and conversion efficiency (eta_c)
          # Source: Burch and Erickson 2004 - http://www.nrel.gov/docs/gen/fy04/36035.pdf

          act_vol = Waterheater.calc_storage_tank_actual_vol(system.tank_volume, nil)
          a_side = Waterheater.calc_tank_areas(act_vol)[1]
          ua = Waterheater.calc_indirect_ua_with_standbyloss(act_vol, system, a_side, 0.0)

          volume_drawn = 64.3 # gal/day
          density = 8.2938 # lb/gal
          draw_mass = volume_drawn * density # lb
          cp = 1.0007 # Btu/lb-F
          t = 135.0 # F
          t_in = 58.0 # F
          t_env = 67.5 # F
          q_load = draw_mass * cp * (t - t_in) # Btu/day

          ef = q_load / ((ua * (t - t_env) * 24.0 + q_load) / eta_c)
        end
      end
      if not system.performance_adjustment.nil?
        ef *= system.performance_adjustment
      end
      return get_eec_numerator('EF') / ef
    elsif type == 'Mech Vent Preheating'
      return get_eec_numerator('COP') / system.preheating_efficiency_cop
    elsif type == 'Mech Vent Precooling'
      return get_eec_numerator('COP') / system.precooling_efficiency_cop
    end
  end

  rated_bldg = rated_output['HPXML'].buildings[0]
  HVAC.apply_shared_systems(rated_bldg)
  reg_bldg = ref_output['HPXML'].buildings[0]

  results = {}

  # ======== #
  # Building #
  # ======== #
  results[:rated_cfa] = rated_bldg.building_construction.conditioned_floor_area
  results[:rated_nbr] = rated_bldg.building_construction.number_of_bedrooms
  results[:rated_nst] = rated_bldg.building_construction.number_of_conditioned_floors_above_grade
  results[:rated_facility_type] = rated_bldg.building_construction.residential_facility_type

  # =========================== #
  # Ventilation Preconditioning #
  # =========================== #

  # Calculate independent nMEUL for ventilation preconditioning

  results[:eri_vent_preheat] = []
  rated_bldg.ventilation_fans.each do |rated_sys|
    next if rated_sys.preheating_fuel.nil?

    results[:eri_vent_preheat] << calculate_eri_component_precond(rated_output, rated_sys, 'Mech Vent Preheating')
  end

  results[:eri_vent_precool] = []
  rated_bldg.ventilation_fans.each do |rated_sys|
    next if rated_sys.precooling_fuel.nil?

    results[:eri_vent_precool] << calculate_eri_component_precond(rated_output, rated_sys, 'Mech Vent Precooling')
  end

  # ======= #
  # Heating #
  # ======= #

  results[:eri_heat] = []
  rated_bldg.hvac_systems.each do |rated_sys|
    if rated_sys.respond_to? :fraction_heat_load_served
      fraction_heat_load_served = rated_sys.fraction_heat_load_served
    elsif rated_sys.respond_to? :integrated_heating_system_fraction_heat_load_served
      fraction_heat_load_served = rated_sys.integrated_heating_system_fraction_heat_load_served
    end
    next if fraction_heat_load_served.to_f <= 0

    # Get corresponding Reference Home system
    ref_sys = reg_bldg.hvac_systems.select { |h| h.respond_to?(:htg_seed_id) && (h.htg_seed_id == rated_sys.htg_seed_id) }[0]

    if rated_sys.is_a?(HPXML::HeatPump) && rated_sys.is_dual_fuel
      # Dual fuel heat pump; calculate ERI using two different HVAC systems
      results[:eri_heat] << calculate_eri_component(rated_output, ref_output, rated_sys, ref_sys, fraction_heat_load_served, 'Heating', true)
      results[:eri_heat] << calculate_eri_component(rated_output, ref_output, rated_sys, ref_sys, fraction_heat_load_served, 'Heating', false)
    else
      results[:eri_heat] << calculate_eri_component(rated_output, ref_output, rated_sys, ref_sys, fraction_heat_load_served, 'Heating')
    end
  end

  # ======= #
  # Cooling #
  # ======= #

  results[:eri_cool] = []
  whf_energy = get_end_use(rated_output, EUT::WholeHouseFan, FT::Elec)
  rated_bldg.hvac_systems.each do |rated_sys|
    if rated_sys.respond_to? :fraction_cool_load_served
      fraction_cool_load_served = rated_sys.fraction_cool_load_served
    end
    next if fraction_cool_load_served.to_f <= 0

    # Get corresponding Reference Home system
    ref_sys = reg_bldg.hvac_systems.select { |h| h.respond_to?(:clg_seed_id) && (h.clg_seed_id == rated_sys.clg_seed_id) }[0]

    results[:eri_cool] << calculate_eri_component(rated_output, ref_output, rated_sys, ref_sys, fraction_cool_load_served, 'Cooling', whf_energy: whf_energy)
  end

  # ======== #
  # HotWater #
  # ======== #

  results[:eri_dhw] = []
  # Always just 1 Reference Home water heater.
  if reg_bldg.water_heating_systems.size != 1
    fail 'Unexpected Reference Home results; should only be 1 DHW system.'
  end

  rated_bldg.water_heating_systems.each do |rated_sys|
    next if rated_sys.fraction_dhw_load_served.nil?

    # Get corresponding Reference Home system
    ref_sys = reg_bldg.water_heating_systems[0]

    results[:eri_dhw] << calculate_eri_component(rated_output, ref_output, rated_sys, ref_sys, rated_sys.fraction_dhw_load_served, 'Hot Water')
  end

  # ===== #
  # Other #
  # ===== #

  results[:teu] = calculate_teu(rated_output)
  renewable_elec_produced = get_end_use(rated_output, EUT::PV, FT::Elec)
  generation_elec_produced = get_end_use(rated_output, EUT::Generator, FT::Elec)
  generation_fuel_consumed = get_end_use(rated_output, EUT::Generator, non_elec_fuels)
  results[:opp] = calculate_opp(renewable_energy_limit, renewable_elec_produced, generation_elec_produced, generation_fuel_consumed)
  results[:pefrac] = calculate_pefrac(results[:teu], results[:opp])

  results[:eul_dh] = calculate_dh(rated_output)
  results[:eul_mv] = calculate_mv(rated_output)
  results[:eul_la] = calculate_la(rated_output)

  results[:reul_dh] = calculate_dh(ref_output)
  results[:reul_mv] = calculate_mv(ref_output)
  results[:reul_la] = calculate_la(ref_output)

  # === #
  # ERI #
  # === #

  results[:reul_heat] = results[:eri_heat].map { |c| c.reul }.sum(0.0)
  results[:reul_cool] = results[:eri_cool].map { |c| c.reul }.sum(0.0)
  results[:reul_dhw] = results[:eri_dhw].map { |c| c.reul }.sum(0.0)
  results[:trl] = results[:reul_heat] + results[:reul_cool] + results[:reul_dhw] +
                  results[:reul_la] + results[:reul_mv] + results[:reul_dh]

  results[:nmeul_heat] = results[:eri_heat].map { |c| c.nmeul }.sum(0.0)
  results[:nmeul_cool] = results[:eri_cool].map { |c| c.nmeul }.sum(0.0)
  results[:nmeul_dhw] = results[:eri_dhw].map { |c| c.nmeul }.sum(0.0)
  results[:nmeul_vent_preheat] = results[:eri_vent_preheat].map { |c| c.nmeul }.sum(0.0)
  results[:nmeul_vent_precool] = results[:eri_vent_precool].map { |c| c.nmeul }.sum(0.0)
  results[:tnml] = results[:nmeul_heat] + results[:nmeul_cool] + results[:nmeul_dhw] +
                   results[:nmeul_vent_preheat] + results[:nmeul_vent_precool] +
                   results[:eul_la] + results[:eul_mv] + results[:eul_dh]

  sum_ec_x = results[:eri_vent_preheat].map { |c| c.ec_x }.sum(0.0) +
             results[:eri_vent_precool].map { |c| c.ec_x }.sum(0.0) +
             results[:eri_heat].map { |c| c.ec_x }.sum(0.0) +
             results[:eri_cool].map { |c| c.ec_x }.sum(0.0) +
             results[:eri_dhw].map { |c| c.ec_x }.sum(0.0) +
             results[:eul_la] + results[:eul_mv] + results[:eul_dh] + whf_energy +
             renewable_elec_produced + generation_elec_produced + generation_fuel_consumed
  total_ec_x = get_fuel_use(rated_output, all_fuels, use_net: true)
  if (sum_ec_x - total_ec_x).abs > 0.1
    fail "Sum of energy consumptions (#{sum_ec_x.round(2)}) do not match total (#{total_ec_x.round(2)}) for Rated Home."
  end

  sum_ec_r = results[:eri_heat].map { |c| c.ec_r }.sum(0.0) +
             results[:eri_cool].map { |c| c.ec_r }.sum(0.0) +
             results[:eri_dhw].map { |c| c.ec_r }.sum(0.0) +
             results[:reul_la] + results[:reul_mv] + results[:reul_dh]
  total_ec_r = get_fuel_use(ref_output, all_fuels)
  if (sum_ec_r - total_ec_r).abs > 0.1
    fail "Sum of energy consumptions (#{sum_ec_r.round(2)}) do not match total (#{total_ec_r.round(2)}) for Reference Home."
  end

  results[:eri] = results[:tnml] / results[:trl] * 100.0

  iaf_rh = _calculate_iaf_rh(results, results_iad)
  results[:eri] /= iaf_rh

  opp_reduction = results[:eri] * (1.0 - results[:pefrac])
  if not opp_reduction_limit.nil?
    if opp_reduction > opp_reduction_limit
      opp_reduction = opp_reduction_limit
    end
  end
  results[:eri] -= opp_reduction

  return results
end

def _calculate_iaf_rh(results, results_iad)
  return 1.0 if results_iad.nil?

  # ANSI/RESNET/ICC 301-2014 Addendum E-2018 House Size Index Adjustment Factors (IAF)

  results[:iad_save] = (100.0 - results_iad[:eri]) / 100.0

  results[:iaf_cfa] = (2400.0 / results[:rated_cfa])**(0.304 * results[:iad_save])
  results[:iaf_nbr] = 1.0 + (0.069 * results[:iad_save] * (results[:rated_nbr] - 3.0))
  results[:iaf_ns] = (2.0 / results[:rated_nst])**(0.12 * results[:iad_save])
  results[:iaf_rh] = results[:iaf_cfa] * results[:iaf_nbr] * results[:iaf_ns]

  return results[:iaf_rh]
end

def all_fuels
  return @fuel_map.values
end

def non_elec_fuels
  return all_fuels - [FT::Elec]
end

def get_load(output, load_type)
  return output["Load: #{load_type}"]
end

def get_fuel_use(output, fuel_types, use_net: false)
  val = 0.0
  fuel_types = [fuel_types] unless fuel_types.is_a? Array
  fuel_types.each do |fuel_type|
    if use_net && fuel_type == FT::Elec
      val += output["Fuel Use: #{fuel_type}: Net"]
    else
      val += output["Fuel Use: #{fuel_type}: Total"]
    end
  end
  return val
end

def get_end_use(output, end_use_type, fuel_types)
  val = 0.0
  fuel_types = [fuel_types] unless fuel_types.is_a? Array
  fuel_types.each do |fuel_type|
    val += output["End Use: #{fuel_type}: #{end_use_type}"]
  end
  return val
end

def get_system_use(output, sys_id, fuel, type)
  val = output["System Use: #{sys_id}: #{fuel}: #{type}"].to_f
  # Add fan/pump energy as appropriate
  if ['Heating', 'Cooling', 'Heating Heat Pump Backup'].include? type
    val += output["System Use: #{sys_id}: #{FT::Elec}: #{type} Fans/Pumps"].to_f
  elsif ['Hot Water'].include? type
    val += output["System Use: #{sys_id}: #{FT::Elec}: #{type} Recirc Pump"].to_f
    val += output["System Use: #{sys_id}: #{FT::Elec}: #{type} Solar Thermal Pump"].to_f
  end
  return val
end

def get_emissions_co2e(output, fuel = nil)
  if fuel.nil?
    return output['Emissions: CO2e: RESNET: Net']
  elsif fuel == FT::Elec
    return output["Emissions: CO2e: RESNET: #{fuel}: Net"]
  else
    return output["Emissions: CO2e: RESNET: #{fuel}: Total"]
  end
end

def calculate_eri_component_precond(rated_output, rated_sys, type)
  c = ERIComponent.new
  c.rated_id = rated_sys.id
  fuel = get_fuel(rated_sys, type)
  c.ec_x = calculate_ec(rated_output, c.rated_id, fuel, type)
  c.reul = 1.0 # Arbitrary; doesn't affect results
  c.coeff_a, c.coeff_b = get_coefficients(fuel, type)
  c.eec_x = get_eec(rated_sys, type)
  c.dse_r = 0.80 # DSE of Reference Home for space conditioning
  c.ec_r = c.reul / c.eec_x / c.dse_r
  c.nec_x = (c.coeff_a * c.eec_x - c.coeff_b) * (c.ec_x * c.ec_r * c.dse_r) / (c.eec_x * c.reul)
  c.nmeul = c.reul * (c.nec_x / c.ec_r)
  return c
end

def calculate_eri_component(rated_output, ref_output, rated_sys, ref_sys, load_frac, type, is_dfhp_primary = nil, whf_energy: nil)
  # is_dfhp_primary = true: The HP portion of the dual-fuel heat pump
  # is_dfhp_primary = false: The backup portion of the dual-fuel heat pump
  c = ERIComponent.new
  c.rated_id = rated_sys.id
  c.ref_id = ref_sys.id
  c.load_frac = load_frac
  c.reul = calculate_reul(ref_output, c.load_frac, type, is_dfhp_primary)
  ref_fuel = get_fuel(ref_sys, type, is_dfhp_primary)
  rated_fuel = get_fuel(rated_sys, type, is_dfhp_primary)
  c.coeff_a, c.coeff_b = get_coefficients(ref_fuel, type)
  c.eec_x = get_eec(rated_sys, type, is_dfhp_primary)
  c.eec_r = get_eec(ref_sys, type, is_dfhp_primary)
  c.is_dual_fuel = is_dfhp_primary
  c.ec_x = calculate_ec(rated_output, c.rated_id, rated_fuel, type, is_dfhp_primary)
  c.ec_r = calculate_ec(ref_output, c.ref_id, ref_fuel, type, is_dfhp_primary, load_frac)
  c.dse_r = c.reul / c.ec_r * c.eec_r
  c.nec_x = 0
  if c.eec_x * c.reul > 0
    c.nec_x = (c.coeff_a * c.eec_x - c.coeff_b) * (c.ec_x * c.ec_r * c.dse_r) / (c.eec_x * c.reul)
  end
  if not whf_energy.nil?
    # Add whole-house fan energy to nec_x per 301 (apportioned by load) and excluded from eul_la
    c.nec_x += (whf_energy * c.load_frac)
  end
  c.nmeul = 0
  if c.ec_r > 0
    c.nmeul = c.reul * (c.nec_x / c.ec_r)
  end
  return c
end

def calculate_reul(output, load_frac, type, is_dfhp_primary = nil)
  if type == 'Heating'
    load_delivered = LT::Heating
    load_hp_backup = LT::HeatingHeatPumpBackup
  elsif type == 'Cooling'
    load_delivered = LT::Cooling
  elsif type == 'Hot Water'
    load_delivered = LT::HotWaterDelivered
  end
  if is_dfhp_primary.nil?
    # Get total load
    load = get_load(output, load_delivered)
  elsif is_dfhp_primary
    # Get HP portion of DFHP
    load = (get_load(output, load_delivered) -
            get_load(output, load_hp_backup))
  else
    # Get backup port of DFHP
    load = get_load(output, load_hp_backup)
  end
  return load * load_frac
end

def calculate_ec(output, sys_id, fuel, type, is_dfhp_primary = nil, load_frac = nil)
  fuel = @fuel_map[fuel]
  if is_dfhp_primary.nil?
    # Get total system use
    ec = get_system_use(output, sys_id, fuel, type) +
         get_system_use(output, sys_id, fuel, "#{type} Heat Pump Backup")
  elsif is_dfhp_primary
    # Get HP portion of DFHP
    ec = get_system_use(output, sys_id, fuel, type)
  else
    # Get backup port of DFHP
    ec = get_system_use(output, sys_id, fuel, "#{type} Heat Pump Backup")
  end
  if (type == 'Hot Water') && (not load_frac.nil?)
    # Only one reference water heater when there are multiple rated water heaters,
    # so multiply by the load fraction
    ec *= load_frac
  end
  return ec
end

def calculate_teu(output)
  # Total Energy Use
  # Fossil fuel site energy uses should be converted to equivalent electric energy use
  # in accordance with Equation 4.1-3. Note: Generator fuel consumption is included here.
  teu = get_fuel_use(output, FT::Elec) +
        0.4 * get_fuel_use(output, non_elec_fuels)
  return teu
end

def calculate_opp(renewable_energy_limit, renewable_elec_produced, generation_elec_produced, generation_fuel_consumed)
  # On-Site Power Production
  # Electricity produced minus equivalent electric energy use calculated in accordance
  # with Equation 4.1-3 of any purchased fossil fuels used to produce the power.
  if not renewable_energy_limit.nil?
    renewable_elec_produced = -1 * [-renewable_elec_produced, renewable_energy_limit].min
  end
  opp = -1 * (renewable_elec_produced + generation_elec_produced) - 0.4 * generation_fuel_consumed
  opp *= -1 if opp == -0
  return opp
end

def calculate_pefrac(teu, opp)
  pefrac = 1.0
  if teu > 0
    pefrac = (teu - opp) / teu
  end
  return pefrac
end

def calculate_la(output)
  return (get_end_use(output, EUT::LightsInterior, FT::Elec) +
          get_end_use(output, EUT::LightsExterior, FT::Elec) +
          get_end_use(output, EUT::LightsGarage, FT::Elec) +
          get_end_use(output, EUT::Refrigerator, FT::Elec) +
          get_end_use(output, EUT::Dishwasher, FT::Elec) +
          get_end_use(output, EUT::ClothesWasher, FT::Elec) +
          get_end_use(output, EUT::ClothesDryer, FT::Elec) +
          get_end_use(output, EUT::PlugLoads, FT::Elec) +
          get_end_use(output, EUT::Television, FT::Elec) +
          get_end_use(output, EUT::RangeOven, FT::Elec) +
          get_end_use(output, EUT::CeilingFan, FT::Elec) +
          get_end_use(output, EUT::ClothesDryer, non_elec_fuels) +
          get_end_use(output, EUT::RangeOven, non_elec_fuels))
end

def calculate_mv(output)
  return get_end_use(output, EUT::MechVent, FT::Elec)
end

def calculate_dh(output)
  return get_end_use(output, EUT::Dehumidifier, FT::Elec)
end

def _calculate_co2e_index(rated_output, ref_output, results_iad)
  # Check that CO2e Reference Home doesn't have fossil fuel use.
  if get_fuel_use(ref_output, non_elec_fuels) > 0
    fail 'CO2e Reference Home found with fossil fuel energy use.'
  end

  rated_bldg = rated_output['HPXML'].buildings[0]

  results = {}

  results[:rated_cfa] = rated_bldg.building_construction.conditioned_floor_area
  results[:rated_nbr] = rated_bldg.building_construction.number_of_bedrooms
  results[:rated_nst] = rated_bldg.building_construction.number_of_conditioned_floors_above_grade

  results[:aco2e] = get_emissions_co2e(rated_output)
  results[:arco2e] = get_emissions_co2e(ref_output)

  if (not results[:aco2e].nil?) && (not results[:arco2e].nil?)
    # Check if any fuel consumption without corresponding CO2e emissions.
    # This would represent a fuel type (e.g., wood) not covered by 301
    # emissions factors.
    all_fuels.each do |fuel|
      next unless get_fuel_use(rated_output, fuel) > 0
      next unless get_emissions_co2e(rated_output, fuel) == 0

      return results
    end

    results[:co2eindex] = results[:aco2e] / results[:arco2e] * 100.0

    # IAF was not in the initial calculation but has since been added
    iaf_rh = _calculate_iaf_rh(results, results_iad)
    results[:co2eindex] /= iaf_rh
  end
  return results
end

def calculate_eri(design_outputs, resultsdir, output_format, output_filename_prefix: nil, opp_reduction_limit: nil,
                  renewable_energy_limit: nil, skip_csv: false)
  if design_outputs.keys.include? Constants.CalcTypeERIIndexAdjustmentDesign
    results_iad = _calculate_eri(design_outputs[Constants.CalcTypeERIIndexAdjustmentDesign],
                                 design_outputs[Constants.CalcTypeERIIndexAdjustmentReferenceHome])
  else
    results_iad = nil
  end

  results = _calculate_eri(design_outputs[Constants.CalcTypeERIRatedHome],
                           design_outputs[Constants.CalcTypeERIReferenceHome],
                           results_iad: results_iad,
                           opp_reduction_limit: opp_reduction_limit,
                           renewable_energy_limit: renewable_energy_limit)

  if not skip_csv
    write_eri_results(results, resultsdir, design_outputs, results_iad, output_filename_prefix, output_format)
  end

  return results
end

def calculate_co2_index(design_outputs, resultsdir, output_format)
  results_iad = _calculate_eri(design_outputs[Constants.CalcTypeERIIndexAdjustmentDesign],
                               design_outputs[Constants.CalcTypeERIIndexAdjustmentReferenceHome])

  if design_outputs.keys.include? Constants.CalcTypeCO2eRatedHome
    results = _calculate_co2e_index(design_outputs[Constants.CalcTypeCO2eRatedHome],
                                    design_outputs[Constants.CalcTypeCO2eReferenceHome],
                                    results_iad)
  end

  write_co2_results(results, resultsdir, output_format)

  return results
end

def write_eri_results(results, resultsdir, design_outputs, results_iad, output_filename_prefix, output_format)
  ref_output = design_outputs[Constants.CalcTypeERIReferenceHome]

  output_filename_prefix = "#{output_filename_prefix}_" unless output_filename_prefix.nil?

  # ERI Results file
  results_csv = File.join(resultsdir, "#{output_filename_prefix}ERI_Results.#{output_format}")
  results_out = []
  results_out << ['ERI', results[:eri].round(2)]
  results_out << ['REUL Heating (MBtu)', results[:eri_heat].map { |c| c.reul.round(2) }.join(',')]
  results_out << ['REUL Cooling (MBtu)', results[:eri_cool].map { |c| c.reul.round(2) }.join(',')]
  results_out << ['REUL Hot Water (MBtu)', results[:eri_dhw].map { |c| c.reul.round(2) }.join(',')]
  results_out << ['EC_r Heating (MBtu)', results[:eri_heat].map { |c| c.ec_r.round(2) }.join(',')]
  results_out << ['EC_r Cooling (MBtu)', results[:eri_cool].map { |c| c.ec_r.round(2) }.join(',')]
  results_out << ['EC_r Hot Water (MBtu)', results[:eri_dhw].map { |c| c.ec_r.round(2) }.join(',')]
  results_out << ['EC_x Heating (MBtu)', results[:eri_heat].map { |c| c.ec_x.round(2) }.join(',')]
  results_out << ['EC_x Cooling (MBtu)', results[:eri_cool].map { |c| c.ec_x.round(2) }.join(',')]
  results_out << ['EC_x Hot Water (MBtu)', results[:eri_dhw].map { |c| c.ec_x.round(2) }.join(',')]
  results_out << ['EC_x L&A (MBtu)', results[:eul_la].round(2)]
  results_out << ['EC_x Vent (MBtu)', results[:eul_mv].round(2)]
  results_out << ['EC_x Dehumid (MBtu)', results[:eul_dh].round(2)]
  if not results_iad.nil?
    results_out << ['IAD_Save (%)', results[:iad_save].round(5)]
  end
  if output_format == 'csv'
    CSV.open(results_csv, 'wb') { |csv| results_out.to_a.each { |elem| csv << elem } }
  elsif output_format == 'json'
    File.open(results_csv, 'wb') { |json| json.write(JSON.pretty_generate(results_out.to_h)) }
  end

  # ERI Worksheet file
  worksheet_csv = File.join(resultsdir, "#{output_filename_prefix}ERI_Worksheet.#{output_format}")
  worksheet_out = []
  worksheet_out << ['Coeff Heating a', results[:eri_heat].map { |c| c.coeff_a.round(4) }.join(',')]
  worksheet_out << ['Coeff Heating b', results[:eri_heat].map { |c| c.coeff_b.round(4) }.join(',')]
  worksheet_out << ['Coeff Cooling a', results[:eri_cool].map { |c| c.coeff_a.round(4) }.join(',')]
  worksheet_out << ['Coeff Cooling b', results[:eri_cool].map { |c| c.coeff_b.round(4) }.join(',')]
  worksheet_out << ['Coeff Hot Water a', results[:eri_dhw].map { |c| c.coeff_a.round(4) }.join(',')]
  worksheet_out << ['Coeff Hot Water b', results[:eri_dhw].map { |c| c.coeff_b.round(4) }.join(',')]
  worksheet_out << ['DSE_r Heating', results[:eri_heat].map { |c| c.dse_r.round(4) }.join(',')]
  worksheet_out << ['DSE_r Cooling', results[:eri_cool].map { |c| c.dse_r.round(4) }.join(',')]
  worksheet_out << ['DSE_r Hot Water', results[:eri_dhw].map { |c| c.dse_r.round(4) }.join(',')]
  worksheet_out << ['EEC_x Heating', results[:eri_heat].map { |c| c.eec_x.round(4) }.join(',')]
  worksheet_out << ['EEC_x Cooling', results[:eri_cool].map { |c| c.eec_x.round(4) }.join(',')]
  worksheet_out << ['EEC_x Hot Water', results[:eri_dhw].map { |c| c.eec_x.round(4) }.join(',')]
  worksheet_out << ['EEC_r Heating', results[:eri_heat].map { |c| c.eec_r.round(4) }.join(',')]
  worksheet_out << ['EEC_r Cooling', results[:eri_cool].map { |c| c.eec_r.round(4) }.join(',')]
  worksheet_out << ['EEC_r Hot Water', results[:eri_dhw].map { |c| c.eec_r.round(4) }.join(',')]
  worksheet_out << ['nEC_x Heating', results[:eri_heat].map { |c| c.nec_x.round(4) }.join(',')]
  worksheet_out << ['nEC_x Cooling', results[:eri_cool].map { |c| c.nec_x.round(4) }.join(',')]
  worksheet_out << ['nEC_x Hot Water', results[:eri_dhw].map { |c| c.nec_x.round(4) }.join(',')]
  worksheet_out << ['nMEUL Heating', results[:eri_heat].map { |c| c.nmeul.round(4) }.join(',')]
  worksheet_out << ['nMEUL Cooling', results[:eri_cool].map { |c| c.nmeul.round(4) }.join(',')]
  worksheet_out << ['nMEUL Hot Water', results[:eri_dhw].map { |c| c.nmeul.round(4) }.join(',')]
  if results[:eri_vent_preheat].empty?
    worksheet_out << ['nMEUL Vent Preheat', 0.0]
  else
    worksheet_out << ['nMEUL Vent Preheat', results[:eri_vent_preheat].map { |c| c.nmeul.round(4) }.join(',')]
  end
  if results[:eri_vent_precool].empty?
    worksheet_out << ['nMEUL Vent Precool', 0.0]
  else
    worksheet_out << ['nMEUL Vent Precool', results[:eri_vent_precool].map { |c| c.nmeul.round(4) }.join(',')]
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
  worksheet_out << [nil] if output_format == 'csv' # line break
  worksheet_out << ['Ref Home CFA', results[:rated_cfa]]
  worksheet_out << ['Ref Home Nbr', results[:rated_nbr]]
  if not results_iad.nil?
    worksheet_out << ['Ref Home NS', results[:rated_nst]]
  end
  worksheet_out << ['Ref dehumid', results[:reul_dh].round(2)]
  worksheet_out << ['Ref L&A resMELs', get_end_use(ref_output, EUT::PlugLoads, FT::Elec).round(2)]
  worksheet_out << ['Ref L&A intLgt', (get_end_use(ref_output, EUT::LightsInterior, FT::Elec) +
                                       get_end_use(ref_output, EUT::LightsGarage, FT::Elec)).round(2)]
  worksheet_out << ['Ref L&A extLgt', get_end_use(ref_output, EUT::LightsExterior, FT::Elec).round(2)]
  worksheet_out << ['Ref L&A Fridg', get_end_use(ref_output, EUT::Refrigerator, FT::Elec).round(2)]
  worksheet_out << ['Ref L&A TVs', get_end_use(ref_output, EUT::Television, FT::Elec).round(2)]
  worksheet_out << ['Ref L&A R/O', get_end_use(ref_output, EUT::RangeOven, all_fuels).round(2)]
  worksheet_out << ['Ref L&A cDryer', get_end_use(ref_output, EUT::ClothesDryer, FT::Elec).round(2)]
  worksheet_out << ['Ref L&A dWash', get_end_use(ref_output, EUT::Dishwasher, FT::Elec).round(2)]
  worksheet_out << ['Ref L&A cWash', get_end_use(ref_output, EUT::ClothesWasher, FT::Elec).round(2)]
  worksheet_out << ['Ref L&A mechV', results[:reul_mv].round(2)]
  worksheet_out << ['Ref L&A ceilFan', get_end_use(ref_output, EUT::CeilingFan, FT::Elec).round(2)]
  worksheet_out << ['Ref L&A total', (results[:reul_la] + results[:reul_mv]).round(2)]
  if output_format == 'csv'
    CSV.open(worksheet_csv, 'wb') { |csv| worksheet_out.to_a.each { |elem| csv << elem } }
  elsif output_format == 'json'
    File.open(worksheet_csv, 'wb') { |json| json.write(JSON.pretty_generate(worksheet_out.to_h)) }
  end
end

def write_co2_results(results, resultsdir, output_format)
  # CO2e Results file
  if not results[:co2eindex].nil?
    results_csv = File.join(resultsdir, "CO2e_Results.#{output_format}")
    results_out = []
    results_out << ['CO2e Rating Index', results[:co2eindex].round(2)]
    results_out << ['ACO2 (lb CO2e)', results[:aco2e].round(2)]
    results_out << ['ARCO2 (lb CO2e)', results[:arco2e].round(2)]
    results_out << ['IAF RH', results[:iaf_rh].round(4)]
    if output_format == 'csv'
      CSV.open(results_csv, 'wb') { |csv| results_out.to_a.each { |elem| csv << elem } }
    elsif output_format == 'json'
      File.open(results_csv, 'wb') { |json| json.write(JSON.pretty_generate(results_out.to_h)) }
    end
  end
end

def write_es_zerh_results(ruleset, resultsdir, rd_eri_results, rated_eri_results, rated_eri_results_wo_opp, target_eri, saf, passes, output_format)
  # Even though pass/fail is calculated based on rounded integer ERIs,
  # we provide two decimal places here so that there's less possibility
  # for user confusion when comparing the actual/target ERIs.
  rd_eri = rd_eri_results[:eri].round(2)
  target_eri = target_eri.round(2)
  rated_eri = rated_eri_results[:eri].round(2)
  rated_wo_opp_eri = rated_eri_results_wo_opp[:eri].round(2)

  if ESConstants.AllVersions.include? ruleset
    program_abbreviation, program_name = 'ES', 'ENERGY STAR'
  elsif ZERHConstants.AllVersions.include? ruleset
    program_abbreviation, program_name = 'ZERH', 'Zero Energy Ready Home'
  end
  results_csv = File.join(resultsdir, "#{program_abbreviation}_Results.#{output_format}")
  results_out = []
  results_out << ['Reference Home ERI', rd_eri]

  if saf.nil?
    results_out << ['SAF (Size Adjustment Factor)', 'N/A']
  else
    results_out << ['SAF (Size Adjustment Factor)', saf.round(3)]
  end
  results_out << ['SAF Adjusted ERI Target', target_eri]
  results_out << [nil] if output_format == 'csv' # line break
  results_out << ['Rated Home ERI', rated_eri]
  results_out << ['Rated Home ERI w/o OPP', rated_wo_opp_eri]
  results_out << [nil] if output_format == 'csv' # line break
  if passes
    results_out << ["#{program_name} Certification", 'PASS']
  else
    results_out << ["#{program_name} Certification", 'FAIL']
  end
  if output_format == 'csv'
    CSV.open(results_csv, 'wb') { |csv| results_out.to_a.each { |elem| csv << elem } }
  elsif output_format == 'json'
    File.open(results_csv, 'wb') { |json| json.write(JSON.pretty_generate(results_out.to_h)) }
  end
end

def main(options)
  OpenStudio::Logger.instance.standardOutLogger.setLogLevel(OpenStudio::Fatal)

  # Setup directories
  unless Dir.exist?(options[:output_dir])
    FileUtils.mkdir_p(options[:output_dir])
  end
  resultsdir = File.join(options[:output_dir], 'results')
  rm_path(resultsdir)
  Dir.mkdir(resultsdir)

  puts "HPXML: #{options[:hpxml]}"
  hpxml_doc = XMLHelper.parse_file(options[:hpxml])
  eri_version, co2_version, es_version, iecc_version, zerh_version = get_program_versions(hpxml_doc)

  # Create list of designs
  designs = []
  if not eri_version.nil?
    # ERI designs
    designs << Design.new(calc_type: Constants.CalcTypeERIRatedHome, output_dir: options[:output_dir], output_format: options[:output_format])
    if not options[:rated_home_only]
      designs << Design.new(calc_type: Constants.CalcTypeERIReferenceHome, output_dir: options[:output_dir], output_format: options[:output_format])
      if Constants.ERIVersions.index(eri_version) >= Constants.ERIVersions.index('2014AE')
        # Add IAF designs
        designs << Design.new(calc_type: Constants.CalcTypeERIIndexAdjustmentDesign, output_dir: options[:output_dir], output_format: options[:output_format])
        designs << Design.new(calc_type: Constants.CalcTypeERIIndexAdjustmentReferenceHome, output_dir: options[:output_dir], output_format: options[:output_format])
      end
      if Constants.ERIVersions.index(eri_version) >= Constants.ERIVersions.index('2019ABCD')
      end
    end
  end
  if not co2_version.nil?
    if (not eri_version.nil?) && (eri_version != co2_version)
      fail 'ERI version and CO2 version must be the same.'
    end

    # Add CO2e designs
    designs << Design.new(calc_type: Constants.CalcTypeCO2eRatedHome, output_dir: options[:output_dir], output_format: options[:output_format])
    designs << Design.new(calc_type: Constants.CalcTypeCO2eReferenceHome, output_dir: options[:output_dir], output_format: options[:output_format])

    # Add IAF designs if we didn't already
    if designs.find { |d| d.calc_type == Constants.CalcTypeERIIndexAdjustmentDesign }.nil?
      designs << Design.new(calc_type: Constants.CalcTypeERIIndexAdjustmentDesign, output_dir: options[:output_dir], output_format: options[:output_format])
      designs << Design.new(calc_type: Constants.CalcTypeERIIndexAdjustmentReferenceHome, output_dir: options[:output_dir], output_format: options[:output_format])
    end
  end
  if not es_version.nil?
    # ENERGY STAR designs
    designs << Design.new(init_calc_type: ESConstants.CalcTypeEnergyStarReference, calc_type: Constants.CalcTypeERIRatedHome, output_dir: options[:output_dir], output_format: options[:output_format])
    designs << Design.new(init_calc_type: ESConstants.CalcTypeEnergyStarReference, calc_type: Constants.CalcTypeERIReferenceHome, output_dir: options[:output_dir], output_format: options[:output_format])
    designs << Design.new(init_calc_type: ESConstants.CalcTypeEnergyStarReference, calc_type: Constants.CalcTypeERIIndexAdjustmentDesign, output_dir: options[:output_dir], output_format: options[:output_format])
    designs << Design.new(init_calc_type: ESConstants.CalcTypeEnergyStarReference, calc_type: Constants.CalcTypeERIIndexAdjustmentReferenceHome, output_dir: options[:output_dir], output_format: options[:output_format])
    designs << Design.new(init_calc_type: ESConstants.CalcTypeEnergyStarRated, calc_type: Constants.CalcTypeERIRatedHome, output_dir: options[:output_dir], output_format: options[:output_format])
    designs << Design.new(init_calc_type: ESConstants.CalcTypeEnergyStarRated, calc_type: Constants.CalcTypeERIReferenceHome, output_dir: options[:output_dir], output_format: options[:output_format])
    designs << Design.new(init_calc_type: ESConstants.CalcTypeEnergyStarRated, calc_type: Constants.CalcTypeERIIndexAdjustmentDesign, output_dir: options[:output_dir], output_format: options[:output_format])
    designs << Design.new(init_calc_type: ESConstants.CalcTypeEnergyStarRated, calc_type: Constants.CalcTypeERIIndexAdjustmentReferenceHome, output_dir: options[:output_dir], output_format: options[:output_format])
  end
  if not iecc_version.nil?
    # IECC ERI designs
    designs << Design.new(iecc_version: iecc_version, calc_type: Constants.CalcTypeERIRatedHome, output_dir: options[:output_dir], output_format: options[:output_format])
    designs << Design.new(iecc_version: iecc_version, calc_type: Constants.CalcTypeERIReferenceHome, output_dir: options[:output_dir], output_format: options[:output_format])
    designs << Design.new(iecc_version: iecc_version, calc_type: Constants.CalcTypeERIIndexAdjustmentDesign, output_dir: options[:output_dir], output_format: options[:output_format])
    designs << Design.new(iecc_version: iecc_version, calc_type: Constants.CalcTypeERIIndexAdjustmentReferenceHome, output_dir: options[:output_dir], output_format: options[:output_format])
  end
  if not zerh_version.nil?
    # ENERGY STAR designs
    designs << Design.new(init_calc_type: ZERHConstants.CalcTypeZERHReference, calc_type: Constants.CalcTypeERIRatedHome, output_dir: options[:output_dir], output_format: options[:output_format])
    designs << Design.new(init_calc_type: ZERHConstants.CalcTypeZERHReference, calc_type: Constants.CalcTypeERIReferenceHome, output_dir: options[:output_dir], output_format: options[:output_format])
    designs << Design.new(init_calc_type: ZERHConstants.CalcTypeZERHReference, calc_type: Constants.CalcTypeERIIndexAdjustmentDesign, output_dir: options[:output_dir], output_format: options[:output_format])
    designs << Design.new(init_calc_type: ZERHConstants.CalcTypeZERHReference, calc_type: Constants.CalcTypeERIIndexAdjustmentReferenceHome, output_dir: options[:output_dir], output_format: options[:output_format])
    designs << Design.new(init_calc_type: ZERHConstants.CalcTypeZERHRated, calc_type: Constants.CalcTypeERIRatedHome, output_dir: options[:output_dir], output_format: options[:output_format])
    designs << Design.new(init_calc_type: ZERHConstants.CalcTypeZERHRated, calc_type: Constants.CalcTypeERIReferenceHome, output_dir: options[:output_dir], output_format: options[:output_format])
    designs << Design.new(init_calc_type: ZERHConstants.CalcTypeZERHRated, calc_type: Constants.CalcTypeERIIndexAdjustmentDesign, output_dir: options[:output_dir], output_format: options[:output_format])
    designs << Design.new(init_calc_type: ZERHConstants.CalcTypeZERHRated, calc_type: Constants.CalcTypeERIIndexAdjustmentReferenceHome, output_dir: options[:output_dir], output_format: options[:output_format])
  end

  if designs.size == 0
    puts 'No calculations requested.'
    exit!
  end

  duplicates = apply_rulesets_and_generate_hpxmls(designs, options)

  if not options[:skip_simulation]

    run_simulations(designs, options, duplicates)

    # For duplicate designs that weren't simulated, populate their output
    duplicate_output_files(duplicates, designs, resultsdir)

    puts 'Calculating results...'

    if (not eri_version.nil?) && (not options[:rated_home_only])
      # Calculate ERI
      eri_designs = designs.select { |d| d.init_calc_type.nil? && d.iecc_version.nil? }
      eri_designs = eri_designs.select { |d|
        [Constants.CalcTypeERIRatedHome,
         Constants.CalcTypeERIReferenceHome,
         Constants.CalcTypeERIIndexAdjustmentDesign,
         Constants.CalcTypeERIIndexAdjustmentReferenceHome].include? d.calc_type
      }
      eri_outputs = retrieve_design_outputs(eri_designs)

      # Calculate and write results
      eri_results = calculate_eri(eri_outputs, resultsdir, options[:output_format])
      puts "ERI: #{eri_results[:eri].round(2)}"
    end

    if not co2_version.nil?
      # Calculate CO2e Index
      co2_designs = designs.select { |d| d.init_calc_type.nil? && d.iecc_version.nil? }
      co2_designs = co2_designs.select { |d|
        [Constants.CalcTypeCO2eRatedHome,
         Constants.CalcTypeCO2eReferenceHome,
         Constants.CalcTypeERIIndexAdjustmentDesign,
         Constants.CalcTypeERIIndexAdjustmentReferenceHome].include? d.calc_type
      }
      co2_outputs = retrieve_design_outputs(co2_designs)

      # Calculate and write results
      co2_results = calculate_co2_index(co2_outputs, resultsdir, options[:output_format])
      if not co2_results[:co2eindex].nil?
        puts "CO2e Index: #{co2_results[:co2eindex].round(2)}"
      end
    end

    if not iecc_version.nil?
      # Calculate IECC ERI
      iecc_eri_designs = designs.select { |d| !d.iecc_version.nil? }
      iecc_eri_outputs = retrieve_design_outputs(iecc_eri_designs)

      renewable_energy_limit = calc_renewable_energy_limit(iecc_eri_outputs, iecc_version)

      # Calculate and write results
      iecc_eri_results = calculate_eri(iecc_eri_outputs, resultsdir, options[:output_format],
                                       output_filename_prefix: 'IECC', renewable_energy_limit: renewable_energy_limit)
      puts "IECC ERI: #{iecc_eri_results[:eri].round(2)}"
    end

    if not es_version.nil?
      # Calculate ES Reference ERI
      esrd_eri_designs = designs.select { |d| d.init_calc_type == ESConstants.CalcTypeEnergyStarReference }
      esrd_eri_outputs = retrieve_design_outputs(esrd_eri_designs)
      esrd_eri_results = calculate_eri(esrd_eri_outputs, resultsdir, options[:output_format],
                                       output_filename_prefix: ESConstants.CalcTypeEnergyStarReference.gsub(' ', ''))

      # Calculate Size-Adjusted ERI for Energy Star Reference Homes
      saf = get_saf(esrd_eri_results, es_version, options[:hpxml])
      target_eri = esrd_eri_results[:eri] * saf

      # Calculate ES Rated ERI, w/ On-site Power Production (OPP) restriction as appropriate
      opp_reduction_limit = calc_opp_eri_limit(esrd_eri_results[:eri], saf, es_version)
      rated_eri_designs = designs.select { |d| d.init_calc_type == ESConstants.CalcTypeEnergyStarRated }
      rated_eri_outputs = retrieve_design_outputs(rated_eri_designs)
      rated_eri_results = calculate_eri(rated_eri_outputs, resultsdir, options[:output_format],
                                        output_filename_prefix: ESConstants.CalcTypeEnergyStarRated.gsub(' ', ''), opp_reduction_limit: opp_reduction_limit)

      if rated_eri_results[:eri].round(0) <= target_eri.round(0)
        passes = true
      else
        passes = false
      end

      # Calculate ES Rated ERI w/o OPP for extra information
      rated_eri_results_wo_opp = calculate_eri(rated_eri_outputs, resultsdir, options[:output_format], skip_csv: true, opp_reduction_limit: 0.0)

      write_es_zerh_results(es_version, resultsdir, esrd_eri_results, rated_eri_results, rated_eri_results_wo_opp, target_eri, saf, passes, options[:output_format])

      if passes
        puts 'ENERGY STAR Certification: PASS'
      else
        puts 'ENERGY STAR Certification: FAIL'
      end
    end

    if not zerh_version.nil?
      # Calculate ZERH Reference ERI
      zerhrd_eri_designs = designs.select { |d| d.init_calc_type == ZERHConstants.CalcTypeZERHReference }
      zerhrd_eri_outputs = retrieve_design_outputs(zerhrd_eri_designs)
      zerhrd_eri_results = calculate_eri(zerhrd_eri_outputs, resultsdir, options[:output_format],
                                         output_filename_prefix: ZERHConstants.CalcTypeZERHReference.gsub(' ', ''))

      # Calculate Size-Adjusted ERI for ZERH Reference Homes
      saf = get_saf(zerhrd_eri_results, zerh_version, options[:hpxml])
      target_eri = zerhrd_eri_results[:eri] * saf

      # Calculate ZERH Rated ERI
      opp_reduction_limit = calc_opp_eri_limit(zerhrd_eri_results[:eri], saf, zerh_version)
      rated_eri_designs = designs.select { |d| d.init_calc_type == ZERHConstants.CalcTypeZERHRated }
      rated_eri_outputs = retrieve_design_outputs(rated_eri_designs)
      rated_eri_results = calculate_eri(rated_eri_outputs, resultsdir, options[:output_format],
                                        output_filename_prefix: ZERHConstants.CalcTypeZERHRated.gsub(' ', ''), opp_reduction_limit: opp_reduction_limit)

      if rated_eri_results[:eri].round(0) <= target_eri.round(0)
        passes = true
      else
        passes = false
      end

      # Calculate ZERH Rated ERI w/o OPP for extra information
      rated_eri_results_wo_opp = calculate_eri(rated_eri_outputs, resultsdir, options[:output_format], skip_csv: true, opp_reduction_limit: 0.0)

      write_es_zerh_results(zerh_version, resultsdir, zerhrd_eri_results, rated_eri_results, rated_eri_results_wo_opp, target_eri, saf, passes, options[:output_format])

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

timeseries_types = ['ALL', 'total', 'fuels', 'enduses', 'systemuses', 'emissions', 'emissionfuels',
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

  options[:output_format] = 'csv'
  opts.on('--output-format TYPE', ['csv', 'json'], 'Output file format type (csv, json)') do |t|
    options[:output_format] = t
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
