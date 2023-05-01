# frozen_string_literal: true

require_relative '../../hpxml-measures/HPXMLtoOpenStudio/resources/minitest_helper'
require 'openstudio'
require_relative '../main.rb'
require 'fileutils'
require_relative 'util.rb'

class ERIGeneratorTest < MiniTest::Test
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

  def test_generator
    hpxml_name = 'base-misc-generators.xml'

    _all_calc_types.each do |calc_type|
      hpxml = _test_ruleset(hpxml_name, calc_type)
      if [Constants.CalcTypeERIRatedHome].include? calc_type
        _check_generator(hpxml, [{ fuel: HPXML::FuelTypeNaturalGas, annual_input: 8500, annual_output: 500, is_shared: false },
                                 { fuel: HPXML::FuelTypeOil, annual_input: 8500, annual_output: 500, is_shared: false }])
      else
        _check_generator(hpxml)
      end
    end
  end

  def test_generator_shared
    hpxml_name = 'base-bldgtype-multifamily-shared-generator.xml'

    _all_calc_types.each do |calc_type|
      hpxml = _test_ruleset(hpxml_name, calc_type)
      if [Constants.CalcTypeERIRatedHome].include? calc_type
        _check_generator(hpxml, [{ fuel: HPXML::FuelTypePropane, annual_input: 85000, annual_output: 5000, is_shared: true, nbeds_served: 18 }])
      else
        _check_generator(hpxml)
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

  def _check_generator(hpxml, all_expected_values = [])
    assert_equal(all_expected_values.size, hpxml.generators.size)
    hpxml.generators.each_with_index do |generator, idx|
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
