require_relative '../../../test/minitest_helper'
require 'openstudio'
require 'openstudio/ruleset/ShowRunnerOutput'
require 'minitest/autorun'
require_relative '../measure.rb'
require 'fileutils'

class ProcessBoilerElectricTest < MiniTest::Test
  
  def test_argument_error_steam_boiler
    args_hash = {}
    args_hash["system_type"] = Constants.BoilerTypeSteam
    result = _test_error("SFD_2000sqft_2story_FB_UA_Denver.osm", args_hash)
    assert_includes(result.errors.map{ |x| x.logMessage }, "Cannot currently model steam boilers.")    
  end  
  
  def test_oat_reset_enabled_nil_oat
    args_hash = {}
    args_hash["system_type"] = Constants.BoilerTypeCondensing
    args_hash["oat_reset_enabled"] = "true"
    args_hash["capacity"] = "20"
    expected_num_del_objects = {}
    expected_num_new_objects = {"BoilerHotWater"=>1, "ZoneHVACBaseboardConvectiveWater"=>2, "PlantLoop"=>1, "CoilHeatingWaterBaseboard"=>2, "SetpointManagerScheduled"=>1, "PumpVariableSpeed"=>1}
    expected_values = {"Efficiency"=>0.96, "NominalCapacity"=>5861.42, "FuelType"=>Constants.FuelTypeElectric, "hvac_priority"=>1}
    _test_measure("SFD_2000sqft_2story_FB_UA_Denver.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 2, 1)
  end
      
  def test_condensing_boiler_oat_reset_enabled
    args_hash = {}
    args_hash["system_type"] = Constants.BoilerTypeCondensing
    args_hash["oat_reset_enabled"] = "true"
    args_hash["oat_low"] = 0.0
    args_hash["oat_hwst_low"] = 180.0
    args_hash["oat_high"] = 68.0
    args_hash["oat_hwst_high"] = 95.0
    expected_num_del_objects = {}
    expected_num_new_objects = {"BoilerHotWater"=>1, "ZoneHVACBaseboardConvectiveWater"=>2, "PlantLoop"=>1, "CoilHeatingWaterBaseboard"=>2, "SetpointManagerScheduled"=>1, "PumpVariableSpeed"=>1}
    expected_values = {"Efficiency"=>0.96, "FuelType"=>Constants.FuelTypeElectric, "hvac_priority"=>1}
    _test_measure("SFD_2000sqft_2story_FB_UA_Denver.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 2)
  end
  
  def test_retrofit_replace_furnace
    args_hash = {}
    expected_num_del_objects = {"AirLoopHVACUnitarySystem"=>1, "AirLoopHVAC"=>1, "CoilHeatingGas"=>1, "FanOnOff"=>1, "AirTerminalSingleDuctUncontrolled"=>2}
    expected_num_new_objects = {"BoilerHotWater"=>1, "ZoneHVACBaseboardConvectiveWater"=>2, "PlantLoop"=>1, "CoilHeatingWaterBaseboard"=>2, "SetpointManagerScheduled"=>1, "PumpVariableSpeed"=>1}
    expected_values = {"Efficiency"=>1.0, "FuelType"=>Constants.FuelTypeElectric, "hvac_priority"=>1}
    _test_measure("SFD_2000sqft_2story_FB_UA_Denver_Furnace.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 4)
  end
  
  def test_retrofit_replace_ashp
    args_hash = {}
    expected_num_del_objects = {"AirLoopHVACUnitarySystem"=>1, "AirLoopHVAC"=>1, "CoilHeatingElectric"=>1, "FanOnOff"=>1, "AirTerminalSingleDuctUncontrolled"=>2, "CoilHeatingDXSingleSpeed"=>1, "CoilCoolingDXSingleSpeed"=>1}
    expected_num_new_objects = {"BoilerHotWater"=>1, "ZoneHVACBaseboardConvectiveWater"=>2, "PlantLoop"=>1, "CoilHeatingWaterBaseboard"=>2, "SetpointManagerScheduled"=>1, "PumpVariableSpeed"=>1}
    expected_values = {"Efficiency"=>1.0, "FuelType"=>Constants.FuelTypeElectric, "hvac_priority"=>1}
    _test_measure("SFD_2000sqft_2story_FB_UA_Denver_ASHP.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 4)
  end  
  
  def test_retrofit_replace_central_air_conditioner
    args_hash = {}
    expected_num_del_objects = {}
    expected_num_new_objects = {"BoilerHotWater"=>1, "ZoneHVACBaseboardConvectiveWater"=>2, "PlantLoop"=>1, "CoilHeatingWaterBaseboard"=>2, "SetpointManagerScheduled"=>1, "PumpVariableSpeed"=>1}
    expected_values = {"Efficiency"=>1.0, "FuelType"=>Constants.FuelTypeElectric, "hvac_priority"=>1}
    _test_measure("SFD_2000sqft_2story_FB_UA_Denver_CentralAC.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 2)
  end
  
  def test_retrofit_replace_room_air_conditioner
    args_hash = {}
    expected_num_del_objects = {}
    expected_num_new_objects = {"BoilerHotWater"=>1, "ZoneHVACBaseboardConvectiveWater"=>2, "PlantLoop"=>1, "CoilHeatingWaterBaseboard"=>2, "SetpointManagerScheduled"=>1, "PumpVariableSpeed"=>1}
    expected_values = {"Efficiency"=>1.0, "FuelType"=>Constants.FuelTypeElectric, "hvac_priority"=>1}
    _test_measure("SFD_2000sqft_2story_FB_UA_Denver_RoomAC.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 2)
  end  
  
  def test_retrofit_replace_electric_baseboard
    args_hash = {}
    expected_num_del_objects = {"ZoneHVACBaseboardConvectiveElectric"=>2}
    expected_num_new_objects = {"BoilerHotWater"=>1, "ZoneHVACBaseboardConvectiveWater"=>2, "PlantLoop"=>1, "CoilHeatingWaterBaseboard"=>2, "SetpointManagerScheduled"=>1, "PumpVariableSpeed"=>1}
    expected_values = {"Efficiency"=>1.0, "FuelType"=>Constants.FuelTypeElectric, "hvac_priority"=>1}
    _test_measure("SFD_2000sqft_2story_FB_UA_Denver_ElectricBaseboard.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 4)
  end
  
  def test_retrofit_replace_boiler
    args_hash = {}
    expected_num_del_objects = {"BoilerHotWater"=>1, "PumpVariableSpeed"=>1, "ZoneHVACBaseboardConvectiveWater"=>2, "SetpointManagerScheduled"=>1, "CoilHeatingWaterBaseboard"=>2, "PlantLoop"=>1}
    expected_num_new_objects = {"BoilerHotWater"=>1, "ZoneHVACBaseboardConvectiveWater"=>2, "PlantLoop"=>1, "CoilHeatingWaterBaseboard"=>2, "SetpointManagerScheduled"=>1, "PumpVariableSpeed"=>1}
    expected_values = {"Efficiency"=>1.0, "FuelType"=>Constants.FuelTypeElectric, "hvac_priority"=>1}
    _test_measure("SFD_2000sqft_2story_FB_UA_Denver_Boiler.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 5)
  end
  
  def test_retrofit_replace_mshp
    args_hash = {}
    expected_num_del_objects = {"FanOnOff"=>2, "AirConditionerVariableRefrigerantFlow"=>2, "ZoneHVACTerminalUnitVariableRefrigerantFlow"=>2, "CoilCoolingDXVariableRefrigerantFlow"=>2, "CoilHeatingDXVariableRefrigerantFlow"=>2, "ZoneHVACBaseboardConvectiveElectric"=>2}
    expected_num_new_objects = {"BoilerHotWater"=>1, "ZoneHVACBaseboardConvectiveWater"=>2, "PlantLoop"=>1, "CoilHeatingWaterBaseboard"=>2, "SetpointManagerScheduled"=>1, "PumpVariableSpeed"=>1}
    expected_values = {"Efficiency"=>1.0, "FuelType"=>Constants.FuelTypeElectric, "hvac_priority"=>1}
    _test_measure("SFD_2000sqft_2story_FB_UA_Denver_MSHP.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 6)
  end
  
  def test_retrofit_replace_furnace_central_air_conditioner
    args_hash = {}
    expected_num_del_objects = {"CoilHeatingGas"=>1}
    expected_num_new_objects = {"BoilerHotWater"=>1, "ZoneHVACBaseboardConvectiveWater"=>2, "PlantLoop"=>1, "CoilHeatingWaterBaseboard"=>2, "SetpointManagerScheduled"=>1, "PumpVariableSpeed"=>1}
    expected_values = {"Efficiency"=>1.0, "FuelType"=>Constants.FuelTypeElectric, "hvac_priority"=>1}
    _test_measure("SFD_2000sqft_2story_FB_UA_Denver_Furnace_CentralAC.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 3)
  end  
  
  def test_retrofit_replace_furnace_room_air_conditioner
    args_hash = {}
    expected_num_del_objects = {"AirLoopHVACUnitarySystem"=>1, "AirLoopHVAC"=>1, "CoilHeatingGas"=>1, "FanOnOff"=>1, "AirTerminalSingleDuctUncontrolled"=>2}
    expected_num_new_objects = {"BoilerHotWater"=>1, "ZoneHVACBaseboardConvectiveWater"=>2, "PlantLoop"=>1, "CoilHeatingWaterBaseboard"=>2, "SetpointManagerScheduled"=>1, "PumpVariableSpeed"=>1}
    expected_values = {"Efficiency"=>1.0, "FuelType"=>Constants.FuelTypeElectric, "hvac_priority"=>1}
    _test_measure("SFD_2000sqft_2story_FB_UA_Denver_Furnace_RoomAC.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 4)
  end
  
  def test_retrofit_replace_electric_baseboard_central_air_conditioner
    args_hash = {}
    expected_num_del_objects = {"ZoneHVACBaseboardConvectiveElectric"=>2}
    expected_num_new_objects = {"BoilerHotWater"=>1, "ZoneHVACBaseboardConvectiveWater"=>2, "PlantLoop"=>1, "CoilHeatingWaterBaseboard"=>2, "SetpointManagerScheduled"=>1, "PumpVariableSpeed"=>1}
    expected_values = {"Efficiency"=>1.0, "FuelType"=>Constants.FuelTypeElectric, "hvac_priority"=>1}
    _test_measure("SFD_2000sqft_2story_FB_UA_Denver_ElectricBaseboard_CentralAC.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 4)
  end  
  
  def test_retrofit_replace_boiler_central_air_conditioner
    args_hash = {}
    expected_num_del_objects = {"BoilerHotWater"=>1, "PumpVariableSpeed"=>1, "ZoneHVACBaseboardConvectiveWater"=>2, "SetpointManagerScheduled"=>1, "CoilHeatingWaterBaseboard"=>2, "PlantLoop"=>1}
    expected_num_new_objects = {"BoilerHotWater"=>1, "ZoneHVACBaseboardConvectiveWater"=>2, "PlantLoop"=>1, "CoilHeatingWaterBaseboard"=>2, "SetpointManagerScheduled"=>1, "PumpVariableSpeed"=>1}
    expected_values = {"Efficiency"=>1.0, "FuelType"=>Constants.FuelTypeElectric, "hvac_priority"=>1}
    _test_measure("SFD_2000sqft_2story_FB_UA_Denver_Boiler_CentralAC.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 5)
  end  

  def test_retrofit_replace_electric_baseboard_room_air_conditioner
    args_hash = {}
    expected_num_del_objects = {"ZoneHVACBaseboardConvectiveElectric"=>2}
    expected_num_new_objects = {"BoilerHotWater"=>1, "ZoneHVACBaseboardConvectiveWater"=>2, "PlantLoop"=>1, "CoilHeatingWaterBaseboard"=>2, "SetpointManagerScheduled"=>1, "PumpVariableSpeed"=>1}
    expected_values = {"Efficiency"=>1.0, "FuelType"=>Constants.FuelTypeElectric, "hvac_priority"=>1}
    _test_measure("SFD_2000sqft_2story_FB_UA_Denver_ElectricBaseboard_RoomAC.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 4)
  end
  
  def test_retrofit_replace_boiler_room_air_conditioner
    args_hash = {}
    expected_num_del_objects = {"BoilerHotWater"=>1, "PumpVariableSpeed"=>1, "ZoneHVACBaseboardConvectiveWater"=>2, "SetpointManagerScheduled"=>1, "CoilHeatingWaterBaseboard"=>2, "PlantLoop"=>1}
    expected_num_new_objects = {"BoilerHotWater"=>1, "ZoneHVACBaseboardConvectiveWater"=>2, "PlantLoop"=>1, "CoilHeatingWaterBaseboard"=>2, "SetpointManagerScheduled"=>1, "PumpVariableSpeed"=>1}
    expected_values = {"Efficiency"=>1.0, "FuelType"=>Constants.FuelTypeElectric, "hvac_priority"=>1}
    _test_measure("SFD_2000sqft_2story_FB_UA_Denver_Boiler_RoomAC.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 5)
  end
  
  def test_retrofit_replace_gshp_vert_bore
    args_hash = {}
    expected_num_del_objects = {"SetpointManagerFollowGroundTemperature"=>1, "GroundHeatExchangerVertical"=>1, "FanOnOff"=>1, "CoilHeatingWaterToAirHeatPumpEquationFit"=>1, "CoilCoolingWaterToAirHeatPumpEquationFit"=>1, "PumpVariableSpeed"=>1, "CoilHeatingElectric"=>1, "PlantLoop"=>1, "AirTerminalSingleDuctUncontrolled"=>2, "AirLoopHVACUnitarySystem"=>1, "AirLoopHVAC"=>1}
    expected_num_new_objects = {"BoilerHotWater"=>1, "ZoneHVACBaseboardConvectiveWater"=>2, "PlantLoop"=>1, "CoilHeatingWaterBaseboard"=>2, "SetpointManagerScheduled"=>1, "PumpVariableSpeed"=>1}
    expected_values = {"Efficiency"=>1.0, "FuelType"=>Constants.FuelTypeElectric, "hvac_priority"=>1}
    _test_measure("SFD_2000sqft_2story_FB_UA_Denver_GSHPVertBore.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 5)
  end  

  def test_single_family_attached_new_construction
    num_units = 4
    args_hash = {}
    expected_num_del_objects = {}
    expected_num_new_objects = {"BoilerHotWater"=>1, "ZoneHVACBaseboardConvectiveWater"=>num_units*2, "PlantLoop"=>1, "CoilHeatingWaterBaseboard"=>num_units*2, "SetpointManagerScheduled"=>1, "PumpVariableSpeed"=>1}
    expected_values = {"Efficiency"=>1.0, "FuelType"=>Constants.FuelTypeElectric, "hvac_priority"=>1}
    _test_measure("SFA_4units_1story_FB_UA_Denver.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, num_units*2)
  end

  def test_multifamily_new_construction
    num_units = 8
    args_hash = {}
    expected_num_del_objects = {}
    expected_num_new_objects = {"BoilerHotWater"=>1, "ZoneHVACBaseboardConvectiveWater"=>num_units, "PlantLoop"=>1, "CoilHeatingWaterBaseboard"=>num_units, "SetpointManagerScheduled"=>1, "PumpVariableSpeed"=>1}
    expected_values = {"Efficiency"=>1.0, "FuelType"=>Constants.FuelTypeElectric, "hvac_priority"=>1}
    _test_measure("MF_8units_1story_SL_Denver.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, num_units*1)
  end  
  
  private
  
  def _test_error(osm_file_or_model, args_hash)
    # create an instance of the measure
    measure = ProcessBoilerElectric.new

    # create an instance of a runner
    runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)

    model = get_model(File.dirname(__FILE__), osm_file_or_model)

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

    # assert that it didn't run
    assert_equal("Fail", result.value.valueName)
    assert(result.errors.size == 1)
    
    return result
  end  
  
  def _test_measure(osm_file_or_model, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, num_infos=0, num_warnings=0, debug=false)
    # create an instance of the measure
    measure = ProcessBoilerElectric.new

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
    obj_type_exclusions = ["CurveBicubic", "CurveQuadratic", "CurveBiquadratic", "CurveCubic", "Node", "AirLoopHVACZoneMixer", "SizingSystem", "AirLoopHVACZoneSplitter", "ScheduleTypeLimits", "CurveExponent", "ScheduleConstant", "SizingPlant", "PipeAdiabatic", "ConnectorSplitter", "ModelObjectList", "ConnectorMixer"]
    all_new_objects = get_object_additions(initial_objects, final_objects, obj_type_exclusions)
    all_del_objects = get_object_additions(final_objects, initial_objects, obj_type_exclusions)
    
    # check we have the expected number of new/deleted objects
    check_num_objects(all_new_objects, expected_num_new_objects, "added")
    check_num_objects(all_del_objects, expected_num_del_objects, "deleted")

    all_new_objects.each do |obj_type, new_objects|
        new_objects.each do |new_object|
            next if not new_object.respond_to?("to_#{obj_type}")
            new_object = new_object.public_send("to_#{obj_type}").get
            if obj_type == "BoilerHotWater"
              assert_in_epsilon(expected_values["Efficiency"], new_object.nominalThermalEfficiency, 0.01)
              assert_equal(HelperMethods.eplus_fuel_map(expected_values["FuelType"]), new_object.fuelType)
              if new_object.nominalCapacity.is_initialized
                assert_in_epsilon(expected_values["NominalCapacity"], new_object.nominalCapacity.get, 0.01)
              end
            elsif obj_type == "ZoneHVACBaseboardConvectiveWater"
                model.getThermalZones.each do |thermal_zone|
                  cooling_seq = thermal_zone.equipmentInCoolingOrder.index new_object
                  heating_seq = thermal_zone.equipmentInHeatingOrder.index new_object
                  next if cooling_seq.nil? or heating_seq.nil?
                  assert_equal(expected_values["hvac_priority"], cooling_seq+1)
                  assert_equal(expected_values["hvac_priority"], heating_seq+1)
                end              
            end
        end
    end
    
    return model
  end
  
end
