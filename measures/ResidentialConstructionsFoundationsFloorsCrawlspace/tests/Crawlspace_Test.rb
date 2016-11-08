require_relative '../../../test/minitest_helper'
require 'openstudio'
require 'openstudio/ruleset/ShowRunnerOutput'
require 'minitest/autorun'
require_relative '../measure.rb'
require 'fileutils'

class ProcessConstructionsFoundationsFloorsCrawlspaceTest < MiniTest::Test

  def osm_geo_slab
    return "2000sqft_2story_SL_UA.osm"
  end

  def osm_geo_slab_garage
    return "2000sqft_2story_SL_GRG_UA.osm"
  end

  def osm_geo_crawl
    return "2000sqft_2story_CS_UA.osm"
  end

  def osm_geo_crawl_garage
    return "2000sqft_2story_CS_GRG_UA.osm"
  end

  def osm_geo_finished_basement
    return "2000sqft_2story_FB_UA.osm"
  end

  def osm_geo_finished_basement_garage
    return "2000sqft_2story_FB_GRG_UA.osm"
  end

  def osm_geo_unfinished_basement
    return "2000sqft_2story_UB_UA.osm"
  end

  def osm_geo_unfinished_basement_garage
    return "2000sqft_2story_UB_GRG_UA.osm"
  end

  def test_add_uninsulated
    args_hash = {}
    args_hash["wall_rigid_r"] = 0
    args_hash["wall_rigid_thick_in"] = 0
    args_hash["ceil_cavity_r"] = 0
    args_hash["ceil_cavity_grade"] = "II" # no insulation, shouldn't apply
    args_hash["ceil_ff"] = 0.13
    args_hash["ceil_joist_height"] = 9.25
    expected_num_del_objects = {}
    expected_num_new_objects = {"Material"=>4, "Construction"=>3}
    expected_values = {"LayerRValue"=>0.23495/2.59817+0.3048/1.731+0.2032/1.3114+11.24877, "LayerDensity"=>67.641+1842.3+2242.8, "LayerSpecificHeat"=>1211.14+418.7+837.4, "LayerIndex"=>0+0+1+0+1}
    _test_measure(osm_geo_crawl, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)
  end

  def test_add_wall_r10
    args_hash = {}
    args_hash["wall_rigid_r"] = 10
    args_hash["wall_rigid_thick_in"] = 2
    args_hash["ceil_cavity_r"] = 0
    args_hash["ceil_cavity_grade"] = "II" # no insulation, shouldn't apply
    args_hash["ceil_ff"] = 0.13
    args_hash["ceil_joist_height"] = 9.25
    expected_num_del_objects = {}
    expected_num_new_objects = {"Material"=>5, "Construction"=>3}
    expected_values = {"LayerRValue"=>0.23495/2.59817+0.3048/1.731+0.2032/1.3114+0.0508/0.02885+2.401, "LayerDensity"=>67.641+1842.3+2242.8+32.04, "LayerSpecificHeat"=>1211.14+418.7+837.4+1214.23, "LayerIndex"=>0+0+1+2+0+1}
    _test_measure(osm_geo_crawl, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)
  end

  def test_add_ceiling_r13_gr3
    args_hash = {}
    args_hash["wall_rigid_r"] = 0
    args_hash["wall_rigid_thick_in"] = 0
    args_hash["ceil_cavity_r"] = 13
    args_hash["ceil_cavity_grade"] = "III"
    args_hash["ceil_ff"] = 0.13
    args_hash["ceil_joist_height"] = 9.25
    expected_num_del_objects = {}
    expected_num_new_objects = {"Material"=>4, "Construction"=>3}
    expected_values = {"LayerRValue"=>0.23495/0.11686+0.3048/1.731+0.2032/1.3114+11.235, "LayerDensity"=>104.429+1842.3+2242.8, "LayerSpecificHeat"=>1153.611+418.7+837.4, "LayerIndex"=>0+0+1+0+1}
    _test_measure(osm_geo_crawl, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)
  end

  def test_add_wall_r10_garage
    args_hash = {}
    args_hash["wall_rigid_r"] = 10
    args_hash["wall_rigid_thick_in"] = 2
    args_hash["ceil_cavity_r"] = 0
    args_hash["ceil_cavity_grade"] = "II" # no insulation, shouldn't apply
    args_hash["ceil_ff"] = 0.13
    args_hash["ceil_joist_height"] = 9.25
    expected_num_del_objects = {}
    expected_num_new_objects = {"Material"=>5, "Construction"=>3}
    expected_values = {"LayerRValue"=>0.23495/2.59817+0.3048/1.731+0.2032/1.3114+0.0508/0.02885+1.881, "LayerDensity"=>67.641+1842.3+2242.8+32.04, "LayerSpecificHeat"=>1211.14+418.7+837.4+1214.23, "LayerIndex"=>0+0+1+2+0+1}
    _test_measure(osm_geo_crawl_garage, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)
  end

  def test_argument_error_wall_rigid_r_negative
    args_hash = {}
    args_hash["wall_rigid_r"] = -1
    result = _test_error(osm_geo_crawl, args_hash)
    assert_equal(result.errors.map{ |x| x.logMessage }[0], "Wall Continuous Insulation Nominal R-value must be greater than or equal to 0.")
  end
    
  def test_argument_error_wall_rigid_thick_in_negative
    args_hash = {}
    args_hash["wall_rigid_thick_in"] = -1
    result = _test_error(osm_geo_crawl, args_hash)
    assert_equal(result.errors.map{ |x| x.logMessage }[0], "Wall Continuous Insulation Thickness must be greater than or equal to 0.")
  end

  def test_argument_error_ceil_cavity_r_negative
    args_hash = {}
    args_hash["ceil_cavity_r"] = -1
    result = _test_error(osm_geo_crawl, args_hash)
    assert_equal(result.errors.map{ |x| x.logMessage }[0], "Ceiling Cavity Insulation Nominal R-value must be greater than or equal to 0.")
  end

  def test_argument_error_ceil_ff_negative
    args_hash = {}
    args_hash["ceil_ff"] = -1
    result = _test_error(osm_geo_crawl, args_hash)
    assert_equal(result.errors.map{ |x| x.logMessage }[0], "Ceiling Framing Factor must be greater than or equal to 0 and less than 1.")
  end

  def test_argument_error_ceil_ff_eq_1
    args_hash = {}
    args_hash["ceil_ff"] = 1
    result = _test_error(osm_geo_crawl, args_hash)
    assert_equal(result.errors.map{ |x| x.logMessage }[0], "Ceiling Framing Factor must be greater than or equal to 0 and less than 1.")
  end

  def test_argument_error_ceil_joist_height_zero
    args_hash = {}
    args_hash["ceil_joist_height"] =0
    result = _test_error(osm_geo_crawl, args_hash)
    assert_equal(result.errors.map{ |x| x.logMessage }[0], "Ceiling Joist Height must be greater than 0.")
  end

  def test_not_applicable_no_geometry
    args_hash = {}
    _test_na(nil, args_hash)
  end

  def test_not_applicable_slab
    args_hash = {}
    _test_na(osm_geo_slab, args_hash)
  end

  def test_not_applicable_slab_garage
    args_hash = {}
    _test_na(osm_geo_slab_garage, args_hash)
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
    measure = ProcessConstructionsFoundationsFloorsCrawlspace.new

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
    measure = ProcessConstructionsFoundationsFloorsCrawlspace.new

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
    measure = ProcessConstructionsFoundationsFloorsCrawlspace.new

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
                if new_object.to_StandardOpaqueMaterial.is_initialized
                    new_object = new_object.to_StandardOpaqueMaterial.get
                    actual_values["LayerRValue"] += new_object.thickness/new_object.conductivity
                else
                    new_object = new_object.to_MasslessOpaqueMaterial.get
                    actual_values["LayerRValue"] += new_object.thermalResistance
                end
                actual_values["LayerDensity"] += new_object.density
                actual_values["LayerSpecificHeat"] += new_object.specificHeat
            elsif obj_type == "Construction"
                next if !all_new_objects.keys.include?("Material")
                all_new_objects["Material"].each do |new_material|
                    if new_material.to_StandardOpaqueMaterial.is_initialized
                        new_material = new_material.to_StandardOpaqueMaterial.get
                    else
                        new_material = new_material.to_MasslessOpaqueMaterial.get
                    end
                    next if new_object.getLayerIndices(new_material)[0].nil?
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
