# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/reference/measure_writing_guide/

require 'rexml/document'
require "#{File.dirname(__FILE__)}/resources/constants"

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
    
    unless (Pathname.new osm_file_path).absolute?
      osm_file_path = File.expand_path(File.join(File.dirname(__FILE__), osm_file_path))
    end 
    unless File.exists?(osm_file_path) and osm_file_path.downcase.end_with? ".osm"
      runner.registerError("'#{osm_file_path}' does not exist or is not an .osm file.")
      return false
    end
    
    translator = OpenStudio::OSVersion::VersionTranslator.new
    path = OpenStudio::Path.new(osm_file_path)
    model = translator.loadModel(path)
    model = model.get    
    
    doc = REXML::Document.new

    root = doc.add_element "HPXML"
    
    xml_transaction_header_information = root.add_element "XMLTransactionHeaderInformation"
    xml_transaction_header_information.add_element "XMLType"
    xml_transaction_header_information.elements["XMLType"].text = "HPXML"
    xml_transaction_header_information.add_element "XMLGeneratedBy"
    xml_transaction_header_information.elements["XMLGeneratedBy"].text = File.basename(File.dirname(__FILE__))
    
    software_info = root.add_element "SoftwareInfo"
    software_info.add_element "SoftwareProgramUsed"
    software_info.elements["SoftwareProgramUsed"].text = "OpenStudio"
    
    building = root.add_element "Building"
    building_details = building.add_element "BuildingDetails"
    building_summary = building_details.add_element "BuildingSummary"
    building_construction = building_summary.add_element "BuildingConstruction"
    building_construction.add_element "ResidentialFacilityType"
    building_construction.elements["ResidentialFacilityType"].text = {Constants.BuildingTypeSingleFamilyDetached=>"single-family detached"}[model.getBuilding.standardsBuildingType.to_s]
    
    enclosure = building_details.add_element "Enclosure"
    walls = enclosure.add_element "Walls"
    
    model.getSurfaces.each do |surface|
      next unless surface.surfaceType.downcase == "wall"
      next unless surface.outsideBoundaryCondition.downcase == "outdoors"
      wall = walls.add_element "Wall"
      wall.add_element "SystemIdentifier", {"id"=>surface.name}
      wall.add_element "ExteriorAdjacentTo"
      wall.elements["ExteriorAdjacentTo"].text = "ambient"
    end
    
    doc.write(File.open(File.join(File.dirname(__FILE__), "#{File.basename osm_file_path, ".*"}.xml"), "w"), 1)

    return true

  end
  
end

# register the measure to be used by the application
HPXMLExport.new.registerWithApplication
