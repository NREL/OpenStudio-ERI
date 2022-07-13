# frozen_string_literal: true

require_relative 'utility_bills'

if ARGV.size == 8
  # Usage: openstudio utility_bills.rb elec_state elec_fixed_charge elec_marginal_rate gas_state gas_fixed_charge gas_marginal_rate oil_state propane_state
  # E.g., if requesting state marginal/average rate based on user-specified fixed charge: openstudio utility_bills.rb CO 12.0 0.0 CO 12.0 0.0 CO CO
  # E.g., if requesting average rate based on user-specified fixed charge and marginal rate: openstudio utility_bills.rb CO 12.0 0.12 CO 12.0 1.10 CO CO
  require_relative 'hpxml'
  require_relative 'constants'
  require 'csv'
  runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)

  elec_state = ARGV[0]
  elec_fixed_charge = Float(ARGV[1])
  elec_marginal_rate = Float(ARGV[2])
  gas_state = ARGV[3]
  gas_fixed_charge = Float(ARGV[4])
  gas_marginal_rate = Float(ARGV[5])
  oil_state = ARGV[6]
  propane_state = ARGV[7]

  elec_marginal_rate = nil if elec_marginal_rate <= 0
  gas_marginal_rate = nil if gas_marginal_rate <= 0
  elec_state = 'US' if Constants.StateCodesMap[elec_state].nil?
  gas_state = 'US' if Constants.StateCodesMap[gas_state].nil?
  oil_state = 'US' if Constants.StateCodesMap[oil_state].nil?
  propane_state = 'US' if Constants.StateCodesMap[propane_state].nil?

  { HPXML::FuelTypeElectricity => [elec_state, elec_fixed_charge, elec_marginal_rate],
    HPXML::FuelTypeNaturalGas => [gas_state, gas_fixed_charge, gas_marginal_rate],
    HPXML::FuelTypeOil => [oil_state, 0.0, nil],
    HPXML::FuelTypePropane => [propane_state, 0.0, nil] }.each do |fuel_type, values|
    state_code, fixed_charge, marginal_rate = values
    marginal_rate, average_rate = UtilityBills.get_rates_from_eia_data(runner, state_code, fuel_type, fixed_charge, marginal_rate)
    if (not marginal_rate.nil?) && average_rate.nil?
      puts "#{fuel_type} #{marginal_rate.round(6)} #{marginal_rate.round(6)}"
    else
      puts "#{fuel_type} #{marginal_rate.round(6)} #{average_rate.round(6)}"
    end
  end
end
