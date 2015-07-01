#see the URL below for information on how to write OpenStudio measures
# http://openstudio.nrel.gov/openstudio-measure-writing-guide

#see your EnergyPlus installation or the URL below for information on EnergyPlus objects
# http://apps1.eere.energy.gov/buildings/energyplus/pdfs/inputoutputreference.pdf

#see the URL below for information on using life cycle cost objects in OpenStudio
# http://openstudio.nrel.gov/openstudio-life-cycle-examples

#see the URL below for access to C++ documentation on workspace objects (click on "workspace" in the main window to view workspace objects)
# http://openstudio.nrel.gov/sites/openstudio.nrel.gov/files/nv_data/cpp_documentation_it/utilities/html/idf_page.html

#load sim.rb
require "#{File.dirname(__FILE__)}/resources/sim"

#start the measure
class ProcessGroundTemperature < OpenStudio::Ruleset::WorkspaceUserScript
  
  #define the name that a user will see, this method may be deprecated as
  #the display name in PAT comes from the name field in measure.xml
  def name
    return "ProcessGroundTemperature"
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

    # Create the sim object
    sim = Sim.new(workspace)

    # Process the ground temperatures
    ground_temps, annual_temp = sim._getGroundTemperatures

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

end #end the measure

#this allows the measure to be use by the application
ProcessGroundTemperature.new.registerWithApplication