require_relative '../../../test/minitest_helper'
require 'openstudio'
require 'openstudio/ruleset/ShowRunnerOutput'
require 'minitest/autorun'
require_relative '../measure.rb'
require 'fileutils'

class ProcessBoilerTest < MiniTest::Test
  
  def test_error_steam_boiler
    args_hash = {}
    args_hash["boilerType"] = Constants.BoilerTypeSteam
    result = _test_error("default_geometry_location.osm", args_hash)
    assert(result.errors.size == 1)
    assert_equal("Fail", result.value.valueName)
    assert_equal(result.errors[0].logMessage, "Cannot currently model steam boilers.")    
  end  
  
  def test_oat_reset_enabled_nil_oat
    args_hash = {}
    args_hash["boilerType"] = Constants.BoilerTypeCondensing
    args_hash["boilerOATResetEnabled"] = true
    result = _test_error("default_geometry_location.osm", args_hash)
    assert(result.errors.size == 0)
    assert_equal("Success", result.value.valueName)
  end
  
  def test_condensing_boiler_oat_reset_enabled
    args_hash = {}
    args_hash["boilerType"] = Constants.BoilerTypeCondensing
    args_hash["boilerOATResetEnabled"] = true
    args_hash["boilerOATLow"] = 0.0
    args_hash["boilerOATLowHWST"] = 180.0
    args_hash["boilerOATHigh"] = 68.0
    args_hash["boilerOATHighHWST"] = 95.0
    result = _test_error("default_geometry_location.osm", args_hash)
    assert(result.errors.size == 0)
    assert_equal("Success", result.value.valueName)
  end
  
  def test_branch_to_slave_zone_hardsized_boiler
    args_hash = {}
    args_hash["boilerOutputCapacity"] = "20 kBtu/hr"
    result = _test_error("finished_basement_geometry_location.osm", args_hash)
    assert(result.errors.size == 0)
    assert_equal("Success", result.value.valueName)    
  end
    
  def test_retrofit_replace_ashp
    args_hash = {}
    _test_measure("default_geometry_location_ashp.osm", args_hash, ["Removed 'DX Cooling Coil' and 'DX Heating Coil' from air loop 'Central Air System'", "Removed air loop 'Central Air System'"])
  end
  
  def test_retrofit_replace_furnace
    args_hash = {}
    _test_measure("default_geometry_location_furnace.osm", args_hash, ["Removed 'Furnace Heating Coil' from air loop 'Central Air System'", "Removed air loop 'Central Air System'"])
  end
  
  def test_retrofit_replace_central_air_conditioner
    args_hash = {}
    _test_measure("default_geometry_location_central_air_conditioner.osm", args_hash, [])
  end
  
  def test_retrofit_replace_room_air_conditioner
    args_hash = {}
    _test_measure("default_geometry_location_room_air_conditioner.osm", args_hash, [])
  end  
  
  def test_retrofit_replace_electric_baseboard
    args_hash = {}
    _test_measure("default_geometry_location_electric_baseboard.osm", args_hash, ["Removed 'Living Zone Electric Baseboards'"])
  end
  
  def test_retrofit_replace_boiler
    args_hash = {}
    _test_measure("default_geometry_location_boiler.osm", args_hash, ["Removed plant loop 'Hydronic Heat Loop'", "Removed 'Living Zone Baseboards'"])
  end
  
  def test_retrofit_replace_mshp
    args_hash = {}
    _test_measure("default_geometry_location_mshp.osm", args_hash, ["Removed 'DX Cooling Coil' and 'DX Heating Coil' from air loop 'Central Air System'", "Removed air loop 'Central Air System'"])
  end
  
  def test_retrofit_replace_furnace_central_air_conditioner
    args_hash = {}
    _test_measure("default_geometry_location_furnace_central_air_conditioner.osm", args_hash, ["Removed 'Furnace Heating Coil 1' from air loop 'Central Air System'"])
  end
  
  def test_retrofit_replace_furnace_room_air_conditioner
    args_hash = {}
    _test_measure("default_geometry_location_furnace_room_air_conditioner.osm", args_hash, ["Removed 'Furnace Heating Coil' from air loop 'Central Air System'"])
  end    
  
  def test_retrofit_replace_electric_baseboard_central_air_conditioner
    args_hash = {}
    _test_measure("default_geometry_location_electric_baseboard_central_air_conditioner.osm", args_hash, ["Removed 'Living Zone Electric Baseboards'"])
  end

  def test_retrofit_replace_boiler_central_air_conditioner
    args_hash = {}
    _test_measure("default_geometry_location_boiler_central_air_conditioner.osm", args_hash, ["Removed plant loop 'Hydronic Heat Loop'", "Removed 'Living Zone Baseboards'"])
  end
  
  def test_retrofit_replace_electric_baseboard_room_air_conditioner
    args_hash = {}
    _test_measure("default_geometry_location_electric_baseboard_room_air_conditioner.osm", args_hash, ["Removed 'Living Zone Electric Baseboards'"])
  end

  def test_retrofit_replace_boiler_room_air_conditioner
    args_hash = {}
    _test_measure("default_geometry_location_boiler_room_air_conditioner.osm", args_hash, ["Removed plant loop 'Hydronic Heat Loop'", "Removed 'Living Zone Baseboards'"])
  end  
  
  private
  
  def _test_error(osm_file, args_hash)
    # create an instance of the measure
    measure = ProcessBoiler.new

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
  
  def _test_measure(osm_file_or_model, args_hash, expected_infos)
    # create an instance of the measure
    measure = ProcessBoiler.new

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
    expected_infos += ["Added baseboard convective water 'Living Zone Baseboards' to thermal zone 'living zone'"]
    expected_infos.each do |expected_info|
      assert_includes(result.info.map{ |x| x.logMessage }, expected_info)
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
