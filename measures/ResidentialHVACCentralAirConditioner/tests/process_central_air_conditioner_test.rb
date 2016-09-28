require_relative '../../../test/minitest_helper'
require 'openstudio'
require 'openstudio/ruleset/ShowRunnerOutput'
require 'minitest/autorun'
require_relative '../measure.rb'
require 'fileutils'

class ProcessCentralAirConditionerTest < MiniTest::Test
  
  def test_argument_error_comp_speeds
    args_hash = {}
    args_hash["acNumberSpeeds"] = 3
    result = _test_error("singlefamily_detached.osm", args_hash)
    assert_equal(result.errors[0].logMessage, "Invalid number of compressor speeds entered.")  
  end
  
  def test_argument_error_wrong_length
    args_hash = {}
    args_hash["acNumberSpeeds"] = 2
    args_hash["acCoolingEER"] = "11.1"
    result = _test_error("singlefamily_detached.osm", args_hash)
    assert_equal(result.errors[0].logMessage, "Entered wrong length for EER, Rated SHR, Capacity Ratio, or Fan Speed Ratio given the Number of Speeds.")
  end  
  
  def test_new_construction_seer_13
    args_hash = {}
    expected_num_del_objects = {}
    expected_num_new_objects = {"AirLoopHVACUnitarySystem"=>1, "AirLoopHVAC"=>1, "CoilCoolingDXSingleSpeed"=>1, "FanOnOff"=>1, "AirTerminalSingleDuctUncontrolled"=>1, "CoilCoolingDXMultiSpeedStageData"=>1}
    expected_values = {"COP"=>3.95, "NominalCapacity"=>"AutoSize", "MaximumSupplyAirTemperature"=>48.88}
    _test_measure("singlefamily_detached.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 4)
  end  
  
  def test_new_construction_fbsmt_seer_13
    args_hash = {}
    args_hash["acCoolingOutputCapacity"] = "3.0 tons"
    expected_num_del_objects = {}
    expected_num_new_objects = {"AirLoopHVACUnitarySystem"=>1, "AirLoopHVAC"=>1, "CoilCoolingDXSingleSpeed"=>1, "FanOnOff"=>1, "AirTerminalSingleDuctUncontrolled"=>2, "CoilCoolingDXMultiSpeedStageData"=>1}
    expected_values = {"COP"=>3.95, "NominalCapacity"=>10550.55, "MaximumSupplyAirTemperature"=>48.88}
    _test_measure("singlefamily_detached_fbsmt.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 5)
  end
  
  def test_new_construction_seer_16
    args_hash = {}
    args_hash["acCoolingInstalledSEER"] = 16.0
    args_hash["acNumberSpeeds"] = 2
    args_hash["acCoolingEER"] = "13.5, 12.4"
    args_hash["acSHRRated"] = "0.71, 0.73"
    args_hash["acCapacityRatio"] = "0.72, 1.0"
    args_hash["acRatedAirFlowRate"] = 355.2
    args_hash["acFanspeedRatio"] = "0.86, 1.0"
    args_hash["acSupplyFanPowerRated"] = 0.14
    args_hash["acSupplyFanPowerInstalled"] = 0.3
    args_hash["acCoolingOutputCapacity"] = "6.0 tons"
    expected_num_del_objects = {}
    expected_num_new_objects = {"AirLoopHVACUnitarySystem"=>1, "AirLoopHVAC"=>1, "CoilCoolingDXMultiSpeed"=>1, "FanOnOff"=>1, "AirTerminalSingleDuctUncontrolled"=>1, "CoilCoolingDXMultiSpeedStageData"=>2}
    expected_values = {"MaximumSupplyAirTemperature"=>48.88}
    _test_measure("singlefamily_detached.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 4)
  end
  
  def test_retrofit_replace_furnace
    args_hash = {}
    expected_num_del_objects = {"AirLoopHVACUnitarySystem"=>1, "AirLoopHVAC"=>1, "CoilHeatingGas"=>1, "FanOnOff"=>1, "AirTerminalSingleDuctUncontrolled"=>2}
    expected_num_new_objects = {"AirLoopHVACUnitarySystem"=>1, "AirLoopHVAC"=>1, "CoilHeatingGas"=>1, "CoilCoolingDXSingleSpeed"=>1, "FanOnOff"=>1, "AirTerminalSingleDuctUncontrolled"=>2, "CoilCoolingDXMultiSpeedStageData"=>1}
    expected_values = {"COP"=>3.95, "NominalCapacity"=>"AutoSize", "MaximumSupplyAirTemperature"=>48.88}
    _test_measure("singlefamily_detached_fbsmt_furnace.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 7)
  end
  
  def test_retrofit_replace_ashp
    args_hash = {}
    expected_num_del_objects = {"AirLoopHVACUnitarySystem"=>1, "AirLoopHVAC"=>1, "CoilHeatingElectric"=>1, "FanOnOff"=>1, "AirTerminalSingleDuctUncontrolled"=>2, "CoilHeatingDXSingleSpeed"=>1, "CoilCoolingDXSingleSpeed"=>1}
    expected_num_new_objects = {"AirLoopHVACUnitarySystem"=>1, "AirLoopHVAC"=>1, "CoilCoolingDXSingleSpeed"=>1, "FanOnOff"=>1, "AirTerminalSingleDuctUncontrolled"=>2, "CoilCoolingDXMultiSpeedStageData"=>1}
    expected_values = {"COP"=>3.95, "NominalCapacity"=>"AutoSize", "MaximumSupplyAirTemperature"=>48.88}
    _test_measure("singlefamily_detached_fbsmt_ashp.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 7)
  end  
  
  def test_retrofit_replace_central_air_conditioner
    args_hash = {}
    expected_num_del_objects = {"AirLoopHVACUnitarySystem"=>1, "AirLoopHVAC"=>1, "FanOnOff"=>1, "AirTerminalSingleDuctUncontrolled"=>2, "CoilCoolingDXSingleSpeed"=>1}
    expected_num_new_objects = {"AirLoopHVACUnitarySystem"=>1, "AirLoopHVAC"=>1, "CoilCoolingDXSingleSpeed"=>1, "FanOnOff"=>1, "AirTerminalSingleDuctUncontrolled"=>2, "CoilCoolingDXMultiSpeedStageData"=>1}
    expected_values = {"COP"=>3.95, "NominalCapacity"=>"AutoSize", "MaximumSupplyAirTemperature"=>48.88}
    _test_measure("singlefamily_detached_fbsmt_central_air_conditioner.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 7)
  end
  
  def test_retrofit_replace_room_air_conditioner
    args_hash = {}
    expected_num_del_objects = {"CoilCoolingDXSingleSpeed"=>1, "ZoneHVACPackagedTerminalAirConditioner"=>1, "CoilHeatingElectric"=>1, "FanOnOff"=>1}
    expected_num_new_objects = {"AirLoopHVACUnitarySystem"=>1, "AirLoopHVAC"=>1, "CoilCoolingDXSingleSpeed"=>1, "FanOnOff"=>1, "AirTerminalSingleDuctUncontrolled"=>2, "CoilCoolingDXMultiSpeedStageData"=>1}
    expected_values = {"COP"=>3.95, "NominalCapacity"=>"AutoSize", "MaximumSupplyAirTemperature"=>48.88}
    _test_measure("singlefamily_detached_fbsmt_room_air_conditioner.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 6)
  end
  
  def test_retrofit_replace_electric_baseboard
    args_hash = {}
    expected_num_del_objects = {}
    expected_num_new_objects = {"AirLoopHVACUnitarySystem"=>1, "AirLoopHVAC"=>1, "CoilCoolingDXSingleSpeed"=>1, "FanOnOff"=>1, "AirTerminalSingleDuctUncontrolled"=>2, "CoilCoolingDXMultiSpeedStageData"=>1}
    expected_values = {"COP"=>3.95, "NominalCapacity"=>"AutoSize", "MaximumSupplyAirTemperature"=>48.88}
    _test_measure("singlefamily_detached_fbsmt_electric_baseboard.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 5)
  end
  
  def test_retrofit_replace_boiler
    args_hash = {}
    expected_num_del_objects = {}
    expected_num_new_objects = {"AirLoopHVACUnitarySystem"=>1, "AirLoopHVAC"=>1, "CoilCoolingDXSingleSpeed"=>1, "FanOnOff"=>1, "AirTerminalSingleDuctUncontrolled"=>2, "CoilCoolingDXMultiSpeedStageData"=>1}
    expected_values = {"COP"=>3.95, "NominalCapacity"=>"AutoSize", "MaximumSupplyAirTemperature"=>48.88}
    _test_measure("singlefamily_detached_fbsmt_boiler.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 5)
  end
  
  def test_retrofit_replace_mshp
    args_hash = {}
    expected_num_del_objects = {"FanOnOff"=>1, "AirConditionerVariableRefrigerantFlow"=>1, "ZoneHVACTerminalUnitVariableRefrigerantFlow"=>1, "CoilCoolingDXVariableRefrigerantFlow"=>1, "CoilHeatingDXVariableRefrigerantFlow"=>1}
    expected_num_new_objects = {"AirLoopHVACUnitarySystem"=>1, "AirLoopHVAC"=>1, "CoilCoolingDXSingleSpeed"=>1, "FanOnOff"=>1, "AirTerminalSingleDuctUncontrolled"=>2, "CoilCoolingDXMultiSpeedStageData"=>1}
    expected_values = {"COP"=>3.95, "NominalCapacity"=>"AutoSize", "MaximumSupplyAirTemperature"=>48.88}
    _test_measure("singlefamily_detached_fbsmt_mshp.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 6)
  end
  
  def test_retrofit_replace_furnace_central_air_conditioner
    args_hash = {}
    expected_num_del_objects = {"AirLoopHVACUnitarySystem"=>1, "AirLoopHVAC"=>1, "CoilHeatingGas"=>1, "FanOnOff"=>1, "AirTerminalSingleDuctUncontrolled"=>2, "CoilCoolingDXSingleSpeed"=>1}
    expected_num_new_objects = {"AirLoopHVACUnitarySystem"=>1, "AirLoopHVAC"=>1, "CoilHeatingGas"=>1, "CoilCoolingDXSingleSpeed"=>1, "FanOnOff"=>1, "AirTerminalSingleDuctUncontrolled"=>2, "CoilCoolingDXMultiSpeedStageData"=>1}
    expected_values = {"COP"=>3.95, "NominalCapacity"=>"AutoSize", "MaximumSupplyAirTemperature"=>48.88}
    _test_measure("singlefamily_detached_fbsmt_furnace_central_air_conditioner.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 8)
  end
  
  def test_retrofit_replace_furnace_room_air_conditioner
    args_hash = {}
    expected_num_del_objects = {"AirLoopHVACUnitarySystem"=>1, "AirLoopHVAC"=>1, "CoilHeatingGas"=>1, "FanOnOff"=>2, "AirTerminalSingleDuctUncontrolled"=>2, "CoilCoolingDXSingleSpeed"=>1, "ZoneHVACPackagedTerminalAirConditioner"=>1, "CoilHeatingElectric"=>1}
    expected_num_new_objects = {"AirLoopHVACUnitarySystem"=>1, "AirLoopHVAC"=>1, "CoilHeatingGas"=>1, "CoilCoolingDXSingleSpeed"=>1, "FanOnOff"=>1, "AirTerminalSingleDuctUncontrolled"=>2, "CoilCoolingDXMultiSpeedStageData"=>1}
    expected_values = {"COP"=>3.95, "NominalCapacity"=>"AutoSize", "MaximumSupplyAirTemperature"=>48.88}
    _test_measure("singlefamily_detached_fbsmt_furnace_room_air_conditioner.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 8)
  end  
  
  def test_retrofit_replace_electric_baseboard_central_air_conditioner
    args_hash = {}
    expected_num_del_objects = {"AirLoopHVACUnitarySystem"=>1, "AirLoopHVAC"=>1, "FanOnOff"=>1, "AirTerminalSingleDuctUncontrolled"=>2, "CoilCoolingDXSingleSpeed"=>1}
    expected_num_new_objects = {"AirLoopHVACUnitarySystem"=>1, "AirLoopHVAC"=>1, "CoilCoolingDXSingleSpeed"=>1, "FanOnOff"=>1, "AirTerminalSingleDuctUncontrolled"=>2, "CoilCoolingDXMultiSpeedStageData"=>1}
    expected_values = {"COP"=>3.95, "NominalCapacity"=>"AutoSize", "MaximumSupplyAirTemperature"=>48.88}
    _test_measure("singlefamily_detached_fbsmt_electric_baseboard_central_air_conditioner.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 7)
  end  
  
  def test_retrofit_replace_boiler_central_air_conditioner
    args_hash = {}
    expected_num_del_objects = {"AirLoopHVACUnitarySystem"=>1, "AirLoopHVAC"=>1, "FanOnOff"=>1, "AirTerminalSingleDuctUncontrolled"=>2, "CoilCoolingDXSingleSpeed"=>1}
    expected_num_new_objects = {"AirLoopHVACUnitarySystem"=>1, "AirLoopHVAC"=>1, "CoilCoolingDXSingleSpeed"=>1, "FanOnOff"=>1, "AirTerminalSingleDuctUncontrolled"=>2, "CoilCoolingDXMultiSpeedStageData"=>1}
    expected_values = {"COP"=>3.95, "NominalCapacity"=>"AutoSize", "MaximumSupplyAirTemperature"=>48.88}
    _test_measure("singlefamily_detached_fbsmt_boiler_central_air_conditioner.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 7)
  end  

  def test_retrofit_replace_electric_baseboard_room_air_conditioner
    args_hash = {}
    expected_num_del_objects = {"CoilCoolingDXSingleSpeed"=>1, "ZoneHVACPackagedTerminalAirConditioner"=>1, "FanOnOff"=>1, "CoilHeatingElectric"=>1}
    expected_num_new_objects = {"AirLoopHVACUnitarySystem"=>1, "AirLoopHVAC"=>1, "CoilCoolingDXSingleSpeed"=>1, "FanOnOff"=>1, "AirTerminalSingleDuctUncontrolled"=>2, "CoilCoolingDXMultiSpeedStageData"=>1}
    expected_values = {"COP"=>3.95, "NominalCapacity"=>"AutoSize", "MaximumSupplyAirTemperature"=>48.88}
    _test_measure("singlefamily_detached_fbsmt_electric_baseboard_room_air_conditioner.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 6)
  end
  
  def test_retrofit_replace_boiler_room_air_conditioner
    args_hash = {}
    expected_num_del_objects = {"CoilCoolingDXSingleSpeed"=>1, "ZoneHVACPackagedTerminalAirConditioner"=>1, "FanOnOff"=>1, "CoilHeatingElectric"=>1}
    expected_num_new_objects = {"AirLoopHVACUnitarySystem"=>1, "AirLoopHVAC"=>1, "CoilCoolingDXSingleSpeed"=>1, "FanOnOff"=>1, "AirTerminalSingleDuctUncontrolled"=>2, "CoilCoolingDXMultiSpeedStageData"=>1}
    expected_values = {"COP"=>3.95, "NominalCapacity"=>"AutoSize", "MaximumSupplyAirTemperature"=>48.88}
    _test_measure("singlefamily_detached_fbsmt_boiler_room_air_conditioner.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 6)
  end

  def test_multifamily_new_construction_1
    num_units = 4
    args_hash = {}
    expected_num_del_objects = {}
    expected_num_new_objects = {"AirLoopHVACUnitarySystem"=>num_units, "AirLoopHVAC"=>num_units, "CoilCoolingDXSingleSpeed"=>num_units, "FanOnOff"=>num_units, "AirTerminalSingleDuctUncontrolled"=>num_units*2, "CoilCoolingDXMultiSpeedStageData"=>num_units}
    expected_values = {"COP"=>3.95, "NominalCapacity"=>"AutoSize", "MaximumSupplyAirTemperature"=>48.88}
    _test_measure("singlefamily_attached_fbsmt_4_units.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, num_units*5)
  end

  def test_multifamily_new_construction_2
    num_units = 8
    args_hash = {}
    expected_num_del_objects = {}
    expected_num_new_objects = {"AirLoopHVACUnitarySystem"=>num_units, "AirLoopHVAC"=>num_units, "CoilCoolingDXSingleSpeed"=>num_units, "FanOnOff"=>num_units, "AirTerminalSingleDuctUncontrolled"=>num_units, "CoilCoolingDXMultiSpeedStageData"=>num_units}
    expected_values = {"COP"=>3.95, "NominalCapacity"=>"AutoSize", "MaximumSupplyAirTemperature"=>48.88}
    _test_measure("multifamily_8_units.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, num_units*3)
  end   
  
  private
  
  def _test_error(osm_file, args_hash)
    # create an instance of the measure
    measure = ProcessCentralAirConditioner.new

    # create an instance of a runner
    runner = OpenStudio::Ruleset::OSRunner.new

    model = _get_model(osm_file)

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
  
  def _test_measure(osm_file_or_model, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, num_infos=0, num_warnings=0, debug=false)
    # create an instance of the measure
    measure = ProcessCentralAirConditioner.new

    # check for standard methods
    assert(!measure.name.empty?)
    assert(!measure.description.empty?)
    assert(!measure.modeler_description.empty?)

    # create an instance of a runner
    runner = OpenStudio::Ruleset::OSRunner.new
    
    model = _get_model(osm_file_or_model)

    # get the initial objects in the model
    initial_objects = _get_objects(model)
    
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
    final_objects = _get_objects(model)
    
    # get new and deleted objects
    obj_type_exclusions = ["CurveQuadratic", "CurveBiquadratic", "CurveCubic", "Node", "AirLoopHVACZoneMixer", "SizingSystem", "AirLoopHVACZoneSplitter", "ScheduleTypeLimits", "CurveExponent", "ScheduleConstant", "SizingPlant", "PipeAdiabatic", "ConnectorSplitter", "ModelObjectList", "ConnectorMixer"]
    all_new_objects = _get_object_additions(initial_objects, final_objects, obj_type_exclusions)
    all_del_objects = _get_object_additions(final_objects, initial_objects, obj_type_exclusions)
    
    # check we have the expected number of new/deleted objects
    _check_num_objects(all_new_objects, expected_num_new_objects, "added")
    _check_num_objects(all_del_objects, expected_num_del_objects, "deleted")

    all_new_objects.each do |obj_type, new_objects|
        new_objects.each do |new_object|
            next if not new_object.respond_to?("to_#{obj_type}")
            new_object = new_object.public_send("to_#{obj_type}").get
            if obj_type == "AirLoopHVACUnitarySystem"
                assert_in_epsilon(expected_values["MaximumSupplyAirTemperature"], new_object.maximumSupplyAirTemperature.get, 0.01)
            elsif obj_type == "CoilCoolingDXSingleSpeed"
                if new_object.ratedCOP.is_initialized
                  assert_in_epsilon(expected_values["COP"], new_object.ratedCOP.get, 0.01)
                end
                if new_object.ratedTotalCoolingCapacity.is_initialized
                  assert_in_epsilon(expected_values["NominalCapacity"], new_object.ratedTotalCoolingCapacity.get, 0.01)
                end
            end
        end
    end
    
    return model
  end
  
  def _get_model(osm_file_or_model)
    if osm_file_or_model.is_a?(OpenStudio::Model::Model)
        # nothing to do
        model = osm_file_or_model
    elsif osm_file_or_model.nil?
        # make an empty model
        model = OpenStudio::Model::Model.new
    else
        # load the test model
        translator = OpenStudio::OSVersion::VersionTranslator.new
        path = OpenStudio::Path.new(File.join(File.dirname(__FILE__), osm_file_or_model))
        model = translator.loadModel(path)
        assert((not model.empty?))
        model = model.get
    end
    return model
  end  
  
  def _get_objects(model)
    # Returns a list with [ObjectTypeString, ModelObject] items
    objects = []
    model.modelObjects.each do |obj|
        objects << [_get_model_object_type(obj), obj]
    end
    return objects
  end
  
  def _get_object_additions(list1, list2, obj_type_exclusions=nil)
    # Identifies all objects in list2 that aren't in list1.
    # Returns a hash with key=ObjectTypeString, value=[ModelObjects]
    additions = {}
    list2.each do |obj_type2, obj2|
        next if list1.include?([obj_type2, obj2])
        next if not obj_type_exclusions.nil? and obj_type_exclusions.include?(obj_type2)
        if not additions.keys.include?(obj_type2)
            additions[obj_type2] = []
        end
        additions[obj_type2] << obj2
    end
    return additions
  end
  
  def _get_model_object_type(model_object)
    # Hacky; is there a better way to get this?
    return model_object.to_s.split(',')[0].gsub('OS:','').gsub(':','')
  end
  
  def _check_num_objects(objects, expected_num_objects, mode)
    # Checks for the exact number of objects as defined in expected_num_objects
    objects.each do |obj_type, new_objects|
        next if not new_objects[0].respond_to?("to_#{obj_type}")
        if expected_num_objects.include?(obj_type)
            puts "Incorrect number of #{obj_type} objects #{mode}." if new_objects.size != expected_num_objects[obj_type]
            assert_equal(expected_num_objects[obj_type], new_objects.size)
        else
            puts "Incorrect number of #{obj_type} objects #{mode}." if new_objects.size != 0
            assert_equal(0, new_objects.size)
        end
    end
    expected_num_objects.each do |obj_type, num_objects|
        next if objects.keys.include?(obj_type)
        puts "Incorrect number of #{obj_type} objects #{mode}." if num_objects != 0
        assert_equal(num_objects, 0)
    end
  end

end
