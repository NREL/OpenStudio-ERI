require_relative '../../../test/minitest_helper'
require 'openstudio'
require 'openstudio/ruleset/ShowRunnerOutput'
require 'minitest/autorun'
require_relative '../measure.rb'
require 'fileutils'

class SetResidentialEPWFileTest < MiniTest::Test

  def test_error_invalid_weather_path
    args_hash = {}
    args_hash["weather_directory"] = "./resuorces" # misspelled
    args_hash["weather_file_name"] = "USA_CO_Denver_Intl_AP_725650_TMY3.epw"
    result = _test_error_or_NA("default_geometry.osm", args_hash)
    assert(result.errors.size == 1)
    assert_equal("Fail", result.value.valueName)
    assert_equal(result.errors[0].logMessage, "'#{File.join(File.expand_path(File.join(File.dirname(__FILE__), '..', args_hash["weather_directory"])), args_hash["weather_file_name"])}' does not exist or is not an .epw file.")
  end
  
  def test_error_invalid_daylight_saving
    args_hash = {}
    args_hash["dst_start_date"] = "April 31"
    result = _test_error_or_NA("default_geometry.osm", args_hash)
    assert(result.errors.size == 1)
    assert_equal("Fail", result.value.valueName)
    assert_equal(result.errors[0].logMessage, "Invalid daylight saving date specified.")
  end   
  
  def test_NA_daylight_saving
    args_hash = {}
    args_hash["dst_start_date"] = "NA"
    args_hash["dst_end_date"] = "NA"
    result = _test_error_or_NA("default_geometry.osm", args_hash)
    assert(result.errors.size == 0)
    assert_equal("Success", result.value.valueName)
  end
  
  def test_retrofit_replace
    args_hash = {}
    model = _test_measure("default_geometry.osm", args_hash, 1, 0)
    args_hash = {}
    _test_measure(model, args_hash, 1, 1)
  end  
  
  private
  
  def _test_error_or_NA(osm_file, args_hash)
    # create an instance of the measure
    measure = SetResidentialEPWFile.new

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
  
  def _test_measure(osm_file_or_model, args_hash, expected_num_new_files=0, expected_num_existing_files=0)
    # create an instance of the measure
    measure = SetResidentialEPWFile.new

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
    new_file = false
    existing_file = false
    result.info.each do |info|
        if info.logMessage.include? "Setting weather file."
            new_file = true
        elsif info.logMessage.include? "Found an existing weather file."
            existing_file = true
        end
    end    
    if expected_num_existing_files == 0 # new
        assert(new_file==true)
        assert(existing_file==false)
    else # replacement
        assert(new_file==true)
        assert(existing_file==true)
    end   

    return model
  end  
  
end
