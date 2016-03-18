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
class ProcessConstructionsUnfinishedBasement < OpenStudio::Ruleset::ModelUserScript
  
  #define the name that a user will see, this method may be deprecated as
  #the display name in PAT comes from the name field in measure.xml
  def name
    return "Set Residential Unfinished Basement Constructions"
  end
  
  def description
    return "This measure assigns constructions to the unfinished basement ceilings, walls, and floors."
  end
  
  def modeler_description
    return "Calculates and assigns material layer properties of constructions for: 1) ceilings above below-grade unfinished space, 2) walls between below-grade unfinished space and ground, and 3) floors below below-grade unfinished space. Below-grade spaces are assumed to be basements (and not crawlspaces) if the space height is greater than or equal to #{Constants.MinimumBasementHeight.to_s} ft."
  end  
  
  #define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Ruleset::OSArgumentVector.new

    #make a choice argument for model objects
    ufbsmtins_display_names = OpenStudio::StringVector.new
    ufbsmtins_display_names << "Uninsulated"
    ufbsmtins_display_names << "Half Wall"
    ufbsmtins_display_names << "Whole Wall"
    ufbsmtins_display_names << "Ceiling"
    
    #make a choice argument for unfinished basement insulation type
    selected_ufbsmtins = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("selectedufbsmtins", ufbsmtins_display_names, true)
    selected_ufbsmtins.setDisplayName("Insulation Type")
    selected_ufbsmtins.setDescription("The type of insulation.")
    selected_ufbsmtins.setDefaultValue("Whole Wall")
    args << selected_ufbsmtins  

    #make a choice argument for model objects
    studsize_display_names = OpenStudio::StringVector.new
    studsize_display_names << "None"
    studsize_display_names << "2x4, 16 in o.c."
    studsize_display_names << "2x6, 24 in o.c."

    #make a string argument for wood stud size of wall cavity
    selected_studsize = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("selectedstudsize", studsize_display_names, false)
    selected_studsize.setDisplayName("Wall Cavity Depth")
    selected_studsize.setUnits("in")
    selected_studsize.setDescription("Depth of the study cavity.")
    selected_studsize.setDefaultValue("None")
    args << selected_studsize
    
    #make a double argument for unfinished basement ceiling / whole wall cavity insulation R-value
    userdefined_ufbsmtwallceilcavr = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedufbsmtwallceilcavr", false)
    userdefined_ufbsmtwallceilcavr.setDisplayName("Wall/Ceiling Cavity Insulation Nominal R-value")
    userdefined_ufbsmtwallceilcavr.setUnits("hr-ft^2-R/Btu")
    userdefined_ufbsmtwallceilcavr.setDescription("R-value is a measure of insulation's ability to resist heat traveling through it.")
    userdefined_ufbsmtwallceilcavr.setDefaultValue(0)
    args << userdefined_ufbsmtwallceilcavr
    
    #make a choice argument for model objects
    installgrade_display_names = OpenStudio::StringVector.new
    installgrade_display_names << "I"
    installgrade_display_names << "II"
    installgrade_display_names << "III" 
    
    #make a choice argument for wall cavity insulation installation grade
    selected_installgrade = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("selectedinstallgrade", installgrade_display_names, true)
    selected_installgrade.setDisplayName("Wall Cavity Install Grade")
    selected_installgrade.setDescription("5% of the wall is considered missing insulation for Grade 3, 2% for Grade 2, and 0% for Grade 1.")
    selected_installgrade.setDefaultValue("I")
    args << selected_installgrade
    
    #make a bool argument for whether the cavity insulation fills the cavity
    selected_insfills = OpenStudio::Ruleset::OSArgument::makeBoolArgument("selectedinsfills", true)
    selected_insfills.setDisplayName("Wall Insulation Fills Cavity")
    selected_insfills.setDescription("Specifies whether the cavity insulation completely fills the depth of the wall cavity.")
    selected_insfills.setDefaultValue(false)
    args << selected_insfills

    #make a double argument for unfinished basement wall continuous R-value
    userdefined_ufbsmtwallcontth = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedufbsmtwallcontth", false)
    userdefined_ufbsmtwallcontth.setDisplayName("Wall Continuous Insulation Thickness")
    userdefined_ufbsmtwallcontth.setUnits("in")
    userdefined_ufbsmtwallcontth.setDescription("The thickness of the continuous insulation.")
    userdefined_ufbsmtwallcontth.setDefaultValue(2.0)
    args << userdefined_ufbsmtwallcontth    
    
    #make a double argument for unfinished basement wall continuous insulation R-value
    userdefined_ufbsmtwallcontr = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedufbsmtwallcontr", false)
    userdefined_ufbsmtwallcontr.setDisplayName("Wall Continuous Insulation Nominal R-value")
    userdefined_ufbsmtwallcontr.setUnits("hr-ft^2-R/Btu")
    userdefined_ufbsmtwallcontr.setDescription("R-value is a measure of insulation's ability to resist heat traveling through it.")
    userdefined_ufbsmtwallcontr.setDefaultValue(10.0)
    args << userdefined_ufbsmtwallcontr 
    
    # Ceiling Joist Height
    #make a choice argument for model objects
    joistheight_display_names = OpenStudio::StringVector.new
    joistheight_display_names << "2x10"
    
    #make a choice argument for unfinished basement ceiling joist height
    selected_ufbsmtceiljoistheight = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("selectedufbsmtceiljoistheight", joistheight_display_names, true)
    selected_ufbsmtceiljoistheight.setDisplayName("Ceiling Joist Height")
    selected_ufbsmtceiljoistheight.setUnits("in")
    selected_ufbsmtceiljoistheight.setDescription("Height of the joist member.")
    selected_ufbsmtceiljoistheight.setDefaultValue("2x10")
    args << selected_ufbsmtceiljoistheight  
    
    # Ceiling Framing Factor
    #make a choice argument for unfinished basement ceiling framing factor
    userdefined_ufbsmtceilff = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedufbsmtceilff", false)
    userdefined_ufbsmtceilff.setDisplayName("Ceiling Framing Factor")
    userdefined_ufbsmtceilff.setUnits("frac")
    userdefined_ufbsmtceilff.setDescription("Fraction of ceiling that is framing.")
    userdefined_ufbsmtceilff.setDefaultValue(0.13)
    args << userdefined_ufbsmtceilff
    
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
    spaces = Geometry.get_unfinished_basement_spaces(model)
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
      runner.registerNotApplicable("Measure not applied because no applicable surfaces were found.")
      return true
    end   
    
    ufbsmtWallContInsRvalue = 0
    ufbsmtWallCavityInsRvalueInstalled = 0
    ufbsmtCeilingCavityInsRvalueNominal = 0
    ufbsmtWallInsHeight = 0

    # Unfinished Basement Insulation
    selected_ufbsmtins = runner.getStringArgumentValue("selectedufbsmtins",user_arguments)  
    
    # Wall Cavity
    selected_studsize = runner.getStringArgumentValue("selectedstudsize",user_arguments)
    userdefined_ufbsmtwallceilcavr = runner.getDoubleArgumentValue("userdefinedufbsmtwallceilcavr",user_arguments)
    ufbsmtWallCavityDepth = {"None"=>0, "2x4, 16 in o.c."=>3.5, "2x6, 24 in o.c."=>5.5}[selected_studsize]
    ufbsmtWallFramingFactor = {"None"=>0, "2x4, 16 in o.c."=>0.25, "2x6, 24 in o.c."=>0.22}[selected_studsize]
    ufbsmtWallInstallGrade = {"I"=>1, "II"=>2, "III"=>3}[runner.getStringArgumentValue("selectedinstallgrade",user_arguments)]  
    ufbsmtWallCavityInsFillsCavity = runner.getBoolArgumentValue("selectedinsfills",user_arguments)  

    # Whole Wall / Ceiling Cavity Insulation
    if ["Half Wall", "Whole Wall", "Ceiling"].include? selected_ufbsmtins.to_s
        userdefined_ufbsmtwallceilcavr = runner.getDoubleArgumentValue("userdefinedufbsmtwallceilcavr",user_arguments)
    end
    
    # Wall Continuous Insulation
    if ["Half Wall", "Whole Wall"].include? selected_ufbsmtins.to_s
        userdefined_ufbsmtwallcontth = runner.getDoubleArgumentValue("userdefinedufbsmtwallcontth",user_arguments)
        userdefined_ufbsmtwallcontr = runner.getDoubleArgumentValue("userdefinedufbsmtwallcontr",user_arguments)
        if selected_ufbsmtins.to_s == "Half Wall"
            ufbsmtWallInsHeight = 4
        elsif selected_ufbsmtins.to_s == "Whole Wall"
            ufbsmtWallInsHeight = 8
        end
    end 
    
    # Ceiling Joist Height
    ufbsmtCeilingJoistHeight = {"2x10"=>9.25}[runner.getStringArgumentValue("selectedufbsmtceiljoistheight",user_arguments)]    
    
    # Ceiling Framing Factor
    ufbsmtCeilingFramingFactor = runner.getDoubleArgumentValue("userdefinedufbsmtceilff",user_arguments)
    if not ( ufbsmtCeilingFramingFactor > 0.0 and ufbsmtCeilingFramingFactor < 1.0 )
      runner.registerError("Invalid unfinished basement ceiling framing factor")
      return false
    end
    
    # Cavity Insulation
    if selected_ufbsmtins.to_s == "Half Wall" or selected_ufbsmtins.to_s == "Whole Wall"
        ufbsmtWallCavityInsRvalueInstalled = userdefined_ufbsmtwallceilcavr
    elsif selected_ufbsmtins.to_s == "Ceiling"
        ufbsmtCeilingCavityInsRvalueNominal = userdefined_ufbsmtwallceilcavr
    end
    
    # Continuous Insulation
    if ["Half Wall", "Whole Wall"].include? selected_ufbsmtins.to_s
        ufbsmtWallContInsThickness = userdefined_ufbsmtwallcontth
        ufbsmtWallContInsRvalue = userdefined_ufbsmtwallcontr
    end 
    
    ubExtPerimeter = Geometry.calculate_perimeter(spaces)
    ubFloorArea = Geometry.calculate_floor_area(spaces)
    ubExtWallArea = Geometry.calculate_perimeter_wall_area(spaces)

    # -------------------------------
    # Process the basement walls
    # -------------------------------
    
    if not wall_surfaces.empty?
        # Define materials
        mat_framing = nil
        mat_cavity = nil
        mat_grap = nil
        mat_rigid = nil
        if ufbsmtWallCavityDepth > 0
            if ufbsmtWallCavityInsRvalueInstalled > 0
                if ufbsmtWallCavityInsFillsCavity
                    # Insulation
                    mat_cavity = Material.new(name=nil, thick_in=ufbsmtWallCavityDepth, mat_base=BaseMaterial.InsulationGenericDensepack, cond=OpenStudio::convert(ufbsmtWallCavityDepth,"in","ft").get / ufbsmtWallCavityInsRvalueInstalled)
                else
                    # Insulation plus air gap when insulation thickness < cavity depth
                    mat_cavity = Material.new(name=nil, thick_in=ufbsmtWallCavityDepth, mat_base=BaseMaterial.InsulationGenericDensepack, cond=OpenStudio::convert(ufbsmtWallCavityDepth,"in","ft").get / (ufbsmtWallCavityInsRvalueInstalled + Gas.AirGapRvalue))
                end
            else
                # Empty cavity
                mat_cavity = Material.AirCavity(ufbsmtWallCavityDepth)
            end
            mat_framing = Material.new(name=nil, thick_in=ufbsmtWallCavityDepth, mat_base=BaseMaterial.Wood)
            mat_gap = Material.AirCavity(ufbsmtWallCavityDepth)
        end
        if ufbsmtWallContInsThickness > 0
            mat_rigid = Material.new(name=nil, thick_in=ufbsmtWallContInsThickness, mat_base=BaseMaterial.InsulationRigid, cond=OpenStudio::convert(ufbsmtWallContInsThickness,"in","ft").get / ufbsmtWallContInsRvalue)
        end
        
        # Set paths
        gapFactor = Construction.GetWallGapFactor(ufbsmtWallInstallGrade, ufbsmtWallFramingFactor, ufbsmtWallCavityInsRvalueInstalled)
        path_fracs = [ufbsmtWallFramingFactor, 1 - ufbsmtWallFramingFactor - gapFactor, gapFactor]

        # Define construction (only used to calculate assembly R-value)
        ufbsmt_wall = Construction.new(path_fracs)
        ufbsmt_wall.addlayer(Material.AirFilmVertical, false)
        if ufbsmtWallCavityDepth > 0
            ufbsmt_wall.addlayer(Material.DefaultWallMass, false) # thermal mass added in separate measure
        end
        if not mat_framing.nil? and not mat_cavity.nil? and not mat_gap.nil?
            ufbsmt_wall.addlayer([mat_framing, mat_cavity, mat_gap], false)
        end
        if ufbsmtWallCavityInsRvalueInstalled > 0 or ufbsmtWallContInsRvalue > 0
            # For foundation walls, only add OSB if there is wall insulation.
            ufbsmt_wall.addlayer(Material.DefaultWallSheathing, false)
        end
        if not mat_rigid.nil?
            ufbsmt_wall.addlayer(mat_rigid, false)
        end

        overall_wall_Rvalue = ufbsmt_wall.assembly_rvalue(runner)
        if overall_wall_Rvalue.nil?
            return false
        end
        
        # Calculate fictitious layer behind finished basement wall to achieve equivalent R-value. See Winkelmann article.
        conduction_factor = Construction.GetBasementConductionFactor(ufbsmtWallInsHeight, overall_wall_Rvalue)
        if ubExtPerimeter > 0
            ub_effective_Rvalue = ubExtWallArea / (conduction_factor * ubExtPerimeter) # hr*ft^2*F/Btu
        else
            ub_effective_Rvalue = 1000 # hr*ft^2*F/Btu
        end
        # Insulation of 4ft height inside a 8ft basement is modeled completely in the fictitious layer
        mat_fic_insul_layer = nil
        if ufbsmtWallContInsRvalue > 0 and ufbsmtWallInsHeight == 8
            thick_in = OpenStudio::convert(ufbsmtWallContInsRvalue*BaseMaterial.InsulationRigid.k, "ft", "in").get
            mat_fic_insul_layer = Material.new(name="UFBaseWallIns", thick_in=thick_in, mat_base=BaseMaterial.InsulationRigid)
            insul_layer_rvalue = ufbsmtWallContInsRvalue
        else
            insul_layer_rvalue = 0
        end
        ub_US_Rvalue = Material.Concrete8in.rvalue + Material.AirFilmVertical.rvalue + insul_layer_rvalue # hr*ft^2*F/Btu
        ub_fictitious_Rvalue = ub_effective_Rvalue - Material.Soil12in.rvalue - ub_US_Rvalue # hr*ft^2*F/Btu
        mat_fic_wall = SimpleMaterial.new(name="UFBaseWall-FicR", rvalue=ub_fictitious_Rvalue)
        
        # Define actual construction
        fic_ufbsmt_wall = Construction.new([1])
        fic_ufbsmt_wall.addlayer(mat_fic_wall, true)
        fic_ufbsmt_wall.addlayer(Material.Soil12in, true)
        fic_ufbsmt_wall.addlayer(Material.Concrete8in, true)
        if not mat_fic_insul_layer.nil?
            fic_ufbsmt_wall.addlayer(mat_fic_insul_layer, true)
        end
        fic_ufbsmt_wall.addlayer(Material.DefaultWallMass, false) # thermal mass added in separate measure
        fic_ufbsmt_wall.addlayer(Material.AirFilmVertical, false)

        # Create and apply construction to surfaces
        if not fic_ufbsmt_wall.create_and_assign_constructions(wall_surfaces, runner, model, "GrndInsUnfinBWall")
            return false
        end
    end

    # -------------------------------
    # Process the basement floor
    # -------------------------------

    if not floor_surfaces.empty?
        ub_total_UA = ubExtWallArea / ub_effective_Rvalue # Btu/hr*F
        ub_wall_Rvalue = ub_US_Rvalue + Material.Soil12in.rvalue
        ub_wall_UA = ubExtWallArea / ub_wall_Rvalue
        
        # Fictitious layer below basement floor to achieve equivalent R-value. See Winklemann article.
        if ub_fictitious_Rvalue < 0 # Not enough cond through walls, need to add in floor conduction
            ub_floor_Rvalue = ubFloorArea / (ub_total_UA - ub_wall_UA) - Material.Soil12in.rvalue - Material.Concrete4in.rvalue # hr*ft^2*F/Btu (assumes basement floor is a 4-in concrete slab)
        else
            ub_floor_Rvalue = 1000 # hr*ft^2*F/Btu
        end
        
        # Define materials
        mat_fic_floor = SimpleMaterial.new(name="UFBaseFloor-FicR", rvalue=ub_floor_Rvalue)
        
        # Define construction
        ub_floor = Construction.new([1.0])
        ub_floor.addlayer(mat_fic_floor, true)
        ub_floor.addlayer(Material.Soil12in, true)
        ub_floor.addlayer(Material.Concrete4in, true)
        
        # Create and apply construction to surfaces
        if not ub_floor.create_and_assign_constructions(floor_surfaces, runner, model, "GrndUninsUnfinBFloor")
            return false
        end
    end
    
    # -------------------------------
    # Process the basement ceiling
    # -------------------------------
    
    if not ceiling_surfaces.empty?
        # Define materials
        mat_2x = Material.Stud2x(ufbsmtCeilingJoistHeight)
        if ufbsmtCeilingCavityInsRvalueNominal == 0
            mat_cavity = Material.new(name=nil, thick_in=mat_2x.thick_in, mat_base=BaseMaterial.InsulationGenericDensepack, cond=1000000000)
        else    
            mat_cavity = Material.new(name=nil, thick_in=mat_2x.thick_in, mat_base=BaseMaterial.InsulationGenericDensepack, cond=mat_2x.thick / ufbsmtCeilingCavityInsRvalueNominal)
        end
        mat_framing = Material.new(name=nil, thick_in=mat_2x.thick_in, mat_base=BaseMaterial.Wood)
        
        # Set paths
        path_fracs = [ufbsmtCeilingFramingFactor, 1 - ufbsmtCeilingFramingFactor]
        
        # Define construction
        ub_ceiling = Construction.new(path_fracs)
        ub_ceiling.addlayer(Material.AirFilmFloorReduced, false)
        ub_ceiling.addlayer([mat_framing, mat_cavity], true, "UFBsmtCeilingIns")
        ub_ceiling.addlayer(Material.Plywood3_4in, true)
        ub_ceiling.addlayer(Material.DefaultFloorMass, false) # thermal mass added in separate measure
        ub_ceiling.addlayer(Material.DefaultCarpet, false) # carpet added in separate measure
        ub_ceiling.addlayer(Material.AirFilmFloorReduced, false)
        
        # Create and apply construction to surfaces
        if not ub_ceiling.create_and_assign_constructions(ceiling_surfaces, runner, model, "UnfinBInsFinFloor")
            return false
        end
    end

    # Remove any materials which aren't used in any constructions
    HelperMethods.remove_unused_materials_and_constructions(model, runner)     

    return true
 
  end #end the run method
  
end #end the measure

#this allows the measure to be use by the application
ProcessConstructionsUnfinishedBasement.new.registerWithApplication