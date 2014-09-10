#see the URL below for information on how to write OpenStudio measures
# http://openstudio.nrel.gov/openstudio-measure-writing-guide

#see the URL below for information on using life cycle cost objects in OpenStudio
# http://openstudio.nrel.gov/openstudio-life-cycle-examples

#see the URL below for access to C++ documentation on model objects (click on "model" in the main window to view model objects)
# http://openstudio.nrel.gov/sites/openstudio.nrel.gov/files/nv_data/cpp_documentation_it/model/html/namespaces.html

#load sim.rb
#require "#{File.dirname(__FILE__)}/resources/sim"
require "C:/OS-BEopt/OpenStudio-Beopt/resources/sim"

#start the measure
class ProcessConstructionsDoors < OpenStudio::Ruleset::ModelUserScript

  class Door
    def initialize
    end
    attr_accessor(:mat_door_Uvalue, :door_thickness)
  end

  class GarageDoor
    def initialize
    end
    attr_accessor(:garage_door_Uvalue, :garage_door_thickness)
  end

  #define the name that a user will see, this method may be deprecated as
  #the display name in PAT comes from the name field in measure.xml
  def name
    return "ProcessConstructionsDoors"
  end
  
  #define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Ruleset::OSArgumentVector.new

    #make a choice argument for model objects
    spacetype_handles = OpenStudio::StringVector.new
    spacetype_display_names = OpenStudio::StringVector.new

    #putting model object and names into hash
    spacetype_args = model.getSpaceTypes
    spacetype_args_hash = {}
    spacetype_args.each do |spacetype_arg|
      spacetype_args_hash[spacetype_arg.name.to_s] = spacetype_arg
    end

    #looping through sorted hash of model objects
    spacetype_args_hash.sort.map do |key,value|
      spacetype_handles << value.handle.to_s
      spacetype_display_names << key
    end

    #make a choice argument for living
    selected_living = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("selectedliving", spacetype_handles, spacetype_display_names, true)
    selected_living.setDisplayName("Of what space type is the living space?")
    args << selected_living

    #make a choice argument for crawlspace
    selected_garage = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("selectedgarage", spacetype_handles, spacetype_display_names, true)
    selected_garage.setDisplayName("Of what space type is the garage?")
    args << selected_garage

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
    selected_garage = runner.getOptionalWorkspaceObjectChoiceValue("selectedgarage",user_arguments,model)
    selected_living = runner.getOptionalWorkspaceObjectChoiceValue("selectedliving",user_arguments,model)

    # Create the material class instances
    d = Door.new
    gd = GarageDoor.new

    # Create the sim object
    sim = Sim.new(model)

    # Process the windows
    d, gd = sim._processConstructionsDoors(d, gd)

    # DoorMaterial
    mat_door_Uvalue = d.mat_door_Uvalue
    door_thickness = d.door_thickness
    d = OpenStudio::Model::StandardOpaqueMaterial.new(model)
    d.setName("DoorMaterial")
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
      if selected_garage.get.handle.to_s == space.spaceType.get.handle.to_s
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
      elsif selected_living.get.handle.to_s == space.spaceType.get.handle.to_s
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