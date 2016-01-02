#see the URL below for information on how to write OpenStudio measures
# http://openstudio.nrel.gov/openstudio-measure-writing-guide

#see the URL below for information on using life cycle cost objects in OpenStudio
# http://openstudio.nrel.gov/openstudio-life-cycle-examples

#see the URL below for access to C++ documentation on model objects (click on "model" in the main window to view model objects)
# http://openstudio.nrel.gov/sites/openstudio.nrel.gov/files/nv_data/cpp_documentation_it/model/html/namespaces.html

#load sim.rb
require "#{File.dirname(__FILE__)}/resources/sim"

#start the measure
class ProcessConstructionsDoors < OpenStudio::Ruleset::ModelUserScript

  class Door
    def initialize(doorUvalue)
		@doorUvalue = doorUvalue
    end
    
	attr_accessor(:mat_door_Uvalue, :door_thickness)
	
	def DoorUvalue
		return @doorUvalue
	end
  end

  class GarageDoor
    def initialize
    end
    attr_accessor(:garage_door_Uvalue, :garage_door_thickness)
  end

  #define the name that a user will see, this method may be deprecated as
  #the display name in PAT comes from the name field in measure.xml
  def name
    return "Assign Residential Door Construction"
  end
  
  def description
    return "This measure assigns a construction to exterior doors adjacent to the living space as well as garage doors."
  end
  
  def modeler_description
    return "Calculates material layer properties of constructions for exterior doors adjacent to the living space as well as garage doors. Finds sub surfaces adjacent to the living space and garage and sets applicable constructions."
  end
  
  #define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Ruleset::OSArgumentVector.new

	#make a choice argument for model objects
	doors_display_names = OpenStudio::StringVector.new
	doors_display_names << "Wood"
	doors_display_names << "Steel"
	doors_display_names << "Fiberglass"
	
    #make a string argument for wood stud size of wall cavity
    selected_door = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("selecteddoor", doors_display_names, true)
    selected_door.setDisplayName("Door Type")
	selected_door.setDescription("The front door type.")
	selected_door.setDefaultValue("Fiberglass")
    args << selected_door	

    #make a choice argument for living space type
    space_types = model.getSpaceTypes
    space_type_args = OpenStudio::StringVector.new
    space_types.each do |space_type|
        space_type_args << space_type.name.to_s
    end
    if not space_type_args.include?(Constants.LivingSpaceType)
        space_type_args << Constants.LivingSpaceType
    end
    living_space_type = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("living_space_type", space_type_args, true)
    living_space_type.setDisplayName("Living space type")
    living_space_type.setDescription("Select the living space type")
    living_space_type.setDefaultValue(Constants.LivingSpaceType)
    args << living_space_type

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

    # Space Type
	living_space_type_r = runner.getStringArgumentValue("living_space_type",user_arguments)
    living_space_type = HelperMethods.get_space_type_from_string(model, living_space_type_r, runner)
    if living_space_type.nil?
        return false
    end
	garage_space_type_r = runner.getStringArgumentValue("garage_space_type",user_arguments)
    garage_space_type = HelperMethods.get_space_type_from_string(model, garage_space_type_r, runner, false)
    
	selected_door = runner.getStringArgumentValue("selecteddoor",user_arguments)
	
	doorUvalue = {"Wood"=>0.48, "Steel"=>0.2, "Fiberglass"=>0.2}[selected_door]

    # Create the material class instances
    d = Door.new(doorUvalue)
    gd = GarageDoor.new

    # Create the sim object
    sim = Sim.new(model, runner)

    # Process the windows
    d, gd = sim._processConstructionsDoors(d, gd)

    # DoorMaterial
    mat_door_Uvalue = d.mat_door_Uvalue
    door_thickness = d.door_thickness
    d = OpenStudio::Model::StandardOpaqueMaterial.new(model)
    d.setName("DoorMaterial")
	d.setRoughness("Rough")
    d.setThickness(OpenStudio::convert(door_thickness,"ft","m").get)
    d.setConductivity(OpenStudio::convert(mat_door_Uvalue * door_thickness,"Btu/hr*ft*R","W/m*K").get)
    d.setDensity(OpenStudio::convert(get_mat_wood.rho,"lb/ft^3","kg/m^3").get)
    d.setSpecificHeat(OpenStudio::convert(get_mat_wood.Cp,"Btu/lb*R","J/kg*K").get)

    # LivingDoors
    door = OpenStudio::Model::Construction.new(model)
    door.setName("LivingDoors")
    door.insertLayer(0,d)

    # GarageDoorMaterial
    garage_door_Uvalue = gd.garage_door_Uvalue
    garage_door_thickness = gd.garage_door_thickness
    gd = OpenStudio::Model::StandardOpaqueMaterial.new(model)
    gd.setName("GarageDoorMaterial")
	gd.setRoughness("Rough")
    gd.setThickness(OpenStudio::convert(garage_door_thickness,"ft","m").get)
    gd.setConductivity(OpenStudio::convert(garage_door_Uvalue * garage_door_thickness,"Btu/hr*ft*R","W/m*K").get)
    gd.setDensity(OpenStudio::convert(get_mat_wood.rho,"lb/ft^3","kg/m^3").get)
    gd.setSpecificHeat(OpenStudio::convert(get_mat_wood.Cp,"Btu/lb*R","J/kg*K").get)

    # GarageDoors
    garagedoor = OpenStudio::Model::Construction.new(model)
    garagedoor.setName("GarageDoors")
    garagedoor.insertLayer(0,gd)

    # loop thru all the spaces
    spaces = model.getSpaces
    spaces.each do |space|
      constructions_hash = {}
      if not garage_space_type.nil? and garage_space_type.handle.to_s == space.spaceType.get.handle.to_s
        # loop thru all surfaces attached to the space
        surfaces = space.surfaces
        surfaces.each do |surface|
          if surface.surfaceType == "Wall" and surface.outsideBoundaryCondition == "Outdoors"
            subSurfaces = surface.subSurfaces
            subSurfaces.each do |subSurface|
              if subSurface.subSurfaceType.include? "Door"
                subSurface.resetConstruction
                subSurface.setConstruction(garagedoor)
                constructions_hash[subSurface.name.to_s] = [subSurface.subSurfaceType,surface.name.to_s,"GarageDoors"]
              end
            end
          end
        end
      elsif living_space_type.handle.to_s == space.spaceType.get.handle.to_s
        # loop thru all surfaces attached to the space
        surfaces = space.surfaces
        surfaces.each do |surface|
          if surface.surfaceType == "Wall" and surface.outsideBoundaryCondition == "Outdoors"
            subSurfaces = surface.subSurfaces
            subSurfaces.each do |subSurface|
              if subSurface.subSurfaceType.include? "Door"
                subSurface.resetConstruction
                subSurface.setConstruction(door)
                constructions_hash[subSurface.name.to_s] = [subSurface.subSurfaceType,surface.name.to_s,"LivingDoors"]
              end
            end
          end
        end
      end
      constructions_hash.map do |key,value|
        runner.registerInfo("Sub Surface '#{key}' of Sub Surface Type '#{value[0]}', attached to Surface '#{value[1]}' which is attached to Space '#{space.name.to_s}' of Space Type '#{space.spaceType.get.name.to_s}', was assigned Construction '#{value[2]}'")
      end
    end

    return true
 
  end #end the run method

end #end the measure

#this allows the measure to be use by the application
ProcessConstructionsDoors.new.registerWithApplication