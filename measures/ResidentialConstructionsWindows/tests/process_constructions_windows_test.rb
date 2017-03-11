require_relative '../../../test/minitest_helper'
require 'openstudio'
require 'openstudio/ruleset/ShowRunnerOutput'
require 'minitest/autorun'
require_relative '../measure.rb'
require 'fileutils'

class ProcessConstructionsWindowsTest < MiniTest::Test

  def test_argument_error_invalid_ufactor
    args_hash = {}
    args_hash["ufactor"] = 0
    result = _test_error("SFD_2000sqft_2story_SL_UA_Denver_Windows.osm", args_hash)
    assert(result.errors.size == 1)
    assert_equal("Fail", result.value.valueName)
    assert_equal(result.errors.map{ |x| x.logMessage }[0], "Invalid window U-value.")    
  end
  
  def test_argument_error_invalid_shgc
    args_hash = {}
    args_hash["shgc"] = 0
    result = _test_error("SFD_2000sqft_2story_SL_UA_Denver_Windows.osm", args_hash)
    assert(result.errors.size == 1)
    assert_equal("Fail", result.value.valueName)
    assert_equal(result.errors.map{ |x| x.logMessage }[0], "Invalid window SHGC.")    
  end
  
  def test_error_no_weather
    args_hash = {}
    result = _test_error("SFD_2000sqft_2story_SL_UA_Windows.osm", args_hash)
    assert(result.errors.size == 1)
    assert_equal("Fail", result.value.valueName)
    assert_equal(result.errors.map{ |x| x.logMessage }[0], "Model has not been assigned a weather file.")    
  end  
  
  def test_no_solar_gain_reduction
    args_hash = {}
    args_hash["heating_shade_mult"] = 1
    args_hash["cooling_shade_mult"] = 1
    expected_num_del_objects = {}
    expected_num_new_objects = {"SimpleGlazing"=>1, "Construction"=>1}
    expected_values = {"shgc"=>0.3, "ufactor"=>0.37}
    result = _test_measure("SFD_2000sqft_2story_SL_UA_Denver_Windows.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)
  end
  
  def test_skip_missing_geometry
    args_hash = {}
    result = _test_error(nil, args_hash)
    assert(result.errors.size == 0)
    assert_equal("NA", result.value.valueName)    
  end
  
  def test_skip_no_windows
    args_hash = {}
    result = _test_error("SFD_2000sqft_2story_SL_UA_Denver.osm", args_hash)
    assert(result.errors.size == 0)
    assert_equal("NA", result.value.valueName)   
  end
  
  def test_retrofit_replace
    args_hash = {}
    expected_num_del_objects = {}
    expected_num_new_objects = {"SimpleGlazing"=>1, "Construction"=>1, "ShadingControl"=>1, "WindowMaterialShade"=>1, "ScheduleRuleset"=>1}
    expected_values = {"shgc"=>0.3*0.7, "ufactor"=>0.37}
    model = _test_measure("SFD_2000sqft_2story_SL_UA_Denver_Windows.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)
    args_hash = {}
    args_hash["ufactor"] = 0.20
    args_hash["shgc"] = 0.5
    args_hash["heating_shade_mult"] = 1
    args_hash["cooling_shade_mult"] = 1
    expected_num_del_objects = {"SimpleGlazing"=>1, "Construction"=>1, "ShadingControl"=>1, "WindowMaterialShade"=>1, "ScheduleRuleset"=>1}
    expected_num_new_objects = {"SimpleGlazing"=>1, "Construction"=>1}
    expected_values = {"shgc"=>0.5, "ufactor"=>0.20}
    _test_measure(model, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)
  end
  
  private
  
  def _test_error(osm_file, args_hash)
    # create an instance of the measure
    measure = ProcessConstructionsWindows.new

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
      
    return result
    
  end
  
  def _test_measure(osm_file_or_model, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)
    # create an instance of the measure
    measure = ProcessConstructionsWindows.new

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
    
    # get the final objects in the model
    final_objects = get_objects(model)

    # get new and deleted objects
    obj_type_exclusions = ["ScheduleRule", "ScheduleDay", "ScheduleTypeLimits"]
    all_new_objects = get_object_additions(initial_objects, final_objects, obj_type_exclusions)
    all_del_objects = get_object_additions(final_objects, initial_objects, obj_type_exclusions)
    
    # check we have the expected number of new/deleted objects
    check_num_objects(all_new_objects, expected_num_new_objects, "added")
    check_num_objects(all_del_objects, expected_num_del_objects, "deleted")
    
    actual_values = {"shgc"=>0, "ufactor"=>0}
    all_new_objects.each do |obj_type, new_objects|
        new_objects.each do |new_object|
            next if not new_object.respond_to?("to_#{obj_type}")
            new_object = new_object.public_send("to_#{obj_type}").get
            if obj_type == "SimpleGlazing"
                new_object = new_object.to_SimpleGlazing.get
                actual_values["ufactor"] += OpenStudio::convert(new_object.uFactor,"W/m^2*K","Btu/ft^2*h*R").get
                actual_values["shgc"] += new_object.solarHeatGainCoefficient
            end
        end
    end
    assert_in_epsilon(expected_values["shgc"], actual_values["shgc"], 0.01)
    assert_in_epsilon(expected_values["ufactor"], actual_values["ufactor"], 0.01)

    return model
  end  
  
end
