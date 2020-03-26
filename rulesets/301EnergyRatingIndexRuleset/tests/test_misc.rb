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
      hpxml_doc = _test_measure(hpxml_name, calc_type)
      _check_misc(hpxml_doc, 2457, 0.855, 0.045, 620, 1, 0)
    end

    # IAD, IAD Reference
    calc_types = [Constants.CalcTypeERIIndexAdjustmentDesign,
                  Constants.CalcTypeERIIndexAdjustmentReferenceHome]
    calc_types.each do |calc_type|
      hpxml_doc = _test_measure(hpxml_name, calc_type)
      _check_misc(hpxml_doc, 2184, 0.855, 0.045, 620, 1, 0)
    end
  end

  def _test_measure(hpxml_name, calc_type)
    args_hash = {}
    args_hash['hpxml_input_path'] = File.join(@root_path, 'workflow', 'sample_files', hpxml_name)
    args_hash['hpxml_output_path'] = File.join(File.dirname(__FILE__), "#{calc_type}.xml")
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
    assert(File.exist? args_hash['hpxml_output_path'])

    hpxml_doc = REXML::Document.new(File.read(args_hash['hpxml_output_path']))
    File.delete(args_hash['hpxml_output_path'])

    return hpxml_doc
  end

  def _check_misc(hpxml_doc, misc_kwh, misc_sens, misc_lat, tv_kwh, tv_sens, tv_lat)
    misc = hpxml_doc.elements['/HPXML/Building/BuildingDetails/MiscLoads/PlugLoad[PlugLoadType="other"]']
    assert_in_epsilon(Float(misc.elements['Load[Units="kWh/year"]/Value'].text), misc_kwh, 0.01)
    assert_in_epsilon(Float(misc.elements['extension/FracSensible'].text), misc_sens, 0.01)
    assert_in_epsilon(Float(misc.elements['extension/FracLatent'].text), misc_lat, 0.01)

    tv = hpxml_doc.elements['/HPXML/Building/BuildingDetails/MiscLoads/PlugLoad[PlugLoadType="TV other"]']
    assert_in_epsilon(Float(tv.elements['Load[Units="kWh/year"]/Value'].text), tv_kwh, 0.01)
    assert_in_epsilon(Float(tv.elements['extension/FracSensible'].text), tv_sens, 0.01)
    assert_in_epsilon(Float(tv.elements['extension/FracLatent'].text), tv_lat, 0.01)
  end
end
