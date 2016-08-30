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
    result = _test_error("default_geometry_location_windows.osm", args_hash)
    assert(result.errors.size == 1)
    assert_equal("Fail", result.value.valueName)
    assert_equal(result.errors[0].logMessage, "Invalid window U-value.")    
  end
  
  def test_argument_error_invalid_shgc
    args_hash = {}
    args_hash["shgc"] = 0
    result = _test_error("default_geometry_location_windows.osm", args_hash)
    assert(result.errors.size == 1)
    assert_equal("Fail", result.value.valueName)
    assert_equal(result.errors[0].logMessage, "Invalid window SHGC.")    
  end
  
  def test_error_no_weather
    args_hash = {}
    result = _test_error("default_geometry_windows.osm", args_hash)
    assert(result.errors.size == 1)
    assert_equal("Fail", result.value.valueName)
    assert_equal(result.errors[0].logMessage, "Model has not been assigned a weather file.")    
  end  
  
  def test_no_solar_gain_reduction
    args_hash = {}
    args_hash["userdefinedintshadeheatingmult"] = 1
    args_hash["userdefinedintshadecoolingmult"] = 1
    result = _test_error("default_geometry_location_windows.osm", args_hash)
    assert(result.errors.size == 0)
    assert_equal("Success", result.value.valueName)
  end
  
  def test_skip_missing_geometry
    args_hash = {}
    result = _test_error(nil, args_hash)
    assert(result.errors.size == 0)
    assert_equal("Success", result.value.valueName)    
  end
  
  def test_skip_no_windows
    args_hash = {}
    result = _test_error("default_geometry_location.osm", args_hash)
    assert(result.errors.size == 0)
    assert_equal("Success", result.value.valueName)   
  end
  
  def test_retrofit_replace
    args_hash = {}
    model = _test_measure("default_geometry_location_windows.osm", args_hash, 1, 1, 0)
    args_hash = {}
    _test_measure(model, args_hash, 0, 1, 1)
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
  
  def _test_measure(osm_file_or_model, args_hash, expected_num_new_materials=0, expected_num_new_constructions=0, expected_num_removed_constructions=0)
    # create an instance of the measure
    measure = ProcessConstructionsWindows.new

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
    material_added = false
    construction_added = false
    construction_removed = false
    result.info.each do |info|
        if info.logMessage.include? "Material 'GlazingMaterial' was created."
            material_added = true
        elsif info.logMessage.include? "Construction 'WindowConstruction' was created with 1 material (GlazingMaterial)." or info.logMessage.include? "Construction 'WindowConstruction 1' was created with 1 material (GlazingMaterial)."
            construction_added = true
        elsif info.logMessage.include? "Removed construction 'WindowConstruction' because it was orphaned."
            construction_removed = true
        end
    end    
    if expected_num_new_materials > 0 # new
        assert(material_added==true)
        assert(construction_added==true)
        assert(construction_removed==false)
    else # replacement
        assert(material_added==false)
        assert(construction_added==true)
        assert(construction_removed==true)
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
