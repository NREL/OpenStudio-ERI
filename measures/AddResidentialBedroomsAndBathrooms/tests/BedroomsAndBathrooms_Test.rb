require_relative '../../../test/minitest_helper'
require 'openstudio'
require 'openstudio/ruleset/ShowRunnerOutput'
require 'minitest/autorun'
require_relative '../measure.rb'
require 'fileutils'

class BedroomsAndBathroomsTest < MiniTest::Test
  
  def test_argument_error_beds_not_equal_to_baths
    args_hash = {}
    args_hash["Num_Br"] = "3.0, 3.0"
    result = _test_error("2000sqft_2story_FB_GRG_UA.osm", args_hash)
    assert(result.errors.size == 1)
    assert_equal("Fail", result.value.valueName)
    assert_equal(result.errors[0].logMessage, "Number of units based on number of bedroom elements specified inconsistent with number of units based on number of bathroom elements specified.")    
  end
  
  def test_argument_error_beds_and_baths_not_equal_to_units
    args_hash = {}
    args_hash["Num_Br"] = "3.0, 3.0"
    args_hash["Num_Ba"] = "2.0, 2.0"
    result = _test_error("2000sqft_2story_FB_GRG_UA.osm", args_hash)
    assert(result.errors.size == 1)
    assert_equal("Fail", result.value.valueName)
    assert_equal(result.errors[0].logMessage, "Number of units based on number of bedrooms elements specified in consistent with number of units defined in the model.")    
  end
  
  def test_error_no_units_defined_in_model
    args_hash = {}
    result = _test_error("EmptySeedModel.osm", args_hash)
    assert(result.errors.size == 1)
    assert_equal("Fail", result.value.valueName)
    assert_equal(result.errors[0].logMessage, "Cannot determine number of building units; Building::standardsNumberOfLivingUnits has not been set.")   
  end
  
  def test_error_inconsistent_units_defined_in_model
    args_hash = {}
    result = _test_error("multifamily_4_units_listed_3_units_defined.osm", args_hash)
    assert(result.errors.size == 1)
    assert_equal("Fail", result.value.valueName)
    assert_equal(result.errors[0].logMessage, "Cannot determine number of building units; inconsistent number of units defined in the model.")   
   end
  
  def test_error_unit_has_no_spaces
    args_hash = {}
    result = _test_error("2000sqft_2story_FB_GRG_UA_no_spaces_in_unit.osm", args_hash)
    assert(result.errors.size == 2)
    assert_equal("Fail", result.value.valueName)
    assert_equal(result.errors[0].logMessage, "Could not find the space '{59fc425b-e98e-42bf-a6d7-37f9c2809157}' associated with unit 1.")
    assert_equal(result.errors[1].logMessage, "Could not determine the spaces associated with unit 1.")   
  end  
  
  def test_sfd_retrofit_replace
    args_hash = {}
    model = _test_measure("2000sqft_2story_FB_GRG_UA.osm", args_hash, 3, 2, 1)
    args_hash = {}
    args_hash["Num_Br"] = "6.0"
    args_hash["Num_Ba"] = "4.0"
    _test_measure(model, args_hash, 6, 4, 1)
  end
  
  def test_mf_retrofit_replace
    args_hash = {}
    model = _test_measure("multifamily_3_units.osm", args_hash, 3, 2, 3)
    args_hash = {}
    args_hash["Num_Br"] = "6.0"
    args_hash["Num_Ba"] = "4.0"    
    _test_measure(model, args_hash, 6, 4, 3)
  end  
  
  def test_mf_urbanopt_retrofit_replace
    args_hash = {}
    model = _test_measure("multifamily_urbanopt.osm", args_hash, 3, 2, 8)
    args_hash = {}
    args_hash["Num_Br"] = "6.0"
    args_hash["Num_Ba"] = "4.0"    
    _test_measure(model, args_hash, 6, 4, 8)
  end  
  
  private
  
  def _test_error(osm_file, args_hash)
    # create an instance of the measure
    measure = AddResidentialBedroomsAndBathrooms.new

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
  
  def _test_measure(osm_file_or_model, args_hash, expected_num_beds=0, expected_num_baths=0, expected_num_units=0)
    # create an instance of the measure
    measure = AddResidentialBedroomsAndBathrooms.new

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
    if expected_num_beds > 5
      expected_num_beds = 5
    end
    if expected_num_baths > 3
      expected_num_baths = 3
    end

    if expected_num_units > 1
      assert_equal(result.finalCondition.get.logMessage, "The building has been assigned #{(expected_num_beds*expected_num_units).round(1)} bedroom(s) and #{(expected_num_baths*expected_num_units).round(1)} bathroom(s) across #{expected_num_units} units.")
    else
      assert_equal(result.finalCondition.get.logMessage, "The building has been assigned #{(expected_num_beds*expected_num_units).round(1)} bedroom(s) and #{(expected_num_baths*expected_num_units).round(1)} bathroom(s).")
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
