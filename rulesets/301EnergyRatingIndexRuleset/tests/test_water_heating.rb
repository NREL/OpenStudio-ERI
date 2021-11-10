# frozen_string_literal: true

require_relative '../../../hpxml-measures/HPXMLtoOpenStudio/resources/minitest_helper'
require 'openstudio'
require 'openstudio/measure/ShowRunnerOutput'
require_relative '../measure.rb'
require 'fileutils'
require_relative 'util.rb'

class ERIWaterHeatingTest < MiniTest::Test
  def setup
    @root_path = File.absolute_path(File.join(File.dirname(__FILE__), '..', '..', '..'))
    @tmp_hpxml_path = File.join(@root_path, 'workflow', 'sample_files', 'tmp.xml')
  end

  def teardown
    File.delete(@tmp_hpxml_path) if File.exist? @tmp_hpxml_path
  end

  def test_water_heating_tank_elec
    hpxml_name = 'base.xml'

    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_water_heater(hpxml, [{ whtype: HPXML::WaterHeaterTypeStorage, fuel: HPXML::FuelTypeElectricity, setpoint: 125.0, location: HPXML::LocationLivingSpace, tank_vol: 40, ef: 0.9172, n_units_served: 1 }])
    _check_hot_water_distribution(hpxml, disttype: HPXML::DHWDistTypeStandard, pipe_r: 0.0, pipe_l: 93.5)
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_water_heater(hpxml, [{ whtype: HPXML::WaterHeaterTypeStorage, fuel: HPXML::FuelTypeElectricity, setpoint: 125.0, location: HPXML::LocationLivingSpace, tank_vol: 40, ef: 0.95, n_units_served: 1 }])
    _check_hot_water_distribution(hpxml, disttype: HPXML::DHWDistTypeStandard, pipe_r: 0.0, pipe_l: 50)
    calc_types = [Constants.CalcTypeERIIndexAdjustmentDesign,
                  Constants.CalcTypeERIIndexAdjustmentReferenceHome]
    calc_types.each do |calc_type|
      hpxml = _test_measure(hpxml_name, calc_type)
      _check_water_heater(hpxml, [{ whtype: HPXML::WaterHeaterTypeStorage, fuel: HPXML::FuelTypeElectricity, setpoint: 125.0, location: HPXML::LocationLivingSpace, tank_vol: 40, ef: 0.9172, n_units_served: 1 }])
      _check_hot_water_distribution(hpxml, disttype: HPXML::DHWDistTypeStandard, pipe_r: 0.0, pipe_l: 89.28)
    end
  end

  def test_water_heating_tank_elec_uef
    hpxml_name = 'base-dhw-tank-elec-uef.xml'

    # Reference Home
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_water_heater(hpxml, [{ whtype: HPXML::WaterHeaterTypeStorage, fuel: HPXML::FuelTypeElectricity, setpoint: 125.0, location: HPXML::LocationLivingSpace, tank_vol: 30, ef: 0.93, n_units_served: 1 }])
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_water_heater(hpxml, [{ whtype: HPXML::WaterHeaterTypeStorage, fuel: HPXML::FuelTypeElectricity, setpoint: 125.0, location: HPXML::LocationLivingSpace, tank_vol: 30, uef: 0.93, fhr: 46.0, n_units_served: 1 }])
    calc_types = [Constants.CalcTypeERIIndexAdjustmentDesign,
                  Constants.CalcTypeERIIndexAdjustmentReferenceHome]
    calc_types.each do |calc_type|
      hpxml = _test_measure(hpxml_name, calc_type)
      _check_water_heater(hpxml, [{ whtype: HPXML::WaterHeaterTypeStorage, fuel: HPXML::FuelTypeElectricity, setpoint: 125.0, location: HPXML::LocationLivingSpace, tank_vol: 30, ef: 0.93, n_units_served: 1 }])
    end
  end

  def test_water_heating_dwhr
    hpxml_name = 'base-dhw-dwhr.xml'

    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_drain_water_heat_recovery(hpxml)
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_drain_water_heat_recovery(hpxml, facilities_connected: HPXML::DWHRFacilitiesConnectedAll, equal_flow: true, efficiency: 0.55)
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentDesign)
    _check_drain_water_heat_recovery(hpxml)
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentReferenceHome)
    _check_drain_water_heat_recovery(hpxml)
  end

  def test_desuperheater
    hpxml_name = 'base-dhw-desuperheater.xml'

    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_desuperheater(hpxml, present: false)
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_desuperheater(hpxml, present: true)
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentDesign)
    _check_desuperheater(hpxml, present: false)
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentReferenceHome)
    _check_desuperheater(hpxml, present: false)
  end

  def test_water_heating_location_basement
    hpxml_name = 'base-foundation-unconditioned-basement.xml'

    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_water_heater(hpxml, [{ whtype: HPXML::WaterHeaterTypeStorage, fuel: HPXML::FuelTypeElectricity, setpoint: 125.0, location: HPXML::LocationBasementUnconditioned, tank_vol: 40, ef: 0.9172, n_units_served: 1 }])
    _check_hot_water_distribution(hpxml, disttype: HPXML::DHWDistTypeStandard, pipe_r: 0.0, pipe_l: 88.5)
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_water_heater(hpxml, [{ whtype: HPXML::WaterHeaterTypeStorage, fuel: HPXML::FuelTypeElectricity, setpoint: 125.0, location: HPXML::LocationBasementUnconditioned, tank_vol: 40, ef: 0.95, n_units_served: 1 }])
    _check_hot_water_distribution(hpxml, disttype: HPXML::DHWDistTypeStandard, pipe_r: 0.0, pipe_l: 50)
    calc_types = [Constants.CalcTypeERIIndexAdjustmentDesign,
                  Constants.CalcTypeERIIndexAdjustmentReferenceHome]
    calc_types.each do |calc_type|
      hpxml = _test_measure(hpxml_name, calc_type)
      _check_water_heater(hpxml, [{ whtype: HPXML::WaterHeaterTypeStorage, fuel: HPXML::FuelTypeElectricity, setpoint: 125.0, location: HPXML::LocationLivingSpace, tank_vol: 40, ef: 0.9172, n_units_served: 1 }])
      _check_hot_water_distribution(hpxml, disttype: HPXML::DHWDistTypeStandard, pipe_r: 0.0, pipe_l: 89.28)
    end
  end

  def test_water_heating_low_flow_fixtures
    hpxml_name = 'base-dhw-low-flow-fixtures.xml'

    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_water_fixtures(hpxml, low_flow_shower: false, low_flow_faucet: false)
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_water_fixtures(hpxml, low_flow_shower: true, low_flow_faucet: true)
    calc_types = [Constants.CalcTypeERIIndexAdjustmentDesign,
                  Constants.CalcTypeERIIndexAdjustmentReferenceHome]
    calc_types.each do |calc_type|
      hpxml = _test_measure(hpxml_name, calc_type)
      _check_water_fixtures(hpxml, low_flow_shower: false, low_flow_faucet: false)
    end
  end

  def test_water_heating_recirc_demand
    hpxml_name = 'base-dhw-recirc-demand.xml'

    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_hot_water_distribution(hpxml, disttype: HPXML::DHWDistTypeStandard, pipe_r: 0.0, pipe_l: 93.5)
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_hot_water_distribution(hpxml, disttype: HPXML::DHWDistTypeRecirc, pipe_r: 3.0, recirc_control: HPXML::DHWRecirControlTypeSensor, recirc_loop_l: 50, recirc_branch_l: 50, recirc_pump_power: 50)
    calc_types = [Constants.CalcTypeERIIndexAdjustmentDesign,
                  Constants.CalcTypeERIIndexAdjustmentReferenceHome]
    calc_types.each do |calc_type|
      hpxml = _test_measure(hpxml_name, calc_type)
      _check_hot_water_distribution(hpxml, disttype: HPXML::DHWDistTypeStandard, pipe_r: 0.0, pipe_l: 89.28)
    end
  end

  def test_water_heating_tank_gas
    # Create derivative file for testing
    hpxml_name = 'base-dhw-tank-gas-uef.xml'
    hpxml = HPXML.new(hpxml_path: File.join(@root_path, 'workflow', 'sample_files', hpxml_name))
    hpxml.water_heating_systems[0].tank_volume = 50.0
    hpxml.water_heating_systems[0].energy_factor = 0.59
    hpxml.water_heating_systems[0].uniform_energy_factor = nil
    hpxml.water_heating_systems[0].first_hour_rating = nil
    hpxml_name = File.basename(@tmp_hpxml_path)
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)

    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_water_heater(hpxml, [{ whtype: HPXML::WaterHeaterTypeStorage, fuel: HPXML::FuelTypeNaturalGas, setpoint: 125.0, location: HPXML::LocationLivingSpace, tank_vol: 50, ef: 0.575, n_units_served: 1 }])
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_water_heater(hpxml, [{ whtype: HPXML::WaterHeaterTypeStorage, fuel: HPXML::FuelTypeNaturalGas, setpoint: 125.0, location: HPXML::LocationLivingSpace, tank_vol: 50, ef: 0.59, n_units_served: 1 }])
    calc_types = [Constants.CalcTypeERIIndexAdjustmentDesign,
                  Constants.CalcTypeERIIndexAdjustmentReferenceHome]
    calc_types.each do |calc_type|
      hpxml = _test_measure(hpxml_name, calc_type)
      _check_water_heater(hpxml, [{ whtype: HPXML::WaterHeaterTypeStorage, fuel: HPXML::FuelTypeNaturalGas, setpoint: 125.0, location: HPXML::LocationLivingSpace, tank_vol: 50, ef: 0.575, n_units_served: 1 }])
    end
  end

  def test_water_heating_tank_gas_uef
    hpxml_name = 'base-dhw-tank-gas-uef.xml'

    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_water_heater(hpxml, [{ whtype: HPXML::WaterHeaterTypeStorage, fuel: HPXML::FuelTypeNaturalGas, setpoint: 125.0, location: HPXML::LocationLivingSpace, tank_vol: 30, ef: 0.61, n_units_served: 1 }])
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_water_heater(hpxml, [{ whtype: HPXML::WaterHeaterTypeStorage, fuel: HPXML::FuelTypeNaturalGas, setpoint: 125.0, location: HPXML::LocationLivingSpace, tank_vol: 30, uef: 0.59, fhr: 56, n_units_served: 1 }])
    calc_types = [Constants.CalcTypeERIIndexAdjustmentDesign,
                  Constants.CalcTypeERIIndexAdjustmentReferenceHome]
    calc_types.each do |calc_type|
      hpxml = _test_measure(hpxml_name, calc_type)
      _check_water_heater(hpxml, [{ whtype: HPXML::WaterHeaterTypeStorage, fuel: HPXML::FuelTypeNaturalGas, setpoint: 125.0, location: HPXML::LocationLivingSpace, tank_vol: 30, ef: 0.61, n_units_served: 1 }])
    end
  end

  def test_water_heating_jacket_insulation
    hpxml_name = 'base-dhw-jacket-gas.xml'

    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_water_heater(hpxml, [{ whtype: HPXML::WaterHeaterTypeStorage, fuel: HPXML::FuelTypeNaturalGas, setpoint: 125.0, location: HPXML::LocationLivingSpace, tank_vol: 50, ef: 0.575, n_units_served: 1 }])
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_water_heater(hpxml, [{ whtype: HPXML::WaterHeaterTypeStorage, fuel: HPXML::FuelTypeNaturalGas, setpoint: 125.0, location: HPXML::LocationLivingSpace, tank_vol: 50, ef: 0.59, n_units_served: 1, jacket_r: 10 }])
    calc_types = [Constants.CalcTypeERIIndexAdjustmentDesign,
                  Constants.CalcTypeERIIndexAdjustmentReferenceHome]
    calc_types.each do |calc_type|
      hpxml = _test_measure(hpxml_name, calc_type)
      _check_water_heater(hpxml, [{ whtype: HPXML::WaterHeaterTypeStorage, fuel: HPXML::FuelTypeNaturalGas, setpoint: 125.0, location: HPXML::LocationLivingSpace, tank_vol: 50, ef: 0.575, n_units_served: 1 }])
    end
  end

  def test_water_heating_tank_heat_pump
    # Create derivative file for testing
    hpxml_name = 'base-dhw-tank-heat-pump-uef.xml'
    hpxml = HPXML.new(hpxml_path: File.join(@root_path, 'workflow', 'sample_files', hpxml_name))
    hpxml.water_heating_systems[0].energy_factor = 2.3
    hpxml.water_heating_systems[0].tank_volume = 80.0
    hpxml.water_heating_systems[0].uniform_energy_factor = nil
    hpxml.water_heating_systems[0].first_hour_rating = nil
    hpxml_name = File.basename(@tmp_hpxml_path)
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)

    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_water_heater(hpxml, [{ whtype: HPXML::WaterHeaterTypeStorage, fuel: HPXML::FuelTypeElectricity, setpoint: 125.0, location: HPXML::LocationLivingSpace, tank_vol: 80, ef: 0.8644, n_units_served: 1 }])
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_water_heater(hpxml, [{ whtype: HPXML::WaterHeaterTypeHeatPump, fuel: HPXML::FuelTypeElectricity, setpoint: 125.0, location: HPXML::LocationLivingSpace, tank_vol: 80, ef: 2.3, n_units_served: 1 }])
    calc_types = [Constants.CalcTypeERIIndexAdjustmentDesign,
                  Constants.CalcTypeERIIndexAdjustmentReferenceHome]
    calc_types.each do |calc_type|
      hpxml = _test_measure(hpxml_name, calc_type)
      _check_water_heater(hpxml, [{ whtype: HPXML::WaterHeaterTypeStorage, fuel: HPXML::FuelTypeElectricity, setpoint: 125.0, location: HPXML::LocationLivingSpace, tank_vol: 80, ef: 0.8644, n_units_served: 1 }])
    end
  end

  def test_water_heating_tank_heat_pump_uef
    hpxml_name = 'base-dhw-tank-heat-pump-uef.xml'

    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_water_heater(hpxml, [{ whtype: HPXML::WaterHeaterTypeStorage, fuel: HPXML::FuelTypeElectricity, setpoint: 125.0, location: HPXML::LocationLivingSpace, tank_vol: 50, ef: 0.9, n_units_served: 1 }])
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_water_heater(hpxml, [{ whtype: HPXML::WaterHeaterTypeHeatPump, fuel: HPXML::FuelTypeElectricity, setpoint: 125.0, location: HPXML::LocationLivingSpace, tank_vol: 50, uef: 3.75, fhr: 56, n_units_served: 1 }])
    calc_types = [Constants.CalcTypeERIIndexAdjustmentDesign,
                  Constants.CalcTypeERIIndexAdjustmentReferenceHome]
    calc_types.each do |calc_type|
      hpxml = _test_measure(hpxml_name, calc_type)
      _check_water_heater(hpxml, [{ whtype: HPXML::WaterHeaterTypeStorage, fuel: HPXML::FuelTypeElectricity, setpoint: 125.0, location: HPXML::LocationLivingSpace, tank_vol: 50, ef: 0.9, n_units_served: 1 }])
    end
  end

  def test_water_heating_tankless_electric
    # Create derivative file for testing
    hpxml_name = 'base-dhw-tankless-electric-uef.xml'
    hpxml = HPXML.new(hpxml_path: File.join(@root_path, 'workflow', 'sample_files', hpxml_name))
    hpxml.water_heating_systems[0].energy_factor = 0.99
    hpxml.water_heating_systems[0].uniform_energy_factor = nil
    hpxml_name = File.basename(@tmp_hpxml_path)
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)

    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_water_heater(hpxml, [{ whtype: HPXML::WaterHeaterTypeStorage, fuel: HPXML::FuelTypeElectricity, setpoint: 125.0, location: HPXML::LocationLivingSpace, tank_vol: 40, ef: 0.9172, n_units_served: 1 }])
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_water_heater(hpxml, [{ whtype: HPXML::WaterHeaterTypeTankless, fuel: HPXML::FuelTypeElectricity, setpoint: 125.0, location: HPXML::LocationLivingSpace, ef: 0.99, n_units_served: 1 }])
    calc_types = [Constants.CalcTypeERIIndexAdjustmentDesign,
                  Constants.CalcTypeERIIndexAdjustmentReferenceHome]
    calc_types.each do |calc_type|
      hpxml = _test_measure(hpxml_name, calc_type)
      _check_water_heater(hpxml, [{ whtype: HPXML::WaterHeaterTypeStorage, fuel: HPXML::FuelTypeElectricity, setpoint: 125.0, location: HPXML::LocationLivingSpace, tank_vol: 40, ef: 0.9172, n_units_served: 1 }])
    end
  end

  def test_water_heating_tankless_electric_uef
    hpxml_name = 'base-dhw-tankless-electric-uef.xml'

    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_water_heater(hpxml, [{ whtype: HPXML::WaterHeaterTypeStorage, fuel: HPXML::FuelTypeElectricity, setpoint: 125.0, location: HPXML::LocationLivingSpace, tank_vol: 40, ef: 0.9172, n_units_served: 1 }])
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_water_heater(hpxml, [{ whtype: HPXML::WaterHeaterTypeTankless, fuel: HPXML::FuelTypeElectricity, setpoint: 125.0, location: HPXML::LocationLivingSpace, uef: 0.98, n_units_served: 1 }])
    calc_types = [Constants.CalcTypeERIIndexAdjustmentDesign,
                  Constants.CalcTypeERIIndexAdjustmentReferenceHome]
    calc_types.each do |calc_type|
      hpxml = _test_measure(hpxml_name, calc_type)
      _check_water_heater(hpxml, [{ whtype: HPXML::WaterHeaterTypeStorage, fuel: HPXML::FuelTypeElectricity, setpoint: 125.0, location: HPXML::LocationLivingSpace, tank_vol: 40, ef: 0.9172, n_units_served: 1 }])
    end
  end

  def test_water_heating_tankless_gas
    # Create derivative file for testing
    hpxml_name = 'base-dhw-tankless-gas-uef.xml'
    hpxml = HPXML.new(hpxml_path: File.join(@root_path, 'workflow', 'sample_files', hpxml_name))
    hpxml.water_heating_systems[0].energy_factor = 0.82
    hpxml.water_heating_systems[0].uniform_energy_factor = nil
    hpxml_name = File.basename(@tmp_hpxml_path)
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)

    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_water_heater(hpxml, [{ whtype: HPXML::WaterHeaterTypeStorage, fuel: HPXML::FuelTypeNaturalGas, setpoint: 125.0, location: HPXML::LocationLivingSpace, tank_vol: 40, ef: 0.594, n_units_served: 1 }])
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_water_heater(hpxml, [{ whtype: HPXML::WaterHeaterTypeTankless, fuel: HPXML::FuelTypeNaturalGas, setpoint: 125.0, location: HPXML::LocationLivingSpace, ef: 0.82, n_units_served: 1 }])
    calc_types = [Constants.CalcTypeERIIndexAdjustmentDesign,
                  Constants.CalcTypeERIIndexAdjustmentReferenceHome]
    calc_types.each do |calc_type|
      hpxml = _test_measure(hpxml_name, calc_type)
      _check_water_heater(hpxml, [{ whtype: HPXML::WaterHeaterTypeStorage, fuel: HPXML::FuelTypeNaturalGas, setpoint: 125.0, location: HPXML::LocationLivingSpace, tank_vol: 40, ef: 0.594, n_units_served: 1 }])
    end
  end

  def test_water_heating_tankless_gas_uef
    hpxml_name = 'base-dhw-tankless-gas-uef.xml'

    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_water_heater(hpxml, [{ whtype: HPXML::WaterHeaterTypeStorage, fuel: HPXML::FuelTypeNaturalGas, setpoint: 125.0, location: HPXML::LocationLivingSpace, tank_vol: 40, ef: 0.594, n_units_served: 1 }])
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_water_heater(hpxml, [{ whtype: HPXML::WaterHeaterTypeTankless, fuel: HPXML::FuelTypeNaturalGas, setpoint: 125.0, location: HPXML::LocationLivingSpace, uef: 0.93, n_units_served: 1 }])
    calc_types = [Constants.CalcTypeERIIndexAdjustmentDesign,
                  Constants.CalcTypeERIIndexAdjustmentReferenceHome]
    calc_types.each do |calc_type|
      hpxml = _test_measure(hpxml_name, calc_type)
      _check_water_heater(hpxml, [{ whtype: HPXML::WaterHeaterTypeStorage, fuel: HPXML::FuelTypeNaturalGas, setpoint: 125.0, location: HPXML::LocationLivingSpace, tank_vol: 40, ef: 0.594, n_units_served: 1 }])
    end
  end

  def test_multiple_water_heating
    hpxml_name = 'base-dhw-multiple.xml'

    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_water_heater(hpxml, [{ whtype: HPXML::WaterHeaterTypeStorage, fuel: HPXML::FuelTypeElectricity, setpoint: 125.0, location: HPXML::LocationLivingSpace, tank_vol: 40, ef: 0.9172, n_units_served: 1 }])
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_water_heater(hpxml, [{ whtype: HPXML::WaterHeaterTypeStorage, fuel: HPXML::FuelTypeElectricity, frac_load: 0.2, setpoint: 125.0, location: HPXML::LocationLivingSpace, tank_vol: 40, ef: 0.95, n_units_served: 1 },
                                { whtype: HPXML::WaterHeaterTypeStorage, fuel: HPXML::FuelTypeNaturalGas, frac_load: 0.2, setpoint: 125.0, location: HPXML::LocationLivingSpace, tank_vol: 50, ef: 0.59, n_units_served: 1 },
                                { whtype: HPXML::WaterHeaterTypeHeatPump, fuel: HPXML::FuelTypeElectricity, frac_load: 0.2, setpoint: 125.0, location: HPXML::LocationLivingSpace, tank_vol: 80, ef: 2.3, n_units_served: 1 },
                                { whtype: HPXML::WaterHeaterTypeTankless, fuel: HPXML::FuelTypeElectricity, frac_load: 0.2, setpoint: 125.0, location: HPXML::LocationLivingSpace, ef: 0.99, n_units_served: 1 },
                                { whtype: HPXML::WaterHeaterTypeTankless, fuel: HPXML::FuelTypeNaturalGas, frac_load: 0.1, setpoint: 125.0, location: HPXML::LocationLivingSpace, ef: 0.82, n_units_served: 1 },
                                { whtype: HPXML::WaterHeaterTypeCombiStorage, frac_load: 0.1, setpoint: 125.0, location: HPXML::LocationLivingSpace, tank_vol: 50, n_units_served: 1, standby_loss: 0.843 }])
    calc_types = [Constants.CalcTypeERIIndexAdjustmentDesign,
                  Constants.CalcTypeERIIndexAdjustmentReferenceHome]
    calc_types.each do |calc_type|
      hpxml = _test_measure(hpxml_name, calc_type)
      _check_water_heater(hpxml, [{ whtype: HPXML::WaterHeaterTypeStorage, fuel: HPXML::FuelTypeElectricity, setpoint: 125.0, location: HPXML::LocationLivingSpace, tank_vol: 40, ef: 0.9172, n_units_served: 1 }])
    end

    # Test tie between water heating fuel types; should choose fossil fuel
    hpxml = HPXML.new(hpxml_path: File.join(@root_path, 'workflow', 'sample_files', hpxml_name))
    hpxml.water_heating_systems.each do |w|
      w.fraction_dhw_load_served = 0.0
    end
    hpxml.water_heating_systems.select { |w| w.fuel_type == HPXML::FuelTypeElectricity }[0].fraction_dhw_load_served = 0.5
    hpxml.water_heating_systems.select { |w| w.fuel_type == HPXML::FuelTypeNaturalGas }[0].fraction_dhw_load_served = 0.5
    hpxml_name = File.basename(@tmp_hpxml_path)
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)

    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    assert_equal(HPXML::FuelTypeNaturalGas, hpxml.water_heating_systems[0].fuel_type)
  end

  def test_indirect_water_heating
    hpxml_name = 'base-dhw-indirect-standbyloss.xml'

    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_water_heater(hpxml, [{ whtype: HPXML::WaterHeaterTypeStorage, fuel: HPXML::FuelTypeNaturalGas, setpoint: 125.0, location: HPXML::LocationLivingSpace, tank_vol: 50, ef: 0.575, n_units_served: 1 }])
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_water_heater(hpxml, [{ whtype: HPXML::WaterHeaterTypeCombiStorage, setpoint: 125.0, location: HPXML::LocationLivingSpace, tank_vol: 50, n_units_served: 1, standby_loss: 1.0 }])
    calc_types = [Constants.CalcTypeERIIndexAdjustmentDesign,
                  Constants.CalcTypeERIIndexAdjustmentReferenceHome]
    calc_types.each do |calc_type|
      hpxml = _test_measure(hpxml_name, calc_type)
      _check_water_heater(hpxml, [{ whtype: HPXML::WaterHeaterTypeStorage, fuel: HPXML::FuelTypeNaturalGas, setpoint: 125.0, location: HPXML::LocationLivingSpace, tank_vol: 50, ef: 0.575, n_units_served: 1 }])
    end
  end

  def test_indirect_tankless_coil
    hpxml_name = 'base-dhw-combi-tankless.xml'

    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_water_heater(hpxml, [{ whtype: HPXML::WaterHeaterTypeStorage, fuel: HPXML::FuelTypeNaturalGas, setpoint: 125.0, location: HPXML::LocationLivingSpace, tank_vol: 40, ef: 0.594, n_units_served: 1 }])
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_water_heater(hpxml, [{ whtype: HPXML::WaterHeaterTypeCombiTankless, setpoint: 125.0, location: HPXML::LocationLivingSpace, n_units_served: 1 }])
    calc_types = [Constants.CalcTypeERIIndexAdjustmentDesign,
                  Constants.CalcTypeERIIndexAdjustmentReferenceHome]
    calc_types.each do |calc_type|
      hpxml = _test_measure(hpxml_name, calc_type)
      _check_water_heater(hpxml, [{ whtype: HPXML::WaterHeaterTypeStorage, fuel: HPXML::FuelTypeNaturalGas, setpoint: 125.0, location: HPXML::LocationLivingSpace, tank_vol: 40, ef: 0.594, n_units_served: 1 }])
    end
  end

  def test_water_heating_none
    hpxml_name = 'base-dhw-none.xml'

    calc_types = [Constants.CalcTypeERIReferenceHome,
                  Constants.CalcTypeERIRatedHome]
    calc_types.each do |calc_type|
      hpxml = _test_measure(hpxml_name, calc_type)
      _check_water_heater(hpxml, [{ whtype: HPXML::WaterHeaterTypeStorage, fuel: HPXML::FuelTypeNaturalGas, setpoint: 125.0, location: HPXML::LocationLivingSpace, tank_vol: 40, ef: 0.594, n_units_served: 1 }])
      _check_hot_water_distribution(hpxml, disttype: HPXML::DHWDistTypeStandard, pipe_r: 0.0, pipe_l: 93.5)
    end
    calc_types = [Constants.CalcTypeERIIndexAdjustmentDesign,
                  Constants.CalcTypeERIIndexAdjustmentReferenceHome]
    calc_types.each do |calc_type|
      hpxml = _test_measure(hpxml_name, calc_type)
      _check_water_heater(hpxml, [{ whtype: HPXML::WaterHeaterTypeStorage, fuel: HPXML::FuelTypeNaturalGas, setpoint: 125.0, location: HPXML::LocationLivingSpace, tank_vol: 40, ef: 0.594, n_units_served: 1 }])
      _check_hot_water_distribution(hpxml, disttype: HPXML::DHWDistTypeStandard, pipe_r: 0.0, pipe_l: 89.28)
    end

    # Test tie between space heating fuel types
    hpxml = HPXML.new(hpxml_path: File.join(@root_path, 'workflow', 'sample_files', hpxml_name))
    hpxml.heating_systems[0].fraction_heat_load_served = 0.15
    { HPXML::FuelTypeOil => 0.35, HPXML::FuelTypeElectricity => 0.5 }.each do |fuel, frac|
      hpxml.heating_systems.add(id: "HeatingSystem#{fuel}",
                                heating_system_type: HPXML::HVACTypeStove,
                                heating_system_fuel: fuel,
                                heating_capacity: 999,
                                heating_efficiency_percent: 0.8,
                                fraction_heat_load_served: frac)
    end
    hpxml_name = File.basename(@tmp_hpxml_path)
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)

    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    assert_equal(HPXML::FuelTypeOil, hpxml.water_heating_systems[0].fuel_type)
  end

  def test_water_heating_pre_addendum_a
    hpxml_name = 'base-version-2014.xml'

    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_water_heater(hpxml, [{ whtype: HPXML::WaterHeaterTypeStorage, fuel: HPXML::FuelTypeElectricity, setpoint: 120.0, location: HPXML::LocationLivingSpace, tank_vol: 40, ef: 0.9172, n_units_served: 1 }])
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_water_heater(hpxml, [{ whtype: HPXML::WaterHeaterTypeStorage, fuel: HPXML::FuelTypeElectricity, setpoint: 120.0, location: HPXML::LocationLivingSpace, tank_vol: 40, ef: 0.95, n_units_served: 1 }])
    calc_types = [Constants.CalcTypeERIIndexAdjustmentDesign,
                  Constants.CalcTypeERIIndexAdjustmentReferenceHome]
    calc_types.each do |calc_type|
      hpxml = _test_measure(hpxml_name, calc_type)
      _check_water_heater(hpxml, [{ whtype: HPXML::WaterHeaterTypeStorage, fuel: HPXML::FuelTypeElectricity, setpoint: 120.0, location: HPXML::LocationLivingSpace, tank_vol: 40, ef: 0.9172, n_units_served: 1 }])
    end
  end

  def test_water_heating_shared_multiple_units_recirc
    hpxml_name = 'base-bldgtype-multifamily-shared-water-heater-recirc.xml'

    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_water_heater(hpxml, [{ whtype: HPXML::WaterHeaterTypeStorage, fuel: HPXML::FuelTypeNaturalGas, setpoint: 125.0, location: HPXML::LocationLivingSpace, tank_vol: 40, ef: 0.59, n_units_served: 1 }])
    _check_hot_water_distribution(hpxml, disttype: HPXML::DHWDistTypeStandard, pipe_r: 0.0, pipe_l: 70.0)
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_water_heater(hpxml, [{ whtype: HPXML::WaterHeaterTypeStorage, fuel: HPXML::FuelTypeNaturalGas, setpoint: 125.0, location: HPXML::LocationLivingSpace, tank_vol: 120, ef: 0.59, n_units_served: 6 }])
    _check_hot_water_distribution(hpxml, disttype: HPXML::DHWDistTypeStandard, pipe_r: 0.0, pipe_l: 50, shared_recirc_power: 220, shared_recirc_num_units_served: 6, shared_recirc_control_type: HPXML::DHWRecirControlTypeTimer)
    calc_types = [Constants.CalcTypeERIIndexAdjustmentDesign,
                  Constants.CalcTypeERIIndexAdjustmentReferenceHome]
    calc_types.each do |calc_type|
      hpxml = _test_measure(hpxml_name, calc_type)
      _check_water_heater(hpxml, [{ whtype: HPXML::WaterHeaterTypeStorage, fuel: HPXML::FuelTypeNaturalGas, setpoint: 125.0, location: HPXML::LocationLivingSpace, tank_vol: 40, ef: 0.59, n_units_served: 1 }])
      _check_hot_water_distribution(hpxml, disttype: HPXML::DHWDistTypeStandard, pipe_r: 0.0, pipe_l: 89.28)
    end
  end

  def test_water_heating_shared_laundry_room
    hpxml_name = 'base-bldgtype-multifamily-shared-laundry-room.xml'

    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_water_heater(hpxml, [{ whtype: HPXML::WaterHeaterTypeStorage, fuel: HPXML::FuelTypeNaturalGas, setpoint: 125.0, location: HPXML::LocationLivingSpace, tank_vol: 40, ef: 0.59, n_units_served: 1 }])
    _check_hot_water_distribution(hpxml, disttype: HPXML::DHWDistTypeStandard, pipe_r: 0.0, pipe_l: 70.0)
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_water_heater(hpxml, [{ whtype: HPXML::WaterHeaterTypeStorage, fuel: HPXML::FuelTypeNaturalGas, setpoint: 125.0, location: HPXML::LocationLivingSpace, tank_vol: 120, ef: 0.59, n_units_served: 6 }])
    _check_hot_water_distribution(hpxml, disttype: HPXML::DHWDistTypeStandard, pipe_r: 0.0, pipe_l: 50)
    calc_types = [Constants.CalcTypeERIIndexAdjustmentDesign,
                  Constants.CalcTypeERIIndexAdjustmentReferenceHome]
    calc_types.each do |calc_type|
      hpxml = _test_measure(hpxml_name, calc_type)
      _check_water_heater(hpxml, [{ whtype: HPXML::WaterHeaterTypeStorage, fuel: HPXML::FuelTypeNaturalGas, setpoint: 125.0, location: HPXML::LocationLivingSpace, tank_vol: 40, ef: 0.59, n_units_served: 1 }])
      _check_hot_water_distribution(hpxml, disttype: HPXML::DHWDistTypeStandard, pipe_r: 0.0, pipe_l: 89.28)
    end
  end

  def test_water_heating_solar_simple
    hpxml_name = 'base-dhw-solar-fraction.xml'

    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_solar_thermal_system(hpxml, present: false)
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_solar_thermal_system(hpxml, present: true)
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentDesign)
    _check_solar_thermal_system(hpxml, present: false)
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentReferenceHome)
    _check_solar_thermal_system(hpxml, present: false)
  end

  def test_water_heating_solar_detailed
    hpxml_name = 'base-dhw-solar-indirect-flat-plate.xml'

    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_solar_thermal_system(hpxml, present: false)
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_solar_thermal_system(hpxml, present: true)
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentDesign)
    _check_solar_thermal_system(hpxml, present: false)
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentReferenceHome)
    _check_solar_thermal_system(hpxml, present: false)
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

  def _check_water_heater(hpxml, all_expected_values = [])
    assert_equal(all_expected_values.size, hpxml.water_heating_systems.size)
    hpxml.water_heating_systems.each_with_index do |water_heater, idx|
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
      if expected_values[:standby_loss].nil?
        assert_nil(water_heater.standby_loss)
      else
        assert_equal(expected_values[:standby_loss], water_heater.standby_loss)
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
      if water_heater.number_of_units_served.nil?
        assert_equal(expected_values[:n_units_served], 1)
      else
        assert_equal(expected_values[:n_units_served], water_heater.number_of_units_served)
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

  def _check_hot_water_distribution(hpxml, disttype:, pipe_r:, pipe_l: nil, recirc_control: nil, recirc_loop_l: nil, recirc_branch_l: nil, recirc_pump_power: nil,
                                    shared_recirc_power: nil, shared_recirc_num_units_served: nil, shared_recirc_control_type: nil)
    assert_equal(1, hpxml.hot_water_distributions.size)
    hot_water_distribution = hpxml.hot_water_distributions[0]
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
      assert_nil(hot_water_distribution.recirculation_piping_length)
    else
      assert_in_epsilon(recirc_loop_l, hot_water_distribution.recirculation_piping_length, 0.01)
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
    if shared_recirc_num_units_served.nil?
      assert_nil(hot_water_distribution.shared_recirculation_number_of_units_served)
    else
      assert_equal(shared_recirc_num_units_served, hot_water_distribution.shared_recirculation_number_of_units_served)
    end
    if shared_recirc_control_type.nil?
      assert_nil(hot_water_distribution.shared_recirculation_control_type)
    else
      assert_equal(shared_recirc_control_type, hot_water_distribution.shared_recirculation_control_type)
    end
  end

  def _check_water_fixtures(hpxml, low_flow_shower:, low_flow_faucet:)
    assert_equal(2, hpxml.water_fixtures.size)
    hpxml.water_fixtures.each do |water_fixture|
      if water_fixture.water_fixture_type == HPXML::WaterFixtureTypeShowerhead
        assert_equal(low_flow_shower, water_fixture.low_flow)
      elsif water_fixture.water_fixture_type == HPXML::WaterFixtureTypeFaucet
        assert_equal(low_flow_faucet, water_fixture.low_flow)
      end
    end
  end

  def _check_drain_water_heat_recovery(hpxml, facilities_connected: nil, equal_flow: nil, efficiency: nil)
    hot_water_distribution = hpxml.hot_water_distributions[0]
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

  def _check_solar_thermal_system(hpxml, present:)
    if present
      assert_equal(1, hpxml.solar_thermal_systems.size)
    else
      assert_equal(0, hpxml.solar_thermal_systems.size)
    end
  end

  def _check_desuperheater(hpxml, present:)
    hpxml.water_heating_systems.each do |water_heater|
      assert_equal(present, water_heater.uses_desuperheater)
    end
  end
end
