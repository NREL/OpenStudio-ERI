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
	
    @weather = WeatherProcess.new(model,runner)
    if @weather.error?
      return false
    end

	avgOAT = OpenStudio::convert(@weather.data.AnnualAvgDrybulb,"F","C").get
	monthlyOAT = @weather.data.MonthlyAvgDrybulbs
	
	min_temp = monthlyOAT.min
	max_temp = monthlyOAT.max
	
	maxDiffOAT = OpenStudio::convert(max_temp,"F","C").get - OpenStudio::convert(min_temp,"F","C").get
	
	#Calc annual average mains temperature to report
	daily_mains, monthly_mains, annual_mains = WeatherProcess._calc_mains_temperature(@weather.data, @weather.header)
		
    swmt = model.getSiteWaterMainsTemperature
        
    swmt.setCalculationMethod "Correlation"
    swmt.setAnnualAverageOutdoorAirTemperature avgOAT
    swmt.setMaximumDifferenceInMonthlyAverageOutdoorAirTemperatures  maxDiffOAT
        
    runner.registerFinalCondition("SiteWaterMainsTemperature has been updated with an average temperature of #{annual_mains.round(1)} F ")
                                  

	return true
	
  end # run 
  
end # ModifySiteWaterMainsTemperature

#this allows the measure to be use by the application
ModifySiteWaterMainsTemperature.new.registerWithApplication