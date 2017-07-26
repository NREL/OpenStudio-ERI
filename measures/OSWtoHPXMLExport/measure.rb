# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/reference/measure_writing_guide/

require 'rexml/document'

require "#{File.dirname(__FILE__)}/resources/xmlhelper"
require "#{File.dirname(__FILE__)}/resources/constants"
require "#{File.dirname(__FILE__)}/resources/helper_methods"
require "#{File.dirname(__FILE__)}/resources/hvac"
require "#{File.dirname(__FILE__)}/resources/301validator"

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
      update_args_hash(measures, step["measure_dir_name"], step["arguments"])
    end

    if measures.keys.include? "ResidentialGeometrySingleFamilyAttached" or measures.keys.include? "ResidentialGeometryMultifamily"
      runner.registerError("Can currently handle only single-family detached.")
      return false
    end

    # Geometry
    if not apply_measures(measures_dir, measures, runner, model, show_measure_calls=true)
      return false
    end

    File.write(File.join(File.dirname(__FILE__), "tests", "#{File.basename osw_file_path, ".*"}.osm"), model.to_s)
    
    doc = REXML::Document.new

    root = doc.add_element "HPXML", {"schemaVersion"=>"2.2"}
    root.add_namespace("http://hpxmlonline.com/2014/6")
    # root.add_namespace("xsi", "http://www.w3.org/2001/XMLSchema-instance")
    
    xml_transaction_header_information = root.add_element "XMLTransactionHeaderInformation"
    XMLHelper.add_element(xml_transaction_header_information, "XMLType", "HPXML")
    XMLHelper.add_element(xml_transaction_header_information, "XMLGeneratedBy", File.basename(File.dirname(__FILE__)))
    XMLHelper.add_element(xml_transaction_header_information, "CreatedDateAndTime", Time.now.strftime('%Y-%m-%dT%H:%M:%S'))
    XMLHelper.add_element(xml_transaction_header_information, "Transaction", "create")
    
    software_info = root.add_element "SoftwareInfo"
    XMLHelper.add_element(software_info, "SoftwareProgramUsed", "OpenStudio")
    XMLHelper.add_element(software_info, "SoftwareProgramVersion", model.getVersion.versionIdentifier)
    
    building = root.add_element "Building"
    XMLHelper.add_attribute(building.add_element("BuildingID"), "id", model.getBuilding.name)
    project_status = building.add_element "ProjectStatus"
    XMLHelper.add_element(project_status, "EventType", "proposed workscope")
    building_details = building.add_element "BuildingDetails"
    building_summary = building_details.add_element "BuildingSummary"
    site = building_summary.add_element "Site"
    if measures.keys.include? "ResidentialAirflow"
      XMLHelper.add_element(site, "SiteType", os_to_hpxml_site_type(measures["ResidentialAirflow"][0]["terrain"]))
    end
    XMLHelper.add_element(site, "Surroundings", "stand-alone")
    if measures.keys.include? "ResidentialGeometryOrientation"
      XMLHelper.add_element(site, "AzimuthOfFrontOfHome", Geometry.get_abs_azimuth(Constants.CoordAbsolute, measures["ResidentialGeometryOrientation"][0]["orientation"].to_f, 0).round)
    end
    building_occupancy = building_summary.add_element "BuildingOccupancy"
    num_people = 0
    model.getPeopleDefinitions.each do |people_def|
      num_people += people_def.numberofPeople.get
    end
    XMLHelper.add_element(building_occupancy, "NumberofResidents", num_people.round)
    building_construction = building_summary.add_element "BuildingConstruction"
    XMLHelper.add_element(building_construction, "ResidentialFacilityType", {Constants.BuildingTypeSingleFamilyDetached=>"single-family detached"}[model.getBuilding.standardsBuildingType.to_s])
    XMLHelper.add_element(building_construction, "NumberofUnits", model.getBuilding.standardsNumberOfLivingUnits)
    model.getBuildingUnits.each do |unit|
      XMLHelper.add_element(building_construction, "NumberofConditionedFloors", Geometry.get_building_stories(unit.spaces))
      XMLHelper.add_element(building_construction, "NumberofConditionedFloorsAboveGrade", Geometry.get_above_grade_building_stories(unit.spaces))    
    end
    XMLHelper.add_element(building_construction, "NumberofBedrooms", measures["ResidentialGeometryNumBedsAndBaths"][0]["num_bedrooms"].to_f.round)
    XMLHelper.add_element(building_construction, "NumberofBathrooms", measures["ResidentialGeometryNumBedsAndBaths"][0]["num_bathrooms"].to_f.round)
    model.getBuildingUnits.each do |unit|
      XMLHelper.add_element(building_construction, "ConditionedFloorArea", Geometry.get_finished_floor_area_from_spaces(unit.spaces).round)
      XMLHelper.add_element(building_construction, "ConditionedBuildingVolume", Geometry.get_finished_volume_from_spaces(unit.spaces).round)
    end
    if measures["ResidentialGeometrySingleFamilyDetached"][0]["garage_width"].to_f * measures["ResidentialGeometrySingleFamilyDetached"][0]["garage_depth"].to_f > 0
      XMLHelper.add_element(building_construction, "GaragePresent", true)
    else
      XMLHelper.add_element(building_construction, "GaragePresent", false)
    end

    arg_vals = []
    measures.values.each do |h|
      h.each do |k, v|
        arg_vals << v
      end
    end
    if arg_vals.include? Constants.FuelTypeGas
      XMLHelper.add_element(building_summary.add_element("extension"), "HasNaturalGasAccessOrFuelDelivery", true)
    else
      XMLHelper.add_element(building_summary.add_element("extension"), "HasNaturalGasAccessOrFuelDelivery", false)
    end
    
    # ClimateandRiskZones
    if measures.keys.include? "ResidentialLocation"
      climate_and_risk_zones = building_details.add_element "ClimateandRiskZones"
      climate_zone_iecc = climate_and_risk_zones.add_element "ClimateZoneIECC"
      XMLHelper.add_element(climate_zone_iecc, "Year", 2006)
      XMLHelper.add_element(climate_zone_iecc, "ClimateZone", 7)
    end
    
    # Enclosure
    enclosure = building_details.add_element "Enclosure"
    
    # AirInfiltration
    air_infiltration = enclosure.add_element "AirInfiltration"
    air_infiltration_measurement = air_infiltration.add_element "AirInfiltrationMeasurement"
    XMLHelper.add_attribute(air_infiltration_measurement.add_element("SystemIdentifier"), "id", Constants.ObjectNameInfiltration)
    building_air_leakage = air_infiltration_measurement.add_element "BuildingAirLeakage"
    XMLHelper.add_element(building_air_leakage, "UnitofMeasure", "ACHnatural")
    XMLHelper.add_element(building_air_leakage, "AirLeakage", measures["ResidentialAirflow"][0]["living_ach50"]) # TODO: how to convert to ACHnatural? what is the N factor?
    
    # AtticAndRoof
    attic_and_roof = enclosure.add_element "AtticAndRoof"    
    roofs = attic_and_roof.add_element "Roofs"    
    attics = attic_and_roof.add_element "Attics"
    
    attached_to_roofs = {}
    model.getSpaces.each do |space|
      roof_area = 0
      space.surfaces.each do |surface|
        next unless surface.surfaceType.downcase == "roofceiling"
        next unless surface.outsideBoundaryCondition.downcase == "outdoors"
        roof_area += OpenStudio.convert(surface.grossArea,"m^2","ft^2").get      
      end
      next unless roof_area > 0
      roof = roofs.add_element "Roof"
      XMLHelper.add_attribute(roof.add_element("SystemIdentifier"), "id", "#{space.name} roof")
      XMLHelper.add_element(roof, "RoofColor", measures["ResidentialConstructionsCeilingsRoofsRoofingMaterial"][0]["color"])
      XMLHelper.add_element(roof, "RoofType", os_to_hpxml_roof_type(measures["ResidentialConstructionsCeilingsRoofsRoofingMaterial"][0]["material"]))
      num, den = measures["ResidentialGeometrySingleFamilyDetached"][0]["roof_pitch"].split(":")
      XMLHelper.add_element(roof, "Pitch", num.to_f / den.to_f)
      XMLHelper.add_element(roof, "RoofArea", roof_area.round(1))
      if measures.keys.include? "ResidentialConstructionsCeilingsRoofsRadiantBarrier"
        XMLHelper.add_element(roof, "RadiantBarrier", measures["ResidentialConstructionsCeilingsRoofsRadiantBarrier"][0]["has_rb"])
      else
        XMLHelper.add_element(roof, "RadiantBarrier", false)
      end
      space.surfaces.each do |surface|
        if surface.surfaceType.downcase == "floor" and ( Geometry.is_unfinished_attic(space) or Geometry.is_finished_attic(space) ) # vented attic, unvented attic, cape cod
        elsif surface.surfaceType.downcase == "roofceiling" and surface.outsideBoundaryCondition.downcase == "outdoors" and Geometry.is_living(space) # cathedral ceiling, flat roof
        else
          next
        end
        attached_to_roofs[space] = roof
      end
    end
      
    attached_to_roofs.each do |space, roof|
      space.surfaces.each do |surface|
        if surface.surfaceType.downcase == "floor" and ( Geometry.is_unfinished_attic(space) or Geometry.is_finished_attic(space) ) # vented attic, unvented attic, cape cod
        elsif surface.surfaceType.downcase == "roofceiling" and surface.outsideBoundaryCondition.downcase == "outdoors" and Geometry.is_living(space) # cathedral ceiling, flat roof
        else
          next
        end
        attic = attics.add_element "Attic"
        XMLHelper.add_attribute(attic.add_element("SystemIdentifier"), "id", "#{space.name} #{get_exterior_adjacent_to(surface)}")
        XMLHelper.add_attribute(attic.add_element("AttachedToRoof"), "idref", roof.elements["SystemIdentifier"].attributes["id"])
        if Geometry.is_unfinished_attic(space)
          if measures["ResidentialAirflow"][0]["unfinished_attic_sla"].to_f == 0
            XMLHelper.add_element(attic, "AtticType", "unvented attic")
          else
            XMLHelper.add_element(attic, "AtticType", "vented attic")
          end
          attic_floor_insulation = attic.add_element "AtticFloorInsulation" # FIXME: what about uninsulated surfaces (e.g., above garage)?
          XMLHelper.add_attribute(attic_floor_insulation.add_element("SystemIdentifier"), "id", "#{space.name} #{get_exterior_adjacent_to(surface)} floor ins")
          XMLHelper.add_element(attic_floor_insulation, "InsulationGrade", os_to_hpxml_ins_grade(measures["ResidentialConstructionsCeilingsRoofsUnfinishedAttic"][0]["ceil_grade"]))
          layer = attic_floor_insulation.add_element "Layer"
          XMLHelper.add_element(layer, "InstallationType", "cavity")
          XMLHelper.add_element(layer, "NominalRValue", measures["ResidentialConstructionsCeilingsRoofsUnfinishedAttic"][0]["ceil_r"])
          XMLHelper.add_element(layer, "Thickness", measures["ResidentialConstructionsCeilingsRoofsUnfinishedAttic"][0]["ceil_ins_thick_in"])
          layer = attic_floor_insulation.add_element "Layer"
          XMLHelper.add_element(layer, "InstallationType", "continuous")
          XMLHelper.add_element(layer, "NominalRValue", 0) # FIXME: can this be specified somewhere?
          XMLHelper.add_element(layer, "Thickness", 0) # FIXME: can this be specified somewhere?          
          attic_roof_insulation = attic.add_element "AtticRoofInsulation"
          XMLHelper.add_attribute(attic_roof_insulation.add_element("SystemIdentifier"), "id", "#{space.name} #{get_exterior_adjacent_to(surface)} roof ins")
          XMLHelper.add_element(attic_roof_insulation, "InsulationGrade", os_to_hpxml_ins_grade(measures["ResidentialConstructionsCeilingsRoofsUnfinishedAttic"][0]["roof_cavity_grade"]))
          layer = attic_roof_insulation.add_element "Layer"
          XMLHelper.add_element(layer, "InstallationType", "cavity")
          XMLHelper.add_element(layer, "NominalRValue", measures["ResidentialConstructionsCeilingsRoofsUnfinishedAttic"][0]["roof_cavity_r"])
          XMLHelper.add_element(layer, "Thickness", measures["ResidentialConstructionsCeilingsRoofsUnfinishedAttic"][0]["roof_cavity_ins_thick_in"])        
          layer = attic_roof_insulation.add_element "Layer"
          XMLHelper.add_element(layer, "InstallationType", "continuous")
          XMLHelper.add_element(layer, "NominalRValue", measures["ResidentialConstructionsCeilingsRoofsSheathing"][0]["rigid_r"])
          XMLHelper.add_element(layer, "Thickness", measures["ResidentialConstructionsCeilingsRoofsSheathing"][0]["rigid_thick_in"])        
          XMLHelper.add_element(attic, "Area", OpenStudio.convert(surface.grossArea,"m^2","ft^2").get.round(1))          
          rafters = attic.add_element "Rafters"
          XMLHelper.add_element(rafters, "Size", get_studs_size_from_thickness(measures["ResidentialConstructionsCeilingsRoofsUnfinishedAttic"][0]["roof_fram_thick_in"]))
          XMLHelper.add_element(rafters, "FramingFactor", measures["ResidentialConstructionsCeilingsRoofsUnfinishedAttic"][0]["roof_ff"])
          XMLHelper.add_element(rafters, "Material", "wood")
          extension = attic.add_element "extension"
          floor_joists = extension.add_element "FloorJoists"
          XMLHelper.add_element(floor_joists, "Material", "wood")
          XMLHelper.add_element(floor_joists, "FramingFactor", measures["ResidentialConstructionsCeilingsRoofsUnfinishedAttic"][0]["ceil_ff"])
          XMLHelper.add_element(extension, "FloorAdjacentTo", get_exterior_adjacent_to(surface))
        elsif Geometry.is_finished_attic(space)
          XMLHelper.add_element(attic, "AtticType", "cape cod")
          attic_floor_insulation = attic.add_element "AtticFloorInsulation" # FIXME: what about uninsulated surfaces (e.g., above garage)?
          XMLHelper.add_attribute(attic_floor_insulation.add_element("SystemIdentifier"), "id", "#{space.name} #{get_exterior_adjacent_to(surface)} floor ins")
          XMLHelper.add_element(attic_floor_insulation, "InsulationGrade", os_to_hpxml_ins_grade(measures["ResidentialConstructionsCeilingsRoofsFinishedRoof"][0]["install_grade"]))
          layer = attic_floor_insulation.add_element "Layer"
          XMLHelper.add_element(layer, "InstallationType", "cavity")
          XMLHelper.add_element(layer, "NominalRValue", measures["ResidentialConstructionsCeilingsRoofsFinishedRoof"][0]["cavity_r"])
          XMLHelper.add_element(layer, "Thickness", 0) # FIXME: can this be specified somewhere?
          layer = attic_floor_insulation.add_element "Layer"
          XMLHelper.add_element(layer, "InstallationType", "continuous")
          XMLHelper.add_element(layer, "NominalRValue", 0) # FIXME: can this be specified somewhere?
          XMLHelper.add_element(layer, "Thickness", 0) # FIXME: can this be specified somewhere?
          attic_roof_insulation = attic.add_element "AtticRoofInsulation"
          XMLHelper.add_attribute(attic_roof_insulation.add_element("SystemIdentifier"), "id", "#{space.name} #{get_exterior_adjacent_to(surface)} roof ins")
          XMLHelper.add_element(attic_roof_insulation, "InsulationGrade", os_to_hpxml_ins_grade(measures["ResidentialConstructionsCeilingsRoofsFinishedRoof"][0]["install_grade"]))
          layer = attic_roof_insulation.add_element "Layer"
          XMLHelper.add_element(layer, "InstallationType", "cavity")
          XMLHelper.add_element(layer, "NominalRValue", measures["ResidentialConstructionsCeilingsRoofsFinishedRoof"][0]["cavity_r"])
          XMLHelper.add_element(layer, "Thickness", 0) # FIXME: can this be specified somewhere?
          layer = attic_roof_insulation.add_element "Layer"
          XMLHelper.add_element(layer, "InstallationType", "continuous")
          XMLHelper.add_element(layer, "NominalRValue", measures["ResidentialConstructionsCeilingsRoofsSheathing"][0]["rigid_r"])
          XMLHelper.add_element(layer, "Thickness", measures["ResidentialConstructionsCeilingsRoofsSheathing"][0]["rigid_thick_in"])
          XMLHelper.add_element(attic, "Area", OpenStudio.convert(surface.grossArea,"m^2","ft^2").get.round(1))
          rafters = attic.add_element "Rafters"
          XMLHelper.add_element(rafters, "Size", get_studs_size_from_thickness(measures["ResidentialConstructionsCeilingsRoofsFinishedRoof"][0]["cavity_depth"]))
          XMLHelper.add_element(rafters, "FramingFactor", measures["ResidentialConstructionsCeilingsRoofsFinishedRoof"][0]["framing_factor"])
          XMLHelper.add_element(rafters, "Material", "wood")
          extension = attic.add_element "extension"
          floor_joists = extension.add_element "FloorJoists"
          XMLHelper.add_element(floor_joists, "Material", "wood")
          XMLHelper.add_element(floor_joists, "FramingFactor", measures["ResidentialConstructionsCeilingsRoofsFinishedRoof"][0]["framing_factor"])
          XMLHelper.add_element(extension, "FloorAdjacentTo", get_exterior_adjacent_to(surface))
        elsif Geometry.is_living(space)
          XMLHelper.add_element(attic, "AtticType", "cathedral ceiling")
          attic_roof_insulation = attic.add_element "AtticRoofInsulation"
          XMLHelper.add_attribute(attic_roof_insulation.add_element("SystemIdentifier"), "id", "#{space.name} #{get_exterior_adjacent_to(surface)} roof ins")
          XMLHelper.add_element(attic_roof_insulation, "InsulationGrade", os_to_hpxml_ins_grade(measures["ResidentialConstructionsCeilingsRoofsFinishedRoof"][0]["install_grade"]))
          layer = attic_roof_insulation.add_element "Layer"
          XMLHelper.add_element(layer, "InstallationType", "cavity")
          XMLHelper.add_element(layer, "NominalRValue", measures["ResidentialConstructionsCeilingsRoofsFinishedRoof"][0]["cavity_r"])
          XMLHelper.add_element(layer, "Thickness", 0) # FIXME: can this be specified somewhere?
          layer = attic_roof_insulation.add_element "Layer"
          XMLHelper.add_element(layer, "InstallationType", "continuous")
          XMLHelper.add_element(layer, "NominalRValue", measures["ResidentialConstructionsCeilingsRoofsSheathing"][0]["rigid_r"])
          XMLHelper.add_element(layer, "Thickness", measures["ResidentialConstructionsCeilingsRoofsSheathing"][0]["rigid_thick_in"])
          XMLHelper.add_element(attic, "Area", OpenStudio.convert(surface.grossArea,"m^2","ft^2").get.round(1))
          rafters = attic.add_element "Rafters"
          XMLHelper.add_element(rafters, "Size", get_studs_size_from_thickness(measures["ResidentialConstructionsCeilingsRoofsFinishedRoof"][0]["cavity_depth"]))
          XMLHelper.add_element(rafters, "FramingFactor", measures["ResidentialConstructionsCeilingsRoofsFinishedRoof"][0]["framing_factor"])
          XMLHelper.add_element(rafters, "Material", "wood")
          extension = attic.add_element "extension"
          floor_joists = extension.add_element "FloorJoists"
          XMLHelper.add_element(floor_joists, "Material", "wood")
          XMLHelper.add_element(floor_joists, "FramingFactor", measures["ResidentialConstructionsCeilingsRoofsFinishedRoof"][0]["framing_factor"])
          XMLHelper.add_element(extension, "FloorAdjacentTo", get_exterior_adjacent_to(surface))
        end
      end
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
          XMLHelper.add_element(slab, "Area", OpenStudio.convert(surface.grossArea,"m^2","ft^2").get.round(1))
          l, w, h = Geometry.get_surface_dimensions(surface)
          XMLHelper.add_element(slab, "ExposedPerimeter", OpenStudio.convert(2*w+2*l,"m","ft").get.round(1))
          XMLHelper.add_element(slab, "PerimeterInsulationDepth", measures["ResidentialConstructionsFoundationsFloorsSlab"][0]["ext_depth"])
          XMLHelper.add_element(slab, "UnderSlabInsulationWidth", measures["ResidentialConstructionsFoundationsFloorsSlab"][0]["perim_width"])
          perimeter_insulation = slab.add_element "PerimeterInsulation"
          XMLHelper.add_attribute(perimeter_insulation.add_element("SystemIdentifier"), "id", "#{surface.name} exterior ins")
          layer = perimeter_insulation.add_element "Layer"
          XMLHelper.add_element(layer, "InstallationType", "continuous")
          XMLHelper.add_element(layer, "NominalRValue", measures["ResidentialConstructionsFoundationsFloorsSlab"][0]["ext_r"])
          XMLHelper.add_element(layer, "Thickness", measures["ResidentialConstructionsFoundationsFloorsSlab"][0]["ext_depth"])
          under_slab_insulation = slab.add_element "UnderSlabInsulation"
          XMLHelper.add_attribute(under_slab_insulation.add_element("SystemIdentifier"), "id", "#{surface.name} perimeter ins")
          layer = under_slab_insulation.add_element "Layer"
          XMLHelper.add_element(layer, "InstallationType", "continuous")
          XMLHelper.add_element(layer, "NominalRValue", measures["ResidentialConstructionsFoundationsFloorsSlab"][0]["perim_r"])
          XMLHelper.add_element(layer, "Thickness", measures["ResidentialConstructionsFoundationsFloorsSlab"][0]["perim_width"])
          extension = slab.add_element "extension"
          XMLHelper.add_element(extension, "CarpetFraction", measures["ResidentialConstructionsFoundationsFloorsCovering"][0]["covering_frac"])
          XMLHelper.add_element(extension, "CarpetRValue", measures["ResidentialConstructionsFoundationsFloorsCovering"][0]["covering_r"])
        end
      end
    end
    
    # Finished Basement
    model.getSpaces.each do |space|
      if Geometry.is_finished_basement(space)
        foundation = foundations.add_element "Foundation"
        XMLHelper.add_attribute(foundation.add_element("SystemIdentifier"), "id", "foundation #{space.name}")
        foundation_type = foundation.add_element "FoundationType"
        basement = foundation_type.add_element "Basement"
        XMLHelper.add_element(basement, "Conditioned", true)
        space.surfaces.each do |surface|
          if surface.surfaceType.downcase == "roofceiling"
            frame_floor = foundation.add_element "FrameFloor"
            XMLHelper.add_attribute(frame_floor.add_element("SystemIdentifier"), "id", surface.name)
            floor_joists = frame_floor.add_element "FloorJoists"
            XMLHelper.add_element(floor_joists, "Size", get_studs_size_from_thickness(measures["ResidentialConstructionsFoundationsFloorsBasementFinished"][0]["ceil_joist_height"]))
            XMLHelper.add_element(floor_joists, "FramingFactor", measures["ResidentialConstructionsFoundationsFloorsBasementFinished"][0]["ceil_ff"])
            XMLHelper.add_element(floor_joists, "Material", "wood")
            XMLHelper.add_element(frame_floor, "Area", OpenStudio.convert(surface.grossArea,"m^2","ft^2").get.round(1))
            insulation = frame_floor.add_element "Insulation"
            XMLHelper.add_attribute(insulation.add_element("SystemIdentifier"), "id", "#{surface.name} ceil ins")
            XMLHelper.add_element(insulation, "InsulationGrade", 1)
            layer = insulation.add_element "Layer"
            XMLHelper.add_element(layer, "InstallationType", "cavity")
            XMLHelper.add_element(layer, "NominalRValue", 0)
            XMLHelper.add_element(layer, "Thickness", 0)
            layer = insulation.add_element "Layer"
            XMLHelper.add_element(layer, "InstallationType", "continuous")
            XMLHelper.add_element(layer, "NominalRValue", 0)
            XMLHelper.add_element(layer, "Thickness", 0)
            extension = frame_floor.add_element "extension"
            XMLHelper.add_element(extension, "AdjacentTo", get_exterior_adjacent_to(surface))
            XMLHelper.add_element(extension, "CarpetFraction", measures["ResidentialConstructionsFoundationsFloorsCovering"][0]["covering_frac"])
            XMLHelper.add_element(extension, "CarpetRValue", measures["ResidentialConstructionsFoundationsFloorsCovering"][0]["covering_r"])
          end
        end
        space.surfaces.each do |surface|          
          if surface.surfaceType.downcase == "wall"
            foundation_wall = foundation.add_element "FoundationWall"
            XMLHelper.add_attribute(foundation_wall.add_element("SystemIdentifier"), "id", surface.name)
            l, w, h = Geometry.get_surface_dimensions(surface)
            XMLHelper.add_element(foundation_wall, "Length", OpenStudio.convert([l, w].max,"m","ft").get.round(1))
            XMLHelper.add_element(foundation_wall, "Height", OpenStudio.convert(h,"m","ft").get.round(1))
            XMLHelper.add_element(foundation_wall, "Area", OpenStudio.convert(surface.grossArea,"m^2","ft^2").get.round(1))
            XMLHelper.add_element(foundation_wall, "BelowGradeDepth", (Geometry.getSurfaceZValues([surface]).min + Geometry.get_z_origin_for_zone(space.thermalZone.get)).abs.round(1))
            XMLHelper.add_element(foundation_wall, "AdjacentTo", "ground")
            interior_studs = foundation_wall.add_element "InteriorStuds"
            if measures["ResidentialConstructionsFoundationsFloorsBasementFinished"][0]["wall_cavity_depth"].to_f > 0
              XMLHelper.add_element(interior_studs, "Size", get_studs_size_from_thickness(measures["ResidentialConstructionsFoundationsFloorsBasementFinished"][0]["wall_cavity_depth"]))
            end
            XMLHelper.add_element(interior_studs, "FramingFactor", measures["ResidentialConstructionsFoundationsFloorsBasementFinished"][0]["wall_ff"])
            XMLHelper.add_element(interior_studs, "Material", "wood")
            insulation = foundation_wall.add_element "Insulation"
            XMLHelper.add_attribute(insulation.add_element("SystemIdentifier"), "id", "#{surface.name} wall ins")
            XMLHelper.add_element(insulation, "InsulationGrade", os_to_hpxml_ins_grade(measures["ResidentialConstructionsFoundationsFloorsBasementFinished"][0]["wall_cavity_grade"]))
            layer = insulation.add_element "Layer"
            XMLHelper.add_element(layer, "InstallationType", "cavity")
            XMLHelper.add_element(layer, "NominalRValue", measures["ResidentialConstructionsFoundationsFloorsBasementFinished"][0]["wall_cavity_r"])
            XMLHelper.add_element(layer, "Thickness", measures["ResidentialConstructionsFoundationsFloorsBasementFinished"][0]["wall_cavity_depth"])
            layer = insulation.add_element "Layer"
            XMLHelper.add_element(layer, "InstallationType", "continuous")
            XMLHelper.add_element(layer, "NominalRValue", measures["ResidentialConstructionsFoundationsFloorsBasementFinished"][0]["wall_rigid_r"])
            XMLHelper.add_element(layer, "Thickness", measures["ResidentialConstructionsFoundationsFloorsBasementFinished"][0]["wall_rigid_thick_in"])
            extension = layer.add_element "extension"
            XMLHelper.add_element(extension, "InsulationHeight", measures["ResidentialConstructionsFoundationsFloorsBasementFinished"][0]["wall_ins_height"])
            extension = foundation_wall.add_element "extension"
            XMLHelper.add_element(extension, "AdjacentTo", get_exterior_adjacent_to(surface))
          end
        end
        space.surfaces.each do |surface|          
          if surface.surfaceType.downcase == "floor"
            slab = foundation.add_element "Slab"
            XMLHelper.add_attribute(slab.add_element("SystemIdentifier"), "id", surface.name)
            XMLHelper.add_element(slab, "Area", OpenStudio.convert(surface.grossArea,"m^2","ft^2").get.round(1))
            l, w, h = Geometry.get_surface_dimensions(surface)
            XMLHelper.add_element(slab, "ExposedPerimeter", OpenStudio.convert(2*w+2*l,"m","ft").get.round(1))
            XMLHelper.add_element(slab, "PerimeterInsulationDepth", 0) # TODO
            XMLHelper.add_element(slab, "UnderSlabInsulationWidth", 0) # TODO
            XMLHelper.add_element(slab, "DepthBelowGrade", (Geometry.get_space_floor_z(space) + Geometry.get_z_origin_for_zone(space.thermalZone.get)).abs.round(1))
            perimeter_insulation = slab.add_element "PerimeterInsulation"
            XMLHelper.add_attribute(perimeter_insulation.add_element("SystemIdentifier"), "id", "#{surface.name} exterior ins")
            layer = perimeter_insulation.add_element "Layer"
            XMLHelper.add_element(layer, "InstallationType", "continuous")
            XMLHelper.add_element(layer, "NominalRValue", 0) # TODO
            XMLHelper.add_element(layer, "Thickness", 0) # TODO
            under_slab_insulation = slab.add_element "UnderSlabInsulation"
            XMLHelper.add_attribute(under_slab_insulation.add_element("SystemIdentifier"), "id", "#{surface.name} perimeter ins")
            layer = under_slab_insulation.add_element "Layer"
            XMLHelper.add_element(layer, "InstallationType", "continuous")
            XMLHelper.add_element(layer, "NominalRValue", 0) # TODO
            XMLHelper.add_element(layer, "Thickness", 0) # TODO
            extension = slab.add_element "extension"
            XMLHelper.add_element(extension, "CarpetFraction", measures["ResidentialConstructionsFoundationsFloorsCovering"][0]["covering_frac"])
            XMLHelper.add_element(extension, "CarpetRValue", measures["ResidentialConstructionsFoundationsFloorsCovering"][0]["covering_r"])
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
        XMLHelper.add_element(basement, "Conditioned", false)
        space.surfaces.each do |surface|
          if surface.surfaceType.downcase == "roofceiling"
            frame_floor = foundation.add_element "FrameFloor"
            XMLHelper.add_attribute(frame_floor.add_element("SystemIdentifier"), "id", surface.name)
            floor_joists = frame_floor.add_element "FloorJoists"
            XMLHelper.add_element(floor_joists, "Size", get_studs_size_from_thickness(measures["ResidentialConstructionsFoundationsFloorsBasementUnfinished"][0]["ceil_joist_height"]))
            XMLHelper.add_element(floor_joists, "FramingFactor", measures["ResidentialConstructionsFoundationsFloorsBasementUnfinished"][0]["ceil_ff"])
            XMLHelper.add_element(floor_joists, "Material", "wood")
            XMLHelper.add_element(frame_floor, "Area", OpenStudio.convert(surface.grossArea,"m^2","ft^2").get.round(1))
            insulation = frame_floor.add_element "Insulation"
            XMLHelper.add_attribute(insulation.add_element("SystemIdentifier"), "id", "#{surface.name} ceil ins")
            XMLHelper.add_element(insulation, "InsulationGrade", os_to_hpxml_ins_grade(measures["ResidentialConstructionsFoundationsFloorsBasementUnfinished"][0]["ceil_cavity_grade"]))
            layer = insulation.add_element "Layer"
            XMLHelper.add_element(layer, "InstallationType", "cavity")
            XMLHelper.add_element(layer, "NominalRValue", measures["ResidentialConstructionsFoundationsFloorsBasementUnfinished"][0]["ceil_cavity_r"])
            XMLHelper.add_element(layer, "Thickness", measures["ResidentialConstructionsFoundationsFloorsBasementUnfinished"][0]["ceil_joist_height"])
            layer = insulation.add_element "Layer"
            XMLHelper.add_element(layer, "InstallationType", "continuous")
            XMLHelper.add_element(layer, "NominalRValue", 0)
            XMLHelper.add_element(layer, "Thickness", 0)            
            extension = frame_floor.add_element "extension"
            XMLHelper.add_element(extension, "AdjacentTo", get_exterior_adjacent_to(surface))
            XMLHelper.add_element(extension, "CarpetFraction", measures["ResidentialConstructionsFoundationsFloorsCovering"][0]["covering_frac"])
            XMLHelper.add_element(extension, "CarpetRValue", measures["ResidentialConstructionsFoundationsFloorsCovering"][0]["covering_r"])
          end
        end
        space.surfaces.each do |surface|          
          if surface.surfaceType.downcase == "wall"
            foundation_wall = foundation.add_element "FoundationWall"
            XMLHelper.add_attribute(foundation_wall.add_element("SystemIdentifier"), "id", surface.name)
            l, w, h = Geometry.get_surface_dimensions(surface)
            XMLHelper.add_element(foundation_wall, "Length", OpenStudio.convert([l, w].max,"m","ft").get.round(1))
            XMLHelper.add_element(foundation_wall, "Height", OpenStudio.convert(h,"m","ft").get.round(1))
            XMLHelper.add_element(foundation_wall, "Area", OpenStudio.convert(surface.grossArea,"m^2","ft^2").get.round(1))
            XMLHelper.add_element(foundation_wall, "BelowGradeDepth", (Geometry.getSurfaceZValues([surface]).min + Geometry.get_z_origin_for_zone(space.thermalZone.get)).abs.round(1))
            XMLHelper.add_element(foundation_wall, "AdjacentTo", "ground")
            interior_studs = foundation_wall.add_element "InteriorStuds"
            if measures["ResidentialConstructionsFoundationsFloorsBasementUnfinished"][0]["wall_cavity_depth"].to_f > 0
              XMLHelper.add_element(interior_studs, "Size", get_studs_size_from_thickness(measures["ResidentialConstructionsFoundationsFloorsBasementUnfinished"][0]["wall_cavity_depth"]))
            end
            XMLHelper.add_element(interior_studs, "FramingFactor", measures["ResidentialConstructionsFoundationsFloorsBasementUnfinished"][0]["wall_ff"])
            XMLHelper.add_element(interior_studs, "Material", "wood")
            insulation = foundation_wall.add_element "Insulation"
            XMLHelper.add_attribute(insulation.add_element("SystemIdentifier"), "id", "#{surface.name} wall ins")
            XMLHelper.add_element(insulation, "InsulationGrade", os_to_hpxml_ins_grade(measures["ResidentialConstructionsFoundationsFloorsBasementUnfinished"][0]["wall_cavity_grade"]))
            layer = insulation.add_element "Layer"
            XMLHelper.add_element(layer, "InstallationType", "cavity")
            XMLHelper.add_element(layer, "NominalRValue", measures["ResidentialConstructionsFoundationsFloorsBasementUnfinished"][0]["wall_cavity_r"])
            XMLHelper.add_element(layer, "Thickness", measures["ResidentialConstructionsFoundationsFloorsBasementUnfinished"][0]["wall_cavity_depth"])
            layer = insulation.add_element "Layer"
            XMLHelper.add_element(layer, "InstallationType", "continuous")
            XMLHelper.add_element(layer, "NominalRValue", measures["ResidentialConstructionsFoundationsFloorsBasementUnfinished"][0]["wall_rigid_r"])
            XMLHelper.add_element(layer, "Thickness", measures["ResidentialConstructionsFoundationsFloorsBasementUnfinished"][0]["wall_rigid_thick_in"])
            extension = layer.add_element "extension"
            XMLHelper.add_element(extension, "InsulationHeight", measures["ResidentialConstructionsFoundationsFloorsBasementUnfinished"][0]["wall_ins_height"])
            extension = foundation_wall.add_element "extension"
            XMLHelper.add_element(extension, "AdjacentTo", get_exterior_adjacent_to(surface))
          end
        end
        space.surfaces.each do |surface|          
          if surface.surfaceType.downcase == "floor"
            slab = foundation.add_element "Slab"
            XMLHelper.add_attribute(slab.add_element("SystemIdentifier"), "id", surface.name)
            XMLHelper.add_element(slab, "Area", OpenStudio.convert(surface.grossArea,"m^2","ft^2").get.round(1))
            l, w, h = Geometry.get_surface_dimensions(surface)
            XMLHelper.add_element(slab, "ExposedPerimeter", OpenStudio.convert(2*w+2*l,"m","ft").get.round(1))
            XMLHelper.add_element(slab, "PerimeterInsulationDepth", 0) # TODO
            XMLHelper.add_element(slab, "UnderSlabInsulationWidth", 0) # TODO             
            XMLHelper.add_element(slab, "DepthBelowGrade", (Geometry.get_space_floor_z(space) + Geometry.get_z_origin_for_zone(space.thermalZone.get)).abs.round(1))
            perimeter_insulation = slab.add_element "PerimeterInsulation"
            XMLHelper.add_attribute(perimeter_insulation.add_element("SystemIdentifier"), "id", "#{surface.name} exterior ins")
            layer = perimeter_insulation.add_element "Layer"
            XMLHelper.add_element(layer, "InstallationType", "continuous")
            XMLHelper.add_element(layer, "NominalRValue", 0) # TODO
            XMLHelper.add_element(layer, "Thickness", 0) # TODO
            under_slab_insulation = slab.add_element "UnderSlabInsulation"
            XMLHelper.add_attribute(under_slab_insulation.add_element("SystemIdentifier"), "id", "#{surface.name} perimeter ins")
            layer = under_slab_insulation.add_element "Layer"
            XMLHelper.add_element(layer, "InstallationType", "continuous")
            XMLHelper.add_element(layer, "NominalRValue", 0) # TODO
            XMLHelper.add_element(layer, "Thickness", 0) # TODO
            extension = slab.add_element "extension"
            XMLHelper.add_element(extension, "CarpetFraction", measures["ResidentialConstructionsFoundationsFloorsCovering"][0]["covering_frac"])
            XMLHelper.add_element(extension, "CarpetRValue", measures["ResidentialConstructionsFoundationsFloorsCovering"][0]["covering_r"])            
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
        if measures["ResidentialAirflow"][0]["crawl_ach"].to_f == 0
          XMLHelper.add_element(crawl, "Vented", "false")
        else
          XMLHelper.add_element(crawl, "Vented", "true")
        end
        space.surfaces.each do |surface|
          if surface.surfaceType.downcase == "roofceiling"
            frame_floor = foundation.add_element "FrameFloor"
            XMLHelper.add_attribute(frame_floor.add_element("SystemIdentifier"), "id", surface.name)
            floor_joists = frame_floor.add_element "FloorJoists"
            XMLHelper.add_element(floor_joists, "Size", get_studs_size_from_thickness(measures["ResidentialConstructionsFoundationsFloorsCrawlspace"][0]["ceil_joist_height"]))
            XMLHelper.add_element(floor_joists, "FramingFactor", measures["ResidentialConstructionsFoundationsFloorsCrawlspace"][0]["ceil_ff"])
            XMLHelper.add_element(floor_joists, "Material", "wood")
            XMLHelper.add_element(frame_floor, "Area", OpenStudio.convert(surface.grossArea,"m^2","ft^2").get.round(1))
            insulation = frame_floor.add_element "Insulation"
            XMLHelper.add_attribute(insulation.add_element("SystemIdentifier"), "id", "#{surface.name} ceil ins")
            XMLHelper.add_element(insulation, "InsulationGrade", os_to_hpxml_ins_grade(measures["ResidentialConstructionsFoundationsFloorsCrawlspace"][0]["ceil_cavity_grade"]))
            layer = insulation.add_element "Layer"
            XMLHelper.add_element(layer, "InstallationType", "cavity")
            XMLHelper.add_element(layer, "NominalRValue", measures["ResidentialConstructionsFoundationsFloorsCrawlspace"][0]["ceil_cavity_r"])
            XMLHelper.add_element(layer, "Thickness", measures["ResidentialConstructionsFoundationsFloorsCrawlspace"][0]["ceil_joist_height"])
            layer = insulation.add_element "Layer"
            XMLHelper.add_element(layer, "InstallationType", "continuous")
            XMLHelper.add_element(layer, "NominalRValue", 0) # TODO
            XMLHelper.add_element(layer, "Thickness", 0) # TODO
            extension = frame_floor.add_element "extension"
            XMLHelper.add_element(extension, "AdjacentTo", get_exterior_adjacent_to(surface))
            XMLHelper.add_element(extension, "CarpetFraction", measures["ResidentialConstructionsFoundationsFloorsCovering"][0]["covering_frac"])
            XMLHelper.add_element(extension, "CarpetRValue", measures["ResidentialConstructionsFoundationsFloorsCovering"][0]["covering_r"])
          end
        end
        space.surfaces.each do |surface|
          if surface.surfaceType.downcase == "wall"
            foundation_wall = foundation.add_element "FoundationWall"
            XMLHelper.add_attribute(foundation_wall.add_element("SystemIdentifier"), "id", surface.name)
            l, w, h = Geometry.get_surface_dimensions(surface)
            XMLHelper.add_element(foundation_wall, "Length", OpenStudio.convert([l, w].max,"m","ft").get.round(1))
            XMLHelper.add_element(foundation_wall, "Height", OpenStudio.convert(h,"m","ft").get.round(1))
            XMLHelper.add_element(foundation_wall, "Area", OpenStudio.convert(surface.grossArea,"m^2","ft^2").get.round(1))
            XMLHelper.add_element(foundation_wall, "BelowGradeDepth", (Geometry.getSurfaceZValues([surface]).min + Geometry.get_z_origin_for_zone(space.thermalZone.get)).abs.round(1))
            XMLHelper.add_element(foundation_wall, "AdjacentTo", "ground")
            interior_studs = foundation_wall.add_element "InteriorStuds"
            XMLHelper.add_element(interior_studs, "FramingFactor", 0.25) # TODO
            XMLHelper.add_element(interior_studs, "Material", "wood")
            insulation = foundation_wall.add_element "Insulation"
            XMLHelper.add_attribute(insulation.add_element("SystemIdentifier"), "id", "#{surface.name} wall ins")
            XMLHelper.add_element(insulation, "InsulationGrade", 1)
            layer = insulation.add_element "Layer"
            XMLHelper.add_element(layer, "InstallationType", "cavity") # TODO
            XMLHelper.add_element(layer, "NominalRValue", 0) # TODO
            XMLHelper.add_element(layer, "Thickness", 0) # TODO 
            layer = insulation.add_element "Layer"
            XMLHelper.add_element(layer, "InstallationType", "continuous")
            XMLHelper.add_element(layer, "NominalRValue", measures["ResidentialConstructionsFoundationsFloorsCrawlspace"][0]["wall_rigid_r"])
            XMLHelper.add_element(layer, "Thickness", measures["ResidentialConstructionsFoundationsFloorsCrawlspace"][0]["wall_rigid_thick_in"])
            extension = foundation_wall.add_element "extension"
            XMLHelper.add_element(extension, "AdjacentTo", get_exterior_adjacent_to(surface))
          end
        end
      end
    end
    
    # PierAndBeam
    model.getSpaces.each do |space|
      if Geometry.is_pier_beam(space)
        foundation = foundations.add_element "Foundation"
        XMLHelper.add_attribute(foundation.add_element("SystemIdentifier"), "id", "foundation #{space.name}")
        foundation_type = foundation.add_element "FoundationType"
        crawl = foundation_type.add_element "Ambient"
        space.surfaces.each do |surface|
          if surface.surfaceType.downcase == "roofceiling"
            frame_floor = foundation.add_element "FrameFloor"
            XMLHelper.add_attribute(frame_floor.add_element("SystemIdentifier"), "id", surface.name)
            floor_joists = frame_floor.add_element "FloorJoists"
            XMLHelper.add_element(floor_joists, "FramingFactor", measures["ResidentialConstructionsFoundationsFloorsPierBeam"][0]["framing_factor"])
            XMLHelper.add_element(floor_joists, "Material", "wood")
            XMLHelper.add_element(frame_floor, "Area", OpenStudio.convert(surface.grossArea,"m^2","ft^2").get.round(1))
            insulation = frame_floor.add_element "Insulation"
            XMLHelper.add_attribute(insulation.add_element("SystemIdentifier"), "id", "#{surface.name} ceil ins")
            XMLHelper.add_element(insulation, "InsulationGrade", os_to_hpxml_ins_grade(measures["ResidentialConstructionsFoundationsFloorsPierBeam"][0]["install_grade"]))
            layer = insulation.add_element "Layer"
            XMLHelper.add_element(layer, "InstallationType", "cavity")
            XMLHelper.add_element(layer, "NominalRValue", measures["ResidentialConstructionsFoundationsFloorsPierBeam"][0]["cavity_r"])
            XMLHelper.add_element(layer, "Thickness", 0) # TODO
            layer = insulation.add_element "Layer"
            XMLHelper.add_element(layer, "InstallationType", "continuous")
            XMLHelper.add_element(layer, "NominalRValue", 0)
            XMLHelper.add_element(layer, "Thickness", 0)
            extension = frame_floor.add_element "extension"
            XMLHelper.add_element(extension, "AdjacentTo", get_exterior_adjacent_to(surface))
            XMLHelper.add_element(extension, "CarpetFraction", measures["ResidentialConstructionsFoundationsFloorsCovering"][0]["covering_frac"])
            XMLHelper.add_element(extension, "CarpetRValue", measures["ResidentialConstructionsFoundationsFloorsCovering"][0]["covering_r"])            
          end
        end
      end
    end    

    # Walls
    walls = enclosure.add_element "Walls"
    model.getSpaces.each do |space|
      next unless Geometry.space_is_above_grade(space)
      next if Geometry.is_foundation(space)
      next if Geometry.is_garage(space)
      space.surfaces.each do |surface|
        next unless surface.surfaceType.downcase == "wall"
        next if surface.outsideBoundaryCondition.downcase == "adiabatic"
        wall = walls.add_element "Wall"
        XMLHelper.add_attribute(wall.add_element("SystemIdentifier"), "id", surface.name)
        wall_type = wall.add_element("WallType")
        if measures.keys.include? "ResidentialConstructionsWallsExteriorWoodStud"
          wall_type.add_element("WoodStud")
        elsif measures.keys.include? "ResidentialConstructionsWallsExteriorDoubleWoodStud"
          XMLHelper.add_element(wall_type.add_element("DoubleWoodStud"), "Staggered", measures["ResidentialConstructionsWallsExteriorDoubleWoodStud"][0]["is_staggered"])
        elsif measures.keys.include? "ResidentialConstructionsWallsExteriorSteelStud"        
          wall_type.add_element("SteelFrame")
        elsif measures.keys.include? "ResidentialConstructionsWallsExteriorICF"        
          wall_type.add_element("InsulatedConcreteForms")
        elsif measures.keys.include? "ResidentialConstructionsWallsExteriorSIP"     
          wall_type.add_element("StructurallyInsulatedPanel")
        elsif measures.keys.include? "ResidentialConstructionsWallsExteriorCMU"         
          wall_type.add_element("ConcreteMasonryUnit")
        elsif measures.keys.include? "ResidentialConstructionsWallsExteriorGeneric"         
          wall_type.add_element("Other")
        end
        if measures.keys.include? "ResidentialConstructionsWallsExteriorWoodStud"
          XMLHelper.add_element(wall, "Area", OpenStudio.convert(surface.grossArea,"m^2","ft^2").get.round(1))
          studs = wall.add_element "Studs"
          XMLHelper.add_element(studs, "Size", get_studs_size_from_thickness(measures["ResidentialConstructionsWallsExteriorWoodStud"][0]["cavity_depth"]))
          XMLHelper.add_element(studs, "FramingFactor", measures["ResidentialConstructionsWallsExteriorWoodStud"][0]["framing_factor"])
          XMLHelper.add_element(studs, "Material", "wood")
          XMLHelper.add_element(wall, "Siding", "wood siding") # TODO: ResidentialConstructionsWallsExteriorFinish
          XMLHelper.add_element(wall, "Color", "medium") # TODO: ResidentialConstructionsWallsExteriorFinish
          insulation = wall.add_element "Insulation"
          XMLHelper.add_attribute(insulation.add_element("SystemIdentifier"), "id", "#{wall.elements["SystemIdentifier"].attributes["id"]} ins")
          if get_exterior_adjacent_to(surface) == "ambient"
            XMLHelper.add_element(insulation, "InsulationGrade", os_to_hpxml_ins_grade(measures["ResidentialConstructionsWallsExteriorWoodStud"][0]["install_grade"]))
            layer = insulation.add_element "Layer"
            XMLHelper.add_element(layer, "InstallationType", "cavity")            
            XMLHelper.add_element(layer, "NominalRValue", measures["ResidentialConstructionsWallsExteriorWoodStud"][0]["cavity_r"])
            XMLHelper.add_element(layer, "Thickness", measures["ResidentialConstructionsWallsExteriorWoodStud"][0]["cavity_depth"])
          elsif get_exterior_adjacent_to(surface) == "garage"
            XMLHelper.add_element(insulation, "InsulationGrade", os_to_hpxml_ins_grade(measures["ResidentialConstructionsWallsInterzonal"][0]["install_grade"]))
            layer = insulation.add_element "Layer"
            XMLHelper.add_element(layer, "InstallationType", "cavity")            
            XMLHelper.add_element(layer, "NominalRValue", measures["ResidentialConstructionsWallsInterzonal"][0]["cavity_r"])
            XMLHelper.add_element(layer, "Thickness", measures["ResidentialConstructionsWallsInterzonal"][0]["cavity_depth"])          
          end
        elsif measures.keys.include? "ResidentialConstructionsWallsExteriorDoubleWoodStud"
          XMLHelper.add_element(wall, "Area", OpenStudio.convert(surface.grossArea,"m^2","ft^2").get.round(1))
          studs = wall.add_element "Studs"
          XMLHelper.add_element(studs, "Size", get_studs_size_from_thickness(measures["ResidentialConstructionsWallsExteriorDoubleWoodStud"][0]["stud_depth"]))
          XMLHelper.add_element(studs, "Spacing", measures[ "ResidentialConstructionsWallsExteriorDoubleWoodStud"][0]["framing_spacing"])
          XMLHelper.add_element(studs, "FramingFactor", measures["ResidentialConstructionsWallsExteriorDoubleWoodStud"][0]["framing_factor"])
          XMLHelper.add_element(studs, "Material", "wood")
          XMLHelper.add_element(wall, "Siding", "wood siding") # TODO: ResidentialConstructionsWallsExteriorFinish
          XMLHelper.add_element(wall, "Color", "medium") # TODO: ResidentialConstructionsWallsExteriorFinish
          insulation = wall.add_element "Insulation"
          XMLHelper.add_attribute(insulation.add_element("SystemIdentifier"), "id", "#{wall.elements["SystemIdentifier"].attributes["id"]} ins")
          XMLHelper.add_element(insulation, "InsulationGrade", os_to_hpxml_ins_grade(measures["ResidentialConstructionsWallsExteriorDoubleWoodStud"][0]["install_grade"]))
          layer = insulation.add_element "Layer"
          XMLHelper.add_element(layer, "InstallationType", "cavity")        
          XMLHelper.add_element(layer, "NominalRValue", measures["ResidentialConstructionsWallsExteriorDoubleWoodStud"][0]["cavity_r"])
          XMLHelper.add_element(layer, "Thickness", measures["ResidentialConstructionsWallsExteriorDoubleWoodStud"][0]["stud_depth"])
        elsif measures.keys.include? "ResidentialConstructionsWallsExteriorSteelStud"
          XMLHelper.add_element(wall, "Area", OpenStudio.convert(surface.grossArea,"m^2","ft^2").get.round(1))
          studs = wall.add_element "Studs"
          XMLHelper.add_element(studs, "Size", get_studs_size_from_thickness(measures["ResidentialConstructionsWallsExteriorSteelStud"][0]["cavity_depth"]))
          XMLHelper.add_element(studs, "FramingFactor", measures["ResidentialConstructionsWallsExteriorSteelStud"][0]["framing_factor"])
          XMLHelper.add_element(studs, "Material", "metal")
          XMLHelper.add_element(wall, "Siding", "wood siding") # TODO: ResidentialConstructionsWallsExteriorFinish
          XMLHelper.add_element(wall, "Color", "medium") # TODO: ResidentialConstructionsWallsExteriorFinish
          insulation = wall.add_element "Insulation"
          XMLHelper.add_attribute(insulation.add_element("SystemIdentifier"), "id", "#{wall.elements["SystemIdentifier"].attributes["id"]} ins")
          XMLHelper.add_element(insulation, "InsulationGrade", os_to_hpxml_ins_grade(measures["ResidentialConstructionsWallsExteriorSteelStud"][0]["install_grade"]))
          layer = insulation.add_element "Layer"
          XMLHelper.add_element(layer, "InstallationType", "cavity")        
          XMLHelper.add_element(layer, "NominalRValue", measures["ResidentialConstructionsWallsExteriorSteelStud"][0]["cavity_r"])
          XMLHelper.add_element(layer, "Thickness", measures["ResidentialConstructionsWallsExteriorDoubleWoodStud"][0]["cavity_depth"])
        elsif measures.keys.include? "ResidentialConstructionsWallsExteriorICF"
          XMLHelper.add_element(wall, "Thickness", measures["ResidentialConstructionsWallsExteriorICF"][0]["concrete_thick_in"])
          XMLHelper.add_element(wall, "Area", OpenStudio.convert(surface.grossArea,"m^2","ft^2").get.round(1))
          XMLHelper.add_element(wall, "Siding", "wood siding") # TODO: ResidentialConstructionsWallsExteriorFinish
          XMLHelper.add_element(wall, "Color", "medium") # TODO: ResidentialConstructionsWallsExteriorFinish
          insulation = wall.add_element "Insulation"
          XMLHelper.add_attribute(insulation.add_element("SystemIdentifier"), "id", "#{wall.elements["SystemIdentifier"].attributes["id"]} ins")
          layer = insulation.add_element "Layer"
          XMLHelper.add_element(layer, "InstallationType", "cavity")        
          XMLHelper.add_element(layer, "NominalRValue", measures["ResidentialConstructionsWallsExteriorICF"][0]["icf_r"])
          XMLHelper.add_element(layer, "Thickness", measures["ResidentialConstructionsWallsExteriorICF"][0]["ins_thick_in"])
        elsif measures.keys.include? "ResidentialConstructionsWallsExteriorSIP"
          XMLHelper.add_element(wall, "Area", OpenStudio.convert(surface.grossArea,"m^2","ft^2").get.round(1))
          XMLHelper.add_element(wall, "Siding", "wood siding") # TODO: ResidentialConstructionsWallsExteriorFinish
          XMLHelper.add_element(wall, "Color", "medium") # TODO: ResidentialConstructionsWallsExteriorFinish
          insulation = wall.add_element "Insulation"
          XMLHelper.add_attribute(insulation.add_element("SystemIdentifier"), "id", "#{wall.elements["SystemIdentifier"].attributes["id"]} ins")
          layer = insulation.add_element "Layer"
          XMLHelper.add_element(layer, "InstallationType", "cavity")        
          XMLHelper.add_element(layer, "NominalRValue", measures["ResidentialConstructionsWallsExteriorSIP"]["sip_r"])
          XMLHelper.add_element(layer, "Thickness", measures["ResidentialConstructionsWallsExteriorSIP"]["thick_in"])
          layer = insulation.add_element "Layer"
          XMLHelper.add_element(layer, "InstallationType", "continuous")
          XMLHelper.add_element(layer.add_element("InsulationMaterial"), "Other", measures["ResidentialConstructionsWallsExteriorSIP"][0]["sheathing_type"])
          XMLHelper.add_element(layer, "Thickness", measures["ResidentialConstructionsWallsExteriorSIP"][0]["sheathing_thick_in"])          
        elsif measures.keys.include? "ResidentialConstructionsWallsExteriorCMU"
          XMLHelper.add_element(wall, "Thickness", measures["ResidentialConstructionsWallsExteriorCMU"][0]["thickness"])
          XMLHelper.add_element(wall, "Area", OpenStudio.convert(surface.grossArea,"m^2","ft^2").get.round(1))
          XMLHelper.add_element(wall, "Siding", "wood siding") # TODO: ResidentialConstructionsWallsExteriorFinish
          XMLHelper.add_element(wall, "Color", "medium") # TODO: ResidentialConstructionsWallsExteriorFinish
          insulation = wall.add_element "Insulation"
          XMLHelper.add_attribute(insulation.add_element("SystemIdentifier"), "id", "#{wall.elements["SystemIdentifier"].attributes["id"]} ins")
          layer = insulation.add_element "Layer"
          XMLHelper.add_element(layer, "InstallationType", "cavity")
          XMLHelper.add_element(layer, "NominalRValue", measures["ResidentialConstructionsWallsExteriorCMU"][0]["furring_r"])
          XMLHelper.add_element(layer, "Thickness", measures["ResidentialConstructionsWallsExteriorCMU"][0]["furring_cavity_depth"])
        elsif measures.keys.include? "ResidentialConstructionsWallsExteriorGeneric"
          XMLHelper.add_element(wall, "Area", OpenStudio.convert(surface.grossArea,"m^2","ft^2").get.round(1))
          XMLHelper.add_element(wall, "Siding", "wood siding") # TODO: ResidentialConstructionsWallsExteriorFinish
          XMLHelper.add_element(wall, "Color", "medium") # TODO: ResidentialConstructionsWallsExteriorFinish
          # TODO: fill in properties of this type of wall
        end
        if measures.keys.include? "ResidentialConstructionsWallsSheathing"
          if insulation.nil?
            insulation = wall.add_element "Insulation"
            XMLHelper.add_attribute(insulation.add_element("SystemIdentifier"), "id", "#{wall.elements["SystemIdentifier"].attributes["id"]} ins")
          end
          layer = insulation.add_element "Layer"
          XMLHelper.add_element(layer, "InstallationType", "continuous")
          insulation_material = layer.add_element "InsulationMaterial"
          XMLHelper.add_element(insulation_material, "Rigid", "unknown")
          XMLHelper.add_element(layer, "NominalRValue", measures["ResidentialConstructionsWallsSheathing"][0]["rigid_r"])
          XMLHelper.add_element(layer, "Thickness", measures["ResidentialConstructionsWallsSheathing"][0]["rigid_thick_in"])
        end
        extension = wall.add_element "extension"
        XMLHelper.add_element(extension, "InteriorAdjacentTo", get_interior_adjacent_to(space, measures))
        XMLHelper.add_element(extension, "ExteriorAdjacentTo", get_exterior_adjacent_to(surface))
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
      XMLHelper.add_element(window, "Area", OpenStudio.convert(subsurface.grossArea,"m^2","ft^2").get.round(1))
      XMLHelper.add_element(window, "Azimuth", OpenStudio.convert(subsurface.azimuth,"rad","deg").get.round)
      XMLHelper.add_element(window, "UFactor", measures["ResidentialConstructionsWindows"][0]["ufactor"])
      XMLHelper.add_element(window, "SHGC", measures["ResidentialConstructionsWindows"][0]["shgc"])
      if measures.keys.include? "ResidentialGeometryOverhangs"
        facade = Geometry.get_facade_for_surface(subsurface.surface.get)
        if measures["ResidentialGeometryOverhangs"][0]["#{facade}_facade"] == "true"
          XMLHelper.add_element(window, "ExteriorShading", "external overhangs")
          overhangs = window.add_element "Overhangs"
          XMLHelper.add_element(overhangs, "Depth", OpenStudio.convert(measures["ResidentialGeometryOverhangs"][0]["depth"].to_f,"ft","in").get.round(1))
          XMLHelper.add_element(overhangs, "DistanceToTopOfWindow", OpenStudio.convert(measures["ResidentialGeometryOverhangs"][0]["offset"].to_f,"ft","in").get.round(1))
        end
      end      
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
      XMLHelper.add_element(door, "Area", OpenStudio.convert(subsurface.grossArea,"m^2","ft^2").get.round(1))
      XMLHelper.add_element(door, "Azimuth", OpenStudio.convert(subsurface.azimuth,"rad","deg").get.round)
      XMLHelper.add_element(door, "RValue", 1.0 / measures["ResidentialConstructionsDoors"][0]["door_ufactor"].to_f)
    end
    
    # Enclosure extension for other living space floors over garage, interior shading, eaves
    extension = enclosure.add_element "extension"
    
    # Floors
    floors = nil
    model.getSpaces.each do |space|
      next unless Geometry.space_is_above_grade(space) and Geometry.is_living(space)
      next if Geometry.is_finished_attic(space)
      space.surfaces.each do |surface|
        next unless surface.surfaceType.downcase == "floor"
        next unless surface.adjacentSurface.is_initialized
        next unless Geometry.is_garage(surface.adjacentSurface.get.space.get)
        if floors.nil?
          floors = extension.add_element "Floors"
        end
        floor = floors.add_element "Floor"
        XMLHelper.add_element(floor, "SystemIdentifier", surface.name)
        XMLHelper.add_element(floor, "Area", OpenStudio.convert(surface.grossArea,"m^2","ft^2").get.round(1))
        floor_joists = floor.add_element "FloorJoists"
        XMLHelper.add_element(floor_joists, "Material", "wood")
        XMLHelper.add_element(floor_joists, "FramingFactor", measures["ResidentialConstructionsFoundationsFloorsInterzonalFloors"][0]["framing_factor"])
        insulation = floor.add_element "Insulation"
        XMLHelper.add_element(insulation, "InsulationGrade", os_to_hpxml_ins_grade(measures["ResidentialConstructionsFoundationsFloorsInterzonalFloors"][0]["install_grade"]))
        layer = insulation.add_element "Layer"
        XMLHelper.add_element(layer, "InstallationType", "cavity")        
        XMLHelper.add_element(layer, "NominalRValue", measures["ResidentialConstructionsFoundationsFloorsInterzonalFloors"][0]["cavity_r"])
        XMLHelper.add_element(layer, "Thickness", 3.5) # FIXME
        layer = insulation.add_element "Layer"
        XMLHelper.add_element(layer, "InstallationType", "continuous")        
        XMLHelper.add_element(layer, "NominalRValue", 0)
        XMLHelper.add_element(layer, "Thickness", 0)
        XMLHelper.add_element(floor, "CarpetFraction", measures["ResidentialConstructionsFoundationsFloorsCovering"][0]["covering_frac"])
        XMLHelper.add_element(floor, "CarpetRValue", measures["ResidentialConstructionsFoundationsFloorsCovering"][0]["covering_r"])
        XMLHelper.add_element(floor, "InteriorAdjacentTo", get_interior_adjacent_to(space, measures))
        XMLHelper.add_element(floor, "ExteriorAdjacentTo", get_exterior_adjacent_to(surface))
      end
    end
    
    # InteriorShading
    interior_shading = extension.add_element "interior_shading"
    XMLHelper.add_element(interior_shading, "heating_shade_mult", measures["ResidentialConstructionsWindows"][0]["heating_shade_mult"])
    XMLHelper.add_element(interior_shading, "cooling_shade_mult", measures["ResidentialConstructionsWindows"][0]["cooling_shade_mult"])
    
    # Eaves
    if measures.keys.include? "ResidentialGeometryEaves"      
      eaves = extension.add_element "eaves_options"
      XMLHelper.add_element(eaves, "eaves_depth", measures["ResidentialGeometryEaves"][0]["eaves_depth"])
      XMLHelper.add_element(eaves, "roof_structure", measures["ResidentialGeometryEaves"][0]["roof_structure"])
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
      XMLHelper.add_element(hvac_control, "ControlType", "programmable thermostat")
      XMLHelper.add_element(hvac_control, "SetpointTempHeatingSeason", measures["ResidentialHVACHeatingSetpoints"][0]["htg_wkdy"])
      XMLHelper.add_element(hvac_control, "SetpointTempCoolingSeason", measures["ResidentialHVACCoolingSetpoints"][0]["clg_wkdy"])
      
      if Geometry.is_pier_beam(control_zone)
        loc = "other exterior"
      elsif Geometry.is_crawl(control_zone)
        loc = "crawlspace - vented"
      elsif Geometry.is_finished_basement(control_zone)
        loc = "basement - conditioned"
      elsif Geometry.is_unfinished_basement(control_zone)
        loc = "basement - unconditioned"              
      elsif Geometry.is_unfinished_attic(control_zone)
        loc = "attic - unconditioned"
      elsif Geometry.is_finished_attic(control_zone)
        loc = "conditioned space"
      elsif Geometry.is_garage(control_zone)
        loc = "garage - unconditioned"
      elsif Geometry.is_living(control_zone) or Geometry.zone_is_finished(control_zone)
        loc = "conditioned space"
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
            fuel_type = os_to_hpxml_fuel_map(Constants.FuelTypeElectric)
          elsif measures.keys.include? "ResidentialHVACFurnaceFuel"
            fuel_type = os_to_hpxml_fuel_map(measures["ResidentialHVACFurnaceFuel"][0]["fuel_type"])
          end
          XMLHelper.add_element(heating_system, "HeatingSystemFuel", fuel_type)
          unless measures[get_measure_match(measures, "Furnace")][0]["capacity"] == Constants.SizingAuto
            XMLHelper.add_element(heating_system, "HeatingCapacity", OpenStudio.convert(measures[get_measure_match(measures, "Furnace")][0]["capacity"].to_f,"kBtu/h","Btu/h").get.round(1))
          end
          annual_heat_efficiency = heating_system.add_element "AnnualHeatingEfficiency"
          XMLHelper.add_element(annual_heat_efficiency, "Units", "AFUE")
          XMLHelper.add_element(annual_heat_efficiency, "Value", measures[get_measure_match(measures, "Furnace")][0]["afue"])
          XMLHelper.add_element(heating_system, "FractionHeatLoadServed", 1)
          XMLHelper.add_element(heating_system, "FloorAreaServed", OpenStudio.convert(control_zone.floorArea,"m^2","ft^2").get.round(1))
        end

      end
      
      if HVAC.has_boiler(model, runner, control_zone)
      
        HVAC.existing_heating_equipment(model, runner, control_zone).each do |htg_equip|
          heating_system = hvac_plant.add_element "HeatingSystem"
          htg_coil = HVAC.get_coil_from_hvac_component(htg_equip.heatingCoil)          
          XMLHelper.add_attribute(heating_system.add_element("SystemIdentifier"), "id", htg_coil.name)
          XMLHelper.add_attribute(hvac_control.add_element("HVACSystemsServed"), "idref", heating_system.elements["SystemIdentifier"].attributes["id"])
          XMLHelper.add_attribute(heating_system.add_element("AttachedToZone"), "idref", control_zone.name)
          XMLHelper.add_element(heating_system, "UnitLocation", loc)
          heating_system_type = heating_system.add_element "HeatingSystemType"
          boiler_type = heating_system_type.add_element("Boiler")
          XMLHelper.add_element(boiler_type, "BoilerType", "hot water")
          if measures[get_measure_match(measures, "Boiler")][0]["system_type"] == Constants.BoilerTypeForcedDraft
            XMLHelper.add_element(boiler_type, "SealedCombustion", "true")
          elsif measures[get_measure_match(measures, "Boiler")][0]["system_type"] == Constants.BoilerTypeCondensing
            XMLHelper.add_element(boiler_type, "CondensingSystem", "true")
          elsif measures[get_measure_match(measures, "Boiler")][0]["system_type"] == Constants.BoilerTypeNaturalDraft
            XMLHelper.add_element(boiler_type, "AtmosphericBurner", "true")
          end
          if measures.keys.include? "ResidentialHVACBoilerElectric"
            fuel_type = os_to_hpxml_fuel_map(Constants.FuelTypeElectric)
          elsif measures.keys.include? "ResidentialHVACBoilerFuel"
            fuel_type = os_to_hpxml_fuel_map(measures["ResidentialHVACBoilerFuel"][0]["fuel_type"])
          end
          XMLHelper.add_element(heating_system, "HeatingSystemFuel", fuel_type)
          unless measures[get_measure_match(measures, "Boiler")][0]["capacity"] == Constants.SizingAuto
            XMLHelper.add_element(heating_system, "HeatingCapacity", OpenStudio.convert(measures[get_measure_match(measures, "Boiler")][0]["capacity"].to_f,"kBtu/h","Btu/h").get.round(1))
          end
          annual_heat_efficiency = heating_system.add_element "AnnualHeatingEfficiency"
          XMLHelper.add_element(annual_heat_efficiency, "Units", "AFUE")
          XMLHelper.add_element(annual_heat_efficiency, "Value", measures[get_measure_match(measures, "Boiler")][0]["afue"])
          XMLHelper.add_element(heating_system, "FractionHeatLoadServed", 1)
          XMLHelper.add_element(heating_system, "FloorAreaServed", OpenStudio.convert(control_zone.floorArea,"m^2","ft^2").get.round(1))
        end

      end
      
      if HVAC.has_electric_baseboard(model, runner, control_zone) and measures.keys.include? "ResidentialHVACElectricBaseboard" # not to be confused with mshp's supplemental heater
      
        HVAC.existing_heating_equipment(model, runner, control_zone).each do |htg_equip|
          heating_system = hvac_plant.add_element "HeatingSystem"
          XMLHelper.add_attribute(heating_system.add_element("SystemIdentifier"), "id", htg_equip.name)
          XMLHelper.add_attribute(hvac_control.add_element("HVACSystemsServed"), "idref", heating_system.elements["SystemIdentifier"].attributes["id"])
          XMLHelper.add_attribute(heating_system.add_element("AttachedToZone"), "idref", control_zone.name)
          XMLHelper.add_element(heating_system, "UnitLocation", loc)
          heating_system_type = heating_system.add_element "HeatingSystemType"
          XMLHelper.add_element(heating_system_type.add_element("ElectricResistance"), "ElectricDistribution", "baseboard")          
          XMLHelper.add_element(heating_system, "HeatingSystemFuel", "electricity")
          unless measures["ResidentialHVACElectricBaseboard"][0]["capacity"] == Constants.SizingAuto
            XMLHelper.add_element(heating_system, "HeatingCapacity", OpenStudio.convert(measures["ResidentialHVACElectricBaseboard"][0]["capacity"].to_f,"kBtu/h","Btu/h").get.round(1))
          end
          annual_heat_efficiency = heating_system.add_element "AnnualHeatingEfficiency"
          XMLHelper.add_element(annual_heat_efficiency, "Units", "Percent")
          XMLHelper.add_element(annual_heat_efficiency, "Value", measures["ResidentialHVACElectricBaseboard"][0]["efficiency"])
          XMLHelper.add_element(heating_system, "FractionHeatLoadServed", 1)
          XMLHelper.add_element(heating_system, "FloorAreaServed", OpenStudio.convert(control_zone.floorArea,"m^2","ft^2").get.round(1))
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
          XMLHelper.add_element(cooling_system, "CoolingSystemFuel", "electricity")
          if clg_coil.to_CoilCoolingDXSingleSpeed.is_initialized
            num_sp = "1-Speed"
          elsif clg_coil.to_CoilCoolingDXMultiSpeed.is_initialized
            num_sp = os_to_hpxml_speeds(clg_coil.stages.length)
          end
          unless measures[get_measure_match(measures, "CentralAirConditioner")][0]["capacity"] == Constants.SizingAuto
            XMLHelper.add_element(cooling_system, "CoolingCapacity", OpenStudio.convert(measures[get_measure_match(measures, "CentralAirConditioner")][0]["capacity"].to_f,"ton","Btu/h").get.round(1))
          end
          XMLHelper.add_element(cooling_system, "FractionCoolLoadServed", 1)
          XMLHelper.add_element(cooling_system, "FloorAreaServed", OpenStudio.convert(control_zone.floorArea,"m^2","ft^2").get.round(1))
          annual_cool_efficiency = cooling_system.add_element "AnnualCoolingEfficiency"
          XMLHelper.add_element(annual_cool_efficiency, "Units", "SEER")
          XMLHelper.add_element(annual_cool_efficiency, "Value", measures[get_measure_match(measures, "CentralAirConditioner")][0]["seer"])
          XMLHelper.add_element(cooling_system.add_element("extension"), "NumberSpeeds", num_sp)
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
          XMLHelper.add_element(cooling_system, "CoolingSystemFuel", "electricity")
          unless measures["ResidentialHVACRoomAirConditioner"][0]["capacity"] == Constants.SizingAuto
            XMLHelper.add_element(cooling_system, "CoolingCapacity", OpenStudio.convert(measures["ResidentialHVACRoomAirConditioner"][0]["capacity"].to_f,"ton","Btu/h").get.round(1))
          end
          XMLHelper.add_element(cooling_system, "FractionCoolLoadServed", 1)
          XMLHelper.add_element(cooling_system, "FloorAreaServed", OpenStudio.convert(control_zone.floorArea,"m^2","ft^2").get.round(1))
          annual_cool_efficiency = cooling_system.add_element "AnnualCoolingEfficiency"
          XMLHelper.add_element(annual_cool_efficiency, "Units", "EER")
          XMLHelper.add_element(annual_cool_efficiency, "Value", measures["ResidentialHVACRoomAirConditioner"][0]["eer"])
          XMLHelper.add_element(cooling_system, "SensibleHeatFraction", measures["ResidentialHVACRoomAirConditioner"][0]["shr"])
          XMLHelper.add_element(cooling_system.add_element("extension"), "NumberSpeeds", "1-Speed")
        end
        
      end
      
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
        num_sp = nil
        
        HVAC.existing_heating_equipment(model, runner, control_zone).each do |htg_equip|

          name = htg_equip.name          
          if HVAC.has_air_source_heat_pump(model, runner, control_zone)
            type = "air-to-air"
            clg_coil = HVAC.get_coil_from_hvac_component(htg_equip.coolingCoil.get)
            supp_coil = HVAC.get_coil_from_hvac_component(htg_equip.supplementalHeatingCoil.get)
            unless measures[get_measure_match(measures, "AirSourceHeatPump")][0]["heat_pump_capacity"] == Constants.SizingAuto
              clg_cap = OpenStudio.convert(measures[get_measure_match(measures, "AirSourceHeatPump")][0]["heat_pump_capacity"].to_f,"ton","Btu/h").get.round(1)
              htg_cap = OpenStudio.convert(measures[get_measure_match(measures, "AirSourceHeatPump")][0]["heat_pump_capacity"].to_f,"ton","Btu/h").get.round(1)
            end
            unless measures[get_measure_match(measures, "AirSourceHeatPump")][0]["supplemental_capacity"] == Constants.SizingAuto
              supp_cap = OpenStudio.convert(measures[get_measure_match(measures, "AirSourceHeatPump")][0]["supplemental_capacity"].to_f,"kBtu/h","Btu/h").get.round(1)
            end
            supp_afue = supp_coil.efficiency.round(2)
            clg_eff = measures[get_measure_match(measures, "AirSourceHeatPump")][0]["seer"]
            htg_eff = measures[get_measure_match(measures, "AirSourceHeatPump")][0]["hspf"]
            if clg_coil.to_CoilCoolingDXSingleSpeed.is_initialized
              num_sp = "1-Speed"
            elsif clg_coil.to_CoilCoolingDXMultiSpeed.is_initialized
              num_sp = os_to_hpxml_speeds(clg_coil.stages.length)              
            end            
          elsif HVAC.has_mini_split_heat_pump(model, runner, control_zone)
            type = "mini-split"            
            unless measures["ResidentialHVACMiniSplitHeatPump"][0]["heat_pump_capacity"] == Constants.SizingAuto
              clg_cap = OpenStudio.convert(measures["ResidentialHVACMiniSplitHeatPump"][0]["heat_pump_capacity"].to_f,"ton","Btu/h").get.round(1)
              htg_cap = OpenStudio.convert(measures["ResidentialHVACMiniSplitHeatPump"][0]["heat_pump_capacity"].to_f,"ton","Btu/h").get.round(1)
            end
            unless measures["ResidentialHVACMiniSplitHeatPump"][0]["supplemental_capacity"] == Constants.SizingAuto
              supp_cap = OpenStudio.convert(measures["ResidentialHVACMiniSplitHeatPump"][0]["supplemental_capacity"],"kBtu/h","Btu/h").get.round(1)
            end
            supp_afue = measures["ResidentialHVACMiniSplitHeatPump"][0]["supplemental_efficiency"]
            clg_eff = measures["ResidentialHVACMiniSplitHeatPump"][0]["seer"]
            htg_eff = measures["ResidentialHVACMiniSplitHeatPump"][0]["hspf"]
            num_sp = "Variable-Speed"
          elsif HVAC.has_gshp_vert_bore(model, runner, control_zone)
            type = "ground-to-air"
            supp_coil = HVAC.get_coil_from_hvac_component(htg_equip.supplementalHeatingCoil.get)
            unless measures["ResidentialHVACGroundSourceHeatPumpVerticalBore"][0]["heat_pump_capacity"] == Constants.SizingAuto
              clg_cap = OpenStudio.convert(measures["ResidentialHVACGroundSourceHeatPumpVerticalBore"][0]["heat_pump_capacity"].to_f,"ton","Btu/h").get.round(1)
              htg_cap = OpenStudio.convert(measures["ResidentialHVACGroundSourceHeatPumpVerticalBore"][0]["heat_pump_capacity"].to_f,"ton","Btu/h").get.round(1)
            end           
            unless measures["ResidentialHVACGroundSourceHeatPumpVerticalBore"][0]["supplemental_capacity"] == Constants.SizingAuto
              supp_cap = OpenStudio.convert(measures["ResidentialHVACGroundSourceHeatPumpVerticalBore"][0]["supplemental_capacity"].to_f,"kBtu/h","Btu/h").get.round(1)
            end
            supp_afue = supp_coil.efficiency.round(2)
            clg_eff = measures["ResidentialHVACGroundSourceHeatPumpVerticalBore"][0]["eer"]
            htg_eff = measures["ResidentialHVACGroundSourceHeatPumpVerticalBore"][0]["cop"]
            num_sp = "Variable-Speed"
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
        XMLHelper.add_element(heat_pump, "FractionHeatLoadServed", 1)
        XMLHelper.add_element(heat_pump, "FractionCoolLoadServed", 1)
        XMLHelper.add_element(heat_pump, "FloorAreaServed", OpenStudio.convert(control_zone.floorArea,"m^2","ft^2").get.round(1))
        annual_cool_efficiency = heat_pump.add_element "AnnualCoolEfficiency"
        XMLHelper.add_element(annual_cool_efficiency, "Units", "SEER")
        XMLHelper.add_element(annual_cool_efficiency, "Value", clg_eff)
        annual_heat_efficiency = heat_pump.add_element "AnnualHeatEfficiency"
        XMLHelper.add_element(annual_heat_efficiency, "Units", "HSPF")
        XMLHelper.add_element(annual_heat_efficiency, "Value", htg_eff)
        XMLHelper.add_element(heat_pump.add_element("extension"), "NumberSpeeds", num_sp)

      end

    end
    
    has_forced_air_equipment = false
    model.getBuildingUnits.each do |building_unit|
      Geometry.get_thermal_zones_from_spaces(building_unit.spaces).each do |thermal_zone|
        if Geometry.is_living(thermal_zone)
          model.getAirLoopHVACs.each do |air_loop|
            next unless air_loop.thermalZones.include? thermal_zone
            has_forced_air_equipment = true
          end
        end
      end
    end
    
    if has_forced_air_equipment and not measures["ResidentialAirflow"][0]["duct_location"] == "none"
    
      duct_location = "conditioned space"
      model.getEnergyManagementSystemSensors.each do |sensor|
        next unless sensor.name.to_s == "#{Constants.ObjectNameDucts} u 1 ah t s".gsub(" ","_")
        duct_location = get_duct_location(sensor.keyName)
      end
    
      hvac_distribution = hvac.add_element "HVACDistribution"
      XMLHelper.add_attribute(hvac_distribution.add_element("SystemIdentifier"), "id", Constants.ObjectNameDucts)
      distribution_system_type = hvac_distribution.add_element "DistributionSystemType"
      air_distribution = distribution_system_type.add_element "AirDistribution"
      XMLHelper.add_element(air_distribution, "AirDistributionType", "regular velocity")    
      duct_leakage_measurement = air_distribution.add_element "DuctLeakageMeasurement"
      extension = duct_leakage_measurement.add_element "extension"
      XMLHelper.add_element(extension, "duct_total_leakage", measures["ResidentialAirflow"][0]["duct_total_leakage"])
      XMLHelper.add_element(extension, "duct_supply_frac", measures["ResidentialAirflow"][0]["duct_supply_frac"])
      XMLHelper.add_element(extension, "duct_return_frac", measures["ResidentialAirflow"][0]["duct_return_frac"])
      XMLHelper.add_element(extension, "duct_ah_supply_frac", measures["ResidentialAirflow"][0]["duct_ah_supply_frac"])
      XMLHelper.add_element(extension, "duct_ah_return_frac", measures["ResidentialAirflow"][0]["duct_ah_return_frac"])    
      duct = air_distribution.add_element "Ducts"
      XMLHelper.add_element(duct, "DuctType", "supply")
      XMLHelper.add_element(duct, "DuctInsulationRValue", measures["ResidentialAirflow"][0]["duct_unconditioned_r"])
      XMLHelper.add_element(duct, "DuctLocation", duct_location)
      XMLHelper.add_element(duct, "FractionDuctArea", Airflow.get_duct_location_frac_leakage(measures["ResidentialAirflow"][0]["duct_location_frac"], building_construction.elements["NumberofConditionedFloorsAboveGrade"].text.to_f))
      XMLHelper.add_element(duct, "DuctSurfaceArea", Airflow.get_duct_supply_surface_area(measures["ResidentialAirflow"][0]["duct_supply_area_mult"].to_f, building_construction.elements["ConditionedFloorArea"].text.to_f, building_construction.elements["NumberofConditionedFloorsAboveGrade"].text.to_f) * Airflow.get_duct_location_frac_leakage(measures["ResidentialAirflow"][0]["duct_location_frac"], building_construction.elements["NumberofConditionedFloorsAboveGrade"].text.to_f))
      if Airflow.get_duct_supply_surface_area(measures["ResidentialAirflow"][0]["duct_supply_area_mult"].to_f, building_construction.elements["ConditionedFloorArea"].text.to_f, building_construction.elements["NumberofConditionedFloorsAboveGrade"].text.to_f) * (1 - Airflow.get_duct_location_frac_leakage(measures["ResidentialAirflow"][0]["duct_location_frac"], building_construction.elements["NumberofConditionedFloorsAboveGrade"].text.to_f)) > 0
        duct = air_distribution.add_element "Ducts"
        XMLHelper.add_element(duct, "DuctType", "supply")
        XMLHelper.add_element(duct, "DuctLocation", "conditioned space")
        XMLHelper.add_element(duct, "FractionDuctArea", 1 - Airflow.get_duct_location_frac_leakage(measures["ResidentialAirflow"][0]["duct_location_frac"], building_construction.elements["NumberofConditionedFloorsAboveGrade"].text.to_f))
        XMLHelper.add_element(duct, "DuctSurfaceArea", Airflow.get_duct_supply_surface_area(measures["ResidentialAirflow"][0]["duct_supply_area_mult"].to_f, building_construction.elements["ConditionedFloorArea"].text.to_f, building_construction.elements["NumberofConditionedFloorsAboveGrade"].text.to_f) * (1 - Airflow.get_duct_location_frac_leakage(measures["ResidentialAirflow"][0]["duct_location_frac"], building_construction.elements["NumberofConditionedFloorsAboveGrade"].text.to_f)))
      end
      duct = air_distribution.add_element "Ducts"
      XMLHelper.add_element(duct, "DuctType", "return")
      XMLHelper.add_element(duct, "DuctInsulationRValue", measures["ResidentialAirflow"][0]["duct_unconditioned_r"])
      XMLHelper.add_element(duct, "DuctLocation", duct_location)
      XMLHelper.add_element(duct, "FractionDuctArea", 1)
      XMLHelper.add_element(duct, "DuctSurfaceArea", Airflow.get_duct_return_surface_area(measures["ResidentialAirflow"][0]["duct_return_area_mult"].to_f, building_construction.elements["ConditionedFloorArea"].text.to_f, building_construction.elements["NumberofConditionedFloorsAboveGrade"].text.to_f, Airflow.get_duct_num_returns(measures["ResidentialAirflow"][0]["duct_num_returns"], building_construction.elements["NumberofConditionedFloorsAboveGrade"].text.to_f)))
      XMLHelper.add_element(air_distribution, "NumberofReturnRegisters", Airflow.get_duct_num_returns(measures["ResidentialAirflow"][0]["duct_num_returns"], building_construction.elements["NumberofConditionedFloorsAboveGrade"].text.to_f).to_i)
      
    end
    
    # NaturalVentilation
    extension = hvac.add_element "extension"
    natural_ventilation = extension.add_element "natural_ventilation"
    XMLHelper.add_element(natural_ventilation, "nat_vent_clg_offset", measures["ResidentialAirflow"][0]["nat_vent_clg_offset"])
    XMLHelper.add_element(natural_ventilation, "nat_vent_clg_season", measures["ResidentialAirflow"][0]["nat_vent_clg_season"])
    XMLHelper.add_element(natural_ventilation, "nat_vent_frac_window_area_openable", measures["ResidentialAirflow"][0]["nat_vent_frac_window_area_openable"])
    XMLHelper.add_element(natural_ventilation, "nat_vent_frac_windows_open", measures["ResidentialAirflow"][0]["nat_vent_frac_windows_open"])    
    XMLHelper.add_element(natural_ventilation, "nat_vent_htg_offset", measures["ResidentialAirflow"][0]["nat_vent_htg_offset"])    
    XMLHelper.add_element(natural_ventilation, "nat_vent_htg_season", measures["ResidentialAirflow"][0]["nat_vent_htg_season"])    
    XMLHelper.add_element(natural_ventilation, "nat_vent_max_oa_hr", measures["ResidentialAirflow"][0]["nat_vent_max_oa_hr"])
    XMLHelper.add_element(natural_ventilation, "nat_vent_max_oa_rh", measures["ResidentialAirflow"][0]["nat_vent_max_oa_rh"])    
    XMLHelper.add_element(natural_ventilation, "nat_vent_num_weekdays", measures["ResidentialAirflow"][0]["nat_vent_num_weekdays"])    
    XMLHelper.add_element(natural_ventilation, "nat_vent_num_weekends", measures["ResidentialAirflow"][0]["nat_vent_num_weekends"])    
    XMLHelper.add_element(natural_ventilation, "nat_vent_ovlp_offset", measures["ResidentialAirflow"][0]["nat_vent_ovlp_offset"])    
    XMLHelper.add_element(natural_ventilation, "nat_vent_ovlp_season", measures["ResidentialAirflow"][0]["nat_vent_ovlp_season"])    
    
    # Dehumidifier
    if measures.keys.include? "ResidentialHVACDehumidifier"
      dehumidifier = extension.add_element "dehumidifier"
      XMLHelper.add_element(dehumidifier, "air_flow_rate", measures["ResidentialHVACDehumidifier"][0]["air_flow_rate"])
      XMLHelper.add_element(dehumidifier, "energy_factor", measures["ResidentialHVACDehumidifier"][0]["energy_factor"])
      XMLHelper.add_element(dehumidifier, "humidity_setpoint", measures["ResidentialHVACDehumidifier"][0]["humidity_setpoint"])
      XMLHelper.add_element(dehumidifier, "water_removal_rate", measures["ResidentialHVACDehumidifier"][0]["water_removal_rate"])
    end
    
    # MechanicalVentilation
    unless measures["ResidentialAirflow"][0]["mech_vent_type"] == Constants.VentTypeNone
      mechanical_ventilation = systems.add_element "MechanicalVentilation"
      ventilation_fans = mechanical_ventilation.add_element "VentilationFans"
      ventilation_fan = ventilation_fans.add_element "VentilationFan"
      XMLHelper.add_attribute(ventilation_fan.add_element("SystemIdentifier"), "id", Constants.ObjectNameMechanicalVentilation)
      XMLHelper.add_element(ventilation_fan, "FanType", os_to_hpxml_mech_vent(measures["ResidentialAirflow"][0]["mech_vent_type"]))
      XMLHelper.add_element(ventilation_fan, "RatedFlowRate", 247)
      XMLHelper.add_element(ventilation_fan, "HoursInOperation", 24)
      XMLHelper.add_element(ventilation_fan, "UsedForWholeBuildingVentilation", true)
      XMLHelper.add_element(ventilation_fan, "TotalRecoveryEfficiency", measures["ResidentialAirflow"][0]["mech_vent_total_efficiency"])
      XMLHelper.add_element(ventilation_fan, "SensibleRecoveryEfficiency", measures["ResidentialAirflow"][0]["mech_vent_sensible_efficiency"])
      XMLHelper.add_element(ventilation_fan, "FanPower", measures["ResidentialAirflow"][0]["mech_vent_fan_power"])
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
        
        ef = nil
        recov_ef = nil
        vol = nil
        
        pl.supplyComponents.each do |wh|
          next if !wh.to_WaterHeaterMixed.is_initialized and !wh.to_WaterHeaterStratified.is_initialized and !wh.to_WaterHeaterHeatPumpWrappedCondenser.is_initialized
          if wh.to_WaterHeaterMixed.is_initialized
            wh = wh.to_WaterHeaterMixed.get
            cap = OpenStudio.convert(wh.heaterMaximumCapacity.get,"W","Btu/h").get.round
            eff = wh.heaterThermalEfficiency.get.round(2)
            if wh.heaterControlType == "Cycle"
              type = "storage water heater"
              vol = OpenStudio.convert(wh.tankVolume.get,"m^3","gal").get.round(1)
            elsif wh.heaterControlType == "Modulate"
              type = "instantaneous water heater"
            end
            loc = wh.ambientTemperatureThermalZone.get
            ef = measures[get_measure_match(measures, "HotWaterHeater")][0]["energy_factor"]
            recov_ef = measures[get_measure_match(measures, "HotWaterHeater")][0]["recovery_efficiency"]          
          elsif wh.to_WaterHeaterStratified.is_initialized
            next if wh.to_WaterHeaterStratified.get.secondaryPlantLoop.is_initialized
            wh = wh.to_WaterHeaterStratified.get
            type = "heat pump water heater"            
            eff = wh.heaterThermalEfficiency.round(2)
            vol = OpenStudio.convert(wh.tankVolume.get,"m^3","gal").get.round(1)
            model.getOtherEquipments.each do |oe|
              next unless oe.name.to_s.downcase.include? "hpwh_sens"
              loc = oe.space.get
            end
            model.getWaterHeaterHeatPumpWrappedCondensers.each do |hp|
              next unless hp.tank == wh
              cap = OpenStudio.convert(hp.dXCoil.to_CoilWaterHeatingAirToWaterHeatPumpWrapped.get.ratedHeatingCapacity,"W","Btu/h").get.round
            end
          end
          XMLHelper.add_attribute(water_heating_system.add_element("SystemIdentifier"), "id", pl.name)
          XMLHelper.add_attribute(water_heating_system.add_element("AttachedToZone"), "idref", loc.name)
          if measures.keys.include? "ResidentialHotWaterHeaterHeatPump" or measures.keys.include? "ResidentialHotWaterHeaterTankElectric" or measures.keys.include? "ResidentialHotWaterHeaterTanklessElectric"
            fuel_type = os_to_hpxml_fuel_map(Constants.FuelTypeElectric)
          elsif
            fuel_type = os_to_hpxml_fuel_map(measures[get_measure_match(measures, "HotWaterHeater")][0]["fuel_type"])
          end
          XMLHelper.add_element(water_heating_system, "FuelType", fuel_type)
          XMLHelper.add_element(water_heating_system, "WaterHeaterType", type)
          if Geometry.is_pier_beam(loc)
            loc = "other exterior"
          elsif Geometry.is_crawl(loc)
            loc = "crawlspace - vented"
          elsif Geometry.is_finished_basement(loc)
            loc = "basement - conditioned"
          elsif Geometry.is_unfinished_basement(loc)
            loc = "basement - unconditioned"              
          elsif Geometry.is_unfinished_attic(loc)
            loc = "attic - unconditioned"
          elsif Geometry.is_finished_attic(loc)
            loc = "conditioned space"
          elsif Geometry.is_garage(loc)
            loc = "garage - unconditioned"
          elsif Geometry.is_living(loc) or Geometry.zone_is_finished(loc)
            loc = "conditioned space"
          end
          XMLHelper.add_element(water_heating_system, "Location", loc)
          unless vol.nil?
            XMLHelper.add_element(water_heating_system, "TankVolume", vol)
          end
          XMLHelper.add_element(water_heating_system, "HeatingCapacity", cap)
          unless ef.nil?
            XMLHelper.add_element(water_heating_system, "EnergyFactor", ef)
          end
          unless recov_ef.nil?
            XMLHelper.add_element(water_heating_system, "RecoveryEfficiency", recov_ef)
          end
          XMLHelper.add_element(water_heating_system, "ThermalEfficiency", eff)
          XMLHelper.add_element(water_heating_system, "HotWaterTemperature", measures[get_measure_match(measures, "HotWaterHeater")][0]["setpoint_temp"])
        end
        
        if measures.keys.include? "ResidentialHotWaterDistribution"
          hot_water_distribution = water_heating.add_element "HotWaterDistribution"
          XMLHelper.add_attribute(hot_water_distribution.add_element("SystemIdentifier"), "id", Constants.ObjectNameHotWaterDistribution)
          XMLHelper.add_attribute(hot_water_distribution.add_element("AttachedToWaterHeatingSystem"), "idref", water_heating_system.elements["SystemIdentifier"].attributes["id"])
          system_type = hot_water_distribution.add_element "SystemType"
          if not measures["ResidentialHotWaterDistribution"][0]["recirc_type"] == Constants.RecircTypeNone
            XMLHelper.add_element(system_type.add_element "Recirculation", "ControlType", os_to_hpxml_recirc(measures["ResidentialHotWaterDistribution"][0]["recirc_type"]))
          else
            system_type.add_element "Standard"
          end
          pipe_insulation = hot_water_distribution.add_element "PipeInsulation"
          XMLHelper.add_element(pipe_insulation, "PipeRValue", measures["ResidentialHotWaterDistribution"][0]["dist_ins"])
          if measures["ResidentialHotWaterDistribution"][0]["dist_ins"].to_f > 0
            XMLHelper.add_element(pipe_insulation, "FractionPipeInsulation", 1)
          else
            XMLHelper.add_element(pipe_insulation, "FractionPipeInsulation", 0)
          end
          XMLHelper.add_element(hot_water_distribution.add_element("extension"), "LongestPipeLength", 30) # TODO: where to get this value?
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
            flow = OpenStudio.convert(fixture.waterUseEquipmentDefinition.peakFlowRate,"m^3/s","gal/min").get.round(2)
            XMLHelper.add_attribute(water_fixture.add_element("SystemIdentifier"), "id", "fixture #{fixture.name}")
            XMLHelper.add_attribute(water_fixture.add_element("AttachedToWaterHeatingSystem"), "idref", water_heating_system.elements["SystemIdentifier"].attributes["id"])
            XMLHelper.add_element(water_fixture, "WaterFixtureType", type)
            XMLHelper.add_element(water_fixture, "FlowRate", flow)
          end
        end        
        
      end
    end    
    
    # SolarThermal
    solar_thermal = nil
    model.getBuildingUnits.each do |unit|
      model.getPlantLoops.each do |pl|
        next if pl.name.to_s != Constants.PlantLoopSolarHotWater(unit.name.to_s)
        if systems.elements["SolarThermal"].nil?
          solar_thermal = systems.add_element "SolarThermal"
        end
        solar_thermal_system = solar_thermal.add_element "SolarThermalSystem"            
        XMLHelper.add_attribute(solar_thermal_system.add_element("SystemIdentifier"), "id", Constants.ObjectNameSolarHotWater)
        XMLHelper.add_element(solar_thermal_system, "SystemType", "hot water")
        XMLHelper.add_element(solar_thermal_system, "CollectorArea", measures["ResidentialHotWaterSolar"][0]["collector_area"])
        XMLHelper.add_element(solar_thermal_system, "CollectorAzimuth", Geometry.get_abs_azimuth(Constants.CoordAbsolute, measures["ResidentialHotWaterSolar"][0]["azimuth"].to_f, 0).round)
        XMLHelper.add_element(solar_thermal_system, "CollectorTilt", measures["ResidentialHotWaterSolar"][0]["tilt"])
        pl.supplyComponents.each do |wh|
          next if !wh.to_WaterHeaterStratified.is_initialized
          XMLHelper.add_element(solar_thermal_system, "StorageVolume", OpenStudio.convert(wh.to_WaterHeaterStratified.get.tankVolume.get,"m^3","gal").get.round)
        end           
      end            
    end
    
    # Appliances
    appliances = building_details.add_element "Appliances"

    if measures.keys.include? "ResidentialApplianceClothesWasher"
      clothes_washer = appliances.add_element "ClothesWasher"
      XMLHelper.add_attribute(clothes_washer.add_element("SystemIdentifier"), "id", Constants.ObjectNameClothesWasher)
      XMLHelper.add_element(clothes_washer, "Location", get_appliance_location(model, Constants.ObjectNameClothesWasher))
      XMLHelper.add_element(clothes_washer, "ModifiedEnergyFactor", measures["ResidentialApplianceClothesWasher"][0]["imef"])
      extension = clothes_washer.add_element "extension"
      XMLHelper.add_element(extension, "EnergyRating", measures["ResidentialApplianceClothesWasher"][0]["rated_annual_energy"])
      XMLHelper.add_element(extension, "ElectricRate", 0.127)
      XMLHelper.add_element(extension, "GasRate", 1.003)
      XMLHelper.add_element(extension, "AnnualGasCost", 24.0)
      XMLHelper.add_element(extension, "Capacity", measures["ResidentialApplianceClothesWasher"][0]["drum_volume"])
    end

    if measures.keys.include? "ResidentialApplianceClothesDryerElectric"
      clothes_dryer = appliances.add_element "ClothesDryer"
      XMLHelper.add_attribute(clothes_dryer.add_element("SystemIdentifier"), "id", Constants.ObjectNameClothesDryer(Constants.FuelTypeElectric))
      XMLHelper.add_element(clothes_dryer, "Location", get_appliance_location(model, Constants.ObjectNameClothesDryer(Constants.FuelTypeElectric)))
      XMLHelper.add_element(clothes_dryer, "FuelType", os_to_hpxml_fuel_map(Constants.FuelTypeElectric))      
      extension = clothes_dryer.add_element "extension"
      XMLHelper.add_element(extension, "EfficiencyFactor", measures["ResidentialApplianceClothesDryerElectric"][0]["cef"])
      XMLHelper.add_element(extension, "HasTimerControl", true)      
    elsif measures.keys.include? "ResidentialApplianceClothesDryerFuel"
      clothes_dryer = appliances.add_element "ClothesDryer"
      XMLHelper.add_attribute(clothes_dryer.add_element("SystemIdentifier"), "id", Constants.ObjectNameClothesDryer(measures["ResidentialApplianceClothesDryerFuel"][0]["fuel_type"]))
      XMLHelper.add_element(clothes_dryer, "Location", get_appliance_location(model, Constants.ObjectNameClothesDryer(measures["ResidentialApplianceClothesDryerFuel"][0]["fuel_type"])))
      XMLHelper.add_element(clothes_dryer, "FuelType", os_to_hpxml_fuel_map(measures["ResidentialApplianceClothesDryerFuel"][0]["fuel_type"]))
      extension = clothes_dryer.add_element "extension"
      XMLHelper.add_element(extension, "EfficiencyFactor", measures["ResidentialApplianceClothesDryerFuel"][0]["cef"])
      XMLHelper.add_element(extension, "HasTimerControl", true)      
    else
      runner.registerError("Building does not have a clothes dryer.")
      return false
    end

    if measures.keys.include? "ResidentialApplianceDishwasher"
      dishwasher = appliances.add_element "Dishwasher"
      XMLHelper.add_attribute(dishwasher.add_element("SystemIdentifier"), "id", "dishwasher")
      XMLHelper.add_element(dishwasher, "RatedAnnualkWh", measures["ResidentialApplianceDishwasher"][0]["dw_E"])
      extension = dishwasher.add_element "extension"
      XMLHelper.add_element(extension, "Capacity", measures["ResidentialApplianceDishwasher"][0]["num_settings"])      
    end

    if measures.keys.include? "ResidentialApplianceRefrigerator"
      refrigerator = appliances.add_element "Refrigerator"
      XMLHelper.add_attribute(refrigerator.add_element("SystemIdentifier"), "id", Constants.ObjectNameRefrigerator)
      XMLHelper.add_element(refrigerator, "Location", get_appliance_location(model, Constants.ObjectNameRefrigerator))
      XMLHelper.add_element(refrigerator, "RatedAnnualkWh", measures["ResidentialApplianceRefrigerator"][0]["fridge_E"])
    end
    
    if measures.keys.include? "ResidentialMiscFreezer"
      freezer = appliances.add_element "Freezer"
      XMLHelper.add_attribute(freezer.add_element("SystemIdentifier"), "id", Constants.ObjectNameFreezer)
      XMLHelper.add_element(freezer, "Location", get_appliance_location(model, Constants.ObjectNameFreezer))
      XMLHelper.add_element(freezer, "RatedAnnualkWh", measures["ResidentialMiscFreezer"][0]["freezer_E"])
    end      

    if measures.keys.include? "ResidentialApplianceCookingRangeElectric"
      cooking_range = appliances.add_element "CookingRange"
      XMLHelper.add_attribute(cooking_range.add_element("SystemIdentifier"), "id", Constants.ObjectNameCookingRange(Constants.FuelTypeElectric))
      XMLHelper.add_element(cooking_range, "FuelType", os_to_hpxml_fuel_map(Constants.FuelTypeElectric))
      extension = cooking_range.add_element "extension"
      XMLHelper.add_element(extension, "IsInduction", true)
      oven = appliances.add_element "Oven"
      XMLHelper.add_attribute(oven.add_element("SystemIdentifier"), "id", "#{Constants.ObjectNameCookingRange(Constants.FuelTypeElectric)} oven")
      XMLHelper.add_element(oven, "FuelType", os_to_hpxml_fuel_map(Constants.FuelTypeElectric))
      extension = oven.add_element "extension"
      XMLHelper.add_element(extension, "IsConvection", true)
    elsif measures.keys.include? "ResidentialApplianceCookingRangeFuel"
      cooking_range = appliances.add_element "CookingRange"
      XMLHelper.add_attribute(cooking_range.add_element("SystemIdentifier"), "id", Constants.ObjectNameCookingRange(measures["ResidentialApplianceCookingRangeFuel"][0]["fuel_type"]))
      XMLHelper.add_element(cooking_range, "FuelType", os_to_hpxml_fuel_map(measures["ResidentialApplianceCookingRangeFuel"][0]["fuel_type"]))
      extension = cooking_range.add_element "extension"
      XMLHelper.add_element(extension, "IsInduction", true)
      oven = appliances.add_element "Oven"
      XMLHelper.add_attribute(oven.add_element("SystemIdentifier"), "id", "#{Constants.ObjectNameCookingRange(Constants.FuelTypeElectric)} oven")
      XMLHelper.add_element(oven, "FuelType", os_to_hpxml_fuel_map(measures["ResidentialApplianceCookingRangeFuel"][0]["fuel_type"]))
      extension = oven.add_element "extension"
      XMLHelper.add_element(extension, "IsConvection", true)
    end
    
    # Lighting
    lighting = building_details.add_element "Lighting"
    
    model.getLightss.each do |l|
      lighting_group = lighting.add_element "LightingGroup"
      XMLHelper.add_attribute(lighting_group.add_element("SystemIdentifier"), "id", l.name)
      XMLHelper.add_element(lighting_group, "Location", "interior")
      XMLHelper.add_element(lighting_group, "FloorAreaServed", OpenStudio.convert(l.space.get.floorArea,"m^2","ft^2").get.round(1))
    end
    lighting_fractions = lighting.add_element "LightingFractions"
    frac_cfl = ( measures["ResidentialLighting"][0]["hw_cfl"].to_f + measures["ResidentialLighting"][0]["pg_cfl"].to_f ) / 2
    frac_lfl = ( measures["ResidentialLighting"][0]["hw_lfl"].to_f + measures["ResidentialLighting"][0]["pg_lfl"].to_f ) / 2
    frac_led = ( measures["ResidentialLighting"][0]["hw_led"].to_f + measures["ResidentialLighting"][0]["pg_led"].to_f ) / 2
    frac_inc = 1.0 - (frac_cfl + frac_lfl + frac_led)
    XMLHelper.add_element(lighting_fractions, "FractionIncandescent", frac_inc.round(1))
    XMLHelper.add_element(lighting_fractions, "FractionCFL", frac_cfl.round(1))
    XMLHelper.add_element(lighting_fractions, "FractionLFL", frac_lfl.round(1))
    XMLHelper.add_element(lighting_fractions, "FractionLED", frac_led.round(1))
    extension = lighting_fractions.add_element "extension"
    XMLHelper.add_element(extension, "QualifyingLightFixturesInterior", 0.5)
    XMLHelper.add_element(extension, "QualifyingLightFixturesExterior", 0.5)
    XMLHelper.add_element(extension, "QualifyingLightFixturesGarage", 0.5)
    
    if measures.keys.include? "ResidentialHVACCeilingFan"
      ceiling_fan = lighting.add_element "CeilingFan"
      XMLHelper.add_attribute(ceiling_fan.add_element("SystemIdentifier"), "id", Constants.ObjectNameCeilingFan)
    end
    
    # extension = lighting.add_element "extension"
    # XMLHelper.add_element(extension, "AnnualInteriorkWh", measures["ResidentialLighting"][0]["energy_use_interior"])
    # XMLHelper.add_element(extension, "AnnualExteriorkWh", measures["ResidentialLighting"][0]["energy_use_exterior"])
    # XMLHelper.add_element(extension, "AnnualGaragekWh", measures["ResidentialLighting"][0]["energy_use_garage"])    
    
    # Pools
    pools = building_details.add_element "Pools"
    
    if measures.keys.include? "ResidentialMiscPoolHeaterElectric"
      pool = pools.add_element "Pool"
      XMLHelper.add_attribute(pool.add_element("SystemIdentifier"), "id", Constants.ObjectNamePoolHeater(Constants.FuelTypeElectric))
      heater = pool.add_element "Heater"
      XMLHelper.add_attribute(heater.add_element("SystemIdentifier"), "id", "#{Constants.ObjectNamePoolHeater(Constants.FuelTypeElectric)} heater")
      XMLHelper.add_element(heater, "Type", "electric resistance")
    end

    if measures.keys.include? "ResidentialMiscPoolHeaterGas"
      pool = pools.add_element "Pool"
      XMLHelper.add_attribute(pool.add_element("SystemIdentifier"), "id", Constants.ObjectNamePoolHeater(Constants.FuelTypeGas))
      heater = pool.add_element "Heater"
      XMLHelper.add_attribute(heater.add_element("SystemIdentifier"), "id", "#{Constants.ObjectNamePoolHeater(Constants.FuelTypeGas)} heater")
      XMLHelper.add_element(heater, "Type", "gas fired")
    end
    
    if measures.keys.include? "ResidentialMiscPoolPump"
      pool = pools.add_element "Pool"
      XMLHelper.add_attribute(pool.add_element("SystemIdentifier"), "id", Constants.ObjectNamePoolPump)
      pool_pumps = pool.add_element "PoolPumps"
      pool_pump = pool_pumps.add_element "PoolPump"
      XMLHelper.add_attribute(pool_pump.add_element("SystemIdentifier"), "id", "#{Constants.ObjectNamePoolPump} pump")
    end
    
    if measures.keys.include? "ResidentialMiscHotTubHeaterElectric"
      pool = pools.add_element "Pool"
      XMLHelper.add_attribute(pool.add_element("SystemIdentifier"), "id", Constants.ObjectNameHotTubHeater(Constants.FuelTypeElectric))
      heater = pool.add_element "Heater"
      XMLHelper.add_attribute(heater.add_element("SystemIdentifier"), "id", "#{Constants.ObjectNameHotTubHeater(Constants.FuelTypeElectric)} heater")
      XMLHelper.add_element(heater, "Type", "electric resistance")
    end
    
    if measures.keys.include? "ResidentialMiscHotTubHeaterGas"
      pool = pools.add_element "Pool"
      XMLHelper.add_attribute(pool.add_element("SystemIdentifier"), "id", Constants.ObjectNameHotTubHeater(Constants.FuelTypeGas))
      heater = pool.add_element "Heater"
      XMLHelper.add_attribute(heater.add_element("SystemIdentifier"), "id", "#{Constants.ObjectNameHotTubHeater(Constants.FuelTypeGas)} heater")
      XMLHelper.add_element(heater, "Type", "gas fired")
    end

    if measures.keys.include? "ResidentialMiscHotTubPump"
      pool = pools.add_element "Pool"
      XMLHelper.add_attribute(pool.add_element("SystemIdentifier"), "id", Constants.ObjectNameHotTubPump)
      pool_pumps = pool.add_element "PoolPumps"
      pool_pump = pool_pumps.add_element "PoolPump"
      XMLHelper.add_attribute(pool_pump.add_element("SystemIdentifier"), "id", "#{Constants.ObjectNameHotTubPump} pump")
    end    
    
    # MiscLoads
    misc_loads = building_details.add_element "MiscLoads"
    
    if measures.keys.include? "ResidentialMiscPlugLoads"
      plug_load = misc_loads.add_element "PlugLoad"
      XMLHelper.add_attribute(plug_load.add_element("SystemIdentifier"), "id", Constants.ObjectNameMiscPlugLoads)
      load = plug_load.add_element "Load"
      XMLHelper.add_element(load, "Units", "kWh/year")
      XMLHelper.add_element(load, "Value", measures["ResidentialMiscPlugLoads"][0]["energy_use"])
    end
    
    if measures.keys.include? "ResidentialMiscExtraRefrigerator"
      plug_load = misc_loads.add_element "PlugLoad"
      XMLHelper.add_attribute(plug_load.add_element("SystemIdentifier"), "id", Constants.ObjectNameExtraRefrigerator)
      load = plug_load.add_element "Load"
      XMLHelper.add_element(load, "Units", "kWh/year")
      XMLHelper.add_element(load, "Value", measures["ResidentialMiscExtraRefrigerator"][0]["fridge_E"])      
    end
    
    errors = []
    XMLHelper.validate(doc.to_s, File.join(schemas_dir, "HPXML.xsd"), runner).each do |error|
      errors << error.to_s
    end
    EnergyRatingIndex301Validator.run_validator(doc, errors)

    errors.each do |error|
      puts error
      runner.registerError(error.to_s)
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
  
  def get_measure_match(measures, substr)
    measure = measures.keys.select{|k| k.include? substr}
    if measure.empty? or measure.length > 1
      return nil
    end
    return measure[0]
  end  
  
  def os_to_hpxml_site_type(type)
    return {Constants.TerrainOcean=>"rural", Constants.TerrainPlains=>"rural", Constants.TerrainRural=>"rural", Constants.TerrainSuburban=>"suburban", Constants.TerrainCity=>"urban"}[type]
  end
  
  def os_to_hpxml_ins_grade(gr)
    return {"I"=>1, "II"=>2, "III"=>3}[gr]    
  end
  
  def os_to_hpxml_fuel_map(fuel)
    return {Constants.FuelTypeGas=>"natural gas", Constants.FuelTypeOil=>"fuel oil", Constants.FuelTypePropane=>"propane", Constants.FuelTypeElectric=>"electricity"}[fuel]
  end
  
  def os_to_hpxml_roof_type(type)
    return {Constants.RoofMaterialAsphaltShingles=>"asphalt or fiberglass shingles", Constants.RoofMaterialMembrane=>"other", Constants.RoofMaterialMetal=>"metal surfacing", Constants.RoofMaterialTarGravel=>"other", Constants.RoofMaterialTile=>"slate or tile shingles", Constants.RoofMaterialWoodShakes=>"wood shingles or shakes"}[type]
  end
  
  def os_to_hpxml_mech_vent(type)
    return {Constants.VentTypeExhaust=>"exhaust only", Constants.VentTypeSupply=>"supply only", Constants.VentTypeBalanced=>"energy recovery ventilator"}[type]
  end
  
  def os_to_hpxml_location(loc)
    if Geometry.is_living(loc)
      return "living space"
    elsif Geometry.is_finished_basement(loc) or Geometry.is_unfinished_basement(loc)
      return "basement"
    elsif Geometry.is_garage(loc)
      return "garage"
    end
    return "other"
  end
  
  def os_to_hpxml_recirc(type)
    return {Constants.RecircTypeNone=>"no control", Constants.RecircTypeDemand=>"manual demand control", Constants.RecircTypeTimer=>"timer"}
  end
  
  def os_to_hpxml_speeds(sp)
    return {2=>"2-Speed", 4=>"Variable-Speed"}[sp]
  end
  
  def get_appliance_location(model, name)
    (model.getElectricEquipments + model.getOtherEquipments).each do |e|
      next unless e.name.to_s.downcase.include? name
      return os_to_hpxml_location(e.space.get)
    end
  end
  
  def get_duct_location(loc)
    return {"unfinished attic zone"=>"unconditioned attic", "finished basement zone"=>"conditioned space", "unfinished basement zone"=>"unconditioned basement", "crawl zone"=>"crawlspace", "pier and beam zone"=>"outside", "garage zone"=>"garage"}[loc]
  end
  
  def get_interior_adjacent_to(space, measures)
    if Geometry.is_living(space)
      interior_adjacent_to = "living space"
    elsif Geometry.is_garage(space)
      interior_adjacent_to = "garage"
    elsif Geometry.is_unfinished_attic(space)
      if measures["ResidentialAirflow"][0]["unfinished_attic_sla"].to_f == 0
        interior_adjacent_to = "unvented attic"
      else
        interior_adjacent_to = "vented attic"
      end
    elsif Geometry.is_finished_attic(space)
      interior_adjacent_to = "cape cod"
    end
  end
  
  def get_exterior_adjacent_to(surface)
    if surface.outsideBoundaryCondition.downcase == "outdoors"
      exterior_adjacent_to = "ambient"
    elsif surface.outsideBoundaryCondition.downcase == "ground"
      exterior_adjacent_to = "ground"
    elsif surface.adjacentSurface.is_initialized
      if Geometry.is_living(surface.adjacentSurface.get.space.get)
        exterior_adjacent_to = "living space"
      elsif Geometry.is_unfinished_attic(surface.adjacentSurface.get.space.get)
        if measures["ResidentialAirflow"][0]["unfinished_attic_sla"].to_f == 0
          exterior_adjacent_to = "unvented attic"
        else
          exterior_adjacent_to = "vented attic"
        end        
      elsif Geometry.is_finished_attic(surface.adjacentSurface.get.space.get)
        exterior_adjacent_to = "living space"
      elsif Geometry.is_garage(surface.adjacentSurface.get.space.get)
        exterior_adjacent_to = "garage"
      end
    end
  end

end

# register the measure to be used by the application
OSWtoHPXMLExport.new.registerWithApplication
