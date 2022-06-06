# frozen_string_literal: true

require_relative '../../../hpxml-measures/HPXMLtoOpenStudio/resources/minitest_helper'
require 'openstudio'
require 'openstudio/ruleset/ShowRunnerOutput'
require_relative '../measure.rb'
require 'fileutils'
require_relative 'util'

class EnergyStarWaterHeatingTest < MiniTest::Test
  def setup
    @root_path = File.absolute_path(File.join(File.dirname(__FILE__), '..', '..', '..'))
    @tmp_hpxml_path = File.join(@root_path, 'workflow', 'sample_files', 'tmp.xml')
  end

  def teardown
    File.delete(@tmp_hpxml_path) if File.exist? @tmp_hpxml_path
  end

  def is_low_flow(es_version)
    if ESConstants.SFVersions.include? es_version
      return false
    elsif ESConstants.MFVersions.include? es_version
      return true
    end
  end

  def pipe_r_value(es_version)
    if [ESConstants.SFOregonWashingtonVer3_2, ESConstants.MFOregonWashingtonVer1_2].include? es_version
      return 3.0
    else
      return 0.0
    end
  end

  def test_water_heating_tank_elec
    ESConstants.AllVersions.each do |es_version|
      _convert_to_es('base.xml', es_version)
      hpxml = _test_measure()
      if [ESConstants.MFNationalVer1_0, ESConstants.MFNationalVer1_1].include? es_version
        _check_water_heater(hpxml, [{ whtype: HPXML::WaterHeaterTypeStorage, fuel: HPXML::FuelTypeElectricity, location: HPXML::LocationLivingSpace, tank_vol: 40, ef: 0.95, n_units_served: 1 }])
      elsif es_version == ESConstants.SFPacificVer3_0
        _check_water_heater(hpxml, [{ whtype: HPXML::WaterHeaterTypeStorage, fuel: HPXML::FuelTypeElectricity, location: HPXML::LocationLivingSpace, tank_vol: 50, ef: 0.90, n_units_served: 1 }])
        _check_solar_thermal_system(hpxml, [{ system_type: 'hot water', solar_fraction: 0.90 }])
      elsif [ESConstants.SFOregonWashingtonVer3_2, ESConstants.MFOregonWashingtonVer1_2].include? es_version
        _check_water_heater(hpxml, [{ whtype: HPXML::WaterHeaterTypeHeatPump, fuel: HPXML::FuelTypeElectricity, location: HPXML::LocationLivingSpace, tank_vol: 60, ef: 2.50, n_units_served: 1 }])
      elsif es_version == ESConstants.SFNationalVer3_2
        _check_water_heater(hpxml, [{ whtype: HPXML::WaterHeaterTypeHeatPump, fuel: HPXML::FuelTypeElectricity, location: HPXML::LocationLivingSpace, tank_vol: 40, uef: 2.20, n_units_served: 1, fhr: 40 }])
      else
        _check_water_heater(hpxml, [{ whtype: HPXML::WaterHeaterTypeStorage, fuel: HPXML::FuelTypeElectricity, location: HPXML::LocationLivingSpace, tank_vol: 40, ef: 0.93, n_units_served: 1 }])
      end
      _check_hot_water_distribution(hpxml, disttype: HPXML::DHWDistTypeStandard, pipe_r: pipe_r_value(es_version), pipe_l: 93.5)
      _check_water_fixtures(hpxml, low_flow_shower: is_low_flow(es_version), low_flow_faucet: is_low_flow(es_version))
      _check_drain_water_heat_recovery(hpxml)
    end
  end

  def test_water_heating_tank_gas
    ESConstants.AllVersions.each do |es_version|
      _convert_to_es('base-dhw-tank-gas-uef.xml', es_version)
      hpxml = _test_measure()
      if [ESConstants.MFNationalVer1_0, ESConstants.MFNationalVer1_1].include? es_version
        _check_water_heater(hpxml, [{ whtype: HPXML::WaterHeaterTypeStorage, fuel: HPXML::FuelTypeNaturalGas, location: HPXML::LocationLivingSpace, tank_vol: 30, ef: 0.67, n_units_served: 1 }])
      elsif es_version == ESConstants.SFPacificVer3_0
        _check_water_heater(hpxml, [{ whtype: HPXML::WaterHeaterTypeStorage, fuel: HPXML::FuelTypeNaturalGas, location: HPXML::LocationLivingSpace, tank_vol: 30, ef: 0.80, n_units_served: 1 }])
      elsif [ESConstants.SFOregonWashingtonVer3_2, ESConstants.MFOregonWashingtonVer1_2].include? es_version
        _check_water_heater(hpxml, [{ whtype: HPXML::WaterHeaterTypeTankless, fuel: HPXML::FuelTypeNaturalGas, location: HPXML::LocationLivingSpace, ef: 0.91, n_units_served: 1 }])
      elsif es_version == ESConstants.SFNationalVer3_2
        _check_water_heater(hpxml, [{ whtype: HPXML::WaterHeaterTypeTankless, fuel: HPXML::FuelTypeNaturalGas, location: HPXML::LocationLivingSpace, uef: 0.90, n_units_served: 1, fhr: 40 }])
      else
        _check_water_heater(hpxml, [{ whtype: HPXML::WaterHeaterTypeStorage, fuel: HPXML::FuelTypeNaturalGas, location: HPXML::LocationLivingSpace, tank_vol: 30, ef: 0.63, n_units_served: 1 }])
      end
      _check_hot_water_distribution(hpxml, disttype: HPXML::DHWDistTypeStandard, pipe_r: pipe_r_value(es_version), pipe_l: 93.5)
      _check_water_fixtures(hpxml, low_flow_shower: is_low_flow(es_version), low_flow_faucet: is_low_flow(es_version))
      _check_drain_water_heat_recovery(hpxml)
    end
  end

  def test_water_heating_tank_oil
    ESConstants.AllVersions.each do |es_version|
      _convert_to_es('base-dhw-tank-oil.xml', es_version)
      hpxml = _test_measure()
      if [ESConstants.MFNationalVer1_0, ESConstants.MFNationalVer1_1].include? es_version
        _check_water_heater(hpxml, [{ whtype: HPXML::WaterHeaterTypeStorage, fuel: HPXML::FuelTypeOil, location: HPXML::LocationLivingSpace, tank_vol: 50, ef: 0.60, n_units_served: 1 }])
      elsif es_version == ESConstants.SFPacificVer3_0
        _check_water_heater(hpxml, [{ whtype: HPXML::WaterHeaterTypeStorage, fuel: HPXML::FuelTypeNaturalGas, location: HPXML::LocationLivingSpace, tank_vol: 50, ef: 0.80, n_units_served: 1 }])
      elsif [ESConstants.SFOregonWashingtonVer3_2, ESConstants.MFOregonWashingtonVer1_2].include? es_version
        _check_water_heater(hpxml, [{ whtype: HPXML::WaterHeaterTypeHeatPump, fuel: HPXML::FuelTypeElectricity, location: HPXML::LocationLivingSpace, tank_vol: 60, ef: 2.50, n_units_served: 1 }])
      elsif es_version == ESConstants.SFNationalVer3_2
        _check_water_heater(hpxml, [{ whtype: HPXML::WaterHeaterTypeTankless, fuel: HPXML::FuelTypeNaturalGas, location: HPXML::LocationLivingSpace, uef: 0.90, n_units_served: 1, fhr: 40 }])
      else
        _check_water_heater(hpxml, [{ whtype: HPXML::WaterHeaterTypeStorage, fuel: HPXML::FuelTypeOil, location: HPXML::LocationLivingSpace, tank_vol: 50, ef: 0.51, n_units_served: 1 }])
      end
      _check_hot_water_distribution(hpxml, disttype: HPXML::DHWDistTypeStandard, pipe_r: pipe_r_value(es_version), pipe_l: 93.5)
      _check_water_fixtures(hpxml, low_flow_shower: is_low_flow(es_version), low_flow_faucet: is_low_flow(es_version))
      _check_drain_water_heat_recovery(hpxml)
    end
  end

  def test_water_heating_tank_heat_pump
    ESConstants.AllVersions.each do |es_version|
      _convert_to_es('base-dhw-tank-heat-pump-uef.xml', es_version)
      hpxml = _test_measure()
      if [ESConstants.MFNationalVer1_0, ESConstants.MFNationalVer1_1].include? es_version
        _check_water_heater(hpxml, [{ whtype: HPXML::WaterHeaterTypeStorage, fuel: HPXML::FuelTypeElectricity, location: HPXML::LocationLivingSpace, tank_vol: 50, ef: 0.95, n_units_served: 1 }])
      elsif es_version == ESConstants.SFPacificVer3_0
        _check_water_heater(hpxml, [{ whtype: HPXML::WaterHeaterTypeStorage, fuel: HPXML::FuelTypeElectricity, location: HPXML::LocationLivingSpace, tank_vol: 50, ef: 0.90, n_units_served: 1 }])
        _check_solar_thermal_system(hpxml, [{ system_type: 'hot water', solar_fraction: 0.90 }])
      elsif [ESConstants.SFOregonWashingtonVer3_2, ESConstants.MFOregonWashingtonVer1_2].include? es_version
        _check_water_heater(hpxml, [{ whtype: HPXML::WaterHeaterTypeHeatPump, fuel: HPXML::FuelTypeElectricity, location: HPXML::LocationLivingSpace, tank_vol: 60, ef: 2.50, n_units_served: 1 }])
      elsif es_version == ESConstants.SFNationalVer3_2
        _check_water_heater(hpxml, [{ whtype: HPXML::WaterHeaterTypeHeatPump, fuel: HPXML::FuelTypeElectricity, location: HPXML::LocationLivingSpace, tank_vol: 50, uef: 2.20, n_units_served: 1, fhr: 40 }])
      else
        _check_water_heater(hpxml, [{ whtype: HPXML::WaterHeaterTypeStorage, fuel: HPXML::FuelTypeElectricity, location: HPXML::LocationLivingSpace, tank_vol: 50, ef: 0.92, n_units_served: 1 }])
      end
      _check_hot_water_distribution(hpxml, disttype: HPXML::DHWDistTypeStandard, pipe_r: pipe_r_value(es_version), pipe_l: 93.5)
      _check_water_fixtures(hpxml, low_flow_shower: is_low_flow(es_version), low_flow_faucet: is_low_flow(es_version))
      _check_drain_water_heat_recovery(hpxml)
    end
  end

  def test_water_heating_tankless_electric
    ESConstants.AllVersions.each do |es_version|
      _convert_to_es('base-dhw-tankless-electric-uef.xml', es_version)
      hpxml = _test_measure()
      if [ESConstants.MFNationalVer1_0, ESConstants.MFNationalVer1_1].include? es_version
        _check_water_heater(hpxml, [{ whtype: HPXML::WaterHeaterTypeStorage, fuel: HPXML::FuelTypeElectricity, location: HPXML::LocationLivingSpace, tank_vol: 60, ef: 0.95, n_units_served: 1 }])
      elsif es_version == ESConstants.SFPacificVer3_0
        _check_water_heater(hpxml, [{ whtype: HPXML::WaterHeaterTypeStorage, fuel: HPXML::FuelTypeElectricity, location: HPXML::LocationLivingSpace, tank_vol: 50, ef: 0.90, n_units_served: 1 }])
        _check_solar_thermal_system(hpxml, [{ system_type: 'hot water', solar_fraction: 0.90 }])
      elsif [ESConstants.SFOregonWashingtonVer3_2, ESConstants.MFOregonWashingtonVer1_2].include? es_version
        _check_water_heater(hpxml, [{ whtype: HPXML::WaterHeaterTypeHeatPump, fuel: HPXML::FuelTypeElectricity, location: HPXML::LocationLivingSpace, tank_vol: 60, ef: 2.50, n_units_served: 1 }])
      elsif es_version == ESConstants.SFNationalVer3_2
        _check_water_heater(hpxml, [{ whtype: HPXML::WaterHeaterTypeHeatPump, fuel: HPXML::FuelTypeElectricity, location: HPXML::LocationLivingSpace, tank_vol: 60, uef: 2.20, n_units_served: 1, fhr: 40 }])
      else
        _check_water_heater(hpxml, [{ whtype: HPXML::WaterHeaterTypeStorage, fuel: HPXML::FuelTypeElectricity, location: HPXML::LocationLivingSpace, tank_vol: 60, ef: 0.91, n_units_served: 1 }])
      end
      _check_hot_water_distribution(hpxml, disttype: HPXML::DHWDistTypeStandard, pipe_r: pipe_r_value(es_version), pipe_l: 93.5)
      _check_water_fixtures(hpxml, low_flow_shower: is_low_flow(es_version), low_flow_faucet: is_low_flow(es_version))
      _check_drain_water_heat_recovery(hpxml)
    end
  end

  def test_water_heating_tankless_gas
    ESConstants.AllVersions.each do |es_version|
      _convert_to_es('base-dhw-tankless-gas-uef.xml', es_version)
      hpxml = _test_measure()
      if [ESConstants.MFNationalVer1_0, ESConstants.MFNationalVer1_1].include? es_version
        _check_water_heater(hpxml, [{ whtype: HPXML::WaterHeaterTypeStorage, fuel: HPXML::FuelTypeNaturalGas, location: HPXML::LocationLivingSpace, tank_vol: 50, ef: 0.67, n_units_served: 1 }])
      elsif es_version == ESConstants.SFPacificVer3_0
        _check_water_heater(hpxml, [{ whtype: HPXML::WaterHeaterTypeStorage, fuel: HPXML::FuelTypeNaturalGas, location: HPXML::LocationLivingSpace, tank_vol: 50, ef: 0.80, n_units_served: 1 }])
      elsif [ESConstants.SFOregonWashingtonVer3_2, ESConstants.MFOregonWashingtonVer1_2].include? es_version
        _check_water_heater(hpxml, [{ whtype: HPXML::WaterHeaterTypeTankless, fuel: HPXML::FuelTypeNaturalGas, location: HPXML::LocationLivingSpace, ef: 0.91, n_units_served: 1 }])
      elsif es_version == ESConstants.SFNationalVer3_2
        _check_water_heater(hpxml, [{ whtype: HPXML::WaterHeaterTypeTankless, fuel: HPXML::FuelTypeNaturalGas, location: HPXML::LocationLivingSpace, uef: 0.90, n_units_served: 1, fhr: 40 }])
      else
        _check_water_heater(hpxml, [{ whtype: HPXML::WaterHeaterTypeStorage, fuel: HPXML::FuelTypeNaturalGas, location: HPXML::LocationLivingSpace, tank_vol: 50, ef: 0.59, n_units_served: 1 }])
      end
      _check_hot_water_distribution(hpxml, disttype: HPXML::DHWDistTypeStandard, pipe_r: pipe_r_value(es_version), pipe_l: 93.5)
      _check_water_fixtures(hpxml, low_flow_shower: is_low_flow(es_version), low_flow_faucet: is_low_flow(es_version))
      _check_drain_water_heat_recovery(hpxml)
    end
  end

  def test_multiple_water_heating
    ESConstants.AllVersions.each do |es_version|
      _convert_to_es('base-dhw-multiple.xml', es_version)
      hpxml = _test_measure()
      if [ESConstants.MFNationalVer1_0, ESConstants.MFNationalVer1_1].include? es_version
        _check_water_heater(hpxml, [{ whtype: HPXML::WaterHeaterTypeStorage, fuel: HPXML::FuelTypeElectricity, frac_load: 0.2, location: HPXML::LocationLivingSpace, tank_vol: 40, ef: 0.95, n_units_served: 1 },
                                    { whtype: HPXML::WaterHeaterTypeStorage, fuel: HPXML::FuelTypeNaturalGas, frac_load: 0.2, location: HPXML::LocationLivingSpace, tank_vol: 50, ef: 0.67, n_units_served: 1 },
                                    { whtype: HPXML::WaterHeaterTypeStorage, fuel: HPXML::FuelTypeElectricity, frac_load: 0.2, location: HPXML::LocationLivingSpace, tank_vol: 80, ef: 0.95, n_units_served: 1 },
                                    { whtype: HPXML::WaterHeaterTypeStorage, fuel: HPXML::FuelTypeElectricity, frac_load: 0.2, location: HPXML::LocationLivingSpace, tank_vol: 60, ef: 0.95, n_units_served: 1 },
                                    { whtype: HPXML::WaterHeaterTypeStorage, fuel: HPXML::FuelTypeNaturalGas, frac_load: 0.1, location: HPXML::LocationLivingSpace, tank_vol: 50, ef: 0.67, n_units_served: 1 },
                                    { whtype: HPXML::WaterHeaterTypeStorage, fuel: HPXML::FuelTypeNaturalGas, frac_load: 0.1, location: HPXML::LocationLivingSpace, tank_vol: 50, ef: 0.67, n_units_served: 1 }])
      elsif es_version == ESConstants.SFPacificVer3_0
        _check_water_heater(hpxml, [{ whtype: HPXML::WaterHeaterTypeStorage, fuel: HPXML::FuelTypeElectricity, frac_load: 0.2, location: HPXML::LocationLivingSpace, tank_vol: 50, ef: 0.90, n_units_served: 1 },
                                    { whtype: HPXML::WaterHeaterTypeStorage, fuel: HPXML::FuelTypeNaturalGas, frac_load: 0.2, location: HPXML::LocationLivingSpace, tank_vol: 50, ef: 0.80, n_units_served: 1 },
                                    { whtype: HPXML::WaterHeaterTypeStorage, fuel: HPXML::FuelTypeElectricity, frac_load: 0.2, location: HPXML::LocationLivingSpace, tank_vol: 50, ef: 0.90, n_units_served: 1 },
                                    { whtype: HPXML::WaterHeaterTypeStorage, fuel: HPXML::FuelTypeElectricity, frac_load: 0.2, location: HPXML::LocationLivingSpace, tank_vol: 50, ef: 0.90, n_units_served: 1 },
                                    { whtype: HPXML::WaterHeaterTypeStorage, fuel: HPXML::FuelTypeNaturalGas, frac_load: 0.1, location: HPXML::LocationLivingSpace, tank_vol: 50, ef: 0.80, n_units_served: 1 },
                                    { whtype: HPXML::WaterHeaterTypeStorage, fuel: HPXML::FuelTypeNaturalGas, frac_load: 0.1, location: HPXML::LocationLivingSpace, tank_vol: 50, ef: 0.80, n_units_served: 1 }])
        _check_solar_thermal_system(hpxml, [{ system_type: 'hot water', solar_fraction: 0.90 }])
      elsif [ESConstants.SFOregonWashingtonVer3_2, ESConstants.MFOregonWashingtonVer1_2].include? es_version
        _check_water_heater(hpxml, [{ whtype: HPXML::WaterHeaterTypeHeatPump, fuel: HPXML::FuelTypeElectricity, frac_load: 0.2, location: HPXML::LocationLivingSpace, tank_vol: 60, ef: 2.50, n_units_served: 1 },
                                    { whtype: HPXML::WaterHeaterTypeTankless, fuel: HPXML::FuelTypeNaturalGas, frac_load: 0.2, location: HPXML::LocationLivingSpace, ef: 0.91, n_units_served: 1 },
                                    { whtype: HPXML::WaterHeaterTypeHeatPump, fuel: HPXML::FuelTypeElectricity, frac_load: 0.2, location: HPXML::LocationLivingSpace, tank_vol: 60, ef: 2.50, n_units_served: 1 },
                                    { whtype: HPXML::WaterHeaterTypeHeatPump, fuel: HPXML::FuelTypeElectricity, frac_load: 0.2, location: HPXML::LocationLivingSpace, tank_vol: 60, ef: 2.50, n_units_served: 1 },
                                    { whtype: HPXML::WaterHeaterTypeTankless, fuel: HPXML::FuelTypeNaturalGas, frac_load: 0.1, location: HPXML::LocationLivingSpace, ef: 0.91, n_units_served: 1 },
                                    { whtype: HPXML::WaterHeaterTypeTankless, fuel: HPXML::FuelTypeNaturalGas, frac_load: 0.1, location: HPXML::LocationLivingSpace, ef: 0.91, n_units_served: 1 }])
      elsif es_version == ESConstants.SFNationalVer3_2
        _check_water_heater(hpxml, [{ whtype: HPXML::WaterHeaterTypeHeatPump, fuel: HPXML::FuelTypeElectricity, frac_load: 0.2, location: HPXML::LocationLivingSpace, tank_vol: 40, uef: 2.20, n_units_served: 1, fhr: 40 },
                                    { whtype: HPXML::WaterHeaterTypeTankless, fuel: HPXML::FuelTypeNaturalGas, frac_load: 0.2, location: HPXML::LocationLivingSpace, uef: 0.90, n_units_served: 1, fhr: 40 },
                                    { whtype: HPXML::WaterHeaterTypeHeatPump, fuel: HPXML::FuelTypeElectricity, frac_load: 0.2, location: HPXML::LocationLivingSpace, tank_vol: 80, uef: 2.20, n_units_served: 1, fhr: 40 },
                                    { whtype: HPXML::WaterHeaterTypeHeatPump, fuel: HPXML::FuelTypeElectricity, frac_load: 0.2, location: HPXML::LocationLivingSpace, tank_vol: 60, uef: 2.20, n_units_served: 1, fhr: 40 },
                                    { whtype: HPXML::WaterHeaterTypeTankless, fuel: HPXML::FuelTypeNaturalGas, frac_load: 0.1, location: HPXML::LocationLivingSpace, uef: 0.90, n_units_served: 1, fhr: 40 },
                                    { whtype: HPXML::WaterHeaterTypeTankless, fuel: HPXML::FuelTypeNaturalGas, frac_load: 0.1, location: HPXML::LocationLivingSpace, uef: 0.90, n_units_served: 1, fhr: 40 }])
      else
        _check_water_heater(hpxml, [{ whtype: HPXML::WaterHeaterTypeStorage, fuel: HPXML::FuelTypeElectricity, frac_load: 0.2, location: HPXML::LocationLivingSpace, tank_vol: 40, ef: 0.93, n_units_served: 1 },
                                    { whtype: HPXML::WaterHeaterTypeStorage, fuel: HPXML::FuelTypeNaturalGas, frac_load: 0.2, location: HPXML::LocationLivingSpace, tank_vol: 50, ef: 0.59, n_units_served: 1 },
                                    { whtype: HPXML::WaterHeaterTypeStorage, fuel: HPXML::FuelTypeElectricity, frac_load: 0.2, location: HPXML::LocationLivingSpace, tank_vol: 80, ef: 0.89, n_units_served: 1 },
                                    { whtype: HPXML::WaterHeaterTypeStorage, fuel: HPXML::FuelTypeElectricity, frac_load: 0.2, location: HPXML::LocationLivingSpace, tank_vol: 60, ef: 0.91, n_units_served: 1 },
                                    { whtype: HPXML::WaterHeaterTypeStorage, fuel: HPXML::FuelTypeNaturalGas, frac_load: 0.1, location: HPXML::LocationLivingSpace, tank_vol: 50, ef: 0.59, n_units_served: 1 },
                                    { whtype: HPXML::WaterHeaterTypeStorage, fuel: HPXML::FuelTypeNaturalGas, frac_load: 0.1, location: HPXML::LocationLivingSpace, tank_vol: 50, ef: 0.59, n_units_served: 1 }])
      end
      _check_hot_water_distribution(hpxml, disttype: HPXML::DHWDistTypeStandard, pipe_r: pipe_r_value(es_version), pipe_l: 93.5)
      _check_water_fixtures(hpxml, low_flow_shower: is_low_flow(es_version), low_flow_faucet: is_low_flow(es_version))
      _check_drain_water_heat_recovery(hpxml)
    end
  end

  def test_indirect_water_heating
    ESConstants.AllVersions.each do |es_version|
      _convert_to_es('base-dhw-indirect-standbyloss.xml', es_version)
      hpxml = _test_measure()
      if [ESConstants.MFNationalVer1_0, ESConstants.MFNationalVer1_1].include? es_version
        _check_water_heater(hpxml, [{ whtype: HPXML::WaterHeaterTypeStorage, fuel: HPXML::FuelTypeNaturalGas, location: HPXML::LocationLivingSpace, tank_vol: 50, ef: 0.67, n_units_served: 1 }])
      elsif es_version == ESConstants.SFPacificVer3_0
        _check_water_heater(hpxml, [{ whtype: HPXML::WaterHeaterTypeStorage, fuel: HPXML::FuelTypeNaturalGas, location: HPXML::LocationLivingSpace, tank_vol: 50, ef: 0.80, n_units_served: 1 }])
      elsif [ESConstants.SFOregonWashingtonVer3_2, ESConstants.MFOregonWashingtonVer1_2].include? es_version
        _check_water_heater(hpxml, [{ whtype: HPXML::WaterHeaterTypeTankless, fuel: HPXML::FuelTypeNaturalGas, location: HPXML::LocationLivingSpace, ef: 0.91, n_units_served: 1 }])
      elsif es_version == ESConstants.SFNationalVer3_2
        _check_water_heater(hpxml, [{ whtype: HPXML::WaterHeaterTypeTankless, fuel: HPXML::FuelTypeNaturalGas, location: HPXML::LocationLivingSpace, uef: 0.90, n_units_served: 1, fhr: 40 }])
      else
        _check_water_heater(hpxml, [{ whtype: HPXML::WaterHeaterTypeStorage, fuel: HPXML::FuelTypeNaturalGas, location: HPXML::LocationLivingSpace, tank_vol: 50, ef: 0.59, n_units_served: 1 }])
      end
      _check_hot_water_distribution(hpxml, disttype: HPXML::DHWDistTypeStandard, pipe_r: pipe_r_value(es_version), pipe_l: 93.5)
      _check_water_fixtures(hpxml, low_flow_shower: is_low_flow(es_version), low_flow_faucet: is_low_flow(es_version))
      _check_drain_water_heat_recovery(hpxml)
    end
  end

  def test_indirect_tankless_coil
    ESConstants.AllVersions.each do |es_version|
      _convert_to_es('base-dhw-combi-tankless.xml', es_version)
      hpxml = _test_measure()
      if [ESConstants.MFNationalVer1_0, ESConstants.MFNationalVer1_1].include? es_version
        _check_water_heater(hpxml, [{ whtype: HPXML::WaterHeaterTypeStorage, fuel: HPXML::FuelTypeNaturalGas, location: HPXML::LocationLivingSpace, tank_vol: 50, ef: 0.67, n_units_served: 1 }])
      elsif es_version == ESConstants.SFPacificVer3_0
        _check_water_heater(hpxml, [{ whtype: HPXML::WaterHeaterTypeStorage, fuel: HPXML::FuelTypeNaturalGas, location: HPXML::LocationLivingSpace, tank_vol: 50, ef: 0.80, n_units_served: 1 }])
      elsif [ESConstants.SFOregonWashingtonVer3_2, ESConstants.MFOregonWashingtonVer1_2].include? es_version
        _check_water_heater(hpxml, [{ whtype: HPXML::WaterHeaterTypeTankless, fuel: HPXML::FuelTypeNaturalGas, location: HPXML::LocationLivingSpace, ef: 0.91, n_units_served: 1 }])
      elsif es_version == ESConstants.SFNationalVer3_2
        _check_water_heater(hpxml, [{ whtype: HPXML::WaterHeaterTypeTankless, fuel: HPXML::FuelTypeNaturalGas, location: HPXML::LocationLivingSpace, uef: 0.90, n_units_served: 1, fhr: 40 }])
      else
        _check_water_heater(hpxml, [{ whtype: HPXML::WaterHeaterTypeStorage, fuel: HPXML::FuelTypeNaturalGas, location: HPXML::LocationLivingSpace, tank_vol: 50, ef: 0.59, n_units_served: 1 }])
      end
      _check_hot_water_distribution(hpxml, disttype: HPXML::DHWDistTypeStandard, pipe_r: pipe_r_value(es_version), pipe_l: 93.5)
      _check_water_fixtures(hpxml, low_flow_shower: is_low_flow(es_version), low_flow_faucet: is_low_flow(es_version))
      _check_drain_water_heat_recovery(hpxml)
    end
  end

  def test_water_heating_recirc
    ESConstants.AllVersions.each do |es_version|
      _convert_to_es('base-dhw-recirc-demand.xml', es_version)
      hpxml = _test_measure()
      if [ESConstants.MFNationalVer1_0, ESConstants.MFNationalVer1_1].include? es_version
        _check_water_heater(hpxml, [{ whtype: HPXML::WaterHeaterTypeStorage, fuel: HPXML::FuelTypeElectricity, location: HPXML::LocationLivingSpace, tank_vol: 40, ef: 0.95, n_units_served: 1 }])
      elsif es_version == ESConstants.SFPacificVer3_0
        _check_water_heater(hpxml, [{ whtype: HPXML::WaterHeaterTypeStorage, fuel: HPXML::FuelTypeElectricity, location: HPXML::LocationLivingSpace, tank_vol: 50, ef: 0.90, n_units_served: 1 }])
      elsif [ESConstants.SFOregonWashingtonVer3_2, ESConstants.MFOregonWashingtonVer1_2].include? es_version
        _check_water_heater(hpxml, [{ whtype: HPXML::WaterHeaterTypeHeatPump, fuel: HPXML::FuelTypeElectricity, frac_load: 1.0, location: HPXML::LocationLivingSpace, tank_vol: 60, ef: 2.50, n_units_served: 1 }])
      elsif es_version == ESConstants.SFNationalVer3_2
        _check_water_heater(hpxml, [{ whtype: HPXML::WaterHeaterTypeHeatPump, fuel: HPXML::FuelTypeElectricity, frac_load: 1.0, location: HPXML::LocationLivingSpace, tank_vol: 40, uef: 2.20, n_units_served: 1, fhr: 40 }])
      else
        _check_water_heater(hpxml, [{ whtype: HPXML::WaterHeaterTypeStorage, fuel: HPXML::FuelTypeElectricity, location: HPXML::LocationLivingSpace, tank_vol: 40, ef: 0.93, n_units_served: 1 }])
      end
      _check_hot_water_distribution(hpxml, disttype: HPXML::DHWDistTypeStandard, pipe_r: pipe_r_value(es_version), pipe_l: 93.5)
      _check_water_fixtures(hpxml, low_flow_shower: is_low_flow(es_version), low_flow_faucet: is_low_flow(es_version))
      _check_drain_water_heat_recovery(hpxml)
    end
  end

  def test_shared_water_heating_recirc
    ESConstants.AllVersions.each do |es_version|
      _convert_to_es('base-bldgtype-multifamily-shared-water-heater-recirc.xml', es_version)
      hpxml = _test_measure()
      if [ESConstants.SFNationalVer3_0, ESConstants.SFNationalVer3_1, ESConstants.SFFloridaVer3_1].include? es_version
        _check_water_heater(hpxml, [{ whtype: HPXML::WaterHeaterTypeStorage, fuel: HPXML::FuelTypeNaturalGas, location: HPXML::LocationLivingSpace, tank_vol: 120.0, ef: 0.45, n_units_served: 1 }])
      elsif es_version == ESConstants.SFPacificVer3_0
        _check_water_heater(hpxml, [{ whtype: HPXML::WaterHeaterTypeStorage, fuel: HPXML::FuelTypeNaturalGas, location: HPXML::LocationLivingSpace, tank_vol: 120.0, ef: 0.80, n_units_served: 1 }])
      elsif [ESConstants.SFOregonWashingtonVer3_2, ESConstants.MFOregonWashingtonVer1_2].include? es_version
        _check_water_heater(hpxml, [{ whtype: HPXML::WaterHeaterTypeTankless, fuel: HPXML::FuelTypeNaturalGas, location: HPXML::LocationLivingSpace, ef: 0.91, n_units_served: 1 }])
      elsif [ESConstants.MFNationalVer1_0, ESConstants.MFNationalVer1_1].include? es_version
        _check_water_heater(hpxml, [{ whtype: HPXML::WaterHeaterTypeStorage, fuel: HPXML::FuelTypeNaturalGas, location: HPXML::LocationLivingSpace, tank_vol: 120.0, ef: 0.77, n_units_served: 1 }])
      end
      _check_hot_water_distribution(hpxml, disttype: HPXML::DHWDistTypeStandard, pipe_r: pipe_r_value(es_version), pipe_l: 70.0, shared_recirc_power: 232.94, shared_recirc_num_units_served: 6, shared_recirc_control_type: HPXML::DHWRecirControlTypeTimer)
      _check_water_fixtures(hpxml, low_flow_shower: is_low_flow(es_version), low_flow_faucet: is_low_flow(es_version))
      _check_drain_water_heat_recovery(hpxml)
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

  def _check_water_heater(hpxml, all_expected_values = [])
    assert_equal(all_expected_values.size, hpxml.water_heating_systems.size)
    hpxml.water_heating_systems.each_with_index do |water_heater, idx|
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
      if expected_values[:standby_loss].nil?
        assert_nil(water_heater.standby_loss)
      else
        assert_equal(expected_values[:standby_loss], water_heater.standby_loss)
      end
      if water_heater.number_of_units_served.nil?
        assert_equal(expected_values[:n_units_served], 1)
      else
        assert_equal(expected_values[:n_units_served], water_heater.number_of_units_served)
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
    end
  end

  def _check_hot_water_distribution(hpxml, disttype:, pipe_r:, pipe_l: nil, recirc_control: nil, recirc_loop_l: nil, recirc_branch_l: nil, recirc_pump_power: nil,
                                    shared_recirc_power: nil, shared_recirc_num_units_served: nil, shared_recirc_control_type: nil)
    assert_equal(1, hpxml.hot_water_distributions.size)
    hot_water_distribution = hpxml.hot_water_distributions[0]
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
      assert_nil(hot_water_distribution.recirculation_piping_length)
    else
      assert_in_epsilon(recirc_loop_l, hot_water_distribution.recirculation_piping_length, 0.01)
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
    if shared_recirc_num_units_served.nil?
      assert_nil(hot_water_distribution.shared_recirculation_number_of_units_served)
    else
      assert_equal(shared_recirc_num_units_served, hot_water_distribution.shared_recirculation_number_of_units_served)
    end
    if shared_recirc_control_type.nil?
      assert_nil(hot_water_distribution.shared_recirculation_control_type)
    else
      assert_equal(shared_recirc_control_type, hot_water_distribution.shared_recirculation_control_type)
    end
  end

  def _check_water_fixtures(hpxml, low_flow_shower:, low_flow_faucet:)
    assert_equal(2, hpxml.water_fixtures.size)
    hpxml.water_fixtures.each do |water_fixture|
      if water_fixture.water_fixture_type == HPXML::WaterFixtureTypeShowerhead
        assert_equal(low_flow_shower, water_fixture.low_flow)
      elsif water_fixture.water_fixture_type == HPXML::WaterFixtureTypeFaucet
        assert_equal(low_flow_faucet, water_fixture.low_flow)
      end
    end
  end

  def _check_drain_water_heat_recovery(hpxml, facilities_connected: nil, equal_flow: nil, efficiency: nil)
    hot_water_distribution = hpxml.hot_water_distributions[0]
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

  def _check_solar_thermal_system(hpxml, systems = [])
    assert_equal(systems.size, hpxml.solar_thermal_systems.size)
    hpxml.solar_thermal_systems.each_with_index do |solar_thermal_system, idx|
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

  def _convert_to_es(hpxml_name, program_version, state_code = nil)
    return convert_to_es(hpxml_name, program_version, @root_path, @tmp_hpxml_path, state_code)
  end
end
