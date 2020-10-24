# frozen_string_literal: true

require_relative '../../../workflow/tests/minitest_helper'
require 'openstudio'
require 'openstudio/measure/ShowRunnerOutput'
require 'minitest/autorun'
require_relative '../measure.rb'
require 'fileutils'
require_relative 'util.rb'

class ERIMechVentTest < MiniTest::Test
  def before_setup
    @root_path = File.absolute_path(File.join(File.dirname(__FILE__), '..', '..', '..'))
    @tmp_hpxml_path = File.join(@root_path, 'workflow', 'sample_files', 'tmp.xml')
  end

  def after_teardown
    File.delete(@tmp_hpxml_path) if File.exist? @tmp_hpxml_path
  end

  def test_mech_vent_none
    hpxml_name = 'base.xml'

    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_mech_vent(hpxml, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 26.8, hours: 24, power: 0.0 }]) # Should have airflow but not fan energy
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_mech_vent(hpxml)
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentDesign)
    _check_mech_vent(hpxml, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 60.0, hours: 24, power: 42.0 }])
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentReferenceHome)
    _check_mech_vent(hpxml, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 8.5, hours: 24, power: 42.0 }])

    hpxml_name = _change_eri_version(hpxml_name, '2014')

    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_mech_vent(hpxml, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 37.0, hours: 24, power: 0.0 }]) # Should have airflow but not fan energy
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_mech_vent(hpxml)
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentDesign)
    _check_mech_vent(hpxml, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 60.0, hours: 24, power: 42.0 }])
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentReferenceHome)
    _check_mech_vent(hpxml, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 34.0, hours: 24, power: 42.0 }])
  end

  def test_mech_vent_attached_or_multifamily
    hpxml_name = 'base-enclosure-other-housing-unit.xml'

    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_mech_vent(hpxml, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 66.3, hours: 24, power: 0.0 }]) # Should have airflow but not fan energy
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_mech_vent(hpxml)
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentDesign)
    _check_mech_vent(hpxml, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 70.6, hours: 24, power: 49.4 }])
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentReferenceHome)
    _check_mech_vent(hpxml, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 32.1, hours: 24, power: 55.0 }])

    # Test w/ 301-2014
    hpxml_name = _change_eri_version(hpxml_name, '2014')

    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_mech_vent(hpxml, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 70.5, hours: 24, power: 0.0 }]) # Should have airflow but not fan energy
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_mech_vent(hpxml)
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentDesign)
    _check_mech_vent(hpxml, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 102.0, hours: 24, power: 71.4 }])
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentReferenceHome)
    _check_mech_vent(hpxml, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 102.0, hours: 24, power: 71.4 }])

    # FIXME: Add tests for new 301-2019 space types HPXML file
  end

  def test_mech_vent_exhaust
    hpxml_name = 'base-mechvent-exhaust.xml'

    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_mech_vent(hpxml, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 26.8, hours: 24, power: 34.8 }])
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_mech_vent(hpxml, [{ fantype: HPXML::MechVentTypeExhaust, flowrate: 110.0, hours: 24, power: 30.0 }])
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentDesign)
    _check_mech_vent(hpxml, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 60.0, hours: 24, power: 42.0 }])
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentReferenceHome)
    _check_mech_vent(hpxml, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 8.5, hours: 24, power: 42.0 }])

    hpxml_name = _change_eri_version(hpxml_name, '2014')

    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_mech_vent(hpxml, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 37.0, hours: 24, power: 26.4 }])
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_mech_vent(hpxml, [{ fantype: HPXML::MechVentTypeExhaust, flowrate: 110.0, hours: 24, power: 30.0 }])
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentDesign)
    _check_mech_vent(hpxml, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 60.0, hours: 24, power: 42.0 }])
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentReferenceHome)
    _check_mech_vent(hpxml, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 34.0, hours: 24, power: 42.0 }])
  end

  def test_mech_vent_exhaust_below_ashrae_622
    # Test Rated Home:
    # For residences with Whole-House Mechanical Ventilation Systems, the measured infiltration rate
    # combined with the time-averaged Whole-House Mechanical Ventilation System rate, which shall
    # not be less than 0.03 x CFA + 7.5 x (Nbr+1) cfm

    # Create derivative file for testing
    hpxml_name = 'base-mechvent-exhaust.xml'
    hpxml = HPXML.new(hpxml_path: File.join(@root_path, 'workflow', 'sample_files', hpxml_name))
    vent_fan = hpxml.ventilation_fans.select { |vf| vf.used_for_whole_building_ventilation }[0]
    vent_fan.hours_in_operation = 12
    hpxml_name = File.basename(@tmp_hpxml_path)
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)

    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_mech_vent(hpxml, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 26.8, hours: 24, power: 34.8 }])
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_mech_vent(hpxml, [{ fantype: HPXML::MechVentTypeExhaust, flowrate: 199.1, hours: 12, power: 54.3 }]) # Increased fan power
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentDesign)
    _check_mech_vent(hpxml, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 60.0, hours: 24, power: 42.0 }])
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentReferenceHome)
    _check_mech_vent(hpxml, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 8.5, hours: 24, power: 42.0 }])

    hpxml_name = _change_eri_version(hpxml_name, '2014')

    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_mech_vent(hpxml, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 37.0, hours: 24, power: 26.4 }])
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_mech_vent(hpxml, [{ fantype: HPXML::MechVentTypeExhaust, flowrate: 150.7, hours: 12, power: 41.1 }]) # Increased fan power
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentDesign)
    _check_mech_vent(hpxml, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 60.0, hours: 24, power: 42.0 }])
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentReferenceHome)
    _check_mech_vent(hpxml, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 34.0, hours: 24, power: 42.0 }])
  end

  def test_mech_vent_exhaust_defaulted_fan_power
    # Create derivative file for testing
    hpxml_name = 'base-mechvent-exhaust.xml'
    hpxml = HPXML.new(hpxml_path: File.join(@root_path, 'workflow', 'sample_files', hpxml_name))
    vent_fan = hpxml.ventilation_fans.select { |vf| vf.used_for_whole_building_ventilation }[0]
    vent_fan.fan_power = nil
    vent_fan.fan_power_defaulted = true
    vent_fan.hours_in_operation = 12
    vent_fan.tested_flow_rate = 10.0
    hpxml_name = File.basename(@tmp_hpxml_path)
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)

    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_mech_vent(hpxml, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 26.8, hours: 24, power: 34.8 }])
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_mech_vent(hpxml, [{ fantype: HPXML::MechVentTypeExhaust, flowrate: 199.1, hours: 12, power: 69.7 }])
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentDesign)
    _check_mech_vent(hpxml, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 60.0, hours: 24, power: 42.0 }])
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentReferenceHome)
    _check_mech_vent(hpxml, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 8.5, hours: 24, power: 42.0 }])

    hpxml_name = _change_eri_version(hpxml_name, '2014')

    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_mech_vent(hpxml, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 37.0, hours: 24, power: 26.4 }])
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_mech_vent(hpxml, [{ fantype: HPXML::MechVentTypeExhaust, flowrate: 150.7, hours: 12, power: 52.8 }])
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentDesign)
    _check_mech_vent(hpxml, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 60.0, hours: 24, power: 42.0 }])
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentReferenceHome)
    _check_mech_vent(hpxml, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 34.0, hours: 24, power: 42.0 }])
  end

  def test_mech_vent_exhaust_unmeasured_airflow_rate
    # Create derivative file for testing
    hpxml_name = 'base-mechvent-exhaust.xml'
    hpxml = HPXML.new(hpxml_path: File.join(@root_path, 'workflow', 'sample_files', hpxml_name))
    vent_fan = hpxml.ventilation_fans.select { |vf| vf.used_for_whole_building_ventilation }[0]
    vent_fan.tested_flow_rate = nil
    vent_fan.flow_rate_not_tested = true
    vent_fan.hours_in_operation = 12
    hpxml_name = File.basename(@tmp_hpxml_path)
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)

    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_mech_vent(hpxml, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 26.8, hours: 24, power: 0.1 }])
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_mech_vent(hpxml, [{ fantype: HPXML::MechVentTypeExhaust, flowrate: 15.0, hours: 24, power: 30.0 }])
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentDesign)
    _check_mech_vent(hpxml, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 60.0, hours: 24, power: 42.0 }])
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentReferenceHome)
    _check_mech_vent(hpxml, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 8.5, hours: 24, power: 42.0 }])

    hpxml_name = _change_eri_version(hpxml_name, '2014')

    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_mech_vent(hpxml, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 37.0, hours: 24, power: 26.4 }])
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_mech_vent(hpxml, [{ fantype: HPXML::MechVentTypeExhaust, flowrate: 75.4, hours: 24, power: 30.0 }])
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentDesign)
    _check_mech_vent(hpxml, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 60.0, hours: 24, power: 42.0 }])
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentReferenceHome)
    _check_mech_vent(hpxml, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 34.0, hours: 24, power: 42.0 }])
  end

  def test_mech_vent_exhaust_unmeasured_airflow_rate_and_defaulted_fan_power
    # Create derivative file for testing
    hpxml_name = 'base-mechvent-exhaust.xml'
    hpxml = HPXML.new(hpxml_path: File.join(@root_path, 'workflow', 'sample_files', hpxml_name))
    vent_fan = hpxml.ventilation_fans.select { |vf| vf.used_for_whole_building_ventilation }[0]
    vent_fan.fan_power = nil
    vent_fan.fan_power_defaulted = true
    vent_fan.tested_flow_rate = nil
    vent_fan.flow_rate_not_tested = true
    vent_fan.hours_in_operation = 12
    hpxml_name = File.basename(@tmp_hpxml_path)
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)

    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_mech_vent(hpxml, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 26.8, hours: 24, power: 0.1 }])
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_mech_vent(hpxml, [{ fantype: HPXML::MechVentTypeExhaust, flowrate: 15.0, hours: 24, power: 5.25 }])
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentDesign)
    _check_mech_vent(hpxml, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 60.0, hours: 24, power: 42.0 }])
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentReferenceHome)
    _check_mech_vent(hpxml, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 8.5, hours: 24, power: 42.0 }])

    hpxml_name = _change_eri_version(hpxml_name, '2014')

    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_mech_vent(hpxml, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 37.0, hours: 24, power: 26.4 }])
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_mech_vent(hpxml, [{ fantype: HPXML::MechVentTypeExhaust, flowrate: 75.4, hours: 24, power: 26.4 }])
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentDesign)
    _check_mech_vent(hpxml, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 60.0, hours: 24, power: 42.0 }])
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentReferenceHome)
    _check_mech_vent(hpxml, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 34.0, hours: 24, power: 42.0 }])
  end

  def test_mech_vent_supply
    hpxml_name = 'base-mechvent-supply.xml'

    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_mech_vent(hpxml, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 26.8, hours: 24, power: 34.8 }])
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_mech_vent(hpxml, [{ fantype: HPXML::MechVentTypeSupply, flowrate: 110.0, hours: 24, power: 30.0 }])
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentDesign)
    _check_mech_vent(hpxml, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 60.0, hours: 24, power: 42.0 }])
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentReferenceHome)
    _check_mech_vent(hpxml, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 8.5, hours: 24, power: 42.0 }])

    hpxml_name = _change_eri_version(hpxml_name, '2014')

    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_mech_vent(hpxml, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 37.0, hours: 24, power: 26.4 }])
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_mech_vent(hpxml, [{ fantype: HPXML::MechVentTypeSupply, flowrate: 110.0, hours: 24, power: 30.0 }])
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentDesign)
    _check_mech_vent(hpxml, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 60.0, hours: 24, power: 42.0 }])
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentReferenceHome)
    _check_mech_vent(hpxml, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 34.0, hours: 24, power: 42.0 }])
  end

  def test_mech_vent_balanced
    hpxml_name = 'base-mechvent-balanced.xml'

    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_mech_vent(hpxml, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 26.8, hours: 24, power: 52.8 }])
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_mech_vent(hpxml, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 110.0, hours: 24, power: 60.0 }])
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentDesign)
    _check_mech_vent(hpxml, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 60.0, hours: 24, power: 42.0 }])
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentReferenceHome)
    _check_mech_vent(hpxml, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 8.5, hours: 24, power: 42.0 }])

    hpxml_name = _change_eri_version(hpxml_name, '2014')

    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_mech_vent(hpxml, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 37.0, hours: 24, power: 52.8 }])
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_mech_vent(hpxml, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 110.0, hours: 24, power: 60.0 }])
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentDesign)
    _check_mech_vent(hpxml, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 60.0, hours: 24, power: 42.0 }])
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentReferenceHome)
    _check_mech_vent(hpxml, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 34.0, hours: 24, power: 42.0 }])
  end

  def test_mech_vent_erv
    hpxml_name = 'base-mechvent-erv.xml'

    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_mech_vent(hpxml, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 26.8, hours: 24, power: 75.4 }])
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_mech_vent(hpxml, [{ fantype: HPXML::MechVentTypeERV, flowrate: 110.0, hours: 24, power: 60.0, sre: 0.72, tre: 0.48 }])
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentDesign)
    _check_mech_vent(hpxml, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 60.0, hours: 24, power: 42.0 }])
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentReferenceHome)
    _check_mech_vent(hpxml, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 8.5, hours: 24, power: 42.0 }])

    hpxml_name = _change_eri_version(hpxml_name, '2014')

    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_mech_vent(hpxml, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 37.0, hours: 24, power: 75.4 }])
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_mech_vent(hpxml, [{ fantype: HPXML::MechVentTypeERV, flowrate: 110.0, hours: 24, power: 60.0, sre: 0.72, tre: 0.48 }])
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentDesign)
    _check_mech_vent(hpxml, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 60.0, hours: 24, power: 42.0 }])
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentReferenceHome)
    _check_mech_vent(hpxml, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 34.0, hours: 24, power: 42.0 }])
  end

  def test_mech_vent_erv_adjusted
    hpxml_name = 'base-mechvent-erv-atre-asre.xml'

    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_mech_vent(hpxml, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 26.8, hours: 24, power: 75.4 }])
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_mech_vent(hpxml, [{ fantype: HPXML::MechVentTypeERV, flowrate: 110.0, hours: 24, power: 60.0, asre: 0.79, atre: 0.526 }])
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentDesign)
    _check_mech_vent(hpxml, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 60.0, hours: 24, power: 42.0 }])
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentReferenceHome)
    _check_mech_vent(hpxml, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 8.5, hours: 24, power: 42.0 }])

    hpxml_name = _change_eri_version(hpxml_name, '2014')

    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_mech_vent(hpxml, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 37.0, hours: 24, power: 75.4 }])
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_mech_vent(hpxml, [{ fantype: HPXML::MechVentTypeERV, flowrate: 110.0, hours: 24, power: 60.0, asre: 0.79, atre: 0.526 }])
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentDesign)
    _check_mech_vent(hpxml, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 60.0, hours: 24, power: 42.0 }])
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentReferenceHome)
    _check_mech_vent(hpxml, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 34.0, hours: 24, power: 42.0 }])
  end

  def test_mech_vent_hrv
    hpxml_name = 'base-mechvent-hrv.xml'

    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_mech_vent(hpxml, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 26.8, hours: 24, power: 75.4 }])
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_mech_vent(hpxml, [{ fantype: HPXML::MechVentTypeHRV, flowrate: 110.0, hours: 24, power: 60.0, sre: 0.72 }])
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentDesign)
    _check_mech_vent(hpxml, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 60.0, hours: 24, power: 42.0 }])
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentReferenceHome)
    _check_mech_vent(hpxml, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 8.5, hours: 24, power: 42.0 }])

    hpxml_name = _change_eri_version(hpxml_name, '2014')

    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_mech_vent(hpxml, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 37.0, hours: 24, power: 75.4 }])
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_mech_vent(hpxml, [{ fantype: HPXML::MechVentTypeHRV, flowrate: 110.0, hours: 24, power: 60.0, sre: 0.72 }])
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentDesign)
    _check_mech_vent(hpxml, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 60.0, hours: 24, power: 42.0 }])
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentReferenceHome)
    _check_mech_vent(hpxml, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 34.0, hours: 24, power: 42.0 }])
  end

  def test_mech_vent_hrv_adjusted
    hpxml_name = 'base-mechvent-hrv-asre.xml'

    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_mech_vent(hpxml, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 26.8, hours: 24, power: 75.4 }])
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_mech_vent(hpxml, [{ fantype: HPXML::MechVentTypeHRV, flowrate: 110.0, hours: 24, power: 60.0, asre: 0.79 }])
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentDesign)
    _check_mech_vent(hpxml, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 60.0, hours: 24, power: 42.0 }])
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentReferenceHome)
    _check_mech_vent(hpxml, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 8.5, hours: 24, power: 42.0 }])

    hpxml_name = _change_eri_version(hpxml_name, '2014')

    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_mech_vent(hpxml, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 37.0, hours: 24, power: 75.4 }])
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_mech_vent(hpxml, [{ fantype: HPXML::MechVentTypeHRV, flowrate: 110.0, hours: 24, power: 60.0, asre: 0.79 }])
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentDesign)
    _check_mech_vent(hpxml, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 60.0, hours: 24, power: 42.0 }])
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentReferenceHome)
    _check_mech_vent(hpxml, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 34.0, hours: 24, power: 42.0 }])
  end

  def test_mech_vent_cfis
    hpxml_name = 'base-mechvent-cfis.xml'

    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_mech_vent(hpxml, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 26.8, hours: 24, power: 34.8 }])
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_mech_vent(hpxml, [{ fantype: HPXML::MechVentTypeCFIS, flowrate: 330.0, hours: 8, power: 300.0 }])
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentDesign)
    _check_mech_vent(hpxml, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 60.0, hours: 24, power: 42.0 }])
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentReferenceHome)
    _check_mech_vent(hpxml, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 8.5, hours: 24, power: 42.0 }])

    hpxml_name = _change_eri_version(hpxml_name, '2014')

    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_mech_vent(hpxml, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 37.0, hours: 24, power: 26.4 }])
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_mech_vent(hpxml, [{ fantype: HPXML::MechVentTypeCFIS, flowrate: 330.0, hours: 8, power: 300.0 }])
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentDesign)
    _check_mech_vent(hpxml, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 60.0, hours: 24, power: 42.0 }])
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentReferenceHome)
    _check_mech_vent(hpxml, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 34.0, hours: 24, power: 42.0 }])
  end

  def test_mech_vent_cfis_unmeasured_airflow_rate_and_defaulted_fan_power
    # Create derivative file for testing
    hpxml_name = 'base-mechvent-cfis.xml'
    hpxml = HPXML.new(hpxml_path: File.join(@root_path, 'workflow', 'sample_files', hpxml_name))
    vent_fan = hpxml.ventilation_fans.select { |vf| vf.used_for_whole_building_ventilation }[0]
    vent_fan.fan_power = nil
    vent_fan.fan_power_defaulted = true
    vent_fan.tested_flow_rate = nil
    vent_fan.flow_rate_not_tested = true
    vent_fan.hours_in_operation = 8
    hpxml_name = File.basename(@tmp_hpxml_path)
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)

    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_mech_vent(hpxml, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 26.8, hours: 24, power: 0.1 }])
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_mech_vent(hpxml, [{ fantype: HPXML::MechVentTypeCFIS, flowrate: 15.0, hours: 24, power: 800.0 }])
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentDesign)
    _check_mech_vent(hpxml, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 60.0, hours: 24, power: 42.0 }])
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentReferenceHome)
    _check_mech_vent(hpxml, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 8.5, hours: 24, power: 42.0 }])
  end

  def test_mech_vent_cfm50_infiltration
    # Create derivative file for testing
    hpxml_name = _change_eri_version('base-enclosure-infil-cfm50.xml', '2014')

    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_mech_vent(hpxml, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 37.0, hours: 24, power: 0.0 }]) # Should have airflow but not fan energy
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_mech_vent(hpxml)
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentDesign)
    _check_mech_vent(hpxml, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 60.0, hours: 24, power: 42.0 }])
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentReferenceHome)
    _check_mech_vent(hpxml, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 34.0, hours: 24, power: 42.0 }])
  end

  def test_mech_vent_multiple
    # 1. Supply (measured) + Exhaust (measured)
    # Create derivative file for testing
    hpxml_name = 'base.xml'
    hpxml = HPXML.new(hpxml_path: File.join(@root_path, 'workflow', 'sample_files', hpxml_name))
    hpxml.ventilation_fans.add(id: 'MechanicalVentilation',
                               fan_type: HPXML::MechVentTypeSupply,
                               tested_flow_rate: 50,
                               hours_in_operation: 12,
                               fan_power: 25,
                               used_for_whole_building_ventilation: true,
                               is_shared_system: false)
    hpxml.ventilation_fans.add(id: 'MechanicalVentilation2',
                               fan_type: HPXML::MechVentTypeExhaust,
                               tested_flow_rate: 50,
                               hours_in_operation: 24,
                               fan_power: 25,
                               used_for_whole_building_ventilation: true,
                               is_shared_system: false)
    hpxml_name = File.basename(@tmp_hpxml_path)
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_name = _change_eri_version(hpxml_name, '2014') # Avoid min nACH for unmeasured systems

    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_mech_vent(hpxml, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 37.0, hours: 24, power: 26.4 }])
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_mech_vent(hpxml, [{ fantype: HPXML::MechVentTypeSupply, flowrate: 75.4, hours: 12, power: 37.7 },
                             { fantype: HPXML::MechVentTypeExhaust, flowrate: 75.4, hours: 24, power: 37.7 }])
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentDesign)
    _check_mech_vent(hpxml, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 60.0, hours: 24, power: 42.0 }])
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentReferenceHome)
    _check_mech_vent(hpxml, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 34.0, hours: 24, power: 42.0 }])

    # 2. Exhaust (measured) + Supply (unmeasured)
    # Create derivative file for testing
    hpxml_name = 'base.xml'
    hpxml = HPXML.new(hpxml_path: File.join(@root_path, 'workflow', 'sample_files', hpxml_name))
    hpxml.ventilation_fans.add(id: 'MechanicalVentilation',
                               fan_type: HPXML::MechVentTypeExhaust,
                               tested_flow_rate: 50,
                               hours_in_operation: 24,
                               fan_power: 25,
                               used_for_whole_building_ventilation: true,
                               is_shared_system: false)
    hpxml.ventilation_fans.add(id: 'MechanicalVentilation2',
                               fan_type: HPXML::MechVentTypeSupply,
                               tested_flow_rate: nil,
                               flow_rate_not_tested: true,
                               hours_in_operation: 12,
                               fan_power: 25,
                               used_for_whole_building_ventilation: true,
                               is_shared_system: false)
    hpxml_name = File.basename(@tmp_hpxml_path)
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_name = _change_eri_version(hpxml_name, '2014') # Avoid min nACH for unmeasured systems

    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_mech_vent(hpxml, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 37.0, hours: 24, power: 26.4 }])
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_mech_vent(hpxml, [{ fantype: HPXML::MechVentTypeExhaust, flowrate: 75.4, hours: 24, power: 37.7 },
                             { fantype: HPXML::MechVentTypeSupply, flowrate: 15.0, hours: 24, power: 25.0 }])

    # 3. Exhaust (measured) + Exhaust (unmeasured)
    # Create derivative file for testing
    hpxml_name = 'base.xml'
    hpxml = HPXML.new(hpxml_path: File.join(@root_path, 'workflow', 'sample_files', hpxml_name))
    hpxml.ventilation_fans.add(id: 'MechanicalVentilation',
                               fan_type: HPXML::MechVentTypeExhaust,
                               tested_flow_rate: 50,
                               hours_in_operation: 24,
                               fan_power: 25,
                               used_for_whole_building_ventilation: true,
                               is_shared_system: false)
    hpxml.ventilation_fans.add(id: 'MechanicalVentilation2',
                               fan_type: HPXML::MechVentTypeExhaust,
                               tested_flow_rate: nil,
                               flow_rate_not_tested: true,
                               hours_in_operation: 12,
                               fan_power: 25,
                               used_for_whole_building_ventilation: true,
                               is_shared_system: false)
    hpxml_name = File.basename(@tmp_hpxml_path)
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_name = _change_eri_version(hpxml_name, '2014') # Avoid min nACH for unmeasured systems

    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_mech_vent(hpxml, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 37.0, hours: 24, power: 26.4 }])
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_mech_vent(hpxml, [{ fantype: HPXML::MechVentTypeExhaust, flowrate: 50.0, hours: 24, power: 25.0 },
                             { fantype: HPXML::MechVentTypeExhaust, flowrate: 25.4, hours: 24, power: 25.0 }])

    # 4. Exhaust (measured) + Balanced (measured)
    # Create derivative file for testing
    hpxml_name = 'base.xml'
    hpxml = HPXML.new(hpxml_path: File.join(@root_path, 'workflow', 'sample_files', hpxml_name))
    hpxml.ventilation_fans.add(id: 'MechanicalVentilation',
                               fan_type: HPXML::MechVentTypeExhaust,
                               tested_flow_rate: 50,
                               hours_in_operation: 12,
                               fan_power: 25,
                               used_for_whole_building_ventilation: true,
                               is_shared_system: false)
    hpxml.ventilation_fans.add(id: 'MechanicalVentilation2',
                               fan_type: HPXML::MechVentTypeBalanced,
                               tested_flow_rate: 25,
                               hours_in_operation: 24,
                               fan_power: 25,
                               used_for_whole_building_ventilation: true,
                               is_shared_system: false)
    hpxml_name = File.basename(@tmp_hpxml_path)
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_name = _change_eri_version(hpxml_name, '2014') # Avoid min nACH for unmeasured systems

    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_mech_vent(hpxml, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 37.0, hours: 24, power: 39.6 }])
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_mech_vent(hpxml, [{ fantype: HPXML::MechVentTypeExhaust, flowrate: 75.4, hours: 12, power: 37.7 },
                             { fantype: HPXML::MechVentTypeBalanced, flowrate: 37.7, hours: 24, power: 37.7 }])

    # 5. Supply (measured) + Exhaust (measured) + Balanced (measured) + Supply (unmeasured) + Exhaust (unmeasured) + Balanced (unmeasured)
    # Create derivative file for testing
    hpxml_name = 'base.xml'
    hpxml = HPXML.new(hpxml_path: File.join(@root_path, 'workflow', 'sample_files', hpxml_name))
    hpxml.ventilation_fans.add(id: 'MechanicalVentilation',
                               fan_type: HPXML::MechVentTypeSupply,
                               tested_flow_rate: 45,
                               hours_in_operation: 8,
                               fan_power: 25,
                               used_for_whole_building_ventilation: true,
                               is_shared_system: false)
    hpxml.ventilation_fans.add(id: 'MechanicalVentilation2',
                               fan_type: HPXML::MechVentTypeExhaust,
                               tested_flow_rate: 50,
                               hours_in_operation: 12,
                               fan_power: 25,
                               used_for_whole_building_ventilation: true,
                               is_shared_system: false)
    hpxml.ventilation_fans.add(id: 'MechanicalVentilation3',
                               fan_type: HPXML::MechVentTypeBalanced,
                               tested_flow_rate: 20,
                               hours_in_operation: 24,
                               fan_power: 25,
                               used_for_whole_building_ventilation: true,
                               is_shared_system: false)
    hpxml.ventilation_fans.add(id: 'MechanicalVentilation4',
                               fan_type: HPXML::MechVentTypeSupply,
                               tested_flow_rate: nil,
                               flow_rate_not_tested: true,
                               hours_in_operation: 8,
                               fan_power: 25,
                               used_for_whole_building_ventilation: true,
                               is_shared_system: false)
    hpxml.ventilation_fans.add(id: 'MechanicalVentilation5',
                               fan_type: HPXML::MechVentTypeExhaust,
                               tested_flow_rate: nil,
                               flow_rate_not_tested: true,
                               hours_in_operation: 12,
                               fan_power: 25,
                               used_for_whole_building_ventilation: true,
                               is_shared_system: false)
    hpxml.ventilation_fans.add(id: 'MechanicalVentilation6',
                               fan_type: HPXML::MechVentTypeBalanced,
                               tested_flow_rate: nil,
                               flow_rate_not_tested: true,
                               hours_in_operation: 24,
                               fan_power: 25,
                               used_for_whole_building_ventilation: true,
                               is_shared_system: false)
    hpxml_name = File.basename(@tmp_hpxml_path)
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_name = _change_eri_version(hpxml_name, '2014') # Avoid min nACH for unmeasured systems

    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_mech_vent(hpxml, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 37.0, hours: 24, power: 36.5 }])
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_mech_vent(hpxml, [{ fantype: HPXML::MechVentTypeSupply, flowrate: 45.0, hours: 8, power: 25.0 },
                             { fantype: HPXML::MechVentTypeExhaust, flowrate: 50.0, hours: 12, power: 25.0 },
                             { fantype: HPXML::MechVentTypeBalanced, flowrate: 20.0, hours: 24, power: 25.0 },
                             { fantype: HPXML::MechVentTypeSupply, flowrate: 15.0, hours: 24, power: 25.0 },
                             { fantype: HPXML::MechVentTypeExhaust, flowrate: 15.0, hours: 24, power: 25.0 },
                             { fantype: HPXML::MechVentTypeBalanced, flowrate: 23.6, hours: 24, power: 25.0 }])

    # 6. Supply (measured) + Exhaust (measured) + Balanced (measured) + Supply (unmeasured) + Exhaust (unmeasured) + Balanced (unmeasured)
    #    where total flow rate > minimum requirement
    # Create derivative file for testing
    hpxml_name = 'base.xml'
    hpxml = HPXML.new(hpxml_path: File.join(@root_path, 'workflow', 'sample_files', hpxml_name))
    hpxml.ventilation_fans.add(id: 'MechanicalVentilation',
                               fan_type: HPXML::MechVentTypeSupply,
                               tested_flow_rate: 45,
                               hours_in_operation: 8,
                               fan_power: 25,
                               used_for_whole_building_ventilation: true,
                               is_shared_system: false)
    hpxml.ventilation_fans.add(id: 'MechanicalVentilation2',
                               fan_type: HPXML::MechVentTypeExhaust,
                               tested_flow_rate: 200,
                               hours_in_operation: 12,
                               fan_power: 25,
                               used_for_whole_building_ventilation: true,
                               is_shared_system: false)
    hpxml.ventilation_fans.add(id: 'MechanicalVentilation3',
                               fan_type: HPXML::MechVentTypeBalanced,
                               tested_flow_rate: 20,
                               hours_in_operation: 24,
                               fan_power: 25,
                               used_for_whole_building_ventilation: true,
                               is_shared_system: false)
    hpxml.ventilation_fans.add(id: 'MechanicalVentilation4',
                               fan_type: HPXML::MechVentTypeSupply,
                               tested_flow_rate: nil,
                               flow_rate_not_tested: true,
                               hours_in_operation: 8,
                               fan_power: 25,
                               used_for_whole_building_ventilation: true,
                               is_shared_system: false)
    hpxml.ventilation_fans.add(id: 'MechanicalVentilation5',
                               fan_type: HPXML::MechVentTypeExhaust,
                               tested_flow_rate: nil,
                               flow_rate_not_tested: true,
                               hours_in_operation: 12,
                               fan_power: 25,
                               used_for_whole_building_ventilation: true,
                               is_shared_system: false)
    hpxml.ventilation_fans.add(id: 'MechanicalVentilation6',
                               fan_type: HPXML::MechVentTypeBalanced,
                               tested_flow_rate: nil,
                               flow_rate_not_tested: true,
                               hours_in_operation: 24,
                               fan_power: 25,
                               used_for_whole_building_ventilation: true,
                               is_shared_system: false)
    hpxml_name = File.basename(@tmp_hpxml_path)
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_name = _change_eri_version(hpxml_name, '2014') # Avoid min nACH for unmeasured systems

    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_mech_vent(hpxml, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 37.0, hours: 24, power: 31.5 }])
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_mech_vent(hpxml, [{ fantype: HPXML::MechVentTypeSupply, flowrate: 45.0, hours: 8, power: 25.0 },
                             { fantype: HPXML::MechVentTypeExhaust, flowrate: 200.0, hours: 12, power: 25.0 },
                             { fantype: HPXML::MechVentTypeBalanced, flowrate: 20.0, hours: 24, power: 25.0 },
                             { fantype: HPXML::MechVentTypeSupply, flowrate: 15.0, hours: 24, power: 25.0 },
                             { fantype: HPXML::MechVentTypeExhaust, flowrate: 15.0, hours: 24, power: 25.0 },
                             { fantype: HPXML::MechVentTypeBalanced, flowrate: 15.0, hours: 24, power: 25.0 }])
  end

  def test_mech_vent_shared
    hpxml_name = 'base-mechvent-shared-preconditioning.xml'

    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_mech_vent(hpxml, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 56.3, hours: 24, power: 33.4 }])
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_mech_vent(hpxml, [{ fantype: HPXML::MechVentTypeSupply, flowrate: 1060.7, hours: 24, power: 318.2, in_unit_flowrate: 106.1, frac_recirc: 0.5, has_preheat: true, has_precool: true },
                             { fantype: HPXML::MechVentTypeExhaust, flowrate: 95.5, hours: 24, power: 34.5 }])
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentDesign)
    _check_mech_vent(hpxml, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 60.0, hours: 24, power: 42.0 }])
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentReferenceHome)
    _check_mech_vent(hpxml, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 8.5, hours: 24, power: 42.0 }])
  end

  def test_mech_vent_shared_defaulted_fan_power
    # Create derivative file for testing
    hpxml_name = 'base-mechvent-shared-preconditioning.xml'
    hpxml = HPXML.new(hpxml_path: File.join(@root_path, 'workflow', 'sample_files', hpxml_name))
    vent_fan = hpxml.ventilation_fans.select { |vf| vf.used_for_whole_building_ventilation && vf.is_shared_system }[0]
    vent_fan.fan_power = nil
    vent_fan.fan_power_defaulted = true
    hpxml_name = File.basename(@tmp_hpxml_path)
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)

    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_mech_vent(hpxml, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 56.3, hours: 24, power: 33.4 }])
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_mech_vent(hpxml, [{ fantype: HPXML::MechVentTypeSupply, flowrate: 1060.7, hours: 24, power: 1060.7, in_unit_flowrate: 106.1, frac_recirc: 0.5, has_preheat: true, has_precool: true },
                             { fantype: HPXML::MechVentTypeExhaust, flowrate: 95.5, hours: 24, power: 34.5 }])
  end

  def test_mech_vent_shared_unmeasured_airflow_rate
    # Create derivative file for testing
    hpxml_name = 'base-mechvent-shared-preconditioning.xml'
    hpxml = HPXML.new(hpxml_path: File.join(@root_path, 'workflow', 'sample_files', hpxml_name))
    vent_fan = hpxml.ventilation_fans.select { |vf| vf.used_for_whole_building_ventilation && vf.is_shared_system }[0]
    vent_fan.in_unit_flow_rate = nil
    vent_fan.flow_rate_not_tested = true
    hpxml_name = File.basename(@tmp_hpxml_path)
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)

    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_mech_vent(hpxml, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 56.3, hours: 24, power: 12.8 }])
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_mech_vent(hpxml, [{ fantype: HPXML::MechVentTypeSupply, flowrate: 800.0, hours: 24, power: 240.0, in_unit_flowrate: 30.0, frac_recirc: 0.5, has_preheat: true, has_precool: true },
                             { fantype: HPXML::MechVentTypeExhaust, flowrate: 72.0, hours: 24, power: 26.0 }])
  end

  def test_mech_vent_shared_unmeasured_airflow_rate_and_defaulted_fan_power
    # Create derivative file for testing
    hpxml_name = 'base-mechvent-shared-preconditioning.xml'
    hpxml = HPXML.new(hpxml_path: File.join(@root_path, 'workflow', 'sample_files', hpxml_name))
    vent_fan = hpxml.ventilation_fans.select { |vf| vf.used_for_whole_building_ventilation && vf.is_shared_system }[0]
    vent_fan.fan_power = nil
    vent_fan.fan_power_defaulted = true
    vent_fan.in_unit_flow_rate = nil
    vent_fan.flow_rate_not_tested = true
    hpxml_name = File.basename(@tmp_hpxml_path)
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)

    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_mech_vent(hpxml, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 56.3, hours: 24, power: 12.8 }])
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_mech_vent(hpxml, [{ fantype: HPXML::MechVentTypeSupply, flowrate: 800.0, hours: 24, power: 800.0, in_unit_flowrate: 30.0, frac_recirc: 0.5, has_preheat: true, has_precool: true },
                             { fantype: HPXML::MechVentTypeExhaust, flowrate: 72.0, hours: 24, power: 26.0 }])
  end

  def test_whole_house_fan
    hpxml_name = 'base-mechvent-whole-house-fan.xml'

    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_whf(hpxml)
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_whf(hpxml, flowrate: 4500, power: 300)
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentDesign)
    _check_whf(hpxml)
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentReferenceHome)
    _check_whf(hpxml)
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

  def _check_mech_vent(hpxml, all_expected_values = [])
    num_mech_vent = 0
    hpxml.ventilation_fans.each_with_index do |ventilation_fan, idx|
      next unless ventilation_fan.used_for_whole_building_ventilation

      expected_values = all_expected_values[idx]
      num_mech_vent += 1
      assert_equal(expected_values[:fantype], ventilation_fan.fan_type)
      assert_in_delta(expected_values[:flowrate], ventilation_fan.rated_flow_rate.to_f + ventilation_fan.tested_flow_rate.to_f, 0.1)
      assert_in_delta(expected_values[:hours], ventilation_fan.hours_in_operation, 0.1)
      assert_in_delta(expected_values[:power], ventilation_fan.fan_power, 0.1)
      if expected_values[:sre].nil?
        assert_nil(ventilation_fan.sensible_recovery_efficiency)
      else
        assert_equal(expected_values[:sre], ventilation_fan.sensible_recovery_efficiency)
      end
      if expected_values[:tre].nil?
        assert_nil(ventilation_fan.total_recovery_efficiency)
      else
        assert_equal(expected_values[:tre], ventilation_fan.total_recovery_efficiency)
      end
      if expected_values[:asre].nil?
        assert_nil(ventilation_fan.sensible_recovery_efficiency_adjusted)
      else
        assert_equal(expected_values[:asre], ventilation_fan.sensible_recovery_efficiency_adjusted)
      end
      if expected_values[:atre].nil?
        assert_nil(ventilation_fan.total_recovery_efficiency_adjusted)
      else
        assert_equal(expected_values[:atre], ventilation_fan.total_recovery_efficiency_adjusted)
      end
      if expected_values[:in_unit_flowrate].nil?
        assert_nil(ventilation_fan.in_unit_flow_rate)
      else
        assert_equal(true, ventilation_fan.is_shared_system)
        assert_in_delta(expected_values[:in_unit_flowrate], ventilation_fan.in_unit_flow_rate, 0.1)
      end
      if expected_values[:frac_recirc].nil?
        assert_nil(ventilation_fan.fraction_recirculation)
      else
        assert_equal(expected_values[:frac_recirc], ventilation_fan.fraction_recirculation)
      end
      if expected_values[:has_preheat].nil? || (not expected_values[:has_preheat])
        assert_nil(ventilation_fan.preheating_fuel)
      else
        refute_nil(ventilation_fan.preheating_fuel)
      end
      if expected_values[:has_precool].nil? || (not expected_values[:has_precool])
        assert_nil(ventilation_fan.precooling_fuel)
      else
        refute_nil(ventilation_fan.precooling_fuel)
      end
    end
    assert_equal(all_expected_values.size, num_mech_vent)
  end

  def _check_whf(hpxml, flowrate: nil, power: nil)
    num_whf = 0
    hpxml.ventilation_fans.each do |ventilation_fan|
      next unless ventilation_fan.used_for_seasonal_cooling_load_reduction

      num_whf += 1
      assert_in_epsilon(flowrate, ventilation_fan.rated_flow_rate, 0.01)
      assert_in_epsilon(power, ventilation_fan.fan_power, 0.01)
    end
    if flowrate.nil?
      assert_equal(0, num_whf)
    else
      assert_equal(1, num_whf)
    end
  end
end
