#see the URL below for information on how to write OpenStudio measures
# http://openstudio.nrel.gov/openstudio-measure-writing-guide

#see the URL below for information on using life cycle cost objects in OpenStudio
# http://openstudio.nrel.gov/openstudio-life-cycle-examples

#see the URL below for access to C++ documentation on model objects (click on "model" in the main window to view model objects)
# http://openstudio.nrel.gov/sites/openstudio.nrel.gov/files/nv_data/cpp_documentation_it/model/html/namespaces.html

#load sim.rb
require "#{File.dirname(__FILE__)}/resources/sim"

#start the measure
class ProcessThermalMassFurniture < OpenStudio::Ruleset::ModelUserScript

  #define the name that a user will see, this method may be deprecated as
  #the display name in PAT comes from the name field in measure.xml
  def name
    return "ProcessThermalMassFurniture"
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

    #make a choice argument for living space
    selected_living = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("selectedliving", spacetype_handles, spacetype_display_names, true)
    selected_living.setDisplayName("Of what space type is the living space?")
    args << selected_living

    #make a choice argument for fbsmt
    selected_fbsmt = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("selectedfbsmt", spacetype_handles, spacetype_display_names, false)
    selected_fbsmt.setDisplayName("Of what space type is the finished basement?")
    args << selected_fbsmt

    #make a choice argument for ufbsmt
    selected_ufbsmt = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("selectedufbsmt", spacetype_handles, spacetype_display_names, false)
    selected_ufbsmt.setDisplayName("Of what space type is the unfinished basement?")
    args << selected_ufbsmt

    #make a choice argument for garage
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

    # Space Type
    selected_living = runner.getOptionalWorkspaceObjectChoiceValue("selectedliving",user_arguments,model)
    selected_fbsmt = runner.getOptionalWorkspaceObjectChoiceValue("selectedfbsmt",user_arguments,model)
    selected_ufbsmt = runner.getOptionalWorkspaceObjectChoiceValue("selectedufbsmt",user_arguments,model)
    selected_garage = runner.getOptionalWorkspaceObjectChoiceValue("selectedgarage",user_arguments,model)

    # loop thru all the spaces
    hasFinishedBasement = false
    hasUnfinishedBasement = false
    hasGarage = false
    if not selected_fbsmt.empty?
      hasFinishedBasement = true
    end
    if not selected_ufbsmt.empty?
      hasUnfinishedBasement = true
    end
    if not selected_garage.empty?
        hasGarage = true
    end

    # Create the sim object
    sim = Sim.new(model)

    # Process the furniture
    living_space_furn, finished_basement_furn, ubsmt_furn, garage_furn, has_furniture = sim._processThermalMassFurniture(hasFinishedBasement, hasUnfinishedBasement, hasGarage)

    if living_space_furn.area_frac > 0 and has_furniture
      lfm = OpenStudio::Model::StandardOpaqueMaterial.new(model)
      lfm.setName("LivingFurnitureMaterial")
      lfm.setRoughness("Rough")
      lfm.setThickness(OpenStudio::convert(living_space_furn.thickness,"ft","m").get)
      lfm.setConductivity(OpenStudio::convert(living_space_furn.conductivity,"Btu*in/hr*ft^2*R","W/m*K").get)
      lfm.setDensity(OpenStudio::convert(living_space_furn.density,"lb/ft^3","kg/m^3").get)
      lfm.setSpecificHeat(OpenStudio::convert(living_space_furn.spec_heat,"Btu/lb*R","J/kg*K").get)
      lfm.setThermalAbsorptance(0.9)
      lfm.setSolarAbsorptance(living_space_furn.solar_abs)
      lfm.setVisibleAbsorptance(0.1)

      lf = OpenStudio::Model::Construction.new(model)
      lf.setName("LivingFurniture")
      lf.insertLayer(0,lfm)

      lsf = OpenStudio::Model::InternalMassDefinition.new(model)
      lsf.setName("LivingSpaceFurniture")
      lsf.setConstruction(lf)
      lsf.setSurfaceArea(living_space_furn.area_frac * OpenStudio::convert(1200,"ft^2","m^2").get) # TODO: replace the 1200 with living space area
      im = OpenStudio::Model::InternalMass.new(lsf)
      im.setName("LivingSpaceFurniture")
      # loop thru all the space types
      spaceTypes = model.getSpaceTypes
      spaceTypes.each do |spaceType|
        if selected_living.get.handle.to_s == spaceType.handle.to_s
          runner.registerInfo("Assigned internal mass object 'LivingSpaceFurniture' to space type '#{spaceType.name}'")
          im.setSpaceType(spaceType)
        end
      end
    end

    if hasFinishedBasement
      if finished_basement_furn.area_frac > 0 and has_furniture
        ffm = OpenStudio::Model::StandardOpaqueMaterial.new(model)
        ffm.setName("FBsmtFurnitureMaterial")
        ffm.setRoughness("Rough")
        ffm.setThickness(OpenStudio::convert(finished_basement_furn.thickness,"ft","m").get)
        ffm.setConductivity(OpenStudio::convert(finished_basement_furn.conductivity,"Btu/hr*ft*R","W/m*K").get)
        ffm.setDensity(OpenStudio::convert(finished_basement_furn.density,"lb/ft^3","kg/m^3").get)
        ffm.setSpecificHeat(OpenStudio::convert(finished_basement_furn.spec_heat,"Btu/lb*R","J/kg*K").get)
        # TODO: Check should thermal, solar, and visible absorptance be put here as in the living space?

        ff = OpenStudio::Model::Construction.new(model)
        ff.setName("FBsmtFurniture")
        ff.insertLayer(0,ffm)

        fsf = OpenStudio::Model::InternalMassDefinition.new(model)
        fsf.setName("FBsmtSpaceFurniture")
        fsf.setConstruction(ff)
        fsf.setSurfaceArea(living_space_furn.area_frac * OpenStudio::convert(1200,"ft^2","m^2").get) # TODO: replace the 1200 with finished basement area
        im = OpenStudio::Model::InternalMass.new(fsf)
        im.setName("FBsmtSpaceFurniture")
        # loop thru all the space types
        spaceTypes = model.getSpaceTypes
        spaceTypes.each do |spaceType|
          if selected_fbsmt.get.handle.to_s == spaceType.handle.to_s
            runner.registerInfo("Assigned internal mass object 'FBsmtSpaceFurniture' to space type '#{spaceType.name}'")
            im.setSpaceType(spaceType)
          end
        end
      end
    end

    if hasUnfinishedBasement
        ufm = OpenStudio::Model::StandardOpaqueMaterial.new(model)
        ufm.setName("UFBsmtFurnitureMaterial")
        ufm.setRoughness("Rough")
        ufm.setThickness(OpenStudio::convert(ubsmt_furn.thickness,"ft","m").get)
        ufm.setConductivity(OpenStudio::convert(ubsmt_furn.conductivity,"Btu/hr*ft*R","W/m*K").get)
        ufm.setDensity(OpenStudio::convert(ubsmt_furn.density,"lb/ft^3","kg/m^3").get)
        ufm.setSpecificHeat(OpenStudio::convert(ubsmt_furn.spec_heat,"Btu/lb*R","J/kg*K").get)
        # TODO: Check should thermal, solar, and visible absorptance be put here as in the living space?

        uf = OpenStudio::Model::Construction.new(model)
        uf.setName("UFBsmtFurniture")
        uf.insertLayer(0,ufm)

        usf = OpenStudio::Model::InternalMassDefinition.new(model)
        usf.setName("UFBsmtSpaceFurniture")
        usf.setConstruction(uf)
        usf.setSurfaceArea(ubsmt_furn.area_frac * OpenStudio::convert(1200,"ft^2","m^2").get) # TODO: replace the 1200 with unfinished basement area
        im = OpenStudio::Model::InternalMass.new(usf)
        im.setName("UFBsmtSpaceFurniture")
        # loop thru all the space types
        spaceTypes = model.getSpaceTypes
        spaceTypes.each do |spaceType|
          if selected_ufbsmt.get.handle.to_s == spaceType.handle.to_s
            runner.registerInfo("Assigned internal mass object 'UFBsmtSpaceFurniture' to space type '#{spaceType.name}'")
            im.setSpaceType(spaceType)
          end
        end
    end

    if hasGarage
      gfm = OpenStudio::Model::StandardOpaqueMaterial.new(model)
      gfm.setName("GarageFurnitureMaterial")
      gfm.setRoughness("Rough")
      gfm.setThickness(OpenStudio::convert(garage_furn.thickness,"ft","m").get)
      gfm.setConductivity(OpenStudio::convert(garage_furn.conductivity,"Btu/hr*ft*R","W/m*K").get)
      gfm.setDensity(OpenStudio::convert(garage_furn.density,"lb/ft^3","kg/m^3").get)
      gfm.setSpecificHeat(OpenStudio::convert(garage_furn.spec_heat,"Btu/lb*R","J/kg*K").get)

      gf = OpenStudio::Model::Construction.new(model)
      gf.setName("GarageFurniture")
      gf.insertLayer(0,gfm)

      gsf = OpenStudio::Model::InternalMassDefinition.new(model)
      gsf.setName("GarageSpaceFurniture")
      gsf.setConstruction(gf)
      gsf.setSurfaceArea(garage_furn.area_frac * OpenStudio::convert(300,"ft^2","m^2").get) # TODO: replace the 300 with garage area
      im = OpenStudio::Model::InternalMass.new(gsf)
      im.setName("GarageSpaceFurniture")
      # loop thru all the space types
      spaceTypes = model.getSpaceTypes
      spaceTypes.each do |spaceType|
        if selected_garage.get.handle.to_s == spaceType.handle.to_s
          runner.registerInfo("Assigned internal mass object 'GarageSpaceFurniture' to space type '#{spaceType.name}'")
          im.setSpaceType(spaceType)
        end
      end
    end

    return true
 
  end #end the run method

end #end the measure

#this allows the measure to be use by the application
ProcessThermalMassFurniture.new.registerWithApplication