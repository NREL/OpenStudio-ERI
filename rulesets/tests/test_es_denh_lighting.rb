# frozen_string_literal: true

require 'openstudio'
require_relative '../../hpxml-measures/HPXMLtoOpenStudio/resources/minitest_helper'
require_relative '../main.rb'
require 'fileutils'
require_relative 'util.rb'
require_relative '../../workflow/design'

class EnergyStarDOEEfficientNewHomeLightingTest < Minitest::Test
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

  def test_lighting
    [*ES::AllVersions, *DENH::AllVersions].each do |program_version|
      _convert_to_es_denh('base.xml', program_version)
      hpxml_bldg = _test_ruleset(program_version)
      if [ES::SFNationalVer3_0, ES::SFPacificVer3_0, ES::SFFloridaVer3_1, DENH::Ver1].include? program_version
        _check_lighting(hpxml_bldg, 0.8, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0)
      elsif [ES::SFNationalVer3_2, ES::SFNationalVer3_3,
             ES::MFNationalVer1_2, ES::MFNationalVer1_3,
             DENH::SFVer2, DENH::MFVer2].include? program_version
        _check_lighting(hpxml_bldg, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0)
      elsif [ES::SFOregonWashingtonVer3_2, ES::SFNationalVer3_1,
             ES::MFOregonWashingtonVer1_2, ES::MFNationalVer1_0, ES::MFNationalVer1_1].include? program_version
        _check_lighting(hpxml_bldg, 0.9, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0)
      else
        fail "Unhandled program version: #{program_version}"
      end
    end
  end

  def test_ceiling_fans_none
    [*ES::AllVersions, *DENH::AllVersions].each do |program_version|
      _convert_to_es_denh('base.xml', program_version)
      hpxml_bldg = _test_ruleset(program_version)
      _check_ceiling_fans(hpxml_bldg)
    end
  end

  def test_ceiling_fans
    [*ES::AllVersions, *DENH::AllVersions].each do |program_version|
      _convert_to_es_denh('base-lighting-ceiling-fans.xml', program_version)
      hpxml_bldg = _test_ruleset(program_version)
      _check_ceiling_fans(hpxml_bldg, cfm_per_w: 122.0, count: 4)
    end
  end

  def test_ceiling_fans_nbeds_5
    [*ES::AllVersions, *DENH::AllVersions].each do |program_version|
      _convert_to_es_denh('base-lighting-ceiling-fans.xml', program_version)
      hpxml = HPXML.new(hpxml_path: @tmp_hpxml_path)
      hpxml_bldg = hpxml.buildings[0]
      hpxml_bldg.building_construction.number_of_bedrooms = 5
      XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
      hpxml_bldg = _test_ruleset(program_version)
      _check_ceiling_fans(hpxml_bldg, cfm_per_w: 122.0, count: 6)
    end
  end

  def _test_ruleset(program_version)
    print '.'

    if ES::AllVersions.include? program_version
      run_type = RunType::ES
    elsif DENH::AllVersions.include? program_version
      run_type = RunType::DENH
    end
    designs = [Design.new(run_type: run_type,
                          init_calc_type: InitCalcType::TargetHome,
                          output_dir: @sample_files_path,
                          version: program_version)]

    success, errors, _, _, hpxml_bldgs = run_rulesets(@tmp_hpxml_path, designs, @schema_validator, @erivalidator)

    errors.each do |s|
      puts "Error: #{s}"
    end

    # assert that it ran correctly
    assert(success)

    # validate against 301 schematron
    designs.each do |design|
      valid = @erivalidator.validate(design.init_hpxml_output_path)
      puts @erivalidator.errors.map { |e| e.logMessage } unless valid
      assert(valid)
      @results_paths << File.absolute_path(File.join(File.dirname(design.init_hpxml_output_path), '..'))
    end

    return hpxml_bldgs.values[0]
  end

  def _check_lighting(hpxml_bldg, f_int_cfl, f_ext_cfl, f_grg_cfl, f_int_lfl, f_ext_lfl, f_grg_lfl, f_int_led, f_ext_led, f_grg_led)
    assert_equal(9, hpxml_bldg.lighting_groups.size)
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
  end

  def _check_ceiling_fans(hpxml_bldg, cfm_per_w: nil, count: nil)
    if cfm_per_w.nil?
      assert_equal(0, hpxml_bldg.ceiling_fans.size)
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
    end
  end
end
