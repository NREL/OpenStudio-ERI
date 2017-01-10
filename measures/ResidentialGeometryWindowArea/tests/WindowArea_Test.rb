require_relative '../../../test/minitest_helper'
require 'openstudio'
require 'openstudio/ruleset/ShowRunnerOutput'
require 'minitest/autorun'
require_relative '../measure.rb'
require 'fileutils'
require_relative '../resources/geometry'
require_relative '../resources/constants'

class WindowAreaTest < MiniTest::Test
  
  def osm_geo
    return "SFD_2000sqft_2story_FB_GRG_UA.osm"
  end
  
  def osm_geo_rotated
    return "SFD_2000sqft_2story_FB_GRG_UA_Southwest.osm"
  end
  
  def test_no_window_area
    args_hash = {}
    args_hash["front_wwr"] = 0
    args_hash["back_wwr"] = 0
    args_hash["left_wwr"] = 0
    args_hash["right_wwr"] = 0
    result = _test_error(osm_geo, args_hash)
    assert(result.errors.size == 0)
    assert_equal("Success", result.value.valueName)
    assert_equal(result.finalCondition.get.logMessage, "No windows added because all window-to-wall ratios were set to 0.")  
  end

  def test_sfd_new_construction_rotated
    args_hash = {}
    model = _test_measure(osm_geo_rotated, args_hash, [0, 0, 0, 0], [81.5, 110.3, 70.0, 55.1])
  end
  
  def test_sfd_retrofit_replace
    args_hash = {}
    model = _test_measure(osm_geo, args_hash, [0, 0, 0, 0], [81.5, 110.3, 70.0, 55.1])
    args_hash = {}
    args_hash["front_wwr"] = 0.12
    args_hash["left_wwr"] = 0.12
    _test_measure(model, args_hash, [81.5, 110.3, 70.0, 55.1], [54.3, 110.3, 46.4, 55.1])
  end
  
  def test_argument_error_invalid_window_area_front_lt_0
    args_hash = {}
    args_hash["front_wwr"] = -20
    result = _test_error(osm_geo, args_hash)
    assert(result.errors.size == 1)
    assert_equal("Fail", result.value.valueName)
    assert_equal(result.errors.map{ |x| x.logMessage }[0], "Front window-to-wall ratio must be greater than or equal to 0 and less than 1.")
  end
  
  def test_argument_error_invalid_window_area_back_lt_0
    args_hash = {}
    args_hash["back_wwr"] = -20
    result = _test_error(osm_geo, args_hash)
    assert(result.errors.size == 1)
    assert_equal("Fail", result.value.valueName)
    assert_equal(result.errors.map{ |x| x.logMessage }[0], "Back window-to-wall ratio must be greater than or equal to 0 and less than 1.")
  end

  def test_argument_error_invalid_window_area_left_lt_0
    args_hash = {}
    args_hash["left_wwr"] = -20
    result = _test_error(osm_geo, args_hash)
    assert(result.errors.size == 1)
    assert_equal("Fail", result.value.valueName)
    assert_equal(result.errors.map{ |x| x.logMessage }[0], "Left window-to-wall ratio must be greater than or equal to 0 and less than 1.")
  end

  def test_argument_error_invalid_window_area_right_lt_0
    args_hash = {}
    args_hash["right_wwr"] = -20
    result = _test_error(osm_geo, args_hash)
    assert(result.errors.size == 1)
    assert_equal("Fail", result.value.valueName)
    assert_equal(result.errors.map{ |x| x.logMessage }[0], "Right window-to-wall ratio must be greater than or equal to 0 and less than 1.")
  end

  def test_argument_error_invalid_window_area_front_eq_1
    args_hash = {}
    args_hash["front_wwr"] = 1
    result = _test_error(osm_geo, args_hash)
    assert(result.errors.size == 1)
    assert_equal("Fail", result.value.valueName)
    assert_equal(result.errors.map{ |x| x.logMessage }[0], "Front window-to-wall ratio must be greater than or equal to 0 and less than 1.")
  end
  
  def test_argument_error_invalid_window_area_back_eq_1
    args_hash = {}
    args_hash["back_wwr"] = 1
    result = _test_error(osm_geo, args_hash)
    assert(result.errors.size == 1)
    assert_equal("Fail", result.value.valueName)
    assert_equal(result.errors.map{ |x| x.logMessage }[0], "Back window-to-wall ratio must be greater than or equal to 0 and less than 1.")
  end

  def test_argument_error_invalid_window_area_left_eq_1
    args_hash = {}
    args_hash["left_wwr"] = 1
    result = _test_error(osm_geo, args_hash)
    assert(result.errors.size == 1)
    assert_equal("Fail", result.value.valueName)
    assert_equal(result.errors.map{ |x| x.logMessage }[0], "Left window-to-wall ratio must be greater than or equal to 0 and less than 1.")
  end

  def test_argument_error_invalid_window_area_right_eq_1
    args_hash = {}
    args_hash["right_wwr"] = 1
    result = _test_error(osm_geo, args_hash)
    assert(result.errors.size == 1)
    assert_equal("Fail", result.value.valueName)
    assert_equal(result.errors.map{ |x| x.logMessage }[0], "Right window-to-wall ratio must be greater than or equal to 0 and less than 1.")
  end
  
  def test_argument_error_invalid_aspect_ratio
    args_hash = {}
    args_hash["aspect_ratio"] = 0
    result = _test_error(osm_geo, args_hash)
    assert(result.errors.size == 1)
    assert_equal("Fail", result.value.valueName)
    assert_equal(result.errors.map{ |x| x.logMessage }[0], "Window Aspect Ratio must be greater than 0.")
  end  
  
  def test_single_family_attached_new_construction
    num_units = 4
    args_hash = {}
    args_hash["back_wwr"] = 0.12
    args_hash["right_wwr"] = 0.12    
    _test_measure("SFA_4units_1story_FB_UA_Denver.osm", args_hash, [0, 0, 0, 0, 0], [122.19, 81.46, 61.09, 40.73])
  end

  def test_multifamily_new_construction
    num_units = 8
    args_hash = {}
    args_hash["back_wwr"] = 0.12
    args_hash["right_wwr"] = 0.12    
    _test_measure("MF_8units_1story_SL_Denver.osm", args_hash, [0, 0, 0, 0, 0], [122.19, 81.46, 122.19, 81.46])
  end 

  private
  
  def _test_error(osm_file, args_hash)
    # create an instance of the measure
    measure = SetResidentialWindowArea.new

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
  
  def _test_measure(osm_file_or_model, args_hash, expected_fblr_win_area_removed, expected_fblr_win_area_added)
    # create an instance of the measure
    measure = SetResidentialWindowArea.new

    # check for standard methods
    assert(!measure.name.empty?)
    assert(!measure.description.empty?)
    assert(!measure.modeler_description.empty?)

    # create an instance of a runner
    runner = OpenStudio::Ruleset::OSRunner.new
    
    model = get_model(File.dirname(__FILE__), osm_file_or_model)

    # store the original windows in the model
    orig_windows = []
    model.getSubSurfaces.each do |sub_surface|
        next if sub_surface.subSurfaceType.downcase != "fixedwindow"
        orig_windows << sub_surface
    end

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
    assert(result.finalCondition.is_initialized)

    # get new/deleted window objects
    new_objects = []
    model.getSubSurfaces.each do |sub_surface|
        next if sub_surface.subSurfaceType.downcase != "fixedwindow"
        next if orig_windows.include?(sub_surface)
        new_objects << sub_surface
    end
    del_objects = []
    orig_windows.each do |orig_window|
        has_window = false
        model.getSubSurfaces.each do |sub_surface|
            next if sub_surface != orig_window
            has_window = true
        end
        next if has_window
        del_objects << orig_window
    end
    
    new_win_area = {Constants.FacadeFront=>0, Constants.FacadeBack=>0, 
                    Constants.FacadeLeft=>0, Constants.FacadeRight=>0}
    new_objects.each do |window|
        new_win_area[Geometry.get_facade_for_surface(window)] += OpenStudio.convert(window.grossArea, "m^2", "ft^2").get
    end

    del_win_area = {Constants.FacadeFront=>0, Constants.FacadeBack=>0, 
                    Constants.FacadeLeft=>0, Constants.FacadeRight=>0}
    del_objects.each do |window|
        del_win_area[Geometry.get_facade_for_surface(window)] += OpenStudio.convert(window.grossArea, "m^2", "ft^2").get
    end

    assert_in_epsilon(expected_fblr_win_area_added[0], new_win_area[Constants.FacadeFront], 0.01)
    assert_in_epsilon(expected_fblr_win_area_added[1], new_win_area[Constants.FacadeBack], 0.01)
    assert_in_epsilon(expected_fblr_win_area_added[2], new_win_area[Constants.FacadeLeft], 0.01)
    assert_in_epsilon(expected_fblr_win_area_added[3], new_win_area[Constants.FacadeRight], 0.01)

    assert_in_epsilon(expected_fblr_win_area_removed[0], del_win_area[Constants.FacadeFront], 0.01)
    assert_in_epsilon(expected_fblr_win_area_removed[1], del_win_area[Constants.FacadeBack], 0.01)
    assert_in_epsilon(expected_fblr_win_area_removed[2], del_win_area[Constants.FacadeLeft], 0.01)
    assert_in_epsilon(expected_fblr_win_area_removed[3], del_win_area[Constants.FacadeRight], 0.01)

    return model
  end  
  
end
