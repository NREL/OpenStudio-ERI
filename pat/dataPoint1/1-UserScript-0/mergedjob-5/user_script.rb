#see the URL below for information on how to write OpenStudio measures
# http://openstudio.nrel.gov/openstudio-measure-writing-guide

#see the URL below for information on using life cycle cost objects in OpenStudio
# http://openstudio.nrel.gov/openstudio-life-cycle-examples

#see the URL below for access to C++ documentation on model objects (click on "model" in the main window to view model objects)
# http://openstudio.nrel.gov/sites/openstudio.nrel.gov/files/nv_data/cpp_documentation_it/model/html/namespaces.html

#load sim.rb
require "#{File.dirname(__FILE__)}/resources/sim"

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
    return "ProcessConstructionsInteriorUninsulatedFloors"
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

    #make a choice argument for crawlspace
    selected_living = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("selectedliving", spacetype_handles, spacetype_display_names, true)
    selected_living.setDisplayName("Of what space type is the living space?")
    args << selected_living

    #make a choice argument for fbsmt
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

    #make a choice argument for interior finish of cavity
    selected_gypsum = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("selectedgypsum", material_handles, material_display_names, false)
    selected_gypsum.setDisplayName("Interior finish (gypsum) of cavity. For manually entering interior finish properties of cavity, leave blank.")
    args << selected_gypsum

    #make a double argument for thickness of gypsum
    userdefined_gypthickness = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedgypthickness", false)
    userdefined_gypthickness.setDisplayName("Thickness of drywall layers [in].")
    args << userdefined_gypthickness

    #make a double argument for number of gypsum layers
    userdefined_gyplayers = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedgyplayers", false)
    userdefined_gyplayers.setDisplayName("Number of drywall layers.")
    args << userdefined_gyplayers

    # Floor Mass
    #make a choice argument for floor mass
    selected_floormass = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("selectedfloormass", material_handles, material_display_names, false)
    selected_floormass.setDisplayName("Floor mass. For manually entering floor mass properties, leave blank.")
    args << selected_floormass

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
    #make a choice argument for carpet pad R-value
    selected_carpet = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("selectedcarpet", material_handles, material_display_names, false)
    selected_carpet.setDisplayName("Carpet. For manually entering carpet properties, leave blank.")
    args << selected_carpet

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

    ceilingMassPCMType = nil

    # Space Type
    selected_living = runner.getOptionalWorkspaceObjectChoiceValue("selectedliving",user_arguments,model)
    selected_fbsmt = runner.getOptionalWorkspaceObjectChoiceValue("selectedfbsmt",user_arguments,model)

    # Gypsum
    selected_gypsum = runner.getOptionalWorkspaceObjectChoiceValue("selectedgypsum",user_arguments,model)
    if selected_gypsum.empty?
      userdefined_gypthickness = runner.getDoubleArgumentValue("userdefinedgypthickness",user_arguments)
      userdefined_gyplayers = runner.getDoubleArgumentValue("userdefinedgyplayers",user_arguments)
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

    # Constants
    mat_gyp = get_mat_gypsum
    mat_wood = get_mat_wood
    constants = Constants.new

    # Gypsum
    if userdefined_gypthickness.nil?
      gypsumRoughness = selected_gypsum.get.to_StandardOpaqueMaterial.get.roughness
      gypsumThickness = OpenStudio::convert(selected_gypsum.get.to_StandardOpaqueMaterial.get.getThickness.value,"m","in").get
      gypsumNumLayers = 1.0
      gypsumConductivity = OpenStudio::convert(selected_gypsum.get.to_StandardOpaqueMaterial.get.getConductivity.value,"W/m*K","Btu/hr*ft*R").get
      gypsumDensity = OpenStudio::convert(selected_gypsum.get.to_StandardOpaqueMaterial.get.getDensity.value,"kg/m^3","lb/ft^3").get
      gypsumSpecificHeat = OpenStudio::convert(selected_gypsum.get.to_StandardOpaqueMaterial.get.getSpecificHeat.value,"J/kg*K","Btu/lb*R").get
      gypsumThermalAbs = selected_gypsum.get.to_StandardOpaqueMaterial.get.getThermalAbsorptance.value
      gypsumSolarAbs = selected_gypsum.get.to_StandardOpaqueMaterial.get.getSolarAbsorptance.value
      gypsumVisibleAbs = selected_gypsum.get.to_StandardOpaqueMaterial.get.getVisibleAbsorptance.value
      gypsumRvalue = OpenStudio::convert(gypsumThickness,"in","ft").get / gypsumConductivity
    else
      gypsumRoughness = "Rough"
      gypsumThickness = userdefined_gypthickness
      gypsumNumLayers = userdefined_gyplayers
      gypsumConductivity = mat_gyp.k
      gypsumDensity = mat_gyp.rho
      gypsumSpecificHeat = mat_gyp.Cp
      gypsumThermalAbs = get_mat_gypsum_ceiling(mat_gyp).TAbs
      gypsumSolarAbs = get_mat_gypsum_ceiling(mat_gyp).SAbs
      gypsumVisibleAbs = get_mat_gypsum_ceiling(mat_gyp).VAbs
      gypsumRvalue = (OpenStudio::convert(gypsumThickness,"in","ft").get * userdefined_gyplayers / mat_gyp.k)
    end

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
    ceiling_mass = CeilingMass.new(gypsumThickness, gypsumNumLayers, gypsumRvalue, ceilingMassPCMType)
    floor_mass = FloorMass.new(floorMassThickness, floorMassConductivity, floorMassDensity, floorMassSpecificHeat)
    carpet = Carpet.new(carpetFloorFraction, carpetPadRValue)
    saf = StudandAirFloor.new

    # Create the sim object
    sim = Sim.new(model)

    # Process the interior uninsulated floor
    saf = sim._processConstructionsInteriorUninsulatedFloors(saf)

    # ConcPCMCeilWall
    if ceiling_mass.CeilingMassPCMType == constants.PCMtypeConcentrated
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
    gypsum.setRoughness(gypsumRoughness)
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
    layercount = 0
    finuninsfinfloor = OpenStudio::Model::Construction.new(model)
    finuninsfinfloor.setName("FinUninsFinFloor")
    if ceiling_mass.CeilingMassPCMType == constants.PCMtypeConcentrated
      finuninsfinfloor.insertLayer(layercount,pcm)
      layercount += 1
    end
    (0...gypsumNumLayers).to_a.each do |i|
      finuninsfinfloor.insertLayer(layercount,gypsum)
      layercount += 1
    end
    finuninsfinfloor.insertLayer(layercount,saf)
    layercount += 1
    finuninsfinfloor.insertLayer(layercount,ply3_4)
    layercount += 1
    finuninsfinfloor.insertLayer(layercount,fm)
    layercount += 1
    if carpet.CarpetFloorFraction > 0
      finuninsfinfloor.insertLayer(layercount,cbl)
    end

    # RevFinUninsFinFloor
    layercount = 0
    revfinuninsfinfloor = OpenStudio::Model::Construction.new(model)
    revfinuninsfinfloor.setName("RevFinUninsFinFloor")
    finuninsfinfloor.layers.reverse_each do |layer|
      revfinuninsfinfloor.insertLayer(layercount,layer)
      layercount += 1
    end

    # UnfinUninsUnfinFloor
    layercount = 0
    unfinuninsunfinfloor = OpenStudio::Model::Construction.new(model)
    unfinuninsunfinfloor.setName("UnfinUninsUnfinFloor")
    unfinuninsunfinfloor.insertLayer(layercount,saf)
    layercount += 1
    unfinuninsunfinfloor.insertLayer(layercount,ply3_4)

    # RevUnfinUninsUnfinFloor
    layercount = 0
    revunfinuninsunfinfloor = OpenStudio::Model::Construction.new(model)
    revunfinuninsunfinfloor.setName("RevUnfinUninsUnfinFloor")
    finuninsfinfloor.layers.reverse_each do |layer|
      revunfinuninsunfinfloor.insertLayer(layercount,layer)
      layercount += 1
    end

    # loop thru all the spaces
    spaces = model.getSpaces
    spaces.each do |space|
      constructions_hash = {}
      if selected_living.get.handle.to_s == space.spaceType.get.handle.to_s
        # loop thru all surfaces attached to the space
        surfaces = space.surfaces
        surfaces.each do |surface|
          if surface.surfaceType == "RoofCeiling" and surface.outsideBoundaryCondition == "Adiabatic"
            surface.resetConstruction
            surface.setConstruction(revfinuninsfinfloor)
            constructions_hash[surface.name.to_s] = [surface.surfaceType,surface.outsideBoundaryCondition,"RevFinUninsFinFloor"]
          elsif surface.surfaceType == "Floor" and surface.outsideBoundaryCondition == "Adiabatic"
            surface.resetConstruction
            surface.setConstruction(finuninsfinfloor)
            constructions_hash[surface.name.to_s] = [surface.surfaceType,surface.outsideBoundaryCondition,"FinUninsFinFloor"]
          end
        end
      end
      if not selected_fbsmt.empty?
        if selected_fbsmt.get.handle.to_s == space.spaceType.get.handle.to_s
          # loop thru all surfaces attached to the space
          surfaces = space.surfaces
          surfaces.each do |surface|
            if surface.surfaceType == "RoofCeiling" and surface.outsideBoundaryCondition == "Surface"
              surface.resetConstruction
              surface.setConstruction(revfinuninsfinfloor)
              constructions_hash[surface.name.to_s] = [surface.surfaceType,surface.outsideBoundaryCondition,"RevFinUninsFinFloor"]
            end
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
ProcessConstructionsInteriorUninsulatedFloors.new.registerWithApplication