# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/reference/measure_writing_guide/

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
    return 'Writes a variety of output files to the directory where the HPXML file resides.'
  end

  # define the arguments that the user will input
  def arguments(ignore = nil)
    args = OpenStudio::Measure::OSArgumentVector.new

    arg = OpenStudio::Measure::OSArgument::makeBoolArgument("hourly_output_fuel_consumptions", true)
    arg.setDisplayName("Generate Hourly Output: Fuel Consumptions")
    arg.setDescription("Generates hourly energy consumptions for each fuel type.")
    arg.setDefaultValue(false)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeBoolArgument("hourly_output_zone_temperatures", true)
    arg.setDisplayName("Generate Hourly Output: Zone Temperatures")
    arg.setDescription("Generates hourly temperatures for each thermal zone.")
    arg.setDefaultValue(false)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeBoolArgument("hourly_output_total_loads", true)
    arg.setDisplayName("Generate Hourly Output: Total Loads")
    arg.setDescription("Generates hourly heating/cooling loads.")
    arg.setDefaultValue(false)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeBoolArgument("hourly_output_component_loads", true)
    arg.setDisplayName("Generate Hourly Output: Component Loads")
    arg.setDescription("Generates hourly heating/cooling loads disaggregated by component type.")
    arg.setDefaultValue(false)
    args << arg

    # TODO: Add hourly output for end uses

    return args
  end

  # define the outputs that the measure will create
  def outputs
    outs = OpenStudio::Measure::OSOutputVector.new

    output_names = [
      "total_site_energy_mbtu",
      "total_site_electricity_kwh",
      "total_site_natural_gas_therm",
      "total_site_fuel_oil_mbtu",
      "total_site_propane_mbtu",
      "net_site_energy_mbtu", # Incorporates PV
      "net_site_electricity_kwh", # Incorporates PV
      "electricity_heating_kwh",
      "electricity_cooling_kwh",
      "electricity_interior_lighting_kwh",
      "electricity_exterior_lighting_kwh",
      "electricity_garage_lighting_kwh",
      "electricity_interior_equipment_kwh",
      "electricity_water_systems_kwh",
      "electricity_pv_kwh",
      "natural_gas_heating_therm",
      "natural_gas_interior_equipment_therm",
      "natural_gas_water_systems_therm",
      "fuel_oil_heating_mbtu",
      "fuel_oil_interior_equipment_mbtu",
      "fuel_oil_water_systems_mbtu",
      "propane_heating_mbtu",
      "propane_interior_equipment_mbtu",
      "propane_water_systems_mbtu",
    ]
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

    # Add annual output meters to increase precision of outputs relative to, e.g., ABUPS report
    meter_names = ["Electricity:Facility",
                   "Gas:Facility",
                   "FuelOil#1:Facility",
                   "Propane:Facility",
                   "Heating:EnergyTransfer",
                   "Cooling:EnergyTransfer",
                   "Heating:DistrictHeating",
                   "Cooling:DistrictCooling",
                   "#{Constants.ObjectNameInteriorLighting}:InteriorLights:Electricity",
                   "#{Constants.ObjectNameGarageLighting}:InteriorLights:Electricity",
                   "ExteriorLights:Electricity",
                   "InteriorEquipment:Electricity",
                   "InteriorEquipment:Gas",
                   "InteriorEquipment:FuelOil#1",
                   "InteriorEquipment:Propane",
                   "#{Constants.ObjectNameRefrigerator}:InteriorEquipment:Electricity",
                   "#{Constants.ObjectNameDishwasher}:InteriorEquipment:Electricity",
                   "#{Constants.ObjectNameClothesWasher}:InteriorEquipment:Electricity",
                   "#{Constants.ObjectNameClothesDryer}:InteriorEquipment:Electricity",
                   "#{Constants.ObjectNameClothesDryer}:InteriorEquipment:Gas",
                   "#{Constants.ObjectNameClothesDryer}:InteriorEquipment:FuelOil#1",
                   "#{Constants.ObjectNameClothesDryer}:InteriorEquipment:Propane",
                   "#{Constants.ObjectNameMiscPlugLoads}:InteriorEquipment:Electricity",
                   "#{Constants.ObjectNameMiscTelevision}:InteriorEquipment:Electricity",
                   "#{Constants.ObjectNameCookingRange}:InteriorEquipment:Electricity",
                   "#{Constants.ObjectNameCookingRange}:InteriorEquipment:Gas",
                   "#{Constants.ObjectNameCookingRange}:InteriorEquipment:FuelOil#1",
                   "#{Constants.ObjectNameCookingRange}:InteriorEquipment:Propane",
                   "#{Constants.ObjectNameCeilingFan}:InteriorEquipment:Electricity",
                   "#{Constants.ObjectNameMechanicalVentilationHouseFan}:InteriorEquipment:Electricity",
                   "#{Constants.ObjectNameWholeHouseFan}:InteriorEquipment:Electricity",
                   "ElectricityProduced:Facility"]
    meter_names.each do |meter_name|
      result << OpenStudio::IdfObject.load("Output:Meter,#{meter_name},runperiod;").get
    end

    # Add Output:Table:Monthly objects for peak electricity outputs
    { "Heating" => "Winter", "Cooling" => "Summer" }.each do |mode, season|
      monthly_array = ["Output:Table:Monthly",
                       "Peak Electricity #{season} Total",
                       "2",
                       "#{mode}:EnergyTransfer",
                       "HoursPositive",
                       "Electricity:Facility",
                       "MaximumDuringHoursShown"]
      result << OpenStudio::IdfObject.load("#{monthly_array.join(",").to_s};").get
    end

    hourly_output_fuel_consumptions = runner.getBoolArgumentValue("hourly_output_fuel_consumptions", user_arguments)
    if hourly_output_fuel_consumptions
      # Energy use by fuel:
      ['Electricity:Facility', 'Gas:Facility', 'FuelOil#1:Facility', 'Propane:Facility'].each do |meter_fuel|
        result << OpenStudio::IdfObject.load("Output:Meter,#{meter_fuel},hourly;").get
      end
    end

    hourly_output_zone_temperatures = runner.getBoolArgumentValue("hourly_output_zone_temperatures", user_arguments)
    if hourly_output_zone_temperatures
      # Thermal zone temperatures:
      result << OpenStudio::IdfObject.load("Output:Variable,*,Zone Mean Air Temperature,hourly;").get
    end

    hourly_output_total_loads = runner.getBoolArgumentValue("hourly_output_total_loads", user_arguments)
    if hourly_output_total_loads
      # Building heating/cooling loads
      # FIXME: This needs to be updated when the new component loads algorithm is merged
      ['Heating:EnergyTransfer', 'Cooling:EnergyTransfer'].each do |meter_load|
        result << OpenStudio::IdfObject.load("Output:Meter,#{meter_load},hourly;").get
      end
    end

    hourly_output_component_loads = runner.getBoolArgumentValue("hourly_output_component_loads", user_arguments)
    if hourly_output_component_loads
      loads_program = nil
      model.getEnergyManagementSystemPrograms.each do |program|
        next unless program.name.to_s == "component_loads_program"

        loads_program = program
      end

      ["htg", "clg"].each do |mode|
        OutputVars.ComponentLoadsMap.each do |component, component_var|
          result << OpenStudio::IdfObject.load("EnergyManagementSystem:OutputVariable,#{mode}_#{component_var}_hourly_outvar,#{mode}_#{component_var},Summed,ZoneTimestep,#{loads_program.name},J;").get
          result << OpenStudio::IdfObject.load("Output:Variable,*,#{mode}_#{component_var}_hourly_outvar,hourly;").get
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

    hourly_output_fuel_consumptions = runner.getBoolArgumentValue("hourly_output_fuel_consumptions", user_arguments)
    hourly_output_zone_temperatures = runner.getBoolArgumentValue("hourly_output_zone_temperatures", user_arguments)
    hourly_output_total_loads = runner.getBoolArgumentValue("hourly_output_total_loads", user_arguments)
    hourly_output_component_loads = runner.getBoolArgumentValue("hourly_output_component_loads", user_arguments)

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

    hpxml_path = model.getBuilding.additionalProperties.getFeatureAsString("hpxml_path").get

    @hpxml_doc = XMLHelper.parse_file(hpxml_path)
    output_dir = File.dirname(hpxml_path)

    # Error Checking
    @tolerance = 0.1 # MMBtu

    # Retrieve HPXML->E+ object name maps
    hvac_map = eval(model.getBuilding.additionalProperties.getFeatureAsString("hvac_map").get)
    dhw_map = eval(model.getBuilding.additionalProperties.getFeatureAsString("dhw_map").get)

    # Set paths
    @eri_design = XMLHelper.get_value(@hpxml_doc, "/HPXML/SoftwareInfo/extension/ERICalculation/Design")
    if not @eri_design.nil?
      design_name = @eri_design.gsub(' ', '')
      summary_output_csv_path = File.join(output_dir, "#{design_name}.csv")
      eri_output_csv_path = File.join(output_dir, "#{design_name}_ERI.csv")
      hourly_output_csv_path = File.join(output_dir, "#{design_name}_Hourly.csv")
    else
      summary_output_csv_path = File.join(output_dir, "results.csv")
      eri_output_csv_path = nil
      hourly_output_csv_path = File.join(output_dir, "results_hourly.csv")
    end

    # Annual outputs
    outputs = {}
    get_hpxml_values(outputs)
    get_sim_outputs(outputs, hvac_map, dhw_map)
    if not check_for_errors(runner, outputs)
      return false
    end
    if not write_summary_output_results(outputs, summary_output_csv_path)
      return false
    end

    report_sim_outputs(outputs, runner)
    write_eri_output_results(outputs, eri_output_csv_path)

    # Hourly outputs
    hourly_outputs = []
    get_sim_hourly_outputs(model, hourly_outputs,
                           hourly_output_fuel_consumptions,
                           hourly_output_zone_temperatures,
                           hourly_output_total_loads,
                           hourly_output_component_loads)
    write_hourly_output_results(hourly_outputs, hourly_output_csv_path)

    return true
  end

  def get_hpxml_values(outputs)
    # HPXML Summary
    bldg_details = @hpxml_doc.elements["/HPXML/Building/BuildingDetails"]
    outputs[:hpxml_cfa] = Float(XMLHelper.get_value(bldg_details, "BuildingSummary/BuildingConstruction/ConditionedFloorArea"))
    outputs[:hpxml_nbr] = Float(XMLHelper.get_value(bldg_details, "BuildingSummary/BuildingConstruction/NumberofBedrooms"))
    outputs[:hpxml_nst] = Float(XMLHelper.get_value(bldg_details, "BuildingSummary/BuildingConstruction/NumberofConditionedFloorsAboveGrade"))

    # HPXML Systems
    set_hpxml_systems()
    outputs[:hpxml_dse_heats] = get_hpxml_dse_heats()
    outputs[:hpxml_dse_cools] = get_hpxml_dse_cools()
    outputs[:hpxml_heat_fuels] = get_hpxml_heat_fuels()
    outputs[:hpxml_dwh_fuels] = get_hpxml_dhw_fuels()
    outputs[:hpxml_eec_heats] = get_hpxml_eec_heats()
    outputs[:hpxml_eec_cools] = get_hpxml_eec_cools()
    outputs[:hpxml_eec_dhws] = get_hpxml_eec_dhws()
    outputs[:hpxml_heat_sys_ids] = outputs[:hpxml_eec_heats].keys
    outputs[:hpxml_cool_sys_ids] = outputs[:hpxml_eec_cools].keys
    outputs[:hpxml_dhw_sys_ids] = outputs[:hpxml_eec_dhws].keys
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

  def get_hpxml_dse_heats()
    dse_heats = {}
    @hpxml_doc.elements.each("/HPXML/Building/BuildingDetails/Systems/HVAC/HVACDistribution") do |hvac_dist|
      dist_id = hvac_dist.elements["SystemIdentifier"].attributes["id"]
      dse_heat_raw = XMLHelper.get_value(hvac_dist, "AnnualHeatingDistributionSystemEfficiency")
      if dse_heat_raw.nil?
        dse_heat = 1.0
      else
        dse_heat = Float(dse_heat_raw)
      end
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

    # All HVAC systems not attached to a distribution system get DSE = 1
    @htgs.each do |htg_system|
      next unless htg_system.elements["DistributionSystem"].nil?

      sys_id = get_system_or_seed_id(htg_system)
      dse_heats[sys_id] = 1.0
    end
    @hp_htgs.each do |heat_pump|
      next unless heat_pump.elements["DistributionSystem"].nil?

      sys_id = get_system_or_seed_id(heat_pump)
      dse_heats[sys_id] = 1.0

      if is_dfhp(heat_pump)
        # Also apply to dual-fuel heat pump backup system
        dse_heats[dfhp_backup_sys_id(sys_id)] = 1.0
      end
    end

    return dse_heats
  end

  def get_hpxml_dse_cools()
    dse_cools = {}

    @hpxml_doc.elements.each("/HPXML/Building/BuildingDetails/Systems/HVAC/HVACDistribution") do |hvac_dist|
      dist_id = hvac_dist.elements["SystemIdentifier"].attributes["id"]
      dse_cool_raw = XMLHelper.get_value(hvac_dist, "AnnualCoolingDistributionSystemEfficiency")
      if dse_cool_raw.nil?
        dse_cool = 1.0
      else
        dse_cool = Float(dse_cool_raw)
      end
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

    # All HVAC systems not attached to a distribution system get DSE = 1
    @clgs.each do |clg_system|
      next unless clg_system.elements["DistributionSystem"].nil?

      sys_id = get_system_or_seed_id(clg_system)
      dse_cools[sys_id] = 1.0
    end
    @hp_clgs.each do |heat_pump|
      next unless heat_pump.elements["DistributionSystem"].nil?

      sys_id = get_system_or_seed_id(heat_pump)
      dse_cools[sys_id] = 1.0

      if is_dfhp(heat_pump)
        # Also apply to dual-fuel heat pump backup system
        dse_cools[dfhp_backup_sys_id(sys_id)] = 1.0
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
    return UnitConversions.convert(@sqlFile.execAndReturnFirstDouble(query).get, "GJ", "MBtu")
  end

  def get_report_variable_data_annual_mbtu(key_values_list, variable_names_list, not_key: false)
    keys = "'" + key_values_list.join("','") + "'"
    vars = "'" + variable_names_list.join("','") + "'"
    if not_key
      s_not = "NOT "
    else
      s_not = ""
    end
    query = "SELECT SUM(VariableValue/1000000000) FROM ReportVariableData WHERE ReportVariableDataDictionaryIndex IN (SELECT ReportVariableDataDictionaryIndex FROM ReportVariableDataDictionary WHERE VariableType='Sum' AND KeyValue #{s_not}IN (#{keys}) AND VariableName IN (#{vars}) AND ReportingFrequency='Run Period' AND VariableUnits='J')"
    return UnitConversions.convert(@sqlFile.execAndReturnFirstDouble(query).get, "GJ", "MBtu")
  end

  def get_tabular_data_value(report_name, report_for_string, table_name, row_name, col_name, units)
    query = "SELECT SUM(Value) FROM TabularDataWithStrings WHERE ReportName='#{report_name}' AND ReportForString='#{report_for_string}' AND TableName='#{table_name}' AND RowName='#{row_name}' AND ColumnName='#{col_name}' AND Units='#{units}'"
    return @sqlFile.execAndReturnFirstDouble(query).get
  end

  def get_sim_outputs(outputs, hvac_map, dhw_map)
    # Building Space Heating/Cooling Loads (total heating/cooling energy delivered including backup ideal air system)
    outputs[:loadHeatingBldg] = get_report_meter_data_annual_mbtu("Heating:EnergyTransfer")
    outputs[:loadCoolingBldg] = get_report_meter_data_annual_mbtu("Cooling:EnergyTransfer")

    # Peak Building Space Heating/Cooling Loads (total heating/cooling energy delivered including backup ideal air system)
    outputs[:peakLoadHeatingBldg] = UnitConversions.convert(get_tabular_data_value("EnergyMeters", "Entire Facility", "Annual and Peak Values - Other", "Heating:EnergyTransfer", "Maximum Value", "W"), "Wh", "kBtu")
    outputs[:peakLoadCoolingBldg] = UnitConversions.convert(get_tabular_data_value("EnergyMeters", "Entire Facility", "Annual and Peak Values - Other", "Cooling:EnergyTransfer", "Maximum Value", "W"), "Wh", "kBtu")

    # Building Unmet Space Heating/Cooling Load (heating/cooling energy delivered by backup ideal air system)
    outputs[:unmetLoadHeatingBldg] = get_report_meter_data_annual_mbtu("Heating:DistrictHeating")
    outputs[:unmetLoadCoolingBldg] = get_report_meter_data_annual_mbtu("Cooling:DistrictCooling")

    # Peak Electricity Consumption
    outputs[:peakElecSummerTotal] = get_tabular_data_value("PEAK ELECTRICITY SUMMER TOTAL", "Meter", "Custom Monthly Report", "Maximum of Months", "ELECTRICITY:FACILITY {MAX FOR HOURS SHOWN", "W")
    outputs[:peakElecWinterTotal] = get_tabular_data_value("PEAK ELECTRICITY WINTER TOTAL", "Meter", "Custom Monthly Report", "Maximum of Months", "ELECTRICITY:FACILITY {MAX FOR HOURS SHOWN", "W")

    # Electricity categories
    outputs[:elecTotal] = get_report_meter_data_annual_mbtu("Electricity:Facility")
    outputs[:elecIntLighting] = get_report_meter_data_annual_mbtu("#{Constants.ObjectNameInteriorLighting}:InteriorLights:Electricity")
    outputs[:elecExtLighting] = get_report_meter_data_annual_mbtu("ExteriorLights:Electricity")
    outputs[:elecGrgLighting] = get_report_meter_data_annual_mbtu("#{Constants.ObjectNameGarageLighting}:InteriorLights:Electricity")
    outputs[:elecAppliances] = get_report_meter_data_annual_mbtu("InteriorEquipment:Electricity")
    outputs[:elecPV] = get_report_meter_data_annual_mbtu("ElectricityProduced:Facility")
    outputs[:elecFridge] = get_report_meter_data_annual_mbtu("#{Constants.ObjectNameRefrigerator}:InteriorEquipment:Electricity")
    outputs[:elecDishwasher] = get_report_meter_data_annual_mbtu("#{Constants.ObjectNameDishwasher}:InteriorEquipment:Electricity")
    outputs[:elecClothesWasher] = get_report_meter_data_annual_mbtu("#{Constants.ObjectNameClothesWasher}:InteriorEquipment:Electricity")
    outputs[:elecClothesDryer] = get_report_meter_data_annual_mbtu("#{Constants.ObjectNameClothesDryer}:InteriorEquipment:Electricity")
    outputs[:elecMELs] = get_report_meter_data_annual_mbtu("#{Constants.ObjectNameMiscPlugLoads}:InteriorEquipment:Electricity")
    outputs[:elecTV] = get_report_meter_data_annual_mbtu("#{Constants.ObjectNameMiscTelevision}:InteriorEquipment:Electricity")
    outputs[:elecRangeOven] = get_report_meter_data_annual_mbtu("#{Constants.ObjectNameCookingRange}:InteriorEquipment:Electricity")
    outputs[:elecCeilingFan] = get_report_meter_data_annual_mbtu("#{Constants.ObjectNameCeilingFan}:InteriorEquipment:Electricity")
    outputs[:elecMechVent] = get_report_meter_data_annual_mbtu("#{Constants.ObjectNameMechanicalVentilationHouseFan}:InteriorEquipment:Electricity")
    outputs[:elecWholeHouseFan] = get_report_meter_data_annual_mbtu("#{Constants.ObjectNameWholeHouseFan}:InteriorEquipment:Electricity")

    # Gas categories
    outputs[:gasTotal] = get_report_meter_data_annual_mbtu("Gas:Facility")
    outputs[:gasAppliances] = get_report_meter_data_annual_mbtu("InteriorEquipment:Gas")
    outputs[:gasClothesDryer] = get_report_meter_data_annual_mbtu("#{Constants.ObjectNameClothesDryer}:InteriorEquipment:Gas")
    outputs[:gasRangeOven] = get_report_meter_data_annual_mbtu("#{Constants.ObjectNameCookingRange}:InteriorEquipment:Gas")

    # Fuel oil categories
    outputs[:oilTotal] = get_report_meter_data_annual_mbtu("FuelOil#1:Facility")
    outputs[:oilAppliances] = get_report_meter_data_annual_mbtu("InteriorEquipment:FuelOil#1")
    outputs[:oilClothesDryer] = get_report_meter_data_annual_mbtu("#{Constants.ObjectNameClothesDryer}:InteriorEquipment:FuelOil#1")
    outputs[:oilRangeOven] = get_report_meter_data_annual_mbtu("#{Constants.ObjectNameCookingRange}:InteriorEquipment:FuelOil#1")

    # Propane categories
    outputs[:propaneTotal] = get_report_meter_data_annual_mbtu("Propane:Facility")
    outputs[:propaneAppliances] = get_report_meter_data_annual_mbtu("InteriorEquipment:Propane")
    outputs[:propaneClothesDryer] = get_report_meter_data_annual_mbtu("#{Constants.ObjectNameClothesDryer}:InteriorEquipment:Propane")
    outputs[:propaneRangeOven] = get_report_meter_data_annual_mbtu("#{Constants.ObjectNameCookingRange}:InteriorEquipment:Propane")

    # Space Heating (by System)
    outputs[:elecHeatingBySystem] = {}
    outputs[:gasHeatingBySystem] = {}
    outputs[:oilHeatingBySystem] = {}
    outputs[:propaneHeatingBySystem] = {}
    outputs[:loadHeatingBySystem] = {}
    dfhp_loads = get_dfhp_loads(outputs, hvac_map) # Calculate dual-fuel heat pump load
    outputs[:hpxml_heat_sys_ids].each do |sys_id|
      ep_output_names, dfhp_primary, dfhp_backup = get_ep_output_names_for_hvac_heating(hvac_map, sys_id)
      keys = ep_output_names.map(&:upcase)

      # Energy Use
      elecHeatingBySystemRaw = get_report_variable_data_annual_mbtu(keys, get_all_var_keys(OutputVars.SpaceHeatingElectricity))
      gasHeatingBySystemRaw = get_report_variable_data_annual_mbtu(keys, get_all_var_keys(OutputVars.SpaceHeatingNaturalGas))
      oilHeatingBySystemRaw = get_report_variable_data_annual_mbtu(keys, get_all_var_keys(OutputVars.SpaceHeatingFuelOil))
      propaneHeatingBySystemRaw = get_report_variable_data_annual_mbtu(keys, get_all_var_keys(OutputVars.SpaceHeatingPropane))

      # Disaggregated Fan Energy Use
      elecHeatingBySystemRaw += get_report_variable_data_annual_mbtu(["EMS"], ep_output_names.select { |name| name.end_with? Constants.ObjectNameFanPumpDisaggregatePrimaryHeat or name.end_with? Constants.ObjectNameFanPumpDisaggregateBackupHeat })

      # Apply distribution system efficiency (DSE)
      outputs[:elecHeatingBySystem][sys_id] = elecHeatingBySystemRaw / outputs[:hpxml_dse_heats][sys_id]
      outputs[:gasHeatingBySystem][sys_id] = gasHeatingBySystemRaw / outputs[:hpxml_dse_heats][sys_id]
      outputs[:oilHeatingBySystem][sys_id] = oilHeatingBySystemRaw / outputs[:hpxml_dse_heats][sys_id]
      outputs[:propaneHeatingBySystem][sys_id] = propaneHeatingBySystemRaw / outputs[:hpxml_dse_heats][sys_id]
      outputs[:elecTotal] += (outputs[:elecHeatingBySystem][sys_id] - elecHeatingBySystemRaw)
      outputs[:gasTotal] += (outputs[:gasHeatingBySystem][sys_id] - gasHeatingBySystemRaw)
      outputs[:oilTotal] += (outputs[:oilHeatingBySystem][sys_id] - oilHeatingBySystemRaw)
      outputs[:propaneTotal] += (outputs[:propaneHeatingBySystem][sys_id] - propaneHeatingBySystemRaw)

      # Reference Load
      if [Constants.CalcTypeERIReferenceHome, Constants.CalcTypeERIIndexAdjustmentReferenceHome].include? @eri_design
        outputs[:loadHeatingBySystem][sys_id] = split_htg_load_to_system_by_fraction(sys_id, outputs[:loadHeatingBldg], dfhp_loads)
      end
    end

    # Space Cooling (by System)
    outputs[:elecCoolingBySystem] = {}
    outputs[:loadCoolingBySystem] = {}
    outputs[:hpxml_cool_sys_ids].each do |sys_id|
      ep_output_names = get_ep_output_names_for_hvac_cooling(hvac_map, sys_id)
      keys = ep_output_names.map(&:upcase)

      # Energy Use
      elecCoolingBySystemRaw = get_report_variable_data_annual_mbtu(keys, get_all_var_keys(OutputVars.SpaceCoolingElectricity))

      # Disaggregated Fan Energy Use
      elecCoolingBySystemRaw += get_report_variable_data_annual_mbtu(["EMS"], ep_output_names.select { |name| name.end_with? Constants.ObjectNameFanPumpDisaggregateCool })

      # Apply distribution system efficiency (DSE)
      outputs[:elecCoolingBySystem][sys_id] = elecCoolingBySystemRaw / outputs[:hpxml_dse_cools][sys_id]
      outputs[:elecTotal] += (outputs[:elecCoolingBySystem][sys_id] - elecCoolingBySystemRaw)

      # Reference Load
      if [Constants.CalcTypeERIReferenceHome, Constants.CalcTypeERIIndexAdjustmentReferenceHome].include? @eri_design
        outputs[:loadCoolingBySystem][sys_id] = split_clg_load_to_system_by_fraction(sys_id, outputs[:loadCoolingBldg])
      end
    end

    # Water Heating (by System)
    outputs[:elecHotWaterBySystem] = {}
    outputs[:elecHotWaterRecircPumpBySystem] = {}
    outputs[:elecHotWaterSolarThermalPumpBySystem] = {}
    outputs[:gasHotWaterBySystem] = {}
    outputs[:oilHotWaterBySystem] = {}
    outputs[:propaneHotWaterBySystem] = {}
    outputs[:loadHotWaterBySystem] = {}
    outputs[:loadHotWaterDesuperheater] = 0
    outputs[:loadHotWaterSolarThermal] = 0
    solar_keys = nil
    outputs[:hpxml_dhw_sys_ids].each do |sys_id|
      ep_output_names = get_ep_output_names_for_water_heating(dhw_map, sys_id)
      keys = ep_output_names.map(&:upcase)

      # Energy Use
      elecHotWaterBySystemRaw = get_report_variable_data_annual_mbtu(keys, get_all_var_keys(OutputVars.WaterHeatingElectricity))
      gasHotWaterBySystemRaw = get_report_variable_data_annual_mbtu(keys, get_all_var_keys(OutputVars.WaterHeatingNaturalGas))
      oilHotWaterBySystemRaw = get_report_variable_data_annual_mbtu(keys, get_all_var_keys(OutputVars.WaterHeatingFuelOil))
      propaneHotWaterBySystemRaw = get_report_variable_data_annual_mbtu(keys, get_all_var_keys(OutputVars.WaterHeatingPropane))

      # Electricity Use - Recirc Pump
      outputs[:elecHotWaterRecircPumpBySystem][sys_id] = get_report_variable_data_annual_mbtu(keys, get_all_var_keys(OutputVars.WaterHeatingElectricityRecircPump))
      outputs[:elecAppliances] -= outputs[:elecHotWaterRecircPumpBySystem][sys_id]

      # Electricity Use - Solar Thermal Pump
      outputs[:elecHotWaterSolarThermalPumpBySystem][sys_id] = get_report_variable_data_annual_mbtu(keys, get_all_var_keys(OutputVars.WaterHeatingElectricitySolarThermalPump))

      # Building Hot Water Load (Delivered Energy)
      outputs[:loadHotWaterBySystem][sys_id] = get_report_variable_data_annual_mbtu(keys, get_all_var_keys(OutputVars.WaterHeatingLoad))

      # Hot Water Load - Desuperheater
      outputs[:loadHotWaterDesuperheater] += get_report_variable_data_annual_mbtu(["EMS"], ep_output_names.select { |name| name.include? Constants.ObjectNameDesuperheaterLoad(nil) })

      # Hot Water Load - Solar Thermal
      solar_keys = ep_output_names.select { |name| name.include? Constants.ObjectNameSolarHotWater }.map(&:upcase)
      outputs[:loadHotWaterSolarThermal] += get_report_variable_data_annual_mbtu(solar_keys, get_all_var_keys(OutputVars.WaterHeaterLoadSolarThermal))

      # Apply solar fraction to load for simple solar water heating systems
      solar_fraction = get_dhw_solar_fraction(sys_id)
      if solar_fraction > 0
        orig_load = outputs[:loadHotWaterBySystem][sys_id]
        outputs[:loadHotWaterBySystem][sys_id] /= (1.0 - solar_fraction)
        outputs[:loadHotWaterSolarThermal] = outputs[:loadHotWaterBySystem][sys_id] - orig_load
      end

      # Combi boiler water system
      hvac_id = get_combi_hvac_id(sys_id)
      if not hvac_id.nil?
        hx_load = -1 * get_report_variable_data_annual_mbtu(keys, get_all_var_keys(OutputVars.WaterHeatingCombiBoilerHeatExchanger))
        htg_load = get_report_variable_data_annual_mbtu(keys, get_all_var_keys(OutputVars.WaterHeatingCombiBoiler))

        # Split combi boiler system energy use by water system load fraction
        htg_ec_elec = outputs[:elecHeatingBySystem][hvac_id]
        htg_ec_gas = outputs[:gasHeatingBySystem][hvac_id]
        htg_ec_oil = outputs[:oilHeatingBySystem][hvac_id]
        htg_ec_propane = outputs[:propaneHeatingBySystem][hvac_id]

        { :elecHotWaterBySystem => [elecHotWaterBySystemRaw, :elecHeatingBySystem, :elecTotal],
          :gasHotWaterBySystem => [gasHotWaterBySystemRaw, :gasHeatingBySystem, :gasTotal],
          :oilHotWaterBySystem => [oilHotWaterBySystemRaw, :oilHeatingBySystem, :oilTotal],
          :propaneHotWaterBySystem => [propaneHotWaterBySystemRaw, :propaneHeatingBySystem, :propaneTotal] }.each do |hotWaterBySystem, vals|
          htg_ec = outputs[vals[1]][hvac_id]
          outputs[hotWaterBySystem][sys_id] = vals[0] + get_combi_water_system_ec(hx_load, htg_load, htg_ec) * outputs[:hpxml_dse_heats][hvac_id] # revert DSE for hot water results
          outputs[vals[1]][hvac_id] -= get_combi_water_system_ec(hx_load, htg_load, htg_ec)
          outputs[vals[2]] -= get_combi_water_system_ec(hx_load, htg_load, htg_ec) * (1.0 - outputs[:hpxml_dse_heats][hvac_id])
        end
      else
        outputs[:elecHotWaterBySystem][sys_id] = elecHotWaterBySystemRaw
        outputs[:gasHotWaterBySystem][sys_id] = gasHotWaterBySystemRaw
        outputs[:oilHotWaterBySystem][sys_id] = oilHotWaterBySystemRaw
        outputs[:propaneHotWaterBySystem][sys_id] = propaneHotWaterBySystemRaw
      end

      # EC adjustment
      ec_adj = get_report_variable_data_annual_mbtu(["EMS"], ep_output_names.select { |name| name.include? Constants.ObjectNameWaterHeaterAdjustment(nil) })

      # Desuperheater adjustment
      desuperheater_adj = get_report_variable_data_annual_mbtu(["EMS"], ep_output_names.select { |name| name.include? Constants.ObjectNameDesuperheaterEnergy(nil) })

      # Adjust water heater/appliances energy consumptions for above adjustments
      tot_adj = ec_adj + desuperheater_adj
      if outputs[:gasHotWaterBySystem][sys_id] > 0
        outputs[:gasHotWaterBySystem][sys_id] += tot_adj
        outputs[:gasAppliances] -= tot_adj
      elsif outputs[:oilHotWaterBySystem][sys_id] > 0
        outputs[:oilHotWaterBySystem][sys_id] += tot_adj
        outputs[:oilAppliances] -= tot_adj
      elsif outputs[:propaneHotWaterBySystem][sys_id] > 0
        outputs[:propaneHotWaterBySystem][sys_id] += tot_adj
        outputs[:propaneAppliances] -= tot_adj
      else
        outputs[:elecHotWaterBySystem][sys_id] += tot_adj
        outputs[:elecAppliances] -= tot_adj
      end
    end

    outputs[:elecHeating] = outputs[:elecHeatingBySystem].values.inject(0, :+)
    outputs[:elecCooling] = outputs[:elecCoolingBySystem].values.inject(0, :+)
    outputs[:elecHotWater] = outputs[:elecHotWaterBySystem].values.inject(0, :+)
    outputs[:elecHotWaterRecircPump] = outputs[:elecHotWaterRecircPumpBySystem].values.inject(0, :+)
    outputs[:elecHotWaterSolarThermalPump] = outputs[:elecHotWaterSolarThermalPumpBySystem].values.inject(0, :+)
    outputs[:gasHeating] = outputs[:gasHeatingBySystem].values.inject(0, :+)
    outputs[:gasHotWater] = outputs[:gasHotWaterBySystem].values.inject(0, :+)
    outputs[:oilHeating] = outputs[:oilHeatingBySystem].values.inject(0, :+)
    outputs[:oilHotWater] = outputs[:oilHotWaterBySystem].values.inject(0, :+)
    outputs[:propaneHeating] = outputs[:propaneHeatingBySystem].values.inject(0, :+)
    outputs[:propaneHotWater] = outputs[:propaneHotWaterBySystem].values.inject(0, :+)
    outputs[:loadHotWaterDelivered] = outputs[:loadHotWaterBySystem].values.inject(0, :+)

    # Hot Water Load - Tank Losses (excluding solar storage tank)
    outputs[:loadHotWaterTankLosses] = get_report_variable_data_annual_mbtu(solar_keys, ["Water Heater Heat Loss Energy"], not_key: true)
    if outputs[:loadHotWaterTankLosses] < 0
      outputs[:loadHotWaterTankLosses] *= -1
    end

    # Component Loads
    { "Heating" => "htg", "Cooling" => "clg" }.each do |mode, mode_var|
      OutputVars.ComponentLoadsMap.each do |component, component_var|
        outputs["componentLoad#{mode}#{component}"] = get_report_variable_data_annual_mbtu(["EMS"], ["#{mode_var}_#{component_var}_outvar"])
      end
    end
  end

  def check_for_errors(runner, outputs)
    all_total = outputs[:elecTotal] + outputs[:gasTotal] + outputs[:oilTotal] + outputs[:propaneTotal]
    if all_total == 0
      runner.registerError("Processing output unsuccessful.")
      return false
    end

    sum_elec_categories = (outputs[:elecHeating] +
                           outputs[:elecCooling] +
                           outputs[:elecHotWater] +
                           outputs[:elecHotWaterRecircPump] +
                           outputs[:elecHotWaterSolarThermalPump] +
                           outputs[:elecIntLighting] +
                           outputs[:elecGrgLighting] +
                           outputs[:elecExtLighting] +
                           outputs[:elecAppliances])
    if (outputs[:elecTotal] - sum_elec_categories).abs > @tolerance
      runner.registerError("Electric category end uses (#{sum_elec_categories}) do not sum to total (#{outputs[:elecTotal]}).\n#{outputs.to_s}")
      return false
    end

    sum_gas_categories = (outputs[:gasHeating] +
                          outputs[:gasHotWater] +
                          outputs[:gasAppliances])
    if (outputs[:gasTotal] - sum_gas_categories).abs > @tolerance
      runner.registerError("Natural gas category end uses (#{sum_gas_categories}) do not sum to total (#{outputs[:gasTotal]}).\n#{outputs.to_s}")
      return false
    end

    sum_oil_categories = (outputs[:oilHeating] +
                          outputs[:oilHotWater] +
                          outputs[:oilAppliances])
    if (outputs[:oilTotal] - sum_oil_categories).abs > @tolerance
      runner.registerError("Oil fuel category end uses (#{sum_oil_categories}) do not sum to total (#{outputs[:oilTotal]}).\n#{outputs.to_s}")
      return false
    end

    sum_propane_categories = (outputs[:propaneHeating] +
                              outputs[:propaneHotWater] +
                              outputs[:propaneAppliances])
    if (outputs[:propaneTotal] - sum_propane_categories).abs > @tolerance
      runner.registerError("Propane fuel category end uses (#{sum_propane_categories}) do not sum to total (#{outputs[:propaneTotal]}).\n#{outputs.to_s}")
      return false
    end

    sum_elec_appliances = (outputs[:elecFridge] +
                           outputs[:elecDishwasher] +
                           outputs[:elecClothesWasher] +
                           outputs[:elecClothesDryer] +
                           outputs[:elecMELs] +
                           outputs[:elecTV] +
                           outputs[:elecRangeOven] +
                           outputs[:elecCeilingFan] +
                           outputs[:elecMechVent] +
                           outputs[:elecWholeHouseFan])
    if (outputs[:elecAppliances] - sum_elec_appliances).abs > @tolerance
      runner.registerError("Electric appliances (#{sum_elec_appliances}) do not sum to total (#{outputs[:elecAppliances]}).\n#{outputs.to_s}")
      return false
    end

    sum_gas_appliances = (outputs[:gasClothesDryer] + outputs[:gasRangeOven])
    if (outputs[:gasAppliances] - sum_gas_appliances).abs > @tolerance
      runner.registerError("Natural gas appliances (#{sum_gas_appliances}) do not sum to total (#{outputs[:gasAppliances]}).\n#{outputs.to_s}")
      return false
    end

    sum_oil_appliances = (outputs[:oilClothesDryer] + outputs[:oilRangeOven])
    if (outputs[:oilAppliances] - sum_oil_appliances).abs > @tolerance
      runner.registerError("Oil fuel appliances (#{sum_oil_appliances}) do not sum to total (#{outputs[:oilAppliances]}).\n#{outputs.to_s}")
      return false
    end

    sum_propane_appliances = (outputs[:propaneClothesDryer] + outputs[:propaneRangeOven])
    if (outputs[:propaneAppliances] - sum_propane_appliances).abs > @tolerance
      runner.registerError("Propane fuel appliances (#{sum_propane_appliances}) do not sum to total (#{outputs[:propaneAppliances]}).\n#{outputs.to_s}")
      return false
    end

    # REUL check: system cooling/heating sum to total bldg load
    if [Constants.CalcTypeERIReferenceHome, Constants.CalcTypeERIIndexAdjustmentReferenceHome].include? @eri_design
      sum_sys_htg_load = outputs[:loadHeatingBySystem].values.inject(0) { |sum, value| sum + value }
      if (sum_sys_htg_load - outputs[:loadHeatingBldg]).abs > @tolerance
        runner.registerError("system heating load not sum to total building heating load")
        return false
      end

      sum_sys_clg_load = outputs[:loadCoolingBySystem].values.inject(0) { |sum, value| sum + value }
      if (sum_sys_clg_load - outputs[:loadCoolingBldg]).abs > @tolerance
        runner.registerError("system cooling load not sum to total building cooling load")
        return false
      end
    end

    return true
  end

  def report_sim_outputs(outputs, runner)
    from_units = "MBtu"
    total_site_units = "MBtu"
    elec_site_units = "kWh"
    gas_site_units = "therm"
    other_fuel_site_units = "MBtu"

    # ELECTRICITY

    report_sim_output(runner, "total_site_electricity_kwh", outputs[:elecTotal], from_units, elec_site_units)
    report_sim_output(runner, "net_site_electricity_kwh", (outputs[:elecTotal] - outputs[:elecPV]), from_units, elec_site_units)
    report_sim_output(runner, "electricity_heating_kwh", outputs[:elecHeating], from_units, elec_site_units)
    report_sim_output(runner, "electricity_cooling_kwh", outputs[:elecCooling], from_units, elec_site_units)
    report_sim_output(runner, "electricity_interior_lighting_kwh", outputs[:elecIntLighting], from_units, elec_site_units)
    report_sim_output(runner, "electricity_exterior_lighting_kwh", outputs[:elecExtLighting], from_units, elec_site_units)
    report_sim_output(runner, "electricity_garage_lighting_kwh", outputs[:elecGrgLighting], from_units, elec_site_units)
    report_sim_output(runner, "electricity_interior_equipment_kwh", outputs[:elecAppliances], from_units, elec_site_units)
    report_sim_output(runner, "electricity_water_systems_kwh", (outputs[:elecHotWater] + outputs[:elecHotWaterRecircPump] + outputs[:elecHotWaterSolarThermalPump]), from_units, elec_site_units)
    report_sim_output(runner, "electricity_pv_kwh", outputs[:elecPV], from_units, elec_site_units)

    # NATURAL GAS

    report_sim_output(runner, "total_site_natural_gas_therm", outputs[:gasTotal], from_units, gas_site_units)
    report_sim_output(runner, "natural_gas_heating_therm", outputs[:gasHeating], from_units, gas_site_units)
    report_sim_output(runner, "natural_gas_interior_equipment_therm", outputs[:gasAppliances], from_units, gas_site_units)
    report_sim_output(runner, "natural_gas_water_systems_therm", outputs[:gasHotWater], from_units, gas_site_units)

    # FUEL OIL

    report_sim_output(runner, "total_site_fuel_oil_mbtu", outputs[:oilTotal], from_units, other_fuel_site_units)
    report_sim_output(runner, "fuel_oil_heating_mbtu", outputs[:oilHeating], from_units, other_fuel_site_units)
    report_sim_output(runner, "fuel_oil_interior_equipment_mbtu", outputs[:oilAppliances], from_units, other_fuel_site_units)
    report_sim_output(runner, "fuel_oil_water_systems_mbtu", outputs[:oilHotWater], from_units, other_fuel_site_units)

    # PROPANE

    report_sim_output(runner, "total_site_propane_mbtu", outputs[:propaneTotal], from_units, other_fuel_site_units)
    report_sim_output(runner, "propane_heating_mbtu", outputs[:propaneHeating], from_units, other_fuel_site_units)
    report_sim_output(runner, "propane_interior_equipment_mbtu", outputs[:propaneAppliances], from_units, other_fuel_site_units)
    report_sim_output(runner, "propane_water_systems_mbtu", outputs[:propaneHotWater], from_units, other_fuel_site_units)

    # TOTAL
    report_sim_output(runner, "total_site_energy_mbtu", (outputs[:elecTotal] + outputs[:gasTotal] + outputs[:oilTotal] + outputs[:propaneTotal]), from_units, total_site_units)
    report_sim_output(runner, "net_site_energy_mbtu", (outputs[:elecTotal] - outputs[:elecPV] + outputs[:gasTotal] + outputs[:oilTotal] + outputs[:propaneTotal]), from_units, total_site_units)

    # FIXME: Check results are internally consistent
    # Replicate logic at end of write_summary_output_results() method, iterating through register values in runner.workflow.workflowSteps.
  end

  def write_summary_output_results(outputs, csv_path)
    results_out = []
    results_out << ["Electricity: Total (MBtu)", outputs[:elecTotal].round(2)]
    results_out << ["Electricity: Net (MBtu)", (outputs[:elecTotal] - outputs[:elecPV]).round(2)]
    results_out << ["Natural Gas: Total (MBtu)", outputs[:gasTotal].round(2)]
    results_out << ["Fuel Oil: Total (MBtu)", outputs[:oilTotal].round(2)]
    results_out << ["Propane: Total (MBtu)", outputs[:propaneTotal].round(2)]
    results_out << [nil] # line break
    results_out << ["Electricity: Heating (MBtu)", outputs[:elecHeating].round(2)]
    results_out << ["Electricity: Cooling (MBtu)", outputs[:elecCooling].round(2)]
    results_out << ["Electricity: Hot Water (MBtu)", outputs[:elecHotWater].round(2)]
    results_out << ["Electricity: Hot Water Recirc Pump (MBtu)", outputs[:elecHotWaterRecircPump].round(2)]
    results_out << ["Electricity: Hot Water Solar Thermal Pump (MBtu)", outputs[:elecHotWaterSolarThermalPump].round(2)]
    results_out << ["Electricity: Lighting Interior (MBtu)", outputs[:elecIntLighting].round(2)]
    results_out << ["Electricity: Lighting Garage (MBtu)", outputs[:elecGrgLighting].round(2)]
    results_out << ["Electricity: Lighting Exterior (MBtu)", outputs[:elecExtLighting].round(2)]
    results_out << ["Electricity: Mech Vent (MBtu)", outputs[:elecMechVent].round(2)]
    results_out << ["Electricity: Whole House Fan (MBtu)", outputs[:elecWholeHouseFan].round(2)]
    results_out << ["Electricity: Refrigerator (MBtu)", outputs[:elecFridge].round(2)]
    results_out << ["Electricity: Dishwasher (MBtu)", outputs[:elecDishwasher].round(2)]
    results_out << ["Electricity: Clothes Washer (MBtu)", outputs[:elecClothesWasher].round(2)]
    results_out << ["Electricity: Clothes Dryer (MBtu)", outputs[:elecClothesDryer].round(2)]
    results_out << ["Electricity: Range/Oven (MBtu)", outputs[:elecRangeOven].round(2)]
    results_out << ["Electricity: Ceiling Fan (MBtu)", outputs[:elecCeilingFan].round(2)]
    results_out << ["Electricity: Plug Loads (MBtu)", (outputs[:elecMELs] + outputs[:elecTV]).round(2)]
    if outputs[:elecPV] > 0
      results_out << ["Electricity: PV (MBtu)", -1.0 * outputs[:elecPV].round(2)]
    else
      results_out << ["Electricity: PV (MBtu)", 0.0]
    end
    results_out << ["Natural Gas: Heating (MBtu)", outputs[:gasHeating].round(2)]
    results_out << ["Natural Gas: Hot Water (MBtu)", outputs[:gasHotWater].round(2)]
    results_out << ["Natural Gas: Clothes Dryer (MBtu)", outputs[:gasClothesDryer].round(2)]
    results_out << ["Natural Gas: Range/Oven (MBtu)", outputs[:gasRangeOven].round(2)]
    results_out << ["Fuel Oil: Heating (MBtu)", outputs[:oilHeating].round(2)]
    results_out << ["Fuel Oil: Hot Water (MBtu)", outputs[:oilHotWater].round(2)]
    results_out << ["Fuel Oil: Clothes Dryer (MBtu)", outputs[:oilClothesDryer].round(2)]
    results_out << ["Fuel Oil: Range/Oven (MBtu)", outputs[:oilRangeOven].round(2)]
    results_out << ["Propane: Heating (MBtu)", outputs[:propaneHeating].round(2)]
    results_out << ["Propane: Hot Water (MBtu)", outputs[:propaneHotWater].round(2)]
    results_out << ["Propane: Clothes Dryer (MBtu)", outputs[:propaneClothesDryer].round(2)]
    results_out << ["Propane: Range/Oven (MBtu)", outputs[:propaneRangeOven].round(2)]
    results_out << [nil] # line break
    results_out << ["Annual Load: Heating (MBtu)", outputs[:loadHeatingBldg].round(2)]
    results_out << ["Annual Load: Cooling (MBtu)", outputs[:loadCoolingBldg].round(2)]
    results_out << ["Annual Load: Hot Water: Delivered (MBtu)", outputs[:loadHotWaterDelivered].round(2)]
    results_out << ["Annual Load: Hot Water: Tank Losses (MBtu)", outputs[:loadHotWaterTankLosses].round(2)]
    results_out << ["Annual Load: Hot Water: Desuperheater (MBtu)", outputs[:loadHotWaterDesuperheater].round(2)]
    results_out << ["Annual Load: Hot Water: Solar Thermal (MBtu)", outputs[:loadHotWaterSolarThermal].round(2)]
    results_out << [nil] # line break
    results_out << ["Annual Unmet Load: Heating (MBtu)", outputs[:unmetLoadHeatingBldg].round(2)]
    results_out << ["Annual Unmet Load: Cooling (MBtu)", outputs[:unmetLoadCoolingBldg].round(2)]
    results_out << [nil] # line break
    results_out << ["Peak Electricity: Winter Total (W)", outputs[:peakElecWinterTotal].round(2)]
    results_out << ["Peak Electricity: Summer Total (W)", outputs[:peakElecSummerTotal].round(2)]
    results_out << [nil] # line break
    results_out << ["Peak Load: Heating (kBtu)", outputs[:peakLoadHeatingBldg].round(2)]
    results_out << ["Peak Load: Cooling (kBtu)", outputs[:peakLoadCoolingBldg].round(2)]
    results_out << [nil] # line break
    { "Heating" => "htg", "Cooling" => "clg" }.each do |mode, mode_var|
      OutputVars.ComponentLoadsMap.each do |component, component_var|
        results_out << ["Component Load: #{mode}: #{component} (MBtu)", outputs["componentLoad#{mode}#{component}"].round(2)]
      end
    end

    CSV.open(csv_path, "wb") { |csv| results_out.to_a.each { |elem| csv << elem } }

    # Check results are internally consistent
    total_results = { "Electricity" => (outputs[:elecTotal] - outputs[:elecPV]).round(2),
                      "Natural Gas" => outputs[:gasTotal].round(2),
                      "Fuel Oil" => outputs[:oilTotal].round(2),
                      "Propane" => outputs[:propaneTotal].round(2) }

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
        runner.registerError("End uses (#{sum_end_use_results[fuel].round(1)}) do not sum to #{fuel} total (#{total_results[fuel].round(1)})).")
        return false
      end
    end

    return true
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

    results_out = []

    # Heating
    keys = outputs[:hpxml_heat_sys_ids]
    results_out << ["hpxml_heat_sys_ids"] + keys
    results_out << ["hpxml_heat_fuels"] + get_hash_values_in_order(keys, outputs[:hpxml_heat_fuels])
    results_out << ["hpxml_eec_heats"] + get_hash_values_in_order(keys, outputs[:hpxml_eec_heats])
    results_out << ["elecHeatingBySystem"] + get_hash_values_in_order(keys, outputs[:elecHeatingBySystem])
    results_out << ["gasHeatingBySystem"] + get_hash_values_in_order(keys, outputs[:gasHeatingBySystem])
    results_out << ["oilHeatingBySystem"] + get_hash_values_in_order(keys, outputs[:oilHeatingBySystem])
    results_out << ["propaneHeatingBySystem"] + get_hash_values_in_order(keys, outputs[:propaneHeatingBySystem])
    results_out << ["loadHeatingBySystem"] + get_hash_values_in_order(keys, outputs[:loadHeatingBySystem])
    results_out << [nil] # line break

    # Cooling
    keys = outputs[:hpxml_cool_sys_ids]
    results_out << ["hpxml_cool_sys_ids"] + keys
    results_out << ["hpxml_eec_cools"] + get_hash_values_in_order(keys, outputs[:hpxml_eec_cools])
    results_out << ["elecCoolingBySystem"] + get_hash_values_in_order(keys, outputs[:elecCoolingBySystem])
    results_out << ["loadCoolingBySystem"] + get_hash_values_in_order(keys, outputs[:loadCoolingBySystem])
    results_out << [nil] # line break

    # DHW
    keys = outputs[:hpxml_dhw_sys_ids]
    results_out << ["hpxml_dhw_sys_ids"] + keys
    results_out << ["hpxml_dwh_fuels"] + get_hash_values_in_order(keys, outputs[:hpxml_dwh_fuels])
    results_out << ["hpxml_eec_dhws"] + get_hash_values_in_order(keys, outputs[:hpxml_eec_dhws])
    results_out << ["elecHotWaterBySystem"] + get_hash_values_in_order(keys, outputs[:elecHotWaterBySystem])
    results_out << ["elecHotWaterRecircPumpBySystem"] + get_hash_values_in_order(keys, outputs[:elecHotWaterRecircPumpBySystem])
    results_out << ["elecHotWaterSolarThermalPumpBySystem"] + get_hash_values_in_order(keys, outputs[:elecHotWaterSolarThermalPumpBySystem])
    results_out << ["gasHotWaterBySystem"] + get_hash_values_in_order(keys, outputs[:gasHotWaterBySystem])
    results_out << ["oilHotWaterBySystem"] + get_hash_values_in_order(keys, outputs[:oilHotWaterBySystem])
    results_out << ["propaneHotWaterBySystem"] + get_hash_values_in_order(keys, outputs[:propaneHotWaterBySystem])
    results_out << ["loadHotWaterBySystem"] + get_hash_values_in_order(keys, outputs[:loadHotWaterBySystem])
    results_out << [nil] # line break

    # Total
    results_out << ["elecTotal", outputs[:elecTotal]]
    results_out << ["gasTotal", outputs[:gasTotal]]
    results_out << ["oilTotal", outputs[:oilTotal]]
    results_out << ["propaneTotal", outputs[:propaneTotal]]
    results_out << ["elecPV", outputs[:elecPV]]
    results_out << [nil] # line break

    # Breakout
    results_out << ["elecIntLighting", outputs[:elecIntLighting]]
    results_out << ["elecExtLighting", outputs[:elecExtLighting]]
    results_out << ["elecGrgLighting", outputs[:elecGrgLighting]]
    results_out << ["elecAppliances", outputs[:elecAppliances]]
    results_out << ["elecMELs", outputs[:elecMELs]]
    results_out << ["elecFridge", outputs[:elecFridge]]
    results_out << ["elecTV", outputs[:elecTV]]
    results_out << ["elecRangeOven", outputs[:elecRangeOven]]
    results_out << ["elecClothesDryer", outputs[:elecClothesDryer]]
    results_out << ["elecDishwasher", outputs[:elecDishwasher]]
    results_out << ["elecClothesWasher", outputs[:elecClothesWasher]]
    results_out << ["elecMechVent", outputs[:elecMechVent]]
    results_out << ["elecWholeHouseFan", outputs[:elecWholeHouseFan]]
    results_out << ["gasAppliances", outputs[:gasAppliances]]
    results_out << ["gasRangeOven", outputs[:gasRangeOven]]
    results_out << ["gasClothesDryer", outputs[:gasClothesDryer]]
    results_out << ["oilAppliances", outputs[:oilAppliances]]
    results_out << ["oilRangeOven", outputs[:oilRangeOven]]
    results_out << ["oilClothesDryer", outputs[:oilClothesDryer]]
    results_out << ["propaneAppliances", outputs[:propaneAppliances]]
    results_out << ["propaneRangeOven", outputs[:propaneRangeOven]]
    results_out << ["propaneClothesDryer", outputs[:propaneClothesDryer]]
    results_out << [nil] # line break

    # Misc
    results_out << ["hpxml_cfa", outputs[:hpxml_cfa]]
    results_out << ["hpxml_nbr", outputs[:hpxml_nbr]]
    results_out << ["hpxml_nst", outputs[:hpxml_nst]]

    CSV.open(csv_path, "wb") { |csv| results_out.to_a.each { |elem| csv << elem } }
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

  def get_sim_hourly_outputs(model, hourly_outputs,
                             hourly_output_fuel_consumptions,
                             hourly_output_zone_temperatures,
                             hourly_output_total_loads,
                             hourly_output_component_loads)

    generate_hourly_output = false
    generate_hourly_output = true if hourly_output_fuel_consumptions
    generate_hourly_output = true if hourly_output_zone_temperatures
    generate_hourly_output = true if hourly_output_total_loads
    generate_hourly_output = true if hourly_output_component_loads

    if generate_hourly_output
      # Generate CSV file with hourly output

      # Unit conversions
      j_to_kwh = UnitConversions.convert(1.0, "j", "kwh")
      j_to_kbtu = UnitConversions.convert(1.0, "j", "kbtu")

      # Header
      hourly_outputs << ["Hour"]

      if hourly_output_fuel_consumptions
        hourly_outputs[0] << "Electricity Use [kWh]"
        hourly_outputs[0] << "Natural Gas Use [kBtu]"
        hourly_outputs[0] << "Fuel Oil Use [kBtu]"
        hourly_outputs[0] << "Propane Use [kBtu]"
      end

      if hourly_output_zone_temperatures
        zone_names = []
        model.getThermalZones.each do |zone|
          next unless zone.floorArea > 1

          zone_names << zone.name.to_s.upcase
        end
        zone_names.sort!

        zone_names.each do |zone_name|
          hourly_outputs[0] << "#{zone_name.split.map(&:capitalize).join(' ')} Temperature [F]"
        end
      end

      if hourly_output_total_loads
        hourly_outputs[0] << "Heating Load - Total [kBtu]"
        hourly_outputs[0] << "Cooling Load - Total [kBtu]"
      end

      if hourly_output_component_loads
        ["Heating", "Cooling"].each do |mode|
          OutputVars.ComponentLoadsMap.each do |component, component_var|
            hourly_outputs[0] << "#{mode} Load - #{component} [kBtu]"
          end
        end
      end

      for hr in 1..8760
        hourly_outputs << [hr]
      end

      # Data
      if hourly_output_fuel_consumptions

        sum_fuel_uses = []
        { "Electricity:Facility" => j_to_kwh,
          "Gas:Facility" => j_to_kbtu,
          "FuelOil#1:Facility" => j_to_kbtu,
          "Propane:Facility" => j_to_kbtu }.each do |meter, unit_conv|
          query = "SELECT VariableValue*#{unit_conv} FROM ReportMeterData WHERE ReportMeterDataDictionaryIndex IN (SELECT ReportMeterDataDictionaryIndex FROM ReportMeterDataDictionary WHERE VariableName='#{meter}' AND ReportingFrequency='Hourly') ORDER BY TimeIndex"
          energy_uses = @sqlFile.execAndReturnVectorOfDouble(query).get
          energy_uses += [0.0] * 8760 if energy_uses.size == 0
          energy_uses.each_with_index do |energy_use, i|
            hourly_outputs[i + 1] << energy_use.round(2)
          end
          sum_fuel_uses << (energy_uses.inject(0, :+) / unit_conv) / 1000000000.0
        end
      end

      if hourly_output_zone_temperatures
        # Space temperatures
        zone_names.each do |zone_name|
          query = "SELECT (VariableValue*9.0/5.0)+32.0 FROM ReportVariableData WHERE ReportVariableDataDictionaryIndex IN (SELECT ReportVariableDataDictionaryIndex FROM ReportVariableDataDictionary WHERE VariableName='Zone Mean Air Temperature' AND KeyValue='#{zone_name}' AND ReportingFrequency='Hourly') ORDER BY TimeIndex"
          temperatures = @sqlFile.execAndReturnVectorOfDouble(query).get

          temperatures.each_with_index do |temperature, i|
            hourly_outputs[i + 1] << temperature.round(2)
          end
        end
      end

      if hourly_output_total_loads
        # FIXME: This needs to be updated when the new component loads algorithm is merged
        ["Heating:EnergyTransfer", "Cooling:EnergyTransfer"].each do |mode|
          query = "SELECT VariableValue*#{j_to_kbtu} FROM ReportMeterData WHERE ReportMeterDataDictionaryIndex IN (SELECT ReportMeterDataDictionaryIndex FROM ReportMeterDataDictionary WHERE VariableName='#{mode}' AND ReportingFrequency='Hourly') ORDER BY TimeIndex"
          results = @sqlFile.execAndReturnVectorOfDouble(query).get

          results.each_with_index do |load, i|
            hourly_outputs[i + 1] << load.round(2)
          end
        end
      end

      if hourly_output_component_loads
        ["htg", "clg"].each do |mode_var|
          OutputVars.ComponentLoadsMap.each do |component, component_var|
            query = "SELECT VariableValue*#{j_to_kbtu} FROM ReportVariableData WHERE ReportVariableDataDictionaryIndex = (SELECT ReportVariableDataDictionaryIndex FROM ReportVariableDataDictionary WHERE VariableType='Sum' AND KeyValue='EMS' AND VariableName='#{mode_var}_#{component_var}_hourly_outvar' AND ReportingFrequency='Hourly' AND VariableUnits='J')"
            results = @sqlFile.execAndReturnVectorOfDouble(query).get

            results.each_with_index do |component_load, i|
              next if i == 0 # EMS outputs lag by 1 hour

              hourly_outputs[i] << component_load.round(2)
            end
            hourly_outputs[8760] << results[-1].round(2) # Add final hour (use same value as previous hour)
          end
        end
      end

    end
  end

  def write_hourly_output_results(hourly_outputs, csv_path)
    if hourly_outputs.size > 0
      CSV.open(csv_path, "wb") { |csv| hourly_outputs.to_a.each { |elem| csv << elem } }
    end
  end

  def report_sim_output(runner, name, val, from_units = nil, to_units = nil)
    if from_units.nil? or to_units.nil? or from_units == to_units
      valInUnits = val
    else
      valInUnits = UnitConversions.convert(val, from_units, to_units)
    end
    runner.registerValue(name, valInUnits)
    runner.registerInfo("Registering #{valInUnits.round(2)} for #{name}.")
  end
end

# register the measure to be used by the application
SimOutputReport.new.registerWithApplication
