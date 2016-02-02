#see the URL below for information on how to write OpenStudio measures
# http://openstudio.nrel.gov/openstudio-measure-writing-guide

#see the URL below for information on using life cycle cost objects in OpenStudio
# http://openstudio.nrel.gov/openstudio-life-cycle-examples

#see the URL below for access to C++ documentation on model objects (click on "model" in the main window to view model objects)
# http://openstudio.nrel.gov/sites/openstudio.nrel.gov/files/nv_data/cpp_documentation_it/model/html/namespaces.html

require "#{File.dirname(__FILE__)}/resources/util"
require "#{File.dirname(__FILE__)}/resources/constants"

#start the measure
class ProcessConstructionsExteriorInsulatedWallsWoodStud < OpenStudio::Ruleset::ModelUserScript
  
  #define the name that a user will see, this method may be deprecated as
  #the display name in PAT comes from the name field in measure.xml
  def name
    return "Set Residential Living Space Wood Stud Wall Construction"
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
    
    # Initialize hashes
    constructions_to_surfaces = {"ExtInsFinWall"=>[]}
    constructions_to_objects = Hash.new      
    
    # Wall between living and outdoors
    living_space_type.spaces.each do |living_space|
      living_space.surfaces.each do |living_surface|
        if living_surface.surfaceType.downcase == "wall" and living_surface.outsideBoundaryCondition.downcase == "outdoors"
          constructions_to_surfaces["ExtInsFinWall"] << living_surface
        end
      end
    end
    
    # Continue if no applicable surfaces
    if constructions_to_surfaces.all? {|construction, surfaces| surfaces.empty?}
      return true
    end 
    
    # Gypsum
    gypsumThickness = runner.getDoubleArgumentValue("userdefinedgypthickness",user_arguments)
    gypsumNumLayers = runner.getDoubleArgumentValue("userdefinedgyplayers",user_arguments)
    gypsumConductivity = Material.Gypsum1_2in.k
    gypsumDensity = Material.Gypsum1_2in.rho
    gypsumSpecificHeat = Material.Gypsum1_2in.Cp
    gypsumThermalAbs = Material.Gypsum1_2in.TAbs
    gypsumSolarAbs = Material.Gypsum1_2in.SAbs
    gypsumVisibleAbs = Material.Gypsum1_2in.VAbs
    gypsumRvalue = (OpenStudio::convert(gypsumThickness,"in","ft").get * gypsumNumLayers / Material.Gypsum1_2in.k)
    
    # Cavity
    wsWallCavityDepth = {"2x4"=>3.5, "2x6"=>5.5, "2x8"=>7.25, "2x10"=>9.25, "2x12"=>11.25, "2x14"=>13.25, "2x16"=>15.25}[runner.getStringArgumentValue("selectedstudsize",user_arguments)]
    wsWallFramingFactor = {"16 in o.c."=>0.25, "24 in o.c."=>0.22}[runner.getStringArgumentValue("selectedspacing",user_arguments)]
    wsWallCavityInsRvalueInstalled = runner.getDoubleArgumentValue("userdefinedinstcavr",user_arguments)
    wsWallInstallGrade = {"I"=>1, "II"=>2, "III"=>3}[runner.getStringArgumentValue("selectedinstallgrade",user_arguments)]
    wsWallCavityInsFillsCavity = runner.getBoolArgumentValue("selectedinsfills",user_arguments)
    
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
    
    # Process the wood stud walls
    sc_thick, sc_cond, sc_dens, sc_sh = _processConstructionsExteriorInsulatedWallsWoodStud(wsWallCavityInsFillsCavity, wsWallCavityInsRvalueInstalled, wsWallInstallGrade, wsWallCavityDepth, wsWallFramingFactor, gypsumThickness, gypsumNumLayers, gypsumRvalue, finishThickness, finishConductivity, finishRvalue, rigidInsThickness, rigidInsRvalue, hasOSB, osbRvalue)

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
    unless constructions_to_surfaces["ExtInsFinWall"].empty?
        extinsfinwall = OpenStudio::Model::Construction.new(materials)
        extinsfinwall.setName("ExtInsFinWall")
        constructions_to_objects["ExtInsFinWall"] = extinsfinwall
    end

    # Apply constructions to surfaces
    constructions_to_surfaces.each do |construction, surfaces|
        surfaces.each do |surface|
            surface.setConstruction(constructions_to_objects[construction])
            runner.registerInfo("Surface '#{surface.name}', of Space Type '#{HelperMethods.get_space_type_from_surface(model, surface.name.to_s, runner)}' and with Surface Type '#{surface.surfaceType}' and Outside Boundary Condition '#{surface.outsideBoundaryCondition}', was assigned Construction '#{construction}'")
        end
    end
    
    # Remove any materials which aren't used in any constructions
    HelperMethods.remove_unused_materials(model, runner)

    return true
 
  end #end the run method

  def _processConstructionsExteriorInsulatedWallsWoodStud(wsWallCavityInsFillsCavity, wsWallCavityInsRvalueInstalled, wsWallInstallGrade, wsWallCavityDepth, wsWallFramingFactor, gypsumThickness, gypsumNumLayers, gypsumRvalue, finishThickness, finishConductivity, finishRvalue, rigidInsThickness, rigidInsRvalue, hasOSB, osbRvalue)
        # Set Furring insulation/air properties 
        if wsWallCavityInsRvalueInstalled == 0
            cavityInsDens = Gas.Air.Cp # lb/ft^3   Assumes that a cavity with an R-value of 0 is an air cavity
            cavityInsSH = Gas.Air.Cp
        else
            cavityInsDens = BaseMaterial.InsulationGenericDensepack.rho
            cavityInsSH = BaseMaterial.InsulationGenericDensepack.Cp
        end
        
        wsGapFactor = Construction.GetWallGapFactor(wsWallInstallGrade, wsWallFramingFactor)
        
        overall_wall_Rvalue = Construction.GetWoodStudWallAssemblyR(wsWallCavityInsFillsCavity, wsWallCavityInsRvalueInstalled, 
                                                                    wsWallInstallGrade, wsWallCavityDepth, wsWallFramingFactor, 
                                                                    "WS", gypsumThickness, gypsumNumLayers, 
                                                                    finishThickness, finishConductivity, 
                                                                    rigidInsThickness, rigidInsRvalue, hasOSB)
        
        # Create layers for modeling
        sc_thick = OpenStudio::convert(wsWallCavityDepth,"in","ft").get
        sc_cond = sc_thick / (overall_wall_Rvalue - (Material.AirFilmVertical.Rvalue + Material.AirFilmOutside.Rvalue + rigidInsRvalue + osbRvalue + finishRvalue + gypsumRvalue))
        sc_dens = wsWallFramingFactor * BaseMaterial.Wood.rho + (1 - wsWallFramingFactor - wsGapFactor) * cavityInsDens + wsGapFactor * Gas.Air.Cp
        sc_sh = (wsWallFramingFactor * BaseMaterial.Wood.Cp * BaseMaterial.Wood.rho + (1 - wsWallFramingFactor - wsGapFactor) * cavityInsSH * cavityInsDens + wsGapFactor * Gas.Air.Cp * Gas.Air.Cp) / sc_dens

        return sc_thick, sc_cond, sc_dens, sc_sh
        
  end
  
end #end the measure

#this allows the measure to be use by the application
ProcessConstructionsExteriorInsulatedWallsWoodStud.new.registerWithApplication