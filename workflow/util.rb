# frozen_string_literal: true

def setup_resultsdir(options)
  unless Dir.exist?(options[:output_dir])
    FileUtils.mkdir_p(options[:output_dir])
  end

  # Create results dir
  resultsdir = File.join(options[:output_dir], 'results')
  rm_path(resultsdir)
  Dir.mkdir(resultsdir)

  return resultsdir
end

def process_arguments(calling_rb, args, basedir)
  timeseries_types = ['ALL', 'fuels', 'enduses', 'hotwater', 'loads', 'componentloads', 'temperatures', 'airflows', 'weather']

  options = {}
  OptionParser.new do |opts|
    opts.banner = "Usage: #{calling_rb} -x building.xml\n e.g., #{calling_rb} -x sample_files/base.xml\n"

    opts.on('-x', '--xml <FILE.xml>', 'HPXML file') do |t|
      options[:hpxml] = t
    end

    opts.on('-o', '--output-dir <DIR>', 'Output directory') do |t|
      options[:output_dir] = t
    end

    options[:hourly_outputs] = []
    opts.on('--hourly TYPE', timeseries_types, "Request hourly output type (#{timeseries_types[0..4].join(', ')},", "#{timeseries_types[5..-1].join(', ')}); can be called multiple times") do |t|
      options[:hourly_outputs] << t
    end

    options[:daily_outputs] = []
    opts.on('--daily TYPE', timeseries_types, "Request daily output type (#{timeseries_types[0..4].join(', ')},", "#{timeseries_types[5..-1].join(', ')}); can be called multiple times") do |t|
      options[:daily_outputs] << t
    end

    options[:monthly_outputs] = []
    opts.on('--monthly TYPE', timeseries_types, "Request monthly output type (#{timeseries_types[0..4].join(', ')},", "#{timeseries_types[5..-1].join(', ')}); can be called multiple times") do |t|
      options[:monthly_outputs] << t
    end

    opts.on('-w', '--download-weather', 'Downloads all US TMY3 weather files') do |t|
      options[:epws] = t
    end

    opts.on('-c', '--cache-weather', 'Caches all weather files') do |t|
      options[:cache] = t
    end

    options[:add_comp_loads] = false
    opts.on('--add-component-loads', 'Add heating/cooling component loads calculation') do |t|
      options[:add_comp_loads] = true
    end

    options[:debug] = false
    opts.on('-d', '--debug') do |t|
      options[:debug] = true
    end

    options[:version] = false
    opts.on('-v', '--version', 'Reports the workflow version') do |t|
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
    fail 'Multiple timeseries frequencies (hourly, daily, monthly) are not supported.'
  end

  if options[:timeseries_outputs].include? 'ALL'
    options[:timeseries_outputs] = timeseries_types[1..-1]
  end
  if options[:version]
    workflow_version = '1.3.0'
    puts "OpenStudio-ERI v#{workflow_version}"
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
    fail "HPXML argument is required. Call #{File.basename(__FILE__)} -h for usage."
  end

  unless (Pathname.new options[:hpxml]).absolute?
    options[:hpxml] = File.expand_path(options[:hpxml])
  end
  unless File.exist?(options[:hpxml]) && options[:hpxml].downcase.end_with?('.xml')
    fail "'#{options[:hpxml]}' does not exist or is not an .xml file."
  end

  if options[:output_dir].nil?
    options[:output_dir] = basedir # default
  end
  options[:output_dir] = File.expand_path(options[:output_dir])

  return options
end

def run_simulations(runs, options, basedir)
  # Run simulations
  puts "HPXML: #{options[:hpxml]}"
  if Process.respond_to?(:fork) # e.g., most Unix systems

    # Code runs in forked child processes and makes direct calls. This is the fastest
    # approach but isn't available on, e.g., Windows.

    def kill
      raise Parallel::Kill
    end

    Parallel.map(runs, in_processes: runs.size) do |run|
      output_hpxml_path, designdir = run_design_direct(basedir, run, options[:hpxml], options[:debug],
                                                       options[:timeseries_output_freq], options[:timeseries_outputs],
                                                       options[:add_comp_loads])
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
    Parallel.map(runs, in_threads: runs.size) do |run|
      output_hpxml_path, designdir, pids[run] = run_design_spawn(basedir, run, options[:hpxml], options[:debug],
                                                                 options[:timeseries_output_freq], options[:timeseries_outputs],
                                                                 options[:add_comp_loads])
      Process.wait pids[run]
      if not File.exist? File.join(designdir, 'eplusout.end')
        kill(pids)
        next
      end
    end

  end
end

def run_design_direct(basedir, run, hpxml, debug, timeseries_output_freq, timeseries_outputs, add_comp_loads)
  # Calls design.rb methods directly. Should only be called from a forked
  # process. This is the fastest approach.
  designdir = get_design_dir(run)
  timeseries_output_freq, timeseries_outputs = timeseries_output_for_run(run, timeseries_output_freq, timeseries_outputs)

  output_hpxml_path = run_design(basedir, run, hpxml, debug, timeseries_output_freq, timeseries_outputs, add_comp_loads)

  return output_hpxml_path, designdir
end

def run_design_spawn(basedir, run, hpxml, debug, timeseries_output_freq, timeseries_outputs, add_comp_loads)
  # Calls design.rb in a new spawned process in order to utilize multiple
  # processes. Not as efficient as calling design.rb methods directly in
  # forked processes for a couple reasons:
  # 1. There is overhead to using the CLI
  # 2. There is overhead to spawning processes vs using forked processes
  designdir = get_design_dir(run)
  output_hpxml_path = get_output_filename(run)
  timeseries_output_freq, timeseries_outputs = timeseries_output_for_run(run, timeseries_output_freq, timeseries_outputs)

  cli_path = OpenStudio.getOpenStudioCLI
  pid = Process.spawn("\"#{cli_path}\" \"#{File.join(File.dirname(__FILE__), 'design.rb')}\" \"#{basedir}\" \"#{run.join('|')}\" \"#{hpxml}\" #{debug} \"#{timeseries_output_freq}\" \"#{timeseries_outputs.join('|')}\" \"#{add_comp_loads}\"")

  return output_hpxml_path, designdir, pid
end

def timeseries_output_for_run(run, timeseries_output_freq, timeseries_outputs)
  if [Constants.CalcTypeERIRatedHome, Constants.CalcTypeERIReferenceHome].include? run[0]
    return timeseries_output_freq, timeseries_outputs
  end

  return 'none', []
end

def retrieve_outputs(runs, options)
  # Retrieve outputs for ERI calculations
  design_outputs = {}
  runs.each do |run|
    runkey = run[0]

    designdir = get_design_dir(run)
    csv_path = get_output_filename(run, '_ERI.csv')

    if not File.exist? csv_path
      puts 'Errors encountered. Aborting...'
      exit!
    end

    design_outputs[runkey] = {}

    csv_data = CSV.read(csv_path, headers: false)
    csv_data.each do |data|
      next if data.empty?

      key = data[0]
      key = key.gsub('enduseElectricity', 'elec')
      key = key.gsub('enduseNaturalGas', 'gas')
      key = key.gsub('enduseFuelOil', 'oil')
      key = key.gsub('endusePropane', 'propane')
      key = key.gsub('enduseWoodCord', 'woodcord')
      key = key.gsub('enduseWoodPellets', 'woodpellets')

      design_outputs[runkey][key.to_sym] = eval(data[1])
    end

    File.delete(csv_path) if not options[:debug]
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
  results[:rated_cfa] = rated_output[:hpxml_cfa]
  results[:rated_nbr] = rated_output[:hpxml_nbr]
  results[:rated_facility_type] = rated_output[:hpxml_residential_facility_type]

  # =========================== #
  # Ventilation Preconditioning #
  # =========================== #

  # Calculate independent nMEUL for ventilation preconditioning

  reul_precond = 1.0 # Arbitrary; doesn't affect results

  results[:nmeul_vent_preheat] = []
  rated_output[:hpxml_vent_preheat_sys_ids].each_with_index do |sys_id, rated_idx|
    ec_x_preheat = rated_output[:elecMechVentPreheating][rated_idx] + rated_output[:gasMechVentPreheating][rated_idx] + rated_output[:oilMechVentPreheating][rated_idx] + rated_output[:propaneMechVentPreheating][rated_idx] + rated_output[:woodcordMechVentPreheating][rated_idx] + rated_output[:woodpelletsMechVentPreheating][rated_idx]
    coeff_preheat_a, coeff_preheat_b = get_heating_coefficients(rated_output[:hpxml_vent_preheat_fuels][rated_idx])
    eec_x_preheat = rated_output[:hpxml_eec_vent_preheats][rated_idx]
    dse_r_preheat = 0.80 # DSE of Reference Home for space heating
    ec_r_preheat = reul_precond / eec_x_preheat / dse_r_preheat
    nEC_x_preheat = (coeff_preheat_a * eec_x_preheat - coeff_preheat_b) * (ec_x_preheat * ec_r_preheat * dse_r_preheat) / (eec_x_preheat * reul_precond)
    results[:nmeul_vent_preheat] << reul_precond * (nEC_x_preheat / ec_r_preheat)
  end

  results[:nmeul_vent_precool] = []
  rated_output[:hpxml_vent_precool_sys_ids].each_with_index do |sys_id, rated_idx|
    ec_x_precool = rated_output[:elecMechVentPrecooling][rated_idx]
    coeff_precool_a, coeff_precool_b = get_cooling_coefficients()
    eec_x_precool = rated_output[:hpxml_eec_vent_precools][rated_idx]
    dse_r_precool = 0.80 # DSE of Reference Home for space cooling
    ec_r_precool = reul_precond / eec_x_precool / dse_r_precool
    nEC_x_precool = (coeff_precool_a * eec_x_precool - coeff_precool_b) * (ec_x_precool * ec_r_precool * dse_r_precool) / (eec_x_precool * reul_precond)
    results[:nmeul_vent_precool] << reul_precond * (nEC_x_precool / ec_r_precool)
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

  rated_output[:hpxml_heat_sys_ids].each_with_index do |sys_id, rated_idx|
    ref_idx = ref_output[:hpxml_heat_sys_ids].index(sys_id)
    fail 'Data not in sync.' if ref_idx.nil?

    reul_heat = ref_output[:loadHeatingDelivered][ref_idx]

    if (ref_output[:hpxml_heat_fuels][ref_idx] == HPXML::FuelTypeElectricity) != (rated_output[:hpxml_heat_fuels][rated_idx] == HPXML::FuelTypeElectricity)
      fail 'Data not in sync.'
    end

    coeff_heat_a, coeff_heat_b = get_heating_coefficients(ref_output[:hpxml_heat_fuels][ref_idx])

    eec_x_heat = rated_output[:hpxml_eec_heats][rated_idx]
    eec_r_heat = ref_output[:hpxml_eec_heats][ref_idx]

    ec_x_heat = rated_output[:elecHeating][rated_idx] + rated_output[:elecHeatingFansPumps][rated_idx] + rated_output[:gasHeating][rated_idx] + rated_output[:oilHeating][rated_idx] + rated_output[:propaneHeating][rated_idx] + rated_output[:woodcordHeating][rated_idx] + rated_output[:woodpelletsHeating][rated_idx]
    ec_r_heat = ref_output[:elecHeating][ref_idx] + ref_output[:elecHeatingFansPumps][ref_idx] + ref_output[:gasHeating][ref_idx] + ref_output[:oilHeating][ref_idx] + ref_output[:propaneHeating][ref_idx] + ref_output[:woodcordHeating][ref_idx] + ref_output[:woodpelletsHeating][ref_idx]

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

  tot_reul_cool = ref_output[:loadCoolingDelivered].sum(0.0)
  rated_output[:hpxml_cool_sys_ids].each_with_index do |sys_id, rated_idx|
    ref_idx = ref_output[:hpxml_cool_sys_ids].index(sys_id)
    fail 'Data not in sync.' if ref_idx.nil?

    reul_cool = ref_output[:loadCoolingDelivered][ref_idx]

    coeff_cool_a, coeff_cool_b = get_cooling_coefficients()

    eec_x_cool = rated_output[:hpxml_eec_cools][rated_idx]
    eec_r_cool = ref_output[:hpxml_eec_cools][ref_idx]

    ec_x_cool = rated_output[:elecCooling][rated_idx] + rated_output[:elecCoolingFansPumps][rated_idx]
    ec_r_cool = ref_output[:elecCooling][ref_idx] + ref_output[:elecCoolingFansPumps][ref_idx]

    dse_r_cool = reul_cool / ec_r_cool * eec_r_cool

    nec_x_cool = 0
    if eec_x_cool * reul_cool > 0
      nec_x_cool = (coeff_cool_a * eec_x_cool - coeff_cool_b) * (ec_x_cool * ec_r_cool * dse_r_cool) / (eec_x_cool * reul_cool)
    end
    # Add whole-house fan energy to nec_x_cool per 301 (apportioned by load) and excluded from eul_la
    nec_x_cool += (rated_output[:elecWholeHouseFan] * reul_cool / tot_reul_cool)

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
  if ref_output[:loadHotWaterDelivered].size != 1
    fail 'Unexpected Reference Home results; should only be 1 DHW system.'
  end

  reul_dhw = ref_output[:loadHotWaterDelivered][0]

  coeff_dhw_a, coeff_dhw_b = get_dhw_coefficients(ref_output[:hpxml_dwh_fuels][0])

  eec_x_dhw = rated_output[:hpxml_eec_dhws].sum(0.0)
  eec_r_dhw = ref_output[:hpxml_eec_dhws][0]

  ec_x_dhw = rated_output[:elecHotWater].sum(0.0) + rated_output[:gasHotWater].sum(0.0) + rated_output[:oilHotWater].sum(0.0) + rated_output[:propaneHotWater].sum(0.0) + rated_output[:woodcordHotWater].sum(0.0) + rated_output[:woodpelletsHotWater].sum(0.0) + rated_output[:elecHotWaterRecircPump].sum(0.0) + rated_output[:elecHotWaterSolarThermalPump].sum(0.0)
  ec_r_dhw = ref_output[:elecHotWater][0] + ref_output[:gasHotWater][0] + ref_output[:oilHotWater][0] + ref_output[:propaneHotWater][0] + ref_output[:woodcordHotWater][0] + ref_output[:woodpelletsHotWater][0] + ref_output[:elecHotWaterRecircPump][0] + ref_output[:elecHotWaterSolarThermalPump][0]

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

  # ===== #
  # Other #
  # ===== #

  # Total Energy Use
  # Fossil fuel site energy uses should be converted to equivalent electric energy use
  # in accordance with Equation 4.1-3. Note: Generator fuel consumption is included here.
  results[:teu] = rated_output[:fuelElectricity] + 0.4 * (rated_output[:fuelNaturalGas] + rated_output[:fuelFuelOil] + rated_output[:fuelPropane] + rated_output[:fuelWoodCord] + rated_output[:fuelWoodPellets])

  # On-Site Power Production
  # Electricity produced minus equivalent electric energy use calculated in accordance
  # with Equation 4.1-3 of any purchased fossil fuels used to produce the power.
  results[:opp] = -1 * (rated_output[:elecPV] + rated_output[:elecGenerator]) - 0.4 * (rated_output[:gasGenerator] + rated_output[:oilGenerator] + rated_output[:propaneGenerator] + rated_output[:woodcordGenerator] + rated_output[:woodpelletsGenerator])

  results[:pefrac] = 1.0
  if results[:teu] > 0
    results[:pefrac] = (results[:teu] - results[:opp]) / results[:teu]
  end

  results[:eul_dh] = rated_output[:elecDehumidifier]
  results[:eul_la] = (rated_output[:elecLightingInterior] + rated_output[:elecLightingExterior] +
                      rated_output[:elecLightingGarage] + rated_output[:elecRefrigerator] +
                      rated_output[:elecDishwasher] + rated_output[:elecClothesWasher] +
                      rated_output[:elecClothesDryer] + rated_output[:elecPlugLoads] +
                      rated_output[:elecTelevision] + rated_output[:elecRangeOven] +
                      rated_output[:elecCeilingFan] + rated_output[:elecMechVent] +
                      rated_output[:gasClothesDryer] + rated_output[:gasRangeOven] +
                      rated_output[:oilClothesDryer] + rated_output[:oilRangeOven] +
                      rated_output[:propaneClothesDryer] + rated_output[:propaneRangeOven] +
                      rated_output[:woodcordClothesDryer] + rated_output[:woodcordRangeOven] +
                      rated_output[:woodpelletsClothesDryer] + rated_output[:woodpelletsRangeOven])

  results[:reul_dh] = ref_output[:elecDehumidifier]
  results[:reul_la] = (ref_output[:elecLightingInterior] + ref_output[:elecLightingExterior] +
                       ref_output[:elecLightingGarage] + ref_output[:elecRefrigerator] +
                       ref_output[:elecDishwasher] + ref_output[:elecClothesWasher] +
                       ref_output[:elecClothesDryer] + ref_output[:elecPlugLoads] +
                       ref_output[:elecTelevision] + ref_output[:elecRangeOven] +
                       ref_output[:elecCeilingFan] + ref_output[:elecMechVent] +
                       ref_output[:gasClothesDryer] + ref_output[:gasRangeOven] +
                       ref_output[:oilClothesDryer] + ref_output[:oilRangeOven] +
                       ref_output[:propaneClothesDryer] + ref_output[:propaneRangeOven] +
                       ref_output[:woodcordClothesDryer] + ref_output[:woodcordRangeOven] +
                       ref_output[:woodpelletsClothesDryer] + ref_output[:woodpelletsRangeOven])

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

    results[:iaf_cfa] = (2400.0 / rated_output[:hpxml_cfa])**(0.304 * results[:iad_save])
    results[:iaf_nbr] = 1.0 + (0.069 * results[:iad_save] * (rated_output[:hpxml_nbr] - 3.0))
    results[:iaf_ns] = (2.0 / rated_output[:hpxml_nst])**(0.12 * results[:iad_save])
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

def calculate_eri(design_outputs, resultsdir, opp_reduction_limit: nil)
  if design_outputs.size == 4
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

  write_results(results, resultsdir, design_outputs, results_iad)

  return results
end

def write_results(results, resultsdir, design_outputs, results_iad)
  ref_output = design_outputs[Constants.CalcTypeERIReferenceHome]

  # Results file
  results_csv = File.join(resultsdir, 'ERI_Results.csv')
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

  # Worksheet file
  worksheet_csv = File.join(resultsdir, 'ERI_Worksheet.csv')
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
  worksheet_out << ['Ref Home CFA', ref_output[:hpxml_cfa]]
  worksheet_out << ['Ref Home Nbr', ref_output[:hpxml_nbr]]
  if not results_iad.nil?
    worksheet_out << ['Ref Home NS', ref_output[:hpxml_nst]]
  end
  worksheet_out << ['Ref dehumid', results[:reul_dh].round(2)]
  worksheet_out << ['Ref L&A resMELs', ref_output[:elecPlugLoads].round(2)]
  worksheet_out << ['Ref L&A intLgt', (ref_output[:elecLightingInterior] + ref_output[:elecLightingGarage]).round(2)]
  worksheet_out << ['Ref L&A extLgt', ref_output[:elecLightingExterior].round(2)]
  worksheet_out << ['Ref L&A Fridg', ref_output[:elecRefrigerator].round(2)]
  worksheet_out << ['Ref L&A TVs', ref_output[:elecTelevision].round(2)]
  worksheet_out << ['Ref L&A R/O', (ref_output[:elecRangeOven] + ref_output[:gasRangeOven] + ref_output[:oilRangeOven] + ref_output[:propaneRangeOven] + ref_output[:woodcordRangeOven] + ref_output[:woodpelletsRangeOven]).round(2)]
  worksheet_out << ['Ref L&A cDryer', (ref_output[:elecClothesDryer] + ref_output[:gasClothesDryer] + ref_output[:oilClothesDryer] + ref_output[:propaneClothesDryer] + ref_output[:woodcordClothesDryer] + ref_output[:woodpelletsClothesDryer]).round(2)]
  worksheet_out << ['Ref L&A dWash', ref_output[:elecDishwasher].round(2)]
  worksheet_out << ['Ref L&A cWash', ref_output[:elecClothesWasher].round(2)]
  worksheet_out << ['Ref L&A mechV', ref_output[:elecMechVent].round(2)]
  worksheet_out << ['Ref L&A ceilFan', ref_output[:elecCeilingFan].round(2)]
  worksheet_out << ['Ref L&A total', results[:reul_la].round(2)]
  CSV.open(worksheet_csv, 'wb') { |csv| worksheet_out.to_a.each { |elem| csv << elem } }
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
