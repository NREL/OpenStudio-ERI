# encoding: utf-8
start_time = Time.now

require 'optparse'
require 'csv'
require 'pathname'
require 'fileutils'
require 'parallel'
require 'openstudio'
require_relative "../measures/301EnergyRatingIndexRuleset/resources/constants"
require_relative "../measures/301EnergyRatingIndexRuleset/resources/xmlhelper"
require_relative "../measures/301EnergyRatingIndexRuleset/resources/util"
require_relative "../measures/301EnergyRatingIndexRuleset/resources/unit_conversions"

# TODO: Rake task to package ERI
# TODO: Add error-checking
# TODO: Add standardized reporting of errors

designs = [
           Constants.CalcTypeERIRatedHome,
           Constants.CalcTypeERIReferenceHome,
           #Constants.CalcTypeERIIndexAdjustmentDesign,
          ]

basedir = File.expand_path(File.dirname(__FILE__))
      
def recreate_path(path)
  if Dir.exists?(path)
    FileUtils.rm_r(path)
  end
  for retries in 1..50
    break if not Dir.exists?(path)
    sleep(0.1)
  end
  Dir.mkdir(path)
end
      
def create_osw(design, basedir, resultsdir, options)

  design_str = design.gsub(' ','')

  # Create dir
  designdir = File.join(basedir, design_str)
  recreate_path(designdir)
  
  # Create OSW
  osw_path = File.join(designdir, "run.osw")
  osw = OpenStudio::WorkflowJSON.new
  osw.setOswPath(osw_path)
  osw.addMeasurePath("../../measures")
  
  # Add measures (w/args) to OSW
  schemas_dir = File.absolute_path(File.join(basedir, "..", "hpxml_schemas"))
  output_hpxml_path = File.join(resultsdir, design_str + ".xml")
  measures = {}
  measures['301EnergyRatingIndexRuleset'] = {}
  measures['301EnergyRatingIndexRuleset']['calc_type'] = design
  measures['301EnergyRatingIndexRuleset']['hpxml_file_path'] = options[:hpxml]
  #measures['301EnergyRatingIndexRuleset']['schemas_dir'] = schemas_dir # FIXME
  measures['301EnergyRatingIndexRuleset']['hpxml_output_file_path'] = output_hpxml_path
  if options[:debug]
    measures['301EnergyRatingIndexRuleset']['debug'] = 'true'
    measures['301EnergyRatingIndexRuleset']['osm_output_file_path'] = output_hpxml_path.gsub(".xml",".osm")
  end
  steps = OpenStudio::WorkflowStepVector.new
  measures.keys.each do |measure|
    step = OpenStudio::MeasureStep.new(measure)
    step.setName(measure)
    measures[measure].each do |arg,val|
      step.setArgument(arg, val)
    end
    steps.push(step)
  end  
  osw.setWorkflowSteps(steps)
  
  # Save OSW
  osw.save
  
  return osw_path, output_hpxml_path
  
end

def run_osw(osw_path, options)

  # Redirect to a log file
  log_str = " >> \"#{osw_path.gsub('.osw','.log')}\""
  
  # FIXME: Push changes upstream to OpenStudio-workflow gem
  gem_str = '-I ../gems/OpenStudio-workflow-gem/lib/ '
  
  debug_str = ''
  verbose_str = ''
  if options[:debug]
    debug_str = '--debug '
    verbose_str = '--verbose '
  end

  cli_path = OpenStudio.getOpenStudioCLI
  command = "\"#{cli_path}\" #{verbose_str}#{gem_str}run #{debug_str}-w \"#{osw_path}\"#{log_str}"
  system(command)
  
  return File.join(File.dirname(osw_path), "run", "eplusout.sql")
  
end

def get_sql_query_result(sqlFile, query)
  result = sqlFile.execAndReturnFirstDouble(query)
  if result.is_initialized
    return UnitConversions.convert(result.get, "GJ", "MBtu")
  end
  return 0
end

def get_sql_result(sqlValue, design)
  if sqlValue.is_initialized
    return UnitConversions.convert(sqlValue.get, "GJ", "MBtu")
  end
  fail "ERROR: Simulation unsuccessful for #{design}."
end

def parse_sql(design, sql_path, output_hpxml_path)
  if not File.exists?(sql_path)
    fail "ERROR: Simulation unsuccessful for #{design}."
  end
  
  sqlFile = OpenStudio::SqlFile.new(sql_path, false)
  
  sim_output = {}
  sim_output[:hpxml] = output_hpxml_path
  sim_output[:allTotal] = get_sql_result(sqlFile.totalSiteEnergy, design)
  
  # Electricity categories
  sim_output[:elecTotal] = get_sql_result(sqlFile.electricityTotalEndUses, design)
  sim_output[:elecHeating] = get_sql_result(sqlFile.electricityHeating, design)
  sim_output[:elecCooling] = get_sql_result(sqlFile.electricityCooling, design)
  sim_output[:elecIntLighting] = get_sql_result(sqlFile.electricityInteriorLighting, design)
  sim_output[:elecExtLighting] = get_sql_result(sqlFile.electricityExteriorLighting, design)
  sim_output[:elecAppliances] = get_sql_result(sqlFile.electricityInteriorEquipment, design)
  sim_output[:elecFans] = get_sql_result(sqlFile.electricityFans, design)
  sim_output[:elecPumps] = get_sql_result(sqlFile.electricityPumps, design)
  sim_output[:elecHotWater] = get_sql_result(sqlFile.electricityWaterSystems, design)
  
  # Fuel categories
  sim_output[:ngTotal] = get_sql_result(sqlFile.naturalGasTotalEndUses, design)
  sim_output[:ngHeating] = get_sql_result(sqlFile.naturalGasHeating, design)
  sim_output[:ngAppliances] = get_sql_result(sqlFile.naturalGasInteriorEquipment, design)
  sim_output[:ngHotWater] = get_sql_result(sqlFile.naturalGasWaterSystems, design)
  sim_output[:otherTotal] = get_sql_result(sqlFile.otherFuelTotalEndUses, design)
  sim_output[:otherHeating] = get_sql_result(sqlFile.otherFuelHeating, design)
  sim_output[:otherAppliances] = get_sql_result(sqlFile.otherFuelInteriorEquipment, design)
  sim_output[:otherHotWater] = get_sql_result(sqlFile.otherFuelWaterSystems, design)
  sim_output[:fuelTotal] = sim_output[:ngTotal] + sim_output[:otherTotal]
  sim_output[:fuelHeating] = sim_output[:ngHeating] + sim_output[:otherHeating]
  sim_output[:fuelAppliances] = sim_output[:ngAppliances] + sim_output[:otherAppliances]
  sim_output[:fuelHotWater] = sim_output[:ngHotWater] + sim_output[:otherHotWater]

  # Other - PV
  query = "SELECT Value FROM TabularDataWithStrings WHERE ReportName='AnnualBuildingUtilityPerformanceSummary' AND ReportForString='Entire Facility' AND TableName='Electric Loads Satisfied' AND RowName='Total On-Site Electric Sources' AND ColumnName='Electricity' AND Units='GJ'"
  sim_output[:elecPV] = get_sql_query_result(sqlFile, query)
  
  # Other - Fridge
  query = "SELECT Value FROM TabularDataWithStrings WHERE ReportName='EnergyMeters' AND ReportForString='Entire Facility' AND TableName='Annual and Peak Values - Electricity' AND RowName LIKE '#{Constants.ObjectNameRefrigerator}%' AND ColumnName='Electricity Annual Value' AND Units='GJ'"
  sim_output[:elecFridge] = get_sql_query_result(sqlFile, query)
  
  # Other - Dishwasher
  query = "SELECT Value FROM TabularDataWithStrings WHERE ReportName='EnergyMeters' AND ReportForString='Entire Facility' AND TableName='Annual and Peak Values - Electricity' AND RowName LIKE '#{Constants.ObjectNameDishwasher}%' AND ColumnName='Electricity Annual Value' AND Units='GJ'"
  sim_output[:elecDishwasher] = get_sql_query_result(sqlFile, query)
  
  # Other - Clothes Washer
  query = "SELECT Value FROM TabularDataWithStrings WHERE ReportName='EnergyMeters' AND ReportForString='Entire Facility' AND TableName='Annual and Peak Values - Electricity' AND RowName LIKE '#{Constants.ObjectNameClothesWasher}%' AND ColumnName='Electricity Annual Value' AND Units='GJ'"
  sim_output[:elecClothesWasher] = get_sql_query_result(sqlFile, query)
  
  # Other - Clothes Dryer
  query = "SELECT Value FROM TabularDataWithStrings WHERE ReportName='EnergyMeters' AND ReportForString='Entire Facility' AND TableName='Annual and Peak Values - Electricity' AND RowName LIKE '#{Constants.ObjectNameClothesDryer(nil)}%' AND ColumnName='Electricity Annual Value' AND Units='GJ'"
  sim_output[:elecClothesDryer] = get_sql_query_result(sqlFile, query)
  query = "SELECT Value FROM TabularDataWithStrings WHERE ReportName='EnergyMeters' AND ReportForString='Entire Facility' AND TableName='Annual and Peak Values - Gas' AND RowName LIKE '#{Constants.ObjectNameClothesDryer(nil)}%' AND ColumnName='Gas Annual Value' AND Units='GJ'"
  sim_output[:ngClothesDryer] = get_sql_query_result(sqlFile, query)
  query = "SELECT Value FROM TabularDataWithStrings WHERE ReportName='EnergyMeters' AND ReportForString='Entire Facility' AND TableName='Annual and Peak Values - Other' AND RowName LIKE '#{Constants.ObjectNameClothesDryer(nil)}%' AND ColumnName='Annual Value' AND Units='GJ'"
  sim_output[:otherClothesDryer] = get_sql_query_result(sqlFile, query)
  sim_output[:fuelClothesDryer] = sim_output[:ngClothesDryer] + sim_output[:otherClothesDryer]
  
  # Other - MELS
  query = "SELECT Value FROM TabularDataWithStrings WHERE ReportName='EnergyMeters' AND ReportForString='Entire Facility' AND TableName='Annual and Peak Values - Electricity' AND RowName LIKE '#{Constants.ObjectNameMiscPlugLoads}%' AND ColumnName='Electricity Annual Value' AND Units='GJ'"
  sim_output[:elecMELs] = get_sql_query_result(sqlFile, query)
  query = "SELECT Value FROM TabularDataWithStrings WHERE ReportName='EnergyMeters' AND ReportForString='Entire Facility' AND TableName='Annual and Peak Values - Electricity' AND RowName LIKE '#{Constants.ObjectNameMiscTelevision}%' AND ColumnName='Electricity Annual Value' AND Units='GJ'"
  sim_output[:elecTV] = get_sql_query_result(sqlFile, query)
  
  # Other - Range/Oven
  query = "SELECT Value FROM TabularDataWithStrings WHERE ReportName='EnergyMeters' AND ReportForString='Entire Facility' AND TableName='Annual and Peak Values - Electricity' AND RowName LIKE '#{Constants.ObjectNameCookingRange(nil)}%' AND ColumnName='Electricity Annual Value' AND Units='GJ'"
  sim_output[:elecRangeOven] = get_sql_query_result(sqlFile, query)
  query = "SELECT Value FROM TabularDataWithStrings WHERE ReportName='EnergyMeters' AND ReportForString='Entire Facility' AND TableName='Annual and Peak Values - Gas' AND RowName LIKE '#{Constants.ObjectNameCookingRange(nil)}%' AND ColumnName='Gas Annual Value' AND Units='GJ'"
  sim_output[:ngRangeOven] = get_sql_query_result(sqlFile, query)
  query = "SELECT Value FROM TabularDataWithStrings WHERE ReportName='EnergyMeters' AND ReportForString='Entire Facility' AND TableName='Annual and Peak Values - Other' AND RowName LIKE '#{Constants.ObjectNameCookingRange(nil)}%' AND ColumnName='Annual Value' AND Units='GJ'"
  sim_output[:otherRangeOven] = get_sql_query_result(sqlFile, query)
  sim_output[:fuelRangeOven] = sim_output[:ngRangeOven] + sim_output[:otherRangeOven]
  
  # Other - Ceiling Fans
  query = "SELECT Value FROM TabularDataWithStrings WHERE ReportName='EnergyMeters' AND ReportForString='Entire Facility' AND TableName='Annual and Peak Values - Electricity' AND RowName LIKE '#{Constants.ObjectNameCeilingFan}%' AND ColumnName='Electricity Annual Value' AND Units='GJ'"
  sim_output[:elecCeilingFan] = get_sql_query_result(sqlFile, query)
  
  # Other - Mechanical Ventilation
  query = "SELECT Value FROM TabularDataWithStrings WHERE ReportName='EnergyMeters' AND ReportForString='Entire Facility' AND TableName='Annual and Peak Values - Electricity' AND RowName LIKE '#{Constants.EndUseMechVentFan}%' AND ColumnName='Electricity Annual Value' AND Units='GJ'"
  sim_output[:elecMechVent] = get_sql_query_result(sqlFile, query)
  
  # Other - Recirculation pump
  query = "SELECT Value FROM TabularDataWithStrings WHERE ReportName='EnergyMeters' AND ReportForString='Entire Facility' AND TableName='Annual and Peak Values - Electricity' AND RowName LIKE '#{Constants.ObjectNameHotWaterRecircPump}%' AND ColumnName='Electricity Annual Value' AND Units='GJ'"
  sim_output[:elecRecircPump] = get_sql_query_result(sqlFile, query)
  sim_output[:elecAppliances] -= sim_output[:elecRecircPump]
  
  # Other - Space Heating Load
  vars = "'" + BuildingLoadVars.get_space_heating_load_vars.join("','") + "'"
  query = "SELECT SUM(ABS(VariableValue)/1000000000) FROM ReportVariableData WHERE ReportVariableDataDictionaryIndex IN (SELECT ReportVariableDataDictionaryIndex FROM ReportVariableDataDictionary WHERE VariableType='Sum' AND IndexGroup='System' AND TimestepType='Zone' AND VariableName IN (#{vars}) AND ReportingFrequency='Run Period' AND VariableUnits='J')"
  sim_output[:loadHeating] = get_sql_query_result(sqlFile, query)
  
  # Other - Space Cooling Load
  vars = "'" + BuildingLoadVars.get_space_cooling_load_vars.join("','") + "'"
  query = "SELECT SUM(ABS(VariableValue)/1000000000) FROM ReportVariableData WHERE ReportVariableDataDictionaryIndex IN (SELECT ReportVariableDataDictionaryIndex FROM ReportVariableDataDictionary WHERE VariableType='Sum' AND IndexGroup='System' AND TimestepType='Zone' AND VariableName IN (#{vars}) AND ReportingFrequency='Run Period' AND VariableUnits='J')"
  sim_output[:loadCooling] = get_sql_query_result(sqlFile, query)
  
  # Other - Water Heating Load
  vars = "'" + BuildingLoadVars.get_water_heating_load_vars.join("','") + "'"
  query = "SELECT SUM(ABS(VariableValue)/1000000000) FROM ReportVariableData WHERE ReportVariableDataDictionaryIndex IN (SELECT ReportVariableDataDictionaryIndex FROM ReportVariableDataDictionary WHERE VariableType='Sum' AND IndexGroup='System' AND TimestepType='Zone' AND VariableName IN (#{vars}) AND ReportingFrequency='Run Period' AND VariableUnits='J')"
  sim_output[:loadHotWater] = get_sql_query_result(sqlFile, query)
  
  # Error Checking
  tolerance = 0.1 # MMBtu
  
  sum_fuels = (sim_output[:elecTotal] + sim_output[:fuelTotal])
  if (sim_output[:allTotal] - sum_fuels).abs > tolerance
    fail "ERROR: Fuels do not sum to total (#{sum_fuels.round(1)} vs #{sim_output[:allTotal].round(1)})."
  end
  
  sum_elec_categories = (sim_output[:elecHeating] + sim_output[:elecCooling] + 
                         sim_output[:elecIntLighting] + sim_output[:elecExtLighting] + 
                         sim_output[:elecAppliances] + sim_output[:elecFans] + 
                         sim_output[:elecPumps] + sim_output[:elecHotWater] + 
                         sim_output[:elecRecircPump])
  if (sim_output[:elecTotal] - sum_elec_categories).abs > tolerance
    fail "ERROR: Electric category end uses do not sum to total.\n#{sim_output.to_s}"
  end
  
  sum_fuel_categories = (sim_output[:fuelHeating] + sim_output[:fuelAppliances] + 
                         sim_output[:fuelHotWater])
  if (sim_output[:fuelTotal] - sum_fuel_categories).abs > tolerance
    fail "ERROR: Fuel category end uses do not sum to total.\n#{sim_output.to_s}"
  end
  
  sum_elec_appliances = (sim_output[:elecFridge] + sim_output[:elecDishwasher] +
                     sim_output[:elecClothesWasher] + sim_output[:elecClothesDryer] +
                     sim_output[:elecMELs] + sim_output[:elecTV] + 
                     sim_output[:elecRangeOven] + sim_output[:elecCeilingFan] + 
                     sim_output[:elecMechVent])
  if (sim_output[:elecAppliances] - sum_elec_appliances).abs > tolerance
    fail "ERROR: Electric appliances do not sum to total.\n#{sim_output.to_s}"
  end
  
  sum_fuel_appliances = (sim_output[:fuelClothesDryer] + sim_output[:fuelRangeOven])
  if (sim_output[:fuelAppliances] - sum_fuel_appliances).abs > tolerance
    fail "ERROR: Fuel appliances do not sum to total.\n#{sim_output.to_s}"
  end
  
  return sim_output
  
end

def get_cfa(hpxml_doc)
  cfa = XMLHelper.get_value(hpxml_doc, "/HPXML/Building/BuildingDetails/BuildingSummary/BuildingConstruction/ConditionedFloorArea")
  
  if cfa.nil?
    fail "ERROR: Conditioned floor area not found."
  end
  
  return cfa.to_f
end

def get_nbr(hpxml_doc)
  nbr = XMLHelper.get_value(hpxml_doc, "/HPXML/Building/BuildingDetails/BuildingSummary/BuildingConstruction/NumberofBedrooms")
  
  if nbr.nil?
    fail "ERROR: Number of bedrooms not found."
  end
  
  return nbr.to_i
end

def get_heating_fuel(hpxml_doc)
  heat_fuel = nil
  
  heating_system = hpxml_doc.elements["/HPXML/Building/BuildingDetails/Systems/HVAC/HVACPlant/HeatingSystem"]
  heat_pump_system = hpxml_doc.elements["/HPXML/Building/BuildingDetails/Systems/HVAC/HVACPlant/HeatPump"]
  
  if heating_system.nil? and heat_pump_system.nil?
    fail "ERROR: No heating system found."
  elsif not heating_system.nil? and not heat_pump_system.nil?
    fail "ERROR: Multiple heating systems found."
  elsif not heating_system.nil?
    heat_fuel = XMLHelper.get_value(heating_system, "HeatingSystemFuel")
  elsif not heat_pump_system.nil?
    heat_fuel = 'electricity'
  end
  
  if heat_fuel.nil?
    fail "ERROR: No heating system fuel type found."
  end

  return heat_fuel
end

def get_dhw_fuel(hpxml_doc)
  dhw_fuel = nil
  
  dhw_system = hpxml_doc.elements["/HPXML/Building/BuildingDetails/Systems/WaterHeating/WaterHeatingSystem"]
  
  if dhw_system.nil?
    fail "ERROR: No water heating system found."
  else
    dhw_fuel = XMLHelper.get_value(dhw_system, "FuelType")
  end
  
  if dhw_fuel.nil?
    fail "ERROR: No water heating system fuel type found."
  end
  
  return dhw_fuel
end

def get_dse_heat_cool(hpxml_doc)
  
  dse_heat = XMLHelper.get_value(hpxml_doc, "/HPXML/Building/BuildingDetails/Systems/HVAC/HVACDistribution/AnnualHeatingDistributionSystemEfficiency")
  dse_cool = XMLHelper.get_value(hpxml_doc, "/HPXML/Building/BuildingDetails/Systems/HVAC/HVACDistribution/AnnualCoolingDistributionSystemEfficiency")
  
  if dse_heat.nil?
    fail "ERROR: Heating distribution system efficiency not found."
  elsif dse_cool.nil?
    fail "ERROR: Cooling distribution system efficiency not found."
  end
  
  return Float(dse_heat), Float(dse_cool)
  
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
  eec_heat = nil
  
  heating_system = hpxml_doc.elements["/HPXML/Building/BuildingDetails/Systems/HVAC/HVACPlant/HeatingSystem"]
  heat_pump_system = hpxml_doc.elements["/HPXML/Building/BuildingDetails/Systems/HVAC/HVACPlant/HeatPump"]
  
  [heating_system, heat_pump_system].each do |sys|
    next if sys.nil?
    ['HSPF','COP','AFUE','Percent'].each do |unit|
      if sys == heating_system
        value = XMLHelper.get_value(sys, "AnnualHeatingEfficiency[Units='#{unit}']/Value")
      elsif sys == heat_pump_system
        value = XMLHelper.get_value(sys, "AnnualHeatEfficiency[Units='#{unit}']/Value")
      end
      next if value.nil?
      if not eec_heat.nil?
        fail "ERROR: Multiple heating system efficiency values found."
      end
      eec_heat = get_eec_value_numerator(unit) / value.to_f
    end
  end

  if eec_heat.nil?
    fail "ERROR: No heating system efficiency value found."
  end

  return eec_heat
end

def get_eec_cool(hpxml_doc)
  eec_cool = nil
  
  cooling_system = hpxml_doc.elements["/HPXML/Building/BuildingDetails/Systems/HVAC/HVACPlant/CoolingSystem"]
  heat_pump_system = hpxml_doc.elements["/HPXML/Building/BuildingDetails/Systems/HVAC/HVACPlant/HeatPump"]
  
  [cooling_system, heat_pump_system].each do |sys|
    next if sys.nil?
    ['SEER','COP','EER'].each do |unit|
      if sys == cooling_system  
        value = XMLHelper.get_value(sys, "AnnualCoolingEfficiency[Units='#{unit}']/Value")
      elsif sys == heat_pump_system
        value = XMLHelper.get_value(sys, "AnnualCoolEfficiency[Units='#{unit}']/Value")
      end
      next if value.nil?
      if not eec_cool.nil?
        fail "ERROR: Multiple cooling system efficiency values found."
      end
      eec_cool = get_eec_value_numerator(unit) / value.to_f
    end
  end
  
  if eec_cool.nil?
    fail "ERROR: No cooling system efficiency value found."
  end
  
  return eec_cool
end

def get_eec_dhw(hpxml_doc)
  eec_dhw = nil
  
  dhw_system = hpxml_doc.elements["/HPXML/Building/BuildingDetails/Systems/WaterHeating/WaterHeatingSystem"]
  
  [dhw_system].each do |sys|
    next if sys.nil?
    value = XMLHelper.get_value(sys, "EnergyFactor")
    value_adj = XMLHelper.get_value(sys, "extension/PerformanceAdjustmentEnergyFactor")
    if not value.nil? and not value_adj.nil?
      eec_dhw = get_eec_value_numerator('EF') / (value.to_f * value_adj.to_f)
    end
  end
  
  if eec_dhw.nil?
    fail "ERROR: No water heating system efficiency value found."
  end
  
  return eec_dhw
end

def dhw_adjustment(hpxml_doc)
  # FIXME: Can we modify EF/COP/etc. efficiencies like we do for DSE, so that we don't need to post-process?
  # FIXME: Double-check this only applies to the Rated Home
  hwdist = hpxml_doc.elements["/HPXML/Building/BuildingDetails/Systems/WaterHeating/HotWaterDistribution"]
  return Float(XMLHelper.get_value(hwdist, "extension/EnergyConsumptionAdjustmentFactor"))
end

def calculate_eri(sim_outputs)

  rated_output = sim_outputs[Constants.CalcTypeERIRatedHome]
  ref_output = sim_outputs[Constants.CalcTypeERIReferenceHome]
  rated_hpxml_doc = REXML::Document.new(File.read(rated_output[:hpxml]))
  ref_hpxml_doc = REXML::Document.new(File.read(ref_output[:hpxml]))
  
  results = {}
  results[:cfa] = get_cfa(rated_hpxml_doc)
  results[:nbr] = get_nbr(rated_hpxml_doc)
  
  # REUL = Reference Home End Use Loads (for heating, cooling or hot water) as computed using an Approved 
  # Software Rating Tool.
  # Heating/Cooling loads include effect of DSE, so we remove the effect below.
  dse_heat, dse_cool = get_dse_heat_cool(ref_hpxml_doc)
  results[:reul_heat] = ref_output[:loadHeating] * dse_heat
  results[:reul_cool] = ref_output[:loadCooling] * dse_cool
  results[:reul_dhw] = ref_output[:loadHotWater]
  
  # XEUL = Rated Home End Use Loads (for heating, cooling or hot water) as computed using an Approved 
  # Software Rating Tool.
  results[:xeul_heat] = 0 # TODO
  results[:xeul_cool] = 0 # TODO
  results[:xeul_dhw] = 0 # TODO
  
  # Table 4.2.1(1) Coefficients a and b
  results[:coeff_cool_a] = 3.8090
  results[:coeff_cool_b] = 0.0
  results[:coeff_heat_a] = nil
  results[:coeff_heat_b] = nil
  results[:coeff_dhw_a] = nil
  results[:coeff_dhw_b] = nil
  heat_fuel = get_heating_fuel(rated_hpxml_doc)
  if heat_fuel == 'electricity'
    results[:coeff_heat_a] = 2.2561
    results[:coeff_heat_b] = 0.0
  elsif ['natural gas','fuel oil','propane'].include? heat_fuel
    results[:coeff_heat_a] = 1.0943
    results[:coeff_heat_b] = 0.4030
  end
  dwh_fuel = get_dhw_fuel(rated_hpxml_doc)
  if dwh_fuel == 'electricity'
    results[:coeff_dhw_a] = 0.9200
    results[:coeff_dhw_b] = 0.0
  elsif ['natural gas','fuel oil','propane'].include? dwh_fuel
    results[:coeff_dhw_a] = 1.1877
    results[:coeff_dhw_b] = 1.0130
  end
  if results[:coeff_heat_a].nil? or results[:coeff_heat_b].nil?
    fail "ERROR: Could not identify EEC coefficients for heating system."
  end
  if results[:coeff_dhw_a].nil? or results[:coeff_dhw_b].nil?
    fail "ERROR: Could not identify EEC coefficients for water heating system."
  end
  
  # EEC_x = Equipment Efficiency Coefficient for the Rated Homes equipment, such that EEC_x equals the
  # energy consumption per unit load in like units as the load, and as derived from the Manufacturers
  # Equipment Performance Rating (MEPR) such that EEC_x equals 1.0 / MEPR for AFUE, COP or EF ratings, or 
  # such that EEC_x equals 3.413 / MEPR for HSPF, EER or SEER ratings.
  results[:eec_x_heat] = get_eec_heat(rated_hpxml_doc)
  results[:eec_x_cool] = get_eec_cool(rated_hpxml_doc)
  results[:eec_x_dhw] = get_eec_dhw(rated_hpxml_doc)
  
  # EEC_r = Equipment Efficiency Coefficient for the Reference Homes equipment, such that EEC_r equals the 
  # energy consumption per unit load in like units as the load, and as derived from the Manufacturers
  # Equipment Performance Rating (MEPR) such that EEC_r equals 1.0 / MEPR for AFUE, COP or EF ratings, or 
  # such that EEC_r equals 3.413 / MEPR for HSPF, EER or SEER ratings
  results[:eec_r_heat] = get_eec_heat(ref_hpxml_doc)
  results[:eec_r_cool] = get_eec_cool(ref_hpxml_doc)
  results[:eec_r_dhw] = get_eec_dhw(ref_hpxml_doc)
  
  # EC_x = estimated Energy Consumption for the Rated Homes end uses (for heating, including Auxiliary 
  # Electric Consumption, cooling or hot water) as computed using an Approved Software Rating Tool.
  results[:ec_x_heat] = rated_output[:elecHeating] + rated_output[:fuelHeating]
  results[:ec_x_cool] = rated_output[:elecCooling]
  results[:ec_x_dhw] = (rated_output[:elecHotWater] + rated_output[:fuelHotWater]) * dhw_adjustment(rated_hpxml_doc) + rated_output[:elecRecircPump]
  
  # EC_r = estimated Energy Consumption for the Reference Homes end uses (for heating, including Auxiliary 
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
  
  # nEC_x = (a* EEC_x  b)*(EC_x * EC_r * DSE_r) / (EEC_x * REUL) (Eq 4.1-1a)
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
  
  # The HERS Index shall be determined in accordance with Equation 4.1-2:
  # HERS Index = PEfrac * (TnML / TRL) * 100
  results[:hers_index] = results[:pefrac] * 100 * results[:tnml] / results[:trl]
  results[:hers_index] = results[:hers_index]

  return results
end

def write_results_annual_output(out_csv, sim_output)
  results_out = {
                 "Electricity, Total (MBtu)"=>sim_output[:elecTotal],
                 "Electricity, Net (MBtu)"=>sim_output[:elecTotal]-sim_output[:elecPV],
                 "Natural Gas, Total (MBtu)"=>sim_output[:ngTotal],
                 "Other Fuels, Total (MBtu)"=>sim_output[:otherTotal],
                 ""=>"", # line break
                 "Electricity, Heating (MBtu)"=>sim_output[:elecHeating],
                 "Electricity, Cooling (MBtu)"=>sim_output[:elecCooling],
                 "Electricity, Fans/Pumps (MBtu)"=>sim_output[:elecFans]+sim_output[:elecPumps],
                 "Electricity, Hot Water (MBtu)"=>sim_output[:elecHotWater]+sim_output[:elecRecircPump],
                 "Electricity, Lighting (MBtu)"=>sim_output[:elecIntLighting]+sim_output[:elecExtLighting],
                 "Electricity, Mech Vent (MBtu)"=>sim_output[:elecMechVent],
                 "Electricity, Refrigerator (MBtu)"=>sim_output[:elecFridge],
                 "Electricity, Dishwasher (MBtu)"=>sim_output[:elecDishwasher],
                 "Electricity, Clothes Washer (MBtu)"=>sim_output[:elecClothesWasher],
                 "Electricity, Clothes Dryer (MBtu)"=>sim_output[:elecClothesDryer],
                 "Electricity, Range/Oven (MBtu)"=>sim_output[:elecRangeOven],
                 "Electricity, Ceiling Fan (MBtu)"=>sim_output[:elecCeilingFan],
                 "Electricity, Plug Loads (MBtu)"=>sim_output[:elecMELs]+sim_output[:elecTV],
                 "Electricity, PV (MBtu)"=>sim_output[:elecPV],
                 "Natural Gas, Heating (MBtu)"=>sim_output[:ngHeating],
                 "Natural Gas, Hot Water (MBtu)"=>sim_output[:ngHotWater],
                 "Natural Gas, Clothes Dryer (MBtu)"=>sim_output[:ngClothesDryer],
                 "Natural Gas, Range/Oven (MBtu)"=>sim_output[:ngRangeOven],
                 "Other Fuels, Heating (MBtu)"=>sim_output[:otherHeating],
                 "Other Fuels, Hot Water (MBtu)"=>sim_output[:otherHotWater],
                 "Other Fuels, Clothes Dryer (MBtu)"=>sim_output[:otherClothesDryer],
                 "Other Fuels, Range/Oven (MBtu)"=>sim_output[:otherRangeOven],
                }
  CSV.open(out_csv, "wb") {|csv| results_out.to_a.each {|elem| csv << elem} }
end

def write_results(results, resultsdir, sim_outputs)

  # Results file
  results_csv = File.join(resultsdir, "ERI_Results.csv")
  results_out = {
                 "HERS Index"=>results[:hers_index].round(2),
                 "REUL Heating (MBtu)"=>results[:reul_heat].round(2),
                 "REUL Cooling (MBtu)"=>results[:reul_cool].round(2),
                 "REUL Hot Water (MBtu)"=>results[:reul_dhw].round(2),
                 "EC_r Heating (MBtu)"=>results[:ec_r_heat].round(2),
                 "EC_r Cooling (MBtu)"=>results[:ec_r_cool].round(2),
                 "EC_r Hot Water (MBtu)"=>results[:ec_r_dhw].round(2),
                 #"XEUL Heating (MBtu)"=>results[:xeul_heat].round(2),
                 #"XEUL Cooling (MBtu)"=>results[:xeul_cool].round(2),
                 #"XEUL Hot Water (MBtu)"=>results[:xeul_dhw].round(2),
                 "EC_x Heating (MBtu)"=>results[:ec_x_heat].round(2),
                 "EC_x Cooling (MBtu)"=>results[:ec_x_cool].round(2),
                 "EC_x Hot Water (MBtu)"=>results[:ec_x_dhw].round(2),
                 "EC_x L&A (MBtu)"=>results[:eul_la].round(2),
                 # TODO:
                 # Heating Fuel
                 # Heating MEPR
                 # Cooling Fuel
                 # Cooling MEPR
                 # Hot Water Fuel
                 # Hot Water MEPR
                }
  CSV.open(results_csv, "wb") {|csv| results_out.to_a.each {|elem| csv << elem} }
  
  # Worksheet file
  worksheet_csv = File.join(resultsdir, "ERI_Worksheet.csv")
  ref_output = sim_outputs[Constants.CalcTypeERIReferenceHome]
  worksheet_out = {
                   "Coeff Heating a"=>results[:coeff_heat_a].round(4),
                   "Coeff Heating b"=>results[:coeff_heat_b].round(4),
                   "Coeff Cooling a"=>results[:coeff_cool_a].round(4),
                   "Coeff Cooling b"=>results[:coeff_cool_b].round(4),
                   "Coeff Hot Water a"=>results[:coeff_dhw_a].round(4),
                   "Coeff Hot Water b"=>results[:coeff_dhw_b].round(4),
                   "DSE_r Heating"=>results[:dse_r_heat].round(4),
                   "DSE_r Cooling"=>results[:dse_r_cool].round(4),
                   "DSE_r Hot Water"=>results[:dse_r_dhw].round(4),
                   "EEC_x Heating"=>results[:eec_x_heat].round(4),
                   "EEC_x Cooling"=>results[:eec_x_cool].round(4),
                   "EEC_x Hot Water"=>results[:eec_x_dhw].round(4),
                   "EEC_r Heating"=>results[:eec_r_heat].round(4),
                   "EEC_r Cooling"=>results[:eec_r_cool].round(4),
                   "EEC_r Hot Water"=>results[:eec_r_dhw].round(4),
                   "nEC_x Heating"=>results[:nec_x_heat].round(4),
                   "nEC_x Cooling"=>results[:nec_x_cool].round(4),
                   "nEC_x Hot Water"=>results[:nec_x_dhw].round(4),
                   "nMEUL Heating"=>results[:nmeul_heat].round(4),
                   "nMEUL Cooling"=>results[:nmeul_cool].round(4),
                   "nMEUL Hot Water"=>results[:nmeul_dhw].round(4),
                   "Total Loads TnML"=>results[:tnml].round(4),
                   "Total Loads TRL"=>results[:trl].round(4),
                   "HERS Index"=>results[:hers_index].round(2),
                   ""=>"", # line break
                   "Home CFA"=>results[:cfa],
                   "Home Nbr"=>results[:nbr],
                   "L&A resMELs"=>ref_output[:elecMELs].round(2),
                   "L&A intLgt"=>ref_output[:elecIntLighting].round(2),
                   "L&A extLgt"=>ref_output[:elecExtLighting].round(2),
                   "L&A Fridg"=>ref_output[:elecFridge].round(2),
                   "L&A TVs"=>ref_output[:elecTV].round(2),
                   "L&A R/O"=>(ref_output[:elecRangeOven]+ref_output[:fuelRangeOven]).round(2),
                   "L&A cDryer"=>(ref_output[:elecClothesDryer]+ref_output[:fuelClothesDryer]).round(2),
                   "L&A dWash"=>ref_output[:elecDishwasher].round(2),
                   "L&A cWash"=>ref_output[:elecClothesWasher].round(2),
                   "L&A mechV"=>ref_output[:elecMechVent].round(2),
                   "L&A total"=>results[:reul_la].round(2),
                  }
  CSV.open(worksheet_csv, "wb") {|csv| worksheet_out.to_a.each {|elem| csv << elem} }
  
  # Summary energy results
  rated_annual_csv = File.join(resultsdir, "HERSRatedHome.csv")
  rated_output = sim_outputs[Constants.CalcTypeERIRatedHome]
  write_results_annual_output(rated_annual_csv, rated_output)
  
  ref_annual_csv = File.join(resultsdir, "HERSReferenceHome.csv")
  ref_output = sim_outputs[Constants.CalcTypeERIReferenceHome]
  write_results_annual_output(ref_annual_csv, ref_output)
  
end

options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: #{File.basename(__FILE__)} -x building.xml\n e.g., #{File.basename(__FILE__)} -x sample_files/valid.xml\n"

  opts.on('-x', '--xml <FILE>', 'HPXML file') do |t|
    options[:hpxml] = t
  end

  options[:debug] = false
  opts.on('-d', '--debug') do |t|
    options[:debug] = true
  end
  
  opts.on_tail('-h', '--help', 'Display help') do
    puts opts
    exit
  end

end.parse!

if not options[:hpxml]
  fail "ERROR: HPXML argument is required. Call #{File.basename(__FILE__)} -h for usage."
end

unless (Pathname.new options[:hpxml]).absolute?
  options[:hpxml] = File.expand_path(File.join(File.dirname(__FILE__), options[:hpxml]))
end 
unless File.exists?(options[:hpxml]) and options[:hpxml].downcase.end_with? ".xml"
  fail "ERROR: '#{options[:hpxml]}' does not exist or is not an .xml file."
end

# Check for mininum versions of OS
os_requires_version = "2.5.1"
os_requires_version_split = os_requires_version.split(".", 3)
os_has_version = OpenStudio.openStudioVersion
os_has_version_split = os_has_version.split(".", 3)
if os_has_version_split[0] < os_requires_version_split[0]
  fail "ERROR: OpenStudio version #{os_requires_version} is required.  You are running #{os_has_version}"
end
if os_has_version_split[0] == os_requires_version_split[0] and os_has_version_split[1] < os_requires_version_split[1]
  fail "ERROR: OpenStudio version #{os_requires_version} is required.  You are running #{os_has_version}"
end
if os_has_version_split[0] == os_requires_version_split[0] and os_has_version_split[1] == os_requires_version_split[1] and os_has_version_split[2] == os_requires_version_split[2]
  fail "ERROR: OpenStudio version #{os_requires_version} is required.  You are running #{os_has_version}"
end


# Create results dir
resultsdir = File.join(basedir, "results")
recreate_path(resultsdir)

# Run simulations
sim_outputs = {}
puts "HPXML: #{options[:hpxml]}"
Parallel.map(designs, in_threads: designs.size) do |design|
  # Use print instead of puts in here (see https://stackoverflow.com/a/5044669)
  
  print "[#{design}] Running workflow...\n"
  osw_path, output_hpxml_path = create_osw(design, basedir, resultsdir, options)
  sql_path = run_osw(osw_path, options)
  
  print "[#{design}] Gathering results...\n"
  sim_outputs[design] = parse_sql(design, sql_path, output_hpxml_path)
  
  print "[#{design}] Done.\n"
end

# Calculate and write results
puts "Calculating ERI..."
results = calculate_eri(sim_outputs)

puts "Writing output files..."
write_results(results, resultsdir, sim_outputs)

puts "Output files written to '#{File.basename(resultsdir)}' directory."
puts "Completed in #{(Time.now - start_time).round(1)} seconds."