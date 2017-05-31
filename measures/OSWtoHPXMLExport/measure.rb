# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/reference/measure_writing_guide/

require 'rexml/document'

require "#{File.dirname(__FILE__)}/resources/xmlhelper"
require "#{File.dirname(__FILE__)}/resources/constants"
require "#{File.dirname(__FILE__)}/resources/helper_methods"
require "#{File.dirname(__FILE__)}/resources/hvac"

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
    
    measures = {}
    
    steps = osw["steps"]    
    steps.each do |step|
      measures[step["measure_dir_name"]] = step["arguments"]
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
    if not apply_measures(measures_dir, measures, runner, model, show_measure_calls=false)
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
    XMLHelper.add_element(building_occupancy, "NumberofResidents", num_people.round)
    building_construction = building_summary.add_element "BuildingConstruction"
    XMLHelper.add_element(building_construction, "ResidentialFacilityType", {Constants.BuildingTypeSingleFamilyDetached=>"single-family detached"}[model.getBuilding.standardsBuildingType.to_s])
    XMLHelper.add_element(building_construction, "NumberofUnits", model.getBuilding.standardsNumberOfLivingUnits)
    XMLHelper.add_element(building_construction, "NumberofBedrooms", measures["ResidentialGeometryNumBedsAndBaths"]["num_bedrooms"])
    XMLHelper.add_element(building_construction, "NumberofBathrooms", measures["ResidentialGeometryNumBedsAndBaths"]["num_bathrooms"])
    model.getBuildingUnits.each do |unit|
      XMLHelper.add_element(building_construction, "ConditionedFloorArea", Geometry.get_above_grade_finished_floor_area_from_spaces(unit.spaces).round)
      XMLHelper.add_element(building_construction, "FinishedFloorArea", Geometry.get_above_grade_finished_floor_area_from_spaces(unit.spaces).round)
      XMLHelper.add_element(building_construction, "NumberofStoriesAboveGrade", Geometry.get_building_stories(unit.spaces))
      XMLHelper.add_element(building_construction, "ConditionedBuildingVolume", Geometry.get_finished_volume_from_spaces(unit.spaces).round)
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
        XMLHelper.add_element(space, "Volume", Geometry.get_volume_from_spaces([sp]).round)
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
    XMLHelper.add_element(building_air_leakage, "AirLeakage", measures["ResidentialAirflow"]["living_ach50"])    
    
    # AtticAndRoof
    attic_and_roof = enclosure.add_element "AtticAndRoof"
    
    roofs = attic_and_roof.add_element "Roofs"
    model.getSurfaces.each do |surface|
      next unless surface.surfaceType.downcase == "roofceiling"
      next unless surface.outsideBoundaryCondition.downcase == "outdoors"
      roof = roofs.add_element "Roof"
      XMLHelper.add_attribute(roof.add_element("SystemIdentifier"), "id", surface.name)
      XMLHelper.add_element(roof, "RoofColor", measures["ResidentialConstructionsCeilingsRoofsRoofingMaterial"]["color"])
      XMLHelper.add_element(roof, "RoofType", osw_to_hpxml_roof_type(measures["ResidentialConstructionsCeilingsRoofsRoofingMaterial"]["material"]))
      num, den = measures["ResidentialGeometrySingleFamilyDetached"]["roof_pitch"].split(":")
      XMLHelper.add_element(roof, "Pitch", num.to_f / den.to_f)
      XMLHelper.add_element(roof, "RoofArea", OpenStudio.convert(surface.grossArea,"m^2","ft^2").get.round)
      XMLHelper.add_element(roof, "RadiantBarrier", measures["ResidentialConstructionsCeilingsRoofsRadiantBarrier"]["has_rb"])
    end
    
    attics = attic_and_roof.add_element "Attics"
    model.getSpaces.each do |space|
      next unless Geometry.is_unfinished_attic(space)
      attic = attics.add_element "Attic"
      XMLHelper.add_attribute(attic.add_element("SystemIdentifier"), "id", "#{space.name} attic")
      XMLHelper.add_element(attic, "AtticType", "venting unknown attic")
      attic_floor_insulation = attic.add_element "AtticFloorInsulation"
      XMLHelper.add_attribute(attic_floor_insulation.add_element("SystemIdentifier"), "id", "#{space.name} floor ins")
      XMLHelper.add_element(attic_floor_insulation, "InsulationGrade", osw_to_hpxml_ins_grade(measures["ResidentialConstructionsCeilingsRoofsUnfinishedAttic"]["ceil_grade"]))
      layer = attic_floor_insulation.add_element "Layer"
      XMLHelper.add_element(layer, "InstallationType", "cavity")
      XMLHelper.add_element(layer, "NominalRValue", measures["ResidentialConstructionsCeilingsRoofsUnfinishedAttic"]["ceil_r"])
      XMLHelper.add_element(layer, "Thickness", measures["ResidentialConstructionsCeilingsRoofsUnfinishedAttic"]["ceil_ins_thick_in"])
      attic_roof_insulation = attic.add_element "AtticRoofInsulation"
      XMLHelper.add_attribute(attic_roof_insulation.add_element("SystemIdentifier"), "id", "#{space.name} roof ins")
      XMLHelper.add_element(attic_roof_insulation, "InsulationGrade", osw_to_hpxml_ins_grade(measures["ResidentialConstructionsCeilingsRoofsUnfinishedAttic"]["roof_cavity_grade"]))
      layer = attic_roof_insulation.add_element "Layer"
      XMLHelper.add_element(layer, "InstallationType", "cavity")
      XMLHelper.add_element(layer, "NominalRValue", measures["ResidentialConstructionsCeilingsRoofsUnfinishedAttic"]["roof_cavity_r"])
      XMLHelper.add_element(layer, "Thickness", measures["ResidentialConstructionsCeilingsRoofsUnfinishedAttic"]["roof_cavity_ins_thick_in"])      
      rafters = attic.add_element "Rafters"
      XMLHelper.add_element(rafters, "Size", get_studs_size_from_thickness(measures["ResidentialConstructionsCeilingsRoofsUnfinishedAttic"]["roof_fram_thick_in"]))
      XMLHelper.add_element(rafters, "FramingFactor", measures["ResidentialConstructionsCeilingsRoofsUnfinishedAttic"]["roof_ff"])
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
          XMLHelper.add_element(slab, "Area", OpenStudio.convert(surface.grossArea,"m^2","ft^2").get.round)
          l, w, h = Geometry.get_surface_dimensions(surface)
          XMLHelper.add_element(slab, "ExposedPerimeter", OpenStudio.convert(2*w+2*l,"m","ft").get.round(1))
          XMLHelper.add_element(slab, "PerimeterInsulationDepth", measures["ResidentialConstructionsFoundationsFloorsSlab"]["ext_depth"])
          XMLHelper.add_element(slab, "UnderSlabInsulationWidth", measures["ResidentialConstructionsFoundationsFloorsSlab"]["perim_width"])
          perimeter_insulation = slab.add_element "PerimeterInsulation"
          XMLHelper.add_attribute(perimeter_insulation.add_element("SystemIdentifier"), "id", "#{surface.name} exterior ins")
          layer = perimeter_insulation.add_element "Layer"
          XMLHelper.add_element(layer, "NominalRValue", measures["ResidentialConstructionsFoundationsFloorsSlab"]["ext_r"]) 
          under_slab_insulation = slab.add_element "UnderSlabInsulation"
          XMLHelper.add_attribute(under_slab_insulation.add_element("SystemIdentifier"), "id", "#{surface.name} perimeter ins")
          layer = under_slab_insulation.add_element "Layer"
          XMLHelper.add_element(layer, "NominalRValue", measures["ResidentialConstructionsFoundationsFloorsSlab"]["perim_r"])         
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
            floor_joists = frame_floor.add_element "FloorJoists"
            XMLHelper.add_element(floor_joists, "Size", get_studs_size_from_thickness(measures["ResidentialConstructionsFoundationsFloorsBasementFinished"]["ceil_joist_height"]))
            XMLHelper.add_element(floor_joists, "FramingFactor", measures["ResidentialConstructionsFoundationsFloorsBasementFinished"]["ceil_ff"])
            XMLHelper.add_element(frame_floor, "Area", OpenStudio.convert(surface.grossArea,"m^2","ft^2").get.round)
          end
        end
        space.surfaces.each do |surface|
          if surface.surfaceType.downcase == "wall"
            foundation_wall = foundation.add_element "FoundationWall"
            XMLHelper.add_attribute(foundation_wall.add_element("SystemIdentifier"), "id", surface.name)
            l, w, h = Geometry.get_surface_dimensions(surface)
            XMLHelper.add_element(foundation_wall, "Length", OpenStudio.convert([l, w].max,"m","ft").get.round(1))
            XMLHelper.add_element(foundation_wall, "Height", OpenStudio.convert(h,"m","ft").get.round(1))
            XMLHelper.add_element(foundation_wall, "Area", OpenStudio.convert(surface.grossArea,"m^2","ft^2").get.round)
            XMLHelper.add_element(foundation_wall, "BelowGradeDepth", (Geometry.getSurfaceZValues([surface]).min + Geometry.get_z_origin_for_zone(space.thermalZone.get)).abs.round(1))
            insulation = foundation_wall.add_element "Insulation"
            XMLHelper.add_attribute(insulation.add_element("SystemIdentifier"), "id", "#{surface.name} wall ins")
            if measures["ResidentialConstructionsFoundationsFloorsBasementFinished"]["wall_cavity_depth"].to_f > 0
              interior_studs = foundation_wall.add_element "InteriorStuds"
              XMLHelper.add_element(interior_studs, "Size", get_studs_size_from_thickness(measures["ResidentialConstructionsFoundationsFloorsBasementFinished"]["wall_cavity_depth"]))
              XMLHelper.add_element(interior_studs, "FramingFactor", measures["ResidentialConstructionsFoundationsFloorsBasementFinished"]["wall_ff"])
              XMLHelper.add_element(insulation, "InsulationGrade", osw_to_hpxml_ins_grade(measures["ResidentialConstructionsFoundationsFloorsBasementFinished"]["wall_cavity_grade"]))
              layer = insulation.add_element "Layer"
              XMLHelper.add_element(layer, "InstallationType", "cavity")
              XMLHelper.add_element(layer, "NominalRValue", measures["ResidentialConstructionsFoundationsFloorsBasementFinished"]["wall_cavity_r"])
            end
            layer = insulation.add_element "Layer"
            XMLHelper.add_element(layer, "InstallationType", "continuous")
            XMLHelper.add_element(layer, "NominalRValue", measures["ResidentialConstructionsFoundationsFloorsBasementFinished"]["wall_rigid_r"])
            XMLHelper.add_element(layer, "Thickness", measures["ResidentialConstructionsFoundationsFloorsBasementFinished"]["wall_rigid_thick_in"])
          end
        end
        space.surfaces.each do |surface|
          if surface.surfaceType.downcase == "floor"
            slab = foundation.add_element "Slab"
            XMLHelper.add_attribute(slab.add_element("SystemIdentifier"), "id", surface.name)
            XMLHelper.add_element(slab, "Area", OpenStudio.convert(surface.grossArea,"m^2","ft^2").get.round)
            l, w, h = Geometry.get_surface_dimensions(surface)
            XMLHelper.add_element(slab, "ExposedPerimeter", OpenStudio.convert(2*w+2*l,"m","ft").get.round(1))
            XMLHelper.add_element(slab, "DepthBelowGrade", (Geometry.get_space_floor_z(space) + Geometry.get_z_origin_for_zone(space.thermalZone.get)).abs.round(1))
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
            floor_joists = frame_floor.add_element "FloorJoists"
            XMLHelper.add_element(floor_joists, "Size", get_studs_size_from_thickness(measures["ResidentialConstructionsFoundationsFloorsBasementUnfinished"]["ceil_joist_height"]))
            XMLHelper.add_element(floor_joists, "FramingFactor", measures["ResidentialConstructionsFoundationsFloorsBasementUnfinished"]["ceil_ff"])
            XMLHelper.add_element(frame_floor, "Area", OpenStudio.convert(surface.grossArea,"m^2","ft^2").get.round)
            insulation = frame_floor.add_element "Insulation"
            XMLHelper.add_attribute(insulation.add_element("SystemIdentifier"), "id", "#{surface.name} ceil ins")
            XMLHelper.add_element(insulation, "InsulationGrade", osw_to_hpxml_ins_grade(measures["ResidentialConstructionsFoundationsFloorsBasementUnfinished"]["ceil_cavity_grade"]))
            layer = insulation.add_element "Layer"
            XMLHelper.add_element(layer, "InstallationType", "cavity")
            XMLHelper.add_element(layer, "NominalRValue", measures["ResidentialConstructionsFoundationsFloorsBasementUnfinished"]["ceil_cavity_r"])            
          end
        end
        space.surfaces.each do |surface|
          if surface.surfaceType.downcase == "wall"
            foundation_wall = foundation.add_element "FoundationWall"
            XMLHelper.add_attribute(foundation_wall.add_element("SystemIdentifier"), "id", surface.name)
            l, w, h = Geometry.get_surface_dimensions(surface)
            XMLHelper.add_element(foundation_wall, "Length", OpenStudio.convert([l, w].max,"m","ft").get.round(1))
            XMLHelper.add_element(foundation_wall, "Height", OpenStudio.convert(h,"m","ft").get.round(1))
            XMLHelper.add_element(foundation_wall, "Area", OpenStudio.convert(surface.grossArea,"m^2","ft^2").get.round)
            XMLHelper.add_element(foundation_wall, "BelowGradeDepth", (Geometry.getSurfaceZValues([surface]).min + Geometry.get_z_origin_for_zone(space.thermalZone.get)).abs.round(1))
            insulation = foundation_wall.add_element "Insulation"
            XMLHelper.add_attribute(insulation.add_element("SystemIdentifier"), "id", "#{surface.name} wall ins")
            if measures["ResidentialConstructionsFoundationsFloorsBasementUnfinished"]["wall_cavity_depth"].to_f > 0
              interior_studs = foundation_wall.add_element "InteriorStuds"
              XMLHelper.add_element(interior_studs, "Size", get_studs_size_from_thickness(measures["ResidentialConstructionsFoundationsFloorsBasementUnfinished"]["wall_cavity_depth"]))
              XMLHelper.add_element(interior_studs, "FramingFactor", measures["ResidentialConstructionsFoundationsFloorsBasementUnfinished"]["wall_ff"])
              XMLHelper.add_element(insulation, "InsulationGrade", osw_to_hpxml_ins_grade(measures["ResidentialConstructionsFoundationsFloorsBasementUnfinished"]["wall_cavity_grade"]))
              layer = insulation.add_element "Layer"
              XMLHelper.add_element(layer, "InstallationType", "cavity")
              XMLHelper.add_element(layer, "NominalRValue", measures["ResidentialConstructionsFoundationsFloorsBasementUnfinished"]["wall_cavity_r"])
            end
            layer = insulation.add_element "Layer"
            XMLHelper.add_element(layer, "InstallationType", "continuous")
            XMLHelper.add_element(layer, "NominalRValue", measures["ResidentialConstructionsFoundationsFloorsBasementUnfinished"]["wall_rigid_r"])
            XMLHelper.add_element(layer, "Thickness", measures["ResidentialConstructionsFoundationsFloorsBasementUnfinished"]["wall_rigid_thick_in"])
          end
        end
        space.surfaces.each do |surface|
          if surface.surfaceType.downcase == "floor"
            slab = foundation.add_element "Slab"
            XMLHelper.add_attribute(slab.add_element("SystemIdentifier"), "id", surface.name)
            XMLHelper.add_element(slab, "Area", OpenStudio.convert(surface.grossArea,"m^2","ft^2").get.round)
            l, w, h = Geometry.get_surface_dimensions(surface)
            XMLHelper.add_element(slab, "ExposedPerimeter", OpenStudio.convert(2*w+2*l,"m","ft").get.round(1))
            XMLHelper.add_element(slab, "DepthBelowGrade", (Geometry.get_space_floor_z(space) + Geometry.get_z_origin_for_zone(space.thermalZone.get)).abs.round(1))
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
        if measures["ResidentialAirflow"]["crawl_ach"].to_f == 0
          XMLHelper.add_element(crawl, "Vented", "false")
        else
          XMLHelper.add_element(crawl, "Vented", "true")
        end
        space.surfaces.each do |surface|
          if surface.surfaceType.downcase == "roofceiling"
            frame_floor = foundation.add_element "FrameFloor"
            XMLHelper.add_attribute(frame_floor.add_element("SystemIdentifier"), "id", surface.name)
            floor_joists = frame_floor.add_element "FloorJoists"
            XMLHelper.add_element(floor_joists, "Size", get_studs_size_from_thickness(measures["ResidentialConstructionsFoundationsFloorsCrawlspace"]["ceil_joist_height"]))
            XMLHelper.add_element(floor_joists, "FramingFactor", measures["ResidentialConstructionsFoundationsFloorsCrawlspace"]["ceil_ff"])
            XMLHelper.add_element(frame_floor, "Area", OpenStudio.convert(surface.grossArea,"m^2","ft^2").get.round)
            insulation = frame_floor.add_element "Insulation"
            XMLHelper.add_attribute(insulation.add_element("SystemIdentifier"), "id", "#{surface.name} ceil ins")
            XMLHelper.add_element(insulation, "InsulationGrade", osw_to_hpxml_ins_grade(measures["ResidentialConstructionsFoundationsFloorsCrawlspace"]["ceil_cavity_grade"]))
            layer = insulation.add_element "Layer"
            XMLHelper.add_element(layer, "InstallationType", "cavity")
            XMLHelper.add_element(layer, "NominalRValue", measures["ResidentialConstructionsFoundationsFloorsCrawlspace"]["ceil_cavity_r"])            
          end
        end
        space.surfaces.each do |surface|
          if surface.surfaceType.downcase == "wall"
            foundation_wall = foundation.add_element "FoundationWall"
            XMLHelper.add_attribute(foundation_wall.add_element("SystemIdentifier"), "id", surface.name)
            l, w, h = Geometry.get_surface_dimensions(surface)
            XMLHelper.add_element(foundation_wall, "Length", OpenStudio.convert([l, w].max,"m","ft").get.round(1))
            XMLHelper.add_element(foundation_wall, "Height", OpenStudio.convert(h,"m","ft").get.round(1))
            XMLHelper.add_element(foundation_wall, "Area", OpenStudio.convert(surface.grossArea,"m^2","ft^2").get.round)
            XMLHelper.add_element(foundation_wall, "BelowGradeDepth", (Geometry.getSurfaceZValues([surface]).min + Geometry.get_z_origin_for_zone(space.thermalZone.get)).abs.round(1))
            insulation = foundation_wall.add_element "Insulation"
            XMLHelper.add_attribute(insulation.add_element("SystemIdentifier"), "id", "#{surface.name} wall ins")
            layer = insulation.add_element "Layer"
            XMLHelper.add_element(layer, "InstallationType", "continuous")
            XMLHelper.add_element(layer, "NominalRValue", measures["ResidentialConstructionsFoundationsFloorsBasementUnfinished"]["wall_rigid_r"])
            XMLHelper.add_element(layer, "Thickness", measures["ResidentialConstructionsFoundationsFloorsBasementUnfinished"]["wall_rigid_thick_in"])
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
        if measures.keys.include? "ResidentialConstructionsWallsExteriorWoodStud"
          wall_type.add_element("WoodStud")
        elsif measures.keys.include? "ResidentialConstructionsWallsExteriorDoubleWoodStud"
          wall_type.add_element("DoubleWoodStud")
        elsif measures.keys.include? "ResidentialConstructionsWallsExteriorSteelStud"
          wall_type.add_element("SteelFrame")
        elsif measures.keys.include? "ResidentialConstructionsWallsExteriorICF"
          wall_type.add_element("InsulatedConcreteForms")
        elsif measures.keys.include? "ResidentialConstructionsWallsExteriorSIP"
          wall_type.add_element("StructurallyInsulatedPanel")
        elsif measures.keys.include? "ResidentialConstructionsWallsExteriorCMU"
          wall_type.add_element("ConcreteMasonryUnit")
        end
        XMLHelper.add_element(wall, "Area", OpenStudio.convert(surface.grossArea,"m^2","ft^2").get.round)
        if measures.keys.include? "ResidentialConstructionsWallsExteriorWoodStud"
          studs = wall.add_element "Studs"
          XMLHelper.add_element(studs, "Size", get_studs_size_from_thickness(measures[get_measure_match(measures, "ResidentialConstructionsWallsExteriorWoodStud")]["cavity_depth"]))
          XMLHelper.add_element(studs, "FramingFactor", measures[get_measure_match(measures, "ResidentialConstructionsWallsExteriorWoodStud")]["framing_factor"])
          insulation = wall.add_element "Insulation"
          XMLHelper.add_attribute(insulation.add_element("SystemIdentifier"), "id", "insulation #{wall.elements["SystemIdentifier"].attributes["id"]}")
          XMLHelper.add_element(insulation, "InsulationGrade", osw_to_hpxml_ins_grade(measures[get_measure_match(measures, "ResidentialConstructionsWallsExteriorWoodStud")]["install_grade"]))
          layer = insulation.add_element "Layer"
          XMLHelper.add_element(layer, "InstallationType", "cavity")        
          XMLHelper.add_element(layer, "NominalRValue", measures["ResidentialConstructionsWallsExteriorWoodStud"]["cavity_r"])
        elsif measures.keys.include? "ResidentialConstructionsWallsExteriorDoubleWoodStud"
          
        elsif measures.keys.include? "ResidentialConstructionsWallsExteriorSteelStud"
          
        elsif measures.keys.include? "ResidentialConstructionsWallsExteriorICF"
          
        elsif measures.keys.include? "ResidentialConstructionsWallsExteriorSIP"
          
        elsif measures.keys.include? "ResidentialConstructionsWallsExteriorCMU"
          
        end
        if measures.keys.include? "ResidentialConstructionsWallsSheathing"
          layer = insulation.add_element "Layer"
          XMLHelper.add_element(layer, "InstallationType", "continuous")
          XMLHelper.add_element(layer, "NominalRValue", measures["ResidentialConstructionsWallsSheathing"]["rigid_r"])
          XMLHelper.add_element(layer, "Thickness", measures["ResidentialConstructionsWallsSheathing"]["rigid_thick_in"])
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
      XMLHelper.add_element(window, "UFactor", measures["ResidentialConstructionsWindows"]["ufactor"])
      XMLHelper.add_element(window, "SHGC", measures["ResidentialConstructionsWindows"]["shgc"])      
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
      XMLHelper.add_element(door, "RValue", 1.0 / measures["ResidentialConstructionsDoors"]["door_uvalue"].to_f)
    end
    
    # Systems
    systems = building_details.add_element "Systems"
    
    # HVAC
    hvac = systems.add_element "HVAC"
    hvac_plant = hvac.add_element "HVACPlant"    
    
    model.getBuildingUnits.each do |unit|
      
      control_slave_zones_hash = HVAC.get_control_and_slave_zones(Geometry.get_thermal_zones_from_spaces(unit.spaces))
      
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
      XMLHelper.add_element(hvac_control, "SetpointTempHeatingSeason", measures["ResidentialHVACHeatingSetpoints"]["htg_wkdy"])
      XMLHelper.add_element(hvac_control, "SetpointTempCoolingSeason", measures["ResidentialHVACCoolingSetpoints"]["clg_wkdy"])
      
      if HVAC.has_air_source_heat_pump(model, runner, control_zone) or HVAC.has_mini_split_heat_pump(model, runner, control_zone) or HVAC.has_gshp_vert_bore(model, runner, control_zone)

        name = nil
        type = nil
        clg_cap = nil
        htg_cap = nil
        clg_eff = nil
        htg_eff = nil
        supp_temp = nil
        supp_afue = nil
        supp_cap = nil
        
        HVAC.existing_heating_equipment(model, runner, control_zone).each do |htg_equip|

          name = htg_equip.name
          if HVAC.has_air_source_heat_pump(model, runner, control_zone)
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
            supp_afue = supp_coil.efficiency.round(2).to_s
            clg_eff = measures[get_measure_match(measures, "HeatPump")]["seer"]
            htg_eff = measures[get_measure_match(measures, "HeatPump")]["hspf"]
          elsif HVAC.has_mini_split_heat_pump(model, runner, control_zone)
            type = "mini-split"
            if htg_equip.to_ZoneHVACTerminalUnitVariableRefrigerantFlow.is_initialized
              model.getAirConditionerVariableRefrigerantFlows.each do |vrf|
                unless vrf.isRatedTotalCoolingCapacityAutosized
                  clg_cap = OpenStudio.convert(vrf.ratedTotalCoolingCapacity.get,"W","Btu/h").get.round(1).to_s
                end
                unless vrf.isRatedTotalHeatingCapacityAutosized
                  htg_cap = OpenStudio.convert(vrf.ratedTotalHeatingCapacity.get,"W","Btu/h").get.round(1).to_s
                end
              end
            elsif htg_equip.to_ZoneHVACBaseboardConvectiveElectric.is_initialized
              supp_afue = htg_equip.efficiency.round(2).to_s
              unless htg_equip.isNominalCapacityAutosized
                supp_cap = OpenStudio.convert(htg_equip.nominalCapacity.get,"W","Btu/h").get.round(1).to_s
              end
            end
            clg_eff = measures[get_measure_match(measures, "HeatPump")]["seer"]
            htg_eff = measures[get_measure_match(measures, "HeatPump")]["hspf"]            
          elsif HVAC.has_gshp_vert_bore(model, runner, control_zone)
            type = "ground-to-air"
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
            supp_afue = supp_coil.efficiency.round(2).to_s
            clg_eff = measures[get_measure_match(measures, "HeatPump")]["eer"]
            htg_eff = measures[get_measure_match(measures, "HeatPump")]["cop"]            
          end
          
        end
        
        heat_pump = hvac_plant.add_element "HeatPump"
        XMLHelper.add_attribute(heat_pump.add_element("SystemIdentifier"), "id", name)
        XMLHelper.add_attribute(hvac_control.add_element("HVACSystemsServed"), "idref", heat_pump.elements["SystemIdentifier"].attributes["id"])
        XMLHelper.add_attribute(heat_pump.add_element("AttachedToZone"), "idref", control_zone.name)
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
        XMLHelper.add_element(heat_pump, "FloorAreaServed", OpenStudio.convert(control_zone.floorArea,"m^2","ft^2").get.round)
        annual_cool_efficiency = heat_pump.add_element "AnnualCoolEfficiency"
        XMLHelper.add_element(annual_cool_efficiency, "Units", "SEER")
        XMLHelper.add_element(annual_cool_efficiency, "Value", clg_eff)
        annual_heat_efficiency = heat_pump.add_element "AnnualHeatEfficiency"
        XMLHelper.add_element(annual_heat_efficiency, "Units", "HSPF")
        XMLHelper.add_element(annual_heat_efficiency, "Value", htg_eff)

      end

      if HVAC.has_furnace(model, runner, control_zone, false, false)
      
        HVAC.existing_heating_equipment(model, runner, control_zone).each do |htg_equip|
          heating_system = hvac_plant.add_element "HeatingSystem"
          htg_coil = HVAC.get_coil_from_hvac_component(htg_equip.heatingCoil.get)
          XMLHelper.add_attribute(heating_system.add_element("SystemIdentifier"), "id", htg_coil.name)
          XMLHelper.add_attribute(hvac_control.add_element("HVACSystemsServed"), "idref", heating_system.elements["SystemIdentifier"].attributes["id"])
          XMLHelper.add_attribute(heating_system.add_element("AttachedToZone"), "idref", control_zone.name)
          XMLHelper.add_element(heating_system, "UnitLocation", loc)
          XMLHelper.add_element(heating_system.add_element("HeatingSystemType"), "Furnace")
          if measures.keys.include? "ResidentialHVACFurnaceElectric"
            fuel_type = "electricity"
          elsif measures.keys.include? "ResidentialHVACFurnaceFuel"
            fuel_type = measures[get_measure_match(measures, "Furnace")]["fuel_type"]
          end
          XMLHelper.add_element(heating_system, "HeatingSystemFuel", osw_to_hpxml_fuel_map(fuel_type))
          unless htg_coil.isNominalCapacityAutosized
            XMLHelper.add_element(heating_system, "HeatingCapacity", OpenStudio.convert(htg_coil.nominalCapacity.get,"W","Btu/h").get.round(1))
          end
          annual_heat_efficiency = heating_system.add_element "AnnualHeatingEfficiency"
          XMLHelper.add_element(annual_heat_efficiency, "Units", "AFUE")
          XMLHelper.add_element(annual_heat_efficiency, "Value", measures[get_measure_match(measures, "Furnace")]["afue"])
          XMLHelper.add_element(heating_system, "FloorAreaServed", OpenStudio.convert(control_zone.floorArea,"m^2","ft^2").get.round)
        end

      end
      
      if HVAC.has_boiler(model, runner, control_zone)
      
        HVAC.existing_heating_equipment(model, runner, control_zone).each do |htg_equip|
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
            if measures.keys.include? "ResidentialHVACBoilerElectric"
              fuel_type = "electricity"
            elsif measures.keys.include? "ResidentialHVACBoilerFuel"
              fuel_type = measures[get_measure_match(measures, "Furnace")]["fuel_type"]
            end
            XMLHelper.add_element(heating_system, "HeatingSystemFuel", osw_to_hpxml_fuel_map(fuel_type))
            unless boiler.isNominalCapacityAutosized
              XMLHelper.add_element(heating_system, "HeatingCapacity", OpenStudio.convert(boiler.nominalCapacity.get,"W","Btu/h").get.round(1))
            end
            annual_heat_efficiency = heating_system.add_element "AnnualHeatingEfficiency"
            XMLHelper.add_element(annual_heat_efficiency, "Units", "AFUE")
            XMLHelper.add_element(annual_heat_efficiency, "Value", boiler.nominalThermalEfficiency.round(2))
            XMLHelper.add_element(heating_system, "FloorAreaServed", OpenStudio.convert(control_zone.floorArea,"m^2","ft^2").get.round)
          end
        end

      end
      
      if HVAC.has_electric_baseboard(model, runner, control_zone)
      
        HVAC.existing_heating_equipment(model, runner, control_zone).each do |htg_equip|
          heating_system = hvac_plant.add_element "HeatingSystem"
          XMLHelper.add_attribute(heating_system.add_element("SystemIdentifier"), "id", htg_equip.name)
          XMLHelper.add_attribute(hvac_control.add_element("HVACSystemsServed"), "idref", heating_system.elements["SystemIdentifier"].attributes["id"])
          XMLHelper.add_attribute(heating_system.add_element("AttachedToZone"), "idref", control_zone.name)
          XMLHelper.add_element(heating_system, "UnitLocation", loc)
          heating_system_type = heating_system.add_element "HeatingSystemType"
          XMLHelper.add_element(heating_system_type.add_element("ElectricResistance"), "ElectricDistribution", "baseboard")          
          XMLHelper.add_element(heating_system, "HeatingSystemFuel", "electricity")
          unless htg_equip.isNominalCapacityAutosized
            XMLHelper.add_element(heating_system, "HeatingCapacity", OpenStudio.convert(htg_equip.nominalCapacity.get,"W","Btu/h").get.round(1))
          end
          annual_heat_efficiency = heating_system.add_element "AnnualHeatingEfficiency"
          XMLHelper.add_element(annual_heat_efficiency, "Units", "AFUE")
          XMLHelper.add_element(annual_heat_efficiency, "Value", htg_equip.efficiency.round(2))
          XMLHelper.add_element(heating_system, "FloorAreaServed", OpenStudio.convert(control_zone.floorArea,"m^2","ft^2").get.round)
        end

      end     

      if HVAC.has_central_air_conditioner(model, runner, control_zone, false, false)
      
        HVAC.existing_cooling_equipment(model, runner, control_zone).each do |clg_equip|
          cooling_system = hvac_plant.add_element "CoolingSystem"
          clg_coil = HVAC.get_coil_from_hvac_component(clg_equip.coolingCoil.get)
          XMLHelper.add_attribute(cooling_system.add_element("SystemIdentifier"), "id", clg_coil.name)
          XMLHelper.add_attribute(hvac_control.add_element("HVACSystemsServed"), "idref", cooling_system.elements["SystemIdentifier"].attributes["id"])
          XMLHelper.add_attribute(cooling_system.add_element("AttachedToZone"), "idref", control_zone.name)
          XMLHelper.add_element(cooling_system, "UnitLocation", loc)
          XMLHelper.add_element(cooling_system, "CoolingSystemType", "central air conditioning")
          unless clg_coil.isRatedTotalCoolingCapacityAutosized
            XMLHelper.add_element(cooling_system, "CoolingCapacity", OpenStudio.convert(clg_coil.ratedTotalCoolingCapacity.get,"W","Btu/h").get.round(1))
          end
          XMLHelper.add_element(cooling_system, "FloorAreaServed", OpenStudio.convert(control_zone.floorArea,"m^2","ft^2").get.round)
          annual_cool_efficiency = cooling_system.add_element "AnnualCoolingEfficiency"
          XMLHelper.add_element(annual_cool_efficiency, "Units", "COP")
          XMLHelper.add_element(annual_cool_efficiency, "Value", measures[get_measure_match(measures, "CentralAirConditioner")]["seer"])
          XMLHelper.add_element(cooling_system, "SensibleHeatFraction", clg_coil.ratedSensibleHeatRatio.get.round(2))
        end
        
      end
      
      if HVAC.has_room_air_conditioner(model, runner, control_zone)
      
        HVAC.existing_cooling_equipment(model, runner, control_zone).each do |clg_equip|
          cooling_system = hvac_plant.add_element "CoolingSystem"
          clg_coil = HVAC.get_coil_from_hvac_component(clg_equip.coolingCoil)
          XMLHelper.add_attribute(cooling_system.add_element("SystemIdentifier"), "id", clg_coil.name)
          XMLHelper.add_attribute(hvac_control.add_element("HVACSystemsServed"), "idref", cooling_system.elements["SystemIdentifier"].attributes["id"])
          XMLHelper.add_attribute(cooling_system.add_element("AttachedToZone"), "idref", control_zone.name)
          XMLHelper.add_element(cooling_system, "UnitLocation", loc)
          XMLHelper.add_element(cooling_system, "CoolingSystemType", "room air conditioner")
          unless clg_coil.isRatedTotalCoolingCapacityAutosized
            XMLHelper.add_element(cooling_system, "CoolingCapacity", OpenStudio.convert(clg_coil.ratedTotalCoolingCapacity.get,"W","Btu/h").get.round(1))
          end
          XMLHelper.add_element(cooling_system, "FloorAreaServed", OpenStudio.convert(control_zone.floorArea,"m^2","ft^2").get.round)
          annual_cool_efficiency = cooling_system.add_element "AnnualCoolingEfficiency"
          XMLHelper.add_element(annual_cool_efficiency, "Units", "COP")
          XMLHelper.add_element(annual_cool_efficiency, "Value", clg_coil.ratedCOP.get.round(2))
          XMLHelper.add_element(cooling_system, "SensibleHeatFraction", clg_coil.ratedSensibleHeatRatio.get.round(2))          
        end
        
      end      

    end
    
    # MechanicalVentilation
    if measures["ResidentialAirflow"]["mech_vent_type"] != "none"
      mechanical_ventilation = systems.add_element "MechanicalVentilation"
      ventilation_fans = mechanical_ventilation.add_element "VentilationFans"
      ventilation_fan = ventilation_fans.add_element "VentilationFan"
      XMLHelper.add_attribute(ventilation_fan.add_element("SystemIdentifier"), "id", "mech vent")
      XMLHelper.add_element(ventilation_fan, "FanType", osw_to_hpxml_mech_vent(measures["ResidentialAirflow"]["mech_vent_type"]))
      XMLHelper.add_element(ventilation_fan, "TotalRecoveryEfficiency", measures["ResidentialAirflow"]["mech_vent_total_efficiency"])
      XMLHelper.add_element(ventilation_fan, "SensibleRecoveryEfficiency", measures["ResidentialAirflow"]["mech_vent_sensible_efficiency"])
      XMLHelper.add_element(ventilation_fan, "FanPower", measures["ResidentialAirflow"]["mech_vent_fan_power"])
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
            control_zone = wh.ambientTemperatureThermalZone.get
          elsif wh.to_WaterHeaterStratified.is_initialized
            wh = wh.to_WaterHeaterStratified.get
          elsif wh.to_WaterHeaterHeatPump.is_initialized
            wh = wh.to_WaterHeaterHeatPump.get
          end
          XMLHelper.add_attribute(water_heating_system.add_element("SystemIdentifier"), "id", pl.name)
          XMLHelper.add_attribute(water_heating_system.add_element("AttachedToZone"), "idref", control_zone.name)
          if measures.keys.include? "ResidentialHotWaterHeaterHeatPump" or measures.keys.include? "ResidentialHotWaterHeaterTankElectric" or measures.keys.include? "ResidentialHotWaterHeaterTanklessElectric"
            fuel_type = "electricity"
          elsif
            fuel_type = osw_to_hpxml_fuel_map(measures[get_measure_match(measures, "HotWaterHeater")]["fuel_type"])
          end
          XMLHelper.add_element(water_heating_system, "FuelType", fuel_type)
          XMLHelper.add_element(water_heating_system, "WaterHeaterType", type)
          XMLHelper.add_element(water_heating_system, "Location", loc)
          XMLHelper.add_element(water_heating_system, "TankVolume", vol)
          XMLHelper.add_element(water_heating_system, "HeatingCapacity", cap)
          XMLHelper.add_element(water_heating_system, "EnergyFactor", measures[get_measure_match(measures, "HotWaterHeater")]["energy_factor"])
          XMLHelper.add_element(water_heating_system, "RecoveryEfficiency", measures[get_measure_match(measures, "HotWaterHeater")]["recovery_efficiency"])
          XMLHelper.add_element(water_heating_system, "ThermalEfficiency", eff)
          XMLHelper.add_element(water_heating_system, "HotWaterTemperature", measures[get_measure_match(measures, "HotWaterHeater")]["setpoint_temp"])
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

    if measures.keys.include? "ResidentialApplianceClothesWasher"
      clothes_washer = appliances.add_element "ClothesWasher"
      XMLHelper.add_attribute(clothes_washer.add_element("SystemIdentifier"), "id", "clothes washer")
      # XMLHelper.add_element(clothes_washer, "Location", loc)
      XMLHelper.add_element(clothes_washer, "ModifiedEnergyFactor", measures["ResidentialApplianceClothesWasher"]["imef"])
    end

    if measures.keys.include? "ResidentialApplianceClothesDryerElectric"
      clothes_dryer = appliances.add_element "ClothesDryer"
      XMLHelper.add_attribute(clothes_dryer.add_element("SystemIdentifier"), "id", "clothes dryer electric")
      # XMLHelper.add_element(clothes_dryer, "Location", loc)
      XMLHelper.add_element(clothes_dryer, "FuelType", "electricity")
    elsif measures.keys.include? "ResidentialApplianceClothesDryerFuel"
      clothes_dryer = appliances.add_element "ClothesDryer"
      XMLHelper.add_attribute(clothes_dryer.add_element("SystemIdentifier"), "id", "clothes dryer fuel")
      # XMLHelper.add_element(clothes_dryer, "Location", loc)
      XMLHelper.add_element(clothes_dryer, "FuelType", osw_to_hpxml_fuel_map(measures["ResidentialApplianceClothesDryerFuel"]["fuel_type"]))
    end

    if measures.keys.include? "ResidentialApplianceDishwasher"
      dishwasher = appliances.add_element "Dishwasher"
      XMLHelper.add_attribute(dishwasher.add_element("SystemIdentifier"), "id", "dishwasher")
      XMLHelper.add_element(dishwasher, "RatedAnnualkWh", measures["ResidentialApplianceDishwasher"]["dw_E"])
    end

    if measures.keys.include? "ResidentialApplianceRefrigerator"
      refrigerator = appliances.add_element "Refrigerator"
      XMLHelper.add_attribute(refrigerator.add_element("SystemIdentifier"), "id", "refrigerator")
      # XMLHelper.add_element(refrigerator, "Location", loc)
      XMLHelper.add_element(refrigerator, "RatedAnnualkWh", measures["ResidentialApplianceRefrigerator"]["fridge_E"])
    end
    
    if measures.keys.include? "ResidentialMiscExtraRefrigerator"
      refrigerator = appliances.add_element "Refrigerator"
      XMLHelper.add_attribute(refrigerator.add_element("SystemIdentifier"), "id", "extra refrigerator")
      # XMLHelper.add_element(refrigerator, "Location", loc)
      XMLHelper.add_element(refrigerator, "RatedAnnualkWh", measures["ResidentialMiscExtraRefrigerator"]["fridge_E"])
    end
    
    if measures.keys.include? "ResidentialMiscFreezer"
      freezer = appliances.add_element "Freezer"
      XMLHelper.add_attribute(freezer.add_element("SystemIdentifier"), "id", "freezer")
      # XMLHelper.add_element(freezer, "Location", loc)
      XMLHelper.add_element(freezer, "RatedAnnualkWh", measures["ResidentialMiscFreezer"]["freezer_E"])
    end      

    if measures.keys.include? "ResidentialApplianceCookingRangeElectric"
      cooking_range = appliances.add_element "CookingRange"
      XMLHelper.add_attribute(cooking_range.add_element("SystemIdentifier"), "id", "cooking range electric")
      # XMLHelper.add_element(cooking_range, "Location", loc)
      XMLHelper.add_element(cooking_range, "FuelType", "electricity")
    elsif measures.keys.include? "ResidentialApplianceCookingRangeFuel"
      cooking_range = appliances.add_element "CookingRange"
      XMLHelper.add_attribute(cooking_range.add_element("SystemIdentifier"), "id", "cooking range")
      # XMLHelper.add_element(cooking_range, "Location", loc)
      XMLHelper.add_element(cooking_range, "FuelType", osw_to_hpxml_fuel_map(measures["ResidentialApplianceCookingRangeFuel"]["fuel_type"]))
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
    lighting_fractions = lighting.add_element "LightingFractions"
    frac_cfl = measures["ResidentialLighting"]["hw_cfl"].to_f + measures["ResidentialLighting"]["pg_cfl"].to_f
    frac_lfl = measures["ResidentialLighting"]["hw_lfl"].to_f + measures["ResidentialLighting"]["pg_lfl"].to_f
    frac_led = measures["ResidentialLighting"]["hw_led"].to_f + measures["ResidentialLighting"]["pg_led"].to_f
    frac_inc = 1.0 - (frac_cfl + frac_lfl + frac_led)
    XMLHelper.add_element(lighting_fractions, "FractionIncandescent", frac_inc.round(2))
    XMLHelper.add_element(lighting_fractions, "FractionCFL", frac_cfl)
    XMLHelper.add_element(lighting_fractions, "FractionLFL", frac_lfl)
    XMLHelper.add_element(lighting_fractions, "FractionLED", frac_led)
    
    if measures.keys.include? "ResidentialHVACCeilingFan"
      ceiling_fan = lighting.add_element "CeilingFan"
      XMLHelper.add_attribute(ceiling_fan.add_element("SystemIdentifier"), "id", "ceiling fan")
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
      XMLHelper.add_element(load, "Value", ee.electricEquipmentDefinition.designLevel.get.round(1)) # TODO: needs to be converted
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
    if (th.to_f - 3.5).abs < 0.1
      return "2x4"
    elsif (th.to_f - 5.5).abs < 0.1
      return "2x6"
    elsif (th.to_f - 7.25).abs < 0.1
      return "2x8"
    elsif (th.to_f - 9.25).abs < 0.1
      return "2x10"
    end
  end
  
  def osw_to_hpxml_ins_grade(gr)
    map = {"I"=>1, "II"=>2, "III"=>3}
    return map[gr]
  end
  
  def get_measure_match(measures, substr)
    measure = measures.keys.select{|k| k.include? substr}
    if measure.empty? or measure.length > 1
      return nil
    end
    return measure[0]
  end
  
  def osw_to_hpxml_fuel_map(fuel)
    return {"gas"=>"natural gas", "oil"=>"fuel oil", "propane"=>"propane", "electricity"=>"electricity"}[fuel]
  end
  
  def osw_to_hpxml_roof_type(type)
    return {"asphalt shingles"=>"asphalt or fiberglass shingles", "membrane"=>"other", "metal"=>"metal surfacing", "tar gravel"=>"other", "tile"=>"slate or tile shingles", "wood shakes"=>"wood shingles or shakes"}[type]
  end
  
  def osw_to_hpxml_mech_vent(type)
    return {"exhaust"=>"exhaust only", "supply"=>"supply only", "balanced"=>"energy recovery ventilator"}[type]
  end
  
end

# register the measure to be used by the application
OSWtoHPXMLExport.new.registerWithApplication
