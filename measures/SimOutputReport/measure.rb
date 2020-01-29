# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/reference/measure_writing_guide/

require_relative "../HPXMLtoOpenStudio/resources/constants.rb"
require_relative "../HPXMLtoOpenStudio/resources/unit_conversions.rb"

# start the measure
class SimOutputReport < OpenStudio::Measure::ReportingMeasure
  # human readable name
  def name
    # Measure name should be the title case of the class name.
    return 'Sim Output Report'
  end

  # human readable description
  def description
    return 'Reports simulation outputs for residential HPXML-based models.'
  end

  # human readable description of modeling approach
  def modeler_description
    return 'Processes EnergyPlus simulation outputs in order to generate an annual output CSV file and an optional timeseries output CSV file.'
  end

  # define the arguments that the user will input
  def arguments(ignore = nil)
    args = OpenStudio::Measure::OSArgumentVector.new

    timeseries_frequency_chs = OpenStudio::StringVector.new
    reporting_frequency_map.keys.each do |freq|
      timeseries_frequency_chs << freq
    end
    arg = OpenStudio::Measure::OSArgument::makeChoiceArgument("timeseries_frequency", timeseries_frequency_chs, true)
    arg.setDisplayName("Timeseries Reporting Frequency")
    arg.setDescription("The frequency at which to report timeseries output data.")
    arg.setDefaultValue("hourly")
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeBoolArgument("timeseries_output_zone_temperatures", true)
    arg.setDisplayName("Generate Timeseries Output: Zone Temperatures")
    arg.setDescription("Generates timeseries temperatures for each thermal zone.")
    arg.setDefaultValue(false)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeBoolArgument("timeseries_output_fuel_consumptions", true)
    arg.setDisplayName("Generate Timeseries Output: Fuel Consumptions")
    arg.setDescription("Generates timeseries energy consumptions for each fuel type.")
    arg.setDefaultValue(false)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeBoolArgument("timeseries_output_end_use_consumptions", true)
    arg.setDisplayName("Generate Timeseries Output: End Use Consumptions")
    arg.setDescription("Generates timeseries energy consumptions for each end use.")
    arg.setDefaultValue(false)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeBoolArgument("timeseries_output_total_loads", true)
    arg.setDisplayName("Generate Timeseries Output: Total Loads")
    arg.setDescription("Generates timeseries heating/cooling loads.")
    arg.setDefaultValue(false)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeBoolArgument("timeseries_output_component_loads", true)
    arg.setDisplayName("Generate Timeseries Output: Component Loads")
    arg.setDescription("Generates timeseries heating/cooling loads disaggregated by component type.")
    arg.setDefaultValue(false)
    args << arg

    return args
  end

  # define the outputs that the measure will create
  def outputs
    outs = OpenStudio::Measure::OSOutputVector.new

    setup_outputs

    output_names = []
    @fuels.each do |fuel_type, fuel|
      output_names << fuel.annual_name
    end
    @end_uses.each do |key, end_use|
      output_names << end_use.annual_name
    end

    output_names.each do |output_name|
      outs << OpenStudio::Measure::OSOutput.makeDoubleOutput(output_name)
    end

    return outs
  end

  # return a vector of IdfObject's to request EnergyPlus objects needed by the run method
  def energyPlusOutputRequests(runner, user_arguments)
    super(runner, user_arguments)

    result = OpenStudio::IdfObjectVector.new

    # use the built-in error checking
    if !runner.validateUserArguments(arguments, user_arguments)
      return result
    end

    # get the last model and sql file
    model = runner.lastOpenStudioModel.get

    setup_outputs

    # Get a few things from the model
    hvac_map, dhw_map = get_object_maps(model)
    loads_program = nil
    model.getEnergyManagementSystemPrograms.each do |program|
      next unless program.name.to_s.start_with? Constants.ObjectNameComponentLoads.gsub(' ', '_')

      loads_program = program
    end

    # Annual outputs

    # Add meters to increase precision of outputs relative to, e.g., ABUPS report
    meters = []
    @fuels.each do |fuel_type, fuel|
      meters << fuel.meter
    end
    @end_uses.each do |key, end_use|
      meters << end_use.meter
    end
    @total_loads.each do |load_type, load|
      meters << load.meter
    end
    meters.push(*unmet_loads_meter_map.values)
    meters.each do |meter|
      next if meter.nil?

      result << OpenStudio::IdfObject.load("Output:Meter,#{meter},runperiod;").get
    end

    # Add peak electricity outputs
    peak_elec_report_map.each do |output_name, report_name|
      if output_name.downcase.include? "winter"
        meter = "Heating:EnergyTransfer"
      elsif output_name.downcase.include? "summer"
        meter = "Cooling:EnergyTransfer"
      end
      monthly_array = ["Output:Table:Monthly",
                       report_name,
                       "2",
                       meter,
                       "HoursPositive",
                       "Electricity:Facility",
                       "MaximumDuringHoursShown"]
      result << OpenStudio::IdfObject.load("#{monthly_array.join(",").to_s};").get
    end

    # Add component load outputs
    ["htg", "clg"].each do |mode|
      OutputVars.ComponentLoadsMap.each do |component, component_var|
        result << OpenStudio::IdfObject.load("EnergyManagementSystem:OutputVariable,#{mode}_#{component_var}_annual_outvar,#{mode}_#{component_var},Summed,ZoneTimestep,#{loads_program.name},J;").get
        result << OpenStudio::IdfObject.load("Output:Variable,*,#{mode}_#{component_var}_annual_outvar,runperiod;").get
      end
    end

    # Add individual HVAC/DHW system variables
    add_object_output_variables(model, hvac_map, dhw_map, 'runperiod').each do |outvar|
      result << outvar
    end

    # Timeseries outputs?
    timeseries_frequency = runner.getStringArgumentValue("timeseries_frequency", user_arguments)

    timeseries_output_zone_temperatures = runner.getBoolArgumentValue("timeseries_output_zone_temperatures", user_arguments)
    if timeseries_output_zone_temperatures
      result << OpenStudio::IdfObject.load("Output:Variable,*,Zone Mean Air Temperature,#{timeseries_frequency};").get
    end

    timeseries_output_fuel_consumptions = runner.getBoolArgumentValue("timeseries_output_fuel_consumptions", user_arguments)
    if timeseries_output_fuel_consumptions
      @fuels.each do |fuel_type, fuel|
        result << OpenStudio::IdfObject.load("Output:Meter,#{fuel.meter},#{timeseries_frequency};").get
      end
    end

    timeseries_output_end_use_consumptions = runner.getBoolArgumentValue("timeseries_output_end_use_consumptions", user_arguments)
    if timeseries_output_end_use_consumptions
      @end_uses.each do |key, end_use|
        next if end_use.meter.nil?

        result << OpenStudio::IdfObject.load("Output:Meter,#{end_use.meter},#{timeseries_frequency};").get
      end
      # Add output variables for individual HVAC/DHW systems
      add_object_output_variables(model, hvac_map, dhw_map, timeseries_frequency).each do |outvar|
        result << outvar
      end
    end

    timeseries_output_total_loads = runner.getBoolArgumentValue("timeseries_output_total_loads", user_arguments)
    if timeseries_output_total_loads
      # FIXME: This needs to be updated when the new component loads algorithm is merged
      @total_loads.each do |load_type, load|
        next if load.meter.nil?

        result << OpenStudio::IdfObject.load("Output:Meter,#{load.meter},#{timeseries_frequency};").get
      end
    end

    timeseries_output_component_loads = runner.getBoolArgumentValue("timeseries_output_component_loads", user_arguments)
    if timeseries_output_component_loads
      ["htg", "clg"].each do |mode|
        OutputVars.ComponentLoadsMap.each do |component, component_var|
          result << OpenStudio::IdfObject.load("EnergyManagementSystem:OutputVariable,#{mode}_#{component_var}_timeseries_outvar,#{mode}_#{component_var},Summed,ZoneTimestep,#{loads_program.name},J;").get
          result << OpenStudio::IdfObject.load("Output:Variable,*,#{mode}_#{component_var}_timeseries_outvar,#{timeseries_frequency};").get
        end
      end
    end

    return result
  end

  # define what happens when the measure is run
  def run(runner, user_arguments)
    super(runner, user_arguments)

    # use the built-in error checking
    if !runner.validateUserArguments(arguments, user_arguments)
      return false
    end

    timeseries_frequency = runner.getStringArgumentValue("timeseries_frequency", user_arguments)
    timeseries_output_zone_temperatures = runner.getBoolArgumentValue("timeseries_output_zone_temperatures", user_arguments)
    timeseries_output_fuel_consumptions = runner.getBoolArgumentValue("timeseries_output_fuel_consumptions", user_arguments)
    timeseries_output_end_use_consumptions = runner.getBoolArgumentValue("timeseries_output_end_use_consumptions", user_arguments)
    timeseries_output_total_loads = runner.getBoolArgumentValue("timeseries_output_total_loads", user_arguments)
    timeseries_output_component_loads = runner.getBoolArgumentValue("timeseries_output_component_loads", user_arguments)

    # get the last model and sql file
    model = runner.lastOpenStudioModel
    if model.empty?
      runner.registerError("Cannot find last model.")
      return false
    end
    model = model.get

    sqlFile = runner.lastEnergyPlusSqlFile
    if sqlFile.empty?
      runner.registerError("Cannot find last sql file.")
      return false
    end
    @sqlFile = sqlFile.get
    model.setSqlFile(@sqlFile)

    setup_outputs

    hpxml_path = model.getBuilding.additionalProperties.getFeatureAsString("hpxml_path").get
    @hpxml_doc = XMLHelper.parse_file(hpxml_path)
    output_dir = File.dirname(hpxml_path)

    # Error Checking
    @tolerance = 0.1 # MMBtu

    hvac_map, dhw_map = get_object_maps(model)

    # Set paths
    @eri_design = XMLHelper.get_value(@hpxml_doc, "/HPXML/SoftwareInfo/extension/ERICalculation/Design")
    if not @eri_design.nil?
      design_name = @eri_design.gsub(' ', '')
      summary_output_csv_path = File.join(output_dir, "#{design_name}.csv")
      eri_output_csv_path = File.join(output_dir, "#{design_name}_ERI.csv")
      timeseries_output_csv_path = File.join(output_dir, "#{design_name}_#{timeseries_frequency}.csv")
    else
      summary_output_csv_path = File.join(output_dir, "results.csv")
      eri_output_csv_path = nil
      timeseries_output_csv_path = File.join(output_dir, "results_timeseries.csv")
    end

    @timeseries_size = { 'hourly' => 8760,
                         'daily' => 365,
                         'timestep' => model.getTimestep.numberOfTimestepsPerHour * 8760 }[timeseries_frequency]
    fail "Unexpected timeseries_frequency: #{timeseries_frequency}." if @timeseries_size.nil?

    # Retrieve and write outputs
    outputs = get_outputs(hvac_map, dhw_map, model, timeseries_frequency,
                          timeseries_output_zone_temperatures,
                          timeseries_output_fuel_consumptions,
                          timeseries_output_end_use_consumptions,
                          timeseries_output_total_loads,
                          timeseries_output_component_loads)
    if not check_for_errors(runner, outputs)
      return false
    end
    if not write_annual_output_results(runner, outputs, summary_output_csv_path)
      return false
    end

    report_sim_outputs(outputs, runner)
    write_eri_output_results(outputs, eri_output_csv_path)
    write_timeseries_output_results(runner, timeseries_output_csv_path, timeseries_frequency)

    return true
  end

  def get_outputs(hvac_map, dhw_map, model, timeseries_frequency,
                  timeseries_output_zone_temperatures,
                  timeseries_output_fuel_consumptions,
                  timeseries_output_end_use_consumptions,
                  timeseries_output_total_loads,
                  timeseries_output_component_loads)
    outputs = {}

    # HPXML Summary
    bldg_details = @hpxml_doc.elements["/HPXML/Building/BuildingDetails"]
    outputs[:hpxml_cfa] = Float(XMLHelper.get_value(bldg_details, "BuildingSummary/BuildingConstruction/ConditionedFloorArea"))
    outputs[:hpxml_nbr] = Float(XMLHelper.get_value(bldg_details, "BuildingSummary/BuildingConstruction/NumberofBedrooms"))
    outputs[:hpxml_nst] = Float(XMLHelper.get_value(bldg_details, "BuildingSummary/BuildingConstruction/NumberofConditionedFloorsAboveGrade"))

    # HPXML Systems
    set_hpxml_systems()
    outputs[:hpxml_eec_heats] = get_hpxml_eec_heats()
    outputs[:hpxml_eec_cools] = get_hpxml_eec_cools()
    outputs[:hpxml_eec_dhws] = get_hpxml_eec_dhws()
    outputs[:hpxml_heat_sys_ids] = outputs[:hpxml_eec_heats].keys
    outputs[:hpxml_cool_sys_ids] = outputs[:hpxml_eec_cools].keys
    outputs[:hpxml_dhw_sys_ids] = outputs[:hpxml_eec_dhws].keys
    outputs[:hpxml_dse_heats] = get_hpxml_dse_heats(outputs[:hpxml_heat_sys_ids])
    outputs[:hpxml_dse_cools] = get_hpxml_dse_cools(outputs[:hpxml_cool_sys_ids])
    outputs[:hpxml_heat_fuels] = get_hpxml_heat_fuels()
    outputs[:hpxml_dwh_fuels] = get_hpxml_dhw_fuels()

    # Fuel Uses
    @fuels.each do |fuel_type, fuel|
      fuel.annual_output = get_report_meter_data_annual_mbtu(fuel.meter)
      if timeseries_output_fuel_consumptions
        fuel.timeseries_output = get_report_meter_data_timeseries("", fuel.meter, fuel.timeseries_unit_conv, 0, timeseries_frequency)
      end
    end

    # Peak Electricity Consumption
    peak_elec_report_map.each do |output_name, report_name|
      outputs[output_name] = get_tabular_data_value(report_name.upcase, "Meter", "Custom Monthly Report", "Maximum of Months", "ELECTRICITY:FACILITY {MAX FOR HOURS SHOWN", "W")
    end

    # Total loads (total heating/cooling energy delivered including backup ideal air system)
    @total_loads.each do |load_type, load|
      next if load.meter.nil?

      load.annual_output = get_report_meter_data_annual_mbtu(load.meter)
      if timeseries_output_total_loads
        # FIXME: This needs to be updated when the new component loads algorithm is merged
        load.timeseries_output = get_report_meter_data_timeseries("", load.meter, load.timeseries_unit_conv, 0, timeseries_frequency)
      end
    end

    # Component Loads
    { "Heating" => "htg", "Cooling" => "clg" }.each do |mode, mode_var|
      OutputVars.ComponentLoadsMap.each do |component, component_var|
        load_type = "#{mode}: #{component}"
        @component_loads[load_type].annual_output = get_report_variable_data_annual_mbtu(["EMS"], ["#{mode_var}_#{component_var}_annual_outvar"])
        if timeseries_output_component_loads
          @component_loads[load_type].timeseries_output = get_report_variable_data_timeseries(["EMS"], ["#{mode_var}_#{component_var}_timeseries_outvar"], UnitConversions.convert(1.0, 'J', 'kBtu'), 0, timeseries_frequency)
        end
      end
    end

    # Unmet loads (heating/cooling energy delivered by backup ideal air system)
    unmet_loads_meter_map.each do |output_name, meter|
      outputs[output_name] = get_report_meter_data_annual_mbtu(meter)
    end

    # Peak Building Space Heating/Cooling Loads (total heating/cooling energy delivered including backup ideal air system)
    peak_loads_meter_map.each do |output_name, meter|
      outputs[output_name] = UnitConversions.convert(get_tabular_data_value("EnergyMeters", "Entire Facility", "Annual and Peak Values - Other", meter, "Maximum Value", "W"), "Wh", "kBtu")
    end

    # End Uses (derived from meters)
    @end_uses.each do |key, end_use|
      next if end_use.meter.nil?

      fuel_type, end_use_type = key
      end_use.annual_output = get_report_meter_data_annual_mbtu(end_use.meter)
      if end_use_type == EUT_PV and @end_uses[key].annual_output > 0
        end_use.annual_output *= -1.0
      end
      if timeseries_output_end_use_consumptions
        end_use.timeseries_output = get_report_meter_data_timeseries("", end_use.meter, end_use.timeseries_unit_conv, 0, timeseries_frequency)
      end
    end

    # Space Heating (by System)
    dfhp_loads = get_dfhp_loads(outputs, hvac_map) # Calculate dual-fuel heat pump load
    outputs[:hpxml_heat_sys_ids].each do |sys_id|
      ep_output_names, dfhp_primary, dfhp_backup = get_ep_output_names_for_hvac_heating(hvac_map, sys_id)
      keys = ep_output_names.map(&:upcase)

      @end_uses.each do |key, end_use|
        fuel_type, end_use_type = key
        next unless [EUT_Heating].include? end_use_type
        next if end_use.variable.nil?

        vars = get_all_var_keys(end_use.variable)

        end_use.annual_output_by_system[sys_id] = get_report_variable_data_annual_mbtu(keys, vars)
        if timeseries_output_end_use_consumptions
          end_use.timeseries_output_by_system[sys_id] = get_report_variable_data_timeseries(keys, vars, end_use.timeseries_unit_conv, 0, timeseries_frequency)
        end

        if fuel_type == FT_Elec
          # Disaggregated Fan/Pump Energy Use
          end_use.annual_output_by_system[sys_id] += get_report_variable_data_annual_mbtu(["EMS"], ep_output_names.select { |name| name.end_with? Constants.ObjectNameFanPumpDisaggregatePrimaryHeat or name.end_with? Constants.ObjectNameFanPumpDisaggregateBackupHeat })
          if timeseries_output_end_use_consumptions
            timeseries_output = get_report_variable_data_timeseries(["EMS"], ep_output_names.select { |name| name.end_with? Constants.ObjectNameFanPumpDisaggregatePrimaryHeat or name.end_with? Constants.ObjectNameFanPumpDisaggregateBackupHeat }, end_use.timeseries_unit_conv, 0, timeseries_frequency)
            end_use.timeseries_output_by_system[sys_id] = sum_elements_in_arrays(end_use.timeseries_output_by_system[sys_id], timeseries_output)
          end
        end

        # Apply DSE
        apply_multiplier(end_use, @fuels[fuel_type], sys_id, 1.0 / outputs[:hpxml_dse_heats][sys_id])
      end

      # Reference Load
      if [Constants.CalcTypeERIReferenceHome, Constants.CalcTypeERIIndexAdjustmentReferenceHome].include? @eri_design
        @total_loads[LT_HeatingTotal].annual_output_by_system[sys_id] = split_htg_load_to_system_by_fraction(sys_id, @total_loads[LT_HeatingTotal].annual_output, dfhp_loads)
      end
    end

    # Space Cooling (by System)
    outputs[:hpxml_cool_sys_ids].each do |sys_id|
      ep_output_names = get_ep_output_names_for_hvac_cooling(hvac_map, sys_id)
      keys = ep_output_names.map(&:upcase)

      @end_uses.each do |key, end_use|
        fuel_type, end_use_type = key
        next unless [EUT_Cooling].include? end_use_type
        next if end_use.variable.nil?

        vars = get_all_var_keys(end_use.variable)

        end_use.annual_output_by_system[sys_id] = get_report_variable_data_annual_mbtu(keys, vars)
        if timeseries_output_end_use_consumptions
          end_use.timeseries_output_by_system[sys_id] = get_report_variable_data_timeseries(keys, vars, end_use.timeseries_unit_conv, 0, timeseries_frequency)
        end

        if fuel_type == FT_Elec
          # Disaggregated Fan/Pump Energy Use
          end_use.annual_output_by_system[sys_id] += get_report_variable_data_annual_mbtu(["EMS"], ep_output_names.select { |name| name.end_with? Constants.ObjectNameFanPumpDisaggregateCool })
          if timeseries_output_end_use_consumptions
            timeseries_output = get_report_variable_data_timeseries(["EMS"], ep_output_names.select { |name| name.end_with? Constants.ObjectNameFanPumpDisaggregateCool }, end_use.timeseries_unit_conv, 0, timeseries_frequency)
            end_use.timeseries_output_by_system[sys_id] = sum_elements_in_arrays(end_use.timeseries_output_by_system[sys_id], timeseries_output)
          end
        end

        # Apply DSE
        apply_multiplier(end_use, @fuels[fuel_type], sys_id, 1.0 / outputs[:hpxml_dse_cools][sys_id])
      end

      # Reference Load
      if [Constants.CalcTypeERIReferenceHome, Constants.CalcTypeERIIndexAdjustmentReferenceHome].include? @eri_design
        @total_loads[LT_CoolingTotal].annual_output_by_system[sys_id] = split_clg_load_to_system_by_fraction(sys_id, @total_loads[LT_CoolingTotal].annual_output)
      end
    end

    # Water Heating (by System)
    solar_keys = nil
    outputs[:hpxml_dhw_sys_ids].each do |sys_id|
      ep_output_names = get_ep_output_names_for_water_heating(dhw_map, sys_id)
      keys = ep_output_names.map(&:upcase)

      @end_uses.each do |key, end_use|
        fuel_type, end_use_type = key
        next unless [EUT_HotWater, EUT_HotWaterRecircPump, EUT_HotWaterSolarThermalPump].include? end_use_type
        next if end_use.variable.nil?

        vars = get_all_var_keys(end_use.variable)

        end_use.annual_output_by_system[sys_id] = get_report_variable_data_annual_mbtu(keys, vars)
        if timeseries_output_end_use_consumptions
          end_use.timeseries_output_by_system[sys_id] = get_report_variable_data_timeseries(keys, vars, end_use.timeseries_unit_conv, 0, timeseries_frequency)
        end
      end

      @total_loads.each do |load_type, load|
        next unless [LT_HotWaterDelivered].include? load_type
        next if load.variable.nil?

        load.annual_output_by_system[sys_id] = get_report_variable_data_annual_mbtu(keys, get_all_var_keys(load.variable))
      end

      # Hot Water Load - Desuperheater
      @total_loads[LT_HotWaterDesuperheater].annual_output = get_report_variable_data_annual_mbtu(["EMS"], ep_output_names.select { |name| name.include? Constants.ObjectNameDesuperheaterLoad(nil) })

      # Hot Water Load - Solar Thermal
      solar_keys = ep_output_names.select { |name| name.include? Constants.ObjectNameSolarHotWater }.map(&:upcase)
      @total_loads[LT_HotWaterSolarThermal].annual_output = get_report_variable_data_annual_mbtu(solar_keys, get_all_var_keys(OutputVars.WaterHeaterLoadSolarThermal))

      # Apply solar fraction to load for simple solar water heating systems
      solar_fraction = get_dhw_solar_fraction(sys_id)
      if solar_fraction > 0
        apply_multiplier(@total_loads[LT_HotWaterDelivered], @total_loads[LT_HotWaterSolarThermal], sys_id, 1.0 / (1.0 - solar_fraction))
      end

      # Combi boiler water system
      # FIXME: Need to implement
      # hvac_id = get_combi_hvac_id(sys_id)
      # if not hvac_id.nil?
      #  hx_load = -1 * get_report_variable_data_annual_mbtu(keys, get_all_var_keys(OutputVars.WaterHeatingCombiBoilerHeatExchanger))
      #  htg_load = get_report_variable_data_annual_mbtu(keys, get_all_var_keys(OutputVars.WaterHeatingCombiBoiler))
      #
      #  # Split combi boiler system energy use by water system load fraction
      #  htg_ec_elec = outputs[BySystemEndUseElecHeating][hvac_id]
      #  htg_ec_gas = outputs[BySystemEndUseGasHeating][hvac_id]
      #  htg_ec_oil = outputs[BySystemEndUseOilHeating][hvac_id]
      #  htg_ec_propane = outputs[BySystemEndUsePropaneHeating][hvac_id]
      #
      #  { BySystemEndUseElecHotWater => [BySystemEndUseElecHeating, FuelElec],
      #    BySystemEndUseGasHotWater => [BySystemEndUseGasHeating, FuelGas],
      #    BySystemEndUseOilHotWater => [BySystemEndUseOilHeating, FuelOil],
      #    BySystemEndUsePropaneHotWater => [BySystemEndUsePropaneHeating, FuelPropane] }.each do |hotWaterBySystem, vals|
      #    htg_ec = outputs[vals[0]][hvac_id]
      #    outputs[hotWaterBySystem][sys_id] += get_combi_water_system_ec(hx_load, htg_load, htg_ec) * outputs[:hpxml_dse_heats][hvac_id] # revert DSE for hot water results
      #    outputs[vals[0]][hvac_id] -= get_combi_water_system_ec(hx_load, htg_load, htg_ec)
      #    outputs[vals[1]] -= get_combi_water_system_ec(hx_load, htg_load, htg_ec) * (1.0 - outputs[:hpxml_dse_heats][hvac_id])
      #  end
      # end

      # EC adjustment
      ec_adj = get_report_variable_data_annual_mbtu(["EMS"], ep_output_names.select { |name| name.include? Constants.ObjectNameWaterHeaterAdjustment(nil) })

      # Desuperheater adjustment
      desuperheater_adj = get_report_variable_data_annual_mbtu(["EMS"], ep_output_names.select { |name| name.include? Constants.ObjectNameDesuperheaterEnergy(nil) })

      # Adjust water heater/appliances energy consumptions for above adjustments
      tot_adj = ec_adj + desuperheater_adj
      @end_uses.each do |key, end_use|
        fuel_type, end_use_type = key
        next unless [EUT_HotWater].include? end_use_type
        next if end_use.variable.nil?
        next unless end_use.annual_output_by_system[sys_id] > 0

        end_use.annual_output_by_system[sys_id] += tot_adj
        if timeseries_output_end_use_consumptions
          end_use.timeseries_output_by_system[sys_id] = sum_elements_in_arrays(end_use.timeseries_output_by_system[sys_id], [tot_adj] * @timeseries_size)
        end
      end
    end

    # Hot Water Load - Tank Losses (excluding solar storage tank)
    @total_loads[LT_HotWaterTankLosses].annual_output = get_report_variable_data_annual_mbtu(solar_keys, ["Water Heater Heat Loss Energy"], not_key: true)
    @total_loads[LT_HotWaterTankLosses].annual_output *= -1.0 if @total_loads[LT_HotWaterTankLosses].annual_output < 0

    # Calculate aggregated values from per-system values as needed
    (@end_uses.values + @total_loads.values).each do |obj|
      if obj.annual_output.nil? and not obj.annual_output_by_system.empty?
        obj.annual_output = obj.annual_output_by_system.values.inject(0, :+)
      end
      if obj.timeseries_output.empty? and not obj.timeseries_output_by_system.empty?
        obj.timeseries_output = sum_elements_in_arrays(*obj.timeseries_output_by_system.values)
      end
    end

    if timeseries_output_zone_temperatures
      zone_names = []
      model.getThermalZones.each do |zone|
        if zone.floorArea > 1
          zone_names << zone.name.to_s.upcase
        end
      end
      zone_names.sort.each do |zone_name|
        @zone_temps[zone_name] = ZoneTemp.new
        @zone_temps[zone_name].timeseries_name = "#{zone_name.split.map(&:capitalize).join(' ')} Temperature (F)"
        @zone_temps[zone_name].timeseries_output = get_report_variable_data_timeseries([zone_name], ["Zone Mean Air Temperature"], 9.0 / 5.0, 32.0, timeseries_frequency)
      end
    end

    return outputs
  end

  def check_for_errors(runner, outputs)
    all_total = @fuels.values.map { |f| f.annual_output }.inject(:+)
    if all_total == 0
      runner.registerError("Processing output unsuccessful.")
      return false
    end

    @fuels.keys.each do |fuel_type|
      sum_categories = @end_uses.select { |k, eu| k[0] == fuel_type }.map { |k, eu| eu.annual_output }.inject(:+)
      fuel_total = @fuels[fuel_type].annual_output
      if fuel_type == FT_Elec
        fuel_total += @end_uses[[FT_Elec, EUT_PV]].annual_output
      end
      if (fuel_total - sum_categories).abs > @tolerance
        runner.registerError("#{fuel_type} category end uses (#{sum_categories}) do not sum to total (#{fuel_total}).")
        return false
      end
    end

    # REUL check: system cooling/heating sum to total bldg load
    # FIXME: Add aggregate vs by_system checks across all outputs
    if [Constants.CalcTypeERIReferenceHome, Constants.CalcTypeERIIndexAdjustmentReferenceHome].include? @eri_design
      [LT_HeatingTotal, LT_CoolingTotal].each do |load_type|
        sum_sys_load = @total_loads[load_type].annual_output_by_system.values.inject(:+)
        total_load = @total_loads[load_type].annual_output
        if (sum_sys_load - total_load).abs > @tolerance
          runner.registerError("System loads (#{sum_sys_load}) do not sum to total building heating load #{total_load}.")
          return false
        end
      end
    end

    return true
  end

  def write_annual_output_results(runner, outputs, csv_path)
    line_break = nil
    pv_end_use = @end_uses[[FT_Elec, EUT_PV]]

    results_out = []
    @fuels.each do |fuel_type, fuel|
      results_out << [fuel.annual_name, fuel.annual_output.round(2)]
      if fuel_type == FT_Elec
        results_out << ["Electricity: Net (MBtu)", (fuel.annual_output + pv_end_use.annual_output).round(2)] # TODO
      end
    end
    results_out << [line_break]
    @end_uses.each do |key, end_use|
      results_out << [end_use.annual_name, end_use.annual_output.round(2)]
    end
    results_out << [line_break]
    @total_loads.each do |load_type, load|
      results_out << [load.annual_name, load.annual_output.round(2)]
    end
    results_out << [line_break]
    unmet_loads_meter_map.keys.each do |output_name|
      results_out << ["#{output_name} (MBtu)", outputs[output_name].round(2)]
    end
    results_out << [line_break]
    peak_elec_report_map.keys.each do |output_name|
      results_out << ["#{output_name} (W)", outputs[output_name].round(2)]
    end
    results_out << [line_break]
    peak_loads_meter_map.keys.each do |output_name|
      results_out << ["#{output_name} (kBtu)", outputs[output_name].round(2)]
    end
    results_out << [line_break]
    @component_loads.each do |load_type, load|
      results_out << [load.annual_name, load.annual_output.round(2)]
    end

    CSV.open(csv_path, "wb") { |csv| results_out.to_a.each { |elem| csv << elem } }
    runner.registerInfo("Wrote annual output results to #{csv_path}.")

    # Check results are internally consistent
    total_results = { "Electricity" => (@fuels[FT_Elec].annual_output + pv_end_use.annual_output).round(2),
                      "Natural Gas" => @fuels[FT_Gas].annual_output.round(2),
                      "Fuel Oil" => @fuels[FT_Oil].annual_output.round(2),
                      "Propane" => @fuels[FT_Propane].annual_output.round(2) }

    sum_end_use_results = {}
    results_out.each do |var, value|
      next if var.nil?

      fuel, enduse = var.split(": ")
      next if enduse.start_with? "Total " or enduse.start_with? "Net "

      sum_end_use_results[fuel] = 0.0 if sum_end_use_results[fuel].nil?
      sum_end_use_results[fuel] += value
    end
    for fuel in total_results.keys
      if (total_results[fuel] - sum_end_use_results[fuel]).abs > 0.1
        runner.registerError("End uses (#{sum_end_use_results[fuel].round(2)}) do not sum to #{fuel} total (#{total_results[fuel].round(2)})).")
        return false
      end
    end

    return true
  end

  def report_sim_outputs(outputs, runner)
    @fuels.each do |fuel_type, fuel|
      runner.registerValue(fuel.annual_name, fuel.annual_output.round(2))
      runner.registerInfo("Registering #{fuel.annual_output.round(2)} for #{fuel.annual_name}.")
    end
    @end_uses.each do |key, end_use|
      runner.registerValue(end_use.annual_name, end_use.annual_output.round(2))
      runner.registerInfo("Registering #{end_use.annual_output.round(2)} for #{end_use.annual_name}.")
    end
  end

  def write_eri_output_results(outputs, csv_path)
    return true if csv_path.nil?

    def get_hash_values_in_order(keys, output)
      vals = []
      keys.each do |key|
        vals << output[key]
      end
      return vals
    end

    line_break = nil

    results_out = []

    # Heating
    keys = outputs[:hpxml_heat_sys_ids]
    results_out << ["hpxml_heat_sys_ids"] + keys
    results_out << ["hpxml_heat_fuels"] + get_hash_values_in_order(keys, outputs[:hpxml_heat_fuels])
    results_out << ["hpxml_eec_heats"] + get_hash_values_in_order(keys, outputs[:hpxml_eec_heats])
    results_out << ["elecHeatingBySystem"] + get_hash_values_in_order(keys, @end_uses[[FT_Elec, EUT_Heating]].annual_output_by_system)
    results_out << ["gasHeatingBySystem"] + get_hash_values_in_order(keys, @end_uses[[FT_Gas, EUT_Heating]].annual_output_by_system)
    results_out << ["oilHeatingBySystem"] + get_hash_values_in_order(keys, @end_uses[[FT_Oil, EUT_Heating]].annual_output_by_system)
    results_out << ["propaneHeatingBySystem"] + get_hash_values_in_order(keys, @end_uses[[FT_Propane, EUT_Heating]].annual_output_by_system)
    results_out << ["loadHeatingBySystem"] + get_hash_values_in_order(keys, @total_loads[LT_HeatingTotal].annual_output_by_system)
    results_out << [line_break]

    # Cooling
    keys = outputs[:hpxml_cool_sys_ids]
    results_out << ["hpxml_cool_sys_ids"] + keys
    results_out << ["hpxml_eec_cools"] + get_hash_values_in_order(keys, outputs[:hpxml_eec_cools])
    results_out << ["elecCoolingBySystem"] + get_hash_values_in_order(keys, @end_uses[[FT_Elec, EUT_Cooling]].annual_output_by_system)
    results_out << ["loadCoolingBySystem"] + get_hash_values_in_order(keys, @total_loads[LT_CoolingTotal].annual_output_by_system)
    results_out << [line_break]

    # DHW
    keys = outputs[:hpxml_dhw_sys_ids]
    results_out << ["hpxml_dhw_sys_ids"] + keys
    results_out << ["hpxml_dwh_fuels"] + get_hash_values_in_order(keys, outputs[:hpxml_dwh_fuels])
    results_out << ["hpxml_eec_dhws"] + get_hash_values_in_order(keys, outputs[:hpxml_eec_dhws])
    results_out << ["elecHotWaterBySystem"] + get_hash_values_in_order(keys, @end_uses[[FT_Elec, EUT_HotWater]].annual_output_by_system)
    results_out << ["elecHotWaterRecircPumpBySystem"] + get_hash_values_in_order(keys, @end_uses[[FT_Elec, EUT_HotWaterRecircPump]].annual_output_by_system)
    results_out << ["elecHotWaterSolarThermalPumpBySystem"] + get_hash_values_in_order(keys, @end_uses[[FT_Elec, EUT_HotWaterSolarThermalPump]].annual_output_by_system)
    results_out << ["gasHotWaterBySystem"] + get_hash_values_in_order(keys, @end_uses[[FT_Gas, EUT_HotWater]].annual_output_by_system)
    results_out << ["oilHotWaterBySystem"] + get_hash_values_in_order(keys, @end_uses[[FT_Oil, EUT_HotWater]].annual_output_by_system)
    results_out << ["propaneHotWaterBySystem"] + get_hash_values_in_order(keys, @end_uses[[FT_Propane, EUT_HotWater]].annual_output_by_system)
    results_out << ["loadHotWaterBySystem"] + get_hash_values_in_order(keys, @total_loads[LT_HotWaterDelivered].annual_output_by_system)
    results_out << [line_break]

    # Total
    results_out << ["elecTotal", @fuels[FT_Elec].annual_output]
    results_out << ["gasTotal", @fuels[FT_Gas].annual_output]
    results_out << ["oilTotal", @fuels[FT_Oil].annual_output]
    results_out << ["propaneTotal", @fuels[FT_Propane].annual_output]
    results_out << ["elecPV", @end_uses[[FT_Elec, EUT_PV]].annual_output]
    results_out << [line_break]

    # Breakout
    results_out << ["elecIntLighting", @end_uses[[FT_Elec, EUT_LightsInterior]].annual_output]
    results_out << ["elecExtLighting", @end_uses[[FT_Elec, EUT_LightsExterior]].annual_output]
    results_out << ["elecGrgLighting", @end_uses[[FT_Elec, EUT_LightsGarage]].annual_output]
    results_out << ["elecMELs", @end_uses[[FT_Elec, EUT_PlugLoads]].annual_output]
    results_out << ["elecFridge", @end_uses[[FT_Elec, EUT_Refrigerator]].annual_output]
    results_out << ["elecTV", @end_uses[[FT_Elec, EUT_Television]].annual_output]
    results_out << ["elecRangeOven", @end_uses[[FT_Elec, EUT_RangeOven]].annual_output]
    results_out << ["elecClothesDryer", @end_uses[[FT_Elec, EUT_ClothesDryer]].annual_output]
    results_out << ["elecDishwasher", @end_uses[[FT_Elec, EUT_Dishwasher]].annual_output]
    results_out << ["elecClothesWasher", @end_uses[[FT_Elec, EUT_ClothesWasher]].annual_output]
    results_out << ["elecMechVent", @end_uses[[FT_Elec, EUT_MechVent]].annual_output]
    results_out << ["elecWholeHouseFan", @end_uses[[FT_Elec, EUT_WholeHouseFan]].annual_output]
    results_out << ["elecCeilingFan", @end_uses[[FT_Elec, EUT_CeilingFan]].annual_output]
    results_out << ["gasRangeOven", @end_uses[[FT_Gas, EUT_RangeOven]].annual_output]
    results_out << ["gasClothesDryer", @end_uses[[FT_Gas, EUT_ClothesDryer]].annual_output]
    results_out << ["oilRangeOven", @end_uses[[FT_Oil, EUT_RangeOven]].annual_output]
    results_out << ["oilClothesDryer", @end_uses[[FT_Oil, EUT_ClothesDryer]].annual_output]
    results_out << ["propaneRangeOven", @end_uses[[FT_Propane, EUT_RangeOven]].annual_output]
    results_out << ["propaneClothesDryer", @end_uses[[FT_Propane, EUT_ClothesDryer]].annual_output]
    results_out << [line_break]

    # Misc
    results_out << ["hpxml_cfa", outputs[:hpxml_cfa]]
    results_out << ["hpxml_nbr", outputs[:hpxml_nbr]]
    results_out << ["hpxml_nst", outputs[:hpxml_nst]]

    CSV.open(csv_path, "wb") { |csv| results_out.to_a.each { |elem| csv << elem } }
  end

  def write_timeseries_output_results(runner, csv_path, timeseries_frequency)
    # Time column
    if timeseries_frequency == 'hourly'
      data = ["Hour"]
    elsif timeseries_frequency == 'daily'
      data = ["Day"]
    elsif timeseries_frequency == 'timestep'
      data = ["Timestep"]
    else
      fail "Unexpected timeseries_frequency: #{timeseries_frequency}."
    end
    for i in 1..@timeseries_size
      data << i
    end

    fuel_data = @fuels.values.select { |x| !x.timeseries_output.empty? }.map { |x| [x.timeseries_name] + x.timeseries_output.map { |v| v.round(2) } }
    end_use_data = @end_uses.values.select { |x| !x.timeseries_output.empty? }.map { |x| [x.timeseries_name] + x.timeseries_output.map { |v| v.round(2) } }
    zone_temps_data = @zone_temps.values.select { |x| !x.timeseries_output.empty? }.map { |x| [x.timeseries_name] + x.timeseries_output.map { |v| v.round(2) } }
    total_loads_data = @total_loads.values.select { |x| !x.timeseries_output.empty? }.map { |x| [x.timeseries_name] + x.timeseries_output.map { |v| v.round(2) } }
    comp_loads_data = @component_loads.values.select { |x| !x.timeseries_output.empty? }.map { |x| [x.timeseries_name] + x.timeseries_output.map { |v| v.round(2) } }

    return if fuel_data.size + end_use_data.size + zone_temps_data.size + total_loads_data.size + comp_loads_data.size == 0

    # Assemble data
    data = data.zip(*fuel_data, *end_use_data, *zone_temps_data, *total_loads_data, *comp_loads_data)

    # Error-check
    n_elements = []
    data.each do |data_array|
      n_elements << data_array.size
    end
    if n_elements.uniq.size > 1
      fail "Inconsistent number of array elements: #{n_elements.uniq.to_s}."
    end

    # Write file
    CSV.open(csv_path, "wb") { |csv| data.to_a.each { |elem| csv << elem } }
    runner.registerInfo("Wrote timeseries output results to #{csv_path}.")
  end

  def set_hpxml_systems()
    @htgs = []
    @clgs = []
    @hp_htgs = []
    @hp_clgs = []
    @dhws = []

    @hpxml_doc.elements.each("/HPXML/Building/BuildingDetails/Systems/HVAC/HVACPlant/HeatingSystem[FractionHeatLoadServed > 0]") do |htg_system|
      @htgs << htg_system
    end
    @hpxml_doc.elements.each("/HPXML/Building/BuildingDetails/Systems/HVAC/HVACPlant/HeatPump[FractionHeatLoadServed > 0]") do |heat_pump|
      @hp_htgs << heat_pump
    end
    @hpxml_doc.elements.each("/HPXML/Building/BuildingDetails/Systems/HVAC/HVACPlant/CoolingSystem[FractionCoolLoadServed > 0]") do |clg_system|
      @clgs << clg_system
    end
    @hpxml_doc.elements.each("/HPXML/Building/BuildingDetails/Systems/HVAC/HVACPlant/HeatPump[FractionCoolLoadServed > 0]") do |heat_pump|
      @hp_clgs << heat_pump
    end
    @hpxml_doc.elements.each("/HPXML/Building/BuildingDetails/Systems/WaterHeating/WaterHeatingSystem[FractionDHWLoadServed > 0]") do |dhw_system|
      @dhws << dhw_system
    end
  end

  def get_hpxml_dse_heats(heat_sys_ids)
    dse_heats = {}

    heat_sys_ids.each do |sys_id|
      dse_heats[sys_id] = 1.0 # Init
    end

    @hpxml_doc.elements.each("/HPXML/Building/BuildingDetails/Systems/HVAC/HVACDistribution") do |hvac_dist|
      dist_id = hvac_dist.elements["SystemIdentifier"].attributes["id"]
      dse_heat = XMLHelper.get_value(hvac_dist, "AnnualHeatingDistributionSystemEfficiency")
      next if dse_heat.nil?

      dse_heat = Float(dse_heat)

      # Get all HVAC systems attached to it
      @htgs.each do |htg_system|
        next if htg_system.elements["DistributionSystem"].nil?
        next unless dist_id == htg_system.elements["DistributionSystem"].attributes["idref"]

        sys_id = get_system_or_seed_id(htg_system)
        dse_heats[sys_id] = dse_heat
      end
      @hp_htgs.each do |heat_pump|
        next if heat_pump.elements["DistributionSystem"].nil?
        next unless dist_id == heat_pump.elements["DistributionSystem"].attributes["idref"]

        sys_id = get_system_or_seed_id(heat_pump)
        dse_heats[sys_id] = dse_heat

        if is_dfhp(heat_pump)
          # Also apply to dual-fuel heat pump backup system
          dse_heats[dfhp_backup_sys_id(sys_id)] = dse_heat
        end
      end
    end

    return dse_heats
  end

  def get_hpxml_dse_cools(cool_sys_ids)
    dse_cools = {}

    # Init
    cool_sys_ids.each do |sys_id|
      dse_cools[sys_id] = 1.0
    end

    @hpxml_doc.elements.each("/HPXML/Building/BuildingDetails/Systems/HVAC/HVACDistribution") do |hvac_dist|
      dist_id = hvac_dist.elements["SystemIdentifier"].attributes["id"]
      dse_cool = XMLHelper.get_value(hvac_dist, "AnnualCoolingDistributionSystemEfficiency")
      next if dse_cool.nil?

      dse_cool = Float(dse_cool)

      # Get all HVAC systems attached to it
      @clgs.each do |clg_system|
        next if clg_system.elements["DistributionSystem"].nil?
        next unless dist_id == clg_system.elements["DistributionSystem"].attributes["idref"]

        sys_id = get_system_or_seed_id(clg_system)
        dse_cools[sys_id] = dse_cool
      end
      @hp_clgs.each do |heat_pump|
        next if heat_pump.elements["DistributionSystem"].nil?
        next unless dist_id == heat_pump.elements["DistributionSystem"].attributes["idref"]

        sys_id = get_system_or_seed_id(heat_pump)
        dse_cools[sys_id] = dse_cool
      end
    end

    return dse_cools
  end

  def get_hpxml_heat_fuels()
    heat_fuels = {}

    @htgs.each do |htg_system|
      sys_id = get_system_or_seed_id(htg_system)
      heat_fuels[sys_id] = XMLHelper.get_value(htg_system, "HeatingSystemFuel")
    end
    @hp_htgs.each do |heat_pump|
      sys_id = get_system_or_seed_id(heat_pump)
      heat_fuels[sys_id] = XMLHelper.get_value(heat_pump, "HeatPumpFuel")
      if is_dfhp(heat_pump)
        heat_fuels[dfhp_backup_sys_id(sys_id)] = XMLHelper.get_value(heat_pump, "BackupSystemFuel")
      end
    end

    return heat_fuels
  end

  def get_hpxml_dhw_fuels()
    dhw_fuels = {}

    @dhws.each do |dhw_system|
      sys_id = dhw_system.elements["SystemIdentifier"].attributes["id"]
      if ['space-heating boiler with tankless coil', 'space-heating boiler with storage tank'].include? XMLHelper.get_value(dhw_system, "WaterHeaterType")
        orig_details = @hpxml_doc.elements["/HPXML/Building/BuildingDetails"]
        hvac_idref = dhw_system.elements["RelatedHVACSystem"].attributes["idref"]
        dhw_fuels[sys_id] = Waterheater.get_combi_system_fuel(hvac_idref, orig_details)
      else
        dhw_fuels[sys_id] = XMLHelper.get_value(dhw_system, "FuelType")
      end
    end

    return dhw_fuels
  end

  def get_hpxml_eec_heats()
    eec_heats = {}

    units = ['HSPF', 'COP', 'AFUE', 'Percent']

    @htgs.each do |htg_system|
      sys_id = get_system_or_seed_id(htg_system)
      units.each do |unit|
        value = XMLHelper.get_value(htg_system, "AnnualHeatingEfficiency[Units='#{unit}']/Value")
        next if value.nil?

        eec_heats[sys_id] = get_eri_eec_value_numerator(unit) / Float(value)
      end
    end
    @hp_htgs.each do |heat_pump|
      sys_id = get_system_or_seed_id(heat_pump)
      units.each do |unit|
        value = XMLHelper.get_value(heat_pump, "AnnualHeatingEfficiency[Units='#{unit}']/Value")
        next if value.nil?

        eec_heats[sys_id] = get_eri_eec_value_numerator(unit) / Float(value)
      end
      if is_dfhp(heat_pump)
        units.each do |unit|
          value = XMLHelper.get_value(heat_pump, "BackupAnnualHeatingEfficiency[Units='#{unit}']/Value")
          next if value.nil?

          eec_heats[dfhp_backup_sys_id(sys_id)] = get_eri_eec_value_numerator(unit) / Float(value)
        end
      end
    end

    return eec_heats
  end

  def get_hpxml_eec_cools()
    eec_cools = {}

    units = ['SEER', 'COP', 'EER']

    @clgs.each do |clg_system|
      sys_id = get_system_or_seed_id(clg_system)
      units.each do |unit|
        value = XMLHelper.get_value(clg_system, "AnnualCoolingEfficiency[Units='#{unit}']/Value")
        next if value.nil?

        eec_cools[sys_id] = get_eri_eec_value_numerator(unit) / Float(value)
      end

      if XMLHelper.get_value(clg_system, "CoolingSystemType") == "evaporative cooler"
        eec_cools[sys_id] = get_eri_eec_value_numerator("SEER") / 15.0 # Arbitrary
      end
    end
    @hp_clgs.each do |heat_pump|
      sys_id = get_system_or_seed_id(heat_pump)
      units.each do |unit|
        value = XMLHelper.get_value(heat_pump, "AnnualCoolingEfficiency[Units='#{unit}']/Value")
        next if value.nil?

        eec_cools[sys_id] = get_eri_eec_value_numerator(unit) / Float(value)
      end
    end

    return eec_cools
  end

  def get_hpxml_eec_dhws()
    eec_dhws = {}

    @dhws.each do |dhw_system|
      sys_id = dhw_system.elements["SystemIdentifier"].attributes["id"]
      value = XMLHelper.get_value(dhw_system, "EnergyFactor")
      wh_type = XMLHelper.get_value(dhw_system, "WaterHeaterType")
      if wh_type == "instantaneous water heater"
        cycling_derate = Float(XMLHelper.get_value(dhw_system, "PerformanceAdjustment"))
        value_adj = 1.0 - cycling_derate
      else
        value_adj = 1.0
      end

      ## Combi system requires recalculating ef
      if value.nil?
        if wh_type == 'space-heating boiler with tankless coil'
          combi_type = 'instantaneous water heater'
          ua = nil
        elsif wh_type == 'space-heating boiler with storage tank'
          combi_type = 'storage water heater'
          vol = Float(XMLHelper.get_value(dhw_system, "TankVolume"))
          standby_loss = Float(XMLHelper.get_value(dhw_system, "extension/StandbyLoss")) unless XMLHelper.get_value(dhw_system, "extension/StandbyLoss").nil?
          act_vol = Waterheater.calc_storage_tank_actual_vol(vol, nil)
          standby_loss = Waterheater.get_indirect_standbyloss(standby_loss, act_vol)
          ua = Waterheater.calc_indirect_ua_with_standbyloss(act_vol, standby_loss, nil, nil)
        end
        combi_boiler_afue = nil
        hvac_idref = dhw_system.elements["RelatedHVACSystem"].attributes["idref"]
        @hpxml_doc.elements.each("/HPXML/Building/BuildingDetails/Systems/HVAC/HVACPlant/HeatingSystem") do |heating_system|
          next unless heating_system.elements["SystemIdentifier"].attributes["id"] == hvac_idref

          combi_boiler_afue = Float(XMLHelper.get_value(heating_system, "AnnualHeatingEfficiency[Units='AFUE']/Value"))
          break
        end
        value = Waterheater.calc_tank_EF(combi_type, ua, combi_boiler_afue)
      end

      if not value.nil? and not value_adj.nil?
        eec_dhws[sys_id] = get_eri_eec_value_numerator('EF') / (Float(value) * Float(value_adj))
      end
    end

    return eec_dhws
  end

  def get_eri_eec_value_numerator(unit)
    if ['HSPF', 'SEER', 'EER'].include? unit
      return 3.413
    elsif ['AFUE', 'COP', 'Percent', 'EF'].include? unit
      return 1.0
    end
  end

  def get_system_or_seed_id(sys)
    if [Constants.CalcTypeERIReferenceHome,
        Constants.CalcTypeERIIndexAdjustmentReferenceHome].include? @eri_design
      if XMLHelper.has_element(sys, "extension/SeedId")
        return XMLHelper.get_value(sys, "extension/SeedId")
      end
    end
    return sys.elements["SystemIdentifier"].attributes["id"]
  end

  def get_report_meter_data_annual_mbtu(variable)
    query = "SELECT SUM(VariableValue/1000000000) FROM ReportMeterData WHERE ReportMeterDataDictionaryIndex IN (SELECT ReportMeterDataDictionaryIndex FROM ReportMeterDataDictionary WHERE VariableName='#{variable}' AND ReportingFrequency='Run Period' AND VariableUnits='J')"
    value = @sqlFile.execAndReturnFirstDouble(query)
    fail "Query error: #{query}" unless value.is_initialized

    return UnitConversions.convert(value.get, "GJ", "MBtu")
  end

  def get_report_variable_data_annual_mbtu(key_values_list, variable_names_list, not_key: false)
    keys = "'" + key_values_list.join("','") + "'"
    vars = "'" + variable_names_list.join("','") + "'"
    if not_key
      s_not = "NOT "
    else
      s_not = ""
    end
    query = "SELECT SUM(VariableValue/1000000000) FROM ReportVariableData WHERE ReportVariableDataDictionaryIndex IN (SELECT ReportVariableDataDictionaryIndex FROM ReportVariableDataDictionary WHERE KeyValue #{s_not}IN (#{keys}) AND VariableName IN (#{vars}) AND ReportingFrequency='Run Period')"
    value = @sqlFile.execAndReturnFirstDouble(query)
    fail "Query error: #{query}" unless value.is_initialized

    return UnitConversions.convert(value.get, "GJ", "MBtu")
  end

  def get_report_meter_data_timeseries(key_value, variable_name, unit_conv, unit_adder, timeseries_frequency)
    query = "SELECT SUM(VariableValue*#{unit_conv}+#{unit_adder}) FROM ReportMeterData WHERE ReportMeterDataDictionaryIndex IN (SELECT ReportMeterDataDictionaryIndex FROM ReportMeterDataDictionary WHERE KeyValue='#{key_value}' AND VariableName='#{variable_name}' AND ReportingFrequency='#{reporting_frequency_map[timeseries_frequency]}' AND VariableUnits='J') GROUP BY TimeIndex ORDER BY TimeIndex"
    values = @sqlFile.execAndReturnVectorOfDouble(query)
    fail "Query error: #{query}" unless values.is_initialized

    values = values.get
    values += [0.0] * @timeseries_size if values.size == 0
    return values
  end

  def get_report_variable_data_timeseries(key_values_list, variable_names_list, unit_conv, unit_adder, timeseries_frequency)
    keys = "'" + key_values_list.join("','") + "'"
    vars = "'" + variable_names_list.join("','") + "'"
    query = "SELECT SUM(VariableValue*#{unit_conv}+#{unit_adder}) FROM ReportVariableData WHERE ReportVariableDataDictionaryIndex IN (SELECT ReportVariableDataDictionaryIndex FROM ReportVariableDataDictionary WHERE KeyValue IN (#{keys}) AND VariableName IN (#{vars}) AND ReportingFrequency='#{reporting_frequency_map[timeseries_frequency]}') GROUP BY TimeIndex ORDER BY TimeIndex"
    values = @sqlFile.execAndReturnVectorOfDouble(query)
    fail "Query error: #{query}" unless values.is_initialized

    values = values.get
    values += [0.0] * @timeseries_size if values.size == 0
    if key_values_list.size == 1 and key_values_list[0] == "EMS"
      # Shift all values by 1 timestep due to EMS reporting lag
      return values[1..-1] + [values[-1]]
    end

    return values
  end

  def get_tabular_data_value(report_name, report_for_string, table_name, row_name, col_name, units)
    query = "SELECT SUM(Value) FROM TabularDataWithStrings WHERE ReportName='#{report_name}' AND ReportForString='#{report_for_string}' AND TableName='#{table_name}' AND RowName='#{row_name}' AND ColumnName='#{col_name}' AND Units='#{units}'"
    result = @sqlFile.execAndReturnFirstDouble(query)
    return result.get
  end

  def apply_multiplier(obj, sync_obj, sys_id, mult)
    # Annual
    orig_value = obj.annual_output_by_system[sys_id]
    obj.annual_output_by_system[sys_id] = orig_value * mult
    sync_obj.annual_output += (orig_value * mult - orig_value)

    # Timeseries
    if not obj.timeseries_output_by_system.empty?
      orig_values = obj.timeseries_output_by_system[sys_id]
      obj.timeseries_output_by_system[sys_id] = obj.timeseries_output_by_system[sys_id].map { |x| x * mult }
      diffs = obj.timeseries_output_by_system[sys_id].zip(orig_values).map { |x, y| x - y }
      sync_obj.timeseries_output = sync_obj.timeseries_output.zip(diffs).map { |x, y| x + y }
    end
  end

  def get_combi_hvac_id(sys_id)
    @dhws.each do |dhw_system|
      next unless sys_id == dhw_system.elements["SystemIdentifier"].attributes["id"]
      next unless ['space-heating boiler with tankless coil', 'space-heating boiler with storage tank'].include? XMLHelper.get_value(dhw_system, "WaterHeaterType")

      return dhw_system.elements["RelatedHVACSystem"].attributes["idref"]
    end

    return nil
  end

  def get_combi_water_system_ec(hx_load, htg_load, htg_energy)
    water_sys_frac = hx_load / htg_load
    return htg_energy * water_sys_frac
  end

  def get_dfhp_loads(outputs, hvac_map)
    dfhp_loads = {}
    outputs[:hpxml_heat_sys_ids].each do |sys_id|
      ep_output_names, dfhp_primary, dfhp_backup = get_ep_output_names_for_hvac_heating(hvac_map, sys_id)
      keys = ep_output_names.map(&:upcase)
      if dfhp_primary or dfhp_backup
        if dfhp_primary
          vars = get_all_var_keys(OutputVars.SpaceHeatingDFHPPrimaryLoad)
        else
          vars = get_all_var_keys(OutputVars.SpaceHeatingDFHPBackupLoad)
          sys_id = dfhp_primary_sys_id(sys_id)
        end
        dfhp_loads[[sys_id, dfhp_primary]] = get_report_variable_data_annual_mbtu(keys, vars)
      end
    end
    return dfhp_loads
  end

  def split_htg_load_to_system_by_fraction(sys_id, bldg_load, dfhp_loads)
    @htgs.each do |htg_system|
      next unless get_system_or_seed_id(htg_system) == sys_id

      return bldg_load * Float(XMLHelper.get_value(htg_system, "FractionHeatLoadServed"))
    end
    @hp_htgs.each do |heat_pump|
      load_fraction = 1.0
      if is_dfhp(heat_pump)
        if dfhp_primary_sys_id(sys_id) == sys_id
          load_fraction = dfhp_loads[[sys_id, true]] / (dfhp_loads[[sys_id, true]] + dfhp_loads[[sys_id, false]])
        else
          sys_id = dfhp_primary_sys_id(sys_id)
          load_fraction = dfhp_loads[[sys_id, false]] / (dfhp_loads[[sys_id, true]] + dfhp_loads[[sys_id, false]])
        end
      end
      next unless get_system_or_seed_id(heat_pump) == sys_id

      return bldg_load * Float(XMLHelper.get_value(heat_pump, "FractionHeatLoadServed")) * load_fraction
    end
  end

  def split_clg_load_to_system_by_fraction(sys_id, bldg_load)
    @clgs.each do |clg_system|
      next unless get_system_or_seed_id(clg_system) == sys_id

      return bldg_load * Float(XMLHelper.get_value(clg_system, "FractionCoolLoadServed"))
    end
    @hp_clgs.each do |heat_pump|
      next unless get_system_or_seed_id(heat_pump) == sys_id

      return bldg_load * Float(XMLHelper.get_value(heat_pump, "FractionCoolLoadServed"))
    end
  end

  def dfhp_backup_sys_id(primary_sys_id)
    return primary_sys_id + "_dfhp_backup_system"
  end

  def dfhp_primary_sys_id(backup_sys_id)
    return backup_sys_id.gsub("_dfhp_backup_system", "")
  end

  def is_dfhp(system)
    if not XMLHelper.get_value(system, "BackupHeatingSwitchoverTemperature").nil? and XMLHelper.get_value(system, "BackupSystemFuel") != "electricity"
      return true
    end

    return false
  end

  def get_all_var_keys(var)
    var_keys = []
    var.keys.each do |key|
      var[key].each do |var_key|
        var_keys << var_key
      end
    end
    return var_keys
  end

  def get_dhw_solar_fraction(sys_id)
    solar_fraction = 0.0
    @hpxml_doc.elements.each("/HPXML/Building/BuildingDetails/Systems/SolarThermal/SolarThermalSystem") do |system|
      next unless sys_id == system.elements["ConnectedTo"].attributes["idref"]

      solar_fraction = XMLHelper.get_value(system, "SolarFraction").to_f
    end
    return solar_fraction
  end

  def get_ep_output_names_for_hvac_heating(map, sys_id)
    dfhp_primary = false
    dfhp_backup = false
    @hpxml_doc.elements.each("/HPXML/Building/BuildingDetails/Systems/HVAC/HVACPlant/HeatingSystem |
                             /HPXML/Building/BuildingDetails/Systems/HVAC/HVACPlant/HeatPump") do |system|
      if is_dfhp(system)
        if dfhp_primary_sys_id(sys_id) == sys_id
          dfhp_primary = true
        else
          dfhp_backup = true
          sys_id = dfhp_primary_sys_id(sys_id)
        end
      end
      next unless XMLHelper.get_value(system, "extension/SeedId") == sys_id

      sys_id = system.elements["SystemIdentifier"].attributes["id"]
      break
    end

    output_names = map[sys_id].dup

    if dfhp_primary or dfhp_backup
      # Exclude output names associated with primary/backup system as appropriate
      output_names.reverse.each do |o|
        is_backup_obj = (o.include? Constants.ObjectNameFanPumpDisaggregateBackupHeat or o.include? Constants.ObjectNameBackupHeatingCoil)
        if dfhp_primary and is_backup_obj
          output_names.delete(o)
        elsif dfhp_backup and not is_backup_obj
          output_names.delete(o)
        end
      end
    end

    return output_names, dfhp_primary, dfhp_backup
  end

  def get_ep_output_names_for_hvac_cooling(map, sys_id)
    @hpxml_doc.elements.each("/HPXML/Building/BuildingDetails/Systems/HVAC/HVACPlant/CoolingSystem |
                             /HPXML/Building/BuildingDetails/Systems/HVAC/HVACPlant/HeatPump") do |system|
      next unless XMLHelper.get_value(system, "extension/SeedId") == sys_id

      sys_id = system.elements["SystemIdentifier"].attributes["id"]
      break
    end

    return map[sys_id]
  end

  def get_ep_output_names_for_water_heating(map, sys_id)
    return map[sys_id]
  end

  def get_object_maps(model)
    # Retrieve HPXML->E+ object name maps
    hvac_map = eval(model.getBuilding.additionalProperties.getFeatureAsString("hvac_map").get)
    dhw_map = eval(model.getBuilding.additionalProperties.getFeatureAsString("dhw_map").get)
    return hvac_map, dhw_map
  end

  def add_object_output_variables(model, hvac_map, dhw_map, timeseries_frequency)
    hvac_output_vars = [OutputVars.SpaceHeatingElectricity,
                        OutputVars.SpaceHeatingNaturalGas,
                        OutputVars.SpaceHeatingFuelOil,
                        OutputVars.SpaceHeatingPropane,
                        OutputVars.SpaceHeatingDFHPPrimaryLoad,
                        OutputVars.SpaceHeatingDFHPBackupLoad,
                        OutputVars.SpaceCoolingElectricity]

    dhw_output_vars = [OutputVars.WaterHeatingElectricity,
                       OutputVars.WaterHeatingElectricityRecircPump,
                       OutputVars.WaterHeatingElectricitySolarThermalPump,
                       OutputVars.WaterHeatingCombiBoilerHeatExchanger, # Needed to disaggregate hot water energy from heating energy
                       OutputVars.WaterHeatingCombiBoiler,              # Needed to disaggregate hot water energy from heating energy
                       OutputVars.WaterHeatingNaturalGas,
                       OutputVars.WaterHeatingFuelOil,
                       OutputVars.WaterHeatingPropane,
                       OutputVars.WaterHeatingLoad,
                       OutputVars.WaterHeatingLoadTankLosses,
                       OutputVars.WaterHeaterLoadDesuperheater,
                       OutputVars.WaterHeaterLoadSolarThermal]

    names_to_objs = {}
    [hvac_map, dhw_map].each do |map|
      map.each do |sys_id, object_names|
        object_names.each do |object_name|
          names_to_objs[object_name] = model.getModelObjectByName(object_name).get
        end
      end
    end

    # Remove objects that are not referenced by output vars and are not
    # EMS output vars.
    { hvac_map => hvac_output_vars,
      dhw_map => dhw_output_vars }.each do |map, vars|
      all_vars = vars.reduce({}, :merge)
      map.each do |sys_id, object_names|
        objects_to_delete = []
        object_names.each do |object_name|
          object = names_to_objs[object_name]
          next if object.to_EnergyManagementSystemOutputVariable.is_initialized
          next unless all_vars[object.class.to_s].nil? # Referenced?

          objects_to_delete << object
        end
        objects_to_delete.uniq.each do |object|
          map[sys_id].delete object
        end
      end
    end

    def add_output_variables(model, vars, object, timeseries_frequency)
      if object.to_EnergyManagementSystemOutputVariable.is_initialized
        return [OpenStudio::IdfObject.load("Output:Variable,*,#{object.name.to_s},#{timeseries_frequency};").get]
      else
        obj_class = nil
        vars.keys.each do |k|
          method_name = "to_#{k.gsub('OpenStudio::Model::', '')}"
          tmp = object.public_send(method_name) if object.respond_to? method_name
          if not tmp.nil? and tmp.is_initialized
            obj_class = tmp.get.class.to_s
          end
        end
        return [] if vars[obj_class].nil?

        results = []
        vars[obj_class].each do |object_var|
          results << OpenStudio::IdfObject.load("Output:Variable,#{object.name.to_s},#{object_var},#{timeseries_frequency};").get
        end
        return results
      end
    end

    results = []

    # Add output variables to model
    ems_objects = []
    hvac_map.each do |sys_id, hvac_names|
      hvac_names.each do |hvac_name|
        hvac_object = names_to_objs[hvac_name]
        if hvac_object.to_EnergyManagementSystemOutputVariable.is_initialized
          ems_objects << hvac_object
        else
          hvac_output_vars.each do |hvac_output_var|
            add_output_variables(model, hvac_output_var, hvac_object, timeseries_frequency).each do |outvar|
              results << outvar
            end
          end
        end
      end
    end
    dhw_map.each do |sys_id, dhw_names|
      dhw_names.each do |dhw_name|
        dhw_object = names_to_objs[dhw_name]
        if dhw_object.to_EnergyManagementSystemOutputVariable.is_initialized
          ems_objects << dhw_object
        else
          dhw_output_vars.each do |dhw_output_var|
            add_output_variables(model, dhw_output_var, dhw_object, timeseries_frequency).each do |outvar|
              results << outvar
            end
          end
        end
      end
    end

    # Add EMS output variables to model
    ems_objects.uniq.each do |ems_object|
      add_output_variables(model, nil, ems_object, timeseries_frequency).each do |outvar|
        results << outvar
      end
    end

    return results
  end

  def sum_elements_in_arrays(*arrays)
    return arrays[0] if arrays.size == 1

    return arrays[0].zip(*arrays[1..-1]).map { |x, y| x + y }
  end

  class Fuel
    def initialize(meter: nil)
      @meter = meter
      @timeseries_output = []
      @timeseries_output_by_system = {}
    end
    attr_accessor(:meter, :annual_output, :annual_name, :timeseries_output, :timeseries_name,
                  :timeseries_unit_conv, :timeseries_output_by_system)
  end

  class EndUse
    def initialize(meter: nil, variable: nil)
      @meter = meter
      @variable = variable
      @timeseries_output = []
      @timeseries_output_by_system = {}
      @annual_output_by_system = {}
    end
    attr_accessor(:meter, :variable, :annual_output, :annual_name, :timeseries_output, :timeseries_name,
                  :timeseries_unit_conv, :annual_output_by_system, :timeseries_output_by_system)
  end

  class Load
    def initialize(meter: nil, variable: nil)
      @meter = meter
      @variable = variable
      @timeseries_output = []
      @timeseries_output_by_system = {}
      @annual_output_by_system = {}
    end
    attr_accessor(:meter, :variable, :annual_output, :annual_name, :timeseries_output, :timeseries_name,
                  :timeseries_unit_conv, :annual_output_by_system, :timeseries_output_by_system)
  end

  class ZoneTemp
    attr_accessor(:timeseries_output, :timeseries_name)
  end

  def setup_outputs
    def get_timeseries_units_from_fuel_type(fuel_type)
      if fuel_type == FT_Elec
        return 'kWh'
      end

      return 'kBtu'
    end

    # Fuels

    @fuels = {
      FT_Elec => Fuel.new(meter: "Electricity:Facility"),
      FT_Gas => Fuel.new(meter: "Gas:Facility"),
      FT_Oil => Fuel.new(meter: "FuelOil#1:Facility"),
      FT_Propane => Fuel.new(meter: "Propane:Facility"),
    }

    @fuels.each do |fuel_type, fuel|
      fuel.annual_name = "#{fuel_type}: Total (#{UNITS_AnnualEnergy})"
      timeseries_units = get_timeseries_units_from_fuel_type(fuel_type)
      fuel.timeseries_name = "#{fuel_type}: Total (#{timeseries_units})"
      fuel.timeseries_unit_conv = UnitConversions.convert(1.0, 'J', timeseries_units)
    end

    # End Uses

    # Some end uses are obtained from meters, others are rolled up from
    # output variables so that we can have more control.
    @end_uses = {
      [FT_Elec, EUT_Heating] => EndUse.new(variable: OutputVars.SpaceHeatingElectricity),
      [FT_Elec, EUT_Cooling] => EndUse.new(variable: OutputVars.SpaceCoolingElectricity),
      [FT_Elec, EUT_HotWater] => EndUse.new(variable: OutputVars.WaterHeatingElectricity),
      [FT_Elec, EUT_HotWaterRecircPump] => EndUse.new(variable: OutputVars.WaterHeatingElectricityRecircPump),
      [FT_Elec, EUT_HotWaterSolarThermalPump] => EndUse.new(variable: OutputVars.WaterHeatingElectricitySolarThermalPump),
      [FT_Elec, EUT_LightsInterior] => EndUse.new(meter: "#{Constants.ObjectNameInteriorLighting}:InteriorLights:Electricity"),
      [FT_Elec, EUT_LightsGarage] => EndUse.new(meter: "#{Constants.ObjectNameGarageLighting}:InteriorLights:Electricity"),
      [FT_Elec, EUT_LightsExterior] => EndUse.new(meter: "ExteriorLights:Electricity"),
      [FT_Elec, EUT_MechVent] => EndUse.new(meter: "#{Constants.ObjectNameMechanicalVentilationHouseFan}:InteriorEquipment:Electricity"),
      [FT_Elec, EUT_WholeHouseFan] => EndUse.new(meter: "#{Constants.ObjectNameWholeHouseFan}:InteriorEquipment:Electricity"),
      [FT_Elec, EUT_Refrigerator] => EndUse.new(meter: "#{Constants.ObjectNameRefrigerator}:InteriorEquipment:Electricity"),
      [FT_Elec, EUT_Dishwasher] => EndUse.new(meter: "#{Constants.ObjectNameDishwasher}:InteriorEquipment:Electricity"),
      [FT_Elec, EUT_ClothesWasher] => EndUse.new(meter: "#{Constants.ObjectNameClothesWasher}:InteriorEquipment:Electricity"),
      [FT_Elec, EUT_ClothesDryer] => EndUse.new(meter: "#{Constants.ObjectNameClothesDryer}:InteriorEquipment:Electricity"),
      [FT_Elec, EUT_RangeOven] => EndUse.new(meter: "#{Constants.ObjectNameCookingRange}:InteriorEquipment:Electricity"),
      [FT_Elec, EUT_CeilingFan] => EndUse.new(meter: "#{Constants.ObjectNameCeilingFan}:InteriorEquipment:Electricity"),
      [FT_Elec, EUT_Television] => EndUse.new(meter: "#{Constants.ObjectNameMiscTelevision}:InteriorEquipment:Electricity"),
      [FT_Elec, EUT_PlugLoads] => EndUse.new(meter: "#{Constants.ObjectNameMiscPlugLoads}:InteriorEquipment:Electricity"),
      [FT_Elec, EUT_PV] => EndUse.new(meter: "ElectricityProduced:Facility"),
      [FT_Gas, EUT_Heating] => EndUse.new(variable: OutputVars.SpaceHeatingNaturalGas),
      [FT_Gas, EUT_HotWater] => EndUse.new(variable: OutputVars.WaterHeatingNaturalGas),
      [FT_Gas, EUT_ClothesDryer] => EndUse.new(meter: "#{Constants.ObjectNameClothesDryer}:InteriorEquipment:Gas"),
      [FT_Gas, EUT_RangeOven] => EndUse.new(meter: "#{Constants.ObjectNameCookingRange}:InteriorEquipment:Gas"),
      [FT_Oil, EUT_Heating] => EndUse.new(variable: OutputVars.SpaceHeatingFuelOil),
      [FT_Oil, EUT_HotWater] => EndUse.new(variable: OutputVars.WaterHeatingFuelOil),
      [FT_Oil, EUT_ClothesDryer] => EndUse.new(meter: "#{Constants.ObjectNameClothesDryer}:InteriorEquipment:FuelOil#1"),
      [FT_Oil, EUT_RangeOven] => EndUse.new(meter: "#{Constants.ObjectNameCookingRange}:InteriorEquipment:FuelOil#1"),
      [FT_Propane, EUT_Heating] => EndUse.new(variable: OutputVars.SpaceHeatingPropane),
      [FT_Propane, EUT_HotWater] => EndUse.new(variable: OutputVars.WaterHeatingPropane),
      [FT_Propane, EUT_ClothesDryer] => EndUse.new(meter: "#{Constants.ObjectNameClothesDryer}:InteriorEquipment:Propane"),
      [FT_Propane, EUT_RangeOven] => EndUse.new(meter: "#{Constants.ObjectNameCookingRange}:InteriorEquipment:Propane"),
    }

    @end_uses.each do |key, end_use|
      fuel_type, end_use_type = key
      end_use.annual_name = "#{fuel_type}: #{end_use_type} (#{UNITS_AnnualEnergy})"
      timeseries_units = get_timeseries_units_from_fuel_type(fuel_type)
      end_use.timeseries_name = "#{fuel_type}: #{end_use_type} (#{timeseries_units})"
      end_use.timeseries_unit_conv = UnitConversions.convert(1.0, 'J', timeseries_units)
      if end_use_type == EUT_PV
        end_use.timeseries_unit_conv *= -1.0
      end
    end

    # Total Loads

    @total_loads = {
      LT_HeatingTotal => Load.new(meter: "Heating:EnergyTransfer"),
      LT_CoolingTotal => Load.new(meter: "Cooling:EnergyTransfer"),
      LT_HotWaterDelivered => Load.new(variable: OutputVars.WaterHeatingLoad),
      LT_HotWaterTankLosses => Load.new(),
      LT_HotWaterDesuperheater => Load.new(),
      LT_HotWaterSolarThermal => Load.new(),
    }

    @total_loads.each do |load_type, load|
      load.annual_name = "Load: #{load_type} (#{UNITS_AnnualLoad})"
      load.timeseries_name = "Load: #{load_type} (#{UNITS_TimeseriesLoad})"
      load.timeseries_unit_conv = UnitConversions.convert(1.0, 'J', UNITS_TimeseriesLoad)
    end

    # Component Loads

    @component_loads = {}
    { "Heating" => "htg", "Cooling" => "clg" }.each do |mode, mode_var|
      OutputVars.ComponentLoadsMap.each do |component, component_var|
        load_type = "#{mode}: #{component}"
        @component_loads[load_type] = Load.new()
      end
    end

    @component_loads.each do |load_type, load|
      load.annual_name = "Component Load: #{load_type} (#{UNITS_AnnualLoad})"
      load.timeseries_name = "Component Load: #{load_type} (#{UNITS_TimeseriesLoad})"
      load.timeseries_unit_conv = UnitConversions.convert(1.0, 'J', UNITS_TimeseriesLoad)
    end

    # Zone Temperatures

    @zone_temps = {}
  end

  def reporting_frequency_map
    return {
      "timestep" => "Zone Timestep",
      "hourly" => "Hourly",
      "daily" => "Daily",
    }
  end

  def peak_elec_report_map
    return {
      PeakElecWinter => "Peak Electricity Winter Total",
      PeakElecSummer => "Peak Electricity Summer Total"
    }
  end

  def unmet_loads_meter_map
    return {
      UnmetLoadHeating => "Heating:DistrictHeating",
      UnmetLoadCooling => "Cooling:DistrictCooling",
    }
  end

  def peak_loads_meter_map
    return {
      PeakLoadHeating => "Heating:EnergyTransfer",
      PeakLoadCooling => "Cooling:EnergyTransfer",
    }
  end

  # Fuel Types
  FT_Elec = "Electricity"
  FT_Gas = "Natural Gas"
  FT_Oil = "Fuel Oil"
  FT_Propane = "Propane"

  # End Use Types
  EUT_Heating = "Heating"
  EUT_Cooling = "Cooling"
  EUT_HotWater = "Hot Water"
  EUT_HotWaterRecircPump = "Hot Water Recirc Pump"
  EUT_HotWaterSolarThermalPump = "Hot Water Solar Thermal Pump"
  EUT_LightsInterior = "Lighting Interior"
  EUT_LightsGarage = "Lighting Garage"
  EUT_LightsExterior = "Lighting Exterior"
  EUT_MechVent = "Mech Vent"
  EUT_WholeHouseFan = "Whole House Fan"
  EUT_Refrigerator = "Refrigerator"
  EUT_Dishwasher = "Dishwasher"
  EUT_ClothesWasher = "Clothes Washer"
  EUT_ClothesDryer = "Clothes Dryer"
  EUT_RangeOven = "Range/Oven"
  EUT_CeilingFan = "Ceiling Fan"
  EUT_Television = "Television"
  EUT_PlugLoads = "Plug Loads"
  EUT_PV = "PV"

  # Load Types
  LT_HeatingTotal = "Heating"
  LT_CoolingTotal = "Cooling"
  LT_HotWaterDelivered = "Hot Water: Delivered"
  LT_HotWaterTankLosses = "Hot Water: Tank Losses"
  LT_HotWaterDesuperheater = "Hot Water: Desuperheater"
  LT_HotWaterSolarThermal = "Hot Water: Solar Thermal"

  # Units
  UNITS_AnnualEnergy = 'MBtu'
  UNITS_AnnualLoad = 'MBtu'
  UNITS_TimeseriesElec = 'kWh'
  UNITS_TimeseriesNonElec = 'kBtu'
  UNITS_TimeseriesLoad = 'kBtu'

  # Peak Electricity Names
  PeakElecSummer = "Peak Electricity: Summer Total"
  PeakElecWinter = "Peak Electricity: Winter Total"

  # Unmet Load Names
  UnmetLoadHeating = "Unmet Load: Heating"
  UnmetLoadCooling = "Unmet Load: Cooling"

  # Peak Load Names
  PeakLoadHeating = "Peak Load: Heating"
  PeakLoadCooling = "Peak Load: Cooling"
end

# register the measure to be used by the application
SimOutputReport.new.registerWithApplication
