require_relative '../../../test/minitest_helper'
require 'openstudio'
require 'openstudio/ruleset/ShowRunnerOutput'
require 'minitest/autorun'
require_relative '../measure.rb'
require 'fileutils'

class ProcessConstructionsFoundationsFloorsSheathingTest < MiniTest::Test

  def osm_geo
    return "SFD_2000sqft_2story_FB_UA.osm"
  end
  
  def test_argument_error_osb_thick_in_negative
    args_hash = {}
    args_hash["osb_thick_in"] = -1
    result = _test_error(osm_geo, args_hash)
    assert_equal(result.errors.map{ |x| x.logMessage }[0], "OSB/Plywood Thickness must be greater than or equal to 0.")
  end
    
  def test_argument_error_rigid_rvalue_negative
    args_hash = {}
    args_hash["rigid_r"] = -1
    result = _test_error(osm_geo, args_hash)
    assert_equal(result.errors.map{ |x| x.logMessage }[0], "Continuous Insulation Nominal R-value must be greater than or equal to 0.")
  end

  def test_argument_error_rigid_thick_in_negative
    args_hash = {}
    args_hash["rigid_thick_in"] = -1
    result = _test_error(osm_geo, args_hash)
    assert_equal(result.errors.map{ |x| x.logMessage }[0], "Continuous Insulation Thickness must be greater than or equal to 0.")
  end  

  def test_retrofit_replace
    args_hash = {}
    expected_num_del_objects = {}
    expected_num_new_objects = {"Material"=>1, "Construction"=>1}
    expected_values = {"LayerThickness"=>0.01905, "LayerConductivity"=>0.1154577, "LayerDensity"=>512.64, "LayerSpecificHeat"=>1214.23, "LayerIndex"=>0, "SurfacesWithConstructions"=>4}
    _test_measure(osm_geo, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)
    args_hash = {}
    args_hash["osb_thick_in"] = 1
    expected_num_del_objects = {}
    expected_num_new_objects = {"Material"=>1, "Construction"=>1}
    expected_values = {"LayerThickness"=>0.0254, "LayerConductivity"=>0.1154577, "LayerDensity"=>512.64, "LayerSpecificHeat"=>1214.23, "LayerIndex"=>0, "SurfacesWithConstructions"=>4}
    _test_measure(osm_geo, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)    
  end

  def test_apply_to_specific_surface
    args_hash = {}
    args_hash["surface"] = "Surface 1"
    expected_num_del_objects = {}
    expected_num_new_objects = {"Material"=>1, "Construction"=>1}
    expected_values = {"LayerThickness"=>0.01905, "LayerConductivity"=>0.1154577, "LayerDensity"=>512.64, "LayerSpecificHeat"=>1214.23, "LayerIndex"=>0, "SurfacesWithConstructions"=>2}
    _test_measure(osm_geo, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)  
  end
  
  private
  
  def _test_error(osm_file, args_hash)
    # create an instance of the measure
    measure = ProcessConstructionsFoundationsFloorsSheathing.new

    # create an instance of a runner
    runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)

    model = get_model(File.dirname(__FILE__), osm_file)

    # get arguments
    arguments = measure.arguments(model)
    argument_map = OpenStudio::Measure.convertOSArgumentVectorToMap(arguments)

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
    measure = ProcessConstructionsFoundationsFloorsSheathing.new

    # create an instance of a runner
    runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)

    model = get_model(File.dirname(__FILE__), osm_file)

    # get arguments
    arguments = measure.arguments(model)
    argument_map = OpenStudio::Measure.convertOSArgumentVectorToMap(arguments)

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
    measure = ProcessConstructionsFoundationsFloorsSheathing.new

    # check for standard methods
    assert(!measure.name.empty?)
    assert(!measure.description.empty?)
    assert(!measure.modeler_description.empty?)

    # create an instance of a runner
    runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)
    
    model = get_model(File.dirname(__FILE__), osm_file_or_model)

    # get the initial objects in the model
    initial_objects = get_objects(model)

    # get arguments
    arguments = measure.arguments(model)
    argument_map = OpenStudio::Measure.convertOSArgumentVectorToMap(arguments)

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
    
    actual_values = {"LayerThickness"=>0, "LayerConductivity"=>0, "LayerDensity"=>0, "LayerSpecificHeat"=>0, "LayerIndex"=>0, "SurfacesWithConstructions"=>0}
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
                next if !all_new_objects.keys.include?("Material")
                all_new_objects["Material"].each do |new_material|
                    new_material = new_material.to_StandardOpaqueMaterial.get
                    actual_values["LayerIndex"] += new_object.getLayerIndices(new_material)[0]
                end
                model.getSurfaces.each do |surface|
                  if surface.construction.is_initialized
                    next unless surface.construction.get == new_object
                    actual_values["SurfacesWithConstructions"] += 1
                  end
                end
            end
        end
    end
    assert_in_epsilon(expected_values["LayerThickness"], actual_values["LayerThickness"], 0.01)
    assert_in_epsilon(expected_values["LayerConductivity"], actual_values["LayerConductivity"], 0.01)
    assert_in_epsilon(expected_values["LayerDensity"], actual_values["LayerDensity"], 0.01)
    assert_in_epsilon(expected_values["LayerSpecificHeat"], actual_values["LayerSpecificHeat"], 0.01)
    assert_in_epsilon(expected_values["LayerIndex"], actual_values["LayerIndex"], 0.01)
    assert_in_epsilon(expected_values["SurfacesWithConstructions"], actual_values["SurfacesWithConstructions"], 0.01)
    
    return model
  end
  
end
