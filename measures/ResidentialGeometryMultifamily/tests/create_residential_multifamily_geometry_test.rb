require_relative '../../../test/minitest_helper'
require 'openstudio'
require 'openstudio/ruleset/ShowRunnerOutput'
require 'minitest/autorun'
require_relative '../measure.rb'
require 'fileutils'

class CreateResidentialMultifamilyGeometryTest < MiniTest::Test

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
  
  def test_warning_uneven_units_per_floor_with_interior_corr
    args_hash = {}
    args_hash["num_units_per_floor"] = 3
    args_hash["corr_width"] = 4
    result = _test_error(nil, args_hash)
    assert(result.warnings.size == 1)
    assert_equal("Success", result.value.valueName)
    assert_equal(result.warnings[0].logMessage, "Specified a double-loaded corridor and an odd number of units per floor. Subtracting one unit per floor.")
  end
  
  def test_error_no_corr
    args_hash = {}
    args_hash["corr_width"] = -1
    result = _test_error(nil, args_hash)
    assert(result.errors.size == 1)
    assert_equal("Fail", result.value.valueName)
    assert_equal(result.errors[0].logMessage, "Invalid corridor width entered.")
  end
  
  def test_warning_balc_but_no_inset
    args_hash = {}
    args_hash["balc_depth"] = 6
    args_hash["corr_pos"] = "None"
    result = _test_error(nil, args_hash)
    assert(result.warnings.size == 1)
    assert_equal("Success", result.value.valueName)
    assert_equal(result.warnings[0].logMessage, "Specified a balcony, but there is no inset.")
  end
  
  def test_two_story_fourplex_left_inset
    args_hash = {}
    args_hash["building_num_floors"] = 2
    args_hash["num_units_per_floor"] = 4
    args_hash["corr_width"] = 5
    args_hash["corr_pos"] = "Double Exterior"
    args_hash["inset_width"] = 8
    args_hash["inset_depth"] = 6
    args_hash["inset_pos"] = "Right"
    args_hash["balc_depth"] = 6
    result = _test_error(nil, args_hash)
    assert(result.errors.size == 0)
    assert_equal("Success", result.value.valueName)    
  end      
  
  def test_multiplex_right_inset
    args_hash = {}
    args_hash["building_num_floors"] = 8
    args_hash["num_units_per_floor"] = 6
    args_hash["corr_width"] = 5
    args_hash["inset_width"] = 8
    args_hash["inset_depth"] = 6
    args_hash["foundation_type"] = Constants.UnfinishedBasementFoundationType
    result = _test_error(nil, args_hash)
    assert(result.errors.size == 0)
    assert_equal("Success", result.value.valueName)    
  end
  
  def test_two_story_multiplex_left_inset
    args_hash = {}
    args_hash["building_num_floors"] = 8
    args_hash["num_units_per_floor"] = 6
    args_hash["corr_width"] = 5
    args_hash["inset_width"] = 8
    args_hash["inset_depth"] = 6
    args_hash["inset_pos"] = "Left"
    args_hash["balc_depth"] = 6
    args_hash["foundation_type"] = Constants.UnfinishedBasementFoundationType
    result = _test_error(nil, args_hash)
    assert(result.errors.size == 0)
    assert_equal("Success", result.value.valueName)    
  end  
  
  def test_apartments_exterior_access
    args_hash = {}
    args_hash["building_num_floors"] = 2
    args_hash["num_units_per_floor"] = 12
    args_hash["corr_width"] = 5
    args_hash["corr_pos"] = "Single Exterior (Front)"
    args_hash["foundation_type"] = Constants.CrawlFoundationType
    result = _test_error(nil, args_hash)
    assert(result.errors.size == 0)
    assert_equal("Success", result.value.valueName)    
  end
  
  def test_crawlspace_double_loaded_corr
    args_hash = {}
    args_hash["num_units_per_floor"] = 4
    args_hash["foundation_type"] = Constants.CrawlFoundationType
    result = _test_error(nil, args_hash)
    assert(result.errors.size == 0)
    assert_equal("Success", result.value.valueName)    
  end
  
  def test_ufbasement_no_corr
    args_hash = {}
    args_hash["num_units_per_floor"] = 4
    args_hash["foundation_type"] = Constants.UnfinishedBasementFoundationType
    result = _test_error(nil, args_hash)
    assert(result.errors.size == 0)
    assert_equal("Success", result.value.valueName)    
  end
  
  private
  
  def _test_error(osm_file_or_model, args_hash)
    # create an instance of the measure
    measure = CreateResidentialMultifamilyGeometry.new

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
      
    return result
    
  end
  
end
