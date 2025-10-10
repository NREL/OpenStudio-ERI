# frozen_string_literal: true

require_relative '../../hpxml-measures/HPXMLtoOpenStudio/resources/minitest_helper'
require 'openstudio'
require_relative '../main.rb'
require 'fileutils'
require_relative 'util.rb'
require_relative '../../workflow/design'

class EnergyStarZeroEnergyReadyHomeApplianceTest < Minitest::Test
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

  def test_appliances_electric
    [*ES::AllVersions, *ZERH::AllVersions].each do |program_version|
      _convert_to_es_zerh('base.xml', program_version)
      hpxml_bldg = _test_ruleset(program_version)
      if [ES::SFNationalVer3_2, ES::SFNationalVer3_3,
          ES::MFNationalVer1_2, ES::MFNationalVer1_3,
          ZERH::SFVer2, ZERH::MFVer2].include? program_version
        _check_clothes_washer(hpxml_bldg, mef: nil, imef: 1.57, annual_kwh: 284, elec_rate: 0.12, gas_rate: 1.09, agc: 18, cap: 4.2, label_usage: 6, location: HPXML::LocationConditionedSpace)
      elsif [ES::SFFloridaVer3_1, ES::SFOregonWashingtonVer3_2, ES::SFPacificVer3_0, ES::SFNationalVer3_0, ES::SFNationalVer3_1,
             ES::MFOregonWashingtonVer1_2, ES::MFNationalVer1_0, ES::MFNationalVer1_1,
             ZERH::Ver1].include? program_version
        _check_clothes_washer(hpxml_bldg, mef: nil, imef: 1.0, annual_kwh: 400, elec_rate: 0.12, gas_rate: 1.09, agc: 27, cap: 3.0, label_usage: 6, location: HPXML::LocationConditionedSpace)
      else
        fail "Unhandled program version: #{program_version}"
      end
      if [ES::SFNationalVer3_2,
          ES::MFNationalVer1_2, ES::MFNationalVer1_3].include? program_version
        _check_refrigerator(hpxml_bldg, annual_kwh: 450.0, location: HPXML::LocationConditionedSpace)
      elsif [ZERH::SFVer2, ZERH::MFVer2].include? program_version
        _check_refrigerator(hpxml_bldg, annual_kwh: 600.0, location: HPXML::LocationConditionedSpace)
      elsif program_version == ES::SFNationalVer3_3
        _check_refrigerator(hpxml_bldg, annual_kwh: 691.0, location: HPXML::LocationConditionedSpace)  # Same as Energy Rating Reference Home, as defined by ANSI/RESNET/ICC 301
      elsif [ES::SFFloridaVer3_1, ES::SFOregonWashingtonVer3_2, ES::SFPacificVer3_0, ES::SFNationalVer3_0, ES::SFNationalVer3_1,
             ES::MFOregonWashingtonVer1_2, ES::MFNationalVer1_0, ES::MFNationalVer1_1,
             ZERH::Ver1].include? program_version
        _check_refrigerator(hpxml_bldg, annual_kwh: 423.0, location: HPXML::LocationConditionedSpace)
      else
        fail "Unhandled program version: #{program_version}"
      end
      _check_clothes_dryer(hpxml_bldg, fuel_type: HPXML::FuelTypeElectricity, ef: nil, cef: 3.01, location: HPXML::LocationConditionedSpace)
      if [ES::SFNationalVer3_3,
          ES::MFNationalVer1_3].include? program_version
        _check_dishwasher(hpxml_bldg, ef: nil, annual_kwh: 240.0, cap: 12, elec_rate: 0.14, gas_rate: 1.21, agc: 24.00, label_usage: 4, location: HPXML::LocationConditionedSpace)
      elsif [ES::SFFloridaVer3_1, ES::SFOregonWashingtonVer3_2, ES::SFPacificVer3_0, ES::SFNationalVer3_0, ES::SFNationalVer3_1, ES::SFNationalVer3_2,
             ES::MFOregonWashingtonVer1_2, ES::MFNationalVer1_0, ES::MFNationalVer1_1, ES::MFNationalVer1_2,
             ZERH::Ver1, ZERH::SFVer2, ZERH::MFVer2].include? program_version
        _check_dishwasher(hpxml_bldg, ef: nil, annual_kwh: 270.0, cap: 12, elec_rate: 0.12, gas_rate: 1.09, agc: 22.23, label_usage: 4, location: HPXML::LocationConditionedSpace)
      else
        fail "Unhandled program version: #{program_version}"
      end
      _check_cooking_range(hpxml_bldg, fuel_type: HPXML::FuelTypeElectricity, cook_is_induction: false, oven_is_convection: false, location: HPXML::LocationConditionedSpace)
    end
  end

  def test_appliances_modified
    [*ES::AllVersions, *ZERH::AllVersions].each do |program_version|
      _convert_to_es_zerh('base-appliances-modified.xml', program_version)
      hpxml_bldg = _test_ruleset(program_version)
      if [ES::SFNationalVer3_2, ES::SFNationalVer3_3,
          ES::MFNationalVer1_2, ES::MFNationalVer1_3,
          ZERH::SFVer2, ZERH::MFVer2].include? program_version
        _check_clothes_washer(hpxml_bldg, mef: nil, imef: 1.57, annual_kwh: 284, elec_rate: 0.12, gas_rate: 1.09, agc: 18, cap: 4.2, label_usage: 6, location: HPXML::LocationConditionedSpace)
      elsif [ES::SFFloridaVer3_1, ES::SFOregonWashingtonVer3_2, ES::SFPacificVer3_0, ES::SFNationalVer3_0, ES::SFNationalVer3_1,
             ES::MFOregonWashingtonVer1_2, ES::MFNationalVer1_0, ES::MFNationalVer1_1,
             ZERH::Ver1].include? program_version
        _check_clothes_washer(hpxml_bldg, mef: nil, imef: 1.0, annual_kwh: 400, elec_rate: 0.12, gas_rate: 1.09, agc: 27, cap: 3.0, label_usage: 6, location: HPXML::LocationConditionedSpace)
      else
        fail "Unhandled program version: #{program_version}"
      end
      if [ES::SFNationalVer3_2,
          ES::MFNationalVer1_2, ES::MFNationalVer1_3].include? program_version
        _check_refrigerator(hpxml_bldg, annual_kwh: 450.0, location: HPXML::LocationConditionedSpace)
      elsif [ZERH::SFVer2, ZERH::MFVer2].include? program_version
        _check_refrigerator(hpxml_bldg, annual_kwh: 600.0, location: HPXML::LocationConditionedSpace)
      elsif program_version == ES::SFNationalVer3_3
        _check_refrigerator(hpxml_bldg, annual_kwh: 691.0, location: HPXML::LocationConditionedSpace)  # Same as Energy Rating Reference Home, as defined by ANSI/RESNET/ICC 301
      elsif [ES::SFFloridaVer3_1, ES::SFOregonWashingtonVer3_2, ES::SFPacificVer3_0, ES::SFNationalVer3_0, ES::SFNationalVer3_1,
             ES::MFOregonWashingtonVer1_2, ES::MFNationalVer1_0, ES::MFNationalVer1_1,
             ZERH::Ver1].include? program_version
        _check_refrigerator(hpxml_bldg, annual_kwh: 423.0, location: HPXML::LocationConditionedSpace)
      else
        fail "Unhandled program version: #{program_version}"
      end
      _check_clothes_dryer(hpxml_bldg, fuel_type: HPXML::FuelTypeElectricity, ef: nil, cef: 3.01, location: HPXML::LocationConditionedSpace)
      _check_dishwasher(hpxml_bldg, ef: nil, annual_kwh: 203.0, cap: 6, elec_rate: 0.12, gas_rate: 1.09, agc: 14.20, label_usage: 4, location: HPXML::LocationConditionedSpace)
      _check_cooking_range(hpxml_bldg, fuel_type: HPXML::FuelTypeElectricity, cook_is_induction: false, oven_is_convection: false, location: HPXML::LocationConditionedSpace)
    end
  end

  def test_appliances_gas
    [*ES::AllVersions, *ZERH::AllVersions].each do |program_version|
      _convert_to_es_zerh('base-appliances-gas.xml', program_version)
      hpxml_bldg = _test_ruleset(program_version)
      if [ES::SFNationalVer3_2, ES::SFNationalVer3_3,
          ES::MFNationalVer1_2, ES::MFNationalVer1_3,
          ZERH::SFVer2, ZERH::MFVer2].include? program_version
        _check_clothes_washer(hpxml_bldg, mef: nil, imef: 1.57, annual_kwh: 284, elec_rate: 0.12, gas_rate: 1.09, agc: 18, cap: 4.2, label_usage: 6, location: HPXML::LocationConditionedSpace)
      elsif [ES::SFFloridaVer3_1, ES::SFOregonWashingtonVer3_2, ES::SFPacificVer3_0, ES::SFNationalVer3_0, ES::SFNationalVer3_1,
             ES::MFOregonWashingtonVer1_2, ES::MFNationalVer1_0, ES::MFNationalVer1_1,
             ZERH::Ver1].include? program_version
        _check_clothes_washer(hpxml_bldg, mef: nil, imef: 1.0, annual_kwh: 400, elec_rate: 0.12, gas_rate: 1.09, agc: 27, cap: 3.0, label_usage: 6, location: HPXML::LocationConditionedSpace)
      else
        fail "Unhandled program version: #{program_version}"
      end
      if [ES::SFNationalVer3_2,
          ES::MFNationalVer1_2, ES::MFNationalVer1_3].include? program_version
        _check_refrigerator(hpxml_bldg, annual_kwh: 450.0, location: HPXML::LocationConditionedSpace)
      elsif [ZERH::SFVer2, ZERH::MFVer2].include? program_version
        _check_refrigerator(hpxml_bldg, annual_kwh: 600.0, location: HPXML::LocationConditionedSpace)
      elsif program_version == ES::SFNationalVer3_3
        _check_refrigerator(hpxml_bldg, annual_kwh: 691.0, location: HPXML::LocationConditionedSpace)  # Same as Energy Rating Reference Home, as defined by ANSI/RESNET/ICC 301
      elsif [ES::SFFloridaVer3_1, ES::SFOregonWashingtonVer3_2, ES::SFPacificVer3_0, ES::SFNationalVer3_0, ES::SFNationalVer3_1,
             ES::MFOregonWashingtonVer1_2, ES::MFNationalVer1_0, ES::MFNationalVer1_1,
             ZERH::Ver1].include? program_version
        _check_refrigerator(hpxml_bldg, annual_kwh: 423.0, location: HPXML::LocationConditionedSpace)
      else
        fail "Unhandled program version: #{program_version}"
      end
      _check_clothes_dryer(hpxml_bldg, fuel_type: HPXML::FuelTypeNaturalGas, ef: nil, cef: 3.01, location: HPXML::LocationConditionedSpace)
      if [ES::SFNationalVer3_3, ES::MFNationalVer1_3].include? program_version
        _check_dishwasher(hpxml_bldg, ef: nil, annual_kwh: 240.0, cap: 12, elec_rate: 0.14, gas_rate: 1.21, agc: 24.00, label_usage: 4, location: HPXML::LocationConditionedSpace)
      elsif [ES::SFFloridaVer3_1, ES::SFOregonWashingtonVer3_2, ES::SFPacificVer3_0, ES::SFNationalVer3_0, ES::SFNationalVer3_1, ES::SFNationalVer3_2,
             ES::MFOregonWashingtonVer1_2, ES::MFNationalVer1_0, ES::MFNationalVer1_1, ES::MFNationalVer1_2,
             ZERH::Ver1, ZERH::SFVer2, ZERH::MFVer2].include? program_version
        _check_dishwasher(hpxml_bldg, ef: nil, annual_kwh: 270.0, cap: 12, elec_rate: 0.12, gas_rate: 1.09, agc: 22.23, label_usage: 4, location: HPXML::LocationConditionedSpace)
      else
        fail "Unhandled program version: #{program_version}"
      end
      _check_cooking_range(hpxml_bldg, fuel_type: HPXML::FuelTypeNaturalGas, cook_is_induction: false, oven_is_convection: false, location: HPXML::LocationConditionedSpace)
    end
  end

  def test_appliances_basement
    [*ES::AllVersions, *ZERH::AllVersions].each do |program_version|
      _convert_to_es_zerh('base-foundation-unconditioned-basement.xml', program_version)
      hpxml_bldg = _test_ruleset(program_version)
      assert_equal(HPXML::LocationBasementUnconditioned, hpxml_bldg.clothes_washers[0].location)
      assert_equal(HPXML::LocationBasementUnconditioned, hpxml_bldg.clothes_dryers[0].location)
      assert_equal(HPXML::LocationBasementUnconditioned, hpxml_bldg.dishwashers[0].location)
      assert_equal(HPXML::LocationBasementUnconditioned, hpxml_bldg.refrigerators[0].location)
      assert_equal(HPXML::LocationBasementUnconditioned, hpxml_bldg.cooking_ranges[0].location)
    end
  end

  def test_appliances_none
    [*ES::AllVersions, *ZERH::AllVersions].each do |program_version|
      _convert_to_es_zerh('base-appliances-none.xml', program_version)
      hpxml_bldg = _test_ruleset(program_version)
      if [ES::SFNationalVer3_2,
          ES::MFNationalVer1_2, ES::MFNationalVer1_3].include? program_version
        _check_refrigerator(hpxml_bldg, annual_kwh: 450.0, location: HPXML::LocationConditionedSpace)
      elsif [ES::SFNationalVer3_3, ZERH::SFVer2, ZERH::MFVer2].include? program_version
        _check_refrigerator(hpxml_bldg, annual_kwh: 691.0, location: HPXML::LocationConditionedSpace)  # Same as Energy Rating Reference Home, as defined by ANSI/RESNET/ICC 301
      elsif [ES::SFFloridaVer3_1, ES::SFOregonWashingtonVer3_2, ES::SFPacificVer3_0, ES::SFNationalVer3_0, ES::SFNationalVer3_1,
             ES::MFOregonWashingtonVer1_2, ES::MFNationalVer1_0, ES::MFNationalVer1_1,
             ZERH::Ver1].include? program_version
        _check_refrigerator(hpxml_bldg, annual_kwh: 423.0, location: HPXML::LocationConditionedSpace)
      else
        fail "Unhandled program version: #{program_version}"
      end
      _check_clothes_washer(hpxml_bldg, mef: nil, imef: 1.0, annual_kwh: 400, elec_rate: 0.12, gas_rate: 1.09, agc: 27, cap: 3.0, label_usage: 6, location: HPXML::LocationConditionedSpace)
      _check_clothes_dryer(hpxml_bldg, fuel_type: HPXML::FuelTypeElectricity, ef: nil, cef: 3.01, location: HPXML::LocationConditionedSpace)
      if [ES::SFNationalVer3_3, ES::MFNationalVer1_3].include? program_version
        _check_dishwasher(hpxml_bldg, ef: nil, annual_kwh: 240.0, cap: 12, elec_rate: 0.14, gas_rate: 1.21, agc: 24.00, label_usage: 4, location: HPXML::LocationConditionedSpace)
      elsif [ES::SFFloridaVer3_1, ES::SFOregonWashingtonVer3_2, ES::SFPacificVer3_0, ES::SFNationalVer3_0, ES::SFNationalVer3_1, ES::SFNationalVer3_2,
             ES::MFOregonWashingtonVer1_2, ES::MFNationalVer1_0, ES::MFNationalVer1_1, ES::MFNationalVer1_2,
             ZERH::Ver1, ZERH::SFVer2, ZERH::MFVer2].include? program_version
        _check_dishwasher(hpxml_bldg, ef: nil, annual_kwh: 270.0, cap: 12, elec_rate: 0.12, gas_rate: 1.09, agc: 22.23, label_usage: 4, location: HPXML::LocationConditionedSpace)
      else
        fail "Unhandled program version: #{program_version}"
      end
      _check_cooking_range(hpxml_bldg, fuel_type: HPXML::FuelTypeElectricity, cook_is_induction: false, oven_is_convection: false, location: HPXML::LocationConditionedSpace)
    end
  end

  def test_appliances_dehumidifier
    [*ES::AllVersions, *ZERH::AllVersions].each do |program_version|
      _convert_to_es_zerh('base.xml', program_version)
      hpxml_bldg = _test_ruleset(program_version)
      _check_dehumidifiers(hpxml_bldg)

      _convert_to_es_zerh('base-appliances-dehumidifier-multiple.xml', program_version)
      hpxml_bldg = _test_ruleset(program_version)
      _check_dehumidifiers(hpxml_bldg, [{ type: HPXML::DehumidifierTypePortable, capacity: 40.0, ief: 1.04, rh_setpoint: 0.6, frac_load: 0.5, location: HPXML::LocationConditionedSpace },
                                        { type: HPXML::DehumidifierTypePortable, capacity: 30.0, ief: 0.95, rh_setpoint: 0.6, frac_load: 0.25, location: HPXML::LocationConditionedSpace }])
    end
  end

  def test_shared_clothes_washers_dryers
    [*ES::AllVersions, *ZERH::AllVersions].each do |program_version|
      _convert_to_es_zerh('base-bldgtype-mf-unit-shared-laundry-room.xml', program_version)
      hpxml_bldg = _test_ruleset(program_version)
      if [ES::SFNationalVer3_2, ES::SFNationalVer3_3,
          ES::MFNationalVer1_2, ES::MFNationalVer1_3,
          ZERH::SFVer2, ZERH::MFVer2].include? program_version
        _check_clothes_washer(hpxml_bldg, mef: nil, imef: 1.57, annual_kwh: 284, elec_rate: 0.12, gas_rate: 1.09, agc: 18, cap: 4.2, label_usage: 6, location: HPXML::LocationOtherHeatedSpace)
      elsif [ES::SFFloridaVer3_1, ES::SFOregonWashingtonVer3_2, ES::SFPacificVer3_0, ES::SFNationalVer3_0, ES::SFNationalVer3_1,
             ES::MFOregonWashingtonVer1_2, ES::MFNationalVer1_0, ES::MFNationalVer1_1,
             ZERH::Ver1].include? program_version
        _check_clothes_washer(hpxml_bldg, mef: nil, imef: 1.0, annual_kwh: 400, elec_rate: 0.12, gas_rate: 1.09, agc: 27, cap: 3.0, label_usage: 6, location: HPXML::LocationOtherHeatedSpace)
      else
        fail "Unhandled program version: #{program_version}"
      end
      if [ES::SFNationalVer3_2,
          ES::MFNationalVer1_2, ES::MFNationalVer1_3].include? program_version
        _check_refrigerator(hpxml_bldg, annual_kwh: 450.0, location: HPXML::LocationConditionedSpace)
      elsif [ZERH::SFVer2, ZERH::MFVer2].include? program_version
        _check_refrigerator(hpxml_bldg, annual_kwh: 600.0, location: HPXML::LocationConditionedSpace)
      elsif program_version == ES::SFNationalVer3_3
        _check_refrigerator(hpxml_bldg, annual_kwh: 691.0, location: HPXML::LocationConditionedSpace)  # Same as Energy Rating Reference Home, as defined by ANSI/RESNET/ICC 301
      elsif [ES::SFFloridaVer3_1, ES::SFOregonWashingtonVer3_2, ES::SFPacificVer3_0, ES::SFNationalVer3_0, ES::SFNationalVer3_1,
             ES::MFOregonWashingtonVer1_2, ES::MFNationalVer1_0, ES::MFNationalVer1_1,
             ZERH::Ver1].include? program_version
        _check_refrigerator(hpxml_bldg, annual_kwh: 423.0, location: HPXML::LocationConditionedSpace)
      else
        fail "Unhandled program version: #{program_version}"
      end
      _check_clothes_dryer(hpxml_bldg, fuel_type: HPXML::FuelTypeElectricity, ef: nil, cef: 3.01, location: HPXML::LocationOtherHeatedSpace)
      if [ES::SFNationalVer3_3, ES::MFNationalVer1_3].include? program_version
        _check_dishwasher(hpxml_bldg, ef: nil, annual_kwh: 240.0, cap: 12, elec_rate: 0.14, gas_rate: 1.21, agc: 24.00, label_usage: 4, location: HPXML::LocationOtherHeatedSpace)
      elsif [ES::SFFloridaVer3_1, ES::SFOregonWashingtonVer3_2, ES::SFPacificVer3_0, ES::SFNationalVer3_0, ES::SFNationalVer3_1, ES::SFNationalVer3_2,
             ES::MFOregonWashingtonVer1_2, ES::MFNationalVer1_0, ES::MFNationalVer1_1, ES::MFNationalVer1_2,
             ZERH::Ver1, ZERH::SFVer2, ZERH::MFVer2].include? program_version
        _check_dishwasher(hpxml_bldg, ef: nil, annual_kwh: 270.0, cap: 12, elec_rate: 0.12, gas_rate: 1.09, agc: 22.23, label_usage: 4, location: HPXML::LocationOtherHeatedSpace)
      else
        fail "Unhandled program version: #{program_version}"
      end
      _check_cooking_range(hpxml_bldg, fuel_type: HPXML::FuelTypeElectricity, cook_is_induction: false, oven_is_convection: false, location: HPXML::LocationConditionedSpace)
    end
  end

  def _test_ruleset(program_version)
    print '.'

    if ES::AllVersions.include? program_version
      run_type = RunType::ES
    elsif ZERH::AllVersions.include? program_version
      run_type = RunType::ZERH
    end
    designs = [Design.new(run_type: run_type,
                          init_calc_type: InitCalcType::TargetHome,
                          output_dir: @sample_files_path,
                          version: program_version)]

    success, errors, _, _, hpxml_bldgs = run_rulesets(@tmp_hpxml_path, designs, @schema_validator, @erivalidator)

    errors.each do |s|
      puts "Error: #{s}"
    end

    # assert that it ran correctly
    assert(success)

    # validate against 301 schematron
    designs.each do |design|
      valid = @erivalidator.validate(design.init_hpxml_output_path)
      puts @erivalidator.errors.map { |e| e.logMessage } unless valid
      assert(valid)
      @results_paths << File.absolute_path(File.join(File.dirname(design.init_hpxml_output_path), '..'))
    end

    return hpxml_bldgs.values[0]
  end

  def _check_clothes_washer(hpxml_bldg, mef:, imef:, annual_kwh:, elec_rate:, gas_rate:, agc:, cap:, label_usage:, location:)
    assert_equal(1, hpxml_bldg.clothes_washers.size)
    clothes_washer = hpxml_bldg.clothes_washers[0]
    assert_equal(location, clothes_washer.location)
    if mef.nil?
      assert_nil(clothes_washer.modified_energy_factor)
      assert_in_epsilon(imef, clothes_washer.integrated_modified_energy_factor, 0.01)
    else
      assert_nil(clothes_washer.integrated_modified_energy_factor)
      assert_in_epsilon(mef, clothes_washer.modified_energy_factor, 0.01)
    end
    assert_in_epsilon(annual_kwh, clothes_washer.rated_annual_kwh, 0.01)
    assert_in_epsilon(elec_rate, clothes_washer.label_electric_rate, 0.01)
    assert_in_epsilon(gas_rate, clothes_washer.label_gas_rate, 0.01)
    assert_in_epsilon(agc, clothes_washer.label_annual_gas_cost, 0.01)
    assert_in_epsilon(cap, clothes_washer.capacity, 0.01)
    assert_in_epsilon(label_usage, clothes_washer.label_usage, 0.01)
  end

  def _check_clothes_dryer(hpxml_bldg, fuel_type:, ef:, cef:, control: nil, location:)
    assert_equal(1, hpxml_bldg.clothes_dryers.size)
    clothes_dryer = hpxml_bldg.clothes_dryers[0]
    assert_equal(location, clothes_dryer.location)
    assert_equal(fuel_type, clothes_dryer.fuel_type)
    if ef.nil?
      assert_nil(clothes_dryer.energy_factor)
      assert_in_epsilon(cef, clothes_dryer.combined_energy_factor, 0.01)
    else
      assert_in_epsilon(ef, clothes_dryer.energy_factor, 0.01)
      assert_nil(clothes_dryer.combined_energy_factor)
    end
    if control.nil?
      assert_nil(clothes_dryer.control_type)
    else
      assert_equal(control, clothes_dryer.control_type)
    end
  end

  def _check_dishwasher(hpxml_bldg, ef:, annual_kwh:, cap:, elec_rate:, gas_rate:, agc:, label_usage:, location:)
    assert_equal(1, hpxml_bldg.dishwashers.size)
    dishwasher = hpxml_bldg.dishwashers[0]
    assert_equal(location, dishwasher.location)
    if ef.nil?
      assert_nil(dishwasher.energy_factor)
      assert_in_epsilon(annual_kwh, dishwasher.rated_annual_kwh, 0.01)
    else
      assert_nil(dishwasher.rated_annual_kwh)
      assert_in_epsilon(ef, dishwasher.energy_factor, 0.01)
    end
    assert_in_epsilon(cap, dishwasher.place_setting_capacity, 0.01)
    assert_in_epsilon(elec_rate, dishwasher.label_electric_rate, 0.01)
    assert_in_epsilon(gas_rate, dishwasher.label_gas_rate, 0.01)
    assert_in_epsilon(agc, dishwasher.label_annual_gas_cost, 0.01)
    assert_in_epsilon(label_usage, dishwasher.label_usage, 0.01)
  end

  def _check_refrigerator(hpxml_bldg, annual_kwh:, location:)
    assert_equal(1, hpxml_bldg.refrigerators.size)
    refrigerator = hpxml_bldg.refrigerators[0]
    assert_equal(location, refrigerator.location)
    assert_in_epsilon(annual_kwh, refrigerator.rated_annual_kwh, 0.01)
  end

  def _check_cooking_range(hpxml_bldg, fuel_type:, cook_is_induction:, oven_is_convection:, location:)
    assert_equal(1, hpxml_bldg.cooking_ranges.size)
    cooking_range = hpxml_bldg.cooking_ranges[0]
    assert_equal(location, cooking_range.location)
    assert_equal(fuel_type, cooking_range.fuel_type)
    assert_equal(cook_is_induction, cooking_range.is_induction)
    assert_equal(1, hpxml_bldg.ovens.size)
    oven = hpxml_bldg.ovens[0]
    assert_equal(oven_is_convection, oven.is_convection)
  end

  def _check_dehumidifiers(hpxml_bldg, all_expected_values = [])
    assert_equal(all_expected_values.size, hpxml_bldg.dehumidifiers.size)
    hpxml_bldg.dehumidifiers.each_with_index do |dehumidifier, idx|
      expected_values = all_expected_values[idx]
      assert_equal(expected_values[:type], dehumidifier.type)
      assert_equal(expected_values[:location], dehumidifier.location)
      assert_equal(expected_values[:capacity], dehumidifier.capacity)
      if expected_values[:ef].nil?
        assert_nil(dehumidifier.energy_factor)
      else
        assert_equal(expected_values[:ef], dehumidifier.energy_factor)
      end
      if expected_values[:ief].nil?
        assert_nil(dehumidifier.integrated_energy_factor)
      else
        assert_equal(expected_values[:ief], dehumidifier.integrated_energy_factor)
      end
      assert_equal(expected_values[:rh_setpoint], dehumidifier.rh_setpoint)
      assert_equal(expected_values[:frac_load], dehumidifier.fraction_served)
    end
  end
end
