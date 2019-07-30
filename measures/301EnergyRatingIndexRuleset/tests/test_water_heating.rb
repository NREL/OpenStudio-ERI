require_relative '../../../workflow/tests/minitest_helper'
require 'openstudio'
require 'openstudio/ruleset/ShowRunnerOutput'
require 'minitest/autorun'
require_relative '../measure.rb'
require 'fileutils'

class WaterHeatingTest < MiniTest::Test
  def before_setup
    @root_path = File.absolute_path(File.join(File.dirname(__FILE__), "..", "..", ".."))
  end

  def test_water_heating
    hpxml_name = "base.xml"

    # Reference Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_water_heater(hpxml_doc, ["storage water heater", "electricity", "living space", 40, 0.9172])
    _check_hot_water_distribution(hpxml_doc, "Standard", 0.0, 93.5, nil, nil, nil, nil)
    _check_water_fixtures(hpxml_doc, false, false)
    _check_drain_water_heat_recovery(hpxml_doc, false, nil, nil, nil)

    # Rated Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_water_heater(hpxml_doc, ["storage water heater", "electricity", "living space", 40, 0.95])
    _check_hot_water_distribution(hpxml_doc, "Standard", 0.0, 90, nil, nil, nil, nil)
    _check_water_fixtures(hpxml_doc, true, false)
    _check_drain_water_heat_recovery(hpxml_doc, false, nil, nil, nil)

    # IAD, IAD Reference
    calc_types = [Constants.CalcTypeERIIndexAdjustmentDesign,
                  Constants.CalcTypeERIIndexAdjustmentReferenceHome]
    calc_types.each do |calc_type|
      hpxml_doc = _test_measure(hpxml_name, calc_type)
      _check_water_heater(hpxml_doc, ["storage water heater", "electricity", "living space", 40, 0.9172])
      _check_hot_water_distribution(hpxml_doc, "Standard", 0.0, 89.28, nil, nil, nil, nil)
      _check_water_fixtures(hpxml_doc, false, false)
      _check_drain_water_heat_recovery(hpxml_doc, false, nil, nil, nil)
    end
  end

  def test_water_heating_dwhr
    hpxml_name = "base-dhw-dwhr.xml"

    # Reference Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_water_heater(hpxml_doc, ["storage water heater", "electricity", "living space", 40, 0.9172])
    _check_hot_water_distribution(hpxml_doc, "Standard", 0.0, 93.5, nil, nil, nil, nil)
    _check_water_fixtures(hpxml_doc, false, false)
    _check_drain_water_heat_recovery(hpxml_doc, false, nil, nil, nil)

    # Rated Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_water_heater(hpxml_doc, ["storage water heater", "electricity", "living space", 40, 0.95])
    _check_hot_water_distribution(hpxml_doc, "Standard", 0.0, 90, nil, nil, nil, nil)
    _check_water_fixtures(hpxml_doc, true, false)
    _check_drain_water_heat_recovery(hpxml_doc, true, "all", true, 0.55)

    # IAD, IAD Reference
    calc_types = [Constants.CalcTypeERIIndexAdjustmentDesign,
                  Constants.CalcTypeERIIndexAdjustmentReferenceHome]
    calc_types.each do |calc_type|
      hpxml_doc = _test_measure(hpxml_name, calc_type)
      _check_water_heater(hpxml_doc, ["storage water heater", "electricity", "living space", 40, 0.9172])
      _check_hot_water_distribution(hpxml_doc, "Standard", 0.0, 89.28, nil, nil, nil, nil)
      _check_water_fixtures(hpxml_doc, false, false)
      _check_drain_water_heat_recovery(hpxml_doc, false, nil, nil, nil)
    end
  end

  def test_water_heating_location_basement
    hpxml_name = "base-foundation-unconditioned-basement.xml"

    # Reference Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_water_heater(hpxml_doc, ["storage water heater", "electricity", "basement - unconditioned", 40, 0.9172])
    _check_hot_water_distribution(hpxml_doc, "Standard", 0.0, 88.5, nil, nil, nil, nil)
    _check_water_fixtures(hpxml_doc, false, false)
    _check_drain_water_heat_recovery(hpxml_doc, false, nil, nil, nil)

    # Rated Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_water_heater(hpxml_doc, ["storage water heater", "electricity", "basement - unconditioned", 40, 0.95])
    _check_hot_water_distribution(hpxml_doc, "Standard", 0.0, 90, nil, nil, nil, nil)
    _check_water_fixtures(hpxml_doc, true, false)
    _check_drain_water_heat_recovery(hpxml_doc, false, nil, nil, nil)

    # IAD, IAD Reference
    calc_types = [Constants.CalcTypeERIIndexAdjustmentDesign,
                  Constants.CalcTypeERIIndexAdjustmentReferenceHome]
    calc_types.each do |calc_type|
      hpxml_doc = _test_measure(hpxml_name, calc_type)
      _check_water_heater(hpxml_doc, ["storage water heater", "electricity", "living space", 40, 0.9172])
      _check_hot_water_distribution(hpxml_doc, "Standard", 0.0, 89.28, nil, nil, nil, nil)
      _check_water_fixtures(hpxml_doc, false, false)
      _check_drain_water_heat_recovery(hpxml_doc, false, nil, nil, nil)
    end
  end

  def test_water_heating_low_flow_fixtures
    hpxml_name = "base-dhw-low-flow-fixtures.xml"

    # Reference Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_water_heater(hpxml_doc, ["storage water heater", "electricity", "living space", 40, 0.9172])
    _check_hot_water_distribution(hpxml_doc, "Standard", 0.0, 93.5, nil, nil, nil, nil)
    _check_water_fixtures(hpxml_doc, false, false)
    _check_drain_water_heat_recovery(hpxml_doc, false, nil, nil, nil)

    # Rated Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_water_heater(hpxml_doc, ["storage water heater", "electricity", "living space", 40, 0.95])
    _check_hot_water_distribution(hpxml_doc, "Standard", 0.0, 90, nil, nil, nil, nil)
    _check_water_fixtures(hpxml_doc, true, true)
    _check_drain_water_heat_recovery(hpxml_doc, false, nil, nil, nil)

    # IAD, IAD Reference
    calc_types = [Constants.CalcTypeERIIndexAdjustmentDesign,
                  Constants.CalcTypeERIIndexAdjustmentReferenceHome]
    calc_types.each do |calc_type|
      hpxml_doc = _test_measure(hpxml_name, calc_type)
      _check_water_heater(hpxml_doc, ["storage water heater", "electricity", "living space", 40, 0.9172])
      _check_hot_water_distribution(hpxml_doc, "Standard", 0.0, 89.28, nil, nil, nil, nil)
      _check_water_fixtures(hpxml_doc, false, false)
      _check_drain_water_heat_recovery(hpxml_doc, false, nil, nil, nil)
    end
  end

  def test_water_heating_recirc_demand
    hpxml_name = "base-dhw-recirc-demand.xml"

    # Reference Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_water_heater(hpxml_doc, ["storage water heater", "electricity", "living space", 40, 0.9172])
    _check_hot_water_distribution(hpxml_doc, "Standard", 0.0, 93.5, nil, nil, nil, nil)
    _check_water_fixtures(hpxml_doc, false, false)
    _check_drain_water_heat_recovery(hpxml_doc, false, nil, nil, nil)

    # Rated Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_water_heater(hpxml_doc, ["storage water heater", "electricity", "living space", 40, 0.95])
    _check_hot_water_distribution(hpxml_doc, "Recirculation", 3.0, nil, "presence sensor demand control", 50, 50, 50)
    _check_water_fixtures(hpxml_doc, true, false)
    _check_drain_water_heat_recovery(hpxml_doc, false, nil, nil, nil)

    # IAD, IAD Reference
    calc_types = [Constants.CalcTypeERIIndexAdjustmentDesign,
                  Constants.CalcTypeERIIndexAdjustmentReferenceHome]
    calc_types.each do |calc_type|
      hpxml_doc = _test_measure(hpxml_name, calc_type)
      _check_water_heater(hpxml_doc, ["storage water heater", "electricity", "living space", 40, 0.9172])
      _check_hot_water_distribution(hpxml_doc, "Standard", 0.0, 89.28, nil, nil, nil, nil)
      _check_water_fixtures(hpxml_doc, false, false)
      _check_drain_water_heat_recovery(hpxml_doc, false, nil, nil, nil)
    end
  end

  def test_water_heating_recirc_nocontrol
    hpxml_name = "base-dhw-recirc-nocontrol.xml"

    # Reference Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_water_heater(hpxml_doc, ["storage water heater", "electricity", "living space", 40, 0.9172])
    _check_hot_water_distribution(hpxml_doc, "Standard", 0.0, 93.5, nil, nil, nil, nil)
    _check_water_fixtures(hpxml_doc, false, false)
    _check_drain_water_heat_recovery(hpxml_doc, false, nil, nil, nil)

    # Rated Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_water_heater(hpxml_doc, ["storage water heater", "electricity", "living space", 40, 0.95])
    _check_hot_water_distribution(hpxml_doc, "Recirculation", 0.0, nil, "no control", 50, 50, 50)
    _check_water_fixtures(hpxml_doc, true, false)
    _check_drain_water_heat_recovery(hpxml_doc, false, nil, nil, nil)

    # IAD, IAD Reference
    calc_types = [Constants.CalcTypeERIIndexAdjustmentDesign,
                  Constants.CalcTypeERIIndexAdjustmentReferenceHome]
    calc_types.each do |calc_type|
      hpxml_doc = _test_measure(hpxml_name, calc_type)
      _check_water_heater(hpxml_doc, ["storage water heater", "electricity", "living space", 40, 0.9172])
      _check_hot_water_distribution(hpxml_doc, "Standard", 0.0, 89.28, nil, nil, nil, nil)
      _check_water_fixtures(hpxml_doc, false, false)
      _check_drain_water_heat_recovery(hpxml_doc, false, nil, nil, nil)
    end
  end

  def test_water_heating_recirc_timer
    hpxml_name = "base-dhw-recirc-timer.xml"

    # Reference Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_water_heater(hpxml_doc, ["storage water heater", "electricity", "living space", 40, 0.9172])
    _check_hot_water_distribution(hpxml_doc, "Standard", 0.0, 93.5, nil, nil, nil, nil)
    _check_water_fixtures(hpxml_doc, false, false)
    _check_drain_water_heat_recovery(hpxml_doc, false, nil, nil, nil)

    # Rated Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_water_heater(hpxml_doc, ["storage water heater", "electricity", "living space", 40, 0.95])
    _check_hot_water_distribution(hpxml_doc, "Recirculation", 0.0, nil, "timer", 50, 50, 50)
    _check_water_fixtures(hpxml_doc, true, false)
    _check_drain_water_heat_recovery(hpxml_doc, false, nil, nil, nil)

    # IAD, IAD Reference
    calc_types = [Constants.CalcTypeERIIndexAdjustmentDesign,
                  Constants.CalcTypeERIIndexAdjustmentReferenceHome]
    calc_types.each do |calc_type|
      hpxml_doc = _test_measure(hpxml_name, calc_type)
      _check_water_heater(hpxml_doc, ["storage water heater", "electricity", "living space", 40, 0.9172])
      _check_hot_water_distribution(hpxml_doc, "Standard", 0.0, 89.28, nil, nil, nil, nil)
      _check_water_fixtures(hpxml_doc, false, false)
      _check_drain_water_heat_recovery(hpxml_doc, false, nil, nil, nil)
    end
  end

  def test_water_heating_recirc_temperature
    hpxml_name = "base-dhw-recirc-temperature.xml"

    # Reference Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_water_heater(hpxml_doc, ["storage water heater", "electricity", "living space", 40, 0.9172])
    _check_hot_water_distribution(hpxml_doc, "Standard", 0.0, 93.5, nil, nil, nil, nil)
    _check_water_fixtures(hpxml_doc, false, false)
    _check_drain_water_heat_recovery(hpxml_doc, false, nil, nil, nil)

    # Rated Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_water_heater(hpxml_doc, ["storage water heater", "electricity", "living space", 40, 0.95])
    _check_hot_water_distribution(hpxml_doc, "Recirculation", 0.0, nil, "temperature", 50, 50, 50)
    _check_water_fixtures(hpxml_doc, true, false)
    _check_drain_water_heat_recovery(hpxml_doc, false, nil, nil, nil)

    # IAD, IAD Reference
    calc_types = [Constants.CalcTypeERIIndexAdjustmentDesign,
                  Constants.CalcTypeERIIndexAdjustmentReferenceHome]
    calc_types.each do |calc_type|
      hpxml_doc = _test_measure(hpxml_name, calc_type)
      _check_water_heater(hpxml_doc, ["storage water heater", "electricity", "living space", 40, 0.9172])
      _check_hot_water_distribution(hpxml_doc, "Standard", 0.0, 89.28, nil, nil, nil, nil)
      _check_water_fixtures(hpxml_doc, false, false)
      _check_drain_water_heat_recovery(hpxml_doc, false, nil, nil, nil)
    end
  end

  def test_water_heating_recirc_manual
    hpxml_name = "base-dhw-recirc-manual.xml"

    # Reference Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_water_heater(hpxml_doc, ["storage water heater", "electricity", "living space", 40, 0.9172])
    _check_hot_water_distribution(hpxml_doc, "Standard", 0.0, 93.5, nil, nil, nil, nil)
    _check_water_fixtures(hpxml_doc, false, false)
    _check_drain_water_heat_recovery(hpxml_doc, false, nil, nil, nil)

    # Rated Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_water_heater(hpxml_doc, ["storage water heater", "electricity", "living space", 40, 0.95])
    _check_hot_water_distribution(hpxml_doc, "Recirculation", 3.0, nil, "manual demand control", 50, 50, 50)
    _check_water_fixtures(hpxml_doc, true, false)
    _check_drain_water_heat_recovery(hpxml_doc, false, nil, nil, nil)

    # IAD, IAD Reference
    calc_types = [Constants.CalcTypeERIIndexAdjustmentDesign,
                  Constants.CalcTypeERIIndexAdjustmentReferenceHome]
    calc_types.each do |calc_type|
      hpxml_doc = _test_measure(hpxml_name, calc_type)
      _check_water_heater(hpxml_doc, ["storage water heater", "electricity", "living space", 40, 0.9172])
      _check_hot_water_distribution(hpxml_doc, "Standard", 0.0, 89.28, nil, nil, nil, nil)
      _check_water_fixtures(hpxml_doc, false, false)
      _check_drain_water_heat_recovery(hpxml_doc, false, nil, nil, nil)
    end
  end

  def test_water_heating_tank_gas
    hpxml_name = "base-dhw-tank-gas.xml"

    # Reference Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_water_heater(hpxml_doc, ["storage water heater", "natural gas", "living space", 50, 0.575])
    _check_hot_water_distribution(hpxml_doc, "Standard", 0.0, 93.5, nil, nil, nil, nil)
    _check_water_fixtures(hpxml_doc, false, false)
    _check_drain_water_heat_recovery(hpxml_doc, false, nil, nil, nil)

    # Rated Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_water_heater(hpxml_doc, ["storage water heater", "natural gas", "living space", 50, 0.59])
    _check_hot_water_distribution(hpxml_doc, "Standard", 0.0, 90, nil, nil, nil, nil)
    _check_water_fixtures(hpxml_doc, true, false)
    _check_drain_water_heat_recovery(hpxml_doc, false, nil, nil, nil)

    # IAD, IAD Reference
    calc_types = [Constants.CalcTypeERIIndexAdjustmentDesign,
                  Constants.CalcTypeERIIndexAdjustmentReferenceHome]
    calc_types.each do |calc_type|
      hpxml_doc = _test_measure(hpxml_name, calc_type)
      _check_water_heater(hpxml_doc, ["storage water heater", "natural gas", "living space", 50, 0.575])
      _check_hot_water_distribution(hpxml_doc, "Standard", 0.0, 89.28, nil, nil, nil, nil)
      _check_water_fixtures(hpxml_doc, false, false)
      _check_drain_water_heat_recovery(hpxml_doc, false, nil, nil, nil)
    end
  end

  def test_water_heating_tank_heat_pump
    hpxml_name = "base-dhw-tank-heat-pump.xml"

    # Reference Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_water_heater(hpxml_doc, ["storage water heater", "electricity", "living space", 80, 0.8644])
    _check_hot_water_distribution(hpxml_doc, "Standard", 0.0, 93.5, nil, nil, nil, nil)
    _check_water_fixtures(hpxml_doc, false, false)
    _check_drain_water_heat_recovery(hpxml_doc, false, nil, nil, nil)

    # Rated Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_water_heater(hpxml_doc, ["heat pump water heater", "electricity", "living space", 80, 2.3])
    _check_hot_water_distribution(hpxml_doc, "Standard", 0.0, 90, nil, nil, nil, nil)
    _check_water_fixtures(hpxml_doc, true, false)
    _check_drain_water_heat_recovery(hpxml_doc, false, nil, nil, nil)

    # IAD, IAD Reference
    calc_types = [Constants.CalcTypeERIIndexAdjustmentDesign,
                  Constants.CalcTypeERIIndexAdjustmentReferenceHome]
    calc_types.each do |calc_type|
      hpxml_doc = _test_measure(hpxml_name, calc_type)
      _check_water_heater(hpxml_doc, ["storage water heater", "electricity", "living space", 80, 0.8644])
      _check_hot_water_distribution(hpxml_doc, "Standard", 0.0, 89.28, nil, nil, nil, nil)
      _check_water_fixtures(hpxml_doc, false, false)
      _check_drain_water_heat_recovery(hpxml_doc, false, nil, nil, nil)
    end
  end

  def test_water_heating_tankless_electric
    hpxml_name = "base-dhw-tankless-electric.xml"

    # Reference Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_water_heater(hpxml_doc, ["storage water heater", "electricity", "living space", 40, 0.9172])
    _check_hot_water_distribution(hpxml_doc, "Standard", 0.0, 93.5, nil, nil, nil, nil)
    _check_water_fixtures(hpxml_doc, false, false)
    _check_drain_water_heat_recovery(hpxml_doc, false, nil, nil, nil)

    # Rated Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_water_heater(hpxml_doc, ["instantaneous water heater", "electricity", "living space", nil, 0.99])
    _check_hot_water_distribution(hpxml_doc, "Standard", 0.0, 90, nil, nil, nil, nil)
    _check_water_fixtures(hpxml_doc, true, false)
    _check_drain_water_heat_recovery(hpxml_doc, false, nil, nil, nil)

    # IAD, IAD Reference
    calc_types = [Constants.CalcTypeERIIndexAdjustmentDesign,
                  Constants.CalcTypeERIIndexAdjustmentReferenceHome]
    calc_types.each do |calc_type|
      hpxml_doc = _test_measure(hpxml_name, calc_type)
      _check_water_heater(hpxml_doc, ["storage water heater", "electricity", "living space", 40, 0.9172])
      _check_hot_water_distribution(hpxml_doc, "Standard", 0.0, 89.28, nil, nil, nil, nil)
      _check_water_fixtures(hpxml_doc, false, false)
      _check_drain_water_heat_recovery(hpxml_doc, false, nil, nil, nil)
    end
  end

  def test_water_heating_tankless_gas
    hpxml_name = "base-dhw-tankless-gas.xml"

    # Reference Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_water_heater(hpxml_doc, ["storage water heater", "natural gas", "living space", 40, 0.594])
    _check_hot_water_distribution(hpxml_doc, "Standard", 0.0, 93.5, nil, nil, nil, nil)
    _check_water_fixtures(hpxml_doc, false, false)
    _check_drain_water_heat_recovery(hpxml_doc, false, nil, nil, nil)

    # Rated Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_water_heater(hpxml_doc, ["instantaneous water heater", "natural gas", "living space", nil, 0.82])
    _check_hot_water_distribution(hpxml_doc, "Standard", 0.0, 90, nil, nil, nil, nil)
    _check_water_fixtures(hpxml_doc, true, false)
    _check_drain_water_heat_recovery(hpxml_doc, false, nil, nil, nil)

    # IAD, IAD Reference
    calc_types = [Constants.CalcTypeERIIndexAdjustmentDesign,
                  Constants.CalcTypeERIIndexAdjustmentReferenceHome]
    calc_types.each do |calc_type|
      hpxml_doc = _test_measure(hpxml_name, calc_type)
      _check_water_heater(hpxml_doc, ["storage water heater", "natural gas", "living space", 40, 0.594])
      _check_hot_water_distribution(hpxml_doc, "Standard", 0.0, 89.28, nil, nil, nil, nil)
      _check_water_fixtures(hpxml_doc, false, false)
      _check_drain_water_heat_recovery(hpxml_doc, false, nil, nil, nil)
    end
  end

  def test_multiple_water_heating
    hpxml_name = "base-dhw-multiple.xml"

    # Reference Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_water_heater(hpxml_doc, ["storage water heater", "electricity", "living space", 40, 0.9172],
                        ["storage water heater", "natural gas", "living space", 50, 0.575],
                        ["storage water heater", "electricity", "living space", 80, 0.8644],
                        ["storage water heater", "electricity", "living space", 40, 0.9172],
                        ["storage water heater", "natural gas", "living space", 40, 0.594],
                        ["storage water heater", "natural gas", "living space", 50, 0.575])
    _check_hot_water_distribution(hpxml_doc, "Standard", 0.0, 93.5, nil, nil, nil, nil)
    _check_water_fixtures(hpxml_doc, false, false)
    _check_drain_water_heat_recovery(hpxml_doc, false, nil, nil, nil)

    # Rated Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_water_heater(hpxml_doc, ["storage water heater", "electricity", "living space", 40, 0.95],
                        ["storage water heater", "natural gas", "living space", 50, 0.59],
                        ["heat pump water heater", "electricity", "living space", 80, 2.3],
                        ["instantaneous water heater", "electricity", "living space", nil, 0.99],
                        ["instantaneous water heater", "natural gas", "living space", nil, 0.82],
                        ["space-heating boiler with storage tank", nil, "living space", 50, nil])
    _check_hot_water_distribution(hpxml_doc, "Standard", 0.0, 90, nil, nil, nil, nil)
    _check_water_fixtures(hpxml_doc, true, false)
    _check_drain_water_heat_recovery(hpxml_doc, false, nil, nil, nil)

    # IAD, IAD Reference
    calc_types = [Constants.CalcTypeERIIndexAdjustmentDesign,
                  Constants.CalcTypeERIIndexAdjustmentReferenceHome]
    calc_types.each do |calc_type|
      hpxml_doc = _test_measure(hpxml_name, calc_type)
      _check_water_heater(hpxml_doc, ["storage water heater", "electricity", "living space", 40, 0.9172],
                          ["storage water heater", "natural gas", "living space", 50, 0.575],
                          ["storage water heater", "electricity", "living space", 80, 0.8644],
                          ["storage water heater", "electricity", "living space", 40, 0.9172],
                          ["storage water heater", "natural gas", "living space", 40, 0.594],
                          ["storage water heater", "natural gas", "living space", 50, 0.575])
      _check_hot_water_distribution(hpxml_doc, "Standard", 0.0, 89.28, nil, nil, nil, nil)
      _check_water_fixtures(hpxml_doc, false, false)
      _check_drain_water_heat_recovery(hpxml_doc, false, nil, nil, nil)
    end
  end

  def test_indirect_water_heating
    hpxml_name = "base-dhw-indirect.xml"

    # Reference Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_water_heater(hpxml_doc, ["storage water heater", "natural gas", "living space", 50, 0.575])
    _check_hot_water_distribution(hpxml_doc, "Standard", 0.0, 93.5, nil, nil, nil, nil)
    _check_water_fixtures(hpxml_doc, false, false)
    _check_drain_water_heat_recovery(hpxml_doc, false, nil, nil, nil)

    # Rated Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_water_heater(hpxml_doc, ["space-heating boiler with storage tank", nil, "living space", 50, nil])
    _check_hot_water_distribution(hpxml_doc, "Standard", 0.0, 90, nil, nil, nil, nil)
    _check_water_fixtures(hpxml_doc, true, false)
    _check_drain_water_heat_recovery(hpxml_doc, false, nil, nil, nil)

    # IAD, IAD Reference
    calc_types = [Constants.CalcTypeERIIndexAdjustmentDesign,
                  Constants.CalcTypeERIIndexAdjustmentReferenceHome]
    calc_types.each do |calc_type|
      hpxml_doc = _test_measure(hpxml_name, calc_type)
      _check_water_heater(hpxml_doc, ["storage water heater", "natural gas", "living space", 50, 0.575])
      _check_hot_water_distribution(hpxml_doc, "Standard", 0.0, 89.28, nil, nil, nil, nil)
      _check_water_fixtures(hpxml_doc, false, false)
      _check_drain_water_heat_recovery(hpxml_doc, false, nil, nil, nil)
    end
  end

  def test_indirect_tankless_coil
    hpxml_name = "base-dhw-combi-tankless.xml"

    # Reference Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_water_heater(hpxml_doc, ["storage water heater", "natural gas", "living space", 40, 0.594])
    _check_hot_water_distribution(hpxml_doc, "Standard", 0.0, 93.5, nil, nil, nil, nil)
    _check_water_fixtures(hpxml_doc, false, false)
    _check_drain_water_heat_recovery(hpxml_doc, false, nil, nil, nil)

    # Rated Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_water_heater(hpxml_doc, ["space-heating boiler with tankless coil", nil, "living space", nil, nil])
    _check_hot_water_distribution(hpxml_doc, "Standard", 0.0, 90, nil, nil, nil, nil)
    _check_water_fixtures(hpxml_doc, true, false)
    _check_drain_water_heat_recovery(hpxml_doc, false, nil, nil, nil)

    # IAD, IAD Reference
    calc_types = [Constants.CalcTypeERIIndexAdjustmentDesign,
                  Constants.CalcTypeERIIndexAdjustmentReferenceHome]
    calc_types.each do |calc_type|
      hpxml_doc = _test_measure(hpxml_name, calc_type)
      _check_water_heater(hpxml_doc, ["storage water heater", "natural gas", "living space", 40, 0.594])
      _check_hot_water_distribution(hpxml_doc, "Standard", 0.0, 89.28, nil, nil, nil, nil)
      _check_water_fixtures(hpxml_doc, false, false)
      _check_drain_water_heat_recovery(hpxml_doc, false, nil, nil, nil)
    end
  end

  def test_water_heating_none
    hpxml_name = "base-dhw-none.xml"

    # Reference Home, Rated Home
    calc_types = [Constants.CalcTypeERIReferenceHome,
                  Constants.CalcTypeERIRatedHome]
    calc_types.each do |calc_type|
      hpxml_doc = _test_measure(hpxml_name, calc_type)
      _check_water_heater(hpxml_doc, ["storage water heater", "natural gas", "living space", 40, 0.594])
      _check_hot_water_distribution(hpxml_doc, "Standard", 0.0, 93.5, nil, nil, nil, nil)
      _check_water_fixtures(hpxml_doc, false, false)
      _check_drain_water_heat_recovery(hpxml_doc, false, nil, nil, nil)
    end

    # IAD, IAD Reference
    calc_types = [Constants.CalcTypeERIIndexAdjustmentDesign,
                  Constants.CalcTypeERIIndexAdjustmentReferenceHome]
    calc_types.each do |calc_type|
      hpxml_doc = _test_measure(hpxml_name, calc_type)
      _check_water_heater(hpxml_doc, ["storage water heater", "natural gas", "living space", 40, 0.594])
      _check_hot_water_distribution(hpxml_doc, "Standard", 0.0, 89.28, nil, nil, nil, nil)
      _check_water_fixtures(hpxml_doc, false, false)
      _check_drain_water_heat_recovery(hpxml_doc, false, nil, nil, nil)
    end
  end

  def test_water_heating_uef
    hpxml_name = "base-dhw-uef.xml"

    # Reference Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_water_heater(hpxml_doc, ["storage water heater", "electricity", "living space", 40, 0.9172])
    _check_hot_water_distribution(hpxml_doc, "Standard", 0.0, 93.5, nil, nil, nil, nil)
    _check_water_fixtures(hpxml_doc, false, false)
    _check_drain_water_heat_recovery(hpxml_doc, false, nil, nil, nil)

    # Rated Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_water_heater(hpxml_doc, ["storage water heater", "electricity", "living space", 40, 0.95])
    _check_hot_water_distribution(hpxml_doc, "Standard", 0.0, 90, nil, nil, nil, nil)
    _check_water_fixtures(hpxml_doc, true, false)
    _check_drain_water_heat_recovery(hpxml_doc, false, nil, nil, nil)

    # IAD, IAD Reference
    calc_types = [Constants.CalcTypeERIIndexAdjustmentDesign,
                  Constants.CalcTypeERIIndexAdjustmentReferenceHome]
    calc_types.each do |calc_type|
      hpxml_doc = _test_measure(hpxml_name, calc_type)
      _check_water_heater(hpxml_doc, ["storage water heater", "electricity", "living space", 40, 0.9172])
      _check_hot_water_distribution(hpxml_doc, "Standard", 0.0, 89.28, nil, nil, nil, nil)
      _check_water_fixtures(hpxml_doc, false, false)
      _check_drain_water_heat_recovery(hpxml_doc, false, nil, nil, nil)
    end
  end

  def test_water_heating_pre_addendum_a
    hpxml_name = "base-addenda-exclude-g-e-a.xml"

    # Reference Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_water_heater(hpxml_doc, ["storage water heater", "electricity", "living space", 40, 0.9172])
    _check_hot_water_distribution(hpxml_doc, "Standard", 0.0, 93.5, nil, nil, nil, nil)
    _check_water_fixtures(hpxml_doc, false, false)
    _check_drain_water_heat_recovery(hpxml_doc, false, nil, nil, nil)

    # Rated Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_water_heater(hpxml_doc, ["storage water heater", "electricity", "living space", 40, 0.95])
    _check_hot_water_distribution(hpxml_doc, "Standard", 0.0, 90, nil, nil, nil, nil)
    _check_water_fixtures(hpxml_doc, true, false)
    _check_drain_water_heat_recovery(hpxml_doc, false, nil, nil, nil)

    # IAD, IAD Reference
    calc_types = [Constants.CalcTypeERIIndexAdjustmentDesign,
                  Constants.CalcTypeERIIndexAdjustmentReferenceHome]
    calc_types.each do |calc_type|
      hpxml_doc = _test_measure(hpxml_name, calc_type)
      _check_water_heater(hpxml_doc, ["storage water heater", "electricity", "living space", 40, 0.9172])
      _check_hot_water_distribution(hpxml_doc, "Standard", 0.0, 89.28, nil, nil, nil, nil)
      _check_water_fixtures(hpxml_doc, false, false)
      _check_drain_water_heat_recovery(hpxml_doc, false, nil, nil, nil)
    end
  end

  def _test_measure(hpxml_name, calc_type)
    args_hash = {}
    args_hash['hpxml_path'] = File.join(@root_path, "workflow", "sample_files", hpxml_name)
    args_hash['weather_dir'] = File.join(@root_path, "weather")
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
    # show_output(result)

    # assert that it ran correctly
    assert_equal("Success", result.value.valueName)
    assert(File.exists? args_hash['hpxml_output_path'])

    hpxml_doc = REXML::Document.new(File.read(args_hash['hpxml_output_path']))
    File.delete(args_hash['hpxml_output_path'])

    return hpxml_doc
  end

  def _check_water_heater(hpxml_doc, *systems)
    assert_equal(systems.size, hpxml_doc.elements["count(/HPXML/Building/BuildingDetails/Systems/WaterHeating/WaterHeatingSystem)"])
    hpxml_doc.elements.each_with_index("/HPXML/Building/BuildingDetails/Systems/WaterHeating/WaterHeatingSystem") do |wh, idx|
      whtype, fuel_type, location, tank_vol, ef = systems[idx]
      assert_equal(wh.elements["WaterHeaterType"].text, whtype)
      assert_equal(wh.elements["Location"].text, location)
      if fuel_type.nil?
        assert_nil(wh.elements["FuelType"])
      else
        assert_equal(wh.elements["FuelType"].text, fuel_type)
      end
      if tank_vol.nil?
        assert_nil(wh.elements["TankVolume"])
      else
        assert_in_epsilon(Float(wh.elements["TankVolume"].text), tank_vol, 0.01)
      end
      if ef.nil?
        assert_nil(wh.elements["EnergyFactor"])
      else
        assert_in_epsilon(Float(wh.elements["EnergyFactor"].text), ef, 0.01)
      end
    end
  end

  def _check_hot_water_distribution(hpxml_doc, disttype, pipe_r, pipe_l, recirc_control, recirc_loop_l, recirc_branch_l, recirc_pump_power)
    dist = hpxml_doc.elements["/HPXML/Building/BuildingDetails/Systems/WaterHeating/HotWaterDistribution"]
    refute_nil(dist.elements["SystemType/#{disttype}"])
    assert_in_epsilon(Float(dist.elements["PipeInsulation/PipeRValue"].text), pipe_r, 0.01)
    if pipe_l.nil?
      assert_nil(dist.elements["SystemType/Standard/PipingLength"])
    else
      assert_in_epsilon(Float(dist.elements["SystemType/Standard/PipingLength"].text), pipe_l, 0.01)
    end
    if recirc_control.nil?
      assert_nil(dist.elements["SystemType/Recirculation/ControlType"])
    else
      assert_equal(dist.elements["SystemType/Recirculation/ControlType"].text, recirc_control)
    end
    if recirc_loop_l.nil?
      assert_nil(dist.elements["SystemType/Recirculation/RecirculationPipingLoopLength"])
    else
      assert_in_epsilon(Float(dist.elements["SystemType/Recirculation/RecirculationPipingLoopLength"].text), recirc_loop_l, 0.01)
    end
    if recirc_branch_l.nil?
      assert_nil(dist.elements["SystemType/Recirculation/BranchPipingLoopLength"])
    else
      assert_in_epsilon(Float(dist.elements["SystemType/Recirculation/BranchPipingLoopLength"].text), recirc_branch_l, 0.01)
    end
    if recirc_pump_power.nil?
      assert_nil(dist.elements["SystemType/Recirculation/PumpPower"])
    else
      assert_in_epsilon(Float(dist.elements["SystemType/Recirculation/PumpPower"].text), recirc_pump_power, 0.01)
    end
  end

  def _check_water_fixtures(hpxml_doc, low_flow_shower, low_flow_faucet)
    wh = hpxml_doc.elements["/HPXML/Building/BuildingDetails/Systems/WaterHeating"]
    assert_equal(Boolean(wh.elements["WaterFixture[WaterFixtureType='shower head']/LowFlow"].text), low_flow_shower)
    assert_equal(Boolean(wh.elements["WaterFixture[WaterFixtureType='faucet']/LowFlow"].text), low_flow_faucet)
  end

  def _check_drain_water_heat_recovery(hpxml_doc, present, facilities_connected, equal_flow, efficiency)
    dist = hpxml_doc.elements["/HPXML/Building/BuildingDetails/Systems/WaterHeating/HotWaterDistribution"]
    assert_equal(!dist.elements["DrainWaterHeatRecovery"].nil?, present)
    if facilities_connected.nil?
      assert_nil(dist.elements["DrainWaterHeatRecovery/FacilitiesConnected"])
    else
      assert_equal(dist.elements["DrainWaterHeatRecovery/FacilitiesConnected"].text, facilities_connected)
    end
    if equal_flow.nil?
      assert_nil(dist.elements["DrainWaterHeatRecovery/EqualFlow"])
    else
      assert_equal(Boolean(dist.elements["DrainWaterHeatRecovery/EqualFlow"].text), equal_flow)
    end
    if efficiency.nil?
      assert_nil(dist.elements["DrainWaterHeatRecovery/Efficiency"])
    else
      assert_equal(Float(dist.elements["DrainWaterHeatRecovery/Efficiency"].text), efficiency)
    end
  end
end
