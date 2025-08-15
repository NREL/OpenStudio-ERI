# frozen_string_literal: true

require_relative '../../hpxml-measures/HPXMLtoOpenStudio/resources/minitest_helper'
require 'openstudio'
require_relative '../main.rb'
require 'fileutils'
require_relative 'util.rb'
require_relative '../../workflow/design'

class ERIApplianceTest < Minitest::Test
  def setup
    @root_path = File.absolute_path(File.join(File.dirname(__FILE__), '..', '..'))
    @sample_files_path = File.join(@root_path, 'workflow', 'sample_files')
    @tmp_hpxml_path = File.join(@sample_files_path, 'tmp.xml')
    @schema_validator = XMLValidator.get_xml_validator(File.join(@root_path, 'hpxml-measures', 'HPXMLtoOpenStudio', 'resources', 'hpxml_schema', 'HPXML.xsd'))
    @epvalidator = XMLValidator.get_xml_validator(File.join(@root_path, 'hpxml-measures', 'HPXMLtoOpenStudio', 'resources', 'hpxml_schematron', 'EPvalidator.sch'))
    @erivalidator = XMLValidator.get_xml_validator(File.join(@root_path, 'rulesets', 'resources', '301validator.sch'))
    @results_paths = []
  end

  def teardown
    File.delete(@tmp_hpxml_path) if File.exist? @tmp_hpxml_path
    @results_paths.each do |results_path|
      FileUtils.rm_rf(results_path) if Dir.exist? results_path
    end
    @results_paths.clear
    puts
  end

  def test_appliances_electric
    hpxml_name = 'base.xml'

    _test_ruleset(hpxml_name).each do |(_run_type, calc_type), hpxml_bldg|
      if [CalcType::RatedHome].include? calc_type
        _check_clothes_washer(hpxml_bldg, mef: nil, imef: 1.21, annual_kwh: 380, elec_rate: 0.12, gas_rate: 1.09, agc: 27.0, cap: 3.2, label_usage: 6, location: HPXML::LocationConditionedSpace)
        _check_clothes_dryer(hpxml_bldg, fuel_type: HPXML::FuelTypeElectricity, ef: nil, cef: 3.73, location: HPXML::LocationConditionedSpace)
        _check_dishwasher(hpxml_bldg, ef: nil, annual_kwh: 307, cap: 12, elec_rate: 0.12, gas_rate: 1.09, agc: 22.32, label_usage: 4, location: HPXML::LocationConditionedSpace)
        _check_refrigerator(hpxml_bldg, annual_kwh: 650.0, location: HPXML::LocationConditionedSpace)
        _check_cooking_range(hpxml_bldg, fuel_type: HPXML::FuelTypeElectricity, cook_is_induction: false, oven_is_convection: false, location: HPXML::LocationConditionedSpace)
      else
        _check_clothes_washer(hpxml_bldg, mef: nil, imef: 1.0, annual_kwh: 400, elec_rate: 0.12, gas_rate: 1.09, agc: 27, cap: 3.0, label_usage: 6, location: HPXML::LocationConditionedSpace)
        _check_clothes_dryer(hpxml_bldg, fuel_type: HPXML::FuelTypeElectricity, ef: nil, cef: 3.01, location: HPXML::LocationConditionedSpace)
        _check_dishwasher(hpxml_bldg, ef: nil, annual_kwh: 467.0, cap: 12, elec_rate: 0.12, gas_rate: 1.09, agc: 33.12, label_usage: 4, location: HPXML::LocationConditionedSpace)
        _check_refrigerator(hpxml_bldg, annual_kwh: 691.0, location: HPXML::LocationConditionedSpace)
        _check_cooking_range(hpxml_bldg, fuel_type: HPXML::FuelTypeElectricity, cook_is_induction: false, oven_is_convection: false, location: HPXML::LocationConditionedSpace)
      end
    end

    # Test w/ 301-2019 pre-Addendum A
    _test_ruleset(hpxml_name, '2019').each do |(_run_type, calc_type), hpxml_bldg|
      if [CalcType::RatedHome].include? calc_type
        _check_clothes_washer(hpxml_bldg, mef: nil, imef: 1.21, annual_kwh: 380, elec_rate: 0.12, gas_rate: 1.09, agc: 27.0, cap: 3.2, label_usage: 6, location: HPXML::LocationConditionedSpace)
        _check_clothes_dryer(hpxml_bldg, fuel_type: HPXML::FuelTypeElectricity, ef: nil, cef: 3.73, control: HPXML::ClothesDryerControlTypeTimer, location: HPXML::LocationConditionedSpace)
        _check_dishwasher(hpxml_bldg, ef: nil, annual_kwh: 307, cap: 12, elec_rate: 0.12, gas_rate: 1.09, agc: 22.32, label_usage: 4, location: HPXML::LocationConditionedSpace)
        _check_refrigerator(hpxml_bldg, annual_kwh: 650.0, location: HPXML::LocationConditionedSpace)
        _check_cooking_range(hpxml_bldg, fuel_type: HPXML::FuelTypeElectricity, cook_is_induction: false, oven_is_convection: false, location: HPXML::LocationConditionedSpace)
      else
        _check_clothes_washer(hpxml_bldg, mef: nil, imef: 0.331, annual_kwh: 704, elec_rate: 0.08, gas_rate: 0.58, agc: 23, cap: 2.874, label_usage: 999, location: HPXML::LocationConditionedSpace)
        _check_clothes_dryer(hpxml_bldg, fuel_type: HPXML::FuelTypeElectricity, ef: nil, cef: 2.62, control: HPXML::ClothesDryerControlTypeTimer, location: HPXML::LocationConditionedSpace)
        _check_dishwasher(hpxml_bldg, ef: nil, annual_kwh: 467.0, cap: 12, elec_rate: 999, gas_rate: 999, agc: 999, label_usage: 999, location: HPXML::LocationConditionedSpace)
        _check_refrigerator(hpxml_bldg, annual_kwh: 691.0, location: HPXML::LocationConditionedSpace)
        _check_cooking_range(hpxml_bldg, fuel_type: HPXML::FuelTypeElectricity, cook_is_induction: false, oven_is_convection: false, location: HPXML::LocationConditionedSpace)
      end
    end
  end

  def test_appliances_modified
    hpxml_name = 'base-appliances-modified.xml'

    _test_ruleset(hpxml_name).each do |(_run_type, calc_type), hpxml_bldg|
      if [CalcType::RatedHome].include? calc_type
        _check_clothes_washer(hpxml_bldg, mef: 1.65, imef: nil, annual_kwh: 380, elec_rate: 0.12, gas_rate: 1.09, agc: 27.0, cap: 3.2, label_usage: 6, location: HPXML::LocationConditionedSpace)
        _check_clothes_dryer(hpxml_bldg, fuel_type: HPXML::FuelTypeElectricity, ef: 4.29, cef: nil, location: HPXML::LocationConditionedSpace)
        _check_dishwasher(hpxml_bldg, ef: 0.7, annual_kwh: nil, cap: 6, elec_rate: 0.12, gas_rate: 1.09, agc: 22.32, label_usage: 4, location: HPXML::LocationConditionedSpace)
        _check_refrigerator(hpxml_bldg, annual_kwh: 650.0, location: HPXML::LocationConditionedSpace)
        _check_cooking_range(hpxml_bldg, fuel_type: HPXML::FuelTypeElectricity, cook_is_induction: false, oven_is_convection: false, location: HPXML::LocationConditionedSpace)
      else
        _check_clothes_washer(hpxml_bldg, mef: nil, imef: 1.0, annual_kwh: 400, elec_rate: 0.12, gas_rate: 1.09, agc: 27, cap: 3.0, label_usage: 6, location: HPXML::LocationConditionedSpace)
        _check_clothes_dryer(hpxml_bldg, fuel_type: HPXML::FuelTypeElectricity, ef: nil, cef: 3.01, location: HPXML::LocationConditionedSpace)
        _check_dishwasher(hpxml_bldg, ef: nil, annual_kwh: 467.0, cap: 12, elec_rate: 0.12, gas_rate: 1.09, agc: 33.12, label_usage: 4, location: HPXML::LocationConditionedSpace)
        _check_refrigerator(hpxml_bldg, annual_kwh: 691.0, location: HPXML::LocationConditionedSpace)
        _check_cooking_range(hpxml_bldg, fuel_type: HPXML::FuelTypeElectricity, cook_is_induction: false, oven_is_convection: false, location: HPXML::LocationConditionedSpace)
      end
    end

    # Test w/ 301-2019 pre-Addendum A
    _test_ruleset(hpxml_name, '2019').each do |(_run_type, calc_type), hpxml_bldg|
      if [CalcType::RatedHome].include? calc_type
        _check_clothes_washer(hpxml_bldg, mef: 1.65, imef: nil, annual_kwh: 380, elec_rate: 0.12, gas_rate: 1.09, agc: 27.0, cap: 3.2, label_usage: 6, location: HPXML::LocationConditionedSpace)
        _check_clothes_dryer(hpxml_bldg, fuel_type: HPXML::FuelTypeElectricity, ef: 4.29, cef: nil, control: HPXML::ClothesDryerControlTypeTimer, location: HPXML::LocationConditionedSpace)
        _check_dishwasher(hpxml_bldg, ef: 0.7, annual_kwh: nil, cap: 6, elec_rate: 0.12, gas_rate: 1.09, agc: 22.32, label_usage: 4, location: HPXML::LocationConditionedSpace)
        _check_refrigerator(hpxml_bldg, annual_kwh: 650.0, location: HPXML::LocationConditionedSpace)
        _check_cooking_range(hpxml_bldg, fuel_type: HPXML::FuelTypeElectricity, cook_is_induction: false, oven_is_convection: false, location: HPXML::LocationConditionedSpace)
      else
        _check_clothes_washer(hpxml_bldg, mef: nil, imef: 0.331, annual_kwh: 704, elec_rate: 0.08, gas_rate: 0.58, agc: 23, cap: 2.874, label_usage: 999, location: HPXML::LocationConditionedSpace)
        _check_clothes_dryer(hpxml_bldg, fuel_type: HPXML::FuelTypeElectricity, ef: nil, cef: 2.62, control: HPXML::ClothesDryerControlTypeTimer, location: HPXML::LocationConditionedSpace)
        _check_dishwasher(hpxml_bldg, ef: nil, annual_kwh: 467.0, cap: 12, elec_rate: 999, gas_rate: 999, agc: 999, label_usage: 999, location: HPXML::LocationConditionedSpace)
        _check_refrigerator(hpxml_bldg, annual_kwh: 691.0, location: HPXML::LocationConditionedSpace)
        _check_cooking_range(hpxml_bldg, fuel_type: HPXML::FuelTypeElectricity, cook_is_induction: false, oven_is_convection: false, location: HPXML::LocationConditionedSpace)
      end
    end
  end

  def test_appliances_gas
    hpxml_name = 'base-appliances-gas.xml'

    _test_ruleset(hpxml_name).each do |(run_type, calc_type), hpxml_bldg|
      if [CalcType::RatedHome].include? calc_type
        _check_clothes_dryer(hpxml_bldg, fuel_type: HPXML::FuelTypeNaturalGas, ef: nil, cef: 3.3, location: HPXML::LocationConditionedSpace)
        _check_cooking_range(hpxml_bldg, fuel_type: HPXML::FuelTypeNaturalGas, cook_is_induction: false, oven_is_convection: false, location: HPXML::LocationConditionedSpace)
      elsif run_type == RunType::CO2e # All-electric
        _check_clothes_dryer(hpxml_bldg, fuel_type: HPXML::FuelTypeElectricity, ef: nil, cef: 3.01, location: HPXML::LocationConditionedSpace)
        _check_cooking_range(hpxml_bldg, fuel_type: HPXML::FuelTypeElectricity, cook_is_induction: false, oven_is_convection: false, location: HPXML::LocationConditionedSpace)
      else
        _check_clothes_dryer(hpxml_bldg, fuel_type: HPXML::FuelTypeNaturalGas, ef: nil, cef: 3.01, location: HPXML::LocationConditionedSpace)
        _check_cooking_range(hpxml_bldg, fuel_type: HPXML::FuelTypeNaturalGas, cook_is_induction: false, oven_is_convection: false, location: HPXML::LocationConditionedSpace)
      end
    end

    # Test w/ 301-2019 pre-Addendum A
    _test_ruleset(hpxml_name, '2019').each do |(run_type, calc_type), hpxml_bldg|
      if [CalcType::RatedHome].include? calc_type
        _check_clothes_dryer(hpxml_bldg, fuel_type: HPXML::FuelTypeNaturalGas, ef: nil, cef: 3.3, control: HPXML::ClothesDryerControlTypeTimer, location: HPXML::LocationConditionedSpace)
        _check_cooking_range(hpxml_bldg, fuel_type: HPXML::FuelTypeNaturalGas, cook_is_induction: false, oven_is_convection: false, location: HPXML::LocationConditionedSpace)
      elsif run_type == RunType::CO2e # All-electric
        _check_clothes_dryer(hpxml_bldg, fuel_type: HPXML::FuelTypeElectricity, ef: nil, cef: 2.62, control: HPXML::ClothesDryerControlTypeTimer, location: HPXML::LocationConditionedSpace)
        _check_cooking_range(hpxml_bldg, fuel_type: HPXML::FuelTypeElectricity, cook_is_induction: false, oven_is_convection: false, location: HPXML::LocationConditionedSpace)
      else
        _check_clothes_dryer(hpxml_bldg, fuel_type: HPXML::FuelTypeNaturalGas, ef: nil, cef: 2.32, control: HPXML::ClothesDryerControlTypeTimer, location: HPXML::LocationConditionedSpace)
        _check_cooking_range(hpxml_bldg, fuel_type: HPXML::FuelTypeNaturalGas, cook_is_induction: false, oven_is_convection: false, location: HPXML::LocationConditionedSpace)
      end
    end
  end

  def test_appliances_basement
    hpxml_name = 'base-foundation-unconditioned-basement.xml'

    _test_ruleset(hpxml_name).each do |(_run_type, calc_type), hpxml_bldg|
      if [CalcType::ReferenceHome, CalcType::RatedHome].include? calc_type
        location = HPXML::LocationBasementUnconditioned
      else
        location = HPXML::LocationConditionedSpace
      end
      assert_equal(location, hpxml_bldg.clothes_washers[0].location)
      assert_equal(location, hpxml_bldg.clothes_dryers[0].location)
      assert_equal(location, hpxml_bldg.dishwashers[0].location)
      assert_equal(location, hpxml_bldg.refrigerators[0].location)
      assert_equal(location, hpxml_bldg.cooking_ranges[0].location)
    end
  end

  def test_appliances_none
    hpxml_name = 'base-appliances-none.xml'

    _test_ruleset(hpxml_name).each do |(_run_type, _calc_type), hpxml_bldg|
      _check_clothes_washer(hpxml_bldg, mef: nil, imef: 1.0, annual_kwh: 400, elec_rate: 0.12, gas_rate: 1.09, agc: 27, cap: 3.0, label_usage: 6, location: HPXML::LocationConditionedSpace)
      _check_clothes_dryer(hpxml_bldg, fuel_type: HPXML::FuelTypeElectricity, ef: nil, cef: 3.01, location: HPXML::LocationConditionedSpace)
      _check_dishwasher(hpxml_bldg, ef: nil, annual_kwh: 467.0, cap: 12, elec_rate: 0.12, gas_rate: 1.09, agc: 33.12, label_usage: 4, location: HPXML::LocationConditionedSpace)
      _check_refrigerator(hpxml_bldg, annual_kwh: 691.0, location: HPXML::LocationConditionedSpace)
      _check_cooking_range(hpxml_bldg, fuel_type: HPXML::FuelTypeElectricity, cook_is_induction: false, oven_is_convection: false, location: HPXML::LocationConditionedSpace)
    end
  end

  def test_appliances_dehumidifier
    hpxml_name = 'base-appliances-dehumidifier-multiple.xml'

    _test_ruleset(hpxml_name).each do |(_run_type, calc_type), hpxml_bldg|
      if [CalcType::ReferenceHome].include? calc_type
        _check_dehumidifiers(hpxml_bldg, [{ type: HPXML::DehumidifierTypePortable, capacity: 40.0, ief: 1.04, rh_setpoint: 0.6, frac_load: 0.5, location: HPXML::LocationConditionedSpace },
                                          { type: HPXML::DehumidifierTypePortable, capacity: 30.0, ief: 0.95, rh_setpoint: 0.6, frac_load: 0.25, location: HPXML::LocationConditionedSpace }])
      elsif [CalcType::RatedHome].include? calc_type
        _check_dehumidifiers(hpxml_bldg, [{ type: HPXML::DehumidifierTypePortable, capacity: 40.0, ef: 1.8, rh_setpoint: 0.6, frac_load: 0.5, location: HPXML::LocationConditionedSpace },
                                          { type: HPXML::DehumidifierTypePortable, capacity: 30.0, ef: 1.6, rh_setpoint: 0.6, frac_load: 0.25, location: HPXML::LocationConditionedSpace }])
      else
        _check_dehumidifiers(hpxml_bldg)
      end
    end

    # Test w/ 301-2019 pre-Addendum B
    # No credit/penalty for dehumidifiers
    _test_ruleset(hpxml_name, '2019A').each do |(_run_type, _calc_type), hpxml_bldg|
      _check_dehumidifiers(hpxml_bldg)
    end
  end

  def test_shared_clothes_washers_dryers
    hpxml_name = 'base-bldgtype-mf-unit-shared-laundry-room.xml'
    [14, 15].each do |ratio_of_units_to_appliance|
      hpxml = HPXML.new(hpxml_path: File.join(@root_path, 'workflow', 'sample_files', hpxml_name))
      hpxml_bldg = hpxml.buildings[0]
      hpxml_bldg.clothes_washers[0].number_of_units_served = ratio_of_units_to_appliance * hpxml_bldg.clothes_washers[0].count
      hpxml_bldg.clothes_dryers[0].number_of_units_served = ratio_of_units_to_appliance * hpxml_bldg.clothes_dryers[0].count
      hpxml_name = File.basename(@tmp_hpxml_path)
      XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)

      _test_ruleset(hpxml_name).each do |(_run_type, calc_type), hpxml_bldg|
        if ratio_of_units_to_appliance > 14
          # Reference appliances
          _check_clothes_washer(hpxml_bldg, mef: nil, imef: 1.0, annual_kwh: 400, elec_rate: 0.12, gas_rate: 1.09, agc: 27, cap: 3.0, label_usage: 6, location: HPXML::LocationConditionedSpace)
          _check_clothes_dryer(hpxml_bldg, fuel_type: HPXML::FuelTypeElectricity, ef: nil, cef: 3.01, location: HPXML::LocationConditionedSpace)
        else
          # Business as usual
          if [CalcType::RatedHome].include? calc_type
            _check_clothes_washer(hpxml_bldg, mef: nil, imef: 1.21, annual_kwh: 380, elec_rate: 0.12, gas_rate: 1.09, agc: 27.0, cap: 3.2, label_usage: 6, location: HPXML::LocationOtherHeatedSpace)
            _check_clothes_dryer(hpxml_bldg, fuel_type: HPXML::FuelTypeElectricity, ef: nil, cef: 3.73, location: HPXML::LocationOtherHeatedSpace)
          else
            if [CalcType::ReferenceHome].include? calc_type
              location = HPXML::LocationOtherHeatedSpace
            else
              location = HPXML::LocationConditionedSpace
            end
            _check_clothes_washer(hpxml_bldg, mef: nil, imef: 1.0, annual_kwh: 400, elec_rate: 0.12, gas_rate: 1.09, agc: 27, cap: 3.0, label_usage: 6, location: location)
            _check_clothes_dryer(hpxml_bldg, fuel_type: HPXML::FuelTypeElectricity, ef: nil, cef: 3.01, location: location)
          end
        end
      end
    end
  end

  def _test_ruleset(hpxml_name, version = 'latest')
    print '.'

    designs = []
    _all_run_calc_types.each do |run_type, calc_type|
      designs << Design.new(run_type: run_type,
                            calc_type: calc_type,
                            output_dir: @sample_files_path,
                            version: version)
    end

    hpxml_input_path = File.join(@sample_files_path, hpxml_name)
    success, errors, _, _, hpxml_bldgs = run_rulesets(hpxml_input_path, designs, @schema_validator, @erivalidator)

    errors.each do |s|
      puts "Error: #{s}"
    end

    # assert that it ran correctly
    assert(success)

    # validate against OS-HPXML schematron
    designs.each do |design|
      valid = @epvalidator.validate(design.hpxml_output_path)
      puts @epvalidator.errors.map { |e| e.logMessage } unless valid
      assert(valid)
      @results_paths << File.absolute_path(File.join(File.dirname(design.hpxml_output_path), '..'))
    end

    return hpxml_bldgs
  end

  def _expected_dw_ref_energy_gains(eri_version, nbeds)
    if Constants::ERIVersions.index(eri_version) >= Constants::ERIVersions.index('2019A')
      kwh_per_yr = 60 + 24 * nbeds
      sens_btu_per_yr = (168 + 67 * nbeds) * 365.0
      lat_btu_per_yr = (168 + 67 * nbeds) * 365.0
    else
      kwh_per_yr = 78 + 31 * nbeds
      sens_btu_per_yr = (219 + 87 * nbeds) * 365.0
      lat_btu_per_yr = (219 + 87 * nbeds) * 365.0
    end
    return [kwh_per_yr, sens_btu_per_yr, lat_btu_per_yr]
  end

  def _expected_rf_ref_energy_gains(nbeds)
    kwh_per_yr = 637 + 18 * nbeds
    sens_btu_per_yr = (5955 + 168 * nbeds) * 365.0
    lat_btu_per_yr = 0.0
    return [kwh_per_yr, sens_btu_per_yr, lat_btu_per_yr]
  end

  def _expected_cw_ref_energy_gains(eri_version, nbeds)
    if Constants::ERIVersions.index(eri_version) >= Constants::ERIVersions.index('2019A')
      kwh_per_yr = 53.53 + 15.18 * nbeds
      sens_btu_per_yr = (135 + 38 * nbeds) * 365.0
      lat_btu_per_yr = (15 + 4.3 * nbeds) * 365.0
    else
      kwh_per_yr = (38 + 10 * nbeds)
      sens_btu_per_yr = (95 + 26 * nbeds) * 365.0
      lat_btu_per_yr = (11 + 2.8 * nbeds) * 365.0
    end
    return [kwh_per_yr, sens_btu_per_yr, lat_btu_per_yr]
  end

  def _expected_cd_ref_energy_gains(eri_version, nbeds, elec_appl)
    if Constants::ERIVersions.index(eri_version) >= Constants::ERIVersions.index('2019A')
      if elec_appl
        kwh_per_yr = 398 + 113 * nbeds
        therms_per_yr = 0.0
        sens_btu_per_yr = (502.3 + 142.6 * nbeds) * 365.0
        lat_btu_per_yr = (55.8 + 15.8 * nbeds) * 365.0
      else
        kwh_per_yr = 31.5 + 8.93 * nbeds
        therms_per_yr = 14.3 + 4.05 * nbeds
        sens_btu_per_yr = (562.4 + 159.3 * nbeds) * 365.0
        lat_btu_per_yr = (69.4 + 19.7 * nbeds) * 365.0
      end
    else
      if elec_appl
        kwh_per_yr = 524 + 149 * nbeds
        therms_per_yr = 0.0
        sens_btu_per_yr = (661 + 188 * nbeds) * 365.0
        lat_btu_per_yr = (73 + 21 * nbeds) * 365.0
      else
        kwh_per_yr = 41 + 11.7 * nbeds
        therms_per_yr = 18.8 + 5.3 * nbeds
        sens_btu_per_yr = (738 + 209 * nbeds) * 365.0
        lat_btu_per_yr = (91 + 26 * nbeds) * 365.0
      end
    end
    return [kwh_per_yr, therms_per_yr, sens_btu_per_yr, lat_btu_per_yr]
  end

  def _expected_cr_ref_energy_gains(nbeds, elec_appl)
    if elec_appl
      kwh_per_yr = 331 + 39 * nbeds
      therms_per_yr = 0.0
      sens_btu_per_yr = (2228 + 262 * nbeds) * 365.0
      lat_btu_per_yr = (248 + 29 * nbeds) * 365.0
    else
      kwh_per_yr = 22.6 + 2.7 * nbeds
      therms_per_yr = 22.6 + 2.7 * nbeds
      sens_btu_per_yr = (4086 + 488 * nbeds) * 365.0
      lat_btu_per_yr = (1037 + 124 * nbeds) * 365.0
    end
    return [kwh_per_yr, therms_per_yr, sens_btu_per_yr, lat_btu_per_yr]
  end

  def _check_clothes_washer(hpxml_bldg, mef:, imef:, annual_kwh:, elec_rate:, gas_rate:, agc:, cap:, label_usage:, location:)
    assert_equal(1, hpxml_bldg.clothes_washers.size)
    clothes_washer = hpxml_bldg.clothes_washers[0]
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
    assert_equal('0.009, 0.007, 0.004, 0.004, 0.007, 0.011, 0.022, 0.049, 0.073, 0.086, 0.084, 0.075, 0.067, 0.060, 0.049, 0.051, 0.050, 0.049, 0.049, 0.049, 0.049, 0.047, 0.032, 0.017', clothes_washer.weekday_fractions)
    assert_equal('0.009, 0.007, 0.004, 0.004, 0.007, 0.011, 0.022, 0.049, 0.073, 0.086, 0.084, 0.075, 0.067, 0.060, 0.049, 0.051, 0.050, 0.049, 0.049, 0.049, 0.049, 0.047, 0.032, 0.017', clothes_washer.weekend_fractions)
    assert_equal('1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0', clothes_washer.monthly_multipliers)
  end

  def _check_clothes_dryer(hpxml_bldg, fuel_type:, ef:, cef:, control: nil, location:)
    assert_equal(1, hpxml_bldg.clothes_dryers.size)
    clothes_dryer = hpxml_bldg.clothes_dryers[0]
    assert_equal(location, clothes_dryer.location)
    assert_equal(fuel_type, clothes_dryer.fuel_type)
    if ef.nil?
      assert_nil(clothes_dryer.energy_factor)
      assert_in_epsilon(cef, clothes_dryer.combined_energy_factor, 0.01)
    else
      assert_nil(clothes_dryer.combined_energy_factor)
      assert_in_epsilon(ef, clothes_dryer.energy_factor, 0.01)
    end
    if control.nil?
      assert_nil(clothes_dryer.control_type)
    else
      assert_equal(control, clothes_dryer.control_type)
    end
    assert_equal(true, clothes_dryer.is_vented)
    assert_equal(0.0, clothes_dryer.vented_flow_rate)
    assert_equal('0.010, 0.006, 0.004, 0.002, 0.004, 0.006, 0.016, 0.032, 0.048, 0.068, 0.078, 0.081, 0.074, 0.067, 0.058, 0.061, 0.055, 0.054, 0.051, 0.051, 0.052, 0.054, 0.044, 0.024', clothes_dryer.weekday_fractions)
    assert_equal('0.010, 0.006, 0.004, 0.002, 0.004, 0.006, 0.016, 0.032, 0.048, 0.068, 0.078, 0.081, 0.074, 0.067, 0.058, 0.061, 0.055, 0.054, 0.051, 0.051, 0.052, 0.054, 0.044, 0.024', clothes_dryer.weekend_fractions)
    assert_equal('1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0', clothes_dryer.monthly_multipliers)
  end

  def _check_dishwasher(hpxml_bldg, ef:, annual_kwh:, cap:, elec_rate:, gas_rate:, agc:, label_usage:, location:)
    assert_equal(1, hpxml_bldg.dishwashers.size)
    dishwasher = hpxml_bldg.dishwashers[0]
    assert_equal(location, dishwasher.location)
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
    assert_in_epsilon(cap, dishwasher.place_setting_capacity, 0.01)
    assert_in_epsilon(elec_rate, dishwasher.label_electric_rate, 0.01)
    assert_in_epsilon(gas_rate, dishwasher.label_gas_rate, 0.01)
    assert_in_epsilon(agc, dishwasher.label_annual_gas_cost, 0.01)
    assert_in_epsilon(label_usage, dishwasher.label_usage, 0.01)
    assert_equal('0.015, 0.007, 0.005, 0.003, 0.003, 0.010, 0.020, 0.031, 0.058, 0.065, 0.056, 0.048, 0.042, 0.046, 0.036, 0.038, 0.038, 0.049, 0.087, 0.111, 0.090, 0.067, 0.044, 0.031', dishwasher.weekday_fractions)
    assert_equal('0.015, 0.007, 0.005, 0.003, 0.003, 0.010, 0.020, 0.031, 0.058, 0.065, 0.056, 0.048, 0.042, 0.046, 0.036, 0.038, 0.038, 0.049, 0.087, 0.111, 0.090, 0.067, 0.044, 0.031', dishwasher.weekend_fractions)
    assert_equal('1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0', dishwasher.monthly_multipliers)
  end

  def _check_refrigerator(hpxml_bldg, annual_kwh:, location:)
    assert_equal(1, hpxml_bldg.refrigerators.size)
    refrigerator = hpxml_bldg.refrigerators[0]
    assert_equal(location, refrigerator.location)
    assert_equal(annual_kwh, refrigerator.rated_annual_kwh)
    assert_nil(refrigerator.weekday_fractions)
    assert_nil(refrigerator.weekend_fractions)
    assert_nil(refrigerator.monthly_multipliers)
    assert_equal('-0.487, -0.340, -0.370, -0.361, -0.515, -0.684, -0.471, -0.159, -0.079, -0.417, -0.411, -0.386, -0.240, -0.314, -0.160, -0.121, -0.469, -0.412, -0.091, 0.077, -0.118, -0.247, -0.445, -0.544', refrigerator.constant_coefficients)
    assert_equal('0.019, 0.016, 0.017, 0.016, 0.018, 0.021, 0.019, 0.015, 0.015, 0.019, 0.018, 0.018, 0.016, 0.017, 0.015, 0.015, 0.020, 0.020, 0.017, 0.014, 0.016, 0.017, 0.019, 0.020', refrigerator.temperature_coefficients)
  end

  def _check_cooking_range(hpxml_bldg, fuel_type:, cook_is_induction:, oven_is_convection:, location:)
    assert_equal(1, hpxml_bldg.cooking_ranges.size)
    cooking_range = hpxml_bldg.cooking_ranges[0]
    assert_equal(location, cooking_range.location)
    assert_equal(fuel_type, cooking_range.fuel_type)
    assert_equal(cook_is_induction, cooking_range.is_induction)
    assert_equal('0.008, 0.008, 0.008, 0.008, 0.008, 0.015, 0.023, 0.039, 0.046, 0.046, 0.046, 0.054, 0.062, 0.046, 0.039, 0.054, 0.076, 0.134, 0.114, 0.058, 0.039, 0.031, 0.023, 0.015', cooking_range.weekday_fractions)
    assert_equal('0.008, 0.008, 0.008, 0.008, 0.008, 0.015, 0.023, 0.039, 0.046, 0.046, 0.046, 0.054, 0.062, 0.046, 0.039, 0.054, 0.076, 0.134, 0.114, 0.058, 0.039, 0.031, 0.023, 0.015', cooking_range.weekend_fractions)
    assert_equal('1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0', cooking_range.monthly_multipliers)
    assert_equal(1, hpxml_bldg.ovens.size)
    oven = hpxml_bldg.ovens[0]
    assert_equal(oven_is_convection, oven.is_convection)
  end

  def _check_dehumidifiers(hpxml_bldg, all_expected_values = [])
    assert_equal(all_expected_values.size, hpxml_bldg.dehumidifiers.size)
    hpxml_bldg.dehumidifiers.each_with_index do |dehumidifier, idx|
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
end
