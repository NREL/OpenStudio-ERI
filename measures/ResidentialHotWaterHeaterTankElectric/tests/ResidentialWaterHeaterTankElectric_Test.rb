require_relative '../../../test/minitest_helper'
require 'openstudio'
require 'openstudio/ruleset/ShowRunnerOutput'
require 'minitest/autorun'
require_relative '../measure.rb'
require 'fileutils'

class ResidentialHotWaterHeaterTankElectricTest < MiniTest::Test

  def osm_geo_loc
    return "2000sqft_2story_FB_GRG_UA_Denver.osm"
  end
  
  def osm_geo_beds
    return "2000sqft_2story_FB_GRG_UA_3Beds_2Baths.osm"
  end

  def osm_geo_beds_loc
    return "2000sqft_2story_FB_GRG_UA_3Beds_2Baths_Denver.osm"
  end
  
  def osm_geo_beds_loc_1_1
    return "2000sqft_2story_FB_GRG_UA_1Beds_1Baths_Denver.osm"
  end

  def osm_geo_beds_loc_2_1
    return "2000sqft_2story_FB_GRG_UA_2Beds_1Baths_Denver.osm"
  end

  def osm_geo_beds_loc_2_2
    return "2000sqft_2story_FB_GRG_UA_2Beds_2Baths_Denver.osm"
  end

  def osm_geo_beds_loc_5_3
    return "2000sqft_2story_FB_GRG_UA_5Beds_3Baths_Denver.osm"
  end
  
  def osm_geo_beds_loc_tank_gas
    return "2000sqft_2story_FB_GRG_UA_3Beds_2Baths_Denver_TankGas.osm"
  end

  def osm_geo_beds_loc_tank_oil
    return "2000sqft_2story_FB_GRG_UA_3Beds_2Baths_Denver_TankOil.osm"
  end

  def osm_geo_beds_loc_tank_propane
    return "2000sqft_2story_FB_GRG_UA_3Beds_2Baths_Denver_TankPropane.osm"
  end

  def osm_geo_beds_loc_tankless_electric
    return "2000sqft_2story_FB_GRG_UA_3Beds_2Baths_Denver_TanklessElectric.osm"
  end

  def osm_geo_beds_loc_tankless_gas
    return "2000sqft_2story_FB_GRG_UA_3Beds_2Baths_Denver_TanklessGas.osm"
  end

  def osm_geo_beds_loc_tankless_propane
    return "2000sqft_2story_FB_GRG_UA_3Beds_2Baths_Denver_TanklessPropane.osm"
  end

  def osm_geo_multifamily_3_units_beds_loc
    return "multifamily_3_units_Beds_Baths_Denver.osm"
  end

  def osm_geo_multifamily_12_units_beds_loc
    return "multifamily_12_units_Beds_Baths_Denver.osm"
  end

  def test_new_construction_standard
    args_hash = {}
    _test_measure(osm_geo_beds_loc, args_hash, 0, 1, 50, Constants.FinishedBasementZone, 4.5, 1.0, 2.21, 125, 0, 0, 1, 0)
  end
    
  def test_new_construction_premium
    args_hash = {}
    args_hash["rated_energy_factor"] = "0.95"
    args_hash["water_heater_capacity"] = "5.5"
    _test_measure(osm_geo_beds_loc, args_hash, 0, 1, 50, Constants.FinishedBasementZone, 5.5, 1.0, 1.34, 125, 0, 0, 1, 0)
  end

  def test_new_construction_standard_auto_ef_and_capacity
    args_hash = {}
    args_hash["rated_energy_factor"] = Constants.Auto
    args_hash["water_heater_capacity"] = Constants.Auto
    _test_measure(osm_geo_beds_loc, args_hash, 0, 1, 50, Constants.FinishedBasementZone, 5.5, 1.0, 2.69, 125, 0, 0, 1, 0)
  end
  
  def test_new_construction_standard_living
    args_hash = {}
    args_hash["water_heater_location"] = Constants.LivingZone
    _test_measure(osm_geo_beds_loc, args_hash, 0, 1, 50, Constants.LivingZone, 4.5, 1.0, 2.21, 125, 0, 0, 1, 0)
  end

  def test_new_construction_standard_setpoint_130
    args_hash = {}
    args_hash["dhw_setpoint_temperature"] = 130
    _test_measure(osm_geo_beds_loc, args_hash, 0, 1, 50, Constants.FinishedBasementZone, 4.5, 1.0, 2.21, 130, 0, 0, 1, 0)
  end

  def test_new_construction_standard_volume_30
    args_hash = {}
    args_hash["storage_tank_volume"] = "30"
    _test_measure(osm_geo_beds_loc, args_hash, 0, 1, 30, Constants.FinishedBasementZone, 4.5, 1.0, 2.21, 125, 0, 0, 1, 0)
  end

  def test_new_construction_beds_baths_1_1
    args_hash = {}
    args_hash["water_heater_capacity"] = Constants.Auto
    args_hash["rated_energy_factor"] = Constants.Auto
    _test_measure(osm_geo_beds_loc_1_1, args_hash, 0, 1, 20, Constants.FinishedBasementZone, 2.5, 1.0, 1.52, 125, 0, 0, 1, 0)
  end

  def test_new_construction_beds_baths_2_1
    args_hash = {}
    args_hash["water_heater_capacity"] = Constants.Auto
    args_hash["rated_energy_factor"] = Constants.Auto
    _test_measure(osm_geo_beds_loc_2_1, args_hash, 0, 1, 30, Constants.FinishedBasementZone, 3.5, 1.0, 1.90, 125, 0, 0, 1, 0)
  end

  def test_new_construction_beds_baths_2_2
    args_hash = {}
    args_hash["water_heater_capacity"] = Constants.Auto
    args_hash["rated_energy_factor"] = Constants.Auto
    _test_measure(osm_geo_beds_loc_2_2, args_hash, 0, 1, 40, Constants.FinishedBasementZone, 4.5, 1.0, 2.29, 125, 0, 0, 1, 0)
  end

  def test_new_construction_beds_baths_5_3
    args_hash = {}
    args_hash["water_heater_capacity"] = Constants.Auto
    args_hash["rated_energy_factor"] = Constants.Auto
    _test_measure(osm_geo_beds_loc_5_3, args_hash, 0, 1, 66, Constants.FinishedBasementZone, 5.5, 1.0, 3.36, 125, 0, 0, 1, 0)
  end

  def test_retrofit_replace
    args_hash = {}
    model = _test_measure(osm_geo_beds_loc, args_hash, 0, 1, 50, Constants.FinishedBasementZone, 4.5, 1.0, 2.21, 125, 0, 0, 1, 0)
    args_hash = {}
    args_hash["rated_energy_factor"] = "0.95"
    args_hash["water_heater_capacity"] = "5.5"
    _test_measure(model, args_hash, 1, 1, 50, Constants.FinishedBasementZone, 5.5, 1.0, 1.34, 125, 0, 0, 1, 0)
  end
  
  def test_retrofit_replace_tank_gas
    args_hash = {}
    _test_measure(osm_geo_beds_loc_tank_gas, args_hash, 1, 1, 50, Constants.FinishedBasementZone, 4.5, 1.0, 2.21, 125, 0, 0, 1, 0)
  end

  def test_retrofit_replace_tank_oil
    args_hash = {}
    _test_measure(osm_geo_beds_loc_tank_oil, args_hash, 1, 1, 50, Constants.FinishedBasementZone, 4.5, 1.0, 2.21, 125, 0, 0, 1, 0)
  end

  def test_retrofit_replace_tank_propane
    args_hash = {}
    _test_measure(osm_geo_beds_loc_tank_propane, args_hash, 1, 1, 50, Constants.FinishedBasementZone, 4.5, 1.0, 2.21, 125, 0, 0, 1, 0)
  end

  def test_retrofit_replace_tankless_electric
    args_hash = {}
    _test_measure(osm_geo_beds_loc_tankless_electric, args_hash, 1, 1, 50, Constants.FinishedBasementZone, 4.5, 1.0, 2.21, 125, 0, 0, 1, 0)
  end

  def test_retrofit_replace_tankless_gas
    args_hash = {}
    _test_measure(osm_geo_beds_loc_tankless_gas, args_hash, 1, 1, 50, Constants.FinishedBasementZone, 4.5, 1.0, 2.21, 125, 0, 0, 1, 0)
  end

  def test_retrofit_replace_tankless_propane
    args_hash = {}
    _test_measure(osm_geo_beds_loc_tankless_propane, args_hash, 1, 1, 50, Constants.FinishedBasementZone, 4.5, 1.0, 2.21, 125, 0, 0, 1, 0)
  end

  def test_multifamily_new_construction
    num_units = 3
    args_hash = {}
    _test_measure(osm_geo_multifamily_3_units_beds_loc, args_hash, 0, num_units, 136, nil, 13.5, 3.0, 6.62, 375, 0, 0, num_units, 0)
  end
  
  def test_multifamily_new_construction_living_zone
    args_hash = {}
    args_hash["water_heater_location"] = "living zone 1"
    _test_measure(osm_geo_multifamily_3_units_beds_loc, args_hash, 0, 1, 50, "living zone 1", 4.5, 1.0, 2.21, 125, 0, 0, 1, 0)
  end

  def test_multifamily_new_construction_mult_draw_profiles
    num_units = 12
    args_hash = {}
    _test_measure(osm_geo_multifamily_12_units_beds_loc, args_hash, 0, num_units, 600, nil, 54, 12, 26.4, 1500, 0, 0, num_units, 0)
  end

  def test_multifamily_retrofit_replace
    num_units = 3
    args_hash = {}
    model = _test_measure(osm_geo_multifamily_3_units_beds_loc, args_hash, 0, num_units, 136, nil, 13.5, 3.0, 6.62, 375, 0, 0, num_units, 0)
    args_hash = {}
    args_hash["rated_energy_factor"] = "0.95"
    args_hash["water_heater_capacity"] = "5.5"
    _test_measure(model, args_hash, num_units, num_units, 136, nil, 16.5, 3.0, 4.01, 375, 0, 0, num_units, 0)
  end

  def test_argument_error_tank_volume_invalid_str
    args_hash = {}
    args_hash["storage_tank_volume"] = "test"
    result = _test_error(osm_geo_beds_loc, args_hash)
    assert_equal(result.errors[0].logMessage, "Storage tank volume must be greater than 0 or #{Constants.Auto}.")
  end
  
  def test_argument_error_tank_volume_lt_0
    args_hash = {}
    args_hash["storage_tank_volume"] = "-10"
    result = _test_error(osm_geo_beds_loc, args_hash)
    assert_equal(result.errors[0].logMessage, "Storage tank volume must be greater than 0 or #{Constants.Auto}.")
  end

  def test_argument_error_tank_volume_eq_0
    args_hash = {}
    args_hash["storage_tank_volume"] = "0"
    result = _test_error(osm_geo_beds_loc, args_hash)
    assert_equal(result.errors[0].logMessage, "Storage tank volume must be greater than 0 or #{Constants.Auto}.")
  end

  def test_argument_error_setpoint_lt_0
    args_hash = {}
    args_hash["dhw_setpoint_temperature"] = -10
    result = _test_error(osm_geo_beds_loc, args_hash)
    assert_equal(result.errors[0].logMessage, "Hot water temperature must be greater than 0 and less than 212.")
  end

  def test_argument_error_setpoint_lg_300
    args_hash = {}
    args_hash["dhw_setpoint_temperature"] = 300
    result = _test_error(osm_geo_beds_loc, args_hash)
    assert_equal(result.errors[0].logMessage, "Hot water temperature must be greater than 0 and less than 212.")
  end

  def test_argument_error_capacity_invalid_str
    args_hash = {}
    args_hash["water_heater_capacity"] = "test"
    result = _test_error(osm_geo_beds_loc, args_hash)
    assert_equal(result.errors[0].logMessage, "Nominal capacity must be greater than 0 or #{Constants.Auto}.")
  end

  def test_argument_error_capacity_lt_0
    args_hash = {}
    args_hash["water_heater_capacity"] = "-10"
    result = _test_error(osm_geo_beds_loc, args_hash)
    assert_equal(result.errors[0].logMessage, "Nominal capacity must be greater than 0 or #{Constants.Auto}.")
  end

  def test_argument_error_capacity_eq_0
    args_hash = {}
    args_hash["water_heater_capacity"] = "0"
    result = _test_error(osm_geo_beds_loc, args_hash)
    assert_equal(result.errors[0].logMessage, "Nominal capacity must be greater than 0 or #{Constants.Auto}.")
  end

  def test_argument_error_ef_invalid_str
    args_hash = {}
    args_hash["rated_energy_factor"] = "test"
    result = _test_error(osm_geo_beds_loc, args_hash)
    assert_equal(result.errors[0].logMessage, "Rated energy factor must be greater than 0 and less than 1, or #{Constants.Auto}.")
  end

  def test_argument_error_ef_lt_0
    args_hash = {}
    args_hash["rated_energy_factor"] = "-10"
    result = _test_error(osm_geo_beds_loc, args_hash)
    assert_equal(result.errors[0].logMessage, "Rated energy factor must be greater than 0 and less than 1, or #{Constants.Auto}.")
  end

  def test_argument_error_ef_eq_0
    args_hash = {}
    args_hash["rated_energy_factor"] = "0"
    result = _test_error(osm_geo_beds_loc, args_hash)
    assert_equal(result.errors[0].logMessage, "Rated energy factor must be greater than 0 and less than 1, or #{Constants.Auto}.")
  end

  def test_argument_error_ef_gt_1
    args_hash = {}
    args_hash["rated_energy_factor"] = "1.1"
    result = _test_error(osm_geo_beds_loc, args_hash)
    assert_equal(result.errors[0].logMessage, "Rated energy factor must be greater than 0 and less than 1, or #{Constants.Auto}.")
  end

  def test_error_missing_geometry
    args_hash = {}
    result = _test_error(nil, args_hash)
    assert_equal(result.errors[0].logMessage, "Cannot determine number of building units; Building::standardsNumberOfLivingUnits has not been set.")
  end
  
  def test_error_missing_beds
    args_hash = {}
    result = _test_error(osm_geo_loc, args_hash)
    assert_equal(result.errors[0].logMessage, "Could not determine number of bedrooms or bathrooms. Run the 'Add Residential Bedrooms And Bathrooms' measure first.")
  end
  
  def test_error_missing_mains_temp
    args_hash = {}
    result = _test_error(osm_geo_beds, args_hash)
    assert_equal(result.errors[0].logMessage, "Mains water temperature has not been set.")
  end

  private
  
  def _test_error(osm_file, args_hash)
    # create an instance of the measure
    measure = ResidentialHotWaterHeaterTankElectric.new

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
    assert_equal("Fail", result.value.valueName)
    assert(result.errors.size == 1)
    
    return result
  end

  def _test_measure(osm_file_or_model, args_hash, expected_num_del_objects, expected_num_new_objects, expected_tank_vol, expected_location, expected_input_cap, expected_thermal_eff, expected_ua, expected_setpoint, expected_oncycle_power, expected_offcycle_power, num_infos=0, num_warnings=0)
    # create an instance of the measure
    measure = ResidentialHotWaterHeaterTankElectric.new

    # check for standard methods
    assert(!measure.name.empty?)
    assert(!measure.description.empty?)
    assert(!measure.modeler_description.empty?)

    # create an instance of a runner
    runner = OpenStudio::Ruleset::OSRunner.new
    
    model = get_model(File.dirname(__FILE__), osm_file_or_model)

    # store the original WHs in the seed model
    orig_whs = []
    model.getPlantLoops.each do |pl|
        pl.supplyComponents.each do |wh|
            if wh.to_WaterHeaterMixed.is_initialized
                orig_whs << wh.to_WaterHeaterMixed.get
            elsif wh.to_WaterHeaterStratified.is_initialized
                orig_whs << wh.to_WaterHeaterStratified.get
            elsif wh.to_WaterHeaterHeatPump.is_initialized
                orig_whs << wh.to_WaterHeaterHeatPump.get
            end
        end
    end

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
    
    # Get the final WHs in the model
    final_whs = []
    model.getPlantLoops.each do |pl|
        pl.supplyComponents.each do |wh|
            if wh.to_WaterHeaterMixed.is_initialized
                final_whs << wh.to_WaterHeaterMixed.get
            elsif wh.to_WaterHeaterStratified.is_initialized
                final_whs << wh.to_WaterHeaterStratified.get
            elsif wh.to_WaterHeaterHeatPump.is_initialized
                final_whs << wh.to_WaterHeaterStratified.get
            end
        end
    end
    
    # get new/deleted WH objects
    new_objects = []
    final_whs.each do |wh|
        next if orig_whs.include?(wh)
        new_objects << wh
    end
    del_objects = []
    orig_whs.each do |wh|
        next if final_whs.include?(wh)
        del_objects << wh
    end
    
    # check for num new/del objects
    assert_equal(expected_num_del_objects, del_objects.size)
    assert_equal(expected_num_new_objects, new_objects.size)
    
    tot_vol = 0
    tot_cap = 0
    tot_te = 0
    tot_ua1 = 0
    tot_ua2 = 0
    tot_setpoint = 0
    tot_oncycle_power = 0
    tot_offcycle_power = 0
    new_objects.each do |new_object|
        # check that the new object has the correct name
        assert(new_object.name.to_s.start_with?(Constants.ObjectNameWaterHeater))
        
        # check tank volume
        tot_vol += OpenStudio.convert(new_object.tankVolume.get, "m^3", "gal").get
        
        # check input capacity
        tot_cap += OpenStudio.convert(new_object.heaterMaximumCapacity.get, "W", "kW").get
        
        # check thermal efficiency
        tot_te += new_object.heaterThermalEfficiency.get
        
        # check UA
        tot_ua1 += OpenStudio::convert(new_object.onCycleLossCoefficienttoAmbientTemperature.get, "W/K", "Btu/hr*R").get
        tot_ua2 += OpenStudio::convert(new_object.offCycleLossCoefficienttoAmbientTemperature.get, "W/K", "Btu/hr*R").get

        # check location
        if !expected_location.nil?
            loc = new_object.ambientTemperatureThermalZone.get.name.to_s
            assert(loc.start_with?(expected_location))
        end
        
        # check setpoint
        tot_setpoint += Waterheater.get_water_heater_setpoint(model, new_object.plantLoop.get, nil)
        
        # check on-cycle consumption
        tot_oncycle_power += new_object.onCycleParasiticFuelConsumptionRate
        
        # check off-cycle consumption
        tot_offcycle_power += new_object.offCycleParasiticFuelConsumptionRate
    end
    assert_in_epsilon(tot_vol, Waterheater.calc_actual_tankvol(expected_tank_vol, Constants.FuelTypeElectric, Constants.WaterHeaterTypeTank), 0.01)
    assert_in_epsilon(tot_cap, expected_input_cap, 0.01)
    assert_in_epsilon(tot_te, expected_thermal_eff, 0.01)
    assert_in_epsilon(tot_ua1, expected_ua, 0.01)
    assert_in_epsilon(tot_ua2, expected_ua, 0.01)
    assert_in_epsilon(tot_setpoint, expected_setpoint, 0.01)
    assert_in_epsilon(tot_oncycle_power, expected_oncycle_power, 0.01)
    assert_in_epsilon(tot_offcycle_power, expected_offcycle_power, 0.01)
    
    del_objects.each do |del_object|
        # check that the del object had the correct name
        assert(del_object.name.to_s.start_with?(Constants.ObjectNameWaterHeater))
    end

    return model
  end
  
end
