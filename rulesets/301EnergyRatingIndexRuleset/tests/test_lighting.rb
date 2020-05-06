# frozen_string_literal: true

require_relative '../../../workflow/tests/minitest_helper'
require 'openstudio'
require 'openstudio/ruleset/ShowRunnerOutput'
require 'minitest/autorun'
require_relative '../measure.rb'
require 'fileutils'

class LightingTest < MiniTest::Test
  def before_setup
    @root_path = File.absolute_path(File.join(File.dirname(__FILE__), '..', '..', '..'))
  end

  def test_lighting
    hpxml_name = 'base.xml'

    # Reference Home
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_lighting(hpxml, 0.1, 0, 0, 0, 0, 0, 0, 0, 0)

    # Rated Home
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_lighting(hpxml, 0.4, 0.4, 0.4, 0.1, 0.1, 0.1, 0.25, 0.25, 0.25)

    # IAD
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentDesign)
    _check_lighting(hpxml, 0.75, 0.75, 0, 0, 0, 0, 0, 0, 0)

    # IAD Reference
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentReferenceHome)
    _check_lighting(hpxml, 0.1, 0, 0, 0, 0, 0, 0, 0, 0)
  end

  def test_lighting_pre_addendum_g
    hpxml_name = 'base-version-2014ADE.xml'

    # Reference Home
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_lighting(hpxml, 0.1, 0, 0, 0, 0, 0, 0, 0, 0)

    # Rated Home
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_lighting(hpxml, 0.4, 0.4, 0.4, 0.1, 0.1, 0.1, 0.25, 0.25, 0.25)

    # IAD
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentDesign)
    _check_lighting(hpxml, 0.75, 0.75, 0, 0, 0, 0, 0, 0, 0)

    # IAD Reference
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentReferenceHome)
    _check_lighting(hpxml, 0.1, 0, 0, 0, 0, 0, 0, 0, 0)
  end

  def test_ceiling_fans
    hpxml_name = 'base-misc-ceiling-fans.xml'

    medium_cfm = 3000.0

    # Reference Home
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    avg_fan_w = 42.6
    _check_ceiling_fans(hpxml, medium_cfm / avg_fan_w, 4)

    # Rated Home
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    avg_fan_w = 30.0
    _check_ceiling_fans(hpxml, medium_cfm / avg_fan_w, 4)

    # IAD
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentDesign)
    avg_fan_w = 42.6
    _check_ceiling_fans(hpxml, medium_cfm / avg_fan_w, 4)

    # IAD Reference
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentReferenceHome)
    avg_fan_w = 42.6
    _check_ceiling_fans(hpxml, medium_cfm / avg_fan_w, 4)
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

  def _check_lighting(hpxml, f_int_cfl, f_ext_cfl, f_grg_cfl, f_int_lfl, f_ext_lfl, f_grg_lfl, f_int_led, f_ext_led, f_grg_led)
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

  def _check_ceiling_fans(hpxml, cfm_per_w, quantity)
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
  end
end
