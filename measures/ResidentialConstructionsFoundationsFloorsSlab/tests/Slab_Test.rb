require_relative '../../../test/minitest_helper'
require 'openstudio'
require 'openstudio/ruleset/ShowRunnerOutput'
require 'minitest/autorun'
require_relative '../measure.rb'
require 'fileutils'

class ProcessConstructionsFoundationsFloorsSlabTest < MiniTest::Test

  def osm_geo_slab
    return "2000sqft_2story_SL_UA.osm"
  end

  def osm_geo_slab_garage
    return "2000sqft_2story_SL_UA_Grg.osm"
  end

  def osm_geo_crawl
    return "2000sqft_2story_CS_UA.osm"
  end

  def osm_geo_crawl_garage
    return "2000sqft_2story_CS_UA_Grg.osm"
  end

  def osm_geo_finished_basement
    return "2000sqft_2story_FB_UA.osm"
  end

  def osm_geo_finished_basement_garage
    return "2000sqft_2story_FB_UA_Grg.osm"
  end

  def osm_geo_unfinished_basement
    return "2000sqft_2story_UB_UA.osm"
  end

  def osm_geo_unfinished_basement_garage
    return "2000sqft_2story_UB_UA_Grg.osm"
  end

  def test_add_uninsulated
    args_hash = {}
    expected_num_del_objects = {}
    expected_num_new_objects = {"Material"=>3, "Construction"=>1}
    expected_values = {"LayerRValue"=>0.0254/0.02949+0.3048/1.731+0.1016/1.3127, "LayerDensity"=>40.05+1842.3+2242.8, "LayerSpecificHeat"=>1214.23+418.7+837.4, "LayerIndex"=>0+1+2}
    _test_measure(osm_geo_slab, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)
  end

  def test_add_2ft_r5_perimeter_r5_gap
    args_hash = {}
    args_hash["perim_r"] = 5
    args_hash["perim_width"] = 2
    args_hash["gap_r"] = 5
    expected_num_del_objects = {}
    expected_num_new_objects = {"Material"=>3, "Construction"=>1}
    expected_values = {"LayerRValue"=>0.0254/0.01838+0.3048/1.731+0.1016/1.3127, "LayerDensity"=>40.05+1842.3+2242.8, "LayerSpecificHeat"=>1214.23+418.7+837.4, "LayerIndex"=>0+1+2}
    _test_measure(osm_geo_slab, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)
  end

  def test_add_4ft_r15_exterior
    args_hash = {}
    args_hash["ext_depth"] = 4
    args_hash["ext_r"] = 15
    expected_num_del_objects = {}
    expected_num_new_objects = {"Material"=>3, "Construction"=>1}
    expected_values = {"LayerRValue"=>0.0254/0.00845+0.3048/1.731+0.1016/1.3127, "LayerDensity"=>40.05+1842.3+2242.8, "LayerSpecificHeat"=>1214.23+418.7+837.4, "LayerIndex"=>0+1+2}
    _test_measure(osm_geo_slab, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)
  end

  def test_add_whole_slab_r20_r10_gap
    args_hash = {}
    args_hash["whole_r"] = 20
    args_hash["gap_r"] = 10
    expected_num_del_objects = {}
    expected_num_new_objects = {"Material"=>3, "Construction"=>1}
    expected_values = {"LayerRValue"=>0.0254/0.00571+0.3048/1.731+0.1016/1.3127, "LayerDensity"=>40.05+1842.3+2242.8, "LayerSpecificHeat"=>1214.23+418.7+837.4, "LayerIndex"=>0+1+2}
    _test_measure(osm_geo_slab, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)
  end

  def test_add_whole_slab_r20_r10_gap_garage
    args_hash = {}
    args_hash["whole_r"] = 20
    args_hash["gap_r"] = 10
    expected_num_del_objects = {}
    expected_num_new_objects = {"Material"=>3, "Construction"=>1}
    expected_values = {"LayerRValue"=>0.0254/0.00743+0.3048/1.731+0.1016/1.3127, "LayerDensity"=>40.05+1842.3+2242.8, "LayerSpecificHeat"=>1214.23+418.7+837.4, "LayerIndex"=>0+1+2}
    _test_measure(osm_geo_slab_garage, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)
  end

  def test_argument_error_perim_r_negative
    args_hash = {}
    args_hash["perim_r"] = -1
    result = _test_error(osm_geo_slab, args_hash)
    assert_equal(result.errors.map{ |x| x.logMessage }[0], "Perimeter Insulation Nominal R-value must be greater than or equal to 0.")
  end
    
  def test_argument_error_perim_width_negative
    args_hash = {}
    args_hash["perim_width"] = -1
    result = _test_error(osm_geo_slab, args_hash)
    assert_equal(result.errors.map{ |x| x.logMessage }[0], "Perimeter Insulation Width must be greater than or equal to 0.")
  end

  def test_argument_error_whole_r_negative
    args_hash = {}
    args_hash["whole_r"] = -1
    result = _test_error(osm_geo_slab, args_hash)
    assert_equal(result.errors.map{ |x| x.logMessage }[0], "Whole Slab Insulation Nominal R-value must be greater than or equal to 0.")
  end

  def test_argument_error_gap_r_negative
    args_hash = {}
    args_hash["gap_r"] = -1
    result = _test_error(osm_geo_slab, args_hash)
    assert_equal(result.errors.map{ |x| x.logMessage }[0], "Gap Insulation Nominal R-value must be greater than or equal to 0.")
  end

  def test_argument_error_ext_r_negative
    args_hash = {}
    args_hash["ext_r"] = -1
    result = _test_error(osm_geo_slab, args_hash)
    assert_equal(result.errors.map{ |x| x.logMessage }[0], "Exterior Insulation Nominal R-value must be greater than or equal to 0.")
  end

  def test_argument_error_ext_depth_negative
    args_hash = {}
    args_hash["ext_depth"] = -1
    result = _test_error(osm_geo_slab, args_hash)
    assert_equal(result.errors.map{ |x| x.logMessage }[0], "Exterior Insulation Depth must be greater than or equal to 0.")
  end

  def test_argument_error_mass_thick_in_zero
    args_hash = {}
    args_hash["mass_thick_in"] = 0
    result = _test_error(osm_geo_slab, args_hash)
    assert_equal(result.errors.map{ |x| x.logMessage }[0], "Mass Thickness must be greater than 0.")
  end

  def test_argument_error_mass_conductivity_zero
    args_hash = {}
    args_hash["mass_conductivity"] = 0
    result = _test_error(osm_geo_slab, args_hash)
    assert_equal(result.errors.map{ |x| x.logMessage }[0], "Mass Conductivity must be greater than 0.")
  end

  def test_argument_error_mass_density_zero
    args_hash = {}
    args_hash["mass_density"] = 0
    result = _test_error(osm_geo_slab, args_hash)
    assert_equal(result.errors.map{ |x| x.logMessage }[0], "Mass Density must be greater than 0.")
  end

  def test_argument_error_mass_specific_heat_zero
    args_hash = {}
    args_hash["mass_specific_heat"] = 0
    result = _test_error(osm_geo_slab, args_hash)
    assert_equal(result.errors.map{ |x| x.logMessage }[0], "Mass Specific Heat must be greater than 0.")
  end
  
  def test_argument_error_perimeter_insulation
    args_hash = {}
    args_hash["perim_r"] = 5
    args_hash["perim_width"] = 0
    result = _test_error(osm_geo_slab, args_hash)
    assert_equal(result.errors.map{ |x| x.logMessage }[0], "Perimeter insulation does not have both properties (R-value and Width) entered.")
  end

  def test_argument_error_exterior_insulation
    args_hash = {}
    args_hash["ext_r"] = 0
    args_hash["ext_depth"] = 5
    result = _test_error(osm_geo_slab, args_hash)
    assert_equal(result.errors.map{ |x| x.logMessage }[0], "Exterior insulation does not have both properties (R-value and Depth) entered.")
  end

  def test_argument_error_invalid_configuration
    args_hash = {}
    args_hash["whole_r"] = 10
    args_hash["ext_r"] = 10
    args_hash["ext_depth"] = 10
    result = _test_error(osm_geo_slab, args_hash)
    assert_equal(result.errors.map{ |x| x.logMessage }[0], "Invalid insulation configuration. The only valid configurations are: Exterior, Perimeter+Gap, Whole+Gap, Perimeter, or Whole.")
  end

  def test_not_applicable_no_geometry
    args_hash = {}
    _test_na(nil, args_hash)
  end

  def test_not_applicable_crawl
    args_hash = {}
    _test_na(osm_geo_crawl, args_hash)
  end

  def test_not_applicable_crawl_garage
    args_hash = {}
    _test_na(osm_geo_crawl_garage, args_hash)
  end

  def test_not_applicable_finished_basement
    args_hash = {}
    _test_na(osm_geo_finished_basement, args_hash)
  end

  def test_not_applicable_finished_basement_garage
    args_hash = {}
    _test_na(osm_geo_finished_basement_garage, args_hash)
  end
  
  def test_not_applicable_unfinished_basement
    args_hash = {}
    _test_na(osm_geo_unfinished_basement, args_hash)
  end

  def test_not_applicable_unfinished_basement_garage
    args_hash = {}
    _test_na(osm_geo_unfinished_basement_garage, args_hash)
  end

  private
  
  def _test_error(osm_file, args_hash)
    # create an instance of the measure
    measure = ProcessConstructionsFoundationsFloorsSlab.new

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
    measure = ProcessConstructionsFoundationsFloorsSlab.new

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
    measure = ProcessConstructionsFoundationsFloorsSlab.new

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
    assert_in_epsilon(expected_values["LayerRValue"], actual_values["LayerRValue"], 0.01)
    assert_in_epsilon(expected_values["LayerDensity"], actual_values["LayerDensity"], 0.01)
    assert_in_epsilon(expected_values["LayerSpecificHeat"], actual_values["LayerSpecificHeat"], 0.01)
    assert_in_epsilon(expected_values["LayerIndex"], actual_values["LayerIndex"], 0.01)
    
    return model
  end
  
end
