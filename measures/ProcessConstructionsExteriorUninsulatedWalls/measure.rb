#see the URL below for information on how to write OpenStudio measures
# http://openstudio.nrel.gov/openstudio-measure-writing-guide

#see the URL below for information on using life cycle cost objects in OpenStudio
# http://openstudio.nrel.gov/openstudio-life-cycle-examples

#see the URL below for access to C++ documentation on model objects (click on "model" in the main window to view model objects)
# http://openstudio.nrel.gov/sites/openstudio.nrel.gov/files/nv_data/cpp_documentation_it/model/html/namespaces.html

require "#{File.dirname(__FILE__)}/resources/util"
require "#{File.dirname(__FILE__)}/resources/constants"

#start the measure
class ProcessConstructionsExteriorUninsulatedWalls < OpenStudio::Ruleset::ModelUserScript

  #define the name that a user will see, this method may be deprecated as
  #the display name in PAT comes from the name field in measure.xml
  def name
    return "Set Residential Unfinished Attic and Garage Wall Constructions"
  end
  
  def description
    return "This measure assigns a construction to the unfinished attic and garage exterior walls."
  end
  
  def modeler_description
    return "Calculates material layer properties of uninsulated, unfinished, stud and air constructions for the exterior walls of the attic and garage. Finds surfaces adjacent to the attic and garage and sets applicable constructions."
  end   
  
  #define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Ruleset::OSArgumentVector.new

    #make a choice argument for unfinished attic space type
    space_types = model.getSpaceTypes
    space_type_args = OpenStudio::StringVector.new
    space_types.each do |space_type|
        space_type_args << space_type.name.to_s
    end
    if not space_type_args.include?(Constants.UnfinishedAtticSpaceType)
        space_type_args << Constants.UnfinishedAtticSpaceType
    end
    unfin_attic_space_type = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("unfin_attic_space_type", space_type_args, true)
    unfin_attic_space_type.setDisplayName("Unfinished Attic space type")
    unfin_attic_space_type.setDescription("Select the unfinished attic space type")
    unfin_attic_space_type.setDefaultValue(Constants.UnfinishedAtticSpaceType)
    args << unfin_attic_space_type
    
    #make a choice argument for garage space type
    space_types = model.getSpaceTypes
    space_type_args = OpenStudio::StringVector.new
    space_types.each do |space_type|
        space_type_args << space_type.name.to_s
    end
    if not space_type_args.include?(Constants.GarageSpaceType)
        space_type_args << Constants.GarageSpaceType
    end
    garage_space_type = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("garage_space_type", space_type_args, true)
    garage_space_type.setDisplayName("Garage space type")
    garage_space_type.setDescription("Select the garage space type")
    garage_space_type.setDefaultValue(Constants.GarageSpaceType)
    args << garage_space_type

    return args
  end #end the arguments method

  #define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)
    
    #use the built-in error checking 
    if not runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

    # Exterior Finish
    extfin = nil
    constructions = model.getConstructions
    constructions.each do |construction|
      if construction.name.to_s == "ExtInsFinWall"
        construction.layers.each do |layer|
          if layer.name.to_s == "ExteriorFinish"
            extfin = layer
          end
        end
      end
    end
    if extfin.nil?
      runner.registerError("Could not find material layer 'ExteriorFinish'. Need to set exterior insulated walls first.")
      return false
    end

    # Space Type
	unfin_attic_space_type_r = runner.getStringArgumentValue("unfin_attic_space_type",user_arguments)
    unfin_attic_space_type = HelperMethods.get_space_type_from_string(model, unfin_attic_space_type_r, runner, false)
	garage_space_type_r = runner.getStringArgumentValue("garage_space_type",user_arguments)
    garage_space_type = HelperMethods.get_space_type_from_string(model, garage_space_type_r, runner, false)
	if unfin_attic_space_type.nil? and garage_space_type.nil?
        # If the building has no unfinished attic and no garage, no constructions are assigned and we continue by returning True
        return true
    end
    
    # Initialize hashes
    constructions_to_surfaces = {"ExtUninsUnfinWall"=>[]}
    constructions_to_objects = Hash.new     
    
    # Wall between unfinished attic and outdoors
	unless unfin_attic_space_type.nil?
	  unfin_attic_space_type.spaces.each do |unfin_attic_space|
	    unfin_attic_space.surfaces.each do |unfin_attic_surface|
            if unfin_attic_surface.surfaceType.downcase == "wall" and unfin_attic_surface.outsideBoundaryCondition.downcase == "outdoors"
                constructions_to_surfaces["ExtUninsUnfinWall"] << unfin_attic_surface
            end
	    end
	  end
	end
    
    # Wall between garage and outdoors
	unless garage_space_type.nil?
	  garage_space_type.spaces.each do |garage_space|
	    garage_space.surfaces.each do |garage_surface|
            if garage_surface.surfaceType.downcase == "wall" and garage_surface.outsideBoundaryCondition.downcase == "outdoors"
                constructions_to_surfaces["ExtUninsUnfinWall"] << garage_surface
            end
	    end	
	  end
	end
    
    # Continue if no applicable surfaces
    if constructions_to_surfaces.all? {|construction, surfaces| surfaces.empty?}
      return true
    end     
    
	# Plywood-1_2in
    mat_plywood1_2in = Material.Plywood1_2in
	ply1_2 = OpenStudio::Model::StandardOpaqueMaterial.new(model)
	ply1_2.setName("Plywood-1_2in")
	ply1_2.setRoughness("Rough")
	ply1_2.setThickness(OpenStudio::convert(mat_plywood1_2in.thick,"ft","m").get)
	ply1_2.setConductivity(OpenStudio::convert(mat_plywood1_2in.k,"Btu/hr*ft*R","W/m*K").get)
	ply1_2.setDensity(OpenStudio::convert(mat_plywood1_2in.rho,"lb/ft^3","kg/m^3").get)
	ply1_2.setSpecificHeat(OpenStudio::convert(mat_plywood1_2in.Cp,"Btu/lb*R","J/kg*K").get)

	# Stud and Air Wall
	saw = OpenStudio::Model::StandardOpaqueMaterial.new(model)
	saw.setName("StudandAirWall")
	saw.setRoughness("Rough")
	saw.setThickness(OpenStudio::convert(Material.StudAndAir.thick,"ft","m").get)
	saw.setConductivity(OpenStudio::convert(Material.StudAndAir.k,"Btu/hr*ft*R","W/m*K").get)
	saw.setDensity(OpenStudio::convert(Material.StudAndAir.rho,"lb/ft^3","kg/m^3").get)
	saw.setSpecificHeat(OpenStudio::convert(Material.StudAndAir.Cp,"Btu/lb*R","J/kg*K").get)
	
	# ExtUninsUnfinWall
	materials = []
	materials << extfin.to_StandardOpaqueMaterial.get
	materials << ply1_2
	materials << saw
    unless constructions_to_surfaces["ExtUninsUnfinWall"].empty?
        extinsfinwall = OpenStudio::Model::Construction.new(materials)
        extinsfinwall.setName("ExtUninsUnfinWall")
        constructions_to_objects["ExtUninsUnfinWall"] = extinsfinwall
    end    
    
    # Apply constructions to surfaces
    constructions_to_surfaces.each do |construction, surfaces|
        surfaces.each do |surface|
            surface.setConstruction(constructions_to_objects[construction])
            runner.registerInfo("Surface '#{surface.name}', of Space Type '#{HelperMethods.get_space_type_from_surface(model, surface.name.to_s, runner)}' and with Surface Type '#{surface.surfaceType}' and Outside Boundary Condition '#{surface.outsideBoundaryCondition}', was assigned Construction '#{construction}'")
        end
    end
    
    # Remove any materials which aren't used in any constructions
    HelperMethods.remove_unused_materials(model, runner)
	
    return true
 
  end #end the run method

end #end the measure

#this allows the measure to be use by the application
ProcessConstructionsExteriorUninsulatedWalls.new.registerWithApplication