#see the URL below for information on how to write OpenStudio measures
# http://openstudio.nrel.gov/openstudio-measure-writing-guide

#see the URL below for information on using life cycle cost objects in OpenStudio
# http://openstudio.nrel.gov/openstudio-life-cycle-examples

#see the URL below for access to C++ documentation on model objects (click on "model" in the main window to view model objects)
# http://openstudio.nrel.gov/sites/openstudio.nrel.gov/files/nv_data/cpp_documentation_it/model/html/namespaces.html

#load sim.rb
#require "#{File.dirname(__FILE__)}/resources/sim"
require "C:/OS-BEopt/OpenStudio-Beopt/resources/sim"

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
    return "ProcessConstructionsExteriorInsulatedWallsWoodStud"
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

    #make a choice argument for living space
    selected_living = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("selectedliving", spacetype_handles, spacetype_display_names, true)
    selected_living.setDisplayName("Of what space type is the living space?")
    args << selected_living

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

	# #make a choice argument for interior finish of wall cavity
	# selected_gypsum = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("selectedgypsum", material_handles, material_display_names, false)
	# selected_gypsum.setDisplayName("Interior finish (gypsum) of wall cavity. For manually entering interior finish properties of wall cavity, leave blank.")
	# args << selected_gypsum

    #make a double argument for thickness of gypsum
    userdefined_gypthickness = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedgypthickness", false)
    userdefined_gypthickness.setDisplayName("Thickness of drywall layers [in].")
    userdefined_gypthickness.setDefaultValue(0.5)
    args << userdefined_gypthickness

    #make a double argument for number of gypsum layers
    userdefined_gyplayers = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedgyplayers", false)
    userdefined_gyplayers.setDisplayName("Number of drywall layers.")
    userdefined_gyplayers.setDefaultValue(1)
    args << userdefined_gyplayers

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
    selected_studsize.setDisplayName("Wood stud size of wall cavity.")
    args << selected_studsize
	
	#make a choice argument for model objects
	spacing_display_names = OpenStudio::StringVector.new
	spacing_display_names << "16 in o.c."
	spacing_display_names << "24 in o.c."
	
	#make a choice argument for wood stud spacing
	selected_spacing = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("selectedspacing", spacing_display_names, true)
	selected_spacing.setDisplayName("Wood stud spacing of wall cavity.")
	args << selected_spacing
	
	#make a double argument for nominal R-value of installed cavity insulation
	userdefined_instcavr = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedinstcavr", true)
	userdefined_instcavr.setDisplayName("Installed R-value of cavity insulation [hr-ft^2-R/Btu].")
	args << userdefined_instcavr
	
	#make a choice argument for model objects
	installgrade_display_names = OpenStudio::StringVector.new
	installgrade_display_names << "I"
	installgrade_display_names << "II"
	installgrade_display_names << "III"
	
	#make a choice argument for wall cavity insulation installation grade
	selected_installgrade = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("selectedinstallgrade", installgrade_display_names, true)
	selected_installgrade.setDisplayName("Insulation installation grade of wood stud wall cavity.")
  selected_installgrade.setDefaultValue("I")
	args << selected_installgrade
	
	#make a bool argument for whether the cavity insulation fills the cavity
	selected_insfills = OpenStudio::Ruleset::OSArgument::makeBoolArgument("selectedinsfills", true)
	selected_insfills.setDisplayName("Cavity insulation fills the cavity?")
  selected_insfills.setDefaultValue(true)
	args << selected_insfills
	
    # #make a choice argument for rigid insulation of wall cavity
    # selected_rigidins = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("selectedrigidins", material_handles, material_display_names, false)
    # selected_rigidins.setDisplayName("Rigid insulation of wall cavity. For manually entering rigid insulation properties of wall cavity, leave blank.")
    # args << selected_rigidins

	#make a double argument for rigid insulation thickness of wall cavity
    userdefined_rigidinsthickness = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedrigidinsthickness", false)
    userdefined_rigidinsthickness.setDisplayName("Rigid insulation thickness of wall cavity [in].")
    userdefined_rigidinsthickness.setDefaultValue(0)
    args << userdefined_rigidinsthickness
	
	#make a double argument for rigid insulation R-value of wall cavity
	userdefined_rigidinsr = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedrigidinsr", false)
	userdefined_rigidinsr.setDisplayName("Rigid insulation R-value of wall cavity [hr-ft^2-R/Btu].")
  userdefined_rigidinsr.setDefaultValue(0)
	args << userdefined_rigidinsr
	
	#make a bool argument for OSB of wall cavity
	userdefined_hasosb = OpenStudio::Ruleset::OSArgument::makeBoolArgument("userdefinedhasosb", true)
	userdefined_hasosb.setDisplayName("Wood stud wall has OSB sheathing?")
	args << userdefined_hasosb		
	
	# #make a choice argument for exterior finish of wall cavity
   #  selected_extfin = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("selectedextfin", material_handles, material_display_names, false)
   #  selected_extfin.setDisplayName("Exterior finish of wall cavity. For manually entering exterior finish properties of wall cavity, leave blank.")
   #  args << selected_extfin
	
	#make a double argument for exterior finish thickness of wall cavity
	userdefined_extfinthickness = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedextfinthickness", false)
	userdefined_extfinthickness.setDisplayName("Exterior finish thickness of wall cavity [in].")
  userdefined_extfinthickness.setDefaultValue(0.375)
	args << userdefined_extfinthickness
	
	#make a double argument for exterior finish R-value of wall cavity
	userdefined_extfinr = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedextfinr", false)
	userdefined_extfinr.setDisplayName("Exterior finish R-value of wall cavity [hr-ft^2-R/Btu].")
  userdefined_extfinr.setDefaultValue(0.6)
	args << userdefined_extfinr	
	
	#make a double argument for exterior finish density of wall cavity
	userdefined_extfindensity = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedextfindensity", false)
	userdefined_extfindensity.setDisplayName("Exterior finish density of wall cavity [lb/ft^3].")
  userdefined_extfindensity.setDefaultValue(11.1)
	args << userdefined_extfindensity

	#make a double argument for exterior finish specific heat of wall cavity
	userdefined_extfinspecheat = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedextfinspecheat", false)
	userdefined_extfinspecheat.setDisplayName("Exterior finish specific heat of wall cavity [Btu/lb-R].")
  userdefined_extfinspecheat.setDefaultValue(0.25)
	args << userdefined_extfinspecheat
	
	#make a double argument for exterior finish thermal absorptance of wall cavity
	userdefined_extfinthermalabs = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedextfinthermalabs", false)
	userdefined_extfinthermalabs.setDisplayName("Exterior finish emissivity of wall cavity.")
  userdefined_extfinthermalabs.setDefaultValue(0.9)
	args << userdefined_extfinthermalabs

	#make a double argument for exterior finish solar/visible absorptance of wall cavity
	userdefined_extfinabs = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedextfinabs", false)
	userdefined_extfinabs.setDisplayName("Exterior finish absorptance of wall cavity.")
  userdefined_extfinabs.setDefaultValue(0.3)
	args << userdefined_extfinabs
	   
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
    selected_living = runner.getOptionalWorkspaceObjectChoiceValue("selectedliving",user_arguments,model)
	
	# Gypsum
	selected_gypsum = runner.getOptionalWorkspaceObjectChoiceValue("selectedgypsum",user_arguments,model)
	if selected_gypsum.empty?
		userdefined_gypthickness = runner.getDoubleArgumentValue("userdefinedgypthickness",user_arguments)
		userdefined_gyplayers = runner.getDoubleArgumentValue("userdefinedgyplayers",user_arguments)
	end
	# Cavity
	selected_studsize = runner.getStringArgumentValue("selectedstudsize",user_arguments)
	selected_spacing = runner.getStringArgumentValue("selectedspacing",user_arguments)
	userdefined_instcavr = runner.getDoubleArgumentValue("userdefinedinstcavr",user_arguments)
	selected_installgrade = runner.getStringArgumentValue("selectedinstallgrade",user_arguments)
	selected_insfills = runner.getBoolArgumentValue("selectedinsfills",user_arguments)
	# Rigid
	selected_rigidins = runner.getOptionalWorkspaceObjectChoiceValue("selectedrigidins",user_arguments,model)
	if selected_rigidins.empty?
		userdefined_rigidinsthickness = runner.getDoubleArgumentValue("userdefinedrigidinsthickness",user_arguments)
		userdefined_rigidinsr = runner.getDoubleArgumentValue("userdefinedrigidinsr",user_arguments)
	end
	userdefined_hasosb = runner.getBoolArgumentValue("userdefinedhasosb",user_arguments)
	# Exterior Finish
	selected_extfin = runner.getOptionalWorkspaceObjectChoiceValue("selectedextfin",user_arguments,model)
	if selected_extfin.empty?
		userdefined_extfinthickness = runner.getDoubleArgumentValue("userdefinedextfinthickness",user_arguments)
		userdefined_extfinr = runner.getDoubleArgumentValue("userdefinedextfinr",user_arguments)
		userdefined_extfindensity = runner.getDoubleArgumentValue("userdefinedextfindensity",user_arguments)
		userdefined_extfinspecheat = runner.getDoubleArgumentValue("userdefinedextfinspecheat",user_arguments)
		userdefined_extfinthermalabs = runner.getDoubleArgumentValue("userdefinedextfinthermalabs",user_arguments)
		userdefined_extfinabs = runner.getDoubleArgumentValue("userdefinedextfinabs",user_arguments)		
	end
	
	# Constants
	mat_wood = get_mat_wood
	mat_gyp = get_mat_gypsum
	mat_air = get_mat_air
	mat_rigid = get_mat_rigid_ins
	mat_densepack_generic = get_mat_densepack_generic

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
		gypsumThermalAbs = get_mat_gypsum_extwall(mat_gyp).TAbs
		gypsumSolarAbs = get_mat_gypsum_extwall(mat_gyp).SAbs
		gypsumVisibleAbs = get_mat_gypsum_extwall(mat_gyp).VAbs
		gypsumRvalue = (OpenStudio::convert(gypsumThickness,"in","ft").get * gypsumNumLayers / mat_gyp.k)
	end

	# Rigid	
	if userdefined_rigidinsthickness.nil?
		rigidInsRoughness = selected_rigidins.get.to_StandardOpaqueMaterial.get.roughness
		rigidInsThickness = OpenStudio::convert(selected_rigidins.get.to_StandardOpaqueMaterial.get.getThickness.value,"m","in").get
		rigidInsConductivity = OpenStudio::convert(selected_rigidins.get.to_StandardOpaqueMaterial.get.getConductivity.value,"W/m*K","Btu/hr*ft*R").get
		rigidInsDensity = OpenStudio::convert(selected_rigidins.get.to_StandardOpaqueMaterial.get.getDensity.value,"kg/m^3","lb/ft^3").get
		rigidInsSpecificHeat = OpenStudio::convert(selected_rigidins.get.to_StandardOpaqueMaterial.get.getSpecificHeat.value,"J/kg*K","Btu/lb*R").get
		rigidInsRvalue = OpenStudio::convert(rigidInsThickness,"in","ft").get / rigidInsConductivity		
	else
		rigidInsRvalue = userdefined_rigidinsr
		rigidInsRoughness = "Rough"
		rigidInsThickness = userdefined_rigidinsthickness
		rigidInsConductivity = OpenStudio::convert(rigidInsThickness,"in","ft").get / rigidInsRvalue
		rigidInsDensity = mat_rigid.rho
		rigidInsSpecificHeat = mat_rigid.Cp	
	end
	hasOSB = userdefined_hasosb
	osbRoughness = "Rough"
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
	if userdefined_extfinthickness.nil?
		finishRoughness = selected_extfin.get.to_StandardOpaqueMaterial.get.roughness
		finishThickness = OpenStudio::convert(selected_extfin.get.to_StandardOpaqueMaterial.get.getThickness.value,"m","in").get
		finishConductivity = OpenStudio::convert(selected_extfin.get.to_StandardOpaqueMaterial.get.getConductivity.value,"W/m*K","Btu/hr*ft*R").get
		finishDensity = OpenStudio::convert(selected_extfin.get.to_StandardOpaqueMaterial.get.getDensity.value,"kg/m^3","lb/ft^3").get
		finishSpecHeat = OpenStudio::convert(selected_extfin.get.to_StandardOpaqueMaterial.get.getSpecificHeat.value,"J/kg*K","Btu/lb*R").get
		finishThermalAbs = selected_extfin.get.to_StandardOpaqueMaterial.get.getThermalAbsorptance.value
		finishSolarAbs = selected_extfin.get.to_StandardOpaqueMaterial.get.getSolarAbsorptance.value
		finishVisibleAbs = selected_extfin.get.to_StandardOpaqueMaterial.get.getVisibleAbsorptance.value
		finishRvalue = OpenStudio::convert(finishThickness,"in","ft").get / finishConductivity
	else
		finishRvalue = userdefined_extfinr
		finishRoughness = "Rough"
		finishThickness = userdefined_extfinthickness
		finishConductivity = finishThickness / finishRvalue
		finishDensity = userdefined_extfindensity
		finishSpecHeat = userdefined_extfinspecheat
		finishThermalAbs = userdefined_extfinthermalabs
		finishSolarAbs = userdefined_extfinabs
		finishVisibleAbs = userdefined_extfinabs
	end
	
	# Create the material class instances
	wsw = WoodStudWall.new(wsWallCavityInsFillsCavity, wsWallCavityInsRvalueInstalled, wsWallInstallGrade, wsWallCavityDepth, wsWallFramingFactor)
	extwallmass = ExtWallMass.new(gypsumThickness, gypsumNumLayers, gypsumRvalue)
	exteriorfinish = ExteriorFinish.new(finishThickness, finishConductivity, finishRvalue)
	wallsh = WallSheathing.new(rigidInsThickness, rigidInsRvalue, hasOSB, osbRvalue)
	sc = StudandCavity.new
	
	# Create the sim object
	sim = Sim.new(model)
	
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
	gypsum.setRoughness(gypsumRoughness)
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
	osb.setRoughness(osbRoughness)
	osb.setThickness(OpenStudio::convert(osbThickness,"in","m").get)
	osb.setConductivity(OpenStudio::convert(osbConductivity,"Btu/hr*ft*R","W/m*K").get)
	osb.setDensity(OpenStudio::convert(osbDensity,"lb/ft^3","kg/m^3").get)
	osb.setSpecificHeat(OpenStudio::convert(osbSpecificHeat,"Btu/lb*R","J/kg*K").get)
	
	# ExteriorFinish
	extfin = OpenStudio::Model::StandardOpaqueMaterial.new(model)
	extfin.setName("ExteriorFinish")
	extfin.setRoughness(finishRoughness)
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
	layercount = 0
	extinsfinwall = OpenStudio::Model::Construction.new(model)
	extinsfinwall.setName("ExtInsFinWall")
	extinsfinwall.insertLayer(layercount,extfin)
	layercount += 1
	if rigidInsRvalue > 0
		extinsfinwall.insertLayer(layercount,rigid)
		layercount += 1
	end
	if hasOSB
		extinsfinwall.insertLayer(layercount,osb)
		layercount += 1
	end
	extinsfinwall.insertLayer(layercount,sc)
	layercount += 1
  (0...gypsumNumLayers).to_a.each do |i|
		extinsfinwall.insertLayer(layercount,gypsum)
    layercount += 1
	end
	
	# ExtInsUnfinWall
	extinsunfinwall = OpenStudio::Model::Construction.new(model)
	extinsunfinwall.setName("ExtInsUnfinWall")
	extinsunfinwall.insertLayer(0,extfin)
	extinsunfinwall.insertLayer(1,sc)

    # loop thru all the spaces
    spaces = model.getSpaces
    spaces.each do |space|
      constructions_hash = {}
      if selected_living.get.handle.to_s == space.spaceType.get.handle.to_s
        # loop thru all surfaces attached to the space
        surfaces = space.surfaces
        surfaces.each do |surface|
          if surface.surfaceType == "Wall" and surface.outsideBoundaryCondition == "Outdoors"
            surface.resetConstruction
            surface.setConstruction(extinsfinwall)
            constructions_hash[surface.name.to_s] = [surface.surfaceType,surface.outsideBoundaryCondition,"ExtInsFinWall"]
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
ProcessConstructionsExteriorInsulatedWallsWoodStud.new.registerWithApplication