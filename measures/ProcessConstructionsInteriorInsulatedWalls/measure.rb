#see the URL below for information on how to write OpenStudio measures
# http://openstudio.nrel.gov/openstudio-measure-writing-guide

#see the URL below for information on using life cycle cost objects in OpenStudio
# http://openstudio.nrel.gov/openstudio-life-cycle-examples

#see the URL below for access to C++ documentation on model objects (click on "model" in the main window to view model objects)
# http://openstudio.nrel.gov/sites/openstudio.nrel.gov/files/nv_data/cpp_documentation_it/model/html/namespaces.html

#load sim.rb
require "#{File.dirname(__FILE__)}/resources/sim"
require "#{File.dirname(__FILE__)}/resources/constants"

#start the measure
class ProcessConstructionsInteriorInsulatedWalls < OpenStudio::Ruleset::ModelUserScript

  class InterzonalWalls
    def initialize(intWallCavityDepth, intWallCavityInsRvalueInstalled, intWallContInsThickness, intWallContInsRvalue, intWallCavityInsFillsCavity, intWallInstallGrade, intWallFramingFactor)
      @intWallCavityDepth = intWallCavityDepth
      @intWallCavityInsRvalueInstalled = intWallCavityInsRvalueInstalled
      @intWallContInsThickness = intWallContInsThickness
      @intWallContInsRvalue = intWallContInsRvalue
      @intWallCavityInsFillsCavity = intWallCavityInsFillsCavity
      @intWallInstallGrade = intWallInstallGrade
      @intWallFramingFactor = intWallFramingFactor
    end

    attr_accessor(:GapFactor)

    def IntWallCavityDepth
      return @intWallCavityDepth
    end

    def IntWallCavityInsRvalueInstalled
      return @intWallCavityInsRvalueInstalled
    end

    def IntWallContInsThickness
      return @intWallContInsThickness
    end

    def IntWallContInsRvalue
      return @intWallContInsRvalue
    end

    def IntWallCavityInsFillsCavity
      return @intWallCavityInsFillsCavity
    end

    def IntWallInstallGrade
      return @intWallInstallGrade
    end

    def IntWallFramingFactor
      return @intWallFramingFactor
    end
  end

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
  end

  class IntWallIns
    def initialize
    end
    attr_accessor(:bndry_wall_Rvalue, :bndry_wall_thickness, :bndry_wall_conductivity, :bndry_wall_density, :bndry_wall_spec_heat)
  end

  #define the name that a user will see, this method may be deprecated as
  #the display name in PAT comes from the name field in measure.xml
  def name
    return "Add/Replace Residential Interzonal Walls"
  end
  
  def description
    return "This measure creates insulated constructions for the interzonal walls between the living space and the garage."
  end
  
  def modeler_description
    return "Calculates material layer properties of insulated constructions for the interzonal walls between the living space and the garage. Finds surfaces adjacent to the living space and garage and sets applicable constructions."
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
    selected_living.setDisplayName("Living Space")
	selected_living.setDescription("The living space type.")
    args << selected_living

    #make a choice argument for crawlspace
    selected_garage = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("selectedgarage", spacetype_handles, spacetype_display_names, true)
    selected_garage.setDisplayName("Garage Space")
	selected_garage.setDescription("The garage space type.")
    args << selected_garage

    #make a double argument for partition wall mass thickness
    userdefined_partitionwallmassth = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedpartitionwallmassth", false)
    userdefined_partitionwallmassth.setDisplayName("Partition Wall Mass: Thickness")
	userdefined_partitionwallmassth.setUnits("in")
	userdefined_partitionwallmassth.setDescription("Thickness of the layer.")
    userdefined_partitionwallmassth.setDefaultValue(0.5)
    args << userdefined_partitionwallmassth

    #make a double argument for partition wall mass conductivity
    userdefined_partitionwallmasscond = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedpartitionwallmasscond", false)
    userdefined_partitionwallmasscond.setDisplayName("Partition Wall Mass: Conductivity")
	userdefined_partitionwallmasscond.setUnits("Btu-in/h-ft^2-R")
	userdefined_partitionwallmasscond.setDescription("Conductivity of the layer.")
    userdefined_partitionwallmasscond.setDefaultValue(1.1112)
    args << userdefined_partitionwallmasscond

    #make a double argument for partition wall mass density
    userdefined_partitionwallmassdens = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedpartitionwallmassdens", false)
    userdefined_partitionwallmassdens.setDisplayName("Partition Wall Mass: Density")
	userdefined_partitionwallmassdens.setUnits("lb/ft^3")
	userdefined_partitionwallmassdens.setDescription("Density of the layer.")
    userdefined_partitionwallmassdens.setDefaultValue(50.0)
    args << userdefined_partitionwallmassdens

    #make a double argument for partition wall mass specific heat
    userdefined_partitionwallmasssh = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedpartitionwallmasssh", false)
    userdefined_partitionwallmasssh.setDisplayName("Partition Wall Mass: Specific Heat")
	userdefined_partitionwallmasssh.setUnits("Btu/lb-R")
	userdefined_partitionwallmasssh.setDescription("Specific heat of the layer.")
    userdefined_partitionwallmasssh.setDefaultValue(0.2)
    args << userdefined_partitionwallmasssh

    #make a choice argument for model objects
    studsize_display_names = OpenStudio::StringVector.new
    studsize_display_names << "2x4"
    studsize_display_names << "2x6"
    studsize_display_names << "2x8"
    studsize_display_names << "2x10"
    studsize_display_names << "2x12"
    studsize_display_names << "2x14"

    #make a string argument for wood stud size of wall cavity
    selected_studsize = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("selectedstudsize", studsize_display_names, true)
    selected_studsize.setDisplayName("Interzonal Walls: Cavity Depth")
	selected_studsize.setUnits("in")
	selected_studsize.setDescription("Depth of the stud cavity.")
	selected_studsize.setDefaultValue("2x4")
    args << selected_studsize

    #make a choice argument for model objects
    spacing_display_names = OpenStudio::StringVector.new
    spacing_display_names << "16 in o.c."
    spacing_display_names << "24 in o.c."

    #make a choice argument for wood stud spacing
    selected_spacing = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("selectedspacing", spacing_display_names, true)
    selected_spacing.setDisplayName("Wood stud spacing of wall cavity.")
	selected_spacing.setUnits("in")
	selected_spacing.setDescription("The on-center spacing between studs in a wall assembly.")
	selected_spacing.setDefaultValue("16 in o.c.")
    args << selected_spacing

    #make a double argument for nominal R-value of installed cavity insulation
    userdefined_instcavr = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedinstcavr", true)
    userdefined_instcavr.setDisplayName("Interzonal Walls: Cavity Insulation Installed R-value")
	userdefined_instcavr.setUnits("hr-ft^2-R/Btu")
	userdefined_instcavr.setDescription("R-value is a measure of insulation's ability to resist heat traveling through it.")
	userdefined_instcavr.setDefaultValue(13.0)
    args << userdefined_instcavr

    #make a choice argument for model objects
    installgrade_display_names = OpenStudio::StringVector.new
    installgrade_display_names << "I"
    installgrade_display_names << "II"
    installgrade_display_names << "III"

	#make a choice argument for wall cavity insulation installation grade
	selected_installgrade = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("selectedinstallgrade", installgrade_display_names, true)
	selected_installgrade.setDisplayName("Wood Stud: Cavity Install Grade")
	selected_installgrade.setDescription("5% of the wall is considered missing insulation for Grade 3, 2% for Grade 2, and 0% for Grade 1.")
    selected_installgrade.setDefaultValue("I")
	args << selected_installgrade

	#make a bool argument for whether the cavity insulation fills the cavity
	selected_insfills = OpenStudio::Ruleset::OSArgument::makeBoolArgument("selectedinsfills", true)
	selected_insfills.setDisplayName("Interzonal Walls: Insulation Fills Cavity")
	selected_insfills.setDescription("Specifies whether the cavity insulation completely fills the depth of the wall cavity.")
    selected_insfills.setDefaultValue(true)
	args << selected_insfills

	#make a double argument for rigid insulation thickness of wall cavity
    userdefined_rigidinsthickness = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedrigidinsthickness", false)
    userdefined_rigidinsthickness.setDisplayName("Interzonal Walls: Continuous Insulation Thickness")
	userdefined_rigidinsthickness.setUnits("in")
	userdefined_rigidinsthickness.setDescription("The thickness of the continuous insulation.")
    userdefined_rigidinsthickness.setDefaultValue(0)
    args << userdefined_rigidinsthickness
	
	#make a double argument for rigid insulation R-value of wall cavity
	userdefined_rigidinsr = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedrigidinsr", false)
	userdefined_rigidinsr.setDisplayName("Interzonal Walls: Continuous Insulation Nominal R-value")
	userdefined_rigidinsr.setUnits("hr-ft^2-R/Btu")
	userdefined_rigidinsr.setDescription("R-value is a measure of insulation's ability to resist heat traveling through it.")
    userdefined_rigidinsr.setDefaultValue(0)
	args << userdefined_rigidinsr

    return args
  end #end the arguments method

  #define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)
    
    #use the built-in error checking 
    if not runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

    partitionWallMassPCMType = nil

    # Space Type
    selected_garage = runner.getOptionalWorkspaceObjectChoiceValue("selectedgarage",user_arguments,model)
    selected_living = runner.getOptionalWorkspaceObjectChoiceValue("selectedliving",user_arguments,model)

    # Partition Wall Mass
    userdefined_partitionwallmassth = runner.getDoubleArgumentValue("userdefinedpartitionwallmassth",user_arguments)
    userdefined_partitionwallmasscond = runner.getDoubleArgumentValue("userdefinedpartitionwallmasscond",user_arguments)
    userdefined_partitionwallmassdens = runner.getDoubleArgumentValue("userdefinedpartitionwallmassdens",user_arguments)
    userdefined_partitionwallmasssh = runner.getDoubleArgumentValue("userdefinedpartitionwallmasssh",user_arguments)
    # Cavity
    selected_studsize = runner.getStringArgumentValue("selectedstudsize",user_arguments)
    selected_spacing = runner.getStringArgumentValue("selectedspacing",user_arguments)
    userdefined_instcavr = runner.getDoubleArgumentValue("userdefinedinstcavr",user_arguments)
    selected_installgrade = runner.getStringArgumentValue("selectedinstallgrade",user_arguments)
    selected_insfills = runner.getBoolArgumentValue("selectedinsfills",user_arguments)
    # Rigid
    userdefined_rigidinsthickness = runner.getDoubleArgumentValue("userdefinedrigidinsthickness",user_arguments)
    userdefined_rigidinsr = runner.getDoubleArgumentValue("userdefinedrigidinsr",user_arguments)

    # Constants
    mat_gyp = get_mat_gypsum
    mat_rigid = get_mat_rigid_ins

    # Partition Wall Mass
    partitionWallMassThickness = userdefined_partitionwallmassth
    partitionWallMassConductivity = userdefined_partitionwallmasscond
    partitionWallMassDensity = userdefined_partitionwallmassdens
    partitionWallMassSpecificHeat = userdefined_partitionwallmasssh

    # Rigid
    rigidInsRvalue = userdefined_rigidinsr
    rigidInsRoughness = "Rough"
    rigidInsThickness = userdefined_rigidinsthickness
    rigidInsConductivity = OpenStudio::convert(rigidInsThickness,"in","ft").get / rigidInsRvalue
    rigidInsDensity = mat_rigid.rho
    rigidInsSpecificHeat = mat_rigid.Cp

    # Cavity
    intWallCavityInsFillsCavity = selected_insfills
    intWallCavityInsRvalueInstalled = userdefined_instcavr
    intWallInstallGrade_dict = {"I"=>1, "II"=>2, "III"=>3}
    intWallInstallGrade = intWallInstallGrade_dict[selected_installgrade]
    intWallCavityDepth_dict = {"2x4"=>3.5, "2x6"=>5.5, "2x8"=>7.25, "2x10"=>9.25, "2x12"=>11.25, "2x14"=>13.25, "2x16"=>15.25}
    intWallCavityDepth = intWallCavityDepth_dict[selected_studsize]
    intWallFramingFactor_dict = {"16 in o.c."=>0.25, "24 in o.c."=>0.22}
    intWallFramingFactor = intWallFramingFactor_dict[selected_spacing]

    # Create the material class instances
    iw = InterzonalWalls.new(intWallCavityDepth, intWallCavityInsRvalueInstalled, rigidInsThickness, rigidInsRvalue, intWallCavityInsFillsCavity, intWallInstallGrade, intWallFramingFactor)
    partition_wall_mass = PartitionWallMass.new(partitionWallMassThickness, partitionWallMassConductivity, partitionWallMassDensity, partitionWallMassSpecificHeat, partitionWallMassPCMType)
    iwi = IntWallIns.new

    # Create the sim object
    sim = Sim.new(model, runner)

    # Process the wood stud walls
    iwi = sim._processConstructionsInteriorInsulatedWalls(iw, partition_wall_mass, iwi)

    # Create the material layers

    # ConcPCMPartWall
    if partition_wall_mass.PartitionWallMassPCMType == Constants.PCMtypeConcentrated
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

    # IntWallIns
    iwiThickness = iwi.bndry_wall_thickness
    iwiConductivity = iwi.bndry_wall_conductivity
    iwiDensity = iwi.bndry_wall_density
    iwiSpecificHeat = iwi.bndry_wall_spec_heat
    iwi = OpenStudio::Model::StandardOpaqueMaterial.new(model)
    iwi.setName("IntWallIns")
    iwi.setRoughness("Rough")
    iwi.setThickness(OpenStudio::convert(iwiThickness,"ft","m").get)
    iwi.setConductivity(OpenStudio::convert(iwiConductivity,"Btu/hr*ft*R","W/m*K").get)
    iwi.setDensity(OpenStudio::convert(iwiDensity,"lb/ft^3","kg/m^3").get)
    iwi.setSpecificHeat(OpenStudio::convert(iwiSpecificHeat,"Btu/lb*R","J/kg*K").get)

    if iw.IntWallContInsRvalue != 0

      # Set Rigid Insulation Layer Properties
      # IntWallRigidIns
      iwri = OpenStudio::Model::StandardOpaqueMaterial.new(model)
      iwri.setName("IntWallRigidIns")
      iwri.setThickness(OpenStudio::convert(iw.IntWallContInsThickness,"in","m").get)
      iwri.setConductivity(OpenStudio::convert(OpenStudio::convert(iw.IntWallContInsThickness,"in","ft").get / iw.IntWallContInsRvalue,"Btu/hr*ft*R","W/m*K").get)
      iwri.setDensity(OpenStudio::convert(mat_rigid.rho,"lb/ft^3","kg/m^3").get) # lbm/ft^3
      iwri.setSpecificHeat(OpenStudio::convert(mat_rigid.Cp,"Btu/lb*R","J/kg*K").get) # Btu/lbm*F

      # UnfinInsFinWall
      layercount = 0
      unfininsfinwall = OpenStudio::Model::Construction.new(model)
      unfininsfinwall.setName("UnfinInsFinWall")
      unfininsfinwall.insertLayer(layercount,iwri)
      layercount += 1
      unfininsfinwall.insertLayer(layercount,iwi)
      layercount += 1
      if partition_wall_mass.PartitionWallMassPCMType == Constants.PCMtypeConcentrated
        unfininsfinwall.insertLayer(layercount,pcm)
        layercount += 1
      end
      unfininsfinwall.insertLayer(layercount,pwm)

      # UnfinInsUnfinWall
      layercount = 0
      unfininsunfinwall = OpenStudio::Model::Construction.new(model)
      unfininsunfinwall.setName("UnfinInsUnfinWall")
      unfininsunfinwall.insertLayer(layercount,iwri)
      layercount += 1
      unfininsunfinwall.insertLayer(layercount,iwi)

    else

      # UnfinInsFinWall
      layercount = 0
      unfininsfinwall = OpenStudio::Model::Construction.new(model)
      unfininsfinwall.setName("UnfinInsFinWall")
      unfininsfinwall.insertLayer(layercount,iwi)
      layercount += 1
      if partition_wall_mass.PartitionWallMassPCMType == Constants.PCMtypeConcentrated
        unfininsfinwall.insertLayer(layercount,pcm)
        layercount += 1
      end
      unfininsfinwall.insertLayer(layercount,pwm)

      # UnfinInsUnfinWall
      layercount = 0
      unfininsunfinwall = OpenStudio::Model::Construction.new(model)
      unfininsunfinwall.setName("UnfinInsUnfinWall")
      unfininsunfinwall.insertLayer(layercount,iwi)

    end

    # RevUnfinInsFinWall
    layercount = 0
    revunfininsfinwall = OpenStudio::Model::Construction.new(model)
    revunfininsfinwall.setName("RevUnfinInsFinWall")
    unfininsfinwall.layers.reverse_each do |layer|
      revunfininsfinwall.insertLayer(layercount,layer)
      layercount += 1
    end

    # RevUnfinInsUnfinWall
    layercount = 0
    revunfininsunfinwall = OpenStudio::Model::Construction.new(model)
    revunfininsunfinwall.setName("RevUnfinInsUnfinWall")
    unfininsunfinwall.layers.reverse_each do |layer|
      revunfininsunfinwall.insertLayer(layercount,layer)
      layercount += 1
    end

    # loop thru all the spaces
    spaces = model.getSpaces
    spaces.each do |space|
      constructions_hash = {}
      if selected_garage.get.handle.to_s == space.spaceType.get.handle.to_s
        # loop thru all surfaces attached to the space
        surfaces = space.surfaces
        surfaces.each do |surface|
          if surface.surfaceType == "Wall" and surface.outsideBoundaryCondition == "Surface"
            surface.resetConstruction
            surface.setConstruction(revunfininsfinwall)
            constructions_hash[surface.name.to_s] = [surface.surfaceType,surface.outsideBoundaryCondition,"RevUnfinInsFinWall"]
          end
        end
      elsif selected_living.get.handle.to_s == space.spaceType.get.handle.to_s
        # loop thru all surfaces attached to the space
        surfaces = space.surfaces
        surfaces.each do |surface|
          if surface.surfaceType == "Wall" and surface.outsideBoundaryCondition == "Surface"
            surface.resetConstruction
            surface.setConstruction(unfininsfinwall)
            constructions_hash[surface.name.to_s] = [surface.surfaceType,surface.outsideBoundaryCondition,"UnfinInsFinWall"]
          end
        end
      end
      constructions_hash.map do |key,value|
        runner.registerInfo("Surface '#{key}', attached to Space '#{space.name.to_s}' of Space Type '#{space.spaceType.get.name.to_s}' and with Surface Type '#{value[0]}' and Outside Boundary Condition '#{value[1]}', was assigned Construction '#{value[2]}'")
      end
    end

    return true
 
  end #end the run method

end #end the measure

#this allows the measure to be use by the application
ProcessConstructionsInteriorInsulatedWalls.new.registerWithApplication