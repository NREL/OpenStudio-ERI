require_relative '../../../test/minitest_helper'
require 'openstudio'
require 'openstudio/ruleset/ShowRunnerOutput'
require 'minitest/autorun'
require_relative '../measure.rb'
require 'fileutils'

class ProcessMiniSplitHeatPumpTest < MiniTest::Test 
  
  def test_new_construction_fbsmt_seer_14_5_8_2_hspf
    args_hash = {}
    args_hash["pan_heater_power"] = 150.0
    args_hash["heat_pump_capacity"] = "3.0 tons"
    args_hash["supplemental_capacity"] = "20 kBtu/hr"
    expected_num_del_objects = {}
    expected_num_new_objects = {"AirConditionerVariableRefrigerantFlow"=>2, "FanOnOff"=>2, "ZoneHVACTerminalUnitVariableRefrigerantFlow"=>2, "CoilHeatingDXVariableRefrigerantFlow"=>2, "CoilCoolingDXVariableRefrigerantFlow"=>2, "ZoneHVACBaseboardConvectiveElectric"=>2, "ElectricEquipment"=>1, "ElectricEquipmentDefinition"=>1, "EnergyManagementSystemSensor"=>3, "EnergyManagementSystemActuator"=>1, "EnergyManagementSystemProgram"=>1, "EnergyManagementSystemProgramCallingManager"=>1, "OutputVariable"=>2}
    expected_values = {"CoolingCOP"=>2.34, "CoolingNominalCapacity"=>8440.45, "FBsmtZoneCoolingNominalCapacity"=>4220.22, "HeatingCOP"=>2.79, "HeatingNominalCapacity"=>8979.70, "FBsmtZoneHeatingNominalCapacity"=>4489.85}
    _test_measure("SFD_2000sqft_2story_FB_UA_Denver.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 4)    
  end  
  
  def test_retrofit_replace_furnace
    args_hash = {}
    expected_num_del_objects = {"AirLoopHVACUnitarySystem"=>1, "AirLoopHVAC"=>1, "CoilHeatingGas"=>1, "FanOnOff"=>1, "AirTerminalSingleDuctUncontrolled"=>2}
    expected_num_new_objects = {"AirConditionerVariableRefrigerantFlow"=>2, "FanOnOff"=>2, "ZoneHVACTerminalUnitVariableRefrigerantFlow"=>2, "CoilHeatingDXVariableRefrigerantFlow"=>2, "CoilCoolingDXVariableRefrigerantFlow"=>2, "ZoneHVACBaseboardConvectiveElectric"=>2}
    expected_values = {"CoolingCOP"=>2.34, "CoolingNominalCapacity"=>"AutoSize", "HeatingCOP"=>2.79, "HeatingNominalCapacity"=>"AutoSize"}
    _test_measure("SFD_2000sqft_2story_FB_UA_Denver_Furnace.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 6)
  end
  
  def test_retrofit_replace_ashp
    args_hash = {}
    expected_num_del_objects = {"AirLoopHVACUnitarySystem"=>1, "AirLoopHVAC"=>1, "CoilHeatingElectric"=>1, "FanOnOff"=>1, "AirTerminalSingleDuctUncontrolled"=>2, "CoilHeatingDXSingleSpeed"=>1, "CoilCoolingDXSingleSpeed"=>1}
    expected_num_new_objects = {"AirConditionerVariableRefrigerantFlow"=>2, "FanOnOff"=>2, "ZoneHVACTerminalUnitVariableRefrigerantFlow"=>2, "CoilHeatingDXVariableRefrigerantFlow"=>2, "CoilCoolingDXVariableRefrigerantFlow"=>2, "ZoneHVACBaseboardConvectiveElectric"=>2}
    expected_values = {"CoolingCOP"=>2.34, "CoolingNominalCapacity"=>"AutoSize", "HeatingCOP"=>2.79, "HeatingNominalCapacity"=>"AutoSize"}
    _test_measure("SFD_2000sqft_2story_FB_UA_Denver_ASHP.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 6)
  end  
  
  def test_retrofit_replace_central_air_conditioner
    args_hash = {}
    expected_num_del_objects = {"AirLoopHVACUnitarySystem"=>1, "AirLoopHVAC"=>1, "FanOnOff"=>1, "AirTerminalSingleDuctUncontrolled"=>2, "CoilCoolingDXSingleSpeed"=>1}
    expected_num_new_objects = {"AirConditionerVariableRefrigerantFlow"=>2, "FanOnOff"=>2, "ZoneHVACTerminalUnitVariableRefrigerantFlow"=>2, "CoilHeatingDXVariableRefrigerantFlow"=>2, "CoilCoolingDXVariableRefrigerantFlow"=>2, "ZoneHVACBaseboardConvectiveElectric"=>2}
    expected_values = {"CoolingCOP"=>2.34, "CoolingNominalCapacity"=>"AutoSize", "HeatingCOP"=>2.79, "HeatingNominalCapacity"=>"AutoSize"}
    _test_measure("SFD_2000sqft_2story_FB_UA_Denver_CentralAC.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 6)
  end  
  
  def test_retrofit_replace_room_air_conditioner
    args_hash = {}
    expected_num_del_objects = {"CoilCoolingDXSingleSpeed"=>1, "ZoneHVACPackagedTerminalAirConditioner"=>1, "CoilHeatingElectric"=>1, "FanOnOff"=>1}
    expected_num_new_objects = {"AirConditionerVariableRefrigerantFlow"=>2, "FanOnOff"=>2, "ZoneHVACTerminalUnitVariableRefrigerantFlow"=>2, "CoilHeatingDXVariableRefrigerantFlow"=>2, "CoilCoolingDXVariableRefrigerantFlow"=>2, "ZoneHVACBaseboardConvectiveElectric"=>2}
    expected_values = {"CoolingCOP"=>2.34, "CoolingNominalCapacity"=>"AutoSize", "HeatingCOP"=>2.79, "HeatingNominalCapacity"=>"AutoSize"}
    _test_measure("SFD_2000sqft_2story_FB_UA_Denver_RoomAC.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 5)
  end  
  
  def test_retrofit_replace_electric_baseboard
    args_hash = {}
    expected_num_del_objects = {"ZoneHVACBaseboardConvectiveElectric"=>2}
    expected_num_new_objects = {"AirConditionerVariableRefrigerantFlow"=>2, "FanOnOff"=>2, "ZoneHVACTerminalUnitVariableRefrigerantFlow"=>2, "CoilHeatingDXVariableRefrigerantFlow"=>2, "CoilCoolingDXVariableRefrigerantFlow"=>2, "ZoneHVACBaseboardConvectiveElectric"=>2}
    expected_values = {"CoolingCOP"=>2.34, "CoolingNominalCapacity"=>"AutoSize", "HeatingCOP"=>2.79, "HeatingNominalCapacity"=>"AutoSize"}
    _test_measure("SFD_2000sqft_2story_FB_UA_Denver_ElectricBaseboard.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 6)
  end
  
  def test_retrofit_replace_boiler
    args_hash = {}
    expected_num_del_objects = {"BoilerHotWater"=>1, "PumpConstantSpeed"=>1, "ZoneHVACBaseboardConvectiveWater"=>2, "SetpointManagerScheduled"=>1, "CoilHeatingWaterBaseboard"=>2, "PlantLoop"=>1}
    expected_num_new_objects = {"AirConditionerVariableRefrigerantFlow"=>2, "FanOnOff"=>2, "ZoneHVACTerminalUnitVariableRefrigerantFlow"=>2, "CoilHeatingDXVariableRefrigerantFlow"=>2, "CoilCoolingDXVariableRefrigerantFlow"=>2, "ZoneHVACBaseboardConvectiveElectric"=>2}
    expected_values = {"CoolingCOP"=>2.34, "CoolingNominalCapacity"=>"AutoSize", "HeatingCOP"=>2.79, "HeatingNominalCapacity"=>"AutoSize"}
    _test_measure("SFD_2000sqft_2story_FB_UA_Denver_Boiler.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 7)
  end  

  def test_retrofit_replace_mshp
    args_hash = {}
    expected_num_del_objects = {"FanOnOff"=>2, "AirConditionerVariableRefrigerantFlow"=>2, "ZoneHVACTerminalUnitVariableRefrigerantFlow"=>2, "CoilCoolingDXVariableRefrigerantFlow"=>2, "CoilHeatingDXVariableRefrigerantFlow"=>2, "ZoneHVACBaseboardConvectiveElectric"=>2}
    expected_num_new_objects = {"AirConditionerVariableRefrigerantFlow"=>2, "FanOnOff"=>2, "ZoneHVACTerminalUnitVariableRefrigerantFlow"=>2, "CoilHeatingDXVariableRefrigerantFlow"=>2, "CoilCoolingDXVariableRefrigerantFlow"=>2, "ZoneHVACBaseboardConvectiveElectric"=>2}
    expected_values = {"CoolingCOP"=>2.34, "CoolingNominalCapacity"=>"AutoSize", "HeatingCOP"=>2.79, "HeatingNominalCapacity"=>"AutoSize"}
    _test_measure("SFD_2000sqft_2story_FB_UA_Denver_MSHP.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 8)
  end
  
  def test_retrofit_replace_furnace_central_air_conditioner
    args_hash = {}
    expected_num_del_objects = {"AirLoopHVACUnitarySystem"=>1, "AirLoopHVAC"=>1, "CoilHeatingGas"=>1, "FanOnOff"=>1, "AirTerminalSingleDuctUncontrolled"=>2, "CoilCoolingDXSingleSpeed"=>1}
    expected_num_new_objects = {"AirConditionerVariableRefrigerantFlow"=>2, "FanOnOff"=>2, "ZoneHVACTerminalUnitVariableRefrigerantFlow"=>2, "CoilHeatingDXVariableRefrigerantFlow"=>2, "CoilCoolingDXVariableRefrigerantFlow"=>2, "ZoneHVACBaseboardConvectiveElectric"=>2}
    expected_values = {"CoolingCOP"=>2.34, "CoolingNominalCapacity"=>"AutoSize", "HeatingCOP"=>2.79, "HeatingNominalCapacity"=>"AutoSize"}
    _test_measure("SFD_2000sqft_2story_FB_UA_Denver_Furnace_CentralAC.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 7)
  end  
  
  def test_retrofit_replace_furnace_room_air_conditioner
    args_hash = {}
    expected_num_del_objects = {"AirLoopHVACUnitarySystem"=>1, "AirLoopHVAC"=>1, "CoilHeatingGas"=>1, "FanOnOff"=>2, "AirTerminalSingleDuctUncontrolled"=>2, "CoilCoolingDXSingleSpeed"=>1, "ZoneHVACPackagedTerminalAirConditioner"=>1, "CoilHeatingElectric"=>1}
    expected_num_new_objects = {"AirConditionerVariableRefrigerantFlow"=>2, "FanOnOff"=>2, "ZoneHVACTerminalUnitVariableRefrigerantFlow"=>2, "CoilHeatingDXVariableRefrigerantFlow"=>2, "CoilCoolingDXVariableRefrigerantFlow"=>2, "ZoneHVACBaseboardConvectiveElectric"=>2}
    expected_values = {"CoolingCOP"=>2.34, "CoolingNominalCapacity"=>"AutoSize", "HeatingCOP"=>2.79, "HeatingNominalCapacity"=>"AutoSize"}
    _test_measure("SFD_2000sqft_2story_FB_UA_Denver_Furnace_RoomAC.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 7)
  end  
  
  def test_retrofit_replace_electric_baseboard_central_air_conditioner
    args_hash = {}
    expected_num_del_objects = {"AirLoopHVACUnitarySystem"=>1, "AirLoopHVAC"=>1, "FanOnOff"=>1, "AirTerminalSingleDuctUncontrolled"=>2, "CoilCoolingDXSingleSpeed"=>1, "ZoneHVACBaseboardConvectiveElectric"=>2}
    expected_num_new_objects = {"AirConditionerVariableRefrigerantFlow"=>2, "FanOnOff"=>2, "ZoneHVACTerminalUnitVariableRefrigerantFlow"=>2, "CoilHeatingDXVariableRefrigerantFlow"=>2, "CoilCoolingDXVariableRefrigerantFlow"=>2, "ZoneHVACBaseboardConvectiveElectric"=>2}
    expected_values = {"CoolingCOP"=>2.34, "CoolingNominalCapacity"=>"AutoSize", "HeatingCOP"=>2.79, "HeatingNominalCapacity"=>"AutoSize"}
    _test_measure("SFD_2000sqft_2story_FB_UA_Denver_ElectricBaseboard_CentralAC.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 8)
  end  
  
  def test_retrofit_replace_boiler_central_air_conditioner
    args_hash = {}
    expected_num_del_objects = {"AirLoopHVACUnitarySystem"=>1, "AirLoopHVAC"=>1, "FanOnOff"=>1, "AirTerminalSingleDuctUncontrolled"=>2, "CoilCoolingDXSingleSpeed"=>1, "BoilerHotWater"=>1, "PumpConstantSpeed"=>1, "ZoneHVACBaseboardConvectiveWater"=>2, "SetpointManagerScheduled"=>1, "CoilHeatingWaterBaseboard"=>2, "PlantLoop"=>1}
    expected_num_new_objects = {"AirConditionerVariableRefrigerantFlow"=>2, "FanOnOff"=>2, "ZoneHVACTerminalUnitVariableRefrigerantFlow"=>2, "CoilHeatingDXVariableRefrigerantFlow"=>2, "CoilCoolingDXVariableRefrigerantFlow"=>2, "ZoneHVACBaseboardConvectiveElectric"=>2}
    expected_values = {"CoolingCOP"=>2.34, "CoolingNominalCapacity"=>"AutoSize", "HeatingCOP"=>2.79, "HeatingNominalCapacity"=>"AutoSize"}
    _test_measure("SFD_2000sqft_2story_FB_UA_Denver_Boiler_CentralAC.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 9)
  end  

  def test_retrofit_replace_electric_baseboard_room_air_conditioner
    args_hash = {}
    expected_num_del_objects = {"CoilCoolingDXSingleSpeed"=>1, "ZoneHVACPackagedTerminalAirConditioner"=>1, "FanOnOff"=>1, "CoilHeatingElectric"=>1, "ZoneHVACBaseboardConvectiveElectric"=>2}
    expected_num_new_objects = {"AirConditionerVariableRefrigerantFlow"=>2, "FanOnOff"=>2, "ZoneHVACTerminalUnitVariableRefrigerantFlow"=>2, "CoilHeatingDXVariableRefrigerantFlow"=>2, "CoilCoolingDXVariableRefrigerantFlow"=>2, "ZoneHVACBaseboardConvectiveElectric"=>2}
    expected_values = {"CoolingCOP"=>2.34, "CoolingNominalCapacity"=>"AutoSize", "HeatingCOP"=>2.79, "HeatingNominalCapacity"=>"AutoSize"}
    _test_measure("SFD_2000sqft_2story_FB_UA_Denver_ElectricBaseboard_RoomAC.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 7)
  end   
  
  def test_retrofit_replace_boiler_room_air_conditioner
    args_hash = {}
    expected_num_del_objects = {"CoilCoolingDXSingleSpeed"=>1, "ZoneHVACPackagedTerminalAirConditioner"=>1, "FanOnOff"=>1, "CoilHeatingElectric"=>1, "BoilerHotWater"=>1, "PumpConstantSpeed"=>1, "ZoneHVACBaseboardConvectiveWater"=>2, "SetpointManagerScheduled"=>1, "CoilHeatingWaterBaseboard"=>2, "PlantLoop"=>1}
    expected_num_new_objects = {"AirConditionerVariableRefrigerantFlow"=>2, "FanOnOff"=>2, "ZoneHVACTerminalUnitVariableRefrigerantFlow"=>2, "CoilHeatingDXVariableRefrigerantFlow"=>2, "CoilCoolingDXVariableRefrigerantFlow"=>2, "ZoneHVACBaseboardConvectiveElectric"=>2}
    expected_values = {"CoolingCOP"=>2.34, "CoolingNominalCapacity"=>"AutoSize", "HeatingCOP"=>2.79, "HeatingNominalCapacity"=>"AutoSize"}
    _test_measure("SFD_2000sqft_2story_FB_UA_Denver_Boiler_RoomAC.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 8)
  end

  def test_retrofit_replace_gshp_vert_bore
    args_hash = {}
    expected_num_del_objects = {"SetpointManagerFollowGroundTemperature"=>1, "GroundHeatExchangerVertical"=>1, "FanOnOff"=>1, "CoilHeatingWaterToAirHeatPumpEquationFit"=>1, "CoilCoolingWaterToAirHeatPumpEquationFit"=>1, "PumpVariableSpeed"=>1, "CoilHeatingElectric"=>1, "PlantLoop"=>1, "AirTerminalSingleDuctUncontrolled"=>2, "AirLoopHVACUnitarySystem"=>1, "AirLoopHVAC"=>1}
    expected_num_new_objects = {"AirConditionerVariableRefrigerantFlow"=>2, "FanOnOff"=>2, "ZoneHVACTerminalUnitVariableRefrigerantFlow"=>2, "CoilHeatingDXVariableRefrigerantFlow"=>2, "CoilCoolingDXVariableRefrigerantFlow"=>2, "ZoneHVACBaseboardConvectiveElectric"=>2}
    expected_values = {"CoolingCOP"=>2.34, "CoolingNominalCapacity"=>"AutoSize", "HeatingCOP"=>2.79, "HeatingNominalCapacity"=>"AutoSize"}
    _test_measure("SFD_2000sqft_2story_FB_UA_Denver_GSHPVertBore.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 7)
  end  
  
  def test_multifamily_new_construction_1
    num_units = 4
    args_hash = {}
    expected_num_del_objects = {}
    expected_num_new_objects = {"AirConditionerVariableRefrigerantFlow"=>num_units*2, "FanOnOff"=>num_units*2, "ZoneHVACTerminalUnitVariableRefrigerantFlow"=>num_units*2, "CoilHeatingDXVariableRefrigerantFlow"=>num_units*2, "CoilCoolingDXVariableRefrigerantFlow"=>num_units*2, "ZoneHVACBaseboardConvectiveElectric"=>num_units*2}
    expected_values = {"CoolingCOP"=>2.34, "CoolingNominalCapacity"=>"AutoSize", "HeatingCOP"=>2.79, "HeatingNominalCapacity"=>"AutoSize"}
    _test_measure("singlefamily_attached_fbsmt_4_units.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, num_units*4)
  end

  def test_multifamily_new_construction_2
    num_units = 8
    args_hash = {}
    args_hash["pan_heater_power"] = 150.0
    expected_num_del_objects = {}
    expected_num_new_objects = {"AirConditionerVariableRefrigerantFlow"=>num_units, "FanOnOff"=>num_units, "ZoneHVACTerminalUnitVariableRefrigerantFlow"=>num_units, "CoilHeatingDXVariableRefrigerantFlow"=>num_units, "CoilCoolingDXVariableRefrigerantFlow"=>num_units, "ZoneHVACBaseboardConvectiveElectric"=>num_units, "ElectricEquipment"=>num_units*1, "ElectricEquipmentDefinition"=>num_units*1, "EnergyManagementSystemSensor"=>num_units*2, "EnergyManagementSystemActuator"=>num_units*1, "EnergyManagementSystemProgram"=>num_units*1, "EnergyManagementSystemProgramCallingManager"=>num_units*1, "OutputVariable"=>2}
    expected_values = {"CoolingCOP"=>2.34, "CoolingNominalCapacity"=>"AutoSize", "HeatingCOP"=>2.79, "HeatingNominalCapacity"=>"AutoSize"}
    _test_measure("multifamily_8_units.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, num_units*2)
  end
  
  def test_retrofit_increase_pan_heater_power
    args_hash = {}
    args_hash["pan_heater_power"] = 20.0
    expected_num_del_objects = {}
    expected_num_new_objects = {"AirConditionerVariableRefrigerantFlow"=>2, "FanOnOff"=>2, "ZoneHVACTerminalUnitVariableRefrigerantFlow"=>2, "CoilHeatingDXVariableRefrigerantFlow"=>2, "CoilCoolingDXVariableRefrigerantFlow"=>2, "ZoneHVACBaseboardConvectiveElectric"=>2, "ElectricEquipment"=>1, "ElectricEquipmentDefinition"=>1, "EnergyManagementSystemSensor"=>3, "EnergyManagementSystemActuator"=>1, "EnergyManagementSystemProgram"=>1, "EnergyManagementSystemProgramCallingManager"=>1, "OutputVariable"=>2}
    expected_values = {"CoolingCOP"=>2.34, "CoolingNominalCapacity"=>"AutoSize", "HeatingCOP"=>2.79, "HeatingNominalCapacity"=>"AutoSize"}
    model = _test_measure("SFD_2000sqft_2story_FB_UA_Denver.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 4)
    args_hash["pan_heater_power"] = 30.0
    expected_num_del_objects = {"AirConditionerVariableRefrigerantFlow"=>2, "FanOnOff"=>2, "ZoneHVACTerminalUnitVariableRefrigerantFlow"=>2, "CoilHeatingDXVariableRefrigerantFlow"=>2, "CoilCoolingDXVariableRefrigerantFlow"=>2, "ZoneHVACBaseboardConvectiveElectric"=>2, "ElectricEquipment"=>1, "ElectricEquipmentDefinition"=>1, "EnergyManagementSystemSensor"=>3, "EnergyManagementSystemActuator"=>1, "EnergyManagementSystemProgram"=>1, "EnergyManagementSystemProgramCallingManager"=>1, "OutputVariable"=>2}
    expected_num_new_objects = {"AirConditionerVariableRefrigerantFlow"=>2, "FanOnOff"=>2, "ZoneHVACTerminalUnitVariableRefrigerantFlow"=>2, "CoilHeatingDXVariableRefrigerantFlow"=>2, "CoilCoolingDXVariableRefrigerantFlow"=>2, "ZoneHVACBaseboardConvectiveElectric"=>2, "ElectricEquipment"=>1, "ElectricEquipmentDefinition"=>1, "EnergyManagementSystemSensor"=>3, "EnergyManagementSystemActuator"=>1, "EnergyManagementSystemProgram"=>1, "EnergyManagementSystemProgramCallingManager"=>1, "OutputVariable"=>2}
    expected_values = {"CoolingCOP"=>2.34, "CoolingNominalCapacity"=>"AutoSize", "HeatingCOP"=>2.79, "HeatingNominalCapacity"=>"AutoSize"}
    _test_measure(model, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 8)
  end
  
  private
  
  def _test_measure(osm_file_or_model, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, num_infos=0, num_warnings=0, debug=false)
    # create an instance of the measure
    measure = ProcessVRFMinisplit.new

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
            if obj_type == "AirConditionerVariableRefrigerantFlow"
              unless new_object.isRatedTotalCoolingCapacityAutosized
                if new_object.name.to_s.start_with? Constants.LivingZone
                  assert_in_epsilon(expected_values["CoolingNominalCapacity"], new_object.ratedTotalCoolingCapacity.get, 0.01)
                elsif new_object.name.to_s.start_with? Constants.FinishedBasementZone
                  assert_in_epsilon(expected_values["FBsmtZoneCoolingNominalCapacity"], new_object.ratedTotalCoolingCapacity.get, 0.01)
                end
              end
              unless new_object.isRatedTotalHeatingCapacityAutosized
                if new_object.name.to_s.start_with? Constants.LivingZone
                  assert_in_epsilon(expected_values["HeatingNominalCapacity"], new_object.ratedTotalHeatingCapacity.get, 0.01)
                elsif new_object.name.to_s.start_with? Constants.FinishedBasementZone
                  assert_in_epsilon(expected_values["FBsmtZoneHeatingNominalCapacity"], new_object.ratedTotalHeatingCapacity.get, 0.01)
                end
              end
              assert_in_epsilon(expected_values["CoolingCOP"], new_object.ratedCoolingCOP, 0.01)
              assert_in_epsilon(expected_values["HeatingCOP"], new_object.ratedHeatingCOP, 0.01)
            end
        end
    end
    
    return model
  end  
  
end
