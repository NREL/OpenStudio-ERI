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

# TODO: Add error-checking
# TODO: Add standardized reporting of errors

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

def run_design_direct(basedir, output_dir, design, resultsdir, hpxml, debug, skip_validation, run)
  # Calls design.rb methods directly. Should only be called from a forked
  # process. This is the fastest approach.
  designdir = get_designdir(output_dir, design)
  rm_path(designdir)

  if run
    output_hpxml_path = run_design(basedir, output_dir, design, resultsdir, hpxml, debug, skip_validation)
  end

  return output_hpxml_path, designdir
end

def run_design_spawn(basedir, output_dir, design, resultsdir, hpxml, debug, skip_validation, run)
  # Calls design.rb in a new spawned process in order to utilize multiple
  # processes. Not as efficient as calling design.rb methods directly in
  # forked processes for a couple reasons:
  # 1. There is overhead to using the CLI
  # 2. There is overhead to spawning processes vs using forked processes
  designdir = get_designdir(output_dir, design)
  rm_path(designdir)

  if run
    cli_path = OpenStudio.getOpenStudioCLI
    system("\"#{cli_path}\" --no-ssl \"#{File.join(File.dirname(__FILE__), "design.rb")}\" \"#{basedir}\" \"#{output_dir}\" \"#{design}\" \"#{resultsdir}\" \"#{hpxml}\" #{debug} #{skip_validation}")
  end

  output_hpxml_path = get_output_hpxml_path(resultsdir, designdir)
  return output_hpxml_path, designdir
end

def process_design_output(design, designdir, resultsdir, output_hpxml_path)
  return nil if output_hpxml_path.nil?

  print "[#{design}] Processing output...\n"

  design_output = read_output(design, designdir, output_hpxml_path)
  return if design_output.nil?

  write_results_annual_output(resultsdir, design, design_output)

  print "[#{design}] Done.\n"

  return design_output
end

def get_sql_query_result(sqlFile, query)
  result = sqlFile.execAndReturnFirstDouble(query)
  if result.is_initialized
    return result.get * 0.9478171203133172 # GJ => MBtu
  end

  return 0
end

def get_sql_result(sqlValue, design)
  if sqlValue.is_initialized
    return sqlValue.get * 0.9478171203133172 # GJ => MBtu
  end

  fail "Could not find sql result."
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
  water_sys_frac = (hx_load) / htg_load
  return htg_energy * water_sys_frac
end

def read_output(design, designdir, output_hpxml_path)
  sql_path = File.join(designdir, "eplusout.sql")
  if not File.exists?(sql_path)
    puts "[#{design}] Processing output unsuccessful."
    return nil
  end

  sqlFile = OpenStudio::SqlFile.new(sql_path, false)

  design_output = {}

  # HPXML
  design_output[:hpxml] = output_hpxml_path
  hpxml_doc = REXML::Document.new(File.read(design_output[:hpxml]))
  design_output[:hpxml_cfa] = get_cfa(hpxml_doc)
  design_output[:hpxml_nbr] = get_nbr(hpxml_doc)
  design_output[:hpxml_nst] = get_nst(hpxml_doc)
  if [Constants.CalcTypeERIReferenceHome, Constants.CalcTypeERIIndexAdjustmentReferenceHome].include? design
    design_output[:hpxml_dse_heats] = get_dse_heats(hpxml_doc, design)
    design_output[:hpxml_dse_cools] = get_dse_cools(hpxml_doc, design)
  end
  design_output[:hpxml_heat_fuels] = get_heat_fuels(hpxml_doc, design)
  design_output[:hpxml_dwh_fuels] = get_dhw_fuels(hpxml_doc)
  design_output[:hpxml_eec_heats] = get_eec_heats(hpxml_doc, design)
  design_output[:hpxml_eec_cools] = get_eec_cools(hpxml_doc, design)
  design_output[:hpxml_eec_dhws] = get_eec_dhws(hpxml_doc)
  design_output[:hpxml_heat_sys_ids] = design_output[:hpxml_eec_heats].keys
  design_output[:hpxml_cool_sys_ids] = design_output[:hpxml_eec_cools].keys
  design_output[:hpxml_dhw_sys_ids] = design_output[:hpxml_eec_dhws].keys

  # Total site energy
  design_output[:allTotal] = get_sql_result(sqlFile.totalSiteEnergy, design)

  # Electricity categories
  design_output[:elecTotal] = get_sql_result(sqlFile.electricityTotalEndUses, design)
  design_output[:elecIntLighting] = get_sql_result(sqlFile.electricityInteriorLighting, design)
  design_output[:elecExtLighting] = get_sql_result(sqlFile.electricityExteriorLighting, design)
  design_output[:elecAppliances] = get_sql_result(sqlFile.electricityInteriorEquipment, design)

  # Fuel categories
  design_output[:fuelTotal] = get_sql_result(sqlFile.naturalGasTotalEndUses, design) + get_sql_result(sqlFile.otherFuelTotalEndUses, design)
  design_output[:fuelAppliances] = get_sql_result(sqlFile.naturalGasInteriorEquipment, design) + get_sql_result(sqlFile.otherFuelInteriorEquipment, design)

  # Space Heating (by System)
  map_tsv_data = CSV.read(File.join(designdir, "map_hvac.tsv"), headers: false, col_sep: "\t")
  design_output[:elecHeatingBySystem] = {}
  design_output[:fuelHeatingBySystem] = {}
  design_output[:loadHeatingBySystem] = {}
  design_output[:hpxml_heat_sys_ids].each do |sys_id|
    ep_output_names = get_ep_output_names_for_hvac_heating(map_tsv_data, sys_id, hpxml_doc, design)
    keys = "'" + ep_output_names.map(&:upcase).join("','") + "'"
    # Electricity Use
    vars = "'" + get_all_var_keys(OutputVars.SpaceHeatingElectricity).join("','") + "'"
    query = "SELECT SUM(ABS(VariableValue)/1000000000) FROM ReportVariableData WHERE ReportVariableDataDictionaryIndex IN (SELECT ReportVariableDataDictionaryIndex FROM ReportVariableDataDictionary WHERE VariableType='Sum' AND KeyValue IN (#{keys}) AND VariableName IN (#{vars}) AND ReportingFrequency='Run Period' AND VariableUnits='J')"
    design_output[:elecHeatingBySystem][sys_id] = get_sql_query_result(sqlFile, query)
    # Fuel Use
    vars = "'" + get_all_var_keys(OutputVars.SpaceHeatingFuel).join("','") + "'"
    query = "SELECT SUM(ABS(VariableValue)/1000000000) FROM ReportVariableData WHERE ReportVariableDataDictionaryIndex IN (SELECT ReportVariableDataDictionaryIndex FROM ReportVariableDataDictionary WHERE VariableType='Sum' AND KeyValue IN (#{keys}) AND VariableName IN (#{vars}) AND ReportingFrequency='Run Period' AND VariableUnits='J')"
    design_output[:fuelHeatingBySystem][sys_id] = get_sql_query_result(sqlFile, query)
    # Disaggregated Fan Energy Use
    ems_keys = "'" + ep_output_names.select { |name| name.include? "Heating" }.join("','") + "'"
    query = "SELECT SUM(ABS(VariableValue)/1000000000) FROM ReportVariableData WHERE ReportVariableDataDictionaryIndex IN (SELECT ReportVariableDataDictionaryIndex FROM ReportVariableDataDictionary WHERE VariableType='Sum' AND KeyValue='EMS' AND VariableName IN (#{ems_keys}) AND ReportingFrequency='Run Period' AND VariableUnits='J')"
    fan_pump_output = get_sql_query_result(sqlFile, query)
    design_output[:elecHeatingBySystem][sys_id] += fan_pump_output
    # Reference Load
    if [Constants.CalcTypeERIReferenceHome, Constants.CalcTypeERIIndexAdjustmentReferenceHome].include? design
      # Only ever gas furnace, gas boiler, or electric ASHP (autosized)
      vars = "'" + get_all_var_keys(OutputVars.SpaceHeatingLoad).join("','") + "'"
      query = "SELECT SUM(ABS(VariableValue)/1000000000) FROM ReportVariableData WHERE ReportVariableDataDictionaryIndex IN (SELECT ReportVariableDataDictionaryIndex FROM ReportVariableDataDictionary WHERE VariableType='Sum' AND KeyValue IN (#{keys}) AND VariableName IN (#{vars}) AND ReportingFrequency='Run Period' AND VariableUnits='J')"
      design_output[:loadHeatingBySystem][sys_id] = get_sql_query_result(sqlFile, query)
      design_output[:loadHeatingBySystem][sys_id] += fan_pump_output
      design_output[:loadHeatingBySystem][sys_id] *= design_output[:hpxml_dse_heats][sys_id] # Remove effect of DSE on load
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
    design_output[:elecCoolingBySystem][sys_id] = get_sql_query_result(sqlFile, query)
    # Disaggregated Fan Energy Use
    ems_keys = "'" + ep_output_names.select { |name| name.include? "Cooling" }.join("','") + "'"
    query = "SELECT SUM(ABS(VariableValue)/1000000000) FROM ReportVariableData WHERE ReportVariableDataDictionaryIndex IN (SELECT ReportVariableDataDictionaryIndex FROM ReportVariableDataDictionary WHERE VariableType='Sum' AND KeyValue='EMS' AND VariableName IN (#{ems_keys}) AND ReportingFrequency='Run Period' AND VariableUnits='J')"
    fan_pump_output = get_sql_query_result(sqlFile, query)
    design_output[:elecCoolingBySystem][sys_id] += fan_pump_output
    # Reference Load
    if [Constants.CalcTypeERIReferenceHome, Constants.CalcTypeERIIndexAdjustmentReferenceHome].include? design
      # Only ever central air conditioner (autosized)
      vars = "'" + get_all_var_keys(OutputVars.SpaceCoolingLoad).join("','") + "'"
      query = "SELECT SUM(ABS(VariableValue)/1000000000) FROM ReportVariableData WHERE ReportVariableDataDictionaryIndex IN (SELECT ReportVariableDataDictionaryIndex FROM ReportVariableDataDictionary WHERE VariableType='Sum' AND KeyValue IN (#{keys}) AND VariableName IN (#{vars}) AND ReportingFrequency='Run Period' AND VariableUnits='J')"
      design_output[:loadCoolingBySystem][sys_id] = get_sql_query_result(sqlFile, query)
      design_output[:loadCoolingBySystem][sys_id] -= fan_pump_output
      design_output[:loadCoolingBySystem][sys_id] *= design_output[:hpxml_dse_cools][sys_id] # Remove effect of DSE on load
    end
  end

  # Water Heating (by System)
  map_tsv_data = CSV.read(File.join(designdir, "map_water_heating.tsv"), headers: false, col_sep: "\t")
  design_output[:elecHotWaterBySystem] = {}
  design_output[:fuelHotWaterBySystem] = {}
  design_output[:loadHotWaterBySystem] = {}
  design_output[:hpxml_dhw_sys_ids].each do |sys_id|
    ep_output_names = get_ep_output_names_for_water_heating(map_tsv_data, sys_id, hpxml_doc, design)
    keys = "'" + ep_output_names.map(&:upcase).join("','") + "'"
    # Electricity Use
    vars = "'" + get_all_var_keys(OutputVars.WaterHeatingElectricity).join("','") + "'"
    query = "SELECT SUM(ABS(VariableValue)/1000000000) FROM ReportVariableData WHERE ReportVariableDataDictionaryIndex IN (SELECT ReportVariableDataDictionaryIndex FROM ReportVariableDataDictionary WHERE VariableType='Sum' AND KeyValue IN (#{keys}) AND VariableName IN (#{vars}) AND ReportingFrequency='Run Period' AND VariableUnits='J')"
    design_output[:elecHotWaterBySystem][sys_id] = get_sql_query_result(sqlFile, query)
    # Electricity Use - Recirc Pump
    vars = "'" + get_all_var_keys(OutputVars.WaterHeatingElectricityRecircPump).join("','") + "'"
    query = "SELECT SUM(ABS(VariableValue)/1000000000) FROM ReportVariableData WHERE ReportVariableDataDictionaryIndex IN (SELECT ReportVariableDataDictionaryIndex FROM ReportVariableDataDictionary WHERE VariableType='Sum' AND KeyValue IN (#{keys}) AND VariableName IN (#{vars}) AND ReportingFrequency='Run Period' AND VariableUnits='J')"
    design_output[:elecHotWaterBySystem][sys_id] += get_sql_query_result(sqlFile, query)
    design_output[:elecAppliances] -= get_sql_query_result(sqlFile, query)
    # Fuel use
    vars = "'" + get_all_var_keys(OutputVars.WaterHeatingFuel).join("','") + "'"
    query = "SELECT SUM(ABS(VariableValue)/1000000000) FROM ReportVariableData WHERE ReportVariableDataDictionaryIndex IN (SELECT ReportVariableDataDictionaryIndex FROM ReportVariableDataDictionary WHERE VariableType='Sum' AND KeyValue IN (#{keys}) AND VariableName IN (#{vars}) AND ReportingFrequency='Run Period' AND VariableUnits='J')"
    design_output[:fuelHotWaterBySystem][sys_id] = get_sql_query_result(sqlFile, query)
    # Reference Load
    if [Constants.CalcTypeERIReferenceHome, Constants.CalcTypeERIIndexAdjustmentReferenceHome].include? design
      # Only ever conventional storage tank water heater
      vars = "'" + get_all_var_keys(OutputVars.WaterHeatingLoad).join("','") + "'"
      query = "SELECT SUM(ABS(VariableValue)/1000000000) FROM ReportVariableData WHERE ReportVariableDataDictionaryIndex IN (SELECT ReportVariableDataDictionaryIndex FROM ReportVariableDataDictionary WHERE VariableType='Sum' AND KeyValue IN (#{keys}) AND VariableName IN (#{vars}) AND ReportingFrequency='Run Period' AND VariableUnits='J')"
      design_output[:loadHotWaterBySystem][sys_id] = get_sql_query_result(sqlFile, query)
    end
    # Combi boiler water system
    hvac_id = get_combi_hvac_id(hpxml_doc, sys_id)
    if not hvac_id.nil?
      vars = "'" + get_all_var_keys(OutputVars.WaterHeatingCombiBoilerHeatExchanger).join("','") + "'"
      query = "SELECT SUM(ABS(VariableValue)/1000000000) FROM ReportVariableData WHERE ReportVariableDataDictionaryIndex IN (SELECT ReportVariableDataDictionaryIndex FROM ReportVariableDataDictionary WHERE VariableType='Sum' AND KeyValue IN (#{keys}) AND VariableName IN (#{vars}) AND ReportingFrequency='Run Period' AND VariableUnits='J')"
      hx_load = get_sql_query_result(sqlFile, query)
      vars = "'" + get_all_var_keys(OutputVars.WaterHeatingCombiBoiler).join("','") + "'"
      query = "SELECT SUM(ABS(VariableValue)/1000000000) FROM ReportVariableData WHERE ReportVariableDataDictionaryIndex IN (SELECT ReportVariableDataDictionaryIndex FROM ReportVariableDataDictionary WHERE VariableType='Sum' AND  KeyValue IN (#{keys}) AND VariableName IN (#{vars}) AND ReportingFrequency='Run Period' AND VariableUnits='J')"
      htg_load = get_sql_query_result(sqlFile, query)

      # Split combi boiler system energy use by water system load fraction
      htg_ec_elec = design_output[:elecHeatingBySystem][hvac_id]
      design_output[:elecHotWaterBySystem][sys_id] += get_combi_water_system_ec(hx_load, htg_load, htg_ec_elec) unless htg_ec_elec.nil?
      design_output[:elecHeatingBySystem][hvac_id] -= get_combi_water_system_ec(hx_load, htg_load, htg_ec_elec) unless htg_ec_elec.nil?
      htg_ec_fuel = design_output[:fuelHeatingBySystem][hvac_id]
      design_output[:fuelHotWaterBySystem][sys_id] += get_combi_water_system_ec(hx_load, htg_load, htg_ec_fuel) unless htg_ec_fuel.nil?
      design_output[:fuelHeatingBySystem][hvac_id] -= get_combi_water_system_ec(hx_load, htg_load, htg_ec_fuel) unless htg_ec_fuel.nil?
    end
  end

  # PV
  query = "SELECT Value FROM TabularDataWithStrings WHERE ReportName='AnnualBuildingUtilityPerformanceSummary' AND ReportForString='Entire Facility' AND TableName='Electric Loads Satisfied' AND RowName='Total On-Site Electric Sources' AND ColumnName='Electricity' AND Units='GJ'"
  design_output[:elecPV] = get_sql_query_result(sqlFile, query)

  # Fridge
  query = "SELECT Value FROM TabularDataWithStrings WHERE ReportName='EnergyMeters' AND ReportForString='Entire Facility' AND TableName='Annual and Peak Values - Electricity' AND RowName LIKE '#{Constants.ObjectNameRefrigerator}%' AND ColumnName='Electricity Annual Value' AND Units='GJ'"
  design_output[:elecFridge] = get_sql_query_result(sqlFile, query)

  # Dishwasher
  query = "SELECT Value FROM TabularDataWithStrings WHERE ReportName='EnergyMeters' AND ReportForString='Entire Facility' AND TableName='Annual and Peak Values - Electricity' AND RowName LIKE '#{Constants.ObjectNameDishwasher}%' AND ColumnName='Electricity Annual Value' AND Units='GJ'"
  design_output[:elecDishwasher] = get_sql_query_result(sqlFile, query)

  # Clothes Washer
  query = "SELECT Value FROM TabularDataWithStrings WHERE ReportName='EnergyMeters' AND ReportForString='Entire Facility' AND TableName='Annual and Peak Values - Electricity' AND RowName LIKE '#{Constants.ObjectNameClothesWasher}%' AND ColumnName='Electricity Annual Value' AND Units='GJ'"
  design_output[:elecClothesWasher] = get_sql_query_result(sqlFile, query)

  # Clothes Dryer
  query = "SELECT Value FROM TabularDataWithStrings WHERE ReportName='EnergyMeters' AND ReportForString='Entire Facility' AND TableName='Annual and Peak Values - Electricity' AND RowName LIKE '#{Constants.ObjectNameClothesDryer}%' AND ColumnName='Electricity Annual Value' AND Units='GJ'"
  design_output[:elecClothesDryer] = get_sql_query_result(sqlFile, query)
  query = "SELECT Value FROM TabularDataWithStrings WHERE ReportName='EnergyMeters' AND ReportForString='Entire Facility' AND TableName='Annual and Peak Values - Gas' AND RowName LIKE '#{Constants.ObjectNameClothesDryer}%' AND ColumnName='Gas Annual Value' AND Units='GJ'"
  design_output[:fuelClothesDryer] = get_sql_query_result(sqlFile, query)
  query = "SELECT Value FROM TabularDataWithStrings WHERE ReportName='EnergyMeters' AND ReportForString='Entire Facility' AND TableName='Annual and Peak Values - Other' AND RowName LIKE '#{Constants.ObjectNameClothesDryer}%' AND ColumnName='Annual Value' AND Units='GJ'"
  design_output[:fuelClothesDryer] += get_sql_query_result(sqlFile, query)

  # MELS
  query = "SELECT Value FROM TabularDataWithStrings WHERE ReportName='EnergyMeters' AND ReportForString='Entire Facility' AND TableName='Annual and Peak Values - Electricity' AND RowName LIKE '#{Constants.ObjectNameMiscPlugLoads}%' AND ColumnName='Electricity Annual Value' AND Units='GJ'"
  design_output[:elecMELs] = get_sql_query_result(sqlFile, query)
  query = "SELECT Value FROM TabularDataWithStrings WHERE ReportName='EnergyMeters' AND ReportForString='Entire Facility' AND TableName='Annual and Peak Values - Electricity' AND RowName LIKE '#{Constants.ObjectNameMiscTelevision}%' AND ColumnName='Electricity Annual Value' AND Units='GJ'"
  design_output[:elecTV] = get_sql_query_result(sqlFile, query)

  # Range/Oven
  query = "SELECT Value FROM TabularDataWithStrings WHERE ReportName='EnergyMeters' AND ReportForString='Entire Facility' AND TableName='Annual and Peak Values - Electricity' AND RowName LIKE '#{Constants.ObjectNameCookingRange}%' AND ColumnName='Electricity Annual Value' AND Units='GJ'"
  design_output[:elecRangeOven] = get_sql_query_result(sqlFile, query)
  query = "SELECT Value FROM TabularDataWithStrings WHERE ReportName='EnergyMeters' AND ReportForString='Entire Facility' AND TableName='Annual and Peak Values - Gas' AND RowName LIKE '#{Constants.ObjectNameCookingRange}%' AND ColumnName='Gas Annual Value' AND Units='GJ'"
  design_output[:fuelRangeOven] = get_sql_query_result(sqlFile, query)
  query = "SELECT Value FROM TabularDataWithStrings WHERE ReportName='EnergyMeters' AND ReportForString='Entire Facility' AND TableName='Annual and Peak Values - Other' AND RowName LIKE '#{Constants.ObjectNameCookingRange}%' AND ColumnName='Annual Value' AND Units='GJ'"
  design_output[:fuelRangeOven] += get_sql_query_result(sqlFile, query)

  # Ceiling Fans
  query = "SELECT Value FROM TabularDataWithStrings WHERE ReportName='EnergyMeters' AND ReportForString='Entire Facility' AND TableName='Annual and Peak Values - Electricity' AND RowName LIKE '#{Constants.ObjectNameCeilingFan}%' AND ColumnName='Electricity Annual Value' AND Units='GJ'"
  design_output[:elecCeilingFan] = get_sql_query_result(sqlFile, query)

  # Mechanical Ventilation
  query = "SELECT SUM(Value) FROM TabularDataWithStrings WHERE ReportName='EnergyMeters' AND ReportForString='Entire Facility' AND TableName='Annual and Peak Values - Electricity' AND RowName LIKE '#{Constants.ObjectNameMechanicalVentilation}%' AND ColumnName='Electricity Annual Value' AND Units='GJ'"
  design_output[:elecMechVent] = get_sql_query_result(sqlFile, query)

  # Error Checking
  tolerance = 0.1 # MMBtu

  sum_fuels = (design_output[:elecTotal] + design_output[:fuelTotal])
  if (design_output[:allTotal] - sum_fuels).abs > tolerance
    fail "[#{design}] Fuels (#{sum_fuels.round(1)} do not sum to total (#{design_output[:allTotal].round(1)}))."
  end

  sum_elec_categories = (design_output[:elecHeatingBySystem].values.inject(0, :+) +
                         design_output[:elecCoolingBySystem].values.inject(0, :+) +
                         design_output[:elecHotWaterBySystem].values.inject(0, :+) +
                         design_output[:elecIntLighting] +
                         design_output[:elecExtLighting] +
                         design_output[:elecAppliances])
  if (design_output[:elecTotal] - sum_elec_categories).abs > tolerance
    fail "[#{design}] Electric category end uses (#{sum_elec_categories}) do not sum to total (#{design_output[:elecTotal]}).\n#{design_output.to_s}"
  end

  sum_fuel_categories = (design_output[:fuelHeatingBySystem].values.inject(0, :+) +
                         design_output[:fuelHotWaterBySystem].values.inject(0, :+) +
                         design_output[:fuelAppliances])
  if (design_output[:fuelTotal] - sum_fuel_categories).abs > tolerance
    fail "[#{design}] Fuel category end uses (#{sum_fuel_categories}) do not sum to total (#{design_output[:fuelTotal]}).\n#{design_output.to_s}"
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

  sum_fuel_appliances = (design_output[:fuelClothesDryer] + design_output[:fuelRangeOven])
  if (design_output[:fuelAppliances] - sum_fuel_appliances).abs > tolerance
    fail "[#{design}] Fuel appliances (#{sum_fuel_appliances}) do not sum to total (#{design_output[:fuelAppliances]}).\n#{design_output.to_s}"
  end

  return design_output
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
    dse_heat = Float(XMLHelper.get_value(hvac_dist, "AnnualHeatingDistributionSystemEfficiency"))
    # Get all HVAC systems attached to it
    hpxml_doc.elements.each("/HPXML/Building/BuildingDetails/Systems/HVAC/HVACPlant/HeatingSystem[FractionHeatLoadServed > 0]") do |htg_system|
      next unless dist_id == htg_system.elements["DistributionSystem"].attributes["idref"]

      sys_id = get_system_or_seed_id(htg_system, design)
      dse_heats[sys_id] = dse_heat
    end
    hpxml_doc.elements.each("/HPXML/Building/BuildingDetails/Systems/HVAC/HVACPlant/HeatPump[FractionHeatLoadServed > 0]") do |heat_pump|
      next unless dist_id == heat_pump.elements["DistributionSystem"].attributes["idref"]

      sys_id = get_system_or_seed_id(heat_pump, design)
      dse_heats[sys_id] = dse_heat
    end
  end

  if dse_heats.empty?
    fail "No heating distribution systems found."
  end

  return dse_heats
end

def get_dse_cools(hpxml_doc, design)
  dse_cools = {}

  hpxml_doc.elements.each("/HPXML/Building/BuildingDetails/Systems/HVAC/HVACDistribution") do |hvac_dist|
    dist_id = hvac_dist.elements["SystemIdentifier"].attributes["id"]
    dse_cool = Float(XMLHelper.get_value(hvac_dist, "AnnualCoolingDistributionSystemEfficiency"))
    # Get all HVAC systems attached to it
    hpxml_doc.elements.each("/HPXML/Building/BuildingDetails/Systems/HVAC/HVACPlant/CoolingSystem[FractionCoolLoadServed > 0]") do |clg_system|
      next unless dist_id == clg_system.elements["DistributionSystem"].attributes["idref"]

      sys_id = get_system_or_seed_id(clg_system, design)
      dse_cools[sys_id] = dse_cool
    end
    hpxml_doc.elements.each("/HPXML/Building/BuildingDetails/Systems/HVAC/HVACPlant/HeatPump[FractionCoolLoadServed > 0]") do |heat_pump|
      next unless dist_id == heat_pump.elements["DistributionSystem"].attributes["idref"]

      sys_id = get_system_or_seed_id(heat_pump, design)
      dse_cools[sys_id] = dse_cool
    end
  end

  if dse_cools.empty?
    fail "No cooling distribution systems found."
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
        dummy_u, ua, dummy_eta = Waterheater.calc_tank_UA(vol, assumed_fuel, assumed_ef, nil, nil, Constants.WaterHeaterTypeTank, 0.0, jacket_r)
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

    ec_x_heat = rated_output[:elecHeatingBySystem][s] + rated_output[:fuelHeatingBySystem][s]
    ec_r_heat = ref_output[:elecHeatingBySystem][s] + ref_output[:fuelHeatingBySystem][s]

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

    ec_x_dhw = rated_output[:elecHotWaterBySystem][s] + rated_output[:fuelHotWaterBySystem][s]
    ec_r_dhw = ref_output[:elecHotWaterBySystem][s] + ref_output[:fuelHotWaterBySystem][s]

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

  results[:teu] = rated_output[:elecTotal] + 0.4 * rated_output[:fuelTotal]
  results[:opp] = rated_output[:elecPV]

  results[:pefrac] = 1.0
  if results[:teu] > 0
    results[:pefrac] = (results[:teu] - results[:opp]) / results[:teu]
  end

  results[:eul_la] = (rated_output[:elecIntLighting] + rated_output[:elecExtLighting] +
                      rated_output[:elecAppliances] + rated_output[:fuelAppliances])

  results[:reul_la] = (ref_output[:elecIntLighting] + ref_output[:elecExtLighting] +
                       ref_output[:elecAppliances] + ref_output[:fuelAppliances])

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

def write_results_annual_output(resultsdir, design, design_output)
  out_csv = File.join(resultsdir, "#{design.gsub(' ', '')}.csv")

  results_out = {}
  results_out["Electricity: Total (MBtu)"] = design_output[:elecTotal]
  results_out["Electricity: Net (MBtu)"] = design_output[:elecTotal] - design_output[:elecPV]
  results_out["Natural Gas: Total (MBtu)"] = design_output[:fuelTotal]
  results_out[""] = "" # line break
  results_out["Electricity: Heating (MBtu)"] = design_output[:elecHeatingBySystem].values.inject(0, :+)
  results_out["Electricity: Cooling (MBtu)"] = design_output[:elecCoolingBySystem].values.inject(0, :+)
  results_out["Electricity: Hot Water (MBtu)"] = design_output[:elecHotWaterBySystem].values.inject(0, :+)
  results_out["Electricity: Lighting (MBtu)"] = design_output[:elecIntLighting] + design_output[:elecExtLighting]
  results_out["Electricity: Mech Vent (MBtu)"] = design_output[:elecMechVent]
  results_out["Electricity: Refrigerator (MBtu)"] = design_output[:elecFridge]
  results_out["Electricity: Dishwasher (MBtu)"] = design_output[:elecDishwasher]
  results_out["Electricity: Clothes Washer (MBtu)"] = design_output[:elecClothesWasher]
  results_out["Electricity: Clothes Dryer (MBtu)"] = design_output[:elecClothesDryer]
  results_out["Electricity: Range/Oven (MBtu)"] = design_output[:elecRangeOven]
  results_out["Electricity: Ceiling Fan (MBtu)"] = design_output[:elecCeilingFan]
  results_out["Electricity: Plug Loads (MBtu)"] = design_output[:elecMELs] + design_output[:elecTV]
  results_out["Electricity: PV (MBtu)"] = design_output[:elecPV]
  results_out["Fuel: Heating (MBtu)"] = design_output[:fuelHeatingBySystem].values.inject(0, :+)
  results_out["Fuel: Hot Water (MBtu)"] = design_output[:fuelHotWaterBySystem].values.inject(0, :+)
  results_out["Fuel: Clothes Dryer (MBtu)"] = design_output[:fuelClothesDryer]
  results_out["Fuel: Range/Oven (MBtu)"] = design_output[:fuelRangeOven]
  CSV.open(out_csv, "wb") { |csv| results_out.to_a.each { |elem| csv << elem } }
end

def write_results(results, resultsdir, design_outputs, using_iaf)
  ref_output = design_outputs[Constants.CalcTypeERIReferenceHome]

  # Results file
  results_csv = File.join(resultsdir, "ERI_Results.csv")
  results_out = {}
  results_out["ERI"] = results[:eri].round(2)
  results_out["REUL Heating (MBtu)"] = results[:reul_heat].values.map { |x| x.round(2) }.join(",")
  results_out["REUL Cooling (MBtu)"] = results[:reul_cool].values.map { |x| x.round(2) }.join(",")
  results_out["REUL Hot Water (MBtu)"] = results[:reul_dhw].values.map { |x| x.round(2) }.join(",")
  results_out["EC_r Heating (MBtu)"] = results[:ec_r_heat].values.map { |x| x.round(2) }.join(",")
  results_out["EC_r Cooling (MBtu)"] = results[:ec_r_cool].values.map { |x| x.round(2) }.join(",")
  results_out["EC_r Hot Water (MBtu)"] = results[:ec_r_dhw].values.map { |x| x.round(2) }.join(",")
  results_out["EC_x Heating (MBtu)"] = results[:ec_x_heat].values.map { |x| x.round(2) }.join(",")
  results_out["EC_x Cooling (MBtu)"] = results[:ec_x_cool].values.map { |x| x.round(2) }.join(",")
  results_out["EC_x Hot Water (MBtu)"] = results[:ec_x_dhw].values.map { |x| x.round(2) }.join(",")
  results_out["EC_x L&A (MBtu)"] = results[:eul_la].round(2)
  if using_iaf
    results_out["IAD_Save (%)"] = results[:iad_save].round(5)
  end
  # TODO: Heating Fuel, Heating MEPR, Cooling Fuel, Cooling MEPR, Hot Water Fuel, Hot Water MEPR
  CSV.open(results_csv, "wb") { |csv| results_out.to_a.each { |elem| csv << elem } }

  # Worksheet file
  worksheet_csv = File.join(resultsdir, "ERI_Worksheet.csv")
  worksheet_out = {}
  worksheet_out["Coeff Heating a"] = results[:coeff_heat_a].values.map { |x| x.round(4) }.join(",")
  worksheet_out["Coeff Heating b"] = results[:coeff_heat_b].values.map { |x| x.round(4) }.join(",")
  worksheet_out["Coeff Cooling a"] = results[:coeff_cool_a].values.map { |x| x.round(4) }.join(",")
  worksheet_out["Coeff Cooling b"] = results[:coeff_cool_b].values.map { |x| x.round(4) }.join(",")
  worksheet_out["Coeff Hot Water a"] = results[:coeff_dhw_a].values.map { |x| x.round(4) }.join(",")
  worksheet_out["Coeff Hot Water b"] = results[:coeff_dhw_b].values.map { |x| x.round(4) }.join(",")
  worksheet_out["DSE_r Heating"] = results[:dse_r_heat].values.map { |x| x.round(4) }.join(",")
  worksheet_out["DSE_r Cooling"] = results[:dse_r_cool].values.map { |x| x.round(4) }.join(",")
  worksheet_out["DSE_r Hot Water"] = results[:dse_r_dhw].values.map { |x| x.round(4) }.join(",")
  worksheet_out["EEC_x Heating"] = results[:eec_x_heat].values.map { |x| x.round(4) }.join(",")
  worksheet_out["EEC_x Cooling"] = results[:eec_x_cool].values.map { |x| x.round(4) }.join(",")
  worksheet_out["EEC_x Hot Water"] = results[:eec_x_dhw].values.map { |x| x.round(4) }.join(",")
  worksheet_out["EEC_r Heating"] = results[:eec_r_heat].values.map { |x| x.round(4) }.join(",")
  worksheet_out["EEC_r Cooling"] = results[:eec_r_cool].values.map { |x| x.round(4) }.join(",")
  worksheet_out["EEC_r Hot Water"] = results[:eec_r_dhw].values.map { |x| x.round(4) }.join(",")
  worksheet_out["nEC_x Heating"] = results[:nec_x_heat].values.map { |x| x.round(4) }.join(",")
  worksheet_out["nEC_x Cooling"] = results[:nec_x_cool].values.map { |x| x.round(4) }.join(",")
  worksheet_out["nEC_x Hot Water"] = results[:nec_x_dhw].values.map { |x| x.round(4) }.join(",")
  worksheet_out["nMEUL Heating"] = results[:nmeul_heat].values.map { |x| x.round(4) }.join(",")
  worksheet_out["nMEUL Cooling"] = results[:nmeul_cool].values.map { |x| x.round(4) }.join(",")
  worksheet_out["nMEUL Hot Water"] = results[:nmeul_dhw].values.map { |x| x.round(4) }.join(",")
  if using_iaf
    worksheet_out["IAF CFA"] = results[:iaf_cfa].round(4)
    worksheet_out["IAF NBR"] = results[:iaf_nbr].round(4)
    worksheet_out["IAF NS"] = results[:iaf_ns].round(4)
    worksheet_out["IAF RH"] = results[:iaf_rh].round(4)
  end
  worksheet_out["Total Loads TnML"] = results[:tnml].round(4)
  worksheet_out["Total Loads TRL"] = results[:trl].round(4)
  if using_iaf
    worksheet_out["Total Loads TRL*IAF"] = (results[:trl] * results[:iaf_rh]).round(4)
  end
  worksheet_out["ERI"] = results[:eri].round(2)
  worksheet_out[""] = "" # line break
  worksheet_out["Ref Home CFA"] = ref_output[:hpxml_cfa]
  worksheet_out["Ref Home Nbr"] = ref_output[:hpxml_nbr]
  if using_iaf
    worksheet_out["Ref Home NS"] = ref_output[:hpxml_nst]
  end
  worksheet_out["Ref L&A resMELs"] = ref_output[:elecMELs].round(2)
  worksheet_out["Ref L&A intLgt"] = ref_output[:elecIntLighting].round(2)
  worksheet_out["Ref L&A extLgt"] = ref_output[:elecExtLighting].round(2)
  worksheet_out["Ref L&A Fridg"] = ref_output[:elecFridge].round(2)
  worksheet_out["Ref L&A TVs"] = ref_output[:elecTV].round(2)
  worksheet_out["Ref L&A R/O"] = (ref_output[:elecRangeOven] + ref_output[:fuelRangeOven]).round(2)
  worksheet_out["Ref L&A cDryer"] = (ref_output[:elecClothesDryer] + ref_output[:fuelClothesDryer]).round(2)
  worksheet_out["Ref L&A dWash"] = ref_output[:elecDishwasher].round(2)
  worksheet_out["Ref L&A cWash"] = ref_output[:elecClothesWasher].round(2)
  worksheet_out["Ref L&A mechV"] = ref_output[:elecMechVent].round(2)
  worksheet_out["Ref L&A total"] = results[:reul_la].round(2)
  CSV.open(worksheet_csv, "wb") { |csv| worksheet_out.to_a.each { |elem| csv << elem } }
end

def download_epws
  weather_dir = File.join(File.dirname(__FILE__), "..", "weather")

  num_epws_expected = File.readlines(File.join(weather_dir, "data.csv")).size - 1
  num_epws_actual = Dir[File.join(weather_dir, "*.epw")].count
  num_cache_expcted = num_epws_expected
  num_cache_actual = Dir[File.join(weather_dir, "*.cache")].count
  if num_epws_actual == num_epws_expected and num_cache_actual == num_cache_expcted
    puts "Weather directory is already up-to-date."
    puts "#{num_epws_actual} weather files are available in the weather directory."
    puts "Completed."
    exit!
  end

  require 'net/http'
  require 'tempfile'

  tmpfile = Tempfile.new("epw")

  url = URI.parse("http://s3.amazonaws.com/epwweatherfiles/openstudio-eri-tmy3s-cache.zip")
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

options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: #{File.basename(__FILE__)} -x building.xml\n e.g., #{File.basename(__FILE__)} -s -x sample_files/base.xml\n"

  opts.on('-x', '--xml <FILE>', 'HPXML file') do |t|
    options[:hpxml] = t
  end

  opts.on('-o', '--output-dir <DIR>', 'Output directory') do |t|
    options[:output_dir] = t
  end

  opts.on('-w', '--download-weather', 'Downloads all weather files') do |t|
    options[:epws] = t
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
os_version = "2.8.1"
if OpenStudio.openStudioVersion != os_version
  fail "OpenStudio version #{os_version} is required."
end

if options[:version]
  workflow_version = "0.2.0"
  puts "OpenStudio-ERI v#{workflow_version}"
  puts "OpenStudio v#{OpenStudio.openStudioLongVersion}"
  puts "EnergyPlus v#{OpenStudio.energyPlusVersion}.#{OpenStudio.energyPlusBuildSHA}"
  exit!
end

if options[:epws]
  download_epws
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

# Run w/ Index Adjustment Factor (IAF) designs?
using_iaf = true
File.open(options[:hpxml], 'r').each do |line|
  line.strip!
  if line.start_with? "<Version>"
    if line == "<Version>2014</Version>" or line == "<Version>2014A</Version>" # 2014 w/o Addendum E
      using_iaf = false
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

  Parallel.map(run_designs, in_processes: run_designs.size) do |design, run|
    output_hpxml_path, designdir = run_design_direct(basedir, options[:output_dir], design, resultsdir, options[:hpxml], options[:debug], options[:skip_validation], run)
    next unless File.exists? File.join(designdir, "in.idf")

    design_output = process_design_output(design, designdir, resultsdir, output_hpxml_path)
    next if design_output.nil?

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

  Parallel.map(run_designs, in_threads: run_designs.size) do |design, run|
    output_hpxml_path, designdir = run_design_spawn(basedir, options[:output_dir], design, resultsdir, options[:hpxml], options[:debug], options[:skip_validation], run)
    next unless File.exists? File.join(designdir, "in.idf")

    design_output = process_design_output(design, designdir, resultsdir, output_hpxml_path)
    next if design_output.nil?

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
