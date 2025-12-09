# frozen_string_literal: true

require_relative '../../hpxml-measures/HPXMLtoOpenStudio/resources/minitest_helper'
require 'openstudio'
require_relative '../main.rb'
require 'fileutils'
require_relative 'util.rb'
require_relative '../../workflow/design'

class ERIHVACtest < Minitest::Test
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

  def _eri_versions
    return ['latest', '2019A'] # Test HVAC installation quality both after and before 301-2019 Addendum A
  end

  def _dse(calc_type)
    if calc_type == CalcType::IndexAdjHome
      return 1.0
    else
      return 0.8
    end
  end

  def _get_default_hvac_iq_values(eri_version, pre_addendum_b_fan_watts_per_cfm)
    if eri_version == 'latest'
      # All test files have -0.25 specified
      return { fan_watts_per_cfm: 0.58,
               airflow_defect_ratio: -0.25,
               charge_defect_ratio: -0.25 }
    else
      # Pre-Addendum B, doesn't apply
      return { fan_watts_per_cfm: pre_addendum_b_fan_watts_per_cfm,
               airflow_defect_ratio: 0.0,
               charge_defect_ratio: 0.0 }
    end
  end

  def test_none
    hpxml_name = 'base-hvac-none.xml'

    _eri_versions.each do |eri_version|
      _test_ruleset(hpxml_name, eri_version).each do |(run_type, calc_type), hpxml_bldg|
        hvac_iq_values = _get_default_hvac_iq_values(eri_version, 0.5)
        if run_type == RunType::CO2e # All-electric
          _check_heat_pump(hpxml_bldg, [{ systype: HPXML::HVACTypeHeatPumpAirToAir, equiptype: HPXML::HVACEquipmentTypeSplit, fuel: HPXML::FuelTypeElectricity, comptype: HPXML::HVACCompressorTypeSingleStage, hspf2: 6.55, seer2: 12.35, eer2: 10.7, frac_load_heat: 1.0, frac_load_cool: 0.0, dse: _dse(calc_type), compressor_temp: 0.0, backup_fuel: HPXML::FuelTypeElectricity, backup_eff: 1.0, backup_during_defrost: true, fan_motor_type: HPXML::HVACFanMotorTypePSC, **hvac_iq_values }])
        else
          _check_heating_system(hpxml_bldg, [{ systype: HPXML::HVACTypeFurnace, fuel: HPXML::FuelTypeNaturalGas, eff: 0.78, frac_load: 1.0, dse: _dse(calc_type), fan_motor_type: HPXML::HVACFanMotorTypePSC, **hvac_iq_values }])
        end
        _check_cooling_system(hpxml_bldg, [{ systype: HPXML::HVACTypeCentralAirConditioner, equiptype: HPXML::HVACEquipmentTypeSplit, fuel: HPXML::FuelTypeElectricity, comptype: HPXML::HVACCompressorTypeSingleStage, seer2: 12.35, eer2: 10.7, frac_load: 1.0, dse: _dse(calc_type), fan_motor_type: HPXML::HVACFanMotorTypePSC, **hvac_iq_values }])
      end
    end
  end

  def test_none_with_no_fuel_access
    hpxml_name = 'base-hvac-none.xml'
    hpxml = HPXML.new(hpxml_path: File.join(@root_path, 'workflow', 'sample_files', hpxml_name))
    hpxml_bldg = hpxml.buildings[0]
    hpxml_bldg.site.available_fuels = [HPXML::FuelTypeElectricity]
    hpxml_name = File.basename(@tmp_hpxml_path)
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)

    _eri_versions.each do |eri_version|
      _test_ruleset(hpxml_name, eri_version).each do |(_run_type, calc_type), hpxml_bldg|
        hvac_iq_values = _get_default_hvac_iq_values(eri_version, 0.5)
        _check_heat_pump(hpxml_bldg, [{ systype: HPXML::HVACTypeHeatPumpAirToAir, equiptype: HPXML::HVACEquipmentTypeSplit, fuel: HPXML::FuelTypeElectricity, comptype: HPXML::HVACCompressorTypeSingleStage, hspf2: 6.55, seer2: 12.35, eer2: 10.7, frac_load_heat: 1.0, frac_load_cool: 0.0, dse: _dse(calc_type), compressor_temp: 0.0, backup_fuel: HPXML::FuelTypeElectricity, backup_eff: 1.0, backup_during_defrost: true, fan_motor_type: HPXML::HVACFanMotorTypePSC, **hvac_iq_values }])
        _check_cooling_system(hpxml_bldg, [{ systype: HPXML::HVACTypeCentralAirConditioner, equiptype: HPXML::HVACEquipmentTypeSplit, fuel: HPXML::FuelTypeElectricity, comptype: HPXML::HVACCompressorTypeSingleStage, seer2: 12.35, eer2: 10.7, frac_load: 1.0, dse: _dse(calc_type), fan_motor_type: HPXML::HVACFanMotorTypePSC, **hvac_iq_values }])
      end
    end
  end

  def test_boiler_elec
    hpxml_name = 'base-hvac-boiler-elec-only.xml'

    _eri_versions.each do |eri_version|
      _test_ruleset(hpxml_name, eri_version).each do |(_run_type, calc_type), hpxml_bldg|
        hvac_iq_values = _get_default_hvac_iq_values(eri_version, 0.5)
        if [CalcType::RatedHome].include? calc_type
          _check_heating_system(hpxml_bldg, [{ systype: HPXML::HVACTypeBoiler, fuel: HPXML::FuelTypeElectricity, eff: 0.98, frac_load: 1.0, eae: 170 }])
        else
          _check_heat_pump(hpxml_bldg, [{ systype: HPXML::HVACTypeHeatPumpAirToAir, equiptype: HPXML::HVACEquipmentTypeSplit, fuel: HPXML::FuelTypeElectricity, comptype: HPXML::HVACCompressorTypeSingleStage, hspf2: 6.55, seer2: 12.35, eer2: 10.7, frac_load_heat: 1.0, frac_load_cool: 0.0, dse: _dse(calc_type), compressor_temp: 0.0, backup_fuel: HPXML::FuelTypeElectricity, backup_eff: 1.0, backup_during_defrost: true, fan_motor_type: HPXML::HVACFanMotorTypePSC, **hvac_iq_values }])
        end
      end
    end
  end

  def test_boiler_gas
    hpxml_name = 'base-hvac-boiler-gas-only.xml'

    _eri_versions.each do |eri_version|
      _test_ruleset(hpxml_name, eri_version).each do |(run_type, calc_type), hpxml_bldg|
        hvac_iq_values = _get_default_hvac_iq_values(eri_version, 0.5)
        if [CalcType::RatedHome].include? calc_type
          _check_heating_system(hpxml_bldg, [{ systype: HPXML::HVACTypeBoiler, fuel: HPXML::FuelTypeNaturalGas, eff: 0.92, frac_load: 1.0, eae: 170 }])
        elsif run_type == RunType::CO2e # All-electric
          _check_heat_pump(hpxml_bldg, [{ systype: HPXML::HVACTypeHeatPumpAirToAir, equiptype: HPXML::HVACEquipmentTypeSplit, fuel: HPXML::FuelTypeElectricity, comptype: HPXML::HVACCompressorTypeSingleStage, hspf2: 6.55, seer2: 12.35, eer2: 10.7, frac_load_heat: 1.0, frac_load_cool: 0.0, dse: _dse(calc_type), compressor_temp: 0.0, backup_fuel: HPXML::FuelTypeElectricity, backup_eff: 1.0, backup_during_defrost: true, fan_motor_type: HPXML::HVACFanMotorTypePSC, **hvac_iq_values }])
        else
          _check_heating_system(hpxml_bldg, [{ systype: HPXML::HVACTypeBoiler, fuel: HPXML::FuelTypeNaturalGas, eff: 0.80, frac_load: 1.0, dse: _dse(calc_type), eae: 170 }])
        end
      end
    end
  end

  def test_furnace_elec
    hpxml_name = 'base-hvac-furnace-elec-only.xml'

    _eri_versions.each do |eri_version|
      _test_ruleset(hpxml_name, eri_version).each do |(_run_type, calc_type), hpxml_bldg|
        if [CalcType::RatedHome].include? calc_type
          hvac_iq_values = _get_default_hvac_iq_values(eri_version, 0.375)
          _check_heating_system(hpxml_bldg, [{ systype: HPXML::HVACTypeFurnace, fuel: HPXML::FuelTypeElectricity, eff: 0.98, frac_load: 1.0, fan_motor_type: HPXML::HVACFanMotorTypeBPM, **hvac_iq_values }])
        else
          hvac_iq_values = _get_default_hvac_iq_values(eri_version, 0.5)
          _check_heat_pump(hpxml_bldg, [{ systype: HPXML::HVACTypeHeatPumpAirToAir, equiptype: HPXML::HVACEquipmentTypeSplit, fuel: HPXML::FuelTypeElectricity, comptype: HPXML::HVACCompressorTypeSingleStage, hspf2: 6.55, seer2: 12.35, eer2: 10.7, frac_load_heat: 1.0, frac_load_cool: 0.0, dse: _dse(calc_type), compressor_temp: 0.0, backup_fuel: HPXML::FuelTypeElectricity, backup_eff: 1.0, backup_during_defrost: true, fan_motor_type: HPXML::HVACFanMotorTypePSC, **hvac_iq_values }])
        end
      end
    end
  end

  def test_furnace_gas
    hpxml_name = 'base-hvac-furnace-gas-only.xml'

    _eri_versions.each do |eri_version|
      _test_ruleset(hpxml_name, eri_version).each do |(run_type, calc_type), hpxml_bldg|
        if [CalcType::RatedHome].include? calc_type
          hvac_iq_values = _get_default_hvac_iq_values(eri_version, 0.375)
          _check_heating_system(hpxml_bldg, [{ systype: HPXML::HVACTypeFurnace, fuel: HPXML::FuelTypeNaturalGas, eff: 0.92, frac_load: 1.0, fan_motor_type: HPXML::HVACFanMotorTypeBPM, **hvac_iq_values }])
        elsif run_type == RunType::CO2e # All-electric
          hvac_iq_values = _get_default_hvac_iq_values(eri_version, 0.5)
          _check_heat_pump(hpxml_bldg, [{ systype: HPXML::HVACTypeHeatPumpAirToAir, equiptype: HPXML::HVACEquipmentTypeSplit, fuel: HPXML::FuelTypeElectricity, comptype: HPXML::HVACCompressorTypeSingleStage, hspf2: 6.55, seer2: 12.35, eer2: 10.7, frac_load_heat: 1.0, frac_load_cool: 0.0, dse: _dse(calc_type), compressor_temp: 0.0, backup_fuel: HPXML::FuelTypeElectricity, backup_eff: 1.0, backup_during_defrost: true, fan_motor_type: HPXML::HVACFanMotorTypePSC, **hvac_iq_values }])
        else
          hvac_iq_values = _get_default_hvac_iq_values(eri_version, 0.5)
          _check_heating_system(hpxml_bldg, [{ systype: HPXML::HVACTypeFurnace, fuel: HPXML::FuelTypeNaturalGas, eff: 0.78, frac_load: 1.0, dse: _dse(calc_type), fan_motor_type: HPXML::HVACFanMotorTypePSC, **hvac_iq_values }])
        end
      end
    end
  end

  def test_stove_wood_pellets
    hpxml_name = 'base-hvac-stove-wood-pellets-only.xml'

    _eri_versions.each do |eri_version|
      _test_ruleset(hpxml_name, eri_version).each do |(run_type, calc_type), hpxml_bldg|
        hvac_iq_values = _get_default_hvac_iq_values(eri_version, 0.5)
        if [CalcType::RatedHome].include? calc_type
          _check_heating_system(hpxml_bldg, [{ systype: HPXML::HVACTypeStove, fuel: HPXML::FuelTypeWoodPellets, frac_load: 1.0, eff: 0.8 }])
        elsif run_type == RunType::CO2e # All-electric
          _check_heat_pump(hpxml_bldg, [{ systype: HPXML::HVACTypeHeatPumpAirToAir, equiptype: HPXML::HVACEquipmentTypeSplit, fuel: HPXML::FuelTypeElectricity, comptype: HPXML::HVACCompressorTypeSingleStage, hspf2: 6.55, seer2: 12.35, eer2: 10.7, frac_load_heat: 1.0, frac_load_cool: 0.0, dse: _dse(calc_type), compressor_temp: 0.0, backup_fuel: HPXML::FuelTypeElectricity, backup_eff: 1.0, backup_during_defrost: true, fan_motor_type: HPXML::HVACFanMotorTypePSC, **hvac_iq_values }])
        else
          _check_heating_system(hpxml_bldg, [{ systype: HPXML::HVACTypeFurnace, fuel: HPXML::FuelTypeNaturalGas, eff: 0.78, frac_load: 1.0, dse: _dse(calc_type), fan_motor_type: HPXML::HVACFanMotorTypePSC, **hvac_iq_values }])
        end
      end
    end
  end

  def test_wall_furnace_elec
    hpxml_name = 'base-hvac-wall-furnace-elec-only.xml'

    _eri_versions.each do |eri_version|
      _test_ruleset(hpxml_name, eri_version).each do |(_run_type, calc_type), hpxml_bldg|
        if [CalcType::RatedHome].include? calc_type
          _check_heating_system(hpxml_bldg, [{ systype: HPXML::HVACTypeWallFurnace, fuel: HPXML::FuelTypeElectricity, eff: 0.98, frac_load: 1.0 }])
        else
          hvac_iq_values = _get_default_hvac_iq_values(eri_version, 0.5)
          _check_heat_pump(hpxml_bldg, [{ systype: HPXML::HVACTypeHeatPumpAirToAir, equiptype: HPXML::HVACEquipmentTypeSplit, fuel: HPXML::FuelTypeElectricity, comptype: HPXML::HVACCompressorTypeSingleStage, hspf2: 6.55, seer2: 12.35, eer2: 10.7, frac_load_heat: 1.0, frac_load_cool: 0.0, dse: _dse(calc_type), compressor_temp: 0.0, backup_fuel: HPXML::FuelTypeElectricity, backup_eff: 1.0, backup_during_defrost: true, fan_motor_type: HPXML::HVACFanMotorTypePSC, **hvac_iq_values }])
        end
      end
    end
  end

  def test_elec_resistance
    hpxml_name = 'base-hvac-elec-resistance-only.xml'

    _eri_versions.each do |eri_version|
      _test_ruleset(hpxml_name, eri_version).each do |(_run_type, calc_type), hpxml_bldg|
        if [CalcType::RatedHome].include? calc_type
          _check_heating_system(hpxml_bldg, [{ systype: HPXML::HVACTypeElectricResistance, fuel: HPXML::FuelTypeElectricity, eff: 1.0, frac_load: 1.0 }])
        else
          hvac_iq_values = _get_default_hvac_iq_values(eri_version, 0.5)
          _check_heat_pump(hpxml_bldg, [{ systype: HPXML::HVACTypeHeatPumpAirToAir, equiptype: HPXML::HVACEquipmentTypeSplit, fuel: HPXML::FuelTypeElectricity, comptype: HPXML::HVACCompressorTypeSingleStage, hspf2: 6.55, seer2: 12.35, eer2: 10.7, frac_load_heat: 1.0, frac_load_cool: 0.0, dse: _dse(calc_type), compressor_temp: 0.0, backup_fuel: HPXML::FuelTypeElectricity, backup_eff: 1.0, backup_during_defrost: true, fan_motor_type: HPXML::HVACFanMotorTypePSC, **hvac_iq_values }])
        end
      end
    end
  end

  def test_air_source_heat_pump
    hpxml_names = ['base-hvac-air-to-air-heat-pump-1-speed.xml',
                   'base-hvac-install-quality-air-to-air-heat-pump-1-speed.xml',
                   'base-hvac-air-to-air-heat-pump-1-speed-lockout-temperatures.xml']

    hpxml_names.each do |hpxml_name|
      if hpxml_name == 'base-hvac-air-to-air-heat-pump-1-speed-lockout-temperatures.xml'
        compressor_temp = 5.0
      else
        compressor_temp = 0.0
      end
      _eri_versions.each do |eri_version|
        _test_ruleset(hpxml_name, eri_version).each do |(_run_type, calc_type), hpxml_bldg|
          if [CalcType::RatedHome].include? calc_type
            hvac_iq_values = _get_default_hvac_iq_values(eri_version, 0.5)
            if hpxml_name.include?('install-quality') && eri_version == 'latest'
              hvac_iq_values[:fan_watts_per_cfm] = 0.365
            end
            _check_heat_pump(hpxml_bldg, [{ systype: HPXML::HVACTypeHeatPumpAirToAir, equiptype: HPXML::HVACEquipmentTypeSplit, fuel: HPXML::FuelTypeElectricity, comptype: HPXML::HVACCompressorTypeSingleStage, hspf2: 7.0, seer2: 13.4, eer2: 11.3, frac_load_heat: 1.0, frac_load_cool: 1.0, compressor_temp: compressor_temp, backup_fuel: HPXML::FuelTypeElectricity, backup_eff: 1.0, backup_during_defrost: true, fan_motor_type: HPXML::HVACFanMotorTypePSC, **hvac_iq_values }])
          else
            hvac_iq_values = _get_default_hvac_iq_values(eri_version, 0.5)
            _check_heat_pump(hpxml_bldg, [{ systype: HPXML::HVACTypeHeatPumpAirToAir, equiptype: HPXML::HVACEquipmentTypeSplit, fuel: HPXML::FuelTypeElectricity, comptype: HPXML::HVACCompressorTypeSingleStage, hspf2: 6.55, seer2: 12.35, eer2: 10.7, frac_load_heat: 1.0, frac_load_cool: 1.0, dse: _dse(calc_type), compressor_temp: 0.0, backup_fuel: HPXML::FuelTypeElectricity, backup_eff: 1.0, backup_during_defrost: true, fan_motor_type: HPXML::HVACFanMotorTypePSC, **hvac_iq_values }])
          end
        end
      end
    end
  end

  def test_mini_split_heat_pump_ducted
    hpxml_names = ['base-hvac-mini-split-heat-pump-ducted.xml',
                   'base-hvac-install-quality-mini-split-heat-pump-ducted.xml']

    hpxml_names.each do |hpxml_name|
      _eri_versions.each do |eri_version|
        _test_ruleset(hpxml_name, eri_version).each do |(_run_type, calc_type), hpxml_bldg|
          if [CalcType::RatedHome].include? calc_type
            hvac_iq_values = _get_default_hvac_iq_values(eri_version, 0.18)
            if hpxml_name.include?('install-quality') && eri_version == 'latest'
              hvac_iq_values[:fan_watts_per_cfm] = 0.365
            end
            _check_heat_pump(hpxml_bldg, [{ systype: HPXML::HVACTypeHeatPumpMiniSplit, equiptype: HPXML::HVACEquipmentTypeSplit, fuel: HPXML::FuelTypeElectricity, comptype: HPXML::HVACCompressorTypeVariableSpeed, hspf2: 8.5, seer2: 18.05, eer2: 12.1, frac_load_heat: 1.0, frac_load_cool: 1.0, compressor_temp: -20.0, backup_fuel: HPXML::FuelTypeElectricity, backup_eff: 1.0, backup_during_defrost: true, fan_motor_type: HPXML::HVACFanMotorTypeBPM, **hvac_iq_values }])
          else
            hvac_iq_values = _get_default_hvac_iq_values(eri_version, 0.5)
            _check_heat_pump(hpxml_bldg, [{ systype: HPXML::HVACTypeHeatPumpAirToAir, equiptype: HPXML::HVACEquipmentTypeSplit, fuel: HPXML::FuelTypeElectricity, comptype: HPXML::HVACCompressorTypeSingleStage, hspf2: 6.55, seer2: 12.35, eer2: 10.7, frac_load_heat: 1.0, frac_load_cool: 1.0, dse: _dse(calc_type), compressor_temp: 0.0, backup_fuel: HPXML::FuelTypeElectricity, backup_eff: 1.0, backup_during_defrost: true, fan_motor_type: HPXML::HVACFanMotorTypePSC, **hvac_iq_values }])
          end
        end
      end
    end
  end

  def test_mini_split_heat_pump_ductless
    hpxml_name = 'base-hvac-mini-split-heat-pump-ductless.xml'

    _eri_versions.each do |eri_version|
      _test_ruleset(hpxml_name, eri_version).each do |(_run_type, calc_type), hpxml_bldg|
        if [CalcType::RatedHome].include? calc_type
          hvac_iq_values = _get_default_hvac_iq_values(eri_version, 0.07)
          hvac_iq_values[:airflow_defect_ratio] = 0.0
          _check_heat_pump(hpxml_bldg, [{ systype: HPXML::HVACTypeHeatPumpMiniSplit, equiptype: HPXML::HVACEquipmentTypeSplit, fuel: HPXML::FuelTypeElectricity, comptype: HPXML::HVACCompressorTypeVariableSpeed, hspf2: 9, seer2: 19, eer2: 12.3, frac_load_heat: 1.0, frac_load_cool: 1.0, compressor_temp: -20.0, backup_fuel: HPXML::FuelTypeElectricity, backup_eff: 1.0, backup_during_defrost: false, fan_motor_type: HPXML::HVACFanMotorTypeBPM, **hvac_iq_values }])
        else
          hvac_iq_values = _get_default_hvac_iq_values(eri_version, 0.5)
          _check_heat_pump(hpxml_bldg, [{ systype: HPXML::HVACTypeHeatPumpAirToAir, equiptype: HPXML::HVACEquipmentTypeSplit, fuel: HPXML::FuelTypeElectricity, comptype: HPXML::HVACCompressorTypeSingleStage, hspf2: 6.55, seer2: 12.35, eer2: 10.7, frac_load_heat: 1.0, frac_load_cool: 1.0, dse: _dse(calc_type), compressor_temp: 0.0, backup_fuel: HPXML::FuelTypeElectricity, backup_eff: 1.0, backup_during_defrost: true, fan_motor_type: HPXML::HVACFanMotorTypePSC, **hvac_iq_values }])
        end
      end
    end
  end

  def test_ground_to_air_heat_pump
    hpxml_names = ['base-hvac-ground-to-air-heat-pump-1-speed.xml',
                   'base-hvac-install-quality-ground-to-air-heat-pump-1-speed.xml']

    hpxml_names.each do |hpxml_name|
      _eri_versions.each do |eri_version|
        _test_ruleset(hpxml_name, eri_version).each do |(_run_type, calc_type), hpxml_bldg|
          hvac_iq_values = _get_default_hvac_iq_values(eri_version, 0.5)
          if [CalcType::RatedHome].include? calc_type
            if hpxml_name.include?('install-quality') && eri_version == 'latest'
              hvac_iq_values[:fan_watts_per_cfm] = 0.365
            end
            _check_heat_pump(hpxml_bldg, [{ systype: HPXML::HVACTypeHeatPumpGroundToAir, fuel: HPXML::FuelTypeElectricity, comptype: HPXML::HVACCompressorTypeSingleStage, eer: 16.6, cop: 3.6, frac_load_heat: 1.0, frac_load_cool: 1.0, backup_fuel: HPXML::FuelTypeElectricity, backup_eff: 1.0, pump_w_per_ton: 100, fan_motor_type: HPXML::HVACFanMotorTypePSC, **hvac_iq_values }])
          else
            _check_heat_pump(hpxml_bldg, [{ systype: HPXML::HVACTypeHeatPumpAirToAir, equiptype: HPXML::HVACEquipmentTypeSplit, fuel: HPXML::FuelTypeElectricity, comptype: HPXML::HVACCompressorTypeSingleStage, hspf2: 6.55, seer2: 12.35, eer2: 10.7, frac_load_heat: 1.0, frac_load_cool: 1.0, dse: _dse(calc_type), compressor_temp: 0.0, backup_fuel: HPXML::FuelTypeElectricity, backup_eff: 1.0, backup_during_defrost: true, fan_motor_type: HPXML::HVACFanMotorTypePSC, **hvac_iq_values }])
          end
        end
      end
    end
  end

  def test_dual_fuel_heat_pump
    hpxml_name = 'base-hvac-dual-fuel-air-to-air-heat-pump-1-speed.xml'

    _eri_versions.each do |eri_version|
      _test_ruleset(hpxml_name, eri_version).each do |(run_type, calc_type), hpxml_bldg|
        if [CalcType::RatedHome].include? calc_type
          hvac_iq_values = _get_default_hvac_iq_values(eri_version, 0.5)
          _check_heat_pump(hpxml_bldg, [{ systype: HPXML::HVACTypeHeatPumpAirToAir, equiptype: HPXML::HVACEquipmentTypeSplit, fuel: HPXML::FuelTypeElectricity, comptype: HPXML::HVACCompressorTypeSingleStage, hspf2: 7.0, seer2: 13.4, eer2: 11.3, frac_load_heat: 1.0, frac_load_cool: 1.0, compressor_temp: 40.0, backup_fuel: HPXML::FuelTypeNaturalGas, backup_eff: 0.95, backup_during_defrost: true, fan_motor_type: HPXML::HVACFanMotorTypePSC, **hvac_iq_values }])
        else
          hvac_iq_values = _get_default_hvac_iq_values(eri_version, 0.5)
          if run_type == RunType::CO2e # All-electric
            _check_heat_pump(hpxml_bldg, [{ systype: HPXML::HVACTypeHeatPumpAirToAir, equiptype: HPXML::HVACEquipmentTypeSplit, fuel: HPXML::FuelTypeElectricity, comptype: HPXML::HVACCompressorTypeSingleStage, hspf2: 6.55, seer2: 12.35, eer2: 10.7, frac_load_heat: 1.0, frac_load_cool: 1.0, dse: _dse(calc_type), compressor_temp: 0.0, backup_fuel: HPXML::FuelTypeElectricity, backup_eff: 1.0, backup_during_defrost: true, fan_motor_type: HPXML::HVACFanMotorTypePSC, **hvac_iq_values }])
          else
            _check_heat_pump(hpxml_bldg, [{ systype: HPXML::HVACTypeHeatPumpAirToAir, equiptype: HPXML::HVACEquipmentTypeSplit, fuel: HPXML::FuelTypeElectricity, comptype: HPXML::HVACCompressorTypeSingleStage, hspf2: 6.55, seer2: 12.35, eer2: 10.7, frac_load_heat: 1.0, frac_load_cool: 1.0, dse: _dse(calc_type), compressor_temp: 40.0, backup_fuel: HPXML::FuelTypeNaturalGas, backup_eff: 0.78, backup_during_defrost: true, fan_motor_type: HPXML::HVACFanMotorTypePSC, **hvac_iq_values }])
          end
        end
      end
    end
  end

  def test_central_air_conditioner
    hpxml_name = 'base-hvac-central-ac-only-1-speed.xml'

    _eri_versions.each do |eri_version|
      _test_ruleset(hpxml_name, eri_version).each do |(_run_type, calc_type), hpxml_bldg|
        if [CalcType::RatedHome].include? calc_type
          hvac_iq_values = _get_default_hvac_iq_values(eri_version, 0.5)
          _check_cooling_system(hpxml_bldg, [{ systype: HPXML::HVACTypeCentralAirConditioner, equiptype: HPXML::HVACEquipmentTypeSplit, fuel: HPXML::FuelTypeElectricity, comptype: HPXML::HVACCompressorTypeSingleStage, seer2: 13.4, eer2: 11.3, frac_load: 1.0, fan_motor_type: HPXML::HVACFanMotorTypePSC, **hvac_iq_values }])
        else
          hvac_iq_values = _get_default_hvac_iq_values(eri_version, 0.5)
          _check_cooling_system(hpxml_bldg, [{ systype: HPXML::HVACTypeCentralAirConditioner, equiptype: HPXML::HVACEquipmentTypeSplit, fuel: HPXML::FuelTypeElectricity, comptype: HPXML::HVACCompressorTypeSingleStage, seer2: 12.35, eer2: 10.7, frac_load: 1.0, dse: _dse(calc_type), fan_motor_type: HPXML::HVACFanMotorTypePSC, **hvac_iq_values }])
        end
      end
    end
  end

  def test_room_air_conditioner_and_ptac
    hpxml_names = ['base-hvac-room-ac-only.xml',
                   'base-hvac-room-ac-only-eer.xml',
                   'base-hvac-ptac.xml']

    hpxml_names.each do |hpxml_name|
      if hpxml_name == 'base-hvac-room-ac-only.xml'
        systype = HPXML::HVACTypeRoomAirConditioner
        ceer = 8.4
      elsif hpxml_name == 'base-hvac-ptac.xml'
        systype = HPXML::HVACTypePTAC
        ceer = 10.6
      else
        systype = HPXML::HVACTypeRoomAirConditioner
        ceer = 8.4
      end
      _eri_versions.each do |eri_version|
        _test_ruleset(hpxml_name, eri_version).each do |(_run_type, calc_type), hpxml_bldg|
          if [CalcType::RatedHome].include? calc_type
            _check_cooling_system(hpxml_bldg, [{ systype: systype, fuel: HPXML::FuelTypeElectricity, ceer: ceer, frac_load: 1.0, comptype: HPXML::HVACCompressorTypeSingleStage }])
          else
            hvac_iq_values = _get_default_hvac_iq_values(eri_version, 0.5)
            _check_cooling_system(hpxml_bldg, [{ systype: HPXML::HVACTypeCentralAirConditioner, equiptype: HPXML::HVACEquipmentTypeSplit, fuel: HPXML::FuelTypeElectricity, comptype: HPXML::HVACCompressorTypeSingleStage, seer2: 12.35, eer2: 10.7, frac_load: 1.0, dse: _dse(calc_type), fan_motor_type: HPXML::HVACFanMotorTypePSC, **hvac_iq_values }])
          end
        end
      end
    end
  end

  def test_room_air_conditioner_and_ptac_with_heating
    hpxml_names = ['base-hvac-room-ac-with-heating.xml',
                   'base-hvac-ptac-with-heating-electricity.xml']

    hpxml_names.each do |hpxml_name|
      if hpxml_name == 'base-hvac-room-ac-with-heating.xml'
        systype = HPXML::HVACTypeRoomAirConditioner
        ceer = 8.4
      else
        systype = HPXML::HVACTypePTAC
        ceer = 10.6
      end
      _eri_versions.each do |eri_version|
        _test_ruleset(hpxml_name, eri_version).each do |(_run_type, calc_type), hpxml_bldg|
          if [CalcType::RatedHome].include? calc_type
            _check_cooling_system(hpxml_bldg, [{ systype: systype, fuel: HPXML::FuelTypeElectricity, ceer: ceer, frac_load: 1.0, comptype: HPXML::HVACCompressorTypeSingleStage,
                                                 integrated_htg_fuel: HPXML::FuelTypeElectricity, integrated_htg_eff: 1.0, integrated_htg_frac_load: 1.0 }])
          else
            hvac_iq_values = _get_default_hvac_iq_values(eri_version, 0.5)
            _check_heat_pump(hpxml_bldg, [{ systype: HPXML::HVACTypeHeatPumpAirToAir, equiptype: HPXML::HVACEquipmentTypeSplit, fuel: HPXML::FuelTypeElectricity, comptype: HPXML::HVACCompressorTypeSingleStage, hspf2: 6.55, seer2: 12.35, eer2: 10.7, frac_load_heat: 1.0, frac_load_cool: 1.0, dse: _dse(calc_type), compressor_temp: 0.0, backup_fuel: HPXML::FuelTypeElectricity, backup_eff: 1.0, backup_during_defrost: true, fan_motor_type: HPXML::HVACFanMotorTypePSC, **hvac_iq_values }])
          end
        end
      end
    end
  end

  def test_room_air_conditioner_and_ptac_with_heating_gas
    hpxml_name = 'base-hvac-ptac-with-heating-natural-gas.xml'

    _eri_versions.each do |eri_version|
      _test_ruleset(hpxml_name, eri_version).each do |(run_type, calc_type), hpxml_bldg|
        if [CalcType::RatedHome].include? calc_type
          _check_cooling_system(hpxml_bldg, [{ systype: HPXML::HVACTypePTAC, fuel: HPXML::FuelTypeElectricity, ceer: 10.6, frac_load: 1.0, comptype: HPXML::HVACCompressorTypeSingleStage,
                                               integrated_htg_fuel: HPXML::FuelTypeNaturalGas, integrated_htg_eff: 0.8, integrated_htg_frac_load: 1.0 }])
        else
          hvac_iq_values = _get_default_hvac_iq_values(eri_version, 0.5)
          if run_type == RunType::CO2e # All-electric
            _check_heat_pump(hpxml_bldg, [{ systype: HPXML::HVACTypeHeatPumpAirToAir, equiptype: HPXML::HVACEquipmentTypeSplit, fuel: HPXML::FuelTypeElectricity, comptype: HPXML::HVACCompressorTypeSingleStage, hspf2: 6.55, seer2: 12.35, eer2: 10.7, frac_load_heat: 1.0, frac_load_cool: 1.0, dse: _dse(calc_type), compressor_temp: 0.0, backup_fuel: HPXML::FuelTypeElectricity, backup_eff: 1.0, backup_during_defrost: true, fan_motor_type: HPXML::HVACFanMotorTypePSC, **hvac_iq_values }])
          else
            _check_heating_system(hpxml_bldg, [{ systype: HPXML::HVACTypeFurnace, fuel: HPXML::FuelTypeNaturalGas, eff: 0.78, frac_load: 1.0, dse: _dse(calc_type), fan_motor_type: HPXML::HVACFanMotorTypePSC, **hvac_iq_values }])
            _check_cooling_system(hpxml_bldg, [{ systype: HPXML::HVACTypeCentralAirConditioner, equiptype: HPXML::HVACEquipmentTypeSplit, fuel: HPXML::FuelTypeElectricity, comptype: HPXML::HVACCompressorTypeSingleStage, seer2: 12.35, eer2: 10.7, frac_load: 1.0, dse: _dse(calc_type), fan_motor_type: HPXML::HVACFanMotorTypePSC, **hvac_iq_values }])
          end
        end
      end
    end
  end

  def test_room_air_conditioner_with_reverse_cycle_and_pthp
    hpxml_names = ['base-hvac-room-ac-with-reverse-cycle.xml',
                   'base-hvac-pthp.xml']

    hpxml_names.each do |hpxml_name|
      if hpxml_name == 'base-hvac-room-ac-with-reverse-cycle.xml'
        systype = HPXML::HVACTypeHeatPumpRoom
      else
        systype = HPXML::HVACTypeHeatPumpPTHP
      end
      _eri_versions.each do |eri_version|
        _test_ruleset(hpxml_name, eri_version).each do |(_run_type, calc_type), hpxml_bldg|
          if [CalcType::RatedHome].include? calc_type
            _check_heat_pump(hpxml_bldg, [{ systype: systype, fuel: HPXML::FuelTypeElectricity, comptype: HPXML::HVACCompressorTypeSingleStage, cop: 3.6, ceer: 11.8, frac_load_heat: 1.0, frac_load_cool: 1.0, compressor_temp: 0.0, backup_fuel: HPXML::FuelTypeElectricity, backup_eff: 1.0, backup_during_defrost: true }])
          else
            hvac_iq_values = _get_default_hvac_iq_values(eri_version, 0.5)
            _check_heat_pump(hpxml_bldg, [{ systype: HPXML::HVACTypeHeatPumpAirToAir, equiptype: HPXML::HVACEquipmentTypeSplit, fuel: HPXML::FuelTypeElectricity, comptype: HPXML::HVACCompressorTypeSingleStage, hspf2: 6.55, seer2: 12.35, eer2: 10.7, frac_load_heat: 1.0, frac_load_cool: 1.0, dse: _dse(calc_type), compressor_temp: 0.0, backup_fuel: HPXML::FuelTypeElectricity, backup_eff: 1.0, backup_during_defrost: true, fan_motor_type: HPXML::HVACFanMotorTypePSC, **hvac_iq_values }])
          end
        end
      end
    end
  end

  def test_evaporative_cooler
    hpxml_name = 'base-hvac-evap-cooler-only.xml'

    _eri_versions.each do |eri_version|
      _test_ruleset(hpxml_name, eri_version).each do |(_run_type, calc_type), hpxml_bldg|
        if [CalcType::RatedHome].include? calc_type
          _check_cooling_system(hpxml_bldg, [{ systype: HPXML::HVACTypeEvaporativeCooler, fuel: HPXML::FuelTypeElectricity, frac_load: 1.0 }])
        else
          hvac_iq_values = _get_default_hvac_iq_values(eri_version, 0.5)
          _check_cooling_system(hpxml_bldg, [{ systype: HPXML::HVACTypeCentralAirConditioner, equiptype: HPXML::HVACEquipmentTypeSplit, fuel: HPXML::FuelTypeElectricity, comptype: HPXML::HVACCompressorTypeSingleStage, seer2: 12.35, eer2: 10.7, frac_load: 1.0, dse: _dse(calc_type), fan_motor_type: HPXML::HVACFanMotorTypePSC, **hvac_iq_values }])
        end
      end
    end
  end

  def test_mini_split_air_conditioner_ducted
    hpxml_names = ['base-hvac-mini-split-air-conditioner-only-ducted.xml',
                   'base-hvac-install-quality-mini-split-air-conditioner-only-ducted.xml']

    hpxml_names.each do |hpxml_name|
      _eri_versions.each do |eri_version|
        _test_ruleset(hpxml_name, eri_version).each do |(_run_type, calc_type), hpxml_bldg|
          if [CalcType::RatedHome].include? calc_type
            hvac_iq_values = _get_default_hvac_iq_values(eri_version, 0.18)
            if hpxml_name.include?('install-quality') && eri_version == 'latest'
              hvac_iq_values[:fan_watts_per_cfm] = 0.365
            end
            _check_cooling_system(hpxml_bldg, [{ systype: HPXML::HVACTypeMiniSplitAirConditioner, equiptype: HPXML::HVACEquipmentTypeSplit, fuel: HPXML::FuelTypeElectricity, comptype: HPXML::HVACCompressorTypeVariableSpeed, seer2: 18.05, eer2: 12.1, frac_load: 1.0, fan_motor_type: HPXML::HVACFanMotorTypeBPM, **hvac_iq_values }])
          else
            hvac_iq_values = _get_default_hvac_iq_values(eri_version, 0.5)
            _check_cooling_system(hpxml_bldg, [{ systype: HPXML::HVACTypeCentralAirConditioner, equiptype: HPXML::HVACEquipmentTypeSplit, fuel: HPXML::FuelTypeElectricity, comptype: HPXML::HVACCompressorTypeSingleStage, seer2: 12.35, eer2: 10.7, frac_load: 1.0, dse: _dse(calc_type), fan_motor_type: HPXML::HVACFanMotorTypePSC, **hvac_iq_values }])
          end
        end
      end
    end
  end

  def test_mini_split_air_conditioner_ductless
    hpxml_name = 'base-hvac-mini-split-air-conditioner-only-ductless.xml'

    _eri_versions.each do |eri_version|
      _test_ruleset(hpxml_name, eri_version).each do |(_run_type, calc_type), hpxml_bldg|
        if [CalcType::RatedHome].include? calc_type
          hvac_iq_values = _get_default_hvac_iq_values(eri_version, 0.07)
          hvac_iq_values[:airflow_defect_ratio] = 0.0
          _check_cooling_system(hpxml_bldg, [{ systype: HPXML::HVACTypeMiniSplitAirConditioner, equiptype: HPXML::HVACEquipmentTypeSplit, fuel: HPXML::FuelTypeElectricity, comptype: HPXML::HVACCompressorTypeVariableSpeed, seer2: 19, eer2: 12.3, frac_load: 1.0, fan_motor_type: HPXML::HVACFanMotorTypeBPM, **hvac_iq_values }])
        else
          hvac_iq_values = _get_default_hvac_iq_values(eri_version, 0.5)
          _check_cooling_system(hpxml_bldg, [{ systype: HPXML::HVACTypeCentralAirConditioner, equiptype: HPXML::HVACEquipmentTypeSplit, fuel: HPXML::FuelTypeElectricity, comptype: HPXML::HVACCompressorTypeSingleStage, seer2: 12.35, eer2: 10.7, frac_load: 1.0, dse: _dse(calc_type), fan_motor_type: HPXML::HVACFanMotorTypePSC, **hvac_iq_values }])
        end
      end
    end
  end

  def test_furnace_gas_central_air_conditioner
    hpxml_names = ['base.xml',
                   'base-hvac-install-quality-furnace-gas-central-ac-1-speed.xml',
                   'base-hvac-fan-motor-type.xml']

    hpxml_names.each do |hpxml_name|
      _eri_versions.each do |eri_version|
        _test_ruleset(hpxml_name, eri_version).each do |(run_type, calc_type), hpxml_bldg|
          if [CalcType::RatedHome].include? calc_type
            if hpxml_name.include?('fan-motor-type')
              fan_motor_type = HPXML::HVACFanMotorTypeBPM
              hvac_iq_values = _get_default_hvac_iq_values(eri_version, 0.375)
            else
              fan_motor_type = HPXML::HVACFanMotorTypePSC
              hvac_iq_values = _get_default_hvac_iq_values(eri_version, 0.5)
            end
            if hpxml_name.include?('install-quality') && eri_version == 'latest'
              hvac_iq_values[:fan_watts_per_cfm] = 0.365
            end
            _check_cooling_system(hpxml_bldg, [{ systype: HPXML::HVACTypeCentralAirConditioner, equiptype: HPXML::HVACEquipmentTypeSplit, fuel: HPXML::FuelTypeElectricity, comptype: HPXML::HVACCompressorTypeSingleStage, seer2: 13.4, eer2: 11.3, frac_load: 1.0, fan_motor_type: fan_motor_type, **hvac_iq_values }])
            _check_heating_system(hpxml_bldg, [{ systype: HPXML::HVACTypeFurnace, fuel: HPXML::FuelTypeNaturalGas, eff: 0.92, frac_load: 1.0, fan_motor_type: fan_motor_type, **hvac_iq_values }])
          else
            hvac_iq_values = _get_default_hvac_iq_values(eri_version, 0.5)
            if run_type == RunType::CO2e # All-electric
              _check_heat_pump(hpxml_bldg, [{ systype: HPXML::HVACTypeHeatPumpAirToAir, equiptype: HPXML::HVACEquipmentTypeSplit, fuel: HPXML::FuelTypeElectricity, comptype: HPXML::HVACCompressorTypeSingleStage, hspf2: 6.55, seer2: 12.35, eer2: 10.7, frac_load_heat: 1.0, frac_load_cool: 1.0, dse: _dse(calc_type), compressor_temp: 0.0, backup_fuel: HPXML::FuelTypeElectricity, backup_eff: 1.0, backup_during_defrost: true, fan_motor_type: HPXML::HVACFanMotorTypePSC, **hvac_iq_values }])
            else
              _check_heating_system(hpxml_bldg, [{ systype: HPXML::HVACTypeFurnace, fuel: HPXML::FuelTypeNaturalGas, eff: 0.78, frac_load: 1.0, dse: _dse(calc_type), fan_motor_type: HPXML::HVACFanMotorTypePSC, **hvac_iq_values }])
              _check_cooling_system(hpxml_bldg, [{ systype: HPXML::HVACTypeCentralAirConditioner, equiptype: HPXML::HVACEquipmentTypeSplit, fuel: HPXML::FuelTypeElectricity, comptype: HPXML::HVACCompressorTypeSingleStage, seer2: 12.35, eer2: 10.7, frac_load: 1.0, dse: _dse(calc_type), fan_motor_type: HPXML::HVACFanMotorTypePSC, **hvac_iq_values }])
            end
          end
        end
      end
    end
  end

  def test_multiple_hvac
    hpxml_name = 'base-hvac-multiple.xml'

    _eri_versions.each do |eri_version|
      _test_ruleset(hpxml_name, eri_version).each do |(run_type, calc_type), hpxml_bldg|
        if [CalcType::RatedHome].include? calc_type
          hvac_iq_values = _get_default_hvac_iq_values(eri_version, 0.5)
          furn_hvac_iq_values = _get_default_hvac_iq_values(eri_version, 0.375)
          mshp_hvac_iq_values = _get_default_hvac_iq_values(eri_version, 0.07)
          mshp_hvac_iq_values[:airflow_defect_ratio] = 0.0
          _check_cooling_system(hpxml_bldg, [{ systype: HPXML::HVACTypeCentralAirConditioner, equiptype: HPXML::HVACEquipmentTypeSplit, fuel: HPXML::FuelTypeElectricity, comptype: HPXML::HVACCompressorTypeSingleStage, seer2: 13.4, eer2: 11.3, frac_load: 0.1333, fan_motor_type: HPXML::HVACFanMotorTypePSC, **hvac_iq_values },
                                             { systype: HPXML::HVACTypeRoomAirConditioner, fuel: HPXML::FuelTypeElectricity, comptype: HPXML::HVACCompressorTypeSingleStage, ceer: 8.4, frac_load: 0.1333 },
                                             { systype: HPXML::HVACTypePTAC, fuel: HPXML::FuelTypeElectricity, comptype: HPXML::HVACCompressorTypeSingleStage, ceer: 10.6, frac_load: 0.1333 }])
          _check_heating_system(hpxml_bldg, [{ systype: HPXML::HVACTypeFurnace, fuel: HPXML::FuelTypeElectricity, eff: 1.0, frac_load: 0.1, fan_motor_type: HPXML::HVACFanMotorTypeBPM, **furn_hvac_iq_values },
                                             { systype: HPXML::HVACTypeFurnace, fuel: HPXML::FuelTypeNaturalGas, eff: 0.92, frac_load: 0.1, fan_motor_type: HPXML::HVACFanMotorTypePSC, **hvac_iq_values },
                                             { systype: HPXML::HVACTypeBoiler, fuel: HPXML::FuelTypeElectricity, eff: 1.0, frac_load: 0.1, eae: 170 },
                                             { systype: HPXML::HVACTypeBoiler, fuel: HPXML::FuelTypeNaturalGas, eff: 0.92, frac_load: 0.1, eae: 170 },
                                             { systype: HPXML::HVACTypeElectricResistance, fuel: HPXML::FuelTypeElectricity, eff: 1.0, frac_load: 0.1 },
                                             { systype: HPXML::HVACTypeStove, fuel: HPXML::FuelTypeOil, eff: 0.8, frac_load: 0.1 },
                                             { systype: HPXML::HVACTypeWallFurnace, fuel: HPXML::FuelTypePropane, eff: 0.8, frac_load: 0.1 }])
          _check_heat_pump(hpxml_bldg, [{ systype: HPXML::HVACTypeHeatPumpAirToAir, equiptype: HPXML::HVACEquipmentTypeSplit, fuel: HPXML::FuelTypeElectricity, comptype: HPXML::HVACCompressorTypeSingleStage, hspf2: 7.0, seer2: 13.4, eer2: 11.3, frac_load_heat: 0.1, frac_load_cool: 0.2, compressor_temp: 0.0, backup_fuel: HPXML::FuelTypeElectricity, backup_eff: 1.0, backup_during_defrost: true, fan_motor_type: HPXML::HVACFanMotorTypePSC, **hvac_iq_values },
                                        { systype: HPXML::HVACTypeHeatPumpGroundToAir, fuel: HPXML::FuelTypeElectricity, comptype: HPXML::HVACCompressorTypeSingleStage, eer: 16.6, cop: 3.6, frac_load_heat: 0.1, frac_load_cool: 0.2, backup_fuel: HPXML::FuelTypeElectricity, backup_eff: 1.0, pump_w_per_ton: 100, fan_motor_type: HPXML::HVACFanMotorTypePSC, **hvac_iq_values },
                                        { systype: HPXML::HVACTypeHeatPumpMiniSplit, equiptype: HPXML::HVACEquipmentTypeSplit, fuel: HPXML::FuelTypeElectricity, comptype: HPXML::HVACCompressorTypeVariableSpeed, hspf2: 9, seer2: 19, eer2: 12.3, frac_load_heat: 0.1, frac_load_cool: 0.2, compressor_temp: -20.0, backup_fuel: HPXML::FuelTypeElectricity, backup_eff: 1.0, backup_during_defrost: true, fan_motor_type: HPXML::HVACFanMotorTypeBPM, **mshp_hvac_iq_values }])
        else
          hvac_iq_values = _get_default_hvac_iq_values(eri_version, 0.5)
          if run_type == RunType::CO2e # All-electric
            _check_heat_pump(hpxml_bldg, [{ systype: HPXML::HVACTypeHeatPumpAirToAir, equiptype: HPXML::HVACEquipmentTypeSplit, fuel: HPXML::FuelTypeElectricity, comptype: HPXML::HVACCompressorTypeSingleStage, hspf2: 6.55, seer2: 12.35, eer2: 10.7, frac_load_heat: 0.1, frac_load_cool: 0.0, dse: _dse(calc_type), compressor_temp: 0.0, backup_fuel: HPXML::FuelTypeElectricity, backup_eff: 1.0, backup_during_defrost: true, fan_motor_type: HPXML::HVACFanMotorTypePSC, **hvac_iq_values },
                                          { systype: HPXML::HVACTypeHeatPumpAirToAir, equiptype: HPXML::HVACEquipmentTypeSplit, fuel: HPXML::FuelTypeElectricity, comptype: HPXML::HVACCompressorTypeSingleStage, hspf2: 6.55, seer2: 12.35, eer2: 10.7, frac_load_heat: 0.1, frac_load_cool: 0.1333, dse: _dse(calc_type), compressor_temp: 0.0, backup_fuel: HPXML::FuelTypeElectricity, backup_eff: 1.0, backup_during_defrost: true, fan_motor_type: HPXML::HVACFanMotorTypePSC, **hvac_iq_values },
                                          { systype: HPXML::HVACTypeHeatPumpAirToAir, equiptype: HPXML::HVACEquipmentTypeSplit, fuel: HPXML::FuelTypeElectricity, comptype: HPXML::HVACCompressorTypeSingleStage, hspf2: 6.55, seer2: 12.35, eer2: 10.7, frac_load_heat: 0.1, frac_load_cool: 0.0, dse: _dse(calc_type), compressor_temp: 0.0, backup_fuel: HPXML::FuelTypeElectricity, backup_eff: 1.0, backup_during_defrost: true, fan_motor_type: HPXML::HVACFanMotorTypePSC, **hvac_iq_values },
                                          { systype: HPXML::HVACTypeHeatPumpAirToAir, equiptype: HPXML::HVACEquipmentTypeSplit, fuel: HPXML::FuelTypeElectricity, comptype: HPXML::HVACCompressorTypeSingleStage, hspf2: 6.55, seer2: 12.35, eer2: 10.7, frac_load_heat: 0.1, frac_load_cool: 0.0, dse: _dse(calc_type), compressor_temp: 0.0, backup_fuel: HPXML::FuelTypeElectricity, backup_eff: 1.0, backup_during_defrost: true, fan_motor_type: HPXML::HVACFanMotorTypePSC, **hvac_iq_values },
                                          { systype: HPXML::HVACTypeHeatPumpAirToAir, equiptype: HPXML::HVACEquipmentTypeSplit, fuel: HPXML::FuelTypeElectricity, comptype: HPXML::HVACCompressorTypeSingleStage, hspf2: 6.55, seer2: 12.35, eer2: 10.7, frac_load_heat: 0.1, frac_load_cool: 0.0, dse: _dse(calc_type), compressor_temp: 0.0, backup_fuel: HPXML::FuelTypeElectricity, backup_eff: 1.0, backup_during_defrost: true, fan_motor_type: HPXML::HVACFanMotorTypePSC, **hvac_iq_values },
                                          { systype: HPXML::HVACTypeHeatPumpAirToAir, equiptype: HPXML::HVACEquipmentTypeSplit, fuel: HPXML::FuelTypeElectricity, comptype: HPXML::HVACCompressorTypeSingleStage, hspf2: 6.55, seer2: 12.35, eer2: 10.7, frac_load_heat: 0.1, frac_load_cool: 0.0, dse: _dse(calc_type), compressor_temp: 0.0, backup_fuel: HPXML::FuelTypeElectricity, backup_eff: 1.0, backup_during_defrost: true, fan_motor_type: HPXML::HVACFanMotorTypePSC, **hvac_iq_values },
                                          { systype: HPXML::HVACTypeHeatPumpAirToAir, equiptype: HPXML::HVACEquipmentTypeSplit, fuel: HPXML::FuelTypeElectricity, comptype: HPXML::HVACCompressorTypeSingleStage, hspf2: 6.55, seer2: 12.35, eer2: 10.7, frac_load_heat: 0.1, frac_load_cool: 0.0, dse: _dse(calc_type), compressor_temp: 0.0, backup_fuel: HPXML::FuelTypeElectricity, backup_eff: 1.0, backup_during_defrost: true, fan_motor_type: HPXML::HVACFanMotorTypePSC, **hvac_iq_values },
                                          { systype: HPXML::HVACTypeHeatPumpAirToAir, equiptype: HPXML::HVACEquipmentTypeSplit, fuel: HPXML::FuelTypeElectricity, comptype: HPXML::HVACCompressorTypeSingleStage, hspf2: 6.55, seer2: 12.35, eer2: 10.7, frac_load_heat: 0.1, frac_load_cool: 0.2, dse: _dse(calc_type), compressor_temp: 0.0, backup_fuel: HPXML::FuelTypeElectricity, backup_eff: 1.0, backup_during_defrost: true, fan_motor_type: HPXML::HVACFanMotorTypePSC, **hvac_iq_values },
                                          { systype: HPXML::HVACTypeHeatPumpAirToAir, equiptype: HPXML::HVACEquipmentTypeSplit, fuel: HPXML::FuelTypeElectricity, comptype: HPXML::HVACCompressorTypeSingleStage, hspf2: 6.55, seer2: 12.35, eer2: 10.7, frac_load_heat: 0.1, frac_load_cool: 0.2, dse: _dse(calc_type), compressor_temp: 0.0, backup_fuel: HPXML::FuelTypeElectricity, backup_eff: 1.0, backup_during_defrost: true, fan_motor_type: HPXML::HVACFanMotorTypePSC, **hvac_iq_values },
                                          { systype: HPXML::HVACTypeHeatPumpAirToAir, equiptype: HPXML::HVACEquipmentTypeSplit, fuel: HPXML::FuelTypeElectricity, comptype: HPXML::HVACCompressorTypeSingleStage, hspf2: 6.55, seer2: 12.35, eer2: 10.7, frac_load_heat: 0.1, frac_load_cool: 0.2, dse: _dse(calc_type), compressor_temp: 0.0, backup_fuel: HPXML::FuelTypeElectricity, backup_eff: 1.0, backup_during_defrost: true, fan_motor_type: HPXML::HVACFanMotorTypePSC, **hvac_iq_values }])
            _check_cooling_system(hpxml_bldg, [{ systype: HPXML::HVACTypeCentralAirConditioner, equiptype: HPXML::HVACEquipmentTypeSplit, fuel: HPXML::FuelTypeElectricity, comptype: HPXML::HVACCompressorTypeSingleStage, seer2: 12.35, eer2: 10.7, frac_load: 0.1333, dse: _dse(calc_type), fan_motor_type: HPXML::HVACFanMotorTypePSC, **hvac_iq_values },
                                               { systype: HPXML::HVACTypeCentralAirConditioner, equiptype: HPXML::HVACEquipmentTypeSplit, fuel: HPXML::FuelTypeElectricity, comptype: HPXML::HVACCompressorTypeSingleStage, seer2: 12.35, eer2: 10.7, frac_load: 0.1333, dse: _dse(calc_type), fan_motor_type: HPXML::HVACFanMotorTypePSC, **hvac_iq_values }])
          else
            _check_heating_system(hpxml_bldg, [{ systype: HPXML::HVACTypeFurnace, fuel: HPXML::FuelTypeNaturalGas, eff: 0.78, frac_load: 0.1, dse: _dse(calc_type), fan_motor_type: HPXML::HVACFanMotorTypePSC, **hvac_iq_values },
                                               { systype: HPXML::HVACTypeBoiler, fuel: HPXML::FuelTypeNaturalGas, eff: 0.8, frac_load: 0.1, dse: _dse(calc_type), eae: 170 },
                                               { systype: HPXML::HVACTypeFurnace, fuel: HPXML::FuelTypeNaturalGas, eff: 0.78, frac_load: 0.1, dse: _dse(calc_type), fan_motor_type: HPXML::HVACFanMotorTypePSC, **hvac_iq_values },
                                               { systype: HPXML::HVACTypeFurnace, fuel: HPXML::FuelTypeNaturalGas, eff: 0.78, frac_load: 0.1, dse: _dse(calc_type), fan_motor_type: HPXML::HVACFanMotorTypePSC, **hvac_iq_values }])
            _check_heat_pump(hpxml_bldg, [{ systype: HPXML::HVACTypeHeatPumpAirToAir, equiptype: HPXML::HVACEquipmentTypeSplit, fuel: HPXML::FuelTypeElectricity, comptype: HPXML::HVACCompressorTypeSingleStage, hspf2: 6.55, seer2: 12.35, eer2: 10.7, frac_load_heat: 0.1, frac_load_cool: 0.0, dse: _dse(calc_type), compressor_temp: 0.0, backup_fuel: HPXML::FuelTypeElectricity, backup_eff: 1.0, backup_during_defrost: true, fan_motor_type: HPXML::HVACFanMotorTypePSC, **hvac_iq_values },
                                          { systype: HPXML::HVACTypeHeatPumpAirToAir, equiptype: HPXML::HVACEquipmentTypeSplit, fuel: HPXML::FuelTypeElectricity, comptype: HPXML::HVACCompressorTypeSingleStage, hspf2: 6.55, seer2: 12.35, eer2: 10.7, frac_load_heat: 0.1, frac_load_cool: 0.0, dse: _dse(calc_type), compressor_temp: 0.0, backup_fuel: HPXML::FuelTypeElectricity, backup_eff: 1.0, backup_during_defrost: true, fan_motor_type: HPXML::HVACFanMotorTypePSC, **hvac_iq_values },
                                          { systype: HPXML::HVACTypeHeatPumpAirToAir, equiptype: HPXML::HVACEquipmentTypeSplit, fuel: HPXML::FuelTypeElectricity, comptype: HPXML::HVACCompressorTypeSingleStage, hspf2: 6.55, seer2: 12.35, eer2: 10.7, frac_load_heat: 0.1, frac_load_cool: 0.0, dse: _dse(calc_type), compressor_temp: 0.0, backup_fuel: HPXML::FuelTypeElectricity, backup_eff: 1.0, backup_during_defrost: true, fan_motor_type: HPXML::HVACFanMotorTypePSC, **hvac_iq_values },
                                          { systype: HPXML::HVACTypeHeatPumpAirToAir, equiptype: HPXML::HVACEquipmentTypeSplit, fuel: HPXML::FuelTypeElectricity, comptype: HPXML::HVACCompressorTypeSingleStage, hspf2: 6.55, seer2: 12.35, eer2: 10.7, frac_load_heat: 0.1, frac_load_cool: 0.2, dse: _dse(calc_type), compressor_temp: 0.0, backup_fuel: HPXML::FuelTypeElectricity, backup_eff: 1.0, backup_during_defrost: true, fan_motor_type: HPXML::HVACFanMotorTypePSC, **hvac_iq_values },
                                          { systype: HPXML::HVACTypeHeatPumpAirToAir, equiptype: HPXML::HVACEquipmentTypeSplit, fuel: HPXML::FuelTypeElectricity, comptype: HPXML::HVACCompressorTypeSingleStage, hspf2: 6.55, seer2: 12.35, eer2: 10.7, frac_load_heat: 0.1, frac_load_cool: 0.2, dse: _dse(calc_type), compressor_temp: 0.0, backup_fuel: HPXML::FuelTypeElectricity, backup_eff: 1.0, backup_during_defrost: true, fan_motor_type: HPXML::HVACFanMotorTypePSC, **hvac_iq_values },
                                          { systype: HPXML::HVACTypeHeatPumpAirToAir, equiptype: HPXML::HVACEquipmentTypeSplit, fuel: HPXML::FuelTypeElectricity, comptype: HPXML::HVACCompressorTypeSingleStage, hspf2: 6.55, seer2: 12.35, eer2: 10.7, frac_load_heat: 0.1, frac_load_cool: 0.2, dse: _dse(calc_type), compressor_temp: 0.0, backup_fuel: HPXML::FuelTypeElectricity, backup_eff: 1.0, backup_during_defrost: true, fan_motor_type: HPXML::HVACFanMotorTypePSC, **hvac_iq_values }])
            _check_cooling_system(hpxml_bldg, [{ systype: HPXML::HVACTypeCentralAirConditioner, equiptype: HPXML::HVACEquipmentTypeSplit, fuel: HPXML::FuelTypeElectricity, comptype: HPXML::HVACCompressorTypeSingleStage, seer2: 12.35, eer2: 10.7, frac_load: 0.1333, dse: _dse(calc_type), fan_motor_type: HPXML::HVACFanMotorTypePSC, **hvac_iq_values },
                                               { systype: HPXML::HVACTypeCentralAirConditioner, equiptype: HPXML::HVACEquipmentTypeSplit, fuel: HPXML::FuelTypeElectricity, comptype: HPXML::HVACCompressorTypeSingleStage, seer2: 12.35, eer2: 10.7, frac_load: 0.1333, dse: _dse(calc_type), fan_motor_type: HPXML::HVACFanMotorTypePSC, **hvac_iq_values },
                                               { systype: HPXML::HVACTypeCentralAirConditioner, equiptype: HPXML::HVACEquipmentTypeSplit, fuel: HPXML::FuelTypeElectricity, comptype: HPXML::HVACCompressorTypeSingleStage, seer2: 12.35, eer2: 10.7, frac_load: 0.1333, dse: _dse(calc_type), fan_motor_type: HPXML::HVACFanMotorTypePSC, **hvac_iq_values }])
          end
        end
      end
    end
  end

  def test_partial_hvac
    # Create derivative file for testing
    hpxml_name = 'base.xml'
    hpxml = HPXML.new(hpxml_path: File.join(@root_path, 'workflow', 'sample_files', hpxml_name))
    hpxml_bldg = hpxml.buildings[0]
    hpxml_bldg.heating_systems[0].fraction_heat_load_served = 0.2
    hpxml_bldg.cooling_systems[0].fraction_cool_load_served = 0.3
    hpxml_name = File.basename(@tmp_hpxml_path)
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)

    _eri_versions.each do |eri_version|
      _test_ruleset(hpxml_name, eri_version).each do |(run_type, calc_type), hpxml_bldg|
        if [CalcType::RatedHome].include? calc_type
          hvac_iq_values = _get_default_hvac_iq_values(eri_version, 0.5)
          _check_cooling_system(hpxml_bldg, [{ systype: HPXML::HVACTypeCentralAirConditioner, equiptype: HPXML::HVACEquipmentTypeSplit, fuel: HPXML::FuelTypeElectricity, comptype: HPXML::HVACCompressorTypeSingleStage, seer2: 13.4, eer2: 11.3, frac_load: 0.3, fan_motor_type: HPXML::HVACFanMotorTypePSC, **hvac_iq_values },
                                             { systype: HPXML::HVACTypeCentralAirConditioner, equiptype: HPXML::HVACEquipmentTypeSplit, fuel: HPXML::FuelTypeElectricity, comptype: HPXML::HVACCompressorTypeSingleStage, seer2: 12.4, eer2: 10.7, frac_load: 0.7, dse: _dse(calc_type), fan_motor_type: HPXML::HVACFanMotorTypePSC, **hvac_iq_values }])
          _check_heating_system(hpxml_bldg, [{ systype: HPXML::HVACTypeFurnace, fuel: HPXML::FuelTypeNaturalGas, eff: 0.92, frac_load: 0.2, fan_motor_type: HPXML::HVACFanMotorTypePSC, **hvac_iq_values },
                                             { systype: HPXML::HVACTypeFurnace, fuel: HPXML::FuelTypeNaturalGas, eff: 0.78, frac_load: 0.8, dse: _dse(calc_type), fan_motor_type: HPXML::HVACFanMotorTypePSC, **hvac_iq_values }])
        else
          hvac_iq_values = _get_default_hvac_iq_values(eri_version, 0.5)
          if run_type == RunType::CO2e # All-electric
            _check_heat_pump(hpxml_bldg, [{ systype: HPXML::HVACTypeHeatPumpAirToAir, equiptype: HPXML::HVACEquipmentTypeSplit, fuel: HPXML::FuelTypeElectricity, comptype: HPXML::HVACCompressorTypeSingleStage, hspf2: 6.55, seer2: 12.35, eer2: 10.7, frac_load_heat: 0.2, frac_load_cool: 0.3, dse: _dse(calc_type), compressor_temp: 0.0, backup_fuel: HPXML::FuelTypeElectricity, backup_eff: 1.0, backup_during_defrost: true, fan_motor_type: HPXML::HVACFanMotorTypePSC, **hvac_iq_values },
                                          { systype: HPXML::HVACTypeHeatPumpAirToAir, equiptype: HPXML::HVACEquipmentTypeSplit, fuel: HPXML::FuelTypeElectricity, comptype: HPXML::HVACCompressorTypeSingleStage, hspf2: 6.55, seer2: 12.35, eer2: 10.7, frac_load_heat: 0.8, frac_load_cool: 0.0, dse: _dse(calc_type), compressor_temp: 0.0, backup_fuel: HPXML::FuelTypeElectricity, backup_eff: 1.0, backup_during_defrost: true, fan_motor_type: HPXML::HVACFanMotorTypePSC, **hvac_iq_values }])
            _check_cooling_system(hpxml_bldg, [{ systype: HPXML::HVACTypeCentralAirConditioner, equiptype: HPXML::HVACEquipmentTypeSplit, fuel: HPXML::FuelTypeElectricity, comptype: HPXML::HVACCompressorTypeSingleStage, seer2: 12.35, eer2: 10.7, frac_load: 0.7, dse: _dse(calc_type), fan_motor_type: HPXML::HVACFanMotorTypePSC, **hvac_iq_values }])
          else
            _check_heating_system(hpxml_bldg, [{ systype: HPXML::HVACTypeFurnace, fuel: HPXML::FuelTypeNaturalGas, eff: 0.78, frac_load: 0.2, dse: _dse(calc_type), fan_motor_type: HPXML::HVACFanMotorTypePSC, **hvac_iq_values },
                                               { systype: HPXML::HVACTypeFurnace, fuel: HPXML::FuelTypeNaturalGas, eff: 0.78, frac_load: 0.8, dse: _dse(calc_type), fan_motor_type: HPXML::HVACFanMotorTypePSC, **hvac_iq_values }])
            _check_cooling_system(hpxml_bldg, [{ systype: HPXML::HVACTypeCentralAirConditioner, equiptype: HPXML::HVACEquipmentTypeSplit, fuel: HPXML::FuelTypeElectricity, comptype: HPXML::HVACCompressorTypeSingleStage, seer2: 12.35, eer2: 10.7, frac_load: 0.3, dse: _dse(calc_type), fan_motor_type: HPXML::HVACFanMotorTypePSC, **hvac_iq_values },
                                               { systype: HPXML::HVACTypeCentralAirConditioner, equiptype: HPXML::HVACEquipmentTypeSplit, fuel: HPXML::FuelTypeElectricity, comptype: HPXML::HVACCompressorTypeSingleStage, seer2: 12.35, eer2: 10.7, frac_load: 0.7, dse: _dse(calc_type), fan_motor_type: HPXML::HVACFanMotorTypePSC, **hvac_iq_values }])
          end
        end
      end
    end
  end

  def test_shared_boiler_baseboard
    hpxml_name = 'base-bldgtype-mf-unit-shared-boiler-only-baseboard.xml'

    _eri_versions.each do |eri_version|
      _test_ruleset(hpxml_name, eri_version).each do |(run_type, calc_type), hpxml_bldg|
        if [CalcType::RatedHome].include? calc_type
          _check_heating_system(hpxml_bldg, [{ systype: HPXML::HVACTypeBoiler, fuel: HPXML::FuelTypeNaturalGas, eff: 0.92, frac_load: 1.0, num_units_served: 6, eae: 208 }])
        else
          hvac_iq_values = _get_default_hvac_iq_values(eri_version, 0.5)
          if run_type == RunType::CO2e # All-electric
            _check_heat_pump(hpxml_bldg, [{ systype: HPXML::HVACTypeHeatPumpAirToAir, equiptype: HPXML::HVACEquipmentTypeSplit, fuel: HPXML::FuelTypeElectricity, comptype: HPXML::HVACCompressorTypeSingleStage, hspf2: 6.55, seer2: 12.35, eer2: 10.7, frac_load_heat: 1.0, frac_load_cool: 0.0, dse: _dse(calc_type), compressor_temp: 0.0, backup_fuel: HPXML::FuelTypeElectricity, backup_eff: 1.0, backup_during_defrost: true, fan_motor_type: HPXML::HVACFanMotorTypePSC, **hvac_iq_values }])
          else
            _check_heating_system(hpxml_bldg, [{ systype: HPXML::HVACTypeBoiler, fuel: HPXML::FuelTypeNaturalGas, eff: 0.80, frac_load: 1.0, dse: _dse(calc_type), eae: 170 }])
          end
        end
      end
    end
  end

  def test_shared_boiler_fan_coil
    hpxml_name = 'base-bldgtype-mf-unit-shared-boiler-only-fan-coil.xml'

    _eri_versions.each do |eri_version|
      _test_ruleset(hpxml_name, eri_version).each do |(run_type, calc_type), hpxml_bldg|
        if [CalcType::RatedHome].include? calc_type
          _check_heating_system(hpxml_bldg, [{ systype: HPXML::HVACTypeBoiler, fuel: HPXML::FuelTypeNaturalGas, eff: 0.92, frac_load: 1.0, num_units_served: 6, eae: 520 }])
        else
          hvac_iq_values = _get_default_hvac_iq_values(eri_version, 0.5)
          if run_type == RunType::CO2e # All-electric
            _check_heat_pump(hpxml_bldg, [{ systype: HPXML::HVACTypeHeatPumpAirToAir, equiptype: HPXML::HVACEquipmentTypeSplit, fuel: HPXML::FuelTypeElectricity, comptype: HPXML::HVACCompressorTypeSingleStage, hspf2: 6.55, seer2: 12.35, eer2: 10.7, frac_load_heat: 1.0, frac_load_cool: 0.0, dse: _dse(calc_type), compressor_temp: 0.0, backup_fuel: HPXML::FuelTypeElectricity, backup_eff: 1.0, backup_during_defrost: true, fan_motor_type: HPXML::HVACFanMotorTypePSC, **hvac_iq_values }])
          else
            _check_heating_system(hpxml_bldg, [{ systype: HPXML::HVACTypeBoiler, fuel: HPXML::FuelTypeNaturalGas, eff: 0.80, frac_load: 1.0, dse: _dse(calc_type), eae: 170 }])
          end
        end
      end
    end
  end

  def test_shared_boiler_fan_coil_ducted
    hpxml_name = 'base-bldgtype-mf-unit-shared-boiler-only-fan-coil-ducted.xml'

    _eri_versions.each do |eri_version|
      _test_ruleset(hpxml_name, eri_version).each do |(run_type, calc_type), hpxml_bldg|
        if [CalcType::RatedHome].include? calc_type
          _check_heating_system(hpxml_bldg, [{ systype: HPXML::HVACTypeBoiler, fuel: HPXML::FuelTypeNaturalGas, eff: 0.92, frac_load: 1.0, num_units_served: 6, eae: 520 }])
        else
          hvac_iq_values = _get_default_hvac_iq_values(eri_version, 0.5)
          if run_type == RunType::CO2e # All-electric
            _check_heat_pump(hpxml_bldg, [{ systype: HPXML::HVACTypeHeatPumpAirToAir, equiptype: HPXML::HVACEquipmentTypeSplit, fuel: HPXML::FuelTypeElectricity, comptype: HPXML::HVACCompressorTypeSingleStage, hspf2: 6.55, seer2: 12.35, eer2: 10.7, frac_load_heat: 1.0, frac_load_cool: 0.0, dse: _dse(calc_type), compressor_temp: 0.0, backup_fuel: HPXML::FuelTypeElectricity, backup_eff: 1.0, backup_during_defrost: true, fan_motor_type: HPXML::HVACFanMotorTypePSC, **hvac_iq_values }])
          else
            _check_heating_system(hpxml_bldg, [{ systype: HPXML::HVACTypeBoiler, fuel: HPXML::FuelTypeNaturalGas, eff: 0.80, frac_load: 1.0, dse: _dse(calc_type), eae: 170 }])
          end
        end
      end
    end
  end

  def test_shared_boiler_water_loop_heat_pump
    hpxml_name = 'base-bldgtype-mf-unit-shared-boiler-only-water-loop-heat-pump.xml'

    _eri_versions.each do |eri_version|
      _test_ruleset(hpxml_name, eri_version).each do |(run_type, calc_type), hpxml_bldg|
        if [CalcType::RatedHome].include? calc_type
          _check_heating_system(hpxml_bldg, [{ systype: HPXML::HVACTypeBoiler, fuel: HPXML::FuelTypeNaturalGas, eff: 0.92, frac_load: 1.0, num_units_served: 6, eae: 208 }])
        else
          hvac_iq_values = _get_default_hvac_iq_values(eri_version, 0.5)
          if run_type == RunType::CO2e # All-electric
            _check_heat_pump(hpxml_bldg, [{ systype: HPXML::HVACTypeHeatPumpAirToAir, equiptype: HPXML::HVACEquipmentTypeSplit, fuel: HPXML::FuelTypeElectricity, comptype: HPXML::HVACCompressorTypeSingleStage, hspf2: 6.55, seer2: 12.35, eer2: 10.7, frac_load_heat: 1.0, frac_load_cool: 0.0, dse: _dse(calc_type), compressor_temp: 0.0, backup_fuel: HPXML::FuelTypeElectricity, backup_eff: 1.0, backup_during_defrost: true, fan_motor_type: HPXML::HVACFanMotorTypePSC, **hvac_iq_values }])
          else
            _check_heating_system(hpxml_bldg, [{ systype: HPXML::HVACTypeBoiler, fuel: HPXML::FuelTypeNaturalGas, eff: 0.80, frac_load: 1 - 1 / 4.4, dse: _dse(calc_type), eae: 170 }])
          end
        end
      end
    end
  end

  def test_shared_chiller_baseboard
    hpxml_name = 'base-bldgtype-mf-unit-shared-chiller-only-baseboard.xml'

    _eri_versions.each do |eri_version|
      _test_ruleset(hpxml_name, eri_version).each do |(_run_type, calc_type), hpxml_bldg|
        if [CalcType::RatedHome].include? calc_type
          _check_cooling_system(hpxml_bldg, [{ num_units_served: 6, systype: HPXML::HVACTypeChiller, fuel: HPXML::FuelTypeElectricity, kw_per_ton: 0.9, frac_load: 1.0, shared_loop_watts: 600 }])
        else
          hvac_iq_values = _get_default_hvac_iq_values(eri_version, 0.5)
          _check_cooling_system(hpxml_bldg, [{ systype: HPXML::HVACTypeCentralAirConditioner, equiptype: HPXML::HVACEquipmentTypeSplit, fuel: HPXML::FuelTypeElectricity, comptype: HPXML::HVACCompressorTypeSingleStage, seer2: 12.35, eer2: 10.7, frac_load: 1.0, dse: _dse(calc_type), fan_motor_type: HPXML::HVACFanMotorTypePSC, **hvac_iq_values }])
        end
      end
    end
  end

  def test_shared_chiller_fan_coil
    hpxml_name = 'base-bldgtype-mf-unit-shared-chiller-only-fan-coil.xml'

    _eri_versions.each do |eri_version|
      _test_ruleset(hpxml_name, eri_version).each do |(_run_type, calc_type), hpxml_bldg|
        if [CalcType::RatedHome].include? calc_type
          _check_cooling_system(hpxml_bldg, [{ num_units_served: 6, systype: HPXML::HVACTypeChiller, fuel: HPXML::FuelTypeElectricity, kw_per_ton: 0.9, frac_load: 1.0, shared_loop_watts: 600, fan_coil_watts: 150 }])
        else
          hvac_iq_values = _get_default_hvac_iq_values(eri_version, 0.5)
          _check_cooling_system(hpxml_bldg, [{ systype: HPXML::HVACTypeCentralAirConditioner, equiptype: HPXML::HVACEquipmentTypeSplit, fuel: HPXML::FuelTypeElectricity, comptype: HPXML::HVACCompressorTypeSingleStage, seer2: 12.35, eer2: 10.7, frac_load: 1.0, dse: _dse(calc_type), fan_motor_type: HPXML::HVACFanMotorTypePSC, **hvac_iq_values }])
        end
      end
    end
  end

  def test_shared_chiller_fan_coil_ducted
    hpxml_name = 'base-bldgtype-mf-unit-shared-chiller-only-fan-coil-ducted.xml'

    _eri_versions.each do |eri_version|
      _test_ruleset(hpxml_name, eri_version).each do |(_run_type, calc_type), hpxml_bldg|
        if [CalcType::RatedHome].include? calc_type
          _check_cooling_system(hpxml_bldg, [{ num_units_served: 6, systype: HPXML::HVACTypeChiller, fuel: HPXML::FuelTypeElectricity, kw_per_ton: 0.9, frac_load: 1.0, shared_loop_watts: 600, fan_coil_watts: 150 }])
        else
          hvac_iq_values = _get_default_hvac_iq_values(eri_version, 0.5)
          _check_cooling_system(hpxml_bldg, [{ systype: HPXML::HVACTypeCentralAirConditioner, equiptype: HPXML::HVACEquipmentTypeSplit, fuel: HPXML::FuelTypeElectricity, comptype: HPXML::HVACCompressorTypeSingleStage, seer2: 12.35, eer2: 10.7, frac_load: 1.0, dse: _dse(calc_type), fan_motor_type: HPXML::HVACFanMotorTypePSC, **hvac_iq_values }])
        end
      end
    end
  end

  def test_shared_chiller_water_loop_heat_pump
    hpxml_name = 'base-bldgtype-mf-unit-shared-chiller-only-water-loop-heat-pump.xml'

    _eri_versions.each do |eri_version|
      _test_ruleset(hpxml_name, eri_version).each do |(_run_type, calc_type), hpxml_bldg|
        if [CalcType::RatedHome].include? calc_type
          _check_cooling_system(hpxml_bldg, [{ num_units_served: 6, systype: HPXML::HVACTypeChiller, fuel: HPXML::FuelTypeElectricity, kw_per_ton: 0.9, frac_load: 1.0, shared_loop_watts: 600 }])
        else
          hvac_iq_values = _get_default_hvac_iq_values(eri_version, 0.5)
          _check_cooling_system(hpxml_bldg, [{ systype: HPXML::HVACTypeCentralAirConditioner, equiptype: HPXML::HVACEquipmentTypeSplit, fuel: HPXML::FuelTypeElectricity, comptype: HPXML::HVACCompressorTypeSingleStage, seer2: 12.35, eer2: 10.7, frac_load: 1.0, dse: _dse(calc_type), fan_motor_type: HPXML::HVACFanMotorTypePSC, **hvac_iq_values }])
        end
      end
    end
  end

  def test_shared_cooling_tower_water_loop_heat_pump
    hpxml_name = 'base-bldgtype-mf-unit-shared-cooling-tower-only-water-loop-heat-pump.xml'

    _eri_versions.each do |eri_version|
      _test_ruleset(hpxml_name, eri_version).each do |(_run_type, calc_type), hpxml_bldg|
        if [CalcType::RatedHome].include? calc_type
          _check_cooling_system(hpxml_bldg, [{ num_units_served: 6, systype: HPXML::HVACTypeCoolingTower, fuel: HPXML::FuelTypeElectricity, frac_load: 1.0, shared_loop_watts: 600 }])
        else
          hvac_iq_values = _get_default_hvac_iq_values(eri_version, 0.5)
          _check_cooling_system(hpxml_bldg, [{ systype: HPXML::HVACTypeCentralAirConditioner, equiptype: HPXML::HVACEquipmentTypeSplit, fuel: HPXML::FuelTypeElectricity, comptype: HPXML::HVACCompressorTypeSingleStage, seer2: 12.35, eer2: 10.7, frac_load: 1.0, dse: _dse(calc_type), fan_motor_type: HPXML::HVACFanMotorTypePSC, **hvac_iq_values }])
        end
      end
    end
  end

  def test_shared_ground_loop_ground_source_heat_pump
    hpxml_name = 'base-bldgtype-mf-unit-shared-ground-loop-ground-to-air-heat-pump.xml'

    _eri_versions.each do |eri_version|
      _test_ruleset(hpxml_name, eri_version).each do |(_run_type, calc_type), hpxml_bldg|
        hvac_iq_values = _get_default_hvac_iq_values(eri_version, 0.5)
        if [CalcType::RatedHome].include? calc_type
          _check_heat_pump(hpxml_bldg, [{ systype: HPXML::HVACTypeHeatPumpGroundToAir, fuel: HPXML::FuelTypeElectricity, comptype: HPXML::HVACCompressorTypeSingleStage, eer: 16.6, cop: 3.6, frac_load_heat: 1.0, frac_load_cool: 1.0, backup_fuel: HPXML::FuelTypeElectricity, backup_eff: 1.0, pump_w_per_ton: 0, num_units_served: 6, shared_loop_watts: 600, fan_motor_type: HPXML::HVACFanMotorTypePSC, **hvac_iq_values }])
        else
          _check_heat_pump(hpxml_bldg, [{ systype: HPXML::HVACTypeHeatPumpAirToAir, equiptype: HPXML::HVACEquipmentTypeSplit, fuel: HPXML::FuelTypeElectricity, comptype: HPXML::HVACCompressorTypeSingleStage, hspf2: 6.55, seer2: 12.35, eer2: 10.7, frac_load_heat: 1.0, frac_load_cool: 1.0, dse: _dse(calc_type), compressor_temp: 0.0, backup_fuel: HPXML::FuelTypeElectricity, backup_eff: 1.0, backup_during_defrost: true, fan_motor_type: HPXML::HVACFanMotorTypePSC, **hvac_iq_values }])
        end
      end
    end
  end

  def test_manual_thermostat
    hpxml_name = 'base.xml'

    _test_ruleset(hpxml_name).each do |(_run_type, _calc_type), hpxml_bldg|
      _check_thermostat(hpxml_bldg, control_type: HPXML::HVACControlTypeManual,
                                    htg_setpoints: '68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68',
                                    clg_setpoints: '78, 78, 78, 78, 78, 78, 78, 78, 78, 78, 78, 78, 78, 78, 78, 78, 78, 78, 78, 78, 78, 78, 78, 78')
    end
  end

  def test_programmable_thermostat
    hpxml_name = 'base-hvac-programmable-thermostat.xml'

    _test_ruleset(hpxml_name).each do |(_run_type, calc_type), hpxml_bldg|
      if [CalcType::RatedHome].include? calc_type
        _check_thermostat(hpxml_bldg, control_type: HPXML::HVACControlTypeProgrammable,
                                      htg_setpoints: '66, 66, 66, 66, 66, 67, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 66',
                                      clg_setpoints: '78, 78, 78, 78, 78, 78, 78, 78, 78, 80, 80, 80, 80, 80, 79, 78, 78, 78, 78, 78, 78, 78, 78, 78')
      else
        _check_thermostat(hpxml_bldg, control_type: HPXML::HVACControlTypeManual,
                                      htg_setpoints: '68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68',
                                      clg_setpoints: '78, 78, 78, 78, 78, 78, 78, 78, 78, 78, 78, 78, 78, 78, 78, 78, 78, 78, 78, 78, 78, 78, 78, 78')
      end
    end

    _test_ruleset(hpxml_name, '2019ABCD').each do |(_run_type, calc_type), hpxml_bldg|
      if [CalcType::RatedHome].include? calc_type
        _check_thermostat(hpxml_bldg, control_type: HPXML::HVACControlTypeProgrammable,
                                      htg_setpoints: '66, 66, 66, 66, 66, 66, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 66',
                                      clg_setpoints: '78, 78, 78, 78, 78, 78, 78, 78, 78, 80, 80, 80, 80, 80, 80, 78, 78, 78, 78, 78, 78, 78, 78, 78')
      else
        _check_thermostat(hpxml_bldg, control_type: HPXML::HVACControlTypeManual,
                                      htg_setpoints: '68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68',
                                      clg_setpoints: '78, 78, 78, 78, 78, 78, 78, 78, 78, 78, 78, 78, 78, 78, 78, 78, 78, 78, 78, 78, 78, 78, 78, 78')
      end
    end
  end

  def test_ducts
    hpxml_name = 'base.xml'

    _test_ruleset(hpxml_name).each do |(_run_type, calc_type), hpxml_bldg|
      if [CalcType::RatedHome].include? calc_type
        _check_ducts(hpxml_bldg, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 4.0, duct_area: 547.0, duct_location: HPXML::LocationAtticUnvented, duct_buried: HPXML::DuctBuriedInsulationNone },
                                  { duct_type: HPXML::DuctTypeReturn, duct_rvalue: 4.0, duct_area: 203.0, duct_location: HPXML::LocationAtticUnvented, duct_buried: HPXML::DuctBuriedInsulationNone },
                                  { duct_type: HPXML::DuctTypeSupply, duct_rvalue: 0.0, duct_area: 182.0, duct_location: HPXML::LocationConditionedSpace, duct_buried: HPXML::DuctBuriedInsulationNone },
                                  { duct_type: HPXML::DuctTypeReturn, duct_rvalue: 0.0, duct_area: 68.0, duct_location: HPXML::LocationConditionedSpace, duct_buried: HPXML::DuctBuriedInsulationNone }])
        _check_duct_leakage(hpxml_bldg, [{ duct_type: HPXML::DuctTypeSupply, duct_leakage_units: HPXML::UnitsCFM25, duct_leakage_value: 81.0, duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside },
                                         { duct_type: HPXML::DuctTypeReturn, duct_leakage_units: HPXML::UnitsCFM25, duct_leakage_value: 27.0, duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside }])
      else
        _check_ducts(hpxml_bldg)
        _check_duct_leakage(hpxml_bldg)
      end
    end
  end

  def test_ducts_cfm50
    hpxml_name = 'base-hvac-ducts-leakage-cfm50.xml'

    _test_ruleset(hpxml_name).each do |(_run_type, calc_type), hpxml_bldg|
      if [CalcType::RatedHome].include? calc_type
        _check_ducts(hpxml_bldg, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 4.0, duct_area: 547.0, duct_location: HPXML::LocationAtticUnvented, duct_buried: HPXML::DuctBuriedInsulationNone },
                                  { duct_type: HPXML::DuctTypeReturn, duct_rvalue: 4.0, duct_area: 203.0, duct_location: HPXML::LocationAtticUnvented, duct_buried: HPXML::DuctBuriedInsulationNone },
                                  { duct_type: HPXML::DuctTypeSupply, duct_rvalue: 0.0, duct_area: 182.0, duct_location: HPXML::LocationConditionedSpace, duct_buried: HPXML::DuctBuriedInsulationNone },
                                  { duct_type: HPXML::DuctTypeReturn, duct_rvalue: 0.0, duct_area: 68.0, duct_location: HPXML::LocationConditionedSpace, duct_buried: HPXML::DuctBuriedInsulationNone }])
        _check_duct_leakage(hpxml_bldg, [{ duct_type: HPXML::DuctTypeSupply, duct_leakage_units: HPXML::UnitsCFM50, duct_leakage_value: 101.0, duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside },
                                         { duct_type: HPXML::DuctTypeReturn, duct_leakage_units: HPXML::UnitsCFM50, duct_leakage_value: 34.0, duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside }])
      else
        _check_ducts(hpxml_bldg)
        _check_duct_leakage(hpxml_bldg)
      end
    end
  end

  def test_ducts_buried
    hpxml_name = 'base-hvac-ducts-buried.xml'

    _test_ruleset(hpxml_name).each do |(_run_type, calc_type), hpxml_bldg|
      if [CalcType::RatedHome].include? calc_type
        _check_ducts(hpxml_bldg, [{ duct_type: HPXML::DuctTypeSupply, duct_rvalue: 4.0, duct_area: 547.0, duct_location: HPXML::LocationAtticUnvented, duct_buried: HPXML::DuctBuriedInsulationDeep },
                                  { duct_type: HPXML::DuctTypeReturn, duct_rvalue: 4.0, duct_area: 203.0, duct_location: HPXML::LocationAtticUnvented, duct_buried: HPXML::DuctBuriedInsulationDeep },
                                  { duct_type: HPXML::DuctTypeSupply, duct_rvalue: 0.0, duct_area: 182.0, duct_location: HPXML::LocationConditionedSpace, duct_buried: HPXML::DuctBuriedInsulationNone },
                                  { duct_type: HPXML::DuctTypeReturn, duct_rvalue: 0.0, duct_area: 68.0, duct_location: HPXML::LocationConditionedSpace, duct_buried: HPXML::DuctBuriedInsulationNone }])
        _check_duct_leakage(hpxml_bldg, [{ duct_type: HPXML::DuctTypeSupply, duct_leakage_units: HPXML::UnitsCFM25, duct_leakage_value: 81.0, duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside },
                                         { duct_type: HPXML::DuctTypeReturn, duct_leakage_units: HPXML::UnitsCFM25, duct_leakage_value: 27.0, duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside }])
      else
        _check_ducts(hpxml_bldg)
        _check_duct_leakage(hpxml_bldg)
      end
    end
  end

  def test_dse
    hpxml_name = 'base-hvac-dse.xml'

    _test_ruleset(hpxml_name).each do |(run_type, calc_type), hpxml_bldg|
      if [CalcType::RatedHome].include? calc_type
        hvac_iq_values = _get_default_hvac_iq_values('latest', 0.5)
        _check_cooling_system(hpxml_bldg, [{ systype: HPXML::HVACTypeCentralAirConditioner, equiptype: HPXML::HVACEquipmentTypeSplit, fuel: HPXML::FuelTypeElectricity, comptype: HPXML::HVACCompressorTypeSingleStage, seer2: 13.4, eer2: 11.3, frac_load: 1.0, dse: 0.7, fan_motor_type: HPXML::HVACFanMotorTypePSC, **hvac_iq_values }])
        _check_heating_system(hpxml_bldg, [{ systype: HPXML::HVACTypeFurnace, fuel: HPXML::FuelTypeNaturalGas, eff: 0.92, frac_load: 1.0, dse: _dse(calc_type), fan_motor_type: HPXML::HVACFanMotorTypePSC, **hvac_iq_values }])
      else
        hvac_iq_values = _get_default_hvac_iq_values('latest', 0.5)
        if run_type == RunType::CO2e # All-electric
          _check_heat_pump(hpxml_bldg, [{ systype: HPXML::HVACTypeHeatPumpAirToAir, equiptype: HPXML::HVACEquipmentTypeSplit, fuel: HPXML::FuelTypeElectricity, comptype: HPXML::HVACCompressorTypeSingleStage, hspf2: 6.55, seer2: 12.35, eer2: 10.7, frac_load_heat: 1.0, frac_load_cool: 1.0, dse: _dse(calc_type), compressor_temp: 0.0, backup_fuel: HPXML::FuelTypeElectricity, backup_eff: 1.0, backup_during_defrost: true, fan_motor_type: HPXML::HVACFanMotorTypePSC, **hvac_iq_values }])
        else
          _check_heating_system(hpxml_bldg, [{ systype: HPXML::HVACTypeFurnace, fuel: HPXML::FuelTypeNaturalGas, eff: 0.78, frac_load: 1.0, dse: _dse(calc_type), fan_motor_type: HPXML::HVACFanMotorTypePSC, **hvac_iq_values }])
          _check_cooling_system(hpxml_bldg, [{ systype: HPXML::HVACTypeCentralAirConditioner, equiptype: HPXML::HVACEquipmentTypeSplit, fuel: HPXML::FuelTypeElectricity, comptype: HPXML::HVACCompressorTypeSingleStage, seer2: 12.35, eer2: 10.7, frac_load: 1.0, dse: _dse(calc_type), fan_motor_type: HPXML::HVACFanMotorTypePSC, **hvac_iq_values }])
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
        assert_in_delta(expected_values[:eff], heating_system.heating_efficiency_afue.to_f + heating_system.heating_efficiency_percent.to_f, 0.1)
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
        assert_in_epsilon(expected_values[:eae], heating_system.electric_auxiliary_energy, 0.1)
      end
      dist_system = heating_system.distribution_system
      if expected_values[:dse].nil?
        assert(dist_system.nil? || dist_system.annual_heating_dse.nil?)
      else
        assert_equal(expected_values[:dse], dist_system.annual_heating_dse)
      end
      if expected_values[:fan_motor_type].nil?
        assert_nil(heating_system.fan_motor_type)
      else
        assert_equal(expected_values[:fan_motor_type], heating_system.fan_motor_type)
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
      if not expected_values[:comptype].nil?
        assert_equal(expected_values[:comptype], heat_pump.compressor_type)
      else
        assert_nil(heat_pump.compressor_type)
      end
      if not expected_values[:hspf2].nil?
        assert_in_delta(expected_values[:hspf2], heat_pump.heating_efficiency_hspf2, 0.1)
      else
        assert_nil(heat_pump.heating_efficiency_hspf2)
      end
      if not expected_values[:cop].nil?
        assert_in_delta(expected_values[:cop], heat_pump.heating_efficiency_cop, 0.1)
      else
        assert_nil(heat_pump.heating_efficiency_cop)
      end
      if not expected_values[:seer2].nil?
        assert_in_delta(expected_values[:seer2], heat_pump.cooling_efficiency_seer2, 0.1)
      else
        assert_nil(heat_pump.cooling_efficiency_seer2)
      end
      if not expected_values[:eer2].nil?
        assert_in_delta(expected_values[:eer2], heat_pump.cooling_efficiency_eer2, 0.1)
      else
        assert_nil(heat_pump.cooling_efficiency_eer2)
      end
      if not expected_values[:eer].nil?
        assert_in_delta(expected_values[:eer], heat_pump.cooling_efficiency_eer, 0.1)
      else
        assert_nil(heat_pump.cooling_efficiency_eer)
      end
      if not expected_values[:ceer].nil?
        assert_in_delta(expected_values[:ceer], heat_pump.cooling_efficiency_ceer, 0.1)
      else
        assert_nil(heat_pump.cooling_efficiency_ceer)
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
        assert_in_delta(expected_values[:backup_eff], heat_pump.backup_heating_efficiency_percent.to_f + heat_pump.backup_heating_efficiency_afue.to_f, 0.1)
        assert_equal(HPXML::HeatPumpBackupTypeIntegrated, heat_pump.backup_type)
      end
      if heat_pump.heat_pump_type != HPXML::HVACTypeHeatPumpGroundToAir
        assert_equal(80, heat_pump.backup_heating_lockout_temp)
      else
        assert_nil(heat_pump.backup_heating_lockout_temp)
      end
      assert_nil(heat_pump.backup_heating_switchover_temp)
      if expected_values[:backup_during_defrost].nil?
        assert_nil(heat_pump.backup_heating_active_during_defrost)
      else
        assert_equal(heat_pump.backup_heating_active_during_defrost, expected_values[:backup_during_defrost])
      end
      if expected_values[:compressor_temp].nil?
        assert_nil(heat_pump.compressor_lockout_temp)
      else
        assert_equal(expected_values[:compressor_temp], heat_pump.compressor_lockout_temp)
      end
      if expected_values[:pump_w_per_ton].nil?
        assert_nil(heat_pump.pump_watts_per_ton)
      else
        assert_equal(expected_values[:pump_w_per_ton], heat_pump.pump_watts_per_ton)
      end
      if expected_values[:fan_motor_type].nil?
        assert_nil(heat_pump.fan_motor_type)
      else
        assert_equal(expected_values[:fan_motor_type], heat_pump.fan_motor_type)
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
      if [HPXML::HVACTypeHeatPumpAirToAir,
          HPXML::HVACTypeHeatPumpMiniSplit].include? heat_pump.heat_pump_type
        assert_equal(HPXML::HVACPanHeaterControlTypeContinuous, heat_pump.pan_heater_control_type)
        assert_equal(150.0, heat_pump.pan_heater_watts)
        if heat_pump.cooling_capacity > 0
          assert_equal(10.0 * UnitConversions.convert(heat_pump.cooling_capacity, 'Btu/hr', 'ton'), heat_pump.crankcase_heater_watts)
        else
          assert_equal(10.0 * UnitConversions.convert(heat_pump.heating_capacity, 'Btu/hr', 'ton'), heat_pump.crankcase_heater_watts)
        end
      else
        assert_nil(heat_pump.pan_heater_control_type)
        assert_equal(0.0, heat_pump.pan_heater_watts.to_f)
        assert_equal(0.0, heat_pump.crankcase_heater_watts.to_f)
      end
      if expected_values[:equiptype].nil?
        assert_nil(heat_pump.equipment_type)
      else
        assert_equal(expected_values[:equiptype], heat_pump.equipment_type)
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
      if not expected_values[:comptype].nil?
        assert_equal(expected_values[:comptype], cooling_system.compressor_type)
      else
        assert_nil(cooling_system.compressor_type)
      end
      if not expected_values[:seer2].nil?
        assert_in_delta(expected_values[:seer2], cooling_system.cooling_efficiency_seer2, 0.1)
      else
        assert_nil(cooling_system.cooling_efficiency_seer2)
      end
      if not expected_values[:eer2].nil?
        assert_in_delta(expected_values[:eer2], cooling_system.cooling_efficiency_eer2, 0.1)
      else
        assert_nil(cooling_system.cooling_efficiency_eer2)
      end
      if not expected_values[:ceer].nil?
        assert_in_delta(expected_values[:ceer], cooling_system.cooling_efficiency_ceer, 0.1)
      else
        assert_nil(cooling_system.cooling_efficiency_ceer)
      end
      if not expected_values[:kw_per_ton].nil?
        assert_in_delta(expected_values[:kw_per_ton], cooling_system.cooling_efficiency_kw_per_ton, 0.1)
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
      if expected_values[:fan_motor_type].nil?
        assert_nil(cooling_system.fan_motor_type)
      else
        assert_equal(expected_values[:fan_motor_type], cooling_system.fan_motor_type)
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
      if expected_values[:integrated_htg_fuel].nil?
        assert_nil(cooling_system.integrated_heating_system_fuel)
      else
        assert_equal(expected_values[:integrated_htg_fuel], cooling_system.integrated_heating_system_fuel)
      end
      if expected_values[:integrated_htg_eff].nil?
        assert_nil(cooling_system.integrated_heating_system_efficiency_percent)
      else
        assert_in_epsilon(expected_values[:integrated_htg_eff], cooling_system.integrated_heating_system_efficiency_percent, 0.1)
      end
      if expected_values[:integrated_htg_frac_load].nil?
        assert_nil(cooling_system.integrated_heating_system_fraction_heat_load_served)
      else
        assert_equal(expected_values[:integrated_htg_frac_load], cooling_system.integrated_heating_system_fraction_heat_load_served)
      end
      if [HPXML::HVACTypeCentralAirConditioner,
          HPXML::HVACTypeMiniSplitAirConditioner].include? cooling_system.cooling_system_type
        assert_equal(10.0 * UnitConversions.convert(cooling_system.cooling_capacity, 'Btu/hr', 'ton'), cooling_system.crankcase_heater_watts)
      else
        assert_equal(0.0, cooling_system.crankcase_heater_watts.to_f)
      end
      if expected_values[:equiptype].nil?
        assert_nil(cooling_system.equipment_type)
      else
        assert_equal(expected_values[:equiptype], cooling_system.equipment_type)
      end
    end
  end

  def _check_thermostat(hpxml_bldg, control_type:, htg_setpoints:, clg_setpoints:)
    assert_equal(1, hpxml_bldg.hvac_controls.size)
    hvac_control = hpxml_bldg.hvac_controls[0]
    assert_equal(control_type, hvac_control.control_type)

    if htg_setpoints.nil?
      assert_nil(hvac_control.weekday_heating_setpoints)
      assert_nil(hvac_control.weekend_heating_setpoints)
    else
      assert_equal(htg_setpoints.split(', ').map(&:to_f), hvac_control.weekday_heating_setpoints.split(', ').map(&:to_f))
      assert_equal(htg_setpoints.split(', ').map(&:to_f), hvac_control.weekend_heating_setpoints.split(', ').map(&:to_f))
    end

    if clg_setpoints.nil?
      assert_nil(hvac_control.weekday_cooling_setpoints)
      assert_nil(hvac_control.weekend_cooling_setpoints)
    else
      assert_equal(clg_setpoints.split(', ').map(&:to_f), hvac_control.weekday_cooling_setpoints.split(', ').map(&:to_f))
      assert_equal(clg_setpoints.split(', ').map(&:to_f), hvac_control.weekend_cooling_setpoints.split(', ').map(&:to_f))
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
          assert_equal(duct_leakage_measurements[idx][:duct_type], duct_leakage_measurement.duct_type)
        end
        if duct_leakage_measurements[idx][:duct_leakage_units].nil?
          assert_nil(duct_leakage_measurement.duct_leakage_units)
        else
          assert_equal(duct_leakage_measurements[idx][:duct_leakage_units], duct_leakage_measurement.duct_leakage_units)
        end
        if duct_leakage_measurements[idx][:duct_leakage_value].nil?
          assert_nil(duct_leakage_measurement.duct_leakage_value)
        else
          assert_in_epsilon(duct_leakage_measurements[idx][:duct_leakage_value], duct_leakage_measurement.duct_leakage_value, 0.01)
        end
        if duct_leakage_measurements[idx][:duct_leakage_total_or_to_outside].nil?
          assert_nil(duct_leakage_measurement.duct_leakage_total_or_to_outside)
        else
          assert_equal(duct_leakage_measurements[idx][:duct_leakage_total_or_to_outside], duct_leakage_measurement.duct_leakage_total_or_to_outside)
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
          assert_equal(ducts[idx][:duct_type], duct.duct_type)
        end
        if ducts[idx][:duct_area].nil?
          assert_nil(duct.duct_surface_area)
        else
          assert_in_epsilon(ducts[idx][:duct_area], Float(duct.duct_surface_area), 0.01)
        end
        if ducts[idx][:duct_rvalue].nil?
          assert_nil(duct.duct_insulation_r_value)
        else
          assert_equal(ducts[idx][:duct_rvalue], Float(duct.duct_insulation_r_value))
        end
        if ducts[idx][:duct_location].nil?
          assert_nil(duct.duct_location)
        else
          assert_equal(ducts[idx][:duct_location], duct.duct_location)
        end
        if ducts[idx][:duct_buried].nil?
          assert_nil(duct.duct_buried_insulation_level)
        else
          assert_equal(ducts[idx][:duct_buried], duct.duct_buried_insulation_level)
        end
        idx += 1
      end
    end
  end
end
