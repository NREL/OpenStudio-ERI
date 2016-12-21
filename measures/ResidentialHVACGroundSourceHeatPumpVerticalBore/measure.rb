# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/reference/measure_writing_guide/

require "#{File.dirname(__FILE__)}/resources/constants"
require "#{File.dirname(__FILE__)}/resources/geometry"

# start the measure
class ProcessGroundSourceHP < OpenStudio::Ruleset::ModelUserScript

  # human readable name
  def name
    return "Set Residential Ground Source Heat Pump Vertical Bore"
  end

  # human readable description
  def description
    return "This measure..."
  end

  # human readable description of modeling approach
  def modeler_description
    return "Uses..."
  end

  # define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Ruleset::OSArgumentVector.new

    #make a double argument for gshp vert bore cop
    gshpVertBoreCOP = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("gshpVertBoreCOP", true)
    gshpVertBoreCOP.setDisplayName("COP")
    gshpVertBoreCOP.setUnits("W/W")
    gshpVertBoreCOP.setDescription("User can use ...")
    gshpVertBoreCOP.setDefaultValue(3.6)
    args << gshpVertBoreCOP
    
    #make a double argument for gshp vert bore eer
    gshpVertBoreEER = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("gshpVertBoreEER", true)
    gshpVertBoreEER.setDisplayName("EER")
    gshpVertBoreEER.setUnits("Btu/W-h")
    gshpVertBoreEER.setDescription("This is a measure of the ...")
    gshpVertBoreEER.setDefaultValue(16.6)
    args << gshpVertBoreEER
    
    #make a double argument for gshp vert bore ground conductivity
    gshpVertBoreGroundCond = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("gshpVertBoreGroundCond", true)
    gshpVertBoreGroundCond.setDisplayName("Ground Conductivity")
    gshpVertBoreGroundCond.setUnits("Btu/hr-ft-R")
    gshpVertBoreGroundCond.setDescription("")
    gshpVertBoreGroundCond.setDefaultValue(0.6)
    args << gshpVertBoreGroundCond
    
    #make a double argument for gshp vert bore grout conductivity
    gshpVertBoreGroutCond = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("gshpVertBoreGroutCond", true)
    gshpVertBoreGroutCond.setDisplayName("Grout Conductivity")
    gshpVertBoreGroutCond.setUnits("Btu/hr-ft-R")
    gshpVertBoreGroutCond.setDescription("")
    gshpVertBoreGroutCond.setDefaultValue(0.4)
    args << gshpVertBoreGroutCond

    #make a double argument for gshp vert bore spacing
    gshpVertBoreSpacing = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("gshpVertBoreSpacing", true)
    gshpVertBoreSpacing.setDisplayName("Bore Spacing")
    gshpVertBoreSpacing.setUnits("ft")
    gshpVertBoreSpacing.setDescription("")
    gshpVertBoreSpacing.setDefaultValue(20.0)
    args << gshpVertBoreSpacing
    
    #make a double argument for gshp vert bore diameter
    gshpVertBoreDia = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("gshpVertBoreDia", true)
    gshpVertBoreDia.setDisplayName("Bore Diameter")
    gshpVertBoreDia.setUnits("in")
    gshpVertBoreDia.setDescription("")
    gshpVertBoreDia.setDefaultValue(5.0)
    args << gshpVertBoreDia
    
    #make a double argument for gshp vert bore nominal pipe size
    gshpVertBorePipeSize = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("gshpVertBorePipeSize", true)
    gshpVertBorePipeSize.setDisplayName("Nominal Pipe Size")
    gshpVertBorePipeSize.setUnits("in")
    gshpVertBorePipeSize.setDescription("")
    gshpVertBorePipeSize.setDefaultValue(0.75)
    args << gshpVertBorePipeSize
    
    #make a double argument for gshp vert bore ground diffusivity
    gshpVertBoreGroundDiff = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("gshpVertBoreGroundDiff", true)
    gshpVertBoreGroundDiff.setDisplayName("Ground Diffusivity")
    gshpVertBoreGroundDiff.setUnits("ft^2/hr")
    gshpVertBoreGroundDiff.setDescription("")
    gshpVertBoreGroundDiff.setDefaultValue(0.0208)
    args << gshpVertBoreGroundDiff
    
    #make a double argument for gshp vert bore frac glycol
    gshpVertBoreFracGlycol = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("gshpVertBoreFracGlycol", true)
    gshpVertBoreFracGlycol.setDisplayName("Fraction Glycol")
    gshpVertBoreFracGlycol.setUnits("frac")
    gshpVertBoreFracGlycol.setDescription("")
    gshpVertBoreFracGlycol.setDefaultValue(0.3)
    args << gshpVertBoreFracGlycol
    
    #make a double argument for gshp vert bore ground loop design delta temp
    gshpVertBoreDTDesign = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("gshpVertBoreDTDesign", true)
    gshpVertBoreDTDesign.setDisplayName("Ground Loop Design Delta Temp")
    gshpVertBoreDTDesign.setUnits("deg F")
    gshpVertBoreDTDesign.setDescription("")
    gshpVertBoreDTDesign.setDefaultValue(10.0)
    args << gshpVertBoreDTDesign
    
    #make a double argument for gshp vert bore pump head
    gshpVertBorePumpHead = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("gshpVertBorePumpHead", true)
    gshpVertBorePumpHead.setDisplayName("Pump Head")
    gshpVertBorePumpHead.setUnits("ft of water")
    gshpVertBorePumpHead.setDescription("")
    gshpVertBorePumpHead.setDefaultValue(50.0)
    args << gshpVertBorePumpHead
    
    #make a double argument for gshp vert bore u tube leg sep
    gshpVertBoreUTubeLegSep = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("gshpVertBoreUTubeLegSep", true)
    gshpVertBoreUTubeLegSep.setDisplayName("U Tube Leg Separation")
    gshpVertBoreUTubeLegSep.setUnits("in")
    gshpVertBoreUTubeLegSep.setDescription("")
    gshpVertBoreUTubeLegSep.setDefaultValue(0.9661)
    args << gshpVertBoreUTubeLegSep
    
    #make a double argument for gshp vert bore rated shr
    gshpVertBoreRatedSHR = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("gshpVertBoreRatedSHR", true)
    gshpVertBoreRatedSHR.setDisplayName("Rated SHR")
    gshpVertBoreRatedSHR.setDescription("")
    gshpVertBoreRatedSHR.setDefaultValue(0.732)
    args << gshpVertBoreRatedSHR
    
    #make a double argument for gshp vert bore supply fan power
    gshpVertBoreSupplyFanPower = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("gshpVertBoreSupplyFanPower", true)
    gshpVertBoreSupplyFanPower.setDisplayName("Supply Fan Power")
    gshpVertBoreUTubeLegSep.setUnits("W/cfm")
    gshpVertBoreSupplyFanPower.setDescription("")
    gshpVertBoreSupplyFanPower.setDefaultValue(0.5)
    args << gshpVertBoreSupplyFanPower    
    
    return args
  end

  # define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)

    # use the built-in error checking
    if !runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

    gshpVertBoreCOP = runner.getDoubleArgumentValue("gshpVertBoreCOP",user_arguments)
    gshpVertBoreEER = runner.getDoubleArgumentValue("gshpVertBoreEER",user_arguments)
    gshpVertBoreGroundCond = runner.getDoubleArgumentValue("gshpVertBoreGroundCond",user_arguments)
    gshpVertBoreGroutCond = runner.getDoubleArgumentValue("gshpVertBoreGroutCond",user_arguments)
    gshpVertBoreSpacing = runner.getDoubleArgumentValue("gshpVertBoreSpacing",user_arguments)
    gshpVertBoreDia = runner.getDoubleArgumentValue("gshpVertBoreDia",user_arguments)
    gshpVertBorePipeSize = runner.getDoubleArgumentValue("gshpVertBorePipeSize",user_arguments)
    gshpVertBoreGroundDiff = runner.getDoubleArgumentValue("gshpVertBoreGroundDiff",user_arguments)
    gshpVertBoreFracGlycol = runner.getDoubleArgumentValue("gshpVertBoreFracGlycol",user_arguments)
    gshpVertBoreDTDesign = runner.getDoubleArgumentValue("gshpVertBoreDTDesign",user_arguments)
    gshpVertBorePumpHead = runner.getDoubleArgumentValue("gshpVertBorePumpHead",user_arguments)
    gshpVertBoreUTubeLegSep = runner.getDoubleArgumentValue("gshpVertBoreUTubeLegSep",user_arguments)
    gshpVertBoreRatedSHR = runner.getDoubleArgumentValue("gshpVertBoreRatedSHR",user_arguments)
    gshpVertBoreSupplyFanPower = runner.getDoubleArgumentValue("gshpVertBoreSupplyFanPower",user_arguments)

    # Get building units
    units = Geometry.get_building_units(model, runner)
    if units.nil?
      return false
    end
    
    units.each do |unit|
    
      obj_name = Constants.ObjectNameGroundSourceHeatPumpVerticalBore(unit.name.to_s)
    
    end
    
    return true

  end
  
end

# register the measure to be used by the application
ProcessGroundSourceHP.new.registerWithApplication
