#see the URL below for information on how to write OpenStudio measures
# http://openstudio.nrel.gov/openstudio-measure-writing-guide

#see the URL below for information on using life cycle cost objects in OpenStudio
# http://openstudio.nrel.gov/openstudio-life-cycle-examples

#see the URL below for access to C++ documentation on model objects (click on "model" in the main window to view model objects)
# http://openstudio.nrel.gov/sites/openstudio.nrel.gov/files/nv_data/cpp_documentation_it/model/html/namespaces.html

#load sim.rb
require "#{File.dirname(__FILE__)}/resources/sim"

#start the measure
class ProcessConstructionsInteriorInsulatedFloors < OpenStudio::Ruleset::ModelUserScript

  class InterzonalFloors
    def initialize(intFloorFramingFactor, intFloorCavityInsRvalueNominal, intFloorInstallGrade)
      @intFloorFramingFactor = intFloorFramingFactor
      @intFloorCavityInsRvalueNominal = intFloorCavityInsRvalueNominal
	  @intFloorInstallGrade = intFloorInstallGrade
    end

    attr_accessor(:dummy)

    def IntFloorFramingFactor
      return @intFloorFramingFactor
    end

    def IntFloorCavityInsRvalueNominal
      return @intFloorCavityInsRvalueNominal
    end
	
	def IntFloorInstallGrade
	  return @intFloorInstallGrade
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

  class IntFloorIns
    def initialize
    end
    attr_accessor(:boundary_floor_thickness, :boundary_floor_conductivity, :boundary_floor_density, :boundary_floor_spec_heat)
  end

  #define the name that a user will see, this method may be deprecated as
  #the display name in PAT comes from the name field in measure.xml
  def name
    return "Assign Residential Interzonal Floor Construction"
  end
  
  def description
    return "This measure assigns a construction to the interzonal floors."
  end
  
  def modeler_description
    return "Calculates material layer properties of insulated constructions for the interzonal floors between the living space and the garage. Finds surfaces adjacent to the living space and garage and sets applicable constructions."
  end    
  
  #define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Ruleset::OSArgumentVector.new

    #make a double argument for nominal R-value of cavity insulation
    userdefined_instcavr = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedinstcavr", true)
    userdefined_instcavr.setDisplayName("Interzonal Floor: Cavity Insulation Nominal R-value")
	userdefined_instcavr.setUnits("hr-ft^2-R/Btu")
	userdefined_instcavr.setDescription("R-value is a measure of insulation's ability to resist heat traveling through it.")
	userdefined_instcavr.setDefaultValue(19.0)
    args << userdefined_instcavr

    #make a choice argument for unfinished attic ceiling framing factor
    userdefined_floorff = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedfloorff", false)
    userdefined_floorff.setDisplayName("Interzonal Floor: Framing Factor")
	userdefined_floorff.setUnits("frac")
	userdefined_floorff.setDescription("The fraction of a floor assembly that is comprised of structural framing.")
    userdefined_floorff.setDefaultValue(0.13)
    args << userdefined_floorff
	
	#make a choice argument for model objects
	installgrade_display_names = OpenStudio::StringVector.new
	installgrade_display_names << "I"
	installgrade_display_names << "II"
	installgrade_display_names << "III"
	
	#make a choice argument for wall cavity insulation installation grade
	selected_installgrade = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("selectedinstallgrade", installgrade_display_names, true)
	selected_installgrade.setDisplayName("Interzonal Floor: Cavity Install Grade")
	selected_installgrade.setDescription("5% of the wall is considered missing insulation for Grade 3, 2% for Grade 2, and 0% for Grade 1.")
    selected_installgrade.setDefaultValue("I")
	args << selected_installgrade	

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
	garage_space_type_r = runner.getStringArgumentValue("garage_space_type",user_arguments)
    garage_space_type = HelperMethods.get_space_type_from_string(model, garage_space_type_r, runner, false)
    if garage_space_type.nil?
        # If the building has no garage, no constructions are assigned and we continue by returning True
        return true
    end

    # Cavity
    userdefined_instcavr = runner.getDoubleArgumentValue("userdefinedinstcavr",user_arguments)
	selected_installgrade = runner.getStringArgumentValue("selectedinstallgrade",user_arguments)

    # Floor Framing Factor
    userdefined_floorff = runner.getDoubleArgumentValue("userdefinedfloorff",user_arguments)
    if not ( userdefined_floorff > 0.0 and userdefined_floorff < 1.0 )
      runner.registerError("Invalid interzonal floor framing factor")
      return false
    end

    # Floor Mass
    userdefined_floormassth = runner.getDoubleArgumentValue("userdefinedfloormassth",user_arguments)
    userdefined_floormasscond = runner.getDoubleArgumentValue("userdefinedfloormasscond",user_arguments)
    userdefined_floormassdens = runner.getDoubleArgumentValue("userdefinedfloormassdens",user_arguments)
    userdefined_floormasssh = runner.getDoubleArgumentValue("userdefinedfloormasssh",user_arguments)

    # Carpet
    userdefined_carpetr = runner.getDoubleArgumentValue("userdefinedcarpetr",user_arguments)
    userdefined_carpetfrac = runner.getDoubleArgumentValue("userdefinedcarpetfrac",user_arguments)

    # Cavity
    intFloorCavityInsRvalueNominal = userdefined_instcavr
	intFloorInstallGrade_dict = {"I"=>1, "II"=>2, "III"=>3}
	intFloorInstallGrade = intFloorInstallGrade_dict[selected_installgrade]

    # Floor Framing Factor
    intFloorFramingFactor = userdefined_floorff

    # Floor Mass
    floorMassThickness = userdefined_floormassth
    floorMassConductivity = userdefined_floormasscond
    floorMassDensity = userdefined_floormassdens
    floorMassSpecificHeat = userdefined_floormasssh

    # Carpet
    carpetPadRValue = userdefined_carpetr
    carpetFloorFraction = userdefined_carpetfrac

    # Create the material class instances
    izf = InterzonalFloors.new(intFloorFramingFactor, intFloorCavityInsRvalueNominal, intFloorInstallGrade)
    carpet = Carpet.new(carpetFloorFraction, carpetPadRValue)
    floor_mass = FloorMass.new(floorMassThickness, floorMassConductivity, floorMassDensity, floorMassSpecificHeat)
    ifi = IntFloorIns.new

    # Create the sim object
    sim = Sim.new(model, runner)

    # Process the wood stud walls
    ifi = sim._processConstructionsInteriorInsulatedFloors(izf, carpet, floor_mass, ifi)

    # Create the material layers

    # IntFloorIns
    ifiThickness = ifi.boundary_floor_thickness
    ifiConductivity = ifi.boundary_floor_conductivity
    ifiDensity = ifi.boundary_floor_density
    ifiSpecificHeat = ifi.boundary_floor_spec_heat
    ifi = OpenStudio::Model::StandardOpaqueMaterial.new(model)
    ifi.setName("IntFloorIns")
    ifi.setRoughness("Rough")
    ifi.setThickness(OpenStudio::convert(ifiThickness,"ft","m").get)
    ifi.setConductivity(OpenStudio::convert(ifiConductivity,"Btu/hr*ft*R","W/m*K").get)
    ifi.setDensity(OpenStudio::convert(ifiDensity,"lb/ft^3","kg/m^3").get)
    ifi.setSpecificHeat(OpenStudio::convert(ifiSpecificHeat,"Btu/lb*R","J/kg*K").get)

    # Plywood-3_4in
    ply3_4 = OpenStudio::Model::StandardOpaqueMaterial.new(model)
    ply3_4.setName("Plywood-3_4in")
    ply3_4.setRoughness("Rough")
    ply3_4.setThickness(OpenStudio::convert(get_mat_plywood3_4in(get_mat_wood).thick,"ft","m").get)
    ply3_4.setConductivity(OpenStudio::convert(get_mat_wood.k,"Btu/hr*ft*R","W/m*K").get)
    ply3_4.setDensity(OpenStudio::convert(get_mat_wood.rho,"lb/ft^3","kg/m^3").get)
    ply3_4.setSpecificHeat(OpenStudio::convert(get_mat_wood.Cp,"Btu/lb*R","J/kg*K").get)

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

    # UnfinInsFinFloor
    layercount = 0
    unfininsfinfloor = OpenStudio::Model::Construction.new(model)
    unfininsfinfloor.setName("UnfinInsFinFloor")
    unfininsfinfloor.insertLayer(layercount,ifi)
    layercount += 1
    unfininsfinfloor.insertLayer(layercount,ply3_4)
    layercount += 1
    unfininsfinfloor.insertLayer(layercount,fm)
    layercount += 1
    if carpet.CarpetFloorFraction > 0
      unfininsfinfloor.insertLayer(layercount,cbl)
    end

    # UnfinInsUnfinFloor
    layercount = 0
    unfininsunfinfloor = OpenStudio::Model::Construction.new(model)
    unfininsunfinfloor.setName("UnfinInsUnfinFloor")
    unfininsunfinfloor.insertLayer(layercount,ifi)
    layercount += 1
    unfininsunfinfloor.insertLayer(layercount,ply3_4)

    # RevUnfinInsFinFloor
    layercount = 0
    revunfininsfinfloor = OpenStudio::Model::Construction.new(model)
    revunfininsfinfloor.setName("RevUnfinInsFinFloor")
    unfininsfinfloor.layers.reverse_each do |layer|
      revunfininsfinfloor.insertLayer(layercount,layer)
      layercount += 1
    end

    # RevUnfinInsUnfinFloor
    layercount = 0
    revunfininsunfinfloor = OpenStudio::Model::Construction.new(model)
    revunfininsunfinfloor.setName("RevUnfinInsUnfinFloor")
    unfininsunfinfloor.layers.reverse_each do |layer|
      revunfininsunfinfloor.insertLayer(layercount,layer)
      layercount += 1
    end

    # loop thru all the spaces
    spaces = model.getSpaces
    spaces.each do |space|
      constructions_hash = {}
      if garage_space_type.handle.to_s == space.spaceType.get.handle.to_s
        # loop thru all surfaces attached to the space
        surfaces = space.surfaces
        surfaces.each do |surface|
          if surface.surfaceType == "RoofCeiling" and surface.outsideBoundaryCondition == "Surface"
            surface.resetConstruction
            surface.setConstruction(revunfininsfinfloor)
            constructions_hash[surface.name.to_s] = [surface.surfaceType,surface.outsideBoundaryCondition,"RevUnfinInsFinFloor"]
          end
        end
      elsif living_space_type.handle.to_s == space.spaceType.get.handle.to_s
        # loop thru all surfaces attached to the space
        surfaces = space.surfaces
        surfaces.each do |surface|
          if surface.surfaceType == "Floor" and surface.outsideBoundaryCondition == "Surface"
            adjacentSpaces = model.getSpaces
            adjacentSpaces.each do |adjacentSpace|
              if garage_space_type.handle.to_s == adjacentSpace.spaceType.get.handle.to_s
                adjacentSurfaces = adjacentSpace.surfaces
                adjacentSurfaces.each do |adjacentSurface|
                  if surface.adjacentSurface.get.handle.to_s == adjacentSurface.handle.to_s
                    surface.resetConstruction
                    surface.setConstruction(unfininsfinfloor)
                    constructions_hash[surface.name.to_s] = [surface.surfaceType,surface.outsideBoundaryCondition,"UnfinInsFinFloor"]
                  end
                end
              end
            end
          end
        end
      end
      constructions_hash.map do |key,value|
        runner.registerInfo("Surface '#{key}', attached to Space '#{space.name.to_s}' of Space Type '#{space.spaceType.get.name.to_s}' and with Surface Type '#{value[0]}' and Outside Boundary Condition '#{value[1]}', was assigned Construction '#{value[2]}'")
      end
    end

    return true


    # loop thru all surfaces attached to the space
    surfaces = space.surfaces
    surfaces.each do |surface|
      if surface.surfaceType == "Floor" and surface.outsideBoundaryCondition == "Surface"
        surface.resetConstruction
        surface.setConstruction(unfininsfinfloor)
        constructions_hash[surface.name.to_s] = [surface.surfaceType,surface.outsideBoundaryCondition,"UnfinInsFinFloor"]
      end
    end

  end #end the run method

end #end the measure

#this allows the measure to be use by the application
ProcessConstructionsInteriorInsulatedFloors.new.registerWithApplication