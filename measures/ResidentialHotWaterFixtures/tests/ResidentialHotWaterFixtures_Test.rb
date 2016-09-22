require_relative '../../../test/minitest_helper'
require 'openstudio'
require 'openstudio/ruleset/ShowRunnerOutput'
require 'minitest/autorun'
require_relative '../measure.rb'
require 'fileutils'

class ResidentialHotWaterFixturesTest < MiniTest::Test

  def osm_geo
    return "2000sqft_2story_FB_GRG_UA.osm"
  end

  def osm_geo_beds
    return "2000sqft_2story_FB_GRG_UA_3Beds_2Baths.osm"
  end

  def osm_geo_beds_loc_tankwh
    return "2000sqft_2story_FB_GRG_UA_3Beds_2Baths_Denver_ElecWHtank.osm"
  end

  def osm_geo_multifamily_3_units_beds_loc_tankwh
    return "multifamily_3_units_Beds_Baths_Denver_ElecWHtank.osm"
  end
  
  def osm_geo_multifamily_12_units_beds_loc_tankwh
    return "multifamily_12_units_Beds_Baths_Denver_ElecWHtank.osm"
  end

  def test_new_construction_none
    # Using energy multiplier
    args_hash = {}
    args_hash["shower_mult"] = 0.0
    args_hash["sink_mult"] = 0.0
    args_hash["bath_mult"] = 0.0
    _test_measure(osm_geo_beds_loc_tankwh, args_hash, 0, 0, 0.0, 0.0)
  end
  
  def test_new_construction_standard
    args_hash = {}
    _test_measure(osm_geo_beds_loc_tankwh, args_hash, 0, 6, 445.1, 60)
  end
  
  def test_new_construction_varying_mults
    args_hash = {}
    args_hash["shower_mult"] = 0.0
    args_hash["sink_mult"] = 0.5
    args_hash["bath_mult"] = 1.5
    _test_measure(osm_geo_beds_loc_tankwh, args_hash, 0, 4, 107.7, 23)
  end
  
  def test_new_construction_basement
    args_hash = {}
    args_hash["space"] = Constants.FinishedBasementSpace
    _test_measure(osm_geo_beds_loc_tankwh, args_hash, 0, 6, 445.1, 60)
  end

  def test_retrofit_replace
    args_hash = {}
    model = _test_measure(osm_geo_beds_loc_tankwh, args_hash, 0, 6, 445.1, 60)
    args_hash = {}
    args_hash["shower_mult"] = 0.0
    args_hash["sink_mult"] = 0.5
    args_hash["bath_mult"] = 1.5
    _test_measure(model, args_hash, 6, 4, 107.7, 23, 1)
  end
    
  def test_retrofit_remove
    args_hash = {}
    model = _test_measure(osm_geo_beds_loc_tankwh, args_hash, 0, 6, 445.1, 60)
    args_hash = {}
    args_hash["shower_mult"] = 0.0
    args_hash["sink_mult"] = 0.0
    args_hash["bath_mult"] = 0.0
    _test_measure(model, args_hash, 6, 0, 0.0, 0.0, 1)
  end
  
  def test_multifamily_new_construction
    num_units = 3
    args_hash = {}
    _test_measure(osm_geo_multifamily_3_units_beds_loc_tankwh, args_hash, 0, 6*num_units, 1261.1, 170.1, num_units)
  end
  
  def test_multifamily_new_construction_finished_basement
    args_hash = {}
    args_hash["space"] = "finishedbasement_1"
    _test_measure(osm_geo_multifamily_3_units_beds_loc_tankwh, args_hash, 0, 6, 445.1, 60)
  end
  
  def test_multifamily_new_construction_mult_draw_profiles
    num_units = 12
    args_hash = {}
    _test_measure(osm_geo_multifamily_12_units_beds_loc_tankwh, args_hash, 0, 6*num_units, 5341.2, 720, num_units)
  end

  def test_multifamily_retrofit_replace
    num_units = 3
    args_hash = {}
    model = _test_measure(osm_geo_multifamily_3_units_beds_loc_tankwh, args_hash, 0, 6*num_units, 1261.1, 170.1, num_units)
    args_hash = {}
    args_hash["shower_mult"] = 0.0
    args_hash["sink_mult"] = 0.5
    args_hash["bath_mult"] = 1.5
    _test_measure(model, args_hash, 6*num_units, 4*num_units, 305.0, 65.1, 2*num_units)
  end
  
  def test_multifamily_retrofit_remove
    num_units = 3
    args_hash = {}
    model = _test_measure(osm_geo_multifamily_3_units_beds_loc_tankwh, args_hash, 0, 6*num_units, 1261.1, 170.1, num_units)
    args_hash = {}
    args_hash["shower_mult"] = 0.0
    args_hash["sink_mult"] = 0.0
    args_hash["bath_mult"] = 0.0
    _test_measure(model, args_hash, 6*num_units, 0, 0.0, 0.0, num_units)
  end
  
  def test_argument_error_shower_mult_negative
    args_hash = {}
    args_hash["shower_mult"] = -1
    result = _test_error(osm_geo_beds_loc_tankwh, args_hash)
    assert_equal(result.errors[0].logMessage, "Shower hot water usage multiplier must be greater than or equal to 0.")
  end

  def test_argument_error_sink_mult_negative
    args_hash = {}
    args_hash["sink_mult"] = -1
    result = _test_error(osm_geo_beds_loc_tankwh, args_hash)
    assert_equal(result.errors[0].logMessage, "Sink hot water usage multiplier must be greater than or equal to 0.")
  end

  def test_argument_error_bath_mult_negative
    args_hash = {}
    args_hash["bath_mult"] = -1
    result = _test_error(osm_geo_beds_loc_tankwh, args_hash)
    assert_equal(result.errors[0].logMessage, "Bath hot water usage multiplier must be greater than or equal to 0.")
  end

  def test_error_missing_geometry
    args_hash = {}
    result = _test_error(nil, args_hash)
    assert_equal(result.errors[0].logMessage, "Cannot determine number of building units; Building::standardsNumberOfLivingUnits has not been set.")
  end
  
  def test_error_missing_beds
    args_hash = {}
    result = _test_error(osm_geo, args_hash)
    assert_equal(result.errors[0].logMessage, "Could not determine number of bedrooms or bathrooms. Run the 'Add Residential Bedrooms And Bathrooms' measure first.")
  end
  
  def test_error_missing_water_heater
    args_hash = {}
    result = _test_error(osm_geo_beds, args_hash)
    assert_equal(result.errors[0].logMessage, "Could not find plant loop.")
  end

  private
  
  def _test_error(osm_file, args_hash)
    # create an instance of the measure
    measure = ResidentialHotWaterFixtures.new
    
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

  def _test_measure(osm_file_or_model, args_hash, expected_num_del_objects, expected_num_new_objects, expected_annual_kwh, expected_hw_gpd, num_infos=0, num_warnings=0)
    # create an instance of the measure
    measure = ResidentialHotWaterFixtures.new

    # check for standard methods
    assert(!measure.name.empty?)
    assert(!measure.description.empty?)
    assert(!measure.modeler_description.empty?)

    # create an instance of a runner
    runner = OpenStudio::Ruleset::OSRunner.new
    
    model = _get_model(osm_file_or_model)

    # store the original equipment in the seed model
    orig_equip = model.getOtherEquipments + model.getWaterUseEquipments

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

    # assert that it ran correctly
    assert_equal("Success", result.value.valueName)
    assert(result.info.size == num_infos)
    assert(result.warnings.size == num_warnings)
    assert(result.finalCondition.is_initialized)
    
    # get new/deleted other equipment objects
    new_objects = []
    (model.getOtherEquipments + model.getWaterUseEquipments).each do |equip|
        next if orig_equip.include?(equip)
        new_objects << equip
    end
    del_objects = []
    orig_equip.each do |equip|
        next if (model.getOtherEquipments + model.getWaterUseEquipments).include?(equip)
        del_objects << equip
    end
    
    # check for num new/del objects
    assert_equal(expected_num_del_objects, del_objects.size)
    assert_equal(expected_num_new_objects, new_objects.size)
    
    actual_annual_kwh = 0.0
    actual_hw_gpd = 0.0
    new_objects.each do |new_object|
        # check that the new object has the correct name
        assert((new_object.name.to_s.start_with?(Constants.ObjectNameShower) or new_object.name.to_s.start_with?(Constants.ObjectNameSink) or new_object.name.to_s.start_with?(Constants.ObjectNameBath)))
    
        # check new object is in correct space
        if argument_map["space"].hasValue
            assert_equal(new_object.space.get.name.to_s, argument_map["space"].valueAsString)
        end
        
        if new_object.is_a?(OpenStudio::Model::OtherEquipment)
            # check for the correct annual energy consumption
            full_load_hrs = Schedule.annual_equivalent_full_load_hrs(model, new_object.schedule.get)
            actual_annual_kwh += OpenStudio.convert(full_load_hrs * new_object.otherEquipmentDefinition.designLevel.get * new_object.multiplier, "Wh", "kWh").get
        elsif new_object.is_a?(OpenStudio::Model::WaterUseEquipment)
            # check for the correct daily hot water consumption
            full_load_hrs = Schedule.annual_equivalent_full_load_hrs(model, new_object.flowRateFractionSchedule.get)
            actual_hw_gpd += OpenStudio.convert(full_load_hrs * new_object.waterUseEquipmentDefinition.peakFlowRate * new_object.multiplier, "m^3/s", "gal/min").get * 60.0 / 365.0
        end
    end
    assert_in_epsilon(expected_annual_kwh, actual_annual_kwh, 0.01)
    assert_in_epsilon(expected_hw_gpd, actual_hw_gpd, 0.02)

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
