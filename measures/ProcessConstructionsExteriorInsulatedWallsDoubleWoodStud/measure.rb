#see the URL below for information on how to write OpenStudio measures
# http://openstudio.nrel.gov/openstudio-measure-writing-guide

#see the URL below for information on using life cycle cost objects in OpenStudio
# http://openstudio.nrel.gov/openstudio-life-cycle-examples

#see the URL below for access to C++ documentation on model objects (click on "model" in the main window to view model objects)
# http://openstudio.nrel.gov/sites/openstudio.nrel.gov/files/nv_data/cpp_documentation_it/model/html/namespaces.html

require "#{File.dirname(__FILE__)}/resources/util"
require "#{File.dirname(__FILE__)}/resources/constants"

#start the measure
class ProcessConstructionsExteriorInsulatedWallsDoubleWoodStud < OpenStudio::Ruleset::ModelUserScript

  #define the name that a user will see, this method may be deprecated as
  #the display name in PAT comes from the name field in measure.xml
  def name
    return "Set Residential Living Space Double Wood Stud Wall Construction"
  end
  
  def description
    return "This measure assigns a double wood stud construction to the living space exterior walls."
  end
  
  def modeler_description
    return "Calculates material layer properties of double wood stud constructions for the exterior walls adjacent to the living space. Finds surfaces adjacent to the living space and sets applicable constructions."
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
	
    #make a string argument for wood stud size of wall cavity
    selected_studdepth = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("selectedstuddepth", studsize_display_names, true)
    selected_studdepth.setDisplayName("Double Wood Stud: Stud Depth")
	selected_studdepth.setUnits("in")
	selected_studdepth.setDescription("Depth of the studs.")
	selected_studdepth.setDefaultValue("2x4")
    args << selected_studdepth
	
    #make a string argument for wood gap size of wall cavity
    userdefined_gapdepth = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedgapdepth", true)
    userdefined_gapdepth.setDisplayName("Double Wood Stud: Gap Depth")
	userdefined_gapdepth.setUnits("in")
	userdefined_gapdepth.setDescription("Depth of the gap between walls.")
	userdefined_gapdepth.setDefaultValue(3.5)
    args << userdefined_gapdepth	
	
    #make a choice argument for model objects
    spacing_display_names = OpenStudio::StringVector.new
    spacing_display_names << "24 in o.c."

	#make a choice argument for wood stud spacing
	selected_spacing = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("selectedspacing", spacing_display_names, true)
	selected_spacing.setDisplayName("Double Wood Stud: Stud Spacing")
	selected_spacing.setUnits("in")
	selected_spacing.setDescription("The on-center spacing between studs in a wall assembly.")
	selected_spacing.setDefaultValue("24 in o.c.")
	args << selected_spacing

    #make a bool argument for stagger of wall cavity
    userdefined_wallstaggered = OpenStudio::Ruleset::OSArgument::makeBoolArgument("userdefinedwallstaggered", true)
    userdefined_wallstaggered.setDisplayName("Double Wood Stud: Staggered Studs")
	userdefined_wallstaggered.setDescription("Indicates that the double studs are aligned in a staggered fashion (as opposed to being center).") 
    userdefined_wallstaggered.setDefaultValue(false)
    args << userdefined_wallstaggered

	#make a double argument for nominal R-value of installed cavity insulation
	userdefined_instcavr = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedinstcavr", true)
	userdefined_instcavr.setDisplayName("Double Wood Stud: Cavity Insulation Nominal R-value")
	userdefined_instcavr.setUnits("hr-ft^2-R/Btu")
	userdefined_instcavr.setDescription("R-value is a measure of insulation's ability to resist heat traveling through it.")
	userdefined_instcavr.setDefaultValue(33.0)
	args << userdefined_instcavr

	#make a choice argument for model objects
	installgrade_display_names = OpenStudio::StringVector.new
	installgrade_display_names << "I"
	installgrade_display_names << "II"
	installgrade_display_names << "III"
	
	#make a choice argument for wall cavity insulation installation grade
	selected_installgrade = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("selectedinstallgrade", installgrade_display_names, true)
	selected_installgrade.setDisplayName("Double Wood Stud: Cavity Install Grade")
	selected_installgrade.setDescription("5% of the wall is considered missing insulation for Grade 3, 2% for Grade 2, and 0% for Grade 1.")
    selected_installgrade.setDefaultValue("I")
	args << selected_installgrade	
	
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
    selected_spacing = runner.getStringArgumentValue("selectedspacing",user_arguments)
    dsWallFramingFactor = {"24 in o.c."=>0.22}[selected_spacing]
    dsWallStudSpacing = {"24 in o.c."=>24.0}[selected_spacing]
    dsWallStudDepth = {"2x4"=>3.5, "2x6"=>5.5, "2x8"=>7.25, "2x10"=>9.25, "2x12"=>11.25, "2x14"=>13.25, "2x16"=>15.25}[runner.getStringArgumentValue("selectedstuddepth",user_arguments)]
	dsWallGapDepth = runner.getDoubleArgumentValue("userdefinedgapdepth",user_arguments)
    dsWallCavityInsRvalue = runner.getDoubleArgumentValue("userdefinedinstcavr",user_arguments)
	dsWallInstallGrade = {"I"=>1, "II"=>2, "III"=>3}[runner.getStringArgumentValue("selectedinstallgrade",user_arguments)]
    dsWallIsStaggered = runner.getBoolArgumentValue("userdefinedwallstaggered",user_arguments)
    
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

    # Process the double wood stud walls
    sc_thick, sc_cond, sc_dens, sc_sh, c_thick, c_cond, c_dens, c_sh = _processConstructionsExteriorInsulatedWallsDoubleStud(dsWallCavityInsRvalue, dsWallStudDepth, dsWallGapDepth, dsWallFramingFactor, dsWallIsStaggered, dsWallInstallGrade, dsWallStudSpacing, gypsumThickness, gypsumNumLayers, gypsumRvalue, finishThickness, finishConductivity, finishRvalue, rigidInsThickness, rigidInsRvalue, hasOSB, osbRvalue)

    # Create the material layers

    # Stud and Cavity
    sc = OpenStudio::Model::StandardOpaqueMaterial.new(model)
    sc.setName("StudandCavity")
    sc.setRoughness("Rough")
    sc.setThickness(OpenStudio::convert(sc_thick,"ft","m").get)
    sc.setConductivity(OpenStudio::convert(sc_cond,"Btu/hr*ft*R","W/m*K").get)
    sc.setDensity(OpenStudio::convert(sc_dens,"lb/ft^3","kg/m^3").get)
    sc.setSpecificHeat(OpenStudio::convert(sc_sh,"Btu/lb*R","J/kg*K").get)

    # Cavity
	if dsWallGapDepth > 0
		c = OpenStudio::Model::StandardOpaqueMaterial.new(model)
		c.setName("Cavity")
		c.setRoughness("Rough")
		c.setThickness(OpenStudio::convert(c_thick,"ft","m").get)
		c.setConductivity(OpenStudio::convert(c_cond,"Btu/hr*ft*R","W/m*K").get)
		c.setDensity(OpenStudio::convert(c_dens,"lb/ft^3","kg/m^3").get)
		c.setSpecificHeat(OpenStudio::convert(c_sh,"Btu/lb*R","J/kg*K").get)
	end

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
	if dsWallGapDepth > 0
      materials << c
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

  def _processConstructionsExteriorInsulatedWallsDoubleStud(dsWallCavityInsRvalue, dsWallStudDepth, dsWallGapDepth, dsWallFramingFactor, dsWallIsStaggered, dsWallInstallGrade, dsWallStudSpacing, gypsumThickness, gypsumNumLayers, gypsumRvalue, finishThickness, finishConductivity, finishRvalue, rigidInsThickness, rigidInsRvalue, hasOSB, osbRvalue)
    dsGapFactor = Construction.GetWallGapFactor(dsWallInstallGrade, dsWallFramingFactor)
	
	overall_wall_Rvalue, dsWallMiscFramingFactor = get_double_stud_wall_r_assembly(dsWallCavityInsRvalue, dsWallStudDepth, dsWallGapDepth, dsWallFramingFactor, dsWallIsStaggered, dsWallInstallGrade, dsWallStudSpacing, gypsumThickness, gypsumNumLayers, finishThickness, finishConductivity, rigidInsThickness, rigidInsRvalue, hasOSB, dsGapFactor)
	
    cavityDepth = 2 * dsWallStudDepth + dsWallGapDepth
	
	if dsWallGapDepth > 0
	  cavity_layer_Rvalue = 1.0 / ((1.0 - dsWallMiscFramingFactor - dsGapFactor) / (dsWallGapDepth / cavityDepth * dsWallCavityInsRvalue) + dsWallMiscFramingFactor / (dsWallGapDepth / BaseMaterial.Wood.k)) # hr*ft^2*F/Btu
      c_thick = OpenStudio::convert(dsWallGapDepth,"in","ft").get # ft
      c_cond = c_thick / cavity_layer_Rvalue # Btu/hr*ft*F
      c_dens = dsWallMiscFramingFactor * BaseMaterial.Wood.rho + (1.0 - dsWallMiscFramingFactor - dsGapFactor) * BaseMaterial.InsulationGenericDensepack.rho # Btu/hr*ft*F
	  c_sh = (dsWallMiscFramingFactor * BaseMaterial.Wood.Cp * BaseMaterial.Wood.rho + (1.0 - dsWallMiscFramingFactor - dsGapFactor) * BaseMaterial.InsulationGenericDensepack.Cp * BaseMaterial.InsulationGenericDensepack.rho + dsGapFactor * Gas.Air.Cp * Gas.Air.Cp) / c_dens # Btu/lbm-F	
	else
	  cavity_layer_Rvalue = 0
	end
	
    sc_thick = OpenStudio::convert(dsWallStudDepth,"in","ft").get # ft
    sc_cond = sc_thick / ((overall_wall_Rvalue - (Material.AirFilmVertical.Rvalue + Material.AirFilmOutside.Rvalue + rigidInsRvalue + cavity_layer_Rvalue + osbRvalue + (finishThickness / finishConductivity) + (OpenStudio::convert(gypsumThickness,"in","ft").get * gypsumNumLayers / BaseMaterial.Gypsum.k))) / 2.0) # Btu/hr*ft*F
    sc_dens = dsWallFramingFactor * BaseMaterial.Wood.rho + (1 - dsWallFramingFactor) * BaseMaterial.InsulationGenericDensepack.rho # lbm/ft^3
    sc_sh = (dsWallFramingFactor * BaseMaterial.Wood.Cp * BaseMaterial.Wood.rho + (1 - dsWallFramingFactor) * BaseMaterial.InsulationGenericDensepack.Cp * BaseMaterial.InsulationGenericDensepack.rho) / sc_dens # Btu/lbm-F

	return sc_thick, sc_cond, sc_dens, sc_sh, c_thick, c_cond, c_dens, c_sh

  end

  def get_double_stud_wall_r_assembly(dsWallCavityInsRvalue, dsWallStudDepth, dsWallGapDepth, dsWallFramingFactor, dsWallIsStaggered, dsWallInstallGrade, dsWallStudSpacing, gypsumThickness, gypsumNumLayers, finishThickness, finishConductivity, rigidInsThickness, rigidInsRvalue, hasOSB, dsGapFactor)
      # Returns assembly R-value for double stud wall, including air films.

      mat_plywood1_2in = Material.Plywood1_2in
      mat_2x = Material.Stud2x(dsWallStudDepth)

      cavityDepth = 2.0 * dsWallStudDepth + dsWallGapDepth
      
      dsWallMiscFramingFactor = (dsWallFramingFactor - mat_2x.width_in / dsWallStudSpacing)

      ins_k = OpenStudio::convert(cavityDepth,"in","ft").get / dsWallCavityInsRvalue # = 1/R_per_foot
      gap_k = OpenStudio::convert(cavityDepth,"in","ft").get / Gas.AirGapRvalue

      if dsWallIsStaggered
        stud_frac = (2.0 * mat_2x.width_in) / dsWallStudSpacing
      else
        stud_frac = (1.0 * mat_2x.width_in) / dsWallStudSpacing
      end

      path_fracs = [dsWallMiscFramingFactor, stud_frac, dsGapFactor, (1.0 - (stud_frac + dsWallMiscFramingFactor - dsGapFactor))] # frame frac, # stud frac, # Cavity frac
      double_stud_wall = Construction.new(path_fracs)

      # Interior Film
      double_stud_wall.addlayer(thickness=OpenStudio::convert(1.0,"in","ft").get, conductivity_list=[OpenStudio::convert(1.0,"in","ft").get / Material.AirFilmVertical.Rvalue])

      # Interior Finish (GWB)
      double_stud_wall.addlayer(thickness=OpenStudio::convert(gypsumThickness,"in","ft").get * gypsumNumLayers, conductivity_list=[BaseMaterial.Gypsum.k])

      # Inner Stud / Cavity Ins
      double_stud_wall.addlayer(thickness=mat_2x.thick, conductivity_list=[BaseMaterial.Wood.k, BaseMaterial.Wood.k, gap_k, ins_k])

      # All cavity layer
      if dsWallGapDepth > 0
        double_stud_wall.addlayer(thickness=OpenStudio::convert(dsWallGapDepth,"in","ft").get, conductivity_list=[BaseMaterial.Wood.k, ins_k, gap_k, ins_k])
      end

      # Outer Stud / Cavity Ins
      if dsWallIsStaggered
        double_stud_wall.addlayer(thickness=mat_2x.thick, conductivity_list=[BaseMaterial.Wood.k, ins_k, gap_k, ins_k])
      else
        double_stud_wall.addlayer(thickness=mat_2x.thick, conductivity_list=[BaseMaterial.Wood.k, BaseMaterial.Wood.k, gap_k, ins_k])
      end

      # OSB sheathing
      if hasOSB
        double_stud_wall.addlayer(thickness=nil, conductivity_list=nil, material=mat_plywood1_2in, material_list=nil)
      end

      # Rigid
      if rigidInsRvalue > 0
        rigid_k = OpenStudio::convert(rigidInsThickness,"in","ft").get / rigidInsRvalue
        double_stud_wall.addlayer(thickness=OpenStudio::convert(rigidInsThickness,"in","ft").get, conductivity_list=[rigid_k])
      end

      # Exterior Finish
      double_stud_wall.addlayer(thickness=OpenStudio::convert(finishThickness,"in","ft").get, conductivity_list=[OpenStudio::convert(finishConductivity,"in","ft").get])

      # Exterior Film
      double_stud_wall.addlayer(thickness=OpenStudio::convert(1.0,"in","ft").get, conductivity_list=[OpenStudio::convert(1.0,"in","ft").get / Material.AirFilmOutside.Rvalue])

      # Get overall wall R-value using parallel paths:
      return double_stud_wall.Rvalue_parallel, dsWallMiscFramingFactor

  end

end #end the measure

#this allows the measure to be use by the application
ProcessConstructionsExteriorInsulatedWallsDoubleWoodStud.new.registerWithApplication