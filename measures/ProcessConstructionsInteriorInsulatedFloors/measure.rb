#see the URL below for information on how to write OpenStudio measures
# http://openstudio.nrel.gov/openstudio-measure-writing-guide

#see the URL below for information on using life cycle cost objects in OpenStudio
# http://openstudio.nrel.gov/openstudio-life-cycle-examples

#see the URL below for access to C++ documentation on model objects (click on "model" in the main window to view model objects)
# http://openstudio.nrel.gov/sites/openstudio.nrel.gov/files/nv_data/cpp_documentation_it/model/html/namespaces.html

require "#{File.dirname(__FILE__)}/resources/util"
require "#{File.dirname(__FILE__)}/resources/constants"

#start the measure
class ProcessConstructionsInteriorInsulatedFloors < OpenStudio::Ruleset::ModelUserScript

  #define the name that a user will see, this method may be deprecated as
  #the display name in PAT comes from the name field in measure.xml
  def name
    return "Set Residential Interzonal Floor Construction"
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

    # Initialize hashes
    constructions_to_surfaces = {"UnfinInsFinFloor"=>[], "RevUnfinInsFinFloor"=>[]}
    constructions_to_objects = Hash.new    
    
    # Floor between garage and living
    living_space_type.spaces.each do |living_space|
      living_space.surfaces.each do |living_surface|
        next unless ["floor"].include? living_surface.surfaceType.downcase
        adjacent_surface = living_surface.adjacentSurface
        next unless adjacent_surface.is_initialized
        adjacent_surface = adjacent_surface.get
        adjacent_surface_r = adjacent_surface.name.to_s
        adjacent_space_type_r = HelperMethods.get_space_type_from_surface(model, adjacent_surface_r, runner)
        next unless [garage_space_type_r].include? adjacent_space_type_r
        constructions_to_surfaces["UnfinInsFinFloor"] << living_surface
        constructions_to_surfaces["RevUnfinInsFinFloor"] << adjacent_surface
      end   
    end
    
    # Continue if no applicable surfaces
    if constructions_to_surfaces.all? {|construction, surfaces| surfaces.empty?}
      return true
    end        
    
    # Cavity
    intFloorCavityInsRvalueNominal = runner.getDoubleArgumentValue("userdefinedinstcavr",user_arguments)
    selected_installgrade = runner.getStringArgumentValue("selectedinstallgrade",user_arguments)
    intFloorInstallGrade_dict = {"I"=>1, "II"=>2, "III"=>3}
    intFloorInstallGrade = intFloorInstallGrade_dict[selected_installgrade]

    # Floor Framing Factor
    intFloorFramingFactor = runner.getDoubleArgumentValue("userdefinedfloorff",user_arguments)
    if not ( intFloorFramingFactor > 0.0 and intFloorFramingFactor < 1.0 )
      runner.registerError("Invalid interzonal floor framing factor")
      return false
    end

    # Floor Mass
    floorMassThickness = runner.getDoubleArgumentValue("userdefinedfloormassth",user_arguments)
    floorMassConductivity = runner.getDoubleArgumentValue("userdefinedfloormasscond",user_arguments)
    floorMassDensity = runner.getDoubleArgumentValue("userdefinedfloormassdens",user_arguments)
    floorMassSpecificHeat = runner.getDoubleArgumentValue("userdefinedfloormasssh",user_arguments)

    # Carpet
    carpetPadRValue = runner.getDoubleArgumentValue("userdefinedcarpetr",user_arguments)
    carpetFloorFraction = runner.getDoubleArgumentValue("userdefinedcarpetfrac",user_arguments)

    # Process the wood stud walls
    sc_thick, sc_cond, sc_dens, sc_sh = _processConstructionsInteriorInsulatedFloors(intFloorFramingFactor, intFloorCavityInsRvalueNominal, intFloorInstallGrade, carpetFloorFraction, carpetPadRValue, floorMassThickness, floorMassConductivity, floorMassDensity, floorMassSpecificHeat)

    # Create the material layers

    # IntFloorIns
    ifi = OpenStudio::Model::StandardOpaqueMaterial.new(model)
    ifi.setName("IntFloorIns")
    ifi.setRoughness("Rough")
    ifi.setThickness(OpenStudio::convert(sc_thick,"ft","m").get)
    ifi.setConductivity(OpenStudio::convert(sc_cond,"Btu/hr*ft*R","W/m*K").get)
    ifi.setDensity(OpenStudio::convert(sc_dens,"lb/ft^3","kg/m^3").get)
    ifi.setSpecificHeat(OpenStudio::convert(sc_sh,"Btu/lb*R","J/kg*K").get)

    # Plywood-3_4in
    ply3_4 = OpenStudio::Model::StandardOpaqueMaterial.new(model)
    ply3_4.setName("Plywood-3_4in")
    ply3_4.setRoughness("Rough")
    ply3_4.setThickness(OpenStudio::convert(Material.Plywood3_4in.thick,"ft","m").get)
    ply3_4.setConductivity(OpenStudio::convert(Material.Plywood3_4in.k,"Btu/hr*ft*R","W/m*K").get)
    ply3_4.setDensity(OpenStudio::convert(Material.Plywood3_4in.rho,"lb/ft^3","kg/m^3").get)
    ply3_4.setSpecificHeat(OpenStudio::convert(Material.Plywood3_4in.Cp,"Btu/lb*R","J/kg*K").get)

    # FloorMass
    mat_floor_mass = Material.MassFloor(floorMassThickness, floorMassConductivity, floorMassDensity, floorMassSpecificHeat)
    fm = OpenStudio::Model::StandardOpaqueMaterial.new(model)
    fm.setName("FloorMass")
    fm.setRoughness("Rough")
    fm.setThickness(OpenStudio::convert(mat_floor_mass.thick,"ft","m").get)
    fm.setConductivity(OpenStudio::convert(mat_floor_mass.k,"Btu/hr*ft*R","W/m*K").get)
    fm.setDensity(OpenStudio::convert(mat_floor_mass.rho,"lb/ft^3","kg/m^3").get)
    fm.setSpecificHeat(OpenStudio::convert(mat_floor_mass.Cp,"Btu/lb*R","J/kg*K").get)
    fm.setThermalAbsorptance(mat_floor_mass.TAbs)
    fm.setSolarAbsorptance(mat_floor_mass.SAbs)

    # CarpetBareLayer
    if carpetFloorFraction > 0
      mat_carpet_bare = Material.CarpetBare(carpetFloorFraction, carpetPadRValue)
      cbl = OpenStudio::Model::StandardOpaqueMaterial.new(model)
      cbl.setName("CarpetBareLayer")
      cbl.setRoughness("Rough")
      cbl.setThickness(OpenStudio::convert(mat_carpet_bare.thick,"ft","m").get)
      cbl.setConductivity(OpenStudio::convert(mat_carpet_bare.k,"Btu/hr*ft*R","W/m*K").get)
      cbl.setDensity(OpenStudio::convert(mat_carpet_bare.rho,"lb/ft^3","kg/m^3").get)
      cbl.setSpecificHeat(OpenStudio::convert(mat_carpet_bare.Cp,"Btu/lb*R","J/kg*K").get)
      cbl.setThermalAbsorptance(mat_carpet_bare.TAbs)
      cbl.setSolarAbsorptance(mat_carpet_bare.SAbs)
    end

    # UnfinInsFinFloor
    materials = []
    materials << ifi
    materials << ply3_4
    materials << fm
    if carpetFloorFraction > 0
      materials << cbl
    end
    unless constructions_to_surfaces["UnfinInsFinFloor"].empty?
        unfininsfinfloor = OpenStudio::Model::Construction.new(materials)
        unfininsfinfloor.setName("UnfinInsFinFloor")
        constructions_to_objects["UnfinInsFinFloor"] = unfininsfinfloor
    end

    # RevUnfinInsFinFloor
    unless constructions_to_surfaces["RevUnfinInsFinFloor"].empty?
        revunfininsfinfloor = unfininsfinfloor.reverseConstruction
        revunfininsfinfloor.setName("RevUnfinInsFinFloor")
        constructions_to_objects["RevUnfinInsFinFloor"] = revunfininsfinfloor
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

  def _processConstructionsInteriorInsulatedFloors(intFloorFramingFactor, intFloorCavityInsRvalueNominal, intFloorInstallGrade, carpetFloorFraction, carpetPadRValue, floorMassThickness, floorMassConductivity, floorMassDensity, floorMassSpecificHeat)
  
    izfGapFactor = Construction.GetWallGapFactor(intFloorInstallGrade, intFloorFramingFactor)

    overall_floor_Rvalue = get_interzonal_floor_r_assembly(intFloorFramingFactor, intFloorCavityInsRvalueNominal, intFloorInstallGrade, carpetPadRValue, carpetFloorFraction, floorMassThickness, floorMassConductivity, floorMassDensity, floorMassSpecificHeat, izfGapFactor)

    # Get overall R-value using parallel paths:
    boundaryFloorRvalue = (overall_floor_Rvalue - Construction.GetFloorNonStudLayerR(floorMassThickness, floorMassConductivity, floorMassDensity, floorMassSpecificHeat, carpetFloorFraction, carpetPadRValue))

    sc_thick = Material.Stud2x6.thick # ft
    sc_cond = sc_thick / boundaryFloorRvalue # Btu/hr*ft*F
    sc_dens = intFloorFramingFactor * BaseMaterial.Wood.rho + (1 - intFloorFramingFactor - izfGapFactor) * BaseMaterial.InsulationGenericDensepack.rho  + izfGapFactor * Gas.Air.Cp # lbm/ft^3
    sc_sh = (intFloorFramingFactor * BaseMaterial.Wood.Cp * BaseMaterial.Wood.rho + (1 - intFloorFramingFactor - izfGapFactor) * BaseMaterial.InsulationGenericDensepack.Cp * BaseMaterial.InsulationGenericDensepack.rho + izfGapFactor * Gas.Air.Cp * Gas.Air.Cp) / sc_dens # Btu/lbm*F

    return sc_thick, sc_cond, sc_dens, sc_sh

  end

  
  def get_interzonal_floor_r_assembly(intFloorFramingFactor, intFloorCavityInsRvalueNominal, intFloorInstallGrade, carpetPadRValue, carpetFloorFraction, floorMassThickness, floorMassConductivity, floorMassDensity, floorMassSpecificHeat, izfGapFactor)
      # Returns assembly R-value for interzonal floor, including air films.

      path_fracs = [intFloorFramingFactor, 1 - intFloorFramingFactor - izfGapFactor, izfGapFactor]

      izf_const = Construction.new(path_fracs)

      # Interior Film
      izf_const.addlayer(thickness=OpenStudio::convert(1.0,"in","ft").get, conductivity_list=[OpenStudio::convert(1.0,"in","ft").get / Material.AirFilmFloorReduced.Rvalue])

      # Stud/cavity layer
      if intFloorCavityInsRvalueNominal == 0
        cavity_k = 1000000000
      else
        cavity_k = Material.Stud2x6.thick / intFloorCavityInsRvalueNominal
      end
      gap_k = Material.Stud2x6.thick / Gas.AirGapRvalue
      
      izf_const.addlayer(thickness=Material.Stud2x6.thick, conductivity_list=[BaseMaterial.Wood.k, cavity_k, gap_k])

      # Floor deck
      izf_const.addlayer(thickness=nil, conductivity_list=nil, material=Material.Plywood3_4in, material_list=nil)

      # Floor mass
      if floorMassThickness > 0
        mat_floor_mass = Material.MassFloor(floorMassThickness, floorMassConductivity, floorMassDensity, floorMassSpecificHeat)
        izf_const.addlayer(thickness=nil, conductivity_list=nil, material=mat_floor_mass, material_list=nil)
      end

      # Carpet
      if carpetFloorFraction > 0
        carpet_smeared_cond = OpenStudio::convert(0.5,"in","ft").get / (carpetPadRValue * carpetFloorFraction)
        izf_const.addlayer(thickness=OpenStudio::convert(0.5,"in","ft").get, conductivity_list=[carpet_smeared_cond])
      end

      # Exterior Film
      izf_const.addlayer(thickness=OpenStudio::convert(1.0,"in","ft").get, conductivity_list=[OpenStudio::convert(1.0,"in","ft").get / Material.AirFilmFloorReduced.Rvalue])

      return izf_const.Rvalue_parallel

  end

  
end #end the measure

#this allows the measure to be use by the application
ProcessConstructionsInteriorInsulatedFloors.new.registerWithApplication