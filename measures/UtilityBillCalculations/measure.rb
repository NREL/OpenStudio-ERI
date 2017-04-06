# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/reference/measure_writing_guide/

require 'erb'
require 'csv'
require 'matrix'
require 'rest-client'

#start the measure
class UtilityBillCalculations < OpenStudio::Measure::ReportingMeasure

  # human readable name
  def name
    return "Utility Bill Calculations"
  end

  # human readable description
  def description
    return "Calls SAM SDK."
  end

  # human readable description of modeling approach
  def modeler_description
    return "Calls SAM SDK."
  end 
  
  # define the arguments that the user will input
  def arguments()
    args = OpenStudio::Measure::OSArgumentVector.new
    
    arg = OpenStudio::Measure::OSArgument.makeStringArgument("run_dir", true)
    arg.setDisplayName("Run Directory")
    arg.setDescription("Relative path of the run directory.")
    arg.setDefaultValue("..")
    args << arg    
    
    arg = OpenStudio::Measure::OSArgument::makeStringArgument("api_key", true)
    arg.setDisplayName("EIA API Key")
    args << arg    
    
    arg = OpenStudio::Measure::OSArgument::makeStringArgument("eia_id", true)
    arg.setDisplayName("EIA Utility ID")
    args << arg      
    
    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument("analysis_period", false)
    arg.setDisplayName("Analysis Period")
    arg.setUnits("yrs")
    arg.setDefaultValue(1)
    args << arg
    
    return args
  end
  
  # define what happens when the measure is run
  def run(runner, user_arguments)
    super(runner, user_arguments)

    # use the built-in error checking 
    if !runner.validateUserArguments(arguments(), user_arguments)
      return false
    end

    if !File.directory? "#{File.dirname(__FILE__)}/resources/sam-sdk-2017-1-17-r1"
      unzip_file = OpenStudio::UnzipFile.new("#{File.dirname(__FILE__)}/resources/sam-sdk-2017-1-17-r1.zip")
      unzip_file.extractAllFiles(OpenStudio::toPath("#{File.dirname(__FILE__)}/resources/sam-sdk-2017-1-17-r1"))
    end

    require "#{File.dirname(__FILE__)}/resources/ssc_api"
    
    # Assign the user inputs to variables
    run_dir = runner.getStringArgumentValue("run_dir", user_arguments)
    api_key = runner.getStringArgumentValue("api_key", user_arguments)
    eia_id = runner.getStringArgumentValue("eia_id", user_arguments)
    analysis_period = runner.getDoubleArgumentValue("analysis_period",user_arguments)
    
    cols = CSV.read(File.expand_path(File.join(run_dir, "enduse_timeseries.csv"))).transpose

    elec_load = nil
    elec_generated = nil
    cols.each do |col|
      if col[0].include? "Electricity:Facility"
        elec_load = col[1..-1]
      elsif col[0].include? "PV:Electricity"
        elec_generated = col[1..-1]
      end
    end
    # elec_generated = [0] * 8760 # this is to check against Pieter's code
    
    # tariff
    utility_ix = nil
    resources_dir = nil
    Dir.entries(run_dir).each do |entry|
      if entry.include? "UtilityBillCalculations"
        resources_dir = File.expand_path(File.join(run_dir, entry, "resources"))
      end
    end
    cols = CSV.read(File.expand_path(File.join(resources_dir, "utilities.csv"))).transpose
    cols.each do |col|
      unless col[0].nil?
        if col[0].include? "eiaid"
          unless col[1..-1].include? eia_id
            runner.registerError("Could not find EIA Utility ID: #{eia_id}.")
            return false
          end
          utility_ix = col.index(eia_id)
        end
      end
    end

    runner.registerInfo("Process api request on getpage=#{cols[4][utility_ix]}.")
    params = {'version':3, 'format':'json', 'detail':'full', 'getpage':cols[4][utility_ix], 'api_key':api_key}
    request = RestClient::Resource.new('http://api.openei.org/utility_rates?')
    response = request.get(params: params)
    tariff = JSON.parse(response.body, :symbolize_names=>true)[:items][0]    
    
    # File.open('result.json', 'w') do |f|
      # f.write(tariff.to_json)
    # end
    
    # utilityrate3
    p_data = SscApi.create_data_object
    SscApi.set_number(p_data, 'analysis_period', 1)
    SscApi.set_array(p_data, 'degradation', [0])
    SscApi.set_array(p_data, 'gen', elec_generated) # kW
    SscApi.set_array(p_data, 'load', elec_load) # kW
    # SscApi.set_number(p_data, 'ur_enable_net_metering', 1)
    SscApi.set_number(p_data, 'system_use_lifetime_output', 0) # TODO: what should this be?
    SscApi.set_number(p_data, 'inflation_rate', 0) # TODO: assume what?
    SscApi.set_number(p_data, 'ur_flat_buy_rate', 0) # TODO: how to get this from list of energyratestructure rates?
    SscApi.set_number(p_data, 'ur_monthly_fixed_charge', tariff[:fixedmonthlycharge]) # $
    unless tariff[:demandratestructure].nil?
      SscApi.set_matrix(p_data, 'ur_dc_sched_weekday', Matrix.rows(tariff[:demandweekdayschedule]))
      SscApi.set_matrix(p_data, 'ur_dc_sched_weekend', Matrix.rows(tariff[:demandweekendschedule]))
      SscApi.set_number(p_data, 'ur_dc_enable', 1)
      tariff[:demandratestructure].each_with_index do |period, i|
        period.each_with_index do |tier, j|
          unless tier[:adj].nil?
            SscApi.set_number(p_data, "ur_dc_p#{i+1}_t#{j+1}_dc", tier[:rate] + tier[:adj])
          else
            SscApi.set_number(p_data, "ur_dc_p#{i+1}_t#{j+1}_dc", tier[:rate])
          end
          unless tier[:max].nil?
            SscApi.set_number(p_data, "ur_dc_p#{i+1}_t#{j+1}_ub", tier[:max])
          else
            SscApi.set_number(p_data, "ur_dc_p#{i+1}_t#{j+1}_ub", 1000000000.0)
          end
        end
      end
    end
    SscApi.set_number(p_data, 'ur_ec_enable', 1)
    SscApi.set_matrix(p_data, 'ur_ec_sched_weekday', Matrix.rows(tariff[:energyweekdayschedule]))
    SscApi.set_matrix(p_data, 'ur_ec_sched_weekend', Matrix.rows(tariff[:energyweekendschedule]))
    tariff[:energyratestructure].each_with_index do |period, i|
      period.each_with_index do |tier, j|
        unless tier[:adj].nil?
          SscApi.set_number(p_data, "ur_ec_p#{i+1}_t#{j+1}_br", tier[:rate] + tier[:adj])
        else
          SscApi.set_number(p_data, "ur_ec_p#{i+1}_t#{j+1}_br", tier[:rate])
        end
        unless tier[:sell].nil?
          SscApi.set_number(p_data, "ur_ec_p#{i+1}_t#{j+1}_sr", tier[:sell])
        end
        unless tier[:max].nil?
          SscApi.set_number(p_data, "ur_ec_p#{i+1}_t#{j+1}_ub", tier[:max])
        else
          SscApi.set_number(p_data, "ur_ec_p#{i+1}_t#{j+1}_ub", 1000000000.0)
        end        
      end
    end
    
    p_mod = SscApi.create_module("utilityrate3")
    # SscApi.set_print(false)
    SscApi.execute_module(p_mod, p_data)
    
    # demand charges fixed
    demand_charges_fixed = SscApi.get_array(p_data, 'charge_w_sys_dc_fixed')[1]
    runner.registerInfo("Registering $#{demand_charges_fixed} for fixed annual demand charges.")    
    
    # demand charges tou
    demand_charges_tou = SscApi.get_array(p_data, 'charge_w_sys_dc_tou')[1]
    runner.registerInfo("Registering $#{demand_charges_tou} for tou annual demand charges.")
    
    # demand charges
    runner.registerValue("Annual Demand Charge", demand_charges_tou + demand_charges_fixed)
    
    # energy charges flat
    energy_charges_flat = SscApi.get_array(p_data, 'charge_w_sys_ec_flat')[1]
    runner.registerInfo("Registering $#{energy_charges_flat} for flat annual energy charges.")    
    
    # energy charges tou
    energy_charges_tou = SscApi.get_array(p_data, 'charge_w_sys_ec')[1]
    runner.registerInfo("Registering $#{energy_charges_tou} for tou annual energy charges.")
    
    # energy charges
    runner.registerValue("Annual Energy Charge", energy_charges_tou + energy_charges_flat)
    
    # annual bill
    utility_bills = SscApi.get_array(p_data, 'year1_monthly_utility_bill_w_sys')
    runner.registerValue("Annual Utility Bill", (utility_bills.inject(0){ |sum, x| sum + x }).round(2))
    runner.registerInfo("Registering $#{(utility_bills.inject(0){ |sum, x| sum + x }).round(2)} for annual electric bill.")
    
    puts "annual demand charges: $#{(demand_charges_tou + demand_charges_fixed).round(2)}"
    puts "annual energy charges: $#{(energy_charges_tou + energy_charges_flat).round(2)}"
    puts "annual utility bill: $#{(utility_bills.inject(0){ |sum, x| sum + x }).round(2)}"
    
    return true
 
  end

end

# register the measure to be used by the application
UtilityBillCalculations.new.registerWithApplication