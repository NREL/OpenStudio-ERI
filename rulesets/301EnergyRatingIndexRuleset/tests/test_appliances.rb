require_relative '../../../workflow/tests/minitest_helper'
require 'openstudio'
require 'openstudio/ruleset/ShowRunnerOutput'
require 'minitest/autorun'
require_relative '../measure.rb'
require 'fileutils'

class ApplianceTest < MiniTest::Test
  def before_setup
    @root_path = File.absolute_path(File.join(File.dirname(__FILE__), '..', '..', '..'))
  end

  def test_appliances_electric
    hpxml_name = 'base.xml'

    # Reference Home
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_clothes_washer(hpxml, nil, 0.331, 704, 0.08, 0.58, 23, 2.874, HPXML::LocationLivingSpace)
    _check_clothes_dryer(hpxml, HPXML::FuelTypeElectricity, nil, 2.62, HPXML::ClothesDryerControlTypeTimer, HPXML::LocationLivingSpace)
    _check_dishwasher(hpxml, nil, 467, 12)
    _check_refrigerator(hpxml, 691.0, HPXML::LocationLivingSpace)
    _check_cooking_range(hpxml, HPXML::FuelTypeElectricity, false, false)

    # Rated Home
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_clothes_washer(hpxml, nil, 1.21, 380, 0.12, 1.09, 27.0, 3.2, HPXML::LocationLivingSpace)
    _check_clothes_dryer(hpxml, HPXML::FuelTypeElectricity, nil, 3.73, HPXML::ClothesDryerControlTypeTimer, HPXML::LocationLivingSpace)
    _check_dishwasher(hpxml, nil, 307, 12)
    _check_refrigerator(hpxml, 650.0, HPXML::LocationLivingSpace)
    _check_cooking_range(hpxml, HPXML::FuelTypeElectricity, false, false)

    # IAD, IAD Reference
    calc_types = [Constants.CalcTypeERIIndexAdjustmentDesign,
                  Constants.CalcTypeERIIndexAdjustmentReferenceHome]
    calc_types.each do |calc_type|
      hpxml = _test_measure(hpxml_name, calc_type)
      _check_clothes_washer(hpxml, nil, 0.331, 704, 0.08, 0.58, 23, 2.874, HPXML::LocationLivingSpace)
      _check_clothes_dryer(hpxml, HPXML::FuelTypeElectricity, nil, 2.62, HPXML::ClothesDryerControlTypeTimer, HPXML::LocationLivingSpace)
      _check_dishwasher(hpxml, nil, 467, 12)
      _check_refrigerator(hpxml, 691.0, HPXML::LocationLivingSpace)
      _check_cooking_range(hpxml, HPXML::FuelTypeElectricity, false, false)
    end
  end

  def test_appliances_modified
    hpxml_name = 'base-appliances-modified.xml'

    # Reference Home
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_clothes_washer(hpxml, nil, 0.331, 704, 0.08, 0.58, 23, 2.874, HPXML::LocationLivingSpace)
    _check_clothes_dryer(hpxml, HPXML::FuelTypeElectricity, nil, 2.62, HPXML::ClothesDryerControlTypeTimer, HPXML::LocationLivingSpace)
    _check_dishwasher(hpxml, nil, 467, 12)
    _check_refrigerator(hpxml, 691.0, HPXML::LocationLivingSpace)
    _check_cooking_range(hpxml, HPXML::FuelTypeElectricity, false, false)

    # Rated Home
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_clothes_washer(hpxml, 1.65, nil, 380, 0.12, 1.09, 27.0, 3.2, HPXML::LocationLivingSpace)
    _check_clothes_dryer(hpxml, HPXML::FuelTypeElectricity, 4.29, nil, HPXML::ClothesDryerControlTypeMoisture, HPXML::LocationLivingSpace)
    _check_dishwasher(hpxml, 0.70, nil, 12)
    _check_refrigerator(hpxml, 650.0, HPXML::LocationLivingSpace)
    _check_cooking_range(hpxml, HPXML::FuelTypeElectricity, false, false)

    # IAD, IAD Reference
    calc_types = [Constants.CalcTypeERIIndexAdjustmentDesign,
                  Constants.CalcTypeERIIndexAdjustmentReferenceHome]
    calc_types.each do |calc_type|
      hpxml = _test_measure(hpxml_name, calc_type)
      _check_clothes_washer(hpxml, nil, 0.331, 704, 0.08, 0.58, 23, 2.874, HPXML::LocationLivingSpace)
      _check_clothes_dryer(hpxml, HPXML::FuelTypeElectricity, nil, 2.62, HPXML::ClothesDryerControlTypeTimer, HPXML::LocationLivingSpace)
      _check_dishwasher(hpxml, nil, 467, 12)
      _check_refrigerator(hpxml, 691.0, HPXML::LocationLivingSpace)
      _check_cooking_range(hpxml, HPXML::FuelTypeElectricity, false, false)
    end
  end

  def test_appliances_gas
    hpxml_name = 'base-appliances-gas.xml'

    # Reference Home
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_clothes_washer(hpxml, nil, 0.331, 704, 0.08, 0.58, 23, 2.874, HPXML::LocationLivingSpace)
    _check_clothes_dryer(hpxml, HPXML::FuelTypeNaturalGas, nil, 2.32, HPXML::ClothesDryerControlTypeTimer, HPXML::LocationLivingSpace)
    _check_dishwasher(hpxml, nil, 467, 12)
    _check_refrigerator(hpxml, 691.0, HPXML::LocationLivingSpace)
    _check_cooking_range(hpxml, HPXML::FuelTypeNaturalGas, false, false)

    # Rated Home
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_clothes_washer(hpxml, nil, 1.21, 380, 0.12, 1.09, 27.0, 3.2, HPXML::LocationLivingSpace)
    _check_clothes_dryer(hpxml, HPXML::FuelTypeNaturalGas, nil, 3.3, HPXML::ClothesDryerControlTypeMoisture, HPXML::LocationLivingSpace)
    _check_dishwasher(hpxml, nil, 307, 12)
    _check_refrigerator(hpxml, 650.0, HPXML::LocationLivingSpace)
    _check_cooking_range(hpxml, HPXML::FuelTypeNaturalGas, false, false)

    # IAD, IAD Reference
    calc_types = [Constants.CalcTypeERIIndexAdjustmentDesign,
                  Constants.CalcTypeERIIndexAdjustmentReferenceHome]
    calc_types.each do |calc_type|
      hpxml = _test_measure(hpxml_name, calc_type)
      _check_clothes_washer(hpxml, nil, 0.331, 704, 0.08, 0.58, 23, 2.874, HPXML::LocationLivingSpace)
      _check_clothes_dryer(hpxml, HPXML::FuelTypeNaturalGas, nil, 2.32, HPXML::ClothesDryerControlTypeTimer, HPXML::LocationLivingSpace)
      _check_dishwasher(hpxml, nil, 467, 12)
      _check_refrigerator(hpxml, 691.0, HPXML::LocationLivingSpace)
      _check_cooking_range(hpxml, HPXML::FuelTypeNaturalGas, false, false)
    end
  end

  def test_appliances_in_basement
    hpxml_name = 'base-foundation-unconditioned-basement.xml'

    # Reference Home
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_clothes_washer(hpxml, nil, 0.331, 704, 0.08, 0.58, 23, 2.874, HPXML::LocationLivingSpace)
    _check_clothes_dryer(hpxml, HPXML::FuelTypeElectricity, nil, 2.62, HPXML::ClothesDryerControlTypeTimer, HPXML::LocationLivingSpace)
    _check_dishwasher(hpxml, nil, 467, 12)
    _check_refrigerator(hpxml, 691.0, HPXML::LocationLivingSpace)
    _check_cooking_range(hpxml, HPXML::FuelTypeElectricity, false, false)

    # Rated Home
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_clothes_washer(hpxml, nil, 1.21, 380, 0.12, 1.09, 27.0, 3.2, HPXML::LocationBasementUnconditioned)
    _check_clothes_dryer(hpxml, HPXML::FuelTypeElectricity, nil, 3.73, HPXML::ClothesDryerControlTypeTimer, HPXML::LocationBasementUnconditioned)
    _check_dishwasher(hpxml, nil, 307, 12)
    _check_refrigerator(hpxml, 650.0, HPXML::LocationBasementUnconditioned)
    _check_cooking_range(hpxml, HPXML::FuelTypeElectricity, false, false)

    # IAD, IAD Reference
    calc_types = [Constants.CalcTypeERIIndexAdjustmentDesign,
                  Constants.CalcTypeERIIndexAdjustmentReferenceHome]
    calc_types.each do |calc_type|
      hpxml = _test_measure(hpxml_name, calc_type)
      _check_clothes_washer(hpxml, nil, 0.331, 704, 0.08, 0.58, 23, 2.874, HPXML::LocationLivingSpace)
      _check_clothes_dryer(hpxml, HPXML::FuelTypeElectricity, nil, 2.62, HPXML::ClothesDryerControlTypeTimer, HPXML::LocationLivingSpace)
      _check_dishwasher(hpxml, nil, 467, 12)
      _check_refrigerator(hpxml, 691.0, HPXML::LocationLivingSpace)
      _check_cooking_range(hpxml, HPXML::FuelTypeElectricity, false, false)
    end
  end

  def _test_measure(hpxml_name, calc_type)
    args_hash = {}
    args_hash['hpxml_input_path'] = File.join(@root_path, 'workflow', 'sample_files', hpxml_name)
    args_hash['calc_type'] = calc_type

    # create an instance of the measure
    measure = EnergyRatingIndex301Measure.new

    # create an instance of a runner
    runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)

    model = OpenStudio::Model::Model.new

    # get arguments
    arguments = measure.arguments(model)
    argument_map = OpenStudio::Measure.convertOSArgumentVectorToMap(arguments)

    # populate argument with specified hash value if specified
    arguments.each do |arg|
      temp_arg_var = arg.clone
      if args_hash.has_key?(arg.name)
        assert(temp_arg_var.setValue(args_hash[arg.name]))
      end
      argument_map[arg.name] = temp_arg_var
    end

    # run the measure
    measure.run(model, runner, argument_map)
    result = runner.result

    # show the output
    show_output(result) unless result.value.valueName == 'Success'

    # assert that it ran correctly
    assert_equal('Success', result.value.valueName)

    return measure.new_hpxml
  end

  def _check_clothes_washer(hpxml, mef, imef, annual_kwh, elec_rate, gas_rate, agc, cap, location)
    assert_equal(1, hpxml.clothes_washers.size)
    clothes_washer = hpxml.clothes_washers[0]
    assert_equal(location, clothes_washer.location)
    if mef.nil?
      assert_nil(clothes_washer.modified_energy_factor)
    else
      assert_in_epsilon(mef, clothes_washer.modified_energy_factor, 0.01)
    end
    if imef.nil?
      assert_nil(clothes_washer.integrated_modified_energy_factor)
    else
      assert_in_epsilon(imef, clothes_washer.integrated_modified_energy_factor, 0.01)
    end
    if annual_kwh.nil?
      assert_nil(clothes_washer.rated_annual_kwh)
    else
      assert_in_epsilon(annual_kwh, clothes_washer.rated_annual_kwh, 0.01)
    end
    if elec_rate.nil?
      assert_nil(clothes_washer.label_electric_rate)
    else
      assert_in_epsilon(elec_rate, clothes_washer.label_electric_rate, 0.01)
    end
    if gas_rate.nil?
      assert_nil(clothes_washer.label_gas_rate)
    else
      assert_in_epsilon(gas_rate, clothes_washer.label_gas_rate, 0.01)
    end
    if agc.nil?
      assert_nil(clothes_washer.label_annual_gas_cost)
    else
      assert_in_epsilon(agc, clothes_washer.label_annual_gas_cost, 0.01)
    end
    if cap.nil?
      assert_nil(clothes_washer.capacity)
    else
      assert_in_epsilon(cap, clothes_washer.capacity, 0.01)
    end
  end

  def _check_clothes_dryer(hpxml, fuel_type, ef, cef, control, location)
    assert_equal(1, hpxml.clothes_dryers.size)
    clothes_dryer = hpxml.clothes_dryers[0]
    assert_equal(location, clothes_dryer.location)
    assert_equal(fuel_type, clothes_dryer.fuel_type)
    if ef.nil?
      assert_nil(clothes_dryer.energy_factor)
    else
      assert_in_epsilon(ef, clothes_dryer.energy_factor, 0.01)
    end
    if cef.nil?
      assert_nil(clothes_dryer.combined_energy_factor)
    else
      assert_in_epsilon(cef, clothes_dryer.combined_energy_factor, 0.01)
    end
    assert_equal(control, clothes_dryer.control_type)
  end

  def _check_dishwasher(hpxml, ef, annual_kwh, cap)
    assert_equal(1, hpxml.dishwashers.size)
    dishwasher = hpxml.dishwashers[0]
    if ef.nil?
      assert_nil(dishwasher.energy_factor)
    else
      assert_in_epsilon(ef, dishwasher.energy_factor, 0.01)
    end
    if annual_kwh.nil?
      assert_nil(dishwasher.rated_annual_kwh)
    else
      assert_in_epsilon(annual_kwh, dishwasher.rated_annual_kwh, 0.01)
    end
    if cap.nil?
      assert_nil(dishwasher.place_setting_capacity)
    else
      assert_in_epsilon(cap, dishwasher.place_setting_capacity, 0.01)
    end
  end

  def _check_refrigerator(hpxml, annual_kwh, location)
    assert_equal(1, hpxml.refrigerators.size)
    refrigerator = hpxml.refrigerators[0]
    assert_equal(location, refrigerator.location)
    assert_in_epsilon(annual_kwh, refrigerator.rated_annual_kwh, 0.01)
  end

  def _check_cooking_range(hpxml, fuel_type, cook_is_induction, oven_is_convection)
    assert_equal(1, hpxml.cooking_ranges.size)
    cooking_range = hpxml.cooking_ranges[0]
    assert_equal(fuel_type, cooking_range.fuel_type)
    assert_equal(cook_is_induction, cooking_range.is_induction)
    assert_equal(1, hpxml.ovens.size)
    oven = hpxml.ovens[0]
    assert_equal(oven_is_convection, oven.is_convection)
  end
end
