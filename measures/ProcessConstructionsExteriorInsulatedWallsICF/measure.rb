# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/measures/measure_writing_guide/

#load sim.rb
require "#{File.dirname(__FILE__)}/resources/sim"

# start the measure
class ProcessConstructionsExteriorInsulatedWallsICF < OpenStudio::Ruleset::ModelUserScript

  # human readable name
  def name
    return "Assign Residential Living Space ICF Wall Construction"
  end

  # human readable description
  def description
    return "This measure assigns an ICF construction to the living space exterior walls."
  end

  # human readable description of modeling approach
  def modeler_description
    return "Calculates material layer properties of ICF constructions for the exterior walls adjacent to the living space. Finds surfaces adjacent to the living space and sets applicable constructions."
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
        
    #make a double argument for framing factor
    userdefined_framingfrac = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedframingfrac", false)
    userdefined_framingfrac.setDisplayName("ICF: Framing Factor")
    userdefined_framingfrac.setUnits("frac")
    userdefined_framingfrac.setDescription("Total fraction of the wall that is framing for windows or doors.")
    userdefined_framingfrac.setDefaultValue(0.076)
    args << userdefined_framingfrac 
    
    #make a double argument for thickness of the icf insulation
    userdefined_icfinsthickness = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedicfinsthickness", true)
    userdefined_icfinsthickness.setDisplayName("ICF: Insulation Thickness")
    userdefined_icfinsthickness.setUnits("in")
    userdefined_icfinsthickness.setDescription("Thickness of each insulating layer of the form.")
    userdefined_icfinsthickness.setDefaultValue(2.0)
    args << userdefined_icfinsthickness 
    
    #make a double argument for nominal R-value of the icf insulation
    userdefined_icfinsr = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedicfinsr", false)
    userdefined_icfinsr.setDisplayName("ICF: Nominal Insulation R-value")
    userdefined_icfinsr.setUnits("hr-ft^2-R/Btu")
    userdefined_icfinsr.setDescription("R-value is a measure of insulation's ability to resist heat traveling through it.")
    userdefined_icfinsr.setDefaultValue(10.0)
    args << userdefined_icfinsr

    #make a double argument for thickness of the concrete
    userdefined_sipintsheathingthick = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedicfconcth", true)
    userdefined_sipintsheathingthick.setDisplayName("ICF: Concrete Thickness")
    userdefined_sipintsheathingthick.setUnits("in")
    userdefined_sipintsheathingthick.setDescription("The thickness of the concrete core of the ICF.")
    userdefined_sipintsheathingthick.setDefaultValue(4.0)
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
    # ICF
    userdefined_framingfrac = runner.getDoubleArgumentValue("userdefinedframingfrac",user_arguments)
    userdefined_icfinsthickness = runner.getDoubleArgumentValue("userdefinedicfinsthickness",user_arguments)
    userdefined_icfinsr = runner.getDoubleArgumentValue("userdefinedicfinsr",user_arguments)
    userdefined_icfconcth = runner.getDoubleArgumentValue("userdefinedicfconcth",user_arguments)
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
    mat_wood = BaseMaterial.Wood
    mat_gyp_extwall = Material.GypsumExtWall
    mat_rigid = BaseMaterial.InsulationRigid
    mat_densepack_generic = BaseMaterial.InsulationGenericDensepack

    # Gypsum    
    gypsumThickness = userdefined_gypthickness
    gypsumNumLayers = userdefined_gyplayers
    gypsumConductivity = mat_gyp_extwall.k
    gypsumDensity = mat_gyp_extwall.rho
    gypsumSpecificHeat = mat_gyp_extwall.Cp
    gypsumThermalAbs = mat_gyp_extwall.TAbs
    gypsumSolarAbs = mat_gyp_extwall.SAbs
    gypsumVisibleAbs = mat_gyp_extwall.VAbs
    gypsumRvalue = (OpenStudio::convert(gypsumThickness,"in","ft").get * gypsumNumLayers / mat_gyp_extwall.k)

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
        osbRvalue = Material.Plywood1_2in.Rvalue
    else
        osbRvalue = 0
    end
    
    # ICF
    icfFramingFactor = userdefined_framingfrac
    icfInsThickness = userdefined_icfinsthickness
    icfInsRvalue = userdefined_icfinsr
    icfConcreteThickness = userdefined_icfconcth

    # Exterior Finish
    finishRvalue = userdefined_extfinr
    finishThickness = userdefined_extfinthickness
    finishConductivity = finishThickness / finishRvalue
    finishDensity = userdefined_extfindensity
    finishSpecHeat = userdefined_extfinspecheat
    finishThermalAbs = userdefined_extfinthermalabs
    finishSolarAbs = userdefined_extfinabs
    finishVisibleAbs = userdefined_extfinabs

    # Process the wood stud walls
    ins_thick, ins_cond, ins_dens, ins_sh, conc_thick, conc_cond, conc_dens, conc_sh, rigid_thick, rigid_cond, rigid_dens, rigid_sh = _processConstructionsExteriorInsulatedWallsICF(icfFramingFactor, icfInsThickness, icfInsRvalue, icfConcreteThickness, gypsumThickness, gypsumNumLayers, gypsumRvalue, finishThickness, finishConductivity, finishRvalue, rigidInsThickness, rigidInsRvalue, hasOSB, osbRvalue)
    
    # Create the material layers
    
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
      rigid.setThickness(OpenStudio::convert(rigid_thick,"ft","m").get)
      rigid.setConductivity(OpenStudio::convert(rigid_cond,"Btu/hr*ft*R","W/m*K").get)
      rigid.setDensity(OpenStudio::convert(rigid_dens,"lb/ft^3","kg/m^3").get)
      rigid.setSpecificHeat(OpenStudio::convert(rigid_sh,"Btu/lb*R","J/kg*K").get)
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
    
    # ICFInsForm
    insform = OpenStudio::Model::StandardOpaqueMaterial.new(model)
    insform.setName("ICFInsForm")
    insform.setRoughness("Rough")
    insform.setThickness(OpenStudio::convert(ins_thick,"ft","m").get)
    insform.setConductivity(OpenStudio::convert(ins_cond,"Btu/hr*ft*R","W/m*K").get)
    insform.setDensity(OpenStudio::convert(ins_dens,"lb/ft^3","kg/m^3").get)
    insform.setSpecificHeat(OpenStudio::convert(ins_sh,"Btu/lb*R","J/kg*K").get)    
    
    # ICFConcrete
    conc = OpenStudio::Model::StandardOpaqueMaterial.new(model)
    conc.setName("ICFConcrete")
    conc.setRoughness("Rough")
    conc.setThickness(OpenStudio::convert(conc_thick,"ft","m").get)
    conc.setConductivity(OpenStudio::convert(conc_cond,"Btu/hr*ft*R","W/m*K").get)
    conc.setDensity(OpenStudio::convert(conc_dens,"lb/ft^3","kg/m^3").get)
    conc.setSpecificHeat(OpenStudio::convert(conc_sh,"Btu/lb*R","J/kg*K").get)      
    
    # ExtInsFinWall
    materials = []
    materials << extfin
    if rigidInsRvalue > 0
        materials << rigid
    end
    if hasOSB
        materials << osb
    end
    materials << insform
    materials << conc
    materials << insform
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

  def _processConstructionsExteriorInsulatedWallsICF(icfFramingFactor, icfInsThickness, icfInsRvalue, icfConcreteThickness, gypsumThickness, gypsumNumLayers, gypsumRvalue, finishThickness, finishConductivity, finishRvalue, rigidInsThickness, rigidInsRvalue, hasOSB, osbRvalue)
    overall_wall_Rvalue = get_icf_wall_r_assembly(icfFramingFactor, icfInsThickness, icfInsRvalue, icfConcreteThickness, gypsumThickness, gypsumNumLayers, finishThickness, finishConductivity, rigidInsThickness, rigidInsRvalue, hasOSB) 
    
    conc_layer_equiv_Rvalue = (1.0 / (icfFramingFactor / (OpenStudio.convert(icfConcreteThickness,"in","ft").get / BaseMaterial.Wood.k) + (1.0 - icfFramingFactor) / (OpenStudio.convert(icfConcreteThickness,"in","ft").get / BaseMaterial.Concrete.k))) # hr*ft^2*F/Btu
    
    ins_thick = OpenStudio.convert(icfInsThickness,"in","ft").get # ft
    ins_cond = (ins_thick / ((overall_wall_Rvalue - (AirFilms.VerticalR + AirFilms.OutsideR + rigidInsRvalue + osbRvalue + conc_layer_equiv_Rvalue + finishRvalue + gypsumRvalue)) / 2.0)) # Btu/hr*ft*F
    ins_dens = icfFramingFactor * BaseMaterial.Wood.rho + (1.0 - icfFramingFactor) * BaseMaterial.InsulationRigid.rho # lbm/ft^3
    ins_sh = (icfFramingFactor * BaseMaterial.Wood.Cp * BaseMaterial.Wood.rho + (1.0 - icfFramingFactor) * BaseMaterial.InsulationRigid.Cp * BaseMaterial.InsulationRigid.rho) / ins_dens # Btu/lbm-F
    
    conc_thick = OpenStudio.convert(icfConcreteThickness,"in","ft").get # ft
    conc_cond = conc_thick / conc_layer_equiv_Rvalue # Btu/hr*ft*F
    conc_dens = icfFramingFactor * BaseMaterial.Wood.rho + (1.0 - icfFramingFactor) * BaseMaterial.Concrete.rho # lbm/ft^3
    conc_sh = (icfFramingFactor * BaseMaterial.Wood.Cp * BaseMaterial.Wood.rho + (1.0 - icfFramingFactor) * BaseMaterial.Concrete.Cp * BaseMaterial.Concrete.rho) / conc_dens # lbm/ft^3
    
    rigid_thick, rigid_cond, rigid_dens, rigid_sh = _addInsulatedSheathingMaterial(rigidInsThickness, rigidInsRvalue)
    
    return ins_thick, ins_cond, ins_dens, ins_sh, conc_thick, conc_cond, conc_dens, conc_sh, rigid_thick, rigid_cond, rigid_dens, rigid_sh
    
  end

  def get_icf_wall_r_assembly(icfFramingFactor, icfInsThickness, icfInsRvalue, icfConcreteThickness, gypsumThickness, gypsumNumLayers, finishThickness, finishConductivity, rigidInsThickness=0, rigidInsRvalue=0, hasOSB=false)
    # Returns assembly R-value for ICF wall, including air films.
    
    mat_wood = BaseMaterial.Wood
    mat_plywood1_2in = Material.Plywood1_2in
    mat_concrete = BaseMaterial.Concrete
    
    path_fracs = [icfFramingFactor, 1.0 - icfFramingFactor]
    
    icf_wall = Construction.new(path_fracs)

    # Interior Film
    icf_wall.addlayer(thickness=OpenStudio.convert(1.0,"in","ft").get, conductivity_list=[OpenStudio.convert(1.0,"in","ft").get / AirFilms.VerticalR])

    # Interior Finish (GWB)
    icf_wall.addlayer(thickness=OpenStudio.convert(gypsumThickness,"in","ft").get, conductivity_list=[BaseMaterial.Gypsum.k])

    # Framing / Rigid Ins
    ins_k = OpenStudio.convert(icfInsThickness,"in","ft").get / icfInsRvalue
    icf_wall.addlayer(thickness=OpenStudio.convert(icfInsThickness,"in","ft").get, conductivity_list=[mat_wood.k, ins_k])

    # Concrete
    icf_wall.addlayer(thickness=OpenStudio.convert(icfConcreteThickness,"in","ft").get, conductivity_list=[mat_wood.k, mat_concrete.k])

    # Framing / Rigid Ins
    ins_k = OpenStudio.convert(icfInsThickness,"in","ft").get / icfInsRvalue
    icf_wall.addlayer(thickness=OpenStudio.convert(icfInsThickness,"in","ft").get, conductivity_list=[mat_wood.k, ins_k])

    # OSB sheathing
    if hasOSB
        icf_wall.addlayer(thickness=nil, conductivity_list=nil, material=mat_plywood1_2in, material_list=nil)
    end

    # Rigid
    if rigidInsRvalue > 0
        rigid_k = OpenStudio.convert(rigidInsThickness,"in","ft").get / rigidInsRvalue
        icf_wall.addlayer(thickness=OpenStudio.convert(rigidInsThickness,"in","ft").get, conductivity_list=[rigid_k])
    end

    # Exterior Finish
    icf_wall.addlayer(thickness=OpenStudio.convert(finishThickness,"in","ft").get, conductivity_list=[OpenStudio.convert(finishConductivity,"in","ft").get])

    # Exterior Film
    icf_wall.addlayer(thickness=OpenStudio.convert(1.0,"in","ft").get, conductivity_list=[OpenStudio.convert(1.0,"in","ft").get / AirFilms.OutsideR])

    return icf_wall.Rvalue_parallel 
    
  end

  
end

# register the measure to be used by the application
ProcessConstructionsExteriorInsulatedWallsICF.new.registerWithApplication
