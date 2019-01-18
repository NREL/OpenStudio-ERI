require_relative '../../../workflow/tests/minitest_helper'
require 'openstudio'
require 'openstudio/ruleset/ShowRunnerOutput'
require 'minitest/autorun'
require_relative '../measure.rb'
require 'fileutils'

class HVACtest < MiniTest::Test
  def _dse(calc_type)
    if calc_type == Constants.CalcTypeERIIndexAdjustmentDesign
      dse = 1.0
    else
      dse = 0.8
    end
  end

  def test_none
    hpxml_name = "valid-hvac-none.xml"

    # Reference Home, Rated Home, IAD, IAD Reference
    calc_types = [Constants.CalcTypeERIReferenceHome,
                  Constants.CalcTypeERIRatedHome,
                  Constants.CalcTypeERIIndexAdjustmentDesign,
                  Constants.CalcTypeERIIndexAdjustmentReferenceHome]
    calc_types.each do |calc_type|
      hpxml_doc = _test_measure(hpxml_name, calc_type)
      _check_heating_system(hpxml_doc, ["Furnace", "natural gas", 0.78, 1.0, _dse(calc_type)])
      _check_cooling_system(hpxml_doc, ["central air conditioning", "electricity", 13, 1.0, _dse(calc_type)])
      _check_heat_pump(hpxml_doc)
      _check_thermostat(hpxml_doc, "manual thermostat")
    end
  end

  def test_none_with_no_fuel_access
    hpxml_name = "valid-hvac-none-no-fuel-access.xml"

    # Reference Home, Rated Home IAD, IAD Reference
    calc_types = [Constants.CalcTypeERIReferenceHome,
                  Constants.CalcTypeERIRatedHome,
                  Constants.CalcTypeERIIndexAdjustmentDesign,
                  Constants.CalcTypeERIIndexAdjustmentReferenceHome]
    calc_types.each do |calc_type|
      hpxml_doc = _test_measure(hpxml_name, calc_type)
      _check_heat_pump(hpxml_doc, ["air-to-air", "electricity", 7.7, nil, 1.0, 0.0, _dse(calc_type)])
      _check_cooling_system(hpxml_doc, ["central air conditioning", "electricity", 13, 1.0, _dse(calc_type)])
      _check_heating_system(hpxml_doc)
      _check_thermostat(hpxml_doc, "manual thermostat")
    end
  end

  def test_boiler_elec
    hpxml_name = "valid-hvac-boiler-elec-only.xml"

    # Reference Home, IAD, IAD Reference
    calc_types = [Constants.CalcTypeERIReferenceHome,
                  Constants.CalcTypeERIIndexAdjustmentDesign,
                  Constants.CalcTypeERIIndexAdjustmentReferenceHome]
    calc_types.each do |calc_type|
      hpxml_doc = _test_measure(hpxml_name, calc_type)
      _check_heat_pump(hpxml_doc, ["air-to-air", "electricity", 7.7, nil, 1.0, 0.0, _dse(calc_type)])
      _check_cooling_system(hpxml_doc, ["central air conditioning", "electricity", 13, 1.0, _dse(calc_type)])
      _check_heating_system(hpxml_doc)
      _check_thermostat(hpxml_doc, "manual thermostat")
    end

    # Rated Home
    calc_type = Constants.CalcTypeERIRatedHome
    hpxml_doc = _test_measure(hpxml_name, calc_type)
    _check_heating_system(hpxml_doc, ["Boiler", "electricity", nil, 1.0, nil])
    _check_cooling_system(hpxml_doc, ["central air conditioning", "electricity", 13, 1.0, _dse(calc_type)])
    _check_heat_pump(hpxml_doc)
    _check_thermostat(hpxml_doc, "manual thermostat")
  end

  def test_boiler_gas
    hpxml_name = "valid-hvac-boiler-gas-only.xml"

    # Reference Home, IAD, IAD Reference
    calc_types = [Constants.CalcTypeERIReferenceHome,
                  Constants.CalcTypeERIIndexAdjustmentDesign,
                  Constants.CalcTypeERIIndexAdjustmentReferenceHome]
    calc_types.each do |calc_type|
      hpxml_doc = _test_measure(hpxml_name, calc_type)
      _check_heating_system(hpxml_doc, ["Boiler", "natural gas", 0.80, 1.0, _dse(calc_type)])
      _check_cooling_system(hpxml_doc, ["central air conditioning", "electricity", 13, 1.0, _dse(calc_type)])
      _check_heat_pump(hpxml_doc)
      _check_thermostat(hpxml_doc, "manual thermostat")
    end

    # Rated Home
    calc_type = Constants.CalcTypeERIRatedHome
    hpxml_doc = _test_measure(hpxml_name, calc_type)
    _check_heating_system(hpxml_doc, ["Boiler", "natural gas", nil, 1.0, nil])
    _check_cooling_system(hpxml_doc, ["central air conditioning", "electricity", 13, 1.0, _dse(calc_type)])
    _check_heat_pump(hpxml_doc)
    _check_thermostat(hpxml_doc, "manual thermostat")
  end

  def test_furnace_elec
    hpxml_name = "valid-hvac-furnace-elec-only.xml"

    # Reference Home, IAD, IAD Reference
    calc_types = [Constants.CalcTypeERIReferenceHome,
                  Constants.CalcTypeERIIndexAdjustmentDesign,
                  Constants.CalcTypeERIIndexAdjustmentReferenceHome]
    calc_types.each do |calc_type|
      hpxml_doc = _test_measure(hpxml_name, calc_type)
      _check_heat_pump(hpxml_doc, ["air-to-air", "electricity", 7.7, nil, 1.0, 0.0, _dse(calc_type)])
      _check_cooling_system(hpxml_doc, ["central air conditioning", "electricity", 13, 1.0, _dse(calc_type)])
      _check_heating_system(hpxml_doc)
      _check_thermostat(hpxml_doc, "manual thermostat")
    end

    # Rated Home
    calc_type = Constants.CalcTypeERIRatedHome
    hpxml_doc = _test_measure(hpxml_name, calc_type)
    _check_heating_system(hpxml_doc, ["Furnace", "electricity", nil, 1.0, nil])
    _check_cooling_system(hpxml_doc, ["central air conditioning", "electricity", 13, 1.0, _dse(calc_type)])
    _check_heat_pump(hpxml_doc)
    _check_thermostat(hpxml_doc, "manual thermostat")
  end

  def test_furnace_gas
    hpxml_name = "valid-hvac-furnace-gas-only.xml"

    # Reference Home, IAD, IAD Reference
    calc_types = [Constants.CalcTypeERIReferenceHome,
                  Constants.CalcTypeERIIndexAdjustmentDesign,
                  Constants.CalcTypeERIIndexAdjustmentReferenceHome]
    calc_types.each do |calc_type|
      hpxml_doc = _test_measure(hpxml_name, calc_type)
      _check_heating_system(hpxml_doc, ["Furnace", "natural gas", 0.78, 1.0, _dse(calc_type)])
      _check_cooling_system(hpxml_doc, ["central air conditioning", "electricity", 13, 1.0, _dse(calc_type)])
      _check_heat_pump(hpxml_doc)
      _check_thermostat(hpxml_doc, "manual thermostat")
    end

    # Rated Home
    calc_type = Constants.CalcTypeERIRatedHome
    hpxml_doc = _test_measure(hpxml_name, calc_type)
    _check_heating_system(hpxml_doc, ["Furnace", "natural gas", nil, 1.0, nil])
    _check_cooling_system(hpxml_doc, ["central air conditioning", "electricity", 13, 1.0, _dse(calc_type)])
    _check_heat_pump(hpxml_doc)
    _check_thermostat(hpxml_doc, "manual thermostat")
  end

  def test_stove_oil
    hpxml_name = "valid-hvac-stove-oil-only.xml"

    # Reference Home, IAD, IAD Reference
    calc_types = [Constants.CalcTypeERIReferenceHome,
                  Constants.CalcTypeERIIndexAdjustmentDesign,
                  Constants.CalcTypeERIIndexAdjustmentReferenceHome]
    calc_types.each do |calc_type|
      hpxml_doc = _test_measure(hpxml_name, calc_type)
      _check_heating_system(hpxml_doc, ["Furnace", "natural gas", 0.78, 1.0, _dse(calc_type)])
      _check_cooling_system(hpxml_doc, ["central air conditioning", "electricity", 13, 1.0, _dse(calc_type)])
      _check_heat_pump(hpxml_doc)
      _check_thermostat(hpxml_doc, "manual thermostat")
    end

    # Rated Home
    calc_type = Constants.CalcTypeERIRatedHome
    hpxml_doc = _test_measure(hpxml_name, calc_type)
    _check_heating_system(hpxml_doc, ["Stove", "fuel oil", nil, 1.0, nil])
    _check_cooling_system(hpxml_doc, ["central air conditioning", "electricity", 13, 1.0, _dse(calc_type)])
    _check_heat_pump(hpxml_doc)
    _check_thermostat(hpxml_doc, "manual thermostat")
  end

  def test_wall_furnace_propane
    hpxml_name = "valid-hvac-wall-furnace-propane-only.xml"

    # Reference Home, IAD, IAD Reference
    calc_types = [Constants.CalcTypeERIReferenceHome,
                  Constants.CalcTypeERIIndexAdjustmentDesign,
                  Constants.CalcTypeERIIndexAdjustmentReferenceHome]
    calc_types.each do |calc_type|
      hpxml_doc = _test_measure(hpxml_name, calc_type)
      _check_heating_system(hpxml_doc, ["Furnace", "natural gas", 0.78, 1.0, _dse(calc_type)])
      _check_cooling_system(hpxml_doc, ["central air conditioning", "electricity", 13, 1.0, _dse(calc_type)])
      _check_heat_pump(hpxml_doc)
      _check_thermostat(hpxml_doc, "manual thermostat")
    end

    # Rated Home
    calc_type = Constants.CalcTypeERIRatedHome
    hpxml_doc = _test_measure(hpxml_name, calc_type)
    _check_heating_system(hpxml_doc, ["WallFurnace", "propane", nil, 1.0, nil])
    _check_cooling_system(hpxml_doc, ["central air conditioning", "electricity", 13, 1.0, _dse(calc_type)])
    _check_heat_pump(hpxml_doc)
    _check_thermostat(hpxml_doc, "manual thermostat")
  end

  def test_elec_resistance
    hpxml_name = "valid-hvac-elec-resistance-only.xml"

    # Reference Home, IAD, IAD Reference
    calc_types = [Constants.CalcTypeERIReferenceHome,
                  Constants.CalcTypeERIIndexAdjustmentDesign,
                  Constants.CalcTypeERIIndexAdjustmentReferenceHome]
    calc_types.each do |calc_type|
      hpxml_doc = _test_measure(hpxml_name, calc_type)
      _check_heat_pump(hpxml_doc, ["air-to-air", "electricity", 7.7, nil, 1.0, 0.0, _dse(calc_type)])
      _check_cooling_system(hpxml_doc, ["central air conditioning", "electricity", 13, 1.0, _dse(calc_type)])
      _check_heating_system(hpxml_doc)
      _check_thermostat(hpxml_doc, "manual thermostat")
    end

    # Rated Home
    calc_type = Constants.CalcTypeERIRatedHome
    hpxml_doc = _test_measure(hpxml_name, calc_type)
    _check_heating_system(hpxml_doc, ["ElectricResistance", "electricity", nil, 1.0, nil])
    _check_cooling_system(hpxml_doc, ["central air conditioning", "electricity", 13, 1.0, _dse(calc_type)])
    _check_heat_pump(hpxml_doc)
    _check_thermostat(hpxml_doc, "manual thermostat")
  end

  def test_air_source_heat_pump
    hpxml_name = "valid-hvac-air-to-air-heat-pump-1-speed.xml"

    # Reference Home, IAD, IAD Reference
    calc_types = [Constants.CalcTypeERIReferenceHome,
                  Constants.CalcTypeERIIndexAdjustmentDesign,
                  Constants.CalcTypeERIIndexAdjustmentReferenceHome]
    calc_types.each do |calc_type|
      hpxml_doc = _test_measure(hpxml_name, calc_type)
      _check_heat_pump(hpxml_doc, ["air-to-air", "electricity", 7.7, nil, 1.0, 0.0, _dse(calc_type)])
      _check_cooling_system(hpxml_doc, ["central air conditioning", "electricity", 13, 1.0, _dse(calc_type)])
      _check_heating_system(hpxml_doc)
      _check_thermostat(hpxml_doc, "manual thermostat")
    end

    # Rated Home
    calc_type = Constants.CalcTypeERIRatedHome
    hpxml_doc = _test_measure(hpxml_name, calc_type)
    _check_heat_pump(hpxml_doc, ["air-to-air", "electricity", nil, nil, 1.0, 1.0, nil])
    _check_cooling_system(hpxml_doc)
    _check_heating_system(hpxml_doc)
    _check_thermostat(hpxml_doc, "manual thermostat")
  end

  def test_mini_split_heat_pump_ducted
    hpxml_name = "valid-hvac-mini-split-heat-pump-ducted.xml"

    # Reference Home, IAD, IAD Reference
    calc_types = [Constants.CalcTypeERIReferenceHome,
                  Constants.CalcTypeERIIndexAdjustmentDesign,
                  Constants.CalcTypeERIIndexAdjustmentReferenceHome]
    calc_types.each do |calc_type|
      hpxml_doc = _test_measure(hpxml_name, calc_type)
      _check_heat_pump(hpxml_doc, ["air-to-air", "electricity", 7.7, nil, 1.0, 0.0, _dse(calc_type)])
      _check_cooling_system(hpxml_doc, ["central air conditioning", "electricity", 13, 1.0, _dse(calc_type)])
      _check_heating_system(hpxml_doc)
      _check_thermostat(hpxml_doc, "manual thermostat")
    end

    # Rated Home
    calc_type = Constants.CalcTypeERIRatedHome
    hpxml_doc = _test_measure(hpxml_name, calc_type)
    _check_heat_pump(hpxml_doc, ["mini-split", "electricity", nil, nil, 1.0, 1.0, nil])
    _check_cooling_system(hpxml_doc)
    _check_heating_system(hpxml_doc)
    _check_thermostat(hpxml_doc, "manual thermostat")
  end

  def test_mini_split_heat_pump_ductless
    hpxml_name = "valid-hvac-mini-split-heat-pump-ductless.xml"

    # Reference Home, IAD, IAD Reference
    calc_types = [Constants.CalcTypeERIReferenceHome,
                  Constants.CalcTypeERIIndexAdjustmentDesign,
                  Constants.CalcTypeERIIndexAdjustmentReferenceHome]
    calc_types.each do |calc_type|
      hpxml_doc = _test_measure(hpxml_name, calc_type)
      _check_heat_pump(hpxml_doc, ["air-to-air", "electricity", 7.7, nil, 1.0, 0.0, _dse(calc_type)])
      _check_cooling_system(hpxml_doc, ["central air conditioning", "electricity", 13, 1.0, _dse(calc_type)])
      _check_heating_system(hpxml_doc)
      _check_thermostat(hpxml_doc, "manual thermostat")
    end

    # Rated Home
    calc_type = Constants.CalcTypeERIRatedHome
    hpxml_doc = _test_measure(hpxml_name, calc_type)
    _check_heat_pump(hpxml_doc, ["mini-split", "electricity", nil, nil, 1.0, 1.0, nil])
    _check_cooling_system(hpxml_doc)
    _check_heating_system(hpxml_doc)
    _check_thermostat(hpxml_doc, "manual thermostat")
  end

  def test_ground_source_heat_pump
    hpxml_name = "valid-hvac-ground-to-air-heat-pump.xml"

    # Reference Home, IAD, IAD Reference
    calc_types = [Constants.CalcTypeERIReferenceHome,
                  Constants.CalcTypeERIIndexAdjustmentDesign,
                  Constants.CalcTypeERIIndexAdjustmentReferenceHome]
    calc_types.each do |calc_type|
      hpxml_doc = _test_measure(hpxml_name, calc_type)
      _check_heat_pump(hpxml_doc, ["air-to-air", "electricity", 7.7, nil, 1.0, 0.0, _dse(calc_type)])
      _check_cooling_system(hpxml_doc, ["central air conditioning", "electricity", 13, 1.0, _dse(calc_type)])
      _check_heating_system(hpxml_doc)
      _check_thermostat(hpxml_doc, "manual thermostat")
    end

    # Rated Home
    calc_type = Constants.CalcTypeERIRatedHome
    hpxml_doc = _test_measure(hpxml_name, calc_type)
    _check_heat_pump(hpxml_doc, ["ground-to-air", "electricity", nil, nil, 1.0, 1.0, nil])
    _check_cooling_system(hpxml_doc)
    _check_heating_system(hpxml_doc)
    _check_thermostat(hpxml_doc, "manual thermostat")
  end

  def test_central_air_conditioner
    hpxml_name = "valid-hvac-central-ac-only-1-speed.xml"

    # Reference Home, IAD, IAD Reference
    calc_types = [Constants.CalcTypeERIReferenceHome,
                  Constants.CalcTypeERIIndexAdjustmentDesign,
                  Constants.CalcTypeERIIndexAdjustmentReferenceHome]
    calc_types.each do |calc_type|
      hpxml_doc = _test_measure(hpxml_name, calc_type)
      _check_cooling_system(hpxml_doc, ["central air conditioning", "electricity", 13, 1.0, _dse(calc_type)])
      _check_heating_system(hpxml_doc, ["Furnace", "natural gas", 0.78, 1.0, _dse(calc_type)])
      _check_heat_pump(hpxml_doc)
      _check_thermostat(hpxml_doc, "manual thermostat")
    end

    # Rated Home
    calc_type = Constants.CalcTypeERIRatedHome
    hpxml_doc = _test_measure(hpxml_name, calc_type)
    _check_cooling_system(hpxml_doc, ["central air conditioning", "electricity", nil, 1.0, nil])
    _check_heating_system(hpxml_doc, ["Furnace", "natural gas", 0.78, 1.0, _dse(calc_type)])
    _check_heat_pump(hpxml_doc)
    _check_thermostat(hpxml_doc, "manual thermostat")
  end

  def test_room_air_conditioner
    hpxml_name = "valid-hvac-room-ac-only.xml"

    # Reference Home, IAD, IAD Reference
    calc_types = [Constants.CalcTypeERIReferenceHome,
                  Constants.CalcTypeERIIndexAdjustmentDesign,
                  Constants.CalcTypeERIIndexAdjustmentReferenceHome]
    calc_types.each do |calc_type|
      hpxml_doc = _test_measure(hpxml_name, calc_type)
      _check_cooling_system(hpxml_doc, ["central air conditioning", "electricity", 13, 1.0, _dse(calc_type)])
      _check_heating_system(hpxml_doc, ["Furnace", "natural gas", 0.78, 1.0, _dse(calc_type)])
      _check_heat_pump(hpxml_doc)
      _check_thermostat(hpxml_doc, "manual thermostat")
    end

    # Rated Home
    calc_type = Constants.CalcTypeERIRatedHome
    hpxml_doc = _test_measure(hpxml_name, calc_type)
    _check_cooling_system(hpxml_doc, ["room air conditioner", "electricity", nil, 1.0, nil])
    _check_heating_system(hpxml_doc, ["Furnace", "natural gas", 0.78, 1.0, _dse(calc_type)])
    _check_heat_pump(hpxml_doc)
    _check_thermostat(hpxml_doc, "manual thermostat")
  end

  def test_furnace_gas_and_central_air_conditioner
    hpxml_name = "valid.xml"

    # Reference Home, IAD, IAD Reference
    calc_types = [Constants.CalcTypeERIReferenceHome,
                  Constants.CalcTypeERIIndexAdjustmentDesign,
                  Constants.CalcTypeERIIndexAdjustmentReferenceHome]
    calc_types.each do |calc_type|
      hpxml_doc = _test_measure(hpxml_name, calc_type)
      _check_cooling_system(hpxml_doc, ["central air conditioning", "electricity", 13, 1.0, _dse(calc_type)])
      _check_heating_system(hpxml_doc, ["Furnace", "natural gas", 0.78, 1.0, _dse(calc_type)])
      _check_heat_pump(hpxml_doc)
      _check_thermostat(hpxml_doc, "manual thermostat")
    end

    # Rated Home
    calc_type = Constants.CalcTypeERIRatedHome
    hpxml_doc = _test_measure(hpxml_name, calc_type)
    _check_cooling_system(hpxml_doc, ["central air conditioning", "electricity", nil, 1.0, nil])
    _check_heating_system(hpxml_doc, ["Furnace", "natural gas", nil, 1.0, nil])
    _check_heat_pump(hpxml_doc)
    _check_thermostat(hpxml_doc, "manual thermostat")
  end

  def test_furnace_gas_room_air_conditioner
    hpxml_name = "valid-hvac-furnace-gas-room-ac.xml"

    # Reference Home, IAD, IAD Reference
    calc_types = [Constants.CalcTypeERIReferenceHome,
                  Constants.CalcTypeERIIndexAdjustmentDesign,
                  Constants.CalcTypeERIIndexAdjustmentReferenceHome]
    calc_types.each do |calc_type|
      hpxml_doc = _test_measure(hpxml_name, calc_type)
      _check_cooling_system(hpxml_doc, ["central air conditioning", "electricity", 13, 1.0, _dse(calc_type)])
      _check_heating_system(hpxml_doc, ["Furnace", "natural gas", 0.78, 1.0, _dse(calc_type)])
      _check_heat_pump(hpxml_doc)
      _check_thermostat(hpxml_doc, "manual thermostat")
    end

    # Rated Home
    calc_type = Constants.CalcTypeERIRatedHome
    hpxml_doc = _test_measure(hpxml_name, calc_type)
    _check_cooling_system(hpxml_doc, ["room air conditioner", "electricity", nil, 1.0, nil])
    _check_heating_system(hpxml_doc, ["Furnace", "natural gas", nil, 1.0, nil])
    _check_heat_pump(hpxml_doc)
    _check_thermostat(hpxml_doc, "manual thermostat")
  end

  def test_all_hvac
    hpxml_name = "valid-hvac-all.xml"

    # Reference Home, IAD, IAD Reference
    calc_types = [Constants.CalcTypeERIReferenceHome,
                  Constants.CalcTypeERIIndexAdjustmentDesign,
                  Constants.CalcTypeERIIndexAdjustmentReferenceHome]
    calc_types.each do |calc_type|
      hpxml_doc = _test_measure(hpxml_name, calc_type)
      _check_cooling_system(hpxml_doc, ["central air conditioning", "electricity", 13, 0.2, _dse(calc_type)],
                            ["central air conditioning", "electricity", 13, 0.2, _dse(calc_type)],
                            ["central air conditioning", "electricity", 13, 0.2, _dse(calc_type)],
                            ["central air conditioning", "electricity", 13, 0.2, _dse(calc_type)],
                            ["central air conditioning", "electricity", 13, 0.2, _dse(calc_type)])
      _check_heating_system(hpxml_doc, ["Boiler", "natural gas", 0.8, 0.1, _dse(calc_type)],
                            ["Furnace", "natural gas", 0.78, 0.1, _dse(calc_type)],
                            ["Furnace", "natural gas", 0.78, 0.1, _dse(calc_type)],
                            ["Furnace", "natural gas", 0.78, 0.1, _dse(calc_type)])
      _check_heat_pump(hpxml_doc, ["air-to-air", "electricity", 7.7, nil, 0.1, 0.0, _dse(calc_type)],
                       ["air-to-air", "electricity", 7.7, nil, 0.1, 0.0, _dse(calc_type)],
                       ["air-to-air", "electricity", 7.7, nil, 0.1, 0.0, _dse(calc_type)],
                       ["air-to-air", "electricity", 7.7, nil, 0.1, 0.0, _dse(calc_type)],
                       ["air-to-air", "electricity", 7.7, nil, 0.1, 0.0, _dse(calc_type)],
                       ["air-to-air", "electricity", 7.7, nil, 0.1, 0.0, _dse(calc_type)])
      _check_thermostat(hpxml_doc, "manual thermostat")
    end

    # Rated Home
    calc_type = Constants.CalcTypeERIRatedHome
    hpxml_doc = _test_measure(hpxml_name, calc_type)
    _check_cooling_system(hpxml_doc, ["central air conditioning", "electricity", nil, 0.2, nil],
                          ["room air conditioner", "electricity", nil, 0.2, nil])
    _check_heating_system(hpxml_doc, ["Boiler", "electricity", nil, 0.1, nil],
                          ["Boiler", "natural gas", nil, 0.1, nil],
                          ["ElectricResistance", "electricity", nil, 0.1, nil],
                          ["Furnace", "electricity", nil, 0.1, nil],
                          ["Furnace", "natural gas", nil, 0.1, nil],
                          ["Stove", "fuel oil", nil, 0.1, nil],
                          ["WallFurnace", "propane", nil, 0.1, nil])
    _check_heat_pump(hpxml_doc, ["air-to-air", "electricity", nil, nil, 0.1, 0.2, nil],
                     ["ground-to-air", "electricity", nil, nil, 0.1, 0.2, nil],
                     ["mini-split", "electricity", nil, nil, 0.1, 0.2, nil])
    _check_thermostat(hpxml_doc, "manual thermostat")
  end

  def test_programmable_thermostat
    hpxml_name = "valid-hvac-programmable-thermostat.xml"

    # Reference Home, IAD, IAD Reference
    calc_types = [Constants.CalcTypeERIReferenceHome,
                  Constants.CalcTypeERIIndexAdjustmentDesign,
                  Constants.CalcTypeERIIndexAdjustmentReferenceHome]
    calc_types.each do |calc_type|
      hpxml_doc = _test_measure(hpxml_name, calc_type)
      _check_thermostat(hpxml_doc, "manual thermostat")
    end

    # Rated Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_thermostat(hpxml_doc, "programmable thermostat")
  end

  def _test_measure(hpxml_name, calc_type)
    root_path = File.absolute_path(File.join(File.dirname(__FILE__), "..", "..", ".."))
    args_hash = {}
    args_hash['hpxml_path'] = File.join(root_path, "workflow", "sample_files", hpxml_name)
    args_hash['schemas_dir'] = File.join(root_path, "measures", "HPXMLtoOpenStudio", "hpxml_schemas")
    args_hash['weather_dir'] = File.join(root_path, "weather")
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

  def _check_heating_system(hpxml_doc, *systems)
    assert_equal(systems.size, hpxml_doc.elements["count(/HPXML/Building/BuildingDetails/Systems/HVAC/HVACPlant/HeatingSystem)"])
    hpxml_doc.elements.each_with_index("/HPXML/Building/BuildingDetails/Systems/HVAC/HVACPlant/HeatingSystem") do |sys, idx|
      systype, fueltype, afue, frac_load, dse = systems[idx]
      refute_nil(sys.elements["HeatingSystemType/#{systype}"])
      assert_equal(sys.elements["HeatingSystemFuel"].text, fueltype)
      if not afue.nil?
        assert_equal(Float(sys.elements["AnnualHeatingEfficiency[Units='AFUE']/Value"].text), afue)
      end
      assert_equal(Float(sys.elements["FractionHeatLoadServed"].text), frac_load)
      _check_dse(hpxml_doc, sys, dse)
    end
  end

  def _check_heat_pump(hpxml_doc, *systems)
    assert_equal(systems.size, hpxml_doc.elements["count(/HPXML/Building/BuildingDetails/Systems/HVAC/HVACPlant/HeatPump)"])
    hpxml_doc.elements.each_with_index("/HPXML/Building/BuildingDetails/Systems/HVAC/HVACPlant/HeatPump") do |sys, idx|
      systype, fueltype, hspf, seer, frac_load_heat, frac_load_cool, dse = systems[idx]
      assert_equal(sys.elements["HeatPumpType"].text, systype)
      assert_equal(sys.elements["HeatPumpFuel"].text, fueltype)
      if not hspf.nil?
        assert_equal(Float(sys.elements["AnnualHeatingEfficiency[Units='HSPF']/Value"].text), hspf)
      end
      if not seer.nil?
        assert_equal(Float(sys.elements["AnnualHeatingEfficiency[Units='SEER']/Value"].text), seer)
      end
      assert_equal(Float(sys.elements["FractionHeatLoadServed"].text), frac_load_heat)
      assert_equal(Float(sys.elements["FractionCoolLoadServed"].text), frac_load_cool)
      _check_dse(hpxml_doc, sys, dse)
    end
  end

  def _check_cooling_system(hpxml_doc, *systems)
    assert_equal(systems.size, hpxml_doc.elements["count(/HPXML/Building/BuildingDetails/Systems/HVAC/HVACPlant/CoolingSystem)"])
    hpxml_doc.elements.each_with_index("/HPXML/Building/BuildingDetails/Systems/HVAC/HVACPlant/CoolingSystem") do |sys, idx|
      systype, fueltype, seer, frac_load, dse = systems[idx]
      assert_equal(sys.elements["CoolingSystemType"].text, systype)
      assert_equal(sys.elements["CoolingSystemFuel"].text, fueltype)
      if not seer.nil?
        assert_equal(Float(sys.elements["AnnualCoolingEfficiency[Units='SEER']/Value"].text), seer)
      end
      assert_equal(Float(sys.elements["FractionCoolLoadServed"].text), frac_load)
      _check_dse(hpxml_doc, sys, dse)
    end
  end

  def _check_thermostat(hpxml_doc, tstattype)
    tstat = hpxml_doc.elements["/HPXML/Building/BuildingDetails/Systems/HVAC/HVACControl"]
    assert_equal(tstat.elements["ControlType"].text, tstattype)
  end

  def _check_dse(hpxml_doc, sys, dse)
    actual_dse_heat, actual_dse_cool = nil, nil
    hpxml_doc.elements.each("/HPXML/Building/BuildingDetails/Systems/HVAC/HVACDistribution[DistributionSystemType[Other='DSE']]") do |dist_dse|
      next if sys.elements["DistributionSystem"].nil?
      next unless dist_dse.elements["SystemIdentifier"].attributes["id"] == sys.elements["DistributionSystem"].attributes["idref"]

      actual_dse_heat = Float(dist_dse.elements["AnnualHeatingDistributionSystemEfficiency"].text)
      actual_dse_cool = Float(dist_dse.elements["AnnualCoolingDistributionSystemEfficiency"].text)
    end
    if dse.nil?
      assert_nil(actual_dse_heat)
      assert_nil(actual_dse_cool)
    else
      assert_equal(dse, actual_dse_heat)
      assert_equal(dse, actual_dse_cool)
    end
  end
end
