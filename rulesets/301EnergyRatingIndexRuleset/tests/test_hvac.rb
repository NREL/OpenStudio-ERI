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
      hpxml_doc = _test_measure(hpxml_name, calc_type)
      _check_heating_system(hpxml_doc, [HPXML::HVACTypeFurnace, HPXML::FuelTypeNaturalGas, 0.78, 1.0, _dse(calc_type)])
      _check_cooling_system(hpxml_doc, [HPXML::HVACTypeCentralAirConditioner, HPXML::FuelTypeElectricity, HPXML::HVACCompressorTypeSingleStage, 13, 1.0, _dse(calc_type), nil])
      _check_heat_pump(hpxml_doc)
      _check_thermostat(hpxml_doc, HPXML::HVACControlTypeManual, 68, 78)
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
      hpxml_doc = _test_measure(hpxml_name, calc_type)
      _check_heat_pump(hpxml_doc, [HPXML::HVACTypeHeatPumpAirToAir, HPXML::FuelTypeElectricity, HPXML::HVACCompressorTypeSingleStage, 7.7, nil, 1.0, 0.0, _dse(calc_type), nil, HPXML::FuelTypeElectricity, 1.0, nil])
      _check_cooling_system(hpxml_doc, [HPXML::HVACTypeCentralAirConditioner, HPXML::FuelTypeElectricity, HPXML::HVACCompressorTypeSingleStage, 13, 1.0, _dse(calc_type), nil])
      _check_heating_system(hpxml_doc)
      _check_thermostat(hpxml_doc, HPXML::HVACControlTypeManual, 68, 78)
    end
  end

  def test_boiler_elec
    hpxml_name = 'base-hvac-boiler-elec-only.xml'

    # Reference Home, IAD, IAD Reference
    calc_types = [Constants.CalcTypeERIReferenceHome,
                  Constants.CalcTypeERIIndexAdjustmentDesign,
                  Constants.CalcTypeERIIndexAdjustmentReferenceHome]
    calc_types.each do |calc_type|
      hpxml_doc = _test_measure(hpxml_name, calc_type)
      _check_heat_pump(hpxml_doc, [HPXML::HVACTypeHeatPumpAirToAir, HPXML::FuelTypeElectricity, HPXML::HVACCompressorTypeSingleStage, 7.7, nil, 1.0, 0.0, _dse(calc_type), nil, HPXML::FuelTypeElectricity, 1.0, nil])
      _check_cooling_system(hpxml_doc, [HPXML::HVACTypeCentralAirConditioner, HPXML::FuelTypeElectricity, HPXML::HVACCompressorTypeSingleStage, 13, 1.0, _dse(calc_type), nil])
      _check_heating_system(hpxml_doc)
      _check_thermostat(hpxml_doc, HPXML::HVACControlTypeManual, 68, 78)
    end

    # Rated Home
    calc_type = Constants.CalcTypeERIRatedHome
    hpxml_doc = _test_measure(hpxml_name, calc_type)
    _check_heating_system(hpxml_doc, [HPXML::HVACTypeBoiler, HPXML::FuelTypeElectricity, nil, 1.0, nil])
    _check_cooling_system(hpxml_doc, [HPXML::HVACTypeCentralAirConditioner, HPXML::FuelTypeElectricity, HPXML::HVACCompressorTypeSingleStage, 13, 1.0, _dse(calc_type), nil])
    _check_heat_pump(hpxml_doc)
    _check_thermostat(hpxml_doc, HPXML::HVACControlTypeManual, 68, 78)
  end

  def test_boiler_gas
    hpxml_name = 'base-hvac-boiler-gas-only.xml'

    # Reference Home, IAD, IAD Reference
    calc_types = [Constants.CalcTypeERIReferenceHome,
                  Constants.CalcTypeERIIndexAdjustmentDesign,
                  Constants.CalcTypeERIIndexAdjustmentReferenceHome]
    calc_types.each do |calc_type|
      hpxml_doc = _test_measure(hpxml_name, calc_type)
      _check_heating_system(hpxml_doc, [HPXML::HVACTypeBoiler, HPXML::FuelTypeNaturalGas, 0.80, 1.0, _dse(calc_type)])
      _check_cooling_system(hpxml_doc, [HPXML::HVACTypeCentralAirConditioner, HPXML::FuelTypeElectricity, HPXML::HVACCompressorTypeSingleStage, 13, 1.0, _dse(calc_type), nil])
      _check_heat_pump(hpxml_doc)
      _check_thermostat(hpxml_doc, HPXML::HVACControlTypeManual, 68, 78)
    end

    # Rated Home
    calc_type = Constants.CalcTypeERIRatedHome
    hpxml_doc = _test_measure(hpxml_name, calc_type)
    _check_heating_system(hpxml_doc, [HPXML::HVACTypeBoiler, HPXML::FuelTypeNaturalGas, nil, 1.0, nil])
    _check_cooling_system(hpxml_doc, [HPXML::HVACTypeCentralAirConditioner, HPXML::FuelTypeElectricity, HPXML::HVACCompressorTypeSingleStage, 13, 1.0, _dse(calc_type), nil])
    _check_heat_pump(hpxml_doc)
    _check_thermostat(hpxml_doc, HPXML::HVACControlTypeManual, 68, 78)
  end

  def test_furnace_elec
    hpxml_name = 'base-hvac-furnace-elec-only.xml'

    # Reference Home, IAD, IAD Reference
    calc_types = [Constants.CalcTypeERIReferenceHome,
                  Constants.CalcTypeERIIndexAdjustmentDesign,
                  Constants.CalcTypeERIIndexAdjustmentReferenceHome]
    calc_types.each do |calc_type|
      hpxml_doc = _test_measure(hpxml_name, calc_type)
      _check_heat_pump(hpxml_doc, [HPXML::HVACTypeHeatPumpAirToAir, HPXML::FuelTypeElectricity, HPXML::HVACCompressorTypeSingleStage, 7.7, nil, 1.0, 0.0, _dse(calc_type), nil, HPXML::FuelTypeElectricity, 1.0, nil])
      _check_cooling_system(hpxml_doc, [HPXML::HVACTypeCentralAirConditioner, HPXML::FuelTypeElectricity, HPXML::HVACCompressorTypeSingleStage, 13, 1.0, _dse(calc_type), nil])
      _check_heating_system(hpxml_doc)
      _check_thermostat(hpxml_doc, HPXML::HVACControlTypeManual, 68, 78)
    end

    # Rated Home
    calc_type = Constants.CalcTypeERIRatedHome
    hpxml_doc = _test_measure(hpxml_name, calc_type)
    _check_heating_system(hpxml_doc, [HPXML::HVACTypeFurnace, HPXML::FuelTypeElectricity, nil, 1.0, nil])
    _check_cooling_system(hpxml_doc, [HPXML::HVACTypeCentralAirConditioner, HPXML::FuelTypeElectricity, HPXML::HVACCompressorTypeSingleStage, 13, 1.0, _dse(calc_type), nil])
    _check_heat_pump(hpxml_doc)
    _check_thermostat(hpxml_doc, HPXML::HVACControlTypeManual, 68, 78)
  end

  def test_furnace_gas
    hpxml_name = 'base-hvac-furnace-gas-only.xml'

    # Reference Home, IAD, IAD Reference
    calc_types = [Constants.CalcTypeERIReferenceHome,
                  Constants.CalcTypeERIIndexAdjustmentDesign,
                  Constants.CalcTypeERIIndexAdjustmentReferenceHome]
    calc_types.each do |calc_type|
      hpxml_doc = _test_measure(hpxml_name, calc_type)
      _check_heating_system(hpxml_doc, [HPXML::HVACTypeFurnace, HPXML::FuelTypeNaturalGas, 0.78, 1.0, _dse(calc_type)])
      _check_cooling_system(hpxml_doc, [HPXML::HVACTypeCentralAirConditioner, HPXML::FuelTypeElectricity, HPXML::HVACCompressorTypeSingleStage, 13, 1.0, _dse(calc_type), nil])
      _check_heat_pump(hpxml_doc)
      _check_thermostat(hpxml_doc, HPXML::HVACControlTypeManual, 68, 78)
    end

    # Rated Home
    calc_type = Constants.CalcTypeERIRatedHome
    hpxml_doc = _test_measure(hpxml_name, calc_type)
    _check_heating_system(hpxml_doc, [HPXML::HVACTypeFurnace, HPXML::FuelTypeNaturalGas, nil, 1.0, nil])
    _check_cooling_system(hpxml_doc, [HPXML::HVACTypeCentralAirConditioner, HPXML::FuelTypeElectricity, HPXML::HVACCompressorTypeSingleStage, 13, 1.0, _dse(calc_type), nil])
    _check_heat_pump(hpxml_doc)
    _check_thermostat(hpxml_doc, HPXML::HVACControlTypeManual, 68, 78)
  end

  def test_stove_oil
    hpxml_name = 'base-hvac-stove-oil-only.xml'

    # Reference Home, IAD, IAD Reference
    calc_types = [Constants.CalcTypeERIReferenceHome,
                  Constants.CalcTypeERIIndexAdjustmentDesign,
                  Constants.CalcTypeERIIndexAdjustmentReferenceHome]
    calc_types.each do |calc_type|
      hpxml_doc = _test_measure(hpxml_name, calc_type)
      _check_heating_system(hpxml_doc, [HPXML::HVACTypeFurnace, HPXML::FuelTypeNaturalGas, 0.78, 1.0, _dse(calc_type)])
      _check_cooling_system(hpxml_doc, [HPXML::HVACTypeCentralAirConditioner, HPXML::FuelTypeElectricity, HPXML::HVACCompressorTypeSingleStage, 13, 1.0, _dse(calc_type), nil])
      _check_heat_pump(hpxml_doc)
      _check_thermostat(hpxml_doc, HPXML::HVACControlTypeManual, 68, 78)
    end

    # Rated Home
    calc_type = Constants.CalcTypeERIRatedHome
    hpxml_doc = _test_measure(hpxml_name, calc_type)
    _check_heating_system(hpxml_doc, [HPXML::HVACTypeStove, HPXML::FuelTypeOil, nil, 1.0, nil])
    _check_cooling_system(hpxml_doc, [HPXML::HVACTypeCentralAirConditioner, HPXML::FuelTypeElectricity, HPXML::HVACCompressorTypeSingleStage, 13, 1.0, _dse(calc_type), nil])
    _check_heat_pump(hpxml_doc)
    _check_thermostat(hpxml_doc, HPXML::HVACControlTypeManual, 68, 78)
  end

  def test_wall_furnace_propane
    hpxml_name = 'base-hvac-wall-furnace-propane-only.xml'

    # Reference Home, IAD, IAD Reference
    calc_types = [Constants.CalcTypeERIReferenceHome,
                  Constants.CalcTypeERIIndexAdjustmentDesign,
                  Constants.CalcTypeERIIndexAdjustmentReferenceHome]
    calc_types.each do |calc_type|
      hpxml_doc = _test_measure(hpxml_name, calc_type)
      _check_heating_system(hpxml_doc, [HPXML::HVACTypeFurnace, HPXML::FuelTypeNaturalGas, 0.78, 1.0, _dse(calc_type)])
      _check_cooling_system(hpxml_doc, [HPXML::HVACTypeCentralAirConditioner, HPXML::FuelTypeElectricity, HPXML::HVACCompressorTypeSingleStage, 13, 1.0, _dse(calc_type), nil])
      _check_heat_pump(hpxml_doc)
      _check_thermostat(hpxml_doc, HPXML::HVACControlTypeManual, 68, 78)
    end

    # Rated Home
    calc_type = Constants.CalcTypeERIRatedHome
    hpxml_doc = _test_measure(hpxml_name, calc_type)
    _check_heating_system(hpxml_doc, [HPXML::HVACTypeWallFurnace, HPXML::FuelTypePropane, nil, 1.0, nil])
    _check_cooling_system(hpxml_doc, [HPXML::HVACTypeCentralAirConditioner, HPXML::FuelTypeElectricity, HPXML::HVACCompressorTypeSingleStage, 13, 1.0, _dse(calc_type), nil])
    _check_heat_pump(hpxml_doc)
    _check_thermostat(hpxml_doc, HPXML::HVACControlTypeManual, 68, 78)
  end

  def test_elec_resistance
    hpxml_name = 'base-hvac-elec-resistance-only.xml'

    # Reference Home, IAD, IAD Reference
    calc_types = [Constants.CalcTypeERIReferenceHome,
                  Constants.CalcTypeERIIndexAdjustmentDesign,
                  Constants.CalcTypeERIIndexAdjustmentReferenceHome]
    calc_types.each do |calc_type|
      hpxml_doc = _test_measure(hpxml_name, calc_type)
      _check_heat_pump(hpxml_doc, [HPXML::HVACTypeHeatPumpAirToAir, HPXML::FuelTypeElectricity, HPXML::HVACCompressorTypeSingleStage, 7.7, nil, 1.0, 0.0, _dse(calc_type), nil, HPXML::FuelTypeElectricity, 1.0, nil])
      _check_cooling_system(hpxml_doc, [HPXML::HVACTypeCentralAirConditioner, HPXML::FuelTypeElectricity, HPXML::HVACCompressorTypeSingleStage, 13, 1.0, _dse(calc_type), nil])
      _check_heating_system(hpxml_doc)
      _check_thermostat(hpxml_doc, HPXML::HVACControlTypeManual, 68, 78)
    end

    # Rated Home
    calc_type = Constants.CalcTypeERIRatedHome
    hpxml_doc = _test_measure(hpxml_name, calc_type)
    _check_heating_system(hpxml_doc, [HPXML::HVACTypeElectricResistance, HPXML::FuelTypeElectricity, nil, 1.0, nil])
    _check_cooling_system(hpxml_doc, [HPXML::HVACTypeCentralAirConditioner, HPXML::FuelTypeElectricity, HPXML::HVACCompressorTypeSingleStage, 13, 1.0, _dse(calc_type), nil])
    _check_heat_pump(hpxml_doc)
    _check_thermostat(hpxml_doc, HPXML::HVACControlTypeManual, 68, 78)
  end

  def test_air_source_heat_pump
    hpxml_name = 'base-hvac-air-to-air-heat-pump-1-speed.xml'

    # Reference Home, IAD, IAD Reference
    calc_types = [Constants.CalcTypeERIReferenceHome,
                  Constants.CalcTypeERIIndexAdjustmentDesign,
                  Constants.CalcTypeERIIndexAdjustmentReferenceHome]
    calc_types.each do |calc_type|
      hpxml_doc = _test_measure(hpxml_name, calc_type)
      _check_heat_pump(hpxml_doc, [HPXML::HVACTypeHeatPumpAirToAir, HPXML::FuelTypeElectricity, HPXML::HVACCompressorTypeSingleStage, 7.7, nil, 1.0, 0.0, _dse(calc_type), nil, HPXML::FuelTypeElectricity, 1.0, nil])
      _check_cooling_system(hpxml_doc, [HPXML::HVACTypeCentralAirConditioner, HPXML::FuelTypeElectricity, HPXML::HVACCompressorTypeSingleStage, 13, 1.0, _dse(calc_type), 0.73])
      _check_heating_system(hpxml_doc)
      _check_thermostat(hpxml_doc, HPXML::HVACControlTypeManual, 68, 78)
    end

    # Rated Home
    calc_type = Constants.CalcTypeERIRatedHome
    hpxml_doc = _test_measure(hpxml_name, calc_type)
    _check_heat_pump(hpxml_doc, [HPXML::HVACTypeHeatPumpAirToAir, HPXML::FuelTypeElectricity, nil, nil, nil, 1.0, 1.0, nil, 0.73, HPXML::FuelTypeElectricity, 1.0, nil])
    _check_cooling_system(hpxml_doc)
    _check_heating_system(hpxml_doc)
    _check_thermostat(hpxml_doc, HPXML::HVACControlTypeManual, 68, 78)
  end

  def test_mini_split_heat_pump_ducted
    hpxml_name = 'base-hvac-mini-split-heat-pump-ducted.xml'

    # Reference Home, IAD, IAD Reference
    calc_types = [Constants.CalcTypeERIReferenceHome,
                  Constants.CalcTypeERIIndexAdjustmentDesign,
                  Constants.CalcTypeERIIndexAdjustmentReferenceHome]
    calc_types.each do |calc_type|
      hpxml_doc = _test_measure(hpxml_name, calc_type)
      _check_heat_pump(hpxml_doc, [HPXML::HVACTypeHeatPumpAirToAir, HPXML::FuelTypeElectricity, HPXML::HVACCompressorTypeSingleStage, 7.7, nil, 1.0, 0.0, _dse(calc_type), nil, HPXML::FuelTypeElectricity, 1.0, nil])
      _check_cooling_system(hpxml_doc, [HPXML::HVACTypeCentralAirConditioner, HPXML::FuelTypeElectricity, HPXML::HVACCompressorTypeSingleStage, 13, 1.0, _dse(calc_type), 0.73])
      _check_heating_system(hpxml_doc)
      _check_thermostat(hpxml_doc, HPXML::HVACControlTypeManual, 68, 78)
    end

    # Rated Home
    calc_type = Constants.CalcTypeERIRatedHome
    hpxml_doc = _test_measure(hpxml_name, calc_type)
    _check_heat_pump(hpxml_doc, [HPXML::HVACTypeHeatPumpMiniSplit, HPXML::FuelTypeElectricity, nil, nil, nil, 1.0, 1.0, nil, 0.73, HPXML::FuelTypeElectricity, 1.0, nil])
    _check_cooling_system(hpxml_doc)
    _check_heating_system(hpxml_doc)
    _check_thermostat(hpxml_doc, HPXML::HVACControlTypeManual, 68, 78)
  end

  def test_mini_split_heat_pump_ductless
    hpxml_name = 'base-hvac-mini-split-heat-pump-ductless.xml'

    # Reference Home, IAD, IAD Reference
    calc_types = [Constants.CalcTypeERIReferenceHome,
                  Constants.CalcTypeERIIndexAdjustmentDesign,
                  Constants.CalcTypeERIIndexAdjustmentReferenceHome]
    calc_types.each do |calc_type|
      hpxml_doc = _test_measure(hpxml_name, calc_type)
      _check_heat_pump(hpxml_doc, [HPXML::HVACTypeHeatPumpAirToAir, HPXML::FuelTypeElectricity, HPXML::HVACCompressorTypeSingleStage, 7.7, nil, 1.0, 0.0, _dse(calc_type), nil, HPXML::FuelTypeElectricity, 1.0, nil])
      _check_cooling_system(hpxml_doc, [HPXML::HVACTypeCentralAirConditioner, HPXML::FuelTypeElectricity, HPXML::HVACCompressorTypeSingleStage, 13, 1.0, _dse(calc_type), 0.73])
      _check_heating_system(hpxml_doc)
      _check_thermostat(hpxml_doc, HPXML::HVACControlTypeManual, 68, 78)
    end

    # Rated Home
    calc_type = Constants.CalcTypeERIRatedHome
    hpxml_doc = _test_measure(hpxml_name, calc_type)
    _check_heat_pump(hpxml_doc, [HPXML::HVACTypeHeatPumpMiniSplit, HPXML::FuelTypeElectricity, nil, nil, nil, 1.0, 1.0, nil, 0.73, HPXML::FuelTypeElectricity, 1.0, nil])
    _check_cooling_system(hpxml_doc)
    _check_heating_system(hpxml_doc)
    _check_thermostat(hpxml_doc, HPXML::HVACControlTypeManual, 68, 78)
  end

  def test_ground_source_heat_pump
    hpxml_name = 'base-hvac-ground-to-air-heat-pump.xml'

    # Reference Home, IAD, IAD Reference
    calc_types = [Constants.CalcTypeERIReferenceHome,
                  Constants.CalcTypeERIIndexAdjustmentDesign,
                  Constants.CalcTypeERIIndexAdjustmentReferenceHome]
    calc_types.each do |calc_type|
      hpxml_doc = _test_measure(hpxml_name, calc_type)
      _check_heat_pump(hpxml_doc, [HPXML::HVACTypeHeatPumpAirToAir, HPXML::FuelTypeElectricity, HPXML::HVACCompressorTypeSingleStage, 7.7, nil, 1.0, 0.0, _dse(calc_type), nil, HPXML::FuelTypeElectricity, 1.0, nil])
      _check_cooling_system(hpxml_doc, [HPXML::HVACTypeCentralAirConditioner, HPXML::FuelTypeElectricity, HPXML::HVACCompressorTypeSingleStage, 13, 1.0, _dse(calc_type), 0.73])
      _check_heating_system(hpxml_doc)
      _check_thermostat(hpxml_doc, HPXML::HVACControlTypeManual, 68, 78)
    end

    # Rated Home
    calc_type = Constants.CalcTypeERIRatedHome
    hpxml_doc = _test_measure(hpxml_name, calc_type)
    _check_heat_pump(hpxml_doc, [HPXML::HVACTypeHeatPumpGroundToAir, HPXML::FuelTypeElectricity, nil, nil, nil, 1.0, 1.0, nil, 0.73, HPXML::FuelTypeElectricity, 1.0, nil])
    _check_cooling_system(hpxml_doc)
    _check_heating_system(hpxml_doc)
    _check_thermostat(hpxml_doc, HPXML::HVACControlTypeManual, 68, 78)
  end

  def test_dual_fuel_heat_pump_gas
    hpxml_name = 'base-hvac-dual-fuel-air-to-air-heat-pump-1-speed.xml'

    # Reference Home, IAD, IAD Reference
    calc_types = [Constants.CalcTypeERIReferenceHome,
                  Constants.CalcTypeERIIndexAdjustmentDesign,
                  Constants.CalcTypeERIIndexAdjustmentReferenceHome]
    calc_types.each do |calc_type|
      hpxml_doc = _test_measure(hpxml_name, calc_type)
      _check_heat_pump(hpxml_doc, [HPXML::HVACTypeHeatPumpAirToAir, HPXML::FuelTypeElectricity, HPXML::HVACCompressorTypeSingleStage, 7.7, nil, 1.0, 0.0, _dse(calc_type), nil, HPXML::FuelTypeNaturalGas, 0.78, 25.0])
      _check_cooling_system(hpxml_doc, [HPXML::HVACTypeCentralAirConditioner, HPXML::FuelTypeElectricity, HPXML::HVACCompressorTypeSingleStage, 13, 1.0, _dse(calc_type), 0.73])
      _check_heating_system(hpxml_doc)
      _check_thermostat(hpxml_doc, HPXML::HVACControlTypeManual, 68, 78)
    end

    # Rated Home
    calc_type = Constants.CalcTypeERIRatedHome
    hpxml_doc = _test_measure(hpxml_name, calc_type)
    _check_heat_pump(hpxml_doc, [HPXML::HVACTypeHeatPumpAirToAir, HPXML::FuelTypeElectricity, nil, nil, nil, 1.0, 1.0, nil, 0.73, HPXML::FuelTypeNaturalGas, 0.95, 25.0])
    _check_cooling_system(hpxml_doc)
    _check_heating_system(hpxml_doc)
    _check_thermostat(hpxml_doc, HPXML::HVACControlTypeManual, 68, 78)
  end

  def test_dual_fuel_heat_pump_electric
    hpxml_name = 'base-hvac-dual-fuel-air-to-air-heat-pump-1-speed-electric.xml'

    # Reference Home, IAD
    calc_types = [Constants.CalcTypeERIReferenceHome,
                  Constants.CalcTypeERIIndexAdjustmentDesign]
    calc_types.each do |calc_type|
      hpxml_doc = _test_measure(hpxml_name, calc_type)
      _check_heat_pump(hpxml_doc, [HPXML::HVACTypeHeatPumpAirToAir, HPXML::FuelTypeElectricity, HPXML::HVACCompressorTypeSingleStage, 7.7, nil, 1.0, 0.0, _dse(calc_type), nil, nil, nil, nil])
      _check_cooling_system(hpxml_doc, [HPXML::HVACTypeCentralAirConditioner, HPXML::FuelTypeElectricity, HPXML::HVACCompressorTypeSingleStage, 13, 1.0, _dse(calc_type), 0.73])
      _check_heating_system(hpxml_doc)
      _check_thermostat(hpxml_doc, HPXML::HVACControlTypeManual, 68, 78)
    end

    # IAD Reference
    calc_type = Constants.CalcTypeERIIndexAdjustmentReferenceHome
    hpxml_doc = _test_measure(hpxml_name, calc_type)
    _check_heat_pump(hpxml_doc, [HPXML::HVACTypeHeatPumpAirToAir, HPXML::FuelTypeElectricity, HPXML::HVACCompressorTypeSingleStage, 7.7, nil, 1.0, 0.0, _dse(calc_type), nil, HPXML::FuelTypeElectricity, 1.0, nil])
    _check_cooling_system(hpxml_doc, [HPXML::HVACTypeCentralAirConditioner, HPXML::FuelTypeElectricity, HPXML::HVACCompressorTypeSingleStage, 13, 1.0, _dse(calc_type), 0.73])
    _check_heating_system(hpxml_doc)
    _check_thermostat(hpxml_doc, HPXML::HVACControlTypeManual, 68, 78)

    # Rated Home
    calc_type = Constants.CalcTypeERIRatedHome
    hpxml_doc = _test_measure(hpxml_name, calc_type)
    _check_heat_pump(hpxml_doc, [HPXML::HVACTypeHeatPumpAirToAir, HPXML::FuelTypeElectricity, nil, nil, nil, 1.0, 1.0, nil, 0.73, HPXML::FuelTypeElectricity, 1.0, 25.0])
    _check_cooling_system(hpxml_doc)
    _check_heating_system(hpxml_doc)
    _check_thermostat(hpxml_doc, HPXML::HVACControlTypeManual, 68, 78)
  end

  def test_central_air_conditioner
    hpxml_name = 'base-hvac-central-ac-only-1-speed.xml'

    # Reference Home, IAD, IAD Reference
    calc_types = [Constants.CalcTypeERIReferenceHome,
                  Constants.CalcTypeERIIndexAdjustmentDesign,
                  Constants.CalcTypeERIIndexAdjustmentReferenceHome]
    calc_types.each do |calc_type|
      hpxml_doc = _test_measure(hpxml_name, calc_type)
      _check_cooling_system(hpxml_doc, [HPXML::HVACTypeCentralAirConditioner, HPXML::FuelTypeElectricity, HPXML::HVACCompressorTypeSingleStage, 13, 1.0, _dse(calc_type), 0.73])
      _check_heating_system(hpxml_doc, [HPXML::HVACTypeFurnace, HPXML::FuelTypeNaturalGas, 0.78, 1.0, _dse(calc_type)])
      _check_heat_pump(hpxml_doc)
      _check_thermostat(hpxml_doc, HPXML::HVACControlTypeManual, 68, 78)
    end

    # Rated Home
    calc_type = Constants.CalcTypeERIRatedHome
    hpxml_doc = _test_measure(hpxml_name, calc_type)
    _check_cooling_system(hpxml_doc, [HPXML::HVACTypeCentralAirConditioner, HPXML::FuelTypeElectricity, nil, nil, 1.0, nil, 0.73])
    _check_heating_system(hpxml_doc, [HPXML::HVACTypeFurnace, HPXML::FuelTypeNaturalGas, 0.78, 1.0, _dse(calc_type)])
    _check_heat_pump(hpxml_doc)
    _check_thermostat(hpxml_doc, HPXML::HVACControlTypeManual, 68, 78)
  end

  def test_room_air_conditioner
    hpxml_name = 'base-hvac-room-ac-only.xml'

    # Reference Home, IAD, IAD Reference
    calc_types = [Constants.CalcTypeERIReferenceHome,
                  Constants.CalcTypeERIIndexAdjustmentDesign,
                  Constants.CalcTypeERIIndexAdjustmentReferenceHome]
    calc_types.each do |calc_type|
      hpxml_doc = _test_measure(hpxml_name, calc_type)
      _check_cooling_system(hpxml_doc, [HPXML::HVACTypeCentralAirConditioner, HPXML::FuelTypeElectricity, HPXML::HVACCompressorTypeSingleStage, 13, 1.0, _dse(calc_type), 0.65])
      _check_heating_system(hpxml_doc, [HPXML::HVACTypeFurnace, HPXML::FuelTypeNaturalGas, 0.78, 1.0, _dse(calc_type)])
      _check_heat_pump(hpxml_doc)
      _check_thermostat(hpxml_doc, HPXML::HVACControlTypeManual, 68, 78)
    end

    # Rated Home
    calc_type = Constants.CalcTypeERIRatedHome
    hpxml_doc = _test_measure(hpxml_name, calc_type)
    _check_cooling_system(hpxml_doc, [HPXML::HVACTypeRoomAirConditioner, HPXML::FuelTypeElectricity, nil, nil, 1.0, nil, 0.65])
    _check_heating_system(hpxml_doc, [HPXML::HVACTypeFurnace, HPXML::FuelTypeNaturalGas, 0.78, 1.0, _dse(calc_type)])
    _check_heat_pump(hpxml_doc)
    _check_thermostat(hpxml_doc, HPXML::HVACControlTypeManual, 68, 78)
  end

  def test_evaporative_cooler
    hpxml_name = 'base-hvac-evap-cooler-only.xml'

    # Reference Home, IAD, IAD Reference
    calc_types = [Constants.CalcTypeERIReferenceHome,
                  Constants.CalcTypeERIIndexAdjustmentDesign,
                  Constants.CalcTypeERIIndexAdjustmentReferenceHome]
    calc_types.each do |calc_type|
      hpxml_doc = _test_measure(hpxml_name, calc_type)
      _check_cooling_system(hpxml_doc, [HPXML::HVACTypeCentralAirConditioner, HPXML::FuelTypeElectricity, HPXML::HVACCompressorTypeSingleStage, 13, 1.0, _dse(calc_type), nil])
      _check_heating_system(hpxml_doc, [HPXML::HVACTypeFurnace, HPXML::FuelTypeNaturalGas, 0.78, 1.0, _dse(calc_type)])
      _check_heat_pump(hpxml_doc)
      _check_thermostat(hpxml_doc, HPXML::HVACControlTypeManual, 68, 78)
    end

    # Rated Home
    calc_type = Constants.CalcTypeERIRatedHome
    hpxml_doc = _test_measure(hpxml_name, calc_type)
    _check_cooling_system(hpxml_doc, [HPXML::HVACTypeEvaporativeCooler, HPXML::FuelTypeElectricity, nil, nil, 1.0, nil, nil])
    _check_heating_system(hpxml_doc, [HPXML::HVACTypeFurnace, HPXML::FuelTypeNaturalGas, 0.78, 1.0, _dse(calc_type)])
    _check_heat_pump(hpxml_doc)
    _check_thermostat(hpxml_doc, HPXML::HVACControlTypeManual, 68, 78)
  end

  def test_furnace_gas_and_central_air_conditioner
    hpxml_name = 'base.xml'

    # Reference Home, IAD, IAD Reference
    calc_types = [Constants.CalcTypeERIReferenceHome,
                  Constants.CalcTypeERIIndexAdjustmentDesign,
                  Constants.CalcTypeERIIndexAdjustmentReferenceHome]
    calc_types.each do |calc_type|
      hpxml_doc = _test_measure(hpxml_name, calc_type)
      _check_cooling_system(hpxml_doc, [HPXML::HVACTypeCentralAirConditioner, HPXML::FuelTypeElectricity, HPXML::HVACCompressorTypeSingleStage, 13, 1.0, _dse(calc_type), 0.73])
      _check_heating_system(hpxml_doc, [HPXML::HVACTypeFurnace, HPXML::FuelTypeNaturalGas, 0.78, 1.0, _dse(calc_type)])
      _check_heat_pump(hpxml_doc)
      _check_thermostat(hpxml_doc, HPXML::HVACControlTypeManual, 68, 78)
    end

    # Rated Home
    calc_type = Constants.CalcTypeERIRatedHome
    hpxml_doc = _test_measure(hpxml_name, calc_type)
    _check_cooling_system(hpxml_doc, [HPXML::HVACTypeCentralAirConditioner, HPXML::FuelTypeElectricity, nil, nil, 1.0, nil, 0.73])
    _check_heating_system(hpxml_doc, [HPXML::HVACTypeFurnace, HPXML::FuelTypeNaturalGas, nil, 1.0, nil])
    _check_heat_pump(hpxml_doc)
    _check_thermostat(hpxml_doc, HPXML::HVACControlTypeManual, 68, 78)
  end

  def test_furnace_gas_room_air_conditioner
    hpxml_name = 'base-hvac-furnace-gas-room-ac.xml'

    # Reference Home, IAD, IAD Reference
    calc_types = [Constants.CalcTypeERIReferenceHome,
                  Constants.CalcTypeERIIndexAdjustmentDesign,
                  Constants.CalcTypeERIIndexAdjustmentReferenceHome]
    calc_types.each do |calc_type|
      hpxml_doc = _test_measure(hpxml_name, calc_type)
      _check_cooling_system(hpxml_doc, [HPXML::HVACTypeCentralAirConditioner, HPXML::FuelTypeElectricity, HPXML::HVACCompressorTypeSingleStage, 13, 1.0, _dse(calc_type), 0.65])
      _check_heating_system(hpxml_doc, [HPXML::HVACTypeFurnace, HPXML::FuelTypeNaturalGas, 0.78, 1.0, _dse(calc_type)])
      _check_heat_pump(hpxml_doc)
      _check_thermostat(hpxml_doc, HPXML::HVACControlTypeManual, 68, 78)
    end

    # Rated Home
    calc_type = Constants.CalcTypeERIRatedHome
    hpxml_doc = _test_measure(hpxml_name, calc_type)
    _check_cooling_system(hpxml_doc, [HPXML::HVACTypeRoomAirConditioner, HPXML::FuelTypeElectricity, nil, nil, 1.0, nil, 0.65])
    _check_heating_system(hpxml_doc, [HPXML::HVACTypeFurnace, HPXML::FuelTypeNaturalGas, nil, 1.0, nil])
    _check_heat_pump(hpxml_doc)
    _check_thermostat(hpxml_doc, HPXML::HVACControlTypeManual, 68, 78)
  end

  def test_multiple_hvac
    hpxml_name = 'base-hvac-multiple.xml'

    # Reference Home, IAD, IAD Reference
    calc_types = [Constants.CalcTypeERIReferenceHome,
                  Constants.CalcTypeERIIndexAdjustmentDesign,
                  Constants.CalcTypeERIIndexAdjustmentReferenceHome]
    calc_types.each do |calc_type|
      hpxml_doc = _test_measure(hpxml_name, calc_type)
      _check_cooling_system(hpxml_doc, [HPXML::HVACTypeCentralAirConditioner, HPXML::FuelTypeElectricity, HPXML::HVACCompressorTypeSingleStage, 13, 0.2, _dse(calc_type), 0.73],
                            [HPXML::HVACTypeCentralAirConditioner, HPXML::FuelTypeElectricity, HPXML::HVACCompressorTypeSingleStage, 13, 0.2, _dse(calc_type), 0.65],
                            [HPXML::HVACTypeCentralAirConditioner, HPXML::FuelTypeElectricity, HPXML::HVACCompressorTypeSingleStage, 13, 0.2, _dse(calc_type), 0.73],
                            [HPXML::HVACTypeCentralAirConditioner, HPXML::FuelTypeElectricity, HPXML::HVACCompressorTypeSingleStage, 13, 0.2, _dse(calc_type), 0.73],
                            [HPXML::HVACTypeCentralAirConditioner, HPXML::FuelTypeElectricity, HPXML::HVACCompressorTypeSingleStage, 13, 0.2, _dse(calc_type), 0.73])
      _check_heating_system(hpxml_doc, [HPXML::HVACTypeBoiler, HPXML::FuelTypeNaturalGas, 0.8, 0.1, _dse(calc_type)],
                            [HPXML::HVACTypeFurnace, HPXML::FuelTypeNaturalGas, 0.78, 0.1, _dse(calc_type)],
                            [HPXML::HVACTypeFurnace, HPXML::FuelTypeNaturalGas, 0.78, 0.1, _dse(calc_type)],
                            [HPXML::HVACTypeFurnace, HPXML::FuelTypeNaturalGas, 0.78, 0.1, _dse(calc_type)])
      _check_heat_pump(hpxml_doc, [HPXML::HVACTypeHeatPumpAirToAir, HPXML::FuelTypeElectricity, HPXML::HVACCompressorTypeSingleStage, 7.7, nil, 0.1, 0.0, _dse(calc_type), nil, HPXML::FuelTypeElectricity, 1.0, nil],
                       [HPXML::HVACTypeHeatPumpAirToAir, HPXML::FuelTypeElectricity, HPXML::HVACCompressorTypeSingleStage, 7.7, nil, 0.1, 0.0, _dse(calc_type), nil, HPXML::FuelTypeElectricity, 1.0, nil],
                       [HPXML::HVACTypeHeatPumpAirToAir, HPXML::FuelTypeElectricity, HPXML::HVACCompressorTypeSingleStage, 7.7, nil, 0.1, 0.0, _dse(calc_type), nil, HPXML::FuelTypeElectricity, 1.0, nil],
                       [HPXML::HVACTypeHeatPumpAirToAir, HPXML::FuelTypeElectricity, HPXML::HVACCompressorTypeSingleStage, 7.7, nil, 0.1, 0.0, _dse(calc_type), nil, HPXML::FuelTypeElectricity, 1.0, nil],
                       [HPXML::HVACTypeHeatPumpAirToAir, HPXML::FuelTypeElectricity, HPXML::HVACCompressorTypeSingleStage, 7.7, nil, 0.1, 0.0, _dse(calc_type), nil, HPXML::FuelTypeElectricity, 1.0, nil],
                       [HPXML::HVACTypeHeatPumpAirToAir, HPXML::FuelTypeElectricity, HPXML::HVACCompressorTypeSingleStage, 7.7, nil, 0.1, 0.0, _dse(calc_type), nil, HPXML::FuelTypeElectricity, 1.0, nil])
      _check_thermostat(hpxml_doc, HPXML::HVACControlTypeManual, 68, 78)
    end

    # Rated Home
    calc_type = Constants.CalcTypeERIRatedHome
    hpxml_doc = _test_measure(hpxml_name, calc_type)
    _check_cooling_system(hpxml_doc, [HPXML::HVACTypeCentralAirConditioner, HPXML::FuelTypeElectricity, nil, nil, 0.2, nil, 0.73],
                          [HPXML::HVACTypeRoomAirConditioner, HPXML::FuelTypeElectricity, nil, nil, 0.2, nil, 0.65])
    _check_heating_system(hpxml_doc, [HPXML::HVACTypeBoiler, HPXML::FuelTypeElectricity, nil, 0.1, nil],
                          [HPXML::HVACTypeBoiler, HPXML::FuelTypeNaturalGas, nil, 0.1, nil],
                          [HPXML::HVACTypeElectricResistance, HPXML::FuelTypeElectricity, nil, 0.1, nil],
                          [HPXML::HVACTypeFurnace, HPXML::FuelTypeElectricity, nil, 0.1, nil],
                          [HPXML::HVACTypeFurnace, HPXML::FuelTypeNaturalGas, nil, 0.1, nil],
                          [HPXML::HVACTypeStove, HPXML::FuelTypeOil, nil, 0.1, nil],
                          [HPXML::HVACTypeWallFurnace, HPXML::FuelTypePropane, nil, 0.1, nil])
    _check_heat_pump(hpxml_doc, [HPXML::HVACTypeHeatPumpAirToAir, HPXML::FuelTypeElectricity, nil, nil, nil, 0.1, 0.2, nil, 0.73, HPXML::FuelTypeElectricity, 1.0, nil],
                     [HPXML::HVACTypeHeatPumpGroundToAir, HPXML::FuelTypeElectricity, nil, nil, nil, 0.1, 0.2, nil, 0.73, HPXML::FuelTypeElectricity, 1.0, nil],
                     [HPXML::HVACTypeHeatPumpMiniSplit, HPXML::FuelTypeElectricity, nil, nil, nil, 0.1, 0.2, nil, 0.73, HPXML::FuelTypeElectricity, 1.0, nil])
    _check_thermostat(hpxml_doc, HPXML::HVACControlTypeManual, 68, 78)
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
      hpxml_doc = _test_measure(hpxml_name, calc_type)
      _check_cooling_system(hpxml_doc, [HPXML::HVACTypeCentralAirConditioner, HPXML::FuelTypeElectricity, HPXML::HVACCompressorTypeSingleStage, 13, 0.3, _dse(calc_type), 0.73],
                            [HPXML::HVACTypeCentralAirConditioner, HPXML::FuelTypeElectricity, HPXML::HVACCompressorTypeSingleStage, 13, 0.7, _dse(calc_type), nil])
      _check_heating_system(hpxml_doc, [HPXML::HVACTypeFurnace, HPXML::FuelTypeNaturalGas, 0.78, 0.2, _dse(calc_type)],
                            [HPXML::HVACTypeFurnace, HPXML::FuelTypeNaturalGas, 0.78, 0.8, _dse(calc_type)])
      _check_heat_pump(hpxml_doc)
      _check_thermostat(hpxml_doc, HPXML::HVACControlTypeManual, 68, 78)
    end

    # Rated Home
    calc_type = Constants.CalcTypeERIRatedHome
    hpxml_doc = _test_measure(hpxml_name, calc_type)
    _check_cooling_system(hpxml_doc, [HPXML::HVACTypeCentralAirConditioner, HPXML::FuelTypeElectricity, nil, nil, 0.3, nil, 0.73],
                          [HPXML::HVACTypeCentralAirConditioner, HPXML::FuelTypeElectricity, HPXML::HVACCompressorTypeSingleStage, 13, 0.7, _dse(calc_type), nil])
    _check_heating_system(hpxml_doc, [HPXML::HVACTypeFurnace, HPXML::FuelTypeNaturalGas, nil, 0.2, nil],
                          [HPXML::HVACTypeFurnace, HPXML::FuelTypeNaturalGas, 0.78, 0.8, _dse(calc_type)])
    _check_heat_pump(hpxml_doc)
    _check_thermostat(hpxml_doc, HPXML::HVACControlTypeManual, 68, 78)
  end

  def test_programmable_thermostat
    hpxml_name = 'base-hvac-programmable-thermostat.xml'

    # Reference Home, IAD, IAD Reference
    calc_types = [Constants.CalcTypeERIReferenceHome,
                  Constants.CalcTypeERIIndexAdjustmentDesign,
                  Constants.CalcTypeERIIndexAdjustmentReferenceHome]
    calc_types.each do |calc_type|
      hpxml_doc = _test_measure(hpxml_name, calc_type)
      _check_thermostat(hpxml_doc, HPXML::HVACControlTypeManual, 68, 78)
    end

    # Rated Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_thermostat(hpxml_doc, HPXML::HVACControlTypeProgrammable, 68, 78, 66, 7 * 7, 23, 80, 6 * 7, 9)
  end

  def test_ceiling_fan
    hpxml_name = 'base-misc-ceiling-fans.xml'

    # Rated Home, Reference Home, IAD, IAD Reference
    calc_types = [Constants.CalcTypeERIRatedHome,
                  Constants.CalcTypeERIReferenceHome,
                  Constants.CalcTypeERIIndexAdjustmentDesign,
                  Constants.CalcTypeERIIndexAdjustmentReferenceHome]
    calc_types.each do |calc_type|
      hpxml_doc = _test_measure(hpxml_name, calc_type)
      _check_thermostat(hpxml_doc, HPXML::HVACControlTypeManual, 68, 78, nil, nil, nil, nil, nil, nil, 0.5)
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
      hpxml_doc = _test_measure(hpxml_name, calc_type)
      _check_thermostat(hpxml_doc, HPXML::HVACControlTypeManual, 68, 78)
    end
  end

  def test_dse
    hpxml_name = 'base-hvac-dse.xml'

    # Reference Home, IAD, IAD Reference
    calc_types = [Constants.CalcTypeERIReferenceHome,
                  Constants.CalcTypeERIIndexAdjustmentDesign,
                  Constants.CalcTypeERIIndexAdjustmentReferenceHome]
    calc_types.each do |calc_type|
      hpxml_doc = _test_measure(hpxml_name, calc_type)
      _check_cooling_system(hpxml_doc, [HPXML::HVACTypeCentralAirConditioner, HPXML::FuelTypeElectricity, HPXML::HVACCompressorTypeSingleStage, 13, 1.0, _dse(calc_type), 0.73])
      _check_heating_system(hpxml_doc, [HPXML::HVACTypeFurnace, HPXML::FuelTypeNaturalGas, 0.78, 1.0, _dse(calc_type)])
      _check_heat_pump(hpxml_doc)
      _check_thermostat(hpxml_doc, HPXML::HVACControlTypeManual, 68, 78)
    end

    # Rated Home
    calc_type = Constants.CalcTypeERIRatedHome
    hpxml_doc = _test_measure(hpxml_name, calc_type)
    _check_cooling_system(hpxml_doc, [HPXML::HVACTypeCentralAirConditioner, HPXML::FuelTypeElectricity, nil, nil, 1.0, 0.7, 0.73])
    _check_heating_system(hpxml_doc, [HPXML::HVACTypeFurnace, HPXML::FuelTypeNaturalGas, nil, 1.0, 0.8])
    _check_heat_pump(hpxml_doc)
    _check_thermostat(hpxml_doc, HPXML::HVACControlTypeManual, 68, 78)
  end

  def _test_measure(hpxml_name, calc_type)
    args_hash = {}
    args_hash['hpxml_input_path'] = File.join(@root_path, 'workflow', 'sample_files', hpxml_name)
    args_hash['hpxml_output_path'] = File.join(File.dirname(__FILE__), "#{calc_type}.xml")
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
    assert(File.exist? args_hash['hpxml_output_path'])

    hpxml_doc = REXML::Document.new(File.read(args_hash['hpxml_output_path']))
    File.delete(args_hash['hpxml_output_path'])

    return hpxml_doc
  end

  def _check_heating_system(hpxml_doc, *systems)
    assert_equal(systems.size, hpxml_doc.elements['count(/HPXML/Building/BuildingDetails/Systems/HVAC/HVACPlant/HeatingSystem)'])
    hpxml_doc.elements.each_with_index('/HPXML/Building/BuildingDetails/Systems/HVAC/HVACPlant/HeatingSystem') do |sys, idx|
      systype, fueltype, afue, frac_load, dse = systems[idx]
      refute_nil(sys.elements["HeatingSystemType/#{systype}"])
      assert_equal(sys.elements['HeatingSystemFuel'].text, fueltype)
      if not afue.nil?
        assert_equal(Float(sys.elements["AnnualHeatingEfficiency[Units='AFUE']/Value"].text), afue)
      end
      assert_equal(Float(sys.elements['FractionHeatLoadServed'].text), frac_load)
      _check_dse_heat(hpxml_doc, sys, dse)
    end
  end

  def _check_heat_pump(hpxml_doc, *systems)
    assert_equal(systems.size, hpxml_doc.elements['count(/HPXML/Building/BuildingDetails/Systems/HVAC/HVACPlant/HeatPump)'])
    hpxml_doc.elements.each_with_index('/HPXML/Building/BuildingDetails/Systems/HVAC/HVACPlant/HeatPump') do |sys, idx|
      systype, fueltype, comptype, hspf, seer, frac_load_heat, frac_load_cool, dse, shr, backup_fuel, backup_eff, backup_temp = systems[idx]
      assert_equal(sys.elements['HeatPumpType'].text, systype)
      assert_equal(sys.elements['HeatPumpFuel'].text, fueltype)
      if not comptype.nil?
        assert_equal(sys.elements['CompressorType'].text, comptype)
      end
      if not hspf.nil?
        assert_equal(Float(sys.elements["AnnualHeatingEfficiency[Units='HSPF']/Value"].text), hspf)
      end
      if not seer.nil?
        assert_equal(Float(sys.elements["AnnualCoolingEfficiency[Units='SEER']/Value"].text), seer)
      end
      assert_equal(Float(sys.elements['FractionHeatLoadServed'].text), frac_load_heat)
      assert_equal(Float(sys.elements['FractionCoolLoadServed'].text), frac_load_cool)
      _check_dse_heat(hpxml_doc, sys, dse)
      _check_dse_cool(hpxml_doc, sys, dse)
      if shr.nil?
        assert(sys.elements['CoolingSensibleHeatFraction'].nil?)
      else
        assert_equal(Float(sys.elements['CoolingSensibleHeatFraction'].text), shr)
      end
      if backup_fuel.nil?
        assert(sys.elements['BackupSystemFuel'].nil?)
      else
        assert_equal(sys.elements['BackupSystemFuel'].text, backup_fuel)
      end
      if backup_eff.nil?
        assert(sys.elements['BackupAnnualHeatingEfficiency'].nil?)
      else
        assert_equal(Float(sys.elements['BackupAnnualHeatingEfficiency/Value'].text), backup_eff)
      end
      if backup_temp.nil?
        assert(sys.elements['BackupHeatingSwitchoverTemperature'].nil?)
      else
        assert_equal(Float(sys.elements['BackupHeatingSwitchoverTemperature'].text), backup_temp)
      end
    end
  end

  def _check_cooling_system(hpxml_doc, *systems)
    assert_equal(systems.size, hpxml_doc.elements['count(/HPXML/Building/BuildingDetails/Systems/HVAC/HVACPlant/CoolingSystem)'])
    hpxml_doc.elements.each_with_index('/HPXML/Building/BuildingDetails/Systems/HVAC/HVACPlant/CoolingSystem') do |sys, idx|
      systype, fueltype, comptype, seer, frac_load, dse, shr = systems[idx]
      assert_equal(sys.elements['CoolingSystemType'].text, systype)
      assert_equal(sys.elements['CoolingSystemFuel'].text, fueltype)
      if not comptype.nil?
        assert_equal(sys.elements['CompressorType'].text, comptype)
      end
      if not seer.nil?
        assert_equal(Float(sys.elements["AnnualCoolingEfficiency[Units='SEER']/Value"].text), seer)
      end
      assert_equal(Float(sys.elements['FractionCoolLoadServed'].text), frac_load)
      _check_dse_cool(hpxml_doc, sys, dse)
      if shr.nil?
        assert(sys.elements['SensibleHeatFraction'].nil?)
      else
        assert_equal(Float(sys.elements['SensibleHeatFraction'].text), shr)
      end
    end
  end

  def _check_thermostat(hpxml_doc, control_type, htg_sp, clg_sp, htg_setback = nil, htg_setback_hrs = nil, htg_setback_start_hr = nil,
                        clg_setup = nil, clg_setup_hrs = nil, clg_setup_start_hr = nil, ceiling_fan_offset = nil)
    tstat = hpxml_doc.elements['/HPXML/Building/BuildingDetails/Systems/HVAC/HVACControl']
    assert_equal(tstat.elements['ControlType'].text, control_type)

    assert_equal(Float(tstat.elements['SetpointTempHeatingSeason'].text), htg_sp)
    if htg_setback.nil?
      assert_nil(tstat.elements['SetbackTempHeatingSeason'])
    else
      assert_equal(Float(tstat.elements['SetbackTempHeatingSeason'].text), htg_setback)
    end
    if htg_setback_hrs.nil?
      assert_nil(tstat.elements['TotalSetbackHoursperWeekHeating'])
    else
      assert_equal(Integer(tstat.elements['TotalSetbackHoursperWeekHeating'].text), htg_setback_hrs)
    end
    if htg_setback_start_hr.nil?
      assert_nil(tstat.elements['extension/SetbackStartHourHeating'])
    else
      assert_equal(Integer(tstat.elements['extension/SetbackStartHourHeating'].text), htg_setback_start_hr)
    end

    assert_equal(Float(tstat.elements['SetpointTempCoolingSeason'].text), clg_sp)
    if clg_setup.nil?
      assert_nil(tstat.elements['SetupTempCoolingSeason'])
    else
      assert_equal(Float(tstat.elements['SetupTempCoolingSeason'].text), clg_setup)
    end
    if clg_setup_hrs.nil?
      assert_nil(tstat.elements['TotalSetupHoursperWeekCooling'])
    else
      assert_equal(Integer(tstat.elements['TotalSetupHoursperWeekCooling'].text), clg_setup_hrs)
    end
    if clg_setup_start_hr.nil?
      assert_nil(tstat.elements['extension/SetupStartHourCooling'])
    else
      assert_equal(Integer(tstat.elements['extension/SetupStartHourCooling'].text), clg_setup_start_hr)
    end

    if ceiling_fan_offset.nil?
      assert_nil(tstat.elements['extension/CeilingFanSetpointTempCoolingSeasonOffset'])
    else
      assert_equal(Float(tstat.elements['extension/CeilingFanSetpointTempCoolingSeasonOffset'].text), ceiling_fan_offset)
    end
  end

  def _check_dse_heat(hpxml_doc, sys, dse)
    actual_dse = nil
    hpxml_doc.elements.each("/HPXML/Building/BuildingDetails/Systems/HVAC/HVACDistribution[DistributionSystemType[Other='DSE']]") do |dist_dse|
      next if sys.elements['DistributionSystem'].nil?
      next unless dist_dse.elements['SystemIdentifier'].attributes['id'] == sys.elements['DistributionSystem'].attributes['idref']

      actual_dse = Float(dist_dse.elements['AnnualHeatingDistributionSystemEfficiency'].text)
    end
    if dse.nil?
      assert_nil(actual_dse)
    else
      assert_equal(dse, actual_dse)
    end
  end

  def _check_dse_cool(hpxml_doc, sys, dse)
    actual_dse = nil
    hpxml_doc.elements.each("/HPXML/Building/BuildingDetails/Systems/HVAC/HVACDistribution[DistributionSystemType[Other='DSE']]") do |dist_dse|
      next if sys.elements['DistributionSystem'].nil?
      next unless dist_dse.elements['SystemIdentifier'].attributes['id'] == sys.elements['DistributionSystem'].attributes['idref']

      actual_dse = Float(dist_dse.elements['AnnualCoolingDistributionSystemEfficiency'].text)
    end
    if dse.nil?
      assert_nil(actual_dse)
    else
      assert_equal(dse, actual_dse)
    end
  end
end
