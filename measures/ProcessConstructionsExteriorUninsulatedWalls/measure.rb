#see the URL below for information on how to write OpenStudio measures
# http://openstudio.nrel.gov/openstudio-measure-writing-guide

#see the URL below for information on using life cycle cost objects in OpenStudio
# http://openstudio.nrel.gov/openstudio-life-cycle-examples

#see the URL below for access to C++ documentation on model objects (click on "model" in the main window to view model objects)
# http://openstudio.nrel.gov/sites/openstudio.nrel.gov/files/nv_data/cpp_documentation_it/model/html/namespaces.html

#start the measure
class ProcessConstructionsExteriorUninsulatedWalls < OpenStudio::Ruleset::ModelUserScript

  #define the name that a user will see, this method may be deprecated as
  #the display name in PAT comes from the name field in measure.xml
  def name
    return "Assign Residential Unfinished Attic and Garage Wall Constructions"
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
    unfin_attic_space_type.setDisplayName("Unfinished attic space type")
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

    # Space Type
	unfin_attic_space_type_r = runner.getStringArgumentValue("unfin_attic_space_type",user_arguments)
    unfin_attic_space_type = HelperMethods.get_space_type_from_string(model, unfin_attic_space_type_r, runner, false)
	garage_space_type_r = runner.getStringArgumentValue("garage_space_type",user_arguments)
    garage_space_type = HelperMethods.get_space_type_from_string(model, garage_space_type_r, runner, false)
	
	mat_wood = get_mat_wood

	# Plywood-1_2in
	ply1_2 = OpenStudio::Model::StandardOpaqueMaterial.new(model)
	ply1_2.setName("Plywood-1_2in")
	ply1_2.setRoughness("Rough")
	ply1_2.setThickness(OpenStudio::convert(get_mat_plywood1_2in(mat_wood).thick,"ft","m").get)
	ply1_2.setConductivity(OpenStudio::convert(mat_wood.k,"Btu/hr*ft*R","W/m*K").get)
	ply1_2.setDensity(OpenStudio::convert(mat_wood.rho,"lb/ft^3","kg/m^3").get)
	ply1_2.setSpecificHeat(OpenStudio::convert(mat_wood.Cp,"Btu/lb*R","J/kg*K").get)

	# Stud and Air Wall
	saw = OpenStudio::Model::StandardOpaqueMaterial.new(model)
	saw.setName("StudandAirWall")
	saw.setRoughness("Rough")
	saw.setThickness(OpenStudio::convert(get_stud_and_air_wall(model, runner, mat_wood).thick,"ft","m").get)
	saw.setConductivity(OpenStudio::convert(get_stud_and_air_wall(model, runner, mat_wood).k,"Btu/hr*ft*R","W/m*K").get)
	saw.setDensity(OpenStudio::convert(get_stud_and_air_wall(model, runner, mat_wood).rho,"lb/ft^3","kg/m^3").get)
	saw.setSpecificHeat(OpenStudio::convert(get_stud_and_air_wall(model, runner, mat_wood).Cp,"Btu/lb*R","J/kg*K").get)
	
	# ExtUninsUnfinWall
	extuninsunfinwall = OpenStudio::Model::Construction.new(model)
	extuninsunfinwall.setName("ExtUninsUnfinWall")
	extuninsunfinwall.insertLayer(0,extfin)
	extuninsunfinwall.insertLayer(1,ply1_2)
	extuninsunfinwall.insertLayer(2,saw)

    # loop thru all the spaces
    spaces = model.getSpaces
    spaces.each do |space|
      constructions_hash = {}
      if not unfin_attic_space_type.nil?
        if unfin_attic_space_type.handle.to_s == space.spaceType.get.handle.to_s
          # loop thru all surfaces attached to the space
          surfaces = space.surfaces
          surfaces.each do |surface|
            if surface.surfaceType == "Wall" and surface.outsideBoundaryCondition == "Outdoors"
              surface.resetConstruction
              surface.setConstruction(extuninsunfinwall)
              constructions_hash[surface.name.to_s] = [surface.surfaceType,surface.outsideBoundaryCondition,"ExtUninsUnfinWall"]
            end
          end
        end
      end
      if not garage_space_type.nil?
        if garage_space_type.handle.to_s == space.spaceType.get.handle.to_s
          # loop thru all surfaces attached to the space
          surfaces = space.surfaces
          surfaces.each do |surface|
            if surface.surfaceType == "Wall" and surface.outsideBoundaryCondition == "Outdoors"
              surface.resetConstruction
              surface.setConstruction(extuninsunfinwall)
              constructions_hash[surface.name.to_s] = [surface.surfaceType,surface.outsideBoundaryCondition,"ExtUninsUnfinWall"]
            end
          end
        end
      end
      constructions_hash.map do |key,value|
        runner.registerInfo("Surface '#{key}', attached to Space '#{space.name.to_s}' of Space Type '#{space.spaceType.get.name.to_s}' and with Surface Type '#{value[0]}' and Outside Boundary Condition '#{value[1]}', was assigned Construction '#{value[2]}'")
      end
    end
	
    return true
 
  end #end the run method

end #end the measure

#this allows the measure to be use by the application
ProcessConstructionsExteriorUninsulatedWalls.new.registerWithApplication