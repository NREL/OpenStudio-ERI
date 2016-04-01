#see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/reference/measure_writing_guide/

require "#{File.dirname(__FILE__)}/resources/util"
require "#{File.dirname(__FILE__)}/resources/constants"
require "#{File.dirname(__FILE__)}/resources/geometry"

#start the measure
class ProcessConstructionsWallsExteriorDoubleWoodStud < OpenStudio::Ruleset::ModelUserScript

  #define the name that a user will see, this method may be deprecated as
  #the display name in PAT comes from the name field in measure.xml
  def name
    return "Set Residential Walls - Double Wood Stud Construction"
  end
  
  def description
    return "This measure assigns a double wood stud construction to above-grade exterior walls adjacent to finished space."
  end
  
  def modeler_description
    return "Calculates and assigns material layer properties of double wood stud constructions for above-grade walls between finished space and outside. If the walls have an existing construction, the layers (other than exterior finish, wall sheathing, and wall mass) are replaced. This measure is intended to be used in conjunction with Exterior Finish, Wall Sheathing, and Exterior Wall Mass measures."
  end   
  
  #define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Ruleset::OSArgumentVector.new

	#make a double argument for nominal R-value of installed cavity insulation
	userdefined_instcavr = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedinstcavr", true)
	userdefined_instcavr.setDisplayName("Cavity Insulation Nominal R-value")
	userdefined_instcavr.setUnits("hr-ft^2-R/Btu")
	userdefined_instcavr.setDescription("Refers to the R-value of the cavity insulation and not the overall R-value of the assembly.")
	userdefined_instcavr.setDefaultValue(33.0)
	args << userdefined_instcavr
    
	#make a choice argument for model objects
	installgrade_display_names = OpenStudio::StringVector.new
	installgrade_display_names << "I"
	installgrade_display_names << "II"
	installgrade_display_names << "III"
	
	#make a choice argument for wall cavity insulation installation grade
	selected_installgrade = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("selectedinstallgrade", installgrade_display_names, true)
	selected_installgrade.setDisplayName("Cavity Install Grade")
	selected_installgrade.setDescription("Installation grade as defined by RESNET standard. 5% of the cavity is considered missing insulation for Grade 3, 2% for Grade 2, and 0% for Grade 1.")
    selected_installgrade.setDefaultValue("I")
	args << selected_installgrade	

    #make a double argument for stud depth
    selected_studdepth = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("selectedstuddepth", true)
    selected_studdepth.setDisplayName("Stud Depth")
	selected_studdepth.setUnits("in")
	selected_studdepth.setDescription("Depth of the studs. 3.5\" for 2x4s, 5.5\" for 2x6s, etc. The total cavity depth of the double stud wall = (2 x stud depth) + gap depth.")
	selected_studdepth.setDefaultValue("3.5")
    args << selected_studdepth
    
    #make a double argument for gap depth
    userdefined_gapdepth = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedgapdepth", true)
    userdefined_gapdepth.setDisplayName("Gap Depth")
	userdefined_gapdepth.setUnits("in")
	userdefined_gapdepth.setDescription("Depth of the gap between walls.")
	userdefined_gapdepth.setDefaultValue(3.5)
    args << userdefined_gapdepth	
	
	#make a double argument for framing factor
	selected_ffactor = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("selectedffactor", true)
	selected_ffactor.setDisplayName("Framing Factor")
	selected_ffactor.setUnits("frac")
	selected_ffactor.setDescription("The fraction of a wall assembly that is comprised of structural framing for the individual (inner and outer) stud walls.")
	selected_ffactor.setDefaultValue("0.22")
	args << selected_ffactor

	#make a double argument for framing spacing
	selected_spacing = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("selectedspacing", true)
	selected_spacing.setDisplayName("Framing Spacing")
	selected_spacing.setUnits("in")
	selected_spacing.setDescription("The on-center spacing between framing in a wall assembly.")
	selected_spacing.setDefaultValue("24")
	args << selected_spacing

    #make a bool argument for staggering of studs
    userdefined_wallstaggered = OpenStudio::Ruleset::OSArgument::makeBoolArgument("userdefinedwallstaggered", true)
    userdefined_wallstaggered.setDisplayName("Staggered Studs")
	userdefined_wallstaggered.setDescription("Indicates that the double studs are aligned in a staggered fashion (as opposed to being center).") 
    userdefined_wallstaggered.setDefaultValue(false)
    args << userdefined_wallstaggered

    return args
  end #end the arguments method

  #define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)
    
    #use the built-in error checking 
    if not runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end
    
    # Above-grade wall between finished space and outdoors
    surfaces = []
    model.getSpaces.each do |space|
        next if Geometry.space_is_unfinished(space)
        next if Geometry.space_is_below_grade(space)
        space.surfaces.each do |surface|
            if surface.surfaceType.downcase == "wall" and surface.outsideBoundaryCondition.downcase == "outdoors"
                surfaces << surface
            end
        end
    end
    
    # Continue if no applicable surfaces
    if surfaces.empty?
      runner.registerAsNotApplicable("Measure not applied because no applicable surfaces were found.")
      return true
    end 
    
    # Get inputs
    dsWallCavityInsRvalue = runner.getDoubleArgumentValue("userdefinedinstcavr",user_arguments)
	dsWallInstallGrade = {"I"=>1, "II"=>2, "III"=>3}[runner.getStringArgumentValue("selectedinstallgrade",user_arguments)]
    dsWallStudDepth = runner.getDoubleArgumentValue("selectedstuddepth",user_arguments)
	dsWallGapDepth = runner.getDoubleArgumentValue("userdefinedgapdepth",user_arguments)
    dsWallFramingFactor = runner.getDoubleArgumentValue("selectedffactor",user_arguments)
    dsWallStudSpacing = runner.getDoubleArgumentValue("selectedspacing",user_arguments)
    dsWallIsStaggered = runner.getBoolArgumentValue("userdefinedwallstaggered",user_arguments)
    
    # Validate inputs
    if dsWallCavityInsRvalue <= 0.0
        runner.registerError("Cavity Insulation Nominal R-value must be greater than 0.")
        return false
    end
    if dsWallStudDepth <= 0.0
        runner.registerError("Stud Depth must be greater than 0.")
        return false
    end
    if dsWallGapDepth < 0.0
        runner.registerError("Gap Depth must be greater than or equal to 0.")
        return false
    end
    if dsWallFramingFactor < 0.0 or dsWallFramingFactor >= 1.0
        runner.registerError("Framing Factor must be greater than or equal to 0 and less than 1.")
        return false
    end
    if dsWallStudSpacing <= 0.0
        runner.registerError("Framing Spacing must be greater than 0.")
        return false
    end

    # Process the double wood stud walls
    
    # Define materials
    cavityDepth = 2.0 * dsWallStudDepth + dsWallGapDepth
    mat_ins_inner_outer = Material.new(name=nil, thick_in=dsWallStudDepth, mat_base=BaseMaterial.InsulationGenericDensepack, k_in=cavityDepth / dsWallCavityInsRvalue)
    mat_ins_middle = Material.new(name=nil, thick_in=dsWallGapDepth, mat_base=BaseMaterial.InsulationGenericDensepack, k_in=cavityDepth / dsWallCavityInsRvalue)
    mat_framing_inner_outer = Material.new(name=nil, thick_in=dsWallStudDepth, mat_base=BaseMaterial.Wood)
    mat_framing_middle = Material.new(name=nil, thick_in=dsWallGapDepth, mat_base=BaseMaterial.Wood)
    mat_stud = Material.new(name=nil, thick_in=dsWallStudDepth, mat_base=BaseMaterial.Wood)
    mat_gap_total = Material.AirCavity(cavityDepth)
    mat_gap_inner_outer = Material.new(name=nil, thick_in=dsWallStudDepth, mat_base=nil, k_in=dsWallStudDepth / (mat_gap_total.rvalue * dsWallStudDepth / cavityDepth), rho=Gas.Air.rho, cp=Gas.Air.cp)
    mat_gap_middle = Material.new(name=nil, thick_in=dsWallGapDepth, mat_base=nil, k_in=dsWallGapDepth / (mat_gap_total.rvalue * dsWallGapDepth / cavityDepth), rho=Gas.Air.rho, cp=Gas.Air.cp)
    
    # Set paths
    stud_frac = 1.5 / dsWallStudSpacing
    dsWallMiscFramingFactor = dsWallFramingFactor - stud_frac
    if dsWallMiscFramingFactor < 0
        runner.registerError("Framing Factor (#{dsWallFramingFactor.to_s}) is less than the framing solely provided by the studs (#{stud_frac.to_s}).")
        return false
    end
    dsGapFactor = Construction.get_wall_gap_factor(dsWallInstallGrade, dsWallFramingFactor, dsWallCavityInsRvalue)
    path_fracs = [dsWallMiscFramingFactor, stud_frac, stud_frac, dsGapFactor, (1.0 - (2 * stud_frac + dsWallMiscFramingFactor + dsGapFactor))] 
    
    # Define construction
    double_stud_wall = Construction.new(path_fracs)
    double_stud_wall.add_layer(Material.AirFilmVertical, false)
    double_stud_wall.add_layer(Material.DefaultWallMass, false) # thermal mass added in separate measure
    double_stud_wall.add_layer([mat_framing_inner_outer, mat_stud, mat_ins_inner_outer, mat_gap_inner_outer, mat_ins_inner_outer], true, "StudandCavityInner")
    if dsWallGapDepth > 0
        double_stud_wall.add_layer([mat_framing_middle, mat_ins_middle, mat_ins_middle, mat_gap_middle, mat_ins_middle], true, "Cavity")
    end
    if dsWallIsStaggered
        double_stud_wall.add_layer([mat_framing_inner_outer, mat_ins_inner_outer, mat_stud, mat_gap_inner_outer, mat_ins_inner_outer], true, "StudandCavityOuter")
    else
        double_stud_wall.add_layer([mat_framing_inner_outer, mat_stud, mat_ins_inner_outer, mat_gap_inner_outer, mat_ins_inner_outer], true, "StudandCavityOuter")
    end
    double_stud_wall.add_layer(Material.DefaultWallSheathing, false) # OSB added in separate measure
    double_stud_wall.add_layer(Material.DefaultExteriorFinish, false) # exterior finish added in separate measure
    double_stud_wall.add_layer(Material.AirFilmOutside, false)

    # Create and assign construction to surfaces
    if not double_stud_wall.create_and_assign_constructions(surfaces, runner, model, name="ExtInsFinWall")
        return false
    end

    # Remove any constructions/materials that aren't used
    HelperMethods.remove_unused_constructions_and_materials(model, runner)

    return true
 
  end #end the run method

end #end the measure

#this allows the measure to be use by the application
ProcessConstructionsWallsExteriorDoubleWoodStud.new.registerWithApplication