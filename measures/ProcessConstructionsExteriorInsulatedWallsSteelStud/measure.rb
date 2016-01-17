# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/measures/measure_writing_guide/

require "#{File.dirname(__FILE__)}/resources/util"
require "#{File.dirname(__FILE__)}/resources/constants"
require "#{File.dirname(__FILE__)}/resources/weather"

# start the measure
class ProcessConstructionsExteriorInsulatedWallsSteelStud < OpenStudio::Ruleset::ModelUserScript

  # human readable name
  def name
    return "Assign Residential Living Space Steel Stud Wall Construction"
  end

  # human readable description
  def description
    return "This measure assigns a steel stud construction to the living space exterior walls."
  end

  # human readable description of modeling approach
  def modeler_description
    return "Calculates material layer properties of steel stud constructions for the exterior walls adjacent to the living space. Finds surfaces adjacent to the living space and sets applicable constructions."
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
    studsize_display_names = OpenStudio::StringVector.new
    studsize_display_names << "2x4"
    studsize_display_names << "2x6"
    studsize_display_names << "2x8"
    
    #make a string argument for steel stud size of wall cavity
    selected_studsize = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("selectedstudsize", studsize_display_names, true)
    selected_studsize.setDisplayName("Steel Stud: Cavity Depth")
    selected_studsize.setUnits("in")
    selected_studsize.setDescription("Depth of the stud cavity.")
    selected_studsize.setDefaultValue("2x4")
    args << selected_studsize
    
    #make a choice argument for model objects
    spacing_display_names = OpenStudio::StringVector.new
    spacing_display_names << "16 in o.c."
    spacing_display_names << "24 in o.c."
    
    #make a choice argument for steel stud spacing
    selected_spacing = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("selectedspacing", spacing_display_names, true)
    selected_spacing.setDisplayName("Steel Stud: Stud Spacing")
    selected_spacing.setUnits("in")
    selected_spacing.setDescription("The on-center spacing between studs in a wall assembly.")
    selected_spacing.setDefaultValue("16 in o.c.")
    args << selected_spacing    
    
    #make a double argument for nominal R-value of installed cavity insulation
    userdefined_instcavr = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedinstcavr", true)
    userdefined_instcavr.setDisplayName("Steel Stud: Cavity Insulation Installed R-value")
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
    selected_installgrade.setDisplayName("Steel Stud: Cavity Install Grade")
    selected_installgrade.setDescription("5% of the wall is considered missing insulation for Grade 3, 2% for Grade 2, and 0% for Grade 1.")
    selected_installgrade.setDefaultValue("I")
    args << selected_installgrade
    
    #make a bool argument for whether the cavity insulation fills the cavity
    selected_insfills = OpenStudio::Ruleset::OSArgument::makeBoolArgument("selectedinsfills", true)
    selected_insfills.setDisplayName("Steel Stud: Insulation Fills Cavity")
    selected_insfills.setDescription("Specifies whether the cavity insulation completely fills the depth of the wall cavity.")
    selected_insfills.setDefaultValue(true)
    args << selected_insfills
    
    #make a double argument for correction factor
    userdefined_corrfact = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedcorrfact", true)
    userdefined_corrfact.setDisplayName("Steel Stud: Correction Factor")
    userdefined_corrfact.setDescription("The parallel path correction factor.")
    userdefined_corrfact.setDefaultValue(0.46)
    args << userdefined_corrfact

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
    gypsumThickness = runner.getDoubleArgumentValue("userdefinedgypthickness",user_arguments)
    gypsumNumLayers = runner.getDoubleArgumentValue("userdefinedgyplayers",user_arguments)
    gypsumConductivity = Material.GypsumExtWall.k
    gypsumDensity = Material.GypsumExtWall.rho
    gypsumSpecificHeat = Material.GypsumExtWall.Cp
    gypsumThermalAbs = Material.GypsumExtWall.TAbs
    gypsumSolarAbs = Material.GypsumExtWall.SAbs
    gypsumVisibleAbs = Material.GypsumExtWall.VAbs
    gypsumRvalue = (OpenStudio::convert(gypsumThickness,"in","ft").get * gypsumNumLayers / Material.GypsumExtWall.k)
    
    # Cavity
    ssWallCavityDepth = {"2x4"=>3.5, "2x6"=>5.5, "2x8"=>7.25, "2x10"=>9.25, "2x12"=>11.25, "2x14"=>13.25, "2x16"=>15.25}[runner.getStringArgumentValue("selectedstudsize",user_arguments)]   
    ssWallFramingFactor = {"16 in o.c."=>0.25, "24 in o.c."=>0.22}[runner.getStringArgumentValue("selectedspacing",user_arguments)]
    ssWallCavityInsRvalueInstalled = runner.getDoubleArgumentValue("userdefinedinstcavr",user_arguments)
    ssWallInstallGrade = {"I"=>1, "II"=>2, "III"=>3}[runner.getStringArgumentValue("selectedinstallgrade",user_arguments)]
    ssWallCavityInsFillsCavity = runner.getBoolArgumentValue("selectedinsfills",user_arguments)  
    ssWallCorrectionFactor = runner.getDoubleArgumentValue("userdefinedcorrfact",user_arguments)  
    
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
    
    # Process the steel stud walls
    sc_thick, sc_cond, sc_dens, sc_sh = _processConstructionsExteriorInsulatedWallsSteelStud(ssWallCavityInsRvalueInstalled, ssWallInstallGrade, ssWallCavityDepth, ssWallCavityInsFillsCavity, ssWallFramingFactor, ssWallCorrectionFactor, gypsumThickness, gypsumNumLayers, gypsumRvalue, finishThickness, finishConductivity, finishRvalue, rigidInsThickness, rigidInsRvalue, hasOSB, osbRvalue, weather.header.LocalPressure)
    
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
        rigid.setThickness(OpenStudio::convert(rigidInsThickness,"in","m").get)
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
    
    # StudandCavity
    sc = OpenStudio::Model::StandardOpaqueMaterial.new(model)
    sc.setName("StudandCavity")
    sc.setRoughness("Rough")
    sc.setThickness(OpenStudio::convert(sc_thick,"ft","m").get)
    sc.setConductivity(OpenStudio::convert(sc_cond,"Btu/hr*ft*R","W/m*K").get)
    sc.setDensity(OpenStudio::convert(sc_dens,"lb/ft^3","kg/m^3").get)
    sc.setSpecificHeat(OpenStudio::convert(sc_sh,"Btu/lb*R","J/kg*K").get) 
    
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

  end
  
  def _processConstructionsExteriorInsulatedWallsSteelStud(ssWallCavityInsRvalueInstalled, ssWallInstallGrade, ssWallCavityDepth, ssWallCavityInsFillsCavity, ssWallFramingFactor, ssWallCorrectionFactor, gypsumThickness, gypsumNumLayers, gypsumRvalue, finishThickness, finishConductivity, finishRvalue, rigidInsThickness, rigidInsRvalue, hasOSB, osbRvalue, localPressure)
    # Set Furring insulation/air properties
    if ssWallCavityInsRvalueInstalled == 0
        cavityInsDens = Gas.AirInsideDensity(localPressure) # lbm/ft^3   Assumes that a cavity with an R-value of 0 is an air cavity
        cavityInsSH = Gas.Air.Cp
    else
        cavityInsDens = BaseMaterial.InsulationGenericDensepack.rho
        cavityInsSH = BaseMaterial.InsulationGenericDensepack.Cp
    end
        
    wsGapFactor = Construction.GetWallGapFactor(ssWallInstallGrade, ssWallFramingFactor)  

    overall_wall_Rvalue = get_steel_stud_wall_r_assembly(ssWallCavityInsRvalueInstalled, ssWallInstallGrade, ssWallCavityDepth, ssWallCavityInsFillsCavity, ssWallFramingFactor, ssWallCorrectionFactor, gypsumThickness, gypsumNumLayers, finishThickness, finishConductivity, rigidInsThickness, rigidInsRvalue, hasOSB, wsGapFactor)
        
    # Create layers for modeling
    sc_thick = OpenStudio::convert(ssWallCavityDepth,"in","ft").get # ft
    sc_cond = sc_thick / (overall_wall_Rvalue - (AirFilms.VerticalR + AirFilms.OutsideR + rigidInsRvalue + osbRvalue + finishRvalue + gypsumRvalue)) # Btu/hr*ft*F     
    sc_dens = ssWallFramingFactor * BaseMaterial.Wood.rho + (1 - ssWallFramingFactor - wsGapFactor) * cavityInsDens + wsGapFactor * Gas.AirInsideDensity(localPressure) 
    sc_sh = (ssWallFramingFactor * BaseMaterial.Wood.Cp * BaseMaterial.Wood.rho + (1 - ssWallFramingFactor - wsGapFactor) * cavityInsSH * cavityInsDens + wsGapFactor * Gas.Air.Cp * Gas.AirInsideDensity(localPressure)) / sc_dens
        
    return sc_thick, sc_cond, sc_dens, sc_sh
        
  end

  def get_steel_stud_wall_r_assembly(ssWallCavityInsRvalueInstalled, ssWallInstallGrade, ssWallCavityDepth, ssWallCavityInsFillsCavity, ssWallFramingFactor, ssWallCorrectionFactor, gypsumThickness, gypsumNumLayers, finishThickness, finishConductivity, rigidInsThickness, rigidInsRvalue, hasOSB, wsGapFactor)
    # Returns assembly R-value for steel stud wall, including air films.
    
    # Uses Equation 4-1 from 2015 IECC, which includes a correction factor, as an alternative
    # calculation to the parallel path approach.

    mat_plywood1_2in = Material.Plywood1_2in
    
    # Add air gap when insulation thickness < cavity depth
    if not ssWallCavityInsFillsCavity
        ssWallCavityInsRvalueInstalled += Gas.AirGapRvalue
    end
    
    # The cumulative R-value of the wall components along the path of heat transfer,
    # excluding the cavity insulation and steel studs
    r = AirFilms.VerticalR # Interior film
    r += (OpenStudio::convert(gypsumThickness,"in","ft").get * gypsumNumLayers / BaseMaterial.Gypsum.k) # Interior Finish (GWB)
    if hasOSB
        r += mat_plywood1_2in.Rvalue # OSB sheathing
    end
    r += rigidInsRvalue
    r += (OpenStudio::convert(finishThickness,"in","ft").get / OpenStudio::convert(finishConductivity,"in","ft").get) # Exterior Finish
    r += AirFilms.OutsideR # Exterior film
    
    # The effective R-value of the cavity insulation with steel studs
    eR = ssWallCavityInsRvalueInstalled * ssWallCorrectionFactor
    
    return r + 1/((1-wsGapFactor)/eR + wsGapFactor/Gas.AirGapRvalue)
    
  end

  
end

# register the measure to be used by the application
ProcessConstructionsExteriorInsulatedWallsSteelStud.new.registerWithApplication
