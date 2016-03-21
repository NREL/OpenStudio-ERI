#see the URL below for information on how to write OpenStudio measures
# http://openstudio.nrel.gov/openstudio-measure-writing-guide

#see the URL below for information on using life cycle cost objects in OpenStudio
# http://openstudio.nrel.gov/openstudio-life-cycle-examples

#see the URL below for access to C++ documentation on model objects (click on "model" in the main window to view model objects)
# http://openstudio.nrel.gov/sites/openstudio.nrel.gov/files/nv_data/cpp_documentation_it/model/html/namespaces.html

require "#{File.dirname(__FILE__)}/resources/util"
require "#{File.dirname(__FILE__)}/resources/constants"
require "#{File.dirname(__FILE__)}/resources/geometry"

#start the measure
class ProcessThermalMassPartitionWall < OpenStudio::Ruleset::ModelUserScript

  class PartitionWallMass
    def initialize(partitionWallMassThickness, partitionWallMassConductivity, partitionWallMassDensity, partitionWallMassSpecHeat)
      @partitionWallMassThickness = partitionWallMassThickness
      @partitionWallMassConductivity = partitionWallMassConductivity
      @partitionWallMassDensity = partitionWallMassDensity
      @partitionWallMassSpecHeat = partitionWallMassSpecHeat
    end

    def PartitionWallMassThickness
      return @partitionWallMassThickness
    end

    def PartitionWallMassConductivity
      return @partitionWallMassConductivity
    end

    def PartitionWallMassDensity
      return @partitionWallMassDensity
    end

    def PartitionWallMassSpecificHeat
      return @partitionWallMassSpecHeat
    end

    attr_accessor(:living_space_area, :finished_basement_area)
  end

  class LivingSpace
    def initialize
    end
    attr_accessor(:area)
  end

  class FinishedBasement
    def initialize
    end
    attr_accessor(:area)
  end

  #define the name that a user will see, this method may be deprecated as
  #the display name in PAT comes from the name field in measure.xml
  def name
    return "Set Residential Partition Wall Thermal Mass"
  end
  
  def description
    return "This measure assigns partition wall mass to the living space and finished basement."
  end
  
  def modeler_description
    return "This measure creates constructions representing the internal mass of partition walls in the living space and finished basement. The constructions are set to define the internal mass objects of their respective spaces."
  end    
  
  #define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Ruleset::OSArgumentVector.new

    #make a double argument for partition wall mass thickness
    partitionwallmassth = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("partitionwallmassth", false)
    partitionwallmassth.setDisplayName("Partition Wall Mass: Thickness")
	partitionwallmassth.setUnits("in")
	partitionwallmassth.setDescription("Thickness of the layer.")
    partitionwallmassth.setDefaultValue(0.5)
    args << partitionwallmassth

    #make a double argument for partition wall mass conductivity
    partitionwallmasscond = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("partitionwallmasscond", false)
    partitionwallmasscond.setDisplayName("Partition Wall Mass: Conductivity")
	partitionwallmasscond.setUnits("Btu-in/h-ft^2-R")
	partitionwallmasscond.setDescription("Conductivity of the layer.")
    partitionwallmasscond.setDefaultValue(1.1112)
    args << partitionwallmasscond

    #make a double argument for partition wall mass density
    partitionwallmassdens = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("partitionwallmassdens", false)
    partitionwallmassdens.setDisplayName("Partition Wall Mass: Density")
	partitionwallmassdens.setUnits("lb/ft^3")
	partitionwallmassdens.setDescription("Density of the layer.")
    partitionwallmassdens.setDefaultValue(50.0)
    args << partitionwallmassdens

    #make a double argument for partition wall mass specific heat
    partitionwallmasssh = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("partitionwallmasssh", false)
    partitionwallmasssh.setDisplayName("Partition Wall Mass: Specific Heat")
	partitionwallmasssh.setUnits("Btu/lb-R")
	partitionwallmasssh.setDescription("Specific heat of the layer.")
    partitionwallmasssh.setDefaultValue(0.2)
    args << partitionwallmasssh

    #make a double argument for partition wall fraction of floor area
    partitionwallfrac = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("partitionwallfrac", false)
    partitionwallfrac.setDisplayName("Partition Wall Mass: Fraction of Floor Area")
	partitionwallfrac.setDescription("Ratio of exposed partition wall area to total finished floor area and accounts for the area of both sides of partition walls.")
    partitionwallfrac.setDefaultValue(1.0)
    args << partitionwallfrac

    #make a choice argument for living space type
    space_types = model.getSpaceTypes
    space_type_args = OpenStudio::StringVector.new
    space_types.each do |space_type|
        space_type_args << space_type.name.to_s
    end
    if not space_type_args.include?(Constants.LivingSpaceType)
        space_type_args << Constants.LivingSpaceType
    end
    living_space_type = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("living_space_type", space_type_args, true)
    living_space_type.setDisplayName("Living space type")
    living_space_type.setDescription("Select the living space type")
    living_space_type.setDefaultValue(Constants.LivingSpaceType)
    args << living_space_type	
	
    #make a choice argument for finished basement space type
    space_types = model.getSpaceTypes
    space_type_args = OpenStudio::StringVector.new
    space_types.each do |space_type|
        space_type_args << space_type.name.to_s
    end
    if not space_type_args.include?(Constants.FinishedBasementSpaceType)
        space_type_args << Constants.FinishedBasementSpaceType
    end
    fbasement_space_type = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("fbasement_space_type", space_type_args, true)
    fbasement_space_type.setDisplayName("Finished basement space type")
    fbasement_space_type.setDescription("Select the finished basement space type")
    fbasement_space_type.setDefaultValue(Constants.FinishedBasementSpaceType)
    args << fbasement_space_type	
	
    return args
  end #end the arguments method

  #define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)

    #use the built-in error checking
    if not runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

    # Space Type
	living_space_type_r = runner.getStringArgumentValue("living_space_type",user_arguments)
    living_space_type = Geometry.get_space_type_from_string(model, living_space_type_r, runner)
    if living_space_type.nil?
        return false
    end
	fbasement_space_type_r = runner.getStringArgumentValue("fbasement_space_type",user_arguments)
    fbasement_space_type = Geometry.get_space_type_from_string(model, fbasement_space_type_r, runner, false)	
	
    partitionWallMassThickness = runner.getDoubleArgumentValue("partitionwallmassth",user_arguments)
    partitionWallMassConductivity = runner.getDoubleArgumentValue("partitionwallmasscond",user_arguments)
    partitionWallMassDensity = runner.getDoubleArgumentValue("partitionwallmassdens",user_arguments)
    partitionWallMassSpecificHeat = runner.getDoubleArgumentValue("partitionwallmasssh",user_arguments)
    partitionWallMassFractionOfFloorArea = runner.getDoubleArgumentValue("partitionwallfrac",user_arguments)
    
	living_space_area = 0
	finished_basement_area = 0
	living_space_area = Geometry.get_floor_area_for_space_type(model, living_space_type.handle)
	unless fbasement_space_type.nil?
		finished_basement_area = Geometry.get_floor_area_for_space_type(model, fbasement_space_type.handle)
	end

    # Constants
    mat_wood = BaseMaterial.Wood
 
    # Create the material class instances
    partition_wall_mass = PartitionWallMass.new(partitionWallMassThickness, partitionWallMassConductivity, partitionWallMassDensity, partitionWallMassSpecificHeat)

    living_space = LivingSpace.new
    finished_basement = FinishedBasement.new

    living_space.area = living_space_area
    finished_basement.area = finished_basement_area

    # Process the partition wall
    partition_wall_mass = _processThermalMassPartitionWall(partitionWallMassFractionOfFloorArea, partition_wall_mass, living_space, finished_basement)

    # Initialize variables for drawn partition wall areas
    livingPartWallDrawnArea = 0 # Drawn partition wall area of the living space
    fbsmtPartWallDrawnArea = 0 # Drawn partition wall area of the finished basement

    # Loop through all walls and find the wall area of drawn partition walls
    # for wall in Geometry.walls.wall:
    #   if wall.space_int == wall.space_ext:
    #       if wall.space_int == Constants.SpaceLiving:
    #           self.LivingPartWallDrawnArea += wall.area
    #       elif wall.space_int == Constants.SpaceFinBasement:
    #           self.FBsmtPartWallDrawnArea += wall.area
    #       # End drawn partition wall area sumation loop

    # PartitionWallMass
    pwm = OpenStudio::Model::StandardOpaqueMaterial.new(model)
    pwm.setName("PartitionWallMass")
    pwm.setRoughness("Rough")
    part_wall_mass = Material.MassPartitionWall(partitionWallMassThickness, partitionWallMassConductivity, partitionWallMassDensity, partitionWallMassSpecificHeat)
    pwm.setThickness(OpenStudio::convert(part_wall_mass.thick,"ft","m").get)
    pwm.setConductivity(OpenStudio::convert(part_wall_mass.k,"Btu/hr*ft*R","W/m*K").get)
    pwm.setDensity(OpenStudio::convert(part_wall_mass.rho,"lb/ft^3","kg/m^3").get)
    pwm.setSpecificHeat(OpenStudio::convert(part_wall_mass.cp,"Btu/lb*R","J/kg*K").get)
    pwm.setThermalAbsorptance(part_wall_mass.tAbs)
    pwm.setSolarAbsorptance(part_wall_mass.sAbs)
    pwm.setVisibleAbsorptance(part_wall_mass.vAbs)

    # StudandAirWall
    saw = OpenStudio::Model::StandardOpaqueMaterial.new(model)
    saw.setName("StudandAirWall")
    saw.setRoughness("Rough")
    saw.setThickness(OpenStudio::convert(Material.StudAndAir.thick,"ft","m").get)
    saw.setConductivity(OpenStudio::convert(Material.StudAndAir.k,"Btu/hr*ft*R","W/m*K").get)
    saw.setDensity(OpenStudio::convert(Material.StudAndAir.rho,"lb/ft^3","kg/m^3").get)
    saw.setSpecificHeat(OpenStudio::convert(Material.StudAndAir.cp,"Btu/lb*R","J/kg*K").get)

    # FinUninsFinWall
    materials = []
    materials << pwm
    materials << saw
    materials << pwm
    fufw = OpenStudio::Model::Construction.new(materials)
    fufw.setName("FinUninsFinWall")	

    # Remaining partition walls within spaces (those without geometric representation)
    lp = OpenStudio::Model::InternalMassDefinition.new(model)
    lp.setName("LivingPartition")
    lp.setConstruction(fufw)
    if partition_wall_mass.living_space_area > (livingPartWallDrawnArea * 2)
      lp.setSurfaceArea(OpenStudio::convert(partition_wall_mass.living_space_area - livingPartWallDrawnArea * 2,"ft^2","m^2").get)
    else
      lp.setSurfaceArea(OpenStudio::convert(0.001,"ft^2","m^2").get)
    end
    im = OpenStudio::Model::InternalMass.new(lp)
    im.setName("LivingPartition")
    
	im.setSpaceType(living_space_type)
	runner.registerInfo("Assigned internal mass object 'LivingPartition' to space type '#{living_space_type_r}'")

    unless fbasement_space_type.nil?
      # Remaining partition walls within spaces (those without geometric representation)
      fbp = OpenStudio::Model::InternalMassDefinition.new(model)
      fbp.setName("FBsmtPartition")
      fbp.setConstruction(fufw)
      #fbp.setZone # TODO: what is this?
      if partition_wall_mass.finished_basement_area > (fbsmtPartWallDrawnArea * 2)
        fbp.setSurfaceArea(OpenStudio::convert(partition_wall_mass.finished_basement_area - fbsmtPartWallDrawnArea * 2,"ft^2","m^2").get)
      else
        runner.registerWarning("The variable PartitionWallMassFractionOfFloorArea in the Partition Wall Mass category resulted in an area that is less than the partition wall area drawn. The mass of the drawn partition walls will be simulated, hence the variable PartitionWallMassFractionOfFloorArea will be ignored.")
        fbp.setSurfaceArea(OpenStudio::convert(0.001,"ft^2","m^2").get)
      end
      im = OpenStudio::Model::InternalMass.new(fbp)
      im.setName("FBsmtPartition")
          
	  im.setSpaceType(fbasement_space_type)
	  runner.registerInfo("Assigned internal mass object 'FBsmtPartition' to space type '#{fbasement_space_type_r}'")
    end
	
    return true

  end #end the run method

  def _processThermalMassPartitionWall(partitionWallMassFractionOfFloorArea, partition_wall_mass, living_space, finished_basement)

    # Handle Exception for user entry of zero (avoids EPlus complaining about zero value)
    if partitionWallMassFractionOfFloorArea <= 0.0
      partitionWallMassFractionOfFloorArea = 0.0001 # Set approximately to zero
    end

    # Calculate the total partition wall mass areas for finished spaces
    partition_wall_mass.living_space_area = partitionWallMassFractionOfFloorArea * living_space.area # ft^2
    partition_wall_mass.finished_basement_area = partitionWallMassFractionOfFloorArea * finished_basement.area # ft^2

    return partition_wall_mass

  end

  
end #end the measure

#this allows the measure to be use by the application
ProcessThermalMassPartitionWall.new.registerWithApplication