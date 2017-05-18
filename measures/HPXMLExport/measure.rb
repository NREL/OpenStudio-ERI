# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/reference/measure_writing_guide/

require 'rexml/document'

require "#{File.dirname(__FILE__)}/resources/constants"
require "#{File.dirname(__FILE__)}/resources/geometry"

# start the measure
class HPXMLExport < OpenStudio::Measure::ModelMeasure

  # human readable name
  def name
    return "HPXML Export"
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
    args = OpenStudio::Ruleset::OSArgumentVector.new

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

    root = doc.add_element "HPXML"
    
    xml_transaction_header_information = root.add_element "XMLTransactionHeaderInformation"
    xml_transaction_header_information.add_element("XMLType").add_text("HPXML")
    xml_transaction_header_information.add_element("XMLGeneratedBy").add_text(File.basename(File.dirname(__FILE__)))
    xml_transaction_header_information.add_element("CreatedDateAndTime").add_text("Test")
    xml_transaction_header_information.add_element("Transaction").add_text("create")
    
    software_info = root.add_element "SoftwareInfo"
    software_info.add_element("SoftwareProgramUsed").add_text("OpenStudio")
    software_info.add_element("SoftwareProgramVersion").add_text(model.getVersion.versionIdentifier)
    
    building = root.add_element "Building"
    building.add_element "BuildingID", {"id"=>model.getBuilding.name}
    project_status = building.add_element "ProjectStatus"
    project_status.add_element("EventType").add_text("audit")
    building_details = building.add_element "BuildingDetails"
    building_summary = building_details.add_element "BuildingSummary"
    building_construction = building_summary.add_element "BuildingConstruction"
    building_construction.add_element("ResidentialFacilityType").add_text({Constants.BuildingTypeSingleFamilyDetached=>"single-family detached"}[model.getBuilding.standardsBuildingType.to_s])
    building_construction.add_element("NumberofUnits").add_text(model.getBuilding.standardsNumberOfLivingUnits.to_s)
    model.getBuildingUnits.each do |unit|
      if unit.getFeatureAsInteger("NumberOfBedrooms").is_initialized
        building_construction.add_element("NumberOfBedrooms").add_text(unit.getFeatureAsInteger("NumberOfBedrooms").get.to_s)
      end
      if unit.getFeatureAsDouble("NumberOfBathrooms").is_initialized
        building_construction.add_element("NumberOfBathrooms").add_text(unit.getFeatureAsDouble("NumberOfBathrooms").get.to_i.to_s)
      end
      building_construction.add_element("ConditionedFloorArea").add_text(Geometry.get_above_grade_finished_floor_area_from_spaces(unit.spaces).round.to_s)
      building_construction.add_element("FinishedFloorArea").add_text(Geometry.get_above_grade_finished_floor_area_from_spaces(unit.spaces).round.to_s)
      # NumberofStoriesAboveGrade
      building_construction.add_element("ConditionedBuildingVolume").add_text(Geometry.get_finished_volume_from_spaces(unit.spaces).round.to_s)
    end
    building_occupancy = building_summary.add_element "BuildingOccupancy"
    num_people = 0
    model.getPeopleDefinitions.each do |people_def|
      num_people += people_def.numberofPeople.get
    end
    building_occupancy.add_element("NumberofResidents").add_text(num_people.round.to_s)
    
    # Enclosure
    enclosure = building_details.add_element "Enclosure"    
    
    # Foundations
    foundations = enclosure.add_element "Foundations"
    model.getSpaces.each do |space|
      if Geometry.space_is_below_grade(space) and Geometry.space_is_finished(space)
        foundation = foundations.add_element "Foundation"
        # foundation.add_element "SystemIdentifier", {"id"=>}
        foundation_type = foundation.add_element "FoundationType"
        basement = foundation_type.add_element "Basement"
        basement.add_element("Conditioned").add_text("true")      
        space.surfaces.each do |surface|
          # next unless surface.outsideBoundaryCondition.downcase == "ground"
          if surface.surfaceType.downcase == "floor"
            slab = foundation.add_element "Slab"
            slab.add_element "SystemIdentifier", {"id"=>surface.name}
            slab.add_element("Area").add_text(OpenStudio.convert(surface.grossArea,"m^2","ft^2").get.round.to_s)
            # Perimeter
            # ExposedPerimeter
            # PerimeterInsulationDepth
            # UnderSlabInsulationWidth
            # DepthBelowGrade
          elsif surface.surfaceType.downcase == "wall"
            foundation_wall = foundation.add_element "FoundationWall"
            foundation_wall.add_element "SystemIdentifier", {"id"=>surface.name}
            # Length
            # Height
            foundation_wall.add_element("Area").add_text(OpenStudio.convert(surface.grossArea,"m^2","ft^2").get.round.to_s)
            # Thickness
            # BelowGradeDepth
          elsif surface.surfaceType.downcase == "roofceiling"
            frame_floor = foundation.add_element "FrameFloor"
            frame_floor.add_element "SystemIdentifier", {"id"=>surface.name}
            # FloorJoists
            frame_floor.add_element("Area").add_text(OpenStudio.convert(surface.grossArea,"m^2","ft^2").get.round.to_s)
            # Insulation
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
        next unless surface.outsideBoundaryCondition.downcase == "outdoors"
        wall = walls.add_element "Wall"
        wall.add_element "SystemIdentifier", {"id"=>surface.name}
        wall.add_element("ExteriorAdjacentTo").add_text("ambient")
        wall.add_element("InteriorAdjacentTo").add_text("living space")
        # WallType
        wall.add_element("Area").add_text(OpenStudio.convert(surface.grossArea,"m^2","ft^2").get.round.to_s)
        surface.construction.get.to_LayeredConstruction.get.layers.each do |layer|
          next unless layer.name.to_s.downcase.include? "studandcavity"
          studs = wall.add_element "Studs"
          studs.add_element("Size").add_text(get_studs_size_from_thickness(layer.thickness))
          # Spacing
          # FramingFactor
        end
        # Color
        # Insulation
        # InsulationGrade
        # Layer
        # InstallationType
        # NominalRValue
        # Thickness
      end
    end
    
    # Roofs
    attics_and_roof = enclosure.add_element "AtticsAndRoof"
    roofs = attics_and_roof.add_element "Roofs"
    model.getSurfaces.each do |surface|
      next unless surface.surfaceType.downcase == "roofceiling"
      next unless surface.outsideBoundaryCondition.downcase == "outdoors"
      roof = roofs.add_element "Roof"
      roof.add_element "SystemIdentifier", {"id"=>surface.name}
      # RoofColor
      roof.add_element("RoofArea").add_text(OpenStudio.convert(surface.grossArea,"m^2","ft^2").get.round.to_s)
      # RadiantBarrier
    end
    
    # Windows
    windows = enclosure.add_element "Windows"
    model.getSubSurfaces.each do |subsurface|
      next unless subsurface.subSurfaceType.downcase == "fixedwindow"
      window = windows.add_element "Window"
      window.add_element "SystemIdentifier", {"id"=>subsurface.name}
      window.add_element("Area").add_text(OpenStudio.convert(subsurface.grossArea,"m^2","ft^2").get.round.to_s)
      subsurface.construction.get.to_LayeredConstruction.get.layers.each do |layer|
        next unless layer.name.to_s.downcase.include? "glazingmaterial"
        layer = layer.to_SimpleGlazing.get
        window.add_element("UFactor").add_text(OpenStudio.convert(layer.uFactor,"W/m^2*K","Btu/hr*ft^2*R").get.round(2).to_s)
        window.add_element("SHGC").add_text(layer.solarHeatGainCoefficient.round(2).to_s)
      end
      # Overhangs
      window.add_element "AttachedToWall", {"idref"=>subsurface.surface.get.name.to_s}
    end
    
    # doc = REXML::Document.new(File.read(File.join("measures", "HPXMLBuildModel", "tests", "CasaElena.xml")))
    
    errors = []
    validate(doc.to_s, File.join(schemas_dir, "HPXML.xsd")).each do |error|
      # runner.registerError(error.to_s)
      errors << error.to_s
      puts error
    end
    
    unless errors.empty?
      # return false
    end
    
    formatter = REXML::Formatters::Pretty.new(2)
    formatter.compact = true
    formatter.write(doc, File.open(File.join(File.dirname(__FILE__), "tests", "#{File.basename osm_file_path, ".*"}.xml"), "w"))
    
    return true

  end
  
  def get_studs_size_from_thickness(th)
    th = OpenStudio.convert(th,"m","in").get.round(1)
    if th == 3.5
      return "2x4"
    end
  end
  
  def validate(doc, xsd_path)
    require 'nokogiri'
    xsd = Nokogiri::XML::Schema(File.open(xsd_path))
    doc = Nokogiri::XML(doc)
    xsd.validate(doc)
  end
  
end

# register the measure to be used by the application
HPXMLExport.new.registerWithApplication
