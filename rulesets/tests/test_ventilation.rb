# frozen_string_literal: true

require_relative '../../hpxml-measures/HPXMLtoOpenStudio/resources/minitest_helper'
require 'openstudio'
require_relative '../main.rb'
require 'fileutils'
require_relative 'util.rb'
require_relative '../../workflow/design'

class ERIMechVentTest < Minitest::Test
  def setup
    @root_path = File.absolute_path(File.join(File.dirname(__FILE__), '..', '..'))
    @sample_files_path = File.join(@root_path, 'workflow', 'sample_files')
    @tmp_hpxml_path = File.join(@sample_files_path, 'tmp.xml')
    @schema_validator = XMLValidator.get_xml_validator(File.join(@root_path, 'hpxml-measures', 'HPXMLtoOpenStudio', 'resources', 'hpxml_schema', 'HPXML.xsd'))
    @epvalidator = XMLValidator.get_xml_validator(File.join(@root_path, 'hpxml-measures', 'HPXMLtoOpenStudio', 'resources', 'hpxml_schematron', 'EPvalidator.sch'))
    @erivalidator = XMLValidator.get_xml_validator(File.join(@root_path, 'rulesets', 'resources', '301validator.sch'))
    @results_paths = []
  end

  def teardown
    File.delete(@tmp_hpxml_path) if File.exist? @tmp_hpxml_path
    @results_paths.each do |results_path|
      FileUtils.rm_rf(results_path) if Dir.exist? results_path
    end
    @results_paths.clear
    puts
  end

  def test_mech_vent_none
    hpxml_name = 'base.xml'

    _test_ruleset(hpxml_name).each do |(_run_type, calc_type), hpxml_bldg|
      if [CalcType::ReferenceHome].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 27.0, hours: 24, power: 0.0 }]) # Should have airflow but not fan energy
      elsif [CalcType::RatedHome].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 3.0, hours: 24, power: 2.1 }]) # Supplemental balanced ventilation to meet total airflow requirement
      elsif [CalcType::IndexAdjHome].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 60.1, hours: 24, power: 42.0 }])
      elsif [CalcType::IndexAdjReferenceHome].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 8.7, hours: 24, power: 42.0 }])
      end
    end

    _test_ruleset(hpxml_name, '2019ABCD').each do |(_run_type, calc_type), hpxml_bldg|
      if [CalcType::ReferenceHome].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 27.0, hours: 24, power: 0.0 }]) # Should have airflow but not fan energy
      elsif [CalcType::RatedHome].include? calc_type
        _check_mech_vent(hpxml_bldg)
      elsif [CalcType::IndexAdjHome].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 60.1, hours: 24, power: 42.0 }])
      elsif [CalcType::IndexAdjReferenceHome].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 8.7, hours: 24, power: 42.0 }])
      end
    end

    _test_ruleset(hpxml_name, '2014').each do |(_run_type, calc_type), hpxml_bldg|
      if [CalcType::ReferenceHome].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 37.0, hours: 24, power: 0.0 }]) # Should have airflow but not fan energy
      elsif [CalcType::RatedHome].include? calc_type
        _check_mech_vent(hpxml_bldg)
      elsif [CalcType::IndexAdjHome].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 60.1, hours: 24, power: 42.0 }])
      elsif [CalcType::IndexAdjReferenceHome].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 34.0, hours: 24, power: 42.0 }])
      end
    end
  end

  def test_mech_vent_none_attached_housing
    hpxml_name = 'base-bldgtype-mf-unit.xml'

    _test_ruleset(hpxml_name).each do |(_run_type, calc_type), hpxml_bldg|
      if [CalcType::ReferenceHome].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 31.1, hours: 24, power: 0.0 }]) # Should have airflow but not fan energy
      elsif [CalcType::RatedHome].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 48.1, hours: 24, power: 33.7 }]) # Supplemental balanced ventilation to meet total airflow requirement
      elsif [CalcType::IndexAdjHome].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 60.1, hours: 24, power: 42.0 }])
      elsif [CalcType::IndexAdjReferenceHome].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 8.7, hours: 24, power: 49.4 }])
      end
    end

    _test_ruleset(hpxml_name, '2019ABCD').each do |(_run_type, calc_type), hpxml_bldg|
      if [CalcType::ReferenceHome].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 31.1, hours: 24, power: 0.0 }]) # Should have airflow but not fan energy
      elsif [CalcType::RatedHome].include? calc_type
        _check_mech_vent(hpxml_bldg)
      elsif [CalcType::IndexAdjHome].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 60.1, hours: 24, power: 42.0 }])
      elsif [CalcType::IndexAdjReferenceHome].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 8.7, hours: 24, power: 49.4 }])
      end
    end

    _test_ruleset(hpxml_name, '2014').each do |(_run_type, calc_type), hpxml_bldg|
      if [CalcType::ReferenceHome].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 57.0, hours: 24, power: 0.0 }]) # Should have airflow but not fan energy
      elsif [CalcType::RatedHome].include? calc_type
        _check_mech_vent(hpxml_bldg)
      elsif [CalcType::IndexAdjHome].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 102.0, hours: 24, power: 71.4 }])
      elsif [CalcType::IndexAdjReferenceHome].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 102.0, hours: 24, power: 71.4 }])
      end
    end
  end

  def test_mech_vent_exhaust
    hpxml_name = 'base-mechvent-exhaust.xml'

    _test_ruleset(hpxml_name).each do |(_run_type, calc_type), hpxml_bldg|
      if [CalcType::ReferenceHome].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 27.0, hours: 24, power: 35.6 }])
      elsif [CalcType::RatedHome].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeExhaust, flowrate: 110.0, hours: 24, power: 30.0 }])
      elsif [CalcType::IndexAdjHome].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 60.1, hours: 24, power: 42.0 }])
      elsif [CalcType::IndexAdjReferenceHome].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 8.7, hours: 24, power: 42.0 }])
      end
    end

    _test_ruleset(hpxml_name, '2019ABCD').each do |(_run_type, calc_type), hpxml_bldg|
      if [CalcType::ReferenceHome].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 27.0, hours: 24, power: 34.9 }])
      elsif [CalcType::RatedHome].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeExhaust, flowrate: 110.0, hours: 24, power: 30.0 }])
      elsif [CalcType::IndexAdjHome].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 60.1, hours: 24, power: 42.0 }])
      elsif [CalcType::IndexAdjReferenceHome].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 8.7, hours: 24, power: 42.0 }])
      end
    end

    _test_ruleset(hpxml_name, '2014').each do |(_run_type, calc_type), hpxml_bldg|
      if [CalcType::ReferenceHome].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 37.0, hours: 24, power: 26.4 }])
      elsif [CalcType::RatedHome].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeExhaust, flowrate: 110.0, hours: 24, power: 30.0 }])
      elsif [CalcType::IndexAdjHome].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 60.1, hours: 24, power: 42.0 }])
      elsif [CalcType::IndexAdjReferenceHome].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 34.0, hours: 24, power: 42.0 }])
      end
    end
  end

  def test_mech_vent_exhaust_below_ashrae_622
    # Test Rated Home:
    # For residences with Whole-House Mechanical Ventilation Systems, the measured infiltration rate
    # combined with the time-averaged Whole-House Mechanical Ventilation System rate, which shall
    # not be less than 0.03 x CFA + 7.5 x (Nbr+1) cfm

    # Create derivative file for testing
    hpxml_name = 'base-mechvent-exhaust.xml'
    hpxml = HPXML.new(hpxml_path: File.join(@root_path, 'workflow', 'sample_files', hpxml_name))
    hpxml_bldg = hpxml.buildings[0]
    vent_fan = hpxml_bldg.ventilation_fans.find { |vf| vf.used_for_whole_building_ventilation }
    vent_fan.hours_in_operation = 12
    hpxml_name = File.basename(@tmp_hpxml_path)
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)

    _test_ruleset(hpxml_name).each do |(_run_type, calc_type), hpxml_bldg|
      if [CalcType::ReferenceHome].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 27.0, hours: 24, power: 35.6 }])
      elsif [CalcType::RatedHome].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeExhaust, flowrate: 110.0, hours: 22.2, power: 30.0 }]) # Increased fan power
      elsif [CalcType::IndexAdjHome].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 60.1, hours: 24, power: 42.0 }])
      elsif [CalcType::IndexAdjReferenceHome].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 8.7, hours: 24, power: 42.0 }])
      end
    end

    _test_ruleset(hpxml_name, '2019ABCD').each do |(_run_type, calc_type), hpxml_bldg|
      if [CalcType::ReferenceHome].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 27.0, hours: 24, power: 34.9 }])
      elsif [CalcType::RatedHome].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeExhaust, flowrate: 110.0, hours: 21.7, power: 30.0 }]) # Increased fan power
      elsif [CalcType::IndexAdjHome].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 60.1, hours: 24, power: 42.0 }])
      elsif [CalcType::IndexAdjReferenceHome].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 8.7, hours: 24, power: 42.0 }])
      end
    end

    _test_ruleset(hpxml_name, '2014').each do |(_run_type, calc_type), hpxml_bldg|
      if [CalcType::ReferenceHome].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 37.0, hours: 24, power: 26.4 }])
      elsif [CalcType::RatedHome].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeExhaust, flowrate: 110.0, hours: 16.5, power: 30.0 }]) # Increased fan power
      elsif [CalcType::IndexAdjHome].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 60.1, hours: 24, power: 42.0 }])
      elsif [CalcType::IndexAdjReferenceHome].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 34.0, hours: 24, power: 42.0 }])
      end
    end
  end

  def test_mech_vent_exhaust_defaulted_fan_power
    # Create derivative file for testing
    hpxml_name = 'base-mechvent-exhaust.xml'
    hpxml = HPXML.new(hpxml_path: File.join(@root_path, 'workflow', 'sample_files', hpxml_name))
    hpxml_bldg = hpxml.buildings[0]
    vent_fan = hpxml_bldg.ventilation_fans.find { |vf| vf.used_for_whole_building_ventilation }
    vent_fan.fan_power = nil
    vent_fan.fan_power_defaulted = true
    vent_fan.hours_in_operation = 12
    vent_fan.tested_flow_rate = 10.0
    hpxml_name = File.basename(@tmp_hpxml_path)
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)

    _test_ruleset(hpxml_name).each do |(_run_type, calc_type), hpxml_bldg|
      if [CalcType::ReferenceHome].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 27.0, hours: 24, power: 35.6 }])
      elsif [CalcType::RatedHome].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeExhaust, flowrate: 101.8, hours: 24, power: 35.6 }])
      elsif [CalcType::IndexAdjHome].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 60.1, hours: 24, power: 42.0 }])
      elsif [CalcType::IndexAdjReferenceHome].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 8.7, hours: 24, power: 42.0 }])
      end
    end

    _test_ruleset(hpxml_name, '2019ABCD').each do |(_run_type, calc_type), hpxml_bldg|
      if [CalcType::ReferenceHome].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 27.0, hours: 24, power: 34.9 }])
      elsif [CalcType::RatedHome].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeExhaust, flowrate: 99.6, hours: 24, power: 34.9 }])
      elsif [CalcType::IndexAdjHome].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 60.1, hours: 24, power: 42.0 }])
      elsif [CalcType::IndexAdjReferenceHome].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 8.7, hours: 24, power: 42.0 }])
      end
    end

    _test_ruleset(hpxml_name, '2014').each do |(_run_type, calc_type), hpxml_bldg|
      if [CalcType::ReferenceHome].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 37.0, hours: 24, power: 26.4 }])
      elsif [CalcType::RatedHome].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeExhaust, flowrate: 75.4, hours: 24, power: 26.4 }])
      elsif [CalcType::IndexAdjHome].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 60.1, hours: 24, power: 42.0 }])
      elsif [CalcType::IndexAdjReferenceHome].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 34.0, hours: 24, power: 42.0 }])
      end
    end
  end

  def test_mech_vent_exhaust_unmeasured_airflow_rate
    # Create derivative file for testing
    hpxml_name = 'base-mechvent-exhaust.xml'
    hpxml = HPXML.new(hpxml_path: File.join(@root_path, 'workflow', 'sample_files', hpxml_name))
    hpxml_bldg = hpxml.buildings[0]
    vent_fan = hpxml_bldg.ventilation_fans.find { |vf| vf.used_for_whole_building_ventilation }
    vent_fan.tested_flow_rate = nil
    vent_fan.flow_rate_not_tested = true
    vent_fan.hours_in_operation = 24
    hpxml_name = File.basename(@tmp_hpxml_path)
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)

    _test_ruleset(hpxml_name).each do |(_run_type, calc_type), hpxml_bldg|
      if [CalcType::ReferenceHome].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 27.0, hours: 24, power: 6.8 }])
      elsif [CalcType::RatedHome].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeExhaust, flowrate: 19.6, hours: 24, power: 30.0 }])
      elsif [CalcType::IndexAdjHome].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 60.1, hours: 24, power: 42.0 }])
      elsif [CalcType::IndexAdjReferenceHome].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 8.7, hours: 24, power: 42.0 }])
      end
    end

    _test_ruleset(hpxml_name, '2019ABCD').each do |(_run_type, calc_type), hpxml_bldg|
      if [CalcType::ReferenceHome].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 27.0, hours: 24, power: 2.1 }])
      elsif [CalcType::RatedHome].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeExhaust, flowrate: 15.0, hours: 24, power: 30.0 }])
      elsif [CalcType::IndexAdjHome].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 60.1, hours: 24, power: 42.0 }])
      elsif [CalcType::IndexAdjReferenceHome].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 8.7, hours: 24, power: 42.0 }])
      end
    end

    _test_ruleset(hpxml_name, '2014').each do |(_run_type, calc_type), hpxml_bldg|
      if [CalcType::ReferenceHome].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 37.0, hours: 24, power: 26.4 }])
      elsif [CalcType::RatedHome].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeExhaust, flowrate: 75.4, hours: 24, power: 30.0 }])
      elsif [CalcType::IndexAdjHome].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 60.1, hours: 24, power: 42.0 }])
      elsif [CalcType::IndexAdjReferenceHome].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 34.0, hours: 24, power: 42.0 }])
      end
    end
  end

  def test_mech_vent_exhaust_unmeasured_airflow_rate_and_defaulted_fan_power
    # Create derivative file for testing
    hpxml_name = 'base-mechvent-exhaust.xml'
    hpxml = HPXML.new(hpxml_path: File.join(@root_path, 'workflow', 'sample_files', hpxml_name))
    hpxml_bldg = hpxml.buildings[0]
    vent_fan = hpxml_bldg.ventilation_fans.find { |vf| vf.used_for_whole_building_ventilation }
    vent_fan.fan_power = nil
    vent_fan.fan_power_defaulted = true
    vent_fan.tested_flow_rate = nil
    vent_fan.flow_rate_not_tested = true
    vent_fan.hours_in_operation = 24
    hpxml_name = File.basename(@tmp_hpxml_path)
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)

    _test_ruleset(hpxml_name).each do |(_run_type, calc_type), hpxml_bldg|
      if [CalcType::ReferenceHome].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 27.0, hours: 24, power: 6.8 }])
      elsif [CalcType::RatedHome].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeExhaust, flowrate: 19.6, hours: 24, power: 6.8 }])
      elsif [CalcType::IndexAdjHome].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 60.1, hours: 24, power: 42.0 }])
      elsif [CalcType::IndexAdjReferenceHome].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 8.7, hours: 24, power: 42.0 }])
      end
    end

    _test_ruleset(hpxml_name, '2019ABCD').each do |(_run_type, calc_type), hpxml_bldg|
      if [CalcType::ReferenceHome].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 27.0, hours: 24, power: 2.1 }])
      elsif [CalcType::RatedHome].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeExhaust, flowrate: 15.0, hours: 24, power: 5.3 }])
      elsif [CalcType::IndexAdjHome].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 60.1, hours: 24, power: 42.0 }])
      elsif [CalcType::IndexAdjReferenceHome].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 8.7, hours: 24, power: 42.0 }])
      end
    end

    _test_ruleset(hpxml_name, '2014').each do |(_run_type, calc_type), hpxml_bldg|
      if [CalcType::ReferenceHome].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 37.0, hours: 24, power: 26.4 }])
      elsif [CalcType::RatedHome].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeExhaust, flowrate: 75.4, hours: 24, power: 26.4 }])
      elsif [CalcType::IndexAdjHome].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 60.1, hours: 24, power: 42.0 }])
      elsif [CalcType::IndexAdjReferenceHome].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 34.0, hours: 24, power: 42.0 }])
      end
    end
  end

  def test_mech_vent_supply
    hpxml_name = 'base-mechvent-supply.xml'

    _test_ruleset(hpxml_name).each do |(_run_type, calc_type), hpxml_bldg|
      if [CalcType::ReferenceHome].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 27.0, hours: 24, power: 35.6 }])
      elsif [CalcType::RatedHome].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeSupply, flowrate: 110.0, hours: 24, power: 30.0 }])
      elsif [CalcType::IndexAdjHome].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 60.1, hours: 24, power: 42.0 }])
      elsif [CalcType::IndexAdjReferenceHome].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 8.7, hours: 24, power: 42.0 }])
      end
    end

    _test_ruleset(hpxml_name, '2019ABCD').each do |(_run_type, calc_type), hpxml_bldg|
      if [CalcType::ReferenceHome].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 27.0, hours: 24, power: 34.9 }])
      elsif [CalcType::RatedHome].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeSupply, flowrate: 110.0, hours: 24, power: 30.0 }])
      elsif [CalcType::IndexAdjHome].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 60.1, hours: 24, power: 42.0 }])
      elsif [CalcType::IndexAdjReferenceHome].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 8.7, hours: 24, power: 42.0 }])
      end
    end

    _test_ruleset(hpxml_name, '2014').each do |(_run_type, calc_type), hpxml_bldg|
      if [CalcType::ReferenceHome].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 37.0, hours: 24, power: 26.4 }])
      elsif [CalcType::RatedHome].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeSupply, flowrate: 110.0, hours: 24, power: 30.0 }])
      elsif [CalcType::IndexAdjHome].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 60.1, hours: 24, power: 42.0 }])
      elsif [CalcType::IndexAdjReferenceHome].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 34.0, hours: 24, power: 42.0 }])
      end
    end
  end

  def test_mech_vent_balanced
    hpxml_name = 'base-mechvent-balanced.xml'

    _test_ruleset(hpxml_name).each do |(_run_type, calc_type), hpxml_bldg|
      if [CalcType::ReferenceHome].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 27.0, hours: 24, power: 52.8 }])
      elsif [CalcType::RatedHome].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 110.0, hours: 24, power: 60.0 }])
      elsif [CalcType::IndexAdjHome].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 60.1, hours: 24, power: 42.0 }])
      elsif [CalcType::IndexAdjReferenceHome].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 8.7, hours: 24, power: 42.0 }])
      end
    end

    _test_ruleset(hpxml_name, '2014').each do |(_run_type, calc_type), hpxml_bldg|
      if [CalcType::ReferenceHome].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 37.0, hours: 24, power: 52.8 }])
      elsif [CalcType::RatedHome].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 110.0, hours: 24, power: 60.0 }])
      elsif [CalcType::IndexAdjHome].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 60.1, hours: 24, power: 42.0 }])
      elsif [CalcType::IndexAdjReferenceHome].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 34.0, hours: 24, power: 42.0 }])
      end
    end
  end

  def test_mech_vent_erv
    hpxml_name = 'base-mechvent-erv.xml'

    _test_ruleset(hpxml_name).each do |(_run_type, calc_type), hpxml_bldg|
      if [CalcType::ReferenceHome].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 27.0, hours: 24, power: 75.4 }])
      elsif [CalcType::RatedHome].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeERV, flowrate: 110.0, hours: 24, power: 60.0, sre: 0.7, tre: 0.6 }])
      elsif [CalcType::IndexAdjHome].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 60.1, hours: 24, power: 42.0 }])
      elsif [CalcType::IndexAdjReferenceHome].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 8.7, hours: 24, power: 42.0 }])
      end
    end

    _test_ruleset(hpxml_name, '2014').each do |(_run_type, calc_type), hpxml_bldg|
      if [CalcType::ReferenceHome].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 37.0, hours: 24, power: 75.4 }])
      elsif [CalcType::RatedHome].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeERV, flowrate: 110.0, hours: 24, power: 60.0, sre: 0.7, tre: 0.6 }])
      elsif [CalcType::IndexAdjHome].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 60.1, hours: 24, power: 42.0 }])
      elsif [CalcType::IndexAdjReferenceHome].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 34.0, hours: 24, power: 42.0 }])
      end
    end
  end

  def test_mech_vent_erv_adjusted
    hpxml_name = 'base-mechvent-erv-atre-asre.xml'

    _test_ruleset(hpxml_name).each do |(_run_type, calc_type), hpxml_bldg|
      if [CalcType::ReferenceHome].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 27.0, hours: 24, power: 75.4 }])
      elsif [CalcType::RatedHome].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeERV, flowrate: 110.0, hours: 24, power: 60.0, asre: 0.77, atre: 0.66 }])
      elsif [CalcType::IndexAdjHome].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 60.1, hours: 24, power: 42.0 }])
      elsif [CalcType::IndexAdjReferenceHome].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 8.7, hours: 24, power: 42.0 }])
      end
    end

    _test_ruleset(hpxml_name, '2014').each do |(_run_type, calc_type), hpxml_bldg|
      if [CalcType::ReferenceHome].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 37.0, hours: 24, power: 75.4 }])
      elsif [CalcType::RatedHome].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeERV, flowrate: 110.0, hours: 24, power: 60.0, asre: 0.77, atre: 0.66 }])
      elsif [CalcType::IndexAdjHome].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 60.1, hours: 24, power: 42.0 }])
      elsif [CalcType::IndexAdjReferenceHome].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 34.0, hours: 24, power: 42.0 }])
      end
    end
  end

  def test_mech_vent_hrv
    hpxml_name = 'base-mechvent-hrv.xml'

    _test_ruleset(hpxml_name).each do |(_run_type, calc_type), hpxml_bldg|
      if [CalcType::ReferenceHome].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 27.0, hours: 24, power: 75.4 }])
      elsif [CalcType::RatedHome].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeHRV, flowrate: 110.0, hours: 24, power: 60.0, sre: 0.7 }])
      elsif [CalcType::IndexAdjHome].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 60.1, hours: 24, power: 42.0 }])
      elsif [CalcType::IndexAdjReferenceHome].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 8.7, hours: 24, power: 42.0 }])
      end
    end

    _test_ruleset(hpxml_name, '2014').each do |(_run_type, calc_type), hpxml_bldg|
      if [CalcType::ReferenceHome].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 37.0, hours: 24, power: 75.4 }])
      elsif [CalcType::RatedHome].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeHRV, flowrate: 110.0, hours: 24, power: 60.0, sre: 0.7 }])
      elsif [CalcType::IndexAdjHome].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 60.1, hours: 24, power: 42.0 }])
      elsif [CalcType::IndexAdjReferenceHome].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 34.0, hours: 24, power: 42.0 }])
      end
    end
  end

  def test_mech_vent_hrv_adjusted
    hpxml_name = 'base-mechvent-hrv-asre.xml'

    _test_ruleset(hpxml_name).each do |(_run_type, calc_type), hpxml_bldg|
      if [CalcType::ReferenceHome].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 27.0, hours: 24, power: 75.4 }])
      elsif [CalcType::RatedHome].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeHRV, flowrate: 110.0, hours: 24, power: 60.0, asre: 0.77 }])
      elsif [CalcType::IndexAdjHome].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 60.1, hours: 24, power: 42.0 }])
      elsif [CalcType::IndexAdjReferenceHome].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 8.7, hours: 24, power: 42.0 }])
      end
    end

    _test_ruleset(hpxml_name, '2014').each do |(_run_type, calc_type), hpxml_bldg|
      if [CalcType::ReferenceHome].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 37.0, hours: 24, power: 75.4 }])
      elsif [CalcType::RatedHome].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeHRV, flowrate: 110.0, hours: 24, power: 60.0, asre: 0.77 }])
      elsif [CalcType::IndexAdjHome].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 60.1, hours: 24, power: 42.0 }])
      elsif [CalcType::IndexAdjReferenceHome].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 34.0, hours: 24, power: 42.0 }])
      end
    end
  end

  def test_mech_vent_cfis
    hpxml_names = ['base-mechvent-cfis.xml',
                   'base-mechvent-cfis-supplemental-fan-exhaust.xml',
                   'base-mechvent-cfis-supplemental-fan-exhaust-synchronized.xml',
                   'base-mechvent-cfis-no-additional-runtime.xml',
                   'base-mechvent-cfis-no-outdoor-air-control.xml',
                   'base-mechvent-cfis-control-type-timer.xml']

    hpxml_names.each do |hpxml_name|
      cfis_suppl_flowrate = nil
      cfis_suppl_power = nil
      cfis_suppl_fan_sync = nil
      cfis_control_type = HPXML::CFISControlTypeOptimized
      if ['base-mechvent-cfis.xml',
          'base-mechvent-cfis-no-outdoor-air-control.xml'].include? hpxml_name
        cfis_mode = HPXML::CFISModeAirHandler
      elsif ['base-mechvent-cfis-supplemental-fan-exhaust.xml',
             'base-mechvent-cfis-supplemental-fan-exhaust-synchronized.xml'].include? hpxml_name
        cfis_mode = HPXML::CFISModeSupplementalFan
        cfis_suppl_flowrate = 120.0
        cfis_suppl_power = 30.0
        cfis_suppl_fan_sync = (hpxml_name == 'base-mechvent-cfis-supplemental-fan-exhaust-synchronized.xml')
      elsif ['base-mechvent-cfis-no-additional-runtime.xml'].include? hpxml_name
        cfis_mode = HPXML::CFISModeNone
      elsif ['base-mechvent-cfis-control-type-timer.xml'].include? hpxml_name
        cfis_mode = HPXML::CFISModeAirHandler
        cfis_control_type = HPXML::CFISControlTypeTimer
      end

      _test_ruleset(hpxml_name).each do |(_run_type, calc_type), hpxml_bldg|
        if [CalcType::ReferenceHome].include? calc_type
          if hpxml_name == 'base-mechvent-cfis-no-additional-runtime.xml'
            # CFIS doesn't qualify as a Dwelling Unit Mechanical Ventilation System, so rated home gets 0.3 nACH and
            # ventilation requirement is lower, resulting in lower Reference Home fan power
            _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 27.0, hours: 24, power: 6.8 }])
          else
            _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 27.0, hours: 24, power: 35.6 }])
          end
        elsif [CalcType::RatedHome].include? calc_type
          _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeCFIS, flowrate: 330.0, hours: 8, cfis_mode: cfis_mode,
                                          cfis_suppl_flowrate: cfis_suppl_flowrate, cfis_suppl_power: cfis_suppl_power,
                                          cfis_suppl_fan_sync: cfis_suppl_fan_sync, cfis_control_type: cfis_control_type }])
        elsif [CalcType::IndexAdjHome].include? calc_type
          _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 60.1, hours: 24, power: 42.0 }])
        elsif [CalcType::IndexAdjReferenceHome].include? calc_type
          _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 8.7, hours: 24, power: 42.0 }])
        end
      end

      _test_ruleset(hpxml_name, '2019ABCD').each do |(_run_type, calc_type), hpxml_bldg|
        if [CalcType::ReferenceHome].include? calc_type
          _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 27.0, hours: 24, power: 34.9 }])
        elsif [CalcType::RatedHome].include? calc_type
          _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeCFIS, flowrate: 330.0, hours: 8, cfis_mode: cfis_mode,
                                          cfis_suppl_flowrate: cfis_suppl_flowrate, cfis_suppl_power: cfis_suppl_power,
                                          cfis_suppl_fan_sync: cfis_suppl_fan_sync, cfis_control_type: cfis_control_type }])
        elsif [CalcType::IndexAdjHome].include? calc_type
          _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 60.1, hours: 24, power: 42.0 }])
        elsif [CalcType::IndexAdjReferenceHome].include? calc_type
          _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 8.7, hours: 24, power: 42.0 }])
        end
      end

      _test_ruleset(hpxml_name, '2014').each do |(_run_type, calc_type), hpxml_bldg|
        if [CalcType::ReferenceHome].include? calc_type
          _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 37.0, hours: 24, power: 26.4 }])
        elsif [CalcType::RatedHome].include? calc_type
          _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeCFIS, flowrate: 330.0, hours: 8, cfis_mode: cfis_mode,
                                          cfis_suppl_flowrate: cfis_suppl_flowrate, cfis_suppl_power: cfis_suppl_power,
                                          cfis_suppl_fan_sync: cfis_suppl_fan_sync, cfis_control_type: cfis_control_type }])
        elsif [CalcType::IndexAdjHome].include? calc_type
          _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 60.1, hours: 24, power: 42.0 }])
        elsif [CalcType::IndexAdjReferenceHome].include? calc_type
          _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 34.0, hours: 24, power: 42.0 }])
        end
      end
    end
  end

  def test_mech_vent_cfis_unmeasured_airflow_rate
    # Create derivative file for testing
    hpxml_name = 'base-mechvent-cfis.xml'
    hpxml = HPXML.new(hpxml_path: File.join(@root_path, 'workflow', 'sample_files', hpxml_name))
    hpxml_bldg = hpxml.buildings[0]
    vent_fan = hpxml_bldg.ventilation_fans.find { |vf| vf.used_for_whole_building_ventilation }
    vent_fan.tested_flow_rate = nil
    vent_fan.flow_rate_not_tested = true
    vent_fan.hours_in_operation = 8
    hpxml_name = File.basename(@tmp_hpxml_path)
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)

    _test_ruleset(hpxml_name).each do |(_run_type, calc_type), hpxml_bldg|
      if calc_type == CalcType::RatedHome
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeCFIS, flowrate: 58.7, hours: 8, cfis_mode: HPXML::CFISModeAirHandler,
                                        cfis_control_type: HPXML::CFISControlTypeOptimized }])
      end
    end

    # Create derivative file for testing
    hpxml_name = 'base-mechvent-cfis-supplemental-fan-exhaust.xml'
    hpxml = HPXML.new(hpxml_path: File.join(@root_path, 'workflow', 'sample_files', hpxml_name))
    hpxml_bldg = hpxml.buildings[0]
    vent_fan_suppl = hpxml_bldg.ventilation_fans.find { |vf| vf.is_cfis_supplemental_fan }
    vent_fan_suppl.fan_power = nil
    vent_fan_suppl.fan_power_defaulted = true
    vent_fan_suppl.tested_flow_rate = nil
    vent_fan_suppl.flow_rate_not_tested = true
    hpxml_name = File.basename(@tmp_hpxml_path)
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)

    _test_ruleset(hpxml_name).each do |(_run_type, calc_type), hpxml_bldg|
      next unless calc_type == CalcType::RatedHome

      _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeCFIS, flowrate: 330.0, hours: 8,
                                      cfis_mode: HPXML::CFISModeSupplementalFan, cfis_suppl_flowrate: 110.0, cfis_suppl_power: 38.5,
                                      cfis_suppl_fan_sync: false, cfis_control_type: HPXML::CFISControlTypeOptimized }])
    end
  end

  def test_mech_vent_cfm50_infiltration
    # Create derivative file for testing
    hpxml_name = 'base-enclosure-infil-cfm50.xml'

    _test_ruleset(hpxml_name, '2014').each do |(_run_type, calc_type), hpxml_bldg|
      if [CalcType::ReferenceHome].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 37.0, hours: 24, power: 0.0 }]) # Should have airflow but not fan energy
      elsif [CalcType::RatedHome].include? calc_type
        _check_mech_vent(hpxml_bldg)
      elsif [CalcType::IndexAdjHome].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 60.1, hours: 24, power: 42.0 }])
      elsif [CalcType::IndexAdjReferenceHome].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 34.0, hours: 24, power: 42.0 }])
      end
    end
  end

  def test_mech_vent_shared
    hpxml_name = 'base-bldgtype-mf-unit-shared-mechvent-preconditioning.xml'

    _test_ruleset(hpxml_name).each do |(_run_type, calc_type), hpxml_bldg|
      if [CalcType::ReferenceHome].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 31.1, hours: 24, power: 19.6 }])
      elsif [CalcType::RatedHome].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeSupply, flowrate: 800.0, hours: 24, power: 240.0, in_unit_flowrate: 80.0, frac_recirc: 0.5, has_preheat: true, has_precool: true },
                                      { fantype: HPXML::MechVentTypeExhaust, flowrate: 72.0, hours: 24, power: 26.0 }])
      elsif [CalcType::IndexAdjHome].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 60.1, hours: 24, power: 42.0 }])
      elsif [CalcType::IndexAdjReferenceHome].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 8.7, hours: 24, power: 49.4 }])
      end
    end

    _test_ruleset(hpxml_name, '2019ABCD').each do |(_run_type, calc_type), hpxml_bldg|
      if [CalcType::ReferenceHome].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 31.1, hours: 24, power: 19.0 }])
      elsif [CalcType::RatedHome].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeSupply, flowrate: 800.0, hours: 24, power: 240.0, in_unit_flowrate: 80.0, frac_recirc: 0.5, has_preheat: true, has_precool: true },
                                      { fantype: HPXML::MechVentTypeExhaust, flowrate: 72.0, hours: 24, power: 26.0 }])
      elsif [CalcType::IndexAdjHome].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 60.1, hours: 24, power: 42.0 }])
      elsif [CalcType::IndexAdjReferenceHome].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 8.7, hours: 24, power: 49.4 }])
      end
    end
  end

  def test_mech_vent_shared_defaulted_fan_power
    # Create derivative file for testing
    hpxml_name = 'base-bldgtype-mf-unit-shared-mechvent-preconditioning.xml'
    hpxml = HPXML.new(hpxml_path: File.join(@root_path, 'workflow', 'sample_files', hpxml_name))
    hpxml_bldg = hpxml.buildings[0]
    vent_fan = hpxml_bldg.ventilation_fans.find { |vf| vf.used_for_whole_building_ventilation && vf.is_shared_system }
    vent_fan.fan_power = nil
    vent_fan.fan_power_defaulted = true
    hpxml_name = File.basename(@tmp_hpxml_path)
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)

    _test_ruleset(hpxml_name).each do |(_run_type, calc_type), hpxml_bldg|
      if [CalcType::ReferenceHome].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 31.1, hours: 24, power: 19.6 }])
      elsif [CalcType::RatedHome].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeSupply, flowrate: 800.0, hours: 24, power: 800.0, in_unit_flowrate: 80.0, frac_recirc: 0.5, has_preheat: true, has_precool: true },
                                      { fantype: HPXML::MechVentTypeExhaust, flowrate: 72.0, hours: 24, power: 26.0 }])
      end
    end
  end

  def test_mech_vent_shared_unmeasured_airflow_rate
    # Create derivative file for testing
    hpxml_name = 'base-bldgtype-mf-unit-shared-mechvent-preconditioning.xml'
    hpxml = HPXML.new(hpxml_path: File.join(@root_path, 'workflow', 'sample_files', hpxml_name))
    hpxml_bldg = hpxml.buildings[0]
    vent_fan = hpxml_bldg.ventilation_fans.find { |vf| vf.used_for_whole_building_ventilation && vf.is_shared_system }
    vent_fan.in_unit_flow_rate = nil
    vent_fan.flow_rate_not_tested = true
    hpxml_name = File.basename(@tmp_hpxml_path)
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)

    _test_ruleset(hpxml_name).each do |(_run_type, calc_type), hpxml_bldg|
      if [CalcType::ReferenceHome].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 31.1, hours: 24, power: 19.5 }])
      elsif [CalcType::RatedHome].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeSupply, flowrate: 800.0, hours: 24, power: 240.0, in_unit_flowrate: 30.0, frac_recirc: 0.5, has_preheat: true, has_precool: true },
                                      { fantype: HPXML::MechVentTypeExhaust, flowrate: 72.0, hours: 24, power: 26.0 }])
      end
    end
  end

  def test_mech_vent_shared_unmeasured_airflow_rate_and_defaulted_fan_power
    # Create derivative file for testing
    hpxml_name = 'base-bldgtype-mf-unit-shared-mechvent-preconditioning.xml'
    hpxml = HPXML.new(hpxml_path: File.join(@root_path, 'workflow', 'sample_files', hpxml_name))
    hpxml_bldg = hpxml.buildings[0]
    vent_fan = hpxml_bldg.ventilation_fans.find { |vf| vf.used_for_whole_building_ventilation && vf.is_shared_system }
    vent_fan.fan_power = nil
    vent_fan.fan_power_defaulted = true
    vent_fan.in_unit_flow_rate = nil
    vent_fan.flow_rate_not_tested = true
    hpxml_name = File.basename(@tmp_hpxml_path)
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)

    _test_ruleset(hpxml_name).each do |(_run_type, calc_type), hpxml_bldg|
      if [CalcType::ReferenceHome].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 31.1, hours: 24, power: 19.5 }])
      elsif [CalcType::RatedHome].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeSupply, flowrate: 800.0, hours: 24, power: 800.0, in_unit_flowrate: 30.0, frac_recirc: 0.5, has_preheat: true, has_precool: true },
                                      { fantype: HPXML::MechVentTypeExhaust, flowrate: 72.0, hours: 24, power: 26.0 }])
      end
    end
  end

  def test_mech_vent_iecc_eri_exception
    IECC::AllVersions.each do |iecc_version|
      # Run IECC calculation
      hpxml_name = 'base-mechvent-exhaust.xml'
      iecc_hpxml_bldgs = _test_ruleset(hpxml_name, iecc_version, run_iecc: true)

      # Run non-IECC calculation (using same ERI version as above)
      eri_version = iecc_hpxml_bldgs.values[0].parent_object.header.eri_calculation_versions[0]
      base_hpxml_bldgs = _test_ruleset(hpxml_name, eri_version)

      iecc_hpxml_bldgs.keys.each do |bldg_key|
        run_type, calc_type = bldg_key
        next if run_type != RunType::IECC

        iecc_hpxml_bldg = iecc_hpxml_bldgs[[RunType::IECC, calc_type]]
        base_hpxml_bldg = base_hpxml_bldgs[[RunType::ERI, calc_type]]
        if ['2018', '2021'].include?(iecc_version) && calc_type == CalcType::ReferenceHome
          # Check that ventilation exception in 2018/2021 IECC is being applied to the ERI Reference Home
          refute_equal(iecc_hpxml_bldg.ventilation_fans[0].tested_flow_rate, base_hpxml_bldg.ventilation_fans[0].tested_flow_rate)
          assert_equal(57.0, iecc_hpxml_bldg.ventilation_fans[0].tested_flow_rate)
        else
          # In all other cases, check for the same ventilation as the standard ERI
          assert_equal(base_hpxml_bldg.ventilation_fans[0].tested_flow_rate, iecc_hpxml_bldg.ventilation_fans[0].tested_flow_rate)
        end
      end
    end
  end

  def test_whole_house_fan
    hpxml_name = 'base-mechvent-whole-house-fan.xml'

    _test_ruleset(hpxml_name).each do |(_run_type, calc_type), hpxml_bldg|
      if [CalcType::RatedHome].include? calc_type
        _check_whf(hpxml_bldg, flowrate: 4500, power: 300)
      else
        _check_whf(hpxml_bldg)
      end
    end
  end

  def _test_ruleset(hpxml_name, version = 'latest', run_iecc: false)
    print '.'

    designs = []
    _all_run_calc_types.each do |run_type, calc_type|
      run_type = RunType::IECC if run_iecc
      designs << Design.new(run_type: run_type,
                            calc_type: calc_type,
                            output_dir: @sample_files_path,
                            version: version)
    end

    hpxml_input_path = File.join(@sample_files_path, hpxml_name)
    success, errors, _, _, hpxml_bldgs = run_rulesets(hpxml_input_path, designs, @schema_validator, @erivalidator)

    errors.each do |s|
      puts "Error: #{s}"
    end

    # assert that it ran correctly
    assert(success)

    # validate against OS-HPXML schematron
    designs.each do |design|
      valid = @epvalidator.validate(design.hpxml_output_path)
      puts @epvalidator.errors.map { |e| e.logMessage } unless valid
      assert(valid)
      @results_paths << File.absolute_path(File.join(File.dirname(design.hpxml_output_path), '..'))
    end

    return hpxml_bldgs
  end

  def _check_mech_vent(hpxml_bldg, all_expected_values = [])
    num_mech_vent = 0
    hpxml_bldg.ventilation_fans.each_with_index do |ventilation_fan, idx|
      next unless ventilation_fan.used_for_whole_building_ventilation
      next if ventilation_fan.is_cfis_supplemental_fan

      expected_values = all_expected_values[idx]
      num_mech_vent += 1
      assert_equal(expected_values[:fantype], ventilation_fan.fan_type)
      assert_in_delta(expected_values[:flowrate], ventilation_fan.rated_flow_rate.to_f + ventilation_fan.tested_flow_rate.to_f, 0.1)
      assert_in_delta(expected_values[:hours], ventilation_fan.hours_in_operation, 0.1)
      if ventilation_fan.fan_type == HPXML::MechVentTypeCFIS
        if ventilation_fan.cfis_addtl_runtime_operating_mode == HPXML::CFISModeAirHandler
          # Power based on W/cfm x autosized blower fan airflow rate, so just check that it's non-zero
          assert_operator(ventilation_fan.fan_power, :>, 0)
        else
          assert_nil(ventilation_fan.fan_power)
        end
      else
        assert_in_delta(expected_values[:power], ventilation_fan.fan_power, 0.1)
      end
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
      if ventilation_fan.fan_type == HPXML::MechVentTypeCFIS && ventilation_fan.cfis_addtl_runtime_operating_mode == HPXML::CFISModeAirHandler
        assert_equal(1.0, ventilation_fan.cfis_vent_mode_airflow_fraction)
      else
        assert_nil(ventilation_fan.cfis_vent_mode_airflow_fraction)
      end
      if expected_values[:cfis_mode].nil?
        assert_nil(ventilation_fan.cfis_addtl_runtime_operating_mode)
      else
        assert_equal(expected_values[:cfis_mode], ventilation_fan.cfis_addtl_runtime_operating_mode)
      end
      cfis_suppl_fan = ventilation_fan.cfis_supplemental_fan
      if expected_values[:cfis_suppl_flowrate].nil?
        assert_nil(cfis_suppl_fan)
      else
        assert_in_delta(expected_values[:cfis_suppl_flowrate], cfis_suppl_fan.rated_flow_rate.to_f + cfis_suppl_fan.tested_flow_rate.to_f, 0.1)
      end
      if expected_values[:cfis_suppl_power].nil?
        assert_nil(cfis_suppl_fan)
      else
        assert_in_delta(expected_values[:cfis_suppl_power], cfis_suppl_fan.fan_power, 0.1)
      end
      if expected_values[:cfis_suppl_fan_sync].nil?
        assert_nil(ventilation_fan.cfis_supplemental_fan_runs_with_air_handler_fan)
      else
        assert_equal(expected_values[:cfis_suppl_fan_sync], ventilation_fan.cfis_supplemental_fan_runs_with_air_handler_fan)
      end
      if expected_values[:cfis_control_type].nil?
        assert_nil(ventilation_fan.cfis_control_type)
      else
        assert_equal(expected_values[:cfis_control_type], ventilation_fan.cfis_control_type)
      end
    end
    assert_equal(all_expected_values.size, num_mech_vent)
  end

  def _check_whf(hpxml_bldg, flowrate: nil, power: nil)
    num_whf = 0
    hpxml_bldg.ventilation_fans.each do |ventilation_fan|
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
