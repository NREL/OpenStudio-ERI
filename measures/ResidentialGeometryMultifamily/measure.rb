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
    return "Sets the basic geometry for the building."
  end

  # human readable description of modeling approach
  def modeler_description
    return "Creates multifamily geometry."
  end

  # define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Ruleset::OSArgumentVector.new

    #make an argument for unit living space floor area
    unit_ffa = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("unit_ffa",true)
    unit_ffa.setDisplayName("Unit Finished Floor Area")
    unit_ffa.setUnits("ft^2")
    unit_ffa.setDescription("Unit floor area of the finished space (including any finished basement floor area).")
    unit_ffa.setDefaultValue(900.0)
    args << unit_ffa
    
    #make an argument for living space height
    living_height = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("living_height",true)
    living_height.setDisplayName("Wall Height (Per Floor)")
    living_height.setUnits("ft")
    living_height.setDescription("The height of the living space (and garage) walls.")
    living_height.setDefaultValue(8.0)
    args << living_height

    #make an argument for total number of floors
    building_num_floors = OpenStudio::Ruleset::OSArgument::makeIntegerArgument("building_num_floors",true)
    building_num_floors.setDisplayName("Building Num Floors")
    building_num_floors.setUnits("#")
    building_num_floors.setDescription("The number of floors above grade. Must be multiplier of number of floors per unit.")
    building_num_floors.setDefaultValue(1)
    args << building_num_floors

    #make an argument for number of units per floor
    num_units_per_floor = OpenStudio::Ruleset::OSArgument::makeIntegerArgument("num_units_per_floor",true)
    num_units_per_floor.setDisplayName("Num Units Per Floor")
    num_units_per_floor.setUnits("#")
    num_units_per_floor.setDescription("The number of units per floor.")
    num_units_per_floor.setDefaultValue(2)
    args << num_units_per_floor      

    #make an argument for number of floors per unit
    num_floors_per_unit = OpenStudio::Ruleset::OSArgument::makeIntegerArgument("num_stories_per_unit",true)
    num_floors_per_unit.setDisplayName("Num Stories Per Unit")
    num_floors_per_unit.setUnits("#")
    num_floors_per_unit.setDescription("The number of stories per unit.")
    num_floors_per_unit.setDefaultValue(1)
    args << num_floors_per_unit       
    
    #make an argument for unit aspect ratio
    unit_aspect_ratio = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("unit_aspect_ratio",true)
    unit_aspect_ratio.setDisplayName("Unit Aspect Ratio")
    unit_aspect_ratio.setUnits("FB/LR")
    unit_aspect_ratio.setDescription("The ratio of the front/back wall length to the left/right wall length.")
    unit_aspect_ratio.setDefaultValue(2.0)
    args << unit_aspect_ratio
    
    #make an argument for unit offset
    offset = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("offset", true)
    offset.setDisplayName("Offset Depth")
    offset.setUnits("ft")
    offset.setDescription("The depth of the offset.")
    offset.setDefaultValue(0.0)
    args << offset    
    
    #make an argument for corridor width
    corr_width = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("corr_width", true)
    corr_width.setDisplayName("Corridor Width")
    corr_width.setUnits("ft")
    corr_width.setDescription("The width of the corridor.")
    corr_width.setDefaultValue(0.0)
    args << corr_width
    
    #make an argument for corridor position
    corr_pos_display_names = OpenStudio::StringVector.new
    corr_pos_display_names << "None"
    corr_pos_display_names << "Double-Loaded Interior"
    corr_pos_display_names << "Single Exterior (Front)"
    corr_pos_display_names << "Double Exterior"
	
    corr_pos = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("corr_pos", corr_pos_display_names, true)
    corr_pos.setDisplayName("Corridor Position")
    corr_pos.setDescription("The position of the corridor.")
    corr_pos.setDefaultValue("None")
    args << corr_pos
    
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
    building_num_floors = runner.getIntegerArgumentValue("building_num_floors",user_arguments)
    num_units_per_floor = runner.getIntegerArgumentValue("num_units_per_floor",user_arguments)
    num_stories_per_unit = runner.getIntegerArgumentValue("num_stories_per_unit",user_arguments)
    unit_aspect_ratio = runner.getDoubleArgumentValue("unit_aspect_ratio",user_arguments)
    offset = OpenStudio::convert(runner.getDoubleArgumentValue("offset",user_arguments),"ft","m").get
    corr_width = OpenStudio::convert(runner.getDoubleArgumentValue("corr_width",user_arguments),"ft","m").get
    corr_pos = runner.getStringArgumentValue("corr_pos",user_arguments)
    inset_width = OpenStudio::convert(runner.getDoubleArgumentValue("inset_width",user_arguments),"ft","m").get
    inset_depth = OpenStudio::convert(runner.getDoubleArgumentValue("inset_depth",user_arguments),"ft","m").get
    inset_pos = runner.getStringArgumentValue("inset_pos",user_arguments)
    
    # error checking
    if model.getSpaces.size > 0
      runner.registerError("Starting model is not empty.")
      return false
    end
    if unit_aspect_ratio < 0
      runner.registerError("Invalid aspect ratio entered.")
      return false
    end
    if building_num_floors % num_stories_per_unit != 0
      runner.registerError("Number of building floors is not a multiplier of the number of stories per unit.")
      return false
    end
    if offset > 0 and corr_width > 0
      runner.registerWarning("Cannot handle unit offset with a corridor. Setting the offset to zero.")
      offset = 0
    end
    if corr_pos == "None" and corr_width > 0
      runner.registerWarning("Specified no corridor with a nonzero corridor width. Assuming a single exterior access in front.")
      corr_pos = "Single Exterior (Front)"
    end
    if corr_pos == "Double-Loaded Interior" and corr_width == 0
      runner.registerWarning("Specified an interior corridor with a zero corridor width. Assuming the building has front units as well as adjacent rear units.")
      corr_pos = "Double Exterior"
    end
    if corr_pos == "Double-Loaded Interior" and num_units_per_floor % 2 != 0
      runner.registerWarning("Specified a double-loaded corridor and an odd number of units per floor. Subtracting one unit per floor.")
      num_units_per_floor -= 1
    end
    
    num_units = num_units_per_floor * building_num_floors / num_stories_per_unit
    
    # starting spaces
    starting_spaces = model.getSpaces
    runner.registerInitialCondition("The building started with #{starting_spaces.size} spaces.") 
    
    # calculate the dimensions of the unit
    footprint = (unit_ffa / num_stories_per_unit) + inset_width * inset_depth
    x = Math.sqrt(footprint / unit_aspect_ratio)
    y = footprint / x    
    
    # create the front prototype unit
    nw_point = OpenStudio::Point3d.new(0, 0, 0)
    ne_point = OpenStudio::Point3d.new(x, 0, 0)
    sw_point = OpenStudio::Point3d.new(0, -y, 0)
    se_point = OpenStudio::Point3d.new(x, -y, 0)
    if inset_width * inset_depth > 0
      if inset_pos == "Right"
        # unit footprint
        inset_point = OpenStudio::Point3d.new(x - inset_width, inset_depth - y, 0)
        front_point = OpenStudio::Point3d.new(x - inset_width, -y, 0)
        side_point = OpenStudio::Point3d.new(x, inset_depth - y, 0)
        living_polygon = Geometry.make_polygon(sw_point, nw_point, ne_point, side_point, inset_point, front_point)
        # unit shading
        inset_point = OpenStudio::Point3d.new(x - inset_width, inset_depth - y, living_height)
        side_point = OpenStudio::Point3d.new(x, inset_depth - y, living_height)
        se_point = OpenStudio::Point3d.new(x, -y, living_height)
        front_point = OpenStudio::Point3d.new(x - inset_width, -y, living_height)
        shading_surface = OpenStudio::Model::ShadingSurface.new(OpenStudio::Point3dVector.new([inset_point, side_point, se_point, front_point]), model)        
      else
        # unit footprint
        inset_point = OpenStudio::Point3d.new(inset_width, inset_depth - y, 0)
        front_point = OpenStudio::Point3d.new(inset_width, -y, 0)
        side_point = OpenStudio::Point3d.new(0, inset_depth - y, 0)
        living_polygon = Geometry.make_polygon(side_point, nw_point, ne_point, se_point, front_point, inset_point)
        # unit shading
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
    
    # additional floors
    (1...num_stories_per_unit).to_a.each do |story|
    
      new_living_space = living_space.clone.to_Space.get
      
      m = OpenStudio::Matrix.new(4,4,0)
      m[0,0] = 1
      m[1,1] = 1
      m[2,2] = 1
      m[3,3] = 1
      m[2,3] = living_height * story
      new_living_space.setTransformation(OpenStudio::Transformation.new(m))
      new_living_space.setThermalZone(living_zone)
      
      living_spaces_front << new_living_space
            
    end
    
    # create the unit
    Geometry.set_unit_beds_baths_spaces(model, 1, living_spaces_front)
    
    # create back units
    if corr_pos == "Double-Loaded Interior" or corr_pos == "Double Exterior" # units in front and back
    
      if corr_pos == "Double-Loaded Interior"
        interior_corr_width = corr_width
      else
        interior_corr_width = 0
      end
             
      # create the back prototype unit
      nw_point = OpenStudio::Point3d.new(0, y + interior_corr_width, 0)
      ne_point = OpenStudio::Point3d.new(x, y + interior_corr_width, 0)
      sw_point = OpenStudio::Point3d.new(0, interior_corr_width, 0)
      se_point = OpenStudio::Point3d.new(x, interior_corr_width, 0)
      if inset_width * inset_depth > 0
        if inset_pos == "Right"
          inset_point = OpenStudio::Point3d.new(x - inset_width, y - inset_depth + interior_corr_width, 0)
          front_point = OpenStudio::Point3d.new(x - inset_width, y + interior_corr_width, 0)
          side_point = OpenStudio::Point3d.new(x, y - inset_depth + interior_corr_width, 0)
          living_polygon = Geometry.make_polygon(sw_point, nw_point, front_point, inset_point, side_point, se_point)
          inset_point = OpenStudio::Point3d.new(x - inset_width, y - inset_depth + interior_corr_width, living_height)
          side_point = OpenStudio::Point3d.new(x, y - inset_depth + interior_corr_width, living_height)
          ne_point = OpenStudio::Point3d.new(x, y + interior_corr_width, living_height)
          front_point = OpenStudio::Point3d.new(x - inset_width, y + interior_corr_width, living_height)
          shading_surface = OpenStudio::Model::ShadingSurface.new(OpenStudio::Point3dVector.new([inset_point, front_point, ne_point, side_point]), model)        
        else
          inset_point = OpenStudio::Point3d.new(inset_width, y - inset_depth + interior_corr_width, 0)
          front_point = OpenStudio::Point3d.new(inset_width, y + interior_corr_width, 0)
          side_point = OpenStudio::Point3d.new(0, y - inset_depth + interior_corr_width, 0)
          living_polygon = Geometry.make_polygon(side_point, inset_point, front_point, ne_point, se_point, sw_point)
          inset_point = OpenStudio::Point3d.new(inset_width, y - inset_depth + interior_corr_width, living_height)
          front_point = OpenStudio::Point3d.new(inset_width, y + interior_corr_width, living_height)
          nw_point = OpenStudio::Point3d.new(0, y + interior_corr_width, living_height)
          side_point = OpenStudio::Point3d.new(0, y - inset_depth + interior_corr_width, living_height)
          shading_surface = OpenStudio::Model::ShadingSurface.new(OpenStudio::Point3dVector.new([inset_point, side_point, nw_point, front_point]), model)        
        end    
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
      
      # additional floors
      (1...num_stories_per_unit).to_a.each do |story|
      
        new_living_space = living_space.clone.to_Space.get
        
        m = OpenStudio::Matrix.new(4,4,0)
        m[0,0] = 1
        m[1,1] = 1
        m[2,2] = 1
        m[3,3] = 1
        m[2,3] = living_height * story
        new_living_space.setTransformation(OpenStudio::Transformation.new(m))
        new_living_space.setThermalZone(living_zone)
        
        living_spaces_back << new_living_space
              
      end
      
      # create the back unit
      Geometry.set_unit_beds_baths_spaces(model, 2, living_spaces_back)     
    
      floor = 0
      pos = 0
      (3..num_units).to_a.each do |unit_num|

        # front or back unit
        if unit_num % 2 != 0
          living_spaces = living_spaces_front
          pos += 1
        else
          living_spaces = living_spaces_back
        end
        
        living_zone = OpenStudio::Model::ThermalZone.new(model)
        living_zone.setName(Constants.LivingZone)        
      
        new_living_spaces = []
        living_spaces.each do |living_space|
      
          new_living_space = living_space.clone.to_Space.get
        
          m = OpenStudio::Matrix.new(4,4,0)
          m[0,0] = 1
          m[1,1] = 1
          m[2,2] = 1
          m[3,3] = 1
          m[0,3] = -pos * x
          if (pos + 1) % 2 == 0
            m[1,3] = -offset
          end          
          m[2,3] = -floor
          new_living_space.changeTransformation(OpenStudio::Transformation.new(m))
          new_living_space.setXOrigin(0)
          new_living_space.setYOrigin(0)
          new_living_space.setZOrigin(0)
          new_living_space.setThermalZone(living_zone)
       
          new_living_spaces << new_living_space
        
        end        
      
        Geometry.set_unit_beds_baths_spaces(model, unit_num, new_living_spaces)
              
        if unit_num % num_units_per_floor == 0      
        
          # which floor
          floor += living_height * num_stories_per_unit
          pos = -1

        end       
        
      end

      # corridors
      if corr_width > 0
      
        if corr_pos == "Double-Loaded Interior"
      
          # create the prototype corridor
          nw_point = OpenStudio::Point3d.new(0, interior_corr_width, 0)
          ne_point = OpenStudio::Point3d.new(x * (num_units_per_floor / 2), interior_corr_width, 0)
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
          top_floor_corridor_space = corridor_space
          
          (1...building_num_floors).to_a.each do |floor|
          
            corridor_zone = OpenStudio::Model::ThermalZone.new(model)
            corridor_zone.setName(Constants.CorridorZone)
            new_corridor_space = corridor_space.clone.to_Space.get
            m = OpenStudio::Matrix.new(4,4,0)
            m[0,0] = 1
            m[1,1] = 1
            m[2,2] = 1
            m[3,3] = 1
            m[2,3] = -floor * living_height
            new_corridor_space.changeTransformation(OpenStudio::Transformation.new(m))
            new_corridor_space.setZOrigin(0)
            new_corridor_space.setThermalZone(corridor_zone)
            top_floor_corridor_space = new_corridor_space
          
          end
          
          top_floor_corridor_space.surfaces.each do |surface|
            next unless surface.outsideBoundaryCondition.downcase == "outdoors"
            next unless surface.surfaceType.downcase == "roofceiling"
            surface.setOutsideBoundaryCondition("Adiabatic")
          end
          
        else
          
          # front access
          (1..building_num_floors).to_a.each do |floor|

            nw_point = OpenStudio::Point3d.new(0, -y, floor * living_height)
            ne_point = OpenStudio::Point3d.new(x * (num_units_per_floor / 2), -y, floor * living_height)
            sw_point = OpenStudio::Point3d.new(0, -y - corr_width, floor * living_height)
            se_point = OpenStudio::Point3d.new(x * (num_units_per_floor / 2), -y - corr_width, floor * living_height)
            
            shading_surface = OpenStudio::Model::ShadingSurface.new(OpenStudio::Point3dVector.new([nw_point, ne_point, se_point, sw_point]), model)
            
            shading_surface_group = OpenStudio::Model::ShadingSurfaceGroup.new(model)      
            shading_surface.setShadingSurfaceGroup(shading_surface_group)
          
          end
          
          # rear access
          (1..building_num_floors).to_a.each do |floor|
          
            nw_point = OpenStudio::Point3d.new(0, y + corr_width, floor * living_height)
            ne_point = OpenStudio::Point3d.new(x * (num_units_per_floor / 2), y + corr_width, floor * living_height)
            sw_point = OpenStudio::Point3d.new(0, y, floor * living_height)
            se_point = OpenStudio::Point3d.new(x * (num_units_per_floor / 2), y, floor * living_height)
            
            shading_surface = OpenStudio::Model::ShadingSurface.new(OpenStudio::Point3dVector.new([nw_point, ne_point, se_point, sw_point]), model)
            
            shading_surface_group = OpenStudio::Model::ShadingSurfaceGroup.new(model)      
            shading_surface.setShadingSurfaceGroup(shading_surface_group)
          
          end          
        
        end        
        
      end
    
    else # units only in front
    
      floor = 0
      pos = 0
      (2..num_units).to_a.each do |unit_num|

        living_spaces = living_spaces_front
        pos += 1
        
        living_zone = OpenStudio::Model::ThermalZone.new(model)
        living_zone.setName(Constants.LivingZone)        
      
        new_living_spaces = []
        living_spaces.each do |living_space|
      
          new_living_space = living_space.clone.to_Space.get
        
          m = OpenStudio::Matrix.new(4,4,0)
          m[0,0] = 1
          m[1,1] = 1
          m[2,2] = 1
          m[3,3] = 1
          m[0,3] = -pos * x
          if (pos + 1) % 2 == 0
            m[1,3] = -offset
          end          
          m[2,3] = -floor
          new_living_space.changeTransformation(OpenStudio::Transformation.new(m))
          new_living_space.setXOrigin(0)
          new_living_space.setYOrigin(0)
          new_living_space.setZOrigin(0)
          new_living_space.setThermalZone(living_zone)
       
          new_living_spaces << new_living_space
        
        end        
      
        Geometry.set_unit_beds_baths_spaces(model, unit_num, new_living_spaces)
              
        if unit_num % num_units_per_floor == 0      
        
          # which floor
          floor += living_height * num_stories_per_unit
          pos = -1

        end
      
      end
      
      if corr_width > 0
              
        (1..building_num_floors).to_a.each do |floor|
        
          nw_point = OpenStudio::Point3d.new(0, -y, floor * living_height)
          ne_point = OpenStudio::Point3d.new(x * num_units_per_floor, -y, floor * living_height)
          sw_point = OpenStudio::Point3d.new(0, -y - corr_width, floor * living_height)
          se_point = OpenStudio::Point3d.new(x * num_units_per_floor, -y - corr_width, floor * living_height)
          
          shading_surface = OpenStudio::Model::ShadingSurface.new(OpenStudio::Point3dVector.new([nw_point, ne_point, se_point, sw_point]), model)
          
          shading_surface_group = OpenStudio::Model::ShadingSurfaceGroup.new(model)      
          shading_surface.setShadingSurfaceGroup(shading_surface_group)
        
        end
                          
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
    
    # Store dwelling unit information (for consistency with multifamily buildings)
    model.getBuilding.setStandardsNumberOfLivingUnits(num_units)
    
    return true

  end
  
end

# register the measure to be used by the application
CreateResidentialMultifamilyGeometry.new.registerWithApplication
