# frozen_string_literal: true

require_relative '../../hpxml-measures/HPXMLtoOpenStudio/resources/minitest_helper'
require 'openstudio'
require_relative '../main.rb'
require 'fileutils'
require_relative 'util.rb'
require_relative '../../workflow/design'

class EnergyStarZeroEnergyReadyHomeWaterHeatingTest < Minitest::Test
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

  def is_low_flow(program_version, hpxml_bldg)
    if [*ES::SFVersions, ZERH::Ver1, ZERH::SFVer2].include? program_version
      iecc_zone = hpxml_bldg.climate_and_risk_zones.climate_zone_ieccs[0].zone
      if program_version == ES::SFNationalVer3_3 && iecc_zone == '4C'
        return true
      else
        return false
      end
    elsif [*ES::MFVersions, ZERH::MFVer2].include? program_version
      return true
    else
      fail "Unhandled program version: #{program_version}"
    end
  end

  def pipe_r_value(program_version, has_shared_water_heater)
    if [ES::SFOregonWashingtonVer3_2, ES::MFOregonWashingtonVer1_2].include? program_version
      return 3.0
    elsif program_version == ZERH::MFVer2 && has_shared_water_heater
      return 3.0
    elsif [ES::SFFloridaVer3_1, ES::SFPacificVer3_0, ES::SFNationalVer3_0, ES::SFNationalVer3_1, ES::SFNationalVer3_2, ES::SFNationalVer3_3,
           ES::MFNationalVer1_0, ES::MFNationalVer1_1, ES::MFNationalVer1_2, ES::MFNationalVer1_3,
           ZERH::Ver1, ZERH::SFVer2, ZERH::MFVer2].include? program_version
      return 0.0
    else
      fail "Unhandled program version: #{program_version}"
    end
  end

  def test_water_heating_tank_elec
    [*ES::AllVersions, *ZERH::AllVersions].each do |program_version|
      _convert_to_es_zerh('base.xml', program_version)
      hpxml_bldg = _test_ruleset(program_version)
      if [ES::MFNationalVer1_0, ES::MFNationalVer1_1].include? program_version
        _check_water_heater(hpxml_bldg, [{ whtype: HPXML::WaterHeaterTypeStorage, fuel: HPXML::FuelTypeElectricity, location: HPXML::LocationConditionedSpace, tank_vol: 40, ef: 0.95 }])
      elsif program_version == ES::SFPacificVer3_0
        _check_water_heater(hpxml_bldg, [{ whtype: HPXML::WaterHeaterTypeStorage, fuel: HPXML::FuelTypeElectricity, location: HPXML::LocationConditionedSpace, tank_vol: 40, ef: 0.90 }])
        _check_solar_thermal_system(hpxml_bldg, [{ system_type: HPXML::SolarThermalSystemTypeHotWater, solar_fraction: 0.90 }])
      elsif [ES::SFOregonWashingtonVer3_2, ES::MFOregonWashingtonVer1_2].include? program_version
        _check_water_heater(hpxml_bldg, [{ whtype: HPXML::WaterHeaterTypeHeatPump, fuel: HPXML::FuelTypeElectricity, location: HPXML::LocationConditionedSpace, tank_vol: 60, ef: 2.50 }])
      elsif [ZERH::Ver1].include? program_version
        _check_water_heater(hpxml_bldg, [{ whtype: HPXML::WaterHeaterTypeHeatPump, fuel: HPXML::FuelTypeElectricity, location: HPXML::LocationConditionedSpace, tank_vol: 40, ef: 2.00 }])
      elsif [ZERH::SFVer2].include? program_version
        _check_water_heater(hpxml_bldg, [{ whtype: HPXML::WaterHeaterTypeHeatPump, fuel: HPXML::FuelTypeElectricity, location: HPXML::LocationConditionedSpace, tank_vol: 40, uef: 2.57, fhr: 56 }])
      elsif [ES::SFNationalVer3_2, ES::SFNationalVer3_3].include? program_version
        _check_water_heater(hpxml_bldg, [{ whtype: HPXML::WaterHeaterTypeHeatPump, fuel: HPXML::FuelTypeElectricity, location: HPXML::LocationConditionedSpace, tank_vol: 40, uef: 2.20, fhr: 56 }])
      elsif program_version == ES::MFNationalVer1_2
        _check_water_heater(hpxml_bldg, [{ whtype: HPXML::WaterHeaterTypeHeatPump, fuel: HPXML::FuelTypeElectricity, location: HPXML::LocationConditionedSpace, tank_vol: 40, uef: 1.49, fhr: 56 }])
      elsif program_version == ES::MFNationalVer1_3
        _check_water_heater(hpxml_bldg, [{ whtype: HPXML::WaterHeaterTypeHeatPump, fuel: HPXML::FuelTypeElectricity, location: HPXML::LocationConditionedSpace, tank_vol: 40, uef: 2.50, fhr: 56 }])
      elsif program_version == ZERH::MFVer2
        _check_water_heater(hpxml_bldg, [{ whtype: HPXML::WaterHeaterTypeHeatPump, fuel: HPXML::FuelTypeElectricity, location: HPXML::LocationConditionedSpace, tank_vol: 40, uef: 1.95, fhr: 56 }])
      elsif [ES::SFFloridaVer3_1, ES::SFNationalVer3_0, ES::SFNationalVer3_1].include? program_version
        _check_water_heater(hpxml_bldg, [{ whtype: HPXML::WaterHeaterTypeStorage, fuel: HPXML::FuelTypeElectricity, location: HPXML::LocationConditionedSpace, tank_vol: 40, ef: 0.93 }])
      else
        fail "Unhandled program version: #{program_version}"
      end
      _check_hot_water_distribution(hpxml_bldg, disttype: HPXML::DHWDistTypeStandard, pipe_r: pipe_r_value(program_version, false), pipe_l: 93.5)
      _check_water_fixtures(hpxml_bldg, low_flow_shower: is_low_flow(program_version, hpxml_bldg), low_flow_faucet: is_low_flow(program_version, hpxml_bldg))
      _check_drain_water_heat_recovery(hpxml_bldg)
    end

    [*ES::NationalVersions, *ZERH::AllVersions].each do |program_version|
      # Test in climate zone 4C
      _convert_to_es_zerh('base.xml', program_version)
      hpxml = HPXML.new(hpxml_path: @tmp_hpxml_path)
      hpxml_bldg = hpxml.buildings[0]
      hpxml_bldg.climate_and_risk_zones.climate_zone_ieccs[0].zone = '4C'
      hpxml_bldg.climate_and_risk_zones.weather_station_name = 'Seattle, WA'
      hpxml_bldg.climate_and_risk_zones.weather_station_wmo = 727930
      XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
      hpxml_bldg = _test_ruleset(program_version)
      if [ES::MFNationalVer1_0, ES::MFNationalVer1_1].include? program_version
        _check_water_heater(hpxml_bldg, [{ whtype: HPXML::WaterHeaterTypeStorage, fuel: HPXML::FuelTypeElectricity, location: HPXML::LocationConditionedSpace, tank_vol: 40, ef: 0.95 }])
      elsif [ZERH::Ver1].include? program_version
        _check_water_heater(hpxml_bldg, [{ whtype: HPXML::WaterHeaterTypeHeatPump, fuel: HPXML::FuelTypeElectricity, location: HPXML::LocationConditionedSpace, tank_vol: 40, ef: 2.00 }])
      elsif [ZERH::SFVer2].include? program_version
        _check_water_heater(hpxml_bldg, [{ whtype: HPXML::WaterHeaterTypeHeatPump, fuel: HPXML::FuelTypeElectricity, location: HPXML::LocationConditionedSpace, tank_vol: 40, uef: 2.57, fhr: 56 }])
      elsif [ES::SFNationalVer3_2].include? program_version
        _check_water_heater(hpxml_bldg, [{ whtype: HPXML::WaterHeaterTypeHeatPump, fuel: HPXML::FuelTypeElectricity, location: HPXML::LocationConditionedSpace, tank_vol: 40, uef: 2.20, fhr: 56 }])
      elsif program_version == ES::MFNationalVer1_2
        _check_water_heater(hpxml_bldg, [{ whtype: HPXML::WaterHeaterTypeHeatPump, fuel: HPXML::FuelTypeElectricity, location: HPXML::LocationConditionedSpace, tank_vol: 40, uef: 1.49, fhr: 56 }])
      elsif [ES::SFNationalVer3_3, ES::MFNationalVer1_3].include? program_version
        _check_water_heater(hpxml_bldg, [{ whtype: HPXML::WaterHeaterTypeHeatPump, fuel: HPXML::FuelTypeElectricity, location: HPXML::LocationConditionedSpace, tank_vol: 40, uef: 3.30, fhr: 56 }])
      elsif program_version == ZERH::MFVer2
        _check_water_heater(hpxml_bldg, [{ whtype: HPXML::WaterHeaterTypeHeatPump, fuel: HPXML::FuelTypeElectricity, location: HPXML::LocationConditionedSpace, tank_vol: 40, uef: 1.95, fhr: 56 }])
      elsif [ES::SFFloridaVer3_1, ES::SFOregonWashingtonVer3_2, ES::SFPacificVer3_0, ES::SFNationalVer3_0, ES::SFNationalVer3_1,
             ES::MFOregonWashingtonVer1_2].include? program_version
        _check_water_heater(hpxml_bldg, [{ whtype: HPXML::WaterHeaterTypeStorage, fuel: HPXML::FuelTypeElectricity, location: HPXML::LocationConditionedSpace, tank_vol: 40, ef: 0.93 }])
      else
        fail "Unhandled program version: #{program_version}"
      end
      _check_hot_water_distribution(hpxml_bldg, disttype: HPXML::DHWDistTypeStandard, pipe_r: pipe_r_value(program_version, false), pipe_l: 93.5)
      _check_water_fixtures(hpxml_bldg, low_flow_shower: is_low_flow(program_version, hpxml_bldg), low_flow_faucet: is_low_flow(program_version, hpxml_bldg))
      _check_drain_water_heat_recovery(hpxml_bldg)
    end
  end

  def test_water_heating_tank_gas
    [*ES::AllVersions, *ZERH::AllVersions].each do |program_version|
      _convert_to_es_zerh('base-dhw-tank-gas-ef.xml', program_version)
      hpxml_bldg = _test_ruleset(program_version)
      if [ES::MFNationalVer1_0, ES::MFNationalVer1_1, ZERH::Ver1].include? program_version
        _check_water_heater(hpxml_bldg, [{ whtype: HPXML::WaterHeaterTypeStorage, fuel: HPXML::FuelTypeNaturalGas, location: HPXML::LocationConditionedSpace, tank_vol: 50, ef: 0.67 }])
      elsif program_version == ES::SFPacificVer3_0
        _check_water_heater(hpxml_bldg, [{ whtype: HPXML::WaterHeaterTypeStorage, fuel: HPXML::FuelTypeNaturalGas, location: HPXML::LocationConditionedSpace, tank_vol: 50, ef: 0.80 }])
      elsif [ES::SFOregonWashingtonVer3_2, ES::MFOregonWashingtonVer1_2].include? program_version
        _check_water_heater(hpxml_bldg, [{ whtype: HPXML::WaterHeaterTypeTankless, fuel: HPXML::FuelTypeNaturalGas, location: HPXML::LocationConditionedSpace, ef: 0.91 }])
      elsif [ZERH::SFVer2, ZERH::MFVer2, ES::SFNationalVer3_3, ES::MFNationalVer1_3].include? program_version
        _check_water_heater(hpxml_bldg, [{ whtype: HPXML::WaterHeaterTypeTankless, fuel: HPXML::FuelTypeNaturalGas, location: HPXML::LocationConditionedSpace, uef: 0.95 }])
      elsif [ES::SFNationalVer3_2, ES::MFNationalVer1_2].include? program_version
        _check_water_heater(hpxml_bldg, [{ whtype: HPXML::WaterHeaterTypeTankless, fuel: HPXML::FuelTypeNaturalGas, location: HPXML::LocationConditionedSpace, uef: 0.90 }])
      elsif [ES::SFFloridaVer3_1, ES::SFNationalVer3_0, ES::SFNationalVer3_1].include? program_version
        _check_water_heater(hpxml_bldg, [{ whtype: HPXML::WaterHeaterTypeStorage, fuel: HPXML::FuelTypeNaturalGas, location: HPXML::LocationConditionedSpace, tank_vol: 50, ef: 0.59 }])
      else
        fail "Unhandled program version: #{program_version}"
      end
      _check_hot_water_distribution(hpxml_bldg, disttype: HPXML::DHWDistTypeStandard, pipe_r: pipe_r_value(program_version, false), pipe_l: 93.5)
      _check_water_fixtures(hpxml_bldg, low_flow_shower: is_low_flow(program_version, hpxml_bldg), low_flow_faucet: is_low_flow(program_version, hpxml_bldg))
      _check_drain_water_heat_recovery(hpxml_bldg)
    end
  end

  def test_water_heating_tank_oil
    [*ES::AllVersions, *ZERH::AllVersions].each do |program_version|
      _convert_to_es_zerh('base-dhw-tank-oil.xml', program_version)
      hpxml_bldg = _test_ruleset(program_version)
      if [ES::MFNationalVer1_0, ES::MFNationalVer1_1].include? program_version
        _check_water_heater(hpxml_bldg, [{ whtype: HPXML::WaterHeaterTypeStorage, fuel: HPXML::FuelTypeOil, location: HPXML::LocationConditionedSpace, tank_vol: 30, ef: 0.64 }])
      elsif program_version == ES::SFPacificVer3_0
        _check_water_heater(hpxml_bldg, [{ whtype: HPXML::WaterHeaterTypeStorage, fuel: HPXML::FuelTypeNaturalGas, location: HPXML::LocationConditionedSpace, tank_vol: 30, ef: 0.80 }])
      elsif [ES::SFOregonWashingtonVer3_2, ES::MFOregonWashingtonVer1_2].include? program_version
        _check_water_heater(hpxml_bldg, [{ whtype: HPXML::WaterHeaterTypeHeatPump, fuel: HPXML::FuelTypeElectricity, location: HPXML::LocationConditionedSpace, tank_vol: 60, ef: 2.50 }])
      elsif [ES::SFNationalVer3_2, ES::MFNationalVer1_2].include? program_version
        _check_water_heater(hpxml_bldg, [{ whtype: HPXML::WaterHeaterTypeTankless, fuel: HPXML::FuelTypeNaturalGas, location: HPXML::LocationConditionedSpace, uef: 0.90 }])
      elsif [ZERH::Ver1].include? program_version
        _check_water_heater(hpxml_bldg, [{ whtype: HPXML::WaterHeaterTypeStorage, fuel: HPXML::FuelTypeOil, location: HPXML::LocationConditionedSpace, tank_vol: 30, ef: 0.6 }])
      elsif [ZERH::SFVer2, ZERH::MFVer2, ES::SFNationalVer3_3, ES::MFNationalVer1_3].include? program_version
        _check_water_heater(hpxml_bldg, [{ whtype: HPXML::WaterHeaterTypeTankless, fuel: HPXML::FuelTypeNaturalGas, location: HPXML::LocationConditionedSpace, uef: 0.95 }])
      elsif [ES::SFFloridaVer3_1, ES::SFOregonWashingtonVer3_2, ES::SFNationalVer3_0, ES::SFNationalVer3_1,
             ES::MFOregonWashingtonVer1_2].include? program_version
        _check_water_heater(hpxml_bldg, [{ whtype: HPXML::WaterHeaterTypeStorage, fuel: HPXML::FuelTypeOil, location: HPXML::LocationConditionedSpace, tank_vol: 30, ef: 0.55 }])
      else
        fail "Unhandled program version: #{program_version}"
      end
      _check_hot_water_distribution(hpxml_bldg, disttype: HPXML::DHWDistTypeStandard, pipe_r: pipe_r_value(program_version, false), pipe_l: 93.5)
      _check_water_fixtures(hpxml_bldg, low_flow_shower: is_low_flow(program_version, hpxml_bldg), low_flow_faucet: is_low_flow(program_version, hpxml_bldg))
      _check_drain_water_heat_recovery(hpxml_bldg)
    end
  end

  def test_water_heating_tank_heat_pump
    [*ES::AllVersions, *ZERH::AllVersions].each do |program_version|
      _convert_to_es_zerh('base-dhw-tank-heat-pump-confined-space.xml', program_version)
      hpxml_bldg = _test_ruleset(program_version)
      if [ES::MFNationalVer1_0, ES::MFNationalVer1_1].include? program_version
        _check_water_heater(hpxml_bldg, [{ whtype: HPXML::WaterHeaterTypeStorage, fuel: HPXML::FuelTypeElectricity, location: HPXML::LocationConditionedSpace, tank_vol: 80, ef: 0.95 }])
      elsif program_version == ES::SFPacificVer3_0
        _check_water_heater(hpxml_bldg, [{ whtype: HPXML::WaterHeaterTypeStorage, fuel: HPXML::FuelTypeElectricity, location: HPXML::LocationConditionedSpace, tank_vol: 80, ef: 0.90 }])
        _check_solar_thermal_system(hpxml_bldg, [{ system_type: HPXML::SolarThermalSystemTypeHotWater, solar_fraction: 0.90 }])
      elsif [ES::SFOregonWashingtonVer3_2, ES::MFOregonWashingtonVer1_2].include? program_version
        _check_water_heater(hpxml_bldg, [{ whtype: HPXML::WaterHeaterTypeHeatPump, fuel: HPXML::FuelTypeElectricity, location: HPXML::LocationConditionedSpace, tank_vol: 60, ef: 2.50 }])
      elsif [ZERH::Ver1].include? program_version
        _check_water_heater(hpxml_bldg, [{ whtype: HPXML::WaterHeaterTypeHeatPump, fuel: HPXML::FuelTypeElectricity, location: HPXML::LocationConditionedSpace, tank_vol: 80, ef: 2.00 }])
      elsif [ZERH::SFVer2].include? program_version
        _check_water_heater(hpxml_bldg, [{ whtype: HPXML::WaterHeaterTypeHeatPump, fuel: HPXML::FuelTypeElectricity, location: HPXML::LocationConditionedSpace, tank_vol: 80, uef: 2.57, fhr: 56 }])
      elsif [ES::SFNationalVer3_2, ES::SFNationalVer3_3].include? program_version
        _check_water_heater(hpxml_bldg, [{ whtype: HPXML::WaterHeaterTypeHeatPump, fuel: HPXML::FuelTypeElectricity, location: HPXML::LocationConditionedSpace, tank_vol: 80, uef: 2.20, fhr: 56 }])
      elsif program_version == ES::MFNationalVer1_2
        _check_water_heater(hpxml_bldg, [{ whtype: HPXML::WaterHeaterTypeHeatPump, fuel: HPXML::FuelTypeElectricity, location: HPXML::LocationConditionedSpace, tank_vol: 80, uef: 1.49, fhr: 56 }])
      elsif program_version == ES::MFNationalVer1_3
        _check_water_heater(hpxml_bldg, [{ whtype: HPXML::WaterHeaterTypeHeatPump, fuel: HPXML::FuelTypeElectricity, location: HPXML::LocationConditionedSpace, tank_vol: 80, uef: 2.50, fhr: 56 }])
      elsif program_version == ZERH::MFVer2
        _check_water_heater(hpxml_bldg, [{ whtype: HPXML::WaterHeaterTypeHeatPump, fuel: HPXML::FuelTypeElectricity, frac_load: 1.0, location: HPXML::LocationConditionedSpace, tank_vol: 80, uef: 1.95, fhr: 56 }])
      elsif [ES::SFFloridaVer3_1, ES::SFNationalVer3_0, ES::SFNationalVer3_1].include? program_version
        _check_water_heater(hpxml_bldg, [{ whtype: HPXML::WaterHeaterTypeStorage, fuel: HPXML::FuelTypeElectricity, location: HPXML::LocationConditionedSpace, tank_vol: 80, ef: 0.89 }])
      else
        fail "Unhandled program version: #{program_version}"
      end
      _check_hot_water_distribution(hpxml_bldg, disttype: HPXML::DHWDistTypeStandard, pipe_r: pipe_r_value(program_version, false), pipe_l: 93.5)
      _check_water_fixtures(hpxml_bldg, low_flow_shower: is_low_flow(program_version, hpxml_bldg), low_flow_faucet: is_low_flow(program_version, hpxml_bldg))
      _check_drain_water_heat_recovery(hpxml_bldg)
    end
  end

  def test_water_heating_tankless_electric
    [*ES::AllVersions, *ZERH::AllVersions].each do |program_version|
      _convert_to_es_zerh('base-dhw-tankless-electric-ef.xml', program_version)
      hpxml_bldg = _test_ruleset(program_version)
      if [ES::MFNationalVer1_0, ES::MFNationalVer1_1].include? program_version
        _check_water_heater(hpxml_bldg, [{ whtype: HPXML::WaterHeaterTypeStorage, fuel: HPXML::FuelTypeElectricity, location: HPXML::LocationConditionedSpace, tank_vol: 60, ef: 0.95 }])
      elsif program_version == ES::SFPacificVer3_0
        _check_water_heater(hpxml_bldg, [{ whtype: HPXML::WaterHeaterTypeStorage, fuel: HPXML::FuelTypeElectricity, location: HPXML::LocationConditionedSpace, tank_vol: 50, ef: 0.90 }])
        _check_solar_thermal_system(hpxml_bldg, [{ system_type: HPXML::SolarThermalSystemTypeHotWater, solar_fraction: 0.90 }])
      elsif [ES::SFOregonWashingtonVer3_2, ES::MFOregonWashingtonVer1_2].include? program_version
        _check_water_heater(hpxml_bldg, [{ whtype: HPXML::WaterHeaterTypeHeatPump, fuel: HPXML::FuelTypeElectricity, location: HPXML::LocationConditionedSpace, tank_vol: 60, ef: 2.50 }])
      elsif [ZERH::Ver1].include? program_version
        _check_water_heater(hpxml_bldg, [{ whtype: HPXML::WaterHeaterTypeHeatPump, fuel: HPXML::FuelTypeElectricity, location: HPXML::LocationConditionedSpace, tank_vol: 60, ef: 2.00 }])
      elsif [ZERH::SFVer2].include? program_version
        _check_water_heater(hpxml_bldg, [{ whtype: HPXML::WaterHeaterTypeHeatPump, fuel: HPXML::FuelTypeElectricity, location: HPXML::LocationConditionedSpace, tank_vol: 60, uef: 2.57, fhr: 63 }])
      elsif [ES::SFNationalVer3_2, ES::SFNationalVer3_3].include? program_version
        _check_water_heater(hpxml_bldg, [{ whtype: HPXML::WaterHeaterTypeHeatPump, fuel: HPXML::FuelTypeElectricity, location: HPXML::LocationConditionedSpace, tank_vol: 60, uef: 2.20, fhr: 63 }])
      elsif program_version == ES::MFNationalVer1_2
        _check_water_heater(hpxml_bldg, [{ whtype: HPXML::WaterHeaterTypeHeatPump, fuel: HPXML::FuelTypeElectricity, location: HPXML::LocationConditionedSpace, tank_vol: 60, uef: 1.49, fhr: 63 }])
      elsif program_version == ES::MFNationalVer1_3
        _check_water_heater(hpxml_bldg, [{ whtype: HPXML::WaterHeaterTypeHeatPump, fuel: HPXML::FuelTypeElectricity, location: HPXML::LocationConditionedSpace, tank_vol: 60, uef: 2.50, fhr: 63 }])
      elsif program_version == ZERH::MFVer2
        _check_water_heater(hpxml_bldg, [{ whtype: HPXML::WaterHeaterTypeHeatPump, fuel: HPXML::FuelTypeElectricity, location: HPXML::LocationConditionedSpace, tank_vol: 60, uef: 1.95, fhr: 63 }])
      elsif [ES::SFFloridaVer3_1, ES::SFNationalVer3_0, ES::SFNationalVer3_1].include? program_version
        _check_water_heater(hpxml_bldg, [{ whtype: HPXML::WaterHeaterTypeStorage, fuel: HPXML::FuelTypeElectricity, location: HPXML::LocationConditionedSpace, tank_vol: 60, ef: 0.91 }])
      else
        fail "Unhandled program version: #{program_version}"
      end
      _check_hot_water_distribution(hpxml_bldg, disttype: HPXML::DHWDistTypeStandard, pipe_r: pipe_r_value(program_version, false), pipe_l: 93.5)
      _check_water_fixtures(hpxml_bldg, low_flow_shower: is_low_flow(program_version, hpxml_bldg), low_flow_faucet: is_low_flow(program_version, hpxml_bldg))
      _check_drain_water_heat_recovery(hpxml_bldg)
    end
  end

  def test_water_heating_tankless_gas
    [*ES::AllVersions, *ZERH::AllVersions].each do |program_version|
      _convert_to_es_zerh('base-dhw-tankless-gas-ef.xml', program_version)
      hpxml_bldg = _test_ruleset(program_version)
      if [ES::MFNationalVer1_0, ES::MFNationalVer1_1].include? program_version
        _check_water_heater(hpxml_bldg, [{ whtype: HPXML::WaterHeaterTypeStorage, fuel: HPXML::FuelTypeNaturalGas, location: HPXML::LocationConditionedSpace, tank_vol: 50, ef: 0.67 }])
      elsif program_version == ES::SFPacificVer3_0
        _check_water_heater(hpxml_bldg, [{ whtype: HPXML::WaterHeaterTypeStorage, fuel: HPXML::FuelTypeNaturalGas, location: HPXML::LocationConditionedSpace, tank_vol: 50, ef: 0.80 }])
      elsif [ES::SFOregonWashingtonVer3_2, ES::MFOregonWashingtonVer1_2].include? program_version
        _check_water_heater(hpxml_bldg, [{ whtype: HPXML::WaterHeaterTypeTankless, fuel: HPXML::FuelTypeNaturalGas, location: HPXML::LocationConditionedSpace, ef: 0.91 }])
      elsif [ZERH::Ver1].include? program_version
        _check_water_heater(hpxml_bldg, [{ whtype: HPXML::WaterHeaterTypeStorage, fuel: HPXML::FuelTypeNaturalGas, location: HPXML::LocationConditionedSpace, tank_vol: 40, ef: 0.67 }])
      elsif [ES::SFNationalVer3_2, ES::MFNationalVer1_2].include? program_version
        _check_water_heater(hpxml_bldg, [{ whtype: HPXML::WaterHeaterTypeTankless, fuel: HPXML::FuelTypeNaturalGas, location: HPXML::LocationConditionedSpace, uef: 0.90 }])
      elsif [ZERH::SFVer2, ZERH::MFVer2, ES::SFNationalVer3_3, ES::MFNationalVer1_3].include? program_version
        _check_water_heater(hpxml_bldg, [{ whtype: HPXML::WaterHeaterTypeTankless, fuel: HPXML::FuelTypeNaturalGas, location: HPXML::LocationConditionedSpace, uef: 0.95 }])
      elsif [ES::SFFloridaVer3_1, ES::SFNationalVer3_0, ES::SFNationalVer3_1].include? program_version
        _check_water_heater(hpxml_bldg, [{ whtype: HPXML::WaterHeaterTypeStorage, fuel: HPXML::FuelTypeNaturalGas, location: HPXML::LocationConditionedSpace, tank_vol: 50, ef: 0.59 }])
      else
        fail "Unhandled program version: #{program_version}"
      end
      _check_hot_water_distribution(hpxml_bldg, disttype: HPXML::DHWDistTypeStandard, pipe_r: pipe_r_value(program_version, false), pipe_l: 93.5)
      _check_water_fixtures(hpxml_bldg, low_flow_shower: is_low_flow(program_version, hpxml_bldg), low_flow_faucet: is_low_flow(program_version, hpxml_bldg))
      _check_drain_water_heat_recovery(hpxml_bldg)
    end
  end

  def test_multiple_water_heating
    [*ES::AllVersions, *ZERH::AllVersions].each do |program_version|
      _convert_to_es_zerh('base-dhw-multiple.xml', program_version)
      hpxml_bldg = _test_ruleset(program_version)
      if [ES::MFNationalVer1_0, ES::MFNationalVer1_1].include? program_version
        _check_water_heater(hpxml_bldg, [{ whtype: HPXML::WaterHeaterTypeStorage, fuel: HPXML::FuelTypeElectricity, frac_load: 0.2, location: HPXML::LocationConditionedSpace, tank_vol: 40, ef: 0.95 },
                                         { whtype: HPXML::WaterHeaterTypeStorage, fuel: HPXML::FuelTypeNaturalGas, frac_load: 0.2, location: HPXML::LocationConditionedSpace, tank_vol: 50, ef: 0.67 },
                                         { whtype: HPXML::WaterHeaterTypeStorage, fuel: HPXML::FuelTypeElectricity, frac_load: 0.2, location: HPXML::LocationConditionedSpace, tank_vol: 80, ef: 0.95 },
                                         { whtype: HPXML::WaterHeaterTypeStorage, fuel: HPXML::FuelTypeElectricity, frac_load: 0.2, location: HPXML::LocationConditionedSpace, tank_vol: 60, ef: 0.95 },
                                         { whtype: HPXML::WaterHeaterTypeStorage, fuel: HPXML::FuelTypeNaturalGas, frac_load: 0.1, location: HPXML::LocationConditionedSpace, tank_vol: 50, ef: 0.67 },
                                         { whtype: HPXML::WaterHeaterTypeStorage, fuel: HPXML::FuelTypeNaturalGas, frac_load: 0.1, location: HPXML::LocationConditionedSpace, tank_vol: 50, ef: 0.67 }])
      elsif program_version == ES::SFPacificVer3_0
        _check_water_heater(hpxml_bldg, [{ whtype: HPXML::WaterHeaterTypeStorage, fuel: HPXML::FuelTypeElectricity, frac_load: 0.2, location: HPXML::LocationConditionedSpace, tank_vol: 40, ef: 0.90 },
                                         { whtype: HPXML::WaterHeaterTypeStorage, fuel: HPXML::FuelTypeNaturalGas, frac_load: 0.2, location: HPXML::LocationConditionedSpace, tank_vol: 50, ef: 0.80 },
                                         { whtype: HPXML::WaterHeaterTypeStorage, fuel: HPXML::FuelTypeElectricity, frac_load: 0.2, location: HPXML::LocationConditionedSpace, tank_vol: 80, ef: 0.90 },
                                         { whtype: HPXML::WaterHeaterTypeStorage, fuel: HPXML::FuelTypeElectricity, frac_load: 0.2, location: HPXML::LocationConditionedSpace, tank_vol: 50, ef: 0.90 },
                                         { whtype: HPXML::WaterHeaterTypeStorage, fuel: HPXML::FuelTypeNaturalGas, frac_load: 0.1, location: HPXML::LocationConditionedSpace, tank_vol: 50, ef: 0.80 },
                                         { whtype: HPXML::WaterHeaterTypeStorage, fuel: HPXML::FuelTypeNaturalGas, frac_load: 0.1, location: HPXML::LocationConditionedSpace, tank_vol: 50, ef: 0.80 }])
        _check_solar_thermal_system(hpxml_bldg, [{ system_type: HPXML::SolarThermalSystemTypeHotWater, solar_fraction: 0.90 }])
      elsif [ES::SFOregonWashingtonVer3_2, ES::MFOregonWashingtonVer1_2].include? program_version
        _check_water_heater(hpxml_bldg, [{ whtype: HPXML::WaterHeaterTypeHeatPump, fuel: HPXML::FuelTypeElectricity, frac_load: 0.2, location: HPXML::LocationConditionedSpace, tank_vol: 60, ef: 2.50 },
                                         { whtype: HPXML::WaterHeaterTypeTankless, fuel: HPXML::FuelTypeNaturalGas, frac_load: 0.2, location: HPXML::LocationConditionedSpace, ef: 0.91 },
                                         { whtype: HPXML::WaterHeaterTypeHeatPump, fuel: HPXML::FuelTypeElectricity, frac_load: 0.2, location: HPXML::LocationConditionedSpace, tank_vol: 60, ef: 2.50 },
                                         { whtype: HPXML::WaterHeaterTypeHeatPump, fuel: HPXML::FuelTypeElectricity, frac_load: 0.2, location: HPXML::LocationConditionedSpace, tank_vol: 60, ef: 2.50 },
                                         { whtype: HPXML::WaterHeaterTypeTankless, fuel: HPXML::FuelTypeNaturalGas, frac_load: 0.1, location: HPXML::LocationConditionedSpace, ef: 0.91 },
                                         { whtype: HPXML::WaterHeaterTypeTankless, fuel: HPXML::FuelTypeNaturalGas, frac_load: 0.1, location: HPXML::LocationConditionedSpace, ef: 0.91 }])
      elsif [ZERH::Ver1].include? program_version
        _check_water_heater(hpxml_bldg, [{ whtype: HPXML::WaterHeaterTypeHeatPump, fuel: HPXML::FuelTypeElectricity, frac_load: 0.2, location: HPXML::LocationConditionedSpace, tank_vol: 40, ef: 2.00 },
                                         { whtype: HPXML::WaterHeaterTypeStorage, fuel: HPXML::FuelTypeNaturalGas, frac_load: 0.2, location: HPXML::LocationConditionedSpace, tank_vol: 50, ef: 0.67 },
                                         { whtype: HPXML::WaterHeaterTypeHeatPump, fuel: HPXML::FuelTypeElectricity, frac_load: 0.2, location: HPXML::LocationConditionedSpace, tank_vol: 80, ef: 2.00 },
                                         { whtype: HPXML::WaterHeaterTypeHeatPump, fuel: HPXML::FuelTypeElectricity, frac_load: 0.2, location: HPXML::LocationConditionedSpace, tank_vol: 60, ef: 2.00 },
                                         { whtype: HPXML::WaterHeaterTypeStorage, fuel: HPXML::FuelTypeNaturalGas, frac_load: 0.1, location: HPXML::LocationConditionedSpace, tank_vol: 40, ef: 0.67 },
                                         { whtype: HPXML::WaterHeaterTypeStorage, fuel: HPXML::FuelTypeNaturalGas, frac_load: 0.1, location: HPXML::LocationConditionedSpace, tank_vol: 50, ef: 0.67 }])
      elsif program_version == ES::SFNationalVer3_2
        _check_water_heater(hpxml_bldg, [{ whtype: HPXML::WaterHeaterTypeHeatPump, fuel: HPXML::FuelTypeElectricity, frac_load: 0.2, location: HPXML::LocationConditionedSpace, tank_vol: 40, uef: 2.20, fhr: 56 },
                                         { whtype: HPXML::WaterHeaterTypeTankless, fuel: HPXML::FuelTypeNaturalGas, frac_load: 0.2, location: HPXML::LocationConditionedSpace, uef: 0.90 },
                                         { whtype: HPXML::WaterHeaterTypeHeatPump, fuel: HPXML::FuelTypeElectricity, frac_load: 0.2, location: HPXML::LocationConditionedSpace, tank_vol: 80, uef: 2.20, fhr: 63 },
                                         { whtype: HPXML::WaterHeaterTypeHeatPump, fuel: HPXML::FuelTypeElectricity, frac_load: 0.2, location: HPXML::LocationConditionedSpace, tank_vol: 60, uef: 2.20, fhr: 63 },
                                         { whtype: HPXML::WaterHeaterTypeTankless, fuel: HPXML::FuelTypeNaturalGas, frac_load: 0.1, location: HPXML::LocationConditionedSpace, uef: 0.90 },
                                         { whtype: HPXML::WaterHeaterTypeTankless, fuel: HPXML::FuelTypeNaturalGas, frac_load: 0.1, location: HPXML::LocationConditionedSpace, uef: 0.90 }])
      elsif program_version == ES::SFNationalVer3_3
        _check_water_heater(hpxml_bldg, [{ whtype: HPXML::WaterHeaterTypeHeatPump, fuel: HPXML::FuelTypeElectricity, frac_load: 0.2, location: HPXML::LocationConditionedSpace, tank_vol: 40, uef: 2.20, fhr: 56 },
                                         { whtype: HPXML::WaterHeaterTypeTankless, fuel: HPXML::FuelTypeNaturalGas, frac_load: 0.2, location: HPXML::LocationConditionedSpace, uef: 0.95 },
                                         { whtype: HPXML::WaterHeaterTypeHeatPump, fuel: HPXML::FuelTypeElectricity, frac_load: 0.2, location: HPXML::LocationConditionedSpace, tank_vol: 80, uef: 2.20, fhr: 63 },
                                         { whtype: HPXML::WaterHeaterTypeHeatPump, fuel: HPXML::FuelTypeElectricity, frac_load: 0.2, location: HPXML::LocationConditionedSpace, tank_vol: 60, uef: 2.20, fhr: 63 },
                                         { whtype: HPXML::WaterHeaterTypeTankless, fuel: HPXML::FuelTypeNaturalGas, frac_load: 0.1, location: HPXML::LocationConditionedSpace, uef: 0.95 },
                                         { whtype: HPXML::WaterHeaterTypeTankless, fuel: HPXML::FuelTypeNaturalGas, frac_load: 0.1, location: HPXML::LocationConditionedSpace, uef: 0.95 }])
      elsif program_version == ES::MFNationalVer1_2
        _check_water_heater(hpxml_bldg, [{ whtype: HPXML::WaterHeaterTypeHeatPump, fuel: HPXML::FuelTypeElectricity, frac_load: 0.2, location: HPXML::LocationConditionedSpace, tank_vol: 40, uef: 1.49, fhr: 56 },
                                         { whtype: HPXML::WaterHeaterTypeTankless, fuel: HPXML::FuelTypeNaturalGas, frac_load: 0.2, location: HPXML::LocationConditionedSpace, uef: 0.90 },
                                         { whtype: HPXML::WaterHeaterTypeHeatPump, fuel: HPXML::FuelTypeElectricity, frac_load: 0.2, location: HPXML::LocationConditionedSpace, tank_vol: 80, uef: 1.49, fhr: 63 },
                                         { whtype: HPXML::WaterHeaterTypeHeatPump, fuel: HPXML::FuelTypeElectricity, frac_load: 0.2, location: HPXML::LocationConditionedSpace, tank_vol: 60, uef: 1.49, fhr: 63 },
                                         { whtype: HPXML::WaterHeaterTypeTankless, fuel: HPXML::FuelTypeNaturalGas, frac_load: 0.1, location: HPXML::LocationConditionedSpace, uef: 0.90 },
                                         { whtype: HPXML::WaterHeaterTypeTankless, fuel: HPXML::FuelTypeNaturalGas, frac_load: 0.1, location: HPXML::LocationConditionedSpace, uef: 0.90 }])
      elsif program_version == ES::MFNationalVer1_3
        _check_water_heater(hpxml_bldg, [{ whtype: HPXML::WaterHeaterTypeHeatPump, fuel: HPXML::FuelTypeElectricity, frac_load: 0.2, location: HPXML::LocationConditionedSpace, tank_vol: 40, uef: 2.50, fhr: 56 },
                                         { whtype: HPXML::WaterHeaterTypeTankless, fuel: HPXML::FuelTypeNaturalGas, frac_load: 0.2, location: HPXML::LocationConditionedSpace, uef: 0.95 },
                                         { whtype: HPXML::WaterHeaterTypeHeatPump, fuel: HPXML::FuelTypeElectricity, frac_load: 0.2, location: HPXML::LocationConditionedSpace, tank_vol: 80, uef: 2.50, fhr: 63 },
                                         { whtype: HPXML::WaterHeaterTypeHeatPump, fuel: HPXML::FuelTypeElectricity, frac_load: 0.2, location: HPXML::LocationConditionedSpace, tank_vol: 60, uef: 2.50, fhr: 63 },
                                         { whtype: HPXML::WaterHeaterTypeTankless, fuel: HPXML::FuelTypeNaturalGas, frac_load: 0.1, location: HPXML::LocationConditionedSpace, uef: 0.95 },
                                         { whtype: HPXML::WaterHeaterTypeTankless, fuel: HPXML::FuelTypeNaturalGas, frac_load: 0.1, location: HPXML::LocationConditionedSpace, uef: 0.95 }])
      elsif program_version == ZERH::SFVer2
        _check_water_heater(hpxml_bldg, [{ whtype: HPXML::WaterHeaterTypeHeatPump, fuel: HPXML::FuelTypeElectricity, frac_load: 0.2, location: HPXML::LocationConditionedSpace, tank_vol: 40, uef: 2.57, fhr: 56 },
                                         { whtype: HPXML::WaterHeaterTypeTankless, fuel: HPXML::FuelTypeNaturalGas, frac_load: 0.2, location: HPXML::LocationConditionedSpace, uef: 0.95 },
                                         { whtype: HPXML::WaterHeaterTypeHeatPump, fuel: HPXML::FuelTypeElectricity, frac_load: 0.2, location: HPXML::LocationConditionedSpace, tank_vol: 80, uef: 2.57, fhr: 63 },
                                         { whtype: HPXML::WaterHeaterTypeHeatPump, fuel: HPXML::FuelTypeElectricity, frac_load: 0.2, location: HPXML::LocationConditionedSpace, tank_vol: 60, uef: 2.57, fhr: 63 },
                                         { whtype: HPXML::WaterHeaterTypeTankless, fuel: HPXML::FuelTypeNaturalGas, frac_load: 0.1, location: HPXML::LocationConditionedSpace, uef: 0.95 },
                                         { whtype: HPXML::WaterHeaterTypeTankless, fuel: HPXML::FuelTypeNaturalGas, frac_load: 0.1, location: HPXML::LocationConditionedSpace, uef: 0.95 }])
      elsif program_version == ZERH::MFVer2
        _check_water_heater(hpxml_bldg, [{ whtype: HPXML::WaterHeaterTypeHeatPump, fuel: HPXML::FuelTypeElectricity, frac_load: 0.2, location: HPXML::LocationConditionedSpace, tank_vol: 40, uef: 1.95, fhr: 56 },
                                         { whtype: HPXML::WaterHeaterTypeTankless, fuel: HPXML::FuelTypeNaturalGas, frac_load: 0.2, location: HPXML::LocationConditionedSpace, uef: 0.95 },
                                         { whtype: HPXML::WaterHeaterTypeHeatPump, fuel: HPXML::FuelTypeElectricity, frac_load: 0.2, location: HPXML::LocationConditionedSpace, tank_vol: 80, uef: 1.95, fhr: 63 },
                                         { whtype: HPXML::WaterHeaterTypeHeatPump, fuel: HPXML::FuelTypeElectricity, frac_load: 0.2, location: HPXML::LocationConditionedSpace, tank_vol: 60, uef: 1.95, fhr: 63 },
                                         { whtype: HPXML::WaterHeaterTypeTankless, fuel: HPXML::FuelTypeNaturalGas, frac_load: 0.1, location: HPXML::LocationConditionedSpace, uef: 0.95 },
                                         { whtype: HPXML::WaterHeaterTypeTankless, fuel: HPXML::FuelTypeNaturalGas, frac_load: 0.1, location: HPXML::LocationConditionedSpace, uef: 0.95 }])
      elsif [ES::SFFloridaVer3_1, ES::SFNationalVer3_0, ES::SFNationalVer3_1].include? program_version
        _check_water_heater(hpxml_bldg, [{ whtype: HPXML::WaterHeaterTypeStorage, fuel: HPXML::FuelTypeElectricity, frac_load: 0.2, location: HPXML::LocationConditionedSpace, tank_vol: 40, ef: 0.93 },
                                         { whtype: HPXML::WaterHeaterTypeStorage, fuel: HPXML::FuelTypeNaturalGas, frac_load: 0.2, location: HPXML::LocationConditionedSpace, tank_vol: 50, ef: 0.59 },
                                         { whtype: HPXML::WaterHeaterTypeStorage, fuel: HPXML::FuelTypeElectricity, frac_load: 0.2, location: HPXML::LocationConditionedSpace, tank_vol: 80, ef: 0.89 },
                                         { whtype: HPXML::WaterHeaterTypeStorage, fuel: HPXML::FuelTypeElectricity, frac_load: 0.2, location: HPXML::LocationConditionedSpace, tank_vol: 60, ef: 0.91 },
                                         { whtype: HPXML::WaterHeaterTypeStorage, fuel: HPXML::FuelTypeNaturalGas, frac_load: 0.1, location: HPXML::LocationConditionedSpace, tank_vol: 50, ef: 0.59 },
                                         { whtype: HPXML::WaterHeaterTypeStorage, fuel: HPXML::FuelTypeNaturalGas, frac_load: 0.1, location: HPXML::LocationConditionedSpace, tank_vol: 50, ef: 0.59 }])
      else
        fail "Unhandled program version: #{program_version}"
      end
      _check_hot_water_distribution(hpxml_bldg, disttype: HPXML::DHWDistTypeStandard, pipe_r: pipe_r_value(program_version, false), pipe_l: 93.5)
      _check_water_fixtures(hpxml_bldg, low_flow_shower: is_low_flow(program_version, hpxml_bldg), low_flow_faucet: is_low_flow(program_version, hpxml_bldg))
      _check_drain_water_heat_recovery(hpxml_bldg)
    end
  end

  def test_indirect_water_heating
    [*ES::AllVersions, *ZERH::AllVersions].each do |program_version|
      _convert_to_es_zerh('base-dhw-indirect-standbyloss.xml', program_version)
      hpxml_bldg = _test_ruleset(program_version)
      if [ES::MFNationalVer1_0, ES::MFNationalVer1_1, ZERH::Ver1].include? program_version
        _check_water_heater(hpxml_bldg, [{ whtype: HPXML::WaterHeaterTypeStorage, fuel: HPXML::FuelTypeNaturalGas, location: HPXML::LocationConditionedSpace, tank_vol: 50, ef: 0.67 }])
      elsif program_version == ES::SFPacificVer3_0
        _check_water_heater(hpxml_bldg, [{ whtype: HPXML::WaterHeaterTypeStorage, fuel: HPXML::FuelTypeNaturalGas, location: HPXML::LocationConditionedSpace, tank_vol: 50, ef: 0.80 }])
      elsif [ES::SFOregonWashingtonVer3_2, ES::MFOregonWashingtonVer1_2].include? program_version
        _check_water_heater(hpxml_bldg, [{ whtype: HPXML::WaterHeaterTypeTankless, fuel: HPXML::FuelTypeNaturalGas, location: HPXML::LocationConditionedSpace, ef: 0.91 }])
      elsif [ES::SFNationalVer3_2, ES::MFNationalVer1_2].include? program_version
        _check_water_heater(hpxml_bldg, [{ whtype: HPXML::WaterHeaterTypeTankless, fuel: HPXML::FuelTypeNaturalGas, location: HPXML::LocationConditionedSpace, uef: 0.90 }])
      elsif [ZERH::SFVer2, ZERH::MFVer2, ES::SFNationalVer3_3, ES::MFNationalVer1_3].include? program_version
        _check_water_heater(hpxml_bldg, [{ whtype: HPXML::WaterHeaterTypeTankless, fuel: HPXML::FuelTypeNaturalGas, location: HPXML::LocationConditionedSpace, uef: 0.95 }])
      elsif [ES::SFFloridaVer3_1, ES::SFNationalVer3_0, ES::SFNationalVer3_1].include? program_version
        _check_water_heater(hpxml_bldg, [{ whtype: HPXML::WaterHeaterTypeStorage, fuel: HPXML::FuelTypeNaturalGas, location: HPXML::LocationConditionedSpace, tank_vol: 50, ef: 0.59 }])
      else
        fail "Unhandled program version: #{program_version}"
      end
      _check_hot_water_distribution(hpxml_bldg, disttype: HPXML::DHWDistTypeStandard, pipe_r: pipe_r_value(program_version, false), pipe_l: 93.5)
      _check_water_fixtures(hpxml_bldg, low_flow_shower: is_low_flow(program_version, hpxml_bldg), low_flow_faucet: is_low_flow(program_version, hpxml_bldg))
      _check_drain_water_heat_recovery(hpxml_bldg)
    end
  end

  def test_indirect_tankless_coil
    [*ES::AllVersions, *ZERH::AllVersions].each do |program_version|
      _convert_to_es_zerh('base-dhw-combi-tankless.xml', program_version)
      hpxml_bldg = _test_ruleset(program_version)
      if [ES::MFNationalVer1_0, ES::MFNationalVer1_1].include? program_version
        _check_water_heater(hpxml_bldg, [{ whtype: HPXML::WaterHeaterTypeStorage, fuel: HPXML::FuelTypeNaturalGas, location: HPXML::LocationConditionedSpace, tank_vol: 50, ef: 0.67 }])
      elsif program_version == ES::SFPacificVer3_0
        _check_water_heater(hpxml_bldg, [{ whtype: HPXML::WaterHeaterTypeStorage, fuel: HPXML::FuelTypeNaturalGas, location: HPXML::LocationConditionedSpace, tank_vol: 50, ef: 0.80 }])
      elsif [ES::SFOregonWashingtonVer3_2, ES::MFOregonWashingtonVer1_2].include? program_version
        _check_water_heater(hpxml_bldg, [{ whtype: HPXML::WaterHeaterTypeTankless, fuel: HPXML::FuelTypeNaturalGas, location: HPXML::LocationConditionedSpace, ef: 0.91 }])
      elsif [ZERH::Ver1].include? program_version
        _check_water_heater(hpxml_bldg, [{ whtype: HPXML::WaterHeaterTypeStorage, fuel: HPXML::FuelTypeNaturalGas, location: HPXML::LocationConditionedSpace, tank_vol: 40, ef: 0.67 }])
      elsif [ES::SFNationalVer3_2, ES::MFNationalVer1_2].include? program_version
        _check_water_heater(hpxml_bldg, [{ whtype: HPXML::WaterHeaterTypeTankless, fuel: HPXML::FuelTypeNaturalGas, location: HPXML::LocationConditionedSpace, uef: 0.90 }])
      elsif [ZERH::SFVer2, ZERH::MFVer2, ES::SFNationalVer3_3, ES::MFNationalVer1_3].include? program_version
        _check_water_heater(hpxml_bldg, [{ whtype: HPXML::WaterHeaterTypeTankless, fuel: HPXML::FuelTypeNaturalGas, location: HPXML::LocationConditionedSpace, uef: 0.95 }])
      elsif [ES::SFFloridaVer3_1, ES::SFNationalVer3_0, ES::SFNationalVer3_1].include? program_version
        _check_water_heater(hpxml_bldg, [{ whtype: HPXML::WaterHeaterTypeStorage, fuel: HPXML::FuelTypeNaturalGas, location: HPXML::LocationConditionedSpace, tank_vol: 50, ef: 0.59 }])
      else
        fail "Unhandled program version: #{program_version}"
      end
      _check_hot_water_distribution(hpxml_bldg, disttype: HPXML::DHWDistTypeStandard, pipe_r: pipe_r_value(program_version, false), pipe_l: 93.5)
      _check_water_fixtures(hpxml_bldg, low_flow_shower: is_low_flow(program_version, hpxml_bldg), low_flow_faucet: is_low_flow(program_version, hpxml_bldg))
      _check_drain_water_heat_recovery(hpxml_bldg)
    end
  end

  def test_water_heating_recirc
    [*ES::AllVersions, *ZERH::AllVersions].each do |program_version|
      _convert_to_es_zerh('base-dhw-recirc-demand.xml', program_version)
      hpxml_bldg = _test_ruleset(program_version)
      if [ES::MFNationalVer1_0, ES::MFNationalVer1_1].include? program_version
        _check_water_heater(hpxml_bldg, [{ whtype: HPXML::WaterHeaterTypeStorage, fuel: HPXML::FuelTypeElectricity, location: HPXML::LocationConditionedSpace, tank_vol: 40, ef: 0.95 }])
      elsif program_version == ES::SFPacificVer3_0
        _check_water_heater(hpxml_bldg, [{ whtype: HPXML::WaterHeaterTypeStorage, fuel: HPXML::FuelTypeElectricity, location: HPXML::LocationConditionedSpace, tank_vol: 40, ef: 0.90 }])
      elsif [ES::SFOregonWashingtonVer3_2, ES::MFOregonWashingtonVer1_2].include? program_version
        _check_water_heater(hpxml_bldg, [{ whtype: HPXML::WaterHeaterTypeHeatPump, fuel: HPXML::FuelTypeElectricity, frac_load: 1.0, location: HPXML::LocationConditionedSpace, tank_vol: 60, ef: 2.50 }])
      elsif [ZERH::Ver1].include? program_version
        _check_water_heater(hpxml_bldg, [{ whtype: HPXML::WaterHeaterTypeHeatPump, fuel: HPXML::FuelTypeElectricity, frac_load: 1.0, location: HPXML::LocationConditionedSpace, tank_vol: 40, ef: 2.00 }])
      elsif [ZERH::SFVer2].include? program_version
        _check_water_heater(hpxml_bldg, [{ whtype: HPXML::WaterHeaterTypeHeatPump, fuel: HPXML::FuelTypeElectricity, frac_load: 1.0, location: HPXML::LocationConditionedSpace, tank_vol: 40, uef: 2.57, fhr: 56 }])
      elsif [ES::SFNationalVer3_2, ES::SFNationalVer3_3].include? program_version
        _check_water_heater(hpxml_bldg, [{ whtype: HPXML::WaterHeaterTypeHeatPump, fuel: HPXML::FuelTypeElectricity, frac_load: 1.0, location: HPXML::LocationConditionedSpace, tank_vol: 40, uef: 2.20, fhr: 56 }])
      elsif program_version == ES::MFNationalVer1_2
        _check_water_heater(hpxml_bldg, [{ whtype: HPXML::WaterHeaterTypeHeatPump, fuel: HPXML::FuelTypeElectricity, frac_load: 1.0, location: HPXML::LocationConditionedSpace, tank_vol: 40, uef: 1.49, fhr: 56 }])
      elsif program_version == ES::MFNationalVer1_3
        _check_water_heater(hpxml_bldg, [{ whtype: HPXML::WaterHeaterTypeHeatPump, fuel: HPXML::FuelTypeElectricity, frac_load: 1.0, location: HPXML::LocationConditionedSpace, tank_vol: 40, uef: 2.50, fhr: 56 }])
      elsif program_version == ZERH::MFVer2
        _check_water_heater(hpxml_bldg, [{ whtype: HPXML::WaterHeaterTypeHeatPump, fuel: HPXML::FuelTypeElectricity, frac_load: 1.0, location: HPXML::LocationConditionedSpace, tank_vol: 40, uef: 1.95, fhr: 56 }])
      elsif [ES::SFFloridaVer3_1, ES::SFNationalVer3_0, ES::SFNationalVer3_1].include? program_version
        _check_water_heater(hpxml_bldg, [{ whtype: HPXML::WaterHeaterTypeStorage, fuel: HPXML::FuelTypeElectricity, location: HPXML::LocationConditionedSpace, tank_vol: 40, ef: 0.93 }])
      else
        fail "Unhandled program version: #{program_version}"
      end
      _check_hot_water_distribution(hpxml_bldg, disttype: HPXML::DHWDistTypeStandard, pipe_r: pipe_r_value(program_version, false), pipe_l: 93.5)
      _check_water_fixtures(hpxml_bldg, low_flow_shower: is_low_flow(program_version, hpxml_bldg), low_flow_faucet: is_low_flow(program_version, hpxml_bldg))
      _check_drain_water_heat_recovery(hpxml_bldg)
    end
  end

  def test_shared_water_heating_recirc
    [*ES::AllVersions, *ZERH::AllVersions].each do |program_version|
      _convert_to_es_zerh('base-bldgtype-mf-unit-shared-water-heater-recirc.xml', program_version)
      hpxml_bldg = _test_ruleset(program_version)
      if [ES::SFNationalVer3_0, ES::SFNationalVer3_1, ES::SFFloridaVer3_1].include? program_version
        _check_water_heater(hpxml_bldg, [{ whtype: HPXML::WaterHeaterTypeStorage, fuel: HPXML::FuelTypeNaturalGas, location: HPXML::LocationConditionedSpace, tank_vol: 120.0, ef: 0.45, n_bedrooms_served: 18 }])
      elsif program_version == ES::SFPacificVer3_0
        _check_water_heater(hpxml_bldg, [{ whtype: HPXML::WaterHeaterTypeStorage, fuel: HPXML::FuelTypeNaturalGas, location: HPXML::LocationConditionedSpace, tank_vol: 120.0, ef: 0.80, n_bedrooms_served: 18 }])
      elsif [ES::SFOregonWashingtonVer3_2, ES::MFOregonWashingtonVer1_2].include? program_version
        _check_water_heater(hpxml_bldg, [{ whtype: HPXML::WaterHeaterTypeTankless, fuel: HPXML::FuelTypeNaturalGas, location: HPXML::LocationConditionedSpace, ef: 0.91, n_bedrooms_served: 18 }])
      elsif [ZERH::SFVer2, ZERH::MFVer2, ES::SFNationalVer3_3, ES::MFNationalVer1_3].include? program_version
        _check_water_heater(hpxml_bldg, [{ whtype: HPXML::WaterHeaterTypeTankless, fuel: HPXML::FuelTypeNaturalGas, location: HPXML::LocationConditionedSpace, uef: 0.95, n_bedrooms_served: 18 }])
      elsif [ES::MFNationalVer1_0, ES::MFNationalVer1_1, ZERH::Ver1].include? program_version
        _check_water_heater(hpxml_bldg, [{ whtype: HPXML::WaterHeaterTypeStorage, fuel: HPXML::FuelTypeNaturalGas, location: HPXML::LocationConditionedSpace, tank_vol: 120.0, ef: 0.77, n_bedrooms_served: 18 }])
      elsif [ES::SFNationalVer3_2, ES::MFNationalVer1_2].include? program_version
        _check_water_heater(hpxml_bldg, [{ whtype: HPXML::WaterHeaterTypeTankless, fuel: HPXML::FuelTypeNaturalGas, location: HPXML::LocationConditionedSpace, uef: 0.90, n_bedrooms_served: 18 }])
      else
        fail "Unhandled program version: #{program_version}"
      end
      _check_hot_water_distribution(hpxml_bldg, disttype: HPXML::DHWDistTypeStandard, pipe_r: pipe_r_value(program_version, true), pipe_l: 70.0, shared_recirc_power: 232.94, shared_recirc_num_bedrooms_served: 18, shared_recirc_control_type: HPXML::DHWRecircControlTypeTimer)
      _check_water_fixtures(hpxml_bldg, low_flow_shower: is_low_flow(program_version, hpxml_bldg), low_flow_faucet: is_low_flow(program_version, hpxml_bldg))
      _check_drain_water_heat_recovery(hpxml_bldg)
    end
  end

  def test_water_fixtures
    [*ES::NationalVersions, *ZERH::AllVersions].each do |program_version|
      # Test in climate zone 4C
      _convert_to_es_zerh('base.xml', program_version)
      hpxml = HPXML.new(hpxml_path: @tmp_hpxml_path)
      hpxml_bldg = hpxml.buildings[0]
      hpxml_bldg.climate_and_risk_zones.climate_zone_ieccs[0].zone = '4C'
      hpxml_bldg.climate_and_risk_zones.weather_station_name = 'Seattle, WA'
      hpxml_bldg.climate_and_risk_zones.weather_station_wmo = 727930
      XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
      hpxml_bldg = _test_ruleset(program_version)
      _check_water_fixtures(hpxml_bldg, low_flow_shower: is_low_flow(program_version, hpxml_bldg), low_flow_faucet: is_low_flow(program_version, hpxml_bldg))
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

  def _check_water_heater(hpxml_bldg, all_expected_values = [])
    assert_equal(all_expected_values.size, hpxml_bldg.water_heating_systems.size)
    hpxml_bldg.water_heating_systems.each_with_index do |water_heater, idx|
      expected_values = all_expected_values[idx]
      assert_equal(expected_values[:whtype], water_heater.water_heater_type)
      assert_equal(expected_values[:location], water_heater.location)
      if expected_values[:fuel].nil?
        assert_nil(water_heater.fuel_type)
      else
        assert_equal(expected_values[:fuel], water_heater.fuel_type)
      end
      if expected_values[:tank_vol].nil?
        assert_nil(water_heater.tank_volume)
      else
        assert_in_epsilon(expected_values[:tank_vol], water_heater.tank_volume, 0.01)
      end
      if expected_values[:ef].nil?
        assert_nil(water_heater.energy_factor)
      else
        assert_in_epsilon(expected_values[:ef], water_heater.energy_factor, 0.01)
      end
      if expected_values[:jacket_r].nil?
        assert_nil(water_heater.jacket_r_value)
      else
        assert_in_epsilon(expected_values[:jacket_r], water_heater.jacket_r_value, 0.01)
      end
      if expected_values[:standby_loss_value].nil?
        assert_nil(water_heater.standby_loss_value)
      else
        assert_equal(HPXML::UnitsDegFPerHour, water_heater.standby_loss_units)
        assert_equal(expected_values[:standby_loss_value], water_heater.standby_loss_value)
      end
      if water_heater.number_of_bedrooms_served.nil?
        assert_nil(expected_values[:n_bedrooms_served])
      else
        assert_equal(expected_values[:n_bedrooms_served], water_heater.number_of_bedrooms_served)
      end
      frac_load = expected_values[:frac_load].nil? ? 1.0 : expected_values[:frac_load]
      assert_equal(frac_load, water_heater.fraction_dhw_load_served)
      if expected_values[:uef].nil?
        assert_nil(water_heater.uniform_energy_factor)
      else
        assert_equal(expected_values[:uef], water_heater.uniform_energy_factor)
      end
      if expected_values[:fhr].nil?
        assert_nil(water_heater.first_hour_rating)
      else
        assert_equal(expected_values[:fhr], water_heater.first_hour_rating)
      end
      if expected_values[:whtype] == HPXML::WaterHeaterTypeHeatPump
        assert_equal(false, water_heater.hpwh_confined_space_without_mitigation)
      else
        assert_nil(water_heater.hpwh_confined_space_without_mitigation)
        assert_nil(water_heater.hpwh_containment_volume)
      end
    end
  end

  def _check_hot_water_distribution(hpxml_bldg, disttype:, pipe_r:, pipe_l: nil, recirc_control: nil, recirc_loop_l: nil, recirc_branch_l: nil, recirc_pump_power: nil,
                                    shared_recirc_power: nil, shared_recirc_num_bedrooms_served: nil, shared_recirc_control_type: nil)
    assert_equal(1, hpxml_bldg.hot_water_distributions.size)
    hot_water_distribution = hpxml_bldg.hot_water_distributions[0]
    assert_equal(disttype, hot_water_distribution.system_type)
    assert_in_epsilon(pipe_r, hot_water_distribution.pipe_r_value, 0.01)
    if pipe_l.nil?
      assert_nil(hot_water_distribution.standard_piping_length)
    else
      assert_in_epsilon(pipe_l, hot_water_distribution.standard_piping_length, 0.01)
    end
    if recirc_control.nil?
      assert_nil(hot_water_distribution.recirculation_control_type)
    else
      assert_equal(recirc_control, hot_water_distribution.recirculation_control_type)
    end
    if recirc_loop_l.nil?
      assert_nil(hot_water_distribution.recirculation_piping_loop_length)
    else
      assert_in_epsilon(recirc_loop_l, hot_water_distribution.recirculation_piping_loop_length, 0.01)
    end
    if recirc_branch_l.nil?
      assert_nil(hot_water_distribution.recirculation_branch_piping_length)
    else
      assert_in_epsilon(recirc_branch_l, hot_water_distribution.recirculation_branch_piping_length, 0.01)
    end
    if recirc_pump_power.nil?
      assert_nil(hot_water_distribution.recirculation_pump_power)
    else
      assert_in_epsilon(recirc_pump_power, hot_water_distribution.recirculation_pump_power, 0.01)
    end
    if shared_recirc_power.nil?
      assert_nil(hot_water_distribution.shared_recirculation_pump_power)
    else
      assert_in_epsilon(shared_recirc_power, hot_water_distribution.shared_recirculation_pump_power, 0.01)
    end
    if shared_recirc_num_bedrooms_served.nil?
      assert_nil(hot_water_distribution.shared_recirculation_number_of_bedrooms_served)
    else
      assert_equal(shared_recirc_num_bedrooms_served, hot_water_distribution.shared_recirculation_number_of_bedrooms_served)
    end
    if shared_recirc_control_type.nil?
      assert_nil(hot_water_distribution.shared_recirculation_control_type)
    else
      assert_equal(shared_recirc_control_type, hot_water_distribution.shared_recirculation_control_type)
    end
  end

  def _check_water_fixtures(hpxml_bldg, low_flow_shower:, low_flow_faucet:)
    assert_equal(2, hpxml_bldg.water_fixtures.size)
    hpxml_bldg.water_fixtures.each do |water_fixture|
      if water_fixture.water_fixture_type == HPXML::WaterFixtureTypeShowerhead
        assert_equal(low_flow_shower, water_fixture.low_flow)
      elsif water_fixture.water_fixture_type == HPXML::WaterFixtureTypeFaucet
        assert_equal(low_flow_faucet, water_fixture.low_flow)
      end
    end
  end

  def _check_drain_water_heat_recovery(hpxml_bldg, facilities_connected: nil, equal_flow: nil, efficiency: nil)
    hot_water_distribution = hpxml_bldg.hot_water_distributions[0]
    if facilities_connected.nil?
      assert_nil(hot_water_distribution.dwhr_facilities_connected)
    else
      assert_equal(facilities_connected, hot_water_distribution.dwhr_facilities_connected)
    end
    if equal_flow.nil?
      assert_nil(hot_water_distribution.dwhr_equal_flow)
    else
      assert_equal(equal_flow, hot_water_distribution.dwhr_equal_flow)
    end
    if efficiency.nil?
      assert_nil(hot_water_distribution.dwhr_efficiency)
    else
      assert_equal(efficiency, hot_water_distribution.dwhr_efficiency)
    end
  end

  def _check_solar_thermal_system(hpxml_bldg, systems = [])
    assert_equal(systems.size, hpxml_bldg.solar_thermal_systems.size)
    hpxml_bldg.solar_thermal_systems.each_with_index do |solar_thermal_system, idx|
      if not systems[idx][:system_type].nil?
        assert_equal(solar_thermal_system.system_type, systems[idx][:system_type])
      end
      if not systems[idx][:collector_area].nil?
        assert_equal(Float(solar_thermal_system.collector_area), systems[idx][:collector_area])
      end
      if not systems[idx][:collector_loop_type].nil?
        assert_equal(solar_thermal_system.collector_loop_type, systems[idx][:collector_loop_type])
      end
      if not systems[idx][:collector_azimuth].nil?
        assert_equal(Float(solar_thermal_system.collector_azimuth), systems[idx][:collector_azimuth])
      end
      if not systems[idx][:collector_type].nil?
        assert_equal(solar_thermal_system.collector_type, systems[idx][:collector_type])
      end
      if not systems[idx][:collector_tilt].nil?
        assert_equal(Float(solar_thermal_system.collector_tilt), systems[idx][:collector_tilt])
      end
      if not systems[idx][:storage_volume].nil?
        assert_equal(Float(solar_thermal_system.storage_volume), systems[idx][:storage_volume])
      end
      if not systems[idx][:solar_fraction].nil?
        assert_equal(Float(solar_thermal_system.solar_fraction), systems[idx][:solar_fraction])
      end
    end
  end
end
