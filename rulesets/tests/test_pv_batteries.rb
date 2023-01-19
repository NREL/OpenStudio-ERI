# frozen_string_literal: true

require_relative '../../hpxml-measures/HPXMLtoOpenStudio/resources/minitest_helper'
require 'openstudio'
require_relative '../main.rb'
require 'fileutils'
require_relative 'util.rb'

class ERIPVTest < MiniTest::Test
  def setup
    @root_path = File.absolute_path(File.join(File.dirname(__FILE__), '..', '..'))
    @output_dir = File.join(@root_path, 'workflow', 'sample_files')
  end

  def teardown
    FileUtils.rm_rf(@results_path) if Dir.exist? @results_path
  end

  def test_pv
    hpxml_name = 'base-pv.xml'

    _all_calc_types.each do |calc_type|
      hpxml = _test_ruleset(hpxml_name, calc_type)
      if [Constants.CalcTypeERIRatedHome].include? calc_type
        _check_pv(hpxml, [{ location: HPXML::LocationRoof, moduletype: HPXML::PVModuleTypeStandard, tracking: HPXML::PVTrackingTypeFixed, azimuth: 180, tilt: 20, power: 4000, inv_eff: 0.96, losses: 0.14, is_shared: false },
                          { location: HPXML::LocationRoof, moduletype: HPXML::PVModuleTypePremium, tracking: HPXML::PVTrackingTypeFixed, azimuth: 90, tilt: 20, power: 1500, inv_eff: 0.96, losses: 0.14, is_shared: false }])
      else
        _check_pv(hpxml)
      end
    end
  end

  def test_pv_shared
    hpxml_name = 'base-bldgtype-multifamily-shared-pv.xml'

    _all_calc_types.each do |calc_type|
      hpxml = _test_ruleset(hpxml_name, calc_type)
      if [Constants.CalcTypeERIRatedHome].include? calc_type
        _check_pv(hpxml, [{ location: HPXML::LocationGround, moduletype: HPXML::PVModuleTypeStandard, tracking: HPXML::PVTrackingTypeFixed, azimuth: 225, tilt: 30, power: 30000, inv_eff: 0.96, losses: 0.14, is_shared: true, nbeds_served: 18 }])
      else
        _check_pv(hpxml)
      end
    end
  end

  def test_pv_batteries
    skip # Temporarily disabled until RESNET allows this.
    hpxml_name = 'base-pv-battery.xml'

    _all_calc_types.each do |calc_type|
      hpxml = _test_ruleset(hpxml_name, calc_type)
      if [Constants.CalcTypeERIRatedHome].include? calc_type
        _check_battery(hpxml, [{ type: HPXML::BatteryTypeLithiumIon, location: HPXML::LocationOutside, nominal_capacity_kwh: 20.0, usable_capacity_kwh: 18.0 }])
      else
        _check_battery(hpxml)
      end
    end
  end

  def _test_ruleset(hpxml_name, calc_type)
    require_relative '../../workflow/design'
    designs = [Design.new(calc_type: calc_type,
                          output_dir: @output_dir)]

    hpxml_input_path = File.join(@root_path, 'workflow', 'sample_files', hpxml_name)
    success, errors, _, _, hpxml = run_rulesets(hpxml_input_path, designs)

    errors.each do |s|
      puts "Error: #{s}"
    end

    # assert that it ran correctly
    assert_equal(true, success)

    # validate against OS-HPXML schematron
    schematron_path = File.join(File.dirname(__FILE__), '..', '..', 'hpxml-measures', 'HPXMLtoOpenStudio', 'resources', 'hpxml_schematron', 'EPvalidator.xml')
    validator = OpenStudio::XMLValidator.new(schematron_path)
    assert_equal(true, validator.validate(designs[0].hpxml_output_path))
    @results_path = File.dirname(designs[0].hpxml_output_path)

    return hpxml
  end

  def _check_pv(hpxml, all_expected_values = [])
    assert_equal(all_expected_values.size, hpxml.pv_systems.size)
    hpxml.pv_systems.each_with_index do |pv_system, idx|
      expected_values = all_expected_values[idx]
      assert_equal(expected_values[:is_shared], pv_system.is_shared_system)
      assert_equal(expected_values[:location], pv_system.location)
      assert_equal(expected_values[:moduletype], pv_system.module_type)
      assert_equal(expected_values[:tracking], pv_system.tracking)
      assert_equal(expected_values[:azimuth], pv_system.array_azimuth)
      assert_equal(expected_values[:tilt], pv_system.array_tilt)
      assert_equal(expected_values[:power], pv_system.max_power_output.to_f)
      assert_equal(expected_values[:inv_eff], pv_system.inverter_efficiency)
      assert_equal(expected_values[:losses], pv_system.system_losses_fraction)
      if expected_values[:nbeds_served].nil?
        assert_nil(pv_system.number_of_bedrooms_served)
      else
        assert_equal(expected_values[:nbeds_served], pv_system.number_of_bedrooms_served)
      end
    end
  end

  def _check_battery(hpxml, all_expected_values = [])
    assert_equal(all_expected_values.size, hpxml.batteries.size)
    hpxml.batteries.each_with_index do |battery, idx|
      expected_values = all_expected_values[idx]
      assert_equal(expected_values[:type], battery.type)
      assert_equal(expected_values[:location], battery.location)
      assert_equal(expected_values[:nominal_capacity_kwh], battery.nominal_capacity_kwh)
      assert_equal(expected_values[:usable_capacity_kwh], battery.usable_capacity_kwh)
    end
  end
end
