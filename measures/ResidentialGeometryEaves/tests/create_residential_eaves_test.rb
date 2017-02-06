require_relative '../../../test/minitest_helper'
require 'openstudio'
require 'openstudio/ruleset/ShowRunnerOutput'
require 'minitest/autorun'
require_relative '../measure.rb'
require 'fileutils'

class CreateResidentialEavesTest < MiniTest::Test
  
  def test_not_applicable_no_surfaces
    args_hash = {}
    result = _test_error(nil, args_hash)
    assert(result.errors.size == 0)
    assert_equal("NA", result.value.valueName)
    assert_includes(result.info.map{ |x| x.logMessage }, "No surfaces found for adding eaves.")
  end
    
  def test_not_applicable_depth_zero
    args_hash = {}
    args_hash["eaves_depth"] = 0
    result = _test_error("SFD_2000sqft_2story_SL_UA.osm", args_hash)
    assert(result.errors.size == 0)
    assert_equal("NA", result.value.valueName)
    assert_includes(result.info.map{ |x| x.logMessage }, "No eaves were added or removed.")
  end
    
  def test_retrofit_replace_gable_roof_aspect_ratio_two
    args_hash = {}
    expected_num_del_objects = {}
    expected_num_new_objects = {"ShadingSurface"=>6, "ShadingSurfaceGroup"=>1}
    expected_values = {"eaves_depth"=>2}
    model = _test_measure("SFD_2000sqft_2story_SL_UA_Denver_GableRoof_AspectRatioTwo.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)
    args_hash["eaves_depth"] = 3
    expected_num_del_objects = {"ShadingSurface"=>6, "ShadingSurfaceGroup"=>1}
    expected_num_new_objects = {"ShadingSurface"=>6, "ShadingSurfaceGroup"=>1}
    expected_values = {"eaves_depth"=>3}
    _test_measure(model, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 2)         
  end
  
  def test_retrofit_replace_gable_roof_aspect_ratio_half    
    args_hash = {}
    expected_num_del_objects = {}
    expected_num_new_objects = {"ShadingSurface"=>6, "ShadingSurfaceGroup"=>1}
    expected_values = {"eaves_depth"=>2}
    model = _test_measure("SFD_2000sqft_2story_SL_UA_Denver_GableRoof_AspectRatioHalf.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)
    args_hash["eaves_depth"] = 3
    expected_num_del_objects = {"ShadingSurface"=>6, "ShadingSurfaceGroup"=>1}
    expected_num_new_objects = {"ShadingSurface"=>6, "ShadingSurfaceGroup"=>1}
    expected_values = {"eaves_depth"=>3}
    _test_measure(model, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 2)
  end
  
  def test_retrofit_replace_hip_roof_aspect_ratio_two    
    args_hash = {}
    expected_num_del_objects = {}
    expected_num_new_objects = {"ShadingSurface"=>4, "ShadingSurfaceGroup"=>1}
    expected_values = {"eaves_depth"=>2}
    model = _test_measure("SFD_2000sqft_2story_SL_UA_Denver_HipRoof_AspectRatioTwo.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)
    args_hash["eaves_depth"] = 3
    expected_num_del_objects = {"ShadingSurface"=>4, "ShadingSurfaceGroup"=>1}
    expected_num_new_objects = {"ShadingSurface"=>4, "ShadingSurfaceGroup"=>1}
    expected_values = {"eaves_depth"=>3}
    _test_measure(model, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 2)
  end  
  
  def test_retrofit_replace_hip_roof_aspect_ratio_half   
    args_hash = {}
    expected_num_del_objects = {}
    expected_num_new_objects = {"ShadingSurface"=>4, "ShadingSurfaceGroup"=>1}
    expected_values = {"eaves_depth"=>2}
    model = _test_measure("SFD_2000sqft_2story_SL_UA_Denver_HipRoof_AspectRatioHalf.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)
    args_hash["eaves_depth"] = 3
    expected_num_del_objects = {"ShadingSurface"=>4, "ShadingSurfaceGroup"=>1}
    expected_num_new_objects = {"ShadingSurface"=>4, "ShadingSurfaceGroup"=>1}
    expected_values = {"eaves_depth"=>3}
    _test_measure(model, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 2)
  end  
  
  def test_retrofit_replace_flat_roof_aspect_ratio_two
    args_hash = {}
    expected_num_del_objects = {}
    expected_num_new_objects = {"ShadingSurface"=>4, "ShadingSurfaceGroup"=>1}
    expected_values = {"eaves_depth"=>2}
    model = _test_measure("SFD_2000sqft_2story_SL_FR_Denver_AspectRatioTwo.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)
    args_hash["eaves_depth"] = 3
    expected_num_del_objects = {"ShadingSurface"=>4, "ShadingSurfaceGroup"=>1}
    expected_num_new_objects = {"ShadingSurface"=>4, "ShadingSurfaceGroup"=>1}
    expected_values = {"eaves_depth"=>3}
    _test_measure(model, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 2)
  end  
  
  def test_retrofit_replace_flat_roof_aspect_ratio_half
    args_hash = {}
    expected_num_del_objects = {}
    expected_num_new_objects = {"ShadingSurface"=>4, "ShadingSurfaceGroup"=>1}
    expected_values = {"eaves_depth"=>2}
    model = _test_measure("SFD_2000sqft_2story_SL_FR_Denver_AspectRatioHalf.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)
    args_hash["eaves_depth"] = 3
    expected_num_del_objects = {"ShadingSurface"=>4, "ShadingSurfaceGroup"=>1}
    expected_num_new_objects = {"ShadingSurface"=>4, "ShadingSurfaceGroup"=>1}
    expected_values = {"eaves_depth"=>3}
    _test_measure(model, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 2)       
  end
  
  def test_gable_roof_garage_aspect_ratio_two
    args_hash = {}
    expected_num_del_objects = {}
    expected_num_new_objects = {"ShadingSurface"=>10, "ShadingSurfaceGroup"=>1}
    expected_values = {"eaves_depth"=>2}
    _test_measure("SFD_2000sqft_2story_SL_GRG_UA.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)       
  end
  
  def test_flat_roof_garage_left_aspect_ratio_two
    args_hash = {}
    expected_num_del_objects = {}
    expected_num_new_objects = {"ShadingSurface"=>6, "ShadingSurfaceGroup"=>1}
    expected_values = {"eaves_depth"=>2}
    _test_measure("SFD_2000sqft_2story_SL_GRGLeft_FlatRoof.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)       
  end

  def test_flat_roof_garage_right_aspect_ratio_two
    args_hash = {}
    expected_num_del_objects = {}
    expected_num_new_objects = {"ShadingSurface"=>6, "ShadingSurfaceGroup"=>1}
    expected_values = {"eaves_depth"=>2}
    _test_measure("SFD_2000sqft_2story_SL_GRG_FlatRoof.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)       
  end
  
  def test_onestory_flat_roof_garage_left_aspect_ratio_two
    args_hash = {}
    expected_num_del_objects = {}
    expected_num_new_objects = {"ShadingSurface"=>7, "ShadingSurfaceGroup"=>1}
    expected_values = {"eaves_depth"=>2}
    _test_measure("SFD_2000sqft_1story_SL_GRGLeft_FlatRoof.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)       
  end  
  
  def test_onestory_flat_roof_garage_right_aspect_ratio_two
    args_hash = {}
    expected_num_del_objects = {}
    expected_num_new_objects = {"ShadingSurface"=>7, "ShadingSurfaceGroup"=>1}
    expected_values = {"eaves_depth"=>2}
    _test_measure("SFD_2000sqft_1story_SL_GRG_FlatRoof.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)       
  end  
  
  def test_single_family_attached_new_construction_gable_roof_aspect_ratio_two
    num_units = 4
    args_hash = {}
    expected_num_del_objects = {}
    expected_num_new_objects = {"ShadingSurface"=>num_units*6, "ShadingSurfaceGroup"=>1}
    expected_values = {"eaves_depth"=>2}
    _test_measure("SFA_4units_1story_FB_UA_Denver.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)
  end

  def test_single_family_attached_new_construction_hip_roof_aspect_ratio_two
    num_units = 4
    args_hash = {}
    expected_num_del_objects = {}
    expected_num_new_objects = {"ShadingSurface"=>num_units*4, "ShadingSurfaceGroup"=>1}
    expected_values = {"eaves_depth"=>2}
    _test_measure("SFA_4units_1story_FB_UA_Denver_HipRoof.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)
  end
  
  def test_single_family_attached_new_construction_flat_roof_aspect_ratio_two
    num_units = 4
    args_hash = {}
    expected_num_del_objects = {}
    expected_num_new_objects = {"ShadingSurface"=>num_units*4, "ShadingSurfaceGroup"=>1}
    expected_values = {"eaves_depth"=>2}
    _test_measure("SFA_4units_1story_FB_UA_Denver_FlatRoof.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)
  end
  
  def test_multifamily_new_construction_flat_roof_aspect_ratio_two_inset_right
    num_units = 8
    args_hash = {}
    expected_num_del_objects = {}
    expected_num_new_objects = {"ShadingSurface"=>num_units*4+num_units*2+1*4, "ShadingSurfaceGroup"=>1}
    expected_values = {"eaves_depth"=>2}
    _test_measure("MF_8units_1story_SL_Inset.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)
  end
  
  def test_multifamily_new_construction_flat_roof_aspect_ratio_two_inset_left
    num_units = 8
    args_hash = {}
    expected_num_del_objects = {}
    expected_num_new_objects = {"ShadingSurface"=>num_units*4+num_units*2+1*4, "ShadingSurfaceGroup"=>1}
    expected_values = {"eaves_depth"=>2}
    _test_measure("MF_8units_1story_SL_InsetLeft.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)
  end  
  
  private
  
  def _test_error(osm_file, args_hash)
    # create an instance of the measure
    measure = CreateResidentialEaves.new

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
      
    return result
    
  end
  
  def _test_measure(osm_file_or_model, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, num_infos=0, num_warnings=0, debug=false)
    # create an instance of the measure
    measure = CreateResidentialEaves.new

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
    
    #show_output(result)

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
                  next if OpenStudio::convert(l,"m","ft").get > 5
                  assert_in_epsilon(expected_values["eaves_depth"], OpenStudio::convert(l,"m","ft").get, 0.01)
                else
                  next if OpenStudio::convert(w,"m","ft").get > 5
                  assert_in_epsilon(expected_values["eaves_depth"], OpenStudio::convert(w,"m","ft").get, 0.01)
                end
            end
        end
    end
    
    return model
  end
  
end
