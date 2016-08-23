# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/reference/measure_writing_guide/

require "#{File.dirname(__FILE__)}/resources/constants"
require "#{File.dirname(__FILE__)}/resources/geometry"

# start the measure
class CreateResidentialMultifamilyApartmentsInteriorCorridorGeometry < OpenStudio::Ruleset::ModelUserScript

  # human readable name
  def name
    return "Create Residential Multifamily Apartments Interior Corridor Geometry"
  end

  # human readable description
  def description
    return "Sets the basic geometry for the apartments w/interior corridor."
  end

  # human readable description of modeling approach
  def modeler_description
    return "Sets the basic geometry for the apartments w/interior corridor by cloning a prototype unit."
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
    num_units.setDefaultValue(24)
    args << num_units
    
    #make an argument for number of floors
    num_units_per_floor = OpenStudio::Ruleset::OSArgument::makeIntegerArgument("num_units_per_floor",true)
    num_units_per_floor.setDisplayName("Num Units Per Floor")
    num_units_per_floor.setUnits("#")
    num_units_per_floor.setDescription("The number of units per floor.")
    num_units_per_floor.setDefaultValue(8)
    args << num_units_per_floor        

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
    
    #make an argument for corridor width
    corr_width = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("corr_width", true)
    corr_width.setDisplayName("Corridor Width")
    corr_width.setUnits("ft")
    corr_width.setDescription("The width of the corridor.")
    corr_width.setDefaultValue(4.0)
    args << corr_width    
    
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
    num_units_per_floor = runner.getIntegerArgumentValue("num_units_per_floor",user_arguments)
    inset_width = OpenStudio::convert(runner.getDoubleArgumentValue("inset_width",user_arguments),"ft","m").get
    inset_depth = OpenStudio::convert(runner.getDoubleArgumentValue("inset_depth",user_arguments),"ft","m").get
    inset_pos = runner.getStringArgumentValue("inset_pos",user_arguments)
    corr_width = OpenStudio::convert(runner.getDoubleArgumentValue("corr_width",user_arguments),"ft","m").get
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
    unless num_units_per_floor % 2 == 0
      runner.registerError("The number of units per floor must be even.")
      return false
    end
    
    # starting spaces
    starting_spaces = model.getSpaces
    runner.registerInitialCondition("The building started with #{starting_spaces.size} spaces.")    
    
    # calculate the dimensions of the building
    footprint = unit_ffa + inset_width * inset_depth
    x = Math.sqrt(footprint / aspect_ratio)
    y = footprint / x
    
    # create the front prototype unit
    nw_point = OpenStudio::Point3d.new(0, 0, 0)
    ne_point = OpenStudio::Point3d.new(x, 0, 0)
    sw_point = OpenStudio::Point3d.new(0, -y, 0)
    se_point = OpenStudio::Point3d.new(x, -y, 0)
    if inset_width * inset_depth > 0
      if inset_pos == "Right"
        inset_point = OpenStudio::Point3d.new(x - inset_width, inset_depth - y, 0)
        front_point = OpenStudio::Point3d.new(x - inset_width, -y, 0)
        side_point = OpenStudio::Point3d.new(x, inset_depth - y, 0)
        living_polygon = Geometry.make_polygon(sw_point, nw_point, ne_point, side_point, inset_point, front_point)
        inset_point = OpenStudio::Point3d.new(x - inset_width, inset_depth - y, living_height)
        side_point = OpenStudio::Point3d.new(x, inset_depth - y, living_height)
        se_point = OpenStudio::Point3d.new(x, -y, living_height)
        front_point = OpenStudio::Point3d.new(x - inset_width, -y, living_height)
        shading_surface = OpenStudio::Model::ShadingSurface.new(OpenStudio::Point3dVector.new([inset_point, side_point, se_point, front_point]), model)        
      else
        inset_point = OpenStudio::Point3d.new(inset_width, inset_depth - y, 0)
        front_point = OpenStudio::Point3d.new(inset_width, -y, 0)
        side_point = OpenStudio::Point3d.new(0, inset_depth - y, 0)
        living_polygon = Geometry.make_polygon(side_point, nw_point, ne_point, se_point, front_point, inset_point)
        inset_point = OpenStudio::Point3d.new(inset_width, inset_depth - y, living_height)
        front_point = OpenStudio::Point3d.new(inset_width, -y, living_height)
        sw_point = OpenStudio::Point3d.new(0, -y, living_height)
        side_point = OpenStudio::Point3d.new(0, inset_depth - y, living_height)
        shading_surface = OpenStudio::Model::ShadingSurface.new(OpenStudio::Point3dVector.new([inset_point, front_point, sw_point, side_point]), model)        
      end
    else
      living_polygon = Geometry.make_polygon(sw_point, nw_point, ne_point, se_point)
    end
    
    # create living zone
    living_zone = OpenStudio::Model::ThermalZone.new(model)
    living_zone.setName(Constants.LivingZone)
    
    # first floor front
    living_spaces_front = []
    living_space = OpenStudio::Model::Space::fromFloorPrint(living_polygon, living_height, model)
    living_space = living_space.get
    living_space_name = Constants.LivingSpace(1)
    living_space.setName(living_space_name)
    living_space.setThermalZone(living_zone)
    
    # add the shade
    if inset_width * inset_depth > 0
      shading_surface_group = OpenStudio::Model::ShadingSurfaceGroup.new(model)      
      shading_surface_group.setSpace(living_space)
      shading_surface.setShadingSurfaceGroup(shading_surface_group)
    end
    
    living_spaces_front << living_space
    
    # create the front unit
    Geometry.set_unit_beds_baths_spaces(model, 1, living_spaces_front)
        
    # create the prototype corridor
    if corr_width > 0
      nw_point = OpenStudio::Point3d.new(0, corr_width, 0)
      ne_point = OpenStudio::Point3d.new(x * (num_units_per_floor / 2), corr_width, 0)
      sw_point = OpenStudio::Point3d.new(0, 0, 0)
      se_point = OpenStudio::Point3d.new(x * (num_units_per_floor / 2), 0, 0) 
      corr_polygon = Geometry.make_polygon(sw_point, nw_point, ne_point, se_point)

      # create corridor zone
      corridor_zone = OpenStudio::Model::ThermalZone.new(model)
      corridor_zone.setName(Constants.CorridorZone)
      
      # first floor corridor
      corridor_spaces = []
      corridor_space = OpenStudio::Model::Space::fromFloorPrint(corr_polygon, living_height, model)
      corridor_space = corridor_space.get
      corridor_space_name = Constants.CorridorSpace
      corridor_space.setName(corridor_space_name)
      corridor_space.setThermalZone(corridor_zone)
      corridor_spaces << corridor_space
    end
        
    # create the back prototype unit
    nw_point = OpenStudio::Point3d.new(0, y + corr_width, 0)
    ne_point = OpenStudio::Point3d.new(x, y + corr_width, 0)
    sw_point = OpenStudio::Point3d.new(0, corr_width, 0)
    se_point = OpenStudio::Point3d.new(x, corr_width, 0)
    if inset_width * inset_depth > 0
      if inset_pos == "Right"
        inset_point = OpenStudio::Point3d.new(x - inset_width, y - inset_depth + corr_width, 0)
        front_point = OpenStudio::Point3d.new(x - inset_width, y + corr_width, 0)
        side_point = OpenStudio::Point3d.new(x, y - inset_depth + corr_width, 0)
        living_polygon = Geometry.make_polygon(sw_point, nw_point, front_point, inset_point, side_point, se_point)
        inset_point = OpenStudio::Point3d.new(x - inset_width, y - inset_depth + corr_width, living_height)
        side_point = OpenStudio::Point3d.new(x, y - inset_depth + corr_width, living_height)
        ne_point = OpenStudio::Point3d.new(x, y + corr_width, living_height)
        front_point = OpenStudio::Point3d.new(x - inset_width, y + corr_width, living_height)
        shading_surface = OpenStudio::Model::ShadingSurface.new(OpenStudio::Point3dVector.new([inset_point, front_point, ne_point, side_point]), model)        
      else
        inset_point = OpenStudio::Point3d.new(inset_width, y - inset_depth + corr_width, 0)
        front_point = OpenStudio::Point3d.new(inset_width, y + corr_width, 0)
        side_point = OpenStudio::Point3d.new(0, y - inset_depth + corr_width, 0)
        living_polygon = Geometry.make_polygon(side_point, inset_point, front_point, ne_point, se_point, sw_point)
        inset_point = OpenStudio::Point3d.new(inset_width, y - inset_depth + corr_width, living_height)
        front_point = OpenStudio::Point3d.new(inset_width, y + corr_width, living_height)
        nw_point = OpenStudio::Point3d.new(0, y + corr_width, living_height)
        side_point = OpenStudio::Point3d.new(0, y - inset_depth + corr_width, living_height)
        shading_surface = OpenStudio::Model::ShadingSurface.new(OpenStudio::Point3dVector.new([inset_point, side_point, nw_point, front_point]), model)        
      end
      shading_surface_group = OpenStudio::Model::ShadingSurfaceGroup.new(model)      
      shading_surface_group.setSpace(living_space)
      shading_surface.setShadingSurfaceGroup(shading_surface_group)      
    else
      living_polygon = Geometry.make_polygon(sw_point, nw_point, ne_point, se_point)
    end
    
    # create living zone
    living_zone = OpenStudio::Model::ThermalZone.new(model)
    living_zone.setName(Constants.LivingZone)
    
    # first floor back
    living_spaces_back = []
    living_space = OpenStudio::Model::Space::fromFloorPrint(living_polygon, living_height, model)
    living_space = living_space.get
    living_space_name = Constants.LivingSpace(1)
    living_space.setName(living_space_name)
    living_space.setThermalZone(living_zone)
    
    # add the shade
    if inset_width * inset_depth > 0
      shading_surface_group = OpenStudio::Model::ShadingSurfaceGroup.new(model)      
      shading_surface_group.setSpace(living_space)
      shading_surface.setShadingSurfaceGroup(shading_surface_group)
    end    
    
    living_spaces_back << living_space
    
    # create the back unit
    Geometry.set_unit_beds_baths_spaces(model, 2, living_spaces_back)       
    
    floor = 0
    pos = 0
    (2...num_units).to_a.each do |unit_num|

      if unit_num % num_units_per_floor == 0
        floor += living_height
        pos = -1
        
        if corr_width > 0
        
          corridor_zone = OpenStudio::Model::ThermalZone.new(model)
          corridor_zone.setName(Constants.CorridorZone)        
          
          corridor_spaces.each do |corridor_space|
            new_corridor_space = corridor_space.clone.to_Space.get
          
            m = OpenStudio::Matrix.new(4,4,0)
            m[0,0] = 1
            m[1,1] = 1
            m[2,2] = 1
            m[3,3] = 1
            m[2,3] = -floor
            new_corridor_space.changeTransformation(OpenStudio::Transformation.new(m))
            new_corridor_space.setZOrigin(0)
            new_corridor_space.setThermalZone(corridor_zone)          
          end
        
        end
      
      end
    
      living_zone = OpenStudio::Model::ThermalZone.new(model)
      living_zone.setName(Constants.LivingZone)
      
      new_living_spaces = []
      if unit_num % 2 == 0
        living_spaces = living_spaces_front
        pos += 1
      else
        living_spaces = living_spaces_back
      end
      living_spaces.each do |living_space|
    
        new_living_space = living_space.clone.to_Space.get
      
        m = OpenStudio::Matrix.new(4,4,0)
        m[0,0] = 1
        m[1,1] = 1
        m[2,2] = 1
        m[3,3] = 1
        m[0,3] = -pos * x
        m[2,3] = -floor
        new_living_space.changeTransformation(OpenStudio::Transformation.new(m))
        new_living_space.setXOrigin(0)
        new_living_space.setZOrigin(0)
        new_living_space.setThermalZone(living_zone)      
     
        new_living_spaces << new_living_space
      
      end
      
      Geometry.set_unit_beds_baths_spaces(model, unit_num + 1, new_living_spaces)
      
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
      Geometry.set_unit_space_association(model, unit_num, runner)    
      _nbeds, _nbaths, unit_spaces = Geometry.get_unit_beds_baths_spaces(model, unit_num, runner)
      next if unit_spaces.nil?
      unit_spaces.each do |space|
        spaces_associated_with_units << space
      end
    end
    model.getSpaces.each do |space|
      if not spaces_associated_with_units.include? space and not space.name.to_s.include? Constants.CorridorSpace
        space.remove
      end
    end
    
    model.getSurfaces.each do |surface|
      next unless surface.outsideBoundaryCondition.downcase == "surface"
      next if surface.adjacentSurface.is_initialized
      surface.setOutsideBoundaryCondition("Adiabatic")
    end
    
    # Store dwelling unit information (for consistency with multifamily buildings)
    model.getBuilding.setStandardsNumberOfLivingUnits(num_units)    
    
    # reporting final condition of model
    runner.registerFinalCondition("The building finished with #{model.getSpaces.size} spaces.")	    
    
    return true

  end
  
end

# register the measure to be used by the application
CreateResidentialMultifamilyApartmentsInteriorCorridorGeometry.new.registerWithApplication