#see the URL below for information on how to write OpenStudio measures
# TODO: Remove this link and replace with the wiki
# http://openstudio.nrel.gov/openstudio-measure-writing-guide

#see the URL below for access to C++ documentation on model objects (click on "model" in the main window to view model objects)
# http://openstudio.nrel.gov/sites/openstudio.nrel.gov/files/nv_data/cpp_documentation_it/model/html/namespaces.html

# Author: Nicholas Long
# Simple measure to load the EPW file and DDY file
require "#{File.dirname(__FILE__)}/resources/stat_file"

class SetDRWeatherFile < OpenStudio::Ruleset::ModelUserScript

  #define the name that a user will see, this method may be deprecated as
  #the display name in PAT comes from the name field in measure.xml
  def name
    'Set DR Weather File'
  end

  #define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Ruleset::OSArgumentVector.new

    weather_directory_name = OpenStudio::Ruleset::OSArgument.makeStringArgument('weather_directory_name', true)
    weather_directory_name.setDisplayName("Weather Directory")
    weather_directory_name.setDescription("Relative directory to weather files from analysis directory")
    weather_directory_name.setUnits('')
    args << weather_directory_name

    weather_file_name = OpenStudio::Ruleset::OSArgument.makeStringArgument('weather_file_name', true)
    weather_file_name.setDisplayName("Weather File Name")
    weather_file_name.setDescription("Name of the weater file to be used, including extension. Should be .epw file.")
    weather_file_name.setUnits('')
    args << weather_file_name
    args
  end

  # Define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)

    #use the built-in error checking 
    if not runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

    # grab the initial weather file
    weather_directory_name = runner.getStringArgumentValue("weather_directory_name", user_arguments)
    weather_file_name = runner.getStringArgumentValue("weather_file_name", user_arguments)

    #Add Weather File
    run_dir_file = File.absolute_path(File.join(Dir.pwd, '../..', weather_file_name))
    weather_file = File.absolute_path(File.join(Dir.pwd, '../../..', weather_directory_name, weather_file_name))
    if File.exists?(weather_file) and weather_file_name.downcase.include? ".epw"
        FileUtils.cp(weather_file, run_dir_file)
    else
      runner.registerError("'#{weather_file}' does not exist or is not an .epw file. weater_file: #{weather_file}; run_dir_file: #{run_dir_file}")
      return false
    end

    runner.registerInfo("Weather file copied from #{weather_file} #{run_dir_file}")

    true
  end
end

# This allows the measure to be use by the application
SetDRWeatherFile.new.registerWithApplication