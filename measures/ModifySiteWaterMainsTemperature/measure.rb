#see the URL below for information on how to write OpenStudio measures
# http://openstudio.nrel.gov/openstudio-measure-writing-guide

#see the URL below for information on using life cycle cost objects in OpenStudio
# http://openstudio.nrel.gov/openstudio-life-cycle-examples

#see the URL below for access to C++ documentation on model objects (click on "model" in the main window to view model objects)
# http://openstudio.nrel.gov/sites/openstudio.nrel.gov/files/nv_data/cpp_documentation_it/model/html/namespaces.html

#load weather.rb
require "#{File.dirname(__FILE__)}/resources/weather"

class ModifySiteWaterMainsTemperature < OpenStudio::Ruleset::ModelUserScript
  
  def name
    return "ModifySiteWaterMainsTemperature"
  end
  
  def description
    return "This measure calculates mains water temperatures using weather data."
  end
  
  def modeler_description
    return "This measure creates or modifies the Site:MainsWaterTemperature object. It currently uses the correlation method, but should be updated to write daily schedules to avoid issues in the southern hemisphere."
  end   
  
  def arguments(model)
    args = OpenStudio::Ruleset::OSArgumentVector.new
    
    return args
  end # arguments 

  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)
  
	@model = nil
	@weather = nil
	unless model.nil?
	  @model = model
	end
	unless runner.nil?
	  begin # Spreadsheet
		#former_workflow_arguments = runner.former_workflow_arguments
		#weather_file_name = former_workflow_arguments["setdrweatherfile"]["weather_file_name"]
		#weather_file_dir = former_workflow_arguments["setdrweatherfile"]["weather_directory_name"]
		weather_file_name = "USA_CO_Denver.Intl.AP.725650_TMY3.epw"
		weather_file_dir = "weather"
		epw_path = File.absolute_path(File.join(__FILE__.gsub('sim.rb', ''), '../../..', weather_file_dir, weather_file_name))
		@weather = WeatherProcess.new(epw_path)
	  rescue # PAT
		if runner.lastEpwFilePath.is_initialized
		  test = runner.lastEpwFilePath.get.to_s
		  if File.exist?(test)
			epw_path = test
			@weather = WeatherProcess.new(epw_path)
		  end
		end
	  end
	end
	unless @weather.nil?
	  runner.registerInfo("EPW weather path set to #{epw_path}")
	else
	  runner.registerInfo("EPW weather path was NOT set")
	end
  
	avgOAT = OpenStudio::convert(@weather.data.AnnualAvgDrybulb,"F","C").get
	monthlyOAT = @weather.data.MonthlyAvgDrybulbs
	
	min_temp = monthlyOAT.min
	max_temp = monthlyOAT.max
	
	maxDiffOAT = OpenStudio::convert(max_temp,"F","C").get - OpenStudio::convert(min_temp,"F","C").get
		
    swmt = model.getSiteWaterMainsTemperature
        
    swmt.setCalculationMethod "Correlation"
    swmt.setAnnualAverageOutdoorAirTemperature avgOAT
    swmt.setMaximumDifferenceInMonthlyAverageOutdoorAirTemperatures  maxDiffOAT
        
    runner.registerFinalCondition("SiteWaterMainsTemperature has been updated with"+
                                  "an average temperature of #{avgOAT.round(1)} C "+
                                  " and a range of #{maxDiffOAT.round(1)} C")

	return true
	
  end # run 
  
end # ModifySiteWaterMainsTemperature

#this allows the measure to be use by the application
ModifySiteWaterMainsTemperature.new.registerWithApplication