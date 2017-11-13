
class EpChangeWeatherFile2 < OpenStudio::Ruleset::WorkspaceUserScript
  
  #define the name that a user will see, this method may be deprecated as
  #the display name in PAT comes from the name field in measure.xml
  def name
    return "EpChangeWeatherFile2"
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

    error = false
    old_file = 'in.epw'
    run_dir = runner.workflow.absoluteRunDir.to_s
    
    # last translation to idf set weather file to 'in.epw' in run dir
    last_epw_path = runner.lastEpwFilePath
    if last_epw_path.empty?
      runner.registerError("lastEpwFilePath is empty")   
      return false
    else
      file_name = File.basename(last_epw_path.get.to_s)
      if file_name != old_file
        runner.registerError("Expected weather file '#{old_file}' but got '#{file_name}'")
        return false
      end
      
      file_dir = File.dirname(last_epw_path.get.to_s)
      if Pathname.new(file_dir).realpath.to_s != Pathname.new(run_dir).realpath.to_s
        runner.registerError("Expected weather file dir '#{run_dir}' but got '#{file_dir}'")
        return false
      end
    end
    
    # load EPW and make sure it is tampa
    epwFile = OpenStudio::EpwFile.load(last_epw_path.get.to_s)
    if epwFile.empty?
      runner.registerError("Cannot load epw file '#{last_epw_path.get.to_s}'")
      return false
    end
    
    if epwFile.get.city != "Chicago Ohare Intl Ap"
      runner.registerError("Expected city 'Chicago Ohare Intl Ap' in epw file but got '#{epwFile.get.city}'")
      return false
    end
    
    return true
 
  end #end the run method

end #end the measure

#this allows the measure to be use by the application
EpChangeWeatherFile2.new.registerWithApplication