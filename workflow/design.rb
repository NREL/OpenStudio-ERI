# Used by energy_rating_index.rb.
# Separate ruby script to allow being called using system() on Windows.

require_relative "../measures/HPXMLtoOpenStudio/resources/meta_measure"

HourlyOutputZoneTemperatures = "Zone Temperatures".upcase
HourlyOutputFuelConsumptions = "Fuel Consumptions".upcase
HourlyOutputTotalLoads = "Total Loads".upcase
HourlyOutputComponentLoads = "Component Loads".upcase

def get_design_name_and_dir(output_dir, run)
  design_name = ""
  run.each do |x|
    next if x.nil?

    design_name += "_" if design_name.length > 0
    design_name += x
  end
  return design_name, File.join(output_dir, design_name.gsub(' ', ''))
end

def get_output_hpxml_path(resultsdir, designdir)
  return File.join(resultsdir, File.basename(designdir) + ".xml")
end

def run_design(basedir, output_dir, run, resultsdir, hpxml, debug, hourly_output)
  eri_design = run[0]
  design_name, designdir = get_design_name_and_dir(output_dir, run)
  hourly_outputs = get_enabled_hourly_outputs(hourly_output)

  # Use print instead of puts in here (see https://stackoverflow.com/a/5044669)
  print "[#{design_name}] Creating input...\n"
  output_hpxml_path, designdir = create_idf(run, basedir, output_dir, resultsdir, hpxml, debug, hourly_outputs, designdir, design_name)

  if not designdir.nil?
    print "[#{design_name}] Running simulation...\n"
    run_energyplus(designdir, debug)
    design_output = process_design_output(run, designdir, resultsdir, output_hpxml_path, hourly_outputs, design_name)
  end

  return output_hpxml_path
end

def get_enabled_hourly_outputs(hourly_output)
  hourly_outputs = []
  if hourly_output
    require 'csv'

    hourly_outputs_rows = CSV.read(File.join(File.dirname(__FILE__), "hourly_outputs.csv"), headers: false)
    hourly_outputs_rows.each do |hourly_output_row|
      next unless hourly_output_row[0].upcase.strip == 'TRUE'

      hourly_outputs << hourly_output_row[1].upcase.strip
    end

  end
  return hourly_outputs
end

def create_idf(run, basedir, output_dir, resultsdir, hpxml, debug, hourly_outputs, designdir, design_name)
  Dir.mkdir(designdir)

  OpenStudio::Logger.instance.standardOutLogger.setLogLevel(OpenStudio::Fatal)

  output_hpxml_path = get_output_hpxml_path(resultsdir, designdir)

  model = OpenStudio::Model::Model.new
  runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)
  measures_dir = File.join(File.dirname(__FILE__), "../measures")

  measures = {}

  if not run[0].nil?
    # Add 301 measure to workflow
    measure_subdir = "301EnergyRatingIndexRuleset"
    args = {}
    args['calc_type'] = run[0]
    args['hpxml_path'] = hpxml
    args['weather_dir'] = File.absolute_path(File.join(basedir, "..", "weather"))
    args['schemas_dir'] = File.absolute_path(File.join(basedir, "..", "measures", "HPXMLtoOpenStudio", "hpxml_schemas"))
    args['hpxml_output_path'] = output_hpxml_path
    update_args_hash(measures, measure_subdir, args)
  end

  # Add HPXML translator measure to workflow
  measure_subdir = "HPXMLtoOpenStudio"
  args = {}
  args['hpxml_path'] = output_hpxml_path
  args['weather_dir'] = File.absolute_path(File.join(basedir, "..", "weather"))
  args['schemas_dir'] = File.absolute_path(File.join(basedir, "..", "measures", "HPXMLtoOpenStudio", "hpxml_schemas"))
  args['epw_output_path'] = File.join(designdir, "in.epw")
  if debug
    args['osm_output_path'] = File.join(designdir, "in.osm")
  end
  args['map_tsv_dir'] = designdir
  update_args_hash(measures, measure_subdir, args)

  # Apply measures
  success = apply_measures(measures_dir, measures, runner, model)

  # Report warnings/errors
  File.open(File.join(designdir, 'run.log'), 'w') do |f|
    if debug
      runner.result.stepInfo.each do |s|
        f << "Info: #{s}\n"
      end
    end
    runner.result.stepWarnings.each do |s|
      f << "Warning: #{s}\n"
    end
    runner.result.stepErrors.each do |s|
      f << "Error: #{s}\n"
    end
  end

  if not success
    print "[#{design_name}] Creating input unsuccessful.\n"
    return output_hpxml_path, nil
  end

  # Add hourly output requests
  if hourly_outputs.include? HourlyOutputZoneTemperatures
    # Thermal zone temperatures:
    output_var = OpenStudio::Model::OutputVariable.new('Zone Mean Air Temperature', model)
    output_var.setReportingFrequency('hourly')
    output_var.setKeyValue('*')
  end
  if hourly_outputs.include? HourlyOutputFuelConsumptions
    # Energy use by fuel:
    ['Electricity:Facility', 'Gas:Facility', 'FuelOil#1:Facility', 'Propane:Facility'].each do |meter_fuel|
      output_meter = OpenStudio::Model::OutputMeter.new(model)
      output_meter.setName(meter_fuel)
      output_meter.setReportingFrequency('hourly')
    end
  end
  if hourly_outputs.include? HourlyOutputTotalLoads
    # Building heating/cooling loads
    # FIXME: This needs to be updated when the new component loads algorithm is merged
    ['Heating:EnergyTransfer', 'Cooling:EnergyTransfer'].each do |meter_load|
      output_meter = OpenStudio::Model::OutputMeter.new(model)
      output_meter.setName(meter_load)
      output_meter.setReportingFrequency('hourly')
    end
  end
  if hourly_outputs.include? HourlyOutputComponentLoads
    loads_program = nil
    model.getEnergyManagementSystemPrograms.each do |program|
      next unless program.name.to_s == "component_loads_program"

      loads_program = program
    end
    fail "Could not find component loads program." if loads_program.nil?

    ["htg", "clg"].each do |mode|
      get_component_load_map.each do |component, component_var|
        ems_output_var = OpenStudio::Model::EnergyManagementSystemOutputVariable.new(model, "#{mode}_#{component_var}")
        ems_output_var.setName("#{mode}_#{component_var}_hourly_outvar")
        ems_output_var.setTypeOfDataInVariable("Summed")
        ems_output_var.setUpdateFrequency("ZoneTimestep")
        ems_output_var.setEMSProgramOrSubroutineName(loads_program)
        ems_output_var.setUnits("J")

        output_var = OpenStudio::Model::OutputVariable.new(ems_output_var.name.to_s, model)
        output_var.setReportingFrequency('hourly')
        output_var.setKeyValue('*')
      end
    end
  end

  # Translate model
  forward_translator = OpenStudio::EnergyPlus::ForwardTranslator.new
  forward_translator.setExcludeLCCObjects(true)
  model_idf = forward_translator.translateModel(model)

  # Report warnings/errors
  File.open(File.join(designdir, 'run.log'), 'a') do |f|
    forward_translator.warnings.each do |s|
      f << "FT Warning: #{s.logMessage}\n"
    end
    forward_translator.errors.each do |s|
      f << "FT Error: #{s.logMessage}\n"
    end
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
    model_idf.addObject(OpenStudio::IdfObject.load("#{monthly_array.join(",").to_s};").get)
  end

  # Write model to IDF
  File.open(File.join(designdir, "in.idf"), 'w') { |f| f << model_idf.to_s }

  return output_hpxml_path, designdir
end

def run_energyplus(designdir, debug)
  # getEnergyPlusDirectory can be unreliable, using getOpenStudioCLI instead
  ep_path = File.absolute_path(File.join(OpenStudio.getOpenStudioCLI.to_s, '..', '..', 'EnergyPlus', 'energyplus'))
  command = "\"#{ep_path}\" -w in.epw in.idf > stdout-energyplus"
  if debug
    File.open(File.join(designdir, 'run.log'), 'a') do |f|
      f << "Executing command '#{command}' from working directory '#{designdir}'"
    end
  end
  Dir.chdir(designdir) do
    system(command, :err => IO.sysopen(File.join(designdir, 'stderr-energyplus'), 'w'))
  end
end

def process_design_output(run, designdir, resultsdir, output_hpxml_path, hourly_outputs, design_name)
  return nil if output_hpxml_path.nil?

  print "[#{design_name}] Processing output...\n"

  design_output, design_hourly_output = read_output(run[0], designdir, output_hpxml_path, hourly_outputs, design_name)
  return if design_output.nil?

  write_summary_output_results(resultsdir, design_name, design_output, design_hourly_output)
  write_eri_output_results(resultsdir, design_name, design_output)

  print "[#{design_name}] Done.\n"

  return design_output
end

def get_combi_hvac_id(hpxml_doc, sys_id, dhws)
  dhws.each do |dhw_system|
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

def get_component_load_map
  return { "Roofs" => "roofs",
           "Ceilings" => "ceilings",
           "Walls" => "walls",
           "Rim Joists" => "rim_joists",
           "Foundation Walls" => "foundation_walls",
           "Doors" => "doors",
           "Windows" => "windows",
           "Skylights" => "skylights",
           "Floors" => "floors",
           "Slabs" => "slabs",
           "Internal Mass" => "internal_mass",
           "Infiltration" => "infil",
           "Natural Ventilation" => "natvent",
           "Mechanical Ventilation" => "mechvent",
           "Ducts" => "ducts",
           "Internal Gains" => "intgains" }
end

def read_output(eri_design, designdir, output_hpxml_path, hourly_outputs, design_name)
  sql_path = File.join(designdir, "eplusout.sql")
  if not File.exists?(sql_path)
    puts "[#{design_name}] Processing output unsuccessful."
    return nil
  end

  sqlFile = OpenStudio::SqlFile.new(sql_path, false)
  if not sqlFile.connectionOpen
    puts "[#{design_name} Processing output unsuccessful."
    return nil
  end

  design_output = {}

  # HPXML
  design_output[:hpxml] = output_hpxml_path
  hpxml_doc = XMLHelper.parse_file(design_output[:hpxml])
  design_output[:hpxml_cfa] = get_cfa(hpxml_doc)
  design_output[:hpxml_nbr] = get_nbr(hpxml_doc)
  design_output[:hpxml_nst] = get_nst(hpxml_doc)
  htgs, clgs, hp_htgs, hp_clgs, dhws = get_systems(hpxml_doc)
  design_output[:hpxml_dse_heats] = get_dse_heats(hpxml_doc, htgs, hp_htgs, eri_design)
  design_output[:hpxml_dse_cools] = get_dse_cools(hpxml_doc, clgs, hp_clgs, eri_design)
  design_output[:hpxml_heat_fuels] = get_heat_fuels(hpxml_doc, htgs, hp_htgs, eri_design)
  design_output[:hpxml_dwh_fuels] = get_dhw_fuels(hpxml_doc, dhws)
  design_output[:hpxml_eec_heats] = get_eec_heats(hpxml_doc, htgs, hp_htgs, eri_design)
  design_output[:hpxml_eec_cools] = get_eec_cools(hpxml_doc, clgs, hp_clgs, eri_design)
  design_output[:hpxml_eec_dhws] = get_eec_dhws(hpxml_doc, dhws)
  design_output[:hpxml_heat_sys_ids] = design_output[:hpxml_eec_heats].keys
  design_output[:hpxml_cool_sys_ids] = design_output[:hpxml_eec_cools].keys
  design_output[:hpxml_dhw_sys_ids] = design_output[:hpxml_eec_dhws].keys

  # Building Space Heating/Cooling Loads (total heating/cooling energy delivered including backup ideal air system)
  query = "SELECT SUM(VariableValue/1000000000) FROM ReportMeterData WHERE ReportMeterDataDictionaryIndex IN (SELECT ReportMeterDataDictionaryIndex FROM ReportMeterDataDictionary WHERE VariableName='Heating:EnergyTransfer' AND ReportingFrequency='Run Period' AND VariableUnits='J')"
  design_output[:loadHeatingBldg] = UnitConversions.convert(sqlFile.execAndReturnFirstDouble(query).get, "GJ", "MBtu")
  query = "SELECT SUM(VariableValue/1000000000) FROM ReportMeterData WHERE ReportMeterDataDictionaryIndex IN (SELECT ReportMeterDataDictionaryIndex FROM ReportMeterDataDictionary WHERE VariableName='Cooling:EnergyTransfer' AND ReportingFrequency='Run Period' AND VariableUnits='J')"
  design_output[:loadCoolingBldg] = UnitConversions.convert(sqlFile.execAndReturnFirstDouble(query).get, "GJ", "MBtu")

  # Peak Building Space Heating/Cooling Loads (total heating/cooling energy delivered including backup ideal air system)
  query = "SELECT SUM(Value) FROM TabularDataWithStrings WHERE ReportName='EnergyMeters' AND ReportForString='Entire Facility' AND TableName='Annual and Peak Values - Other' AND RowName='Heating:EnergyTransfer' AND ColumnName='Maximum Value' AND Units='W'"
  design_output[:peakLoadHeatingBldg] = UnitConversions.convert(sqlFile.execAndReturnFirstDouble(query).get, "Wh", "kBtu")
  query = "SELECT SUM(Value) FROM TabularDataWithStrings WHERE ReportName='EnergyMeters' AND ReportForString='Entire Facility' AND TableName='Annual and Peak Values - Other' AND RowName='Cooling:EnergyTransfer' AND ColumnName='Maximum Value' AND Units='W'"
  design_output[:peakLoadCoolingBldg] = UnitConversions.convert(sqlFile.execAndReturnFirstDouble(query).get, "Wh", "kBtu")

  # Building Unmet Space Heating/Cooling Load (heating/cooling energy delivered by backup ideal air system)
  query = "SELECT SUM(VariableValue/1000000000) FROM ReportMeterData WHERE ReportMeterDataDictionaryIndex IN (SELECT ReportMeterDataDictionaryIndex FROM ReportMeterDataDictionary WHERE VariableName='Heating:DistrictHeating' AND ReportingFrequency='Run Period' AND VariableUnits='J')"
  design_output[:unmetLoadHeatingBldg] = UnitConversions.convert(sqlFile.execAndReturnFirstDouble(query).get, "GJ", "MBtu")
  query = "SELECT SUM(VariableValue/1000000000) FROM ReportMeterData WHERE ReportMeterDataDictionaryIndex IN (SELECT ReportMeterDataDictionaryIndex FROM ReportMeterDataDictionary WHERE VariableName='Cooling:DistrictCooling' AND ReportingFrequency='Run Period' AND VariableUnits='J')"
  design_output[:unmetLoadCoolingBldg] = UnitConversions.convert(sqlFile.execAndReturnFirstDouble(query).get, "GJ", "MBtu")

  # Peak Electricity Consumption
  query = "SELECT SUM(Value) FROM TabularDataWithStrings WHERE ReportName='PEAK ELECTRICITY SUMMER TOTAL' AND ReportForString='Meter' AND TableName='Custom Monthly Report' AND RowName='Maximum of Months' AND Units='W'"
  design_output[:peakElecSummerTotal] = sqlFile.execAndReturnFirstDouble(query).get
  query = "SELECT SUM(Value) FROM TabularDataWithStrings WHERE ReportName='PEAK ELECTRICITY WINTER TOTAL' AND ReportForString='Meter' AND TableName='Custom Monthly Report' AND RowName='Maximum of Months' AND Units='W'"
  design_output[:peakElecWinterTotal] = sqlFile.execAndReturnFirstDouble(query).get

  # Electricity categories
  query = "SELECT SUM(VariableValue/1000000000) FROM ReportMeterData WHERE ReportMeterDataDictionaryIndex IN (SELECT ReportMeterDataDictionaryIndex FROM ReportMeterDataDictionary WHERE VariableName='Electricity:Facility' AND ReportingFrequency='Run Period' AND VariableUnits='J')"
  design_output[:elecTotal] = UnitConversions.convert(sqlFile.execAndReturnFirstDouble(query).get, "GJ", "MBtu")
  query = "SELECT SUM(VariableValue/1000000000) FROM ReportMeterData WHERE ReportMeterDataDictionaryIndex IN (SELECT ReportMeterDataDictionaryIndex FROM ReportMeterDataDictionary WHERE VariableName='#{Constants.ObjectNameInteriorLighting}:InteriorLights:Electricity' AND ReportingFrequency='Run Period' AND VariableUnits='J')"
  design_output[:elecIntLighting] = UnitConversions.convert(sqlFile.execAndReturnFirstDouble(query).get, "GJ", "MBtu")
  query = "SELECT SUM(VariableValue/1000000000) FROM ReportMeterData WHERE ReportMeterDataDictionaryIndex IN (SELECT ReportMeterDataDictionaryIndex FROM ReportMeterDataDictionary WHERE VariableName='ExteriorLights:Electricity' AND ReportingFrequency='Run Period' AND VariableUnits='J')"
  design_output[:elecExtLighting] = UnitConversions.convert(sqlFile.execAndReturnFirstDouble(query).get, "GJ", "MBtu")
  query = "SELECT SUM(VariableValue/1000000000) FROM ReportMeterData WHERE ReportMeterDataDictionaryIndex IN (SELECT ReportMeterDataDictionaryIndex FROM ReportMeterDataDictionary WHERE VariableName='#{Constants.ObjectNameGarageLighting}:InteriorLights:Electricity' AND ReportingFrequency='Run Period' AND VariableUnits='J')"
  design_output[:elecGrgLighting] = UnitConversions.convert(sqlFile.execAndReturnFirstDouble(query).get, "GJ", "MBtu")
  query = "SELECT SUM(VariableValue/1000000000) FROM ReportMeterData WHERE ReportMeterDataDictionaryIndex IN (SELECT ReportMeterDataDictionaryIndex FROM ReportMeterDataDictionary WHERE VariableName='InteriorEquipment:Electricity' AND ReportingFrequency='Run Period' AND VariableUnits='J')"
  design_output[:elecAppliances] = UnitConversions.convert(sqlFile.execAndReturnFirstDouble(query).get, "GJ", "MBtu")

  # Fuel categories
  query = "SELECT SUM(VariableValue/1000000000) FROM ReportMeterData WHERE ReportMeterDataDictionaryIndex IN (SELECT ReportMeterDataDictionaryIndex FROM ReportMeterDataDictionary WHERE VariableName='Gas:Facility' AND ReportingFrequency='Run Period' AND VariableUnits='J')"
  design_output[:gasTotal] = UnitConversions.convert(sqlFile.execAndReturnFirstDouble(query).get, "GJ", "MBtu")
  query = "SELECT SUM(VariableValue/1000000000) FROM ReportMeterData WHERE ReportMeterDataDictionaryIndex IN (SELECT ReportMeterDataDictionaryIndex FROM ReportMeterDataDictionary WHERE VariableName='FuelOil#1:Facility' AND ReportingFrequency='Run Period' AND VariableUnits='J')"
  design_output[:oilTotal] = UnitConversions.convert(sqlFile.execAndReturnFirstDouble(query).get, "GJ", "MBtu")
  query = "SELECT SUM(VariableValue/1000000000) FROM ReportMeterData WHERE ReportMeterDataDictionaryIndex IN (SELECT ReportMeterDataDictionaryIndex FROM ReportMeterDataDictionary WHERE VariableName='Propane:Facility' AND ReportingFrequency='Run Period' AND VariableUnits='J')"
  design_output[:propaneTotal] = UnitConversions.convert(sqlFile.execAndReturnFirstDouble(query).get, "GJ", "MBtu")
  query = "SELECT SUM(VariableValue/1000000000) FROM ReportMeterData WHERE ReportMeterDataDictionaryIndex IN (SELECT ReportMeterDataDictionaryIndex FROM ReportMeterDataDictionary WHERE VariableName='InteriorEquipment:Gas' AND ReportingFrequency='Run Period' AND VariableUnits='J')"
  design_output[:gasAppliances] = UnitConversions.convert(sqlFile.execAndReturnFirstDouble(query).get, "GJ", "MBtu")
  query = "SELECT SUM(VariableValue/1000000000) FROM ReportMeterData WHERE ReportMeterDataDictionaryIndex IN (SELECT ReportMeterDataDictionaryIndex FROM ReportMeterDataDictionary WHERE VariableName='InteriorEquipment:FuelOil#1' AND ReportingFrequency='Run Period' AND VariableUnits='J')"
  design_output[:oilAppliances] = UnitConversions.convert(sqlFile.execAndReturnFirstDouble(query).get, "GJ", "MBtu")
  query = "SELECT SUM(VariableValue/1000000000) FROM ReportMeterData WHERE ReportMeterDataDictionaryIndex IN (SELECT ReportMeterDataDictionaryIndex FROM ReportMeterDataDictionary WHERE VariableName='InteriorEquipment:Propane' AND ReportingFrequency='Run Period' AND VariableUnits='J')"
  design_output[:propaneAppliances] = UnitConversions.convert(sqlFile.execAndReturnFirstDouble(query).get, "GJ", "MBtu")

  # Space Heating (by System)
  map_tsv_data = CSV.read(File.join(designdir, "map_hvac.tsv"), headers: false, col_sep: "\t")
  design_output[:elecHeatingBySystem] = {}
  design_output[:gasHeatingBySystem] = {}
  design_output[:oilHeatingBySystem] = {}
  design_output[:propaneHeatingBySystem] = {}
  design_output[:loadHeatingBySystem] = {}
  # First, calculate dual-fuel heat pump load
  dfhp_loads = {}
  design_output[:hpxml_heat_sys_ids].each do |sys_id|
    ep_output_names, dfhp_primary, dfhp_backup = get_ep_output_names_for_hvac_heating(map_tsv_data, sys_id, hpxml_doc)
    keys = "'" + ep_output_names.map(&:upcase).join("','") + "'"
    if dfhp_primary or dfhp_backup
      if dfhp_primary
        vars = "'" + get_all_var_keys(OutputVars.SpaceHeatingDFHPPrimaryLoad).join("','") + "'"
      else
        vars = "'" + get_all_var_keys(OutputVars.SpaceHeatingDFHPBackupLoad).join("','") + "'"
        sys_id = dfhp_primary_sys_id(sys_id)
      end
      query = "SELECT SUM(ABS(VariableValue)/1000000000) FROM ReportVariableData WHERE ReportVariableDataDictionaryIndex IN (SELECT ReportVariableDataDictionaryIndex FROM ReportVariableDataDictionary WHERE VariableType='Sum' AND KeyValue IN (#{keys}) AND VariableName IN (#{vars}) AND ReportingFrequency='Run Period' AND VariableUnits='J')"
      dfhp_loads[[sys_id, dfhp_primary]] = UnitConversions.convert(sqlFile.execAndReturnFirstDouble(query).get, "GJ", "MBtu")
    end
  end
  design_output[:hpxml_heat_sys_ids].each do |sys_id|
    ep_output_names, dfhp_primary, dfhp_backup = get_ep_output_names_for_hvac_heating(map_tsv_data, sys_id, hpxml_doc)
    keys = "'" + ep_output_names.map(&:upcase).join("','") + "'"

    # Electricity Use
    vars = "'" + get_all_var_keys(OutputVars.SpaceHeatingElectricity).join("','") + "'"
    query = "SELECT SUM(ABS(VariableValue)/1000000000) FROM ReportVariableData WHERE ReportVariableDataDictionaryIndex IN (SELECT ReportVariableDataDictionaryIndex FROM ReportVariableDataDictionary WHERE VariableType='Sum' AND KeyValue IN (#{keys}) AND VariableName IN (#{vars}) AND ReportingFrequency='Run Period' AND VariableUnits='J')"
    elecHeatingBySystemRaw = UnitConversions.convert(sqlFile.execAndReturnFirstDouble(query).get, "GJ", "MBtu")

    # Natural Gas Use
    vars = "'" + get_all_var_keys(OutputVars.SpaceHeatingNaturalGas).join("','") + "'"
    query = "SELECT SUM(ABS(VariableValue)/1000000000) FROM ReportVariableData WHERE ReportVariableDataDictionaryIndex IN (SELECT ReportVariableDataDictionaryIndex FROM ReportVariableDataDictionary WHERE VariableType='Sum' AND KeyValue IN (#{keys}) AND VariableName IN (#{vars}) AND ReportingFrequency='Run Period' AND VariableUnits='J')"
    gasHeatingBySystemRaw = UnitConversions.convert(sqlFile.execAndReturnFirstDouble(query).get, "GJ", "MBtu")

    # Oil Fuel Use
    vars = "'" + get_all_var_keys(OutputVars.SpaceHeatingFuelOil).join("','") + "'"
    query = "SELECT SUM(ABS(VariableValue)/1000000000) FROM ReportVariableData WHERE ReportVariableDataDictionaryIndex IN (SELECT ReportVariableDataDictionaryIndex FROM ReportVariableDataDictionary WHERE VariableType='Sum' AND KeyValue IN (#{keys}) AND VariableName IN (#{vars}) AND ReportingFrequency='Run Period' AND VariableUnits='J')"
    oilHeatingBySystemRaw = UnitConversions.convert(sqlFile.execAndReturnFirstDouble(query).get, "GJ", "MBtu")

    # Propane Fuel Use
    vars = "'" + get_all_var_keys(OutputVars.SpaceHeatingPropane).join("','") + "'"
    query = "SELECT SUM(ABS(VariableValue)/1000000000) FROM ReportVariableData WHERE ReportVariableDataDictionaryIndex IN (SELECT ReportVariableDataDictionaryIndex FROM ReportVariableDataDictionary WHERE VariableType='Sum' AND KeyValue IN (#{keys}) AND VariableName IN (#{vars}) AND ReportingFrequency='Run Period' AND VariableUnits='J')"
    propaneHeatingBySystemRaw = UnitConversions.convert(sqlFile.execAndReturnFirstDouble(query).get, "GJ", "MBtu")

    # Disaggregated Fan Energy Use
    ems_keys = "'" + ep_output_names.select { |name| name.end_with? Constants.ObjectNameFanPumpDisaggregatePrimaryHeat or name.end_with? Constants.ObjectNameFanPumpDisaggregateBackupHeat }.join("','") + "'"
    query = "SELECT SUM(ABS(VariableValue)/1000000000) FROM ReportVariableData WHERE ReportVariableDataDictionaryIndex IN (SELECT ReportVariableDataDictionaryIndex FROM ReportVariableDataDictionary WHERE VariableType='Sum' AND KeyValue='EMS' AND VariableName IN (#{ems_keys}) AND ReportingFrequency='Run Period' AND VariableUnits='J')"
    elecHeatingBySystemRaw += UnitConversions.convert(sqlFile.execAndReturnFirstDouble(query).get, "GJ", "MBtu")

    # apply dse to scale up energy use excluding no distribution systems
    design_output[:elecHeatingBySystem][sys_id] = elecHeatingBySystemRaw / design_output[:hpxml_dse_heats][sys_id]
    design_output[:gasHeatingBySystem][sys_id] = gasHeatingBySystemRaw / design_output[:hpxml_dse_heats][sys_id]
    design_output[:oilHeatingBySystem][sys_id] = oilHeatingBySystemRaw / design_output[:hpxml_dse_heats][sys_id]
    design_output[:propaneHeatingBySystem][sys_id] = propaneHeatingBySystemRaw / design_output[:hpxml_dse_heats][sys_id]
    # Also update totals:
    design_output[:elecTotal] += (design_output[:elecHeatingBySystem][sys_id] - elecHeatingBySystemRaw)
    design_output[:gasTotal] += (design_output[:gasHeatingBySystem][sys_id] - gasHeatingBySystemRaw)
    design_output[:oilTotal] += (design_output[:oilHeatingBySystem][sys_id] - oilHeatingBySystemRaw)
    design_output[:propaneTotal] += (design_output[:propaneHeatingBySystem][sys_id] - propaneHeatingBySystemRaw)

    # Reference Load
    if [Constants.CalcTypeERIReferenceHome, Constants.CalcTypeERIIndexAdjustmentReferenceHome].include? eri_design
      design_output[:loadHeatingBySystem][sys_id] = split_htg_load_to_system_by_fraction(sys_id, design_output[:loadHeatingBldg], hpxml_doc, eri_design, dfhp_loads, htgs, hp_htgs)
    end
  end

  # Space Cooling (by System)
  design_output[:elecCoolingBySystem] = {}
  design_output[:loadCoolingBySystem] = {}
  design_output[:hpxml_cool_sys_ids].each do |sys_id|
    ep_output_names = get_ep_output_names_for_hvac_cooling(map_tsv_data, sys_id, hpxml_doc)
    keys = "'" + ep_output_names.map(&:upcase).join("','") + "'"

    # Electricity Use
    vars = "'" + get_all_var_keys(OutputVars.SpaceCoolingElectricity).join("','") + "'"
    query = "SELECT SUM(ABS(VariableValue)/1000000000) FROM ReportVariableData WHERE ReportVariableDataDictionaryIndex IN (SELECT ReportVariableDataDictionaryIndex FROM ReportVariableDataDictionary WHERE VariableType='Sum' AND KeyValue IN (#{keys}) AND VariableName IN (#{vars}) AND ReportingFrequency='Run Period' AND VariableUnits='J')"
    elecCoolingBySystemRaw = UnitConversions.convert(sqlFile.execAndReturnFirstDouble(query).get, "GJ", "MBtu")

    # Disaggregated Fan Energy Use
    ems_keys = "'" + ep_output_names.select { |name| name.end_with? Constants.ObjectNameFanPumpDisaggregateCool }.join("','") + "'"
    query = "SELECT SUM(ABS(VariableValue)/1000000000) FROM ReportVariableData WHERE ReportVariableDataDictionaryIndex IN (SELECT ReportVariableDataDictionaryIndex FROM ReportVariableDataDictionary WHERE VariableType='Sum' AND KeyValue='EMS' AND VariableName IN (#{ems_keys}) AND ReportingFrequency='Run Period' AND VariableUnits='J')"
    elecCoolingBySystemRaw += UnitConversions.convert(sqlFile.execAndReturnFirstDouble(query).get, "GJ", "MBtu")

    # apply dse to scale up electricity energy use excluding no distribution systems
    if design_output[:hpxml_dse_cools][sys_id].nil?
      design_output[:elecCoolingBySystem][sys_id] = elecCoolingBySystemRaw
    else
      design_output[:elecCoolingBySystem][sys_id] = elecCoolingBySystemRaw / design_output[:hpxml_dse_cools][sys_id]
      # Also update totals:
      design_output[:elecTotal] += (design_output[:elecCoolingBySystem][sys_id] - elecCoolingBySystemRaw)
    end

    # Reference Load
    if [Constants.CalcTypeERIReferenceHome, Constants.CalcTypeERIIndexAdjustmentReferenceHome].include? eri_design
      design_output[:loadCoolingBySystem][sys_id] = split_clg_load_to_system_by_fraction(sys_id, design_output[:loadCoolingBldg], hpxml_doc, eri_design, clgs, hp_clgs)
    end
  end

  # Water Heating (by System)
  map_tsv_data = CSV.read(File.join(designdir, "map_water_heating.tsv"), headers: false, col_sep: "\t")
  design_output[:elecHotWaterBySystem] = {}
  design_output[:elecHotWaterRecircPumpBySystem] = {}
  design_output[:elecHotWaterSolarThermalPumpBySystem] = {}
  design_output[:gasHotWaterBySystem] = {}
  design_output[:oilHotWaterBySystem] = {}
  design_output[:propaneHotWaterBySystem] = {}
  design_output[:loadHotWaterBySystem] = {}
  design_output[:loadHotWaterDesuperheater] = 0
  design_output[:loadHotWaterSolarThermal] = 0
  solar_keys = nil
  design_output[:hpxml_dhw_sys_ids].each do |sys_id|
    ep_output_names = get_ep_output_names_for_water_heating(map_tsv_data, sys_id)
    keys = "'" + ep_output_names.map(&:upcase).join("','") + "'"

    # Electricity Use
    vars = "'" + get_all_var_keys(OutputVars.WaterHeatingElectricity).join("','") + "'"
    query = "SELECT SUM(ABS(VariableValue)/1000000000) FROM ReportVariableData WHERE ReportVariableDataDictionaryIndex IN (SELECT ReportVariableDataDictionaryIndex FROM ReportVariableDataDictionary WHERE VariableType='Sum' AND KeyValue IN (#{keys}) AND VariableName IN (#{vars}) AND ReportingFrequency='Run Period' AND VariableUnits='J')"
    elecHotWaterBySystemRaw = UnitConversions.convert(sqlFile.execAndReturnFirstDouble(query).get, "GJ", "MBtu")

    # Electricity Use - Recirc Pump
    vars = "'" + get_all_var_keys(OutputVars.WaterHeatingElectricityRecircPump).join("','") + "'"
    query = "SELECT SUM(ABS(VariableValue)/1000000000) FROM ReportVariableData WHERE ReportVariableDataDictionaryIndex IN (SELECT ReportVariableDataDictionaryIndex FROM ReportVariableDataDictionary WHERE VariableType='Sum' AND KeyValue IN (#{keys}) AND VariableName IN (#{vars}) AND ReportingFrequency='Run Period' AND VariableUnits='J')"
    design_output[:elecHotWaterRecircPumpBySystem][sys_id] = UnitConversions.convert(sqlFile.execAndReturnFirstDouble(query).get, "GJ", "MBtu")
    design_output[:elecAppliances] -= design_output[:elecHotWaterRecircPumpBySystem][sys_id]

    # Electricity Use - Solar Thermal Pump
    vars = "'" + get_all_var_keys(OutputVars.WaterHeatingElectricitySolarThermalPump).join("','") + "'"
    query = "SELECT SUM(ABS(VariableValue)/1000000000) FROM ReportVariableData WHERE ReportVariableDataDictionaryIndex IN (SELECT ReportVariableDataDictionaryIndex FROM ReportVariableDataDictionary WHERE VariableType='Sum' AND KeyValue IN (#{keys}) AND VariableName IN (#{vars}) AND ReportingFrequency='Run Period' AND VariableUnits='J')"
    design_output[:elecHotWaterSolarThermalPumpBySystem][sys_id] = UnitConversions.convert(sqlFile.execAndReturnFirstDouble(query).get, "GJ", "MBtu")

    # Natural Gas use
    vars = "'" + get_all_var_keys(OutputVars.WaterHeatingNaturalGas).join("','") + "'"
    query = "SELECT SUM(ABS(VariableValue)/1000000000) FROM ReportVariableData WHERE ReportVariableDataDictionaryIndex IN (SELECT ReportVariableDataDictionaryIndex FROM ReportVariableDataDictionary WHERE VariableType='Sum' AND KeyValue IN (#{keys}) AND VariableName IN (#{vars}) AND ReportingFrequency='Run Period' AND VariableUnits='J')"
    gasHotWaterBySystemRaw = UnitConversions.convert(sqlFile.execAndReturnFirstDouble(query).get, "GJ", "MBtu")

    # Oil Fuel use
    vars = "'" + get_all_var_keys(OutputVars.WaterHeatingFuelOil).join("','") + "'"
    query = "SELECT SUM(ABS(VariableValue)/1000000000) FROM ReportVariableData WHERE ReportVariableDataDictionaryIndex IN (SELECT ReportVariableDataDictionaryIndex FROM ReportVariableDataDictionary WHERE VariableType='Sum' AND KeyValue IN (#{keys}) AND VariableName IN (#{vars}) AND ReportingFrequency='Run Period' AND VariableUnits='J')"
    oilHotWaterBySystemRaw = UnitConversions.convert(sqlFile.execAndReturnFirstDouble(query).get, "GJ", "MBtu")

    # Propane Fuel use
    vars = "'" + get_all_var_keys(OutputVars.WaterHeatingPropane).join("','") + "'"
    query = "SELECT SUM(ABS(VariableValue)/1000000000) FROM ReportVariableData WHERE ReportVariableDataDictionaryIndex IN (SELECT ReportVariableDataDictionaryIndex FROM ReportVariableDataDictionary WHERE VariableType='Sum' AND KeyValue IN (#{keys}) AND VariableName IN (#{vars}) AND ReportingFrequency='Run Period' AND VariableUnits='J')"
    propaneHotWaterBySystemRaw = UnitConversions.convert(sqlFile.execAndReturnFirstDouble(query).get, "GJ", "MBtu")

    # Building Hot Water Load (Delivered Energy)
    vars = "'" + get_all_var_keys(OutputVars.WaterHeatingLoad).join("','") + "'"
    query = "SELECT SUM(ABS(VariableValue)/1000000000) FROM ReportVariableData WHERE ReportVariableDataDictionaryIndex IN (SELECT ReportVariableDataDictionaryIndex FROM ReportVariableDataDictionary WHERE VariableType='Sum' AND KeyValue IN (#{keys}) AND VariableName IN (#{vars}) AND ReportingFrequency='Run Period' AND VariableUnits='J')"
    design_output[:loadHotWaterBySystem][sys_id] = UnitConversions.convert(sqlFile.execAndReturnFirstDouble(query).get, "GJ", "MBtu")

    # Hot Water Load - Desuperheater
    ems_keys = "'" + ep_output_names.select { |name| name.include? Constants.ObjectNameDesuperheaterLoad(nil) }.join("','") + "'"
    query = "SELECT SUM(ABS(VariableValue)/1000000000) FROM ReportVariableData WHERE ReportVariableDataDictionaryIndex IN (SELECT ReportVariableDataDictionaryIndex FROM ReportVariableDataDictionary WHERE VariableType='Sum' AND KeyValue='EMS' AND VariableName IN (#{ems_keys}) AND ReportingFrequency='Run Period' AND VariableUnits='J')"
    design_output[:loadHotWaterDesuperheater] += UnitConversions.convert(sqlFile.execAndReturnFirstDouble(query).get, "GJ", "MBtu")

    # Hot Water Load - Solar Thermal
    solar_keys = "'" + ep_output_names.select { |name| name.include? Constants.ObjectNameSolarHotWater }.map(&:upcase).join("','") + "'"
    vars = "'" + get_all_var_keys(OutputVars.WaterHeaterLoadSolarThermal).join("','") + "'"
    query = "SELECT SUM(ABS(VariableValue)/1000000000) FROM ReportVariableData WHERE ReportVariableDataDictionaryIndex IN (SELECT ReportVariableDataDictionaryIndex FROM ReportVariableDataDictionary WHERE VariableType='Sum' AND KeyValue IN (#{solar_keys}) AND VariableName IN (#{vars}) AND ReportingFrequency='Run Period' AND VariableUnits='J')"
    design_output[:loadHotWaterSolarThermal] += UnitConversions.convert(sqlFile.execAndReturnFirstDouble(query).get, "GJ", "MBtu")

    # Apply solar fraction to load for simple solar water heating systems
    solar_fraction = get_dhw_solar_fraction(hpxml_doc, sys_id)
    if solar_fraction > 0
      orig_load = design_output[:loadHotWaterBySystem][sys_id]
      design_output[:loadHotWaterBySystem][sys_id] /= (1.0 - solar_fraction)
      design_output[:loadHotWaterSolarThermal] = design_output[:loadHotWaterBySystem][sys_id] - orig_load
    end

    # Combi boiler water system
    hvac_id = get_combi_hvac_id(hpxml_doc, sys_id, dhws)
    if not hvac_id.nil?
      vars = "'" + get_all_var_keys(OutputVars.WaterHeatingCombiBoilerHeatExchanger).join("','") + "'"
      query = "SELECT SUM(ABS(VariableValue)/1000000000) FROM ReportVariableData WHERE ReportVariableDataDictionaryIndex IN (SELECT ReportVariableDataDictionaryIndex FROM ReportVariableDataDictionary WHERE VariableType='Sum' AND KeyValue IN (#{keys}) AND VariableName IN (#{vars}) AND ReportingFrequency='Run Period' AND VariableUnits='J')"
      hx_load = UnitConversions.convert(sqlFile.execAndReturnFirstDouble(query).get, "GJ", "MBtu")
      vars = "'" + get_all_var_keys(OutputVars.WaterHeatingCombiBoiler).join("','") + "'"
      query = "SELECT SUM(ABS(VariableValue)/1000000000) FROM ReportVariableData WHERE ReportVariableDataDictionaryIndex IN (SELECT ReportVariableDataDictionaryIndex FROM ReportVariableDataDictionary WHERE VariableType='Sum' AND  KeyValue IN (#{keys}) AND VariableName IN (#{vars}) AND ReportingFrequency='Run Period' AND VariableUnits='J')"
      htg_load = UnitConversions.convert(sqlFile.execAndReturnFirstDouble(query).get, "GJ", "MBtu")

      # Split combi boiler system energy use by water system load fraction
      htg_ec_elec = design_output[:elecHeatingBySystem][hvac_id]
      htg_ec_gas = design_output[:gasHeatingBySystem][hvac_id]
      htg_ec_oil = design_output[:oilHeatingBySystem][hvac_id]
      htg_ec_propane = design_output[:propaneHeatingBySystem][hvac_id]

      if not htg_ec_elec.nil?
        design_output[:elecHotWaterBySystem][sys_id] = elecHotWaterBySystemRaw + get_combi_water_system_ec(hx_load, htg_load, htg_ec_elec) * design_output[:hpxml_dse_heats][hvac_id] # revert dse for hot water results
        design_output[:elecHeatingBySystem][hvac_id] -= get_combi_water_system_ec(hx_load, htg_load, htg_ec_elec)
        design_output[:elecTotal] -= get_combi_water_system_ec(hx_load, htg_load, htg_ec_elec) * (1.0 - design_output[:hpxml_dse_heats][hvac_id])
      end
      if not htg_ec_gas.nil?
        design_output[:gasHotWaterBySystem][sys_id] = gasHotWaterBySystemRaw + get_combi_water_system_ec(hx_load, htg_load, htg_ec_gas) * design_output[:hpxml_dse_heats][hvac_id] # revert dse for hot water results
        design_output[:gasHeatingBySystem][hvac_id] -= get_combi_water_system_ec(hx_load, htg_load, htg_ec_gas)
        design_output[:gasTotal] -= get_combi_water_system_ec(hx_load, htg_load, htg_ec_gas) * (1.0 - design_output[:hpxml_dse_heats][hvac_id])
      end
      if not htg_ec_oil.nil?
        design_output[:oilHotWaterBySystem][sys_id] = oilHotWaterBySystemRaw + get_combi_water_system_ec(hx_load, htg_load, htg_ec_oil) * design_output[:hpxml_dse_heats][hvac_id] # revert dse for hot water results
        design_output[:oilHeatingBySystem][hvac_id] -= get_combi_water_system_ec(hx_load, htg_load, htg_ec_oil)
        design_output[:oilTotal] -= get_combi_water_system_ec(hx_load, htg_load, htg_ec_oil) * (1.0 - design_output[:hpxml_dse_heats][hvac_id])
      end
      if not htg_ec_propane.nil?
        design_output[:propaneHotWaterBySystem][sys_id] = propaneHotWaterBySystemRaw + get_combi_water_system_ec(hx_load, htg_load, htg_ec_propane) * design_output[:hpxml_dse_heats][hvac_id] # revert dse for hot water results
        design_output[:propaneHeatingBySystem][hvac_id] -= get_combi_water_system_ec(hx_load, htg_load, htg_ec_propane)
        design_output[:propaneTotal] -= get_combi_water_system_ec(hx_load, htg_load, htg_ec_propane) * (1.0 - design_output[:hpxml_dse_heats][hvac_id])
      end
    else
      design_output[:elecHotWaterBySystem][sys_id] = elecHotWaterBySystemRaw
      design_output[:gasHotWaterBySystem][sys_id] = gasHotWaterBySystemRaw
      design_output[:oilHotWaterBySystem][sys_id] = oilHotWaterBySystemRaw
      design_output[:propaneHotWaterBySystem][sys_id] = propaneHotWaterBySystemRaw
    end

    # EC adjustment
    ems_keys = "'" + ep_output_names.select { |name| name.include? Constants.ObjectNameWaterHeaterAdjustment(nil) }.join("','") + "'"
    query = "SELECT SUM(VariableValue/1000000000) FROM ReportVariableData WHERE ReportVariableDataDictionaryIndex IN (SELECT ReportVariableDataDictionaryIndex FROM ReportVariableDataDictionary WHERE VariableType='Sum' AND KeyValue='EMS' AND VariableName IN (#{ems_keys}) AND ReportingFrequency='Run Period' AND VariableUnits='J')"
    ec_adj = UnitConversions.convert(sqlFile.execAndReturnFirstDouble(query).get, "GJ", "MBtu")

    # Desuperheater adjustment
    ems_keys = "'" + ep_output_names.select { |name| name.include? Constants.ObjectNameDesuperheaterEnergy(nil) }.join("','") + "'"
    query = "SELECT SUM(VariableValue/1000000000) FROM ReportVariableData WHERE ReportVariableDataDictionaryIndex IN (SELECT ReportVariableDataDictionaryIndex FROM ReportVariableDataDictionary WHERE VariableType='Sum' AND KeyValue='EMS' AND VariableName IN (#{ems_keys}) AND ReportingFrequency='Run Period' AND VariableUnits='J')"
    desuperheater_adj = UnitConversions.convert(sqlFile.execAndReturnFirstDouble(query).get, "GJ", "MBtu")

    # Adjust water heater/appliances energy consumptions for above adjustments
    tot_adj = ec_adj + desuperheater_adj
    if design_output[:gasHotWaterBySystem][sys_id] > 0
      design_output[:gasHotWaterBySystem][sys_id] += tot_adj
      design_output[:gasAppliances] -= tot_adj
    elsif design_output[:oilHotWaterBySystem][sys_id] > 0
      design_output[:oilHotWaterBySystem][sys_id] += tot_adj
      design_output[:oilAppliances] -= tot_adj
    elsif design_output[:propaneHotWaterBySystem][sys_id] > 0
      design_output[:propaneHotWaterBySystem][sys_id] += tot_adj
      design_output[:propaneAppliances] -= tot_adj
    else
      design_output[:elecHotWaterBySystem][sys_id] += tot_adj
      design_output[:elecAppliances] -= tot_adj
    end
  end
  design_output[:loadHotWaterDelivered] = design_output[:loadHotWaterBySystem].values.inject(0, :+)

  # Hot Water Load - Tank Losses (excluding solar storage tank)
  query = "SELECT SUM(ABS(VariableValue)/1000000000) FROM ReportVariableData WHERE ReportVariableDataDictionaryIndex IN (SELECT ReportVariableDataDictionaryIndex FROM ReportVariableDataDictionary WHERE VariableType='Sum' AND KeyValue NOT IN (#{solar_keys}) AND VariableName='Water Heater Heat Loss Energy' AND ReportingFrequency='Run Period' AND VariableUnits='J')"
  design_output[:loadHotWaterTankLosses] = UnitConversions.convert(sqlFile.execAndReturnFirstDouble(query).get, "GJ", "MBtu")

  # PV
  query = "SELECT SUM(VariableValue/1000000000) FROM ReportMeterData WHERE ReportMeterDataDictionaryIndex IN (SELECT ReportMeterDataDictionaryIndex FROM ReportMeterDataDictionary WHERE VariableName='ElectricityProduced:Facility' AND ReportingFrequency='Run Period' AND VariableUnits='J')"
  design_output[:elecPV] = UnitConversions.convert(sqlFile.execAndReturnFirstDouble(query).get, "GJ", "MBtu")

  # Fridge
  query = "SELECT SUM(VariableValue/1000000000) FROM ReportMeterData WHERE ReportMeterDataDictionaryIndex IN (SELECT ReportMeterDataDictionaryIndex FROM ReportMeterDataDictionary WHERE VariableName='#{Constants.ObjectNameRefrigerator}:InteriorEquipment:Electricity' AND ReportingFrequency='Run Period' AND VariableUnits='J')"
  design_output[:elecFridge] = UnitConversions.convert(sqlFile.execAndReturnFirstDouble(query).get, "GJ", "MBtu")

  # Dishwasher
  query = "SELECT SUM(VariableValue/1000000000) FROM ReportMeterData WHERE ReportMeterDataDictionaryIndex IN (SELECT ReportMeterDataDictionaryIndex FROM ReportMeterDataDictionary WHERE VariableName='#{Constants.ObjectNameDishwasher}:InteriorEquipment:Electricity' AND ReportingFrequency='Run Period' AND VariableUnits='J')"
  design_output[:elecDishwasher] = UnitConversions.convert(sqlFile.execAndReturnFirstDouble(query).get, "GJ", "MBtu")

  # Clothes Washer
  query = "SELECT SUM(VariableValue/1000000000) FROM ReportMeterData WHERE ReportMeterDataDictionaryIndex IN (SELECT ReportMeterDataDictionaryIndex FROM ReportMeterDataDictionary WHERE VariableName='#{Constants.ObjectNameClothesWasher}:InteriorEquipment:Electricity' AND ReportingFrequency='Run Period' AND VariableUnits='J')"
  design_output[:elecClothesWasher] = UnitConversions.convert(sqlFile.execAndReturnFirstDouble(query).get, "GJ", "MBtu")

  # Clothes Dryer
  query = "SELECT SUM(VariableValue/1000000000) FROM ReportMeterData WHERE ReportMeterDataDictionaryIndex IN (SELECT ReportMeterDataDictionaryIndex FROM ReportMeterDataDictionary WHERE VariableName='#{Constants.ObjectNameClothesDryer}:InteriorEquipment:Electricity' AND ReportingFrequency='Run Period' AND VariableUnits='J')"
  design_output[:elecClothesDryer] = UnitConversions.convert(sqlFile.execAndReturnFirstDouble(query).get, "GJ", "MBtu")
  query = "SELECT SUM(VariableValue/1000000000) FROM ReportMeterData WHERE ReportMeterDataDictionaryIndex IN (SELECT ReportMeterDataDictionaryIndex FROM ReportMeterDataDictionary WHERE VariableName='#{Constants.ObjectNameClothesDryer}:InteriorEquipment:Gas' AND ReportingFrequency='Run Period' AND VariableUnits='J')"
  design_output[:gasClothesDryer] = UnitConversions.convert(sqlFile.execAndReturnFirstDouble(query).get, "GJ", "MBtu")
  query = "SELECT SUM(VariableValue/1000000000) FROM ReportMeterData WHERE ReportMeterDataDictionaryIndex IN (SELECT ReportMeterDataDictionaryIndex FROM ReportMeterDataDictionary WHERE VariableName='#{Constants.ObjectNameClothesDryer}:InteriorEquipment:FuelOil#1' AND ReportingFrequency='Run Period' AND VariableUnits='J')"
  design_output[:oilClothesDryer] = UnitConversions.convert(sqlFile.execAndReturnFirstDouble(query).get, "GJ", "MBtu")
  query = "SELECT SUM(VariableValue/1000000000) FROM ReportMeterData WHERE ReportMeterDataDictionaryIndex IN (SELECT ReportMeterDataDictionaryIndex FROM ReportMeterDataDictionary WHERE VariableName='#{Constants.ObjectNameClothesDryer}:InteriorEquipment:Propane' AND ReportingFrequency='Run Period' AND VariableUnits='J')"
  design_output[:propaneClothesDryer] = UnitConversions.convert(sqlFile.execAndReturnFirstDouble(query).get, "GJ", "MBtu")

  # MELS
  query = "SELECT SUM(VariableValue/1000000000) FROM ReportMeterData WHERE ReportMeterDataDictionaryIndex IN (SELECT ReportMeterDataDictionaryIndex FROM ReportMeterDataDictionary WHERE VariableName='#{Constants.ObjectNameMiscPlugLoads}:InteriorEquipment:Electricity' AND ReportingFrequency='Run Period' AND VariableUnits='J')"
  design_output[:elecMELs] = UnitConversions.convert(sqlFile.execAndReturnFirstDouble(query).get, "GJ", "MBtu")
  query = "SELECT SUM(VariableValue/1000000000) FROM ReportMeterData WHERE ReportMeterDataDictionaryIndex IN (SELECT ReportMeterDataDictionaryIndex FROM ReportMeterDataDictionary WHERE VariableName='#{Constants.ObjectNameMiscTelevision}:InteriorEquipment:Electricity' AND ReportingFrequency='Run Period' AND VariableUnits='J')"
  design_output[:elecTV] = UnitConversions.convert(sqlFile.execAndReturnFirstDouble(query).get, "GJ", "MBtu")

  # Range/Oven
  query = "SELECT SUM(VariableValue/1000000000) FROM ReportMeterData WHERE ReportMeterDataDictionaryIndex IN (SELECT ReportMeterDataDictionaryIndex FROM ReportMeterDataDictionary WHERE VariableName='#{Constants.ObjectNameCookingRange}:InteriorEquipment:Electricity' AND ReportingFrequency='Run Period' AND VariableUnits='J')"
  design_output[:elecRangeOven] = UnitConversions.convert(sqlFile.execAndReturnFirstDouble(query).get, "GJ", "MBtu")
  query = "SELECT SUM(VariableValue/1000000000) FROM ReportMeterData WHERE ReportMeterDataDictionaryIndex IN (SELECT ReportMeterDataDictionaryIndex FROM ReportMeterDataDictionary WHERE VariableName='#{Constants.ObjectNameCookingRange}:InteriorEquipment:Gas' AND ReportingFrequency='Run Period' AND VariableUnits='J')"
  design_output[:gasRangeOven] = UnitConversions.convert(sqlFile.execAndReturnFirstDouble(query).get, "GJ", "MBtu")
  query = "SELECT SUM(VariableValue/1000000000) FROM ReportMeterData WHERE ReportMeterDataDictionaryIndex IN (SELECT ReportMeterDataDictionaryIndex FROM ReportMeterDataDictionary WHERE VariableName='#{Constants.ObjectNameCookingRange}:InteriorEquipment:FuelOil#1' AND ReportingFrequency='Run Period' AND VariableUnits='J')"
  design_output[:oilRangeOven] = UnitConversions.convert(sqlFile.execAndReturnFirstDouble(query).get, "GJ", "MBtu")
  query = "SELECT SUM(VariableValue/1000000000) FROM ReportMeterData WHERE ReportMeterDataDictionaryIndex IN (SELECT ReportMeterDataDictionaryIndex FROM ReportMeterDataDictionary WHERE VariableName='#{Constants.ObjectNameCookingRange}:InteriorEquipment:Propane' AND ReportingFrequency='Run Period' AND VariableUnits='J')"
  design_output[:propaneRangeOven] = UnitConversions.convert(sqlFile.execAndReturnFirstDouble(query).get, "GJ", "MBtu")

  # Ceiling Fans
  query = "SELECT SUM(VariableValue/1000000000) FROM ReportMeterData WHERE ReportMeterDataDictionaryIndex IN (SELECT ReportMeterDataDictionaryIndex FROM ReportMeterDataDictionary WHERE VariableName='#{Constants.ObjectNameCeilingFan}:InteriorEquipment:Electricity' AND ReportingFrequency='Run Period' AND VariableUnits='J')"
  design_output[:elecCeilingFan] = UnitConversions.convert(sqlFile.execAndReturnFirstDouble(query).get, "GJ", "MBtu")

  # Mechanical Ventilation
  query = "SELECT SUM(VariableValue/1000000000) FROM ReportMeterData WHERE ReportMeterDataDictionaryIndex IN (SELECT ReportMeterDataDictionaryIndex FROM ReportMeterDataDictionary WHERE VariableName='#{Constants.ObjectNameMechanicalVentilation} house fan:InteriorEquipment:Electricity' AND ReportingFrequency='Run Period' AND VariableUnits='J')"
  design_output[:elecMechVent] = UnitConversions.convert(sqlFile.execAndReturnFirstDouble(query).get, "GJ", "MBtu")

  # Error Checking
  tolerance = 0.1 # MMBtu

  all_total = design_output[:elecTotal] + design_output[:gasTotal] + design_output[:oilTotal] + design_output[:propaneTotal]
  if all_total == 0
    puts "[#{design_name}] Processing output unsuccessful."
    return nil
  end

  sum_elec_categories = (design_output[:elecHeatingBySystem].values.inject(0, :+) +
                         design_output[:elecCoolingBySystem].values.inject(0, :+) +
                         design_output[:elecHotWaterBySystem].values.inject(0, :+) +
                         design_output[:elecHotWaterRecircPumpBySystem].values.inject(0, :+) +
                         design_output[:elecHotWaterSolarThermalPumpBySystem].values.inject(0, :+) +
                         design_output[:elecIntLighting] +
                         design_output[:elecGrgLighting] +
                         design_output[:elecExtLighting] +
                         design_output[:elecAppliances])
  if (design_output[:elecTotal] - sum_elec_categories).abs > tolerance
    fail "[#{design_name}] Electric category end uses (#{sum_elec_categories}) do not sum to total (#{design_output[:elecTotal]}).\n#{design_output.to_s}"
  end

  sum_gas_categories = (design_output[:gasHeatingBySystem].values.inject(0, :+) +
                        design_output[:gasHotWaterBySystem].values.inject(0, :+) +
                        design_output[:gasAppliances])
  if (design_output[:gasTotal] - sum_gas_categories).abs > tolerance
    fail "[#{design_name}] Natural gas category end uses (#{sum_gas_categories}) do not sum to total (#{design_output[:gasTotal]}).\n#{design_output.to_s}"
  end

  sum_oil_categories = (design_output[:oilHeatingBySystem].values.inject(0, :+) +
                        design_output[:oilHotWaterBySystem].values.inject(0, :+) +
                        design_output[:oilAppliances])
  if (design_output[:oilTotal] - sum_oil_categories).abs > tolerance
    fail "[#{design_name}] Oil fuel category end uses (#{sum_oil_categories}) do not sum to total (#{design_output[:oilTotal]}).\n#{design_output.to_s}"
  end

  sum_propane_categories = (design_output[:propaneHeatingBySystem].values.inject(0, :+) +
                            design_output[:propaneHotWaterBySystem].values.inject(0, :+) +
                            design_output[:propaneAppliances])
  if (design_output[:propaneTotal] - sum_propane_categories).abs > tolerance
    fail "[#{design_name}] Propane fuel category end uses (#{sum_propane_categories}) do not sum to total (#{design_output[:propaneTotal]}).\n#{design_output.to_s}"
  end

  sum_elec_appliances = (design_output[:elecFridge] +
                         design_output[:elecDishwasher] +
                         design_output[:elecClothesWasher] +
                         design_output[:elecClothesDryer] +
                         design_output[:elecMELs] +
                         design_output[:elecTV] +
                         design_output[:elecRangeOven] +
                         design_output[:elecCeilingFan] +
                         design_output[:elecMechVent])
  if (design_output[:elecAppliances] - sum_elec_appliances).abs > tolerance
    fail "[#{design_name}] Electric appliances (#{sum_elec_appliances}) do not sum to total (#{design_output[:elecAppliances]}).\n#{design_output.to_s}"
  end

  sum_gas_appliances = (design_output[:gasClothesDryer] + design_output[:gasRangeOven])
  if (design_output[:gasAppliances] - sum_gas_appliances).abs > tolerance
    fail "[#{design_name}] Natural gas appliances (#{sum_gas_appliances}) do not sum to total (#{design_output[:gasAppliances]}).\n#{design_output.to_s}"
  end

  sum_oil_appliances = (design_output[:oilClothesDryer] + design_output[:oilRangeOven])
  if (design_output[:oilAppliances] - sum_oil_appliances).abs > tolerance
    fail "[#{design_name}] Oil fuel appliances (#{sum_oil_appliances}) do not sum to total (#{design_output[:oilAppliances]}).\n#{design_output.to_s}"
  end

  sum_propane_appliances = (design_output[:propaneClothesDryer] + design_output[:propaneRangeOven])
  if (design_output[:propaneAppliances] - sum_propane_appliances).abs > tolerance
    fail "[#{design_name}] Propane fuel appliances (#{sum_propane_appliances}) do not sum to total (#{design_output[:propaneAppliances]}).\n#{design_output.to_s}"
  end

  # REUL check: system cooling/heating sum to total bldg load
  if [Constants.CalcTypeERIReferenceHome, Constants.CalcTypeERIIndexAdjustmentReferenceHome].include? eri_design
    sum_sys_htg_load = design_output[:loadHeatingBySystem].values.inject(0) { |sum, value| sum + value }
    if (sum_sys_htg_load - design_output[:loadHeatingBldg]).abs > tolerance
      fail "[#{design_name}] system heating load not sum to total building heating load"
    end

    sum_sys_clg_load = design_output[:loadCoolingBySystem].values.inject(0) { |sum, value| sum + value }
    if (sum_sys_clg_load - design_output[:loadCoolingBldg]).abs > tolerance
      fail "[#{design_name}] system cooling load not sum to total building cooling load"
    end
  end

  # Component Loads

  { "Heating" => "htg", "Cooling" => "clg" }.each do |mode, mode_var|
    get_component_load_map.each do |component, component_var|
      query = "SELECT VariableValue/1000000000 FROM ReportVariableData WHERE ReportVariableDataDictionaryIndex = (SELECT ReportVariableDataDictionaryIndex FROM ReportVariableDataDictionary WHERE VariableType='Sum' AND KeyValue='EMS' AND VariableName='#{mode_var}_#{component_var}_outvar' AND ReportingFrequency='Run Period' AND VariableUnits='J')"
      design_output["componentLoad#{mode}#{component}"] = UnitConversions.convert(sqlFile.execAndReturnFirstDouble(query).get, "GJ", "MBtu")
    end
  end
  query = "SELECT SUM(VariableValue/1000000000) FROM ReportVariableData WHERE ReportVariableDataDictionaryIndex IN (SELECT ReportVariableDataDictionaryIndex FROM ReportVariableDataDictionary WHERE VariableType='Sum' AND KeyValue='EMS' AND VariableName LIKE 'htg_%_outvar' AND ReportingFrequency='Run Period' AND VariableUnits='J')"
  sum_heating_component_loads = UnitConversions.convert(sqlFile.execAndReturnFirstDouble(query).get, "GJ", "MBtu")
  query = "SELECT SUM(VariableValue/1000000000) FROM ReportVariableData WHERE ReportVariableDataDictionaryIndex IN (SELECT ReportVariableDataDictionaryIndex FROM ReportVariableDataDictionary WHERE VariableType='Sum' AND KeyValue='EMS' AND VariableName LIKE 'clg_%_outvar' AND ReportingFrequency='Run Period' AND VariableUnits='J')"
  sum_cooling_component_loads = UnitConversions.convert(sqlFile.execAndReturnFirstDouble(query).get, "GJ", "MBtu")

  design_hourly_output = []
  if hourly_outputs.size > 0
    # Generate CSV file with hourly output

    # Unit conversions
    j_to_kwh = UnitConversions.convert(1.0, "j", "kwh")
    j_to_kbtu = UnitConversions.convert(1.0, "j", "kbtu")

    # Header
    design_hourly_output = [["Hour"]]
    if hourly_outputs.include? HourlyOutputFuelConsumptions
      design_hourly_output[0] << "Electricity Use [kWh]"
      design_hourly_output[0] << "Natural Gas Use [kBtu]"
      design_hourly_output[0] << "Fuel Oil Use [kBtu]"
      design_hourly_output[0] << "Propane Use [kBtu]"
    end
    if hourly_outputs.include? HourlyOutputZoneTemperatures
      # Get zone names (excluding duct zone/return plenum)
      zone_names = []
      query = "SELECT KeyValue FROM ReportVariableDataDictionary WHERE VariableName='Zone Mean Air Temperature'"
      sqlFile.execAndReturnVectorOfString(query).get.each do |zone_name|
        query = "SELECT FloorArea FROM Zones WHERE ZoneName='#{zone_name}'"
        floor_area = sqlFile.execAndReturnFirstDouble(query).get
        next unless floor_area > 1.0

        zone_names << zone_name
      end
      zone_names.sort!

      zone_names.each do |zone_name|
        design_hourly_output[0] << "#{zone_name.split.map(&:capitalize).join(' ')} Temperature [F]"
      end
    end
    if hourly_outputs.include? HourlyOutputTotalLoads
      design_hourly_output[0] << "Heating Load - Total [kBtu]"
      design_hourly_output[0] << "Cooling Load - Total [kBtu]"
    end
    if hourly_outputs.include? HourlyOutputComponentLoads
      ["Heating", "Cooling"].each do |mode|
        get_component_load_map.each do |component, component_var|
          design_hourly_output[0] << "#{mode} Load - #{component} [kBtu]"
        end
      end
    end

    for hr in 1..8760
      design_hourly_output << [hr]
    end

    # Data
    if hourly_outputs.include? HourlyOutputFuelConsumptions
      # Electricity
      query = "SELECT VariableValue*#{j_to_kwh} FROM ReportMeterData WHERE ReportMeterDataDictionaryIndex IN (SELECT ReportMeterDataDictionaryIndex FROM ReportMeterDataDictionary WHERE VariableName='Electricity:Facility' AND ReportingFrequency='Hourly') ORDER BY TimeIndex"
      elec_use = sqlFile.execAndReturnVectorOfDouble(query).get
      elec_use += [0.0] * 8760 if elec_use.size == 0

      # Natural Gas
      query = "SELECT VariableValue*#{j_to_kbtu} FROM ReportMeterData WHERE ReportMeterDataDictionaryIndex IN (SELECT ReportMeterDataDictionaryIndex FROM ReportMeterDataDictionary WHERE VariableName='Gas:Facility' AND ReportingFrequency='Hourly') ORDER BY TimeIndex"
      gas_use = [] + sqlFile.execAndReturnVectorOfDouble(query).get
      gas_use += [0.0] * 8760 if gas_use.size == 0

      # Fuel Oil
      query = "SELECT VariableValue*#{j_to_kbtu} FROM ReportMeterData WHERE ReportMeterDataDictionaryIndex IN (SELECT ReportMeterDataDictionaryIndex FROM ReportMeterDataDictionary WHERE VariableName='FuelOil#1:Facility' AND ReportingFrequency='Hourly') ORDER BY TimeIndex"
      oil_use = [] + sqlFile.execAndReturnVectorOfDouble(query).get
      oil_use += [0.0] * 8760 if oil_use.size == 0

      # Propane
      query = "SELECT VariableValue*#{j_to_kbtu} FROM ReportMeterData WHERE ReportMeterDataDictionaryIndex IN (SELECT ReportMeterDataDictionaryIndex FROM ReportMeterDataDictionary WHERE VariableName='Propane:Facility' AND ReportingFrequency='Hourly') ORDER BY TimeIndex"
      propane_use = [] + sqlFile.execAndReturnVectorOfDouble(query).get
      propane_use += [0.0] * 8760 if propane_use.size == 0

      elec_use.zip(gas_use, oil_use, propane_use).each_with_index do |(elec, gas, oil, propane), i|
        design_hourly_output[i + 1] << elec.round(2)
        design_hourly_output[i + 1] << gas.round(2)
        design_hourly_output[i + 1] << oil.round(2)
        design_hourly_output[i + 1] << propane.round(2)
      end

      # Error Checking
      elec_sum_hourly_gj = (elec_use.inject(0, :+) / j_to_kwh) / 1000000000.0
      query = "SELECT SUM(VariableValue/1000000000) FROM ReportMeterData WHERE ReportMeterDataDictionaryIndex IN (SELECT ReportMeterDataDictionaryIndex FROM ReportMeterDataDictionary WHERE VariableName='Electricity:Facility' AND ReportingFrequency='Run Period' AND VariableUnits='J')"
      elec_annual_gj = sqlFile.execAndReturnFirstDouble(query).get
      if (elec_annual_gj - elec_sum_hourly_gj).abs > tolerance
        fail "[#{design_name}] Hourly electricity results (#{elec_sum_hourly_gj}) do not sum to annual (#{elec_annual_gj}).\n#{design_output.to_s}"
      end

      gas_sum_hourly_gj = (gas_use.inject(0, :+) / j_to_kbtu) / 1000000000.0
      query = "SELECT SUM(VariableValue/1000000000) FROM ReportMeterData WHERE ReportMeterDataDictionaryIndex IN (SELECT ReportMeterDataDictionaryIndex FROM ReportMeterDataDictionary WHERE VariableName='Gas:Facility' AND ReportingFrequency='Run Period' AND VariableUnits='J')"
      gas_annual_gj = sqlFile.execAndReturnFirstDouble(query).get
      if (gas_annual_gj - gas_sum_hourly_gj).abs > tolerance
        fail "[#{design_name}] Hourly natural gas results (#{gas_sum_hourly_gj}) do not sum to annual (#{gas_annual_gj}).\n#{design_output.to_s}"
      end

      oil_sum_hourly_gj = (oil_use.inject(0, :+) / j_to_kbtu) / 1000000000.0
      query = "SELECT SUM(VariableValue/1000000000) FROM ReportMeterData WHERE ReportMeterDataDictionaryIndex IN (SELECT ReportMeterDataDictionaryIndex FROM ReportMeterDataDictionary WHERE VariableName='FuelOil#1:Facility' AND ReportingFrequency='Run Period' AND VariableUnits='J')"
      oil_annual_gj = sqlFile.execAndReturnFirstDouble(query).get
      if (oil_annual_gj - oil_sum_hourly_gj).abs > tolerance
        fail "[#{design_name}] Hourly oil fuel results (#{oil_sum_hourly_gj}) do not sum to annual (#{oil_annual_gj}).\n#{design_output.to_s}"
      end

      propane_sum_hourly_gj = (propane_use.inject(0, :+) / j_to_kbtu) / 1000000000.0
      query = "SELECT SUM(VariableValue/1000000000) FROM ReportMeterData WHERE ReportMeterDataDictionaryIndex IN (SELECT ReportMeterDataDictionaryIndex FROM ReportMeterDataDictionary WHERE VariableName='Propane:Facility' AND ReportingFrequency='Run Period' AND VariableUnits='J')"
      propane_annual_gj = sqlFile.execAndReturnFirstDouble(query).get
      if (propane_annual_gj - propane_sum_hourly_gj).abs > tolerance
        fail "[#{design_name}] Hourly propane fuel results (#{propane_sum_hourly_gj}) do not sum to annual (#{propane_annual_gj}).\n#{design_output.to_s}"
      end
    end

    if hourly_outputs.include? HourlyOutputZoneTemperatures
      # Space temperatures
      zone_names.each do |zone_name|
        query = "SELECT (VariableValue*9.0/5.0)+32.0 FROM ReportVariableData WHERE ReportVariableDataDictionaryIndex IN (SELECT ReportVariableDataDictionaryIndex FROM ReportVariableDataDictionary WHERE VariableName='Zone Mean Air Temperature' AND KeyValue='#{zone_name}' AND ReportingFrequency='Hourly') ORDER BY TimeIndex"
        temperatures = sqlFile.execAndReturnVectorOfDouble(query).get
        fail "Unexpected result" if temperatures.size != 8760

        temperatures.each_with_index do |temperature, i|
          design_hourly_output[i + 1] << temperature.round(2)
        end
      end
    end

    if hourly_outputs.include? HourlyOutputTotalLoads
      # FIXME: This needs to be updated when the new component loads algorithm is merged

      # Heating load total
      query = "SELECT VariableValue*#{j_to_kbtu} FROM ReportMeterData WHERE ReportMeterDataDictionaryIndex IN (SELECT ReportMeterDataDictionaryIndex FROM ReportMeterDataDictionary WHERE VariableName='Heating:EnergyTransfer' AND ReportingFrequency='Hourly') ORDER BY TimeIndex"
      results = sqlFile.execAndReturnVectorOfDouble(query).get
      fail "Unexpected result" if results.size != 8760

      results.each_with_index do |htg_load, i|
        design_hourly_output[i + 1] << htg_load.round(2)
      end

      # Cooling load total
      query = "SELECT VariableValue*#{j_to_kbtu} FROM ReportMeterData WHERE ReportMeterDataDictionaryIndex IN (SELECT ReportMeterDataDictionaryIndex FROM ReportMeterDataDictionary WHERE VariableName='Cooling:EnergyTransfer' AND ReportingFrequency='Hourly') ORDER BY TimeIndex"
      results = sqlFile.execAndReturnVectorOfDouble(query).get
      fail "Unexpected result" if results.size != 8760

      results.each_with_index do |clg_load, i|
        design_hourly_output[i + 1] << clg_load.round(2)
      end
    end

    if hourly_outputs.include? HourlyOutputComponentLoads
      ["htg", "clg"].each do |mode_var|
        get_component_load_map.each do |component, component_var|
          query = "SELECT VariableValue*#{j_to_kbtu} FROM ReportVariableData WHERE ReportVariableDataDictionaryIndex = (SELECT ReportVariableDataDictionaryIndex FROM ReportVariableDataDictionary WHERE VariableType='Sum' AND KeyValue='EMS' AND VariableName='#{mode_var}_#{component_var}_hourly_outvar' AND ReportingFrequency='Hourly' AND VariableUnits='J')"
          results = sqlFile.execAndReturnVectorOfDouble(query).get
          fail "Unexpected result" if results.size != 8760

          results.each_with_index do |component_load, i|
            next if i == 0 # EMS outputs lag by 1 hour

            design_hourly_output[i] << component_load.round(2)
          end
          design_hourly_output[8760] << 0.0 # Add final hour
        end
      end
    end

  end

  return design_output, design_hourly_output
end

def split_htg_load_to_system_by_fraction(sys_id, bldg_load, hpxml_doc, eri_design, dfhp_loads, htgs, hp_htgs)
  htgs.each do |htg_system|
    next unless get_system_or_seed_id(htg_system, eri_design) == sys_id

    return bldg_load * Float(XMLHelper.get_value(htg_system, "FractionHeatLoadServed"))
  end
  hp_htgs.each do |heat_pump|
    load_fraction = 1.0
    if is_dfhp(heat_pump)
      if dfhp_primary_sys_id(sys_id) == sys_id
        load_fraction = dfhp_loads[[sys_id, true]] / (dfhp_loads[[sys_id, true]] + dfhp_loads[[sys_id, false]])
      else
        sys_id = dfhp_primary_sys_id(sys_id)
        load_fraction = dfhp_loads[[sys_id, false]] / (dfhp_loads[[sys_id, true]] + dfhp_loads[[sys_id, false]])
      end
    end
    next unless get_system_or_seed_id(heat_pump, eri_design) == sys_id

    return bldg_load * Float(XMLHelper.get_value(heat_pump, "FractionHeatLoadServed")) * load_fraction
  end

  fail "Could not find load fraction for #{sys_id}."
end

def split_clg_load_to_system_by_fraction(sys_id, bldg_load, hpxml_doc, eri_design, clgs, hp_clgs)
  clgs.each do |clg_system|
    next unless get_system_or_seed_id(clg_system, eri_design) == sys_id

    return bldg_load * Float(XMLHelper.get_value(clg_system, "FractionCoolLoadServed"))
  end
  hp_clgs.each do |heat_pump|
    next unless get_system_or_seed_id(heat_pump, eri_design) == sys_id

    return bldg_load * Float(XMLHelper.get_value(heat_pump, "FractionCoolLoadServed"))
  end

  fail "Could not find load fraction for #{sys_id}."
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

def get_cfa(hpxml_doc)
  return Float(XMLHelper.get_value(hpxml_doc, "/HPXML/Building/BuildingDetails/BuildingSummary/BuildingConstruction/ConditionedFloorArea"))
end

def get_nbr(hpxml_doc)
  return Float(XMLHelper.get_value(hpxml_doc, "/HPXML/Building/BuildingDetails/BuildingSummary/BuildingConstruction/NumberofBedrooms"))
end

def get_nst(hpxml_doc)
  return Float(XMLHelper.get_value(hpxml_doc, "/HPXML/Building/BuildingDetails/BuildingSummary/BuildingConstruction/NumberofConditionedFloorsAboveGrade"))
end

def get_system_or_seed_id(sys, eri_design)
  if [Constants.CalcTypeERIReferenceHome,
      Constants.CalcTypeERIIndexAdjustmentReferenceHome].include? eri_design
    if XMLHelper.has_element(sys, "extension/SeedId")
      return XMLHelper.get_value(sys, "extension/SeedId")
    end
  end
  return sys.elements["SystemIdentifier"].attributes["id"]
end

def get_systems(hpxml_doc)
  htgs = []
  clgs = []
  hp_htgs = []
  hp_clgs = []
  dhws = []

  hpxml_doc.elements.each("/HPXML/Building/BuildingDetails/Systems/HVAC/HVACPlant/HeatingSystem[FractionHeatLoadServed > 0]") do |htg_system|
    htgs << htg_system
  end
  hpxml_doc.elements.each("/HPXML/Building/BuildingDetails/Systems/HVAC/HVACPlant/HeatPump[FractionHeatLoadServed > 0]") do |heat_pump|
    hp_htgs << heat_pump
  end
  hpxml_doc.elements.each("/HPXML/Building/BuildingDetails/Systems/HVAC/HVACPlant/CoolingSystem[FractionCoolLoadServed > 0]") do |clg_system|
    clgs << clg_system
  end
  hpxml_doc.elements.each("/HPXML/Building/BuildingDetails/Systems/HVAC/HVACPlant/HeatPump[FractionCoolLoadServed > 0]") do |heat_pump|
    hp_clgs << heat_pump
  end
  hpxml_doc.elements.each("/HPXML/Building/BuildingDetails/Systems/WaterHeating/WaterHeatingSystem[FractionDHWLoadServed > 0]") do |dhw_system|
    dhws << dhw_system
  end

  return htgs, clgs, hp_htgs, hp_clgs, dhws
end

def get_heat_fuels(hpxml_doc, htgs, hp_htgs, eri_design)
  heat_fuels = {}

  htgs.each do |htg_system|
    sys_id = get_system_or_seed_id(htg_system, eri_design)
    heat_fuels[sys_id] = XMLHelper.get_value(htg_system, "HeatingSystemFuel")
  end
  hp_htgs.each do |heat_pump|
    sys_id = get_system_or_seed_id(heat_pump, eri_design)
    heat_fuels[sys_id] = XMLHelper.get_value(heat_pump, "HeatPumpFuel")
    if is_dfhp(heat_pump)
      heat_fuels[dfhp_backup_sys_id(sys_id)] = XMLHelper.get_value(heat_pump, "BackupSystemFuel")
    end
  end

  if heat_fuels.empty?
    fail "No heating systems found."
  end

  return heat_fuels
end

def get_dhw_fuels(hpxml_doc, dhws)
  dhw_fuels = {}

  dhws.each do |dhw_system|
    sys_id = dhw_system.elements["SystemIdentifier"].attributes["id"]
    if ['space-heating boiler with tankless coil', 'space-heating boiler with storage tank'].include? XMLHelper.get_value(dhw_system, "WaterHeaterType")
      orig_details = hpxml_doc.elements["/HPXML/Building/BuildingDetails"]
      hvac_idref = dhw_system.elements["RelatedHVACSystem"].attributes["idref"]
      dhw_fuels[sys_id] = Waterheater.get_combi_system_fuel(hvac_idref, orig_details)
    else
      dhw_fuels[sys_id] = XMLHelper.get_value(dhw_system, "FuelType")
    end
  end

  if dhw_fuels.empty?
    fail "No water heating systems found."
  end

  return dhw_fuels
end

def get_dse_heats(hpxml_doc, htgs, hp_htgs, eri_design)
  dse_heats = {}
  hpxml_doc.elements.each("/HPXML/Building/BuildingDetails/Systems/HVAC/HVACDistribution") do |hvac_dist|
    dist_id = hvac_dist.elements["SystemIdentifier"].attributes["id"]
    dse_heat_raw = XMLHelper.get_value(hvac_dist, "AnnualHeatingDistributionSystemEfficiency")
    if dse_heat_raw.nil?
      dse_heat = 1.0
    else
      dse_heat = Float(dse_heat_raw)
    end
    # Get all HVAC systems attached to it
    htgs.each do |htg_system|
      next if htg_system.elements["DistributionSystem"].nil?
      next unless dist_id == htg_system.elements["DistributionSystem"].attributes["idref"]

      sys_id = get_system_or_seed_id(htg_system, eri_design)
      dse_heats[sys_id] = dse_heat
    end
    hp_htgs.each do |heat_pump|
      next if heat_pump.elements["DistributionSystem"].nil?
      next unless dist_id == heat_pump.elements["DistributionSystem"].attributes["idref"]

      sys_id = get_system_or_seed_id(heat_pump, eri_design)
      dse_heats[sys_id] = dse_heat

      if is_dfhp(heat_pump)
        # Also apply to dual-fuel heat pump backup system
        dse_heats[dfhp_backup_sys_id(sys_id)] = dse_heat
      end
    end
  end

  # All HVAC systems not attached to a distribution system get DSE = 1
  htgs.each do |htg_system|
    next unless htg_system.elements["DistributionSystem"].nil?

    sys_id = get_system_or_seed_id(htg_system, eri_design)
    dse_heats[sys_id] = 1.0
  end
  hp_htgs.each do |heat_pump|
    next unless heat_pump.elements["DistributionSystem"].nil?

    sys_id = get_system_or_seed_id(heat_pump, eri_design)
    dse_heats[sys_id] = 1.0

    if is_dfhp(heat_pump)
      # Also apply to dual-fuel heat pump backup system
      dse_heats[dfhp_backup_sys_id(sys_id)] = 1.0
    end
  end

  return dse_heats
end

def get_dse_cools(hpxml_doc, clgs, hp_clgs, eri_design)
  dse_cools = {}

  hpxml_doc.elements.each("/HPXML/Building/BuildingDetails/Systems/HVAC/HVACDistribution") do |hvac_dist|
    dist_id = hvac_dist.elements["SystemIdentifier"].attributes["id"]
    dse_cool_raw = XMLHelper.get_value(hvac_dist, "AnnualCoolingDistributionSystemEfficiency")
    if dse_cool_raw.nil?
      dse_cool = 1.0
    else
      dse_cool = Float(dse_cool_raw)
    end
    # Get all HVAC systems attached to it
    clgs.each do |clg_system|
      next if clg_system.elements["DistributionSystem"].nil?
      next unless dist_id == clg_system.elements["DistributionSystem"].attributes["idref"]

      sys_id = get_system_or_seed_id(clg_system, eri_design)
      dse_cools[sys_id] = dse_cool
    end
    hp_clgs.each do |heat_pump|
      next if heat_pump.elements["DistributionSystem"].nil?
      next unless dist_id == heat_pump.elements["DistributionSystem"].attributes["idref"]

      sys_id = get_system_or_seed_id(heat_pump, eri_design)
      dse_cools[sys_id] = dse_cool
    end
  end

  # All HVAC systems not attached to a distribution system get DSE = 1
  clgs.each do |clg_system|
    next unless clg_system.elements["DistributionSystem"].nil?

    sys_id = get_system_or_seed_id(clg_system, eri_design)
    dse_cools[sys_id] = 1.0
  end
  hp_clgs.each do |heat_pump|
    next unless heat_pump.elements["DistributionSystem"].nil?

    sys_id = get_system_or_seed_id(heat_pump, eri_design)
    dse_cools[sys_id] = 1.0

    if is_dfhp(heat_pump)
      # Also apply to dual-fuel heat pump backup system
      dse_cools[dfhp_backup_sys_id(sys_id)] = 1.0
    end
  end

  return dse_cools
end

def get_eec_value_numerator(unit)
  if ['HSPF', 'SEER', 'EER'].include? unit
    return 3.413
  elsif ['AFUE', 'COP', 'Percent', 'EF'].include? unit
    return 1.0
  end

  fail "Unexpected unit #{unit}."
end

def get_eec_heats(hpxml_doc, htgs, hp_htgs, eri_design)
  eec_heats = {}

  units = ['HSPF', 'COP', 'AFUE', 'Percent']

  htgs.each do |htg_system|
    sys_id = get_system_or_seed_id(htg_system, eri_design)
    units.each do |unit|
      value = XMLHelper.get_value(htg_system, "AnnualHeatingEfficiency[Units='#{unit}']/Value")
      next if value.nil?

      eec_heats[sys_id] = get_eec_value_numerator(unit) / Float(value)
    end
  end
  hp_htgs.each do |heat_pump|
    sys_id = get_system_or_seed_id(heat_pump, eri_design)
    units.each do |unit|
      value = XMLHelper.get_value(heat_pump, "AnnualHeatingEfficiency[Units='#{unit}']/Value")
      next if value.nil?

      eec_heats[sys_id] = get_eec_value_numerator(unit) / Float(value)
    end
    if is_dfhp(heat_pump)
      units.each do |unit|
        value = XMLHelper.get_value(heat_pump, "BackupAnnualHeatingEfficiency[Units='#{unit}']/Value")
        next if value.nil?

        eec_heats[dfhp_backup_sys_id(sys_id)] = get_eec_value_numerator(unit) / Float(value)
      end
    end
  end

  if eec_heats.empty?
    fail "No heating systems found."
  end

  return eec_heats
end

def get_eec_cools(hpxml_doc, clgs, hp_clgs, eri_design)
  eec_cools = {}

  units = ['SEER', 'COP', 'EER']

  clgs.each do |clg_system|
    sys_id = get_system_or_seed_id(clg_system, eri_design)
    units.each do |unit|
      value = XMLHelper.get_value(clg_system, "AnnualCoolingEfficiency[Units='#{unit}']/Value")
      next if value.nil?

      eec_cools[sys_id] = get_eec_value_numerator(unit) / Float(value)
    end

    if XMLHelper.get_value(clg_system, "CoolingSystemType") == "evaporative cooler"
      eec_cools[sys_id] = get_eec_value_numerator("SEER") / 15.0 # Arbitrary
    end
  end
  hp_clgs.each do |heat_pump|
    sys_id = get_system_or_seed_id(heat_pump, eri_design)
    units.each do |unit|
      value = XMLHelper.get_value(heat_pump, "AnnualCoolingEfficiency[Units='#{unit}']/Value")
      next if value.nil?

      eec_cools[sys_id] = get_eec_value_numerator(unit) / Float(value)
    end
  end

  if eec_cools.empty?
    fail "No cooling systems found."
  end

  return eec_cools
end

def get_eec_dhws(hpxml_doc, dhws)
  eec_dhws = {}

  dhws.each do |dhw_system|
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
      hpxml_doc.elements.each("/HPXML/Building/BuildingDetails/Systems/HVAC/HVACPlant/HeatingSystem") do |heating_system|
        next unless heating_system.elements["SystemIdentifier"].attributes["id"] == hvac_idref

        combi_boiler_afue = Float(XMLHelper.get_value(heating_system, "AnnualHeatingEfficiency[Units='AFUE']/Value"))
        break
      end
      value = Waterheater.calc_tank_EF(combi_type, ua, combi_boiler_afue)
    end

    if not value.nil? and not value_adj.nil?
      eec_dhws[sys_id] = get_eec_value_numerator('EF') / (Float(value) * Float(value_adj))
    end
  end

  if eec_dhws.empty?
    fail "No water heating systems found."
  end

  return eec_dhws
end

def get_dhw_solar_fraction(hpxml_doc, sys_id)
  solar_fraction = 0.0
  hpxml_doc.elements.each("/HPXML/Building/BuildingDetails/Systems/SolarThermal/SolarThermalSystem") do |system|
    next unless sys_id == system.elements["ConnectedTo"].attributes["idref"]

    solar_fraction = XMLHelper.get_value(system, "SolarFraction").to_f
  end
  return solar_fraction
end

def get_ep_output_names_for_hvac_heating(map_tsv_data, sys_id, hpxml_doc)
  dfhp_primary = false
  dfhp_backup = false
  hpxml_doc.elements.each("/HPXML/Building/BuildingDetails/Systems/HVAC/HVACPlant/HeatingSystem |
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

  map_tsv_data.each do |tsv_line|
    next unless tsv_line[0] == sys_id

    output_names = tsv_line[1..-1]

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
    fail "[#{design_name}] Could not find EnergyPlus output name associated with #{sys_id}." if output_names.size == 0

    return output_names, dfhp_primary, dfhp_backup
  end

  fail "[#{design_name}] Could not find EnergyPlus output name associated with #{sys_id}."
end

def get_ep_output_names_for_hvac_cooling(map_tsv_data, sys_id, hpxml_doc)
  hpxml_doc.elements.each("/HPXML/Building/BuildingDetails/Systems/HVAC/HVACPlant/CoolingSystem |
                           /HPXML/Building/BuildingDetails/Systems/HVAC/HVACPlant/HeatPump") do |system|
    next unless XMLHelper.get_value(system, "extension/SeedId") == sys_id

    sys_id = system.elements["SystemIdentifier"].attributes["id"]
    break
  end

  map_tsv_data.each do |tsv_line|
    next unless tsv_line[0] == sys_id

    return tsv_line[1..-1]
  end

  fail "[#{design_name}] Could not find EnergyPlus output name associated with #{sys_id}."
end

def get_ep_output_names_for_water_heating(map_tsv_data, sys_id)
  map_tsv_data.each do |tsv_line|
    next unless tsv_line[0] == sys_id

    return tsv_line[1..-1]
  end

  fail "[#{design_name}] Could not find EnergyPlus output name associated with #{sys_id}."
end

def write_summary_output_results(resultsdir, design_name, design_output, design_hourly_output)
  out_csv = File.join(resultsdir, "#{design_name.gsub(' ', '')}.csv")

  results_out = []
  results_out << ["Electricity: Total (MBtu)", design_output[:elecTotal].round(2)]
  results_out << ["Electricity: Net (MBtu)", (design_output[:elecTotal] - design_output[:elecPV]).round(2)]
  results_out << ["Natural Gas: Total (MBtu)", design_output[:gasTotal].round(2)]
  results_out << ["Fuel Oil: Total (MBtu)", design_output[:oilTotal].round(2)]
  results_out << ["Propane: Total (MBtu)", design_output[:propaneTotal].round(2)]
  results_out << [nil] # line break
  results_out << ["Electricity: Heating (MBtu)", design_output[:elecHeatingBySystem].values.inject(0, :+).round(2)]
  results_out << ["Electricity: Cooling (MBtu)", design_output[:elecCoolingBySystem].values.inject(0, :+).round(2)]
  results_out << ["Electricity: Hot Water (MBtu)", design_output[:elecHotWaterBySystem].values.inject(0, :+).round(2)]
  results_out << ["Electricity: Hot Water Recirc Pump (MBtu)", design_output[:elecHotWaterRecircPumpBySystem].values.inject(0, :+).round(2)]
  results_out << ["Electricity: Hot Water Solar Thermal Pump (MBtu)", design_output[:elecHotWaterSolarThermalPumpBySystem].values.inject(0, :+).round(2)]
  results_out << ["Electricity: Lighting Interior (MBtu)", design_output[:elecIntLighting].round(2)]
  results_out << ["Electricity: Lighting Garage (MBtu)", design_output[:elecGrgLighting].round(2)]
  results_out << ["Electricity: Lighting Exterior (MBtu)", design_output[:elecExtLighting].round(2)]
  results_out << ["Electricity: Mech Vent (MBtu)", design_output[:elecMechVent].round(2)]
  results_out << ["Electricity: Refrigerator (MBtu)", design_output[:elecFridge].round(2)]
  results_out << ["Electricity: Dishwasher (MBtu)", design_output[:elecDishwasher].round(2)]
  results_out << ["Electricity: Clothes Washer (MBtu)", design_output[:elecClothesWasher].round(2)]
  results_out << ["Electricity: Clothes Dryer (MBtu)", design_output[:elecClothesDryer].round(2)]
  results_out << ["Electricity: Range/Oven (MBtu)", design_output[:elecRangeOven].round(2)]
  results_out << ["Electricity: Ceiling Fan (MBtu)", design_output[:elecCeilingFan].round(2)]
  results_out << ["Electricity: Plug Loads (MBtu)", (design_output[:elecMELs] + design_output[:elecTV]).round(2)]
  if design_output[:elecPV] > 0
    results_out << ["Electricity: PV (MBtu)", -1.0 * design_output[:elecPV].round(2)]
  else
    results_out << ["Electricity: PV (MBtu)", 0.0]
  end
  results_out << ["Natural Gas: Heating (MBtu)", design_output[:gasHeatingBySystem].values.inject(0, :+).round(2)]
  results_out << ["Natural Gas: Hot Water (MBtu)", design_output[:gasHotWaterBySystem].values.inject(0, :+).round(2)]
  results_out << ["Natural Gas: Clothes Dryer (MBtu)", design_output[:gasClothesDryer].round(2)]
  results_out << ["Natural Gas: Range/Oven (MBtu)", design_output[:gasRangeOven].round(2)]
  results_out << ["Fuel Oil: Heating (MBtu)", design_output[:oilHeatingBySystem].values.inject(0, :+).round(2)]
  results_out << ["Fuel Oil: Hot Water (MBtu)", design_output[:oilHotWaterBySystem].values.inject(0, :+).round(2)]
  results_out << ["Fuel Oil: Clothes Dryer (MBtu)", design_output[:oilClothesDryer].round(2)]
  results_out << ["Fuel Oil: Range/Oven (MBtu)", design_output[:oilRangeOven].round(2)]
  results_out << ["Propane: Heating (MBtu)", design_output[:propaneHeatingBySystem].values.inject(0, :+).round(2)]
  results_out << ["Propane: Hot Water (MBtu)", design_output[:propaneHotWaterBySystem].values.inject(0, :+).round(2)]
  results_out << ["Propane: Clothes Dryer (MBtu)", design_output[:propaneClothesDryer].round(2)]
  results_out << ["Propane: Range/Oven (MBtu)", design_output[:propaneRangeOven].round(2)]
  results_out << [nil] # line break
  results_out << ["Annual Load: Heating (MBtu)", design_output[:loadHeatingBldg].round(2)]
  results_out << ["Annual Load: Cooling (MBtu)", design_output[:loadCoolingBldg].round(2)]
  results_out << ["Annual Load: Hot Water: Delivered (MBtu)", design_output[:loadHotWaterDelivered].round(2)]
  results_out << ["Annual Load: Hot Water: Tank Losses (MBtu)", design_output[:loadHotWaterTankLosses].round(2)]
  results_out << ["Annual Load: Hot Water: Desuperheater (MBtu)", design_output[:loadHotWaterDesuperheater].round(2)]
  results_out << ["Annual Load: Hot Water: Solar Thermal (MBtu)", design_output[:loadHotWaterSolarThermal].round(2)]
  results_out << [nil] # line break
  results_out << ["Annual Unmet Load: Heating (MBtu)", design_output[:unmetLoadHeatingBldg].round(2)]
  results_out << ["Annual Unmet Load: Cooling (MBtu)", design_output[:unmetLoadCoolingBldg].round(2)]
  results_out << [nil] # line break
  results_out << ["Peak Electricity: Winter Total (W)", design_output[:peakElecWinterTotal].round(2)]
  results_out << ["Peak Electricity: Summer Total (W)", design_output[:peakElecSummerTotal].round(2)]
  results_out << [nil] # line break
  results_out << ["Peak Load: Heating (kBtu)", design_output[:peakLoadHeatingBldg].round(2)]
  results_out << ["Peak Load: Cooling (kBtu)", design_output[:peakLoadCoolingBldg].round(2)]
  results_out << [nil] # line break
  { "Heating" => "htg", "Cooling" => "clg" }.each do |mode, mode_var|
    get_component_load_map.each do |component, component_var|
      results_out << ["Component Load: #{mode}: #{component} (MBtu)", design_output["componentLoad#{mode}#{component}"].round(2)]
    end
  end

  CSV.open(out_csv, "wb") { |csv| results_out.to_a.each { |elem| csv << elem } }

  # Check results are internally consistent
  total_results = { "Electricity" => (design_output[:elecTotal] - design_output[:elecPV]).round(2),
                    "Natural Gas" => design_output[:gasTotal].round(2),
                    "Fuel Oil" => design_output[:oilTotal].round(2),
                    "Propane" => design_output[:propaneTotal].round(2) }

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
      fail "[#{design_name}] End uses (#{sum_end_use_results[fuel].round(1)}) do not sum to #{fuel} total (#{total_results[fuel].round(1)}))."
    end
  end

  if not design_hourly_output.nil? and design_hourly_output.size > 0
    out_csv = File.join(resultsdir, "#{design_name.gsub(' ', '')}_Hourly.csv")
    CSV.open(out_csv, "wb") { |csv| design_hourly_output.to_a.each { |elem| csv << elem } }
  end
end

def get_hash_values_in_order(keys, output)
  vals = []
  keys.each do |key|
    vals << output[key]
  end
  return vals
end

def write_eri_output_results(resultsdir, design_name, design_output)
  out_csv = File.join(resultsdir, "#{design_name.gsub(' ', '')}_ERI.csv")

  results_out = []

  # Heating
  keys = design_output[:hpxml_heat_sys_ids]
  results_out << ["hpxml_heat_sys_ids"] + keys
  results_out << ["hpxml_heat_fuels"] + get_hash_values_in_order(keys, design_output[:hpxml_heat_fuels])
  results_out << ["hpxml_eec_heats"] + get_hash_values_in_order(keys, design_output[:hpxml_eec_heats])
  results_out << ["elecHeatingBySystem"] + get_hash_values_in_order(keys, design_output[:elecHeatingBySystem])
  results_out << ["gasHeatingBySystem"] + get_hash_values_in_order(keys, design_output[:gasHeatingBySystem])
  results_out << ["oilHeatingBySystem"] + get_hash_values_in_order(keys, design_output[:oilHeatingBySystem])
  results_out << ["propaneHeatingBySystem"] + get_hash_values_in_order(keys, design_output[:propaneHeatingBySystem])
  results_out << ["loadHeatingBySystem"] + get_hash_values_in_order(keys, design_output[:loadHeatingBySystem])
  results_out << [nil] # line break

  # Cooling
  keys = design_output[:hpxml_cool_sys_ids]
  results_out << ["hpxml_cool_sys_ids"] + keys
  results_out << ["hpxml_eec_cools"] + get_hash_values_in_order(keys, design_output[:hpxml_eec_cools])
  results_out << ["elecCoolingBySystem"] + get_hash_values_in_order(keys, design_output[:elecCoolingBySystem])
  results_out << ["loadCoolingBySystem"] + get_hash_values_in_order(keys, design_output[:loadCoolingBySystem])
  results_out << [nil] # line break

  # DHW
  keys = design_output[:hpxml_dhw_sys_ids]
  results_out << ["hpxml_dhw_sys_ids"] + keys
  results_out << ["hpxml_dwh_fuels"] + get_hash_values_in_order(keys, design_output[:hpxml_dwh_fuels])
  results_out << ["hpxml_eec_dhws"] + get_hash_values_in_order(keys, design_output[:hpxml_eec_dhws])
  results_out << ["elecHotWaterBySystem"] + get_hash_values_in_order(keys, design_output[:elecHotWaterBySystem])
  results_out << ["elecHotWaterRecircPumpBySystem"] + get_hash_values_in_order(keys, design_output[:elecHotWaterRecircPumpBySystem])
  results_out << ["elecHotWaterSolarThermalPumpBySystem"] + get_hash_values_in_order(keys, design_output[:elecHotWaterSolarThermalPumpBySystem])
  results_out << ["gasHotWaterBySystem"] + get_hash_values_in_order(keys, design_output[:gasHotWaterBySystem])
  results_out << ["oilHotWaterBySystem"] + get_hash_values_in_order(keys, design_output[:oilHotWaterBySystem])
  results_out << ["propaneHotWaterBySystem"] + get_hash_values_in_order(keys, design_output[:propaneHotWaterBySystem])
  results_out << ["loadHotWaterBySystem"] + get_hash_values_in_order(keys, design_output[:loadHotWaterBySystem])
  results_out << [nil] # line break

  # Total
  results_out << ["elecTotal", design_output[:elecTotal]]
  results_out << ["gasTotal", design_output[:gasTotal]]
  results_out << ["oilTotal", design_output[:oilTotal]]
  results_out << ["propaneTotal", design_output[:propaneTotal]]
  results_out << ["elecPV", design_output[:elecPV]]
  results_out << [nil] # line break

  # Breakout
  results_out << ["elecIntLighting", design_output[:elecIntLighting]]
  results_out << ["elecExtLighting", design_output[:elecExtLighting]]
  results_out << ["elecGrgLighting", design_output[:elecGrgLighting]]
  results_out << ["elecAppliances", design_output[:elecAppliances]]
  results_out << ["elecMELs", design_output[:elecMELs]]
  results_out << ["elecFridge", design_output[:elecFridge]]
  results_out << ["elecTV", design_output[:elecTV]]
  results_out << ["elecRangeOven", design_output[:elecRangeOven]]
  results_out << ["elecClothesDryer", design_output[:elecClothesDryer]]
  results_out << ["elecDishwasher", design_output[:elecDishwasher]]
  results_out << ["elecClothesWasher", design_output[:elecClothesWasher]]
  results_out << ["elecMechVent", design_output[:elecMechVent]]
  results_out << ["gasAppliances", design_output[:gasAppliances]]
  results_out << ["gasRangeOven", design_output[:gasRangeOven]]
  results_out << ["gasClothesDryer", design_output[:gasClothesDryer]]
  results_out << ["oilAppliances", design_output[:oilAppliances]]
  results_out << ["oilRangeOven", design_output[:oilRangeOven]]
  results_out << ["oilClothesDryer", design_output[:oilClothesDryer]]
  results_out << ["propaneAppliances", design_output[:propaneAppliances]]
  results_out << ["propaneRangeOven", design_output[:propaneRangeOven]]
  results_out << ["propaneClothesDryer", design_output[:propaneClothesDryer]]
  results_out << [nil] # line break

  # Misc
  results_out << ["hpxml_cfa", design_output[:hpxml_cfa]]
  results_out << ["hpxml_nbr", design_output[:hpxml_nbr]]
  results_out << ["hpxml_nst", design_output[:hpxml_nst]]

  CSV.open(out_csv, "wb") { |csv| results_out.to_a.each { |elem| csv << elem } }
end

if ARGV.size == 7
  basedir = ARGV[0]
  output_dir = ARGV[1]
  run = ARGV[2].split("|").map { |x| (x.length == 0 ? nil : x) }
  resultsdir = ARGV[3]
  hpxml = ARGV[4]
  debug = (ARGV[5].downcase.to_s == "true")
  hourly_output = (ARGV[6].downcase.to_s == "true")
  run_design(basedir, output_dir, run, resultsdir, hpxml, debug, hourly_output)
end
