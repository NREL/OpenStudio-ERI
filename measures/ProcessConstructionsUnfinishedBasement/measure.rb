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
class ProcessConstructionsUnfinishedBasement < OpenStudio::Ruleset::ModelUserScript
  
	class UnfinishedBasement
		def initialize(ufbsmtWallContInsRvalue, ufbsmtWallCavityInsRvalueInstalled, ufbsmtCeilingCavityInsRvalueNominal, ufbsmtWallContInsThickness, ufbsmtWallInsHeight, ufbsmtCeilingJoistHeight, ufbsmtCeilingFramingFactor, ufbsmtWallCavityInsFillsCavity, ufbsmtWallInstallGrade, ufbsmtWallCavityDepth, ufbsmtWallFramingFactor)
			@ufbsmtWallContInsRvalue = ufbsmtWallContInsRvalue
			@ufbsmtWallCavityInsRvalueInstalled = ufbsmtWallCavityInsRvalueInstalled
			@ufbsmtCeilingCavityInsRvalueNominal = ufbsmtCeilingCavityInsRvalueNominal
			@ufbsmtCeilingJoistHeight = ufbsmtCeilingJoistHeight
			@ufbsmtWallContInsThickness = ufbsmtWallContInsThickness
			@ufbsmtWallInsHeight = ufbsmtWallInsHeight
			@ufbsmtCeilingJoistHeight = ufbsmtCeilingJoistHeight
			@ufbsmtCeilingFramingFactor = ufbsmtCeilingFramingFactor
			@ufbsmtWallCavityInsFillsCavity = ufbsmtWallCavityInsFillsCavity
			@ufbsmtWallInstallGrade = ufbsmtWallInstallGrade
			@ufbsmtWallCavityDepth = ufbsmtWallCavityDepth
			@ufbsmtWallFramingFactor = ufbsmtWallFramingFactor
		end
		
		attr_accessor(:UFBsmtRimJoistInsRvalue, :ext_perimeter)
		
		def UFBsmtWallContInsRvalue
			return @ufbsmtWallContInsRvalue
		end
		
		def UFBsmtWallCavityInsRvalueInstalled
			return @ufbsmtWallCavityInsRvalueInstalled
		end
		
		def UFBsmtCeilingCavityInsRvalueNominal
			return @ufbsmtCeilingCavityInsRvalueNominal
		end
		
		def UFBsmtCeilingJoistHeight
			return @ufbsmtCeilingJoistHeight
		end
		
		def UFBsmtWallContInsThickness
			return @ufbsmtWallContInsThickness
		end
		
		def UFBsmtWallInsHeight
			return @ufbsmtWallInsHeight
		end
		
		def UFBsmtCeilingJoistHeight
			return @ufbsmtCeilingJoistHeight
		end
		
		def UFBsmtCeilingFramingFactor
			return @ufbsmtCeilingFramingFactor
		end

		def UFBsmtWallCavityInsFillsCavity
			return @ufbsmtWallCavityInsFillsCavity
		end		
		
		def UFBsmtWallInstallGrade
			return @ufbsmtWallInstallGrade
		end
		
		def UFBsmtWallCavityDepth
			return @ufbsmtWallCavityDepth
		end
		
		def UFBsmtWallFramingFactor
			return @ufbsmtWallFramingFactor
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
	
	class WallSheathing
		def initialize(wallSheathingContInsThickness, wallSheathingContInsRvalue)
			@wallSheathingContInsThickness = wallSheathingContInsThickness
			@wallSheathingContInsRvalue = wallSheathingContInsRvalue
		end
		
		attr_accessor(:rigid_ins_layer_thickness, :rigid_ins_layer_conductivity, :rigid_ins_layer_density, :rigid_ins_layer_spec_heat)
		
		def WallSheathingContInsThickness
			return @wallSheathingContInsThickness
		end
		
		def WallSheathingContInsRvalue
			return @wallSheathingContInsRvalue
		end	
	end	
	
	class ExteriorFinish
		def initialize(finishThickness, finishConductivity)
			@finishThickness = finishThickness
			@finishConductivity = finishConductivity
		end
		
		def FinishThickness
			return @finishThickness
		end
		
		def FinishConductivity
			return @finishConductivity
		end
	end	
	
	class UFBsmtCeilingIns
		def initialize
		end
		attr_accessor(:ub_ceiling_Rvalue, :ub_ceiling_thickness, :ub_ceiling_conductivity, :ub_ceiling_density, :ub_ceiling_spec_heat)
	end
	
	class UFBaseWallIns
		def initialize
		end
		attr_accessor(:ub_wall_Rvalue, :ub_wall_thickness, :ub_wall_conductivity, :ub_wall_density, :ub_spec_heat, :ub_add_insul_layer)
	end

	class UFBaseWallFicR
		def initialize
		end
		attr_accessor(:ub_fictitious_Rvalue)
	end
	
	class UFBaseFloorFicR
		def initialize
		end
		attr_accessor(:ub_basement_floor_Rvalue)
	end
	
	class UFBsmtJoistandCavity
		def initialize
		end
		attr_accessor(:ub_rimjoist_thickness, :ub_rimjoist_conductivity, :ub_rimjoist_density, :ub_rimjoist_spec_heat, :ub_rimjoist_Rvalue)
	end
		
  #define the name that a user will see, this method may be deprecated as
  #the display name in PAT comes from the name field in measure.xml
  def name
    return "ProcessConstructionsUnfinishedBasement"
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

    #make a choice argument for ufbsmt
    selected_ufbsmt = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("selectedufbsmt", spacetype_handles, spacetype_display_names, true)
    selected_ufbsmt.setDisplayName("Of what space type is the unfinished basement?")
    args << selected_ufbsmt

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
    
	#make a choice argument for model objects
	ufbsmtins_display_names = OpenStudio::StringVector.new
	ufbsmtins_display_names << "Uninsulated"
	ufbsmtins_display_names << "Half Wall"
	ufbsmtins_display_names << "Whole Wall"
	ufbsmtins_display_names << "Ceiling"
	
	#make a choice argument for unfinished basement insulation type
	selected_ufbsmtins = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("selectedufbsmtins", ufbsmtins_display_names, true)
	selected_ufbsmtins.setDisplayName("Unfinished basement insulation type.")
	args << selected_ufbsmtins	

	#make a choice argument for model objects
	studsize_display_names = OpenStudio::StringVector.new
  studsize_display_names << "None"
	studsize_display_names << "2x4, 16 in o.c."
	studsize_display_names << "2x6, 24 in o.c."

    #make a string argument for wood stud size of wall cavity
    selected_studsize = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("selectedstudsize", studsize_display_names, false)
    selected_studsize.setDisplayName("Wood stud size of wall cavity.")
    selected_studsize.setDefaultValue("None")
    args << selected_studsize

	# Whole Wall / Ceiling Cavity Insulation
	#make a choice argument for wall / ceiling cavity insulation
	selected_ufbsmtwallceilcav = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("selectedufbsmtwallceilcav", material_handles, material_display_names, false)
	selected_ufbsmtwallceilcav.setDisplayName("Unfinished basement whole wall or ceiling cavity insulation. For manually entering unfinished basement whole wall or ceiling cavity insulation properties, leave blank.")
	args << selected_ufbsmtwallceilcav		
	
	#make a double argument for unfinished basement ceiling / whole wall cavity insulation R-value
	userdefined_ufbsmtwallceilcavr = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedufbsmtwallceilcavr", false)
	userdefined_ufbsmtwallceilcavr.setDisplayName("Unfinished basement whole wall cavity insulation or ceiling cavity insulation R-value [hr-ft^2-R/Btu].")
	userdefined_ufbsmtwallceilcavr.setDefaultValue(0)
	args << userdefined_ufbsmtwallceilcavr
	
	#make a choice argument for model objects
	installgrade_display_names = OpenStudio::StringVector.new
	installgrade_display_names << "I"
	installgrade_display_names << "II"
	installgrade_display_names << "III"	
	
	#make a choice argument for wall cavity insulation installation grade
	selected_installgrade = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("selectedinstallgrade", installgrade_display_names, false)
	selected_installgrade.setDisplayName("Insulation installation grade of wood stud wall cavity.")
	selected_installgrade.setDefaultValue("I")
	args << selected_installgrade	
	
	#make a bool argument for whether the cavity insulation fills the cavity
	selected_insfills = OpenStudio::Ruleset::OSArgument::makeBoolArgument("selectedinsfills", false)
	selected_insfills.setDisplayName("Cavity insulation fills the cavity?")
	selected_insfills.setDefaultValue(true)
	args << selected_insfills	
	
	# Wall Continuous Insulation
	#make a choice argument for wall continuous insulation
	selected_ufbsmtwallcont = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("selectedufbsmtwallcont", material_handles, material_display_names, false)
	selected_ufbsmtwallcont.setDisplayName("Unfinished basement wall continuous insulation. For manually entering unfinished basement wall continuous insulation properties, leave blank.")
	args << selected_ufbsmtwallcont	

	#make a double argument for unfinished basement wall continuous R-value
	userdefined_ufbsmtwallcontth = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedufbsmtwallcontth", false)
	userdefined_ufbsmtwallcontth.setDisplayName("Unfinished basement wall continuous insulation thickness [in].")
	userdefined_ufbsmtwallcontth.setDefaultValue(0)
	args << userdefined_ufbsmtwallcontth	
	
	#make a double argument for unfinished basement wall continuous insulation R-value
	userdefined_ufbsmtwallcontr = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedufbsmtwallcontr", false)
	userdefined_ufbsmtwallcontr.setDisplayName("Unfinished basement wall continuous insulation R-value [hr-ft^2-R/Btu].")
	userdefined_ufbsmtwallcontr.setDefaultValue(0)
	args << userdefined_ufbsmtwallcontr	
	
	# Ceiling Joist Height
	#make a choice argument for model objects
	joistheight_display_names = OpenStudio::StringVector.new
	joistheight_display_names << "9.25"	
	
	#make a choice argument for crawlspace ceiling joist height
	selected_ufbsmtceiljoistheight = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("selectedufbsmtceiljoistheight", joistheight_display_names, true)
	selected_ufbsmtceiljoistheight.setDisplayName("Unfinished basement ceiling joist height [in].")
	args << selected_ufbsmtceiljoistheight	
	
	# Ceiling Framing Factor
	#make a choice argument for model objects
	ceilff_display_names = OpenStudio::StringVector.new
	ceilff_display_names << "0.13"		
	
	#make a choice argument for crawlspace ceiling framing factor
	selected_ufbsmtceilff = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("selectedufbsmtceilff", ceilff_display_names, true)
	selected_ufbsmtceilff.setDisplayName("Unfinished basement ceiling framing factor [frac].")
	args << selected_ufbsmtceilff

	# Rim Joist
	#make a choice argument for rim joist insulation
	selected_ufbsmtrimjoist = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("selectedufbsmtrimjoist", material_handles, material_display_names, false)
	selected_ufbsmtrimjoist.setDisplayName("Unfinished basement rim joist insulation. For manually entering unfinished basement rim joist insulation properties, leave blank.")
	args << selected_ufbsmtrimjoist		
	
	#make a double argument for rim joist insulation R-value
	userdefined_ufbsmtrimjoistr = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedufbsmtrimjoistr", false)
	userdefined_ufbsmtrimjoistr.setDisplayName("Unfinished basement rim joist insulation R-value [hr-ft^2-R/Btu].")
	userdefined_ufbsmtrimjoistr.setDefaultValue(0)
	args << userdefined_ufbsmtrimjoistr	

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

	ufbsmtWallContInsRvalue = 0
	ufbsmtWallCavityInsRvalueInstalled = 0
	ufbsmtCeilingCavityInsRvalueNominal = 0
	ufbsmtWallInsHeight = 0
	ufbsmtRimJoistInsRvalue = 0
	carpetPadRValue = 0

    # Space Type
    selected_ufbsmt = runner.getOptionalWorkspaceObjectChoiceValue("selectedufbsmt",user_arguments,model)
    selected_living = runner.getOptionalWorkspaceObjectChoiceValue("selectedliving",user_arguments,model)

	# Unfinished Basement Insulation
	selected_ufbsmtins = runner.getStringArgumentValue("selectedufbsmtins",user_arguments)	
	
	# Wall Cavity
	selected_studsize = runner.getStringArgumentValue("selectedstudsize",user_arguments)
	userdefined_ufbsmtwallceilcavr = runner.getDoubleArgumentValue("userdefinedufbsmtwallceilcavr",user_arguments)
	selected_installgrade = runner.getStringArgumentValue("selectedinstallgrade",user_arguments)
	selected_insfills = runner.getBoolArgumentValue("selectedinsfills",user_arguments)	

	# Whole Wall / Ceiling Cavity Insulation
	if ["Half Wall", "Whole Wall", "Ceiling"].include? selected_ufbsmtins.to_s
		selected_ufbsmtwallceilcav = runner.getOptionalWorkspaceObjectChoiceValue("selectedufbsmtwallceilcav",user_arguments,model)
		if selected_ufbsmtwallceilcav.empty?
			userdefined_ufbsmtwallceilcavr = runner.getDoubleArgumentValue("userdefinedufbsmtwallceilcavr",user_arguments)
		end	
	end
	
	# Wall Continuous Insulation
	if ["Half Wall", "Whole Wall"].include? selected_ufbsmtins.to_s
		selected_ufbsmtwallcont = runner.getOptionalWorkspaceObjectChoiceValue("selectedufbsmtwallcont",user_arguments,model)
		if selected_ufbsmtwallcont.empty?
			userdefined_ufbsmtwallcontth = runner.getDoubleArgumentValue("userdefinedufbsmtwallcontth",user_arguments)
			userdefined_ufbsmtwallcontr = runner.getDoubleArgumentValue("userdefinedufbsmtwallcontr",user_arguments)
		end
		if selected_ufbsmtins.to_s == "Half Wall"
			ufbsmtWallInsHeight = 4
		elsif selected_ufbsmtins.to_s == "Whole Wall"
			ufbsmtWallInsHeight = 8
		end
	end	
	
	# Ceiling Joist Height
	selected_ufbsmtceiljoistheight = runner.getStringArgumentValue("selectedufbsmtceiljoistheight",user_arguments)
	
	# Ceiling Framing Factor
	selected_ufbsmtceilff = runner.getStringArgumentValue("selectedufbsmtceilff",user_arguments)	
	
	# Rim Joist
	if ["Half Wall", "Whole Wall"].include? selected_ufbsmtins.to_s
		selected_ufbsmtrimjoist = runner.getOptionalWorkspaceObjectChoiceValue("selectedufbsmtrimjoist",user_arguments,model)
		if selected_ufbsmtrimjoist.empty?
			userdefined_ufbsmtrimjoistr = runner.getDoubleArgumentValue("userdefinedufbsmtrimjoistr",user_arguments)
		end
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
	mat_soil = get_mat_soil
	mat_concrete = get_mat_concrete	
	
	# Cavity Insulation
	if selected_ufbsmtins.to_s == "Half Wall" or selected_ufbsmtins.to_s == "Whole Wall"
		if userdefined_ufbsmtwallceilcavr.nil?
			ubWallThickness = OpenStudio::convert(selected_ufbsmtwallceilcav.get.to_StandardOpaqueMaterial.get.getThickness.value,"m","in").get
			ubWallConductivity = OpenStudio::convert(selected_ufbsmtwallceilcav.get.to_StandardOpaqueMaterial.get.getConductivity.value,"W/m*K","Btu/hr*ft*R").get
			ufbsmtWallCavityInsRvalueInstalled = OpenStudio::convert(ubWallThickness,"in","ft").get / ubWallConductivity	
		else
			ufbsmtWallCavityInsRvalueInstalled = userdefined_ufbsmtwallceilcavr
		end
	elsif selected_ufbsmtins.to_s == "Ceiling"
		if userdefined_ufbsmtwallceilcavr.nil?
			ubCeilingThickness = OpenStudio::convert(selected_ufbsmtwallceilcav.get.to_StandardOpaqueMaterial.get.getThickness.value,"m","in").get
			ubCeilingConductivity = OpenStudio::convert(selected_ufbsmtwallceilcav.get.to_StandardOpaqueMaterial.get.getConductivity.value,"W/m*K","Btu/hr*ft*R").get
			ufbsmtCeilingCavityInsRvalueNominal = OpenStudio::convert(ubCeilingThickness,"in","ft").get / ubCeilingConductivity
		else
			ufbsmtCeilingCavityInsRvalueNominal = userdefined_ufbsmtwallceilcavr
		end
	end
	
	# Continuous Insulation
	if ["Half Wall", "Whole Wall"].include? selected_ufbsmtins.to_s
		if userdefined_ufbsmtwallcontr.nil?
			ubWallThickness = OpenStudio::convert(selected_ufbsmtwallcont.get.to_StandardOpaqueMaterial.get.getThickness.value,"m","in").get
			ubWallConductivity = OpenStudio::convert(selected_ufbsmtwallcont.get.to_StandardOpaqueMaterial.get.getConductivity.value,"W/m*K","Btu/hr*ft*R").get
			ufbsmtWallContInsThickness = ubWallThickness
			ufbsmtWallContInsRvalue = OpenStudio::convert(ubWallThickness,"in","ft").get / ubWallConductivity
		else
			ufbsmtWallContInsThickness = userdefined_ufbsmtwallcontth
			ufbsmtWallContInsRvalue = userdefined_ufbsmtwallcontr
		end
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
	ufbsmtCeilingJoistHeight_dict = {"9.25"=>9.25}
	ufbsmtCeilingJoistHeight = ufbsmtCeilingJoistHeight_dict[selected_ufbsmtceiljoistheight]	
		
	# Ceiling Framing Factor
	ufbsmtCeilingFramingFactor_dict = {"0.13"=>0.13}
	ufbsmtCeilingFramingFactor = ufbsmtCeilingFramingFactor_dict[selected_ufbsmtceilff]
	
	# Rim Joist
	if ["Half Wall", "Whole Wall"].include? selected_ufbsmtins.to_s
		if userdefined_ufbsmtrimjoistr.nil?
			ubRimJoistThickness = OpenStudio::convert(selected_ufbsmtrimjoist.get.to_StandardOpaqueMaterial.get.getThickness.value,"m","in").get
			ubRimJoistConductivity = OpenStudio::convert(selected_ufbsmtrimjoist.get.to_StandardOpaqueMaterial.get.getConductivity.value,"W/m*K","Btu/hr*ft*R").get		
			ufbsmtRimJoistInsRvalue = OpenStudio::convert(ubRimJoistThickness,"in","ft").get / ubRimJoistConductivity	
		else
			ufbsmtRimJoistInsRvalue = userdefined_ufbsmtrimjoistr
		end
	end
	
	# Gypsum	
    gypsumRoughness = "Rough"
    gypsumThickness = userdefined_gypthickness
    gypsumNumLayers = userdefined_gyplayers
    gypsumConductivity = mat_gyp.k
    gypsumDensity = mat_gyp.rho
    gypsumSpecificHeat = mat_gyp.Cp
    gypsumThermalAbs = get_mat_gypsum1_2in(mat_gyp).TAbs
    gypsumSolarAbs = get_mat_gypsum1_2in(mat_gyp).SAbs
    gypsumVisibleAbs = get_mat_gypsum1_2in(mat_gyp).VAbs
    gypsumRvalue = (OpenStudio::convert(gypsumThickness,"in","ft").get * gypsumNumLayers / mat_gyp.k)

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

	# Create the material class instances
	ub = UnfinishedBasement.new(ufbsmtWallContInsRvalue, ufbsmtWallCavityInsRvalueInstalled, ufbsmtCeilingCavityInsRvalueNominal, ufbsmtWallContInsThickness, ufbsmtWallInsHeight, ufbsmtCeilingJoistHeight, ufbsmtCeilingFramingFactor, ufbsmtWallCavityInsFillsCavity, ufbsmtWallInstallGrade, ufbsmtWallCavityDepth, ufbsmtWallFramingFactor)
	carpet = Carpet.new(carpetFloorFraction, carpetPadRValue)
	floor_mass = FloorMass.new(floorMassThickness, floorMassConductivity, floorMassDensity, floorMassSpecificHeat)
	extwallmass = ExtWallMass.new(gypsumThickness, gypsumNumLayers, gypsumRvalue)
	uci = UFBsmtCeilingIns.new
	uwi = UFBaseWallIns.new
	uwfr = UFBaseWallFicR.new
	uffr = UFBaseFloorFicR.new
	ujc = UFBsmtJoistandCavity.new
	wallsh = WallSheathing.new(wallSheathingContInsThickness, wallSheathingContInsRvalue)
	exterior_finish = ExteriorFinish.new(finishThickness, finishConductivity)	
	
	if ufbsmtWallContInsRvalue > 0 or ufbsmtWallCavityInsRvalueInstalled > 0
		ub.UFBsmtRimJoistInsRvalue = ufbsmtRimJoistInsRvalue
	end	

	# Create the sim object
	sim = Sim.new(model)	
	
	# Process the slab
	uci, uwi, uwfr, uffr, ujc, wallsh = sim._processConstructionsUnfinishedBasement(ub, carpet, floor_mass, extwallmass, wallsh, exterior_finish, uci, uwi, uwfr, uffr, ujc)	
    
	# UFBsmtCeilingIns
	uciThickness = uci.ub_ceiling_thickness
	uciConductivity = uci.ub_ceiling_conductivity
	uciDensity = uci.ub_ceiling_density
	uciSpecificHeat = uci.ub_ceiling_spec_heat
	uciRvalue = uci.ub_ceiling_Rvalue
	if uciRvalue > 0
		uci = OpenStudio::Model::StandardOpaqueMaterial.new(model)
		uci.setName("UFBsmtCeilingIns")
		uci.setRoughness("Rough")
		uci.setThickness(OpenStudio::convert(uciThickness,"ft","m").get)
		uci.setConductivity(OpenStudio::convert(uciConductivity,"Btu/hr*ft*R","W/m*K").get)
		uci.setDensity(OpenStudio::convert(uciDensity,"lb/ft^3","kg/m^3").get)
		uci.setSpecificHeat(OpenStudio::convert(uciSpecificHeat,"Btu/lb*R","J/kg*K").get)
	end
	
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
	
	# UnfinBInsFinFloor
	layercount = 0
	unfinbinsfinfloor = OpenStudio::Model::Construction.new(model)
	unfinbinsfinfloor.setName("UnfinBInsFinFloor")
	if uciRvalue > 0
		unfinbinsfinfloor.insertLayer(layercount,uci)
		layercount += 1
	end
	unfinbinsfinfloor.insertLayer(layercount,ply3_4)
	layercount += 1
	unfinbinsfinfloor.insertLayer(layercount,fm)
	layercount += 1
	if carpet.CarpetFloorFraction > 0
		unfinbinsfinfloor.insertLayer(layercount,cbl)
	end
	
	# UFBaseWallIns
	uwiThickness = uwi.ub_wall_thickness
	uwiConductivity = uwi.ub_wall_conductivity
	uwiDensity = uwi.ub_wall_density
	uwiSpecificHeat = uwi.ub_spec_heat
	uwiaddinsullayer = uwi.ub_add_insul_layer
	if uwiaddinsullayer
		uwi = OpenStudio::Model::StandardOpaqueMaterial.new(model)
		uwi.setName("UFBaseWallIns")
		uwi.setThickness(OpenStudio::convert(uwiThickness,"ft","m").get)
		uwi.setConductivity(OpenStudio::convert(uwiConductivity,"Btu/hr*ft*R","W/m*K").get)
		uwi.setDensity(OpenStudio::convert(uwiDensity,"lb/ft^3","kg/m^3").get)
		uwi.setSpecificHeat(OpenStudio::convert(uwiSpecificHeat,"Btu/lb*R","J/kg*K").get)
	end
	
	# UFBaseWall-FicR
	uwfrRvalue = uwfr.ub_fictitious_Rvalue
	if uwfrRvalue > 0
		uwfr = OpenStudio::Model::MasslessOpaqueMaterial.new(model)
		uwfr.setName("UFBaseWall-FicR")
		uwfr.setRoughness("Rough")
		uwfr.setThermalResistance(OpenStudio::convert(uwfrRvalue,"hr*ft^2*R/Btu","m^2*K/W").get)
	end
	
	# Soil-12in
	soil = OpenStudio::Model::StandardOpaqueMaterial.new(model)
	soil.setName("Soil-12in")
	soil.setRoughness("Rough")
	soil.setThickness(OpenStudio::convert(get_mat_soil12in(mat_soil).thick,"ft","m").get)
	soil.setConductivity(OpenStudio::convert(mat_soil.k,"Btu/hr*ft*R","W/m*K").get)
	soil.setDensity(OpenStudio::convert(mat_soil.rho,"lb/ft^3","kg/m^3").get)
	soil.setSpecificHeat(OpenStudio::convert(mat_soil.Cp,"Btu/lb*R","J/kg*K").get)	
	
	# Concrete-8in
	conc8 = OpenStudio::Model::StandardOpaqueMaterial.new(model)
	conc8.setName("Concrete-8in")
	conc8.setRoughness("Rough")
	conc8.setThickness(OpenStudio::convert(get_mat_concrete8in(mat_concrete).thick,"ft","m").get)
	conc8.setConductivity(OpenStudio::convert(mat_concrete.k,"Btu/hr*ft*R","W/m*K").get)
	conc8.setDensity(OpenStudio::convert(mat_concrete.rho,"lb/ft^3","kg/m^3").get)
	conc8.setSpecificHeat(OpenStudio::convert(mat_concrete.Cp,"Btu/lb*R","J/kg*K").get)
	conc8.setThermalAbsorptance(get_mat_concrete8in(mat_concrete).TAbs)	
	
	# GrndInsUnfinBWall
	layercount = 0
	grndinsunfinbwall = OpenStudio::Model::Construction.new(model)
	grndinsunfinbwall.setName("GrndInsUnfinBWall")
	if uwfrRvalue > 0
		# Fictitious layer behind unfinished basement wall to achieve equivalent R-value. See Winkelmann article.
		grndinsunfinbwall.insertLayer(layercount,uwfr)
		layercount += 1
	end
	grndinsunfinbwall.insertLayer(layercount,soil)
	layercount += 1
	grndinsunfinbwall.insertLayer(layercount,conc8)
	layercount += 1
	if uwiaddinsullayer
		grndinsunfinbwall.insertLayer(layercount,uwi)
	end
	
	# UFBaseFloor-FicR
	uffrRvalue = uffr.ub_basement_floor_Rvalue
	uffr = OpenStudio::Model::MasslessOpaqueMaterial.new(model)
	uffr.setName("UFBaseFloor-FicR")
	uffr.setRoughness("Rough")
	uffr.setThermalResistance(OpenStudio::convert(uffrRvalue,"hr*ft^2*R/Btu","m^2*K/W").get)
	
	# Concrete-4in
	conc4 = OpenStudio::Model::StandardOpaqueMaterial.new(model)
	conc4.setName("Concrete-4in")
	conc4.setRoughness("Rough")
	conc4.setThickness(OpenStudio::convert(get_mat_concrete4in(mat_concrete).thick,"ft","m").get)
	conc4.setConductivity(OpenStudio::convert(mat_concrete.k,"Btu/hr*ft*R","W/m*K").get)
	conc4.setDensity(OpenStudio::convert(mat_concrete.rho,"lb/ft^3","kg/m^3").get)
	conc4.setSpecificHeat(OpenStudio::convert(mat_concrete.Cp,"Btu/lb*R","J/kg*K").get)
	conc4.setThermalAbsorptance(get_mat_concrete4in(mat_concrete).TAbs)	
	
	# GrndUninsUnfinBFloor
	layercount = 0
	grnduninsunfinbfloor = OpenStudio::Model::Construction.new(model)
	grnduninsunfinbfloor.setName("GrndUninsUnfinBFloor")
	grnduninsunfinbfloor.insertLayer(layercount,uffr)
	layercount += 1
	grnduninsunfinbfloor.insertLayer(layercount,soil)
	layercount += 1
	grnduninsunfinbfloor.insertLayer(layercount,conc4)
	
	# RevUnfinBInsFinFloor
	layercount = 0
	revunfinbinsfinfloor = OpenStudio::Model::Construction.new(model)
  revunfinbinsfinfloor.setName("RevUnfinBInsFinFloor")
  unfinbinsfinfloor.layers.reverse_each do |layer|
    revunfinbinsfinfloor.insertLayer(layercount,layer)
    layercount += 1
  end

	# Rigid
	if wallSheathingContInsRvalue > 0
		rigid = OpenStudio::Model::StandardOpaqueMaterial.new(model)
		rigid.setName("WallRigidIns")
		rigid.setRoughness("Rough")
		rigid.setThickness(OpenStudio::convert(wallsh.rigid_ins_layer_thickness,"ft","m").get)
		rigid.setConductivity(OpenStudio::convert(wallsh.rigid_ins_layer_conductivity,"Btu/hr*ft*R","W/m*K").get)
		rigid.setDensity(OpenStudio::convert(wallsh.rigid_ins_layer_density,"lb/ft^3","kg/m^3").get)
		rigid.setSpecificHeat(OpenStudio::convert(wallsh.rigid_ins_layer_spec_heat,"Btu/lb*R","J/kg*K").get)
	end
	
	# Plywood-3_2in
	ply3_2 = OpenStudio::Model::StandardOpaqueMaterial.new(model)
	ply3_2.setName("Plywood-3_2in")
	ply3_2.setRoughness("Rough")
	ply3_2.setThickness(OpenStudio::convert(get_mat_plywood3_2in(mat_wood).thick,"ft","m").get)
	ply3_2.setConductivity(OpenStudio::convert(mat_wood.k,"Btu/hr*ft*R","W/m*K").get)
	ply3_2.setDensity(OpenStudio::convert(mat_wood.rho,"lb/ft^3","kg/m^3").get)
	ply3_2.setSpecificHeat(OpenStudio::convert(mat_wood.Cp,"Btu/lb*R","J/kg*K").get)	
	
	# UFBsmtJoistandCavity
	ujcThickness = ujc.ub_rimjoist_thickness
	ujcConductivity = ujc.ub_rimjoist_conductivity
	ujcDensity = ujc.ub_rimjoist_density
	ujcSpecificHeat = ujc.ub_rimjoist_spec_heat
	ujcrimjoistrvalue = ujc.ub_rimjoist_Rvalue
	if ujcrimjoistrvalue > 0
		ujc = OpenStudio::Model::StandardOpaqueMaterial.new(model)
		ujc.setName("UFBsmtJoistandCavity")
		ujc.setRoughness("Rough")
		ujc.setThickness(OpenStudio::convert(ujcThickness,"ft","m").get)
		ujc.setConductivity(OpenStudio::convert(ujcConductivity,"Btu/hr*ft*R","W/m*K").get)
		ujc.setDensity(OpenStudio::convert(ujcDensity,"lb/ft^3","kg/m^3").get)
		ujc.setSpecificHeat(OpenStudio::convert(ujcSpecificHeat,"Btu/lb*R","J/kg*K").get)
	end
	
	# UFBsmtRimJoist
	layercount = 0
	ufbsmtrimjoist = OpenStudio::Model::Construction.new(model)
	ufbsmtrimjoist.setName("UFBsmtRimJoist")
	ufbsmtrimjoist.insertLayer(layercount,extfin)
	layercount += 1
	if wallsh.WallSheathingContInsRvalue > 0 #Wall sheathing also covers rimjoist
		ufbsmtrimjoist.insertLayer(layercount,rigid)
		layercount += 1
	end
	ufbsmtrimjoist.insertLayer(layercount,ply3_2)
	layercount += 1
	if ujcrimjoistrvalue > 0
		ufbsmtrimjoist.insertLayer(layercount,ujc)
	end

    # loop thru all the spaces
    spaces = model.getSpaces
    spaces.each do |space|
      constructions_hash = {}
      if selected_ufbsmt.get.handle.to_s == space.spaceType.get.handle.to_s
        # loop thru all surfaces attached to the space
        surfaces = space.surfaces
        surfaces.each do |surface|
          if surface.surfaceType == "RoofCeiling" and surface.outsideBoundaryCondition == "Surface"
            surface.resetConstruction
            surface.setConstruction(revunfinbinsfinfloor)
            constructions_hash[surface.name.to_s] = [surface.surfaceType,surface.outsideBoundaryCondition,"RevUnfinBInsFinFloor"]
          elsif surface.surfaceType == "Wall" and surface.outsideBoundaryCondition == "Ground"
            surface.resetConstruction
            surface.setConstruction(grndinsunfinbwall)
            constructions_hash[surface.name.to_s] = [surface.surfaceType,surface.outsideBoundaryCondition,"GrndInsUnfinBWall"]
          elsif surface.surfaceType == "Floor" and surface.outsideBoundaryCondition == "Ground"
            surface.resetConstruction
            surface.setConstruction(grnduninsunfinbfloor)
            constructions_hash[surface.name.to_s] = [surface.surfaceType,surface.outsideBoundaryCondition,"GrndUninsUnfinBFloor"]
          elsif surface.surfaceType == "Wall" and surface.outsideBoundaryCondition == "Outdoors"
            surface.resetConstruction
            surface.setConstruction(ufbsmtrimjoist)
            constructions_hash[surface.name.to_s] = [surface.surfaceType,surface.outsideBoundaryCondition,"UFBsmtRimJoist"]
          end
        end
      elsif selected_living.get.handle.to_s == space.spaceType.get.handle.to_s
        # loop thru all surfaces attached to the space
        surfaces = space.surfaces
        surfaces.each do |surface|
          if surface.surfaceType == "Floor" and surface.outsideBoundaryCondition == "Surface"
            adjacentSpaces = model.getSpaces
            adjacentSpaces.each do |adjacentSpace|
              if selected_ufbsmt.get.handle.to_s == adjacentSpace.spaceType.get.handle.to_s
                adjacentSurfaces = adjacentSpace.surfaces
                adjacentSurfaces.each do |adjacentSurface|
                  if surface.adjacentSurface.get.handle.to_s == adjacentSurface.handle.to_s
                    surface.resetConstruction
                    surface.setConstruction(unfinbinsfinfloor)
                    constructions_hash[surface.name.to_s] = [surface.surfaceType,surface.outsideBoundaryCondition,"UnfinBInsFinFloor"]
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
 
  end #end the run method

end #end the measure

#this allows the measure to be use by the application
ProcessConstructionsUnfinishedBasement.new.registerWithApplication