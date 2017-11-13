# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/reference/measure_writing_guide/

# start the measure
class BrokenMeasure < OpenStudio::Ruleset::ModelUserScript

  # human readable name
  def name
    return "BrokenMeasure"
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
    
    # make a required argument with no default, osw should run without validating that
    r_value = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("r_value",true)
    r_value.setDisplayName("Percentage Increase of R-value for Roof Insulation.")
    args << r_value
    
    return args
  end

  # define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)

    # use the built-in error checking
    if !runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

    fail "Major bad"

    return true

  end
  
end

# register the measure to be used by the application
BrokenMeasure.new.registerWithApplication
