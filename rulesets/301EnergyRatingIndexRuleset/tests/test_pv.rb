# frozen_string_literal: true

require_relative '../../../workflow/tests/minitest_helper'
require 'openstudio/ruleset/ShowRunnerOutput'
require 'minitest/autorun'
require_relative '../measure.rb'
require 'fileutils'
require_relative 'util.rb'

class ERIPVTest < MiniTest::Test
  def before_setup
    @root_path = File.absolute_path(File.join(File.dirname(__FILE__), '..', '..', '..'))
  end

  def test_pv
    hpxml_name = 'base-pv.xml'

    # Reference Home, IAD, IAD Reference
    calc_types = [Constants.CalcTypeERIReferenceHome,
                  Constants.CalcTypeERIIndexAdjustmentDesign,
                  Constants.CalcTypeERIIndexAdjustmentReferenceHome]
    calc_types.each do |calc_type|
      hpxml = _test_measure(hpxml_name, calc_type)
      _check_pv(hpxml)
    end

    # Rated Home
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_pv(hpxml, [false, HPXML::LocationRoof, HPXML::PVModuleTypeStandard, HPXML::PVTrackingTypeFixed, 180, 20, 4000, 0.96, 0.14],
              [false, HPXML::LocationRoof, HPXML::PVModuleTypePremium, HPXML::PVTrackingTypeFixed, 90, 20, 1500, 0.96, 0.14])
  end

  def test_pv_shared
    hpxml_name = 'base-pv-shared.xml'

    # Reference Home, IAD, IAD Reference
    calc_types = [Constants.CalcTypeERIReferenceHome,
                  Constants.CalcTypeERIIndexAdjustmentDesign,
                  Constants.CalcTypeERIIndexAdjustmentReferenceHome]
    calc_types.each do |calc_type|
      hpxml = _test_measure(hpxml_name, calc_type)
      _check_pv(hpxml)
    end

    # Rated Home
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_pv(hpxml, [true, HPXML::LocationGround, HPXML::PVModuleTypeStandard, HPXML::PVTrackingTypeFixed, 225, 30, 30000, 0.96, 0.14, 20])
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

  def _check_pv(hpxml, *pvsystems)
    assert_equal(pvsystems.size, hpxml.pv_systems.size)
    hpxml.pv_systems.each_with_index do |pv_system, idx|
      is_shared, location, moduletype, tracking, azimuth, tilt, power, inv_eff, losses, nbeds_served = pvsystems[idx]
      assert_equal(is_shared, pv_system.is_shared_system)
      assert_equal(location, pv_system.location)
      assert_equal(moduletype, pv_system.module_type)
      assert_equal(tracking, pv_system.tracking)
      assert_equal(azimuth, pv_system.array_azimuth)
      assert_equal(tilt, pv_system.array_tilt)
      assert_equal(power, pv_system.max_power_output.to_f)
      assert_equal(inv_eff, pv_system.inverter_efficiency)
      assert_equal(losses, pv_system.system_losses_fraction)
      if nbeds_served.nil?
        assert_nil(pv_system.number_of_bedrooms_served)
      else
        assert_equal(nbeds_served, pv_system.number_of_bedrooms_served)
      end
    end
  end
end
