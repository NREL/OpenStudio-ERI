# frozen_string_literal: true

require 'openstudio'
require_relative '../../hpxml-measures/HPXMLtoOpenStudio/resources/minitest_helper'
require_relative '../main.rb'
require 'fileutils'
require_relative 'util.rb'
require_relative '../../workflow/design'

class ERIGeneratorTest < Minitest::Test
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

  def test_generator
    hpxml_name = 'base-misc-generators.xml'

    _test_ruleset(hpxml_name).each do |(_run_type, calc_type), hpxml_bldg|
      if [CalcType::RatedHome].include? calc_type
        _check_generator(hpxml_bldg, [{ fuel: HPXML::FuelTypeNaturalGas, annual_input: 8500, annual_output: 1200, is_shared: false },
                                      { fuel: HPXML::FuelTypeOil, annual_input: 8500, annual_output: 1200, is_shared: false }])
      else
        _check_generator(hpxml_bldg)
      end
    end
  end

  def test_generator_shared
    hpxml_name = 'base-bldgtype-mf-unit-shared-generator.xml'

    _test_ruleset(hpxml_name).each do |(_run_type, calc_type), hpxml_bldg|
      if [CalcType::RatedHome].include? calc_type
        _check_generator(hpxml_bldg, [{ fuel: HPXML::FuelTypePropane, annual_input: 85000, annual_output: 12000, is_shared: true, nbeds_served: 18 }])
      else
        _check_generator(hpxml_bldg)
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

  def _check_generator(hpxml_bldg, all_expected_values = [])
    assert_equal(all_expected_values.size, hpxml_bldg.generators.size)
    hpxml_bldg.generators.each_with_index do |generator, idx|
      expected_values = all_expected_values[idx]
      assert_equal(expected_values[:is_shared], generator.is_shared_system)
      assert_equal(expected_values[:fuel], generator.fuel_type)
      assert_equal(expected_values[:annual_input], generator.annual_consumption_kbtu)
      assert_equal(expected_values[:annual_output], generator.annual_output_kwh)
      if expected_values[:nbeds_served].nil?
        assert_nil(generator.number_of_bedrooms_served)
      else
        assert_equal(expected_values[:nbeds_served], generator.number_of_bedrooms_served)
      end
    end
  end
end
