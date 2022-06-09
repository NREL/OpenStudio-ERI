# frozen_string_literal: true

require_relative '../../../hpxml-measures/HPXMLtoOpenStudio/resources/minitest_helper'
require 'openstudio'
require 'openstudio/ruleset/ShowRunnerOutput'
require_relative '../measure.rb'
require 'fileutils'
require_relative 'util'

class EnergyStarVentTest < MiniTest::Test
  def setup
    @root_path = File.absolute_path(File.join(File.dirname(__FILE__), '..', '..', '..'))
    @tmp_hpxml_path = File.join(@root_path, 'workflow', 'sample_files', 'tmp.xml')
  end

  def teardown
    File.delete(@tmp_hpxml_path) if File.exist? @tmp_hpxml_path
  end

  def cfm_per_watt(es_version)
    if [ESConstants.SFNationalVer3_0, ESConstants.MFNationalVer1_0, ESConstants.SFPacificVer3_0, ESConstants.SFFloridaVer3_1].include? es_version
      return 2.2
    elsif [ESConstants.SFNationalVer3_1, ESConstants.SFNationalVer3_2, ESConstants.SFOregonWashingtonVer3_2,
           ESConstants.MFNationalVer1_1, ESConstants.MFNationalVer1_2, ESConstants.MFOregonWashingtonVer1_2].include? es_version
      return 2.8
    end
  end

  def fan_type(es_version, hpxml)
    iecc_zone = hpxml.climate_and_risk_zones.iecc_zone
    if [ESConstants.SFPacificVer3_0, ESConstants.SFFloridaVer3_1].include? es_version
      return HPXML::MechVentTypeSupply
    elsif [ESConstants.SFOregonWashingtonVer3_2, ESConstants.MFOregonWashingtonVer1_2].include? es_version
      return HPXML::MechVentTypeExhaust
    else
      if ['1A', '1B', '1C', '2A', '2B', '2C', '3A', '3B', '3C', '4A', '4B'].include? iecc_zone
        return HPXML::MechVentTypeSupply
      elsif ['4C', '5A', '5B', '5C', '6A', '6B', '6C', '7', '8'].include? iecc_zone
        return HPXML::MechVentTypeExhaust
      end
    end
  end

  def test_mech_vent
    ESConstants.AllVersions.each do |es_version|
      _convert_to_es('base.xml', es_version)
      hpxml = _test_measure()
      _check_mech_vent(hpxml, [{ fantype: fan_type(es_version, hpxml), flowrate: 57.0, hours: 24, power: (57.0 / cfm_per_watt(es_version)) }])
    end
  end

  def test_mech_vent_attached_or_multifamily
    ESConstants.AllVersions.each do |es_version|
      _convert_to_es('base-bldgtype-multifamily.xml', es_version)
      hpxml = _test_measure()
      _check_mech_vent(hpxml, [{ fantype: fan_type(es_version, hpxml), flowrate: 39.0, hours: 24, power: (39.0 / cfm_per_watt(es_version)) }])
    end
  end

  def test_mech_vent_erv
    ESConstants.AllVersions.each do |es_version|
      _convert_to_es('base-mechvent-erv.xml', es_version)
      hpxml = _test_measure()
      _check_mech_vent(hpxml, [{ fantype: fan_type(es_version, hpxml), flowrate: 57.0, hours: 24, power: (57.0 / cfm_per_watt(es_version)) }])
    end
  end

  def test_mech_vent_hrv
    ESConstants.AllVersions.each do |es_version|
      _convert_to_es('base-mechvent-hrv.xml', es_version)
      hpxml = _test_measure()
      _check_mech_vent(hpxml, [{ fantype: fan_type(es_version, hpxml), flowrate: 57.0, hours: 24, power: (57.0 / cfm_per_watt(es_version)) }])
    end
  end

  def test_mech_vent_nbeds_5
    ESConstants.AllVersions.each do |es_version|
      _convert_to_es('base-enclosure-beds-5.xml', es_version)
      hpxml = _test_measure()
      _check_mech_vent(hpxml, [{ fantype: fan_type(es_version, hpxml), flowrate: 72.0, hours: 24, power: (72.0 / cfm_per_watt(es_version)) }])
    end
  end

  def test_mech_vent_location_miami_fl
    ESConstants.NationalVersions.each do |es_version|
      _convert_to_es('base-location-miami-fl.xml', es_version)
      hpxml = _test_measure()
      _check_mech_vent(hpxml, [{ fantype: fan_type(es_version, hpxml), flowrate: 43.5, hours: 24, power: (43.5 / cfm_per_watt(es_version)) }])
    end
  end

  def test_mech_vent_attached_or_multifamily_location_miami_fl
    ESConstants.AllVersions.each do |es_version|
      next unless ESConstants.NationalVersions.include?(es_version)

      _convert_to_es('base-bldgtype-multifamily.xml', es_version)
      hpxml = HPXML.new(hpxml_path: @tmp_hpxml_path)
      hpxml.climate_and_risk_zones.iecc_zone = '1A'
      hpxml.climate_and_risk_zones.weather_station_name = 'Miami, FL'
      hpxml.climate_and_risk_zones.weather_station_wmo = 722020
      XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
      hpxml = _test_measure()
      _check_mech_vent(hpxml, [{ fantype: fan_type(es_version, hpxml), flowrate: 39.0, hours: 24, power: (39.0 / cfm_per_watt(es_version)) }])
    end
  end

  def test_whole_house_fan
    ESConstants.AllVersions.each do |es_version|
      _convert_to_es('base-mechvent-whole-house-fan.xml', es_version)
      hpxml = _test_measure()
      _check_whf(hpxml)
    end
  end

  def _test_measure()
    args_hash = {}
    args_hash['hpxml_input_path'] = @tmp_hpxml_path
    args_hash['calc_type'] = ESConstants.CalcTypeEnergyStarReference

    # create an instance of the measure
    measure = EnergyStarMeasure.new

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

  def _check_mech_vent(hpxml, all_expected_values = [])
    num_mech_vent = 0
    hpxml.ventilation_fans.each_with_index do |ventilation_fan, idx|
      next unless ventilation_fan.used_for_whole_building_ventilation

      expected_values = all_expected_values[idx]
      num_mech_vent += 1
      assert_equal(expected_values[:fantype], ventilation_fan.fan_type)
      assert_in_delta(expected_values[:flowrate], ventilation_fan.rated_flow_rate.to_f + ventilation_fan.tested_flow_rate.to_f, 0.1)
      assert_in_delta(expected_values[:hours], ventilation_fan.hours_in_operation, 0.1)
      assert_in_delta(expected_values[:power], ventilation_fan.fan_power, 0.1)
      if expected_values[:sre].nil?
        assert_nil(ventilation_fan.sensible_recovery_efficiency)
      else
        assert_equal(expected_values[:sre], ventilation_fan.sensible_recovery_efficiency)
      end
      if expected_values[:tre].nil?
        assert_nil(ventilation_fan.total_recovery_efficiency)
      else
        assert_equal(expected_values[:tre], ventilation_fan.total_recovery_efficiency)
      end
      if expected_values[:asre].nil?
        assert_nil(ventilation_fan.sensible_recovery_efficiency_adjusted)
      else
        assert_equal(expected_values[:asre], ventilation_fan.sensible_recovery_efficiency_adjusted)
      end
      if expected_values[:atre].nil?
        assert_nil(ventilation_fan.total_recovery_efficiency_adjusted)
      else
        assert_equal(expected_values[:atre], ventilation_fan.total_recovery_efficiency_adjusted)
      end
      if expected_values[:in_unit_flowrate].nil?
        assert_nil(ventilation_fan.in_unit_flow_rate)
      else
        assert_equal(true, ventilation_fan.is_shared_system)
        assert_in_delta(expected_values[:in_unit_flowrate], ventilation_fan.in_unit_flow_rate, 0.1)
      end
      if expected_values[:frac_recirc].nil?
        assert_nil(ventilation_fan.fraction_recirculation)
      else
        assert_equal(expected_values[:frac_recirc], ventilation_fan.fraction_recirculation)
      end
      if expected_values[:has_preheat].nil? || (not expected_values[:has_preheat])
        assert_nil(ventilation_fan.preheating_fuel)
      else
        refute_nil(ventilation_fan.preheating_fuel)
      end
      if expected_values[:has_precool].nil? || (not expected_values[:has_precool])
        assert_nil(ventilation_fan.precooling_fuel)
      else
        refute_nil(ventilation_fan.precooling_fuel)
      end
    end
    assert_equal(all_expected_values.size, num_mech_vent)
  end

  def _check_whf(hpxml)
    assert_equal(0, hpxml.ventilation_fans.select { |f| f.used_for_seasonal_cooling_load_reduction }.size)
  end

  def _convert_to_es(hpxml_name, program_version, state_code = nil)
    return convert_to_es(hpxml_name, program_version, @root_path, @tmp_hpxml_path, state_code)
  end
end
