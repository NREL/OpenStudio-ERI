# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/reference/measure_writing_guide/

require 'rexml/document'

require "#{File.dirname(__FILE__)}/resources/xmlhelper"
require "#{File.dirname(__FILE__)}/resources/hpxml"

# start the measure
class OSWtoHPXMLExport < OpenStudio::Measure::ModelMeasure

  # human readable name
  def name
    return "OSW to HPXML Export"
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

    arg = OpenStudio::Measure::OSArgument.makeStringArgument("osw_file_path", true)
    arg.setDisplayName("OSW File Path")
    arg.setDescription("Absolute (or relative) path of the OSW file.")
    args << arg

    arg = OpenStudio::Measure::OSArgument.makeStringArgument("schemas_dir", true)
    arg.setDisplayName("HPXML Schemas Directory")
    arg.setDescription("Absolute path of the hpxml schemas.")
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

    osw_file_path = runner.getStringArgumentValue("osw_file_path", user_arguments)
    schemas_dir = runner.getStringArgumentValue("schemas_dir", user_arguments)
    measures_dir = runner.getStringArgumentValue("measures_dir", user_arguments)
    
    unless (Pathname.new osw_file_path).absolute?
      osw_file_path = File.expand_path(File.join(File.dirname(__FILE__), osw_file_path))
    end 
    unless File.exists?(osw_file_path) and osw_file_path.downcase.end_with? ".osw"
      runner.registerError("'#{osw_file_path}' does not exist or is not an .osw file.")
      return false
    end
    
    unless (Pathname.new schemas_dir).absolute?
      schemas_dir = File.expand_path(File.join(File.dirname(__FILE__), schemas_dir))
    end
    unless Dir.exists?(schemas_dir)
      runner.registerError("'#{schemas_dir}' does not exist.")
      return false
    end
    
    unless (Pathname.new measures_dir).absolute?
      measures_dir = File.expand_path(File.join(File.dirname(__FILE__), measures_dir))
    end
    unless Dir.exists?(measures_dir)
      runner.registerError("'#{measures_dir}' does not exist.")
      return false
    end    
    
    osw = JSON.parse(File.read(osw_file_path))
    
    geometry = {}
    options = {}
    
    steps = osw["steps"]    
    steps.each do |step|
      if step["measure_dir_name"].downcase.include? "geometry"
        geometry[step["measure_dir_name"]] = step["arguments"]
      else
        options[step["measure_dir_name"]] = step["arguments"]
      end
    end    
    
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
    
    # Geometry
    if not OSModel.apply_measures(measures_dir, geometry, runner, model, show_measure_calls=false)
      return false
    end    
    
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
    air_infiltration_measurement = air_infiltration.add_element "AirInfiltrationMeasurement"
    XMLHelper.add_attribute(air_infiltration_measurement.add_element("SystemIdentifier"), "id", "air infiltration measurement")
    building_air_leakage = air_infiltration_measurement.add_element "BuildingAirLeakage"
    XMLHelper.add_element(building_air_leakage, "UnitofMeasure", "ACH")
    XMLHelper.add_element(building_air_leakage, "AirLeakage", options["ResidentialAirflow"]["living_ach50"])    
    
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
        wall_type = wall.add_element("WallType")
        if options.keys.include? "ResidentialConstructionsWallsExteriorWoodStud"
          wall_type.add_element("WoodStud")
        elsif options.keys.include? "ResidentialConstructionsWallsExteriorDoubleWoodStud"
          wall_type.add_element("DoubleWoodStud")
        elsif options.keys.include? "ResidentialConstructionsWallsExteriorSteelStud"
          wall_type.add_element("SteelFrame")
        elsif options.keys.include? "ResidentialConstructionsWallsExteriorICF"
          wall_type.add_element("InsulatedConcreteForms")
        elsif options.keys.include? "ResidentialConstructionsWallsExteriorSIP"
          wall_type.add_element("StructurallyInsulatedPanel")
        elsif options.keys.include? "ResidentialConstructionsWallsExteriorCMU"
          wall_type.add_element("ConcreteMasonryUnit")
        end
        wall.add_element("Area").add_text(OpenStudio.convert(surface.grossArea,"m^2","ft^2").get.round.to_s)
        studs = wall.add_element "Studs"
        XMLHelper.add_element(studs, "Size", get_studs_size_from_thickness(options["ResidentialConstructionsWallsExteriorWoodStud"]["cavity_depth"].to_f))
        XMLHelper.add_element(studs, "FramingFactor", options["ResidentialConstructionsWallsExteriorWoodStud"]["framing_factor"])
        insulation = wall.add_element "Insulation"
        XMLHelper.add_attribute(insulation.add_element("SystemIdentifier"), "id", "insulation #{wall.elements["SystemIdentifier"].attributes["id"]}")
        XMLHelper.add_element(insulation, "InsulationGrade", insulation_grade(options["ResidentialConstructionsWallsExteriorWoodStud"]["install_grade"]))
        layer = insulation.add_element "Layer"
        XMLHelper.add_element(layer, "NominalRValue", options["ResidentialConstructionsWallsExteriorWoodStud"]["cavity_r"])        
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
      XMLHelper.add_element(window, "UFactor", options["ResidentialConstructionsWindows"]["ufactor"])
      XMLHelper.add_element(window, "SHGC", options["ResidentialConstructionsWindows"]["shgc"])      
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
      XMLHelper.add_element(door, "RValue", 1.0 / options["ResidentialConstructionsDoors"]["door_uvalue"].to_f)
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
    
    XMLHelper.write_file(doc, File.join(File.dirname(__FILE__), "tests", "#{File.basename osw_file_path, ".*"}.xml"))    
    
    return true

  end
  
  def get_studs_size_from_thickness(th)
    if (th - 3.5).abs < 0.1
      return "2x4"
    elsif (th - 5.5).abs < 0.1
      return "2x6"
    end
  end
  
  def insulation_grade(gr)
    map = {"I"=>1, "II"=>2, "III"=>3}
    return map[gr]
  end
  
end

# register the measure to be used by the application
OSWtoHPXMLExport.new.registerWithApplication
