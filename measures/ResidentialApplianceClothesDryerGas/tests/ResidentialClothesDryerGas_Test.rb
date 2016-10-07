require_relative '../../../test/minitest_helper'
require 'openstudio'
require 'openstudio/ruleset/ShowRunnerOutput'
require 'minitest/autorun'
require_relative '../measure.rb'
require 'fileutils'

class ResidentialClothesDryerGasTest < MiniTest::Test

  def osm_geo
    return "2000sqft_2story_FB_GRG_UA.osm"
  end

  def osm_geo_beds
    return "2000sqft_2story_FB_GRG_UA_3Beds_2Baths.osm"
  end
  
  def osm_geo_beds_elecdryer
    return "2000sqft_2story_FB_GRG_UA_3Beds_2Baths_ElecClothesDryer.osm"
  end

  def osm_geo_multifamily_3_units_beds
    return "multifamily_3_units_Beds_Baths.osm"
  end

  def test_new_construction_none
    # Using energy multiplier
    args_hash = {}
    args_hash["cd_mult"] = 0.0
    expected_num_del_objects = {}
    expected_num_new_objects = {}
    expected_values = {"Annual_kwh"=>0, "Annual_therm"=>0}
    _test_measure(osm_geo_beds, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)
  end
  
  def test_new_construction_standard
    args_hash = {}
    args_hash["cd_ef"] = 2.75
    expected_num_del_objects = {}
    expected_num_new_objects = {"ElectricEquipmentDefinition"=>1, "ElectricEquipment"=>1, "GasEquipmentDefinition"=>1, "GasEquipment"=>1, "ScheduleRuleset"=>1}
    expected_values = {"Annual_kwh"=>81.0, "Annual_therm"=>36.7}
    _test_measure(osm_geo_beds, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)
  end
  
  def test_new_construction_premium
    args_hash = {}
    args_hash["cd_ef"] = 3.48
    expected_num_del_objects = {}
    expected_num_new_objects = {"ElectricEquipmentDefinition"=>1, "ElectricEquipment"=>1, "GasEquipmentDefinition"=>1, "GasEquipment"=>1, "ScheduleRuleset"=>1}
    expected_values = {"Annual_kwh"=>64.0, "Annual_therm"=>29.0}
    _test_measure(osm_geo_beds, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)
  end

  def test_new_construction_mult_0_80
    args_hash = {}
    args_hash["cd_ef"] = 2.75
    args_hash["cd_mult"] = 0.8
    expected_num_del_objects = {}
    expected_num_new_objects = {"ElectricEquipmentDefinition"=>1, "ElectricEquipment"=>1, "GasEquipmentDefinition"=>1, "GasEquipment"=>1, "ScheduleRuleset"=>1}
    expected_values = {"Annual_kwh"=>64.8, "Annual_therm"=>29.4}
    _test_measure(osm_geo_beds, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)
  end

  def test_new_construction_split_0_05
    args_hash = {}
    args_hash["cd_ef"] = 2.75
    args_hash["cd_gas_split"] = 0.05
    expected_num_del_objects = {}
    expected_num_new_objects = {"ElectricEquipmentDefinition"=>1, "ElectricEquipment"=>1, "GasEquipmentDefinition"=>1, "GasEquipment"=>1, "ScheduleRuleset"=>1}
    expected_values = {"Annual_kwh"=>57.8, "Annual_therm"=>37.5}
    _test_measure(osm_geo_beds, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)
  end

  def test_new_construction_estar_washer
    args_hash = {}
    args_hash["cd_ef"] = 2.75
    args_hash["cw_mef"] = 2.47
    args_hash["cw_rated_annual_energy"] = 123.0
    args_hash["cw_drum_volume"] = 3.68
    expected_num_del_objects = {}
    expected_num_new_objects = {"ElectricEquipmentDefinition"=>1, "ElectricEquipment"=>1, "GasEquipmentDefinition"=>1, "GasEquipment"=>1, "ScheduleRuleset"=>1}
    expected_values = {"Annual_kwh"=>62.2, "Annual_therm"=>28.2}
    _test_measure(osm_geo_beds, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)
  end

  def test_new_construction_modified_schedule
    args_hash = {}
    args_hash["cd_ef"] = 2.75
    args_hash["cd_weekday_sch"] = "1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24"
    args_hash["cd_weekend_sch"] = "1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24"
    args_hash["cd_monthly_sch"] = "1,2,3,4,5,6,7,8,9,10,11,12"
    expected_num_del_objects = {}
    expected_num_new_objects = {"ElectricEquipmentDefinition"=>1, "ElectricEquipment"=>1, "GasEquipmentDefinition"=>1, "GasEquipment"=>1, "ScheduleRuleset"=>1}
    expected_values = {"Annual_kwh"=>81.0, "Annual_therm"=>36.7}
    _test_measure(osm_geo_beds, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)
  end

  def test_new_construction_basement
    args_hash = {}
    args_hash["cd_ef"] = 2.75
    args_hash["space"] = Constants.FinishedBasementSpace
    expected_num_del_objects = {}
    expected_num_new_objects = {"ElectricEquipmentDefinition"=>1, "ElectricEquipment"=>1, "GasEquipmentDefinition"=>1, "GasEquipment"=>1, "ScheduleRuleset"=>1}
    expected_values = {"Annual_kwh"=>81.0, "Annual_therm"=>36.7}
    _test_measure(osm_geo_beds, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)
  end

  def test_new_construction_garage
    args_hash = {}
    args_hash["cd_ef"] = 2.75
    args_hash["space"] = Constants.GarageSpace
    expected_num_del_objects = {}
    expected_num_new_objects = {"ElectricEquipmentDefinition"=>1, "ElectricEquipment"=>1, "GasEquipmentDefinition"=>1, "GasEquipment"=>1, "ScheduleRuleset"=>1}
    expected_values = {"Annual_kwh"=>81.0, "Annual_therm"=>36.7}
    _test_measure(osm_geo_beds, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)
  end

  def test_retrofit_replace
    args_hash = {}
    args_hash["cd_ef"] = 2.75
    expected_num_del_objects = {}
    expected_num_new_objects = {"ElectricEquipmentDefinition"=>1, "ElectricEquipment"=>1, "GasEquipmentDefinition"=>1, "GasEquipment"=>1, "ScheduleRuleset"=>1}
    expected_values = {"Annual_kwh"=>81.0, "Annual_therm"=>36.7}
    model = _test_measure(osm_geo_beds, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)
    args_hash = {}
    args_hash["cd_ef"] = 3.48
    expected_num_del_objects = {"ElectricEquipmentDefinition"=>1, "ElectricEquipment"=>1, "GasEquipmentDefinition"=>1, "GasEquipment"=>1, "ScheduleRuleset"=>1}
    expected_num_new_objects = {"ElectricEquipmentDefinition"=>1, "ElectricEquipment"=>1, "GasEquipmentDefinition"=>1, "GasEquipment"=>1, "ScheduleRuleset"=>1}
    expected_values = {"Annual_kwh"=>64.0, "Annual_therm"=>29.0}
    _test_measure(model, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 1)
  end
    
  def test_retrofit_replace_elec_clothes_dryer
    model = get_model(File.dirname(__FILE__), osm_geo_beds_elecdryer)
    args_hash = {}
    args_hash["cd_ef"] = 3.48
    expected_num_del_objects = {"ElectricEquipmentDefinition"=>1, "ElectricEquipment"=>1, "ScheduleRuleset"=>1}
    expected_num_new_objects = {"ElectricEquipmentDefinition"=>1, "ElectricEquipment"=>1, "GasEquipmentDefinition"=>1, "GasEquipment"=>1, "ScheduleRuleset"=>1}
    expected_values = {"Annual_kwh"=>64.0, "Annual_therm"=>29.0}
    _test_measure(model, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 1)
  end

  def test_retrofit_remove
    args_hash = {}
    args_hash["cd_ef"] = 2.75
    expected_num_del_objects = {}
    expected_num_new_objects = {"ElectricEquipmentDefinition"=>1, "ElectricEquipment"=>1, "GasEquipmentDefinition"=>1, "GasEquipment"=>1, "ScheduleRuleset"=>1}
    expected_values = {"Annual_kwh"=>81.0, "Annual_therm"=>36.7}
    model = _test_measure(osm_geo_beds, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)
    args_hash = {}
    args_hash["cd_mult"] = 0.0
    expected_num_del_objects = {"ElectricEquipmentDefinition"=>1, "ElectricEquipment"=>1, "GasEquipmentDefinition"=>1, "GasEquipment"=>1, "ScheduleRuleset"=>1}
    expected_num_new_objects = {}
    expected_values = {"Annual_kwh"=>0, "Annual_therm"=>0}
    _test_measure(model, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 1)
  end
  
  def test_multifamily_new_construction
    num_units = 3
    args_hash = {}
    args_hash["cd_ef"] = 2.75
    expected_num_del_objects = {}
    expected_num_new_objects = {"ElectricEquipmentDefinition"=>num_units, "ElectricEquipment"=>num_units, "GasEquipmentDefinition"=>num_units, "GasEquipment"=>num_units, "ScheduleRuleset"=>1}
    expected_values = {"Annual_kwh"=>229.5, "Annual_therm"=>104.1}
    _test_measure(osm_geo_multifamily_3_units_beds, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, num_units)
  end
  
  def test_multifamily_new_construction_finished_basement
    num_units = 3
    args_hash = {}
    args_hash["cd_ef"] = 2.75
    args_hash["space"] = "finishedbasement_1"
    expected_num_del_objects = {}
    expected_num_new_objects = {"ElectricEquipmentDefinition"=>1, "ElectricEquipment"=>1, "GasEquipmentDefinition"=>1, "GasEquipment"=>1, "ScheduleRuleset"=>1}
    expected_values = {"Annual_kwh"=>81.0, "Annual_therm"=>36.7}
    _test_measure(osm_geo_multifamily_3_units_beds, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)
  end
  
  def test_multifamily_retrofit_replace
    num_units = 3
    args_hash = {}
    args_hash["cd_ef"] = 2.75
    expected_num_del_objects = {}
    expected_num_new_objects = {"ElectricEquipmentDefinition"=>num_units, "ElectricEquipment"=>num_units, "GasEquipmentDefinition"=>num_units, "GasEquipment"=>num_units, "ScheduleRuleset"=>1}
    expected_values = {"Annual_kwh"=>229.5, "Annual_therm"=>104.1}
    model = _test_measure(osm_geo_multifamily_3_units_beds, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, num_units)
    args_hash = {}
    args_hash["cd_ef"] = 3.48
    expected_num_del_objects = {"ElectricEquipmentDefinition"=>num_units, "ElectricEquipment"=>num_units, "GasEquipmentDefinition"=>num_units, "GasEquipment"=>num_units, "ScheduleRuleset"=>1}
    expected_num_new_objects = {"ElectricEquipmentDefinition"=>num_units, "ElectricEquipment"=>num_units, "GasEquipmentDefinition"=>num_units, "GasEquipment"=>num_units, "ScheduleRuleset"=>1}
    expected_values = {"Annual_kwh"=>181.2, "Annual_therm"=>82.2}
    _test_measure(model, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 2*num_units)
  end
  
  def test_multifamily_retrofit_remove
    num_units = 3
    args_hash = {}
    args_hash["cd_ef"] = 2.75
    expected_num_del_objects = {}
    expected_num_new_objects = {"ElectricEquipmentDefinition"=>num_units, "ElectricEquipment"=>num_units, "GasEquipmentDefinition"=>num_units, "GasEquipment"=>num_units, "ScheduleRuleset"=>1}
    expected_values = {"Annual_kwh"=>229.5, "Annual_therm"=>104.1}
    model = _test_measure(osm_geo_multifamily_3_units_beds, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, num_units)
    args_hash = {}
    args_hash["cd_mult"] = 0.0
    expected_num_del_objects = {"ElectricEquipmentDefinition"=>num_units, "ElectricEquipment"=>num_units, "GasEquipmentDefinition"=>num_units, "GasEquipment"=>num_units, "ScheduleRuleset"=>1}
    expected_num_new_objects = {}
    expected_values = {"Annual_kwh"=>0, "Annual_therm"=>0}
    _test_measure(model, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, num_units)
  end
  
  def test_argument_error_cd_ef_negative
    args_hash = {}
    args_hash["cd_ef"] = -1
    result = _test_error(osm_geo_beds, args_hash)
    assert_equal(result_errors(result)[0], "Energy factor must be greater than 0.0.")
  end
  
  def test_argument_error_cd_ef_zero
    args_hash = {}
    args_hash["cd_ef"] = 0
    result = _test_error(osm_geo_beds, args_hash)
    assert_equal(result_errors(result)[0], "Energy factor must be greater than 0.0.")
  end

  def test_argument_error_cd_gas_split_lt_0
    args_hash = {}
    args_hash["cd_gas_split"] = -1
    result = _test_error(osm_geo_beds, args_hash)
    assert_equal(result_errors(result)[0], "Assumed gas electric split must be greater than or equal to 0.0 and less than or equal to 1.0.")
  end
  
  def test_argument_error_cd_gas_split_gt_1
    args_hash = {}
    args_hash["cd_gas_split"] = 2
    result = _test_error(osm_geo_beds, args_hash)
    assert_equal(result_errors(result)[0], "Assumed gas electric split must be greater than or equal to 0.0 and less than or equal to 1.0.")
  end

  def test_argument_error_cd_mult_negative
    args_hash = {}
    args_hash["cd_mult"] = -1
    result = _test_error(osm_geo_beds, args_hash)
    assert_equal(result_errors(result)[0], "Occupancy energy multiplier must be greater than or equal to 0.0.")
  end

  def test_argument_error_weekday_sch_wrong_number_of_values
    args_hash = {}
    args_hash["cd_weekday_sch"] = "1,1"
    result = _test_error(osm_geo_beds, args_hash)
    assert_equal(result_errors(result)[0], "A comma-separated string of 24 numbers must be entered for the weekday schedule.")
  end  

  def test_argument_error_weekday_sch_not_number
    args_hash = {}
    args_hash["cd_weekday_sch"] = "str,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1"
    result = _test_error(osm_geo_beds, args_hash)
    assert_equal(result_errors(result)[0], "A comma-separated string of 24 numbers must be entered for the weekday schedule.")
  end
    
  def test_argument_error_weekend_sch_wrong_number_of_values
    args_hash = {}
    args_hash["cd_weekend_sch"] = "1,1"
    result = _test_error(osm_geo_beds, args_hash)
    assert_equal(result_errors(result)[0], "A comma-separated string of 24 numbers must be entered for the weekend schedule.")
  end
    
  def test_argument_error_weekend_sch_not_number
    args_hash = {}
    args_hash["cd_weekend_sch"] = "str,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1"
    result = _test_error(osm_geo_beds, args_hash)
    assert_equal(result_errors(result)[0], "A comma-separated string of 24 numbers must be entered for the weekend schedule.")
  end
  
  def test_argument_error_monthly_sch_wrong_number_of_values  
    args_hash = {}
    args_hash["cd_monthly_sch"] = "1,1"
    result = _test_error(osm_geo_beds, args_hash)
    assert_equal(result_errors(result)[0], "A comma-separated string of 12 numbers must be entered for the monthly schedule.")
  end
  
  def test_argument_error_monthly_sch_not_number
    args_hash = {}
    args_hash["cd_monthly_sch"] = "str,1,1,1,1,1,1,1,1,1,1,1"
    result = _test_error(osm_geo_beds, args_hash)
    assert_equal(result_errors(result)[0], "A comma-separated string of 12 numbers must be entered for the monthly schedule.")
  end
  
  def test_argument_error_cw_mef_negative
    args_hash = {}
    args_hash["cw_mef"] = -1
    result = _test_error(osm_geo_beds, args_hash)
    assert_equal(result_errors(result)[0], "Clothes washer modified energy factor must be greater than 0.0.")
  end
  
  def test_argument_error_cw_mef_zero
    args_hash = {}
    args_hash["cw_mef"] = 0
    result = _test_error(osm_geo_beds, args_hash)
    assert_equal(result_errors(result)[0], "Clothes washer modified energy factor must be greater than 0.0.")
  end

  def test_argument_error_cw_rated_annual_energy_negative
    args_hash = {}
    args_hash["cw_rated_annual_energy"] = -1.0
    result = _test_error(osm_geo_beds, args_hash)
    assert_equal(result_errors(result)[0], "Clothes washer rated annual consumption must be greater than 0.0.")
  end
  
  def test_argument_error_cw_rated_annual_energy_zero
    args_hash = {}
    args_hash["cw_rated_annual_energy"] = 0.0
    result = _test_error(osm_geo_beds, args_hash)
    assert_equal(result_errors(result)[0], "Clothes washer rated annual consumption must be greater than 0.0.")
  end

  def test_argument_error_cw_drum_volume_negative
    args_hash = {}
    args_hash["cw_drum_volume"] = -1
    result = _test_error(osm_geo_beds, args_hash)
    assert_equal(result_errors(result)[0], "Clothes washer drum volume must be greater than 0.0.")
  end

  def test_argument_error_cw_drum_volume_zero
    args_hash = {}
    args_hash["cw_drum_volume"] = 0
    result = _test_error(osm_geo_beds, args_hash)
    assert_equal(result_errors(result)[0], "Clothes washer drum volume must be greater than 0.0.")
  end

  def test_error_missing_beds
    args_hash = {}
    result = _test_error(osm_geo, args_hash)
    assert_equal(result_errors(result)[0], "Could not determine number of bedrooms or bathrooms. Run the 'Add Residential Bedrooms And Bathrooms' measure first.")
  end
  
  def test_error_missing_geometry
    args_hash = {}
    result = _test_error(nil, args_hash)
    assert_equal(result_errors(result)[0], "Cannot determine number of building units; Building::standardsNumberOfLivingUnits has not been set.")
  end

  private
  
  def _test_error(osm_file, args_hash)
    # create an instance of the measure
    measure = ResidentialClothesDryerGas.new
    
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
    measure = ResidentialClothesDryerGas.new

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
    obj_type_exclusions = ["ScheduleRule", "ScheduleDay", "ScheduleTypeLimits"]
    all_new_objects = get_object_additions(initial_objects, final_objects, obj_type_exclusions)
    all_del_objects = get_object_additions(final_objects, initial_objects, obj_type_exclusions)
    
    # check we have the expected number of new/deleted objects
    check_num_objects(all_new_objects, expected_num_new_objects, "added")
    check_num_objects(all_del_objects, expected_num_del_objects, "deleted")
    
    actual_values = {"Annual_kwh"=>0, "Annual_therm"=>0}
    all_new_objects.each do |obj_type, new_objects|
        new_objects.each do |new_object|
            next if not new_object.respond_to?("to_#{obj_type}")
            new_object = new_object.public_send("to_#{obj_type}").get
            if obj_type == "ElectricEquipment"
                full_load_hrs = Schedule.annual_equivalent_full_load_hrs(model, new_object.schedule.get)
                actual_values["Annual_kwh"] += OpenStudio.convert(full_load_hrs * new_object.designLevel.get * new_object.multiplier, "Wh", "kWh").get
            elsif obj_type == "GasEquipment"
                full_load_hrs = Schedule.annual_equivalent_full_load_hrs(model, new_object.schedule.get)
                actual_values["Annual_therm"] += OpenStudio.convert(full_load_hrs * new_object.designLevel.get * new_object.multiplier, "Wh", "therm").get
            end
        end
    end
    assert_in_epsilon(expected_values["Annual_kwh"], actual_values["Annual_kwh"], 0.01)
    assert_in_epsilon(expected_values["Annual_therm"], actual_values["Annual_therm"], 0.01)

    return model
  end
  
end
