require_relative '../../../test/minitest_helper'
require 'openstudio'
require 'openstudio/ruleset/ShowRunnerOutput'
require 'minitest/autorun'
require_relative '../measure.rb'
require 'fileutils'

class ResidentialHotWaterHeaterTanklessPropaneTest < MiniTest::Test

  def osm_geo_loc
    return "2000sqft_2story_FB_GRG_UA_Denver.osm"
  end
  
  def osm_geo_beds
    return "2000sqft_2story_FB_GRG_UA_3Beds_2Baths.osm"
  end

  def osm_geo_beds_loc
    return "2000sqft_2story_FB_GRG_UA_3Beds_2Baths_Denver.osm"
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

  def osm_geo_beds_loc_tank_electric
    return "2000sqft_2story_FB_GRG_UA_3Beds_2Baths_Denver_TankElectric.osm"
  end

  def osm_geo_beds_loc_tankless_electric
    return "2000sqft_2story_FB_GRG_UA_3Beds_2Baths_Denver_TanklessElectric.osm"
  end

  def osm_geo_beds_loc_tankless_gas
    return "2000sqft_2story_FB_GRG_UA_3Beds_2Baths_Denver_TanklessGas.osm"
  end

  def osm_geo_multifamily_3_units_beds_loc
    return "multifamily_3_units_Beds_Baths_Denver.osm"
  end

  def test_new_construction_standard
    args_hash = {}
    _test_measure(osm_geo_beds_loc, args_hash, 0, 1, Constants.FinishedBasementZone, 29307107, 0.754, 125, 7.38, 7.38, 1, 0)
  end
    
  def test_new_construction_standard_living
    args_hash = {}
    args_hash["water_heater_location"] = Constants.LivingZone
    _test_measure(osm_geo_beds_loc, args_hash, 0, 1, Constants.LivingZone, 29307107, 0.754, 125, 7.38, 7.38, 1, 0)
  end

  def test_new_construction_standard_setpoint_130
    args_hash = {}
    args_hash["dhw_setpoint_temperature"] = 130
    _test_measure(osm_geo_beds_loc, args_hash, 0, 1, Constants.FinishedBasementZone, 29307107, 0.754, 130, 7.38, 7.38, 1, 0)
  end

  def test_new_construction_standard_cd_0
    args_hash = {}
    args_hash["water_heater_cycling_derate"] = 0
    _test_measure(osm_geo_beds_loc, args_hash, 0, 1, Constants.FinishedBasementZone, 29307107, 0.82, 125, 7.38, 7.38, 1, 0)
  end

  def test_retrofit_replace
    args_hash = {}
    model = _test_measure(osm_geo_beds_loc, args_hash, 0, 1, Constants.FinishedBasementZone, 29307107, 0.754, 125, 7.38, 7.38, 1, 0)
    args_hash = {}
    args_hash["rated_energy_factor"] = 0.96
    _test_measure(model, args_hash, 1, 1, Constants.FinishedBasementZone, 29307107, 0.883, 125, 7.38, 7.38, 1, 0)
  end
  
  def test_retrofit_replace_tank_gas
    args_hash = {}
    _test_measure(osm_geo_beds_loc_tank_gas, args_hash, 1, 1, Constants.FinishedBasementZone, 29307107, 0.754, 125, 7.38, 7.38, 1, 0)
  end

  def test_retrofit_replace_tank_oil
    args_hash = {}
    _test_measure(osm_geo_beds_loc_tank_oil, args_hash, 1, 1, Constants.FinishedBasementZone, 29307107, 0.754, 125, 7.38, 7.38, 1, 0)
  end

  def test_retrofit_replace_tank_propane
    args_hash = {}
    _test_measure(osm_geo_beds_loc_tank_propane, args_hash, 1, 1, Constants.FinishedBasementZone, 29307107, 0.754, 125, 7.38, 7.38, 1, 0)
  end

  def test_retrofit_replace_tank_electric
    args_hash = {}
    _test_measure(osm_geo_beds_loc_tank_electric, args_hash, 1, 1, Constants.FinishedBasementZone, 29307107, 0.754, 125, 7.38, 7.38, 1, 0)
  end

  def test_retrofit_replace_tankless_electric
    args_hash = {}
    _test_measure(osm_geo_beds_loc_tankless_electric, args_hash, 1, 1, Constants.FinishedBasementZone, 29307107, 0.754, 125, 7.38, 7.38, 1, 0)
  end

  def test_retrofit_replace_tankless_gas
    args_hash = {}
    _test_measure(osm_geo_beds_loc_tankless_gas, args_hash, 1, 1, Constants.FinishedBasementZone, 29307107, 0.754, 125, 7.38, 7.38, 1, 0)
  end

  def test_multifamily_new_construction
    num_units = 3
    args_hash = {}
    _test_measure(osm_geo_multifamily_3_units_beds_loc, args_hash, 0, num_units, nil, 87921321, 2.262, 375, 21.76, 21.76, num_units, 0)
  end
  
  def test_multifamily_new_construction_living_zone
    args_hash = {}
    args_hash["water_heater_location"] = "living zone 1"
    _test_measure(osm_geo_multifamily_3_units_beds_loc, args_hash, 0, 1, "living zone 1", 29307107, 0.754, 125, 7.38, 7.38, 1, 0)
  end

  def test_multifamily_retrofit_replace
    num_units = 3
    args_hash = {}
    model = _test_measure(osm_geo_multifamily_3_units_beds_loc, args_hash, 0, num_units, nil, 87921321, 2.262, 375, 21.76, 21.76, num_units, 0)
    args_hash = {}
    args_hash["rated_energy_factor"] = 0.96
    _test_measure(model, args_hash, num_units, num_units, nil, 87921321, 2.649, 375, 21.76, 21.76, num_units, 0)
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

  def test_argument_error_capacity_lt_0
    args_hash = {}
    args_hash["water_heater_capacity"] = -10
    result = _test_error(osm_geo_beds_loc, args_hash)
    assert_equal(result.errors[0].logMessage, "Nominal capacity must be greater than 0.")
  end

  def test_argument_error_capacity_eq_0
    args_hash = {}
    args_hash["water_heater_capacity"] = 0
    result = _test_error(osm_geo_beds_loc, args_hash)
    assert_equal(result.errors[0].logMessage, "Nominal capacity must be greater than 0.")
  end

  def test_argument_error_ef_lt_0
    args_hash = {}
    args_hash["rated_energy_factor"] = -10
    result = _test_error(osm_geo_beds_loc, args_hash)
    assert_equal(result.errors[0].logMessage, "Rated energy factor must be greater than 0 and less than 1.")
  end

  def test_argument_error_ef_eq_0
    args_hash = {}
    args_hash["rated_energy_factor"] = 0
    result = _test_error(osm_geo_beds_loc, args_hash)
    assert_equal(result.errors[0].logMessage, "Rated energy factor must be greater than 0 and less than 1.")
  end

  def test_argument_error_ef_gt_1
    args_hash = {}
    args_hash["rated_energy_factor"] = 1.1
    result = _test_error(osm_geo_beds_loc, args_hash)
    assert_equal(result.errors[0].logMessage, "Rated energy factor must be greater than 0 and less than 1.")
  end
  
  def test_argument_error_cd_lt_0
    args_hash = {}
    args_hash["water_heater_cycling_derate"] = -1
    result = _test_error(osm_geo_beds_loc, args_hash)
    assert_equal(result.errors[0].logMessage, "Cycling derate must be at least 0 and at most 1.")
  end

  def test_argument_error_cd_gt_1
    args_hash = {}
    args_hash["water_heater_cycling_derate"] = 1.1
    result = _test_error(osm_geo_beds_loc, args_hash)
    assert_equal(result.errors[0].logMessage, "Cycling derate must be at least 0 and at most 1.")
  end
  
  def test_argument_error_oncycle_lt_0
    args_hash = {}
    args_hash["oncyc_power"] = -1
    result = _test_error(osm_geo_beds_loc, args_hash)
    assert_equal(result.errors[0].logMessage, "Forced draft fan power must be greater than 0.")
  end

  def test_argument_error_offcycle_lt_0
    args_hash = {}
    args_hash["offcyc_power"] = -1
    result = _test_error(osm_geo_beds_loc, args_hash)
    assert_equal(result.errors[0].logMessage, "Parasitic electricity power must be greater than 0.")
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
    assert_equal(result.errors[0].logMessage, "Mains water temperature must be set before adding a water heater.")
  end

  private
  
  def _test_error(osm_file, args_hash)
    # create an instance of the measure
    measure = ResidentialHotWaterHeaterTanklessPropane.new

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

  def _test_measure(osm_file_or_model, args_hash, expected_num_del_objects, expected_num_new_objects, expected_location, expected_input_cap, expected_thermal_eff, expected_setpoint, expected_oncycle_power, expected_offcycle_power, num_infos=0, num_warnings=0)
    # create an instance of the measure
    measure = ResidentialHotWaterHeaterTanklessPropane.new

    # check for standard methods
    assert(!measure.name.empty?)
    assert(!measure.description.empty?)
    assert(!measure.modeler_description.empty?)

    # create an instance of a runner
    runner = OpenStudio::Ruleset::OSRunner.new
    
    model = _get_model(osm_file_or_model)

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
    assert_in_epsilon(tot_vol, new_objects.size*Waterheater.calc_actual_tankvol(nil, nil, Constants.WaterHeaterTypeTankless), 0.01)
    assert_in_epsilon(tot_cap, expected_input_cap, 0.01)
    assert_in_epsilon(tot_te, expected_thermal_eff, 0.01)
    assert_in_epsilon(tot_ua1, 0, 0.01)
    assert_in_epsilon(tot_ua2, 0, 0.01)
    assert_in_epsilon(tot_setpoint, expected_setpoint, 0.01)
    assert_in_epsilon(tot_oncycle_power, expected_oncycle_power, 0.01)
    assert_in_epsilon(tot_offcycle_power, expected_offcycle_power, 0.01)
    
    del_objects.each do |del_object|
        # check that the del object had the correct name
        assert(del_object.name.to_s.start_with?(Constants.ObjectNameWaterHeater))
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
