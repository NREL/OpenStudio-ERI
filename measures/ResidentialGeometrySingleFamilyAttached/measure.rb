# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/reference/measure_writing_guide/

require "#{File.dirname(__FILE__)}/resources/constants"
require "#{File.dirname(__FILE__)}/resources/geometry"

# start the measure
class CreateResidentialSingleFamilyAttachedGeometry < OpenStudio::Ruleset::ModelUserScript

  # human readable name
  def name
    return "Create Residential Single-Family Attached Geometry"
  end

  # human readable description
  def description
    return "Sets the basic geometry for the building."
  end

  # human readable description of modeling approach
  def modeler_description
    return "Creates single-family attached geometry."
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
    building_num_floors.setDescription("The number of floors above grade.")
    building_num_floors.setDefaultValue(1)
    args << building_num_floors

    #make an argument for number of units per floor
    num_units = OpenStudio::Ruleset::OSArgument::makeIntegerArgument("num_units",true)
    num_units.setDisplayName("Num Units")
    num_units.setUnits("#")
    num_units.setDescription("The number of units.")
    num_units.setDefaultValue(2)
    args << num_units
    
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
    offset.setDescription("DOES NOT CURRENTLY WORK WITH ZONE MULTIPLIERS The depth of the offset.")
    offset.setDefaultValue(0.0)
    args << offset
    
    #make an argument for units in back
    has_rear_units = OpenStudio::Ruleset::OSArgument::makeBoolArgument("has_rear_units", true)
    has_rear_units.setDisplayName("Has Rear Units?")
    has_rear_units.setDescription("Whether the building has rear adjacent units.")
    has_rear_units.setDefaultValue(false)
    args << has_rear_units      
    
    #make a choice argument for model objects
    foundation_display_names = OpenStudio::StringVector.new
    foundation_display_names << Constants.SlabFoundationType
    foundation_display_names << Constants.CrawlFoundationType
    foundation_display_names << Constants.UnfinishedBasementFoundationType
    foundation_display_names << Constants.FinishedBasementFoundationType
    foundation_display_names << Constants.PierBeamFoundationType
	
    #make a choice argument for foundation type
    foundation_type = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("foundation_type", foundation_display_names, true)
    foundation_type.setDisplayName("Foundation Type")
    foundation_type.setDescription("The foundation type of the building.")
    foundation_type.setDefaultValue(Constants.SlabFoundationType)
    args << foundation_type

    #make an argument for crawlspace height
    foundation_height = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("foundation_height",true)
    foundation_height.setDisplayName("Crawlspace Height")
    foundation_height.setUnits("ft")
    foundation_height.setDescription("The height of the crawlspace walls.")
    foundation_height.setDefaultValue(3.0)
    args << foundation_height    
    
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
    building_num_floors = runner.getIntegerArgumentValue("building_num_floors",user_arguments)
    num_units = runner.getIntegerArgumentValue("num_units",user_arguments)
    unit_aspect_ratio = runner.getDoubleArgumentValue("unit_aspect_ratio",user_arguments)
    offset = OpenStudio::convert(runner.getDoubleArgumentValue("offset",user_arguments),"ft","m").get
    has_rear_units = runner.getBoolArgumentValue("has_rear_units",user_arguments)
    foundation_type = runner.getStringArgumentValue("foundation_type",user_arguments)
    foundation_height = runner.getDoubleArgumentValue("foundation_height",user_arguments)
    use_zone_mult = runner.getBoolArgumentValue("use_zone_mult",user_arguments)
    
    if foundation_type == Constants.SlabFoundationType
      foundation_height = 0.0
    elsif foundation_type == Constants.UnfinishedBasementFoundationType or foundation_type == Constants.FinishedBasementFoundationType
      foundation_height = 8.0
    end    
    
    # error checking
    if model.getSpaces.size > 0
      runner.registerError("Starting model is not empty.")
      return false
    end
    if foundation_type == Constants.CrawlFoundationType and ( foundation_height < 1.5 or foundation_height > 5.0 )
      runner.registerError("The crawlspace height can be set between 1.5 and 5 ft.")
      return false
    end
    if num_units == 1 and has_rear_units
      runner.registerError("Specified building as having rear units, but didn't specify enough units.")
      return false
    end    
    if unit_aspect_ratio < 0
      runner.registerError("Invalid aspect ratio entered.")
      return false
    end
    
    # Convert to SI
    foundation_height = OpenStudio.convert(foundation_height,"ft","m").get    
        
    # starting spaces
    runner.registerInitialCondition("The building started with #{model.getSpaces.size} spaces.")
    
    # calculate the dimensions of the unit
    footprint = unit_ffa / building_num_floors
    x = Math.sqrt(footprint / unit_aspect_ratio)
    y = footprint / x    
    
    foundation_front_polygon = nil
    foundation_back_polygon = nil
    
    # create the front prototype unit
    nw_point = OpenStudio::Point3d.new(0, 0, 0)
    ne_point = OpenStudio::Point3d.new(x, 0, 0)
    sw_point = OpenStudio::Point3d.new(0, -y, 0)
    se_point = OpenStudio::Point3d.new(x, -y, 0)
    living_polygon = Geometry.make_polygon(sw_point, nw_point, ne_point, se_point)
           
    # foundation
    if foundation_height > 0 and foundation_front_polygon.nil?
      foundation_front_polygon = living_polygon
    end
           
    # create living zone
    living_zone = OpenStudio::Model::ThermalZone.new(model)
    living_zone.setName(Constants.LivingZone(1))
    
    # first floor front
    living_spaces_front = []
    living_space = OpenStudio::Model::Space::fromFloorPrint(living_polygon, living_height, model)
    living_space = living_space.get
    living_space.setName(Constants.LivingSpace(1, 1))
    living_space.setThermalZone(living_zone)
    
    living_spaces_front << living_space
    
    # additional floors
    (2..building_num_floors).to_a.each do |story|
    
      new_living_space = living_space.clone.to_Space.get
      new_living_space.setName(Constants.LivingSpace(story, 1))
      
      m = OpenStudio::Matrix.new(4,4,0)
      m[0,0] = 1
      m[1,1] = 1
      m[2,2] = 1
      m[3,3] = 1
      m[2,3] = living_height * (story - 1)
      new_living_space.setTransformation(OpenStudio::Transformation.new(m))
      new_living_space.setThermalZone(living_zone)
      
      living_spaces_front << new_living_space
            
    end
    
    # create the unit
    unit_spaces_hash = {}
    unit_spaces_hash[1] = living_spaces_front
        
    if has_rear_units # units in front and back
             
      # create the back prototype unit
      nw_point = OpenStudio::Point3d.new(0, y, 0)
      ne_point = OpenStudio::Point3d.new(x, y, 0)
      sw_point = OpenStudio::Point3d.new(0, 0, 0)
      se_point = OpenStudio::Point3d.new(x, 0, 0)
      living_polygon = Geometry.make_polygon(sw_point, nw_point, ne_point, se_point)
      
      # foundation
      if foundation_height > 0 and foundation_back_polygon.nil?
        foundation_back_polygon = living_polygon
      end
      
      # create living zone
      living_zone = OpenStudio::Model::ThermalZone.new(model)
      living_zone.setName(Constants.LivingZone(2))
      
      # first floor back
      living_spaces_back = []
      living_space = OpenStudio::Model::Space::fromFloorPrint(living_polygon, living_height, model)
      living_space = living_space.get
      living_space.setName(Constants.LivingSpace(1, 2))
      living_space.setThermalZone(living_zone) 
      
      living_spaces_back << living_space
      
      # additional floors
      (2..building_num_floors).to_a.each do |story|
      
        new_living_space = living_space.clone.to_Space.get
        new_living_space.setName(Constants.LivingSpace(story, 2))
        
        m = OpenStudio::Matrix.new(4,4,0)
        m[0,0] = 1
        m[1,1] = 1
        m[2,2] = 1
        m[3,3] = 1
        m[2,3] = living_height * (story - 1)
        new_living_space.setTransformation(OpenStudio::Transformation.new(m))
        new_living_space.setThermalZone(living_zone)
        
        living_spaces_back << new_living_space
              
      end
      
      # create the back unit
      unit_spaces_hash[2] = living_spaces_back

      pos = 0
      (3..num_units).to_a.each do |unit_num|

        # front or back unit
        if unit_num % 2 != 0 # odd unit number
          living_spaces = living_spaces_front
          pos += 1
        else # even unit number
          living_spaces = living_spaces_back
        end
        
        living_zone = OpenStudio::Model::ThermalZone.new(model)
        living_zone.setName(Constants.LivingZone(unit_num))        
      
        new_living_spaces = []
        living_spaces.each_with_index do |living_space, story|
      
          new_living_space = living_space.clone.to_Space.get
          new_living_space.setName(Constants.LivingSpace(story + 1, unit_num))
        
          m = OpenStudio::Matrix.new(4,4,0)
          m[0,0] = 1
          m[1,1] = 1
          m[2,2] = 1
          m[3,3] = 1
          m[0,3] = -pos * x
          if (pos + 1) % 2 == 0
            m[1,3] = -offset
          end          
          new_living_space.changeTransformation(OpenStudio::Transformation.new(m))
          new_living_space.setXOrigin(0)
          new_living_space.setYOrigin(0)
          new_living_space.setZOrigin(0)
          new_living_space.setThermalZone(living_zone)
       
          new_living_spaces << new_living_space
        
        end        
      
        unit_spaces_hash[unit_num] = new_living_spaces
        
      end
    
    else # units only in front

      pos = 0
      (2..num_units).to_a.each do |unit_num|

        living_spaces = living_spaces_front
        pos += 1
        
        living_zone = OpenStudio::Model::ThermalZone.new(model)
        living_zone.setName(Constants.LivingZone(unit_num))
      
        new_living_spaces = []
        living_spaces.each_with_index do |living_space, story|
      
          new_living_space = living_space.clone.to_Space.get
          new_living_space.setName(Constants.LivingSpace(story + 1, unit_num))
        
          m = OpenStudio::Matrix.new(4,4,0)
          m[0,0] = 1
          m[1,1] = 1
          m[2,2] = 1
          m[3,3] = 1
          m[0,3] = -pos * x
          if (pos + 1) % 2 == 0
            m[1,3] = -offset
          end          
          new_living_space.changeTransformation(OpenStudio::Transformation.new(m))
          new_living_space.setXOrigin(0)
          new_living_space.setYOrigin(0)
          new_living_space.setZOrigin(0)
          new_living_space.setThermalZone(living_zone)
       
          new_living_spaces << new_living_space
        
        end        
      
        unit_spaces_hash[unit_num] = new_living_spaces
      
      end     
    
    end
    
    # foundation
    if foundation_height > 0
      
      foundation_spaces = []
      
      # foundation front
      foundation_space_front = []
      foundation_space = OpenStudio::Model::Space::fromFloorPrint(foundation_front_polygon, foundation_height, model)
      foundation_space = foundation_space.get
      m = OpenStudio::Matrix.new(4,4,0)
      m[0,0] = 1
      m[1,1] = 1
      m[2,2] = 1
      m[3,3] = 1
      m[2,3] = foundation_height
      foundation_space.changeTransformation(OpenStudio::Transformation.new(m))
      foundation_space.setXOrigin(0)
      foundation_space.setYOrigin(0)
      foundation_space.setZOrigin(0)
      
      if foundation_type == Constants.FinishedBasementFoundationType
        foundation_zone = OpenStudio::Model::ThermalZone.new(model)
        foundation_space.setName(Constants.FinishedBasementSpace(1))
        foundation_zone.setName(Constants.FinishedBasementZone(1))
        foundation_space.setThermalZone(foundation_zone)
      end
      
      foundation_space_front << foundation_space
      foundation_spaces << foundation_space
      
      # create the unit
      if foundation_type == Constants.FinishedBasementFoundationType
        unit_spaces_hash[1] << foundation_space
      end

      if has_rear_units # units in front and back
            
        # foundation back
        foundation_space_back = []
        foundation_space = OpenStudio::Model::Space::fromFloorPrint(foundation_back_polygon, foundation_height, model)
        foundation_space = foundation_space.get
        m = OpenStudio::Matrix.new(4,4,0)
        m[0,0] = 1
        m[1,1] = 1
        m[2,2] = 1
        m[3,3] = 1
        m[2,3] = foundation_height
        foundation_space.changeTransformation(OpenStudio::Transformation.new(m))
        foundation_space.setXOrigin(0)
        foundation_space.setYOrigin(0)
        foundation_space.setZOrigin(0)
        
        if foundation_type == Constants.FinishedBasementFoundationType
          foundation_zone = OpenStudio::Model::ThermalZone.new(model)
          foundation_space.setName(Constants.FinishedBasementSpace(2))
          foundation_zone.setName(Constants.FinishedBasementZone(2))
          foundation_space.setThermalZone(foundation_zone)
        end
        
        foundation_space_back << foundation_space
        foundation_spaces << foundation_space
        
        # create the unit
        if foundation_type == Constants.FinishedBasementFoundationType
          unit_spaces_hash[2] << foundation_space
        end
    
        pos = 0
        (3..num_units).to_a.each do |unit_num|

          # front or back unit
          if unit_num % 2 != 0 # odd unit number
            living_spaces = foundation_space_front
            pos += 1
          else # even unit number
            living_spaces = foundation_space_back
          end
          
          if foundation_type == Constants.FinishedBasementFoundationType
            living_zone = OpenStudio::Model::ThermalZone.new(model)
            living_zone.setName(Constants.FinishedBasementZone(unit_num))
          end
        
          living_spaces.each do |living_space|
        
            new_living_space = living_space.clone.to_Space.get
            if foundation_type == Constants.FinishedBasementFoundationType
              new_living_space.setName(Constants.FinishedBasementSpace(unit_num))
            end
          
            m = OpenStudio::Matrix.new(4,4,0)
            m[0,0] = 1
            m[1,1] = 1
            m[2,2] = 1
            m[3,3] = 1
            m[0,3] = -pos * x
            if (pos + 1) % 2 == 0
              m[1,3] = -offset
            end          
            new_living_space.changeTransformation(OpenStudio::Transformation.new(m))
            new_living_space.setXOrigin(0)
            new_living_space.setYOrigin(0)
            new_living_space.setZOrigin(0)
            if foundation_type == Constants.FinishedBasementFoundationType
              new_living_space.setThermalZone(living_zone)
            end
         
            foundation_spaces << new_living_space
            
            if foundation_type == Constants.FinishedBasementFoundationType
              unit_spaces_hash[unit_num] << new_living_space
            end            
          
          end
          
        end
    
      else # units only in front
      
        pos = 0
        (2..num_units).to_a.each do |unit_num|

          living_spaces = foundation_space_front
          pos += 1
          
          if foundation_type == Constants.FinishedBasementFoundationType
            living_zone = OpenStudio::Model::ThermalZone.new(model)
            living_zone.setName(Constants.FinishedBasementZone(unit_num))
          end
        
          living_spaces.each do |living_space|
            
            new_living_space = living_space.clone.to_Space.get
            if foundation_type == Constants.FinishedBasementFoundationType
              new_living_space.setName(Constants.FinishedBasementSpace(unit_num))
            end
          
            m = OpenStudio::Matrix.new(4,4,0)
            m[0,0] = 1
            m[1,1] = 1
            m[2,2] = 1
            m[3,3] = 1
            m[0,3] = -pos * x
            if (pos + 1) % 2 == 0
              m[1,3] = -offset
            end          
            new_living_space.changeTransformation(OpenStudio::Transformation.new(m))
            new_living_space.setXOrigin(0)
            new_living_space.setYOrigin(0)
            new_living_space.setZOrigin(0)
            if foundation_type == Constants.FinishedBasementFoundationType
              new_living_space.setThermalZone(living_zone)
            end
         
            foundation_spaces << new_living_space
          
            if foundation_type == Constants.FinishedBasementFoundationType
              unit_spaces_hash[unit_num] << new_living_space
            end
            
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
    
      if [Constants.CrawlFoundationType, Constants.UnfinishedBasementFoundationType].include? foundation_type
        foundation_space = Geometry.make_one_space_from_multiple_spaces(model, foundation_spaces)
        if foundation_type == Constants.CrawlFoundationType
          foundation_space.setName(Constants.CrawlSpace)
          foundation_zone = OpenStudio::Model::ThermalZone.new(model)
          foundation_zone.setName(Constants.CrawlZone)
          foundation_space.setThermalZone(foundation_zone)
        elsif foundation_type == Constants.UnfinishedBasementFoundationType
          foundation_space.setName(Constants.UnfinishedBasementSpace)
          foundation_zone = OpenStudio::Model::ThermalZone.new(model)
          foundation_zone.setName(Constants.UnfinishedBasementZone)
          foundation_space.setThermalZone(foundation_zone)
        end
      end
    
      # set foundation walls to ground
      spaces = model.getSpaces
      spaces.each do |space|
        if space.name.to_s.start_with? Constants.CrawlSpace or space.name.to_s.start_with? Constants.UnfinishedBasementSpace or space.name.to_s.start_with? Constants.FinishedBasementSpace
          surfaces = space.surfaces
          surfaces.each do |surface|
            next if surface.surfaceType.downcase != "wall"
            surface.setOutsideBoundaryCondition("Ground")
          end
        end
      end

    end     
    
    unit_hash = {}
    unit_spaces_hash.each do |unit_num, spaces|
      # Store building unit information
      unit = OpenStudio::Model::BuildingUnit.new(model)
      unit.setBuildingUnitType(Constants.BuildingUnitTypeResidential)
      unit.setName(Constants.ObjectNameBuildingUnit(unit_num))
      spaces.each do |space|
        space.setBuildingUnit(unit)
      end
      unit_hash[unit_num] = unit
    end
    
    # put all of the spaces in the model into a vector
    spaces = OpenStudio::Model::SpaceVector.new
    model.getSpaces.each do |space|
      spaces << space
    end    
    
    # intersect and match surfaces for each space in the vector
    OpenStudio::Model.intersectSurfaces(spaces)
    OpenStudio::Model.matchSurfaces(spaces)
    
    if use_zone_mult and ((num_units > 3 and not has_rear_units) or (num_units > 7 and has_rear_units))
      (2..num_units).to_a.each do |unit_num|

        if not has_rear_units
          
          zone_names_for_multiplier_adjustment = []        
          space_names_to_remove = []
          unit_spaces = unit_hash[unit_num].spaces
          if unit_num == 2 # leftmost interior unit
            unit_spaces.each do |space|
              thermal_zone = space.thermalZone.get
              zone_names_for_multiplier_adjustment << thermal_zone.name.to_s
            end
            model.getThermalZones.each do |thermal_zone|
              zone_names_for_multiplier_adjustment.each do |tz|
                if thermal_zone.name.to_s == tz
                  thermal_zone.setMultiplier(num_units - 2)
                end
              end
            end            
          elsif unit_num < num_units # interior units that get removed
            unit_spaces.each do |space|
              space_names_to_remove << space.name.to_s
            end
            unit_hash[unit_num].remove
            model.getSpaces.each do |space|
              space_names_to_remove.each do |s|
                if space.name.to_s == s
                  if space.thermalZone.is_initialized
                    thermal_zone = space.thermalZone.get
                    thermal_zone.remove
                  end
                  space.remove
                end
              end
            end
          end       
          
        else # has rear units
          next unless unit_num > 2

          zone_names_for_multiplier_adjustment = []        
          space_names_to_remove = []
          unit_spaces = unit_hash[unit_num].spaces
          if unit_num == 3 or unit_num == 4 # leftmost interior units
            unit_spaces.each do |space|
              thermal_zone = space.thermalZone.get
              zone_names_for_multiplier_adjustment << thermal_zone.name.to_s
            end
            model.getThermalZones.each do |thermal_zone|
              zone_names_for_multiplier_adjustment.each do |tz|
                if thermal_zone.name.to_s == tz
                  thermal_zone.setMultiplier(num_units / 2 - 2)
                end
              end
            end
          elsif unit_num != num_units - 1 and unit_num != num_units # interior units that get removed
            unit_spaces.each do |space|
              space_names_to_remove << space.name.to_s
            end
            unit_hash[unit_num].remove
            model.getSpaces.each do |space|
              space_names_to_remove.each do |s|
                if space.name.to_s == s
                  if space.thermalZone.is_initialized
                    thermal_zone = space.thermalZone.get
                    thermal_zone.remove
                  end
                  space.remove
                end
              end
            end
          end
        
        end
        
      end
    end
    
    model.getSurfaces.each do |surface|
      next unless surface.outsideBoundaryCondition.downcase == "surface"
      next if surface.adjacentSurface.is_initialized
      surface.setOutsideBoundaryCondition("Adiabatic")
    end
    
    # Store number of units
    model.getBuilding.setStandardsNumberOfLivingUnits(num_units)
    
    # reporting final condition of model
    runner.registerFinalCondition("The building finished with #{model.getSpaces.size} spaces.")  
    
    return true

  end
  
end

# register the measure to be used by the application
CreateResidentialSingleFamilyAttachedGeometry.new.registerWithApplication
