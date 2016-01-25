#see the URL below for information on how to write OpenStudio measures
# http://openstudio.nrel.gov/openstudio-measure-writing-guide

#see the URL below for information on using life cycle cost objects in OpenStudio
# http://openstudio.nrel.gov/openstudio-life-cycle-examples

#see the URL below for access to C++ documentation on model objects (click on "model" in the main window to view model objects)
# http://openstudio.nrel.gov/sites/openstudio.nrel.gov/files/nv_data/cpp_documentation_it/model/html/namespaces.html

require "#{File.dirname(__FILE__)}/resources/util"
require "#{File.dirname(__FILE__)}/resources/constants"

#start the measure
class ProcessConstructionsCrawlspace < OpenStudio::Ruleset::ModelUserScript
  
  #define the name that a user will see, this method may be deprecated as
  #the display name in PAT comes from the name field in measure.xml
  def name
    return "Set Residential Crawlspace Constructions"
  end
  
  def description
    return "This measure assigns constructions to the crawlspace ceiling, walls, floor, and rim joists."
  end
  
  def modeler_description
    return "Calculates material layer properties of constructions for the crawlspace ceiling, walls, floor, and rim joists. Finds surfaces adjacent to the crawlspace and sets applicable constructions."
  end    
  
  #define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Ruleset::OSArgumentVector.new

    #make a choice argument for model objects
    csins_display_names = OpenStudio::StringVector.new
    csins_display_names << "Uninsulated"
    csins_display_names << "Wall"
    csins_display_names << "Ceiling"
    
    #make a choice argument for cs insulation type
    selected_csins = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("selectedcsins", csins_display_names, true)
    selected_csins.setDisplayName("Crawlspace: Insulation Type")
    selected_csins.setDescription("The type of insulation.")
    selected_csins.setDefaultValue("Wall")
    args << selected_csins  

    #make a double argument for crawlspace ceiling / wall insulation R-value
    userdefined_cswallceilr = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedcswallceilr", false)
    userdefined_cswallceilr.setDisplayName("Crawlspace: Wall/Ceiling Continuous/Cavity Insulation Nominal R-value")
    userdefined_cswallceilr.setUnits("hr-ft^2-R/Btu")
    userdefined_cswallceilr.setDescription("R-value is a measure of insulation's ability to resist heat traveling through it.")
    userdefined_cswallceilr.setDefaultValue(5.0)
    args << userdefined_cswallceilr
    
    # Ceiling Joist Height
    #make a choice argument for model objects
    joistheight_display_names = OpenStudio::StringVector.new
    joistheight_display_names << "2x10" 
    
    #make a choice argument for crawlspace ceiling joist height
    selected_csceiljoistheight = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("selectedcsceiljoistheight", joistheight_display_names, true)
    selected_csceiljoistheight.setDisplayName("Crawlspace: Ceiling Joist Height")
    selected_csceiljoistheight.setUnits("in")
    selected_csceiljoistheight.setDescription("Height of the joist member.")
    selected_csceiljoistheight.setDefaultValue("2x10")
    args << selected_csceiljoistheight  
    
    #make a choice argument for model objects
    installgrade_display_names = OpenStudio::StringVector.new
    installgrade_display_names << "I"
    installgrade_display_names << "II"
    installgrade_display_names << "III"
    
    #make a choice argument for wall cavity insulation installation grade
    selected_installgrade = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("selectedinstallgrade", installgrade_display_names, true)
    selected_installgrade.setDisplayName("Crawlspace: Ceiling Cavity Install Grade")
    selected_installgrade.setDescription("5% of the wall is considered missing insulation for Grade 3, 2% for Grade 2, and 0% for Grade 1.")
    selected_installgrade.setDefaultValue("I")
    args << selected_installgrade   
    
    # Ceiling Framing Factor
    #make a choice argument for crawlspace ceiling framing factor
    userdefined_csceilff = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedcsceilff", false)
    userdefined_csceilff.setDisplayName("Crawlspace: Ceiling Framing Factor")
    userdefined_csceilff.setUnits("frac")
    userdefined_csceilff.setDescription("Fraction of ceiling that is framing.")
    userdefined_csceilff.setDefaultValue(0.13)
    args << userdefined_csceilff
    
    #make a double argument for rim joist insulation R-value
    userdefined_csrimjoistr = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedcsrimjoistr", false)
    userdefined_csrimjoistr.setDisplayName("Crawlspace: Rim Joist Insulation R-value")
    userdefined_csrimjoistr.setUnits("hr-ft^2-R/Btu")
    userdefined_csrimjoistr.setDescription("R-value is a measure of insulation's ability to resist heat traveling through it.")
    userdefined_csrimjoistr.setDefaultValue(5.0)
    args << userdefined_csrimjoistr
    
    #make a double argument for floor mass thickness
    userdefined_floormassth = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedfloormassth", false)
    userdefined_floormassth.setDisplayName("Floor Mass: Thickness")
    userdefined_floormassth.setUnits("in")
    userdefined_floormassth.setDescription("Thickness of the floor mass.")
    userdefined_floormassth.setDefaultValue(0.625)
    args << userdefined_floormassth

    #make a double argument for floor mass conductivity
    userdefined_floormasscond = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedfloormasscond", false)
    userdefined_floormasscond.setDisplayName("Floor Mass: Conductivity")
    userdefined_floormasscond.setUnits("Btu-in/h-ft^2-R")
    userdefined_floormasscond.setDescription("Conductivity of the floor mass.")
    userdefined_floormasscond.setDefaultValue(0.8004)
    args << userdefined_floormasscond

    #make a double argument for floor mass density
    userdefined_floormassdens = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedfloormassdens", false)
    userdefined_floormassdens.setDisplayName("Floor Mass: Density")
    userdefined_floormassdens.setUnits("lb/ft^3")
    userdefined_floormassdens.setDescription("Density of the floor mass.")
    userdefined_floormassdens.setDefaultValue(34.0)
    args << userdefined_floormassdens

    #make a double argument for floor mass specific heat
    userdefined_floormasssh = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedfloormasssh", false)
    userdefined_floormasssh.setDisplayName("Floor Mass: Specific Heat")
    userdefined_floormasssh.setUnits("Btu/lb-R")
    userdefined_floormasssh.setDescription("Specific heat of the floor mass.")
    userdefined_floormasssh.setDefaultValue(0.29)
    args << userdefined_floormasssh
    
    #make a double argument for carpet pad R-value
    userdefined_carpetr = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedcarpetr", false)
    userdefined_carpetr.setDisplayName("Carpet: Carpet Pad R-value")
    userdefined_carpetr.setUnits("hr-ft^2-R/Btu")
    userdefined_carpetr.setDescription("The combined R-value of the carpet and the pad.")
    userdefined_carpetr.setDefaultValue(2.08)
    args << userdefined_carpetr

    #make a double argument for carpet floor fraction
    userdefined_carpetfrac = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedcarpetfrac", false)
    userdefined_carpetfrac.setDisplayName("Carpet: Floor Carpet Fraction")
    userdefined_carpetfrac.setUnits("frac")
    userdefined_carpetfrac.setDescription("Defines the fraction of a floor which is covered by carpet.")
    userdefined_carpetfrac.setDefaultValue(0.8)
    args << userdefined_carpetfrac

    # Geometry
    userdefinedcsarea = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedcsarea", false)
    userdefinedcsarea.setDisplayName("Crawlspace Area")
    userdefinedcsarea.setUnits("ft^2")
    userdefinedcsarea.setDescription("The area of the crawlspace.")
    userdefinedcsarea.setDefaultValue(1200.0)
    args << userdefinedcsarea   
    
    userdefinedcsheight = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedcsheight", false)
    userdefinedcsheight.setDisplayName("Crawlspace Height")
    userdefinedcsheight.setUnits("ft")
    userdefinedcsheight.setDescription("The height of the crawlspace.")
    userdefinedcsheight.setDefaultValue(4.0)
    args << userdefinedcsheight

    userdefinedcsextperim = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedcsextperim", false)
    userdefinedcsextperim.setDisplayName("Crawlspace Perimeter")
    userdefinedcsextperim.setUnits("ft")
    userdefinedcsextperim.setDescription("The perimeter of the crawlspace.")
    userdefinedcsextperim.setDefaultValue(140.0)
    args << userdefinedcsextperim

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

    #make a choice argument for crawl space type
    space_types = model.getSpaceTypes
    space_type_args = OpenStudio::StringVector.new
    space_types.each do |space_type|
        space_type_args << space_type.name.to_s
    end
    if not space_type_args.include?(Constants.CrawlSpaceType)
        space_type_args << Constants.CrawlSpaceType
    end
    crawl_space_type = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("crawl_space_type", space_type_args, true)
    crawl_space_type.setDisplayName("Crawlspace space type")
    crawl_space_type.setDescription("Select the crawlspace space type")
    crawl_space_type.setDefaultValue(Constants.CrawlSpaceType)
    args << crawl_space_type
    
    return args
  end #end the arguments method

  #define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)
    
    #use the built-in error checking 
    if not runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

    crawlWallContInsRvalueNominal = 0
    crawlCeilingCavityInsRvalueNominal = 0
    crawlRimJoistInsRvalue = 0
    carpetPadRValue = 0

    # Space Type
    living_space_type_r = runner.getStringArgumentValue("living_space_type",user_arguments)
    living_space_type = HelperMethods.get_space_type_from_string(model, living_space_type_r, runner)
    if living_space_type.nil?
        return false
    end
    crawl_space_type_r = runner.getStringArgumentValue("crawl_space_type",user_arguments)
    crawl_space_type = HelperMethods.get_space_type_from_string(model, crawl_space_type_r, runner, false)
    if crawl_space_type.nil?
        # If the building has no crawlspace, no constructions are assigned and we continue by returning True
        return true
    end

    has_applicable_surfaces = false
    
    living_space_type.spaces.each do |living_space|
      living_space.surfaces.each do |living_surface|
        next unless ["floor"].include? living_surface.surfaceType.downcase
        adjacent_surface = living_surface.adjacentSurface
        next unless adjacent_surface.is_initialized
        adjacent_surface = adjacent_surface.get
        adjacent_surface_r = adjacent_surface.name.to_s
        adjacent_space_type_r = HelperMethods.get_space_type_from_surface(model, adjacent_surface_r)
        next unless [crawl_space_type_r].include? adjacent_space_type_r
        has_applicable_surfaces = true
        break
      end   
    end 
    
    crawl_space_type.spaces.each do |crawl_space|
      crawl_space.surfaces.each do |crawl_surface|
        if ( crawl_surface.surfaceType.downcase == "wall" and crawl_surface.outsideBoundaryCondition.downcase == "ground" ) or ( crawl_surface.surfaceType.downcase == "floor" and crawl_surface.outsideBoundaryCondition.downcase == "ground" ) or ( crawl_surface.surfaceType.downcase == "wall" and crawl_surface.outsideBoundaryCondition.downcase == "outdoors" )
          has_applicable_surfaces = true
          break
        end
      end   
    end

    unless has_applicable_surfaces
        return true
    end    
    
    # Crawlspace Insulation
    selected_csins = runner.getStringArgumentValue("selectedcsins",user_arguments)
    selected_installgrade = runner.getStringArgumentValue("selectedinstallgrade",user_arguments)
    
    # Wall / Ceiling Insulation
    if ["Wall", "Ceiling"].include? selected_csins.to_s
        userdefined_cswallceilr = runner.getDoubleArgumentValue("userdefinedcswallceilr",user_arguments)
    end
    
    # Ceiling Joist Height
    selected_csceiljoistheight = runner.getStringArgumentValue("selectedcsceiljoistheight",user_arguments)
    
    # Ceiling Framing Factor
    userdefined_csceilff = runner.getDoubleArgumentValue("userdefinedcsceilff",user_arguments)
    if not ( userdefined_csceilff > 0.0 and userdefined_csceilff < 1.0 )
      runner.registerError("Invalid crawlspace ceiling framing factor")
      return false
    end

    # Rim Joist
    if ["Wall"].include? selected_csins.to_s
        selected_csrimjoist = runner.getOptionalWorkspaceObjectChoiceValue("selectedcsrimjoist",user_arguments,model)
        if selected_csrimjoist.empty?
            userdefined_csrimjoistr = runner.getDoubleArgumentValue("userdefinedcsrimjoistr",user_arguments)
        end
    end
    
    # Floor Mass
    floorMassThickness = runner.getDoubleArgumentValue("userdefinedfloormassth",user_arguments)
    floorMassConductivity = runner.getDoubleArgumentValue("userdefinedfloormasscond",user_arguments)
    floorMassDensity = runner.getDoubleArgumentValue("userdefinedfloormassdens",user_arguments)
    floorMassSpecificHeat = runner.getDoubleArgumentValue("userdefinedfloormasssh",user_arguments)
    
    # Carpet
    carpetPadRValue = runner.getDoubleArgumentValue("userdefinedcarpetr",user_arguments)
    carpetFloorFraction = runner.getDoubleArgumentValue("userdefinedcarpetfrac",user_arguments)
    
    # Insulation
    if selected_csins.to_s == "Wall"
        crawlWallContInsRvalueNominal = userdefined_cswallceilr
    elsif selected_csins.to_s == "Ceiling"
        crawlCeilingCavityInsRvalueNominal = userdefined_cswallceilr
    end
    crawlCeilingInstallGrade_dict = {"I"=>1, "II"=>2, "III"=>3}
    crawlCeilingInstallGrade = crawlCeilingInstallGrade_dict[selected_installgrade] 
    
    # Ceiling Joist Height
    csCeilingJoistHeight_dict = {"2x10"=>9.25}
    crawlCeilingJoistHeight = csCeilingJoistHeight_dict[selected_csceiljoistheight] 
        
    # Ceiling Framing Factor
    crawlCeilingFramingFactor = userdefined_csceilff
    
    # Rim Joist
    if ["Wall"].include? selected_csins.to_s
        crawlRimJoistInsRvalue = userdefined_csrimjoistr
    end
    
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
            wallSheathingContInsConductivity = OpenStudio::convert(layer.to_StandardOpaqueMaterial.get.conductivity,"W/m*K","Btu*in/hr*ft^2*R").get
            wallSheathingContInsRvalue = wallSheathingContInsThickness/wallSheathingContInsConductivity
          end
        end
      end
    end

    # FIXME: Need to calculate and remove inputs
    csHeight = runner.getDoubleArgumentValue("userdefinedcsheight",user_arguments)
    csArea = runner.getDoubleArgumentValue("userdefinedcsarea",user_arguments)
    csExtPerimeter = runner.getDoubleArgumentValue("userdefinedcsextperim",user_arguments)
    
    # Process the crawlspace
    sc_thick, sc_cond, sc_dens, sc_sh, sc_Rvalue, crawlspace_fictitious_Rvalue, wall_thick, wall_cond, wall_dens, wall_sh, crawlspace_floor_Rvalue, rj_thick, rj_cond, rj_dens, rj_sh = _processConstructionsCrawlspace(crawlCeilingFramingFactor, crawlCeilingInstallGrade, crawlWallContInsRvalueNominal, crawlRimJoistInsRvalue, crawlCeilingJoistHeight, crawlCeilingCavityInsRvalueNominal, carpetFloorFraction, carpetPadRValue, floorMassThickness, floorMassConductivity, floorMassDensity, floorMassSpecificHeat, wallSheathingContInsThickness, wallSheathingContInsRvalue, finishThickness, finishConductivity, crawl_space_type, csHeight, csExtPerimeter, csArea)
    
    # CrawlCeilingIns
    if sc_Rvalue > 0
        cci = OpenStudio::Model::StandardOpaqueMaterial.new(model)
        cci.setName("CrawlCeilingIns")
        cci.setRoughness("Rough")
        cci.setThickness(OpenStudio::convert(sc_thick,"ft","m").get)
        cci.setConductivity(OpenStudio::convert(sc_cond,"Btu/hr*ft*R","W/m*K").get)
        cci.setDensity(OpenStudio::convert(sc_dens,"lb/ft^3","kg/m^3").get)
        cci.setSpecificHeat(OpenStudio::convert(sc_sh,"Btu/lb*R","J/kg*K").get)
    end
    
    # Plywood-3_4in
    ply3_4 = OpenStudio::Model::StandardOpaqueMaterial.new(model)
    ply3_4.setName("Plywood-3_4in")
    ply3_4.setRoughness("Rough")
    ply3_4.setThickness(OpenStudio::convert(Material.Plywood3_4in.thick,"in","m").get)
    ply3_4.setConductivity(OpenStudio::convert(Material.Plywood3_4in.k,"Btu/hr*ft*R","W/m*K").get)
    ply3_4.setDensity(OpenStudio::convert(Material.Plywood3_4in.rho,"lb/ft^3","kg/m^3").get)
    ply3_4.setSpecificHeat(OpenStudio::convert(Material.Plywood3_4in.Cp,"Btu/lb*R","J/kg*K").get)
    
    # Plywood-3_2in
    ply3_2 = OpenStudio::Model::StandardOpaqueMaterial.new(model)
    ply3_2.setName("Plywood-3_2in")
    ply3_2.setRoughness("Rough")
    ply3_2.setThickness(OpenStudio::convert(Material.Plywood3_2in.thick,"ft","m").get)
    ply3_2.setConductivity(OpenStudio::convert(Material.Plywood3_2in.k,"Btu/hr*ft*R","W/m*K").get)
    ply3_2.setDensity(OpenStudio::convert(Material.Plywood3_2in.rho,"lb/ft^3","kg/m^3").get)
    ply3_2.setSpecificHeat(OpenStudio::convert(Material.Plywood3_2in.Cp,"Btu/lb*R","J/kg*K").get)    
    
    # FloorMass
    mat_floor_mass = Material.MassFloor(floorMassThickness, floorMassConductivity, floorMassDensity, floorMassSpecificHeat)
    fm = OpenStudio::Model::StandardOpaqueMaterial.new(model)
    fm.setName("FloorMass")
    fm.setRoughness("Rough")
    fm.setThickness(OpenStudio::convert(mat_floor_mass.thick,"ft","m").get)
    fm.setConductivity(OpenStudio::convert(mat_floor_mass.k,"Btu/hr*ft*R","W/m*K").get)
    fm.setDensity(OpenStudio::convert(mat_floor_mass.rho,"lb/ft^3","kg/m^3").get)
    fm.setSpecificHeat(OpenStudio::convert(mat_floor_mass.Cp,"Btu/lb*R","J/kg*K").get)
    fm.setThermalAbsorptance(mat_floor_mass.TAbs)
    fm.setSolarAbsorptance(mat_floor_mass.SAbs)
        
    # CWall-FicR
    if crawlspace_fictitious_Rvalue > 0
        cwfr = OpenStudio::Model::MasslessOpaqueMaterial.new(model)
        cwfr.setName("CWall-FicR")
        cwfr.setRoughness("Rough")
        cwfr.setThermalResistance(OpenStudio::convert(crawlspace_fictitious_Rvalue,"hr*ft^2*R/Btu","m^2*K/W").get)
    end
    
    # Soil-12in
    soil = OpenStudio::Model::StandardOpaqueMaterial.new(model)
    soil.setName("Soil-12in")
    soil.setRoughness("Rough")
    soil.setThickness(OpenStudio::convert(Material.Soil12in.thick,"ft","m").get)
    soil.setConductivity(OpenStudio::convert(Material.Soil12in.k,"Btu/hr*ft*R","W/m*K").get)
    soil.setDensity(OpenStudio::convert(Material.Soil12in.rho,"lb/ft^3","kg/m^3").get)
    soil.setSpecificHeat(OpenStudio::convert(Material.Soil12in.Cp,"Btu/lb*R","J/kg*K").get)
    
    # Concrete-8in
    conc8 = OpenStudio::Model::StandardOpaqueMaterial.new(model)
    conc8.setName("Concrete-8in")
    conc8.setRoughness("Rough")
    conc8.setThickness(OpenStudio::convert(Material.Concrete8in.thick,"ft","m").get)
    conc8.setConductivity(OpenStudio::convert(Material.Concrete8in.k,"Btu/hr*ft*R","W/m*K").get)
    conc8.setDensity(OpenStudio::convert(Material.Concrete8in.rho,"lb/ft^3","kg/m^3").get)
    conc8.setSpecificHeat(OpenStudio::convert(Material.Concrete8in.Cp,"Btu/lb*R","J/kg*K").get)
    conc8.setThermalAbsorptance(Material.Concrete8in.TAbs)
    
    # CWallIns
    if crawlWallContInsRvalueNominal > 0
        cwi = OpenStudio::Model::StandardOpaqueMaterial.new(model)
        cwi.setName("CWallIns")
        cwi.setRoughness("Rough")
        cwi.setThickness(OpenStudio::convert(wall_thick,"ft","m").get)
        cwi.setConductivity(OpenStudio::convert(wall_cond,"Btu/hr*ft*R","W/m*K").get)
        cwi.setDensity(OpenStudio::convert(wall_dens,"lb/ft^3","kg/m^3").get)
        cwi.setSpecificHeat(OpenStudio::convert(wall_sh,"Btu/lb*R","J/kg*K").get)
    end
    
    # CFloor-FicR
    cffr = OpenStudio::Model::MasslessOpaqueMaterial.new(model)
    cffr.setName("CFloor-FicR")
    cffr.setRoughness("Rough")
    cffr.setThermalResistance(OpenStudio::convert(crawlspace_floor_Rvalue,"hr*ft^2*R/Btu","m^2*K/W").get)
    
    # CSJoistandCavity
    cjc = OpenStudio::Model::StandardOpaqueMaterial.new(model)
    cjc.setName("CSJoistandCavity")
    cjc.setRoughness("Rough")
    cjc.setThickness(OpenStudio::convert(rj_thick,"ft","m").get)
    cjc.setConductivity(OpenStudio::convert(rj_cond,"Btu/hr*ft*R","W/m*K").get)
    cjc.setDensity(OpenStudio::convert(rj_dens,"lb/ft^3","kg/m^3").get)
    cjc.setSpecificHeat(OpenStudio::convert(rj_sh,"Btu/lb*R","J/kg*K").get)

    # Rigid
    if wallSheathingContInsRvalue > 0
        rigid = OpenStudio::Model::StandardOpaqueMaterial.new(model)
        rigid.setName("WallRigidIns")
        rigid.setRoughness("Rough")
		rigid.setThickness(OpenStudio::convert(wallSheathingContInsThickness,"in","m").get)
		rigid.setConductivity(OpenStudio::convert(wallSheathingContInsConductivity,"Btu/hr*ft*R","W/m*K").get)
		rigid.setDensity(OpenStudio::convert(BaseMaterial.RigidInsulation.rho,"lb/ft^3","kg/m^3").get)
		rigid.setSpecificHeat(OpenStudio::convert(BaseMaterial.RigidInsulation.Cp,"Btu/lb*R","J/kg*K").get)
    end
    
    # CarpetBareLayer
    if carpetFloorFraction > 0
        mat_carpet_bare = Material.CarpetBare(carpetFloorFraction, carpetPadRValue)
        cbl = OpenStudio::Model::StandardOpaqueMaterial.new(model)
        cbl.setName("CarpetBareLayer")
        cbl.setRoughness("Rough")
        cbl.setThickness(OpenStudio::convert(mat_carpet_bare.thick,"ft","m").get)
        cbl.setConductivity(OpenStudio::convert(mat_carpet_bare.k,"Btu/hr*ft*R","W/m*K").get)
        cbl.setDensity(OpenStudio::convert(mat_carpet_bare.rho,"lb/ft^3","kg/m^3").get)
        cbl.setSpecificHeat(OpenStudio::convert(mat_carpet_bare.Cp,"Btu/lb*R","J/kg*K").get)
        cbl.setThermalAbsorptance(mat_carpet_bare.TAbs)
        cbl.setSolarAbsorptance(mat_carpet_bare.SAbs)
    end
    
    # UnfinCSInsFinFloor
    materials = []
    if sc_Rvalue > 0
        materials << cci
    end 
    materials << ply3_4
    materials << fm
    if carpetFloorFraction > 0
        materials << cbl
    end
    unfincsinsfinfloor = OpenStudio::Model::Construction.new(materials)
    unfincsinsfinfloor.setName("UnfinCSInsFinFloor")    

    # RevUnfinCSInsFinFloor
    revunfincsinsfinfloor = unfincsinsfinfloor.reverseConstruction
    revunfincsinsfinfloor.setName("RevUnfinCSInsFinFloor")

    # GrndInsUnfinCSWall
    materials = []
    if crawlspace_fictitious_Rvalue > 0
        materials << cwfr
    end
    materials << soil
    materials << conc8
    if crawlWallContInsRvalueNominal > 0
        materials << cwi
    end
    grndinsunfincswall = OpenStudio::Model::Construction.new(materials)
    grndinsunfincswall.setName("GrndInsUnfinCSWall")    
    
    # GrndUninsUnfinCSFloor
    materials = []
    materials << cffr
    materials << soil
    grnduninsunfincsfloor = OpenStudio::Model::Construction.new(materials)
    grnduninsunfincsfloor.setName("GrndUninsUnfinCSFloor")
    
    # CSRimJoist
    materials = []
    materials << extfin.to_StandardOpaqueMaterial.get
    if wallSheathingContInsRvalue > 0
        materials << rigid
    end
    materials << ply3_2
    materials << cjc
    csrimjoist = OpenStudio::Model::Construction.new(materials)
    csrimjoist.setName("CSRimJoist")
    
    living_space_type.spaces.each do |living_space|
      living_space.surfaces.each do |living_surface|
        next unless ["floor"].include? living_surface.surfaceType.downcase
        adjacent_surface = living_surface.adjacentSurface
        next unless adjacent_surface.is_initialized
        adjacent_surface = adjacent_surface.get
        adjacent_surface_r = adjacent_surface.name.to_s
        adjacent_space_type_r = HelperMethods.get_space_type_from_surface(model, adjacent_surface_r)
        next unless [crawl_space_type_r].include? adjacent_space_type_r
        living_surface.setConstruction(unfincsinsfinfloor)
        runner.registerInfo("Surface '#{living_surface.name}', of Space Type '#{living_space_type_r}' and with Surface Type '#{living_surface.surfaceType}' and Outside Boundary Condition '#{living_surface.outsideBoundaryCondition}', was assigned Construction '#{unfincsinsfinfloor.name}'")
        adjacent_surface.setConstruction(revunfincsinsfinfloor)     
        runner.registerInfo("Surface '#{adjacent_surface.name}', of Space Type '#{adjacent_space_type_r}' and with Surface Type '#{adjacent_surface.surfaceType}' and Outside Boundary Condition '#{adjacent_surface.outsideBoundaryCondition}', was assigned Construction '#{revunfincsinsfinfloor.name}'")
      end   
    end 
    
    crawl_space_type.spaces.each do |crawl_space|
      crawl_space.surfaces.each do |crawl_surface|
        if crawl_surface.surfaceType.downcase == "wall" and crawl_surface.outsideBoundaryCondition.downcase == "ground"
          crawl_surface.setConstruction(grndinsunfincswall)
          runner.registerInfo("Surface '#{crawl_surface.name}', of Space Type '#{crawl_space_type_r}' and with Surface Type '#{crawl_surface.surfaceType}' and Outside Boundary Condition '#{crawl_surface.outsideBoundaryCondition}', was assigned Construction '#{grndinsunfincswall.name}'")
        elsif crawl_surface.surfaceType.downcase == "floor" and crawl_surface.outsideBoundaryCondition.downcase == "ground"
          crawl_surface.setConstruction(grnduninsunfincsfloor)
          runner.registerInfo("Surface '#{crawl_surface.name}', of Space Type '#{crawl_space_type_r}' and with Surface Type '#{crawl_surface.surfaceType}' and Outside Boundary Condition '#{crawl_surface.outsideBoundaryCondition}', was assigned Construction '#{grnduninsunfincsfloor.name}'")      
        elsif crawl_surface.surfaceType.downcase == "wall" and crawl_surface.outsideBoundaryCondition.downcase == "outdoors"
          crawl_surface.setConstruction(csrimjoist)
          runner.registerInfo("Surface '#{crawl_surface.name}', of Space Type '#{crawl_space_type_r}' and with Surface Type '#{crawl_surface.surfaceType}' and Outside Boundary Condition '#{crawl_surface.outsideBoundaryCondition}', was assigned Construction '#{csrimjoist.name}'")             
        end
      end   
    end

    return true

  end #end the run method

  def _processConstructionsCrawlspace(crawlCeilingFramingFactor, crawlCeilingInstallGrade, crawlWallContInsRvalueNominal, crawlRimJoistInsRvalue, crawlCeilingJoistHeight, crawlCeilingCavityInsRvalueNominal, carpetFloorFraction, carpetPadRValue, floorMassThickness, floorMassConductivity, floorMassDensity, floorMassSpecificHeat, wallSheathingContInsThickness, wallSheathingContInsRvalue, finishThickness, finishConductivity, selected_crawlspace, csHeight, csExtPerimeter, csArea)
        # If there is no wall insulation, apply the ceiling insulation R-value to the rim joists
        if crawlWallContInsRvalueNominal == 0
            crawlRimJoistInsRvalue = crawlCeilingCavityInsRvalueNominal
        end
        
        mat_2x = Material.Stud2x(crawlCeilingJoistHeight)
        
        crawlspace_conduction = calc_crawlspace_wall_conductance(crawlWallContInsRvalueNominal, csHeight)
        
        csGapFactor = Construction.GetWallGapFactor(crawlCeilingInstallGrade, crawlCeilingFramingFactor)

        sc_Rvalue = get_crawlspace_ceiling_r_assembly(crawlCeilingCavityInsRvalueNominal, crawlCeilingFramingFactor, crawlCeilingInstallGrade, crawlCeilingJoistHeight, carpetFloorFraction, carpetPadRValue, floorMassThickness, floorMassConductivity, floorMassDensity, floorMassSpecificHeat, csGapFactor)
        
        crawl_ceiling_studlayer_Rvalue = sc_Rvalue - Construction.GetFloorNonStudLayerR(floorMassThickness, floorMassConductivity, floorMassDensity, floorMassSpecificHeat, carpetFloorFraction, carpetPadRValue)
        
        if sc_Rvalue > 0
            sc_thick = mat_2x.thick
            sc_cond = sc_thick / crawl_ceiling_studlayer_Rvalue
            sc_dens = crawlCeilingFramingFactor * BaseMaterial.Wood.rho + (1 - crawlCeilingFramingFactor - csGapFactor) * BaseMaterial.InsulationGenericDensepack.rho + csGapFactor * Gas.Air.Cp # lbm/ft^3
            sc_sh = (crawlCeilingFramingFactor * BaseMaterial.Wood.Cp * BaseMaterial.Wood.rho + (1 - crawlCeilingFramingFactor - csGapFactor) * BaseMaterial.InsulationGenericDensepack.Cp * BaseMaterial.InsulationGenericDensepack.rho + csGapFactor * Gas.Air.Cp * Gas.Air.Cp) / sc_dens # Btu/lbm*F
        end
        
        if crawlWallContInsRvalueNominal > 0
            wall_thick = OpenStudio::convert(crawlWallContInsRvalueNominal / 5.0,"in","ft").get # ft
            wall_cond = wall_thick / crawlWallContInsRvalueNominal # Btu/hr*ft*F
            wall_dens = BaseMaterial.InsulationRigid.rho # lbm/ft^3
            wall_sh = BaseMaterial.InsulationRigid.Cp # Btu/lbm*F
        end
        
        crawlspace_wall_area = csExtPerimeter * csHeight
        
        if csExtPerimeter > 0
            crawlspace_effective_Rvalue = crawlspace_wall_area / (crawlspace_conduction * csExtPerimeter) # hr*ft^2*F/Btu
        else
            crawlspace_effective_Rvalue = 1000 # hr*ft^2*F/Btu
        end
        
        # Fictitious layer behind unvented crawlspace wall to achieve equivalent R-value. See Winklemann article.
        crawlspace_US_Rvalue = Material.Concrete8in.Rvalue + AirFilms.VerticalR + crawlWallContInsRvalueNominal
        crawlspace_fictitious_Rvalue = crawlspace_effective_Rvalue - Material.Soil12in.Rvalue - crawlspace_US_Rvalue
        
        crawlspace_total_UA = crawlspace_wall_area / crawlspace_effective_Rvalue # Btu/hr*F
        crawlspace_wall_Rvalue = crawlspace_US_Rvalue + Material.Soil12in.Rvalue
        crawlspace_wall_UA = crawlspace_wall_area / crawlspace_wall_Rvalue
        
        # Fictitious layer below crawlspace floor to achieve equivalent R-value. See Winklemann article.
        if crawlspace_fictitious_Rvalue < 0
            crawlspace_floor_Rvalue = csArea / (crawlspace_total_UA - crawlspace_wall_area / (crawlspace_US_Rvalue + Material.Soil12in.Rvalue)) - Material.Soil12in.Rvalue # hr*ft^2*F/Btu
             # (assumes crawlspace floor is dirt with no concrete slab)
        else
            crawlspace_floor_Rvalue = 1000 # hr*ft^2*F/Btu
        end

        rj_thick, rj_cond, rj_dens, rj_sh = _processConstructionsCrawlspaceRimJoist(crawlRimJoistInsRvalue, crawlCeilingJoistHeight, crawlCeilingFramingFactor, wallSheathingContInsThickness, wallSheathingContInsRvalue, finishThickness, finishConductivity)
        
        return sc_thick, sc_cond, sc_dens, sc_sh, sc_Rvalue, crawlspace_fictitious_Rvalue, wall_thick, wall_cond, wall_dens, wall_sh, crawlspace_floor_Rvalue, rj_thick, rj_cond, rj_dens, rj_sh

  end

  def get_crawlspace_ceiling_r_assembly(crawlCeilingCavityInsRvalueNominal, crawlCeilingFramingFactor, crawlCeilingInstallGrade, crawlCeilingJoistHeight, carpetFloorFraction, carpetPadRValue, floorMassThickness, floorMassConductivity, floorMassDensity, floorMassSpecificHeat, csGapFactor)
    # Returns assembly R-value for crawlspace ceiling, including air films.
    
    mat_2x = Material.Stud2x(crawlCeilingJoistHeight)
    
    path_fracs = [crawlCeilingFramingFactor, 1 - crawlCeilingFramingFactor - csGapFactor, csGapFactor]
    
    crawl_ceiling = Construction.new(path_fracs)
    
    # Interior Film
    crawl_ceiling.addlayer(thickness=OpenStudio::convert(1.0,"in","ft").get, conductivity_list=[OpenStudio::convert(1.0,"in","ft").get / AirFilms.FloorReducedR])
    
    # Stud/cavity layer
    if crawlCeilingCavityInsRvalueNominal == 0
        cavity_k = 1000000000
    else
        cavity_k = (mat_2x.thick / crawlCeilingCavityInsRvalueNominal)
    end
    gap_k = mat_2x.thick / Gas.AirGapRvalue
    
    crawl_ceiling.addlayer(thickness=mat_2x.thick, conductivity_list=[BaseMaterial.Wood.k, cavity_k, gap_k])

    # Floor deck
    crawl_ceiling.addlayer(thickness=nil, conductivity_list=nil, material=Material.Plywood3_4in)

    # Floor mass
    if floorMassThickness > 0
        mat_floor_mass = Material.MassFloor(floorMassThickness, floorMassConductivity, floorMassDensity, floorMassSpecificHeat)
        crawl_ceiling.addlayer(thickness=nil, conductivity_list=nil, material=mat_floor_mass)
    end

    # Carpet
    if carpetFloorFraction > 0
        carpet_smeared_cond = OpenStudio::convert(0.5,"in","ft").get / (carpetPadRValue * carpetFloorFraction)
        crawl_ceiling.addlayer(thickness=OpenStudio::convert(0.5,"in","ft").get, conductivity_list=[carpet_smeared_cond])   
    end

    # Exterior Film
    crawl_ceiling.addlayer(thickness=OpenStudio::convert(1.0,"in","ft").get, conductivity_list=[OpenStudio::convert(1.0,"in","ft").get / AirFilms.FloorReducedR])

    return crawl_ceiling.Rvalue_parallel
    
  end

  def _processConstructionsCrawlspaceRimJoist(crawlRimJoistInsRvalue, crawlCeilingJoistHeight, crawlCeilingFramingFactor, wallSheathingContInsThickness, wallSheathingContInsRvalue, finishThickness, finishConductivity)
    
        rimjoist_framingfactor = 0.6 * crawlCeilingFramingFactor #0.6 Factor added for due joist orientation
        mat_2x = Material.Stud2x(crawlCeilingJoistHeight)

        crawl_rimjoist_Rvalue = Construction.GetRimJoistAssmeblyR(crawlRimJoistInsRvalue, crawlCeilingJoistHeight, wallSheathingContInsThickness, wallSheathingContInsRvalue, 0, 0, rimjoist_framingfactor, finishThickness, finishConductivity)
        
        crawl_rimjoist_studlayer_Rvalue = crawl_rimjoist_Rvalue - Construction.GetRimJoistNonStudLayerR
        
        rj_thick = mat_2x.thick
        rj_cond = rj_thick / crawl_rimjoist_studlayer_Rvalue
        if crawlRimJoistInsRvalue > 0
            rj_dens = crawlCeilingFramingFactor * BaseMaterial.Wood.rho + (1 - rimjoist_framingfactor) * BaseMaterial.InsulationGenericDensepack.rho  # lbm/ft^3
            rj_sh = (crawlCeilingFramingFactor * BaseMaterial.Wood.Cp * BaseMaterial.Wood.rho + (1 - rimjoist_framingfactor) * BaseMaterial.InsulationGenericDensepack.Cp * BaseMaterial.InsulationGenericDensepack.rho) / rj_dens # Btu/lbm*F
        else
            rj_dens = rimjoist_framingfactor * BaseMaterial.Wood.rho + (1 - rimjoist_framingfactor) * Gas.Air.Cp # lbm/ft^3
            rj_sh = (rimjoist_framingfactor * BaseMaterial.Wood.Cp * BaseMaterial.Wood.rho + (1 - rimjoist_framingfactor) * Gas.Air.Cp * Gas.Air.Cp) / rj_dens # Btu/lbm*F
        end
   
        return rj_thick, rj_cond, rj_dens, rj_sh
    
  end

  def calc_crawlspace_wall_conductance(crawlWallContInsRvalueNominal, crawlWallHeight)
    # Interpolate/extrapolate between 2ft and 4ft conduction factors based on actual space height:
    crawlspace_conduction2 = 1.120 / (0.237 + crawlWallContInsRvalueNominal) ** 0.099
    crawlspace_conduction4 = 1.126 / (0.621 + crawlWallContInsRvalueNominal) ** 0.269
    crawlspace_conduction = crawlspace_conduction2 + (crawlspace_conduction4 - crawlspace_conduction2) * (crawlWallHeight - 2) / (4 - 2)
    return crawlspace_conduction
  end

  
end #end the measure

#this allows the measure to be use by the application
ProcessConstructionsCrawlspace.new.registerWithApplication