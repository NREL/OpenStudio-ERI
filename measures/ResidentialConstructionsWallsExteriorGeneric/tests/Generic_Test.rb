require_relative '../../../test/minitest_helper'
require 'openstudio'
require 'openstudio/ruleset/ShowRunnerOutput'
require 'minitest/autorun'
require_relative '../measure.rb'
require 'fileutils'

class ProcessConstructionsWallsExteriorGenericTest < MiniTest::Test

  def osm_geo
    return "2000sqft_2story_SL_UA.osm"
  end
  
  def osm_geo_layers
    return "2000sqft_2story_SL_UA_layers.osm"
  end

  def test_add_tmass_wall_metal_ties
    args_hash = {}
    args_hash["thick_in_1"] = 2.5
    args_hash["thick_in_2"] = 3.0
    args_hash["thick_in_3"] = 2.5
    args_hash["conductivity_1"] = 9.211
    args_hash["conductivity_2"] = 0.425
    args_hash["conductivity_3"] = 7.471
    args_hash["density_1"] = 138.33
    args_hash["density_2"] = 2.6
    args_hash["density_3"] = 136.59
    args_hash["specific_heat_1"] = 0.23
    args_hash["specific_heat_2"] = 0.28
    args_hash["specific_heat_3"] = 0.28
    expected_num_del_objects = {}
    expected_num_new_objects = {"Material"=>3, "Construction"=>1}
    expected_values = {"LayerRValue"=>0.0635/1.3286+0.0762/0.0613+0.0635/1.0777, "LayerDensity"=>2216.046+41.652+2188.172, "LayerSpecificHeat"=>963.01+1172.36+1172.36, "LayerIndex"=>0+1+2}
    _test_measure(osm_geo, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)
  end

  def test_add_10in_grid_icf
    args_hash = {}
    args_hash["thick_in_1"] = 2.75
    args_hash["thick_in_2"] = 3.725
    args_hash["thick_in_3"] = 3.5
    args_hash["conductivity_1"] = 0.4429
    args_hash["conductivity_2"] = 3.457
    args_hash["conductivity_3"] = 0.927
    args_hash["density_1"] = 66.48
    args_hash["density_2"] = 97.0
    args_hash["density_3"] = 52.03
    args_hash["specific_heat_1"] = 0.25
    args_hash["specific_heat_2"] = 0.21
    args_hash["specific_heat_3"] = 0.25
    expected_num_del_objects = {}
    expected_num_new_objects = {"Material"=>3, "Construction"=>1}
    expected_values = {"LayerRValue"=>0.06985/0.0638+0.0946/0.4986+0.0889/0.1337, "LayerDensity"=>1065.01+1553.94+833.52, "LayerSpecificHeat"=>1046.75+879.27+1046.75, "LayerIndex"=>0+1+2}
    _test_measure(osm_geo, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)
  end

  def test_add_10in_grid_icf_to_layers
    args_hash = {}
    args_hash["thick_in_1"] = 2.75
    args_hash["thick_in_2"] = 3.725
    args_hash["thick_in_3"] = 3.5
    args_hash["conductivity_1"] = 0.4429
    args_hash["conductivity_2"] = 3.457
    args_hash["conductivity_3"] = 0.927
    args_hash["density_1"] = 66.48
    args_hash["density_2"] = 97.0
    args_hash["density_3"] = 52.03
    args_hash["specific_heat_1"] = 0.25
    args_hash["specific_heat_2"] = 0.21
    args_hash["specific_heat_3"] = 0.25
    expected_num_del_objects = {"Construction"=>1}
    expected_num_new_objects = {"Material"=>3, "Construction"=>1}
    expected_values = {"LayerRValue"=>0.06985/0.0638+0.0946/0.4986+0.0889/0.1337, "LayerDensity"=>1065.01+1553.94+833.52, "LayerSpecificHeat"=>1046.75+879.27+1046.75, "LayerIndex"=>2+3+4}
    _test_measure(osm_geo_layers, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)
  end

  def test_argument_error_thick_in_1_negative
    args_hash = {}
    args_hash["thick_in_1"] = -1
    result = _test_error(osm_geo, args_hash)
    assert_equal(result.errors.map{ |x| x.logMessage }[0], "Thickness 1 must be greater than 0.")
  end
    
  def test_argument_error_thick_in_1_zero
    args_hash = {}
    args_hash["thick_in_1"] = 0
    result = _test_error(osm_geo, args_hash)
    assert_equal(result.errors.map{ |x| x.logMessage }[0], "Thickness 1 must be greater than 0.")
  end

  def test_argument_error_conductivity_1_negative
    args_hash = {}
    args_hash["conductivity_1"] = -1
    result = _test_error(osm_geo, args_hash)
    assert_equal(result.errors.map{ |x| x.logMessage }[0], "Conductivity 1 must be greater than 0.")
  end

  def test_argument_error_conductivity_1_zero
    args_hash = {}
    args_hash["conductivity_1"] = 0
    result = _test_error(osm_geo, args_hash)
    assert_equal(result.errors.map{ |x| x.logMessage }[0], "Conductivity 1 must be greater than 0.")
  end

  def test_argument_error_density_1_negative
    args_hash = {}
    args_hash["density_1"] = -1
    result = _test_error(osm_geo, args_hash)
    assert_equal(result.errors.map{ |x| x.logMessage }[0], "Density 1 must be greater than 0.")
  end

  def test_argument_error_density_1_zero
    args_hash = {}
    args_hash["density_1"] = 0
    result = _test_error(osm_geo, args_hash)
    assert_equal(result.errors.map{ |x| x.logMessage }[0], "Density 1 must be greater than 0.")
  end

  def test_argument_error_specific_heat_1_negative
    args_hash = {}
    args_hash["specific_heat_1"] = -1
    result = _test_error(osm_geo, args_hash)
    assert_equal(result.errors.map{ |x| x.logMessage }[0], "Specific Heat 1 must be greater than 0.")
  end

  def test_argument_error_specific_heat_1_zero
    args_hash = {}
    args_hash["specific_heat_1"] = 0
    result = _test_error(osm_geo, args_hash)
    assert_equal(result.errors.map{ |x| x.logMessage }[0], "Specific Heat 1 must be greater than 0.")
  end
  
  def test_argument_error_layer_2_missing_properties
    args_hash = {}
    args_hash["thick_in_1"] = 0.5
    args_hash["thick_in_2"] = 0.5
    args_hash["conductivity_1"] = 0.5
    args_hash["conductivity_2"] = 0.5
    args_hash["density_1"] = 0.5
    args_hash["density_2"] = 0.5
    args_hash["specific_heat_1"] = 0.5
    result = _test_error(osm_geo, args_hash)
    assert_equal(result.errors.map{ |x| x.logMessage }[0], "Layer 2 does not have all four properties (thickness, conductivity, density, specific heat) entered.")
  end

  def test_not_applicable_no_geometry
    args_hash = {}
    _test_na(nil, args_hash)
  end

  private
  
  def _test_error(osm_file, args_hash)
    # create an instance of the measure
    measure = ProcessConstructionsWallsExteriorGeneric.new

    # create an instance of a runner
    runner = OpenStudio::Ruleset::OSRunner.new

    model = get_model(File.dirname(__FILE__), osm_file)

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

    # show the output
    #show_output(result)

    # assert that it didn't run
    assert_equal("Fail", result.value.valueName)
    assert(result.errors.size == 1)
    
    return result
  end
  
  def _test_na(osm_file, args_hash)
    # create an instance of the measure
    measure = ProcessConstructionsWallsExteriorGeneric.new

    # create an instance of a runner
    runner = OpenStudio::Ruleset::OSRunner.new

    model = get_model(File.dirname(__FILE__), osm_file)

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

    # show the output
    #show_output(result)

    # assert that it returned NA
    assert_equal("NA", result.value.valueName)
    assert(result.info.size == 1)
    
    return result
  end

  def _test_measure(osm_file_or_model, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)
    # create an instance of the measure
    measure = ProcessConstructionsWallsExteriorGeneric.new

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

    # show the output
    #show_output(result)

    # assert that it ran correctly
    assert_equal("Success", result.value.valueName)
    
    # get the final objects in the model
    final_objects = get_objects(model)

    # get new and deleted objects
    obj_type_exclusions = []
    all_new_objects = get_object_additions(initial_objects, final_objects, obj_type_exclusions)
    all_del_objects = get_object_additions(final_objects, initial_objects, obj_type_exclusions)
    
    # check we have the expected number of new/deleted objects
    check_num_objects(all_new_objects, expected_num_new_objects, "added")
    check_num_objects(all_del_objects, expected_num_del_objects, "deleted")
    
    actual_values = {"LayerRValue"=>0, "LayerDensity"=>0, "LayerSpecificHeat"=>0, "LayerIndex"=>0}
    all_new_objects.each do |obj_type, new_objects|
        new_objects.each do |new_object|
            next if not new_object.respond_to?("to_#{obj_type}")
            new_object = new_object.public_send("to_#{obj_type}").get
            if obj_type == "Material"
                new_object = new_object.to_StandardOpaqueMaterial.get
                actual_values["LayerRValue"] += new_object.thickness/new_object.conductivity
                actual_values["LayerDensity"] += new_object.density
                actual_values["LayerSpecificHeat"] += new_object.specificHeat
            elsif obj_type == "Construction"
                next if !all_new_objects.keys.include?("Material")
                all_new_objects["Material"].each do |new_material|
                    new_material = new_material.to_StandardOpaqueMaterial.get
                    actual_values["LayerIndex"] += new_object.getLayerIndices(new_material)[0]
                end
            end
        end
    end
    assert_in_epsilon(expected_values["LayerRValue"], actual_values["LayerRValue"], 0.02)
    assert_in_epsilon(expected_values["LayerDensity"], actual_values["LayerDensity"], 0.02)
    assert_in_epsilon(expected_values["LayerSpecificHeat"], actual_values["LayerSpecificHeat"], 0.02)
    assert_in_epsilon(expected_values["LayerIndex"], actual_values["LayerIndex"], 0.02)
    
    return model
  end
  
end
