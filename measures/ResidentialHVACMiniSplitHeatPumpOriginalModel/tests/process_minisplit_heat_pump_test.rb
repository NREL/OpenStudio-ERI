require_relative '../../../test/minitest_helper'
require 'openstudio'
require 'openstudio/ruleset/ShowRunnerOutput'
require 'minitest/autorun'
require_relative '../measure.rb'
require 'fileutils'

class ProcessMinisplitTest < MiniTest::Test
  
  def test_hardsized_minisplit_heat_pump
    args_hash = {}
    args_hash["miniSplitCoolingOutputCapacity"] = "3.0 tons"
    result = _test_error("singlefamily_fbsmt_location.osm", args_hash)
    assert(result_errors(result).size == 0)
    assert_equal("Success", result_value(result))    
  end
  
  def test_branch_to_slave_zone
    args_hash = {}    
    result = _test_error("singlefamily_fbsmt_location.osm", args_hash)
    assert(result_errors(result).size == 0)
    assert_equal("Success", result_value(result))
  end
  
  def test_mf
    num_units = 3
    args_hash = {}
    result = _test_error("multifamily_3_units_location.osm", args_hash)
    assert(result_errors(result).size == 0)
    assert_equal("Success", result_value(result))
    assert_includes(result_infos(result), "Added air loop 'Central Air System_1' to thermal zone 'living zone 1' of unit 1")
    assert_includes(result_infos(result), "Added air loop 'Central Air System_1' to thermal zone 'finished basement zone 1' of unit 1")    
    (2..num_units).to_a.each do |unit_num|
      assert_includes(result_infos(result), "Added air loop 'Central Air System_#{unit_num}' to thermal zone 'living zone #{unit_num}' of unit #{unit_num}")
    end
  end
  
  def test_mf_urbanopt
    num_units = 8
    args_hash = {}
    result = _test_error("multifamily_urbanopt_location.osm", args_hash)
    assert(result_errors(result).size == 0)
    assert_equal("Success", result_value(result))
    assert_includes(result_infos(result), "Added air loop 'Central Air System_1' to thermal zone 'Building Story 0 ThermalZone' of unit 1")
    (2..5).to_a.each do |unit_num|
      assert_includes(result_infos(result), "Added air loop 'Central Air System_#{unit_num}' to thermal zone 'Building Story #{unit_num - 1} ThermalZone' of unit #{unit_num}")
    end
    assert_includes(result_infos(result), "Added air loop 'Central Air System_6' to thermal zone 'Building Story 1 ThermalZone' of unit 6")
    assert_includes(result_infos(result), "Added air loop 'Central Air System_7' to thermal zone 'Building Story 2 ThermalZone' of unit 7")
    assert_includes(result_infos(result), "Added air loop 'Central Air System_8' to thermal zone 'Building Story 3 ThermalZone' of unit 8")
  end    
  
  private
  
  def _test_error(osm_file, args_hash)
    # create an instance of the measure
    measure = ProcessMinisplit.new

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
    measure = ProcessMinisplit.new

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
    assert_equal("Success", result_value(result))
    expected_infos += ["Added DX heating coil 'DX Heating Coil' to branch 'Forced Air System' of air loop 'Central Air System_1'", "Added DX cooling coil 'DX Cooling Coil' to branch 'Forced Air System' of air loop 'Central Air System_1'"]
    expected_infos.each do |expected_info|
      assert_includes(result_infos(result), expected_info)
    end   

    return model
  end  
  
end
