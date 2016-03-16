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
class ProcessConstructionsExteriorInsulatedWallsDoubleWoodStud < OpenStudio::Ruleset::ModelUserScript

  #define the name that a user will see, this method may be deprecated as
  #the display name in PAT comes from the name field in measure.xml
  def name
    return "Set Residential Exterior Double Wood Stud Wall Construction"
  end
  
  def description
    return "This measure assigns a double wood stud construction to above-grade exterior walls adjacent to finished space."
  end
  
  def modeler_description
    return "Calculates and assigns material layer properties of double wood stud constructions for above-grade walls between finished space and outside."
  end   
  
  #define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Ruleset::OSArgumentVector.new

	#make a choice argument for model objects
	studsize_display_names = OpenStudio::StringVector.new
	studsize_display_names << "2x4"	
	
    #make a string argument for wood stud size of wall cavity
    selected_studdepth = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("selectedstuddepth", studsize_display_names, true)
    selected_studdepth.setDisplayName("Stud Depth")
	selected_studdepth.setUnits("in")
	selected_studdepth.setDescription("Depth of the studs.")
	selected_studdepth.setDefaultValue("2x4")
    args << selected_studdepth
	
    #make a string argument for wood gap size of wall cavity
    userdefined_gapdepth = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedgapdepth", true)
    userdefined_gapdepth.setDisplayName("Gap Depth")
	userdefined_gapdepth.setUnits("in")
	userdefined_gapdepth.setDescription("Depth of the gap between walls.")
	userdefined_gapdepth.setDefaultValue(3.5)
    args << userdefined_gapdepth	
	
    #make a choice argument for model objects
    spacing_display_names = OpenStudio::StringVector.new
    spacing_display_names << "24 in o.c."

	#make a choice argument for wood stud spacing
	selected_spacing = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("selectedspacing", spacing_display_names, true)
	selected_spacing.setDisplayName("Stud Spacing")
	selected_spacing.setUnits("in")
	selected_spacing.setDescription("The on-center spacing between studs in a wall assembly.")
	selected_spacing.setDefaultValue("24 in o.c.")
	args << selected_spacing

    #make a bool argument for stagger of wall cavity
    userdefined_wallstaggered = OpenStudio::Ruleset::OSArgument::makeBoolArgument("userdefinedwallstaggered", true)
    userdefined_wallstaggered.setDisplayName("Staggered Studs")
	userdefined_wallstaggered.setDescription("Indicates that the double studs are aligned in a staggered fashion (as opposed to being center).") 
    userdefined_wallstaggered.setDefaultValue(false)
    args << userdefined_wallstaggered

	#make a double argument for nominal R-value of installed cavity insulation
	userdefined_instcavr = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedinstcavr", true)
	userdefined_instcavr.setDisplayName("Cavity Insulation Nominal R-value")
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
	selected_installgrade.setDisplayName("Cavity Install Grade")
	selected_installgrade.setDescription("5% of the wall is considered missing insulation for Grade 3, 2% for Grade 2, and 0% for Grade 1.")
    selected_installgrade.setDefaultValue("I")
	args << selected_installgrade	

    return args
  end #end the arguments method

  #define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)
    
    #use the built-in error checking 
    if not runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

    # Wall between finished space and outdoors
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
      return true
    end  
    
    # Cavity
    selected_spacing = runner.getStringArgumentValue("selectedspacing",user_arguments)
    dsWallFramingFactor = {"24 in o.c."=>0.22}[selected_spacing]
    dsWallStudSpacing = {"24 in o.c."=>24.0}[selected_spacing]
    dsWallStudDepth = {"2x4"=>3.5, "2x6"=>5.5, "2x8"=>7.25, "2x10"=>9.25, "2x12"=>11.25, "2x14"=>13.25, "2x16"=>15.25}[runner.getStringArgumentValue("selectedstuddepth",user_arguments)]
	dsWallGapDepth = runner.getDoubleArgumentValue("userdefinedgapdepth",user_arguments)
    dsWallCavityInsRvalue = runner.getDoubleArgumentValue("userdefinedinstcavr",user_arguments)
	dsWallInstallGrade = {"I"=>1, "II"=>2, "III"=>3}[runner.getStringArgumentValue("selectedinstallgrade",user_arguments)]
    dsWallIsStaggered = runner.getBoolArgumentValue("userdefinedwallstaggered",user_arguments)
    
    # Process the double wood stud walls
    
    # Define materials
    cavityDepth = 2.0 * dsWallStudDepth + dsWallGapDepth
    mat_ins_inner_outer = Material.new(name=nil, thick_in=dsWallStudDepth, mat_base=BaseMaterial.InsulationGenericDensepack, cond=OpenStudio::convert(cavityDepth,"in","ft").get / dsWallCavityInsRvalue)
    mat_ins_middle = Material.new(name=nil, thick_in=dsWallGapDepth, mat_base=BaseMaterial.InsulationGenericDensepack, cond=OpenStudio::convert(cavityDepth,"in","ft").get / dsWallCavityInsRvalue)
    mat_framing_inner_outer = Material.new(name=nil, thick_in=dsWallStudDepth, mat_base=BaseMaterial.Wood)
    mat_framing_middle = Material.new(name=nil, thick_in=dsWallGapDepth, mat_base=BaseMaterial.Wood)
    mat_stud = Material.new(name=nil, thick_in=dsWallStudDepth, mat_base=BaseMaterial.Wood)
    mat_gap_inner_outer = Material.AirCavity(dsWallStudDepth)
    mat_gap_middle = Material.AirCavity(dsWallGapDepth)
    
    # Set paths
    mat_2x = Material.Stud2x(dsWallStudDepth)
    stud_frac = 1.5 / dsWallStudSpacing
    dsWallMiscFramingFactor = dsWallFramingFactor - stud_frac
    dsGapFactor = Construction.GetWallGapFactor(dsWallInstallGrade, dsWallFramingFactor)
    path_fracs = [dsWallMiscFramingFactor, stud_frac, stud_frac, dsGapFactor, (1.0 - (2*stud_frac + dsWallMiscFramingFactor - dsGapFactor))] 
    
    # Define construction
    double_stud_wall = Construction.new(path_fracs)
    double_stud_wall.addlayer(Material.AirFilmVertical, false)
    double_stud_wall.addlayer(Material.DefaultWallMass, false) # thermal mass added in separate measure
    double_stud_wall.addlayer([mat_framing_inner_outer, mat_stud, mat_ins_inner_outer, mat_gap_inner_outer, mat_ins_inner_outer], true, "StudandCavityInner")
    double_stud_wall.addlayer([mat_framing_middle, mat_ins_middle, mat_ins_middle, mat_gap_middle, mat_ins_middle], true, "Cavity")
    if dsWallIsStaggered
        double_stud_wall.addlayer([mat_framing_inner_outer, mat_ins_inner_outer, mat_stud, mat_gap_inner_outer, mat_ins_inner_outer], true, "StudandCavityOuter")
    else
        double_stud_wall.addlayer([mat_framing_inner_outer, mat_stud, mat_ins_inner_outer, mat_gap_inner_outer, mat_ins_inner_outer], true, "StudandCavityOuter")
    end
    double_stud_wall.addlayer(Material.DefaultWallSheathing, false) # OSB added in separate measure
    double_stud_wall.addlayer(Material.DefaultExteriorFinish, false) # exterior finish added in separate measure
    double_stud_wall.addlayer(Material.AirFilmOutside, false)

    # Create and apply construction to surfaces
    if not double_stud_wall.create_and_assign_constructions(surfaces, runner, model, "ExtInsFinWall")
        return false
    end

    # Remove any materials which aren't used in any constructions
    HelperMethods.remove_unused_materials_and_constructions(model, runner)

    return true
 
  end #end the run method

end #end the measure

#this allows the measure to be use by the application
ProcessConstructionsExteriorInsulatedWallsDoubleWoodStud.new.registerWithApplication