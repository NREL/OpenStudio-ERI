require_relative '../../../test/minitest_helper'
require 'openstudio'
require 'openstudio/ruleset/ShowRunnerOutput'
require 'minitest/autorun'
require_relative '../measure.rb'
require 'fileutils'

class AirflowTest < MiniTest::Test
  
  def test_mech_vent_none
    args_hash = {}
    args_hash["selectedventtype"] = "none"
    result = _test_error("singlefamily_slab_location_beds_furnace_central_air_conditioner.osm", args_hash)
    assert(result.errors.size == 0)
    assert_equal("Success", result.value.valueName)    
  end
  
  def test_mech_vent_balanced
    args_hash = {}
    args_hash["selectedventtype"] = Constants.VentTypeBalanced
    result = _test_error("singlefamily_slab_location_beds_furnace_central_air_conditioner.osm", args_hash)
    assert(result.errors.size == 0)
    assert_equal("Success", result.value.valueName)    
  end  
  
  def test_garage
    args_hash = {}  
    result = _test_error("singlefamily_garage_location_beds_furnace_central_air_conditioner.osm", args_hash)
    assert(result.errors.size == 0)
    assert_equal("Success", result.value.valueName)    
  end
  
  def test_crawl
    args_hash = {}  
    result = _test_error("singlefamily_crawl_location_beds_furnace_central_air_conditioner.osm", args_hash)
    assert(result.errors.size == 0)
    assert_equal("Success", result.value.valueName)    
  end
  
  def test_ufbasement
    args_hash = {}  
    result = _test_error("singlefamily_ufbasement_location_beds_furnace_central_air_conditioner.osm", args_hash)
    assert(result.errors.size == 0)
    assert_equal("Success", result.value.valueName)    
  end
  
  def test_fbasement
    args_hash = {}  
    result = _test_error("singlefamily_fbasement_location_beds_furnace_central_air_conditioner.osm", args_hash)
    assert(result.errors.size == 0)
    assert_equal("Success", result.value.valueName)    
  end
  
  def test_duct_location_ufbasement
    args_hash = {}
    args_hash["duct_location"] = Constants.BasementZone
    result = _test_error("singlefamily_ufbasement_location_beds_furnace_central_air_conditioner.osm", args_hash)
    assert(result.errors.size == 0)
    assert_equal("Success", result.value.valueName)    
  end
  
  def test_duct_location_fbasement
    args_hash = {}
    args_hash["duct_location"] = Constants.BasementZone
    result = _test_error("singlefamily_fbasement_location_beds_furnace_central_air_conditioner.osm", args_hash)
    assert(result.errors.size == 0)
    assert_equal("Success", result.value.valueName)    
  end
  
  def test_duct_location_ufattic
    args_hash = {}
    args_hash["duct_location"] = Constants.AtticZone
    result = _test_error("singlefamily_slab_location_beds_furnace_central_air_conditioner.osm", args_hash)
    assert(result.errors.size == 0)
    assert_equal("Success", result.value.valueName)    
  end  
  
  def test_duct_location_basement_but_no_basement
    args_hash = {}
    args_hash["duct_location"] = Constants.BasementZone
    result = _test_error("singlefamily_slab_location_beds_furnace_central_air_conditioner.osm", args_hash)
    assert(result.errors.size == 1)
    assert_equal("Fail", result.value.valueName)    
    assert_equal(result.errors[0].logMessage, "Duct location is basement, but the building does not have a basement.")
  end   
  
  def test_duct_location_in_living
    args_hash = {}
    args_hash["duct_location"] = Constants.LivingZone
    result = _test_error("singlefamily_slab_location_beds_furnace_central_air_conditioner.osm", args_hash)
    assert(result.errors.size == 0)
    assert_equal("Success", result.value.valueName)
  end  
  
  def test_mshp # TODO: has_minisplit = false?
    args_hash = {}
    result = _test_error("singlefamily_slab_location_beds_mshp.osm", args_hash)
    assert(result.errors.size == 0)
    assert_equal("Success", result.value.valueName)
  end
  
  def test_duct_norm_leak_to_outside
    args_hash = {}
    args_hash["duct_norm_leakage_to_outside"] = "8.0"
    result = _test_error("singlefamily_slab_location_beds_furnace_central_air_conditioner.osm", args_hash)
    assert(result.errors.size == 1)
    assert_equal("Fail", result.value.valueName)
    assert_equal(result.errors[0].logMessage, "Duct leakage to outside was specified by we don't calculate fan air flow rate.")
  end
  
  def test_terrain_ocean
    args_hash = {}
    args_hash["selectedterraintype"] = Constants.TerrainOcean
    result = _test_error("singlefamily_slab_location_beds_furnace_central_air_conditioner.osm", args_hash)
    assert(result.errors.size == 0)
    assert_equal("Success", result.value.valueName)
  end
  
  def test_terrain_plains
    args_hash = {}
    args_hash["selectedterraintype"] = Constants.TerrainPlains
    result = _test_error("singlefamily_slab_location_beds_furnace_central_air_conditioner.osm", args_hash)
    assert(result.errors.size == 0)
    assert_equal("Success", result.value.valueName)
  end
  
  def test_terrain_rural
    args_hash = {}
    args_hash["selectedterraintype"] = Constants.TerrainRural
    result = _test_error("singlefamily_slab_location_beds_furnace_central_air_conditioner.osm", args_hash)
    assert(result.errors.size == 0)
    assert_equal("Success", result.value.valueName)
  end
  
  def test_terrain_city
    args_hash = {}
    args_hash["selectedterraintype"] = Constants.TerrainCity
    result = _test_error("singlefamily_slab_location_beds_furnace_central_air_conditioner.osm", args_hash)
    assert(result.errors.size == 0)
    assert_equal("Success", result.value.valueName)
  end
  
  private
  
  def _test_error(osm_file_or_model, args_hash)
    # create an instance of the measure
    measure = ProcessAirflow.new

    # check for standard methods
    assert(!measure.name.empty?)
    assert(!measure.description.empty?)
    assert(!measure.modeler_description.empty?)

    # create an instance of a runner
    runner = OpenStudio::Ruleset::OSRunner.new

    model = _get_model(osm_file_or_model)
    translator = OpenStudio::EnergyPlus::ForwardTranslator.new
    workspace = translator.translateModel(model)
    runner.setLastOpenStudioModel(model)
    
    # get arguments
    arguments = measure.arguments(workspace)
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
    measure.run(workspace, runner, argument_map)
    result = runner.result
      
    return result
    
  end
  
  def _test_measure(osm_file_or_model, args_hash, expected_infos)
    # create an instance of the measure
    measure = ProcessAirflow.new

    # check for standard methods
    assert(!measure.name.empty?)
    assert(!measure.description.empty?)
    assert(!measure.modeler_description.empty?)

    # create an instance of a runner
    runner = OpenStudio::Ruleset::OSRunner.new
    
    model = _get_model(osm_file_or_model)
    translator = OpenStudio::EnergyPlus::ForwardTranslator.new
    workspace = translator.translateModel(model)
    runner.setLastOpenStudioModel(model)

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
    expected_infos += ["Added heating coil 'Furnace Heating Coil' to branch 'Forced Air System' of air loop 'Central Air System'"]
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
