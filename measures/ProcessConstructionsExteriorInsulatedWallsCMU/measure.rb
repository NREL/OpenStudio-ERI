# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/measures/measure_writing_guide/

require "#{File.dirname(__FILE__)}/resources/util"
require "#{File.dirname(__FILE__)}/resources/constants"
require "#{File.dirname(__FILE__)}/resources/weather"

# start the measure
class ProcessConstructionsExteriorInsulatedWallsCMU < OpenStudio::Ruleset::ModelUserScript
    
  # human readable name
  def name
    return "Set Residential Living Space CMU Wall Construction"
  end

  # human readable description
  def description
    return "This measure assigns a CMU construction to the living space exterior walls."
  end

  # human readable description of modeling approach
  def modeler_description
    return "Calculates material layer properties of CMU constructions for the exterior walls adjacent to the living space. Finds surfaces adjacent to the living space and sets applicable constructions."
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
    
    #make a double argument for thickness of the cmu block
    userdefined_cmuthickness = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedcmuthickness", true)
    userdefined_cmuthickness.setDisplayName("CMU: CMU Block Thickness")
    userdefined_cmuthickness.setUnits("in")
    userdefined_cmuthickness.setDescription("Thickness of the CMU portion of the wall.")
    userdefined_cmuthickness.setDefaultValue(6.0)
    args << userdefined_cmuthickness
    
    #make a double argument for conductivity of the cmu block
    userdefined_cmuconductivity = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedcmuconductivity", false)
    userdefined_cmuconductivity.setDisplayName("CMU: CMU Conductivity")
    userdefined_cmuconductivity.setUnits("Btu-in/hr-ft^2-R")
    userdefined_cmuconductivity.setDescription("Overall conductivity of the finished CMU block.")
    userdefined_cmuconductivity.setDefaultValue(5.33)
    args << userdefined_cmuconductivity 
    
    #make a double argument for density of the cmu block
    userdefined_cmudensity = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedcmudensity", false)
    userdefined_cmudensity.setDisplayName("CMU: CMU Density")
    userdefined_cmudensity.setUnits("lb/ft^3")
    userdefined_cmudensity.setDescription("The density of the finished CMU block.")
    userdefined_cmudensity.setDefaultValue(119.0)
    args << userdefined_cmudensity      
    
    #make a double argument for framing factor
    userdefined_framingfrac = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedframingfrac", false)
    userdefined_framingfrac.setDisplayName("CMU: Framing Factor")
    userdefined_framingfrac.setUnits("frac")
    userdefined_framingfrac.setDescription("Total fraction of the wall that is framing for windows or doors.")
    userdefined_framingfrac.setDefaultValue(0.076)
    args << userdefined_framingfrac
    
    #make a double argument for furring insulation R-value
    userdefined_furringr = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedfurringr", false)
    userdefined_furringr.setDisplayName("CMU: Furring Insulation R-value")
    userdefined_furringr.setUnits("hr-ft^2-R/Btu")
    userdefined_furringr.setDescription("R-value of the insulation filling the furring cavity.")
    userdefined_furringr.setDefaultValue(0.0)
    args << userdefined_furringr
    
    #make a double argument for furring cavity depth
    userdefined_furringcavdepth = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedfurringcavdepth", false)
    userdefined_furringcavdepth.setDisplayName("CMU: Furring Cavity Depth")
    userdefined_furringcavdepth.setUnits("in")
    userdefined_furringcavdepth.setDescription("The depth of the interior furring cavity.")
    userdefined_furringcavdepth.setDefaultValue(1.0)
    args << userdefined_furringcavdepth 
    
    #make a double argument for furring stud spacing
    userdefined_furringstudspacing = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedfurringstudspacing", false)
    userdefined_furringstudspacing.setDisplayName("CMU: Furring Stud Spacing")
    userdefined_furringstudspacing.setUnits("in")
    userdefined_furringstudspacing.setDescription("Spacing of studs in the furring.")
    userdefined_furringstudspacing.setDefaultValue(24.0)
    args << userdefined_furringstudspacing  
    
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
    
    # Space type
    living_space_type_r = runner.getStringArgumentValue("living_space_type",user_arguments)
    living_space_type = HelperMethods.get_space_type_from_string(model, living_space_type_r, runner)
    if living_space_type.nil?
        return false
    end
        
    # Gypsum
    gypsumThickness = runner.getDoubleArgumentValue("userdefinedgypthickness",user_arguments)
    gypsumNumLayers = runner.getDoubleArgumentValue("userdefinedgyplayers",user_arguments)
    gypsumConductivity = Material.GypsumExtWall.k
    gypsumDensity = Material.GypsumExtWall.rho
    gypsumSpecificHeat = Material.GypsumExtWall.Cp
    gypsumThermalAbs = Material.GypsumExtWall.TAbs
    gypsumSolarAbs = Material.GypsumExtWall.SAbs
    gypsumVisibleAbs = Material.GypsumExtWall.VAbs
    gypsumRvalue = (OpenStudio::convert(gypsumThickness,"in","ft").get * gypsumNumLayers / Material.GypsumExtWall.k)

    # CMU / Furring
    cmuThickness = runner.getDoubleArgumentValue("userdefinedcmuthickness",user_arguments)
    cmuConductivity = runner.getDoubleArgumentValue("userdefinedcmuconductivity",user_arguments)
    cmuDensity = runner.getDoubleArgumentValue("userdefinedcmudensity",user_arguments)
    cmuFramingFactor = runner.getDoubleArgumentValue("userdefinedframingfrac",user_arguments)
    cmuFurringInsRvalue = runner.getDoubleArgumentValue("userdefinedfurringr",user_arguments)
    cmuFurringCavityDepth = runner.getDoubleArgumentValue("userdefinedfurringcavdepth",user_arguments)
    cmuFurringStudSpacing = runner.getDoubleArgumentValue("userdefinedfurringstudspacing",user_arguments)

    # Rigid
    rigidInsThickness = runner.getDoubleArgumentValue("userdefinedrigidinsthickness",user_arguments)
    rigidInsRvalue = runner.getDoubleArgumentValue("userdefinedrigidinsr",user_arguments)
    rigidInsConductivity = OpenStudio::convert(rigidInsThickness,"in","ft").get / rigidInsRvalue
    rigidInsDensity = BaseMaterial.InsulationRigid.rho
    rigidInsSpecificHeat = BaseMaterial.InsulationRigid.Cp 
    hasOSB = runner.getBoolArgumentValue("userdefinedhasosb",user_arguments)
    osbThickness = 0.5
    osbConductivity = Material.Plywood1_2in.k
    osbDensity = Material.Plywood1_2in.rho
    osbSpecificHeat = Material.Plywood1_2in.Cp
    if hasOSB
        osbRvalue = Material.Plywood1_2in.Rvalue
    else
        osbRvalue = 0
    end

    # Exterior Finish
    finishThickness = runner.getDoubleArgumentValue("userdefinedextfinthickness",user_arguments)
    finishRvalue = runner.getDoubleArgumentValue("userdefinedextfinr",user_arguments)
    finishDensity = runner.getDoubleArgumentValue("userdefinedextfindensity",user_arguments)
    finishSpecHeat = runner.getDoubleArgumentValue("userdefinedextfinspecheat",user_arguments)
    finishThermalAbs = runner.getDoubleArgumentValue("userdefinedextfinthermalabs",user_arguments)
    finishSolarAbs = runner.getDoubleArgumentValue("userdefinedextfinabs",user_arguments)    
    finishVisibleAbs = finishSolarAbs
    finishConductivity = finishThickness / finishRvalue

    weather = WeatherProcess.new(model,runner,header_only=true)
    if weather.error?
        return false
    end
    
    # Process the CMU walls
    cmu_cond, cmu_dens, cmu_sh, fu_thick, fu_cond, fu_dens, fu_sh = _processConstructionsExteriorInsulatedWallsCMU(cmuThickness, cmuConductivity, cmuDensity, cmuFramingFactor, cmuFurringCavityDepth, cmuFurringStudSpacing, cmuFurringInsRvalue, gypsumThickness, gypsumNumLayers, gypsumRvalue, finishThickness, finishConductivity, finishRvalue, rigidInsThickness, rigidInsRvalue, hasOSB, osbRvalue, weather.header.LocalPressure)
        
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
        rigid.setThickness(OpenStudio::convert(rigidInsThickness,"in","ft").get)
        rigid.setConductivity(OpenStudio::convert(rigidInsConductivity,"Btu/hr*ft*R","W/m*K").get)
        rigid.setDensity(OpenStudio::convert(rigidInsDensity,"lb/ft^3","kg/m^3").get)
        rigid.setSpecificHeat(OpenStudio::convert(rigidInsSpecificHeat,"Btu/lb*R","J/kg*K").get)
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
    
    # CMU
    cmu = OpenStudio::Model::StandardOpaqueMaterial.new(model)
    cmu.setName("CMU")
    cmu.setRoughness("Rough")
    cmu.setThickness(OpenStudio::convert(cmuThickness,"in","m").get)
    cmu.setConductivity(OpenStudio::convert(cmu_cond,"Btu/hr*ft*R","W/m*K").get)
    cmu.setDensity(OpenStudio::convert(cmu_dens,"lb/ft^3","kg/m^3").get)
    cmu.setSpecificHeat(OpenStudio::convert(cmu_sh,"Btu/lb*R","J/kg*K").get)   
    
    # Furring
    fu = OpenStudio::Model::StandardOpaqueMaterial.new(model)
    fu.setName("Furring")
    fu.setRoughness("Rough")
    fu.setThickness(OpenStudio::convert(fu_thick,"ft","m").get)
    fu.setConductivity(OpenStudio::convert(fu_cond,"Btu/hr*ft*R","W/m*K").get)
    fu.setDensity(OpenStudio::convert(fu_dens,"lb/ft^3","kg/m^3").get)
    fu.setSpecificHeat(OpenStudio::convert(fu_sh,"Btu/lb*R","J/kg*K").get) 
        
    # ExtInsFinWall
    materials = []
    materials << extfin
    if rigidInsRvalue > 0
        materials << rigid
    end
    if hasOSB
        materials << osb
    end
    materials << cmu
    if cmuFurringCavityDepth > 0
        materials << fu
    end
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

  def _processConstructionsExteriorInsulatedWallsCMU(cmuThickness, cmuConductivity, cmuDensity, cmuFramingFactor, cmuFurringCavityDepth, cmuFurringStudSpacing, cmuFurringInsRvalue, gypsumThickness, gypsumNumLayers, gypsumRvalue, finishThickness, finishConductivity, finishRvalue, rigidInsThickness, rigidInsRvalue, hasOSB, osbRvalue, localPressure)
    overall_wall_Rvalue, furring_layer_equiv_Rvalue = get_cmu_wall_r_assembly(cmuThickness, cmuConductivity, cmuDensity, cmuFramingFactor, cmuFurringCavityDepth, cmuFurringStudSpacing, cmuFurringInsRvalue, gypsumThickness, gypsumNumLayers, finishThickness, finishConductivity, rigidInsThickness, rigidInsRvalue, hasOSB)
    
    # Set Furring insulation/air properties
    cmu_cond = (OpenStudio.convert(cmuThickness,"in","ft").get / (overall_wall_Rvalue - (AirFilms.VerticalR + AirFilms.OutsideR + furring_layer_equiv_Rvalue + rigidInsRvalue + osbRvalue + finishRvalue + gypsumRvalue))) # Btu/hr*ft*F
    cmu_dens = (cmuFramingFactor * BaseMaterial.Wood.rho + (1.0 - cmuFramingFactor) * cmuDensity) # lbm/ft^3)
    cmu_sh = (cmuFramingFactor * BaseMaterial.Wood.Cp * BaseMaterial.Wood.rho + (1.0 - cmuFramingFactor) * BaseMaterial.Concrete.Cp * cmuDensity) / cmu_dens # Btu/lbm-F
    
    if cmuFurringCavityDepth != 0
    
        # Add air film coefficients when no insulation
        if cmuFurringInsRvalue.nil? or cmuFurringInsRvalue == 0
            cmuFurringInsRvalue = Gas.AirGapRvalue
        end
    
        if cmuFurringInsRvalue == 0
            furring_ins_dens = Gas.AirInsideDensity(localPressure) # lbm/ft^3   Assumes an empty cavity with air films
            furring_ins_sh = Gas.Air.Cp
        else
            furring_ins_dens = BaseMaterial.InsulationGenericDensepack.rho # lbm/ft^3
            furring_ins_sh = BaseMaterial.InsulationGenericDensepack.Cp
        end
        
        fu_thick = OpenStudio.convert(cmuFurringCavityDepth,"in","ft").get # ft
        fu_cond = fu_thick / furring_layer_equiv_Rvalue # Btu/hr*ft*F
        frac = Material.Stud2x4.width_in / cmuFurringStudSpacing + cmuFramingFactor
        fu_dens = frac * BaseMaterial.Wood.rho + (1.0 - frac) * furring_ins_dens # lbm/ft^3
        fu_sh = (frac * BaseMaterial.Wood.Cp * BaseMaterial.Wood.rho + (1.0 - frac) * furring_ins_sh * furring_ins_dens) / fu_dens # Btu/lbm*F
        
    end
    
    return cmu_cond, cmu_dens, cmu_sh, fu_thick, fu_cond, fu_dens, fu_sh
  
  end

  def get_cmu_wall_r_assembly(cmuThickness, cmuConductivity, cmuDensity, cmuFramingFactor, cmuFurringCavityDepth, cmuFurringStudSpacing, cmuFurringInsRvalue, gypsumThickness, gypsumNumLayers, finishThickness, finishConductivity, rigidInsThickness, rigidInsRvalue, hasOSB)
    # Returns assembly R-value for CMU wall, including air films.
    # Also returns furring layer equivalent R-value.
    
    # Set paths
    if cmuFurringCavityDepth != 0
        # Add air film coefficients when no insulation
        if cmuFurringInsRvalue.nil? or cmuFurringInsRvalue == 0
            cmuFurringInsRvalue = Gas.AirGapRvalue
        end
        
        stud_frac = Material.Stud2x4.width_in / cmuFurringStudSpacing
        cavity_frac = 1.0 - (stud_frac + cmuFramingFactor)
        path_fracs = [cmuFramingFactor, stud_frac, cavity_frac]
        furring_layer_equiv_Rvalue = 1.0 / (cavity_frac / cmuFurringInsRvalue + (1.0 - cavity_frac) / (OpenStudio.convert(cmuFurringCavityDepth,"in","ft").get / BaseMaterial.Wood.k)) # hr*ft^2*F/Btu
    else # No furring:
        path_fracs = [cmuFramingFactor, 1.0 - cmuFramingFactor]
        furring_layer_equiv_Rvalue = 0.0
    end
    
    cmu_wall = Construction.new(path_fracs)
    
    # Interior Film
    cmu_wall.addlayer(thickness=OpenStudio.convert(1.0,"in","ft").get, conductivity_list=[OpenStudio.convert(1.0,"in","ft").get / AirFilms.VerticalR])
    
    # Interior Finish (GWB)
    cmu_wall.addlayer(thickness=OpenStudio.convert(gypsumThickness,"in","ft").get, conductivity_list=[BaseMaterial.Gypsum.k])

    # Furring/Cavity layer
    cmu_layer_conductivity = OpenStudio.convert(cmuConductivity,"in","ft").get # Btu/hr-ft-F
    
    if cmuFurringCavityDepth != 0
        cavity_ins_k = OpenStudio.convert(cmuFurringCavityDepth,"in","ft").get / cmuFurringInsRvalue
        cmu_wall.addlayer(thickness=OpenStudio.convert(cmuFurringCavityDepth,"in","ft").get, conductivity_list=[BaseMaterial.Wood.k, BaseMaterial.Wood.k, cavity_ins_k])
        # CMU layer
        cmu_wall.addlayer(thickness=OpenStudio.convert(cmuThickness,"in","ft").get, conductivity_list=[BaseMaterial.Wood.k, cmu_layer_conductivity, cmu_layer_conductivity])
    else
        cmu_wall.addlayer(thickness=OpenStudio.convert(cmuThickness,"in","ft").get, conductivity_list=[BaseMaterial.Wood.k, cmu_layer_conductivity])     
    end
    
    # OSB sheathing
    if hasOSB
        cmu_wall.addlayer(thickness=nil, conductivity_list=nil, material=Material.Plywood1_2in, material_list=nil)
    end
    
    if rigidInsRvalue > 0
        rigid_k = OpenStudio.convert(rigidInsThickness,"in","ft").get / rigidInsRvalue
        cmu_wall.addlayer(thickness=OpenStudio.convert(rigidInsThickness,"in","ft").get, conductivity_list=[rigid_k])
    end
    
    # Exterior Finish
    cmu_wall.addlayer(thickness=OpenStudio.convert(finishThickness,"in","ft").get, conductivity_list=[OpenStudio.convert(finishConductivity,"in","ft").get])
    
    # Exterior Film
    cmu_wall.addlayer(thickness=OpenStudio.convert(1.0,"in","ft").get, conductivity_list=[OpenStudio.convert(1.0,"in","ft").get / AirFilms.OutsideR])
    
    return cmu_wall.Rvalue_parallel, furring_layer_equiv_Rvalue
    
  end

  
end

# register the measure to be used by the application
ProcessConstructionsExteriorInsulatedWallsCMU.new.registerWithApplication
