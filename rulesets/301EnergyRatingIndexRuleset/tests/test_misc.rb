# frozen_string_literal: true

require_relative '../../../workflow/tests/minitest_helper'
require 'openstudio'
require 'openstudio/ruleset/ShowRunnerOutput'
require 'minitest/autorun'
require_relative '../measure.rb'
require 'fileutils'

class MiscTest < MiniTest::Test
  def before_setup
    @root_path = File.absolute_path(File.join(File.dirname(__FILE__), '..', '..', '..'))
  end

  def test_misc
    hpxml_name = 'base.xml'

    # Reference Home, Rated Home
    calc_types = [Constants.CalcTypeERIReferenceHome,
                  Constants.CalcTypeERIRatedHome]
    calc_types.each do |calc_type|
      hpxml = _test_measure(hpxml_name, calc_type)
      _check_misc(hpxml, 2457, 0.855, 0.045, 620, 1, 0)
    end

    # IAD, IAD Reference
    calc_types = [Constants.CalcTypeERIIndexAdjustmentDesign,
                  Constants.CalcTypeERIIndexAdjustmentReferenceHome]
    calc_types.each do |calc_type|
      hpxml = _test_measure(hpxml_name, calc_type)
      _check_misc(hpxml, 2184, 0.855, 0.045, 620, 1, 0)
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

  def _check_misc(hpxml, misc_kwh, misc_sens, misc_lat, tv_kwh, tv_sens, tv_lat)
    assert_equal(2, hpxml.plug_loads.size)
    hpxml.plug_loads.each do |plug_load|
      if plug_load.plug_load_type == HPXML::PlugLoadTypeOther
        assert_in_epsilon(misc_kwh, plug_load.kWh_per_year, 0.01)
        assert_in_epsilon(misc_sens, plug_load.frac_sensible, 0.01)
        assert_in_epsilon(misc_lat, plug_load.frac_latent, 0.01)
      elsif plug_load.plug_load_type == HPXML::PlugLoadTypeOther
        assert_in_epsilon(tv_kwh, plug_load.kWh_per_year, 0.01)
        assert_in_epsilon(tv_sens, plug_load.frac_sensible, 0.01)
        assert_in_epsilon(tv_lat, plug_load.frac_latent, 0.01)
      end
    end
  end
end
