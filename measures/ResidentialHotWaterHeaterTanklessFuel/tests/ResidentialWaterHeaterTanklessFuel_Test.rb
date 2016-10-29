require_relative '../../../test/minitest_helper'
require 'openstudio'
require 'openstudio/ruleset/ShowRunnerOutput'
require 'minitest/autorun'
require_relative '../measure.rb'
require 'fileutils'

class ResidentialHotWaterHeaterTanklessFuelTest < MiniTest::Test

  def osm_geo_loc
    return "2000sqft_2story_FB_GRG_UA_Denver.osm"
  end
  
  def osm_geo_beds
    return "2000sqft_2story_FB_GRG_UA_3Beds_2Baths.osm"
  end

  def osm_geo_beds_loc
    return "2000sqft_2story_FB_GRG_UA_3Beds_2Baths_Denver.osm"
  end
  
  def osm_geo_beds_loc_tank_gas
    return "2000sqft_2story_FB_GRG_UA_3Beds_2Baths_Denver_TankGas.osm"
  end

  def osm_geo_beds_loc_tank_oil
    return "2000sqft_2story_FB_GRG_UA_3Beds_2Baths_Denver_TankOil.osm"
  end

  def osm_geo_beds_loc_tank_propane
    return "2000sqft_2story_FB_GRG_UA_3Beds_2Baths_Denver_TankPropane.osm"
  end

  def osm_geo_beds_loc_tank_electric
    return "2000sqft_2story_FB_GRG_UA_3Beds_2Baths_Denver_TankElectric.osm"
  end

  def osm_geo_beds_loc_tankless_electric
    return "2000sqft_2story_FB_GRG_UA_3Beds_2Baths_Denver_TanklessElectric.osm"
  end

  def osm_geo_multifamily_3_units_beds_loc
    return "multifamily_3_units_Beds_Baths_Denver.osm"
  end

  def osm_geo_multifamily_12_units_beds_loc
    return "multifamily_12_units_Beds_Baths_Denver.osm"
  end

  def test_new_construction_standard
    args_hash = {}
    args_hash["fuel_type"] = Constants.FuelTypeGas
    expected_num_del_objects = {}
    expected_num_new_objects = {"WaterHeaterMixed"=>1, "PlantLoop"=>1, "PumpVariableSpeed"=>1, "ScheduleRuleset"=>2}
    expected_values = {"InputCapacity"=>29307107, "ThermalEfficiency"=>0.754, "Setpoint"=>125, "OnCycle"=>7.38, "OffCycle"=>7.38, "FuelType"=>Constants.FuelTypeGas}
    _test_measure(osm_geo_beds_loc, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 1)
  end
    
  def test_new_construction_standard_propane
    args_hash = {}
    args_hash["fuel_type"] = Constants.FuelTypePropane
    expected_num_del_objects = {}
    expected_num_new_objects = {"WaterHeaterMixed"=>1, "PlantLoop"=>1, "PumpVariableSpeed"=>1, "ScheduleRuleset"=>2}
    expected_values = {"InputCapacity"=>29307107, "ThermalEfficiency"=>0.754, "Setpoint"=>125, "OnCycle"=>7.38, "OffCycle"=>7.38, "FuelType"=>Constants.FuelTypePropane}
    _test_measure(osm_geo_beds_loc, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 1)
  end
    
  def test_new_construction_standard_living
    args_hash = {}
    args_hash["location"] = Constants.LivingZone
    args_hash["fuel_type"] = Constants.FuelTypeGas
    expected_num_del_objects = {}
    expected_num_new_objects = {"WaterHeaterMixed"=>1, "PlantLoop"=>1, "PumpVariableSpeed"=>1, "ScheduleRuleset"=>2}
    expected_values = {"InputCapacity"=>29307107, "ThermalEfficiency"=>0.754, "Setpoint"=>125, "OnCycle"=>7.38, "OffCycle"=>7.38, "FuelType"=>Constants.FuelTypeGas}
    _test_measure(osm_geo_beds_loc, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 1)
  end

  def test_new_construction_standard_setpoint_130
    args_hash = {}
    args_hash["setpoint_temp"] = 130
    args_hash["fuel_type"] = Constants.FuelTypeGas
    expected_num_del_objects = {}
    expected_num_new_objects = {"WaterHeaterMixed"=>1, "PlantLoop"=>1, "PumpVariableSpeed"=>1, "ScheduleRuleset"=>2}
    expected_values = {"InputCapacity"=>29307107, "ThermalEfficiency"=>0.754, "Setpoint"=>130, "OnCycle"=>7.38, "OffCycle"=>7.38, "FuelType"=>Constants.FuelTypeGas}
    _test_measure(osm_geo_beds_loc, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 1)
  end

  def test_new_construction_standard_cd_0
    args_hash = {}
    args_hash["water_heater_cycling_derate"] = 0
    args_hash["fuel_type"] = Constants.FuelTypeGas
    expected_num_del_objects = {}
    expected_num_new_objects = {"WaterHeaterMixed"=>1, "PlantLoop"=>1, "PumpVariableSpeed"=>1, "ScheduleRuleset"=>2}
    expected_values = {"InputCapacity"=>29307107, "ThermalEfficiency"=>0.82, "Setpoint"=>125, "OnCycle"=>7.38, "OffCycle"=>7.38, "FuelType"=>Constants.FuelTypeGas}
    _test_measure(osm_geo_beds_loc, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 1)
  end

  def test_retrofit_replace
    args_hash = {}
    args_hash["fuel_type"] = Constants.FuelTypeGas
    expected_num_del_objects = {}
    expected_num_new_objects = {"WaterHeaterMixed"=>1, "PlantLoop"=>1, "PumpVariableSpeed"=>1, "ScheduleRuleset"=>2}
    expected_values = {"InputCapacity"=>29307107, "ThermalEfficiency"=>0.754, "Setpoint"=>125, "OnCycle"=>7.38, "OffCycle"=>7.38, "FuelType"=>Constants.FuelTypeGas}
    model = _test_measure(osm_geo_beds_loc, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 1)
    args_hash = {}
    args_hash["energy_factor"] = 0.96
    args_hash["setpoint_temp"] = 130
    args_hash["fuel_type"] = Constants.FuelTypeGas
    expected_num_del_objects = {"WaterHeaterMixed"=>1, "ScheduleRuleset"=>1}
    expected_num_new_objects = {"WaterHeaterMixed"=>1, "ScheduleRuleset"=>1}
    expected_values = {"InputCapacity"=>29307107, "ThermalEfficiency"=>0.883, "Setpoint"=>130, "OnCycle"=>7.38, "OffCycle"=>7.38, "FuelType"=>Constants.FuelTypeGas}
    _test_measure(model, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 1)
  end
  
  def test_retrofit_replace_tank_gas
    args_hash = {}
    args_hash["fuel_type"] = Constants.FuelTypeGas
    expected_num_del_objects = {"WaterHeaterMixed"=>1, "ScheduleRuleset"=>1}
    expected_num_new_objects = {"WaterHeaterMixed"=>1, "ScheduleRuleset"=>1}
    expected_values = {"InputCapacity"=>29307107, "ThermalEfficiency"=>0.754, "Setpoint"=>125, "OnCycle"=>7.38, "OffCycle"=>7.38, "FuelType"=>Constants.FuelTypeGas}
    _test_measure(osm_geo_beds_loc_tank_gas, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 1)
  end

  def test_retrofit_replace_tank_oil
    args_hash = {}
    args_hash["fuel_type"] = Constants.FuelTypeGas
    expected_num_del_objects = {"WaterHeaterMixed"=>1, "ScheduleRuleset"=>1}
    expected_num_new_objects = {"WaterHeaterMixed"=>1, "ScheduleRuleset"=>1}
    expected_values = {"InputCapacity"=>29307107, "ThermalEfficiency"=>0.754, "Setpoint"=>125, "OnCycle"=>7.38, "OffCycle"=>7.38, "FuelType"=>Constants.FuelTypeGas}
    _test_measure(osm_geo_beds_loc_tank_oil, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 1)
  end

  def test_retrofit_replace_tank_propane
    args_hash = {}
    args_hash["fuel_type"] = Constants.FuelTypeGas
    expected_num_del_objects = {"WaterHeaterMixed"=>1, "ScheduleRuleset"=>1}
    expected_num_new_objects = {"WaterHeaterMixed"=>1, "ScheduleRuleset"=>1}
    expected_values = {"InputCapacity"=>29307107, "ThermalEfficiency"=>0.754, "Setpoint"=>125, "OnCycle"=>7.38, "OffCycle"=>7.38, "FuelType"=>Constants.FuelTypeGas}
    _test_measure(osm_geo_beds_loc_tank_propane, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 1)
  end

  def test_retrofit_replace_tank_electric
    args_hash = {}
    args_hash["fuel_type"] = Constants.FuelTypeGas
    expected_num_del_objects = {"WaterHeaterMixed"=>1, "ScheduleRuleset"=>1}
    expected_num_new_objects = {"WaterHeaterMixed"=>1, "ScheduleRuleset"=>1}
    expected_values = {"InputCapacity"=>29307107, "ThermalEfficiency"=>0.754, "Setpoint"=>125, "OnCycle"=>7.38, "OffCycle"=>7.38, "FuelType"=>Constants.FuelTypeGas}
    _test_measure(osm_geo_beds_loc_tank_electric, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 1)
  end

  def test_retrofit_replace_tankless_electric
    args_hash = {}
    args_hash["fuel_type"] = Constants.FuelTypeGas
    expected_num_del_objects = {"WaterHeaterMixed"=>1, "ScheduleRuleset"=>1}
    expected_num_new_objects = {"WaterHeaterMixed"=>1, "ScheduleRuleset"=>1}
    expected_values = {"InputCapacity"=>29307107, "ThermalEfficiency"=>0.754, "Setpoint"=>125, "OnCycle"=>7.38, "OffCycle"=>7.38, "FuelType"=>Constants.FuelTypeGas}
    _test_measure(osm_geo_beds_loc_tankless_electric, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 1)
  end

  def test_multifamily_new_construction
    num_units = 3
    args_hash = {}
    args_hash["fuel_type"] = Constants.FuelTypeGas
    expected_num_del_objects = {}
    expected_num_new_objects = {"WaterHeaterMixed"=>num_units, "PlantLoop"=>num_units, "PumpVariableSpeed"=>num_units, "ScheduleRuleset"=>2*num_units}
    expected_values = {"InputCapacity"=>87921321, "ThermalEfficiency"=>2.262, "Setpoint"=>375, "OnCycle"=>21.76, "OffCycle"=>21.76, "FuelType"=>Constants.FuelTypeGas}
    _test_measure(osm_geo_multifamily_3_units_beds_loc, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, num_units)
  end
  
  def test_multifamily_new_construction_living_zone
    args_hash = {}
    args_hash["location"] = "living zone 1"
    args_hash["fuel_type"] = Constants.FuelTypeGas
    expected_num_del_objects = {}
    expected_num_new_objects = {"WaterHeaterMixed"=>1, "PlantLoop"=>1, "PumpVariableSpeed"=>1, "ScheduleRuleset"=>2}
    expected_values = {"InputCapacity"=>29307107, "ThermalEfficiency"=>0.754, "Setpoint"=>125, "OnCycle"=>7.38, "OffCycle"=>7.38, "FuelType"=>Constants.FuelTypeGas}
    _test_measure(osm_geo_multifamily_3_units_beds_loc, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 1)
  end
  
  def test_multifamily_new_construction_mult_draw_profiles
    num_units = 12
    args_hash = {}
    args_hash["fuel_type"] = Constants.FuelTypeGas
    expected_num_del_objects = {}
    expected_num_new_objects = {"WaterHeaterMixed"=>num_units, "PlantLoop"=>num_units, "PumpVariableSpeed"=>num_units, "ScheduleRuleset"=>2*num_units}
    expected_values = {"InputCapacity"=>351685284, "ThermalEfficiency"=>9.0525, "Setpoint"=>1500, "OnCycle"=>88.54, "OffCycle"=>88.54, "FuelType"=>Constants.FuelTypeGas}
    _test_measure(osm_geo_multifamily_12_units_beds_loc, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, num_units)
  end

  def test_multifamily_retrofit_replace
    num_units = 3
    args_hash = {}
    args_hash["fuel_type"] = Constants.FuelTypeGas
    expected_num_del_objects = {}
    expected_num_new_objects = {"WaterHeaterMixed"=>num_units, "PlantLoop"=>num_units, "PumpVariableSpeed"=>num_units, "ScheduleRuleset"=>2*num_units}
    expected_values = {"InputCapacity"=>87921321, "ThermalEfficiency"=>2.262, "Setpoint"=>375, "OnCycle"=>21.76, "OffCycle"=>21.76, "FuelType"=>Constants.FuelTypeGas}
    model = _test_measure(osm_geo_multifamily_3_units_beds_loc, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, num_units)
    args_hash = {}
    args_hash["energy_factor"] = 0.96
    args_hash["fuel_type"] = Constants.FuelTypeGas
    expected_num_del_objects = {"WaterHeaterMixed"=>num_units, "ScheduleRuleset"=>num_units}
    expected_num_new_objects = {"WaterHeaterMixed"=>num_units, "ScheduleRuleset"=>num_units}
    expected_values = {"InputCapacity"=>87921321, "ThermalEfficiency"=>2.649, "Setpoint"=>375, "OnCycle"=>21.76, "OffCycle"=>21.76, "FuelType"=>Constants.FuelTypeGas}
    _test_measure(model, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, num_units)
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

  def test_argument_error_capacity_lt_0
    args_hash = {}
    args_hash["capacity"] = -10
    result = _test_error(osm_geo_beds_loc, args_hash)
    assert_equal(result.errors.map{ |x| x.logMessage }[0], "Nominal capacity must be greater than 0.")
  end

  def test_argument_error_capacity_eq_0
    args_hash = {}
    args_hash["capacity"] = 0
    result = _test_error(osm_geo_beds_loc, args_hash)
    assert_equal(result.errors.map{ |x| x.logMessage }[0], "Nominal capacity must be greater than 0.")
  end

  def test_argument_error_ef_lt_0
    args_hash = {}
    args_hash["energy_factor"] = -10
    result = _test_error(osm_geo_beds_loc, args_hash)
    assert_equal(result.errors.map{ |x| x.logMessage }[0], "Rated energy factor must be greater than 0 and less than 1.")
  end

  def test_argument_error_ef_eq_0
    args_hash = {}
    args_hash["energy_factor"] = 0
    result = _test_error(osm_geo_beds_loc, args_hash)
    assert_equal(result.errors.map{ |x| x.logMessage }[0], "Rated energy factor must be greater than 0 and less than 1.")
  end

  def test_argument_error_ef_gt_1
    args_hash = {}
    args_hash["energy_factor"] = 1.1
    result = _test_error(osm_geo_beds_loc, args_hash)
    assert_equal(result.errors.map{ |x| x.logMessage }[0], "Rated energy factor must be greater than 0 and less than 1.")
  end
  
  def test_argument_error_cd_lt_0
    args_hash = {}
    args_hash["water_heater_cycling_derate"] = -1
    result = _test_error(osm_geo_beds_loc, args_hash)
    assert_equal(result.errors.map{ |x| x.logMessage }[0], "Cycling derate must be at least 0 and at most 1.")
  end

  def test_argument_error_cd_gt_1
    args_hash = {}
    args_hash["water_heater_cycling_derate"] = 1.1
    result = _test_error(osm_geo_beds_loc, args_hash)
    assert_equal(result.errors.map{ |x| x.logMessage }[0], "Cycling derate must be at least 0 and at most 1.")
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

  private
  
  def _test_error(osm_file, args_hash)
    # create an instance of the measure
    measure = ResidentialHotWaterHeaterTanklessFuel.new

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
    measure = ResidentialHotWaterHeaterTanklessFuel.new

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

    actual_values = {"TankVolume"=>0, "InputCapacity"=>0, "ThermalEfficiency"=>0, "TankUA1"=>0, "TankUA2"=>0, "Setpoint"=>0, "OnCycle"=>0, "OffCycle"=>0}
    num_new_whs = 0
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
                num_new_whs += 1
            end
        end
    end
    assert_in_epsilon(num_new_whs.to_f*Waterheater.calc_actual_tankvol(nil, args_hash["fuel_type"], Constants.WaterHeaterTypeTankless), actual_values["TankVolume"], 0.01)
    assert_in_epsilon(expected_values["InputCapacity"], actual_values["InputCapacity"], 0.01)
    assert_in_epsilon(expected_values["ThermalEfficiency"], actual_values["ThermalEfficiency"], 0.01)
    assert_in_epsilon(0, actual_values["TankUA1"], 0.01)
    assert_in_epsilon(0, actual_values["TankUA2"], 0.01)
    assert_in_epsilon(expected_values["Setpoint"], actual_values["Setpoint"], 0.01)
    assert_in_epsilon(expected_values["OnCycle"], actual_values["OnCycle"], 0.01)
    assert_in_epsilon(expected_values["OffCycle"], actual_values["OffCycle"], 0.01)

    return model
  end
  
end
