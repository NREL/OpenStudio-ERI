#see the URL below for information on how to write OpenStudio measures
# http://openstudio.nrel.gov/openstudio-measure-writing-guide

#see the URL below for information on using life cycle cost objects in OpenStudio
# http://openstudio.nrel.gov/openstudio-life-cycle-examples

#see the URL below for access to C++ documentation on model objects (click on "model" in the main window to view model objects)
# http://openstudio.nrel.gov/sites/openstudio.nrel.gov/files/nv_data/cpp_documentation_it/model/html/namespaces.html

require "#{File.dirname(__FILE__)}/resources/util"
require "#{File.dirname(__FILE__)}/resources/constants"

#start the measure
class ProcessConstructionsInteriorUninsulatedWalls < OpenStudio::Ruleset::ModelUserScript

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

  end

  #define the name that a user will see, this method may be deprecated as
  #the display name in PAT comes from the name field in measure.xml
  def name
    return "Set Residential Uninsulated Wall Construction"
  end
  
  def description
    return "This measure assigns constructions for the uninsulated walls between spaces."
  end
  
  def modeler_description
    return "Calculates material layer properties of uninsulated constructions for the walls between spaces. Finds surfaces adjacent to the space and sets applicable constructions."
  end    
  
  #define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Ruleset::OSArgumentVector.new

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

    #make a choice argument for unfinished attic space type
    space_types = model.getSpaceTypes
    space_type_args = OpenStudio::StringVector.new
    space_types.each do |space_type|
        space_type_args << space_type.name.to_s
    end
    if not space_type_args.include?(Constants.UnfinishedAtticSpaceType)
        space_type_args << Constants.UnfinishedAtticSpaceType
    end
    unfin_attic_space_type = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("unfin_attic_space_type", space_type_args, true)
    unfin_attic_space_type.setDisplayName("Unfinished Attic space type")
    unfin_attic_space_type.setDescription("Select the unfinished attic space type")
    unfin_attic_space_type.setDefaultValue(Constants.UnfinishedAtticSpaceType)
    args << unfin_attic_space_type
    
    #make a choice argument for garage space type
    space_types = model.getSpaceTypes
    space_type_args = OpenStudio::StringVector.new
    space_types.each do |space_type|
        space_type_args << space_type.name.to_s
    end
    if not space_type_args.include?(Constants.GarageSpaceType)
        space_type_args << Constants.GarageSpaceType
    end
    garage_space_type = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("garage_space_type", space_type_args, true)
    garage_space_type.setDisplayName("Garage space type")
    garage_space_type.setDescription("Select the garage space type")
    garage_space_type.setDefaultValue(Constants.GarageSpaceType)
    args << garage_space_type    
    
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
    living_space_type = HelperMethods.get_space_type_from_string(model, living_space_type_r, runner)
    if living_space_type.nil?
        return false
    end
	unfin_attic_space_type_r = runner.getStringArgumentValue("unfin_attic_space_type",user_arguments)
    unfin_attic_space_type = HelperMethods.get_space_type_from_string(model, unfin_attic_space_type_r, runner, false)
	garage_space_type_r = runner.getStringArgumentValue("garage_space_type",user_arguments)
    garage_space_type = HelperMethods.get_space_type_from_string(model, garage_space_type_r, runner, false)    
	
    # Initialize hashes
    constructions_to_surfaces = {"FinUninsFinWall"=>[], "RevFinUninsFinWall"=>[], "UnfinUninsUnfinWall"=>[], "RevUnfinUninsUnfinWall"=>[]}
    constructions_to_objects = Hash.new 
    
    # Walls between living spaces
	living_space_type.spaces.each do |living_space|
	  living_space.surfaces.each do |living_surface|
	    next unless ["wall"].include? living_surface.surfaceType.downcase
		adjacent_surface = living_surface.adjacentSurface
		next unless adjacent_surface.is_initialized
		adjacent_surface = adjacent_surface.get
	    adjacent_surface_r = adjacent_surface.name.to_s
	    adjacent_space_type_r = HelperMethods.get_space_type_from_surface(model, adjacent_surface_r, runner)
	    next unless [living_space_type_r].include? adjacent_space_type_r
        constructions_to_surfaces["FinUninsFinWall"] << living_surface
        constructions_to_surfaces["RevFinUninsFinWall"] << adjacent_surface
	  end	
	end
	
    # Walls between garage and unfinished attic
    unless garage_space_type.nil?
      garage_space_type.spaces.each do |garage_space|
        garage_space.surfaces.each do |garage_surface|    
          next unless ["wall"].include? garage_surface.surfaceType.downcase
          adjacent_surface = garage_surface.adjacentSurface
          next unless adjacent_surface.is_initialized
          adjacent_surface = adjacent_surface.get
          adjacent_surface_r = adjacent_surface.name.to_s
          adjacent_space_type_r = HelperMethods.get_space_type_from_surface(model, adjacent_surface_r, runner)
          next unless [unfin_attic_space_type_r].include? adjacent_space_type_r
          constructions_to_surfaces["RevUnfinUninsUnfinWall"] << garage_surface
          constructions_to_surfaces["UnfinUninsUnfinWall"] << adjacent_surface
        end
      end          
    end

    # Continue if no applicable surfaces
    if constructions_to_surfaces.all? {|construction, surfaces| surfaces.empty?}
      return true
    end     
    
    # Partition Wall Mass
    partitionWallMassThickness = runner.getDoubleArgumentValue("userdefinedpartitionwallmassth",user_arguments)
    partitionWallMassConductivity = runner.getDoubleArgumentValue("userdefinedpartitionwallmasscond",user_arguments)
    partitionWallMassDensity = runner.getDoubleArgumentValue("userdefinedpartitionwallmassdens",user_arguments)
    partitionWallMassSpecificHeat = runner.getDoubleArgumentValue("userdefinedpartitionwallmasssh",user_arguments)

    # Create the material class instances
    partition_wall_mass = PartitionWallMass.new(partitionWallMassThickness, partitionWallMassConductivity, partitionWallMassDensity, partitionWallMassSpecificHeat)

    # PartitionWallMass
    mat_partition_wall_mass = Material.MassPartitionWall(partitionWallMassThickness, partitionWallMassConductivity, partitionWallMassDensity, partitionWallMassSpecificHeat)
    pwm = OpenStudio::Model::StandardOpaqueMaterial.new(model)
    pwm.setName("PartitionWallMass")
    pwm.setRoughness("Rough")
    pwm.setThickness(OpenStudio::convert(mat_partition_wall_mass.thick,"ft","m").get)
    pwm.setConductivity(OpenStudio::convert(mat_partition_wall_mass.k,"Btu/hr*ft*R","W/m*K").get)
    pwm.setDensity(OpenStudio::convert(mat_partition_wall_mass.rho,"lb/ft^3","kg/m^3").get)
    pwm.setSpecificHeat(OpenStudio::convert(mat_partition_wall_mass.Cp,"Btu/lb*R","J/kg*K").get)
    pwm.setThermalAbsorptance(mat_partition_wall_mass.TAbs)
    pwm.setSolarAbsorptance(mat_partition_wall_mass.SAbs)
    pwm.setVisibleAbsorptance(mat_partition_wall_mass.VAbs)

    # StudandAirWall
    saw = OpenStudio::Model::StandardOpaqueMaterial.new(model)
    saw.setName("StudandAirWall")
    saw.setRoughness("Rough")
    saw.setThickness(OpenStudio::convert(Material.StudAndAir.thick,"ft","m").get)
    saw.setConductivity(OpenStudio::convert(Material.StudAndAir.k,"Btu/hr*ft*R","W/m*K").get)
    saw.setDensity(OpenStudio::convert(Material.StudAndAir.rho,"lb/ft^3","kg/m^3").get)
    saw.setSpecificHeat(OpenStudio::convert(Material.StudAndAir.Cp,"Btu/lb*R","J/kg*K").get)

    # Plywood-1_2in
    ply1_2 = OpenStudio::Model::StandardOpaqueMaterial.new(model)
    ply1_2.setName("Plywood-1_2in")
    ply1_2.setRoughness("Rough")
    ply1_2.setThickness(OpenStudio::convert(Material.Plywood1_2in.thick,"ft","m").get)
    ply1_2.setConductivity(OpenStudio::convert(Material.Plywood1_2in.k,"Btu/hr*ft*R","W/m*K").get)
    ply1_2.setDensity(OpenStudio::convert(Material.Plywood1_2in.rho,"lb/ft^3","kg/m^3").get)
    ply1_2.setSpecificHeat(OpenStudio::convert(Material.Plywood1_2in.Cp,"Btu/lb*R","J/kg*K").get)

    # FinUninsFinWall
	materials = []
    materials << pwm
    materials << saw
    materials << pwm
    unless constructions_to_surfaces["FinUninsFinWall"].empty?
        fufw = OpenStudio::Model::Construction.new(materials)
        fufw.setName("FinUninsFinWall")
        constructions_to_objects["FinUninsFinWall"] = fufw
    end
	
    # RevFinUninsFinWall
    unless constructions_to_surfaces["RevFinUninsFinWall"].empty?
        rfufw = fufw.reverseConstruction
        rfufw.setName("RevFinUninsFinWall")
        constructions_to_objects["RevFinUninsFinWall"] = rfufw
    end

    # UnfinUninsUnfinWall
    materials = []
    materials << saw
    materials << ply1_2
    unless constructions_to_surfaces["UnfinUninsUnfinWall"].empty?
        unfinuninsunfinwall = OpenStudio::Model::Construction.new(materials)
        unfinuninsunfinwall.setName("UnfinUninsUnfinWall")
        constructions_to_objects["UnfinUninsUnfinWall"] = unfinuninsunfinwall
    end
    
    # RevUnfinUninsUnfinWall
    unless constructions_to_surfaces["RevUnfinUninsUnfinWall"].empty?
        revunfinuninsunfinwall = unfinuninsunfinwall.reverseConstruction
        revunfinuninsunfinwall.setName("RevUnfinUninsUnfinWall")
        constructions_to_objects["RevUnfinUninsUnfinWall"] = revunfinuninsunfinwall
    end
    
    # Apply constructions to surfaces
    constructions_to_surfaces.each do |construction, surfaces|
        surfaces.each do |surface|
            surface.setConstruction(constructions_to_objects[construction])
            runner.registerInfo("Surface '#{surface.name}', of Space Type '#{HelperMethods.get_space_type_from_surface(model, surface.name.to_s, runner)}' and with Surface Type '#{surface.surfaceType}' and Outside Boundary Condition '#{surface.outsideBoundaryCondition}', was assigned Construction '#{construction}'")
        end
    end
    
    # Remove any materials which aren't used in any constructions
    HelperMethods.remove_unused_materials(model, runner)     
    
    return true
 
  end #end the run method

end #end the measure

#this allows the measure to be use by the application
ProcessConstructionsInteriorUninsulatedWalls.new.registerWithApplication