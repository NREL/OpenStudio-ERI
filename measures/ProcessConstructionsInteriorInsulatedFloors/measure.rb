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
    def initialize(intFloorFramingFactor, intFloorCavityInsRvalueNominal)
      @intFloorFramingFactor = intFloorFramingFactor
      @intFloorCavityInsRvalueNominal = intFloorCavityInsRvalueNominal
    end

    attr_accessor(:dummy)

    def IntFloorFramingFactor
      return @intFloorFramingFactor
    end

    def IntFloorCavityInsRvalueNominal
      return @intFloorCavityInsRvalueNominal
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
    return "ProcessConstructionsInteriorInsulatedFloors"
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
    selected_garage = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("selectedgarage", spacetype_handles, spacetype_display_names, true)
    selected_garage.setDisplayName("Of what space type is the garage?")
    args << selected_garage

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

    #make a double argument for nominal R-value of cavity insulation
    userdefined_instcavr = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedinstcavr", true)
    userdefined_instcavr.setDisplayName("R-value of cavity insulation [hr-ft^2-R/Btu].")
    args << userdefined_instcavr

    #make a choice argument for unfinished attic ceiling framing factor
    userdefined_floorff = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedfloorff", false)
    userdefined_floorff.setDisplayName("Interzonal floor framing factor [frac].")
    userdefined_floorff.setDefaultValue(0.13)
    args << userdefined_floorff

    # Floor Mass
    # #make a choice argument for floor mass
    # selected_floormass = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("selectedfloormass", material_handles, material_display_names, false)
    # selected_floormass.setDisplayName("Floor mass. For manually entering floor mass properties, leave blank.")
    # args << selected_floormass

    #make a double argument for floor mass thickness
    userdefined_floormassth = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedfloormassth", false)
    userdefined_floormassth.setDisplayName("Floor mass thickness [in].")
    userdefined_floormassth.setDefaultValue(0.625)
    args << userdefined_floormassth

    #make a double argument for floor mass conductivity
    userdefined_floormasscond = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedfloormasscond", false)
    userdefined_floormasscond.setDisplayName("Floor mass conductivity [Btu-in/h-ft^2-R].")
    userdefined_floormasscond.setDefaultValue(0.8004)
    args << userdefined_floormasscond

    #make a double argument for floor mass density
    userdefined_floormassdens = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedfloormassdens", false)
    userdefined_floormassdens.setDisplayName("Floor mass density [lb/ft^3].")
    userdefined_floormassdens.setDefaultValue(34.0)
    args << userdefined_floormassdens

    #make a double argument for floor mass specific heat
    userdefined_floormasssh = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedfloormasssh", false)
    userdefined_floormasssh.setDisplayName("Floor mass specific heat [Btu/lb-R].")
    userdefined_floormasssh.setDefaultValue(0.29)
    args << userdefined_floormasssh

    # Carpet
    # #make a choice argument for carpet pad R-value
    # selected_carpet = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("selectedcarpet", material_handles, material_display_names, false)
    # selected_carpet.setDisplayName("Carpet. For manually entering carpet properties, leave blank.")
    # args << selected_carpet

    #make a double argument for carpet pad R-value
    userdefined_carpetr = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedcarpetr", false)
    userdefined_carpetr.setDisplayName("Carpet pad R-value [hr-ft^2-R/Btu].")
    userdefined_carpetr.setDefaultValue(2.08)
    args << userdefined_carpetr

    #make a double argument for carpet floor fraction
    userdefined_carpetfrac = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedcarpetfrac", false)
    userdefined_carpetfrac.setDisplayName("Carpet floor fraction [frac].")
    userdefined_carpetfrac.setDefaultValue(0.8)
    args << userdefined_carpetfrac

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
    selected_garage = runner.getOptionalWorkspaceObjectChoiceValue("selectedgarage",user_arguments,model)
    selected_living = runner.getOptionalWorkspaceObjectChoiceValue("selectedliving",user_arguments,model)

    # Cavity
    userdefined_instcavr = runner.getDoubleArgumentValue("userdefinedinstcavr",user_arguments)

    # Floor Framing Factor
    userdefined_floorff = runner.getDoubleArgumentValue("userdefinedfloorff",user_arguments)
    if not ( userdefined_floorff > 0.0 and userdefined_floorff < 1.0 )
      runner.registerError("Invalid interzonal floor framing factor")
      return false
    end

    # Floor Mass
    selected_slabfloormass = runner.getOptionalWorkspaceObjectChoiceValue("selectedfloormass",user_arguments,model)
    if selected_slabfloormass.empty?
      userdefined_floormassth = runner.getDoubleArgumentValue("userdefinedfloormassth",user_arguments)
      userdefined_floormasscond = runner.getDoubleArgumentValue("userdefinedfloormasscond",user_arguments)
      userdefined_floormassdens = runner.getDoubleArgumentValue("userdefinedfloormassdens",user_arguments)
      userdefined_floormasssh = runner.getDoubleArgumentValue("userdefinedfloormasssh",user_arguments)
    end

    # Carpet
    selected_carpet = runner.getOptionalWorkspaceObjectChoiceValue("selectedcarpet",user_arguments,model)
    if selected_carpet.empty?
      userdefined_carpetr = runner.getDoubleArgumentValue("userdefinedcarpetr",user_arguments)
    end
    userdefined_carpetfrac = runner.getDoubleArgumentValue("userdefinedcarpetfrac",user_arguments)

    # Cavity
    intFloorCavityInsRvalueNominal = userdefined_instcavr

    # Floor Framing Factor
    intFloorFramingFactor = userdefined_floorff

    # Floor Mass
    if userdefined_floormassth.nil?
      floorMassThickness = OpenStudio::convert(selected_floormass.get.to_StandardOpaqueMaterial.get.getThickness.value,"m","in").get
      floorMassConductivity = OpenStudio::convert(selected_floormass.get.to_StandardOpaqueMaterial.get.getConductivity.value,"W/m*K","Btu/hr*ft*R").get
      floorMassDensity = OpenStudio::convert(selected_floormass.get.to_StandardOpaqueMaterial.get.getDensity.value,"kg/m^3","lb/ft^3").get
      floorMassSpecificHeat = OpenStudio::convert(selected_floormass.get.to_StandardOpaqueMaterial.get.getSpecificHeat.value,"J/kg*K","Btu/lb*R").get
    else
      floorMassThickness = userdefined_floormassth
      floorMassConductivity = userdefined_floormasscond
      floorMassDensity = userdefined_floormassdens
      floorMassSpecificHeat = userdefined_floormasssh
    end

    # Carpet
    if userdefined_carpetr.nil?
      carpetPadThickness = OpenStudio::convert(selected_carpet.get.to_StandardOpaqueMaterial.get.getThickness.value,"m","in").get
      carpetPadConductivity = OpenStudio::convert(selected_carpet.get.to_StandardOpaqueMaterial.get.getConductivity.value,"W/m*K","Btu/hr*ft*R").get
      carpetPadRValue = OpenStudio::convert(carpetPadThickness,"in","ft").get / carpetPadConductivity
    else
      carpetPadRValue = userdefined_carpetr
    end
    carpetFloorFraction = userdefined_carpetfrac

    # Create the material class instances
    izf = InterzonalFloors.new(intFloorFramingFactor, intFloorCavityInsRvalueNominal)
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
      if selected_garage.get.handle.to_s == space.spaceType.get.handle.to_s
        # loop thru all surfaces attached to the space
        surfaces = space.surfaces
        surfaces.each do |surface|
          if surface.surfaceType == "RoofCeiling" and surface.outsideBoundaryCondition == "Surface"
            surface.resetConstruction
            surface.setConstruction(revunfininsfinfloor)
            constructions_hash[surface.name.to_s] = [surface.surfaceType,surface.outsideBoundaryCondition,"RevUnfinInsFinFloor"]
          end
        end
      elsif selected_living.get.handle.to_s == space.spaceType.get.handle.to_s
        # loop thru all surfaces attached to the space
        surfaces = space.surfaces
        surfaces.each do |surface|
          if surface.surfaceType == "Floor" and surface.outsideBoundaryCondition == "Surface"
            adjacentSpaces = model.getSpaces
            adjacentSpaces.each do |adjacentSpace|
              if selected_garage.get.handle.to_s == adjacentSpace.spaceType.get.handle.to_s
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