require_relative '../../../test/minitest_helper'
require 'openstudio'
require 'openstudio/ruleset/ShowRunnerOutput'
require 'minitest/autorun'
require_relative '../measure.rb'
require 'fileutils'

class CreateResidentialOverhangsTest < MiniTest::Test

  def test_error_invalid_overhang_depth
    args_hash = {}
    args_hash["depth"] = -1
    result = _test_error("SFD_2000sqft_2story_SL_UA_Windows.osm", args_hash)
    assert(result.errors.size == 1)
    assert_equal("Fail", result.value.valueName)
    assert_includes(result.errors.map{ |x| x.logMessage }, "Overhang depth must be greater than or equal to 0.")    
  end

  def test_error_invalid_overhang_offset
    args_hash = {}
    args_hash["offset"] = -1
    result = _test_error("SFD_2000sqft_2story_SL_UA_Windows.osm", args_hash)
    assert(result.errors.size == 1)
    assert_equal("Fail", result.value.valueName)
    assert_includes(result.errors.map{ |x| x.logMessage }, "Overhang offset must be greater than or equal to 0.")    
  end
  
  def test_not_applicable_no_windows
    args_hash = {}
    result = _test_error("SFD_2000sqft_2story_SL_UA.osm", args_hash)
    assert(result.errors.size == 0)
    assert_equal("NA", result.value.valueName)
    assert_includes(result.info.map{ |x| x.logMessage }, "No windows found for adding overhangs.")
  end
  
  def test_not_applicable_depth_zero
    args_hash = {}
    args_hash["depth"] = 0
    result = _test_error("SFD_2000sqft_2story_SL_UA.osm", args_hash)
    assert(result.errors.size == 0)
    assert_equal("NA", result.value.valueName)
    assert_includes(result.info.map{ |x| x.logMessage }, "No overhangs were added or removed.")
  end
  
  def test_retrofit_replace_one_ft_with_two_ft
    args_hash = {}
    args_hash["depth"] = 1
    expected_num_del_objects = {}
    expected_num_new_objects = {"ShadingSurface"=>36, "ShadingSurfaceGroup"=>36}
    expected_values = {"overhang_depth"=>1}
    model = _test_measure("SFD_2000sqft_2story_SL_UA_Windows.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 36)
    args_hash["depth"] = 2
    expected_num_del_objects = {"ShadingSurface"=>36, "ShadingSurfaceGroup"=>36}
    expected_num_new_objects = {"ShadingSurface"=>36, "ShadingSurfaceGroup"=>36}
    expected_values = {"overhang_depth"=>2}
    _test_measure(model, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 36+1)
  end
  
  def test_single_family_attached_new_construction
    num_units = 4
    args_hash = {}
    expected_num_del_objects = {}
    expected_num_new_objects = {"ShadingSurface"=>36, "ShadingSurfaceGroup"=>36}
    expected_values = {"overhang_depth"=>2}
    _test_measure("SFA_4units_1story_SL_UA_Windows.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 36)
  end

  def test_single_family_attached_new_construction_offset
    num_units = 4
    args_hash = {}
    expected_num_del_objects = {}
    expected_num_new_objects = {"ShadingSurface"=>42, "ShadingSurfaceGroup"=>42}
    expected_values = {"overhang_depth"=>2}
    _test_measure("SFA_4units_1story_SL_UA_Offset_Windows.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 42)
  end  
  
  def test_multifamily_new_construction
    num_units = 8
    args_hash = {}
    expected_num_del_objects = {}
    expected_num_new_objects = {"ShadingSurface"=>48, "ShadingSurfaceGroup"=>48}
    expected_values = {"overhang_depth"=>2}
    _test_measure("MF_8units_1story_SL_Windows.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 48)
  end
  
  def test_multifamily_new_construction_inset
    num_units = 8
    args_hash = {}
    expected_num_del_objects = {}
    expected_num_new_objects = {"ShadingSurface"=>60, "ShadingSurfaceGroup"=>60}
    expected_values = {"overhang_depth"=>2}
    _test_measure("MF_8units_1story_SL_Inset_Windows.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 60)
  end
  
  private
  
  def _test_error(osm_file, args_hash)
    # create an instance of the measure
    measure = CreateResidentialOverhangs.new

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
      
    return result
    
  end
  
  def _test_measure(osm_file_or_model, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, num_infos=0, num_warnings=0, debug=false)
    # create an instance of the measure
    measure = CreateResidentialOverhangs.new

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

    all_new_objects.each do |obj_type, new_objects|
        new_objects.each do |new_object|
            next if not new_object.respond_to?("to_#{obj_type}")
            new_object = new_object.public_send("to_#{obj_type}").get
            if obj_type == "ShadingSurface"
                l, w, h = Geometry.get_surface_dimensions(new_object)
                if l < w
                  assert_in_epsilon(expected_values["overhang_depth"], OpenStudio::convert(l,"m","ft").get, 0.01)
                else
                  assert_in_epsilon(expected_values["overhang_depth"], OpenStudio::convert(w,"m","ft").get, 0.01)
                end
            end
        end
    end
    
    return model
  end  
  
end
