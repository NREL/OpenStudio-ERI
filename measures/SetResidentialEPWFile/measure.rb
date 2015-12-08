# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/measures/measure_writing_guide/

# start the measure
class SetResidentialEPWFile < OpenStudio::Ruleset::ModelUserScript

  # human readable name
  def name
    return "Set Residential EPW File"
  end

  # human readable description
  def description
    return ""
  end

  # human readable description of modeling approach
  def modeler_description
    return ""
  end

  # define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Ruleset::OSArgumentVector.new

    arg = OpenStudio::Ruleset::OSArgument.makeStringArgument('weather_directory', true)
    arg.setDisplayName("Weather Directory")
    arg.setDescription("Relative directory to weather files from analysis directory")
	arg.setDefaultValue("../../../../OpenStudio-Beopt/OpenStudio-analysis-spreadsheet/weather")
    args << arg

    arg = OpenStudio::Ruleset::OSArgument.makeStringArgument('weather_file_name', true)
    arg.setDisplayName("Weather File Name")
    arg.setDescription("Name of the weather file to change to. This is the filename with the extension (e.g. NewWeather.epw)")
	arg.setDefaultValue("USA_CO_Denver.Intl.AP.725650_TMY3.epw")
    args << arg

    return args
  end

  # define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)

    # use the built-in error checking
    if !runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

    # grab the initial weather file
    @weather_directory = runner.getStringArgumentValue("weather_directory", user_arguments)
    weather_file_name = runner.getStringArgumentValue("weather_file_name", user_arguments)

    #Add Weather File
    unless (Pathname.new @weather_directory).absolute?
      @weather_directory = File.expand_path(File.join(File.dirname(__FILE__), @weather_directory))
    end
    weather_file = File.join(@weather_directory, weather_file_name)
    if File.exists?(weather_file) and weather_file_name.downcase.include? ".epw"
        epw_file = OpenStudio::EpwFile.new(weather_file)
    else
      runner.registerError("'#{weather_file}' does not exist or is not an .epw file.")
      return false
    end	

    OpenStudio::Model::WeatherFile.setWeatherFile(model, epw_file).get
    runner.registerInfo("Setting weather file.")	

    return true

  end
  
end

# register the measure to be used by the application
SetResidentialEPWFile.new.registerWithApplication
