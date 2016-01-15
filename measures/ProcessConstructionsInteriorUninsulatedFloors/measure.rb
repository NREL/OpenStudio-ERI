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
    mat_gyp_ceiling = Material.GypsumCeiling
    selected_gypsum = runner.getOptionalWorkspaceObjectChoiceValue("selectedgypsum",user_arguments,model)
    if selected_gypsum.empty?
      gypsumThickness = runner.getDoubleArgumentValue("userdefinedgypthickness",user_arguments)
      gypsumNumLayers = runner.getDoubleArgumentValue("userdefinedgyplayers",user_arguments)
    end
    gypsumConductivity = mat_gyp_ceiling.k
    gypsumDensity = mat_gyp_ceiling.rho
    gypsumSpecificHeat = mat_gyp_ceiling.Cp
    gypsumThermalAbs = mat_gyp_ceiling.TAbs
    gypsumSolarAbs = mat_gyp_ceiling.SAbs
    gypsumVisibleAbs = mat_gyp_ceiling.VAbs
    gypsumRvalue = (OpenStudio::convert(gypsumThickness,"in","ft").get * gypsumNumLayers / mat_gyp_ceiling.k)

    # Floor Mass
    floorMassThickness = runner.getDoubleArgumentValue("userdefinedfloormassth",user_arguments)
    floorMassConductivity = runner.getDoubleArgumentValue("userdefinedfloormasscond",user_arguments)
    floorMassDensity = runner.getDoubleArgumentValue("userdefinedfloormassdens",user_arguments)
    floorMassSpecificHeat = runner.getDoubleArgumentValue("userdefinedfloormasssh",user_arguments)

    # Carpet
    carpetPadRValue = runner.getDoubleArgumentValue("userdefinedcarpetr",user_arguments)
    carpetFloorFraction = runner.getDoubleArgumentValue("userdefinedcarpetfrac",user_arguments)

    weather = WeatherProcess.new(model,runner,header_only=true)
    if weather.error?
        return false
    end

    # Process the interior uninsulated floor
    sc_thick, sc_cond, sc_dens, sc_sh = _processConstructionsInteriorUninsulatedFloors(weather.header.LocalPressure)

    # StudandAirFloor
    saf = OpenStudio::Model::StandardOpaqueMaterial.new(model)
    saf.setName("StudandAirFloor")
    saf.setRoughness("Rough")
    saf.setThickness(OpenStudio::convert(sc_thick,"ft","m").get)
    saf.setConductivity(OpenStudio::convert(sc_cond,"Btu/hr*ft*R","W/m*K").get)
    saf.setDensity(OpenStudio::convert(sc_dens,"lb/ft^3","kg/m^3").get)
    saf.setSpecificHeat(OpenStudio::convert(sc_sh,"Btu/lb*R","J/kg*K").get)

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
    mat_plywood3_4in = Material.Plywood3_4in
    ply3_4 = OpenStudio::Model::StandardOpaqueMaterial.new(model)
    ply3_4.setName("Plywood-3_4in")
    ply3_4.setRoughness("Rough")
    ply3_4.setThickness(OpenStudio::convert(mat_plywood3_4in.thick,"ft","m").get)
    ply3_4.setConductivity(OpenStudio::convert(mat_plywood3_4in.k,"Btu/hr*ft*R","W/m*K").get)
    ply3_4.setDensity(OpenStudio::convert(mat_plywood3_4in.rho,"lb/ft^3","kg/m^3").get)
    ply3_4.setSpecificHeat(OpenStudio::convert(mat_plywood3_4in.Cp,"Btu/lb*R","J/kg*K").get)

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

    # FinUninsFinFloor
    materials = []
    (0...gypsumNumLayers).to_a.each do |i|
      materials << gypsum
    end
    materials << saf
    materials << ply3_4
    materials << fm
    if carpetFloorFraction > 0
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

  def _processConstructionsInteriorUninsulatedFloors(localPressure)
    floor_part_U_cavity_path = (1 - Constants.DefaultFramingFactorFloor) / Gas.AirGapRvalue # Btu/hr*ft^2*F
    floor_part_U_stud_path = Constants.DefaultFramingFactorFloor / Material.Stud2x6.Rvalue # Btu/hr*ft^2*F
    floor_part_Rvalue = 1 / (floor_part_U_cavity_path + floor_part_U_stud_path) # hr*ft^2*F/Btu

    sc_thick = Material.Stud2x4.thick # ft
    sc_cond = sc_thick / floor_part_Rvalue # Btu/hr*ft*F
    sc_dens = Constants.DefaultFramingFactorFloor * BaseMaterial.Wood.rho + (1 - Constants.DefaultFramingFactorFloor) * Gas.AirInsideDensity(localPressure) # lbm/ft^3
    sc_sh = (Constants.DefaultFramingFactorFloor * BaseMaterial.Wood.Cp * BaseMaterial.Wood.rho + (1 - Constants.DefaultFramingFactorFloor) * Gas.Air.Cp * Gas.AirInsideDensity(localPressure)) / sc_dens # Btu/lbm*F

    return sc_thick, sc_cond, sc_dens, sc_sh
  end

  
end #end the measure

#this allows the measure to be use by the application
ProcessConstructionsInteriorUninsulatedFloors.new.registerWithApplication