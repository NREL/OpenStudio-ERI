require_relative '../../../test/minitest_helper'
require 'openstudio'
require 'openstudio/ruleset/ShowRunnerOutput'
require 'minitest/autorun'
require_relative '../measure.rb'
require 'fileutils'

class BedroomsAndBathroomsTest < MiniTest::Test
  
  def test_argument_error_beds_not_equal_to_baths
    args_hash = {}
    args_hash["Num_Br"] = "3.0, 3.0, 3.0"
    args_hash["Num_Ba"] = "2.0, 2.0"
    result = _test_error("singlefamily_detached.osm", args_hash)
    assert_equal(result.errors.map{ |x| x.logMessage }[0], "Number of bedroom elements specified inconsistent with number of bathroom elements specified.")
  end
  
  def test_argument_error_beds_not_equal_to_units
    args_hash = {}
    args_hash["Num_Br"] = "3.0, 3.0"
    result = _test_error("singlefamily_detached.osm", args_hash)
    assert_equal(result.errors.map{ |x| x.logMessage }[0], "Number of bedroom elements specified inconsistent with number of multifamily units defined in the model.")
  end
  
  def test_argument_error_baths_not_equal_to_units
    args_hash = {}
    args_hash["Num_Ba"] = "2.0, 2.0"
    result = _test_error("singlefamily_detached.osm", args_hash)
    assert_equal(result.errors.map{ |x| x.logMessage }[0], "Number of bathroom elements specified inconsistent with number of multifamily units defined in the model.")
  end
  
  def test_argument_error_beds_not_numerical
    args_hash = {}
    args_hash["Num_Br"] = "3.0, 3.0, typo"
    result = _test_error("singlefamily_detached.osm", args_hash)
    assert_equal(result.errors.map{ |x| x.logMessage }[0], "Number of bedrooms must be a numerical value.")
  end
  
  def test_argument_error_baths_not_numerical
    args_hash = {}
    args_hash["Num_Ba"] = "2.0, 2.0, typo"
    result = _test_error("singlefamily_detached.osm", args_hash)
    assert_equal(result.errors.map{ |x| x.logMessage }[0], "Number of bathrooms must be a numerical value.")  
  end
  
  def test_argument_error_beds_not_positive_integer
    args_hash = {}
    args_hash["Num_Br"] = "3.0, 3.0, 3.5"
    result = _test_error("singlefamily_detached.osm", args_hash)
    assert_equal(result.errors.map{ |x| x.logMessage }[0], "Number of bedrooms must be a positive integer.")    
  end
  
  def test_argument_error_baths_not_positive_multiple_of_0pt25
    args_hash = {}
    args_hash["Num_Ba"] = "2.0, 2.0, 2.8"
    result = _test_error("singlefamily_detached.osm", args_hash)
    assert_equal(result.errors.map{ |x| x.logMessage }[0], "Number of bathrooms must be a positive multiple of 0.25.")    
  end
  
  def test_error_no_units_defined_in_model
    args_hash = {}
    result = _test_error("EmptySeedModel.osm", args_hash)
    assert_equal(result.errors.map{ |x| x.logMessage }[0], "Cannot determine number of building units; Building::standardsNumberOfLivingUnits has not been set.")   
  end
  
  def test_error_inconsistent_units_defined_in_model
    args_hash = {}
    result = _test_error("multifamily_8_units_6_listed.osm", args_hash)
    assert_equal(result.errors.map{ |x| x.logMessage }[0], "Cannot determine number of building units; inconsistent number of units defined in the model.")   
   end
  
  def test_error_unit_has_no_spaces
    args_hash = {}
    result = _test_error("multifamily_8_units_missing_space.osm", args_hash)
    assert_equal(result.errors.map{ |x| x.logMessage }[0], "Could not find the space '{381d5b54-fa3f-4245-9812-ebdc33acae12}' associated with unit 1.")
  end
  
  def test_retrofit_replace
    num_units = 1
    args_hash = {}
    expected_num_del_objects = {}
    expected_num_new_objects = {}
    expected_values = {"Beds"=>3.0, "Baths"=>2.0, "Num_Units"=>num_units}
    model = _test_measure("singlefamily_detached.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)
    args_hash["Num_Br"] = "4"
    args_hash["Num_Ba"] = "3"
    expected_num_del_objects = {}
    expected_num_new_objects = {}
    expected_values = {"Beds"=>4.0, "Baths"=>3.0, "Num_Units"=>num_units}
    _test_measure(model, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)    
  end
  
  def test_multifamily_new_construction_1
    num_units = 4
    args_hash = {}
    args_hash["Num_Br"] = "2"
    args_hash["Num_Ba"] = "1"
    expected_num_del_objects = {}
    expected_num_new_objects = {}
    expected_values = {"Beds"=>2.0, "Baths"=>1.0, "Num_Units"=>num_units}
    _test_measure("singlefamily_attached_fbsmt_4_units.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, num_units)    
  end
  
  def test_multifamily_new_construction_2
    num_units = 8
    args_hash = {}
    args_hash["Num_Br"] = "2"
    args_hash["Num_Ba"] = "1.5"
    expected_num_del_objects = {}
    expected_num_new_objects = {}
    expected_values = {"Beds"=>2.0, "Baths"=>1.5, "Num_Units"=>num_units}
    _test_measure("multifamily_8_units.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, num_units)    
  end  
  
  private
  
  def _test_error(osm_file_or_model, args_hash)
    # create an instance of the measure
    measure = AddResidentialBedroomsAndBathrooms.new

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

    # assert that it didn't run
    assert_equal("Fail", result.value.valueName)
    assert(result.errors.size == 1)
    
    return result
  end  
  
  def _test_measure(osm_file_or_model, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, num_infos=0, num_warnings=0, debug=false)
    # create an instance of the measure
    measure = AddResidentialBedroomsAndBathrooms.new

    # check for standard methods
    assert(!measure.name.empty?)
    assert(!measure.description.empty?)
    assert(!measure.modeler_description.empty?)

    # create an instance of a runner
    runner = OpenStudio::Ruleset::OSRunner.new
    
    model = get_model(File.dirname(__FILE__), osm_file_or_model)

    # get the initial objects in the model
    initial_objects = get_objects(model)   
    
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
    assert(result.info.size == num_infos)
    assert(result.warnings.size == num_warnings)
    
    # get the final objects in the model  
    final_objects = get_objects(model)
    
    # get new and deleted objects
    obj_type_exclusions = []
    all_new_objects = get_object_additions(initial_objects, final_objects, obj_type_exclusions)
    all_del_objects = get_object_additions(final_objects, initial_objects, obj_type_exclusions)
    
    # check we have the expected number of new/deleted objects
    check_num_objects(all_new_objects, expected_num_new_objects, "added")
    check_num_objects(all_del_objects, expected_num_del_objects, "deleted")

    actual_values = {"ElectricEquipment"=>0, "ElectricEquipmentDefinition"=>0}
    final_objects.each do |obj_type, final_object|
        next if not final_object.respond_to?("to_#{obj_type}")
        final_object = final_object.public_send("to_#{obj_type}").get
        if obj_type == "ElectricEquipment"
            if final_object.name.to_s.start_with?("unit=")
                actual_values["ElectricEquipment"] += 1
            end
        elsif obj_type == "ElectricEquipmentDefinition"
            if final_object.name.to_s.start_with?("unit=")
                actual_values["ElectricEquipmentDefinition"] += 1
            end            
        end
    end
    assert_equal(expected_values["Num_Units"], actual_values["ElectricEquipment"])
    assert_equal(expected_values["Num_Units"], actual_values["ElectricEquipmentDefinition"])
    
    nbeds, nbaths, spaces_list = Geometry.get_unit_beds_baths_spaces(model, 1)
    assert_in_epsilon(expected_values["Beds"], nbeds, 0.01)
    assert_in_epsilon(expected_values["Baths"], nbaths, 0.01)
    
    return model
  end 
  
end
