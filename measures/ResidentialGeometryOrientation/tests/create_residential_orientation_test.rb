require_relative '../../../test/minitest_helper'
require 'openstudio'
require 'openstudio/ruleset/ShowRunnerOutput'
require 'minitest/autorun'
require_relative '../measure.rb'
require 'fileutils'

class CreateResidentialOrientationTest < MiniTest::Test
  
  def test_error_invalid_orientation
    args_hash = {}
    args_hash["orientation"] = -180
    result = _test_error("default_geometry_location.osm", args_hash)
    assert_includes(result.errors.map{ |x| x.logMessage }, "Invalid orientation entered.")
  end
    
  def test_retrofit_replace
    args_hash = {}
    args_hash["orientation"] = 0
    model = _test_measure("default_geometry_location.osm", args_hash, 0)
    args_hash = {}
    args_hash["orientation"] = 180
    _test_measure(model, args_hash, 1)
  end  
  
  private
  
  def _test_error(osm_file, args_hash)
    # create an instance of the measure
    measure = CreateResidentialOrientation.new

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
      
    # assert that it didn't run
    assert_equal("Fail", result.value.valueName)
    assert(result.errors.size == 1)

    return result
    
  end
  
  def _test_measure(osm_file_or_model, args_hash, expected_num_orientation_changes=0)
    # create an instance of the measure
    measure = CreateResidentialOrientation.new

    # check for standard methods
    assert(!measure.name.empty?)
    assert(!measure.description.empty?)
    assert(!measure.modeler_description.empty?)

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

    # assert that it ran correctly
    assert_equal("Success", result.value.valueName)
    orientation_changed = false
    result.info.map{ |x| x.logMessage }.each do |info|
        if info.include? "The orientation of the building has changed."
            orientation_changed = true
        end
    end    
    if expected_num_orientation_changes == 0 # new
        assert(orientation_changed==false)
    else # replacement
        assert(orientation_changed==true)
    end   

    return model
  end  
  
end
