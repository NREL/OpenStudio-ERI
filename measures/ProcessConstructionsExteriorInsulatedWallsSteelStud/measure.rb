# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/measures/measure_writing_guide/

#load sim.rb
require "#{File.dirname(__FILE__)}/resources/sim"

# start the measure
class ProcessConstructionsExteriorInsulatedWallsSteelStud < OpenStudio::Ruleset::ModelUserScript

	class SteelStudWall
		def initialize(ssWallCavityInsRvalueInstalled, ssWallInstallGrade, ssWallCavityDepth, ssWallCavityInsFillsCavity, ssWallFramingFactor, ssWallStudSpacing, ssWallCorrectionFactor)
			@ssWallCavityInsRvalueInstalled = ssWallCavityInsRvalueInstalled
			@ssWallInstallGrade = ssWallInstallGrade
			@ssWallCavityDepth = ssWallCavityDepth
			@ssWallCavityInsFillsCavity = ssWallCavityInsFillsCavity
			@ssWallFramingFactor = ssWallFramingFactor
			@ssWallStudSpacing = ssWallStudSpacing
			@ssWallCorrectionFactor = ssWallCorrectionFactor
		end
		
		def SSWallCavityInsRvalueInstalled
			return @ssWallCavityInsRvalueInstalled
		end
		
		def SSWallInstallGrade
			return @ssWallInstallGrade
		end
		
		def SSWallCavityDepth
			return @ssWallCavityDepth
		end
		
		def SSWallCavityInsFillsCavity
			return @ssWallCavityInsFillsCavity
		end 
		
		def SSWallFramingFactor
			return @ssWallFramingFactor
		end
		
		def SSWallStudSpacing
			return @ssWallStudSpacing
		end
		
		def SSWallCorrectionFactor
			return @ssWallCorrectionFactor
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

  # human readable name
  def name
    return "ProcessConstructionsExteriorInsulatedWallsSteelStud"
  end

  # human readable description
  def description
    return ""
  end

  # human readable description of modeling approach
  def modeler_description
    return ""
  end

  # define the arguments that the user will input
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
	mat_densepack_generic = get_mat_densepack_generics	
	
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
	ssWallCavityInsFillsCavity = selected_insfills
	ssWallCavityInsRvalueInstalled = userdefined_instcavr
	ssWallInstallGrade_dict = {"I"=>1, "II"=>2, "III"=>3}
	ssWallInstallGrade = ssWallInstallGrade_dict[selected_installgrade]
	ssWallCavityDepth_dict = {"2x4"=>3.5, "2x6"=>5.5, "2x8"=>7.25, "2x10"=>9.25, "2x12"=>11.25, "2x14"=>13.25, "2x16"=>15.25} 
	ssWallCavityDepth = ssWallCavityDepth_dict[selected_studsize]	
	ssWallFramingFactor_dict = {"16 in o.c."=>0.25, "24 in o.c."=>0.22}
	ssWallFramingFactor = ssWallFramingFactor_dict[selected_spacing]
	ssWallStudSpacing =
	ssWallCorrectionFactor =

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
	ss = StudSteelWall.new(ssWallCavityInsRvalueInstalled, ssWallInstallGrade, ssWallCavityDepth, ssWallCavityInsFillsCavity, ssWallFramingFactor, ssWallStudSpacing, ssWallCorrectionFactor)
	extwallmass = ExtWallMass.new(gypsumThickness, gypsumNumLayers, gypsumRvalue)
	exteriorfinish = ExteriorFinish.new(finishThickness, finishConductivity, finishRvalue)
	wallsh = WallSheathing.new(rigidInsThickness, rigidInsRvalue, hasOSB, osbRvalue)
	sc = StudandCavity.new	

	# Create the sim object
	sim = Sim.new(model, runner)
	
	# Process the steel stud walls
	sc, wallsh = sim._processConstructionsExteriorInsulatedWallsSteelStud(ss, extwallmass, exteriorfinish, wallsh, sc)	
	
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

  end
  
end

# register the measure to be used by the application
ProcessConstructionsExteriorInsulatedWallsSteelStud.new.registerWithApplication
