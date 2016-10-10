require_relative '../../../test/minitest_helper'
require 'openstudio'
require 'openstudio/ruleset/ShowRunnerOutput'
require 'minitest/autorun'
require_relative '../measure.rb'
require 'fileutils'

class ProcessConstructionsCeilingsRoofsFinishedRoofTest < MiniTest::Test

  def osm_geo_finished_attic
    return "2000sqft_2story_SL_FA.osm"
  end

  def osm_geo_finished_attic_roof_material
    return "2000sqft_2story_SL_FA_roof_material.osm"
  end

  def osm_geo_finished_attic_roof_sheathing
    return "2000sqft_2story_SL_FA_roof_sheathing.osm"
  end

  def osm_geo_finished_attic_ceiling_mass
    return "2000sqft_2story_SL_FA_ceiling_mass.osm"
  end

  def osm_geo_finished_attic_all_other_layers
    return "2000sqft_2story_SL_FA_all_other_layers.osm"
  end

  def osm_geo_unfinished_attic
    return "2000sqft_2story_FB_GRG_UA.osm"
  end
  
  def test_set_uninsulated_2x6
    args_hash = {}
    args_hash["cavity_r"] = 0
    args_hash["install_grade"] = "I" # no insulation, shouldn't apply
    args_hash["cavity_depth"] = 5.5
    args_hash["ins_fills_cavity"] = false # no insulation, shouldn't apply
    args_hash["framing_factor"] = 0.07
    expected_num_del_objects = {}
    expected_num_new_objects = {"Material"=>1, "Construction"=>1}
    expected_values = {"LayerThickness"=>0.140, "LayerConductivity"=>0.682, "LayerDensity"=>36.952, "LayerSpecificHeat"=>1208.183, "LayerIndex"=>0}
    _test_measure(osm_geo_finished_attic, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)
  end
  
  def test_set_uninsulated_2x6_gr3_ins_fills_cavity
    args_hash = {}
    args_hash["cavity_r"] = 0
    args_hash["install_grade"] = "III" # no insulation, shouldn't apply
    args_hash["cavity_depth"] = 5.5
    args_hash["ins_fills_cavity"] = true # no insulation, shouldn't apply
    args_hash["framing_factor"] = 0.07
    expected_num_del_objects = {}
    expected_num_new_objects = {"Material"=>1, "Construction"=>1}
    expected_values = {"LayerThickness"=>0.140, "LayerConductivity"=>0.682, "LayerDensity"=>36.952, "LayerSpecificHeat"=>1208.183, "LayerIndex"=>0}
    _test_measure(osm_geo_finished_attic, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)
  end

  def test_set_r19_2x6_gr1
    args_hash = {}
    args_hash["cavity_r"] = 17.3 # compressed R-value
    args_hash["install_grade"] = "I"
    args_hash["cavity_depth"] = 5.5
    args_hash["ins_fills_cavity"] = true
    args_hash["framing_factor"] = 0.07
    expected_num_del_objects = {}
    expected_num_new_objects = {"Material"=>1, "Construction"=>1}
    expected_values = {"LayerThickness"=>0.140, "LayerConductivity"=>0.050, "LayerDensity"=>78.346, "LayerSpecificHeat"=>1123.461, "LayerIndex"=>0}
    _test_measure(osm_geo_finished_attic, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)
  end

  def test_set_r19_2x10_gr3_ff11
    args_hash = {}
    args_hash["cavity_r"] = 19
    args_hash["install_grade"] = "III"
    args_hash["cavity_depth"] = 9.25
    args_hash["ins_fills_cavity"] = false
    args_hash["framing_factor"] = 0.11
    expected_num_del_objects = {}
    expected_num_new_objects = {"Material"=>1, "Construction"=>1}
    expected_values = {"LayerThickness"=>0.235, "LayerConductivity"=>0.090, "LayerDensity"=>95.044, "LayerSpecificHeat"=>1146.094, "LayerIndex"=>0}
    _test_measure(osm_geo_finished_attic, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)
  end

  def test_add_r19_2x8_gr1_to_roof_material
    args_hash = {}
    args_hash["cavity_r"] = 19
    args_hash["install_grade"] = "I"
    args_hash["cavity_depth"] = 7.25
    args_hash["ins_fills_cavity"] = false
    args_hash["framing_factor"] = 0.07
    expected_num_del_objects = {"Construction"=>1}
    expected_num_new_objects = {"Material"=>1, "Construction"=>1}
    expected_values = {"LayerThickness"=>0.184, "LayerConductivity"=>0.056, "LayerDensity"=>78.346, "LayerSpecificHeat"=>1123.461, "LayerIndex"=>1}
    _test_measure(osm_geo_finished_attic_roof_material, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)
  end

  def test_add_r19_2x8_gr1_to_roof_sheathing
    args_hash = {}
    args_hash["cavity_r"] = 19
    args_hash["install_grade"] = "I"
    args_hash["cavity_depth"] = 7.25
    args_hash["ins_fills_cavity"] = false
    args_hash["framing_factor"] = 0.07
    expected_num_del_objects = {"Construction"=>1}
    expected_num_new_objects = {"Material"=>1, "Construction"=>1}
    expected_values = {"LayerThickness"=>0.184, "LayerConductivity"=>0.056, "LayerDensity"=>78.346, "LayerSpecificHeat"=>1123.461, "LayerIndex"=>1}
    _test_measure(osm_geo_finished_attic_roof_sheathing, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)
  end

  def test_add_r19_2x8_gr1_to_ceiling_mass
    args_hash = {}
    args_hash["cavity_r"] = 19
    args_hash["install_grade"] = "I"
    args_hash["cavity_depth"] = 7.25
    args_hash["ins_fills_cavity"] = false
    args_hash["framing_factor"] = 0.07
    expected_num_del_objects = {}
    expected_num_new_objects = {"Material"=>1, "Construction"=>1}
    expected_values = {"LayerThickness"=>0.184, "LayerConductivity"=>0.056, "LayerDensity"=>78.346, "LayerSpecificHeat"=>1123.461, "LayerIndex"=>0}
    _test_measure(osm_geo_finished_attic_ceiling_mass, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)
  end

  def test_add_r19_2x8_gr1_to_all_other_layers_and_replace_with_r30c
    args_hash = {}
    args_hash["cavity_r"] = 19
    args_hash["install_grade"] = "I"
    args_hash["cavity_depth"] = 7.25
    args_hash["ins_fills_cavity"] = false
    args_hash["framing_factor"] = 0.07
    expected_num_del_objects = {"Construction"=>1}
    expected_num_new_objects = {"Material"=>1, "Construction"=>1}
    expected_values = {"LayerThickness"=>0.184, "LayerConductivity"=>0.056, "LayerDensity"=>78.346, "LayerSpecificHeat"=>1123.461, "LayerIndex"=>2}
    model = _test_measure(osm_geo_finished_attic_all_other_layers, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)
    args_hash["cavity_r"] = 28.1 # compressed R-value
    args_hash["ins_fills_cavity"] = true
    expected_num_del_objects = {"Material"=>1, "Construction"=>1}
    expected_num_new_objects = {"Material"=>1, "Construction"=>1}
    expected_values = {"LayerThickness"=>0.184, "LayerConductivity"=>0.042, "LayerDensity"=>78.346, "LayerSpecificHeat"=>1123.461, "LayerIndex"=>2}
    _test_measure(model, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)
  end

  def test_argument_error_cavity_r_negative
    args_hash = {}
    args_hash["cavity_r"] = -1
    result = _test_error(osm_geo_finished_attic, args_hash)
    assert_equal(result_errors(result)[0], "Cavity Insulation Installed R-value must be greater than or equal to 0.")
  end
    
  def test_argument_error_cavity_depth_negative
    args_hash = {}
    args_hash["cavity_depth"] = -1
    result = _test_error(osm_geo_finished_attic, args_hash)
    assert_equal(result_errors(result)[0], "Cavity Depth must be greater than 0.")
  end

  def test_argument_error_cavity_depth_zero
    args_hash = {}
    args_hash["cavity_depth"] = 0
    result = _test_error(osm_geo_finished_attic, args_hash)
    assert_equal(result_errors(result)[0], "Cavity Depth must be greater than 0.")
  end

  def test_argument_error_framing_factor_negative
    args_hash = {}
    args_hash["framing_factor"] = -1
    result = _test_error(osm_geo_finished_attic, args_hash)
    assert_equal(result_errors(result)[0], "Framing Factor must be greater than or equal to 0 and less than 1.")
  end

  def test_argument_error_framing_factor_eq_1
    args_hash = {}
    args_hash["framing_factor"] = 1.0
    result = _test_error(osm_geo_finished_attic, args_hash)
    assert_equal(result_errors(result)[0], "Framing Factor must be greater than or equal to 0 and less than 1.")
  end

  def test_not_applicable_attic
    args_hash = {}
    expected_num_del_objects = {}
    expected_num_new_objects = {}
    expected_values = {}
    _test_na(osm_geo_unfinished_attic, args_hash)
  end

  def test_not_applicable_no_geometry
    args_hash = {}
    expected_num_del_objects = {}
    expected_num_new_objects = {}
    expected_values = {}
    _test_na(nil, args_hash)
  end

  private
  
  def _test_error(osm_file, args_hash)
    # create an instance of the measure
    measure = ProcessConstructionsCeilingsRoofsFinishedRoof.new

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
    assert_equal("Fail", result_value(result))
    assert(result_errors(result).size == 1)
    
    return result
  end
  
  def _test_na(osm_file, args_hash)
    # create an instance of the measure
    measure = ProcessConstructionsCeilingsRoofsFinishedRoof.new

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
    assert_equal("NA", result_value(result))
    assert(result_infos(result).size == 1)
    
    return result
  end

  def _test_measure(osm_file_or_model, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)
    # create an instance of the measure
    measure = ProcessConstructionsCeilingsRoofsFinishedRoof.new

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
    assert_equal("Success", result_value(result))
    
    # get the final objects in the model
    final_objects = get_objects(model)

    # get new and deleted objects
    obj_type_exclusions = []
    all_new_objects = get_object_additions(initial_objects, final_objects, obj_type_exclusions)
    all_del_objects = get_object_additions(final_objects, initial_objects, obj_type_exclusions)
    
    # check we have the expected number of new/deleted objects
    check_num_objects(all_new_objects, expected_num_new_objects, "added")
    check_num_objects(all_del_objects, expected_num_del_objects, "deleted")
    
    actual_values = {"LayerThickness"=>0, "LayerConductivity"=>0, "LayerDensity"=>0, "LayerSpecificHeat"=>0, "LayerIndex"=>0}
    all_new_objects.each do |obj_type, new_objects|
        new_objects.each do |new_object|
            next if not new_object.respond_to?("to_#{obj_type}")
            new_object = new_object.public_send("to_#{obj_type}").get
            if obj_type == "Material"
                new_object = new_object.to_StandardOpaqueMaterial.get
                actual_values["LayerThickness"] += new_object.thickness
                actual_values["LayerConductivity"] += new_object.conductivity
                actual_values["LayerDensity"] += new_object.density
                actual_values["LayerSpecificHeat"] += new_object.specificHeat
            elsif obj_type == "Construction"
                new_material = all_new_objects["Material"][0].to_StandardOpaqueMaterial.get
                actual_values["LayerIndex"] += new_object.getLayerIndices(new_material)[0]
            end
        end
    end
    assert_in_epsilon(expected_values["LayerThickness"], actual_values["LayerThickness"], 0.01)
    assert_in_epsilon(expected_values["LayerConductivity"], actual_values["LayerConductivity"], 0.01)
    assert_in_epsilon(expected_values["LayerDensity"], actual_values["LayerDensity"], 0.01)
    assert_in_epsilon(expected_values["LayerSpecificHeat"], actual_values["LayerSpecificHeat"], 0.01)
    assert_in_epsilon(expected_values["LayerIndex"], actual_values["LayerIndex"], 0.01)
    
    return model
  end
  
end
