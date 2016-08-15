# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/reference/measure_writing_guide/

require "#{File.dirname(__FILE__)}/resources/constants"
require "#{File.dirname(__FILE__)}/resources/geometry"

# start the measure
class CreateResidentialMultifamilyGeometry < OpenStudio::Ruleset::ModelUserScript

  # human readable name
  def name
    return "Create Residential Multifamily Geometry"
  end

  # human readable description
  def description
    return "Sets the basic geometry for the multifamily building. Building is limited to one foundation type."
  end

  # human readable description of modeling approach
  def modeler_description
    return ""
  end

  # define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Ruleset::OSArgumentVector.new

    #make an argument for total living space floor area
    total_ffa = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("total_ffa",true)
    total_ffa.setDisplayName("Total Finished Floor Area")
    total_ffa.setUnits("ft^2")
    total_ffa.setDescription("The total floor area of the finished space (including any finished basement floor area).")
    total_ffa.setDefaultValue(2000.0)
    args << total_ffa
	
    #make an argument for living space height
    living_height = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("living_height",true)
    living_height.setDisplayName("Wall Height (Per Floor)")
    living_height.setUnits("ft")
    living_height.setDescription("The height of the living space (and garage) walls.")
    living_height.setDefaultValue(8.0)
    args << living_height	
	
    #make an argument for number of floors
    num_floors = OpenStudio::Ruleset::OSArgument::makeIntegerArgument("num_floors",true)
    num_floors.setDisplayName("Num Floors")
    num_floors.setUnits("#")
    num_floors.setDescription("The number of floors above grade.")
    num_floors.setDefaultValue(2)
    args << num_floors
	
    #make an argument for aspect ratio
    aspect_ratio = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("aspect_ratio",true)
    aspect_ratio.setDisplayName("Aspect Ratio")
    aspect_ratio.setUnits("FB/LR")
    aspect_ratio.setDescription("The ratio of the front/back wall length to the left/right wall length.")
    aspect_ratio.setDefaultValue(2.0)
    args << aspect_ratio

    #make a choice argument for model objects
    building_type = OpenStudio::StringVector.new
    building_type << "Duplex"
    building_type << "Not a duplex"
	
    #make a choice argument for roof pitch
    building_type = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("building_type", building_type, true)
    building_type.setDisplayName("Building Type")
    building_type.setDescription("The building type.")
    building_type.setDefaultValue("Duplex")
    args << building_type
    
    #make an argument for number of residential units
    res_units = OpenStudio::Ruleset::OSArgument::makeIntegerArgument("res_units",true)
    res_units.setDisplayName("Num Units")
    res_units.setUnits("#")
    res_units.setDescription("The number of residential units.")
    res_units.setDefaultValue(2)
    args << res_units    

    return args
  end

  # define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)

    # use the built-in error checking
    if !runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

    total_ffa = OpenStudio.convert(runner.getDoubleArgumentValue("total_ffa",user_arguments),"ft^2","m^2").get
    living_height = OpenStudio.convert(runner.getDoubleArgumentValue("living_height",user_arguments),"ft","m").get
    num_floors = runner.getIntegerArgumentValue("num_floors",user_arguments)
    aspect_ratio = runner.getDoubleArgumentValue("aspect_ratio",user_arguments)
    res_units = runner.getIntegerArgumentValue("res_units",user_arguments)
    building_type = runner.getStringArgumentValue("building_type",user_arguments)
    
    if building_type == "Duplex" and res_units != 2
      runner.registerError("Building defined as a duplex but number of units entered is not two.")
      return false
    end
    
    footprint = total_ffa / num_floors
    
    # calculate the dimensions of the building
    width = Math.sqrt(footprint / aspect_ratio)
    length = footprint / width   

    units_per_floor = (res_units / num_floors).floor
    units_remainder = res_units - (num_floors * units_per_floor)
    unit_num = 1
    
    # create living zone
    living_zone = OpenStudio::Model::ThermalZone.new(model)
    living_zone.setName(Constants.LivingZone)    
    
    for floor in (0..num_floors-1)
    
      z = living_height * floor
    
      sw_point = OpenStudio::Point3d.new(0,0,z)
      nw_point = OpenStudio::Point3d.new(0,width,z)
      ne_point = OpenStudio::Point3d.new(length,width,z)
      se_point = OpenStudio::Point3d.new(length,0,z)    
      living_polygon = Geometry.make_polygon(sw_point, nw_point, ne_point, se_point)
      
      living_space = OpenStudio::Model::Space::fromFloorPrint(living_polygon, living_height, model)
      living_space = living_space.get
      living_space_name = Constants.LivingSpace(floor+1)
      living_space.setName(living_space_name)
      runner.registerInfo("Set #{living_space_name}.")
      
      # set these to the living zone
      living_space.setThermalZone(living_zone)      
      
      m = OpenStudio::Matrix.new(4,4,0)
      m[0,0] = 1
      m[1,1] = 1
      m[2,2] = 1
      m[3,3] = 1
      m[2,3] = z
      living_space.changeTransformation(OpenStudio::Transformation.new(m))
      
      first_unit = (floor * units_per_floor) + 1
      (first_unit...first_unit+units_per_floor).to_a.each do |unit_num|
        Geometry.set_unit_beds_baths_spaces(model, unit_num, [living_space])
      end
    
    end
    
    first_unit = res_units - units_remainder + 1
    spaces = model.getSpaces
    i = 0
    (first_unit..res_units).to_a.each do |unit_num|
      Geometry.set_unit_beds_baths_spaces(model, unit_num, [spaces[i]])
      i += 1
    end    
    
    # Store dwelling unit information (for consistency with multifamily buildings)
    model.getBuilding.setStandardsNumberOfLivingUnits(res_units)    
    
    return true

  end
  
end

# register the measure to be used by the application
CreateResidentialMultifamilyGeometry.new.registerWithApplication
