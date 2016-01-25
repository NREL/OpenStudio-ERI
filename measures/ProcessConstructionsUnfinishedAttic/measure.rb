#see the URL below for information on how to write OpenStudio measures
# http://openstudio.nrel.gov/openstudio-measure-writing-guide

#see the URL below for information on using life cycle cost objects in OpenStudio
# http://openstudio.nrel.gov/openstudio-life-cycle-examples

#see the URL below for access to C++ documentation on model objects (click on "model" in the main window to view model objects)
# http://openstudio.nrel.gov/sites/openstudio.nrel.gov/files/nv_data/cpp_documentation_it/model/html/namespaces.html

require "#{File.dirname(__FILE__)}/resources/util"
require "#{File.dirname(__FILE__)}/resources/constants"

#start the measure
class ProcessConstructionsUnfinishedAttic < OpenStudio::Ruleset::ModelUserScript

  #define the name that a user will see, this method may be deprecated as
  #the display name in PAT comes from the name field in measure.xml
  def name
    return "Set Residential Unfinished Attic Constructions"
  end
  
  def description
    return "This measure assigns constructions to the unfinished attic floor and ceiling."
  end
  
  def modeler_description
    return "Calculates material layer properties of constructions for the unfinished attic floor and ceiling. Finds surfaces adjacent to the unfinished attic and sets applicable constructions."
  end    
  
  #define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Ruleset::OSArgumentVector.new

    #make a choice argument for model objects
    uains_display_names = OpenStudio::StringVector.new
    uains_display_names << "Uninsulated"
    uains_display_names << "Ceiling"
    uains_display_names << "Roof"

    #make a choice argument for unfinished attic insulation type
    selected_uains = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("selecteduains", uains_display_names, false)
    selected_uains.setDisplayName("Unfinished Attic: Insulation Type")
    selected_uains.setDescription("The type of insulation.")
    selected_uains.setDefaultValue("Ceiling")
    args << selected_uains

    #make a double argument for ceiling / roof insulation thickness
    userdefined_ceilroofinsthickness = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedceilroofinsthickness", false)
    userdefined_ceilroofinsthickness.setDisplayName("Unfinished Attic: Ceiling/Roof Insulation Thickness")
    userdefined_ceilroofinsthickness.setUnits("in")
    userdefined_ceilroofinsthickness.setDescription("The thickness in inches of insulation required to obtain a certain R-value.")
    userdefined_ceilroofinsthickness.setDefaultValue(8.55)
    args << userdefined_ceilroofinsthickness

    #make a double argument for unfinished attic ceiling / roof insulation R-value
    userdefined_uaceilroofr = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefineduaceilroofr", false)
    userdefined_uaceilroofr.setDisplayName("Unfinished Attic: Ceiling/Roof Insulation Nominal R-value")
    userdefined_uaceilroofr.setUnits("hr-ft^2-R/Btu")
    userdefined_uaceilroofr.setDescription("R-value is a measure of insulation's ability to resist heat traveling through it.")
    userdefined_uaceilroofr.setDefaultValue(30.0)
    args << userdefined_uaceilroofr

    #make a choice argument for model objects
    joistthickness_display_names = OpenStudio::StringVector.new
    joistthickness_display_names << "3.5"

    #make a string argument for wood stud size of wall cavity
    selected_joistthickness = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("selecteduaceiljoistthickness", joistthickness_display_names, false)
    selected_joistthickness.setDisplayName("Unfinished Attic: Ceiling Joist Thickness")
    selected_joistthickness.setDescription("Thickness of joists in the ceiling.")
    selected_joistthickness.setDefaultValue("3.5")
    args << selected_joistthickness

    #make a choice argument for unfinished attic ceiling framing factor
    userdefined_uaceilff = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefineduaceilff", false)
    userdefined_uaceilff.setDisplayName("Unfinished Attic: Ceiling Framing Factor")
    userdefined_uaceilff.setUnits("frac")
    userdefined_uaceilff.setDescription("The framing factor of the ceiling.")
    userdefined_uaceilff.setDefaultValue(0.07)
    args << userdefined_uaceilff

    #make a choice argument for model objects
    framethickness_display_names = OpenStudio::StringVector.new
    framethickness_display_names << "7.25"

    #make a string argument for unfinished attic roof framing factor
    selected_framethickness = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("selecteduaroofframethickness", framethickness_display_names, false)
    selected_framethickness.setDisplayName("Unfinished Attic: Roof Framing Thickness")
    selected_framethickness.setUnits("in")
    selected_framethickness.setDescription("Thickness of roof framing.")
    selected_framethickness.setDefaultValue("7.25")
    args << selected_framethickness

    #make a choice argument for unfinished attic roof framing factor
    userdefined_uaroofff = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefineduaroofff", false)
    userdefined_uaroofff.setDisplayName("Unfinished Attic: Roof Framing Factor")
    userdefined_uaroofff.setUnits("frac")
    userdefined_uaroofff.setDescription("Fraction of roof that is made up of framing elements.")
    userdefined_uaroofff.setDefaultValue(0.07)
    args << userdefined_uaroofff

    #make a double argument for rigid insulation thickness of roof cavity
    userdefined_rigidinsthickness = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedrigidinsthickness", false)
    userdefined_rigidinsthickness.setDisplayName("Unfinished Attic: Roof Continuous Insulation Thickness")
    userdefined_rigidinsthickness.setUnits("in")
    userdefined_rigidinsthickness.setDescription("Thickness of rigid insulation added to the roof.")
    userdefined_rigidinsthickness.setDefaultValue(0)
    args << userdefined_rigidinsthickness

    #make a double argument for rigid insulation R-value of roof cavity
    userdefined_rigidinsr = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedrigidinsr", false)
    userdefined_rigidinsr.setDisplayName("Unfinished Attic: Roof Continuous Insulation Nominal R-value")
    userdefined_rigidinsr.setUnits("hr-ft^2-R/Btu")
    userdefined_rigidinsr.setDescription("The nominal R-value of the continuous insulation.")
    userdefined_rigidinsr.setDefaultValue(0)
    args << userdefined_rigidinsr

    #make a bool argument for radiant barrier of roof cavity
    userdefined_hasradiantbarrier = OpenStudio::Ruleset::OSArgument::makeBoolArgument("userdefinedhasradiantbarrier", false)
    userdefined_hasradiantbarrier.setDisplayName("Has Radiant Barrier")
    userdefined_hasradiantbarrier.setDescription("Layers of reflective material used to reduce heat transfer between the attic roof and the ceiling insulation and ductwork (if present).")
    userdefined_hasradiantbarrier.setDefaultValue(false)
    args << userdefined_hasradiantbarrier

    #make a double argument for thickness of gypsum
    userdefined_gypthickness = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedgypthickness", false)
    userdefined_gypthickness.setDisplayName("Ceiling Mass: Thickness")
    userdefined_gypthickness.setUnits("in")
    userdefined_gypthickness.setDescription("Gypsum layer thickness.")
    userdefined_gypthickness.setDefaultValue(0.5)
    args << userdefined_gypthickness

    #make a double argument for number of gypsum layers
    userdefined_gyplayers = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedgyplayers", false)
    userdefined_gyplayers.setDisplayName("Ceiling Mass: Num Layers")
    userdefined_gyplayers.setUnits("#")
    userdefined_gyplayers.setDescription("Integer number of layers of gypsum.")
    userdefined_gyplayers.setDefaultValue(1)
    args << userdefined_gyplayers

    #make a double argument for roofing material thermal absorptance of unfinished attic
    userdefined_roofmatthermalabs = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedroofmatthermalabs", false)
    userdefined_roofmatthermalabs.setDisplayName("Roof Material: Emissivity.")
    userdefined_roofmatthermalabs.setDescription("Infrared emissivity of the outside surface of the roof.")
    userdefined_roofmatthermalabs.setDefaultValue(0.91)
    args << userdefined_roofmatthermalabs

    #make a double argument for roofing material solar/visible absorptance of unfinished attic
    userdefined_roofmatabs = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedroofmatabs", false)
    userdefined_roofmatabs.setDisplayName("Roof Material: Absorptivity")
    userdefined_roofmatabs.setDescription("The solar radiation absorptance of the outside roof surface, specified as a value between 0 and 1.")
    userdefined_roofmatabs.setDefaultValue(0.85)
    args << userdefined_roofmatabs

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

    #make a choice argument for unfinished attic space type
    space_types = model.getSpaceTypes
    space_type_args = OpenStudio::StringVector.new
    space_types.each do |space_type|
        space_type_args << space_type.name.to_s
    end
    if not space_type_args.include?(Constants.UnfinishedAtticSpaceType)
        space_type_args << Constants.UnfinishedAtticSpaceType
    end
    unfin_attic_space_type = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("unfin_attic_space_type", space_type_args, true)
    unfin_attic_space_type.setDisplayName("Unfinished Attic space type")
    unfin_attic_space_type.setDescription("Select the unfinished attic space type")
    unfin_attic_space_type.setDefaultValue(Constants.UnfinishedAtticSpaceType)
    args << unfin_attic_space_type

    return args
  end #end the arguments method

  #define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)

    #use the built-in error checking
    if not runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

    eavesDepth = 0
    uACeilingInsThickness = 0
    uACeilingInsRvalueNominal = 0
    uARoofInsThickness = 0
    uARoofInsRvalueNominal = 0
    rigidInsThickness = 0
    rigidInsRvalue = 0

    # Space Type
    living_space_type_r = runner.getStringArgumentValue("living_space_type",user_arguments)
    living_space_type = HelperMethods.get_space_type_from_string(model, living_space_type_r, runner)
    if living_space_type.nil?
        return false
    end
    unfin_attic_space_type_r = runner.getStringArgumentValue("unfin_attic_space_type",user_arguments)
    unfin_attic_space_type = HelperMethods.get_space_type_from_string(model, unfin_attic_space_type_r, runner, false)
    if unfin_attic_space_type.nil?
        # If the building has no unfinished attic, no constructions are assigned and we continue by returning True
        return true
    end

    has_applicable_surfaces = false
    
    living_space_type.spaces.each do |living_space|
      living_space.surfaces.each do |living_surface|
        next unless ["roofceiling"].include? living_surface.surfaceType.downcase
        adjacent_surface = living_surface.adjacentSurface
        next unless adjacent_surface.is_initialized
        adjacent_surface = adjacent_surface.get
        adjacent_surface_r = adjacent_surface.name.to_s
        adjacent_space_type_r = HelperMethods.get_space_type_from_surface(model, adjacent_surface_r)
        next unless [unfin_attic_space_type_r].include? adjacent_space_type_r
        has_applicable_surfaces = true
        break
      end   
    end 
    
    unfin_attic_space_type.spaces.each do |unfin_attic_space|
      unfin_attic_space.surfaces.each do |unfin_attic_surface|
        next unless unfin_attic_surface.surfaceType.downcase == "roofceiling" and unfin_attic_surface.outsideBoundaryCondition.downcase == "outdoors"
        has_applicable_surfaces = true
        break
      end   
    end

    unless has_applicable_surfaces
        return true
    end    
    
    # Unfinished Attic Insulation
    selected_uains = runner.getStringArgumentValue("selecteduains",user_arguments)

    # Ceiling / Roof Insulation
    if ["Ceiling", "Roof"].include? selected_uains.to_s
      userdefined_uaceilroofr = runner.getDoubleArgumentValue("userdefineduaceilroofr",user_arguments)
      userdefined_ceilroofinsthickness = runner.getDoubleArgumentValue("userdefinedceilroofinsthickness",user_arguments)
    end

    # Ceiling Joist Thickness
    uACeilingJoistThickness = {"3.5"=>3.5}[runner.getStringArgumentValue("selecteduaceiljoistthickness",user_arguments)]

    # Ceiling Framing Factor
    uACeilingFramingFactor = runner.getDoubleArgumentValue("userdefineduaceilff",user_arguments)
    if not ( uACeilingFramingFactor > 0.0 and uACeilingFramingFactor < 1.0 )
      runner.registerError("Invalid unfinished attic ceiling framing factor")
      return false
    end

    # Roof Framing Thickness
    uARoofFramingThickness = {"7.25"=>7.25}[runner.getStringArgumentValue("selecteduaroofframethickness",user_arguments)]

    # Roof Framing Factor
    uARoofFramingFactor = runner.getDoubleArgumentValue("userdefineduaroofff",user_arguments)
    if not ( uARoofFramingFactor > 0.0 and uARoofFramingFactor < 1.0 )
      runner.registerError("Invalid unfinished attic roof framing factor")
      return false
    end

    # Rigid
    if ["Roof"].include? selected_uains.to_s
      rigidInsThickness = runner.getDoubleArgumentValue("userdefinedrigidinsthickness",user_arguments)
      rigidInsRvalue = runner.getDoubleArgumentValue("userdefinedrigidinsr",user_arguments)
      rigidInsConductivity = OpenStudio::convert(rigidInsThickness,"in","ft").get / rigidInsRvalue
      rigidInsDensity = BaseMaterial.InsulationRigid.rho
      rigidInsSpecificHeat = BaseMaterial.InsulationRigid.Cp
    end

    # Radiant Barrier
    hasRadiantBarrier = runner.getBoolArgumentValue("userdefinedhasradiantbarrier",user_arguments)

    # Gypsum
    gypsumThickness = runner.getDoubleArgumentValue("userdefinedgypthickness",user_arguments)
    gypsumNumLayers = runner.getDoubleArgumentValue("userdefinedgyplayers",user_arguments)
    gypsumConductivity = Material.GypsumCeiling.k
    gypsumDensity = Material.GypsumCeiling.rho
    gypsumSpecificHeat = Material.GypsumCeiling.Cp
    gypsumThermalAbs = Material.GypsumCeiling.TAbs
    gypsumSolarAbs = Material.GypsumCeiling.SAbs
    gypsumVisibleAbs = Material.GypsumCeiling.VAbs
    gypsumRvalue = (OpenStudio::convert(gypsumThickness,"in","ft").get * gypsumNumLayers / Material.GypsumCeiling.k)

    # Roofing Material
    roofMatEmissivity = runner.getDoubleArgumentValue("userdefinedroofmatthermalabs",user_arguments)
    roofMatAbsorptivity = runner.getDoubleArgumentValue("userdefinedroofmatabs",user_arguments)

    # Insulation
    if selected_uains.to_s == "Ceiling"
      uACeilingInsThickness = userdefined_ceilroofinsthickness
      uACeilingInsRvalueNominal = userdefined_uaceilroofr
    elsif selected_uains.to_s == "Roof"
      uARoofInsThickness = userdefined_ceilroofinsthickness
      uARoofInsRvalueNominal = userdefined_uaceilroofr
    end

    highest_roof_pitch = 26.565 # FIXME: Currently hardcoded
    film_roof_R = AirFilms.RoofR(highest_roof_pitch)
    film_roof_radiant_barrier_R = AirFilms.RoofRadiantBarrierR(highest_roof_pitch)

    # Process the unfinished attic ceiling and roof
    ceiling_ins_above_dens, ceiling_ins_above_sh, ceiling_joist_ins_cond, ceiling_joist_ins_dens, ceiling_joist_ins_sh, uACeilingInsThickness_Rev, uACeilingInsRvalueNominal_Rev = _processConstructionsUnfinishedAtticCeiling(uACeilingInsThickness, uARoofFramingThickness, uACeilingFramingFactor, uACeilingInsRvalueNominal, uACeilingJoistThickness, rigidInsThickness, rigidInsRvalue, uARoofFramingFactor, uARoofInsThickness, uARoofInsRvalueNominal, eavesDepth, gypsumThickness, gypsumNumLayers, gypsumRvalue)
    roof_rigid_thick, roof_rigid_cond, roof_rigid_dens, roof_rigid_sh, roof_ins_thick, roof_ins_cond, roof_ins_dens, roof_ins_sh = _processConstructionsUnfinishedAtticRoof(rigidInsThickness, rigidInsRvalue, uARoofInsRvalueNominal, uARoofFramingFactor, uARoofInsThickness, uARoofFramingThickness, hasRadiantBarrier, film_roof_R, film_roof_radiant_barrier_R)

    # UAAdditionalCeilingIns
    if not (uACeilingInsRvalueNominal == 0 or uACeilingInsThickness_Rev == 0)
      if uACeilingInsThickness_Rev >= uACeilingJoistThickness
        if uACeilingInsThickness_Rev > uACeilingJoistThickness
          uaaci = OpenStudio::Model::StandardOpaqueMaterial.new(model)
          uaaci.setName("UAAdditionalCeilingIns")
          uaaci.setRoughness("Rough")
          uaaci.setThickness(OpenStudio::convert(uACeilingInsThickness_Rev - uACeilingJoistThickness,"in","m").get)
          uaaci.setConductivity(OpenStudio::convert(uACeilingInsThickness_Rev,"Btu*in/hr*ft^2*R","W/m*K").get / uACeilingInsRvalueNominal_Rev)
          uaaci.setDensity(OpenStudio::convert(ceiling_ins_above_dens,"lb/ft^3","kg/m^3").get)
          uaaci.setSpecificHeat(OpenStudio::convert(ceiling_ins_above_sh,"Btu/lb*R","J/kg*K").get)
        end
      end
    end

    # Gypsum
    gypsum = OpenStudio::Model::StandardOpaqueMaterial.new(model)
    gypsum.setName("GypsumBoard-Ceiling")
    gypsum.setRoughness("Rough")
    gypsum.setThickness(OpenStudio::convert(gypsumThickness,"in","m").get)
    gypsum.setConductivity(OpenStudio::convert(gypsumConductivity,"Btu/hr*ft*R","W/m*K").get)
    gypsum.setDensity(OpenStudio::convert(gypsumDensity,"lb/ft^3","kg/m^3").get)
    gypsum.setSpecificHeat(OpenStudio::convert(gypsumSpecificHeat,"Btu/lb*R","J/kg*K").get)
    gypsum.setThermalAbsorptance(gypsumThermalAbs)
    gypsum.setSolarAbsorptance(gypsumSolarAbs)
    gypsum.setVisibleAbsorptance(gypsumVisibleAbs)

    # FinInsUnfinUAFloor
    materials = []
    (0...gypsumNumLayers).to_a.each do |i|
      materials << gypsum
    end 

    # UATrussandIns
    if uACeilingInsRvalueNominal_Rev != 0 and uACeilingInsThickness_Rev != 0
      uatai = OpenStudio::Model::StandardOpaqueMaterial.new(model)
      uatai.setName("UATrussandIns")
      uatai.setRoughness("Rough")
      uatai.setThickness(OpenStudio::convert(uACeilingJoistThickness,"in","m").get)
      uatai.setConductivity(OpenStudio::convert(ceiling_joist_ins_cond,"Btu/hr*ft*R","W/m*K").get)
      uatai.setDensity(OpenStudio::convert(ceiling_joist_ins_dens,"lb/ft^3","kg/m^3").get)
      uatai.setSpecificHeat(OpenStudio::convert(ceiling_joist_ins_sh,"Btu/lb*R","J/kg*K").get)
      materials << uatai
      if uACeilingInsThickness_Rev > uACeilingJoistThickness
        materials << uaaci
      end
    else
      # Without insulation, we run the risk of CTF errors ("Construction too thin or too light")
      # We add a layer here to prevent that error.
      ctf = OpenStudio::Model::StandardOpaqueMaterial.new(model)
      ctf.setName("AddforCTFCalc")
      ctf.setRoughness("Rough")
      ctf.setThickness(OpenStudio::convert(0.75,"in","m").get)
      ctf.setConductivity(OpenStudio::convert(BaseMaterial.Wood.k,"Btu/hr*ft*R","W/m*K").get)
      ctf.setDensity(OpenStudio::convert(BaseMaterial.Wood.rho,"lb/ft^3","kg/m^3").get)
      ctf.setSpecificHeat(OpenStudio::convert(BaseMaterial.Wood.Cp,"Btu/lb*R","J/kg*K").get)
      materials << ctf
    end
    fininsunfinuafloor = OpenStudio::Model::Construction.new(materials)
    fininsunfinuafloor.setName("FinInsUnfinUAFloor")    

    # RevFinInsUnfinUAFloor
    revfininsunfinuafloor = fininsunfinuafloor.reverseConstruction
    revfininsunfinuafloor.setName("RevFinInsUnfinUAFloor")

    # RoofingMaterial
    mat_roof_mat = Material.RoofMaterial(roofMatEmissivity, roofMatAbsorptivity)
    roofmat = OpenStudio::Model::StandardOpaqueMaterial.new(model)
    roofmat.setName("RoofingMaterial")
    roofmat.setRoughness("Rough")
    roofmat.setThickness(OpenStudio::convert(mat_roof_mat.thick,"ft","m").get)
    roofmat.setConductivity(OpenStudio::convert(mat_roof_mat.k,"Btu/hr*ft*R","W/m*K").get)
    roofmat.setDensity(OpenStudio::convert(mat_roof_mat.rho,"lb/ft^3","kg/m^3").get)
    roofmat.setSpecificHeat(OpenStudio::convert(mat_roof_mat.Cp,"Btu/lb*R","J/kg*K").get)
    roofmat.setThermalAbsorptance(mat_roof_mat.TAbs)
    roofmat.setSolarAbsorptance(mat_roof_mat.SAbs)
    roofmat.setVisibleAbsorptance(mat_roof_mat.VAbs)

    # Plywood-3_4in
    ply3_4 = OpenStudio::Model::StandardOpaqueMaterial.new(model)
    ply3_4.setName("Plywood-3_4in")
    ply3_4.setRoughness("Rough")
    ply3_4.setThickness(OpenStudio::convert(Material.Plywood3_4in.thick,"ft","m").get)
    ply3_4.setConductivity(OpenStudio::convert(Material.Plywood3_4in.k,"Btu/hr*ft*R","W/m*K").get)
    ply3_4.setDensity(OpenStudio::convert(Material.Plywood3_4in.rho,"lb/ft^3","kg/m^3").get)
    ply3_4.setSpecificHeat(OpenStudio::convert(Material.Plywood3_4in.Cp,"Btu/lb*R","J/kg*K").get)

    # RadiantBarrier
    radbar = OpenStudio::Model::StandardOpaqueMaterial.new(model)
    radbar.setName("RadiantBarrier")
    radbar.setRoughness("Rough")
    radbar.setThickness(OpenStudio::convert(Material.RadiantBarrier.thick,"ft","m").get)
    radbar.setConductivity(OpenStudio::convert(Material.RadiantBarrier.k,"Btu/hr*ft*R","W/m*K").get)
    radbar.setDensity(OpenStudio::convert(Material.RadiantBarrier.rho,"lb/ft^3","kg/m^3").get)
    radbar.setSpecificHeat(OpenStudio::convert(Material.RadiantBarrier.Cp,"Btu/lb*R","J/kg*K").get)
    radbar.setThermalAbsorptance(Material.RadiantBarrier.TAbs)
    radbar.setSolarAbsorptance(Material.RadiantBarrier.SAbs)
    radbar.setVisibleAbsorptance(Material.RadiantBarrier.VAbs)

    # UARigidRoofIns
    if rigidInsThickness > 0
      uarri = OpenStudio::Model::StandardOpaqueMaterial.new(model)
      uarri.setName("UARigidRoofIns")
      uarri.setRoughness("Rough")
      uarri.setThickness(OpenStudio::convert(roof_rigid_thick,"ft","m").get)
      uarri.setConductivity(OpenStudio::convert(roof_rigid_cond,"Btu/hr*ft*R","W/m*K").get)
      uarri.setDensity(OpenStudio::convert(roof_rigid_dens,"lb/ft^3","kg/m^3").get)
      uarri.setSpecificHeat(OpenStudio::convert(roof_rigid_sh,"Btu/lb*R","J/kg*K").get)
    end

    # UARoofIns
    uari = OpenStudio::Model::StandardOpaqueMaterial.new(model)
    uari.setName("UARoofIns")
    uari.setRoughness("Rough")
    uari.setThickness(OpenStudio::convert(roof_ins_thick,"ft","m").get)
    uari.setConductivity(OpenStudio::convert(roof_ins_cond,"Btu/hr*ft*R","W/m*K").get)
    uari.setDensity(OpenStudio::convert(roof_ins_dens,"lb/ft^3","kg/m^3").get)
    uari.setSpecificHeat(OpenStudio::convert(roof_ins_sh,"Btu/lb*R","J/kg*K").get)

    # UnfinInsExtRoof
    materials = []
    materials << roofmat
    materials << ply3_4
    if rigidInsThickness > 0
      materials << uarri
      materials << ply3_4
    end
    materials << uari
    if hasRadiantBarrier
      materials << radbar
    end
    unfininsextroof = OpenStudio::Model::Construction.new(materials)
    unfininsextroof.setName("UnfinInsExtRoof")  

    living_space_type.spaces.each do |living_space|
      living_space.surfaces.each do |living_surface|
        next unless ["roofceiling"].include? living_surface.surfaceType.downcase
        adjacent_surface = living_surface.adjacentSurface
        next unless adjacent_surface.is_initialized
        adjacent_surface = adjacent_surface.get
        adjacent_surface_r = adjacent_surface.name.to_s
        adjacent_space_type_r = HelperMethods.get_space_type_from_surface(model, adjacent_surface_r)
        next unless [unfin_attic_space_type_r].include? adjacent_space_type_r
        living_surface.setConstruction(revfininsunfinuafloor)
        runner.registerInfo("Surface '#{living_surface.name}', of Space Type '#{living_space_type_r}' and with Surface Type '#{living_surface.surfaceType}' and Outside Boundary Condition '#{living_surface.outsideBoundaryCondition}', was assigned Construction '#{revfininsunfinuafloor.name}'")
        adjacent_surface.setConstruction(fininsunfinuafloor)        
        runner.registerInfo("Surface '#{adjacent_surface.name}', of Space Type '#{adjacent_space_type_r}' and with Surface Type '#{adjacent_surface.surfaceType}' and Outside Boundary Condition '#{adjacent_surface.outsideBoundaryCondition}', was assigned Construction '#{fininsunfinuafloor.name}'")
      end   
    end 
    
    unfin_attic_space_type.spaces.each do |unfin_attic_space|
      unfin_attic_space.surfaces.each do |unfin_attic_surface|
        next unless unfin_attic_surface.surfaceType.downcase == "roofceiling" and unfin_attic_surface.outsideBoundaryCondition.downcase == "outdoors"
        unfin_attic_surface.setConstruction(unfininsextroof)
        runner.registerInfo("Surface '#{unfin_attic_surface.name}', of Space Type '#{unfin_attic_space_type_r}' and with Surface Type '#{unfin_attic_surface.surfaceType}' and Outside Boundary Condition '#{unfin_attic_surface.outsideBoundaryCondition}', was assigned Construction '#{unfininsextroof.name}'")      
      end   
    end 

    return true
 
  end #end the run method

  def _processConstructionsUnfinishedAtticCeiling(uACeilingInsThickness, uARoofFramingThickness, uACeilingFramingFactor, uACeilingInsRvalueNominal, uACeilingJoistThickness, uARoofContInsThickness, uARoofContInsRvalue, uARoofFramingFactor, uARoofInsThickness, uARoofInsRvalueNominal, eavesDepth, gypsumThickness, gypsumNumLayers, gypsumRvalue)
    ceiling_ins_above_dens = nil
    ceiling_ins_above_sh = nil
    ceiling_joist_ins_cond = nil
    ceiling_joist_ins_dens = nil
    ceiling_joist_ins_sh = nil

    uACeilingInsThickness_Rev = get_unfinished_attic_perimeter_insulation_derating(uACeilingInsThickness, uACeilingFramingFactor, uARoofFramingThickness, geometry="temp", eavesDepth)

    # Set properties of ceilings below unfinished attics.

    # If there is ceiling insulation
    if not (uACeilingInsRvalueNominal == 0 or uACeilingInsThickness_Rev == 0)

      uA_ceiling_overall_ins_Rvalue, uACeilingInsRvalueNominal_Rev = get_unfinished_attic_ceiling_r_assembly(uACeilingInsThickness, uACeilingFramingFactor, uACeilingInsRvalueNominal, uACeilingJoistThickness, gypsumThickness, gypsumNumLayers, uACeilingInsThickness_Rev)

      # If the ceiling insulation thickness is greater than the joist thickness
      if uACeilingInsThickness_Rev >= uACeilingJoistThickness

        # Define a layer equivalent to the thickness of the joists,
        # including both heat flow paths (joist and insulation in parallel).
        uA_ceiling_joist_ins_Rvalue = (uA_ceiling_overall_ins_Rvalue - gypsumRvalue - 2.0 * AirFilms.FloorAverageR - uACeilingInsRvalueNominal_Rev + uACeilingInsRvalueNominal_Rev * uACeilingJoistThickness / uACeilingInsThickness_Rev) # Btu/hr*ft^2*F
        ceiling_joist_ins_cond = (OpenStudio::convert(uACeilingJoistThickness,"in","ft").get / uA_ceiling_joist_ins_Rvalue) # Btu/hr*ft*F
        ceiling_joist_ins_dens = uACeilingFramingFactor * BaseMaterial.Wood.rho + (1 - uACeilingFramingFactor) * BaseMaterial.InsulationGenericLoosefill.rho # lbm/ft^3
        ceiling_joist_ins_sh = (uACeilingFramingFactor * BaseMaterial.Wood.Cp * BaseMaterial.Wood.rho + (1 - uACeilingFramingFactor) * BaseMaterial.InsulationGenericLoosefill.Cp * BaseMaterial.InsulationGenericLoosefill.rho) / ceiling_joist_ins_dens # lbm/ft^3

        # If there is additional insulation, above the rafter height,
        # these inputs are used for defining an additional layer.
        if uACeilingInsThickness_Rev > uACeilingJoistThickness

          ceiling_ins_above_dens = BaseMaterial.InsulationGenericLoosefill.rho # lbm/ft^3
          ceiling_ins_above_sh = BaseMaterial.InsulationGenericLoosefill.Cp # Btu/lbm*F

        # Else the joist thickness is greater than the ceiling insulation thickness
        else
          # Define a layer equivalent to the thickness of the joists,
          # including both heat flow paths (joists and insulation in parallel).
          ceiling_joist_ins_cond = (OpenStudio::convert(uACeilingJoistThickness,"in","ft").get / (uA_ceiling_overall_ins_Rvalue - gypsumRvalue - 2.0 * AirFilms.FloorAverageR)) # Btu/hr*ft*F
          ceiling_joist_ins_dens = OpenStudio::convert(uACeilingJoistThickness,"in","ft").get / uACeilingJoistThickness * (uACeilingFramingFactor * BaseMaterial.Wood.rho + (1 - uACeilingFramingFactor) * BaseMaterial.InsulationGenericLoosefill.rho) + (1 - OpenStudio::convert(uACeilingJoistThickness,"in","ft").get / uACeilingJoistThickness) * Gas.Air.Cp # lbm/ft^3
          ceiling_joist_ins_sh = (OpenStudio::convert(uACeilingJoistThickness,"in","ft").get / uACeilingJoistThickness * (uACeilingFramingFactor * BaseMaterial.Wood.Cp * BaseMaterial.Wood.rho + (1 - uACeilingFramingFactor) * BaseMaterial.InsulationGenericLoosefill.Cp * BaseMaterial.InsulationGenericLoosefill.rho) + (1 - OpenStudio::convert(uACeilingJoistThickness,"in","ft").get / uACeilingJoistThickness) * Gas.Air.Cp * Gas.Air.Cp) / ceiling_joist_ins_dens # Btu/lbm*F
          
        end

      end

    else

      uACeilingInsRvalueNominal_Rev = 0

    end
    return ceiling_ins_above_dens, ceiling_ins_above_sh, ceiling_joist_ins_cond, ceiling_joist_ins_dens, ceiling_joist_ins_sh, uACeilingInsThickness_Rev, uACeilingInsRvalueNominal_Rev

  end
  
  def _processConstructionsUnfinishedAtticRoof(uARoofContInsThickness, uARoofContInsRvalue, uARoofInsRvalueNominal, uARoofFramingFactor, uARoofInsThickness, uARoofFramingThickness, hasRadiantBarrier, film_roof_R, film_roof_radiant_barrier_R)

    roof_rigid_thick = nil
    roof_rigid_cond = nil
    roof_rigid_dens = nil
    roof_rigid_sh = nil

    uA_roof_overall_ins_Rvalue, roof_ins_thick = get_unfinished_attic_roof_r_assembly(uARoofFramingFactor, uARoofInsThickness, uARoofFramingThickness, uARoofInsRvalueNominal, uARoofContInsThickness, uARoofContInsRvalue, hasRadiantBarrier, film_roof_R)

    if uARoofContInsThickness > 0
      uA_roof_overall_ins_Rvalue = (uA_roof_overall_ins_Rvalue - film_roof_R - AirFilms.OutsideR - 2.0 * Material.Plywood3_4in.Rvalue - uARoofContInsRvalue) # hr*ft^2*F/Btu

      roof_rigid_thick = OpenStudio::convert(uUARoofContInsThickness,"in","ft").get
      roof_rigid_cond = roof_rigid_thick / uARoofContInsRvalue # Btu/hr*ft*F
      roof_rigid_dens = BaseMaterial.InsulationRigid.rho # lbm/ft^3
      roof_rigid_sh = BaseMaterial.InsulationRigid.Cp # Btu/lbm*F

    else

      uA_roof_overall_ins_Rvalue = (uA_roof_overall_ins_Rvalue - film_roof_R - AirFilms.OutsideR - Material.Plywood3_4in.Rvalue) # hr*ft^2*F/Btu
      
    end

    roof_ins_cond = roof_ins_thick / uA_roof_overall_ins_Rvalue # Btu/hr*ft*F

    if uARoofInsRvalueNominal == 0
      roof_ins_dens = uARoofFramingFactor * BaseMaterial.Wood.rho + (1 - uARoofFramingFactor) * Gas.Air.Cp # lbm/ft^3
      roof_ins_sh = (uARoofFramingFactor * BaseMaterial.Wood.Cp * BaseMaterial.Wood.rho + (1 - uARoofFramingFactor) * Gas.Air.Cp * Gas.Air.Cp) / roof_ins_dens # Btu/lb*F
    else
      roof_ins_dens = uARoofFramingFactor * BaseMaterial.Wood.rho + (1 - uARoofFramingFactor) * BaseMaterial.InsulationGenericDensepack.rho # lbm/ft^3
      roof_ins_sh = (uARoofFramingFactor * BaseMaterial.Wood.Cp * BaseMaterial.Wood.rho + (1 - uARoofFramingFactor) * BaseMaterial.InsulationGenericDensepack.Cp * BaseMaterial.InsulationGenericDensepack.rho) / roof_ins_dens # Btu/lb*F
    end

    # Set UA roof film
    if hasRadiantBarrier
      uA_roof_film = film_roof_radiant_barrier_R
    else
      uA_roof_film = film_roof_R
    end

    return roof_rigid_thick, roof_rigid_cond, roof_rigid_dens, roof_rigid_sh, roof_ins_thick, roof_ins_cond, roof_ins_dens, roof_ins_sh

  end
  
  def get_unfinished_attic_ceiling_r_assembly(uACeilingInsThickness, uACeilingFramingFactor, uACeilingInsRvalueNominal, uACeilingJoistThickness, gypsumThickness, gypsumNumLayers, uACeilingInsThickness_Rev=nil)
      # Returns assembly R-value for unfinished attic ceiling, including air films.

      if uACeilingInsThickness_Rev.nil?
        # No perimeter taper effect:
        uACeilingInsThickness_Rev = uACeilingInsThickness
      end

      path_fracs = [uACeilingFramingFactor, 1 - uACeilingFramingFactor]

      attic_floor = Construction.new(path_fracs)

      # Interior Film
      attic_floor.addlayer(thickness=OpenStudio::convert(1,"in","ft").get, conductivity_list=[OpenStudio::convert(1,"in","ft").get / AirFilms.FloorAverageR])

      # Interior Finish (GWB)
      attic_floor.addlayer(thickness=OpenStudio::convert(gypsumThickness,"in","ft").get * gypsumNumLayers, conductivity_list=[BaseMaterial.Gypsum.k])

      if uACeilingInsThickness == 0
        uACeilingInsRvalueNominal_Rev = uACeilingInsRvalueNominal
      else
        uACeilingInsRvalueNominal_Rev = [uACeilingInsRvalueNominal * uACeilingInsThickness_Rev / uACeilingInsThickness, 0.0001].max
      end

      # If the ceiling insulation thickness is greater than the joist thickness
      if uACeilingInsThickness_Rev >= uACeilingJoistThickness

        # Stud / Cavity Ins
        attic_floor.addlayer(thickness=OpenStudio::convert(uACeilingJoistThickness,"in","ft").get, conductivity_list=[BaseMaterial.Wood.k, OpenStudio::convert(uACeilingInsThickness_Rev,"in","ft").get / uACeilingInsRvalueNominal_Rev])

        # If there is additional insulation, above the rafter height,
        # these inputs are used for defining an additional layer.after() do

        if uACeilingInsThickness_Rev > uACeilingJoistThickness

          uA_ceiling_ins_above_thickness = OpenStudio::convert(uACeilingInsThickness_Rev - uACeilingJoistThickness,"in","ft").get # ft

          attic_floor.addlayer(thickness=uA_ceiling_ins_above_thickness, conductivity_list=[OpenStudio::convert(uACeilingInsThickness_Rev,"in","ft").get / uACeilingInsRvalueNominal_Rev])

        # Else the joist thickness is greater than the ceiling insulation thickness
        else
          # Stud / Cavity Ins - Insulation layer made thicker and more conductive
          uA_ceiling_joist_ins_thickness = OpenStudio::convert(uACeilingJoistThickness,"in","ft").get # ft
          if uACeilingInsRvalueNominal_Rev == 0
            cond_insul = 99999
          else
            cond_insul = uA_ceiling_joist_ins_thickness / uACeilingInsRvalueNominal_Rev
          end
          attic_floor.addlayer(thickness=uA_ceiling_joist_ins_thickness, conductivity_list=[BaseMaterial.Wood.k, cond_insul])
        end

      end

      # Exterior Film
      attic_floor.addlayer(thickness=OpenStudio::convert(1.0,"in","ft").get, conductivity_list=[OpenStudio::convert(1.0,"in","ft").get / AirFilms.FloorAverageR])

      return attic_floor.Rvalue_parallel, uACeilingInsRvalueNominal_Rev

  end

  def get_unfinished_attic_roof_r_assembly(uARoofFramingFactor, uARoofInsThickness, uARoofFramingThickness, uARoofInsRvalueNominal, uARoofContInsThickness, uARoofContInsRvalue, hasRadiantBarrier, film_roof)
      # Returns assembly R-value for unfinished attic roof, including air films.
      # Also returns roof insulation thickness.

      path_fracs = [uARoofFramingFactor, 1 - uARoofFramingFactor]

      roof_const = Construction.new(path_fracs)

      # Interior Film
      roof_const.addlayer(thickness=OpenStudio::convert(1.0,"in","ft").get, conductivity_list=[OpenStudio::convert(1.0,"in","ft").get / film_roof])

      uA_roof_ins_thickness = OpenStudio::convert([uARoofInsThickness, uARoofFramingThickness].max,"in","ft").get

      # Stud/cavity layer
      if uARoofInsRvalueNominal == 0
        if hasRadiantBarrier
          cavity_k = OpenStudio::convert(uARoofFramingThickness,"in","ft").get / Gas.AirGapRvalue
        else
          cavity_k = 1000000000
        end
      else
        cavity_k = OpenStudio::convert(uARoofInsThickness,"in","ft").get / uARoofInsRvalueNominal
        if uARoofInsThickness < uARoofFramingThickness
          cavity_k = cavity_k * uARoofFramingThickness / uARoofInsThickness
        end
      end

      if uARoofInsThickness > uARoofFramingThickness and uARoofFramingThickness > 0
        wood_k = BaseMaterial.Wood.k * uARoofInsThickness / uARoofFramingThickness
      else
        wood_k = BaseMaterial.Wood.k
      end
      roof_const.addlayer(thickness=uA_roof_ins_thickness, conductivity_list=[wood_k, cavity_k])

      # Sheathing
      roof_const.addlayer(thickness=nil, conductivity_list=nil, material=Material.Plywood3_4in, material_list=nil)

      # Rigid
      if uARoofContInsThickness > 0
        roof_const.addlayer(thickness=OpenStudio::convert(uARoofContInsThickness,"in","ft").get, conductivity_list=[OpenStudio::convert(uARoofContInsThickness,"in","ft").get / uARoofContInsRvalue])
        # More sheathing
        roof_const.addlayer(thickness=nil, conductivity_list=nil, material=Material.Plywood3_4in, material_list=nil)
      end

      # Exterior Film
      roof_const.addlayer(thickness=OpenStudio::convert(1.0,"in","ft").get, conductivity_list=[OpenStudio::convert(1.0,"in","ft").get / AirFilms.OutsideR])

      return roof_const.Rvalue_parallel, uA_roof_ins_thickness

  end

  def get_unfinished_attic_perimeter_insulation_derating(uACeilingInsThickness, uACeilingFramingFactor, uARoofFramingThickness, geometry, eaves_depth)

      if uACeilingInsThickness == 0
        return uACeilingInsThickness
      end

      spaceArea_Rev_UAtc = 0
      windBaffleClearance = 2 # Minimum 2" wind baffle clearance

      if uARoofFramingThickness < 10
        birdMouthDepth = 0
      else
        birdMouthDepth = 1.5 # inches
      end
      
      #FIXME: Lots of hard-coded stuff here.

      #(2...@model.getBuildingStorys.length + 1).to_a.each do |i|
      # temp
      (2..2).to_a.each do |i|
      #
        spaceArea_UAtc = 0
        rfEdgeW_UAtc = 0
        rfEdgeMinH_UAtc = 0
        rfPerimeter_UAtc = 0
        spaceArea_UAtc_Perim = 0
        # index_num = story_num - 1

        #rfTilt = geometry.roof_pitch.item[index_num]
        # temp
        rfTilt = 26.565052
        #

        # if geometry.roof_structure.item[index_num].nil?
        #   next
        # end

        #geometry.roofs.roof.each do |roof|
        # temp
        (0..1).each do |k|
        #

          # if not (roof.story == story_num and roof.space_below == Constants::SpaceUnfinAttic)
          #   next
          # end

          perimeterUAtc = 0

          # if geometry.roof_structure.item[index_num] == Constants::RoofStructureRafter
          # temp
          roofstructurerafter = "trusscantilever"
          if roofstructurerafter == "rafter"
            rfEdgeMinH_UAtc = OpenStudio::convert([uACeilingInsThickness, (1 - uACeilingFramingFactor) * ((uARoofFramingThickness - windBaffleClearance) / Math::cos(rfTilt / 180 * Math::PI) - birdMouthDepth)].min,"in","ft").get # ft
            rfEdgeW_UAtc = [0, (OpenStudio::convert(uACeilingInsThickness,"in","ft").get - rfEdgeMinH_UAtc) / Math::tan(rfTilt / 180 * Math::PI)].max # ft
          else
            rfEdgeMinH_UAtc = OpenStudio::convert([uACeilingInsThickness, OpenStudio::convert(eaves_depth * Math::tan(rfTilt / 180 * Math::PI),"ft","in").get + [0, (1 - uACeilingFramingFactor) * ((uARoofFramingThickness - windBaffleClearance) / Math::cos(rfTilt / 180 * Math::PI) - birdMouthDepth)].max].min,"in","ft").get # ft
            rfEdgeW_UAtc = [0, (OpenStudio::convert(uACeilingInsThickness,"in","ft").get - rfEdgeMinH_UAtc) / Math::tan(rfTilt / 180 * Math::PI)].max # ft
          end

          # min_z = min(roof.vertices.coord.z)
          # roof.vertices.coord[:-1].each_with_index do |vertex,vnum|
          #   vertex_next = roof.vertices.coord[vnum + 1]
          #   if vertex.z < min_z + 0.1 and vertex_next.z < min_z + 0.1
          #     dRoofX = vertex_next.x - vertex.x
          #     dRoofY = vertex_next.y - vertex.y
          #     perimeterUAtc += sqrt(dRoofX ** 2 + dRoofY ** 2) # Calculate unfinished attic Mid edge perimeter
          #   end
          # end
          # temp
          if k == 0
            perimeterUAtc = 40
          elsif k == 1
            perimeterUAtc = 40
          end
          #

          rfPerimeter_UAtc += perimeterUAtc
          #spaceArea_UAtc += roof.area * Math::cos(rfTilt / 180 * Math::PI) # Unfinished attic Area
          # temp
          if k == 0
            spaceArea_UAtc += 670.8204 * Math::cos(rfTilt / 180 * Math::PI) # Unfinished attic Area
          elsif k == 1
            spaceArea_UAtc += 670.8204 * Math::cos(rfTilt / 180 * Math::PI) # Unfinished attic Area
          end
          #
          spaceArea_UAtc_Perim += (perimeterUAtc - 2 * rfEdgeW_UAtc) * rfEdgeW_UAtc

        end

        spaceArea_UAtc_Perim += 4 * rfEdgeW_UAtc ** 2

        if spaceArea_UAtc_Perim != 0 and rfEdgeMinH_UAtc < OpenStudio::convert(uACeilingInsThickness,"in","ft").get
          spaceArea_UAtc = spaceArea_UAtc - spaceArea_UAtc_Perim + Math::log((rfEdgeW_UAtc * Math::tan(rfTilt / 180 * Math::PI) + rfEdgeMinH_UAtc) / rfEdgeMinH_UAtc) / Math::tan(rfTilt / 180 * Math::PI) * rfPerimeter_UAtc * OpenStudio::convert(uACeilingInsThickness,"in","ft").get
        end

        spaceArea_Rev_UAtc += spaceArea_UAtc

      end

      area = 1000 # FIXME: Currently hard-coded
      return uACeilingInsThickness * area / spaceArea_Rev_UAtc

  end


  
end #end the measure

#this allows the measure to be use by the application
ProcessConstructionsUnfinishedAttic.new.registerWithApplication