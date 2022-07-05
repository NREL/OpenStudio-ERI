# frozen_string_literal: true

require_relative '../../../hpxml-measures/HPXMLtoOpenStudio/resources/minitest_helper'
require 'openstudio'
require 'openstudio/ruleset/ShowRunnerOutput'
require_relative '../measure.rb'
require 'fileutils'
require_relative 'util'

class EnergyStarLightingTest < MiniTest::Test
  def setup
    @root_path = File.absolute_path(File.join(File.dirname(__FILE__), '..', '..', '..'))
    @tmp_hpxml_path = File.join(@root_path, 'workflow', 'sample_files', 'tmp.xml')
  end

  def teardown
    File.delete(@tmp_hpxml_path) if File.exist? @tmp_hpxml_path
  end

  def test_lighting
    ESConstants.AllVersions.each do |es_version|
      _convert_to_es('base.xml', es_version)
      hpxml = _test_measure()
      if [ESConstants.SFNationalVer3_0, ESConstants.SFPacificVer3_0, ESConstants.SFFloridaVer3_1].include? es_version
        _check_lighting(hpxml, 0.8, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0)
      elsif es_version == ESConstants.SFNationalVer3_2
        _check_lighting(hpxml, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0)
      elsif es_version == ESConstants.MFNationalVer1_2
        _check_lighting(hpxml, 1.0, 1.0, 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0)
      else
        _check_lighting(hpxml, 0.9, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0)
      end
    end
  end

  def test_ceiling_fans_none
    ESConstants.AllVersions.each do |es_version|
      _convert_to_es('base.xml', es_version)
      hpxml = _test_measure()
      _check_ceiling_fans(hpxml)
    end
  end

  def test_ceiling_fans
    ESConstants.AllVersions.each do |es_version|
      _convert_to_es('base-lighting-ceiling-fans.xml', es_version)
      hpxml = _test_measure()
      _check_ceiling_fans(hpxml, cfm_per_w: 122.0, quantity: 4)
    end
  end

  def test_ceiling_fans_nbeds_5
    ESConstants.AllVersions.each do |es_version|
      _convert_to_es('base-lighting-ceiling-fans.xml', es_version)
      hpxml = HPXML.new(hpxml_path: @tmp_hpxml_path)
      hpxml.building_construction.number_of_bedrooms = 5
      XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
      hpxml = _test_measure()
      _check_ceiling_fans(hpxml, cfm_per_w: 122.0, quantity: 6)
    end
  end

  def _test_measure()
    args_hash = {}
    args_hash['hpxml_input_path'] = @tmp_hpxml_path
    args_hash['init_calc_type'] = ESConstants.CalcTypeEnergyStarReference

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

  def _check_ceiling_fans(hpxml, cfm_per_w: nil, quantity: nil)
    if cfm_per_w.nil?
      assert_equal(0, hpxml.ceiling_fans.size)
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
    end
  end

  def _convert_to_es(hpxml_name, program_version, state_code = nil)
    return convert_to_es(hpxml_name, program_version, @root_path, @tmp_hpxml_path, state_code)
  end
end
