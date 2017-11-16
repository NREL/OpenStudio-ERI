require_relative '../../../test/minitest_helper'
require 'openstudio'
require 'openstudio/ruleset/ShowRunnerOutput'
require 'minitest/autorun'
require_relative '../measure.rb'
require 'fileutils'

# TODO: Merge with simulation tests

class EnergyRatingIndex301Test < MiniTest::Test

  def get_args_hash(hpxml_filename, calc_type)
    args_hash = {}
    args_hash["hpxml_file_path"] = "../../workflow/sample_files/#{hpxml_filename}"
    args_hash["weather_file_path"] = "../../resources/measures/ResidentialLocation/resources/USA_CO_Denver_Intl_AP_725650_TMY3.epw"
    args_hash["calc_type"] = calc_type
    args_hash["measures_dir"] = "../../resources/measures"
    args_hash["schemas_dir"] = "../../hpxml_schemas"
    args_hash["hpxml_output_file_path"] = File.join(File.dirname(__FILE__), "#{calc_type} - #{hpxml_filename}")
    args_hash["osm_output_file_path"] = File.join(File.dirname(__FILE__), "#{calc_type} - #{hpxml_filename.gsub(".xml", ".osm")}")
    return args_hash
  end

  def test_hpxml_home
    hpxml = "valid.xml"

    # Reference Home
    args_hash = get_args_hash(hpxml, "HERS Reference Home")
    expected_num_del_objects = {}
    expected_num_new_objects = {}
    expected_values = {}
    result, details = _test_measure(nil, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)
    _test_for_hpxml_furnace(details, "natural gas", 0.78, 1.0)
    _test_for_hpxml_air_conditioner(details, "central air conditioning", 13.0, nil, 1.0)
    _test_for_hpxml_dse(details, 0.8)
    
    # Rated Home
    args_hash = get_args_hash(hpxml, "HERS Rated Home")
    expected_num_del_objects = {}
    expected_num_new_objects = {}
    expected_values = {}
    result, details = _test_measure(nil, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)
    _test_for_hpxml_furnace(details, "natural gas", 0.92, 1.0)
    _test_for_hpxml_air_conditioner(details, "central air conditioning", 16.0, nil, 1.0)
    _test_for_hpxml_ducts(details)
  end

  def test_hpxml_home_foundation_unconditioned_basement
    hpxml = "valid-foundation-unconditioned-basement.xml"

    # Reference Home
    args_hash = get_args_hash(hpxml, "HERS Reference Home")
    expected_num_del_objects = {}
    expected_num_new_objects = {}
    expected_values = {}
    result, details = _test_measure(nil, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)
    _test_for_hpxml_furnace(details, "natural gas", 0.78, 1.0)
    _test_for_hpxml_air_conditioner(details, "central air conditioning", 13.0, nil, 1.0)
    _test_for_hpxml_dse(details, 0.8)
    
    # Rated Home
    args_hash = get_args_hash(hpxml, "HERS Rated Home")
    expected_num_del_objects = {}
    expected_num_new_objects = {}
    expected_values = {}
    result, details = _test_measure(nil, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)
    _test_for_hpxml_furnace(details, "natural gas", 0.92, 1.0)
    _test_for_hpxml_air_conditioner(details, "central air conditioning", 16.0, nil, 1.0)
    _test_for_hpxml_ducts(details)
  end

  def test_hpxml_home_foundation_vented_crawlspace
    hpxml = "valid-foundation-vented-crawlspace.xml"

    # Reference Home
    args_hash = get_args_hash(hpxml, "HERS Reference Home")
    expected_num_del_objects = {}
    expected_num_new_objects = {}
    expected_values = {}
    result, details = _test_measure(nil, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)
    _test_for_hpxml_furnace(details, "natural gas", 0.78, 1.0)
    _test_for_hpxml_air_conditioner(details, "central air conditioning", 13.0, nil, 1.0)
    _test_for_hpxml_dse(details, 0.8)
    
    # Rated Home
    args_hash = get_args_hash(hpxml, "HERS Rated Home")
    expected_num_del_objects = {}
    expected_num_new_objects = {}
    expected_values = {}
    result, details = _test_measure(nil, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)
    _test_for_hpxml_furnace(details, "natural gas", 0.92, 1.0)
    _test_for_hpxml_air_conditioner(details, "central air conditioning", 16.0, nil, 1.0)
    _test_for_hpxml_ducts(details)
  end

  def test_hpxml_home_foundation_slab
    hpxml = "valid-foundation-slab.xml"

    # Reference Home
    args_hash = get_args_hash(hpxml, "HERS Reference Home")
    expected_num_del_objects = {}
    expected_num_new_objects = {}
    expected_values = {}
    result, details = _test_measure(nil, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)
    _test_for_hpxml_furnace(details, "natural gas", 0.78, 1.0)
    _test_for_hpxml_air_conditioner(details, "central air conditioning", 13.0, nil, 1.0)
    _test_for_hpxml_dse(details, 0.8)
    
    # Rated Home
    args_hash = get_args_hash(hpxml, "HERS Rated Home")
    expected_num_del_objects = {}
    expected_num_new_objects = {}
    expected_values = {}
    result, details = _test_measure(nil, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)
    _test_for_hpxml_furnace(details, "natural gas", 0.92, 1.0)
    _test_for_hpxml_air_conditioner(details, "central air conditioning", 16.0, nil, 1.0)
    _test_for_hpxml_ducts(details)
  end

  def test_hpxml_home_hvac_central_ac_only
    hpxml = "valid-hvac-central-ac-only.xml"

    # Reference Home
    args_hash = get_args_hash(hpxml, "HERS Reference Home")
    expected_num_del_objects = {}
    expected_num_new_objects = {}
    expected_values = {}
    result, details = _test_measure(nil, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)
    _test_for_hpxml_furnace(details, "natural gas", 0.78, 1.0)
    _test_for_hpxml_air_conditioner(details, "central air conditioning", 13.0, nil, 1.0)
    _test_for_hpxml_dse(details, 0.8)
    
    # Rated Home
    args_hash = get_args_hash(hpxml, "HERS Rated Home")
    expected_num_del_objects = {}
    expected_num_new_objects = {}
    expected_values = {}
    result, details = _test_measure(nil, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)
    _test_for_hpxml_furnace(details, "natural gas", 0.78, 1.0)
    _test_for_hpxml_air_conditioner(details, "central air conditioning", 16.0, nil, 1.0)
    _test_for_hpxml_ducts(details)
  end

  def test_hpxml_home_hvac_furnace_gas_only
    hpxml = "valid-hvac-furnace-gas-only.xml"

    # Reference Home
    args_hash = get_args_hash(hpxml, "HERS Reference Home")
    expected_num_del_objects = {}
    expected_num_new_objects = {}
    expected_values = {}
    result, details = _test_measure(nil, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)
    _test_for_hpxml_furnace(details, "natural gas", 0.78, 1.0)
    _test_for_hpxml_air_conditioner(details, "central air conditioning", 13.0, nil, 1.0)
    _test_for_hpxml_dse(details, 0.8)
    
    # Rated Home
    args_hash = get_args_hash(hpxml, "HERS Rated Home")
    expected_num_del_objects = {}
    expected_num_new_objects = {}
    expected_values = {}
    result, details = _test_measure(nil, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)
    _test_for_hpxml_furnace(details, "natural gas", 0.92, 1.0)
    _test_for_hpxml_air_conditioner(details, "central air conditioning", 13.0, nil, 1.0)
    _test_for_hpxml_ducts(details)
  end
  
  def test_hpxml_home_hvac_furnace_elec_only
    hpxml = "valid-hvac-furnace-elec-only.xml"

    # Reference Home
    args_hash = get_args_hash(hpxml, "HERS Reference Home")
    expected_num_del_objects = {}
    expected_num_new_objects = {}
    expected_values = {}
    result, details = _test_measure(nil, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)
    _test_for_hpxml_heat_pump(details, "air-to-air", 7.7, nil, 1.0, nil, nil, nil)
    _test_for_hpxml_air_conditioner(details, "central air conditioning", 13.0, nil, 1.0)
    _test_for_hpxml_dse(details, 0.8)
    
    # Rated Home
    args_hash = get_args_hash(hpxml, "HERS Rated Home")
    expected_num_del_objects = {}
    expected_num_new_objects = {}
    expected_values = {}
    result, details = _test_measure(nil, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)
    _test_for_hpxml_furnace(details, "electricity", 1.0, 1.0)
    _test_for_hpxml_air_conditioner(details, "central air conditioning", 13.0, nil, 1.0)
    _test_for_hpxml_ducts(details)
  end
  
  def test_hpxml_home_hvac_air_to_air_heat_pump
    hpxml = "valid-hvac-air-to-air-heat-pump.xml"

    # Reference Home
    args_hash = get_args_hash(hpxml, "HERS Reference Home")
    expected_num_del_objects = {}
    expected_num_new_objects = {}
    expected_values = {}
    result, details = _test_measure(nil, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)
    _test_for_hpxml_heat_pump(details, "air-to-air", 7.7, nil, 1.0, nil, nil, nil)
    _test_for_hpxml_air_conditioner(details, "central air conditioning", 13.0, nil, 1.0)
    _test_for_hpxml_dse(details, 0.8)
    
    # Rated Home
    args_hash = get_args_hash(hpxml, "HERS Rated Home")
    expected_num_del_objects = {}
    expected_num_new_objects = {}
    expected_values = {}
    result, details = _test_measure(nil, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)
    _test_for_hpxml_heat_pump(details, "air-to-air", 10.0, nil, 1.0, 19.0, nil, 1.0)
    _test_for_hpxml_ducts(details)
  end
  
  def test_hpxml_home_hvac_none
    hpxml = "valid-hvac-none.xml"

    # Reference Home
    args_hash = get_args_hash(hpxml, "HERS Reference Home")
    expected_num_del_objects = {}
    expected_num_new_objects = {}
    expected_values = {}
    result, details = _test_measure(nil, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)
    _test_for_hpxml_furnace(details, "natural gas", 0.78, 1.0)
    _test_for_hpxml_air_conditioner(details, "central air conditioning", 13.0, nil, 1.0)
    _test_for_hpxml_dse(details, 0.8)
    
    # Rated Home
    args_hash = get_args_hash(hpxml, "HERS Rated Home")
    expected_num_del_objects = {}
    expected_num_new_objects = {}
    expected_values = {}
    result, details = _test_measure(nil, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)
    _test_for_hpxml_furnace(details, "natural gas", 0.78, 1.0)
    _test_for_hpxml_air_conditioner(details, "central air conditioning", 13.0, nil, 1.0)
    _test_for_hpxml_ducts(details)
  end
  
  def test_hpxml_home_hvac_none_no_fuel_access
    hpxml = "valid-hvac-none-no-fuel-access.xml"

    # Reference Home
    args_hash = get_args_hash(hpxml, "HERS Reference Home")
    expected_num_del_objects = {}
    expected_num_new_objects = {}
    expected_values = {}
    result, details = _test_measure(nil, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)
    _test_for_hpxml_heat_pump(details, "air-to-air", 7.7, nil, 1.0, nil, nil, nil)
    _test_for_hpxml_air_conditioner(details, "central air conditioning", 13.0, nil, 1.0)
    _test_for_hpxml_dse(details, 0.8)
    
    # Rated Home
    args_hash = get_args_hash(hpxml, "HERS Rated Home")
    expected_num_del_objects = {}
    expected_num_new_objects = {}
    expected_values = {}
    result, details = _test_measure(nil, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)
    _test_for_hpxml_heat_pump(details, "air-to-air", 7.7, nil, 1.0, nil, nil, nil)
    _test_for_hpxml_air_conditioner(details, "central air conditioning", 13.0, nil, 1.0)
    _test_for_hpxml_ducts(details)
  end
  
  def test_hpxml_home_hvac_boiler_gas_only
    hpxml = "valid-hvac-boiler-gas-only.xml"

    # Reference Home
    args_hash = get_args_hash(hpxml, "HERS Reference Home")
    expected_num_del_objects = {}
    expected_num_new_objects = {}
    expected_values = {}
    result, details = _test_measure(nil, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)
    _test_for_hpxml_boiler(details, "natural gas", 0.80, 1.0)
    _test_for_hpxml_air_conditioner(details, "central air conditioning", 13.0, nil, 1.0)
    _test_for_hpxml_dse(details, 0.8)
    
    # Rated Home
    args_hash = get_args_hash(hpxml, "HERS Rated Home")
    expected_num_del_objects = {}
    expected_num_new_objects = {}
    expected_values = {}
    result, details = _test_measure(nil, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)
    _test_for_hpxml_boiler(details, "natural gas", 0.92, 1.0)
    _test_for_hpxml_air_conditioner(details, "central air conditioning", 13.0, nil, 1.0)
    _test_for_hpxml_ducts(details)
  end
  
  def test_hpxml_home_hvac_boiler_elec_only
    hpxml = "valid-hvac-boiler-elec-only.xml"

    # Reference Home
    args_hash = get_args_hash(hpxml, "HERS Reference Home")
    expected_num_del_objects = {}
    expected_num_new_objects = {}
    expected_values = {}
    result, details = _test_measure(nil, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)
    _test_for_hpxml_heat_pump(details, "air-to-air", 7.7, nil, 1.0, nil, nil, nil)
    _test_for_hpxml_air_conditioner(details, "central air conditioning", 13.0, nil, 1.0)
    _test_for_hpxml_dse(details, 0.8)
    
    # Rated Home
    args_hash = get_args_hash(hpxml, "HERS Rated Home")
    expected_num_del_objects = {}
    expected_num_new_objects = {}
    expected_values = {}
    result, details = _test_measure(nil, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)
    _test_for_hpxml_boiler(details, "electricity", 1.0, 1.0)
    _test_for_hpxml_air_conditioner(details, "central air conditioning", 13.0, nil, 1.0)
    _test_for_hpxml_ducts(details)
  end
  
  def test_hpxml_home_hvac_elec_resistance_only
    hpxml = "valid-hvac-elec-resistance-only.xml"

    # Reference Home
    args_hash = get_args_hash(hpxml, "HERS Reference Home")
    expected_num_del_objects = {}
    expected_num_new_objects = {}
    expected_values = {}
    result, details = _test_measure(nil, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)
    _test_for_hpxml_heat_pump(details, "air-to-air", 7.7, nil, 1.0, nil, nil, nil)
    _test_for_hpxml_air_conditioner(details, "central air conditioning", 13.0, nil, 1.0)
    _test_for_hpxml_dse(details, 0.8)
    
    # Rated Home
    args_hash = get_args_hash(hpxml, "HERS Rated Home")
    expected_num_del_objects = {}
    expected_num_new_objects = {}
    expected_values = {}
    result, details = _test_measure(nil, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)
    _test_for_hpxml_elec_resistance(details, 1.0, 1.0)
    _test_for_hpxml_air_conditioner(details, "central air conditioning", 13.0, nil, 1.0)
    _test_for_hpxml_ducts(details)
  end

  def test_hpxml_home_hvac_ground_to_air_heat_pump
    hpxml = "valid-hvac-ground-to-air-heat-pump.xml"

    # Reference Home
    args_hash = get_args_hash(hpxml, "HERS Reference Home")
    expected_num_del_objects = {}
    expected_num_new_objects = {}
    expected_values = {}
    result, details = _test_measure(nil, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)
    _test_for_hpxml_heat_pump(details, "air-to-air", 7.7, nil, 1.0, nil, nil, nil)
    _test_for_hpxml_air_conditioner(details, "central air conditioning", 13.0, nil, 1.0)
    _test_for_hpxml_dse(details, 0.8)
    
    # Rated Home
    args_hash = get_args_hash(hpxml, "HERS Rated Home")
    expected_num_del_objects = {}
    expected_num_new_objects = {}
    expected_values = {}
    result, details = _test_measure(nil, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)
    _test_for_hpxml_heat_pump(details, "ground-to-air", nil, 3.6, 1.0, nil, 16.6, 1.0)
    _test_for_hpxml_ducts(details)
  end

  def test_hpxml_home_hvac_mini_split_heat_pump
    hpxml = "valid-hvac-mini-split-heat-pump.xml"

    # Reference Home
    args_hash = get_args_hash(hpxml, "HERS Reference Home")
    expected_num_del_objects = {}
    expected_num_new_objects = {}
    expected_values = {}
    result, details = _test_measure(nil, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)
    _test_for_hpxml_heat_pump(details, "air-to-air", 7.7, nil, 1.0, nil, nil, nil)
    _test_for_hpxml_air_conditioner(details, "central air conditioning", 13.0, nil, 1.0)
    _test_for_hpxml_dse(details, 0.8)
    
    # Rated Home
    args_hash = get_args_hash(hpxml, "HERS Rated Home")
    expected_num_del_objects = {}
    expected_num_new_objects = {}
    expected_values = {}
    result, details = _test_measure(nil, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)
    _test_for_hpxml_heat_pump(details, "mini-split", 10.0, nil, 1.0, 19.0, nil, 1.0)
    _test_for_hpxml_ducts(details)
  end
  
  def test_hpxml_home_hvac_room_ac_only
    hpxml = "valid-hvac-room-ac-only.xml"

    # Reference Home
    args_hash = get_args_hash(hpxml, "HERS Reference Home")
    expected_num_del_objects = {}
    expected_num_new_objects = {}
    expected_values = {}
    result, details = _test_measure(nil, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)
    _test_for_hpxml_furnace(details, "natural gas", 0.78, 1.0)
    _test_for_hpxml_air_conditioner(details, "central air conditioning", 13.0, nil, 1.0)
    _test_for_hpxml_dse(details, 0.8)
    
    # Rated Home
    args_hash = get_args_hash(hpxml, "HERS Rated Home")
    expected_num_del_objects = {}
    expected_num_new_objects = {}
    expected_values = {}
    result, details = _test_measure(nil, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)
    _test_for_hpxml_furnace(details, "natural gas", 0.78, 1.0)
    _test_for_hpxml_air_conditioner(details, "room air conditioner", nil, 8.5, 1.0)
    _test_for_hpxml_ducts(details)
  end

  private
  
  def _test_for_hpxml_furnace(details, fueltype, afue, loadfrac)
    assert(XMLHelper.has_element(details, "Systems/HVAC/HVACPlant/HeatingSystem/HeatingSystemType/Furnace"))
    assert_equal(fueltype, XMLHelper.get_value(details, "Systems/HVAC/HVACPlant/HeatingSystem/HeatingSystemFuel"))
    assert_equal(afue, Float(XMLHelper.get_value(details, "Systems/HVAC/HVACPlant/HeatingSystem/AnnualHeatingEfficiency[Units='AFUE']/Value")))
    assert_equal(loadfrac, Float(XMLHelper.get_value(details, "Systems/HVAC/HVACPlant/HeatingSystem/FractionHeatLoadServed")))
  end
  
  def _test_for_hpxml_air_conditioner(details, actype, seer, eer, loadfrac)
    assert(XMLHelper.has_element(details, "Systems/HVAC/HVACPlant/CoolingSystem"))
    assert_equal(actype, XMLHelper.get_value(details, "Systems/HVAC/HVACPlant/CoolingSystem/CoolingSystemType"))
    if not seer.nil?
      assert_equal(seer, Float(XMLHelper.get_value(details, "Systems/HVAC/HVACPlant/CoolingSystem/AnnualCoolingEfficiency[Units='SEER']/Value")))
    end
    if not eer.nil?
      assert_equal(eer, Float(XMLHelper.get_value(details, "Systems/HVAC/HVACPlant/CoolingSystem/AnnualCoolingEfficiency[Units='EER']/Value")))
    end
    assert_equal(loadfrac, Float(XMLHelper.get_value(details, "Systems/HVAC/HVACPlant/CoolingSystem/FractionCoolLoadServed")))
  end
  
  def _test_for_hpxml_heat_pump(details, hptype, hspf, cop, heatloadfrac, seer, eer, coolloadfrac)
    assert(XMLHelper.has_element(details, "Systems/HVAC/HVACPlant/HeatPump"))
    assert_equal(hptype, XMLHelper.get_value(details, "Systems/HVAC/HVACPlant/HeatPump/HeatPumpType"))
    if not hspf.nil?
      assert_equal(hspf, Float(XMLHelper.get_value(details, "Systems/HVAC/HVACPlant/HeatPump/AnnualHeatEfficiency[Units='HSPF']/Value")))
    end
    if not cop.nil?
      assert_equal(cop, Float(XMLHelper.get_value(details, "Systems/HVAC/HVACPlant/HeatPump/AnnualHeatEfficiency[Units='COP']/Value")))
    end
    if not heatloadfrac.nil?
      assert_equal(heatloadfrac, Float(XMLHelper.get_value(details, "Systems/HVAC/HVACPlant/HeatPump/FractionHeatLoadServed")))
    end
    if not seer.nil?
      assert_equal(seer, Float(XMLHelper.get_value(details, "Systems/HVAC/HVACPlant/HeatPump/AnnualCoolEfficiency[Units='SEER']/Value")))
    end
    if not eer.nil?
      assert_equal(eer, Float(XMLHelper.get_value(details, "Systems/HVAC/HVACPlant/HeatPump/AnnualCoolEfficiency[Units='EER']/Value")))
    end
    if not coolloadfrac.nil?
      assert_equal(coolloadfrac, Float(XMLHelper.get_value(details, "Systems/HVAC/HVACPlant/HeatPump/FractionCoolLoadServed")))
    end
  end
  
  def _test_for_hpxml_boiler(details, fueltype, afue, loadfrac)
    assert(XMLHelper.has_element(details, "Systems/HVAC/HVACPlant/HeatingSystem/HeatingSystemType/Boiler"))
    assert_equal(fueltype, XMLHelper.get_value(details, "Systems/HVAC/HVACPlant/HeatingSystem/HeatingSystemFuel"))
    assert_equal(afue, Float(XMLHelper.get_value(details, "Systems/HVAC/HVACPlant/HeatingSystem/AnnualHeatingEfficiency[Units='AFUE']/Value")))
    assert_equal(loadfrac, Float(XMLHelper.get_value(details, "Systems/HVAC/HVACPlant/HeatingSystem/FractionHeatLoadServed")))
  end
  
  def _test_for_hpxml_elec_resistance(details, percent, loadfrac)
    assert(XMLHelper.has_element(details, "Systems/HVAC/HVACPlant/HeatingSystem/HeatingSystemType/ElectricResistance"))
    assert_equal("electricity", XMLHelper.get_value(details, "Systems/HVAC/HVACPlant/HeatingSystem/HeatingSystemFuel"))
    assert_equal(percent, Float(XMLHelper.get_value(details, "Systems/HVAC/HVACPlant/HeatingSystem/AnnualHeatingEfficiency[Units='Percent']/Value")))
    assert_equal(loadfrac, Float(XMLHelper.get_value(details, "Systems/HVAC/HVACPlant/HeatingSystem/FractionHeatLoadServed")))
  end
  
  def _test_for_hpxml_ducts(details)
    # TODO
  end
  
  def _test_for_hpxml_dse(details, dse)
    assert_equal(dse, Float(XMLHelper.get_value(details, "Systems/HVAC/HVACDistribution/AnnualHeatingDistributionSystemEfficiency")))
    assert_equal(dse, Float(XMLHelper.get_value(details, "Systems/HVAC/HVACDistribution/AnnualCoolingDistributionSystemEfficiency")))
  end
  
  def _test_error_or_NA(osm_file_or_model, args_hash)
    # create an instance of the measure
    measure = EnergyRatingIndex301.new

    # create an instance of a runner
    runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)

    model = get_model(File.dirname(__FILE__), osm_file_or_model)

    # get arguments
    arguments = measure.arguments(model)
    argument_map = OpenStudio::Measure.convertOSArgumentVectorToMap(arguments)

    # populate argument with specified hash value if specified
    arguments.each do |arg|
      temp_arg_var = arg.clone
      if args_hash[arg.name]
        assert(temp_arg_var.setValue(args_hash[arg.name]))
      end
      argument_map[arg.name] = temp_arg_var
    end

    # run the measure
    measure.run(model, runner, argument_map)
    result = runner.result
      
    return result
    
  end
  
  def _test_measure(osm_file_or_model, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, num_infos=0, num_warnings=0, debug=false)
    # create an instance of the measure
    measure = EnergyRatingIndex301.new

    # check for standard methods
    assert(!measure.name.empty?)
    assert(!measure.description.empty?)
    assert(!measure.modeler_description.empty?)

    # create an instance of a runner
    runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)
    
    model = get_model(File.dirname(__FILE__), osm_file_or_model)

    # get the initial objects in the model
    initial_objects = get_objects(model)
    
    # get arguments
    arguments = measure.arguments(model)
    argument_map = OpenStudio::Measure.convertOSArgumentVectorToMap(arguments)

    # populate argument with specified hash value if specified
    arguments.each do |arg|
      temp_arg_var = arg.clone
      if args_hash[arg.name]
        assert(temp_arg_var.setValue(args_hash[arg.name]))
      end
      argument_map[arg.name] = temp_arg_var
    end

    # run the measure
    measure.run(model, runner, argument_map)
    result = runner.result
    
    show_output(result)

    # assert that it ran correctly
    puts result.errors.map{ |x| x.logMessage }
    assert_equal("Success", result.value.valueName)
    #assert(result.info.size == num_infos)
    #assert(result.warnings.size == num_warnings)
    
    # get the final objects in the model
    final_objects = get_objects(model)
    
    # get new and deleted objects
    obj_type_exclusions = []
    all_new_objects = get_object_additions(initial_objects, final_objects, obj_type_exclusions)
    all_del_objects = get_object_additions(final_objects, initial_objects, obj_type_exclusions)
    
    # check we have the expected number of new/deleted objects
    #check_num_objects(all_new_objects, expected_num_new_objects, "added")
    #check_num_objects(all_del_objects, expected_num_del_objects, "deleted")

    all_new_objects.each do |obj_type, new_objects|
        new_objects.each do |new_object|
            next if not new_object.respond_to?("to_#{obj_type}")
            new_object = new_object.public_send("to_#{obj_type}").get
        end
    end
    
    hpxml_doc = REXML::Document.new(File.new(args_hash["hpxml_output_file_path"]))
    details = hpxml_doc.elements["//Building/BuildingDetails"]
    
    return result, details
  end

end
