# frozen_string_literal: true

require_relative '../../hpxml-measures/HPXMLtoOpenStudio/resources/minitest_helper'
require 'openstudio'
require_relative '../main.rb'
require 'fileutils'
require_relative 'util.rb'

class EnergyStarZeroEnergyReadyHomeVentTest < Minitest::Test
  def setup
    @root_path = File.absolute_path(File.join(File.dirname(__FILE__), '..', '..'))
    @output_dir = File.join(@root_path, 'workflow', 'sample_files')
    @tmp_hpxml_path = File.join(@output_dir, 'tmp.xml')
    schema_path = File.join(@root_path, 'hpxml-measures', 'HPXMLtoOpenStudio', 'resources', 'hpxml_schema', 'HPXML.xsd')
    @schema_validator = XMLValidator.get_schema_validator(schema_path)
    erivalidator_path = File.join(@root_path, 'rulesets', 'resources', '301validator.xml')
    @erivalidator = OpenStudio::XMLValidator.new(erivalidator_path)
  end

  def teardown
    File.delete(@tmp_hpxml_path) if File.exist? @tmp_hpxml_path
    FileUtils.rm_rf(@results_path) if Dir.exist? @results_path
  end

  def cfm_per_watt(program_version, hpxml)
    iecc_zone = hpxml.climate_and_risk_zones.climate_zone_ieccs[0].zone
    if [ESConstants.SFNationalVer3_0, ESConstants.MFNationalVer1_0, ESConstants.SFPacificVer3_0, ESConstants.SFFloridaVer3_1].include? program_version
      return 2.2
    elsif [ESConstants.SFNationalVer3_1, ESConstants.SFNationalVer3_2, ESConstants.SFOregonWashingtonVer3_2,
           ESConstants.MFNationalVer1_1, ESConstants.MFNationalVer1_2, ESConstants.MFOregonWashingtonVer1_2].include? program_version
      return 2.8
    elsif [ZERHConstants.Ver1].include? program_version
      if ['1A', '1B', '1C', '2A', '2B', '2C', '3A', '3B', '3C', '4A', '4B'].include? iecc_zone
        return 2.8
      elsif ['4C', '5A', '5B', '5C', '6A', '6B', '6C'].include? iecc_zone
        return 1.2
      end
    elsif [ZERHConstants.SFVer2].include? program_version
      if ['1A', '1B', '1C', '2A', '2B', '2C', '3A', '3B', '3C', '4A', '4B'].include? iecc_zone
        return 2.9
      elsif ['4C', '5A', '5B', '5C', '6A', '6B', '6C'].include? iecc_zone
        return 1.2
      end
    end
  end

  def fan_type(program_version, hpxml)
    iecc_zone = hpxml.climate_and_risk_zones.climate_zone_ieccs[0].zone
    if [ESConstants.SFPacificVer3_0, ESConstants.SFFloridaVer3_1].include? program_version
      return HPXML::MechVentTypeSupply
    elsif [ESConstants.SFOregonWashingtonVer3_2, ESConstants.MFOregonWashingtonVer1_2].include? program_version
      return HPXML::MechVentTypeExhaust
    elsif [ZERHConstants.Ver1, ZERHConstants.SFVer2].include? program_version
      if ['1A', '1B', '1C', '2A', '2B', '2C', '3A', '3B', '3C', '4A', '4B'].include? iecc_zone
        return HPXML::MechVentTypeSupply
      elsif ['4C', '5A', '5B', '5C', '6A', '6B', '6C', '7', '8'].include? iecc_zone
        return HPXML::MechVentTypeHRV
      end
    else
      if ['1A', '1B', '1C', '2A', '2B', '2C', '3A', '3B', '3C', '4A', '4B'].include? iecc_zone
        return HPXML::MechVentTypeSupply
      elsif ['4C', '5A', '5B', '5C', '6A', '6B', '6C', '7', '8'].include? iecc_zone
        return HPXML::MechVentTypeExhaust
      end
    end
  end

  def sre(program_version, hpxml)
    iecc_zone = hpxml.climate_and_risk_zones.climate_zone_ieccs[0].zone
    if ESConstants.AllVersions.include? program_version
      return
    elsif [ZERHConstants.Ver1].include? program_version
      if ['1A', '1B', '1C', '2A', '2B', '2C', '3A', '3B', '3C', '4A', '4B'].include? iecc_zone
        return
      elsif ['4C', '5A', '5B', '5C', '6A', '6B', '6C', '7', '8'].include? iecc_zone
        return 0.6
      end
    elsif [ZERHConstants.SFVer2].include? program_version
      if ['1A', '1B', '1C', '2A', '2B', '2C', '3A', '3B', '3C', '4A', '4B'].include? iecc_zone
        return
      elsif ['4C', '5A', '5B', '5C', '6A', '6B', '6C', '7', '8'].include? iecc_zone
        return 0.65
      end
    end
  end

  def test_mech_vent
    [*ESConstants.AllVersions, *ZERHConstants.AllVersions].each do |program_version|
      _convert_to_es_zerh('base.xml', program_version)
      hpxml = _test_ruleset(program_version)
      _check_mech_vent(hpxml, [{ fantype: fan_type(program_version, hpxml), flowrate: 57.0, hours: 24, power: (57.0 / cfm_per_watt(program_version, hpxml)), sre: sre(program_version, hpxml) }])
    end
  end

  def test_mech_vent_attached_or_multifamily
    ESConstants.AllVersions.each do |program_version|
      _convert_to_es_zerh('base-bldgtype-multifamily.xml', program_version)
      hpxml = _test_ruleset(program_version)
      _check_mech_vent(hpxml, [{ fantype: fan_type(program_version, hpxml), flowrate: 39.0, hours: 24, power: (39.0 / cfm_per_watt(program_version, hpxml)), sre: sre(program_version, hpxml) }])
    end
  end

  def test_mech_vent_erv
    [*ESConstants.AllVersions, *ZERHConstants.AllVersions].each do |program_version|
      _convert_to_es_zerh('base-mechvent-erv.xml', program_version)
      hpxml = _test_ruleset(program_version)
      _check_mech_vent(hpxml, [{ fantype: fan_type(program_version, hpxml), flowrate: 57.0, hours: 24, power: (57.0 / cfm_per_watt(program_version, hpxml)), sre: sre(program_version, hpxml) }])
    end
  end

  def test_mech_vent_hrv
    [*ESConstants.AllVersions, *ZERHConstants.AllVersions].each do |program_version|
      _convert_to_es_zerh('base-mechvent-hrv.xml', program_version)
      hpxml = _test_ruleset(program_version)
      _check_mech_vent(hpxml, [{ fantype: fan_type(program_version, hpxml), flowrate: 57.0, hours: 24, power: (57.0 / cfm_per_watt(program_version, hpxml)), sre: sre(program_version, hpxml) }])
    end
  end

  def test_mech_vent_nbeds_5
    [*ESConstants.AllVersions, *ZERHConstants.AllVersions].each do |program_version|
      _convert_to_es_zerh('base-enclosure-beds-5.xml', program_version)
      hpxml = _test_ruleset(program_version)
      _check_mech_vent(hpxml, [{ fantype: fan_type(program_version, hpxml), flowrate: 72.0, hours: 24, power: (72.0 / cfm_per_watt(program_version, hpxml)), sre: sre(program_version, hpxml) }])
    end
  end

  def test_mech_vent_location_miami_fl
    [*ESConstants.AllVersions, *ZERHConstants.AllVersions].each do |program_version|
      _convert_to_es_zerh('base-location-miami-fl.xml', program_version)
      hpxml = _test_ruleset(program_version)
      _check_mech_vent(hpxml, [{ fantype: fan_type(program_version, hpxml), flowrate: 43.5, hours: 24, power: (43.5 / cfm_per_watt(program_version, hpxml)), sre: sre(program_version, hpxml) }])
    end
  end

  def test_mech_vent_attached_or_multifamily_location_miami_fl
    [*ESConstants.AllVersions, *ZERHConstants.AllVersions].each do |program_version|
      next unless ESConstants.NationalVersions.include?(program_version)

      _convert_to_es_zerh('base-bldgtype-multifamily.xml', program_version)
      hpxml = HPXML.new(hpxml_path: @tmp_hpxml_path)
      hpxml.climate_and_risk_zones.climate_zone_ieccs.each do |climate_zone_iecc|
        climate_zone_iecc.zone = '1A'
      end
      hpxml.climate_and_risk_zones.weather_station_name = 'Miami, FL'
      hpxml.climate_and_risk_zones.weather_station_wmo = 722020
      XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
      hpxml = _test_ruleset(program_version)
      _check_mech_vent(hpxml, [{ fantype: fan_type(program_version, hpxml), flowrate: 39.0, hours: 24, power: (39.0 / cfm_per_watt(program_version, hpxml)), sre: sre(program_version, hpxml) }])
    end
  end

  def test_whole_house_fan
    [*ESConstants.AllVersions, *ZERHConstants.AllVersions].each do |program_version|
      _convert_to_es_zerh('base-mechvent-whole-house-fan.xml', program_version)
      hpxml = _test_ruleset(program_version)
      _check_whf(hpxml)
    end
  end

  def _test_ruleset(program_version)
    require_relative '../../workflow/design'
    if ESConstants.AllVersions.include? program_version
      designs = [Design.new(init_calc_type: ESConstants.CalcTypeEnergyStarReference,
                            output_dir: @output_dir)]
    elsif ZERHConstants.AllVersions.include? program_version
      designs = [Design.new(init_calc_type: ZERHConstants.CalcTypeZERHReference,
                            output_dir: @output_dir)]
    end

    success, errors, _, _, hpxml = run_rulesets(@tmp_hpxml_path, designs, @schema_validator, @erivalidator)

    errors.each do |s|
      puts "Error: #{s}"
    end

    # assert that it ran correctly
    assert_equal(true, success)

    # validate against 301 schematron
    assert_equal(true, @erivalidator.validate(designs[0].init_hpxml_output_path))
    @results_path = File.dirname(designs[0].init_hpxml_output_path)

    return hpxml
  end

  def _check_mech_vent(hpxml, all_expected_values = [])
    num_mech_vent = 0
    hpxml.ventilation_fans.each_with_index do |ventilation_fan, idx|
      next unless ventilation_fan.used_for_whole_building_ventilation

      expected_values = all_expected_values[idx]
      num_mech_vent += 1
      assert_equal(expected_values[:fantype], ventilation_fan.fan_type)
      assert_in_delta(expected_values[:flowrate], ventilation_fan.rated_flow_rate.to_f + ventilation_fan.tested_flow_rate.to_f, 0.1)
      assert_in_delta(expected_values[:hours], ventilation_fan.hours_in_operation, 0.1)
      assert_in_delta(expected_values[:power], ventilation_fan.fan_power, 0.1)
      if expected_values[:sre].nil?
        assert_nil(ventilation_fan.sensible_recovery_efficiency)
      else
        assert_equal(expected_values[:sre], ventilation_fan.sensible_recovery_efficiency)
      end
      if expected_values[:tre].nil?
        assert_nil(ventilation_fan.total_recovery_efficiency)
      else
        assert_equal(expected_values[:tre], ventilation_fan.total_recovery_efficiency)
      end
      if expected_values[:asre].nil?
        assert_nil(ventilation_fan.sensible_recovery_efficiency_adjusted)
      else
        assert_equal(expected_values[:asre], ventilation_fan.sensible_recovery_efficiency_adjusted)
      end
      if expected_values[:atre].nil?
        assert_nil(ventilation_fan.total_recovery_efficiency_adjusted)
      else
        assert_equal(expected_values[:atre], ventilation_fan.total_recovery_efficiency_adjusted)
      end
      if expected_values[:in_unit_flowrate].nil?
        assert_nil(ventilation_fan.in_unit_flow_rate)
      else
        assert_equal(true, ventilation_fan.is_shared_system)
        assert_in_delta(expected_values[:in_unit_flowrate], ventilation_fan.in_unit_flow_rate, 0.1)
      end
      if expected_values[:frac_recirc].nil?
        assert_nil(ventilation_fan.fraction_recirculation)
      else
        assert_equal(expected_values[:frac_recirc], ventilation_fan.fraction_recirculation)
      end
      if expected_values[:has_preheat].nil? || (not expected_values[:has_preheat])
        assert_nil(ventilation_fan.preheating_fuel)
      else
        refute_nil(ventilation_fan.preheating_fuel)
      end
      if expected_values[:has_precool].nil? || (not expected_values[:has_precool])
        assert_nil(ventilation_fan.precooling_fuel)
      else
        refute_nil(ventilation_fan.precooling_fuel)
      end
    end
    assert_equal(all_expected_values.size, num_mech_vent)
  end

  def _check_whf(hpxml)
    assert_equal(0, hpxml.ventilation_fans.select { |f| f.used_for_seasonal_cooling_load_reduction }.size)
  end

  def _convert_to_es_zerh(hpxml_name, program_version, state_code = nil)
    return convert_to_es_zerh(hpxml_name, program_version, @root_path, @tmp_hpxml_path, state_code)
  end
end
