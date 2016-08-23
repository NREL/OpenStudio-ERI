require_relative '../../../test/minitest_helper'
require 'openstudio'
require 'openstudio/ruleset/ShowRunnerOutput'
require 'minitest/autorun'
require_relative '../measure.rb'
require 'fileutils'

class DoorAreaTest < MiniTest::Test
  
  def test_argument_error_invalid_door_area
    args_hash = {}
    args_hash["userdefineddoorarea"] = -20
    result = _test_error("2000sqft_2story_FB_GRG_UA.osm", args_hash)
    assert(result.errors.size == 1)
    assert_equal("Fail", result.value.valueName)
    assert_equal(result.errors[0].logMessage, "Invalid door area.")
  end
  
  def test_argument_no_door
    args_hash = {}
    args_hash["userdefineddoorarea"] = 0
    result = _test_error("2000sqft_2story_FB_GRG_UA.osm", args_hash)
    assert(result.errors.size == 0)
    assert_equal("Success", result.value.valueName)
    assert_equal(result.info[0].logMessage, "No door added because door area was set to 0 ft^2.")  
  end
  
  def test_sfd_retrofit_replace
    num_units = 1
    args_hash = {}
    model = _test_measure("2000sqft_2story_FB_GRG_UA.osm", args_hash, 0, num_units)
    args_hash = {}
    _test_measure(model, args_hash, num_units, num_units)
  end
  
  def test_mf_retrofit_replace
    num_units = 3
    args_hash = {}
    model = _test_measure("multifamily_3_units.osm", args_hash, 0, num_units)
    args_hash = {}
    _test_measure(model, args_hash, num_units, num_units)
  end
  
  def test_mf_urbanopt_retrofit_replace
    num_units = 8
    args_hash = {}
    model = _test_measure("multifamily_urbanopt.osm", args_hash, 0, num_units - 1)
    args_hash = {}
    _test_measure(model, args_hash, num_units - 1, num_units - 1)
  end
  
  def test_mf_corridor
    num_units = 24
    args_hash = {}
    model = _test_measure("multifamily_corridor.osm", args_hash, 0, num_units)
    args_hash = {}
    _test_measure(model, args_hash, num_units * 2, num_units)
  end  
  
  private
  
  def _test_error(osm_file, args_hash)
    # create an instance of the measure
    measure = CreateResidentialDoorArea.new

    # create an instance of a runner
    runner = OpenStudio::Ruleset::OSRunner.new

    model = _get_model(osm_file)

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
  
  def _test_measure(osm_file_or_model, args_hash, expected_num_doors_removed=0, expected_num_doors_added=0)
    # create an instance of the measure
    measure = CreateResidentialDoorArea.new

    # check for standard methods
    assert(!measure.name.empty?)
    assert(!measure.description.empty?)
    assert(!measure.modeler_description.empty?)

    # create an instance of a runner
    runner = OpenStudio::Ruleset::OSRunner.new
    
    model = _get_model(osm_file_or_model)

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

    doors_removed = 0
    doors_added = 0
    
    result.info.each do |info|
      if info.logMessage.include? "Removed door(s) from"
        doors_removed += 1
      end
      if info.logMessage.include? "added "
        doors_added += 1
      end
    end
    
    assert_equal(expected_num_doors_removed, doors_removed)
    assert_equal(expected_num_doors_added, doors_added)

    return model
  end  
  
  def _get_model(osm_file_or_model)
    if osm_file_or_model.is_a?(OpenStudio::Model::Model)
        # nothing to do
        model = osm_file_or_model
    elsif osm_file_or_model.nil?
        # make an empty model
        model = OpenStudio::Model::Model.new
    else
        # load the test model
        translator = OpenStudio::OSVersion::VersionTranslator.new
        path = OpenStudio::Path.new(File.join(File.dirname(__FILE__), osm_file_or_model))
        model = translator.loadModel(path)
        assert((not model.empty?))
        model = model.get
    end
    return model
  end  

end
