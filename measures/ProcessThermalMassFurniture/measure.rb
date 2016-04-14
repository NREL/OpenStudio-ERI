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
    return "Set Residential Furniture Thermal Mass"
  end
  
  def description
    return "This measure assigns furniture mass to the living space, finished basement, unfinished basement, and garage."
  end
  
  def modeler_description
    return "This measure creates constructions representing the internal mass of furniture in the living space, finished basement, unfinished basement, and garage. The constructions are set to define the internal mass objects of their respective spaces."
  end    
  
  #define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Ruleset::OSArgumentVector.new
	
    #make a choice argument for living space type
    space_types = model.getSpaceTypes
    space_type_args = OpenStudio::StringVector.new
    space_types.each do |space_type|
        space_type_args << space_type.name.to_s
    end
    if space_type_args.empty?
        space_type_args << Constants.LivingSpaceType
    end
    living_space_type = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("living_space_type", space_type_args, true)
    living_space_type.setDisplayName("Living space type")
    living_space_type.setDescription("Select the living space type")
    if space_type_args.include?(Constants.LivingSpaceType)
        living_space_type.setDefaultValue(Constants.LivingSpaceType)
    end
    args << living_space_type	
	
    #make a choice argument for finished basement space type
    space_types = model.getSpaceTypes
    space_type_args = OpenStudio::StringVector.new
    space_types.each do |space_type|
        space_type_args << space_type.name.to_s
    end
    if space_type_args.empty?
        space_type_args << Constants.FinishedBasementSpaceType
    end
    fbasement_space_type = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("fbasement_space_type", space_type_args, true)
    fbasement_space_type.setDisplayName("Finished basement space type")
    fbasement_space_type.setDescription("Select the finished basement space type")
    if space_type_args.include?(Constants.FinishedBasementSpaceType)
        fbasement_space_type.setDefaultValue(Constants.FinishedBasementSpaceType)
    end
    args << fbasement_space_type	
	
    #make a choice argument for unfinished basement space type
    space_types = model.getSpaceTypes
    space_type_args = OpenStudio::StringVector.new
    space_types.each do |space_type|
        space_type_args << space_type.name.to_s
    end
    if space_type_args.empty?
        space_type_args << Constants.UnfinishedBasementSpaceType
    end
    ubasement_space_type = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("ubasement_space_type", space_type_args, true)
    ubasement_space_type.setDisplayName("Unfinished basement space type")
    ubasement_space_type.setDescription("Select the unfinished basement space type")
    if space_type_args.include?(Constants.UnfinishedBasementSpaceType)
        ubasement_space_type.setDefaultValue(Constants.UnfinishedBasementSpaceType)
    end
    args << ubasement_space_type

    #make a choice argument for garage space type
    space_types = model.getSpaceTypes
    space_type_args = OpenStudio::StringVector.new
    space_types.each do |space_type|
        space_type_args << space_type.name.to_s
    end
    if space_type_args.empty?
        space_type_args << Constants.GarageSpaceType
    end
    garage_space_type = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("garage_space_type", space_type_args, true)
    garage_space_type.setDisplayName("Garage space type")
    garage_space_type.setDescription("Select the garage space type")
    if space_type_args.include?(Constants.GarageSpaceType)
        garage_space_type.setDefaultValue(Constants.GarageSpaceType)
    end
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
    living_space_type = Geometry.get_space_type_from_string(model, living_space_type_r, runner)
    if living_space_type.nil?
        return false
    end
	fbasement_space_type_r = runner.getStringArgumentValue("fbasement_space_type",user_arguments)
    fbasement_space_type = Geometry.get_space_type_from_string(model, fbasement_space_type_r, runner, false)
	ubasement_space_type_r = runner.getStringArgumentValue("ubasement_space_type",user_arguments)
    ubasement_space_type = Geometry.get_space_type_from_string(model, ubasement_space_type_r, runner, false)
	garage_space_type_r = runner.getStringArgumentValue("garage_space_type",user_arguments)
    garage_space_type = Geometry.get_space_type_from_string(model, garage_space_type_r, runner, false)
    
	living_space_furn_area = 0
	finished_basement_furn_area = 0
	unfinished_basement_furn_area = 0
	garage_furn_area = 0
	living_space_furn_area = Geometry.get_floor_area_for_space_type(model, living_space_type.handle)
	unless fbasement_space_type.nil?
		finished_basement_furn_area = Geometry.get_floor_area_for_space_type(model, fbasement_space_type.handle)
	end
	unless ubasement_space_type.nil?
		unfinished_basement_furn_area = Geometry.get_floor_area_for_space_type(model, ubasement_space_type.handle)
	end
	unless garage_space_type.nil?
		garage_furn_area = Geometry.get_floor_area_for_space_type(model, garage_space_type.handle)
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
    unless fbasement_space_type.nil?

      finished_basement_furn = Furniture.new(finished_basement_furn_type, furnitureDensity, furnitureConductivity, furnitureSpecHeat, furnitureAreaFraction, furnitureWeight, furnitureSolarAbsorptance)

      if has_furniture
        finished_basement_furn.thickness = finished_basement_furn.total_mass / (finished_basement_furn.density * finished_basement_furn.area_frac) # ft
      else
        finished_basement_furn.thickness = 0.00001 # ft, Set greater than the EnergyPlus lower limit of zero.
      end

    end

    # Unfinished Basement Furniture with hard-coded variables
    unless ubasement_space_type.nil?

      furn_type_ubsmt = Constants.FurnTypeLight
      if furn_type_ubsmt == Constants.FurnTypeLight
        ubsmt_furn = Furniture.new(furn_type_ubsmt, 40.0, 0.0667, BaseMaterial.Wood.cp, 0.4, 8.0, nil)
      elsif furn_type_ubsmt == Constants.FurnTypeHeavy
        ubsmt_furn = Furniture.new(furn_type_ubsmt, 80.0, 0.0939, 0.35, 0.4, 8.0, nil)
      end

      ubsmt_furn.thickness = ubsmt_furn.total_mass / (ubsmt_furn.density * ubsmt_furn.area_frac)

    end

    # Garage Furniture with hard-coded variables
    unless garage_space_type.nil?

      furn_type_grg = Constants.FurnTypeLight
      if furn_type_grg == Constants.FurnTypeLight
        garage_furn = Furniture.new(furn_type_grg, 40.0, 0.0667, BaseMaterial.Wood.cp, 0.1, 2.0, nil)
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

	  materials = []
      materials << lfm
      lf = OpenStudio::Model::Construction.new(materials)
      lf.setName("LivingFurniture")	  

      lsf = OpenStudio::Model::InternalMassDefinition.new(model)
      lsf.setName("LivingSpaceFurniture")
      lsf.setConstruction(lf)
      lsf.setSurfaceArea(living_space_furn.area_frac * OpenStudio::convert(living_space_furn_area,"ft^2","m^2").get)
      im = OpenStudio::Model::InternalMass.new(lsf)
      im.setName("LivingSpaceFurniture")
	  im.setSpaceType(living_space_type)
	  runner.registerInfo("Assigned internal mass object 'LivingSpaceFurniture' to space type '#{living_space_type_r}'")
    end

    unless fbasement_space_type.nil?
      if finished_basement_furn.area_frac > 0 and has_furniture
        ffm = OpenStudio::Model::StandardOpaqueMaterial.new(model)
        ffm.setName("FBsmtFurnitureMaterial")
        ffm.setRoughness("Rough")
        ffm.setThickness(OpenStudio::convert(finished_basement_furn.thickness,"ft","m").get)
        ffm.setConductivity(OpenStudio::convert(finished_basement_furn.conductivity,"Btu/hr*ft*R","W/m*K").get)
        ffm.setDensity(OpenStudio::convert(finished_basement_furn.density,"lb/ft^3","kg/m^3").get)
        ffm.setSpecificHeat(OpenStudio::convert(finished_basement_furn.spec_heat,"Btu/lb*R","J/kg*K").get)
        # TODO: Check should thermal, solar, and visible absorptance be put here as in the living space?

		materials = []
        materials << ffm
        ff = OpenStudio::Model::Construction.new(materials)
        ff.setName("FBsmtFurniture")		

        fsf = OpenStudio::Model::InternalMassDefinition.new(model)
        fsf.setName("FBsmtSpaceFurniture")
        fsf.setConstruction(ff)
        fsf.setSurfaceArea(living_space_furn.area_frac * OpenStudio::convert(finished_basement_furn_area,"ft^2","m^2").get)
        im = OpenStudio::Model::InternalMass.new(fsf)
        im.setName("FBsmtSpaceFurniture")            
		im.setSpaceType(fbasement_space_type)
		runner.registerInfo("Assigned internal mass object 'FBsmtSpaceFurniture' to space type '#{fbasement_space_type_r}'")
      end
    end

    unless ubasement_space_type.nil?
	  ufm = OpenStudio::Model::StandardOpaqueMaterial.new(model)
	  ufm.setName("UFBsmtFurnitureMaterial")
	  ufm.setRoughness("Rough")
	  ufm.setThickness(OpenStudio::convert(ubsmt_furn.thickness,"ft","m").get)
	  ufm.setConductivity(OpenStudio::convert(ubsmt_furn.conductivity,"Btu/hr*ft*R","W/m*K").get)
	  ufm.setDensity(OpenStudio::convert(ubsmt_furn.density,"lb/ft^3","kg/m^3").get)
	  ufm.setSpecificHeat(OpenStudio::convert(ubsmt_furn.spec_heat,"Btu/lb*R","J/kg*K").get)
	  # TODO: Check should thermal, solar, and visible absorptance be put here as in the living space?

	  materials = []
	  materials << ufm
	  uf = OpenStudio::Model::Construction.new(materials)
	  uf.setName("UFBsmtFurniture")		

	  usf = OpenStudio::Model::InternalMassDefinition.new(model)
	  usf.setName("UFBsmtSpaceFurniture")
	  usf.setConstruction(uf)
	  usf.setSurfaceArea(ubsmt_furn.area_frac * OpenStudio::convert(unfinished_basement_furn_area,"ft^2","m^2").get)
	  im = OpenStudio::Model::InternalMass.new(usf)
	  im.setName("UFBsmtSpaceFurniture")
	  im.setSpaceType(ubasement_space_type)
	  runner.registerInfo("Assigned internal mass object 'UFBsmtSpaceFurniture' to space type '#{ubasement_space_type_r}'")
    end

    unless garage_space_type.nil?
      gfm = OpenStudio::Model::StandardOpaqueMaterial.new(model)
      gfm.setName("GarageFurnitureMaterial")
      gfm.setRoughness("Rough")
      gfm.setThickness(OpenStudio::convert(garage_furn.thickness,"ft","m").get)
      gfm.setConductivity(OpenStudio::convert(garage_furn.conductivity,"Btu/hr*ft*R","W/m*K").get)
      gfm.setDensity(OpenStudio::convert(garage_furn.density,"lb/ft^3","kg/m^3").get)
      gfm.setSpecificHeat(OpenStudio::convert(garage_furn.spec_heat,"Btu/lb*R","J/kg*K").get)

	  materials = []
      materials << gfm
      gf = OpenStudio::Model::Construction.new(materials)
      gf.setName("GarageFurniture")	  

      gsf = OpenStudio::Model::InternalMassDefinition.new(model)
      gsf.setName("GarageSpaceFurniture")
      gsf.setConstruction(gf)
      gsf.setSurfaceArea(garage_furn.area_frac * OpenStudio::convert(garage_furn_area,"ft^2","m^2").get)
      im = OpenStudio::Model::InternalMass.new(gsf)
      im.setName("GarageSpaceFurniture")
	  im.setSpaceType(garage_space_type)
	  runner.registerInfo("Assigned internal mass object 'GarageSpaceFurniture' to space type '#{garage_space_type_r}'")
    end

    return true
 
  end #end the run method

end #end the measure

#this allows the measure to be use by the application
ProcessThermalMassFurniture.new.registerWithApplication