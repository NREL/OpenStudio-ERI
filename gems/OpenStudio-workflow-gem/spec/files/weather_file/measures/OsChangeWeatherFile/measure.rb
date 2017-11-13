
class OsChangeWeatherFile < OpenStudio::Ruleset::ModelUserScript

  #define the name that a user will see
  def name
    return "OsChangeWeatherFile"
  end

  #define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Ruleset::OSArgumentVector.new

    return args
  end #end the arguments method
  
  def check_model_weather_file(model, runner, expected)
    error = false
    
    weather_file = model.getOptionalWeatherFile
    if weather_file.empty?
      error = true
      runner.registerError("Empty weather file in model")
    else
      weather_file_path = weather_file.get.path
      if weather_file_path.empty?
        error = true
        runner.registerError("Empty weather file path in model")
      else
        file_name = File.basename(weather_file_path.get.to_s)
        if file_name != expected
          error = true
          runner.registerError("Expected weather file '#{expected}' in model but got '#{file_name}'")
        end
      end
    end
    
    return error
  end
  
  def check_workflow_weather_file(workflow_json, runner, expected)
    error = false
    
    weather_file_path = workflow_json.weatherFile
    if weather_file_path.empty?
      error = true
      runner.registerError("Empty weather file in OSW")    
    else
      file_name = File.basename(weather_file_path.get.to_s)
      if file_name != expected
        error = true
        runner.registerError("Expected weather file '#{expected}' in OSW but got '#{file_name}'")
      end
    end
    
    return error
  end
  
  #define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)

    #use the built-in error checking
    if not runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end
    
    error = false
    old_file = 'USA_CA_San.Francisco.Intl.AP.724940_TMY3.epw'
    
    # initial model was loaded with Golden weather file
    # osw overrode that with San Francisco weather file
    last_epw_path = runner.lastEpwFilePath
    if last_epw_path.empty?
      error = true
      runner.registerError("lastEpwFilePath is empty")   
    else
      file_name = File.basename(last_epw_path.get.to_s)
      if file_name != old_file
        error = true
        runner.registerError("Expected weather file '#{old_file}' in OSW but got '#{file_name}'")
      end
    end

    error = check_model_weather_file(model, runner, old_file) || error
    
    begin
      error = check_workflow_weather_file(model.workflowJSON, runner, old_file) || error
    rescue
      # OS 1.x
    end
    
    error = check_workflow_weather_file(runner.workflow, runner, old_file) || error

    # now change the weather file
    new_file = 'USA_FL_Tampa.Intl.AP.722110_TMY3.epw'
    weather_file_path = runner.workflow.findFile(new_file)
    
    if weather_file_path.empty?
      error = true
      runner.registerError("Cannot find '#{new_file}'")    
    else
      epwFile = OpenStudio::EpwFile.load(weather_file_path.get)
      if epwFile.empty?
        error = true
        runner.registerError("Cannot load '#{new_file}'")    
      else
        OpenStudio::Model::WeatherFile.setWeatherFile(model, epwFile.get)
      end
    end
    
    # model shows the new weather file
    error = check_model_weather_file(model, runner, new_file) || error
    
    # workflow still shows the old weather file
    begin
      error = check_workflow_weather_file(model.workflowJSON, runner, old_file) || error
    rescue
      # OS 1.x
    end
    
    error = check_workflow_weather_file(runner.workflow, runner, old_file) || error
    
    if error
      return false
    end
    
    return true

  end #end the run method

end #end the measure

#this allows the measure to be used by the application
OsChangeWeatherFile.new.registerWithApplication
