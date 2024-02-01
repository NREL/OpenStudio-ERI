# frozen_string_literal: true

require_relative '../../hpxml-measures/HPXMLtoOpenStudio/resources/minitest_helper'
require 'openstudio'
require_relative '../main.rb'
require 'fileutils'
require_relative 'util.rb'

class ERILightingTest < Minitest::Test
  def setup
    @root_path = File.absolute_path(File.join(File.dirname(__FILE__), '..', '..'))
    @sample_files_path = File.join(@root_path, 'workflow', 'sample_files')
    @tmp_hpxml_path = File.join(@sample_files_path, 'tmp.xml')
    @schema_validator = XMLValidator.get_schema_validator(File.join(@root_path, 'hpxml-measures', 'HPXMLtoOpenStudio', 'resources', 'hpxml_schema', 'HPXML.xsd'))
    @epvalidator = OpenStudio::XMLValidator.new(File.join(@root_path, 'hpxml-measures', 'HPXMLtoOpenStudio', 'resources', 'hpxml_schematron', 'EPvalidator.xml'))
    @erivalidator = OpenStudio::XMLValidator.new(File.join(@root_path, 'rulesets', 'resources', '301validator.xml'))
  end

  def teardown
    File.delete(@tmp_hpxml_path) if File.exist? @tmp_hpxml_path
    FileUtils.rm_rf(@results_path) if Dir.exist? @results_path
  end

  def test_lighting
    hpxml_name = 'base-enclosure-garage.xml'

    _all_calc_types.each do |calc_type|
      _hpxml, hpxml_bldg = _test_ruleset(hpxml_name, calc_type)
      if [Constants.CalcTypeERIReferenceHome, Constants.CalcTypeCO2eReferenceHome].include? calc_type
        _check_lighting(hpxml_bldg, f_int_cfl: 0.1, f_ext_cfl: 0.0, f_grg_cfl: 0.0, f_int_lfl: 0.0, f_ext_lfl: 0.0, f_grg_lfl: 0.0, f_int_led: 0.0, f_ext_led: 0.0, f_grg_led: 0.0)
      elsif [Constants.CalcTypeERIRatedHome].include? calc_type
        _check_lighting(hpxml_bldg, f_int_cfl: 0.4, f_ext_cfl: 0.4, f_grg_cfl: 0.4, f_int_lfl: 0.1, f_ext_lfl: 0.1, f_grg_lfl: 0.1, f_int_led: 0.25, f_ext_led: 0.25, f_grg_led: 0.25)
      elsif [Constants.CalcTypeERIIndexAdjustmentDesign].include? calc_type
        _check_lighting(hpxml_bldg, f_int_cfl: 0.75, f_ext_cfl: 0.75, f_grg_cfl: 0.0, f_int_lfl: 0.0, f_ext_lfl: 0.0, f_grg_lfl: 0.0, f_int_led: 0.0, f_ext_led: 0.0, f_grg_led: 0.0)
      elsif [Constants.CalcTypeERIIndexAdjustmentReferenceHome].include? calc_type
        _check_lighting(hpxml_bldg, f_int_cfl: 0.1, f_ext_cfl: 0.0, f_grg_cfl: 0.0, f_int_lfl: 0.0, f_ext_lfl: 0.0, f_grg_lfl: 0.0, f_int_led: 0.0, f_ext_led: 0.0, f_grg_led: 0.0)
      end
    end
  end

  def test_lighting_pre_addendum_g
    hpxml_name = 'base-version-eri-2014AE.xml'

    _all_calc_types.each do |calc_type|
      _hpxml, hpxml_bldg = _test_ruleset(hpxml_name, calc_type)
      if [Constants.CalcTypeERIReferenceHome, Constants.CalcTypeCO2eReferenceHome].include? calc_type
        _check_lighting(hpxml_bldg, f_int_cfl: 0.1, f_ext_cfl: 0.0, f_int_lfl: 0.0, f_ext_lfl: 0.0, f_int_led: 0.0, f_ext_led: 0.0)
      elsif [Constants.CalcTypeERIRatedHome].include? calc_type
        _check_lighting(hpxml_bldg, f_int_cfl: 0.4, f_ext_cfl: 0.4, f_int_lfl: 0.1, f_ext_lfl: 0.1, f_int_led: 0.25, f_ext_led: 0.25)
      elsif [Constants.CalcTypeERIIndexAdjustmentDesign].include? calc_type
        _check_lighting(hpxml_bldg, f_int_cfl: 0.75, f_ext_cfl: 0.75, f_int_lfl: 0.0, f_ext_lfl: 0.0, f_int_led: 0.0, f_ext_led: 0.0)
      elsif [Constants.CalcTypeERIIndexAdjustmentReferenceHome].include? calc_type
        _check_lighting(hpxml_bldg, f_int_cfl: 0.1, f_ext_cfl: 0.0, f_int_lfl: 0.0, f_ext_lfl: 0.0, f_int_led: 0.0, f_ext_led: 0.0)
      end
    end
  end

  def test_ceiling_fans
    # Test w/ 301-2019
    hpxml_name = 'base-lighting-ceiling-fans.xml'
    hpxml = HPXML.new(hpxml_path: File.join(@root_path, 'workflow', 'sample_files', hpxml_name))
    hpxml_name = File.basename(@tmp_hpxml_path)
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)

    _all_calc_types.each do |calc_type|
      _hpxml, hpxml_bldg = _test_ruleset(hpxml_name, calc_type)
      if [Constants.CalcTypeERIRatedHome].include? calc_type
        _check_ceiling_fans(hpxml_bldg, cfm_per_w: 3000.0 / 30.0, count: 4)
      else
        _check_ceiling_fans(hpxml_bldg, cfm_per_w: 3000.0 / 42.6, count: 4)
      end
    end

    # Test w/ 301-2019 and Nfans < Nbr + 1
    hpxml_name = 'base-lighting-ceiling-fans.xml'
    hpxml = HPXML.new(hpxml_path: File.join(@root_path, 'workflow', 'sample_files', hpxml_name))
    hpxml_bldg = hpxml.buildings[0]
    hpxml_bldg.ceiling_fans[0].count = 3
    hpxml_name = File.basename(@tmp_hpxml_path)
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)

    _all_calc_types.each do |calc_type|
      _hpxml, hpxml_bldg = _test_ruleset(hpxml_name, calc_type)
      _check_ceiling_fans(hpxml_bldg)
    end

    # Test w/ 301-2014 and Nfans < Nbr + 1
    hpxml_name = _change_eri_version('base-lighting-ceiling-fans.xml', '2014')
    hpxml = HPXML.new(hpxml_path: File.join(@root_path, 'workflow', 'sample_files', hpxml_name))
    hpxml_bldg = hpxml.buildings[0]
    hpxml_bldg.ceiling_fans[0].count = 3
    hpxml_name = File.basename(@tmp_hpxml_path)
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)

    _all_calc_types.each do |calc_type|
      _hpxml, hpxml_bldg = _test_ruleset(hpxml_name, calc_type)
      if [Constants.CalcTypeERIRatedHome].include? calc_type
        _check_ceiling_fans(hpxml_bldg, cfm_per_w: 3000.0 / 30.0, count: 4)
      else
        _check_ceiling_fans(hpxml_bldg, cfm_per_w: 3000.0 / 42.6, count: 4)
      end
    end

    # Test w/ different Nbr
    hpxml_name = 'base-lighting-ceiling-fans.xml'
    hpxml = HPXML.new(hpxml_path: File.join(@root_path, 'workflow', 'sample_files', hpxml_name))
    hpxml_bldg = hpxml.buildings[0]
    hpxml_bldg.building_construction.number_of_bedrooms = 5
    hpxml_bldg.ceiling_fans[0].count = 6
    hpxml_name = File.basename(@tmp_hpxml_path)
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)

    _all_calc_types.each do |calc_type|
      _hpxml, hpxml_bldg = _test_ruleset(hpxml_name, calc_type)
      if [Constants.CalcTypeERIReferenceHome, Constants.CalcTypeCO2eReferenceHome].include? calc_type
        _check_ceiling_fans(hpxml_bldg, cfm_per_w: 3000.0 / 42.6, count: 6)
      elsif [Constants.CalcTypeERIRatedHome].include? calc_type
        _check_ceiling_fans(hpxml_bldg, cfm_per_w: 3000.0 / 30.0, count: 6)
      else
        _check_ceiling_fans(hpxml_bldg, cfm_per_w: 3000.0 / 42.6, count: 4)
      end
    end
  end

  def _test_ruleset(hpxml_name, calc_type)
    require_relative '../../workflow/design'
    designs = [Design.new(calc_type: calc_type,
                          output_dir: @sample_files_path)]

    hpxml_input_path = File.join(@sample_files_path, hpxml_name)
    success, errors, _, _, hpxml = run_rulesets(hpxml_input_path, designs, @schema_validator, @erivalidator)

    errors.each do |s|
      puts "Error: #{s}"
    end

    # assert that it ran correctly
    assert_equal(true, success)

    # validate against OS-HPXML schematron
    assert_equal(true, @epvalidator.validate(designs[0].hpxml_output_path))
    @results_path = File.dirname(designs[0].hpxml_output_path)

    return hpxml, hpxml.buildings[0]
  end

  def _check_lighting(hpxml_bldg, f_int_cfl: nil, f_ext_cfl: nil, f_grg_cfl: nil, f_int_lfl: nil,
                      f_ext_lfl: nil, f_grg_lfl: nil, f_int_led: nil, f_ext_led: nil, f_grg_led: nil)
    n_grps = 0
    n_grps += 1 unless f_int_cfl.nil?
    n_grps += 1 unless f_ext_cfl.nil?
    n_grps += 1 unless f_grg_cfl.nil?
    n_grps += 1 unless f_int_lfl.nil?
    n_grps += 1 unless f_ext_lfl.nil?
    n_grps += 1 unless f_grg_lfl.nil?
    n_grps += 1 unless f_int_led.nil?
    n_grps += 1 unless f_ext_led.nil?
    n_grps += 1 unless f_grg_led.nil?
    assert_equal(n_grps, hpxml_bldg.lighting_groups.size)

    hpxml_bldg.lighting_groups.each do |lg|
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

    assert_equal('0.012, 0.010, 0.010, 0.010, 0.011, 0.018, 0.030, 0.038, 0.041, 0.041, 0.039, 0.037, 0.036, 0.035, 0.037, 0.041, 0.050, 0.065, 0.086, 0.106, 0.110, 0.079, 0.040, 0.018', hpxml_bldg.lighting.interior_weekday_fractions)
    assert_equal('0.012, 0.010, 0.010, 0.010, 0.011, 0.018, 0.030, 0.038, 0.041, 0.041, 0.039, 0.037, 0.036, 0.035, 0.037, 0.041, 0.050, 0.065, 0.086, 0.106, 0.110, 0.079, 0.040, 0.018', hpxml_bldg.lighting.interior_weekend_fractions)
    assert_equal('1.19, 1.11, 1.02, 0.93, 0.84, 0.80, 0.82, 0.88, 0.98, 1.07, 1.16, 1.20', hpxml_bldg.lighting.interior_monthly_multipliers)
    assert_equal('0.040, 0.037, 0.037, 0.035, 0.035, 0.039, 0.044, 0.041, 0.031, 0.025, 0.024, 0.024, 0.025, 0.028, 0.030, 0.035, 0.044, 0.056, 0.064, 0.068, 0.070, 0.065, 0.056, 0.047', hpxml_bldg.lighting.exterior_weekday_fractions)
    assert_equal('0.040, 0.037, 0.037, 0.035, 0.035, 0.039, 0.044, 0.041, 0.031, 0.025, 0.024, 0.024, 0.025, 0.028, 0.030, 0.035, 0.044, 0.056, 0.064, 0.068, 0.070, 0.065, 0.056, 0.047', hpxml_bldg.lighting.exterior_weekend_fractions)
    assert_equal('1.19, 1.11, 1.02, 0.93, 0.84, 0.80, 0.82, 0.88, 0.98, 1.07, 1.16, 1.20', hpxml_bldg.lighting.exterior_monthly_multipliers)
    if hpxml_bldg.has_location(HPXML::LocationGarage)
      assert_equal('0.023, 0.019, 0.015, 0.017, 0.021, 0.031, 0.042, 0.041, 0.034, 0.029, 0.027, 0.025, 0.021, 0.021, 0.021, 0.026, 0.031, 0.044, 0.084, 0.117, 0.113, 0.096, 0.063, 0.039', hpxml_bldg.lighting.garage_weekday_fractions)
      assert_equal('0.023, 0.019, 0.015, 0.017, 0.021, 0.031, 0.042, 0.041, 0.034, 0.029, 0.027, 0.025, 0.021, 0.021, 0.021, 0.026, 0.031, 0.044, 0.084, 0.117, 0.113, 0.096, 0.063, 0.039', hpxml_bldg.lighting.garage_weekend_fractions)
      assert_equal('1.19, 1.11, 1.02, 0.93, 0.84, 0.80, 0.82, 0.88, 0.98, 1.07, 1.16, 1.20', hpxml_bldg.lighting.garage_monthly_multipliers)
    end
  end

  def _check_ceiling_fans(hpxml_bldg, cfm_per_w: nil, count: nil)
    if cfm_per_w.nil? && count.nil?
      assert_equal(0, hpxml_bldg.ceiling_fans.size)
      assert_nil(hpxml_bldg.hvac_controls[0].ceiling_fan_cooling_setpoint_temp_offset)
    else
      assert_equal(1, hpxml_bldg.ceiling_fans.size)
      ceiling_fan = hpxml_bldg.ceiling_fans[0]
      if cfm_per_w.nil?
        assert_nil(ceiling_fan.efficiency)
      else
        assert_equal(cfm_per_w, ceiling_fan.efficiency)
      end
      if count.nil?
        assert_nil(ceiling_fan.count)
      else
        assert_equal(count, ceiling_fan.count)
      end
      assert_equal(0.5, hpxml_bldg.hvac_controls[0].ceiling_fan_cooling_setpoint_temp_offset)
    end

    hpxml_bldg.ceiling_fans.each do |ceiling_fan|
      assert_equal('0.057, 0.057, 0.057, 0.057, 0.057, 0.057, 0.057, 0.024, 0.024, 0.024, 0.024, 0.024, 0.024, 0.024, 0.024, 0.024, 0.024, 0.024, 0.052, 0.057, 0.057, 0.057, 0.057, 0.057', ceiling_fan.weekday_fractions)
      assert_equal('0.057, 0.057, 0.057, 0.057, 0.057, 0.057, 0.057, 0.024, 0.024, 0.024, 0.024, 0.024, 0.024, 0.024, 0.024, 0.024, 0.024, 0.024, 0.052, 0.057, 0.057, 0.057, 0.057, 0.057', ceiling_fan.weekend_fractions)
      assert_equal('0, 0, 0, 0, 0, 1, 1, 1, 1, 0, 0, 0', ceiling_fan.monthly_multipliers)
    end
  end
end
