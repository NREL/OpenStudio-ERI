# frozen_string_literal: true

require_relative '../../../hpxml-measures/HPXMLtoOpenStudio/resources/minitest_helper'
require 'openstudio'
require 'openstudio/measure/ShowRunnerOutput'
require_relative '../measure.rb'
require 'fileutils'
require_relative 'util.rb'

class ERIGeneratorTest < MiniTest::Test
  def setup
    @root_path = File.absolute_path(File.join(File.dirname(__FILE__), '..', '..', '..'))
  end

  def test_generator
    hpxml_name = 'base-misc-generators.xml'

    _all_calc_types.each do |calc_type|
      hpxml = _test_measure(hpxml_name, calc_type)
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
      hpxml = _test_measure(hpxml_name, calc_type)
      if [Constants.CalcTypeERIRatedHome].include? calc_type
        _check_generator(hpxml, [{ fuel: HPXML::FuelTypePropane, annual_input: 85000, annual_output: 5000, is_shared: true, nbeds_served: 18 }])
      else
        _check_generator(hpxml)
      end
    end
  end

  def _test_measure(hpxml_name, calc_type)
    args_hash = {}
    args_hash['hpxml_input_path'] = File.join(@root_path, 'workflow', 'sample_files', hpxml_name)
    args_hash['calc_type'] = calc_type

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
