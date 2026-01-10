# frozen_string_literal: true

require 'openstudio'
require_relative '../../hpxml-measures/HPXMLtoOpenStudio/resources/minitest_helper'
require_relative '../main.rb'
require 'fileutils'
require_relative 'util.rb'
require_relative '../../workflow/design'

class EnergyStarDOEEfficientNewHomeVentTest < Minitest::Test
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

  def cfm_per_watt(program_version, hpxml_bldg)
    iecc_zone = hpxml_bldg.climate_and_risk_zones.climate_zone_ieccs[0].zone
    if [ES::SFNationalVer3_0, ES::MFNationalVer1_0, ES::SFPacificVer3_0, ES::SFFloridaVer3_1].include? program_version
      return 2.2
    elsif [ES::SFNationalVer3_1, ES::SFNationalVer3_2, ES::SFOregonWashingtonVer3_2,
           ES::MFNationalVer1_1, ES::MFNationalVer1_2, ES::MFOregonWashingtonVer1_2].include? program_version
      return 2.8
    elsif [ES::SFNationalVer3_3, ES::MFNationalVer1_3].include? program_version
      if ['1A', '1B', '1C', '2A', '2B', '2C', '3A', '3B', '3C', '4A', '4B'].include? iecc_zone
        return 3.8
      elsif ['4C', '5A', '5B', '5C'].include? iecc_zone
        return 2.8
      elsif ['6A', '6B', '6C'].include? iecc_zone
        return 1.2
      end
    elsif [DENH::Ver1].include? program_version
      if ['1A', '1B', '1C', '2A', '2B', '2C', '3A', '3B', '3C', '4A', '4B'].include? iecc_zone
        return 2.8
      elsif ['4C', '5A', '5B', '5C', '6A', '6B', '6C'].include? iecc_zone
        return 1.2
      end
    elsif [DENH::SFVer2, DENH::MFVer2].include? program_version
      if ['1A', '1B', '1C', '2A', '2B', '2C', '3A', '3B', '3C', '4A', '4B'].include? iecc_zone
        return 2.9
      elsif ['4C', '5A', '5B', '5C', '6A', '6B', '6C'].include? iecc_zone
        return 1.2
      end
    else
      fail "Unhandled program version: #{program_version}"
    end
  end

  def fan_type(program_version, hpxml_bldg)
    iecc_zone = hpxml_bldg.climate_and_risk_zones.climate_zone_ieccs[0].zone
    if [ES::SFPacificVer3_0, ES::SFFloridaVer3_1].include? program_version
      return HPXML::MechVentTypeSupply
    elsif [ES::SFOregonWashingtonVer3_2, ES::MFOregonWashingtonVer1_2].include? program_version
      return HPXML::MechVentTypeExhaust
    elsif [DENH::Ver1, DENH::SFVer2, DENH::MFVer2].include? program_version
      if ['1A', '1B', '1C', '2A', '2B', '2C', '3A', '3B', '3C', '4A', '4B'].include? iecc_zone
        return HPXML::MechVentTypeSupply
      elsif ['4C', '5A', '5B', '5C', '6A', '6B', '6C', '7', '8'].include? iecc_zone
        return HPXML::MechVentTypeHRV
      end
    elsif [ES::SFNationalVer3_3, ES::MFNationalVer1_3].include? program_version
      if ['1A', '1B', '1C', '2A', '2B', '2C', '3A', '3B', '3C', '4A', '4B'].include? iecc_zone
        return HPXML::MechVentTypeSupply
      elsif ['4C', '5A', '5B', '5C'].include? iecc_zone
        return HPXML::MechVentTypeExhaust
      elsif ['6A', '6B', '6C', '7', '8'].include? iecc_zone
        return HPXML::MechVentTypeHRV
      end
    elsif [ES::SFNationalVer3_0, ES::SFNationalVer3_1, ES::SFNationalVer3_2,
           ES::MFNationalVer1_0, ES::MFNationalVer1_1, ES::MFNationalVer1_2].include? program_version
      if ['1A', '1B', '1C', '2A', '2B', '2C', '3A', '3B', '3C', '4A', '4B'].include? iecc_zone
        return HPXML::MechVentTypeSupply
      elsif ['4C', '5A', '5B', '5C', '6A', '6B', '6C', '7', '8'].include? iecc_zone
        return HPXML::MechVentTypeExhaust
      end
    else
      fail "Unhandled program version: #{program_version}"
    end
  end

  def sre(program_version, hpxml_bldg)
    iecc_zone = hpxml_bldg.climate_and_risk_zones.climate_zone_ieccs[0].zone
    if ES::AllVersions.include? program_version
      return
    elsif [DENH::Ver1].include? program_version
      if ['1A', '1B', '1C', '2A', '2B', '2C', '3A', '3B', '3C', '4A', '4B'].include? iecc_zone
        return
      elsif ['4C', '5A', '5B', '5C', '6A', '6B', '6C', '7', '8'].include? iecc_zone
        return 0.6
      end
    elsif [ES::SFNationalVer3_3, ES::MFNationalVer1_3].include? program_version
      if ['1A', '1B', '1C', '2A', '2B', '2C', '3A', '3B', '3C', '4A', '4B', '4C', '5A', '5B', '5C'].include? iecc_zone
        return
      elsif ['6A', '6B', '6C', '7', '8'].include? iecc_zone
        return 0.65
      end
    elsif [DENH::SFVer2, DENH::MFVer2].include? program_version
      return
    else
      fail "Unhandled program version: #{program_version}"
    end
  end

  def asre(program_version, hpxml_bldg)
    iecc_zone = hpxml_bldg.climate_and_risk_zones.climate_zone_ieccs[0].zone
    if [DENH::SFVer2, DENH::MFVer2].include? program_version
      if ['1A', '1B', '1C', '2A', '2B', '2C', '3A', '3B', '3C', '4A', '4B'].include? iecc_zone
        return
      elsif ['4C', '5A', '5B', '5C', '6A', '6B', '6C', '7', '8'].include? iecc_zone
        return 0.65
      end
    elsif [ES::SFFloridaVer3_1, ES::SFOregonWashingtonVer3_2, ES::SFPacificVer3_0, ES::SFNationalVer3_0, ES::SFNationalVer3_1, ES::SFNationalVer3_2, ES::SFNationalVer3_3,
           ES::MFOregonWashingtonVer1_2, ES::MFNationalVer1_0, ES::MFNationalVer1_1, ES::MFNationalVer1_2, ES::MFNationalVer1_3,
           DENH::Ver1].include? program_version
      return
    else
      fail "Unhandled program version: #{program_version}"
    end
  end

  def test_mech_vent
    [*ES::AllVersions, *DENH::AllVersions].each do |program_version|
      _convert_to_es_denh('base.xml', program_version)
      hpxml_bldg = _test_ruleset(program_version)
      if [DENH::SFVer2, DENH::MFVer2].include? program_version
        _check_mech_vent(hpxml_bldg, [{ fantype: fan_type(program_version, hpxml_bldg), flowrate: 57.0, hours: 24, power: (57.0 / cfm_per_watt(program_version, hpxml_bldg)), asre: asre(program_version, hpxml_bldg) }])
      elsif [ES::SFFloridaVer3_1, ES::SFOregonWashingtonVer3_2, ES::SFPacificVer3_0, ES::SFNationalVer3_0, ES::SFNationalVer3_1, ES::SFNationalVer3_2, ES::SFNationalVer3_3,
             ES::MFOregonWashingtonVer1_2, ES::MFNationalVer1_0, ES::MFNationalVer1_1, ES::MFNationalVer1_2, ES::MFNationalVer1_3,
             DENH::Ver1].include? program_version
        _check_mech_vent(hpxml_bldg, [{ fantype: fan_type(program_version, hpxml_bldg), flowrate: 57.0, hours: 24, power: (57.0 / cfm_per_watt(program_version, hpxml_bldg)), sre: sre(program_version, hpxml_bldg) }])
      else
        fail "Unhandled program version: #{program_version}"
      end
    end
  end

  def test_mech_vent_attached_housing
    [*ES::AllVersions, *DENH::AllVersions].each do |program_version|
      _convert_to_es_denh('base-bldgtype-mf-unit.xml', program_version)
      hpxml_bldg = _test_ruleset(program_version)
      if [DENH::SFVer2, DENH::MFVer2].include? program_version
        _check_mech_vent(hpxml_bldg, [{ fantype: fan_type(program_version, hpxml_bldg), flowrate: 39.0, hours: 24, power: (39.0 / cfm_per_watt(program_version, hpxml_bldg)), asre: asre(program_version, hpxml_bldg) }])
      elsif [ES::SFFloridaVer3_1, ES::SFOregonWashingtonVer3_2, ES::SFPacificVer3_0, ES::SFNationalVer3_0, ES::SFNationalVer3_1, ES::SFNationalVer3_2, ES::SFNationalVer3_3,
             ES::MFOregonWashingtonVer1_2, ES::MFNationalVer1_0, ES::MFNationalVer1_1, ES::MFNationalVer1_2, ES::MFNationalVer1_3,
             DENH::Ver1].include? program_version
        _check_mech_vent(hpxml_bldg, [{ fantype: fan_type(program_version, hpxml_bldg), flowrate: 39.0, hours: 24, power: (39.0 / cfm_per_watt(program_version, hpxml_bldg)), sre: sre(program_version, hpxml_bldg) }])
      else
        fail "Unhandled program version: #{program_version}"
      end
    end
  end

  def test_mech_vent_erv
    [*ES::AllVersions, *DENH::AllVersions].each do |program_version|
      _convert_to_es_denh('base-mechvent-erv.xml', program_version)
      hpxml_bldg = _test_ruleset(program_version)
      if [DENH::SFVer2, DENH::MFVer2].include? program_version
        _check_mech_vent(hpxml_bldg, [{ fantype: fan_type(program_version, hpxml_bldg), flowrate: 57.0, hours: 24, power: (57.0 / cfm_per_watt(program_version, hpxml_bldg)), asre: asre(program_version, hpxml_bldg) }])
      elsif [ES::SFFloridaVer3_1, ES::SFOregonWashingtonVer3_2, ES::SFPacificVer3_0, ES::SFNationalVer3_0, ES::SFNationalVer3_1, ES::SFNationalVer3_2, ES::SFNationalVer3_3,
             ES::MFOregonWashingtonVer1_2, ES::MFNationalVer1_0, ES::MFNationalVer1_1, ES::MFNationalVer1_2, ES::MFNationalVer1_3,
             DENH::Ver1].include? program_version
        _check_mech_vent(hpxml_bldg, [{ fantype: fan_type(program_version, hpxml_bldg), flowrate: 57.0, hours: 24, power: (57.0 / cfm_per_watt(program_version, hpxml_bldg)), sre: sre(program_version, hpxml_bldg) }])
      else
        fail "Unhandled program version: #{program_version}"
      end
    end
  end

  def test_mech_vent_hrv
    [*ES::AllVersions, *DENH::AllVersions].each do |program_version|
      _convert_to_es_denh('base-mechvent-hrv.xml', program_version)
      hpxml_bldg = _test_ruleset(program_version)
      if [DENH::SFVer2, DENH::MFVer2].include? program_version
        _check_mech_vent(hpxml_bldg, [{ fantype: fan_type(program_version, hpxml_bldg), flowrate: 57.0, hours: 24, power: (57.0 / cfm_per_watt(program_version, hpxml_bldg)), asre: asre(program_version, hpxml_bldg) }])
      elsif [ES::SFFloridaVer3_1, ES::SFOregonWashingtonVer3_2, ES::SFPacificVer3_0, ES::SFNationalVer3_0, ES::SFNationalVer3_1, ES::SFNationalVer3_2, ES::SFNationalVer3_3,
             ES::MFOregonWashingtonVer1_2, ES::MFNationalVer1_0, ES::MFNationalVer1_1, ES::MFNationalVer1_2, ES::MFNationalVer1_3,
             DENH::Ver1].include? program_version
        _check_mech_vent(hpxml_bldg, [{ fantype: fan_type(program_version, hpxml_bldg), flowrate: 57.0, hours: 24, power: (57.0 / cfm_per_watt(program_version, hpxml_bldg)), sre: sre(program_version, hpxml_bldg) }])
      else
        fail "Unhandled program version: #{program_version}"
      end
    end
  end

  def test_mech_vent_nbeds_5
    [*ES::AllVersions, *DENH::AllVersions].each do |program_version|
      _convert_to_es_denh('base-enclosure-beds-5.xml', program_version)
      hpxml_bldg = _test_ruleset(program_version)
      if [DENH::SFVer2, DENH::MFVer2].include? program_version
        _check_mech_vent(hpxml_bldg, [{ fantype: fan_type(program_version, hpxml_bldg), flowrate: 72.0, hours: 24, power: (72.0 / cfm_per_watt(program_version, hpxml_bldg)), asre: asre(program_version, hpxml_bldg) }])
      elsif [ES::SFFloridaVer3_1, ES::SFOregonWashingtonVer3_2, ES::SFPacificVer3_0, ES::SFNationalVer3_0, ES::SFNationalVer3_1, ES::SFNationalVer3_2, ES::SFNationalVer3_3,
             ES::MFOregonWashingtonVer1_2, ES::MFNationalVer1_0, ES::MFNationalVer1_1, ES::MFNationalVer1_2, ES::MFNationalVer1_3,
             DENH::Ver1].include? program_version
        _check_mech_vent(hpxml_bldg, [{ fantype: fan_type(program_version, hpxml_bldg), flowrate: 72.0, hours: 24, power: (72.0 / cfm_per_watt(program_version, hpxml_bldg)), sre: sre(program_version, hpxml_bldg) }])
      else
        fail "Unhandled program version: #{program_version}"
      end
    end
  end

  def test_mech_vent_location_miami_fl
    [*ES::AllVersions, *DENH::AllVersions].each do |program_version|
      _convert_to_es_denh('base-location-miami-fl.xml', program_version)
      hpxml_bldg = _test_ruleset(program_version)
      if [DENH::SFVer2, DENH::MFVer2].include? program_version
        _check_mech_vent(hpxml_bldg, [{ fantype: fan_type(program_version, hpxml_bldg), flowrate: 43.5, hours: 24, power: (43.5 / cfm_per_watt(program_version, hpxml_bldg)), asre: asre(program_version, hpxml_bldg) }])
      elsif [ES::SFFloridaVer3_1, ES::SFOregonWashingtonVer3_2, ES::SFPacificVer3_0, ES::SFNationalVer3_0, ES::SFNationalVer3_1, ES::SFNationalVer3_2, ES::SFNationalVer3_3,
             ES::MFOregonWashingtonVer1_2, ES::MFNationalVer1_0, ES::MFNationalVer1_1, ES::MFNationalVer1_2, ES::MFNationalVer1_3,
             DENH::Ver1].include? program_version
        _check_mech_vent(hpxml_bldg, [{ fantype: fan_type(program_version, hpxml_bldg), flowrate: 43.5, hours: 24, power: (43.5 / cfm_per_watt(program_version, hpxml_bldg)), sre: sre(program_version, hpxml_bldg) }])
      else
        fail "Unhandled program version: #{program_version}"
      end
    end
  end

  def test_mech_vent_attached_housing_location_miami_fl
    [*ES::AllVersions, *DENH::AllVersions].each do |program_version|
      next unless ES::NationalVersions.include?(program_version)

      _convert_to_es_denh('base-bldgtype-mf-unit.xml', program_version)
      hpxml = HPXML.new(hpxml_path: @tmp_hpxml_path)
      hpxml_bldg = hpxml.buildings[0]
      hpxml_bldg.climate_and_risk_zones.climate_zone_ieccs[0].zone = '1A'
      hpxml_bldg.climate_and_risk_zones.weather_station_name = 'Miami, FL'
      hpxml_bldg.climate_and_risk_zones.weather_station_wmo = 722020
      XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
      hpxml_bldg = _test_ruleset(program_version)
      if [DENH::SFVer2, DENH::MFVer2].include? program_version
        _check_mech_vent(hpxml_bldg, [{ fantype: fan_type(program_version, hpxml_bldg), flowrate: 39.0, hours: 24, power: (39.0 / cfm_per_watt(program_version, hpxml_bldg)), asre: asre(program_version, hpxml_bldg) }])
      elsif [ES::SFFloridaVer3_1, ES::SFOregonWashingtonVer3_2, ES::SFPacificVer3_0, ES::SFNationalVer3_0, ES::SFNationalVer3_1, ES::SFNationalVer3_2, ES::SFNationalVer3_3,
             ES::MFOregonWashingtonVer1_2, ES::MFNationalVer1_0, ES::MFNationalVer1_1, ES::MFNationalVer1_2, ES::MFNationalVer1_3,
             DENH::Ver1].include? program_version
        _check_mech_vent(hpxml_bldg, [{ fantype: fan_type(program_version, hpxml_bldg), flowrate: 39.0, hours: 24, power: (39.0 / cfm_per_watt(program_version, hpxml_bldg)), sre: sre(program_version, hpxml_bldg) }])
      else
        fail "Unhandled program version: #{program_version}"
      end
    end
  end

  def test_whole_house_fan
    [*ES::AllVersions, *DENH::AllVersions].each do |program_version|
      _convert_to_es_denh('base-mechvent-whole-house-fan.xml', program_version)
      hpxml_bldg = _test_ruleset(program_version)
      _check_whf(hpxml_bldg)
    end
  end

  def _test_ruleset(program_version)
    print '.'

    if ES::AllVersions.include? program_version
      run_type = RunType::ES
    elsif DENH::AllVersions.include? program_version
      run_type = RunType::DENH
    end
    designs = [Design.new(run_type: run_type,
                          init_calc_type: InitCalcType::TargetHome,
                          output_dir: @sample_files_path,
                          version: program_version)]

    success, errors, _, _, hpxml_bldgs = run_rulesets(@tmp_hpxml_path, designs, @schema_validator, @erivalidator)

    errors.each do |s|
      puts "Error: #{s}"
    end

    # assert that it ran correctly
    assert(success)

    # validate against 301 schematron
    designs.each do |design|
      valid = @erivalidator.validate(design.init_hpxml_output_path)
      puts @erivalidator.errors.map { |e| e.logMessage } unless valid
      assert(valid)
      @results_paths << File.absolute_path(File.join(File.dirname(design.init_hpxml_output_path), '..'))
    end

    return hpxml_bldgs.values[0]
  end

  def _check_mech_vent(hpxml_bldg, all_expected_values = [])
    num_mech_vent = 0
    hpxml_bldg.ventilation_fans.each_with_index do |ventilation_fan, idx|
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

  def _check_whf(hpxml_bldg)
    assert_equal(0, hpxml_bldg.ventilation_fans.select { |f| f.used_for_seasonal_cooling_load_reduction }.size)
  end
end
