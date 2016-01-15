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
class ProcessConstructionsInteriorUninsulatedFloors < OpenStudio::Ruleset::ModelUserScript

    class StudandAirFloor
        def initialize
        end
        attr_accessor(:floor_part_thickness, :floor_part_conductivity, :floor_part_density, :floor_part_spec_heat)
    end

  class CeilingMass
    def initialize(ceilingMassGypsumThickness, ceilingMassGypsumNumLayers, rvalue, ceilingMassPCMType)
      @ceilingMassGypsumThickness = ceilingMassGypsumThickness
      @ceilingMassGypsumNumLayers = ceilingMassGypsumNumLayers
      @rvalue = rvalue
      @ceilingMassPCMType = ceilingMassPCMType
    end

    def CeilingMassGypsumThickness
      return @ceilingMassGypsumThickness
    end

    def CeilingMassGypsumNumLayers
      return @ceilingMassGypsumNumLayers
    end

    def Rvalue
      return @rvalue
    end

    def CeilingMassPCMType
      return @ceilingMassPCMType
    end
  end

  class FloorMass
    def initialize(floorMassThickness, floorMassConductivity, floorMassDensity, floorMassSpecificHeat)
      @floorMassThickness = floorMassThickness
      @floorMassConductivity = floorMassConductivity
      @floorMassDensity = floorMassDensity
      @floorMassSpecificHeat = floorMassSpecificHeat
    end

    def FloorMassThickness
      return @floorMassThickness
    end

    def FloorMassConductivity
      return @floorMassConductivity
    end

    def FloorMassDensity
      return @floorMassDensity
    end

    def FloorMassSpecificHeat
      return @floorMassSpecificHeat
    end
  end

  class Carpet
    def initialize(carpetFloorFraction, carpetPadRValue)
      @carpetFloorFraction = carpetFloorFraction
      @carpetPadRValue = carpetPadRValue
    end

    attr_accessor(:floor_bare_fraction)

    def CarpetFloorFraction
      return @carpetFloorFraction
    end

    def CarpetPadRValue
      return @carpetPadRValue
    end
  end

  #define the name that a user will see, this method may be deprecated as
  #the display name in PAT comes from the name field in measure.xml
  def name
    return "Assign Residential Uninsulated Floor Construction"
  end
  
  def description
    return "This measure assigns a construction to the floors between living spaces and the floors between the living space and finished basement."
  end
  
  def modeler_description
    return "Calculates material layer properties of uninsulated constructions for the floors between living spaces and the floors between the living space and finished basement. Finds surfaces adjacent to the living space and finished basement and sets applicable constructions."
  end   
  
  #define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Ruleset::OSArgumentVector.new

    #make a double argument for thickness of gypsum
    userdefined_gypthickness = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedgypthickness", false)
    userdefined_gypthickness.setDisplayName("Ceiling Mass: Thickness")
    userdefined_gypthickness.setUnits("in")
    userdefined_gypthickness.setDescription("Gypsum layer thickness.")
    userdefined_gypthickness.setDefaultValue(0.5)
    args << userdefined_gypthickness

    #make a double argument for number of gypsum layers
    userdefined_gyplayers = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedgyplayers", false)
    userdefined_gyplayers.setDisplayName("Ceiling Mass: Num Layers")
    userdefined_gyplayers.setUnits("#")
    userdefined_gyplayers.setDescription("Integer number of layers of gypsum.")
    userdefined_gyplayers.setDefaultValue(1)
    args << userdefined_gyplayers

    #make a double argument for floor mass thickness
    userdefined_floormassth = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedfloormassth", false)
    userdefined_floormassth.setDisplayName("Floor Mass: Thickness")
    userdefined_floormassth.setUnits("in")
    userdefined_floormassth.setDescription("Thickness of the floor mass.")
    userdefined_floormassth.setDefaultValue(0.625)
    args << userdefined_floormassth

    #make a double argument for floor mass conductivity
    userdefined_floormasscond = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedfloormasscond", false)
    userdefined_floormasscond.setDisplayName("Floor Mass: Conductivity")
    userdefined_floormasscond.setUnits("Btu-in/h-ft^2-R")
    userdefined_floormasscond.setDescription("Conductivity of the floor mass.")
    userdefined_floormasscond.setDefaultValue(0.8004)
    args << userdefined_floormasscond

    #make a double argument for floor mass density
    userdefined_floormassdens = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedfloormassdens", false)
    userdefined_floormassdens.setDisplayName("Floor Mass: Density")
    userdefined_floormassdens.setUnits("lb/ft^3")
    userdefined_floormassdens.setDescription("Density of the floor mass.")
    userdefined_floormassdens.setDefaultValue(34.0)
    args << userdefined_floormassdens

    #make a double argument for floor mass specific heat
    userdefined_floormasssh = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedfloormasssh", false)
    userdefined_floormasssh.setDisplayName("Floor Mass: Specific Heat")
    userdefined_floormasssh.setUnits("Btu/lb-R")
    userdefined_floormasssh.setDescription("Specific heat of the floor mass.")
    userdefined_floormasssh.setDefaultValue(0.29)
    args << userdefined_floormasssh

    #make a double argument for carpet pad R-value
    userdefined_carpetr = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedcarpetr", false)
    userdefined_carpetr.setDisplayName("Carpet: Carpet Pad R-value")
    userdefined_carpetr.setUnits("hr-ft^2-R/Btu")
    userdefined_carpetr.setDescription("The combined R-value of the carpet and the pad.")
    userdefined_carpetr.setDefaultValue(2.08)
    args << userdefined_carpetr

    #make a double argument for carpet floor fraction
    userdefined_carpetfrac = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedcarpetfrac", false)
    userdefined_carpetfrac.setDisplayName("Carpet: Floor Carpet Fraction")
    userdefined_carpetfrac.setUnits("frac")
    userdefined_carpetfrac.setDescription("Defines the fraction of a floor which is covered by carpet.")
    userdefined_carpetfrac.setDefaultValue(0.8)
    args << userdefined_carpetfrac

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
    fbasement_space_type.setDisplayName("Finished Basement space type")
    fbasement_space_type.setDescription("Select the finished basement space type")
    fbasement_space_type.setDefaultValue(Constants.FinishedBasementSpaceType)
    args << fbasement_space_type    
    
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
    
    return args
  end #end the arguments method

  #define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)
    
    #use the built-in error checking 
    if not runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

    ceilingMassPCMType = nil

    # Space Type
    living_space_type_r = runner.getStringArgumentValue("living_space_type",user_arguments)
    living_space_type = HelperMethods.get_space_type_from_string(model, living_space_type_r, runner)
    if living_space_type.nil?
        return false
    end
    fbasement_space_type_r = runner.getStringArgumentValue("fbasement_space_type",user_arguments)
    fbasement_space_type = HelperMethods.get_space_type_from_string(model, fbasement_space_type_r, runner, false)
    garage_space_type_r = runner.getStringArgumentValue("garage_space_type",user_arguments)
    garage_space_type = HelperMethods.get_space_type_from_string(model, garage_space_type_r, runner, false)
    unfin_attic_space_type_r = runner.getStringArgumentValue("unfin_attic_space_type",user_arguments)
    unfin_attic_space_type = HelperMethods.get_space_type_from_string(model, unfin_attic_space_type_r, runner, false)   
    
    # Gypsum
    selected_gypsum = runner.getOptionalWorkspaceObjectChoiceValue("selectedgypsum",user_arguments,model)
    if selected_gypsum.empty?
      userdefined_gypthickness = runner.getDoubleArgumentValue("userdefinedgypthickness",user_arguments)
      userdefined_gyplayers = runner.getDoubleArgumentValue("userdefinedgyplayers",user_arguments)
    end

    # Floor Mass
    userdefined_floormassth = runner.getDoubleArgumentValue("userdefinedfloormassth",user_arguments)
    userdefined_floormasscond = runner.getDoubleArgumentValue("userdefinedfloormasscond",user_arguments)
    userdefined_floormassdens = runner.getDoubleArgumentValue("userdefinedfloormassdens",user_arguments)
    userdefined_floormasssh = runner.getDoubleArgumentValue("userdefinedfloormasssh",user_arguments)

    # Carpet
    userdefined_carpetr = runner.getDoubleArgumentValue("userdefinedcarpetr",user_arguments)
    userdefined_carpetfrac = runner.getDoubleArgumentValue("userdefinedcarpetfrac",user_arguments)

    # Constants
    mat_gyp = get_mat_gypsum
    mat_wood = get_mat_wood

    # Gypsum
    gypsumThickness = userdefined_gypthickness
    gypsumNumLayers = userdefined_gyplayers
    gypsumConductivity = mat_gyp.k
    gypsumDensity = mat_gyp.rho
    gypsumSpecificHeat = mat_gyp.Cp
    gypsumThermalAbs = get_mat_gypsum_ceiling(mat_gyp).TAbs
    gypsumSolarAbs = get_mat_gypsum_ceiling(mat_gyp).SAbs
    gypsumVisibleAbs = get_mat_gypsum_ceiling(mat_gyp).VAbs
    gypsumRvalue = (OpenStudio::convert(gypsumThickness,"in","ft").get * gypsumNumLayers / mat_gyp.k)

    # Floor Mass
    floorMassThickness = userdefined_floormassth
    floorMassConductivity = userdefined_floormasscond
    floorMassDensity = userdefined_floormassdens
    floorMassSpecificHeat = userdefined_floormasssh

    # Carpet
    carpetPadRValue = userdefined_carpetr
    carpetFloorFraction = userdefined_carpetfrac

    # Create the material class instances
    ceiling_mass = CeilingMass.new(gypsumThickness, gypsumNumLayers, gypsumRvalue, ceilingMassPCMType)
    floor_mass = FloorMass.new(floorMassThickness, floorMassConductivity, floorMassDensity, floorMassSpecificHeat)
    carpet = Carpet.new(carpetFloorFraction, carpetPadRValue)
    saf = StudandAirFloor.new

    # Create the sim object
    sim = Sim.new(model, runner)

    # Process the interior uninsulated floor
    saf = sim._processConstructionsInteriorUninsulatedFloors(saf)

    # ConcPCMCeilWall
    if ceiling_mass.CeilingMassPCMType == Constants.PCMtypeConcentrated
      pcm = OpenStudio::Model::StandardOpaqueMaterial.new(model)
      pcm.setName("ConcPCMCeilWall")
      pcm.setRoughness("Rough")
      pcm.setThickness(OpenStudio::convert(get_mat_ceil_pcm_conc(get_mat_ceil_pcm(ceiling_mass), ceiling_mass).thick,"ft","m").get)
      pcm.setConductivity()
      pcm.setDensity()
      pcm.setSpecificHeat()
    end

    # StudandAirFloor
    safThickness = saf.floor_part_thickness
    safConductivity = saf.floor_part_conductivity
    safDensity = saf.floor_part_density
    safSpecificHeat = saf.floor_part_spec_heat
    saf = OpenStudio::Model::StandardOpaqueMaterial.new(model)
    saf.setName("StudandAirFloor")
    saf.setRoughness("Rough")
    saf.setThickness(OpenStudio::convert(safThickness,"ft","m").get)
    saf.setConductivity(OpenStudio::convert(safConductivity,"Btu/hr*ft*R","W/m*K").get)
    saf.setDensity(OpenStudio::convert(safDensity,"lb/ft^3","kg/m^3").get)
    saf.setSpecificHeat(OpenStudio::convert(safSpecificHeat,"Btu/lb*R","J/kg*K").get)

    # Gypsum
    gypsum = OpenStudio::Model::StandardOpaqueMaterial.new(model)
    gypsum.setName("GypsumBoard-Ceiling")
    gypsum.setRoughness("Rough")
    gypsum.setThickness(OpenStudio::convert(gypsumThickness,"in","m").get)
    gypsum.setConductivity(OpenStudio::convert(gypsumConductivity,"Btu/hr*ft*R","W/m*K").get)
    gypsum.setDensity(OpenStudio::convert(gypsumDensity,"lb/ft^3","kg/m^3").get)
    gypsum.setSpecificHeat(OpenStudio::convert(gypsumSpecificHeat,"Btu/lb*R","J/kg*K").get)
    gypsum.setThermalAbsorptance(gypsumThermalAbs)
    gypsum.setSolarAbsorptance(gypsumSolarAbs)
    gypsum.setVisibleAbsorptance(gypsumVisibleAbs)

    # Plywood-3_4in
    ply3_4 = OpenStudio::Model::StandardOpaqueMaterial.new(model)
    ply3_4.setName("Plywood-3_4in")
    ply3_4.setRoughness("Rough")
    ply3_4.setThickness(OpenStudio::convert(get_mat_plywood3_4in(mat_wood).thick,"ft","m").get)
    ply3_4.setConductivity(OpenStudio::convert(mat_wood.k,"Btu/hr*ft*R","W/m*K").get)
    ply3_4.setDensity(OpenStudio::convert(mat_wood.rho,"lb/ft^3","kg/m^3").get)
    ply3_4.setSpecificHeat(OpenStudio::convert(mat_wood.Cp,"Btu/lb*R","J/kg*K").get)

    # FloorMass
    fm = OpenStudio::Model::StandardOpaqueMaterial.new(model)
    fm.setName("FloorMass")
    fm.setRoughness("Rough")
    fm.setThickness(OpenStudio::convert(get_mat_floor_mass(floor_mass).thick,"ft","m").get)
    fm.setConductivity(OpenStudio::convert(get_mat_floor_mass(floor_mass).k,"Btu/hr*ft*R","W/m*K").get)
    fm.setDensity(OpenStudio::convert(get_mat_floor_mass(floor_mass).rho,"lb/ft^3","kg/m^3").get)
    fm.setSpecificHeat(OpenStudio::convert(get_mat_floor_mass(floor_mass).Cp,"Btu/lb*R","J/kg*K").get)
    fm.setThermalAbsorptance(get_mat_floor_mass(floor_mass).TAbs)
    fm.setSolarAbsorptance(get_mat_floor_mass(floor_mass).SAbs)

    # CarpetBareLayer
    if carpet.CarpetFloorFraction > 0
      cbl = OpenStudio::Model::StandardOpaqueMaterial.new(model)
      cbl.setName("CarpetBareLayer")
      cbl.setRoughness("Rough")
      cbl.setThickness(OpenStudio::convert(get_mat_carpet_bare(carpet).thick,"ft","m").get)
      cbl.setConductivity(OpenStudio::convert(get_mat_carpet_bare(carpet).k,"Btu/hr*ft*R","W/m*K").get)
      cbl.setDensity(OpenStudio::convert(get_mat_carpet_bare(carpet).rho,"lb/ft^3","kg/m^3").get)
      cbl.setSpecificHeat(OpenStudio::convert(get_mat_carpet_bare(carpet).Cp,"Btu/lb*R","J/kg*K").get)
      cbl.setThermalAbsorptance(get_mat_carpet_bare(carpet).TAbs)
      cbl.setSolarAbsorptance(get_mat_carpet_bare(carpet).SAbs)
    end

    # FinUninsFinFloor
    materials = []
    if ceiling_mass.CeilingMassPCMType == Constants.PCMtypeConcentrated
      materials << pcm
    end
    (0...gypsumNumLayers).to_a.each do |i|
      materials << gypsum
    end
    materials << saf
    materials << ply3_4
    materials << fm
    if carpet.CarpetFloorFraction > 0
      materials << cbl
    end
    finuninsfinfloor = OpenStudio::Model::Construction.new(materials)
    finuninsfinfloor.setName("FinUninsFinFloor")
    
    # RevFinUninsFinFloor
    revfinuninsfinfloor = finuninsfinfloor.reverseConstruction
    revfinuninsfinfloor.setName("RevFinUninsFinFloor")
    
    # UnfinUninsUnfinFloor
    materials = []
    materials << saf
    materials << ply3_4
    unfinuninsunfinfloor = OpenStudio::Model::Construction.new(materials)
    unfinuninsunfinfloor.setName("UnfinUninsUnfinFloor")
    
    # RevUnfinUninsUnfinFloor
    revunfinuninsunfinfloor = unfinuninsunfinfloor.reverseConstruction
    revunfinuninsunfinfloor.setName("RevUnfinUninsUnfinFloor")
    
    living_space_type.spaces.each do |living_space|
      living_space.surfaces.each do |living_surface|
        next unless ["floor"].include? living_surface.surfaceType.downcase
        adjacent_surface = living_surface.adjacentSurface
        next unless adjacent_surface.is_initialized
        adjacent_surface = adjacent_surface.get
        adjacent_surface_r = adjacent_surface.name.to_s
        adjacent_space_type_r = HelperMethods.get_space_type_from_surface(model, adjacent_surface_r)
        next unless [living_space_type_r, fbasement_space_type_r].include? adjacent_space_type_r
        living_surface.setConstruction(finuninsfinfloor)
        runner.registerInfo("Surface '#{living_surface.name}', of Space Type '#{living_space_type_r}' and with Surface Type '#{living_surface.surfaceType}' and Outside Boundary Condition '#{living_surface.outsideBoundaryCondition}', was assigned Construction '#{finuninsfinfloor.name}'")
        adjacent_surface.setConstruction(revfinuninsfinfloor)       
        runner.registerInfo("Surface '#{adjacent_surface.name}', of Space Type '#{adjacent_space_type_r}' and with Surface Type '#{adjacent_surface.surfaceType}' and Outside Boundary Condition '#{adjacent_surface.outsideBoundaryCondition}', was assigned Construction '#{revfinuninsfinfloor.name}'")
      end   
    end
    
    living_space_type.spaces.each do |living_space|
      living_space.surfaces.each do |living_surface|
        next unless living_surface.outsideBoundaryCondition.downcase == "adiabatic"
        if living_surface.surfaceType.downcase == "floor"
          living_surface.setConstruction(finuninsfinfloor)
          runner.registerInfo("Surface '#{living_surface.name}', of Space Type '#{living_space_type_r}' and with Surface Type '#{living_surface.surfaceType}' and Outside Boundary Condition '#{living_surface.outsideBoundaryCondition}', was assigned Construction '#{finuninsfinfloor.name}'")
        elsif living_surface.surfaceType.downcase == "roofceiling"
          living_surface.setConstruction(revfinuninsfinfloor)       
          runner.registerInfo("Surface '#{living_surface.name}', of Space Type '#{living_space_type_r}' and with Surface Type '#{living_surface.surfaceType}' and Outside Boundary Condition '#{living_surface.outsideBoundaryCondition}', was assigned Construction '#{revfinuninsfinfloor.name}'")
        end
      end   
    end
    
    unless fbasement_space_type.nil?
      fbasement_space_type.spaces.each do |fbasement_space|
        fbasement_space.surfaces.each do |fbasement_surface|
          next unless fbasement_surface.outsideBoundaryCondition.downcase == "adiabatic"
          if fbasement_surface.surfaceType.downcase == "roofceiling"
            fbasement_surface.setConstruction(revfinuninsfinfloor)      
            runner.registerInfo("Surface '#{fbasement_surface.name}', of Space Type '#{fbasement_space_type_r}' and with Surface Type '#{fbasement_surface.surfaceType}' and Outside Boundary Condition '#{fbasement_surface.outsideBoundaryCondition}', was assigned Construction '#{revfinuninsfinfloor.name}'")
          end
        end
      end   
    end
    
    unless unfin_attic_space_type.nil?
      unfin_attic_space_type.spaces.each do |unfin_attic_space|
        unfin_attic_space.surfaces.each do |unfin_attic_surface|
          next unless ["floor"].include? unfin_attic_surface.surfaceType.downcase
          adjacent_surface = unfin_attic_surface.adjacentSurface
          next unless adjacent_surface.is_initialized
          adjacent_surface = adjacent_surface.get
          adjacent_surface_r = adjacent_surface.name.to_s
          adjacent_space_type_r = HelperMethods.get_space_type_from_surface(model, adjacent_surface_r)
          next unless [garage_space_type_r].include? adjacent_space_type_r
          unfin_attic_surface.setConstruction(unfinuninsunfinfloor)
          runner.registerInfo("Surface '#{unfin_attic_surface.name}', of Space Type '#{living_space_type_r}' and with Surface Type '#{unfin_attic_surface.surfaceType}' and Outside Boundary Condition '#{unfin_attic_surface.outsideBoundaryCondition}', was assigned Construction '#{unfinuninsunfinfloor.name}'")
          adjacent_surface.setConstruction(revunfinuninsunfinfloor)     
          runner.registerInfo("Surface '#{adjacent_surface.name}', of Space Type '#{adjacent_space_type_r}' and with Surface Type '#{adjacent_surface.surfaceType}' and Outside Boundary Condition '#{adjacent_surface.outsideBoundaryCondition}', was assigned Construction '#{revunfinuninsunfinfloor.name}'")
        end 
      end
    end
    
    return true
 
  end #end the run method

end #end the measure

#this allows the measure to be use by the application
ProcessConstructionsInteriorUninsulatedFloors.new.registerWithApplication