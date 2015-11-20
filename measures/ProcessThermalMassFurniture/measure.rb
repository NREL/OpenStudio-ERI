#see the URL below for information on how to write OpenStudio measures
# http://openstudio.nrel.gov/openstudio-measure-writing-guide

#see the URL below for information on using life cycle cost objects in OpenStudio
# http://openstudio.nrel.gov/openstudio-life-cycle-examples

#see the URL below for access to C++ documentation on model objects (click on "model" in the main window to view model objects)
# http://openstudio.nrel.gov/sites/openstudio.nrel.gov/files/nv_data/cpp_documentation_it/model/html/namespaces.html

require "#{File.dirname(__FILE__)}/resources/constants"

#start the measure
class ProcessThermalMassFurniture < OpenStudio::Ruleset::ModelUserScript

  class LivingSpace
    def initialize
    end
    attr_accessor(:area)
  end

  class FinishedBasement
    def initialize
    end
    attr_accessor(:area)
  end

  class Furniture
    def initialize(type=nil, density=nil, conductivity=nil, spec_heat=nil, area_frac=nil, total_mass=nil, solar_abs=nil)
      @type = type
      @density = density
      @conductivity = conductivity
      @spec_heat = spec_heat
      @area_frac = area_frac
      @total_mass = total_mass
      @solar_abs = solar_abs
    end

    def area_frac
      return @area_frac
    end

    def total_mass
      return @total_mass
    end

    def density
      return @density
    end

    def conductivity
      return @conductivity
    end

    def spec_heat
      return @spec_heat
    end

    def solar_abs
      return @solar_abs
    end

    attr_accessor(:thickness)
  end

  #define the name that a user will see, this method may be deprecated as
  #the display name in PAT comes from the name field in measure.xml
  def name
    return "Add/Replace Residential Furniture Thermal Mass"
  end
  
  def description
    return "This measure creates internal mass for furniture in the living space, finished basement, unfinished basement, and garage."
  end
  
  def modeler_description
    return "This measure creates constructions representing the internal mass of furniture in the living space, finished basement, unfinished basement, and garage. The constructions are set to define the internal mass objects of their respective spaces."
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
	selected_living.setDescription("The living space type.")
    args << selected_living

    #make a choice argument for fbsmt
    selected_fbsmt = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("selectedfbsmt", spacetype_handles, spacetype_display_names, false)
    selected_fbsmt.setDisplayName("Finished Basement Space")
	selected_fbsmt.setDescription("The finished basement space type.")
    args << selected_fbsmt

    #make a choice argument for ufbsmt
    selected_ufbsmt = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("selectedufbsmt", spacetype_handles, spacetype_display_names, false)
    selected_ufbsmt.setDisplayName("Unfinished Basement Space")
	selected_ufbsmt.setDescription("The unfinished basement space type.")
    args << selected_ufbsmt

    #make a choice argument for garage
    selected_garage = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("selectedgarage", spacetype_handles, spacetype_display_names, false)
    selected_garage.setDisplayName("Garage Space")
	selected_garage.setDescription("The garage space type.")
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
    
    living_space_furn_area = 0
    finished_basement_furn_area = 0
    unfinished_basement_furn_area = 0
    garage_furn_area = 0
	model.getSpaceTypes.each do |spaceType|
		spacehandle = spaceType.handle.to_s
        if spacehandle == selected_living.get.handle.to_s
            living_space_furn_area = OpenStudio.convert(spaceType.floorArea,"m^2","ft^2").get
        elsif hasFinishedBasement and spacehandle == selected_fbsmt.get.handle.to_s
            finished_basement_furn_area = OpenStudio.convert(spaceType.floorArea,"m^2","ft^2").get
        elsif hasUnfinishedBasement and spacehandle == selected_ufbsmt.get.handle.to_s
            unfinished_basement_furn_area = OpenStudio.convert(spaceType.floorArea,"m^2","ft^2").get
        elsif hasGarage and spacehandle == selected_garage.get.handle.to_s
            garage_furn_area = OpenStudio.convert(spaceType.floorArea,"m^2","ft^2").get
        end
    end

    # Process the furniture
    has_furniture = true
    furnitureWeight = 8.0
    furnitureAreaFraction = 0.4
    furnitureDensity = 40.0
    furnitureConductivity = 0.8004
    furnitureSpecHeat = 0.29
    furnitureSolarAbsorptance = 0.6

    if furnitureDensity < 60.0
      living_space_furn_type = Constants.FurnTypeLight
      finished_basement_furn_type = Constants.FurnTypeLight
    else
      living_space_furn_type = Constants.FurnTypeHeavy
      finished_basement_furn_type = Constants.FurnTypeHeavy
    end

    # Living Space Furniture
    living_space_furn = Furniture.new(living_space_furn_type, furnitureDensity, furnitureConductivity, furnitureSpecHeat, furnitureAreaFraction, furnitureWeight, furnitureSolarAbsorptance)

    if has_furniture
      living_space_furn.thickness = living_space_furn.total_mass / (living_space_furn.density * living_space_furn.area_frac) # ft
    else
      living_space_furn.thickness = 0.00001 # ft. Set greater than EnergyPlus lower limit of zero.
    end

    # Finished Basement Furniture
    if hasFinishedBasement

      finished_basement_furn = Furniture.new(finished_basement_furn_type, furnitureDensity, furnitureConductivity, furnitureSpecHeat, furnitureAreaFraction, furnitureWeight, furnitureSolarAbsorptance)

      if has_furniture
        finished_basement_furn.thickness = finished_basement_furn.total_mass / (finished_basement_furn.density * finished_basement_furn.area_frac) # ft
      else
        finished_basement_furn.thickness = 0.00001 # ft, Set greater than the EnergyPlus lower limit of zero.
      end

    end

    # Unfinished Basement Furniture with hard-coded variables
    if hasUnfinishedBasement

      furn_type_ubsmt = Constants.FurnTypeLight
      if furn_type_ubsmt == Constants.FurnTypeLight
        ubsmt_furn = Furniture.new(furn_type_ubsmt, 40.0, 0.0667, get_mat_wood.Cp, 0.4, 8.0, nil)
      elsif furn_type_ubsmt == Constants.FurnTypeHeavy
        ubsmt_furn = Furniture.new(furn_type_ubsmt, 80.0, 0.0939, 0.35, 0.4, 8.0, nil)
      end

      ubsmt_furn.thickness = ubsmt_furn.total_mass / (ubsmt_furn.density * ubsmt_furn.area_frac)

    end

    # Garage Furniture with hard-coded variables
    if hasGarage

      furn_type_grg = Constants.FurnTypeLight
      if furn_type_grg == Constants.FurnTypeLight
        garage_furn = Furniture.new(furn_type_grg, 40.0, 0.0667, get_mat_wood.Cp, 0.1, 2.0, nil)
      elsif furn_type_grg == Constants.FurnTypeHeavy
        garage_furn = Furniture.new(furn_type_grg, 80.0, 0.0939, 0.35, 0.1, 2.0, nil)
      end

      garage_furn.thickness = garage_furn.total_mass / (garage_furn.density * garage_furn.area_frac)

    end
    
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
      lsf.setSurfaceArea(living_space_furn.area_frac * OpenStudio::convert(living_space_furn_area,"ft^2","m^2").get)
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
        fsf.setSurfaceArea(living_space_furn.area_frac * OpenStudio::convert(finished_basement_furn_area,"ft^2","m^2").get)
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
        usf.setSurfaceArea(ubsmt_furn.area_frac * OpenStudio::convert(unfinished_basement_furn_area,"ft^2","m^2").get)
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
      gsf.setSurfaceArea(garage_furn.area_frac * OpenStudio::convert(garage_furn_area,"ft^2","m^2").get)
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