start_time = Time.now

require 'optparse'
require 'csv'
require "pathname"
require 'fileutils'
require 'parallel'
require 'openstudio'
require "#{File.dirname(__FILE__)}/../../resources/constants" # FIXME
require "#{File.dirname(__FILE__)}/../../resources/xmlhelper" # FIXME

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
  for retries in 1..10
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
  osw.addMeasurePath("../../../measures") # FIXME
  osw.setSeedFile("../../../seeds/EmptySeedModel.osm") # FIXME
  
  # Add measures (w/args) to OSW
  measures_dir = File.join(basedir, "..", "..", "measures") # FIXME
  schemas_dir = File.join(basedir, "..", "..", "measures", "301EnergyRatingIndexRuleset", "tests", "schemas")
  output_hpxml_path = File.join(resultsdir, design_str + ".xml")
  measures = {
              '301EnergyRatingIndexRuleset'=>{
                                              "calc_type"=>design,
                                              "hpxml_file_path"=>options[:hpxml],
                                              "weather_file_path"=>options[:epw],
                                              "measures_dir"=>measures_dir,
                                              "schemas_dir"=>schemas_dir,
                                              "output_file_path"=>output_hpxml_path,
                                             },
             }
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

def run_osw(osw_path, show_debug=false)

  # FIXME: Get latest installed version of openstudio.exe
  os_clis = Dir["C:/openstudio-*/bin/openstudio.exe"] + Dir["/usr/bin/openstudio"] + Dir["/usr/local/bin/openstudio"]
  if os_clis.size == 0
    puts "ERROR: Could not find the openstudio binary. You may need to install the OpenStudio Command Line Interface."
    exit
  end
  os_cli = os_clis[-1]

  log_str = ''
  if not show_debug
    # Redirect to a log file
    log_str = " >> \"#{osw_path.gsub('.osw','.log')}\""
  end

  command = "\"#{os_cli}\" run -w \"#{osw_path}\"#{log_str}"
  system(command)
  
  return File.join(File.dirname(osw_path), "run", "eplusout.sql")
  
end

def get_sql_query_result(sqlFile, query)
  result = sqlFile.execAndReturnFirstDouble(query)
  if result.is_initialized
    return OpenStudio::convert(result.get, "GJ", "MBtu").get
  end
  return 0
end

def parse_sql(design, sql_path, output_hpxml_path)
  if not File.exists?(sql_path)
    fail "ERROR: Simulation unsuccessful for #{design}."
  end
  
  sqlFile = OpenStudio::SqlFile.new(sql_path)
  
  sim_output = {}
  sim_output[:hpxml] = output_hpxml_path
  sim_output[:allTotal] = OpenStudio::convert(sqlFile.totalSiteEnergy.get, "GJ", "MBtu").get
  
  # Electricity categories
  sim_output[:elecTotal] = OpenStudio::convert(sqlFile.electricityTotalEndUses.get, "GJ", "MBtu").get
  sim_output[:elecHeating] = OpenStudio::convert(sqlFile.electricityHeating.get, "GJ", "MBtu").get
  sim_output[:elecCooling] = OpenStudio::convert(sqlFile.electricityCooling.get, "GJ", "MBtu").get
  sim_output[:elecIntLighting] = OpenStudio::convert(sqlFile.electricityInteriorLighting.get, "GJ", "MBtu").get
  sim_output[:elecExtLighting] = OpenStudio::convert(sqlFile.electricityExteriorLighting.get, "GJ", "MBtu").get
  sim_output[:elecEquipment] = OpenStudio::convert(sqlFile.electricityInteriorEquipment.get, "GJ", "MBtu").get
  sim_output[:elecFans] = OpenStudio::convert(sqlFile.electricityFans.get, "GJ", "MBtu").get
  sim_output[:elecPumps] = OpenStudio::convert(sqlFile.electricityPumps.get, "GJ", "MBtu").get
  sim_output[:elecHotWater] = OpenStudio::convert(sqlFile.electricityWaterSystems.get, "GJ", "MBtu").get
  
  # Fuel categories
  sim_output[:fuelTotal] = OpenStudio::convert(sqlFile.naturalGasTotalEndUses.get, "GJ", "MBtu").get + OpenStudio::convert(sqlFile.otherFuelTotalEndUses.get, "GJ", "MBtu").get
  sim_output[:fuelHeating] = OpenStudio::convert(sqlFile.naturalGasHeating.get, "GJ", "MBtu").get + OpenStudio::convert(sqlFile.otherFuelHeating.get, "GJ", "MBtu").get
  sim_output[:fuelEquipment] = OpenStudio::convert(sqlFile.naturalGasInteriorEquipment.get, "GJ", "MBtu").get + OpenStudio::convert(sqlFile.otherFuelInteriorEquipment.get, "GJ", "MBtu").get
  sim_output[:fuelHotWater] = OpenStudio::convert(sqlFile.naturalGasWaterSystems.get, "GJ", "MBtu").get + OpenStudio::convert(sqlFile.otherFuelWaterSystems.get, "GJ", "MBtu").get

  # Other - PV
  query = "SELECT -1*Value FROM TabularDataWithStrings WHERE ReportName='AnnualBuildingUtilityPerformanceSummary' AND ReportForString='Entire Facility' AND TableName='Electric Loads Satisfied' AND RowName='Total On-Site Electric Sources' AND ColumnName='Electricity' AND Units='GJ'"
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
  sim_output[:fuelClothesDryer] = get_sql_query_result(sqlFile, query)
  query = "SELECT Value FROM TabularDataWithStrings WHERE ReportName='EnergyMeters' AND ReportForString='Entire Facility' AND TableName='Annual and Peak Values - Other' AND RowName LIKE '#{Constants.ObjectNameClothesDryer(nil)}%' AND ColumnName='Annual Value' AND Units='GJ'"
  sim_output[:fuelClothesDryer] += get_sql_query_result(sqlFile, query)
  
  # Other - MELS
  query = "SELECT Value FROM TabularDataWithStrings WHERE ReportName='EnergyMeters' AND ReportForString='Entire Facility' AND TableName='Annual and Peak Values - Electricity' AND RowName LIKE '#{Constants.ObjectNameMiscPlugLoads}%' AND ColumnName='Electricity Annual Value' AND Units='GJ'"
  sim_output[:elecMELs] = get_sql_query_result(sqlFile, query)
  
  # Other - Range/Oven
  query = "SELECT Value FROM TabularDataWithStrings WHERE ReportName='EnergyMeters' AND ReportForString='Entire Facility' AND TableName='Annual and Peak Values - Electricity' AND RowName LIKE '#{Constants.ObjectNameCookingRange(nil)}%' AND ColumnName='Electricity Annual Value' AND Units='GJ'"
  sim_output[:elecRangeOven] = get_sql_query_result(sqlFile, query)
  query = "SELECT Value FROM TabularDataWithStrings WHERE ReportName='EnergyMeters' AND ReportForString='Entire Facility' AND TableName='Annual and Peak Values - Gas' AND RowName LIKE '#{Constants.ObjectNameCookingRange(nil)}%' AND ColumnName='Gas Annual Value' AND Units='GJ'"
  sim_output[:fuelRangeOven] = get_sql_query_result(sqlFile, query)
  query = "SELECT Value FROM TabularDataWithStrings WHERE ReportName='EnergyMeters' AND ReportForString='Entire Facility' AND TableName='Annual and Peak Values - Other' AND RowName LIKE '#{Constants.ObjectNameCookingRange(nil)}%' AND ColumnName='Annual Value' AND Units='GJ'"
  sim_output[:fuelRangeOven] += get_sql_query_result(sqlFile, query)
  
  # Other - Ceiling Fans
  query = "SELECT Value FROM TabularDataWithStrings WHERE ReportName='EnergyMeters' AND ReportForString='Entire Facility' AND TableName='Annual and Peak Values - Electricity' AND RowName LIKE '#{Constants.ObjectNameCeilingFan}%' AND ColumnName='Electricity Annual Value' AND Units='GJ'"
  sim_output[:elecCeilingFan] = get_sql_query_result(sqlFile, query)
  
  # Other - Mechanical Ventilation
  query = "SELECT Value FROM TabularDataWithStrings WHERE ReportName='EnergyMeters' AND ReportForString='Entire Facility' AND TableName='Annual and Peak Values - Electricity' AND RowName LIKE 'VentFans%' AND ColumnName='Electricity Annual Value' AND Units='GJ'"
  sim_output[:elecMechVent] = get_sql_query_result(sqlFile, query)
  
  # Error Checking
  tolerance = 0.1 # MMBtu
  
  sum_fuels = (sim_output[:elecTotal] + sim_output[:fuelTotal])
  if (sim_output[:allTotal] - sum_fuels).abs > tolerance
    fail "ERROR: Fuels do not sum to total."
  end
  
  sum_elec_categories = (sim_output[:elecHeating] + sim_output[:elecCooling] + 
                         sim_output[:elecIntLighting] + sim_output[:elecExtLighting] + 
                         sim_output[:elecEquipment] + sim_output[:elecFans] + 
                         sim_output[:elecPumps] + sim_output[:elecHotWater])
  if (sim_output[:elecTotal] - sum_elec_categories).abs > tolerance
    fail "ERROR: Electric category end uses do not sum to total."
  end
  
  sum_fuel_categories = (sim_output[:fuelHeating] + sim_output[:fuelEquipment] + 
                         sim_output[:fuelHotWater])
  if (sim_output[:fuelTotal] - sum_fuel_categories).abs > tolerance
    fail "ERROR: Fuel category end uses do not sum to total."
  end
  
  sum_elec_equips = (sim_output[:elecFridge] + sim_output[:elecDishwasher] +
                     sim_output[:elecClothesWasher] + sim_output[:elecClothesDryer] +
                     sim_output[:elecMELs] + sim_output[:elecRangeOven] +
                     sim_output[:elecCeilingFan] + sim_output[:elecMechVent])
  if (sim_output[:elecEquipment] - sum_elec_equips).abs > tolerance
    fail "ERROR: Electric equipments do not sum to total."
  end
  
  sum_fuel_equips = (sim_output[:fuelClothesDryer] + sim_output[:fuelRangeOven])
  if (sim_output[:fuelEquipment] - sum_fuel_equips).abs > tolerance
    fail "ERROR: Fuel equipments do not sum to total."
  end
  
  return sim_output
  
end

def get_cfa(hpxml_doc)
  cfa = XMLHelper.get_value(hpxml_doc, "//Building/BuildingDetails/BuildingSummary/BuildingConstruction/ConditionedFloorArea")
  
  if cfa.nil?
    fail "ERROR: Conditioned floor area not found."
  end
  
  return cfa.to_f
end

def get_nbr(hpxml_doc)
  nbr = XMLHelper.get_value(hpxml_doc, "//Building/BuildingDetails/BuildingSummary/BuildingConstruction/NumberofBedrooms")
  
  if nbr.nil?
    fail "ERROR: Number of bedrooms not found."
  end
  
  return nbr.to_i
end

def get_heating_fuel(hpxml_doc)
  heat_fuel = nil
  
  heating_system = hpxml_doc.elements["//Building/BuildingDetails/Systems/HVAC/HVACPlant/HeatingSystem"]
  heat_pump_system = hpxml_doc.elements["//Building/BuildingDetails/Systems/HVAC/HVACPlant/HeatPump"]
  
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
  
  dhw_system = hpxml_doc.elements["//Building/BuildingDetails/Systems/WaterHeating/WaterHeatingSystem"]
  
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
  
  heating_system = hpxml_doc.elements["//Building/BuildingDetails/Systems/HVAC/HVACPlant/HeatingSystem"]
  heat_pump_system = hpxml_doc.elements["//Building/BuildingDetails/Systems/HVAC/HVACPlant/HeatPump"]
  
  if heating_system.nil? and heat_pump_system.nil?
    fail "ERROR: No heating system found."
  elsif not heating_system.nil? and not heat_pump_system.nil?
    fail "ERROR: Multiple heating systems found."
  else
    sys = heating_system
    if sys.nil?
      sys = heat_pump_system
    end
    ['HSPF','COP','AFUE','Percent'].each do |unit|
      value = XMLHelper.get_value(sys, "AnnualHeatingEfficiency[Units='#{unit}']/Value")
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
  
  cooling_system = hpxml_doc.elements["//Building/BuildingDetails/Systems/HVAC/HVACPlant/CoolingSystem"]
  heat_pump_system = hpxml_doc.elements["//Building/BuildingDetails/Systems/HVAC/HVACPlant/HeatPump"]
  
  if cooling_system.nil? and heat_pump_system.nil?
    fail "ERROR: No cooling system found."
  elsif not cooling_system.nil? and not heat_pump_system.nil?
    fail "ERROR: Multiple cooling systems found."
  else
    sys = cooling_system
    if sys.nil?
      sys = heat_pump_system
    end
    ['SEER','COP','EER'].each do |unit|
      value = XMLHelper.get_value(sys, "AnnualCoolingEfficiency[Units='#{unit}']/Value")
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
  
  dhw_system = hpxml_doc.elements["//Building/BuildingDetails/Systems/WaterHeating/WaterHeatingSystem"]
  
  if dhw_system.nil?
    fail "ERROR: No water heating system found."
  else
    value = XMLHelper.get_value(dhw_system, "EnergyFactor")
    value_adj = XMLHelper.get_value(dhw_system, "extension/PerformanceAdjustmentEnergyFactor")
    if not value.nil? and not value_adj.nil?
      eec_dhw = get_eec_value_numerator('EF') / (value.to_f * value_adj.to_f)
    end
  end
  
  if eec_dhw.nil?
    fail "ERROR: No water heating system efficiency value found."
  end
  
  return eec_dhw
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
  results[:reul_heat] = ref_output[:elecHeating] + ref_output[:fuelHeating] # FIXME
  results[:reul_cool] = ref_output[:elecCooling] # FIXME
  results[:reul_dhw] = ref_output[:elecHotWater] + ref_output[:fuelHotWater] # FIXME
  
  # XEUL = Rated Home End Use Loads (for heating, cooling or hot water) as computed using an Approved 
  # Software Rating Tool.
  results[:xeul_heat] = rated_output[:elecHeating] + rated_output[:fuelHeating] # FIXME
  results[:xeul_cool] = rated_output[:elecCooling] # FIXME
  results[:xeul_dhw] = rated_output[:elecHotWater] + rated_output[:fuelHotWater] # FIXME
  
  # Table 4.2.1(1) Coefficients ‘a’ and ‘b’
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
  
  # EEC_x = Equipment Efficiency Coefficient for the Rated Home’s equipment, such that EEC_x equals the 
  # energy consumption per unit load in like units as the load, and as derived from the Manufacturer’s 
  # Equipment Performance Rating (MEPR) such that EEC_x equals 1.0 / MEPR for AFUE, COP or EF ratings, or 
  # such that EEC_x equals 3.413 / MEPR for HSPF, EER or SEER ratings.
  results[:eec_x_heat] = get_eec_heat(ref_hpxml_doc)
  results[:eec_x_cool] = get_eec_cool(ref_hpxml_doc)
  results[:eec_x_dhw] = get_eec_dhw(ref_hpxml_doc)
  
  # EEC_r = Equipment Efficiency Coefficient for the Reference Home’s equipment, such that EEC_r equals the 
  # energy consumption per unit load in like units as the load, and as derived from the Manufacturer’s 
  # Equipment Performance Rating (MEPR) such that EEC_r equals 1.0 / MEPR for AFUE, COP or EF ratings, or 
  # such that EEC_r equals 3.413 / MEPR for HSPF, EER or SEER ratings
  results[:eec_r_heat] = get_eec_heat(rated_hpxml_doc)
  results[:eec_r_cool] = get_eec_cool(rated_hpxml_doc)
  results[:eec_r_dhw] = get_eec_dhw(rated_hpxml_doc)
  
  # EC_x = estimated Energy Consumption for the Rated Home’s end uses (for heating, including Auxiliary 
  # Electric Consumption, cooling or hot water) as computed using an Approved Software Rating Tool.
  results[:ec_x_heat] = rated_output[:elecHeating] + rated_output[:fuelHeating]
  results[:ec_x_cool] = rated_output[:elecCooling]
  results[:ec_x_dhw] = rated_output[:elecHotWater] + rated_output[:fuelHotWater]
  
  # EC_r = estimated Energy Consumption for the Reference Home’s end uses (for heating, including Auxiliary 
  # Electric Consumption, cooling or hot water) as computed using an Approved Software Rating Tool.
  results[:ec_r_heat] = ref_output[:elecHeating] + ref_output[:fuelHeating]
  results[:ec_r_cool] = ref_output[:elecCooling]
  results[:ec_r_dhw] = ref_output[:elecHotWater] + ref_output[:fuelHotWater]
  
  # results[:ec_x_dhw] *= dhw_adjustment(ratedsim.water_distribution) # FIXME
  
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
  results[:nmeul_heat] = results[:reul_heat] * (results[:nec_x_heat] / results[:ec_r_heat])
  results[:nmeul_cool] = results[:reul_cool] * (results[:nec_x_cool] / results[:ec_r_cool])
  results[:nmeul_dhw] = results[:reul_dhw] * (results[:nec_x_dhw] / results[:ec_r_dhw])
      
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
                      rated_output[:elecEquipment] + rated_output[:fuelEquipment])
  
  # REULLA = The Reference Home end use loads for lighting, appliances and MELs as defined by Section 4.2.2.5.1, 
  # converted to MBtu/y, where MBtu/y = (kWh/y)/293 or (therms/y)/10, as appropriate.
  results[:reul_la] = (ref_output[:elecIntLighting] + ref_output[:elecExtLighting] + 
                       ref_output[:elecEquipment] + ref_output[:fuelEquipment])
  
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

def write_results(results, resultsdir, sim_outputs)

  # Results file
  results_csv = File.join(resultsdir, "results.csv")
  results_out = {
                 "HERS Index"=>results[:hers_index],
                 "REUL Heating (MBtu)"=>results[:reul_heat],
                 "REUL Cooling (MBtu)"=>results[:reul_cool],
                 "REUL Hot Water (MBtu)"=>results[:reul_dhw],
                 "EC_r Heating (MBtu)"=>results[:ec_r_heat],
                 "EC_r Cooling (MBtu)"=>results[:ec_r_cool],
                 "EC_r Hot Water (MBtu)"=>results[:ec_r_dhw],
                 "XEUL Heating (MBtu)"=>results[:xeul_heat],
                 "XEUL Cooling (MBtu)"=>results[:xeul_cool],
                 "XEUL Hot Water (MBtu)"=>results[:xeul_dhw],
                 "EC_x Heating (MBtu)"=>results[:ec_x_heat],
                 "EC_x Cooling (MBtu)"=>results[:ec_x_cool],
                 "EC_x Hot Water (MBtu)"=>results[:ec_x_dhw],
                 "EC_x L&A (MBtu)"=>results[:eul_la],
                }
  CSV.open(results_csv, "wb") {|csv| results_out.to_a.each {|elem| csv << elem} }
  
  # Worksheet file
  worksheet_csv = File.join(resultsdir, "worksheet.csv")
  ref_output = sim_outputs[Constants.CalcTypeERIReferenceHome]
  worksheet_out = {
                   "Coeff Heating a"=>results[:coeff_heat_a],
                   "Coeff Heating b"=>results[:coeff_heat_b],
                   "Coeff Cooling a"=>results[:coeff_cool_a],
                   "Coeff Cooling b"=>results[:coeff_cool_b],
                   "Coeff Hot Water a"=>results[:coeff_dhw_a],
                   "Coeff Hot Water b"=>results[:coeff_dhw_b],
                   "DSE_r Heating"=>results[:dse_r_heat],
                   "DSE_r Cooling"=>results[:dse_r_cool],
                   "DSE_r Hot Water"=>results[:dse_r_dhw],
                   "EEC_x Heating"=>results[:eec_x_heat],
                   "EEC_x Cooling"=>results[:eec_x_cool],
                   "EEC_x Hot Water"=>results[:eec_x_dhw],
                   "EEC_r Heating"=>results[:eec_r_heat],
                   "EEC_r Cooling"=>results[:eec_r_cool],
                   "EEC_r Hot Water"=>results[:eec_r_dhw],
                   "nEC_x Heating"=>results[:nec_x_heat],
                   "nEC_x Cooling"=>results[:nec_x_cool],
                   "nEC_x Hot Water"=>results[:nec_x_dhw],
                   "nMEUL Heating"=>results[:nmeul_heat],
                   "nMEUL Cooling"=>results[:nmeul_cool],
                   "nMEUL Hot Water"=>results[:nmeul_dhw],
                   "Total Loads TnML"=>results[:tnml],
                   "Total Loads TRL"=>results[:trl],
                   "HERS Index"=>results[:hers_index],
                   "Home CFA"=>results[:cfa],
                   "Home Nbr"=>results[:nbr],
                   "L&A resMELs"=>ref_output[:elecMELs],
                   "L&A intLgt"=>ref_output[:elecIntLighting],
                   "L&A extLgt"=>ref_output[:elecExtLighting],
                   "L&A Fridg"=>ref_output[:elecFridge],
                   "L&A TVs"=>0, # FIXME
                   "L&A R/O"=>(ref_output[:elecRangeOven]+ref_output[:fuelRangeOven]),
                   "L&A cDryer"=>(ref_output[:elecClothesDryer]+ref_output[:fuelClothesDryer]),
                   "L&A dWash"=>ref_output[:elecDishwasher],
                   "L&A cWash"=>ref_output[:elecClothesWasher],
                   "L&A total"=>results[:reul_la],
                  }
  CSV.open(worksheet_csv, "wb") {|csv| worksheet_out.to_a.each {|elem| csv << elem} }
  
end

options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: #{File.basename(__FILE__)} -x building.xml -w location.epw"

  opts.on('-x', '--xml <FILE>', 'HPXML file') do |t|
    options[:hpxml] = t
  end

  opts.on('-e', '--epw <FILE>', 'EPW weather file') do |t|
    options[:epw] = t
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

if not options[:epw]
  fail "ERROR: EWP weather file argument is required. Call #{File.basename(__FILE__)} -h for usage."
end

unless (Pathname.new options[:epw]).absolute?
  options[:epw] = File.expand_path(File.join(File.dirname(__FILE__), options[:epw]))
end
unless File.exists?(options[:epw]) and options[:epw].downcase.end_with? ".epw"
  fail "ERROR: '#{options[:epw]}' does not exist or is not an .epw file."
end
# FIXME: Need to require DDY as well?
    
# Create results dir
resultsdir = File.join(basedir, "results")
recreate_path(resultsdir)

# Run simulations
sim_outputs = {}
Parallel.map(designs, in_threads: designs.size) do |design|
  # Use print instead of puts in here (https://stackoverflow.com/a/5044669)
  
  print "[#{design}] Creating workflow...\n"
  osw_path, output_hpxml_path = create_osw(design, basedir, resultsdir, options)
  
  print "[#{design}] Running workflow...\n"
  sql_path = run_osw(osw_path)
  
  print "[#{design}] Gathering results...\n"
  sim_outputs[design] = parse_sql(design, sql_path, output_hpxml_path)
end

# Calculate and write results
puts "Calcuting ERI..."
results = calculate_eri(sim_outputs)

puts "Writing output files..."
write_results(results, resultsdir, sim_outputs)

puts "Output files written to '#{File.basename(resultsdir)}' directory."
puts "Completed in #{Time.now - start_time} seconds."