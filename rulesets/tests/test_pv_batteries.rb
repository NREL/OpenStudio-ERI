# frozen_string_literal: true

require_relative '../../hpxml-measures/HPXMLtoOpenStudio/resources/minitest_helper'
require 'openstudio'
require_relative '../main.rb'
require 'fileutils'
require_relative 'util.rb'
require_relative '../../workflow/design'

class ERIPVTest < Minitest::Test
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
    hpxml_name = 'base-pv.xml'

    _test_ruleset(hpxml_name).each do |(_run_type, calc_type), hpxml_bldg|
      if [CalcType::RatedHome].include? calc_type
        _check_pv(hpxml_bldg, [{ location: HPXML::LocationRoof, moduletype: HPXML::PVModuleTypeStandard, tracking: HPXML::PVTrackingTypeFixed, azimuth: 180, tilt: 20, power: 4000, inv_eff: 0.96, losses: 0.14, is_shared: false },
                               { location: HPXML::LocationRoof, moduletype: HPXML::PVModuleTypePremium, tracking: HPXML::PVTrackingTypeFixed, azimuth: 90, tilt: 20, power: 1500, inv_eff: 0.96, losses: 0.14, is_shared: false }])
      else
        _check_pv(hpxml_bldg)
      end
    end
  end

  def test_pv_shared
    hpxml_name = 'base-bldgtype-mf-unit-shared-pv.xml'

    _test_ruleset(hpxml_name).each do |(_run_type, calc_type), hpxml_bldg|
      if [CalcType::RatedHome].include? calc_type
        _check_pv(hpxml_bldg, [{ location: HPXML::LocationGround, moduletype: HPXML::PVModuleTypeStandard, tracking: HPXML::PVTrackingTypeFixed, azimuth: 225, tilt: 30, power: 30000, inv_eff: 0.96, losses: 0.14, is_shared: true, nbeds_served: 18 }])
      else
        _check_pv(hpxml_bldg)
      end
    end
  end

  def test_pv_batteries
    hpxml_name = 'base-pv-battery.xml'

    _test_ruleset(hpxml_name).each do |(_run_type, calc_type), hpxml_bldg|
      if [CalcType::RatedHome].include? calc_type
        _check_battery(hpxml_bldg, [{ type: HPXML::BatteryTypeLithiumIon, location: HPXML::LocationOutside, nominal_capacity_kwh: 20.0, usable_capacity_kwh: 18.0, rated_power_output: 6000, round_trip_efficiency: 0.925, is_shared: false }])
      else
        _check_battery(hpxml_bldg)
      end
    end
  end

  def test_pv_batteries_shared
    hpxml_name = 'base-bldgtype-mf-unit-shared-pv-battery.xml'

    _test_ruleset(hpxml_name).each do |(_run_type, calc_type), hpxml_bldg|
      if [CalcType::RatedHome].include? calc_type
        _check_pv(hpxml_bldg, [{ location: HPXML::LocationGround, moduletype: HPXML::PVModuleTypeStandard, tracking: HPXML::PVTrackingTypeFixed, azimuth: 225, tilt: 30, power: 30000, inv_eff: 0.96, losses: 0.14, is_shared: true, nbeds_served: 18 }])
        _check_battery(hpxml_bldg, [{ type: HPXML::BatteryTypeLithiumIon, location: HPXML::LocationOutside, nominal_capacity_kwh: 120.0, usable_capacity_kwh: 108.0, rated_power_output: 36000, round_trip_efficiency: 0.925, is_shared: true, nbeds_served: 18 }])
      else
        _check_pv(hpxml_bldg)
        _check_battery(hpxml_bldg)
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

  def _check_pv(hpxml_bldg, all_expected_values = [])
    assert_equal(all_expected_values.size, hpxml_bldg.pv_systems.size)
    hpxml_bldg.pv_systems.each_with_index do |pv_system, idx|
      expected_values = all_expected_values[idx]
      assert_equal(expected_values[:is_shared], pv_system.is_shared_system)
      assert_equal(expected_values[:location], pv_system.location)
      assert_equal(expected_values[:moduletype], pv_system.module_type)
      assert_equal(expected_values[:tracking], pv_system.tracking)
      assert_equal(expected_values[:azimuth], pv_system.array_azimuth)
      assert_equal(expected_values[:tilt], pv_system.array_tilt)
      assert_equal(expected_values[:power], pv_system.max_power_output.to_f)
      assert_equal(expected_values[:inv_eff], pv_system.inverter.inverter_efficiency)
      assert_equal(expected_values[:losses], pv_system.system_losses_fraction)
      if expected_values[:nbeds_served].nil?
        assert_nil(pv_system.number_of_bedrooms_served)
      else
        assert_equal(expected_values[:nbeds_served], pv_system.number_of_bedrooms_served)
      end
    end
  end

  def _check_battery(hpxml_bldg, all_expected_values = [])
    assert_equal(all_expected_values.size, hpxml_bldg.batteries.size)
    hpxml_bldg.batteries.each_with_index do |battery, idx|
      expected_values = all_expected_values[idx]
      assert_equal(expected_values[:is_shared], battery.is_shared_system)
      assert_equal(expected_values[:type], battery.type)
      assert_equal(expected_values[:location], battery.location)
      assert_equal(expected_values[:nominal_capacity_kwh], battery.nominal_capacity_kwh)
      assert_equal(expected_values[:usable_capacity_kwh], battery.usable_capacity_kwh)
      assert_equal(expected_values[:rated_power_output], battery.rated_power_output)
      assert_equal(expected_values[:round_trip_efficiency], battery.round_trip_efficiency)
      if expected_values[:nbeds_served].nil?
        assert_nil(battery.number_of_bedrooms_served)
      else
        assert_equal(expected_values[:nbeds_served], battery.number_of_bedrooms_served)
      end
    end
  end
end
