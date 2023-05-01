# frozen_string_literal: true

require_relative '../../hpxml-measures/HPXMLtoOpenStudio/resources/minitest_helper'
require 'openstudio'
require_relative '../main.rb'
require 'fileutils'
require_relative 'util.rb'

class ERIMiscTest < MiniTest::Test
  def setup
    @root_path = File.absolute_path(File.join(File.dirname(__FILE__), '..', '..'))
    @output_dir = File.join(@root_path, 'workflow', 'sample_files')
    schema_path = File.join(@root_path, 'hpxml-measures', 'HPXMLtoOpenStudio', 'resources', 'hpxml_schema', 'HPXML.xsd')
    @schema_validator = XMLValidator.get_schema_validator(schema_path)
    epvalidator_path = File.join(@root_path, 'hpxml-measures', 'HPXMLtoOpenStudio', 'resources', 'hpxml_schematron', 'EPvalidator.xml')
    @epvalidator = OpenStudio::XMLValidator.new(epvalidator_path)
    erivalidator_path = File.join(@root_path, 'rulesets', 'resources', '301validator.xml')
    @erivalidator = OpenStudio::XMLValidator.new(erivalidator_path)
  end

  def teardown
    FileUtils.rm_rf(@results_path) if Dir.exist? @results_path
  end

  def test_misc
    hpxml_name = 'base.xml'

    _all_calc_types.each do |calc_type|
      hpxml = _test_ruleset(hpxml_name, calc_type)
      if [Constants.CalcTypeERIIndexAdjustmentDesign, Constants.CalcTypeERIIndexAdjustmentReferenceHome].include? calc_type
        _check_misc(hpxml, misc_kwh: 2184, misc_sens: 0.855, misc_lat: 0.045, tv_kwh: 620, tv_sens: 1, tv_lat: 0)
      else
        _check_misc(hpxml, misc_kwh: 2457, misc_sens: 0.855, misc_lat: 0.045, tv_kwh: 620, tv_sens: 1, tv_lat: 0)
      end
    end
  end

  def _test_ruleset(hpxml_name, calc_type)
    require_relative '../../workflow/design'
    designs = [Design.new(calc_type: calc_type,
                          output_dir: @output_dir)]

    hpxml_input_path = File.join(@root_path, 'workflow', 'sample_files', hpxml_name)
    success, errors, _, _, hpxml = run_rulesets(hpxml_input_path, designs, @schema_validator, @erivalidator)

    errors.each do |s|
      puts "Error: #{s}"
    end

    # assert that it ran correctly
    assert_equal(true, success)

    # validate against OS-HPXML schematron
    assert_equal(true, @epvalidator.validate(designs[0].hpxml_output_path))
    @results_path = File.dirname(designs[0].hpxml_output_path)

    return hpxml
  end

  def _expected_misc_ref_energy_gains(cfa)
    kwh_per_yr = 0.91 * cfa
    sens_btu_per_yr = (7.27 * cfa) * 365.0
    lat_btu_per_yr = (0.38 * cfa) * 365.0
    return [kwh_per_yr, sens_btu_per_yr, lat_btu_per_yr]
  end

  def _expected_tv_ref_energy_gains(nbeds)
    kwh_per_yr = 413 + 69 * nbeds
    sens_btu_per_yr = (3861 + 645 * nbeds) * 365.0
    lat_btu_per_yr = 0.0
    return [kwh_per_yr, sens_btu_per_yr, lat_btu_per_yr]
  end

  def _check_misc(hpxml, misc_kwh:, misc_sens:, misc_lat:, tv_kwh:, tv_sens:, tv_lat:)
    num_pls = 0
    hpxml.plug_loads.each do |plug_load|
      if plug_load.plug_load_type == HPXML::PlugLoadTypeOther
        num_pls += 1
        assert_in_epsilon(misc_kwh, plug_load.kwh_per_year, 0.01)
        assert_in_epsilon(misc_sens, plug_load.frac_sensible, 0.01)
        assert_in_epsilon(misc_lat, plug_load.frac_latent, 0.01)
      elsif plug_load.plug_load_type == HPXML::PlugLoadTypeTelevision
        num_pls += 1
        assert_in_epsilon(tv_kwh, plug_load.kwh_per_year, 0.01)
        assert_in_epsilon(tv_sens, plug_load.frac_sensible, 0.01)
        assert_in_epsilon(tv_lat, plug_load.frac_latent, 0.01)
      end
    end
    assert_equal(2, num_pls)
  end
end
