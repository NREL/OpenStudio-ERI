# frozen_string_literal: true

require_relative '../../hpxml-measures/HPXMLtoOpenStudio/resources/minitest_helper'
require 'openstudio'
require_relative '../main.rb'
require 'fileutils'
require_relative 'util.rb'
require_relative '../../workflow/design'

class ERIMiscTest < Minitest::Test
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

  def test_misc
    hpxml_name = 'base.xml'

    _test_ruleset(hpxml_name).each do |(_run_type, calc_type), hpxml_bldg|
      if [CalcType::IndexAdjHome, CalcType::IndexAdjReferenceHome].include? calc_type
        _check_misc(hpxml_bldg, misc_kwh: 2184, misc_sens: 0.855, misc_lat: 0.045, tv_kwh: 620, tv_sens: 1, tv_lat: 0)
      else
        _check_misc(hpxml_bldg, misc_kwh: 2457, misc_sens: 0.855, misc_lat: 0.045, tv_kwh: 620, tv_sens: 1, tv_lat: 0)
      end
    end
  end

  def _test_ruleset(hpxml_name, version = 'latest')
    print '.'

    designs = []
    _all_run_calc_types.each do |run_type, calc_type|
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

  def _check_misc(hpxml_bldg, misc_kwh:, misc_sens:, misc_lat:, tv_kwh:, tv_sens:, tv_lat:)
    num_pls = 0
    hpxml_bldg.plug_loads.each do |plug_load|
      if plug_load.plug_load_type == HPXML::PlugLoadTypeOther
        num_pls += 1
        assert_in_epsilon(misc_kwh, plug_load.kwh_per_year, 0.01)
        assert_in_epsilon(misc_sens, plug_load.frac_sensible, 0.01)
        assert_in_epsilon(misc_lat, plug_load.frac_latent, 0.01)
        assert_equal('0.036, 0.036, 0.036, 0.036, 0.036, 0.036, 0.038, 0.041, 0.042, 0.042, 0.042, 0.042, 0.042, 0.042, 0.042, 0.044, 0.047, 0.050, 0.051, 0.050, 0.048, 0.044, 0.040, 0.037', plug_load.weekday_fractions)
        assert_equal('0.036, 0.036, 0.036, 0.036, 0.036, 0.036, 0.038, 0.041, 0.042, 0.042, 0.042, 0.042, 0.042, 0.042, 0.042, 0.044, 0.047, 0.050, 0.051, 0.050, 0.048, 0.044, 0.040, 0.037', plug_load.weekend_fractions)
      elsif plug_load.plug_load_type == HPXML::PlugLoadTypeTelevision
        num_pls += 1
        assert_in_epsilon(tv_kwh, plug_load.kwh_per_year, 0.01)
        assert_in_epsilon(tv_sens, plug_load.frac_sensible, 0.01)
        assert_in_epsilon(tv_lat, plug_load.frac_latent, 0.01)
        assert_equal('0.014, 0.007, 0.004, 0.003, 0.004, 0.006, 0.010, 0.015, 0.020, 0.025, 0.028, 0.031, 0.033, 0.038, 0.042, 0.046, 0.054, 0.062, 0.080, 0.110, 0.132, 0.125, 0.077, 0.034', plug_load.weekday_fractions)
        assert_equal('0.014, 0.007, 0.004, 0.003, 0.004, 0.006, 0.010, 0.015, 0.020, 0.025, 0.028, 0.031, 0.033, 0.038, 0.042, 0.046, 0.054, 0.062, 0.080, 0.110, 0.132, 0.125, 0.077, 0.034', plug_load.weekend_fractions)
      end
      assert_equal('1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0', plug_load.monthly_multipliers)
    end
    assert_equal(2, num_pls)
  end
end
