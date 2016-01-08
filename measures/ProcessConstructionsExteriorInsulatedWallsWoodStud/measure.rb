#see the URL below for information on how to write OpenStudio measures
# http://openstudio.nrel.gov/openstudio-measure-writing-guide

#see the URL below for information on using life cycle cost objects in OpenStudio
# http://openstudio.nrel.gov/openstudio-life-cycle-examples

#see the URL below for access to C++ documentation on model objects (click on "model" in the main window to view model objects)
# http://openstudio.nrel.gov/sites/openstudio.nrel.gov/files/nv_data/cpp_documentation_it/model/html/namespaces.html

#load sim.rb
require "#{File.dirname(__FILE__)}/resources/sim"

#start the measure
class ProcessConstructionsExteriorInsulatedWallsWoodStud < OpenStudio::Ruleset::ModelUserScript
  
	class WoodStudWall
		def initialize(wsWallCavityInsFillsCavity, wsWallCavityInsRvalueInstalled, wsWallInstallGrade, wsWallCavityDepth, wsWallFramingFactor)
			@wsWallCavityInsFillsCavity = wsWallCavityInsFillsCavity
			@wsWallCavityInsRvalueInstalled = wsWallCavityInsRvalueInstalled
			@wsWallInstallGrade = wsWallInstallGrade
			@wsWallCavityDepth = wsWallCavityDepth
			@wsWallFramingFactor = wsWallFramingFactor
		end
		
		def WSWallCavityInsFillsCavity
			return @wsWallCavityInsFillsCavity
		end
		
		def WSWallCavityInsRvalueInstalled
			return @wsWallCavityInsRvalueInstalled
		end
		
		def WSWallInstallGrade
			return @wsWallInstallGrade
		end
		
		def WSWallCavityDepth
			return @wsWallCavityDepth
		end 
		
		def WSWallFramingFactor
			return @wsWallFramingFactor
		end	
	end
	
	class ExtWallMass
		def initialize(gypsumThickness, gypsumNumLayers, gypsumRvalue)
			@gypsumThickness = gypsumThickness
			@gypsumNumLayers = gypsumNumLayers
			@gypsumRvalue = gypsumRvalue
		end
		
		def ExtWallMassGypsumThickness
			return @gypsumThickness
		end
		
		def ExtWallMassGypsumNumLayers
			return @gypsumNumLayers
		end
		
		def ExtWallMassGypsumRvalue
			return @gypsumRvalue
		end
	end		
	
	class ExteriorFinish
		def initialize(finishThickness, finishConductivity, finishRvalue)
			@finishThickness = finishThickness
			@finishConductivity = finishConductivity
			@finishRvalue = finishRvalue
		end
		
		def FinishThickness
			return @finishThickness
		end
		
		def FinishConductivity
			return @finishConductivity
		end
		
		def FinishRvalue
			return @finishRvalue
		end
	end
	
	class WallSheathing
		def initialize(rigidInsThickness, rigidInsRvalue, hasOSB, osbRvalue)
			@rigidInsThickness = rigidInsThickness
			@rigidInsRvalue = rigidInsRvalue
			@hasOSB = hasOSB
			@osbRvalue = osbRvalue
		end

		attr_accessor(:rigid_ins_layer_thickness, :rigid_ins_layer_conductivity, :rigid_ins_layer_density, :rigid_ins_layer_spec_heat)
		
		def WallSheathingContInsThickness
			return @rigidInsThickness
		end
		
		def WallSheathingContInsRvalue
			return @rigidInsRvalue
		end
		
		def WallSheathingHasOSB
			return @hasOSB
		end
		
		def OSBRvalue
			return @osbRvalue		
		end
	end 
	
	class StudandCavity
		def initialize
		end
		attr_accessor(:stud_layer_thickness, :stud_layer_conductivity, :stud_layer_density, :stud_layer_spec_heat)
	end
  
  #define the name that a user will see, this method may be deprecated as
  #the display name in PAT comes from the name field in measure.xml
  def name
    return "Assign Residential Living Space Wood Stud Wall Construction"
  end
  
  def description
    return "This measure assigns a wood stud constructions to the living space exterior walls."
  end
  
  def modeler_description
    return "Calculates material layer properties of wood stud constructions for the exterior walls adjacent to the living space. Finds surfaces adjacent to the living space and sets applicable constructions."
  end  
  
  #define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Ruleset::OSArgumentVector.new

    #make a double argument for thickness of gypsum
    userdefined_gypthickness = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedgypthickness", false)
    userdefined_gypthickness.setDisplayName("Exterior Wall Mass: Thickness")
	userdefined_gypthickness.setUnits("in")
	userdefined_gypthickness.setDescription("Gypsum layer thickness.")
    userdefined_gypthickness.setDefaultValue(0.5)
    args << userdefined_gypthickness

    #make a double argument for number of gypsum layers
    userdefined_gyplayers = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedgyplayers", false)
    userdefined_gyplayers.setDisplayName("Exterior Wall Mass: Num Layers")
	userdefined_gyplayers.setUnits("#")
	userdefined_gyplayers.setDescription("Integer number of layers of gypsum.")
    userdefined_gyplayers.setDefaultValue(1)
    args << userdefined_gyplayers

	#make a choice argument for model objects
	studsize_display_names = OpenStudio::StringVector.new
	studsize_display_names << "2x4"
	studsize_display_names << "2x6"
	
    #make a string argument for wood stud size of wall cavity
    selected_studsize = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("selectedstudsize", studsize_display_names, true)
    selected_studsize.setDisplayName("Wood Stud: Cavity Depth")
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
	selected_spacing.setDisplayName("Wood Stud: Stud Spacing")
	selected_spacing.setUnits("in")
	selected_spacing.setDescription("The on-center spacing between studs in a wall assembly.")
	selected_spacing.setDefaultValue("16 in o.c.")
	args << selected_spacing
	
	#make a double argument for nominal R-value of installed cavity insulation
	userdefined_instcavr = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedinstcavr", true)
	userdefined_instcavr.setDisplayName("Wood Stud: Cavity Insulation Installed R-value")
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
	selected_insfills.setDisplayName("Wood Stud: Insulation Fills Cavity")
	selected_insfills.setDescription("Specifies whether the cavity insulation completely fills the depth of the wall cavity.")
    selected_insfills.setDefaultValue(true)
	args << selected_insfills

	#make a bool argument for OSB of wall cavity
	userdefined_hasosb = OpenStudio::Ruleset::OSArgument::makeBoolArgument("userdefinedhasosb", true)
	userdefined_hasosb.setDisplayName("Wall Sheathing: Has OSB")
	userdefined_hasosb.setDescription("Specifies if the walls have a layer of structural shear OSB sheathing.")
	userdefined_hasosb.setDefaultValue(true)
	args << userdefined_hasosb	
	
	#make a double argument for rigid insulation thickness of wall cavity
    userdefined_rigidinsthickness = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedrigidinsthickness", false)
    userdefined_rigidinsthickness.setDisplayName("Wall Sheathing: Continuous Insulation Thickness")
	userdefined_rigidinsthickness.setUnits("in")
	userdefined_rigidinsthickness.setDescription("The thickness of the continuous insulation.")
    userdefined_rigidinsthickness.setDefaultValue(0)
    args << userdefined_rigidinsthickness
	
	#make a double argument for rigid insulation R-value of wall cavity
	userdefined_rigidinsr = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedrigidinsr", false)
	userdefined_rigidinsr.setDisplayName("Wall Sheathing: Continuous Insulation Nominal R-value")
	userdefined_rigidinsr.setUnits("hr-ft^2-R/Btu")
	userdefined_rigidinsr.setDescription("R-value is a measure of insulation's ability to resist heat traveling through it.")
    userdefined_rigidinsr.setDefaultValue(0)
	args << userdefined_rigidinsr
	
	#make a double argument for exterior finish thickness of wall cavity
	userdefined_extfinthickness = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedextfinthickness", false)
	userdefined_extfinthickness.setDisplayName("Exterior Finish: Thickness")
	userdefined_extfinthickness.setUnits("in")
	userdefined_extfinthickness.setDescription("Thickness of the exterior finish assembly.")
    userdefined_extfinthickness.setDefaultValue(0.375)
	args << userdefined_extfinthickness
	
	#make a double argument for exterior finish R-value of wall cavity
	userdefined_extfinr = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedextfinr", false)
	userdefined_extfinr.setDisplayName("Exterior Finish: R-value")
	userdefined_extfinr.setUnits("hr-ft^2-R/Btu")
	userdefined_extfinr.setDescription("R-value is a measure of insulation's ability to resist heat traveling through it.")
    userdefined_extfinr.setDefaultValue(0.6)
	args << userdefined_extfinr	
	
	#make a double argument for exterior finish density of wall cavity
	userdefined_extfindensity = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedextfindensity", false)
	userdefined_extfindensity.setDisplayName("Exterior Finish: Density")
	userdefined_extfindensity.setUnits("lb/ft^3")
	userdefined_extfindensity.setDescription("Density of the exterior finish assembly.")
    userdefined_extfindensity.setDefaultValue(11.1)
	args << userdefined_extfindensity

	#make a double argument for exterior finish specific heat of wall cavity
	userdefined_extfinspecheat = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedextfinspecheat", false)
	userdefined_extfinspecheat.setDisplayName("Exterior Finish: Specific Heat")
	userdefined_extfinspecheat.setUnits("Btu/lb-R")
	userdefined_extfinspecheat.setDescription("Specific heat of the exterior finish assembly.")
    userdefined_extfinspecheat.setDefaultValue(0.25)
	args << userdefined_extfinspecheat
	
	#make a double argument for exterior finish thermal absorptance of wall cavity
	userdefined_extfinthermalabs = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedextfinthermalabs", false)
	userdefined_extfinthermalabs.setDisplayName("Exterior Finish: Emissivity")
	userdefined_extfinthermalabs.setDescription("The property that determines the fraction of the incident radiation that is absorbed.")
    userdefined_extfinthermalabs.setDefaultValue(0.9)
	args << userdefined_extfinthermalabs

	#make a double argument for exterior finish solar/visible absorptance of wall cavity
	userdefined_extfinabs = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedextfinabs", false)
	userdefined_extfinabs.setDisplayName("Exterior Finish: Solar Absorptivity")
	userdefined_extfinabs.setDescription("The property that determines the fraction of the incident radiation that is absorbed.")
    userdefined_extfinabs.setDefaultValue(0.3)
	args << userdefined_extfinabs

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
	
	# Gypsum
	userdefined_gypthickness = runner.getDoubleArgumentValue("userdefinedgypthickness",user_arguments)
	userdefined_gyplayers = runner.getDoubleArgumentValue("userdefinedgyplayers",user_arguments)
	# Cavity
	selected_studsize = runner.getStringArgumentValue("selectedstudsize",user_arguments)
	selected_spacing = runner.getStringArgumentValue("selectedspacing",user_arguments)
	userdefined_instcavr = runner.getDoubleArgumentValue("userdefinedinstcavr",user_arguments)
	selected_installgrade = runner.getStringArgumentValue("selectedinstallgrade",user_arguments)
	selected_insfills = runner.getBoolArgumentValue("selectedinsfills",user_arguments)
	# Rigid
	userdefined_rigidinsthickness = runner.getDoubleArgumentValue("userdefinedrigidinsthickness",user_arguments)
	userdefined_rigidinsr = runner.getDoubleArgumentValue("userdefinedrigidinsr",user_arguments)
	userdefined_hasosb = runner.getBoolArgumentValue("userdefinedhasosb",user_arguments)
	# Exterior Finish
	userdefined_extfinthickness = runner.getDoubleArgumentValue("userdefinedextfinthickness",user_arguments)
	userdefined_extfinr = runner.getDoubleArgumentValue("userdefinedextfinr",user_arguments)
	userdefined_extfindensity = runner.getDoubleArgumentValue("userdefinedextfindensity",user_arguments)
	userdefined_extfinspecheat = runner.getDoubleArgumentValue("userdefinedextfinspecheat",user_arguments)
	userdefined_extfinthermalabs = runner.getDoubleArgumentValue("userdefinedextfinthermalabs",user_arguments)
	userdefined_extfinabs = runner.getDoubleArgumentValue("userdefinedextfinabs",user_arguments)		
	
	# Constants
	mat_wood = get_mat_wood
	mat_gyp = get_mat_gypsum
	mat_air = get_mat_air
	mat_rigid = get_mat_rigid_ins
	mat_densepack_generic = get_mat_densepack_generic

	# Gypsum	
	gypsumThickness = userdefined_gypthickness
	gypsumNumLayers = userdefined_gyplayers
	gypsumConductivity = mat_gyp.k
	gypsumDensity = mat_gyp.rho
	gypsumSpecificHeat = mat_gyp.Cp
	gypsumThermalAbs = get_mat_gypsum_extwall(mat_gyp).TAbs
	gypsumSolarAbs = get_mat_gypsum_extwall(mat_gyp).SAbs
	gypsumVisibleAbs = get_mat_gypsum_extwall(mat_gyp).VAbs
	gypsumRvalue = (OpenStudio::convert(gypsumThickness,"in","ft").get * gypsumNumLayers / mat_gyp.k)

	# Rigid	
	rigidInsRvalue = userdefined_rigidinsr
	rigidInsThickness = userdefined_rigidinsthickness
	rigidInsConductivity = OpenStudio::convert(rigidInsThickness,"in","ft").get / rigidInsRvalue
	rigidInsDensity = mat_rigid.rho
	rigidInsSpecificHeat = mat_rigid.Cp	
	hasOSB = userdefined_hasosb
	osbThickness = 0.5
	osbConductivity = mat_wood.k
	osbDensity = mat_wood.rho
	osbSpecificHeat = mat_wood.Cp
	if hasOSB
		mat_plywood1_2in = get_mat_plywood1_2in(mat_wood)	
		osbRvalue = mat_plywood1_2in.Rvalue
	else
		osbRvalue = 0
	end
	
	# Cavity
	wsWallCavityInsFillsCavity = selected_insfills
	wsWallCavityInsRvalueInstalled = userdefined_instcavr
	wsWallInstallGrade_dict = {"I"=>1, "II"=>2, "III"=>3}
	wsWallInstallGrade = wsWallInstallGrade_dict[selected_installgrade]
	wsWallCavityDepth_dict = {"2x4"=>3.5, "2x6"=>5.5, "2x8"=>7.25, "2x10"=>9.25, "2x12"=>11.25, "2x14"=>13.25, "2x16"=>15.25}
	wsWallCavityDepth = wsWallCavityDepth_dict[selected_studsize]
	wsWallFramingFactor_dict = {"16 in o.c."=>0.25, "24 in o.c."=>0.22}
	wsWallFramingFactor = wsWallFramingFactor_dict[selected_spacing]
	
	# Exterior Finish
	finishRvalue = userdefined_extfinr
	finishThickness = userdefined_extfinthickness
	finishConductivity = finishThickness / finishRvalue
	finishDensity = userdefined_extfindensity
	finishSpecHeat = userdefined_extfinspecheat
	finishThermalAbs = userdefined_extfinthermalabs
	finishSolarAbs = userdefined_extfinabs
	finishVisibleAbs = userdefined_extfinabs
	
	# Create the material class instances
	wsw = WoodStudWall.new(wsWallCavityInsFillsCavity, wsWallCavityInsRvalueInstalled, wsWallInstallGrade, wsWallCavityDepth, wsWallFramingFactor)
	extwallmass = ExtWallMass.new(gypsumThickness, gypsumNumLayers, gypsumRvalue)
	exteriorfinish = ExteriorFinish.new(finishThickness, finishConductivity, finishRvalue)
	wallsh = WallSheathing.new(rigidInsThickness, rigidInsRvalue, hasOSB, osbRvalue)
	sc = StudandCavity.new
	
	# Create the sim object
	sim = Sim.new(model, runner)
	
	# Process the wood stud walls
	sc, wallsh = sim._processConstructionsExteriorInsulatedWallsWoodStud(wsw, extwallmass, exteriorfinish, wallsh, sc)

	# Create the material layers
	
	# Stud and Cavity
	scThickness = sc.stud_layer_thickness
	scConductivity = sc.stud_layer_conductivity
	scDensity = sc.stud_layer_density
	scSpecificHeat = sc.stud_layer_spec_heat
	
	# Gypsum
	gypsum = OpenStudio::Model::StandardOpaqueMaterial.new(model)
	gypsum.setName("GypsumBoard-ExtWall")
	gypsum.setRoughness("Rough")
	gypsum.setThickness(OpenStudio::convert(gypsumThickness,"in","m").get)
	gypsum.setConductivity(OpenStudio::convert(gypsumConductivity,"Btu/hr*ft*R","W/m*K").get)
	gypsum.setDensity(OpenStudio::convert(gypsumDensity,"lb/ft^3","kg/m^3").get)
	gypsum.setSpecificHeat(OpenStudio::convert(gypsumSpecificHeat,"Btu/lb*R","J/kg*K").get)
	gypsum.setThermalAbsorptance(gypsumThermalAbs)
	gypsum.setSolarAbsorptance(gypsumSolarAbs)
	gypsum.setVisibleAbsorptance(gypsumVisibleAbs)

  # Rigid
  if rigidInsRvalue > 0
    rigid = OpenStudio::Model::StandardOpaqueMaterial.new(model)
    rigid.setName("WallRigidIns")
    rigid.setRoughness("Rough")
    rigid.setThickness(OpenStudio::convert(wallsh.rigid_ins_layer_thickness,"ft","m").get)
    rigid.setConductivity(OpenStudio::convert(wallsh.rigid_ins_layer_conductivity,"Btu/hr*ft*R","W/m*K").get)
    rigid.setDensity(OpenStudio::convert(wallsh.rigid_ins_layer_density,"lb/ft^3","kg/m^3").get)
    rigid.setSpecificHeat(OpenStudio::convert(wallsh.rigid_ins_layer_spec_heat,"Btu/lb*R","J/kg*K").get)
  end
	
	# OSB
	osb = OpenStudio::Model::StandardOpaqueMaterial.new(model)
	osb.setName("Plywood-1_2in")
	osb.setRoughness("Rough")
	osb.setThickness(OpenStudio::convert(osbThickness,"in","m").get)
	osb.setConductivity(OpenStudio::convert(osbConductivity,"Btu/hr*ft*R","W/m*K").get)
	osb.setDensity(OpenStudio::convert(osbDensity,"lb/ft^3","kg/m^3").get)
	osb.setSpecificHeat(OpenStudio::convert(osbSpecificHeat,"Btu/lb*R","J/kg*K").get)
	
	# ExteriorFinish
	extfin = OpenStudio::Model::StandardOpaqueMaterial.new(model)
	extfin.setName("ExteriorFinish")
	extfin.setRoughness("Rough")
	extfin.setThickness(OpenStudio::convert(finishThickness,"in","m").get)
	extfin.setConductivity(OpenStudio::convert(finishConductivity,"Btu*in/hr*ft^2*R","W/m*K").get)
	extfin.setDensity(OpenStudio::convert(finishDensity,"lb/ft^3","kg/m^3").get)
	extfin.setSpecificHeat(OpenStudio::convert(finishSpecHeat,"Btu/lb*R","J/kg*K").get)
	extfin.setThermalAbsorptance(finishThermalAbs)
	extfin.setSolarAbsorptance(finishSolarAbs)
	extfin.setVisibleAbsorptance(finishVisibleAbs)
	
	# StudandCavity
	sc = OpenStudio::Model::StandardOpaqueMaterial.new(model)
	sc.setName("StudandCavity")
	sc.setRoughness("Rough")
	sc.setThickness(OpenStudio::convert(scThickness,"ft","m").get)
	sc.setConductivity(OpenStudio::convert(scConductivity,"Btu/hr*ft*R","W/m*K").get)
	sc.setDensity(OpenStudio::convert(scDensity,"lb/ft^3","kg/m^3").get)
	sc.setSpecificHeat(OpenStudio::convert(scSpecificHeat,"Btu/lb*R","J/kg*K").get)
	
	# ExtInsFinWall
	materials = []
	materials << extfin
	if rigidInsRvalue > 0
		materials << rigid
	end
	if hasOSB
		materials << osb
	end
	materials << sc
    (0...gypsumNumLayers).to_a.each do |i|
		materials << gypsum
	end
	extinsfinwall = OpenStudio::Model::Construction.new(materials)
	extinsfinwall.setName("ExtInsFinWall")	

	living_space_type.spaces.each do |living_space|
	  living_space.surfaces.each do |living_surface|
		next unless living_surface.surfaceType.downcase == "wall" and living_surface.outsideBoundaryCondition.downcase == "outdoors"
		living_surface.setConstruction(extinsfinwall)
		runner.registerInfo("Surface '#{living_surface.name}', of Space Type '#{living_space_type_r}' and with Surface Type '#{living_surface.surfaceType}' and Outside Boundary Condition '#{living_surface.outsideBoundaryCondition}', was assigned Construction '#{extinsfinwall.name}'")
	  end	
	end

    return true
 
  end #end the run method

end #end the measure

#this allows the measure to be use by the application
ProcessConstructionsExteriorInsulatedWallsWoodStud.new.registerWithApplication