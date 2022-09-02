# frozen_string_literal: true

require_relative '../../hpxml-measures/HPXMLtoOpenStudio/resources/minitest_helper'
require_relative '../main.rb'
require 'fileutils'
require_relative 'util.rb'

class EnergyStarZeroEnergyReadyHomeApplianceTest < MiniTest::Test
  def setup
    @root_path = File.absolute_path(File.join(File.dirname(__FILE__), '..', '..'))
    @tmp_hpxml_path = File.join(@root_path, 'workflow', 'sample_files', 'tmp.xml')
  end

  def teardown
    File.delete(@tmp_hpxml_path) if File.exist? @tmp_hpxml_path
  end

  def test_appliances_electric
    [*ESConstants.AllVersions, *ZERHConstants.AllVersions].each do |program_version|
      _convert_to_es_zerh('base.xml', program_version)
      hpxml = _test_ruleset(program_version)
      _check_clothes_washer(hpxml, mef: nil, imef: 1.0, annual_kwh: 400, elec_rate: 0.12, gas_rate: 1.09, agc: 27, cap: 3.0, label_usage: 6, location: HPXML::LocationLivingSpace)
      _check_clothes_dryer(hpxml, fuel_type: HPXML::FuelTypeElectricity, ef: nil, cef: 3.01, location: HPXML::LocationLivingSpace)
      _check_dishwasher(hpxml, ef: nil, annual_kwh: 270.0, cap: 12, elec_rate: 0.12, gas_rate: 1.09, agc: 22.23, label_usage: 4, location: HPXML::LocationLivingSpace)
      _check_refrigerator(hpxml, annual_kwh: 423.0, location: HPXML::LocationLivingSpace)
      _check_cooking_range(hpxml, fuel_type: HPXML::FuelTypeElectricity, cook_is_induction: false, oven_is_convection: false, location: HPXML::LocationLivingSpace)
    end
  end

  def test_appliances_modified
    [*ESConstants.AllVersions, *ZERHConstants.AllVersions].each do |program_version|
      _convert_to_es_zerh('base-appliances-modified.xml', program_version)
      hpxml = _test_ruleset(program_version)
      _check_clothes_washer(hpxml, mef: nil, imef: 1.0, annual_kwh: 400, elec_rate: 0.12, gas_rate: 1.09, agc: 27, cap: 3.0, label_usage: 6, location: HPXML::LocationLivingSpace)
      _check_clothes_dryer(hpxml, fuel_type: HPXML::FuelTypeElectricity, ef: nil, cef: 3.01, location: HPXML::LocationLivingSpace)
      _check_dishwasher(hpxml, ef: nil, annual_kwh: 203.0, cap: 6, elec_rate: 0.12, gas_rate: 1.09, agc: 14.20, label_usage: 4, location: HPXML::LocationLivingSpace)
      _check_refrigerator(hpxml, annual_kwh: 423.0, location: HPXML::LocationLivingSpace)
      _check_cooking_range(hpxml, fuel_type: HPXML::FuelTypeElectricity, cook_is_induction: false, oven_is_convection: false, location: HPXML::LocationLivingSpace)
    end
  end

  def test_appliances_gas
    [*ESConstants.AllVersions, *ZERHConstants.AllVersions].each do |program_version|
      _convert_to_es_zerh('base-appliances-gas.xml', program_version)
      hpxml = _test_ruleset(program_version)
      _check_clothes_washer(hpxml, mef: nil, imef: 1.0, annual_kwh: 400, elec_rate: 0.12, gas_rate: 1.09, agc: 27, cap: 3.0, label_usage: 6, location: HPXML::LocationLivingSpace)
      _check_clothes_dryer(hpxml, fuel_type: HPXML::FuelTypeNaturalGas, ef: nil, cef: 3.01, location: HPXML::LocationLivingSpace)
      _check_dishwasher(hpxml, ef: nil, annual_kwh: 270.0, cap: 12, elec_rate: 0.12, gas_rate: 1.09, agc: 22.23, label_usage: 4, location: HPXML::LocationLivingSpace)
      _check_refrigerator(hpxml, annual_kwh: 423.0, location: HPXML::LocationLivingSpace)
      _check_cooking_range(hpxml, fuel_type: HPXML::FuelTypeNaturalGas, cook_is_induction: false, oven_is_convection: false, location: HPXML::LocationLivingSpace)
    end
  end

  def test_appliances_basement
    [*ESConstants.AllVersions, *ZERHConstants.AllVersions].each do |program_version|
      _convert_to_es_zerh('base-foundation-unconditioned-basement.xml', program_version)
      hpxml = _test_ruleset(program_version)
      assert_equal(HPXML::LocationBasementUnconditioned, hpxml.clothes_washers[0].location)
      assert_equal(HPXML::LocationBasementUnconditioned, hpxml.clothes_dryers[0].location)
      assert_equal(HPXML::LocationBasementUnconditioned, hpxml.dishwashers[0].location)
      assert_equal(HPXML::LocationBasementUnconditioned, hpxml.refrigerators[0].location)
      assert_equal(HPXML::LocationBasementUnconditioned, hpxml.cooking_ranges[0].location)
    end
  end

  def test_appliances_none
    [*ESConstants.AllVersions, *ZERHConstants.AllVersions].each do |program_version|
      _convert_to_es_zerh('base-appliances-none.xml', program_version)
      hpxml = _test_ruleset(program_version)
      _check_clothes_washer(hpxml, mef: nil, imef: 1.0, annual_kwh: 400, elec_rate: 0.12, gas_rate: 1.09, agc: 27, cap: 3.0, label_usage: 6, location: HPXML::LocationLivingSpace)
      _check_clothes_dryer(hpxml, fuel_type: HPXML::FuelTypeElectricity, ef: nil, cef: 3.01, location: HPXML::LocationLivingSpace)
      _check_dishwasher(hpxml, ef: nil, annual_kwh: 270.0, cap: 12, elec_rate: 0.12, gas_rate: 1.09, agc: 22.23, label_usage: 4, location: HPXML::LocationLivingSpace)
      _check_refrigerator(hpxml, annual_kwh: 423.0, location: HPXML::LocationLivingSpace)
      _check_cooking_range(hpxml, fuel_type: HPXML::FuelTypeElectricity, cook_is_induction: false, oven_is_convection: false, location: HPXML::LocationLivingSpace)
    end
  end

  def test_appliances_dehumidifier
    [*ESConstants.AllVersions, *ZERHConstants.AllVersions].each do |program_version|
      _convert_to_es_zerh('base.xml', program_version)
      hpxml = _test_ruleset(program_version)
      _check_dehumidifiers(hpxml)

      _convert_to_es_zerh('base-appliances-dehumidifier-multiple.xml', program_version)
      hpxml = _test_ruleset(program_version)
      _check_dehumidifiers(hpxml, [{ type: HPXML::DehumidifierTypePortable, capacity: 40.0, ief: 1.04, rh_setpoint: 0.6, frac_load: 0.5, location: HPXML::LocationLivingSpace },
                                   { type: HPXML::DehumidifierTypePortable, capacity: 30.0, ief: 0.95, rh_setpoint: 0.6, frac_load: 0.25, location: HPXML::LocationLivingSpace }])
    end
  end

  def test_shared_clothes_washers_dryers
    [*ESConstants.AllVersions, *ZERHConstants.AllVersions].each do |program_version|
      _convert_to_es_zerh('base-bldgtype-multifamily-shared-laundry-room.xml', program_version)
      hpxml = _test_ruleset(program_version)
      _check_clothes_washer(hpxml, mef: nil, imef: 1.0, annual_kwh: 400, elec_rate: 0.12, gas_rate: 1.09, agc: 27, cap: 3.0, label_usage: 6, location: HPXML::LocationOtherHeatedSpace)
      _check_clothes_dryer(hpxml, fuel_type: HPXML::FuelTypeElectricity, ef: nil, cef: 3.01, location: HPXML::LocationOtherHeatedSpace)
      _check_dishwasher(hpxml, ef: nil, annual_kwh: 270.0, cap: 12, elec_rate: 0.12, gas_rate: 1.09, agc: 22.23, label_usage: 4, location: HPXML::LocationOtherHeatedSpace)
      _check_refrigerator(hpxml, annual_kwh: 423.0, location: HPXML::LocationLivingSpace)
      _check_cooking_range(hpxml, fuel_type: HPXML::FuelTypeElectricity, cook_is_induction: false, oven_is_convection: false, location: HPXML::LocationLivingSpace)
    end
  end

  def _test_ruleset(program_version)
    require_relative '../../workflow/design'
    if ESConstants.AllVersions.include? program_version
      designs = [Design.new(init_calc_type: ESConstants.CalcTypeEnergyStarReference)]
    elsif ZERHConstants.AllVersions.include? program_version
      designs = [Design.new(init_calc_type: ZERHConstants.CalcTypeZERHReference)]
    end

    success, errors, _, _, hpxml = run_rulesets(@tmp_hpxml_path, designs)

    errors.each do |s|
      puts "Error: #{s}"
    end

    # assert that it ran correctly
    assert_equal(true, success)

    return hpxml
  end

  def _check_clothes_washer(hpxml, mef:, imef:, annual_kwh:, elec_rate:, gas_rate:, agc:, cap:, label_usage:, location:)
    assert_equal(1, hpxml.clothes_washers.size)
    clothes_washer = hpxml.clothes_washers[0]
    assert_equal(location, clothes_washer.location)
    if mef.nil?
      assert_nil(clothes_washer.modified_energy_factor)
      assert_in_epsilon(imef, clothes_washer.integrated_modified_energy_factor, 0.01)
    else
      assert_nil(clothes_washer.integrated_modified_energy_factor)
      assert_in_epsilon(mef, clothes_washer.modified_energy_factor, 0.01)
    end
    assert_in_epsilon(annual_kwh, clothes_washer.rated_annual_kwh, 0.01)
    assert_in_epsilon(elec_rate, clothes_washer.label_electric_rate, 0.01)
    assert_in_epsilon(gas_rate, clothes_washer.label_gas_rate, 0.01)
    assert_in_epsilon(agc, clothes_washer.label_annual_gas_cost, 0.01)
    assert_in_epsilon(cap, clothes_washer.capacity, 0.01)
    assert_in_epsilon(label_usage, clothes_washer.label_usage, 0.01)
  end

  def _check_clothes_dryer(hpxml, fuel_type:, ef:, cef:, control: nil, location:)
    assert_equal(1, hpxml.clothes_dryers.size)
    clothes_dryer = hpxml.clothes_dryers[0]
    assert_equal(location, clothes_dryer.location)
    assert_equal(fuel_type, clothes_dryer.fuel_type)
    if ef.nil?
      assert_nil(clothes_dryer.energy_factor)
      assert_in_epsilon(cef, clothes_dryer.combined_energy_factor, 0.01)
    else
      assert_in_epsilon(ef, clothes_dryer.energy_factor, 0.01)
      assert_nil(clothes_dryer.combined_energy_factor)
    end
    if control.nil?
      assert_nil(clothes_dryer.control_type)
    else
      assert_equal(control, clothes_dryer.control_type)
    end
  end

  def _check_dishwasher(hpxml, ef:, annual_kwh:, cap:, elec_rate:, gas_rate:, agc:, label_usage:, location:)
    assert_equal(1, hpxml.dishwashers.size)
    dishwasher = hpxml.dishwashers[0]
    assert_equal(location, dishwasher.location)
    if ef.nil?
      assert_nil(dishwasher.energy_factor)
      assert_in_epsilon(annual_kwh, dishwasher.rated_annual_kwh, 0.01)
    else
      assert_nil(dishwasher.rated_annual_kwh)
      assert_in_epsilon(ef, dishwasher.energy_factor, 0.01)
    end
    assert_in_epsilon(cap, dishwasher.place_setting_capacity, 0.01)
    assert_in_epsilon(elec_rate, dishwasher.label_electric_rate, 0.01)
    assert_in_epsilon(gas_rate, dishwasher.label_gas_rate, 0.01)
    assert_in_epsilon(agc, dishwasher.label_annual_gas_cost, 0.01)
    assert_in_epsilon(label_usage, dishwasher.label_usage, 0.01)
  end

  def _check_refrigerator(hpxml, annual_kwh:, location:)
    assert_equal(1, hpxml.refrigerators.size)
    refrigerator = hpxml.refrigerators[0]
    assert_equal(location, refrigerator.location)
    assert_in_epsilon(annual_kwh, refrigerator.rated_annual_kwh, 0.01)
  end

  def _check_cooking_range(hpxml, fuel_type:, cook_is_induction:, oven_is_convection:, location:)
    assert_equal(1, hpxml.cooking_ranges.size)
    cooking_range = hpxml.cooking_ranges[0]
    assert_equal(location, cooking_range.location)
    assert_equal(fuel_type, cooking_range.fuel_type)
    assert_equal(cook_is_induction, cooking_range.is_induction)
    assert_equal(1, hpxml.ovens.size)
    oven = hpxml.ovens[0]
    assert_equal(oven_is_convection, oven.is_convection)
  end

  def _check_dehumidifiers(hpxml, all_expected_values = [])
    assert_equal(all_expected_values.size, hpxml.dehumidifiers.size)
    hpxml.dehumidifiers.each_with_index do |dehumidifier, idx|
      expected_values = all_expected_values[idx]
      assert_equal(expected_values[:type], dehumidifier.type)
      assert_equal(expected_values[:location], dehumidifier.location)
      assert_equal(expected_values[:capacity], dehumidifier.capacity)
      if expected_values[:ef].nil?
        assert_nil(dehumidifier.energy_factor)
      else
        assert_equal(expected_values[:ef], dehumidifier.energy_factor)
      end
      if expected_values[:ief].nil?
        assert_nil(dehumidifier.integrated_energy_factor)
      else
        assert_equal(expected_values[:ief], dehumidifier.integrated_energy_factor)
      end
      assert_equal(expected_values[:rh_setpoint], dehumidifier.rh_setpoint)
      assert_equal(expected_values[:frac_load], dehumidifier.fraction_served)
    end
  end

  def _convert_to_es_zerh(hpxml_name, program_version, state_code = nil)
    return convert_to_es_zerh(hpxml_name, program_version, @root_path, @tmp_hpxml_path, state_code)
  end
end
