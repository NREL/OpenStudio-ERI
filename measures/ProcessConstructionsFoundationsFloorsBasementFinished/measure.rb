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
class ProcessConstructionsFinishedBasement < OpenStudio::Ruleset::ModelUserScript

  #define the name that a user will see, this method may be deprecated as
  #the display name in PAT comes from the name field in measure.xml
  def name
    return "Set Residential Finished Basement Constructions"
  end

  def description
    return "This measure assigns constructions to finished basement walls and floors."
  end
  
  def modeler_description
    return "Calculates and assigns material layer properties of constructions for: 1) walls between below-grade finished space and ground, and 2) floors below below-grade finished space. Below-grade spaces are assumed to be basements (and not crawlspaces) if the space height is greater than or equal to #{Constants.MinimumBasementHeight.to_s} ft."
  end   
  
  #define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Ruleset::OSArgumentVector.new

    #make a choice argument for model objects
    fbsmtins_display_names = OpenStudio::StringVector.new
    fbsmtins_display_names << "Uninsulated"
    fbsmtins_display_names << "Half Wall"
    fbsmtins_display_names << "Whole Wall"

    #make a choice argument for finished basement insulation type
    selected_fbsmtins = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("selectedfbsmtins", fbsmtins_display_names, true)
    selected_fbsmtins.setDisplayName("Insulation Type")
	selected_fbsmtins.setDescription("The type of insulation.")
	selected_fbsmtins.setDefaultValue("Whole Wall")
    args << selected_fbsmtins

    #make a choice argument for model objects
    studsize_display_names = OpenStudio::StringVector.new
    studsize_display_names << "None"
    studsize_display_names << "2x4, 16 in o.c."
    studsize_display_names << "2x6, 24 in o.c."

    #make a string argument for wood stud size of wall cavity
    selected_studsize = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("selectedstudsize", studsize_display_names, false)
    selected_studsize.setDisplayName("Cavity Depth")
	selected_studsize.setUnits("in")
	selected_studsize.setDescription("Depth of the stud cavity.")
    selected_studsize.setDefaultValue("None")
    args << selected_studsize

    #make a double argument for unfinished basement whole wall cavity insulation R-value
    userdefined_fbsmtwallcavr = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedfbsmtwallcavr", false)
    userdefined_fbsmtwallcavr.setDisplayName("Cavity Insulation Installed R-value")
	userdefined_fbsmtwallcavr.setUnits("hr-ft^2-R/Btu")
	userdefined_fbsmtwallcavr.setDescription("R-value is a measure of insulation's ability to resist heat traveling through it.")
    userdefined_fbsmtwallcavr.setDefaultValue(0)
    args << userdefined_fbsmtwallcavr

    #make a choice argument for model objects
    installgrade_display_names = OpenStudio::StringVector.new
    installgrade_display_names << "I"
    installgrade_display_names << "II"
    installgrade_display_names << "III"

	#make a choice argument for wall cavity insulation installation grade
	selected_installgrade = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("selectedinstallgrade", installgrade_display_names, true)
	selected_installgrade.setDisplayName("Cavity Install Grade")
	selected_installgrade.setDescription("5% of the wall is considered missing insulation for Grade 3, 2% for Grade 2, and 0% for Grade 1.")
    selected_installgrade.setDefaultValue("I")
	args << selected_installgrade

	#make a bool argument for whether the cavity insulation fills the cavity
	selected_insfills = OpenStudio::Ruleset::OSArgument::makeBoolArgument("selectedinsfills", true)
	selected_insfills.setDisplayName("Insulation Fills Cavity")
	selected_insfills.setDescription("When the insulation does not completely fill the depth of the cavity, air film resistances are added to the insulation R-value.")
    selected_insfills.setDefaultValue(false)
	args << selected_insfills

    #make a double argument for finished basement wall continuous R-value
    userdefined_fbsmtwallcontth = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedfbsmtwallcontth", false)
    userdefined_fbsmtwallcontth.setDisplayName("Continuous Insulation Thickness")
	userdefined_fbsmtwallcontth.setUnits("in")
	userdefined_fbsmtwallcontth.setDescription("The thickness of the continuous insulation.")
    userdefined_fbsmtwallcontth.setDefaultValue(2.0)
    args << userdefined_fbsmtwallcontth

    #make a double argument for finished basement wall continuous insulation R-value
    userdefined_fbsmtwallcontr = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedfbsmtwallcontr", false)
    userdefined_fbsmtwallcontr.setDisplayName("Continuous Insulation Nominal R-value")
	userdefined_fbsmtwallcontr.setUnits("hr-ft^2-R/Btu")
	userdefined_fbsmtwallcontr.setDescription("R-value is a measure of insulation's ability to resist heat traveling through it.")
    userdefined_fbsmtwallcontr.setDefaultValue(10.0)
    args << userdefined_fbsmtwallcontr

    # Ceiling Joist Height
    #make a choice argument for model objects
    joistheight_display_names = OpenStudio::StringVector.new
    joistheight_display_names << "2x10"

	#make a choice argument for finished basement ceiling joist height
	selected_fbsmtceiljoistheight = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("selectedfbsmtceiljoistheight", joistheight_display_names, true)
	selected_fbsmtceiljoistheight.setDisplayName("Ceiling Joist Height")
	selected_fbsmtceiljoistheight.setUnits("in")
	selected_fbsmtceiljoistheight.setDescription("Height of the joist member.")
	selected_fbsmtceiljoistheight.setDefaultValue("2x10")
	args << selected_fbsmtceiljoistheight	

    # Ceiling Framing Factor
	#make a choice argument for finished basement ceiling framing factor
	userdefined_fbsmtceilff = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedfbsmtceilff", false)
    userdefined_fbsmtceilff.setDisplayName("Ceiling Framing Factor")
	userdefined_fbsmtceilff.setUnits("frac")
	userdefined_fbsmtceilff.setDescription("Fraction of ceiling that is framing.")
    userdefined_fbsmtceilff.setDefaultValue(0.13)
	args << userdefined_fbsmtceilff

    return args
  end #end the arguments method

  #define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)

    #use the built-in error checking 
    if not runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

    # Initialize
    wall_surfaces = []
    floor_surfaces = []
    spaces = Geometry.get_finished_basement_spaces(model)
    spaces.each do |space|
        space.surfaces.each do |surface|
            # Wall between below-grade finished space and ground
            if surface.surfaceType.downcase == "wall" and surface.outsideBoundaryCondition.downcase == "ground"
                wall_surfaces << surface
            end
            # Floor below below-grade finished space
            if surface.surfaceType.downcase == "floor" and surface.outsideBoundaryCondition.downcase == "ground"
                floor_surfaces << surface
            end
        end
    end
    
    # Continue if no applicable surfaces
    if wall_surfaces.empty? and floor_surfaces.empty?
      runner.registerNotApplicable("Measure not applied because no applicable surfaces were found.")
      return true
    end           
    
    fbsmtWallContInsRvalue = 0
    fbsmtWallCavityInsRvalueInstalled = 0
    fbsmtWallInsHeight = 0

    # Finished Basement Insulation
    selected_fbsmtins = runner.getStringArgumentValue("selectedfbsmtins",user_arguments)

    # Wall Cavity
    selected_studsize = runner.getStringArgumentValue("selectedstudsize",user_arguments)
    userdefined_fbsmtwallcavr = runner.getDoubleArgumentValue("userdefinedfbsmtwallcavr",user_arguments)
    fbsmtWallInstallGrade = {"I"=>1, "II"=>2, "III"=>3}[runner.getStringArgumentValue("selectedinstallgrade",user_arguments)]
    fbsmtWallCavityDepth = {"None"=>0, "2x4, 16 in o.c."=>3.5, "2x6, 24 in o.c."=>5.5}[selected_studsize]
    fbsmtWallFramingFactor = {"None"=>0, "2x4, 16 in o.c."=>0.25, "2x6, 24 in o.c."=>0.22}[selected_studsize]
    fbsmtWallCavityInsFillsCavity = runner.getBoolArgumentValue("selectedinsfills",user_arguments)

    # Whole Wall Cavity Insulation
    if ["Half Wall", "Whole Wall"].include? selected_fbsmtins.to_s
      userdefined_fbsmtwallcavr = runner.getDoubleArgumentValue("userdefinedfbsmtwallcavr",user_arguments)
    end

    # Wall Continuous Insulation
    if ["Half Wall", "Whole Wall"].include? selected_fbsmtins.to_s
      userdefined_fbsmtwallcontth = runner.getDoubleArgumentValue("userdefinedfbsmtwallcontth",user_arguments)
      userdefined_fbsmtwallcontr = runner.getDoubleArgumentValue("userdefinedfbsmtwallcontr",user_arguments)
      if selected_fbsmtins.to_s == "Half Wall"
        fbsmtWallInsHeight = 4
      elsif selected_fbsmtins.to_s == "Whole Wall"
        fbsmtWallInsHeight = 8
      end
    end

    # Ceiling Joist Height
    fbsmtCeilingJoistHeight = {"2x10"=>9.25}[runner.getStringArgumentValue("selectedfbsmtceiljoistheight",user_arguments)]

    # Ceiling Framing Factor
    fbsmtCeilingFramingFactor = runner.getDoubleArgumentValue("userdefinedfbsmtceilff",user_arguments)
    if not ( fbsmtCeilingFramingFactor > 0.0 and fbsmtCeilingFramingFactor < 1.0 )
      runner.registerError("Invalid finished basement ceiling framing factor")
      return false
    end

    # Cavity Insulation
    if selected_fbsmtins.to_s == "Half Wall" or selected_fbsmtins.to_s == "Whole Wall"
      fbsmtWallCavityInsRvalueInstalled = userdefined_fbsmtwallcavr
    end

    # Continuous Insulation
    if ["Half Wall", "Whole Wall"].include? selected_fbsmtins.to_s
      fbsmtWallContInsThickness = userdefined_fbsmtwallcontth
      fbsmtWallContInsRvalue = userdefined_fbsmtwallcontr
    end

    fbExtPerimeter = Geometry.calculate_perimeter(spaces)
    fbFloorArea = Geometry.calculate_floor_area(spaces)
    fbExtWallArea = Geometry.calculate_perimeter_wall_area(spaces)
    
    # -------------------------------
    # Process the basement walls
    # -------------------------------
    
    if not wall_surfaces.empty?
        # Define materials
        mat_framing = nil
        mat_cavity = nil
        mat_grap = nil
        mat_rigid = nil
        if fbsmtWallCavityDepth > 0
            if fbsmtWallCavityInsRvalueInstalled > 0
                if fbsmtWallCavityInsFillsCavity
                    # Insulation
                    mat_cavity = Material.new(name=nil, thick_in=fbsmtWallCavityDepth, mat_base=BaseMaterial.InsulationGenericDensepack, cond=OpenStudio::convert(fbsmtWallCavityDepth,"in","ft").get / fbsmtWallCavityInsRvalueInstalled)
                else
                    # Insulation plus air gap when insulation thickness < cavity depth
                    mat_cavity = Material.new(name=nil, thick_in=fbsmtWallCavityDepth, mat_base=BaseMaterial.InsulationGenericDensepack, cond=OpenStudio::convert(fbsmtWallCavityDepth,"in","ft").get / (fbsmtWallCavityInsRvalueInstalled + Gas.AirGapRvalue))
                end
            else
                # Empty cavity
                mat_cavity = Material.AirCavity(fbsmtWallCavityDepth)
            end
            mat_framing = Material.new(name=nil, thick_in=fbsmtWallCavityDepth, mat_base=BaseMaterial.Wood)
            mat_gap = Material.AirCavity(fbsmtWallCavityDepth)
        end
        if fbsmtWallContInsThickness > 0
            mat_rigid = Material.new(name=nil, thick_in=fbsmtWallContInsThickness, mat_base=BaseMaterial.InsulationRigid, cond=OpenStudio::convert(fbsmtWallContInsThickness,"in","ft").get / fbsmtWallContInsRvalue)
        end

        # Set paths
        gapFactor = Construction.GetWallGapFactor(fbsmtWallInstallGrade, fbsmtWallFramingFactor, fbsmtWallCavityInsRvalueInstalled)
        path_fracs = [fbsmtWallFramingFactor, 1 - fbsmtWallFramingFactor - gapFactor, gapFactor]
        
        # Define construction (only used to calculate assembly R-value)
        fbsmt_wall = Construction.new(path_fracs)
        fbsmt_wall.addlayer(Material.AirFilmVertical, false)
        fbsmt_wall.addlayer(Material.DefaultWallMass, false)
        if not mat_framing.nil? and not mat_cavity.nil? and not mat_gap.nil?
            fbsmt_wall.addlayer([mat_framing, mat_cavity, mat_gap], false)
        end
        if fbsmtWallCavityInsRvalueInstalled > 0 or fbsmtWallContInsRvalue > 0
            # For foundation walls, only add OSB if there is wall insulation.
            fbsmt_wall.addlayer(Material.DefaultWallSheathing, false)
        end
        if not mat_rigid.nil?
            fbsmt_wall.addlayer(mat_rigid, false)
        end

        overall_wall_Rvalue = fbsmt_wall.assembly_rvalue(runner)
        if overall_wall_Rvalue.nil?
            return false
        end
        
        # Calculate fictitious layer behind finished basement wall to achieve equivalent R-value. See Winkelmann article.
        conduction_factor = Construction.GetBasementConductionFactor(fbsmtWallInsHeight, overall_wall_Rvalue)
        if fbExtPerimeter > 0
            fb_effective_Rvalue = fbExtWallArea / (conduction_factor * fbExtPerimeter) # hr*ft^2*F/Btu
        else
            fb_effective_Rvalue = 1000 # hr*ft^2*F/Btu
        end
        mat_fic_insul_layer = nil
        if fbsmtWallContInsRvalue > 0 and fbsmtWallInsHeight == 8 # Insulation of 4ft height inside a 8ft basement is modeled completely in the fictitious layer
            thick_in = OpenStudio::convert(fbsmtWallContInsRvalue*BaseMaterial.InsulationRigid.k, "ft", "in").get
            mat_fic_insul_layer = Material.new(name="FBaseWallIns", thick_in=thick_in, mat_base=BaseMaterial.InsulationRigid)
            insul_layer_rvalue = fbsmtWallContInsRvalue
        else
            insul_layer_rvalue = 0
        end
        fb_US_Rvalue = Material.Concrete8in.rvalue + Material.AirFilmVertical.rvalue + insul_layer_rvalue + Material.DefaultWallMass.rvalue
        fb_fictitious_Rvalue = fb_effective_Rvalue - Material.Soil12in.rvalue - fb_US_Rvalue
        mat_fic_wall = SimpleMaterial.new(name="FBaseWall-FicR", rvalue=fb_fictitious_Rvalue)
        
        # Define actual construction
        fic_fbsmt_wall = Construction.new([1])
        fic_fbsmt_wall.addlayer(mat_fic_wall, true)
        fic_fbsmt_wall.addlayer(Material.Soil12in, true)
        fic_fbsmt_wall.addlayer(Material.Concrete8in, true)
        if not mat_fic_insul_layer.nil?
            fic_fbsmt_wall.addlayer(mat_fic_insul_layer, true)
        end
        fic_fbsmt_wall.addlayer(Material.DefaultWallMass, false) # thermal mass added in separate measure
        fic_fbsmt_wall.addlayer(Material.AirFilmVertical, false)

        # Create and assign construction to surfaces
        if not fic_fbsmt_wall.create_and_assign_constructions(wall_surfaces, runner, model, "GrndInsFinWall")
            return false
        end
    end

    # -------------------------------
    # Process the basement floor
    # -------------------------------
    
    if not floor_surfaces.empty?
        fb_total_ua = fbExtWallArea / fb_effective_Rvalue # Btu/hr*F
        fb_wall_Rvalue = fb_US_Rvalue + Material.Soil12in.rvalue
        fb_wall_UA = fbExtWallArea / fb_wall_Rvalue

        # Fictitious layer below basement floor to achieve equivalent R-value. See Winklemann article.
        if fb_fictitious_Rvalue < 0 # Not enough cond through walls, need to add in floor conduction
            fb_floor_Rvalue = fbFloorArea / (fb_total_ua - fb_wall_UA) - Material.Soil12in.rvalue - Material.Concrete4in.rvalue # hr*ft^2*F/Btu (assumes basement floor is a 4-in concrete slab)
        else
            fb_floor_Rvalue = 1000 # hr*ft^2*F/Btu
        end
        
        # Define materials
        mat_fic_floor = SimpleMaterial.new(name="CFloor-FicR", rvalue=fb_floor_Rvalue)

        # Define construction
        fb_floor = Construction.new([1.0])
        fb_floor.addlayer(mat_fic_floor, true)
        fb_floor.addlayer(Material.Soil12in, true)
        fb_floor.addlayer(Material.Concrete4in, true)
        
        # Create and assign construction to surfaces
        if not fb_floor.create_and_assign_constructions(floor_surfaces, runner, model, "GrndUninsFinBFloor")
            return false
        end
    end

    # Remove any materials which aren't used in any constructions
    HelperMethods.remove_unused_materials_and_constructions(model, runner)    
    
    return true

  end #end the run method

end #end the measure

#this allows the measure to be use by the application
ProcessConstructionsFinishedBasement.new.registerWithApplication