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
class ProcessConstructionsInteriorInsulatedWalls < OpenStudio::Ruleset::ModelUserScript

  #define the name that a user will see, this method may be deprecated as
  #the display name in PAT comes from the name field in measure.xml
  def name
    return "Set Residential Interzonal Wall Construction"
  end
  
  def description
    return "This measure assigns a construction to interzonal walls."
  end
  
  def modeler_description
    return "Calculates and assigns material layer properties of insulated constructions for walls between finished and unfinished spaces."
  end  
  
  #define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Ruleset::OSArgumentVector.new

    #make a choice argument for model objects
    studsize_display_names = OpenStudio::StringVector.new
    studsize_display_names << "2x4"
    studsize_display_names << "2x6"
    studsize_display_names << "2x8"
    studsize_display_names << "2x10"
    studsize_display_names << "2x12"
    studsize_display_names << "2x14"

    #make a string argument for wood stud size of wall cavity
    selected_studsize = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("selectedstudsize", studsize_display_names, true)
    selected_studsize.setDisplayName("Cavity Depth")
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
    selected_spacing.setDisplayName("Stud Spacing")
    selected_spacing.setUnits("in")
    selected_spacing.setDescription("The on-center spacing between studs in a wall assembly.")
    selected_spacing.setDefaultValue("16 in o.c.")
    args << selected_spacing

    #make a double argument for nominal R-value of installed cavity insulation
    userdefined_instcavr = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedinstcavr", true)
    userdefined_instcavr.setDisplayName("Cavity Insulation Installed R-value")
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
    selected_installgrade.setDisplayName("Cavity Install Grade")
    selected_installgrade.setDescription("5% of the wall is considered missing insulation for Grade 3, 2% for Grade 2, and 0% for Grade 1.")
    selected_installgrade.setDefaultValue("I")
    args << selected_installgrade

    #make a bool argument for whether the cavity insulation fills the cavity
    selected_insfills = OpenStudio::Ruleset::OSArgument::makeBoolArgument("selectedinsfills", true)
    selected_insfills.setDisplayName("Insulation Fills Cavity")
    selected_insfills.setDescription("Specifies whether the cavity insulation completely fills the depth of the wall cavity.")
    selected_insfills.setDefaultValue(true)
    args << selected_insfills

    return args
  end #end the arguments method

  #define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)
    
    #use the built-in error checking 
    if not runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

    surfaces = []
    model.getSpaces.each do |space|
        next if Geometry.space_is_unfinished(space)
        space.surfaces.each do |surface|
            next if surface.surfaceType.downcase != "wall"
            next if not surface.adjacentSurface.is_initialized
            adjacent_space = Geometry.get_space_from_surface(model, surface.adjacentSurface.get.name.to_s, runner)
            next if Geometry.space_is_finished(adjacent_space)
            # Wall between finished space and unfinished space
            surfaces << surface
        end
    end
    
    # Continue if no applicable surfaces
    if surfaces.empty?
        return true
    end        
    
    # Cavity
    intWallCavityDepth = {"2x4"=>3.5, "2x6"=>5.5, "2x8"=>7.25, "2x10"=>9.25, "2x12"=>11.25, "2x14"=>13.25, "2x16"=>15.25}[runner.getStringArgumentValue("selectedstudsize",user_arguments)]
    intWallFramingFactor = {"16 in o.c."=>0.25, "24 in o.c."=>0.22}[runner.getStringArgumentValue("selectedspacing",user_arguments)]
    intWallCavityInsRvalueInstalled = runner.getDoubleArgumentValue("userdefinedinstcavr",user_arguments)
    intWallInstallGrade = {"I"=>1, "II"=>2, "III"=>3}[runner.getStringArgumentValue("selectedinstallgrade",user_arguments)]
    intWallCavityInsFillsCavity = runner.getBoolArgumentValue("selectedinsfills",user_arguments)
    if not ( intWallFramingFactor > 0.0 and intWallFramingFactor < 1.0 )
        runner.registerError("Invalid framing factor.")
        return false
    end

    # Process the walls

    # Define materials
    if intWallCavityInsRvalueInstalled > 0
        if intWallCavityInsFillsCavity
            # Insulation
            mat_cavity = Material.new(name=nil, thick_in=intWallCavityDepth, mat_base=BaseMaterial.InsulationGenericDensepack, cond=OpenStudio::convert(intWallCavityDepth,"in","ft").get / intWallCavityInsRvalueInstalled)
        else
            # Insulation plus air gap when insulation thickness < cavity depth
            mat_cavity = Material.new(name=nil, thick_in=intWallCavityDepth, mat_base=BaseMaterial.InsulationGenericDensepack, cond=OpenStudio::convert(intWallCavityDepth,"in","ft").get / (intWallCavityInsRvalueInstalled + Gas.AirGapRvalue))
        end
    else
        # Empty cavity
        mat_cavity = Material.AirCavity(intWallCavityDepth)
    end
    mat_framing = Material.new(name=nil, thick_in=intWallCavityDepth, mat_base=BaseMaterial.Wood)
    mat_gap = Material.AirCavity(intWallCavityDepth)
    
    # Set paths
    gapFactor = Construction.GetWallGapFactor(intWallInstallGrade, intWallFramingFactor)
    path_fracs = [intWallFramingFactor, 1 - intWallFramingFactor - gapFactor, gapFactor]
    
    # Define construction
    interzonal_wall = Construction.new(path_fracs)
    interzonal_wall.addlayer(Material.AirFilmVertical, false)
    interzonal_wall.addlayer(Material.DefaultWallMass, false) # thermal mass added in separate measure
    interzonal_wall.addlayer([mat_framing, mat_cavity, mat_gap], true, "IntWallIns")
    interzonal_wall.addlayer(Material.DefaultWallSheathing, false) # OSB added in separate measure
    interzonal_wall.addlayer(Material.AirFilmVertical, false)

    # Create and apply construction to surfaces
    if not interzonal_wall.create_and_assign_constructions(surfaces, runner, model, "UnfinInsFinWall")
        return false
    end

    
    # Remove any materials which aren't used in any constructions
    HelperMethods.remove_unused_materials_and_constructions(model, runner)

    return true
 
  end #end the run method
  
end #end the measure

#this allows the measure to be use by the application
ProcessConstructionsInteriorInsulatedWalls.new.registerWithApplication