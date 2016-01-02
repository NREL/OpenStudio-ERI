# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/measures/measure_writing_guide/

# start the measure
class SetResidentialEPWFile < OpenStudio::Ruleset::ModelUserScript

  # human readable name
  def name
    return "Set Residential Weather File"
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
    arg.setDescription("Absolute (or relative) directory to weather files")
	arg.setDefaultValue("C:/Program Files (x86)/NREL/BEopt_2.5.0/Weather")
    args << arg

    arg = OpenStudio::Ruleset::OSArgument.makeStringArgument('weather_file_name', true)
    arg.setDisplayName("Weather File Name")
    arg.setDescription("Name of the weather file to assign.")
	arg.setDefaultValue("USA_GA_Atlanta-Hartsfield-Jackson.Intl.AP.722190_TMY3.epw")
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
