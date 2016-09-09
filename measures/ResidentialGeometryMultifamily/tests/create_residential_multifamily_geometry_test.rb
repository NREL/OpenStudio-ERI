require_relative '../../../test/minitest_helper'
require 'openstudio'
require 'openstudio/ruleset/ShowRunnerOutput'
require 'minitest/autorun'
require_relative '../measure.rb'
require 'fileutils'

class CreateResidentialMultifamilyGeometryTest < MiniTest::Test

  def test_warning_implied_front_and_back_units
    args_hash = {}
    args_hash["corr_pos"] = "Double-Loaded Interior"
    args_hash["corr_width"] = 0
    result = _test_error(nil, args_hash)
    assert(result.warnings.size == 1)
    assert_equal("Success", result.value.valueName)
    assert_equal(result.warnings[0].logMessage, "Specified an interior corridor with a zero corridor width. Assuming the building has front units as well as adjacent rear units.")
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
  
  def test_argument_error_num_floors_not_mult_of_floors_per_unit
    args_hash = {}
    args_hash["building_num_floors"] = 3
    args_hash["num_stories_per_unit"] = 2
    result = _test_error(nil, args_hash)
    assert(result.errors.size == 1)
    assert_equal("Fail", result.value.valueName)
    assert_equal(result.errors[0].logMessage, "Number of building floors is not a multiplier of the number of stories per unit.")
  end
  
  def test_warning_offset_with_corridor
    args_hash = {}
    args_hash["offset"] = 6
    args_hash["corr_width"] = 5
    args_hash["corr_pos"] = "Double Exterior"
    result = _test_error(nil, args_hash)
    assert(result.warnings.size == 1)
    assert_equal("Success", result.value.valueName)
    assert_equal(result.warnings[0].logMessage, "Cannot handle unit offset with a corridor. Setting the offset to zero.")
  end
  
  def test_warning_no_corr_but_nonzero_corr_width
    args_hash = {}
    args_hash["corr_width"] = 5
    args_hash["corr_pos"] = "None"
    result = _test_error(nil, args_hash)
    assert(result.warnings.size == 1)
    assert_equal("Success", result.value.valueName)
    assert_equal(result.warnings[0].logMessage, "Specified no corridor with a nonzero corridor width. Assuming there is no corridor.")
  end
  
  def test_warning_uneven_units_per_floor_with_interior_corr
    args_hash = {}
    args_hash["num_units_per_floor"] = 3
    args_hash["corr_width"] = 4
    args_hash["corr_pos"] = "Double-Loaded Interior"    
    result = _test_error(nil, args_hash)
    assert(result.warnings.size == 1)
    assert_equal("Success", result.value.valueName)
    assert_equal(result.warnings[0].logMessage, "Specified a double-loaded corridor and an odd number of units per floor. Subtracting one unit per floor.")
  end
  
  def test_warning_balc_but_no_inset
    args_hash = {}
    args_hash["corr_width"] = 0
    args_hash["balc_depth"] = 6
    result = _test_error(nil, args_hash)
    assert(result.warnings.size == 1)
    assert_equal("Success", result.value.valueName)
    assert_equal(result.warnings[0].logMessage, "Specified a balcony, but there is no inset.")
  end  
  
  def test_two_story_fourplex_left_inset
    args_hash = {}
    args_hash["building_num_floors"] = 2
    args_hash["num_units_per_floor"] = 4
    args_hash["num_stories_per_unit"] = 2
    args_hash["corr_width"] = 5
    args_hash["corr_pos"] = "Double Exterior"
    args_hash["inset_width"] = 8
    args_hash["inset_depth"] = 6
    args_hash["inset_pos"] = "Left"
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
    args_hash["corr_pos"] = "Double-Loaded Interior"
    args_hash["inset_width"] = 8
    args_hash["inset_depth"] = 6
    result = _test_error(nil, args_hash)
    assert(result.errors.size == 0)
    assert_equal("Success", result.value.valueName)    
  end
  
  def test_two_story_multiplex_left_inset
    args_hash = {}
    args_hash["building_num_floors"] = 8
    args_hash["num_units_per_floor"] = 6
    args_hash["num_stories_per_unit"] = 2
    args_hash["corr_width"] = 5
    args_hash["corr_pos"] = "Double-Loaded Interior"
    args_hash["inset_width"] = 8
    args_hash["inset_depth"] = 6
    args_hash["inset_pos"] = "Left"
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
