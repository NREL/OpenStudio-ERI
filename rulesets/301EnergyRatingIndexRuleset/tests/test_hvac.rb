# frozen_string_literal: true

require_relative '../../../workflow/tests/minitest_helper'
require 'openstudio'
require 'openstudio/measure/ShowRunnerOutput'
require 'minitest/autorun'
require_relative '../measure.rb'
require 'fileutils'
require_relative 'util.rb'

class ERIHVACtest < MiniTest::Test
  def before_setup
    @root_path = File.absolute_path(File.join(File.dirname(__FILE__), '..', '..', '..'))
    @tmp_hpxml_path = File.join(@root_path, 'workflow', 'sample_files', 'tmp.xml')
  end

  def after_teardown
    File.delete(@tmp_hpxml_path) if File.exist? @tmp_hpxml_path
  end

  def _eri_versions
    return ['latest', '2019A'] # Test HVAC installation quality both after and before 301-2019 Addendum A
  end

  def _dse(calc_type)
    if calc_type == Constants.CalcTypeERIIndexAdjustmentDesign
      return 1.0
    else
      return 0.8
    end
  end

  def test_none
    hpxml_name = 'base-hvac-none.xml'

    _eri_versions.each do |eri_version|
      hpxml_name = _change_eri_version(hpxml_name, eri_version) unless eri_version == 'latest'
      calc_types = [Constants.CalcTypeERIReferenceHome,
                    Constants.CalcTypeERIRatedHome,
                    Constants.CalcTypeERIIndexAdjustmentDesign,
                    Constants.CalcTypeERIIndexAdjustmentReferenceHome]
      calc_types.each do |calc_type|
        hpxml = _test_measure(hpxml_name, calc_type)
        _check_heating_system(hpxml, calc_type, [{ systype: HPXML::HVACTypeFurnace, fuel: HPXML::FuelTypeNaturalGas, eff: 0.78, dse: _dse(calc_type) }])
        _check_cooling_system(hpxml, calc_type, [{ systype: HPXML::HVACTypeCentralAirConditioner, fuel: HPXML::FuelTypeElectricity, comptype: HPXML::HVACCompressorTypeSingleStage, seer: 13, dse: _dse(calc_type) }])
        _check_heat_pump(hpxml, calc_type)
        _check_thermostat(hpxml, control_type: HPXML::HVACControlTypeManual, htg_sp: 68, clg_sp: 78)
      end
    end
  end

  def test_none_with_no_fuel_access
    hpxml_name = 'base-hvac-none.xml'
    hpxml = HPXML.new(hpxml_path: File.join(@root_path, 'workflow', 'sample_files', hpxml_name))
    hpxml.site.fuels = [HPXML::FuelTypeElectricity]
    hpxml_name = File.basename(@tmp_hpxml_path)
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)

    _eri_versions.each do |eri_version|
      hpxml_name = _change_eri_version(hpxml_name, eri_version) unless eri_version == 'latest'
      calc_types = [Constants.CalcTypeERIReferenceHome,
                    Constants.CalcTypeERIRatedHome,
                    Constants.CalcTypeERIIndexAdjustmentDesign,
                    Constants.CalcTypeERIIndexAdjustmentReferenceHome]
      calc_types.each do |calc_type|
        hpxml = _test_measure(hpxml_name, calc_type)
        _check_heat_pump(hpxml, calc_type, [{ systype: HPXML::HVACTypeHeatPumpAirToAir, fuel: HPXML::FuelTypeElectricity, comptype: HPXML::HVACCompressorTypeSingleStage, hspf: 7.7, seer: 13, dse: _dse(calc_type), backup_fuel: HPXML::FuelTypeElectricity, backup_eff: 1.0, frac_load_cool: 0.0 }])
        _check_cooling_system(hpxml, calc_type, [{ systype: HPXML::HVACTypeCentralAirConditioner, fuel: HPXML::FuelTypeElectricity, comptype: HPXML::HVACCompressorTypeSingleStage, seer: 13, dse: _dse(calc_type) }])
        _check_heating_system(hpxml, calc_type)
        _check_thermostat(hpxml, control_type: HPXML::HVACControlTypeManual, htg_sp: 68, clg_sp: 78)
      end
    end
  end

  def test_boiler_elec
    hpxml_name = 'base-hvac-boiler-elec-only.xml'

    _eri_versions.each do |eri_version|
      hpxml_name = _change_eri_version(hpxml_name, eri_version) unless eri_version == 'latest'
      calc_types = [Constants.CalcTypeERIReferenceHome,
                    Constants.CalcTypeERIIndexAdjustmentDesign,
                    Constants.CalcTypeERIIndexAdjustmentReferenceHome]
      calc_types.each do |calc_type|
        hpxml = _test_measure(hpxml_name, calc_type)
        _check_heat_pump(hpxml, calc_type, [{ systype: HPXML::HVACTypeHeatPumpAirToAir, fuel: HPXML::FuelTypeElectricity, comptype: HPXML::HVACCompressorTypeSingleStage, hspf: 7.7, seer: 13, dse: _dse(calc_type), backup_fuel: HPXML::FuelTypeElectricity, backup_eff: 1.0, frac_load_cool: 0.0 }])
        _check_cooling_system(hpxml, calc_type, [{ systype: HPXML::HVACTypeCentralAirConditioner, fuel: HPXML::FuelTypeElectricity, comptype: HPXML::HVACCompressorTypeSingleStage, seer: 13, dse: _dse(calc_type) }])
        _check_heating_system(hpxml, calc_type)
        _check_thermostat(hpxml, control_type: HPXML::HVACControlTypeManual, htg_sp: 68, clg_sp: 78)
      end
      calc_type = Constants.CalcTypeERIRatedHome
      hpxml = _test_measure(hpxml_name, calc_type)
      _check_heating_system(hpxml, calc_type, [{ systype: HPXML::HVACTypeBoiler, fuel: HPXML::FuelTypeElectricity, eff: 1.0, eae: 170 }])
      _check_cooling_system(hpxml, calc_type, [{ systype: HPXML::HVACTypeCentralAirConditioner, fuel: HPXML::FuelTypeElectricity, comptype: HPXML::HVACCompressorTypeSingleStage, seer: 13, dse: _dse(calc_type) }])
      _check_heat_pump(hpxml, calc_type)
      _check_thermostat(hpxml, control_type: HPXML::HVACControlTypeManual, htg_sp: 68, clg_sp: 78)
    end
  end

  def test_boiler_gas
    hpxml_name = 'base-hvac-boiler-gas-only.xml'

    _eri_versions.each do |eri_version|
      hpxml_name = _change_eri_version(hpxml_name, eri_version) unless eri_version == 'latest'
      calc_types = [Constants.CalcTypeERIReferenceHome,
                    Constants.CalcTypeERIIndexAdjustmentDesign,
                    Constants.CalcTypeERIIndexAdjustmentReferenceHome]
      calc_types.each do |calc_type|
        hpxml = _test_measure(hpxml_name, calc_type)
        _check_heating_system(hpxml, calc_type, [{ systype: HPXML::HVACTypeBoiler, fuel: HPXML::FuelTypeNaturalGas, eff: 0.80, dse: _dse(calc_type), eae: 170 }])
        _check_cooling_system(hpxml, calc_type, [{ systype: HPXML::HVACTypeCentralAirConditioner, fuel: HPXML::FuelTypeElectricity, comptype: HPXML::HVACCompressorTypeSingleStage, seer: 13, dse: _dse(calc_type) }])
        _check_heat_pump(hpxml, calc_type)
        _check_thermostat(hpxml, control_type: HPXML::HVACControlTypeManual, htg_sp: 68, clg_sp: 78)
      end
      calc_type = Constants.CalcTypeERIRatedHome
      hpxml = _test_measure(hpxml_name, calc_type)
      _check_heating_system(hpxml, calc_type, [{ systype: HPXML::HVACTypeBoiler, fuel: HPXML::FuelTypeNaturalGas, eff: 0.92, eae: 200 }])
      _check_cooling_system(hpxml, calc_type, [{ systype: HPXML::HVACTypeCentralAirConditioner, fuel: HPXML::FuelTypeElectricity, comptype: HPXML::HVACCompressorTypeSingleStage, seer: 13, dse: _dse(calc_type) }])
      _check_heat_pump(hpxml, calc_type)
      _check_thermostat(hpxml, control_type: HPXML::HVACControlTypeManual, htg_sp: 68, clg_sp: 78)
    end
  end

  def test_furnace_elec
    hpxml_name = 'base-hvac-furnace-elec-only.xml'

    _eri_versions.each do |eri_version|
      hpxml_name = _change_eri_version(hpxml_name, eri_version) unless eri_version == 'latest'
      calc_types = [Constants.CalcTypeERIReferenceHome,
                    Constants.CalcTypeERIIndexAdjustmentDesign,
                    Constants.CalcTypeERIIndexAdjustmentReferenceHome]
      calc_types.each do |calc_type|
        hpxml = _test_measure(hpxml_name, calc_type)
        _check_heat_pump(hpxml, calc_type, [{ systype: HPXML::HVACTypeHeatPumpAirToAir, fuel: HPXML::FuelTypeElectricity, comptype: HPXML::HVACCompressorTypeSingleStage, hspf: 7.7, seer: 13, dse: _dse(calc_type), backup_fuel: HPXML::FuelTypeElectricity, backup_eff: 1.0, frac_load_cool: 0.0 }])
        _check_cooling_system(hpxml, calc_type, [{ systype: HPXML::HVACTypeCentralAirConditioner, fuel: HPXML::FuelTypeElectricity, comptype: HPXML::HVACCompressorTypeSingleStage, seer: 13, dse: _dse(calc_type) }])
        _check_heating_system(hpxml, calc_type)
        _check_thermostat(hpxml, control_type: HPXML::HVACControlTypeManual, htg_sp: 68, clg_sp: 78)
      end
      calc_type = Constants.CalcTypeERIRatedHome
      hpxml = _test_measure(hpxml_name, calc_type)
      _check_heating_system(hpxml, calc_type, [{ systype: HPXML::HVACTypeFurnace, fuel: HPXML::FuelTypeElectricity, eff: 1.0 }])
      _check_cooling_system(hpxml, calc_type, [{ systype: HPXML::HVACTypeCentralAirConditioner, fuel: HPXML::FuelTypeElectricity, comptype: HPXML::HVACCompressorTypeSingleStage, seer: 13, dse: _dse(calc_type) }])
      _check_heat_pump(hpxml, calc_type)
      _check_thermostat(hpxml, control_type: HPXML::HVACControlTypeManual, htg_sp: 68, clg_sp: 78)
    end
  end

  def test_furnace_gas
    hpxml_names = ['base-hvac-furnace-gas-only.xml',
                   'base-hvac-install-qual-all-furnace-gas-only.xml']

    hpxml_names.each do |hpxml_name|
      _eri_versions.each do |eri_version|
        hpxml_name = _change_eri_version(hpxml_name, eri_version) unless eri_version == 'latest'
        calc_types = [Constants.CalcTypeERIReferenceHome,
                      Constants.CalcTypeERIIndexAdjustmentDesign,
                      Constants.CalcTypeERIIndexAdjustmentReferenceHome]
        calc_types.each do |calc_type|
          hpxml = _test_measure(hpxml_name, calc_type)
          _check_heating_system(hpxml, calc_type, [{ systype: HPXML::HVACTypeFurnace, fuel: HPXML::FuelTypeNaturalGas, eff: 0.78, dse: _dse(calc_type) }])
          _check_cooling_system(hpxml, calc_type, [{ systype: HPXML::HVACTypeCentralAirConditioner, fuel: HPXML::FuelTypeElectricity, comptype: HPXML::HVACCompressorTypeSingleStage, seer: 13, dse: _dse(calc_type) }])
          _check_heat_pump(hpxml, calc_type)
          _check_thermostat(hpxml, control_type: HPXML::HVACControlTypeManual, htg_sp: 68, clg_sp: 78)
        end
        calc_type = Constants.CalcTypeERIRatedHome
        if hpxml_name.include?('install-qual') && eri_version == 'latest'
          hvac_install_qual_values = { fan_watts_per_cfm: 0.365, airflow_defect_ratio: -0.25 }
        else
          hvac_install_qual_values = {}
        end
        hpxml = _test_measure(hpxml_name, calc_type)
        _check_heating_system(hpxml, calc_type, [{ systype: HPXML::HVACTypeFurnace, fuel: HPXML::FuelTypeNaturalGas, eff: 0.92, **hvac_install_qual_values }])
        _check_cooling_system(hpxml, calc_type, [{ systype: HPXML::HVACTypeCentralAirConditioner, fuel: HPXML::FuelTypeElectricity, comptype: HPXML::HVACCompressorTypeSingleStage, seer: 13, dse: _dse(calc_type) }])
        _check_heat_pump(hpxml, calc_type)
        _check_thermostat(hpxml, control_type: HPXML::HVACControlTypeManual, htg_sp: 68, clg_sp: 78)
      end
    end
  end

  def test_stove_oil
    hpxml_name = 'base-hvac-stove-oil-only.xml'

    _eri_versions.each do |eri_version|
      hpxml_name = _change_eri_version(hpxml_name, eri_version) unless eri_version == 'latest'
      calc_types = [Constants.CalcTypeERIReferenceHome,
                    Constants.CalcTypeERIIndexAdjustmentDesign,
                    Constants.CalcTypeERIIndexAdjustmentReferenceHome]
      calc_types.each do |calc_type|
        hpxml = _test_measure(hpxml_name, calc_type)
        _check_heating_system(hpxml, calc_type, [{ systype: HPXML::HVACTypeFurnace, fuel: HPXML::FuelTypeNaturalGas, eff: 0.78, dse: _dse(calc_type) }])
        _check_cooling_system(hpxml, calc_type, [{ systype: HPXML::HVACTypeCentralAirConditioner, fuel: HPXML::FuelTypeElectricity, comptype: HPXML::HVACCompressorTypeSingleStage, seer: 13, dse: _dse(calc_type) }])
        _check_heat_pump(hpxml, calc_type)
        _check_thermostat(hpxml, control_type: HPXML::HVACControlTypeManual, htg_sp: 68, clg_sp: 78)
      end
      calc_type = Constants.CalcTypeERIRatedHome
      hpxml = _test_measure(hpxml_name, calc_type)
      _check_heating_system(hpxml, calc_type, [{ systype: HPXML::HVACTypeStove, fuel: HPXML::FuelTypeOil, eff: 0.8 }])
      _check_cooling_system(hpxml, calc_type, [{ systype: HPXML::HVACTypeCentralAirConditioner, fuel: HPXML::FuelTypeElectricity, comptype: HPXML::HVACCompressorTypeSingleStage, seer: 13, dse: _dse(calc_type) }])
      _check_heat_pump(hpxml, calc_type)
      _check_thermostat(hpxml, control_type: HPXML::HVACControlTypeManual, htg_sp: 68, clg_sp: 78)
    end
  end

  def test_wall_furnace_elec
    hpxml_name = 'base-hvac-wall-furnace-elec-only.xml'

    _eri_versions.each do |eri_version|
      hpxml_name = _change_eri_version(hpxml_name, eri_version) unless eri_version == 'latest'
      calc_types = [Constants.CalcTypeERIReferenceHome,
                    Constants.CalcTypeERIIndexAdjustmentDesign,
                    Constants.CalcTypeERIIndexAdjustmentReferenceHome]
      calc_types.each do |calc_type|
        hpxml = _test_measure(hpxml_name, calc_type)
        _check_heat_pump(hpxml, calc_type, [{ systype: HPXML::HVACTypeHeatPumpAirToAir, fuel: HPXML::FuelTypeElectricity, comptype: HPXML::HVACCompressorTypeSingleStage, hspf: 7.7, seer: 13, dse: _dse(calc_type), backup_fuel: HPXML::FuelTypeElectricity, backup_eff: 1.0, frac_load_cool: 0.0 }])
        _check_cooling_system(hpxml, calc_type, [{ systype: HPXML::HVACTypeCentralAirConditioner, fuel: HPXML::FuelTypeElectricity, comptype: HPXML::HVACCompressorTypeSingleStage, seer: 13, dse: _dse(calc_type) }])
        _check_heating_system(hpxml, calc_type)
        _check_thermostat(hpxml, control_type: HPXML::HVACControlTypeManual, htg_sp: 68, clg_sp: 78)
      end
      calc_type = Constants.CalcTypeERIRatedHome
      hpxml = _test_measure(hpxml_name, calc_type)
      _check_heating_system(hpxml, calc_type, [{ systype: HPXML::HVACTypeWallFurnace, fuel: HPXML::FuelTypeElectricity, eff: 1.0 }])
      _check_cooling_system(hpxml, calc_type, [{ systype: HPXML::HVACTypeCentralAirConditioner, fuel: HPXML::FuelTypeElectricity, comptype: HPXML::HVACCompressorTypeSingleStage, seer: 13, dse: _dse(calc_type) }])
      _check_heat_pump(hpxml, calc_type)
      _check_thermostat(hpxml, control_type: HPXML::HVACControlTypeManual, htg_sp: 68, clg_sp: 78)
    end
  end

  def test_elec_resistance
    hpxml_name = 'base-hvac-elec-resistance-only.xml'

    _eri_versions.each do |eri_version|
      hpxml_name = _change_eri_version(hpxml_name, eri_version) unless eri_version == 'latest'
      calc_types = [Constants.CalcTypeERIReferenceHome,
                    Constants.CalcTypeERIIndexAdjustmentDesign,
                    Constants.CalcTypeERIIndexAdjustmentReferenceHome]
      calc_types.each do |calc_type|
        hpxml = _test_measure(hpxml_name, calc_type)
        _check_heat_pump(hpxml, calc_type, [{ systype: HPXML::HVACTypeHeatPumpAirToAir, fuel: HPXML::FuelTypeElectricity, comptype: HPXML::HVACCompressorTypeSingleStage, hspf: 7.7, seer: 13, dse: _dse(calc_type), backup_fuel: HPXML::FuelTypeElectricity, backup_eff: 1.0, frac_load_cool: 0.0 }])
        _check_cooling_system(hpxml, calc_type, [{ systype: HPXML::HVACTypeCentralAirConditioner, fuel: HPXML::FuelTypeElectricity, comptype: HPXML::HVACCompressorTypeSingleStage, seer: 13, dse: _dse(calc_type) }])
        _check_heating_system(hpxml, calc_type)
        _check_thermostat(hpxml, control_type: HPXML::HVACControlTypeManual, htg_sp: 68, clg_sp: 78)
      end
      calc_type = Constants.CalcTypeERIRatedHome
      hpxml = _test_measure(hpxml_name, calc_type)
      _check_heating_system(hpxml, calc_type, [{ systype: HPXML::HVACTypeElectricResistance, fuel: HPXML::FuelTypeElectricity, eff: 1.0 }])
      _check_cooling_system(hpxml, calc_type, [{ systype: HPXML::HVACTypeCentralAirConditioner, fuel: HPXML::FuelTypeElectricity, comptype: HPXML::HVACCompressorTypeSingleStage, seer: 13, dse: _dse(calc_type) }])
      _check_heat_pump(hpxml, calc_type)
      _check_thermostat(hpxml, control_type: HPXML::HVACControlTypeManual, htg_sp: 68, clg_sp: 78)
    end
  end

  def test_air_source_heat_pump
    hpxml_names = ['base-hvac-air-to-air-heat-pump-1-speed.xml',
                   'base-hvac-install-qual-all-air-to-air-heat-pump-1-speed.xml']

    hpxml_names.each do |hpxml_name|
      _eri_versions.each do |eri_version|
        hpxml_name = _change_eri_version(hpxml_name, eri_version) unless eri_version == 'latest'
        calc_types = [Constants.CalcTypeERIReferenceHome,
                      Constants.CalcTypeERIIndexAdjustmentDesign,
                      Constants.CalcTypeERIIndexAdjustmentReferenceHome]
        calc_types.each do |calc_type|
          hpxml = _test_measure(hpxml_name, calc_type)
          _check_heat_pump(hpxml, calc_type, [{ systype: HPXML::HVACTypeHeatPumpAirToAir, fuel: HPXML::FuelTypeElectricity, comptype: HPXML::HVACCompressorTypeSingleStage, hspf: 7.7, seer: 13, dse: _dse(calc_type), backup_fuel: HPXML::FuelTypeElectricity, backup_eff: 1.0, frac_load_cool: 0.0 }])
          _check_cooling_system(hpxml, calc_type, [{ systype: HPXML::HVACTypeCentralAirConditioner, fuel: HPXML::FuelTypeElectricity, comptype: HPXML::HVACCompressorTypeSingleStage, seer: 13, dse: _dse(calc_type), shr: 0.73 }])
          _check_heating_system(hpxml, calc_type)
          _check_thermostat(hpxml, control_type: HPXML::HVACControlTypeManual, htg_sp: 68, clg_sp: 78)
        end
        calc_type = Constants.CalcTypeERIRatedHome
        hpxml = _test_measure(hpxml_name, calc_type)
        if hpxml_name.include?('install-qual') && eri_version == 'latest'
          hvac_install_qual_values = { fan_watts_per_cfm: 0.365, airflow_defect_ratio: -0.25, charge_defect_ratio: -0.25 }
        else
          hvac_install_qual_values = {}
        end
        _check_heat_pump(hpxml, calc_type, [{ systype: HPXML::HVACTypeHeatPumpAirToAir, fuel: HPXML::FuelTypeElectricity, comptype: HPXML::HVACCompressorTypeSingleStage, hspf: 7.7, seer: 13, shr: 0.73, backup_fuel: HPXML::FuelTypeElectricity, backup_eff: 1.0, **hvac_install_qual_values }])
        _check_cooling_system(hpxml, calc_type)
        _check_heating_system(hpxml, calc_type)
        _check_thermostat(hpxml, control_type: HPXML::HVACControlTypeManual, htg_sp: 68, clg_sp: 78)
      end
    end
  end

  def test_mini_split_heat_pump_ducted
    hpxml_names = ['base-hvac-mini-split-heat-pump-ducted.xml',
                   'base-hvac-install-qual-all-mini-split-heat-pump-ducted.xml']

    hpxml_names.each do |hpxml_name|
      _eri_versions.each do |eri_version|
        hpxml_name = _change_eri_version(hpxml_name, eri_version) unless eri_version == 'latest'
        calc_types = [Constants.CalcTypeERIReferenceHome,
                      Constants.CalcTypeERIIndexAdjustmentDesign,
                      Constants.CalcTypeERIIndexAdjustmentReferenceHome]
        calc_types.each do |calc_type|
          hpxml = _test_measure(hpxml_name, calc_type)
          _check_heat_pump(hpxml, calc_type, [{ systype: HPXML::HVACTypeHeatPumpAirToAir, fuel: HPXML::FuelTypeElectricity, comptype: HPXML::HVACCompressorTypeSingleStage, hspf: 7.7, seer: 13, dse: _dse(calc_type), backup_fuel: HPXML::FuelTypeElectricity, backup_eff: 1.0, frac_load_cool: 0.0 }])
          _check_cooling_system(hpxml, calc_type, [{ systype: HPXML::HVACTypeCentralAirConditioner, fuel: HPXML::FuelTypeElectricity, comptype: HPXML::HVACCompressorTypeSingleStage, seer: 13, dse: _dse(calc_type), shr: 0.73 }])
          _check_heating_system(hpxml, calc_type)
          _check_thermostat(hpxml, control_type: HPXML::HVACControlTypeManual, htg_sp: 68, clg_sp: 78)
        end
        calc_type = Constants.CalcTypeERIRatedHome
        if hpxml_name.include?('install-qual') && eri_version == 'latest'
          hvac_install_qual_values = { fan_watts_per_cfm: 0.365, airflow_defect_ratio: -0.25, charge_defect_ratio: -0.25 }
        else
          hvac_install_qual_values = {}
        end
        hpxml = _test_measure(hpxml_name, calc_type)
        _check_heat_pump(hpxml, calc_type, [{ systype: HPXML::HVACTypeHeatPumpMiniSplit, fuel: HPXML::FuelTypeElectricity, hspf: 10, seer: 19, shr: 0.73, backup_fuel: HPXML::FuelTypeElectricity, backup_eff: 1.0, **hvac_install_qual_values }])
        _check_cooling_system(hpxml, calc_type)
        _check_heating_system(hpxml, calc_type)
        _check_thermostat(hpxml, control_type: HPXML::HVACControlTypeManual, htg_sp: 68, clg_sp: 78)
      end
    end
  end

  def test_mini_split_heat_pump_ductless
    hpxml_name = 'base-hvac-mini-split-heat-pump-ductless.xml'

    _eri_versions.each do |eri_version|
      hpxml_name = _change_eri_version(hpxml_name, eri_version) unless eri_version == 'latest'
      calc_types = [Constants.CalcTypeERIReferenceHome,
                    Constants.CalcTypeERIIndexAdjustmentDesign,
                    Constants.CalcTypeERIIndexAdjustmentReferenceHome]
      calc_types.each do |calc_type|
        hpxml = _test_measure(hpxml_name, calc_type)
        _check_heat_pump(hpxml, calc_type, [{ systype: HPXML::HVACTypeHeatPumpAirToAir, fuel: HPXML::FuelTypeElectricity, comptype: HPXML::HVACCompressorTypeSingleStage, hspf: 7.7, seer: 13, dse: _dse(calc_type), backup_fuel: HPXML::FuelTypeElectricity, backup_eff: 1.0, frac_load_cool: 0.0 }])
        _check_cooling_system(hpxml, calc_type, [{ systype: HPXML::HVACTypeCentralAirConditioner, fuel: HPXML::FuelTypeElectricity, comptype: HPXML::HVACCompressorTypeSingleStage, seer: 13, dse: _dse(calc_type), shr: 0.73 }])
        _check_heating_system(hpxml, calc_type)
        _check_thermostat(hpxml, control_type: HPXML::HVACControlTypeManual, htg_sp: 68, clg_sp: 78)
      end
      calc_type = Constants.CalcTypeERIRatedHome
      hpxml = _test_measure(hpxml_name, calc_type)
      _check_heat_pump(hpxml, calc_type, [{ systype: HPXML::HVACTypeHeatPumpMiniSplit, fuel: HPXML::FuelTypeElectricity, hspf: 10, seer: 19, shr: 0.73 }])
      _check_cooling_system(hpxml, calc_type)
      _check_heating_system(hpxml, calc_type)
      _check_thermostat(hpxml, control_type: HPXML::HVACControlTypeManual, htg_sp: 68, clg_sp: 78)
    end
  end

  def test_ground_to_air_heat_pump
    hpxml_names = ['base-hvac-ground-to-air-heat-pump.xml',
                   'base-hvac-install-qual-all-ground-to-air-heat-pump.xml']

    hpxml_names.each do |hpxml_name|
      _eri_versions.each do |eri_version|
        hpxml_name = _change_eri_version(hpxml_name, eri_version) unless eri_version == 'latest'
        calc_types = [Constants.CalcTypeERIReferenceHome,
                      Constants.CalcTypeERIIndexAdjustmentDesign,
                      Constants.CalcTypeERIIndexAdjustmentReferenceHome]
        calc_types.each do |calc_type|
          hpxml = _test_measure(hpxml_name, calc_type)
          _check_heat_pump(hpxml, calc_type, [{ systype: HPXML::HVACTypeHeatPumpAirToAir, fuel: HPXML::FuelTypeElectricity, comptype: HPXML::HVACCompressorTypeSingleStage, hspf: 7.7, seer: 13, dse: _dse(calc_type), backup_fuel: HPXML::FuelTypeElectricity, backup_eff: 1.0, frac_load_cool: 0.0 }])
          _check_cooling_system(hpxml, calc_type, [{ systype: HPXML::HVACTypeCentralAirConditioner, fuel: HPXML::FuelTypeElectricity, comptype: HPXML::HVACCompressorTypeSingleStage, seer: 13, dse: _dse(calc_type), shr: 0.73 }])
          _check_heating_system(hpxml, calc_type)
          _check_thermostat(hpxml, control_type: HPXML::HVACControlTypeManual, htg_sp: 68, clg_sp: 78)
        end
        calc_type = Constants.CalcTypeERIRatedHome
        if hpxml_name.include?('install-qual') && eri_version == 'latest'
          hvac_install_qual_values = { fan_watts_per_cfm: 0.365, airflow_defect_ratio: -0.25 }
        else
          hvac_install_qual_values = {}
        end
        hpxml = _test_measure(hpxml_name, calc_type)
        _check_heat_pump(hpxml, calc_type, [{ systype: HPXML::HVACTypeHeatPumpGroundToAir, fuel: HPXML::FuelTypeElectricity, eer: 16.6, cop: 3.6, shr: 0.73, backup_fuel: HPXML::FuelTypeElectricity, backup_eff: 1.0, pump_w_per_ton: 30, **hvac_install_qual_values }])
        _check_cooling_system(hpxml, calc_type)
        _check_heating_system(hpxml, calc_type)
        _check_thermostat(hpxml, control_type: HPXML::HVACControlTypeManual, htg_sp: 68, clg_sp: 78)
      end
    end
  end

  def test_dual_fuel_heat_pump_gas
    hpxml_name = 'base-hvac-dual-fuel-air-to-air-heat-pump-1-speed.xml'

    _eri_versions.each do |eri_version|
      hpxml_name = _change_eri_version(hpxml_name, eri_version) unless eri_version == 'latest'
      calc_types = [Constants.CalcTypeERIReferenceHome,
                    Constants.CalcTypeERIIndexAdjustmentDesign,
                    Constants.CalcTypeERIIndexAdjustmentReferenceHome]
      calc_types.each do |calc_type|
        hpxml = _test_measure(hpxml_name, calc_type)
        _check_heat_pump(hpxml, calc_type, [{ systype: HPXML::HVACTypeHeatPumpAirToAir, fuel: HPXML::FuelTypeElectricity, comptype: HPXML::HVACCompressorTypeSingleStage, hspf: 7.7, seer: 13, dse: _dse(calc_type), backup_fuel: HPXML::FuelTypeNaturalGas, backup_eff: 0.78, backup_temp: 25.0, frac_load_cool: 0.0 }])
        _check_cooling_system(hpxml, calc_type, [{ systype: HPXML::HVACTypeCentralAirConditioner, fuel: HPXML::FuelTypeElectricity, comptype: HPXML::HVACCompressorTypeSingleStage, seer: 13, dse: _dse(calc_type), shr: 0.73 }])
        _check_heating_system(hpxml, calc_type)
        _check_thermostat(hpxml, control_type: HPXML::HVACControlTypeManual, htg_sp: 68, clg_sp: 78)
      end
      calc_type = Constants.CalcTypeERIRatedHome
      hpxml = _test_measure(hpxml_name, calc_type)
      _check_heat_pump(hpxml, calc_type, [{ systype: HPXML::HVACTypeHeatPumpAirToAir, fuel: HPXML::FuelTypeElectricity, comptype: HPXML::HVACCompressorTypeSingleStage, hspf: 7.7, seer: 13, shr: 0.73, backup_fuel: HPXML::FuelTypeNaturalGas, backup_eff: 0.95, backup_temp: 25.0 }])
      _check_cooling_system(hpxml, calc_type)
      _check_heating_system(hpxml, calc_type)
      _check_thermostat(hpxml, control_type: HPXML::HVACControlTypeManual, htg_sp: 68, clg_sp: 78)
    end
  end

  def test_dual_fuel_heat_pump_electric
    hpxml_name = 'base-hvac-dual-fuel-air-to-air-heat-pump-1-speed-electric.xml'

    _eri_versions.each do |eri_version|
      hpxml_name = _change_eri_version(hpxml_name, eri_version) unless eri_version == 'latest'
      calc_types = [Constants.CalcTypeERIReferenceHome,
                    Constants.CalcTypeERIIndexAdjustmentDesign]
      calc_types.each do |calc_type|
        hpxml = _test_measure(hpxml_name, calc_type)
        _check_heat_pump(hpxml, calc_type, [{ systype: HPXML::HVACTypeHeatPumpAirToAir, fuel: HPXML::FuelTypeElectricity, comptype: HPXML::HVACCompressorTypeSingleStage, hspf: 7.7, seer: 13, dse: _dse(calc_type), frac_load_cool: 0.0 }])
        _check_cooling_system(hpxml, calc_type, [{ systype: HPXML::HVACTypeCentralAirConditioner, fuel: HPXML::FuelTypeElectricity, comptype: HPXML::HVACCompressorTypeSingleStage, seer: 13, dse: _dse(calc_type), shr: 0.73 }])
        _check_heating_system(hpxml, calc_type)
        _check_thermostat(hpxml, control_type: HPXML::HVACControlTypeManual, htg_sp: 68, clg_sp: 78)
      end
      calc_type = Constants.CalcTypeERIIndexAdjustmentReferenceHome
      hpxml = _test_measure(hpxml_name, calc_type)
      _check_heat_pump(hpxml, calc_type, [{ systype: HPXML::HVACTypeHeatPumpAirToAir, fuel: HPXML::FuelTypeElectricity, comptype: HPXML::HVACCompressorTypeSingleStage, hspf: 7.7, seer: 13, dse: _dse(calc_type), backup_fuel: HPXML::FuelTypeElectricity, backup_eff: 1.0, frac_load_cool: 0.0 }])
      _check_cooling_system(hpxml, calc_type, [{ systype: HPXML::HVACTypeCentralAirConditioner, fuel: HPXML::FuelTypeElectricity, comptype: HPXML::HVACCompressorTypeSingleStage, seer: 13, dse: _dse(calc_type), shr: 0.73 }])
      _check_heating_system(hpxml, calc_type)
      _check_thermostat(hpxml, control_type: HPXML::HVACControlTypeManual, htg_sp: 68, clg_sp: 78)
      calc_type = Constants.CalcTypeERIRatedHome
      hpxml = _test_measure(hpxml_name, calc_type)
      _check_heat_pump(hpxml, calc_type, [{ systype: HPXML::HVACTypeHeatPumpAirToAir, fuel: HPXML::FuelTypeElectricity, comptype: HPXML::HVACCompressorTypeSingleStage, hspf: 7.7, seer: 13, shr: 0.73, backup_fuel: HPXML::FuelTypeElectricity, backup_eff: 1.0, backup_temp: 25.0 }])
      _check_cooling_system(hpxml, calc_type)
      _check_heating_system(hpxml, calc_type)
      _check_thermostat(hpxml, control_type: HPXML::HVACControlTypeManual, htg_sp: 68, clg_sp: 78)
    end
  end

  def test_central_air_conditioner
    hpxml_name = 'base-hvac-central-ac-only-1-speed.xml'

    _eri_versions.each do |eri_version|
      hpxml_name = _change_eri_version(hpxml_name, eri_version) unless eri_version == 'latest'
      calc_types = [Constants.CalcTypeERIReferenceHome,
                    Constants.CalcTypeERIIndexAdjustmentDesign,
                    Constants.CalcTypeERIIndexAdjustmentReferenceHome]
      calc_types.each do |calc_type|
        hpxml = _test_measure(hpxml_name, calc_type)
        _check_cooling_system(hpxml, calc_type, [{ systype: HPXML::HVACTypeCentralAirConditioner, fuel: HPXML::FuelTypeElectricity, comptype: HPXML::HVACCompressorTypeSingleStage, seer: 13, dse: _dse(calc_type), shr: 0.73 }])
        _check_heating_system(hpxml, calc_type, [{ systype: HPXML::HVACTypeFurnace, fuel: HPXML::FuelTypeNaturalGas, eff: 0.78, dse: _dse(calc_type) }])
        _check_heat_pump(hpxml, calc_type)
        _check_thermostat(hpxml, control_type: HPXML::HVACControlTypeManual, htg_sp: 68, clg_sp: 78)
      end
      calc_type = Constants.CalcTypeERIRatedHome
      hpxml = _test_measure(hpxml_name, calc_type)
      _check_cooling_system(hpxml, calc_type, [{ systype: HPXML::HVACTypeCentralAirConditioner, fuel: HPXML::FuelTypeElectricity, comptype: HPXML::HVACCompressorTypeSingleStage, seer: 13, shr: 0.73 }])
      _check_heating_system(hpxml, calc_type, [{ systype: HPXML::HVACTypeFurnace, fuel: HPXML::FuelTypeNaturalGas, eff: 0.78, dse: _dse(calc_type) }])
      _check_heat_pump(hpxml, calc_type)
      _check_thermostat(hpxml, control_type: HPXML::HVACControlTypeManual, htg_sp: 68, clg_sp: 78)
    end
  end

  def test_room_air_conditioner
    hpxml_name = 'base-hvac-room-ac-only.xml'

    _eri_versions.each do |eri_version|
      hpxml_name = _change_eri_version(hpxml_name, eri_version) unless eri_version == 'latest'
      calc_types = [Constants.CalcTypeERIReferenceHome,
                    Constants.CalcTypeERIIndexAdjustmentDesign,
                    Constants.CalcTypeERIIndexAdjustmentReferenceHome]
      calc_types.each do |calc_type|
        hpxml = _test_measure(hpxml_name, calc_type)
        _check_cooling_system(hpxml, calc_type, [{ systype: HPXML::HVACTypeCentralAirConditioner, fuel: HPXML::FuelTypeElectricity, comptype: HPXML::HVACCompressorTypeSingleStage, seer: 13, dse: _dse(calc_type), shr: 0.65 }])
        _check_heating_system(hpxml, calc_type, [{ systype: HPXML::HVACTypeFurnace, fuel: HPXML::FuelTypeNaturalGas, eff: 0.78, dse: _dse(calc_type) }])
        _check_heat_pump(hpxml, calc_type)
        _check_thermostat(hpxml, control_type: HPXML::HVACControlTypeManual, htg_sp: 68, clg_sp: 78)
      end
      calc_type = Constants.CalcTypeERIRatedHome
      hpxml = _test_measure(hpxml_name, calc_type)
      _check_cooling_system(hpxml, calc_type, [{ systype: HPXML::HVACTypeRoomAirConditioner, fuel: HPXML::FuelTypeElectricity, eer: 8.5, shr: 0.65 }])
      _check_heating_system(hpxml, calc_type, [{ systype: HPXML::HVACTypeFurnace, fuel: HPXML::FuelTypeNaturalGas, eff: 0.78, dse: _dse(calc_type) }])
      _check_heat_pump(hpxml, calc_type)
      _check_thermostat(hpxml, control_type: HPXML::HVACControlTypeManual, htg_sp: 68, clg_sp: 78)
    end
  end

  def test_evaporative_cooler
    hpxml_name = 'base-hvac-evap-cooler-only.xml'

    _eri_versions.each do |eri_version|
      hpxml_name = _change_eri_version(hpxml_name, eri_version) unless eri_version == 'latest'
      calc_types = [Constants.CalcTypeERIReferenceHome,
                    Constants.CalcTypeERIIndexAdjustmentDesign,
                    Constants.CalcTypeERIIndexAdjustmentReferenceHome]
      calc_types.each do |calc_type|
        hpxml = _test_measure(hpxml_name, calc_type)
        _check_cooling_system(hpxml, calc_type, [{ systype: HPXML::HVACTypeCentralAirConditioner, fuel: HPXML::FuelTypeElectricity, comptype: HPXML::HVACCompressorTypeSingleStage, seer: 13, dse: _dse(calc_type) }])
        _check_heating_system(hpxml, calc_type, [{ systype: HPXML::HVACTypeFurnace, fuel: HPXML::FuelTypeNaturalGas, eff: 0.78, dse: _dse(calc_type) }])
        _check_heat_pump(hpxml, calc_type)
        _check_thermostat(hpxml, control_type: HPXML::HVACControlTypeManual, htg_sp: 68, clg_sp: 78)
      end
      calc_type = Constants.CalcTypeERIRatedHome
      hpxml = _test_measure(hpxml_name, calc_type)
      _check_cooling_system(hpxml, calc_type, [{ systype: HPXML::HVACTypeEvaporativeCooler, fuel: HPXML::FuelTypeElectricity }])
      _check_heating_system(hpxml, calc_type, [{ systype: HPXML::HVACTypeFurnace, fuel: HPXML::FuelTypeNaturalGas, eff: 0.78, dse: _dse(calc_type) }])
      _check_heat_pump(hpxml, calc_type)
      _check_thermostat(hpxml, control_type: HPXML::HVACControlTypeManual, htg_sp: 68, clg_sp: 78)
    end
  end

  def test_furnace_gas_and_central_air_conditioner
    hpxml_names = ['base.xml',
                   'base-hvac-install-qual-all-furnace-gas-central-ac-1-speed.xml']

    hpxml_names.each do |hpxml_name|
      _eri_versions.each do |eri_version|
        hpxml_name = _change_eri_version(hpxml_name, eri_version) unless eri_version == 'latest'
        calc_types = [Constants.CalcTypeERIReferenceHome,
                      Constants.CalcTypeERIIndexAdjustmentDesign,
                      Constants.CalcTypeERIIndexAdjustmentReferenceHome]
        calc_types.each do |calc_type|
          hpxml = _test_measure(hpxml_name, calc_type)
          _check_cooling_system(hpxml, calc_type, [{ systype: HPXML::HVACTypeCentralAirConditioner, fuel: HPXML::FuelTypeElectricity, comptype: HPXML::HVACCompressorTypeSingleStage, seer: 13, dse: _dse(calc_type), shr: 0.73 }])
          _check_heating_system(hpxml, calc_type, [{ systype: HPXML::HVACTypeFurnace, fuel: HPXML::FuelTypeNaturalGas, eff: 0.78, dse: _dse(calc_type) }])
          _check_heat_pump(hpxml, calc_type)
          _check_thermostat(hpxml, control_type: HPXML::HVACControlTypeManual, htg_sp: 68, clg_sp: 78)
        end
        calc_type = Constants.CalcTypeERIRatedHome
        if hpxml_name.include?('install-qual') && eri_version == 'latest'
          heat_install_qual_values = { fan_watts_per_cfm: 0.365, airflow_defect_ratio: -0.25 }
          cool_install_qual_values = { fan_watts_per_cfm: 0.365, airflow_defect_ratio: -0.25, charge_defect_ratio: -0.25 }
        else
          heat_install_qual_values = {}
          cool_install_qual_values = {}
        end
        hpxml = _test_measure(hpxml_name, calc_type)
        _check_cooling_system(hpxml, calc_type, [{ systype: HPXML::HVACTypeCentralAirConditioner, fuel: HPXML::FuelTypeElectricity, comptype: HPXML::HVACCompressorTypeSingleStage, seer: 13, shr: 0.73, **cool_install_qual_values }])
        _check_heating_system(hpxml, calc_type, [{ systype: HPXML::HVACTypeFurnace, fuel: HPXML::FuelTypeNaturalGas, eff: 0.92, **heat_install_qual_values }])
        _check_heat_pump(hpxml, calc_type)
        _check_thermostat(hpxml, control_type: HPXML::HVACControlTypeManual, htg_sp: 68, clg_sp: 78)
      end
    end
  end

  def test_furnace_gas_room_air_conditioner
    hpxml_name = 'base-hvac-furnace-gas-room-ac.xml'

    _eri_versions.each do |eri_version|
      hpxml_name = _change_eri_version(hpxml_name, eri_version) unless eri_version == 'latest'
      calc_types = [Constants.CalcTypeERIReferenceHome,
                    Constants.CalcTypeERIIndexAdjustmentDesign,
                    Constants.CalcTypeERIIndexAdjustmentReferenceHome]
      calc_types.each do |calc_type|
        hpxml = _test_measure(hpxml_name, calc_type)
        _check_cooling_system(hpxml, calc_type, [{ systype: HPXML::HVACTypeCentralAirConditioner, fuel: HPXML::FuelTypeElectricity, comptype: HPXML::HVACCompressorTypeSingleStage, seer: 13, dse: _dse(calc_type), shr: 0.65 }])
        _check_heating_system(hpxml, calc_type, [{ systype: HPXML::HVACTypeFurnace, fuel: HPXML::FuelTypeNaturalGas, eff: 0.78, dse: _dse(calc_type) }])
        _check_heat_pump(hpxml, calc_type)
        _check_thermostat(hpxml, control_type: HPXML::HVACControlTypeManual, htg_sp: 68, clg_sp: 78)
      end
      calc_type = Constants.CalcTypeERIRatedHome
      hpxml = _test_measure(hpxml_name, calc_type)
      _check_cooling_system(hpxml, calc_type, [{ systype: HPXML::HVACTypeRoomAirConditioner, fuel: HPXML::FuelTypeElectricity, eer: 8.5, shr: 0.65 }])
      _check_heating_system(hpxml, calc_type, [{ systype: HPXML::HVACTypeFurnace, fuel: HPXML::FuelTypeNaturalGas, eff: 0.92 }])
      _check_heat_pump(hpxml, calc_type)
      _check_thermostat(hpxml, control_type: HPXML::HVACControlTypeManual, htg_sp: 68, clg_sp: 78)
    end
  end

  def test_multiple_hvac
    hpxml_name = 'base-hvac-multiple.xml'

    _eri_versions.each do |eri_version|
      hpxml_name = _change_eri_version(hpxml_name, eri_version) unless eri_version == 'latest'
      calc_types = [Constants.CalcTypeERIReferenceHome,
                    Constants.CalcTypeERIIndexAdjustmentDesign,
                    Constants.CalcTypeERIIndexAdjustmentReferenceHome]
      calc_types.each do |calc_type|
        hpxml = _test_measure(hpxml_name, calc_type)
        _check_cooling_system(hpxml, calc_type, [{ systype: HPXML::HVACTypeCentralAirConditioner, fuel: HPXML::FuelTypeElectricity, comptype: HPXML::HVACCompressorTypeSingleStage, seer: 13, frac_load: 0.2, dse: _dse(calc_type), shr: 0.73 },
                                                 { systype: HPXML::HVACTypeCentralAirConditioner, fuel: HPXML::FuelTypeElectricity, comptype: HPXML::HVACCompressorTypeSingleStage, seer: 13, frac_load: 0.2, dse: _dse(calc_type), shr: 0.65 },
                                                 { systype: HPXML::HVACTypeCentralAirConditioner, fuel: HPXML::FuelTypeElectricity, comptype: HPXML::HVACCompressorTypeSingleStage, seer: 13, frac_load: 0.2, dse: _dse(calc_type), shr: 0.73 },
                                                 { systype: HPXML::HVACTypeCentralAirConditioner, fuel: HPXML::FuelTypeElectricity, comptype: HPXML::HVACCompressorTypeSingleStage, seer: 13, frac_load: 0.2, dse: _dse(calc_type), shr: 0.73 },
                                                 { systype: HPXML::HVACTypeCentralAirConditioner, fuel: HPXML::FuelTypeElectricity, comptype: HPXML::HVACCompressorTypeSingleStage, seer: 13, frac_load: 0.2, dse: _dse(calc_type), shr: 0.73 }])
        _check_heating_system(hpxml, calc_type, [{ systype: HPXML::HVACTypeFurnace, fuel: HPXML::FuelTypeNaturalGas, eff: 0.78, frac_load: 0.1, dse: _dse(calc_type) },
                                                 { systype: HPXML::HVACTypeBoiler, fuel: HPXML::FuelTypeNaturalGas, eff: 0.8, frac_load: 0.1, dse: _dse(calc_type), eae: 170 },
                                                 { systype: HPXML::HVACTypeFurnace, fuel: HPXML::FuelTypeNaturalGas, eff: 0.78, frac_load: 0.1, dse: _dse(calc_type) },
                                                 { systype: HPXML::HVACTypeFurnace, fuel: HPXML::FuelTypeNaturalGas, eff: 0.78, frac_load: 0.1, dse: _dse(calc_type) }])
        _check_heat_pump(hpxml, calc_type, [{ systype: HPXML::HVACTypeHeatPumpAirToAir, fuel: HPXML::FuelTypeElectricity, comptype: HPXML::HVACCompressorTypeSingleStage, hspf: 7.7, seer: 13, frac_load_heat: 0.1, frac_load_cool: 0.0, dse: _dse(calc_type), backup_fuel: HPXML::FuelTypeElectricity, backup_eff: 1.0 },
                                            { systype: HPXML::HVACTypeHeatPumpAirToAir, fuel: HPXML::FuelTypeElectricity, comptype: HPXML::HVACCompressorTypeSingleStage, hspf: 7.7, seer: 13, frac_load_heat: 0.1, frac_load_cool: 0.0, dse: _dse(calc_type), backup_fuel: HPXML::FuelTypeElectricity, backup_eff: 1.0 },
                                            { systype: HPXML::HVACTypeHeatPumpAirToAir, fuel: HPXML::FuelTypeElectricity, comptype: HPXML::HVACCompressorTypeSingleStage, hspf: 7.7, seer: 13, frac_load_heat: 0.1, frac_load_cool: 0.0, dse: _dse(calc_type), backup_fuel: HPXML::FuelTypeElectricity, backup_eff: 1.0 },
                                            { systype: HPXML::HVACTypeHeatPumpAirToAir, fuel: HPXML::FuelTypeElectricity, comptype: HPXML::HVACCompressorTypeSingleStage, hspf: 7.7, seer: 13, frac_load_heat: 0.1, frac_load_cool: 0.0, dse: _dse(calc_type), backup_fuel: HPXML::FuelTypeElectricity, backup_eff: 1.0 },
                                            { systype: HPXML::HVACTypeHeatPumpAirToAir, fuel: HPXML::FuelTypeElectricity, comptype: HPXML::HVACCompressorTypeSingleStage, hspf: 7.7, seer: 13, frac_load_heat: 0.1, frac_load_cool: 0.0, dse: _dse(calc_type), backup_fuel: HPXML::FuelTypeElectricity, backup_eff: 1.0 },
                                            { systype: HPXML::HVACTypeHeatPumpAirToAir, fuel: HPXML::FuelTypeElectricity, comptype: HPXML::HVACCompressorTypeSingleStage, hspf: 7.7, seer: 13, frac_load_heat: 0.1, frac_load_cool: 0.0, dse: _dse(calc_type), backup_fuel: HPXML::FuelTypeElectricity, backup_eff: 1.0 }])
        _check_thermostat(hpxml, control_type: HPXML::HVACControlTypeManual, htg_sp: 68, clg_sp: 78)
      end
      calc_type = Constants.CalcTypeERIRatedHome
      hpxml = _test_measure(hpxml_name, calc_type)
      _check_cooling_system(hpxml, calc_type, [{ systype: HPXML::HVACTypeCentralAirConditioner, fuel: HPXML::FuelTypeElectricity, comptype: HPXML::HVACCompressorTypeSingleStage, seer: 13, frac_load: 0.2, shr: 0.73 },
                                               { systype: HPXML::HVACTypeRoomAirConditioner, fuel: HPXML::FuelTypeElectricity, eer: 8.5, frac_load: 0.2, shr: 0.65 }])
      _check_heating_system(hpxml, calc_type, [{ systype: HPXML::HVACTypeFurnace, fuel: HPXML::FuelTypeElectricity, eff: 1.0, frac_load: 0.1 },
                                               { systype: HPXML::HVACTypeFurnace, fuel: HPXML::FuelTypeNaturalGas, eff: 0.92, frac_load: 0.1 },
                                               { systype: HPXML::HVACTypeBoiler, fuel: HPXML::FuelTypeElectricity, eff: 1.0, frac_load: 0.1, eae: 170 },
                                               { systype: HPXML::HVACTypeBoiler, fuel: HPXML::FuelTypeNaturalGas, eff: 0.92, frac_load: 0.1, eae: 200 },
                                               { systype: HPXML::HVACTypeElectricResistance, fuel: HPXML::FuelTypeElectricity, eff: 1.0, frac_load: 0.1 },
                                               { systype: HPXML::HVACTypeStove, fuel: HPXML::FuelTypeOil, eff: 0.8, frac_load: 0.1 },
                                               { systype: HPXML::HVACTypeWallFurnace, fuel: HPXML::FuelTypePropane, eff: 0.8, frac_load: 0.1 }])
      _check_heat_pump(hpxml, calc_type, [{ systype: HPXML::HVACTypeHeatPumpAirToAir, fuel: HPXML::FuelTypeElectricity, comptype: HPXML::HVACCompressorTypeSingleStage, hspf: 7.7, seer: 13, frac_load_heat: 0.1, frac_load_cool: 0.2, shr: 0.73, backup_fuel: HPXML::FuelTypeElectricity, backup_eff: 1.0 },
                                          { systype: HPXML::HVACTypeHeatPumpGroundToAir, fuel: HPXML::FuelTypeElectricity, eer: 16.6, cop: 3.6, frac_load_heat: 0.1, frac_load_cool: 0.2, shr: 0.73, backup_fuel: HPXML::FuelTypeElectricity, backup_eff: 1.0, pump_w_per_ton: 30 },
                                          { systype: HPXML::HVACTypeHeatPumpMiniSplit, fuel: HPXML::FuelTypeElectricity, hspf: 10, seer: 19, frac_load_heat: 0.1, frac_load_cool: 0.2, shr: 0.73, backup_fuel: HPXML::FuelTypeElectricity, backup_eff: 1.0 }])
      _check_thermostat(hpxml, control_type: HPXML::HVACControlTypeManual, htg_sp: 68, clg_sp: 78)
    end
  end

  def test_partial_hvac
    # Create derivative file for testing
    hpxml_name = 'base.xml'
    hpxml = HPXML.new(hpxml_path: File.join(@root_path, 'workflow', 'sample_files', hpxml_name))
    hpxml.heating_systems[0].fraction_heat_load_served = 0.2
    hpxml.cooling_systems[0].fraction_cool_load_served = 0.3
    hpxml_name = File.basename(@tmp_hpxml_path)
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)

    _eri_versions.each do |eri_version|
      hpxml_name = _change_eri_version(hpxml_name, eri_version) unless eri_version == 'latest'
      calc_types = [Constants.CalcTypeERIReferenceHome,
                    Constants.CalcTypeERIIndexAdjustmentDesign,
                    Constants.CalcTypeERIIndexAdjustmentReferenceHome]
      calc_types.each do |calc_type|
        hpxml = _test_measure(hpxml_name, calc_type)
        _check_cooling_system(hpxml, calc_type, [{ systype: HPXML::HVACTypeCentralAirConditioner, fuel: HPXML::FuelTypeElectricity, comptype: HPXML::HVACCompressorTypeSingleStage, seer: 13, frac_load: 0.3, dse: _dse(calc_type), shr: 0.73 },
                                                 { systype: HPXML::HVACTypeCentralAirConditioner, fuel: HPXML::FuelTypeElectricity, comptype: HPXML::HVACCompressorTypeSingleStage, seer: 13, frac_load: 0.7, dse: _dse(calc_type) }])
        _check_heating_system(hpxml, calc_type, [{ systype: HPXML::HVACTypeFurnace, fuel: HPXML::FuelTypeNaturalGas, eff: 0.78, frac_load: 0.2, dse: _dse(calc_type) },
                                                 { systype: HPXML::HVACTypeFurnace, fuel: HPXML::FuelTypeNaturalGas, eff: 0.78, frac_load: 0.8, dse: _dse(calc_type) }])
        _check_heat_pump(hpxml, calc_type)
        _check_thermostat(hpxml, control_type: HPXML::HVACControlTypeManual, htg_sp: 68, clg_sp: 78)
      end
      calc_type = Constants.CalcTypeERIRatedHome
      hpxml = _test_measure(hpxml_name, calc_type)
      _check_cooling_system(hpxml, calc_type, [{ systype: HPXML::HVACTypeCentralAirConditioner, fuel: HPXML::FuelTypeElectricity, comptype: HPXML::HVACCompressorTypeSingleStage, seer: 13, frac_load: 0.3, shr: 0.73 },
                                               { systype: HPXML::HVACTypeCentralAirConditioner, fuel: HPXML::FuelTypeElectricity, comptype: HPXML::HVACCompressorTypeSingleStage, seer: 13, frac_load: 0.7, dse: _dse(calc_type) }])
      _check_heating_system(hpxml, calc_type, [{ systype: HPXML::HVACTypeFurnace, fuel: HPXML::FuelTypeNaturalGas, eff: 0.92, frac_load: 0.2 },
                                               { systype: HPXML::HVACTypeFurnace, fuel: HPXML::FuelTypeNaturalGas, eff: 0.78, frac_load: 0.8, dse: _dse(calc_type) }])
      _check_heat_pump(hpxml, calc_type)
      _check_thermostat(hpxml, control_type: HPXML::HVACControlTypeManual, htg_sp: 68, clg_sp: 78)
    end
  end

  def test_shared_boiler_baseboard
    hpxml_name = 'base-hvac-shared-boiler-only-baseboard.xml'

    _eri_versions.each do |eri_version|
      hpxml_name = _change_eri_version(hpxml_name, eri_version) unless eri_version == 'latest'
      calc_types = [Constants.CalcTypeERIReferenceHome,
                    Constants.CalcTypeERIIndexAdjustmentDesign,
                    Constants.CalcTypeERIIndexAdjustmentReferenceHome]
      calc_types.each do |calc_type|
        hpxml = _test_measure(hpxml_name, calc_type)
        _check_heating_system(hpxml, calc_type, [{ systype: HPXML::HVACTypeBoiler, fuel: HPXML::FuelTypeNaturalGas, eff: 0.80, dse: _dse(calc_type), eae: 170 }])
        _check_cooling_system(hpxml, calc_type, [{ systype: HPXML::HVACTypeCentralAirConditioner, fuel: HPXML::FuelTypeElectricity, comptype: HPXML::HVACCompressorTypeSingleStage, seer: 13, dse: _dse(calc_type) }])
        _check_heat_pump(hpxml, calc_type)
        _check_thermostat(hpxml, control_type: HPXML::HVACControlTypeManual, htg_sp: 68, clg_sp: 78)
      end
      calc_type = Constants.CalcTypeERIRatedHome
      hpxml = _test_measure(hpxml_name, calc_type)
      _check_heating_system(hpxml, calc_type, [{ systype: HPXML::HVACTypeBoiler, fuel: HPXML::FuelTypeNaturalGas, eff: 0.92, eae: 208, num_units_served: 6 }])
      _check_cooling_system(hpxml, calc_type, [{ systype: HPXML::HVACTypeCentralAirConditioner, fuel: HPXML::FuelTypeElectricity, comptype: HPXML::HVACCompressorTypeSingleStage, seer: 13, dse: _dse(calc_type) }])
      _check_heat_pump(hpxml, calc_type)
      _check_thermostat(hpxml, control_type: HPXML::HVACControlTypeManual, htg_sp: 68, clg_sp: 78)
    end
  end

  def test_shared_boiler_water_loop_heat_pump
    hpxml_name = 'base-hvac-shared-boiler-only-water-loop-heat-pump.xml'

    _eri_versions.each do |eri_version|
      hpxml_name = _change_eri_version(hpxml_name, eri_version) unless eri_version == 'latest'
      calc_types = [Constants.CalcTypeERIReferenceHome,
                    Constants.CalcTypeERIIndexAdjustmentDesign,
                    Constants.CalcTypeERIIndexAdjustmentReferenceHome]
      calc_types.each do |calc_type|
        hpxml = _test_measure(hpxml_name, calc_type)
        _check_heating_system(hpxml, calc_type, [{ systype: HPXML::HVACTypeBoiler, fuel: HPXML::FuelTypeNaturalGas, eff: 0.80, frac_load: 1 - 1 / 4.4, dse: _dse(calc_type), eae: 170 }])
        _check_cooling_system(hpxml, calc_type, [{ systype: HPXML::HVACTypeCentralAirConditioner, fuel: HPXML::FuelTypeElectricity, comptype: HPXML::HVACCompressorTypeSingleStage, seer: 13, dse: _dse(calc_type) }])
        _check_heat_pump(hpxml, calc_type, [{ systype: HPXML::HVACTypeHeatPumpAirToAir, fuel: HPXML::FuelTypeElectricity, comptype: HPXML::HVACCompressorTypeSingleStage, hspf: 7.7, seer: 13, frac_load_heat: 1 / 4.4, dse: _dse(calc_type), backup_fuel: HPXML::FuelTypeElectricity, backup_eff: 1.0, frac_load_cool: 0.0 }])
        _check_thermostat(hpxml, control_type: HPXML::HVACControlTypeManual, htg_sp: 68, clg_sp: 78)
      end
      calc_type = Constants.CalcTypeERIRatedHome
      hpxml = _test_measure(hpxml_name, calc_type)
      _check_heating_system(hpxml, calc_type, [{ systype: HPXML::HVACTypeBoiler, fuel: HPXML::FuelTypeNaturalGas, eff: 0.92, eae: 208, num_units_served: 6 }])
      _check_cooling_system(hpxml, calc_type, [{ systype: HPXML::HVACTypeCentralAirConditioner, fuel: HPXML::FuelTypeElectricity, comptype: HPXML::HVACCompressorTypeSingleStage, seer: 13, dse: _dse(calc_type) }])
      _check_heat_pump(hpxml, calc_type)
      _check_thermostat(hpxml, control_type: HPXML::HVACControlTypeManual, htg_sp: 68, clg_sp: 78)
    end
  end

  def test_shared_chiller_baseboard
    hpxml_name = 'base-hvac-shared-chiller-only-baseboard.xml'

    _eri_versions.each do |eri_version|
      hpxml_name = _change_eri_version(hpxml_name, eri_version) unless eri_version == 'latest'
      calc_types = [Constants.CalcTypeERIReferenceHome,
                    Constants.CalcTypeERIIndexAdjustmentDesign,
                    Constants.CalcTypeERIIndexAdjustmentReferenceHome]
      calc_types.each do |calc_type|
        hpxml = _test_measure(hpxml_name, calc_type)
        _check_cooling_system(hpxml, calc_type, [{ systype: HPXML::HVACTypeCentralAirConditioner, fuel: HPXML::FuelTypeElectricity, comptype: HPXML::HVACCompressorTypeSingleStage, seer: 13, dse: _dse(calc_type) }])
        _check_heating_system(hpxml, calc_type, [{ systype: HPXML::HVACTypeFurnace, fuel: HPXML::FuelTypeNaturalGas, eff: 0.78, dse: _dse(calc_type) }])
        _check_heat_pump(hpxml, calc_type)
        _check_thermostat(hpxml, control_type: HPXML::HVACControlTypeManual, htg_sp: 68, clg_sp: 78)
      end
      calc_type = Constants.CalcTypeERIRatedHome
      hpxml = _test_measure(hpxml_name, calc_type)
      _check_cooling_system(hpxml, calc_type, [{ systype: HPXML::HVACTypeChiller, fuel: HPXML::FuelTypeElectricity, kw_per_ton: 0.9, num_units_served: 6 }])
      _check_heating_system(hpxml, calc_type, [{ systype: HPXML::HVACTypeFurnace, fuel: HPXML::FuelTypeNaturalGas, eff: 0.78, dse: _dse(calc_type) }])
      _check_heat_pump(hpxml, calc_type)
      _check_thermostat(hpxml, control_type: HPXML::HVACControlTypeManual, htg_sp: 68, clg_sp: 78)
    end
  end

  def test_shared_chiller_water_loop_heat_pump
    hpxml_name = 'base-hvac-shared-chiller-only-water-loop-heat-pump.xml'

    _eri_versions.each do |eri_version|
      hpxml_name = _change_eri_version(hpxml_name, eri_version) unless eri_version == 'latest'
      calc_types = [Constants.CalcTypeERIReferenceHome,
                    Constants.CalcTypeERIIndexAdjustmentDesign,
                    Constants.CalcTypeERIIndexAdjustmentReferenceHome]
      calc_types.each do |calc_type|
        hpxml = _test_measure(hpxml_name, calc_type)
        _check_cooling_system(hpxml, calc_type, [{ systype: HPXML::HVACTypeCentralAirConditioner, fuel: HPXML::FuelTypeElectricity, comptype: HPXML::HVACCompressorTypeSingleStage, seer: 13, dse: _dse(calc_type) }])
        _check_heating_system(hpxml, calc_type, [{ systype: HPXML::HVACTypeFurnace, fuel: HPXML::FuelTypeNaturalGas, eff: 0.78, dse: _dse(calc_type) }])
        _check_heat_pump(hpxml, calc_type)
        _check_thermostat(hpxml, control_type: HPXML::HVACControlTypeManual, htg_sp: 68, clg_sp: 78)
      end
      calc_type = Constants.CalcTypeERIRatedHome
      hpxml = _test_measure(hpxml_name, calc_type)
      _check_cooling_system(hpxml, calc_type, [{ systype: HPXML::HVACTypeChiller, fuel: HPXML::FuelTypeElectricity, kw_per_ton: 0.9, wlhp_eer: 12.8, num_units_served: 6 }])
      _check_heating_system(hpxml, calc_type, [{ systype: HPXML::HVACTypeFurnace, fuel: HPXML::FuelTypeNaturalGas, eff: 0.78, dse: _dse(calc_type) }])
      _check_heat_pump(hpxml, calc_type)
      _check_thermostat(hpxml, control_type: HPXML::HVACControlTypeManual, htg_sp: 68, clg_sp: 78)
    end
  end

  def test_shared_cooling_tower_water_loop_heat_pump
    hpxml_name = 'base-hvac-shared-cooling-tower-only-water-loop-heat-pump.xml'

    _eri_versions.each do |eri_version|
      hpxml_name = _change_eri_version(hpxml_name, eri_version) unless eri_version == 'latest'
      calc_types = [Constants.CalcTypeERIReferenceHome,
                    Constants.CalcTypeERIIndexAdjustmentDesign,
                    Constants.CalcTypeERIIndexAdjustmentReferenceHome]
      calc_types.each do |calc_type|
        hpxml = _test_measure(hpxml_name, calc_type)
        _check_cooling_system(hpxml, calc_type, [{ systype: HPXML::HVACTypeCentralAirConditioner, fuel: HPXML::FuelTypeElectricity, comptype: HPXML::HVACCompressorTypeSingleStage, seer: 13, dse: _dse(calc_type) }])
        _check_heating_system(hpxml, calc_type, [{ systype: HPXML::HVACTypeFurnace, fuel: HPXML::FuelTypeNaturalGas, eff: 0.78, dse: _dse(calc_type) }])
        _check_heat_pump(hpxml, calc_type)
        _check_thermostat(hpxml, control_type: HPXML::HVACControlTypeManual, htg_sp: 68, clg_sp: 78)
      end
      calc_type = Constants.CalcTypeERIRatedHome
      hpxml = _test_measure(hpxml_name, calc_type)
      _check_cooling_system(hpxml, calc_type, [{ systype: HPXML::HVACTypeCoolingTower, fuel: HPXML::FuelTypeElectricity, wlhp_eer: 12.8, num_units_served: 6 }])
      _check_heating_system(hpxml, calc_type, [{ systype: HPXML::HVACTypeFurnace, fuel: HPXML::FuelTypeNaturalGas, eff: 0.78, dse: _dse(calc_type) }])
      _check_heat_pump(hpxml, calc_type)
      _check_thermostat(hpxml, control_type: HPXML::HVACControlTypeManual, htg_sp: 68, clg_sp: 78)
    end
  end

  def test_shared_ground_loop_gound_ground_source_heat_pump
    hpxml_name = 'base-hvac-shared-ground-loop-ground-to-air-heat-pump.xml'

    _eri_versions.each do |eri_version|
      hpxml_name = _change_eri_version(hpxml_name, eri_version) unless eri_version == 'latest'
      calc_types = [Constants.CalcTypeERIReferenceHome,
                    Constants.CalcTypeERIIndexAdjustmentDesign,
                    Constants.CalcTypeERIIndexAdjustmentReferenceHome]
      calc_types.each do |calc_type|
        hpxml = _test_measure(hpxml_name, calc_type)
        _check_heat_pump(hpxml, calc_type, [{ systype: HPXML::HVACTypeHeatPumpAirToAir, fuel: HPXML::FuelTypeElectricity, comptype: HPXML::HVACCompressorTypeSingleStage, hspf: 7.7, seer: 13, dse: _dse(calc_type), backup_fuel: HPXML::FuelTypeElectricity, backup_eff: 1.0, frac_load_cool: 0.0 }])
        _check_cooling_system(hpxml, calc_type, [{ systype: HPXML::HVACTypeCentralAirConditioner, fuel: HPXML::FuelTypeElectricity, comptype: HPXML::HVACCompressorTypeSingleStage, seer: 13, dse: _dse(calc_type), shr: 0.73 }])
        _check_heating_system(hpxml, calc_type)
        _check_thermostat(hpxml, control_type: HPXML::HVACControlTypeManual, htg_sp: 68, clg_sp: 78)
      end
      calc_type = Constants.CalcTypeERIRatedHome
      hpxml = _test_measure(hpxml_name, calc_type)
      _check_heat_pump(hpxml, calc_type, [{ systype: HPXML::HVACTypeHeatPumpGroundToAir, fuel: HPXML::FuelTypeElectricity, eer: 16.6, cop: 3.6, shr: 0.73, backup_fuel: HPXML::FuelTypeElectricity, backup_eff: 1.0, pump_w_per_ton: 30, num_units_served: 6 }])
      _check_cooling_system(hpxml, calc_type)
      _check_heating_system(hpxml, calc_type)
      _check_thermostat(hpxml, control_type: HPXML::HVACControlTypeManual, htg_sp: 68, clg_sp: 78)
    end
  end

  def test_programmable_thermostat
    hpxml_name = 'base-hvac-programmable-thermostat.xml'

    calc_types = [Constants.CalcTypeERIReferenceHome,
                  Constants.CalcTypeERIIndexAdjustmentDesign,
                  Constants.CalcTypeERIIndexAdjustmentReferenceHome]
    calc_types.each do |calc_type|
      hpxml = _test_measure(hpxml_name, calc_type)
      _check_thermostat(hpxml, control_type: HPXML::HVACControlTypeManual, htg_sp: 68, clg_sp: 78)
    end
    calc_type = Constants.CalcTypeERIRatedHome
    hpxml = _test_measure(hpxml_name, calc_type)
    _check_thermostat(hpxml, control_type: HPXML::HVACControlTypeProgrammable, htg_sp: 68, clg_sp: 78, htg_setback: 66, htg_setback_hrs: 49, htg_setback_start_hr: 23, clg_setup: 80, clg_setup_hrs: 42, clg_setup_start_hr: 9)
  end

  def test_custom_setpoints
    hpxml_name = 'base-hvac-setpoints.xml'

    calc_types = [Constants.CalcTypeERIRatedHome,
                  Constants.CalcTypeERIReferenceHome,
                  Constants.CalcTypeERIIndexAdjustmentDesign,
                  Constants.CalcTypeERIIndexAdjustmentReferenceHome]
    calc_types.each do |calc_type|
      hpxml = _test_measure(hpxml_name, calc_type)
      _check_thermostat(hpxml, control_type: HPXML::HVACControlTypeManual, htg_sp: 68, clg_sp: 78)
    end
  end

  def test_dse
    hpxml_name = 'base-hvac-dse.xml'

    calc_types = [Constants.CalcTypeERIReferenceHome,
                  Constants.CalcTypeERIIndexAdjustmentDesign,
                  Constants.CalcTypeERIIndexAdjustmentReferenceHome]
    calc_types.each do |calc_type|
      hpxml = _test_measure(hpxml_name, calc_type)
      _check_cooling_system(hpxml, calc_type, [{ systype: HPXML::HVACTypeCentralAirConditioner, fuel: HPXML::FuelTypeElectricity, comptype: HPXML::HVACCompressorTypeSingleStage, seer: 13, dse: _dse(calc_type), shr: 0.73 }])
      _check_heating_system(hpxml, calc_type, [{ systype: HPXML::HVACTypeFurnace, fuel: HPXML::FuelTypeNaturalGas, eff: 0.78, dse: _dse(calc_type) }])
      _check_heat_pump(hpxml, calc_type)
      _check_thermostat(hpxml, control_type: HPXML::HVACControlTypeManual, htg_sp: 68, clg_sp: 78)
    end
    calc_type = Constants.CalcTypeERIRatedHome
    hpxml = _test_measure(hpxml_name, calc_type)
    _check_cooling_system(hpxml, calc_type, [{ systype: HPXML::HVACTypeCentralAirConditioner, fuel: HPXML::FuelTypeElectricity, comptype: HPXML::HVACCompressorTypeSingleStage, seer: 13, dse: 0.7, shr: 0.73 }])
    _check_heating_system(hpxml, calc_type, [{ systype: HPXML::HVACTypeFurnace, fuel: HPXML::FuelTypeNaturalGas, eff: 0.92, dse: _dse(calc_type) }])
    _check_heat_pump(hpxml, calc_type)
    _check_thermostat(hpxml, control_type: HPXML::HVACControlTypeManual, htg_sp: 68, clg_sp: 78)
  end

  def test_duct_leakage_exemption
    # Addendum L
    # Create derivative file for testing
    hpxml_name = 'base-hvac-ducts-leakage-to-outside-exemption.xml'
    hpxml = HPXML.new(hpxml_path: File.join(@root_path, 'workflow', 'sample_files', hpxml_name))
    hpxml.header.eri_calculation_version = '2014ADEGL'
    hpxml_name = File.basename(@tmp_hpxml_path)
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)

    calc_types = [Constants.CalcTypeERIReferenceHome,
                  Constants.CalcTypeERIIndexAdjustmentDesign,
                  Constants.CalcTypeERIIndexAdjustmentReferenceHome]
    calc_types.each do |calc_type|
      hpxml = _test_measure(hpxml_name, calc_type)
      _check_cooling_system(hpxml, calc_type, [{ systype: HPXML::HVACTypeCentralAirConditioner, fuel: HPXML::FuelTypeElectricity, comptype: HPXML::HVACCompressorTypeSingleStage, seer: 13, dse: _dse(calc_type), shr: 0.73 }])
      _check_heating_system(hpxml, calc_type, [{ systype: HPXML::HVACTypeFurnace, fuel: HPXML::FuelTypeNaturalGas, eff: 0.78, dse: _dse(calc_type) }])
      _check_heat_pump(hpxml, calc_type)
      _check_thermostat(hpxml, control_type: HPXML::HVACControlTypeManual, htg_sp: 68, clg_sp: 78)
    end
    calc_type = Constants.CalcTypeERIRatedHome
    hpxml = _test_measure(hpxml_name, calc_type)
    _check_cooling_system(hpxml, calc_type, [{ systype: HPXML::HVACTypeCentralAirConditioner, fuel: HPXML::FuelTypeElectricity, comptype: HPXML::HVACCompressorTypeSingleStage, seer: 13, dse: 0.88, shr: 0.73 }])
    _check_heating_system(hpxml, calc_type, [{ systype: HPXML::HVACTypeFurnace, fuel: HPXML::FuelTypeNaturalGas, eff: 0.92, dse: 0.88 }])
    _check_heat_pump(hpxml, calc_type)
    _check_thermostat(hpxml, control_type: HPXML::HVACControlTypeManual, htg_sp: 68, clg_sp: 78)

    # Addendum D
    # Create derivative file for testing
    hpxml_name = 'base-hvac-ducts-leakage-to-outside-exemption.xml'
    hpxml = HPXML.new(hpxml_path: File.join(@root_path, 'workflow', 'sample_files', hpxml_name))
    hpxml.header.eri_calculation_version = '2014AD'
    hpxml_name = File.basename(@tmp_hpxml_path)
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)

    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_duct_leakage(hpxml, total_or_outside: HPXML::DuctLeakageToOutside, leakage_sum: 0.0)
  end

  def test_duct_leakage_total
    # Addendum L
    # Create derivative file for testing
    hpxml_name = 'base-hvac-ducts-leakage-total.xml'
    hpxml = HPXML.new(hpxml_path: File.join(@root_path, 'workflow', 'sample_files', hpxml_name))
    hpxml.header.eri_calculation_version = '2014ADEGL'
    hpxml_name = File.basename(@tmp_hpxml_path)
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)

    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_duct_leakage(hpxml, total_or_outside: HPXML::DuctLeakageToOutside, leakage_sum: 75.0)

    # Addendum L - Apartments
    # Create derivative file for testing
    hpxml_name = 'base-hvac-ducts-leakage-total.xml'
    hpxml = HPXML.new(hpxml_path: File.join(@root_path, 'workflow', 'sample_files', hpxml_name))
    hpxml.building_construction.residential_facility_type = HPXML::ResidentialTypeApartment
    hpxml_name = File.basename(@tmp_hpxml_path)
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)

    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_duct_leakage(hpxml, total_or_outside: HPXML::DuctLeakageToOutside, leakage_sum: 128.2)
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

    new_hpxml = measure.new_hpxml

    # Check that HVAC sizing correctly specified
    assert_equal(true, new_hpxml.header.use_max_load_for_heat_pumps)
    assert_equal(true, new_hpxml.header.allow_increased_fixed_capacities)

    return new_hpxml
  end

  def _add_hvac_install_qual_values(expected_values, hpxml, calc_type, hvac)
    if Constants.ERIVersions.index(hpxml.header.eri_calculation_version) < Constants.ERIVersions.index('2019AB')
      # HVAC installation quality only applies as of 301-2019 Addendum B
      return
    end

    hvac_type = nil
    if hvac.is_a? HPXML::HeatingSystem
      hvac_type = hvac.heating_system_type
    elsif hvac.is_a? HPXML::CoolingSystem
      hvac_type = hvac.cooling_system_type
    elsif hvac.is_a? HPXML::HeatPump
      hvac_type = hvac.heat_pump_type
    end

    fail 'Could not determine HVAC type.' if hvac_type.nil?

    if [HPXML::HVACTypeFurnace,
        HPXML::HVACTypeCentralAirConditioner,
        HPXML::HVACTypeHeatPumpAirToAir,
        HPXML::HVACTypeHeatPumpMiniSplit,
        HPXML::HVACTypeHeatPumpGroundToAir].include? hvac_type
      if expected_values[:fan_watts_per_cfm].nil?
        if calc_type == Constants.CalcTypeERIIndexAdjustmentDesign
          expected_values[:fan_watts_per_cfm] = 0.45 # W/cfm
        else
          expected_values[:fan_watts_per_cfm] = 0.58 # W/cfm
        end
      end
      if expected_values[:airflow_defect_ratio].nil?
        if calc_type == Constants.CalcTypeERIIndexAdjustmentDesign
          expected_values[:airflow_defect_ratio] = 0.0
        else
          expected_values[:airflow_defect_ratio] = -0.25
        end
      end
    end

    if [HPXML::HVACTypeCentralAirConditioner,
        HPXML::HVACTypeHeatPumpAirToAir,
        HPXML::HVACTypeHeatPumpMiniSplit].include? hvac_type
      if expected_values[:charge_defect_ratio].nil?
        if calc_type == Constants.CalcTypeERIIndexAdjustmentDesign
          expected_values[:charge_defect_ratio] = 0.0
        else
          expected_values[:charge_defect_ratio] = -0.25
        end
      end
    end
  end

  def _check_heating_system(hpxml, calc_type, all_expected_values = [])
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
      frac_load = expected_values[:frac_load].nil? ? 1.0 : expected_values[:frac_load]
      assert_equal(frac_load, heating_system.fraction_heat_load_served)
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
      # HVAC installation quality
      _add_hvac_install_qual_values(expected_values, hpxml, calc_type, heating_system)
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
    end
  end

  def _check_heat_pump(hpxml, calc_type, all_expected_values = [])
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
      frac_load_heat = expected_values[:frac_load_heat].nil? ? 1.0 : expected_values[:frac_load_heat]
      assert_equal(frac_load_heat, heat_pump.fraction_heat_load_served)
      frac_load_cool = expected_values[:frac_load_cool].nil? ? 1.0 : expected_values[:frac_load_cool]
      assert_equal(frac_load_cool, heat_pump.fraction_cool_load_served)
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
      # HVAC installation quality
      _add_hvac_install_qual_values(expected_values, hpxml, calc_type, heat_pump)
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
    end
  end

  def _check_cooling_system(hpxml, calc_type, all_expected_values = [])
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
        assert_equal(expected_values[:seer], cooling_system.cooling_efficiency_seer)
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
      if not expected_values[:wlhp_eer].nil?
        assert_equal(expected_values[:wlhp_eer], cooling_system.wlhp_cooling_efficiency_eer)
      else
        assert_nil(cooling_system.wlhp_cooling_efficiency_eer)
      end
      frac_load = expected_values[:frac_load].nil? ? 1.0 : expected_values[:frac_load]
      assert_equal(frac_load, cooling_system.fraction_cool_load_served)
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
      # HVAC installation quality
      _add_hvac_install_qual_values(expected_values, hpxml, calc_type, cooling_system)
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
    end
  end

  def _check_thermostat(hpxml, control_type:, htg_sp:, clg_sp:, htg_setback: nil, htg_setback_hrs: nil, htg_setback_start_hr: nil,
                        clg_setup: nil, clg_setup_hrs: nil, clg_setup_start_hr: nil)
    assert_equal(1, hpxml.hvac_controls.size)
    hvac_control = hpxml.hvac_controls[0]
    assert_equal(control_type, hvac_control.control_type)
    assert_equal(htg_sp, hvac_control.heating_setpoint_temp)
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

    assert_equal(clg_sp, hvac_control.cooling_setpoint_temp)
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

  def _check_duct_leakage(hpxml, total_or_outside:, leakage_sum:)
    actual_sum = nil
    hpxml.hvac_distributions.each do |hvac_distribution|
      hvac_distribution.duct_leakage_measurements.each do |duct_leakage|
        actual_sum = 0.0 if actual_sum.nil?
        actual_sum += duct_leakage.duct_leakage_value
        assert_equal(HPXML::UnitsCFM25, duct_leakage.duct_leakage_units)
        assert_equal(total_or_outside, duct_leakage.duct_leakage_total_or_to_outside)
      end
    end
    assert_in_epsilon(leakage_sum, actual_sum, 0.01)
  end
end
