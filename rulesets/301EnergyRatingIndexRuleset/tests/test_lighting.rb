# frozen_string_literal: true

require_relative '../../../hpxml-measures/HPXMLtoOpenStudio/resources/minitest_helper'
require 'openstudio'
require 'openstudio/measure/ShowRunnerOutput'
require_relative '../measure.rb'
require 'fileutils'
require_relative 'util.rb'

class ERILightingTest < MiniTest::Test
  def setup
    @root_path = File.absolute_path(File.join(File.dirname(__FILE__), '..', '..', '..'))
    @tmp_hpxml_path = File.join(@root_path, 'workflow', 'sample_files', 'tmp.xml')
  end

  def teardown
    File.delete(@tmp_hpxml_path) if File.exist? @tmp_hpxml_path
  end

  def test_lighting
    hpxml_name = 'base.xml'

    _all_calc_types.each do |calc_type|
      _get_co2_calcs(calc_type).each do |is_co2_calc|
        hpxml = _test_measure(hpxml_name, calc_type, is_co2_calc)
        if calc_type == Constants.CalcTypeERIReferenceHome
          values = { f_int_cfl: 0.1 }
        elsif calc_type == Constants.CalcTypeERIRatedHome
          values = { f_int_cfl: 0.4, f_ext_cfl: 0.4, f_grg_cfl: 0.4, f_int_lfl: 0.1, f_ext_lfl: 0.1, f_grg_lfl: 0.1, f_int_led: 0.25, f_ext_led: 0.25, f_grg_led: 0.25 }
        elsif calc_type == Constants.CalcTypeERIIndexAdjustmentDesign
          values = { f_int_cfl: 0.75, f_ext_cfl: 0.75 }
        elsif calc_type == Constants.CalcTypeERIIndexAdjustmentReferenceHome
          values = { f_int_cfl: 0.1 }
        end
        _check_lighting(hpxml, **values)
      end
    end
  end

  def test_lighting_pre_addendum_g
    hpxml_name = 'base-version-2014AE.xml'

    _all_calc_types.each do |calc_type|
      _get_co2_calcs(calc_type).each do |is_co2_calc|
        hpxml = _test_measure(hpxml_name, calc_type, is_co2_calc)
        if calc_type == Constants.CalcTypeERIReferenceHome
          values = { f_int_cfl: 0.1 }
        elsif calc_type == Constants.CalcTypeERIRatedHome
          values = { f_int_cfl: 0.4, f_ext_cfl: 0.4, f_grg_cfl: 0.4, f_int_lfl: 0.1, f_ext_lfl: 0.1, f_grg_lfl: 0.1, f_int_led: 0.25, f_ext_led: 0.25, f_grg_led: 0.25 }
        elsif calc_type == Constants.CalcTypeERIIndexAdjustmentDesign
          values = { f_int_cfl: 0.75, f_ext_cfl: 0.75 }
        elsif calc_type == Constants.CalcTypeERIIndexAdjustmentReferenceHome
          values = { f_int_cfl: 0.1 }
        end
        _check_lighting(hpxml, **values)
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
      _get_co2_calcs(calc_type).each do |is_co2_calc|
        hpxml = _test_measure(hpxml_name, calc_type, is_co2_calc)
        if calc_type == Constants.CalcTypeERIReferenceHome
          values = { cfm_per_w: 3000.0 / 42.6, quantity: 4 }
        elsif calc_type == Constants.CalcTypeERIRatedHome
          values = { cfm_per_w: 3000.0 / 30.0, quantity: 4 }
        elsif calc_type == Constants.CalcTypeERIIndexAdjustmentDesign
          values = { cfm_per_w: 3000.0 / 42.6, quantity: 4 }
        elsif calc_type == Constants.CalcTypeERIIndexAdjustmentReferenceHome
          values = { cfm_per_w: 3000.0 / 42.6, quantity: 4 }
        end
        _check_ceiling_fans(hpxml, **values)
      end
    end

    # Test w/ 301-2019 and Nfans < Nbr + 1
    hpxml_name = 'base-lighting-ceiling-fans.xml'
    hpxml = HPXML.new(hpxml_path: File.join(@root_path, 'workflow', 'sample_files', hpxml_name))
    hpxml.ceiling_fans[0].quantity = 3
    hpxml_name = File.basename(@tmp_hpxml_path)
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)

    _all_calc_types.each do |calc_type|
      _get_co2_calcs(calc_type).each do |is_co2_calc|
        hpxml = _test_measure(hpxml_name, calc_type, is_co2_calc)
        _check_ceiling_fans(hpxml)
      end
    end

    # Test w/ 301-2014 and Nfans < Nbr + 1
    hpxml_name = _change_eri_version('base-lighting-ceiling-fans.xml', '2014')
    hpxml = HPXML.new(hpxml_path: File.join(@root_path, 'workflow', 'sample_files', hpxml_name))
    hpxml.ceiling_fans[0].quantity = 3
    hpxml_name = File.basename(@tmp_hpxml_path)
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)

    _all_calc_types.each do |calc_type|
      _get_co2_calcs(calc_type).each do |is_co2_calc|
        hpxml = _test_measure(hpxml_name, calc_type, is_co2_calc)
        if calc_type == Constants.CalcTypeERIReferenceHome
          values = { cfm_per_w: 3000.0 / 42.6, quantity: 4 }
        elsif calc_type == Constants.CalcTypeERIRatedHome
          values = { cfm_per_w: 3000.0 / 30.0, quantity: 4 }
        elsif calc_type == Constants.CalcTypeERIIndexAdjustmentDesign
          values = { cfm_per_w: 3000.0 / 42.6, quantity: 4 }
        elsif calc_type == Constants.CalcTypeERIIndexAdjustmentReferenceHome
          values = { cfm_per_w: 3000.0 / 42.6, quantity: 4 }
        end
        _check_ceiling_fans(hpxml, **values)
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
      _get_co2_calcs(calc_type).each do |is_co2_calc|
        hpxml = _test_measure(hpxml_name, calc_type, is_co2_calc)
        if calc_type == Constants.CalcTypeERIReferenceHome
          values = { cfm_per_w: 3000.0 / 42.6, quantity: 6 }
        elsif calc_type == Constants.CalcTypeERIRatedHome
          values = { cfm_per_w: 3000.0 / 30.0, quantity: 6 }
        elsif calc_type == Constants.CalcTypeERIIndexAdjustmentDesign
          values = { cfm_per_w: 3000.0 / 42.6, quantity: 4 }
        elsif calc_type == Constants.CalcTypeERIIndexAdjustmentReferenceHome
          values = { cfm_per_w: 3000.0 / 42.6, quantity: 4 }
        end
        _check_ceiling_fans(hpxml, **values)
      end
    end
  end

  def _test_measure(hpxml_name, calc_type, is_co2_calc)
    args_hash = {}
    args_hash['hpxml_input_path'] = File.join(@root_path, 'workflow', 'sample_files', hpxml_name)
    args_hash['calc_type'] = calc_type
    args_hash['is_co2_calc'] = is_co2_calc

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
