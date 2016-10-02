require_relative '../../../test/minitest_helper'
require 'openstudio'
require 'openstudio/ruleset/ShowRunnerOutput'
require 'minitest/autorun'
require_relative '../measure.rb'
require 'fileutils'

class ResidentialPoolPumpTest < MiniTest::Test

  def osm_geo
    return "2000sqft_2story_FB_GRG_UA.osm"
  end
  
  def osm_geo_beds
    return "2000sqft_2story_FB_GRG_UA_3Beds_2Baths.osm"
  end
  
  def osm_geo_multifamily_3_units_beds
    return "multifamily_3_units_Beds_Baths.osm"
  end

  def test_new_construction_none1
    # Using annual energy
    args_hash = {}
    args_hash["base_energy"] = 0.0
    _test_measure(osm_geo_beds, args_hash, 0, 0, 0.0)
  end
  
  def test_new_construction_none2
    # Using energy multiplier
    args_hash = {}
    args_hash["mult"] = 0.0
    _test_measure(osm_geo_beds, args_hash, 0, 0, 0.0)
  end
  
  def test_new_construction_electric
    args_hash = {}
    args_hash["base_energy"] = 2250.0
    _test_measure(osm_geo_beds, args_hash, 0, 1, 2273.4)
  end
  
  def test_new_construction_mult_0_075
    args_hash = {}
    args_hash["base_energy"] = 2250.0
    args_hash["mult"] = 0.075
    _test_measure(osm_geo_beds, args_hash, 0, 1, 170.5)
  end
  
  def test_new_construction_modified_schedule
    args_hash = {}
    args_hash["base_energy"] = 2250.0
    args_hash["weekday_sch"] = "1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24"
    args_hash["weekend_sch"] = "1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24"
    args_hash["monthly_sch"] = "1,2,3,4,5,6,7,8,9,10,11,12"
    _test_measure(osm_geo_beds, args_hash, 0, 1, 2273.4)
  end

  def test_new_construction_no_scale_energy
    args_hash = {}
    args_hash["base_energy"] = 2250.0
    args_hash["scale_energy"] = "false"
    _test_measure(osm_geo_beds, args_hash, 0, 1, 2250.0)
  end

  def test_retrofit_replace
    args_hash = {}
    args_hash["base_energy"] = 2250.0
    model = _test_measure(osm_geo_beds, args_hash, 0, 1, 2273.4)
    args_hash = {}
    args_hash["base_energy"] = 1150.0
    _test_measure(model, args_hash, 1, 1, 1162.0, 1)
  end
  
  def test_retrofit_remove
    args_hash = {}
    args_hash["base_energy"] = 2250.0
    model = _test_measure(osm_geo_beds, args_hash, 0, 1, 2273.4)
    args_hash = {}
    args_hash["base_energy"] = 0.0
    _test_measure(model, args_hash, 1, 0, 0.0, 1)
  end
  
  def test_multifamily_new_construction
    num_units = 3
    args_hash = {}
    args_hash["base_energy"] = 2250.0
    _test_measure(osm_geo_multifamily_3_units_beds, args_hash, 0, num_units, 6017.6, num_units)
  end
  
  def test_multifamily_retrofit_replace
    num_units = 3
    args_hash = {}
    args_hash["base_energy"] = 2250.0
    model = _test_measure(osm_geo_multifamily_3_units_beds, args_hash, 0, num_units, 6017.6, num_units)
    args_hash = {}
    args_hash["base_energy"] = 1125.0
    _test_measure(model, args_hash, num_units, num_units, 3008.8, 2*num_units)
  end
  
  def test_multifamily_retrofit_remove
    num_units = 3
    args_hash = {}
    args_hash["base_energy"] = 2250.0
    model = _test_measure(osm_geo_multifamily_3_units_beds, args_hash, 0, num_units, 6017.6, num_units)
    args_hash = {}
    args_hash["base_energy"] = 0.0
    _test_measure(model, args_hash, num_units, 0, 0.0, num_units)
  end

  def test_argument_error_base_energy_negative
    args_hash = {}
    args_hash["base_energy"] = -1.0
    result = _test_error(osm_geo_beds, args_hash)
    assert_equal(result.errors[0].logMessage, "Base energy use must be greater than or equal to 0.")
  end
  
  def test_argument_error_mult_negative
    args_hash = {}
    args_hash["mult"] = -1.0
    result = _test_error(osm_geo_beds, args_hash)
    assert_equal(result.errors[0].logMessage, "Energy multiplier must be greater than or equal to 0.")
  end
  
  def test_argument_error_weekday_sch_wrong_number_of_values
    args_hash = {}
    args_hash["weekday_sch"] = "1,1"
    result = _test_error(osm_geo_beds, args_hash)
    assert_equal(result.errors[0].logMessage, "A comma-separated string of 24 numbers must be entered for the weekday schedule.")
  end
  
  def test_argument_error_weekday_sch_not_number
    args_hash = {}
    args_hash["weekday_sch"] = "str,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1"
    result = _test_error(osm_geo_beds, args_hash)
    assert_equal(result.errors[0].logMessage, "A comma-separated string of 24 numbers must be entered for the weekday schedule.")
  end
    
  def test_argument_error_weekend_sch_wrong_number_of_values
    args_hash = {}
    args_hash["weekend_sch"] = "1,1"
    result = _test_error(osm_geo_beds, args_hash)
    assert_equal(result.errors[0].logMessage, "A comma-separated string of 24 numbers must be entered for the weekend schedule.")
  end
    
  def test_argument_error_weekend_sch_not_number
    args_hash = {}
    args_hash["weekend_sch"] = "str,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1"
    result = _test_error(osm_geo_beds, args_hash)
    assert_equal(result.errors[0].logMessage, "A comma-separated string of 24 numbers must be entered for the weekend schedule.")
  end
  
  def test_argument_error_monthly_sch_wrong_number_of_values  
    args_hash = {}
    args_hash["monthly_sch"] = "1,1"
    result = _test_error(osm_geo_beds, args_hash)
    assert_equal(result.errors[0].logMessage, "A comma-separated string of 12 numbers must be entered for the monthly schedule.")
  end
  
  def test_argument_error_monthly_sch_not_number
    args_hash = {}
    args_hash["monthly_sch"] = "str,1,1,1,1,1,1,1,1,1,1,1"
    result = _test_error(osm_geo_beds, args_hash)
    assert_equal(result.errors[0].logMessage, "A comma-separated string of 12 numbers must be entered for the monthly schedule.")
  end
  
  def test_error_missing_beds
    args_hash = {}
    result = _test_error(osm_geo, args_hash)
    assert_equal(result.errors[0].logMessage, "Could not determine number of bedrooms or bathrooms. Run the 'Add Residential Bedrooms And Bathrooms' measure first.")
  end
  
  def test_error_missing_geometry
    args_hash = {}
    result = _test_error(nil, args_hash)
    assert_equal(result.errors[0].logMessage, "Cannot determine number of building units; Building::standardsNumberOfLivingUnits has not been set.")
  end

  private
  
  def _test_error(osm_file, args_hash)
    # create an instance of the measure
    measure = ResidentialPoolPump.new

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

  def _test_measure(osm_file_or_model, args_hash, expected_num_del_objects, expected_num_new_objects, expected_annual_kwh, num_infos=0, num_warnings=0)
    # create an instance of the measure
    measure = ResidentialPoolPump.new

    # check for standard methods
    assert(!measure.name.empty?)
    assert(!measure.description.empty?)
    assert(!measure.modeler_description.empty?)

    # create an instance of a runner
    runner = OpenStudio::Ruleset::OSRunner.new

    model = get_model(File.dirname(__FILE__), osm_file_or_model)
    
    # store the original equipment in the seed model
    orig_equip = model.getElectricEquipments

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
    
    # get new/deleted equipment objects
    new_objects = []
    model.getElectricEquipments.each do |equip|
        next if orig_equip.include?(equip)
        new_objects << equip
    end
    del_objects = []
    orig_equip.each do |equip|
        next if model.getElectricEquipments.include?(equip)
        del_objects << equip
    end
    
    # check for num new/del objects
    assert_equal(expected_num_del_objects, del_objects.size)
    assert_equal(expected_num_new_objects, new_objects.size)
    
    actual_annual_kwh = 0.0
    new_objects.each do |new_object|
        # check that the new object has the correct name
        assert(new_object.name.to_s.start_with?(Constants.ObjectNamePoolPump))
        
        # check new object has no internal gains
        assert_equal(new_object.electricEquipmentDefinition.fractionLost, 1.0)
        
        # check for the correct annual energy consumption
        full_load_hrs = Schedule.annual_equivalent_full_load_hrs(model, new_object.schedule.get)
        actual_annual_kwh += OpenStudio.convert(full_load_hrs * new_object.designLevel.get * new_object.multiplier, "Wh", "kWh").get
    end
    assert_in_epsilon(expected_annual_kwh, actual_annual_kwh, 0.01)

    return model
  end
  
end
