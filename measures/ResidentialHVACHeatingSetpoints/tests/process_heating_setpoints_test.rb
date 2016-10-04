require_relative '../../../test/minitest_helper'
require 'openstudio'
require 'openstudio/ruleset/ShowRunnerOutput'
require 'minitest/autorun'
require_relative '../measure.rb'
require 'fileutils'

class ProcessHeatingSetpointsTest < MiniTest::Test

  def test_error_no_weather
    args_hash = {}
    result = _test_error("singlefamily_detached_no_location.osm", args_hash)
    assert_equal(result.errors[0].logMessage, "Model has not been assigned a weather file.")    
  end 

  def test_argument_error_not_24_values
    args_hash = {}
    args_hash["htg_wkdy"] = "71, 71, 71, 71, 71, 71, 71, 71, 71, 71, 71, 71, 71, 71, 71, 71, 71, 71, 71, 71, 71, 71, 71"
    result = _test_error("singlefamily_detached_furnace.osm", args_hash)
    assert_equal(result.errors[0].logMessage, "A comma-separated string of 24 numbers must be entered for the weekday schedule.")    
  end
  
  def test_warning_no_equip
    args_hash = {}
    expected_num_del_objects = {}
    expected_num_new_objects = {"ScheduleRule"=>12, "ScheduleRuleset"=>1}
    expected_values = {}
    _test_measure("singlefamily_detached.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 0, 1)
  end
  
  def test_wkdy_wked_are_different
    args_hash = {}
    args_hash["htg_wkdy"] = "72"
    expected_num_del_objects = {}
    expected_num_new_objects = {"ScheduleRule"=>48, "ScheduleRuleset"=>3, "ThermostatSetpointDualSetpoint"=>1}
    expected_values = {}
    _test_measure("singlefamily_detached_furnace.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 5)
  end    
  
  def test_furnace
    args_hash = {}
    expected_num_del_objects = {}
    expected_num_new_objects = {"ScheduleRule"=>36, "ScheduleRuleset"=>3, "ThermostatSetpointDualSetpoint"=>1}
    expected_values = {}
    _test_measure("singlefamily_detached_furnace.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 5)
  end  
  
  def test_air_source_heat_pump
    args_hash = {}
    expected_num_del_objects = {}
    expected_num_new_objects = {"ScheduleRule"=>36, "ScheduleRuleset"=>3, "ThermostatSetpointDualSetpoint"=>1}
    expected_values = {}
    _test_measure("singlefamily_detached_ashp.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 6)
  end
  
  def test_mini_split_heat_pump
    args_hash = {}
    expected_num_del_objects = {}
    expected_num_new_objects = {"ScheduleRule"=>36, "ScheduleRuleset"=>3, "ThermostatSetpointDualSetpoint"=>1}
    expected_values = {}
    _test_measure("singlefamily_detached_mshp.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 5)
  end

  def test_boiler
    args_hash = {}
    expected_num_del_objects = {}
    expected_num_new_objects = {"ScheduleRule"=>36, "ScheduleRuleset"=>3, "ThermostatSetpointDualSetpoint"=>1}
    expected_values = {}
    _test_measure("singlefamily_detached_boiler.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 5)
  end
  
  def test_electric_baseboard
    args_hash = {}
    expected_num_del_objects = {}
    expected_num_new_objects = {"ScheduleRule"=>36, "ScheduleRuleset"=>3, "ThermostatSetpointDualSetpoint"=>1}
    expected_values = {}
    _test_measure("singlefamily_detached_electric_baseboard.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 5)
  end  
  
  def test_retrofit_replace
    args_hash = {}
    expected_num_del_objects = {}
    expected_num_new_objects = {"ScheduleRule"=>36, "ScheduleRuleset"=>3, "ThermostatSetpointDualSetpoint"=>1}
    expected_values = {}
    model = _test_measure("singlefamily_detached_furnace.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 5)
    expected_num_del_objects = {"ScheduleRule"=>24, "ScheduleRuleset"=>2}
    expected_num_new_objects = {"ScheduleRule"=>36, "ScheduleRuleset"=>3}
    expected_values = {}
    _test_measure(model, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 4)    
  end
  
  def test_cooling_setpoints_exist
    args_hash = {}
    expected_num_del_objects = {"ScheduleRule"=>24, "ScheduleRuleset"=>2}
    expected_num_new_objects = {"ScheduleRule"=>36, "ScheduleRuleset"=>3}
    expected_values = {}
    _test_measure("singlefamily_detached_furnace_central_air_conditioner_cooling_setpoints.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 4)
  end  
  
  private
  
  def _test_error(osm_file_or_model, args_hash)
    # create an instance of the measure
    measure = ProcessHeatingSetpoints.new

    # create an instance of a runner
    runner = OpenStudio::Ruleset::OSRunner.new

    model = get_model(File.dirname(__FILE__), osm_file_or_model)

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

    # assert that it didn't run
    assert_equal("Fail", result.value.valueName)
    assert(result.errors.size == 1)
    
    return result
  end  
  
  def _test_measure(osm_file_or_model, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, num_infos=0, num_warnings=0, debug=false)
    # create an instance of the measure
    measure = ProcessHeatingSetpoints.new

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

    # assert that it ran correctly
    assert_equal("Success", result.value.valueName)
    assert(result.info.size == num_infos)
    assert(result.warnings.size == num_warnings)
    
    # get the final objects in the model
    final_objects = get_objects(model)
    
    # get new and deleted objects
    obj_type_exclusions = ["ScheduleDay", "ScheduleTypeLimits"]
    all_new_objects = get_object_additions(initial_objects, final_objects, obj_type_exclusions)
    all_del_objects = get_object_additions(final_objects, initial_objects, obj_type_exclusions)
    
    # check we have the expected number of new/deleted objects
    check_num_objects(all_new_objects, expected_num_new_objects, "added")
    check_num_objects(all_del_objects, expected_num_del_objects, "deleted")
    
    return model
  end  
  
end
