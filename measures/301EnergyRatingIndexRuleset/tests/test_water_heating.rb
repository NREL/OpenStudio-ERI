require 'openstudio'
require 'openstudio/ruleset/ShowRunnerOutput'
require 'minitest/autorun'
require_relative '../measure.rb'
require 'fileutils'

class WaterHeatingTest < MiniTest::Test

  def test_water_heating
    hpxml_name = "valid.xml"
    
    # Reference Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_water_heater(hpxml_doc, "storage water heater", "electricity", "conditioned space", 40, 0.9172, 1.0)
    _check_hot_water_distribution(hpxml_doc, "Standard", 17.8, nil, 1.0)
    _check_water_fixtures(hpxml_doc, 54.6, -1044995, 1060325)
    _check_drain_water_heat_recovery(hpxml_doc, false, nil, nil, nil, nil, nil)
    
    # Rated Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_water_heater(hpxml_doc, "storage water heater", "electricity", "conditioned space", 40, 0.95, 1.0)
    _check_hot_water_distribution(hpxml_doc, "Standard", 8.3, nil, 0.893)
    _check_water_fixtures(hpxml_doc, 54.6, -1044995, 1060325)
    _check_drain_water_heat_recovery(hpxml_doc, false, nil, nil, nil, nil, nil)
    
    # IAD, IAD Reference
    calc_types = [Constants.CalcTypeERIIndexAdjustmentDesign,
                  Constants.CalcTypeERIIndexAdjustmentReferenceHome]
    calc_types.each do |calc_type|
      hpxml_doc = _test_measure(hpxml_name, calc_type)
      _check_water_heater(hpxml_doc, "storage water heater", "electricity", "conditioned space", 40, 0.9172, 1.0)
      _check_hot_water_distribution(hpxml_doc, "Standard", 15.7, nil, 1.0)
      _check_water_fixtures(hpxml_doc, 44.6, -895710, 908850)
      _check_drain_water_heat_recovery(hpxml_doc, false, nil, nil, nil, nil, nil)
    end
  end
  
  def test_water_heating_dwhr
    hpxml_name = "valid-dhw-dwhr.xml"
    
    # Reference Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_water_heater(hpxml_doc, "storage water heater", "electricity", "conditioned space", 40, 0.9172, 1.0)
    _check_hot_water_distribution(hpxml_doc, "Standard", 17.8, nil, 1.0)
    _check_water_fixtures(hpxml_doc, 54.6, -1044995, 1060325)
    _check_drain_water_heat_recovery(hpxml_doc, false, nil, nil, nil, nil, nil)
    
    # Rated Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_water_heater(hpxml_doc, "storage water heater", "electricity", "conditioned space", 40, 0.95, 1.0)
    _check_hot_water_distribution(hpxml_doc, "Standard", 8.3, nil, 0.893)
    _check_water_fixtures(hpxml_doc, 54.6, -1044995, 1060325)
    _check_drain_water_heat_recovery(hpxml_doc, true, 1.0, 0.6136, 0.994, 1.0, 1.0)
    
    # IAD, IAD Reference
    calc_types = [Constants.CalcTypeERIIndexAdjustmentDesign,
                  Constants.CalcTypeERIIndexAdjustmentReferenceHome]
    calc_types.each do |calc_type|
      hpxml_doc = _test_measure(hpxml_name, calc_type)
      _check_water_heater(hpxml_doc, "storage water heater", "electricity", "conditioned space", 40, 0.9172, 1.0)
      _check_hot_water_distribution(hpxml_doc, "Standard", 15.7, nil, 1.0)
      _check_water_fixtures(hpxml_doc, 44.6, -895710, 908850)
      _check_drain_water_heat_recovery(hpxml_doc, false, nil, nil, nil, nil, nil)
    end
  end
  
  def test_water_heating_location_attic
    hpxml_name = "valid-dhw-location-attic.xml"
    
    # Reference Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_water_heater(hpxml_doc, "storage water heater", "electricity", "attic - unconditioned", 40, 0.9172, 1.0)
    _check_hot_water_distribution(hpxml_doc, "Standard", 17.8, nil, 1.0)
    _check_water_fixtures(hpxml_doc, 54.6, -1044995, 1060325)
    _check_drain_water_heat_recovery(hpxml_doc, false, nil, nil, nil, nil, nil)
    
    # Rated Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_water_heater(hpxml_doc, "storage water heater", "electricity", "attic - unconditioned", 40, 0.95, 1.0)
    _check_hot_water_distribution(hpxml_doc, "Standard", 8.3, nil, 0.893)
    _check_water_fixtures(hpxml_doc, 54.6, -1044995, 1060325)
    _check_drain_water_heat_recovery(hpxml_doc, false, nil, nil, nil, nil, nil)
    
    # IAD, IAD Reference
    calc_types = [Constants.CalcTypeERIIndexAdjustmentDesign,
                  Constants.CalcTypeERIIndexAdjustmentReferenceHome]
    calc_types.each do |calc_type|
      hpxml_doc = _test_measure(hpxml_name, calc_type)
      _check_water_heater(hpxml_doc, "storage water heater", "electricity", "attic - unconditioned", 40, 0.9172, 1.0)
      _check_hot_water_distribution(hpxml_doc, "Standard", 15.7, nil, 1.0)
      _check_water_fixtures(hpxml_doc, 44.6, -895710, 908850)
      _check_drain_water_heat_recovery(hpxml_doc, false, nil, nil, nil, nil, nil)
    end
  end
  
  def test_water_heating_recirc_demand
    hpxml_name = "valid-dhw-recirc-demand.xml"
    
    # Reference Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_water_heater(hpxml_doc, "storage water heater", "electricity", "conditioned space", 40, 0.9172, 1.0)
    _check_hot_water_distribution(hpxml_doc, "Standard", 17.8, nil, 1.0)
    _check_water_fixtures(hpxml_doc, 54.6, -1044995, 1060325)
    _check_drain_water_heat_recovery(hpxml_doc, false, nil, nil, nil, nil, nil)
    
    # Rated Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_water_heater(hpxml_doc, "storage water heater", "electricity", "conditioned space", 40, 0.95, 1.0)
    _check_hot_water_distribution(hpxml_doc, "Recirculation", 8.4, 7.5, 0.900)
    _check_water_fixtures(hpxml_doc, 54.6, -1044995, 1060325)
    _check_drain_water_heat_recovery(hpxml_doc, false, nil, nil, nil, nil, nil)
    
    # IAD, IAD Reference
    calc_types = [Constants.CalcTypeERIIndexAdjustmentDesign,
                  Constants.CalcTypeERIIndexAdjustmentReferenceHome]
    calc_types.each do |calc_type|
      hpxml_doc = _test_measure(hpxml_name, calc_type)
      _check_water_heater(hpxml_doc, "storage water heater", "electricity", "conditioned space", 40, 0.9172, 1.0)
      _check_hot_water_distribution(hpxml_doc, "Standard", 15.7, nil, 1.0)
      _check_water_fixtures(hpxml_doc, 44.6, -895710, 908850)
      _check_drain_water_heat_recovery(hpxml_doc, false, nil, nil, nil, nil, nil)
    end
  end
  
  def test_water_heating_recirc_nocontrol
    hpxml_name = "valid-dhw-recirc-nocontrol.xml"
    
    # Reference Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_water_heater(hpxml_doc, "storage water heater", "electricity", "conditioned space", 40, 0.9172, 1.0)
    _check_hot_water_distribution(hpxml_doc, "Standard", 17.8, nil, 1.0)
    _check_water_fixtures(hpxml_doc, 54.6, -1044995, 1060325)
    _check_drain_water_heat_recovery(hpxml_doc, false, nil, nil, nil, nil, nil)
    
    # Rated Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_water_heater(hpxml_doc, "storage water heater", "electricity", "conditioned space", 40, 0.95, 1.0)
    _check_hot_water_distribution(hpxml_doc, "Recirculation", 8.9, 438, 1.957)
    _check_water_fixtures(hpxml_doc, 54.6, -1044995, 1060325)
    _check_drain_water_heat_recovery(hpxml_doc, false, nil, nil, nil, nil, nil)
    
    # IAD, IAD Reference
    calc_types = [Constants.CalcTypeERIIndexAdjustmentDesign,
                  Constants.CalcTypeERIIndexAdjustmentReferenceHome]
    calc_types.each do |calc_type|
      hpxml_doc = _test_measure(hpxml_name, calc_type)
      _check_water_heater(hpxml_doc, "storage water heater", "electricity", "conditioned space", 40, 0.9172, 1.0)
      _check_hot_water_distribution(hpxml_doc, "Standard", 15.7, nil, 1.0)
      _check_water_fixtures(hpxml_doc, 44.6, -895710, 908850)
      _check_drain_water_heat_recovery(hpxml_doc, false, nil, nil, nil, nil, nil)
    end
  end
  
  def test_water_heating_recirc_timer
    hpxml_name = "valid-dhw-recirc-timer.xml"
    
    # Reference Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_water_heater(hpxml_doc, "storage water heater", "electricity", "conditioned space", 40, 0.9172, 1.0)
    _check_hot_water_distribution(hpxml_doc, "Standard", 17.8, nil, 1.0)
    _check_water_fixtures(hpxml_doc, 54.6, -1044995, 1060325)
    _check_drain_water_heat_recovery(hpxml_doc, false, nil, nil, nil, nil, nil)
    
    # Rated Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_water_heater(hpxml_doc, "storage water heater", "electricity", "conditioned space", 40, 0.95, 1.0)
    _check_hot_water_distribution(hpxml_doc, "Recirculation", 8.9, 438, 1.957)
    _check_water_fixtures(hpxml_doc, 54.6, -1044995, 1060325)
    _check_drain_water_heat_recovery(hpxml_doc, false, nil, nil, nil, nil, nil)
    
    # IAD, IAD Reference
    calc_types = [Constants.CalcTypeERIIndexAdjustmentDesign,
                  Constants.CalcTypeERIIndexAdjustmentReferenceHome]
    calc_types.each do |calc_type|
      hpxml_doc = _test_measure(hpxml_name, calc_type)
      _check_water_heater(hpxml_doc, "storage water heater", "electricity", "conditioned space", 40, 0.9172, 1.0)
      _check_hot_water_distribution(hpxml_doc, "Standard", 15.7, nil, 1.0)
      _check_water_fixtures(hpxml_doc, 44.6, -895710, 908850)
      _check_drain_water_heat_recovery(hpxml_doc, false, nil, nil, nil, nil, nil)
    end
  end
  
  def test_water_heating_recirc_temperature
    hpxml_name = "valid-dhw-recirc-temperature.xml"
    
    # Reference Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_water_heater(hpxml_doc, "storage water heater", "electricity", "conditioned space", 40, 0.9172, 1.0)
    _check_hot_water_distribution(hpxml_doc, "Standard", 17.8, nil, 1.0)
    _check_water_fixtures(hpxml_doc, 54.6, -1044995, 1060325)
    _check_drain_water_heat_recovery(hpxml_doc, false, nil, nil, nil, nil, nil)
    
    # Rated Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_water_heater(hpxml_doc, "storage water heater", "electricity", "conditioned space", 40, 0.95, 1.0)
    _check_hot_water_distribution(hpxml_doc, "Recirculation", 8.9, 73, 1.667)
    _check_water_fixtures(hpxml_doc, 54.6, -1044995, 1060325)
    _check_drain_water_heat_recovery(hpxml_doc, false, nil, nil, nil, nil, nil)
    
    # IAD, IAD Reference
    calc_types = [Constants.CalcTypeERIIndexAdjustmentDesign,
                  Constants.CalcTypeERIIndexAdjustmentReferenceHome]
    calc_types.each do |calc_type|
      hpxml_doc = _test_measure(hpxml_name, calc_type)
      _check_water_heater(hpxml_doc, "storage water heater", "electricity", "conditioned space", 40, 0.9172, 1.0)
      _check_hot_water_distribution(hpxml_doc, "Standard", 15.7, nil, 1.0)
      _check_water_fixtures(hpxml_doc, 44.6, -895710, 908850)
      _check_drain_water_heat_recovery(hpxml_doc, false, nil, nil, nil, nil, nil)
    end
  end
  
  def test_water_heating_recirc_manual
    hpxml_name = "valid-dhw-recirc-manual.xml"
    
    # Reference Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_water_heater(hpxml_doc, "storage water heater", "electricity", "conditioned space", 40, 0.9172, 1.0)
    _check_hot_water_distribution(hpxml_doc, "Standard", 17.8, nil, 1.0)
    _check_water_fixtures(hpxml_doc, 54.6, -1044995, 1060325)
    _check_drain_water_heat_recovery(hpxml_doc, false, nil, nil, nil, nil, nil)
    
    # Rated Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_water_heater(hpxml_doc, "storage water heater", "electricity", "conditioned space", 40, 0.95, 1.0)
    _check_hot_water_distribution(hpxml_doc, "Recirculation", 8.4, 5, 0.867)
    _check_water_fixtures(hpxml_doc, 54.6, -1044995, 1060325)
    _check_drain_water_heat_recovery(hpxml_doc, false, nil, nil, nil, nil, nil)
    
    # IAD, IAD Reference
    calc_types = [Constants.CalcTypeERIIndexAdjustmentDesign,
                  Constants.CalcTypeERIIndexAdjustmentReferenceHome]
    calc_types.each do |calc_type|
      hpxml_doc = _test_measure(hpxml_name, calc_type)
      _check_water_heater(hpxml_doc, "storage water heater", "electricity", "conditioned space", 40, 0.9172, 1.0)
      _check_hot_water_distribution(hpxml_doc, "Standard", 15.7, nil, 1.0)
      _check_water_fixtures(hpxml_doc, 44.6, -895710, 908850)
      _check_drain_water_heat_recovery(hpxml_doc, false, nil, nil, nil, nil, nil)
    end
  end
  
  def test_water_heating_tank_gas
    hpxml_name = "valid-dhw-tank-gas.xml"
    
    # Reference Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_water_heater(hpxml_doc, "storage water heater", "natural gas", "conditioned space", 50, 0.575, 1.0)
    _check_hot_water_distribution(hpxml_doc, "Standard", 17.8, nil, 1.0)
    _check_water_fixtures(hpxml_doc, 54.6, -1044995, 1060325)
    _check_drain_water_heat_recovery(hpxml_doc, false, nil, nil, nil, nil, nil)
    
    # Rated Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_water_heater(hpxml_doc, "storage water heater", "natural gas", "conditioned space", 50, 0.59, 1.0)
    _check_hot_water_distribution(hpxml_doc, "Standard", 8.3, nil, 0.893)
    _check_water_fixtures(hpxml_doc, 54.6, -1044995, 1060325)
    _check_drain_water_heat_recovery(hpxml_doc, false, nil, nil, nil, nil, nil)
    
    # IAD, IAD Reference
    calc_types = [Constants.CalcTypeERIIndexAdjustmentDesign,
                  Constants.CalcTypeERIIndexAdjustmentReferenceHome]
    calc_types.each do |calc_type|
      hpxml_doc = _test_measure(hpxml_name, calc_type)
      _check_water_heater(hpxml_doc, "storage water heater", "natural gas", "conditioned space", 50, 0.575, 1.0)
      _check_hot_water_distribution(hpxml_doc, "Standard", 15.7, nil, 1.0)
      _check_water_fixtures(hpxml_doc, 44.6, -895710, 908850)
      _check_drain_water_heat_recovery(hpxml_doc, false, nil, nil, nil, nil, nil)
    end
  end
  
  def test_water_heating_tank_heat_pump
    hpxml_name = "valid-dhw-tank-heat-pump.xml"
    
    # Reference Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_water_heater(hpxml_doc, "storage water heater", "electricity", "conditioned space", 80, 0.8644, 1.0)
    _check_hot_water_distribution(hpxml_doc, "Standard", 17.8, nil, 1.0)
    _check_water_fixtures(hpxml_doc, 54.6, -1044995, 1060325)
    _check_drain_water_heat_recovery(hpxml_doc, false, nil, nil, nil, nil, nil)
    
    # Rated Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_water_heater(hpxml_doc, "heat pump water heater", "electricity", "conditioned space", 80, 2.3, 1.0)
    _check_hot_water_distribution(hpxml_doc, "Standard", 8.3, nil, 0.893)
    _check_water_fixtures(hpxml_doc, 54.6, -1044995, 1060325)
    _check_drain_water_heat_recovery(hpxml_doc, false, nil, nil, nil, nil, nil)
    
    # IAD, IAD Reference
    calc_types = [Constants.CalcTypeERIIndexAdjustmentDesign,
                  Constants.CalcTypeERIIndexAdjustmentReferenceHome]
    calc_types.each do |calc_type|
      hpxml_doc = _test_measure(hpxml_name, calc_type)
      _check_water_heater(hpxml_doc, "storage water heater", "electricity", "conditioned space", 80, 0.8644, 1.0)
      _check_hot_water_distribution(hpxml_doc, "Standard", 15.7, nil, 1.0)
      _check_water_fixtures(hpxml_doc, 44.6, -895710, 908850)
      _check_drain_water_heat_recovery(hpxml_doc, false, nil, nil, nil, nil, nil)
    end
  end
  
  def test_water_heating_tankless_electric
    hpxml_name = "valid-dhw-tankless-electric.xml"
    
    # Reference Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_water_heater(hpxml_doc, "storage water heater", "electricity", "conditioned space", 40, 0.9172, 1.0)
    _check_hot_water_distribution(hpxml_doc, "Standard", 17.8, nil, 1.0)
    _check_water_fixtures(hpxml_doc, 54.6, -1044995, 1060325)
    _check_drain_water_heat_recovery(hpxml_doc, false, nil, nil, nil, nil, nil)
    
    # Rated Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_water_heater(hpxml_doc, "instantaneous water heater", "electricity", "conditioned space", nil, 0.99, 0.92)
    _check_hot_water_distribution(hpxml_doc, "Standard", 8.3, nil, 0.893)
    _check_water_fixtures(hpxml_doc, 54.6, -1044995, 1060325)
    _check_drain_water_heat_recovery(hpxml_doc, false, nil, nil, nil, nil, nil)
    
    # IAD, IAD Reference
    calc_types = [Constants.CalcTypeERIIndexAdjustmentDesign,
                  Constants.CalcTypeERIIndexAdjustmentReferenceHome]
    calc_types.each do |calc_type|
      hpxml_doc = _test_measure(hpxml_name, calc_type)
      _check_water_heater(hpxml_doc, "storage water heater", "electricity", "conditioned space", 40, 0.9172, 1.0)
      _check_hot_water_distribution(hpxml_doc, "Standard", 15.7, nil, 1.0)
      _check_water_fixtures(hpxml_doc, 44.6, -895710, 908850)
      _check_drain_water_heat_recovery(hpxml_doc, false, nil, nil, nil, nil, nil)
    end
  end
  
  def test_water_heating_tankless_gas
    hpxml_name = "valid-dhw-tankless-gas.xml"
    
    # Reference Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_water_heater(hpxml_doc, "storage water heater", "natural gas", "conditioned space", 40, 0.594, 1.0)
    _check_hot_water_distribution(hpxml_doc, "Standard", 17.8, nil, 1.0)
    _check_water_fixtures(hpxml_doc, 54.6, -1044995, 1060325)
    _check_drain_water_heat_recovery(hpxml_doc, false, nil, nil, nil, nil, nil)
    
    # Rated Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_water_heater(hpxml_doc, "instantaneous water heater", "natural gas", "conditioned space", nil, 0.82, 0.92)
    _check_hot_water_distribution(hpxml_doc, "Standard", 8.3, nil, 0.893)
    _check_water_fixtures(hpxml_doc, 54.6, -1044995, 1060325)
    _check_drain_water_heat_recovery(hpxml_doc, false, nil, nil, nil, nil, nil)
    
    # IAD, IAD Reference
    calc_types = [Constants.CalcTypeERIIndexAdjustmentDesign,
                  Constants.CalcTypeERIIndexAdjustmentReferenceHome]
    calc_types.each do |calc_type|
      hpxml_doc = _test_measure(hpxml_name, calc_type)
      _check_water_heater(hpxml_doc, "storage water heater", "natural gas", "conditioned space", 40, 0.594, 1.0)
      _check_hot_water_distribution(hpxml_doc, "Standard", 15.7, nil, 1.0)
      _check_water_fixtures(hpxml_doc, 44.6, -895710, 908850)
      _check_drain_water_heat_recovery(hpxml_doc, false, nil, nil, nil, nil, nil)
    end
  end
  
  def test_water_heating_none
    hpxml_name = "valid-dhw-none.xml"
    
    # Reference Home, Rated Home
    calc_types = [Constants.CalcTypeERIReferenceHome,
                  Constants.CalcTypeERIRatedHome]
    calc_types.each do |calc_type|
      hpxml_doc = _test_measure(hpxml_name, calc_type)
      _check_water_heater(hpxml_doc, "storage water heater", "natural gas", "conditioned space", 40, 0.594, 1.0)
      _check_hot_water_distribution(hpxml_doc, "Standard", 17.8, nil, 1.0)
      _check_water_fixtures(hpxml_doc, 54.6, -1044995, 1060325)
      _check_drain_water_heat_recovery(hpxml_doc, false, nil, nil, nil, nil, nil)
    end
    
    # IAD, IAD Reference
    calc_types = [Constants.CalcTypeERIIndexAdjustmentDesign,
                  Constants.CalcTypeERIIndexAdjustmentReferenceHome]
    calc_types.each do |calc_type|
      hpxml_doc = _test_measure(hpxml_name, calc_type)
      _check_water_heater(hpxml_doc, "storage water heater", "natural gas", "conditioned space", 40, 0.594, 1.0)
      _check_hot_water_distribution(hpxml_doc, "Standard", 15.7, nil, 1.0)
      _check_water_fixtures(hpxml_doc, 44.6, -895710, 908850)
      _check_drain_water_heat_recovery(hpxml_doc, false, nil, nil, nil, nil, nil)
    end
  end
  
  def test_water_heating_uef
    hpxml_name = "valid-dhw-uef.xml"
    
    # Reference Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_water_heater(hpxml_doc, "storage water heater", "electricity", "conditioned space", 40, 0.9172, 1.0)
    _check_hot_water_distribution(hpxml_doc, "Standard", 17.8, nil, 1.0)
    _check_water_fixtures(hpxml_doc, 54.6, -1044995, 1060325)
    _check_drain_water_heat_recovery(hpxml_doc, false, nil, nil, nil, nil, nil)
    
    # Rated Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_water_heater(hpxml_doc, "storage water heater", "electricity", "conditioned space", 40, 0.95, 1.0)
    _check_hot_water_distribution(hpxml_doc, "Standard", 8.3, nil, 0.893)
    _check_water_fixtures(hpxml_doc, 54.6, -1044995, 1060325)
    _check_drain_water_heat_recovery(hpxml_doc, false, nil, nil, nil, nil, nil)
    
    # IAD, IAD Reference
    calc_types = [Constants.CalcTypeERIIndexAdjustmentDesign,
                  Constants.CalcTypeERIIndexAdjustmentReferenceHome]
    calc_types.each do |calc_type|
      hpxml_doc = _test_measure(hpxml_name, calc_type)
      _check_water_heater(hpxml_doc, "storage water heater", "electricity", "conditioned space", 40, 0.9172, 1.0)
      _check_hot_water_distribution(hpxml_doc, "Standard", 15.7, nil, 1.0)
      _check_water_fixtures(hpxml_doc, 44.6, -895710, 908850)
      _check_drain_water_heat_recovery(hpxml_doc, false, nil, nil, nil, nil, nil)
    end
  end
  
  def test_water_heating_pre_addendum_a
    hpxml_name = "valid-addenda-exclude-g-e-a.xml"
    # TODO
  end
  
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

  def _check_water_heater(hpxml_doc, whtype, fuel_type, location, tank_vol, ef, ef_mult)
    wh = hpxml_doc.elements["/HPXML/Building/BuildingDetails/Systems/WaterHeating/WaterHeatingSystem"]
    assert_equal(wh.elements["WaterHeaterType"].text, whtype)
    assert_equal(wh.elements["FuelType"].text, fuel_type)
    assert_equal(wh.elements["Location"].text, location)
    if tank_vol.nil?
      assert_nil(wh.elements["TankVolume"])
    else
      assert_in_epsilon(Float(wh.elements["TankVolume"].text), tank_vol, 0.01)
    end
    assert_in_epsilon(Float(wh.elements["EnergyFactor"].text), ef, 0.01)
    assert_in_epsilon(Float(wh.elements["extension/EnergyFactorMultiplier"].text), ef_mult, 0.01)
  end
  
  def _check_hot_water_distribution(hpxml_doc, disttype, mw_gpd, recirc_kwh, ec_adj)
    dist = hpxml_doc.elements["/HPXML/Building/BuildingDetails/Systems/WaterHeating/HotWaterDistribution"]
    refute_nil(dist.elements["SystemType/#{disttype}"])
    assert_in_epsilon(Float(dist.elements["extension/MixedWaterGPD"].text), mw_gpd, 0.01)
    if recirc_kwh.nil?
      assert_nil(dist.elements["SystemType/Recirculation/extension/PumpAnnualkWh"])
    else
      assert_in_epsilon(Float(dist.elements["SystemType/Recirculation/extension/PumpAnnualkWh"].text), recirc_kwh, 0.01)
    end
    assert_in_epsilon(Float(dist.elements["extension/EnergyConsumptionAdjustmentFactor"].text), ec_adj, 0.01)
  end
  
  def _check_water_fixtures(hpxml_doc, mw_gpd, sens_btu, lat_btu)
    wf = hpxml_doc.elements["/HPXML/Building/BuildingDetails/Systems/WaterHeating/WaterFixture"]
    assert_in_epsilon(Float(wf.elements["extension/MixedWaterGPD"].text), mw_gpd, 0.01)
    assert_in_epsilon(Float(wf.elements["extension/AnnualSensibleGainsBtu"].text), sens_btu, 0.01)
    assert_in_epsilon(Float(wf.elements["extension/AnnualLatentGainsBtu"].text), lat_btu, 0.01)
  end
  
  def _check_drain_water_heat_recovery(hpxml_doc, exists, eff_adj, frac_impact_hw, pipe_loss_coeff, loc_f, fix_f)
    dist = hpxml_doc.elements["/HPXML/Building/BuildingDetails/Systems/WaterHeating/HotWaterDistribution"]
    assert_equal(!dist.elements["DrainWaterHeatRecovery"].nil?, exists)
  end
  
end