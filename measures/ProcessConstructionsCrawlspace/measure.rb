#see the URL below for information on how to write OpenStudio measures
# http://openstudio.nrel.gov/openstudio-measure-writing-guide

#see the URL below for information on using life cycle cost objects in OpenStudio
# http://openstudio.nrel.gov/openstudio-life-cycle-examples

#see the URL below for access to C++ documentation on model objects (click on "model" in the main window to view model objects)
# http://openstudio.nrel.gov/sites/openstudio.nrel.gov/files/nv_data/cpp_documentation_it/model/html/namespaces.html

require "#{File.dirname(__FILE__)}/resources/util"
require "#{File.dirname(__FILE__)}/resources/constants"
require "#{File.dirname(__FILE__)}/resources/geometry"

#start the measure
class ProcessConstructionsCrawlspace < OpenStudio::Ruleset::ModelUserScript
  
  #define the name that a user will see, this method may be deprecated as
  #the display name in PAT comes from the name field in measure.xml
  def name
    return "Set Residential Crawlspace Constructions"
  end
  
  def description
    return "This measure assigns constructions to the crawlspace ceilings, walls, and floors."
  end
  
  def modeler_description
    return "Calculates and assigns material layer properties of constructions for: 1) ceilings above below-grade unfinished space, 2) walls between below-grade unfinished space and ground, and 3) floors below below-grade unfinished space. Below-grade spaces are assumed to be crawlspaces (and not basements) if the space height is less than #{Constants.MinimumBasementHeight.to_s} ft."
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
    selected_csins.setDisplayName("Insulation Type")
    selected_csins.setDescription("The type of insulation.")
    selected_csins.setDefaultValue("Wall")
    args << selected_csins  

    #make a double argument for crawlspace ceiling / wall insulation R-value
    userdefined_cswallceilr = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedcswallceilr", false)
    userdefined_cswallceilr.setDisplayName("Wall/Ceiling Continuous/Cavity Insulation Nominal R-value")
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
    selected_csceiljoistheight.setDisplayName("Ceiling Joist Height")
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
    selected_installgrade.setDisplayName("Ceiling Cavity Install Grade")
    selected_installgrade.setDescription("5% of the wall is considered missing insulation for Grade 3, 2% for Grade 2, and 0% for Grade 1.")
    selected_installgrade.setDefaultValue("I")
    args << selected_installgrade   
    
    # Ceiling Framing Factor
    #make a choice argument for crawlspace ceiling framing factor
    userdefined_csceilff = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedcsceilff", false)
    userdefined_csceilff.setDisplayName("Ceiling Framing Factor")
    userdefined_csceilff.setUnits("frac")
    userdefined_csceilff.setDescription("Fraction of ceiling that is framing.")
    userdefined_csceilff.setDefaultValue(0.13)
    args << userdefined_csceilff
    
    return args
  end #end the arguments method

  #define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)
    
    #use the built-in error checking 
    if not runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

    wall_surfaces = []
    floor_surfaces = []
    ceiling_surfaces = []
    spaces = Geometry.get_crawl_spaces(model)
    spaces.each do |space|
        space.surfaces.each do |surface|
            # Wall between below-grade unfinished space and ground
            if surface.surfaceType.downcase == "wall" and surface.outsideBoundaryCondition.downcase == "ground"
                wall_surfaces << surface
            end
            # Floor below below-grade unfinished space
            if surface.surfaceType.downcase == "floor" and surface.outsideBoundaryCondition.downcase == "ground"
                floor_surfaces << surface
            end
            # Ceiling above below-grade unfinished space and below finished space
            if surface.surfaceType.downcase == "roofceiling" and surface.adjacentSurface.is_initialized
                adjacent_space = Geometry.get_space_from_surface(model, surface.adjacentSurface.get.name.to_s, runner)
                if Geometry.space_is_finished(adjacent_space)
                    ceiling_surfaces << surface
                end
            end
        end
    end
    
    # Continue if no applicable surfaces
    if wall_surfaces.empty? and floor_surfaces.empty? and ceiling_surfaces.empty?
      return true
    end    
    
    crawlWallContInsRvalueNominal = 0
    crawlCeilingCavityInsRvalueNominal = 0

    # Crawlspace Insulation
    selected_csins = runner.getStringArgumentValue("selectedcsins",user_arguments)
    crawlCeilingInstallGrade = {"I"=>1, "II"=>2, "III"=>3}[runner.getStringArgumentValue("selectedinstallgrade",user_arguments)] 
    
    # Wall / Ceiling Insulation
    if ["Wall", "Ceiling"].include? selected_csins.to_s
        userdefined_cswallceilr = runner.getDoubleArgumentValue("userdefinedcswallceilr",user_arguments)
    end
    
    # Ceiling Joist Height
    crawlCeilingJoistHeight = {"2x10"=>9.25}[runner.getStringArgumentValue("selectedcsceiljoistheight",user_arguments)] 
    
    # Ceiling Framing Factor
    crawlCeilingFramingFactor = runner.getDoubleArgumentValue("userdefinedcsceilff",user_arguments)
    if not ( crawlCeilingFramingFactor > 0.0 and crawlCeilingFramingFactor < 1.0 )
      runner.registerError("Invalid crawlspace ceiling framing factor")
      return false
    end

    # Insulation
    if selected_csins.to_s == "Wall"
        crawlWallContInsRvalueNominal = userdefined_cswallceilr
    elsif selected_csins.to_s == "Ceiling"
        crawlCeilingCavityInsRvalueNominal = userdefined_cswallceilr
    end
    
    csHeight = Geometry.spaces_avg_height(spaces)
    csArea = Geometry.calculate_floor_area(spaces)
    csExtPerimeter = Geometry.calculate_perimeter(spaces)
    csExtWallArea = Geometry.calculate_perimeter_wall_area(spaces)

    # -------------------------------
    # Process the crawl walls
    # -------------------------------
    
    if not wall_surfaces.empty?
        # Calculate fictitious layer behind finished basement wall to achieve equivalent R-value. See Winkelmann article.
        # Interpolate/extrapolate between 2ft and 4ft conduction factors based on actual space height:
        crawlspace_conduction2 = 1.120 / (0.237 + crawlWallContInsRvalueNominal) ** 0.099
        crawlspace_conduction4 = 1.126 / (0.621 + crawlWallContInsRvalueNominal) ** 0.269
        crawlspace_conduction = crawlspace_conduction2 + (crawlspace_conduction4 - crawlspace_conduction2) * (csHeight - 2) / (4 - 2)
        if csExtPerimeter > 0
            crawlspace_effective_Rvalue = csExtWallArea / (crawlspace_conduction * csExtPerimeter) # hr*ft^2*F/Btu
        else
            crawlspace_effective_Rvalue = 1000 # hr*ft^2*F/Btu
        end
        crawlspace_US_Rvalue = Material.Concrete8in.rvalue + Material.AirFilmVertical.rvalue + crawlWallContInsRvalueNominal
        crawlspace_fictitious_Rvalue = crawlspace_effective_Rvalue - Material.Soil12in.rvalue - crawlspace_US_Rvalue

        # Define materials
        mat_ins = Material.new(name="CWallIns", thick_in=crawlWallContInsRvalueNominal/BaseMaterial.InsulationRigid.k, mat_base=BaseMaterial.InsulationRigid)
        mat_fic_wall = SimpleMaterial.new(name="CWall-FicR", rvalue=crawlspace_fictitious_Rvalue)
        
        # Define construction
        cs_wall = Construction.new([1.0])
        cs_wall.addlayer(mat_fic_wall, true)
        cs_wall.addlayer(Material.Soil12in, true)
        cs_wall.addlayer(Material.Concrete8in, true)
        cs_wall.addlayer(mat_ins, true)
        cs_wall.addlayer(Material.AirFilmVertical, false)
        
        # Create and apply construction to surfaces
        if not cs_wall.create_and_assign_constructions(wall_surfaces, runner, model, "GrndInsUnfinCSWall")
            return false
        end
    end
    
    # -------------------------------
    # Process the crawl floor
    # -------------------------------
    
    if not floor_surfaces.empty?
        crawlspace_total_UA = csExtWallArea / crawlspace_effective_Rvalue # Btu/hr*F
        crawlspace_wall_Rvalue = crawlspace_US_Rvalue + Material.Soil12in.rvalue
        crawlspace_wall_UA = csExtWallArea / crawlspace_wall_Rvalue
        
        # Fictitious layer below crawlspace floor to achieve equivalent R-value. See Winklemann article.
        if crawlspace_fictitious_Rvalue < 0 # Not enough cond through walls, need to add in floor conduction
            crawlspace_floor_Rvalue = csArea / (crawlspace_total_UA - crawlspace_wall_UA) - Material.Soil12in.rvalue # hr*ft^2*F/Btu (assumes crawlspace floor is dirt with no concrete slab)
        else
            crawlspace_floor_Rvalue = 1000 # hr*ft^2*F/Btu
        end
        
        # Define materials
        mat_fic_floor = SimpleMaterial.new(name="CFloor-FicR", rvalue=crawlspace_floor_Rvalue)
        
        # Define construction
        cs_floor = Construction.new([1.0])
        cs_floor.addlayer(mat_fic_floor, true)
        cs_floor.addlayer(Material.Soil12in, true)
        
        # Create and apply construction to surfaces
        if not cs_floor.create_and_assign_constructions(floor_surfaces, runner, model, "GrndUninsUnfinCSFloor")
            return false
        end
    end

    # -------------------------------
    # Process the crawl ceiling
    # -------------------------------
    
    if not ceiling_surfaces.empty?
        # Define materials
        mat_2x = Material.Stud2x(crawlCeilingJoistHeight)
        if crawlCeilingCavityInsRvalueNominal == 0
            mat_cavity = Material.new(name=nil, thick_in=mat_2x.thick_in, mat_base=BaseMaterial.InsulationGenericDensepack, cond=1000000000)
        else    
            mat_cavity = Material.new(name=nil, thick_in=mat_2x.thick_in, mat_base=BaseMaterial.InsulationGenericDensepack, cond=mat_2x.thick / crawlCeilingCavityInsRvalueNominal)
        end
        mat_framing = Material.new(name=nil, thick_in=mat_2x.thick_in, mat_base=BaseMaterial.Wood)
        mat_gap = Material.AirCavity(mat_2x.thick_in)
        
        # Set paths
        csGapFactor = Construction.GetWallGapFactor(crawlCeilingInstallGrade, crawlCeilingFramingFactor)
        path_fracs = [crawlCeilingFramingFactor, 1 - crawlCeilingFramingFactor - csGapFactor, csGapFactor]
        
        # Define construction
        cs_ceiling = Construction.new(path_fracs)
        cs_ceiling.addlayer(Material.AirFilmFloorReduced, false)
        cs_ceiling.addlayer([mat_framing, mat_cavity, mat_gap], true, "CrawlCeilingIns")
        cs_ceiling.addlayer(Material.Plywood3_4in, true)
        cs_ceiling.addlayer(Material.DefaultFloorMass, false) # thermal mass added in separate measure
        cs_ceiling.addlayer(Material.DefaultCarpet, false) # carpet added in separate measure
        cs_ceiling.addlayer(Material.AirFilmFloorReduced, false)

        # Create and apply construction to surfaces
        if not cs_ceiling.create_and_assign_constructions(ceiling_surfaces, runner, model, "UnfinCSInsFinFloor")
            return false
        end
    end

    # Remove any materials which aren't used in any constructions
    HelperMethods.remove_unused_materials_and_constructions(model, runner)

    return true

  end #end the run method

end #end the measure

#this allows the measure to be use by the application
ProcessConstructionsCrawlspace.new.registerWithApplication