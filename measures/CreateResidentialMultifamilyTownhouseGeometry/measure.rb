# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/reference/measure_writing_guide/

require "#{File.dirname(__FILE__)}/resources/constants"
require "#{File.dirname(__FILE__)}/resources/geometry"

# start the measure
class CreateResidentialMultifamilyTownhouseGeometry < OpenStudio::Ruleset::ModelUserScript

  # human readable name
  def name
    return "Create Residential Multifamily Townhouse Geometry"
  end

  # human readable description
  def description
    return "Sets the basic geometry for the townhouse."
  end

  # human readable description of modeling approach
  def modeler_description
    return "Sets the basic geometry for the townhouse by cloning a prototype unit."
  end

  # define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Ruleset::OSArgumentVector.new

    #make an argument for unit living space floor area
    unit_ffa = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("unit_ffa",true)
    unit_ffa.setDisplayName("Finished Floor Area Per Unit")
    unit_ffa.setUnits("ft^2")
    unit_ffa.setDescription("Unit floor area of the finished space (including any finished basement floor area).")
    unit_ffa.setDefaultValue(1000.0)
    args << unit_ffa
	
    #make an argument for living space height
    living_height = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("living_height",true)
    living_height.setDisplayName("Wall Height (Per Floor)")
    living_height.setUnits("ft")
    living_height.setDescription("The height of the living space (and garage) walls.")
    living_height.setDefaultValue(8.0)
    args << living_height
	
    #make an argument for aspect ratio
    aspect_ratio = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("aspect_ratio",true)
    aspect_ratio.setDisplayName("Unit Aspect Ratio")
    aspect_ratio.setUnits("FB/LR")
    aspect_ratio.setDescription("The ratio of the front/back wall length to the left/right wall length.")
    aspect_ratio.setDefaultValue(2.0)
    args << aspect_ratio
    
    #make an argument for number of residential units
    num_units = OpenStudio::Ruleset::OSArgument::makeIntegerArgument("num_units",true)
    num_units.setDisplayName("Num Units")
    num_units.setUnits("#")
    num_units.setDescription("The number of residential units.")
    num_units.setDefaultValue(4)
    args << num_units
    
    #make an argument for number of floors per unit
    num_floors = OpenStudio::Ruleset::OSArgument::makeIntegerArgument("num_floors",true)
    num_floors.setDisplayName("Num Floors Per Unit")
    num_floors.setUnits("#")
    num_floors.setDescription("The number of floors per unit.")
    num_floors.setDefaultValue(2)
    args << num_floors        

    #make an argument for inset width
    inset_width = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("inset_width", true)
    inset_width.setDisplayName("Inset Width")
    inset_width.setUnits("ft")
    inset_width.setDescription("The width of the inset.")
    inset_width.setDefaultValue(0.0)
    args << inset_width
    
    #make an argument for inset depth
    inset_depth = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("inset_depth", true)
    inset_depth.setDisplayName("Inset Depth")
    inset_depth.setUnits("ft")
    inset_depth.setDescription("The depth of the inset.")
    inset_depth.setDefaultValue(0.0)
    args << inset_depth    
    
    #make an argument for inset position
    inset_pos_display_names = OpenStudio::StringVector.new
    inset_pos_display_names << "Right"
    inset_pos_display_names << "Left"
	
    inset_pos = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("inset_pos", inset_pos_display_names, true)
    inset_pos.setDisplayName("Inset Position")
    inset_pos.setDescription("The position of the inset.")
    inset_pos.setDefaultValue("Right")
    args << inset_pos    
    
    #make an argument for unit offset
    offset = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("offset", true)
    offset.setDisplayName("Offset Depth")
    offset.setUnits("ft")
    offset.setDescription("The depth of the offset.")
    offset.setDefaultValue(0.0)
    args << offset
    
    #make an argument for using zone multipliers
    use_zone_mult = OpenStudio::Ruleset::OSArgument::makeBoolArgument("use_zone_mult", true)
    use_zone_mult.setDisplayName("Use Zone Multipliers?")
    use_zone_mult.setDescription("Model only one interior unit with its thermal zone multiplier equal to the number of interior units.")
    use_zone_mult.setDefaultValue(false)
    args << use_zone_mult
    
    return args
  end

  # define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)

    # use the built-in error checking
    if !runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

    unit_ffa = OpenStudio.convert(runner.getDoubleArgumentValue("unit_ffa",user_arguments),"ft^2","m^2").get
    living_height = OpenStudio.convert(runner.getDoubleArgumentValue("living_height",user_arguments),"ft","m").get
    aspect_ratio = runner.getDoubleArgumentValue("aspect_ratio",user_arguments)
    num_units = runner.getIntegerArgumentValue("num_units",user_arguments)
    num_floors = runner.getIntegerArgumentValue("num_floors",user_arguments)
    inset_width = OpenStudio::convert(runner.getDoubleArgumentValue("inset_width",user_arguments),"ft","m").get
    inset_depth = OpenStudio::convert(runner.getDoubleArgumentValue("inset_depth",user_arguments),"ft","m").get
    inset_pos = runner.getStringArgumentValue("inset_pos",user_arguments)
    offset = OpenStudio::convert(runner.getDoubleArgumentValue("offset",user_arguments),"ft","m").get
    use_zone_mult = runner.getBoolArgumentValue("use_zone_mult",user_arguments)
    
    # error checking
    if model.getSpaces.size > 0
      runner.registerError("Starting model is not empty.")
      return false
    end
    if aspect_ratio < 0
      runner.registerError("Invalid aspect ratio entered.")
      return false
    end
    if num_floors > 6
      runner.registerError("Too many floors.")
      return false
    end    
    
    # starting spaces
    starting_spaces = model.getSpaces
    runner.registerInitialCondition("The building started with #{starting_spaces.size} spaces.")    
    
    # calculate the dimensions of the building
    footprint = (unit_ffa / num_floors) + inset_width * inset_depth
    x = Math.sqrt(footprint / aspect_ratio)
    y = footprint / x
    
    # create the prototype unit
    nw_point = OpenStudio::Point3d.new(0, y, 0)
    ne_point = OpenStudio::Point3d.new(x, y, 0)
    sw_point = OpenStudio::Point3d.new(0, 0, 0)
    se_point = OpenStudio::Point3d.new(x, 0, 0)    
    if inset_width * inset_depth > 0
      if inset_pos == "Right"
        inset_point = OpenStudio::Point3d.new(x - inset_width, inset_depth, 0)
        front_point = OpenStudio::Point3d.new(x - inset_width, 0, 0)
        side_point = OpenStudio::Point3d.new(x, inset_depth, 0)
        living_polygon = Geometry.make_polygon(sw_point, nw_point, ne_point, side_point, inset_point, front_point)
      else
        inset_point = OpenStudio::Point3d.new(inset_width, inset_depth, 0)
        front_point = OpenStudio::Point3d.new(inset_width, 0, 0)
        side_point = OpenStudio::Point3d.new(0, inset_depth, 0)
        living_polygon = Geometry.make_polygon(side_point, nw_point, ne_point, se_point, front_point, inset_point)
      end
    else
      living_polygon = Geometry.make_polygon(sw_point, nw_point, ne_point, se_point)
    end
    
    # create living zone
    living_zone = OpenStudio::Model::ThermalZone.new(model)
    living_zone.setName(Constants.LivingZone)
    
    # first floor
    living_spaces = []
    living_space = OpenStudio::Model::Space::fromFloorPrint(living_polygon, living_height, model)
    living_space = living_space.get
    living_space_name = Constants.LivingSpace(1)
    living_space.setName(living_space_name)
    living_space.setThermalZone(living_zone)
    living_spaces << living_space
    
    # additional floors
    if num_floors > 1
      (1...num_floors).to_a.each do |floor|
      
        new_living_space = living_space.clone.to_Space.get
        
        m = OpenStudio::Matrix.new(4,4,0)
        m[0,0] = 1
        m[1,1] = 1
        m[2,2] = 1
        m[3,3] = 1
        m[2,3] = living_height * floor
        new_living_space.setTransformation(OpenStudio::Transformation.new(m))
        new_living_space.setThermalZone(living_zone)
        
        living_spaces << new_living_space
              
      end
    end
    
    # create the unit
    Geometry.set_unit_beds_baths_spaces(model, 1, living_spaces)
        
    (1...num_units).to_a.each do |unit_num|

      if use_zone_mult and (unit_num == 1 or unit_num + 1 == num_units)
        living_zone = OpenStudio::Model::ThermalZone.new(model)
        living_zone.setName(Constants.LivingZone)
        if unit_num == 1
          living_zone.setMultiplier(num_units - 2)
        end
      elsif !use_zone_mult
        living_zone = OpenStudio::Model::ThermalZone.new(model)
        living_zone.setName(Constants.LivingZone)
      end
      
      new_living_spaces = []
      living_spaces.each do |living_space|
    
        new_living_space = living_space.clone.to_Space.get
      
        m = OpenStudio::Matrix.new(4,4,0)
        m[0,0] = 1
        m[1,1] = 1
        m[2,2] = 1
        m[3,3] = 1
        if (unit_num + 1) % 2 == 0
          m[1,3] = -offset
        end
        m[0,3] = -unit_num * x
        new_living_space.changeTransformation(OpenStudio::Transformation.new(m))
        new_living_space.setXOrigin(0)
        new_living_space.setYOrigin(0)
        if (use_zone_mult and (unit_num == 1 or unit_num + 1 == num_units)) or !use_zone_mult
          new_living_space.setThermalZone(living_zone)
        else
          new_living_space.resetThermalZone          
        end        
     
        new_living_spaces << new_living_space
      
      end
      
      if unit_num == 1 or !use_zone_mult
        Geometry.set_unit_beds_baths_spaces(model, unit_num + 1, new_living_spaces)
      elsif use_zone_mult and unit_num + 1 == num_units
        Geometry.set_unit_beds_baths_spaces(model, 3, new_living_spaces)
      end
      
    end   
    
    # put all of the spaces in the model into a vector
    spaces = OpenStudio::Model::SpaceVector.new
    model.getSpaces.each do |space|
      spaces << space
    end    
    
    # intersect and match surfaces for each space in the vector
    OpenStudio::Model.intersectSurfaces(spaces)
    OpenStudio::Model.matchSurfaces(spaces)    

    spaces_associated_with_units = []
    (1..num_units).to_a.each do |unit_num|
      _nbeds, _nbaths, unit_spaces = Geometry.get_unit_beds_baths_spaces(model, unit_num, runner)
      next if unit_spaces.nil?
      unit_spaces.each do |space|
        spaces_associated_with_units << space
      end
    end
    model.getSpaces.each do |space|
      unless spaces_associated_with_units.include? space
        space.remove
      end
    end
    
    model.getSurfaces.each do |surface|
      next unless surface.outsideBoundaryCondition.downcase == "surface"
      next if surface.adjacentSurface.is_initialized
      surface.setOutsideBoundaryCondition("Adiabatic")
    end
    
    # Store dwelling unit information (for consistency with multifamily buildings)
    if use_zone_mult
      num_units = 3
    end
    model.getBuilding.setStandardsNumberOfLivingUnits(num_units)    
    
    # reporting final condition of model
    runner.registerFinalCondition("The building finished with #{model.getSpaces.size} spaces.")	    
    
    return true

  end
  
end

# register the measure to be used by the application
CreateResidentialMultifamilyTownhouseGeometry.new.registerWithApplication
