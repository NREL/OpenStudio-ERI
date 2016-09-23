require_relative '../../../test/minitest_helper'
require 'openstudio'
require 'openstudio/ruleset/ShowRunnerOutput'
require 'minitest/autorun'
require_relative '../measure.rb'
require 'fileutils'

class ProcessFurnaceTest < MiniTest::Test 
  
  # expected_objects: [AirLoopHVACUnitarySystem, AirLoopHVAC, CoilHeatingGas, CoilHeatingElectric, FanOnOff, AirTerminalSingleDuctUncontrolled, CoilHeatingDXSingleSpeed, CoilCoolingDXSingleSpeed, ZoneHVACPackagedTerminalAirConditioner, ZoneHVACBaseboardConvectiveElectric, PlantLoop, BoilerHotWater, CoilHeatingWaterBaseboard, AirConditionerVariableRefrigerantFlow, ZoneHVACTerminalUnitVariableRefrigerantFlow]
  # expected_values: [Efficiency, NominalCapacity, MaximumSupplyAirTemperature]

  def test_new_construction_afue_0_78
    args_hash = {}
    _test_measure("singlefamily_detached.osm", args_hash, [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0], [1, 1, 1, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0], [0.78, "AutoSize", 48.88], 4)
  end  
  
  def test_new_construction_fbsmt_afue_0_78
    args_hash = {}
    args_hash["furnacecap"] = "20 kBtu/hr"
    _test_measure("singlefamily_detached_fbsmt.osm", args_hash, [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0], [1, 1, 1, 0, 1, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0], [0.78, 5861.42, 48.88], 5)
  end
  
  def test_new_construction_afue_1
    args_hash = {}
    args_hash["fueltype"] = Constants.FuelTypeElectric
    args_hash["afue"] = 1
    args_hash["furnacecap"] = "40 kBtu/hr"
    _test_measure("singlefamily_detached.osm", args_hash, [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0], [1, 1, 0, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0], [1, 2*5861.42, 48.88], 4)
  end
  
  def test_retrofit_replace_furnace
    args_hash = {}
    _test_measure("singlefamily_detached_fbsmt_furnace.osm", args_hash, [1, 1, 1, 0, 1, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0], [1, 1, 1, 0, 1, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0], [0.78, "AutoSize", 48.88], 7)
  end
  
  def test_retrofit_replace_ashp
    args_hash = {}
    _test_measure("singlefamily_detached_fbsmt_ashp.osm", args_hash, [1, 1, 0, 1, 1, 2, 1, 1, 0, 0, 0, 0, 0, 0, 0], [1, 1, 1, 0, 1, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0], [0.78, "AutoSize", 48.88], 7)
  end  
  
  def test_retrofit_replace_central_air_conditioner
    args_hash = {}
    _test_measure("singlefamily_detached_fbsmt_central_air_conditioner.osm", args_hash, [1, 1, 0, 0, 1, 2, 0, 1, 0, 0, 0, 0, 0, 0, 0], [1, 1, 1, 0, 1, 2, 0, 1, 0, 0, 0, 0, 0, 0, 0], [0.78, "AutoSize", 48.88], 7)
  end
  
  def test_retrofit_replace_room_air_conditioner
    args_hash = {}
    _test_measure("singlefamily_detached_fbsmt_room_air_conditioner.osm", args_hash, [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0], [1, 1, 1, 0, 1, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0], [0.78, "AutoSize", 48.88], 5)
  end
  
  def test_retrofit_replace_electric_baseboard
    args_hash = {}
    _test_measure("singlefamily_detached_fbsmt_electric_baseboard.osm", args_hash, [0, 0, 0, 0, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0], [1, 1, 1, 0, 1, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0], [0.78, "AutoSize", 48.88], 7)
  end
  
  def test_retrofit_replace_boiler
    args_hash = {}
    _test_measure("singlefamily_detached_fbsmt_boiler.osm", args_hash, [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 2, 0, 0], [1, 1, 1, 0, 1, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0], [0.78, "AutoSize", 48.88], 8)
  end
  
  def test_retrofit_replace_mshp
    args_hash = {}
    _test_measure("singlefamily_detached_fbsmt_mshp.osm", args_hash, [0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1], [1, 1, 1, 0, 1, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0], [0.78, "AutoSize", 48.88], 6)
  end
  
  def test_retrofit_replace_furnace_central_air_conditioner
    args_hash = {}
    _test_measure("singlefamily_detached_fbsmt_furnace_central_air_conditioner.osm", args_hash, [1, 1, 1, 0, 1, 2, 0, 1, 0, 0, 0, 0, 0, 0, 0], [1, 1, 1, 0, 1, 2, 0, 1, 0, 0, 0, 0, 0, 0, 0], [0.78, "AutoSize", 48.88], 8)
  end
  
  def test_retrofit_replace_furnace_room_air_conditioner
    args_hash = {}
    _test_measure("singlefamily_detached_fbsmt_furnace_room_air_conditioner.osm", args_hash, [1, 1, 1, 0, 1, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0], [1, 1, 1, 0, 1, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0], [0.78, "AutoSize", 48.88], 7)
  end  
  
  def test_retrofit_replace_electric_baseboard_central_air_conditioner
    args_hash = {}
    _test_measure("singlefamily_detached_fbsmt_electric_baseboard_central_air_conditioner.osm", args_hash, [1, 1, 0, 0, 1, 2, 0, 1, 0, 2, 0, 0, 0, 0, 0], [1, 1, 1, 0, 1, 2, 0, 1, 0, 0, 0, 0, 0, 0, 0], [0.78, "AutoSize", 48.88], 9)
  end  
  
  def test_retrofit_replace_boiler_central_air_conditioner
    args_hash = {}
    _test_measure("singlefamily_detached_fbsmt_boiler_central_air_conditioner.osm", args_hash, [1, 1, 0, 0, 1, 2, 0, 1, 0, 0, 1, 1, 2, 0, 0], [1, 1, 1, 0, 1, 2, 0, 1, 0, 0, 0, 0, 0, 0, 0], [0.78, "AutoSize", 48.88], 10)
  end  

  def test_retrofit_replace_electric_baseboard_room_air_conditioner
    args_hash = {}
    _test_measure("singlefamily_detached_fbsmt_electric_baseboard_room_air_conditioner.osm", args_hash, [0, 0, 0, 0, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0], [1, 1, 1, 0, 1, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0], [0.78, "AutoSize", 48.88], 7)
  end
  
  def test_retrofit_replace_boiler_room_air_conditioner
    args_hash = {}
    _test_measure("singlefamily_detached_fbsmt_boiler_room_air_conditioner.osm", args_hash, [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 2, 0, 0], [1, 1, 1, 0, 1, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0], [0.78, "AutoSize", 48.88], 8)
  end

  def test_multifamily_new_construction_1
    num_units = 4
    args_hash = {}
    _test_measure("singlefamily_attached_fbsmt_4_units.osm", args_hash, [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0], [num_units*1, num_units*1, num_units*1, 0, num_units*1, num_units*2, 0, 0, 0, 0, 0, 0, 0, 0, 0], [0.78, "AutoSize", 48.88], num_units*5)
  end

  def test_multifamily_new_construction_2
    num_units = 8
    args_hash = {}
    _test_measure("multifamily_8_units.osm", args_hash, [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0], [num_units*1, num_units*1, num_units*1, 0, num_units*1, num_units*1, 0, 0, 0, 0, 0, 0, 0, 0, 0], [0.78, "AutoSize", 48.88], num_units*3, 0)
  end  
  
  private
  
  def _test_measure(osm_file_or_model, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, num_infos=0, num_warnings=0, debug=false)
    # create an instance of the measure
    measure = ProcessFurnace.new

    # check for standard methods
    assert(!measure.name.empty?)
    assert(!measure.description.empty?)
    assert(!measure.modeler_description.empty?)

    # create an instance of a runner
    runner = OpenStudio::Ruleset::OSRunner.new
    
    model = _get_model(osm_file_or_model)

    # store the original equipment in the seed model
    orig_equips = [model.getAirLoopHVACUnitarySystems, model.getAirLoopHVACs, model.getCoilHeatingGass, model.getCoilHeatingElectrics, model.getFanOnOffs, model.getAirTerminalSingleDuctUncontrolleds, model.getCoilHeatingDXSingleSpeeds, model.getCoilCoolingDXSingleSpeeds, model.getZoneHVACPackagedTerminalAirConditioners, model.getZoneHVACBaseboardConvectiveElectrics, model.getPlantLoops, model.getBoilerHotWaters, model.getCoilHeatingWaterBaseboards, model.getAirConditionerVariableRefrigerantFlows, model.getZoneHVACTerminalUnitVariableRefrigerantFlows]
    
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
    
    [model.getAirLoopHVACUnitarySystems, model.getAirLoopHVACs, model.getCoilHeatingGass, model.getCoilHeatingElectrics, model.getFanOnOffs, model.getAirTerminalSingleDuctUncontrolleds, model.getCoilHeatingDXSingleSpeeds, model.getCoilCoolingDXSingleSpeeds, model.getZoneHVACPackagedTerminalAirConditioners, model.getZoneHVACBaseboardConvectiveElectrics, model.getPlantLoops, model.getBoilerHotWaters, model.getCoilHeatingWaterBaseboards, model.getAirConditionerVariableRefrigerantFlows, model.getZoneHVACTerminalUnitVariableRefrigerantFlows].each_with_index do |equip, i|
    
        # get new/deleted unitary system objects
        new_objects = []
        equip.each do |e|
            next if orig_equips[i].include?(e)
            new_objects << e
        end
        del_objects = []
        orig_equips[i].each do |e|
            next if equip.include?(e)
            del_objects << e
        end    
        # check for num new/del objects      
        assert_equal(expected_num_del_objects[i], del_objects.size)              
        assert_equal(expected_num_new_objects[i], new_objects.size)
        
        next if new_objects.empty?
        if i == 0 # check the unitary system
            new_objects.each do |new_object|
                assert_in_epsilon(expected_values[2], new_object.maximumSupplyAirTemperature.get, 0.01)
            end    
        elsif i == 2 # check the gas coil
            new_objects.each do |new_object|
                assert_in_epsilon(expected_values[0], new_object.gasBurnerEfficiency, 0.01)
                if new_object.nominalCapacity.is_initialized
                  assert_in_epsilon(expected_values[1], new_object.nominalCapacity.get, 0.01)
                end       
            end
        elsif i == 3 # check the electric coil
            new_objects.each do |new_object|
                assert_in_epsilon(expected_values[0], new_object.efficiency, 0.01)
                if new_object.nominalCapacity.is_initialized
                  assert_in_epsilon(expected_values[1], new_object.nominalCapacity.get, 0.01)
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

end
