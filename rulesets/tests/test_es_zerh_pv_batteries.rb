# frozen_string_literal: true

require_relative '../../hpxml-measures/HPXMLtoOpenStudio/resources/minitest_helper'
require 'openstudio'
require_relative '../main.rb'
require 'fileutils'
require_relative 'util.rb'
require_relative '../../workflow/design'

class EnergyStarZeroEnergyReadyHomePVTest < Minitest::Test
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

  def test_pv
    [*ES::AllVersions, *ZERH::AllVersions].each do |program_version|
      _convert_to_es_zerh('base-pv.xml', program_version)
      hpxml_bldg = _test_ruleset(program_version)
      _check_pv(hpxml_bldg)
    end
  end

  def test_pv_batteries
    [*ES::AllVersions, *ZERH::AllVersions].each do |program_version|
      _convert_to_es_zerh('base-pv-battery.xml', program_version)
      hpxml_bldg = _test_ruleset(program_version)
      _check_battery(hpxml_bldg)
    end
  end

  def _test_ruleset(program_version)
    print '.'

    if ES::AllVersions.include? program_version
      run_type = RunType::ES
    elsif ZERH::AllVersions.include? program_version
      run_type = RunType::ZERH
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

  def _check_pv(hpxml_bldg)
    assert_equal(0, hpxml_bldg.pv_systems.size)
  end

  def _check_battery(hpxml_bldg)
    assert_equal(0, hpxml_bldg.batteries.size)
  end
end
