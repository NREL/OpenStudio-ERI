# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/reference/measure_writing_guide/

require 'erb'
require 'csv'
require 'matrix'

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
    analysis_period = runner.getDoubleArgumentValue("analysis_period",user_arguments)

    cols = CSV.read(File.expand_path(File.join(run_dir, "enduse_timeseries.csv"))).transpose
    
    e_with_system = nil
    e_without_system = nil
    cols.each do |col|
      if col[0].include? "Electricity:Facility"
        e_with_system = col[1..-1]
      elsif col[0].include? "Fans:Electricity"
        e_without_system = col[1..-1]
      end
    end

    # annualoutput
    p_data = SscApi.create_data_object    
    SscApi.set_number(p_data, 'analysis_period', analysis_period)
    SscApi.set_array(p_data, 'energy_availability', [98])
    SscApi.set_array(p_data, 'energy_degradation', [0.05])
    SscApi.set_matrix(p_data, 'energy_curtailment', Matrix.rows([[1] * 24] * 12))
    SscApi.set_number(p_data, 'system_use_lifetime_output', 0)
    SscApi.set_array(p_data, 'system_hourly_energy', e_with_system) # kW

    p_mod = SscApi.create_module("annualoutput")
    # SscApi.set_print(false)
    SscApi.execute_module(p_mod, p_data)
    
    puts "Annual energy: #{SscApi.get_array(p_data, 'annual_energy')}" # kWh
    
    # utilityrate2
    p_data = SscApi.create_data_object
    SscApi.set_number(p_data, 'analysis_period', analysis_period)
    SscApi.set_array(p_data, 'degradation', [0.05])
    SscApi.set_array(p_data, 'hourly_gen', e_with_system) # kWh
    SscApi.set_array(p_data, 'e_load', e_without_system) # kWh
    SscApi.set_number(p_data, 'ur_flat_buy_rate', 0.10) # $/kWh
    
    p_mod = SscApi.create_module("utilityrate2")
    # SscApi.set_print(false)
    SscApi.execute_module(p_mod, p_data)
    
    puts "Annual energy charge: $#{SscApi.get_array(p_data, 'annual_energy_value')}"
    
    ["jan", "feb", "mar", "apr", "may", "jun", "jul", "aug", "sep", "oct", "nov", "dec"].each do |month|
      monthly_bill_name = "change_ec_#{month}"
      monthly_bill_str = "#{SscApi.get_number(p_data, "change_ec_#{month}")}"      
      runner.registerValue(monthly_bill_name, monthly_bill_str)
      runner.registerInfo("Registering #{monthly_bill_str} for #{monthly_bill_name}.")    
    end
    
    return true
 
  end

end

# register the measure to be used by the application
UtilityBillCalculations.new.registerWithApplication
