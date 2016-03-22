#see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/reference/measure_writing_guide/

require "#{File.dirname(__FILE__)}/resources/util"
require "#{File.dirname(__FILE__)}/resources/constants"
require "#{File.dirname(__FILE__)}/resources/geometry"

#start the measure
class ProcessConstructionsInteriorUninsulatedFloors < OpenStudio::Ruleset::ModelUserScript

  #define the name that a user will see, this method may be deprecated as
  #the display name in PAT comes from the name field in measure.xml
  def name
    return "Set Residential Partition Floor Construction"
  end
  
  def description
    return "This measure assigns a construction to floors between two unfinished spaces or two finished spaces."
  end
  
  def modeler_description
    return "Calculates and assigns material layer properties of uninsulated constructions for the floors 1) between two unfinished spaces, 2) between two finished spaces, or 3) with adiabatic outside boundary condition. If the floors have an existing construction, the layers (other than carpet, floor mass, and ceiling mass) are replaced. This measure is intended to be used in conjunction with Carpet, Floor Mass, and Ceiling Mass measures."
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
            next if surface.surfaceType.downcase != "floor"
            # Adiabatic floor adjacent to finished space
            if surface.outsideBoundaryCondition.downcase == "adiabatic"
                finished_surfaces << surface
                next
            end
            next if not surface.adjacentSurface.is_initialized
            adjacent_surface = surface.adjacentSurface.get
            adjacent_space = Geometry.get_space_from_surface(model, adjacent_surface.name.to_s, runner)
            next if Geometry.space_is_unfinished(adjacent_space)
            # Floor between two finished spaces
            finished_surfaces << surface
        end
    end
    
    unfinished_surfaces = []
    model.getSpaces.each do |space|
        next if Geometry.space_is_finished(space)
        space.surfaces.each do |surface|
            next if surface.surfaceType.downcase != "floor"
            # Adiabatic floor adjacent to unfinished space
            if surface.outsideBoundaryCondition.downcase == "adiabatic"
                unfinished_surfaces << surface
                next
            end
            next if not surface.adjacentSurface.is_initialized
            adjacent_surface = surface.adjacentSurface.get
            adjacent_space = Geometry.get_space_from_surface(model, adjacent_surface.name.to_s, runner)
            next if Geometry.space_is_finished(adjacent_space)
            # Floor between two unfinished spaces
            unfinished_surfaces << surface
        end
    end
    
    # Continue if no applicable surfaces
    if finished_surfaces.empty? and unfinished_surfaces.empty?
      runner.registerAsNotApplicable("Measure not applied because no applicable surfaces were found.")
      return true
    end 
    
    # Process the floors
    
    # Define materials
    mat_cavity = Material.AirCavity(Material.Stud2x6.thick_in)
    mat_framing = Material.new(name=nil, thick_in=Material.Stud2x6.thick_in, mat_base=BaseMaterial.Wood)
    
    # Set paths
    path_fracs = [Constants.DefaultFramingFactorFloor, 1 - Constants.DefaultFramingFactorFloor]

    if not finished_surfaces.empty?
        # Define construction
        fin_floor = Construction.new(path_fracs)
        fin_floor.addlayer(Material.AirFilmFloorAverage, false)
        fin_floor.addlayer(Material.DefaultCeilingMass, false) # thermal mass added in separate measure
        fin_floor.addlayer([mat_framing, mat_cavity], true, "StudAndAirFloor")
        fin_floor.addlayer(Material.Plywood3_4in, true)
        fin_floor.addlayer(Material.DefaultFloorMass, false) # thermal mass added in separate measure
        fin_floor.addlayer(Material.DefaultCarpet, false) # carpet added in separate measure
        fin_floor.addlayer(Material.AirFilmFloorAverage, false)

        # Create and apply construction to finished surfaces
        if not fin_floor.create_and_assign_constructions(finished_surfaces, runner, model, name="FinUninsFinFloor")
            return false
        end
    end
    
    if not unfinished_surfaces.empty?
        # Define construction
        unfin_floor = Construction.new(path_fracs)
        unfin_floor.addlayer(Material.AirFilmFloorAverage, false)
        unfin_floor.addlayer([mat_framing, mat_cavity], true, "StudAndAirFloor")
        unfin_floor.addlayer(Material.Plywood3_4in, true)
        unfin_floor.addlayer(Material.AirFilmFloorAverage, false)

        # Create and apply construction to unfinished surfaces
        if not unfin_floor.create_and_assign_constructions(unfinished_surfaces, runner, model, name="UnfinUninsUnfinFloor")
            return false
        end
    end
    
    # Remove any materials which aren't used in any constructions
    HelperMethods.remove_unused_materials_and_constructions(model, runner)    
    
    return true
 
  end #end the run method
  
end #end the measure

#this allows the measure to be use by the application
ProcessConstructionsInteriorUninsulatedFloors.new.registerWithApplication