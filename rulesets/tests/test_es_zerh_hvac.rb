# frozen_string_literal: true

require_relative '../../hpxml-measures/HPXMLtoOpenStudio/resources/minitest_helper'
require 'openstudio'
require_relative '../main.rb'
require 'fileutils'
require_relative 'util.rb'

class EnergyStarZeroEnergyReadyHomeHVACtest < MiniTest::Test
  def setup
    @root_path = File.absolute_path(File.join(File.dirname(__FILE__), '..', '..'))
    @tmp_hpxml_path = File.join(@root_path, 'workflow', 'sample_files', 'tmp.xml')
  end

  def teardown
    File.delete(@tmp_hpxml_path) if File.exist? @tmp_hpxml_path
  end

  def get_es_zerh_duct_leakage(program_version, value_if_duct_location_not_living_space)
    if [ESConstants.SFNationalVer3_1, ESConstants.SFNationalVer3_2, ESConstants.SFFloridaVer3_1,
        ESConstants.MFNationalVer1_1, ESConstants.MFNationalVer1_2,
        ZERHConstants.Ver1, ZERHConstants.SFVer2].include? program_version
      return 0.0
    else
      return value_if_duct_location_not_living_space
    end
  end

  def get_es_zerh_central_ac_seer_cz5(program_version)
    if [ESConstants.SFPacificVer3_0].include? program_version
      return 14.5
    elsif [ESConstants.SFFloridaVer3_1].include? program_version
      return 15.0
    elsif [ESConstants.SFNationalVer3_0, ESConstants.SFNationalVer3_1, ESConstants.SFOregonWashingtonVer3_2, ESConstants.MFNationalVer1_0, ESConstants.MFNationalVer1_1, ESConstants.MFOregonWashingtonVer1_2, ZERHConstants.Ver1].include? program_version
      return 13.0
    elsif [ESConstants.SFNationalVer3_2, ESConstants.MFNationalVer1_2, ZERHConstants.SFVer2].include? program_version
      return 14.0
    end
  end

  def get_es_zerh_ashp_seer_cz5(program_version)
    if [ESConstants.SFNationalVer3_1, ESConstants.SFFloridaVer3_1, ESConstants.SFOregonWashingtonVer3_2, ESConstants.MFNationalVer1_1, ESConstants.MFOregonWashingtonVer1_2].include? program_version
      return 15.0
    elsif [ESConstants.SFPacificVer3_0, ESConstants.SFNationalVer3_0, ESConstants.MFNationalVer1_0].include? program_version
      return 14.5
    elsif [ZERHConstants.Ver1].include? program_version
      return 13.0
    elsif [ESConstants.SFNationalVer3_2, ESConstants.MFNationalVer1_2, ZERHConstants.SFVer2].include? program_version
      return 16.0
    end
  end

  def get_es_zerh_ashp_seer_cz7(program_version)
    if [ESConstants.SFNationalVer3_1, ESConstants.SFNationalVer3_2, ESConstants.MFNationalVer1_1, ESConstants.MFNationalVer1_2, ZERHConstants.SFVer2].include? program_version
      return 16.0
    end
  end

  def get_es_zerh_ashp_hspf_cz5(program_version)
    if [ESConstants.SFNationalVer3_1, ESConstants.SFNationalVer3_0, ESConstants.MFNationalVer1_0, ESConstants.MFNationalVer1_1].include? program_version
      return 9.25
    elsif [ESConstants.SFPacificVer3_0, ESConstants.SFFloridaVer3_1].include? program_version
      return 8.20
    elsif [ESConstants.SFOregonWashingtonVer3_2, ESConstants.MFOregonWashingtonVer1_2, ZERHConstants.SFVer2].include? program_version
      return 9.50
    elsif [ZERHConstants.Ver1].include? program_version
      return 10.0
    elsif [ESConstants.SFNationalVer3_2, ESConstants.MFNationalVer1_2].include? program_version
      return 9.20
    end
  end

  def get_es_zerh_ashp_hspf_cz7(program_version)
    if [ESConstants.SFNationalVer3_1, ESConstants.SFNationalVer3_2, ESConstants.MFNationalVer1_1, ESConstants.MFNationalVer1_2].include? program_version
      return 9.20
    elsif [ZERHConstants.SFVer2].include? program_version
      return 9.50
    end
  end

  def get_es_zerh_gshp_cop_cz5(program_version)
    if [ESConstants.MFNationalVer1_2, ESConstants.MFNationalVer1_1].include? program_version
      return 2.7
    end
  end

  def get_es_zerh_gshp_eer_cz5(program_version)
    if [ESConstants.MFNationalVer1_2].include? program_version
      return 14.0
    elsif [ESConstants.MFNationalVer1_1].include? program_version
      return 13.0
    end
  end

  def get_es_zerh_gshp_cop_cz7(program_version)
    if [ESConstants.SFNationalVer3_1].include? program_version
      return 3.6
    elsif [ESConstants.SFNationalVer3_0, ESConstants.SFPacificVer3_0, ESConstants.SFFloridaVer3_1, ESConstants.SFOregonWashingtonVer3_2, ESConstants.MFNationalVer1_0].include? program_version
      return 3.5
    elsif [ESConstants.MFOregonWashingtonVer1_2, ZERHConstants.SFVer2].include? program_version
      return # Never applies
    elsif [ESConstants.MFNationalVer1_2, ESConstants.MFNationalVer1_1].include? program_version
      return 2.7
    end
  end

  def get_es_zerh_gshp_eer_cz7(program_version)
    if [ESConstants.SFNationalVer3_1, ESConstants.MFNationalVer1_1, ZERHConstants.Ver1].include? program_version
      return 17.1
    elsif [ESConstants.SFNationalVer3_0, ESConstants.SFPacificVer3_0, ESConstants.SFFloridaVer3_1, ESConstants.SFOregonWashingtonVer3_2, ESConstants.MFNationalVer1_0].include? program_version
      return 16.1
    elsif [ESConstants.MFOregonWashingtonVer1_2, ZERHConstants.SFVer2].include? program_version
      return # Never applies
    elsif [ESConstants.MFNationalVer1_2].include? program_version
      return 14.0
    end
  end

  def get_es_zerh_gas_boiler_afue_cz5(program_version)
    if [ESConstants.SFNationalVer3_1, ESConstants.SFOregonWashingtonVer3_2, ESConstants.MFNationalVer1_1, ESConstants.MFOregonWashingtonVer1_2].include? program_version
      return 0.90
    elsif [ESConstants.SFPacificVer3_0, ESConstants.SFFloridaVer3_1].include? program_version
      return 0.80
    elsif [ESConstants.SFNationalVer3_0, ESConstants.MFNationalVer1_0].include? program_version
      return 0.85
    elsif [ZERHConstants.Ver1].include? program_version
      return 0.94
    elsif [ESConstants.SFNationalVer3_2, ESConstants.MFNationalVer1_2, ZERHConstants.SFVer2].include? program_version
      return 0.95
    end
  end

  def get_es_zerh_gas_furnace_afue_cz5(program_version)
    if [ESConstants.SFNationalVer3_1, ESConstants.SFNationalVer3_2, ESConstants.SFOregonWashingtonVer3_2,
        ESConstants.MFNationalVer1_1, ESConstants.MFNationalVer1_2, ESConstants.MFOregonWashingtonVer1_2, ZERHConstants.SFVer2].include? program_version
      return 0.95
    elsif [ESConstants.SFPacificVer3_0, ESConstants.SFFloridaVer3_1].include? program_version
      return 0.80
    elsif [ESConstants.SFNationalVer3_0, ESConstants.MFNationalVer1_0].include? program_version
      return 0.90
    elsif [ZERHConstants.Ver1].include? program_version
      return 0.94
    end
  end

  def get_es_zerh_oil_furnace_afue_cz5(program_version)
    if [ESConstants.SFNationalVer3_1, ESConstants.SFOregonWashingtonVer3_2, ESConstants.MFNationalVer1_1, ESConstants.MFOregonWashingtonVer1_2].include? program_version
      return 0.85
    elsif [ESConstants.SFPacificVer3_0, ESConstants.SFFloridaVer3_1].include? program_version
      return 0.80
    elsif [ESConstants.SFNationalVer3_0, ESConstants.MFNationalVer1_0].include? program_version
      return 0.85
    elsif [ZERHConstants.Ver1].include? program_version
      return 0.94
    elsif [ZERHConstants.SFVer2].include? program_version
      return 0.95
    end
  end

  def get_default_hvac_iq_values(program_version)
    if [ZERHConstants.SFVer2].include? program_version
      return { charge_defect_ratio: -0.25,
               airflow_defect_ratio: -0.075,
               fan_watts_per_cfm: 0.45 }
    elsif [ESConstants.SFNationalVer3_2, ESConstants.MFNationalVer1_2].include? program_version
      return { charge_defect_ratio: -0.25,
               airflow_defect_ratio: -0.20,
               fan_watts_per_cfm: 0.52 }
    else
      # Grade 3 installation quality
      return { charge_defect_ratio: -0.25,
               airflow_defect_ratio: -0.25,
               fan_watts_per_cfm: 0.58 }
    end
  end

  def test_none
    [*ESConstants.AllVersions, *ZERHConstants.AllVersions].each do |program_version|
      _convert_to_es_zerh('base-hvac-none.xml', program_version)
      hpxml = _test_ruleset(program_version)
      _check_heating_system(hpxml)
      _check_cooling_system(hpxml)
      _check_heat_pump(hpxml)
      _check_thermostat(hpxml, control_type: HPXML::HVACControlTypeProgrammable)
      _check_ducts(hpxml)
      _check_duct_leakage(hpxml)
    end
  end

  def test_boiler_elec
    [*ESConstants.AllVersions, *ZERHConstants.AllVersions].each do |program_version|
      _convert_to_es_zerh('base-hvac-boiler-elec-only.xml', program_version)
      hpxml = _test_ruleset(program_version)
      _check_heating_system(hpxml, [{ systype: HPXML::HVACTypeBoiler, fuel: HPXML::FuelTypeElectricity, eff: 0.98, frac_load: 1.0 }])
      _check_cooling_system(hpxml)
      _check_heat_pump(hpxml)
      _check_thermostat(hpxml, control_type: HPXML::HVACControlTypeProgrammable)
      _check_ducts(hpxml)
      _check_duct_leakage(hpxml)
    end
  end

  def test_boiler_gas
    [*ESConstants.AllVersions, *ZERHConstants.AllVersions].each do |program_version|
      _convert_to_es_zerh('base-hvac-boiler-gas-only.xml', program_version)
      hpxml = _test_ruleset(program_version)
      _check_heating_system(hpxml, [{ systype: HPXML::HVACTypeBoiler, fuel: HPXML::FuelTypeNaturalGas, eff: get_es_zerh_gas_boiler_afue_cz5(program_version), frac_load: 1.0 }])
      _check_cooling_system(hpxml)
      _check_heat_pump(hpxml)
      _check_thermostat(hpxml, control_type: HPXML::HVACControlTypeProgrammable)
      _check_ducts(hpxml)
      _check_duct_leakage(hpxml)
    end
  end

  def test_furnace_elec
    [*ESConstants.AllVersions, *ZERHConstants.AllVersions].each do |program_version|
      _convert_to_es_zerh('base-hvac-furnace-elec-only.xml', program_version)
      hpxml = _test_ruleset(program_version)
      hvac_iq_values = get_default_hvac_iq_values(program_version)
      _check_heating_system(hpxml)
      _check_cooling_system(hpxml)
      _check_heat_pump(hpxml, [{ systype: HPXML::HVACTypeHeatPumpAirToAir, fuel: HPXML::FuelTypeElectricity, hspf: get_es_zerh_ashp_hspf_cz5(program_version), seer: get_es_zerh_ashp_seer_cz5(program_version), frac_load_heat: 1.0, frac_load_cool: 0.0, backup_fuel: HPXML::FuelTypeElectricity, backup_eff: 1.0, **hvac_iq_values }])
      _check_thermostat(hpxml, control_type: HPXML::HVACControlTypeProgrammable)
      if [ESConstants.SFNationalVer3_0, ESConstants.SFPacificVer3_0, ESConstants.SFOregonWashingtonVer3_2].include? program_version
        _check_ducts(hpxml, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 0.0, duct_area: 729.0, duct_location: HPXML::LocationBasementConditioned },
                             { duct_type: HPXML::DuctTypeReturn, duct_rvalue: 0.0, duct_area: 270.0, duct_location: HPXML::LocationBasementConditioned }])
      elsif [ESConstants.SFNationalVer3_1, ESConstants.SFNationalVer3_2, ESConstants.SFFloridaVer3_1,
             ESConstants.MFNationalVer1_1, ESConstants.MFNationalVer1_2,
             ZERHConstants.Ver1].include? program_version
        _check_ducts(hpxml, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 0.0, duct_area: 729.0, duct_location: HPXML::LocationLivingSpace },
                             { duct_type: HPXML::DuctTypeReturn, duct_rvalue: 0.0, duct_area: 270.0, duct_location: HPXML::LocationLivingSpace }])
      else
        return_r = (program_version != ESConstants.MFOregonWashingtonVer1_2 ? 6.0 : 8.0)
        _check_ducts(hpxml, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 8.0, duct_area: 729.0, duct_location: HPXML::LocationAtticVented },
                             { duct_type: HPXML::DuctTypeReturn, duct_rvalue: return_r, duct_area: 270.0, duct_location: HPXML::LocationAtticVented }])
      end
      _check_duct_leakage(hpxml, [{ duct_type: HPXML::DuctTypeSupply, duct_leakage_units: HPXML::UnitsCFM25, duct_leakage_value: get_es_zerh_duct_leakage(program_version, 54.0), duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside },
                                  { duct_type: HPXML::DuctTypeReturn, duct_leakage_units: HPXML::UnitsCFM25, duct_leakage_value: get_es_zerh_duct_leakage(program_version, 54.0), duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside }])
    end
  end

  def test_furnace_gas
    [*ESConstants.AllVersions, *ZERHConstants.AllVersions].each do |program_version|
      _convert_to_es_zerh('base-hvac-furnace-gas-only.xml', program_version)
      hpxml = _test_ruleset(program_version)
      hvac_iq_values = get_default_hvac_iq_values(program_version)
      _check_heating_system(hpxml, [{ systype: HPXML::HVACTypeFurnace, fuel: HPXML::FuelTypeNaturalGas, eff: get_es_zerh_gas_furnace_afue_cz5(program_version), frac_load: 1.0, **hvac_iq_values }])
      _check_cooling_system(hpxml)
      _check_heat_pump(hpxml)
      _check_thermostat(hpxml, control_type: HPXML::HVACControlTypeProgrammable)
      if [ESConstants.SFNationalVer3_0, ESConstants.SFPacificVer3_0, ESConstants.SFOregonWashingtonVer3_2].include? program_version
        _check_ducts(hpxml, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 0.0, duct_area: 729.0, duct_location: HPXML::LocationBasementConditioned },
                             { duct_type: HPXML::DuctTypeReturn, duct_rvalue: 0.0, duct_area: 270.0, duct_location: HPXML::LocationBasementConditioned }])
      elsif [ESConstants.SFNationalVer3_1, ESConstants.SFNationalVer3_2, ESConstants.SFFloridaVer3_1,
             ESConstants.MFNationalVer1_1, ESConstants.MFNationalVer1_2,
             ZERHConstants.Ver1].include? program_version
        _check_ducts(hpxml, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 0.0, duct_area: 729.0, duct_location: HPXML::LocationLivingSpace },
                             { duct_type: HPXML::DuctTypeReturn, duct_rvalue: 0.0, duct_area: 270.0, duct_location: HPXML::LocationLivingSpace }])
      else
        return_r = (program_version != ESConstants.MFOregonWashingtonVer1_2 ? 6.0 : 8.0)
        _check_ducts(hpxml, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 8.0, duct_area: 729.0, duct_location: HPXML::LocationAtticVented },
                             { duct_type: HPXML::DuctTypeReturn, duct_rvalue: return_r, duct_area: 270.0, duct_location: HPXML::LocationAtticVented }])
      end
      _check_duct_leakage(hpxml, [{ duct_type: HPXML::DuctTypeSupply, duct_leakage_units: HPXML::UnitsCFM25, duct_leakage_value: get_es_zerh_duct_leakage(program_version, 54.0), duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside },
                                  { duct_type: HPXML::DuctTypeReturn, duct_leakage_units: HPXML::UnitsCFM25, duct_leakage_value: get_es_zerh_duct_leakage(program_version, 54.0), duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside }])
    end
  end

  def test_stove_wood_pellets
    [*ESConstants.AllVersions, *ZERHConstants.AllVersions].each do |program_version|
      _convert_to_es_zerh('base-hvac-stove-wood-pellets-only.xml', program_version)
      hpxml = _test_ruleset(program_version)
      hvac_iq_values = get_default_hvac_iq_values(program_version)
      _check_heating_system(hpxml, [{ systype: HPXML::HVACTypeFurnace, fuel: HPXML::FuelTypeNaturalGas, eff: get_es_zerh_gas_furnace_afue_cz5(program_version), frac_load: 1.0, **hvac_iq_values }])
      _check_cooling_system(hpxml)
      _check_heat_pump(hpxml)
      _check_thermostat(hpxml, control_type: HPXML::HVACControlTypeProgrammable)
      if [ESConstants.SFNationalVer3_0, ESConstants.SFPacificVer3_0, ESConstants.SFOregonWashingtonVer3_2].include? program_version
        _check_ducts(hpxml, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 0.0, duct_area: 729.0, duct_location: HPXML::LocationBasementConditioned },
                             { duct_type: HPXML::DuctTypeReturn, duct_rvalue: 0.0, duct_area: 135.0, duct_location: HPXML::LocationBasementConditioned }])
      elsif [ESConstants.SFNationalVer3_1, ESConstants.SFNationalVer3_2, ESConstants.SFFloridaVer3_1,
             ESConstants.MFNationalVer1_1, ESConstants.MFNationalVer1_2,
             ZERHConstants.Ver1].include? program_version
        _check_ducts(hpxml, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 0.0, duct_area: 729.0, duct_location: HPXML::LocationLivingSpace },
                             { duct_type: HPXML::DuctTypeReturn, duct_rvalue: 0.0, duct_area: 135.0, duct_location: HPXML::LocationLivingSpace }])
      else
        return_r = (program_version != ESConstants.MFOregonWashingtonVer1_2 ? 6.0 : 8.0)
        _check_ducts(hpxml, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 8.0, duct_area: 729.0, duct_location: HPXML::LocationAtticVented },
                             { duct_type: HPXML::DuctTypeReturn, duct_rvalue: return_r, duct_area: 135.0, duct_location: HPXML::LocationAtticVented }])
      end
      _check_duct_leakage(hpxml, [{ duct_type: HPXML::DuctTypeSupply, duct_leakage_units: HPXML::UnitsCFM25, duct_leakage_value: get_es_zerh_duct_leakage(program_version, 54.0), duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside },
                                  { duct_type: HPXML::DuctTypeReturn, duct_leakage_units: HPXML::UnitsCFM25, duct_leakage_value: get_es_zerh_duct_leakage(program_version, 54.0), duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside }])
    end
  end

  def test_wall_furnace_elec
    [*ESConstants.AllVersions, *ZERHConstants.AllVersions].each do |program_version|
      _convert_to_es_zerh('base-hvac-wall-furnace-elec-only.xml', program_version)
      hpxml = _test_ruleset(program_version)
      hvac_iq_values = get_default_hvac_iq_values(program_version)
      _check_heating_system(hpxml)
      _check_cooling_system(hpxml)
      _check_heat_pump(hpxml, [{ systype: HPXML::HVACTypeHeatPumpAirToAir, fuel: HPXML::FuelTypeElectricity, hspf: get_es_zerh_ashp_hspf_cz5(program_version), seer: get_es_zerh_ashp_seer_cz5(program_version), frac_load_heat: 1.0, frac_load_cool: 0.0, backup_fuel: HPXML::FuelTypeElectricity, backup_eff: 1.0, **hvac_iq_values }])
      _check_thermostat(hpxml, control_type: HPXML::HVACControlTypeProgrammable)
      if [ESConstants.SFNationalVer3_0, ESConstants.SFPacificVer3_0, ESConstants.SFOregonWashingtonVer3_2].include? program_version
        _check_ducts(hpxml, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 0.0, duct_area: 729.0, duct_location: HPXML::LocationBasementConditioned },
                             { duct_type: HPXML::DuctTypeReturn, duct_rvalue: 0.0, duct_area: 135.0, duct_location: HPXML::LocationBasementConditioned }])
      elsif [ESConstants.SFNationalVer3_1, ESConstants.SFNationalVer3_2, ESConstants.SFFloridaVer3_1,
             ESConstants.MFNationalVer1_1, ESConstants.MFNationalVer1_2,
             ZERHConstants.Ver1].include? program_version
        _check_ducts(hpxml, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 0.0, duct_area: 729.0, duct_location: HPXML::LocationLivingSpace },
                             { duct_type: HPXML::DuctTypeReturn, duct_rvalue: 0.0, duct_area: 135.0, duct_location: HPXML::LocationLivingSpace }])
      else
        return_r = (program_version != ESConstants.MFOregonWashingtonVer1_2 ? 6.0 : 8.0)
        _check_ducts(hpxml, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 8.0, duct_area: 729.0, duct_location: HPXML::LocationAtticVented },
                             { duct_type: HPXML::DuctTypeReturn, duct_rvalue: return_r, duct_area: 135.0, duct_location: HPXML::LocationAtticVented }])
      end
      _check_duct_leakage(hpxml, [{ duct_type: HPXML::DuctTypeSupply, duct_leakage_units: HPXML::UnitsCFM25, duct_leakage_value: get_es_zerh_duct_leakage(program_version, 54.0), duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside },
                                  { duct_type: HPXML::DuctTypeReturn, duct_leakage_units: HPXML::UnitsCFM25, duct_leakage_value: get_es_zerh_duct_leakage(program_version, 54.0), duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside }])
    end
  end

  def test_elec_resistance
    [*ESConstants.AllVersions, *ZERHConstants.AllVersions].each do |program_version|
      _convert_to_es_zerh('base-hvac-elec-resistance-only.xml', program_version)
      hpxml = _test_ruleset(program_version)
      hvac_iq_values = get_default_hvac_iq_values(program_version)
      _check_heating_system(hpxml)
      _check_cooling_system(hpxml)
      _check_heat_pump(hpxml, [{ systype: HPXML::HVACTypeHeatPumpAirToAir, fuel: HPXML::FuelTypeElectricity, hspf: get_es_zerh_ashp_hspf_cz5(program_version), seer: get_es_zerh_ashp_seer_cz5(program_version), frac_load_heat: 1.0, frac_load_cool: 0.0, backup_fuel: HPXML::FuelTypeElectricity, backup_eff: 1.0, **hvac_iq_values }])
      _check_thermostat(hpxml, control_type: HPXML::HVACControlTypeProgrammable)
      if [ESConstants.SFNationalVer3_0, ESConstants.SFPacificVer3_0, ESConstants.SFOregonWashingtonVer3_2].include? program_version
        _check_ducts(hpxml, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 0.0, duct_area: 729.0, duct_location: HPXML::LocationBasementConditioned },
                             { duct_type: HPXML::DuctTypeReturn, duct_rvalue: 0.0, duct_area: 135.0, duct_location: HPXML::LocationBasementConditioned }])
      elsif [ESConstants.SFNationalVer3_1, ESConstants.SFNationalVer3_2, ESConstants.SFFloridaVer3_1,
             ESConstants.MFNationalVer1_1, ESConstants.MFNationalVer1_2,
             ZERHConstants.Ver1].include? program_version
        _check_ducts(hpxml, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 0.0, duct_area: 729.0, duct_location: HPXML::LocationLivingSpace },
                             { duct_type: HPXML::DuctTypeReturn, duct_rvalue: 0.0, duct_area: 135.0, duct_location: HPXML::LocationLivingSpace }])
      else
        return_r = (program_version != ESConstants.MFOregonWashingtonVer1_2 ? 6.0 : 8.0)
        _check_ducts(hpxml, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 8.0, duct_area: 729.0, duct_location: HPXML::LocationAtticVented },
                             { duct_type: HPXML::DuctTypeReturn, duct_rvalue: return_r, duct_area: 135.0, duct_location: HPXML::LocationAtticVented }])
      end
      _check_duct_leakage(hpxml, [{ duct_type: HPXML::DuctTypeSupply, duct_leakage_units: HPXML::UnitsCFM25, duct_leakage_value: get_es_zerh_duct_leakage(program_version, 54.0), duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside },
                                  { duct_type: HPXML::DuctTypeReturn, duct_leakage_units: HPXML::UnitsCFM25, duct_leakage_value: get_es_zerh_duct_leakage(program_version, 54.0), duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside }])

      next unless ESConstants.NationalVersions.include?(program_version)

      # Test in climate zone 7
      _convert_to_es_zerh('base-hvac-elec-resistance-only.xml', program_version)
      hpxml = HPXML.new(hpxml_path: @tmp_hpxml_path)
      hpxml.climate_and_risk_zones.climate_zone_ieccs.each do |climate_zone_iecc|
        climate_zone_iecc.zone = '7'
      end
      hpxml.climate_and_risk_zones.weather_station_name = 'Duluth, MN'
      hpxml.climate_and_risk_zones.weather_station_wmo = 727450
      XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
      hpxml = _test_ruleset(program_version)
      hvac_iq_values = get_default_hvac_iq_values(program_version)
      _check_heating_system(hpxml)
      _check_cooling_system(hpxml)
      if [ESConstants.SFNationalVer3_1, ESConstants.SFNationalVer3_2, ESConstants.MFNationalVer1_1, ESConstants.MFNationalVer1_2].include? program_version
        _check_heat_pump(hpxml, [{ systype: HPXML::HVACTypeHeatPumpAirToAir, fuel: HPXML::FuelTypeElectricity, hspf: get_es_zerh_ashp_hspf_cz7(program_version), seer: get_es_zerh_ashp_seer_cz7(program_version), frac_load_heat: 1.0, frac_load_cool: 0.0, backup_fuel: HPXML::FuelTypeElectricity, backup_eff: 1.0, **hvac_iq_values }])
      else
        _check_heat_pump(hpxml, [{ systype: HPXML::HVACTypeHeatPumpGroundToAir, fuel: HPXML::FuelTypeElectricity, cop: get_es_zerh_gshp_cop_cz7(program_version), eer: get_es_zerh_gshp_eer_cz7(program_version), frac_load_heat: 1.0, frac_load_cool: 0.0, pump_w_per_ton: 30, **hvac_iq_values }])
      end
      _check_thermostat(hpxml, control_type: HPXML::HVACControlTypeProgrammable)
      if [ESConstants.SFNationalVer3_0, ESConstants.SFPacificVer3_0, ESConstants.SFOregonWashingtonVer3_2].include? program_version
        _check_ducts(hpxml, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 0.0, duct_area: 729.0, duct_location: HPXML::LocationBasementConditioned },
                             { duct_type: HPXML::DuctTypeReturn, duct_rvalue: 0.0, duct_area: 135.0, duct_location: HPXML::LocationBasementConditioned }])
      elsif [ESConstants.SFNationalVer3_1, ESConstants.SFNationalVer3_2, ESConstants.SFFloridaVer3_1,
             ESConstants.MFNationalVer1_1, ESConstants.MFNationalVer1_2,
             ZERHConstants.Ver1].include? program_version
        _check_ducts(hpxml, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 0.0, duct_area: 729.0, duct_location: HPXML::LocationLivingSpace },
                             { duct_type: HPXML::DuctTypeReturn, duct_rvalue: 0.0, duct_area: 135.0, duct_location: HPXML::LocationLivingSpace }])
      else
        return_r = (program_version != ESConstants.MFOregonWashingtonVer1_2 ? 6.0 : 8.0)
        _check_ducts(hpxml, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 8.0, duct_area: 729.0, duct_location: HPXML::LocationAtticVented },
                             { duct_type: HPXML::DuctTypeReturn, duct_rvalue: return_r, duct_area: 135.0, duct_location: HPXML::LocationAtticVented }])
      end
      _check_duct_leakage(hpxml, [{ duct_type: HPXML::DuctTypeSupply, duct_leakage_units: HPXML::UnitsCFM25, duct_leakage_value: get_es_zerh_duct_leakage(program_version, 54.0), duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside },
                                  { duct_type: HPXML::DuctTypeReturn, duct_leakage_units: HPXML::UnitsCFM25, duct_leakage_value: get_es_zerh_duct_leakage(program_version, 54.0), duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside }])
    end
  end

  def test_air_source_heat_pump
    ['base-hvac-air-to-air-heat-pump-1-speed.xml', 'base-hvac-air-to-air-heat-pump-1-speed-seer2-hspf2.xml'].each do |hpxml_name|
      [*ESConstants.AllVersions, *ZERHConstants.AllVersions].each do |program_version|
        _convert_to_es_zerh(hpxml_name, program_version)
        hpxml = _test_ruleset(program_version)
        hvac_iq_values = get_default_hvac_iq_values(program_version)
        _check_heating_system(hpxml)
        _check_cooling_system(hpxml)
        _check_heat_pump(hpxml, [{ systype: HPXML::HVACTypeHeatPumpAirToAir, fuel: HPXML::FuelTypeElectricity, hspf: get_es_zerh_ashp_hspf_cz5(program_version), seer: get_es_zerh_ashp_seer_cz5(program_version), frac_load_heat: 1.0, frac_load_cool: 1.0, backup_fuel: HPXML::FuelTypeElectricity, backup_eff: 1.0, shr: 0.73, **hvac_iq_values }])
        _check_thermostat(hpxml, control_type: HPXML::HVACControlTypeProgrammable)
        if [ESConstants.SFNationalVer3_0, ESConstants.SFPacificVer3_0, ESConstants.SFOregonWashingtonVer3_2].include? program_version
          _check_ducts(hpxml, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 0.0, duct_area: 729.0, duct_location: HPXML::LocationBasementConditioned },
                               { duct_type: HPXML::DuctTypeReturn, duct_rvalue: 0.0, duct_area: 270.0, duct_location: HPXML::LocationBasementConditioned }])
        elsif [ESConstants.SFNationalVer3_1, ESConstants.SFNationalVer3_2, ESConstants.SFFloridaVer3_1,
               ESConstants.MFNationalVer1_1, ESConstants.MFNationalVer1_2,
               ZERHConstants.Ver1].include? program_version
          _check_ducts(hpxml, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 0.0, duct_area: 729.0, duct_location: HPXML::LocationLivingSpace },
                               { duct_type: HPXML::DuctTypeReturn, duct_rvalue: 0.0, duct_area: 270.0, duct_location: HPXML::LocationLivingSpace }])
        else
          return_r = (program_version != ESConstants.MFOregonWashingtonVer1_2 ? 6.0 : 8.0)
          _check_ducts(hpxml, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 8.0, duct_area: 729.0, duct_location: HPXML::LocationAtticVented },
                               { duct_type: HPXML::DuctTypeReturn, duct_rvalue: return_r, duct_area: 270.0, duct_location: HPXML::LocationAtticVented }])
        end
        _check_duct_leakage(hpxml, [{ duct_type: HPXML::DuctTypeSupply, duct_leakage_units: HPXML::UnitsCFM25, duct_leakage_value: get_es_zerh_duct_leakage(program_version, 54.0), duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside },
                                    { duct_type: HPXML::DuctTypeReturn, duct_leakage_units: HPXML::UnitsCFM25, duct_leakage_value: get_es_zerh_duct_leakage(program_version, 54.0), duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside }])

        next unless ESConstants.NationalVersions.include?(program_version)

        # Test in climate zone 7
        _convert_to_es_zerh(hpxml_name, program_version)
        hpxml = HPXML.new(hpxml_path: @tmp_hpxml_path)
        hpxml.climate_and_risk_zones.climate_zone_ieccs.each do |climate_zone_iecc|
          climate_zone_iecc.zone = '7'
        end
        hpxml.climate_and_risk_zones.weather_station_name = 'Duluth, MN'
        hpxml.climate_and_risk_zones.weather_station_wmo = 727450
        XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
        hpxml = _test_ruleset(program_version)
        hvac_iq_values = get_default_hvac_iq_values(program_version)
        _check_heating_system(hpxml)
        _check_cooling_system(hpxml)
        if [ESConstants.SFNationalVer3_0, ESConstants.MFNationalVer1_0].include? program_version
          _check_heat_pump(hpxml, [{ systype: HPXML::HVACTypeHeatPumpGroundToAir, fuel: HPXML::FuelTypeElectricity, cop: get_es_zerh_gshp_cop_cz7(program_version), eer: get_es_zerh_gshp_eer_cz7(program_version), frac_load_heat: 1.0, frac_load_cool: 1.0, shr: 0.73, pump_w_per_ton: 30, **hvac_iq_values }])
        else
          _check_heat_pump(hpxml, [{ systype: HPXML::HVACTypeHeatPumpAirToAir, fuel: HPXML::FuelTypeElectricity, hspf: get_es_zerh_ashp_hspf_cz7(program_version), seer: get_es_zerh_ashp_seer_cz7(program_version), frac_load_heat: 1.0, frac_load_cool: 1.0, backup_fuel: HPXML::FuelTypeElectricity, backup_eff: 1.0, shr: 0.73, **hvac_iq_values }])
        end
        _check_thermostat(hpxml, control_type: HPXML::HVACControlTypeProgrammable)
        if [ESConstants.SFNationalVer3_0, ESConstants.SFPacificVer3_0, ESConstants.SFOregonWashingtonVer3_2].include? program_version
          _check_ducts(hpxml, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 0.0, duct_area: 729.0, duct_location: HPXML::LocationBasementConditioned },
                               { duct_type: HPXML::DuctTypeReturn, duct_rvalue: 0.0, duct_area: 270.0, duct_location: HPXML::LocationBasementConditioned }])
        elsif [ESConstants.SFNationalVer3_1, ESConstants.SFNationalVer3_2, ESConstants.SFFloridaVer3_1,
               ESConstants.MFNationalVer1_1, ESConstants.MFNationalVer1_2,
               ZERHConstants.Ver1].include? program_version
          _check_ducts(hpxml, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 0.0, duct_area: 729.0, duct_location: HPXML::LocationLivingSpace },
                               { duct_type: HPXML::DuctTypeReturn, duct_rvalue: 0.0, duct_area: 270.0, duct_location: HPXML::LocationLivingSpace }])
        else
          return_r = (program_version != ESConstants.MFOregonWashingtonVer1_2 ? 6.0 : 8.0)
          _check_ducts(hpxml, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 8.0, duct_area: 729.0, duct_location: HPXML::LocationAtticVented },
                               { duct_type: HPXML::DuctTypeReturn, duct_rvalue: return_r, duct_area: 270.0, duct_location: HPXML::LocationAtticVented }])
        end
        _check_duct_leakage(hpxml, [{ duct_type: HPXML::DuctTypeSupply, duct_leakage_units: HPXML::UnitsCFM25, duct_leakage_value: get_es_zerh_duct_leakage(program_version, 54.0), duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside },
                                    { duct_type: HPXML::DuctTypeReturn, duct_leakage_units: HPXML::UnitsCFM25, duct_leakage_value: get_es_zerh_duct_leakage(program_version, 54.0), duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside }])
      end
    end
  end

  def test_mini_split_heat_pump_ducted
    [*ESConstants.AllVersions, *ZERHConstants.AllVersions].each do |program_version|
      _convert_to_es_zerh('base-hvac-mini-split-heat-pump-ducted.xml', program_version)
      hpxml = _test_ruleset(program_version)
      hvac_iq_values = get_default_hvac_iq_values(program_version)
      _check_heating_system(hpxml)
      _check_cooling_system(hpxml)
      _check_heat_pump(hpxml, [{ systype: HPXML::HVACTypeHeatPumpAirToAir, fuel: HPXML::FuelTypeElectricity, hspf: get_es_zerh_ashp_hspf_cz5(program_version), seer: get_es_zerh_ashp_seer_cz5(program_version), frac_load_heat: 1.0, frac_load_cool: 1.0, backup_fuel: HPXML::FuelTypeElectricity, backup_eff: 1.0, shr: 0.73, **hvac_iq_values }])
      _check_thermostat(hpxml, control_type: HPXML::HVACControlTypeProgrammable)
      if [ESConstants.SFNationalVer3_0, ESConstants.SFPacificVer3_0, ESConstants.SFOregonWashingtonVer3_2].include? program_version
        _check_ducts(hpxml, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 0.0, duct_area: 729.0, duct_location: HPXML::LocationBasementConditioned },
                             { duct_type: HPXML::DuctTypeReturn, duct_rvalue: 0.0, duct_area: 270.0, duct_location: HPXML::LocationBasementConditioned }])
      elsif [ESConstants.SFNationalVer3_1, ESConstants.SFNationalVer3_2, ESConstants.SFFloridaVer3_1,
             ESConstants.MFNationalVer1_1, ESConstants.MFNationalVer1_2,
             ZERHConstants.Ver1].include? program_version
        _check_ducts(hpxml, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 0.0, duct_area: 729.0, duct_location: HPXML::LocationLivingSpace },
                             { duct_type: HPXML::DuctTypeReturn, duct_rvalue: 0.0, duct_area: 270.0, duct_location: HPXML::LocationLivingSpace }])
      else
        return_r = (program_version != ESConstants.MFOregonWashingtonVer1_2 ? 6.0 : 8.0)
        _check_ducts(hpxml, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 8.0, duct_area: 729.0, duct_location: HPXML::LocationAtticVented },
                             { duct_type: HPXML::DuctTypeReturn, duct_rvalue: return_r, duct_area: 270.0, duct_location: HPXML::LocationAtticVented }])
      end
      _check_duct_leakage(hpxml, [{ duct_type: HPXML::DuctTypeSupply, duct_leakage_units: HPXML::UnitsCFM25, duct_leakage_value: get_es_zerh_duct_leakage(program_version, 54.0), duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside },
                                  { duct_type: HPXML::DuctTypeReturn, duct_leakage_units: HPXML::UnitsCFM25, duct_leakage_value: get_es_zerh_duct_leakage(program_version, 54.0), duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside }])
    end
  end

  def test_mini_split_heat_pump_ductless
    [*ESConstants.AllVersions, *ZERHConstants.AllVersions].each do |program_version|
      _convert_to_es_zerh('base-hvac-mini-split-heat-pump-ductless.xml', program_version)
      hpxml = _test_ruleset(program_version)
      hvac_iq_values = get_default_hvac_iq_values(program_version)
      _check_heating_system(hpxml)
      _check_cooling_system(hpxml)
      _check_heat_pump(hpxml, [{ systype: HPXML::HVACTypeHeatPumpAirToAir, fuel: HPXML::FuelTypeElectricity, hspf: get_es_zerh_ashp_hspf_cz5(program_version), seer: get_es_zerh_ashp_seer_cz5(program_version), frac_load_heat: 1.0, frac_load_cool: 1.0, backup_fuel: HPXML::FuelTypeElectricity, backup_eff: 1.0, shr: 0.73, **hvac_iq_values }])
      _check_thermostat(hpxml, control_type: HPXML::HVACControlTypeProgrammable)
      if [ESConstants.SFNationalVer3_0, ESConstants.SFPacificVer3_0, ESConstants.SFOregonWashingtonVer3_2].include? program_version
        _check_ducts(hpxml, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 0.0, duct_area: 729.0, duct_location: HPXML::LocationBasementConditioned },
                             { duct_type: HPXML::DuctTypeReturn, duct_rvalue: 0.0, duct_area: 135.0, duct_location: HPXML::LocationBasementConditioned }])
      elsif [ESConstants.SFNationalVer3_1, ESConstants.SFNationalVer3_2, ESConstants.SFFloridaVer3_1,
             ESConstants.MFNationalVer1_1, ESConstants.MFNationalVer1_2,
             ZERHConstants.Ver1].include? program_version
        _check_ducts(hpxml, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 0.0, duct_area: 729.0, duct_location: HPXML::LocationLivingSpace },
                             { duct_type: HPXML::DuctTypeReturn, duct_rvalue: 0.0, duct_area: 135.0, duct_location: HPXML::LocationLivingSpace }])
      else
        return_r = (program_version != ESConstants.MFOregonWashingtonVer1_2 ? 6.0 : 8.0)
        _check_ducts(hpxml, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 8.0, duct_area: 729.0, duct_location: HPXML::LocationAtticVented },
                             { duct_type: HPXML::DuctTypeReturn, duct_rvalue: return_r, duct_area: 135.0, duct_location: HPXML::LocationAtticVented }])
      end
      _check_duct_leakage(hpxml, [{ duct_type: HPXML::DuctTypeSupply, duct_leakage_units: HPXML::UnitsCFM25, duct_leakage_value: get_es_zerh_duct_leakage(program_version, 54.0), duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside },
                                  { duct_type: HPXML::DuctTypeReturn, duct_leakage_units: HPXML::UnitsCFM25, duct_leakage_value: get_es_zerh_duct_leakage(program_version, 54.0), duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside }])
    end
  end

  def test_ground_source_heat_pump
    [*ESConstants.AllVersions, *ZERHConstants.AllVersions].each do |program_version|
      _convert_to_es_zerh('base-hvac-ground-to-air-heat-pump.xml', program_version)
      hpxml = _test_ruleset(program_version)
      hvac_iq_values = get_default_hvac_iq_values(program_version)
      _check_heating_system(hpxml)
      _check_cooling_system(hpxml)
      if ESConstants.MFVersions.include? program_version
        _check_heat_pump(hpxml, [{ systype: HPXML::HVACTypeHeatPumpGroundToAir, fuel: HPXML::FuelTypeElectricity, cop: get_es_zerh_gshp_cop_cz5(program_version), eer: get_es_zerh_gshp_eer_cz5(program_version), frac_load_heat: 1.0, frac_load_cool: 1.0, shr: 0.73, pump_w_per_ton: 30, **hvac_iq_values }])
      else
        _check_heat_pump(hpxml, [{ systype: HPXML::HVACTypeHeatPumpAirToAir, fuel: HPXML::FuelTypeElectricity, hspf: get_es_zerh_ashp_hspf_cz5(program_version), seer: get_es_zerh_ashp_seer_cz5(program_version), frac_load_heat: 1.0, frac_load_cool: 1.0, backup_fuel: HPXML::FuelTypeElectricity, backup_eff: 1.0, shr: 0.73, **hvac_iq_values }])
      end
      _check_thermostat(hpxml, control_type: HPXML::HVACControlTypeProgrammable)
      if [ESConstants.SFNationalVer3_0, ESConstants.SFPacificVer3_0, ESConstants.SFOregonWashingtonVer3_2].include? program_version
        _check_ducts(hpxml, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 0.0, duct_area: 729.0, duct_location: HPXML::LocationBasementConditioned },
                             { duct_type: HPXML::DuctTypeReturn, duct_rvalue: 0.0, duct_area: 270.0, duct_location: HPXML::LocationBasementConditioned }])
      elsif [ESConstants.SFNationalVer3_1, ESConstants.SFNationalVer3_2, ESConstants.SFFloridaVer3_1,
             ESConstants.MFNationalVer1_1, ESConstants.MFNationalVer1_2,
             ZERHConstants.Ver1].include? program_version
        _check_ducts(hpxml, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 0.0, duct_area: 729.0, duct_location: HPXML::LocationLivingSpace },
                             { duct_type: HPXML::DuctTypeReturn, duct_rvalue: 0.0, duct_area: 270.0, duct_location: HPXML::LocationLivingSpace }])
      else
        return_r = (program_version != ESConstants.MFOregonWashingtonVer1_2 ? 6.0 : 8.0)
        _check_ducts(hpxml, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 8.0, duct_area: 729.0, duct_location: HPXML::LocationAtticVented },
                             { duct_type: HPXML::DuctTypeReturn, duct_rvalue: return_r, duct_area: 270.0, duct_location: HPXML::LocationAtticVented }])
      end
      _check_duct_leakage(hpxml, [{ duct_type: HPXML::DuctTypeSupply, duct_leakage_units: HPXML::UnitsCFM25, duct_leakage_value: get_es_zerh_duct_leakage(program_version, 54.0), duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside },
                                  { duct_type: HPXML::DuctTypeReturn, duct_leakage_units: HPXML::UnitsCFM25, duct_leakage_value: get_es_zerh_duct_leakage(program_version, 54.0), duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside }])

      next unless ESConstants.NationalVersions.include?(program_version)

      # Test in climate zone 7
      _convert_to_es_zerh('base-hvac-ground-to-air-heat-pump.xml', program_version)
      hpxml = HPXML.new(hpxml_path: @tmp_hpxml_path)
      hpxml.climate_and_risk_zones.climate_zone_ieccs.each do |climate_zone_iecc|
        climate_zone_iecc.zone = '7'
      end
      hpxml.climate_and_risk_zones.weather_station_name = 'Duluth, MN'
      hpxml.climate_and_risk_zones.weather_station_wmo = 727450
      XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
      hpxml = _test_ruleset(program_version)
      hvac_iq_values = get_default_hvac_iq_values(program_version)
      _check_heating_system(hpxml)
      _check_cooling_system(hpxml)
      if ESConstants.MFVersions.include?(program_version) || [ESConstants.SFNationalVer3_0, ZERHConstants.Ver1].include?(program_version)
        _check_heat_pump(hpxml, [{ systype: HPXML::HVACTypeHeatPumpGroundToAir, fuel: HPXML::FuelTypeElectricity, cop: get_es_zerh_gshp_cop_cz7(program_version), eer: get_es_zerh_gshp_eer_cz7(program_version), frac_load_heat: 1.0, frac_load_cool: 1.0, shr: 0.73, pump_w_per_ton: 30, **hvac_iq_values }])
      else
        _check_heat_pump(hpxml, [{ systype: HPXML::HVACTypeHeatPumpAirToAir, fuel: HPXML::FuelTypeElectricity, hspf: get_es_zerh_ashp_hspf_cz7(program_version), seer: get_es_zerh_ashp_seer_cz7(program_version), frac_load_heat: 1.0, frac_load_cool: 1.0, backup_fuel: HPXML::FuelTypeElectricity, backup_eff: 1.0, shr: 0.73, **hvac_iq_values }])
      end
      _check_thermostat(hpxml, control_type: HPXML::HVACControlTypeProgrammable)
      if [ESConstants.SFNationalVer3_0, ESConstants.SFPacificVer3_0, ESConstants.SFOregonWashingtonVer3_2].include? program_version
        _check_ducts(hpxml, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 0.0, duct_area: 729.0, duct_location: HPXML::LocationBasementConditioned },
                             { duct_type: HPXML::DuctTypeReturn, duct_rvalue: 0.0, duct_area: 270.0, duct_location: HPXML::LocationBasementConditioned }])
      elsif [ESConstants.SFNationalVer3_1, ESConstants.SFNationalVer3_2, ESConstants.SFFloridaVer3_1,
             ESConstants.MFNationalVer1_1, ESConstants.MFNationalVer1_2,
             ZERHConstants.Ver1].include? program_version
        _check_ducts(hpxml, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 0.0, duct_area: 729.0, duct_location: HPXML::LocationLivingSpace },
                             { duct_type: HPXML::DuctTypeReturn, duct_rvalue: 0.0, duct_area: 270.0, duct_location: HPXML::LocationLivingSpace }])
      else
        return_r = (program_version != ESConstants.MFOregonWashingtonVer1_2 ? 6.0 : 8.0)
        _check_ducts(hpxml, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 8.0, duct_area: 729.0, duct_location: HPXML::LocationAtticVented },
                             { duct_type: HPXML::DuctTypeReturn, duct_rvalue: return_r, duct_area: 270.0, duct_location: HPXML::LocationAtticVented }])
      end
      _check_duct_leakage(hpxml, [{ duct_type: HPXML::DuctTypeSupply, duct_leakage_units: HPXML::UnitsCFM25, duct_leakage_value: get_es_zerh_duct_leakage(program_version, 54.0), duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside },
                                  { duct_type: HPXML::DuctTypeReturn, duct_leakage_units: HPXML::UnitsCFM25, duct_leakage_value: get_es_zerh_duct_leakage(program_version, 54.0), duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside }])
    end
  end

  def test_dual_fuel_heat_pump_gas
    [*ESConstants.AllVersions, *ZERHConstants.AllVersions].each do |program_version|
      _convert_to_es_zerh('base-hvac-dual-fuel-air-to-air-heat-pump-1-speed.xml', program_version)
      hpxml = _test_ruleset(program_version)
      hvac_iq_values = get_default_hvac_iq_values(program_version)
      _check_heating_system(hpxml)
      _check_cooling_system(hpxml)
      _check_heat_pump(hpxml, [{ systype: HPXML::HVACTypeHeatPumpAirToAir, fuel: HPXML::FuelTypeElectricity, hspf: get_es_zerh_ashp_hspf_cz5(program_version), seer: get_es_zerh_ashp_seer_cz5(program_version), frac_load_heat: 1.0, frac_load_cool: 1.0, backup_fuel: HPXML::FuelTypeElectricity, backup_eff: 1.0, shr: 0.73, **hvac_iq_values }])
      _check_thermostat(hpxml, control_type: HPXML::HVACControlTypeProgrammable)
      if [ESConstants.SFNationalVer3_0, ESConstants.SFPacificVer3_0, ESConstants.SFOregonWashingtonVer3_2].include? program_version
        _check_ducts(hpxml, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 0.0, duct_area: 729.0, duct_location: HPXML::LocationBasementConditioned },
                             { duct_type: HPXML::DuctTypeReturn, duct_rvalue: 0.0, duct_area: 270.0, duct_location: HPXML::LocationBasementConditioned }])
      elsif [ESConstants.SFNationalVer3_1, ESConstants.SFNationalVer3_2, ESConstants.SFFloridaVer3_1,
             ESConstants.MFNationalVer1_1, ESConstants.MFNationalVer1_2,
             ZERHConstants.Ver1].include? program_version
        _check_ducts(hpxml, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 0.0, duct_area: 729.0, duct_location: HPXML::LocationLivingSpace },
                             { duct_type: HPXML::DuctTypeReturn, duct_rvalue: 0.0, duct_area: 270.0, duct_location: HPXML::LocationLivingSpace }])
      else
        return_r = (program_version != ESConstants.MFOregonWashingtonVer1_2 ? 6.0 : 8.0)
        _check_ducts(hpxml, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 8.0, duct_area: 729.0, duct_location: HPXML::LocationAtticVented },
                             { duct_type: HPXML::DuctTypeReturn, duct_rvalue: return_r, duct_area: 270.0, duct_location: HPXML::LocationAtticVented }])
      end
      _check_duct_leakage(hpxml, [{ duct_type: HPXML::DuctTypeSupply, duct_leakage_units: HPXML::UnitsCFM25, duct_leakage_value: get_es_zerh_duct_leakage(program_version, 54.0), duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside },
                                  { duct_type: HPXML::DuctTypeReturn, duct_leakage_units: HPXML::UnitsCFM25, duct_leakage_value: get_es_zerh_duct_leakage(program_version, 54.0), duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside }])
    end
  end

  def test_dual_fuel_heat_pump_elec
    [*ESConstants.AllVersions, *ZERHConstants.AllVersions].each do |program_version|
      _convert_to_es_zerh('base-hvac-dual-fuel-air-to-air-heat-pump-1-speed-electric.xml', program_version)
      hpxml = _test_ruleset(program_version)
      hvac_iq_values = get_default_hvac_iq_values(program_version)
      _check_heating_system(hpxml)
      _check_cooling_system(hpxml)
      _check_heat_pump(hpxml, [{ systype: HPXML::HVACTypeHeatPumpAirToAir, fuel: HPXML::FuelTypeElectricity, hspf: get_es_zerh_ashp_hspf_cz5(program_version), seer: get_es_zerh_ashp_seer_cz5(program_version), frac_load_heat: 1.0, frac_load_cool: 1.0, backup_fuel: HPXML::FuelTypeElectricity, backup_eff: 1.0, shr: 0.73, **hvac_iq_values }])
      _check_thermostat(hpxml, control_type: HPXML::HVACControlTypeProgrammable)
      if [ESConstants.SFNationalVer3_0, ESConstants.SFPacificVer3_0, ESConstants.SFOregonWashingtonVer3_2].include? program_version
        _check_ducts(hpxml, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 0.0, duct_area: 729.0, duct_location: HPXML::LocationBasementConditioned },
                             { duct_type: HPXML::DuctTypeReturn, duct_rvalue: 0.0, duct_area: 270.0, duct_location: HPXML::LocationBasementConditioned }])
      elsif [ESConstants.SFNationalVer3_1, ESConstants.SFNationalVer3_2, ESConstants.SFFloridaVer3_1,
             ESConstants.MFNationalVer1_1, ESConstants.MFNationalVer1_2,
             ZERHConstants.Ver1].include? program_version
        _check_ducts(hpxml, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 0.0, duct_area: 729.0, duct_location: HPXML::LocationLivingSpace },
                             { duct_type: HPXML::DuctTypeReturn, duct_rvalue: 0.0, duct_area: 270.0, duct_location: HPXML::LocationLivingSpace }])
      else
        return_r = (program_version != ESConstants.MFOregonWashingtonVer1_2 ? 6.0 : 8.0)
        _check_ducts(hpxml, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 8.0, duct_area: 729.0, duct_location: HPXML::LocationAtticVented },
                             { duct_type: HPXML::DuctTypeReturn, duct_rvalue: return_r, duct_area: 270.0, duct_location: HPXML::LocationAtticVented }])
      end
      _check_duct_leakage(hpxml, [{ duct_type: HPXML::DuctTypeSupply, duct_leakage_units: HPXML::UnitsCFM25, duct_leakage_value: get_es_zerh_duct_leakage(program_version, 54.0), duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside },
                                  { duct_type: HPXML::DuctTypeReturn, duct_leakage_units: HPXML::UnitsCFM25, duct_leakage_value: get_es_zerh_duct_leakage(program_version, 54.0), duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside }])
    end
  end

  def test_central_air_conditioner
    ['base-hvac-central-ac-only-1-speed.xml', 'base-hvac-central-ac-only-1-speed-seer2.xml'].each do |hpxml_name|
      [*ESConstants.AllVersions, *ZERHConstants.AllVersions].each do |program_version|
        _convert_to_es_zerh(hpxml_name, program_version)
        hpxml = _test_ruleset(program_version)
        hvac_iq_values = get_default_hvac_iq_values(program_version)
        _check_heating_system(hpxml)
        _check_cooling_system(hpxml, [{ systype: HPXML::HVACTypeCentralAirConditioner, fuel: HPXML::FuelTypeElectricity, seer: get_es_zerh_central_ac_seer_cz5(program_version), frac_load: 1.0, shr: 0.73, **hvac_iq_values }])
        _check_heat_pump(hpxml)
        _check_thermostat(hpxml, control_type: HPXML::HVACControlTypeProgrammable)
        if [ESConstants.SFNationalVer3_0, ESConstants.SFPacificVer3_0, ESConstants.SFOregonWashingtonVer3_2].include? program_version
          _check_ducts(hpxml, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 0.0, duct_area: 729.0, duct_location: HPXML::LocationBasementConditioned },
                               { duct_type: HPXML::DuctTypeReturn, duct_rvalue: 0.0, duct_area: 270.0, duct_location: HPXML::LocationBasementConditioned }])
        elsif [ESConstants.SFNationalVer3_1, ESConstants.SFNationalVer3_2, ESConstants.SFFloridaVer3_1,
               ESConstants.MFNationalVer1_1, ESConstants.MFNationalVer1_2,
               ZERHConstants.Ver1].include? program_version
          _check_ducts(hpxml, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 0.0, duct_area: 729.0, duct_location: HPXML::LocationLivingSpace },
                               { duct_type: HPXML::DuctTypeReturn, duct_rvalue: 0.0, duct_area: 270.0, duct_location: HPXML::LocationLivingSpace }])
        else
          return_r = (program_version != ESConstants.MFOregonWashingtonVer1_2 ? 6.0 : 8.0)
          _check_ducts(hpxml, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 8.0, duct_area: 729.0, duct_location: HPXML::LocationAtticVented },
                               { duct_type: HPXML::DuctTypeReturn, duct_rvalue: return_r, duct_area: 270.0, duct_location: HPXML::LocationAtticVented }])
        end
        _check_duct_leakage(hpxml, [{ duct_type: HPXML::DuctTypeSupply, duct_leakage_units: HPXML::UnitsCFM25, duct_leakage_value: get_es_zerh_duct_leakage(program_version, 54.0), duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside },
                                    { duct_type: HPXML::DuctTypeReturn, duct_leakage_units: HPXML::UnitsCFM25, duct_leakage_value: get_es_zerh_duct_leakage(program_version, 54.0), duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside }])
      end
    end
  end

  def test_room_air_conditioner_and_ptac
    hpxml_names = ['base-hvac-room-ac-only.xml',
                   'base-hvac-room-ac-only-ceer.xml',
                   'base-hvac-ptac.xml']

    hpxml_names.each do |hpxml_name|
      [*ESConstants.AllVersions, *ZERHConstants.AllVersions].each do |program_version|
        _convert_to_es_zerh(hpxml_name, program_version)
        hpxml = _test_ruleset(program_version)
        hvac_iq_values = get_default_hvac_iq_values(program_version)
        _check_heating_system(hpxml)
        _check_cooling_system(hpxml, [{ systype: HPXML::HVACTypeCentralAirConditioner, fuel: HPXML::FuelTypeElectricity, seer: get_es_zerh_central_ac_seer_cz5(program_version), frac_load: 1.0, shr: 0.65, **hvac_iq_values }])
        _check_heat_pump(hpxml)
        _check_thermostat(hpxml, control_type: HPXML::HVACControlTypeProgrammable)
        if [ESConstants.SFNationalVer3_0, ESConstants.SFPacificVer3_0, ESConstants.SFOregonWashingtonVer3_2].include? program_version
          _check_ducts(hpxml, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 0.0, duct_area: 729.0, duct_location: HPXML::LocationBasementConditioned },
                               { duct_type: HPXML::DuctTypeReturn, duct_rvalue: 0.0, duct_area: 135.0, duct_location: HPXML::LocationBasementConditioned }])
        elsif [ESConstants.SFNationalVer3_1, ESConstants.SFNationalVer3_2, ESConstants.SFFloridaVer3_1,
               ESConstants.MFNationalVer1_1, ESConstants.MFNationalVer1_2,
               ZERHConstants.Ver1].include? program_version
          _check_ducts(hpxml, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 0.0, duct_area: 729.0, duct_location: HPXML::LocationLivingSpace },
                               { duct_type: HPXML::DuctTypeReturn, duct_rvalue: 0.0, duct_area: 135.0, duct_location: HPXML::LocationLivingSpace }])
        else
          return_r = (program_version != ESConstants.MFOregonWashingtonVer1_2 ? 6.0 : 8.0)
          _check_ducts(hpxml, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 8.0, duct_area: 729.0, duct_location: HPXML::LocationAtticVented },
                               { duct_type: HPXML::DuctTypeReturn, duct_rvalue: return_r, duct_area: 135.0, duct_location: HPXML::LocationAtticVented }])
        end
        _check_duct_leakage(hpxml, [{ duct_type: HPXML::DuctTypeSupply, duct_leakage_units: HPXML::UnitsCFM25, duct_leakage_value: get_es_zerh_duct_leakage(program_version, 54.0), duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside },
                                    { duct_type: HPXML::DuctTypeReturn, duct_leakage_units: HPXML::UnitsCFM25, duct_leakage_value: get_es_zerh_duct_leakage(program_version, 54.0), duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside }])
      end
    end
  end

  def test_room_air_conditioner_and_ptac_with_heating
    hpxml_names = ['base-hvac-room-ac-with-heating.xml',
                   'base-hvac-ptac-with-heating-electricity.xml']

    hpxml_names.each do |hpxml_name|
      [*ESConstants.AllVersions, *ZERHConstants.AllVersions].each do |program_version|
        _convert_to_es_zerh(hpxml_name, program_version)
        hpxml = _test_ruleset(program_version)
        hvac_iq_values = get_default_hvac_iq_values(program_version)
        _check_heating_system(hpxml)
        _check_cooling_system(hpxml)
        _check_heat_pump(hpxml, [{ systype: HPXML::HVACTypeHeatPumpAirToAir, fuel: HPXML::FuelTypeElectricity, hspf: get_es_zerh_ashp_hspf_cz5(program_version), seer: get_es_zerh_ashp_seer_cz5(program_version), frac_load_heat: 1.0, frac_load_cool: 1.0, shr: 0.65, backup_fuel: HPXML::FuelTypeElectricity, backup_eff: 1.0, **hvac_iq_values }])
        _check_thermostat(hpxml, control_type: HPXML::HVACControlTypeProgrammable)
        if [ESConstants.SFNationalVer3_0, ESConstants.SFPacificVer3_0, ESConstants.SFOregonWashingtonVer3_2].include? program_version
          _check_ducts(hpxml, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 0.0, duct_area: 729.0, duct_location: HPXML::LocationBasementConditioned },
                               { duct_type: HPXML::DuctTypeReturn, duct_rvalue: 0.0, duct_area: 135.0, duct_location: HPXML::LocationBasementConditioned }])
        elsif [ESConstants.SFNationalVer3_1, ESConstants.SFNationalVer3_2, ESConstants.SFFloridaVer3_1,
               ESConstants.MFNationalVer1_1, ESConstants.MFNationalVer1_2,
               ZERHConstants.Ver1].include? program_version
          _check_ducts(hpxml, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 0.0, duct_area: 729.0, duct_location: HPXML::LocationLivingSpace },
                               { duct_type: HPXML::DuctTypeReturn, duct_rvalue: 0.0, duct_area: 135.0, duct_location: HPXML::LocationLivingSpace }])
        else
          return_r = (program_version != ESConstants.MFOregonWashingtonVer1_2 ? 6.0 : 8.0)
          _check_ducts(hpxml, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 8.0, duct_area: 729.0, duct_location: HPXML::LocationAtticVented },
                               { duct_type: HPXML::DuctTypeReturn, duct_rvalue: return_r, duct_area: 135.0, duct_location: HPXML::LocationAtticVented }])
        end
        _check_duct_leakage(hpxml, [{ duct_type: HPXML::DuctTypeSupply, duct_leakage_units: HPXML::UnitsCFM25, duct_leakage_value: get_es_zerh_duct_leakage(program_version, 54.0), duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside },
                                    { duct_type: HPXML::DuctTypeReturn, duct_leakage_units: HPXML::UnitsCFM25, duct_leakage_value: get_es_zerh_duct_leakage(program_version, 54.0), duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside }])
      end
    end
  end

  def test_room_air_conditioner_and_ptac_with_heating_gas
    hpxml_name = 'base-hvac-ptac-with-heating-natural-gas.xml'

    [*ESConstants.AllVersions, *ZERHConstants.AllVersions].each do |program_version|
      _convert_to_es_zerh(hpxml_name, program_version)
      hpxml = _test_ruleset(program_version)
      hvac_iq_values = get_default_hvac_iq_values(program_version)
      _check_heating_system(hpxml, [{ systype: HPXML::HVACTypeFurnace, fuel: HPXML::FuelTypeNaturalGas, eff: get_es_zerh_gas_furnace_afue_cz5(program_version), frac_load: 1.0, **hvac_iq_values }])
      _check_cooling_system(hpxml, [{ systype: HPXML::HVACTypeCentralAirConditioner, fuel: HPXML::FuelTypeElectricity, seer: get_es_zerh_central_ac_seer_cz5(program_version), frac_load: 1.0, shr: 0.65, **hvac_iq_values }])
      _check_heat_pump(hpxml)
      _check_thermostat(hpxml, control_type: HPXML::HVACControlTypeProgrammable)
      if [ESConstants.SFNationalVer3_0, ESConstants.SFPacificVer3_0, ESConstants.SFOregonWashingtonVer3_2].include? program_version
        _check_ducts(hpxml, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 0.0, duct_area: 729.0, duct_location: HPXML::LocationBasementConditioned },
                             { duct_type: HPXML::DuctTypeReturn, duct_rvalue: 0.0, duct_area: 135.0, duct_location: HPXML::LocationBasementConditioned }] * 2)
      elsif [ESConstants.SFNationalVer3_1, ESConstants.SFNationalVer3_2, ESConstants.SFFloridaVer3_1,
             ESConstants.MFNationalVer1_1, ESConstants.MFNationalVer1_2,
             ZERHConstants.Ver1, ZERHConstants.SFVer2].include? program_version
        _check_ducts(hpxml, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 0.0, duct_area: 729.0, duct_location: HPXML::LocationLivingSpace },
                             { duct_type: HPXML::DuctTypeReturn, duct_rvalue: 0.0, duct_area: 135.0, duct_location: HPXML::LocationLivingSpace }] * 2)
      else
        return_r = (program_version != ESConstants.MFOregonWashingtonVer1_2 ? 6.0 : 8.0)
        _check_ducts(hpxml, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 8.0, duct_area: 729.0, duct_location: HPXML::LocationAtticVented },
                             { duct_type: HPXML::DuctTypeReturn, duct_rvalue: return_r, duct_area: 135.0, duct_location: HPXML::LocationAtticVented }] * 2)
      end
      _check_duct_leakage(hpxml, [{ duct_type: HPXML::DuctTypeSupply, duct_leakage_units: HPXML::UnitsCFM25, duct_leakage_value: get_es_zerh_duct_leakage(program_version, 54.0), duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside },
                                  { duct_type: HPXML::DuctTypeReturn, duct_leakage_units: HPXML::UnitsCFM25, duct_leakage_value: get_es_zerh_duct_leakage(program_version, 54.0), duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside }] * 2)
    end
  end

  def test_room_air_conditioner_with_reverse_cycle_and_pthp
    hpxml_names = ['base-hvac-room-ac-with-reverse-cycle.xml',
                   'base-hvac-pthp.xml']

    hpxml_names.each do |hpxml_name|
      [*ESConstants.AllVersions, *ZERHConstants.AllVersions].each do |program_version|
        _convert_to_es_zerh(hpxml_name, program_version)
        hpxml = _test_ruleset(program_version)
        hvac_iq_values = get_default_hvac_iq_values(program_version)
        _check_heating_system(hpxml)
        _check_cooling_system(hpxml)
        _check_heat_pump(hpxml, [{ systype: HPXML::HVACTypeHeatPumpAirToAir, fuel: HPXML::FuelTypeElectricity, hspf: get_es_zerh_ashp_hspf_cz5(program_version), seer: get_es_zerh_ashp_seer_cz5(program_version), frac_load_heat: 1.0, frac_load_cool: 1.0, backup_fuel: HPXML::FuelTypeElectricity, backup_eff: 1.0, shr: 0.65, **hvac_iq_values }])
        _check_thermostat(hpxml, control_type: HPXML::HVACControlTypeProgrammable)
        if [ESConstants.SFNationalVer3_0, ESConstants.SFPacificVer3_0, ESConstants.SFOregonWashingtonVer3_2].include? program_version
          _check_ducts(hpxml, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 0.0, duct_area: 729.0, duct_location: HPXML::LocationBasementConditioned },
                               { duct_type: HPXML::DuctTypeReturn, duct_rvalue: 0.0, duct_area: 135.0, duct_location: HPXML::LocationBasementConditioned }])
        elsif [ESConstants.SFNationalVer3_1, ESConstants.SFNationalVer3_2, ESConstants.SFFloridaVer3_1,
               ESConstants.MFNationalVer1_1, ESConstants.MFNationalVer1_2,
               ZERHConstants.Ver1, ZERHConstants.SFVer2].include? program_version
          _check_ducts(hpxml, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 0.0, duct_area: 729.0, duct_location: HPXML::LocationLivingSpace },
                               { duct_type: HPXML::DuctTypeReturn, duct_rvalue: 0.0, duct_area: 135.0, duct_location: HPXML::LocationLivingSpace }])
        else
          return_r = (program_version != ESConstants.MFOregonWashingtonVer1_2 ? 6.0 : 8.0)
          _check_ducts(hpxml, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 8.0, duct_area: 729.0, duct_location: HPXML::LocationAtticVented },
                               { duct_type: HPXML::DuctTypeReturn, duct_rvalue: return_r, duct_area: 135.0, duct_location: HPXML::LocationAtticVented }])
        end
        _check_duct_leakage(hpxml, [{ duct_type: HPXML::DuctTypeSupply, duct_leakage_units: HPXML::UnitsCFM25, duct_leakage_value: get_es_zerh_duct_leakage(program_version, 54.0), duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside },
                                    { duct_type: HPXML::DuctTypeReturn, duct_leakage_units: HPXML::UnitsCFM25, duct_leakage_value: get_es_zerh_duct_leakage(program_version, 54.0), duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside }])
      end
    end
  end

  def test_evaporative_cooler
    [*ESConstants.AllVersions, *ZERHConstants.AllVersions].each do |program_version|
      _convert_to_es_zerh('base-hvac-evap-cooler-only.xml', program_version)
      hpxml = _test_ruleset(program_version)
      hvac_iq_values = get_default_hvac_iq_values(program_version)
      _check_heating_system(hpxml)
      _check_cooling_system(hpxml, [{ systype: HPXML::HVACTypeCentralAirConditioner, fuel: HPXML::FuelTypeElectricity, seer: get_es_zerh_central_ac_seer_cz5(program_version), frac_load: 1.0, **hvac_iq_values }])
      _check_heat_pump(hpxml)
      _check_thermostat(hpxml, control_type: HPXML::HVACControlTypeProgrammable)
      if [ESConstants.SFNationalVer3_0, ESConstants.SFPacificVer3_0, ESConstants.SFOregonWashingtonVer3_2].include? program_version
        _check_ducts(hpxml, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 0.0, duct_area: 729.0, duct_location: HPXML::LocationBasementConditioned },
                             { duct_type: HPXML::DuctTypeReturn, duct_rvalue: 0.0, duct_area: 135.0, duct_location: HPXML::LocationBasementConditioned }])
      elsif [ESConstants.SFNationalVer3_1, ESConstants.SFNationalVer3_2, ESConstants.SFFloridaVer3_1,
             ESConstants.MFNationalVer1_1, ESConstants.MFNationalVer1_2,
             ZERHConstants.Ver1, ZERHConstants.SFVer2].include? program_version
        _check_ducts(hpxml, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 0.0, duct_area: 729.0, duct_location: HPXML::LocationLivingSpace },
                             { duct_type: HPXML::DuctTypeReturn, duct_rvalue: 0.0, duct_area: 135.0, duct_location: HPXML::LocationLivingSpace }])
      else
        return_r = (program_version != ESConstants.MFOregonWashingtonVer1_2 ? 6.0 : 8.0)
        _check_ducts(hpxml, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 8.0, duct_area: 729.0, duct_location: HPXML::LocationAtticVented },
                             { duct_type: HPXML::DuctTypeReturn, duct_rvalue: return_r, duct_area: 135.0, duct_location: HPXML::LocationAtticVented }])
      end
      _check_duct_leakage(hpxml, [{ duct_type: HPXML::DuctTypeSupply, duct_leakage_units: HPXML::UnitsCFM25, duct_leakage_value: get_es_zerh_duct_leakage(program_version, 54.0), duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside },
                                  { duct_type: HPXML::DuctTypeReturn, duct_leakage_units: HPXML::UnitsCFM25, duct_leakage_value: get_es_zerh_duct_leakage(program_version, 54.0), duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside }])
    end
  end

  def test_mini_split_air_conditioner_ducted
    [*ESConstants.AllVersions, *ZERHConstants.AllVersions].each do |program_version|
      _convert_to_es_zerh('base-hvac-mini-split-air-conditioner-only-ducted.xml', program_version)
      hpxml = _test_ruleset(program_version)
      hvac_iq_values = get_default_hvac_iq_values(program_version)
      _check_heating_system(hpxml)
      _check_cooling_system(hpxml, [{ systype: HPXML::HVACTypeCentralAirConditioner, fuel: HPXML::FuelTypeElectricity, seer: get_es_zerh_central_ac_seer_cz5(program_version), frac_load: 1.0, shr: 0.73, **hvac_iq_values }])
      _check_heat_pump(hpxml)
      _check_thermostat(hpxml, control_type: HPXML::HVACControlTypeProgrammable)
      if [ESConstants.SFNationalVer3_0, ESConstants.SFPacificVer3_0, ESConstants.SFOregonWashingtonVer3_2].include? program_version
        _check_ducts(hpxml, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 0.0, duct_area: 729.0, duct_location: HPXML::LocationBasementConditioned },
                             { duct_type: HPXML::DuctTypeReturn, duct_rvalue: 0.0, duct_area: 270.0, duct_location: HPXML::LocationBasementConditioned }])
      elsif [ESConstants.SFNationalVer3_1, ESConstants.SFNationalVer3_2, ESConstants.SFFloridaVer3_1,
             ESConstants.MFNationalVer1_1, ESConstants.MFNationalVer1_2,
             ZERHConstants.Ver1, ZERHConstants.SFVer2].include? program_version
        _check_ducts(hpxml, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 0.0, duct_area: 729.0, duct_location: HPXML::LocationLivingSpace },
                             { duct_type: HPXML::DuctTypeReturn, duct_rvalue: 0.0, duct_area: 270.0, duct_location: HPXML::LocationLivingSpace }])
      else
        return_r = (program_version != ESConstants.MFOregonWashingtonVer1_2 ? 6.0 : 8.0)
        _check_ducts(hpxml, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 8.0, duct_area: 729.0, duct_location: HPXML::LocationAtticVented },
                             { duct_type: HPXML::DuctTypeReturn, duct_rvalue: return_r, duct_area: 270.0, duct_location: HPXML::LocationAtticVented }])
      end
      _check_duct_leakage(hpxml, [{ duct_type: HPXML::DuctTypeSupply, duct_leakage_units: HPXML::UnitsCFM25, duct_leakage_value: get_es_zerh_duct_leakage(program_version, 54.0), duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside },
                                  { duct_type: HPXML::DuctTypeReturn, duct_leakage_units: HPXML::UnitsCFM25, duct_leakage_value: get_es_zerh_duct_leakage(program_version, 54.0), duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside }])
    end
  end

  def test_mini_split_air_conditioner_ductless
    [*ESConstants.AllVersions, *ZERHConstants.AllVersions].each do |program_version|
      _convert_to_es_zerh('base-hvac-mini-split-air-conditioner-only-ductless.xml', program_version)
      hpxml = _test_ruleset(program_version)
      hvac_iq_values = get_default_hvac_iq_values(program_version)
      _check_heating_system(hpxml)
      _check_cooling_system(hpxml, [{ systype: HPXML::HVACTypeCentralAirConditioner, fuel: HPXML::FuelTypeElectricity, seer: get_es_zerh_central_ac_seer_cz5(program_version), frac_load: 1.0, shr: 0.73, **hvac_iq_values }])
      _check_heat_pump(hpxml)
      _check_thermostat(hpxml, control_type: HPXML::HVACControlTypeProgrammable)
      if [ESConstants.SFNationalVer3_0, ESConstants.SFPacificVer3_0, ESConstants.SFOregonWashingtonVer3_2].include? program_version
        _check_ducts(hpxml, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 0.0, duct_area: 729.0, duct_location: HPXML::LocationBasementConditioned },
                             { duct_type: HPXML::DuctTypeReturn, duct_rvalue: 0.0, duct_area: 135.0, duct_location: HPXML::LocationBasementConditioned }])
      elsif [ESConstants.SFNationalVer3_1, ESConstants.SFNationalVer3_2, ESConstants.SFFloridaVer3_1,
             ESConstants.MFNationalVer1_1, ESConstants.MFNationalVer1_2,
             ZERHConstants.Ver1, ZERHConstants.SFVer2].include? program_version
        _check_ducts(hpxml, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 0.0, duct_area: 729.0, duct_location: HPXML::LocationLivingSpace },
                             { duct_type: HPXML::DuctTypeReturn, duct_rvalue: 0.0, duct_area: 135.0, duct_location: HPXML::LocationLivingSpace }])
      else
        return_r = (program_version != ESConstants.MFOregonWashingtonVer1_2 ? 6.0 : 8.0)
        _check_ducts(hpxml, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 8.0, duct_area: 729.0, duct_location: HPXML::LocationAtticVented },
                             { duct_type: HPXML::DuctTypeReturn, duct_rvalue: return_r, duct_area: 135.0, duct_location: HPXML::LocationAtticVented }])
      end
      _check_duct_leakage(hpxml, [{ duct_type: HPXML::DuctTypeSupply, duct_leakage_units: HPXML::UnitsCFM25, duct_leakage_value: get_es_zerh_duct_leakage(program_version, 54.0), duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside },
                                  { duct_type: HPXML::DuctTypeReturn, duct_leakage_units: HPXML::UnitsCFM25, duct_leakage_value: get_es_zerh_duct_leakage(program_version, 54.0), duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside }])
    end
  end

  def test_furnace_gas_and_central_air_conditioner
    [*ESConstants.AllVersions, *ZERHConstants.AllVersions].each do |program_version|
      _convert_to_es_zerh('base.xml', program_version)
      hpxml = _test_ruleset(program_version)
      hvac_iq_values = get_default_hvac_iq_values(program_version)
      _check_heating_system(hpxml, [{ systype: HPXML::HVACTypeFurnace, fuel: HPXML::FuelTypeNaturalGas, eff: get_es_zerh_gas_furnace_afue_cz5(program_version), frac_load: 1.0, **hvac_iq_values }])
      _check_cooling_system(hpxml, [{ systype: HPXML::HVACTypeCentralAirConditioner, fuel: HPXML::FuelTypeElectricity, seer: get_es_zerh_central_ac_seer_cz5(program_version), frac_load: 1.0, shr: 0.73, **hvac_iq_values }])
      _check_heat_pump(hpxml)
      _check_thermostat(hpxml, control_type: HPXML::HVACControlTypeProgrammable)
      if [ESConstants.SFNationalVer3_0, ESConstants.SFPacificVer3_0, ESConstants.SFOregonWashingtonVer3_2].include? program_version
        _check_ducts(hpxml, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 0.0, duct_area: 729.0, duct_location: HPXML::LocationBasementConditioned },
                             { duct_type: HPXML::DuctTypeReturn, duct_rvalue: 0.0, duct_area: 270.0, duct_location: HPXML::LocationBasementConditioned }])
      elsif [ESConstants.SFNationalVer3_1, ESConstants.SFNationalVer3_2, ESConstants.SFFloridaVer3_1,
             ESConstants.MFNationalVer1_1, ESConstants.MFNationalVer1_2,
             ZERHConstants.Ver1, ZERHConstants.SFVer2].include? program_version
        _check_ducts(hpxml, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 0.0, duct_area: 729.0, duct_location: HPXML::LocationLivingSpace },
                             { duct_type: HPXML::DuctTypeReturn, duct_rvalue: 0.0, duct_area: 270.0, duct_location: HPXML::LocationLivingSpace }])
      else
        return_r = (program_version != ESConstants.MFOregonWashingtonVer1_2 ? 6.0 : 8.0)
        _check_ducts(hpxml, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 8.0, duct_area: 729.0, duct_location: HPXML::LocationAtticVented },
                             { duct_type: HPXML::DuctTypeReturn, duct_rvalue: return_r, duct_area: 270.0, duct_location: HPXML::LocationAtticVented }])
      end
      _check_duct_leakage(hpxml, [{ duct_type: HPXML::DuctTypeSupply, duct_leakage_units: HPXML::UnitsCFM25, duct_leakage_value: get_es_zerh_duct_leakage(program_version, 54.0), duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside },
                                  { duct_type: HPXML::DuctTypeReturn, duct_leakage_units: HPXML::UnitsCFM25, duct_leakage_value: get_es_zerh_duct_leakage(program_version, 54.0), duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside }])

      _convert_to_es_zerh('base-foundation-multiple.xml', program_version)
      hpxml = _test_ruleset(program_version)
      hvac_iq_values = get_default_hvac_iq_values(program_version)
      _check_heating_system(hpxml, [{ systype: HPXML::HVACTypeFurnace, fuel: HPXML::FuelTypeNaturalGas, eff: get_es_zerh_gas_furnace_afue_cz5(program_version), frac_load: 1.0, **hvac_iq_values }])
      _check_cooling_system(hpxml, [{ systype: HPXML::HVACTypeCentralAirConditioner, fuel: HPXML::FuelTypeElectricity, seer: get_es_zerh_central_ac_seer_cz5(program_version), frac_load: 1.0, shr: 0.73, **hvac_iq_values }])
      _check_heat_pump(hpxml)
      _check_thermostat(hpxml, control_type: HPXML::HVACControlTypeProgrammable)
      if [ESConstants.SFNationalVer3_0, ESConstants.SFPacificVer3_0, ESConstants.SFOregonWashingtonVer3_2].include? program_version
        duct_r = (program_version != ESConstants.SFOregonWashingtonVer3_2 ? 6.0 : 8.0)
        _check_ducts(hpxml, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: duct_r, duct_area: 364.5, duct_location: HPXML::LocationBasementUnconditioned },
                             { duct_type: HPXML::DuctTypeReturn, duct_rvalue: duct_r, duct_area: 67.5, duct_location: HPXML::LocationBasementUnconditioned }])
      elsif [ESConstants.SFNationalVer3_1, ESConstants.SFNationalVer3_2, ESConstants.SFFloridaVer3_1,
             ESConstants.MFNationalVer1_1, ESConstants.MFNationalVer1_2,
             ZERHConstants.Ver1, ZERHConstants.SFVer2].include? program_version
        _check_ducts(hpxml, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 0.0, duct_area: 364.5, duct_location: HPXML::LocationLivingSpace },
                             { duct_type: HPXML::DuctTypeReturn, duct_rvalue: 0.0, duct_area: 67.5, duct_location: HPXML::LocationLivingSpace }])
      else
        return_r = (program_version != ESConstants.MFOregonWashingtonVer1_2 ? 6.0 : 8.0)
        _check_ducts(hpxml, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 8.0, duct_area: 364.5, duct_location: HPXML::LocationAtticVented },
                             { duct_type: HPXML::DuctTypeReturn, duct_rvalue: return_r, duct_area: 67.5, duct_location: HPXML::LocationAtticVented }])
      end
      _check_duct_leakage(hpxml, [{ duct_type: HPXML::DuctTypeSupply, duct_leakage_units: HPXML::UnitsCFM25, duct_leakage_value: get_es_zerh_duct_leakage(program_version, 27.0), duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside },
                                  { duct_type: HPXML::DuctTypeReturn, duct_leakage_units: HPXML::UnitsCFM25, duct_leakage_value: get_es_zerh_duct_leakage(program_version, 27.0), duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside }])

      _convert_to_es_zerh('base-foundation-ambient.xml', program_version)
      hpxml = _test_ruleset(program_version)
      hvac_iq_values = get_default_hvac_iq_values(program_version)
      _check_heating_system(hpxml, [{ systype: HPXML::HVACTypeFurnace, fuel: HPXML::FuelTypeNaturalGas, eff: get_es_zerh_gas_furnace_afue_cz5(program_version), frac_load: 1.0, **hvac_iq_values }])
      _check_cooling_system(hpxml, [{ systype: HPXML::HVACTypeCentralAirConditioner, fuel: HPXML::FuelTypeElectricity, seer: get_es_zerh_central_ac_seer_cz5(program_version), frac_load: 1.0, shr: 0.73, **hvac_iq_values }])
      _check_heat_pump(hpxml)
      _check_thermostat(hpxml, control_type: HPXML::HVACControlTypeProgrammable)
      if [ESConstants.SFNationalVer3_0, ESConstants.SFPacificVer3_0, ESConstants.SFOregonWashingtonVer3_2].include? program_version
        duct_r = (program_version != ESConstants.SFOregonWashingtonVer3_2 ? 6.0 : 8.0)
        _check_ducts(hpxml, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: duct_r, duct_area: 364.5, duct_location: HPXML::LocationOutside },
                             { duct_type: HPXML::DuctTypeReturn, duct_rvalue: duct_r, duct_area: 67.5, duct_location: HPXML::LocationOutside }])
      elsif [ESConstants.SFNationalVer3_1, ESConstants.SFNationalVer3_2, ESConstants.SFFloridaVer3_1,
             ESConstants.MFNationalVer1_1, ESConstants.MFNationalVer1_2,
             ZERHConstants.Ver1, ZERHConstants.SFVer2].include? program_version
        _check_ducts(hpxml, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 0.0, duct_area: 364.5, duct_location: HPXML::LocationLivingSpace },
                             { duct_type: HPXML::DuctTypeReturn, duct_rvalue: 0.0, duct_area: 67.5, duct_location: HPXML::LocationLivingSpace }])
      else
        return_r = (program_version != ESConstants.MFOregonWashingtonVer1_2 ? 6.0 : 8.0)
        _check_ducts(hpxml, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 8.0, duct_area: 364.5, duct_location: HPXML::LocationAtticVented },
                             { duct_type: HPXML::DuctTypeReturn, duct_rvalue: return_r, duct_area: 67.5, duct_location: HPXML::LocationAtticVented }])
      end
      _check_duct_leakage(hpxml, [{ duct_type: HPXML::DuctTypeSupply, duct_leakage_units: HPXML::UnitsCFM25, duct_leakage_value: get_es_zerh_duct_leakage(program_version, 27.0), duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside },
                                  { duct_type: HPXML::DuctTypeReturn, duct_leakage_units: HPXML::UnitsCFM25, duct_leakage_value: get_es_zerh_duct_leakage(program_version, 27.0), duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside }])

      # Test w/ 2 stories
      _convert_to_es_zerh('base-enclosure-2stories.xml', program_version)
      hpxml = _test_ruleset(program_version)
      hvac_iq_values = get_default_hvac_iq_values(program_version)
      _check_heating_system(hpxml, [{ systype: HPXML::HVACTypeFurnace, fuel: HPXML::FuelTypeNaturalGas, eff: get_es_zerh_gas_furnace_afue_cz5(program_version), frac_load: 1.0, **hvac_iq_values }])
      _check_cooling_system(hpxml, [{ systype: HPXML::HVACTypeCentralAirConditioner, fuel: HPXML::FuelTypeElectricity, seer: get_es_zerh_central_ac_seer_cz5(program_version), frac_load: 1.0, shr: 0.73, **hvac_iq_values }])
      _check_heat_pump(hpxml)
      _check_thermostat(hpxml, control_type: HPXML::HVACControlTypeProgrammable)
      if [ESConstants.SFNationalVer3_0, ESConstants.SFPacificVer3_0, ESConstants.SFOregonWashingtonVer3_2].include? program_version
        duct_r = (program_version != ESConstants.SFOregonWashingtonVer3_2 ? 6.0 : 8.0)
        _check_ducts(hpxml, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 0.0, duct_area: 546.75, duct_location: HPXML::LocationBasementConditioned },
                             { duct_type: HPXML::DuctTypeSupply, duct_rvalue: 8.0, duct_area: 546.75, duct_location: HPXML::LocationAtticVented },
                             { duct_type: HPXML::DuctTypeReturn, duct_rvalue: 0.0, duct_area: 303.75, duct_location: HPXML::LocationBasementConditioned },
                             { duct_type: HPXML::DuctTypeReturn, duct_rvalue: duct_r, duct_area: 303.75, duct_location: HPXML::LocationAtticVented }])
      elsif [ESConstants.MFNationalVer1_0, ESConstants.MFOregonWashingtonVer1_2].include? program_version
        return_r = (program_version != ESConstants.MFOregonWashingtonVer1_2 ? 6.0 : 8.0)
        _check_ducts(hpxml, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 8.0, duct_area: 820.12, duct_location: HPXML::LocationAtticVented },
                             { duct_type: HPXML::DuctTypeSupply, duct_rvalue: 0.0, duct_area: 273.37, duct_location: HPXML::LocationLivingSpace },
                             { duct_type: HPXML::DuctTypeReturn, duct_rvalue: return_r, duct_area: 455.63, duct_location: HPXML::LocationAtticVented },
                             { duct_type: HPXML::DuctTypeReturn, duct_rvalue: 0.0, duct_area: 151.88, duct_location: HPXML::LocationLivingSpace }])
      else
        _check_ducts(hpxml, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 0.0, duct_area: 1093.51, duct_location: HPXML::LocationLivingSpace },
                             { duct_type: HPXML::DuctTypeReturn, duct_rvalue: 0.0, duct_area: 607.51, duct_location: HPXML::LocationLivingSpace }])
      end
      _check_duct_leakage(hpxml, [{ duct_type: HPXML::DuctTypeSupply, duct_leakage_units: HPXML::UnitsCFM25, duct_leakage_value: get_es_zerh_duct_leakage(program_version, 81.0), duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside },
                                  { duct_type: HPXML::DuctTypeReturn, duct_leakage_units: HPXML::UnitsCFM25, duct_leakage_value: get_es_zerh_duct_leakage(program_version, 81.0), duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside }])

      # Test w/ 2 stories
      _convert_to_es_zerh('base-foundation-multiple.xml', program_version)
      hpxml = HPXML.new(hpxml_path: @tmp_hpxml_path)
      hpxml.building_construction.number_of_conditioned_floors += 1
      hpxml.building_construction.number_of_conditioned_floors_above_grade += 1
      XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
      hpxml = _test_ruleset(program_version)
      hvac_iq_values = get_default_hvac_iq_values(program_version)
      _check_heating_system(hpxml, [{ systype: HPXML::HVACTypeFurnace, fuel: HPXML::FuelTypeNaturalGas, eff: get_es_zerh_gas_furnace_afue_cz5(program_version), frac_load: 1.0, **hvac_iq_values }])
      _check_cooling_system(hpxml, [{ systype: HPXML::HVACTypeCentralAirConditioner, fuel: HPXML::FuelTypeElectricity, seer: get_es_zerh_central_ac_seer_cz5(program_version), frac_load: 1.0, shr: 0.73, **hvac_iq_values }])
      _check_heat_pump(hpxml)
      _check_thermostat(hpxml, control_type: HPXML::HVACControlTypeProgrammable)
      if [ESConstants.SFNationalVer3_0, ESConstants.SFPacificVer3_0, ESConstants.SFOregonWashingtonVer3_2].include? program_version
        duct_r = (program_version != ESConstants.SFOregonWashingtonVer3_2 ? 6.0 : 8.0)
        _check_ducts(hpxml, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: duct_r, duct_area: 182.25, duct_location: HPXML::LocationBasementUnconditioned },
                             { duct_type: HPXML::DuctTypeSupply, duct_rvalue: 8.0, duct_area: 182.25, duct_location: HPXML::LocationAtticVented },
                             { duct_type: HPXML::DuctTypeReturn, duct_rvalue: duct_r, duct_area: 33.75, duct_location: HPXML::LocationBasementUnconditioned },
                             { duct_type: HPXML::DuctTypeReturn, duct_rvalue: duct_r, duct_area: 33.75, duct_location: HPXML::LocationAtticVented }])
      elsif [ESConstants.MFNationalVer1_0, ESConstants.MFOregonWashingtonVer1_2].include? program_version
        return_r = (program_version != ESConstants.MFOregonWashingtonVer1_2 ? 6.0 : 8.0)
        _check_ducts(hpxml, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 8.0, duct_area: 273.375, duct_location: HPXML::LocationAtticVented },
                             { duct_type: HPXML::DuctTypeSupply, duct_rvalue: 0.0, duct_area: 91.125, duct_location: HPXML::LocationLivingSpace },
                             { duct_type: HPXML::DuctTypeReturn, duct_rvalue: return_r, duct_area: 50.625, duct_location: HPXML::LocationAtticVented },
                             { duct_type: HPXML::DuctTypeReturn, duct_rvalue: 0.0, duct_area: 16.875, duct_location: HPXML::LocationLivingSpace }])
      else
        _check_ducts(hpxml, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 0.0, duct_area: 364.51, duct_location: HPXML::LocationLivingSpace },
                             { duct_type: HPXML::DuctTypeReturn, duct_rvalue: 0.0, duct_area: 67.5, duct_location: HPXML::LocationLivingSpace }])
      end
      _check_duct_leakage(hpxml, [{ duct_type: HPXML::DuctTypeSupply, duct_leakage_units: HPXML::UnitsCFM25, duct_leakage_value: get_es_zerh_duct_leakage(program_version, 27.0), duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside },
                                  { duct_type: HPXML::DuctTypeReturn, duct_leakage_units: HPXML::UnitsCFM25, duct_leakage_value: get_es_zerh_duct_leakage(program_version, 27.0), duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside }])

      # Test w/ 2 stories
      _convert_to_es_zerh('base-foundation-ambient.xml', program_version)
      hpxml = HPXML.new(hpxml_path: @tmp_hpxml_path)
      hpxml.building_construction.number_of_conditioned_floors += 1
      hpxml.building_construction.number_of_conditioned_floors_above_grade += 1
      XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
      hpxml = _test_ruleset(program_version)
      hvac_iq_values = get_default_hvac_iq_values(program_version)
      _check_heating_system(hpxml, [{ systype: HPXML::HVACTypeFurnace, fuel: HPXML::FuelTypeNaturalGas, eff: get_es_zerh_gas_furnace_afue_cz5(program_version), frac_load: 1.0, **hvac_iq_values }])
      _check_cooling_system(hpxml, [{ systype: HPXML::HVACTypeCentralAirConditioner, fuel: HPXML::FuelTypeElectricity, seer: get_es_zerh_central_ac_seer_cz5(program_version), frac_load: 1.0, shr: 0.73, **hvac_iq_values }])
      _check_heat_pump(hpxml)
      _check_thermostat(hpxml, control_type: HPXML::HVACControlTypeProgrammable)
      if [ESConstants.SFNationalVer3_0, ESConstants.SFPacificVer3_0, ESConstants.SFOregonWashingtonVer3_2].include? program_version
        duct_r = (program_version != ESConstants.SFOregonWashingtonVer3_2 ? 6.0 : 8.0)
        _check_ducts(hpxml, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: duct_r, duct_area: 182.25, duct_location: HPXML::LocationOutside },
                             { duct_type: HPXML::DuctTypeSupply, duct_rvalue: 8.0, duct_area: 182.25, duct_location: HPXML::LocationAtticVented },
                             { duct_type: HPXML::DuctTypeReturn, duct_rvalue: duct_r, duct_area: 33.75, duct_location: HPXML::LocationOutside },
                             { duct_type: HPXML::DuctTypeReturn, duct_rvalue: duct_r, duct_area: 33.75, duct_location: HPXML::LocationAtticVented }])
      elsif [ESConstants.MFNationalVer1_0, ESConstants.MFOregonWashingtonVer1_2].include? program_version
        return_r = (program_version != ESConstants.MFOregonWashingtonVer1_2 ? 6.0 : 8.0)
        _check_ducts(hpxml, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 8.0, duct_area: 273.375, duct_location: HPXML::LocationAtticVented },
                             { duct_type: HPXML::DuctTypeSupply, duct_rvalue: 0.0, duct_area: 91.125, duct_location: HPXML::LocationLivingSpace },
                             { duct_type: HPXML::DuctTypeReturn, duct_rvalue: return_r, duct_area: 50.625, duct_location: HPXML::LocationAtticVented },
                             { duct_type: HPXML::DuctTypeReturn, duct_rvalue: 0.0, duct_area: 16.875, duct_location: HPXML::LocationLivingSpace }])
      else
        _check_ducts(hpxml, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 0.0, duct_area: 364.51, duct_location: HPXML::LocationLivingSpace },
                             { duct_type: HPXML::DuctTypeReturn, duct_rvalue: 0.0, duct_area: 67.5, duct_location: HPXML::LocationLivingSpace }])
      end
      _check_duct_leakage(hpxml, [{ duct_type: HPXML::DuctTypeSupply, duct_leakage_units: HPXML::UnitsCFM25, duct_leakage_value: get_es_zerh_duct_leakage(program_version, 27.0), duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside },
                                  { duct_type: HPXML::DuctTypeReturn, duct_leakage_units: HPXML::UnitsCFM25, duct_leakage_value: get_es_zerh_duct_leakage(program_version, 27.0), duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside }])
    end
  end

  def test_multiple_hvac
    [*ESConstants.AllVersions, *ZERHConstants.AllVersions].each do |program_version|
      _convert_to_es_zerh('base-hvac-multiple.xml', program_version)
      hpxml = _test_ruleset(program_version)
      hvac_iq_values = get_default_hvac_iq_values(program_version)
      if [ESConstants.SFNationalVer3_2, ESConstants.MFNationalVer1_2].include? program_version
        _check_heating_system(hpxml, [{ systype: HPXML::HVACTypeFurnace, fuel: HPXML::FuelTypeNaturalGas, eff: get_es_zerh_gas_furnace_afue_cz5(program_version), frac_load: 0.1, **hvac_iq_values },
                                      { systype: HPXML::HVACTypeBoiler, fuel: HPXML::FuelTypeElectricity, eff: 0.98, frac_load: 0.1 },
                                      { systype: HPXML::HVACTypeBoiler, fuel: HPXML::FuelTypeNaturalGas, eff: get_es_zerh_gas_boiler_afue_cz5(program_version), frac_load: 0.1 },
                                      { systype: HPXML::HVACTypeFurnace, fuel: HPXML::FuelTypeNaturalGas, eff: get_es_zerh_gas_furnace_afue_cz5(program_version), frac_load: 0.1, **hvac_iq_values },
                                      { systype: HPXML::HVACTypeFurnace, fuel: HPXML::FuelTypeNaturalGas, eff: get_es_zerh_gas_furnace_afue_cz5(program_version), frac_load: 0.1, **hvac_iq_values }])
      else
        _check_heating_system(hpxml, [{ systype: HPXML::HVACTypeFurnace, fuel: HPXML::FuelTypeNaturalGas, eff: get_es_zerh_gas_furnace_afue_cz5(program_version), frac_load: 0.1, **hvac_iq_values },
                                      { systype: HPXML::HVACTypeBoiler, fuel: HPXML::FuelTypeElectricity, eff: 0.98, frac_load: 0.1 },
                                      { systype: HPXML::HVACTypeBoiler, fuel: HPXML::FuelTypeNaturalGas, eff: get_es_zerh_gas_boiler_afue_cz5(program_version), frac_load: 0.1 },
                                      { systype: HPXML::HVACTypeFurnace, fuel: HPXML::FuelTypeOil, eff: get_es_zerh_oil_furnace_afue_cz5(program_version), frac_load: 0.1, **hvac_iq_values },
                                      { systype: HPXML::HVACTypeFurnace, fuel: HPXML::FuelTypeNaturalGas, eff: get_es_zerh_gas_furnace_afue_cz5(program_version), frac_load: 0.1, **hvac_iq_values }])
      end
      _check_cooling_system(hpxml, [{ systype: HPXML::HVACTypeCentralAirConditioner, fuel: HPXML::FuelTypeElectricity, seer: get_es_zerh_central_ac_seer_cz5(program_version), frac_load: 0.1333, shr: 0.73, **hvac_iq_values },
                                    { systype: HPXML::HVACTypeCentralAirConditioner, fuel: HPXML::FuelTypeElectricity, seer: get_es_zerh_central_ac_seer_cz5(program_version), frac_load: 0.1333, shr: 0.65, **hvac_iq_values },
                                    { systype: HPXML::HVACTypeCentralAirConditioner, fuel: HPXML::FuelTypeElectricity, seer: get_es_zerh_central_ac_seer_cz5(program_version), frac_load: 0.1333, shr: 0.65, **hvac_iq_values }])
      if ESConstants.MFVersions.include? program_version
        _check_heat_pump(hpxml, [{ systype: HPXML::HVACTypeHeatPumpAirToAir, fuel: HPXML::FuelTypeElectricity, hspf: get_es_zerh_ashp_hspf_cz5(program_version), seer: get_es_zerh_ashp_seer_cz5(program_version), frac_load_heat: 0.1, frac_load_cool: 0.0, backup_fuel: HPXML::FuelTypeElectricity, backup_eff: 1.0, **hvac_iq_values },
                                 { systype: HPXML::HVACTypeHeatPumpAirToAir, fuel: HPXML::FuelTypeElectricity, hspf: get_es_zerh_ashp_hspf_cz5(program_version), seer: get_es_zerh_ashp_seer_cz5(program_version), frac_load_heat: 0.1, frac_load_cool: 0.0, backup_fuel: HPXML::FuelTypeElectricity, backup_eff: 1.0, **hvac_iq_values },
                                 { systype: HPXML::HVACTypeHeatPumpAirToAir, fuel: HPXML::FuelTypeElectricity, hspf: get_es_zerh_ashp_hspf_cz5(program_version), seer: get_es_zerh_ashp_seer_cz5(program_version), frac_load_heat: 0.1, frac_load_cool: 0.2, backup_fuel: HPXML::FuelTypeElectricity, backup_eff: 1.0, shr: 0.73, **hvac_iq_values },
                                 { systype: HPXML::HVACTypeHeatPumpGroundToAir, fuel: HPXML::FuelTypeElectricity, cop: get_es_zerh_gshp_cop_cz5(program_version), eer: get_es_zerh_gshp_eer_cz5(program_version), frac_load_heat: 0.1, frac_load_cool: 0.2, pump_w_per_ton: 30, is_shared_system: false, shr: 0.73, **hvac_iq_values },
                                 { systype: HPXML::HVACTypeHeatPumpAirToAir, fuel: HPXML::FuelTypeElectricity, hspf: get_es_zerh_ashp_hspf_cz5(program_version), seer: get_es_zerh_ashp_seer_cz5(program_version), frac_load_heat: 0.1, frac_load_cool: 0.2, backup_fuel: HPXML::FuelTypeElectricity, backup_eff: 1.0, shr: 0.73, **hvac_iq_values }])
      else
        _check_heat_pump(hpxml, [{ systype: HPXML::HVACTypeHeatPumpAirToAir, fuel: HPXML::FuelTypeElectricity, hspf: get_es_zerh_ashp_hspf_cz5(program_version), seer: get_es_zerh_ashp_seer_cz5(program_version), frac_load_heat: 0.1, frac_load_cool: 0.0, backup_fuel: HPXML::FuelTypeElectricity, backup_eff: 1.0, **hvac_iq_values },
                                 { systype: HPXML::HVACTypeHeatPumpAirToAir, fuel: HPXML::FuelTypeElectricity, hspf: get_es_zerh_ashp_hspf_cz5(program_version), seer: get_es_zerh_ashp_seer_cz5(program_version), frac_load_heat: 0.1, frac_load_cool: 0.0, backup_fuel: HPXML::FuelTypeElectricity, backup_eff: 1.0, **hvac_iq_values },
                                 { systype: HPXML::HVACTypeHeatPumpAirToAir, fuel: HPXML::FuelTypeElectricity, hspf: get_es_zerh_ashp_hspf_cz5(program_version), seer: get_es_zerh_ashp_seer_cz5(program_version), frac_load_heat: 0.1, frac_load_cool: 0.2, backup_fuel: HPXML::FuelTypeElectricity, backup_eff: 1.0, shr: 0.73, **hvac_iq_values },
                                 { systype: HPXML::HVACTypeHeatPumpAirToAir, fuel: HPXML::FuelTypeElectricity, hspf: get_es_zerh_ashp_hspf_cz5(program_version), seer: get_es_zerh_ashp_seer_cz5(program_version), frac_load_heat: 0.1, frac_load_cool: 0.2, backup_fuel: HPXML::FuelTypeElectricity, backup_eff: 1.0, shr: 0.73, **hvac_iq_values },
                                 { systype: HPXML::HVACTypeHeatPumpAirToAir, fuel: HPXML::FuelTypeElectricity, hspf: get_es_zerh_ashp_hspf_cz5(program_version), seer: get_es_zerh_ashp_seer_cz5(program_version), frac_load_heat: 0.1, frac_load_cool: 0.2, backup_fuel: HPXML::FuelTypeElectricity, backup_eff: 1.0, shr: 0.73, **hvac_iq_values }])

      end
      _check_thermostat(hpxml, control_type: HPXML::HVACControlTypeProgrammable)
    end
  end

  def test_partial_hvac
    [*ESConstants.AllVersions, *ZERHConstants.AllVersions].each do |program_version|
      _convert_to_es_zerh('base.xml', program_version)
      hpxml = HPXML.new(hpxml_path: @tmp_hpxml_path)
      hpxml.heating_systems[0].fraction_heat_load_served = 0.2
      hpxml.cooling_systems[0].fraction_cool_load_served = 0.3
      XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
      hpxml = _test_ruleset(program_version)
      hvac_iq_values = get_default_hvac_iq_values(program_version)
      _check_heating_system(hpxml, [{ systype: HPXML::HVACTypeFurnace, fuel: HPXML::FuelTypeNaturalGas, eff: get_es_zerh_gas_furnace_afue_cz5(program_version), frac_load: 0.2, **hvac_iq_values }])
      _check_cooling_system(hpxml, [{ systype: HPXML::HVACTypeCentralAirConditioner, fuel: HPXML::FuelTypeElectricity, seer: get_es_zerh_central_ac_seer_cz5(program_version), frac_load: 0.3, shr: 0.73, **hvac_iq_values }])
      _check_heat_pump(hpxml)
      _check_thermostat(hpxml, control_type: HPXML::HVACControlTypeProgrammable)
      if [ESConstants.SFNationalVer3_0, ESConstants.SFPacificVer3_0, ESConstants.SFOregonWashingtonVer3_2].include? program_version
        _check_ducts(hpxml, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 0.0, duct_area: 729.0, duct_location: HPXML::LocationBasementConditioned },
                             { duct_type: HPXML::DuctTypeReturn, duct_rvalue: 0.0, duct_area: 270.0, duct_location: HPXML::LocationBasementConditioned }])
      elsif [ESConstants.SFNationalVer3_1, ESConstants.SFNationalVer3_2, ESConstants.SFFloridaVer3_1,
             ESConstants.MFNationalVer1_1, ESConstants.MFNationalVer1_2,
             ZERHConstants.Ver1, ZERHConstants.SFVer2].include? program_version
        _check_ducts(hpxml, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 0.0, duct_area: 729.0, duct_location: HPXML::LocationLivingSpace },
                             { duct_type: HPXML::DuctTypeReturn, duct_rvalue: 0.0, duct_area: 270.0, duct_location: HPXML::LocationLivingSpace }])
      else
        return_r = (program_version != ESConstants.MFOregonWashingtonVer1_2 ? 6.0 : 8.0)
        _check_ducts(hpxml, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 8.0, duct_area: 729.0, duct_location: HPXML::LocationAtticVented },
                             { duct_type: HPXML::DuctTypeReturn, duct_rvalue: return_r, duct_area: 270.0, duct_location: HPXML::LocationAtticVented }])
      end
      _check_duct_leakage(hpxml, [{ duct_type: HPXML::DuctTypeSupply, duct_leakage_units: HPXML::UnitsCFM25, duct_leakage_value: get_es_zerh_duct_leakage(program_version, 54.0), duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside },
                                  { duct_type: HPXML::DuctTypeReturn, duct_leakage_units: HPXML::UnitsCFM25, duct_leakage_value: get_es_zerh_duct_leakage(program_version, 54.0), duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside }])
    end
  end

  def test_shared_boiler_baseboard
    hpxml_name = 'base-bldgtype-multifamily-shared-boiler-only-baseboard.xml'
    [*ESConstants.AllVersions, *ZERHConstants.AllVersions].each do |program_version|
      _convert_to_es_zerh(hpxml_name, program_version)
      hpxml = HPXML.new(hpxml_path: @tmp_hpxml_path)
      XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
      hpxml = _test_ruleset(program_version)
      if [ESConstants.MFNationalVer1_2, ESConstants.SFNationalVer3_2].include? program_version
        _check_heating_system(hpxml, [{ systype: HPXML::HVACTypeBoiler, fuel: HPXML::FuelTypeNaturalGas, eff: 0.95, num_units_served: 6, frac_load: 1.0, shared_loop_watts: 635.3 }])
      else
        _check_heating_system(hpxml, [{ systype: HPXML::HVACTypeBoiler, fuel: HPXML::FuelTypeNaturalGas, eff: 0.86, num_units_served: 6, frac_load: 1.0, shared_loop_watts: 635.3 }])
      end
      _check_cooling_system(hpxml)
      _check_heat_pump(hpxml)
      _check_thermostat(hpxml, control_type: HPXML::HVACControlTypeProgrammable)
      _check_ducts(hpxml)
      _check_duct_leakage(hpxml)

      # test with heating capacity less than 300,000 Btuh
      _convert_to_es_zerh(hpxml_name, program_version)
      hpxml = HPXML.new(hpxml_path: @tmp_hpxml_path)
      hpxml.heating_systems[0].heating_capacity = 290000
      XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
      hpxml = _test_ruleset(program_version)
      if [ESConstants.SFNationalVer3_0, ESConstants.MFNationalVer1_0].include? program_version
        _check_heating_system(hpxml, [{ systype: HPXML::HVACTypeBoiler, fuel: HPXML::FuelTypeNaturalGas, eff: 0.85, num_units_served: 6, frac_load: 1.0, shared_loop_watts: 635.3 }])
      elsif [ESConstants.SFPacificVer3_0, ESConstants.SFFloridaVer3_1].include? program_version
        _check_heating_system(hpxml, [{ systype: HPXML::HVACTypeBoiler, fuel: HPXML::FuelTypeNaturalGas, eff: 0.80, num_units_served: 6, frac_load: 1.0, shared_loop_watts: 635.3 }])
      elsif [ZERHConstants.Ver1].include? program_version
        _check_heating_system(hpxml, [{ systype: HPXML::HVACTypeBoiler, fuel: HPXML::FuelTypeNaturalGas, eff: 0.94, num_units_served: 6, frac_load: 1.0, shared_loop_watts: 635.3 }])
      elsif [ESConstants.SFNationalVer3_2, ESConstants.MFNationalVer1_2].include? program_version
        _check_heating_system(hpxml, [{ systype: HPXML::HVACTypeBoiler, fuel: HPXML::FuelTypeNaturalGas, eff: 0.95, num_units_served: 6, frac_load: 1.0, shared_loop_watts: 635.3 }])
      else
        _check_heating_system(hpxml, [{ systype: HPXML::HVACTypeBoiler, fuel: HPXML::FuelTypeNaturalGas, eff: 0.90, num_units_served: 6, frac_load: 1.0, shared_loop_watts: 635.3 }])
      end
      _check_cooling_system(hpxml)
      _check_heat_pump(hpxml)
      _check_thermostat(hpxml, control_type: HPXML::HVACControlTypeProgrammable)
      _check_ducts(hpxml)
      _check_duct_leakage(hpxml)
    end
  end

  def test_shared_boiler_fan_coil
    hpxml_name = 'base-bldgtype-multifamily-shared-boiler-only-fan-coil.xml'
    [*ESConstants.AllVersions, *ZERHConstants.AllVersions].each do |program_version|
      _convert_to_es_zerh(hpxml_name, program_version)
      hpxml = HPXML.new(hpxml_path: @tmp_hpxml_path)
      XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
      hpxml = _test_ruleset(program_version)
      if [ESConstants.MFNationalVer1_2, ESConstants.SFNationalVer3_2].include? program_version
        _check_heating_system(hpxml, [{ systype: HPXML::HVACTypeBoiler, fuel: HPXML::FuelTypeNaturalGas, eff: 0.95, num_units_served: 6, frac_load: 1.0, shared_loop_watts: 635.3, fan_coil_watts: 150.0 }])
      else
        _check_heating_system(hpxml, [{ systype: HPXML::HVACTypeBoiler, fuel: HPXML::FuelTypeNaturalGas, eff: 0.86, num_units_served: 6, frac_load: 1.0, shared_loop_watts: 635.3, fan_coil_watts: 150.0 }])
      end
      _check_cooling_system(hpxml)
      _check_heat_pump(hpxml)
      _check_thermostat(hpxml, control_type: HPXML::HVACControlTypeProgrammable)
      if [ESConstants.SFNationalVer3_0, ESConstants.SFPacificVer3_0, ESConstants.SFOregonWashingtonVer3_2].include? program_version
        return_duct_r = (program_version != ESConstants.SFOregonWashingtonVer3_2 ? 6.0 : 8.0)
        _check_ducts(hpxml, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 8.0, duct_area: 243.0, duct_location: HPXML::LocationAtticVented },
                             { duct_type: HPXML::DuctTypeReturn, duct_rvalue: return_duct_r, duct_area: 45.0, duct_location: HPXML::LocationAtticVented }])
      else
        _check_ducts(hpxml, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 0.0, duct_area: 243.0, duct_location: HPXML::LocationLivingSpace },
                             { duct_type: HPXML::DuctTypeReturn, duct_rvalue: 0.0, duct_area: 45.0, duct_location: HPXML::LocationLivingSpace }])
      end
      _check_duct_leakage(hpxml, [{ duct_type: HPXML::DuctTypeSupply, duct_leakage_units: HPXML::UnitsCFM25, duct_leakage_value: get_es_zerh_duct_leakage(program_version, 20.0), duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside },
                                  { duct_type: HPXML::DuctTypeReturn, duct_leakage_units: HPXML::UnitsCFM25, duct_leakage_value: get_es_zerh_duct_leakage(program_version, 20.0), duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside }])

      # test with heating capacity less than 300,000 Btuh
      _convert_to_es_zerh(hpxml_name, program_version)
      hpxml = HPXML.new(hpxml_path: @tmp_hpxml_path)
      hpxml.heating_systems[0].heating_capacity = 290000
      XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
      hpxml = _test_ruleset(program_version)
      if [ESConstants.SFNationalVer3_0, ESConstants.MFNationalVer1_0].include? program_version
        _check_heating_system(hpxml, [{ systype: HPXML::HVACTypeBoiler, fuel: HPXML::FuelTypeNaturalGas, eff: 0.85, num_units_served: 6, frac_load: 1.0, shared_loop_watts: 635.3, fan_coil_watts: 150.0 }])
      elsif [ESConstants.SFPacificVer3_0, ESConstants.SFFloridaVer3_1].include? program_version
        _check_heating_system(hpxml, [{ systype: HPXML::HVACTypeBoiler, fuel: HPXML::FuelTypeNaturalGas, eff: 0.80, num_units_served: 6, frac_load: 1.0, shared_loop_watts: 635.3, fan_coil_watts: 150.0 }])
      elsif [ZERHConstants.Ver1].include? program_version
        _check_heating_system(hpxml, [{ systype: HPXML::HVACTypeBoiler, fuel: HPXML::FuelTypeNaturalGas, eff: 0.94, num_units_served: 6, frac_load: 1.0, shared_loop_watts: 635.3, fan_coil_watts: 150.0 }])
      elsif [ESConstants.SFNationalVer3_2, ESConstants.MFNationalVer1_2].include? program_version
        _check_heating_system(hpxml, [{ systype: HPXML::HVACTypeBoiler, fuel: HPXML::FuelTypeNaturalGas, eff: 0.95, num_units_served: 6, frac_load: 1.0, shared_loop_watts: 635.3, fan_coil_watts: 150.0 }])
      else
        _check_heating_system(hpxml, [{ systype: HPXML::HVACTypeBoiler, fuel: HPXML::FuelTypeNaturalGas, eff: 0.90, num_units_served: 6, frac_load: 1.0, shared_loop_watts: 635.3, fan_coil_watts: 150.0 }])
      end
      _check_cooling_system(hpxml)
      _check_heat_pump(hpxml)
      _check_thermostat(hpxml, control_type: HPXML::HVACControlTypeProgrammable)
      if [ESConstants.SFNationalVer3_0, ESConstants.SFPacificVer3_0, ESConstants.SFOregonWashingtonVer3_2].include? program_version
        return_duct_r = (program_version != ESConstants.SFOregonWashingtonVer3_2 ? 6.0 : 8.0)
        _check_ducts(hpxml, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 8.0, duct_area: 243.0, duct_location: HPXML::LocationAtticVented },
                             { duct_type: HPXML::DuctTypeReturn, duct_rvalue: return_duct_r, duct_area: 45.0, duct_location: HPXML::LocationAtticVented }])
      else
        _check_ducts(hpxml, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 0.0, duct_area: 243.0, duct_location: HPXML::LocationLivingSpace },
                             { duct_type: HPXML::DuctTypeReturn, duct_rvalue: 0.0, duct_area: 45.0, duct_location: HPXML::LocationLivingSpace }])
      end
      _check_duct_leakage(hpxml, [{ duct_type: HPXML::DuctTypeSupply, duct_leakage_units: HPXML::UnitsCFM25, duct_leakage_value: get_es_zerh_duct_leakage(program_version, 20.0), duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside },
                                  { duct_type: HPXML::DuctTypeReturn, duct_leakage_units: HPXML::UnitsCFM25, duct_leakage_value: get_es_zerh_duct_leakage(program_version, 20.0), duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside }])
    end
  end

  def test_shared_boiler_fan_coil_ducted
    hpxml_name = 'base-bldgtype-multifamily-shared-boiler-only-fan-coil-ducted.xml'
    [*ESConstants.AllVersions, *ZERHConstants.AllVersions].each do |program_version|
      _convert_to_es_zerh(hpxml_name, program_version)
      hpxml = HPXML.new(hpxml_path: @tmp_hpxml_path)
      XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
      hpxml = _test_ruleset(program_version)
      if [ESConstants.MFNationalVer1_2, ESConstants.SFNationalVer3_2].include? program_version
        _check_heating_system(hpxml, [{ systype: HPXML::HVACTypeBoiler, fuel: HPXML::FuelTypeNaturalGas, eff: 0.95, num_units_served: 6, frac_load: 1.0, shared_loop_watts: 635.3, fan_coil_watts: 150.0 }])
      else
        _check_heating_system(hpxml, [{ systype: HPXML::HVACTypeBoiler, fuel: HPXML::FuelTypeNaturalGas, eff: 0.86, num_units_served: 6, frac_load: 1.0, shared_loop_watts: 635.3, fan_coil_watts: 150.0 }])
      end
      _check_cooling_system(hpxml)
      _check_heat_pump(hpxml)
      _check_thermostat(hpxml, control_type: HPXML::HVACControlTypeProgrammable)
      if [ESConstants.SFNationalVer3_0, ESConstants.SFPacificVer3_0, ESConstants.SFOregonWashingtonVer3_2].include? program_version
        return_duct_r = (program_version != ESConstants.SFOregonWashingtonVer3_2 ? 6.0 : 8.0)
        _check_ducts(hpxml, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 8.0, duct_area: 243.0, duct_location: HPXML::LocationAtticVented },
                             { duct_type: HPXML::DuctTypeReturn, duct_rvalue: return_duct_r, duct_area: 45.0, duct_location: HPXML::LocationAtticVented }])
      else
        _check_ducts(hpxml, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 0.0, duct_area: 243.0, duct_location: HPXML::LocationLivingSpace },
                             { duct_type: HPXML::DuctTypeReturn, duct_rvalue: 0.0, duct_area: 45.0, duct_location: HPXML::LocationLivingSpace }])
      end
      _check_duct_leakage(hpxml, [{ duct_type: HPXML::DuctTypeSupply, duct_leakage_units: HPXML::UnitsCFM25, duct_leakage_value: get_es_zerh_duct_leakage(program_version, 20.0), duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside },
                                  { duct_type: HPXML::DuctTypeReturn, duct_leakage_units: HPXML::UnitsCFM25, duct_leakage_value: get_es_zerh_duct_leakage(program_version, 20.0), duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside }])

      # test with heating capacity less than 300,000 Btuh
      _convert_to_es_zerh(hpxml_name, program_version)
      hpxml = HPXML.new(hpxml_path: @tmp_hpxml_path)
      hpxml.heating_systems[0].heating_capacity = 290000
      XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
      hpxml = _test_ruleset(program_version)
      if [ESConstants.SFNationalVer3_0, ESConstants.MFNationalVer1_0].include? program_version
        _check_heating_system(hpxml, [{ systype: HPXML::HVACTypeBoiler, fuel: HPXML::FuelTypeNaturalGas, eff: 0.85, num_units_served: 6, frac_load: 1.0, shared_loop_watts: 635.3, fan_coil_watts: 150.0 }])
      elsif [ESConstants.SFPacificVer3_0, ESConstants.SFFloridaVer3_1].include? program_version
        _check_heating_system(hpxml, [{ systype: HPXML::HVACTypeBoiler, fuel: HPXML::FuelTypeNaturalGas, eff: 0.80, num_units_served: 6, frac_load: 1.0, shared_loop_watts: 635.3, fan_coil_watts: 150.0 }])
      elsif [ZERHConstants.Ver1].include? program_version
        _check_heating_system(hpxml, [{ systype: HPXML::HVACTypeBoiler, fuel: HPXML::FuelTypeNaturalGas, eff: 0.94, num_units_served: 6, frac_load: 1.0, shared_loop_watts: 635.3, fan_coil_watts: 150.0 }])
      elsif [ESConstants.SFNationalVer3_2, ESConstants.MFNationalVer1_2].include? program_version
        _check_heating_system(hpxml, [{ systype: HPXML::HVACTypeBoiler, fuel: HPXML::FuelTypeNaturalGas, eff: 0.95, num_units_served: 6, frac_load: 1.0, shared_loop_watts: 635.3, fan_coil_watts: 150.0 }])
      else
        _check_heating_system(hpxml, [{ systype: HPXML::HVACTypeBoiler, fuel: HPXML::FuelTypeNaturalGas, eff: 0.90, num_units_served: 6, frac_load: 1.0, shared_loop_watts: 635.3, fan_coil_watts: 150.0 }])
      end
      _check_cooling_system(hpxml)
      _check_heat_pump(hpxml)
      _check_thermostat(hpxml, control_type: HPXML::HVACControlTypeProgrammable)
      if [ESConstants.SFNationalVer3_0, ESConstants.SFPacificVer3_0, ESConstants.SFOregonWashingtonVer3_2].include? program_version
        return_duct_r = (program_version != ESConstants.SFOregonWashingtonVer3_2 ? 6.0 : 8.0)
        _check_ducts(hpxml, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 8.0, duct_area: 243.0, duct_location: HPXML::LocationAtticVented },
                             { duct_type: HPXML::DuctTypeReturn, duct_rvalue: return_duct_r, duct_area: 45.0, duct_location: HPXML::LocationAtticVented }])
      else
        _check_ducts(hpxml, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 0.0, duct_area: 243.0, duct_location: HPXML::LocationLivingSpace },
                             { duct_type: HPXML::DuctTypeReturn, duct_rvalue: 0.0, duct_area: 45.0, duct_location: HPXML::LocationLivingSpace }])
      end
      _check_duct_leakage(hpxml, [{ duct_type: HPXML::DuctTypeSupply, duct_leakage_units: HPXML::UnitsCFM25, duct_leakage_value: get_es_zerh_duct_leakage(program_version, 20.0), duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside },
                                  { duct_type: HPXML::DuctTypeReturn, duct_leakage_units: HPXML::UnitsCFM25, duct_leakage_value: get_es_zerh_duct_leakage(program_version, 20.0), duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside }])
    end
  end

  def test_shared_boiler_water_loop_heat_pump
    hpxml_name = 'base-bldgtype-multifamily-shared-boiler-only-water-loop-heat-pump.xml'
    [*ESConstants.AllVersions, *ZERHConstants.AllVersions].each do |program_version|
      _convert_to_es_zerh(hpxml_name, program_version)
      hpxml = HPXML.new(hpxml_path: @tmp_hpxml_path)
      XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
      hpxml = _test_ruleset(program_version)
      if [ESConstants.MFNationalVer1_2, ESConstants.SFNationalVer3_2].include? program_version
        _check_heating_system(hpxml, [{ systype: HPXML::HVACTypeBoiler, fuel: HPXML::FuelTypeNaturalGas, eff: 0.90, num_units_served: 6, frac_load: 1.0, shared_loop_watts: 635.3 }])
      else
        _check_heating_system(hpxml, [{ systype: HPXML::HVACTypeBoiler, fuel: HPXML::FuelTypeNaturalGas, eff: 0.89, num_units_served: 6, frac_load: 1.0, shared_loop_watts: 635.3 }])
      end
      _check_cooling_system(hpxml)
      if [ESConstants.MFNationalVer1_2, ESConstants.SFNationalVer3_2].include? program_version
        _check_heat_pump(hpxml, [{ systype: HPXML::HVACTypeHeatPumpWaterLoopToAir, fuel: HPXML::FuelTypeElectricity, cop: 4.5, eer: 15, heating_capacity: 24000.0 }])
      else
        _check_heat_pump(hpxml, [{ systype: HPXML::HVACTypeHeatPumpWaterLoopToAir, fuel: HPXML::FuelTypeElectricity, cop: 4.2, eer: 14, heating_capacity: 24000.0 }])
      end
      _check_thermostat(hpxml, control_type: HPXML::HVACControlTypeProgrammable)
      if [ESConstants.SFNationalVer3_0, ESConstants.SFPacificVer3_0, ESConstants.SFOregonWashingtonVer3_2].include? program_version
        return_duct_r = (program_version != ESConstants.SFOregonWashingtonVer3_2 ? 6.0 : 8.0)
        _check_ducts(hpxml, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 8.0, duct_area: 243.0, duct_location: HPXML::LocationAtticVented },
                             { duct_type: HPXML::DuctTypeReturn, duct_rvalue: return_duct_r, duct_area: 45.0, duct_location: HPXML::LocationAtticVented }])
      else
        _check_ducts(hpxml, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 0.0, duct_area: 243.0, duct_location: HPXML::LocationLivingSpace },
                             { duct_type: HPXML::DuctTypeReturn, duct_rvalue: 0.0, duct_area: 45.0, duct_location: HPXML::LocationLivingSpace }])
      end
      _check_duct_leakage(hpxml, [{ duct_type: HPXML::DuctTypeSupply, duct_leakage_units: HPXML::UnitsCFM25, duct_leakage_value: get_es_zerh_duct_leakage(program_version, 20.0), duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside },
                                  { duct_type: HPXML::DuctTypeReturn, duct_leakage_units: HPXML::UnitsCFM25, duct_leakage_value: get_es_zerh_duct_leakage(program_version, 20.0), duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside }])

      # test w/ heating capacity less than 300,000 Btuh
      _convert_to_es_zerh(hpxml_name, program_version)
      hpxml = HPXML.new(hpxml_path: @tmp_hpxml_path)
      hpxml.heating_systems[0].heating_capacity = 290000
      XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
      hpxml = _test_ruleset(program_version)
      if [ESConstants.SFNationalVer3_0, ESConstants.MFNationalVer1_0].include? program_version
        _check_heating_system(hpxml, [{ systype: HPXML::HVACTypeBoiler, fuel: HPXML::FuelTypeNaturalGas, eff: 0.85, num_units_served: 6, frac_load: 1.0, shared_loop_watts: 635.3 }])
      elsif [ESConstants.SFPacificVer3_0, ESConstants.SFFloridaVer3_1].include? program_version
        _check_heating_system(hpxml, [{ systype: HPXML::HVACTypeBoiler, fuel: HPXML::FuelTypeNaturalGas, eff: 0.80, num_units_served: 6, frac_load: 1.0, shared_loop_watts: 635.3 }])
      elsif [ZERHConstants.Ver1].include? program_version
        _check_heating_system(hpxml, [{ systype: HPXML::HVACTypeBoiler, fuel: HPXML::FuelTypeNaturalGas, eff: 0.94, num_units_served: 6, frac_load: 1.0, shared_loop_watts: 635.3 }])
      elsif [ESConstants.SFNationalVer3_2, ESConstants.MFNationalVer1_2].include? program_version
        _check_heating_system(hpxml, [{ systype: HPXML::HVACTypeBoiler, fuel: HPXML::FuelTypeNaturalGas, eff: 0.95, num_units_served: 6, frac_load: 1.0, shared_loop_watts: 635.3 }])
      else
        _check_heating_system(hpxml, [{ systype: HPXML::HVACTypeBoiler, fuel: HPXML::FuelTypeNaturalGas, eff: 0.90, num_units_served: 6, frac_load: 1.0, shared_loop_watts: 635.3 }])
      end
      _check_cooling_system(hpxml)
      if [ESConstants.MFNationalVer1_2, ESConstants.SFNationalVer3_2].include? program_version
        _check_heat_pump(hpxml, [{ systype: HPXML::HVACTypeHeatPumpWaterLoopToAir, fuel: HPXML::FuelTypeElectricity, cop: 4.5, eer: 15, heating_capacity: 24000.0 }])
      else
        _check_heat_pump(hpxml, [{ systype: HPXML::HVACTypeHeatPumpWaterLoopToAir, fuel: HPXML::FuelTypeElectricity, cop: 4.2, eer: 14, heating_capacity: 24000.0 }])
      end
      _check_thermostat(hpxml, control_type: HPXML::HVACControlTypeProgrammable)
      if [ESConstants.SFNationalVer3_0, ESConstants.SFPacificVer3_0, ESConstants.SFOregonWashingtonVer3_2].include? program_version
        return_duct_r = (program_version != ESConstants.SFOregonWashingtonVer3_2 ? 6.0 : 8.0)
        _check_ducts(hpxml, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 8.0, duct_area: 243.0, duct_location: HPXML::LocationAtticVented },
                             { duct_type: HPXML::DuctTypeReturn, duct_rvalue: return_duct_r, duct_area: 45.0, duct_location: HPXML::LocationAtticVented }])
      else
        _check_ducts(hpxml, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 0.0, duct_area: 243.0, duct_location: HPXML::LocationLivingSpace },
                             { duct_type: HPXML::DuctTypeReturn, duct_rvalue: 0.0, duct_area: 45.0, duct_location: HPXML::LocationLivingSpace }])
      end
      _check_duct_leakage(hpxml, [{ duct_type: HPXML::DuctTypeSupply, duct_leakage_units: HPXML::UnitsCFM25, duct_leakage_value: get_es_zerh_duct_leakage(program_version, 20.0), duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside },
                                  { duct_type: HPXML::DuctTypeReturn, duct_leakage_units: HPXML::UnitsCFM25, duct_leakage_value: get_es_zerh_duct_leakage(program_version, 20.0), duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside }])
    end
  end

  def test_shared_chiller_baseboard
    hpxml_name = 'base-bldgtype-multifamily-shared-chiller-only-baseboard.xml'
    [*ESConstants.AllVersions, *ZERHConstants.AllVersions].each do |program_version|
      _convert_to_es_zerh(hpxml_name, program_version)
      hpxml = _test_ruleset(program_version)
      _check_heating_system(hpxml)
      if [ESConstants.MFNationalVer1_2, ESConstants.SFNationalVer3_2].include? program_version
        _check_cooling_system(hpxml, [{ num_units_served: 6, systype: HPXML::HVACTypeChiller, fuel: HPXML::FuelTypeElectricity, kw_per_ton: 0.75, frac_load: 1.0, shared_loop_watts: 635.3 }])
      else
        _check_cooling_system(hpxml, [{ num_units_served: 6, systype: HPXML::HVACTypeChiller, fuel: HPXML::FuelTypeElectricity, kw_per_ton: 0.78, frac_load: 1.0, shared_loop_watts: 635.3 }])
      end
      _check_heat_pump(hpxml)
      _check_thermostat(hpxml, control_type: HPXML::HVACControlTypeProgrammable)
      _check_ducts(hpxml)
      _check_duct_leakage(hpxml)
    end
  end

  def test_shared_chiller_fan_coil
    hpxml_name = 'base-bldgtype-multifamily-shared-chiller-only-fan-coil.xml'
    [*ESConstants.AllVersions, *ZERHConstants.AllVersions].each do |program_version|
      _convert_to_es_zerh(hpxml_name, program_version)
      hpxml = _test_ruleset(program_version)
      _check_heating_system(hpxml)
      if [ESConstants.MFNationalVer1_2, ESConstants.SFNationalVer3_2].include? program_version
        _check_cooling_system(hpxml, [{ num_units_served: 6, systype: HPXML::HVACTypeChiller, fuel: HPXML::FuelTypeElectricity, kw_per_ton: 0.75, frac_load: 1.0, shared_loop_watts: 635.3, fan_coil_watts: 150.0 }])
      else
        _check_cooling_system(hpxml, [{ num_units_served: 6, systype: HPXML::HVACTypeChiller, fuel: HPXML::FuelTypeElectricity, kw_per_ton: 0.78, frac_load: 1.0, shared_loop_watts: 635.3, fan_coil_watts: 150.0 }])
      end
      _check_heat_pump(hpxml)
      _check_thermostat(hpxml, control_type: HPXML::HVACControlTypeProgrammable)
      if [ESConstants.SFNationalVer3_0, ESConstants.SFPacificVer3_0, ESConstants.SFOregonWashingtonVer3_2].include? program_version
        return_duct_r = (program_version != ESConstants.SFOregonWashingtonVer3_2 ? 6.0 : 8.0)
        _check_ducts(hpxml, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 8.0, duct_area: 243.0, duct_location: HPXML::LocationAtticVented },
                             { duct_type: HPXML::DuctTypeReturn, duct_rvalue: return_duct_r, duct_area: 45.0, duct_location: HPXML::LocationAtticVented }])
      else
        _check_ducts(hpxml, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 0.0, duct_area: 243.0, duct_location: HPXML::LocationLivingSpace },
                             { duct_type: HPXML::DuctTypeReturn, duct_rvalue: 0.0, duct_area: 45.0, duct_location: HPXML::LocationLivingSpace }])
      end
      _check_duct_leakage(hpxml, [{ duct_type: HPXML::DuctTypeSupply, duct_leakage_units: HPXML::UnitsCFM25, duct_leakage_value: get_es_zerh_duct_leakage(program_version, 20.0), duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside },
                                  { duct_type: HPXML::DuctTypeReturn, duct_leakage_units: HPXML::UnitsCFM25, duct_leakage_value: get_es_zerh_duct_leakage(program_version, 20.0), duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside }])
    end
  end

  def test_shared_chiller_fan_coil_ducted
    hpxml_name = 'base-bldgtype-multifamily-shared-chiller-only-fan-coil.xml'
    [*ESConstants.AllVersions, *ZERHConstants.AllVersions].each do |program_version|
      _convert_to_es_zerh(hpxml_name, program_version)
      hpxml = _test_ruleset(program_version)
      _check_heating_system(hpxml)
      if [ESConstants.MFNationalVer1_2, ESConstants.SFNationalVer3_2].include? program_version
        _check_cooling_system(hpxml, [{ num_units_served: 6, systype: HPXML::HVACTypeChiller, fuel: HPXML::FuelTypeElectricity, kw_per_ton: 0.75, frac_load: 1.0, shared_loop_watts: 635.3, fan_coil_watts: 150.0 }])
      else
        _check_cooling_system(hpxml, [{ num_units_served: 6, systype: HPXML::HVACTypeChiller, fuel: HPXML::FuelTypeElectricity, kw_per_ton: 0.78, frac_load: 1.0, shared_loop_watts: 635.3, fan_coil_watts: 150.0 }])
      end
      _check_heat_pump(hpxml)
      _check_thermostat(hpxml, control_type: HPXML::HVACControlTypeProgrammable)
      if [ESConstants.SFNationalVer3_0, ESConstants.SFPacificVer3_0, ESConstants.SFOregonWashingtonVer3_2].include? program_version
        return_duct_r = (program_version != ESConstants.SFOregonWashingtonVer3_2 ? 6.0 : 8.0)
        _check_ducts(hpxml, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 8.0, duct_area: 243.0, duct_location: HPXML::LocationAtticVented },
                             { duct_type: HPXML::DuctTypeReturn, duct_rvalue: return_duct_r, duct_area: 45.0, duct_location: HPXML::LocationAtticVented }])
      else
        _check_ducts(hpxml, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 0.0, duct_area: 243.0, duct_location: HPXML::LocationLivingSpace },
                             { duct_type: HPXML::DuctTypeReturn, duct_rvalue: 0.0, duct_area: 45.0, duct_location: HPXML::LocationLivingSpace }])
      end
      _check_duct_leakage(hpxml, [{ duct_type: HPXML::DuctTypeSupply, duct_leakage_units: HPXML::UnitsCFM25, duct_leakage_value: get_es_zerh_duct_leakage(program_version, 20.0), duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside },
                                  { duct_type: HPXML::DuctTypeReturn, duct_leakage_units: HPXML::UnitsCFM25, duct_leakage_value: get_es_zerh_duct_leakage(program_version, 20.0), duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside }])
    end
  end

  def test_shared_chiller_water_loop_heat_pump
    hpxml_name = 'base-bldgtype-multifamily-shared-chiller-only-water-loop-heat-pump.xml'
    [*ESConstants.AllVersions, *ZERHConstants.AllVersions].each do |program_version|
      _convert_to_es_zerh(hpxml_name, program_version)
      hpxml = _test_ruleset(program_version)
      _check_heating_system(hpxml)
      if [ESConstants.MFNationalVer1_2, ESConstants.SFNationalVer3_2].include? program_version
        _check_cooling_system(hpxml, [{ num_units_served: 6, systype: HPXML::HVACTypeChiller, fuel: HPXML::FuelTypeElectricity, kw_per_ton: 0.75, frac_load: 1.0, shared_loop_watts: 635.3 }])
      else
        _check_cooling_system(hpxml, [{ num_units_served: 6, systype: HPXML::HVACTypeChiller, fuel: HPXML::FuelTypeElectricity, kw_per_ton: 0.78, frac_load: 1.0, shared_loop_watts: 635.3 }])
      end
      if [ESConstants.MFNationalVer1_2, ESConstants.SFNationalVer3_2].include? program_version
        _check_heat_pump(hpxml, [{ systype: HPXML::HVACTypeHeatPumpWaterLoopToAir, fuel: HPXML::FuelTypeElectricity, cop: 4.5, eer: 15, heating_capacity: 24000.0 }])
      else
        _check_heat_pump(hpxml, [{ systype: HPXML::HVACTypeHeatPumpWaterLoopToAir, fuel: HPXML::FuelTypeElectricity, cop: 4.2, eer: 14, heating_capacity: 24000.0 }])
      end
      _check_thermostat(hpxml, control_type: HPXML::HVACControlTypeProgrammable)
      if [ESConstants.SFNationalVer3_0, ESConstants.SFPacificVer3_0, ESConstants.SFOregonWashingtonVer3_2].include? program_version
        return_duct_r = (program_version != ESConstants.SFOregonWashingtonVer3_2 ? 6.0 : 8.0)
        _check_ducts(hpxml, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 8.0, duct_area: 243.0, duct_location: HPXML::LocationAtticVented },
                             { duct_type: HPXML::DuctTypeReturn, duct_rvalue: return_duct_r, duct_area: 45.0, duct_location: HPXML::LocationAtticVented }])
      else
        _check_ducts(hpxml, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 0.0, duct_area: 243.0, duct_location: HPXML::LocationLivingSpace },
                             { duct_type: HPXML::DuctTypeReturn, duct_rvalue: 0.0, duct_area: 45.0, duct_location: HPXML::LocationLivingSpace }])
      end
      _check_duct_leakage(hpxml, [{ duct_type: HPXML::DuctTypeSupply, duct_leakage_units: HPXML::UnitsCFM25, duct_leakage_value: get_es_zerh_duct_leakage(program_version, 20.0), duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside },
                                  { duct_type: HPXML::DuctTypeReturn, duct_leakage_units: HPXML::UnitsCFM25, duct_leakage_value: get_es_zerh_duct_leakage(program_version, 20.0), duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside }])
    end
  end

  def test_shared_cooling_tower_water_loop_heat_pump
    hpxml_name = 'base-bldgtype-multifamily-shared-cooling-tower-only-water-loop-heat-pump.xml'
    [*ESConstants.AllVersions, *ZERHConstants.AllVersions].each do |program_version|
      _convert_to_es_zerh(hpxml_name, program_version)
      hpxml = _test_ruleset(program_version)
      _check_heating_system(hpxml)
      _check_cooling_system(hpxml, [{ num_units_served: 6, systype: HPXML::HVACTypeCoolingTower, fuel: HPXML::FuelTypeElectricity, frac_load: 1.0, shared_loop_watts: 635.3 }])
      if [ESConstants.MFNationalVer1_2, ESConstants.SFNationalVer3_2].include? program_version
        _check_heat_pump(hpxml, [{ systype: HPXML::HVACTypeHeatPumpWaterLoopToAir, fuel: HPXML::FuelTypeElectricity, cop: 4.5, eer: 15, heating_capacity: 24000.0 }])
      else
        _check_heat_pump(hpxml, [{ systype: HPXML::HVACTypeHeatPumpWaterLoopToAir, fuel: HPXML::FuelTypeElectricity, cop: 4.2, eer: 14, heating_capacity: 24000.0 }])
      end
      _check_thermostat(hpxml, control_type: HPXML::HVACControlTypeProgrammable)
      if [ESConstants.SFNationalVer3_0, ESConstants.SFPacificVer3_0, ESConstants.SFOregonWashingtonVer3_2].include? program_version
        return_duct_r = (program_version != ESConstants.SFOregonWashingtonVer3_2 ? 6.0 : 8.0)
        _check_ducts(hpxml, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 8.0, duct_area: 243.0, duct_location: HPXML::LocationAtticVented },
                             { duct_type: HPXML::DuctTypeReturn, duct_rvalue: return_duct_r, duct_area: 45.0, duct_location: HPXML::LocationAtticVented }])
      else
        _check_ducts(hpxml, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 0.0, duct_area: 243.0, duct_location: HPXML::LocationLivingSpace },
                             { duct_type: HPXML::DuctTypeReturn, duct_rvalue: 0.0, duct_area: 45.0, duct_location: HPXML::LocationLivingSpace }])
      end
      _check_duct_leakage(hpxml, [{ duct_type: HPXML::DuctTypeSupply, duct_leakage_units: HPXML::UnitsCFM25, duct_leakage_value: get_es_zerh_duct_leakage(program_version, 20.0), duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside },
                                  { duct_type: HPXML::DuctTypeReturn, duct_leakage_units: HPXML::UnitsCFM25, duct_leakage_value: get_es_zerh_duct_leakage(program_version, 20.0), duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside }])
    end
  end

  def test_shared_ground_loop_ground_source
    hpxml_name = 'base-bldgtype-multifamily-shared-ground-loop-ground-to-air-heat-pump.xml'
    [*ESConstants.AllVersions, *ZERHConstants.AllVersions].each do |program_version|
      _convert_to_es_zerh(hpxml_name, program_version)
      hpxml = _test_ruleset(program_version)
      hvac_iq_values = get_default_hvac_iq_values(program_version)
      _check_heating_system(hpxml)
      _check_cooling_system(hpxml)
      if ESConstants.MFVersions.include? program_version
        _check_heat_pump(hpxml, [{ systype: HPXML::HVACTypeHeatPumpGroundToAir, fuel: HPXML::FuelTypeElectricity, num_units_served: 6, eer: get_es_zerh_gshp_eer_cz5(program_version), cop: get_es_zerh_gshp_cop_cz5(program_version), frac_load_heat: 1.0, frac_load_cool: 1.0, shr: 0.73, shared_loop_watts: 635.3, pump_w_per_ton: 30, is_shared_system: true, **hvac_iq_values }])
      else
        _check_heat_pump(hpxml, [{ systype: HPXML::HVACTypeHeatPumpAirToAir, fuel: HPXML::FuelTypeElectricity, hspf: get_es_zerh_ashp_hspf_cz5(program_version), seer: get_es_zerh_ashp_seer_cz5(program_version), frac_load_heat: 1.0, frac_load_cool: 1.0, backup_fuel: HPXML::FuelTypeElectricity, backup_eff: 1.0, shr: 0.73, **hvac_iq_values }])
      end
      _check_thermostat(hpxml, control_type: HPXML::HVACControlTypeProgrammable)
      if [ESConstants.SFNationalVer3_0, ESConstants.SFPacificVer3_0, ESConstants.SFOregonWashingtonVer3_2].include? program_version
        return_duct_r = (program_version != ESConstants.SFOregonWashingtonVer3_2 ? 6.0 : 8.0)
        _check_ducts(hpxml, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 8.0, duct_area: 243.0, duct_location: HPXML::LocationAtticVented },
                             { duct_type: HPXML::DuctTypeReturn, duct_rvalue: return_duct_r, duct_area: 45.0, duct_location: HPXML::LocationAtticVented }])
      else
        _check_ducts(hpxml, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 0.0, duct_area: 243.0, duct_location: HPXML::LocationLivingSpace },
                             { duct_type: HPXML::DuctTypeReturn, duct_rvalue: 0.0, duct_area: 45.0, duct_location: HPXML::LocationLivingSpace }])
      end
      _check_duct_leakage(hpxml, [{ duct_type: HPXML::DuctTypeSupply, duct_leakage_units: HPXML::UnitsCFM25, duct_leakage_value: get_es_zerh_duct_leakage(program_version, 20.0), duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside },
                                  { duct_type: HPXML::DuctTypeReturn, duct_leakage_units: HPXML::UnitsCFM25, duct_leakage_value: get_es_zerh_duct_leakage(program_version, 20.0), duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside }])

      next unless ESConstants.NationalVersions.include?(program_version)

      # Test in climate zone 7
      _convert_to_es_zerh(hpxml_name, program_version)
      hpxml = HPXML.new(hpxml_path: @tmp_hpxml_path)
      hpxml.climate_and_risk_zones.climate_zone_ieccs.each do |climate_zone_iecc|
        climate_zone_iecc.zone = '7'
      end
      hpxml.climate_and_risk_zones.weather_station_name = 'Duluth, MN'
      hpxml.climate_and_risk_zones.weather_station_wmo = 727450
      XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
      hpxml = _test_ruleset(program_version)
      hvac_iq_values = get_default_hvac_iq_values(program_version)
      _check_heating_system(hpxml)
      _check_cooling_system(hpxml)
      if ESConstants.MFVersions.include?(program_version) || [ESConstants.SFNationalVer3_0, ZERHConstants.Ver1].include?(program_version)
        _check_heat_pump(hpxml, [{ systype: HPXML::HVACTypeHeatPumpGroundToAir, fuel: HPXML::FuelTypeElectricity, num_units_served: 6, eer: get_es_zerh_gshp_eer_cz7(program_version), cop: get_es_zerh_gshp_cop_cz7(program_version), frac_load_heat: 1.0, frac_load_cool: 1.0, shr: 0.73, shared_loop_watts: 635.3, pump_w_per_ton: 30, is_shared_system: true, **hvac_iq_values }])
      else
        _check_heat_pump(hpxml, [{ systype: HPXML::HVACTypeHeatPumpAirToAir, fuel: HPXML::FuelTypeElectricity, hspf: get_es_zerh_ashp_hspf_cz7(program_version), seer: get_es_zerh_ashp_seer_cz7(program_version), frac_load_heat: 1.0, frac_load_cool: 1.0, backup_fuel: HPXML::FuelTypeElectricity, backup_eff: 1.0, shr: 0.73, **hvac_iq_values }])
      end
      _check_thermostat(hpxml, control_type: HPXML::HVACControlTypeProgrammable)
      if [ESConstants.SFNationalVer3_0, ESConstants.SFPacificVer3_0, ESConstants.SFOregonWashingtonVer3_2].include? program_version
        return_duct_r = (program_version != ESConstants.SFOregonWashingtonVer3_2 ? 6.0 : 8.0)
        _check_ducts(hpxml, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 8.0, duct_area: 243.0, duct_location: HPXML::LocationAtticVented },
                             { duct_type: HPXML::DuctTypeReturn, duct_rvalue: return_duct_r, duct_area: 45.0, duct_location: HPXML::LocationAtticVented }])
      else
        _check_ducts(hpxml, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 0.0, duct_area: 243.0, duct_location: HPXML::LocationLivingSpace },
                             { duct_type: HPXML::DuctTypeReturn, duct_rvalue: 0.0, duct_area: 45.0, duct_location: HPXML::LocationLivingSpace }])
      end
      _check_duct_leakage(hpxml, [{ duct_type: HPXML::DuctTypeSupply, duct_leakage_units: HPXML::UnitsCFM25, duct_leakage_value: get_es_zerh_duct_leakage(program_version, 20.0), duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside },
                                  { duct_type: HPXML::DuctTypeReturn, duct_leakage_units: HPXML::UnitsCFM25, duct_leakage_value: get_es_zerh_duct_leakage(program_version, 20.0), duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside }])
    end
  end

  def test_custom_setpoints
    [*ESConstants.AllVersions, *ZERHConstants.AllVersions].each do |program_version|
      _convert_to_es_zerh('base.xml', program_version)
      hpxml = HPXML.new(hpxml_path: @tmp_hpxml_path)
      hpxml.hvac_controls[0].heating_setpoint_temp = 60
      hpxml.hvac_controls[0].cooling_setpoint_temp = 80
      hpxml.hvac_controls[0].control_type = HPXML::HVACControlTypeManual
      XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
      hpxml = _test_ruleset(program_version)
      _check_thermostat(hpxml, control_type: HPXML::HVACControlTypeProgrammable)
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

  def _check_heating_system(hpxml, all_expected_values = [])
    assert_equal(all_expected_values.size, hpxml.heating_systems.size)
    hpxml.heating_systems.each_with_index do |heating_system, idx|
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

  def _check_heat_pump(hpxml, all_expected_values = [])
    assert_equal(all_expected_values.size, hpxml.heat_pumps.size)
    hpxml.heat_pumps.each_with_index do |heat_pump, idx|
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
        assert_equal(expected_values[:seer], heat_pump.cooling_efficiency_seer)
      else
        assert_nil(heat_pump.cooling_efficiency_seer)
      end
      if not expected_values[:eer].nil?
        assert_equal(expected_values[:eer], heat_pump.cooling_efficiency_eer)
      else
        assert_nil(heat_pump.cooling_efficiency_eer)
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
      if expected_values[:shr].nil?
        assert_nil(heat_pump.cooling_shr)
      else
        assert_equal(expected_values[:shr], heat_pump.cooling_shr)
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
      if expected_values[:backup_temp].nil?
        assert_nil(heat_pump.backup_heating_switchover_temp)
      else
        assert_equal(expected_values[:backup_temp], heat_pump.backup_heating_switchover_temp)
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

  def _check_cooling_system(hpxml, all_expected_values = [])
    assert_equal(all_expected_values.size, hpxml.cooling_systems.size)
    hpxml.cooling_systems.each_with_index do |cooling_system, idx|
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
        assert_in_epsilon(expected_values[:seer], cooling_system.cooling_efficiency_seer, 0.01)
      else
        assert_nil(cooling_system.cooling_efficiency_seer)
      end
      if not expected_values[:eer].nil?
        assert_equal(expected_values[:eer], cooling_system.cooling_efficiency_eer)
      else
        assert_nil(cooling_system.cooling_efficiency_eer)
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
      if expected_values[:shr].nil?
        assert_nil(cooling_system.cooling_shr)
      else
        assert_equal(expected_values[:shr], cooling_system.cooling_shr)
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

  def _check_thermostat(hpxml, control_type:, htg_sp: nil, clg_sp: nil, htg_setback: nil, htg_setback_hrs: nil, htg_setback_start_hr: nil,
                        clg_setup: nil, clg_setup_hrs: nil, clg_setup_start_hr: nil)
    assert_equal(1, hpxml.hvac_controls.size)
    hvac_control = hpxml.hvac_controls[0]
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

  def _check_duct_leakage(hpxml, duct_leakage_measurements = [])
    assert_equal(duct_leakage_measurements.size, hpxml.hvac_distributions.map { |x| x.duct_leakage_measurements.size }.inject(0, :+))
    idx = 0
    hpxml.hvac_distributions.each do |hvac_distribution|
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

  def _check_ducts(hpxml, ducts = [])
    assert_equal(ducts.size, hpxml.hvac_distributions.map { |x| x.ducts.size }.inject(0, :+))
    idx = 0
    hpxml.hvac_distributions.each do |hvac_distribution|
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

  def _convert_to_es_zerh(hpxml_name, program_version, state_code = nil)
    return convert_to_es_zerh(hpxml_name, program_version, @root_path, @tmp_hpxml_path, state_code)
  end
end
