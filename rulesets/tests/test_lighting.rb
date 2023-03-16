# frozen_string_literal: true

require_relative '../../hpxml-measures/HPXMLtoOpenStudio/resources/minitest_helper'
require 'openstudio'
require_relative '../main.rb'
require 'fileutils'
require_relative 'util.rb'

class ERILightingTest < MiniTest::Test
  def setup
    @root_path = File.absolute_path(File.join(File.dirname(__FILE__), '..', '..'))
    @output_dir = File.join(@root_path, 'workflow', 'sample_files')
    @tmp_hpxml_path = File.join(@output_dir, 'tmp.xml')
  end

  def teardown
    File.delete(@tmp_hpxml_path) if File.exist? @tmp_hpxml_path
    FileUtils.rm_rf(@results_path) if Dir.exist? @results_path
  end

  def test_lighting
    hpxml_name = 'base.xml'

    _all_calc_types.each do |calc_type|
      hpxml = _test_ruleset(hpxml_name, calc_type)
      if [Constants.CalcTypeERIReferenceHome, Constants.CalcTypeCO2eReferenceHome].include? calc_type
        _check_lighting(hpxml, f_int_cfl: 0.1)
      elsif [Constants.CalcTypeERIRatedHome].include? calc_type
        _check_lighting(hpxml, f_int_cfl: 0.4, f_ext_cfl: 0.4, f_grg_cfl: 0.4, f_int_lfl: 0.1, f_ext_lfl: 0.1, f_grg_lfl: 0.1, f_int_led: 0.25, f_ext_led: 0.25, f_grg_led: 0.25)
      elsif [Constants.CalcTypeERIIndexAdjustmentDesign].include? calc_type
        _check_lighting(hpxml, f_int_cfl: 0.75, f_ext_cfl: 0.75)
      elsif [Constants.CalcTypeERIIndexAdjustmentReferenceHome].include? calc_type
        _check_lighting(hpxml, f_int_cfl: 0.1)
      end
    end
  end

  def test_lighting_pre_addendum_g
    hpxml_name = 'base-version-eri-2014AE.xml'

    _all_calc_types.each do |calc_type|
      hpxml = _test_ruleset(hpxml_name, calc_type)
      if [Constants.CalcTypeERIReferenceHome, Constants.CalcTypeCO2eReferenceHome].include? calc_type
        _check_lighting(hpxml, f_int_cfl: 0.1)
      elsif [Constants.CalcTypeERIRatedHome].include? calc_type
        _check_lighting(hpxml, f_int_cfl: 0.4, f_ext_cfl: 0.4, f_grg_cfl: 0.4, f_int_lfl: 0.1, f_ext_lfl: 0.1, f_grg_lfl: 0.1, f_int_led: 0.25, f_ext_led: 0.25, f_grg_led: 0.25)
      elsif [Constants.CalcTypeERIIndexAdjustmentDesign].include? calc_type
        _check_lighting(hpxml, f_int_cfl: 0.75, f_ext_cfl: 0.75)
      elsif [Constants.CalcTypeERIIndexAdjustmentReferenceHome].include? calc_type
        _check_lighting(hpxml, f_int_cfl: 0.1)
      end
    end
  end

  def test_ceiling_fans
    # Test w/ 301-2019
    hpxml_name = 'base-lighting-ceiling-fans.xml'
    hpxml = HPXML.new(hpxml_path: File.join(@root_path, 'workflow', 'sample_files', hpxml_name))
    hpxml_name = File.basename(@tmp_hpxml_path)
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)

    _all_calc_types.each do |calc_type|
      hpxml = _test_ruleset(hpxml_name, calc_type)
      if [Constants.CalcTypeERIRatedHome].include? calc_type
        _check_ceiling_fans(hpxml, cfm_per_w: 3000.0 / 30.0, quantity: 4)
      else
        _check_ceiling_fans(hpxml, cfm_per_w: 3000.0 / 42.6, quantity: 4)
      end
    end

    # Test w/ 301-2019 and Nfans < Nbr + 1
    hpxml_name = 'base-lighting-ceiling-fans.xml'
    hpxml = HPXML.new(hpxml_path: File.join(@root_path, 'workflow', 'sample_files', hpxml_name))
    hpxml.ceiling_fans[0].quantity = 3
    hpxml_name = File.basename(@tmp_hpxml_path)
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)

    _all_calc_types.each do |calc_type|
      hpxml = _test_ruleset(hpxml_name, calc_type)
      _check_ceiling_fans(hpxml)
    end

    # Test w/ 301-2014 and Nfans < Nbr + 1
    hpxml_name = _change_eri_version('base-lighting-ceiling-fans.xml', '2014')
    hpxml = HPXML.new(hpxml_path: File.join(@root_path, 'workflow', 'sample_files', hpxml_name))
    hpxml.ceiling_fans[0].quantity = 3
    hpxml_name = File.basename(@tmp_hpxml_path)
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)

    _all_calc_types.each do |calc_type|
      hpxml = _test_ruleset(hpxml_name, calc_type)
      if [Constants.CalcTypeERIRatedHome].include? calc_type
        _check_ceiling_fans(hpxml, cfm_per_w: 3000.0 / 30.0, quantity: 4)
      else
        _check_ceiling_fans(hpxml, cfm_per_w: 3000.0 / 42.6, quantity: 4)
      end
    end

    # Test w/ different Nbr
    hpxml_name = 'base-lighting-ceiling-fans.xml'
    hpxml = HPXML.new(hpxml_path: File.join(@root_path, 'workflow', 'sample_files', hpxml_name))
    hpxml.building_construction.number_of_bedrooms = 5
    hpxml.ceiling_fans[0].quantity = 6
    hpxml_name = File.basename(@tmp_hpxml_path)
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)

    _all_calc_types.each do |calc_type|
      hpxml = _test_ruleset(hpxml_name, calc_type)
      if [Constants.CalcTypeERIReferenceHome, Constants.CalcTypeCO2eReferenceHome].include? calc_type
        _check_ceiling_fans(hpxml, cfm_per_w: 3000.0 / 42.6, quantity: 6)
      elsif [Constants.CalcTypeERIRatedHome].include? calc_type
        _check_ceiling_fans(hpxml, cfm_per_w: 3000.0 / 30.0, quantity: 6)
      else
        _check_ceiling_fans(hpxml, cfm_per_w: 3000.0 / 42.6, quantity: 4)
      end
    end
  end

  def _test_ruleset(hpxml_name, calc_type)
    require_relative '../../workflow/design'
    designs = [Design.new(calc_type: calc_type,
                          output_dir: @output_dir)]

    hpxml_input_path = File.join(@root_path, 'workflow', 'sample_files', hpxml_name)
    success, errors, _, _, hpxml = run_rulesets(hpxml_input_path, designs)

    errors.each do |s|
      puts "Error: #{s}"
    end

    # assert that it ran correctly
    assert_equal(true, success)

    # validate against OS-HPXML schematron
    schematron_path = File.join(File.dirname(__FILE__), '..', '..', 'hpxml-measures', 'HPXMLtoOpenStudio', 'resources', 'hpxml_schematron', 'EPvalidator.xml')
    validator = OpenStudio::XMLValidator.new(schematron_path)
    assert_equal(true, validator.validate(designs[0].hpxml_output_path))
    @results_path = File.dirname(designs[0].hpxml_output_path)

    return hpxml
  end

  def _check_lighting(hpxml, f_int_cfl: 0, f_ext_cfl: 0, f_grg_cfl: 0, f_int_lfl: 0,
                      f_ext_lfl: 0, f_grg_lfl: 0, f_int_led: 0, f_ext_led: 0, f_grg_led: 0)
    assert_equal(9, hpxml.lighting_groups.size)
    hpxml.lighting_groups.each do |lg|
      assert([HPXML::LightingTypeCFL, HPXML::LightingTypeLFL, HPXML::LightingTypeLED].include? lg.lighting_type)
      assert([HPXML::LocationInterior, HPXML::LocationExterior, HPXML::LocationGarage].include? lg.location)

      if (lg.lighting_type == HPXML::LightingTypeCFL) && (lg.location == HPXML::LocationInterior)
        assert_in_epsilon(f_int_cfl, lg.fraction_of_units_in_location, 0.01)
      elsif (lg.lighting_type == HPXML::LightingTypeCFL) && (lg.location == HPXML::LocationExterior)
        assert_in_epsilon(f_ext_cfl, lg.fraction_of_units_in_location, 0.01)
      elsif (lg.lighting_type == HPXML::LightingTypeCFL) && (lg.location == HPXML::LocationGarage)
        assert_in_epsilon(f_grg_cfl, lg.fraction_of_units_in_location, 0.01)
      elsif (lg.lighting_type == HPXML::LightingTypeLFL) && (lg.location == HPXML::LocationInterior)
        assert_in_epsilon(f_int_lfl, lg.fraction_of_units_in_location, 0.01)
      elsif (lg.lighting_type == HPXML::LightingTypeLFL) && (lg.location == HPXML::LocationExterior)
        assert_in_epsilon(f_ext_lfl, lg.fraction_of_units_in_location, 0.01)
      elsif (lg.lighting_type == HPXML::LightingTypeLFL) && (lg.location == HPXML::LocationGarage)
        assert_in_epsilon(f_grg_lfl, lg.fraction_of_units_in_location, 0.01)
      elsif (lg.lighting_type == HPXML::LightingTypeLED) && (lg.location == HPXML::LocationInterior)
        assert_in_epsilon(f_int_led, lg.fraction_of_units_in_location, 0.01)
      elsif (lg.lighting_type == HPXML::LightingTypeLED) && (lg.location == HPXML::LocationExterior)
        assert_in_epsilon(f_ext_led, lg.fraction_of_units_in_location, 0.01)
      elsif (lg.lighting_type == HPXML::LightingTypeLED) && (lg.location == HPXML::LocationGarage)
        assert_in_epsilon(f_grg_led, lg.fraction_of_units_in_location, 0.01)
      end
    end
  end

  def _check_ceiling_fans(hpxml, cfm_per_w: nil, quantity: nil)
    if cfm_per_w.nil? && quantity.nil?
      assert_equal(0, hpxml.ceiling_fans.size)
      assert_nil(hpxml.hvac_controls[0].ceiling_fan_cooling_setpoint_temp_offset)
    else
      assert_equal(1, hpxml.ceiling_fans.size)
      ceiling_fan = hpxml.ceiling_fans[0]
      if cfm_per_w.nil?
        assert_nil(ceiling_fan.efficiency)
      else
        assert_equal(cfm_per_w, ceiling_fan.efficiency)
      end
      if quantity.nil?
        assert_nil(ceiling_fan.quantity)
      else
        assert_equal(quantity, ceiling_fan.quantity)
      end
      assert_equal(0.5, hpxml.hvac_controls[0].ceiling_fan_cooling_setpoint_temp_offset)
    end
  end
end
