require_relative '../../../test/minitest_helper'
require 'openstudio'
require 'openstudio/ruleset/ShowRunnerOutput'
require 'minitest/autorun'
require_relative '../measure.rb'
require 'fileutils'

class ResidentialPhotovoltaicsTest < MiniTest::Test

  def test_error_invalid_azimuth
    args_hash = {}
    args_hash["azimuth"] = -180
    result = _test_error("SFD_2000sqft_2story_SL_UA_Denver.osm", args_hash)
    assert_includes(result.errors.map{ |x| x.logMessage }, "Invalid azimuth entered.")
  end
  
  def test_azimuth_absolute
    args_hash = {}
    args_hash["azimuth_type"] = Constants.CoordAbsolute
    args_hash["azimuth"] = 180.0
    expected_num_del_objects = {}
    expected_num_new_objects = {"GeneratorMicroTurbine"=>1, "CurveBiquadratic"=>1, "CurveCubic"=>2, "ElectricLoadCenterDistribution"=>1, "ScheduleFixedInterval"=>1}
    expected_values = {"PanelArea"=>18.93}
    _test_measure("SFD_2000sqft_2story_SL_UA_Denver.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 1)
  end  
  
  def test_tilt_absolute
    args_hash = {}
    args_hash["size"] = 5.0
    args_hash["tilt_type"] = Constants.CoordAbsolute
    args_hash["tilt"] = 0.5
    expected_num_del_objects = {}
    expected_num_new_objects = {"GeneratorMicroTurbine"=>1, "CurveBiquadratic"=>1, "CurveCubic"=>2, "ElectricLoadCenterDistribution"=>1, "ScheduleFixedInterval"=>1}
    expected_values = {"PanelArea"=>2*18.93}
    _test_measure("SFD_2000sqft_2story_SL_UA_Denver.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 1)
  end
  
  def test_tilt_latitude
    args_hash = {}
    args_hash["size"] = 5.0
    args_hash["tilt_type"] = Constants.TiltLatitude
    expected_num_del_objects = {}
    expected_num_new_objects = {"GeneratorMicroTurbine"=>1, "CurveBiquadratic"=>1, "CurveCubic"=>2, "ElectricLoadCenterDistribution"=>1, "ScheduleFixedInterval"=>1}
    expected_values = {"PanelArea"=>2*18.93}
    _test_measure("SFD_2000sqft_2story_SL_UA_Denver.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 1)
  end  
  
  def test_single_family_attached_new_construction
    num_units = 4
    args_hash = {}
    expected_num_del_objects = {}
    expected_num_new_objects = {"GeneratorMicroTurbine"=>1, "CurveBiquadratic"=>1, "CurveCubic"=>2, "ElectricLoadCenterDistribution"=>1, "ScheduleFixedInterval"=>1}
    expected_values = {}
    _test_measure("SFA_4units_1story_FB_UA_Denver.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 1)
  end
  
  def test_multifamily_new_construction
    num_units = 8
    args_hash = {}
    expected_num_del_objects = {}
    expected_num_new_objects = {"GeneratorMicroTurbine"=>1, "CurveBiquadratic"=>1, "CurveCubic"=>2, "ElectricLoadCenterDistribution"=>1, "ScheduleFixedInterval"=>1}
    expected_values = {}
    _test_measure("MF_8units_1story_SL_Denver.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 1)
  end
  
  def test_retrofit_size
    args_hash = {}
    expected_num_del_objects = {}
    expected_num_new_objects = {"GeneratorMicroTurbine"=>1, "CurveBiquadratic"=>1, "CurveCubic"=>2, "ElectricLoadCenterDistribution"=>1, "ScheduleFixedInterval"=>1}
    expected_values = {}
    model = _test_measure("SFD_2000sqft_2story_SL_UA_Denver.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 1)
    args_hash["size"] = 5.0
    expected_num_del_objects = {"GeneratorMicroTurbine"=>1, "ElectricLoadCenterDistribution"=>1, "ScheduleFixedInterval"=>1}
    expected_num_new_objects = {"GeneratorMicroTurbine"=>1, "CurveBiquadratic"=>1, "CurveCubic"=>2, "ElectricLoadCenterDistribution"=>1, "ScheduleFixedInterval"=>1}
    expected_values = {}
    _test_measure(model, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 1)
  end  
  
  private
  
  def _test_error(osm_file_or_model, args_hash)
    # create an instance of the measure
    measure = ResidentialPhotovoltaicsSAM.new

    # create an instance of a runner
    runner = OpenStudio::Ruleset::OSRunner.new

    model = get_model(File.dirname(__FILE__), osm_file_or_model)

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

    # assert that it didn't run
    assert_equal("Fail", result.value.valueName)
    assert(result.errors.size == 1)
    
    return result
  end  
  
  def _test_measure(osm_file_or_model, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, num_infos=0, num_warnings=0, debug=false)
    # create an instance of the measure
    measure = ResidentialPhotovoltaicsSAM.new

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

    # assert that it ran correctly
    assert_equal("Success", result.value.valueName)
    assert(result.info.size == num_infos)
    assert(result.warnings.size == num_warnings)
    
    # get the final objects in the model
    final_objects = get_objects(model)
    
    # get new and deleted objects
    obj_type_exclusions = ["ModelObjectList", "ScheduleTypeLimits", "ScheduleConstant"]
    all_new_objects = get_object_additions(initial_objects, final_objects, obj_type_exclusions)
    all_del_objects = get_object_additions(final_objects, initial_objects, obj_type_exclusions)
    
    # check we have the expected number of new/deleted objects
    check_num_objects(all_new_objects, expected_num_new_objects, "added")
    check_num_objects(all_del_objects, expected_num_del_objects, "deleted")

    all_new_objects.each do |obj_type, new_objects|
        new_objects.each do |new_object|
            next if not new_object.respond_to?("to_#{obj_type}")
            new_object = new_object.public_send("to_#{obj_type}").get
      
        end
    end
    
    return model
  end

end
