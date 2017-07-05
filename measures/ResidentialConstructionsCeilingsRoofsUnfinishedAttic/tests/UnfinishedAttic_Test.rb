require_relative '../../../test/minitest_helper'
require 'openstudio'
require 'openstudio/ruleset/ShowRunnerOutput'
require 'minitest/autorun'
require_relative '../measure.rb'
require 'fileutils'

class ProcessConstructionsCeilingsRoofsUnfinishedAtticTest < MiniTest::Test

  def osm_geo
    return "SFD_2000sqft_2story_FB_UA_Denver.osm"
  end

  def osm_geo_finished_attic
    return "SFD_2000sqft_2story_SL_FA.osm"
  end  
  
  def test_not_applicable_finished_attic
    args_hash = {}
    _test_na(osm_geo_finished_attic, args_hash)
  end
  
  def test_argument_error_ceil_cavity_r_negative
    args_hash = {}
    args_hash["ceil_r"] = -1
    result = _test_error(osm_geo, args_hash)
    assert_equal(result.errors.map{ |x| x.logMessage }[0], "Ceiling Insulation Nominal R-value must be greater than or equal to 0.")
  end
  
  def test_argument_error_ceil_cavity_in_thk_negative
    args_hash = {}
    args_hash["ceil_ins_thick_in"] = -1
    result = _test_error(osm_geo, args_hash)
    assert_equal(result.errors.map{ |x| x.logMessage }[0], "Ceiling Insulation Thickness must be greater than or equal to 0.")
  end
  
  def test_argument_error_ceil_framing_factor_negative
    args_hash = {}
    args_hash["ceil_ff"] = -1
    result = _test_error(osm_geo, args_hash)
    assert_equal(result.errors.map{ |x| x.logMessage }[0], "Ceiling Framing Factor must be greater than or equal to 0 and less than 1.")
  end

  def test_argument_error_ceil_framing_factor_eq_1
    args_hash = {}
    args_hash["ceil_ff"] = 1.0
    result = _test_error(osm_geo, args_hash)
    assert_equal(result.errors.map{ |x| x.logMessage }[0], "Ceiling Framing Factor must be greater than or equal to 0 and less than 1.")
  end
  
  def test_argument_error_ceil_joist_ht_negative
    args_hash = {}
    args_hash["ceil_joist_height"] = -1
    result = _test_error(osm_geo, args_hash)
    assert_equal(result.errors.map{ |x| x.logMessage }[0], "Ceiling Joist Height must be greater than 0.")
  end
  
  def test_argument_error_roof_cavity_r_negative
    args_hash = {}
    args_hash["roof_cavity_r"] = -1
    result = _test_error(osm_geo, args_hash)
    assert_equal(result.errors.map{ |x| x.logMessage }[0], "Roof Cavity Insulation Nominal R-value must be greater than or equal to 0.")
  end
  
  def test_argument_error_roof_cavity_in_thk_negative
    args_hash = {}
    args_hash["roof_cavity_ins_thick_in"] = -1
    result = _test_error(osm_geo, args_hash)
    assert_equal(result.errors.map{ |x| x.logMessage }[0], "Roof Cavity Insulation Thickness must be greater than or equal to 0.")
  end
  
  def test_argument_error_roof_framing_factor_negative
    args_hash = {}
    args_hash["roof_ff"] = -1
    result = _test_error(osm_geo, args_hash)
    assert_equal(result.errors.map{ |x| x.logMessage }[0], "Roof Framing Factor must be greater than or equal to 0 and less than 1.")
  end

  def test_argument_error_roof_framing_factor_eq_1
    args_hash = {}
    args_hash["roof_ff"] = 1.0
    result = _test_error(osm_geo, args_hash)
    assert_equal(result.errors.map{ |x| x.logMessage }[0], "Roof Framing Factor must be greater than or equal to 0 and less than 1.")
  end
  
  def test_argument_error_roof_joist_ht_negative
    args_hash = {}
    args_hash["roof_fram_thick_in"] = -1
    result = _test_error(osm_geo, args_hash)
    assert_equal(result.errors.map{ |x| x.logMessage }[0], "Roof Framing Thickness must be greater than 0.")
  end
  
  def test_ceil_ins_thk_less_than_joist_ht
    args_hash = {}
    args_hash["ceil_r"] = 7
    args_hash["ceil_ins_thick_in"] = 2.95
    expected_num_del_objects = {}
    expected_num_new_objects = {"Material"=>2, "Construction"=>2}
    expected_values = {"LayerThickness"=>0.18415+0.0889, "LayerConductivity"=>8.103343031561298+0.0748255853219425, "LayerDensity"=>36.952092371013855+50.778528, "LayerSpecificHeat"=>1208.1833151295375+1165.039835, "LayerIndex"=>0, "SurfacesWithConstructions"=>4}
    _test_measure(osm_geo, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)  
  end  
  
  def test_roof_insulated
    args_hash = {}
    args_hash["ceil_r"] = 0
    args_hash["ceil_ins_thick_in"] = 0
    args_hash["roof_cavity_r"] = 19
    args_hash["roof_cavity_ins_thick_in"] = 6.25
    expected_num_del_objects = {}
    expected_num_new_objects = {"Material"=>2, "Construction"=>2}
    expected_values = {"LayerThickness"=>0.18415+0.0889, "LayerConductivity"=>0.0588738039479539+5.036356, "LayerDensity"=>78.34581+37.001327, "LayerSpecificHeat"=>1123.461011144055+1207.822949, "LayerIndex"=>0, "SurfacesWithConstructions"=>4}
    _test_measure(osm_geo, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)   
  end
  
  def test_roof_ins_thk_more_than_roof_framing_thk
    args_hash = {}
    args_hash["ceil_r"] = 0
    args_hash["ceil_ins_thick_in"] = 0
    args_hash["roof_cavity_r"] = 30
    args_hash["roof_cavity_ins_thick_in"] = 9.5
    expected_num_del_objects = {}
    expected_num_new_objects = {"Material"=>2, "Construction"=>2}
    expected_values = {"LayerThickness"=>0.2413+0.0889, "LayerConductivity"=>0.052124+5.036356, "LayerDensity"=>78.338295+37.001327, "LayerSpecificHeat"=>1123.407346+1207.822949, "LayerIndex"=>0, "SurfacesWithConstructions"=>4}
    _test_measure(osm_geo, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)   
  end  
  
  def test_retrofit_replace
    args_hash = {}
    expected_num_del_objects = {}
    expected_num_new_objects = {"Material"=>3, "Construction"=>3}
    expected_values = {"LayerThickness"=>0.0889+0.1282700089665573+0.18415, "LayerConductivity"=>0.0436673813937437+0.04111125+8.103343031561298, "LayerDensity"=>50.7834+16.02+36.952092371013855, "LayerSpecificHeat"=>1165.0954889589907+1046.75+1208.1833151295375, "LayerIndex"=>0+1+0+1, "SurfacesWithConstructions"=>4}
    _test_measure(osm_geo, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)    
  end
  
  def test_apply_to_specific_surface
    args_hash = {}
    args_hash["surface"] = "Surface 13"
    expected_num_del_objects = {}
    expected_num_new_objects = {"Material"=>2, "Construction"=>2}
    expected_values = {"LayerThickness"=>0.0889+0.1282700089665573, "LayerConductivity"=>0.0436673813937437+0.04111125, "LayerDensity"=>50.7834+16.02, "LayerSpecificHeat"=>1165.0954889589907+1046.75, "LayerIndex"=>0+1+0+1, "SurfacesWithConstructions"=>2}
    _test_measure(osm_geo, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)  
  end

  private
  
  def _test_error(osm_file, args_hash)
    # create an instance of the measure
    measure = ProcessConstructionsCeilingsRoofsUnfinishedAttic.new

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
    measure = ProcessConstructionsCeilingsRoofsUnfinishedAttic.new

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
    measure = ProcessConstructionsCeilingsRoofsUnfinishedAttic.new

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
                    if new_material.to_StandardOpaqueMaterial.is_initialized
                        new_material = new_material.to_StandardOpaqueMaterial.get
                    else
                        new_material = new_material.to_MasslessOpaqueMaterial.get
                    end
                    next if new_object.getLayerIndices(new_material)[0].nil?
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
