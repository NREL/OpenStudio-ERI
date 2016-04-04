#see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/reference/measure_writing_guide/

require "#{File.dirname(__FILE__)}/resources/util"
require "#{File.dirname(__FILE__)}/resources/constants"
require "#{File.dirname(__FILE__)}/resources/geometry"

#start the measure
class ProcessConstructionsWallsPartition < OpenStudio::Ruleset::ModelUserScript

  #define the name that a user will see, this method may be deprecated as
  #the display name in PAT comes from the name field in measure.xml
  def name
    return "Set Residential Walls - Partition Construction"
  end
  
  def description
    return "This measure assigns a construction to the walls between two unfinished spaces or two finished spaces."
  end
  
  def modeler_description
    return "Calculates and assigns material layer properties of uninsulated constructions for the walls 1) between two unfinished spaces, 2) between two finished spaces, or 3) with adiabatic outside boundary condition."
  end    
  
  #define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Ruleset::OSArgumentVector.new

    return args
  end #end the arguments method

  #define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)
    
    #use the built-in error checking 
    if not runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

    finished_surfaces = []
    model.getSpaces.each do |space|
        next if Geometry.space_is_unfinished(space)
        space.surfaces.each do |surface|
            next if surface.surfaceType.downcase != "wall"
            # Adiabatic wall adjacent to finished space
            if surface.outsideBoundaryCondition.downcase == "adiabatic"
                finished_surfaces << surface
                next
            end
            next if not surface.adjacentSurface.is_initialized
            next if not surface.adjacentSurface.get.space.is_initialized
            adjacent_space = surface.adjacentSurface.get.space.get
            next if Geometry.space_is_unfinished(adjacent_space)
            # Wall between two finished spaces
            finished_surfaces << surface
        end
    end
    
    unfinished_surfaces = []
    model.getSpaces.each do |space|
        next if Geometry.space_is_finished(space)
        space.surfaces.each do |surface|
            next if surface.surfaceType.downcase != "wall"
            # Adiabatic wall adjacent to unfinished space
            if surface.outsideBoundaryCondition.downcase == "adiabatic"
                unfinished_surfaces << surface
                next
            end
            next if not surface.adjacentSurface.is_initialized
            next if not surface.adjacentSurface.get.space.is_initialized
            adjacent_space = surface.adjacentSurface.get.space.get
            next if Geometry.space_is_finished(adjacent_space)
            # Wall between two unfinished spaces
            unfinished_surfaces << surface
        end
    end

    # Continue if no applicable surfaces
    if unfinished_surfaces.empty? and finished_surfaces.empty?
      runner.registerAsNotApplicable("Measure not applied because no applicable surfaces were found.")
      return true
    end     
    
    # Process the walls

    # Define materials
    mat_cavity = Material.AirCavityClosed(Material.Stud2x4.thick_in)
    mat_framing = Material.new(name=nil, thick_in=Material.Stud2x4.thick_in, mat_base=BaseMaterial.Wood)
    
    # Set paths
    path_fracs = [Constants.DefaultFramingFactorInterior, 1 - Constants.DefaultFramingFactorInterior]
    
    # Define construction
    wall = Construction.new(path_fracs)
    wall.add_layer([mat_framing, mat_cavity], true, "IntStudAndAirWall")

    # Create and apply construction to unfinished surfaces
    if not wall.create_and_assign_constructions(unfinished_surfaces, runner, model, name="UnfinUninsUnfinWall")
        return false
    end

    # Create and apply construction to finished surfaces
    if not wall.create_and_assign_constructions(finished_surfaces, runner, model, name="FinUninsFinWall")
        return false
    end

    # Remove any constructions/materials that aren't used
    HelperMethods.remove_unused_constructions_and_materials(model, runner)
    
    return true
 
  end #end the run method

end #end the measure

#this allows the measure to be use by the application
ProcessConstructionsWallsPartition.new.registerWithApplication