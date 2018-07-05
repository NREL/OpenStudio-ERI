start_time = Time.now

require 'optparse'
require 'csv'
require 'pathname'
require 'fileutils'
require 'parallel'
require_relative "design"
require_relative "../measures/301EnergyRatingIndexRuleset/resources/constants"
require_relative "../measures/301EnergyRatingIndexRuleset/resources/xmlhelper"

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

def run_design_direct(basedir, design, resultsdir, hpxml, debug, run)
  # Calls design.rb methods directly. Should only be called from a forked 
  # process. This is the fastest approach.
  designdir = get_designdir(basedir, design)
  rm_path(designdir)

  return nil if not run
  
  output_hpxml_path = run_design(basedir, design, resultsdir, hpxml, debug)
  return output_hpxml_path, designdir
end

def run_design_spawn(basedir, design, resultsdir, hpxml, debug, run)
  # Calls design.rb in a new spawned process in order to utilize multiple 
  # processes. Not as efficient as calling design.rb methods directly in 
  # forked processes for a couple reasons:
  # 1. There is overhead to using the CLI
  # 2. There is overhead to spawning processes vs using forked processes
  designdir = get_designdir(basedir, design)
  rm_path(designdir)

  return nil if not run
  
  cli_path = OpenStudio.getOpenStudioCLI
  system("\"#{cli_path}\" --no-ssl design.rb \"#{basedir}\" \"#{design}\" \"#{resultsdir}\" \"#{hpxml}\" #{debug}")
  
  output_hpxml_path = get_output_hpxml_path(resultsdir, designdir)
  return output_hpxml_path, designdir
end

def process_design_output(design, designdir, resultsdir, output_hpxml_path)
  return nil if output_hpxml_path.nil?
  
  print "[#{design}] Processing output...\n"
  design_output = read_output(design, designdir, output_hpxml_path)
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
  fail "ERROR: Simulation unsuccessful for #{design}."
end

def read_output(design, designdir, output_hpxml_path)
  sql_path = File.join(designdir, "run", "eplusout.sql")
  if not File.exists?(sql_path)
    fail "ERROR: Simulation unsuccessful for #{design}."
  end
  
  sqlFile = OpenStudio::SqlFile.new(sql_path, false)
  
  design_output = {}
  
  # HPXML
  design_output[:hpxml] = output_hpxml_path
  hpxml_doc = REXML::Document.new(File.read(design_output[:hpxml]))
  design_output[:hpxml_cfa] = get_cfa(hpxml_doc)
  design_output[:hpxml_nbr] = get_nbr(hpxml_doc)
  design_output[:hpxml_nst] = get_nst(hpxml_doc)
  if design == Constants.CalcTypeERIReferenceHome
    design_output[:hpxml_dse_heat], design_output[:hpxml_dse_cool] = get_dse_heat_cool(hpxml_doc)
  end
  design_output[:hpxml_heat_fuel] = get_heating_fuel(hpxml_doc)
  design_output[:hpxml_dwh_fuel] = get_dhw_fuel(hpxml_doc)
  design_output[:hpxml_eec_heat] = get_eec_heat(hpxml_doc)
  design_output[:hpxml_eec_cool] = get_eec_cool(hpxml_doc)
  design_output[:hpxml_eec_dhw] = get_eec_dhw(hpxml_doc)
  
  # Total site energy
  design_output[:allTotal] = get_sql_result(sqlFile.totalSiteEnergy, design)
  
  # Electricity categories
  design_output[:elecTotal] = get_sql_result(sqlFile.electricityTotalEndUses, design)
  design_output[:elecHeating] = get_sql_result(sqlFile.electricityHeating, design)
  design_output[:elecCooling] = get_sql_result(sqlFile.electricityCooling, design)
  design_output[:elecIntLighting] = get_sql_result(sqlFile.electricityInteriorLighting, design)
  design_output[:elecExtLighting] = get_sql_result(sqlFile.electricityExteriorLighting, design)
  design_output[:elecAppliances] = get_sql_result(sqlFile.electricityInteriorEquipment, design)
  design_output[:elecFans] = get_sql_result(sqlFile.electricityFans, design)
  design_output[:elecPumps] = get_sql_result(sqlFile.electricityPumps, design)
  design_output[:elecHotWater] = get_sql_result(sqlFile.electricityWaterSystems, design)
  
  # Fuel categories
  design_output[:ngTotal] = get_sql_result(sqlFile.naturalGasTotalEndUses, design)
  design_output[:ngHeating] = get_sql_result(sqlFile.naturalGasHeating, design)
  design_output[:ngAppliances] = get_sql_result(sqlFile.naturalGasInteriorEquipment, design)
  design_output[:ngHotWater] = get_sql_result(sqlFile.naturalGasWaterSystems, design)
  design_output[:otherTotal] = get_sql_result(sqlFile.otherFuelTotalEndUses, design)
  design_output[:otherHeating] = get_sql_result(sqlFile.otherFuelHeating, design)
  design_output[:otherAppliances] = get_sql_result(sqlFile.otherFuelInteriorEquipment, design)
  design_output[:otherHotWater] = get_sql_result(sqlFile.otherFuelWaterSystems, design)
  design_output[:fuelTotal] = design_output[:ngTotal] + design_output[:otherTotal]
  design_output[:fuelHeating] = design_output[:ngHeating] + design_output[:otherHeating]
  design_output[:fuelAppliances] = design_output[:ngAppliances] + design_output[:otherAppliances]
  design_output[:fuelHotWater] = design_output[:ngHotWater] + design_output[:otherHotWater]

  # Other - PV
  query = "SELECT Value FROM TabularDataWithStrings WHERE ReportName='AnnualBuildingUtilityPerformanceSummary' AND ReportForString='Entire Facility' AND TableName='Electric Loads Satisfied' AND RowName='Total On-Site Electric Sources' AND ColumnName='Electricity' AND Units='GJ'"
  design_output[:elecPV] = get_sql_query_result(sqlFile, query)
  
  # Other - Fridge
  query = "SELECT Value FROM TabularDataWithStrings WHERE ReportName='EnergyMeters' AND ReportForString='Entire Facility' AND TableName='Annual and Peak Values - Electricity' AND RowName LIKE '#{Constants.ObjectNameRefrigerator}%' AND ColumnName='Electricity Annual Value' AND Units='GJ'"
  design_output[:elecFridge] = get_sql_query_result(sqlFile, query)
  
  # Other - Dishwasher
  query = "SELECT Value FROM TabularDataWithStrings WHERE ReportName='EnergyMeters' AND ReportForString='Entire Facility' AND TableName='Annual and Peak Values - Electricity' AND RowName LIKE '#{Constants.ObjectNameDishwasher}%' AND ColumnName='Electricity Annual Value' AND Units='GJ'"
  design_output[:elecDishwasher] = get_sql_query_result(sqlFile, query)
  
  # Other - Clothes Washer
  query = "SELECT Value FROM TabularDataWithStrings WHERE ReportName='EnergyMeters' AND ReportForString='Entire Facility' AND TableName='Annual and Peak Values - Electricity' AND RowName LIKE '#{Constants.ObjectNameClothesWasher}%' AND ColumnName='Electricity Annual Value' AND Units='GJ'"
  design_output[:elecClothesWasher] = get_sql_query_result(sqlFile, query)
  
  # Other - Clothes Dryer
  query = "SELECT Value FROM TabularDataWithStrings WHERE ReportName='EnergyMeters' AND ReportForString='Entire Facility' AND TableName='Annual and Peak Values - Electricity' AND RowName LIKE '#{Constants.ObjectNameClothesDryer(nil)}%' AND ColumnName='Electricity Annual Value' AND Units='GJ'"
  design_output[:elecClothesDryer] = get_sql_query_result(sqlFile, query)
  query = "SELECT Value FROM TabularDataWithStrings WHERE ReportName='EnergyMeters' AND ReportForString='Entire Facility' AND TableName='Annual and Peak Values - Gas' AND RowName LIKE '#{Constants.ObjectNameClothesDryer(nil)}%' AND ColumnName='Gas Annual Value' AND Units='GJ'"
  design_output[:ngClothesDryer] = get_sql_query_result(sqlFile, query)
  query = "SELECT Value FROM TabularDataWithStrings WHERE ReportName='EnergyMeters' AND ReportForString='Entire Facility' AND TableName='Annual and Peak Values - Other' AND RowName LIKE '#{Constants.ObjectNameClothesDryer(nil)}%' AND ColumnName='Annual Value' AND Units='GJ'"
  design_output[:otherClothesDryer] = get_sql_query_result(sqlFile, query)
  design_output[:fuelClothesDryer] = design_output[:ngClothesDryer] + design_output[:otherClothesDryer]
  
  # Other - MELS
  query = "SELECT Value FROM TabularDataWithStrings WHERE ReportName='EnergyMeters' AND ReportForString='Entire Facility' AND TableName='Annual and Peak Values - Electricity' AND RowName LIKE '#{Constants.ObjectNameMiscPlugLoads}%' AND ColumnName='Electricity Annual Value' AND Units='GJ'"
  design_output[:elecMELs] = get_sql_query_result(sqlFile, query)
  query = "SELECT Value FROM TabularDataWithStrings WHERE ReportName='EnergyMeters' AND ReportForString='Entire Facility' AND TableName='Annual and Peak Values - Electricity' AND RowName LIKE '#{Constants.ObjectNameMiscTelevision}%' AND ColumnName='Electricity Annual Value' AND Units='GJ'"
  design_output[:elecTV] = get_sql_query_result(sqlFile, query)
  
  # Other - Range/Oven
  query = "SELECT Value FROM TabularDataWithStrings WHERE ReportName='EnergyMeters' AND ReportForString='Entire Facility' AND TableName='Annual and Peak Values - Electricity' AND RowName LIKE '#{Constants.ObjectNameCookingRange(nil)}%' AND ColumnName='Electricity Annual Value' AND Units='GJ'"
  design_output[:elecRangeOven] = get_sql_query_result(sqlFile, query)
  query = "SELECT Value FROM TabularDataWithStrings WHERE ReportName='EnergyMeters' AND ReportForString='Entire Facility' AND TableName='Annual and Peak Values - Gas' AND RowName LIKE '#{Constants.ObjectNameCookingRange(nil)}%' AND ColumnName='Gas Annual Value' AND Units='GJ'"
  design_output[:ngRangeOven] = get_sql_query_result(sqlFile, query)
  query = "SELECT Value FROM TabularDataWithStrings WHERE ReportName='EnergyMeters' AND ReportForString='Entire Facility' AND TableName='Annual and Peak Values - Other' AND RowName LIKE '#{Constants.ObjectNameCookingRange(nil)}%' AND ColumnName='Annual Value' AND Units='GJ'"
  design_output[:otherRangeOven] = get_sql_query_result(sqlFile, query)
  design_output[:fuelRangeOven] = design_output[:ngRangeOven] + design_output[:otherRangeOven]
  
  # Other - Ceiling Fans
  query = "SELECT Value FROM TabularDataWithStrings WHERE ReportName='EnergyMeters' AND ReportForString='Entire Facility' AND TableName='Annual and Peak Values - Electricity' AND RowName LIKE '#{Constants.ObjectNameCeilingFan}%' AND ColumnName='Electricity Annual Value' AND Units='GJ'"
  design_output[:elecCeilingFan] = get_sql_query_result(sqlFile, query)
  
  # Other - Mechanical Ventilation
  query = "SELECT Value FROM TabularDataWithStrings WHERE ReportName='EnergyMeters' AND ReportForString='Entire Facility' AND TableName='Annual and Peak Values - Electricity' AND RowName LIKE '#{Constants.EndUseMechVentFan}%' AND ColumnName='Electricity Annual Value' AND Units='GJ'"
  design_output[:elecMechVent] = get_sql_query_result(sqlFile, query)
  
  # Other - Recirculation pump
  query = "SELECT Value FROM TabularDataWithStrings WHERE ReportName='EnergyMeters' AND ReportForString='Entire Facility' AND TableName='Annual and Peak Values - Electricity' AND RowName LIKE '#{Constants.ObjectNameHotWaterRecircPump}%' AND ColumnName='Electricity Annual Value' AND Units='GJ'"
  design_output[:elecRecircPump] = get_sql_query_result(sqlFile, query)
  design_output[:elecAppliances] -= design_output[:elecRecircPump]
  
  # Other - Space Heating Load
  vars = "'" + Constants.LoadVarsSpaceHeating.join("','") + "'"
  query = "SELECT SUM(ABS(VariableValue)/1000000000) FROM ReportVariableData WHERE ReportVariableDataDictionaryIndex IN (SELECT ReportVariableDataDictionaryIndex FROM ReportVariableDataDictionary WHERE VariableType='Sum' AND IndexGroup='System' AND TimestepType='Zone' AND VariableName IN (#{vars}) AND ReportingFrequency='Run Period' AND VariableUnits='J')"
  design_output[:loadHeating] = get_sql_query_result(sqlFile, query)
  
  # Other - Space Cooling Load
  vars = "'" + Constants.LoadVarsSpaceCooling.join("','") + "'"
  query = "SELECT SUM(ABS(VariableValue)/1000000000) FROM ReportVariableData WHERE ReportVariableDataDictionaryIndex IN (SELECT ReportVariableDataDictionaryIndex FROM ReportVariableDataDictionary WHERE VariableType='Sum' AND IndexGroup='System' AND TimestepType='Zone' AND VariableName IN (#{vars}) AND ReportingFrequency='Run Period' AND VariableUnits='J')"
  design_output[:loadCooling] = get_sql_query_result(sqlFile, query)
  
  # Other - Water Heating Load
  vars = "'" + Constants.LoadVarsWaterHeating.join("','") + "'"
  query = "SELECT SUM(ABS(VariableValue)/1000000000) FROM ReportVariableData WHERE ReportVariableDataDictionaryIndex IN (SELECT ReportVariableDataDictionaryIndex FROM ReportVariableDataDictionary WHERE VariableType='Sum' AND IndexGroup='System' AND TimestepType='Zone' AND VariableName IN (#{vars}) AND ReportingFrequency='Run Period' AND VariableUnits='J')"
  design_output[:loadHotWater] = get_sql_query_result(sqlFile, query)
  
  # Error Checking
  tolerance = 0.1 # MMBtu
  
  sum_fuels = (design_output[:elecTotal] + design_output[:fuelTotal])
  if (design_output[:allTotal] - sum_fuels).abs > tolerance
    fail "ERROR: Fuels do not sum to total (#{sum_fuels.round(1)} vs #{design_output[:allTotal].round(1)})."
  end
  
  sum_elec_categories = (design_output[:elecHeating] + design_output[:elecCooling] + 
                         design_output[:elecIntLighting] + design_output[:elecExtLighting] + 
                         design_output[:elecAppliances] + design_output[:elecFans] + 
                         design_output[:elecPumps] + design_output[:elecHotWater] + 
                         design_output[:elecRecircPump])
  if (design_output[:elecTotal] - sum_elec_categories).abs > tolerance
    fail "ERROR: Electric category end uses do not sum to total.\n#{design_output.to_s}"
  end
  
  sum_fuel_categories = (design_output[:fuelHeating] + design_output[:fuelAppliances] + 
                         design_output[:fuelHotWater])
  if (design_output[:fuelTotal] - sum_fuel_categories).abs > tolerance
    fail "ERROR: Fuel category end uses do not sum to total.\n#{design_output.to_s}"
  end
  
  sum_elec_appliances = (design_output[:elecFridge] + design_output[:elecDishwasher] +
                     design_output[:elecClothesWasher] + design_output[:elecClothesDryer] +
                     design_output[:elecMELs] + design_output[:elecTV] + 
                     design_output[:elecRangeOven] + design_output[:elecCeilingFan] + 
                     design_output[:elecMechVent])
  if (design_output[:elecAppliances] - sum_elec_appliances).abs > tolerance
    fail "ERROR: Electric appliances do not sum to total.\n#{design_output.to_s}"
  end
  
  sum_fuel_appliances = (design_output[:fuelClothesDryer] + design_output[:fuelRangeOven])
  if (design_output[:fuelAppliances] - sum_fuel_appliances).abs > tolerance
    fail "ERROR: Fuel appliances do not sum to total.\n#{design_output.to_s}"
  end
  
  return design_output
  
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

def get_heating_fuel(hpxml_doc)
  heat_fuels = []
  
  hpxml_doc.elements.each("/HPXML/Building/BuildingDetails/Systems/HVAC/HVACPlant/HeatingSystem") do |htg_system|
    heat_fuels << XMLHelper.get_value(htg_system, "HeatingSystemFuel")
  end
  hpxml_doc.elements.each("/HPXML/Building/BuildingDetails/Systems/HVAC/HVACPlant/HeatPump") do |heat_pump|
    heat_fuels << "electricity"
  end
  
  heat_fuels.uniq!
  
  if heat_fuels.size == 0
    fail "ERROR: No heating system fuel type found."
  elsif heat_fuels.size > 1
    fail "ERROR: Multiple heating system fuel types found."
  end

  return heat_fuels[0]
end

def get_dhw_fuel(hpxml_doc)
  dhw_fuels = []
  
  hpxml_doc.elements.each("/HPXML/Building/BuildingDetails/Systems/WaterHeating/WaterHeatingSystem") do |dhw_system|
    dhw_fuels << XMLHelper.get_value(dhw_system, "FuelType")
  end
  
  dhw_fuels.uniq!
  
  if dhw_fuels.size == 0
    fail "ERROR: No water heating system fuel type found."
  elsif dhw_fuels.size > 1
    fail "ERROR: Multiple water heating system fuel types found."
  end
  
  return dhw_fuels[0]
end

def get_dse_heat_cool(hpxml_doc)
  
  dse_heats = []
  dse_cools = []
  
  hpxml_doc.elements.each("/HPXML/Building/BuildingDetails/Systems/HVAC/HVACDistribution") do |hvac_dist|
    dse_heats << Float(XMLHelper.get_value(hvac_dist, "AnnualHeatingDistributionSystemEfficiency"))
    dse_cools << Float(XMLHelper.get_value(hvac_dist, "AnnualCoolingDistributionSystemEfficiency"))
  end
  
  dse_heats.uniq!
  dse_cools.uniq!
  
  if dse_heats.size == 0
    fail "ERROR: No heating distribution system efficiency value found."
  elsif dse_cools.size == 0
    fail "ERROR: No cooling distribution system efficiency value found."
  elsif dse_heats.size > 1
    fail "ERROR: Multiple heating distribution system efficiency values found."
  elsif dse_cools.size > 1
    fail "ERROR: Multiple cooling distribution system efficiency values found."
  end
  
  return dse_heats[0], dse_cools[0]
  
end

def get_eec_value_numerator(unit)
  if ['HSPF','SEER','EER'].include? unit
    return 3.413
  elsif ['AFUE','COP','Percent','EF'].include? unit
    return 1.0
  end
  fail "ERROR: Unexpected unit #{unit}."
end

def get_eec_heat(hpxml_doc)
  eec_heats = []
  
  units = ['HSPF','COP','AFUE','Percent']
  
  hpxml_doc.elements.each("/HPXML/Building/BuildingDetails/Systems/HVAC/HVACPlant/HeatingSystem") do |htg_system|
    units.each do |unit|
      value = XMLHelper.get_value(htg_system, "AnnualHeatingEfficiency[Units='#{unit}']/Value")
      next if value.nil?
      eec_heats << get_eec_value_numerator(unit) / Float(value)
    end
  end
  hpxml_doc.elements.each("/HPXML/Building/BuildingDetails/Systems/HVAC/HVACPlant/HeatPump") do |heat_pump|
    units.each do |unit|
      value = XMLHelper.get_value(heat_pump, "AnnualHeatEfficiency[Units='#{unit}']/Value")
      next if value.nil?
      eec_heats << get_eec_value_numerator(unit) / Float(value)
    end
  end
  
  eec_heats.uniq!
  
  if eec_heats.size == 0
    fail "ERROR: No heating system efficiency value found."
  elsif eec_heats.size > 1
    fail "ERROR: Multiple heating system efficiency values found."
  end

  return eec_heats[0]
end

def get_eec_cool(hpxml_doc)
  eec_cools = []
  
  units = ['SEER','COP','EER']
  
  hpxml_doc.elements.each("/HPXML/Building/BuildingDetails/Systems/HVAC/HVACPlant/CoolingSystem") do |clg_system|
    units.each do |unit|
      value = XMLHelper.get_value(clg_system, "AnnualCoolingEfficiency[Units='#{unit}']/Value")
      next if value.nil?
      eec_cools << get_eec_value_numerator(unit) / Float(value)
    end
  end
  hpxml_doc.elements.each("/HPXML/Building/BuildingDetails/Systems/HVAC/HVACPlant/HeatPump") do |heat_pump|
    units.each do |unit|
      value = XMLHelper.get_value(heat_pump, "AnnualCoolEfficiency[Units='#{unit}']/Value")
      next if value.nil?
      eec_cools << get_eec_value_numerator(unit) / Float(value)
    end
  end
  
  eec_cools.uniq!
  
  if eec_cools.size == 0
    fail "ERROR: No cooling system efficiency value found."
  elsif eec_cools.size > 1
    fail "ERROR: Multiple cooling system efficiency values found."
  end

  return eec_cools[0]
end

def get_eec_dhw(hpxml_doc)
  eec_dhws = []
  
  hpxml_doc.elements.each("/HPXML/Building/BuildingDetails/Systems/WaterHeating/WaterHeatingSystem") do |dhw_system|
    value = XMLHelper.get_value(dhw_system, "EnergyFactor")
    value_adj = XMLHelper.get_value(dhw_system, "extension/PerformanceAdjustmentEnergyFactor")
    if not value.nil? and not value_adj.nil?
      eec_dhws << get_eec_value_numerator('EF') / (Float(value) * Float(value_adj))
    end
  end
  
  eec_dhws.uniq!
  
  if eec_dhws.size == 0
    fail "ERROR: No water heating system efficiency value found."
  elsif eec_dhws.size > 1
    fail "ERROR: Multiple water heating system efficiency values found."
  end
  
  return eec_dhws[0]
end

def calculate_eri(rated_output, ref_output, results_iad=nil)

  results = {}
  
  # REUL = Reference Home End Use Loads (for heating, cooling or hot water) as computed using an Approved 
  # Software Rating Tool.
  # Heating/Cooling loads include effect of DSE, so we remove the effect below.
  results[:reul_heat] = ref_output[:loadHeating] * ref_output[:hpxml_dse_heat]
  results[:reul_cool] = ref_output[:loadCooling] * ref_output[:hpxml_dse_cool]
  results[:reul_dhw] = ref_output[:loadHotWater]
  
  # XEUL = Rated Home End Use Loads (for heating, cooling or hot water) as computed using an Approved 
  # Software Rating Tool.
  results[:xeul_heat] = 0 # TODO
  results[:xeul_cool] = 0 # TODO
  results[:xeul_dhw] = 0 # TODO
  
  # Table 4.2.1(1) Coefficients ‘a’ and ‘b’
  results[:coeff_cool_a] = 3.8090
  results[:coeff_cool_b] = 0.0
  results[:coeff_heat_a] = nil
  results[:coeff_heat_b] = nil
  results[:coeff_dhw_a] = nil
  results[:coeff_dhw_b] = nil
  if rated_output[:hpxml_heat_fuel] == 'electricity'
    results[:coeff_heat_a] = 2.2561
    results[:coeff_heat_b] = 0.0
  elsif ['natural gas','fuel oil','propane'].include? rated_output[:hpxml_heat_fuel]
    results[:coeff_heat_a] = 1.0943
    results[:coeff_heat_b] = 0.4030
  end
  if rated_output[:hpxml_dwh_fuel] == 'electricity'
    results[:coeff_dhw_a] = 0.9200
    results[:coeff_dhw_b] = 0.0
  elsif ['natural gas','fuel oil','propane'].include? rated_output[:hpxml_dwh_fuel]
    results[:coeff_dhw_a] = 1.1877
    results[:coeff_dhw_b] = 1.0130
  end
  if results[:coeff_heat_a].nil? or results[:coeff_heat_b].nil?
    fail "ERROR: Could not identify EEC coefficients for heating system."
  end
  if results[:coeff_dhw_a].nil? or results[:coeff_dhw_b].nil?
    fail "ERROR: Could not identify EEC coefficients for water heating system."
  end
  
  # EEC_x = Equipment Efficiency Coefficient for the Rated Home’s equipment, such that EEC_x equals the 
  # energy consumption per unit load in like units as the load, and as derived from the Manufacturer’s 
  # Equipment Performance Rating (MEPR) such that EEC_x equals 1.0 / MEPR for AFUE, COP or EF ratings, or 
  # such that EEC_x equals 3.413 / MEPR for HSPF, EER or SEER ratings.
  results[:eec_x_heat] = rated_output[:hpxml_eec_heat]
  results[:eec_x_cool] = rated_output[:hpxml_eec_cool]
  results[:eec_x_dhw] = rated_output[:hpxml_eec_dhw]
  
  # EEC_r = Equipment Efficiency Coefficient for the Reference Home’s equipment, such that EEC_r equals the 
  # energy consumption per unit load in like units as the load, and as derived from the Manufacturer’s 
  # Equipment Performance Rating (MEPR) such that EEC_r equals 1.0 / MEPR for AFUE, COP or EF ratings, or 
  # such that EEC_r equals 3.413 / MEPR for HSPF, EER or SEER ratings
  results[:eec_r_heat] = ref_output[:hpxml_eec_heat]
  results[:eec_r_cool] = ref_output[:hpxml_eec_cool]
  results[:eec_r_dhw] = ref_output[:hpxml_eec_dhw]
  
  # EC_x = estimated Energy Consumption for the Rated Home’s end uses (for heating, including Auxiliary 
  # Electric Consumption, cooling or hot water) as computed using an Approved Software Rating Tool.
  results[:ec_x_heat] = rated_output[:elecHeating] + rated_output[:fuelHeating]
  results[:ec_x_cool] = rated_output[:elecCooling]
  results[:ec_x_dhw] = rated_output[:elecHotWater] + rated_output[:fuelHotWater] + rated_output[:elecRecircPump]
  
  # EC_r = estimated Energy Consumption for the Reference Home’s end uses (for heating, including Auxiliary 
  # Electric Consumption, cooling or hot water) as computed using an Approved Software Rating Tool.
  results[:ec_r_heat] = ref_output[:elecHeating] + ref_output[:fuelHeating]
  results[:ec_r_cool] = ref_output[:elecCooling]
  results[:ec_r_dhw] = ref_output[:elecHotWater] + ref_output[:fuelHotWater]
  
  # DSE_r = REUL/EC_r * EEC_r
  # For simplified system performance methods, DSE_r equals 0.80 for heating and cooling systems and 1.00 
  # for hot water systems [see Table 4.2.2(1)]. However, for detailed modeling of heating and cooling systems,
  # DSE_r may be less than 0.80 as a result of part load performance degradation, coil air flow degradation, 
  # improper system charge and auxiliary resistance heating for heat pumps. Except as otherwise provided by 
  # these Standards, where detailed systems modeling is employed, it must be applied equally to both the 
  # Reference and the Rated Homes.
  results[:dse_r_heat] = results[:reul_heat] / results[:ec_r_heat] * results[:eec_r_heat]
  results[:dse_r_cool] = results[:reul_cool] / results[:ec_r_cool] * results[:eec_r_cool]
  results[:dse_r_dhw] = results[:reul_dhw] / results[:ec_r_dhw] * results[:eec_r_dhw]
  
  # nEC_x = (a* EEC_x – b)*(EC_x * EC_r * DSE_r) / (EEC_x * REUL) (Eq 4.1-1a)
  results[:nec_x_heat] = 0
  results[:nec_x_cool] = 0
  results[:nec_x_dhw] = 0
  if results[:eec_x_heat] * results[:reul_heat] > 0
    results[:nec_x_heat] = (results[:coeff_heat_a] * results[:eec_x_heat] - results[:coeff_heat_b])*(results[:ec_x_heat] * results[:ec_r_heat] * results[:dse_r_heat]) / (results[:eec_x_heat] * results[:reul_heat])
  end
  if results[:eec_x_cool] * results[:reul_cool] > 0
    results[:nec_x_cool] = (results[:coeff_cool_a] * results[:eec_x_cool] - results[:coeff_cool_b])*(results[:ec_x_cool] * results[:ec_r_cool] * results[:dse_r_cool]) / (results[:eec_x_cool] * results[:reul_cool])
  end
  if results[:eec_x_dhw] * results[:reul_dhw] > 0
    results[:nec_x_dhw] = (results[:coeff_dhw_a] * results[:eec_x_dhw] - results[:coeff_dhw_b])*(results[:ec_x_dhw] * results[:ec_r_dhw] * results[:dse_r_dhw]) / (results[:eec_x_dhw] * results[:reul_dhw])
  end
  
  # The normalized Modified End Use Loads (nMEUL) for space heating and cooling and domestic hot water use 
  # shall each be determined in accordance with Equation 4.1-1:
  # nMEUL = REUL * (nEC_x / EC_r) (Eq 4.1-1)
  results[:nmeul_heat] = 0
  results[:nmeul_cool] = 0
  results[:nmeul_dhw] = 0
  if results[:ec_r_heat] > 0
    results[:nmeul_heat] = results[:reul_heat] * (results[:nec_x_heat] / results[:ec_r_heat])
  end
  if results[:ec_r_cool] > 0
    results[:nmeul_cool] = results[:reul_cool] * (results[:nec_x_cool] / results[:ec_r_cool])
  end
  if results[:ec_r_dhw] > 0
    results[:nmeul_dhw] = results[:reul_dhw] * (results[:nec_x_dhw] / results[:ec_r_dhw])
  end
      
  # TEU = Total energy use of the Rated Home including all rated and non-rated energy features where all 
  # fossil fuel site energy uses (Btufossil) are converted to equivalent electric energy use (kWheq) in 
  # accordance with Equation 4.1-3.
  # kWheq = (Btufossil * 0.40) / 3412 (Eq 4.1-3)
  results[:teu] = rated_output[:elecTotal] + 0.4 * rated_output[:fuelTotal]
  
  # OPP = On-Site Power Production as defined by Section 5.1.1.4 of this Standard.
  results[:opp] = rated_output[:elecPV]
  
  # PEfrac = (TEU - OPP) / TEU
  results[:pefrac] = 1.0
  if results[:teu] > 0
    results[:pefrac] = (results[:teu] - results[:opp]) / results[:teu]
  end
  
  # EULLA = The Rated Home end use loads for lighting, appliances and MELs as defined by Section 4.2.2.5.2, 
  # converted to MBtu/y, where MBtu/y = (kWh/y)/293 or (therms/y)/10, as appropriate.
  results[:eul_la] = (rated_output[:elecIntLighting] + rated_output[:elecExtLighting] + 
                      rated_output[:elecAppliances] + rated_output[:fuelAppliances])
  
  # REULLA = The Reference Home end use loads for lighting, appliances and MELs as defined by Section 4.2.2.5.1, 
  # converted to MBtu/y, where MBtu/y = (kWh/y)/293 or (therms/y)/10, as appropriate.
  results[:reul_la] = (ref_output[:elecIntLighting] + ref_output[:elecExtLighting] + 
                       ref_output[:elecAppliances] + ref_output[:fuelAppliances])
  
  # TRL = REULHEAT + REULCOOL + REULHW + REULLA (MBtu/y).
  results[:trl] = results[:reul_heat] + results[:reul_cool] + results[:reul_dhw] + results[:reul_la]

  # TnML = nMEULHEAT + nMEULCOOL + nMEULHW + EULLA (MBtu/y).  
  results[:tnml] = results[:nmeul_heat] + results[:nmeul_cool] + results[:nmeul_dhw] + results[:eul_la]
  
  if not results_iad.nil?
  
    # ANSI/RESNET/ICC 301-2014 Addendum E-2018 House Size Index Adjustment Factors (IAF)
    
    # 4.3.3 The saving represented by the IAD shall be calculated using equation 4.3.3-1.
    # IADSAVE = (100 – ERIIAD) / 100
    results[:iad_save] = (100.0 - results_iad[:hers_index]) / 100.0
    
    # 4.3.4 The IAF for the Rated Home (IAFPD) shall be calculated in accordance with equation 4.3.4-1.
    # IAFRH = IAFCFA * IAFNbr * IAFNS (Eq. 4.3.4-1)
    # where:
    #   IAFRH = combined Index Adjustment Factor for Rated Home
    #   IAFCFA = (2400/CFA) ^ [0.304 * (IADSAVE)]
    #   IAFNbr = 1+ [0.069 * (IADSAVE) * (Nbr-3)]
    #   IAFNS = (2/NS) ^ [0.12 * (IADSAVE)]
    results[:iaf_cfa] = (2400.0 / rated_output[:hpxml_cfa]) ** (0.304 * results[:iad_save])
    results[:iaf_nbr] = 1.0 + (0.069 * results[:iad_save] * (rated_output[:hpxml_nbr] - 3.0))
    results[:iaf_ns] = (2.0 / rated_output[:hpxml_nst]) ** (0.12 * results[:iad_save])
    results[:iaf_rh] = results[:iaf_cfa] * results[:iaf_nbr] * results[:iaf_ns]
    
    # ERI = PEfrac * (TnML / (TRL * IAFRH)) * 100 (Eq 4.1-2)
    # where:
    #   IAFRH = Index Adjustment Factor of Rated Home
    results[:hers_index] = results[:pefrac] * results[:tnml] / (results[:trl] * results[:iaf_rh]) * 100.0
    
  else
  
    # The HERS Index shall be determined in accordance with Equation 4.1-2:
    # HERS Index = PEfrac * (TnML / TRL) * 100
    results[:hers_index] = results[:pefrac] * results[:tnml] / results[:trl] * 100.0
    
  end

  return results
end

def write_results_annual_output(resultsdir, design, design_output)
  
  out_csv = File.join(resultsdir, "#{design.gsub(' ','')}.csv")
  
  results_out = {}
  results_out["Electricity: Total (MBtu)"] = design_output[:elecTotal]
  results_out["Electricity: Net (MBtu)"] = design_output[:elecTotal]-design_output[:elecPV]
  results_out["Natural Gas: Total (MBtu)"] = design_output[:ngTotal]
  results_out["Other Fuels: Total (MBtu)"] = design_output[:otherTotal]
  results_out[""] = "" # line break
  results_out["Electricity: Heating (MBtu)"] = design_output[:elecHeating]
  results_out["Electricity: Cooling (MBtu)"] = design_output[:elecCooling]
  results_out["Electricity: Fans/Pumps (MBtu)"] = design_output[:elecFans]+design_output[:elecPumps]
  results_out["Electricity: Hot Water (MBtu)"] = design_output[:elecHotWater]+design_output[:elecRecircPump]
  results_out["Electricity: Lighting (MBtu)"] = design_output[:elecIntLighting]+design_output[:elecExtLighting]
  results_out["Electricity: Mech Vent (MBtu)"] = design_output[:elecMechVent]
  results_out["Electricity: Refrigerator (MBtu)"] = design_output[:elecFridge]
  results_out["Electricity: Dishwasher (MBtu)"] = design_output[:elecDishwasher]
  results_out["Electricity: Clothes Washer (MBtu)"] = design_output[:elecClothesWasher]
  results_out["Electricity: Clothes Dryer (MBtu)"] = design_output[:elecClothesDryer]
  results_out["Electricity: Range/Oven (MBtu)"] = design_output[:elecRangeOven]
  results_out["Electricity: Ceiling Fan (MBtu)"] = design_output[:elecCeilingFan]
  results_out["Electricity: Plug Loads (MBtu)"] = design_output[:elecMELs]+design_output[:elecTV]
  results_out["Electricity: PV (MBtu)"] = design_output[:elecPV]
  results_out["Natural Gas: Heating (MBtu)"] = design_output[:ngHeating]
  results_out["Natural Gas: Hot Water (MBtu)"] = design_output[:ngHotWater]
  results_out["Natural Gas: Clothes Dryer (MBtu)"] = design_output[:ngClothesDryer]
  results_out["Natural Gas: Range/Oven (MBtu)"] = design_output[:ngRangeOven]
  results_out["Other Fuels: Heating (MBtu)"] = design_output[:otherHeating]
  results_out["Other Fuels: Hot Water (MBtu)"] = design_output[:otherHotWater]
  results_out["Other Fuels: Clothes Dryer (MBtu)"] = design_output[:otherClothesDryer]
  results_out["Other Fuels: Range/Oven (MBtu)"] = design_output[:otherRangeOven]
  CSV.open(out_csv, "wb") {|csv| results_out.to_a.each {|elem| csv << elem} }
  
end

def write_results(results, resultsdir, design_outputs, using_iaf)

  ref_output = design_outputs[Constants.CalcTypeERIReferenceHome]
  
  # Results file
  results_csv = File.join(resultsdir, "ERI_Results.csv")
  results_out = {}
  results_out["HERS Index"] = results[:hers_index].round(2)
  results_out["REUL Heating (MBtu)"] = results[:reul_heat].round(2)
  results_out["REUL Cooling (MBtu)"] = results[:reul_cool].round(2)
  results_out["REUL Hot Water (MBtu)"] = results[:reul_dhw].round(2)
  results_out["EC_r Heating (MBtu)"] = results[:ec_r_heat].round(2)
  results_out["EC_r Cooling (MBtu)"] = results[:ec_r_cool].round(2)
  results_out["EC_r Hot Water (MBtu)"] = results[:ec_r_dhw].round(2)
  #results_out["XEUL Heating (MBtu)"] = results[:xeul_heat].round(2)
  #results_out["XEUL Cooling (MBtu)"] = results[:xeul_cool].round(2)
  #results_out["XEUL Hot Water (MBtu)"] = results[:xeul_dhw].round(2)
  results_out["EC_x Heating (MBtu)"] = results[:ec_x_heat].round(2)
  results_out["EC_x Cooling (MBtu)"] = results[:ec_x_cool].round(2)
  results_out["EC_x Hot Water (MBtu)"] = results[:ec_x_dhw].round(2)
  results_out["EC_x L&A (MBtu)"] = results[:eul_la].round(2)
  if using_iaf
    results_out["IAD_Save (%)"] = results[:iad_save]
  end
  # TODO: Heating Fuel, Heating MEPR, Cooling Fuel, Cooling MEPR, Hot Water Fuel, Hot Water MEPR
  CSV.open(results_csv, "wb") {|csv| results_out.to_a.each {|elem| csv << elem} }
  
  # Worksheet file
  worksheet_csv = File.join(resultsdir, "ERI_Worksheet.csv")
  worksheet_out = {}
  worksheet_out["Coeff Heating a"] = results[:coeff_heat_a].round(4)
  worksheet_out["Coeff Heating b"] = results[:coeff_heat_b].round(4)
  worksheet_out["Coeff Cooling a"] = results[:coeff_cool_a].round(4)
  worksheet_out["Coeff Cooling b"] = results[:coeff_cool_b].round(4)
  worksheet_out["Coeff Hot Water a"] = results[:coeff_dhw_a].round(4)
  worksheet_out["Coeff Hot Water b"] = results[:coeff_dhw_b].round(4)
  worksheet_out["DSE_r Heating"] = results[:dse_r_heat].round(4)
  worksheet_out["DSE_r Cooling"] = results[:dse_r_cool].round(4)
  worksheet_out["DSE_r Hot Water"] = results[:dse_r_dhw].round(4)
  worksheet_out["EEC_x Heating"] = results[:eec_x_heat].round(4)
  worksheet_out["EEC_x Cooling"] = results[:eec_x_cool].round(4)
  worksheet_out["EEC_x Hot Water"] = results[:eec_x_dhw].round(4)
  worksheet_out["EEC_r Heating"] = results[:eec_r_heat].round(4)
  worksheet_out["EEC_r Cooling"] = results[:eec_r_cool].round(4)
  worksheet_out["EEC_r Hot Water"] = results[:eec_r_dhw].round(4)
  worksheet_out["nEC_x Heating"] = results[:nec_x_heat].round(4)
  worksheet_out["nEC_x Cooling"] = results[:nec_x_cool].round(4)
  worksheet_out["nEC_x Hot Water"] = results[:nec_x_dhw].round(4)
  worksheet_out["nMEUL Heating"] = results[:nmeul_heat].round(4)
  worksheet_out["nMEUL Cooling"] = results[:nmeul_cool].round(4)
  worksheet_out["nMEUL Hot Water"] = results[:nmeul_dhw].round(4)
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
  worksheet_out["HERS Index"] = results[:hers_index].round(2)
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
  worksheet_out["Ref L&A R/O"] = (ref_output[:elecRangeOven]+ref_output[:fuelRangeOven]).round(2)
  worksheet_out["Ref L&A cDryer"] = (ref_output[:elecClothesDryer]+ref_output[:fuelClothesDryer]).round(2)
  worksheet_out["Ref L&A dWash"] = ref_output[:elecDishwasher].round(2)
  worksheet_out["Ref L&A cWash"] = ref_output[:elecClothesWasher].round(2)
  worksheet_out["Ref L&A mechV"] = ref_output[:elecMechVent].round(2)
  worksheet_out["Ref L&A total"] = results[:reul_la].round(2)
  CSV.open(worksheet_csv, "wb") {|csv| worksheet_out.to_a.each {|elem| csv << elem} }
  
end

def download_epws

  weather_dir = File.join(File.dirname(__FILE__), "..", "weather")
  
  num_epws_expected = File.readlines(File.join(weather_dir, "data.csv")).size - 1
  num_epws_actual = Dir[File.join(weather_dir, "*.epw")].count
  if num_epws_actual == num_epws_expected
    puts "Weather directory is already up-to-date."
    puts "#{num_epws_actual} weather files are available in the weather directory."
    puts "Completed."
    exit!
  end
  
  require 'net/http'
  require 'tempfile'
  
  tmpfile = Tempfile.new("epw")

  url = URI.parse("http://s3.amazonaws.com/epwweatherfiles/openstudio-eri-tmy3s.zip")
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
  opts.banner = "Usage: #{File.basename(__FILE__)} -x building.xml\n e.g., #{File.basename(__FILE__)} -x sample_files/valid.xml\n"

  opts.on('-x', '--xml <FILE>', 'HPXML file') do |t|
    options[:hpxml] = t
  end

  opts.on('--download-weather', 'Downloads all weather files') do |t|
    options[:epws] = t
  end
  
  options[:debug] = false
  opts.on('-d', '--debug') do |t|
    options[:debug] = true
  end
  
  opts.on_tail('-h', '--help', 'Display help') do
    puts opts
    exit!
  end

end.parse!

if options[:epws]
  download_epws
end

if not options[:hpxml]
  fail "ERROR: HPXML argument is required. Call #{File.basename(__FILE__)} -h for usage."
end

unless (Pathname.new options[:hpxml]).absolute?
  options[:hpxml] = File.expand_path(File.join(File.dirname(__FILE__), options[:hpxml]))
end 
unless File.exists?(options[:hpxml]) and options[:hpxml].downcase.end_with? ".xml"
  fail "ERROR: '#{options[:hpxml]}' does not exist or is not an .xml file."
end

# Check for correct versions of OS
os_version = "2.6.0"
if OpenStudio.openStudioVersion != os_version
  fail "ERROR: OpenStudio version #{os_version} is required."
end

# Create results dir
resultsdir = File.join(basedir, "results")
rm_path(resultsdir)
Dir.mkdir(resultsdir)

# Run w/ Addendum E House Size Index Adjustment Factor?
using_iaf = false
hpxml_doc = REXML::Document.new(File.read(options[:hpxml]))
eri_version = XMLHelper.get_value(hpxml_doc, "/HPXML/SoftwareInfo/extension/ERICalculation/Version")
if ['2014AE', '2014AEG'].include? eri_version
  using_iaf = true
end

run_designs = {Constants.CalcTypeERIRatedHome => true,
               Constants.CalcTypeERIReferenceHome => true,
               Constants.CalcTypeERIIndexAdjustmentDesign => using_iaf}

# Run simulations
puts "HPXML: #{options[:hpxml]}"
design_outputs = {}
if Process.respond_to?(:fork) # e.g., most Unix systems
  
  # Code runs in forked child processes and makes direct calls. This is the fastest 
  # approach but isn't available on, e.g., Windows.
  
  # Setup IO.pipe to communicate output from child processes to this parent process
  readers,writers = {},{}
  run_designs.keys.each do |design|
    readers[design],writers[design] = IO.pipe
  end
  
  Parallel.map(run_designs, in_processes: run_designs.size) do |design, run|
    output_hpxml_path, designdir = run_design_direct(basedir, design, resultsdir, options[:hpxml], options[:debug], run)
    design_output = process_design_output(design, designdir, resultsdir, output_hpxml_path)
    writers[design].puts(Marshal.dump(design_output)) # Provide output data to parent process
  end
  
  # Retrieve output data from child processes
  readers.each do |design,reader|
    writers[design].close
    next if not run_designs[design]
    design_outputs[design] = Marshal.load(reader.read)
  end
  
else # e.g., Windows
  
  # Fallback. Code runs in spawned child processes in order to take advantage of
  # multiple processors.
  
  Parallel.map(run_designs, in_threads: run_designs.size) do |design, run|
    output_hpxml_path, designdir = run_design_spawn(basedir, design, resultsdir, options[:hpxml], options[:debug], run)
    design_outputs[design] = process_design_output(design, designdir, resultsdir, output_hpxml_path)
  end
  
end

# Calculate and write results
puts "Calculating ERI..."
if using_iaf
  results_iad = calculate_eri(design_outputs[Constants.CalcTypeERIIndexAdjustmentDesign], 
                              design_outputs[Constants.CalcTypeERIReferenceHome])
else
  results_iad = nil
end
results = calculate_eri(design_outputs[Constants.CalcTypeERIRatedHome], 
                        design_outputs[Constants.CalcTypeERIReferenceHome], 
                        results_iad)

write_results(results, resultsdir, design_outputs, using_iaf)

puts "Output files written to '#{File.basename(resultsdir)}' directory."
puts "Completed in #{(Time.now - start_time).round(1)} seconds."