require_relative '../../../test/minitest_helper'
require 'openstudio'
require 'openstudio/ruleset/ShowRunnerOutput'
require 'minitest/autorun'
require_relative '../measure.rb'
require 'fileutils'
require_relative '../../CreateResidentialGeometry/measure.rb'
require_relative '../../SetResidentialEPWFile/measure.rb'
require_relative '../../ProcessFurnace/measure.rb'
require_relative '../../ProcessAirSourceHeatPump/measure.rb'
require_relative '../../ProcessRoomAirConditioner/measure.rb'
require_relative '../../ProcessCentralAirConditioner/measure.rb'
require_relative '../../ProcessHeatingSetpoints/measure.rb'

class ProcessCoolingSetpointsTest < MiniTest::Test

  def test_error_input_not_24_values
    args_hash = {}
    args_hash["clg_wkdy"] = "71, 71, 71, 71, 71, 71, 71, 71, 71, 71, 71, 71, 71, 71, 71, 71, 71, 71, 71, 71, 71, 71, 71"
    result = _test_error("EmptySeedModel.osm", args_hash, "ProcessCentralAirConditioner")
    assert(result.errors.size == 1)
    assert_equal("Fail", result.value.valueName)
    assert_equal(result.errors[0].logMessage, "Either a comma-separated string of 24 numbers or an array of 24 numbers must be entered for the weekday schedule.")    
  end

  def test_error_no_equip
    args_hash = {}
    result = _test_error("EmptySeedModel.osm", args_hash)
    assert(result.errors.size == 0)
    assert_equal("Success", result.value.valueName)
    assert_equal(result.warnings[0].logMessage, "No cooling equipment found.")
  end
  
  def test_central_air_conditioner_avail_sched
    args_hash = {}
    result = _test_error("EmptySeedModel.osm", args_hash, "ProcessCentralAirConditioner")
    assert(result.errors.size == 0)
    assert_equal("Success", result.value.valueName)
  end

  def test_ashp_avail_sched
    args_hash = {}
    result = _test_error("EmptySeedModel.osm", args_hash, "ProcessAirSourceHeatPump")
    assert(result.errors.size == 0)
    assert_equal("Success", result.value.valueName)
  end
  
  def test_room_air_conditioner_avail_sched
    args_hash = {}
    result = _test_error("EmptySeedModel.osm", args_hash, "ProcessRoomAirConditioner")
    assert(result.errors.size == 0)
    assert_equal("Success", result.value.valueName)
  end
  
  def test_heating_setpoints_exist
    args_hash = {}
    result = _test_error("EmptySeedModel.osm", args_hash, "ProcessCentralAirConditioner", "ProcessHeatingSetpoints")
    assert(result.errors.size == 0)
    assert_equal("Success", result.value.valueName)    
  end
  
  private
  
  def _test_error(osm_file, args_hash, equip=nil, hsp=nil)
    # create an instance of the measure
    measure = ProcessCoolingSetpoints.new

    # create an instance of a runner
    runner = OpenStudio::Ruleset::OSRunner.new

    model = _get_model(osm_file, equip, hsp)

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
  
  def _get_model(osm_file, equip, hsp)
    if osm_file.nil?
        # make an empty model
        model = OpenStudio::Model::Model.new
    else
        # load the test model
        translator = OpenStudio::OSVersion::VersionTranslator.new
        path = OpenStudio::Path.new(File.join(File.dirname(__FILE__), osm_file))
        model = translator.loadModel(path)
        assert((not model.empty?))
        model = model.get
    end
    model = _apply_measure(model, {}, "CreateBasicGeometry")
    model = _apply_measure(model, {}, "SetResidentialEPWFile")
    unless hsp.nil?
      model = _apply_measure(model, {}, "ProcessFurnace")
      model = _apply_measure(model, {}, hsp)
    end
    unless equip.nil?
      model = _apply_measure(model, {}, equip)
    end    
    return model
  end
  
  def _apply_measure(model, args_hash, measure_class)
    # create an instance of the measure
    measure = eval(measure_class).new

    # create an instance of a runner
    runner = OpenStudio::Ruleset::OSRunner.new

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
      
    return model
  end

end
