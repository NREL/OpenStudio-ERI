require_relative '../../../test/minitest_helper'
require 'openstudio'
require 'openstudio/ruleset/ShowRunnerOutput'
require 'minitest/autorun'
require_relative '../measure.rb'
require 'fileutils'

class ResidentialHotWaterHeaterTankFuelTest < MiniTest::Test

  def osm_geo_loc
    return "SFD_2000sqft_2story_FB_GRG_UA_Denver.osm"
  end
  
  def osm_geo_beds
    return "SFD_2000sqft_2story_FB_GRG_UA_3Beds_2Baths.osm"
  end

  def osm_geo_beds_loc
    return "SFD_2000sqft_2story_FB_GRG_UA_3Beds_2Baths_Denver.osm"
  end
  
  def osm_geo_beds_loc_1_1
    return "SFD_2000sqft_2story_FB_GRG_UA_1Beds_1Baths_Denver.osm"
  end

  def osm_geo_beds_loc_2_1
    return "SFD_2000sqft_2story_FB_GRG_UA_2Beds_1Baths_Denver.osm"
  end

  def osm_geo_beds_loc_2_2
    return "SFD_2000sqft_2story_FB_GRG_UA_2Beds_2Baths_Denver.osm"
  end

  def osm_geo_beds_loc_5_3
    return "SFD_2000sqft_2story_FB_GRG_UA_5Beds_3Baths_Denver.osm"
  end

  def osm_geo_beds_loc_tank_electric
    return "SFD_2000sqft_2story_FB_GRG_UA_3Beds_2Baths_Denver_ElecWHTank.osm"
  end

  def osm_geo_beds_loc_tankless_electric
    return "SFD_2000sqft_2story_FB_GRG_UA_3Beds_2Baths_Denver_ElecWHTankless.osm"
  end

  def osm_geo_beds_loc_tankless_gas
    return "SFD_2000sqft_2story_FB_GRG_UA_3Beds_2Baths_Denver_GasWHTankless.osm"
  end

  def osm_geo_beds_loc_tankless_propane
    return "SFD_2000sqft_2story_FB_GRG_UA_3Beds_2Baths_Denver_PropaneWHTankless.osm"
  end

  def test_new_construction_standard
    args_hash = {}
    args_hash["fuel_type"] = Constants.FuelTypeGas
    expected_num_del_objects = {}
    expected_num_new_objects = {"WaterHeaterMixed"=>1, "PlantLoop"=>1, "PumpVariableSpeed"=>1, "ScheduleRuleset"=>2}
    expected_values = {"TankVolume"=>40, "InputCapacity"=>11.72, "ThermalEfficiency"=>0.773, "TankUA"=>7.88, "Setpoint"=>125, "OnCycle"=>0, "OffCycle"=>0, "FuelType"=>Constants.FuelTypeGas, "SkinLossFrac"=>0.64}
    _test_measure(osm_geo_beds_loc, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 1)
  end
    
  def test_new_construction_premium
    args_hash = {}
    args_hash["energy_factor"] = "0.67"
    args_hash["recovery_efficiency"] = 0.78
    args_hash["capacity"] = "34"
    args_hash["oncyc_power"] = 165
    args_hash["offcyc_power"] = 1
    args_hash["fuel_type"] = Constants.FuelTypeGas
    expected_num_del_objects = {}
    expected_num_new_objects = {"WaterHeaterMixed"=>1, "PlantLoop"=>1, "PumpVariableSpeed"=>1, "ScheduleRuleset"=>2}
    expected_values = {"TankVolume"=>40, "InputCapacity"=>9.97, "ThermalEfficiency"=>0.789, "TankUA"=>4.503, "Setpoint"=>125, "OnCycle"=>165, "OffCycle"=>1, "FuelType"=>Constants.FuelTypeGas, "SkinLossFrac"=>0.91}
    _test_measure(osm_geo_beds_loc, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 1)
  end

  def test_new_construction_standard_auto_ef_and_capacity
    args_hash = {}
    args_hash["energy_factor"] = Constants.Auto
    args_hash["capacity"] = Constants.Auto
    args_hash["fuel_type"] = Constants.FuelTypeGas
    expected_num_del_objects = {}
    expected_num_new_objects = {"WaterHeaterMixed"=>1, "PlantLoop"=>1, "PumpVariableSpeed"=>1, "ScheduleRuleset"=>2}
    expected_values = {"TankVolume"=>40, "InputCapacity"=>10.55, "ThermalEfficiency"=>0.774, "TankUA"=>7.706, "Setpoint"=>125, "OnCycle"=>0, "OffCycle"=>0, "FuelType"=>Constants.FuelTypeGas, "SkinLossFrac"=>0.64}
    _test_measure(osm_geo_beds_loc, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 1)
  end
  
  def test_new_construction_standard_oil
    args_hash = {}
    args_hash["capacity"] = "90.0"
    args_hash["energy_factor"] = "0.62"
    args_hash["recovery_efficiency"] = 0.78
    args_hash["fuel_type"] = Constants.FuelTypeOil
    expected_num_del_objects = {}
    expected_num_new_objects = {"WaterHeaterMixed"=>1, "PlantLoop"=>1, "PumpVariableSpeed"=>1, "ScheduleRuleset"=>2}
    expected_values = {"TankVolume"=>40, "InputCapacity"=>26.38, "ThermalEfficiency"=>0.785, "TankUA"=>6.753, "Setpoint"=>125, "OnCycle"=>0, "OffCycle"=>0, "FuelType"=>Constants.FuelTypeOil, "SkinLossFrac"=>0.64}
    _test_measure(osm_geo_beds_loc, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 1)
  end
    
  def test_new_construction_premium_oil
    args_hash = {}
    args_hash["capacity"] = "104"
    args_hash["energy_factor"] = "0.68"
    args_hash["recovery_efficiency"] = 0.9
    args_hash["oncyc_power"] = 165
    args_hash["offcyc_power"] = 1
    args_hash["fuel_type"] = Constants.FuelTypeOil
    expected_num_del_objects = {}
    expected_num_new_objects = {"WaterHeaterMixed"=>1, "PlantLoop"=>1, "PumpVariableSpeed"=>1, "ScheduleRuleset"=>2}
    expected_values = {"TankVolume"=>40, "InputCapacity"=>30.48, "ThermalEfficiency"=>0.905, "TankUA"=>8.410, "Setpoint"=>125, "OnCycle"=>165, "OffCycle"=>1, "FuelType"=>Constants.FuelTypeOil, "SkinLossFrac"=>0.91}
    _test_measure(osm_geo_beds_loc, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 1)
  end

  def test_new_construction_standard_auto_ef_and_capacity_oil
    args_hash = {}
    args_hash["capacity"] = Constants.Auto
    args_hash["energy_factor"] = Constants.Auto
    args_hash["recovery_efficiency"] = 0.78
    args_hash["fuel_type"] = Constants.FuelTypeOil
    expected_num_del_objects = {}
    expected_num_new_objects = {"WaterHeaterMixed"=>1, "PlantLoop"=>1, "PumpVariableSpeed"=>1, "ScheduleRuleset"=>2}
    expected_values = {"TankVolume"=>40, "InputCapacity"=>10.55, "ThermalEfficiency"=>0.807, "TankUA"=>14.465, "Setpoint"=>125, "OnCycle"=>0, "OffCycle"=>0, "FuelType"=>Constants.FuelTypeOil, "SkinLossFrac"=>0.64}
    _test_measure(osm_geo_beds_loc, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 1)
  end

  def test_new_construction_standard_propane
    args_hash = {}
    args_hash["capacity"] = "47"
    args_hash["fuel_type"] = Constants.FuelTypePropane
    expected_num_del_objects = {}
    expected_num_new_objects = {"WaterHeaterMixed"=>1, "PlantLoop"=>1, "PumpVariableSpeed"=>1, "ScheduleRuleset"=>2}
    expected_values = {"TankVolume"=>40, "InputCapacity"=>13.78, "ThermalEfficiency"=>0.771, "TankUA"=>7.790, "Setpoint"=>125, "OnCycle"=>0, "OffCycle"=>0, "FuelType"=>Constants.FuelTypePropane, "SkinLossFrac"=>0.64}
    _test_measure(osm_geo_beds_loc, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 1)
  end
    
  def test_new_construction_premium_propane
    args_hash = {}
    args_hash["capacity"] = "47"
    args_hash["energy_factor"] = "0.67"
    args_hash["recovery_efficiency"] = 0.78
    args_hash["oncyc_power"] = 140
    args_hash["offcyc_power"] = 1
    args_hash["fuel_type"] = Constants.FuelTypePropane
    expected_num_del_objects = {}
    expected_num_new_objects = {"WaterHeaterMixed"=>1, "PlantLoop"=>1, "PumpVariableSpeed"=>1, "ScheduleRuleset"=>2}
    expected_values = {"TankVolume"=>40, "InputCapacity"=>13.78, "ThermalEfficiency"=>0.786, "TankUA"=>4.404, "Setpoint"=>125, "OnCycle"=>140, "OffCycle"=>1, "FuelType"=>Constants.FuelTypePropane, "SkinLossFrac"=>0.91}
    _test_measure(osm_geo_beds_loc, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 1)
  end

  def test_new_construction_standard_auto_ef_and_capacity_propane
    args_hash = {}
    args_hash["capacity"] = Constants.Auto
    args_hash["energy_factor"] = Constants.Auto
    args_hash["fuel_type"] = Constants.FuelTypePropane
    expected_num_del_objects = {}
    expected_num_new_objects = {"WaterHeaterMixed"=>1, "PlantLoop"=>1, "PumpVariableSpeed"=>1, "ScheduleRuleset"=>2}
    expected_values = {"TankVolume"=>40, "InputCapacity"=>10.55, "ThermalEfficiency"=>0.774, "TankUA"=>7.706, "Setpoint"=>125, "OnCycle"=>0, "OffCycle"=>0, "FuelType"=>Constants.FuelTypePropane, "SkinLossFrac"=>0.64}
    _test_measure(osm_geo_beds_loc, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 1)
  end

  def test_new_construction_standard_living
    args_hash = {}
    args_hash["location"] = Constants.LivingZone
    args_hash["fuel_type"] = Constants.FuelTypeGas
    expected_num_del_objects = {}
    expected_num_new_objects = {"WaterHeaterMixed"=>1, "PlantLoop"=>1, "PumpVariableSpeed"=>1, "ScheduleRuleset"=>2}
    expected_values = {"TankVolume"=>40, "InputCapacity"=>11.72, "ThermalEfficiency"=>0.773, "TankUA"=>7.88, "Setpoint"=>125, "OnCycle"=>0, "OffCycle"=>0, "FuelType"=>Constants.FuelTypeGas, "SkinLossFrac"=>0.64}
    _test_measure(osm_geo_beds_loc, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 1)
  end

  def test_new_construction_standard_setpoint_130
    args_hash = {}
    args_hash["setpoint_temp"] = 130
    args_hash["fuel_type"] = Constants.FuelTypeGas
    expected_num_del_objects = {}
    expected_num_new_objects = {"WaterHeaterMixed"=>1, "PlantLoop"=>1, "PumpVariableSpeed"=>1, "ScheduleRuleset"=>2}
    expected_values = {"TankVolume"=>40, "InputCapacity"=>11.72, "ThermalEfficiency"=>0.773, "TankUA"=>7.88, "Setpoint"=>130, "OnCycle"=>0, "OffCycle"=>0, "FuelType"=>Constants.FuelTypeGas, "SkinLossFrac"=>0.64}
    _test_measure(osm_geo_beds_loc, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 1)
  end

  def test_new_construction_standard_volume_30
    args_hash = {}
    args_hash["tank_volume"] = "30"
    args_hash["fuel_type"] = Constants.FuelTypeGas
    expected_num_del_objects = {}
    expected_num_new_objects = {"WaterHeaterMixed"=>1, "PlantLoop"=>1, "PumpVariableSpeed"=>1, "ScheduleRuleset"=>2}
    expected_values = {"TankVolume"=>30, "InputCapacity"=>11.72, "ThermalEfficiency"=>0.773, "TankUA"=>7.88, "Setpoint"=>125, "OnCycle"=>0, "OffCycle"=>0, "FuelType"=>Constants.FuelTypeGas, "SkinLossFrac"=>0.64}
    _test_measure(osm_geo_beds_loc, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 1)
  end

  def test_new_construction_beds_baths_1_1
    args_hash = {}
    args_hash["capacity"] = Constants.Auto
    args_hash["energy_factor"] = Constants.Auto
    args_hash["fuel_type"] = Constants.FuelTypeGas
    expected_num_del_objects = {}
    expected_num_new_objects = {"WaterHeaterMixed"=>1, "PlantLoop"=>1, "PumpVariableSpeed"=>1, "ScheduleRuleset"=>2}
    expected_values = {"TankVolume"=>30, "InputCapacity"=>10.55, "ThermalEfficiency"=>0.772, "TankUA"=>6.594, "Setpoint"=>125, "OnCycle"=>0, "OffCycle"=>0, "FuelType"=>Constants.FuelTypeGas, "SkinLossFrac"=>0.64}
    _test_measure(osm_geo_beds_loc_1_1, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 1)
  end

  def test_new_construction_beds_baths_2_1
    args_hash = {}
    args_hash["capacity"] = Constants.Auto
    args_hash["energy_factor"] = Constants.Auto
    args_hash["fuel_type"] = Constants.FuelTypeGas
    expected_num_del_objects = {}
    expected_num_new_objects = {"WaterHeaterMixed"=>1, "PlantLoop"=>1, "PumpVariableSpeed"=>1, "ScheduleRuleset"=>2}
    expected_values = {"TankVolume"=>30, "InputCapacity"=>10.55, "ThermalEfficiency"=>0.772, "TankUA"=>6.594, "Setpoint"=>125, "OnCycle"=>0, "OffCycle"=>0, "FuelType"=>Constants.FuelTypeGas, "SkinLossFrac"=>0.64}
    _test_measure(osm_geo_beds_loc_2_1, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 1)
  end

  def test_new_construction_beds_baths_2_2
    args_hash = {}
    args_hash["capacity"] = Constants.Auto
    args_hash["energy_factor"] = Constants.Auto
    args_hash["fuel_type"] = Constants.FuelTypeGas
    expected_num_del_objects = {}
    expected_num_new_objects = {"WaterHeaterMixed"=>1, "PlantLoop"=>1, "PumpVariableSpeed"=>1, "ScheduleRuleset"=>2}
    expected_values = {"TankVolume"=>30, "InputCapacity"=>10.55, "ThermalEfficiency"=>0.772, "TankUA"=>6.594, "Setpoint"=>125, "OnCycle"=>0, "OffCycle"=>0, "FuelType"=>Constants.FuelTypeGas, "SkinLossFrac"=>0.64}
    _test_measure(osm_geo_beds_loc_2_2, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 1)
  end

  def test_new_construction_beds_baths_5_3
    args_hash = {}
    args_hash["capacity"] = Constants.Auto
    args_hash["energy_factor"] = Constants.Auto
    args_hash["fuel_type"] = Constants.FuelTypeGas
    expected_num_del_objects = {}
    expected_num_new_objects = {"WaterHeaterMixed"=>1, "PlantLoop"=>1, "PumpVariableSpeed"=>1, "ScheduleRuleset"=>2}
    expected_values = {"TankVolume"=>50, "InputCapacity"=>13.78, "ThermalEfficiency"=>0.773, "TankUA"=>8.713, "Setpoint"=>125, "OnCycle"=>0, "OffCycle"=>0, "FuelType"=>Constants.FuelTypeGas, "SkinLossFrac"=>0.64}
    _test_measure(osm_geo_beds_loc_5_3, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 1)
  end

  def test_retrofit_replace
    args_hash = {}
    args_hash["fuel_type"] = Constants.FuelTypeGas
    expected_num_del_objects = {}
    expected_num_new_objects = {"WaterHeaterMixed"=>1, "PlantLoop"=>1, "PumpVariableSpeed"=>1, "ScheduleRuleset"=>2}
    expected_values = {"TankVolume"=>40, "InputCapacity"=>11.72, "ThermalEfficiency"=>0.773, "TankUA"=>7.88, "Setpoint"=>125, "OnCycle"=>0, "OffCycle"=>0, "FuelType"=>Constants.FuelTypeGas, "SkinLossFrac"=>0.64}
    model = _test_measure(osm_geo_beds_loc, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 1)
    args_hash = {}
    args_hash["energy_factor"] = "0.67"
    args_hash["recovery_efficiency"] = 0.78
    args_hash["capacity"] = "34"
    args_hash["oncyc_power"] = 165
    args_hash["offcyc_power"] = 1
    args_hash["setpoint_temp"] = 130
    args_hash["fuel_type"] = Constants.FuelTypeGas
    expected_num_del_objects = {"WaterHeaterMixed"=>1, "ScheduleRuleset"=>1}
    expected_num_new_objects = {"WaterHeaterMixed"=>1, "ScheduleRuleset"=>1}
    expected_values = {"TankVolume"=>40, "InputCapacity"=>9.97, "ThermalEfficiency"=>0.789, "TankUA"=>4.503, "Setpoint"=>130, "OnCycle"=>165, "OffCycle"=>1, "FuelType"=>Constants.FuelTypeGas, "SkinLossFrac"=>0.91}
    _test_measure(model, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 1)
  end
  
  def test_retrofit_replace_tank_electric
    args_hash = {}
    args_hash["fuel_type"] = Constants.FuelTypeGas
    expected_num_del_objects = {"WaterHeaterMixed"=>1, "ScheduleRuleset"=>1}
    expected_num_new_objects = {"WaterHeaterMixed"=>1, "ScheduleRuleset"=>1}
    expected_values = {"TankVolume"=>40, "InputCapacity"=>11.72, "ThermalEfficiency"=>0.773, "TankUA"=>7.88, "Setpoint"=>125, "OnCycle"=>0, "OffCycle"=>0, "FuelType"=>Constants.FuelTypeGas, "SkinLossFrac"=>0.64}
    _test_measure(osm_geo_beds_loc_tank_electric, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 1)
  end

  def test_retrofit_replace_tankless_electric
    args_hash = {}
    args_hash["fuel_type"] = Constants.FuelTypeGas
    expected_num_del_objects = {"WaterHeaterMixed"=>1, "ScheduleRuleset"=>1}
    expected_num_new_objects = {"WaterHeaterMixed"=>1, "ScheduleRuleset"=>1}
    expected_values = {"TankVolume"=>40, "InputCapacity"=>11.72, "ThermalEfficiency"=>0.773, "TankUA"=>7.88, "Setpoint"=>125, "OnCycle"=>0, "OffCycle"=>0, "FuelType"=>Constants.FuelTypeGas, "SkinLossFrac"=>0.64}
    _test_measure(osm_geo_beds_loc_tankless_electric, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 1)
  end

  def test_retrofit_replace_tankless_gas
    args_hash = {}
    args_hash["fuel_type"] = Constants.FuelTypeGas
    expected_num_del_objects = {"WaterHeaterMixed"=>1, "ScheduleRuleset"=>1}
    expected_num_new_objects = {"WaterHeaterMixed"=>1, "ScheduleRuleset"=>1}
    expected_values = {"TankVolume"=>40, "InputCapacity"=>11.72, "ThermalEfficiency"=>0.773, "TankUA"=>7.88, "Setpoint"=>125, "OnCycle"=>0, "OffCycle"=>0, "FuelType"=>Constants.FuelTypeGas, "SkinLossFrac"=>0.64}
    _test_measure(osm_geo_beds_loc_tankless_gas, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 1)
  end

  def test_retrofit_replace_tankless_propane
    args_hash = {}
    args_hash["fuel_type"] = Constants.FuelTypeGas
    expected_num_del_objects = {"WaterHeaterMixed"=>1, "ScheduleRuleset"=>1}
    expected_num_new_objects = {"WaterHeaterMixed"=>1, "ScheduleRuleset"=>1}
    expected_values = {"TankVolume"=>40, "InputCapacity"=>11.72, "ThermalEfficiency"=>0.773, "TankUA"=>7.88, "Setpoint"=>125, "OnCycle"=>0, "OffCycle"=>0, "FuelType"=>Constants.FuelTypeGas, "SkinLossFrac"=>0.64}
    _test_measure(osm_geo_beds_loc_tankless_propane, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 1)
  end

  def test_argument_error_tank_volume_invalid_str
    args_hash = {}
    args_hash["tank_volume"] = "test"
    result = _test_error(osm_geo_beds_loc, args_hash)
    assert_equal(result.errors.map{ |x| x.logMessage }[0], "Storage tank volume must be greater than 0 or #{Constants.Auto}.")
  end
  
  def test_argument_error_tank_volume_lt_0
    args_hash = {}
    args_hash["tank_volume"] = "-10"
    result = _test_error(osm_geo_beds_loc, args_hash)
    assert_equal(result.errors.map{ |x| x.logMessage }[0], "Storage tank volume must be greater than 0 or #{Constants.Auto}.")
  end

  def test_argument_error_tank_volume_eq_0
    args_hash = {}
    args_hash["tank_volume"] = "0"
    result = _test_error(osm_geo_beds_loc, args_hash)
    assert_equal(result.errors.map{ |x| x.logMessage }[0], "Storage tank volume must be greater than 0 or #{Constants.Auto}.")
  end

  def test_argument_error_setpoint_lt_0
    args_hash = {}
    args_hash["setpoint_temp"] = -10
    result = _test_error(osm_geo_beds_loc, args_hash)
    assert_equal(result.errors.map{ |x| x.logMessage }[0], "Hot water temperature must be greater than 0 and less than 212.")
  end

  def test_argument_error_setpoint_lg_300
    args_hash = {}
    args_hash["setpoint_temp"] = 300
    result = _test_error(osm_geo_beds_loc, args_hash)
    assert_equal(result.errors.map{ |x| x.logMessage }[0], "Hot water temperature must be greater than 0 and less than 212.")
  end

  def test_argument_error_capacity_invalid_str
    args_hash = {}
    args_hash["capacity"] = "test"
    result = _test_error(osm_geo_beds_loc, args_hash)
    assert_equal(result.errors.map{ |x| x.logMessage }[0], "Nominal capacity must be greater than 0 or #{Constants.Auto}.")
  end

  def test_argument_error_capacity_lt_0
    args_hash = {}
    args_hash["capacity"] = "-10"
    result = _test_error(osm_geo_beds_loc, args_hash)
    assert_equal(result.errors.map{ |x| x.logMessage }[0], "Nominal capacity must be greater than 0 or #{Constants.Auto}.")
  end

  def test_argument_error_capacity_eq_0
    args_hash = {}
    args_hash["capacity"] = "0"
    result = _test_error(osm_geo_beds_loc, args_hash)
    assert_equal(result.errors.map{ |x| x.logMessage }[0], "Nominal capacity must be greater than 0 or #{Constants.Auto}.")
  end
  
  def test_argument_error_re_lt_0
    args_hash = {}
    args_hash["recovery_efficiency"] = -1
    result = _test_error(osm_geo_beds_loc, args_hash)
    assert_equal(result.errors.map{ |x| x.logMessage }[0], "Recovery efficiency must be at least 0 and at most 1.")
  end

  def test_argument_error_re_gt_1
    args_hash = {}
    args_hash["recovery_efficiency"] = 1.1
    result = _test_error(osm_geo_beds_loc, args_hash)
    assert_equal(result.errors.map{ |x| x.logMessage }[0], "Recovery efficiency must be at least 0 and at most 1.")
  end

  def test_argument_error_ef_invalid_str
    args_hash = {}
    args_hash["energy_factor"] = "test"
    result = _test_error(osm_geo_beds_loc, args_hash)
    assert_equal(result.errors.map{ |x| x.logMessage }[0], "Rated energy factor must be greater than 0 and less than 1, or #{Constants.Auto}.")
  end

  def test_argument_error_ef_lt_0
    args_hash = {}
    args_hash["energy_factor"] = "-10"
    result = _test_error(osm_geo_beds_loc, args_hash)
    assert_equal(result.errors.map{ |x| x.logMessage }[0], "Rated energy factor must be greater than 0 and less than 1, or #{Constants.Auto}.")
  end

  def test_argument_error_ef_eq_0
    args_hash = {}
    args_hash["energy_factor"] = "0"
    result = _test_error(osm_geo_beds_loc, args_hash)
    assert_equal(result.errors.map{ |x| x.logMessage }[0], "Rated energy factor must be greater than 0 and less than 1, or #{Constants.Auto}.")
  end

  def test_argument_error_ef_gt_1
    args_hash = {}
    args_hash["energy_factor"] = "1.1"
    result = _test_error(osm_geo_beds_loc, args_hash)
    assert_equal(result.errors.map{ |x| x.logMessage }[0], "Rated energy factor must be greater than 0 and less than 1, or #{Constants.Auto}.")
  end
  
  def test_argument_error_oncycle_lt_0
    args_hash = {}
    args_hash["oncyc_power"] = -1
    result = _test_error(osm_geo_beds_loc, args_hash)
    assert_equal(result.errors.map{ |x| x.logMessage }[0], "Forced draft fan power must be greater than 0.")
  end

  def test_argument_error_offcycle_lt_0
    args_hash = {}
    args_hash["offcyc_power"] = -1
    result = _test_error(osm_geo_beds_loc, args_hash)
    assert_equal(result.errors.map{ |x| x.logMessage }[0], "Parasitic electricity power must be greater than 0.")
  end

  def test_error_missing_geometry
    args_hash = {}
    result = _test_error(nil, args_hash)
    assert_equal(result.errors.map{ |x| x.logMessage }[0], "No building geometry has been defined.")
  end
  
  def test_error_missing_beds
    args_hash = {}
    result = _test_error(osm_geo_loc, args_hash)
    assert_equal(result.errors.map{ |x| x.logMessage }[0], "Could not determine number of bedrooms or bathrooms. Run the 'Add Residential Bedrooms And Bathrooms' measure first.")
  end
  
  def test_error_missing_mains_temp
    args_hash = {}
    result = _test_error(osm_geo_beds, args_hash)
    assert_equal(result.errors.map{ |x| x.logMessage }[0], "Mains water temperature has not been set.")
  end
  
  def test_single_family_attached_new_construction
    num_units = 4
    args_hash = {}
    expected_num_del_objects = {}
    expected_num_new_objects = {"WaterHeaterMixed"=>num_units, "PlantLoop"=>num_units, "PumpVariableSpeed"=>num_units, "ScheduleRuleset"=>2*num_units}
    expected_values = {"TankVolume"=>num_units*40, "InputCapacity"=>num_units*11.72, "ThermalEfficiency"=>num_units*0.773, "TankUA"=>num_units*7.88, "Setpoint"=>num_units*125, "OnCycle"=>0, "OffCycle"=>0, "FuelType"=>Constants.FuelTypeGas, "SkinLossFrac"=>num_units*0.64}
    _test_measure("SFA_4units_1story_FB_UA_3Beds_2Baths_Denver.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, num_units)
  end

  def test_single_family_attached_new_construction_living_zone
    num_units = 4
    args_hash = {}
    args_hash["location"] = Constants.LivingZone
    expected_num_del_objects = {}
    expected_num_new_objects = {"WaterHeaterMixed"=>1, "PlantLoop"=>1, "PumpVariableSpeed"=>1, "ScheduleRuleset"=>2}
    expected_values = {"TankVolume"=>40, "InputCapacity"=>11.72, "ThermalEfficiency"=>0.773, "TankUA"=>7.88, "Setpoint"=>125, "OnCycle"=>0, "OffCycle"=>0, "FuelType"=>Constants.FuelTypeGas, "SkinLossFrac"=>0.64}
    _test_measure("SFA_4units_1story_FB_UA_3Beds_2Baths_Denver.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 1)
  end  
  
  def test_multifamily_new_construction
    num_units = 8
    args_hash = {}
    expected_num_del_objects = {}
    expected_num_new_objects = {"WaterHeaterMixed"=>num_units, "PlantLoop"=>num_units, "PumpVariableSpeed"=>num_units, "ScheduleRuleset"=>2*num_units}
    expected_values = {"TankVolume"=>num_units*40, "InputCapacity"=>num_units*11.72, "ThermalEfficiency"=>num_units*0.773, "TankUA"=>num_units*7.88, "Setpoint"=>num_units*125, "OnCycle"=>0, "OffCycle"=>0, "FuelType"=>Constants.FuelTypeGas, "SkinLossFrac"=>num_units*0.64}
    _test_measure("MF_8units_1story_SL_3Beds_2Baths_Denver.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, num_units)
  end
  
  private
  
  def _test_error(osm_file, args_hash)
    # create an instance of the measure
    measure = ResidentialHotWaterHeaterTankFuel.new

    # create an instance of a runner
    runner = OpenStudio::Ruleset::OSRunner.new

    model = get_model(File.dirname(__FILE__), osm_file)

    # get arguments
    arguments = measure.arguments(model)
    argument_map = OpenStudio::Ruleset.convertOSArgumentVectorToMap(arguments)

    # populate argument with specified hash value if specified
    arguments.each do |arg|
      temp_arg_var = arg.clone
      if args_hash[arg.name]
        assert(temp_arg_var.setValue(args_hash[arg.name]))
      end
      argument_map[arg.name] = temp_arg_var
    end

    # run the measure
    measure.run(model, runner, argument_map)
    result = runner.result

    # show the output
    #show_output(result)

    # assert that it didn't run
    assert_equal("Fail", result.value.valueName)
    assert(result.errors.size == 1)
    
    return result
  end

  def _test_measure(osm_file_or_model, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, num_infos=0, num_warnings=0)
    # create an instance of the measure
    measure = ResidentialHotWaterHeaterTankFuel.new

    # check for standard methods
    assert(!measure.name.empty?)
    assert(!measure.description.empty?)
    assert(!measure.modeler_description.empty?)

    # create an instance of a runner
    runner = OpenStudio::Ruleset::OSRunner.new
    
    model = get_model(File.dirname(__FILE__), osm_file_or_model)

    # get the initial objects in the model
    initial_objects = get_objects(model)

    # get arguments
    arguments = measure.arguments(model)
    argument_map = OpenStudio::Ruleset.convertOSArgumentVectorToMap(arguments)

    # populate argument with specified hash value if specified
    arguments.each do |arg|
      temp_arg_var = arg.clone
      if args_hash[arg.name]
        assert(temp_arg_var.setValue(args_hash[arg.name]))
      end
      argument_map[arg.name] = temp_arg_var
    end

    # run the measure
    measure.run(model, runner, argument_map)
    result = runner.result

    # show the output
    #show_output(result)

    # assert that it ran correctly
    assert_equal("Success", result.value.valueName)
    assert(result.info.size == num_infos)
    assert(result.warnings.size == num_warnings)
    assert(result.finalCondition.is_initialized)
    
    # get the final objects in the model
    final_objects = get_objects(model)
    
    # get new and deleted objects
    obj_type_exclusions = ["ConnectorMixer", "ConnectorSplitter", "Node", "SetpointManagerScheduled", "ScheduleDay", "PipeAdiabatic", "ScheduleTypeLimits", "SizingPlant"]
    all_new_objects = get_object_additions(initial_objects, final_objects, obj_type_exclusions)
    all_del_objects = get_object_additions(final_objects, initial_objects, obj_type_exclusions)
    
    # check we have the expected number of new/deleted objects
    check_num_objects(all_new_objects, expected_num_new_objects, "added")
    check_num_objects(all_del_objects, expected_num_del_objects, "deleted")

    actual_values = {"TankVolume"=>0, "InputCapacity"=>0, "ThermalEfficiency"=>0, "TankUA1"=>0, "TankUA2"=>0, "Setpoint"=>0, "OnCycle"=>0, "OffCycle"=>0, "SkinLossFrac"=>0}
    all_new_objects.each do |obj_type, new_objects|
        new_objects.each do |new_object|
            next if not new_object.respond_to?("to_#{obj_type}")
            new_object = new_object.public_send("to_#{obj_type}").get
            if obj_type == "WaterHeaterMixed" or obj_type == "WaterHeaterStratified" or obj_type == "WaterHeaterHeatPump"
                actual_values["TankVolume"] += OpenStudio.convert(new_object.tankVolume.get, "m^3", "gal").get
                actual_values["InputCapacity"] += OpenStudio.convert(new_object.heaterMaximumCapacity.get, "W", "kW").get
                actual_values["ThermalEfficiency"] += new_object.heaterThermalEfficiency.get
                actual_values["TankUA1"] += OpenStudio::convert(new_object.onCycleLossCoefficienttoAmbientTemperature.get, "W/K", "Btu/hr*R").get
                actual_values["TankUA2"] += OpenStudio::convert(new_object.offCycleLossCoefficienttoAmbientTemperature.get, "W/K", "Btu/hr*R").get
                actual_values["Setpoint"] += Waterheater.get_water_heater_setpoint(model, new_object.plantLoop.get, nil)
                actual_values["OnCycle"] += new_object.onCycleParasiticFuelConsumptionRate
                actual_values["OffCycle"] += new_object.offCycleParasiticFuelConsumptionRate
                assert_equal(HelperMethods.eplus_fuel_map(expected_values["FuelType"]), new_object.heaterFuelType)
                actual_values["SkinLossFrac"] += new_object.offCycleLossFractiontoThermalZone
            end
        end
    end
    assert_in_epsilon(Waterheater.calc_actual_tankvol(expected_values["TankVolume"], args_hash["fuel_type"], Constants.WaterHeaterTypeTank), actual_values["TankVolume"], 0.01)
    assert_in_epsilon(expected_values["InputCapacity"], actual_values["InputCapacity"], 0.01)
    assert_in_epsilon(expected_values["ThermalEfficiency"], actual_values["ThermalEfficiency"], 0.01)
    assert_in_epsilon(expected_values["TankUA"], actual_values["TankUA1"], 0.01)
    assert_in_epsilon(expected_values["TankUA"], actual_values["TankUA2"], 0.01)
    assert_in_epsilon(expected_values["Setpoint"], actual_values["Setpoint"], 0.01)
    assert_in_epsilon(expected_values["OnCycle"], actual_values["OnCycle"], 0.01)
    assert_in_epsilon(expected_values["OffCycle"], actual_values["OffCycle"], 0.01)
    assert_in_epsilon(expected_values["SkinLossFrac"], actual_values["SkinLossFrac"], 0.01)

    return model
  end
  
end
