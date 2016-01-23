#see the URL below for information on how to write OpenStudio measures
# http://openstudio.nrel.gov/openstudio-measure-writing-guide

#see your EnergyPlus installation or the URL below for information on EnergyPlus objects
# http://apps1.eere.energy.gov/buildings/energyplus/pdfs/inputoutputreference.pdf

#see the URL below for information on using life cycle cost objects in OpenStudio
# http://openstudio.nrel.gov/openstudio-life-cycle-examples

#see the URL below for access to C++ documentation on workspace objects (click on "workspace" in the main window to view workspace objects)
# http://openstudio.nrel.gov/sites/openstudio.nrel.gov/files/nv_data/cpp_documentation_it/utilities/html/idf_page.html

require "#{File.dirname(__FILE__)}/resources/weather"

#start the measure
class ProcessGroundTemperature < OpenStudio::Ruleset::WorkspaceUserScript
  
  #define the name that a user will see, this method may be deprecated as
  #the display name in PAT comes from the name field in measure.xml
  def name
    return "Set Residential Ground Temperatures"
  end
  
  def description
    return "This measure calculates ground temperatures using weather data."
  end
  
  def modeler_description
    return "This measure writes monthly ground temperatures to the EnergyPlus objects Site:GroundTemperature:BuildingSurface and Site:GroundTemperature:Deep."
  end   
  
  #define the arguments that the user will input
  def arguments(workspace)
    args = OpenStudio::Ruleset::OSArgumentVector.new
    
    return args
  end #end the arguments method

  #define what happens when the measure is run
  def run(workspace, runner, user_arguments)
    super(workspace, runner, user_arguments)
    
    #use the built-in error checking 
    if not runner.validateUserArguments(arguments(workspace), user_arguments)
      return false
    end

    weather = WeatherProcess.new(workspace,runner)
    if weather.error?
      return false
    end

    # Process the ground temperatures
    ground_temps, annual_temp = _getGroundTemperatures(weather)

    t = []

    t << "
    Site:GroundTemperature:BuildingSurface,
      #{OpenStudio::convert(ground_temps[0],"F","C").get},                    !- Jan Ground Temperature {degC}
      #{OpenStudio::convert(ground_temps[1],"F","C").get},                    !- Feb Ground Temperature {degC}
      #{OpenStudio::convert(ground_temps[2],"F","C").get},                    !- Mar Ground Temperature {degC}
      #{OpenStudio::convert(ground_temps[3],"F","C").get},                    !- Apr Ground Temperature {degC}
      #{OpenStudio::convert(ground_temps[4],"F","C").get},                    !- May Ground Temperature {degC}
      #{OpenStudio::convert(ground_temps[5],"F","C").get},                    !- Jun Ground Temperature {degC}
      #{OpenStudio::convert(ground_temps[6],"F","C").get},                    !- Jul Ground Temperature {degC}
      #{OpenStudio::convert(ground_temps[7],"F","C").get},                    !- Aug Ground Temperature {degC}
      #{OpenStudio::convert(ground_temps[8],"F","C").get},                    !- Sep Ground Temperature {degC}
      #{OpenStudio::convert(ground_temps[9],"F","C").get},                    !- Oct Ground Temperature {degC}
      #{OpenStudio::convert(ground_temps[10],"F","C").get},                   !- Nov Ground Temperature {degC}
      #{OpenStudio::convert(ground_temps[11],"F","C").get};                   !- Dec Ground Temperature {degC}"

    t << "
    Site:GroundTemperature:Deep,
      #{OpenStudio::convert(annual_temp,"F","C").get},                        !- Jan Deep Ground Temperature {C}
      #{OpenStudio::convert(annual_temp,"F","C").get},                        !- Feb Deep Ground Temperature {C}
      #{OpenStudio::convert(annual_temp,"F","C").get},                        !- Mar Deep Ground Temperature {C}
      #{OpenStudio::convert(annual_temp,"F","C").get},                        !- Apr Deep Ground Temperature {C}
      #{OpenStudio::convert(annual_temp,"F","C").get},                        !- May Deep Ground Temperature {C}
      #{OpenStudio::convert(annual_temp,"F","C").get},                        !- Jun Deep Ground Temperature {C}
      #{OpenStudio::convert(annual_temp,"F","C").get},                        !- Jul Deep Ground Temperature {C}
      #{OpenStudio::convert(annual_temp,"F","C").get},                        !- Aug Deep Ground Temperature {C}
      #{OpenStudio::convert(annual_temp,"F","C").get},                        !- Sep Deep Ground Temperature {C}
      #{OpenStudio::convert(annual_temp,"F","C").get},                        !- Oct Deep Ground Temperature {C}
      #{OpenStudio::convert(annual_temp,"F","C").get},                        !- Nov Deep Ground Temperature {C}
      #{OpenStudio::convert(annual_temp,"F","C").get};                        !- Dec Deep Ground Temperature {C}"

    t.each do |str|
      idfObject = OpenStudio::IdfObject::load(str)
      object = idfObject.get
      wsObject = workspace.addObject(object)
      runner.registerInfo("Set object '#{str.split("\n")[1].gsub(",","")} - #{str.split("\n")[2].split(",")[0]}'")
    end

    return true
 
  end #end the run method

  def _getGroundTemperatures(weather)
    # Return monthly ground temperatures.

    # This correlation is the same that is used in DOE-2's src\WTH.f file, subroutine GTEMP.
    monthly_temps = weather.data.MonthlyAvgDrybulbs
    annual_temp = weather.data.AnnualAvgDrybulb

    amon = [15.0, 46.0, 74.0, 95.0, 135.0, 166.0, 196.0, 227.0, 258.0, 288.0, 319.0, 349.0]
    po = 0.6
    dif = 0.025
    p = OpenStudio::convert(1.0,"yr","hr").get

    beta = Math::sqrt(Math::PI / (p * dif)) * 10.0
    x = Math::exp(-beta)
    x2 = x * x
    s = Math::sin(beta)
    c = Math::cos(beta)
    y = (x2 - 2.0 * x * c + 1.0) / (2.0 * beta ** 2.0)
    gm = Math::sqrt(y)
    z = (1.0 - x * (c + s)) / (1.0 - x * (c - s))
    phi = Math::atan(z)
    bo = (monthly_temps.max - monthly_temps.min) * 0.5

    ground_temps = []
    (0...12).to_a.each do |i|
      theta = amon[i] * 24.0
      ground_temps << OpenStudio::convert(annual_temp - bo * Math::cos(2.0 * Math::PI / p * theta - po - phi) * gm + 460.0,"R","F").get
    end

    return ground_temps, annual_temp

  end

  
end #end the measure

#this allows the measure to be use by the application
ProcessGroundTemperature.new.registerWithApplication