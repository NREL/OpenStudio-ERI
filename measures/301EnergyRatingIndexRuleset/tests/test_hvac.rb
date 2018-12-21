require_relative '../../../workflow/tests/minitest_helper'
require 'openstudio'
require 'openstudio/ruleset/ShowRunnerOutput'
require 'minitest/autorun'
require_relative '../measure.rb'
require 'fileutils'

class HVACtest < MiniTest::Test
  def test_none
    hpxml_name = "valid-hvac-none.xml"

    # Reference Home, Rated Home, IAD, IAD Reference
    calc_types = [Constants.CalcTypeERIReferenceHome,
                  Constants.CalcTypeERIRatedHome,
                  Constants.CalcTypeERIIndexAdjustmentDesign,
                  Constants.CalcTypeERIIndexAdjustmentReferenceHome]
    calc_types.each do |calc_type|
      hpxml_doc = _test_measure(hpxml_name, calc_type)
      _check_heating_system(hpxml_doc, ["Furnace"], ["natural gas"], [0.78], [1.0])
      _check_cooling_system(hpxml_doc, ["central air conditioning"], [13], [1.0])
      _check_heat_pump(hpxml_doc, [], [], [], [], [])
      _check_thermostat(hpxml_doc, "manual thermostat")
      if calc_type == Constants.CalcTypeERIIndexAdjustmentDesign
        _check_dse(hpxml_doc, 1.0)
      else
        _check_dse(hpxml_doc, 0.8)
      end
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
      _check_heat_pump(hpxml_doc, ["air-to-air"], [7.7], [nil], [1.0], [0.0])
      _check_cooling_system(hpxml_doc, ["central air conditioning"], [13], [1.0])
      _check_heating_system(hpxml_doc, [], [], [], [])
      _check_thermostat(hpxml_doc, "manual thermostat")
      if calc_type == Constants.CalcTypeERIIndexAdjustmentDesign
        _check_dse(hpxml_doc, 1.0)
      else
        _check_dse(hpxml_doc, 0.8)
      end
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
      _check_heat_pump(hpxml_doc, ["air-to-air"], [7.7], [nil], [1.0], [0.0])
      _check_cooling_system(hpxml_doc, ["central air conditioning"], [13], [1.0])
      _check_heating_system(hpxml_doc, [], [], [], [])
      _check_thermostat(hpxml_doc, "manual thermostat")
      if calc_type == Constants.CalcTypeERIIndexAdjustmentDesign
        _check_dse(hpxml_doc, 1.0)
      else
        _check_dse(hpxml_doc, 0.8)
      end
    end

    # Rated Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_heating_system(hpxml_doc, ["Boiler"], ["electricity"], [nil], [1.0])
    _check_cooling_system(hpxml_doc, ["central air conditioning"], [13], [1.0])
    _check_heat_pump(hpxml_doc, [], [], [], [], [])
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
      _check_heating_system(hpxml_doc, ["Boiler"], ["natural gas"], [0.80], [1.0])
      _check_cooling_system(hpxml_doc, ["central air conditioning"], [13], [1.0])
      _check_heat_pump(hpxml_doc, [], [], [], [], [])
      _check_thermostat(hpxml_doc, "manual thermostat")
      if calc_type == Constants.CalcTypeERIIndexAdjustmentDesign
        _check_dse(hpxml_doc, 1.0)
      else
        _check_dse(hpxml_doc, 0.8)
      end
    end

    # Rated Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_heating_system(hpxml_doc, ["Boiler"], ["natural gas"], [nil], [1.0])
    _check_cooling_system(hpxml_doc, ["central air conditioning"], [13], [1.0])
    _check_heat_pump(hpxml_doc, [], [], [], [], [])
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
      _check_heat_pump(hpxml_doc, ["air-to-air"], [7.7], [nil], [1.0], [0.0])
      _check_cooling_system(hpxml_doc, ["central air conditioning"], [13], [1.0])
      _check_heating_system(hpxml_doc, [], [], [], [])
      _check_thermostat(hpxml_doc, "manual thermostat")
      if calc_type == Constants.CalcTypeERIIndexAdjustmentDesign
        _check_dse(hpxml_doc, 1.0)
      else
        _check_dse(hpxml_doc, 0.8)
      end
    end

    # Rated Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_heating_system(hpxml_doc, ["Furnace"], ["electricity"], [nil], [1.0])
    _check_cooling_system(hpxml_doc, ["central air conditioning"], [13], [1.0])
    _check_heat_pump(hpxml_doc, [], [], [], [], [])
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
      _check_heating_system(hpxml_doc, ["Furnace"], ["natural gas"], [0.78], [1.0])
      _check_cooling_system(hpxml_doc, ["central air conditioning"], [13], [1.0])
      _check_heat_pump(hpxml_doc, [], [], [], [], [])
      _check_thermostat(hpxml_doc, "manual thermostat")
      if calc_type == Constants.CalcTypeERIIndexAdjustmentDesign
        _check_dse(hpxml_doc, 1.0)
      else
        _check_dse(hpxml_doc, 0.8)
      end
    end

    # Rated Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_heating_system(hpxml_doc, ["Furnace"], ["natural gas"], [nil], [1.0])
    _check_cooling_system(hpxml_doc, ["central air conditioning"], [13], [1.0])
    _check_heat_pump(hpxml_doc, [], [], [], [], [])
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
      _check_heating_system(hpxml_doc, ["Furnace"], ["natural gas"], [0.78], [1.0])
      _check_cooling_system(hpxml_doc, ["central air conditioning"], [13], [1.0])
      _check_heat_pump(hpxml_doc, [], [], [], [], [])
      _check_thermostat(hpxml_doc, "manual thermostat")
      if calc_type == Constants.CalcTypeERIIndexAdjustmentDesign
        _check_dse(hpxml_doc, 1.0)
      else
        _check_dse(hpxml_doc, 0.8)
      end
    end

    # Rated Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_heating_system(hpxml_doc, ["Stove"], ["fuel oil"], [nil], [1.0])
    _check_cooling_system(hpxml_doc, ["central air conditioning"], [13], [1.0])
    _check_heat_pump(hpxml_doc, [], [], [], [], [])
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
      _check_heating_system(hpxml_doc, ["Furnace"], ["natural gas"], [0.78], [1.0])
      _check_cooling_system(hpxml_doc, ["central air conditioning"], [13], [1.0])
      _check_heat_pump(hpxml_doc, [], [], [], [], [])
      _check_thermostat(hpxml_doc, "manual thermostat")
      if calc_type == Constants.CalcTypeERIIndexAdjustmentDesign
        _check_dse(hpxml_doc, 1.0)
      else
        _check_dse(hpxml_doc, 0.8)
      end
    end

    # Rated Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_heating_system(hpxml_doc, ["WallFurnace"], ["propane"], [nil], [1.0])
    _check_cooling_system(hpxml_doc, ["central air conditioning"], [13], [1.0])
    _check_heat_pump(hpxml_doc, [], [], [], [], [])
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
      _check_heat_pump(hpxml_doc, ["air-to-air"], [7.7], [nil], [1.0], [0.0])
      _check_cooling_system(hpxml_doc, ["central air conditioning"], [13], [1.0])
      _check_heating_system(hpxml_doc, [], [], [], [])
      _check_thermostat(hpxml_doc, "manual thermostat")
      if calc_type == Constants.CalcTypeERIIndexAdjustmentDesign
        _check_dse(hpxml_doc, 1.0)
      else
        _check_dse(hpxml_doc, 0.8)
      end
    end

    # Rated Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_heating_system(hpxml_doc, ["ElectricResistance"], ["electricity"], [nil], [1.0])
    _check_cooling_system(hpxml_doc, ["central air conditioning"], [13], [1.0])
    _check_heat_pump(hpxml_doc, [], [], [], [], [])
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
      _check_heat_pump(hpxml_doc, ["air-to-air"], [7.7], [nil], [1.0], [0.0])
      _check_cooling_system(hpxml_doc, ["central air conditioning"], [13], [1.0])
      _check_heating_system(hpxml_doc, [], [], [], [])
      _check_thermostat(hpxml_doc, "manual thermostat")
      if calc_type == Constants.CalcTypeERIIndexAdjustmentDesign
        _check_dse(hpxml_doc, 1.0)
      else
        _check_dse(hpxml_doc, 0.8)
      end
    end

    # Rated Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_heat_pump(hpxml_doc, ["air-to-air"], [nil], [nil], [1.0], [1.0])
    _check_cooling_system(hpxml_doc, [], [], [])
    _check_heating_system(hpxml_doc, [], [], [], [])
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
      _check_heat_pump(hpxml_doc, ["air-to-air"], [7.7], [nil], [1.0], [0.0])
      _check_cooling_system(hpxml_doc, ["central air conditioning"], [13], [1.0])
      _check_heating_system(hpxml_doc, [], [], [], [])
      _check_thermostat(hpxml_doc, "manual thermostat")
      if calc_type == Constants.CalcTypeERIIndexAdjustmentDesign
        _check_dse(hpxml_doc, 1.0)
      else
        _check_dse(hpxml_doc, 0.8)
      end
    end

    # Rated Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_heat_pump(hpxml_doc, ["mini-split"], [nil], [nil], [1.0], [1.0])
    _check_cooling_system(hpxml_doc, [], [], [])
    _check_heating_system(hpxml_doc, [], [], [], [])
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
      _check_heat_pump(hpxml_doc, ["air-to-air"], [7.7], [nil], [1.0], [0.0])
      _check_cooling_system(hpxml_doc, ["central air conditioning"], [13], [1.0])
      _check_heating_system(hpxml_doc, [], [], [], [])
      _check_thermostat(hpxml_doc, "manual thermostat")
      if calc_type == Constants.CalcTypeERIIndexAdjustmentDesign
        _check_dse(hpxml_doc, 1.0)
      else
        _check_dse(hpxml_doc, 0.8)
      end
    end

    # Rated Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_heat_pump(hpxml_doc, ["mini-split"], [nil], [nil], [1.0], [1.0])
    _check_cooling_system(hpxml_doc, [], [], [])
    _check_heating_system(hpxml_doc, [], [], [], [])
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
      _check_heat_pump(hpxml_doc, ["air-to-air"], [7.7], [nil], [1.0], [0.0])
      _check_cooling_system(hpxml_doc, ["central air conditioning"], [13], [1.0])
      _check_heating_system(hpxml_doc, [], [], [], [])
      _check_thermostat(hpxml_doc, "manual thermostat")
      if calc_type == Constants.CalcTypeERIIndexAdjustmentDesign
        _check_dse(hpxml_doc, 1.0)
      else
        _check_dse(hpxml_doc, 0.8)
      end
    end

    # Rated Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_heat_pump(hpxml_doc, ["ground-to-air"], [nil], [nil], [1.0], [1.0])
    _check_cooling_system(hpxml_doc, [], [], [])
    _check_heating_system(hpxml_doc, [], [], [], [])
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
      _check_cooling_system(hpxml_doc, ["central air conditioning"], [13], [1.0])
      _check_heating_system(hpxml_doc, ["Furnace"], ["natural gas"], [0.78], [1.0])
      _check_heat_pump(hpxml_doc, [], [], [], [], [])
      _check_thermostat(hpxml_doc, "manual thermostat")
      if calc_type == Constants.CalcTypeERIIndexAdjustmentDesign
        _check_dse(hpxml_doc, 1.0)
      else
        _check_dse(hpxml_doc, 0.8)
      end
    end

    # Rated Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_cooling_system(hpxml_doc, ["central air conditioning"], [nil], [1.0])
    _check_heating_system(hpxml_doc, ["Furnace"], ["natural gas"], [0.78], [1.0])
    _check_heat_pump(hpxml_doc, [], [], [], [], [])
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
      _check_cooling_system(hpxml_doc, ["central air conditioning"], [13], [1.0])
      _check_heating_system(hpxml_doc, ["Furnace"], ["natural gas"], [0.78], [1.0])
      _check_heat_pump(hpxml_doc, [], [], [], [], [])
      _check_thermostat(hpxml_doc, "manual thermostat")
      if calc_type == Constants.CalcTypeERIIndexAdjustmentDesign
        _check_dse(hpxml_doc, 1.0)
      else
        _check_dse(hpxml_doc, 0.8)
      end
    end

    # Rated Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_cooling_system(hpxml_doc, ["room air conditioner"], [nil], [1.0])
    _check_heating_system(hpxml_doc, ["Furnace"], ["natural gas"], [0.78], [1.0])
    _check_heat_pump(hpxml_doc, [], [], [], [], [])
    _check_thermostat(hpxml_doc, "manual thermostat")
  end

  # TODO: valid.xml (gas furnace + AC)
  # TODO: valid-hvac-furnace-gas-room-ac.xml
  # TODO: multiple_hvac

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

  def _check_heating_system(hpxml_doc, systypes, fueltypes, afues, frac_loads)
    assert_equal(systypes.size, hpxml_doc.elements["count(/HPXML/Building/BuildingDetails/Systems/HVAC/HVACPlant/HeatingSystem)"])
    hpxml_doc.elements.each_with_index("/HPXML/Building/BuildingDetails/Systems/HVAC/HVACPlant/HeatingSystem") do |sys, idx|
      refute_nil(sys.elements["HeatingSystemType/#{systypes[idx]}"])
      assert_equal(sys.elements["HeatingSystemFuel"].text, fueltypes[idx])
      if not afues[idx].nil?
        assert_equal(Float(sys.elements["AnnualHeatingEfficiency[Units='AFUE']/Value"].text), afues[idx])
      end
      assert_equal(Float(sys.elements["FractionHeatLoadServed"].text), frac_loads[idx])
    end
  end

  def _check_heat_pump(hpxml_doc, systypes, hspfs, seers, frac_load_heats, frac_load_cools)
    assert_equal(systypes.size, hpxml_doc.elements["count(/HPXML/Building/BuildingDetails/Systems/HVAC/HVACPlant/HeatPump)"])
    hpxml_doc.elements.each_with_index("/HPXML/Building/BuildingDetails/Systems/HVAC/HVACPlant/HeatPump") do |sys, idx|
      assert_equal(sys.elements["HeatPumpType"].text, systypes[idx])
      if not hspfs[idx].nil?
        assert_equal(Float(sys.elements["AnnualHeatingEfficiency[Units='HSPF']/Value"].text), hspfs[idx])
      end
      if not seers[idx].nil?
        assert_equal(Float(sys.elements["AnnualHeatingEfficiency[Units='SEER']/Value"].text), seers[idx])
      end
      assert_equal(Float(sys.elements["FractionHeatLoadServed"].text), frac_load_heats[idx])
      assert_equal(Float(sys.elements["FractionCoolLoadServed"].text), frac_load_cools[idx])
    end
  end

  def _check_cooling_system(hpxml_doc, systypes, seers, frac_loads)
    assert_equal(systypes.size, hpxml_doc.elements["count(/HPXML/Building/BuildingDetails/Systems/HVAC/HVACPlant/CoolingSystem)"])
    hpxml_doc.elements.each_with_index("/HPXML/Building/BuildingDetails/Systems/HVAC/HVACPlant/CoolingSystem") do |sys, idx|
      assert_equal(sys.elements["CoolingSystemType"].text, systypes[idx])
      if not seers[idx].nil?
        assert_equal(Float(sys.elements["AnnualCoolingEfficiency[Units='SEER']/Value"].text), seers[idx])
      end
      assert_equal(Float(sys.elements["FractionCoolLoadServed"].text), frac_loads[idx])
    end
  end

  def _check_thermostat(hpxml_doc, tstattype)
    tstat = hpxml_doc.elements["/HPXML/Building/BuildingDetails/Systems/HVAC/HVACControl"]
    assert_equal(tstat.elements["ControlType"].text, tstattype)
  end

  def _check_dse(hpxml_doc, dse)
    dist_dse = hpxml_doc.elements["/HPXML/Building/BuildingDetails/Systems/HVAC/HVACDistribution[DistributionSystemType[Other='DSE']]"]
    assert_equal(Float(dist_dse.elements["AnnualHeatingDistributionSystemEfficiency"].text), dse)
    assert_equal(Float(dist_dse.elements["AnnualCoolingDistributionSystemEfficiency"].text), dse)
  end
end
