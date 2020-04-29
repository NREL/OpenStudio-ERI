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

  def _get_hpxml_info(hpxml)
    nbeds = hpxml.building_construction.number_of_bedrooms
    cfa = hpxml.building_construction.conditioned_floor_area
    eri_design = hpxml.header.eri_design
    return nbeds, cfa, eri_design
  end

  def _expected_misc_ref_energy_gains(cfa)
    kwh_per_yr = 0.91 * cfa
    sens_btu_per_yr = (7.27 * cfa) * 365.0
    lat_btu_per_yr = (0.38 * cfa) * 365.0
    return [kwh_per_yr, sens_btu_per_yr, lat_btu_per_yr]
  end

  def _expected_tv_ref_energy_gains(nbeds)
    kwh_per_yr = 413 + 69 * nbeds
    sens_btu_per_yr = (3861 + 645 * nbeds) * 365.0
    lat_btu_per_yr = 0.0
    return [kwh_per_yr, sens_btu_per_yr, lat_btu_per_yr]
  end

  def _check_misc(hpxml, misc_kwh, misc_sens, misc_lat, tv_kwh, tv_sens, tv_lat)
    num_pls = 0
    hpxml.plug_loads.each do |plug_load|
      if plug_load.plug_load_type == HPXML::PlugLoadTypeOther
        num_pls += 1
        assert_in_epsilon(misc_kwh, plug_load.kWh_per_year, 0.01)
        assert_in_epsilon(misc_sens, plug_load.frac_sensible, 0.01)
        assert_in_epsilon(misc_lat, plug_load.frac_latent, 0.01)

        # Energy & Internal Gains
        nbeds, cfa, eri_design = _get_hpxml_info(hpxml)
        if (eri_design == Constants.CalcTypeERIReferenceHome) || (eri_design == Constants.CalcTypeERIIndexAdjustmentReferenceHome)
          btu = UnitConversions.convert(plug_load.kWh_per_year, 'kWh', 'Btu')

          expected_annual_kwh, expected_sens_btu, expected_lat_btu = _expected_misc_ref_energy_gains(cfa)
          assert_in_epsilon(expected_annual_kwh, plug_load.kWh_per_year, 0.02)
          assert_in_epsilon(expected_sens_btu, plug_load.frac_sensible * btu, 0.01)
          assert_in_epsilon(expected_lat_btu, plug_load.frac_latent * btu, 0.01)
        end
      elsif plug_load.plug_load_type == HPXML::PlugLoadTypeTelevision
        num_pls += 1
        assert_in_epsilon(tv_kwh, plug_load.kWh_per_year, 0.01)
        assert_in_epsilon(tv_sens, plug_load.frac_sensible, 0.01)
        assert_in_epsilon(tv_lat, plug_load.frac_latent, 0.01)

        # Energy & Internal Gains
        nbeds, cfa, eri_design = _get_hpxml_info(hpxml)
        if (eri_design == Constants.CalcTypeERIReferenceHome) || (eri_design == Constants.CalcTypeERIIndexAdjustmentReferenceHome)
          btu = UnitConversions.convert(plug_load.kWh_per_year, 'kWh', 'Btu')

          expected_annual_kwh, expected_sens_btu, expected_lat_btu = _expected_tv_ref_energy_gains(nbeds)
          assert_in_epsilon(expected_annual_kwh, plug_load.kWh_per_year, 0.02)
          assert_in_epsilon(expected_sens_btu, plug_load.frac_sensible * btu, 0.01)
          assert_in_epsilon(expected_lat_btu, plug_load.frac_latent * btu, 0.01)
        end
      end
    end
    assert_equal(2, num_pls)
  end
end
