# frozen_string_literal: true

require_relative '../../hpxml-measures/HPXMLtoOpenStudio/resources/minitest_helper'
require 'openstudio'
require_relative '../main.rb'
require 'fileutils'
require_relative 'util.rb'
require_relative '../../workflow/design'

class ERIWaterHeatingTest < Minitest::Test
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

  def test_water_heating_tank_elec
    hpxml_name = 'base.xml'

    _test_ruleset(hpxml_name).each do |(_run_type, calc_type), hpxml_bldg|
      if [CalcType::ReferenceHome, CalcType::ReferenceHome].include? calc_type
        _check_water_heater(hpxml_bldg, [{ whtype: HPXML::WaterHeaterTypeStorage, fuel: HPXML::FuelTypeElectricity, setpoint: 125.0, location: HPXML::LocationBasementConditioned, tank_vol: 40, ef: 0.92 }])
        _check_hot_water_distribution(hpxml_bldg, disttype: HPXML::DHWDistTypeStandard, pipe_r: 0.0, pipe_l: 93.5)
      elsif [CalcType::RatedHome].include? calc_type
        _check_water_heater(hpxml_bldg, [{ whtype: HPXML::WaterHeaterTypeStorage, fuel: HPXML::FuelTypeElectricity, setpoint: 125.0, location: HPXML::LocationConditionedSpace, tank_vol: 40, uef: 0.94, fhr: 56.0 }])
        _check_hot_water_distribution(hpxml_bldg, disttype: HPXML::DHWDistTypeStandard, pipe_r: 0.0, pipe_l: 50)
      else
        _check_water_heater(hpxml_bldg, [{ whtype: HPXML::WaterHeaterTypeStorage, fuel: HPXML::FuelTypeElectricity, setpoint: 125.0, location: HPXML::LocationConditionedSpace, tank_vol: 40, ef: 0.92 }])
        _check_hot_water_distribution(hpxml_bldg, disttype: HPXML::DHWDistTypeStandard, pipe_r: 0.0, pipe_l: 89.28)
      end
    end
  end

  def test_water_heating_tank_elec_ef
    hpxml_name = 'base-dhw-tank-elec-ef.xml'

    _test_ruleset(hpxml_name).each do |(_run_type, calc_type), hpxml_bldg|
      if [CalcType::ReferenceHome, CalcType::ReferenceHome].include? calc_type
        _check_water_heater(hpxml_bldg, [{ whtype: HPXML::WaterHeaterTypeStorage, fuel: HPXML::FuelTypeElectricity, setpoint: 125.0, location: HPXML::LocationBasementConditioned, tank_vol: 40, ef: 0.92 }])
      elsif [CalcType::RatedHome].include? calc_type
        _check_water_heater(hpxml_bldg, [{ whtype: HPXML::WaterHeaterTypeStorage, fuel: HPXML::FuelTypeElectricity, setpoint: 125.0, location: HPXML::LocationConditionedSpace, tank_vol: 40, ef: 0.93 }])
      else
        _check_water_heater(hpxml_bldg, [{ whtype: HPXML::WaterHeaterTypeStorage, fuel: HPXML::FuelTypeElectricity, setpoint: 125.0, location: HPXML::LocationConditionedSpace, tank_vol: 40, ef: 0.92 }])
      end
    end
  end

  def test_water_heating_dwhr
    hpxml_name = 'base-dhw-dwhr.xml'

    _test_ruleset(hpxml_name).each do |(_run_type, calc_type), hpxml_bldg|
      if [CalcType::RatedHome].include? calc_type
        _check_drain_water_heat_recovery(hpxml_bldg, facilities_connected: HPXML::DWHRFacilitiesConnectedAll, equal_flow: true, efficiency: 0.55)
      else
        _check_drain_water_heat_recovery(hpxml_bldg)
      end
    end
  end

  def test_desuperheater
    hpxml_name = 'base-dhw-desuperheater.xml'

    _test_ruleset(hpxml_name).each do |(_run_type, calc_type), hpxml_bldg|
      if [CalcType::RatedHome].include? calc_type
        _check_desuperheater(hpxml_bldg, present: true)
      else
        _check_desuperheater(hpxml_bldg, present: false)
      end
    end
  end

  def test_water_heating_location_basement
    hpxml_name = 'base-foundation-unconditioned-basement.xml'

    _test_ruleset(hpxml_name).each do |(_run_type, calc_type), hpxml_bldg|
      if [CalcType::ReferenceHome, CalcType::ReferenceHome].include? calc_type
        _check_water_heater(hpxml_bldg, [{ whtype: HPXML::WaterHeaterTypeStorage, fuel: HPXML::FuelTypeElectricity, setpoint: 125.0, location: HPXML::LocationBasementUnconditioned, tank_vol: 40, ef: 0.9172 }])
        _check_hot_water_distribution(hpxml_bldg, disttype: HPXML::DHWDistTypeStandard, pipe_r: 0.0, pipe_l: 88.5)
      elsif [CalcType::RatedHome].include? calc_type
        _check_water_heater(hpxml_bldg, [{ whtype: HPXML::WaterHeaterTypeStorage, fuel: HPXML::FuelTypeElectricity, setpoint: 125.0, location: HPXML::LocationBasementUnconditioned, tank_vol: 40, uef: 0.94, fhr: 56.0 }])
        _check_hot_water_distribution(hpxml_bldg, disttype: HPXML::DHWDistTypeStandard, pipe_r: 0.0, pipe_l: 50)
      else
        _check_water_heater(hpxml_bldg, [{ whtype: HPXML::WaterHeaterTypeStorage, fuel: HPXML::FuelTypeElectricity, setpoint: 125.0, location: HPXML::LocationConditionedSpace, tank_vol: 40, ef: 0.9172 }])
        _check_hot_water_distribution(hpxml_bldg, disttype: HPXML::DHWDistTypeStandard, pipe_r: 0.0, pipe_l: 89.28)
      end
    end
  end

  def test_water_heating_low_flow_fixtures
    hpxml_name = 'base-dhw-low-flow-fixtures.xml'

    _test_ruleset(hpxml_name).each do |(_run_type, calc_type), hpxml_bldg|
      if [CalcType::ReferenceHome, CalcType::ReferenceHome].include? calc_type
        _check_water_fixtures(hpxml_bldg, low_flow_shower: false, low_flow_faucet: false)
      elsif [CalcType::RatedHome].include? calc_type
        _check_water_fixtures(hpxml_bldg, low_flow_shower: true, low_flow_faucet: true)
      else
        _check_water_fixtures(hpxml_bldg, low_flow_shower: false, low_flow_faucet: false)
      end
    end
  end

  def test_water_heating_recirc_demand
    hpxml_name = 'base-dhw-recirc-demand.xml'

    _test_ruleset(hpxml_name).each do |(_run_type, calc_type), hpxml_bldg|
      if [CalcType::ReferenceHome, CalcType::ReferenceHome].include? calc_type
        _check_hot_water_distribution(hpxml_bldg, disttype: HPXML::DHWDistTypeStandard, pipe_r: 0.0, pipe_l: 93.5)
      elsif [CalcType::RatedHome].include? calc_type
        _check_hot_water_distribution(hpxml_bldg, disttype: HPXML::DHWDistTypeRecirc, pipe_r: 3.0, recirc_control: HPXML::DHWRecircControlTypeSensor, recirc_loop_l: 50, recirc_branch_l: 50, recirc_pump_power: 50)
      else
        _check_hot_water_distribution(hpxml_bldg, disttype: HPXML::DHWDistTypeStandard, pipe_r: 0.0, pipe_l: 89.28)
      end
    end
  end

  def test_water_heating_tank_gas
    # Create derivative file for testing
    hpxml_name = 'base-dhw-tank-gas-ef.xml'
    hpxml = HPXML.new(hpxml_path: File.join(@root_path, 'workflow', 'sample_files', hpxml_name))
    hpxml_bldg = hpxml.buildings[0]
    hpxml_bldg.water_heating_systems[0].tank_volume = 50.0
    hpxml_bldg.water_heating_systems[0].energy_factor = nil
    hpxml_bldg.water_heating_systems[0].uniform_energy_factor = 0.59
    hpxml_bldg.water_heating_systems[0].first_hour_rating = 55.0
    hpxml_name = File.basename(@tmp_hpxml_path)
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)

    _test_ruleset(hpxml_name).each do |(run_type, calc_type), hpxml_bldg|
      if [CalcType::ReferenceHome].include? calc_type
        if run_type == RunType::CO2e # All-electric
          _check_water_heater(hpxml_bldg, [{ whtype: HPXML::WaterHeaterTypeStorage, fuel: HPXML::FuelTypeElectricity, setpoint: 125.0, location: HPXML::LocationBasementConditioned, tank_vol: 50, ef: 0.9 }])
        else
          _check_water_heater(hpxml_bldg, [{ whtype: HPXML::WaterHeaterTypeStorage, fuel: HPXML::FuelTypeNaturalGas, setpoint: 125.0, location: HPXML::LocationBasementConditioned, tank_vol: 50, ef: 0.575 }])
        end
      elsif [CalcType::RatedHome].include? calc_type
        _check_water_heater(hpxml_bldg, [{ whtype: HPXML::WaterHeaterTypeStorage, fuel: HPXML::FuelTypeNaturalGas, setpoint: 125.0, location: HPXML::LocationConditionedSpace, tank_vol: 50, uef: 0.59, fhr: 55.0 }])
      else
        _check_water_heater(hpxml_bldg, [{ whtype: HPXML::WaterHeaterTypeStorage, fuel: HPXML::FuelTypeNaturalGas, setpoint: 125.0, location: HPXML::LocationConditionedSpace, tank_vol: 50, ef: 0.575 }])
      end
    end
  end

  def test_water_heating_tank_gas_ef
    hpxml_name = 'base-dhw-tank-gas-ef.xml'

    _test_ruleset(hpxml_name).each do |(run_type, calc_type), hpxml_bldg|
      if [CalcType::ReferenceHome].include? calc_type
        if run_type == RunType::CO2e # All-electric
          _check_water_heater(hpxml_bldg, [{ whtype: HPXML::WaterHeaterTypeStorage, fuel: HPXML::FuelTypeElectricity, setpoint: 125.0, location: HPXML::LocationBasementConditioned, tank_vol: 50, ef: 0.9 }])
        else
          _check_water_heater(hpxml_bldg, [{ whtype: HPXML::WaterHeaterTypeStorage, fuel: HPXML::FuelTypeNaturalGas, setpoint: 125.0, location: HPXML::LocationBasementConditioned, tank_vol: 50, ef: 0.58 }])
        end
      elsif [CalcType::RatedHome].include? calc_type
        _check_water_heater(hpxml_bldg, [{ whtype: HPXML::WaterHeaterTypeStorage, fuel: HPXML::FuelTypeNaturalGas, setpoint: 125.0, location: HPXML::LocationConditionedSpace, tank_vol: 50, ef: 0.59 }])
      else
        _check_water_heater(hpxml_bldg, [{ whtype: HPXML::WaterHeaterTypeStorage, fuel: HPXML::FuelTypeNaturalGas, setpoint: 125.0, location: HPXML::LocationConditionedSpace, tank_vol: 50, ef: 0.58 }])
      end
    end
  end

  def test_water_heating_jacket_insulation
    hpxml_name = 'base-dhw-jacket-gas.xml'

    _test_ruleset(hpxml_name).each do |(run_type, calc_type), hpxml_bldg|
      if [CalcType::ReferenceHome].include? calc_type
        if run_type == RunType::CO2e # All-electric
          _check_water_heater(hpxml_bldg, [{ whtype: HPXML::WaterHeaterTypeStorage, fuel: HPXML::FuelTypeElectricity, setpoint: 125.0, location: HPXML::LocationBasementConditioned, tank_vol: 30, ef: 0.93 }])
        else
          _check_water_heater(hpxml_bldg, [{ whtype: HPXML::WaterHeaterTypeStorage, fuel: HPXML::FuelTypeNaturalGas, setpoint: 125.0, location: HPXML::LocationBasementConditioned, tank_vol: 30, ef: 0.61 }])
        end
      elsif [CalcType::RatedHome].include? calc_type
        _check_water_heater(hpxml_bldg, [{ whtype: HPXML::WaterHeaterTypeStorage, fuel: HPXML::FuelTypeNaturalGas, setpoint: 125.0, location: HPXML::LocationConditionedSpace, tank_vol: 30, uef: 0.60, fhr: 56.0, jacket_r: 10 }])
      else
        _check_water_heater(hpxml_bldg, [{ whtype: HPXML::WaterHeaterTypeStorage, fuel: HPXML::FuelTypeNaturalGas, setpoint: 125.0, location: HPXML::LocationConditionedSpace, tank_vol: 30, ef: 0.61 }])
      end
    end
  end

  def test_water_heating_tank_heat_pump
    # Create derivative file for testing
    hpxml_name = 'base-dhw-tank-heat-pump-ef.xml'
    hpxml = HPXML.new(hpxml_path: File.join(@root_path, 'workflow', 'sample_files', hpxml_name))
    hpxml_bldg = hpxml.buildings[0]
    hpxml_bldg.water_heating_systems[0].energy_factor = nil
    hpxml_bldg.water_heating_systems[0].tank_volume = 80.0
    hpxml_bldg.water_heating_systems[0].uniform_energy_factor = 3.75
    hpxml_bldg.water_heating_systems[0].first_hour_rating = 56.0
    hpxml_name = File.basename(@tmp_hpxml_path)
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)

    _test_ruleset(hpxml_name).each do |(_run_type, calc_type), hpxml_bldg|
      if [CalcType::ReferenceHome, CalcType::ReferenceHome].include? calc_type
        _check_water_heater(hpxml_bldg, [{ whtype: HPXML::WaterHeaterTypeStorage, fuel: HPXML::FuelTypeElectricity, setpoint: 125.0, location: HPXML::LocationBasementConditioned, tank_vol: 80, ef: 0.8644 }])
      elsif [CalcType::RatedHome].include? calc_type
        _check_water_heater(hpxml_bldg, [{ whtype: HPXML::WaterHeaterTypeHeatPump, fuel: HPXML::FuelTypeElectricity, setpoint: 125.0, location: HPXML::LocationConditionedSpace, tank_vol: 80, uef: 3.75, fhr: 56 }])
      else
        _check_water_heater(hpxml_bldg, [{ whtype: HPXML::WaterHeaterTypeStorage, fuel: HPXML::FuelTypeElectricity, setpoint: 125.0, location: HPXML::LocationConditionedSpace, tank_vol: 80, ef: 0.8644 }])
      end
    end
  end

  def test_water_heating_tank_heat_pump_ef
    hpxml_name = 'base-dhw-tank-heat-pump-ef.xml'

    _test_ruleset(hpxml_name).each do |(_run_type, calc_type), hpxml_bldg|
      if [CalcType::ReferenceHome, CalcType::ReferenceHome].include? calc_type
        _check_water_heater(hpxml_bldg, [{ whtype: HPXML::WaterHeaterTypeStorage, fuel: HPXML::FuelTypeElectricity, setpoint: 125.0, location: HPXML::LocationBasementConditioned, tank_vol: 80, ef: 0.86 }])
      elsif [CalcType::RatedHome].include? calc_type
        _check_water_heater(hpxml_bldg, [{ whtype: HPXML::WaterHeaterTypeHeatPump, fuel: HPXML::FuelTypeElectricity, setpoint: 125.0, location: HPXML::LocationConditionedSpace, tank_vol: 80, ef: 3.1 }])
      else
        _check_water_heater(hpxml_bldg, [{ whtype: HPXML::WaterHeaterTypeStorage, fuel: HPXML::FuelTypeElectricity, setpoint: 125.0, location: HPXML::LocationConditionedSpace, tank_vol: 80, ef: 0.86 }])
      end
    end
  end

  def test_water_heating_tankless_electric
    # Create derivative file for testing
    hpxml_name = 'base-dhw-tankless-electric-ef.xml'
    hpxml = HPXML.new(hpxml_path: File.join(@root_path, 'workflow', 'sample_files', hpxml_name))
    hpxml_bldg = hpxml.buildings[0]
    hpxml_bldg.water_heating_systems[0].energy_factor = nil
    hpxml_bldg.water_heating_systems[0].uniform_energy_factor = 0.98
    hpxml_name = File.basename(@tmp_hpxml_path)
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)

    _test_ruleset(hpxml_name).each do |(_run_type, calc_type), hpxml_bldg|
      if [CalcType::ReferenceHome, CalcType::ReferenceHome].include? calc_type
        _check_water_heater(hpxml_bldg, [{ whtype: HPXML::WaterHeaterTypeStorage, fuel: HPXML::FuelTypeElectricity, setpoint: 125.0, location: HPXML::LocationBasementConditioned, tank_vol: 40, ef: 0.9172 }])
      elsif [CalcType::RatedHome].include? calc_type
        _check_water_heater(hpxml_bldg, [{ whtype: HPXML::WaterHeaterTypeTankless, fuel: HPXML::FuelTypeElectricity, setpoint: 125.0, location: HPXML::LocationConditionedSpace, uef: 0.98 }])
      else
        _check_water_heater(hpxml_bldg, [{ whtype: HPXML::WaterHeaterTypeStorage, fuel: HPXML::FuelTypeElectricity, setpoint: 125.0, location: HPXML::LocationConditionedSpace, tank_vol: 40, ef: 0.9172, }])
      end
    end
  end

  def test_water_heating_tankless_electric_ef
    hpxml_name = 'base-dhw-tankless-electric-ef.xml'

    _test_ruleset(hpxml_name).each do |(_run_type, calc_type), hpxml_bldg|
      if [CalcType::ReferenceHome, CalcType::ReferenceHome].include? calc_type
        _check_water_heater(hpxml_bldg, [{ whtype: HPXML::WaterHeaterTypeStorage, fuel: HPXML::FuelTypeElectricity, setpoint: 125.0, location: HPXML::LocationBasementConditioned, tank_vol: 40, ef: 0.9172 }])
      elsif [CalcType::RatedHome].include? calc_type
        _check_water_heater(hpxml_bldg, [{ whtype: HPXML::WaterHeaterTypeTankless, fuel: HPXML::FuelTypeElectricity, setpoint: 125.0, location: HPXML::LocationConditionedSpace, ef: 0.96 }])
      else
        _check_water_heater(hpxml_bldg, [{ whtype: HPXML::WaterHeaterTypeStorage, fuel: HPXML::FuelTypeElectricity, setpoint: 125.0, location: HPXML::LocationConditionedSpace, tank_vol: 40, ef: 0.9172 }])
      end
    end
  end

  def test_water_heating_tankless_gas
    # Create derivative file for testing
    hpxml_name = 'base-dhw-tankless-gas-ef.xml'
    hpxml = HPXML.new(hpxml_path: File.join(@root_path, 'workflow', 'sample_files', hpxml_name))
    hpxml_bldg = hpxml.buildings[0]
    hpxml_bldg.water_heating_systems[0].energy_factor = nil
    hpxml_bldg.water_heating_systems[0].uniform_energy_factor = 0.93
    hpxml_name = File.basename(@tmp_hpxml_path)
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)

    _test_ruleset(hpxml_name).each do |(run_type, calc_type), hpxml_bldg|
      if [CalcType::ReferenceHome].include? calc_type
        if run_type == RunType::CO2e # All-electric
          _check_water_heater(hpxml_bldg, [{ whtype: HPXML::WaterHeaterTypeStorage, fuel: HPXML::FuelTypeElectricity, setpoint: 125.0, location: HPXML::LocationBasementConditioned, tank_vol: 40, ef: 0.92 }])
        else
          _check_water_heater(hpxml_bldg, [{ whtype: HPXML::WaterHeaterTypeStorage, fuel: HPXML::FuelTypeNaturalGas, setpoint: 125.0, location: HPXML::LocationBasementConditioned, tank_vol: 40, ef: 0.594 }])
        end
      elsif [CalcType::RatedHome].include? calc_type
        _check_water_heater(hpxml_bldg, [{ whtype: HPXML::WaterHeaterTypeTankless, fuel: HPXML::FuelTypeNaturalGas, setpoint: 125.0, location: HPXML::LocationConditionedSpace, uef: 0.93 }])
      else
        _check_water_heater(hpxml_bldg, [{ whtype: HPXML::WaterHeaterTypeStorage, fuel: HPXML::FuelTypeNaturalGas, setpoint: 125.0, location: HPXML::LocationConditionedSpace, tank_vol: 40, ef: 0.594 }])
      end
    end
  end

  def test_water_heating_tankless_gas_ef
    hpxml_name = 'base-dhw-tankless-gas-ef.xml'

    _test_ruleset(hpxml_name).each do |(run_type, calc_type), hpxml_bldg|
      if [CalcType::ReferenceHome].include? calc_type
        if run_type == RunType::CO2e # All-electric
          _check_water_heater(hpxml_bldg, [{ whtype: HPXML::WaterHeaterTypeStorage, fuel: HPXML::FuelTypeElectricity, setpoint: 125.0, location: HPXML::LocationBasementConditioned, tank_vol: 40, ef: 0.92 }])
        else
          _check_water_heater(hpxml_bldg, [{ whtype: HPXML::WaterHeaterTypeStorage, fuel: HPXML::FuelTypeNaturalGas, setpoint: 125.0, location: HPXML::LocationBasementConditioned, tank_vol: 40, ef: 0.594 }])
        end
      elsif [CalcType::RatedHome].include? calc_type
        _check_water_heater(hpxml_bldg, [{ whtype: HPXML::WaterHeaterTypeTankless, fuel: HPXML::FuelTypeNaturalGas, setpoint: 125.0, location: HPXML::LocationConditionedSpace, ef: 0.95 }])
      else
        _check_water_heater(hpxml_bldg, [{ whtype: HPXML::WaterHeaterTypeStorage, fuel: HPXML::FuelTypeNaturalGas, setpoint: 125.0, location: HPXML::LocationConditionedSpace, tank_vol: 40, ef: 0.594 }])
      end
    end
  end

  def test_multiple_water_heating
    hpxml_name = 'base-dhw-multiple.xml'

    _test_ruleset(hpxml_name).each do |(_run_type, calc_type), hpxml_bldg|
      if [CalcType::ReferenceHome, CalcType::ReferenceHome].include? calc_type
        _check_water_heater(hpxml_bldg, [{ whtype: HPXML::WaterHeaterTypeStorage, fuel: HPXML::FuelTypeElectricity, setpoint: 125.0, location: HPXML::LocationBasementConditioned, tank_vol: 40, ef: 0.9172 }])
      elsif [CalcType::RatedHome].include? calc_type
        _check_water_heater(hpxml_bldg, [{ whtype: HPXML::WaterHeaterTypeStorage, fuel: HPXML::FuelTypeElectricity, frac_load: 0.2, setpoint: 125.0, location: HPXML::LocationConditionedSpace, tank_vol: 40, uef: 0.94, fhr: 56.0 },
                                         { whtype: HPXML::WaterHeaterTypeStorage, fuel: HPXML::FuelTypeNaturalGas, frac_load: 0.2, setpoint: 125.0, location: HPXML::LocationConditionedSpace, tank_vol: 50, ef: 0.59 },
                                         { whtype: HPXML::WaterHeaterTypeHeatPump, fuel: HPXML::FuelTypeElectricity, frac_load: 0.2, setpoint: 125.0, location: HPXML::LocationConditionedSpace, tank_vol: 80, ef: 2.3 },
                                         { whtype: HPXML::WaterHeaterTypeTankless, fuel: HPXML::FuelTypeElectricity, frac_load: 0.2, setpoint: 125.0, location: HPXML::LocationConditionedSpace, ef: 0.99 },
                                         { whtype: HPXML::WaterHeaterTypeTankless, fuel: HPXML::FuelTypeNaturalGas, frac_load: 0.1, setpoint: 125.0, location: HPXML::LocationConditionedSpace, ef: 0.82 },
                                         { whtype: HPXML::WaterHeaterTypeCombiStorage, frac_load: 0.1, setpoint: 125.0, location: HPXML::LocationConditionedSpace, tank_vol: 50, standby_loss_value: 0.843 }])
      else
        _check_water_heater(hpxml_bldg, [{ whtype: HPXML::WaterHeaterTypeStorage, fuel: HPXML::FuelTypeElectricity, setpoint: 125.0, location: HPXML::LocationConditionedSpace, tank_vol: 40, ef: 0.9172 }])
      end
    end

    # Test tie between water heating fuel types; should choose fossil fuel
    hpxml = HPXML.new(hpxml_path: File.join(@root_path, 'workflow', 'sample_files', hpxml_name))
    hpxml_bldg = hpxml.buildings[0]
    hpxml_bldg.water_heating_systems.each do |w|
      w.fraction_dhw_load_served = 0.0
    end
    hpxml_bldg.water_heating_systems.find { |w| w.fuel_type == HPXML::FuelTypeElectricity }.fraction_dhw_load_served = 0.5
    hpxml_bldg.water_heating_systems.find { |w| w.fuel_type == HPXML::FuelTypeNaturalGas }.fraction_dhw_load_served = 0.5
    hpxml_name = File.basename(@tmp_hpxml_path)
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)

    _test_ruleset(hpxml_name).each do |(run_type, calc_type), hpxml_bldg|
      next unless run_type == RunType::ERI && calc_type == CalcType::ReferenceHome

      assert_equal(HPXML::FuelTypeNaturalGas, hpxml_bldg.water_heating_systems[0].fuel_type)
    end
  end

  def test_indirect_water_heating
    hpxml_name = 'base-dhw-indirect-standbyloss.xml'

    _test_ruleset(hpxml_name).each do |(run_type, calc_type), hpxml_bldg|
      if [CalcType::ReferenceHome].include? calc_type
        if run_type == RunType::CO2e # All-electric
          _check_water_heater(hpxml_bldg, [{ whtype: HPXML::WaterHeaterTypeStorage, fuel: HPXML::FuelTypeElectricity, setpoint: 125.0, location: HPXML::LocationBasementConditioned, tank_vol: 50, ef: 0.9 }])
        else
          _check_water_heater(hpxml_bldg, [{ whtype: HPXML::WaterHeaterTypeStorage, fuel: HPXML::FuelTypeNaturalGas, setpoint: 125.0, location: HPXML::LocationBasementConditioned, tank_vol: 50, ef: 0.575 }])
        end
      elsif [CalcType::RatedHome].include? calc_type
        _check_water_heater(hpxml_bldg, [{ whtype: HPXML::WaterHeaterTypeCombiStorage, setpoint: 125.0, location: HPXML::LocationConditionedSpace, tank_vol: 50, standby_loss_value: 1.0 }])
      else
        _check_water_heater(hpxml_bldg, [{ whtype: HPXML::WaterHeaterTypeStorage, fuel: HPXML::FuelTypeNaturalGas, setpoint: 125.0, location: HPXML::LocationConditionedSpace, tank_vol: 50, ef: 0.575 }])
      end
    end
  end

  def test_indirect_tankless_coil
    hpxml_name = 'base-dhw-combi-tankless.xml'

    _test_ruleset(hpxml_name).each do |(run_type, calc_type), hpxml_bldg|
      if [CalcType::ReferenceHome].include? calc_type
        if run_type == RunType::CO2e # All-electric
          _check_water_heater(hpxml_bldg, [{ whtype: HPXML::WaterHeaterTypeStorage, fuel: HPXML::FuelTypeElectricity, setpoint: 125.0, location: HPXML::LocationBasementConditioned, tank_vol: 40, ef: 0.92 }])
        else
          _check_water_heater(hpxml_bldg, [{ whtype: HPXML::WaterHeaterTypeStorage, fuel: HPXML::FuelTypeNaturalGas, setpoint: 125.0, location: HPXML::LocationBasementConditioned, tank_vol: 40, ef: 0.594 }])
        end
      elsif [CalcType::RatedHome].include? calc_type
        _check_water_heater(hpxml_bldg, [{ whtype: HPXML::WaterHeaterTypeCombiTankless, setpoint: 125.0, location: HPXML::LocationConditionedSpace }])
      else
        _check_water_heater(hpxml_bldg, [{ whtype: HPXML::WaterHeaterTypeStorage, fuel: HPXML::FuelTypeNaturalGas, setpoint: 125.0, location: HPXML::LocationConditionedSpace, tank_vol: 40, ef: 0.594 }])
      end
    end
  end

  def test_water_heating_none
    hpxml_name = 'base-dhw-none.xml'

    _test_ruleset(hpxml_name).each do |(run_type, calc_type), hpxml_bldg|
      if [CalcType::ReferenceHome].include? calc_type
        if run_type == RunType::CO2e # All-electric
          _check_water_heater(hpxml_bldg, [{ whtype: HPXML::WaterHeaterTypeStorage, fuel: HPXML::FuelTypeElectricity, setpoint: 125.0, location: HPXML::LocationConditionedSpace, tank_vol: 40, ef: 0.92 }])
        else
          _check_water_heater(hpxml_bldg, [{ whtype: HPXML::WaterHeaterTypeStorage, fuel: HPXML::FuelTypeNaturalGas, setpoint: 125.0, location: HPXML::LocationConditionedSpace, tank_vol: 40, ef: 0.594 }])
        end
      elsif [CalcType::RatedHome].include? calc_type
        _check_water_heater(hpxml_bldg, [{ whtype: HPXML::WaterHeaterTypeStorage, fuel: HPXML::FuelTypeNaturalGas, setpoint: 125.0, location: HPXML::LocationConditionedSpace, tank_vol: 40, ef: 0.594 }])
      else
        _check_water_heater(hpxml_bldg, [{ whtype: HPXML::WaterHeaterTypeStorage, fuel: HPXML::FuelTypeNaturalGas, setpoint: 125.0, location: HPXML::LocationConditionedSpace, tank_vol: 40, ef: 0.594 }])
      end
      if [CalcType::ReferenceHome, CalcType::ReferenceHome].include? calc_type
        _check_hot_water_distribution(hpxml_bldg, disttype: HPXML::DHWDistTypeStandard, pipe_r: 0.0, pipe_l: 93.5)
      elsif [CalcType::RatedHome].include? calc_type
        _check_hot_water_distribution(hpxml_bldg, disttype: HPXML::DHWDistTypeStandard, pipe_r: 0.0, pipe_l: 93.5)
      else
        _check_hot_water_distribution(hpxml_bldg, disttype: HPXML::DHWDistTypeStandard, pipe_r: 0.0, pipe_l: 89.28)
      end
    end

    # Test tie between space heating fuel types
    hpxml = HPXML.new(hpxml_path: File.join(@root_path, 'workflow', 'sample_files', hpxml_name))
    hpxml_bldg = hpxml.buildings[0]
    hpxml_bldg.heating_systems[0].fraction_heat_load_served = 0.15
    { HPXML::FuelTypeOil => 0.35, HPXML::FuelTypeElectricity => 0.5 }.each do |fuel, frac|
      hpxml_bldg.heating_systems.add(id: "HeatingSystem#{fuel.gsub(' ', '')}",
                                     heating_system_type: HPXML::HVACTypeStove,
                                     heating_system_fuel: fuel,
                                     heating_capacity: 999,
                                     heating_efficiency_percent: 0.8,
                                     fraction_heat_load_served: frac)
    end
    hpxml_name = File.basename(@tmp_hpxml_path)
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)

    _test_ruleset(hpxml_name).each do |(_run_type, calc_type), hpxml_bldg|
      if calc_type == CalcType::RatedHome
        assert_equal(HPXML::FuelTypeOil, hpxml_bldg.water_heating_systems[0].fuel_type)
      end
    end
  end

  def test_water_heating_pre_addendum_a
    hpxml_name = 'base.xml'

    _test_ruleset(hpxml_name, '2014').each do |(_run_type, calc_type), hpxml_bldg|
      if [CalcType::ReferenceHome, CalcType::ReferenceHome].include? calc_type
        _check_water_heater(hpxml_bldg, [{ whtype: HPXML::WaterHeaterTypeStorage, fuel: HPXML::FuelTypeElectricity, setpoint: 120.0, location: HPXML::LocationConditionedSpace, tank_vol: 40, ef: 0.9172 }])
      elsif [CalcType::RatedHome].include? calc_type
        _check_water_heater(hpxml_bldg, [{ whtype: HPXML::WaterHeaterTypeStorage, fuel: HPXML::FuelTypeElectricity, setpoint: 120.0, location: HPXML::LocationConditionedSpace, tank_vol: 40, uef: 0.94, fhr: 56.0 }])
      else
        _check_water_heater(hpxml_bldg, [{ whtype: HPXML::WaterHeaterTypeStorage, fuel: HPXML::FuelTypeElectricity, setpoint: 120.0, location: HPXML::LocationConditionedSpace, tank_vol: 40, ef: 0.9172 }])
      end
    end
  end

  def test_water_heating_shared_multiple_units_recirc
    hpxml_name = 'base-bldgtype-mf-unit-shared-water-heater-recirc.xml'

    _test_ruleset(hpxml_name).each do |(run_type, calc_type), hpxml_bldg|
      if [CalcType::ReferenceHome].include? calc_type
        if run_type == RunType::CO2e # All-electric
          _check_water_heater(hpxml_bldg, [{ whtype: HPXML::WaterHeaterTypeStorage, fuel: HPXML::FuelTypeElectricity, setpoint: 125.0, location: HPXML::LocationConditionedSpace, tank_vol: 40, ef: 0.92 }])
        else
          _check_water_heater(hpxml_bldg, [{ whtype: HPXML::WaterHeaterTypeStorage, fuel: HPXML::FuelTypeNaturalGas, setpoint: 125.0, location: HPXML::LocationConditionedSpace, tank_vol: 40, ef: 0.59 }])
        end
      elsif [CalcType::RatedHome].include? calc_type
        _check_water_heater(hpxml_bldg, [{ whtype: HPXML::WaterHeaterTypeStorage, fuel: HPXML::FuelTypeNaturalGas, setpoint: 125.0, location: HPXML::LocationConditionedSpace, tank_vol: 120, uef: 0.60, fhr: 56.0, n_bedrooms_served: 18 }])
      else
        _check_water_heater(hpxml_bldg, [{ whtype: HPXML::WaterHeaterTypeStorage, fuel: HPXML::FuelTypeNaturalGas, setpoint: 125.0, location: HPXML::LocationConditionedSpace, tank_vol: 40, ef: 0.59 }])
      end
      if [CalcType::ReferenceHome, CalcType::ReferenceHome].include? calc_type
        _check_hot_water_distribution(hpxml_bldg, disttype: HPXML::DHWDistTypeStandard, pipe_r: 0.0, pipe_l: 70.0)
      elsif [CalcType::RatedHome].include? calc_type
        _check_hot_water_distribution(hpxml_bldg, disttype: HPXML::DHWDistTypeStandard, pipe_r: 0.0, pipe_l: 50, shared_recirc_power: 220, shared_recirc_num_bedrooms_served: 18, shared_recirc_control_type: HPXML::DHWRecircControlTypeTimer)
      else
        _check_hot_water_distribution(hpxml_bldg, disttype: HPXML::DHWDistTypeStandard, pipe_r: 0.0, pipe_l: 89.28)
      end
    end
  end

  def test_water_heating_shared_laundry_room
    hpxml_name = 'base-bldgtype-mf-unit-shared-laundry-room.xml'

    _test_ruleset(hpxml_name).each do |(run_type, calc_type), hpxml_bldg|
      if [CalcType::ReferenceHome].include? calc_type
        if run_type == RunType::CO2e # All-electric
          _check_water_heater(hpxml_bldg, [{ whtype: HPXML::WaterHeaterTypeStorage, fuel: HPXML::FuelTypeElectricity, setpoint: 125.0, location: HPXML::LocationConditionedSpace, tank_vol: 40, ef: 0.92 }])
        else
          _check_water_heater(hpxml_bldg, [{ whtype: HPXML::WaterHeaterTypeStorage, fuel: HPXML::FuelTypeNaturalGas, setpoint: 125.0, location: HPXML::LocationConditionedSpace, tank_vol: 40, ef: 0.59 }])
        end
      elsif [CalcType::RatedHome].include? calc_type
        _check_water_heater(hpxml_bldg, [{ whtype: HPXML::WaterHeaterTypeStorage, fuel: HPXML::FuelTypeNaturalGas, setpoint: 125.0, location: HPXML::LocationConditionedSpace, tank_vol: 120, ef: 0.59, n_bedrooms_served: 18 }])
      else
        _check_water_heater(hpxml_bldg, [{ whtype: HPXML::WaterHeaterTypeStorage, fuel: HPXML::FuelTypeNaturalGas, setpoint: 125.0, location: HPXML::LocationConditionedSpace, tank_vol: 40, ef: 0.59 }])
      end
      if [CalcType::ReferenceHome, CalcType::ReferenceHome].include? calc_type
        _check_hot_water_distribution(hpxml_bldg, disttype: HPXML::DHWDistTypeStandard, pipe_r: 0.0, pipe_l: 70.0)
      elsif [CalcType::RatedHome].include? calc_type
        _check_hot_water_distribution(hpxml_bldg, disttype: HPXML::DHWDistTypeStandard, pipe_r: 0.0, pipe_l: 50)
      else
        _check_hot_water_distribution(hpxml_bldg, disttype: HPXML::DHWDistTypeStandard, pipe_r: 0.0, pipe_l: 89.28)
      end
    end
  end

  def test_water_heating_solar_simple
    hpxml_name = 'base-dhw-solar-fraction.xml'

    _test_ruleset(hpxml_name).each do |(_run_type, calc_type), hpxml_bldg|
      if [CalcType::RatedHome].include? calc_type
        _check_solar_thermal_system(hpxml_bldg, present: true)
      else
        _check_solar_thermal_system(hpxml_bldg, present: false)
      end
    end
  end

  def test_water_heating_solar_detailed
    hpxml_name = 'base-dhw-solar-indirect-flat-plate.xml'

    _test_ruleset(hpxml_name).each do |(_run_type, calc_type), hpxml_bldg|
      if [CalcType::RatedHome].include? calc_type
        _check_solar_thermal_system(hpxml_bldg, present: true)
      else
        _check_solar_thermal_system(hpxml_bldg, present: false)
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

  def _check_water_heater(hpxml_bldg, all_expected_values = [])
    assert_equal(all_expected_values.size, hpxml_bldg.water_heating_systems.size)
    hpxml_bldg.water_heating_systems.each_with_index do |water_heater, idx|
      expected_values = all_expected_values[idx]
      assert_equal(expected_values[:whtype], water_heater.water_heater_type)
      assert_equal(expected_values[:location], water_heater.location)
      if expected_values[:fuel].nil?
        assert_nil(water_heater.fuel_type)
      else
        assert_equal(expected_values[:fuel], water_heater.fuel_type)
      end
      if expected_values[:tank_vol].nil?
        assert_nil(water_heater.tank_volume)
      else
        assert_in_epsilon(expected_values[:tank_vol], water_heater.tank_volume, 0.01)
      end
      if expected_values[:ef].nil?
        assert_nil(water_heater.energy_factor)
      else
        assert_in_epsilon(expected_values[:ef], water_heater.energy_factor, 0.01)
      end
      if expected_values[:jacket_r].nil?
        assert_nil(water_heater.jacket_r_value)
      else
        assert_in_epsilon(expected_values[:jacket_r], water_heater.jacket_r_value, 0.01)
      end
      assert_in_epsilon(expected_values[:setpoint], water_heater.temperature, 0.01)
      if expected_values[:standby_loss_value].nil?
        assert_nil(water_heater.standby_loss_value)
      else
        assert_equal(HPXML::UnitsDegFPerHour, water_heater.standby_loss_units)
        assert_equal(expected_values[:standby_loss_value], water_heater.standby_loss_value)
      end
      if expected_values[:whtype] == HPXML::WaterHeaterTypeTankless
        if not expected_values[:uef].nil?
          assert_equal(0.94, water_heater.performance_adjustment)
        else
          assert_equal(0.92, water_heater.performance_adjustment)
        end
      else
        assert_equal(1.0, water_heater.performance_adjustment)
      end
      if water_heater.number_of_bedrooms_served.nil?
        assert_nil(expected_values[:n_bedrooms_served])
      else
        assert_equal(expected_values[:n_bedrooms_served], water_heater.number_of_bedrooms_served)
      end
      frac_load = expected_values[:frac_load].nil? ? 1.0 : expected_values[:frac_load]
      assert_equal(frac_load, water_heater.fraction_dhw_load_served)
      if expected_values[:uef].nil?
        assert_nil(water_heater.uniform_energy_factor)
      else
        assert_equal(expected_values[:uef], water_heater.uniform_energy_factor)
      end
      if expected_values[:fhr].nil?
        assert_nil(water_heater.first_hour_rating)
      else
        assert_equal(expected_values[:fhr], water_heater.first_hour_rating)
      end
    end
  end

  def _check_hot_water_distribution(hpxml_bldg, disttype:, pipe_r:, pipe_l: nil, recirc_control: nil, recirc_loop_l: nil, recirc_branch_l: nil, recirc_pump_power: nil,
                                    shared_recirc_power: nil, shared_recirc_num_bedrooms_served: nil, shared_recirc_control_type: nil)
    assert_equal(1, hpxml_bldg.hot_water_distributions.size)
    hot_water_distribution = hpxml_bldg.hot_water_distributions[0]
    assert_equal(disttype, hot_water_distribution.system_type)
    assert_in_epsilon(pipe_r, hot_water_distribution.pipe_r_value, 0.01)
    if pipe_l.nil?
      assert_nil(hot_water_distribution.standard_piping_length)
    else
      assert_in_epsilon(pipe_l, hot_water_distribution.standard_piping_length, 0.01)
    end
    if recirc_control.nil?
      assert_nil(hot_water_distribution.recirculation_control_type)
    else
      assert_equal(recirc_control, hot_water_distribution.recirculation_control_type)
    end
    if recirc_loop_l.nil?
      assert_nil(hot_water_distribution.recirculation_piping_loop_length)
    else
      assert_in_epsilon(recirc_loop_l, hot_water_distribution.recirculation_piping_loop_length, 0.01)
    end
    if recirc_branch_l.nil?
      assert_nil(hot_water_distribution.recirculation_branch_piping_length)
    else
      assert_in_epsilon(recirc_branch_l, hot_water_distribution.recirculation_branch_piping_length, 0.01)
    end
    if recirc_pump_power.nil?
      assert_nil(hot_water_distribution.recirculation_pump_power)
    else
      assert_in_epsilon(recirc_pump_power, hot_water_distribution.recirculation_pump_power, 0.01)
    end
    if shared_recirc_power.nil?
      assert_nil(hot_water_distribution.shared_recirculation_pump_power)
    else
      assert_equal(shared_recirc_power, hot_water_distribution.shared_recirculation_pump_power)
    end
    if shared_recirc_num_bedrooms_served.nil?
      assert_nil(hot_water_distribution.shared_recirculation_number_of_bedrooms_served)
    else
      assert_equal(shared_recirc_num_bedrooms_served, hot_water_distribution.shared_recirculation_number_of_bedrooms_served)
    end
    if shared_recirc_control_type.nil?
      assert_nil(hot_water_distribution.shared_recirculation_control_type)
    else
      assert_equal(shared_recirc_control_type, hot_water_distribution.shared_recirculation_control_type)
    end

    if hot_water_distribution.system_type == HPXML::DHWDistTypeRecirc || hot_water_distribution.has_shared_recirculation
      recirc_control_type = hot_water_distribution.has_shared_recirculation ? hot_water_distribution.shared_recirculation_control_type : hot_water_distribution.recirculation_control_type
      if [HPXML::DHWRecircControlTypeNone, HPXML::DHWRecircControlTypeTimer].include?(recirc_control_type)
        assert_equal('0.042, 0.042, 0.042, 0.042, 0.042, 0.042, 0.042, 0.042, 0.042, 0.042, 0.042, 0.042, 0.042, 0.042, 0.042, 0.042, 0.042, 0.042, 0.042, 0.042, 0.042, 0.042, 0.042, 0.042', hot_water_distribution.recirculation_pump_weekday_fractions)
        assert_equal('0.042, 0.042, 0.042, 0.042, 0.042, 0.042, 0.042, 0.042, 0.042, 0.042, 0.042, 0.042, 0.042, 0.042, 0.042, 0.042, 0.042, 0.042, 0.042, 0.042, 0.042, 0.042, 0.042, 0.042', hot_water_distribution.recirculation_pump_weekend_fractions)
      elsif [HPXML::DHWRecircControlTypeSensor, HPXML::DHWRecircControlTypeManual].include?(recirc_control_type)
        assert_equal('0.012, 0.006, 0.004, 0.005, 0.010, 0.034, 0.078, 0.086, 0.080, 0.067, 0.056, 0.047, 0.040, 0.035, 0.033, 0.031, 0.038, 0.051, 0.060, 0.060, 0.055, 0.048, 0.038, 0.026', hot_water_distribution.recirculation_pump_weekday_fractions)
        assert_equal('0.012, 0.006, 0.004, 0.005, 0.010, 0.034, 0.078, 0.086, 0.080, 0.067, 0.056, 0.047, 0.040, 0.035, 0.033, 0.031, 0.038, 0.051, 0.060, 0.060, 0.055, 0.048, 0.038, 0.026', hot_water_distribution.recirculation_pump_weekend_fractions)
      elsif [HPXML::DHWRecircControlTypeTemperature].include?(recirc_control_type)
        assert_equal('0.067, 0.072, 0.074, 0.073, 0.069, 0.048, 0.011, 0.003, 0.009, 0.020, 0.030, 0.037, 0.043, 0.047, 0.050, 0.051, 0.044, 0.034, 0.026, 0.026, 0.030, 0.036, 0.045, 0.055', hot_water_distribution.recirculation_pump_weekday_fractions)
        assert_equal('0.067, 0.072, 0.074, 0.073, 0.069, 0.048, 0.011, 0.003, 0.009, 0.020, 0.030, 0.037, 0.043, 0.047, 0.050, 0.051, 0.044, 0.034, 0.026, 0.026, 0.030, 0.036, 0.045, 0.055', hot_water_distribution.recirculation_pump_weekend_fractions)
      end
      assert_equal('1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0', hot_water_distribution.recirculation_pump_monthly_multipliers)
    end
  end

  def _check_water_fixtures(hpxml_bldg, low_flow_shower:, low_flow_faucet:)
    assert_equal(2, hpxml_bldg.water_fixtures.size)
    hpxml_bldg.water_fixtures.each do |water_fixture|
      if water_fixture.water_fixture_type == HPXML::WaterFixtureTypeShowerhead
        assert_equal(low_flow_shower, water_fixture.low_flow)
      elsif water_fixture.water_fixture_type == HPXML::WaterFixtureTypeFaucet
        assert_equal(low_flow_faucet, water_fixture.low_flow)
      end
    end
    assert_equal('0.012, 0.006, 0.004, 0.005, 0.010, 0.034, 0.078, 0.086, 0.080, 0.067, 0.056, 0.047, 0.040, 0.035, 0.033, 0.031, 0.038, 0.051, 0.060, 0.060, 0.055, 0.048, 0.038, 0.026', hpxml_bldg.water_heating.water_fixtures_weekday_fractions)
    assert_equal('0.012, 0.006, 0.004, 0.005, 0.010, 0.034, 0.078, 0.086, 0.080, 0.067, 0.056, 0.047, 0.040, 0.035, 0.033, 0.031, 0.038, 0.051, 0.060, 0.060, 0.055, 0.048, 0.038, 0.026', hpxml_bldg.water_heating.water_fixtures_weekend_fractions)
    assert_equal('1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0', hpxml_bldg.water_heating.water_fixtures_monthly_multipliers)
  end

  def _check_drain_water_heat_recovery(hpxml_bldg, facilities_connected: nil, equal_flow: nil, efficiency: nil)
    hot_water_distribution = hpxml_bldg.hot_water_distributions[0]
    if facilities_connected.nil?
      assert_nil(hot_water_distribution.dwhr_facilities_connected)
    else
      assert_equal(facilities_connected, hot_water_distribution.dwhr_facilities_connected)
    end
    if equal_flow.nil?
      assert_nil(hot_water_distribution.dwhr_equal_flow)
    else
      assert_equal(equal_flow, hot_water_distribution.dwhr_equal_flow)
    end
    if efficiency.nil?
      assert_nil(hot_water_distribution.dwhr_efficiency)
    else
      assert_equal(efficiency, hot_water_distribution.dwhr_efficiency)
    end
  end

  def _check_solar_thermal_system(hpxml_bldg, present:)
    if present
      assert_equal(1, hpxml_bldg.solar_thermal_systems.size)
    else
      assert_equal(0, hpxml_bldg.solar_thermal_systems.size)
    end
  end

  def _check_desuperheater(hpxml_bldg, present:)
    hpxml_bldg.water_heating_systems.each do |water_heater|
      assert_equal(present, water_heater.uses_desuperheater)
    end
  end
end
