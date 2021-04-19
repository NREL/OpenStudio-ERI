# frozen_string_literal: true

require_relative '../../../hpxml-measures/HPXMLtoOpenStudio/resources/minitest_helper'
require 'openstudio'
require 'openstudio/ruleset/ShowRunnerOutput'
require_relative '../measure.rb'
require 'fileutils'
require_relative 'util'

class EnergyStarHVACtest < MiniTest::Test
  def setup
    @root_path = File.absolute_path(File.join(File.dirname(__FILE__), '..', '..', '..'))
    @tmp_hpxml_path = File.join(@root_path, 'workflow', 'sample_files', 'tmp.xml')
  end

  def teardown
    File.delete(@tmp_hpxml_path) if File.exist? @tmp_hpxml_path
  end

  def get_es_duct_leakage(es_version, value_if_duct_location_not_living_space)
    if [ESConstants.SFNationalVer3_1, ESConstants.SFFloridaVer3_1, ESConstants.MFNationalVer1_1_2019].include? es_version
      return 0.0
    else
      return value_if_duct_location_not_living_space
    end
  end

  def get_es_central_ac_seer_cz5(es_version)
    if [ESConstants.SFPacificVer3].include? es_version
      return 14.5
    elsif [ESConstants.SFFloridaVer3_1].include? es_version
      return 15.0
    elsif [ESConstants.SFNationalVer3, ESConstants.SFNationalVer3_1, ESConstants.SFOregonWashingtonVer3_2, ESConstants.MFNationalVer1_2019, ESConstants.MFNationalVer1_1_2019, ESConstants.MFOregonWashingtonVer1_2_2019].include? es_version
      return 13.0
    end
  end

  def get_es_ashp_seer_cz5(es_version)
    if [ESConstants.SFNationalVer3_1, ESConstants.SFFloridaVer3_1, ESConstants.SFOregonWashingtonVer3_2, ESConstants.MFNationalVer1_1_2019, ESConstants.MFOregonWashingtonVer1_2_2019].include? es_version
      return 15.0
    elsif [ESConstants.SFPacificVer3, ESConstants.SFNationalVer3, ESConstants.MFNationalVer1_2019].include? es_version
      return 14.5
    end
  end

  def get_es_ashp_hspf_cz5(es_version)
    if [ESConstants.SFNationalVer3_1, ESConstants.SFNationalVer3, ESConstants.MFNationalVer1_2019, ESConstants.MFNationalVer1_1_2019].include? es_version
      return 9.25
    elsif [ESConstants.SFPacificVer3, ESConstants.SFFloridaVer3_1].include? es_version
      return 8.20
    elsif [ESConstants.SFOregonWashingtonVer3_2, ESConstants.MFOregonWashingtonVer1_2_2019].include? es_version
      return 9.50
    end
  end

  def get_es_gshp_cop_cz7(es_version)
    if [ESConstants.SFNationalVer3_1, ESConstants.MFNationalVer1_1_2019].include? es_version
      return 3.6
    elsif [ESConstants.SFNationalVer3, ESConstants.SFPacificVer3, ESConstants.SFFloridaVer3_1, ESConstants.SFOregonWashingtonVer3_2, ESConstants.MFNationalVer1_2019].include? es_version
      return 3.5
    elsif [ESConstants.MFOregonWashingtonVer1_2_2019].include? es_version
      return # Never applies
    end
  end

  def get_es_gshp_eer_cz7(es_version)
    if [ESConstants.SFNationalVer3_1, ESConstants.MFNationalVer1_1_2019].include? es_version
      return 17.1
    elsif [ESConstants.SFNationalVer3, ESConstants.SFPacificVer3, ESConstants.SFFloridaVer3_1, ESConstants.SFOregonWashingtonVer3_2, ESConstants.MFNationalVer1_2019].include? es_version
      return 16.1
    elsif [ESConstants.MFOregonWashingtonVer1_2_2019].include? es_version
      return # Never applies
    end
  end

  def get_es_gas_boiler_afue_cz5(es_version)
    if [ESConstants.SFNationalVer3_1, ESConstants.SFOregonWashingtonVer3_2, ESConstants.MFNationalVer1_1_2019, ESConstants.MFOregonWashingtonVer1_2_2019].include? es_version
      return 0.90
    elsif [ESConstants.SFPacificVer3, ESConstants.SFFloridaVer3_1].include? es_version
      return 0.80
    elsif [ESConstants.SFNationalVer3, ESConstants.MFNationalVer1_2019].include? es_version
      return 0.85
    end
  end

  def get_es_gas_furnace_afue_cz5(es_version)
    if [ESConstants.SFNationalVer3_1, ESConstants.SFOregonWashingtonVer3_2, ESConstants.MFNationalVer1_1_2019, ESConstants.MFOregonWashingtonVer1_2_2019].include? es_version
      return 0.95
    elsif [ESConstants.SFPacificVer3, ESConstants.SFFloridaVer3_1].include? es_version
      return 0.80
    elsif [ESConstants.SFNationalVer3, ESConstants.MFNationalVer1_2019].include? es_version
      return 0.90
    end
  end

  def get_es_oil_furnace_afue_cz5(es_version)
    if [ESConstants.SFNationalVer3_1, ESConstants.SFOregonWashingtonVer3_2, ESConstants.MFNationalVer1_1_2019, ESConstants.MFOregonWashingtonVer1_2_2019].include? es_version
      return 0.85
    elsif [ESConstants.SFPacificVer3, ESConstants.SFFloridaVer3_1].include? es_version
      return 0.80
    elsif [ESConstants.SFNationalVer3, ESConstants.MFNationalVer1_2019].include? es_version
      return 0.85
    end
  end

  def get_default_hvac_iq_values(es_version)
    # Grade 3 installation quality
    return { fan_watts_per_cfm: 0.58,
             airflow_defect_ratio: -0.25,
             charge_defect_ratio: -0.25 }
  end

  def test_none
    ESConstants.AllVersions.each do |es_version|
      _convert_to_es('base-hvac-none.xml', es_version)
      hpxml = _test_measure()
      _check_heating_system(hpxml)
      _check_cooling_system(hpxml)
      _check_heat_pump(hpxml)
      _check_thermostat(hpxml, control_type: HPXML::HVACControlTypeProgrammable)
      _check_ducts(hpxml)
      _check_duct_leakage(hpxml)
    end
  end

  def test_boiler_elec
    ESConstants.AllVersions.each do |es_version|
      _convert_to_es('base-hvac-boiler-elec-only.xml', es_version)
      hpxml = _test_measure()
      _check_heating_system(hpxml, [{ systype: HPXML::HVACTypeBoiler, fuel: HPXML::FuelTypeElectricity, eff: 0.98, frac_load: 1.0, eae: 170 }])
      _check_cooling_system(hpxml)
      _check_heat_pump(hpxml)
      _check_thermostat(hpxml, control_type: HPXML::HVACControlTypeProgrammable)
      _check_ducts(hpxml)
      _check_duct_leakage(hpxml)
    end
  end

  def test_boiler_gas
    ESConstants.AllVersions.each do |es_version|
      _convert_to_es('base-hvac-boiler-gas-only.xml', es_version)
      hpxml = _test_measure()
      _check_heating_system(hpxml, [{ systype: HPXML::HVACTypeBoiler, fuel: HPXML::FuelTypeNaturalGas, eff: get_es_gas_boiler_afue_cz5(es_version), frac_load: 1.0, eae: 170 }])
      _check_cooling_system(hpxml)
      _check_heat_pump(hpxml)
      _check_thermostat(hpxml, control_type: HPXML::HVACControlTypeProgrammable)
      _check_ducts(hpxml)
      _check_duct_leakage(hpxml)
    end
  end

  def test_furnace_elec
    ESConstants.AllVersions.each do |es_version|
      _convert_to_es('base-hvac-furnace-elec-only.xml', es_version)
      hpxml = _test_measure()
      hvac_iq_values = get_default_hvac_iq_values(es_version)
      _check_heating_system(hpxml)
      _check_cooling_system(hpxml)
      _check_heat_pump(hpxml, [{ systype: HPXML::HVACTypeHeatPumpAirToAir, fuel: HPXML::FuelTypeElectricity, comptype: HPXML::HVACCompressorTypeSingleStage, hspf: get_es_ashp_hspf_cz5(es_version), seer: get_es_ashp_seer_cz5(es_version), frac_load_heat: 1.0, frac_load_cool: 0.0, backup_fuel: HPXML::FuelTypeElectricity, shr: 0.73, backup_eff: 1.0, **hvac_iq_values }])
      _check_thermostat(hpxml, control_type: HPXML::HVACControlTypeProgrammable)
      if [ESConstants.SFNationalVer3, ESConstants.SFPacificVer3, ESConstants.SFOregonWashingtonVer3_2].include? es_version
        _check_ducts(hpxml, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 0.0, duct_area: 729.0, duct_location: HPXML::LocationBasementConditioned },
                             { duct_type: HPXML::DuctTypeReturn, duct_rvalue: 0.0, duct_area: 270.0, duct_location: HPXML::LocationBasementConditioned }])
      elsif [ESConstants.SFNationalVer3_1, ESConstants.SFFloridaVer3_1, ESConstants.MFNationalVer1_1_2019].include? es_version
        _check_ducts(hpxml, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 0.0, duct_area: 729.0, duct_location: HPXML::LocationLivingSpace },
                             { duct_type: HPXML::DuctTypeReturn, duct_rvalue: 0.0, duct_area: 270.0, duct_location: HPXML::LocationLivingSpace }])
      elsif [ESConstants.MFNationalVer1_2019, ESConstants.MFOregonWashingtonVer1_2_2019].include? es_version
        return_r = (es_version != ESConstants.MFOregonWashingtonVer1_2_2019 ? 6.0 : 8.0)
        _check_ducts(hpxml, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 8.0, duct_area: 729.0, duct_location: HPXML::LocationAtticVented },
                             { duct_type: HPXML::DuctTypeReturn, duct_rvalue: return_r, duct_area: 270.0, duct_location: HPXML::LocationAtticVented }])
      end
      _check_duct_leakage(hpxml, [{ duct_leakage_units: HPXML::UnitsCFM25, duct_leakage_value: get_es_duct_leakage(es_version, 54.0), duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside },
                                  { duct_leakage_units: HPXML::UnitsCFM25, duct_leakage_value: get_es_duct_leakage(es_version, 54.0), duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside }])
    end
  end

  def test_furnace_gas
    ESConstants.AllVersions.each do |es_version|
      _convert_to_es('base-hvac-furnace-gas-only.xml', es_version)
      hpxml = _test_measure()
      hvac_iq_values = get_default_hvac_iq_values(es_version)
      _check_heating_system(hpxml, [{ systype: HPXML::HVACTypeFurnace, fuel: HPXML::FuelTypeNaturalGas, eff: get_es_gas_furnace_afue_cz5(es_version), frac_load: 1.0, **hvac_iq_values }])
      _check_cooling_system(hpxml)
      _check_heat_pump(hpxml)
      _check_thermostat(hpxml, control_type: HPXML::HVACControlTypeProgrammable)
      if [ESConstants.SFNationalVer3, ESConstants.SFPacificVer3, ESConstants.SFOregonWashingtonVer3_2].include? es_version
        _check_ducts(hpxml, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 0.0, duct_area: 729.0, duct_location: HPXML::LocationBasementConditioned },
                             { duct_type: HPXML::DuctTypeReturn, duct_rvalue: 0.0, duct_area: 270.0, duct_location: HPXML::LocationBasementConditioned }])
      elsif [ESConstants.SFNationalVer3_1, ESConstants.SFFloridaVer3_1, ESConstants.MFNationalVer1_1_2019].include? es_version
        _check_ducts(hpxml, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 0.0, duct_area: 729.0, duct_location: HPXML::LocationLivingSpace },
                             { duct_type: HPXML::DuctTypeReturn, duct_rvalue: 0.0, duct_area: 270.0, duct_location: HPXML::LocationLivingSpace }])
      elsif [ESConstants.MFNationalVer1_2019, ESConstants.MFOregonWashingtonVer1_2_2019].include? es_version
        return_r = (es_version != ESConstants.MFOregonWashingtonVer1_2_2019 ? 6.0 : 8.0)
        _check_ducts(hpxml, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 8.0, duct_area: 729.0, duct_location: HPXML::LocationAtticVented },
                             { duct_type: HPXML::DuctTypeReturn, duct_rvalue: return_r, duct_area: 270.0, duct_location: HPXML::LocationAtticVented }])
      end
      _check_duct_leakage(hpxml, [{ duct_leakage_units: HPXML::UnitsCFM25, duct_leakage_value: get_es_duct_leakage(es_version, 54.0), duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside },
                                  { duct_leakage_units: HPXML::UnitsCFM25, duct_leakage_value: get_es_duct_leakage(es_version, 54.0), duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside }])
    end
  end

  def test_stove_wood_pellets
    ESConstants.AllVersions.each do |es_version|
      _convert_to_es('base-hvac-stove-wood-pellets-only.xml', es_version)
      hpxml = _test_measure()
      hvac_iq_values = get_default_hvac_iq_values(es_version)
      _check_heating_system(hpxml, [{ systype: HPXML::HVACTypeFurnace, fuel: HPXML::FuelTypeWoodPellets, eff: get_es_gas_furnace_afue_cz5(es_version), frac_load: 1.0, **hvac_iq_values }])
      _check_cooling_system(hpxml)
      _check_heat_pump(hpxml)
      _check_thermostat(hpxml, control_type: HPXML::HVACControlTypeProgrammable)
      if [ESConstants.SFNationalVer3, ESConstants.SFPacificVer3, ESConstants.SFOregonWashingtonVer3_2].include? es_version
        _check_ducts(hpxml, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 0.0, duct_area: 729.0, duct_location: HPXML::LocationBasementConditioned },
                             { duct_type: HPXML::DuctTypeReturn, duct_rvalue: 0.0, duct_area: 135.0, duct_location: HPXML::LocationBasementConditioned }])
      elsif [ESConstants.SFNationalVer3_1, ESConstants.SFFloridaVer3_1, ESConstants.MFNationalVer1_1_2019].include? es_version
        _check_ducts(hpxml, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 0.0, duct_area: 729.0, duct_location: HPXML::LocationLivingSpace },
                             { duct_type: HPXML::DuctTypeReturn, duct_rvalue: 0.0, duct_area: 135.0, duct_location: HPXML::LocationLivingSpace }])
      elsif [ESConstants.MFNationalVer1_2019, ESConstants.MFOregonWashingtonVer1_2_2019].include? es_version
        return_r = (es_version != ESConstants.MFOregonWashingtonVer1_2_2019 ? 6.0 : 8.0)
        _check_ducts(hpxml, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 8.0, duct_area: 729.0, duct_location: HPXML::LocationAtticVented },
                             { duct_type: HPXML::DuctTypeReturn, duct_rvalue: return_r, duct_area: 135.0, duct_location: HPXML::LocationAtticVented }])
      end
      _check_duct_leakage(hpxml, [{ duct_leakage_units: HPXML::UnitsCFM25, duct_leakage_value: get_es_duct_leakage(es_version, 54.0), duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside },
                                  { duct_leakage_units: HPXML::UnitsCFM25, duct_leakage_value: get_es_duct_leakage(es_version, 54.0), duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside }])
    end
  end

  def test_wall_furnace_elec
    ESConstants.AllVersions.each do |es_version|
      _convert_to_es('base-hvac-wall-furnace-elec-only.xml', es_version)
      hpxml = _test_measure()
      hvac_iq_values = get_default_hvac_iq_values(es_version)
      _check_heating_system(hpxml)
      _check_cooling_system(hpxml)
      _check_heat_pump(hpxml, [{ systype: HPXML::HVACTypeHeatPumpAirToAir, fuel: HPXML::FuelTypeElectricity, comptype: HPXML::HVACCompressorTypeSingleStage, hspf: get_es_ashp_hspf_cz5(es_version), seer: get_es_ashp_seer_cz5(es_version), frac_load_heat: 1.0, frac_load_cool: 0.0, backup_fuel: HPXML::FuelTypeElectricity, shr: 0.73, backup_eff: 1.0, **hvac_iq_values }])
      _check_thermostat(hpxml, control_type: HPXML::HVACControlTypeProgrammable)
      if [ESConstants.SFNationalVer3, ESConstants.SFPacificVer3, ESConstants.SFOregonWashingtonVer3_2].include? es_version
        _check_ducts(hpxml, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 0.0, duct_area: 729.0, duct_location: HPXML::LocationBasementConditioned },
                             { duct_type: HPXML::DuctTypeReturn, duct_rvalue: 0.0, duct_area: 135.0, duct_location: HPXML::LocationBasementConditioned }])
      elsif [ESConstants.SFNationalVer3_1, ESConstants.SFFloridaVer3_1, ESConstants.MFNationalVer1_1_2019].include? es_version
        _check_ducts(hpxml, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 0.0, duct_area: 729.0, duct_location: HPXML::LocationLivingSpace },
                             { duct_type: HPXML::DuctTypeReturn, duct_rvalue: 0.0, duct_area: 135.0, duct_location: HPXML::LocationLivingSpace }])
      elsif [ESConstants.MFNationalVer1_2019, ESConstants.MFOregonWashingtonVer1_2_2019].include? es_version
        return_r = (es_version != ESConstants.MFOregonWashingtonVer1_2_2019 ? 6.0 : 8.0)
        _check_ducts(hpxml, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 8.0, duct_area: 729.0, duct_location: HPXML::LocationAtticVented },
                             { duct_type: HPXML::DuctTypeReturn, duct_rvalue: return_r, duct_area: 135.0, duct_location: HPXML::LocationAtticVented }])
      end
      _check_duct_leakage(hpxml, [{ duct_leakage_units: HPXML::UnitsCFM25, duct_leakage_value: get_es_duct_leakage(es_version, 54.0), duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside },
                                  { duct_leakage_units: HPXML::UnitsCFM25, duct_leakage_value: get_es_duct_leakage(es_version, 54.0), duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside }])
    end
  end

  def test_elec_resistance
    ESConstants.AllVersions.each do |es_version|
      _convert_to_es('base-hvac-elec-resistance-only.xml', es_version)
      hpxml = _test_measure()
      hvac_iq_values = get_default_hvac_iq_values(es_version)
      _check_heating_system(hpxml)
      _check_cooling_system(hpxml)
      _check_heat_pump(hpxml, [{ systype: HPXML::HVACTypeHeatPumpAirToAir, fuel: HPXML::FuelTypeElectricity, comptype: HPXML::HVACCompressorTypeSingleStage, hspf: get_es_ashp_hspf_cz5(es_version), seer: get_es_ashp_seer_cz5(es_version), frac_load_heat: 1.0, frac_load_cool: 0.0, backup_fuel: HPXML::FuelTypeElectricity, shr: 0.73, backup_eff: 1.0, **hvac_iq_values }])
      _check_thermostat(hpxml, control_type: HPXML::HVACControlTypeProgrammable)
      if [ESConstants.SFNationalVer3, ESConstants.SFPacificVer3, ESConstants.SFOregonWashingtonVer3_2].include? es_version
        _check_ducts(hpxml, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 0.0, duct_area: 729.0, duct_location: HPXML::LocationBasementConditioned },
                             { duct_type: HPXML::DuctTypeReturn, duct_rvalue: 0.0, duct_area: 135.0, duct_location: HPXML::LocationBasementConditioned }])
      elsif [ESConstants.SFNationalVer3_1, ESConstants.SFFloridaVer3_1, ESConstants.MFNationalVer1_1_2019].include? es_version
        _check_ducts(hpxml, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 0.0, duct_area: 729.0, duct_location: HPXML::LocationLivingSpace },
                             { duct_type: HPXML::DuctTypeReturn, duct_rvalue: 0.0, duct_area: 135.0, duct_location: HPXML::LocationLivingSpace }])
      elsif [ESConstants.MFNationalVer1_2019, ESConstants.MFOregonWashingtonVer1_2_2019].include? es_version
        return_r = (es_version != ESConstants.MFOregonWashingtonVer1_2_2019 ? 6.0 : 8.0)
        _check_ducts(hpxml, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 8.0, duct_area: 729.0, duct_location: HPXML::LocationAtticVented },
                             { duct_type: HPXML::DuctTypeReturn, duct_rvalue: return_r, duct_area: 135.0, duct_location: HPXML::LocationAtticVented }])
      end
      _check_duct_leakage(hpxml, [{ duct_leakage_units: HPXML::UnitsCFM25, duct_leakage_value: get_es_duct_leakage(es_version, 54.0), duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside },
                                  { duct_leakage_units: HPXML::UnitsCFM25, duct_leakage_value: get_es_duct_leakage(es_version, 54.0), duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside }])

      next unless ESConstants.NationalVersions.include?(es_version)

      # Test in climate zone 7
      _convert_to_es('base-hvac-elec-resistance-only.xml', es_version)
      hpxml = HPXML.new(hpxml_path: @tmp_hpxml_path)
      hpxml.climate_and_risk_zones.iecc_zone = '7'
      hpxml.climate_and_risk_zones.weather_station_name = 'Duluth, MN'
      hpxml.climate_and_risk_zones.weather_station_wmo = 727450
      XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
      hpxml = _test_measure()
      hvac_iq_values = get_default_hvac_iq_values(es_version)
      _check_heating_system(hpxml)
      _check_cooling_system(hpxml)
      hvac_iq_values[:charge_defect_ratio] = 0 # FIXME: Temporary
      _check_heat_pump(hpxml, [{ systype: HPXML::HVACTypeHeatPumpGroundToAir, fuel: HPXML::FuelTypeElectricity, cop: get_es_gshp_cop_cz7(es_version), eer: get_es_gshp_eer_cz7(es_version), frac_load_heat: 1.0, frac_load_cool: 0.0, shr: 0.732, pump_w_per_ton: 30, **hvac_iq_values }])
      _check_thermostat(hpxml, control_type: HPXML::HVACControlTypeProgrammable)
      if [ESConstants.SFNationalVer3, ESConstants.SFPacificVer3, ESConstants.SFOregonWashingtonVer3_2].include? es_version
        _check_ducts(hpxml, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 0.0, duct_area: 729.0, duct_location: HPXML::LocationBasementConditioned },
                             { duct_type: HPXML::DuctTypeReturn, duct_rvalue: 0.0, duct_area: 135.0, duct_location: HPXML::LocationBasementConditioned }])
      elsif [ESConstants.SFNationalVer3_1, ESConstants.SFFloridaVer3_1, ESConstants.MFNationalVer1_1_2019].include? es_version
        _check_ducts(hpxml, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 0.0, duct_area: 729.0, duct_location: HPXML::LocationLivingSpace },
                             { duct_type: HPXML::DuctTypeReturn, duct_rvalue: 0.0, duct_area: 135.0, duct_location: HPXML::LocationLivingSpace }])
      elsif [ESConstants.MFNationalVer1_2019, ESConstants.MFOregonWashingtonVer1_2_2019].include? es_version
        return_r = (es_version != ESConstants.MFOregonWashingtonVer1_2_2019 ? 6.0 : 8.0)
        _check_ducts(hpxml, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 8.0, duct_area: 729.0, duct_location: HPXML::LocationAtticVented },
                             { duct_type: HPXML::DuctTypeReturn, duct_rvalue: return_r, duct_area: 135.0, duct_location: HPXML::LocationAtticVented }])
      end
      _check_duct_leakage(hpxml, [{ duct_leakage_units: HPXML::UnitsCFM25, duct_leakage_value: get_es_duct_leakage(es_version, 54.0), duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside },
                                  { duct_leakage_units: HPXML::UnitsCFM25, duct_leakage_value: get_es_duct_leakage(es_version, 54.0), duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside }])
    end
  end

  def test_air_source_heat_pump
    ESConstants.AllVersions.each do |es_version|
      _convert_to_es('base-hvac-air-to-air-heat-pump-1-speed.xml', es_version)
      hpxml = _test_measure()
      hvac_iq_values = get_default_hvac_iq_values(es_version)
      _check_heating_system(hpxml)
      _check_cooling_system(hpxml)
      _check_heat_pump(hpxml, [{ systype: HPXML::HVACTypeHeatPumpAirToAir, fuel: HPXML::FuelTypeElectricity, comptype: HPXML::HVACCompressorTypeSingleStage, hspf: get_es_ashp_hspf_cz5(es_version), seer: get_es_ashp_seer_cz5(es_version), frac_load_heat: 1.0, frac_load_cool: 1.0, backup_fuel: HPXML::FuelTypeElectricity, backup_eff: 1.0, shr: 0.73, **hvac_iq_values }])
      _check_thermostat(hpxml, control_type: HPXML::HVACControlTypeProgrammable)
      if [ESConstants.SFNationalVer3, ESConstants.SFPacificVer3, ESConstants.SFOregonWashingtonVer3_2].include? es_version
        _check_ducts(hpxml, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 0.0, duct_area: 729.0, duct_location: HPXML::LocationBasementConditioned },
                             { duct_type: HPXML::DuctTypeReturn, duct_rvalue: 0.0, duct_area: 270.0, duct_location: HPXML::LocationBasementConditioned }])
      elsif [ESConstants.SFNationalVer3_1, ESConstants.SFFloridaVer3_1, ESConstants.MFNationalVer1_1_2019].include? es_version
        _check_ducts(hpxml, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 0.0, duct_area: 729.0, duct_location: HPXML::LocationLivingSpace },
                             { duct_type: HPXML::DuctTypeReturn, duct_rvalue: 0.0, duct_area: 270.0, duct_location: HPXML::LocationLivingSpace }])
      elsif [ESConstants.MFNationalVer1_2019, ESConstants.MFOregonWashingtonVer1_2_2019].include? es_version
        return_r = (es_version != ESConstants.MFOregonWashingtonVer1_2_2019 ? 6.0 : 8.0)
        _check_ducts(hpxml, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 8.0, duct_area: 729.0, duct_location: HPXML::LocationAtticVented },
                             { duct_type: HPXML::DuctTypeReturn, duct_rvalue: return_r, duct_area: 270.0, duct_location: HPXML::LocationAtticVented }])
      end
      _check_duct_leakage(hpxml, [{ duct_leakage_units: HPXML::UnitsCFM25, duct_leakage_value: get_es_duct_leakage(es_version, 54.0), duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside },
                                  { duct_leakage_units: HPXML::UnitsCFM25, duct_leakage_value: get_es_duct_leakage(es_version, 54.0), duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside }])

      next unless ESConstants.NationalVersions.include?(es_version)

      # Test in climate zone 7
      _convert_to_es('base-hvac-air-to-air-heat-pump-1-speed.xml', es_version)
      hpxml = HPXML.new(hpxml_path: @tmp_hpxml_path)
      hpxml.climate_and_risk_zones.iecc_zone = '7'
      hpxml.climate_and_risk_zones.weather_station_name = 'Duluth, MN'
      hpxml.climate_and_risk_zones.weather_station_wmo = 727450
      XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
      hpxml = _test_measure()
      hvac_iq_values = get_default_hvac_iq_values(es_version)
      hvac_iq_values[:charge_defect_ratio] = 0 # FIXME: Temporary
      _check_heating_system(hpxml)
      _check_cooling_system(hpxml)
      _check_heat_pump(hpxml, [{ systype: HPXML::HVACTypeHeatPumpGroundToAir, fuel: HPXML::FuelTypeElectricity, cop: get_es_gshp_cop_cz7(es_version), eer: get_es_gshp_eer_cz7(es_version), frac_load_heat: 1.0, frac_load_cool: 1.0, shr: 0.73, pump_w_per_ton: 30, **hvac_iq_values }])
      _check_thermostat(hpxml, control_type: HPXML::HVACControlTypeProgrammable)
      if [ESConstants.SFNationalVer3, ESConstants.SFPacificVer3, ESConstants.SFOregonWashingtonVer3_2].include? es_version
        _check_ducts(hpxml, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 0.0, duct_area: 729.0, duct_location: HPXML::LocationBasementConditioned },
                             { duct_type: HPXML::DuctTypeReturn, duct_rvalue: 0.0, duct_area: 270.0, duct_location: HPXML::LocationBasementConditioned }])
      elsif [ESConstants.SFNationalVer3_1, ESConstants.SFFloridaVer3_1, ESConstants.MFNationalVer1_1_2019].include? es_version
        _check_ducts(hpxml, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 0.0, duct_area: 729.0, duct_location: HPXML::LocationLivingSpace },
                             { duct_type: HPXML::DuctTypeReturn, duct_rvalue: 0.0, duct_area: 270.0, duct_location: HPXML::LocationLivingSpace }])
      elsif [ESConstants.MFNationalVer1_2019, ESConstants.MFOregonWashingtonVer1_2_2019].include? es_version
        return_r = (es_version != ESConstants.MFOregonWashingtonVer1_2_2019 ? 6.0 : 8.0)
        _check_ducts(hpxml, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 8.0, duct_area: 729.0, duct_location: HPXML::LocationAtticVented },
                             { duct_type: HPXML::DuctTypeReturn, duct_rvalue: return_r, duct_area: 270.0, duct_location: HPXML::LocationAtticVented }])
      end
      _check_duct_leakage(hpxml, [{ duct_leakage_units: HPXML::UnitsCFM25, duct_leakage_value: get_es_duct_leakage(es_version, 54.0), duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside },
                                  { duct_leakage_units: HPXML::UnitsCFM25, duct_leakage_value: get_es_duct_leakage(es_version, 54.0), duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside }])
    end
  end

  def test_mini_split_heat_pump_ducted
    ESConstants.AllVersions.each do |es_version|
      _convert_to_es('base-hvac-mini-split-heat-pump-ducted.xml', es_version)
      hpxml = _test_measure()
      hvac_iq_values = get_default_hvac_iq_values(es_version)
      _check_heating_system(hpxml)
      _check_cooling_system(hpxml)
      _check_heat_pump(hpxml, [{ systype: HPXML::HVACTypeHeatPumpAirToAir, fuel: HPXML::FuelTypeElectricity, comptype: HPXML::HVACCompressorTypeSingleStage, hspf: get_es_ashp_hspf_cz5(es_version), seer: get_es_ashp_seer_cz5(es_version), frac_load_heat: 1.0, frac_load_cool: 1.0, backup_fuel: HPXML::FuelTypeElectricity, backup_eff: 1.0, shr: 0.73, **hvac_iq_values }])
      _check_thermostat(hpxml, control_type: HPXML::HVACControlTypeProgrammable)
      if [ESConstants.SFNationalVer3, ESConstants.SFPacificVer3, ESConstants.SFOregonWashingtonVer3_2].include? es_version
        _check_ducts(hpxml, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 0.0, duct_area: 729.0, duct_location: HPXML::LocationBasementConditioned },
                             { duct_type: HPXML::DuctTypeReturn, duct_rvalue: 0.0, duct_area: 270.0, duct_location: HPXML::LocationBasementConditioned }])
      elsif [ESConstants.SFNationalVer3_1, ESConstants.SFFloridaVer3_1, ESConstants.MFNationalVer1_1_2019].include? es_version
        _check_ducts(hpxml, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 0.0, duct_area: 729.0, duct_location: HPXML::LocationLivingSpace },
                             { duct_type: HPXML::DuctTypeReturn, duct_rvalue: 0.0, duct_area: 270.0, duct_location: HPXML::LocationLivingSpace }])
      elsif [ESConstants.MFNationalVer1_2019, ESConstants.MFOregonWashingtonVer1_2_2019].include? es_version
        return_r = (es_version != ESConstants.MFOregonWashingtonVer1_2_2019 ? 6.0 : 8.0)
        _check_ducts(hpxml, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 8.0, duct_area: 729.0, duct_location: HPXML::LocationAtticVented },
                             { duct_type: HPXML::DuctTypeReturn, duct_rvalue: return_r, duct_area: 270.0, duct_location: HPXML::LocationAtticVented }])
      end
      _check_duct_leakage(hpxml, [{ duct_leakage_units: HPXML::UnitsCFM25, duct_leakage_value: get_es_duct_leakage(es_version, 54.0), duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside },
                                  { duct_leakage_units: HPXML::UnitsCFM25, duct_leakage_value: get_es_duct_leakage(es_version, 54.0), duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside }])
    end
  end

  def test_mini_split_heat_pump_ductless
    ESConstants.AllVersions.each do |es_version|
      _convert_to_es('base-hvac-mini-split-heat-pump-ductless.xml', es_version)
      hpxml = _test_measure()
      hvac_iq_values = get_default_hvac_iq_values(es_version)
      _check_heating_system(hpxml)
      _check_cooling_system(hpxml)
      _check_heat_pump(hpxml, [{ systype: HPXML::HVACTypeHeatPumpAirToAir, fuel: HPXML::FuelTypeElectricity, comptype: HPXML::HVACCompressorTypeSingleStage, hspf: get_es_ashp_hspf_cz5(es_version), seer: get_es_ashp_seer_cz5(es_version), frac_load_heat: 1.0, frac_load_cool: 1.0, backup_fuel: HPXML::FuelTypeElectricity, backup_eff: 1.0, shr: 0.73, **hvac_iq_values }])
      _check_thermostat(hpxml, control_type: HPXML::HVACControlTypeProgrammable)
      if [ESConstants.SFNationalVer3, ESConstants.SFPacificVer3, ESConstants.SFOregonWashingtonVer3_2].include? es_version
        _check_ducts(hpxml, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 0.0, duct_area: 729.0, duct_location: HPXML::LocationBasementConditioned },
                             { duct_type: HPXML::DuctTypeReturn, duct_rvalue: 0.0, duct_area: 135.0, duct_location: HPXML::LocationBasementConditioned }])
      elsif [ESConstants.SFNationalVer3_1, ESConstants.SFFloridaVer3_1, ESConstants.MFNationalVer1_1_2019].include? es_version
        _check_ducts(hpxml, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 0.0, duct_area: 729.0, duct_location: HPXML::LocationLivingSpace },
                             { duct_type: HPXML::DuctTypeReturn, duct_rvalue: 0.0, duct_area: 135.0, duct_location: HPXML::LocationLivingSpace }])
      elsif [ESConstants.MFNationalVer1_2019, ESConstants.MFOregonWashingtonVer1_2_2019].include? es_version
        return_r = (es_version != ESConstants.MFOregonWashingtonVer1_2_2019 ? 6.0 : 8.0)
        _check_ducts(hpxml, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 8.0, duct_area: 729.0, duct_location: HPXML::LocationAtticVented },
                             { duct_type: HPXML::DuctTypeReturn, duct_rvalue: return_r, duct_area: 135.0, duct_location: HPXML::LocationAtticVented }])
      end
      _check_duct_leakage(hpxml, [{ duct_leakage_units: HPXML::UnitsCFM25, duct_leakage_value: get_es_duct_leakage(es_version, 54.0), duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside },
                                  { duct_leakage_units: HPXML::UnitsCFM25, duct_leakage_value: get_es_duct_leakage(es_version, 54.0), duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside }])
    end
  end

  def test_ground_source_heat_pump
    ESConstants.AllVersions.each do |es_version|
      _convert_to_es('base-hvac-ground-to-air-heat-pump.xml', es_version)
      hpxml = _test_measure()
      hvac_iq_values = get_default_hvac_iq_values(es_version)
      _check_heating_system(hpxml)
      _check_cooling_system(hpxml)
      _check_heat_pump(hpxml, [{ systype: HPXML::HVACTypeHeatPumpAirToAir, fuel: HPXML::FuelTypeElectricity, comptype: HPXML::HVACCompressorTypeSingleStage, hspf: get_es_ashp_hspf_cz5(es_version), seer: get_es_ashp_seer_cz5(es_version), frac_load_heat: 1.0, frac_load_cool: 1.0, backup_fuel: HPXML::FuelTypeElectricity, backup_eff: 1.0, shr: 0.73, **hvac_iq_values }])
      _check_thermostat(hpxml, control_type: HPXML::HVACControlTypeProgrammable)
      if [ESConstants.SFNationalVer3, ESConstants.SFPacificVer3, ESConstants.SFOregonWashingtonVer3_2].include? es_version
        _check_ducts(hpxml, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 0.0, duct_area: 729.0, duct_location: HPXML::LocationBasementConditioned },
                             { duct_type: HPXML::DuctTypeReturn, duct_rvalue: 0.0, duct_area: 270.0, duct_location: HPXML::LocationBasementConditioned }])
      elsif [ESConstants.SFNationalVer3_1, ESConstants.SFFloridaVer3_1, ESConstants.MFNationalVer1_1_2019].include? es_version
        _check_ducts(hpxml, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 0.0, duct_area: 729.0, duct_location: HPXML::LocationLivingSpace },
                             { duct_type: HPXML::DuctTypeReturn, duct_rvalue: 0.0, duct_area: 270.0, duct_location: HPXML::LocationLivingSpace }])
      elsif [ESConstants.MFNationalVer1_2019, ESConstants.MFOregonWashingtonVer1_2_2019].include? es_version
        return_r = (es_version != ESConstants.MFOregonWashingtonVer1_2_2019 ? 6.0 : 8.0)
        _check_ducts(hpxml, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 8.0, duct_area: 729.0, duct_location: HPXML::LocationAtticVented },
                             { duct_type: HPXML::DuctTypeReturn, duct_rvalue: return_r, duct_area: 270.0, duct_location: HPXML::LocationAtticVented }])
      end
      _check_duct_leakage(hpxml, [{ duct_leakage_units: HPXML::UnitsCFM25, duct_leakage_value: get_es_duct_leakage(es_version, 54.0), duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside },
                                  { duct_leakage_units: HPXML::UnitsCFM25, duct_leakage_value: get_es_duct_leakage(es_version, 54.0), duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside }])

      next unless ESConstants.NationalVersions.include?(es_version)

      # Test in climate zone 7
      _convert_to_es('base-hvac-ground-to-air-heat-pump.xml', es_version)
      hpxml = HPXML.new(hpxml_path: @tmp_hpxml_path)
      hpxml.climate_and_risk_zones.iecc_zone = '7'
      hpxml.climate_and_risk_zones.weather_station_name = 'Duluth, MN'
      hpxml.climate_and_risk_zones.weather_station_wmo = 727450
      XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
      hpxml = _test_measure()
      hvac_iq_values = get_default_hvac_iq_values(es_version)
      hvac_iq_values[:charge_defect_ratio] = 0 # FIXME: Temporary
      _check_heating_system(hpxml)
      _check_cooling_system(hpxml)
      _check_heat_pump(hpxml, [{ systype: HPXML::HVACTypeHeatPumpGroundToAir, fuel: HPXML::FuelTypeElectricity, cop: get_es_gshp_cop_cz7(es_version), eer: get_es_gshp_eer_cz7(es_version), frac_load_heat: 1.0, frac_load_cool: 1.0, shr: 0.73, pump_w_per_ton: 30, **hvac_iq_values }])
      _check_thermostat(hpxml, control_type: HPXML::HVACControlTypeProgrammable)
      if [ESConstants.SFNationalVer3, ESConstants.SFPacificVer3, ESConstants.SFOregonWashingtonVer3_2].include? es_version
        _check_ducts(hpxml, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 0.0, duct_area: 729.0, duct_location: HPXML::LocationBasementConditioned },
                             { duct_type: HPXML::DuctTypeReturn, duct_rvalue: 0.0, duct_area: 270.0, duct_location: HPXML::LocationBasementConditioned }])
      elsif [ESConstants.SFNationalVer3_1, ESConstants.SFFloridaVer3_1, ESConstants.MFNationalVer1_1_2019].include? es_version
        _check_ducts(hpxml, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 0.0, duct_area: 729.0, duct_location: HPXML::LocationLivingSpace },
                             { duct_type: HPXML::DuctTypeReturn, duct_rvalue: 0.0, duct_area: 270.0, duct_location: HPXML::LocationLivingSpace }])
      elsif [ESConstants.MFNationalVer1_2019, ESConstants.MFOregonWashingtonVer1_2_2019].include? es_version
        return_r = (es_version != ESConstants.MFOregonWashingtonVer1_2_2019 ? 6.0 : 8.0)
        _check_ducts(hpxml, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 8.0, duct_area: 729.0, duct_location: HPXML::LocationAtticVented },
                             { duct_type: HPXML::DuctTypeReturn, duct_rvalue: return_r, duct_area: 270.0, duct_location: HPXML::LocationAtticVented }])
      end
      _check_duct_leakage(hpxml, [{ duct_leakage_units: HPXML::UnitsCFM25, duct_leakage_value: get_es_duct_leakage(es_version, 54.0), duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside },
                                  { duct_leakage_units: HPXML::UnitsCFM25, duct_leakage_value: get_es_duct_leakage(es_version, 54.0), duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside }])
    end
  end

  def test_dual_fuel_heat_pump_gas
    ESConstants.AllVersions.each do |es_version|
      _convert_to_es('base-hvac-dual-fuel-air-to-air-heat-pump-1-speed.xml', es_version)
      hpxml = _test_measure()
      hvac_iq_values = get_default_hvac_iq_values(es_version)
      _check_heating_system(hpxml)
      _check_cooling_system(hpxml)
      _check_heat_pump(hpxml, [{ systype: HPXML::HVACTypeHeatPumpAirToAir, fuel: HPXML::FuelTypeElectricity, comptype: HPXML::HVACCompressorTypeSingleStage, hspf: get_es_ashp_hspf_cz5(es_version), seer: get_es_ashp_seer_cz5(es_version), frac_load_heat: 1.0, frac_load_cool: 1.0, backup_fuel: HPXML::FuelTypeElectricity, backup_eff: 1.0, shr: 0.73, **hvac_iq_values }])
      _check_thermostat(hpxml, control_type: HPXML::HVACControlTypeProgrammable)
      if [ESConstants.SFNationalVer3, ESConstants.SFPacificVer3, ESConstants.SFOregonWashingtonVer3_2].include? es_version
        _check_ducts(hpxml, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 0.0, duct_area: 729.0, duct_location: HPXML::LocationBasementConditioned },
                             { duct_type: HPXML::DuctTypeReturn, duct_rvalue: 0.0, duct_area: 270.0, duct_location: HPXML::LocationBasementConditioned }])
      elsif [ESConstants.SFNationalVer3_1, ESConstants.SFFloridaVer3_1, ESConstants.MFNationalVer1_1_2019].include? es_version
        _check_ducts(hpxml, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 0.0, duct_area: 729.0, duct_location: HPXML::LocationLivingSpace },
                             { duct_type: HPXML::DuctTypeReturn, duct_rvalue: 0.0, duct_area: 270.0, duct_location: HPXML::LocationLivingSpace }])
      elsif [ESConstants.MFNationalVer1_2019, ESConstants.MFOregonWashingtonVer1_2_2019].include? es_version
        return_r = (es_version != ESConstants.MFOregonWashingtonVer1_2_2019 ? 6.0 : 8.0)
        _check_ducts(hpxml, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 8.0, duct_area: 729.0, duct_location: HPXML::LocationAtticVented },
                             { duct_type: HPXML::DuctTypeReturn, duct_rvalue: return_r, duct_area: 270.0, duct_location: HPXML::LocationAtticVented }])
      end
      _check_duct_leakage(hpxml, [{ duct_leakage_units: HPXML::UnitsCFM25, duct_leakage_value: get_es_duct_leakage(es_version, 54.0), duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside },
                                  { duct_leakage_units: HPXML::UnitsCFM25, duct_leakage_value: get_es_duct_leakage(es_version, 54.0), duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside }])
    end
  end

  def test_dual_fuel_heat_pump_elec
    ESConstants.AllVersions.each do |es_version|
      _convert_to_es('base-hvac-dual-fuel-air-to-air-heat-pump-1-speed-electric.xml', es_version)
      hpxml = _test_measure()
      hvac_iq_values = get_default_hvac_iq_values(es_version)
      _check_heating_system(hpxml)
      _check_cooling_system(hpxml)
      _check_heat_pump(hpxml, [{ systype: HPXML::HVACTypeHeatPumpAirToAir, fuel: HPXML::FuelTypeElectricity, comptype: HPXML::HVACCompressorTypeSingleStage, hspf: get_es_ashp_hspf_cz5(es_version), seer: get_es_ashp_seer_cz5(es_version), frac_load_heat: 1.0, frac_load_cool: 1.0, backup_fuel: HPXML::FuelTypeElectricity, backup_eff: 1.0, shr: 0.73, **hvac_iq_values }])
      _check_thermostat(hpxml, control_type: HPXML::HVACControlTypeProgrammable)
      if [ESConstants.SFNationalVer3, ESConstants.SFPacificVer3, ESConstants.SFOregonWashingtonVer3_2].include? es_version
        _check_ducts(hpxml, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 0.0, duct_area: 729.0, duct_location: HPXML::LocationBasementConditioned },
                             { duct_type: HPXML::DuctTypeReturn, duct_rvalue: 0.0, duct_area: 270.0, duct_location: HPXML::LocationBasementConditioned }])
      elsif [ESConstants.SFNationalVer3_1, ESConstants.SFFloridaVer3_1, ESConstants.MFNationalVer1_1_2019].include? es_version
        _check_ducts(hpxml, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 0.0, duct_area: 729.0, duct_location: HPXML::LocationLivingSpace },
                             { duct_type: HPXML::DuctTypeReturn, duct_rvalue: 0.0, duct_area: 270.0, duct_location: HPXML::LocationLivingSpace }])
      elsif [ESConstants.MFNationalVer1_2019, ESConstants.MFOregonWashingtonVer1_2_2019].include? es_version
        return_r = (es_version != ESConstants.MFOregonWashingtonVer1_2_2019 ? 6.0 : 8.0)
        _check_ducts(hpxml, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 8.0, duct_area: 729.0, duct_location: HPXML::LocationAtticVented },
                             { duct_type: HPXML::DuctTypeReturn, duct_rvalue: return_r, duct_area: 270.0, duct_location: HPXML::LocationAtticVented }])
      end
      _check_duct_leakage(hpxml, [{ duct_leakage_units: HPXML::UnitsCFM25, duct_leakage_value: get_es_duct_leakage(es_version, 54.0), duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside },
                                  { duct_leakage_units: HPXML::UnitsCFM25, duct_leakage_value: get_es_duct_leakage(es_version, 54.0), duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside }])
    end
  end

  def test_central_air_conditioner
    ESConstants.AllVersions.each do |es_version|
      _convert_to_es('base-hvac-central-ac-only-1-speed.xml', es_version)
      hpxml = _test_measure()
      hvac_iq_values = get_default_hvac_iq_values(es_version)
      _check_heating_system(hpxml)
      _check_cooling_system(hpxml, [{ systype: HPXML::HVACTypeCentralAirConditioner, fuel: HPXML::FuelTypeElectricity, comptype: HPXML::HVACCompressorTypeSingleStage, seer: get_es_central_ac_seer_cz5(es_version), frac_load: 1.0, shr: 0.73, **hvac_iq_values }])
      _check_heat_pump(hpxml)
      _check_thermostat(hpxml, control_type: HPXML::HVACControlTypeProgrammable)
      if [ESConstants.SFNationalVer3, ESConstants.SFPacificVer3, ESConstants.SFOregonWashingtonVer3_2].include? es_version
        _check_ducts(hpxml, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 0.0, duct_area: 729.0, duct_location: HPXML::LocationBasementConditioned },
                             { duct_type: HPXML::DuctTypeReturn, duct_rvalue: 0.0, duct_area: 270.0, duct_location: HPXML::LocationBasementConditioned }])
      elsif [ESConstants.SFNationalVer3_1, ESConstants.SFFloridaVer3_1, ESConstants.MFNationalVer1_1_2019].include? es_version
        _check_ducts(hpxml, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 0.0, duct_area: 729.0, duct_location: HPXML::LocationLivingSpace },
                             { duct_type: HPXML::DuctTypeReturn, duct_rvalue: 0.0, duct_area: 270.0, duct_location: HPXML::LocationLivingSpace }])
      elsif [ESConstants.MFNationalVer1_2019, ESConstants.MFOregonWashingtonVer1_2_2019].include? es_version
        return_r = (es_version != ESConstants.MFOregonWashingtonVer1_2_2019 ? 6.0 : 8.0)
        _check_ducts(hpxml, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 8.0, duct_area: 729.0, duct_location: HPXML::LocationAtticVented },
                             { duct_type: HPXML::DuctTypeReturn, duct_rvalue: return_r, duct_area: 270.0, duct_location: HPXML::LocationAtticVented }])
      end
      _check_duct_leakage(hpxml, [{ duct_leakage_units: HPXML::UnitsCFM25, duct_leakage_value: get_es_duct_leakage(es_version, 54.0), duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside },
                                  { duct_leakage_units: HPXML::UnitsCFM25, duct_leakage_value: get_es_duct_leakage(es_version, 54.0), duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside }])
    end
  end

  def test_room_air_conditioner
    ESConstants.AllVersions.each do |es_version|
      _convert_to_es('base-hvac-room-ac-only.xml', es_version)
      hpxml = _test_measure()
      hvac_iq_values = get_default_hvac_iq_values(es_version)
      _check_heating_system(hpxml)
      _check_cooling_system(hpxml, [{ systype: HPXML::HVACTypeCentralAirConditioner, fuel: HPXML::FuelTypeElectricity, comptype: HPXML::HVACCompressorTypeSingleStage, seer: get_es_central_ac_seer_cz5(es_version), frac_load: 1.0, shr: 0.65, **hvac_iq_values }])
      _check_heat_pump(hpxml)
      _check_thermostat(hpxml, control_type: HPXML::HVACControlTypeProgrammable)
      if [ESConstants.SFNationalVer3, ESConstants.SFPacificVer3, ESConstants.SFOregonWashingtonVer3_2].include? es_version
        _check_ducts(hpxml, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 0.0, duct_area: 729.0, duct_location: HPXML::LocationBasementConditioned },
                             { duct_type: HPXML::DuctTypeReturn, duct_rvalue: 0.0, duct_area: 135.0, duct_location: HPXML::LocationBasementConditioned }])
      elsif [ESConstants.SFNationalVer3_1, ESConstants.SFFloridaVer3_1, ESConstants.MFNationalVer1_1_2019].include? es_version
        _check_ducts(hpxml, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 0.0, duct_area: 729.0, duct_location: HPXML::LocationLivingSpace },
                             { duct_type: HPXML::DuctTypeReturn, duct_rvalue: 0.0, duct_area: 135.0, duct_location: HPXML::LocationLivingSpace }])
      elsif [ESConstants.MFNationalVer1_2019, ESConstants.MFOregonWashingtonVer1_2_2019].include? es_version
        return_r = (es_version != ESConstants.MFOregonWashingtonVer1_2_2019 ? 6.0 : 8.0)
        _check_ducts(hpxml, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 8.0, duct_area: 729.0, duct_location: HPXML::LocationAtticVented },
                             { duct_type: HPXML::DuctTypeReturn, duct_rvalue: return_r, duct_area: 135.0, duct_location: HPXML::LocationAtticVented }])
      end
      _check_duct_leakage(hpxml, [{ duct_leakage_units: HPXML::UnitsCFM25, duct_leakage_value: get_es_duct_leakage(es_version, 54.0), duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside },
                                  { duct_leakage_units: HPXML::UnitsCFM25, duct_leakage_value: get_es_duct_leakage(es_version, 54.0), duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside }])
    end
  end

  def test_evaporative_cooler
    ESConstants.AllVersions.each do |es_version|
      _convert_to_es('base-hvac-evap-cooler-only.xml', es_version)
      hpxml = _test_measure()
      hvac_iq_values = get_default_hvac_iq_values(es_version)
      _check_heating_system(hpxml)
      _check_cooling_system(hpxml, [{ systype: HPXML::HVACTypeCentralAirConditioner, fuel: HPXML::FuelTypeElectricity, comptype: HPXML::HVACCompressorTypeSingleStage, seer: get_es_central_ac_seer_cz5(es_version), frac_load: 1.0, shr: 0.73, **hvac_iq_values }])
      _check_heat_pump(hpxml)
      _check_thermostat(hpxml, control_type: HPXML::HVACControlTypeProgrammable)
      if [ESConstants.SFNationalVer3, ESConstants.SFPacificVer3, ESConstants.SFOregonWashingtonVer3_2].include? es_version
        _check_ducts(hpxml, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 0.0, duct_area: 729.0, duct_location: HPXML::LocationBasementConditioned },
                             { duct_type: HPXML::DuctTypeReturn, duct_rvalue: 0.0, duct_area: 135.0, duct_location: HPXML::LocationBasementConditioned }])
      elsif [ESConstants.SFNationalVer3_1, ESConstants.SFFloridaVer3_1, ESConstants.MFNationalVer1_1_2019].include? es_version
        _check_ducts(hpxml, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 0.0, duct_area: 729.0, duct_location: HPXML::LocationLivingSpace },
                             { duct_type: HPXML::DuctTypeReturn, duct_rvalue: 0.0, duct_area: 135.0, duct_location: HPXML::LocationLivingSpace }])
      elsif [ESConstants.MFNationalVer1_2019, ESConstants.MFOregonWashingtonVer1_2_2019].include? es_version
        return_r = (es_version != ESConstants.MFOregonWashingtonVer1_2_2019 ? 6.0 : 8.0)
        _check_ducts(hpxml, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 8.0, duct_area: 729.0, duct_location: HPXML::LocationAtticVented },
                             { duct_type: HPXML::DuctTypeReturn, duct_rvalue: return_r, duct_area: 135.0, duct_location: HPXML::LocationAtticVented }])
      end
      _check_duct_leakage(hpxml, [{ duct_leakage_units: HPXML::UnitsCFM25, duct_leakage_value: get_es_duct_leakage(es_version, 54.0), duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside },
                                  { duct_leakage_units: HPXML::UnitsCFM25, duct_leakage_value: get_es_duct_leakage(es_version, 54.0), duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside }])
    end
  end

  def test_mini_split_air_conditioner_ducted
    ESConstants.AllVersions.each do |es_version|
      hpxml_files = ['base-hvac-mini-split-air-conditioner-only-ducted.xml',
                     'base-hvac-install-quality-all-mini-split-air-conditioner-only-ducted.xml']
      hpxml_files.each do |hpxml_file|
        _convert_to_es(hpxml_file, es_version)
        hpxml = _test_measure()
        hvac_iq_values = get_default_hvac_iq_values(es_version)
        _check_heating_system(hpxml)
        _check_cooling_system(hpxml, [{ systype: HPXML::HVACTypeCentralAirConditioner, fuel: HPXML::FuelTypeElectricity, comptype: HPXML::HVACCompressorTypeSingleStage, seer: get_es_central_ac_seer_cz5(es_version), frac_load: 1.0, shr: 0.73, **hvac_iq_values }])
        _check_heat_pump(hpxml)
        _check_thermostat(hpxml, control_type: HPXML::HVACControlTypeProgrammable)
        if [ESConstants.SFNationalVer3, ESConstants.SFPacificVer3, ESConstants.SFOregonWashingtonVer3_2].include? es_version
          _check_ducts(hpxml, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 0.0, duct_area: 729.0, duct_location: HPXML::LocationBasementConditioned },
                               { duct_type: HPXML::DuctTypeReturn, duct_rvalue: 0.0, duct_area: 270.0, duct_location: HPXML::LocationBasementConditioned }])
        elsif [ESConstants.SFNationalVer3_1, ESConstants.SFFloridaVer3_1, ESConstants.MFNationalVer1_1_2019].include? es_version
          _check_ducts(hpxml, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 0.0, duct_area: 729.0, duct_location: HPXML::LocationLivingSpace },
                               { duct_type: HPXML::DuctTypeReturn, duct_rvalue: 0.0, duct_area: 270.0, duct_location: HPXML::LocationLivingSpace }])
        elsif [ESConstants.MFNationalVer1_2019, ESConstants.MFOregonWashingtonVer1_2_2019].include? es_version
          return_r = (es_version != ESConstants.MFOregonWashingtonVer1_2_2019 ? 6.0 : 8.0)
          _check_ducts(hpxml, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 8.0, duct_area: 729.0, duct_location: HPXML::LocationAtticVented },
                               { duct_type: HPXML::DuctTypeReturn, duct_rvalue: return_r, duct_area: 270.0, duct_location: HPXML::LocationAtticVented }])
        end
        _check_duct_leakage(hpxml, [{ duct_leakage_units: HPXML::UnitsCFM25, duct_leakage_value: get_es_duct_leakage(es_version, 54.0), duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside },
                                    { duct_leakage_units: HPXML::UnitsCFM25, duct_leakage_value: get_es_duct_leakage(es_version, 54.0), duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside }])
      end
    end
  end

  def test_mini_split_air_conditioner_ductless
    ESConstants.AllVersions.each do |es_version|
      _convert_to_es('base-hvac-mini-split-air-conditioner-only-ductless.xml', es_version)
      hpxml = _test_measure()
      hvac_iq_values = get_default_hvac_iq_values(es_version)
      _check_heating_system(hpxml)
      _check_cooling_system(hpxml, [{ systype: HPXML::HVACTypeCentralAirConditioner, fuel: HPXML::FuelTypeElectricity, comptype: HPXML::HVACCompressorTypeSingleStage, seer: get_es_central_ac_seer_cz5(es_version), frac_load: 1.0, shr: 0.73, **hvac_iq_values }])
      _check_heat_pump(hpxml)
      _check_thermostat(hpxml, control_type: HPXML::HVACControlTypeProgrammable)
      if [ESConstants.SFNationalVer3, ESConstants.SFPacificVer3, ESConstants.SFOregonWashingtonVer3_2].include? es_version
        _check_ducts(hpxml, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 0.0, duct_area: 729.0, duct_location: HPXML::LocationBasementConditioned },
                             { duct_type: HPXML::DuctTypeReturn, duct_rvalue: 0.0, duct_area: 135.0, duct_location: HPXML::LocationBasementConditioned }])
      elsif [ESConstants.SFNationalVer3_1, ESConstants.SFFloridaVer3_1, ESConstants.MFNationalVer1_1_2019].include? es_version
        _check_ducts(hpxml, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 0.0, duct_area: 729.0, duct_location: HPXML::LocationLivingSpace },
                             { duct_type: HPXML::DuctTypeReturn, duct_rvalue: 0.0, duct_area: 135.0, duct_location: HPXML::LocationLivingSpace }])
      elsif [ESConstants.MFNationalVer1_2019, ESConstants.MFOregonWashingtonVer1_2_2019].include? es_version
        return_r = (es_version != ESConstants.MFOregonWashingtonVer1_2_2019 ? 6.0 : 8.0)
        _check_ducts(hpxml, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 8.0, duct_area: 729.0, duct_location: HPXML::LocationAtticVented },
                             { duct_type: HPXML::DuctTypeReturn, duct_rvalue: return_r, duct_area: 135.0, duct_location: HPXML::LocationAtticVented }])
      end
      _check_duct_leakage(hpxml, [{ duct_leakage_units: HPXML::UnitsCFM25, duct_leakage_value: get_es_duct_leakage(es_version, 54.0), duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside },
                                  { duct_leakage_units: HPXML::UnitsCFM25, duct_leakage_value: get_es_duct_leakage(es_version, 54.0), duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside }])
    end
  end

  def test_furnace_gas_and_central_air_conditioner
    ESConstants.AllVersions.each do |es_version|
      _convert_to_es('base.xml', es_version)
      hpxml = _test_measure()
      hvac_iq_values = get_default_hvac_iq_values(es_version)
      _check_heating_system(hpxml, [{ systype: HPXML::HVACTypeFurnace, fuel: HPXML::FuelTypeNaturalGas, eff: get_es_gas_furnace_afue_cz5(es_version), frac_load: 1.0, **hvac_iq_values }])
      _check_cooling_system(hpxml, [{ systype: HPXML::HVACTypeCentralAirConditioner, fuel: HPXML::FuelTypeElectricity, comptype: HPXML::HVACCompressorTypeSingleStage, seer: get_es_central_ac_seer_cz5(es_version), frac_load: 1.0, shr: 0.73, **hvac_iq_values }])
      _check_heat_pump(hpxml)
      _check_thermostat(hpxml, control_type: HPXML::HVACControlTypeProgrammable)
      if [ESConstants.SFNationalVer3, ESConstants.SFPacificVer3, ESConstants.SFOregonWashingtonVer3_2].include? es_version
        _check_ducts(hpxml, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 0.0, duct_area: 729.0, duct_location: HPXML::LocationBasementConditioned },
                             { duct_type: HPXML::DuctTypeReturn, duct_rvalue: 0.0, duct_area: 270.0, duct_location: HPXML::LocationBasementConditioned }])
      elsif [ESConstants.SFNationalVer3_1, ESConstants.SFFloridaVer3_1, ESConstants.MFNationalVer1_1_2019].include? es_version
        _check_ducts(hpxml, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 0.0, duct_area: 729.0, duct_location: HPXML::LocationLivingSpace },
                             { duct_type: HPXML::DuctTypeReturn, duct_rvalue: 0.0, duct_area: 270.0, duct_location: HPXML::LocationLivingSpace }])
      elsif [ESConstants.MFNationalVer1_2019, ESConstants.MFOregonWashingtonVer1_2_2019].include? es_version
        return_r = (es_version != ESConstants.MFOregonWashingtonVer1_2_2019 ? 6.0 : 8.0)
        _check_ducts(hpxml, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 8.0, duct_area: 729.0, duct_location: HPXML::LocationAtticVented },
                             { duct_type: HPXML::DuctTypeReturn, duct_rvalue: return_r, duct_area: 270.0, duct_location: HPXML::LocationAtticVented }])
      end
      _check_duct_leakage(hpxml, [{ duct_leakage_units: HPXML::UnitsCFM25, duct_leakage_value: get_es_duct_leakage(es_version, 54.0), duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside },
                                  { duct_leakage_units: HPXML::UnitsCFM25, duct_leakage_value: get_es_duct_leakage(es_version, 54.0), duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside }])

      _convert_to_es('base-foundation-multiple.xml', es_version)
      hpxml = _test_measure()
      hvac_iq_values = get_default_hvac_iq_values(es_version)
      _check_heating_system(hpxml, [{ systype: HPXML::HVACTypeFurnace, fuel: HPXML::FuelTypeNaturalGas, eff: get_es_gas_furnace_afue_cz5(es_version), frac_load: 1.0, **hvac_iq_values }])
      _check_cooling_system(hpxml, [{ systype: HPXML::HVACTypeCentralAirConditioner, fuel: HPXML::FuelTypeElectricity, comptype: HPXML::HVACCompressorTypeSingleStage, seer: get_es_central_ac_seer_cz5(es_version), frac_load: 1.0, shr: 0.73, **hvac_iq_values }])
      _check_heat_pump(hpxml)
      _check_thermostat(hpxml, control_type: HPXML::HVACControlTypeProgrammable)
      if [ESConstants.SFNationalVer3, ESConstants.SFPacificVer3, ESConstants.SFOregonWashingtonVer3_2].include? es_version
        duct_r = (es_version != ESConstants.SFOregonWashingtonVer3_2 ? 6.0 : 8.0)
        _check_ducts(hpxml, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: duct_r, duct_area: 364.5, duct_location: HPXML::LocationBasementUnconditioned },
                             { duct_type: HPXML::DuctTypeReturn, duct_rvalue: duct_r, duct_area: 67.5, duct_location: HPXML::LocationBasementUnconditioned }])
      elsif [ESConstants.SFNationalVer3_1, ESConstants.SFFloridaVer3_1, ESConstants.MFNationalVer1_1_2019].include? es_version
        _check_ducts(hpxml, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 0.0, duct_area: 364.5, duct_location: HPXML::LocationLivingSpace },
                             { duct_type: HPXML::DuctTypeReturn, duct_rvalue: 0.0, duct_area: 67.5, duct_location: HPXML::LocationLivingSpace }])
      elsif [ESConstants.MFNationalVer1_2019, ESConstants.MFOregonWashingtonVer1_2_2019].include? es_version
        return_r = (es_version != ESConstants.MFOregonWashingtonVer1_2_2019 ? 6.0 : 8.0)
        _check_ducts(hpxml, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 8.0, duct_area: 364.5, duct_location: HPXML::LocationAtticVented },
                             { duct_type: HPXML::DuctTypeReturn, duct_rvalue: return_r, duct_area: 67.5, duct_location: HPXML::LocationAtticVented }])
      end
      _check_duct_leakage(hpxml, [{ duct_leakage_units: HPXML::UnitsCFM25, duct_leakage_value: get_es_duct_leakage(es_version, 27.0), duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside },
                                  { duct_leakage_units: HPXML::UnitsCFM25, duct_leakage_value: get_es_duct_leakage(es_version, 27.0), duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside }])

      _convert_to_es('base-foundation-ambient.xml', es_version)
      hpxml = _test_measure()
      hvac_iq_values = get_default_hvac_iq_values(es_version)
      _check_heating_system(hpxml, [{ systype: HPXML::HVACTypeFurnace, fuel: HPXML::FuelTypeNaturalGas, eff: get_es_gas_furnace_afue_cz5(es_version), frac_load: 1.0, **hvac_iq_values }])
      _check_cooling_system(hpxml, [{ systype: HPXML::HVACTypeCentralAirConditioner, fuel: HPXML::FuelTypeElectricity, comptype: HPXML::HVACCompressorTypeSingleStage, seer: get_es_central_ac_seer_cz5(es_version), frac_load: 1.0, shr: 0.73, **hvac_iq_values }])
      _check_heat_pump(hpxml)
      _check_thermostat(hpxml, control_type: HPXML::HVACControlTypeProgrammable)
      if [ESConstants.SFNationalVer3, ESConstants.SFPacificVer3, ESConstants.SFOregonWashingtonVer3_2].include? es_version
        duct_r = (es_version != ESConstants.SFOregonWashingtonVer3_2 ? 6.0 : 8.0)
        _check_ducts(hpxml, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: duct_r, duct_area: 364.5, duct_location: HPXML::LocationOutside },
                             { duct_type: HPXML::DuctTypeReturn, duct_rvalue: duct_r, duct_area: 67.5, duct_location: HPXML::LocationOutside }])
      elsif [ESConstants.SFNationalVer3_1, ESConstants.SFFloridaVer3_1, ESConstants.MFNationalVer1_1_2019].include? es_version
        _check_ducts(hpxml, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 0.0, duct_area: 364.5, duct_location: HPXML::LocationLivingSpace },
                             { duct_type: HPXML::DuctTypeReturn, duct_rvalue: 0.0, duct_area: 67.5, duct_location: HPXML::LocationLivingSpace }])
      elsif [ESConstants.MFNationalVer1_2019, ESConstants.MFOregonWashingtonVer1_2_2019].include? es_version
        return_r = (es_version != ESConstants.MFOregonWashingtonVer1_2_2019 ? 6.0 : 8.0)
        _check_ducts(hpxml, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 8.0, duct_area: 364.5, duct_location: HPXML::LocationAtticVented },
                             { duct_type: HPXML::DuctTypeReturn, duct_rvalue: return_r, duct_area: 67.5, duct_location: HPXML::LocationAtticVented }])
      end
      _check_duct_leakage(hpxml, [{ duct_leakage_units: HPXML::UnitsCFM25, duct_leakage_value: get_es_duct_leakage(es_version, 27.0), duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside },
                                  { duct_leakage_units: HPXML::UnitsCFM25, duct_leakage_value: get_es_duct_leakage(es_version, 27.0), duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside }])

      # Test w/ 2 stories
      _convert_to_es('base-enclosure-2stories.xml', es_version)
      hpxml = _test_measure()
      hvac_iq_values = get_default_hvac_iq_values(es_version)
      _check_heating_system(hpxml, [{ systype: HPXML::HVACTypeFurnace, fuel: HPXML::FuelTypeNaturalGas, eff: get_es_gas_furnace_afue_cz5(es_version), frac_load: 1.0, **hvac_iq_values }])
      _check_cooling_system(hpxml, [{ systype: HPXML::HVACTypeCentralAirConditioner, fuel: HPXML::FuelTypeElectricity, comptype: HPXML::HVACCompressorTypeSingleStage, seer: get_es_central_ac_seer_cz5(es_version), frac_load: 1.0, shr: 0.73, **hvac_iq_values }])
      _check_heat_pump(hpxml)
      _check_thermostat(hpxml, control_type: HPXML::HVACControlTypeProgrammable)
      if es_version == ESConstants.SFNationalVer3
        _check_ducts(hpxml, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 0.0, duct_area: 546.75, duct_location: HPXML::LocationBasementConditioned },
                             { duct_type: HPXML::DuctTypeSupply, duct_rvalue: 8.0, duct_area: 546.75, duct_location: HPXML::LocationAtticVented },
                             { duct_type: HPXML::DuctTypeReturn, duct_rvalue: 0.0, duct_area: 303.75, duct_location: HPXML::LocationBasementConditioned },
                             { duct_type: HPXML::DuctTypeReturn, duct_rvalue: 6.0, duct_area: 303.75, duct_location: HPXML::LocationAtticVented }])
      elsif es_version == ESConstants.MFNationalVer1_2019
        _check_ducts(hpxml, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 8.0, duct_area: 820.12, duct_location: HPXML::LocationAtticVented },
                             { duct_type: HPXML::DuctTypeSupply, duct_rvalue: 0.0, duct_area: 273.37, duct_location: HPXML::LocationLivingSpace },
                             { duct_type: HPXML::DuctTypeReturn, duct_rvalue: 6.0, duct_area: 455.63, duct_location: HPXML::LocationAtticVented },
                             { duct_type: HPXML::DuctTypeReturn, duct_rvalue: 0.0, duct_area: 151.88, duct_location: HPXML::LocationLivingSpace }])
      elsif es_version == ESConstants.SFNationalVer3_1
        _check_ducts(hpxml, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 0.0, duct_area: 1093.51, duct_location: HPXML::LocationLivingSpace },
                             { duct_type: HPXML::DuctTypeReturn, duct_rvalue: 0.0, duct_area: 607.51, duct_location: HPXML::LocationLivingSpace }])
      end
      _check_duct_leakage(hpxml, [{ duct_leakage_units: HPXML::UnitsCFM25, duct_leakage_value: get_es_duct_leakage(es_version, 81.0), duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside },
                                  { duct_leakage_units: HPXML::UnitsCFM25, duct_leakage_value: get_es_duct_leakage(es_version, 81.0), duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside }])

      # Test w/ 2 stories
      _convert_to_es('base-foundation-multiple.xml', es_version)
      hpxml = HPXML.new(hpxml_path: @tmp_hpxml_path)
      hpxml.building_construction.number_of_conditioned_floors += 1
      hpxml.building_construction.number_of_conditioned_floors_above_grade += 1
      XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
      hpxml = _test_measure()
      hvac_iq_values = get_default_hvac_iq_values(es_version)
      _check_heating_system(hpxml, [{ systype: HPXML::HVACTypeFurnace, fuel: HPXML::FuelTypeNaturalGas, eff: get_es_gas_furnace_afue_cz5(es_version), frac_load: 1.0, **hvac_iq_values }])
      _check_cooling_system(hpxml, [{ systype: HPXML::HVACTypeCentralAirConditioner, fuel: HPXML::FuelTypeElectricity, comptype: HPXML::HVACCompressorTypeSingleStage, seer: get_es_central_ac_seer_cz5(es_version), frac_load: 1.0, shr: 0.73, **hvac_iq_values }])
      _check_heat_pump(hpxml)
      _check_thermostat(hpxml, control_type: HPXML::HVACControlTypeProgrammable)
      if es_version == ESConstants.SFNationalVer3
        _check_ducts(hpxml, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 6.0, duct_area: 182.25, duct_location: HPXML::LocationBasementUnconditioned },
                             { duct_type: HPXML::DuctTypeSupply, duct_rvalue: 8.0, duct_area: 182.25, duct_location: HPXML::LocationAtticVented },
                             { duct_type: HPXML::DuctTypeReturn, duct_rvalue: 6.0, duct_area: 33.75, duct_location: HPXML::LocationBasementUnconditioned },
                             { duct_type: HPXML::DuctTypeReturn, duct_rvalue: 6.0, duct_area: 33.75, duct_location: HPXML::LocationAtticVented }])
      elsif es_version == ESConstants.MFNationalVer1_2019
        _check_ducts(hpxml, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 8.0, duct_area: 273.375, duct_location: HPXML::LocationAtticVented },
                             { duct_type: HPXML::DuctTypeSupply, duct_rvalue: 0.0, duct_area: 91.125, duct_location: HPXML::LocationLivingSpace },
                             { duct_type: HPXML::DuctTypeReturn, duct_rvalue: 6.0, duct_area: 50.625, duct_location: HPXML::LocationAtticVented },
                             { duct_type: HPXML::DuctTypeReturn, duct_rvalue: 0.0, duct_area: 16.875, duct_location: HPXML::LocationLivingSpace }])
      elsif es_version == ESConstants.SFNationalVer3_1
        _check_ducts(hpxml, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 0.0, duct_area: 364.51, duct_location: HPXML::LocationLivingSpace },
                             { duct_type: HPXML::DuctTypeReturn, duct_rvalue: 0.0, duct_area: 67.5, duct_location: HPXML::LocationLivingSpace }])
      end
      _check_duct_leakage(hpxml, [{ duct_leakage_units: HPXML::UnitsCFM25, duct_leakage_value: get_es_duct_leakage(es_version, 27.0), duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside },
                                  { duct_leakage_units: HPXML::UnitsCFM25, duct_leakage_value: get_es_duct_leakage(es_version, 27.0), duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside }])

      # Test w/ 2 stories
      _convert_to_es('base-foundation-ambient.xml', es_version)
      hpxml = HPXML.new(hpxml_path: @tmp_hpxml_path)
      hpxml.building_construction.number_of_conditioned_floors += 1
      hpxml.building_construction.number_of_conditioned_floors_above_grade += 1
      XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
      hpxml = _test_measure()
      hvac_iq_values = get_default_hvac_iq_values(es_version)
      _check_heating_system(hpxml, [{ systype: HPXML::HVACTypeFurnace, fuel: HPXML::FuelTypeNaturalGas, eff: get_es_gas_furnace_afue_cz5(es_version), frac_load: 1.0, **hvac_iq_values }])
      _check_cooling_system(hpxml, [{ systype: HPXML::HVACTypeCentralAirConditioner, fuel: HPXML::FuelTypeElectricity, comptype: HPXML::HVACCompressorTypeSingleStage, seer: get_es_central_ac_seer_cz5(es_version), frac_load: 1.0, shr: 0.73, **hvac_iq_values }])
      _check_heat_pump(hpxml)
      _check_thermostat(hpxml, control_type: HPXML::HVACControlTypeProgrammable)
      if es_version == ESConstants.SFNationalVer3
        _check_ducts(hpxml, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 6.0, duct_area: 182.25, duct_location: HPXML::LocationOutside },
                             { duct_type: HPXML::DuctTypeSupply, duct_rvalue: 8.0, duct_area: 182.25, duct_location: HPXML::LocationAtticVented },
                             { duct_type: HPXML::DuctTypeReturn, duct_rvalue: 6.0, duct_area: 33.75, duct_location: HPXML::LocationOutside },
                             { duct_type: HPXML::DuctTypeReturn, duct_rvalue: 6.0, duct_area: 33.75, duct_location: HPXML::LocationAtticVented }])
      elsif es_version == ESConstants.MFNationalVer1_2019
        _check_ducts(hpxml, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 8.0, duct_area: 273.375, duct_location: HPXML::LocationAtticVented },
                             { duct_type: HPXML::DuctTypeSupply, duct_rvalue: 0.0, duct_area: 91.125, duct_location: HPXML::LocationLivingSpace },
                             { duct_type: HPXML::DuctTypeReturn, duct_rvalue: 6.0, duct_area: 50.625, duct_location: HPXML::LocationAtticVented },
                             { duct_type: HPXML::DuctTypeReturn, duct_rvalue: 0.0, duct_area: 16.875, duct_location: HPXML::LocationLivingSpace }])
      elsif es_version == ESConstants.SFNationalVer3_1
        _check_ducts(hpxml, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 0.0, duct_area: 364.51, duct_location: HPXML::LocationLivingSpace },
                             { duct_type: HPXML::DuctTypeReturn, duct_rvalue: 0.0, duct_area: 67.5, duct_location: HPXML::LocationLivingSpace }])
      end
      _check_duct_leakage(hpxml, [{ duct_leakage_units: HPXML::UnitsCFM25, duct_leakage_value: get_es_duct_leakage(es_version, 27.0), duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside },
                                  { duct_leakage_units: HPXML::UnitsCFM25, duct_leakage_value: get_es_duct_leakage(es_version, 27.0), duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside }])
    end
  end

  def test_multiple_hvac
    ESConstants.AllVersions.each do |es_version|
      _convert_to_es('base-hvac-multiple.xml', es_version)
      hpxml = _test_measure()
      hvac_iq_values = get_default_hvac_iq_values(es_version)
      _check_heating_system(hpxml, [{ systype: HPXML::HVACTypeFurnace, fuel: HPXML::FuelTypeNaturalGas, eff: get_es_gas_furnace_afue_cz5(es_version), frac_load: 0.1, **hvac_iq_values },
                                    { systype: HPXML::HVACTypeBoiler, fuel: HPXML::FuelTypeElectricity, eff: 0.98, frac_load: 0.1, eae: 170 },
                                    { systype: HPXML::HVACTypeBoiler, fuel: HPXML::FuelTypeNaturalGas, eff: get_es_gas_boiler_afue_cz5(es_version), frac_load: 0.1, eae: 170 },
                                    { systype: HPXML::HVACTypeFurnace, fuel: HPXML::FuelTypeOil, eff: get_es_oil_furnace_afue_cz5(es_version), frac_load: 0.1, **hvac_iq_values },
                                    { systype: HPXML::HVACTypeFurnace, fuel: HPXML::FuelTypePropane, eff: get_es_gas_furnace_afue_cz5(es_version), frac_load: 0.1, **hvac_iq_values }])
      _check_cooling_system(hpxml, [{ systype: HPXML::HVACTypeCentralAirConditioner, fuel: HPXML::FuelTypeElectricity, comptype: HPXML::HVACCompressorTypeSingleStage, seer: get_es_central_ac_seer_cz5(es_version), frac_load: 0.2, shr: 0.73, **hvac_iq_values },
                                    { systype: HPXML::HVACTypeCentralAirConditioner, fuel: HPXML::FuelTypeElectricity, comptype: HPXML::HVACCompressorTypeSingleStage, seer: get_es_central_ac_seer_cz5(es_version), frac_load: 0.2, shr: 0.65, **hvac_iq_values }])
      _check_heat_pump(hpxml, [{ systype: HPXML::HVACTypeHeatPumpAirToAir, fuel: HPXML::FuelTypeElectricity, comptype: HPXML::HVACCompressorTypeSingleStage, hspf: get_es_ashp_hspf_cz5(es_version), seer: get_es_ashp_seer_cz5(es_version), frac_load_heat: 0.1, frac_load_cool: 0.0, backup_fuel: HPXML::FuelTypeElectricity, backup_eff: 1.0, shr: 0.73, **hvac_iq_values },
                               { systype: HPXML::HVACTypeHeatPumpAirToAir, fuel: HPXML::FuelTypeElectricity, comptype: HPXML::HVACCompressorTypeSingleStage, hspf: get_es_ashp_hspf_cz5(es_version), seer: get_es_ashp_seer_cz5(es_version), frac_load_heat: 0.1, frac_load_cool: 0.0, backup_fuel: HPXML::FuelTypeElectricity, backup_eff: 1.0, shr: 0.73, **hvac_iq_values }, # Electric Resistance => ASHP
                               { systype: HPXML::HVACTypeHeatPumpAirToAir, fuel: HPXML::FuelTypeElectricity, comptype: HPXML::HVACCompressorTypeSingleStage, hspf: get_es_ashp_hspf_cz5(es_version), seer: get_es_ashp_seer_cz5(es_version), frac_load_heat: 0.1, frac_load_cool: 0.2, backup_fuel: HPXML::FuelTypeElectricity, backup_eff: 1.0, shr: 0.73, **hvac_iq_values },
                               { systype: HPXML::HVACTypeHeatPumpAirToAir, fuel: HPXML::FuelTypeElectricity, comptype: HPXML::HVACCompressorTypeSingleStage, hspf: get_es_ashp_hspf_cz5(es_version), seer: get_es_ashp_seer_cz5(es_version), frac_load_heat: 0.1, frac_load_cool: 0.2, backup_fuel: HPXML::FuelTypeElectricity, backup_eff: 1.0, shr: 0.73, **hvac_iq_values },
                               { systype: HPXML::HVACTypeHeatPumpAirToAir, fuel: HPXML::FuelTypeElectricity, comptype: HPXML::HVACCompressorTypeSingleStage, hspf: get_es_ashp_hspf_cz5(es_version), seer: get_es_ashp_seer_cz5(es_version), frac_load_heat: 0.1, frac_load_cool: 0.2, backup_fuel: HPXML::FuelTypeElectricity, backup_eff: 1.0, shr: 0.73, **hvac_iq_values }]) # Mini-split => ASHP
      _check_thermostat(hpxml, control_type: HPXML::HVACControlTypeProgrammable)
      if [ESConstants.SFNationalVer3, ESConstants.SFPacificVer3, ESConstants.SFOregonWashingtonVer3_2].include? es_version
        _check_ducts(hpxml, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 0.0, duct_area: 66.2, duct_location: HPXML::LocationBasementConditioned },
                             { duct_type: HPXML::DuctTypeReturn, duct_rvalue: 0.0, duct_area: 24.5, duct_location: HPXML::LocationBasementConditioned },
                             { duct_type: HPXML::DuctTypeSupply, duct_rvalue: 0.0, duct_area: 66.2, duct_location: HPXML::LocationBasementConditioned },
                             { duct_type: HPXML::DuctTypeReturn, duct_rvalue: 0.0, duct_area: 24.5, duct_location: HPXML::LocationBasementConditioned },
                             { duct_type: HPXML::DuctTypeSupply, duct_rvalue: 0.0, duct_area: 66.2, duct_location: HPXML::LocationBasementConditioned },
                             { duct_type: HPXML::DuctTypeReturn, duct_rvalue: 0.0, duct_area: 24.5, duct_location: HPXML::LocationBasementConditioned },
                             { duct_type: HPXML::DuctTypeSupply, duct_rvalue: 0.0, duct_area: 66.2, duct_location: HPXML::LocationBasementConditioned },
                             { duct_type: HPXML::DuctTypeReturn, duct_rvalue: 0.0, duct_area: 24.5, duct_location: HPXML::LocationBasementConditioned },
                             { duct_type: HPXML::DuctTypeSupply, duct_rvalue: 0.0, duct_area: 72.9, duct_location: HPXML::LocationBasementConditioned },
                             { duct_type: HPXML::DuctTypeReturn, duct_rvalue: 0.0, duct_area: 13.5, duct_location: HPXML::LocationBasementConditioned },
                             { duct_type: HPXML::DuctTypeSupply, duct_rvalue: 0.0, duct_area: 72.9, duct_location: HPXML::LocationBasementConditioned },
                             { duct_type: HPXML::DuctTypeReturn, duct_rvalue: 0.0, duct_area: 13.5, duct_location: HPXML::LocationBasementConditioned },
                             { duct_type: HPXML::DuctTypeSupply, duct_rvalue: 0.0, duct_area: 72.9, duct_location: HPXML::LocationBasementConditioned },
                             { duct_type: HPXML::DuctTypeReturn, duct_rvalue: 0.0, duct_area: 13.5, duct_location: HPXML::LocationBasementConditioned },
                             { duct_type: HPXML::DuctTypeSupply, duct_rvalue: 0.0, duct_area: 145.8, duct_location: HPXML::LocationBasementConditioned },
                             { duct_type: HPXML::DuctTypeReturn, duct_rvalue: 0.0, duct_area: 27.0, duct_location: HPXML::LocationBasementConditioned },
                             { duct_type: HPXML::DuctTypeSupply, duct_rvalue: 0.0, duct_area: 145.8, duct_location: HPXML::LocationBasementConditioned },
                             { duct_type: HPXML::DuctTypeReturn, duct_rvalue: 0.0, duct_area: 27.0, duct_location: HPXML::LocationBasementConditioned }])
      elsif [ESConstants.SFNationalVer3_1, ESConstants.SFFloridaVer3_1, ESConstants.MFNationalVer1_1_2019].include? es_version
        _check_ducts(hpxml, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 0.0, duct_area: 66.2, duct_location: HPXML::LocationLivingSpace },
                             { duct_type: HPXML::DuctTypeReturn, duct_rvalue: 0.0, duct_area: 24.5, duct_location: HPXML::LocationLivingSpace },
                             { duct_type: HPXML::DuctTypeSupply, duct_rvalue: 0.0, duct_area: 66.2, duct_location: HPXML::LocationLivingSpace },
                             { duct_type: HPXML::DuctTypeReturn, duct_rvalue: 0.0, duct_area: 24.5, duct_location: HPXML::LocationLivingSpace },
                             { duct_type: HPXML::DuctTypeSupply, duct_rvalue: 0.0, duct_area: 66.2, duct_location: HPXML::LocationLivingSpace },
                             { duct_type: HPXML::DuctTypeReturn, duct_rvalue: 0.0, duct_area: 24.5, duct_location: HPXML::LocationLivingSpace },
                             { duct_type: HPXML::DuctTypeSupply, duct_rvalue: 0.0, duct_area: 66.2, duct_location: HPXML::LocationLivingSpace },
                             { duct_type: HPXML::DuctTypeReturn, duct_rvalue: 0.0, duct_area: 24.5, duct_location: HPXML::LocationLivingSpace },
                             { duct_type: HPXML::DuctTypeSupply, duct_rvalue: 0.0, duct_area: 72.9, duct_location: HPXML::LocationLivingSpace },
                             { duct_type: HPXML::DuctTypeReturn, duct_rvalue: 0.0, duct_area: 13.5, duct_location: HPXML::LocationLivingSpace },
                             { duct_type: HPXML::DuctTypeSupply, duct_rvalue: 0.0, duct_area: 72.9, duct_location: HPXML::LocationLivingSpace },
                             { duct_type: HPXML::DuctTypeReturn, duct_rvalue: 0.0, duct_area: 13.5, duct_location: HPXML::LocationLivingSpace },
                             { duct_type: HPXML::DuctTypeSupply, duct_rvalue: 0.0, duct_area: 72.9, duct_location: HPXML::LocationLivingSpace },
                             { duct_type: HPXML::DuctTypeReturn, duct_rvalue: 0.0, duct_area: 13.5, duct_location: HPXML::LocationLivingSpace },
                             { duct_type: HPXML::DuctTypeSupply, duct_rvalue: 0.0, duct_area: 145.8, duct_location: HPXML::LocationLivingSpace },
                             { duct_type: HPXML::DuctTypeReturn, duct_rvalue: 0.0, duct_area: 27.0, duct_location: HPXML::LocationLivingSpace },
                             { duct_type: HPXML::DuctTypeSupply, duct_rvalue: 0.0, duct_area: 145.8, duct_location: HPXML::LocationLivingSpace },
                             { duct_type: HPXML::DuctTypeReturn, duct_rvalue: 0.0, duct_area: 27.0, duct_location: HPXML::LocationLivingSpace }])
      elsif [ESConstants.MFNationalVer1_2019, ESConstants.MFOregonWashingtonVer1_2_2019].include? es_version
        return_r = (es_version != ESConstants.MFOregonWashingtonVer1_2_2019 ? 6.0 : 8.0)
        _check_ducts(hpxml, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 8.0, duct_area: 66.2, duct_location: HPXML::LocationAtticVented },
                             { duct_type: HPXML::DuctTypeReturn, duct_rvalue: return_r, duct_area: 24.5, duct_location: HPXML::LocationAtticVented },
                             { duct_type: HPXML::DuctTypeSupply, duct_rvalue: 8.0, duct_area: 66.2, duct_location: HPXML::LocationAtticVented },
                             { duct_type: HPXML::DuctTypeReturn, duct_rvalue: return_r, duct_area: 24.5, duct_location: HPXML::LocationAtticVented },
                             { duct_type: HPXML::DuctTypeSupply, duct_rvalue: 8.0, duct_area: 66.2, duct_location: HPXML::LocationAtticVented },
                             { duct_type: HPXML::DuctTypeReturn, duct_rvalue: return_r, duct_area: 24.5, duct_location: HPXML::LocationAtticVented },
                             { duct_type: HPXML::DuctTypeSupply, duct_rvalue: 8.0, duct_area: 66.2, duct_location: HPXML::LocationAtticVented },
                             { duct_type: HPXML::DuctTypeReturn, duct_rvalue: return_r, duct_area: 24.5, duct_location: HPXML::LocationAtticVented },
                             { duct_type: HPXML::DuctTypeSupply, duct_rvalue: 8.0, duct_area: 72.9, duct_location: HPXML::LocationAtticVented },
                             { duct_type: HPXML::DuctTypeReturn, duct_rvalue: return_r, duct_area: 13.5, duct_location: HPXML::LocationAtticVented },
                             { duct_type: HPXML::DuctTypeSupply, duct_rvalue: 8.0, duct_area: 72.9, duct_location: HPXML::LocationAtticVented },
                             { duct_type: HPXML::DuctTypeReturn, duct_rvalue: return_r, duct_area: 13.5, duct_location: HPXML::LocationAtticVented },
                             { duct_type: HPXML::DuctTypeSupply, duct_rvalue: 8.0, duct_area: 72.9, duct_location: HPXML::LocationAtticVented },
                             { duct_type: HPXML::DuctTypeReturn, duct_rvalue: return_r, duct_area: 13.5, duct_location: HPXML::LocationAtticVented },
                             { duct_type: HPXML::DuctTypeSupply, duct_rvalue: 8.0, duct_area: 145.8, duct_location: HPXML::LocationAtticVented },
                             { duct_type: HPXML::DuctTypeReturn, duct_rvalue: return_r, duct_area: 27.0, duct_location: HPXML::LocationAtticVented },
                             { duct_type: HPXML::DuctTypeSupply, duct_rvalue: 8.0, duct_area: 145.8, duct_location: HPXML::LocationAtticVented },
                             { duct_type: HPXML::DuctTypeReturn, duct_rvalue: return_r, duct_area: 27.0, duct_location: HPXML::LocationAtticVented }])
      end
      _check_duct_leakage(hpxml, [{ duct_leakage_units: HPXML::UnitsCFM25, duct_leakage_value: get_es_duct_leakage(es_version, 20.0), duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside },
                                  { duct_leakage_units: HPXML::UnitsCFM25, duct_leakage_value: get_es_duct_leakage(es_version, 20.0), duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside },
                                  { duct_leakage_units: HPXML::UnitsCFM25, duct_leakage_value: get_es_duct_leakage(es_version, 20.0), duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside },
                                  { duct_leakage_units: HPXML::UnitsCFM25, duct_leakage_value: get_es_duct_leakage(es_version, 20.0), duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside },
                                  { duct_leakage_units: HPXML::UnitsCFM25, duct_leakage_value: get_es_duct_leakage(es_version, 20.0), duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside },
                                  { duct_leakage_units: HPXML::UnitsCFM25, duct_leakage_value: get_es_duct_leakage(es_version, 20.0), duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside },
                                  { duct_leakage_units: HPXML::UnitsCFM25, duct_leakage_value: get_es_duct_leakage(es_version, 20.0), duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside },
                                  { duct_leakage_units: HPXML::UnitsCFM25, duct_leakage_value: get_es_duct_leakage(es_version, 20.0), duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside },
                                  { duct_leakage_units: HPXML::UnitsCFM25, duct_leakage_value: get_es_duct_leakage(es_version, 20.0), duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside },
                                  { duct_leakage_units: HPXML::UnitsCFM25, duct_leakage_value: get_es_duct_leakage(es_version, 20.0), duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside },
                                  { duct_leakage_units: HPXML::UnitsCFM25, duct_leakage_value: get_es_duct_leakage(es_version, 20.0), duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside },
                                  { duct_leakage_units: HPXML::UnitsCFM25, duct_leakage_value: get_es_duct_leakage(es_version, 20.0), duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside },
                                  { duct_leakage_units: HPXML::UnitsCFM25, duct_leakage_value: get_es_duct_leakage(es_version, 20.0), duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside },
                                  { duct_leakage_units: HPXML::UnitsCFM25, duct_leakage_value: get_es_duct_leakage(es_version, 20.0), duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside },
                                  { duct_leakage_units: HPXML::UnitsCFM25, duct_leakage_value: get_es_duct_leakage(es_version, 20.0), duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside },
                                  { duct_leakage_units: HPXML::UnitsCFM25, duct_leakage_value: get_es_duct_leakage(es_version, 20.0), duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside },
                                  { duct_leakage_units: HPXML::UnitsCFM25, duct_leakage_value: get_es_duct_leakage(es_version, 20.0), duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside },
                                  { duct_leakage_units: HPXML::UnitsCFM25, duct_leakage_value: get_es_duct_leakage(es_version, 20.0), duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside }])
    end
  end

  def test_partial_hvac
    ESConstants.AllVersions.each do |es_version|
      _convert_to_es('base.xml', es_version)
      hpxml = HPXML.new(hpxml_path: @tmp_hpxml_path)
      hpxml.heating_systems[0].fraction_heat_load_served = 0.2
      hpxml.cooling_systems[0].fraction_cool_load_served = 0.3
      XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
      hpxml = _test_measure()
      hvac_iq_values = get_default_hvac_iq_values(es_version)
      _check_heating_system(hpxml, [{ systype: HPXML::HVACTypeFurnace, fuel: HPXML::FuelTypeNaturalGas, eff: get_es_gas_furnace_afue_cz5(es_version), frac_load: 0.2, **hvac_iq_values }])
      _check_cooling_system(hpxml, [{ systype: HPXML::HVACTypeCentralAirConditioner, fuel: HPXML::FuelTypeElectricity, comptype: HPXML::HVACCompressorTypeSingleStage, seer: get_es_central_ac_seer_cz5(es_version), frac_load: 0.3, shr: 0.73, **hvac_iq_values }])
      _check_heat_pump(hpxml)
      _check_thermostat(hpxml, control_type: HPXML::HVACControlTypeProgrammable)
      if [ESConstants.SFNationalVer3, ESConstants.SFPacificVer3, ESConstants.SFOregonWashingtonVer3_2].include? es_version
        _check_ducts(hpxml, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 0.0, duct_area: 729.0, duct_location: HPXML::LocationBasementConditioned },
                             { duct_type: HPXML::DuctTypeReturn, duct_rvalue: 0.0, duct_area: 270.0, duct_location: HPXML::LocationBasementConditioned }])
      elsif [ESConstants.SFNationalVer3_1, ESConstants.SFFloridaVer3_1, ESConstants.MFNationalVer1_1_2019].include? es_version
        _check_ducts(hpxml, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 0.0, duct_area: 729.0, duct_location: HPXML::LocationLivingSpace },
                             { duct_type: HPXML::DuctTypeReturn, duct_rvalue: 0.0, duct_area: 270.0, duct_location: HPXML::LocationLivingSpace }])
      elsif [ESConstants.MFNationalVer1_2019, ESConstants.MFOregonWashingtonVer1_2_2019].include? es_version
        return_r = (es_version != ESConstants.MFOregonWashingtonVer1_2_2019 ? 6.0 : 8.0)
        _check_ducts(hpxml, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 8.0, duct_area: 729.0, duct_location: HPXML::LocationAtticVented },
                             { duct_type: HPXML::DuctTypeReturn, duct_rvalue: return_r, duct_area: 270.0, duct_location: HPXML::LocationAtticVented }])
      end
      _check_duct_leakage(hpxml, [{ duct_leakage_units: HPXML::UnitsCFM25, duct_leakage_value: get_es_duct_leakage(es_version, 54.0), duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside },
                                  { duct_leakage_units: HPXML::UnitsCFM25, duct_leakage_value: get_es_duct_leakage(es_version, 54.0), duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside }])
    end
  end

  def test_shared_boiler_baseboard
    hpxml_name = 'base-bldgtype-multifamily-shared-boiler-only-baseboard.xml'
    ESConstants.AllVersions.each do |es_version|
      _convert_to_es(hpxml_name, es_version)
      hpxml = HPXML.new(hpxml_path: @tmp_hpxml_path)
      XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
      hpxml = _test_measure()
      _check_heating_system(hpxml, [{ systype: HPXML::HVACTypeBoiler, fuel: HPXML::FuelTypeNaturalGas, eff: 0.86, num_units_served: 6, frac_load: 1.0, eae: 220.2 }])
      _check_cooling_system(hpxml)
      _check_heat_pump(hpxml)
      _check_thermostat(hpxml, control_type: HPXML::HVACControlTypeProgrammable)
      _check_ducts(hpxml)
      _check_duct_leakage(hpxml)

      # test with heating capacity less than 300,000 Btuh
      _convert_to_es(hpxml_name, es_version)
      hpxml = HPXML.new(hpxml_path: @tmp_hpxml_path)
      hpxml.heating_systems[0].heating_capacity = 290000
      XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
      hpxml = _test_measure()
      if [ESConstants.SFNationalVer3, ESConstants.MFNationalVer1_2019].include? es_version
        _check_heating_system(hpxml, [{ systype: HPXML::HVACTypeBoiler, fuel: HPXML::FuelTypeNaturalGas, eff: 0.85, num_units_served: 6, frac_load: 1.0, eae: 220.2 }])
      elsif [ESConstants.SFPacificVer3, ESConstants.SFFloridaVer3_1].include? es_version
        _check_heating_system(hpxml, [{ systype: HPXML::HVACTypeBoiler, fuel: HPXML::FuelTypeNaturalGas, eff: 0.80, num_units_served: 6, frac_load: 1.0, eae: 220.2 }])
      else
        _check_heating_system(hpxml, [{ systype: HPXML::HVACTypeBoiler, fuel: HPXML::FuelTypeNaturalGas, eff: 0.90, num_units_served: 6, frac_load: 1.0, eae: 220.2 }])
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
    ESConstants.AllVersions.each do |es_version|
      _convert_to_es(hpxml_name, es_version)
      hpxml = HPXML.new(hpxml_path: @tmp_hpxml_path)
      XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
      hpxml = _test_measure()
      _check_heating_system(hpxml, [{ systype: HPXML::HVACTypeBoiler, fuel: HPXML::FuelTypeNaturalGas, eff: 0.86, num_units_served: 6, frac_load: 1.0, eae: 532.2 }])
      _check_cooling_system(hpxml)
      _check_heat_pump(hpxml)
      _check_thermostat(hpxml, control_type: HPXML::HVACControlTypeProgrammable)
      if [ESConstants.SFNationalVer3, ESConstants.SFPacificVer3, ESConstants.SFOregonWashingtonVer3_2].include? es_version
        return_duct_r = (es_version != ESConstants.SFOregonWashingtonVer3_2 ? 6.0 : 8.0)
        _check_ducts(hpxml, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 8.0, duct_area: 243.0, duct_location: HPXML::LocationAtticVented },
                             { duct_type: HPXML::DuctTypeReturn, duct_rvalue: return_duct_r, duct_area: 45.0, duct_location: HPXML::LocationAtticVented }])
      elsif [ESConstants.SFNationalVer3_1, ESConstants.SFFloridaVer3_1, ESConstants.MFNationalVer1_1_2019, ESConstants.MFNationalVer1_2019, ESConstants.MFOregonWashingtonVer1_2_2019].include? es_version
        _check_ducts(hpxml, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 0.0, duct_area: 243.0, duct_location: HPXML::LocationLivingSpace },
                             { duct_type: HPXML::DuctTypeReturn, duct_rvalue: 0.0, duct_area: 45.0, duct_location: HPXML::LocationLivingSpace }])
      end
      _check_duct_leakage(hpxml, [{ duct_leakage_units: HPXML::UnitsCFM25, duct_leakage_value: get_es_duct_leakage(es_version, 20.0), duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside },
                                  { duct_leakage_units: HPXML::UnitsCFM25, duct_leakage_value: get_es_duct_leakage(es_version, 20.0), duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside }])

      # test with heating capacity less than 300,000 Btuh
      _convert_to_es(hpxml_name, es_version)
      hpxml = HPXML.new(hpxml_path: @tmp_hpxml_path)
      hpxml.heating_systems[0].heating_capacity = 290000
      XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
      hpxml = _test_measure()
      if [ESConstants.SFNationalVer3, ESConstants.MFNationalVer1_2019].include? es_version
        _check_heating_system(hpxml, [{ systype: HPXML::HVACTypeBoiler, fuel: HPXML::FuelTypeNaturalGas, eff: 0.85, num_units_served: 6, frac_load: 1.0, eae: 532.2 }])
      elsif [ESConstants.SFPacificVer3, ESConstants.SFFloridaVer3_1].include? es_version
        _check_heating_system(hpxml, [{ systype: HPXML::HVACTypeBoiler, fuel: HPXML::FuelTypeNaturalGas, eff: 0.80, num_units_served: 6, frac_load: 1.0, eae: 532.2 }])
      else
        _check_heating_system(hpxml, [{ systype: HPXML::HVACTypeBoiler, fuel: HPXML::FuelTypeNaturalGas, eff: 0.90, num_units_served: 6, frac_load: 1.0, eae: 532.2 }])
      end
      _check_cooling_system(hpxml)
      _check_heat_pump(hpxml)
      _check_thermostat(hpxml, control_type: HPXML::HVACControlTypeProgrammable)
      if [ESConstants.SFNationalVer3, ESConstants.SFPacificVer3, ESConstants.SFOregonWashingtonVer3_2].include? es_version
        return_duct_r = (es_version != ESConstants.SFOregonWashingtonVer3_2 ? 6.0 : 8.0)
        _check_ducts(hpxml, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 8.0, duct_area: 243.0, duct_location: HPXML::LocationAtticVented },
                             { duct_type: HPXML::DuctTypeReturn, duct_rvalue: return_duct_r, duct_area: 45.0, duct_location: HPXML::LocationAtticVented }])
      elsif [ESConstants.SFNationalVer3_1, ESConstants.SFFloridaVer3_1, ESConstants.MFNationalVer1_1_2019, ESConstants.MFNationalVer1_2019, ESConstants.MFOregonWashingtonVer1_2_2019].include? es_version
        _check_ducts(hpxml, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 0.0, duct_area: 243.0, duct_location: HPXML::LocationLivingSpace },
                             { duct_type: HPXML::DuctTypeReturn, duct_rvalue: 0.0, duct_area: 45.0, duct_location: HPXML::LocationLivingSpace }])
      end
      _check_duct_leakage(hpxml, [{ duct_leakage_units: HPXML::UnitsCFM25, duct_leakage_value: get_es_duct_leakage(es_version, 20.0), duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside },
                                  { duct_leakage_units: HPXML::UnitsCFM25, duct_leakage_value: get_es_duct_leakage(es_version, 20.0), duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside }])
    end
  end

  def test_shared_boiler_fan_coil_ducted
    hpxml_name = 'base-bldgtype-multifamily-shared-boiler-only-fan-coil-ducted.xml'
    ESConstants.AllVersions.each do |es_version|
      _convert_to_es(hpxml_name, es_version)
      hpxml = HPXML.new(hpxml_path: @tmp_hpxml_path)
      XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
      hpxml = _test_measure()
      _check_heating_system(hpxml, [{ systype: HPXML::HVACTypeBoiler, fuel: HPXML::FuelTypeNaturalGas, eff: 0.86, num_units_served: 6, frac_load: 1.0, eae: 532.2 }])
      _check_cooling_system(hpxml)
      _check_heat_pump(hpxml)
      _check_thermostat(hpxml, control_type: HPXML::HVACControlTypeProgrammable)
      if [ESConstants.SFNationalVer3, ESConstants.SFPacificVer3, ESConstants.SFOregonWashingtonVer3_2].include? es_version
        return_duct_r = (es_version != ESConstants.SFOregonWashingtonVer3_2 ? 6.0 : 8.0)
        _check_ducts(hpxml, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 8.0, duct_area: 243.0, duct_location: HPXML::LocationAtticVented },
                             { duct_type: HPXML::DuctTypeReturn, duct_rvalue: return_duct_r, duct_area: 45.0, duct_location: HPXML::LocationAtticVented }])
      elsif [ESConstants.SFNationalVer3_1, ESConstants.SFFloridaVer3_1, ESConstants.MFNationalVer1_1_2019, ESConstants.MFNationalVer1_2019, ESConstants.MFOregonWashingtonVer1_2_2019].include? es_version
        _check_ducts(hpxml, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 0.0, duct_area: 243.0, duct_location: HPXML::LocationLivingSpace },
                             { duct_type: HPXML::DuctTypeReturn, duct_rvalue: 0.0, duct_area: 45.0, duct_location: HPXML::LocationLivingSpace }])
      end
      _check_duct_leakage(hpxml, [{ duct_leakage_units: HPXML::UnitsCFM25, duct_leakage_value: get_es_duct_leakage(es_version, 20.0), duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside },
                                  { duct_leakage_units: HPXML::UnitsCFM25, duct_leakage_value: get_es_duct_leakage(es_version, 20.0), duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside }])

      # test with heating capacity less than 300,000 Btuh
      _convert_to_es(hpxml_name, es_version)
      hpxml = HPXML.new(hpxml_path: @tmp_hpxml_path)
      hpxml.heating_systems[0].heating_capacity = 290000
      XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
      hpxml = _test_measure()
      if [ESConstants.SFNationalVer3, ESConstants.MFNationalVer1_2019].include? es_version
        _check_heating_system(hpxml, [{ systype: HPXML::HVACTypeBoiler, fuel: HPXML::FuelTypeNaturalGas, eff: 0.85, num_units_served: 6, frac_load: 1.0, eae: 532.2 }])
      elsif [ESConstants.SFPacificVer3, ESConstants.SFFloridaVer3_1].include? es_version
        _check_heating_system(hpxml, [{ systype: HPXML::HVACTypeBoiler, fuel: HPXML::FuelTypeNaturalGas, eff: 0.80, num_units_served: 6, frac_load: 1.0, eae: 532.2 }])
      else
        _check_heating_system(hpxml, [{ systype: HPXML::HVACTypeBoiler, fuel: HPXML::FuelTypeNaturalGas, eff: 0.90, num_units_served: 6, frac_load: 1.0, eae: 532.2 }])
      end
      _check_cooling_system(hpxml)
      _check_heat_pump(hpxml)
      _check_thermostat(hpxml, control_type: HPXML::HVACControlTypeProgrammable)
      if [ESConstants.SFNationalVer3, ESConstants.SFPacificVer3, ESConstants.SFOregonWashingtonVer3_2].include? es_version
        return_duct_r = (es_version != ESConstants.SFOregonWashingtonVer3_2 ? 6.0 : 8.0)
        _check_ducts(hpxml, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 8.0, duct_area: 243.0, duct_location: HPXML::LocationAtticVented },
                             { duct_type: HPXML::DuctTypeReturn, duct_rvalue: return_duct_r, duct_area: 45.0, duct_location: HPXML::LocationAtticVented }])
      elsif [ESConstants.SFNationalVer3_1, ESConstants.SFFloridaVer3_1, ESConstants.MFNationalVer1_1_2019, ESConstants.MFNationalVer1_2019, ESConstants.MFOregonWashingtonVer1_2_2019].include? es_version
        _check_ducts(hpxml, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 0.0, duct_area: 243.0, duct_location: HPXML::LocationLivingSpace },
                             { duct_type: HPXML::DuctTypeReturn, duct_rvalue: 0.0, duct_area: 45.0, duct_location: HPXML::LocationLivingSpace }])
      end
      _check_duct_leakage(hpxml, [{ duct_leakage_units: HPXML::UnitsCFM25, duct_leakage_value: get_es_duct_leakage(es_version, 20.0), duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside },
                                  { duct_leakage_units: HPXML::UnitsCFM25, duct_leakage_value: get_es_duct_leakage(es_version, 20.0), duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside }])
    end
  end

  def test_shared_boiler_water_loop_heat_pump
    hpxml_name = 'base-bldgtype-multifamily-shared-boiler-only-water-loop-heat-pump.xml'
    ESConstants.AllVersions.each do |es_version|
      _convert_to_es(hpxml_name, es_version)
      hpxml = HPXML.new(hpxml_path: @tmp_hpxml_path)
      XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
      hpxml = _test_measure()
      _check_heating_system(hpxml, [{ systype: HPXML::HVACTypeBoiler, fuel: HPXML::FuelTypeNaturalGas, eff: 0.89, num_units_served: 6, frac_load: 1 - 1 / 4.2, eae: 220.2 }])
      _check_cooling_system(hpxml)
      _check_heat_pump(hpxml, [{ systype: HPXML::HVACTypeHeatPumpWaterLoopToAir, fuel: HPXML::FuelTypeElectricity, cop: 4.2, eer: 14, heating_capacity: 24000.0, frac_load_heat: 1 / 4.2, frac_load_cool: 0.0 }])
      _check_thermostat(hpxml, control_type: HPXML::HVACControlTypeProgrammable)
      if [ESConstants.SFNationalVer3, ESConstants.SFPacificVer3, ESConstants.SFOregonWashingtonVer3_2].include? es_version
        return_duct_r = (es_version != ESConstants.SFOregonWashingtonVer3_2 ? 6.0 : 8.0)
        _check_ducts(hpxml, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 8.0, duct_area: 243.0, duct_location: HPXML::LocationAtticVented },
                             { duct_type: HPXML::DuctTypeReturn, duct_rvalue: return_duct_r, duct_area: 45.0, duct_location: HPXML::LocationAtticVented }])
      elsif [ESConstants.SFNationalVer3_1, ESConstants.SFFloridaVer3_1, ESConstants.MFNationalVer1_1_2019, ESConstants.MFNationalVer1_2019, ESConstants.MFOregonWashingtonVer1_2_2019].include? es_version
        _check_ducts(hpxml, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 0.0, duct_area: 243.0, duct_location: HPXML::LocationLivingSpace },
                             { duct_type: HPXML::DuctTypeReturn, duct_rvalue: 0.0, duct_area: 45.0, duct_location: HPXML::LocationLivingSpace }])
      end
      _check_duct_leakage(hpxml, [{ duct_leakage_units: HPXML::UnitsCFM25, duct_leakage_value: get_es_duct_leakage(es_version, 20.0), duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside },
                                  { duct_leakage_units: HPXML::UnitsCFM25, duct_leakage_value: get_es_duct_leakage(es_version, 20.0), duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside }])

      # test w/ heating capacity less than 300,000 Btuh
      _convert_to_es(hpxml_name, es_version)
      hpxml = HPXML.new(hpxml_path: @tmp_hpxml_path)
      hpxml.heating_systems[0].heating_capacity = 290000
      XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
      hpxml = _test_measure()
      if [ESConstants.SFNationalVer3, ESConstants.MFNationalVer1_2019].include? es_version
        _check_heating_system(hpxml, [{ systype: HPXML::HVACTypeBoiler, fuel: HPXML::FuelTypeNaturalGas, eff: 0.85, num_units_served: 6, frac_load: 1 - 1 / 4.2, eae: 220.2 }])
      elsif [ESConstants.SFPacificVer3, ESConstants.SFFloridaVer3_1].include? es_version
        _check_heating_system(hpxml, [{ systype: HPXML::HVACTypeBoiler, fuel: HPXML::FuelTypeNaturalGas, eff: 0.80, num_units_served: 6, frac_load: 1 - 1 / 4.2, eae: 220.2 }])
      else
        _check_heating_system(hpxml, [{ systype: HPXML::HVACTypeBoiler, fuel: HPXML::FuelTypeNaturalGas, eff: 0.90, num_units_served: 6, frac_load: 1 - 1 / 4.2, eae: 220.2 }])
      end
      _check_cooling_system(hpxml)
      _check_heat_pump(hpxml, [{ systype: HPXML::HVACTypeHeatPumpWaterLoopToAir, fuel: HPXML::FuelTypeElectricity, cop: 4.2, eer: 14, heating_capacity: 24000.0, frac_load_heat: 1 / 4.2, frac_load_cool: 0.0 }])
      _check_thermostat(hpxml, control_type: HPXML::HVACControlTypeProgrammable)
      if [ESConstants.SFNationalVer3, ESConstants.SFPacificVer3, ESConstants.SFOregonWashingtonVer3_2].include? es_version
        return_duct_r = (es_version != ESConstants.SFOregonWashingtonVer3_2 ? 6.0 : 8.0)
        _check_ducts(hpxml, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 8.0, duct_area: 243.0, duct_location: HPXML::LocationAtticVented },
                             { duct_type: HPXML::DuctTypeReturn, duct_rvalue: return_duct_r, duct_area: 45.0, duct_location: HPXML::LocationAtticVented }])
      elsif [ESConstants.SFNationalVer3_1, ESConstants.SFFloridaVer3_1, ESConstants.MFNationalVer1_1_2019, ESConstants.MFNationalVer1_2019, ESConstants.MFOregonWashingtonVer1_2_2019].include? es_version
        _check_ducts(hpxml, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 0.0, duct_area: 243.0, duct_location: HPXML::LocationLivingSpace },
                             { duct_type: HPXML::DuctTypeReturn, duct_rvalue: 0.0, duct_area: 45.0, duct_location: HPXML::LocationLivingSpace }])
      end
      _check_duct_leakage(hpxml, [{ duct_leakage_units: HPXML::UnitsCFM25, duct_leakage_value: get_es_duct_leakage(es_version, 20.0), duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside },
                                  { duct_leakage_units: HPXML::UnitsCFM25, duct_leakage_value: get_es_duct_leakage(es_version, 20.0), duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside }])
    end
  end

  def test_shared_chiller_baseboard
    hpxml_name = 'base-bldgtype-multifamily-shared-chiller-only-baseboard.xml'
    ESConstants.AllVersions.each do |es_version|
      _convert_to_es(hpxml_name, es_version)
      hpxml = _test_measure()
      hvac_iq_values = get_default_hvac_iq_values(es_version)
      _check_heating_system(hpxml)
      hvac_iq_values[:fan_watts_per_cfm] = 0.375 # Chiller converted to AC, default AC fan w/cfm
      hvac_iq_values[:airflow_defect_ratio] = 0.0 # Chiller converted to AC, no airflow defect
      hvac_iq_values[:charge_defect_ratio] = 0.0 # Chiller converted to AC, no charge defect
      _check_cooling_system(hpxml, [{ systype: HPXML::HVACTypeCentralAirConditioner, fuel: HPXML::FuelTypeElectricity, comptype: HPXML::HVACCompressorTypeSingleStage, seer: 14.19, frac_load: 1.0, dse: 1.0, shr: 0.73, **hvac_iq_values }])
      _check_heat_pump(hpxml)
      _check_thermostat(hpxml, control_type: HPXML::HVACControlTypeProgrammable)
      _check_ducts(hpxml)
      _check_duct_leakage(hpxml)
    end
  end

  def test_shared_chiller_fan_coil
    hpxml_name = 'base-bldgtype-multifamily-shared-chiller-only-fan-coil.xml'
    ESConstants.AllVersions.each do |es_version|
      _convert_to_es(hpxml_name, es_version)
      hpxml = _test_measure()
      hvac_iq_values = get_default_hvac_iq_values(es_version)
      _check_heating_system(hpxml)
      hvac_iq_values[:fan_watts_per_cfm] = 0.5 # Chiller converted to AC, default AC fan w/cfm
      hvac_iq_values[:airflow_defect_ratio] = 0.0 # Chiller converted to AC, no airflow defect
      hvac_iq_values[:charge_defect_ratio] = 0.0 # Chiller converted to AC, no charge defect
      _check_cooling_system(hpxml, [{ systype: HPXML::HVACTypeCentralAirConditioner, fuel: HPXML::FuelTypeElectricity, comptype: HPXML::HVACCompressorTypeSingleStage, seer: 12.74, frac_load: 1.0, shr: 0.73, **hvac_iq_values }])
      _check_heat_pump(hpxml)
      _check_thermostat(hpxml, control_type: HPXML::HVACControlTypeProgrammable)
      if [ESConstants.SFNationalVer3, ESConstants.SFPacificVer3, ESConstants.SFOregonWashingtonVer3_2].include? es_version
        return_duct_r = (es_version != ESConstants.SFOregonWashingtonVer3_2 ? 6.0 : 8.0)
        _check_ducts(hpxml, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 8.0, duct_area: 243.0, duct_location: HPXML::LocationAtticVented },
                             { duct_type: HPXML::DuctTypeReturn, duct_rvalue: return_duct_r, duct_area: 45.0, duct_location: HPXML::LocationAtticVented }])
      elsif [ESConstants.SFNationalVer3_1, ESConstants.SFFloridaVer3_1, ESConstants.MFNationalVer1_1_2019, ESConstants.MFNationalVer1_2019, ESConstants.MFOregonWashingtonVer1_2_2019].include? es_version
        _check_ducts(hpxml, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 0.0, duct_area: 243.0, duct_location: HPXML::LocationLivingSpace },
                             { duct_type: HPXML::DuctTypeReturn, duct_rvalue: 0.0, duct_area: 45.0, duct_location: HPXML::LocationLivingSpace }])
      end
      _check_duct_leakage(hpxml, [{ duct_leakage_units: HPXML::UnitsCFM25, duct_leakage_value: get_es_duct_leakage(es_version, 20.0), duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside },
                                  { duct_leakage_units: HPXML::UnitsCFM25, duct_leakage_value: get_es_duct_leakage(es_version, 20.0), duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside }])
    end
  end

  def test_shared_chiller_fan_coil_ducted
    hpxml_name = 'base-bldgtype-multifamily-shared-chiller-only-fan-coil.xml'
    ESConstants.AllVersions.each do |es_version|
      _convert_to_es(hpxml_name, es_version)
      hpxml = _test_measure()
      hvac_iq_values = get_default_hvac_iq_values(es_version)
      _check_heating_system(hpxml)
      hvac_iq_values[:fan_watts_per_cfm] = 0.5 # Chiller converted to AC, default AC fan w/cfm
      hvac_iq_values[:airflow_defect_ratio] = 0.0 # Chiller converted to AC, no airflow defect
      hvac_iq_values[:charge_defect_ratio] = 0.0 # Chiller converted to AC, no charge defect
      _check_cooling_system(hpxml, [{ systype: HPXML::HVACTypeCentralAirConditioner, fuel: HPXML::FuelTypeElectricity, comptype: HPXML::HVACCompressorTypeSingleStage, seer: 12.74, frac_load: 1.0, shr: 0.73, **hvac_iq_values }])
      _check_heat_pump(hpxml)
      _check_thermostat(hpxml, control_type: HPXML::HVACControlTypeProgrammable)
      if [ESConstants.SFNationalVer3, ESConstants.SFPacificVer3, ESConstants.SFOregonWashingtonVer3_2].include? es_version
        return_duct_r = (es_version != ESConstants.SFOregonWashingtonVer3_2 ? 6.0 : 8.0)
        _check_ducts(hpxml, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 8.0, duct_area: 243.0, duct_location: HPXML::LocationAtticVented },
                             { duct_type: HPXML::DuctTypeReturn, duct_rvalue: return_duct_r, duct_area: 45.0, duct_location: HPXML::LocationAtticVented }])
      elsif [ESConstants.SFNationalVer3_1, ESConstants.SFFloridaVer3_1, ESConstants.MFNationalVer1_1_2019, ESConstants.MFNationalVer1_2019, ESConstants.MFOregonWashingtonVer1_2_2019].include? es_version
        _check_ducts(hpxml, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 0.0, duct_area: 243.0, duct_location: HPXML::LocationLivingSpace },
                             { duct_type: HPXML::DuctTypeReturn, duct_rvalue: 0.0, duct_area: 45.0, duct_location: HPXML::LocationLivingSpace }])
      end
      _check_duct_leakage(hpxml, [{ duct_leakage_units: HPXML::UnitsCFM25, duct_leakage_value: get_es_duct_leakage(es_version, 20.0), duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside },
                                  { duct_leakage_units: HPXML::UnitsCFM25, duct_leakage_value: get_es_duct_leakage(es_version, 20.0), duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside }])
    end
  end

  def test_shared_chiller_water_loop_heat_pump
    hpxml_name = 'base-bldgtype-multifamily-shared-chiller-only-water-loop-heat-pump.xml'
    ESConstants.AllVersions.each do |es_version|
      _convert_to_es(hpxml_name, es_version)
      hpxml = _test_measure()
      hvac_iq_values = get_default_hvac_iq_values(es_version)
      _check_heating_system(hpxml)
      hvac_iq_values[:fan_watts_per_cfm] = 0.5 # Chiller converted to AC, default AC fan w/cfm
      hvac_iq_values[:airflow_defect_ratio] = 0.0 # Chiller converted to AC, no airflow defect
      hvac_iq_values[:charge_defect_ratio] = 0.0 # Chiller converted to AC, no charge defect
      _check_cooling_system(hpxml, [{ systype: HPXML::HVACTypeCentralAirConditioner, fuel: HPXML::FuelTypeElectricity, comptype: HPXML::HVACCompressorTypeSingleStage, seer: 5.26, frac_load: 1.0, shr: 0.73, **hvac_iq_values }])
      _check_heat_pump(hpxml)
      _check_thermostat(hpxml, control_type: HPXML::HVACControlTypeProgrammable)
      if [ESConstants.SFNationalVer3, ESConstants.SFPacificVer3, ESConstants.SFOregonWashingtonVer3_2].include? es_version
        return_duct_r = (es_version != ESConstants.SFOregonWashingtonVer3_2 ? 6.0 : 8.0)
        _check_ducts(hpxml, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 8.0, duct_area: 243.0, duct_location: HPXML::LocationAtticVented },
                             { duct_type: HPXML::DuctTypeReturn, duct_rvalue: return_duct_r, duct_area: 45.0, duct_location: HPXML::LocationAtticVented }])
      elsif [ESConstants.SFNationalVer3_1, ESConstants.SFFloridaVer3_1, ESConstants.MFNationalVer1_1_2019, ESConstants.MFNationalVer1_2019, ESConstants.MFOregonWashingtonVer1_2_2019].include? es_version
        _check_ducts(hpxml, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 0.0, duct_area: 243.0, duct_location: HPXML::LocationLivingSpace },
                             { duct_type: HPXML::DuctTypeReturn, duct_rvalue: 0.0, duct_area: 45.0, duct_location: HPXML::LocationLivingSpace }])
      end
      _check_duct_leakage(hpxml, [{ duct_leakage_units: HPXML::UnitsCFM25, duct_leakage_value: get_es_duct_leakage(es_version, 20.0), duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside },
                                  { duct_leakage_units: HPXML::UnitsCFM25, duct_leakage_value: get_es_duct_leakage(es_version, 20.0), duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside }])
    end
  end

  def test_shared_cooling_tower_water_loop_heat_pump
    hpxml_name = 'base-bldgtype-multifamily-shared-cooling-tower-only-water-loop-heat-pump.xml'
    ESConstants.AllVersions.each do |es_version|
      _convert_to_es(hpxml_name, es_version)
      hpxml = _test_measure()
      hvac_iq_values = get_default_hvac_iq_values(es_version)
      _check_heating_system(hpxml)
      hvac_iq_values[:fan_watts_per_cfm] = 0.5 # Chiller converted to AC, default AC fan w/cfm
      hvac_iq_values[:airflow_defect_ratio] = 0.0 # Chiller converted to AC, no airflow defect
      hvac_iq_values[:charge_defect_ratio] = 0.0 # Chiller converted to AC, no charge defect
      _check_cooling_system(hpxml, [{ systype: HPXML::HVACTypeCentralAirConditioner, fuel: HPXML::FuelTypeElectricity, comptype: HPXML::HVACCompressorTypeSingleStage, seer: 12.99, frac_load: 1.0, shr: 0.73, **hvac_iq_values }])
      _check_heat_pump(hpxml)
      _check_thermostat(hpxml, control_type: HPXML::HVACControlTypeProgrammable)
      if [ESConstants.SFNationalVer3, ESConstants.SFPacificVer3, ESConstants.SFOregonWashingtonVer3_2].include? es_version
        return_duct_r = (es_version != ESConstants.SFOregonWashingtonVer3_2 ? 6.0 : 8.0)
        _check_ducts(hpxml, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 8.0, duct_area: 243.0, duct_location: HPXML::LocationAtticVented },
                             { duct_type: HPXML::DuctTypeReturn, duct_rvalue: return_duct_r, duct_area: 45.0, duct_location: HPXML::LocationAtticVented }])
      elsif [ESConstants.SFNationalVer3_1, ESConstants.SFFloridaVer3_1, ESConstants.MFNationalVer1_1_2019, ESConstants.MFNationalVer1_2019, ESConstants.MFOregonWashingtonVer1_2_2019].include? es_version
        _check_ducts(hpxml, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 0.0, duct_area: 243.0, duct_location: HPXML::LocationLivingSpace },
                             { duct_type: HPXML::DuctTypeReturn, duct_rvalue: 0.0, duct_area: 45.0, duct_location: HPXML::LocationLivingSpace }])
      end
      _check_duct_leakage(hpxml, [{ duct_leakage_units: HPXML::UnitsCFM25, duct_leakage_value: get_es_duct_leakage(es_version, 20.0), duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside },
                                  { duct_leakage_units: HPXML::UnitsCFM25, duct_leakage_value: get_es_duct_leakage(es_version, 20.0), duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside }])
    end
  end

  def test_shared_ground_loop_gound_ground_source
    hpxml_name = 'base-bldgtype-multifamily-shared-ground-loop-ground-to-air-heat-pump.xml'
    ESConstants.AllVersions.each do |es_version|
      _convert_to_es(hpxml_name, es_version)
      hpxml = _test_measure()
      hvac_iq_values = get_default_hvac_iq_values(es_version)
      _check_heating_system(hpxml)
      _check_cooling_system(hpxml)
      _check_heat_pump(hpxml, [{ systype: HPXML::HVACTypeHeatPumpAirToAir, fuel: HPXML::FuelTypeElectricity, comptype: HPXML::HVACCompressorTypeSingleStage, hspf: get_es_ashp_hspf_cz5(es_version), seer: get_es_ashp_seer_cz5(es_version), frac_load_heat: 1.0, frac_load_cool: 1.0, backup_fuel: HPXML::FuelTypeElectricity, backup_eff: 1.0, shr: 0.73, **hvac_iq_values }])
      _check_thermostat(hpxml, control_type: HPXML::HVACControlTypeProgrammable)
      if [ESConstants.SFNationalVer3, ESConstants.SFPacificVer3, ESConstants.SFOregonWashingtonVer3_2].include? es_version
        return_duct_r = (es_version != ESConstants.SFOregonWashingtonVer3_2 ? 6.0 : 8.0)
        _check_ducts(hpxml, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 8.0, duct_area: 243.0, duct_location: HPXML::LocationAtticVented },
                             { duct_type: HPXML::DuctTypeReturn, duct_rvalue: return_duct_r, duct_area: 45.0, duct_location: HPXML::LocationAtticVented }])
      elsif [ESConstants.SFNationalVer3_1, ESConstants.SFFloridaVer3_1, ESConstants.MFNationalVer1_1_2019, ESConstants.MFNationalVer1_2019, ESConstants.MFOregonWashingtonVer1_2_2019].include? es_version
        _check_ducts(hpxml, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 0.0, duct_area: 243.0, duct_location: HPXML::LocationLivingSpace },
                             { duct_type: HPXML::DuctTypeReturn, duct_rvalue: 0.0, duct_area: 45.0, duct_location: HPXML::LocationLivingSpace }])
      end
      _check_duct_leakage(hpxml, [{ duct_leakage_units: HPXML::UnitsCFM25, duct_leakage_value: get_es_duct_leakage(es_version, 20.0), duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside },
                                  { duct_leakage_units: HPXML::UnitsCFM25, duct_leakage_value: get_es_duct_leakage(es_version, 20.0), duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside }])

      next unless ESConstants.NationalVersions.include?(es_version)

      # Test in climate zone 7
      _convert_to_es(hpxml_name, es_version)
      hpxml = HPXML.new(hpxml_path: @tmp_hpxml_path)
      hpxml.climate_and_risk_zones.iecc_zone = '7'
      hpxml.climate_and_risk_zones.weather_station_name = 'Duluth, MN'
      hpxml.climate_and_risk_zones.weather_station_wmo = 727450
      XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
      hpxml = _test_measure()
      hvac_iq_values = get_default_hvac_iq_values(es_version)
      hvac_iq_values[:charge_defect_ratio] = 0.0 # Can't currently handle non-zero GSHP charge defect
      _check_heating_system(hpxml)
      _check_cooling_system(hpxml)
      _check_heat_pump(hpxml, [{ systype: HPXML::HVACTypeHeatPumpGroundToAir, fuel: HPXML::FuelTypeElectricity, num_units_served: 6, eer: get_es_gshp_eer_cz7(es_version), cop: get_es_gshp_cop_cz7(es_version), frac_load_heat: 1.0, frac_load_cool: 1.0, shr: 0.73, shared_loop_watts: 635.3, pump_w_per_ton: 30, is_shared_system: true, **hvac_iq_values }])
      _check_thermostat(hpxml, control_type: HPXML::HVACControlTypeProgrammable)
      if [ESConstants.SFNationalVer3, ESConstants.SFPacificVer3, ESConstants.SFOregonWashingtonVer3_2].include? es_version
        return_duct_r = (es_version != ESConstants.SFOregonWashingtonVer3_2 ? 6.0 : 8.0)
        _check_ducts(hpxml, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 8.0, duct_area: 243.0, duct_location: HPXML::LocationAtticVented },
                             { duct_type: HPXML::DuctTypeReturn, duct_rvalue: return_duct_r, duct_area: 45.0, duct_location: HPXML::LocationAtticVented }])
      elsif [ESConstants.SFNationalVer3_1, ESConstants.SFFloridaVer3_1, ESConstants.MFNationalVer1_1_2019, ESConstants.MFNationalVer1_2019, ESConstants.MFOregonWashingtonVer1_2_2019].include? es_version
        _check_ducts(hpxml, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 0.0, duct_area: 243.0, duct_location: HPXML::LocationLivingSpace },
                             { duct_type: HPXML::DuctTypeReturn, duct_rvalue: 0.0, duct_area: 45.0, duct_location: HPXML::LocationLivingSpace }])
      end
      _check_duct_leakage(hpxml, [{ duct_leakage_units: HPXML::UnitsCFM25, duct_leakage_value: get_es_duct_leakage(es_version, 20.0), duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside },
                                  { duct_leakage_units: HPXML::UnitsCFM25, duct_leakage_value: get_es_duct_leakage(es_version, 20.0), duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside }])
    end
  end

  def test_custom_setpoints
    ESConstants.AllVersions.each do |es_version|
      _convert_to_es('base.xml', es_version)
      hpxml = HPXML.new(hpxml_path: @tmp_hpxml_path)
      hpxml.hvac_controls[0].heating_setpoint_temp = 60
      hpxml.hvac_controls[0].cooling_setpoint_temp = 80
      hpxml.hvac_controls[0].control_type = HPXML::HVACControlTypeManual
      XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
      hpxml = _test_measure()
      _check_thermostat(hpxml, control_type: HPXML::HVACControlTypeProgrammable)
    end
  end

  def _test_measure()
    args_hash = {}
    args_hash['hpxml_input_path'] = @tmp_hpxml_path
    args_hash['calc_type'] = ESConstants.CalcTypeEnergyStarReference

    # create an instance of the measure
    measure = EnergyStarMeasure.new

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
      if not expected_values[:comptype].nil?
        assert_equal(expected_values[:comptype], heat_pump.compressor_type)
      else
        assert_nil(heat_pump.compressor_type)
      end
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
      else
        assert_equal(expected_values[:backup_eff], heat_pump.backup_heating_efficiency_percent.to_f + heat_pump.backup_heating_efficiency_afue.to_f)
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
      if not expected_values[:comptype].nil?
        assert_equal(expected_values[:comptype], cooling_system.compressor_type)
      else
        assert_nil(cooling_system.compressor_type)
      end
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

  def _convert_to_es(hpxml_name, program_version, state_code = nil)
    return convert_to_es(hpxml_name, program_version, @root_path, @tmp_hpxml_path, state_code)
  end
end
