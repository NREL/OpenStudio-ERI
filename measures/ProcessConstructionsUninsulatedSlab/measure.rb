#see the URL below for information on how to write OpenStudio measures
# http://openstudio.nrel.gov/openstudio-measure-writing-guide

#see the URL below for information on using life cycle cost objects in OpenStudio
# http://openstudio.nrel.gov/openstudio-life-cycle-examples

#see the URL below for access to C++ documentation on model objects (click on "model" in the main window to view model objects)
# http://openstudio.nrel.gov/sites/openstudio.nrel.gov/files/nv_data/cpp_documentation_it/model/html/namespaces.html

require "#{File.dirname(__FILE__)}/resources/constants"
require "#{File.dirname(__FILE__)}/resources/util"
require "#{File.dirname(__FILE__)}/resources/geometry"

#start the measure
class ProcessConstructionsGarageSlab < OpenStudio::Ruleset::ModelUserScript
  
  #define the name that a user will see, this method may be deprecated as
  #the display name in PAT comes from the name field in measure.xml
  def name
    return "Set Residential Unfinished Slab Construction"
  end
  
  def description
    return "This measure assigns a construction to unfinished slabs."
  end
  
  def modeler_description
    return "Calculates and assigns material layer properties of slab constructions for floors between above-grade unfinished space and ground."
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

    surfaces = []
    spaces = []
    model.getSpaces.each do |space|
        next if Geometry.space_is_finished(space)
        next if Geometry.space_is_below_grade(space)
        space.surfaces.each do |surface|
            next if surface.surfaceType.downcase != "floor"
            next if surface.outsideBoundaryCondition.downcase != "ground"
            # Floors between above-grade unfinished space and ground
            surfaces << surface
            if not spaces.include? space
                spaces << space
            end
        end
    end

    # Continue if no applicable surfaces
    if surfaces.empty?
      runner.registerNotApplicable("Measure not applied because no applicable surfaces were found.")
      return true
    end       
    
    # Define construction
    slab = Construction.new([1.0])
    slab.addlayer(SimpleMaterial.Adiabatic, true)
    slab.addlayer(Material.Soil12in, true)
    slab.addlayer(Material.Concrete4in, true)
    
    # Create and assign construction to surfaces
    if not slab.create_and_assign_constructions(surfaces, runner, model, "GrndUninsUnfinGrgFloor")
        return false
    end
    
    # Remove any materials which aren't used in any constructions
    HelperMethods.remove_unused_materials_and_constructions(model, runner)     
    
    return true
 
  end #end the run method

end #end the measure

#this allows the measure to be use by the application
ProcessConstructionsGarageSlab.new.registerWithApplication