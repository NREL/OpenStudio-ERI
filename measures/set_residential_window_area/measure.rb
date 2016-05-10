# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/measures/measure_writing_guide/

require "#{File.dirname(__FILE__)}/resources/constants"
require "#{File.dirname(__FILE__)}/resources/geometry"

# start the measure
class SetResidentialWindowArea < OpenStudio::Ruleset::ModelUserScript

  # human readable name
  def name
    return "Set Residential Window Area"
  end

  # human readable description
  def description
    return "Sets the window area for the building. Doors with glazing should be set as window area."
  end

  # human readable description of modeling approach
  def modeler_description
    return "Automatically creates and positions standard residential windows based on the specified window area on each building facade. Windows are only added to surfaces between finished space and outside. Any existing windows are removed."
  end

  # define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Ruleset::OSArgumentVector.new

    #make a double argument for front wwr
    front_wwr = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("front_wwr", true)
    front_wwr.setDisplayName("Front Window-to-Wall Ratio")
    front_wwr.setDescription("The ratio of window area to wall area for the building's front facade.")
    front_wwr.setDefaultValue(0.18)
    args << front_wwr

    #make a double argument for back wwr
    back_wwr = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("back_wwr", true)
    back_wwr.setDisplayName("Back Window-to-Wall Ratio")
    back_wwr.setDescription("The ratio of window area to wall area for the building's back facade.")
    back_wwr.setDefaultValue(0.18)
    args << back_wwr

    #make a double argument for left wwr
    left_wwr = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("left_wwr", true)
    left_wwr.setDisplayName("Left Window-to-Wall Ratio")
    left_wwr.setDescription("The ratio of window area to wall area for the building's left facade.")
    left_wwr.setDefaultValue(0.18)
    args << left_wwr

    #make a double argument for right wwr
    right_wwr = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("right_wwr", true)
    right_wwr.setDisplayName("Right Window-to-Wall Ratio")
    right_wwr.setDescription("The ratio of window area to wall area for the building's right facade.")
    right_wwr.setDefaultValue(0.18)
    args << right_wwr

    return args
  end

  # define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)

    # use the built-in error checking
    if !runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

    facades = [Constants.FacadeFront, Constants.FacadeBack, Constants.FacadeLeft, Constants.FacadeRight]
	
    wwr = {}
    wwr[Constants.FacadeFront] = runner.getDoubleArgumentValue("front_wwr",user_arguments)
    wwr[Constants.FacadeBack] = runner.getDoubleArgumentValue("back_wwr",user_arguments)
    wwr[Constants.FacadeLeft] = runner.getDoubleArgumentValue("left_wwr",user_arguments)
    wwr[Constants.FacadeRight] = runner.getDoubleArgumentValue("right_wwr",user_arguments)

    # Remove existing windows and store surfaces that should get windows by facade
    surfaces = {Constants.FacadeFront=>[], Constants.FacadeBack=>[],
                Constants.FacadeLeft=>[], Constants.FacadeRight=>[]}
    Geometry.get_finished_spaces(model).each do |space|
        space.surfaces.each do |surface|
            next if not (surface.surfaceType.downcase == "wall" and surface.outsideBoundaryCondition.downcase == "outdoors")
            win_removed = false
            surface.subSurfaces.each do |sub_surface|
                next if sub_surface.subSurfaceType.downcase != "fixedwindow"
                sub_surface.remove
                win_removed = true
            end
            if win_removed
                runner.registerInfo("Removed fixed window(s) from #{surface.name}.")
            end
            facade = Geometry.get_facade_from_surface_azimuth(surface.azimuth, model)
            surfaces[facade] << surface
        end
    end
    
    # error checking
    if wwr[Constants.FacadeFront] < 0 or wwr[Constants.FacadeFront] >= 1
      runner.registerError("Front Window-to-Wall Ratio must be greater than or equal to 0 and less than 1.")
      return false
    end
    if wwr[Constants.FacadeBack] < 0 or wwr[Constants.FacadeBack] >= 1
      runner.registerError("Back Window-to-Wall Ratio must be greater than or equal to 0 and less than 1.")
      return false
    end
    if wwr[Constants.FacadeLeft] < 0 or wwr[Constants.FacadeLeft] >= 1
      runner.registerError("Left Window-to-Wall Ratio must be greater than or equal to 0 and less than 1.")
      return false
    end
    if wwr[Constants.FacadeRight] < 0 or wwr[Constants.FacadeRight] >= 1
      runner.registerError("Right Window-to-Wall Ratio must be greater than or equal to 0 and less than 1.")
      return false
    end    
    
    # Split any surfaces that have doors so that we can ignore them when
    # adding windows.
    facades.each do |facade|
        surfaces_to_add = []
        surfaces[facade].each do |surface|
            next if surface.subSurfaces.size == 0
            new_surfaces = surface.splitSurfaceForSubSurfaces
            new_surfaces.each do |new_surface|
                next if new_surface.subSurfaces.size > 0
                surfaces_to_add << new_surface
            end
        end
        surfaces_to_add.each do |surface_to_add|
            surfaces[facade] << surface_to_add
        end
    end
    
    # Default assumptions
    default_window_aspect_ratio = 1.333 # height/width
    min_single_window_area = 5.333 # sqft (2x2.67)
    max_single_window_area = 12.0 # sqft (3x4); default_window_aspect_ratio preserved
    max_single_window_area_tall = 21.0 # sqft (3x7); default_window_aspect_ratio not preserved
    max_window_width = 3.0 # ft; after a window hits max_single_window_area only the height increases
    window_gap_y = 1.0 # minimum ft from, e.g., a gable wall top edge
    min_wall_height_for_window = Math.sqrt(max_single_window_area * default_window_aspect_ratio) + window_gap_y * 1.05 # allow some wall area above/below
    min_window_width = Math.sqrt(min_single_window_area / default_window_aspect_ratio) * 1.05 # allow some wall area to the left/right
    
    # Calculate available area for each wall, facade
    surface_avail_area = {}
    facade_avail_area = {}
    facades.each do |facade|
        facade_avail_area[facade] = 0
        surfaces[facade].each do |surface|
            if not surface_avail_area.include? surface
                surface_avail_area[surface] = 0
            end
            area = get_wall_area_for_windows(surface, min_wall_height_for_window, min_window_width, runner)
            surface_avail_area[surface] += area
            facade_avail_area[facade] += area
        end
    end
    
    surface_window_area = {}
    facades.each do |facade|
    
        # Initialize
        surfaces[facade].each do |surface|
            surface_window_area[surface] = 0
        end
    
        # Calculate target window area for this facade
        wall_area = 0
        surfaces[facade].each do |surface|
            wall_area += OpenStudio.convert(surface.grossArea, "m^2", "ft^2").get
        end
        target_window_area = wall_area * wwr[facade]
        
        next if target_window_area == 0
        
        if target_window_area < min_single_window_area
            # If the total window area for the facade is less than the minimum window area,
            # set all of the window area to the surface with the greatest available wall area
            surface = my_hash.max_by{|k,v| v}[0]
            surface_window_area[surface] = target_window_area
            next
        end
        
        # Initial guess for wall of this facade
        surfaces[facade].each do |surface|
            surface_window_area[surface] = surface_avail_area[surface] / facade_avail_area[facade] * target_window_area
        end
        
        # If window area for a surface is less than the minimum window area, 
        # set the window area to zero and proportionally redistribute to the
        # other surfaces.
        surfaces[facade].each_with_index do |surface, surface_num|
            next if surface_window_area[surface] >= min_single_window_area
            
            removed_window_area = surface_window_area[surface]
            surface_window_area[surface] = 0
            
            # Future surfaces are those that have not yet been compared to min_single_window_area
            future_surfaces_area = 0
            surfaces[facade].each_with_index do |future_surface, future_surface_num|
                next if future_surface_num <= surface_num
                future_surfaces_area += surface_avail_area[future_surface]
            end
            next if future_surfaces_area == 0
            
            surfaces[facade].each_with_index do |future_surface, future_surface_num|
                next if future_surface_num <= surface_num
                surface_window_area[future_surface] += removed_window_area * surface_window_area[future_surface] / future_surfaces_area
            end
        end
        
        # Because the above process is calculated based on the order of surfaces, it's possible
        # that we have less area for this facade than we should. If so, redistribute proportionally
        # to all surfaces that have window area.
        sum_window_area = 0
        surfaces[facade].each do |surface|
            sum_window_area += surface_window_area[surface]
        end
        next if sum_window_area == 0
        surfaces[facade].each do |surface|
            surface_window_area[surface] += surface_window_area[surface] / sum_window_area * (target_window_area - sum_window_area)
        end
    
    end
    
    facades.each do |facade|
        surfaces[facade].each do |surface|
            next if surface_window_area[surface] == 0
            add_windows_to_wall(surface, surface_window_area[surface], window_gap_y, 
                                default_window_aspect_ratio, max_window_width,
                                max_single_window_area, max_single_window_area_tall,
                                facade, model, runner)
        end
    end
    
    return true

  end
  
  def get_wall_area_for_windows(surface, min_wall_height_for_window, min_window_width, runner)
    # Only allow on gable and rectangular walls
    if not (Geometry.is_rectangular_wall(surface) or Geometry.is_gable_wall(surface))
        return 0.0
    end
  
    # Can't fit the smallest window?
    if Geometry.get_surface_length(surface) < min_window_width
        return 0.0
    end
    
    # Wall too short?
    if min_wall_height_for_window > Geometry.get_surface_height(surface)
        return 0.0
    end
    
    # Gable too short?
    # TODO: super crude safety factor of 1.5
    if Geometry.is_gable_wall(surface) and min_wall_height_for_window > Geometry.get_surface_height(surface)/1.5
        return 0.0
    end

    # TODO: Currently just returns total wall area, which is OK for rectangular 
    # surfaces but less so for other shapes (e.g., gable walls).
    return OpenStudio.convert(surface.grossArea, "m^2", "ft^2").get
  end
  
  def add_windows_to_wall(surface, window_area, window_gap_y, default_window_aspect_ratio, max_window_width, max_single_window_area, max_single_window_area_tall, facade, model, runner)
    window_gap_x = 0.2 # ft; default between windows in a group
    
    wall_width = Geometry.get_surface_length(surface)
    wall_height = Geometry.get_surface_height(surface)
    
    # Calculate number of windows needed
    num_windows = (window_area / max_single_window_area).ceil
    window_width = Math.sqrt((window_area / num_windows.to_f) / default_window_aspect_ratio)
    width_for_windows = window_width * num_windows.to_f
    if width_for_windows >= Geometry.get_surface_length(surface)
        # Need to enlarge windows
        num_windows = (window_area / max_single_window_area_tall).ceil
        window_width = Math.sqrt((window_area / num_windows.to_f) / default_window_aspect_ratio)
    end
    window_height = (window_area / num_windows.to_f) / window_width
    
    # Position window from top of surface
    win_top = wall_height - window_gap_y
    if Geometry.is_gable_wall(surface)
        # For gable surfaces, position windows from bottom of surface so they fit
        win_top = window_height + window_gap_y
    end
    
    # Groups of two windows
    num_window_groups = (num_windows / 2.0).ceil
    win_num = 0
    for i in (1..num_window_groups)
        
        # Center vertex for group
        group_cx = wall_width * i / (num_window_groups+1).to_f
        group_cy = win_top - window_height / 2.0
        
        if not (i == num_window_groups and num_windows % 2 == 1)
            # Two windows in group
            win_num += 1
            add_window_to_wall(surface, window_width, window_height, group_cx - window_width/2.0 - window_gap_x/2.0, group_cy, win_num, facade, model, runner)
            win_num += 1
            add_window_to_wall(surface, window_width, window_height, group_cx + window_width/2.0 + window_gap_x/2.0, group_cy, win_num, facade, model, runner)
        else
            # One window in group
            win_num += 1
            add_window_to_wall(surface, window_width, window_height, group_cx, group_cy, win_num, facade, model, runner)
        end
    end
    runner.registerInfo("Added #{num_windows.to_s} window(s), totaling #{window_area.round(1).to_s} ft^2, to #{surface.name}.")
    
  end
  
  def add_window_to_wall(surface, win_width, win_height, win_center_x, win_center_y, win_num, facade, model, runner)
    
    # Create window vertices in relative coordinates, ft
    upperleft = [win_center_x - win_width/2.0, win_center_y + win_height/2.0]
    upperright = [win_center_x + win_width/2.0, win_center_y + win_height/2.0]
    lowerright = [win_center_x + win_width/2.0, win_center_y - win_height/2.0]
    lowerleft = [win_center_x - win_width/2.0, win_center_y - win_height/2.0]
    
    # Convert to 3D geometry; assign to surface
    window_polygon = OpenStudio::Point3dVector.new
    if facade == Constants.FacadeFront
        multx = 1
        multy = 0
    elsif facade == Constants.FacadeBack
        multx = -1
        multy = 0
    elsif facade == Constants.FacadeLeft
        multx = 0
        multy = -1
    elsif facade == Constants.FacadeRight
        multx = 0
        multy = 1
    end
    if facade == Constants.FacadeBack or facade == Constants.FacadeLeft
        leftx = Geometry.getSurfaceXValues([surface]).max
        lefty = Geometry.getSurfaceYValues([surface]).max
    else
        leftx = Geometry.getSurfaceXValues([surface]).min
        lefty = Geometry.getSurfaceYValues([surface]).min
    end
    bottomz = Geometry.getSurfaceZValues([surface]).min
    [upperleft, lowerleft, lowerright, upperright ].each do |coord|
        newx = OpenStudio.convert(leftx + multx * coord[0], "ft", "m").get
        newy = OpenStudio.convert(lefty + multy * coord[0], "ft", "m").get
        newz = OpenStudio.convert(bottomz + coord[1], "ft", "m").get
        window_vertex = OpenStudio::Point3d.new(newx, newy, newz)
        window_polygon << window_vertex
    end
    sub_surface = OpenStudio::Model::SubSurface.new(window_polygon, model)
    sub_surface.setName("#{surface.name} - Window #{win_num.to_s}")
    sub_surface.setSurface(surface)
    sub_surface.setSubSurfaceType("FixedWindow")
    
  end
  
end

# register the measure to be used by the application
SetResidentialWindowArea.new.registerWithApplication
