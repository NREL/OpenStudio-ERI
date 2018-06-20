class HPXMLtoOSMTranslator

  def self.create(hpxml_doc, runner, model, weather)
  
    # Simulation parameters
    success = add_simulation_params(runner, model)
    return false if not success

    building = hpxml_doc.elements["/HPXML/Building"]
  
    # Geometry/Envelope
    
    success, spaces, unit = add_geometry_envelope(runner, model, building, weather)
    return false if not success
    
    # Bedrooms, Occupants
    
    success = add_num_bedrooms_occupants(model, building, runner)
    return false if not success
    
    # Hot Water
    
    success = add_water_heater(runner, model, building, unit, weather, spaces)
    return false if not success
    success = add_hot_water_and_appliances(runner, model, building, unit, weather)
    return false if not success
    
    # HVAC
    success = add_hvac(runner, model, building, unit, weather)
    return false if not success
    success = add_setpoints(runner, model, building, weather) 
    return false if not success
    success = add_dehumidifier(runner, model, building, unit)
    return false if not success
    success = add_ceiling_fans(runner, model, building, unit)
    return false if not success
    
    # Plug Loads & Lighting
    
    success = add_mels(runner, model, building, unit, spaces[Constants.SpaceTypeLiving])
    return false if not success
    success = add_lighting(runner, model, building, unit, weather)
    return false if not success
    
    # Other
    
    success = add_airflow(runner, model, building, unit, weather)
    return false if not success
    success = add_photovoltaics(runner, model, building)
    return false if not success
    
    # HVAC Sizing (final step)
    
    success = add_hvac_sizing(runner, model, unit, weather)
    return false if not success
    
    # TODO: Error-checking
    # Need to ensure that every thermal zone has at least one wall, floor, and ceiling/roof surface
    
    return true
    
  end
  
  private
  
  def self.add_simulation_params(runner, model)
  
    success = Simulation.apply(model, runner, 1, 0)
    return false if not success
    
    return true
  end
  
  def self.add_geometry_envelope(runner, model, building, weather)
  
    # FIXME
    avg_ceil_hgt = XMLHelper.get_value(building, "BuildingDetails/BuildingSummary/BuildingConstruction/AverageCeilingHeight")
    if avg_ceil_hgt.nil?
      avg_ceil_hgt = 8.0
    else
      avg_ceil_hgt = Float(avg_ceil_hgt)
    end
    
    spaces = create_all_spaces_and_zones(model, building)
    return false if spaces.empty?
    
    success, unit = add_building_info(model, building)
    return false if not success
  
    fenestration_areas = {}
    
    success = add_windows(runner, model, building, spaces, fenestration_areas, weather)
    return false if not success
    
    success = add_doors(runner, model, building, spaces, fenestration_areas)
    return false if not success
    
    success = add_foundations(runner, model, building, spaces, fenestration_areas, unit) # TODO: Don't need to pass unit once slab hvac sizing is updated
    return false if not success
    
    success = add_walls(runner, model, building, avg_ceil_hgt, spaces, fenestration_areas)
    return false if not success
    
    success = add_rim_joists(runner, model, building, spaces)
    return false if not success
    
    success = add_attics(runner, model, building, avg_ceil_hgt, spaces, fenestration_areas)
    return false if not success
    
    success = add_finished_floor_area(runner, model, building, spaces)
    return false if not success
    
    success = add_thermal_mass(runner, model, building)
    return false if not success
    
    success = set_zone_volumes(runner, model, building)
    return false if not success
    
    success = explode_surfaces(runner, model)
    return false if not success

    return true, spaces, unit
  end
  
  def self.set_zone_volumes(runner, model, building)
  
    total_conditioned_volume = Float(XMLHelper.get_value(building, "BuildingDetails/BuildingSummary/BuildingConstruction/ConditionedBuildingVolume"))
    thermal_zones = model.getThermalZones

    # Init
    living_volume = total_conditioned_volume
    zones_updated = 0
  
    # Basements, crawl, garage
    thermal_zones.each do |thermal_zone|
      if Geometry.is_finished_basement(thermal_zone) or Geometry.is_unfinished_basement(thermal_zone) or Geometry.is_crawl(thermal_zone) or Geometry.is_garage(thermal_zone)
        zones_updated += 1
        
        zone_volume = Geometry.get_height_of_spaces(thermal_zone.spaces) * Geometry.get_floor_area_from_spaces(thermal_zone.spaces)
        thermal_zone.setVolume(UnitConversions.convert(zone_volume,"ft^3","m^3"))
        
        if Geometry.is_finished_basement(thermal_zone)
          living_volume = total_conditioned_volume - zone_volume
        end
        
      end
    end
    
    # Conditioned living
    thermal_zones.each do |thermal_zone|
      if Geometry.is_living(thermal_zone)
        zones_updated += 1
        
        if living_volume <= 0
          fail "Calculated volume for living zone #{living_volume} is not greater than zero."
        end
        thermal_zone.setVolume(UnitConversions.convert(living_volume,"ft^3","m^3"))
        
      end
    end
    
    # Attic
    thermal_zones.each do |thermal_zone|
      if Geometry.is_unfinished_attic(thermal_zone)
        zones_updated += 1
        
        zone_surfaces = []
        thermal_zone.spaces.each do |space|
          space.surfaces.each do |surface|
            zone_surfaces << surface
          end
        end
        
        # Assume square hip roof for volume calculations; energy results are very insensitive to actual volume
        zone_area = Geometry.get_floor_area_from_spaces(thermal_zone.spaces)
        zone_length = zone_area ** 0.5
        zone_height = Math.tan(UnitConversions.convert(Geometry.get_roof_pitch(zone_surfaces), "deg", "rad")) * zone_length / 2.0
        zone_volume = zone_area * zone_height / 3.0
        
        if zone_volume <= 0
          fail "Calculated volume for attic zone #{zone_volume} is not greater than zero."
        end
        thermal_zone.setVolume(UnitConversions.convert(zone_volume,"ft^3","m^3"))
      
      end
    end
  
    if zones_updated != thermal_zones.size
      fail "Unhandled volume calculations for thermal zones."
    end
    
    return true
  end
  
  def self.explode_surfaces(runner, model)
    # Re-position surfaces so as to not shade each other. 
    # TODO: Might be able to use the new self-shading options in E+ 8.9 ShadowCalculation object
  
    # Explode the walls
    wall_offset = 10.0
    surfaces_moved = []
    model.getSurfaces.sort.each do |surface|

      next unless surface.surfaceType.downcase == "wall"
      next if surface.subSurfaces.any? { |subsurface| subsurface.subSurfaceType.downcase == "fixedwindow" }
      
      if surface.adjacentSurface.is_initialized
        next if surfaces_moved.include? surface.adjacentSurface.get
      end
      
      transformation = get_surface_transformation(wall_offset, surface.outwardNormal.x, surface.outwardNormal.y, 0)   
      
      if surface.adjacentSurface.is_initialized
        surface.adjacentSurface.get.setVertices(transformation * surface.adjacentSurface.get.vertices)
      end
      surface.setVertices(transformation * surface.vertices)
      
      surface.subSurfaces.each do |subsurface|
        next unless subsurface.subSurfaceType.downcase == "door"
        subsurface.setVertices(transformation * subsurface.vertices)
      end
      
      wall_offset += 10
      
      surfaces_moved << surface
      
    end
    
    # Explode the above-grade floors
    # FIXME: Need to fix heights for airflow measure
    floor_offset = 0.5
    surfaces_moved = []
    model.getSurfaces.sort.each do |surface|

      next unless surface.surfaceType.downcase == "floor" or surface.surfaceType.downcase == "roofceiling"
      next if surface.outsideBoundaryCondition.downcase == "foundation"
      
      if surface.adjacentSurface.is_initialized
        next if surfaces_moved.include? surface.adjacentSurface.get
      end
      
      transformation = get_surface_transformation(floor_offset, 0, 0, surface.outwardNormal.z)

      if surface.adjacentSurface.is_initialized
        surface.adjacentSurface.get.setVertices(transformation * surface.adjacentSurface.get.vertices)
      end
      surface.setVertices(transformation * surface.vertices)
      
      floor_offset += 10
      
      surfaces_moved << surface
      
    end
    
    # Explode the windows
    window_offset = 50.0
    model.getSubSurfaces.sort.each do |sub_surface|

      next unless sub_surface.subSurfaceType.downcase == "fixedwindow"
      
      transformation = get_surface_transformation(window_offset, sub_surface.outwardNormal.x, sub_surface.outwardNormal.y, 0)

      surface = sub_surface.surface.get
      sub_surface.setVertices(transformation * sub_surface.vertices)      
      if surface.adjacentSurface.is_initialized
        surface.adjacentSurface.get.setVertices(transformation * surface.adjacentSurface.get.vertices)
      end
      surface.setVertices(transformation * surface.vertices)
      
      sub_surface.shadingSurfaceGroups.each do |shading_group|
        shading_group.shadingSurfaces.each do |shading_surface|
          shading_surface.setVertices(transformation * shading_surface.vertices)
        end
      end
      
      window_offset += 10
      
    end
    
    return true
    
  end
  
  def self.create_space_and_zone(model, spaces, space_type)
    if not spaces.keys.include? space_type
      thermal_zone = OpenStudio::Model::ThermalZone.new(model)
      thermal_zone.setName(space_type)
      
      space = OpenStudio::Model::Space.new(model)
      space.setName(space_type)
      
      st = OpenStudio::Model::SpaceType.new(model)
      st.setStandardsSpaceType(space_type)
      space.setSpaceType(st)
      
      space.setThermalZone(thermal_zone)
      spaces[space_type] = space
    end
  end

  # FIXME: Remove this method and create spaces/zones on the fly.
  def self.create_all_spaces_and_zones(model, building)
    
    spaces = {}
    
    building.elements.each("BuildingDetails/Enclosure/AtticAndRoof/Attics/Attic") do |attic|
    
      attic_type = XMLHelper.get_value(attic, "AtticType")
      if ["vented attic", "unvented attic"].include? attic_type
        create_space_and_zone(model, spaces, Constants.SpaceTypeUnfinishedAttic)
      elsif attic_type == "cape cod"
        create_space_and_zone(model, spaces, Constants.SpaceTypeLiving)
      elsif attic_type != "flat roof" and attic_type != "cathedral ceiling"
        fail "Unhandled value (#{attic_type})."
      end
    
      floors = attic.elements["Floors"]
      floors.elements.each("Floor") do |floor|
    
        exterior_adjacent_to = XMLHelper.get_value(floor, "extension/ExteriorAdjacentTo")
        if exterior_adjacent_to == "living space"
          create_space_and_zone(model, spaces, Constants.SpaceTypeLiving)
        elsif exterior_adjacent_to == "garage"
          create_space_and_zone(model, spaces, Constants.SpaceTypeGarage)
        elsif exterior_adjacent_to != "ambient" and exterior_adjacent_to != "ground"
          fail "Unhandled value (#{exterior_adjacent_to})."
        end
        
      end
      
      walls = attic.elements["Walls"]
      walls.elements.each("Wall") do |wall|
      
        exterior_adjacent_to = XMLHelper.get_value(wall, "extension/ExteriorAdjacentTo")
        if exterior_adjacent_to == "living space"
          create_space_and_zone(model, spaces, Constants.SpaceTypeLiving)
        elsif exterior_adjacent_to == "garage"
          create_space_and_zone(model, spaces, Constants.SpaceTypeGarage)
        elsif exterior_adjacent_to != "ambient" and exterior_adjacent_to != "ground"
          fail "Unhandled value (#{exterior_adjacent_to})."
        end        

      end
      
    end
    
    building.elements.each("BuildingDetails/Enclosure/Foundations/Foundation") do |foundation|
      
      foundation_space_type = foundation.elements["FoundationType"]      
      if foundation_space_type.elements["Basement/Conditioned/text()='true'"]        
        create_space_and_zone(model, spaces, Constants.SpaceTypeFinishedBasement)
      elsif foundation_space_type.elements["Basement/Conditioned/text()='false'"]      
        create_space_and_zone(model, spaces, Constants.SpaceTypeUnfinishedBasement)
      elsif foundation_space_type.elements["Crawlspace"]
        create_space_and_zone(model, spaces, Constants.SpaceTypeCrawl)
      elsif not foundation_space_type.elements["SlabOnGrade"] and not foundation_space_type.elements["Ambient"]
        fail "Unhandled value (#{foundation_space_type})."
      end
      
      foundation.elements.each("FrameFloor") do |frame_floor|
        
        exterior_adjacent_to = XMLHelper.get_value(frame_floor, "extension/ExteriorAdjacentTo")
        if exterior_adjacent_to == "living space"
          create_space_and_zone(model, spaces, Constants.SpaceTypeLiving)
        elsif exterior_adjacent_to != "ambient" and exterior_adjacent_to != "ground"
          fail "Unhandled value (#{exterior_adjacent_to})."
        end
        
      end
      
      foundation.elements.each("FoundationWall") do |foundation_wall|
        
        exterior_adjacent_to = XMLHelper.get_value(foundation_wall, "extension/ExteriorAdjacentTo")
        if exterior_adjacent_to == "unconditioned basement"
          create_space_and_zone(model, spaces, Constants.SpaceTypeUnfinishedBasement)
        elsif exterior_adjacent_to == "conditioned basement"
          create_space_and_zone(model, spaces, Constants.SpaceTypeFinishedBasement)
        elsif exterior_adjacent_to == "crawlspace"
          create_space_and_zone(model, spaces, Constants.SpaceTypeCrawl)
        elsif exterior_adjacent_to != "ambient" and exterior_adjacent_to != "ground"
          fail "Unhandled value (#{exterior_adjacent_to})."
        end
        
      end
    
    end

    building.elements.each("BuildingDetails/Enclosure/Walls/Wall") do |wall|
    
      interior_adjacent_to = XMLHelper.get_value(wall, "extension/InteriorAdjacentTo")
      if interior_adjacent_to == "living space"
        create_space_and_zone(model, spaces, Constants.SpaceTypeLiving)
      elsif interior_adjacent_to == "garage"
        create_space_and_zone(model, spaces, Constants.SpaceTypeGarage)
      else
        fail "Unhandled value (#{interior_adjacent_to})."
      end
      
      exterior_adjacent_to = XMLHelper.get_value(wall, "extension/ExteriorAdjacentTo")
      if exterior_adjacent_to == "garage"
        create_space_and_zone(model, spaces, Constants.SpaceTypeGarage)
      elsif exterior_adjacent_to == "living space"
        create_space_and_zone(model, spaces, Constants.SpaceTypeLiving)
      elsif exterior_adjacent_to != "ambient" and exterior_adjacent_to != "ground"
        fail "Unhandled value (#{exterior_adjacent_to})."
      end      
      
    end
    
    return spaces
    
  end
  
  def self.add_building_info(model, building)
  
    # Store building unit information
    unit = OpenStudio::Model::BuildingUnit.new(model)
    unit.setBuildingUnitType(Constants.BuildingUnitTypeResidential)
    unit.setName(Constants.ObjectNameBuildingUnit)
    model.getSpaces.each do |space|
      space.setBuildingUnit(unit)
    end    
    
    # Store number of units
    model.getBuilding.setStandardsNumberOfLivingUnits(1)    
    
    # Store number of stories TODO: Review this
    num_floors = XMLHelper.get_value(building, "BuildingDetails/BuildingSummary/BuildingConstruction/NumberofStoriesAboveGrade")
    if num_floors.nil?
      num_floors = 1
    else
      num_floors = Integer(num_floors)
    end    
    
    if (REXML::XPath.first(building, "count(BuildingDetails/Enclosure/AtticAndRoof/Attics/Attic[AtticType='cathedral ceiling'])") + REXML::XPath.first(building, "count(BuildingDetails/Enclosure/AtticAndRoof/Attics/Attic[AtticType='cape cod'])")) > 0
      num_floors += 1
    end
    model.getBuilding.setStandardsNumberOfAboveGroundStories(num_floors)
    model.getSpaces.each do |space|
      if space.name.to_s == Constants.SpaceTypeFinishedBasement
        num_floors += 1  
        break
      end
    end
    model.getBuilding.setStandardsNumberOfStories(num_floors)
    
    # Store info for HVAC Sizing measure
    if Boolean(XMLHelper.get_value(building, "BuildingDetails/BuildingSummary/BuildingConstruction/GaragePresent"))
      unit.setFeature(Constants.SizingInfoGarageFracUnderFinishedSpace, 1.0) # FIXME: assumption
    end
    
    return true, unit
  end
  
  def self.get_surface_transformation(offset, x, y, z)
  
    m = OpenStudio::Matrix.new(4, 4, 0)
    m[0,0] = 1
    m[1,1] = 1
    m[2,2] = 1
    m[3,3] = 1
    m[0,3] = x * offset
    m[1,3] = y * offset
    m[2,3] = z.abs * offset
 
    return OpenStudio::Transformation.new(m)
      
  end
  
  def self.add_floor_polygon(x, y, z)
      
    vertices = OpenStudio::Point3dVector.new
    vertices << OpenStudio::Point3d.new(0-x/2, 0-y/2, z)
    vertices << OpenStudio::Point3d.new(0-x/2, y/2, z)
    vertices << OpenStudio::Point3d.new(x/2, y/2, z)
    vertices << OpenStudio::Point3d.new(x/2, 0-y/2, z)
      
    return vertices
      
  end

  def self.add_wall_polygon(x, y, z, azimuth=0, offsets=[0]*4)

    vertices = OpenStudio::Point3dVector.new
    vertices << OpenStudio::Point3d.new(0-(x/2) - offsets[1], 0, z - offsets[0])
    vertices << OpenStudio::Point3d.new(0-(x/2) - offsets[1], 0, z + y + offsets[2])
    vertices << OpenStudio::Point3d.new(x-(x/2) + offsets[3], 0, z + y + offsets[2])
    vertices << OpenStudio::Point3d.new(x-(x/2) + offsets[3], 0, z - offsets[0])
    
    m = OpenStudio::Matrix.new(4, 4, 0)
    m[0,0] = Math::cos(-azimuth * Math::PI / 180.0)
    m[1,1] = Math::cos(-azimuth * Math::PI / 180.0)
    m[0,1] = -Math::sin(-azimuth * Math::PI / 180.0)
    m[1,0] = Math::sin(-azimuth * Math::PI / 180.0)
    m[2,2] = 1
    m[3,3] = 1
    transformation = OpenStudio::Transformation.new(m)
  
    return transformation * vertices
      
  end
  
  def self.add_roof_polygon(x, y, z, azimuth=0, tilt=0.5)

    vertices = OpenStudio::Point3dVector.new
    vertices << OpenStudio::Point3d.new(x/2, -y/2, z)
    vertices << OpenStudio::Point3d.new(x/2, y/2, z)
    vertices << OpenStudio::Point3d.new(-x/2, y/2, z)
    vertices << OpenStudio::Point3d.new(-x/2, -y/2, z)

    # Rotate about the x axis
    m = OpenStudio::Matrix.new(4, 4, 0)
    m[0,0] = 1
    m[1,1] = Math::cos(Math::atan(tilt))
    m[1,2] = -Math::sin(Math::atan(tilt))
    m[2,1] = Math::sin(Math::atan(tilt))
    m[2,2] = Math::cos(Math::atan(tilt))
    m[3,3] = 1
    transformation = OpenStudio::Transformation.new(m)
    vertices = transformation * vertices

    # Rotate about the z axis
    m = OpenStudio::Matrix.new(4, 4, 0)
    m[0,0] = Math::cos(UnitConversions.convert(azimuth, "deg", "rad"))
    m[1,1] = Math::cos(UnitConversions.convert(azimuth, "deg", "rad"))
    m[0,1] = -Math::sin(UnitConversions.convert(azimuth, "deg", "rad"))
    m[1,0] = Math::sin(UnitConversions.convert(azimuth, "deg", "rad"))
    m[2,2] = 1
    m[3,3] = 1
    transformation = OpenStudio::Transformation.new(m)
    vertices = transformation * vertices

    return vertices

  end

  def self.net_wall_area(gross_wall_area, wall_fenestration_areas, wall_id)
    if wall_fenestration_areas.keys.include? wall_id
      return gross_wall_area - wall_fenestration_areas[wall_id]
    end    
    return gross_wall_area
  end

  def self.add_num_bedrooms_occupants(model, building, runner)
    
    # Bedrooms
    num_bedrooms = Integer(XMLHelper.get_value(building, "BuildingDetails/BuildingSummary/BuildingConstruction/NumberofBedrooms"))
    num_bathrooms = 3.0 # Arbitrary, no impact on results since water heater capacity is required
    success = Geometry.process_beds_and_baths(model, runner, [num_bedrooms], [num_bathrooms])
    return false if not success
    
    # Occupants
    num_occ = Float(XMLHelper.get_value(building, "BuildingDetails/BuildingSummary/BuildingOccupancy/NumberofResidents"))
    occ_gain = Float(XMLHelper.get_value(building, "BuildingDetails/BuildingSummary/BuildingOccupancy/extension/HeatGainBtuPerPersonPerHr"))
    sens_frac = Float(XMLHelper.get_value(building, "BuildingDetails/BuildingSummary/BuildingOccupancy/extension/FracSensible"))
    lat_frac = Float(XMLHelper.get_value(building, "BuildingDetails/BuildingSummary/BuildingOccupancy/extension/FracLatent"))
    hrs_per_day = Float(XMLHelper.get_value(building, "BuildingDetails/BuildingSummary/BuildingOccupancy/extension/PersonHrsPerDay")) # TODO
    weekday_sch = "1.00000, 1.00000, 1.00000, 1.00000, 1.00000, 1.00000, 1.00000, 0.88310, 0.40861, 0.24189, 0.24189, 0.24189, 0.24189, 0.24189, 0.24189, 0.24189, 0.29498, 0.55310, 0.89693, 0.89693, 0.89693, 1.00000, 1.00000, 1.00000"
    weekend_sch = "1.00000, 1.00000, 1.00000, 1.00000, 1.00000, 1.00000, 1.00000, 0.88310, 0.40861, 0.24189, 0.24189, 0.24189, 0.24189, 0.24189, 0.24189, 0.24189, 0.29498, 0.55310, 0.89693, 0.89693, 0.89693, 1.00000, 1.00000, 1.00000"
    monthly_sch = "1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0"
    success = Geometry.process_occupants(model, runner, num_occ.to_s, occ_gain, sens_frac, lat_frac, weekday_sch, weekend_sch, monthly_sch)
    return false if not success
    
    return true
  end
  
  def self.add_foundations(runner, model, building, spaces, fenestration_areas, unit)
  
    building.elements.each("BuildingDetails/Enclosure/Foundations/Foundation") do |foundation|
      
      foundation_type = foundation.elements["FoundationType"]

      # Foundation slab surfaces
      
      slab_surface = nil
      perim_exp = 0.0
      slab_ext_r, slab_ext_depth, slab_perim_r, slab_perim_width, slab_gap_r = nil
      slab_whole_r, slab_concrete_thick_in = nil
      foundation.elements.each("Slab") do |fnd_slab|
      
        slab_id = fnd_slab.elements["SystemIdentifier"].attributes["id"]
      
        slab_length = Float(XMLHelper.get_value(fnd_slab, "ExposedPerimeter"))
        perim_exp += slab_length
        slab_area = Float(XMLHelper.get_value(fnd_slab, "Area"))
        slab_width = slab_area/slab_length
        
        z_origin = 0
        unless fnd_slab.elements["DepthBelowGrade"].nil?
          z_origin = -1 * Float(XMLHelper.get_value(fnd_slab, "DepthBelowGrade"))
        end
        
        surface = OpenStudio::Model::Surface.new(add_floor_polygon(UnitConversions.convert(slab_length,"ft","m"), 
                                                                   UnitConversions.convert(slab_width,"ft","m"), 
                                                                   UnitConversions.convert(z_origin,"ft","m")), model)
        surface.setName(slab_id)
        surface.setSurfaceType("Floor") 
        surface.setOutsideBoundaryCondition("Foundation")
        if foundation_type.elements["Basement/Conditioned/text()='true'"]
          surface.setSpace(spaces[Constants.SpaceTypeFinishedBasement])
        elsif foundation_type.elements["Basement/Conditioned/text()='false'"]
          surface.setSpace(spaces[Constants.SpaceTypeUnfinishedBasement])
        elsif foundation_type.elements["Crawlspace"]
          surface.setSpace(spaces[Constants.SpaceTypeCrawl])
        elsif foundation_type.elements["SlabOnGrade"]
          surface.setSpace(spaces[Constants.SpaceTypeLiving])
        else
          fail "Unhandled foundation type #{foundation_type}."
        end
        slab_surface = surface
        
        slab_gap_r = 0.0 # FIXME
        slab_whole_r = 0.0 # FIXME
        slab_concrete_thick_in = Float(XMLHelper.get_value(fnd_slab, "Thickness"))
        
        fnd_slab_perim = fnd_slab.elements["PerimeterInsulation/Layer[InstallationType='continuous']"]
        slab_ext_r = Float(XMLHelper.get_value(fnd_slab_perim, "NominalRValue"))
        slab_ext_depth = Float(XMLHelper.get_value(fnd_slab, "PerimeterInsulationDepth"))
        if slab_ext_r == 0 or slab_ext_depth == 0
          slab_ext_r = 0
          slab_ext_depth = 0
        end
        
        fnd_slab_under = fnd_slab.elements["UnderSlabInsulation/Layer[InstallationType='continuous']"]
        slab_perim_r = Float(XMLHelper.get_value(fnd_slab_under, "NominalRValue"))
        slab_perim_width = Float(XMLHelper.get_value(fnd_slab, "UnderSlabInsulationWidth"))
        if slab_perim_r == 0 or slab_perim_width == 0
          slab_perim_r = 0
          slab_perim_width = 0
        end
        
      end
      
      # Foundation wall surfaces
      
      fnd_id = foundation.elements["SystemIdentifier"].attributes["id"]
      wall_surface = nil
      wall_height, wall_cav_r, wall_cav_depth, wall_grade, wall_ff, wall_cont_height, wall_cont_r = nil
      wall_cont_depth, wall_filled_cavity, walls_drywall_thick_in, wall_concrete_thick_in = nil
      wall_assembly_r, wall_film_r = nil
      foundation.elements.each("FoundationWall") do |fnd_wall|
      
        wall_id = fnd_wall.elements["SystemIdentifier"].attributes["id"]
        
        exterior_adjacent_to = XMLHelper.get_value(fnd_wall, "extension/ExteriorAdjacentTo")
        
        wall_height = Float(XMLHelper.get_value(fnd_wall, "Height")) # FIXME: Need to handle above-grade portion
        wall_gross_area = Float(XMLHelper.get_value(fnd_wall, "Area"))
        wall_net_area = net_wall_area(wall_gross_area, fenestration_areas, fnd_id)
        wall_length = wall_net_area / wall_height
        
        z_origin = -1 * Float(XMLHelper.get_value(fnd_wall, "DepthBelowGrade"))
        
        surface = OpenStudio::Model::Surface.new(add_wall_polygon(UnitConversions.convert(wall_length,"ft","m"), 
                                                                  UnitConversions.convert(wall_height,"ft","m"), 
                                                                  UnitConversions.convert(z_origin,"ft","m")), model)
        surface.setName(wall_id)
        surface.setSurfaceType("Wall")
        if exterior_adjacent_to == "ground"
          surface.setOutsideBoundaryCondition("Foundation")
        else
          fail "Unhandled value (#{exterior_adjacent_to})."
        end
        if foundation_type.elements["Basement/Conditioned/text()='true'"]        
          surface.setSpace(spaces[Constants.SpaceTypeFinishedBasement])
        elsif foundation_type.elements["Basement/Conditioned/text()='false'"]      
          surface.setSpace(spaces[Constants.SpaceTypeUnfinishedBasement])
        elsif foundation_type.elements["Crawlspace"]
          surface.setSpace(spaces[Constants.SpaceTypeCrawl])
        else
          fail "Unhandled foundation type #{foundation_type}."
        end
        wall_surface = surface
        
        wall_filled_cavity = true # FIXME
        wall_concrete_thick_in = Float(XMLHelper.get_value(fnd_wall, "Thickness"))
        walls_drywall_thick_in = 0.0
        wall_assembly_r = Float(XMLHelper.get_value(fnd_wall, "Insulation/AssemblyEffectiveRValue"))
        wall_film_r = Material.AirFilmVertical.rvalue
        wall_cav_r = 0.0
        wall_cav_depth = 0.0
        wall_grade = 1
        wall_ff = 0.0
        wall_cont_height = Float(XMLHelper.get_value(fnd_wall, "Height"))
        wall_cont_r = wall_assembly_r - Material.Concrete(wall_concrete_thick_in).rvalue - Material.GypsumWall(walls_drywall_thick_in).rvalue - wall_film_r
        wall_cont_depth = 1.0
        
      end
      
      # Foundation ceiling surfaces
      
      ceiling_surfaces = []
      floor_cav_r, floor_cav_depth, floor_grade, floor_ff, floor_cont_r, floor_cont_depth = nil
      plywood_thick_in, mat_floor_covering, mat_carpet = nil
      floor_assembly_r, floor_film_r = nil
      foundation.elements.each("FrameFloor") do |fnd_floor|
      
        floor_id = fnd_floor.elements["SystemIdentifier"].attributes["id"]

        framefloor_area = Float(XMLHelper.get_value(fnd_floor, "Area"))
        framefloor_width = Math::sqrt(framefloor_area)
        framefloor_length = framefloor_area / framefloor_width
        
        z_origin = 0 # FIXME
        
        surface = OpenStudio::Model::Surface.new(add_floor_polygon(UnitConversions.convert(framefloor_length,"ft","m"), 
                                                                   UnitConversions.convert(framefloor_width,"ft","m"), 
                                                                   UnitConversions.convert(z_origin,"ft","m")), model)
        surface.setName(floor_id)
        if foundation_type.elements["Basement/Conditioned/text()='true'"]
          surface.setSurfaceType("RoofCeiling")
          surface.setSpace(spaces[Constants.SpaceTypeFinishedBasement])
          surface.createAdjacentSurface(spaces[Constants.SpaceTypeLiving])
        elsif foundation_type.elements["Basement/Conditioned/text()='false'"]
          surface.setSurfaceType("RoofCeiling")
          surface.setSpace(spaces[Constants.SpaceTypeUnfinishedBasement])
          surface.createAdjacentSurface(spaces[Constants.SpaceTypeLiving])
        elsif foundation_type.elements["Crawlspace"]
          surface.setSurfaceType("RoofCeiling")
          surface.setSpace(spaces[Constants.SpaceTypeCrawl])
          surface.createAdjacentSurface(spaces[Constants.SpaceTypeLiving])
        elsif foundation_type.elements["Ambient"]
          surface.setSurfaceType("Floor")
          surface.setSpace(spaces[Constants.SpaceTypeLiving])
          surface.setOutsideBoundaryCondition("Outdoors")
        else
          fail "Unhandled foundation type #{foundation_type}."
        end
        
        # For ASHRAE Standard 140 tests
        sun_exposed = XMLHelper.get_value(fnd_floor, "extension/SunExposed")
        if not sun_exposed.nil? and not Boolean(sun_exposed)
          surface.setSunExposure('NoSun')
        end
        wind_exposed = XMLHelper.get_value(fnd_floor, "extension/WindExposed")
        if not wind_exposed.nil? and not Boolean(wind_exposed)
          surface.setWindExposure('NoWind')
        end
        
        ceiling_surfaces << surface
        
        mat_floor_covering = nil
        mat_carpet = nil
        plywood_thick_in = 0.0
        floor_assembly_r = Float(XMLHelper.get_value(fnd_floor, "Insulation/AssemblyEffectiveRValue"))
        floor_film_r = 2 * Material.AirFilmFloorReduced.rvalue
        misc_r = Material.Plywood(plywood_thick_in).rvalue + floor_film_r
        wood_stud = Material.Stud2x6
        floor_cav_depth = wood_stud.thick_in
        floor_ff = 0.01
        floor_cav_r = (1.0 - floor_ff) / (1.0 / floor_assembly_r - floor_ff / (wood_stud.rvalue + misc_r)) - misc_r
        floor_cont_r = 0.0
        floor_cont_depth = 0.0
        floor_grade = 1

      end
      
      # Apply constructions
      
      if wall_surface.nil?
      
        # Foundation slab only
        
        success = FoundationConstructions.apply_slab(runner, model, slab_surface, "SlabConstruction",
                                                     slab_perim_r, slab_perim_width, slab_gap_r, slab_ext_r, slab_ext_depth,
                                                     slab_whole_r, slab_concrete_thick_in, mat_carpet,
                                                     false, perim_exp, nil)
        return false if not success
        
        # FIXME: Temporary code for sizing
        unit.setFeature(Constants.SizingInfoSlabRvalue(slab_surface), 5.0)
        
      else
      
        # Foundation slab, walls, and ceilings
        
        if slab_surface.nil?
          # Handle crawlspace without a slab (i.e., dirt floor)
        end
        
        success = FoundationConstructions.apply_walls_and_slab(runner, model, [wall_surface], "FndWallConstruction", 
                                                               wall_cont_height, wall_cav_r, wall_grade,
                                                               wall_cav_depth, wall_filled_cavity, wall_ff, 
                                                               wall_cont_r, walls_drywall_thick_in, wall_concrete_thick_in, 
                                                               wall_height, slab_surface, "SlabConstruction",
                                                               slab_whole_r, slab_concrete_thick_in, perim_exp)
        return false if not success
        
        if not wall_assembly_r.nil?
          check_surface_assembly_rvalue(wall_surface, wall_film_r, wall_assembly_r)
        end
        
      end
      
      # Foundation ceiling
      success = FloorConstructions.apply_foundation_ceiling(runner, model, ceiling_surfaces, "FndCeilingConstruction",
                                                            floor_cav_r, floor_grade,
                                                            floor_ff, floor_cav_depth,
                                                            plywood_thick_in, mat_floor_covering, 
                                                            mat_carpet)
      return false if not success
      
      if not floor_assembly_r.nil?
        check_surface_assembly_rvalue(ceiling_surfaces[0], floor_film_r, floor_assembly_r)
      end
        
    end
    
    return true
  end

  def self.add_finished_floor_area(runner, model, building, spaces)
  
    # Add finished floor area (e.g., floors between finished spaces) to ensure model has
    # the correct ffa as specified.
  
    ffa = Float(XMLHelper.get_value(building, "BuildingDetails/BuildingSummary/BuildingConstruction/ConditionedFloorArea")).round(1)
    
    # Calculate ffa already added to model
    model_ffa = Geometry.get_finished_floor_area_from_spaces(model.getSpaces).round(1)
    
    if model_ffa > ffa
      runner.registerError("Sum of conditioned floor surface areas #{model_ffa.to_s} is greater than ConditionedFloorArea specified #{ffa.to_s}.")
      return false
    end
    
    addtl_ffa = ffa - model_ffa
    return true unless addtl_ffa > 0
    
    runner.registerWarning("Adding adiabatic conditioned floors with #{addtl_ffa.to_s} ft^2 to preserve building total conditioned floor area.")
      
    
    finishedfloor_width = Math::sqrt(addtl_ffa)
    finishedfloor_length = addtl_ffa / finishedfloor_width
    z_origin = 0
    
    surface = OpenStudio::Model::Surface.new(add_floor_polygon(-UnitConversions.convert(finishedfloor_width,"ft","m"), 
                                                               -UnitConversions.convert(finishedfloor_length,"ft","m"), 
                                                               UnitConversions.convert(z_origin,"ft","m")), model)
    surface.setName("inferred finished floor")
    surface.setSurfaceType("Floor")
    surface.setSpace(spaces[Constants.SpaceTypeLiving])
    surface.setOutsideBoundaryCondition("Adiabatic")
    
    # Apply Construction
    success = apply_adiabatic_construction(runner, model, [surface], "floor")
    return false if not success

    return true
  end
  
  def self.add_thermal_mass(runner, model, building)
  
    # FIXME: See 301 Standard
    furniture_frac_of_ffa = 1.0
    mass_lb_per_sqft = 8.0 # Move to HPXMLc
    density_lb_per_cuft = 40.0
    mat = BaseMaterial.Wood
    success = ThermalMassConstructions.apply_furniture(runner, model, furniture_frac_of_ffa, 
                                                       mass_lb_per_sqft, density_lb_per_cuft, mat)
    return false if not success

    return true
  end
  
  def self.add_walls(runner, model, building, avg_ceil_hgt, spaces, fenestration_areas)

    building.elements.each("BuildingDetails/Enclosure/Walls/Wall") do |wall|
    
      interior_adjacent_to = XMLHelper.get_value(wall, "extension/InteriorAdjacentTo")
      exterior_adjacent_to = XMLHelper.get_value(wall, "extension/ExteriorAdjacentTo")
      
      wall_id = wall.elements["SystemIdentifier"].attributes["id"]
      
      wall_gross_area = Float(XMLHelper.get_value(wall, "Area"))
      wall_net_area = net_wall_area(wall_gross_area, fenestration_areas, wall_id)
      wall_height = avg_ceil_hgt
      wall_length = wall_net_area / wall_height
      z_origin = 0

      surface = OpenStudio::Model::Surface.new(add_wall_polygon(UnitConversions.convert(wall_length,"ft","m"), 
                                                                UnitConversions.convert(wall_height,"ft","m"), 
                                                                UnitConversions.convert(z_origin,"ft","m")), model)
      surface.setName(wall_id)
      surface.setSurfaceType("Wall") 
      if ["living space"].include? interior_adjacent_to
        surface.setSpace(spaces[Constants.SpaceTypeLiving])
      elsif ["garage"].include? interior_adjacent_to
        surface.setSpace(spaces[Constants.SpaceTypeGarage])
      elsif ["unvented attic", "vented attic"].include? interior_adjacent_to
        surface.setSpace(spaces[Constants.SpaceTypeUnfinishedAttic])
      elsif ["cape cod"].include? interior_adjacent_to
        surface.setSpace(spaces[Constants.SpaceTypeFinishedAttic])
      else
        fail "Unhandled value (#{interior_adjacent_to})."
      end
      if ["ambient"].include? exterior_adjacent_to
        surface.setOutsideBoundaryCondition("Outdoors")
      elsif ["garage"].include? exterior_adjacent_to
        surface.createAdjacentSurface(spaces[Constants.SpaceTypeGarage])
      elsif ["unvented attic", "vented attic"].include? exterior_adjacent_to
        surface.createAdjacentSurface(spaces[Constants.SpaceTypeUnfinishedAttic])
      elsif ["cape cod"].include? exterior_adjacent_to
        surface.createAdjacentSurface(spaces[Constants.SpaceTypeFinishedAttic])
      elsif exterior_adjacent_to != "ambient" and exterior_adjacent_to != "ground"
        fail "Unhandled value (#{exterior_adjacent_to})."
      end
      
      # Apply construction
      
      siding = XMLHelper.get_value(wall, "Siding")
      solar_abs = Float(XMLHelper.get_value(wall, "SolarAbsorptance"))
      emitt = Float(XMLHelper.get_value(wall, "Emittance"))
      mat_ext_finish = get_siding_material(siding, solar_abs, emitt)
      assembly_r, film_r = nil

      if XMLHelper.has_element(wall, "WallType/WoodStud")
      
        osb_thick_in = 0.0
        drywall_thick_in = 0.0
        assembly_r = Float(XMLHelper.get_value(wall, "Insulation/AssemblyEffectiveRValue"))
        film_r = Material.AirFilmVertical.rvalue + Material.AirFilmOutside.rvalue
        misc_r = Material.GypsumWall(drywall_thick_in).rvalue + Material.Plywood(osb_thick_in).rvalue + mat_ext_finish.rvalue + film_r
        wood_stud = Material.Stud2x6
        cavity_depth_in = wood_stud.thick_in
        framing_factor = 0.01
        cavity_r = (1.0 - framing_factor) / (1.0 / assembly_r - framing_factor / (wood_stud.rvalue + misc_r)) - misc_r
        rigid_r = 0.0
        install_grade = 1
        cavity_filled = true
        
        success = WallConstructions.apply_wood_stud(runner, model, [surface],
                                                    "WallConstruction",
                                                    cavity_r, install_grade, cavity_depth_in,
                                                    cavity_filled, framing_factor,
                                                    drywall_thick_in, osb_thick_in,
                                                    rigid_r, mat_ext_finish)
        return false if not success
        
        check_surface_assembly_rvalue(surface, film_r, assembly_r)
          
      else
      
        fail "Unexpected wall type."
        
      end
      
    end
    
    return true
    
  end
  
  def self.add_rim_joists(runner, model, building, spaces)

    building.elements.each("BuildingDetails/Enclosure/RimJoists/RimJoist") do |rim_joist|
    
      interior_adjacent_to = XMLHelper.get_value(rim_joist, "InteriorAdjacentTo")
      exterior_adjacent_to = XMLHelper.get_value(rim_joist, "ExteriorAdjacentTo")
      
      rim_joist_id = rim_joist.elements["SystemIdentifier"].attributes["id"]
      
      rim_joist_area = Float(XMLHelper.get_value(rim_joist, "Area"))
      rim_joist_height = 7.5
      rim_joist_length = rim_joist_area / rim_joist_height
      z_origin = 0

      surface = OpenStudio::Model::Surface.new(add_wall_polygon(UnitConversions.convert(rim_joist_length,"ft","m"), 
                                                                UnitConversions.convert(rim_joist_height,"ft","m"), 
                                                                UnitConversions.convert(z_origin,"ft","m")), model)
      surface.setName(rim_joist_id)
      surface.setSurfaceType("Wall") 
      if ["living space"].include? interior_adjacent_to
        surface.setSpace(spaces[Constants.SpaceTypeLiving])
      elsif ["garage"].include? interior_adjacent_to
        surface.setSpace(spaces[Constants.SpaceTypeGarage])
      elsif ["unvented attic", "vented attic"].include? interior_adjacent_to
        surface.setSpace(spaces[Constants.SpaceTypeUnfinishedAttic])
      elsif ["cape cod"].include? interior_adjacent_to
        surface.setSpace(spaces[Constants.SpaceTypeFinishedAttic])
      else
        fail "Unhandled value (#{interior_adjacent_to})."
      end
      if ["ambient"].include? exterior_adjacent_to
        surface.setOutsideBoundaryCondition("Outdoors")
      elsif ["garage"].include? exterior_adjacent_to
        surface.createAdjacentSurface(spaces[Constants.SpaceTypeGarage])
      elsif ["unvented attic", "vented attic"].include? exterior_adjacent_to
        surface.createAdjacentSurface(spaces[Constants.SpaceTypeUnfinishedAttic])
      elsif ["cape cod"].include? exterior_adjacent_to
        surface.createAdjacentSurface(spaces[Constants.SpaceTypeFinishedAttic])
      elsif exterior_adjacent_to != "ambient" and exterior_adjacent_to != "ground"
        fail "Unhandled value (#{exterior_adjacent_to})."
      end
      
      # Apply construction
      
      siding = "fiber cement siding" # FIXME
      solar_abs = Float(XMLHelper.get_value(rim_joist, "extension/SolarAbsorptance"))
      emitt = Float(XMLHelper.get_value(rim_joist, "extension/Emittance"))
      mat_ext_finish = get_siding_material(siding, solar_abs, emitt)
      assembly_r, film_r = nil

      osb_thick_in = 0.0
      drywall_thick_in = 0.0
      continuous_wood_thick_in = 1.5
      assembly_r = Float(XMLHelper.get_value(rim_joist, "Insulation/AssemblyEffectiveRValue"))
      film_r = Material.AirFilmVertical.rvalue + Material.AirFilmOutside.rvalue
      misc_r = Material.GypsumWall(drywall_thick_in).rvalue + Material.Plywood(osb_thick_in).rvalue + Material.Stud2x(continuous_wood_thick_in).rvalue + mat_ext_finish.rvalue + film_r
      wood_stud = Material.Stud2x(2.0)
      framing_factor = 1.5 / (1.5 + 7.5)
      cavity_r = (1.0 - framing_factor) / (1.0 / assembly_r - framing_factor / (wood_stud.rvalue + misc_r)) - misc_r
      rigid_r = 0.0
      install_grade = 1
      
      success = WallConstructions.apply_rim_joist(runner, model, [surface],
                                                  "RimJoistConstruction",
                                                  cavity_r, install_grade, framing_factor,
                                                  drywall_thick_in, osb_thick_in,
                                                  rigid_r, mat_ext_finish)
      return false if not success
      
      check_surface_assembly_rvalue(surface, film_r, assembly_r)
      
    end
    
    return true
    
  end
  
  def self.get_siding_material(siding, solar_abs, emitt)
    
    if siding == "stucco"    
      k_in = 4.5
      rho = 80.0
      cp = 0.21
      thick_in = 1.0
    elsif siding == "brick veneer"
      k_in = 5.5
      rho = 110.0
      cp = 0.19
      thick_in = 4.0
    elsif siding == "wood siding"
      k_in = 0.71
      rho = 34.0
      cp = 0.28
      thick_in = 1.0
    elsif siding == "aluminum siding"
      k_in = 0.61
      rho = 10.9
      cp = 0.29
      thick_in = 0.375
    elsif siding == "vinyl siding"
      k_in = 0.62
      rho = 11.1
      cp = 0.25
      thick_in = 0.375
    elsif siding == "fiber cement siding"
      k_in = 1.79
      rho = 21.7
      cp = 0.24
      thick_in = 0.375
    else
      fail "Unexpected siding type: #{siding}."
    end
    
    return Material.new(name="Siding", thick_in=thick_in, mat_base=nil, k_in=k_in, rho=rho, cp=cp, tAbs=emitt, sAbs=solar_abs, vAbs=solar_abs)
    
  end
  
  def self.add_attics(runner, model, building, avg_ceil_hgt, spaces, fenestration_areas)

    building.elements.each("BuildingDetails/Enclosure/AtticAndRoof/Attics/Attic") do |attic|
    
      attic_type = XMLHelper.get_value(attic, "AtticType")
    
      attic.elements.each("Floors/Floor") do |floor|
      
        floor_id = floor.elements["SystemIdentifier"].attributes["id"]
        exterior_adjacent_to = XMLHelper.get_value(floor, "extension/ExteriorAdjacentTo")
        
        floor_area = Float(XMLHelper.get_value(floor, "Area"))
        floor_width = Math::sqrt(floor_area)
        floor_length = floor_area / floor_width
        z_origin = 0
       
        surface = OpenStudio::Model::Surface.new(add_floor_polygon(UnitConversions.convert(floor_length,"ft","m"), 
                                                                   UnitConversions.convert(floor_width,"ft","m"), 
                                                                   UnitConversions.convert(z_origin,"ft","m")), model)
        surface.setName(floor_id)
        surface.setSurfaceType("Floor")
        if ["vented attic", "unvented attic"].include? attic_type
          surface.setSpace(spaces[Constants.SpaceTypeUnfinishedAttic])
        elsif ["cape cod"].include? attic_type
          surface.setSpace(spaces[Constants.SpaceTypeFinishedAttic])
        elsif attic_type != "flat roof" and attic_type != "cathedral ceiling"
          fail "Unhandled value (#{attic_type})."
        end
        if ["living space"].include? exterior_adjacent_to
          surface.createAdjacentSurface(spaces[Constants.SpaceTypeLiving])
        elsif ["garage"].include? exterior_adjacent_to
          surface.createAdjacentSurface(spaces[Constants.SpaceTypeGarage])
        elsif exterior_adjacent_to != "ambient" and exterior_adjacent_to != "ground"
          fail "Unhandled value (#{exterior_adjacent_to})."
        end
        
        # Apply construction
        
        ceiling_drywall_thick_in = 0.0
        assembly_r = Float(XMLHelper.get_value(floor, "Insulation/AssemblyEffectiveRValue"))
        film_r = 2 * Material.AirFilmFloorAverage.rvalue
        misc_r = Material.GypsumWall(ceiling_drywall_thick_in).rvalue + film_r
        wood_stud = Material.Stud2x6
        ceiling_joist_height_in = wood_stud.thick_in
        ceiling_ins_thick_in = ceiling_joist_height_in
        ceiling_framing_factor = 0.01
        ceiling_r = (1.0 - ceiling_framing_factor) / (1.0 / assembly_r - ceiling_framing_factor / (wood_stud.rvalue + misc_r)) - misc_r
        ceiling_install_grade = 1
        
        success = FloorConstructions.apply_unfinished_attic(runner, model, [surface],
                                                            "FloorConstruction",
                                                            ceiling_r, ceiling_install_grade,
                                                            ceiling_ins_thick_in,
                                                            ceiling_framing_factor,
                                                            ceiling_joist_height_in,
                                                            ceiling_drywall_thick_in)
        return false if not success
        
        check_surface_assembly_rvalue(surface, film_r, assembly_r)
        
      end
      
      attic.elements.each("Roofs/Roof") do |roof|
  
        roof_id = roof.elements["SystemIdentifier"].attributes["id"]
     
        # FIXME: Calculate net from gross due to skylights
        roof_area = Float(XMLHelper.get_value(roof, "Area"))
        roof_width = Math::sqrt(roof_area)
        roof_length = roof_area / roof_width
        z_origin = 0
        roof_tilt = Float(XMLHelper.get_value(roof, "Pitch"))/12.0

        surface = OpenStudio::Model::Surface.new(add_roof_polygon(UnitConversions.convert(roof_length,"ft","m"), 
                                                                  UnitConversions.convert(roof_width,"ft","m"), 
                                                                  UnitConversions.convert(z_origin,"ft","m"),
                                                                  0.0, roof_tilt), model)
                                                                     
        surface.setName(roof_id)
        surface.setSurfaceType("RoofCeiling")
        surface.setOutsideBoundaryCondition("Outdoors")
        if ["unvented attic", "vented attic"].include? attic_type
          surface.setSpace(spaces[Constants.SpaceTypeUnfinishedAttic])
        elsif ["flat roof", "cathedral ceiling"].include? attic_type
          surface.setSpace(spaces[Constants.SpaceTypeLiving])
        elsif ["cape cod"].include? attic_type
          surface.setSpace(spaces[Constants.SpaceTypeFinishedAttic])
        end
        
        # Apply construction
        
        mat_roofing = Material.RoofingAsphaltShinglesDark # FIXME
        roof_osb_thick_in = 0.0
        assembly_r = Float(XMLHelper.get_value(roof, "Insulation/AssemblyEffectiveRValue"))
        film_r = Material.AirFilmOutside.rvalue + Material.AirFilmRoof(Geometry.get_roof_pitch([surface])).rvalue
        misc_r = mat_roofing.rvalue + Material.Plywood(roof_osb_thick_in).rvalue + film_r
        wood_stud = Material.Stud2x6
        roof_framing_thick_in = wood_stud.thick_in
        roof_cavity_ins_thick_in = roof_framing_thick_in
        roof_framing_factor = 0.01
        roof_cavity_r = (1.0 - roof_framing_factor) / (1.0 / assembly_r - roof_framing_factor / (wood_stud.rvalue + misc_r)) - misc_r
        roof_install_grade = 1
        roof_rigid_r = 0.0
        has_radiant_barrier = false

        # FIXME: Unfinished vs finished
        success = RoofConstructions.apply_unfinished_attic(runner, model, [surface],
                                                           "RoofConstruction",
                                                           roof_cavity_r, roof_install_grade, 
                                                           roof_cavity_ins_thick_in,
                                                           roof_framing_factor, 
                                                           roof_framing_thick_in,
                                                           roof_osb_thick_in, roof_rigid_r,
                                                           mat_roofing, has_radiant_barrier)
        return false if not success
        
        check_surface_assembly_rvalue(surface, film_r, assembly_r)
        
      end
      
      attic.elements.each("Walls/Wall") do |wall|
      
        exterior_adjacent_to = XMLHelper.get_value(wall, "extension/ExteriorAdjacentTo")
        
        wall_id = wall.elements["SystemIdentifier"].attributes["id"]
        
        wall_gross_area = Float(XMLHelper.get_value(wall, "Area"))
        wall_net_area = net_wall_area(wall_gross_area, fenestration_areas, wall_id)
        wall_height = avg_ceil_hgt
        wall_length = wall_net_area / wall_height
        z_origin = 0

        surface = OpenStudio::Model::Surface.new(add_wall_polygon(UnitConversions.convert(wall_length,"ft","m"), 
                                                                  UnitConversions.convert(wall_height,"ft","m"), 
                                                                  UnitConversions.convert(z_origin,"ft","m")), model)
        surface.setName(wall_id)
        surface.setSurfaceType("Wall") 
        if ["unvented attic", "vented attic"].include? attic_type
          surface.setSpace(spaces[Constants.SpaceTypeUnfinishedAttic])
        elsif ["flat roof", "cathedral ceiling"].include? attic_type
          surface.setSpace(spaces[Constants.SpaceTypeLiving])
        elsif ["cape cod"].include? attic_type
          surface.setSpace(spaces[Constants.SpaceTypeFinishedAttic])
        end
        if ["ambient"].include? exterior_adjacent_to
          surface.setOutsideBoundaryCondition("Outdoors")
        elsif ["garage"].include? exterior_adjacent_to
          surface.createAdjacentSurface(spaces[Constants.SpaceTypeGarage])
        elsif ["unvented attic", "vented attic"].include? exterior_adjacent_to
          surface.createAdjacentSurface(spaces[Constants.SpaceTypeUnfinishedAttic])
        elsif ["cape cod"].include? exterior_adjacent_to
          surface.createAdjacentSurface(spaces[Constants.SpaceTypeFinishedAttic])
        elsif ["living space"].include? exterior_adjacent_to
          surface.createAdjacentSurface(spaces[Constants.SpaceTypeLiving])
        elsif exterior_adjacent_to != "ambient" and exterior_adjacent_to != "ground"
          fail "Unhandled value (#{exterior_adjacent_to})."
        end
        
        # Apply construction
        
        siding = XMLHelper.get_value(wall, "Siding")
        solar_abs = Float(XMLHelper.get_value(wall, "SolarAbsorptance"))
        emitt = Float(XMLHelper.get_value(wall, "Emittance"))
        mat_ext_finish = get_siding_material(siding, solar_abs, emitt)

        if XMLHelper.has_element(wall, "WallType/WoodStud")
        
          osb_thick_in = 0.0
          drywall_thick_in = 0.0
          assembly_r = Float(XMLHelper.get_value(wall, "Insulation/AssemblyEffectiveRValue"))
          film_r = Material.AirFilmVertical.rvalue + Material.AirFilmOutside.rvalue
          misc_r = Material.GypsumWall(drywall_thick_in).rvalue + Material.Plywood(osb_thick_in).rvalue + mat_ext_finish.rvalue + film_r
          wood_stud = Material.Stud2x4
          cavity_depth_in = wood_stud.thick_in
          framing_factor = 0.01
          cavity_r = (1.0 - framing_factor) / (1.0 / assembly_r - framing_factor / (wood_stud.rvalue + misc_r)) - misc_r
          rigid_r = 0.0
          install_grade = 1
          cavity_filled = true
          
          success = WallConstructions.apply_wood_stud(runner, model, [surface],
                                                      "WallConstruction",
                                                      cavity_r, install_grade, cavity_depth_in,
                                                      cavity_filled, framing_factor,
                                                      drywall_thick_in, osb_thick_in,
                                                      rigid_r, mat_ext_finish)
          return false if not success
          
          check_surface_assembly_rvalue(surface, film_r, assembly_r)
            
        else
        
          fail "Unexpected wall type."
          
        end
      
      end
      
    end
    
    return true
      
  end

  def self.add_windows(runner, model, building, spaces, fenestration_areas, weather)
  
    heating_season, cooling_season = HVAC.calc_heating_and_cooling_seasons(model, weather, runner)
    if heating_season.nil? or cooling_season.nil?
      return false
    end
  
    surfaces = []
    building.elements.each("BuildingDetails/Enclosure/Windows/Window") do |window|
    
      window_id = window.elements["SystemIdentifier"].attributes["id"]

      window_area = Float(XMLHelper.get_value(window, "Area"))
      window_height = Float(XMLHelper.get_value(window, "extension/Height"))
      window_width = window_area / window_height
      window_azimuth = Float(XMLHelper.get_value(window, "Azimuth"))
      z_origin = 0

      if not fenestration_areas.keys.include? window.elements["AttachedToWall"].attributes["idref"]
        fenestration_areas[window.elements["AttachedToWall"].attributes["idref"]] = window_area
      else
        fenestration_areas[window.elements["AttachedToWall"].attributes["idref"]] += window_area
      end

      surface = OpenStudio::Model::Surface.new(add_wall_polygon(UnitConversions.convert(window_width,"ft","m"), 
                                                                UnitConversions.convert(window_height,"ft","m"), 
                                                                UnitConversions.convert(z_origin,"ft","m"), 
                                                                window_azimuth,
                                                                [0, 0.001, 0.001 * 2, 0.001]), model) # offsets B, L, T, R
      surface.setName("surface #{window_id}")
      surface.setSurfaceType("Wall")
      building.elements.each("BuildingDetails/Enclosure/Walls/Wall") do |wall|
        next unless wall.elements["SystemIdentifier"].attributes["id"] == window.elements["AttachedToWall"].attributes["idref"]
        interior_adjacent_to = XMLHelper.get_value(wall, "extension/InteriorAdjacentTo")
        if interior_adjacent_to == "living space"
          surface.setSpace(spaces[Constants.SpaceTypeLiving])
        elsif interior_adjacent_to == "garage"
          surface.setSpace(spaces[Constants.SpaceTypeGarage])
        elsif interior_adjacent_to == "vented attic" or interior_adjacent_to == "unvented attic"
          surface.setSpace(spaces[Constants.SpaceTypeUnfinishedAttic])
        elsif interior_adjacent_to == "cape cod"
          surface.setSpace(spaces[Constants.SpaceTypeFinishedAttic])
        else
          fail "Unhandled value (#{interior_adjacent_to})."
        end
      end
      surface.setOutsideBoundaryCondition("Outdoors") # cannot be adiabatic or OS won't create subsurface
      surfaces << surface
      
      sub_surface = OpenStudio::Model::SubSurface.new(add_wall_polygon(UnitConversions.convert(window_width,"ft","m"), 
                                                                       UnitConversions.convert(window_height,"ft","m"), 
                                                                       UnitConversions.convert(z_origin,"ft","m"), 
                                                                       window_azimuth, 
                                                                       [-0.001, 0, 0.001, 0]), model) # offsets B, L, T, R
      sub_surface.setName(window_id)
      sub_surface.setSurface(surface)
      sub_surface.setSubSurfaceType("FixedWindow")
      
      overhang_depth = 0
      overhang_offset = 0
      if window.elements["Overhangs"]
        overhang_depth = Float(XMLHelper.get_value(window, "Overhangs/Depth"))
        overhang_offset = Float(XMLHelper.get_value(window, "Overhangs/DistanceToTopOfWindow"))
        if overhang_depth > 0
          puts "add overhang!"
          puts sub_surface.addOverhang(UnitConversions.convert(overhang_depth,"ft","m"), UnitConversions.convert(overhang_offset,"ft","m")).is_initialized
        end
      end
      
      # Apply construction
      ufactor = Float(XMLHelper.get_value(window, "UFactor"))
      shgc = Float(XMLHelper.get_value(window, "SHGC"))
      cool_shade_mult = Float(XMLHelper.get_value(window, "extension/InteriorShadingFactorSummer"))
      heat_shade_mult = Float(XMLHelper.get_value(window, "extension/InteriorShadingFactorWinter"))
      
      success = SubsurfaceConstructions.apply_window(runner, model, [sub_surface],
                                                     "WindowConstruction",
                                                     weather, cooling_season, ufactor, shgc,
                                                     heat_shade_mult, cool_shade_mult)
      return false if not success

    end
    
    success = apply_adiabatic_construction(runner, model, surfaces, "wall")
    return false if not success
      
    return true
   
  end
  
  def self.add_doors(runner, model, building, spaces, fenestration_areas)
  
    surfaces = []
    building.elements.each("BuildingDetails/Enclosure/Doors/Door") do |door|
    
      door_id = door.elements["SystemIdentifier"].attributes["id"]

      door_area = Float(XMLHelper.get_value(door, "Area"))
      door_height = Float(XMLHelper.get_value(door, "extension/Height"))
      door_width = door_area / door_height
      door_azimuth = Float(XMLHelper.get_value(door, "Azimuth"))
      z_origin = 0
    
      if not fenestration_areas.keys.include? door.elements["AttachedToWall"].attributes["idref"]
        fenestration_areas[door.elements["AttachedToWall"].attributes["idref"]] = door_area
      else
        fenestration_areas[door.elements["AttachedToWall"].attributes["idref"]] += door_area
      end

      surface = OpenStudio::Model::Surface.new(add_wall_polygon(UnitConversions.convert(door_width,"ft","m"), 
                                                                UnitConversions.convert(door_height,"ft","m"), 
                                                                UnitConversions.convert(z_origin,"ft","m"), 
                                                                door_azimuth, 
                                                                [0, 0.001, 0.001, 0.001]), model) # offsets B, L, T, R
      surface.setName("surface #{door_id}")
      surface.setSurfaceType("Wall")
      building.elements.each("BuildingDetails/Enclosure/Walls/Wall") do |wall|
        next unless wall.elements["SystemIdentifier"].attributes["id"] == door.elements["AttachedToWall"].attributes["idref"]
        interior_adjacent_to = XMLHelper.get_value(wall, "extension/InteriorAdjacentTo")
        if interior_adjacent_to == "living space"
          surface.setSpace(spaces[Constants.SpaceTypeLiving])
        elsif interior_adjacent_to == "garage"
          surface.setSpace(spaces[Constants.SpaceTypeGarage])
        elsif interior_adjacent_to == "vented attic" or interior_adjacent_to == "unvented attic"
          surface.setSpace(spaces[Constants.SpaceTypeUnfinishedAttic])
        elsif interior_adjacent_to == "cape cod"
          surface.setSpace(spaces[Constants.SpaceTypeFinishedAttic])
        else
          fail "Unhandled value (#{interior_adjacent_to})."
        end
      end
      surface.setOutsideBoundaryCondition("Outdoors") # cannot be adiabatic or OS won't create subsurface
      surfaces << surface

      sub_surface = OpenStudio::Model::SubSurface.new(add_wall_polygon(UnitConversions.convert(door_width,"ft","m"), 
                                                                       UnitConversions.convert(door_height,"ft","m"), 
                                                                       UnitConversions.convert(z_origin,"ft","m"), 
                                                                       door_azimuth, 
                                                                       [0, 0, 0, 0]), model) # offsets B, L, T, R
      sub_surface.setName(door_id)
      sub_surface.setSurface(surface)
      sub_surface.setSubSurfaceType("Door")
      
      # Apply construction
      name = door.elements["SystemIdentifier"].attributes["id"]
      area = Float(XMLHelper.get_value(door, "Area"))
      ua = area/Float(XMLHelper.get_value(door, "RValue"))
      ufactor = ua/area
      
      success = SubsurfaceConstructions.apply_door(runner, model, [sub_surface], "Door", ufactor)
      return false if not success

    end
    
    success = apply_adiabatic_construction(runner, model, surfaces, "wall")
    return false if not success
    
    return true
   
  end  
  
  def self.apply_adiabatic_construction(runner, model, surfaces, type)
    
    # Arbitrary constructions, only heat capacitance matters
    
    if type == "wall"
    
        framing_factor = Constants.DefaultFramingFactorInterior
        cavity_r = 0.0
        install_grade = 1
        cavity_depth_in = 3.5
        cavity_filled = false
        rigid_r = 0.0
        drywall_thick_in = 0.5
        mat_ext_finish = Material.ExtFinishStuccoMedDark
        success = WallConstructions.apply_wood_stud(runner, model, surfaces,
                                                    "AdiabaticWallConstruction", 
                                                    cavity_r, install_grade, cavity_depth_in, 
                                                    cavity_filled, framing_factor,
                                                    drywall_thick_in, 0, rigid_r, mat_ext_finish)
        return false if not success
        
    elsif type == "floor"
        
        plywood_thick_in = 0.75
        drywall_thick_in = 0.0
        mat_floor_covering = Material.FloorWood
        mat_carpet = Material.CoveringBare
        success = FloorConstructions.apply_uninsulated(runner, model, surfaces,
                                                       "AdiabaticFloorConstruction",
                                                       plywood_thick_in, drywall_thick_in,
                                                       mat_floor_covering, mat_carpet)
        return false if not success
        
    end
    
    return true
  end
  
  def self.add_water_heater(runner, model, building, unit, weather, spaces)

    ec_adj = XMLHelper.get_value(building, "BuildingDetails/Systems/WaterHeating/HotWaterDistribution/extension/EnergyConsumptionAdjustmentFactor")
    if ec_adj.nil?
      ec_adj = 1.0
    else
      ec_adj = Float(ec_adj)
    end
  
    dhw = building.elements["BuildingDetails/Systems/WaterHeating/WaterHeatingSystem"]
    
    return true if dhw.nil?
    
    location = XMLHelper.get_value(dhw, "Location")
    setpoint_temp = Float(XMLHelper.get_value(dhw, "HotWaterTemperature"))
    wh_type = XMLHelper.get_value(dhw, "WaterHeaterType")
    fuel = XMLHelper.get_value(dhw, "FuelType")
    
    if location == 'conditioned space'
      space = spaces[Constants.SpaceTypeLiving]
    elsif location == 'basement - unconditioned'
      space = spaces[Constants.SpaceTypeUnfinishedBasement]
    elsif location == 'attic - unconditioned'
      space = spaces[Constants.SpaceTypeUnfinishedAttic]
    elsif location == 'garage - unconditioned'
      space = spaces[Constants.SpaceTypeGarage]
    elsif location == 'crawlspace - unvented' or location == 'crawlspace - vented'
      space = spaces[Constants.SpaceTypeCrawl]
    else
      fail "Unhandled water heater space: #{location}."
    end
    if space.nil?
      fail "Water heater location was #{location} but building does not have this space type."
    end

    if wh_type == "storage water heater"
    
      tank_vol = Float(XMLHelper.get_value(dhw, "TankVolume"))
      ef = Float(XMLHelper.get_value(dhw, "EnergyFactor"))
      if fuel != "electricity"
        re = Float(XMLHelper.get_value(dhw, "RecoveryEfficiency"))
      else
        re = 0.98
      end
      capacity_kbtuh = Float(XMLHelper.get_value(dhw, "HeatingCapacity")) / 1000.0
      oncycle_power = 0.0
      offcycle_power = 0.0
      success = Waterheater.apply_tank(model, unit, runner, space, to_beopt_fuel(fuel), 
                                       capacity_kbtuh, tank_vol, ef, re, setpoint_temp, 
                                       oncycle_power, offcycle_power, ec_adj)
      return false if not success
      
    elsif wh_type == "instantaneous water heater"
    
      ef = Float(XMLHelper.get_value(dhw, "EnergyFactor"))
      ef_adj = Float(XMLHelper.get_value(dhw, "extension/PerformanceAdjustmentEnergyFactor"))
      capacity_kbtuh = 100000000.0
      oncycle_power = 0.0
      offcycle_power = 0.0
      success = Waterheater.apply_tankless(model, unit, runner, space, to_beopt_fuel(fuel), 
                                           capacity_kbtuh, ef, ef_adj,
                                           setpoint_temp, oncycle_power, offcycle_power, ec_adj)
      return false if not success
      
    elsif wh_type == "heat pump water heater"
    
      tank_vol = Float(XMLHelper.get_value(dhw, "TankVolume"))
      e_cap = 4.5 # FIXME
      min_temp = 45.0 # FIXME
      max_temp = 120.0 # FIXME
      cap = 0.5 # FIXME
      cop = 2.8 # FIXME
      shr = 0.88 # FIXME
      airflow_rate = 181.0 # FIXME
      fan_power = 0.0462 # FIXME
      parasitics = 3.0 # FIXME
      tank_ua = 3.9 # FIXME
      int_factor = 1.0 # FIXME
      temp_depress = 0.0 # FIXME
      ducting = "none"
      # FIXME: Use ec_adj
      success = Waterheater.apply_heatpump(model, unit, runner, space, weather,
                                           e_cap, tank_vol, setpoint_temp, min_temp, max_temp,
                                           cap, cop, shr, airflow_rate, fan_power,
                                           parasitics, tank_ua, int_factor, temp_depress,
                                           ducting, 0)
      return false if not success
      
    else
    
      fail "Unhandled water heater (#{wh_type})."
      
    end
    
    return true

  end
  
  def self.add_hot_water_and_appliances(runner, model, building, unit, weather)
  
    wh = building.elements["BuildingDetails/Systems/WaterHeating"]
    appl = building.elements["BuildingDetails/Appliances"]
    
    # Clothes Washer
    cw = appl.elements["ClothesWasher"]
    cw_annual_kwh = Float(XMLHelper.get_value(cw, "extension/AnnualkWh"))
    cw_frac_sens = Float(XMLHelper.get_value(cw, "extension/FracSensible"))
    cw_frac_lat = Float(XMLHelper.get_value(cw, "extension/FracLatent"))
    cw_gpd = Float(XMLHelper.get_value(cw, "extension/HotWaterGPD"))
    
    # Clothes Dryer
    cd = appl.elements["ClothesDryer"]
    cd_annual_kwh = Float(XMLHelper.get_value(cd, "extension/AnnualkWh"))
    cd_annual_therm = Float(XMLHelper.get_value(cd, "extension/AnnualTherm"))
    cd_frac_sens = Float(XMLHelper.get_value(cd, "extension/FracSensible"))
    cd_frac_lat = Float(XMLHelper.get_value(cd, "extension/FracLatent"))
    cd_fuel_type = to_beopt_fuel(XMLHelper.get_value(cd, "FuelType"))
    
    # Dishwasher
    dw = appl.elements["Dishwasher"]
    dw_annual_kwh = Float(XMLHelper.get_value(dw, "extension/AnnualkWh"))
    dw_frac_sens = Float(XMLHelper.get_value(dw, "extension/FracSensible"))
    dw_frac_lat = Float(XMLHelper.get_value(dw, "extension/FracLatent"))
    dw_gpd = Float(XMLHelper.get_value(dw, "extension/HotWaterGPD"))
  
    # Refrigerator
    fridge = appl.elements["Refrigerator"]
    fridge_annual_kwh = Float(XMLHelper.get_value(fridge, "RatedAnnualkWh"))
    
    # Cooking Range
    cook = appl.elements["CookingRange"]
    cook_annual_kwh = Float(XMLHelper.get_value(cook, "extension/AnnualkWh"))
    cook_annual_therm = Float(XMLHelper.get_value(cook, "extension/AnnualTherm"))
    cook_frac_sens = Float(XMLHelper.get_value(cook, "extension/FracSensible"))
    cook_frac_lat = Float(XMLHelper.get_value(cook, "extension/FracLatent"))
    cook_fuel_type = to_beopt_fuel(XMLHelper.get_value(cook, "FuelType"))
    
    # Fixtures
    fx_gpd = 0.0
    fx_sens_btu = 0.0
    fx_lat_btu = 0.0
    if not wh.nil?
      fx = wh.elements["WaterFixture"]
      fx_gpd = Float(XMLHelper.get_value(fx, "extension/MixedWaterGPD"))
      fx_sens_btu = Float(XMLHelper.get_value(fx, "extension/SensibleGainsBtu"))
      fx_lat_btu = Float(XMLHelper.get_value(fx, "extension/LatentGainsBtu"))
    end
    
    # Distribution
    dist_type = "standard"
    dist_pump_annual_kwh = 0.0
    dist_gpd = 0.0
    dwhr_avail = false
    dwhr_eff = 0.0
    dwhr_eff_adj = 0.0
    dwhr_iFrac = 0.0
    dwhr_plc = 0.0
    dwhr_locF = 0.0
    dwhr_fixF = 0.0
    if not wh.nil?
      dist = wh.elements["HotWaterDistribution"]
      if XMLHelper.has_element(dist, "SystemType/Standard")
        dist_type = "standard"
        dist_pump_annual_kwh = 0.0
      elsif XMLHelper.has_element(dist, "SystemType/Recirculation")
        dist_type = "recirculation"
        dist_pump_annual_kwh = Float(XMLHelper.get_value(dist, "extension/RecircPumpAnnualkWh"))
      end
      dist_gpd = Float(XMLHelper.get_value(dist, "extension/MixedWaterGPD"))
      
      # Drain Water Heat Recovery
      if XMLHelper.has_element(dist, "DrainWaterHeatRecovery")
        dwhr_avail = true
        dwhr_eff = Float(XMLHelper.get_value(dist, "DrainWaterHeatRecovery/Efficiency"))
        dwhr_eff_adj = Float(XMLHelper.get_value(dist, "DrainWaterHeatRecovery/extension/EfficiencyAdjustment"))
        dwhr_iFrac = Float(XMLHelper.get_value(dist, "DrainWaterHeatRecovery/extension/FracImpactedHotWater"))
        dwhr_plc = Float(XMLHelper.get_value(dist, "DrainWaterHeatRecovery/extension/PipingLossCoefficient"))
        dwhr_locF = Float(XMLHelper.get_value(dist, "DrainWaterHeatRecovery/extension/LocationFactor"))
        dwhr_fixF = Float(XMLHelper.get_value(dist, "DrainWaterHeatRecovery/extension/FixtureFactor"))
      end

    end
    
    sum_gpd = cw_gpd + dw_gpd + fx_gpd + dist_gpd
    sum_kwh = cw_annual_kwh + cd_annual_kwh + dw_annual_kwh + fridge_annual_kwh + cook_annual_kwh + dist_pump_annual_kwh
    sum_therm = cd_annual_therm + cook_annual_therm
    if sum_gpd > 0 or sum_kwh > 0 or sum_therm > 0
      success = Waterheater.apply_eri_hw_appl(model, unit, runner, weather,
                                              cw_annual_kwh, cw_frac_sens, cw_frac_lat,
                                              cw_gpd, cd_annual_kwh, cd_annual_therm,
                                              cd_frac_sens, cd_frac_lat, cd_fuel_type,
                                              dw_annual_kwh, dw_frac_sens, dw_frac_lat,
                                              dw_gpd, fridge_annual_kwh, cook_annual_kwh,
                                              cook_annual_therm, cook_frac_sens, 
                                              cook_frac_lat, cook_fuel_type, fx_gpd,
                                              fx_sens_btu, fx_lat_btu, dist_type, 
                                              dist_gpd, dist_pump_annual_kwh, dwhr_avail,
                                              dwhr_eff, dwhr_eff_adj, dwhr_iFrac,
                                              dwhr_plc, dwhr_locF, dwhr_fixF)
      return false if not success
    end
    
    return true
  end
  
  
  def self.add_hvac(runner, model, building, unit, weather)
  
    dse = get_dse(building)
    
    clgsys = building.elements["BuildingDetails/Systems/HVAC/HVACPlant/CoolingSystem"]
    htgsys = building.elements["BuildingDetails/Systems/HVAC/HVACPlant/HeatingSystem"]
    heatpump = building.elements["BuildingDetails/Systems/HVAC/HVACPlant/HeatPump"]
    
    if clgsys
      if not heatpump # FIXME: Temporary
        success = add_cooling_system(runner, model, building, unit, clgsys, dse)
        return false if not success
      end
    end
    
    if htgsys
      if not heatpump # FIXME: Temporary
        success = add_heating_system(runner, model, building, unit, htgsys, dse)
        return false if not success
      end
    end
    
    if heatpump
      success = add_heat_pump(runner, model, building, unit, heatpump, dse, weather)
      return false if not success
    end
    
    if not clgsys and not htgsys and not heatpump
      # Used for, e.g., ASHRAE 140 loads
      success = add_ideal_air_loads(runner, model, unit)
      return false if not success
    end
    
    return true
  end
  
  def self.add_cooling_system(runner, model, building, unit, clgsys, dse)
  
    clg_type = XMLHelper.get_value(clgsys, "CoolingSystemType")
    
    cool_capacity_btuh = XMLHelper.get_value(clgsys, "CoolingCapacity")
    if cool_capacity_btuh.nil?
      cool_capacity_btuh = Constants.SizingAuto
    else
      cool_capacity_btuh = Float(cool_capacity_btuh)
    end
    
    if clg_type == "central air conditioning"
    
      # FIXME: Generalize
      seer_nom = Float(XMLHelper.get_value(clgsys, "AnnualCoolingEfficiency[Units='SEER']/Value"))
      seer_adj = Float(XMLHelper.get_value(clgsys, "extension/PerformanceAdjustmentSEER"))
      seer = seer_nom * seer_adj
      if seer_nom <= 15
        num_speeds = "1-Speed"
      elsif seer_nom <= 21
        num_speeds = "2-Speed"
      else
        num_speeds = "Variable-Speed"
      end
      crankcase_kw = 0.0
      crankcase_temp = 55.0
    
      if num_speeds == "1-Speed"
      
        eers = [0.82 * seer_nom + 0.64]
        shrs = [0.73]
        fan_power_rated = 0.365
        fan_power_installed = 0.5
        eer_capacity_derates = [1.0, 1.0, 1.0, 1.0, 1.0]
        success = HVAC.apply_central_ac_1speed(model, unit, runner, seer, eers, shrs,
                                               fan_power_rated, fan_power_installed,
                                               crankcase_kw, crankcase_temp,
                                               eer_capacity_derates, cool_capacity_btuh, 
                                               dse)
        return false if not success
      
      elsif num_speeds == "2-Speed"
      
        eers = [0.83 * seer_nom + 0.15, 0.56 * seer_nom + 3.57]
        shrs = [0.71, 0.73]
        capacity_ratios = [0.72, 1.0]
        fan_speed_ratios = [0.86, 1.0]
        fan_power_rated = 0.14
        fan_power_installed = 0.3
        eer_capacity_derates = [1.0, 1.0, 1.0, 1.0, 1.0]
        success = HVAC.apply_central_ac_2speed(model, unit, runner, seer, eers, shrs,
                                               capacity_ratios, fan_speed_ratios,
                                               fan_power_rated, fan_power_installed,
                                               crankcase_kw, crankcase_temp,
                                               eer_capacity_derates, cool_capacity_btuh, 
                                               dse)
        return false if not success
        
      elsif num_speeds == "Variable-Speed"
      
        eers = [0.80 * seer_nom, 0.75 * seer_nom, 0.65 * seer_nom, 0.60 * seer_nom]
        shrs = [0.98, 0.82, 0.745, 0.77]
        capacity_ratios = [0.36, 0.64, 1.0, 1.16]
        fan_speed_ratios = [0.51, 0.84, 1.0, 1.19]
        fan_power_rated = 0.14
        fan_power_installed = 0.3
        eer_capacity_derates = [1.0, 1.0, 1.0, 1.0, 1.0]
        success = HVAC.apply_central_ac_4speed(model, unit, runner, seer, eers, shrs,
                                                capacity_ratios, fan_speed_ratios,
                                                fan_power_rated, fan_power_installed,
                                                crankcase_kw, crankcase_temp,
                                                eer_capacity_derates, cool_capacity_btuh, 
                                                dse)
        return false if not success
                                     
      else
      
        fail "Unexpected number of speeds (#{num_speeds}) for cooling system."
        
      end
      
    elsif clg_type == "room air conditioner"
    
      eer = Float(XMLHelper.get_value(clgsys, "AnnualCoolingEfficiency[Units='EER']/Value"))
      shr = 0.65
      airflow_rate = 350.0
      
      success = HVAC.apply_room_ac(model, unit, runner, eer, shr,
                                   airflow_rate, cool_capacity_btuh)
      return false if not success
      
    end  
    
    return true

  end
  
  def self.add_heating_system(runner, model, building, unit, htgsys, dse)

    fuel = XMLHelper.get_value(htgsys, "HeatingSystemFuel")
    
    heat_capacity_btuh = XMLHelper.get_value(htgsys, "HeatingCapacity")
    if heat_capacity_btuh.nil?
      heat_capacity_btuh = Constants.SizingAuto
    else
      heat_capacity_btuh = Float(heat_capacity_btuh)
    end
    
    if XMLHelper.has_element(htgsys, "HeatingSystemType/Furnace")
    
      # FIXME: THIS SHOULD NOT BE NEEDED
      # ==================================
      objname = nil
      if XMLHelper.has_element(htgsys, "HeatingSystemType/Furnace")
        objname = Constants.ObjectNameFurnace
      elsif XMLHelper.has_element(htgsys, "HeatingSystemType/Boiler")
        objname = Constants.ObjectNameBoiler
      elsif XMLHelper.has_element(htgsys, "HeatingSystemType/ElectricResistance")
        objname = Constants.ObjectNameElectricBaseboard
      end
      existing_objects = {}
      thermal_zones = Geometry.get_thermal_zones_from_spaces(unit.spaces)
      HVAC.get_control_and_slave_zones(thermal_zones).each do |control_zone, slave_zones|
        ([control_zone] + slave_zones).each do |zone|
          existing_objects[zone] = HVAC.remove_hvac_equipment(model, runner, zone, unit, objname)
        end
      end
      # ==================================
    
      afue = Float(XMLHelper.get_value(htgsys,"AnnualHeatingEfficiency[Units='AFUE']/Value"))
    
      fan_power_installed = 0.5
      success = HVAC.apply_furnace(model, unit, runner, to_beopt_fuel(fuel), afue,
                                   heat_capacity_btuh, fan_power_installed, dse,
                                   existing_objects)
      return false if not success
      
    elsif XMLHelper.has_element(htgsys, "HeatingSystemType/Boiler")
    
      system_type = Constants.BoilerTypeForcedDraft
      afue = Float(XMLHelper.get_value(htgsys,"AnnualHeatingEfficiency[Units='AFUE']/Value"))
      oat_reset_enabled = false
      oat_high = nil
      oat_low = nil
      oat_hwst_high = nil
      oat_hwst_low = nil
      design_temp = 180.0
      is_modulating = false
      success = HVAC.apply_boiler(model, unit, runner, to_beopt_fuel(fuel), system_type, afue,
                                  oat_reset_enabled, oat_high, oat_low, oat_hwst_high, oat_hwst_low,
                                  heat_capacity_btuh, design_temp, is_modulating, dse)
      return false if not success
    
    elsif XMLHelper.has_element(htgsys, "HeatingSystemType/ElectricResistance")
    
      efficiency = Float(XMLHelper.get_value(htgsys, "AnnualHeatingEfficiency[Units='Percent']/Value"))
      success = HVAC.apply_electric_baseboard(model, unit, runner, efficiency, 
                                              heat_capacity_btuh)
      return false if not success

    # TODO
    #success = HVAC.apply_unit_heater(model, unit, runner, fuel_type,
    #                                 efficiency, capacity, fan_power,
    #                                 airflow)
    #return false if not success
      
    end
    
    return true

  end

  def self.add_heat_pump(runner, model, building, unit, hp, dse, weather)

    hp_type = XMLHelper.get_value(hp, "HeatPumpType")
    
    cool_capacity_btuh = XMLHelper.get_value(hp, "CoolingCapacity")
    if cool_capacity_btuh.nil?
      cool_capacity_btuh = Constants.SizingAuto
    else
      cool_capacity_btuh = Float(cool_capacity_btuh)
    end
    
    backup_heat_capacity_btuh = XMLHelper.get_value(hp, "BackupHeatingCapacity")
    if backup_heat_capacity_btuh.nil?
      backup_heat_capacity_btuh = Constants.SizingAuto
    else
      backup_heat_capacity_btuh = Float(backup_heat_capacity_btuh)
    end
    
    if hp_type == "air-to-air"        
    
      # FIXME: Generalize
      if not hp.elements["AnnualCoolingEfficiency"].nil?
        seer_nom = Float(XMLHelper.get_value(hp, "AnnualCoolingEfficiency[Units='SEER']/Value"))
        seer_adj = Float(XMLHelper.get_value(hp, "extension/PerformanceAdjustmentSEER"))
      else
        # FIXME: Currently getting from AC
        clgsys = building.elements["BuildingDetails/Systems/HVAC/HVACPlant/CoolingSystem"]
        seer_nom = Float(XMLHelper.get_value(clgsys, "AnnualCoolingEfficiency[Units='SEER']/Value"))
        seer_adj = Float(XMLHelper.get_value(clgsys, "extension/PerformanceAdjustmentSEER"))
      end
      seer = seer_nom * seer_adj
      hspf_nom = Float(XMLHelper.get_value(hp, "AnnualHeatingEfficiency[Units='HSPF']/Value"))
      hspf_adj = Float(XMLHelper.get_value(hp, "extension/PerformanceAdjustmentHSPF"))
      hspf = hspf_nom * hspf_adj
      
      if seer_nom <= 15
        num_speeds = "1-Speed"
      elsif seer_nom <= 21
        num_speeds = "2-Speed"
      else
        num_speeds = "Variable-Speed"
      end
      
      crankcase_kw = 0.02
      crankcase_temp = 55.0
      
      if num_speeds == "1-Speed"
      
        eers = [0.80 * seer_nom + 1.0]
        cops = [0.45 * seer_nom - 0.34]
        shrs = [0.73]
        fan_power_rated = 0.365
        fan_power_installed = 0.5
        min_temp = 0.0
        eer_capacity_derates = [1.0, 1.0, 1.0, 1.0, 1.0]
        cop_capacity_derates = [1.0, 1.0, 1.0, 1.0, 1.0]
        supplemental_efficiency = 1.0
        success = HVAC.apply_central_ashp_1speed(model, unit, runner, seer, hspf, eers, cops, shrs,
                                                 fan_power_rated, fan_power_installed, min_temp,
                                                 crankcase_kw, crankcase_temp,
                                                 eer_capacity_derates, cop_capacity_derates,
                                                 cool_capacity_btuh, supplemental_efficiency, 
                                                 backup_heat_capacity_btuh, dse)
        return false if not success
        
      elsif num_speeds == "2-Speed"
      
        eers = [0.78 * seer_nom + 0.6, 0.68 * seer_nom + 1.0]
        cops = [0.60 * seer_nom - 1.40, 0.50 * seer_nom - 0.94]
        shrs = [0.71, 0.724]
        capacity_ratios = [0.72, 1.0]
        fan_speed_ratios_cooling = [0.86, 1.0]
        fan_speed_ratios_heating = [0.8, 1.0]
        fan_power_rated = 0.14
        fan_power_installed = 0.3
        min_temp = 0.0
        eer_capacity_derates = [1.0, 1.0, 1.0, 1.0, 1.0]
        cop_capacity_derates = [1.0, 1.0, 1.0, 1.0, 1.0]
        supplemental_efficiency = 1.0
        success = HVAC.apply_central_ashp_2speed(model, unit, runner, seer, hspf, eers, cops, shrs,
                                                 capacity_ratios, fan_speed_ratios_cooling,
                                                 fan_speed_ratios_heating,
                                                 fan_power_rated, fan_power_installed, min_temp,
                                                 crankcase_kw, crankcase_temp,
                                                 eer_capacity_derates, cop_capacity_derates,
                                                 cool_capacity_btuh, supplemental_efficiency,
                                                 backup_heat_capacity_btuh, dse)
        return false if not success
        
      elsif num_speeds == "Variable-Speed"
      
        eers = [0.80 * seer_nom, 0.75 * seer_nom, 0.65 * seer_nom, 0.60 * seer_nom]
        cops = [0.48 * seer_nom, 0.45 * seer_nom, 0.39 * seer_nom, 0.39 * seer_nom]
        shrs = [0.84, 0.79, 0.76, 0.77]
        capacity_ratios = [0.49, 0.67, 1.0, 1.2]
        fan_speed_ratios_cooling = [0.7, 0.9, 1.0, 1.26]
        fan_speed_ratios_heating = [0.74, 0.92, 1.0, 1.22]
        fan_power_rated = 0.14
        fan_power_installed = 0.3
        min_temp = 0.0
        eer_capacity_derates = [1.0, 1.0, 1.0, 1.0, 1.0]
        cop_capacity_derates = [1.0, 1.0, 1.0, 1.0, 1.0]
        supplemental_efficiency = 1.0
        success = HVAC.apply_central_ashp_4speed(model, unit, runner, seer, hspf, eers, cops, shrs,
                                                 capacity_ratios, fan_speed_ratios_cooling,
                                                 fan_speed_ratios_heating,
                                                 fan_power_rated, fan_power_installed, min_temp,
                                                 crankcase_kw, crankcase_temp,
                                                 eer_capacity_derates, cop_capacity_derates,
                                                 cool_capacity_btuh, supplemental_efficiency,
                                                 backup_heat_capacity_btuh, dse)
        return false if not success
        
      else
      
        fail "Unexpected number of speeds (#{num_speeds}) for heat pump system."
        
      end
      
    elsif hp_type == "mini-split"
      
      # FIXME: Generalize
      seer_nom = Float(XMLHelper.get_value(hp, "AnnualCoolingEfficiency[Units='SEER']/Value"))
      seer_adj = Float(XMLHelper.get_value(hp, "extension/PerformanceAdjustmentSEER"))
      seer = seer_nom * seer_adj
      hspf_nom = Float(XMLHelper.get_value(hp, "AnnualHeatingEfficiency[Units='HSPF']/Value"))
      hspf_adj = Float(XMLHelper.get_value(hp, "extension/PerformanceAdjustmentHSPF"))
      hspf = hspf_nom * hspf_adj
      shr = 0.73
      min_cooling_capacity = 0.4
      max_cooling_capacity = 1.2
      min_cooling_airflow_rate = 200.0
      max_cooling_airflow_rate = 425.0
      min_heating_capacity = 0.3
      max_heating_capacity = 1.2
      min_heating_airflow_rate = 200.0
      max_heating_airflow_rate = 400.0
      heating_capacity_offset = 2300.0
      cap_retention_frac = 0.25
      cap_retention_temp = -5.0
      pan_heater_power = 0.0
      fan_power = 0.07
      is_ducted = false
      supplemental_efficiency = 1.0
      success = HVAC.apply_mshp(model, unit, runner, seer, hspf, shr,
                                min_cooling_capacity, max_cooling_capacity,
                                min_cooling_airflow_rate, max_cooling_airflow_rate,
                                min_heating_capacity, max_heating_capacity,
                                min_heating_airflow_rate, max_heating_airflow_rate, 
                                heating_capacity_offset, cap_retention_frac,
                                cap_retention_temp, pan_heater_power, fan_power,
                                is_ducted, cool_capacity_btuh,
                                supplemental_efficiency, backup_heat_capacity_btuh,
                                dse)
      return false if not success
             
    elsif hp_type == "ground-to-air"
    
      # FIXME: Generalize
      cop = Float(XMLHelper.get_value(hp, "AnnualHeatingEfficiency[Units='COP']/Value"))
      eer = Float(XMLHelper.get_value(hp, "AnnualCoolingEfficiency[Units='EER']/Value"))
      shr = 0.732
      ground_conductivity = 0.6
      grout_conductivity = 0.4
      bore_config = Constants.SizingAuto
      bore_holes = Constants.SizingAuto
      bore_depth = Constants.SizingAuto
      bore_spacing = 20.0
      bore_diameter = 5.0
      pipe_size = 0.75
      ground_diffusivity = 0.0208
      fluid_type = Constants.FluidPropyleneGlycol
      frac_glycol = 0.3
      design_delta_t = 10.0
      pump_head = 50.0
      u_tube_leg_spacing = 0.9661
      u_tube_spacing_type = "b"
      fan_power = 0.5
      heat_pump_capacity = cool_capacity_btuh
      supplemental_efficiency = 1
      supplemental_capacity = backup_heat_capacity_btuh
      success = HVAC.apply_gshp(model, unit, runner, weather, cop, eer, shr,
                                ground_conductivity, grout_conductivity,
                                bore_config, bore_holes, bore_depth,
                                bore_spacing, bore_diameter, pipe_size,
                                ground_diffusivity, fluid_type, frac_glycol,
                                design_delta_t, pump_head,
                                u_tube_leg_spacing, u_tube_spacing_type,
                                fan_power, heat_pump_capacity, supplemental_efficiency,
                                supplemental_capacity, dse)
      return false if not success
             
    end
    
    return true

  end
  
  def self.add_ideal_air_loads(runner, model, unit)
    
    success = HVAC.apply_ideal_air_loads(model, unit, runner)
    return false if not success
    
    return true
  end
  
  def self.add_setpoints(runner, model, building, weather) 

    control = building.elements["BuildingDetails/Systems/HVAC/HVACControl"]
    
    # TODO: Setbacks and setups
  
    htg_sp = Float(XMLHelper.get_value(control, "SetpointTempHeatingSeason"))
    weekday_setpoints = [htg_sp]*24
    weekend_setpoints = [htg_sp]*24
    use_auto_season = false
    season_start_month = 1
    season_end_month = 12
    success = HVAC.apply_heating_setpoints(model, runner, weather, weekday_setpoints, weekend_setpoints,
                                           use_auto_season, season_start_month, season_end_month)
    return false if not success
    
    clg_sp = Float(XMLHelper.get_value(control, "SetpointTempCoolingSeason"))
    weekday_setpoints = [clg_sp]*24
    weekend_setpoints = [clg_sp]*24
    use_auto_season = false
    season_start_month = 1
    season_end_month = 12
    success = HVAC.apply_cooling_setpoints(model, runner, weather, weekday_setpoints, weekend_setpoints,
                                           use_auto_season, season_start_month, season_end_month)
    return false if not success

    return true
    
  end

  def self.add_dehumidifier(runner, model, building, unit)
  
    dehumidifier = building.elements["BuildingDetails/Systems/HVAC/extension/dehumidifier"]
    return true if dehumidifier.nil?
    
    energy_factor = XMLHelper.get_value(dehumidifier, "energy_factor")
    water_removal_rate = XMLHelper.get_value(dehumidifier, "water_removal_rate")
    air_flow_rate = XMLHelper.get_value(dehumidifier, "air_flow_rate")
    humidity_setpoint = XMLHelper.get_value(dehumidifier, "humidity_setpoint")
    success = HVAC.apply_dehumidifier(model, unit, runner, energy_factor, 
                                      water_removal_rate, air_flow_rate, humidity_setpoint)
    return false if not success
  
    return true
    
  end
  
  def self.add_ceiling_fans(runner, model, building, unit)

    # FIXME
    cf = building.elements["BuildingDetails/Lighting/CeilingFan"]
    coverage = nil
    specified_num = nil
    power = nil
    control = nil
    use_benchmark_energy = true
    mult = 1.0
    cooling_setpoint_offset = 0.0
    weekday_sch = "0.04, 0.037, 0.037, 0.036, 0.033, 0.036, 0.043, 0.047, 0.034, 0.023, 0.024, 0.025, 0.024, 0.028, 0.031, 0.032, 0.039, 0.053, 0.063, 0.067, 0.071, 0.069, 0.059, 0.05"
    weekend_sch = "0.04, 0.037, 0.037, 0.036, 0.033, 0.036, 0.043, 0.047, 0.034, 0.023, 0.024, 0.025, 0.024, 0.028, 0.031, 0.032, 0.039, 0.053, 0.063, 0.067, 0.071, 0.069, 0.059, 0.05"
    monthly_sch = "1.248, 1.257, 0.993, 0.989, 0.993, 0.827, 0.821, 0.821, 0.827, 0.99, 0.987, 1.248"
    #success = HVAC.apply_ceiling_fans(model, unit, runner, coverage, specified_num, power,
    #                                  control, use_benchmark_energy, cooling_setpoint_offset,
    #                                  mult, weekday_sch, weekend_sch, monthly_sch, sch=nil)
    #return false if not success

    return true
  end
  
  def self.get_dse(building)
    dse_cool = XMLHelper.get_value(building, "BuildingDetails/Systems/HVAC/HVACDistribution/AnnualCoolingDistributionSystemEfficiency")
    dse_heat = XMLHelper.get_value(building, "BuildingDetails/Systems/HVAC/HVACDistribution/AnnualHeatingDistributionSystemEfficiency")
    if dse_cool.nil? and dse_heat.nil?
      dse_cool = 1.0
      dse_heat = 1.0
    elsif not dse_cool.nil? and not dse_heat.nil?
      dse_cool = Float(dse_cool)
      dse_heat = Float(dse_heat)
    end
    if dse_cool != dse_heat
      fail "Cannot handle different distribution system efficiency (DSE) values for heating and cooling."
    end
    return dse_cool
  end
  
  def self.to_beopt_fuel(fuel)
    conv = {"natural gas"=>Constants.FuelTypeGas, 
            "fuel oil"=>Constants.FuelTypeOil, 
            "propane"=>Constants.FuelTypePropane, 
            "electricity"=>Constants.FuelTypeElectric}
    return conv[fuel]
  end
  
  def self.add_mels(runner, model, building, unit, living_space)
  
    # Misc
    annual_kwh = Float(XMLHelper.get_value(building, "BuildingDetails/MiscLoads/PlugLoad[PlugLoadType='other']/Load[Units='kWh/year']/Value"))
    sens_frac = Float(XMLHelper.get_value(building, "BuildingDetails/MiscLoads/PlugLoad[PlugLoadType='other']/extension/FracSensible"))
    lat_frac = Float(XMLHelper.get_value(building, "BuildingDetails/MiscLoads/PlugLoad[PlugLoadType='other']/extension/FracLatent"))
    weekday_sch = XMLHelper.get_value(building, "BuildingDetails/MiscLoads/PlugLoad[PlugLoadType='other']/extension/WeekdayScheduleFractions")
    weekend_sch = XMLHelper.get_value(building, "BuildingDetails/MiscLoads/PlugLoad[PlugLoadType='other']/extension/WeekendScheduleFractions")
    monthly_sch = XMLHelper.get_value(building, "BuildingDetails/MiscLoads/PlugLoad[PlugLoadType='other']/extension/MonthlyScheduleMultipliers")
    success, sch = MiscLoads.apply_plug(model, unit, runner, annual_kwh, 
                                        sens_frac, lat_frac, weekday_sch, 
                                        weekend_sch, monthly_sch, nil)
    return false if not success
    
    # Television
    if not building.elements["BuildingDetails/MiscLoads/PlugLoad[PlugLoadType='TV other']/Load[Units='kWh/year']/Value"].nil?
      annual_kwh = Float(XMLHelper.get_value(building, "BuildingDetails/MiscLoads/PlugLoad[PlugLoadType='TV other']/Load[Units='kWh/year']/Value"))
      success = MiscLoads.apply_tv(model, unit, runner, annual_kwh, sch, living_space)
      return false if not success
    end
    
    return true
  
  end  
  
  def self.add_lighting(runner, model, building, unit, weather)
  
    lighting = building.elements["BuildingDetails/Lighting"]
  
    annual_kwh_interior = Float(XMLHelper.get_value(lighting, "extension/AnnualInteriorkWh"))
    success, sch = Lighting.apply_interior(model, unit, runner, weather, 
                                                    nil, annual_kwh_interior)
    return false if not success
    
    annual_kwh_garage = Float(XMLHelper.get_value(lighting, "extension/AnnualGaragekWh"))
    success = Lighting.apply_garage(model, runner, sch, annual_kwh_garage)
    return false if not success

    annual_kwh_exterior = Float(XMLHelper.get_value(lighting, "extension/AnnualExteriorkWh"))
    success = Lighting.apply_exterior(model, runner, sch, annual_kwh_exterior)
    return false if not success
    
    return true
  end
  
  def self.add_airflow(runner, model, building, unit, weather)
  
    # Infiltration
    infiltration = building.elements["BuildingDetails/Enclosure/AirInfiltration"]
    if infiltration.elements["AirInfiltrationMeasurement[HousePressure='50']/BuildingAirLeakage[UnitofMeasure='ACH']/AirLeakage"]
      # ACH50
      infil_ach50 = Float(XMLHelper.get_value(infiltration, "AirInfiltrationMeasurement[HousePressure='50']/BuildingAirLeakage[UnitofMeasure='ACH']/AirLeakage"))
      infil_const_ach = nil
    elsif infiltration.elements["AirInfiltrationMeasurement/BuildingAirLeakage[UnitofMeasure='ACHnatural']/AirLeakage"]
      # nACH
      infil_nach = Float(XMLHelper.get_value(infiltration, "AirInfiltrationMeasurement/BuildingAirLeakage[UnitofMeasure='ACHnatural']/AirLeakage"))
      # Convert to ACH50
      ncfl_ag = Float(XMLHelper.get_value(building, "BuildingDetails/BuildingSummary/BuildingConstruction/NumberofConditionedFloorsAboveGrade"))
      cfa = Float(XMLHelper.get_value(building, "BuildingDetails/BuildingSummary/BuildingConstruction/ConditionedFloorArea"))
      cvolume = Float(XMLHelper.get_value(building, "BuildingDetails/BuildingSummary/BuildingConstruction/ConditionedBuildingVolume"))
      infil_sla = Airflow.get_infiltration_SLA_from_ACH(infil_nach, ncfl_ag, weather)
      infil_ach50 = Airflow.get_infiltration_ACH50_from_SLA(infil_sla, 0.67, cfa, cvolume)
      infil_const_ach = nil
    elsif infiltration.elements["extension/BuildingConstantACHnatural"]
      # Constant nACH
      infil_const_ach = Float(XMLHelper.get_value(infiltration, "extension/BuildingConstantACHnatural"))
      infil_ach50 = nil
    end
    
    # Vented crawl SLA
    vented_crawl_sum_area = 0.0
    vented_crawl_sum_sla_area = 0.0
    building.elements.each("BuildingDetails/Enclosure/Foundations/Foundation[FoundationType/Crawlspace[Vented='true']]") do |vented_crawl|
      area = REXML::XPath.first(vented_crawl, "sum(FrameFloor/Area/text())")
      vented_crawl_sum_sla_area += (Float(XMLHelper.get_value(vented_crawl, "extension/CrawlspaceSpecificLeakageArea")) * area)
      vented_crawl_sum_area += area
    end
    if vented_crawl_sum_area > 0
      crawl_sla = vented_crawl_sum_sla_area / vented_crawl_sum_area
    else
      crawl_sla = 0.0
    end
    
    # Vented attic SLA
    vented_attic_sum_area = 0.0
    vented_attic_sum_sla_area = 0.0
    vented_attic_sum_ach_area = 0.0
    building.elements.each("BuildingDetails/Enclosure/AtticAndRoof/Attics/Attic[AtticType='vented attic']") do |vented_attic|
      area = REXML::XPath.first(vented_attic, "sum(Floors/Floor/Area/text())")
      if XMLHelper.has_element(vented_attic, "extension/AtticSpecificLeakageArea")
        vented_attic_sum_sla_area += (Float(XMLHelper.get_value(vented_attic, "extension/AtticSpecificLeakageArea")) * area)
      else
        vented_attic_sum_ach_area += (Float(XMLHelper.get_value(vented_attic, "extension/AtticConstantACHnatural")) * area)
      end
      vented_attic_sum_area += area
    end
    if vented_attic_sum_sla_area > 0
      attic_sla = vented_attic_sum_sla_area / vented_attic_sum_area
      attic_const_ach = nil
    elsif vented_attic_sum_ach_area > 0
      attic_const_ach = vented_attic_sum_ach_area / vented_attic_sum_area
      attic_sla = nil
    else
      attic_sla = 0.0
      attic_const_ach = nil
    end
    
    living_ach50 = infil_ach50
    garage_ach50 = infil_ach50
    finished_basement_ach = 0 # TODO: Need to handle above-grade basement
    unfinished_basement_ach = 0.1 # TODO: Need to handle above-grade basement
    crawl_ach = crawl_sla # FIXME: sla vs ach
    pier_beam_ach = 100
    shelter_coef = Constants.Auto
    has_flue_chimney = false
    is_existing_home = false
    terrain = Constants.TerrainSuburban
    infil = Infiltration.new(living_ach50, infil_const_ach, shelter_coef, garage_ach50, crawl_ach, attic_sla, attic_const_ach,
                             unfinished_basement_ach, finished_basement_ach, pier_beam_ach, has_flue_chimney, is_existing_home, terrain)

    # Mechanical Ventilation
    whole_house_fan = building.elements["BuildingDetails/Systems/MechanicalVentilation/VentilationFans/VentilationFan[UsedForWholeBuildingVentilation='true']"]
    if whole_house_fan.nil?
      mech_vent_type = Constants.VentTypeNone
      mech_vent_total_efficiency = 0.0
      mech_vent_sensible_efficiency = 0.0
      mech_vent_fan_power = 0.0
      mech_vent_cfm = 0.0
    else
      # FIXME: HoursInOperation isn't being used
      fan_type = XMLHelper.get_value(whole_house_fan, "FanType")
      if fan_type == "supply only"
        mech_vent_type = Constants.VentTypeSupply
      elsif fan_type == "exhaust only"
        mech_vent_type = Constants.VentTypeExhaust
      else
        mech_vent_type = Constants.VentTypeBalanced
      end
      mech_vent_total_efficiency = 0.0
      mech_vent_sensible_efficiency = 0.0
      if fan_type == "energy recovery ventilator" or fan_type == "heat recovery ventilator"
        mech_vent_sensible_efficiency = Float(XMLHelper.get_value(whole_house_fan, "SensibleRecoveryEfficiency"))
      end
      if fan_type == "energy recovery ventilator"
        mech_vent_total_efficiency = Float(XMLHelper.get_value(whole_house_fan, "TotalRecoveryEfficiency"))
      end
      mech_vent_cfm = Float(XMLHelper.get_value(whole_house_fan, "RatedFlowRate"))
      mech_vent_w = Float(XMLHelper.get_value(whole_house_fan, "FanPower"))
      mech_vent_fan_power = mech_vent_w/mech_vent_cfm
    end
    mech_vent_ashrae_std = '2013'
    mech_vent_infil_credit = true
    mech_vent_cfis_open_time = 20.0
    mech_vent_cfis_airflow_frac = 1.0
    clothes_dryer_exhaust = 0.0
    range_exhaust = 0.0
    range_exhaust_hour = 16
    bathroom_exhaust = 0.0
    bathroom_exhaust_hour = 5
    mech_vent = MechanicalVentilation.new(mech_vent_type, mech_vent_infil_credit, mech_vent_total_efficiency, 
                                          nil, mech_vent_cfm, mech_vent_fan_power, mech_vent_sensible_efficiency, 
                                          mech_vent_ashrae_std, mech_vent_cfis_open_time, mech_vent_cfis_airflow_frac, 
                                          clothes_dryer_exhaust, range_exhaust, range_exhaust_hour, bathroom_exhaust, 
                                          bathroom_exhaust_hour)

    # Natural Ventilation
    sum_window_area = 0.0
    sum_window_area_openable = 0.0
    building.elements.each("BuildingDetails/Enclosure/Windows/Window") do |window|
      window_area = Float(XMLHelper.get_value(window, "Area"))
      window_openable = XMLHelper.get_value(window, "Operable")
      if window_openable.nil? or Boolean(window_openable)
        sum_window_area_openable += window_area * 0.2
      end
      sum_window_area += window_area
    end
    nat_vent_htg_offset = 1.0
    nat_vent_clg_offset = 1.0
    nat_vent_ovlp_offset = 1.0
    nat_vent_htg_season = true
    nat_vent_clg_season = true
    nat_vent_ovlp_season = true
    nat_vent_num_weekdays = 5
    nat_vent_num_weekends = 2
    nat_vent_frac_windows_open = 0.33
    if sum_window_area > 0
      nat_vent_frac_window_area_openable = sum_window_area_openable / sum_window_area
    else
      nat_vent_frac_window_area_openable = 0.0
    end
    nat_vent_max_oa_hr = 0.0115
    nat_vent_max_oa_rh = 0.7
    nat_vent = NaturalVentilation.new(nat_vent_htg_offset, nat_vent_clg_offset, nat_vent_ovlp_offset, nat_vent_htg_season,
                                      nat_vent_clg_season, nat_vent_ovlp_season, nat_vent_num_weekdays, 
                                      nat_vent_num_weekends, nat_vent_frac_windows_open, nat_vent_frac_window_area_openable, 
                                      nat_vent_max_oa_hr, nat_vent_max_oa_rh)
  
    # Ducts
    hvac_distribution = building.elements["BuildingDetails/Systems/HVAC/HVACDistribution"]
    air_distribution = nil
    if not hvac_distribution.nil?
      air_distribution = hvac_distribution.elements["DistributionSystemType/AirDistribution"]
    end
    if not air_distribution.nil?
      # Ducts
      supply_cfm25 = Float(XMLHelper.get_value(air_distribution, "DuctLeakageMeasurement[DuctType='supply']/DuctLeakage[Units='CFM25' and TotalOrToOutside='to outside']/Value"))
      return_cfm25 = Float(XMLHelper.get_value(air_distribution, "DuctLeakageMeasurement[DuctType='return']/DuctLeakage[Units='CFM25' and TotalOrToOutside='to outside']/Value"))
      supply_r = Float(XMLHelper.get_value(air_distribution, "Ducts[DuctType='supply']/DuctInsulationRValue"))
      return_r = Float(XMLHelper.get_value(air_distribution, "Ducts[DuctType='return']/DuctInsulationRValue"))
      supply_area = Float(XMLHelper.get_value(air_distribution, "Ducts[DuctType='supply']/DuctSurfaceArea"))
      return_area = Float(XMLHelper.get_value(air_distribution, "Ducts[DuctType='return']/DuctSurfaceArea"))
      # FIXME: Values below
      duct_location = Constants.Auto
      duct_total_leakage = 0.3
      duct_supply_frac = 0.6
      duct_return_frac = 0.067
      duct_ah_supply_frac = 0.067
      duct_ah_return_frac = 0.267
      duct_location_frac = Constants.Auto
      duct_num_returns = 1
      duct_supply_area_mult = 1.0
      duct_return_area_mult = 1.0
      duct_r = 4.0
    else
      duct_location = "none"
      duct_total_leakage = 0.0
      duct_supply_frac = 0.0
      duct_return_frac = 0.0
      duct_ah_supply_frac = 0.0
      duct_ah_return_frac = 0.0
      duct_location_frac = Constants.Auto
      duct_num_returns = Constants.Auto
      duct_supply_area_mult = 1.0
      duct_return_area_mult = 1.0
      duct_r = 0.0
    end
    duct_norm_leakage_25pa = nil
    ducts = Ducts.new(duct_total_leakage, duct_norm_leakage_25pa, duct_supply_area_mult, duct_return_area_mult, duct_r, 
                      duct_supply_frac, duct_return_frac, duct_ah_supply_frac, duct_ah_return_frac, duct_location_frac, 
                      duct_num_returns, duct_location)

    success = Airflow.apply(model, runner, infil, mech_vent, nat_vent, ducts, File.dirname(__FILE__))
    return false if not success
    
    return true
    
  end
  
  def self.add_hvac_sizing(runner, model, unit, weather)
    
    success = HVACSizing.apply(model, unit, runner, weather, false)
    return false if not success
    
    return true

  end
  
  def self.add_photovoltaics(runner, model, building)

    return true if building.elements["BuildingDetails/Systems/Photovoltaics/PVSystem"].nil?
  
    building.elements.each("BuildingDetails/Systems/Photovoltaics/PVSystem") do |pvsys|
    
      pv_id = pvsys.elements["SystemIdentifier"].attributes["id"]
      az = Float(XMLHelper.get_value(pvsys, "ArrayAzimuth"))
      tilt = Float(XMLHelper.get_value(pvsys, "ArrayTilt"))
      inv_eff = Float(XMLHelper.get_value(pvsys, "InverterEfficiency"))
      power_w = Float(XMLHelper.get_value(pvsys, "MaxPowerOutput"))
      
      # FIXME: Need to double-check azimuth/tilt inputs
      module_type = Constants.PVModuleTypeStandard
      system_losses = 0.14
      success = PV.apply(model, runner, pv_id, power_w, module_type, 
                         system_losses, inv_eff, tilt, az)
      return false if not success
      
    end
      
    return true
  end
  
  def self.check_surface_assembly_rvalue(surface, film_r, assembly_r)
    constr_r = UnitConversions.convert(1.0 / surface.construction.get.uFactor(0.0).get,'m^2*k/w','hr*ft^2*f/btu') + film_r
    
    if surface.adjacentFoundation.is_initialized
      foundation = surface.adjacentFoundation.get
      if foundation.interiorVerticalInsulationMaterial.is_initialized
        int_mat = foundation.interiorVerticalInsulationMaterial.get.to_StandardOpaqueMaterial.get
        constr_r += UnitConversions.convert(int_mat.thickness,"m","ft")/UnitConversions.convert(int_mat.thermalConductivity,"W/(m*K)","Btu/(hr*ft*R)")
      end
      if foundation.exteriorVerticalInsulationMaterial.is_initialized
        ext_mat = foundation.exteriorVerticalInsulationMaterial.get.to_StandardOpaqueMaterial.get
        constr_r += UnitConversions.convert(ext_mat.thickness,"m","ft")/UnitConversions.convert(ext_mat.thermalConductivity,"W/(m*K)","Btu/(hr*ft*R)")
      end
    end
    
    if (assembly_r - constr_r).abs > 0.01
      fail "Construction R-value does not match Assembly R-value for #{surface.name.to_s}."
    end

  end
  
end
