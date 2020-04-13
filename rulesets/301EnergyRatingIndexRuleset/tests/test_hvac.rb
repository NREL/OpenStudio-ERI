require_relative '../../../workflow/tests/minitest_helper'
require 'openstudio'
require 'openstudio/ruleset/ShowRunnerOutput'
require 'minitest/autorun'
require_relative '../measure.rb'
require 'fileutils'

class HVACtest < MiniTest::Test
  def before_setup
    @root_path = File.absolute_path(File.join(File.dirname(__FILE__), '..', '..', '..'))
    @tmp_hpxml_path = File.join(@root_path, 'workflow', 'sample_files', 'tmp.xml')
  end

  def after_teardown
    File.delete(@tmp_hpxml_path) if File.exist? @tmp_hpxml_path
  end

  def _dse(calc_type)
    if calc_type == Constants.CalcTypeERIIndexAdjustmentDesign
      dse = 1.0
    else
      dse = 0.8
    end
  end

  def test_none
    hpxml_name = 'base-hvac-none.xml'

    # Reference Home, Rated Home, IAD, IAD Reference
    calc_types = [Constants.CalcTypeERIReferenceHome,
                  Constants.CalcTypeERIRatedHome,
                  Constants.CalcTypeERIIndexAdjustmentDesign,
                  Constants.CalcTypeERIIndexAdjustmentReferenceHome]
    calc_types.each do |calc_type|
      hpxml = _test_measure(hpxml_name, calc_type)
      _check_heating_system(hpxml, [HPXML::HVACTypeFurnace, HPXML::FuelTypeNaturalGas, 0.78, 1.0, _dse(calc_type)])
      _check_cooling_system(hpxml, [HPXML::HVACTypeCentralAirConditioner, HPXML::FuelTypeElectricity, HPXML::HVACCompressorTypeSingleStage, 13, 1.0, _dse(calc_type), nil])
      _check_heat_pump(hpxml)
      _check_thermostat(hpxml, HPXML::HVACControlTypeManual, 68, 78)
    end
  end

  def test_none_with_no_fuel_access
    hpxml_name = 'base-hvac-none-no-fuel-access.xml'

    # Reference Home, Rated Home IAD, IAD Reference
    calc_types = [Constants.CalcTypeERIReferenceHome,
                  Constants.CalcTypeERIRatedHome,
                  Constants.CalcTypeERIIndexAdjustmentDesign,
                  Constants.CalcTypeERIIndexAdjustmentReferenceHome]
    calc_types.each do |calc_type|
      hpxml = _test_measure(hpxml_name, calc_type)
      _check_heat_pump(hpxml, [HPXML::HVACTypeHeatPumpAirToAir, HPXML::FuelTypeElectricity, HPXML::HVACCompressorTypeSingleStage, 7.7, nil, 1.0, 0.0, _dse(calc_type), nil, HPXML::FuelTypeElectricity, 1.0, nil])
      _check_cooling_system(hpxml, [HPXML::HVACTypeCentralAirConditioner, HPXML::FuelTypeElectricity, HPXML::HVACCompressorTypeSingleStage, 13, 1.0, _dse(calc_type), nil])
      _check_heating_system(hpxml)
      _check_thermostat(hpxml, HPXML::HVACControlTypeManual, 68, 78)
    end
  end

  def test_boiler_elec
    hpxml_name = 'base-hvac-boiler-elec-only.xml'

    # Reference Home, IAD, IAD Reference
    calc_types = [Constants.CalcTypeERIReferenceHome,
                  Constants.CalcTypeERIIndexAdjustmentDesign,
                  Constants.CalcTypeERIIndexAdjustmentReferenceHome]
    calc_types.each do |calc_type|
      hpxml = _test_measure(hpxml_name, calc_type)
      _check_heat_pump(hpxml, [HPXML::HVACTypeHeatPumpAirToAir, HPXML::FuelTypeElectricity, HPXML::HVACCompressorTypeSingleStage, 7.7, nil, 1.0, 0.0, _dse(calc_type), nil, HPXML::FuelTypeElectricity, 1.0, nil])
      _check_cooling_system(hpxml, [HPXML::HVACTypeCentralAirConditioner, HPXML::FuelTypeElectricity, HPXML::HVACCompressorTypeSingleStage, 13, 1.0, _dse(calc_type), nil])
      _check_heating_system(hpxml)
      _check_thermostat(hpxml, HPXML::HVACControlTypeManual, 68, 78)
    end

    # Rated Home
    calc_type = Constants.CalcTypeERIRatedHome
    hpxml = _test_measure(hpxml_name, calc_type)
    _check_heating_system(hpxml, [HPXML::HVACTypeBoiler, HPXML::FuelTypeElectricity, nil, 1.0, nil])
    _check_cooling_system(hpxml, [HPXML::HVACTypeCentralAirConditioner, HPXML::FuelTypeElectricity, HPXML::HVACCompressorTypeSingleStage, 13, 1.0, _dse(calc_type), nil])
    _check_heat_pump(hpxml)
    _check_thermostat(hpxml, HPXML::HVACControlTypeManual, 68, 78)
  end

  def test_boiler_gas
    hpxml_name = 'base-hvac-boiler-gas-only.xml'

    # Reference Home, IAD, IAD Reference
    calc_types = [Constants.CalcTypeERIReferenceHome,
                  Constants.CalcTypeERIIndexAdjustmentDesign,
                  Constants.CalcTypeERIIndexAdjustmentReferenceHome]
    calc_types.each do |calc_type|
      hpxml = _test_measure(hpxml_name, calc_type)
      _check_heating_system(hpxml, [HPXML::HVACTypeBoiler, HPXML::FuelTypeNaturalGas, 0.80, 1.0, _dse(calc_type)])
      _check_cooling_system(hpxml, [HPXML::HVACTypeCentralAirConditioner, HPXML::FuelTypeElectricity, HPXML::HVACCompressorTypeSingleStage, 13, 1.0, _dse(calc_type), nil])
      _check_heat_pump(hpxml)
      _check_thermostat(hpxml, HPXML::HVACControlTypeManual, 68, 78)
    end

    # Rated Home
    calc_type = Constants.CalcTypeERIRatedHome
    hpxml = _test_measure(hpxml_name, calc_type)
    _check_heating_system(hpxml, [HPXML::HVACTypeBoiler, HPXML::FuelTypeNaturalGas, nil, 1.0, nil])
    _check_cooling_system(hpxml, [HPXML::HVACTypeCentralAirConditioner, HPXML::FuelTypeElectricity, HPXML::HVACCompressorTypeSingleStage, 13, 1.0, _dse(calc_type), nil])
    _check_heat_pump(hpxml)
    _check_thermostat(hpxml, HPXML::HVACControlTypeManual, 68, 78)
  end

  def test_furnace_elec
    hpxml_name = 'base-hvac-furnace-elec-only.xml'

    # Reference Home, IAD, IAD Reference
    calc_types = [Constants.CalcTypeERIReferenceHome,
                  Constants.CalcTypeERIIndexAdjustmentDesign,
                  Constants.CalcTypeERIIndexAdjustmentReferenceHome]
    calc_types.each do |calc_type|
      hpxml = _test_measure(hpxml_name, calc_type)
      _check_heat_pump(hpxml, [HPXML::HVACTypeHeatPumpAirToAir, HPXML::FuelTypeElectricity, HPXML::HVACCompressorTypeSingleStage, 7.7, nil, 1.0, 0.0, _dse(calc_type), nil, HPXML::FuelTypeElectricity, 1.0, nil])
      _check_cooling_system(hpxml, [HPXML::HVACTypeCentralAirConditioner, HPXML::FuelTypeElectricity, HPXML::HVACCompressorTypeSingleStage, 13, 1.0, _dse(calc_type), nil])
      _check_heating_system(hpxml)
      _check_thermostat(hpxml, HPXML::HVACControlTypeManual, 68, 78)
    end

    # Rated Home
    calc_type = Constants.CalcTypeERIRatedHome
    hpxml = _test_measure(hpxml_name, calc_type)
    _check_heating_system(hpxml, [HPXML::HVACTypeFurnace, HPXML::FuelTypeElectricity, nil, 1.0, nil])
    _check_cooling_system(hpxml, [HPXML::HVACTypeCentralAirConditioner, HPXML::FuelTypeElectricity, HPXML::HVACCompressorTypeSingleStage, 13, 1.0, _dse(calc_type), nil])
    _check_heat_pump(hpxml)
    _check_thermostat(hpxml, HPXML::HVACControlTypeManual, 68, 78)
  end

  def test_furnace_gas
    hpxml_name = 'base-hvac-furnace-gas-only.xml'

    # Reference Home, IAD, IAD Reference
    calc_types = [Constants.CalcTypeERIReferenceHome,
                  Constants.CalcTypeERIIndexAdjustmentDesign,
                  Constants.CalcTypeERIIndexAdjustmentReferenceHome]
    calc_types.each do |calc_type|
      hpxml = _test_measure(hpxml_name, calc_type)
      _check_heating_system(hpxml, [HPXML::HVACTypeFurnace, HPXML::FuelTypeNaturalGas, 0.78, 1.0, _dse(calc_type)])
      _check_cooling_system(hpxml, [HPXML::HVACTypeCentralAirConditioner, HPXML::FuelTypeElectricity, HPXML::HVACCompressorTypeSingleStage, 13, 1.0, _dse(calc_type), nil])
      _check_heat_pump(hpxml)
      _check_thermostat(hpxml, HPXML::HVACControlTypeManual, 68, 78)
    end

    # Rated Home
    calc_type = Constants.CalcTypeERIRatedHome
    hpxml = _test_measure(hpxml_name, calc_type)
    _check_heating_system(hpxml, [HPXML::HVACTypeFurnace, HPXML::FuelTypeNaturalGas, nil, 1.0, nil])
    _check_cooling_system(hpxml, [HPXML::HVACTypeCentralAirConditioner, HPXML::FuelTypeElectricity, HPXML::HVACCompressorTypeSingleStage, 13, 1.0, _dse(calc_type), nil])
    _check_heat_pump(hpxml)
    _check_thermostat(hpxml, HPXML::HVACControlTypeManual, 68, 78)
  end

  def test_stove_oil
    hpxml_name = 'base-hvac-stove-oil-only.xml'

    # Reference Home, IAD, IAD Reference
    calc_types = [Constants.CalcTypeERIReferenceHome,
                  Constants.CalcTypeERIIndexAdjustmentDesign,
                  Constants.CalcTypeERIIndexAdjustmentReferenceHome]
    calc_types.each do |calc_type|
      hpxml = _test_measure(hpxml_name, calc_type)
      _check_heating_system(hpxml, [HPXML::HVACTypeFurnace, HPXML::FuelTypeNaturalGas, 0.78, 1.0, _dse(calc_type)])
      _check_cooling_system(hpxml, [HPXML::HVACTypeCentralAirConditioner, HPXML::FuelTypeElectricity, HPXML::HVACCompressorTypeSingleStage, 13, 1.0, _dse(calc_type), nil])
      _check_heat_pump(hpxml)
      _check_thermostat(hpxml, HPXML::HVACControlTypeManual, 68, 78)
    end

    # Rated Home
    calc_type = Constants.CalcTypeERIRatedHome
    hpxml = _test_measure(hpxml_name, calc_type)
    _check_heating_system(hpxml, [HPXML::HVACTypeStove, HPXML::FuelTypeOil, nil, 1.0, nil])
    _check_cooling_system(hpxml, [HPXML::HVACTypeCentralAirConditioner, HPXML::FuelTypeElectricity, HPXML::HVACCompressorTypeSingleStage, 13, 1.0, _dse(calc_type), nil])
    _check_heat_pump(hpxml)
    _check_thermostat(hpxml, HPXML::HVACControlTypeManual, 68, 78)
  end

  def test_wall_furnace_propane
    hpxml_name = 'base-hvac-wall-furnace-propane-only.xml'

    # Reference Home, IAD, IAD Reference
    calc_types = [Constants.CalcTypeERIReferenceHome,
                  Constants.CalcTypeERIIndexAdjustmentDesign,
                  Constants.CalcTypeERIIndexAdjustmentReferenceHome]
    calc_types.each do |calc_type|
      hpxml = _test_measure(hpxml_name, calc_type)
      _check_heating_system(hpxml, [HPXML::HVACTypeFurnace, HPXML::FuelTypeNaturalGas, 0.78, 1.0, _dse(calc_type)])
      _check_cooling_system(hpxml, [HPXML::HVACTypeCentralAirConditioner, HPXML::FuelTypeElectricity, HPXML::HVACCompressorTypeSingleStage, 13, 1.0, _dse(calc_type), nil])
      _check_heat_pump(hpxml)
      _check_thermostat(hpxml, HPXML::HVACControlTypeManual, 68, 78)
    end

    # Rated Home
    calc_type = Constants.CalcTypeERIRatedHome
    hpxml = _test_measure(hpxml_name, calc_type)
    _check_heating_system(hpxml, [HPXML::HVACTypeWallFurnace, HPXML::FuelTypePropane, nil, 1.0, nil])
    _check_cooling_system(hpxml, [HPXML::HVACTypeCentralAirConditioner, HPXML::FuelTypeElectricity, HPXML::HVACCompressorTypeSingleStage, 13, 1.0, _dse(calc_type), nil])
    _check_heat_pump(hpxml)
    _check_thermostat(hpxml, HPXML::HVACControlTypeManual, 68, 78)
  end

  def test_elec_resistance
    hpxml_name = 'base-hvac-elec-resistance-only.xml'

    # Reference Home, IAD, IAD Reference
    calc_types = [Constants.CalcTypeERIReferenceHome,
                  Constants.CalcTypeERIIndexAdjustmentDesign,
                  Constants.CalcTypeERIIndexAdjustmentReferenceHome]
    calc_types.each do |calc_type|
      hpxml = _test_measure(hpxml_name, calc_type)
      _check_heat_pump(hpxml, [HPXML::HVACTypeHeatPumpAirToAir, HPXML::FuelTypeElectricity, HPXML::HVACCompressorTypeSingleStage, 7.7, nil, 1.0, 0.0, _dse(calc_type), nil, HPXML::FuelTypeElectricity, 1.0, nil])
      _check_cooling_system(hpxml, [HPXML::HVACTypeCentralAirConditioner, HPXML::FuelTypeElectricity, HPXML::HVACCompressorTypeSingleStage, 13, 1.0, _dse(calc_type), nil])
      _check_heating_system(hpxml)
      _check_thermostat(hpxml, HPXML::HVACControlTypeManual, 68, 78)
    end

    # Rated Home
    calc_type = Constants.CalcTypeERIRatedHome
    hpxml = _test_measure(hpxml_name, calc_type)
    _check_heating_system(hpxml, [HPXML::HVACTypeElectricResistance, HPXML::FuelTypeElectricity, nil, 1.0, nil])
    _check_cooling_system(hpxml, [HPXML::HVACTypeCentralAirConditioner, HPXML::FuelTypeElectricity, HPXML::HVACCompressorTypeSingleStage, 13, 1.0, _dse(calc_type), nil])
    _check_heat_pump(hpxml)
    _check_thermostat(hpxml, HPXML::HVACControlTypeManual, 68, 78)
  end

  def test_air_source_heat_pump
    hpxml_name = 'base-hvac-air-to-air-heat-pump-1-speed.xml'

    # Reference Home, IAD, IAD Reference
    calc_types = [Constants.CalcTypeERIReferenceHome,
                  Constants.CalcTypeERIIndexAdjustmentDesign,
                  Constants.CalcTypeERIIndexAdjustmentReferenceHome]
    calc_types.each do |calc_type|
      hpxml = _test_measure(hpxml_name, calc_type)
      _check_heat_pump(hpxml, [HPXML::HVACTypeHeatPumpAirToAir, HPXML::FuelTypeElectricity, HPXML::HVACCompressorTypeSingleStage, 7.7, nil, 1.0, 0.0, _dse(calc_type), nil, HPXML::FuelTypeElectricity, 1.0, nil])
      _check_cooling_system(hpxml, [HPXML::HVACTypeCentralAirConditioner, HPXML::FuelTypeElectricity, HPXML::HVACCompressorTypeSingleStage, 13, 1.0, _dse(calc_type), 0.73])
      _check_heating_system(hpxml)
      _check_thermostat(hpxml, HPXML::HVACControlTypeManual, 68, 78)
    end

    # Rated Home
    calc_type = Constants.CalcTypeERIRatedHome
    hpxml = _test_measure(hpxml_name, calc_type)
    _check_heat_pump(hpxml, [HPXML::HVACTypeHeatPumpAirToAir, HPXML::FuelTypeElectricity, nil, nil, nil, 1.0, 1.0, nil, 0.73, HPXML::FuelTypeElectricity, 1.0, nil])
    _check_cooling_system(hpxml)
    _check_heating_system(hpxml)
    _check_thermostat(hpxml, HPXML::HVACControlTypeManual, 68, 78)
  end

  def test_mini_split_heat_pump_ducted
    hpxml_name = 'base-hvac-mini-split-heat-pump-ducted.xml'

    # Reference Home, IAD, IAD Reference
    calc_types = [Constants.CalcTypeERIReferenceHome,
                  Constants.CalcTypeERIIndexAdjustmentDesign,
                  Constants.CalcTypeERIIndexAdjustmentReferenceHome]
    calc_types.each do |calc_type|
      hpxml = _test_measure(hpxml_name, calc_type)
      _check_heat_pump(hpxml, [HPXML::HVACTypeHeatPumpAirToAir, HPXML::FuelTypeElectricity, HPXML::HVACCompressorTypeSingleStage, 7.7, nil, 1.0, 0.0, _dse(calc_type), nil, HPXML::FuelTypeElectricity, 1.0, nil])
      _check_cooling_system(hpxml, [HPXML::HVACTypeCentralAirConditioner, HPXML::FuelTypeElectricity, HPXML::HVACCompressorTypeSingleStage, 13, 1.0, _dse(calc_type), 0.73])
      _check_heating_system(hpxml)
      _check_thermostat(hpxml, HPXML::HVACControlTypeManual, 68, 78)
    end

    # Rated Home
    calc_type = Constants.CalcTypeERIRatedHome
    hpxml = _test_measure(hpxml_name, calc_type)
    _check_heat_pump(hpxml, [HPXML::HVACTypeHeatPumpMiniSplit, HPXML::FuelTypeElectricity, nil, nil, nil, 1.0, 1.0, nil, 0.73, HPXML::FuelTypeElectricity, 1.0, nil])
    _check_cooling_system(hpxml)
    _check_heating_system(hpxml)
    _check_thermostat(hpxml, HPXML::HVACControlTypeManual, 68, 78)
  end

  def test_mini_split_heat_pump_ductless
    hpxml_name = 'base-hvac-mini-split-heat-pump-ductless.xml'

    # Reference Home, IAD, IAD Reference
    calc_types = [Constants.CalcTypeERIReferenceHome,
                  Constants.CalcTypeERIIndexAdjustmentDesign,
                  Constants.CalcTypeERIIndexAdjustmentReferenceHome]
    calc_types.each do |calc_type|
      hpxml = _test_measure(hpxml_name, calc_type)
      _check_heat_pump(hpxml, [HPXML::HVACTypeHeatPumpAirToAir, HPXML::FuelTypeElectricity, HPXML::HVACCompressorTypeSingleStage, 7.7, nil, 1.0, 0.0, _dse(calc_type), nil, HPXML::FuelTypeElectricity, 1.0, nil])
      _check_cooling_system(hpxml, [HPXML::HVACTypeCentralAirConditioner, HPXML::FuelTypeElectricity, HPXML::HVACCompressorTypeSingleStage, 13, 1.0, _dse(calc_type), 0.73])
      _check_heating_system(hpxml)
      _check_thermostat(hpxml, HPXML::HVACControlTypeManual, 68, 78)
    end

    # Rated Home
    calc_type = Constants.CalcTypeERIRatedHome
    hpxml = _test_measure(hpxml_name, calc_type)
    _check_heat_pump(hpxml, [HPXML::HVACTypeHeatPumpMiniSplit, HPXML::FuelTypeElectricity, nil, nil, nil, 1.0, 1.0, nil, 0.73, HPXML::FuelTypeElectricity, 1.0, nil])
    _check_cooling_system(hpxml)
    _check_heating_system(hpxml)
    _check_thermostat(hpxml, HPXML::HVACControlTypeManual, 68, 78)
  end

  def test_ground_source_heat_pump
    hpxml_name = 'base-hvac-ground-to-air-heat-pump.xml'

    # Reference Home, IAD, IAD Reference
    calc_types = [Constants.CalcTypeERIReferenceHome,
                  Constants.CalcTypeERIIndexAdjustmentDesign,
                  Constants.CalcTypeERIIndexAdjustmentReferenceHome]
    calc_types.each do |calc_type|
      hpxml = _test_measure(hpxml_name, calc_type)
      _check_heat_pump(hpxml, [HPXML::HVACTypeHeatPumpAirToAir, HPXML::FuelTypeElectricity, HPXML::HVACCompressorTypeSingleStage, 7.7, nil, 1.0, 0.0, _dse(calc_type), nil, HPXML::FuelTypeElectricity, 1.0, nil])
      _check_cooling_system(hpxml, [HPXML::HVACTypeCentralAirConditioner, HPXML::FuelTypeElectricity, HPXML::HVACCompressorTypeSingleStage, 13, 1.0, _dse(calc_type), 0.73])
      _check_heating_system(hpxml)
      _check_thermostat(hpxml, HPXML::HVACControlTypeManual, 68, 78)
    end

    # Rated Home
    calc_type = Constants.CalcTypeERIRatedHome
    hpxml = _test_measure(hpxml_name, calc_type)
    _check_heat_pump(hpxml, [HPXML::HVACTypeHeatPumpGroundToAir, HPXML::FuelTypeElectricity, nil, nil, nil, 1.0, 1.0, nil, 0.73, HPXML::FuelTypeElectricity, 1.0, nil])
    _check_cooling_system(hpxml)
    _check_heating_system(hpxml)
    _check_thermostat(hpxml, HPXML::HVACControlTypeManual, 68, 78)
  end

  def test_dual_fuel_heat_pump_gas
    hpxml_name = 'base-hvac-dual-fuel-air-to-air-heat-pump-1-speed.xml'

    # Reference Home, IAD, IAD Reference
    calc_types = [Constants.CalcTypeERIReferenceHome,
                  Constants.CalcTypeERIIndexAdjustmentDesign,
                  Constants.CalcTypeERIIndexAdjustmentReferenceHome]
    calc_types.each do |calc_type|
      hpxml = _test_measure(hpxml_name, calc_type)
      _check_heat_pump(hpxml, [HPXML::HVACTypeHeatPumpAirToAir, HPXML::FuelTypeElectricity, HPXML::HVACCompressorTypeSingleStage, 7.7, nil, 1.0, 0.0, _dse(calc_type), nil, HPXML::FuelTypeNaturalGas, 0.78, 25.0])
      _check_cooling_system(hpxml, [HPXML::HVACTypeCentralAirConditioner, HPXML::FuelTypeElectricity, HPXML::HVACCompressorTypeSingleStage, 13, 1.0, _dse(calc_type), 0.73])
      _check_heating_system(hpxml)
      _check_thermostat(hpxml, HPXML::HVACControlTypeManual, 68, 78)
    end

    # Rated Home
    calc_type = Constants.CalcTypeERIRatedHome
    hpxml = _test_measure(hpxml_name, calc_type)
    _check_heat_pump(hpxml, [HPXML::HVACTypeHeatPumpAirToAir, HPXML::FuelTypeElectricity, nil, nil, nil, 1.0, 1.0, nil, 0.73, HPXML::FuelTypeNaturalGas, 0.95, 25.0])
    _check_cooling_system(hpxml)
    _check_heating_system(hpxml)
    _check_thermostat(hpxml, HPXML::HVACControlTypeManual, 68, 78)
  end

  def test_dual_fuel_heat_pump_electric
    hpxml_name = 'base-hvac-dual-fuel-air-to-air-heat-pump-1-speed-electric.xml'

    # Reference Home, IAD
    calc_types = [Constants.CalcTypeERIReferenceHome,
                  Constants.CalcTypeERIIndexAdjustmentDesign]
    calc_types.each do |calc_type|
      hpxml = _test_measure(hpxml_name, calc_type)
      _check_heat_pump(hpxml, [HPXML::HVACTypeHeatPumpAirToAir, HPXML::FuelTypeElectricity, HPXML::HVACCompressorTypeSingleStage, 7.7, nil, 1.0, 0.0, _dse(calc_type), nil, nil, nil, nil])
      _check_cooling_system(hpxml, [HPXML::HVACTypeCentralAirConditioner, HPXML::FuelTypeElectricity, HPXML::HVACCompressorTypeSingleStage, 13, 1.0, _dse(calc_type), 0.73])
      _check_heating_system(hpxml)
      _check_thermostat(hpxml, HPXML::HVACControlTypeManual, 68, 78)
    end

    # IAD Reference
    calc_type = Constants.CalcTypeERIIndexAdjustmentReferenceHome
    hpxml = _test_measure(hpxml_name, calc_type)
    _check_heat_pump(hpxml, [HPXML::HVACTypeHeatPumpAirToAir, HPXML::FuelTypeElectricity, HPXML::HVACCompressorTypeSingleStage, 7.7, nil, 1.0, 0.0, _dse(calc_type), nil, HPXML::FuelTypeElectricity, 1.0, nil])
    _check_cooling_system(hpxml, [HPXML::HVACTypeCentralAirConditioner, HPXML::FuelTypeElectricity, HPXML::HVACCompressorTypeSingleStage, 13, 1.0, _dse(calc_type), 0.73])
    _check_heating_system(hpxml)
    _check_thermostat(hpxml, HPXML::HVACControlTypeManual, 68, 78)

    # Rated Home
    calc_type = Constants.CalcTypeERIRatedHome
    hpxml = _test_measure(hpxml_name, calc_type)
    _check_heat_pump(hpxml, [HPXML::HVACTypeHeatPumpAirToAir, HPXML::FuelTypeElectricity, nil, nil, nil, 1.0, 1.0, nil, 0.73, HPXML::FuelTypeElectricity, 1.0, 25.0])
    _check_cooling_system(hpxml)
    _check_heating_system(hpxml)
    _check_thermostat(hpxml, HPXML::HVACControlTypeManual, 68, 78)
  end

  def test_central_air_conditioner
    hpxml_name = 'base-hvac-central-ac-only-1-speed.xml'

    # Reference Home, IAD, IAD Reference
    calc_types = [Constants.CalcTypeERIReferenceHome,
                  Constants.CalcTypeERIIndexAdjustmentDesign,
                  Constants.CalcTypeERIIndexAdjustmentReferenceHome]
    calc_types.each do |calc_type|
      hpxml = _test_measure(hpxml_name, calc_type)
      _check_cooling_system(hpxml, [HPXML::HVACTypeCentralAirConditioner, HPXML::FuelTypeElectricity, HPXML::HVACCompressorTypeSingleStage, 13, 1.0, _dse(calc_type), 0.73])
      _check_heating_system(hpxml, [HPXML::HVACTypeFurnace, HPXML::FuelTypeNaturalGas, 0.78, 1.0, _dse(calc_type)])
      _check_heat_pump(hpxml)
      _check_thermostat(hpxml, HPXML::HVACControlTypeManual, 68, 78)
    end

    # Rated Home
    calc_type = Constants.CalcTypeERIRatedHome
    hpxml = _test_measure(hpxml_name, calc_type)
    _check_cooling_system(hpxml, [HPXML::HVACTypeCentralAirConditioner, HPXML::FuelTypeElectricity, nil, nil, 1.0, nil, 0.73])
    _check_heating_system(hpxml, [HPXML::HVACTypeFurnace, HPXML::FuelTypeNaturalGas, 0.78, 1.0, _dse(calc_type)])
    _check_heat_pump(hpxml)
    _check_thermostat(hpxml, HPXML::HVACControlTypeManual, 68, 78)
  end

  def test_room_air_conditioner
    hpxml_name = 'base-hvac-room-ac-only.xml'

    # Reference Home, IAD, IAD Reference
    calc_types = [Constants.CalcTypeERIReferenceHome,
                  Constants.CalcTypeERIIndexAdjustmentDesign,
                  Constants.CalcTypeERIIndexAdjustmentReferenceHome]
    calc_types.each do |calc_type|
      hpxml = _test_measure(hpxml_name, calc_type)
      _check_cooling_system(hpxml, [HPXML::HVACTypeCentralAirConditioner, HPXML::FuelTypeElectricity, HPXML::HVACCompressorTypeSingleStage, 13, 1.0, _dse(calc_type), 0.65])
      _check_heating_system(hpxml, [HPXML::HVACTypeFurnace, HPXML::FuelTypeNaturalGas, 0.78, 1.0, _dse(calc_type)])
      _check_heat_pump(hpxml)
      _check_thermostat(hpxml, HPXML::HVACControlTypeManual, 68, 78)
    end

    # Rated Home
    calc_type = Constants.CalcTypeERIRatedHome
    hpxml = _test_measure(hpxml_name, calc_type)
    _check_cooling_system(hpxml, [HPXML::HVACTypeRoomAirConditioner, HPXML::FuelTypeElectricity, nil, nil, 1.0, nil, 0.65])
    _check_heating_system(hpxml, [HPXML::HVACTypeFurnace, HPXML::FuelTypeNaturalGas, 0.78, 1.0, _dse(calc_type)])
    _check_heat_pump(hpxml)
    _check_thermostat(hpxml, HPXML::HVACControlTypeManual, 68, 78)
  end

  def test_evaporative_cooler
    hpxml_name = 'base-hvac-evap-cooler-only.xml'

    # Reference Home, IAD, IAD Reference
    calc_types = [Constants.CalcTypeERIReferenceHome,
                  Constants.CalcTypeERIIndexAdjustmentDesign,
                  Constants.CalcTypeERIIndexAdjustmentReferenceHome]
    calc_types.each do |calc_type|
      hpxml = _test_measure(hpxml_name, calc_type)
      _check_cooling_system(hpxml, [HPXML::HVACTypeCentralAirConditioner, HPXML::FuelTypeElectricity, HPXML::HVACCompressorTypeSingleStage, 13, 1.0, _dse(calc_type), nil])
      _check_heating_system(hpxml, [HPXML::HVACTypeFurnace, HPXML::FuelTypeNaturalGas, 0.78, 1.0, _dse(calc_type)])
      _check_heat_pump(hpxml)
      _check_thermostat(hpxml, HPXML::HVACControlTypeManual, 68, 78)
    end

    # Rated Home
    calc_type = Constants.CalcTypeERIRatedHome
    hpxml = _test_measure(hpxml_name, calc_type)
    _check_cooling_system(hpxml, [HPXML::HVACTypeEvaporativeCooler, HPXML::FuelTypeElectricity, nil, nil, 1.0, nil, nil])
    _check_heating_system(hpxml, [HPXML::HVACTypeFurnace, HPXML::FuelTypeNaturalGas, 0.78, 1.0, _dse(calc_type)])
    _check_heat_pump(hpxml)
    _check_thermostat(hpxml, HPXML::HVACControlTypeManual, 68, 78)
  end

  def test_furnace_gas_and_central_air_conditioner
    hpxml_name = 'base.xml'

    # Reference Home, IAD, IAD Reference
    calc_types = [Constants.CalcTypeERIReferenceHome,
                  Constants.CalcTypeERIIndexAdjustmentDesign,
                  Constants.CalcTypeERIIndexAdjustmentReferenceHome]
    calc_types.each do |calc_type|
      hpxml = _test_measure(hpxml_name, calc_type)
      _check_cooling_system(hpxml, [HPXML::HVACTypeCentralAirConditioner, HPXML::FuelTypeElectricity, HPXML::HVACCompressorTypeSingleStage, 13, 1.0, _dse(calc_type), 0.73])
      _check_heating_system(hpxml, [HPXML::HVACTypeFurnace, HPXML::FuelTypeNaturalGas, 0.78, 1.0, _dse(calc_type)])
      _check_heat_pump(hpxml)
      _check_thermostat(hpxml, HPXML::HVACControlTypeManual, 68, 78)
    end

    # Rated Home
    calc_type = Constants.CalcTypeERIRatedHome
    hpxml = _test_measure(hpxml_name, calc_type)
    _check_cooling_system(hpxml, [HPXML::HVACTypeCentralAirConditioner, HPXML::FuelTypeElectricity, nil, nil, 1.0, nil, 0.73])
    _check_heating_system(hpxml, [HPXML::HVACTypeFurnace, HPXML::FuelTypeNaturalGas, nil, 1.0, nil])
    _check_heat_pump(hpxml)
    _check_thermostat(hpxml, HPXML::HVACControlTypeManual, 68, 78)
  end

  def test_furnace_gas_room_air_conditioner
    hpxml_name = 'base-hvac-furnace-gas-room-ac.xml'

    # Reference Home, IAD, IAD Reference
    calc_types = [Constants.CalcTypeERIReferenceHome,
                  Constants.CalcTypeERIIndexAdjustmentDesign,
                  Constants.CalcTypeERIIndexAdjustmentReferenceHome]
    calc_types.each do |calc_type|
      hpxml = _test_measure(hpxml_name, calc_type)
      _check_cooling_system(hpxml, [HPXML::HVACTypeCentralAirConditioner, HPXML::FuelTypeElectricity, HPXML::HVACCompressorTypeSingleStage, 13, 1.0, _dse(calc_type), 0.65])
      _check_heating_system(hpxml, [HPXML::HVACTypeFurnace, HPXML::FuelTypeNaturalGas, 0.78, 1.0, _dse(calc_type)])
      _check_heat_pump(hpxml)
      _check_thermostat(hpxml, HPXML::HVACControlTypeManual, 68, 78)
    end

    # Rated Home
    calc_type = Constants.CalcTypeERIRatedHome
    hpxml = _test_measure(hpxml_name, calc_type)
    _check_cooling_system(hpxml, [HPXML::HVACTypeRoomAirConditioner, HPXML::FuelTypeElectricity, nil, nil, 1.0, nil, 0.65])
    _check_heating_system(hpxml, [HPXML::HVACTypeFurnace, HPXML::FuelTypeNaturalGas, nil, 1.0, nil])
    _check_heat_pump(hpxml)
    _check_thermostat(hpxml, HPXML::HVACControlTypeManual, 68, 78)
  end

  def test_multiple_hvac
    hpxml_name = 'base-hvac-multiple.xml'

    # Reference Home, IAD, IAD Reference
    calc_types = [Constants.CalcTypeERIReferenceHome,
                  Constants.CalcTypeERIIndexAdjustmentDesign,
                  Constants.CalcTypeERIIndexAdjustmentReferenceHome]
    calc_types.each do |calc_type|
      hpxml = _test_measure(hpxml_name, calc_type)
      _check_cooling_system(hpxml, [HPXML::HVACTypeCentralAirConditioner, HPXML::FuelTypeElectricity, HPXML::HVACCompressorTypeSingleStage, 13, 0.2, _dse(calc_type), 0.73],
                            [HPXML::HVACTypeCentralAirConditioner, HPXML::FuelTypeElectricity, HPXML::HVACCompressorTypeSingleStage, 13, 0.2, _dse(calc_type), 0.65],
                            [HPXML::HVACTypeCentralAirConditioner, HPXML::FuelTypeElectricity, HPXML::HVACCompressorTypeSingleStage, 13, 0.2, _dse(calc_type), 0.73],
                            [HPXML::HVACTypeCentralAirConditioner, HPXML::FuelTypeElectricity, HPXML::HVACCompressorTypeSingleStage, 13, 0.2, _dse(calc_type), 0.73],
                            [HPXML::HVACTypeCentralAirConditioner, HPXML::FuelTypeElectricity, HPXML::HVACCompressorTypeSingleStage, 13, 0.2, _dse(calc_type), 0.73])
      _check_heating_system(hpxml, [HPXML::HVACTypeFurnace, HPXML::FuelTypeNaturalGas, 0.78, 0.1, _dse(calc_type)],
                            [HPXML::HVACTypeBoiler, HPXML::FuelTypeNaturalGas, 0.8, 0.1, _dse(calc_type)],
                            [HPXML::HVACTypeFurnace, HPXML::FuelTypeNaturalGas, 0.78, 0.1, _dse(calc_type)],
                            [HPXML::HVACTypeFurnace, HPXML::FuelTypeNaturalGas, 0.78, 0.1, _dse(calc_type)])
      _check_heat_pump(hpxml, [HPXML::HVACTypeHeatPumpAirToAir, HPXML::FuelTypeElectricity, HPXML::HVACCompressorTypeSingleStage, 7.7, nil, 0.1, 0.0, _dse(calc_type), nil, HPXML::FuelTypeElectricity, 1.0, nil],
                       [HPXML::HVACTypeHeatPumpAirToAir, HPXML::FuelTypeElectricity, HPXML::HVACCompressorTypeSingleStage, 7.7, nil, 0.1, 0.0, _dse(calc_type), nil, HPXML::FuelTypeElectricity, 1.0, nil],
                       [HPXML::HVACTypeHeatPumpAirToAir, HPXML::FuelTypeElectricity, HPXML::HVACCompressorTypeSingleStage, 7.7, nil, 0.1, 0.0, _dse(calc_type), nil, HPXML::FuelTypeElectricity, 1.0, nil],
                       [HPXML::HVACTypeHeatPumpAirToAir, HPXML::FuelTypeElectricity, HPXML::HVACCompressorTypeSingleStage, 7.7, nil, 0.1, 0.0, _dse(calc_type), nil, HPXML::FuelTypeElectricity, 1.0, nil],
                       [HPXML::HVACTypeHeatPumpAirToAir, HPXML::FuelTypeElectricity, HPXML::HVACCompressorTypeSingleStage, 7.7, nil, 0.1, 0.0, _dse(calc_type), nil, HPXML::FuelTypeElectricity, 1.0, nil],
                       [HPXML::HVACTypeHeatPumpAirToAir, HPXML::FuelTypeElectricity, HPXML::HVACCompressorTypeSingleStage, 7.7, nil, 0.1, 0.0, _dse(calc_type), nil, HPXML::FuelTypeElectricity, 1.0, nil])
      _check_thermostat(hpxml, HPXML::HVACControlTypeManual, 68, 78)
    end

    # Rated Home
    calc_type = Constants.CalcTypeERIRatedHome
    hpxml = _test_measure(hpxml_name, calc_type)
    _check_cooling_system(hpxml, [HPXML::HVACTypeCentralAirConditioner, HPXML::FuelTypeElectricity, nil, nil, 0.2, nil, 0.73],
                          [HPXML::HVACTypeRoomAirConditioner, HPXML::FuelTypeElectricity, nil, nil, 0.2, nil, 0.65])
    _check_heating_system(hpxml, [HPXML::HVACTypeFurnace, HPXML::FuelTypeElectricity, nil, 0.1, nil],
                          [HPXML::HVACTypeFurnace, HPXML::FuelTypeNaturalGas, nil, 0.1, nil],
                          [HPXML::HVACTypeBoiler, HPXML::FuelTypeElectricity, nil, 0.1, nil],
                          [HPXML::HVACTypeBoiler, HPXML::FuelTypeNaturalGas, nil, 0.1, nil],
                          [HPXML::HVACTypeElectricResistance, HPXML::FuelTypeElectricity, nil, 0.1, nil],
                          [HPXML::HVACTypeStove, HPXML::FuelTypeOil, nil, 0.1, nil],
                          [HPXML::HVACTypeWallFurnace, HPXML::FuelTypePropane, nil, 0.1, nil])
    _check_heat_pump(hpxml, [HPXML::HVACTypeHeatPumpAirToAir, HPXML::FuelTypeElectricity, nil, nil, nil, 0.1, 0.2, nil, 0.73, HPXML::FuelTypeElectricity, 1.0, nil],
                     [HPXML::HVACTypeHeatPumpGroundToAir, HPXML::FuelTypeElectricity, nil, nil, nil, 0.1, 0.2, nil, 0.73, HPXML::FuelTypeElectricity, 1.0, nil],
                     [HPXML::HVACTypeHeatPumpMiniSplit, HPXML::FuelTypeElectricity, nil, nil, nil, 0.1, 0.2, nil, 0.73, HPXML::FuelTypeElectricity, 1.0, nil])
    _check_thermostat(hpxml, HPXML::HVACControlTypeManual, 68, 78)
  end

  def test_partial_hvac
    # Create derivative file for testing
    hpxml_name = 'base.xml'
    hpxml = HPXML.new(hpxml_path: File.join(@root_path, 'workflow', 'sample_files', hpxml_name))
    hpxml.heating_systems[0].fraction_heat_load_served = 0.2
    hpxml.cooling_systems[0].fraction_cool_load_served = 0.3

    # Save new file
    hpxml_name = File.basename(@tmp_hpxml_path)
    XMLHelper.write_file(hpxml.to_rexml(), @tmp_hpxml_path)

    # Reference Home, IAD, IAD Reference
    calc_types = [Constants.CalcTypeERIReferenceHome,
                  Constants.CalcTypeERIIndexAdjustmentDesign,
                  Constants.CalcTypeERIIndexAdjustmentReferenceHome]
    calc_types.each do |calc_type|
      hpxml = _test_measure(hpxml_name, calc_type)
      _check_cooling_system(hpxml, [HPXML::HVACTypeCentralAirConditioner, HPXML::FuelTypeElectricity, HPXML::HVACCompressorTypeSingleStage, 13, 0.3, _dse(calc_type), 0.73],
                            [HPXML::HVACTypeCentralAirConditioner, HPXML::FuelTypeElectricity, HPXML::HVACCompressorTypeSingleStage, 13, 0.7, _dse(calc_type), nil])
      _check_heating_system(hpxml, [HPXML::HVACTypeFurnace, HPXML::FuelTypeNaturalGas, 0.78, 0.2, _dse(calc_type)],
                            [HPXML::HVACTypeFurnace, HPXML::FuelTypeNaturalGas, 0.78, 0.8, _dse(calc_type)])
      _check_heat_pump(hpxml)
      _check_thermostat(hpxml, HPXML::HVACControlTypeManual, 68, 78)
    end

    # Rated Home
    calc_type = Constants.CalcTypeERIRatedHome
    hpxml = _test_measure(hpxml_name, calc_type)
    _check_cooling_system(hpxml, [HPXML::HVACTypeCentralAirConditioner, HPXML::FuelTypeElectricity, nil, nil, 0.3, nil, 0.73],
                          [HPXML::HVACTypeCentralAirConditioner, HPXML::FuelTypeElectricity, HPXML::HVACCompressorTypeSingleStage, 13, 0.7, _dse(calc_type), nil])
    _check_heating_system(hpxml, [HPXML::HVACTypeFurnace, HPXML::FuelTypeNaturalGas, nil, 0.2, nil],
                          [HPXML::HVACTypeFurnace, HPXML::FuelTypeNaturalGas, 0.78, 0.8, _dse(calc_type)])
    _check_heat_pump(hpxml)
    _check_thermostat(hpxml, HPXML::HVACControlTypeManual, 68, 78)
  end

  def test_programmable_thermostat
    hpxml_name = 'base-hvac-programmable-thermostat.xml'

    # Reference Home, IAD, IAD Reference
    calc_types = [Constants.CalcTypeERIReferenceHome,
                  Constants.CalcTypeERIIndexAdjustmentDesign,
                  Constants.CalcTypeERIIndexAdjustmentReferenceHome]
    calc_types.each do |calc_type|
      hpxml = _test_measure(hpxml_name, calc_type)
      _check_thermostat(hpxml, HPXML::HVACControlTypeManual, 68, 78)
    end

    # Rated Home
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_thermostat(hpxml, HPXML::HVACControlTypeProgrammable, 68, 78, 66, 7 * 7, 23, 80, 6 * 7, 9)
  end

  def test_ceiling_fan
    hpxml_name = 'base-misc-ceiling-fans.xml'

    # Rated Home, Reference Home, IAD, IAD Reference
    calc_types = [Constants.CalcTypeERIRatedHome,
                  Constants.CalcTypeERIReferenceHome,
                  Constants.CalcTypeERIIndexAdjustmentDesign,
                  Constants.CalcTypeERIIndexAdjustmentReferenceHome]
    calc_types.each do |calc_type|
      hpxml = _test_measure(hpxml_name, calc_type)
      _check_thermostat(hpxml, HPXML::HVACControlTypeManual, 68, 78, nil, nil, nil, nil, nil, nil, 0.5)
    end
  end

  def test_custom_setpoints
    hpxml_name = 'base-hvac-setpoints.xml'

    # Rated Home, Reference Home, IAD, IAD Reference
    calc_types = [Constants.CalcTypeERIRatedHome,
                  Constants.CalcTypeERIReferenceHome,
                  Constants.CalcTypeERIIndexAdjustmentDesign,
                  Constants.CalcTypeERIIndexAdjustmentReferenceHome]
    calc_types.each do |calc_type|
      hpxml = _test_measure(hpxml_name, calc_type)
      _check_thermostat(hpxml, HPXML::HVACControlTypeManual, 68, 78)
    end
  end

  def test_dse
    hpxml_name = 'base-hvac-dse.xml'

    # Reference Home, IAD, IAD Reference
    calc_types = [Constants.CalcTypeERIReferenceHome,
                  Constants.CalcTypeERIIndexAdjustmentDesign,
                  Constants.CalcTypeERIIndexAdjustmentReferenceHome]
    calc_types.each do |calc_type|
      hpxml = _test_measure(hpxml_name, calc_type)
      _check_cooling_system(hpxml, [HPXML::HVACTypeCentralAirConditioner, HPXML::FuelTypeElectricity, HPXML::HVACCompressorTypeSingleStage, 13, 1.0, _dse(calc_type), 0.73])
      _check_heating_system(hpxml, [HPXML::HVACTypeFurnace, HPXML::FuelTypeNaturalGas, 0.78, 1.0, _dse(calc_type)])
      _check_heat_pump(hpxml)
      _check_thermostat(hpxml, HPXML::HVACControlTypeManual, 68, 78)
    end

    # Rated Home
    calc_type = Constants.CalcTypeERIRatedHome
    hpxml = _test_measure(hpxml_name, calc_type)
    _check_cooling_system(hpxml, [HPXML::HVACTypeCentralAirConditioner, HPXML::FuelTypeElectricity, nil, nil, 1.0, 0.7, 0.73])
    _check_heating_system(hpxml, [HPXML::HVACTypeFurnace, HPXML::FuelTypeNaturalGas, nil, 1.0, 0.8])
    _check_heat_pump(hpxml)
    _check_thermostat(hpxml, HPXML::HVACControlTypeManual, 68, 78)
  end

  def test_duct_leakage_exemption
    # Addendum L
    # Create derivative file for testing
    hpxml_name = 'base-hvac-ducts-leakage-exemption.xml'
    hpxml = HPXML.new(hpxml_path: File.join(@root_path, 'workflow', 'sample_files', hpxml_name))
    hpxml.header.eri_calculation_version = '2014ADEGL'
    hpxml_name = File.basename(@tmp_hpxml_path)
    XMLHelper.write_file(hpxml.to_rexml, @tmp_hpxml_path)

    # Reference Home, IAD, IAD Reference
    calc_types = [Constants.CalcTypeERIReferenceHome,
                  Constants.CalcTypeERIIndexAdjustmentDesign,
                  Constants.CalcTypeERIIndexAdjustmentReferenceHome]
    calc_types.each do |calc_type|
      hpxml = _test_measure(hpxml_name, calc_type)
      _check_cooling_system(hpxml, [HPXML::HVACTypeCentralAirConditioner, HPXML::FuelTypeElectricity, HPXML::HVACCompressorTypeSingleStage, 13, 1.0, _dse(calc_type), 0.73])
      _check_heating_system(hpxml, [HPXML::HVACTypeFurnace, HPXML::FuelTypeNaturalGas, 0.78, 1.0, _dse(calc_type)])
      _check_heat_pump(hpxml)
      _check_thermostat(hpxml, HPXML::HVACControlTypeManual, 68, 78)
    end

    # Rated Home
    calc_type = Constants.CalcTypeERIRatedHome
    hpxml = _test_measure(hpxml_name, calc_type)
    _check_cooling_system(hpxml, [HPXML::HVACTypeCentralAirConditioner, HPXML::FuelTypeElectricity, nil, nil, 1.0, 0.88, 0.73])
    _check_heating_system(hpxml, [HPXML::HVACTypeFurnace, HPXML::FuelTypeNaturalGas, nil, 1.0, 0.88])
    _check_heat_pump(hpxml)
    _check_thermostat(hpxml, HPXML::HVACControlTypeManual, 68, 78)

    # Addendum D
    # Create derivative file for testing
    hpxml_name = 'base-hvac-ducts-leakage-exemption.xml'
    hpxml = HPXML.new(hpxml_path: File.join(@root_path, 'workflow', 'sample_files', hpxml_name))
    hpxml.header.eri_calculation_version = '2014AD'
    hpxml_name = File.basename(@tmp_hpxml_path)
    XMLHelper.write_file(hpxml.to_rexml, @tmp_hpxml_path)

    # Rated Home
    calc_type = Constants.CalcTypeERIRatedHome
    hpxml = _test_measure(hpxml_name, calc_type)
    _check_duct_leakage(hpxml, HPXML::DuctLeakageToOutside, 0.0)
  end

  def test_duct_leakage_total
    # Addendum L
    # Create derivative file for testing
    hpxml_name = 'base-hvac-ducts-leakage-total.xml'
    hpxml = HPXML.new(hpxml_path: File.join(@root_path, 'workflow', 'sample_files', hpxml_name))
    hpxml.header.eri_calculation_version = '2014ADEGL'
    hpxml_name = File.basename(@tmp_hpxml_path)
    XMLHelper.write_file(hpxml.to_rexml, @tmp_hpxml_path)

    # Rated Home
    calc_type = Constants.CalcTypeERIRatedHome
    hpxml = _test_measure(hpxml_name, calc_type)
    _check_duct_leakage(hpxml, HPXML::DuctLeakageToOutside, 75.0)

    # Addendum L - Apartments
    # Create derivative file for testing
    hpxml_name = 'base-hvac-ducts-leakage-total.xml'
    hpxml = HPXML.new(hpxml_path: File.join(@root_path, 'workflow', 'sample_files', hpxml_name))
    hpxml.building_construction.residential_facility_type = HPXML::ResidentialTypeApartment
    hpxml_name = File.basename(@tmp_hpxml_path)
    XMLHelper.write_file(hpxml.to_rexml, @tmp_hpxml_path)

    # Rated Home
    calc_type = Constants.CalcTypeERIRatedHome
    hpxml = _test_measure(hpxml_name, calc_type)
    _check_duct_leakage(hpxml, HPXML::DuctLeakageToOutside, 128.2)
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

    return measure.new_hpxml
  end

  def _check_heating_system(hpxml, *systems)
    assert_equal(systems.size, hpxml.heating_systems.size)
    hpxml.heating_systems.each_with_index do |heating_system, idx|
      systype, fueltype, afue, frac_load, dse = systems[idx]
      assert_equal(systype, heating_system.heating_system_type)
      assert_equal(fueltype, heating_system.heating_system_fuel)
      if not afue.nil?
        assert_equal(afue, heating_system.heating_efficiency_afue)
      end
      assert_equal(frac_load, heating_system.fraction_heat_load_served)
      dist_system = heating_system.distribution_system
      if dse.nil?
        assert(dist_system.nil? || dist_system.annual_heating_dse.nil?)
      else
        assert_equal(dse, dist_system.annual_heating_dse)
      end
    end
  end

  def _check_heat_pump(hpxml, *systems)
    assert_equal(systems.size, hpxml.heat_pumps.size)
    hpxml.heat_pumps.each_with_index do |heat_pump, idx|
      systype, fueltype, comptype, hspf, seer, frac_load_heat, frac_load_cool, dse, shr, backup_fuel, backup_eff, backup_temp = systems[idx]
      assert_equal(systype, heat_pump.heat_pump_type)
      assert_equal(fueltype, heat_pump.heat_pump_fuel)
      if not comptype.nil?
        assert_equal(comptype, heat_pump.compressor_type)
      end
      if not hspf.nil?
        assert_equal(hspf, heat_pump.heating_efficiency_hspf)
      end
      if not seer.nil?
        assert_equal(seer, heat_pump.cooling_efficiency_seer)
      end
      assert_equal(frac_load_heat, heat_pump.fraction_heat_load_served)
      assert_equal(frac_load_cool, heat_pump.fraction_cool_load_served)
      dist_system = heat_pump.distribution_system
      if dse.nil?
        assert(dist_system.nil? || dist_system.annual_heating_dse.nil?)
        assert(dist_system.nil? || dist_system.annual_cooling_dse.nil?)
      else
        assert_equal(dse, dist_system.annual_heating_dse)
        assert_equal(dse, dist_system.annual_cooling_dse)
      end
      if shr.nil?
        assert_nil(heat_pump.cooling_shr)
      else
        assert_equal(shr, heat_pump.cooling_shr)
      end
      if backup_fuel.nil?
        assert_nil(heat_pump.backup_heating_fuel)
      else
        assert_equal(backup_fuel, heat_pump.backup_heating_fuel)
      end
      if backup_eff.nil?
        assert_nil(heat_pump.backup_heating_efficiency_percent)
        assert_nil(heat_pump.backup_heating_efficiency_afue)
      else
        assert_equal(backup_eff, heat_pump.backup_heating_efficiency_percent.to_f + heat_pump.backup_heating_efficiency_afue.to_f)
      end
      if backup_temp.nil?
        assert_nil(heat_pump.backup_heating_switchover_temp)
      else
        assert_equal(backup_temp, heat_pump.backup_heating_switchover_temp)
      end
    end
  end

  def _check_cooling_system(hpxml, *systems)
    assert_equal(systems.size, hpxml.cooling_systems.size)
    hpxml.cooling_systems.each_with_index do |cooling_system, idx|
      systype, fueltype, comptype, seer, frac_load, dse, shr = systems[idx]
      assert_equal(systype, cooling_system.cooling_system_type)
      assert_equal(fueltype, cooling_system.cooling_system_fuel)
      if not comptype.nil?
        assert_equal(comptype, cooling_system.compressor_type)
      end
      if not seer.nil?
        assert_equal(seer, cooling_system.cooling_efficiency_seer)
      end
      assert_equal(frac_load, cooling_system.fraction_cool_load_served)
      dist_system = cooling_system.distribution_system
      if dse.nil?
        assert(dist_system.nil? || dist_system.annual_cooling_dse.nil?)
      else
        assert_equal(dse, dist_system.annual_cooling_dse)
      end
      if shr.nil?
        assert_nil(cooling_system.cooling_shr)
      else
        assert_equal(shr, cooling_system.cooling_shr)
      end
    end
  end

  def _check_thermostat(hpxml, control_type, htg_sp, clg_sp, htg_setback = nil, htg_setback_hrs = nil, htg_setback_start_hr = nil,
                        clg_setup = nil, clg_setup_hrs = nil, clg_setup_start_hr = nil, ceiling_fan_offset = nil)
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

    if ceiling_fan_offset.nil?
      assert_nil(hvac_control.ceiling_fan_cooling_setpoint_temp_offset)
    else
      assert_equal(ceiling_fan_offset, hvac_control.ceiling_fan_cooling_setpoint_temp_offset)
    end
  end

  def _check_duct_leakage(hpxml, total_or_to_outside, sum)
    actual_sum = nil
    hpxml.hvac_distributions.each do |hvac_distribution|
      hvac_distribution.duct_leakage_measurements.each do |duct_leakage|
        actual_sum = 0.0 if actual_sum.nil?
        actual_sum += duct_leakage.duct_leakage_value
        assert_equal(HPXML::UnitsCFM25, duct_leakage.duct_leakage_units)
        assert_equal(total_or_to_outside, duct_leakage.duct_leakage_total_or_to_outside)
      end
    end
    assert_in_epsilon(sum, actual_sum, 0.01)
  end
end
