# frozen_string_literal: true

require_relative '../../hpxml-measures/HPXMLtoOpenStudio/resources/minitest_helper'
require 'openstudio'
require_relative '../main.rb'
require 'fileutils'
require_relative 'util.rb'

class EnergyStarZeroEnergyReadyHomePVTest < Minitest::Test
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

  def test_pv
    [*ESConstants.AllVersions, *ZERHConstants.AllVersions].each do |program_version|
      _convert_to_es_zerh('base-pv.xml', program_version)
      _hpxml, hpxml_bldg = _test_ruleset(program_version)
      _check_pv(hpxml_bldg)
    end
  end

  def test_pv_batteries
    [*ESConstants.AllVersions, *ZERHConstants.AllVersions].each do |program_version|
      _convert_to_es_zerh('base-pv-battery.xml', program_version)
      _hpxml, hpxml_bldg = _test_ruleset(program_version)
      _check_battery(hpxml_bldg)
    end
  end

  def _test_ruleset(program_version)
    require_relative '../../workflow/design'
    if ESConstants.AllVersions.include? program_version
      designs = [Design.new(init_calc_type: ESConstants.CalcTypeEnergyStarReference,
                            output_dir: @sample_files_path)]
    elsif ZERHConstants.AllVersions.include? program_version
      designs = [Design.new(init_calc_type: ZERHConstants.CalcTypeZERHReference,
                            output_dir: @sample_files_path)]
    end

    success, errors, _, _, hpxml = run_rulesets(@tmp_hpxml_path, designs, @schema_validator, @erivalidator)

    errors.each do |s|
      puts "Error: #{s}"
    end

    # assert that it ran correctly
    assert_equal(true, success)

    # validate against 301 schematron
    assert_equal(true, @erivalidator.validate(designs[0].init_hpxml_output_path))
    @results_path = File.dirname(designs[0].init_hpxml_output_path)

    return hpxml, hpxml.buildings[0]
  end

  def _check_pv(hpxml_bldg)
    assert_equal(0, hpxml_bldg.pv_systems.size)
  end

  def _check_battery(hpxml_bldg)
    assert_equal(0, hpxml_bldg.batteries.size)
  end

  def _convert_to_es_zerh(hpxml_name, program_version, state_code = nil)
    return convert_to_es_zerh(hpxml_name, program_version, @root_path, @tmp_hpxml_path, state_code)
  end
end
