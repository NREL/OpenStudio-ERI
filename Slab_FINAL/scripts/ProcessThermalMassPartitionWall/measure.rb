#see the URL below for information on how to write OpenStudio measures
# http://openstudio.nrel.gov/openstudio-measure-writing-guide

#see the URL below for information on using life cycle cost objects in OpenStudio
# http://openstudio.nrel.gov/openstudio-life-cycle-examples

#see the URL below for access to C++ documentation on model objects (click on "model" in the main window to view model objects)
# http://openstudio.nrel.gov/sites/openstudio.nrel.gov/files/nv_data/cpp_documentation_it/model/html/namespaces.html

#load sim.rb
require "#{File.dirname(__FILE__)}/resources/sim"

#start the measure
class ProcessThermalMassPartitionWall < OpenStudio::Ruleset::ModelUserScript

  class PartitionWallMass
    def initialize(partitionWallMassThickness, partitionWallMassConductivity, partitionWallMassDensity, partitionWallMassSpecHeat, partitionWallMassPCMType)
      @partitionWallMassThickness = partitionWallMassThickness
      @partitionWallMassConductivity = partitionWallMassConductivity
      @partitionWallMassDensity = partitionWallMassDensity
      @partitionWallMassSpecHeat = partitionWallMassSpecHeat
      @partitionWallMassPCMType = partitionWallMassPCMType
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

    def PartitionWallMassPCMType
      return @partitionWallMassPCMType
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
    return "ProcessThermalMassPartitionWall"
  end
  
  #define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Ruleset::OSArgumentVector.new

    #make a choice argument for model objects
    spacetype_handles = OpenStudio::StringVector.new
    spacetype_display_names = OpenStudio::StringVector.new

    #putting model object and names into hash
    spacetype_args = model.getSpaceTypes
    spacetype_args_hash = {}
    spacetype_args.each do |spacetype_arg|
      spacetype_args_hash[spacetype_arg.name.to_s] = spacetype_arg
    end

    #looping through sorted hash of model objects
    spacetype_args_hash.sort.map do |key,value|
      spacetype_handles << value.handle.to_s
      spacetype_display_names << key
    end

    #make a choice argument for living
    selected_living = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("selectedliving", spacetype_handles, spacetype_display_names, true)
    selected_living.setDisplayName("Of what space type is the living space?")
    args << selected_living

    #make a choice argument for crawlspace
    selected_fbsmt = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("selectedfbsmt", spacetype_handles, spacetype_display_names, false)
    selected_fbsmt.setDisplayName("Of what space type is the finished basement?")
    args << selected_fbsmt

    #make a choice argument for model objects
    material_handles = OpenStudio::StringVector.new
    material_display_names = OpenStudio::StringVector.new

    #putting model object and names into hash
    material_args = model.getStandardOpaqueMaterials
    material_args_hash = {}
    material_args.each do |material_arg|
      material_args_hash[material_arg.name.to_s] = material_arg
    end

    #looping through sorted hash of model objects
    material_args_hash.sort.map do |key,value|
      material_handles << value.handle.to_s
      material_display_names << key
    end

    # #make a choice argument for partition wall mass
    # selected_partitionwallmass = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("selectedpartitionwallmass", material_handles, material_display_names, false)
    # selected_partitionwallmass.setDisplayName("Partition wall mass. For manually entering partition wall mass properties, leave blank.")
    # args << selected_partitionwallmass

    #make a double argument for partition wall mass thickness
    userdefined_partitionwallmassth = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedpartitionwallmassth", false)
    userdefined_partitionwallmassth.setDisplayName("Partition wall mass thickness [in].")
    userdefined_partitionwallmassth.setDefaultValue(0.5)
    args << userdefined_partitionwallmassth

    #make a double argument for partition wall mass conductivity
    userdefined_partitionwallmasscond = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedpartitionwallmasscond", false)
    userdefined_partitionwallmasscond.setDisplayName("Partition wall mass conductivity [Btu-in/h-ft^2-R].")
    userdefined_partitionwallmasscond.setDefaultValue(1.1112)
    args << userdefined_partitionwallmasscond

    #make a double argument for partition wall mass density
    userdefined_partitionwallmassdens = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedpartitionwallmassdens", false)
    userdefined_partitionwallmassdens.setDisplayName("Partition wall mass density [lb/ft^3].")
    userdefined_partitionwallmassdens.setDefaultValue(50.0)
    args << userdefined_partitionwallmassdens

    #make a double argument for partition wall mass specific heat
    userdefined_partitionwallmasssh = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedpartitionwallmasssh", false)
    userdefined_partitionwallmasssh.setDisplayName("Partition wall mass specific heat [Btu/lb-R].")
    userdefined_partitionwallmasssh.setDefaultValue(0.2)
    args << userdefined_partitionwallmasssh

    #make a double argument for partition wall fraction of floor area
    userdefined_partitionwallfrac = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedpartitionwallfrac", false)
    userdefined_partitionwallfrac.setDisplayName("Ratio of exposed partition wall area to total conditioned floor area and accounts for the area of both sides of partition walls.")
    userdefined_partitionwallfrac.setDefaultValue(1.0)
    args << userdefined_partitionwallfrac

    # Geometry
    userdefinedlivingarea = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedlivingarea", true)
    userdefinedlivingarea.setDisplayName("The area of the living space [ft^2].")
    userdefinedlivingarea.setDefaultValue(2700.0)
    args << userdefinedlivingarea

    userdefinedfbsmtarea = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedfbsmtarea", true)
    userdefinedfbsmtarea.setDisplayName("The area of the finished basement [ft^2].")
    userdefinedfbsmtarea.setDefaultValue(1200.0)
    args << userdefinedfbsmtarea

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
    selected_living = runner.getOptionalWorkspaceObjectChoiceValue("selectedliving",user_arguments,model)
    selected_fbsmt = runner.getOptionalWorkspaceObjectChoiceValue("selectedfbsmt",user_arguments,model)

    # loop thru all the spaces
    hasFinishedBasement = false
    if not selected_fbsmt.empty?
      hasFinishedBasement = true
    end

    # Partition Wall Mass
    selected_partitionwallmass = runner.getOptionalWorkspaceObjectChoiceValue("selectedpartitionwallmass",user_arguments,model)
    if selected_partitionwallmass.empty?
      userdefined_partitionwallmassth = runner.getDoubleArgumentValue("userdefinedpartitionwallmassth",user_arguments)
      userdefined_partitionwallmasscond = runner.getDoubleArgumentValue("userdefinedpartitionwallmasscond",user_arguments)
      userdefined_partitionwallmassdens = runner.getDoubleArgumentValue("userdefinedpartitionwallmassdens",user_arguments)
      userdefined_partitionwallmasssh = runner.getDoubleArgumentValue("userdefinedpartitionwallmasssh",user_arguments)
    end

    # Constants
    constants = Constants.new
    mat_wood = get_mat_wood

    # Partition Wall Mass
    if userdefined_partitionwallmassth.nil?
      partitionWallMassThickness = OpenStudio::convert(selected_partitionwallmass.get.to_StandardOpaqueMaterial.get.getThickness.value,"m","in").get
      partitionWallMassConductivity = OpenStudio::convert(selected_partitionwallmass.get.to_StandardOpaqueMaterial.get.getConductivity.value,"W/m*K","Btu/hr*ft*R").get
      partitionWallMassDensity = OpenStudio::convert(selected_partitionwallmass.get.to_StandardOpaqueMaterial.get.getDensity.value,"kg/m^3","lb/ft^3").get
      partitionWallMassSpecificHeat = OpenStudio::convert(selected_partitionwallmass.get.to_StandardOpaqueMaterial.get.getSpecificHeat.value,"J/kg*K","Btu/lb*R").get
    else
      partitionWallMassThickness = userdefined_partitionwallmassth
      partitionWallMassConductivity = userdefined_partitionwallmasscond
      partitionWallMassDensity = userdefined_partitionwallmassdens
      partitionWallMassSpecificHeat = userdefined_partitionwallmasssh
    end

    partitionWallMassFractionOfFloorArea = runner.getDoubleArgumentValue("userdefinedpartitionwallfrac",user_arguments)

    partitionWallMassPCMType = nil

    # Create the material class instances
    partition_wall_mass = PartitionWallMass.new(partitionWallMassThickness, partitionWallMassConductivity, partitionWallMassDensity, partitionWallMassSpecificHeat, partitionWallMassPCMType)

    # Create the sim object
    sim = Sim.new(model)
    living_space = LivingSpace.new
    finished_basement = FinishedBasement.new

    living_space.area = runner.getDoubleArgumentValue("userdefinedlivingarea",user_arguments)
    finished_basement.area = runner.getDoubleArgumentValue("userdefinedfbsmtarea",user_arguments)

    # Process the partition wall
    partition_wall_mass = sim._processThermalMassPartitionWall(partitionWallMassFractionOfFloorArea, partition_wall_mass, living_space, finished_basement)

    # Initialize variables for drawn partition wall areas
    livingPartWallDrawnArea = 0 # Drawn partition wall area of the living space
    fbsmtPartWallDrawnArea = 0 # Drawn partition wall area of the finished basement

    # Loop through all walls and find the wall area of drawn partition walls
    # for wall in geometry.walls.wall:
    #   if wall.space_int == wall.space_ext:
    #       if wall.space_int == Constants.SpaceLiving:
    #           self.LivingPartWallDrawnArea += wall.area
    #       elif wall.space_int == Constants.SpaceFinBasement:
    #           self.FBsmtPartWallDrawnArea += wall.area
    #       # End drawn partition wall area sumation loop

    # temp
    livingPartWallDrawnArea = partition_wall_mass.living_space_area / 2.0
    fbsmtPartWallDrawnArea = partition_wall_mass.finished_basement_area / 2.0
    #

    # ConcPCMPartWall
    if partition_wall_mass.PartitionWallMassPCMType == constants.PCMtypeConcentrated
      pcm = OpenStudio::Model::StandardOpaqueMaterial.new(model)
      pcm.setName("ConcPCMPartWall")
      pcm.setRoughness("Rough")
      pcm.setThickness(OpenStudio::convert(get_mat_part_pcm_conc(get_mat_part_pcm(partition_wall_mass), partition_wall_mass).thick,"ft","m").get)
      pcm.setConductivity()
      pcm.setDensity()
      pcm.setSpecificHeat()
    end

    # PartitionWallMass
    pwm = OpenStudio::Model::StandardOpaqueMaterial.new(model)
    pwm.setName("PartitionWallMass")
    pwm.setRoughness("Rough")
    pwm.setThickness(OpenStudio::convert(get_mat_partition_wall_mass(partition_wall_mass).thick,"ft","m").get)
    pwm.setConductivity(OpenStudio::convert(get_mat_partition_wall_mass(partition_wall_mass).k,"Btu/hr*ft*R","W/m*K").get)
    pwm.setDensity(OpenStudio::convert(get_mat_partition_wall_mass(partition_wall_mass).rho,"lb/ft^3","kg/m^3").get)
    pwm.setSpecificHeat(OpenStudio::convert(get_mat_partition_wall_mass(partition_wall_mass).Cp,"Btu/lb*R","J/kg*K").get)
    pwm.setThermalAbsorptance(get_mat_partition_wall_mass(partition_wall_mass).TAbs)
    pwm.setSolarAbsorptance(get_mat_partition_wall_mass(partition_wall_mass).SAbs)
    pwm.setVisibleAbsorptance(get_mat_partition_wall_mass(partition_wall_mass).VAbs)

    # StudandAirWall
    saw = OpenStudio::Model::StandardOpaqueMaterial.new(model)
    saw.setName("StudandAirWall")
    saw.setRoughness("Rough")
    saw.setThickness(OpenStudio::convert(get_stud_and_air_wall(model, mat_wood).thick,"ft","m").get)
    saw.setConductivity(OpenStudio::convert(get_stud_and_air_wall(model, mat_wood).k,"Btu/hr*ft*R","W/m*K").get)
    saw.setDensity(OpenStudio::convert(get_stud_and_air_wall(model, mat_wood).rho,"lb/ft^3","kg/m^3").get)
    saw.setSpecificHeat(OpenStudio::convert(get_stud_and_air_wall(model, mat_wood).Cp,"Btu/lb*R","J/kg*K").get) # tk

    # FinUninsFinWall
    layercount = 0
    fufw = OpenStudio::Model::Construction.new(model)
    fufw.setName("FinUninsFinWall")
    fufw.insertLayer(layercount,pwm)
    layercount += 1
    if partition_wall_mass.PartitionWallMassPCMType == constants.PCMtypeConcentrated
      fufw.insertLayer(layercount,pcm)
      layercount += 1
    end
    fufw.insertLayer(layercount,saw)
    layercount += 1
    if partition_wall_mass.PartitionWallMassPCMType == constants.PCMtypeConcentrated
      fufw.insertLayer(layercount,pcm)
      layercount += 1
    end
    fufw.insertLayer(layercount,pwm)

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
    # loop thru all the space types
    spaceTypes = model.getSpaceTypes
    spaceTypes.each do |spaceType|
      if selected_living.get.handle.to_s == spaceType.handle.to_s
        runner.registerInfo("Assigned internal mass object 'LivingPartition' to space type '#{spaceType.name}'")
        im.setSpaceType(spaceType)
      end
    end

    if hasFinishedBasement
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
      # loop thru all the space types
      spaceTypes = model.getSpaceTypes
      spaceTypes.each do |spaceType|
        if selected_fbsmt.get.handle.to_s == spaceType.handle.to_s
          runner.registerInfo("Assigned internal mass object 'FBsmtPartition' to space type '#{spaceType.name}'")
          im.setSpaceType(spaceType)
        end
      end
    end

    return true

  end #end the run method

end #end the measure

#this allows the measure to be use by the application
ProcessThermalMassPartitionWall.new.registerWithApplication