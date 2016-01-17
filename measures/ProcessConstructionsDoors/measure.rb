#see the URL below for information on how to write OpenStudio measures
# http://openstudio.nrel.gov/openstudio-measure-writing-guide

#see the URL below for information on using life cycle cost objects in OpenStudio
# http://openstudio.nrel.gov/openstudio-life-cycle-examples

#see the URL below for access to C++ documentation on model objects (click on "model" in the main window to view model objects)
# http://openstudio.nrel.gov/sites/openstudio.nrel.gov/files/nv_data/cpp_documentation_it/model/html/namespaces.html

require "#{File.dirname(__FILE__)}/resources/util"
require "#{File.dirname(__FILE__)}/resources/constants"

#start the measure
class ProcessConstructionsDoors < OpenStudio::Ruleset::ModelUserScript

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

    # Process the door construction
    door_Uvalue_air_to_air = doorUvalue
    garage_door_Uvalue_air_to_air = 0.2 # Btu/hr*ft^2*F, R-values typically vary from R5 to R10, from the Home Depot website

    door_Rvalue_air_to_air = 1.0 / door_Uvalue_air_to_air
    garage_door_Rvalue_air_to_air = 1.0 / garage_door_Uvalue_air_to_air

    door_Rvalue = door_Rvalue_air_to_air - AirFilms.OutsideR - AirFilms.VerticalR
    garage_door_Rvalue = garage_door_Rvalue_air_to_air - AirFilms.OutsideR - AirFilms.VerticalR

    door_Uvalue = 1.0 / door_Rvalue
    garage_door_Uvalue = 1.0 / garage_door_Rvalue

    door_thickness = OpenStudio.convert(1.75,"in","ft").get # ft
    garage_door_thickness = OpenStudio.convert(2.5,"in","ft").get # ft

    # DoorMaterial
    d = OpenStudio::Model::StandardOpaqueMaterial.new(model)
    d.setName("DoorMaterial")
    d.setRoughness("Rough")
    d.setThickness(OpenStudio::convert(door_thickness,"ft","m").get)
    d.setConductivity(OpenStudio::convert(door_Uvalue * door_thickness,"Btu/hr*ft*R","W/m*K").get)
    d.setDensity(OpenStudio::convert(BaseMaterial.Wood.rho,"lb/ft^3","kg/m^3").get)
    d.setSpecificHeat(OpenStudio::convert(BaseMaterial.Wood.Cp,"Btu/lb*R","J/kg*K").get)

    # LivingDoors
    materials = []
    materials << d
    door = OpenStudio::Model::Construction.new(materials)
    door.setName("LivingDoors") 

    # GarageDoorMaterial
    gd = OpenStudio::Model::StandardOpaqueMaterial.new(model)
    gd.setName("GarageDoorMaterial")
    gd.setRoughness("Rough")
    gd.setThickness(OpenStudio::convert(garage_door_thickness,"ft","m").get)
    gd.setConductivity(OpenStudio::convert(garage_door_Uvalue * garage_door_thickness,"Btu/hr*ft*R","W/m*K").get)
    gd.setDensity(OpenStudio::convert(BaseMaterial.Wood.rho,"lb/ft^3","kg/m^3").get)
    gd.setSpecificHeat(OpenStudio::convert(BaseMaterial.Wood.Cp,"Btu/lb*R","J/kg*K").get)

    # GarageDoors
    materials = []
    materials << gd
    garagedoor = OpenStudio::Model::Construction.new(materials)
    garagedoor.setName("GarageDoors")   

    living_space_type.spaces.each do |living_space|
      living_space.surfaces.each do |living_surface|
        next unless living_surface.surfaceType.downcase == "wall" and living_surface.outsideBoundaryCondition.downcase == "outdoors"
        living_surface.subSurfaces.each do |living_sub_surface|
          next unless living_sub_surface.subSurfaceType.downcase.include? "door"
          living_sub_surface.setConstruction(door)
          runner.registerInfo("Sub Surface '#{living_sub_surface.name}', of Space Type '#{living_space_type_r}' and with Sub Surface Type '#{living_sub_surface.subSurfaceType}', was assigned Construction '#{door.name}'")
        end
      end   
    end 

    if not garage_space_type.nil?
      garage_space_type.spaces.each do |garage_space|
        garage_space.surfaces.each do |garage_surface|
          next unless garage_surface.surfaceType.downcase == "wall" and garage_surface.outsideBoundaryCondition.downcase == "outdoors"
          garage_surface.subSurfaces.each do |garage_sub_surface|
            next unless garage_sub_surface.subSurfaceType.downcase.include? "door"
            garage_sub_surface.setConstruction(door)
            runner.registerInfo("Sub Surface '#{garage_sub_surface.name}', of Space Type '#{garage_space_type_r}' and with Sub Surface Type '#{garage_sub_surface.subSurfaceType}', was assigned Construction '#{door.name}'")
          end
        end   
      end
    end
    
    return true
 
  end #end the run method

end #end the measure

#this allows the measure to be use by the application
ProcessConstructionsDoors.new.registerWithApplication