#start the measure
class SetWeatherFile < OpenStudio::Ruleset::ModelUserScript

  #define the name that a user will see
  def name
    return "SetWeatherFile"
  end

  #define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Ruleset::OSArgumentVector.new

    return args
  end #end the arguments method

  #define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)

    #use the built-in error checking
    if not runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

    epw_file_path = File.join(File.dirname(__FILE__), "resources/srrl_2013_amy.epw")
    epw_file = OpenStudio::EpwFile.load(epw_file_path).get
    OpenStudio::Model::WeatherFile.setWeatherFile(model, epw_file)
    
    return true

  end #end the run method

end #end the measure

#this allows the measure to be used by the application
SetWeatherFile.new.registerWithApplication
