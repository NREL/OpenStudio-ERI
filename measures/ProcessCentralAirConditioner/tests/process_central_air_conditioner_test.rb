require_relative '../../../test/minitest_helper'
require 'openstudio'
require 'openstudio/ruleset/ShowRunnerOutput'
require 'minitest/autorun'
require_relative '../measure.rb'
require 'fileutils'

class ProcessCentralAirConditionerTest < MiniTest::Test
  
  def test_error_invalid_compressor_speeds
    args_hash = {}
    args_hash["acNumberSpeeds"] = 3
    result = _test_error("default_geometry_location.osm", args_hash)
    assert(result.errors.size == 1)
    assert_equal("Fail", result.value.valueName)
    assert_equal(result.errors[0].logMessage, "Invalid number of compressor speeds entered.")
  end
  
  def test_error_wrong_lengths_given_compressor_speeds
    args_hash = {}
    args_hash["acCoolingEER"] = "11.1, 11.1"
    result = _test_error("default_geometry_location.osm", args_hash)
    assert(result.errors.size == 1)
    assert_equal("Fail", result.value.valueName)
    assert_equal(result.errors[0].logMessage, "Entered wrong length for EER, Rated SHR, Capacity Ratio, or Fan Speed Ratio given the Number of Speeds.")
  end 
  
  def test_existing_furnace
    args_hash = {}    
    result = _test_error("default_geometry_location_gas_furnace.osm", args_hash)
    assert(result.errors.size == 0)
    assert_equal("Success", result.value.valueName)    
  end  
  
  def test_multi_speed_central_air_conditioner
    args_hash = {}
    args_hash["acNumberSpeeds"] = 2
    args_hash["acCoolingEER"] = "13.5, 12.4"
    args_hash["acSHRRated"] = "0.71, 0.73"
    args_hash["acCapacityRatio"] = "0.72, 1.0"
    args_hash["acFanspeedRatio"] = "0.86, 1.0"
    result = _test_error("default_geometry_location.osm", args_hash)
    assert(result.errors.size == 0)
    assert_equal("Success", result.value.valueName)    
  end
  
  def test_existing_gas_furnace_multi_speed_central_air_conditioner
    args_hash = {}
    args_hash["acNumberSpeeds"] = 2
    args_hash["acCoolingEER"] = "13.5, 12.4"
    args_hash["acSHRRated"] = "0.71, 0.73"
    args_hash["acCapacityRatio"] = "0.72, 1.0"
    args_hash["acFanspeedRatio"] = "0.86, 1.0"
    result = _test_error("default_geometry_location_gas_furnace.osm", args_hash)
    assert(result.errors.size == 0)
    assert_equal("Success", result.value.valueName)    
  end
  
  def test_existing_hardsized_gas_furnace_multi_speed_central_air_conditioner
    args_hash = {}
    args_hash["acNumberSpeeds"] = 2
    args_hash["acCoolingEER"] = "13.5, 12.4"
    args_hash["acSHRRated"] = "0.71, 0.73"
    args_hash["acCapacityRatio"] = "0.72, 1.0"
    args_hash["acFanspeedRatio"] = "0.86, 1.0"
    result = _test_error("default_geometry_location_hardsized_gas_furnace.osm", args_hash)
    assert(result.errors.size == 0)
    assert_equal("Success", result.value.valueName)    
  end

    def test_existing_electric_furnace_multi_speed_central_air_conditioner
    args_hash = {}
    args_hash["acNumberSpeeds"] = 2
    args_hash["acCoolingEER"] = "13.5, 12.4"
    args_hash["acSHRRated"] = "0.71, 0.73"
    args_hash["acCapacityRatio"] = "0.72, 1.0"
    args_hash["acFanspeedRatio"] = "0.86, 1.0"
    result = _test_error("default_geometry_location_electric_furnace.osm", args_hash)
    assert(result.errors.size == 0)
    assert_equal("Success", result.value.valueName)    
  end
  
  def test_existing_hardsized_electric_furnace_multi_speed_central_air_conditioner
    args_hash = {}
    args_hash["acNumberSpeeds"] = 2
    args_hash["acCoolingEER"] = "13.5, 12.4"
    args_hash["acSHRRated"] = "0.71, 0.73"
    args_hash["acCapacityRatio"] = "0.72, 1.0"
    args_hash["acFanspeedRatio"] = "0.86, 1.0"
    result = _test_error("default_geometry_location_hardsized_electric_furnace.osm", args_hash)
    assert(result.errors.size == 0)
    assert_equal("Success", result.value.valueName)    
  end
  
  def test_hardsized_evaporatively_cooled_unit
    args_hash = {}
    args_hash["acCoolingOutputCapacity"] = "3.0 tons"
    args_hash["acCondenserType"] = "evaporativelycooled"
    result = _test_error("default_geometry_location.osm", args_hash)
    assert(result.errors.size == 0)
    assert_equal("Success", result.value.valueName)    
  end
  
  def test_hardsized_has_ideal_ac
    args_hash = {}
    args_hash["acCoolingInstalledSEER"] = 999
    args_hash["acCoolingOutputCapacity"] = "3.0 tons"
    result = _test_error("default_geometry_location.osm", args_hash)
    assert(result.errors.size == 0)
    assert_equal("Success", result.value.valueName)    
  end
  
  def test_branch_to_slave_zone
    args_hash = {}    
    result = _test_error("finished_basement_geometry_location.osm", args_hash)
    assert(result.errors.size == 0)
    assert_equal("Success", result.value.valueName)
  end
    
  def test_retrofit_replace
    args_hash = {}
    model = _test_measure("default_geometry_location.osm", args_hash, 1, 0)
    args_hash = {}
    _test_measure(model, args_hash, 1, 1)
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
      
    return result
    
  end
  
  def _test_measure(osm_file_or_model, args_hash, expected_num_new_coils=0, expected_num_existing_coils=0)
    # create an instance of the measure
    measure = ProcessCentralAirConditioner.new

    # check for standard methods
    assert(!measure.name.empty?)
    assert(!measure.description.empty?)
    assert(!measure.modeler_description.empty?)

    # create an instance of a runner
    runner = OpenStudio::Ruleset::OSRunner.new
    
    model = _get_model(osm_file_or_model)

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
    new_coil = false
    existing_coil = false
    result.info.each do |info|
        if info.logMessage.include? "Added DX cooling coil 'DX Cooling Coil' to branch 'Forced Air System' of air loop 'Central Air System'"
            new_coil = true
        elsif info.logMessage.include? "Removed 'DX Cooling Coil' (Central Air Conditioner) from air loop 'Central Air System'"
            existing_coil = true
        end
    end    
    if expected_num_existing_coils == 0 # new
        assert(new_coil==true)
        assert(existing_coil==false)
    else # replacement
        assert(new_coil==true)
        assert(existing_coil==true)
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
