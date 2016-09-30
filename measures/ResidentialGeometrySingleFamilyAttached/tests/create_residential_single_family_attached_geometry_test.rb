require_relative '../../../test/minitest_helper'
require 'openstudio'
require 'openstudio/ruleset/ShowRunnerOutput'
require 'minitest/autorun'
require_relative '../measure.rb'
require 'fileutils'

class CreateResidentialSingleFamilyAttachedGeometryTest < MiniTest::Test

  def test_argument_error_crawl_height_invalid
    args_hash = {}
    args_hash["foundation_type"] = Constants.CrawlFoundationType
    args_hash["foundation_height"] = 0
    result = _test_error(nil, args_hash)
    assert(result.errors.size == 1)
    assert_equal("Fail", result.value.valueName)
    assert_equal(result.errors[0].logMessage, "The crawlspace height can be set between 1.5 and 5 ft.")
  end

  def test_error_existing_geometry
    args_hash = {}
    result = _test_error("2000sqft_2story_FB_GRG_UA.osm", args_hash)
    assert(result.errors.size == 1)
    assert_equal("Fail", result.value.valueName)    
    assert_equal(result.errors[0].logMessage, "Starting model is not empty.")
  end  
  
  def test_argument_error_aspect_ratio_invalid
    args_hash = {}
    args_hash["unit_aspect_ratio"] = -1.0
    result = _test_error(nil, args_hash)
    assert(result.errors.size == 1)
    assert_equal("Fail", result.value.valueName)
    assert_equal(result.errors[0].logMessage, "Invalid aspect ratio entered.")
  end
  
  def test_two_story_fourplex_front_units
    args_hash = {}
    args_hash["building_num_floors"] = 2
    args_hash["num_units"] = 4
    args_hash["foundation_type"] = Constants.FinishedBasementFoundationType    
    result = _test_error(nil, args_hash)
    assert(result.errors.size == 0)
    assert_equal("Success", result.value.valueName)    
  end  
  
  def test_two_story_fourplex_rear_units
    args_hash = {}
    args_hash["building_num_floors"] = 2
    args_hash["num_units"] = 4
    args_hash["has_rear_units"] = true
    args_hash["foundation_type"] = Constants.FinishedBasementFoundationType    
    result = _test_error(nil, args_hash)
    assert(result.errors.size == 0)
    assert_equal("Success", result.value.valueName)    
  end
  
  def test_ufbasement
    args_hash = {}
    args_hash["num_units"] = 4
    args_hash["foundation_type"] = Constants.UnfinishedBasementFoundationType
    result = _test_error(nil, args_hash)
    assert(result.errors.size == 0)
    assert_equal("Success", result.value.valueName)
  end
  
  def test_crawl
    args_hash = {}
    args_hash["num_units"] = 4
    args_hash["foundation_type"] = Constants.CrawlFoundationType
    result = _test_error(nil, args_hash)
    assert(result.errors.size == 0)
    assert_equal("Success", result.value.valueName)    
  end
  
  def test_zone_mult_front_units_only
    args_hash = {}
    args_hash["num_units"] = 8
    args_hash["use_zone_mult"] = "true"
    result = _test_error(nil, args_hash)
    assert(result.errors.size == 0)
    assert_equal("Success", result.value.valueName)    
  end
  
  def test_zone_mult_with_rear_units
    args_hash = {}
    args_hash["num_units"] = 8
    args_hash["has_rear_units"] = "true"
    args_hash["use_zone_mult"] = "true"
    result = _test_error(nil, args_hash)
    assert(result.errors.size == 0)
    assert_equal("Success", result.value.valueName)    
  end  
  
  private
  
  def _test_error(osm_file_or_model, args_hash)
    # create an instance of the measure
    measure = CreateResidentialSingleFamilyAttachedGeometry.new

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
      
    return result
    
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
