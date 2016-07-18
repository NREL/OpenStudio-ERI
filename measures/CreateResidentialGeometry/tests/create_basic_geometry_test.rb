require_relative '../../../test/minitest_helper'
require 'openstudio'
require 'openstudio/ruleset/ShowRunnerOutput'
require 'minitest/autorun'
require_relative '../measure.rb'
require 'fileutils'

class CreateBasicGeometryTest < MiniTest::Test

  def test_error_existing_geometry
    args_hash = {}
    result = _test_error("2000sqft_2story_FB_GRG_UA.osm", args_hash)
    assert(result.errors.size == 1)
    assert_equal("Fail", result.value.valueName)    
    assert_equal(result.errors[0].logMessage, "Starting model is not empty.")
  end
  
  def test_argument_error_aspect_ratio_invalid
    args_hash = {}
    args_hash["aspect_ratio"] = -1.0
    result = _test_error(nil, args_hash)
    assert(result.errors.size == 1)
    assert_equal("Fail", result.value.valueName)
    assert_equal(result.errors[0].logMessage, "Invalid aspect ratio entered.")
  end
  
  def test_argument_error_basement_height_invalid
    args_hash = {}
    args_hash["foundation_type"] = Constants.FinishedBasementSpace
    result = _test_error(nil, args_hash)
    assert(result.errors.size == 1)
    assert_equal("Fail", result.value.valueName)
    assert_equal(result.errors[0].logMessage, "Currently the basement height is restricted to 8 ft.")
  end
  
  def test_argument_error_crawl_height_invalid
    args_hash = {}
    args_hash["foundation_type"] = Constants.CrawlSpace
    result = _test_error(nil, args_hash)
    assert(result.errors.size == 1)
    assert_equal("Fail", result.value.valueName)
    assert_equal(result.errors[0].logMessage, "The crawlspace height can be set between 1.5 and 5 ft.")
  end  
  
  def test_argument_error_pierbeam_height_invalid
    args_hash = {}
    args_hash["foundation_type"] = Constants.PierBeamSpace
    result = _test_error(nil, args_hash)
    assert(result.errors.size == 1)
    assert_equal("Fail", result.value.valueName)
    assert_equal(result.errors[0].logMessage, "The pier & beam height can be set between 0.5 and 8 ft.")
  end  
  
  def test_argument_error_num_floors_invalid
    args_hash = {}
    args_hash["num_floors"] = 7
    result = _test_error(nil, args_hash)
    assert(result.errors.size == 1)
    assert_equal("Fail", result.value.valueName)
    assert_equal(result.errors[0].logMessage, "Too many floors.")
  end
  
  def test_argument_error_garage_protrusion_invalid
    args_hash = {}
    args_hash["garage_protrusion"] = 2
    result = _test_error(nil, args_hash)
    assert(result.errors.size == 1)
    assert_equal("Fail", result.value.valueName)
    assert_equal(result.errors[0].logMessage, "Invalid garage protrusion value entered.")
  end
  
  def test_argument_error_hip_roof_and_garage_protrudes
    args_hash = {}
    args_hash["garage_protrusion"] = 0.5
    args_hash["roof_type"] = Constants.RoofTypeHip
    result = _test_error(nil, args_hash)
    assert(result.errors.size == 1)
    assert_equal("Fail", result.value.valueName)
    assert_equal(result.errors[0].logMessage, "Cannot handle protruding garage and hip roof.")
  end
  
  def test_argument_error_living_and_garage_ridges_are_parallel
    args_hash = {}
    args_hash["garage_protrusion"] = 0.5
    args_hash["aspect_ratio"] = 0.75
    result = _test_error(nil, args_hash)
    assert(result.errors.size == 1)
    assert_equal("Fail", result.value.valueName)
    assert_equal(result.errors[0].logMessage, "Cannot handle protruding garage and attic ridge running from front to back.")
  end
  
  def test_argument_error_garage_width_exceeds_living_width
    args_hash = {}
    args_hash["garage_width"] = 10000
    result = _test_error(nil, args_hash)
    assert(result.errors.size == 1)
    assert_equal("Fail", result.value.valueName)
    assert_equal(result.errors[0].logMessage, "Invalid living space and garage dimensions.")  
  end
  
  def test_argument_error_garage_depth_exceeds_living_depth
    args_hash = {}
    args_hash["garage_width"] = 12
    args_hash["garage_depth"] = 10000
    result = _test_error(nil, args_hash)
    assert(result.errors.size == 1)
    assert_equal("Fail", result.value.valueName)
    assert_equal(result.errors[0].logMessage, "Invalid living space and garage dimensions.")  
  end  
  
  def test_gable_ridge_front_to_back
    args_hash = {}
    args_hash["aspect_ratio"] = 0.75
    result = _test_error(nil, args_hash)
    assert(result.errors.size == 0)
    assert_equal("Success", result.value.valueName)
  end
  
  def test_hip_ridge_front_to_back
    args_hash = {}
    args_hash["aspect_ratio"] = 0.75
    args_hash["roof_type"] = Constants.RoofTypeHip
    result = _test_error(nil, args_hash)
    assert(result.errors.size == 0)
    assert_equal("Success", result.value.valueName)
  end

  def test_finished_attic
    args_hash = {}
    args_hash["attic_type"] = Constants.FinishedAtticSpace
    result = _test_error(nil, args_hash)
    assert(result.errors.size == 0)
    assert_equal("Success", result.value.valueName)
  end
  
  def test_crawlspace
    args_hash = {}
    args_hash["foundation_type"] = Constants.CrawlSpace
    args_hash["foundation_height"] = 4
    result = _test_error(nil, args_hash)
    assert(result.errors.size == 0)
    assert_equal("Success", result.value.valueName)
  end

  def test_ufbasement
    args_hash = {}
    args_hash["foundation_type"] = Constants.UnfinishedBasementSpace
    args_hash["foundation_height"] = 8
    result = _test_error(nil, args_hash)
    assert(result.errors.size == 0)
    assert_equal("Success", result.value.valueName)
  end  
  
  # test_[NUMSTORIES]_[FOUNDATIONTYPE]_[GARAGEPRESENT]_[GARAGEPROTRUDES]_[GARAGEPOSITION]_[ROOFTYPE]
  def test_onestory_fbasement_nogarage_noprotrusion_garageright_gableroof
    args_hash = {}
    args_hash["num_floors"] = 1
    args_hash["foundation_type"] = Constants.FinishedBasementSpace
    args_hash["foundation_height"] = 8
    result = _test_error(nil, args_hash)
    assert(result.errors.size == 0)
    assert_equal("Success", result.value.valueName)
  end  
  
  def test_onestory_fbasement_hasgarage_noprotrusion_garageright_gableroof
    args_hash = {}
    args_hash["num_floors"] = 1
    args_hash["garage_width"] = 12
    args_hash["foundation_type"] = Constants.FinishedBasementSpace
    args_hash["foundation_height"] = 8
    result = _test_error(nil, args_hash)
    assert(result.errors.size == 0)
    assert_equal("Success", result.value.valueName)
  end

  def test_onestory_fbasement_hasgarage_halfprotrusion_garageright_gableroof
    args_hash = {}
    args_hash["num_floors"] = 1
    args_hash["garage_width"] = 12
    args_hash["foundation_type"] = Constants.FinishedBasementSpace
    args_hash["foundation_height"] = 8
    args_hash["garage_protrusion"] = 0.5
    result = _test_error(nil, args_hash)
    assert(result.errors.size == 0)
    assert_equal("Success", result.value.valueName)
  end
  
  def test_onestory_fbasement_hasgarage_fullprotrusion_garageright_gableroof
    args_hash = {}
    args_hash["num_floors"] = 1
    args_hash["garage_width"] = 12
    args_hash["foundation_type"] = Constants.FinishedBasementSpace
    args_hash["foundation_height"] = 8
    args_hash["garage_protrusion"] = 1
    result = _test_error(nil, args_hash)
    assert(result.errors.size == 0)
    assert_equal("Success", result.value.valueName)
  end  
  
  def test_twostory_fbasement_hasgarage_noprotrusion_garageright_garagetobackwall_gableroof
    args_hash = {}
    args_hash["garage_width"] = 10
    args_hash["foundation_type"] = Constants.FinishedBasementSpace
    args_hash["foundation_height"] = 8
    result = _test_error(nil, args_hash)
    assert(result.errors.size == 0)
    assert_equal("Success", result.value.valueName)    
  end  
  
  def test_twostory_fbasement_hasgarage_noprotrusion_garageright_gableroof
    args_hash = {}
    args_hash["garage_width"] = 12
    args_hash["foundation_type"] = Constants.FinishedBasementSpace
    args_hash["foundation_height"] = 8
    result = _test_error(nil, args_hash)
    assert(result.errors.size == 0)
    assert_equal("Success", result.value.valueName)    
  end

  def test_twostory_fbasement_hasgarage_halfprotrusion_garageright_gableroof
    args_hash = {}
    args_hash["garage_width"] = 12
    args_hash["foundation_type"] = Constants.FinishedBasementSpace
    args_hash["foundation_height"] = 8
    args_hash["garage_protrusion"] = 0.5
    result = _test_error(nil, args_hash)
    assert(result.errors.size == 0)
    assert_equal("Success", result.value.valueName)   
  end
  
  def test_twostory_fbasement_hasgarage_fullprotrusion_garageright_gableroof
    args_hash = {}
    args_hash["garage_width"] = 12
    args_hash["foundation_type"] = Constants.FinishedBasementSpace
    args_hash["foundation_height"] = 8
    args_hash["garage_protrusion"] = 1
    result = _test_error(nil, args_hash)
    assert(result.errors.size == 0)
    assert_equal("Success", result.value.valueName)   
  end  
  
  def test_onestory_fbasement_hasgarage_noprotrusion_garageleft_gableroof
    args_hash = {}
    args_hash["num_floors"] = 1
    args_hash["garage_width"] = 12
    args_hash["garage_pos"] = "Left"
    args_hash["foundation_type"] = Constants.FinishedBasementSpace
    args_hash["foundation_height"] = 8
    result = _test_error(nil, args_hash)
    assert(result.errors.size == 0)
    assert_equal("Success", result.value.valueName)
  end

  def test_onestory_fbasement_hasgarage_halfprotrusion_garageleft_gableroof
    args_hash = {}
    args_hash["num_floors"] = 1
    args_hash["garage_width"] = 12
    args_hash["garage_pos"] = "Left"
    args_hash["foundation_type"] = Constants.FinishedBasementSpace
    args_hash["foundation_height"] = 8
    args_hash["garage_protrusion"] = 0.5
    result = _test_error(nil, args_hash)
    assert(result.errors.size == 0)
    assert_equal("Success", result.value.valueName)
  end
  
  def test_onestory_fbasement_hasgarage_fullprotrusion_garageleft_gableroof
    args_hash = {}
    args_hash["num_floors"] = 1
    args_hash["garage_width"] = 12
    args_hash["garage_pos"] = "Left"
    args_hash["foundation_type"] = Constants.FinishedBasementSpace
    args_hash["foundation_height"] = 8
    args_hash["garage_protrusion"] = 1
    result = _test_error(nil, args_hash)
    assert(result.errors.size == 0)
    assert_equal("Success", result.value.valueName)
  end  
  
  def test_twostory_fbasement_hasgarage_noprotrusion_garageleft_gableroof
    args_hash = {}
    args_hash["garage_width"] = 12
    args_hash["garage_pos"] = "Left"
    args_hash["foundation_type"] = Constants.FinishedBasementSpace
    args_hash["foundation_height"] = 8
    result = _test_error(nil, args_hash)
    assert(result.errors.size == 0)
    assert_equal("Success", result.value.valueName)    
  end

  def test_twostory_fbasement_hasgarage_halfprotrusion_garageleft_gableroof
    args_hash = {}
    args_hash["garage_width"] = 12
    args_hash["garage_pos"] = "Left"
    args_hash["foundation_type"] = Constants.FinishedBasementSpace
    args_hash["foundation_height"] = 8
    args_hash["garage_protrusion"] = 0.5
    result = _test_error(nil, args_hash)
    assert(result.errors.size == 0)
    assert_equal("Success", result.value.valueName)   
  end
  
  def test_twostory_fbasement_hasgarage_fullprotrusion_garageleft_gableroof
    args_hash = {}
    args_hash["garage_width"] = 12
    args_hash["garage_pos"] = "Left"
    args_hash["foundation_type"] = Constants.FinishedBasementSpace
    args_hash["foundation_height"] = 8
    args_hash["garage_protrusion"] = 1
    result = _test_error(nil, args_hash)
    assert(result.errors.size == 0)
    assert_equal("Success", result.value.valueName)   
  end

  def test_twostory_slab_hasgarage_noprotrusion_garageright_hiproof
    args_hash = {}
    args_hash["garage_width"] = 12
    args_hash["roof_type"] = Constants.RoofTypeHip
    result = _test_error(nil, args_hash)
    assert(result.errors.size == 0)
    assert_equal("Success", result.value.valueName)
  end  
  
  private
  
  def _test_error(osm_file_or_model, args_hash)
    # create an instance of the measure
    measure = CreateBasicGeometry.new

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
