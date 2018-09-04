require 'openstudio'
require 'openstudio/ruleset/ShowRunnerOutput'
require 'minitest/autorun'
require_relative '../measure.rb'
require 'fileutils'

# TODO: Test HVACControl
# TODO: Test HVACDistribution
# TODO: Add IAD

class HVACtest < MiniTest::Test

  def test_heating_none
    hpxml_name = "valid-hvac-none.xml"

    # Reference Home, IAD, IAD Reference
    calc_types = [Constants.CalcTypeERIReferenceHome,
                  Constants.CalcTypeERIIndexAdjustmentDesign,
                  Constants.CalcTypeERIIndexAdjustmentReferenceHome]
    calc_types.each do |calc_type|
      hpxml_doc = _test_measure(hpxml_name, calc_type)
      _check_heating_system(hpxml_doc, "Furnace", "natural gas", 0.78)
    end
    
    # Rated Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_heating_system(hpxml_doc, "Furnace", "natural gas", 0.78)
  end
  
  def test_heating_none_with_no_fuel_access
    hpxml_name = "valid-hvac-none-no-fuel-access.xml"

    # Reference Home, IAD, IAD Reference
    calc_types = [Constants.CalcTypeERIReferenceHome,
                  Constants.CalcTypeERIIndexAdjustmentDesign,
                  Constants.CalcTypeERIIndexAdjustmentReferenceHome]
    calc_types.each do |calc_type|
      hpxml_doc = _test_measure(hpxml_name, calc_type)
      _check_heat_pump_heating(hpxml_doc, "air-to-air", 7.7)
    end
    
    # Rated Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_heat_pump_heating(hpxml_doc, "air-to-air", 7.7)
  end
  
  def test_heating_boiler_elec
    hpxml_name = "valid-hvac-boiler-elec-only.xml"

    # Reference Home, IAD, IAD Reference
    calc_types = [Constants.CalcTypeERIReferenceHome,
                  Constants.CalcTypeERIIndexAdjustmentDesign,
                  Constants.CalcTypeERIIndexAdjustmentReferenceHome]
    calc_types.each do |calc_type|
      hpxml_doc = _test_measure(hpxml_name, calc_type)
      _check_heat_pump_heating(hpxml_doc, "air-to-air", 7.7)
    end
    
    # Rated Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_heating_system(hpxml_doc, "Boiler", "electricity", nil)
  end
  
  def test_heating_boiler_gas
    hpxml_name = "valid-hvac-boiler-gas-only.xml"

    # Reference Home, IAD, IAD Reference
    calc_types = [Constants.CalcTypeERIReferenceHome,
                  Constants.CalcTypeERIIndexAdjustmentDesign,
                  Constants.CalcTypeERIIndexAdjustmentReferenceHome]
    calc_types.each do |calc_type|
      hpxml_doc = _test_measure(hpxml_name, calc_type)
      _check_heating_system(hpxml_doc, "Boiler", "natural gas", 0.80)
    end
    
    # Rated Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_heating_system(hpxml_doc, "Boiler", "natural gas", nil)
  end
  
  def test_heating_furnace_elec
    hpxml_name = "valid-hvac-furnace-elec-only.xml"

    # Reference Home, IAD, IAD Reference
    calc_types = [Constants.CalcTypeERIReferenceHome,
                  Constants.CalcTypeERIIndexAdjustmentDesign,
                  Constants.CalcTypeERIIndexAdjustmentReferenceHome]
    calc_types.each do |calc_type|
      hpxml_doc = _test_measure(hpxml_name, calc_type)
      _check_heat_pump_heating(hpxml_doc, "air-to-air", 7.7)
    end
    
    # Rated Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_heating_system(hpxml_doc, "Furnace", "electricity", nil)
  end
  
  def test_heating_furnace_gas
    hpxml_name = "valid-hvac-furnace-gas-only.xml"

    # Reference Home, IAD, IAD Reference
    calc_types = [Constants.CalcTypeERIReferenceHome,
                  Constants.CalcTypeERIIndexAdjustmentDesign,
                  Constants.CalcTypeERIIndexAdjustmentReferenceHome]
    calc_types.each do |calc_type|
      hpxml_doc = _test_measure(hpxml_name, calc_type)
      _check_heating_system(hpxml_doc, "Furnace", "natural gas", 0.78)
    end
    
    # Rated Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_heating_system(hpxml_doc, "Furnace", "natural gas", nil)
  end
  
  def test_heating_stove_oil
    hpxml_name = "valid-hvac-stove-oil-only.xml"

    # Reference Home, IAD, IAD Reference
    calc_types = [Constants.CalcTypeERIReferenceHome,
                  Constants.CalcTypeERIIndexAdjustmentDesign,
                  Constants.CalcTypeERIIndexAdjustmentReferenceHome]
    calc_types.each do |calc_type|
      hpxml_doc = _test_measure(hpxml_name, calc_type)
      _check_heating_system(hpxml_doc, "Furnace", "natural gas", 0.78)
    end
    
    # Rated Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_heating_system(hpxml_doc, "Stove", "fuel oil", nil)
  end
  
  def test_heating_wall_furnace_propane
    hpxml_name = "valid-hvac-wall-furnace-propane-only.xml"

    # Reference Home, IAD, IAD Reference
    calc_types = [Constants.CalcTypeERIReferenceHome,
                  Constants.CalcTypeERIIndexAdjustmentDesign,
                  Constants.CalcTypeERIIndexAdjustmentReferenceHome]
    calc_types.each do |calc_type|
      hpxml_doc = _test_measure(hpxml_name, calc_type)
      _check_heating_system(hpxml_doc, "Furnace", "natural gas", 0.78)
    end
    
    # Rated Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_heating_system(hpxml_doc, "WallFurnace", "propane", nil)
  end
  
  def test_heating_elec_resistance
    hpxml_name = "valid-hvac-elec-resistance-only.xml"

    # Reference Home, IAD, IAD Reference
    calc_types = [Constants.CalcTypeERIReferenceHome,
                  Constants.CalcTypeERIIndexAdjustmentDesign,
                  Constants.CalcTypeERIIndexAdjustmentReferenceHome]
    calc_types.each do |calc_type|
      hpxml_doc = _test_measure(hpxml_name, calc_type)
      _check_heat_pump_heating(hpxml_doc, "air-to-air", 7.7)
    end
    
    # Rated Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_heating_system(hpxml_doc, "ElectricResistance", "electricity", nil)
  end
  
  def test_heating_air_source_heat_pump
    hpxml_name = "valid-hvac-air-to-air-heat-pump.xml"

    # Reference Home, IAD, IAD Reference
    calc_types = [Constants.CalcTypeERIReferenceHome,
                  Constants.CalcTypeERIIndexAdjustmentDesign,
                  Constants.CalcTypeERIIndexAdjustmentReferenceHome]
    calc_types.each do |calc_type|
      hpxml_doc = _test_measure(hpxml_name, calc_type)
      _check_heat_pump_heating(hpxml_doc, "air-to-air", 7.7)
    end
    
    # Rated Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_heat_pump_heating(hpxml_doc, "air-to-air", nil)
  end
  
  def test_heating_mini_split_heat_pump
    hpxml_name = "valid-hvac-mini-split-heat-pump.xml"

    # Reference Home, IAD, IAD Reference
    calc_types = [Constants.CalcTypeERIReferenceHome,
                  Constants.CalcTypeERIIndexAdjustmentDesign,
                  Constants.CalcTypeERIIndexAdjustmentReferenceHome]
    calc_types.each do |calc_type|
      hpxml_doc = _test_measure(hpxml_name, calc_type)
      _check_heat_pump_heating(hpxml_doc, "air-to-air", 7.7)
    end
    
    # Rated Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_heat_pump_heating(hpxml_doc, "mini-split", nil)
  end
  
  def test_heating_ground_source_heat_pump
    hpxml_name = "valid-hvac-ground-to-air-heat-pump.xml"

    # Reference Home, IAD, IAD Reference
    calc_types = [Constants.CalcTypeERIReferenceHome,
                  Constants.CalcTypeERIIndexAdjustmentDesign,
                  Constants.CalcTypeERIIndexAdjustmentReferenceHome]
    calc_types.each do |calc_type|
      hpxml_doc = _test_measure(hpxml_name, calc_type)
      _check_heat_pump_heating(hpxml_doc, "air-to-air", 7.7)
    end
    
    # Rated Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_heat_pump_heating(hpxml_doc, "ground-to-air", nil)
  end
  
  def test_cooling_none
    hpxml_name = "valid-hvac-none.xml"

    # Reference Home, IAD, IAD Reference
    calc_types = [Constants.CalcTypeERIReferenceHome,
                  Constants.CalcTypeERIIndexAdjustmentDesign,
                  Constants.CalcTypeERIIndexAdjustmentReferenceHome]
    calc_types.each do |calc_type|
      hpxml_doc = _test_measure(hpxml_name, calc_type)
      _check_cooling_system(hpxml_doc, "central air conditioning", 13)
    end
    
    # Rated Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_cooling_system(hpxml_doc, "central air conditioning", 13)
  end
  
  def test_cooling_central_air_conditioner
    hpxml_name = "valid-hvac-central-ac-only.xml"

    # Reference Home, IAD, IAD Reference
    calc_types = [Constants.CalcTypeERIReferenceHome,
                  Constants.CalcTypeERIIndexAdjustmentDesign,
                  Constants.CalcTypeERIIndexAdjustmentReferenceHome]
    calc_types.each do |calc_type|
      hpxml_doc = _test_measure(hpxml_name, calc_type)
      _check_cooling_system(hpxml_doc, "central air conditioning", 13)
    end
    
    # Rated Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_cooling_system(hpxml_doc, "central air conditioning", nil)
  end
  
  def test_cooling_room_air_conditioner
    hpxml_name = "valid-hvac-room-ac-only.xml"

    # Reference Home, IAD, IAD Reference
    calc_types = [Constants.CalcTypeERIReferenceHome,
                  Constants.CalcTypeERIIndexAdjustmentDesign,
                  Constants.CalcTypeERIIndexAdjustmentReferenceHome]
    calc_types.each do |calc_type|
      hpxml_doc = _test_measure(hpxml_name, calc_type)
      _check_cooling_system(hpxml_doc, "central air conditioning", 13)
    end
    
    # Rated Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_cooling_system(hpxml_doc, "room air conditioner", nil)
  end
  
  def test_cooling_air_source_heat_pump
    hpxml_name = "valid-hvac-air-to-air-heat-pump.xml"

    # Reference Home, IAD, IAD Reference
    calc_types = [Constants.CalcTypeERIReferenceHome,
                  Constants.CalcTypeERIIndexAdjustmentDesign,
                  Constants.CalcTypeERIIndexAdjustmentReferenceHome]
    calc_types.each do |calc_type|
      hpxml_doc = _test_measure(hpxml_name, calc_type)
      _check_cooling_system(hpxml_doc, "central air conditioning", 13)
    end
    
    # Rated Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_heat_pump_cooling(hpxml_doc, "air-to-air")
  end
  
  def test_cooling_mini_split_heat_pump
    hpxml_name = "valid-hvac-mini-split-heat-pump.xml"

    # Reference Home, IAD, IAD Reference
    calc_types = [Constants.CalcTypeERIReferenceHome,
                  Constants.CalcTypeERIIndexAdjustmentDesign,
                  Constants.CalcTypeERIIndexAdjustmentReferenceHome]
    calc_types.each do |calc_type|
      hpxml_doc = _test_measure(hpxml_name, calc_type)
      _check_cooling_system(hpxml_doc, "central air conditioning", 13)
    end
    
    # Rated Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_heat_pump_cooling(hpxml_doc, "mini-split")
  end
  
  def test_cooling_ground_source_heat_pump
    hpxml_name = "valid-hvac-ground-to-air-heat-pump.xml"

    # Reference Home, IAD, IAD Reference
    calc_types = [Constants.CalcTypeERIReferenceHome,
                  Constants.CalcTypeERIIndexAdjustmentDesign,
                  Constants.CalcTypeERIIndexAdjustmentReferenceHome]
    calc_types.each do |calc_type|
      hpxml_doc = _test_measure(hpxml_name, calc_type)
      _check_cooling_system(hpxml_doc, "central air conditioning", 13)
    end
    
    # Rated Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_heat_pump_cooling(hpxml_doc, "ground-to-air")
  end
  
  private
  
  def _test_measure(hpxml_name, calc_type)
    root_path = File.absolute_path(File.join(File.dirname(__FILE__), "..", "..", ".."))
    args_hash = {}
    args_hash['hpxml_path'] = File.join(root_path, "workflow", "sample_files", hpxml_name)
    args_hash['weather_dir'] = File.join(root_path, "weather")
    args_hash['hpxml_output_path'] = File.join(File.dirname(__FILE__), "#{calc_type}.xml")
    args_hash['calc_type'] = calc_type
  
    # create an instance of the measure
    measure = EnergyRatingIndex301.new
    
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
  
  def _check_heating_system(hpxml_doc, systype, fueltype, afue)
    sys = hpxml_doc.elements["/HPXML/Building/BuildingDetails/Systems/HVAC/HVACPlant/HeatingSystem"]
    refute_nil(sys.elements["HeatingSystemType/#{systype}"])
    assert_equal(sys.elements["HeatingSystemFuel"].text, fueltype)
    if not afue.nil?
      assert_equal(Float(sys.elements["AnnualHeatingEfficiency[Units='AFUE']/Value"].text), afue)
    end
    assert(Float(sys.elements["FractionHeatLoadServed"].text) > 0)
  end
  
  def _check_heat_pump_heating(hpxml_doc, systype, hspf)
    sys = hpxml_doc.elements["/HPXML/Building/BuildingDetails/Systems/HVAC/HVACPlant/HeatPump"]
    assert_equal(sys.elements["HeatPumpType"].text, systype)
    if not hspf.nil?
      assert_equal(Float(sys.elements["AnnualHeatingEfficiency[Units='HSPF']/Value"].text), hspf)
    end
    assert(Float(sys.elements["FractionHeatLoadServed"].text) > 0)
  end
  
  def _check_cooling_system(hpxml_doc, systype, seer)
    sys = hpxml_doc.elements["/HPXML/Building/BuildingDetails/Systems/HVAC/HVACPlant/CoolingSystem"]
    assert_equal(sys.elements["CoolingSystemType"].text, systype)
    if not seer.nil?
      assert_equal(Float(sys.elements["AnnualCoolingEfficiency[Units='SEER']/Value"].text), seer)
    end
    assert(Float(sys.elements["FractionCoolLoadServed"].text) > 0)
  end

  def _check_heat_pump_cooling(hpxml_doc, systype)
    sys = hpxml_doc.elements["/HPXML/Building/BuildingDetails/Systems/HVAC/HVACPlant/HeatPump"]
    assert_equal(sys.elements["HeatPumpType"].text, systype)
    assert(Float(sys.elements["FractionCoolLoadServed"].text) > 0)
  end
  
end