#see the URL below for information on how to write OpenStudio measures
# http://openstudio.nrel.gov/openstudio-measure-writing-guide

#see the URL below for information on using life cycle cost objects in OpenStudio
# http://openstudio.nrel.gov/openstudio-life-cycle-examples

#see the URL below for access to C++ documentation on model objects (click on "model" in the main window to view model objects)
# http://openstudio.nrel.gov/sites/openstudio.nrel.gov/files/nv_data/cpp_documentation_it/model/html/namespaces.html

#load sim.rb
require "#{File.dirname(__FILE__)}/resources/sim"

#start the measure
class ProcessConstructionsGarageSlab < OpenStudio::Ruleset::ModelUserScript
  
  #define the name that a user will see, this method may be deprecated as
  #the display name in PAT comes from the name field in measure.xml
  def name
    return "Assign Residential Garage Slab Construction"
  end
  
  def description
    return "This measure creates slab constructions for the garage floor."
  end
  
  def modeler_description
    return "Calculates material layer properties of slab constructions for the garage floor. Finds surfaces adjacent to the garage and sets applicable constructions."
  end    
  
  #define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Ruleset::OSArgumentVector.new

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
	garage_space_type_r = runner.getStringArgumentValue("garage_space_type",user_arguments)
    garage_space_type = HelperMethods.get_space_type_from_string(model, garage_space_type_r, runner, false)
    if garage_space_type.nil?
        # If the building has no garage, no constructions are assigned and we continue by returning True
        return true
    end

	mat_concrete = BaseMaterial.Concrete
	mat_soil = BaseMaterial.Soil
	
	# Adiabatic
	adi = OpenStudio::Model::MasslessOpaqueMaterial.new(model)
	adi.setName("Adiabatic")
	adi.setRoughness("Rough")
	adi.setThermalResistance(OpenStudio::convert(1000,"hr*ft^2*R/Btu","m^2*K/W").get)
	
	# Soil-12in
	soil = OpenStudio::Model::StandardOpaqueMaterial.new(model)
	soil.setName("Soil-12in")
	soil.setRoughness("Rough")
	soil.setThickness(OpenStudio::convert(Material.Soil12in.thick,"ft","m").get)
	soil.setConductivity(OpenStudio::convert(mat_soil.k,"Btu/hr*ft*R","W/m*K").get)
	soil.setDensity(OpenStudio::convert(mat_soil.rho,"lb/ft^3","kg/m^3").get)
	soil.setSpecificHeat(OpenStudio::convert(mat_soil.Cp,"Btu/lb*R","J/kg*K").get)	
	
	# Concrete-4in
    mat_concrete4in = Material.Concrete4in
	conc = OpenStudio::Model::StandardOpaqueMaterial.new(model)
	conc.setName("Concrete-4in")
	conc.setRoughness("Rough")
	conc.setThickness(OpenStudio::convert(mat_concrete4in.thick,"ft","m").get)
	conc.setConductivity(OpenStudio::convert(mat_concrete4in.k,"Btu/hr*ft*R","W/m*K").get)
	conc.setDensity(OpenStudio::convert(mat_concrete4in.rho,"lb/ft^3","kg/m^3").get)
	conc.setSpecificHeat(OpenStudio::convert(mat_concrete4in.Cp,"Btu/lb*R","J/kg*K").get)
	conc.setThermalAbsorptance(mat_concrete4in.TAbs)	
	
	# GrndUninsUnfinGrgFloor
	materials = []
	materials << adi
	materials << soil
	materials << conc
	grnduninsunfingrgfloor = OpenStudio::Model::Construction.new(materials)
	grnduninsunfingrgfloor.setName("GrndUninsUnfinGrgFloor")	

	garage_space_type.spaces.each do |garage_space|
	  garage_space.surfaces.each do |garage_surface|
	    next unless garage_surface.surfaceType.downcase == "floor" and garage_surface.outsideBoundaryCondition.downcase == "ground"
	    garage_surface.setConstruction(grnduninsunfingrgfloor)
		runner.registerInfo("Surface '#{garage_surface.name}', of Space Type '#{garage_space_type_r}' and with Surface Type '#{garage_surface.surfaceType}' and Outside Boundary Condition '#{garage_surface.outsideBoundaryCondition}', was assigned Construction '#{grnduninsunfingrgfloor.name}'")
	  end	
	end
	
    return true
 
  end #end the run method

end #end the measure

#this allows the measure to be use by the application
ProcessConstructionsGarageSlab.new.registerWithApplication