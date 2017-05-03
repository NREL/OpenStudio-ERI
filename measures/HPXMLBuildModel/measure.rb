# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/reference/measure_writing_guide/

require 'rexml/document'
require 'rexml/xpath'

# start the measure
class HPXMLBuildModel < OpenStudio::Measure::ModelMeasure

  # human readable name
  def name
    return "HPXML Build Model"
  end

  # human readable description
  def description
    return "E+ RESNET"
  end

  # human readable description of modeling approach
  def modeler_description
    return "E+ RESNET"
  end

  # define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Measure::OSArgumentVector.new

    arg = OpenStudio::Measure::OSArgument.makeStringArgument("hpxml_file_path", true)
    arg.setDisplayName("HPXML File Path")
    arg.setDescription("Absolute (or relative) path of the HPXML file.")
    args << arg

    arg = OpenStudio::Measure::OSArgument.makeStringArgument("weather_file_path", false)
    arg.setDisplayName("EPW File Path")
    arg.setDescription("Absolute (or relative) path of the EPW weather file to assign. The corresponding DDY file must also be in the same directory.")
    args << arg

    arg = OpenStudio::Measure::OSArgument.makeStringArgument("measures_dir", true)
    arg.setDisplayName("Residential Measures Directory")
    arg.setDescription("Absolute path of the residential measures.")
    args << arg
    
    return args
  end

  # define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)
    
    # use the built-in error checking
    if !runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

    hpxml_file_path = runner.getStringArgumentValue("hpxml_file_path", user_arguments)
    weather_file_path = runner.getOptionalStringArgumentValue("weather_file_path", user_arguments)
    weather_file_path.is_initialized ? weather_file_path = weather_file_path.get : weather_file_path = nil
    measures_dir = runner.getStringArgumentValue("measures_dir", user_arguments)

    unless (Pathname.new hpxml_file_path).absolute?
      hpxml_file_path = File.expand_path(File.join(File.dirname(__FILE__), hpxml_file_path))
    end 
    unless File.exists?(hpxml_file_path) and hpxml_file_path.downcase.end_with? ".xml"
      runner.registerError("'#{hpxml_file_path}' does not exist or is not an .xml file.")
      return false
    end
    
    unless weather_file_path.nil?
      unless (Pathname.new weather_file_path).absolute?
        weather_file_path = File.expand_path(File.join(File.dirname(__FILE__), weather_file_path))
      end
      unless File.exists?(weather_file_path) and weather_file_path.downcase.end_with? ".epw"
        runner.registerError("'#{weather_file_path}' does not exist or is not an .epw file.")
        return false
      end
    end
    
    unless (Pathname.new measures_dir).absolute?
      measures_dir = File.expand_path(File.join(File.dirname(__FILE__), measures_dir))
    end
    unless Dir.exists?(measures_dir)
      runner.registerError("'#{measures_dir}' does not exist.")
      return false
    end
    
    # Get file/dir paths
    resources_dir = File.join(File.dirname(__FILE__), "resources")
    helper_methods_file = File.join(resources_dir, "helper_methods.rb")
    
    # Load helper_methods
    require File.join(File.dirname(helper_methods_file), File.basename(helper_methods_file, File.extname(helper_methods_file)))    
    
    # Need to ensure this has the same order as https://github.com/NREL/OpenStudio-Beopt#new-construction-workflow-for-users
    measures_tested = ["ResidentialLocation",
                       "ResidentialGeometryNumBedsAndBaths", 
                       "ResidentialGeometryNumOccupants",
                       "ResidentialGeometryDoorArea",
                       "ResidentialConstructionsCeilingsRoofsUnfinishedAttic",
                       "ResidentialConstructionsCeilingsRoofsFinishedRoof",
                       "ResidentialConstructionsCeilingsRoofsRoofingMaterial",
                       "ResidentialConstructionsFoundationsFloorsSlab",
                       "ResidentialConstructionsFoundationsFloorsBasementFinished",
                       "ResidentialConstructionsFoundationsFloorsCrawlspace",
                       "ResidentialConstructionsWallsExteriorWoodStud",
                       "ResidentialConstructionsWallsInterzonal",                       
                       "ResidentialConstructionsUninsulatedSurfaces",
                       "ResidentialConstructionsWindows",
                       "ResidentialConstructionsDoors",
                       # "ResidentialHVACFurnaceFuel",
                       # "ResidentialHVACHeatingSetpoints",
                       "ResidentialAirflow",
                       "ResidentialHVACSizing",
                       # "ResidentialPhotovoltaics"
                       ] # TODO: Remove
    
    # Obtain measures and default arguments
    measures = {}
    Dir.foreach(measures_dir) do |measure_subdir|
      next if !measure_subdir.include? 'Residential'
      next if !measures_tested.include? measure_subdir # TODO: Remove
      full_measure_path = File.join(measures_dir, measure_subdir, "measure.rb")
      check_file_exists(full_measure_path, runner)      
      measure_instance = get_measure_instance(full_measure_path)
      measures[measure_subdir] = default_args_hash(model, measure_instance)
    end
    
    # TODO: Parse hpxml and update measure arguments
    doc = REXML::Document.new(File.read(hpxml_file_path))
    
    event_types = []
    doc.elements.each("*/*/ProjectStatus/EventType") do |el|
      next unless el.text == "audit" # TODO: consider all event types?
      event_types << el.text
    end
    
    # Error checking
    facility_types_handled = ["single-family detached"]
    if doc.elements["//Building[ProjectStatus/EventType='#{event_types[0]}']/BuildingDetails/BuildingSummary/BuildingConstruction/ResidentialFacilityType"].nil?
      runner.registerError("Residential facility type not specified.")
      return false
    elsif not facility_types_handled.include? doc.elements["//Building[ProjectStatus/EventType='#{event_types[0]}']/BuildingDetails/BuildingSummary/BuildingConstruction/ResidentialFacilityType"].text
      runner.registerError("Residential facility type not #{facility_types_handled.join(", ")}.")
      return false
    end    
    
    # ResidentialLocation
    if weather_file_path.nil?
    
      city_municipality = doc.elements["//Building[ProjectStatus/EventType='#{event_types[0]}']/Site/Address/CityMunicipality"]
      state_code = doc.elements["//Building[ProjectStatus/EventType='#{event_types[0]}']/Site/Address/StateCode"]
      zip_code = doc.elements["//Building[ProjectStatus/EventType='#{event_types[0]}']/Site/Address/ZipCode"]
      
      lat, lng = get_lat_lng_from_address(runner, resources_dir, city_municipality, state_code, zip_code)
      if lat.nil? and lng.nil?
        return false
      end

      weather_file_path = File.join(measures["ResidentialLocation"]["weather_directory"], get_epw_from_lat_lng(runner, resources_dir, lat, lng))
      if weather_file_path.nil?
        return false
      end
      runner.registerInfo("Found #{File.expand_path(File.join(measures_dir, "ResidentialLocation", weather_file_path))} based on lat, lng.")
      
    else      
      runner.registerInfo("Found user-specified #{weather_file_path}.")
    end

    measures["ResidentialLocation"]["weather_directory"] = File.dirname(weather_file_path)
    measures["ResidentialLocation"]["weather_file_name"] = File.basename(weather_file_path)
    
    # Geometry
    
    avg_ceil_hgt = doc.elements["//Building[ProjectStatus/EventType='#{event_types[0]}']/BuildingDetails/BuildingSummary/BuildingConstruction/AverageCeilingHeight"]
    if avg_ceil_hgt.nil?
      avg_ceil_hgt = 8.0
    else
      avg_ceil_hgt = avg_ceil_hgt.text.to_f
    end

    foundation_space, foundation_zone = build_foundation_space(model, doc, event_types)
    living_space = build_living_space(model, doc, event_types)
    attic_space, attic_zone = build_attic_space(model, doc, event_types)
    foundation_finished_floor_area = add_foundation_floors(model, doc, event_types, living_space, foundation_space)
    add_foundation_walls(model, doc, event_types, living_space, foundation_space)
    foundation_finished_floor_area = add_foundation_ceilings(model, doc, event_types, foundation_space, living_space, foundation_finished_floor_area)
    add_living_floors(model, doc, event_types, foundation_space, living_space, foundation_finished_floor_area) # TODO: need these assumptions for airflow measure
    wall_fractions, window_areas = get_wall_orientation_fractions(doc, event_types)
    surface_window_area = add_living_walls(model, doc, event_types, avg_ceil_hgt, living_space, attic_space, wall_fractions, window_areas)
    add_attic_floors(model, doc, event_types, avg_ceil_hgt, attic_space, living_space)
    add_attic_walls(model, doc, event_types, avg_ceil_hgt, attic_space, living_space)
    add_attic_ceilings(model, doc, event_types, avg_ceil_hgt, attic_space, living_space)
    add_windows(model, doc, event_types, runner, surface_window_area)
    
    # Set the zone volumes based on the sum of space volumes
    model.getThermalZones.each do |thermal_zone|
      zone_volume = 0
      if not Geometry.get_volume_from_spaces(thermal_zone.spaces) > 0 # space doesn't have a floor
        if thermal_zone.name.to_s == Constants.CrawlZone
          floor_area = nil
          thermal_zone.spaces.each do |space|
            space.surfaces.each do |surface|
              next unless surface.surfaceType.downcase == "roofceiling"
              floor_area = surface.grossArea
            end
          end
          zone_volume = OpenStudio.convert(floor_area,"m^2","ft^2").get * Geometry.get_height_of_spaces(thermal_zone.spaces)
        end
      else # space has a floor
        zone_volume = Geometry.get_volume_from_spaces(thermal_zone.spaces)
      end
      thermal_zone.setVolume(OpenStudio.convert(zone_volume,"ft^3","m^3").get)
    end
   
    # Explode wall surfaces out from origin, from top down
    [Constants.FacadeFront, Constants.FacadeBack, Constants.FacadeLeft, Constants.FacadeRight].each do |facade|
    
      wall_surfaces = {}
      model.getSurfaces.each do |surface|
        next unless Geometry.get_facade_for_surface(surface) == facade
        next unless surface.surfaceType.downcase == "wall"
        if surface.adjacentSurface.is_initialized
          next if wall_surfaces.keys.include? surface or wall_surfaces.keys.include? surface.adjacentSurface.get
        end
        z_val = -10000
        surface.vertices.each do |vertex|
          if vertex.z > z_val
            wall_surfaces[surface] = vertex.z.to_f
            z_val = vertex.z
          end
        end
      end
          
      offset = 30.0 # m
      wall_surfaces.sort_by{|k, v| v}.reverse.to_h.keys.each do |surface|

        m = OpenStudio::Matrix.new(4, 4, 0)
        m[0,0] = 1
        m[1,1] = 1
        m[2,2] = 1
        m[3,3] = 1
        if Geometry.get_facade_for_surface(surface) == Constants.FacadeFront
          m[1,3] = -offset
        elsif Geometry.get_facade_for_surface(surface) == Constants.FacadeBack
          m[1,3] = offset
        elsif Geometry.get_facade_for_surface(surface) == Constants.FacadeLeft
          m[0,3] = -offset
        elsif Geometry.get_facade_for_surface(surface) == Constants.FacadeRight
          m[0,3] = offset
        end
     
        transformation = OpenStudio::Transformation.new(m)      
        
        surface.subSurfaces.each do |subsurface|
          next unless subsurface.subSurfaceType.downcase == "fixedwindow"
          subsurface.setVertices(transformation * subsurface.vertices)
        end
        if surface.adjacentSurface.is_initialized
          surface.adjacentSurface.get.setVertices(transformation * surface.adjacentSurface.get.vertices)
        end
        surface.setVertices(transformation * surface.vertices)
        
        offset += 5.0 # m
          
      end

    end
    
    exposed_perim = 0
    doc.elements.each("//Building[ProjectStatus/EventType='#{event_types[0]}']/BuildingDetails/Enclosure/Foundations/Foundation") do |foundation|
      foundation.elements.each("Slab") do |slab|        
        unless slab.elements["ExposedPerimeter"].nil?
          exposed_perim += slab.elements["ExposedPerimeter"].text.to_f
        end
      end      
    end
          
    measures.keys.each do |measure|
      next unless measures[measure].keys.include? "exposed_perim"
      measures[measure]["exposed_perim"] = exposed_perim.to_s
    end
    
    # Store building name
    model.getBuilding.setName(File.basename(hpxml_file_path))
        
    # Store building unit information
    unit = OpenStudio::Model::BuildingUnit.new(model)
    unit.setBuildingUnitType(Constants.BuildingUnitTypeResidential)
    unit.setName(Constants.ObjectNameBuildingUnit)
    model.getSpaces.each do |space|
      space.setBuildingUnit(unit)
    end
    
    # Store number of units
    model.getBuilding.setStandardsNumberOfLivingUnits(1)    
    
    # Store number of stories
    num_floors = doc.elements["//Building[ProjectStatus/EventType='#{event_types[0]}']/BuildingDetails/BuildingSummary/BuildingConstruction/NumberofStoriesAboveGrade"]
    if num_floors.nil?
      num_floors = 1
    else
      num_floors = num_floors.text.to_i
    end    
    
    if (REXML::XPath.first(doc, "count(//Building[ProjectStatus/EventType='#{event_types[0]}']/BuildingDetails/Enclosure/AtticAndRoof/Attics/Attic[AtticType='cathedral ceiling'])") + REXML::XPath.first(doc, "count(//Building[ProjectStatus/EventType='#{event_types[0]}']/BuildingDetails/Enclosure/AtticAndRoof/Attics/Attic[AtticType='cape cod'])")) > 0
      num_floors += 1
    end
    model.getBuilding.setStandardsNumberOfAboveGroundStories(num_floors)
    model.getSpaces.each do |space|
      if space.name.to_s == Constants.FinishedBasementSpace
        num_floors += 1  
        break
      end
    end
    model.getBuilding.setStandardsNumberOfStories(num_floors)
    
    # Store the building type
    facility_types_map = {"single-family detached"=>Constants.BuildingTypeSingleFamilyDetached}
    model.getBuilding.setStandardsBuildingType(facility_types_map[doc.elements["//Building[ProjectStatus/EventType='#{event_types[0]}']/BuildingDetails/BuildingSummary/BuildingConstruction/ResidentialFacilityType"].text])
        
    # ResidentialGeometryNumBedsAndBaths
    measures = update_measure_args(doc, measures, "ResidentialGeometryNumBedsAndBaths", "num_bedrooms", "//Building[ProjectStatus/EventType='#{event_types[0]}']/BuildingDetails/BuildingSummary/BuildingConstruction/NumberofBedrooms")
    measures = update_measure_args(doc, measures, "ResidentialGeometryNumBedsAndBaths", "num_bathrooms", "//Building[ProjectStatus/EventType='#{event_types[0]}']/BuildingDetails/BuildingSummary/BuildingConstruction/NumberofBathrooms")

    # ResidentialGeometryNumOccupants
    measures = update_measure_args(doc, measures, "ResidentialGeometryNumOccupants", "num_occ", "//Building[ProjectStatus/EventType='#{event_types[0]}']/BuildingDetails/BuildingSummary/BuildingOccupancy/NumberofResidents")

    # ResidentialGeometryDoorArea
    measures = update_measure_args(doc, measures, "ResidentialGeometryDoorArea", "door_area", "//Building[ProjectStatus/EventType='#{event_types[0]}']/BuildingDetails/Enclosure/Doors/Door/Area")
    
    select_measures = {} # TODO: Remove
    measures_tested.each do |k|
      select_measures[k] = measures[k]
    end
    measures = select_measures
    
    # Call each measure for sample to build up model
    measures.keys.each do |measure_subdir|
      # Gather measure arguments and call measure
      full_measure_path = File.join(measures_dir, measure_subdir, "measure.rb")      
      measure_instance = get_measure_instance(full_measure_path)
      argument_map = get_argument_map(model, measure_instance, measures[measure_subdir], measure_subdir, runner)
      print_measure_call(measures[measure_subdir], measure_subdir, runner)

      if not run_measure(model, measure_instance, argument_map, runner)
        return false
      end
    end
    
    return true

  end
  
  def add_floor_polygon(x, y, z)
    
    vertices = OpenStudio::Point3dVector.new
    vertices << OpenStudio::Point3d.new(0, 0, z)
    vertices << OpenStudio::Point3d.new(0, y, z)
    vertices << OpenStudio::Point3d.new(x, y, z)
    vertices << OpenStudio::Point3d.new(x, 0, z)
    
    return vertices
    
  end
  
  def add_wall_polygon(x, y, z, orientation="south")
  
    vertices = OpenStudio::Point3dVector.new
    if orientation == "north"      
      vertices << OpenStudio::Point3d.new(0-(x/2), 0, z)
      vertices << OpenStudio::Point3d.new(0-(x/2), 0, z + y)
      vertices << OpenStudio::Point3d.new(x-(x/2), 0, z + y)
      vertices << OpenStudio::Point3d.new(x-(x/2), 0, z)
    elsif orientation == "south"
      vertices << OpenStudio::Point3d.new(x-(x/2), 0, z)
      vertices << OpenStudio::Point3d.new(x-(x/2), 0, z + y)
      vertices << OpenStudio::Point3d.new(0-(x/2), 0, z + y)
      vertices << OpenStudio::Point3d.new(0-(x/2), 0, z)
    elsif orientation == "east"
      vertices << OpenStudio::Point3d.new(0, x-(x/2), z)
      vertices << OpenStudio::Point3d.new(0, x-(x/2), z + y)
      vertices << OpenStudio::Point3d.new(0, 0-(x/2), z + y)
      vertices << OpenStudio::Point3d.new(0, 0-(x/2), z)
    elsif orientation == "west"
      vertices << OpenStudio::Point3d.new(0, 0-(x/2), z)
      vertices << OpenStudio::Point3d.new(0, 0-(x/2), z + y)
      vertices << OpenStudio::Point3d.new(0, x-(x/2), z + y)
      vertices << OpenStudio::Point3d.new(0, x-(x/2), z)
    end
    return vertices
    
  end
  
  def add_ceiling_polygon(x, y, z)
    
    return OpenStudio::reverse(add_floor_polygon(x, y, z))
    
  end
  
  def build_living_space(model, doc, event_types)
    
    living_zone = OpenStudio::Model::ThermalZone.new(model)
    living_zone.setName(Constants.LivingZone)
    living_space = OpenStudio::Model::Space.new(model)
    living_space.setName(Constants.LivingSpace)
    living_space.setThermalZone(living_zone)   
    
    return living_space
    
  end
  
  def get_wall_orientation_fractions(doc, event_types)
  
    wall_fractions = {}
    doc.elements.each("//Building[ProjectStatus/EventType='#{event_types[0]}']/BuildingDetails/Enclosure/Windows/Window") do |window|
      orientation = window.elements["Orientation"].text
      if orientation == "southwest"
        orientation = "south"
      elsif orientation == "northwest"
        orientation = "west"
      elsif orientation == "southeast"
        orientation = "east"
      elsif orientation == "northeast"
        orientation = "north"
      end
      if wall_fractions.keys.include? window.elements["AttachedToWall"].attributes["idref"]      
        if wall_fractions[window.elements["AttachedToWall"].attributes["idref"]].keys.include? orientation
          wall_fractions[window.elements["AttachedToWall"].attributes["idref"]][orientation] += window.elements["Area"].text.to_f
        else
          wall_fractions[window.elements["AttachedToWall"].attributes["idref"]][orientation] = window.elements["Area"].text.to_f
        end
      else      
        wall_fractions[window.elements["AttachedToWall"].attributes["idref"]] = {}
        wall_fractions[window.elements["AttachedToWall"].attributes["idref"]][orientation] = window.elements["Area"].text.to_f        
      end
    end

    window_areas = {}
    doc.elements.each("//Building[ProjectStatus/EventType='#{event_types[0]}']/BuildingDetails/Enclosure/Windows/Window") do |window|
      if window_areas.keys.include? window.elements["AttachedToWall"].attributes["idref"]
        window_areas[window.elements["AttachedToWall"].attributes["idref"]] += window.elements["Area"].text.to_f        
      else
        window_areas[window.elements["AttachedToWall"].attributes["idref"]] = {}
        window_areas[window.elements["AttachedToWall"].attributes["idref"]] = window.elements["Area"].text.to_f        
      end
    end

    wall_fractions.each do |wall_id, orientations|    
      orientations.each do |orientation, area|
        wall_fractions[wall_id][orientation] /= window_areas[wall_id]
      end    
    end
    
    return wall_fractions, window_areas
  
  end  
  
  def add_living_walls(model, doc, event_types, avg_ceil_hgt, living_space, attic_space, wall_fractions, window_areas)
  
    rotate = {"north"=>0, "south"=>180, "west"=>90, "east"=>270}
  
    surface_window_area = {}
    doc.elements.each("//Building[ProjectStatus/EventType='#{event_types[0]}']/BuildingDetails/Enclosure/Walls/Wall") do |wall|
    
      next unless wall.elements["InteriorAdjacentTo"].text == "living space"
      next if wall.elements["Area"].nil?
      
      z_origin = 0
      unless wall.elements["ExteriorAdjacentTo"].nil?
        if wall.elements["ExteriorAdjacentTo"].text == "attic"
          z_origin = OpenStudio.convert(avg_ceil_hgt,"ft","m").get * 1 # TODO: is this a bad assumption?
        end
      end
    
      if not wall_fractions.keys.include? wall.elements["SystemIdentifier"].attributes["id"]
      
        wall_height = OpenStudio.convert(avg_ceil_hgt,"ft","m").get
        wall_length = OpenStudio.convert(wall.elements["Area"].text.to_f,"ft^2","m^2").get / wall_height

        surface = OpenStudio::Model::Surface.new(add_wall_polygon(wall_length, wall_height, z_origin), model)
        surface.setName(wall.elements["SystemIdentifier"].attributes["id"])
        surface.setSurfaceType("Wall") 
        surface.setSpace(living_space)
        if wall.elements["ExteriorAdjacentTo"].text == "attic"
          surface.createAdjacentSurface(attic_space)
        elsif wall.elements["ExteriorAdjacentTo"].text == "ambient"
          surface.setOutsideBoundaryCondition("Outdoors")
        else
          puts "#{wall.elements["ExteriorAdjacentTo"].text} not handled yet."
        end      
      
      else
      
        wall_fractions[wall.elements["SystemIdentifier"].attributes["id"]].each do |orientation, frac|
        
          wall_height = OpenStudio.convert(avg_ceil_hgt,"ft","m").get
          wall_length = frac * OpenStudio.convert(wall.elements["Area"].text.to_f,"ft^2","m^2").get / wall_height

          surface = OpenStudio::Model::Surface.new(add_wall_polygon(wall_length, wall_height, z_origin, orientation), model)
          surface.setName("#{wall.elements["SystemIdentifier"].attributes["id"]} #{orientation}")
          surface.setSurfaceType("Wall") 
          surface.setSpace(living_space)
          if wall.elements["ExteriorAdjacentTo"].text == "attic"
            surface.createAdjacentSurface(attic_space)
          elsif wall.elements["ExteriorAdjacentTo"].text == "ambient"
            surface.setOutsideBoundaryCondition("Outdoors")
          else
            puts "#{wall.elements["ExteriorAdjacentTo"].text} not handled yet."
          end
          
          surface_window_area["#{wall.elements["SystemIdentifier"].attributes["id"]} #{orientation}"] = frac * window_areas[wall.elements["SystemIdentifier"].attributes["id"]]      
        
        end
        
      end
      
    end
    
    return surface_window_area
    
  end
  
  def build_foundation_space(model, doc, event_types)
  
    foundation_type = doc.elements["//Building[ProjectStatus/EventType='#{event_types[0]}']/BuildingDetails/BuildingSummary/BuildingConstruction/FoundationType"]
    unless foundation_type.nil?
      foundation_space_name = nil
      foundation_zone_name = nil
      if foundation_type.elements["Basement/Conditioned/text()='true'"] or foundation_type.elements["Basement/Finished/text()='true'"]
        foundation_zone_name = Constants.FinishedBasementZone
        foundation_space_name = Constants.FinishedBasementSpace
      elsif foundation_type.elements["Basement/Conditioned/text()='false'"] or foundation_type.elements["Basement/Finished/text()='false'"]
        foundation_zone_name = Constants.UnfinishedBasementZone
        foundation_space_name = Constants.UnfinishedBasementSpace
      elsif foundation_type.elements["Crawlspace/Vented/text()='true'"] or foundation_type.elements["Crawlspace/Vented/text()='false'"] or foundation_type.elements["Crawlspace/Conditioned/text()='true'"] or foundation_type.elements["Crawlspace/Conditioned/text()='false'"]
        foundation_zone_name = Constants.CrawlZone
        foundation_space_name = Constants.CrawlSpace
      elsif foundation_type.elements["Garage/Conditioned/text()='true'"] or foundation_type.elements["Garage/Conditioned/text()='false'"]
        foundation_zone_name = Constants.GarageZone
        foundation_space_name = Constants.GarageSpace
      elsif foundation_type.elements["SlabOnGrade"]     
      end
      if not foundation_space_name.nil? and not foundation_zone_name.nil?
        foundation_zone = OpenStudio::Model::ThermalZone.new(model)
        foundation_zone.setName(foundation_zone_name)
        foundation_space = OpenStudio::Model::Space.new(model)
        foundation_space.setName(foundation_space_name)
        foundation_space.setThermalZone(foundation_zone)
      end
    end
    
    return foundation_space, foundation_zone
    
  end
  
  def add_foundation_floors(model, doc, event_types, living_space, foundation_space)
    
    foundation_finished_floor_area = 0
    doc.elements.each("//Building[ProjectStatus/EventType='#{event_types[0]}']/BuildingDetails/Enclosure/Foundations/Foundation") do |foundation|
    
      foundation.elements.each("Slab") do |slab|
      
        next if slab.elements["Area"].nil?
        
        slab_width = OpenStudio.convert(Math::sqrt(slab.elements["Area"].text.to_f),"ft","m").get
        slab_length = OpenStudio.convert(slab.elements["Area"].text.to_f,"ft^2","m^2").get / slab_width
        
        z_origin = 0
        unless slab.elements["DepthBelowGrade"].nil?
          z_origin = -OpenStudio.convert(slab.elements["DepthBelowGrade"].text.to_f,"ft","m").get
        end
        
        surface = OpenStudio::Model::Surface.new(add_floor_polygon(slab_length, slab_width, z_origin), model)
        surface.setName(slab.elements["SystemIdentifier"].attributes["id"])
        surface.setSurfaceType("Floor") 
        surface.setOutsideBoundaryCondition("Ground")
        if z_origin < 0
          surface.setSpace(foundation_space)
        else
          surface.setSpace(living_space)
        end
        if foundation_space.nil?
          foundation_finished_floor_area += slab.elements["Area"].text.to_f # is a slab foundation
        elsif foundation_space.name.to_s == Constants.FinishedBasementSpace
          foundation_finished_floor_area += slab.elements["Area"].text.to_f # is a finished basement foundation
        end
        
      end
      
    end
    
    return foundation_finished_floor_area
      
  end
  
  def add_foundation_walls(model, doc, event_types, living_space, foundation_space)
  
    doc.elements.each("//Building[ProjectStatus/EventType='#{event_types[0]}']/BuildingDetails/Enclosure/Foundations/Foundation") do |foundation|
      
      foundation.elements.each("FoundationWall") do |wall|
        
        if not wall.elements["Length"].nil? and not wall.elements["Height"].nil?
        
          wall_length = OpenStudio.convert(wall.elements["Length"].text.to_f,"ft","m").get
          wall_height = OpenStudio.convert(wall.elements["Height"].text.to_f,"ft","m").get
        
        elsif not wall.elements["Area"].nil?
        
          wall_length = OpenStudio.convert(Math::sqrt(wall.elements["Area"].text.to_f),"ft","m").get
          wall_height = OpenStudio.convert(wall.elements["Area"].text.to_f,"ft^2","m^2").get / wall_length
        
        else
        
          next
        
        end
        
        z_origin = 0
        unless wall.elements["BelowGradeDepth"].nil?
          z_origin = -OpenStudio.convert(wall.elements["BelowGradeDepth"].text.to_f,"ft","m").get
        end
        
        surface = OpenStudio::Model::Surface.new(add_wall_polygon(wall_length, wall_height, z_origin), model)
        surface.setName(wall.elements["SystemIdentifier"].attributes["id"])
        surface.setSurfaceType("Wall") 
        surface.setOutsideBoundaryCondition("Ground")
        surface.setSpace(foundation_space)
        
      end
    
    end
  
  end
  
  def add_foundation_ceilings(model, doc, event_types, foundation_space, living_space, foundation_finished_floor_area)
     
    doc.elements.each("//Building[ProjectStatus/EventType='#{event_types[0]}']/BuildingDetails/Enclosure/Foundations/Foundation") do |foundation|
     
      foundation.elements.each("FrameFloor") do |framefloor|
      
        next if framefloor.elements["Area"].nil?

        framefloor_width = OpenStudio.convert(Math::sqrt(framefloor.elements["Area"].text.to_f),"ft","m").get
        framefloor_length = OpenStudio.convert(framefloor.elements["Area"].text.to_f,"ft^2","m^2").get / framefloor_width
        
        z_origin = 0
        
        surface = OpenStudio::Model::Surface.new(add_ceiling_polygon(framefloor_length, framefloor_width, z_origin), model)
        surface.setName(framefloor.elements["SystemIdentifier"].attributes["id"])
        surface.setSurfaceType("RoofCeiling")
        surface.setSpace(foundation_space)
        surface.createAdjacentSurface(living_space)
        
        foundation_finished_floor_area += framefloor.elements["Area"].text.to_f
      
      end
    
    end
    
    return foundation_finished_floor_area
    
  end
  
  def add_living_floors(model, doc, event_types, foundation_space, living_space, foundation_finished_floor_area)
  
    finished_floor_area = nil
    if not doc.elements["//Building[ProjectStatus/EventType='#{event_types[0]}']/BuildingDetails/BuildingSummary/BuildingConstruction/FinishedFloorArea"].nil?
      finished_floor_area = doc.elements["//Building[ProjectStatus/EventType='#{event_types[0]}']/BuildingDetails/BuildingSummary/BuildingConstruction/FinishedFloorArea"].text.to_f
      if finished_floor_area == 0 and not doc.elements["//Building[ProjectStatus/EventType='#{event_types[0]}']/BuildingDetails/BuildingSummary/BuildingConstruction/ConditionedFloorArea"].nil?
        finished_floor_area = doc.elements["//Building[ProjectStatus/EventType='#{event_types[0]}']/BuildingDetails/BuildingSummary/BuildingConstruction/ConditionedFloorArea"].text.to_f
      end
    elsif not doc.elements["//Building[ProjectStatus/EventType='#{event_types[0]}']/BuildingDetails/BuildingSummary/BuildingConstruction/ConditionedFloorArea"].nil?
      finished_floor_area = doc.elements["//Building[ProjectStatus/EventType='#{event_types[0]}']/BuildingDetails/BuildingSummary/BuildingConstruction/ConditionedFloorArea"].text.to_f
    end
    if finished_floor_area.nil?
      puts "Could not find finished floor area."
    end
    above_grade_finished_floor_area = finished_floor_area - foundation_finished_floor_area
    return unless above_grade_finished_floor_area > 0
    
    finishedfloor_width = OpenStudio.convert(Math::sqrt(above_grade_finished_floor_area),"ft","m").get
    finishedfloor_length = OpenStudio.convert(above_grade_finished_floor_area,"ft^2","m^2").get / finishedfloor_width
    
    surface = OpenStudio::Model::Surface.new(add_floor_polygon(-finishedfloor_width, -finishedfloor_length, 0), model) # don't put it right on top of existing finished floor
    surface.setName("inferred above grade finished floor")
    surface.setSurfaceType("Floor")
    surface.setSpace(living_space)
    if foundation_space.nil?
      surface.createAdjacentSurface(living_space)
    else
      surface.createAdjacentSurface(foundation_space)
    end
  
  end
  
  def build_attic_space(model, doc, event_types)

    attic_space = nil
    attic_zone = nil
    doc.elements.each("//Building[ProjectStatus/EventType='#{event_types[0]}']/BuildingDetails/Enclosure/AtticAndRoof/Attics/Attic") do |attic|
    
      next if attic.elements["Area"].nil?
    
      if ["venting unknown attic", "vented attic", "unvented attic"].include? attic.elements["AtticType"].text
        if attic_space.nil?
          attic_zone = OpenStudio::Model::ThermalZone.new(model)
          attic_zone.setName(Constants.UnfinishedAtticZone)
          attic_space = OpenStudio::Model::Space.new(model)
          attic_space.setName(Constants.UnfinishedAtticSpace)
          attic_space.setThermalZone(attic_zone)
        end
      end
      
    end
    
    return attic_space, attic_zone
    
  end
  
  def add_attic_floors(model, doc, event_types, avg_ceil_hgt, attic_space, living_space)
  
    doc.elements.each("//Building[ProjectStatus/EventType='#{event_types[0]}']/BuildingDetails/Enclosure/AtticAndRoof/Attics/Attic") do |attic|
    
      next if ["cathedral ceiling", "cape cod"].include? attic.elements["AtticType"].text
      next if attic.elements["Area"].nil?
    
      attic_width = OpenStudio.convert(Math::sqrt(attic.elements["Area"].text.to_f),"ft","m").get
      attic_length = OpenStudio.convert(attic.elements["Area"].text.to_f,"ft^2","m^2").get / attic_width
    
      z_origin = OpenStudio.convert(avg_ceil_hgt,"ft","m").get * 1 # TODO: is this a bad assumption?
     
      if ["cathedral ceiling", "cape cod"].include? attic.elements["AtticType"].text
      elsif ["venting unknown attic", "vented attic", "unvented attic"].include? attic.elements["AtticType"].text
        surface = OpenStudio::Model::Surface.new(add_floor_polygon(attic_length, attic_width, z_origin), model)
        surface.setName(attic.elements["SystemIdentifier"].attributes["id"])        
        surface.setSpace(attic_space)
        surface.setSurfaceType("Floor")
        surface.createAdjacentSurface(living_space)
      else
        puts "#{attic.elements["AtticType"].text} not handled yet."
      end
      
    end
    
  end
  
  def add_attic_walls(model, doc, event_types, avg_ceil_hgt, attic_space, living_space)
  
    doc.elements.each("//Building[ProjectStatus/EventType='#{event_types[0]}']/BuildingDetails/Enclosure/Walls/Wall") do |wall|
    
      next unless wall.elements["InteriorAdjacentTo"].text == "attic"
      next if wall.elements["Area"].nil?
      
      z_origin = OpenStudio.convert(avg_ceil_hgt,"ft","m").get * 1 # TODO: is this a bad assumption?
      
      wall_height = OpenStudio.convert(avg_ceil_hgt,"ft","m").get
      wall_length = OpenStudio.convert(wall.elements["Area"].text.to_f,"ft^2","m^2").get / wall_height

      surface = OpenStudio::Model::Surface.new(add_wall_polygon(wall_height, wall_length, z_origin), model)
      surface.setName(wall.elements["SystemIdentifier"].attributes["id"])
      surface.setSurfaceType("Wall")
      surface.setSpace(living_space)
      if wall.elements["ExteriorAdjacentTo"].text == "living space"
        surface.createAdjacentSurface(living_space)
      elsif wall.elements["ExteriorAdjacentTo"].text == "ambient"
        surface.setOutsideBoundaryCondition("Outdoors")
      else
        puts "#{wall.elements["ExteriorAdjacentTo"].text} not handled yet."
      end
      
    end
    
  end
  
  def add_attic_ceilings(model, doc, event_types, avg_ceil_hgt, attic_space, living_space)
  
    doc.elements.each("//Building[ProjectStatus/EventType='#{event_types[0]}']/BuildingDetails/Enclosure/AtticAndRoof/Attics/Attic") do |attic|
    
      next if ["venting unknown attic", "vented attic", "unvented attic"].include? attic.elements["AtticType"].text
      next if attic.elements["Area"].nil?
    
      attic_width = OpenStudio.convert(Math::sqrt(attic.elements["Area"].text.to_f),"ft","m").get
      attic_length = OpenStudio.convert(attic.elements["Area"].text.to_f,"ft^2","m^2").get / attic_width
    
      z_origin = OpenStudio.convert(avg_ceil_hgt,"ft","m").get * 1 # TODO: is this a bad assumption?
     
      if ["cathedral ceiling", "cape cod"].include? attic.elements["AtticType"].text
        surface = OpenStudio::Model::Surface.new(add_ceiling_polygon(attic_length, attic_width, z_origin), model)
        surface.setName(attic.elements["SystemIdentifier"].attributes["id"])
        surface.setSpace(living_space)
        surface.setSurfaceType("RoofCeiling")
        surface.setOutsideBoundaryCondition("Outdoors")
      elsif ["venting unknown attic", "vented attic", "unvented attic"].include? attic.elements["AtticType"].text     
      else
        puts "#{attic.elements["AtticType"].text} not handled yet."
      end
      
    end  
  
    doc.elements.each("//Building[ProjectStatus/EventType='#{event_types[0]}']/BuildingDetails/Enclosure/AtticAndRoof/Roofs/Roof") do |roof|
    
      next if roof.elements["RoofArea"].nil?
    
      roof_width = OpenStudio.convert(Math::sqrt(roof.elements["RoofArea"].text.to_f),"ft","m").get
      roof_length = OpenStudio.convert(roof.elements["RoofArea"].text.to_f,"ft^2","m^2").get / roof_width
    
      z_origin = OpenStudio.convert(avg_ceil_hgt,"ft","m").get * 2 # TODO: is this a bad assumption?

      surface = OpenStudio::Model::Surface.new(add_ceiling_polygon(roof_length, roof_width, z_origin), model)
      surface.setName("#{roof.elements["SystemIdentifier"].attributes["id"]}")
      surface.setSurfaceType("RoofCeiling")
      surface.setOutsideBoundaryCondition("Outdoors")
      surface.setSpace(attic_space)

    end
      
  end
  
  def add_windows(model, doc, event_types, runner, surface_window_area)
    
    max_single_window_area = 12.0 # sqft
    window_gap_y = 1.0 # ft; distance from top of wall
    window_gap_x = 0.2 # ft; distance between windows in a two-window group
    aspect_ratio = 1.333
    facades = {"south"=>Constants.FacadeFront, "north"=>Constants.FacadeBack, "west"=>Constants.FacadeLeft, "east"=>Constants.FacadeRight}
    model.getSurfaces.each do |surface|
      next unless surface_window_area.keys.include? surface.name.to_s
      next if surface.outsideBoundaryCondition.downcase == "ground" # TODO: can't have windows on surfaces adjacent to ground in energyplus
      add_windows_to_wall(surface, surface_window_area[surface.name.to_s], window_gap_y, window_gap_x, aspect_ratio, max_single_window_area, facades[surface.name.to_s.split(' ')[1]], model, runner)      
    end
    
  end
  
  def add_windows_to_wall(surface, window_area, window_gap_y, window_gap_x, aspect_ratio, max_single_window_area, facade, model, runner)
    wall_width = Geometry.get_surface_length(surface)
    wall_height = Geometry.get_surface_height(surface)
    
    # Calculate number of windows needed
    num_windows = (window_area / max_single_window_area).ceil
    num_window_groups = (num_windows / 2.0).ceil
    num_window_gaps = num_window_groups
    if num_windows % 2 == 1
        num_window_gaps -= 1
    end
    window_width = Math.sqrt((window_area / num_windows.to_f) / aspect_ratio)
    window_height = (window_area / num_windows.to_f) / window_width
    width_for_windows = window_width * num_windows.to_f + window_gap_x * num_window_gaps.to_f
    if width_for_windows > wall_width
        runner.registerError("Could not fit windows on #{surface.name.to_s}.")
        return false
    end
    
    # Position window from top of surface
    win_top = wall_height - window_gap_y
    if Geometry.is_gable_wall(surface)
        # For gable surfaces, position windows from bottom of surface so they fit
        win_top = window_height + window_gap_y
    end
    
    # Groups of two windows
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
    return true
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
  
  def update_measure_args(doc, measures, measure, arg, xpath)
    new_measure_args = measures[measure]
    val = doc.elements[xpath]
    unless val.nil?
      new_measure_args[arg] = val.text
    end
    measures[measure].update(new_measure_args)
    return measures
  end  
  
  def default_args_hash(model, measure)
    args_hash = {}
    arguments = measure.arguments(model)
    arguments.each do |arg|	
      if arg.hasDefaultValue
        type = arg.type.valueName
        case type
        when "Boolean"
          args_hash[arg.name] = arg.defaultValueAsBool.to_s
        when "Double"
          args_hash[arg.name] = arg.defaultValueAsDouble.to_s
        when "Integer"
          args_hash[arg.name] = arg.defaultValueAsInteger.to_s
        when "String"
          args_hash[arg.name] = arg.defaultValueAsString
        when "Choice"
          args_hash[arg.name] = arg.defaultValueAsString
        end
      else
        args_hash[arg.name] = nil
      end
    end
    return args_hash
  end
  
  def get_lat_lng_from_address(runner, resources_dir, city_municipality, state_code, zip_code)
    postalcodes = CSV.read(File.expand_path(File.join(resources_dir, "postalcodes.csv")))
    postalcodes.each do |row|
      if not zip_code.nil?
        if not zip_code.text.nil? and postalcodes.transpose[0].include? zip_code.text
          if zip_code.text == row[0]
            return row[4], row[5]
          end
        elsif not city_municipality.nil? and not state_code.nil?
          if city_municipality.text.downcase == row[1].downcase and state_code.text.downcase == row[3].downcase
            return row[4], row[5]
          end
        end
      elsif not city_municipality.nil? and not state_code.nil?
        if city_municipality.text.downcase == row[1].downcase and state_code.text.downcase == row[3].downcase
          return row[4], row[5]
        end
      else
        runner.registerError("Could not find lat, lng from address.")
        return nil, nil
      end
    end
  end
  
  def get_epw_from_lat_lng(runner, resources_dir, lat, lng)
    lat_lng_table = CSV.read(File.expand_path(File.join(resources_dir, "lat_long_table.csv")))
    meters = []
    lat_lng_table.each do |row|
      meters << haversine(lat.to_f, lng.to_f, row[1].to_f, row[2].to_f)
    end
    row = lat_lng_table[meters.each_with_index.min[1]]
    return "USA_CO_Denver_Intl_AP_725650_TMY3.epw" # TODO: Remove
    return row[0]  
  end
  
  def haversine(lat1, long1, lat2, long2)
    dtor = Math::PI/180
    r = 6378.14*1000

    rlat1 = lat1 * dtor 
    rlong1 = long1 * dtor 
    rlat2 = lat2 * dtor 
    rlong2 = long2 * dtor 

    dlon = rlong1 - rlong2
    dlat = rlat1 - rlat2

    a = Math::sin(dlat/2) ** 2 + Math::cos(rlat1) * Math::cos(rlat2) * Math::sin(dlon/2) ** 2
    c = 2 * Math::atan2(Math::sqrt(a), Math::sqrt(1-a))
    d = r * c

    return d
  end
  
end

# register the measure to be used by the application
HPXMLBuildModel.new.registerWithApplication
