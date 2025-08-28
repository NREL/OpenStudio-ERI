# frozen_string_literal: true

require_relative '../../hpxml-measures/HPXMLtoOpenStudio/resources/minitest_helper'
require 'openstudio'
require_relative '../main.rb'
require 'fileutils'
require_relative 'util.rb'
require_relative '../../workflow/design'

class EnergyStarZeroEnergyReadyHomeHVACtest < Minitest::Test
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

  def get_duct_leakage(program_version, value)
    if [ES::SFNationalVer3_1, ES::SFNationalVer3_2, ES::SFNationalVer3_3, ES::SFFloridaVer3_1,
        ES::MFNationalVer1_1, ES::MFNationalVer1_2, ES::MFNationalVer1_3,
        ZERH::SFVer2, ZERH::MFVer2].include? program_version
      return 0.0
    elsif [ZERH::Ver1].include? program_version
      return value
    elsif [ES::SFOregonWashingtonVer3_2, ES::SFPacificVer3_0, ES::SFNationalVer3_0,
           ES::MFOregonWashingtonVer1_2, ES::MFNationalVer1_0].include? program_version
      return [value, 20.0].max # 40 total; 20 each for supply/return
    else
      fail "Unhandled program version: #{program_version}"
    end
  end

  def get_central_ac_seer_cz5(program_version)
    if [ES::SFPacificVer3_0].include? program_version
      return 14.5
    elsif [ES::SFFloridaVer3_1].include? program_version
      return 15.0
    elsif [ES::SFNationalVer3_0, ES::SFNationalVer3_1, ES::SFOregonWashingtonVer3_2, ES::MFNationalVer1_0, ES::MFNationalVer1_1, ES::MFOregonWashingtonVer1_2, ZERH::Ver1].include? program_version
      return 13.0
    elsif [ES::SFNationalVer3_2, ES::SFNationalVer3_3, ES::MFNationalVer1_2, ES::MFNationalVer1_3, ZERH::SFVer2, ZERH::MFVer2].include? program_version
      return 14.0
    else
      fail "Unhandled program version: #{program_version}"
    end
  end

  def get_ashp_seer_cz5(program_version)
    if [ES::SFNationalVer3_1, ES::SFFloridaVer3_1, ES::SFOregonWashingtonVer3_2,
        ES::MFNationalVer1_1, ES::MFOregonWashingtonVer1_2].include? program_version
      return 15.0
    elsif [ES::SFPacificVer3_0, ES::SFNationalVer3_0, ES::MFNationalVer1_0].include? program_version
      return 14.5
    elsif [ZERH::Ver1].include? program_version
      return 13.0
    elsif [ES::SFNationalVer3_2, ES::SFNationalVer3_3,
           ES::MFNationalVer1_2, ES::MFNationalVer1_3,
           ZERH::SFVer2, ZERH::MFVer2].include? program_version
      return 16.0
    else
      fail "Unhandled program version: #{program_version}"
    end
  end

  def get_ashp_eer_cz5(program_version)
    if [ES::SFNationalVer3_1, ES::SFFloridaVer3_1, ES::SFOregonWashingtonVer3_2,
        ES::MFNationalVer1_1, ES::MFOregonWashingtonVer1_2].include? program_version
      return 12.5
    elsif [ES::SFPacificVer3_0, ES::SFNationalVer3_0, ES::MFNationalVer1_0].include? program_version
      return 12.1
    elsif [ZERH::Ver1].include? program_version
      return 13.0
    elsif [ES::SFNationalVer3_2, ES::SFNationalVer3_3,
           ES::MFNationalVer1_2, ES::MFNationalVer1_3,
           ZERH::SFVer2, ZERH::MFVer2].include? program_version
      return 16.0
    else
      fail "Unhandled program version: #{program_version}"
    end
  end

  def get_ashp_seer_cz7(program_version)
    if [ES::SFNationalVer3_1, ES::SFNationalVer3_2, ES::SFNationalVer3_3,
        ES::MFNationalVer1_1, ES::MFNationalVer1_2, ES::MFNationalVer1_3,
        ZERH::SFVer2, ZERH::MFVer2].include? program_version
      return 16.0
    else
      fail "Unhandled program version: #{program_version}"
    end
  end

  def get_ashp_hspf_cz5(program_version)
    if [ES::SFNationalVer3_1, ES::SFNationalVer3_0,
        ES::MFNationalVer1_0, ES::MFNationalVer1_1].include? program_version
      return 9.25
    elsif [ES::SFPacificVer3_0, ES::SFFloridaVer3_1].include? program_version
      return 8.20
    elsif [ES::SFOregonWashingtonVer3_2, ES::SFNationalVer3_3,
           ES::MFOregonWashingtonVer1_2, ES::MFNationalVer1_3,
           ZERH::SFVer2, ZERH::MFVer2].include? program_version
      return 9.50
    elsif [ZERH::Ver1].include? program_version
      return 10.0
    elsif [ES::SFNationalVer3_2, ES::MFNationalVer1_2].include? program_version
      return 9.20
    else
      fail "Unhandled program version: #{program_version}"
    end
  end

  def get_ashp_hspf_cz7(program_version)
    if [ES::SFNationalVer3_1, ES::SFNationalVer3_2,
        ES::MFNationalVer1_1, ES::MFNationalVer1_2].include? program_version
      return 9.20
    elsif [ES::SFNationalVer3_3, ES::MFNationalVer1_3,
           ZERH::SFVer2, ZERH::MFVer2].include? program_version
      return 9.50
    else
      fail "Unhandled program version: #{program_version}"
    end
  end

  def get_gshp_cop_cz5(program_version)
    if [ES::MFNationalVer1_2, ES::MFNationalVer1_1, ES::MFNationalVer1_0].include? program_version
      return 2.7
    elsif [ES::SFNationalVer3_3, ES::MFOregonWashingtonVer1_2, ES::MFNationalVer1_3, ZERH::MFVer2].include? program_version
      return 2.8
    else
      fail "Unhandled program version: #{program_version}"
    end
  end

  def get_gshp_eer_cz5(program_version)
    if [ES::SFNationalVer3_3, ES::MFNationalVer1_2, ES::MFNationalVer1_3, ZERH::MFVer2].include? program_version
      return 14.0
    elsif [ES::MFNationalVer1_1, ES::MFOregonWashingtonVer1_2].include? program_version
      return 13.0
    elsif [ES::MFNationalVer1_0].include? program_version
      return 12.7
    else
      fail "Unhandled program version: #{program_version}"
    end
  end

  def get_gshp_cop_cz7(program_version)
    if [ES::SFNationalVer3_1, ZERH::Ver1].include? program_version
      return 3.6
    elsif [ES::SFNationalVer3_0, ES::SFPacificVer3_0, ES::SFFloridaVer3_1, ES::SFOregonWashingtonVer3_2, ES::MFNationalVer1_0].include? program_version
      return 3.5
    elsif [ES::MFOregonWashingtonVer1_2, ZERH::SFVer2].include? program_version
      return # Never applies
    elsif [ES::MFNationalVer1_2, ES::MFNationalVer1_1].include? program_version
      return 2.7
    elsif [ES::SFNationalVer3_3, ES::MFNationalVer1_3, ZERH::MFVer2].include? program_version
      return 2.8
    else
      fail "Unhandled program version: #{program_version}"
    end
  end

  def get_gshp_eer_cz7(program_version)
    if [ES::SFNationalVer3_1, ES::MFNationalVer1_1, ZERH::Ver1].include? program_version
      return 17.1
    elsif [ES::SFNationalVer3_0, ES::SFPacificVer3_0, ES::SFFloridaVer3_1, ES::SFOregonWashingtonVer3_2, ES::MFNationalVer1_0].include? program_version
      return 16.1
    elsif [ES::MFOregonWashingtonVer1_2, ZERH::SFVer2].include? program_version
      return # Never applies
    elsif [ES::SFNationalVer3_3, ES::MFNationalVer1_2, ES::MFNationalVer1_3, ZERH::MFVer2].include? program_version
      return 14.0
    else
      fail "Unhandled program version: #{program_version}"
    end
  end

  def get_gas_boiler_afue_cz5(program_version)
    if [ES::SFNationalVer3_1, ES::SFOregonWashingtonVer3_2, ES::MFNationalVer1_1, ES::MFOregonWashingtonVer1_2].include? program_version
      return 0.90
    elsif [ES::SFPacificVer3_0, ES::SFFloridaVer3_1].include? program_version
      return 0.80
    elsif [ES::SFNationalVer3_0, ES::MFNationalVer1_0].include? program_version
      return 0.85
    elsif [ZERH::Ver1].include? program_version
      return 0.94
    elsif [ES::SFNationalVer3_2, ES::SFNationalVer3_3, ES::MFNationalVer1_2, ES::MFNationalVer1_3, ZERH::SFVer2, ZERH::MFVer2].include? program_version
      return 0.95
    else
      fail "Unhandled program version: #{program_version}"
    end
  end

  def get_gas_furnace_afue_cz5(program_version)
    if [ES::SFNationalVer3_1, ES::SFNationalVer3_2, ES::SFNationalVer3_3, ES::SFOregonWashingtonVer3_2,
        ES::MFNationalVer1_1, ES::MFNationalVer1_2, ES::MFNationalVer1_3, ES::MFOregonWashingtonVer1_2, ZERH::SFVer2, ZERH::MFVer2].include? program_version
      return 0.95
    elsif [ES::SFPacificVer3_0, ES::SFFloridaVer3_1].include? program_version
      return 0.80
    elsif [ES::SFNationalVer3_0, ES::MFNationalVer1_0].include? program_version
      return 0.90
    elsif [ZERH::Ver1].include? program_version
      return 0.94
    else
      fail "Unhandled program version: #{program_version}"
    end
  end

  def get_oil_furnace_afue_cz5(program_version)
    if [ES::SFNationalVer3_1, ES::SFOregonWashingtonVer3_2, ES::MFNationalVer1_1, ES::MFOregonWashingtonVer1_2].include? program_version
      return 0.85
    elsif [ES::SFPacificVer3_0, ES::SFFloridaVer3_1].include? program_version
      return 0.80
    elsif [ES::SFNationalVer3_0, ES::MFNationalVer1_0].include? program_version
      return 0.85
    elsif [ZERH::Ver1].include? program_version
      return 0.94
    elsif [ZERH::SFVer2, ZERH::MFVer2, ES::SFNationalVer3_3, ES::MFNationalVer1_3].include? program_version
      return 0.95
    else
      fail "Unhandled program version: #{program_version}"
    end
  end

  def get_default_hvac_iq_values(program_version)
    if [ZERH::SFVer2, ZERH::MFVer2].include? program_version
      return { charge_defect_ratio: -0.25,
               airflow_defect_ratio: -0.075,
               fan_watts_per_cfm: 0.45 }
    elsif [ES::SFNationalVer3_2, ES::MFNationalVer1_2].include? program_version
      return { charge_defect_ratio: -0.25,
               airflow_defect_ratio: -0.20,
               fan_watts_per_cfm: 0.52 }
    elsif [ES::SFNationalVer3_3, ES::MFNationalVer1_3].include? program_version
      return { charge_defect_ratio: -0.25,
               airflow_defect_ratio: -0.075,
               fan_watts_per_cfm: 0.52 }
    elsif [ES::SFFloridaVer3_1, ES::SFOregonWashingtonVer3_2, ES::SFPacificVer3_0, ES::SFNationalVer3_0, ES::SFNationalVer3_1,
           ES::MFOregonWashingtonVer1_2, ES::MFNationalVer1_0, ES::MFNationalVer1_1,
           ZERH::Ver1].include? program_version
      # Grade 3 installation quality
      return { charge_defect_ratio: -0.25,
               airflow_defect_ratio: -0.25,
               fan_watts_per_cfm: 0.58 }
    else
      fail "Unhandled program version: #{program_version}"
    end
  end

  def get_eer_from_seer(seer)
    return { 13.0 => 11.3,
             14.0 => 11.9,
             14.5 => 12.2,
             15.0 => 12.4,
             16.0 => 13.0,
             18.0 => 13.8 }[seer]
  end

  def get_compressor_type_from_seer(seer)
    if seer <= 15
      return HPXML::HVACCompressorTypeSingleStage
    else
      return HPXML::HVACCompressorTypeTwoStage
    end
  end

  def test_none
    [*ES::AllVersions, *ZERH::AllVersions].each do |program_version|
      _convert_to_es_zerh('base-hvac-none.xml', program_version)
      hpxml_bldg = _test_ruleset(program_version)
      _check_heating_system(hpxml_bldg)
      _check_cooling_system(hpxml_bldg)
      _check_heat_pump(hpxml_bldg)
      _check_thermostat(hpxml_bldg, control_type: HPXML::HVACControlTypeProgrammable)
      _check_ducts(hpxml_bldg)
      _check_duct_leakage(hpxml_bldg)
    end
  end

  def test_boiler_elec
    [*ES::AllVersions, *ZERH::AllVersions].each do |program_version|
      _convert_to_es_zerh('base-hvac-boiler-elec-only.xml', program_version)
      hpxml_bldg = _test_ruleset(program_version)
      hvac_iq_values = get_default_hvac_iq_values(program_version)
      _check_heating_system(hpxml_bldg)
      _check_cooling_system(hpxml_bldg)
      _check_heat_pump(hpxml_bldg, [{ systype: HPXML::HVACTypeHeatPumpAirToAir, fuel: HPXML::FuelTypeElectricity, hspf: get_ashp_hspf_cz5(program_version), seer: get_ashp_seer_cz5(program_version), frac_load_heat: 1.0, frac_load_cool: 0.0, backup_fuel: HPXML::FuelTypeElectricity, backup_eff: 1.0, **hvac_iq_values }])
      _check_thermostat(hpxml_bldg, control_type: HPXML::HVACControlTypeProgrammable)
      if [ES::SFNationalVer3_0, ES::SFPacificVer3_0, ES::SFOregonWashingtonVer3_2].include? program_version
        _check_ducts(hpxml_bldg, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 0.0, duct_area: 729.0, duct_location: HPXML::LocationBasementConditioned },
                                  { duct_type: HPXML::DuctTypeReturn, duct_rvalue: 0.0, duct_area: 135.0, duct_location: HPXML::LocationBasementConditioned }])
      elsif [ES::SFNationalVer3_1, ES::SFNationalVer3_2, ES::SFNationalVer3_3, ES::SFFloridaVer3_1,
             ES::MFNationalVer1_1, ES::MFNationalVer1_2, ES::MFNationalVer1_3,
             ZERH::Ver1, ZERH::SFVer2, ZERH::MFVer2].include? program_version
        _check_ducts(hpxml_bldg, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 0.0, duct_area: 729.0, duct_location: HPXML::LocationConditionedSpace },
                                  { duct_type: HPXML::DuctTypeReturn, duct_rvalue: 0.0, duct_area: 135.0, duct_location: HPXML::LocationConditionedSpace }])
      elsif [ES::MFOregonWashingtonVer1_2, ES::MFNationalVer1_0].include? program_version
        return_r = (program_version != ES::MFOregonWashingtonVer1_2 ? 6.0 : 8.0)
        _check_ducts(hpxml_bldg, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 8.0, duct_area: 729.0, duct_location: HPXML::LocationAtticVented },
                                  { duct_type: HPXML::DuctTypeReturn, duct_rvalue: return_r, duct_area: 135.0, duct_location: HPXML::LocationAtticVented }])
      else
        fail "Unhandled program version: #{program_version}"
      end
      _check_duct_leakage(hpxml_bldg, [{ duct_type: HPXML::DuctTypeSupply, duct_leakage_units: HPXML::UnitsCFM25, duct_leakage_value: get_duct_leakage(program_version, 54.0), duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside },
                                       { duct_type: HPXML::DuctTypeReturn, duct_leakage_units: HPXML::UnitsCFM25, duct_leakage_value: get_duct_leakage(program_version, 54.0), duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside }])
    end
  end

  def test_boiler_gas
    [*ES::AllVersions, *ZERH::AllVersions].each do |program_version|
      _convert_to_es_zerh('base-hvac-boiler-gas-only.xml', program_version)
      hpxml_bldg = _test_ruleset(program_version)
      _check_heating_system(hpxml_bldg, [{ systype: HPXML::HVACTypeBoiler, fuel: HPXML::FuelTypeNaturalGas, eff: get_gas_boiler_afue_cz5(program_version), frac_load: 1.0 }])
      _check_cooling_system(hpxml_bldg)
      _check_heat_pump(hpxml_bldg)
      _check_thermostat(hpxml_bldg, control_type: HPXML::HVACControlTypeProgrammable)
      _check_ducts(hpxml_bldg)
      _check_duct_leakage(hpxml_bldg)
    end
  end

  def test_furnace_elec
    [*ES::AllVersions, *ZERH::AllVersions].each do |program_version|
      _convert_to_es_zerh('base-hvac-furnace-elec-only.xml', program_version)
      hpxml_bldg = _test_ruleset(program_version)
      hvac_iq_values = get_default_hvac_iq_values(program_version)
      _check_heating_system(hpxml_bldg)
      _check_cooling_system(hpxml_bldg)
      _check_heat_pump(hpxml_bldg, [{ systype: HPXML::HVACTypeHeatPumpAirToAir, fuel: HPXML::FuelTypeElectricity, hspf: get_ashp_hspf_cz5(program_version), seer: get_ashp_seer_cz5(program_version), frac_load_heat: 1.0, frac_load_cool: 0.0, backup_fuel: HPXML::FuelTypeElectricity, backup_eff: 1.0, **hvac_iq_values }])
      _check_thermostat(hpxml_bldg, control_type: HPXML::HVACControlTypeProgrammable)
      if [ES::SFNationalVer3_0, ES::SFPacificVer3_0, ES::SFOregonWashingtonVer3_2].include? program_version
        _check_ducts(hpxml_bldg, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 0.0, duct_area: 729.0, duct_location: HPXML::LocationBasementConditioned },
                                  { duct_type: HPXML::DuctTypeReturn, duct_rvalue: 0.0, duct_area: 270.0, duct_location: HPXML::LocationBasementConditioned }])
      elsif [ES::SFNationalVer3_1, ES::SFNationalVer3_2, ES::SFNationalVer3_3, ES::SFFloridaVer3_1,
             ES::MFNationalVer1_1, ES::MFNationalVer1_2, ES::MFNationalVer1_3,
             ZERH::Ver1, ZERH::SFVer2, ZERH::MFVer2].include? program_version
        _check_ducts(hpxml_bldg, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 0.0, duct_area: 729.0, duct_location: HPXML::LocationConditionedSpace },
                                  { duct_type: HPXML::DuctTypeReturn, duct_rvalue: 0.0, duct_area: 270.0, duct_location: HPXML::LocationConditionedSpace }])
      elsif [ES::MFOregonWashingtonVer1_2, ES::MFNationalVer1_0].include? program_version
        return_r = (program_version != ES::MFOregonWashingtonVer1_2 ? 6.0 : 8.0)
        _check_ducts(hpxml_bldg, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 8.0, duct_area: 729.0, duct_location: HPXML::LocationAtticVented },
                                  { duct_type: HPXML::DuctTypeReturn, duct_rvalue: return_r, duct_area: 270.0, duct_location: HPXML::LocationAtticVented }])
      else
        fail "Unhandled program version: #{program_version}"
      end
      _check_duct_leakage(hpxml_bldg, [{ duct_type: HPXML::DuctTypeSupply, duct_leakage_units: HPXML::UnitsCFM25, duct_leakage_value: get_duct_leakage(program_version, 54.0), duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside },
                                       { duct_type: HPXML::DuctTypeReturn, duct_leakage_units: HPXML::UnitsCFM25, duct_leakage_value: get_duct_leakage(program_version, 54.0), duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside }])
    end
  end

  def test_furnace_gas
    [*ES::AllVersions, *ZERH::AllVersions].each do |program_version|
      _convert_to_es_zerh('base-hvac-furnace-gas-only.xml', program_version)
      hpxml_bldg = _test_ruleset(program_version)
      hvac_iq_values = get_default_hvac_iq_values(program_version)
      _check_heating_system(hpxml_bldg, [{ systype: HPXML::HVACTypeFurnace, fuel: HPXML::FuelTypeNaturalGas, eff: get_gas_furnace_afue_cz5(program_version), frac_load: 1.0, **hvac_iq_values }])
      _check_cooling_system(hpxml_bldg)
      _check_heat_pump(hpxml_bldg)
      _check_thermostat(hpxml_bldg, control_type: HPXML::HVACControlTypeProgrammable)
      if [ES::SFNationalVer3_0, ES::SFPacificVer3_0, ES::SFOregonWashingtonVer3_2].include? program_version
        _check_ducts(hpxml_bldg, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 0.0, duct_area: 729.0, duct_location: HPXML::LocationBasementConditioned },
                                  { duct_type: HPXML::DuctTypeReturn, duct_rvalue: 0.0, duct_area: 270.0, duct_location: HPXML::LocationBasementConditioned }])
      elsif [ES::SFNationalVer3_1, ES::SFNationalVer3_2, ES::SFNationalVer3_3, ES::SFFloridaVer3_1,
             ES::MFNationalVer1_1, ES::MFNationalVer1_2, ES::MFNationalVer1_3,
             ZERH::Ver1, ZERH::SFVer2, ZERH::MFVer2].include? program_version
        _check_ducts(hpxml_bldg, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 0.0, duct_area: 729.0, duct_location: HPXML::LocationConditionedSpace },
                                  { duct_type: HPXML::DuctTypeReturn, duct_rvalue: 0.0, duct_area: 270.0, duct_location: HPXML::LocationConditionedSpace }])
      elsif [ES::MFOregonWashingtonVer1_2, ES::MFNationalVer1_0].include? program_version
        return_r = (program_version != ES::MFOregonWashingtonVer1_2 ? 6.0 : 8.0)
        _check_ducts(hpxml_bldg, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 8.0, duct_area: 729.0, duct_location: HPXML::LocationAtticVented },
                                  { duct_type: HPXML::DuctTypeReturn, duct_rvalue: return_r, duct_area: 270.0, duct_location: HPXML::LocationAtticVented }])
      else
        fail "Unhandled program version: #{program_version}"
      end
      _check_duct_leakage(hpxml_bldg, [{ duct_type: HPXML::DuctTypeSupply, duct_leakage_units: HPXML::UnitsCFM25, duct_leakage_value: get_duct_leakage(program_version, 54.0), duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside },
                                       { duct_type: HPXML::DuctTypeReturn, duct_leakage_units: HPXML::UnitsCFM25, duct_leakage_value: get_duct_leakage(program_version, 54.0), duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside }])
    end
  end

  def test_stove_wood_pellets
    [*ES::AllVersions, *ZERH::AllVersions].each do |program_version|
      _convert_to_es_zerh('base-hvac-stove-wood-pellets-only.xml', program_version)
      hpxml_bldg = _test_ruleset(program_version)
      hvac_iq_values = get_default_hvac_iq_values(program_version)
      _check_heating_system(hpxml_bldg, [{ systype: HPXML::HVACTypeFurnace, fuel: HPXML::FuelTypeNaturalGas, eff: get_gas_furnace_afue_cz5(program_version), frac_load: 1.0, **hvac_iq_values }])
      _check_cooling_system(hpxml_bldg)
      _check_heat_pump(hpxml_bldg)
      _check_thermostat(hpxml_bldg, control_type: HPXML::HVACControlTypeProgrammable)
      if [ES::SFNationalVer3_0, ES::SFPacificVer3_0, ES::SFOregonWashingtonVer3_2].include? program_version
        _check_ducts(hpxml_bldg, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 0.0, duct_area: 729.0, duct_location: HPXML::LocationBasementConditioned },
                                  { duct_type: HPXML::DuctTypeReturn, duct_rvalue: 0.0, duct_area: 135.0, duct_location: HPXML::LocationBasementConditioned }])
      elsif [ES::SFNationalVer3_1, ES::SFNationalVer3_2, ES::SFNationalVer3_3, ES::SFFloridaVer3_1,
             ES::MFNationalVer1_1, ES::MFNationalVer1_2, ES::MFNationalVer1_3,
             ZERH::Ver1, ZERH::SFVer2, ZERH::MFVer2].include? program_version
        _check_ducts(hpxml_bldg, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 0.0, duct_area: 729.0, duct_location: HPXML::LocationConditionedSpace },
                                  { duct_type: HPXML::DuctTypeReturn, duct_rvalue: 0.0, duct_area: 135.0, duct_location: HPXML::LocationConditionedSpace }])
      elsif [ES::MFOregonWashingtonVer1_2, ES::MFNationalVer1_0].include? program_version
        return_r = (program_version != ES::MFOregonWashingtonVer1_2 ? 6.0 : 8.0)
        _check_ducts(hpxml_bldg, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 8.0, duct_area: 729.0, duct_location: HPXML::LocationAtticVented },
                                  { duct_type: HPXML::DuctTypeReturn, duct_rvalue: return_r, duct_area: 135.0, duct_location: HPXML::LocationAtticVented }])
      else
        fail "Unhandled program version: #{program_version}"
      end
      _check_duct_leakage(hpxml_bldg, [{ duct_type: HPXML::DuctTypeSupply, duct_leakage_units: HPXML::UnitsCFM25, duct_leakage_value: get_duct_leakage(program_version, 54.0), duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside },
                                       { duct_type: HPXML::DuctTypeReturn, duct_leakage_units: HPXML::UnitsCFM25, duct_leakage_value: get_duct_leakage(program_version, 54.0), duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside }])
    end
  end

  def test_wall_furnace_elec
    [*ES::AllVersions, *ZERH::AllVersions].each do |program_version|
      _convert_to_es_zerh('base-hvac-wall-furnace-elec-only.xml', program_version)
      hpxml_bldg = _test_ruleset(program_version)
      hvac_iq_values = get_default_hvac_iq_values(program_version)
      _check_heating_system(hpxml_bldg)
      _check_cooling_system(hpxml_bldg)
      _check_heat_pump(hpxml_bldg, [{ systype: HPXML::HVACTypeHeatPumpAirToAir, fuel: HPXML::FuelTypeElectricity, hspf: get_ashp_hspf_cz5(program_version), seer: get_ashp_seer_cz5(program_version), frac_load_heat: 1.0, frac_load_cool: 0.0, backup_fuel: HPXML::FuelTypeElectricity, backup_eff: 1.0, **hvac_iq_values }])
      _check_thermostat(hpxml_bldg, control_type: HPXML::HVACControlTypeProgrammable)
      if [ES::SFNationalVer3_0, ES::SFPacificVer3_0, ES::SFOregonWashingtonVer3_2].include? program_version
        _check_ducts(hpxml_bldg, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 0.0, duct_area: 729.0, duct_location: HPXML::LocationBasementConditioned },
                                  { duct_type: HPXML::DuctTypeReturn, duct_rvalue: 0.0, duct_area: 135.0, duct_location: HPXML::LocationBasementConditioned }])
      elsif [ES::SFNationalVer3_1, ES::SFNationalVer3_2, ES::SFNationalVer3_3, ES::SFFloridaVer3_1,
             ES::MFNationalVer1_1, ES::MFNationalVer1_2, ES::MFNationalVer1_3,
             ZERH::Ver1, ZERH::SFVer2, ZERH::MFVer2].include? program_version
        _check_ducts(hpxml_bldg, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 0.0, duct_area: 729.0, duct_location: HPXML::LocationConditionedSpace },
                                  { duct_type: HPXML::DuctTypeReturn, duct_rvalue: 0.0, duct_area: 135.0, duct_location: HPXML::LocationConditionedSpace }])
      elsif [ES::MFOregonWashingtonVer1_2, ES::MFNationalVer1_0].include? program_version
        return_r = (program_version != ES::MFOregonWashingtonVer1_2 ? 6.0 : 8.0)
        _check_ducts(hpxml_bldg, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 8.0, duct_area: 729.0, duct_location: HPXML::LocationAtticVented },
                                  { duct_type: HPXML::DuctTypeReturn, duct_rvalue: return_r, duct_area: 135.0, duct_location: HPXML::LocationAtticVented }])
      else
        fail "Unhandled program version: #{program_version}"
      end
      _check_duct_leakage(hpxml_bldg, [{ duct_type: HPXML::DuctTypeSupply, duct_leakage_units: HPXML::UnitsCFM25, duct_leakage_value: get_duct_leakage(program_version, 54.0), duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside },
                                       { duct_type: HPXML::DuctTypeReturn, duct_leakage_units: HPXML::UnitsCFM25, duct_leakage_value: get_duct_leakage(program_version, 54.0), duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside }])
    end
  end

  def test_elec_resistance
    [*ES::AllVersions, *ZERH::AllVersions].each do |program_version|
      _convert_to_es_zerh('base-hvac-elec-resistance-only.xml', program_version)
      hpxml_bldg = _test_ruleset(program_version)
      hvac_iq_values = get_default_hvac_iq_values(program_version)
      _check_heating_system(hpxml_bldg)
      _check_cooling_system(hpxml_bldg)
      _check_heat_pump(hpxml_bldg, [{ systype: HPXML::HVACTypeHeatPumpAirToAir, fuel: HPXML::FuelTypeElectricity, hspf: get_ashp_hspf_cz5(program_version), seer: get_ashp_seer_cz5(program_version), frac_load_heat: 1.0, frac_load_cool: 0.0, backup_fuel: HPXML::FuelTypeElectricity, backup_eff: 1.0, **hvac_iq_values }])
      _check_thermostat(hpxml_bldg, control_type: HPXML::HVACControlTypeProgrammable)
      if [ES::SFNationalVer3_0, ES::SFPacificVer3_0, ES::SFOregonWashingtonVer3_2].include? program_version
        _check_ducts(hpxml_bldg, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 0.0, duct_area: 729.0, duct_location: HPXML::LocationBasementConditioned },
                                  { duct_type: HPXML::DuctTypeReturn, duct_rvalue: 0.0, duct_area: 135.0, duct_location: HPXML::LocationBasementConditioned }])
      elsif [ES::SFNationalVer3_1, ES::SFNationalVer3_2, ES::SFNationalVer3_3, ES::SFFloridaVer3_1,
             ES::MFNationalVer1_1, ES::MFNationalVer1_2, ES::MFNationalVer1_3,
             ZERH::Ver1, ZERH::SFVer2, ZERH::MFVer2].include? program_version
        _check_ducts(hpxml_bldg, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 0.0, duct_area: 729.0, duct_location: HPXML::LocationConditionedSpace },
                                  { duct_type: HPXML::DuctTypeReturn, duct_rvalue: 0.0, duct_area: 135.0, duct_location: HPXML::LocationConditionedSpace }])
      elsif [ES::MFOregonWashingtonVer1_2, ES::MFNationalVer1_0].include? program_version
        return_r = (program_version != ES::MFOregonWashingtonVer1_2 ? 6.0 : 8.0)
        _check_ducts(hpxml_bldg, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 8.0, duct_area: 729.0, duct_location: HPXML::LocationAtticVented },
                                  { duct_type: HPXML::DuctTypeReturn, duct_rvalue: return_r, duct_area: 135.0, duct_location: HPXML::LocationAtticVented }])
      else
        fail "Unhandled program version: #{program_version}"
      end
      _check_duct_leakage(hpxml_bldg, [{ duct_type: HPXML::DuctTypeSupply, duct_leakage_units: HPXML::UnitsCFM25, duct_leakage_value: get_duct_leakage(program_version, 54.0), duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside },
                                       { duct_type: HPXML::DuctTypeReturn, duct_leakage_units: HPXML::UnitsCFM25, duct_leakage_value: get_duct_leakage(program_version, 54.0), duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside }])

      next unless [*ES::NationalVersions, *ZERH::AllVersions].include?(program_version)

      # Test in climate zone 7
      _convert_to_es_zerh('base-hvac-elec-resistance-only.xml', program_version)
      hpxml = HPXML.new(hpxml_path: @tmp_hpxml_path)
      hpxml_bldg = hpxml.buildings[0]
      hpxml_bldg.climate_and_risk_zones.climate_zone_ieccs[0].zone = '7'
      hpxml_bldg.climate_and_risk_zones.weather_station_name = 'Duluth, MN'
      hpxml_bldg.climate_and_risk_zones.weather_station_wmo = 727450
      XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
      hpxml_bldg = _test_ruleset(program_version)
      hvac_iq_values = get_default_hvac_iq_values(program_version)
      _check_heating_system(hpxml_bldg)
      _check_cooling_system(hpxml_bldg)
      if [ES::SFNationalVer3_1, ES::SFNationalVer3_2, ES::SFNationalVer3_3,
          ES::MFNationalVer1_1, ES::MFNationalVer1_2, ES::MFNationalVer1_3,
          ZERH::SFVer2, ZERH::MFVer2].include? program_version
        _check_heat_pump(hpxml_bldg, [{ systype: HPXML::HVACTypeHeatPumpAirToAir, fuel: HPXML::FuelTypeElectricity, hspf: get_ashp_hspf_cz7(program_version), seer: get_ashp_seer_cz7(program_version), frac_load_heat: 1.0, frac_load_cool: 0.0, backup_fuel: HPXML::FuelTypeElectricity, backup_eff: 1.0, **hvac_iq_values }])
      elsif [ES::SFFloridaVer3_1, ES::SFOregonWashingtonVer3_2, ES::SFPacificVer3_0, ES::SFNationalVer3_0,
             ES::MFOregonWashingtonVer1_2, ES::MFNationalVer1_0,
             ZERH::Ver1].include? program_version
        _check_heat_pump(hpxml_bldg, [{ systype: HPXML::HVACTypeHeatPumpGroundToAir, fuel: HPXML::FuelTypeElectricity, cop: get_gshp_cop_cz7(program_version), eer: get_gshp_eer_cz7(program_version), frac_load_heat: 1.0, frac_load_cool: 0.0, pump_w_per_ton: 80, **hvac_iq_values }])
      else
        fail "Unhandled program version: #{program_version}"
      end
      _check_thermostat(hpxml_bldg, control_type: HPXML::HVACControlTypeProgrammable)
      if [ES::SFNationalVer3_0, ES::SFPacificVer3_0, ES::SFOregonWashingtonVer3_2].include? program_version
        _check_ducts(hpxml_bldg, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 0.0, duct_area: 729.0, duct_location: HPXML::LocationBasementConditioned },
                                  { duct_type: HPXML::DuctTypeReturn, duct_rvalue: 0.0, duct_area: 135.0, duct_location: HPXML::LocationBasementConditioned }])
      elsif [ES::SFNationalVer3_1, ES::SFNationalVer3_2, ES::SFNationalVer3_3, ES::SFFloridaVer3_1,
             ES::MFNationalVer1_1, ES::MFNationalVer1_2, ES::MFNationalVer1_3,
             ZERH::Ver1, ZERH::SFVer2, ZERH::MFVer2].include? program_version
        _check_ducts(hpxml_bldg, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 0.0, duct_area: 729.0, duct_location: HPXML::LocationConditionedSpace },
                                  { duct_type: HPXML::DuctTypeReturn, duct_rvalue: 0.0, duct_area: 135.0, duct_location: HPXML::LocationConditionedSpace }])
      elsif [ES::MFOregonWashingtonVer1_2, ES::MFNationalVer1_0].include? program_version
        return_r = (program_version != ES::MFOregonWashingtonVer1_2 ? 6.0 : 8.0)
        _check_ducts(hpxml_bldg, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 8.0, duct_area: 729.0, duct_location: HPXML::LocationAtticVented },
                                  { duct_type: HPXML::DuctTypeReturn, duct_rvalue: return_r, duct_area: 135.0, duct_location: HPXML::LocationAtticVented }])
      else
        fail "Unhandled program version: #{program_version}"
      end
      _check_duct_leakage(hpxml_bldg, [{ duct_type: HPXML::DuctTypeSupply, duct_leakage_units: HPXML::UnitsCFM25, duct_leakage_value: get_duct_leakage(program_version, 54.0), duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside },
                                       { duct_type: HPXML::DuctTypeReturn, duct_leakage_units: HPXML::UnitsCFM25, duct_leakage_value: get_duct_leakage(program_version, 54.0), duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside }])
    end
  end

  def test_air_source_heat_pump
    ['base-hvac-air-to-air-heat-pump-1-speed.xml', 'base-hvac-air-to-air-heat-pump-1-speed-seer-hspf.xml'].each do |hpxml_name|
      [*ES::AllVersions, *ZERH::AllVersions].each do |program_version|
        _convert_to_es_zerh(hpxml_name, program_version)
        hpxml_bldg = _test_ruleset(program_version)
        hvac_iq_values = get_default_hvac_iq_values(program_version)
        _check_heating_system(hpxml_bldg)
        _check_cooling_system(hpxml_bldg)
        _check_heat_pump(hpxml_bldg, [{ systype: HPXML::HVACTypeHeatPumpAirToAir, fuel: HPXML::FuelTypeElectricity, hspf: get_ashp_hspf_cz5(program_version), seer: get_ashp_seer_cz5(program_version), frac_load_heat: 1.0, frac_load_cool: 1.0, backup_fuel: HPXML::FuelTypeElectricity, backup_eff: 1.0, **hvac_iq_values }])
        _check_thermostat(hpxml_bldg, control_type: HPXML::HVACControlTypeProgrammable)
        if [ES::SFNationalVer3_0, ES::SFPacificVer3_0, ES::SFOregonWashingtonVer3_2].include? program_version
          _check_ducts(hpxml_bldg, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 0.0, duct_area: 729.0, duct_location: HPXML::LocationBasementConditioned },
                                    { duct_type: HPXML::DuctTypeReturn, duct_rvalue: 0.0, duct_area: 270.0, duct_location: HPXML::LocationBasementConditioned }])
        elsif [ES::SFNationalVer3_1, ES::SFNationalVer3_2, ES::SFNationalVer3_3, ES::SFFloridaVer3_1,
               ES::MFNationalVer1_1, ES::MFNationalVer1_2, ES::MFNationalVer1_3,
               ZERH::Ver1, ZERH::SFVer2, ZERH::MFVer2].include? program_version
          _check_ducts(hpxml_bldg, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 0.0, duct_area: 729.0, duct_location: HPXML::LocationConditionedSpace },
                                    { duct_type: HPXML::DuctTypeReturn, duct_rvalue: 0.0, duct_area: 270.0, duct_location: HPXML::LocationConditionedSpace }])
        elsif [ES::MFOregonWashingtonVer1_2, ES::MFNationalVer1_0].include? program_version
          return_r = (program_version != ES::MFOregonWashingtonVer1_2 ? 6.0 : 8.0)
          _check_ducts(hpxml_bldg, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 8.0, duct_area: 729.0, duct_location: HPXML::LocationAtticVented },
                                    { duct_type: HPXML::DuctTypeReturn, duct_rvalue: return_r, duct_area: 270.0, duct_location: HPXML::LocationAtticVented }])
        else
          fail "Unhandled program version: #{program_version}"
        end
        _check_duct_leakage(hpxml_bldg, [{ duct_type: HPXML::DuctTypeSupply, duct_leakage_units: HPXML::UnitsCFM25, duct_leakage_value: get_duct_leakage(program_version, 54.0), duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside },
                                         { duct_type: HPXML::DuctTypeReturn, duct_leakage_units: HPXML::UnitsCFM25, duct_leakage_value: get_duct_leakage(program_version, 54.0), duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside }])

        next unless [*ES::NationalVersions, *ZERH::AllVersions].include?(program_version)

        # Test in climate zone 7
        _convert_to_es_zerh(hpxml_name, program_version)
        hpxml = HPXML.new(hpxml_path: @tmp_hpxml_path)
        hpxml_bldg = hpxml.buildings[0]
        hpxml_bldg.climate_and_risk_zones.climate_zone_ieccs[0].zone = '7'
        hpxml_bldg.climate_and_risk_zones.weather_station_name = 'Duluth, MN'
        hpxml_bldg.climate_and_risk_zones.weather_station_wmo = 727450
        XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
        hpxml_bldg = _test_ruleset(program_version)
        hvac_iq_values = get_default_hvac_iq_values(program_version)
        _check_heating_system(hpxml_bldg)
        _check_cooling_system(hpxml_bldg)
        if [ES::SFNationalVer3_0, ES::MFNationalVer1_0, ZERH::Ver1].include? program_version
          _check_heat_pump(hpxml_bldg, [{ systype: HPXML::HVACTypeHeatPumpGroundToAir, fuel: HPXML::FuelTypeElectricity, cop: get_gshp_cop_cz7(program_version), eer: get_gshp_eer_cz7(program_version), frac_load_heat: 1.0, frac_load_cool: 1.0, pump_w_per_ton: 80, **hvac_iq_values }])
        elsif [ES::SFFloridaVer3_1, ES::SFOregonWashingtonVer3_2, ES::SFPacificVer3_0, ES::SFNationalVer3_1, ES::SFNationalVer3_2, ES::SFNationalVer3_3,
               ES::MFOregonWashingtonVer1_2, ES::MFNationalVer1_1, ES::MFNationalVer1_2, ES::MFNationalVer1_3,
               ZERH::SFVer2, ZERH::MFVer2].include? program_version
          _check_heat_pump(hpxml_bldg, [{ systype: HPXML::HVACTypeHeatPumpAirToAir, fuel: HPXML::FuelTypeElectricity, hspf: get_ashp_hspf_cz7(program_version), seer: get_ashp_seer_cz7(program_version), frac_load_heat: 1.0, frac_load_cool: 1.0, backup_fuel: HPXML::FuelTypeElectricity, backup_eff: 1.0, **hvac_iq_values }])
        else
          fail "Unhandled program version: #{program_version}"
        end
        _check_thermostat(hpxml_bldg, control_type: HPXML::HVACControlTypeProgrammable)
        if [ES::SFNationalVer3_0, ES::SFPacificVer3_0, ES::SFOregonWashingtonVer3_2].include? program_version
          _check_ducts(hpxml_bldg, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 0.0, duct_area: 729.0, duct_location: HPXML::LocationBasementConditioned },
                                    { duct_type: HPXML::DuctTypeReturn, duct_rvalue: 0.0, duct_area: 270.0, duct_location: HPXML::LocationBasementConditioned }])
        elsif [ES::SFNationalVer3_1, ES::SFNationalVer3_2, ES::SFNationalVer3_3, ES::SFFloridaVer3_1,
               ES::MFNationalVer1_1, ES::MFNationalVer1_2, ES::MFNationalVer1_3,
               ZERH::Ver1, ZERH::SFVer2, ZERH::MFVer2].include? program_version
          _check_ducts(hpxml_bldg, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 0.0, duct_area: 729.0, duct_location: HPXML::LocationConditionedSpace },
                                    { duct_type: HPXML::DuctTypeReturn, duct_rvalue: 0.0, duct_area: 270.0, duct_location: HPXML::LocationConditionedSpace }])
        elsif [ES::MFOregonWashingtonVer1_2, ES::MFNationalVer1_0].include? program_version
          return_r = (program_version != ES::MFOregonWashingtonVer1_2 ? 6.0 : 8.0)
          _check_ducts(hpxml_bldg, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 8.0, duct_area: 729.0, duct_location: HPXML::LocationAtticVented },
                                    { duct_type: HPXML::DuctTypeReturn, duct_rvalue: return_r, duct_area: 270.0, duct_location: HPXML::LocationAtticVented }])
        else
          fail "Unhandled program version: #{program_version}"
        end
        _check_duct_leakage(hpxml_bldg, [{ duct_type: HPXML::DuctTypeSupply, duct_leakage_units: HPXML::UnitsCFM25, duct_leakage_value: get_duct_leakage(program_version, 54.0), duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside },
                                         { duct_type: HPXML::DuctTypeReturn, duct_leakage_units: HPXML::UnitsCFM25, duct_leakage_value: get_duct_leakage(program_version, 54.0), duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside }])
      end
    end
  end

  def test_mini_split_heat_pump_ducted
    [*ES::AllVersions, *ZERH::AllVersions].each do |program_version|
      _convert_to_es_zerh('base-hvac-mini-split-heat-pump-ducted.xml', program_version)
      hpxml_bldg = _test_ruleset(program_version)
      hvac_iq_values = get_default_hvac_iq_values(program_version)
      _check_heating_system(hpxml_bldg)
      _check_cooling_system(hpxml_bldg)
      _check_heat_pump(hpxml_bldg, [{ systype: HPXML::HVACTypeHeatPumpAirToAir, fuel: HPXML::FuelTypeElectricity, hspf: get_ashp_hspf_cz5(program_version), seer: get_ashp_seer_cz5(program_version), frac_load_heat: 1.0, frac_load_cool: 1.0, backup_fuel: HPXML::FuelTypeElectricity, backup_eff: 1.0, **hvac_iq_values }])
      _check_thermostat(hpxml_bldg, control_type: HPXML::HVACControlTypeProgrammable)
      if [ES::SFNationalVer3_0, ES::SFPacificVer3_0, ES::SFOregonWashingtonVer3_2].include? program_version
        _check_ducts(hpxml_bldg, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 0.0, duct_area: 729.0, duct_location: HPXML::LocationBasementConditioned },
                                  { duct_type: HPXML::DuctTypeReturn, duct_rvalue: 0.0, duct_area: 270.0, duct_location: HPXML::LocationBasementConditioned }])
      elsif [ES::SFNationalVer3_1, ES::SFNationalVer3_2, ES::SFNationalVer3_3, ES::SFFloridaVer3_1,
             ES::MFNationalVer1_1, ES::MFNationalVer1_2, ES::MFNationalVer1_3,
             ZERH::Ver1, ZERH::SFVer2, ZERH::MFVer2].include? program_version
        _check_ducts(hpxml_bldg, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 0.0, duct_area: 729.0, duct_location: HPXML::LocationConditionedSpace },
                                  { duct_type: HPXML::DuctTypeReturn, duct_rvalue: 0.0, duct_area: 270.0, duct_location: HPXML::LocationConditionedSpace }])
      elsif [ES::MFOregonWashingtonVer1_2, ES::MFNationalVer1_0].include? program_version
        return_r = (program_version != ES::MFOregonWashingtonVer1_2 ? 6.0 : 8.0)
        _check_ducts(hpxml_bldg, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 8.0, duct_area: 729.0, duct_location: HPXML::LocationAtticVented },
                                  { duct_type: HPXML::DuctTypeReturn, duct_rvalue: return_r, duct_area: 270.0, duct_location: HPXML::LocationAtticVented }])
      else
        fail "Unhandled program version: #{program_version}"
      end
      _check_duct_leakage(hpxml_bldg, [{ duct_type: HPXML::DuctTypeSupply, duct_leakage_units: HPXML::UnitsCFM25, duct_leakage_value: get_duct_leakage(program_version, 54.0), duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside },
                                       { duct_type: HPXML::DuctTypeReturn, duct_leakage_units: HPXML::UnitsCFM25, duct_leakage_value: get_duct_leakage(program_version, 54.0), duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside }])
    end
  end

  def test_mini_split_heat_pump_ductless
    [*ES::AllVersions, *ZERH::AllVersions].each do |program_version|
      _convert_to_es_zerh('base-hvac-mini-split-heat-pump-ductless.xml', program_version)
      hpxml_bldg = _test_ruleset(program_version)
      hvac_iq_values = get_default_hvac_iq_values(program_version)
      _check_heating_system(hpxml_bldg)
      _check_cooling_system(hpxml_bldg)
      _check_heat_pump(hpxml_bldg, [{ systype: HPXML::HVACTypeHeatPumpAirToAir, fuel: HPXML::FuelTypeElectricity, hspf: get_ashp_hspf_cz5(program_version), seer: get_ashp_seer_cz5(program_version), frac_load_heat: 1.0, frac_load_cool: 1.0, backup_fuel: HPXML::FuelTypeElectricity, backup_eff: 1.0, **hvac_iq_values }])
      _check_thermostat(hpxml_bldg, control_type: HPXML::HVACControlTypeProgrammable)
      if [ES::SFNationalVer3_0, ES::SFPacificVer3_0, ES::SFOregonWashingtonVer3_2].include? program_version
        _check_ducts(hpxml_bldg, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 0.0, duct_area: 729.0, duct_location: HPXML::LocationBasementConditioned },
                                  { duct_type: HPXML::DuctTypeReturn, duct_rvalue: 0.0, duct_area: 135.0, duct_location: HPXML::LocationBasementConditioned }])
      elsif [ES::SFNationalVer3_1, ES::SFNationalVer3_2, ES::SFNationalVer3_3, ES::SFFloridaVer3_1,
             ES::MFNationalVer1_1, ES::MFNationalVer1_2, ES::MFNationalVer1_3,
             ZERH::Ver1, ZERH::SFVer2, ZERH::MFVer2].include? program_version
        _check_ducts(hpxml_bldg, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 0.0, duct_area: 729.0, duct_location: HPXML::LocationConditionedSpace },
                                  { duct_type: HPXML::DuctTypeReturn, duct_rvalue: 0.0, duct_area: 135.0, duct_location: HPXML::LocationConditionedSpace }])
      elsif [ES::MFOregonWashingtonVer1_2, ES::MFNationalVer1_0].include? program_version
        return_r = (program_version != ES::MFOregonWashingtonVer1_2 ? 6.0 : 8.0)
        _check_ducts(hpxml_bldg, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 8.0, duct_area: 729.0, duct_location: HPXML::LocationAtticVented },
                                  { duct_type: HPXML::DuctTypeReturn, duct_rvalue: return_r, duct_area: 135.0, duct_location: HPXML::LocationAtticVented }])
      else
        fail "Unhandled program version: #{program_version}"
      end
      _check_duct_leakage(hpxml_bldg, [{ duct_type: HPXML::DuctTypeSupply, duct_leakage_units: HPXML::UnitsCFM25, duct_leakage_value: get_duct_leakage(program_version, 54.0), duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside },
                                       { duct_type: HPXML::DuctTypeReturn, duct_leakage_units: HPXML::UnitsCFM25, duct_leakage_value: get_duct_leakage(program_version, 54.0), duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside }])
    end
  end

  def test_ground_source_heat_pump
    [*ES::AllVersions, *ZERH::AllVersions].each do |program_version|
      _convert_to_es_zerh('base-hvac-ground-to-air-heat-pump-1-speed.xml', program_version)
      hpxml_bldg = _test_ruleset(program_version)
      hvac_iq_values = get_default_hvac_iq_values(program_version)
      _check_heating_system(hpxml_bldg)
      _check_cooling_system(hpxml_bldg)
      if [*ES::MFVersions, ZERH::MFVer2].include? program_version
        _check_heat_pump(hpxml_bldg, [{ systype: HPXML::HVACTypeHeatPumpGroundToAir, fuel: HPXML::FuelTypeElectricity, cop: get_gshp_cop_cz5(program_version), eer: get_gshp_eer_cz5(program_version), frac_load_heat: 1.0, frac_load_cool: 1.0, pump_w_per_ton: 80, **hvac_iq_values }])
      elsif [ES::SFFloridaVer3_1, ES::SFOregonWashingtonVer3_2, ES::SFPacificVer3_0, ES::SFNationalVer3_0, ES::SFNationalVer3_1, ES::SFNationalVer3_2, ES::SFNationalVer3_3,
             ZERH::Ver1, ZERH::SFVer2].include? program_version
        _check_heat_pump(hpxml_bldg, [{ systype: HPXML::HVACTypeHeatPumpAirToAir, fuel: HPXML::FuelTypeElectricity, hspf: get_ashp_hspf_cz5(program_version), seer: get_ashp_seer_cz5(program_version), frac_load_heat: 1.0, frac_load_cool: 1.0, backup_fuel: HPXML::FuelTypeElectricity, backup_eff: 1.0, **hvac_iq_values }])
      else
        fail "Unhandled program version: #{program_version}"
      end
      _check_thermostat(hpxml_bldg, control_type: HPXML::HVACControlTypeProgrammable)
      if [ES::SFNationalVer3_0, ES::SFPacificVer3_0, ES::SFOregonWashingtonVer3_2].include? program_version
        _check_ducts(hpxml_bldg, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 0.0, duct_area: 729.0, duct_location: HPXML::LocationBasementConditioned },
                                  { duct_type: HPXML::DuctTypeReturn, duct_rvalue: 0.0, duct_area: 270.0, duct_location: HPXML::LocationBasementConditioned }])
      elsif [ES::SFNationalVer3_1, ES::SFNationalVer3_2, ES::SFNationalVer3_3, ES::SFFloridaVer3_1,
             ES::MFNationalVer1_1, ES::MFNationalVer1_2, ES::MFNationalVer1_3,
             ZERH::Ver1, ZERH::SFVer2, ZERH::MFVer2].include? program_version
        _check_ducts(hpxml_bldg, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 0.0, duct_area: 729.0, duct_location: HPXML::LocationConditionedSpace },
                                  { duct_type: HPXML::DuctTypeReturn, duct_rvalue: 0.0, duct_area: 270.0, duct_location: HPXML::LocationConditionedSpace }])
      elsif [ES::MFOregonWashingtonVer1_2, ES::MFNationalVer1_0].include? program_version
        return_r = (program_version != ES::MFOregonWashingtonVer1_2 ? 6.0 : 8.0)
        _check_ducts(hpxml_bldg, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 8.0, duct_area: 729.0, duct_location: HPXML::LocationAtticVented },
                                  { duct_type: HPXML::DuctTypeReturn, duct_rvalue: return_r, duct_area: 270.0, duct_location: HPXML::LocationAtticVented }])
      else
        fail "Unhandled program version: #{program_version}"
      end
      _check_duct_leakage(hpxml_bldg, [{ duct_type: HPXML::DuctTypeSupply, duct_leakage_units: HPXML::UnitsCFM25, duct_leakage_value: get_duct_leakage(program_version, 54.0), duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside },
                                       { duct_type: HPXML::DuctTypeReturn, duct_leakage_units: HPXML::UnitsCFM25, duct_leakage_value: get_duct_leakage(program_version, 54.0), duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside }])

      next unless [*ES::NationalVersions, *ZERH::AllVersions].include?(program_version)

      # Test in climate zone 7
      _convert_to_es_zerh('base-hvac-ground-to-air-heat-pump-1-speed.xml', program_version)
      hpxml = HPXML.new(hpxml_path: @tmp_hpxml_path)
      hpxml_bldg = hpxml.buildings[0]
      hpxml_bldg.climate_and_risk_zones.climate_zone_ieccs[0].zone = '7'
      hpxml_bldg.climate_and_risk_zones.weather_station_name = 'Duluth, MN'
      hpxml_bldg.climate_and_risk_zones.weather_station_wmo = 727450
      XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
      hpxml_bldg = _test_ruleset(program_version)
      hvac_iq_values = get_default_hvac_iq_values(program_version)
      _check_heating_system(hpxml_bldg)
      _check_cooling_system(hpxml_bldg)
      if [ES::SFNationalVer3_0, *ES::MFVersions, ZERH::Ver1, ZERH::MFVer2].include? program_version
        _check_heat_pump(hpxml_bldg, [{ systype: HPXML::HVACTypeHeatPumpGroundToAir, fuel: HPXML::FuelTypeElectricity, cop: get_gshp_cop_cz7(program_version), eer: get_gshp_eer_cz7(program_version), frac_load_heat: 1.0, frac_load_cool: 1.0, pump_w_per_ton: 80, **hvac_iq_values }])
      elsif [ES::SFFloridaVer3_1, ES::SFOregonWashingtonVer3_2, ES::SFPacificVer3_0, ES::SFNationalVer3_1, ES::SFNationalVer3_2, ES::SFNationalVer3_3,
             ES::MFOregonWashingtonVer1_2, ES::MFNationalVer1_0, ES::MFNationalVer1_1, ES::MFNationalVer1_2, ES::MFNationalVer1_3,
             ZERH::SFVer2].include? program_version
        _check_heat_pump(hpxml_bldg, [{ systype: HPXML::HVACTypeHeatPumpAirToAir, fuel: HPXML::FuelTypeElectricity, hspf: get_ashp_hspf_cz7(program_version), seer: get_ashp_seer_cz7(program_version), frac_load_heat: 1.0, frac_load_cool: 1.0, backup_fuel: HPXML::FuelTypeElectricity, backup_eff: 1.0, **hvac_iq_values }])
      else
        fail "Unhandled program version: #{program_version}"
      end
      _check_thermostat(hpxml_bldg, control_type: HPXML::HVACControlTypeProgrammable)
      if [ES::SFNationalVer3_0, ES::SFPacificVer3_0, ES::SFOregonWashingtonVer3_2].include? program_version
        _check_ducts(hpxml_bldg, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 0.0, duct_area: 729.0, duct_location: HPXML::LocationBasementConditioned },
                                  { duct_type: HPXML::DuctTypeReturn, duct_rvalue: 0.0, duct_area: 270.0, duct_location: HPXML::LocationBasementConditioned }])
      elsif [ES::SFNationalVer3_1, ES::SFNationalVer3_2, ES::SFNationalVer3_3, ES::SFFloridaVer3_1,
             ES::MFNationalVer1_1, ES::MFNationalVer1_2, ES::MFNationalVer1_3,
             ZERH::Ver1, ZERH::SFVer2, ZERH::MFVer2].include? program_version
        _check_ducts(hpxml_bldg, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 0.0, duct_area: 729.0, duct_location: HPXML::LocationConditionedSpace },
                                  { duct_type: HPXML::DuctTypeReturn, duct_rvalue: 0.0, duct_area: 270.0, duct_location: HPXML::LocationConditionedSpace }])
      elsif [ES::MFOregonWashingtonVer1_2, ES::MFNationalVer1_0].include? program_version
        return_r = (program_version != ES::MFOregonWashingtonVer1_2 ? 6.0 : 8.0)
        _check_ducts(hpxml_bldg, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 8.0, duct_area: 729.0, duct_location: HPXML::LocationAtticVented },
                                  { duct_type: HPXML::DuctTypeReturn, duct_rvalue: return_r, duct_area: 270.0, duct_location: HPXML::LocationAtticVented }])
      else
        fail "Unhandled program version: #{program_version}"
      end
      _check_duct_leakage(hpxml_bldg, [{ duct_type: HPXML::DuctTypeSupply, duct_leakage_units: HPXML::UnitsCFM25, duct_leakage_value: get_duct_leakage(program_version, 54.0), duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside },
                                       { duct_type: HPXML::DuctTypeReturn, duct_leakage_units: HPXML::UnitsCFM25, duct_leakage_value: get_duct_leakage(program_version, 54.0), duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside }])
    end
  end

  def test_dual_fuel_heat_pump_gas
    [*ES::AllVersions, *ZERH::AllVersions].each do |program_version|
      _convert_to_es_zerh('base-hvac-dual-fuel-air-to-air-heat-pump-1-speed.xml', program_version)
      hpxml_bldg = _test_ruleset(program_version)
      hvac_iq_values = get_default_hvac_iq_values(program_version)
      _check_heating_system(hpxml_bldg)
      _check_cooling_system(hpxml_bldg)
      _check_heat_pump(hpxml_bldg, [{ systype: HPXML::HVACTypeHeatPumpAirToAir, fuel: HPXML::FuelTypeElectricity, hspf: get_ashp_hspf_cz5(program_version), seer: get_ashp_seer_cz5(program_version), frac_load_heat: 1.0, frac_load_cool: 1.0, backup_fuel: HPXML::FuelTypeNaturalGas, backup_eff: get_gas_furnace_afue_cz5(program_version), **hvac_iq_values }])

      _check_thermostat(hpxml_bldg, control_type: HPXML::HVACControlTypeProgrammable)
      if [ES::SFNationalVer3_0, ES::SFPacificVer3_0, ES::SFOregonWashingtonVer3_2].include? program_version
        _check_ducts(hpxml_bldg, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 0.0, duct_area: 729.0, duct_location: HPXML::LocationBasementConditioned },
                                  { duct_type: HPXML::DuctTypeReturn, duct_rvalue: 0.0, duct_area: 270.0, duct_location: HPXML::LocationBasementConditioned }])
      elsif [ES::SFNationalVer3_1, ES::SFNationalVer3_2, ES::SFNationalVer3_3, ES::SFFloridaVer3_1,
             ES::MFNationalVer1_1, ES::MFNationalVer1_2, ES::MFNationalVer1_3,
             ZERH::Ver1, ZERH::SFVer2, ZERH::MFVer2].include? program_version
        _check_ducts(hpxml_bldg, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 0.0, duct_area: 729.0, duct_location: HPXML::LocationConditionedSpace },
                                  { duct_type: HPXML::DuctTypeReturn, duct_rvalue: 0.0, duct_area: 270.0, duct_location: HPXML::LocationConditionedSpace }])
      elsif [ES::MFOregonWashingtonVer1_2, ES::MFNationalVer1_0].include? program_version
        return_r = (program_version != ES::MFOregonWashingtonVer1_2 ? 6.0 : 8.0)
        _check_ducts(hpxml_bldg, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 8.0, duct_area: 729.0, duct_location: HPXML::LocationAtticVented },
                                  { duct_type: HPXML::DuctTypeReturn, duct_rvalue: return_r, duct_area: 270.0, duct_location: HPXML::LocationAtticVented }])
      else
        fail "Unhandled program version: #{program_version}"
      end
      _check_duct_leakage(hpxml_bldg, [{ duct_type: HPXML::DuctTypeSupply, duct_leakage_units: HPXML::UnitsCFM25, duct_leakage_value: get_duct_leakage(program_version, 54.0), duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside },
                                       { duct_type: HPXML::DuctTypeReturn, duct_leakage_units: HPXML::UnitsCFM25, duct_leakage_value: get_duct_leakage(program_version, 54.0), duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside }])
    end
  end

  def test_central_air_conditioner
    ['base-hvac-central-ac-only-1-speed.xml', 'base-hvac-central-ac-only-1-speed-seer.xml'].each do |hpxml_name|
      [*ES::AllVersions, *ZERH::AllVersions].each do |program_version|
        _convert_to_es_zerh(hpxml_name, program_version)
        hpxml_bldg = _test_ruleset(program_version)
        hvac_iq_values = get_default_hvac_iq_values(program_version)
        _check_heating_system(hpxml_bldg)
        _check_cooling_system(hpxml_bldg, [{ systype: HPXML::HVACTypeCentralAirConditioner, fuel: HPXML::FuelTypeElectricity, seer: get_central_ac_seer_cz5(program_version), frac_load: 1.0, **hvac_iq_values }])
        _check_heat_pump(hpxml_bldg)
        _check_thermostat(hpxml_bldg, control_type: HPXML::HVACControlTypeProgrammable)
        if [ES::SFNationalVer3_0, ES::SFPacificVer3_0, ES::SFOregonWashingtonVer3_2].include? program_version
          _check_ducts(hpxml_bldg, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 0.0, duct_area: 729.0, duct_location: HPXML::LocationBasementConditioned },
                                    { duct_type: HPXML::DuctTypeReturn, duct_rvalue: 0.0, duct_area: 270.0, duct_location: HPXML::LocationBasementConditioned }])
        elsif [ES::SFNationalVer3_1, ES::SFNationalVer3_2, ES::SFNationalVer3_3, ES::SFFloridaVer3_1,
               ES::MFNationalVer1_1, ES::MFNationalVer1_2, ES::MFNationalVer1_3,
               ZERH::Ver1, ZERH::SFVer2, ZERH::MFVer2].include? program_version
          _check_ducts(hpxml_bldg, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 0.0, duct_area: 729.0, duct_location: HPXML::LocationConditionedSpace },
                                    { duct_type: HPXML::DuctTypeReturn, duct_rvalue: 0.0, duct_area: 270.0, duct_location: HPXML::LocationConditionedSpace }])
        elsif [ES::MFOregonWashingtonVer1_2, ES::MFNationalVer1_0].include? program_version
          return_r = (program_version != ES::MFOregonWashingtonVer1_2 ? 6.0 : 8.0)
          _check_ducts(hpxml_bldg, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 8.0, duct_area: 729.0, duct_location: HPXML::LocationAtticVented },
                                    { duct_type: HPXML::DuctTypeReturn, duct_rvalue: return_r, duct_area: 270.0, duct_location: HPXML::LocationAtticVented }])
        else
          fail "Unhandled program version: #{program_version}"
        end
        _check_duct_leakage(hpxml_bldg, [{ duct_type: HPXML::DuctTypeSupply, duct_leakage_units: HPXML::UnitsCFM25, duct_leakage_value: get_duct_leakage(program_version, 54.0), duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside },
                                         { duct_type: HPXML::DuctTypeReturn, duct_leakage_units: HPXML::UnitsCFM25, duct_leakage_value: get_duct_leakage(program_version, 54.0), duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside }])
      end
    end
  end

  def test_room_air_conditioner_and_ptac
    hpxml_names = ['base-hvac-room-ac-only.xml',
                   'base-hvac-room-ac-only-eer.xml',
                   'base-hvac-ptac.xml']

    hpxml_names.each do |hpxml_name|
      [*ES::AllVersions, *ZERH::AllVersions].each do |program_version|
        _convert_to_es_zerh(hpxml_name, program_version)
        hpxml_bldg = _test_ruleset(program_version)
        hvac_iq_values = get_default_hvac_iq_values(program_version)
        _check_heating_system(hpxml_bldg)
        _check_cooling_system(hpxml_bldg, [{ systype: HPXML::HVACTypeCentralAirConditioner, fuel: HPXML::FuelTypeElectricity, seer: get_central_ac_seer_cz5(program_version), frac_load: 1.0, **hvac_iq_values }])
        _check_heat_pump(hpxml_bldg)
        _check_thermostat(hpxml_bldg, control_type: HPXML::HVACControlTypeProgrammable)
        if [ES::SFNationalVer3_0, ES::SFPacificVer3_0, ES::SFOregonWashingtonVer3_2].include? program_version
          _check_ducts(hpxml_bldg, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 0.0, duct_area: 729.0, duct_location: HPXML::LocationBasementConditioned },
                                    { duct_type: HPXML::DuctTypeReturn, duct_rvalue: 0.0, duct_area: 135.0, duct_location: HPXML::LocationBasementConditioned }])
        elsif [ES::SFNationalVer3_1, ES::SFNationalVer3_2, ES::SFNationalVer3_3, ES::SFFloridaVer3_1,
               ES::MFNationalVer1_1, ES::MFNationalVer1_2, ES::MFNationalVer1_3,
               ZERH::Ver1, ZERH::SFVer2, ZERH::MFVer2].include? program_version
          _check_ducts(hpxml_bldg, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 0.0, duct_area: 729.0, duct_location: HPXML::LocationConditionedSpace },
                                    { duct_type: HPXML::DuctTypeReturn, duct_rvalue: 0.0, duct_area: 135.0, duct_location: HPXML::LocationConditionedSpace }])
        elsif [ES::MFOregonWashingtonVer1_2, ES::MFNationalVer1_0].include? program_version
          return_r = (program_version != ES::MFOregonWashingtonVer1_2 ? 6.0 : 8.0)
          _check_ducts(hpxml_bldg, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 8.0, duct_area: 729.0, duct_location: HPXML::LocationAtticVented },
                                    { duct_type: HPXML::DuctTypeReturn, duct_rvalue: return_r, duct_area: 135.0, duct_location: HPXML::LocationAtticVented }])
        else
          fail "Unhandled program version: #{program_version}"
        end
        _check_duct_leakage(hpxml_bldg, [{ duct_type: HPXML::DuctTypeSupply, duct_leakage_units: HPXML::UnitsCFM25, duct_leakage_value: get_duct_leakage(program_version, 54.0), duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside },
                                         { duct_type: HPXML::DuctTypeReturn, duct_leakage_units: HPXML::UnitsCFM25, duct_leakage_value: get_duct_leakage(program_version, 54.0), duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside }])
      end
    end
  end

  def test_room_air_conditioner_and_ptac_with_heating
    hpxml_names = ['base-hvac-room-ac-with-heating.xml',
                   'base-hvac-ptac-with-heating-electricity.xml']

    hpxml_names.each do |hpxml_name|
      [*ES::AllVersions, *ZERH::AllVersions].each do |program_version|
        _convert_to_es_zerh(hpxml_name, program_version)
        hpxml_bldg = _test_ruleset(program_version)
        hvac_iq_values = get_default_hvac_iq_values(program_version)
        _check_heating_system(hpxml_bldg)
        _check_cooling_system(hpxml_bldg)
        _check_heat_pump(hpxml_bldg, [{ systype: HPXML::HVACTypeHeatPumpAirToAir, fuel: HPXML::FuelTypeElectricity, hspf: get_ashp_hspf_cz5(program_version), seer: get_ashp_seer_cz5(program_version), frac_load_heat: 1.0, frac_load_cool: 1.0, backup_fuel: HPXML::FuelTypeElectricity, backup_eff: 1.0, **hvac_iq_values }])
        _check_thermostat(hpxml_bldg, control_type: HPXML::HVACControlTypeProgrammable)
        if [ES::SFNationalVer3_0, ES::SFPacificVer3_0, ES::SFOregonWashingtonVer3_2].include? program_version
          _check_ducts(hpxml_bldg, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 0.0, duct_area: 729.0, duct_location: HPXML::LocationBasementConditioned },
                                    { duct_type: HPXML::DuctTypeReturn, duct_rvalue: 0.0, duct_area: 135.0, duct_location: HPXML::LocationBasementConditioned }])
        elsif [ES::SFNationalVer3_1, ES::SFNationalVer3_2, ES::SFNationalVer3_3, ES::SFFloridaVer3_1,
               ES::MFNationalVer1_1, ES::MFNationalVer1_2, ES::MFNationalVer1_3,
               ZERH::Ver1, ZERH::SFVer2, ZERH::MFVer2].include? program_version
          _check_ducts(hpxml_bldg, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 0.0, duct_area: 729.0, duct_location: HPXML::LocationConditionedSpace },
                                    { duct_type: HPXML::DuctTypeReturn, duct_rvalue: 0.0, duct_area: 135.0, duct_location: HPXML::LocationConditionedSpace }])
        elsif [ES::MFOregonWashingtonVer1_2, ES::MFNationalVer1_0].include? program_version
          return_r = (program_version != ES::MFOregonWashingtonVer1_2 ? 6.0 : 8.0)
          _check_ducts(hpxml_bldg, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 8.0, duct_area: 729.0, duct_location: HPXML::LocationAtticVented },
                                    { duct_type: HPXML::DuctTypeReturn, duct_rvalue: return_r, duct_area: 135.0, duct_location: HPXML::LocationAtticVented }])
        else
          fail "Unhandled program version: #{program_version}"
        end
        _check_duct_leakage(hpxml_bldg, [{ duct_type: HPXML::DuctTypeSupply, duct_leakage_units: HPXML::UnitsCFM25, duct_leakage_value: get_duct_leakage(program_version, 54.0), duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside },
                                         { duct_type: HPXML::DuctTypeReturn, duct_leakage_units: HPXML::UnitsCFM25, duct_leakage_value: get_duct_leakage(program_version, 54.0), duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside }])
      end
    end
  end

  def test_room_air_conditioner_and_ptac_with_heating_gas
    hpxml_name = 'base-hvac-ptac-with-heating-natural-gas.xml'

    [*ES::AllVersions, *ZERH::AllVersions].each do |program_version|
      _convert_to_es_zerh(hpxml_name, program_version)
      hpxml_bldg = _test_ruleset(program_version)
      hvac_iq_values = get_default_hvac_iq_values(program_version)
      _check_heating_system(hpxml_bldg, [{ systype: HPXML::HVACTypeFurnace, fuel: HPXML::FuelTypeNaturalGas, eff: get_gas_furnace_afue_cz5(program_version), frac_load: 1.0, **hvac_iq_values }])
      _check_cooling_system(hpxml_bldg, [{ systype: HPXML::HVACTypeCentralAirConditioner, fuel: HPXML::FuelTypeElectricity, seer: get_central_ac_seer_cz5(program_version), frac_load: 1.0, **hvac_iq_values }])
      _check_heat_pump(hpxml_bldg)
      _check_thermostat(hpxml_bldg, control_type: HPXML::HVACControlTypeProgrammable)
      if [ES::SFNationalVer3_0, ES::SFPacificVer3_0, ES::SFOregonWashingtonVer3_2].include? program_version
        _check_ducts(hpxml_bldg, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 0.0, duct_area: 729.0, duct_location: HPXML::LocationBasementConditioned },
                                  { duct_type: HPXML::DuctTypeReturn, duct_rvalue: 0.0, duct_area: 135.0, duct_location: HPXML::LocationBasementConditioned }] * 2)
      elsif [ES::SFNationalVer3_1, ES::SFNationalVer3_2, ES::SFNationalVer3_3, ES::SFFloridaVer3_1,
             ES::MFNationalVer1_1, ES::MFNationalVer1_2, ES::MFNationalVer1_3,
             ZERH::Ver1, ZERH::SFVer2, ZERH::MFVer2].include? program_version
        _check_ducts(hpxml_bldg, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 0.0, duct_area: 729.0, duct_location: HPXML::LocationConditionedSpace },
                                  { duct_type: HPXML::DuctTypeReturn, duct_rvalue: 0.0, duct_area: 135.0, duct_location: HPXML::LocationConditionedSpace }] * 2)
      elsif [ES::MFOregonWashingtonVer1_2, ES::MFNationalVer1_0].include? program_version
        return_r = (program_version != ES::MFOregonWashingtonVer1_2 ? 6.0 : 8.0)
        _check_ducts(hpxml_bldg, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 8.0, duct_area: 729.0, duct_location: HPXML::LocationAtticVented },
                                  { duct_type: HPXML::DuctTypeReturn, duct_rvalue: return_r, duct_area: 135.0, duct_location: HPXML::LocationAtticVented }] * 2)
      else
        fail "Unhandled program version: #{program_version}"
      end
      _check_duct_leakage(hpxml_bldg, [{ duct_type: HPXML::DuctTypeSupply, duct_leakage_units: HPXML::UnitsCFM25, duct_leakage_value: get_duct_leakage(program_version, 54.0), duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside },
                                       { duct_type: HPXML::DuctTypeReturn, duct_leakage_units: HPXML::UnitsCFM25, duct_leakage_value: get_duct_leakage(program_version, 54.0), duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside }] * 2)
    end
  end

  def test_room_air_conditioner_with_reverse_cycle_and_pthp
    hpxml_names = ['base-hvac-room-ac-with-reverse-cycle.xml',
                   'base-hvac-pthp.xml']

    hpxml_names.each do |hpxml_name|
      [*ES::AllVersions, *ZERH::AllVersions].each do |program_version|
        _convert_to_es_zerh(hpxml_name, program_version)
        hpxml_bldg = _test_ruleset(program_version)
        hvac_iq_values = get_default_hvac_iq_values(program_version)
        _check_heating_system(hpxml_bldg)
        _check_cooling_system(hpxml_bldg)
        _check_heat_pump(hpxml_bldg, [{ systype: HPXML::HVACTypeHeatPumpAirToAir, fuel: HPXML::FuelTypeElectricity, hspf: get_ashp_hspf_cz5(program_version), seer: get_ashp_seer_cz5(program_version), frac_load_heat: 1.0, frac_load_cool: 1.0, backup_fuel: HPXML::FuelTypeElectricity, backup_eff: 1.0, **hvac_iq_values }])
        _check_thermostat(hpxml_bldg, control_type: HPXML::HVACControlTypeProgrammable)
        if [ES::SFNationalVer3_0, ES::SFPacificVer3_0, ES::SFOregonWashingtonVer3_2].include? program_version
          _check_ducts(hpxml_bldg, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 0.0, duct_area: 729.0, duct_location: HPXML::LocationBasementConditioned },
                                    { duct_type: HPXML::DuctTypeReturn, duct_rvalue: 0.0, duct_area: 135.0, duct_location: HPXML::LocationBasementConditioned }])
        elsif [ES::SFNationalVer3_1, ES::SFNationalVer3_2, ES::SFNationalVer3_3, ES::SFFloridaVer3_1,
               ES::MFNationalVer1_1, ES::MFNationalVer1_2, ES::MFNationalVer1_3,
               ZERH::Ver1, ZERH::SFVer2, ZERH::MFVer2].include? program_version
          _check_ducts(hpxml_bldg, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 0.0, duct_area: 729.0, duct_location: HPXML::LocationConditionedSpace },
                                    { duct_type: HPXML::DuctTypeReturn, duct_rvalue: 0.0, duct_area: 135.0, duct_location: HPXML::LocationConditionedSpace }])
        elsif [ES::MFOregonWashingtonVer1_2, ES::MFNationalVer1_0].include? program_version
          return_r = (program_version != ES::MFOregonWashingtonVer1_2 ? 6.0 : 8.0)
          _check_ducts(hpxml_bldg, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 8.0, duct_area: 729.0, duct_location: HPXML::LocationAtticVented },
                                    { duct_type: HPXML::DuctTypeReturn, duct_rvalue: return_r, duct_area: 135.0, duct_location: HPXML::LocationAtticVented }])
        else
          fail "Unhandled program version: #{program_version}"
        end
        _check_duct_leakage(hpxml_bldg, [{ duct_type: HPXML::DuctTypeSupply, duct_leakage_units: HPXML::UnitsCFM25, duct_leakage_value: get_duct_leakage(program_version, 54.0), duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside },
                                         { duct_type: HPXML::DuctTypeReturn, duct_leakage_units: HPXML::UnitsCFM25, duct_leakage_value: get_duct_leakage(program_version, 54.0), duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside }])
      end
    end
  end

  def test_evaporative_cooler
    [*ES::AllVersions, *ZERH::AllVersions].each do |program_version|
      _convert_to_es_zerh('base-hvac-evap-cooler-only.xml', program_version)
      hpxml_bldg = _test_ruleset(program_version)
      hvac_iq_values = get_default_hvac_iq_values(program_version)
      _check_heating_system(hpxml_bldg)
      _check_cooling_system(hpxml_bldg, [{ systype: HPXML::HVACTypeCentralAirConditioner, fuel: HPXML::FuelTypeElectricity, seer: get_central_ac_seer_cz5(program_version), frac_load: 1.0, **hvac_iq_values }])
      _check_heat_pump(hpxml_bldg)
      _check_thermostat(hpxml_bldg, control_type: HPXML::HVACControlTypeProgrammable)
      if [ES::SFNationalVer3_0, ES::SFPacificVer3_0, ES::SFOregonWashingtonVer3_2].include? program_version
        _check_ducts(hpxml_bldg, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 0.0, duct_area: 729.0, duct_location: HPXML::LocationBasementConditioned },
                                  { duct_type: HPXML::DuctTypeReturn, duct_rvalue: 0.0, duct_area: 135.0, duct_location: HPXML::LocationBasementConditioned }])
      elsif [ES::SFNationalVer3_1, ES::SFNationalVer3_2, ES::SFNationalVer3_3, ES::SFFloridaVer3_1,
             ES::MFNationalVer1_1, ES::MFNationalVer1_2, ES::MFNationalVer1_3,
             ZERH::Ver1, ZERH::SFVer2, ZERH::MFVer2].include? program_version
        _check_ducts(hpxml_bldg, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 0.0, duct_area: 729.0, duct_location: HPXML::LocationConditionedSpace },
                                  { duct_type: HPXML::DuctTypeReturn, duct_rvalue: 0.0, duct_area: 135.0, duct_location: HPXML::LocationConditionedSpace }])
      elsif [ES::MFOregonWashingtonVer1_2, ES::MFNationalVer1_0].include? program_version
        return_r = (program_version != ES::MFOregonWashingtonVer1_2 ? 6.0 : 8.0)
        _check_ducts(hpxml_bldg, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 8.0, duct_area: 729.0, duct_location: HPXML::LocationAtticVented },
                                  { duct_type: HPXML::DuctTypeReturn, duct_rvalue: return_r, duct_area: 135.0, duct_location: HPXML::LocationAtticVented }])
      else
        fail "Unhandled program version: #{program_version}"
      end
      _check_duct_leakage(hpxml_bldg, [{ duct_type: HPXML::DuctTypeSupply, duct_leakage_units: HPXML::UnitsCFM25, duct_leakage_value: get_duct_leakage(program_version, 54.0), duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside },
                                       { duct_type: HPXML::DuctTypeReturn, duct_leakage_units: HPXML::UnitsCFM25, duct_leakage_value: get_duct_leakage(program_version, 54.0), duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside }])
    end
  end

  def test_mini_split_air_conditioner_ducted
    [*ES::AllVersions, *ZERH::AllVersions].each do |program_version|
      _convert_to_es_zerh('base-hvac-mini-split-air-conditioner-only-ducted.xml', program_version)
      hpxml_bldg = _test_ruleset(program_version)
      hvac_iq_values = get_default_hvac_iq_values(program_version)
      _check_heating_system(hpxml_bldg)
      _check_cooling_system(hpxml_bldg, [{ systype: HPXML::HVACTypeCentralAirConditioner, fuel: HPXML::FuelTypeElectricity, seer: get_central_ac_seer_cz5(program_version), frac_load: 1.0, **hvac_iq_values }])
      _check_heat_pump(hpxml_bldg)
      _check_thermostat(hpxml_bldg, control_type: HPXML::HVACControlTypeProgrammable)
      if [ES::SFNationalVer3_0, ES::SFPacificVer3_0, ES::SFOregonWashingtonVer3_2].include? program_version
        _check_ducts(hpxml_bldg, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 0.0, duct_area: 729.0, duct_location: HPXML::LocationBasementConditioned },
                                  { duct_type: HPXML::DuctTypeReturn, duct_rvalue: 0.0, duct_area: 270.0, duct_location: HPXML::LocationBasementConditioned }])
      elsif [ES::SFNationalVer3_1, ES::SFNationalVer3_2, ES::SFNationalVer3_3, ES::SFFloridaVer3_1,
             ES::MFNationalVer1_1, ES::MFNationalVer1_2, ES::MFNationalVer1_3,
             ZERH::Ver1, ZERH::SFVer2, ZERH::MFVer2].include? program_version
        _check_ducts(hpxml_bldg, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 0.0, duct_area: 729.0, duct_location: HPXML::LocationConditionedSpace },
                                  { duct_type: HPXML::DuctTypeReturn, duct_rvalue: 0.0, duct_area: 270.0, duct_location: HPXML::LocationConditionedSpace }])
      elsif [ES::MFOregonWashingtonVer1_2, ES::MFNationalVer1_0].include? program_version
        return_r = (program_version != ES::MFOregonWashingtonVer1_2 ? 6.0 : 8.0)
        _check_ducts(hpxml_bldg, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 8.0, duct_area: 729.0, duct_location: HPXML::LocationAtticVented },
                                  { duct_type: HPXML::DuctTypeReturn, duct_rvalue: return_r, duct_area: 270.0, duct_location: HPXML::LocationAtticVented }])
      else
        fail "Unhandled program version: #{program_version}"
      end
      _check_duct_leakage(hpxml_bldg, [{ duct_type: HPXML::DuctTypeSupply, duct_leakage_units: HPXML::UnitsCFM25, duct_leakage_value: get_duct_leakage(program_version, 54.0), duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside },
                                       { duct_type: HPXML::DuctTypeReturn, duct_leakage_units: HPXML::UnitsCFM25, duct_leakage_value: get_duct_leakage(program_version, 54.0), duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside }])
    end
  end

  def test_mini_split_air_conditioner_ductless
    [*ES::AllVersions, *ZERH::AllVersions].each do |program_version|
      _convert_to_es_zerh('base-hvac-mini-split-air-conditioner-only-ductless.xml', program_version)
      hpxml_bldg = _test_ruleset(program_version)
      hvac_iq_values = get_default_hvac_iq_values(program_version)
      _check_heating_system(hpxml_bldg)
      _check_cooling_system(hpxml_bldg, [{ systype: HPXML::HVACTypeCentralAirConditioner, fuel: HPXML::FuelTypeElectricity, seer: get_central_ac_seer_cz5(program_version), frac_load: 1.0, **hvac_iq_values }])
      _check_heat_pump(hpxml_bldg)
      _check_thermostat(hpxml_bldg, control_type: HPXML::HVACControlTypeProgrammable)
      if [ES::SFNationalVer3_0, ES::SFPacificVer3_0, ES::SFOregonWashingtonVer3_2].include? program_version
        _check_ducts(hpxml_bldg, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 0.0, duct_area: 729.0, duct_location: HPXML::LocationBasementConditioned },
                                  { duct_type: HPXML::DuctTypeReturn, duct_rvalue: 0.0, duct_area: 135.0, duct_location: HPXML::LocationBasementConditioned }])
      elsif [ES::SFNationalVer3_1, ES::SFNationalVer3_2, ES::SFNationalVer3_3, ES::SFFloridaVer3_1,
             ES::MFNationalVer1_1, ES::MFNationalVer1_2, ES::MFNationalVer1_3,
             ZERH::Ver1, ZERH::SFVer2, ZERH::MFVer2].include? program_version
        _check_ducts(hpxml_bldg, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 0.0, duct_area: 729.0, duct_location: HPXML::LocationConditionedSpace },
                                  { duct_type: HPXML::DuctTypeReturn, duct_rvalue: 0.0, duct_area: 135.0, duct_location: HPXML::LocationConditionedSpace }])
      elsif [ES::MFOregonWashingtonVer1_2, ES::MFNationalVer1_0].include? program_version
        return_r = (program_version != ES::MFOregonWashingtonVer1_2 ? 6.0 : 8.0)
        _check_ducts(hpxml_bldg, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 8.0, duct_area: 729.0, duct_location: HPXML::LocationAtticVented },
                                  { duct_type: HPXML::DuctTypeReturn, duct_rvalue: return_r, duct_area: 135.0, duct_location: HPXML::LocationAtticVented }])
      else
        fail "Unhandled program version: #{program_version}"
      end
      _check_duct_leakage(hpxml_bldg, [{ duct_type: HPXML::DuctTypeSupply, duct_leakage_units: HPXML::UnitsCFM25, duct_leakage_value: get_duct_leakage(program_version, 54.0), duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside },
                                       { duct_type: HPXML::DuctTypeReturn, duct_leakage_units: HPXML::UnitsCFM25, duct_leakage_value: get_duct_leakage(program_version, 54.0), duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside }])
    end
  end

  def test_furnace_gas_and_central_air_conditioner
    [*ES::AllVersions, *ZERH::AllVersions].each do |program_version|
      _convert_to_es_zerh('base.xml', program_version)
      hpxml_bldg = _test_ruleset(program_version)
      hvac_iq_values = get_default_hvac_iq_values(program_version)
      _check_heating_system(hpxml_bldg, [{ systype: HPXML::HVACTypeFurnace, fuel: HPXML::FuelTypeNaturalGas, eff: get_gas_furnace_afue_cz5(program_version), frac_load: 1.0, **hvac_iq_values }])
      _check_cooling_system(hpxml_bldg, [{ systype: HPXML::HVACTypeCentralAirConditioner, fuel: HPXML::FuelTypeElectricity, seer: get_central_ac_seer_cz5(program_version), frac_load: 1.0, **hvac_iq_values }])
      _check_heat_pump(hpxml_bldg)
      _check_thermostat(hpxml_bldg, control_type: HPXML::HVACControlTypeProgrammable)
      if [ES::SFNationalVer3_0, ES::SFPacificVer3_0, ES::SFOregonWashingtonVer3_2].include? program_version
        _check_ducts(hpxml_bldg, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 0.0, duct_area: 729.0, duct_location: HPXML::LocationBasementConditioned },
                                  { duct_type: HPXML::DuctTypeReturn, duct_rvalue: 0.0, duct_area: 270.0, duct_location: HPXML::LocationBasementConditioned }])
      elsif [ES::SFNationalVer3_1, ES::SFNationalVer3_2, ES::SFNationalVer3_3, ES::SFFloridaVer3_1,
             ES::MFNationalVer1_1, ES::MFNationalVer1_2, ES::MFNationalVer1_3,
             ZERH::Ver1, ZERH::SFVer2, ZERH::MFVer2].include? program_version
        _check_ducts(hpxml_bldg, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 0.0, duct_area: 729.0, duct_location: HPXML::LocationConditionedSpace },
                                  { duct_type: HPXML::DuctTypeReturn, duct_rvalue: 0.0, duct_area: 270.0, duct_location: HPXML::LocationConditionedSpace }])
      elsif [ES::MFOregonWashingtonVer1_2, ES::MFNationalVer1_0].include? program_version
        return_r = (program_version != ES::MFOregonWashingtonVer1_2 ? 6.0 : 8.0)
        _check_ducts(hpxml_bldg, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 8.0, duct_area: 729.0, duct_location: HPXML::LocationAtticVented },
                                  { duct_type: HPXML::DuctTypeReturn, duct_rvalue: return_r, duct_area: 270.0, duct_location: HPXML::LocationAtticVented }])
      else
        fail "Unhandled program version: #{program_version}"
      end
      _check_duct_leakage(hpxml_bldg, [{ duct_type: HPXML::DuctTypeSupply, duct_leakage_units: HPXML::UnitsCFM25, duct_leakage_value: get_duct_leakage(program_version, 54.0), duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside },
                                       { duct_type: HPXML::DuctTypeReturn, duct_leakage_units: HPXML::UnitsCFM25, duct_leakage_value: get_duct_leakage(program_version, 54.0), duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside }])

      _convert_to_es_zerh('base-foundation-multiple.xml', program_version)
      hpxml_bldg = _test_ruleset(program_version)
      hvac_iq_values = get_default_hvac_iq_values(program_version)
      _check_heating_system(hpxml_bldg, [{ systype: HPXML::HVACTypeFurnace, fuel: HPXML::FuelTypeNaturalGas, eff: get_gas_furnace_afue_cz5(program_version), frac_load: 1.0, **hvac_iq_values }])
      _check_cooling_system(hpxml_bldg, [{ systype: HPXML::HVACTypeCentralAirConditioner, fuel: HPXML::FuelTypeElectricity, seer: get_central_ac_seer_cz5(program_version), frac_load: 1.0, **hvac_iq_values }])
      _check_heat_pump(hpxml_bldg)
      _check_thermostat(hpxml_bldg, control_type: HPXML::HVACControlTypeProgrammable)
      if [ES::SFNationalVer3_0, ES::SFPacificVer3_0, ES::SFOregonWashingtonVer3_2].include? program_version
        duct_r = (program_version != ES::SFOregonWashingtonVer3_2 ? 6.0 : 8.0)
        _check_ducts(hpxml_bldg, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: duct_r, duct_area: 364.5, duct_location: HPXML::LocationBasementUnconditioned },
                                  { duct_type: HPXML::DuctTypeReturn, duct_rvalue: duct_r, duct_area: 67.5, duct_location: HPXML::LocationBasementUnconditioned }])
      elsif [ES::SFNationalVer3_1, ES::SFNationalVer3_2, ES::SFNationalVer3_3, ES::SFFloridaVer3_1,
             ES::MFNationalVer1_1, ES::MFNationalVer1_2, ES::MFNationalVer1_3,
             ZERH::Ver1, ZERH::SFVer2, ZERH::MFVer2].include? program_version
        _check_ducts(hpxml_bldg, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 0.0, duct_area: 364.5, duct_location: HPXML::LocationConditionedSpace },
                                  { duct_type: HPXML::DuctTypeReturn, duct_rvalue: 0.0, duct_area: 67.5, duct_location: HPXML::LocationConditionedSpace }])
      elsif [ES::MFOregonWashingtonVer1_2, ES::MFNationalVer1_0].include? program_version
        return_r = (program_version != ES::MFOregonWashingtonVer1_2 ? 6.0 : 8.0)
        _check_ducts(hpxml_bldg, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 8.0, duct_area: 364.5, duct_location: HPXML::LocationAtticVented },
                                  { duct_type: HPXML::DuctTypeReturn, duct_rvalue: return_r, duct_area: 67.5, duct_location: HPXML::LocationAtticVented }])
      else
        fail "Unhandled program version: #{program_version}"
      end
      _check_duct_leakage(hpxml_bldg, [{ duct_type: HPXML::DuctTypeSupply, duct_leakage_units: HPXML::UnitsCFM25, duct_leakage_value: get_duct_leakage(program_version, 27.0), duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside },
                                       { duct_type: HPXML::DuctTypeReturn, duct_leakage_units: HPXML::UnitsCFM25, duct_leakage_value: get_duct_leakage(program_version, 27.0), duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside }])

      _convert_to_es_zerh('base-foundation-ambient.xml', program_version)
      hpxml_bldg = _test_ruleset(program_version)
      hvac_iq_values = get_default_hvac_iq_values(program_version)
      _check_heating_system(hpxml_bldg, [{ systype: HPXML::HVACTypeFurnace, fuel: HPXML::FuelTypeNaturalGas, eff: get_gas_furnace_afue_cz5(program_version), frac_load: 1.0, **hvac_iq_values }])
      _check_cooling_system(hpxml_bldg, [{ systype: HPXML::HVACTypeCentralAirConditioner, fuel: HPXML::FuelTypeElectricity, seer: get_central_ac_seer_cz5(program_version), frac_load: 1.0, **hvac_iq_values }])
      _check_heat_pump(hpxml_bldg)
      _check_thermostat(hpxml_bldg, control_type: HPXML::HVACControlTypeProgrammable)
      if [ES::SFNationalVer3_0, ES::SFPacificVer3_0, ES::SFOregonWashingtonVer3_2].include? program_version
        duct_r = (program_version != ES::SFOregonWashingtonVer3_2 ? 6.0 : 8.0)
        _check_ducts(hpxml_bldg, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: duct_r, duct_area: 364.5, duct_location: HPXML::LocationOutside },
                                  { duct_type: HPXML::DuctTypeReturn, duct_rvalue: duct_r, duct_area: 67.5, duct_location: HPXML::LocationOutside }])
      elsif [ES::SFNationalVer3_1, ES::SFNationalVer3_2, ES::SFNationalVer3_3, ES::SFFloridaVer3_1,
             ES::MFNationalVer1_1, ES::MFNationalVer1_2, ES::MFNationalVer1_3,
             ZERH::Ver1, ZERH::SFVer2, ZERH::MFVer2].include? program_version
        _check_ducts(hpxml_bldg, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 0.0, duct_area: 364.5, duct_location: HPXML::LocationConditionedSpace },
                                  { duct_type: HPXML::DuctTypeReturn, duct_rvalue: 0.0, duct_area: 67.5, duct_location: HPXML::LocationConditionedSpace }])
      elsif [ES::MFOregonWashingtonVer1_2, ES::MFNationalVer1_0].include? program_version
        return_r = (program_version != ES::MFOregonWashingtonVer1_2 ? 6.0 : 8.0)
        _check_ducts(hpxml_bldg, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 8.0, duct_area: 364.5, duct_location: HPXML::LocationAtticVented },
                                  { duct_type: HPXML::DuctTypeReturn, duct_rvalue: return_r, duct_area: 67.5, duct_location: HPXML::LocationAtticVented }])
      else
        fail "Unhandled program version: #{program_version}"
      end
      _check_duct_leakage(hpxml_bldg, [{ duct_type: HPXML::DuctTypeSupply, duct_leakage_units: HPXML::UnitsCFM25, duct_leakage_value: get_duct_leakage(program_version, 27.0), duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside },
                                       { duct_type: HPXML::DuctTypeReturn, duct_leakage_units: HPXML::UnitsCFM25, duct_leakage_value: get_duct_leakage(program_version, 27.0), duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside }])

      # Test w/ 2 stories
      _convert_to_es_zerh('base-enclosure-2stories.xml', program_version)
      hpxml_bldg = _test_ruleset(program_version)
      hvac_iq_values = get_default_hvac_iq_values(program_version)
      _check_heating_system(hpxml_bldg, [{ systype: HPXML::HVACTypeFurnace, fuel: HPXML::FuelTypeNaturalGas, eff: get_gas_furnace_afue_cz5(program_version), frac_load: 1.0, **hvac_iq_values }])
      _check_cooling_system(hpxml_bldg, [{ systype: HPXML::HVACTypeCentralAirConditioner, fuel: HPXML::FuelTypeElectricity, seer: get_central_ac_seer_cz5(program_version), frac_load: 1.0, **hvac_iq_values }])
      _check_heat_pump(hpxml_bldg)
      _check_thermostat(hpxml_bldg, control_type: HPXML::HVACControlTypeProgrammable)
      if [ES::SFNationalVer3_0, ES::SFPacificVer3_0, ES::SFOregonWashingtonVer3_2].include? program_version
        duct_r = (program_version != ES::SFOregonWashingtonVer3_2 ? 6.0 : 8.0)
        _check_ducts(hpxml_bldg, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 0.0, duct_area: 546.75, duct_location: HPXML::LocationBasementConditioned },
                                  { duct_type: HPXML::DuctTypeSupply, duct_rvalue: 8.0, duct_area: 546.75, duct_location: HPXML::LocationAtticVented },
                                  { duct_type: HPXML::DuctTypeReturn, duct_rvalue: 0.0, duct_area: 303.75, duct_location: HPXML::LocationBasementConditioned },
                                  { duct_type: HPXML::DuctTypeReturn, duct_rvalue: duct_r, duct_area: 303.75, duct_location: HPXML::LocationAtticVented }])
      elsif [ES::MFNationalVer1_0, ES::MFOregonWashingtonVer1_2].include? program_version
        return_r = (program_version != ES::MFOregonWashingtonVer1_2 ? 6.0 : 8.0)
        _check_ducts(hpxml_bldg, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 8.0, duct_area: 820.12, duct_location: HPXML::LocationAtticVented },
                                  { duct_type: HPXML::DuctTypeSupply, duct_rvalue: 0.0, duct_area: 273.37, duct_location: HPXML::LocationConditionedSpace },
                                  { duct_type: HPXML::DuctTypeReturn, duct_rvalue: return_r, duct_area: 455.63, duct_location: HPXML::LocationAtticVented },
                                  { duct_type: HPXML::DuctTypeReturn, duct_rvalue: 0.0, duct_area: 151.88, duct_location: HPXML::LocationConditionedSpace }])
      elsif [ES::SFFloridaVer3_1, ES::SFNationalVer3_1, ES::SFNationalVer3_2, ES::SFNationalVer3_3,
             ES::MFNationalVer1_1, ES::MFNationalVer1_2, ES::MFNationalVer1_3,
             ZERH::Ver1, ZERH::SFVer2, ZERH::MFVer2].include? program_version
        _check_ducts(hpxml_bldg, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 0.0, duct_area: 1093.51, duct_location: HPXML::LocationConditionedSpace },
                                  { duct_type: HPXML::DuctTypeReturn, duct_rvalue: 0.0, duct_area: 607.51, duct_location: HPXML::LocationConditionedSpace }])
      else
        fail "Unhandled program version: #{program_version}"
      end
      _check_duct_leakage(hpxml_bldg, [{ duct_type: HPXML::DuctTypeSupply, duct_leakage_units: HPXML::UnitsCFM25, duct_leakage_value: get_duct_leakage(program_version, 81.0), duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside },
                                       { duct_type: HPXML::DuctTypeReturn, duct_leakage_units: HPXML::UnitsCFM25, duct_leakage_value: get_duct_leakage(program_version, 81.0), duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside }])

      # Test w/ 2 stories
      _convert_to_es_zerh('base-foundation-multiple.xml', program_version)
      hpxml = HPXML.new(hpxml_path: @tmp_hpxml_path)
      hpxml_bldg = hpxml.buildings[0]
      hpxml_bldg.building_construction.number_of_conditioned_floors += 1
      hpxml_bldg.building_construction.number_of_conditioned_floors_above_grade += 1
      XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
      hpxml_bldg = _test_ruleset(program_version)
      hvac_iq_values = get_default_hvac_iq_values(program_version)
      _check_heating_system(hpxml_bldg, [{ systype: HPXML::HVACTypeFurnace, fuel: HPXML::FuelTypeNaturalGas, eff: get_gas_furnace_afue_cz5(program_version), frac_load: 1.0, **hvac_iq_values }])
      _check_cooling_system(hpxml_bldg, [{ systype: HPXML::HVACTypeCentralAirConditioner, fuel: HPXML::FuelTypeElectricity, seer: get_central_ac_seer_cz5(program_version), frac_load: 1.0, **hvac_iq_values }])
      _check_heat_pump(hpxml_bldg)
      _check_thermostat(hpxml_bldg, control_type: HPXML::HVACControlTypeProgrammable)
      if [ES::SFNationalVer3_0, ES::SFPacificVer3_0, ES::SFOregonWashingtonVer3_2].include? program_version
        duct_r = (program_version != ES::SFOregonWashingtonVer3_2 ? 6.0 : 8.0)
        _check_ducts(hpxml_bldg, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: duct_r, duct_area: 182.25, duct_location: HPXML::LocationBasementUnconditioned },
                                  { duct_type: HPXML::DuctTypeSupply, duct_rvalue: 8.0, duct_area: 182.25, duct_location: HPXML::LocationAtticVented },
                                  { duct_type: HPXML::DuctTypeReturn, duct_rvalue: duct_r, duct_area: 33.75, duct_location: HPXML::LocationBasementUnconditioned },
                                  { duct_type: HPXML::DuctTypeReturn, duct_rvalue: duct_r, duct_area: 33.75, duct_location: HPXML::LocationAtticVented }])
      elsif [ES::MFNationalVer1_0, ES::MFOregonWashingtonVer1_2].include? program_version
        return_r = (program_version != ES::MFOregonWashingtonVer1_2 ? 6.0 : 8.0)
        _check_ducts(hpxml_bldg, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 8.0, duct_area: 273.375, duct_location: HPXML::LocationAtticVented },
                                  { duct_type: HPXML::DuctTypeSupply, duct_rvalue: 0.0, duct_area: 91.125, duct_location: HPXML::LocationConditionedSpace },
                                  { duct_type: HPXML::DuctTypeReturn, duct_rvalue: return_r, duct_area: 50.625, duct_location: HPXML::LocationAtticVented },
                                  { duct_type: HPXML::DuctTypeReturn, duct_rvalue: 0.0, duct_area: 16.875, duct_location: HPXML::LocationConditionedSpace }])
      elsif [ES::SFFloridaVer3_1, ES::SFNationalVer3_1, ES::SFNationalVer3_2, ES::SFNationalVer3_3,
             ES::MFNationalVer1_1, ES::MFNationalVer1_2, ES::MFNationalVer1_3,
             ZERH::Ver1, ZERH::SFVer2, ZERH::MFVer2].include? program_version
        _check_ducts(hpxml_bldg, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 0.0, duct_area: 364.51, duct_location: HPXML::LocationConditionedSpace },
                                  { duct_type: HPXML::DuctTypeReturn, duct_rvalue: 0.0, duct_area: 67.5, duct_location: HPXML::LocationConditionedSpace }])
      else
        fail "Unhandled program version: #{program_version}"
      end
      _check_duct_leakage(hpxml_bldg, [{ duct_type: HPXML::DuctTypeSupply, duct_leakage_units: HPXML::UnitsCFM25, duct_leakage_value: get_duct_leakage(program_version, 27.0), duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside },
                                       { duct_type: HPXML::DuctTypeReturn, duct_leakage_units: HPXML::UnitsCFM25, duct_leakage_value: get_duct_leakage(program_version, 27.0), duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside }])

      # Test w/ 2 stories
      _convert_to_es_zerh('base-foundation-ambient.xml', program_version)
      hpxml = HPXML.new(hpxml_path: @tmp_hpxml_path)
      hpxml_bldg = hpxml.buildings[0]
      hpxml_bldg.building_construction.number_of_conditioned_floors += 1
      hpxml_bldg.building_construction.number_of_conditioned_floors_above_grade += 1
      XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
      hpxml_bldg = _test_ruleset(program_version)
      hvac_iq_values = get_default_hvac_iq_values(program_version)
      _check_heating_system(hpxml_bldg, [{ systype: HPXML::HVACTypeFurnace, fuel: HPXML::FuelTypeNaturalGas, eff: get_gas_furnace_afue_cz5(program_version), frac_load: 1.0, **hvac_iq_values }])
      _check_cooling_system(hpxml_bldg, [{ systype: HPXML::HVACTypeCentralAirConditioner, fuel: HPXML::FuelTypeElectricity, seer: get_central_ac_seer_cz5(program_version), frac_load: 1.0, **hvac_iq_values }])
      _check_heat_pump(hpxml_bldg)
      _check_thermostat(hpxml_bldg, control_type: HPXML::HVACControlTypeProgrammable)
      if [ES::SFNationalVer3_0, ES::SFPacificVer3_0, ES::SFOregonWashingtonVer3_2].include? program_version
        duct_r = (program_version != ES::SFOregonWashingtonVer3_2 ? 6.0 : 8.0)
        _check_ducts(hpxml_bldg, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: duct_r, duct_area: 182.25, duct_location: HPXML::LocationOutside },
                                  { duct_type: HPXML::DuctTypeSupply, duct_rvalue: 8.0, duct_area: 182.25, duct_location: HPXML::LocationAtticVented },
                                  { duct_type: HPXML::DuctTypeReturn, duct_rvalue: duct_r, duct_area: 33.75, duct_location: HPXML::LocationOutside },
                                  { duct_type: HPXML::DuctTypeReturn, duct_rvalue: duct_r, duct_area: 33.75, duct_location: HPXML::LocationAtticVented }])
      elsif [ES::MFNationalVer1_0, ES::MFOregonWashingtonVer1_2].include? program_version
        return_r = (program_version != ES::MFOregonWashingtonVer1_2 ? 6.0 : 8.0)
        _check_ducts(hpxml_bldg, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 8.0, duct_area: 273.375, duct_location: HPXML::LocationAtticVented },
                                  { duct_type: HPXML::DuctTypeSupply, duct_rvalue: 0.0, duct_area: 91.125, duct_location: HPXML::LocationConditionedSpace },
                                  { duct_type: HPXML::DuctTypeReturn, duct_rvalue: return_r, duct_area: 50.625, duct_location: HPXML::LocationAtticVented },
                                  { duct_type: HPXML::DuctTypeReturn, duct_rvalue: 0.0, duct_area: 16.875, duct_location: HPXML::LocationConditionedSpace }])
      elsif [ES::SFFloridaVer3_1, ES::SFNationalVer3_1, ES::SFNationalVer3_2, ES::SFNationalVer3_3,
             ES::MFNationalVer1_1, ES::MFNationalVer1_2, ES::MFNationalVer1_3,
             ZERH::Ver1, ZERH::SFVer2, ZERH::MFVer2].include? program_version
        _check_ducts(hpxml_bldg, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 0.0, duct_area: 364.51, duct_location: HPXML::LocationConditionedSpace },
                                  { duct_type: HPXML::DuctTypeReturn, duct_rvalue: 0.0, duct_area: 67.5, duct_location: HPXML::LocationConditionedSpace }])
      else
        fail "Unhandled program version: #{program_version}"
      end
      _check_duct_leakage(hpxml_bldg, [{ duct_type: HPXML::DuctTypeSupply, duct_leakage_units: HPXML::UnitsCFM25, duct_leakage_value: get_duct_leakage(program_version, 27.0), duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside },
                                       { duct_type: HPXML::DuctTypeReturn, duct_leakage_units: HPXML::UnitsCFM25, duct_leakage_value: get_duct_leakage(program_version, 27.0), duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside }])
    end
  end

  def test_multiple_hvac
    [*ES::AllVersions, *ZERH::AllVersions].each do |program_version|
      _convert_to_es_zerh('base-hvac-multiple.xml', program_version)
      hpxml_bldg = _test_ruleset(program_version)
      hvac_iq_values = get_default_hvac_iq_values(program_version)
      if [ES::SFNationalVer3_2, ES::SFNationalVer3_3,
          ES::MFNationalVer1_2, ES::MFNationalVer1_3,
          ZERH::SFVer2, ZERH::MFVer2].include? program_version
        _check_heating_system(hpxml_bldg, [{ systype: HPXML::HVACTypeFurnace, fuel: HPXML::FuelTypeNaturalGas, eff: get_gas_furnace_afue_cz5(program_version), frac_load: 0.1, **hvac_iq_values },
                                           { systype: HPXML::HVACTypeBoiler, fuel: HPXML::FuelTypeNaturalGas, eff: get_gas_boiler_afue_cz5(program_version), frac_load: 0.1 },
                                           { systype: HPXML::HVACTypeFurnace, fuel: HPXML::FuelTypeNaturalGas, eff: get_gas_furnace_afue_cz5(program_version), frac_load: 0.1, **hvac_iq_values },
                                           { systype: HPXML::HVACTypeFurnace, fuel: HPXML::FuelTypeNaturalGas, eff: get_gas_furnace_afue_cz5(program_version), frac_load: 0.1, **hvac_iq_values }])
      elsif [ES::SFFloridaVer3_1, ES::SFOregonWashingtonVer3_2, ES::SFPacificVer3_0, ES::SFNationalVer3_0, ES::SFNationalVer3_1,
             ES::MFOregonWashingtonVer1_2, ES::MFNationalVer1_0, ES::MFNationalVer1_1,
             ZERH::Ver1].include? program_version
        _check_heating_system(hpxml_bldg, [{ systype: HPXML::HVACTypeFurnace, fuel: HPXML::FuelTypeNaturalGas, eff: get_gas_furnace_afue_cz5(program_version), frac_load: 0.1, **hvac_iq_values },
                                           { systype: HPXML::HVACTypeBoiler, fuel: HPXML::FuelTypeNaturalGas, eff: get_gas_boiler_afue_cz5(program_version), frac_load: 0.1 },
                                           { systype: HPXML::HVACTypeFurnace, fuel: HPXML::FuelTypeOil, eff: get_oil_furnace_afue_cz5(program_version), frac_load: 0.1, **hvac_iq_values },
                                           { systype: HPXML::HVACTypeFurnace, fuel: HPXML::FuelTypeNaturalGas, eff: get_gas_furnace_afue_cz5(program_version), frac_load: 0.1, **hvac_iq_values }])
      else
        fail "Unhandled program version: #{program_version}"
      end
      _check_cooling_system(hpxml_bldg, [{ systype: HPXML::HVACTypeCentralAirConditioner, fuel: HPXML::FuelTypeElectricity, seer: get_central_ac_seer_cz5(program_version), frac_load: 0.1333, **hvac_iq_values },
                                         { systype: HPXML::HVACTypeCentralAirConditioner, fuel: HPXML::FuelTypeElectricity, seer: get_central_ac_seer_cz5(program_version), frac_load: 0.1333, **hvac_iq_values },
                                         { systype: HPXML::HVACTypeCentralAirConditioner, fuel: HPXML::FuelTypeElectricity, seer: get_central_ac_seer_cz5(program_version), frac_load: 0.1333, **hvac_iq_values }])
      if [*ES::MFVersions, ZERH::MFVer2].include? program_version
        _check_heat_pump(hpxml_bldg, [{ systype: HPXML::HVACTypeHeatPumpAirToAir, fuel: HPXML::FuelTypeElectricity, hspf: get_ashp_hspf_cz5(program_version), seer: get_ashp_seer_cz5(program_version), frac_load_heat: 0.1, frac_load_cool: 0.0, backup_fuel: HPXML::FuelTypeElectricity, backup_eff: 1.0, **hvac_iq_values },
                                      { systype: HPXML::HVACTypeHeatPumpAirToAir, fuel: HPXML::FuelTypeElectricity, hspf: get_ashp_hspf_cz5(program_version), seer: get_ashp_seer_cz5(program_version), frac_load_heat: 0.1, frac_load_cool: 0.0, backup_fuel: HPXML::FuelTypeElectricity, backup_eff: 1.0, **hvac_iq_values },
                                      { systype: HPXML::HVACTypeHeatPumpAirToAir, fuel: HPXML::FuelTypeElectricity, hspf: get_ashp_hspf_cz5(program_version), seer: get_ashp_seer_cz5(program_version), frac_load_heat: 0.1, frac_load_cool: 0.0, backup_fuel: HPXML::FuelTypeElectricity, backup_eff: 1.0, **hvac_iq_values },
                                      { systype: HPXML::HVACTypeHeatPumpAirToAir, fuel: HPXML::FuelTypeElectricity, hspf: get_ashp_hspf_cz5(program_version), seer: get_ashp_seer_cz5(program_version), frac_load_heat: 0.1, frac_load_cool: 0.2, backup_fuel: HPXML::FuelTypeElectricity, backup_eff: 1.0, **hvac_iq_values },
                                      { systype: HPXML::HVACTypeHeatPumpGroundToAir, fuel: HPXML::FuelTypeElectricity, cop: get_gshp_cop_cz5(program_version), eer: get_gshp_eer_cz5(program_version), frac_load_heat: 0.1, frac_load_cool: 0.2, pump_w_per_ton: 80, is_shared_system: false, **hvac_iq_values },
                                      { systype: HPXML::HVACTypeHeatPumpAirToAir, fuel: HPXML::FuelTypeElectricity, hspf: get_ashp_hspf_cz5(program_version), seer: get_ashp_seer_cz5(program_version), frac_load_heat: 0.1, frac_load_cool: 0.2, backup_fuel: HPXML::FuelTypeElectricity, backup_eff: 1.0, **hvac_iq_values }])
      elsif [ES::SFFloridaVer3_1, ES::SFOregonWashingtonVer3_2, ES::SFPacificVer3_0, ES::SFNationalVer3_0, ES::SFNationalVer3_1, ES::SFNationalVer3_2, ES::SFNationalVer3_3,
             ZERH::Ver1, ZERH::SFVer2].include? program_version
        _check_heat_pump(hpxml_bldg, [{ systype: HPXML::HVACTypeHeatPumpAirToAir, fuel: HPXML::FuelTypeElectricity, hspf: get_ashp_hspf_cz5(program_version), seer: get_ashp_seer_cz5(program_version), frac_load_heat: 0.1, frac_load_cool: 0.0, backup_fuel: HPXML::FuelTypeElectricity, backup_eff: 1.0, **hvac_iq_values },
                                      { systype: HPXML::HVACTypeHeatPumpAirToAir, fuel: HPXML::FuelTypeElectricity, hspf: get_ashp_hspf_cz5(program_version), seer: get_ashp_seer_cz5(program_version), frac_load_heat: 0.1, frac_load_cool: 0.0, backup_fuel: HPXML::FuelTypeElectricity, backup_eff: 1.0, **hvac_iq_values },
                                      { systype: HPXML::HVACTypeHeatPumpAirToAir, fuel: HPXML::FuelTypeElectricity, hspf: get_ashp_hspf_cz5(program_version), seer: get_ashp_seer_cz5(program_version), frac_load_heat: 0.1, frac_load_cool: 0.0, backup_fuel: HPXML::FuelTypeElectricity, backup_eff: 1.0, **hvac_iq_values },
                                      { systype: HPXML::HVACTypeHeatPumpAirToAir, fuel: HPXML::FuelTypeElectricity, hspf: get_ashp_hspf_cz5(program_version), seer: get_ashp_seer_cz5(program_version), frac_load_heat: 0.1, frac_load_cool: 0.2, backup_fuel: HPXML::FuelTypeElectricity, backup_eff: 1.0, **hvac_iq_values },
                                      { systype: HPXML::HVACTypeHeatPumpAirToAir, fuel: HPXML::FuelTypeElectricity, hspf: get_ashp_hspf_cz5(program_version), seer: get_ashp_seer_cz5(program_version), frac_load_heat: 0.1, frac_load_cool: 0.2, backup_fuel: HPXML::FuelTypeElectricity, backup_eff: 1.0, **hvac_iq_values },
                                      { systype: HPXML::HVACTypeHeatPumpAirToAir, fuel: HPXML::FuelTypeElectricity, hspf: get_ashp_hspf_cz5(program_version), seer: get_ashp_seer_cz5(program_version), frac_load_heat: 0.1, frac_load_cool: 0.2, backup_fuel: HPXML::FuelTypeElectricity, backup_eff: 1.0, **hvac_iq_values }])
      else
        fail "Unhandled program version: #{program_version}"
      end
      _check_thermostat(hpxml_bldg, control_type: HPXML::HVACControlTypeProgrammable)
    end
  end

  def test_partial_hvac
    [*ES::AllVersions, *ZERH::AllVersions].each do |program_version|
      _convert_to_es_zerh('base.xml', program_version)
      hpxml = HPXML.new(hpxml_path: @tmp_hpxml_path)
      hpxml_bldg = hpxml.buildings[0]
      hpxml_bldg.heating_systems[0].fraction_heat_load_served = 0.2
      hpxml_bldg.cooling_systems[0].fraction_cool_load_served = 0.3
      XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
      hpxml_bldg = _test_ruleset(program_version)
      hvac_iq_values = get_default_hvac_iq_values(program_version)
      _check_heating_system(hpxml_bldg, [{ systype: HPXML::HVACTypeFurnace, fuel: HPXML::FuelTypeNaturalGas, eff: get_gas_furnace_afue_cz5(program_version), frac_load: 0.2, **hvac_iq_values }])
      _check_cooling_system(hpxml_bldg, [{ systype: HPXML::HVACTypeCentralAirConditioner, fuel: HPXML::FuelTypeElectricity, seer: get_central_ac_seer_cz5(program_version), frac_load: 0.3, **hvac_iq_values }])
      _check_heat_pump(hpxml_bldg)
      _check_thermostat(hpxml_bldg, control_type: HPXML::HVACControlTypeProgrammable)
      if [ES::SFNationalVer3_0, ES::SFPacificVer3_0, ES::SFOregonWashingtonVer3_2].include? program_version
        _check_ducts(hpxml_bldg, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 0.0, duct_area: 729.0, duct_location: HPXML::LocationBasementConditioned },
                                  { duct_type: HPXML::DuctTypeReturn, duct_rvalue: 0.0, duct_area: 270.0, duct_location: HPXML::LocationBasementConditioned }])
      elsif [ES::SFNationalVer3_1, ES::SFNationalVer3_2, ES::SFNationalVer3_3, ES::SFFloridaVer3_1,
             ES::MFNationalVer1_1, ES::MFNationalVer1_2, ES::MFNationalVer1_3,
             ZERH::Ver1, ZERH::SFVer2, ZERH::MFVer2].include? program_version
        _check_ducts(hpxml_bldg, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 0.0, duct_area: 729.0, duct_location: HPXML::LocationConditionedSpace },
                                  { duct_type: HPXML::DuctTypeReturn, duct_rvalue: 0.0, duct_area: 270.0, duct_location: HPXML::LocationConditionedSpace }])
      elsif [ES::MFOregonWashingtonVer1_2, ES::MFNationalVer1_0].include? program_version
        return_r = (program_version != ES::MFOregonWashingtonVer1_2 ? 6.0 : 8.0)
        _check_ducts(hpxml_bldg, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 8.0, duct_area: 729.0, duct_location: HPXML::LocationAtticVented },
                                  { duct_type: HPXML::DuctTypeReturn, duct_rvalue: return_r, duct_area: 270.0, duct_location: HPXML::LocationAtticVented }])
      else
        fail "Unhandled program version: #{program_version}"
      end
      _check_duct_leakage(hpxml_bldg, [{ duct_type: HPXML::DuctTypeSupply, duct_leakage_units: HPXML::UnitsCFM25, duct_leakage_value: get_duct_leakage(program_version, 54.0), duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside },
                                       { duct_type: HPXML::DuctTypeReturn, duct_leakage_units: HPXML::UnitsCFM25, duct_leakage_value: get_duct_leakage(program_version, 54.0), duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside }])
    end
  end

  def test_shared_boiler_baseboard
    hpxml_name = 'base-bldgtype-mf-unit-shared-boiler-only-baseboard.xml'
    [*ES::AllVersions, *ZERH::AllVersions].each do |program_version|
      _convert_to_es_zerh(hpxml_name, program_version)
      hpxml = HPXML.new(hpxml_path: @tmp_hpxml_path)
      XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
      hpxml_bldg = _test_ruleset(program_version)
      if [ES::SFNationalVer3_2, ES::SFNationalVer3_3,
          ES::MFNationalVer1_2, ES::MFNationalVer1_3,
          ZERH::SFVer2, ZERH::MFVer2].include? program_version
        _check_heating_system(hpxml_bldg, [{ systype: HPXML::HVACTypeBoiler, fuel: HPXML::FuelTypeNaturalGas, eff: 0.95, num_units_served: 6, frac_load: 1.0, shared_loop_watts: 635.3 }])
      elsif [ES::SFFloridaVer3_1, ES::SFOregonWashingtonVer3_2, ES::SFPacificVer3_0, ES::SFNationalVer3_0, ES::SFNationalVer3_1,
             ES::MFOregonWashingtonVer1_2, ES::MFNationalVer1_0, ES::MFNationalVer1_1,
             ZERH::Ver1].include? program_version
        _check_heating_system(hpxml_bldg, [{ systype: HPXML::HVACTypeBoiler, fuel: HPXML::FuelTypeNaturalGas, eff: 0.86, num_units_served: 6, frac_load: 1.0, shared_loop_watts: 635.3 }])
      else
        fail "Unhandled program version: #{program_version}"
      end
      _check_cooling_system(hpxml_bldg)
      _check_heat_pump(hpxml_bldg)
      _check_thermostat(hpxml_bldg, control_type: HPXML::HVACControlTypeProgrammable)
      _check_ducts(hpxml_bldg)
      _check_duct_leakage(hpxml_bldg)

      # test with heating capacity less than 300,000 Btuh
      _convert_to_es_zerh(hpxml_name, program_version)
      hpxml = HPXML.new(hpxml_path: @tmp_hpxml_path)
      hpxml_bldg = hpxml.buildings[0]
      hpxml_bldg.heating_systems[0].heating_capacity = 290000
      XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
      hpxml_bldg = _test_ruleset(program_version)
      if [ES::SFNationalVer3_0, ES::MFNationalVer1_0].include? program_version
        _check_heating_system(hpxml_bldg, [{ systype: HPXML::HVACTypeBoiler, fuel: HPXML::FuelTypeNaturalGas, eff: 0.85, num_units_served: 6, frac_load: 1.0, shared_loop_watts: 635.3 }])
      elsif [ES::SFPacificVer3_0, ES::SFFloridaVer3_1].include? program_version
        _check_heating_system(hpxml_bldg, [{ systype: HPXML::HVACTypeBoiler, fuel: HPXML::FuelTypeNaturalGas, eff: 0.80, num_units_served: 6, frac_load: 1.0, shared_loop_watts: 635.3 }])
      elsif [ZERH::Ver1].include? program_version
        _check_heating_system(hpxml_bldg, [{ systype: HPXML::HVACTypeBoiler, fuel: HPXML::FuelTypeNaturalGas, eff: 0.94, num_units_served: 6, frac_load: 1.0, shared_loop_watts: 635.3 }])
      elsif [ES::SFNationalVer3_2, ES::SFNationalVer3_3,
             ES::MFNationalVer1_2, ES::MFNationalVer1_3,
             ZERH::SFVer2, ZERH::MFVer2].include? program_version
        _check_heating_system(hpxml_bldg, [{ systype: HPXML::HVACTypeBoiler, fuel: HPXML::FuelTypeNaturalGas, eff: 0.95, num_units_served: 6, frac_load: 1.0, shared_loop_watts: 635.3 }])
      elsif [ES::SFOregonWashingtonVer3_2, ES::SFNationalVer3_1,
             ES::MFOregonWashingtonVer1_2, ES::MFNationalVer1_1,
             ZERH::Ver1].include? program_version
        _check_heating_system(hpxml_bldg, [{ systype: HPXML::HVACTypeBoiler, fuel: HPXML::FuelTypeNaturalGas, eff: 0.90, num_units_served: 6, frac_load: 1.0, shared_loop_watts: 635.3 }])
      else
        fail "Unhandled program version: #{program_version}"
      end
      _check_cooling_system(hpxml_bldg)
      _check_heat_pump(hpxml_bldg)
      _check_thermostat(hpxml_bldg, control_type: HPXML::HVACControlTypeProgrammable)
      _check_ducts(hpxml_bldg)
      _check_duct_leakage(hpxml_bldg)
    end
  end

  def test_shared_boiler_fan_coil
    hpxml_name = 'base-bldgtype-mf-unit-shared-boiler-only-fan-coil.xml'
    [*ES::AllVersions, *ZERH::AllVersions].each do |program_version|
      _convert_to_es_zerh(hpxml_name, program_version)
      hpxml = HPXML.new(hpxml_path: @tmp_hpxml_path)
      XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
      hpxml_bldg = _test_ruleset(program_version)
      if [ES::SFNationalVer3_2, ES::SFNationalVer3_3,
          ES::MFNationalVer1_2, ES::MFNationalVer1_3,
          ZERH::SFVer2, ZERH::MFVer2].include? program_version
        _check_heating_system(hpxml_bldg, [{ systype: HPXML::HVACTypeBoiler, fuel: HPXML::FuelTypeNaturalGas, eff: 0.95, num_units_served: 6, frac_load: 1.0, shared_loop_watts: 635.3, fan_coil_watts: 150.0 }])
      elsif [ES::SFFloridaVer3_1, ES::SFOregonWashingtonVer3_2, ES::SFPacificVer3_0, ES::SFNationalVer3_0, ES::SFNationalVer3_1,
             ES::MFOregonWashingtonVer1_2, ES::MFNationalVer1_0, ES::MFNationalVer1_1,
             ZERH::Ver1].include? program_version
        _check_heating_system(hpxml_bldg, [{ systype: HPXML::HVACTypeBoiler, fuel: HPXML::FuelTypeNaturalGas, eff: 0.86, num_units_served: 6, frac_load: 1.0, shared_loop_watts: 635.3, fan_coil_watts: 150.0 }])
      else
        fail "Unhandled program version: #{program_version}"
      end
      _check_cooling_system(hpxml_bldg)
      _check_heat_pump(hpxml_bldg)
      _check_thermostat(hpxml_bldg, control_type: HPXML::HVACControlTypeProgrammable)
      if [ES::SFNationalVer3_0, ES::SFPacificVer3_0, ES::SFOregonWashingtonVer3_2].include? program_version
        return_duct_r = (program_version != ES::SFOregonWashingtonVer3_2 ? 6.0 : 8.0)
        _check_ducts(hpxml_bldg, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 8.0, duct_area: 243.0, duct_location: HPXML::LocationAtticVented },
                                  { duct_type: HPXML::DuctTypeReturn, duct_rvalue: return_duct_r, duct_area: 45.0, duct_location: HPXML::LocationAtticVented }])
      elsif [ES::SFFloridaVer3_1, ES::SFNationalVer3_1, ES::SFNationalVer3_2, ES::SFNationalVer3_3,
             ES::MFOregonWashingtonVer1_2, ES::MFNationalVer1_0, ES::MFNationalVer1_1, ES::MFNationalVer1_2, ES::MFNationalVer1_3,
             ZERH::Ver1, ZERH::SFVer2, ZERH::MFVer2].include? program_version
        _check_ducts(hpxml_bldg, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 0.0, duct_area: 243.0, duct_location: HPXML::LocationConditionedSpace },
                                  { duct_type: HPXML::DuctTypeReturn, duct_rvalue: 0.0, duct_area: 45.0, duct_location: HPXML::LocationConditionedSpace }])
      else
        fail "Unhandled program version: #{program_version}"
      end
      _check_duct_leakage(hpxml_bldg, [{ duct_type: HPXML::DuctTypeSupply, duct_leakage_units: HPXML::UnitsCFM25, duct_leakage_value: get_duct_leakage(program_version, 18.0), duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside },
                                       { duct_type: HPXML::DuctTypeReturn, duct_leakage_units: HPXML::UnitsCFM25, duct_leakage_value: get_duct_leakage(program_version, 18.0), duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside }])

      # test with heating capacity less than 300,000 Btuh
      _convert_to_es_zerh(hpxml_name, program_version)
      hpxml = HPXML.new(hpxml_path: @tmp_hpxml_path)
      hpxml_bldg = hpxml.buildings[0]
      hpxml_bldg.heating_systems[0].heating_capacity = 290000
      XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
      hpxml_bldg = _test_ruleset(program_version)
      if [ES::SFNationalVer3_0, ES::MFNationalVer1_0].include? program_version
        _check_heating_system(hpxml_bldg, [{ systype: HPXML::HVACTypeBoiler, fuel: HPXML::FuelTypeNaturalGas, eff: 0.85, num_units_served: 6, frac_load: 1.0, shared_loop_watts: 635.3, fan_coil_watts: 150.0 }])
      elsif [ES::SFPacificVer3_0, ES::SFFloridaVer3_1].include? program_version
        _check_heating_system(hpxml_bldg, [{ systype: HPXML::HVACTypeBoiler, fuel: HPXML::FuelTypeNaturalGas, eff: 0.80, num_units_served: 6, frac_load: 1.0, shared_loop_watts: 635.3, fan_coil_watts: 150.0 }])
      elsif [ZERH::Ver1].include? program_version
        _check_heating_system(hpxml_bldg, [{ systype: HPXML::HVACTypeBoiler, fuel: HPXML::FuelTypeNaturalGas, eff: 0.94, num_units_served: 6, frac_load: 1.0, shared_loop_watts: 635.3, fan_coil_watts: 150.0 }])
      elsif [ES::SFNationalVer3_2, ES::SFNationalVer3_3,
             ES::MFNationalVer1_2, ES::MFNationalVer1_3,
             ZERH::SFVer2, ZERH::MFVer2].include? program_version
        _check_heating_system(hpxml_bldg, [{ systype: HPXML::HVACTypeBoiler, fuel: HPXML::FuelTypeNaturalGas, eff: 0.95, num_units_served: 6, frac_load: 1.0, shared_loop_watts: 635.3, fan_coil_watts: 150.0 }])
      elsif [ES::SFOregonWashingtonVer3_2, ES::SFNationalVer3_1,
             ES::MFOregonWashingtonVer1_2, ES::MFNationalVer1_1].include? program_version
        _check_heating_system(hpxml_bldg, [{ systype: HPXML::HVACTypeBoiler, fuel: HPXML::FuelTypeNaturalGas, eff: 0.90, num_units_served: 6, frac_load: 1.0, shared_loop_watts: 635.3, fan_coil_watts: 150.0 }])
      else
        fail "Unhandled program version: #{program_version}"
      end
      _check_cooling_system(hpxml_bldg)
      _check_heat_pump(hpxml_bldg)
      _check_thermostat(hpxml_bldg, control_type: HPXML::HVACControlTypeProgrammable)
      if [ES::SFNationalVer3_0, ES::SFPacificVer3_0, ES::SFOregonWashingtonVer3_2].include? program_version
        return_duct_r = (program_version != ES::SFOregonWashingtonVer3_2 ? 6.0 : 8.0)
        _check_ducts(hpxml_bldg, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 8.0, duct_area: 243.0, duct_location: HPXML::LocationAtticVented },
                                  { duct_type: HPXML::DuctTypeReturn, duct_rvalue: return_duct_r, duct_area: 45.0, duct_location: HPXML::LocationAtticVented }])
      elsif [ES::SFFloridaVer3_1, ES::SFNationalVer3_1, ES::SFNationalVer3_2, ES::SFNationalVer3_3,
             ES::MFOregonWashingtonVer1_2, ES::MFNationalVer1_0, ES::MFNationalVer1_1, ES::MFNationalVer1_2, ES::MFNationalVer1_3,
             ZERH::Ver1, ZERH::SFVer2, ZERH::MFVer2].include? program_version
        _check_ducts(hpxml_bldg, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 0.0, duct_area: 243.0, duct_location: HPXML::LocationConditionedSpace },
                                  { duct_type: HPXML::DuctTypeReturn, duct_rvalue: 0.0, duct_area: 45.0, duct_location: HPXML::LocationConditionedSpace }])
      else
        fail "Unhandled program version: #{program_version}"
      end
      _check_duct_leakage(hpxml_bldg, [{ duct_type: HPXML::DuctTypeSupply, duct_leakage_units: HPXML::UnitsCFM25, duct_leakage_value: get_duct_leakage(program_version, 18.0), duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside },
                                       { duct_type: HPXML::DuctTypeReturn, duct_leakage_units: HPXML::UnitsCFM25, duct_leakage_value: get_duct_leakage(program_version, 18.0), duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside }])
    end
  end

  def test_shared_boiler_fan_coil_ducted
    hpxml_name = 'base-bldgtype-mf-unit-shared-boiler-only-fan-coil-ducted.xml'
    [*ES::AllVersions, *ZERH::AllVersions].each do |program_version|
      _convert_to_es_zerh(hpxml_name, program_version)
      hpxml = HPXML.new(hpxml_path: @tmp_hpxml_path)
      XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
      hpxml_bldg = _test_ruleset(program_version)
      if [ES::SFNationalVer3_2, ES::SFNationalVer3_3,
          ES::MFNationalVer1_2, ES::MFNationalVer1_3,
          ZERH::SFVer2, ZERH::MFVer2].include? program_version
        _check_heating_system(hpxml_bldg, [{ systype: HPXML::HVACTypeBoiler, fuel: HPXML::FuelTypeNaturalGas, eff: 0.95, num_units_served: 6, frac_load: 1.0, shared_loop_watts: 635.3, fan_coil_watts: 150.0 }])
      elsif [ES::SFFloridaVer3_1, ES::SFOregonWashingtonVer3_2, ES::SFPacificVer3_0, ES::SFNationalVer3_0, ES::SFNationalVer3_1,
             ES::MFOregonWashingtonVer1_2, ES::MFNationalVer1_0, ES::MFNationalVer1_1,
             ZERH::Ver1].include? program_version
        _check_heating_system(hpxml_bldg, [{ systype: HPXML::HVACTypeBoiler, fuel: HPXML::FuelTypeNaturalGas, eff: 0.86, num_units_served: 6, frac_load: 1.0, shared_loop_watts: 635.3, fan_coil_watts: 150.0 }])
      else
        fail "Unhandled program version: #{program_version}"
      end
      _check_cooling_system(hpxml_bldg)
      _check_heat_pump(hpxml_bldg)
      _check_thermostat(hpxml_bldg, control_type: HPXML::HVACControlTypeProgrammable)
      if [ES::SFNationalVer3_0, ES::SFPacificVer3_0, ES::SFOregonWashingtonVer3_2].include? program_version
        return_duct_r = (program_version != ES::SFOregonWashingtonVer3_2 ? 6.0 : 8.0)
        _check_ducts(hpxml_bldg, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 8.0, duct_area: 243.0, duct_location: HPXML::LocationAtticVented },
                                  { duct_type: HPXML::DuctTypeReturn, duct_rvalue: return_duct_r, duct_area: 45.0, duct_location: HPXML::LocationAtticVented }])
      elsif [ES::SFFloridaVer3_1, ES::SFNationalVer3_1, ES::SFNationalVer3_2, ES::SFNationalVer3_3,
             ES::MFOregonWashingtonVer1_2, ES::MFNationalVer1_0, ES::MFNationalVer1_1, ES::MFNationalVer1_2, ES::MFNationalVer1_3,
             ZERH::Ver1, ZERH::SFVer2, ZERH::MFVer2].include? program_version
        _check_ducts(hpxml_bldg, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 0.0, duct_area: 243.0, duct_location: HPXML::LocationConditionedSpace },
                                  { duct_type: HPXML::DuctTypeReturn, duct_rvalue: 0.0, duct_area: 45.0, duct_location: HPXML::LocationConditionedSpace }])
      else
        fail "Unhandled program version: #{program_version}"
      end
      _check_duct_leakage(hpxml_bldg, [{ duct_type: HPXML::DuctTypeSupply, duct_leakage_units: HPXML::UnitsCFM25, duct_leakage_value: get_duct_leakage(program_version, 18.0), duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside },
                                       { duct_type: HPXML::DuctTypeReturn, duct_leakage_units: HPXML::UnitsCFM25, duct_leakage_value: get_duct_leakage(program_version, 18.0), duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside }])

      # test with heating capacity less than 300,000 Btuh
      _convert_to_es_zerh(hpxml_name, program_version)
      hpxml = HPXML.new(hpxml_path: @tmp_hpxml_path)
      hpxml_bldg = hpxml.buildings[0]
      hpxml_bldg.heating_systems[0].heating_capacity = 290000
      XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
      hpxml_bldg = _test_ruleset(program_version)
      if [ES::SFNationalVer3_0, ES::MFNationalVer1_0].include? program_version
        _check_heating_system(hpxml_bldg, [{ systype: HPXML::HVACTypeBoiler, fuel: HPXML::FuelTypeNaturalGas, eff: 0.85, num_units_served: 6, frac_load: 1.0, shared_loop_watts: 635.3, fan_coil_watts: 150.0 }])
      elsif [ES::SFPacificVer3_0, ES::SFFloridaVer3_1].include? program_version
        _check_heating_system(hpxml_bldg, [{ systype: HPXML::HVACTypeBoiler, fuel: HPXML::FuelTypeNaturalGas, eff: 0.80, num_units_served: 6, frac_load: 1.0, shared_loop_watts: 635.3, fan_coil_watts: 150.0 }])
      elsif [ZERH::Ver1].include? program_version
        _check_heating_system(hpxml_bldg, [{ systype: HPXML::HVACTypeBoiler, fuel: HPXML::FuelTypeNaturalGas, eff: 0.94, num_units_served: 6, frac_load: 1.0, shared_loop_watts: 635.3, fan_coil_watts: 150.0 }])
      elsif [ES::SFNationalVer3_2, ES::SFNationalVer3_3,
             ES::MFNationalVer1_2, ES::MFNationalVer1_3,
             ZERH::SFVer2, ZERH::MFVer2].include? program_version
        _check_heating_system(hpxml_bldg, [{ systype: HPXML::HVACTypeBoiler, fuel: HPXML::FuelTypeNaturalGas, eff: 0.95, num_units_served: 6, frac_load: 1.0, shared_loop_watts: 635.3, fan_coil_watts: 150.0 }])
      elsif [ES::SFOregonWashingtonVer3_2, ES::SFNationalVer3_1,
             ES::MFOregonWashingtonVer1_2, ES::MFNationalVer1_1].include? program_version
        _check_heating_system(hpxml_bldg, [{ systype: HPXML::HVACTypeBoiler, fuel: HPXML::FuelTypeNaturalGas, eff: 0.90, num_units_served: 6, frac_load: 1.0, shared_loop_watts: 635.3, fan_coil_watts: 150.0 }])
      else
        fail "Unhandled program version: #{program_version}"
      end
      _check_cooling_system(hpxml_bldg)
      _check_heat_pump(hpxml_bldg)
      _check_thermostat(hpxml_bldg, control_type: HPXML::HVACControlTypeProgrammable)
      if [ES::SFNationalVer3_0, ES::SFPacificVer3_0, ES::SFOregonWashingtonVer3_2].include? program_version
        return_duct_r = (program_version != ES::SFOregonWashingtonVer3_2 ? 6.0 : 8.0)
        _check_ducts(hpxml_bldg, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 8.0, duct_area: 243.0, duct_location: HPXML::LocationAtticVented },
                                  { duct_type: HPXML::DuctTypeReturn, duct_rvalue: return_duct_r, duct_area: 45.0, duct_location: HPXML::LocationAtticVented }])
      elsif [ES::SFFloridaVer3_1, ES::SFNationalVer3_1, ES::SFNationalVer3_2, ES::SFNationalVer3_3,
             ES::MFOregonWashingtonVer1_2, ES::MFNationalVer1_0, ES::MFNationalVer1_1, ES::MFNationalVer1_2, ES::MFNationalVer1_3,
             ZERH::Ver1, ZERH::SFVer2, ZERH::MFVer2].include? program_version
        _check_ducts(hpxml_bldg, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 0.0, duct_area: 243.0, duct_location: HPXML::LocationConditionedSpace },
                                  { duct_type: HPXML::DuctTypeReturn, duct_rvalue: 0.0, duct_area: 45.0, duct_location: HPXML::LocationConditionedSpace }])
      else
        fail "Unhandled program version: #{program_version}"
      end
      _check_duct_leakage(hpxml_bldg, [{ duct_type: HPXML::DuctTypeSupply, duct_leakage_units: HPXML::UnitsCFM25, duct_leakage_value: get_duct_leakage(program_version, 18.0), duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside },
                                       { duct_type: HPXML::DuctTypeReturn, duct_leakage_units: HPXML::UnitsCFM25, duct_leakage_value: get_duct_leakage(program_version, 18.0), duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside }])
    end
  end

  def test_shared_boiler_water_loop_heat_pump
    hpxml_name = 'base-bldgtype-mf-unit-shared-boiler-only-water-loop-heat-pump.xml'
    [*ES::AllVersions, *ZERH::AllVersions].each do |program_version|
      _convert_to_es_zerh(hpxml_name, program_version)
      hpxml = HPXML.new(hpxml_path: @tmp_hpxml_path)
      XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
      hpxml_bldg = _test_ruleset(program_version)
      if [ES::SFNationalVer3_2, ES::SFNationalVer3_3,
          ES::MFNationalVer1_2, ES::MFNationalVer1_3,
          ZERH::SFVer2, ZERH::MFVer2].include? program_version
        _check_heating_system(hpxml_bldg, [{ systype: HPXML::HVACTypeBoiler, fuel: HPXML::FuelTypeNaturalGas, eff: 0.90, num_units_served: 6, frac_load: 1.0, shared_loop_watts: 635.3 }])
      elsif [ES::SFFloridaVer3_1, ES::SFOregonWashingtonVer3_2, ES::SFPacificVer3_0, ES::SFNationalVer3_0, ES::SFNationalVer3_1,
             ES::MFOregonWashingtonVer1_2, ES::MFNationalVer1_0, ES::MFNationalVer1_1,
             ZERH::Ver1].include? program_version
        _check_heating_system(hpxml_bldg, [{ systype: HPXML::HVACTypeBoiler, fuel: HPXML::FuelTypeNaturalGas, eff: 0.89, num_units_served: 6, frac_load: 1.0, shared_loop_watts: 635.3 }])
      else
        fail "Unhandled program version: #{program_version}"
      end
      _check_cooling_system(hpxml_bldg)
      if [ES::SFNationalVer3_2, ES::SFNationalVer3_3,
          ES::MFNationalVer1_2, ES::MFNationalVer1_3,
          ZERH::SFVer2, ZERH::MFVer2].include? program_version
        _check_heat_pump(hpxml_bldg, [{ systype: HPXML::HVACTypeHeatPumpWaterLoopToAir, fuel: HPXML::FuelTypeElectricity, cop: 4.5, eer: 15, heating_capacity: 24000.0 }])
      elsif [ES::SFFloridaVer3_1, ES::SFOregonWashingtonVer3_2, ES::SFPacificVer3_0, ES::SFNationalVer3_0, ES::SFNationalVer3_1,
             ES::MFOregonWashingtonVer1_2, ES::MFNationalVer1_0, ES::MFNationalVer1_1,
             ZERH::Ver1].include? program_version
        _check_heat_pump(hpxml_bldg, [{ systype: HPXML::HVACTypeHeatPumpWaterLoopToAir, fuel: HPXML::FuelTypeElectricity, cop: 4.2, eer: 14, heating_capacity: 24000.0 }])
      else
        fail "Unhandled program version: #{program_version}"
      end
      _check_thermostat(hpxml_bldg, control_type: HPXML::HVACControlTypeProgrammable)
      if [ES::SFNationalVer3_0, ES::SFPacificVer3_0, ES::SFOregonWashingtonVer3_2].include? program_version
        return_duct_r = (program_version != ES::SFOregonWashingtonVer3_2 ? 6.0 : 8.0)
        _check_ducts(hpxml_bldg, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 8.0, duct_area: 243.0, duct_location: HPXML::LocationAtticVented },
                                  { duct_type: HPXML::DuctTypeReturn, duct_rvalue: return_duct_r, duct_area: 45.0, duct_location: HPXML::LocationAtticVented }])
      elsif [ES::SFFloridaVer3_1, ES::SFNationalVer3_1, ES::SFNationalVer3_2, ES::SFNationalVer3_3,
             ES::MFOregonWashingtonVer1_2, ES::MFNationalVer1_0, ES::MFNationalVer1_1, ES::MFNationalVer1_2, ES::MFNationalVer1_3,
             ZERH::Ver1, ZERH::SFVer2, ZERH::MFVer2].include? program_version
        _check_ducts(hpxml_bldg, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 0.0, duct_area: 243.0, duct_location: HPXML::LocationConditionedSpace },
                                  { duct_type: HPXML::DuctTypeReturn, duct_rvalue: 0.0, duct_area: 45.0, duct_location: HPXML::LocationConditionedSpace }])
      else
        fail "Unhandled program version: #{program_version}"
      end
      _check_duct_leakage(hpxml_bldg, [{ duct_type: HPXML::DuctTypeSupply, duct_leakage_units: HPXML::UnitsCFM25, duct_leakage_value: get_duct_leakage(program_version, 18.0), duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside },
                                       { duct_type: HPXML::DuctTypeReturn, duct_leakage_units: HPXML::UnitsCFM25, duct_leakage_value: get_duct_leakage(program_version, 18.0), duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside }])

      # test w/ heating capacity less than 300,000 Btuh
      _convert_to_es_zerh(hpxml_name, program_version)
      hpxml = HPXML.new(hpxml_path: @tmp_hpxml_path)
      hpxml_bldg = hpxml.buildings[0]
      hpxml_bldg.heating_systems[0].heating_capacity = 290000
      XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
      hpxml_bldg = _test_ruleset(program_version)
      if [ES::SFNationalVer3_0, ES::MFNationalVer1_0].include? program_version
        _check_heating_system(hpxml_bldg, [{ systype: HPXML::HVACTypeBoiler, fuel: HPXML::FuelTypeNaturalGas, eff: 0.85, num_units_served: 6, frac_load: 1.0, shared_loop_watts: 635.3 }])
      elsif [ES::SFPacificVer3_0, ES::SFFloridaVer3_1].include? program_version
        _check_heating_system(hpxml_bldg, [{ systype: HPXML::HVACTypeBoiler, fuel: HPXML::FuelTypeNaturalGas, eff: 0.80, num_units_served: 6, frac_load: 1.0, shared_loop_watts: 635.3 }])
      elsif [ZERH::Ver1].include? program_version
        _check_heating_system(hpxml_bldg, [{ systype: HPXML::HVACTypeBoiler, fuel: HPXML::FuelTypeNaturalGas, eff: 0.94, num_units_served: 6, frac_load: 1.0, shared_loop_watts: 635.3 }])
      elsif [ES::SFNationalVer3_2, ES::SFNationalVer3_3,
             ES::MFNationalVer1_2, ES::MFNationalVer1_3,
             ZERH::SFVer2, ZERH::MFVer2].include? program_version
        _check_heating_system(hpxml_bldg, [{ systype: HPXML::HVACTypeBoiler, fuel: HPXML::FuelTypeNaturalGas, eff: 0.95, num_units_served: 6, frac_load: 1.0, shared_loop_watts: 635.3 }])
      elsif [ES::SFOregonWashingtonVer3_2, ES::SFNationalVer3_1,
             ES::MFOregonWashingtonVer1_2, ES::MFNationalVer1_1].include? program_version
        _check_heating_system(hpxml_bldg, [{ systype: HPXML::HVACTypeBoiler, fuel: HPXML::FuelTypeNaturalGas, eff: 0.90, num_units_served: 6, frac_load: 1.0, shared_loop_watts: 635.3 }])
      else
        fail "Unhandled program version: #{program_version}"
      end
      _check_cooling_system(hpxml_bldg)
      if [ES::SFNationalVer3_2, ES::SFNationalVer3_3,
          ES::MFNationalVer1_2, ES::MFNationalVer1_3,
          ZERH::SFVer2, ZERH::MFVer2].include? program_version
        _check_heat_pump(hpxml_bldg, [{ systype: HPXML::HVACTypeHeatPumpWaterLoopToAir, fuel: HPXML::FuelTypeElectricity, cop: 4.5, eer: 15, heating_capacity: 24000.0 }])
      elsif [ES::SFFloridaVer3_1, ES::SFOregonWashingtonVer3_2, ES::SFPacificVer3_0, ES::SFNationalVer3_0, ES::SFNationalVer3_1,
             ES::MFOregonWashingtonVer1_2, ES::MFNationalVer1_0, ES::MFNationalVer1_1,
             ZERH::Ver1].include? program_version
        _check_heat_pump(hpxml_bldg, [{ systype: HPXML::HVACTypeHeatPumpWaterLoopToAir, fuel: HPXML::FuelTypeElectricity, cop: 4.2, eer: 14, heating_capacity: 24000.0 }])
      else
        fail "Unhandled program version: #{program_version}"
      end
      _check_thermostat(hpxml_bldg, control_type: HPXML::HVACControlTypeProgrammable)
      if [ES::SFNationalVer3_0, ES::SFPacificVer3_0, ES::SFOregonWashingtonVer3_2].include? program_version
        return_duct_r = (program_version != ES::SFOregonWashingtonVer3_2 ? 6.0 : 8.0)
        _check_ducts(hpxml_bldg, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 8.0, duct_area: 243.0, duct_location: HPXML::LocationAtticVented },
                                  { duct_type: HPXML::DuctTypeReturn, duct_rvalue: return_duct_r, duct_area: 45.0, duct_location: HPXML::LocationAtticVented }])
      elsif [ES::SFFloridaVer3_1, ES::SFNationalVer3_1, ES::SFNationalVer3_2, ES::SFNationalVer3_3,
             ES::MFOregonWashingtonVer1_2, ES::MFNationalVer1_0, ES::MFNationalVer1_1, ES::MFNationalVer1_2, ES::MFNationalVer1_3,
             ZERH::Ver1, ZERH::SFVer2, ZERH::MFVer2].include? program_version
        _check_ducts(hpxml_bldg, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 0.0, duct_area: 243.0, duct_location: HPXML::LocationConditionedSpace },
                                  { duct_type: HPXML::DuctTypeReturn, duct_rvalue: 0.0, duct_area: 45.0, duct_location: HPXML::LocationConditionedSpace }])
      else
        fail "Unhandled program version: #{program_version}"
      end
      _check_duct_leakage(hpxml_bldg, [{ duct_type: HPXML::DuctTypeSupply, duct_leakage_units: HPXML::UnitsCFM25, duct_leakage_value: get_duct_leakage(program_version, 18.0), duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside },
                                       { duct_type: HPXML::DuctTypeReturn, duct_leakage_units: HPXML::UnitsCFM25, duct_leakage_value: get_duct_leakage(program_version, 18.0), duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside }])
    end
  end

  def test_shared_chiller_baseboard
    hpxml_name = 'base-bldgtype-mf-unit-shared-chiller-only-baseboard.xml'
    [*ES::AllVersions, *ZERH::AllVersions].each do |program_version|
      _convert_to_es_zerh(hpxml_name, program_version)
      hpxml_bldg = _test_ruleset(program_version)
      _check_heating_system(hpxml_bldg)
      if [ES::SFNationalVer3_2, ES::SFNationalVer3_3,
          ES::MFNationalVer1_2, ES::MFNationalVer1_3,
          ZERH::SFVer2, ZERH::MFVer2].include? program_version
        _check_cooling_system(hpxml_bldg, [{ num_units_served: 6, systype: HPXML::HVACTypeChiller, fuel: HPXML::FuelTypeElectricity, kw_per_ton: 0.75, frac_load: 1.0, shared_loop_watts: 635.3 }])
      elsif [ES::SFFloridaVer3_1, ES::SFOregonWashingtonVer3_2, ES::SFPacificVer3_0, ES::SFNationalVer3_0, ES::SFNationalVer3_1,
             ES::MFOregonWashingtonVer1_2, ES::MFNationalVer1_0, ES::MFNationalVer1_1,
             ZERH::Ver1].include? program_version
        _check_cooling_system(hpxml_bldg, [{ num_units_served: 6, systype: HPXML::HVACTypeChiller, fuel: HPXML::FuelTypeElectricity, kw_per_ton: 0.78, frac_load: 1.0, shared_loop_watts: 635.3 }])
      else
        fail "Unhandled program version: #{program_version}"
      end
      _check_heat_pump(hpxml_bldg)
      _check_thermostat(hpxml_bldg, control_type: HPXML::HVACControlTypeProgrammable)
      _check_ducts(hpxml_bldg)
      _check_duct_leakage(hpxml_bldg)
    end
  end

  def test_shared_chiller_fan_coil
    hpxml_name = 'base-bldgtype-mf-unit-shared-chiller-only-fan-coil.xml'
    [*ES::AllVersions, *ZERH::AllVersions].each do |program_version|
      _convert_to_es_zerh(hpxml_name, program_version)
      hpxml_bldg = _test_ruleset(program_version)
      _check_heating_system(hpxml_bldg)
      if [ES::SFNationalVer3_2, ES::SFNationalVer3_3,
          ES::MFNationalVer1_2, ES::MFNationalVer1_3,
          ZERH::SFVer2, ZERH::MFVer2].include? program_version
        _check_cooling_system(hpxml_bldg, [{ num_units_served: 6, systype: HPXML::HVACTypeChiller, fuel: HPXML::FuelTypeElectricity, kw_per_ton: 0.75, frac_load: 1.0, shared_loop_watts: 635.3, fan_coil_watts: 150.0 }])
      elsif [ES::SFFloridaVer3_1, ES::SFOregonWashingtonVer3_2, ES::SFPacificVer3_0, ES::SFNationalVer3_0, ES::SFNationalVer3_1,
             ES::MFOregonWashingtonVer1_2, ES::MFNationalVer1_0, ES::MFNationalVer1_1,
             ZERH::Ver1].include? program_version
        _check_cooling_system(hpxml_bldg, [{ num_units_served: 6, systype: HPXML::HVACTypeChiller, fuel: HPXML::FuelTypeElectricity, kw_per_ton: 0.78, frac_load: 1.0, shared_loop_watts: 635.3, fan_coil_watts: 150.0 }])
      else
        fail "Unhandled program version: #{program_version}"
      end
      _check_heat_pump(hpxml_bldg)
      _check_thermostat(hpxml_bldg, control_type: HPXML::HVACControlTypeProgrammable)
      if [ES::SFNationalVer3_0, ES::SFPacificVer3_0, ES::SFOregonWashingtonVer3_2].include? program_version
        return_duct_r = (program_version != ES::SFOregonWashingtonVer3_2 ? 6.0 : 8.0)
        _check_ducts(hpxml_bldg, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 8.0, duct_area: 243.0, duct_location: HPXML::LocationAtticVented },
                                  { duct_type: HPXML::DuctTypeReturn, duct_rvalue: return_duct_r, duct_area: 45.0, duct_location: HPXML::LocationAtticVented }])
      elsif [ES::SFFloridaVer3_1, ES::SFNationalVer3_1, ES::SFNationalVer3_2, ES::SFNationalVer3_3,
             ES::MFOregonWashingtonVer1_2, ES::MFNationalVer1_0, ES::MFNationalVer1_1, ES::MFNationalVer1_2, ES::MFNationalVer1_3,
             ZERH::Ver1, ZERH::SFVer2, ZERH::MFVer2].include? program_version
        _check_ducts(hpxml_bldg, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 0.0, duct_area: 243.0, duct_location: HPXML::LocationConditionedSpace },
                                  { duct_type: HPXML::DuctTypeReturn, duct_rvalue: 0.0, duct_area: 45.0, duct_location: HPXML::LocationConditionedSpace }])
      else
        fail "Unhandled program version: #{program_version}"
      end
      _check_duct_leakage(hpxml_bldg, [{ duct_type: HPXML::DuctTypeSupply, duct_leakage_units: HPXML::UnitsCFM25, duct_leakage_value: get_duct_leakage(program_version, 18.0), duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside },
                                       { duct_type: HPXML::DuctTypeReturn, duct_leakage_units: HPXML::UnitsCFM25, duct_leakage_value: get_duct_leakage(program_version, 18.0), duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside }])
    end
  end

  def test_shared_chiller_fan_coil_ducted
    hpxml_name = 'base-bldgtype-mf-unit-shared-chiller-only-fan-coil.xml'
    [*ES::AllVersions, *ZERH::AllVersions].each do |program_version|
      _convert_to_es_zerh(hpxml_name, program_version)
      hpxml_bldg = _test_ruleset(program_version)
      _check_heating_system(hpxml_bldg)
      if [ES::SFNationalVer3_2, ES::SFNationalVer3_3,
          ES::MFNationalVer1_2, ES::MFNationalVer1_3,
          ZERH::SFVer2, ZERH::MFVer2].include? program_version
        _check_cooling_system(hpxml_bldg, [{ num_units_served: 6, systype: HPXML::HVACTypeChiller, fuel: HPXML::FuelTypeElectricity, kw_per_ton: 0.75, frac_load: 1.0, shared_loop_watts: 635.3, fan_coil_watts: 150.0 }])
      elsif [ES::SFFloridaVer3_1, ES::SFOregonWashingtonVer3_2, ES::SFPacificVer3_0, ES::SFNationalVer3_0, ES::SFNationalVer3_1,
             ES::MFOregonWashingtonVer1_2, ES::MFNationalVer1_0, ES::MFNationalVer1_1,
             ZERH::Ver1].include? program_version
        _check_cooling_system(hpxml_bldg, [{ num_units_served: 6, systype: HPXML::HVACTypeChiller, fuel: HPXML::FuelTypeElectricity, kw_per_ton: 0.78, frac_load: 1.0, shared_loop_watts: 635.3, fan_coil_watts: 150.0 }])
      else
        fail "Unhandled program version: #{program_version}"
      end
      _check_heat_pump(hpxml_bldg)
      _check_thermostat(hpxml_bldg, control_type: HPXML::HVACControlTypeProgrammable)
      if [ES::SFNationalVer3_0, ES::SFPacificVer3_0, ES::SFOregonWashingtonVer3_2].include? program_version
        return_duct_r = (program_version != ES::SFOregonWashingtonVer3_2 ? 6.0 : 8.0)
        _check_ducts(hpxml_bldg, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 8.0, duct_area: 243.0, duct_location: HPXML::LocationAtticVented },
                                  { duct_type: HPXML::DuctTypeReturn, duct_rvalue: return_duct_r, duct_area: 45.0, duct_location: HPXML::LocationAtticVented }])
      elsif [ES::SFFloridaVer3_1, ES::SFNationalVer3_1, ES::SFNationalVer3_2, ES::SFNationalVer3_3,
             ES::MFOregonWashingtonVer1_2, ES::MFNationalVer1_0, ES::MFNationalVer1_1, ES::MFNationalVer1_2, ES::MFNationalVer1_3,
             ZERH::Ver1, ZERH::SFVer2, ZERH::MFVer2].include? program_version
        _check_ducts(hpxml_bldg, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 0.0, duct_area: 243.0, duct_location: HPXML::LocationConditionedSpace },
                                  { duct_type: HPXML::DuctTypeReturn, duct_rvalue: 0.0, duct_area: 45.0, duct_location: HPXML::LocationConditionedSpace }])
      else
        fail "Unhandled program version: #{program_version}"
      end
      _check_duct_leakage(hpxml_bldg, [{ duct_type: HPXML::DuctTypeSupply, duct_leakage_units: HPXML::UnitsCFM25, duct_leakage_value: get_duct_leakage(program_version, 18.0), duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside },
                                       { duct_type: HPXML::DuctTypeReturn, duct_leakage_units: HPXML::UnitsCFM25, duct_leakage_value: get_duct_leakage(program_version, 18.0), duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside }])
    end
  end

  def test_shared_chiller_water_loop_heat_pump
    hpxml_name = 'base-bldgtype-mf-unit-shared-chiller-only-water-loop-heat-pump.xml'
    [*ES::AllVersions, *ZERH::AllVersions].each do |program_version|
      _convert_to_es_zerh(hpxml_name, program_version)
      hpxml_bldg = _test_ruleset(program_version)
      _check_heating_system(hpxml_bldg)
      if [ES::SFNationalVer3_2, ES::SFNationalVer3_3,
          ES::MFNationalVer1_2, ES::MFNationalVer1_3,
          ZERH::SFVer2, ZERH::MFVer2].include? program_version
        _check_cooling_system(hpxml_bldg, [{ num_units_served: 6, systype: HPXML::HVACTypeChiller, fuel: HPXML::FuelTypeElectricity, kw_per_ton: 0.75, frac_load: 1.0, shared_loop_watts: 635.3 }])
      elsif [ES::SFFloridaVer3_1, ES::SFOregonWashingtonVer3_2, ES::SFPacificVer3_0, ES::SFNationalVer3_0, ES::SFNationalVer3_1,
             ES::MFOregonWashingtonVer1_2, ES::MFNationalVer1_0, ES::MFNationalVer1_1,
             ZERH::Ver1].include? program_version
        _check_cooling_system(hpxml_bldg, [{ num_units_served: 6, systype: HPXML::HVACTypeChiller, fuel: HPXML::FuelTypeElectricity, kw_per_ton: 0.78, frac_load: 1.0, shared_loop_watts: 635.3 }])
      else
        fail "Unhandled program version: #{program_version}"
      end
      if [ES::SFNationalVer3_2, ES::SFNationalVer3_3,
          ES::MFNationalVer1_2, ES::MFNationalVer1_3,
          ZERH::SFVer2, ZERH::MFVer2].include? program_version
        _check_heat_pump(hpxml_bldg, [{ systype: HPXML::HVACTypeHeatPumpWaterLoopToAir, fuel: HPXML::FuelTypeElectricity, cop: 4.5, eer: 15, heating_capacity: 24000.0 }])
      elsif [ES::SFFloridaVer3_1, ES::SFOregonWashingtonVer3_2, ES::SFPacificVer3_0, ES::SFNationalVer3_0, ES::SFNationalVer3_1,
             ES::MFOregonWashingtonVer1_2, ES::MFNationalVer1_0, ES::MFNationalVer1_1,
             ZERH::Ver1].include? program_version
        _check_heat_pump(hpxml_bldg, [{ systype: HPXML::HVACTypeHeatPumpWaterLoopToAir, fuel: HPXML::FuelTypeElectricity, cop: 4.2, eer: 14, heating_capacity: 24000.0 }])
      else
        fail "Unhandled program version: #{program_version}"
      end
      _check_thermostat(hpxml_bldg, control_type: HPXML::HVACControlTypeProgrammable)
      if [ES::SFNationalVer3_0, ES::SFPacificVer3_0, ES::SFOregonWashingtonVer3_2].include? program_version
        return_duct_r = (program_version != ES::SFOregonWashingtonVer3_2 ? 6.0 : 8.0)
        _check_ducts(hpxml_bldg, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 8.0, duct_area: 243.0, duct_location: HPXML::LocationAtticVented },
                                  { duct_type: HPXML::DuctTypeReturn, duct_rvalue: return_duct_r, duct_area: 45.0, duct_location: HPXML::LocationAtticVented }])
      elsif [ES::SFFloridaVer3_1, ES::SFNationalVer3_1, ES::SFNationalVer3_2, ES::SFNationalVer3_3,
             ES::MFOregonWashingtonVer1_2, ES::MFNationalVer1_0, ES::MFNationalVer1_1, ES::MFNationalVer1_2, ES::MFNationalVer1_3,
             ZERH::Ver1, ZERH::SFVer2, ZERH::MFVer2].include? program_version
        _check_ducts(hpxml_bldg, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 0.0, duct_area: 243.0, duct_location: HPXML::LocationConditionedSpace },
                                  { duct_type: HPXML::DuctTypeReturn, duct_rvalue: 0.0, duct_area: 45.0, duct_location: HPXML::LocationConditionedSpace }])
      else
        fail "Unhandled program version: #{program_version}"
      end
      _check_duct_leakage(hpxml_bldg, [{ duct_type: HPXML::DuctTypeSupply, duct_leakage_units: HPXML::UnitsCFM25, duct_leakage_value: get_duct_leakage(program_version, 18.0), duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside },
                                       { duct_type: HPXML::DuctTypeReturn, duct_leakage_units: HPXML::UnitsCFM25, duct_leakage_value: get_duct_leakage(program_version, 18.0), duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside }])
    end
  end

  def test_shared_cooling_tower_water_loop_heat_pump
    hpxml_name = 'base-bldgtype-mf-unit-shared-cooling-tower-only-water-loop-heat-pump.xml'
    [*ES::AllVersions, *ZERH::AllVersions].each do |program_version|
      _convert_to_es_zerh(hpxml_name, program_version)
      hpxml_bldg = _test_ruleset(program_version)
      _check_heating_system(hpxml_bldg)
      _check_cooling_system(hpxml_bldg, [{ num_units_served: 6, systype: HPXML::HVACTypeCoolingTower, fuel: HPXML::FuelTypeElectricity, frac_load: 1.0, shared_loop_watts: 635.3 }])
      if [ES::SFNationalVer3_2, ES::SFNationalVer3_3,
          ES::MFNationalVer1_2, ES::MFNationalVer1_3,
          ZERH::SFVer2, ZERH::MFVer2].include? program_version
        _check_heat_pump(hpxml_bldg, [{ systype: HPXML::HVACTypeHeatPumpWaterLoopToAir, fuel: HPXML::FuelTypeElectricity, cop: 4.5, eer: 15, heating_capacity: 24000.0 }])
      elsif [ES::SFFloridaVer3_1, ES::SFOregonWashingtonVer3_2, ES::SFPacificVer3_0, ES::SFNationalVer3_0, ES::SFNationalVer3_1,
             ES::MFOregonWashingtonVer1_2, ES::MFNationalVer1_0, ES::MFNationalVer1_1,
             ZERH::Ver1].include? program_version
        _check_heat_pump(hpxml_bldg, [{ systype: HPXML::HVACTypeHeatPumpWaterLoopToAir, fuel: HPXML::FuelTypeElectricity, cop: 4.2, eer: 14, heating_capacity: 24000.0 }])
      else
        fail "Unhandled program version: #{program_version}"
      end
      _check_thermostat(hpxml_bldg, control_type: HPXML::HVACControlTypeProgrammable)
      if [ES::SFNationalVer3_0, ES::SFPacificVer3_0, ES::SFOregonWashingtonVer3_2].include? program_version
        return_duct_r = (program_version != ES::SFOregonWashingtonVer3_2 ? 6.0 : 8.0)
        _check_ducts(hpxml_bldg, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 8.0, duct_area: 243.0, duct_location: HPXML::LocationAtticVented },
                                  { duct_type: HPXML::DuctTypeReturn, duct_rvalue: return_duct_r, duct_area: 45.0, duct_location: HPXML::LocationAtticVented }])
      elsif [ES::SFFloridaVer3_1, ES::SFNationalVer3_1, ES::SFNationalVer3_2, ES::SFNationalVer3_3,
             ES::MFOregonWashingtonVer1_2, ES::MFNationalVer1_0, ES::MFNationalVer1_1, ES::MFNationalVer1_2, ES::MFNationalVer1_3,
             ZERH::Ver1, ZERH::SFVer2, ZERH::MFVer2].include? program_version
        _check_ducts(hpxml_bldg, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 0.0, duct_area: 243.0, duct_location: HPXML::LocationConditionedSpace },
                                  { duct_type: HPXML::DuctTypeReturn, duct_rvalue: 0.0, duct_area: 45.0, duct_location: HPXML::LocationConditionedSpace }])
      else
        fail "Unhandled program version: #{program_version}"
      end
      _check_duct_leakage(hpxml_bldg, [{ duct_type: HPXML::DuctTypeSupply, duct_leakage_units: HPXML::UnitsCFM25, duct_leakage_value: get_duct_leakage(program_version, 18.0), duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside },
                                       { duct_type: HPXML::DuctTypeReturn, duct_leakage_units: HPXML::UnitsCFM25, duct_leakage_value: get_duct_leakage(program_version, 18.0), duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside }])
    end
  end

  def test_shared_ground_loop_ground_source_heat_pump
    hpxml_name = 'base-bldgtype-mf-unit-shared-ground-loop-ground-to-air-heat-pump.xml'
    [*ES::AllVersions, *ZERH::AllVersions].each do |program_version|
      _convert_to_es_zerh(hpxml_name, program_version)
      hpxml_bldg = _test_ruleset(program_version)
      hvac_iq_values = get_default_hvac_iq_values(program_version)
      _check_heating_system(hpxml_bldg)
      _check_cooling_system(hpxml_bldg)
      if [*ES::MFVersions, ZERH::MFVer2].include? program_version
        _check_heat_pump(hpxml_bldg, [{ systype: HPXML::HVACTypeHeatPumpGroundToAir, fuel: HPXML::FuelTypeElectricity, num_units_served: 6, eer: get_gshp_eer_cz5(program_version), cop: get_gshp_cop_cz5(program_version), frac_load_heat: 1.0, frac_load_cool: 1.0, shared_loop_watts: 635.3, pump_w_per_ton: 80, is_shared_system: true, **hvac_iq_values }])
      elsif [ES::SFFloridaVer3_1, ES::SFOregonWashingtonVer3_2, ES::SFPacificVer3_0, ES::SFNationalVer3_0, ES::SFNationalVer3_1, ES::SFNationalVer3_2, ES::SFNationalVer3_3,
             ZERH::Ver1, ZERH::SFVer2].include? program_version
        _check_heat_pump(hpxml_bldg, [{ systype: HPXML::HVACTypeHeatPumpAirToAir, fuel: HPXML::FuelTypeElectricity, hspf: get_ashp_hspf_cz5(program_version), seer: get_ashp_seer_cz5(program_version), frac_load_heat: 1.0, frac_load_cool: 1.0, backup_fuel: HPXML::FuelTypeElectricity, backup_eff: 1.0, **hvac_iq_values }])
      else
        fail "Unhandled program version: #{program_version}"
      end
      _check_thermostat(hpxml_bldg, control_type: HPXML::HVACControlTypeProgrammable)
      if [ES::SFNationalVer3_0, ES::SFPacificVer3_0, ES::SFOregonWashingtonVer3_2].include? program_version
        return_duct_r = (program_version != ES::SFOregonWashingtonVer3_2 ? 6.0 : 8.0)
        _check_ducts(hpxml_bldg, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 8.0, duct_area: 243.0, duct_location: HPXML::LocationAtticVented },
                                  { duct_type: HPXML::DuctTypeReturn, duct_rvalue: return_duct_r, duct_area: 45.0, duct_location: HPXML::LocationAtticVented }])
      elsif [ES::SFFloridaVer3_1, ES::SFNationalVer3_1, ES::SFNationalVer3_2, ES::SFNationalVer3_3,
             ES::MFOregonWashingtonVer1_2, ES::MFNationalVer1_0, ES::MFNationalVer1_1, ES::MFNationalVer1_2, ES::MFNationalVer1_3,
             ZERH::Ver1, ZERH::SFVer2, ZERH::MFVer2].include? program_version
        _check_ducts(hpxml_bldg, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 0.0, duct_area: 243.0, duct_location: HPXML::LocationConditionedSpace },
                                  { duct_type: HPXML::DuctTypeReturn, duct_rvalue: 0.0, duct_area: 45.0, duct_location: HPXML::LocationConditionedSpace }])
      else
        fail "Unhandled program version: #{program_version}"
      end
      _check_duct_leakage(hpxml_bldg, [{ duct_type: HPXML::DuctTypeSupply, duct_leakage_units: HPXML::UnitsCFM25, duct_leakage_value: get_duct_leakage(program_version, 18.0), duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside },
                                       { duct_type: HPXML::DuctTypeReturn, duct_leakage_units: HPXML::UnitsCFM25, duct_leakage_value: get_duct_leakage(program_version, 18.0), duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside }])

      next unless [*ES::NationalVersions, *ZERH::AllVersions].include?(program_version)

      # Test in climate zone 7
      _convert_to_es_zerh(hpxml_name, program_version)
      hpxml = HPXML.new(hpxml_path: @tmp_hpxml_path)
      hpxml_bldg = hpxml.buildings[0]
      hpxml_bldg.climate_and_risk_zones.climate_zone_ieccs[0].zone = '7'
      hpxml_bldg.climate_and_risk_zones.weather_station_name = 'Duluth, MN'
      hpxml_bldg.climate_and_risk_zones.weather_station_wmo = 727450
      XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
      hpxml_bldg = _test_ruleset(program_version)
      hvac_iq_values = get_default_hvac_iq_values(program_version)
      _check_heating_system(hpxml_bldg)
      _check_cooling_system(hpxml_bldg)
      if [ES::SFNationalVer3_0, *ES::MFVersions, ZERH::Ver1, ZERH::MFVer2].include? program_version
        _check_heat_pump(hpxml_bldg, [{ systype: HPXML::HVACTypeHeatPumpGroundToAir, fuel: HPXML::FuelTypeElectricity, num_units_served: 6, eer: get_gshp_eer_cz7(program_version), cop: get_gshp_cop_cz7(program_version), frac_load_heat: 1.0, frac_load_cool: 1.0, shared_loop_watts: 635.3, pump_w_per_ton: 80, is_shared_system: true, **hvac_iq_values }])
      elsif [ES::SFFloridaVer3_1, ES::SFOregonWashingtonVer3_2, ES::SFPacificVer3_0, ES::SFNationalVer3_1, ES::SFNationalVer3_2, ES::SFNationalVer3_3,
             ZERH::SFVer2].include? program_version
        _check_heat_pump(hpxml_bldg, [{ systype: HPXML::HVACTypeHeatPumpAirToAir, fuel: HPXML::FuelTypeElectricity, hspf: get_ashp_hspf_cz7(program_version), seer: get_ashp_seer_cz7(program_version), frac_load_heat: 1.0, frac_load_cool: 1.0, backup_fuel: HPXML::FuelTypeElectricity, backup_eff: 1.0, **hvac_iq_values }])
      else
        fail "Unhandled program version: #{program_version}"
      end
      _check_thermostat(hpxml_bldg, control_type: HPXML::HVACControlTypeProgrammable)
      if [ES::SFNationalVer3_0, ES::SFPacificVer3_0, ES::SFOregonWashingtonVer3_2].include? program_version
        return_duct_r = (program_version != ES::SFOregonWashingtonVer3_2 ? 6.0 : 8.0)
        _check_ducts(hpxml_bldg, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 8.0, duct_area: 243.0, duct_location: HPXML::LocationAtticVented },
                                  { duct_type: HPXML::DuctTypeReturn, duct_rvalue: return_duct_r, duct_area: 45.0, duct_location: HPXML::LocationAtticVented }])
      elsif [ES::SFFloridaVer3_1, ES::SFNationalVer3_1, ES::SFNationalVer3_2, ES::SFNationalVer3_3,
             ES::MFOregonWashingtonVer1_2, ES::MFNationalVer1_0, ES::MFNationalVer1_1, ES::MFNationalVer1_2, ES::MFNationalVer1_3,
             ZERH::Ver1, ZERH::SFVer2, ZERH::MFVer2].include? program_version
        _check_ducts(hpxml_bldg, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 0.0, duct_area: 243.0, duct_location: HPXML::LocationConditionedSpace },
                                  { duct_type: HPXML::DuctTypeReturn, duct_rvalue: 0.0, duct_area: 45.0, duct_location: HPXML::LocationConditionedSpace }])
      else
        fail "Unhandled program version: #{program_version}"
      end
      _check_duct_leakage(hpxml_bldg, [{ duct_type: HPXML::DuctTypeSupply, duct_leakage_units: HPXML::UnitsCFM25, duct_leakage_value: get_duct_leakage(program_version, 18.0), duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside },
                                       { duct_type: HPXML::DuctTypeReturn, duct_leakage_units: HPXML::UnitsCFM25, duct_leakage_value: get_duct_leakage(program_version, 18.0), duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside }])
    end
  end

  def test_custom_setpoints
    [*ES::AllVersions, *ZERH::AllVersions].each do |program_version|
      _convert_to_es_zerh('base.xml', program_version)
      hpxml = HPXML.new(hpxml_path: @tmp_hpxml_path)
      hpxml_bldg = hpxml.buildings[0]
      hpxml_bldg.hvac_controls[0].heating_setpoint_temp = 60
      hpxml_bldg.hvac_controls[0].cooling_setpoint_temp = 80
      hpxml_bldg.hvac_controls[0].control_type = HPXML::HVACControlTypeManual
      XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
      hpxml_bldg = _test_ruleset(program_version)
      _check_thermostat(hpxml_bldg, control_type: HPXML::HVACControlTypeProgrammable)
    end
  end

  def _test_ruleset(program_version)
    print '.'

    if ES::AllVersions.include? program_version
      run_type = RunType::ES
    elsif ZERH::AllVersions.include? program_version
      run_type = RunType::ZERH
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

  def _check_heating_system(hpxml_bldg, all_expected_values = [])
    assert_equal(all_expected_values.size, hpxml_bldg.heating_systems.size)
    hpxml_bldg.heating_systems.each_with_index do |heating_system, idx|
      expected_values = all_expected_values[idx]
      if expected_values[:num_units_served].to_f > 1
        assert_equal(true, heating_system.is_shared_system)
        assert_equal(expected_values[:num_units_served], heating_system.number_of_units_served)
      else
        assert(heating_system.is_shared_system.nil? || (not heating_system.is_shared_system))
        assert(heating_system.number_of_units_served.to_f <= 1)
      end
      assert_equal(expected_values[:systype], heating_system.heating_system_type)
      assert_equal(expected_values[:fuel], heating_system.heating_system_fuel)
      if not expected_values[:eff].nil?
        assert_equal(expected_values[:eff], heating_system.heating_efficiency_afue.to_f + heating_system.heating_efficiency_percent.to_f)
      else
        assert_nil(heating_system.heating_efficiency_afue)
        assert_nil(heating_system.heating_efficiency_percent)
      end
      if not expected_values[:frac_load].nil?
        assert_equal(expected_values[:frac_load], heating_system.fraction_heat_load_served)
      else
        assert_nil(heating_system.fraction_heat_load_served)
      end
      if expected_values[:eae].nil?
        assert_nil(heating_system.electric_auxiliary_energy)
      else
        assert_in_epsilon(expected_values[:eae], heating_system.electric_auxiliary_energy, 0.01)
      end
      dist_system = heating_system.distribution_system
      if expected_values[:dse].nil?
        assert(dist_system.nil? || dist_system.annual_heating_dse.nil?)
      else
        assert_equal(expected_values[:dse], dist_system.annual_heating_dse)
      end
      if expected_values[:fan_watts_per_cfm].nil?
        assert_nil(heating_system.fan_watts_per_cfm)
      else
        assert_equal(expected_values[:fan_watts_per_cfm], heating_system.fan_watts_per_cfm)
      end
      if expected_values[:airflow_defect_ratio].nil?
        assert_nil(heating_system.airflow_defect_ratio)
      else
        assert_equal(expected_values[:airflow_defect_ratio], heating_system.airflow_defect_ratio)
      end
      if expected_values[:shared_loop_watts].nil?
        assert_nil(heating_system.shared_loop_watts)
      else
        assert_in_epsilon(expected_values[:shared_loop_watts], heating_system.shared_loop_watts, 0.01)
      end
      if expected_values[:fan_coil_watts].nil?
        assert_nil(heating_system.fan_coil_watts)
      else
        assert_in_epsilon(expected_values[:fan_coil_watts], heating_system.fan_coil_watts, 0.01)
      end
    end
  end

  def _check_heat_pump(hpxml_bldg, all_expected_values = [])
    assert_equal(all_expected_values.size, hpxml_bldg.heat_pumps.size)
    hpxml_bldg.heat_pumps.each_with_index do |heat_pump, idx|
      expected_values = all_expected_values[idx]
      if expected_values[:num_units_served].to_f > 1
        assert_equal(true, heat_pump.is_shared_system)
        assert_equal(expected_values[:num_units_served], heat_pump.number_of_units_served)
      else
        assert(heat_pump.is_shared_system.nil? || (not heat_pump.is_shared_system))
        assert(heat_pump.number_of_units_served.to_f <= 1)
      end
      assert_equal(expected_values[:systype], heat_pump.heat_pump_type)
      assert_equal(expected_values[:fuel], heat_pump.heat_pump_fuel)
      if not expected_values[:hspf].nil?
        assert_equal(expected_values[:hspf], heat_pump.heating_efficiency_hspf)
      else
        assert_nil(heat_pump.heating_efficiency_hspf)
      end
      if not expected_values[:cop].nil?
        assert_equal(expected_values[:cop], heat_pump.heating_efficiency_cop)
      else
        assert_nil(heat_pump.heating_efficiency_cop)
      end
      if not expected_values[:seer].nil?
        if not heat_pump.cooling_efficiency_seer2.nil?
          assert_in_delta(expected_values[:seer], HVAC.calc_seer_from_seer2(heat_pump), 0.1)
        else
          assert_in_delta(expected_values[:seer], heat_pump.cooling_efficiency_seer, 0.1)
        end
        assert_in_delta(get_eer_from_seer(expected_values[:seer]), heat_pump.cooling_efficiency_eer, 0.1)
        assert_equal(get_compressor_type_from_seer(expected_values[:seer]), heat_pump.compressor_type)
      else
        assert_nil(heat_pump.cooling_efficiency_seer)
        assert_nil(heat_pump.compressor_type)
      end
      if not expected_values[:eer].nil?
        if not heat_pump.cooling_efficiency_eer2.nil?
          assert_in_delta(expected_values[:eer], HVAC.calc_eer_from_eer2(heat_pump), 0.1)
        elsif not heat_pump.cooling_efficiency_ceer.nil?
          assert_in_delta(expected_values[:eer], HVAC.calc_eer_from_ceer(heat_pump), 0.1)
        else
          assert_in_delta(expected_values[:eer], heat_pump.cooling_efficiency_eer, 0.1)
        end
      end
      if not expected_values[:frac_load_heat].nil?
        assert_equal(expected_values[:frac_load_heat], heat_pump.fraction_heat_load_served)
      else
        assert_nil(heat_pump.fraction_heat_load_served)
      end
      if not expected_values[:frac_load_cool].nil?
        assert_equal(expected_values[:frac_load_cool], heat_pump.fraction_cool_load_served)
      else
        assert_nil(heat_pump.fraction_cool_load_served)
      end
      dist_system = heat_pump.distribution_system
      if expected_values[:dse].nil?
        assert(dist_system.nil? || dist_system.annual_heating_dse.nil?)
        assert(dist_system.nil? || dist_system.annual_cooling_dse.nil?)
      else
        assert_equal(expected_values[:dse], dist_system.annual_heating_dse)
        assert_equal(expected_values[:dse], dist_system.annual_cooling_dse)
      end
      if expected_values[:backup_fuel].nil?
        assert_nil(heat_pump.backup_heating_fuel)
      else
        assert_equal(expected_values[:backup_fuel], heat_pump.backup_heating_fuel)
      end
      if expected_values[:backup_eff].nil?
        assert_nil(heat_pump.backup_heating_efficiency_percent)
        assert_nil(heat_pump.backup_heating_efficiency_afue)
        assert_nil(heat_pump.backup_type)
      else
        assert_equal(expected_values[:backup_eff], heat_pump.backup_heating_efficiency_percent.to_f + heat_pump.backup_heating_efficiency_afue.to_f)
        assert_equal(HPXML::HeatPumpBackupTypeIntegrated, heat_pump.backup_type)
      end
      if expected_values[:pump_w_per_ton].nil?
        assert_nil(heat_pump.pump_watts_per_ton)
      else
        assert_equal(expected_values[:pump_w_per_ton], heat_pump.pump_watts_per_ton)
      end
      if expected_values[:fan_watts_per_cfm].nil?
        assert_nil(heat_pump.fan_watts_per_cfm)
      else
        assert_equal(expected_values[:fan_watts_per_cfm], heat_pump.fan_watts_per_cfm)
      end
      if expected_values[:airflow_defect_ratio].nil?
        assert_nil(heat_pump.airflow_defect_ratio)
      else
        assert_equal(expected_values[:airflow_defect_ratio], heat_pump.airflow_defect_ratio)
      end
      if expected_values[:charge_defect_ratio].nil?
        assert_nil(heat_pump.charge_defect_ratio)
      else
        assert_equal(expected_values[:charge_defect_ratio], heat_pump.charge_defect_ratio)
      end
      if expected_values[:shared_loop_watts].nil?
        assert_nil(heat_pump.shared_loop_watts)
      else
        assert_in_epsilon(expected_values[:shared_loop_watts], heat_pump.shared_loop_watts, 0.01)
      end
    end
  end

  def _check_cooling_system(hpxml_bldg, all_expected_values = [])
    assert_equal(all_expected_values.size, hpxml_bldg.cooling_systems.size)
    hpxml_bldg.cooling_systems.each_with_index do |cooling_system, idx|
      expected_values = all_expected_values[idx]
      if expected_values[:num_units_served].to_f > 1
        assert_equal(true, cooling_system.is_shared_system)
        assert_equal(expected_values[:num_units_served], cooling_system.number_of_units_served)
      else
        assert(cooling_system.is_shared_system.nil? || (not cooling_system.is_shared_system))
        assert(cooling_system.number_of_units_served.to_f <= 1)
      end
      assert_equal(expected_values[:systype], cooling_system.cooling_system_type)
      assert_equal(expected_values[:fuel], cooling_system.cooling_system_fuel)
      if not expected_values[:seer].nil?
        if not cooling_system.cooling_efficiency_seer2.nil?
          assert_in_epsilon(expected_values[:seer], HVAC.calc_seer_from_seer2(cooling_system), 0.1)
        else
          assert_in_epsilon(expected_values[:seer], cooling_system.cooling_efficiency_seer, 0.1)
        end
        assert_in_delta(get_eer_from_seer(expected_values[:seer]), cooling_system.cooling_efficiency_eer, 0.1)
        assert_equal(get_compressor_type_from_seer(expected_values[:seer]), cooling_system.compressor_type)
      else
        assert_nil(cooling_system.cooling_efficiency_seer)
        assert_nil(cooling_system.compressor_type)
      end
      if not expected_values[:eer].nil?
        if not cooling_system.cooling_efficiency_eer2.nil?
          assert_in_delta(expected_values[:eer], HVAC.calc_eer_from_eer2(cooling_system), 0.1)
        elsif not cooling_system.cooling_efficiency_ceer.nil?
          assert_in_delta(expected_values[:eer], HVAC.calc_eer_from_ceer(cooling_system), 0.1)
        else
          assert_in_delta(expected_values[:eer], cooling_system.cooling_efficiency_eer, 0.1)
        end
      elsif not expected_values[:ceer].nil?
        assert_in_delta(expected_values[:ceer], cooling_system.cooling_efficiency_ceer, 0.1)
      else
        assert_nil(cooling_system.cooling_efficiency_ceer)
      end
      if not expected_values[:kw_per_ton].nil?
        assert_equal(expected_values[:kw_per_ton], cooling_system.cooling_efficiency_kw_per_ton)
      else
        assert_nil(cooling_system.cooling_efficiency_kw_per_ton)
      end
      if not expected_values[:frac_load].nil?
        assert_equal(expected_values[:frac_load], cooling_system.fraction_cool_load_served)
      else
        assert_nil(cooling_system.fraction_cool_load_served)
      end
      dist_system = cooling_system.distribution_system
      if expected_values[:dse].nil?
        assert(dist_system.nil? || dist_system.annual_cooling_dse.nil?)
      else
        assert_equal(expected_values[:dse], dist_system.annual_cooling_dse)
      end
      if expected_values[:fan_watts_per_cfm].nil?
        assert_nil(cooling_system.fan_watts_per_cfm)
      else
        assert_equal(expected_values[:fan_watts_per_cfm], cooling_system.fan_watts_per_cfm)
      end
      if expected_values[:airflow_defect_ratio].nil?
        assert_nil(cooling_system.airflow_defect_ratio)
      else
        assert_equal(expected_values[:airflow_defect_ratio], cooling_system.airflow_defect_ratio)
      end
      if expected_values[:charge_defect_ratio].nil?
        assert_nil(cooling_system.charge_defect_ratio)
      else
        assert_equal(expected_values[:charge_defect_ratio], cooling_system.charge_defect_ratio)
      end
      if expected_values[:shared_loop_watts].nil?
        assert_nil(cooling_system.shared_loop_watts)
      else
        assert_in_epsilon(expected_values[:shared_loop_watts], cooling_system.shared_loop_watts, 0.01)
      end
      if expected_values[:fan_coil_watts].nil?
        assert_nil(cooling_system.fan_coil_watts)
      else
        assert_in_epsilon(expected_values[:fan_coil_watts], cooling_system.fan_coil_watts, 0.01)
      end
    end
  end

  def _check_thermostat(hpxml_bldg, control_type:, htg_sp: nil, clg_sp: nil, htg_setback: nil, htg_setback_hrs: nil, htg_setback_start_hr: nil,
                        clg_setup: nil, clg_setup_hrs: nil, clg_setup_start_hr: nil)
    assert_equal(1, hpxml_bldg.hvac_controls.size)
    hvac_control = hpxml_bldg.hvac_controls[0]
    assert_equal(control_type, hvac_control.control_type)

    if htg_sp.nil?
      assert_nil(hvac_control.heating_setpoint_temp)
    else
      assert_equal(htg_sp, hvac_control.heating_setpoint_temp)
    end
    if htg_setback.nil?
      assert_nil(hvac_control.heating_setback_temp)
    else
      assert_equal(htg_setback, hvac_control.heating_setback_temp)
    end
    if htg_setback_hrs.nil?
      assert_nil(hvac_control.heating_setback_hours_per_week)
    else
      assert_equal(htg_setback_hrs, hvac_control.heating_setback_hours_per_week)
    end
    if htg_setback_start_hr.nil?
      assert_nil(hvac_control.heating_setback_start_hour)
    else
      assert_equal(htg_setback_start_hr, hvac_control.heating_setback_start_hour)
    end

    if clg_sp.nil?
      assert_nil(hvac_control.cooling_setpoint_temp)
    else
      assert_equal(clg_sp, hvac_control.cooling_setpoint_temp)
    end
    if clg_setup.nil?
      assert_nil(hvac_control.cooling_setup_temp)
    else
      assert_equal(clg_setup, hvac_control.cooling_setup_temp)
    end
    if clg_setup_hrs.nil?
      assert_nil(hvac_control.cooling_setup_hours_per_week)
    else
      assert_equal(clg_setup_hrs, hvac_control.cooling_setup_hours_per_week)
    end
    if clg_setup_start_hr.nil?
      assert_nil(hvac_control.cooling_setup_start_hour)
    else
      assert_equal(clg_setup_start_hr, hvac_control.cooling_setup_start_hour)
    end
  end

  def _check_duct_leakage(hpxml_bldg, duct_leakage_measurements = [])
    assert_equal(duct_leakage_measurements.size, hpxml_bldg.hvac_distributions.map { |x| x.duct_leakage_measurements.size }.sum)
    idx = 0
    hpxml_bldg.hvac_distributions.each do |hvac_distribution|
      hvac_distribution.duct_leakage_measurements.each do |duct_leakage_measurement|
        if duct_leakage_measurements[idx][:duct_type].nil?
          assert_nil(duct_leakage_measurement.duct_type)
        else
          assert_equal(duct_leakage_measurement.duct_type, duct_leakage_measurements[idx][:duct_type])
        end
        if duct_leakage_measurements[idx][:duct_leakage_units].nil?
          assert_nil(duct_leakage_measurement.duct_leakage_units)
        else
          assert_equal(duct_leakage_measurement.duct_leakage_units, duct_leakage_measurements[idx][:duct_leakage_units])
        end
        if duct_leakage_measurements[idx][:duct_leakage_value].nil?
          assert_nil(duct_leakage_measurement.duct_leakage_value)
        else
          assert_equal(duct_leakage_measurement.duct_leakage_value, duct_leakage_measurements[idx][:duct_leakage_value])
        end
        if duct_leakage_measurements[idx][:duct_leakage_total_or_to_outside].nil?
          assert_nil(duct_leakage_measurement.duct_leakage_total_or_to_outside)
        else
          assert_equal(duct_leakage_measurement.duct_leakage_total_or_to_outside, duct_leakage_measurements[idx][:duct_leakage_total_or_to_outside])
        end
        idx += 1
      end
    end
  end

  def _check_ducts(hpxml_bldg, ducts = [])
    assert_equal(ducts.size, hpxml_bldg.hvac_distributions.map { |x| x.ducts.size }.sum)
    idx = 0
    hpxml_bldg.hvac_distributions.each do |hvac_distribution|
      hvac_distribution.ducts.each do |duct|
        if ducts[idx][:duct_type].nil?
          assert_nil(duct.duct_type)
        else
          assert_equal(duct.duct_type, ducts[idx][:duct_type])
        end
        if ducts[idx][:duct_area].nil?
          assert_nil(duct.duct_surface_area)
        else
          assert_in_epsilon(Float(duct.duct_surface_area), ducts[idx][:duct_area], 0.01)
        end
        if ducts[idx][:duct_rvalue].nil?
          assert_nil(duct.duct_insulation_r_value)
        else
          assert_equal(Float(duct.duct_insulation_r_value), ducts[idx][:duct_rvalue])
        end
        if ducts[idx][:duct_location].nil?
          assert_nil(duct.duct_location)
        else
          assert_equal(duct.duct_location, ducts[idx][:duct_location])
        end
        idx += 1
      end
    end
  end
end
