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
class ProcessConstructionsInteriorInsulatedFloors < OpenStudio::Ruleset::ModelUserScript

  #define the name that a user will see, this method may be deprecated as
  #the display name in PAT comes from the name field in measure.xml
  def name
    return "Set Residential Interzonal Floor Construction"
  end
  
  def description
    return "This measure assigns a construction to interzonal floors."
  end
  
  def modeler_description
    return "Calculates and assigns material layer properties of insulated constructions for floors between above-grade finished and above-grade unfinished spaces."
  end    
  
  #define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Ruleset::OSArgumentVector.new

    #make a double argument for nominal R-value of cavity insulation
    userdefined_instcavr = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedinstcavr", true)
    userdefined_instcavr.setDisplayName("Cavity Insulation Nominal R-value")
    userdefined_instcavr.setUnits("hr-ft^2-R/Btu")
    userdefined_instcavr.setDescription("R-value is a measure of insulation's ability to resist heat traveling through it.")
    userdefined_instcavr.setDefaultValue(19.0)
    args << userdefined_instcavr

    #make a choice argument for unfinished attic ceiling framing factor
    userdefined_floorff = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedfloorff", false)
    userdefined_floorff.setDisplayName("Framing Factor")
    userdefined_floorff.setUnits("frac")
    userdefined_floorff.setDescription("The fraction of a floor assembly that is comprised of structural framing.")
    userdefined_floorff.setDefaultValue(0.13)
    args << userdefined_floorff
    
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

    # Floor between above-grade finished space and above-grade unfinished space
    surfaces = []
    model.getSpaces.each do |space|
        next if Geometry.space_is_unfinished(space)
        next if Geometry.space_is_below_grade(space)
        space.surfaces.each do |surface|
            next if surface.surfaceType.downcase != "floor" and surface.surfaceType.downcase != "roofceiling"
            next if not surface.adjacentSurface.is_initialized
            adjacent_space = Geometry.get_space_from_surface(model, surface.adjacentSurface.get.name.to_s, runner)
            next if Geometry.space_is_finished(adjacent_space)
            next if Geometry.space_is_below_grade(adjacent_space)
            surfaces << surface
        end
    end
    
    # Continue if no applicable surfaces
    if surfaces.empty?
      runner.registerNotApplicable("Measure not applied because no applicable surfaces were found.")
      return true
    end        
    
    # Cavity
    intFloorCavityInsRvalueNominal = runner.getDoubleArgumentValue("userdefinedinstcavr",user_arguments)
    selected_installgrade = runner.getStringArgumentValue("selectedinstallgrade",user_arguments)
    intFloorInstallGrade_dict = {"I"=>1, "II"=>2, "III"=>3}
    intFloorInstallGrade = intFloorInstallGrade_dict[selected_installgrade]
    intFloorFramingFactor = runner.getDoubleArgumentValue("userdefinedfloorff",user_arguments)
    if not ( intFloorFramingFactor > 0.0 and intFloorFramingFactor < 1.0 )
        runner.registerError("Invalid framing factor.")
        return false
    end
    
    # Process the floors
    
    # Define Materials
    if intFloorCavityInsRvalueNominal == 0
        mat_cavity = Material.new(name=nil, thick_in=Material.Stud2x6.thick_in, mat_base=BaseMaterial.InsulationGenericDensepack, cond=1000000000)
    else
        mat_cavity = Material.new(name=nil, thick_in=Material.Stud2x6.thick_in, mat_base=BaseMaterial.InsulationGenericDensepack, cond=Material.Stud2x6.thick / intFloorCavityInsRvalueNominal)
    end
    mat_framing = Material.new(name=nil, thick_in=Material.Stud2x6.thick_in, mat_base=BaseMaterial.Wood)
    mat_gap = Material.AirCavity(Material.Stud2x6.thick_in)
    
    # Set paths
    izfGapFactor = Construction.GetWallGapFactor(intFloorInstallGrade, intFloorFramingFactor, intFloorCavityInsRvalueNominal)
    path_fracs = [intFloorFramingFactor, 1 - intFloorFramingFactor - izfGapFactor, izfGapFactor]
    
    # Define construction
    izf_const = Construction.new(path_fracs)
    izf_const.addlayer(Material.AirFilmFloorReduced, false)
    izf_const.addlayer([mat_framing, mat_cavity, mat_gap], true, "IntFloorIns")
    izf_const.addlayer(Material.Plywood3_4in, false)
    izf_const.addlayer(Material.DefaultFloorMass, false) # thermal mass added in separate measure
    izf_const.addlayer(Material.DefaultCarpet, false) # carpet added in separate measure
    izf_const.addlayer(Material.AirFilmFloorReduced, false)
    
    # Create and apply construction to surfaces
    if not izf_const.create_and_assign_constructions(surfaces, runner, model, "UnfinInsFinFloor")
        return false
    end
    
    # Remove any materials which aren't used in any constructions
    HelperMethods.remove_unused_materials_and_constructions(model, runner)    
    
    return true

  end #end the run method

end #end the measure

#this allows the measure to be use by the application
ProcessConstructionsInteriorInsulatedFloors.new.registerWithApplication