#see the URL below for information on how to write OpenStudio measures
# http://openstudio.nrel.gov/openstudio-measure-writing-guide

#see the URL below for information on using life cycle cost objects in OpenStudio
# http://openstudio.nrel.gov/openstudio-life-cycle-examples

#see the URL below for access to C++ documentation on model objects (click on "model" in the main window to view model objects)
# http://openstudio.nrel.gov/sites/openstudio.nrel.gov/files/nv_data/cpp_documentation_it/model/html/namespaces.html

#load sim.rb
require "#{File.dirname(__FILE__)}/resources/sim"

#start the measure
class ProcessConstructionsUnfinishedBasement < OpenStudio::Ruleset::ModelUserScript
  
  #define the name that a user will see, this method may be deprecated as
  #the display name in PAT comes from the name field in measure.xml
  def name
    return "Assign Residential Unfinished Basement Constructions"
  end
  
  def description
    return "This measure assigns constructions to the unfinished basement ceiling, walls, floor, and rim joists."
  end
  
  def modeler_description
    return "Calculates material layer properties of wood stud constructions for the exterior walls adjacent to the living space. Finds surfaces adjacent to the living space and sets applicable constructions."
  end  
  
  #define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Ruleset::OSArgumentVector.new

	#make a choice argument for model objects
	ufbsmtins_display_names = OpenStudio::StringVector.new
	ufbsmtins_display_names << "Uninsulated"
	ufbsmtins_display_names << "Half Wall"
	ufbsmtins_display_names << "Whole Wall"
	ufbsmtins_display_names << "Ceiling"
	
	#make a choice argument for unfinished basement insulation type
	selected_ufbsmtins = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("selectedufbsmtins", ufbsmtins_display_names, true)
	selected_ufbsmtins.setDisplayName("Unfinished Basement: Insulation Type")
	selected_ufbsmtins.setDescription("The type of insulation.")
	selected_ufbsmtins.setDefaultValue("Whole Wall")
	args << selected_ufbsmtins	

	#make a choice argument for model objects
	studsize_display_names = OpenStudio::StringVector.new
    studsize_display_names << "None"
	studsize_display_names << "2x4, 16 in o.c."
	studsize_display_names << "2x6, 24 in o.c."

    #make a string argument for wood stud size of wall cavity
    selected_studsize = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("selectedstudsize", studsize_display_names, false)
    selected_studsize.setDisplayName("Unfinished Basement: Wall Cavity Depth")
	selected_studsize.setUnits("in")
	selected_studsize.setDescription("Depth of the study cavity.")
    selected_studsize.setDefaultValue("None")
    args << selected_studsize
	
	#make a double argument for unfinished basement ceiling / whole wall cavity insulation R-value
	userdefined_ufbsmtwallceilcavr = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedufbsmtwallceilcavr", false)
	userdefined_ufbsmtwallceilcavr.setDisplayName("Unfinished Basement: Wall/Ceiling Cavity Insulation Nominal R-value")
	userdefined_ufbsmtwallceilcavr.setUnits("hr-ft^2-R/Btu")
	userdefined_ufbsmtwallceilcavr.setDescription("R-value is a measure of insulation's ability to resist heat traveling through it.")
	userdefined_ufbsmtwallceilcavr.setDefaultValue(0)
	args << userdefined_ufbsmtwallceilcavr
	
	#make a choice argument for model objects
	installgrade_display_names = OpenStudio::StringVector.new
	installgrade_display_names << "I"
	installgrade_display_names << "II"
	installgrade_display_names << "III"	
	
	#make a choice argument for wall cavity insulation installation grade
	selected_installgrade = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("selectedinstallgrade", installgrade_display_names, true)
	selected_installgrade.setDisplayName("Unfinished Basement: Wall Cavity Install Grade")
	selected_installgrade.setDescription("5% of the wall is considered missing insulation for Grade 3, 2% for Grade 2, and 0% for Grade 1.")
    selected_installgrade.setDefaultValue("I")
	args << selected_installgrade
	
	#make a bool argument for whether the cavity insulation fills the cavity
	selected_insfills = OpenStudio::Ruleset::OSArgument::makeBoolArgument("selectedinsfills", true)
	selected_insfills.setDisplayName("Unfinished Basement: Wall Insulation Fills Cavity")
	selected_insfills.setDescription("Specifies whether the cavity insulation completely fills the depth of the wall cavity.")
    selected_insfills.setDefaultValue(false)
	args << selected_insfills

	#make a double argument for unfinished basement wall continuous R-value
	userdefined_ufbsmtwallcontth = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedufbsmtwallcontth", false)
	userdefined_ufbsmtwallcontth.setDisplayName("Unfinished Basement: Wall Continuous Insulation Thickness")
	userdefined_ufbsmtwallcontth.setUnits("in")
	userdefined_ufbsmtwallcontth.setDescription("The thickness of the continuous insulation.")
	userdefined_ufbsmtwallcontth.setDefaultValue(2.0)
	args << userdefined_ufbsmtwallcontth	
	
	#make a double argument for unfinished basement wall continuous insulation R-value
	userdefined_ufbsmtwallcontr = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedufbsmtwallcontr", false)
	userdefined_ufbsmtwallcontr.setDisplayName("Unfinished Basement: Wall Continuous Insulation Nominal R-value")
	userdefined_ufbsmtwallcontr.setUnits("hr-ft^2-R/Btu")
	userdefined_ufbsmtwallcontr.setDescription("R-value is a measure of insulation's ability to resist heat traveling through it.")
	userdefined_ufbsmtwallcontr.setDefaultValue(10.0)
	args << userdefined_ufbsmtwallcontr	
	
	# Ceiling Joist Height
	#make a choice argument for model objects
	joistheight_display_names = OpenStudio::StringVector.new
	joistheight_display_names << "2x10"
	
	#make a choice argument for unfinished basement ceiling joist height
	selected_ufbsmtceiljoistheight = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("selectedufbsmtceiljoistheight", joistheight_display_names, true)
	selected_ufbsmtceiljoistheight.setDisplayName("Unfinished Basement: Ceiling Joist Height")
	selected_ufbsmtceiljoistheight.setUnits("in")
	selected_ufbsmtceiljoistheight.setDescription("Height of the joist member.")
	selected_ufbsmtceiljoistheight.setDefaultValue("2x10")
	args << selected_ufbsmtceiljoistheight	
	
	# Ceiling Framing Factor
	#make a choice argument for unfinished basement ceiling framing factor
	userdefined_ufbsmtceilff = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedufbsmtceilff", false)
    userdefined_ufbsmtceilff.setDisplayName("Unfinished Basement: Ceiling Framing Factor")
	userdefined_ufbsmtceilff.setUnits("frac")
	userdefined_ufbsmtceilff.setDescription("Fraction of ceiling that is framing.")
    userdefined_ufbsmtceilff.setDefaultValue(0.13)
	args << userdefined_ufbsmtceilff
	
	#make a double argument for rim joist insulation R-value
	userdefined_ufbsmtrimjoistr = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedufbsmtrimjoistr", false)
	userdefined_ufbsmtrimjoistr.setDisplayName("Unfinished Basement: Rim Joist Insulation R-value")
	userdefined_ufbsmtrimjoistr.setUnits("hr-ft^2-R/Btu")
	userdefined_ufbsmtrimjoistr.setDescription("R-value is a measure of insulation's ability to resist heat traveling through it.")
	userdefined_ufbsmtrimjoistr.setDefaultValue(10.0)
	args << userdefined_ufbsmtrimjoistr
	
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

    #make a choice argument for unfinished basement space type
    space_types = model.getSpaceTypes
    space_type_args = OpenStudio::StringVector.new
    space_types.each do |space_type|
        space_type_args << space_type.name.to_s
    end
    if not space_type_args.include?(Constants.UnfinishedBasementSpaceType)
        space_type_args << Constants.UnfinishedBasementSpaceType
    end
    ubasement_space_type = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("ubasement_space_type", space_type_args, true)
    ubasement_space_type.setDisplayName("Unfinished basement space type")
    ubasement_space_type.setDescription("Select the unfinished basement space type")
    ubasement_space_type.setDefaultValue(Constants.UnfinishedBasementSpaceType)
    args << ubasement_space_type
	
    return args
  end #end the arguments method

  #define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)
    
    #use the built-in error checking 
    if not runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

	ufbsmtWallContInsRvalue = 0
	ufbsmtWallCavityInsRvalueInstalled = 0
	ufbsmtCeilingCavityInsRvalueNominal = 0
	ufbsmtWallInsHeight = 0
	ufbsmtRimJoistInsRvalue = 0
	carpetPadRValue = 0

    # Space Type
	living_space_type_r = runner.getStringArgumentValue("living_space_type",user_arguments)
    living_space_type = HelperMethods.get_space_type_from_string(model, living_space_type_r, runner)
    if living_space_type.nil?
        return false
    end
	ubasement_space_type_r = runner.getStringArgumentValue("ubasement_space_type",user_arguments)
    ubasement_space_type = HelperMethods.get_space_type_from_string(model, ubasement_space_type_r, runner, false)
    if ubasement_space_type.nil?
        # If the building has no unfinished basement, no constructions are assigned and we continue by returning True
        return true
    end

	# Unfinished Basement Insulation
	selected_ufbsmtins = runner.getStringArgumentValue("selectedufbsmtins",user_arguments)	
	
	# Wall Cavity
	selected_studsize = runner.getStringArgumentValue("selectedstudsize",user_arguments)
	userdefined_ufbsmtwallceilcavr = runner.getDoubleArgumentValue("userdefinedufbsmtwallceilcavr",user_arguments)
	selected_installgrade = runner.getStringArgumentValue("selectedinstallgrade",user_arguments)
	selected_insfills = runner.getBoolArgumentValue("selectedinsfills",user_arguments)	

	# Whole Wall / Ceiling Cavity Insulation
	if ["Half Wall", "Whole Wall", "Ceiling"].include? selected_ufbsmtins.to_s
		userdefined_ufbsmtwallceilcavr = runner.getDoubleArgumentValue("userdefinedufbsmtwallceilcavr",user_arguments)
	end
	
	# Wall Continuous Insulation
	if ["Half Wall", "Whole Wall"].include? selected_ufbsmtins.to_s
		userdefined_ufbsmtwallcontth = runner.getDoubleArgumentValue("userdefinedufbsmtwallcontth",user_arguments)
		userdefined_ufbsmtwallcontr = runner.getDoubleArgumentValue("userdefinedufbsmtwallcontr",user_arguments)
		if selected_ufbsmtins.to_s == "Half Wall"
			ufbsmtWallInsHeight = 4
		elsif selected_ufbsmtins.to_s == "Whole Wall"
			ufbsmtWallInsHeight = 8
		end
	end	
	
	# Ceiling Joist Height
	selected_ufbsmtceiljoistheight = runner.getStringArgumentValue("selectedufbsmtceiljoistheight",user_arguments)
	
	# Ceiling Framing Factor
	userdefined_ufbsmtceilff = runner.getDoubleArgumentValue("userdefinedufbsmtceilff",user_arguments)
    if not ( userdefined_ufbsmtceilff > 0.0 and userdefined_ufbsmtceilff < 1.0 )
      runner.registerError("Invalid unfinished basement ceiling framing factor")
      return false
    end
	
	# Rim Joist
	if ["Half Wall", "Whole Wall"].include? selected_ufbsmtins.to_s
		userdefined_ufbsmtrimjoistr = runner.getDoubleArgumentValue("userdefinedufbsmtrimjoistr",user_arguments)
	end

    # Gypsum
    userdefined_gypthickness = 0
    userdefined_gyplayers = 0
    constructions = model.getConstructions
    constructions.each do |construction|
      if construction.name.to_s == "ExtInsFinWall"
        userdefined_gyplayers = 0
        construction.layers.each do |layer|
          if layer.name.to_s == "GypsumBoard-ExtWall"
            userdefined_gypthickness = OpenStudio::convert(layer.thickness,"m","in").get
            userdefined_gyplayers += 1
          end
        end
      end
    end
	
	# Floor Mass
	floorMassThickness = runner.getDoubleArgumentValue("userdefinedfloormassth",user_arguments)
	floorMassConductivity = runner.getDoubleArgumentValue("userdefinedfloormasscond",user_arguments)
	floorMassDensity = runner.getDoubleArgumentValue("userdefinedfloormassdens",user_arguments)
	floorMassSpecificHeat = runner.getDoubleArgumentValue("userdefinedfloormasssh",user_arguments)
	
	# Carpet
	selected_carpet = runner.getOptionalWorkspaceObjectChoiceValue("selectedcarpet",user_arguments,model)
	if selected_carpet.empty?
		carpetPadRValue = runner.getDoubleArgumentValue("userdefinedcarpetr",user_arguments)
	end
	carpetFloorFraction = runner.getDoubleArgumentValue("userdefinedcarpetfrac",user_arguments)	
	
	# Constants
	mat_gyp = get_mat_gypsum
	mat_wood = get_mat_wood
	mat_soil = get_mat_soil
	mat_concrete = get_mat_concrete	
	
	# Cavity Insulation
	if selected_ufbsmtins.to_s == "Half Wall" or selected_ufbsmtins.to_s == "Whole Wall"
		ufbsmtWallCavityInsRvalueInstalled = userdefined_ufbsmtwallceilcavr
	elsif selected_ufbsmtins.to_s == "Ceiling"
		ufbsmtCeilingCavityInsRvalueNominal = userdefined_ufbsmtwallceilcavr
	end
	
	# Continuous Insulation
	if ["Half Wall", "Whole Wall"].include? selected_ufbsmtins.to_s
		ufbsmtWallContInsThickness = userdefined_ufbsmtwallcontth
		ufbsmtWallContInsRvalue = userdefined_ufbsmtwallcontr
	end	
	
	# Wall Cavity
	ufbsmtWallInstallGrade_dict = {"I"=>1, "II"=>2, "III"=>3}
	ufbsmtWallInstallGrade = ufbsmtWallInstallGrade_dict[selected_installgrade]	
	ufbsmtWallCavityDepth_dict = {"None"=>0, "2x4, 16 in o.c."=>3.5, "2x6, 24 in o.c."=>5.5}
	ufbsmtWallCavityDepth = ufbsmtWallCavityDepth_dict[selected_studsize]
	ufbsmtWallFramingFactor_dict = {"None"=>0, "2x4, 16 in o.c."=>0.25, "2x6, 24 in o.c."=>0.22}
	ufbsmtWallFramingFactor = ufbsmtWallFramingFactor_dict[selected_studsize]
	ufbsmtWallCavityInsFillsCavity = selected_insfills
	
	# Ceiling Joist Height
	ufbsmtCeilingJoistHeight_dict = {"2x10"=>9.25}
	ufbsmtCeilingJoistHeight = ufbsmtCeilingJoistHeight_dict[selected_ufbsmtceiljoistheight]	
		
	# Ceiling Framing Factor
	ufbsmtCeilingFramingFactor = userdefined_ufbsmtceilff
	
	# Rim Joist
	if ["Half Wall", "Whole Wall"].include? selected_ufbsmtins.to_s
		ufbsmtRimJoistInsRvalue = userdefined_ufbsmtrimjoistr
	end
	
	# Gypsum	
    gypsumThickness = userdefined_gypthickness
    gypsumNumLayers = userdefined_gyplayers
    mat_gypsum1_2in = get_mat_gypsum1_2in
    gypsumConductivity = mat_gypsum1_2in.k
    gypsumDensity = mat_gypsum1_2in.rho
    gypsumSpecificHeat = mat_gypsum1_2in.Cp
    gypsumThermalAbs = mat_gypsum1_2in.TAbs
    gypsumSolarAbs = mat_gypsum1_2in.SAbs
    gypsumVisibleAbs = mat_gypsum1_2in.VAbs
    gypsumRvalue = (OpenStudio::convert(gypsumThickness,"in","ft").get * gypsumNumLayers / mat_gypsum1_2in.k)

    # Exterior Finish
    finishThickness = 0
    finishConductivity = 0
    extfin = nil
    constructions = model.getConstructions
    constructions.each do |construction|
      if construction.name.to_s == "ExtInsFinWall"
        construction.layers.each do |layer|
          if layer.name.to_s == "ExteriorFinish"
            extfin = layer
            finishThickness = OpenStudio::convert(layer.thickness,"m","in").get
            finishConductivity = OpenStudio::convert(layer.to_StandardOpaqueMaterial.get.conductivity,"W/m*K","Btu*in/hr*ft^2*R").get
          end
        end
      end
    end

    # Rigid
    wallSheathingContInsThickness = 0
    wallSheathingContInsRvalue = 0
    constructions = model.getConstructions
    constructions.each do |construction|
      if construction.name.to_s == "ExtInsFinWall"
        construction.layers.each do |layer|
          if layer.name.to_s == "WallRigidIns"
            wallSheathingContInsThickness = OpenStudio::convert(layer.thickness,"m","in").get
            wallSheathingContInsThickness = OpenStudio::convert(layer.to_StandardOpaqueMaterial.get.conductivity,"W/m*K","Btu*in/hr*ft^2*R").get
          end
        end
      end
    end

	# Process the slab
	ceiling_Rvalue, ceiling_thick, ceiling_cond, ceiling_dens, ceiling_sh, wall_thick, wall_cond, wall_dens, wall_sh, wall_add_insul_layer, ub_fictitious_Rvalue, ub_basement_floor_Rvalue, rj_thick, rj_cond, rj_dens, rj_sh, rj_Rvalue, rigid_thick, rigid_cond, rigid_dens, rigid_sh = _processConstructionsUnfinishedBasement(ufbsmtCeilingJoistHeight, ufbsmtCeilingFramingFactor, ufbsmtWallInsHeight, ufbsmtWallContInsThickness, ufbsmtWallFramingFactor, ufbsmtWallCavityDepth, ufbsmtWallInstallGrade, ufbsmtWallCavityInsFillsCavity, ufbsmtCeilingCavityInsRvalueNominal, ufbsmtRimJoistInsRvalue, ufbsmtWallCavityInsRvalueInstalled, ufbsmtWallContInsRvalue, carpetFloorFraction, carpetPadRValue, floorMassThickness, floorMassConductivity, floorMassDensity, floorMassSpecificHeat, gypsumThickness, gypsumNumLayers, gypsumRvalue, wallSheathingContInsThickness, wallSheathingContInsRvalue, finishThickness, finishConductivity)	
    
	# UFBsmtCeilingIns
	if ceiling_Rvalue > 0
		uci = OpenStudio::Model::StandardOpaqueMaterial.new(model)
		uci.setName("UFBsmtCeilingIns")
		uci.setRoughness("Rough")
		uci.setThickness(OpenStudio::convert(ceiling_thick,"ft","m").get)
		uci.setConductivity(OpenStudio::convert(ceiling_cond,"Btu/hr*ft*R","W/m*K").get)
		uci.setDensity(OpenStudio::convert(ceiling_dens,"lb/ft^3","kg/m^3").get)
		uci.setSpecificHeat(OpenStudio::convert(ceiling_sh,"Btu/lb*R","J/kg*K").get)
	end
	
	# Plywood-3_4in
    mat_plywood3_4in = get_mat_plywood3_4in
	ply3_4 = OpenStudio::Model::StandardOpaqueMaterial.new(model)
	ply3_4.setName("Plywood-3_4in")
	ply3_4.setRoughness("Rough")
	ply3_4.setThickness(OpenStudio::convert(mat_plywood3_4in.thick,"ft","m").get)
	ply3_4.setConductivity(OpenStudio::convert(mat_plywood3_4in.k,"Btu/hr*ft*R","W/m*K").get)
	ply3_4.setDensity(OpenStudio::convert(mat_plywood3_4in.rho,"lb/ft^3","kg/m^3").get)
	ply3_4.setSpecificHeat(OpenStudio::convert(mat_plywood3_4in.Cp,"Btu/lb*R","J/kg*K").get)	

	# FloorMass
    mat_floor_mass = get_mat_floor_mass(floorMassThickness, floorMassConductivity, floorMassDensity, floorMassSpecificHeat)
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
        mat_carpet_bare = get_mat_carpet_bare(carpetFloorFraction, carpetPadRValue)
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
	
	# UnfinBInsFinFloor
	materials = []
	if ceiling_Rvalue > 0
		materials << uci
	end
	materials << ply3_4
	materials << fm
	if carpetFloorFraction > 0
		materials << cbl
	end
	unfinbinsfinfloor = OpenStudio::Model::Construction.new(materials)
	unfinbinsfinfloor.setName("UnfinBInsFinFloor")	
	
	# UFBaseWallIns
	if wall_add_insul_layer
		uwi = OpenStudio::Model::StandardOpaqueMaterial.new(model)
		uwi.setName("UFBaseWallIns")
		uwi.setThickness(OpenStudio::convert(wall_thick,"ft","m").get)
		uwi.setConductivity(OpenStudio::convert(wall_cond,"Btu/hr*ft*R","W/m*K").get)
		uwi.setDensity(OpenStudio::convert(wall_dens,"lb/ft^3","kg/m^3").get)
		uwi.setSpecificHeat(OpenStudio::convert(wall_sh,"Btu/lb*R","J/kg*K").get)
	end
	
	# UFBaseWall-FicR
	if ub_fictitious_Rvalue > 0
		uwfr = OpenStudio::Model::MasslessOpaqueMaterial.new(model)
		uwfr.setName("UFBaseWall-FicR")
		uwfr.setRoughness("Rough")
		uwfr.setThermalResistance(OpenStudio::convert(ub_fictitious_Rvalue,"hr*ft^2*R/Btu","m^2*K/W").get)
	end
	
	# Soil-12in
	soil = OpenStudio::Model::StandardOpaqueMaterial.new(model)
	soil.setName("Soil-12in")
	soil.setRoughness("Rough")
	soil.setThickness(OpenStudio::convert(get_mat_soil12in.thick,"ft","m").get)
	soil.setConductivity(OpenStudio::convert(mat_soil.k,"Btu/hr*ft*R","W/m*K").get)
	soil.setDensity(OpenStudio::convert(mat_soil.rho,"lb/ft^3","kg/m^3").get)
	soil.setSpecificHeat(OpenStudio::convert(mat_soil.Cp,"Btu/lb*R","J/kg*K").get)	
	
	# Concrete-8in
    mat_concrete8in = get_mat_concrete8in
	conc8 = OpenStudio::Model::StandardOpaqueMaterial.new(model)
	conc8.setName("Concrete-8in")
	conc8.setRoughness("Rough")
	conc8.setThickness(OpenStudio::convert(mat_concrete8in.thick,"ft","m").get)
	conc8.setConductivity(OpenStudio::convert(mat_concrete8in.k,"Btu/hr*ft*R","W/m*K").get)
	conc8.setDensity(OpenStudio::convert(mat_concrete8in.rho,"lb/ft^3","kg/m^3").get)
	conc8.setSpecificHeat(OpenStudio::convert(mat_concrete8in.Cp,"Btu/lb*R","J/kg*K").get)
	conc8.setThermalAbsorptance(mat_concrete8in.TAbs)	
	
	# GrndInsUnfinBWall
	materials = []
	if ub_fictitious_Rvalue > 0
		# Fictitious layer behind unfinished basement wall to achieve equivalent R-value. See Winkelmann article.
		materials << uwfr
	end
	materials << soil
	materials << conc8
	if wall_add_insul_layer
		materials << uwi
	end
	grndinsunfinbwall = OpenStudio::Model::Construction.new(materials)
	grndinsunfinbwall.setName("GrndInsUnfinBWall")	
	
	# UFBaseFloor-FicR
	uffr = OpenStudio::Model::MasslessOpaqueMaterial.new(model)
	uffr.setName("UFBaseFloor-FicR")
	uffr.setRoughness("Rough")
	uffr.setThermalResistance(OpenStudio::convert(ub_basement_floor_Rvalue,"hr*ft^2*R/Btu","m^2*K/W").get)
	
	# Concrete-4in
    mat_concrete4in = get_mat_concrete4in
	conc4 = OpenStudio::Model::StandardOpaqueMaterial.new(model)
	conc4.setName("Concrete-4in")
	conc4.setRoughness("Rough")
	conc4.setThickness(OpenStudio::convert(mat_concrete4in.thick,"ft","m").get)
	conc4.setConductivity(OpenStudio::convert(mat_concrete4in.k,"Btu/hr*ft*R","W/m*K").get)
	conc4.setDensity(OpenStudio::convert(mat_concrete4in.rho,"lb/ft^3","kg/m^3").get)
	conc4.setSpecificHeat(OpenStudio::convert(mat_concrete4in.Cp,"Btu/lb*R","J/kg*K").get)
	conc4.setThermalAbsorptance(mat_concrete4in.TAbs)	
	
	# GrndUninsUnfinBFloor
	materials = []
	materials << uffr
	materials << soil
	materials << conc4
	grnduninsunfinbfloor = OpenStudio::Model::Construction.new(materials)
	grnduninsunfinbfloor.setName("GrndUninsUnfinBFloor")	
	
	# RevUnfinBInsFinFloor
	revunfinbinsfinfloor = unfinbinsfinfloor.reverseConstruction
	revunfinbinsfinfloor.setName("RevUnfinBInsFinFloor")

	# Rigid
	if wallSheathingContInsRvalue > 0
		rigid = OpenStudio::Model::StandardOpaqueMaterial.new(model)
		rigid.setName("WallRigidIns")
		rigid.setRoughness("Rough")
		rigid.setThickness(OpenStudio::convert(rigid_thick,"ft","m").get)
		rigid.setConductivity(OpenStudio::convert(rigid_cond,"Btu/hr*ft*R","W/m*K").get)
		rigid.setDensity(OpenStudio::convert(rigid_dens,"lb/ft^3","kg/m^3").get)
		rigid.setSpecificHeat(OpenStudio::convert(rigid_sh,"Btu/lb*R","J/kg*K").get)
	end
	
	# Plywood-3_2in
    mat_plywood3_2in = get_mat_plywood3_2in
	ply3_2 = OpenStudio::Model::StandardOpaqueMaterial.new(model)
	ply3_2.setName("Plywood-3_2in")
	ply3_2.setRoughness("Rough")
	ply3_2.setThickness(OpenStudio::convert(mat_plywood3_2in.thick,"ft","m").get)
	ply3_2.setConductivity(OpenStudio::convert(mat_plywood3_2in.k,"Btu/hr*ft*R","W/m*K").get)
	ply3_2.setDensity(OpenStudio::convert(mat_plywood3_2in.rho,"lb/ft^3","kg/m^3").get)
	ply3_2.setSpecificHeat(OpenStudio::convert(mat_plywood3_2in.Cp,"Btu/lb*R","J/kg*K").get)	
	
	# UFBsmtJoistandCavity
	if rj_Rvalue > 0
		ujc = OpenStudio::Model::StandardOpaqueMaterial.new(model)
		ujc.setName("UFBsmtJoistandCavity")
		ujc.setRoughness("Rough")
		ujc.setThickness(OpenStudio::convert(rj_thick,"ft","m").get)
		ujc.setConductivity(OpenStudio::convert(rj_cond,"Btu/hr*ft*R","W/m*K").get)
		ujc.setDensity(OpenStudio::convert(rj_dens,"lb/ft^3","kg/m^3").get)
		ujc.setSpecificHeat(OpenStudio::convert(rj_sh,"Btu/lb*R","J/kg*K").get)
	end
	
	# UFBsmtRimJoist
	materials = []
	materials << extfin.to_StandardOpaqueMaterial.get
	if wallSheathingContInsRvalue > 0 #Wall sheathing also covers rimjoist
		materials << rigid
	end
	materials << ply3_2
	if rj_Rvalue > 0
		materials << ujc
	end
	ufbsmtrimjoist = OpenStudio::Model::Construction.new(materials)
	ufbsmtrimjoist.setName("UFBsmtRimJoist")	

	living_space_type.spaces.each do |living_space|
	  living_space.surfaces.each do |living_surface|
	    next unless ["floor"].include? living_surface.surfaceType.downcase
		adjacent_surface = living_surface.adjacentSurface
		next unless adjacent_surface.is_initialized
		adjacent_surface = adjacent_surface.get
	    adjacent_surface_r = adjacent_surface.name.to_s
	    adjacent_space_type_r = HelperMethods.get_space_type_from_surface(model, adjacent_surface_r)
	    next unless [ubasement_space_type_r].include? adjacent_space_type_r
	    living_surface.setConstruction(unfinbinsfinfloor)
		runner.registerInfo("Surface '#{living_surface.name}', of Space Type '#{living_space_type_r}' and with Surface Type '#{living_surface.surfaceType}' and Outside Boundary Condition '#{living_surface.outsideBoundaryCondition}', was assigned Construction '#{unfinbinsfinfloor.name}'")
	    adjacent_surface.setConstruction(revunfinbinsfinfloor)		
		runner.registerInfo("Surface '#{adjacent_surface.name}', of Space Type '#{adjacent_space_type_r}' and with Surface Type '#{adjacent_surface.surfaceType}' and Outside Boundary Condition '#{adjacent_surface.outsideBoundaryCondition}', was assigned Construction '#{revunfinbinsfinfloor.name}'")
	  end	
	end	
	
	ubasement_space_type.spaces.each do |ubasement_space|
	  ubasement_space.surfaces.each do |ubasement_surface|
	    if ubasement_surface.surfaceType.downcase == "wall" and ubasement_surface.outsideBoundaryCondition.downcase == "ground"
		  ubasement_surface.setConstruction(grndinsunfinbwall)
		  runner.registerInfo("Surface '#{ubasement_surface.name}', of Space Type '#{ubasement_space_type_r}' and with Surface Type '#{ubasement_surface.surfaceType}' and Outside Boundary Condition '#{ubasement_surface.outsideBoundaryCondition}', was assigned Construction '#{grndinsunfinbwall.name}'")
		elsif ubasement_surface.surfaceType.downcase == "floor" and ubasement_surface.outsideBoundaryCondition.downcase == "ground"
		  ubasement_surface.setConstruction(grnduninsunfinbfloor)
		  runner.registerInfo("Surface '#{ubasement_surface.name}', of Space Type '#{ubasement_space_type_r}' and with Surface Type '#{ubasement_surface.surfaceType}' and Outside Boundary Condition '#{ubasement_surface.outsideBoundaryCondition}', was assigned Construction '#{grnduninsunfinbfloor.name}'")		
		elsif ubasement_surface.surfaceType.downcase == "wall" and ubasement_surface.outsideBoundaryCondition.downcase == "outdoors"
		  ubasement_surface.setConstruction(ufbsmtrimjoist)
		  runner.registerInfo("Surface '#{ubasement_surface.name}', of Space Type '#{ubasement_space_type_r}' and with Surface Type '#{ubasement_surface.surfaceType}' and Outside Boundary Condition '#{ubasement_surface.outsideBoundaryCondition}', was assigned Construction '#{ufbsmtrimjoist.name}'")				
		end
	  end	
	end

    return true
 
  end #end the run method

  def _processConstructionsUnfinishedBasement(ufbsmtCeilingJoistHeight, ufbsmtCeilingFramingFactor, ufbsmtWallInsHeight, ufbsmtWallContInsThickness, ufbsmtWallFramingFactor, ufbsmtWallCavityDepth, ufbsmtWallInstallGrade, ufbsmtWallCavityInsFillsCavity, ufbsmtCeilingCavityInsRvalueNominal, ufbsmtRimJoistInsRvalue, ufbsmtWallCavityInsRvalueInstalled, ufbsmtWallContInsRvalue, carpetFloorFraction, carpetPadRValue, floorMassThickness, floorMassConductivity, floorMassDensity, floorMassSpecificHeat, gypsumThickness, gypsumNumLayers, gypsumRvalue, wallSheathingContInsThickness, wallSheathingContInsRvalue, finishThickness, finishConductivity)

    # If there is no wall insulation, apply the ceiling insulation R-value to the rim joists
    if ufbsmtWallContInsRvalue == 0 and ufbsmtWallCavityInsRvalueInstalled == 0
        ufbsmtRimJoistInsRvalue = ufbsmtCeilingCavityInsRvalueNominal
    end

    mat_2x = get_mat_2x(ufbsmtCeilingJoistHeight)
    
    # Calculate overall R value of the basement wall, including framed walls with cavity insulation
    overall_wall_Rvalue = get_wood_stud_wall_r_assembly(ufbsmtWallCavityInsFillsCavity, ufbsmtWallCavityInsRvalueInstalled,
                                                        ufbsmtWallInstallGrade, ufbsmtWallCavityDepth, ufbsmtWallFramingFactor,        
                                                        "UFBsmt", gypsumThickness, gypsumNumLayers, 0, nil, 
                                                        ufbsmtWallContInsThickness, ufbsmtWallContInsRvalue)

    ub_conduction_factor = calc_basement_conduction_factor(ufbsmtWallInsHeight, overall_wall_Rvalue)

    ceiling_Rvalue = get_unfinished_basement_ceiling_r_assembly(ufbsmtCeilingCavityInsRvalueNominal, ufbsmtCeilingFramingFactor, ufbsmtCeilingJoistHeight, carpetFloorFraction, carpetPadRValue, floorMassThickness, floorMassConductivity, floorMassDensity, floorMassSpecificHeat)
    
    ub_ceiling_studlayer_Rvalue = ceiling_Rvalue - floor_nonstud_layer_Rvalue(floorMassThickness, floorMassConductivity, floorMassDensity, floorMassSpecificHeat, carpetFloorFraction, carpetPadRValue)
    
    if ceiling_Rvalue > 0
        ceiling_thick = mat_2x.thick # ft
        ceiling_cond = ceiling_thick / ub_ceiling_studlayer_Rvalue # Btu/hr*ft*F
        ceiling_dens = ufbsmtCeilingFramingFactor * get_mat_wood.rho + (1 - ufbsmtCeilingFramingFactor) * get_mat_densepack_generic.rho # lbm/ft^3
        ceiling_sh = (ufbsmtCeilingFramingFactor * get_mat_wood.Cp * get_mat_wood.rho + (1 - ufbsmtCeilingFramingFactor) * get_mat_densepack_generic.Cp * get_mat_densepack_generic.rho) / ceiling_dens
    end
    
    # FIXME: Currently hard-coded
    ubWallArea = 1360
    ubExtPerimeter = 170

    if ubExtPerimeter > 0
        ub_effective_Rvalue = ubWallArea / (ub_conduction_factor * ubExtPerimeter)
    else
        ub_effective_Rvalue = 1000 # hr*ft^2*F/Btu
    end
    
    # Insulation of 4ft height inside a 8ft basement is modeled completely in the fictitious layer
    # Insulation of 4ft  inside a 8ft basement is modeled completely in the fictitious layer
    if ufbsmtWallContInsRvalue > 0 and ufbsmtWallInsHeight == 8
        wall_add_insul_layer = true
    else
        wall_add_insul_layer = false
    end
    
    if wall_add_insul_layer
        wall_Rvalue = ufbsmtWallContInsRvalue # hr*ft^2*F/Btu
        wall_thick = wall_Rvalue * get_mat_rigid_ins.k # ft
        wall_cond = get_mat_rigid_ins.k # Btu/hr*ft*F
        wall_dens = get_mat_rigid_ins.rho # lbm/ft^3
        wall_sh = get_mat_rigid_ins.Cp
    else
        wall_Rvalue = 0
    end
    
    ub_US_Rvalue = get_mat_concrete8in.Rvalue + Properties.film_vertical_R + wall_Rvalue # hr*ft^2*F/Btu
    
    ub_fictitious_Rvalue = ub_effective_Rvalue - get_mat_soil12in.Rvalue - ub_US_Rvalue # hr*ft^2*F/Btu

    # For some foundations the effective U-value of the wall can be
    # greater than the raw U-value of the wall. If this is the case,
    # then the resistance of the fictitious layer will be negative
    # which DOE-2 will not accept. The code here sets a fictitious
    # R-value for the basement floor which results in the same
    # overall UA value for the crawlspace. Note: The DOE-2 keyword
    # U-EFFECTIVE does not affect DOE-2.2 simulations.
    
    ub_total_UA = ubWallArea / ub_effective_Rvalue # Btu/hr*F
    ub_wall_Rvalue = ub_US_Rvalue + get_mat_soil12in.Rvalue
    ub_wall_UA = ubWallArea / ub_wall_Rvalue
    
    # Fictitious layer below basement floor to achieve equivalent R-value. See Winklemann article.
    if ub_fictitious_Rvalue < 0 # Not enough cond through walls, need to add in floor conduction
        area = 1505 # FIXME: Currently hard-coded
        ub_basement_floor_Rvalue = area / (ub_total_UA - ub_wall_UA) - get_mat_soil12in.Rvalue - get_mat_concrete4in.Rvalue # hr*ft^2*F/Btu # (assumes basement floor is a 4-in concrete slab)
    else
        ub_basement_floor_Rvalue = 1000
    end
    
    # unfinished_basement.WallUA = ub_wallUA
    # unfinished_basement.FloorUA = self._getSpace(Constants.SpaceUnfinBasement).area / ub_basement_floor_Rvalue
    # unfinished_basement.CeilingUA = self._getSpace(Constants.SpaceUnfinBasement).area * 1/ceiling_Rvalue
            
    rj_thick, rj_cond, rj_dens, rj_sh, rj_Rvalue, rigid_thick, rigid_cond, rigid_dens, rigid_sh = _processConstructionsUnfinishedBasementRimJoist(ufbsmtRimJoistInsRvalue, ufbsmtCeilingJoistHeight, ufbsmtCeilingFramingFactor, wallSheathingContInsThickness, wallSheathingContInsRvalue, finishThickness, finishConductivity)
        
    return ceiling_Rvalue, ceiling_thick, ceiling_cond, ceiling_dens, ceiling_sh, wall_thick, wall_cond, wall_dens, wall_sh, wall_add_insul_layer, ub_fictitious_Rvalue, ub_basement_floor_Rvalue, rj_thick, rj_cond, rj_dens, rj_sh, rj_Rvalue, rigid_thick, rigid_cond, rigid_dens, rigid_sh
        
  end
    
  def _processConstructionsUnfinishedBasementRimJoist(ufbsmtRimJoistInsRvalue, ufbsmtCeilingJoistHeight, ufbsmtCeilingFramingFactor, wallSheathingContInsThickness, wallSheathingContInsRvalue, finishThickness, finishConductivity)
            
    rimjoist_framingfactor = 0.6 * ufbsmtCeilingFramingFactor #06 Factor added for due joist orientation
    
    mat_2x = get_mat_2x(ufbsmtCeilingJoistHeight)
    mat_plywood3_2in = get_mat_plywood3_2in
    rigid_thick, rigid_cond, rigid_dens, rigid_sh = _addInsulatedSheathingMaterial(wallSheathingContInsThickness, wallSheathingContInsRvalue)
    
    rj_Rvalue = get_rimjoist_r_assembly(ufbsmtRimJoistInsRvalue, ufbsmtCeilingJoistHeight, wallSheathingContInsThickness, wallSheathingContInsRvalue, 0, 0, rimjoist_framingfactor, finishThickness, finishConductivity)
        
    ub_rimjoist_studlayer_Rvalue = rj_Rvalue - rimjoist_nonstud_layer_Rvalue
    
    rj_thick = mat_2x.thick
    rj_cond = rj_thick / ub_rimjoist_studlayer_Rvalue         
        
    if ufbsmtRimJoistInsRvalue > 0
        rj_dens = rimjoist_framingfactor * get_mat_wood.rho + (1 - rimjoist_framingfactor) * get_mat_densepack_generic.rho # lbm/ft^3
        rj_sh = (rimjoist_framingfactor * get_mat_wood.Cp * get_mat_wood.rho + (1 - rimjoist_framingfactor) * get_mat_densepack_generic.Cp * get_mat_densepack_generic.rho) / rj_dens # Btu/lbm*F
    else            
        rj_dens = rimjoist_framingfactor * get_mat_wood.rho + (1 - rimjoist_framingfactor) * Properties.inside_air_dens(localPressure) # lbm/ft^3
        rj_sh = (rimjoist_framingfactor * get_mat_wood.Cp * get_mat_wood.rho + (1 - rimjoist_framingfactor) * get_mat_air.inside_air_sh * Properties.inside_air_dens(localPressure)) / rj_dens # Btu/lbm*F
    end
    
    return rj_thick, rj_cond, rj_dens, rj_sh, rj_Rvalue, rigid_thick, rigid_cond, rigid_dens, rigid_sh          
            
  end

  def get_unfinished_basement_ceiling_r_assembly(ufbsmtCeilingCavityInsRvalueNominal, ufbsmtCeilingFramingFactor, ufbsmtCeilingJoistHeight, carpetFloorFraction, carpetPadRValue, floorMassThickness, floorMassConductivity, floorMassDensity, floorMassSpecificHeat)
    # Returns assembly R-value for unfinished basement ceiling, including air films.
    mat_wood = get_mat_wood
    mat_2x = get_mat_2x(ufbsmtCeilingJoistHeight)
    mat_plywood3_4in = get_mat_plywood3_4in
    
    path_fracs = [ufbsmtCeilingFramingFactor, 1 - ufbsmtCeilingFramingFactor]
    
    ub_ceiling = Construction.new(path_fracs)
    
    # Interior Film
    ub_ceiling.addlayer(thickness=OpenStudio::convert(1,"in","ft").get, conductivity_list=[OpenStudio::convert(1,"in","ft").get / Properties.film_floor_reduced_R])
    
    # Stud/cavity layer
    if ufbsmtCeilingCavityInsRvalueNominal == 0
        cavity_k = 1000000000
    else    
        cavity_k = (mat_2x.thick / ufbsmtCeilingCavityInsRvalueNominal)
    end
    
    ub_ceiling.addlayer(thickness=mat_2x.thick, conductivity_list=[mat_wood.k, cavity_k])
    
    # Floor deck
    ub_ceiling.addlayer(thickness=nil, conductivity_list=nil, material=mat_plywood3_4in, material_list=nil)
    
    # Floor mass
    if floorMassThickness > 0
        mat_floor_mass = get_mat_floor_mass(floorMassThickness, floorMassConductivity, floorMassDensity, floorMassSpecificHeat)
        ub_ceiling.addlayer(thickness=nil, conductivity_list=nil, material=mat_floor_mass, material_list=nil)
    end
    
    # Carpet
    if carpetFloorFraction > 0
        carpet_smeared_cond = OpenStudio::convert(0.5,"in","ft").get / (carpetPadRValue * carpetFloorFraction)
        ub_ceiling.addlayer(thickness=OpenStudio::convert(0.5,"in","ft").get, conductivity_list=[carpet_smeared_cond])
    end
    
    # Exterior Film
    ub_ceiling.addlayer(thickness=OpenStudio::convert(1,"in","ft").get, conductivity_list=[OpenStudio::convert(1,"in","ft").get / Properties.film_floor_reduced_R])
    
    return ub_ceiling.Rvalue_parallel   

  end

  
end #end the measure

#this allows the measure to be use by the application
ProcessConstructionsUnfinishedBasement.new.registerWithApplication