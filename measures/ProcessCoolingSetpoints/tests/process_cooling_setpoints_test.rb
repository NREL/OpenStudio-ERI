require_relative '../../../test/minitest_helper'
require 'openstudio'
require 'openstudio/ruleset/ShowRunnerOutput'
require 'minitest/autorun'
require_relative '../measure.rb'
require 'fileutils'

class ProcessCoolingSetpointsTest < MiniTest::Test

  def test_error_no_weather
    args_hash = {}
    result = _test_error("default_geometry.osm", args_hash)
    assert(result.errors.size == 1)
    assert_equal("Fail", result.value.valueName)
    assert_equal(result.errors[0].logMessage, "Model has not been assigned a weather file.")    
  end 

  def test_error_input_not_24_values
    args_hash = {}
    args_hash["clg_wkdy"] = "71, 71, 71, 71, 71, 71, 71, 71, 71, 71, 71, 71, 71, 71, 71, 71, 71, 71, 71, 71, 71, 71, 71"
    result = _test_error("default_geometry_location_central_air_conditioner.osm", args_hash)
    assert(result.errors.size == 1)
    assert_equal("Fail", result.value.valueName)
    assert_equal(result.errors[0].logMessage, "Either a comma-separated string of 24 numbers or an array of 24 numbers must be entered for the weekday schedule.")    
  end

  def test_warning_no_equip
    args_hash = {}
    result = _test_error("default_geometry_location.osm", args_hash)
    assert(result.errors.size == 0)
    assert_equal("Success", result.value.valueName)
    assert_equal(result.warnings[0].logMessage, "No cooling equipment found.")
  end
  
  def test_central_air_conditioner_avail_sched
    args_hash = {}
    result = _test_error("default_geometry_location_central_air_conditioner.osm", args_hash)
    assert(result.errors.size == 0)
    assert_equal("Success", result.value.valueName)
  end
  
  def test_room_air_conditioner_avail_sched
    args_hash = {}
    result = _test_error("default_geometry_location_room_air_conditioner.osm", args_hash)
    assert(result.errors.size == 0)
    assert_equal("Success", result.value.valueName)
  end  

  def test_ashp_avail_sched
    args_hash = {}
    result = _test_error("default_geometry_location_ashp.osm", args_hash)
    assert(result.errors.size == 0)
    assert_equal("Success", result.value.valueName)
  end
  
  def test_mshp_avail_sched
    args_hash = {}
    result = _test_error("default_geometry_location_mshp.osm", args_hash)
    assert(result.errors.size == 0)
    assert_equal("Success", result.value.valueName)
  end
  
  def test_heating_setpoints_exist
    args_hash = {}
    result = _test_error("default_geometry_location_furnace_and_central_air_conditioner_with_heating_setpoints.osm", args_hash)
    assert(result.errors.size == 0)
    assert_equal("Success", result.value.valueName)    
  end
  
  def test_retrofit_replace
    args_hash = {}
    model = _test_measure("default_geometry_location_central_air_conditioner.osm", args_hash, 1, 0)
    args_hash = {}
    _test_measure(model, args_hash, 1, 1)
  end
  
  private
  
  def _test_error(osm_file, args_hash)
    # create an instance of the measure
    measure = ProcessCoolingSetpoints.new

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
  
  def _test_measure(osm_file_or_model, args_hash, expected_num_new_schedules=0, expected_num_existing_schedules=0)
    # create an instance of the measure
    measure = ProcessCoolingSetpoints.new

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
    new_schedule = false
    existing_schedule = false
    result.info.each do |info|
        if info.logMessage.include? "Set the cooling setpoint schedule for Living Zone Temperature SP."
            new_schedule = true
        elsif info.logMessage.include? "Found existing thermostat Living Zone Temperature SP for living zone."
            existing_schedule = true
        end
    end    
    if expected_num_existing_schedules == 0 # new
        assert(new_schedule==true)
        assert(existing_schedule==false)
    else # replacement
        assert(new_schedule==true)
        assert(existing_schedule==true)
    end   

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
