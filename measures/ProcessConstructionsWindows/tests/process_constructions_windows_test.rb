require_relative '../../../test/minitest_helper'
require 'openstudio'
require 'openstudio/ruleset/ShowRunnerOutput'
require 'minitest/autorun'
require_relative '../measure.rb'
require 'fileutils'
require_relative '../../CreateResidentialGeometry/measure.rb'
require_relative '../../SetResidentialEPWFile/measure.rb'
require_relative '../../CreateResidentialWindowArea/measure.rb'

class ProcessConstructionsWindowsTest < MiniTest::Test

  def test_error_invalid_ufactor
    args_hash = {}
    args_hash["ufactor"] = 0
    result = _test_error("EmptySeedModel.osm", args_hash)
    assert(result.errors.size == 1)
    assert_equal("Fail", result.value.valueName)
    assert_equal(result.errors[0].logMessage, "Invalid window U-value.")    
  end
  
  def test_error_invalid_shgc
    args_hash = {}
    args_hash["shgc"] = 0
    result = _test_error("EmptySeedModel.osm", args_hash)
    assert(result.errors.size == 1)
    assert_equal("Fail", result.value.valueName)
    assert_equal(result.errors[0].logMessage, "Invalid window SHGC.")    
  end
  
  def test_no_solar_gain_reduction
    args_hash = {}
    args_hash["userdefinedintshadeheatingmult"] = 1
    args_hash["userdefinedintshadecoolingmult"] = 1
    result = _test_error("EmptySeedModel.osm", args_hash)
    assert(result.errors.size == 0)
    assert_equal("Success", result.value.valueName)
  end  
  
  private
  
  def _test_error(osm_file, args_hash)
    # create an instance of the measure
    measure = ProcessConstructionsWindows.new

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
  
  def _get_model(osm_file)
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
    model = _apply_measure(model, {}, "SetResidentialWindowArea")
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
