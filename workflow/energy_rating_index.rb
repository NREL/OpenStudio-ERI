start_time = Time.now

require 'optparse'
require 'csv'
require 'pathname'
require 'fileutils'
require 'parallel'
require File.join(File.dirname(__FILE__), "design.rb")
require_relative "../measures/HPXMLtoOpenStudio/measure"
require_relative "../measures/HPXMLtoOpenStudio/resources/constants"
require_relative "../measures/HPXMLtoOpenStudio/resources/waterheater"
require_relative "../measures/HPXMLtoOpenStudio/resources/xmlhelper"

basedir = File.expand_path(File.dirname(__FILE__))

def rm_path(path)
  if Dir.exists?(path)
    FileUtils.rm_r(path)
  end
  while true
    break if not Dir.exists?(path)

    sleep(0.01)
  end
end

def run_design_direct(basedir, output_dir, design, resultsdir, hpxml, debug, skip_validation, hourly_output)
  # Calls design.rb methods directly. Should only be called from a forked
  # process. This is the fastest approach.
  designdir = get_designdir(output_dir, design)
  rm_path(designdir)

  output_hpxml_path = run_design(basedir, output_dir, design, resultsdir, hpxml, debug, skip_validation, hourly_output)

  return output_hpxml_path, designdir
end

def run_design_spawn(basedir, output_dir, design, resultsdir, hpxml, debug, skip_validation, hourly_output)
  # Calls design.rb in a new spawned process in order to utilize multiple
  # processes. Not as efficient as calling design.rb methods directly in
  # forked processes for a couple reasons:
  # 1. There is overhead to using the CLI
  # 2. There is overhead to spawning processes vs using forked processes
  designdir = get_designdir(output_dir, design)
  rm_path(designdir)
  output_hpxml_path = get_output_hpxml_path(resultsdir, designdir)

  cli_path = OpenStudio.getOpenStudioCLI
  pid = Process.spawn("\"#{cli_path}\" --no-ssl \"#{File.join(File.dirname(__FILE__), "design.rb")}\" \"#{basedir}\" \"#{output_dir}\" \"#{design}\" \"#{resultsdir}\" \"#{hpxml}\" #{debug} #{skip_validation} #{hourly_output}")

  return output_hpxml_path, designdir, pid
end

def process_design_output(design, designdir, resultsdir, output_hpxml_path, hourly_output)
  return nil if output_hpxml_path.nil?

  print "[#{design}] Processing output...\n"

  design_output, design_hourly_output = read_output(design, designdir, output_hpxml_path, hourly_output)
  return if design_output.nil?

  write_output_results(resultsdir, design, design_output, design_hourly_output)

  print "[#{design}] Done.\n"

  return design_output
end

def get_combi_hvac_id(hpxml_doc, sys_id)
  hpxml_doc.elements.each("/HPXML/Building/BuildingDetails/Systems/WaterHeating/WaterHeatingSystem[FractionDHWLoadServed > 0]") do |dhw_system|
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

def read_output(design, designdir, output_hpxml_path, hourly_output)
  sql_path = File.join(designdir, "eplusout.sql")
  if not File.exists?(sql_path)
    puts "[#{design}] Processing output unsuccessful."
    return nil
  end

  sqlFile = OpenStudio::SqlFile.new(sql_path, false)
  if not sqlFile.connectionOpen
    puts "[#{design} Processing output unsuccessful."
    return nil
  end

  design_output = {}

  # HPXML
  design_output[:hpxml] = output_hpxml_path
  hpxml_doc = REXML::Document.new(File.read(design_output[:hpxml]))
  design_output[:hpxml_cfa] = get_cfa(hpxml_doc)
  design_output[:hpxml_nbr] = get_nbr(hpxml_doc)
  design_output[:hpxml_nst] = get_nst(hpxml_doc)
  design_output[:hpxml_dse_heats] = get_dse_heats(hpxml_doc, design)
  design_output[:hpxml_dse_cools] = get_dse_cools(hpxml_doc, design)
  design_output[:hpxml_heat_fuels] = get_heat_fuels(hpxml_doc, design)
  design_output[:hpxml_dwh_fuels] = get_dhw_fuels(hpxml_doc)
  design_output[:hpxml_eec_heats] = get_eec_heats(hpxml_doc, design)
  design_output[:hpxml_eec_cools] = get_eec_cools(hpxml_doc, design)
  design_output[:hpxml_eec_dhws] = get_eec_dhws(hpxml_doc)
  design_output[:hpxml_heat_sys_ids] = design_output[:hpxml_eec_heats].keys
  design_output[:hpxml_cool_sys_ids] = design_output[:hpxml_eec_cools].keys
  design_output[:hpxml_dhw_sys_ids] = design_output[:hpxml_eec_dhws].keys

  # Building Space Heating/Cooling Loads (total heating/cooling energy delivered including backup ideal air system)
  query = "SELECT SUM(VariableValue/1000000000) FROM ReportMeterData WHERE ReportMeterDataDictionaryIndex IN (SELECT ReportMeterDataDictionaryIndex FROM ReportMeterDataDictionary WHERE VariableName='Heating:EnergyTransfer:Zone:LIVING' AND ReportingFrequency='Run Period' AND VariableUnits='J')"
  design_output[:loadHeatingBldg] = UnitConversions.convert(sqlFile.execAndReturnFirstDouble(query).get, "GJ", "MBtu")
  query = "SELECT SUM(VariableValue/1000000000) FROM ReportMeterData WHERE ReportMeterDataDictionaryIndex IN (SELECT ReportMeterDataDictionaryIndex FROM ReportMeterDataDictionary WHERE VariableName='Cooling:EnergyTransfer:Zone:LIVING' AND ReportingFrequency='Run Period' AND VariableUnits='J')"
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
  design_output[:hpxml_heat_sys_ids].each do |sys_id|
    ep_output_names = get_ep_output_names_for_hvac_heating(map_tsv_data, sys_id, hpxml_doc, design)
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
    ems_keys = "'" + ep_output_names.select { |name| name.end_with? Constants.ObjectNameFanPumpDisaggregate(false) }.join("','") + "'"
    query = "SELECT SUM(ABS(VariableValue)/1000000000) FROM ReportVariableData WHERE ReportVariableDataDictionaryIndex IN (SELECT ReportVariableDataDictionaryIndex FROM ReportVariableDataDictionary WHERE VariableType='Sum' AND KeyValue='EMS' AND VariableName IN (#{ems_keys}) AND ReportingFrequency='Run Period' AND VariableUnits='J')"
    elecHeatingBySystemRaw += UnitConversions.convert(sqlFile.execAndReturnFirstDouble(query).get, "GJ", "MBtu")

    # apply dse to scale up energy use excluding no distribution systems
    if design_output[:hpxml_dse_heats][sys_id].nil?
      design_output[:elecHeatingBySystem][sys_id] = elecHeatingBySystemRaw
      design_output[:gasHeatingBySystem][sys_id] = gasHeatingBySystemRaw
      design_output[:oilHeatingBySystem][sys_id] = oilHeatingBySystemRaw
      design_output[:propaneHeatingBySystem][sys_id] = propaneHeatingBySystemRaw
    else
      design_output[:elecHeatingBySystem][sys_id] = elecHeatingBySystemRaw / design_output[:hpxml_dse_heats][sys_id]
      design_output[:gasHeatingBySystem][sys_id] = gasHeatingBySystemRaw / design_output[:hpxml_dse_heats][sys_id]
      design_output[:oilHeatingBySystem][sys_id] = oilHeatingBySystemRaw / design_output[:hpxml_dse_heats][sys_id]
      design_output[:propaneHeatingBySystem][sys_id] = propaneHeatingBySystemRaw / design_output[:hpxml_dse_heats][sys_id]
      # Also update totals:
      design_output[:elecTotal] += (design_output[:elecHeatingBySystem][sys_id] - elecHeatingBySystemRaw)
      design_output[:gasTotal] += (design_output[:gasHeatingBySystem][sys_id] - gasHeatingBySystemRaw)
      design_output[:oilTotal] += (design_output[:oilHeatingBySystem][sys_id] - oilHeatingBySystemRaw)
      design_output[:propaneTotal] += (design_output[:propaneHeatingBySystem][sys_id] - propaneHeatingBySystemRaw)
    end

    # Reference Load
    if [Constants.CalcTypeERIReferenceHome, Constants.CalcTypeERIIndexAdjustmentReferenceHome].include? design
      design_output[:loadHeatingBySystem][sys_id] = split_htg_load_to_system_by_fraction(sys_id, design_output[:loadHeatingBldg], hpxml_doc, design)
    end
  end

  # Space Cooling (by System)
  design_output[:elecCoolingBySystem] = {}
  design_output[:loadCoolingBySystem] = {}
  design_output[:hpxml_cool_sys_ids].each do |sys_id|
    ep_output_names = get_ep_output_names_for_hvac_cooling(map_tsv_data, sys_id, hpxml_doc, design)
    keys = "'" + ep_output_names.map(&:upcase).join("','") + "'"

    # Electricity Use
    vars = "'" + get_all_var_keys(OutputVars.SpaceCoolingElectricity).join("','") + "'"
    query = "SELECT SUM(ABS(VariableValue)/1000000000) FROM ReportVariableData WHERE ReportVariableDataDictionaryIndex IN (SELECT ReportVariableDataDictionaryIndex FROM ReportVariableDataDictionary WHERE VariableType='Sum' AND KeyValue IN (#{keys}) AND VariableName IN (#{vars}) AND ReportingFrequency='Run Period' AND VariableUnits='J')"
    elecCoolingBySystemRaw = UnitConversions.convert(sqlFile.execAndReturnFirstDouble(query).get, "GJ", "MBtu")

    # Disaggregated Fan Energy Use
    ems_keys = "'" + ep_output_names.select { |name| name.end_with? Constants.ObjectNameFanPumpDisaggregate(true) }.join("','") + "'"
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
    if [Constants.CalcTypeERIReferenceHome, Constants.CalcTypeERIIndexAdjustmentReferenceHome].include? design
      design_output[:loadCoolingBySystem][sys_id] = split_clg_load_to_system_by_fraction(sys_id, design_output[:loadCoolingBldg], hpxml_doc, design)
    end
  end

  # Water Heating (by System)
  map_tsv_data = CSV.read(File.join(designdir, "map_water_heating.tsv"), headers: false, col_sep: "\t")
  design_output[:elecHotWaterBySystem] = {}
  design_output[:elecHotWaterRecircPumpBySystem] = {}
  design_output[:gasHotWaterBySystem] = {}
  design_output[:oilHotWaterBySystem] = {}
  design_output[:propaneHotWaterBySystem] = {}
  design_output[:loadHotWaterBySystem] = {}
  design_output[:loadHotWaterDesuperheater] = 0
  design_output[:hpxml_dhw_sys_ids].each do |sys_id|
    ep_output_names = get_ep_output_names_for_water_heating(map_tsv_data, sys_id, hpxml_doc, design)
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
    ems_keys = "'" + ep_output_names.select { |name| name.include? Constants.ObjectNameDesuperheater(nil) }.join("','") + "'"
    query = "SELECT SUM(ABS(VariableValue)/1000000000) FROM ReportVariableData WHERE ReportVariableDataDictionaryIndex IN (SELECT ReportVariableDataDictionaryIndex FROM ReportVariableDataDictionary WHERE VariableType='Sum' AND KeyValue='EMS' AND VariableName IN (#{ems_keys}) AND ReportingFrequency='Run Period' AND VariableUnits='J')"
    design_output[:loadHotWaterDesuperheater] += UnitConversions.convert(sqlFile.execAndReturnFirstDouble(query).get, "GJ", "MBtu")

    # Combi boiler water system
    hvac_id = get_combi_hvac_id(hpxml_doc, sys_id)
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
    query = "SELECT SUM(Value) FROM TabularDataWithStrings WHERE ReportName='EnergyMeters' AND ReportForString='Entire Facility' AND TableName LIKE 'Annual and Peak Values%' AND RowName LIKE '%#{Constants.ObjectNameWaterHeaterAdjustment(nil)}:InteriorEquipment:Electricity' AND ColumnName LIKE '%Annual Value' AND Units='GJ'"
    ec_adj = UnitConversions.convert(sqlFile.execAndReturnFirstDouble(query).get, "GJ", "MBtu")
    
    # Desuperheater adjustment
    query = "SELECT SUM(Value) FROM TabularDataWithStrings WHERE ReportName='EnergyMeters' AND ReportForString='Entire Facility' AND TableName LIKE 'Annual and Peak Values%' AND RowName LIKE '%#{Constants.ObjectNameDesuperheater(nil)}:InteriorEquipment:Electricity' AND ColumnName LIKE '%Annual Value' AND Units='GJ'"
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

  # Hot Water Load - Tank Losses
  query = "SELECT SUM(ABS(VariableValue)/1000000000) FROM ReportVariableData WHERE ReportVariableDataDictionaryIndex IN (SELECT ReportVariableDataDictionaryIndex FROM ReportVariableDataDictionary WHERE VariableType='Sum' AND VariableName='Water Heater Heat Loss Energy' AND ReportingFrequency='Run Period' AND VariableUnits='J')"
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
    puts "[#{design}] Processing output unsuccessful."
    return nil
  end

  sum_elec_categories = (design_output[:elecHeatingBySystem].values.inject(0, :+) +
                         design_output[:elecCoolingBySystem].values.inject(0, :+) +
                         design_output[:elecHotWaterBySystem].values.inject(0, :+) +
                         design_output[:elecHotWaterRecircPumpBySystem].values.inject(0, :+) +
                         design_output[:elecIntLighting] +
                         design_output[:elecGrgLighting] +
                         design_output[:elecExtLighting] +
                         design_output[:elecAppliances])
  if (design_output[:elecTotal] - sum_elec_categories).abs > tolerance
    fail "[#{design}] Electric category end uses (#{sum_elec_categories}) do not sum to total (#{design_output[:elecTotal]}).\n#{design_output.to_s}"
  end

  sum_gas_categories = (design_output[:gasHeatingBySystem].values.inject(0, :+) +
                        design_output[:gasHotWaterBySystem].values.inject(0, :+) +
                        design_output[:gasAppliances])
  if (design_output[:gasTotal] - sum_gas_categories).abs > tolerance
    fail "[#{design}] Natural gas category end uses (#{sum_gas_categories}) do not sum to total (#{design_output[:gasTotal]}).\n#{design_output.to_s}"
  end

  sum_oil_categories = (design_output[:oilHeatingBySystem].values.inject(0, :+) +
                        design_output[:oilHotWaterBySystem].values.inject(0, :+) +
                        design_output[:oilAppliances])
  if (design_output[:oilTotal] - sum_oil_categories).abs > tolerance
    fail "[#{design}] Oil fuel category end uses (#{sum_oil_categories}) do not sum to total (#{design_output[:oilTotal]}).\n#{design_output.to_s}"
  end

  sum_propane_categories = (design_output[:propaneHeatingBySystem].values.inject(0, :+) +
                            design_output[:propaneHotWaterBySystem].values.inject(0, :+) +
                            design_output[:propaneAppliances])
  if (design_output[:propaneTotal] - sum_propane_categories).abs > tolerance
    fail "[#{design}] Propane fuel category end uses (#{sum_propane_categories}) do not sum to total (#{design_output[:propaneTotal]}).\n#{design_output.to_s}"
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
    fail "[#{design}] Electric appliances (#{sum_elec_appliances}) do not sum to total (#{design_output[:elecAppliances]}).\n#{design_output.to_s}"
  end

  sum_gas_appliances = (design_output[:gasClothesDryer] + design_output[:gasRangeOven])
  if (design_output[:gasAppliances] - sum_gas_appliances).abs > tolerance
    fail "[#{design}] Natural gas appliances (#{sum_gas_appliances}) do not sum to total (#{design_output[:gasAppliances]}).\n#{design_output.to_s}"
  end

  sum_oil_appliances = (design_output[:oilClothesDryer] + design_output[:oilRangeOven])
  if (design_output[:oilAppliances] - sum_oil_appliances).abs > tolerance
    fail "[#{design}] Oil fuel appliances (#{sum_oil_appliances}) do not sum to total (#{design_output[:oilAppliances]}).\n#{design_output.to_s}"
  end

  sum_propane_appliances = (design_output[:propaneClothesDryer] + design_output[:propaneRangeOven])
  if (design_output[:propaneAppliances] - sum_propane_appliances).abs > tolerance
    fail "[#{design}] Propane fuel appliances (#{sum_propane_appliances}) do not sum to total (#{design_output[:propaneAppliances]}).\n#{design_output.to_s}"
  end

  # REUL check: system cooling/heating sum to total bldg load
  if [Constants.CalcTypeERIReferenceHome, Constants.CalcTypeERIIndexAdjustmentReferenceHome].include? design
    sum_sys_htg_load = design_output[:loadHeatingBySystem].values.inject(0) { |sum, value| sum + value }
    if (sum_sys_htg_load - design_output[:loadHeatingBldg]).abs > tolerance
      fail "[#{design}] system heating load not sum to total building heating load"
    end

    sum_sys_clg_load = design_output[:loadCoolingBySystem].values.inject(0) { |sum, value| sum + value }
    if (sum_sys_clg_load - design_output[:loadCoolingBldg]).abs > tolerance
      fail "[#{design}] system cooling load not sum to total building cooling load"
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
  if hourly_output
    # Generate CSV file with hourly output

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

    # Unit conversions
    j_to_kwh = UnitConversions.convert(1.0, "j", "kwh")
    j_to_kbtu = UnitConversions.convert(1.0, "j", "kbtu")

    # Header
    design_hourly_output = [["Hour",
                             "Electricity Use [kWh]",
                             "Natural Gas Use [kBtu]",
                             "Fuel Oil Use [kBtu]",
                             "Propane Use [kBtu]"]]
    zone_names.each do |zone_name|
      design_hourly_output[0] << "#{zone_name.split.map(&:capitalize).join(' ')} Temperature [F]"
    end

    # Electricity
    query = "SELECT VariableValue*#{j_to_kwh} FROM ReportMeterData WHERE ReportMeterDataDictionaryIndex IN (SELECT ReportMeterDataDictionaryIndex FROM ReportMeterDataDictionary WHERE VariableName='Electricity:Facility' AND ReportingFrequency='Hourly') ORDER BY TimeIndex"
    elec_use = sqlFile.execAndReturnVectorOfDouble(query).get
    elec_use += [0.0] * 8760 if elec_use.size == 0
    fail "Unexpected result" if elec_use.size != 8760

    # Natural Gas
    query = "SELECT VariableValue*#{j_to_kbtu} FROM ReportMeterData WHERE ReportMeterDataDictionaryIndex IN (SELECT ReportMeterDataDictionaryIndex FROM ReportMeterDataDictionary WHERE VariableName='Gas:Facility' AND ReportingFrequency='Hourly') ORDER BY TimeIndex"
    gas_use = [] + sqlFile.execAndReturnVectorOfDouble(query).get
    gas_use += [0.0] * 8760 if gas_use.size == 0
    fail "Unexpected result" if gas_use.size != 8760

    # Fuel Oil
    query = "SELECT VariableValue*#{j_to_kbtu} FROM ReportMeterData WHERE ReportMeterDataDictionaryIndex IN (SELECT ReportMeterDataDictionaryIndex FROM ReportMeterDataDictionary WHERE VariableName='FuelOil#1:Facility' AND ReportingFrequency='Hourly') ORDER BY TimeIndex"
    oil_use = [] + sqlFile.execAndReturnVectorOfDouble(query).get
    oil_use += [0.0] * 8760 if oil_use.size == 0
    fail "Unexpected result" if oil_use.size != 8760

    # Propane
    query = "SELECT VariableValue*#{j_to_kbtu} FROM ReportMeterData WHERE ReportMeterDataDictionaryIndex IN (SELECT ReportMeterDataDictionaryIndex FROM ReportMeterDataDictionary WHERE VariableName='Propane:Facility' AND ReportingFrequency='Hourly') ORDER BY TimeIndex"
    propane_use = [] + sqlFile.execAndReturnVectorOfDouble(query).get
    propane_use += [0.0] * 8760 if propane_use.size == 0
    fail "Unexpected result" if propane_use.size != 8760

    elec_use.zip(gas_use, oil_use, propane_use).each_with_index do |(elec, gas, oil, propane), i|
      design_hourly_output << [i + 1, elec.round(2), gas.round(2), oil.round(2), propane.round(2)]
    end

    # Space temperatures
    zone_names.each do |zone_name|
      query = "SELECT (VariableValue*9.0/5.0)+32.0 FROM ReportVariableData WHERE ReportVariableDataDictionaryIndex IN (SELECT ReportVariableDataDictionaryIndex FROM ReportVariableDataDictionary WHERE VariableName='Zone Mean Air Temperature' AND KeyValue='#{zone_name}' AND ReportingFrequency='Hourly') ORDER BY TimeIndex"
      temperatures = sqlFile.execAndReturnVectorOfDouble(query).get
      fail "Unexpected result" if temperatures.size != 8760

      temperatures.each_with_index do |temperature, i|
        design_hourly_output[i + 1] << temperature.round(2)
      end
    end

    # Error Checking
    elec_sum_hourly_gj = (elec_use.inject(0, :+) / j_to_kwh) / 1000000000.0
    query = "SELECT SUM(VariableValue/1000000000) FROM ReportMeterData WHERE ReportMeterDataDictionaryIndex IN (SELECT ReportMeterDataDictionaryIndex FROM ReportMeterDataDictionary WHERE VariableName='Electricity:Facility' AND ReportingFrequency='Run Period' AND VariableUnits='J')"
    elec_annual_gj = sqlFile.execAndReturnFirstDouble(query).get
    if (elec_annual_gj - elec_sum_hourly_gj).abs > tolerance
      fail "[#{design}] Hourly electricity results (#{elec_sum_hourly_gj}) do not sum to annual (#{elec_annual_gj}).\n#{design_output.to_s}"
    end

    gas_sum_hourly_gj = (gas_use.inject(0, :+) / j_to_kbtu) / 1000000000.0
    query = "SELECT SUM(VariableValue/1000000000) FROM ReportMeterData WHERE ReportMeterDataDictionaryIndex IN (SELECT ReportMeterDataDictionaryIndex FROM ReportMeterDataDictionary WHERE VariableName='Gas:Facility' AND ReportingFrequency='Run Period' AND VariableUnits='J')"
    gas_annual_gj = sqlFile.execAndReturnFirstDouble(query).get
    if (gas_annual_gj - gas_sum_hourly_gj).abs > tolerance
      fail "[#{design}] Hourly natural gas results (#{gas_sum_hourly_gj}) do not sum to annual (#{gas_annual_gj}).\n#{design_output.to_s}"
    end

    oil_sum_hourly_gj = (oil_use.inject(0, :+) / j_to_kbtu) / 1000000000.0
    query = "SELECT SUM(VariableValue/1000000000) FROM ReportMeterData WHERE ReportMeterDataDictionaryIndex IN (SELECT ReportMeterDataDictionaryIndex FROM ReportMeterDataDictionary WHERE VariableName='FuelOil#1:Facility' AND ReportingFrequency='Run Period' AND VariableUnits='J')"
    oil_annual_gj = sqlFile.execAndReturnFirstDouble(query).get
    if (oil_annual_gj - oil_sum_hourly_gj).abs > tolerance
      fail "[#{design}] Hourly oil fuel results (#{oil_sum_hourly_gj}) do not sum to annual (#{oil_annual_gj}).\n#{design_output.to_s}"
    end

    propane_sum_hourly_gj = (propane_use.inject(0, :+) / j_to_kbtu) / 1000000000.0
    query = "SELECT SUM(VariableValue/1000000000) FROM ReportMeterData WHERE ReportMeterDataDictionaryIndex IN (SELECT ReportMeterDataDictionaryIndex FROM ReportMeterDataDictionary WHERE VariableName='Propane:Facility' AND ReportingFrequency='Run Period' AND VariableUnits='J')"
    propane_annual_gj = sqlFile.execAndReturnFirstDouble(query).get
    if (propane_annual_gj - propane_sum_hourly_gj).abs > tolerance
      fail "[#{design}] Hourly propane fuel results (#{propane_sum_hourly_gj}) do not sum to annual (#{propane_annual_gj}).\n#{design_output.to_s}"
    end

  end

  return design_output, design_hourly_output
end

def split_htg_load_to_system_by_fraction(sys_id, bldg_load, hpxml_doc, design)
  hpxml_doc.elements.each("/HPXML/Building/BuildingDetails/Systems/HVAC/HVACPlant/HeatingSystem[FractionHeatLoadServed > 0]") do |htg_system|
    next unless get_system_or_seed_id(htg_system, design) == sys_id

    return bldg_load * Float(XMLHelper.get_value(htg_system, "FractionHeatLoadServed"))
  end
  hpxml_doc.elements.each("/HPXML/Building/BuildingDetails/Systems/HVAC/HVACPlant/HeatPump[FractionHeatLoadServed > 0]") do |heat_pump|
    next unless get_system_or_seed_id(heat_pump, design) == sys_id

    return bldg_load * Float(XMLHelper.get_value(heat_pump, "FractionHeatLoadServed"))
  end
end

def split_clg_load_to_system_by_fraction(sys_id, bldg_load, hpxml_doc, design)
  hpxml_doc.elements.each("/HPXML/Building/BuildingDetails/Systems/HVAC/HVACPlant/CoolingSystem[FractionCoolLoadServed > 0]") do |clg_system|
    next unless get_system_or_seed_id(clg_system, design) == sys_id

    return bldg_load * Float(XMLHelper.get_value(clg_system, "FractionCoolLoadServed"))
  end
  hpxml_doc.elements.each("/HPXML/Building/BuildingDetails/Systems/HVAC/HVACPlant/HeatPump[FractionCoolLoadServed > 0]") do |heat_pump|
    next unless get_system_or_seed_id(heat_pump, design) == sys_id

    return bldg_load * Float(XMLHelper.get_value(heat_pump, "FractionCoolLoadServed"))
  end
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

def get_system_or_seed_id(sys, design)
  if [Constants.CalcTypeERIReferenceHome,
      Constants.CalcTypeERIIndexAdjustmentReferenceHome].include? design
    if XMLHelper.has_element(sys, "extension/SeedId")
      return XMLHelper.get_value(sys, "extension/SeedId")
    end
  end
  return sys.elements["SystemIdentifier"].attributes["id"]
end

def get_heat_fuels(hpxml_doc, design)
  heat_fuels = {}

  hpxml_doc.elements.each("/HPXML/Building/BuildingDetails/Systems/HVAC/HVACPlant/HeatingSystem[FractionHeatLoadServed > 0]") do |htg_system|
    sys_id = get_system_or_seed_id(htg_system, design)
    heat_fuels[sys_id] = XMLHelper.get_value(htg_system, "HeatingSystemFuel")
  end
  hpxml_doc.elements.each("/HPXML/Building/BuildingDetails/Systems/HVAC/HVACPlant/HeatPump[FractionHeatLoadServed > 0]") do |heat_pump|
    sys_id = get_system_or_seed_id(heat_pump, design)
    heat_fuels[sys_id] = XMLHelper.get_value(heat_pump, "HeatPumpFuel")
  end

  if heat_fuels.empty?
    fail "No heating systems found."
  end

  return heat_fuels
end

def get_dhw_fuels(hpxml_doc)
  dhw_fuels = {}

  hpxml_doc.elements.each("/HPXML/Building/BuildingDetails/Systems/WaterHeating/WaterHeatingSystem[FractionDHWLoadServed > 0]") do |dhw_system|
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

def get_dse_heats(hpxml_doc, design)
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
    hpxml_doc.elements.each("/HPXML/Building/BuildingDetails/Systems/HVAC/HVACPlant/HeatingSystem[FractionHeatLoadServed > 0]") do |htg_system|
      next if htg_system.elements["DistributionSystem"].nil?
      next unless dist_id == htg_system.elements["DistributionSystem"].attributes["idref"]

      sys_id = get_system_or_seed_id(htg_system, design)
      dse_heats[sys_id] = dse_heat
    end
    hpxml_doc.elements.each("/HPXML/Building/BuildingDetails/Systems/HVAC/HVACPlant/HeatPump[FractionHeatLoadServed > 0]") do |heat_pump|
      next if heat_pump.elements["DistributionSystem"].nil?
      next unless dist_id == heat_pump.elements["DistributionSystem"].attributes["idref"]

      sys_id = get_system_or_seed_id(heat_pump, design)
      dse_heats[sys_id] = dse_heat
    end
  end

  return dse_heats
end

def get_dse_cools(hpxml_doc, design)
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
    hpxml_doc.elements.each("/HPXML/Building/BuildingDetails/Systems/HVAC/HVACPlant/CoolingSystem[FractionCoolLoadServed > 0]") do |clg_system|
      next if clg_system.elements["DistributionSystem"].nil?
      next unless dist_id == clg_system.elements["DistributionSystem"].attributes["idref"]

      sys_id = get_system_or_seed_id(clg_system, design)
      dse_cools[sys_id] = dse_cool
    end
    hpxml_doc.elements.each("/HPXML/Building/BuildingDetails/Systems/HVAC/HVACPlant/HeatPump[FractionCoolLoadServed > 0]") do |heat_pump|
      next if heat_pump.elements["DistributionSystem"].nil?
      next unless dist_id == heat_pump.elements["DistributionSystem"].attributes["idref"]

      sys_id = get_system_or_seed_id(heat_pump, design)
      dse_cools[sys_id] = dse_cool
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

def get_eec_heats(hpxml_doc, design)
  eec_heats = {}

  units = ['HSPF', 'COP', 'AFUE', 'Percent']

  hpxml_doc.elements.each("/HPXML/Building/BuildingDetails/Systems/HVAC/HVACPlant/HeatingSystem[FractionHeatLoadServed > 0]") do |htg_system|
    sys_id = get_system_or_seed_id(htg_system, design)
    units.each do |unit|
      value = XMLHelper.get_value(htg_system, "AnnualHeatingEfficiency[Units='#{unit}']/Value")
      next if value.nil?

      eec_heats[sys_id] = get_eec_value_numerator(unit) / Float(value)
    end
  end
  hpxml_doc.elements.each("/HPXML/Building/BuildingDetails/Systems/HVAC/HVACPlant/HeatPump[FractionHeatLoadServed > 0]") do |heat_pump|
    sys_id = get_system_or_seed_id(heat_pump, design)
    units.each do |unit|
      value = XMLHelper.get_value(heat_pump, "AnnualHeatingEfficiency[Units='#{unit}']/Value")
      next if value.nil?

      eec_heats[sys_id] = get_eec_value_numerator(unit) / Float(value)
    end
  end

  if eec_heats.empty?
    fail "No heating systems found."
  end

  return eec_heats
end

def get_eec_cools(hpxml_doc, design)
  eec_cools = {}

  units = ['SEER', 'COP', 'EER']

  hpxml_doc.elements.each("/HPXML/Building/BuildingDetails/Systems/HVAC/HVACPlant/CoolingSystem[FractionCoolLoadServed > 0]") do |clg_system|
    sys_id = get_system_or_seed_id(clg_system, design)
    units.each do |unit|
      value = XMLHelper.get_value(clg_system, "AnnualCoolingEfficiency[Units='#{unit}']/Value")
      next if value.nil?

      eec_cools[sys_id] = get_eec_value_numerator(unit) / Float(value)
    end

    if XMLHelper.get_value(clg_system, "CoolingSystemType") == "evaporative cooler"
      eec_cools[sys_id] = get_eec_value_numerator("SEER") / 15.0 # Arbitrary
    end
  end
  hpxml_doc.elements.each("/HPXML/Building/BuildingDetails/Systems/HVAC/HVACPlant/HeatPump[FractionCoolLoadServed > 0]") do |heat_pump|
    sys_id = get_system_or_seed_id(heat_pump, design)
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

def get_eec_dhws(hpxml_doc)
  eec_dhws = {}

  hpxml_doc.elements.each("/HPXML/Building/BuildingDetails/Systems/WaterHeating/WaterHeatingSystem[FractionDHWLoadServed > 0]") do |dhw_system|
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
        combi_type = Constants.WaterHeaterTypeTankless
        ua = nil
      elsif wh_type == 'space-heating boiler with storage tank'
        vol = Float(XMLHelper.get_value(dhw_system, "TankVolume"))
        jacket_r = XMLHelper.get_value(dhw_system, "WaterHeaterInsulation/Jacket/JacketRValue").to_f
        assumed_ef = Waterheater.get_indirect_assumed_ef_for_tank_losses()
        assumed_fuel = Waterheater.get_indirect_assumed_fuel_for_tank_losses()
        dummy_u, ua, dummy_eta = Waterheater.calc_tank_UA(vol, assumed_fuel, assumed_ef, nil, nil, Constants.WaterHeaterTypeTank, 0.0, jacket_r, nil)
        combi_type = Constants.WaterHeaterTypeTank
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

def get_ep_output_names_for_hvac_heating(map_tsv_data, sys_id, hpxml_doc, design)
  hpxml_doc.elements.each("/HPXML/Building/BuildingDetails/Systems/HVAC/HVACPlant/HeatingSystem |
                           /HPXML/Building/BuildingDetails/Systems/HVAC/HVACPlant/HeatPump") do |system|
    next unless XMLHelper.get_value(system, "extension/SeedId") == sys_id

    sys_id = system.elements["SystemIdentifier"].attributes["id"]
    break
  end

  map_tsv_data.each do |tsv_line|
    next unless tsv_line[0] == sys_id

    return tsv_line[1..-1]
  end

  fail "[#{design}] Could not find EnergyPlus output name associated with #{sys_id}."
end

def get_ep_output_names_for_hvac_cooling(map_tsv_data, sys_id, hpxml_doc, design)
  hpxml_doc.elements.each("/HPXML/Building/BuildingDetails/Systems/HVAC/HVACPlant/CoolingSystem |
                           /HPXML/Building/BuildingDetails/Systems/HVAC/HVACPlant/HeatPump") do |system|
    next unless XMLHelper.get_value(system, "extension/SeedId") == sys_id

    sys_id = system.elements["SystemIdentifier"].attributes["id"]
  end

  map_tsv_data.each do |tsv_line|
    next unless tsv_line[0] == sys_id

    return tsv_line[1..-1]
  end

  fail "[#{design}] Could not find EnergyPlus output name associated with #{sys_id}."
end

def get_ep_output_names_for_water_heating(map_tsv_data, sys_id, hpxml_doc, design)
  map_tsv_data.each do |tsv_line|
    next unless tsv_line[0] == sys_id

    return tsv_line[1..-1]
  end

  fail "[#{design}] Could not find EnergyPlus output name associated with #{sys_id}."
end

def calculate_eri(rated_output, ref_output, results_iad = nil)
  results = {}

  # ======= #
  # Heating #
  # ======= #

  results[:reul_heat] = {}
  results[:coeff_heat_a] = {}
  results[:coeff_heat_b] = {}
  results[:eec_x_heat] = {}
  results[:eec_r_heat] = {}
  results[:ec_x_heat] = {}
  results[:ec_r_heat] = {}
  results[:dse_r_heat] = {}
  results[:nec_x_heat] = {}
  results[:nmeul_heat] = {}

  rated_output[:hpxml_heat_sys_ids].each do |s|
    reul_heat = ref_output[:loadHeatingBySystem][s]

    coeff_heat_a = nil
    coeff_heat_b = nil
    if rated_output[:hpxml_heat_fuels][s] == 'electricity'
      coeff_heat_a = 2.2561
      coeff_heat_b = 0.0
    elsif ['natural gas', 'fuel oil', 'propane'].include? rated_output[:hpxml_heat_fuels][s]
      coeff_heat_a = 1.0943
      coeff_heat_b = 0.4030
    end
    if coeff_heat_a.nil? or coeff_heat_b.nil?
      fail "Could not identify EEC coefficients for heating system."
    end

    eec_x_heat = rated_output[:hpxml_eec_heats][s]
    eec_r_heat = ref_output[:hpxml_eec_heats][s]

    ec_x_heat = rated_output[:elecHeatingBySystem][s] + rated_output[:gasHeatingBySystem][s] + rated_output[:oilHeatingBySystem][s] + rated_output[:propaneHeatingBySystem][s]
    ec_r_heat = ref_output[:elecHeatingBySystem][s] + ref_output[:gasHeatingBySystem][s] + ref_output[:oilHeatingBySystem][s] + ref_output[:propaneHeatingBySystem][s]

    dse_r_heat = reul_heat / ec_r_heat * eec_r_heat

    nec_x_heat = 0
    if eec_x_heat * reul_heat > 0
      nec_x_heat = (coeff_heat_a * eec_x_heat - coeff_heat_b) * (ec_x_heat * ec_r_heat * dse_r_heat) / (eec_x_heat * reul_heat)
    end

    nmeul_heat = 0
    if ec_r_heat > 0
      nmeul_heat = reul_heat * (nec_x_heat / ec_r_heat)
    end

    results[:reul_heat][s] = reul_heat
    results[:coeff_heat_a][s] = coeff_heat_a
    results[:coeff_heat_b][s] = coeff_heat_b
    results[:eec_x_heat][s] = eec_x_heat
    results[:eec_r_heat][s] = eec_r_heat
    results[:ec_x_heat][s] = ec_x_heat
    results[:ec_r_heat][s] = ec_r_heat
    results[:dse_r_heat][s] = dse_r_heat
    results[:nec_x_heat][s] = nec_x_heat
    results[:nmeul_heat][s] = nmeul_heat
  end

  # ======= #
  # Cooling #
  # ======= #

  results[:reul_cool] = {}
  results[:coeff_cool_a] = {}
  results[:coeff_cool_b] = {}
  results[:eec_x_cool] = {}
  results[:eec_r_cool] = {}
  results[:ec_x_cool] = {}
  results[:ec_r_cool] = {}
  results[:dse_r_cool] = {}
  results[:nec_x_cool] = {}
  results[:nmeul_cool] = {}

  rated_output[:hpxml_cool_sys_ids].each do |s|
    reul_cool = ref_output[:loadCoolingBySystem][s]

    coeff_cool_a = 3.8090
    coeff_cool_b = 0.0

    eec_x_cool = rated_output[:hpxml_eec_cools][s]
    eec_r_cool = ref_output[:hpxml_eec_cools][s]

    ec_x_cool = rated_output[:elecCoolingBySystem][s]
    ec_r_cool = ref_output[:elecCoolingBySystem][s]

    dse_r_cool = reul_cool / ec_r_cool * eec_r_cool

    nec_x_cool = 0
    if eec_x_cool * reul_cool > 0
      nec_x_cool = (coeff_cool_a * eec_x_cool - coeff_cool_b) * (ec_x_cool * ec_r_cool * dse_r_cool) / (eec_x_cool * reul_cool)
    end

    nmeul_cool = 0
    if ec_r_cool > 0
      nmeul_cool = reul_cool * (nec_x_cool / ec_r_cool)
    end

    results[:reul_cool][s] = reul_cool
    results[:coeff_cool_a][s] = coeff_cool_a
    results[:coeff_cool_b][s] = coeff_cool_b
    results[:eec_x_cool][s] = eec_x_cool
    results[:eec_r_cool][s] = eec_r_cool
    results[:ec_x_cool][s] = ec_x_cool
    results[:ec_r_cool][s] = ec_r_cool
    results[:dse_r_cool][s] = dse_r_cool
    results[:nec_x_cool][s] = nec_x_cool
    results[:nmeul_cool][s] = nmeul_cool
  end

  # ======== #
  # HotWater #
  # ======== #

  results[:reul_dhw] = {}
  results[:coeff_dhw_a] = {}
  results[:coeff_dhw_b] = {}
  results[:eec_x_dhw] = {}
  results[:eec_r_dhw] = {}
  results[:ec_x_dhw] = {}
  results[:ec_r_dhw] = {}
  results[:dse_r_dhw] = {}
  results[:nec_x_dhw] = {}
  results[:nmeul_dhw] = {}

  rated_output[:hpxml_dhw_sys_ids].each do |s|
    reul_dhw = ref_output[:loadHotWaterBySystem][s]

    coeff_dhw_a = nil
    coeff_dhw_b = nil
    if rated_output[:hpxml_dwh_fuels][s] == 'electricity'
      coeff_dhw_a = 0.9200
      coeff_dhw_b = 0.0
    elsif ['natural gas', 'fuel oil', 'propane'].include? rated_output[:hpxml_dwh_fuels][s]
      coeff_dhw_a = 1.1877
      coeff_dhw_b = 1.0130
    end
    if coeff_dhw_a.nil? or coeff_dhw_b.nil?
      fail "Could not identify EEC coefficients for water heating system."
    end

    eec_x_dhw = rated_output[:hpxml_eec_dhws][s]
    eec_r_dhw = ref_output[:hpxml_eec_dhws][s]

    ec_x_dhw = rated_output[:elecHotWaterBySystem][s] + rated_output[:gasHotWaterBySystem][s] + rated_output[:oilHotWaterBySystem][s] + rated_output[:propaneHotWaterBySystem][s] + rated_output[:elecHotWaterRecircPumpBySystem][s]
    ec_r_dhw = ref_output[:elecHotWaterBySystem][s] + ref_output[:gasHotWaterBySystem][s] + ref_output[:oilHotWaterBySystem][s] + ref_output[:propaneHotWaterBySystem][s] + ref_output[:elecHotWaterRecircPumpBySystem][s]

    dse_r_dhw = reul_dhw / ec_r_dhw * eec_r_dhw

    nec_x_dhw = 0
    if eec_x_dhw * reul_dhw > 0
      nec_x_dhw = (coeff_dhw_a * eec_x_dhw - coeff_dhw_b) * (ec_x_dhw * ec_r_dhw * dse_r_dhw) / (eec_x_dhw * reul_dhw)
    end

    nmeul_dhw = 0
    if ec_r_dhw > 0
      nmeul_dhw = reul_dhw * (nec_x_dhw / ec_r_dhw)
    end

    results[:reul_dhw][s] = reul_dhw
    results[:coeff_dhw_a][s] = coeff_dhw_a
    results[:coeff_dhw_b][s] = coeff_dhw_b
    results[:eec_x_dhw][s] = eec_x_dhw
    results[:eec_r_dhw][s] = eec_r_dhw
    results[:ec_x_dhw][s] = ec_x_dhw
    results[:ec_r_dhw][s] = ec_r_dhw
    results[:dse_r_dhw][s] = dse_r_dhw
    results[:nec_x_dhw][s] = nec_x_dhw
    results[:nmeul_dhw][s] = nmeul_dhw
  end

  # ===== #
  # Other #
  # ===== #

  results[:teu] = rated_output[:elecTotal] + 0.4 * (rated_output[:gasTotal] + rated_output[:oilTotal] + rated_output[:propaneTotal])
  results[:opp] = rated_output[:elecPV]

  results[:pefrac] = 1.0
  if results[:teu] > 0
    results[:pefrac] = (results[:teu] - results[:opp]) / results[:teu]
  end

  results[:eul_la] = (rated_output[:elecIntLighting] + rated_output[:elecExtLighting] +
                      rated_output[:elecGrgLighting] + rated_output[:elecAppliances] +
                      rated_output[:gasAppliances] + rated_output[:oilAppliances] + rated_output[:propaneAppliances])

  results[:reul_la] = (ref_output[:elecIntLighting] + ref_output[:elecExtLighting] +
                       ref_output[:elecGrgLighting] + ref_output[:elecAppliances] +
                       ref_output[:gasAppliances] + ref_output[:oilAppliances] + ref_output[:propaneAppliances])

  # === #
  # ERI #
  # === #

  results[:trl] = results[:reul_heat].values.inject(0, :+) +
                  results[:reul_cool].values.inject(0, :+) +
                  results[:reul_dhw].values.inject(0, :+) +
                  results[:reul_la]
  results[:tnml] = results[:nmeul_heat].values.inject(0, :+) +
                   results[:nmeul_cool].values.inject(0, :+) +
                   results[:nmeul_dhw].values.inject(0, :+) +
                   results[:eul_la]

  if not results_iad.nil?

    # ANSI/RESNET/ICC 301-2014 Addendum E-2018 House Size Index Adjustment Factors (IAF)

    results[:iad_save] = (100.0 - results_iad[:eri]) / 100.0

    results[:iaf_cfa] = (2400.0 / rated_output[:hpxml_cfa])**(0.304 * results[:iad_save])
    results[:iaf_nbr] = 1.0 + (0.069 * results[:iad_save] * (rated_output[:hpxml_nbr] - 3.0))
    results[:iaf_ns] = (2.0 / rated_output[:hpxml_nst])**(0.12 * results[:iad_save])
    results[:iaf_rh] = results[:iaf_cfa] * results[:iaf_nbr] * results[:iaf_ns]

    results[:eri] = results[:pefrac] * results[:tnml] / (results[:trl] * results[:iaf_rh]) * 100.0

  else

    results[:eri] = results[:pefrac] * results[:tnml] / results[:trl] * 100.0

  end

  return results
end

def write_output_results(resultsdir, design, design_output, design_hourly_output)
  out_csv = File.join(resultsdir, "#{design.gsub(' ', '')}.csv")

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
      fail "[#{design}] End uses (#{sum_end_use_results[fuel].round(1)}) do not sum to #{fuel} total (#{total_results[fuel].round(1)}))."
    end
  end

  if not design_hourly_output.nil? and design_hourly_output.size > 0
    out_csv = File.join(resultsdir, "#{design.gsub(' ', '')}_Hourly.csv")
    CSV.open(out_csv, "wb") { |csv| design_hourly_output.to_a.each { |elem| csv << elem } }
  end
end

def write_results(results, resultsdir, design_outputs, using_iaf)
  ref_output = design_outputs[Constants.CalcTypeERIReferenceHome]

  # Results file
  results_csv = File.join(resultsdir, "ERI_Results.csv")
  results_out = []
  results_out << ["ERI", results[:eri].round(2)]
  results_out << ["REUL Heating (MBtu)", results[:reul_heat].values.map { |x| x.round(2) }.join(",")]
  results_out << ["REUL Cooling (MBtu)", results[:reul_cool].values.map { |x| x.round(2) }.join(",")]
  results_out << ["REUL Hot Water (MBtu)", results[:reul_dhw].values.map { |x| x.round(2) }.join(",")]
  results_out << ["EC_r Heating (MBtu)", results[:ec_r_heat].values.map { |x| x.round(2) }.join(",")]
  results_out << ["EC_r Cooling (MBtu)", results[:ec_r_cool].values.map { |x| x.round(2) }.join(",")]
  results_out << ["EC_r Hot Water (MBtu)", results[:ec_r_dhw].values.map { |x| x.round(2) }.join(",")]
  results_out << ["EC_x Heating (MBtu)", results[:ec_x_heat].values.map { |x| x.round(2) }.join(",")]
  results_out << ["EC_x Cooling (MBtu)", results[:ec_x_cool].values.map { |x| x.round(2) }.join(",")]
  results_out << ["EC_x Hot Water (MBtu)", results[:ec_x_dhw].values.map { |x| x.round(2) }.join(",")]
  results_out << ["EC_x L&A (MBtu)", results[:eul_la].round(2)]
  if using_iaf
    results_out << ["IAD_Save (%)", results[:iad_save].round(5)]
  end
  # TODO: Heating Fuel, Heating MEPR, Cooling Fuel, Cooling MEPR, Hot Water Fuel, Hot Water MEPR
  CSV.open(results_csv, "wb") { |csv| results_out.to_a.each { |elem| csv << elem } }

  # Worksheet file
  worksheet_csv = File.join(resultsdir, "ERI_Worksheet.csv")
  worksheet_out = []
  worksheet_out << ["Coeff Heating a", results[:coeff_heat_a].values.map { |x| x.round(4) }.join(",")]
  worksheet_out << ["Coeff Heating b", results[:coeff_heat_b].values.map { |x| x.round(4) }.join(",")]
  worksheet_out << ["Coeff Cooling a", results[:coeff_cool_a].values.map { |x| x.round(4) }.join(",")]
  worksheet_out << ["Coeff Cooling b", results[:coeff_cool_b].values.map { |x| x.round(4) }.join(",")]
  worksheet_out << ["Coeff Hot Water a", results[:coeff_dhw_a].values.map { |x| x.round(4) }.join(",")]
  worksheet_out << ["Coeff Hot Water b", results[:coeff_dhw_b].values.map { |x| x.round(4) }.join(",")]
  worksheet_out << ["DSE_r Heating", results[:dse_r_heat].values.map { |x| x.round(4) }.join(",")]
  worksheet_out << ["DSE_r Cooling", results[:dse_r_cool].values.map { |x| x.round(4) }.join(",")]
  worksheet_out << ["DSE_r Hot Water", results[:dse_r_dhw].values.map { |x| x.round(4) }.join(",")]
  worksheet_out << ["EEC_x Heating", results[:eec_x_heat].values.map { |x| x.round(4) }.join(",")]
  worksheet_out << ["EEC_x Cooling", results[:eec_x_cool].values.map { |x| x.round(4) }.join(",")]
  worksheet_out << ["EEC_x Hot Water", results[:eec_x_dhw].values.map { |x| x.round(4) }.join(",")]
  worksheet_out << ["EEC_r Heating", results[:eec_r_heat].values.map { |x| x.round(4) }.join(",")]
  worksheet_out << ["EEC_r Cooling", results[:eec_r_cool].values.map { |x| x.round(4) }.join(",")]
  worksheet_out << ["EEC_r Hot Water", results[:eec_r_dhw].values.map { |x| x.round(4) }.join(",")]
  worksheet_out << ["nEC_x Heating", results[:nec_x_heat].values.map { |x| x.round(4) }.join(",")]
  worksheet_out << ["nEC_x Cooling", results[:nec_x_cool].values.map { |x| x.round(4) }.join(",")]
  worksheet_out << ["nEC_x Hot Water", results[:nec_x_dhw].values.map { |x| x.round(4) }.join(",")]
  worksheet_out << ["nMEUL Heating", results[:nmeul_heat].values.map { |x| x.round(4) }.join(",")]
  worksheet_out << ["nMEUL Cooling", results[:nmeul_cool].values.map { |x| x.round(4) }.join(",")]
  worksheet_out << ["nMEUL Hot Water", results[:nmeul_dhw].values.map { |x| x.round(4) }.join(",")]
  if using_iaf
    worksheet_out << ["IAF CFA", results[:iaf_cfa].round(4)]
    worksheet_out << ["IAF NBR", results[:iaf_nbr].round(4)]
    worksheet_out << ["IAF NS", results[:iaf_ns].round(4)]
    worksheet_out << ["IAF RH", results[:iaf_rh].round(4)]
  end
  worksheet_out << ["Total Loads TnML", results[:tnml].round(4)]
  worksheet_out << ["Total Loads TRL", results[:trl].round(4)]
  if using_iaf
    worksheet_out << ["Total Loads TRL*IAF", (results[:trl] * results[:iaf_rh]).round(4)]
  end
  worksheet_out << ["ERI", results[:eri].round(2)]
  worksheet_out << [nil] # line break
  worksheet_out << ["Ref Home CFA", ref_output[:hpxml_cfa]]
  worksheet_out << ["Ref Home Nbr", ref_output[:hpxml_nbr]]
  if using_iaf
    worksheet_out << ["Ref Home NS", ref_output[:hpxml_nst]]
  end
  worksheet_out << ["Ref L&A resMELs", ref_output[:elecMELs].round(2)]
  worksheet_out << ["Ref L&A intLgt", (ref_output[:elecIntLighting] + ref_output[:elecGrgLighting]).round(2)]
  worksheet_out << ["Ref L&A extLgt", ref_output[:elecExtLighting].round(2)]
  worksheet_out << ["Ref L&A Fridg", ref_output[:elecFridge].round(2)]
  worksheet_out << ["Ref L&A TVs", ref_output[:elecTV].round(2)]
  worksheet_out << ["Ref L&A R/O", (ref_output[:elecRangeOven] + ref_output[:gasRangeOven] + ref_output[:oilRangeOven] + ref_output[:propaneRangeOven]).round(2)]
  worksheet_out << ["Ref L&A cDryer", (ref_output[:elecClothesDryer] + ref_output[:gasClothesDryer] + ref_output[:oilClothesDryer] + ref_output[:propaneClothesDryer]).round(2)]
  worksheet_out << ["Ref L&A dWash", ref_output[:elecDishwasher].round(2)]
  worksheet_out << ["Ref L&A cWash", ref_output[:elecClothesWasher].round(2)]
  worksheet_out << ["Ref L&A mechV", ref_output[:elecMechVent].round(2)]
  worksheet_out << ["Ref L&A total", results[:reul_la].round(2)]
  CSV.open(worksheet_csv, "wb") { |csv| worksheet_out.to_a.each { |elem| csv << elem } }
end

def download_epws
  weather_dir = File.join(File.dirname(__FILE__), "..", "weather")

  require 'net/http'
  require 'tempfile'

  tmpfile = Tempfile.new("epw")

  url = URI.parse("http://s3.amazonaws.com/epwweatherfiles/tmy3s-cache.zip")
  http = Net::HTTP.new(url.host, url.port)

  params = { 'User-Agent' => 'curl/7.43.0', 'Accept-Encoding' => 'identity' }
  request = Net::HTTP::Get.new(url.path, params)
  request.content_type = 'application/zip, application/octet-stream'

  http.request request do |response|
    total = response.header["Content-Length"].to_i
    if total == 0
      fail "Did not successfully download zip file."
    end

    size = 0
    progress = 0
    open tmpfile, 'wb' do |io|
      response.read_body do |chunk|
        io.write chunk
        size += chunk.size
        new_progress = (size * 100) / total
        unless new_progress == progress
          puts "Downloading %s (%3d%%) " % [url.path, new_progress]
        end
        progress = new_progress
      end
    end
  end

  puts "Extracting weather files..."
  unzip_file = OpenStudio::UnzipFile.new(tmpfile.path.to_s)
  unzip_file.extractAllFiles(OpenStudio::toPath(weather_dir))

  num_epws_actual = Dir[File.join(weather_dir, "*.epw")].count
  puts "#{num_epws_actual} weather files are available in the weather directory."
  puts "Completed."
  exit!
end

def cache_weather
  # Process all epw files through weather.rb and serialize objects
  # OpenStudio::Logger.instance.standardOutLogger.setLogLevel(OpenStudio::Fatal)
  weather_dir = File.join(File.dirname(__FILE__), "..", "weather")
  runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)
  puts "Creating *.cache for weather files..."
  Dir["#{weather_dir}/*.epw"].each do |epw|
    next if File.exists? epw.gsub(".epw", ".cache")

    puts "Processing #{epw}..."
    model = OpenStudio::Model::Model.new
    epw_file = OpenStudio::EpwFile.new(epw)
    OpenStudio::Model::WeatherFile.setWeatherFile(model, epw_file).get
    weather = WeatherProcess.new(model, runner)
    if weather.error? or weather.data.WSF.nil?
      fail "Error."
    end

    File.open(epw.gsub(".epw", ".cache"), "wb") do |file|
      Marshal.dump(weather, file)
    end

    # Also add file to data.csv
    weather_data = []
    weather_data << epw_file.wmoNumber            # wmo
    weather_data << epw_file.city                 # station_name
    weather_data << epw_file.stateProvinceRegion  # state
    weather_data << epw_file.latitude             # latitude
    weather_data << epw_file.longitude            # longitude
    weather_data << epw_file.timeZone.to_i        # timezone
    weather_data << epw_file.elevation.to_i       # elevation
    weather_data << "???"                         # class
    weather_data << File.basename(epw)            # filename
    # Write entire file again (rather than just appending new data) to prevent
    # inconsistent line endings.
    csv_data = CSV.read(File.join(weather_dir, "data.csv"))
    csv_data << weather_data
    CSV.open(File.join(weather_dir, "data.csv"), "w") do |csv|
      csv_data.each do |data|
        csv << data
      end
    end
  end
  puts "Completed."
  exit!
end

options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: #{File.basename(__FILE__)} -x building.xml\n e.g., #{File.basename(__FILE__)} -s -x sample_files/base.xml\n"

  opts.on('-x', '--xml <FILE>', 'HPXML file') do |t|
    options[:hpxml] = t
  end

  opts.on('-o', '--output-dir <DIR>', 'Output directory') do |t|
    options[:output_dir] = t
  end

  options[:hourly_output] = false
  opts.on('', '--hourly-output', 'Request hourly output') do |t|
    options[:hourly_output] = true
  end

  opts.on('-w', '--download-weather', 'Downloads all weather files') do |t|
    options[:epws] = t
  end

  opts.on('-c', '--cache-weather', 'Caches all weather files') do |t|
    options[:cache] = t
  end

  options[:debug] = false
  opts.on('-d', '--debug') do |t|
    options[:debug] = true
  end

  options[:skip_validation] = false
  opts.on('-s', '--skip-validation', 'Skips HPXML validation') do |t|
    options[:skip_validation] = true
  end

  options[:version] = false
  opts.on('-v', '--version', 'Reports the workflow version') do |t|
    options[:version] = true
  end

  opts.on_tail('-h', '--help', 'Display help') do
    puts opts
    exit!
  end
end.parse!

# Check for correct versions of OS
os_version = "2.9.0"
if OpenStudio.openStudioVersion != os_version
  fail "OpenStudio version #{os_version} is required."
end

if options[:version]
  workflow_version = "0.6.0"
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
unless File.exists?(options[:hpxml]) and options[:hpxml].downcase.end_with? ".xml"
  fail "'#{options[:hpxml]}' does not exist or is not an .xml file."
end

if options[:output_dir].nil?
  options[:output_dir] = basedir # default
end
options[:output_dir] = File.expand_path(options[:output_dir])

unless Dir.exists?(options[:output_dir])
  FileUtils.mkdir_p(options[:output_dir])
end

# Create results dir
resultsdir = File.join(options[:output_dir], "results")
rm_path(resultsdir)
Dir.mkdir(resultsdir)

# Run w/ Addendum E House Size Index Adjustment Factor?
using_iaf = false
File.open(options[:hpxml], 'r').each do |line|
  if line.strip.downcase.start_with? "<version>"
    if line.include? '2014AE' or line.include? '2014AEG'
      using_iaf = true
    end
    break
  end
end

run_designs = {
  Constants.CalcTypeERIRatedHome => true,
  Constants.CalcTypeERIReferenceHome => true,
  Constants.CalcTypeERIIndexAdjustmentDesign => using_iaf,
  Constants.CalcTypeERIIndexAdjustmentReferenceHome => using_iaf
}

# Run simulations
puts "HPXML: #{options[:hpxml]}"
design_outputs = {}
if Process.respond_to?(:fork) # e.g., most Unix systems

  # Code runs in forked child processes and makes direct calls. This is the fastest
  # approach but isn't available on, e.g., Windows.

  # Setup IO.pipe to communicate output from child processes to this parent process
  readers, writers = {}, {}
  run_designs.keys.each do |design|
    readers[design], writers[design] = IO.pipe
  end

  def kill
    raise Parallel::Kill
  end

  Parallel.map(run_designs, in_processes: run_designs.size) do |design, run|
    next if not run

    output_hpxml_path, designdir = run_design_direct(basedir, options[:output_dir], design, resultsdir, options[:hpxml], options[:debug], options[:skip_validation], options[:hourly_output])
    kill unless File.exists? File.join(designdir, "eplusout.end")

    design_output = process_design_output(design, designdir, resultsdir, output_hpxml_path, options[:hourly_output])
    kill if design_output.nil?

    writers[design].puts(Marshal.dump(design_output)) # Provide output data to parent process
  end

  # Retrieve output data from child processes
  readers.each do |design, reader|
    writers[design].close
    next if not run_designs[design]

    begin
      design_outputs[design] = Marshal.load(reader.read)
    rescue
      # nop
    end
  end

else # e.g., Windows

  # Fallback. Code runs in spawned child processes in order to take advantage of
  # multiple processors.

  def kill(pids)
    pids.values.each do |pid|
      begin
        Process.kill("KILL", pid)
      rescue
      end
    end
  end

  pids = {}
  killing_process = false
  Parallel.map(run_designs, in_threads: run_designs.size) do |design, run|
    next if not run

    output_hpxml_path, designdir, pids[design] = run_design_spawn(basedir, options[:output_dir], design, resultsdir, options[:hpxml], options[:debug], options[:skip_validation], options[:hourly_output])
    Process.wait pids[design]
    if not File.exists? File.join(designdir, "eplusout.end")
      kill(pids)
      next
    end

    design_output = process_design_output(design, designdir, resultsdir, output_hpxml_path, options[:hourly_output])
    if design_output.nil?
      kill(pids)
      next
    end

    design_outputs[design] = design_output
  end

end

# Exit now if any designs that should have been run have no output.
run_designs.each do |design, run|
  next unless run and design_outputs[design].nil?

  puts "Errors encountered. Aborting..."
  exit!
end

# Calculate and write results
puts "Calculating ERI..."
if using_iaf
  results_iad = calculate_eri(design_outputs[Constants.CalcTypeERIIndexAdjustmentDesign],
                              design_outputs[Constants.CalcTypeERIIndexAdjustmentReferenceHome])
else
  results_iad = nil
end
results = calculate_eri(design_outputs[Constants.CalcTypeERIRatedHome],
                        design_outputs[Constants.CalcTypeERIReferenceHome],
                        results_iad)

write_results(results, resultsdir, design_outputs, using_iaf)

puts "ERI: #{results[:eri].round(2)}"
puts "Output files written to '#{File.basename(resultsdir)}' directory."
puts "Completed in #{(Time.now - start_time).round(1)} seconds."
