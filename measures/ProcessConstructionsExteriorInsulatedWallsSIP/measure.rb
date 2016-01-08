# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/measures/measure_writing_guide/

#load sim.rb
require "#{File.dirname(__FILE__)}/resources/sim"

# start the measure
class ProcessConstructionsExteriorInsulatedWallsSIP < OpenStudio::Ruleset::ModelUserScript

	class SIPWall
		def initialize(sipIntSheathingType, sipFramingFactor, sipInsThickness, sipInsRvalue, sipIntSheathingThick)
			@sipIntSheathingType = sipIntSheathingType
			@sipFramingFactor = sipFramingFactor
			@sipInsThickness = sipInsThickness
			@sipInsRvalue = sipInsRvalue
			@sipIntSheathingThick = sipIntSheathingThick
		end
		attr_accessor(:spline_layer_thickness, :spline_layer_conductivity, :spline_layer_density, :spline_layer_spec_heat, :ins_layer_thickness, :ins_layer_conductivity, :ins_layer_density, :ins_layer_spec_heat)
		
		def SIPIntSheathingType
			return @sipIntSheathingType
		end
		
		def SIPFramingFactor
			return @sipFramingFactor
		end
		
		def SIPInsThickness
			return @sipInsThickness
		end

		def SIPInsRvalue
			return @sipInsRvalue
		end

		def SIPIntSheathingThick
			return @sipIntSheathingThick
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

  # human readable name
  def name
    return "Assign Residential Living Space SIP Wall Construction"
  end

  # human readable description
  def description
    return "This measure assigns a SIP construction to the living space exterior walls."
  end

  # human readable description of modeling approach
  def modeler_description
    return "Calculates material layer properties of SIP constructions for the exterior walls adjacent to the living space. Finds surfaces adjacent to the living space and sets applicable constructions."
  end

  # define the arguments that the user will input
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
	intsheathing_display_names = OpenStudio::StringVector.new
	intsheathing_display_names << "osb"
	intsheathing_display_names << "gyp"	
	
    #make a string argument for interior sheathing type
    selected_intsheathingtype = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("selectedintsheathingtype", intsheathing_display_names, true)
    selected_intsheathingtype.setDisplayName("SIP: Interior Sheathing Type")
	selected_intsheathingtype.setDescription("The interior sheathing type of the SIP wall.")
	selected_intsheathingtype.setDefaultValue("osb")
    args << selected_intsheathingtype	
	
	#make a double argument for framing factor
	userdefined_framingfrac = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedframingfrac", false)
	userdefined_framingfrac.setDisplayName("SIP: Framing Factor")
	userdefined_framingfrac.setUnits("frac")
	userdefined_framingfrac.setDescription("Total fraction of the wall that is framing for windows or doors.")
    userdefined_framingfrac.setDefaultValue(0.156)
	args << userdefined_framingfrac	
	
    #make a double argument for thickness of the sip insulation
    userdefined_sipinsthickness = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedsipinsthickness", true)
    userdefined_sipinsthickness.setDisplayName("SIP: Insulation Thickness")
	userdefined_sipinsthickness.setUnits("in")
	userdefined_sipinsthickness.setDescription("Thickness of the insulating core of the SIP.")
	userdefined_sipinsthickness.setDefaultValue(3.625)
    args << userdefined_sipinsthickness	
	
	#make a double argument for nominal R-value of the sip insulation
	userdefined_sipinsr = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedsipinsr", false)
	userdefined_sipinsr.setDisplayName("SIP: Nominal Insulation R-value")
	userdefined_sipinsr.setUnits("hr-ft^2-R/Btu")
	userdefined_sipinsr.setDescription("R-value is a measure of insulation's ability to resist heat traveling through it.")
    userdefined_sipinsr.setDefaultValue(17.5)
	args << userdefined_sipinsr

    #make a double argument for thickness of the interior sheathing
    userdefined_sipintsheathingthick = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedsipintsheathingthick", true)
    userdefined_sipintsheathingthick.setDisplayName("SIP: Interior Sheathing Thickness")
	userdefined_sipintsheathingthick.setUnits("in")
	userdefined_sipintsheathingthick.setDescription("The thickness of the interior sheathing.")
	userdefined_sipintsheathingthick.setDefaultValue(0.44)
    args << userdefined_sipintsheathingthick
	
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
  end

  # define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)

    # use the built-in error checking
    if !runner.validateUserArguments(arguments(model), user_arguments)
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
	# SIP
	selected_intsheathingtype = runner.getStringArgumentValue("selectedintsheathingtype",user_arguments)
	userdefined_framingfrac = runner.getDoubleArgumentValue("userdefinedframingfrac",user_arguments)
	userdefined_sipinsthickness = runner.getDoubleArgumentValue("userdefinedsipinsthickness",user_arguments)
	userdefined_sipinsr = runner.getDoubleArgumentValue("userdefinedsipinsr",user_arguments)
	userdefined_sipintsheathingthick = runner.getDoubleArgumentValue("userdefinedsipintsheathingthick",user_arguments)
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
	
	# SIP
	sipIntSheathingType = selected_intsheathingtype
	sipFramingFactor = userdefined_framingfrac
	sipInsThickness = userdefined_sipinsthickness
	sipInsRvalue = userdefined_sipinsr
	sipIntSheathingThick = userdefined_sipintsheathingthick

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
	sip = SIPWall.new(sipIntSheathingType, sipFramingFactor, sipInsThickness, sipInsRvalue, sipIntSheathingThick)
	extwallmass = ExtWallMass.new(gypsumThickness, gypsumNumLayers, gypsumRvalue)
	exteriorfinish = ExteriorFinish.new(finishThickness, finishConductivity, finishRvalue)
	wallsh = WallSheathing.new(rigidInsThickness, rigidInsRvalue, hasOSB, osbRvalue)
	
	# Create the sim object
	sim = Sim.new(model, runner)
	
	# Process the wood stud walls
	sip, int_sheathing, wallsh = sim._processConstructionsExteriorInsulatedWallsSIP(sip, extwallmass, exteriorfinish, wallsh)
	
	# Create the material layers
	
	# SplineLayer
	splineLayerThickness = sip.spline_layer_thickness
	splineLayerConductivty = sip.spline_layer_conductivity
	splineLayerDensity= sip.spline_layer_density
	splineLayerSpecHeat = sip.spline_layer_spec_heat
	
	# WallIns
	insLayerThickness = sip.ins_layer_thickness
	insLayerConductivity = sip.ins_layer_conductivity
	insLayerDensity = sip.ins_layer_density
	insLayerSpecHeat = sip.ins_layer_spec_heat
	
	# IntSheathing
	intSheathingConductivity = int_sheathing.k
	intSheathingDensity = int_sheathing.rho
	intSheathingSpecHeat = int_sheathing.Cp
	
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
	
	# SplineLayer
	spline = OpenStudio::Model::StandardOpaqueMaterial.new(model)
	spline.setName("SplineLayer")
	spline.setRoughness("Rough")
	spline.setThickness(OpenStudio::convert(splineLayerThickness,"ft","m").get)
	spline.setConductivity(OpenStudio::convert(splineLayerConductivty,"Btu/hr*ft*R","W/m*K").get)
	spline.setDensity(OpenStudio::convert(splineLayerDensity,"lb/ft^3","kg/m^3").get)
	spline.setSpecificHeat(OpenStudio::convert(splineLayerSpecHeat,"Btu/lb*R","J/kg*K").get)	
	
	# WallIns
	wallins = OpenStudio::Model::StandardOpaqueMaterial.new(model)
	wallins.setName("WallIns")
	wallins.setRoughness("Rough")
	wallins.setThickness(OpenStudio::convert(insLayerThickness,"ft","m").get)
	wallins.setConductivity(OpenStudio::convert(insLayerConductivity,"Btu/hr*ft*R","W/m*K").get)
	wallins.setDensity(OpenStudio::convert(insLayerDensity,"lb/ft^3","kg/m^3").get)
	wallins.setSpecificHeat(OpenStudio::convert(insLayerSpecHeat,"Btu/lb*R","J/kg*K").get)	
	
	# IntSheathing
	intsheathing = OpenStudio::Model::StandardOpaqueMaterial.new(model)
	intsheathing.setName("IntSheathing")
	intsheathing.setRoughness("Rough")
	intsheathing.setThickness(OpenStudio::convert(sipIntSheathingThick,"in","m").get)
	intsheathing.setConductivity(OpenStudio::convert(intSheathingConductivity,"Btu/hr*ft*R","W/m*K").get)
	intsheathing.setDensity(OpenStudio::convert(intSheathingDensity,"lb/ft^3","kg/m^3").get)
	intsheathing.setSpecificHeat(OpenStudio::convert(intSheathingSpecHeat,"Btu/lb*R","J/kg*K").get)		
	
	# ExtInsFinWall
	materials = []
	materials << extfin
	if rigidInsRvalue > 0
		materials << rigid
	end
	if hasOSB
		materials << osb
	end
	materials << spline
	materials << wallins
	materials << spline
	materials << intsheathing
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

  end
  
end

# register the measure to be used by the application
ProcessConstructionsExteriorInsulatedWallsSIP.new.registerWithApplication
