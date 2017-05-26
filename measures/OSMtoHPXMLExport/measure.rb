# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/reference/measure_writing_guide/

require 'rexml/document'

require "#{File.dirname(__FILE__)}/resources/xmlhelper"
require "#{File.dirname(__FILE__)}/resources/constants"
require "#{File.dirname(__FILE__)}/resources/geometry"
require "#{File.dirname(__FILE__)}/resources/hvac"

# start the measure
class OSMtoHPXMLExport < OpenStudio::Measure::ModelMeasure

  # human readable name
  def name
    return "OSM to HPXML Export"
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

    arg = OpenStudio::Measure::OSArgument.makeStringArgument("osm_file_path", true)
    arg.setDisplayName("OSM File Path")
    arg.setDescription("Absolute (or relative) path of the OSM file.")
    args << arg

    arg = OpenStudio::Measure::OSArgument.makeStringArgument("schemas_dir", true)
    arg.setDisplayName("HPXML Schemas Directory")
    arg.setDescription("Absolute path of the hpxml schemas.")
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

    osm_file_path = runner.getStringArgumentValue("osm_file_path", user_arguments)
    schemas_dir = runner.getStringArgumentValue("schemas_dir", user_arguments)
    
    unless (Pathname.new osm_file_path).absolute?
      osm_file_path = File.expand_path(File.join(File.dirname(__FILE__), osm_file_path))
    end 
    unless File.exists?(osm_file_path) and osm_file_path.downcase.end_with? ".osm"
      runner.registerError("'#{osm_file_path}' does not exist or is not an .osm file.")
      return false
    end
    
    unless (Pathname.new schemas_dir).absolute?
      schemas_dir = File.expand_path(File.join(File.dirname(__FILE__), schemas_dir))
    end
    unless Dir.exists?(schemas_dir)
      runner.registerError("'#{schemas_dir}' does not exist.")
      return false
    end
    
    translator = OpenStudio::OSVersion::VersionTranslator.new
    path = OpenStudio::Path.new(osm_file_path)
    model = translator.loadModel(path)
    model = model.get
    
    doc = REXML::Document.new

    root = doc.add_element "HPXML", {"schemaVersion"=>"2.2"}
    root.add_namespace("http://hpxmlonline.com/2014/6")
    # root.add_namespace("xsi", "http://www.w3.org/2001/XMLSchema-instance")
    
    xml_transaction_header_information = root.add_element "XMLTransactionHeaderInformation"
    xml_transaction_header_information.add_element("XMLType")
    xml_transaction_header_information.add_element("XMLGeneratedBy").add_text(File.basename(File.dirname(__FILE__)))
    xml_transaction_header_information.add_element("CreatedDateAndTime").add_text(Time.now.strftime('%Y-%m-%dT%H:%M:%S'))
    xml_transaction_header_information.add_element("Transaction").add_text("create")
    
    software_info = root.add_element "SoftwareInfo"
    software_info.add_element("SoftwareProgramUsed").add_text("OpenStudio")
    software_info.add_element("SoftwareProgramVersion").add_text(model.getVersion.versionIdentifier)
    
    building = root.add_element "Building"
    XMLHelper.add_attribute(building.add_element("BuildingID"), "id", model.getBuilding.name)
    project_status = building.add_element "ProjectStatus"
    project_status.add_element("EventType").add_text("audit")
    building_details = building.add_element "BuildingDetails"
    building_summary = building_details.add_element "BuildingSummary"
    building_occupancy = building_summary.add_element "BuildingOccupancy"
    num_people = 0
    model.getPeopleDefinitions.each do |people_def|
      num_people += people_def.numberofPeople.get
    end
    building_occupancy.add_element("NumberofResidents").add_text(num_people.round.to_s)    
    building_construction = building_summary.add_element "BuildingConstruction"
    building_construction.add_element("ResidentialFacilityType").add_text({Constants.BuildingTypeSingleFamilyDetached=>"single-family detached"}[model.getBuilding.standardsBuildingType.to_s])
    building_construction.add_element("NumberofUnits").add_text(model.getBuilding.standardsNumberOfLivingUnits.to_s)
    model.getBuildingUnits.each do |unit|
      if unit.getFeatureAsInteger("NumberOfBedrooms").is_initialized
        building_construction.add_element("NumberofBedrooms").add_text(unit.getFeatureAsInteger("NumberOfBedrooms").get.to_s)
      end
      if unit.getFeatureAsDouble("NumberOfBathrooms").is_initialized
        building_construction.add_element("NumberofBathrooms").add_text(unit.getFeatureAsDouble("NumberOfBathrooms").get.to_i.to_s)
      end
      building_construction.add_element("ConditionedFloorArea").add_text(Geometry.get_above_grade_finished_floor_area_from_spaces(unit.spaces).round.to_s)
      building_construction.add_element("FinishedFloorArea").add_text(Geometry.get_above_grade_finished_floor_area_from_spaces(unit.spaces).round.to_s)
      building_construction.add_element("NumberofStoriesAboveGrade").add_text(Geometry.get_building_stories(unit.spaces).to_s)
      building_construction.add_element("ConditionedBuildingVolume").add_text(Geometry.get_finished_volume_from_spaces(unit.spaces).round.to_s)
    end
    
    # ClimateandRiskZones
    if model.getSite.weatherFile.is_initialized
      # climate_and_risk_zones = building_details.add_element "ClimateandRiskZones"
      # weather_station = climate_and_risk_zones.add_element "WeatherStation"
      # XMLHelper.add_attribute(weather_station.add_element("SystemIdentifiersInfo"), "id", "weather_station")
      # XMLHelper.add_element(weather_station, "Name", File.basename(model.getSite.weatherFile.get.file.get.path.to_s))
      # XMLHelper.add_element(weather_station, "City", model.getSite.weatherFile.get.city.to_s)
      # XMLHelper.add_element(weather_station, "State", model.getSite.weatherFile.get.stateProvinceRegion.to_s)
      # XMLHelper.add_element(weather_station, "WBAN", model.getSite.weatherFile.get.file.get.wmoNumber.to_s)
    end
    
    # Zones
    zones = building_details.add_element "Zones"
    model.getThermalZones.each do |thermal_zone|
      zone = zones.add_element "Zone"
      XMLHelper.add_attribute(zone.add_element("SystemIdentifier"), "id", thermal_zone.name)
      if thermal_zone.thermostat.is_initialized or thermal_zone.thermostatSetpointDualSetpoint.is_initialized
        XMLHelper.add_element(zone, "ZoneType", "conditioned")
      else
        XMLHelper.add_element(zone, "ZoneType", "unconditioned")
      end
      spaces = zone.add_element "Spaces"
      thermal_zone.spaces.each do |sp|
        space = spaces.add_element "Space"
        XMLHelper.add_attribute(space.add_element("SystemIdentifier"), "id", sp.name)
        XMLHelper.add_element(space, "FloorArea", OpenStudio.convert(sp.floorArea,"m^2","ft^2").get.round)
        XMLHelper.add_element(space, "Volume", Geometry.get_volume_from_spaces([sp]).round.to_s)
      end
    end

    # Enclosure
    enclosure = building_details.add_element "Enclosure"
    
    # AirInfiltration
    air_infiltration = enclosure.add_element "AirInfiltration"
    model.getBuildingUnits.each do |unit|
      unit_thermal_zones = Geometry.get_thermal_zones_from_spaces(unit.spaces)
      control_slave_zones_hash = HVAC.get_control_and_slave_zones(unit_thermal_zones)
      control_zone = control_slave_zones_hash.keys[0]
      air_infiltration_measurement = air_infiltration.add_element "AirInfiltrationMeasurement"    
      XMLHelper.add_attribute(air_infiltration_measurement.add_element("SystemIdentifier"), "id", "air_infiltration")
      if unit.getFeatureAsDouble(Constants.SizingInfoZoneInfiltrationELA(control_zone)).is_initialized
        XMLHelper.add_element(air_infiltration_measurement, "EffectiveLeakageArea", unit.getFeatureAsDouble(Constants.SizingInfoZoneInfiltrationELA(control_zone)).get.round(5).to_s)
      end
    end
    
    # Roofs
    attic_and_roof = enclosure.add_element "AtticAndRoof"
    roofs = attic_and_roof.add_element "Roofs"
    model.getSurfaces.each do |surface|
      next unless surface.surfaceType.downcase == "roofceiling"
      next unless surface.outsideBoundaryCondition.downcase == "outdoors"
      roof = roofs.add_element "Roof"
      XMLHelper.add_attribute(roof.add_element("SystemIdentifier"), "id", surface.name)
      roof.add_element("RoofArea").add_text(OpenStudio.convert(surface.grossArea,"m^2","ft^2").get.round.to_s)
    end    
    
    # Foundations
    foundations = enclosure.add_element "Foundations"
    
    # Slab
    model.getSpaces.each do |space|
      if Geometry.space_is_above_grade(space) and Geometry.space_is_finished(space)
        slab_on_grade = nil
        space.surfaces.each do |surface|
          next unless surface.surfaceType.downcase == "floor"
          next unless surface.outsideBoundaryCondition.downcase == "ground"
          if slab_on_grade.nil?
            foundation = foundations.add_element "Foundation"
            XMLHelper.add_attribute(foundation.add_element("SystemIdentifier"), "id", "foundation #{space.name}")
            foundation_type = foundation.add_element "FoundationType"
            slab_on_grade = foundation_type.add_element "SlabOnGrade"
          end
          slab = foundation.add_element "Slab"
          XMLHelper.add_attribute(slab.add_element("SystemIdentifier"), "id", surface.name)
          slab.add_element("Area").add_text(OpenStudio.convert(surface.grossArea,"m^2","ft^2").get.round.to_s)
          if surface.construction.is_initialized
            surface.construction.get.to_LayeredConstruction.get.layers.each do |layer|
              next unless layer.name.to_s.downcase.include? "slabmass"
            end
          end
          l, w, h = Geometry.get_surface_dimensions(surface)
          slab.add_element("ExposedPerimeter").add_text(OpenStudio.convert(2*w+2*l,"m","ft").get.round(1).to_s)
        end
      end
    end
    
    # Finished Basement
    model.getSpaces.each do |space|
      if Geometry.is_finished_basement(space)
        foundation = foundations.add_element "Foundation"
        XMLHelper.add_attribute(foundation.add_element("SystemIdentifier"), "id", "foundaiton #{space.name}")
        foundation_type = foundation.add_element "FoundationType"
        basement = foundation_type.add_element "Basement"
        basement.add_element("Finished").add_text("true")
        space.surfaces.each do |surface|
          if surface.surfaceType.downcase == "roofceiling"
            frame_floor = foundation.add_element "FrameFloor"
            XMLHelper.add_attribute(frame_floor.add_element("SystemIdentifier"), "id", surface.name)
            frame_floor.add_element("Area").add_text(OpenStudio.convert(surface.grossArea,"m^2","ft^2").get.round.to_s)
          end
        end
        space.surfaces.each do |surface|
          if surface.surfaceType.downcase == "wall"
            foundation_wall = foundation.add_element "FoundationWall"
            XMLHelper.add_attribute(foundation_wall.add_element("SystemIdentifier"), "id", surface.name)
            l, w, h = Geometry.get_surface_dimensions(surface)
            foundation_wall.add_element("Length").add_text(OpenStudio.convert([l, w].max,"m","ft").get.round(1).to_s)
            foundation_wall.add_element("Height").add_text(OpenStudio.convert(h,"m","ft").get.round(1).to_s)
            foundation_wall.add_element("Area").add_text(OpenStudio.convert(surface.grossArea,"m^2","ft^2").get.round.to_s)
            if surface.construction.is_initialized
              thickness = 0
              surface.construction.get.to_LayeredConstruction.get.layers.each do |layer|
                next if layer.name.to_s.downcase.include? "soil"
                thickness += OpenStudio.convert(layer.thickness,"m","in").get
              end
              foundation_wall.add_element("Thickness").add_text(thickness.round(1).to_s)
            end
            foundation_wall.add_element("BelowGradeDepth").add_text((Geometry.getSurfaceZValues([surface]).min + Geometry.get_z_origin_for_zone(space.thermalZone.get)).abs.round(1).to_s)
          end
        end
        space.surfaces.each do |surface|
          if surface.surfaceType.downcase == "floor"
            slab = foundation.add_element "Slab"
            XMLHelper.add_attribute(slab.add_element("SystemIdentifier"), "id", surface.name)
            slab.add_element("Area").add_text(OpenStudio.convert(surface.grossArea,"m^2","ft^2").get.round.to_s)
            l, w, h = Geometry.get_surface_dimensions(surface)
            slab.add_element("ExposedPerimeter").add_text(OpenStudio.convert(2*w+2*l,"m","ft").get.round(1).to_s)
            slab.add_element("DepthBelowGrade").add_text((Geometry.get_space_floor_z(space) + Geometry.get_z_origin_for_zone(space.thermalZone.get)).abs.round(1).to_s)
          end
        end
      end
    end
    
    # Unfinished Basement
    model.getSpaces.each do |space|
      if Geometry.is_unfinished_basement(space)
        foundation = foundations.add_element "Foundation"
        XMLHelper.add_attribute(foundation.add_element("SystemIdentifier"), "id", "foundation #{space.name}")
        foundation_type = foundation.add_element "FoundationType"
        basement = foundation_type.add_element "Basement"
        basement.add_element("Finished").add_text("false")
        space.surfaces.each do |surface|
          if surface.surfaceType.downcase == "roofceiling"
            frame_floor = foundation.add_element "FrameFloor"
            XMLHelper.add_attribute(frame_floor.add_element("SystemIdentifier"), "id", surface.name)
            frame_floor.add_element("Area").add_text(OpenStudio.convert(surface.grossArea,"m^2","ft^2").get.round.to_s)
          end
        end
        space.surfaces.each do |surface|
          if surface.surfaceType.downcase == "wall"
            foundation_wall = foundation.add_element "FoundationWall"
            XMLHelper.add_attribute(foundation_wall.add_element("SystemIdentifier"), "id", surface.name)
            l, w, h = Geometry.get_surface_dimensions(surface)
            foundation_wall.add_element("Length").add_text(OpenStudio.convert([l, w].max,"m","ft").get.round(1).to_s)
            foundation_wall.add_element("Height").add_text(OpenStudio.convert(h,"m","ft").get.round(1).to_s)
            foundation_wall.add_element("Area").add_text(OpenStudio.convert(surface.grossArea,"m^2","ft^2").get.round.to_s)
            if surface.construction.is_initialized
              thickness = 0
              surface.construction.get.to_LayeredConstruction.get.layers.each do |layer|
                next if layer.name.to_s.downcase.include? "soil"
                thickness += OpenStudio.convert(layer.thickness,"m","in").get
              end
              foundation_wall.add_element("Thickness").add_text(thickness.round(1).to_s)
            end
            foundation_wall.add_element("BelowGradeDepth").add_text((Geometry.getSurfaceZValues([surface]).min + Geometry.get_z_origin_for_zone(space.thermalZone.get)).abs.round(1).to_s)
          end
        end
        space.surfaces.each do |surface|
          if surface.surfaceType.downcase == "floor"
            slab = foundation.add_element "Slab"
            XMLHelper.add_attribute(slab.add_element("SystemIdentifier"), "id", surface.name)
            slab.add_element("Area").add_text(OpenStudio.convert(surface.grossArea,"m^2","ft^2").get.round.to_s)
            l, w, h = Geometry.get_surface_dimensions(surface)
            slab.add_element("ExposedPerimeter").add_text(OpenStudio.convert(2*w+2*l,"m","ft").get.round(1).to_s)
            slab.add_element("DepthBelowGrade").add_text((Geometry.get_space_floor_z(space) + Geometry.get_z_origin_for_zone(space.thermalZone.get)).abs.round(1).to_s)
          end
        end
      end
    end

    # Crawlspace
    model.getSpaces.each do |space|
      if Geometry.is_crawl(space)
        foundation = foundations.add_element "Foundation"
        XMLHelper.add_attribute(foundation.add_element("SystemIdentifier"), "id", "foundation #{space.name}")
        foundation_type = foundation.add_element "FoundationType"
        crawl = foundation_type.add_element "Crawlspace"
        model.getBuildingUnits.each do |unit|
          if unit.getFeatureAsDouble(Constants.SizingInfoZoneInfiltrationCFM(space.thermalZone.get)).get.to_f == 0
            crawl.add_element("Vented").add_text("false")
          else
            crawl.add_element("Vented").add_text("true")
          end
        end
        space.surfaces.each do |surface|
          if surface.surfaceType.downcase == "roofceiling"
            frame_floor = foundation.add_element "FrameFloor"
            XMLHelper.add_attribute(frame_floor.add_element("SystemIdentifier"), "id", surface.name)
            frame_floor.add_element("Area").add_text(OpenStudio.convert(surface.grossArea,"m^2","ft^2").get.round.to_s)
          end
        end
        space.surfaces.each do |surface|
          if surface.surfaceType.downcase == "wall"
            foundation_wall = foundation.add_element "FoundationWall"
            XMLHelper.add_attribute(foundation_wall.add_element("SystemIdentifier"), "id", surface.name)
            l, w, h = Geometry.get_surface_dimensions(surface)
            foundation_wall.add_element("Length").add_text(OpenStudio.convert([l, w].max,"m","ft").get.round(1).to_s)
            foundation_wall.add_element("Height").add_text(OpenStudio.convert(h,"m","ft").get.round(1).to_s)
            foundation_wall.add_element("Area").add_text(OpenStudio.convert(surface.grossArea,"m^2","ft^2").get.round.to_s)
            if surface.construction.is_initialized
              thickness = 0
              surface.construction.get.to_LayeredConstruction.get.layers.each do |layer|
                next if layer.name.to_s.downcase.include? "soil"
                thickness += OpenStudio.convert(layer.thickness,"m","in").get
              end
              foundation_wall.add_element("Thickness").add_text(thickness.round(1).to_s)
            end
            foundation_wall.add_element("BelowGradeDepth").add_text((Geometry.getSurfaceZValues([surface]).min + Geometry.get_z_origin_for_zone(space.thermalZone.get)).abs.round(1).to_s)
          end
        end
        space.surfaces.each do |surface|
          if surface.surfaceType.downcase == "floor"
            slab = foundation.add_element "Slab"
            XMLHelper.add_attribute(slab.add_element("SystemIdentifier"), "id", surface.name)
            slab.add_element("Area").add_text(OpenStudio.convert(surface.grossArea,"m^2","ft^2").get.round.to_s)
            l, w, h = Geometry.get_surface_dimensions(surface)
            slab.add_element("ExposedPerimeter").add_text(OpenStudio.convert(2*w+2*l,"m","ft").get.round(1).to_s)
            slab.add_element("DepthBelowGrade").add_text((Geometry.get_space_floor_z(space) + Geometry.get_z_origin_for_zone(space.thermalZone.get)).abs.round(1).to_s)
          end
        end
      end
    end
    
    # Walls
    walls = enclosure.add_element "Walls"
    model.getSpaces.each do |space|
      next unless ( Geometry.space_is_above_grade(space) and Geometry.space_is_finished(space) )
      space.surfaces.each do |surface|
        next unless surface.surfaceType.downcase == "wall"
        wall = walls.add_element "Wall"
        XMLHelper.add_attribute(wall.add_element("SystemIdentifier"), "id", surface.name)
        if surface.outsideBoundaryCondition.downcase == "outdoors"
           exterior_adjacent_to = "ambient"
        elsif surface.adjacentSurface.is_initialized
          if Geometry.is_living(surface.adjacentSurface.get.space.get)
            exterior_adjacent_to = "living space"
          elsif Geometry.is_unfinished_attic(surface.adjacentSurface.get.space.get)
            exterior_adjacent_to = "attic"
          elsif Geometry.is_finished_attic(surface.adjacentSurface.get.space.get)
            exterior_adjacent_to = "living space"
          elsif Geometry.is_garage(surface.adjacentSurface.get.space.get)
            exterior_adjacent_to = "garage"
          end
        end
        wall.add_element("ExteriorAdjacentTo").add_text(exterior_adjacent_to)
        wall.add_element("InteriorAdjacentTo").add_text("living space")
        model.getBuildingUnits.each do |unit|
          if unit.getFeatureAsString(Constants.SizingInfoWallType(surface)).is_initialized
            if unit.getFeatureAsString(Constants.SizingInfoWallType(surface)).get == "WoodStud"
              wall_type = wall.add_element("WallType")
              wall_type.add_element("WoodStud")
            end
          end
        end
        if surface.construction.is_initialized
          thickness = 0
          surface.construction.get.to_LayeredConstruction.get.layers.each do |layer|
            thickness += OpenStudio.convert(layer.thickness,"m","in").get
          end
          wall.add_element("Thickness").add_text(thickness.round(1).to_s)
        end
        wall.add_element("Area").add_text(OpenStudio.convert(surface.grossArea,"m^2","ft^2").get.round.to_s)
        if surface.construction.is_initialized
          surface.construction.get.to_LayeredConstruction.get.layers.each do |layer|
            next unless layer.name.to_s.downcase.include? "studandcavity"
            studs = wall.add_element "Studs"
            studs.add_element("Size").add_text(get_studs_size_from_thickness(layer.thickness))
          end
        end
      end
    end
    
    # Windows
    windows = nil
    model.getSubSurfaces.each do |subsurface|
      next unless subsurface.subSurfaceType.downcase == "fixedwindow"
      if enclosure.elements["Windows"].nil?
        windows = enclosure.add_element "Windows"
      end
      window = windows.add_element "Window"
      XMLHelper.add_attribute(window.add_element("SystemIdentifier"), "id", subsurface.name)
      window.add_element("Area").add_text(OpenStudio.convert(subsurface.grossArea,"m^2","ft^2").get.round.to_s)
      subsurface.construction.get.to_LayeredConstruction.get.layers.each do |layer|
        next unless layer.name.to_s.downcase.include? "glazingmaterial"
        layer = layer.to_SimpleGlazing.get
        window.add_element("UFactor").add_text(OpenStudio.convert(layer.uFactor,"W/m^2*K","Btu/hr*ft^2*R").get.round(2).to_s)
        window.add_element("SHGC").add_text(layer.solarHeatGainCoefficient.round(2).to_s)
      end
      # Overhangs
      XMLHelper.add_attribute(window.add_element("AttachedToWall"), "idref", subsurface.surface.get.name)
    end
    
    # Doors
    doors = nil
    model.getSubSurfaces.each do |subsurface|
      next unless subsurface.subSurfaceType.downcase == "door"
      if enclosure.elements["Doors"].nil?
        doors = enclosure.add_element "Doors"
      end      
      door = doors.add_element "Door"
      XMLHelper.add_attribute(door.add_element("SystemIdentifier"), "id", subsurface.name)
      XMLHelper.add_attribute(door.add_element("AttachedToWall"), "idref", subsurface.surface.get.name)
      door.add_element("Area").add_text(OpenStudio.convert(subsurface.grossArea,"m^2","ft^2").get.round.to_s)
      subsurface.construction.get.to_LayeredConstruction.get.layers.each do |layer|
        next unless layer.name.to_s.downcase.include? "doormaterial"
        layer = layer.to_StandardOpaqueMaterial.get
        door.add_element("RValue").add_text(OpenStudio.convert(OpenStudio.convert(layer.thickness,"m","in").get / layer.conductivity,"W/m^2*K","Btu/hr*ft^2*R").get.round(1).to_s)
      end
    end
    
    # Systems
    systems = building_details.add_element "Systems"
    
    # HVAC
    hvac = systems.add_element "HVAC"
    hvac_plant = hvac.add_element "HVACPlant"    
    
    model.getBuildingUnits.each do |unit|
    
      clg_equips = []
      htg_equips = []
      
      unit_thermal_zones = Geometry.get_thermal_zones_from_spaces(unit.spaces)
      control_slave_zones_hash = HVAC.get_control_and_slave_zones(unit_thermal_zones)
      
      if control_slave_zones_hash.keys.size > 1
        runner.registerError("Cannot handle multiple HVAC equipment in a unit.")
        return nil
      end
      
      control_zone = control_slave_zones_hash.keys[0]
      next unless control_zone.thermostatSetpointDualSetpoint.is_initialized
      thermostat = control_zone.thermostatSetpointDualSetpoint.get
      hvac_control = hvac.add_element "HVACControl"
      XMLHelper.add_attribute(hvac_control.add_element("SystemIdentifier"), "id", thermostat.name)
      XMLHelper.add_attribute(hvac_control.add_element("AttachedToZone"), "idref", control_zone.name)

      if Geometry.zone_is_finished(control_zone)
        loc = "conditioned space"
      end
      
      HVAC.existing_cooling_equipment(model, runner, control_zone).each do |clg_equip|
        next if clg_equips.include? clg_equip
        clg_equips << clg_equip
      end
      
      HVAC.existing_heating_equipment(model, runner, control_zone).each do |htg_equip|
        next if htg_equips.include? htg_equip
        htg_equips << htg_equip
      end
      
      next if clg_equips.empty? and htg_equips.empty?

      if HVAC.has_air_source_heat_pump(model, runner, control_zone) or HVAC.has_mini_split_heat_pump(model, runner, control_zone) or HVAC.has_gshp_vert_bore(model, runner, control_zone)

        name = nil
        type = nil
        clg_cap = nil
        htg_cap = nil
        clg_cop = nil
        htg_cop = nil
        supp_temp = nil
        supp_afue = nil
        supp_cap = nil
        
        htg_equips.each do |htg_equip|

          if HVAC.has_air_source_heat_pump(model, runner, control_zone)
            name = htg_equip.name
            type = "air-to-air"
            clg_coil = HVAC.get_coil_from_hvac_component(htg_equip.coolingCoil.get)
            htg_coil = HVAC.get_coil_from_hvac_component(htg_equip.heatingCoil.get)
            supp_coil = HVAC.get_coil_from_hvac_component(htg_equip.supplementalHeatingCoil.get)
            unless clg_coil.isRatedTotalCoolingCapacityAutosized
              clg_cap = OpenStudio.convert(clg_coil.ratedTotalCoolingCapacity.get,"W","Btu/h").get.round(1).to_s
            end
            unless htg_coil.isRatedTotalHeatingCapacityAutosized
              htg_cap = OpenStudio.convert(htg_coil.ratedTotalHeatingCapacity.get,"W","Btu/h").get.round(1).to_s
            end
            unless supp_coil.isNominalCapacityAutosized 
              supp_cap = OpenStudio.convert(supp_coil.nominalCapacity.get,"W","Btu/h").get.round(1).to_s
            end
            supp_temp = OpenStudio.convert(htg_equip.maximumOutdoorDryBulbTemperatureforSupplementalHeaterOperation,"C","F").get.round(1).to_s
            supp_afue = supp_coil.efficiency.round(2).to_s
            clg_cop = clg_coil.ratedCOP.get.round(2).to_s
            htg_cop = htg_coil.ratedCOP.round(2).to_s
          elsif HVAC.has_mini_split_heat_pump(model, runner, control_zone)
            name = htg_equip.name
            type = "mini-split"
            if htg_equip.to_ZoneHVACTerminalUnitVariableRefrigerantFlow.is_initialized
              model.getAirConditionerVariableRefrigerantFlows.each do |vrf|
                unless vrf.isRatedTotalCoolingCapacityAutosized
                  clg_cap = OpenStudio.convert(vrf.ratedTotalCoolingCapacity.get,"W","Btu/h").get.round(1).to_s
                end
                unless vrf.isRatedTotalHeatingCapacityAutosized
                  htg_cap = OpenStudio.convert(vrf.ratedTotalHeatingCapacity.get,"W","Btu/h").get.round(1).to_s
                end
                supp_temp = OpenStudio.convert(vrf.maximumOutdoorTemperatureinHeatingMode,"C","F").get.round(1).to_s
                clg_cop = vrf.ratedCoolingCOP.round(2).to_s
                htg_cop = vrf.ratedHeatingCOP.round(2).to_s
              end
            elsif htg_equip.to_ZoneHVACBaseboardConvectiveElectric.is_initialized
              supp_afue = htg_equip.efficiency.round(2).to_s
              unless htg_equip.isNominalCapacityAutosized
                supp_cap = OpenStudio.convert(htg_equip.nominalCapacity.get,"W","Btu/h").get.round(1).to_s
              end
            end            
          elsif HVAC.has_gshp_vert_bore(model, runner, control_zone)
            name = htg_equip.name
            type = "ground-to-air"
            clg_coil = HVAC.get_coil_from_hvac_component(htg_equip.coolingCoil.get)
            htg_coil = HVAC.get_coil_from_hvac_component(htg_equip.heatingCoil.get)
            supp_coil = HVAC.get_coil_from_hvac_component(htg_equip.supplementalHeatingCoil.get)
            unless supp_coil.isNominalCapacityAutosized 
              supp_cap = OpenStudio.convert(supp_coil.nominalCapacity.get,"W","Btu/h").get.round(1).to_s
            end
            supp_temp = OpenStudio.convert(htg_equip.maximumOutdoorDryBulbTemperatureforSupplementalHeaterOperation,"C","F").get.round(1).to_s
            supp_afue = supp_coil.efficiency.round(2).to_s
            clg_cop = clg_coil.ratedCoolingCoefficientofPerformance.round(2).to_s
            htg_cop = htg_coil.ratedHeatingCoefficientofPerformance.round(2).to_s            
          end
          
        end
        
        heat_pump = hvac_plant.add_element "HeatPump"
        XMLHelper.add_attribute(heat_pump.add_element("SystemIdentifier"), "id", name)
        XMLHelper.add_attribute(hvac_control.add_element("HVACSystemsServed"), "idref", heat_pump.elements["SystemIdentifier"].attributes["id"])
        XMLHelper.add_attribute(heat_pump.add_element("AttachedToZone"), "idref", control_zone.name)        
        XMLHelper.add_element(heat_pump, "UnitLocation", loc)
        XMLHelper.add_element(heat_pump, "HeatPumpType", type)
        unless htg_cap.nil?
          XMLHelper.add_element(heat_pump, "HeatingCapacity", htg_cap)
        end 
        unless clg_cap.nil?
          XMLHelper.add_element(heat_pump, "CoolingCapacity", clg_cap)
        end
        XMLHelper.add_element(heat_pump, "BackupSystemFuel", "electricity")
        XMLHelper.add_element(heat_pump, "BackupAFUE", supp_afue)
        unless supp_cap.nil?
          XMLHelper.add_element(heat_pump, "BackupHeatingCapacity", supp_cap)
        end
        XMLHelper.add_element(heat_pump, "BackupHeatingSwitchoverTemperature", supp_temp)
        XMLHelper.add_element(heat_pump, "FloorAreaServed", OpenStudio.convert(control_zone.floorArea,"m^2","ft^2").get.round.to_s)
        annual_cool_efficiency = heat_pump.add_element "AnnualCoolEfficiency"
        XMLHelper.add_element(annual_cool_efficiency, "Units", "COP")
        XMLHelper.add_element(annual_cool_efficiency, "Value", clg_cop)
        annual_heat_efficiency = heat_pump.add_element "AnnualHeatEfficiency"
        XMLHelper.add_element(annual_heat_efficiency, "Units", "COP")
        XMLHelper.add_element(annual_heat_efficiency, "Value", htg_cop)

      end

      if HVAC.has_furnace(model, runner, control_zone, false, false)
      
        htg_equips.each do |htg_equip|
          heating_system = hvac_plant.add_element "HeatingSystem"
          htg_coil = HVAC.get_coil_from_hvac_component(htg_equip.heatingCoil.get)
          XMLHelper.add_attribute(heating_system.add_element("SystemIdentifier"), "id", htg_coil.name)
          XMLHelper.add_attribute(hvac_control.add_element("HVACSystemsServed"), "idref", heating_system.elements["SystemIdentifier"].attributes["id"])
          XMLHelper.add_attribute(heating_system.add_element("AttachedToZone"), "idref", control_zone.name)
          XMLHelper.add_element(heating_system, "UnitLocation", loc)
          XMLHelper.add_element(heating_system.add_element("HeatingSystemType"), "Furnace")
          XMLHelper.add_element(heating_system, "HeatingSystemFuel", osm_to_hpxml_fuel_map(htg_coil.fuelType))
          unless htg_coil.isNominalCapacityAutosized
            XMLHelper.add_element(heating_system, "HeatingCapacity", OpenStudio.convert(htg_coil.nominalCapacity.get,"W","Btu/h").get.round(1).to_s)
          end
          annual_heat_efficiency = heating_system.add_element "AnnualHeatingEfficiency"
          XMLHelper.add_element(annual_heat_efficiency, "Units", "AFUE")
          XMLHelper.add_element(annual_heat_efficiency, "Value", htg_coil.gasBurnerEfficiency.round(2).to_s)
          XMLHelper.add_element(heating_system, "FloorAreaServed", OpenStudio.convert(control_zone.floorArea,"m^2","ft^2").get.round.to_s)
        end

      end
      
      if HVAC.has_boiler(model, runner, control_zone)
      
        htg_equips.each do |htg_equip|
          htg_coil = HVAC.get_coil_from_hvac_component(htg_equip.heatingCoil)
          htg_coil.plantLoop.get.supplyComponents.each do |supply_component|
            next unless supply_component.to_BoilerHotWater.is_initialized
            boiler = supply_component.to_BoilerHotWater.get
            heating_system = hvac_plant.add_element "HeatingSystem"
            XMLHelper.add_attribute(heating_system.add_element("SystemIdentifier"), "id", htg_coil.name)
            XMLHelper.add_attribute(hvac_control.add_element("HVACSystemsServed"), "idref", heating_system.elements["SystemIdentifier"].attributes["id"])
            XMLHelper.add_attribute(heating_system.add_element("AttachedToZone"), "idref", control_zone.name)
            XMLHelper.add_element(heating_system, "UnitLocation", loc)
            heating_system_type = heating_system.add_element "HeatingSystemType"
            XMLHelper.add_element(heating_system_type.add_element("Boiler"), "BoilerType", "hot water")
            XMLHelper.add_element(heating_system, "HeatingSystemFuel", osm_to_hpxml_fuel_map(boiler.fuelType))
            unless boiler.isNominalCapacityAutosized
              XMLHelper.add_element(heating_system, "HeatingCapacity", OpenStudio.convert(boiler.nominalCapacity.get,"W","Btu/h").get.round(1).to_s)
            end
            annual_heat_efficiency = heating_system.add_element "AnnualHeatingEfficiency"
            XMLHelper.add_element(annual_heat_efficiency, "Units", "AFUE")
            XMLHelper.add_element(annual_heat_efficiency, "Value", boiler.nominalThermalEfficiency.round(2).to_s)
            XMLHelper.add_element(heating_system, "FloorAreaServed", OpenStudio.convert(control_zone.floorArea,"m^2","ft^2").get.round.to_s)
          end
        end

      end
      
      if HVAC.has_electric_baseboard(model, runner, control_zone)
      
        htg_equips.each do |htg_equip|
          heating_system = hvac_plant.add_element "HeatingSystem"
          XMLHelper.add_attribute(heating_system.add_element("SystemIdentifier"), "id", htg_equip.name)
          XMLHelper.add_attribute(hvac_control.add_element("HVACSystemsServed"), "idref", heating_system.elements["SystemIdentifier"].attributes["id"])
          XMLHelper.add_attribute(heating_system.add_element("AttachedToZone"), "idref", control_zone.name)
          XMLHelper.add_element(heating_system, "UnitLocation", loc)
          heating_system_type = heating_system.add_element "HeatingSystemType"
          XMLHelper.add_element(heating_system_type.add_element("ElectricResistance"), "ElectricDistribution", "baseboard")          
          XMLHelper.add_element(heating_system, "HeatingSystemFuel", "electricity")
          unless htg_equip.isNominalCapacityAutosized
            XMLHelper.add_element(heating_system, "HeatingCapacity", OpenStudio.convert(htg_equip.nominalCapacity.get,"W","Btu/h").get.round(1).to_s)
          end
          annual_heat_efficiency = heating_system.add_element "AnnualHeatingEfficiency"
          XMLHelper.add_element(annual_heat_efficiency, "Units", "AFUE")
          XMLHelper.add_element(annual_heat_efficiency, "Value", htg_equip.efficiency.round(2).to_s)
          XMLHelper.add_element(heating_system, "FloorAreaServed", OpenStudio.convert(control_zone.floorArea,"m^2","ft^2").get.round.to_s)
        end

      end     

      if HVAC.has_central_air_conditioner(model, runner, control_zone, false, false)
      
        clg_equips.each do |clg_equip|
          cooling_system = hvac_plant.add_element "CoolingSystem"
          clg_coil = HVAC.get_coil_from_hvac_component(clg_equip.coolingCoil.get)
          XMLHelper.add_attribute(cooling_system.add_element("SystemIdentifier"), "id", clg_coil.name)
          XMLHelper.add_attribute(hvac_control.add_element("HVACSystemsServed"), "idref", cooling_system.elements["SystemIdentifier"].attributes["id"])
          XMLHelper.add_attribute(cooling_system.add_element("AttachedToZone"), "idref", control_zone.name)
          XMLHelper.add_element(cooling_system, "UnitLocation", loc)
          XMLHelper.add_element(cooling_system, "CoolingSystemType", "central air conditioning")
          unless clg_coil.isRatedTotalCoolingCapacityAutosized
            XMLHelper.add_element(cooling_system, "CoolingCapacity", OpenStudio.convert(clg_coil.ratedTotalCoolingCapacity.get,"W","Btu/h").get.round(1).to_s)
          end
          XMLHelper.add_element(cooling_system, "FloorAreaServed", OpenStudio.convert(control_zone.floorArea,"m^2","ft^2").get.round.to_s)
          annual_cool_efficiency = cooling_system.add_element "AnnualCoolingEfficiency"
          XMLHelper.add_element(annual_cool_efficiency, "Units", "COP")
          XMLHelper.add_element(annual_cool_efficiency, "Value", clg_coil.ratedCOP.get.round(2).to_s)
          XMLHelper.add_element(cooling_system, "SensibleHeatFraction", clg_coil.ratedSensibleHeatRatio.get.round(2).to_s)
        end
        
      end
      
      if HVAC.has_room_air_conditioner(model, runner, control_zone)
      
        clg_equips.each do |clg_equip|
          cooling_system = hvac_plant.add_element "CoolingSystem"
          clg_coil = HVAC.get_coil_from_hvac_component(clg_equip.coolingCoil)
          XMLHelper.add_attribute(cooling_system.add_element("SystemIdentifier"), "id", clg_coil.name)
          XMLHelper.add_attribute(hvac_control.add_element("HVACSystemsServed"), "idref", cooling_system.elements["SystemIdentifier"].attributes["id"])
          XMLHelper.add_attribute(cooling_system.add_element("AttachedToZone"), "idref", control_zone.name)
          XMLHelper.add_element(cooling_system, "UnitLocation", loc)
          XMLHelper.add_element(cooling_system, "CoolingSystemType", "room air conditioner")
          unless clg_coil.isRatedTotalCoolingCapacityAutosized
            XMLHelper.add_element(cooling_system, "CoolingCapacity", OpenStudio.convert(clg_coil.ratedTotalCoolingCapacity.get,"W","Btu/h").get.round(1).to_s)
          end
          XMLHelper.add_element(cooling_system, "FloorAreaServed", OpenStudio.convert(control_zone.floorArea,"m^2","ft^2").get.round.to_s)
          annual_cool_efficiency = cooling_system.add_element "AnnualCoolingEfficiency"
          XMLHelper.add_element(annual_cool_efficiency, "Units", "COP")
          XMLHelper.add_element(annual_cool_efficiency, "Value", clg_coil.ratedCOP.get.round(2).to_s)
          XMLHelper.add_element(cooling_system, "SensibleHeatFraction", clg_coil.ratedSensibleHeatRatio.get.round(2).to_s)          
        end
        
      end      

    end
    
    # WaterHeating
    water_heating = nil
    model.getBuildingUnits.each do |unit|
      model.getPlantLoops.each do |pl|
        next if pl.name.to_s != Constants.PlantLoopDomesticWater(unit.name.to_s)
        if systems.elements["WaterHeating"].nil?
          water_heating = systems.add_element "WaterHeating"
        end
        water_heating_system = water_heating.add_element "WaterHeatingSystem"
        
        pl.supplyComponents.each do |wh|
          next if !wh.to_WaterHeaterMixed.is_initialized and !wh.to_WaterHeaterStratified.is_initialized and !wh.to_WaterHeaterHeatPump.is_initialized
          if wh.to_WaterHeaterMixed.is_initialized
            wh = wh.to_WaterHeaterMixed.get
            fuel = osm_to_hpxml_fuel_map(wh.heaterFuelType.to_s)
            if wh.heaterMaximumCapacity.is_initialized
              cap = OpenStudio.convert(wh.heaterMaximumCapacity.get,"W","Btu/h").get.round.to_s
            end
            if wh.heaterThermalEfficiency.is_initialized
              eff = wh.heaterThermalEfficiency.get.round(2).to_s
            end
            if wh.heaterControlType == "Cycle"
              type = "storage water heater"
              vol = OpenStudio.convert(wh.tankVolume.get,"m^3","gal").get.round(1).to_s
            elsif wh.heaterControlType == "Modulate"
              type = "instantaneous water heater"
            end
            if Geometry.is_pier_beam(wh.ambientTemperatureThermalZone.get)
              loc = "other exterior"
            elsif Geometry.is_crawl(wh.ambientTemperatureThermalZone.get)
              loc = "crawlspace - vented"
            elsif Geometry.is_finished_basement(wh.ambientTemperatureThermalZone.get)
              loc = "basement - conditioned"
            elsif Geometry.is_unfinished_basement(wh.ambientTemperatureThermalZone.get)
              loc = "basement - unconditioned"              
            elsif Geometry.is_unfinished_attic(wh.ambientTemperatureThermalZone.get)
              loc = "attic - unconditioned"
            elsif Geometry.is_finished_attic(wh.ambientTemperatureThermalZone.get)
              loc = "conditioned space"
            elsif Geometry.is_garage(wh.ambientTemperatureThermalZone.get)
              loc = "garage - unconditioned"
            elsif Geometry.is_living(wh.ambientTemperatureThermalZone.get)
              loc = "conditioned space"            
            elsif Geometry.zone_is_finished(wh.ambientTemperatureThermalZone.get)
              loc = "conditioned space"
            end
            if wh.setpointTemperatureSchedule.is_initialized
              temp = OpenStudio.convert(wh.setpointTemperatureSchedule.get.to_ScheduleConstant.get.value,"C","F").get.round(1).to_s
            end
            control_zone = wh.ambientTemperatureThermalZone.get
          elsif wh.to_WaterHeaterStratified.is_initialized
            wh = wh.to_WaterHeaterStratified.get
          elsif wh.to_WaterHeaterHeatPump.is_initialized
            wh = wh.to_WaterHeaterHeatPump.get
          end
          XMLHelper.add_attribute(water_heating_system.add_element("SystemIdentifier"), "id", pl.name)
          XMLHelper.add_attribute(water_heating_system.add_element("AttachedToZone"), "idref", control_zone.name)
          XMLHelper.add_element(water_heating_system, "FuelType", fuel)
          XMLHelper.add_element(water_heating_system, "WaterHeaterType", type)
          XMLHelper.add_element(water_heating_system, "Location", loc)
          XMLHelper.add_element(water_heating_system, "TankVolume", vol)
          XMLHelper.add_element(water_heating_system, "HeatingCapacity", cap)
          XMLHelper.add_element(water_heating_system, "ThermalEfficiency", eff)
          XMLHelper.add_element(water_heating_system, "HotWaterTemperature", temp)
        end
        
        pl.demandComponents.each do |component|
          next unless component.to_WaterUseConnections.is_initialized
          water_use_connection = component.to_WaterUseConnections.get
          water_use_connection.waterUseEquipment.each do |fixture|
            next if fixture.name.to_s.include? "dist"
            water_fixture = water_heating.add_element "WaterFixture"
            if [/faucet/, /sink/, /bath/].any? { |type| fixture.name.to_s =~ type }
              type = "faucet"
            elsif fixture.name.to_s =~ /shower/
              type = "shower head"
            else
              type = "other"
            end
            flow = OpenStudio.convert(fixture.waterUseEquipmentDefinition.peakFlowRate,"m^3/s","gal/min").get.round(2).to_s
            XMLHelper.add_attribute(water_fixture.add_element("SystemIdentifier"), "id", "fixture #{fixture.name}")
            XMLHelper.add_attribute(water_fixture.add_element("AttachedToWaterHeatingSystem"), "idref", water_heating_system.elements["SystemIdentifier"].attributes["id"])            
            XMLHelper.add_element(water_fixture, "WaterFixtureType", type)
            XMLHelper.add_element(water_fixture, "FlowRate", flow)
          end
        end        
        
      end
    end
    
    # Appliances
    appliances = building_details.add_element "Appliances"

    model.getSpaces.each do |space|
      if Geometry.is_living(space)
        loc = "living space"
      elsif Geometry.is_garage(space)
        loc = "garage"
      elsif Geometry.is_finished_basement(space) or Geometry.is_unfinished_basement(space)
        loc = "basement"
      end
      space.electricEquipment.each do |ee|
        next unless ee.name.to_s.downcase.include? "clothes washer"
        clothes_washer = appliances.add_element "ClothesWasher"
        XMLHelper.add_attribute(clothes_washer.add_element("SystemIdentifier"), "id", "#{ee.name}")
        XMLHelper.add_element(clothes_washer, "Location", loc)
      end
      space.electricEquipment.each do |ee|
        next unless ee.name.to_s.downcase.include? "clothes dryer"
        clothes_dryer = appliances.add_element "ClothesDryer"
        XMLHelper.add_attribute(clothes_dryer.add_element("SystemIdentifier"), "id", "#{ee.name}")
        XMLHelper.add_element(clothes_dryer, "Location", loc)
        XMLHelper.add_element(clothes_dryer, "FuelType", "electricity")
      end
      space.otherEquipment.each do |oe|
        next unless oe.name.to_s.downcase.include? "clothes dryer"
        clothes_dryer = appliances.add_element "ClothesDryer"
        XMLHelper.add_attribute(clothes_dryer.add_element("SystemIdentifier"), "id", "#{oe.name}")
        XMLHelper.add_element(clothes_dryer, "Location", loc)
        XMLHelper.add_element(clothes_dryer, "FuelType", osm_to_hpxml_fuel_map(oe.fuelType))
      end      
      space.electricEquipment.each do |ee|
        next unless ee.name.to_s.downcase.include? "dishwasher"
        dishwasher = appliances.add_element "Dishwasher"
        XMLHelper.add_attribute(dishwasher.add_element("SystemIdentifier"), "id", "#{ee.name}")
      end      
      space.electricEquipment.each do |ee|
        next unless ee.name.to_s.downcase.include? "refrigerator"
        refrigerator = appliances.add_element "Refrigerator"
        XMLHelper.add_attribute(refrigerator.add_element("SystemIdentifier"), "id", "#{ee.name}")
        XMLHelper.add_element(refrigerator, "Location", loc)
        XMLHelper.add_element(refrigerator, "RatedAnnualkWh", ee.electricEquipmentDefinition.designLevel.get)
      end
      space.electricEquipment.each do |ee|
        next unless ee.name.to_s.downcase.include? "cooking range"
        cooking_range = appliances.add_element "CookingRange"
        XMLHelper.add_attribute(cooking_range.add_element("SystemIdentifier"), "id", "#{ee.name}")
        XMLHelper.add_element(cooking_range, "Location", loc)
      end
      space.otherEquipment.each do |oe|
        next unless oe.name.to_s.downcase.include? "cooking range"
        cooking_range = appliances.add_element "CookingRange"
        XMLHelper.add_attribute(cooking_range.add_element("SystemIdentifier"), "id", "#{oe.name}")
        XMLHelper.add_element(cooking_range, "Location", loc)
        XMLHelper.add_element(cooking_range, "FuelType", osm_to_hpxml_fuel_map(oe.fuelType))
      end
      space.electricEquipment.each do |ee|
        next unless ee.name.to_s.downcase.include? "freezer"
        freezer = appliances.add_element "Freezer"
        XMLHelper.add_attribute(freezer.add_element("SystemIdentifier"), "id", "#{ee.name}")
        XMLHelper.add_element(freezer, "Location", loc)
        XMLHelper.add_element(freezer, "RatedAnnualkWh", ee.electricEquipmentDefinition.designLevel.get)
      end
    end
    
    # Lighting
    lighting = building_details.add_element "Lighting"
    
    model.getLightss.each do |l|
      next unless l.name.to_s.downcase.include? "lighting"
      lighting_group = lighting.add_element "LightingGroup"
      XMLHelper.add_attribute(lighting_group.add_element("SystemIdentifier"), "id", l.name)
      XMLHelper.add_attribute(lighting_group.add_element("AttachedToSpace"), "idref", l.space.get.name)
      XMLHelper.add_element(lighting_group, "Location", "interior")
      XMLHelper.add_element(lighting_group, "FloorAreaServed", OpenStudio.convert(l.space.get.floorArea,"m^2","ft^2").get.round.to_s)
    end    
    
    model.getElectricEquipments.each do |ee|
      next unless ee.name.to_s.downcase.include? "ceiling fan"
      ceiling_fan = lighting.add_element "CeilingFan"
      XMLHelper.add_attribute(ceiling_fan.add_element("SystemIdentifier"), "id", ee.name)    
    end
    
    # Pools
    pools = building_details.add_element "Pools"
    
    model.getElectricEquipments.each do |ee|
      next unless ee.name.to_s.downcase.include? "pool heater"
      pool = pools.add_element "Pool"
      XMLHelper.add_attribute(pool.add_element("SystemIdentifier"), "id", ee.name)
      heater = pool.add_element "Heater"
      XMLHelper.add_attribute(heater.add_element("SystemIdentifier"), "id", "heater #{ee.name}")
      XMLHelper.add_element(heater, "Type", "electric resistance")
    end
    
    model.getGasEquipments.each do |ge|
      next unless ge.name.to_s.downcase.include? "pool heater"
      pool = pools.add_element "Pool"
      XMLHelper.add_attribute(pool.add_element("SystemIdentifier"), "id", ge.name)
      heater = pool.add_element "Heater"
      XMLHelper.add_attribute(heater.add_element("SystemIdentifier"), "id", "heater #{ge.name}")
      XMLHelper.add_element(heater, "Type", "gas fired")
    end
    
    model.getElectricEquipments.each do |ee|
      next unless ee.name.to_s.downcase.include? "pool pump"
      pool = pools.add_element "Pool"
      XMLHelper.add_attribute(pool.add_element("SystemIdentifier"), "id", ee.name)
      pool_pumps = pool.add_element "PoolPumps"
      pool_pump = pool_pumps.add_element "PoolPump"
      XMLHelper.add_attribute(pool_pump.add_element("SystemIdentifier"), "id", "pump #{ee.name}")
    end
    
    model.getElectricEquipments.each do |ee|
      next unless ee.name.to_s.downcase.include? "hot tub heater"
      pool = pools.add_element "Pool"
      XMLHelper.add_attribute(pool.add_element("SystemIdentifier"), "id", ee.name)
      heater = pool.add_element "Heater"
      XMLHelper.add_attribute(heater.add_element("SystemIdentifier"), "id", "heater #{ee.name}")
      XMLHelper.add_element(heater, "Type", "electric resistance")
    end
    
    model.getGasEquipments.each do |ge|
      next unless ge.name.to_s.downcase.include? "hot tub heater"
      pool = pools.add_element "Pool"
      XMLHelper.add_attribute(pool.add_element("SystemIdentifier"), "id", ge.name)
      heater = pool.add_element "Heater"
      XMLHelper.add_attribute(heater.add_element("SystemIdentifier"), "id", "heater #{ge.name}")
      XMLHelper.add_element(heater, "Type", "gas fired")
    end
    
    model.getElectricEquipments.each do |ee|
      next unless ee.name.to_s.downcase.include? "hot tub pump"
      pool = pools.add_element "Pool"
      XMLHelper.add_attribute(pool.add_element("SystemIdentifier"), "id", ee.name)
      pool_pumps = pool.add_element "PoolPumps"
      pool_pump = pool_pumps.add_element "PoolPump"
      XMLHelper.add_attribute(pool_pump.add_element("SystemIdentifier"), "id", "pump #{ee.name}")
    end    
    
    # MiscLoads
    misc_loads = building_details.add_element "MiscLoads"
    
    model.getElectricEquipments.each do |ee|
      next unless ee.name.to_s.downcase.include? "plug loads"
      plug_load = misc_loads.add_element "PlugLoad"
      XMLHelper.add_attribute(plug_load.add_element("SystemIdentifier"), "id", ee.name)
      XMLHelper.add_attribute(plug_load.add_element("AttachedToSpace"), "idref", ee.space.get.name)
      XMLHelper.add_element(plug_load, "Location", "interior")
      load = plug_load.add_element "Load"
      XMLHelper.add_element(load, "Units", "W")
      XMLHelper.add_element(load, "Value", ee.electricEquipmentDefinition.designLevel.get.round(1))
    end
    
    errors = []
    XMLHelper.validate(doc.to_s, File.join(schemas_dir, "HPXML.xsd")).each do |error|
      runner.registerError(error.to_s)
      errors << error.to_s
      puts error
    end
    
    unless errors.empty?
      # return false
    end
    
    XMLHelper.write_file(doc, File.join(File.dirname(__FILE__), "tests", "#{File.basename osm_file_path, ".*"}.xml"))
    
    return true

  end
  
  def get_studs_size_from_thickness(th)
    th = OpenStudio.convert(th,"m","in").get
    if (th - 3.5).abs < 0.1
      return "2x4"
    elsif (th - 5.5).abs < 0.1
      return "2x6"
    end
  end
  
  def osm_to_hpxml_fuel_map(fuel)
    return {"NaturalGas"=>"natural gas", "FuelOil#1"=>"fuel oil", "PropaneGas"=>"propane", "Electricity"=>"electricity"}[fuel]
  end
  
end

# register the measure to be used by the application
OSMtoHPXMLExport.new.registerWithApplication
