require_relative '../../../test/minitest_helper'
require 'openstudio'
require 'openstudio/ruleset/ShowRunnerOutput'
require 'minitest/autorun'
require_relative '../measure.rb'
require 'fileutils'

class ProcessConstructionsWallsExteriorSIPTest < MiniTest::Test

  def osm_geo
    return "2000sqft_2story_SL_UA.osm"
  end
  
  def osm_geo_layers
    return "2000sqft_2story_SL_UA_layers.osm"
  end

  def test_add_3_6in_eps_osb_interior
    args_hash = {}
    args_hash["sip_r"] = 17.5
    args_hash["thick_in"] = 3.625
    args_hash["framing_factor"] = 0.156
    args_hash["sheathing_type"] = Constants.MaterialOSB
    args_hash["sheathing_thick_in"] = 0.44
    expected_num_del_objects = {}
    expected_num_new_objects = {"Material"=>4, "Construction"=>1}
    expected_values = {"LayerRvalue"=>0.0127/0.0343*2+0.0666/0.0432+0.0111/0.1154, "LayerDensity"=>147.063*2+107.013+512.64, "LayerSpecificHeat"=>1214.23*2+1214.23+1214.23, "LayerIndex"=>0+1+2+3}
    _test_measure(osm_geo, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)
  end

  def test_add_9_4in_eps_osb_interior
    args_hash = {}
    args_hash["sip_r"] = 47.5
    args_hash["thick_in"] = 9.375
    args_hash["framing_factor"] = 0.156
    args_hash["sheathing_type"] = Constants.MaterialGypsum
    args_hash["sheathing_thick_in"] = 0.5
    expected_num_del_objects = {}
    expected_num_new_objects = {"Material"=>4, "Construction"=>1}
    expected_values = {"LayerRvalue"=>0.0127/0.0307*2+0.2127/0.0420+0.0127/0.1603, "LayerDensity"=>147.063*2+107.013+801, "LayerSpecificHeat"=>1214.23*2+1214.23+837.4, "LayerIndex"=>0+1+2+3}
    _test_measure(osm_geo, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)
  end

  def test_add_9_4in_eps_osb_interior_to_layers
    args_hash = {}
    args_hash["sip_r"] = 47.5
    args_hash["thick_in"] = 9.375
    args_hash["framing_factor"] = 0.156
    args_hash["sheathing_type"] = Constants.MaterialGypsum
    args_hash["sheathing_thick_in"] = 0.5
    expected_num_del_objects = {"Construction"=>1}
    expected_num_new_objects = {"Material"=>4, "Construction"=>1}
    expected_values = {"LayerRvalue"=>0.0127/0.0307*2+0.2127/0.0420+0.0127/0.1603, "LayerDensity"=>147.063*2+107.013+801, "LayerSpecificHeat"=>1214.23*2+1214.23+837.4, "LayerIndex"=>2+3+4+5}
    _test_measure(osm_geo_layers, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)
  end

  def test_argument_error_sip_rvalue_negative
    args_hash = {}
    args_hash["sip_r"] = -1
    result = _test_error(osm_geo, args_hash)
    assert_equal(result.errors.map{ |x| x.logMessage }[0], "Nominal Insulation R-value must be greater than 0.")
  end
    
  def test_argument_error_thick_in_negative
    args_hash = {}
    args_hash["thick_in"] = -1
    result = _test_error(osm_geo, args_hash)
    assert_equal(result.errors.map{ |x| x.logMessage }[0], "Insulation Thickness must be greater than 0.")
  end

  def test_argument_error_thick_in_zero
    args_hash = {}
    args_hash["thick_in"] = 0
    result = _test_error(osm_geo, args_hash)
    assert_equal(result.errors.map{ |x| x.logMessage }[0], "Insulation Thickness must be greater than 0.")
  end

  def test_argument_error_framing_factor_negative
    args_hash = {}
    args_hash["framing_factor"] = -1
    result = _test_error(osm_geo, args_hash)
    assert_equal(result.errors.map{ |x| x.logMessage }[0], "Framing Factor must be greater than or equal to 0 and less than 1.")
  end

  def test_argument_error_framing_factor_eq_1
    args_hash = {}
    args_hash["framing_factor"] = 1.0
    result = _test_error(osm_geo, args_hash)
    assert_equal(result.errors.map{ |x| x.logMessage }[0], "Framing Factor must be greater than or equal to 0 and less than 1.")
  end
  
  def test_argument_error_sheathing_thick_in_negative
    args_hash = {}
    args_hash["sheathing_thick_in"] = -1
    result = _test_error(osm_geo, args_hash)
    assert_equal(result.errors.map{ |x| x.logMessage }[0], "Interior Sheathing Thickness must be greater than 0.")
  end

  def test_argument_error_sheathing_thick_in_zero
    args_hash = {}
    args_hash["sheathing_thick_in"] = 0
    result = _test_error(osm_geo, args_hash)
    assert_equal(result.errors.map{ |x| x.logMessage }[0], "Interior Sheathing Thickness must be greater than 0.")
  end

  def test_not_applicable_no_geometry
    args_hash = {}
    _test_na(nil, args_hash)
  end

  private
  
  def _test_error(osm_file, args_hash)
    # create an instance of the measure
    measure = ProcessConstructionsWallsExteriorSIP.new

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
    measure = ProcessConstructionsWallsExteriorSIP.new

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
    measure = ProcessConstructionsWallsExteriorSIP.new

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
    
    actual_values = {"LayerRvalue"=>0, "LayerDensity"=>0, "LayerSpecificHeat"=>0, "LayerIndex"=>0}
    all_new_objects.each do |obj_type, new_objects|
        new_objects.each do |new_object|
            next if not new_object.respond_to?("to_#{obj_type}")
            new_object = new_object.public_send("to_#{obj_type}").get
            if obj_type == "Material"
                new_object = new_object.to_StandardOpaqueMaterial.get
                actual_values["LayerRvalue"] += new_object.thickness/new_object.conductivity
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
    assert_in_epsilon(expected_values["LayerRvalue"], actual_values["LayerRvalue"], 0.01)
    assert_in_epsilon(expected_values["LayerDensity"], actual_values["LayerDensity"], 0.01)
    assert_in_epsilon(expected_values["LayerSpecificHeat"], actual_values["LayerSpecificHeat"], 0.01)
    assert_in_epsilon(expected_values["LayerIndex"], actual_values["LayerIndex"], 0.01)
    
    return model
  end
  
end
