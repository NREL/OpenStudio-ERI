# frozen_string_literal: true

require_relative '../../hpxml-measures/HPXMLtoOpenStudio/resources/minitest_helper'
require 'openstudio'
require_relative '../main.rb'
require 'fileutils'
require_relative 'util.rb'

class ERIOccupancyTest < Minitest::Test
  def setup
    @root_path = File.absolute_path(File.join(File.dirname(__FILE__), '..', '..'))
    @sample_files_path = File.join(@root_path, 'workflow', 'sample_files')
    @tmp_hpxml_path = File.join(@sample_files_path, 'tmp.xml')
    @schema_validator = XMLValidator.get_xml_validator(File.join(@root_path, 'hpxml-measures', 'HPXMLtoOpenStudio', 'resources', 'hpxml_schema', 'HPXML.xsd'))
    @epvalidator = XMLValidator.get_xml_validator(File.join(@root_path, 'hpxml-measures', 'HPXMLtoOpenStudio', 'resources', 'hpxml_schematron', 'EPvalidator.xml'))
    @erivalidator = XMLValidator.get_xml_validator(File.join(@root_path, 'rulesets', 'resources', '301validator.xml'))
  end

  def teardown
    File.delete(@tmp_hpxml_path) if File.exist? @tmp_hpxml_path
    FileUtils.rm_rf(@results_path) if Dir.exist? @results_path
  end

  def test_building
    hpxml_name = 'base.xml'

    _all_calc_types.each do |calc_type|
      _hpxml, hpxml_bldg = _test_ruleset(hpxml_name, calc_type)
      _check_occupancy(hpxml_bldg)
      _check_general_water_use(hpxml_bldg)
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

  def _check_occupancy(hpxml_bldg)
    building_occupancy = hpxml_bldg.building_occupancy
    assert_equal('0.035, 0.035, 0.035, 0.035, 0.035, 0.059, 0.082, 0.055, 0.027, 0.014, 0.014, 0.014, 0.014, 0.014, 0.019, 0.027, 0.041, 0.055, 0.068, 0.082, 0.082, 0.070, 0.053, 0.035', building_occupancy.weekday_fractions)
    assert_equal('0.035, 0.035, 0.035, 0.035, 0.035, 0.059, 0.082, 0.055, 0.027, 0.014, 0.014, 0.014, 0.014, 0.014, 0.019, 0.027, 0.041, 0.055, 0.068, 0.082, 0.082, 0.070, 0.053, 0.035', building_occupancy.weekend_fractions)
    assert_equal('1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0', building_occupancy.monthly_multipliers)
  end

  def _check_general_water_use(hpxml_bldg)
    building_occupancy = hpxml_bldg.building_occupancy
    assert_equal('0.023, 0.021, 0.021, 0.025, 0.027, 0.038, 0.044, 0.039, 0.037, 0.037, 0.034, 0.035, 0.035, 0.035, 0.039, 0.043, 0.051, 0.064, 0.065, 0.072, 0.073, 0.063, 0.045, 0.034', building_occupancy.general_water_use_weekday_fractions)
    assert_equal('0.023, 0.021, 0.021, 0.025, 0.027, 0.038, 0.044, 0.039, 0.037, 0.037, 0.034, 0.035, 0.035, 0.035, 0.039, 0.043, 0.051, 0.064, 0.065, 0.072, 0.073, 0.063, 0.045, 0.034', building_occupancy.general_water_use_weekend_fractions)
    assert_equal('1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0', building_occupancy.general_water_use_monthly_multipliers)
  end
end
