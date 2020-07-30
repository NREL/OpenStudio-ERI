# frozen_string_literal: true

require_relative '../../../workflow/tests/minitest_helper'
require 'openstudio'
require 'openstudio/ruleset/ShowRunnerOutput'
require 'minitest/autorun'
require_relative '../measure.rb'
require 'fileutils'
require_relative 'util.rb'

class ERIWaterHeatingTest < MiniTest::Test
  def before_setup
    @root_path = File.absolute_path(File.join(File.dirname(__FILE__), '..', '..', '..'))
  end

  def test_water_heating
    hpxml_name = 'base.xml'

    # Reference Home
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_water_heater(hpxml, [HPXML::WaterHeaterTypeStorage, HPXML::FuelTypeElectricity, 125.0, HPXML::LocationLivingSpace, 40, 0.9172, 1])
    _check_hot_water_distribution(hpxml, HPXML::DHWDistTypeStandard, 0.0, 93.5, nil, nil, nil, nil)
    _check_water_fixtures(hpxml, false, false)
    _check_drain_water_heat_recovery(hpxml, nil, nil, nil)

    # Rated Home
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_water_heater(hpxml, [HPXML::WaterHeaterTypeStorage, HPXML::FuelTypeElectricity, 125.0, HPXML::LocationLivingSpace, 40, 0.95, 1])
    _check_hot_water_distribution(hpxml, HPXML::DHWDistTypeStandard, 0.0, 50, nil, nil, nil, nil)
    _check_water_fixtures(hpxml, true, false)
    _check_drain_water_heat_recovery(hpxml, nil, nil, nil)

    # IAD, IAD Reference
    calc_types = [Constants.CalcTypeERIIndexAdjustmentDesign,
                  Constants.CalcTypeERIIndexAdjustmentReferenceHome]
    calc_types.each do |calc_type|
      hpxml = _test_measure(hpxml_name, calc_type)
      _check_water_heater(hpxml, [HPXML::WaterHeaterTypeStorage, HPXML::FuelTypeElectricity, 125.0, HPXML::LocationLivingSpace, 40, 0.9172, 1])
      _check_hot_water_distribution(hpxml, HPXML::DHWDistTypeStandard, 0.0, 89.28, nil, nil, nil, nil)
      _check_water_fixtures(hpxml, false, false)
      _check_drain_water_heat_recovery(hpxml, nil, nil, nil)
    end
  end

  def test_water_heating_dwhr
    hpxml_name = 'base-dhw-dwhr.xml'

    # Reference Home
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_water_heater(hpxml, [HPXML::WaterHeaterTypeStorage, HPXML::FuelTypeElectricity, 125.0, HPXML::LocationLivingSpace, 40, 0.9172, 1])
    _check_hot_water_distribution(hpxml, HPXML::DHWDistTypeStandard, 0.0, 93.5, nil, nil, nil, nil)
    _check_water_fixtures(hpxml, false, false)
    _check_drain_water_heat_recovery(hpxml, nil, nil, nil)

    # Rated Home
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_water_heater(hpxml, [HPXML::WaterHeaterTypeStorage, HPXML::FuelTypeElectricity, 125.0, HPXML::LocationLivingSpace, 40, 0.95, 1])
    _check_hot_water_distribution(hpxml, HPXML::DHWDistTypeStandard, 0.0, 50, nil, nil, nil, nil)
    _check_water_fixtures(hpxml, true, false)
    _check_drain_water_heat_recovery(hpxml, HPXML::DWHRFacilitiesConnectedAll, true, 0.55)

    # IAD, IAD Reference
    calc_types = [Constants.CalcTypeERIIndexAdjustmentDesign,
                  Constants.CalcTypeERIIndexAdjustmentReferenceHome]
    calc_types.each do |calc_type|
      hpxml = _test_measure(hpxml_name, calc_type)
      _check_water_heater(hpxml, [HPXML::WaterHeaterTypeStorage, HPXML::FuelTypeElectricity, 125.0, HPXML::LocationLivingSpace, 40, 0.9172, 1])
      _check_hot_water_distribution(hpxml, HPXML::DHWDistTypeStandard, 0.0, 89.28, nil, nil, nil, nil)
      _check_water_fixtures(hpxml, false, false)
      _check_drain_water_heat_recovery(hpxml, nil, nil, nil)
    end
  end

  def test_desuperheater
    hpxml_name = 'base-dhw-desuperheater.xml'

    # Reference Home, IAD, IAD Reference
    calc_types = [Constants.CalcTypeERIReferenceHome,
                  Constants.CalcTypeERIIndexAdjustmentDesign,
                  Constants.CalcTypeERIIndexAdjustmentReferenceHome]
    calc_types.each do |calc_type|
      hpxml = _test_measure(hpxml_name, calc_type)
      _check_desuperheater(hpxml, false)
    end

    # Rated Home
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_desuperheater(hpxml, true)
  end

  def test_water_heating_location_basement
    hpxml_name = 'base-foundation-unconditioned-basement.xml'

    # Reference Home
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_water_heater(hpxml, [HPXML::WaterHeaterTypeStorage, HPXML::FuelTypeElectricity, 125.0, HPXML::LocationBasementUnconditioned, 40, 0.9172, 1])
    _check_hot_water_distribution(hpxml, HPXML::DHWDistTypeStandard, 0.0, 88.5, nil, nil, nil, nil)
    _check_water_fixtures(hpxml, false, false)
    _check_drain_water_heat_recovery(hpxml, nil, nil, nil)

    # Rated Home
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_water_heater(hpxml, [HPXML::WaterHeaterTypeStorage, HPXML::FuelTypeElectricity, 125.0, HPXML::LocationBasementUnconditioned, 40, 0.95, 1])
    _check_hot_water_distribution(hpxml, HPXML::DHWDistTypeStandard, 0.0, 50, nil, nil, nil, nil)
    _check_water_fixtures(hpxml, true, false)
    _check_drain_water_heat_recovery(hpxml, nil, nil, nil)

    # IAD, IAD Reference
    calc_types = [Constants.CalcTypeERIIndexAdjustmentDesign,
                  Constants.CalcTypeERIIndexAdjustmentReferenceHome]
    calc_types.each do |calc_type|
      hpxml = _test_measure(hpxml_name, calc_type)
      _check_water_heater(hpxml, [HPXML::WaterHeaterTypeStorage, HPXML::FuelTypeElectricity, 125.0, HPXML::LocationLivingSpace, 40, 0.9172, 1])
      _check_hot_water_distribution(hpxml, HPXML::DHWDistTypeStandard, 0.0, 89.28, nil, nil, nil, nil)
      _check_water_fixtures(hpxml, false, false)
      _check_drain_water_heat_recovery(hpxml, nil, nil, nil)
    end
  end

  def test_water_heating_low_flow_fixtures
    hpxml_name = 'base-dhw-low-flow-fixtures.xml'

    # Reference Home
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_water_heater(hpxml, [HPXML::WaterHeaterTypeStorage, HPXML::FuelTypeElectricity, 125.0, HPXML::LocationLivingSpace, 40, 0.9172, 1])
    _check_hot_water_distribution(hpxml, HPXML::DHWDistTypeStandard, 0.0, 93.5, nil, nil, nil, nil)
    _check_water_fixtures(hpxml, false, false)
    _check_drain_water_heat_recovery(hpxml, nil, nil, nil)

    # Rated Home
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_water_heater(hpxml, [HPXML::WaterHeaterTypeStorage, HPXML::FuelTypeElectricity, 125.0, HPXML::LocationLivingSpace, 40, 0.95, 1])
    _check_hot_water_distribution(hpxml, HPXML::DHWDistTypeStandard, 0.0, 50, nil, nil, nil, nil)
    _check_water_fixtures(hpxml, true, true)
    _check_drain_water_heat_recovery(hpxml, nil, nil, nil)

    # IAD, IAD Reference
    calc_types = [Constants.CalcTypeERIIndexAdjustmentDesign,
                  Constants.CalcTypeERIIndexAdjustmentReferenceHome]
    calc_types.each do |calc_type|
      hpxml = _test_measure(hpxml_name, calc_type)
      _check_water_heater(hpxml, [HPXML::WaterHeaterTypeStorage, HPXML::FuelTypeElectricity, 125.0, HPXML::LocationLivingSpace, 40, 0.9172, 1])
      _check_hot_water_distribution(hpxml, HPXML::DHWDistTypeStandard, 0.0, 89.28, nil, nil, nil, nil)
      _check_water_fixtures(hpxml, false, false)
      _check_drain_water_heat_recovery(hpxml, nil, nil, nil)
    end
  end

  def test_water_heating_recirc_demand
    hpxml_name = 'base-dhw-recirc-demand.xml'

    # Reference Home
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_water_heater(hpxml, [HPXML::WaterHeaterTypeStorage, HPXML::FuelTypeElectricity, 125.0, HPXML::LocationLivingSpace, 40, 0.9172, 1])
    _check_hot_water_distribution(hpxml, HPXML::DHWDistTypeStandard, 0.0, 93.5, nil, nil, nil, nil)
    _check_water_fixtures(hpxml, false, false)
    _check_drain_water_heat_recovery(hpxml, nil, nil, nil)

    # Rated Home
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_water_heater(hpxml, [HPXML::WaterHeaterTypeStorage, HPXML::FuelTypeElectricity, 125.0, HPXML::LocationLivingSpace, 40, 0.95, 1])
    _check_hot_water_distribution(hpxml, HPXML::DHWDistTypeRecirc, 3.0, nil, HPXML::DHWRecirControlTypeSensor, 50, 50, 50)
    _check_water_fixtures(hpxml, true, false)
    _check_drain_water_heat_recovery(hpxml, nil, nil, nil)

    # IAD, IAD Reference
    calc_types = [Constants.CalcTypeERIIndexAdjustmentDesign,
                  Constants.CalcTypeERIIndexAdjustmentReferenceHome]
    calc_types.each do |calc_type|
      hpxml = _test_measure(hpxml_name, calc_type)
      _check_water_heater(hpxml, [HPXML::WaterHeaterTypeStorage, HPXML::FuelTypeElectricity, 125.0, HPXML::LocationLivingSpace, 40, 0.9172, 1])
      _check_hot_water_distribution(hpxml, HPXML::DHWDistTypeStandard, 0.0, 89.28, nil, nil, nil, nil)
      _check_water_fixtures(hpxml, false, false)
      _check_drain_water_heat_recovery(hpxml, nil, nil, nil)
    end
  end

  def test_water_heating_recirc_nocontrol
    hpxml_name = 'base-dhw-recirc-nocontrol.xml'

    # Reference Home
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_water_heater(hpxml, [HPXML::WaterHeaterTypeStorage, HPXML::FuelTypeElectricity, 125.0, HPXML::LocationLivingSpace, 40, 0.9172, 1])
    _check_hot_water_distribution(hpxml, HPXML::DHWDistTypeStandard, 0.0, 93.5, nil, nil, nil, nil)
    _check_water_fixtures(hpxml, false, false)
    _check_drain_water_heat_recovery(hpxml, nil, nil, nil)

    # Rated Home
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_water_heater(hpxml, [HPXML::WaterHeaterTypeStorage, HPXML::FuelTypeElectricity, 125.0, HPXML::LocationLivingSpace, 40, 0.95, 1])
    _check_hot_water_distribution(hpxml, HPXML::DHWDistTypeRecirc, 0.0, nil, HPXML::DHWRecirControlTypeNone, 50, 50, 50)
    _check_water_fixtures(hpxml, true, false)
    _check_drain_water_heat_recovery(hpxml, nil, nil, nil)

    # IAD, IAD Reference
    calc_types = [Constants.CalcTypeERIIndexAdjustmentDesign,
                  Constants.CalcTypeERIIndexAdjustmentReferenceHome]
    calc_types.each do |calc_type|
      hpxml = _test_measure(hpxml_name, calc_type)
      _check_water_heater(hpxml, [HPXML::WaterHeaterTypeStorage, HPXML::FuelTypeElectricity, 125.0, HPXML::LocationLivingSpace, 40, 0.9172, 1])
      _check_hot_water_distribution(hpxml, HPXML::DHWDistTypeStandard, 0.0, 89.28, nil, nil, nil, nil)
      _check_water_fixtures(hpxml, false, false)
      _check_drain_water_heat_recovery(hpxml, nil, nil, nil)
    end
  end

  def test_water_heating_recirc_timer
    hpxml_name = 'base-dhw-recirc-timer.xml'

    # Reference Home
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_water_heater(hpxml, [HPXML::WaterHeaterTypeStorage, HPXML::FuelTypeElectricity, 125.0, HPXML::LocationLivingSpace, 40, 0.9172, 1])
    _check_hot_water_distribution(hpxml, HPXML::DHWDistTypeStandard, 0.0, 93.5, nil, nil, nil, nil)
    _check_water_fixtures(hpxml, false, false)
    _check_drain_water_heat_recovery(hpxml, nil, nil, nil)

    # Rated Home
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_water_heater(hpxml, [HPXML::WaterHeaterTypeStorage, HPXML::FuelTypeElectricity, 125.0, HPXML::LocationLivingSpace, 40, 0.95, 1])
    _check_hot_water_distribution(hpxml, HPXML::DHWDistTypeRecirc, 0.0, nil, HPXML::DHWRecirControlTypeTimer, 50, 50, 50)
    _check_water_fixtures(hpxml, true, false)
    _check_drain_water_heat_recovery(hpxml, nil, nil, nil)

    # IAD, IAD Reference
    calc_types = [Constants.CalcTypeERIIndexAdjustmentDesign,
                  Constants.CalcTypeERIIndexAdjustmentReferenceHome]
    calc_types.each do |calc_type|
      hpxml = _test_measure(hpxml_name, calc_type)
      _check_water_heater(hpxml, [HPXML::WaterHeaterTypeStorage, HPXML::FuelTypeElectricity, 125.0, HPXML::LocationLivingSpace, 40, 0.9172, 1])
      _check_hot_water_distribution(hpxml, HPXML::DHWDistTypeStandard, 0.0, 89.28, nil, nil, nil, nil)
      _check_water_fixtures(hpxml, false, false)
      _check_drain_water_heat_recovery(hpxml, nil, nil, nil)
    end
  end

  def test_water_heating_recirc_temperature
    hpxml_name = 'base-dhw-recirc-temperature.xml'

    # Reference Home
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_water_heater(hpxml, [HPXML::WaterHeaterTypeStorage, HPXML::FuelTypeElectricity, 125.0, HPXML::LocationLivingSpace, 40, 0.9172, 1])
    _check_hot_water_distribution(hpxml, HPXML::DHWDistTypeStandard, 0.0, 93.5, nil, nil, nil, nil)
    _check_water_fixtures(hpxml, false, false)
    _check_drain_water_heat_recovery(hpxml, nil, nil, nil)

    # Rated Home
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_water_heater(hpxml, [HPXML::WaterHeaterTypeStorage, HPXML::FuelTypeElectricity, 125.0, HPXML::LocationLivingSpace, 40, 0.95, 1])
    _check_hot_water_distribution(hpxml, HPXML::DHWDistTypeRecirc, 0.0, nil, HPXML::DHWRecirControlTypeTemperature, 50, 50, 50)
    _check_water_fixtures(hpxml, true, false)
    _check_drain_water_heat_recovery(hpxml, nil, nil, nil)

    # IAD, IAD Reference
    calc_types = [Constants.CalcTypeERIIndexAdjustmentDesign,
                  Constants.CalcTypeERIIndexAdjustmentReferenceHome]
    calc_types.each do |calc_type|
      hpxml = _test_measure(hpxml_name, calc_type)
      _check_water_heater(hpxml, [HPXML::WaterHeaterTypeStorage, HPXML::FuelTypeElectricity, 125.0, HPXML::LocationLivingSpace, 40, 0.9172, 1])
      _check_hot_water_distribution(hpxml, HPXML::DHWDistTypeStandard, 0.0, 89.28, nil, nil, nil, nil)
      _check_water_fixtures(hpxml, false, false)
      _check_drain_water_heat_recovery(hpxml, nil, nil, nil)
    end
  end

  def test_water_heating_recirc_manual
    hpxml_name = 'base-dhw-recirc-manual.xml'

    # Reference Home
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_water_heater(hpxml, [HPXML::WaterHeaterTypeStorage, HPXML::FuelTypeElectricity, 125.0, HPXML::LocationLivingSpace, 40, 0.9172, 1])
    _check_hot_water_distribution(hpxml, HPXML::DHWDistTypeStandard, 0.0, 93.5, nil, nil, nil, nil)
    _check_water_fixtures(hpxml, false, false)
    _check_drain_water_heat_recovery(hpxml, nil, nil, nil)

    # Rated Home
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_water_heater(hpxml, [HPXML::WaterHeaterTypeStorage, HPXML::FuelTypeElectricity, 125.0, HPXML::LocationLivingSpace, 40, 0.95, 1])
    _check_hot_water_distribution(hpxml, HPXML::DHWDistTypeRecirc, 3.0, nil, HPXML::DHWRecirControlTypeManual, 50, 50, 50)
    _check_water_fixtures(hpxml, true, false)
    _check_drain_water_heat_recovery(hpxml, nil, nil, nil)

    # IAD, IAD Reference
    calc_types = [Constants.CalcTypeERIIndexAdjustmentDesign,
                  Constants.CalcTypeERIIndexAdjustmentReferenceHome]
    calc_types.each do |calc_type|
      hpxml = _test_measure(hpxml_name, calc_type)
      _check_water_heater(hpxml, [HPXML::WaterHeaterTypeStorage, HPXML::FuelTypeElectricity, 125.0, HPXML::LocationLivingSpace, 40, 0.9172, 1])
      _check_hot_water_distribution(hpxml, HPXML::DHWDistTypeStandard, 0.0, 89.28, nil, nil, nil, nil)
      _check_water_fixtures(hpxml, false, false)
      _check_drain_water_heat_recovery(hpxml, nil, nil, nil)
    end
  end

  def test_water_heating_tank_gas
    hpxml_name = 'base-dhw-tank-gas.xml'

    # Reference Home
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_water_heater(hpxml, [HPXML::WaterHeaterTypeStorage, HPXML::FuelTypeNaturalGas, 125.0, HPXML::LocationLivingSpace, 50, 0.575, 1])
    _check_hot_water_distribution(hpxml, HPXML::DHWDistTypeStandard, 0.0, 93.5, nil, nil, nil, nil)
    _check_water_fixtures(hpxml, false, false)
    _check_drain_water_heat_recovery(hpxml, nil, nil, nil)

    # Rated Home
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_water_heater(hpxml, [HPXML::WaterHeaterTypeStorage, HPXML::FuelTypeNaturalGas, 125.0, HPXML::LocationLivingSpace, 50, 0.59, 1])
    _check_hot_water_distribution(hpxml, HPXML::DHWDistTypeStandard, 0.0, 50, nil, nil, nil, nil)
    _check_water_fixtures(hpxml, true, false)
    _check_drain_water_heat_recovery(hpxml, nil, nil, nil)

    # IAD, IAD Reference
    calc_types = [Constants.CalcTypeERIIndexAdjustmentDesign,
                  Constants.CalcTypeERIIndexAdjustmentReferenceHome]
    calc_types.each do |calc_type|
      hpxml = _test_measure(hpxml_name, calc_type)
      _check_water_heater(hpxml, [HPXML::WaterHeaterTypeStorage, HPXML::FuelTypeNaturalGas, 125.0, HPXML::LocationLivingSpace, 50, 0.575, 1])
      _check_hot_water_distribution(hpxml, HPXML::DHWDistTypeStandard, 0.0, 89.28, nil, nil, nil, nil)
      _check_water_fixtures(hpxml, false, false)
      _check_drain_water_heat_recovery(hpxml, nil, nil, nil)
    end
  end

  def test_water_heating_jacket_insulation
    hpxml_name = 'base-dhw-jacket-gas.xml'

    # Reference Home
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_water_heater(hpxml, [HPXML::WaterHeaterTypeStorage, HPXML::FuelTypeNaturalGas, 125.0, HPXML::LocationLivingSpace, 50, 0.575, 1])
    _check_hot_water_distribution(hpxml, HPXML::DHWDistTypeStandard, 0.0, 93.5, nil, nil, nil, nil)
    _check_water_fixtures(hpxml, false, false)
    _check_drain_water_heat_recovery(hpxml, nil, nil, nil)

    # Rated Home
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_water_heater(hpxml, [HPXML::WaterHeaterTypeStorage, HPXML::FuelTypeNaturalGas, 125.0, HPXML::LocationLivingSpace, 50, 0.59, 1, 10])
    _check_hot_water_distribution(hpxml, HPXML::DHWDistTypeStandard, 0.0, 50, nil, nil, nil, nil)
    _check_water_fixtures(hpxml, true, false)
    _check_drain_water_heat_recovery(hpxml, nil, nil, nil)

    # IAD, IAD Reference
    calc_types = [Constants.CalcTypeERIIndexAdjustmentDesign,
                  Constants.CalcTypeERIIndexAdjustmentReferenceHome]
    calc_types.each do |calc_type|
      hpxml = _test_measure(hpxml_name, calc_type)
      _check_water_heater(hpxml, [HPXML::WaterHeaterTypeStorage, HPXML::FuelTypeNaturalGas, 125.0, HPXML::LocationLivingSpace, 50, 0.575, 1])
      _check_hot_water_distribution(hpxml, HPXML::DHWDistTypeStandard, 0.0, 89.28, nil, nil, nil, nil)
      _check_water_fixtures(hpxml, false, false)
      _check_drain_water_heat_recovery(hpxml, nil, nil, nil)
    end
  end

  def test_water_heating_tank_heat_pump
    hpxml_name = 'base-dhw-tank-heat-pump.xml'

    # Reference Home
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_water_heater(hpxml, [HPXML::WaterHeaterTypeStorage, HPXML::FuelTypeElectricity, 125.0, HPXML::LocationLivingSpace, 80, 0.8644, 1])
    _check_hot_water_distribution(hpxml, HPXML::DHWDistTypeStandard, 0.0, 93.5, nil, nil, nil, nil)
    _check_water_fixtures(hpxml, false, false)
    _check_drain_water_heat_recovery(hpxml, nil, nil, nil)

    # Rated Home
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_water_heater(hpxml, [HPXML::WaterHeaterTypeHeatPump, HPXML::FuelTypeElectricity, 125.0, HPXML::LocationLivingSpace, 80, 2.3, 1])
    _check_hot_water_distribution(hpxml, HPXML::DHWDistTypeStandard, 0.0, 50, nil, nil, nil, nil)
    _check_water_fixtures(hpxml, true, false)
    _check_drain_water_heat_recovery(hpxml, nil, nil, nil)

    # IAD, IAD Reference
    calc_types = [Constants.CalcTypeERIIndexAdjustmentDesign,
                  Constants.CalcTypeERIIndexAdjustmentReferenceHome]
    calc_types.each do |calc_type|
      hpxml = _test_measure(hpxml_name, calc_type)
      _check_water_heater(hpxml, [HPXML::WaterHeaterTypeStorage, HPXML::FuelTypeElectricity, 125.0, HPXML::LocationLivingSpace, 80, 0.8644, 1])
      _check_hot_water_distribution(hpxml, HPXML::DHWDistTypeStandard, 0.0, 89.28, nil, nil, nil, nil)
      _check_water_fixtures(hpxml, false, false)
      _check_drain_water_heat_recovery(hpxml, nil, nil, nil)
    end
  end

  def test_water_heating_tankless_electric
    hpxml_name = 'base-dhw-tankless-electric.xml'

    # Reference Home
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_water_heater(hpxml, [HPXML::WaterHeaterTypeStorage, HPXML::FuelTypeElectricity, 125.0, HPXML::LocationLivingSpace, 40, 0.9172, 1])
    _check_hot_water_distribution(hpxml, HPXML::DHWDistTypeStandard, 0.0, 93.5, nil, nil, nil, nil)
    _check_water_fixtures(hpxml, false, false)
    _check_drain_water_heat_recovery(hpxml, nil, nil, nil)

    # Rated Home
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_water_heater(hpxml, [HPXML::WaterHeaterTypeTankless, HPXML::FuelTypeElectricity, 125.0, HPXML::LocationLivingSpace, nil, 0.99, 1])
    _check_hot_water_distribution(hpxml, HPXML::DHWDistTypeStandard, 0.0, 50, nil, nil, nil, nil)
    _check_water_fixtures(hpxml, true, false)
    _check_drain_water_heat_recovery(hpxml, nil, nil, nil)

    # IAD, IAD Reference
    calc_types = [Constants.CalcTypeERIIndexAdjustmentDesign,
                  Constants.CalcTypeERIIndexAdjustmentReferenceHome]
    calc_types.each do |calc_type|
      hpxml = _test_measure(hpxml_name, calc_type)
      _check_water_heater(hpxml, [HPXML::WaterHeaterTypeStorage, HPXML::FuelTypeElectricity, 125.0, HPXML::LocationLivingSpace, 40, 0.9172, 1])
      _check_hot_water_distribution(hpxml, HPXML::DHWDistTypeStandard, 0.0, 89.28, nil, nil, nil, nil)
      _check_water_fixtures(hpxml, false, false)
      _check_drain_water_heat_recovery(hpxml, nil, nil, nil)
    end
  end

  def test_water_heating_tankless_gas
    hpxml_name = 'base-dhw-tankless-gas.xml'

    # Reference Home
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_water_heater(hpxml, [HPXML::WaterHeaterTypeStorage, HPXML::FuelTypeNaturalGas, 125.0, HPXML::LocationLivingSpace, 40, 0.594, 1])
    _check_hot_water_distribution(hpxml, HPXML::DHWDistTypeStandard, 0.0, 93.5, nil, nil, nil, nil)
    _check_water_fixtures(hpxml, false, false)
    _check_drain_water_heat_recovery(hpxml, nil, nil, nil)

    # Rated Home
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_water_heater(hpxml, [HPXML::WaterHeaterTypeTankless, HPXML::FuelTypeNaturalGas, 125.0, HPXML::LocationLivingSpace, nil, 0.82, 1])
    _check_hot_water_distribution(hpxml, HPXML::DHWDistTypeStandard, 0.0, 50, nil, nil, nil, nil)
    _check_water_fixtures(hpxml, true, false)
    _check_drain_water_heat_recovery(hpxml, nil, nil, nil)

    # IAD, IAD Reference
    calc_types = [Constants.CalcTypeERIIndexAdjustmentDesign,
                  Constants.CalcTypeERIIndexAdjustmentReferenceHome]
    calc_types.each do |calc_type|
      hpxml = _test_measure(hpxml_name, calc_type)
      _check_water_heater(hpxml, [HPXML::WaterHeaterTypeStorage, HPXML::FuelTypeNaturalGas, 125.0, HPXML::LocationLivingSpace, 40, 0.594, 1])
      _check_hot_water_distribution(hpxml, HPXML::DHWDistTypeStandard, 0.0, 89.28, nil, nil, nil, nil)
      _check_water_fixtures(hpxml, false, false)
      _check_drain_water_heat_recovery(hpxml, nil, nil, nil)
    end
  end

  def test_multiple_water_heating
    hpxml_name = 'base-dhw-multiple.xml'

    # Reference Home
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_water_heater(hpxml, [HPXML::WaterHeaterTypeStorage, HPXML::FuelTypeElectricity, 125.0, HPXML::LocationLivingSpace, 40, 0.9172, 1],
                        [HPXML::WaterHeaterTypeStorage, HPXML::FuelTypeNaturalGas, 125.0, HPXML::LocationLivingSpace, 50, 0.575, 1],
                        [HPXML::WaterHeaterTypeStorage, HPXML::FuelTypeElectricity, 125.0, HPXML::LocationLivingSpace, 80, 0.8644, 1],
                        [HPXML::WaterHeaterTypeStorage, HPXML::FuelTypeElectricity, 125.0, HPXML::LocationLivingSpace, 40, 0.9172, 1],
                        [HPXML::WaterHeaterTypeStorage, HPXML::FuelTypeNaturalGas, 125.0, HPXML::LocationLivingSpace, 40, 0.594, 1],
                        [HPXML::WaterHeaterTypeStorage, HPXML::FuelTypeNaturalGas, 125.0, HPXML::LocationLivingSpace, 50, 0.575, 1])
    _check_hot_water_distribution(hpxml, HPXML::DHWDistTypeStandard, 0.0, 93.5, nil, nil, nil, nil)
    _check_water_fixtures(hpxml, false, false)
    _check_drain_water_heat_recovery(hpxml, nil, nil, nil)

    # Rated Home
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_water_heater(hpxml, [HPXML::WaterHeaterTypeStorage, HPXML::FuelTypeElectricity, 125.0, HPXML::LocationLivingSpace, 40, 0.95, 1],
                        [HPXML::WaterHeaterTypeStorage, HPXML::FuelTypeNaturalGas, 125.0, HPXML::LocationLivingSpace, 50, 0.59, 1],
                        [HPXML::WaterHeaterTypeHeatPump, HPXML::FuelTypeElectricity, 125.0, HPXML::LocationLivingSpace, 80, 2.3, 1],
                        [HPXML::WaterHeaterTypeTankless, HPXML::FuelTypeElectricity, 125.0, HPXML::LocationLivingSpace, nil, 0.99, 1],
                        [HPXML::WaterHeaterTypeTankless, HPXML::FuelTypeNaturalGas, 125.0, HPXML::LocationLivingSpace, nil, 0.82, 1],
                        [HPXML::WaterHeaterTypeCombiStorage, nil, 125.0, HPXML::LocationLivingSpace, 50, nil, 1])
    _check_hot_water_distribution(hpxml, HPXML::DHWDistTypeStandard, 0.0, 50, nil, nil, nil, nil)
    _check_water_fixtures(hpxml, true, false)
    _check_drain_water_heat_recovery(hpxml, nil, nil, nil)

    # IAD, IAD Reference
    calc_types = [Constants.CalcTypeERIIndexAdjustmentDesign,
                  Constants.CalcTypeERIIndexAdjustmentReferenceHome]
    calc_types.each do |calc_type|
      hpxml = _test_measure(hpxml_name, calc_type)
      _check_water_heater(hpxml, [HPXML::WaterHeaterTypeStorage, HPXML::FuelTypeElectricity, 125.0, HPXML::LocationLivingSpace, 40, 0.9172, 1],
                          [HPXML::WaterHeaterTypeStorage, HPXML::FuelTypeNaturalGas, 125.0, HPXML::LocationLivingSpace, 50, 0.575, 1],
                          [HPXML::WaterHeaterTypeStorage, HPXML::FuelTypeElectricity, 125.0, HPXML::LocationLivingSpace, 80, 0.8644, 1],
                          [HPXML::WaterHeaterTypeStorage, HPXML::FuelTypeElectricity, 125.0, HPXML::LocationLivingSpace, 40, 0.9172, 1],
                          [HPXML::WaterHeaterTypeStorage, HPXML::FuelTypeNaturalGas, 125.0, HPXML::LocationLivingSpace, 40, 0.594, 1],
                          [HPXML::WaterHeaterTypeStorage, HPXML::FuelTypeNaturalGas, 125.0, HPXML::LocationLivingSpace, 50, 0.575, 1])
      _check_hot_water_distribution(hpxml, HPXML::DHWDistTypeStandard, 0.0, 89.28, nil, nil, nil, nil)
      _check_water_fixtures(hpxml, false, false)
      _check_drain_water_heat_recovery(hpxml, nil, nil, nil)
    end
  end

  def test_indirect_water_heating
    hpxml_name = 'base-dhw-indirect.xml'

    # Reference Home
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_water_heater(hpxml, [HPXML::WaterHeaterTypeStorage, HPXML::FuelTypeNaturalGas, 125.0, HPXML::LocationLivingSpace, 50, 0.575, 1])
    _check_hot_water_distribution(hpxml, HPXML::DHWDistTypeStandard, 0.0, 93.5, nil, nil, nil, nil)
    _check_water_fixtures(hpxml, false, false)
    _check_drain_water_heat_recovery(hpxml, nil, nil, nil)

    # Rated Home
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_water_heater(hpxml, [HPXML::WaterHeaterTypeCombiStorage, nil, 125.0, HPXML::LocationLivingSpace, 50, nil, 1])
    _check_hot_water_distribution(hpxml, HPXML::DHWDistTypeStandard, 0.0, 50, nil, nil, nil, nil)
    _check_water_fixtures(hpxml, true, false)
    _check_drain_water_heat_recovery(hpxml, nil, nil, nil)

    # IAD, IAD Reference
    calc_types = [Constants.CalcTypeERIIndexAdjustmentDesign,
                  Constants.CalcTypeERIIndexAdjustmentReferenceHome]
    calc_types.each do |calc_type|
      hpxml = _test_measure(hpxml_name, calc_type)
      _check_water_heater(hpxml, [HPXML::WaterHeaterTypeStorage, HPXML::FuelTypeNaturalGas, 125.0, HPXML::LocationLivingSpace, 50, 0.575, 1])
      _check_hot_water_distribution(hpxml, HPXML::DHWDistTypeStandard, 0.0, 89.28, nil, nil, nil, nil)
      _check_water_fixtures(hpxml, false, false)
      _check_drain_water_heat_recovery(hpxml, nil, nil, nil)
    end
  end

  def test_indirect_tankless_coil
    hpxml_name = 'base-dhw-combi-tankless.xml'

    # Reference Home
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_water_heater(hpxml, [HPXML::WaterHeaterTypeStorage, HPXML::FuelTypeNaturalGas, 125.0, HPXML::LocationLivingSpace, 40, 0.594, 1])
    _check_hot_water_distribution(hpxml, HPXML::DHWDistTypeStandard, 0.0, 93.5, nil, nil, nil, nil)
    _check_water_fixtures(hpxml, false, false)
    _check_drain_water_heat_recovery(hpxml, nil, nil, nil)

    # Rated Home
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_water_heater(hpxml, [HPXML::WaterHeaterTypeCombiTankless, nil, 125.0, HPXML::LocationLivingSpace, nil, nil, 1])
    _check_hot_water_distribution(hpxml, HPXML::DHWDistTypeStandard, 0.0, 50, nil, nil, nil, nil)
    _check_water_fixtures(hpxml, true, false)
    _check_drain_water_heat_recovery(hpxml, nil, nil, nil)

    # IAD, IAD Reference
    calc_types = [Constants.CalcTypeERIIndexAdjustmentDesign,
                  Constants.CalcTypeERIIndexAdjustmentReferenceHome]
    calc_types.each do |calc_type|
      hpxml = _test_measure(hpxml_name, calc_type)
      _check_water_heater(hpxml, [HPXML::WaterHeaterTypeStorage, HPXML::FuelTypeNaturalGas, 125.0, HPXML::LocationLivingSpace, 40, 0.594, 1])
      _check_hot_water_distribution(hpxml, HPXML::DHWDistTypeStandard, 0.0, 89.28, nil, nil, nil, nil)
      _check_water_fixtures(hpxml, false, false)
      _check_drain_water_heat_recovery(hpxml, nil, nil, nil)
    end
  end

  def test_water_heating_none
    hpxml_name = 'base-dhw-none.xml'

    # Reference Home, Rated Home
    calc_types = [Constants.CalcTypeERIReferenceHome,
                  Constants.CalcTypeERIRatedHome]
    calc_types.each do |calc_type|
      hpxml = _test_measure(hpxml_name, calc_type)
      _check_water_heater(hpxml, [HPXML::WaterHeaterTypeStorage, HPXML::FuelTypeNaturalGas, 125.0, HPXML::LocationLivingSpace, 40, 0.594, 1])
      _check_hot_water_distribution(hpxml, HPXML::DHWDistTypeStandard, 0.0, 93.5, nil, nil, nil, nil)
      _check_water_fixtures(hpxml, false, false)
      _check_drain_water_heat_recovery(hpxml, nil, nil, nil)
    end

    # IAD, IAD Reference
    calc_types = [Constants.CalcTypeERIIndexAdjustmentDesign,
                  Constants.CalcTypeERIIndexAdjustmentReferenceHome]
    calc_types.each do |calc_type|
      hpxml = _test_measure(hpxml_name, calc_type)
      _check_water_heater(hpxml, [HPXML::WaterHeaterTypeStorage, HPXML::FuelTypeNaturalGas, 125.0, HPXML::LocationLivingSpace, 40, 0.594, 1])
      _check_hot_water_distribution(hpxml, HPXML::DHWDistTypeStandard, 0.0, 89.28, nil, nil, nil, nil)
      _check_water_fixtures(hpxml, false, false)
      _check_drain_water_heat_recovery(hpxml, nil, nil, nil)
    end
  end

  def test_water_heating_uef
    hpxml_name = 'base-dhw-uef.xml'

    # Reference Home
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_water_heater(hpxml, [HPXML::WaterHeaterTypeStorage, HPXML::FuelTypeElectricity, 125.0, HPXML::LocationLivingSpace, 40, 0.9172, 1])
    _check_hot_water_distribution(hpxml, HPXML::DHWDistTypeStandard, 0.0, 93.5, nil, nil, nil, nil)
    _check_water_fixtures(hpxml, false, false)
    _check_drain_water_heat_recovery(hpxml, nil, nil, nil)

    # Rated Home
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_water_heater(hpxml, [HPXML::WaterHeaterTypeStorage, HPXML::FuelTypeElectricity, 125.0, HPXML::LocationLivingSpace, 40, 0.95, 1])
    _check_hot_water_distribution(hpxml, HPXML::DHWDistTypeStandard, 0.0, 50, nil, nil, nil, nil)
    _check_water_fixtures(hpxml, true, false)
    _check_drain_water_heat_recovery(hpxml, nil, nil, nil)

    # IAD, IAD Reference
    calc_types = [Constants.CalcTypeERIIndexAdjustmentDesign,
                  Constants.CalcTypeERIIndexAdjustmentReferenceHome]
    calc_types.each do |calc_type|
      hpxml = _test_measure(hpxml_name, calc_type)
      _check_water_heater(hpxml, [HPXML::WaterHeaterTypeStorage, HPXML::FuelTypeElectricity, 125.0, HPXML::LocationLivingSpace, 40, 0.9172, 1])
      _check_hot_water_distribution(hpxml, HPXML::DHWDistTypeStandard, 0.0, 89.28, nil, nil, nil, nil)
      _check_water_fixtures(hpxml, false, false)
      _check_drain_water_heat_recovery(hpxml, nil, nil, nil)
    end
  end

  def test_indirect_standbyloss
    hpxml_name = 'base-dhw-indirect-standbyloss.xml'

    # Reference Home
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_water_heater(hpxml, [HPXML::WaterHeaterTypeStorage, HPXML::FuelTypeNaturalGas, 125.0, HPXML::LocationLivingSpace, 50, 0.575, 1])
    _check_hot_water_distribution(hpxml, HPXML::DHWDistTypeStandard, 0.0, 93.5, nil, nil, nil, nil)
    _check_water_fixtures(hpxml, false, false)
    _check_drain_water_heat_recovery(hpxml, nil, nil, nil)

    # Rated Home
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_water_heater(hpxml, [HPXML::WaterHeaterTypeCombiStorage, nil, 125.0, HPXML::LocationLivingSpace, 50, nil, 1, nil, 1.0])
    _check_hot_water_distribution(hpxml, HPXML::DHWDistTypeStandard, 0.0, 50, nil, nil, nil, nil)
    _check_water_fixtures(hpxml, true, false)
    _check_drain_water_heat_recovery(hpxml, nil, nil, nil)

    # IAD, IAD Reference
    calc_types = [Constants.CalcTypeERIIndexAdjustmentDesign,
                  Constants.CalcTypeERIIndexAdjustmentReferenceHome]
    calc_types.each do |calc_type|
      hpxml = _test_measure(hpxml_name, calc_type)
      _check_water_heater(hpxml, [HPXML::WaterHeaterTypeStorage, HPXML::FuelTypeNaturalGas, 125.0, HPXML::LocationLivingSpace, 50, 0.575, 1])
      _check_hot_water_distribution(hpxml, HPXML::DHWDistTypeStandard, 0.0, 89.28, nil, nil, nil, nil)
      _check_water_fixtures(hpxml, false, false)
      _check_drain_water_heat_recovery(hpxml, nil, nil, nil)
    end
  end

  def test_water_heating_pre_addendum_a
    hpxml_name = 'base-version-2014.xml'

    # Reference Home
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_water_heater(hpxml, [HPXML::WaterHeaterTypeStorage, HPXML::FuelTypeElectricity, 120.0, HPXML::LocationLivingSpace, 40, 0.9172, 1])
    _check_hot_water_distribution(hpxml, HPXML::DHWDistTypeStandard, 0.0, 93.5, nil, nil, nil, nil)
    _check_water_fixtures(hpxml, false, false)
    _check_drain_water_heat_recovery(hpxml, nil, nil, nil)

    # Rated Home
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_water_heater(hpxml, [HPXML::WaterHeaterTypeStorage, HPXML::FuelTypeElectricity, 120.0, HPXML::LocationLivingSpace, 40, 0.95, 1])
    _check_hot_water_distribution(hpxml, HPXML::DHWDistTypeStandard, 0.0, 50, nil, nil, nil, nil)
    _check_water_fixtures(hpxml, true, false)
    _check_drain_water_heat_recovery(hpxml, nil, nil, nil)

    # IAD, IAD Reference
    calc_types = [Constants.CalcTypeERIIndexAdjustmentDesign,
                  Constants.CalcTypeERIIndexAdjustmentReferenceHome]
    calc_types.each do |calc_type|
      hpxml = _test_measure(hpxml_name, calc_type)
      _check_water_heater(hpxml, [HPXML::WaterHeaterTypeStorage, HPXML::FuelTypeElectricity, 120.0, HPXML::LocationLivingSpace, 40, 0.9172, 1])
      _check_hot_water_distribution(hpxml, HPXML::DHWDistTypeStandard, 0.0, 89.28, nil, nil, nil, nil)
      _check_water_fixtures(hpxml, false, false)
      _check_drain_water_heat_recovery(hpxml, nil, nil, nil)
    end
  end

  def test_water_heating_shared_multiple_units_recirc
    hpxml_name = 'base-dhw-shared-water-heater-multiple-units-recirc.xml'

    # Reference Home
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_water_heater(hpxml, [HPXML::WaterHeaterTypeStorage, HPXML::FuelTypeNaturalGas, 125.0, HPXML::LocationLivingSpace, 40, 0.59, 1])
    _check_hot_water_distribution(hpxml, HPXML::DHWDistTypeStandard, 0.0, 93.5, nil, nil, nil, nil)
    _check_water_fixtures(hpxml, false, false)
    _check_drain_water_heat_recovery(hpxml, nil, nil, nil)

    # Rated Home
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_water_heater(hpxml, [HPXML::WaterHeaterTypeStorage, HPXML::FuelTypeNaturalGas, 125.0, HPXML::LocationLivingSpace, 50, 0.59, 6])
    _check_hot_water_distribution(hpxml, HPXML::DHWDistTypeStandard, 0.0, 50, nil, nil, nil, nil, 220, 6, HPXML::DHWRecirControlTypeTimer)
    _check_water_fixtures(hpxml, true, false)
    _check_drain_water_heat_recovery(hpxml, nil, nil, nil)

    # IAD, IAD Reference
    calc_types = [Constants.CalcTypeERIIndexAdjustmentDesign,
                  Constants.CalcTypeERIIndexAdjustmentReferenceHome]
    calc_types.each do |calc_type|
      hpxml = _test_measure(hpxml_name, calc_type)
      _check_water_heater(hpxml, [HPXML::WaterHeaterTypeStorage, HPXML::FuelTypeNaturalGas, 125.0, HPXML::LocationLivingSpace, 40, 0.59, 1])
      _check_hot_water_distribution(hpxml, HPXML::DHWDistTypeStandard, 0.0, 89.28, nil, nil, nil, nil)
      _check_water_fixtures(hpxml, false, false)
      _check_drain_water_heat_recovery(hpxml, nil, nil, nil)
    end
  end

  def test_water_heating_shared_equipment_room
    hpxml_name = 'base-dhw-shared-water-heater-equipment-room.xml'

    # Reference Home
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_water_heater(hpxml, [HPXML::WaterHeaterTypeStorage, HPXML::FuelTypeElectricity, 125.0, HPXML::LocationLivingSpace, 40, 0.9172, 1],
                        [HPXML::WaterHeaterTypeStorage, HPXML::FuelTypeElectricity, 125.0, HPXML::LocationOtherHeatedSpace, 40, 0.9172, 1])
    _check_hot_water_distribution(hpxml, HPXML::DHWDistTypeStandard, 0.0, 93.5, nil, nil, nil, nil)
    _check_water_fixtures(hpxml, false, false)
    _check_drain_water_heat_recovery(hpxml, nil, nil, nil)

    # Rated Home
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_water_heater(hpxml, [HPXML::WaterHeaterTypeStorage, HPXML::FuelTypeElectricity, 125.0, HPXML::LocationLivingSpace, 40, 0.95, 1],
                        [HPXML::WaterHeaterTypeStorage, HPXML::FuelTypeElectricity, 125.0, HPXML::LocationOtherHeatedSpace, 40, 0.95, 6])
    _check_hot_water_distribution(hpxml, HPXML::DHWDistTypeStandard, 0.0, 50, nil, nil, nil, nil)
    _check_water_fixtures(hpxml, true, false)
    _check_drain_water_heat_recovery(hpxml, nil, nil, nil)

    # IAD, IAD Reference
    calc_types = [Constants.CalcTypeERIIndexAdjustmentDesign,
                  Constants.CalcTypeERIIndexAdjustmentReferenceHome]
    calc_types.each do |calc_type|
      hpxml = _test_measure(hpxml_name, calc_type)
      _check_water_heater(hpxml, [HPXML::WaterHeaterTypeStorage, HPXML::FuelTypeElectricity, 125.0, HPXML::LocationLivingSpace, 40, 0.9172, 1],
                          [HPXML::WaterHeaterTypeStorage, HPXML::FuelTypeElectricity, 125.0, HPXML::LocationLivingSpace, 40, 0.9172, 1])
      _check_hot_water_distribution(hpxml, HPXML::DHWDistTypeStandard, 0.0, 89.28, nil, nil, nil, nil)
      _check_water_fixtures(hpxml, false, false)
      _check_drain_water_heat_recovery(hpxml, nil, nil, nil)
    end
  end

  def test_water_heating_solar_simple
    hpxml_name = 'base-dhw-solar-fraction.xml'

    # Rated Home
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_solar_thermal_system(hpxml, true)

    # Reference Home, IAD, IAD Reference
    calc_types = [Constants.CalcTypeERIReferenceHome,
                  Constants.CalcTypeERIIndexAdjustmentDesign,
                  Constants.CalcTypeERIIndexAdjustmentReferenceHome]
    calc_types.each do |calc_type|
      hpxml = _test_measure(hpxml_name, calc_type)
      _check_solar_thermal_system(hpxml, false)
    end
  end

  def test_water_heating_solar_detailed
    hpxml_name = 'base-dhw-solar-indirect-flat-plate.xml'

    # Rated Home
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_solar_thermal_system(hpxml, true)

    # Reference Home, IAD, IAD Reference
    calc_types = [Constants.CalcTypeERIReferenceHome,
                  Constants.CalcTypeERIIndexAdjustmentDesign,
                  Constants.CalcTypeERIIndexAdjustmentReferenceHome]
    calc_types.each do |calc_type|
      hpxml = _test_measure(hpxml_name, calc_type)
      _check_solar_thermal_system(hpxml, false)
    end
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

  def _check_water_heater(hpxml, *systems)
    assert_equal(systems.size, hpxml.water_heating_systems.size)
    hpxml.water_heating_systems.each_with_index do |water_heater, idx|
      whtype, fuel_type, temp, location, tank_vol, ef, n_units_served, jacket_r, standby_loss = systems[idx]
      assert_equal(whtype, water_heater.water_heater_type)
      assert_equal(location, water_heater.location)
      if fuel_type.nil?
        assert_nil(water_heater.fuel_type)
      else
        assert_equal(fuel_type, water_heater.fuel_type)
      end
      if tank_vol.nil?
        assert_nil(water_heater.tank_volume)
      else
        assert_in_epsilon(tank_vol, water_heater.tank_volume, 0.01)
      end
      if ef.nil?
        assert_nil(water_heater.energy_factor)
      else
        assert_in_epsilon(ef, water_heater.energy_factor, 0.01)
      end
      if jacket_r.nil?
        assert_nil(water_heater.jacket_r_value)
      else
        assert_in_epsilon(jacket_r, water_heater.jacket_r_value, 0.01)
      end
      assert_in_epsilon(temp, water_heater.temperature, 0.01)
      if standby_loss.nil?
        assert_nil(water_heater.standby_loss)
      else
        assert_in_epsilon(standby_loss, water_heater.standby_loss, 0.01)
      end
      if whtype == HPXML::WaterHeaterTypeTankless
        assert_equal(0.92, water_heater.performance_adjustment)
      else
        assert_equal(1.0, water_heater.performance_adjustment)
      end
      if water_heater.number_of_units_served.nil?
        assert_equal(n_units_served, 1)
      else
        assert_equal(n_units_served, water_heater.number_of_units_served)
      end
    end
  end

  def _check_hot_water_distribution(hpxml, disttype, pipe_r, pipe_l, recirc_control, recirc_loop_l, recirc_branch_l, recirc_pump_power,
                                    shared_recirc_power = nil, shared_recirc_num_units_served = nil, shared_recirc_control_type = nil)
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

  def _check_water_fixtures(hpxml, low_flow_shower, low_flow_faucet)
    assert_equal(2, hpxml.water_fixtures.size)
    hpxml.water_fixtures.each do |water_fixture|
      if water_fixture.water_fixture_type == HPXML::WaterFixtureTypeShowerhead
        assert_equal(low_flow_shower, water_fixture.low_flow)
      elsif water_fixture.water_fixture_type == HPXML::WaterFixtureTypeFaucet
        assert_equal(low_flow_faucet, water_fixture.low_flow)
      end
    end
  end

  def _check_drain_water_heat_recovery(hpxml, facilities_connected, equal_flow, efficiency)
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

  def _check_solar_thermal_system(hpxml, present)
    if present
      assert_equal(1, hpxml.solar_thermal_systems.size)
    else
      assert_equal(0, hpxml.solar_thermal_systems.size)
    end
  end

  def _check_desuperheater(hpxml, present)
    hpxml.water_heating_systems.each do |water_heater|
      assert_equal(present, water_heater.uses_desuperheater)
    end
  end
end
