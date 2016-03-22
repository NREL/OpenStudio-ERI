#see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/reference/measure_writing_guide/

require "#{File.dirname(__FILE__)}/resources/util"
require "#{File.dirname(__FILE__)}/resources/constants"
require "#{File.dirname(__FILE__)}/resources/geometry"

#start the measure
class SetResidentialFloorCarpet < OpenStudio::Ruleset::ModelUserScript

  #define the name that a user will see, this method may be deprecated as
  #the display name in PAT comes from the name field in measure.xml
  def name
    return " Set Residential Floor Carpet"
  end
  
  def description
    return "This measure assigns carpet to floors of above-grade finished spaces."
  end
  
  def modeler_description
    return "Assigns material layer properties for floors of above-grade finished spaces."
  end    
  
  #define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Ruleset::OSArgumentVector.new

    #make a double argument for floor carpet fraction
    carpet_frac = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("carpet_frac", true)
    carpet_frac.setDisplayName("Floor Carpet Fraction")
    carpet_frac.setDescription("Fraction of floors that are carpeted.")
    carpet_frac.setDefaultValue(0.8)
    args << carpet_frac
    
    #make a double argument for carpet pad r-value
    carpet_r = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("carpet_r", true)
    carpet_r.setDisplayName("Carpet R-value")
    carpet_r.setUnits("h-ft^2-R/Btu")
    carpet_r.setDescription("The combined R-value of the carpet and pad.")
    carpet_r.setDefaultValue(2.08)
    args << carpet_r
    
    return args
  end #end the arguments method

  #define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)
    
    #use the built-in error checking 
    if not runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

    # Floors of above-grade finished spaces
    surfaces = []
    model.getSpaces.each do |space|
        next if Geometry.space_is_unfinished(space)
        next if Geometry.space_is_below_grade(space)
        space.surfaces.each do |surface|
            next if surface.surfaceType.downcase != "floor"
            surfaces << surface
        end
    end
    
    # Continue if no applicable surfaces
    if surfaces.empty?
      runner.registerAsNotApplicable("Measure not applied because no applicable surfaces were found.")
      return true
    end        
    
    # Get Inputs
    carpet_frac = runner.getDoubleArgumentValue("carpet_frac",user_arguments)
    carpet_r = runner.getDoubleArgumentValue("carpet_r",user_arguments)
    
    # Validate Inputs
    if carpet_frac < 0.0 or carpet_frac > 1.0
        runner.registerError("Floor Carpet Fraction must be greater than or equal to 0 and less than or equal to 1.")
        return false
    end
    if carpet_r < 0.0
        runner.registerError("Carpet R-value must be greater than or equal to 0.")
        return false
    end
    
    # Process the floors mass
    
    # Define Materials
    mat = nil
    if carpet_frac > 0 and carpet_r > 0
        mat = Material.CarpetBare(carpet_frac, carpet_r)
    end
    
    # Define construction
    floor = Construction.new([1])
    if not mat.nil?
        floor.addlayer(mat, true)
    else
        floor.removelayer(Constants.MaterialFloorCovering)
    end
    
    # Create and assign construction to surfaces
    if not floor.create_and_assign_constructions(surfaces, runner, model, name=nil)
        return false
    end
    
    # Remove any materials which aren't used in any constructions
    HelperMethods.remove_unused_materials_and_constructions(model, runner)    
    
    return true

  end #end the run method

end #end the measure

#this allows the measure to be use by the application
SetResidentialFloorCarpet.new.registerWithApplication