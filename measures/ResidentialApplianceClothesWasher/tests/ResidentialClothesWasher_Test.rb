require_relative '../../../test/minitest_helper'
require 'openstudio'
require 'openstudio/ruleset/ShowRunnerOutput'
require 'minitest/autorun'
require_relative '../measure.rb'
require 'fileutils'

class ResidentialClothesWasherTest < MiniTest::Test

  def osm_geo_beds
    return "2000sqft_2story_FB_GRG_UA_3Beds_2Baths.osm"
  end

  def osm_geo_loc
    return "2000sqft_2story_FB_GRG_UA_Denver.osm"
  end

  def osm_geo_beds_loc
    return "2000sqft_2story_FB_GRG_UA_3Beds_2Baths_Denver.osm"
  end

  def osm_geo_beds_loc_tankwh
    return "2000sqft_2story_FB_GRG_UA_3Beds_2Baths_Denver_ElecWHtank.osm"
  end

  def osm_geo_beds_loc_tanklesswh
    return "2000sqft_2story_FB_GRG_UA_3Beds_2Baths_Denver_ElecWHtankless.osm"
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
    args_hash["cw_mult_e"] = 0.0
    args_hash["cw_mult_hw"] = 0.0
    expected_num_del_objects = {}
    expected_num_new_objects = {}
    expected_values = {"Annual_kwh"=>0, "HotWater_gpd"=>0}
    _test_measure(osm_geo_beds_loc_tankwh, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)
  end
  
  def test_new_construction_standard
    args_hash = {}
    args_hash["cw_mef"] = 1.41
    args_hash["cw_rated_annual_energy"] = 387
    expected_num_del_objects = {}
    expected_num_new_objects = {"ElectricEquipmentDefinition"=>1, "ElectricEquipment"=>1, "WaterUseEquipmentDefinition"=>1, "WaterUseEquipment"=>1, "ScheduleFixedInterval"=>1, "ScheduleConstant"=>1}
    expected_values = {"Annual_kwh"=>42.9, "HotWater_gpd"=>10.00}
    _test_measure(osm_geo_beds_loc_tankwh, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)
  end
  
  def test_new_construction_energystar
    args_hash = {}
    args_hash["cw_mef"] = 2.47
    args_hash["cw_rated_annual_energy"] = 123
    args_hash["cw_annual_cost"] = 9.0
    args_hash["cw_drum_volume"] = 3.68
    expected_num_del_objects = {}
    expected_num_new_objects = {"ElectricEquipmentDefinition"=>1, "ElectricEquipment"=>1, "WaterUseEquipmentDefinition"=>1, "WaterUseEquipment"=>1, "ScheduleFixedInterval"=>1, "ScheduleConstant"=>1}
    expected_values = {"Annual_kwh"=>34.9, "HotWater_gpd"=>2.27}
    _test_measure(osm_geo_beds_loc_tankwh, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)
  end
  
  def test_new_construction_standard_2003
    args_hash = {}
    args_hash["cw_mef"] = 1.41
    args_hash["cw_rated_annual_energy"] = 387
    args_hash["cw_test_date"] = 2003
    expected_num_del_objects = {}
    expected_num_new_objects = {"ElectricEquipmentDefinition"=>1, "ElectricEquipment"=>1, "WaterUseEquipmentDefinition"=>1, "WaterUseEquipment"=>1, "ScheduleFixedInterval"=>1, "ScheduleConstant"=>1}
    expected_values = {"Annual_kwh"=>176.0, "HotWater_gpd"=>4.80}
    _test_measure(osm_geo_beds_loc_tankwh, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)
  end

  def test_new_construction_standard_mult_0_80
    args_hash = {}
    args_hash["cw_mef"] = 1.41
    args_hash["cw_rated_annual_energy"] = 387
    args_hash["cw_mult_e"] = 0.8
    args_hash["cw_mult_hw"] = 0.8
    expected_num_del_objects = {}
    expected_num_new_objects = {"ElectricEquipmentDefinition"=>1, "ElectricEquipment"=>1, "WaterUseEquipmentDefinition"=>1, "WaterUseEquipment"=>1, "ScheduleFixedInterval"=>1, "ScheduleConstant"=>1}
    expected_values = {"Annual_kwh"=>34.3, "HotWater_gpd"=>8.00}
    _test_measure(osm_geo_beds_loc_tankwh, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)
  end
  
  def test_new_construction_standard_int_heater
    args_hash = {}
    args_hash["cw_mef"] = 1.41
    args_hash["cw_rated_annual_energy"] = 387
    args_hash["cw_internal_heater"] = "true"
    expected_num_del_objects = {}
    expected_num_new_objects = {"ElectricEquipmentDefinition"=>1, "ElectricEquipment"=>1, "WaterUseEquipmentDefinition"=>1, "WaterUseEquipment"=>1, "ScheduleFixedInterval"=>1, "ScheduleConstant"=>1}
    expected_values = {"Annual_kwh"=>42.9, "HotWater_gpd"=>10.00}
    _test_measure(osm_geo_beds_loc_tankwh, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)
  end

  def test_new_construction_standard_no_thermostatic_control
    args_hash = {}
    args_hash["cw_mef"] = 1.41
    args_hash["cw_rated_annual_energy"] = 387
    args_hash["cw_thermostatic_control"] = "false"
    expected_num_del_objects = {}
    expected_num_new_objects = {"ElectricEquipmentDefinition"=>1, "ElectricEquipment"=>1, "WaterUseEquipmentDefinition"=>1, "WaterUseEquipment"=>1, "ScheduleFixedInterval"=>1, "ScheduleConstant"=>1}
    expected_values = {"Annual_kwh"=>42.9, "HotWater_gpd"=>8.67}
    _test_measure(osm_geo_beds_loc_tankwh, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)
  end

  def test_new_construction_energystar_cold_inlet
    args_hash = {}
    args_hash["cw_mef"] = 2.47
    args_hash["cw_rated_annual_energy"] = 123.0
    args_hash["cw_annual_cost"] = 9.0
    args_hash["cw_drum_volume"] = 3.68
    args_hash["cw_cold_cycle"] = "true"
    expected_num_del_objects = {}
    expected_num_new_objects = {"ElectricEquipmentDefinition"=>1, "ElectricEquipment"=>1, "WaterUseEquipmentDefinition"=>1, "WaterUseEquipment"=>1, "ScheduleFixedInterval"=>1, "ScheduleConstant"=>1}
    expected_values = {"Annual_kwh"=>34.9, "HotWater_gpd"=>2.27}
    _test_measure(osm_geo_beds_loc_tankwh, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)
  end

  def test_new_construction_energystar_cold_inlet_tankless
    args_hash = {}
    args_hash["cw_mef"] = 2.47
    args_hash["cw_rated_annual_energy"] = 123.0
    args_hash["cw_annual_cost"] = 9.0
    args_hash["cw_drum_volume"] = 3.68
    args_hash["cw_cold_cycle"] = "true"
    expected_num_del_objects = {}
    expected_num_new_objects = {"ElectricEquipmentDefinition"=>1, "ElectricEquipment"=>1, "WaterUseEquipmentDefinition"=>1, "WaterUseEquipment"=>1, "ScheduleFixedInterval"=>1, "ScheduleConstant"=>1}
    expected_values = {"Annual_kwh"=>34.9, "HotWater_gpd"=>2.27}
    _test_measure(osm_geo_beds_loc_tanklesswh, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)
  end

  def test_new_construction_basement
    args_hash = {}
    args_hash["cw_mef"] = 1.41
    args_hash["cw_rated_annual_energy"] = 387
    args_hash["space"] = Constants.FinishedBasementSpace
    expected_num_del_objects = {}
    expected_num_new_objects = {"ElectricEquipmentDefinition"=>1, "ElectricEquipment"=>1, "WaterUseEquipmentDefinition"=>1, "WaterUseEquipment"=>1, "ScheduleFixedInterval"=>1, "ScheduleConstant"=>1}
    expected_values = {"Annual_kwh"=>42.9, "HotWater_gpd"=>10.00}
    _test_measure(osm_geo_beds_loc_tankwh, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)
  end

  def test_retrofit_replace
    args_hash = {}
    args_hash["cw_mef"] = 1.41
    args_hash["cw_rated_annual_energy"] = 387
    expected_num_del_objects = {}
    expected_num_new_objects = {"ElectricEquipmentDefinition"=>1, "ElectricEquipment"=>1, "WaterUseEquipmentDefinition"=>1, "WaterUseEquipment"=>1, "ScheduleFixedInterval"=>1, "ScheduleConstant"=>1}
    expected_values = {"Annual_kwh"=>42.9, "HotWater_gpd"=>10.00}
    model = _test_measure(osm_geo_beds_loc_tankwh, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)
    args_hash = {}
    args_hash["cw_mef"] = 2.47
    args_hash["cw_rated_annual_energy"] = 123.0
    args_hash["cw_annual_cost"] = 9.0
    args_hash["cw_drum_volume"] = 3.68
    expected_num_del_objects = {"ElectricEquipmentDefinition"=>1, "ElectricEquipment"=>1, "WaterUseEquipmentDefinition"=>1, "WaterUseEquipment"=>1, "ScheduleFixedInterval"=>1, "ScheduleConstant"=>1}
    expected_num_new_objects = {"ElectricEquipmentDefinition"=>1, "ElectricEquipment"=>1, "WaterUseEquipmentDefinition"=>1, "WaterUseEquipment"=>1, "ScheduleFixedInterval"=>1, "ScheduleConstant"=>1}
    expected_values = {"Annual_kwh"=>34.9, "HotWater_gpd"=>2.27}
    _test_measure(model, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 1)
  end
    
  def test_retrofit_remove
    args_hash = {}
    args_hash["cw_mef"] = 1.41
    args_hash["cw_rated_annual_energy"] = 387
    expected_num_del_objects = {}
    expected_num_new_objects = {"ElectricEquipmentDefinition"=>1, "ElectricEquipment"=>1, "WaterUseEquipmentDefinition"=>1, "WaterUseEquipment"=>1, "ScheduleFixedInterval"=>1, "ScheduleConstant"=>1}
    expected_values = {"Annual_kwh"=>42.9, "HotWater_gpd"=>10.00}
    model = _test_measure(osm_geo_beds_loc_tankwh, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)
    args_hash = {}
    args_hash["cw_mult_e"] = 0.0
    args_hash["cw_mult_hw"] = 0.0
    expected_num_del_objects = {"ElectricEquipmentDefinition"=>1, "ElectricEquipment"=>1, "WaterUseEquipmentDefinition"=>1, "WaterUseEquipment"=>1, "ScheduleFixedInterval"=>1, "ScheduleConstant"=>1}
    expected_num_new_objects = {}
    expected_values = {"Annual_kwh"=>0, "HotWater_gpd"=>0}
    _test_measure(model, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 1)
  end
  
  def test_multifamily_new_construction
    num_units = 3
    args_hash = {}
    args_hash["cw_mef"] = 1.41
    args_hash["cw_rated_annual_energy"] = 387
    expected_num_del_objects = {}
    expected_num_new_objects = {"ElectricEquipmentDefinition"=>num_units, "ElectricEquipment"=>num_units, "WaterUseEquipmentDefinition"=>num_units, "WaterUseEquipment"=>num_units, "ScheduleFixedInterval"=>num_units, "ScheduleConstant"=>num_units}
    expected_values = {"Annual_kwh"=>121.5, "HotWater_gpd"=>28.3}
    _test_measure(osm_geo_multifamily_3_units_beds_loc_tankwh, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, num_units)
  end
  
  def test_multifamily_new_construction_finished_basement
    num_units = 3
    args_hash = {}
    args_hash["cw_mef"] = 1.41
    args_hash["cw_rated_annual_energy"] = 387
    args_hash["space"] = "finishedbasement_1"
    expected_num_del_objects = {}
    expected_num_new_objects = {"ElectricEquipmentDefinition"=>1, "ElectricEquipment"=>1, "WaterUseEquipmentDefinition"=>1, "WaterUseEquipment"=>1, "ScheduleFixedInterval"=>1, "ScheduleConstant"=>1}
    expected_values = {"Annual_kwh"=>42.9, "HotWater_gpd"=>10.0}
    _test_measure(osm_geo_multifamily_3_units_beds_loc_tankwh, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)
  end
  
  def test_multifamily_new_construction_mult_draw_profiles
    num_units = 12
    args_hash = {}
    args_hash["cw_mef"] = 1.41
    args_hash["cw_rated_annual_energy"] = 387
    expected_num_del_objects = {}
    expected_num_new_objects = {"ElectricEquipmentDefinition"=>num_units, "ElectricEquipment"=>num_units, "WaterUseEquipmentDefinition"=>num_units, "WaterUseEquipment"=>num_units, "ScheduleFixedInterval"=>num_units, "ScheduleConstant"=>num_units}
    expected_values = {"Annual_kwh"=>514.8, "HotWater_gpd"=>120}
    _test_measure(osm_geo_multifamily_12_units_beds_loc_tankwh, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, num_units)
  end
  
  def test_multifamily_retrofit_replace
    num_units = 3
    args_hash = {}
    args_hash["cw_mef"] = 1.41
    args_hash["cw_rated_annual_energy"] = 387
    expected_num_del_objects = {}
    expected_num_new_objects = {"ElectricEquipmentDefinition"=>num_units, "ElectricEquipment"=>num_units, "WaterUseEquipmentDefinition"=>num_units, "WaterUseEquipment"=>num_units, "ScheduleFixedInterval"=>num_units, "ScheduleConstant"=>num_units}
    expected_values = {"Annual_kwh"=>121.5, "HotWater_gpd"=>28.3}
    model = _test_measure(osm_geo_multifamily_3_units_beds_loc_tankwh, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, num_units)
    args_hash = {}
    args_hash["cw_mef"] = 2.47
    args_hash["cw_rated_annual_energy"] = 123
    args_hash["cw_annual_cost"] = 9.0
    args_hash["cw_drum_volume"] = 3.68
    expected_num_del_objects = {"ElectricEquipmentDefinition"=>num_units, "ElectricEquipment"=>num_units, "WaterUseEquipmentDefinition"=>num_units, "WaterUseEquipment"=>num_units, "ScheduleFixedInterval"=>num_units, "ScheduleConstant"=>num_units}
    expected_num_new_objects = {"ElectricEquipmentDefinition"=>num_units, "ElectricEquipment"=>num_units, "WaterUseEquipmentDefinition"=>num_units, "WaterUseEquipment"=>num_units, "ScheduleFixedInterval"=>num_units, "ScheduleConstant"=>num_units}
    expected_values = {"Annual_kwh"=>98.9, "HotWater_gpd"=>6.4}
    _test_measure(model, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 2*num_units)
  end
  
  def test_multifamily_retrofit_remove
    num_units = 3
    args_hash = {}
    args_hash["cw_mef"] = 1.41
    args_hash["cw_rated_annual_energy"] = 387
    expected_num_del_objects = {}
    expected_num_new_objects = {"ElectricEquipmentDefinition"=>num_units, "ElectricEquipment"=>num_units, "WaterUseEquipmentDefinition"=>num_units, "WaterUseEquipment"=>num_units, "ScheduleFixedInterval"=>num_units, "ScheduleConstant"=>num_units}
    expected_values = {"Annual_kwh"=>121.5, "HotWater_gpd"=>28.3}
    model = _test_measure(osm_geo_multifamily_3_units_beds_loc_tankwh, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, num_units)
    args_hash = {}
    args_hash["cw_mult_e"] = 0.0
    args_hash["cw_mult_hw"] = 0.0
    expected_num_del_objects = {"ElectricEquipmentDefinition"=>num_units, "ElectricEquipment"=>num_units, "WaterUseEquipmentDefinition"=>num_units, "WaterUseEquipment"=>num_units, "ScheduleFixedInterval"=>num_units, "ScheduleConstant"=>num_units}
    expected_num_new_objects = {}
    expected_values = {"Annual_kwh"=>0, "HotWater_gpd"=>0}
    _test_measure(model, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, num_units)
  end
  
  def test_argument_error_cw_mef_negative
    args_hash = {}
    args_hash["cw_mef"] = -1
    result = _test_error(osm_geo_beds_loc_tankwh, args_hash)
    assert_equal(result_errors(result)[0], "Modified energy factor must be greater than 0.0.")
  end
  
  def test_argument_error_cw_mef_zero
    args_hash = {}
    args_hash["cw_mef"] = 0
    result = _test_error(osm_geo_beds_loc_tankwh, args_hash)
    assert_equal(result_errors(result)[0], "Modified energy factor must be greater than 0.0.")
  end

  def test_argument_error_cw_rated_annual_energy_negative
    args_hash = {}
    args_hash["cw_rated_annual_energy"] = -1.0
    result = _test_error(osm_geo_beds_loc_tankwh, args_hash)
    assert_equal(result_errors(result)[0], "Rated annual consumption must be greater than 0.0.")
  end
  
  def test_argument_error_cw_rated_annual_energy_zero
    args_hash = {}
    args_hash["cw_rated_annual_energy"] = 0.0
    result = _test_error(osm_geo_beds_loc_tankwh, args_hash)
    assert_equal(result_errors(result)[0], "Rated annual consumption must be greater than 0.0.")
  end

  def test_argument_error_cw_test_date_negative
    args_hash = {}
    args_hash["cw_test_date"] = -1
    result = _test_error(osm_geo_beds_loc_tankwh, args_hash)
    assert_equal(result_errors(result)[0], "Test date must be greater than or equal to 1900.")
  end

  def test_argument_error_cw_test_date_zero
    args_hash = {}
    args_hash["cw_test_date"] = 0
    result = _test_error(osm_geo_beds_loc_tankwh, args_hash)
    assert_equal(result_errors(result)[0], "Test date must be greater than or equal to 1900.")
  end

  def test_argument_error_cw_annual_cost_negative
    args_hash = {}
    args_hash["cw_annual_cost"] = -1
    result = _test_error(osm_geo_beds_loc_tankwh, args_hash)
    assert_equal(result_errors(result)[0], "Annual cost with gas DHW must be greater than 0.0.")
  end

  def test_argument_error_cw_annual_cost_zero
    args_hash = {}
    args_hash["cw_annual_cost"] = 0
    result = _test_error(osm_geo_beds_loc_tankwh, args_hash)
    assert_equal(result_errors(result)[0], "Annual cost with gas DHW must be greater than 0.0.")
  end
  
  def test_argument_error_cw_drum_volume_negative
    args_hash = {}
    args_hash["cw_drum_volume"] = -1
    result = _test_error(osm_geo_beds_loc_tankwh, args_hash)
    assert_equal(result_errors(result)[0], "Drum volume must be greater than 0.0.")
  end

  def test_argument_error_cw_drum_volume_zero
    args_hash = {}
    args_hash["cw_drum_volume"] = 0
    result = _test_error(osm_geo_beds_loc_tankwh, args_hash)
    assert_equal(result_errors(result)[0], "Drum volume must be greater than 0.0.")
  end

  def test_argument_error_cw_mult_e_negative
    args_hash = {}
    args_hash["cw_mult_e"] = -1
    result = _test_error(osm_geo_beds_loc_tankwh, args_hash)
    assert_equal(result_errors(result)[0], "Occupancy energy multiplier must be greater than or equal to 0.0.")
  end

  def test_argument_error_cw_mult_hw_negative
    args_hash = {}
    args_hash["cw_mult_hw"] = -1
    result = _test_error(osm_geo_beds_loc_tankwh, args_hash)
    assert_equal(result_errors(result)[0], "Occupancy hot water multiplier must be greater than or equal to 0.0.")
  end

  def test_error_missing_geometry
    args_hash = {}
    result = _test_error(nil, args_hash)
    assert_equal(result_errors(result)[0], "Cannot determine number of building units; Building::standardsNumberOfLivingUnits has not been set.")
  end
  
  def test_error_missing_beds
    args_hash = {}
    result = _test_error(osm_geo_loc, args_hash)
    assert_equal(result_errors(result)[0], "Could not determine number of bedrooms or bathrooms. Run the 'Add Residential Bedrooms And Bathrooms' measure first.")
  end
  
  def test_error_missing_location
    args_hash = {}
    result = _test_error(osm_geo_beds, args_hash)
    assert_equal(result_errors(result)[0], "Mains water temperature has not been set.")
  end

  def test_error_missing_water_heater
    args_hash = {}
    result = _test_error(osm_geo_beds_loc, args_hash)
    assert_equal(result_errors(result)[0], "Could not find plant loop.")
  end

  private
  
  def _test_error(osm_file, args_hash)
    # create an instance of the measure
    measure = ResidentialClothesWasher.new
    
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

    # show the output
    #show_output(result)

    # assert that it didn't run
    assert_equal("Fail", result_value(result))
    assert(result_errors(result).size == 1)
    
    return result
  end

  def _test_measure(osm_file_or_model, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, num_infos=0, num_warnings=0)
    # create an instance of the measure
    measure = ResidentialClothesWasher.new

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

    # show the output
    #show_output(result)

    # assert that it ran correctly
    assert_equal("Success", result_value(result))
    assert(result_infos(result).size == num_infos)
    assert(result_warnings(result).size == num_warnings)
    assert(result_has_final_condition(result))
    
    # get the final objects in the model
    final_objects = get_objects(model)
    
    # get new and deleted objects
    obj_type_exclusions = ["WaterUseConnections", "Node"]
    all_new_objects = get_object_additions(initial_objects, final_objects, obj_type_exclusions)
    all_del_objects = get_object_additions(final_objects, initial_objects, obj_type_exclusions)
    
    # check we have the expected number of new/deleted objects
    check_num_objects(all_new_objects, expected_num_new_objects, "added")
    check_num_objects(all_del_objects, expected_num_del_objects, "deleted")

    actual_values = {"Annual_kwh"=>0, "HotWater_gpd"=>0}
    all_new_objects.each do |obj_type, new_objects|
        new_objects.each do |new_object|
            next if not new_object.respond_to?("to_#{obj_type}")
            new_object = new_object.public_send("to_#{obj_type}").get
            if obj_type == "ElectricEquipment"
                full_load_hrs = Schedule.annual_equivalent_full_load_hrs(model, new_object.schedule.get)
                actual_values["Annual_kwh"] += OpenStudio.convert(full_load_hrs * new_object.designLevel.get * new_object.multiplier, "Wh", "kWh").get
            elsif obj_type == "WaterUseEquipment"
                full_load_hrs = Schedule.annual_equivalent_full_load_hrs(model, new_object.flowRateFractionSchedule.get)
                actual_values["HotWater_gpd"] += OpenStudio.convert(full_load_hrs * new_object.waterUseEquipmentDefinition.peakFlowRate * new_object.multiplier, "m^3/s", "gal/min").get * 60.0 / 365.0
            end
        end
    end
    assert_in_epsilon(expected_values["Annual_kwh"], actual_values["Annual_kwh"], 0.01)
    assert_in_epsilon(expected_values["HotWater_gpd"], actual_values["HotWater_gpd"], 0.01)

    return model
  end
  
end
