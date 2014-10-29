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
class ProcessConstructionsExteriorUninsulatedWalls < OpenStudio::Ruleset::ModelUserScript

  #define the name that a user will see, this method may be deprecated as
  #the display name in PAT comes from the name field in measure.xml
  def name
    return "ProcessConstructionsExteriorUninsulatedWalls"
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

    #make a choice argument for crawlspace
    selected_attic = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("selectedattic", spacetype_handles, spacetype_display_names, false)
    selected_attic.setDisplayName("Of what space type is the attic?")
    args << selected_attic

    #make a choice argument for living
    selected_garage = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("selectedgarage", spacetype_handles, spacetype_display_names, false)
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
    selected_attic = runner.getOptionalWorkspaceObjectChoiceValue("selectedattic",user_arguments,model)
    selected_garage = runner.getOptionalWorkspaceObjectChoiceValue("selectedgarage",user_arguments,model)
	
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
	saw.setThickness(OpenStudio::convert(get_stud_and_air_wall(model, mat_wood).thick,"ft","m").get)
	saw.setConductivity(OpenStudio::convert(get_stud_and_air_wall(model, mat_wood).k,"Btu/hr*ft*R","W/m*K").get)
	saw.setDensity(OpenStudio::convert(get_stud_and_air_wall(model, mat_wood).rho,"lb/ft^3","kg/m^3").get)
	saw.setSpecificHeat(OpenStudio::convert(get_stud_and_air_wall(model, mat_wood).Cp,"Btu/lb*R","J/kg*K").get) # tk
	
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
      if not selected_attic.empty?
        if selected_attic.get.handle.to_s == space.spaceType.get.handle.to_s
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
      if not selected_garage.empty?
        if selected_garage.get.handle.to_s == space.spaceType.get.handle.to_s
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