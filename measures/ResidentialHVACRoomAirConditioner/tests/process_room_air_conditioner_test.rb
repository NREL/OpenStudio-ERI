require_relative '../../../test/minitest_helper'
require 'openstudio'
require 'openstudio/ruleset/ShowRunnerOutput'
require 'minitest/autorun'
require_relative '../measure.rb'
require 'fileutils'

class ProcessRoomAirConditionerTest < MiniTest::Test
    
  def test_hardsized_room_air_conditioner
    args_hash = {}
    args_hash["capacity"] = "2.0 tons"
    expected_num_del_objects = {}
    expected_num_new_objects = {"CoilHeatingElectric"=>1, "FanOnOff"=>1, "CoilCoolingDXSingleSpeed"=>1, "ZoneHVACPackagedTerminalAirConditioner"=>1}
    expected_values = {"COP"=>2.49, "NominalCapacity"=>7033.70}
    _test_measure("SFD_2000sqft_2story_FB_UA_Denver.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 1)  
  end    
  
  def test_retrofit_replace_furnace
    args_hash = {}
    expected_num_del_objects = {}
    expected_num_new_objects = {"CoilHeatingElectric"=>1, "FanOnOff"=>1, "CoilCoolingDXSingleSpeed"=>1, "ZoneHVACPackagedTerminalAirConditioner"=>1}
    expected_values = {"COP"=>2.49}
    _test_measure("SFD_2000sqft_2story_FB_UA_Denver_Furnace.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 1)
  end
  
  def test_retrofit_replace_ashp
    args_hash = {}
    expected_num_del_objects = {"AirLoopHVACUnitarySystem"=>1, "AirLoopHVAC"=>1, "CoilHeatingElectric"=>1, "FanOnOff"=>1, "AirTerminalSingleDuctUncontrolled"=>2, "CoilHeatingDXSingleSpeed"=>1, "CoilCoolingDXSingleSpeed"=>1}
    expected_num_new_objects = {"CoilHeatingElectric"=>1, "FanOnOff"=>1, "CoilCoolingDXSingleSpeed"=>1, "ZoneHVACPackagedTerminalAirConditioner"=>1}
    expected_values = {"COP"=>2.49}
    _test_measure("SFD_2000sqft_2story_FB_UA_Denver_ASHP.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 3)
  end  
  
  def test_retrofit_replace_central_air_conditioner
    args_hash = {}
    expected_num_del_objects = {"AirLoopHVACUnitarySystem"=>1, "AirLoopHVAC"=>1, "FanOnOff"=>1, "AirTerminalSingleDuctUncontrolled"=>2, "CoilCoolingDXSingleSpeed"=>1}
    expected_num_new_objects = {"CoilHeatingElectric"=>1, "FanOnOff"=>1, "CoilCoolingDXSingleSpeed"=>1, "ZoneHVACPackagedTerminalAirConditioner"=>1}
    expected_values = {"COP"=>2.49}
    _test_measure("SFD_2000sqft_2story_FB_UA_Denver_CentralAC.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 3)
  end
  
  def test_retrofit_replace_room_air_conditioner
    args_hash = {}
    expected_num_del_objects = {"CoilCoolingDXSingleSpeed"=>1, "ZoneHVACPackagedTerminalAirConditioner"=>1, "CoilHeatingElectric"=>1, "FanOnOff"=>1}
    expected_num_new_objects = {"CoilHeatingElectric"=>1, "FanOnOff"=>1, "CoilCoolingDXSingleSpeed"=>1, "ZoneHVACPackagedTerminalAirConditioner"=>1}
    expected_values = {"COP"=>2.49}
    _test_measure("SFD_2000sqft_2story_FB_UA_Denver_RoomAC.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 2)
  end
  
  def test_retrofit_replace_electric_baseboard
    args_hash = {}
    expected_num_del_objects = {}
    expected_num_new_objects = {"CoilHeatingElectric"=>1, "FanOnOff"=>1, "CoilCoolingDXSingleSpeed"=>1, "ZoneHVACPackagedTerminalAirConditioner"=>1}
    expected_values = {"COP"=>2.49}
    _test_measure("SFD_2000sqft_2story_FB_UA_Denver_ElectricBaseboard.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 1)
  end
  
  def test_retrofit_replace_boiler
    args_hash = {}
    expected_num_del_objects = {}
    expected_num_new_objects = {"CoilHeatingElectric"=>1, "FanOnOff"=>1, "CoilCoolingDXSingleSpeed"=>1, "ZoneHVACPackagedTerminalAirConditioner"=>1}
    expected_values = {"COP"=>2.49}
    _test_measure("SFD_2000sqft_2story_FB_UA_Denver_Boiler.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 1)
  end  
  
  def test_retrofit_replace_mshp
    args_hash = {}
    expected_num_del_objects = {"FanOnOff"=>2, "AirConditionerVariableRefrigerantFlow"=>2, "ZoneHVACTerminalUnitVariableRefrigerantFlow"=>2, "CoilCoolingDXVariableRefrigerantFlow"=>2, "CoilHeatingDXVariableRefrigerantFlow"=>2, "ZoneHVACBaseboardConvectiveElectric"=>2}
    expected_num_new_objects = {"CoilHeatingElectric"=>1, "FanOnOff"=>1, "CoilCoolingDXSingleSpeed"=>1, "ZoneHVACPackagedTerminalAirConditioner"=>1}
    expected_values = {"COP"=>2.49}
    _test_measure("SFD_2000sqft_2story_FB_UA_Denver_MSHP.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 5)
  end
  
  def test_retrofit_replace_furnace_central_air_conditioner
    args_hash = {}
    expected_num_del_objects = {"CoilCoolingDXSingleSpeed"=>1}
    expected_num_new_objects = {"CoilHeatingElectric"=>1, "FanOnOff"=>1, "CoilCoolingDXSingleSpeed"=>1, "ZoneHVACPackagedTerminalAirConditioner"=>1}
    expected_values = {"COP"=>2.49}
    _test_measure("SFD_2000sqft_2story_FB_UA_Denver_Furnace_CentralAC.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 2)
  end
  
  def test_retrofit_replace_furnace_room_air_conditioner
    args_hash = {}
    expected_num_del_objects = {"FanOnOff"=>1, "CoilCoolingDXSingleSpeed"=>1, "ZoneHVACPackagedTerminalAirConditioner"=>1, "CoilHeatingElectric"=>1}
    expected_num_new_objects = {"CoilHeatingElectric"=>1, "FanOnOff"=>1, "CoilCoolingDXSingleSpeed"=>1, "ZoneHVACPackagedTerminalAirConditioner"=>1}
    expected_values = {"COP"=>2.49}
    _test_measure("SFD_2000sqft_2story_FB_UA_Denver_Furnace_RoomAC.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 2)
  end   
  
  def test_retrofit_replace_electric_baseboard_central_air_conditioner
    args_hash = {}
    expected_num_del_objects = {"AirLoopHVACUnitarySystem"=>1, "AirLoopHVAC"=>1, "FanOnOff"=>1, "AirTerminalSingleDuctUncontrolled"=>2, "CoilCoolingDXSingleSpeed"=>1}
    expected_num_new_objects = {"CoilHeatingElectric"=>1, "FanOnOff"=>1, "CoilCoolingDXSingleSpeed"=>1, "ZoneHVACPackagedTerminalAirConditioner"=>1}
    expected_values = {"COP"=>2.49}
    _test_measure("SFD_2000sqft_2story_FB_UA_Denver_ElectricBaseboard_CentralAC.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 3)
  end  
  
  def test_retrofit_replace_boiler_central_air_conditioner
    args_hash = {}
    expected_num_del_objects = {"AirLoopHVACUnitarySystem"=>1, "AirLoopHVAC"=>1, "FanOnOff"=>1, "AirTerminalSingleDuctUncontrolled"=>2, "CoilCoolingDXSingleSpeed"=>1}
    expected_num_new_objects = {"CoilHeatingElectric"=>1, "FanOnOff"=>1, "CoilCoolingDXSingleSpeed"=>1, "ZoneHVACPackagedTerminalAirConditioner"=>1}
    expected_values = {"COP"=>2.49}
    _test_measure("SFD_2000sqft_2story_FB_UA_Denver_Boiler_CentralAC.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 3)
  end  

  def test_retrofit_replace_electric_baseboard_room_air_conditioner
    args_hash = {}
    expected_num_del_objects = {"CoilCoolingDXSingleSpeed"=>1, "ZoneHVACPackagedTerminalAirConditioner"=>1, "FanOnOff"=>1, "CoilHeatingElectric"=>1}
    expected_num_new_objects = {"CoilHeatingElectric"=>1, "FanOnOff"=>1, "CoilCoolingDXSingleSpeed"=>1, "ZoneHVACPackagedTerminalAirConditioner"=>1}
    expected_values = {"COP"=>2.49}
    _test_measure("SFD_2000sqft_2story_FB_UA_Denver_ElectricBaseboard_RoomAC.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 2)
  end  
  
  def test_retrofit_replace_boiler_room_air_conditioner
    args_hash = {}
    expected_num_del_objects = {"CoilCoolingDXSingleSpeed"=>1, "ZoneHVACPackagedTerminalAirConditioner"=>1, "FanOnOff"=>1, "CoilHeatingElectric"=>1}
    expected_num_new_objects = {"CoilHeatingElectric"=>1, "FanOnOff"=>1, "CoilCoolingDXSingleSpeed"=>1, "ZoneHVACPackagedTerminalAirConditioner"=>1}
    expected_values = {"COP"=>2.49}
    _test_measure("SFD_2000sqft_2story_FB_UA_Denver_Boiler_RoomAC.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 2)
  end

  def test_retrofit_replace_gshp_vert_bore
    args_hash = {}
    expected_num_del_objects = {"SetpointManagerFollowGroundTemperature"=>1, "GroundHeatExchangerVertical"=>1, "FanOnOff"=>1, "CoilHeatingWaterToAirHeatPumpEquationFit"=>1, "CoilCoolingWaterToAirHeatPumpEquationFit"=>1, "PumpVariableSpeed"=>1, "CoilHeatingElectric"=>1, "PlantLoop"=>1, "AirTerminalSingleDuctUncontrolled"=>2, "AirLoopHVACUnitarySystem"=>1, "AirLoopHVAC"=>1}
    expected_num_new_objects = {"CoilHeatingElectric"=>1, "FanOnOff"=>1, "CoilCoolingDXSingleSpeed"=>1, "ZoneHVACPackagedTerminalAirConditioner"=>1}
    expected_values = {"COP"=>2.49}
    _test_measure("SFD_2000sqft_2story_FB_UA_Denver_GSHPVertBore.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 4)
  end  
  
  def test_single_family_attached_new_construction
    num_units = 4
    args_hash = {}
    expected_num_del_objects = {}
    expected_num_new_objects = {"CoilHeatingElectric"=>num_units, "FanOnOff"=>num_units, "CoilCoolingDXSingleSpeed"=>num_units, "ZoneHVACPackagedTerminalAirConditioner"=>num_units}
    expected_values = {"COP"=>2.49}
    _test_measure("SFA_4units_1story_FB_UA_Denver.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, num_units*1)
  end

  def test_multifamily_new_construction
    num_units = 8
    args_hash = {}
    expected_num_del_objects = {}
    expected_num_new_objects = {"CoilHeatingElectric"=>num_units, "FanOnOff"=>num_units, "CoilCoolingDXSingleSpeed"=>num_units, "ZoneHVACPackagedTerminalAirConditioner"=>num_units}
    expected_values = {"COP"=>2.49}
    _test_measure("MF_8units_1story_SL_Denver.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, num_units*1)
  end   
  
  private 
  
  def _test_measure(osm_file_or_model, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, num_infos=0, num_warnings=0, debug=false)
    # create an instance of the measure
    measure = ProcessRoomAirConditioner.new

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
    obj_type_exclusions = ["CurveQuadratic", "CurveBiquadratic", "CurveCubic", "Node", "AirLoopHVACZoneMixer", "SizingSystem", "AirLoopHVACZoneSplitter", "ScheduleTypeLimits", "CurveExponent", "ScheduleConstant", "SizingPlant", "PipeAdiabatic", "ConnectorSplitter", "ModelObjectList", "ConnectorMixer"]
    all_new_objects = get_object_additions(initial_objects, final_objects, obj_type_exclusions)
    all_del_objects = get_object_additions(final_objects, initial_objects, obj_type_exclusions)
    
    # check we have the expected number of new/deleted objects
    check_num_objects(all_new_objects, expected_num_new_objects, "added")
    check_num_objects(all_del_objects, expected_num_del_objects, "deleted")

    all_new_objects.each do |obj_type, new_objects|
        new_objects.each do |new_object|
            next if not new_object.respond_to?("to_#{obj_type}")
            new_object = new_object.public_send("to_#{obj_type}").get
            if obj_type == "CoilCoolingDXSingleSpeed"
                if new_object.ratedCOP.is_initialized
                  assert_in_epsilon(expected_values["COP"], new_object.ratedCOP.get, 0.01)
                end
                if new_object.ratedTotalCoolingCapacity.is_initialized
                  assert_in_epsilon(expected_values["NominalCapacity"], new_object.ratedTotalCoolingCapacity.get, 0.01)
                end            end
        end
    end
    
    return model
  end
  
end
