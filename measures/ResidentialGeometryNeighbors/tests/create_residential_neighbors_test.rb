require_relative '../../../test/minitest_helper'
require 'openstudio'
require 'openstudio/ruleset/ShowRunnerOutput'
require 'minitest/autorun'
require_relative '../measure.rb'
require 'fileutils'

class CreateResidentialNeighborsTest < MiniTest::Test
  
  def test_error_invalid_neighbor_offset
    args_hash = {}
    args_hash["left_neighbor_offset"] = -10
    result = _test_error("default_geometry_location.osm", args_hash)
    assert(result.errors.size == 1)
    assert_equal("Fail", result.value.valueName)
    assert_equal(result.errors[0].logMessage, "Neighbor offsets must be greater than or equal to 0.")
  end
  
  def test_not_applicable_no_surfaces
    args_hash = {}
    result = _test_error(nil, args_hash)
    assert(result.errors.size == 0)
    assert_equal("NA", result.value.valueName)
    assert_equal(result.info[0].logMessage, "No surfaces found to copy for neighboring buildings.")
  end  
    
  def test_retrofit_replace
    args_hash = {}
    args_hash["left_neighbor_offset"] = 10
    args_hash["right_neighbor_offset"] = 10
    args_hash["back_neighbor_offset"] = 10
    args_hash["front_neighbor_offset"] = 10
    model = _test_measure("default_geometry_location.osm", args_hash, false, true)
    args_hash = {}
    args_hash["left_neighbor_offset"] = 20
    _test_measure(model, args_hash, true, true)
  end  
  
  private
  
  def _test_error(osm_file, args_hash)
    # create an instance of the measure
    measure = CreateResidentialNeighbors.new

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
  
  def _test_measure(osm_file_or_model, args_hash, expected_existing_neighbors=false, expected_new_neighbors=false)
    # create an instance of the measure
    measure = CreateResidentialNeighbors.new

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
    existing_neighbors = false
    new_neighbors = false
    result.info.each do |info|
        if info.logMessage.include? "Removed existing neighbors."
            existing_neighbors = true
        elsif info.logMessage.include? "Created shading surface"
            new_neighbors = true
        end
    end    
    if expected_existing_neighbors == false # new
        assert(existing_neighbors==false)
        assert(new_neighbors==true)
    else # replacement
        assert(existing_neighbors==true)
        assert(new_neighbors==true)
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
