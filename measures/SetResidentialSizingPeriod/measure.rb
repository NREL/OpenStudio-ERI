# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/measures/measure_writing_guide/

# start the measure
class SetResidentialSizingPeriod < OpenStudio::Ruleset::WorkspaceUserScript

  # human readable name
  def name
    return "Set Residential Sizing Period"
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
  def arguments(workspace)
    args = OpenStudio::Ruleset::OSArgumentVector.new

    return args
  end 

  # define what happens when the measure is run
  def run(workspace, runner, user_arguments)
    super(workspace, runner, user_arguments)

    # use the built-in error checking 
    if !runner.validateUserArguments(arguments(workspace), user_arguments)
      return false
    end
    
    # _processSimulationControl
    simulation_controls = workspace.getObjectsByType("SimulationControl".to_IddObjectType)
	simulation_controls.each do |simulation_control|
	  simulation_control.setString(0, "Yes") # Do Zone Sizing Calculation
	  simulation_control.setString(1, "No") # Do System Sizing Calculation
	  simulation_control.setString(2, "Yes") # Do Plant Sizing Calculation
	  simulation_control.setString(3, "No") # Run Simulation for Sizing Periods
	end	    

	# _processRunSizingPeriod
	obj = []
	
    obj << "
    SizingPeriod:WeatherFileDays,
      Plant DD,                                        	!- Name
      1,                                   				!- Begin Month
      1,                                                !- Begin Day of Month
      1,                                                !- End Month
      1,                                                !- End Day of Month
      Tuesday,                                          !- Day of Week for Start Day
      Yes,                                              !- Use Weather File Daylight Saving Period
      No;                                               !- Use Weather File Rain and Snow Indicators"	
	
    obj << "
    RunPeriodControl:DaylightSavingTime,
      April 7,                                   		!- Start Date
      October 26;                                       !- End Date"	
	
    obj.each do |str|
      idfObject = OpenStudio::IdfObject::load(str)
      object = idfObject.get
      wsObject = workspace.addObject(object)
      runner.registerInfo("Set object '#{str.split("\n")[1].gsub(",","")} - #{str.split("\n")[2].split(",")[0]}'")
    end
	
    return true
 
  end

end 

# register the measure to be used by the application
SetResidentialSizingPeriod.new.registerWithApplication
