require_relative '../../../test/minitest_helper'
require 'openstudio'
require 'openstudio/ruleset/ShowRunnerOutput'
require 'minitest/autorun'
require_relative '../measure.rb'
require 'fileutils'

class ProcessMiniSplitHeatPumpTest < MiniTest::Test 
  
 def test_hardsized_minisplit_heat_pump
    args_hash = {}
    args_hash["miniSplitCoolingOutputCapacity"] = "3.0 tons"
    result = _test_error("singlefamily_fbsmt_location.osm", args_hash)
    assert(result.errors.size == 0)
    assert_equal("Success", result.value.valueName)    
  end
  
  def test_no_supp_heat
    args_hash = {}
    args_hash["miniSplitSupplementalHeatingOutputCapacity"] = "NO SUPP HEAT"
    result = _test_error("singlefamily_fbsmt_location.osm", args_hash)
    assert(result.errors.size == 0)
    assert_equal("Success", result.value.valueName)    
  end
  
  def test_hardsized_supp_heat
    args_hash = {}
    args_hash["miniSplitSupplementalHeatingOutputCapacity"] = "20 kBtu/hr"
    result = _test_error("singlefamily_fbsmt_location.osm", args_hash)
    assert(result.errors.size == 0)
    assert_equal("Success", result.value.valueName)    
  end
  
  def test_branch_to_slave_zone
    args_hash = {}    
    result = _test_error("singlefamily_fbsmt_location.osm", args_hash)
    assert(result.errors.size == 0)
    assert_equal("Success", result.value.valueName)
  end
  
  def test_retrofit_replace_ashp
    args_hash = {}
    _test_measure("singlefamily_fbsmt_location_ashp.osm", args_hash, ["Removed 'DX Cooling Coil' and 'DX Heating Coil' from air loop 'Central Air System_1'", "Removed air loop 'Central Air System_1'"])
  end
  
  def test_retrofit_replace_furnace
    args_hash = {}
    _test_measure("singlefamily_fbsmt_location_furnace.osm", args_hash, ["Removed 'Furnace Heating Coil' from air loop 'Central Air System_1'", "Removed air loop 'Central Air System_1'"])
  end
  
  def test_retrofit_replace_central_air_conditioner
    args_hash = {}
    _test_measure("singlefamily_fbsmt_location_central_air_conditioner.osm", args_hash, ["Removed 'DX Cooling Coil' from air loop 'Central Air System_1'", "Removed air loop 'Central Air System_1'"])
  end
  
  def test_retrofit_replace_room_air_conditioner
    args_hash = {}
    _test_measure("singlefamily_fbsmt_location_room_air_conditioner.osm", args_hash, ["Removed packaged terminal air conditioner 'Window AC'"])
  end
  
  def test_retrofit_replace_electric_baseboard
    args_hash = {}
    _test_measure("singlefamily_fbsmt_location_electric_baseboard.osm", args_hash, ["Removed baseboard convective electric 'Living Zone Electric Baseboards'"])
  end
  
  def test_retrofit_replace_boiler
    args_hash = {}
    _test_measure("singlefamily_fbsmt_location_boiler.osm", args_hash, ["Removed plant loop 'Hydronic Heat Loop'", "Removed baseboard convective water 'Living Zone Baseboards'"])
  end
  
  def test_retrofit_replace_mshp
    args_hash = {}
    _test_measure("singlefamily_fbsmt_location_mshp.osm", args_hash, ["Removed variable refrigerant flow terminal unit 'Indoor Unit_1'"])
  end
  
  def test_retrofit_replace_furnace_central_air_conditioner
    args_hash = {}
    _test_measure("singlefamily_fbsmt_location_furnace_central_air_conditioner.osm", args_hash, ["Removed 'Furnace Heating Coil 1' from air loop 'Central Air System_1'", "Removed 'DX Cooling Coil' from air loop 'Central Air System_1'", "Removed air loop 'Central Air System_1'"])
  end
  
  def test_retrofit_replace_furnace_room_air_conditioner
    args_hash = {}
    _test_measure("singlefamily_fbsmt_location_furnace_room_air_conditioner.osm", args_hash, ["Removed 'Furnace Heating Coil' from air loop 'Central Air System_1'", "Removed packaged terminal air conditioner 'Window AC'", "Removed air loop 'Central Air System_1'"])
  end    
  
  def test_retrofit_replace_electric_baseboard_central_air_conditioner
    args_hash = {}
    _test_measure("singlefamily_fbsmt_location_electric_baseboard_central_air_conditioner.osm", args_hash, ["Removed baseboard convective electric 'Living Zone Electric Baseboards'", "Removed 'DX Cooling Coil' from air loop 'Central Air System_1'", "Removed air loop 'Central Air System_1'"])
  end

  def test_retrofit_replace_boiler_central_air_conditioner
    args_hash = {}
    _test_measure("singlefamily_fbsmt_location_boiler_central_air_conditioner.osm", args_hash, ["Removed plant loop 'Hydronic Heat Loop'", "Removed baseboard convective water 'Living Zone Baseboards'", "Removed 'DX Cooling Coil' from air loop 'Central Air System_1'", "Removed air loop 'Central Air System_1'"])
  end
  
  def test_retrofit_replace_electric_baseboard_room_air_conditioner
    args_hash = {}
    _test_measure("singlefamily_fbsmt_location_electric_baseboard_room_air_conditioner.osm", args_hash, ["Removed baseboard convective electric 'Living Zone Electric Baseboards'", "Removed packaged terminal air conditioner 'Window AC'"])
  end

  def test_retrofit_replace_boiler_room_air_conditioner
    args_hash = {}
    _test_measure("singlefamily_fbsmt_location_boiler_room_air_conditioner.osm", args_hash, ["Removed plant loop 'Hydronic Heat Loop'", "Removed baseboard convective water 'Living Zone Baseboards'", "Removed packaged terminal air conditioner 'Window AC'"])
  end
  
  def test_mf
    num_units = 3
    args_hash = {}
    result = _test_error("multifamily_3_units_location.osm", args_hash)
    assert(result.errors.size == 0)
    assert_equal("Success", result.value.valueName)
    assert_includes(result.info.map{ |x| x.logMessage }, "Added variable refrigerant flow terminal unit 'Indoor Unit_1' to thermal zone 'living zone 1' of unit 1")
    (2..num_units).to_a.each do |unit_num|
      assert_includes(result.info.map{ |x| x.logMessage }, "Added variable refrigerant flow terminal unit 'Indoor Unit_#{unit_num}' to thermal zone 'living zone #{unit_num}' of unit #{unit_num}")
    end
  end
  
  def test_mf_urbanopt
    num_units = 8
    args_hash = {}
    result = _test_error("multifamily_urbanopt_location.osm", args_hash)
    assert(result.errors.size == 0)
    assert_equal("Success", result.value.valueName)
    assert_includes(result.info.map{ |x| x.logMessage }, "Added variable refrigerant flow terminal unit 'Indoor Unit_1' to thermal zone 'Building Story 0 ThermalZone' of unit 1")
    (2..5).to_a.each do |unit_num|
      assert_includes(result.info.map{ |x| x.logMessage }, "Added variable refrigerant flow terminal unit 'Indoor Unit_#{unit_num}' to thermal zone 'Building Story #{unit_num - 1} ThermalZone' of unit #{unit_num}")
    end
    assert_includes(result.info.map{ |x| x.logMessage }, "Added variable refrigerant flow terminal unit 'Indoor Unit_6' to thermal zone 'Building Story 1 ThermalZone' of unit 6")
    assert_includes(result.info.map{ |x| x.logMessage }, "Added variable refrigerant flow terminal unit 'Indoor Unit_7' to thermal zone 'Building Story 2 ThermalZone' of unit 7")
    assert_includes(result.info.map{ |x| x.logMessage }, "Added variable refrigerant flow terminal unit 'Indoor Unit_8' to thermal zone 'Building Story 3 ThermalZone' of unit 8")
  end
  
  private
  
  def _test_error(osm_file, args_hash)
    # create an instance of the measure
    measure = ProcessVRFMinisplit.new

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
  
  def _test_measure(osm_file_or_model, args_hash, expected_infos)
    # create an instance of the measure
    measure = ProcessVRFMinisplit.new

    # check for standard methods
    assert(!measure.name.empty?)
    assert(!measure.description.empty?)
    assert(!measure.modeler_description.empty?)

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

    # assert that it ran correctly
    assert_equal("Success", result.value.valueName)
    expected_infos += ["Added variable refrigerant flow terminal unit 'Indoor Unit_1' to thermal zone 'living zone' of unit 1"]
    expected_infos.each do |expected_info|
      assert_includes(result.info.map{ |x| x.logMessage }, expected_info)
    end   

    return model
  end  
  
end
