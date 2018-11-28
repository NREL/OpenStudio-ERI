require_relative "../../HPXMLtoOpenStudio/measure"
require_relative "../../HPXMLtoOpenStudio/resources/airflow"
require_relative "../../HPXMLtoOpenStudio/resources/constants"
require_relative "../../HPXMLtoOpenStudio/resources/constructions"
require_relative "../../HPXMLtoOpenStudio/resources/geometry"
require_relative "../../HPXMLtoOpenStudio/resources/hotwater_appliances"
require_relative "../../HPXMLtoOpenStudio/resources/lighting"
require_relative "../../HPXMLtoOpenStudio/resources/unit_conversions"
require_relative "../../HPXMLtoOpenStudio/resources/waterheater"
require_relative "../../HPXMLtoOpenStudio/resources/xmlhelper"

class EnergyRatingIndex301Ruleset
  def self.apply_ruleset(hpxml_doc, calc_type, weather)
    building = hpxml_doc.elements["/HPXML/Building"]

    # Update XML type
    header = hpxml_doc.elements["/HPXML/XMLTransactionHeaderInformation"]
    if header.elements["XMLType"].nil?
      header.elements["XMLType"].text = calc_type
    else
      header.elements["XMLType"].text += ", #{calc_type}"
    end

    # Global variables
    @eri_version = XMLHelper.get_value(hpxml_doc, "/HPXML/SoftwareInfo/extension/ERICalculation/Version")
    @weather = weather
    @ndu = 1 # Dwelling units
    @cfa = Float(XMLHelper.get_value(building, "BuildingDetails/BuildingSummary/BuildingConstruction/ConditionedFloorArea"))
    @nbeds = Float(XMLHelper.get_value(building, "BuildingDetails/BuildingSummary/BuildingConstruction/NumberofBedrooms"))
    @ncfl = Float(XMLHelper.get_value(building, "BuildingDetails/BuildingSummary/BuildingConstruction/NumberofConditionedFloors"))
    @ncfl_ag = Float(XMLHelper.get_value(building, "BuildingDetails/BuildingSummary/BuildingConstruction/NumberofConditionedFloorsAboveGrade"))
    @cvolume = Float(XMLHelper.get_value(building, "BuildingDetails/BuildingSummary/BuildingConstruction/ConditionedBuildingVolume"))
    @iecc_zone_2006 = XMLHelper.get_value(building, "BuildingDetails/ClimateandRiskZones/ClimateZoneIECC[Year='2006']/ClimateZone")
    @iecc_zone_2012 = XMLHelper.get_value(building, "BuildingDetails/ClimateandRiskZones/ClimateZoneIECC[Year='2012']/ClimateZone")

    # Update HPXML object based on calculation type
    if calc_type == Constants.CalcTypeERIReferenceHome
      apply_reference_home_ruleset(building)
    elsif calc_type == Constants.CalcTypeERIRatedHome
      apply_rated_home_ruleset(building)
    elsif calc_type == Constants.CalcTypeERIIndexAdjustmentDesign
      apply_index_adjustment_design_ruleset(building)
    elsif calc_type == Constants.CalcTypeERIIndexAdjustmentReferenceHome
      apply_index_adjustment_design_ruleset(building)
      apply_reference_home_ruleset(building)
    end
  end

  def self.apply_reference_home_ruleset(building)
    # Create new BuildingDetails element
    orig_details = XMLHelper.delete_element(building, "BuildingDetails")
    XMLHelper.delete_element(building, "ModeledUsages")
    XMLHelper.delete_element(building, "extensions")
    new_details = XMLHelper.add_element(building, "BuildingDetails")

    # BuildingSummary
    new_summary = XMLHelper.add_element(new_details, "BuildingSummary")
    set_summary_reference(new_summary, orig_details)

    # ClimateAndRiskZones
    XMLHelper.copy_element(new_details, orig_details, "ClimateandRiskZones")

    # Enclosure
    new_enclosure = XMLHelper.add_element(new_details, "Enclosure")
    set_enclosure_air_infiltration_reference(new_enclosure, orig_details)
    set_enclosure_attics_roofs_reference(new_enclosure, orig_details)
    set_enclosure_foundations_reference(new_enclosure, orig_details)
    set_enclosure_rim_joists_reference(new_enclosure, orig_details)
    set_enclosure_walls_reference(new_enclosure, orig_details)
    set_enclosure_windows_reference(new_enclosure, orig_details)
    set_enclosure_skylights_reference(new_enclosure)
    set_enclosure_doors_reference(new_enclosure, orig_details)

    # Systems
    new_systems = XMLHelper.add_element(new_details, "Systems")
    set_systems_hvac_reference(new_systems, orig_details)
    set_systems_mechanical_ventilation_reference(new_systems, orig_details, new_enclosure)
    set_systems_water_heater_reference(new_systems, orig_details)
    set_systems_water_heating_use_reference(new_systems, orig_details)
    set_systems_photovoltaics_reference(new_systems)

    # Appliances
    new_appliances = XMLHelper.add_element(new_details, "Appliances")
    set_appliances_clothes_washer_reference(new_appliances, orig_details)
    set_appliances_clothes_dryer_reference(new_appliances, orig_details)
    set_appliances_dishwasher_reference(new_appliances, orig_details)
    set_appliances_refrigerator_reference(new_appliances, orig_details)
    set_appliances_cooking_range_oven_reference(new_appliances, orig_details)

    # Lighting
    new_lighting = XMLHelper.add_element(new_details, "Lighting")
    set_lighting_reference(new_lighting, orig_details)
    set_ceiling_fans_reference(new_lighting, orig_details)
  end

  def self.apply_rated_home_ruleset(building)
    # Create new BuildingDetails element
    orig_details = XMLHelper.delete_element(building, "BuildingDetails")
    XMLHelper.delete_element(building, "ModeledUsages")
    XMLHelper.delete_element(building, "extensions")
    new_details = XMLHelper.add_element(building, "BuildingDetails")

    # BuildingSummary
    new_summary = XMLHelper.add_element(new_details, "BuildingSummary")
    set_summary_rated(new_summary, orig_details)

    # ClimateAndRiskZones
    XMLHelper.copy_element(new_details, orig_details, "ClimateandRiskZones")

    # Enclosure
    new_enclosure = XMLHelper.add_element(new_details, "Enclosure")
    set_enclosure_air_infiltration_rated(new_enclosure, orig_details)
    set_enclosure_attics_roofs_rated(new_enclosure, orig_details)
    set_enclosure_foundations_rated(new_enclosure, orig_details)
    set_enclosure_rim_joists_rated(new_enclosure, orig_details)
    set_enclosure_walls_rated(new_enclosure, orig_details)
    set_enclosure_windows_rated(new_enclosure, orig_details)
    set_enclosure_skylights_rated(new_enclosure, orig_details)
    set_enclosure_doors_rated(new_enclosure, orig_details)

    # Systems
    new_systems = XMLHelper.add_element(new_details, "Systems")
    set_systems_hvac_rated(new_systems, orig_details)
    set_systems_mechanical_ventilation_rated(new_systems, orig_details)
    set_systems_water_heater_rated(new_systems, orig_details)
    set_systems_water_heating_use_rated(new_systems, orig_details)
    set_systems_photovoltaics_rated(new_systems, orig_details)

    # Appliances
    new_appliances = XMLHelper.add_element(new_details, "Appliances")
    set_appliances_clothes_washer_rated(new_appliances, orig_details)
    set_appliances_clothes_dryer_rated(new_appliances, orig_details)
    set_appliances_dishwasher_rated(new_appliances, orig_details)
    set_appliances_refrigerator_rated(new_appliances, orig_details)
    set_appliances_cooking_range_oven_rated(new_appliances, orig_details)

    # Lighting
    new_lighting = XMLHelper.add_element(new_details, "Lighting")
    set_lighting_rated(new_lighting, orig_details)
    set_ceiling_fans_rated(new_lighting, orig_details)
  end

  def self.apply_index_adjustment_design_ruleset(building)
    # Create new BuildingDetails element
    orig_details = XMLHelper.delete_element(building, "BuildingDetails")
    XMLHelper.delete_element(building, "ModeledUsages")
    XMLHelper.delete_element(building, "extensions")
    new_details = XMLHelper.add_element(building, "BuildingDetails")

    # BuildingSummary
    new_summary = XMLHelper.add_element(new_details, "BuildingSummary")
    set_summary_iad(new_summary, orig_details)

    # ClimateAndRiskZones
    XMLHelper.copy_element(new_details, orig_details, "ClimateandRiskZones")

    # Enclosure
    new_enclosure = XMLHelper.add_element(new_details, "Enclosure")
    set_enclosure_air_infiltration_iad(new_enclosure, orig_details)
    set_enclosure_attics_roofs_iad(new_enclosure, orig_details)
    set_enclosure_foundations_iad(new_enclosure, orig_details)
    set_enclosure_rim_joists_iad(new_enclosure, orig_details)
    set_enclosure_walls_iad(new_enclosure, orig_details)
    set_enclosure_windows_iad(new_enclosure, orig_details)
    set_enclosure_skylights_iad(new_enclosure, orig_details)
    set_enclosure_doors_iad(new_enclosure, orig_details)

    # Systems
    new_systems = XMLHelper.add_element(new_details, "Systems")
    set_systems_hvac_iad(new_systems, orig_details)
    set_systems_mechanical_ventilation_iad(new_systems, orig_details, new_enclosure)
    set_systems_water_heater_iad(new_systems, orig_details)
    set_systems_water_heating_use_iad(new_systems, orig_details)
    set_systems_photovoltaics_iad(new_systems)

    # Appliances
    new_appliances = XMLHelper.add_element(new_details, "Appliances")
    set_appliances_clothes_washer_iad(new_appliances, orig_details)
    set_appliances_clothes_dryer_iad(new_appliances, orig_details)
    set_appliances_dishwasher_iad(new_appliances, orig_details)
    set_appliances_refrigerator_iad(new_appliances, orig_details)
    set_appliances_cooking_range_oven_iad(new_appliances, orig_details)

    # Lighting
    new_lighting = XMLHelper.add_element(new_details, "Lighting")
    set_lighting_iad(new_lighting, orig_details)
    set_ceiling_fans_iad(new_lighting, orig_details)
  end

  def self.set_summary_reference(new_summary, orig_details)
    new_site = XMLHelper.add_element(new_summary, "Site")
    orig_site = orig_details.elements["BuildingSummary/Site"]
    XMLHelper.copy_element(new_site, orig_site, "FuelTypesAvailable")
    extension = XMLHelper.add_element(new_site, "extension")
    XMLHelper.add_element(extension, "ShelterCoefficient", Airflow.get_default_shelter_coefficient())

    new_occupancy = XMLHelper.add_element(new_summary, "BuildingOccupancy")
    orig_occupancy = orig_details.elements["BuildingSummary/BuildingOccupancy"]
    XMLHelper.add_element(new_occupancy, "NumberofResidents", Geometry.get_occupancy_default_num(@nbeds))

    new_construction = XMLHelper.add_element(new_summary, "BuildingConstruction")
    orig_construction = orig_details.elements["BuildingSummary/BuildingConstruction"]
    XMLHelper.copy_element(new_construction, orig_construction, "NumberofConditionedFloors")
    XMLHelper.copy_element(new_construction, orig_construction, "NumberofConditionedFloorsAboveGrade")
    XMLHelper.copy_element(new_construction, orig_construction, "NumberofBedrooms")
    XMLHelper.copy_element(new_construction, orig_construction, "ConditionedFloorArea")
    XMLHelper.copy_element(new_construction, orig_construction, "ConditionedBuildingVolume")
    XMLHelper.copy_element(new_construction, orig_construction, "GaragePresent")
  end

  def self.set_summary_rated(new_summary, orig_details)
    new_site = XMLHelper.add_element(new_summary, "Site")
    orig_site = orig_details.elements["BuildingSummary/Site"]
    XMLHelper.copy_element(new_site, orig_site, "FuelTypesAvailable")
    extension = XMLHelper.add_element(new_site, "extension")
    XMLHelper.add_element(extension, "ShelterCoefficient", Airflow.get_default_shelter_coefficient())

    new_occupancy = XMLHelper.add_element(new_summary, "BuildingOccupancy")
    orig_occupancy = orig_details.elements["BuildingSummary/BuildingOccupancy"]
    XMLHelper.add_element(new_occupancy, "NumberofResidents", Geometry.get_occupancy_default_num(@nbeds))

    new_construction = XMLHelper.add_element(new_summary, "BuildingConstruction")
    orig_construction = orig_details.elements["BuildingSummary/BuildingConstruction"]
    XMLHelper.copy_element(new_construction, orig_construction, "NumberofConditionedFloors")
    XMLHelper.copy_element(new_construction, orig_construction, "NumberofConditionedFloorsAboveGrade")
    XMLHelper.copy_element(new_construction, orig_construction, "NumberofBedrooms")
    XMLHelper.copy_element(new_construction, orig_construction, "ConditionedFloorArea")
    XMLHelper.copy_element(new_construction, orig_construction, "ConditionedBuildingVolume")
    XMLHelper.copy_element(new_construction, orig_construction, "GaragePresent")
  end

  def self.set_summary_iad(new_summary, orig_details)
    # Table 4.3.1(1) Configuration of Index Adjustment Design - General Characteristics
    @cfa = 2400
    @nbeds = 3
    @ncfl = 2
    @ncfl_ag = 2
    @cvolume = 20400
    @garage_present = false

    new_site = XMLHelper.add_element(new_summary, "Site")
    orig_site = orig_details.elements["BuildingSummary/Site"]
    XMLHelper.copy_element(new_site, orig_site, "FuelTypesAvailable")
    extension = XMLHelper.add_element(new_site, "extension")
    XMLHelper.add_element(extension, "ShelterCoefficient", Airflow.get_default_shelter_coefficient())

    new_occupancy = XMLHelper.add_element(new_summary, "BuildingOccupancy")
    orig_occupancy = orig_details.elements["BuildingSummary/BuildingOccupancy"]
    XMLHelper.add_element(new_occupancy, "NumberofResidents", Geometry.get_occupancy_default_num(@nbeds))

    new_construction = XMLHelper.add_element(new_summary, "BuildingConstruction")
    orig_construction = orig_details.elements["BuildingSummary/BuildingConstruction"]
    XMLHelper.add_element(new_construction, "NumberofConditionedFloors", @ncfl)
    XMLHelper.add_element(new_construction, "NumberofConditionedFloorsAboveGrade", @ncfl_ag)
    XMLHelper.add_element(new_construction, "NumberofBedrooms", @nbeds)
    XMLHelper.add_element(new_construction, "ConditionedFloorArea", @cfa)
    XMLHelper.add_element(new_construction, "ConditionedBuildingVolume", @cvolume)
    XMLHelper.add_element(new_construction, "GaragePresent", @garage_present)
  end

  def self.set_enclosure_air_infiltration_reference(new_enclosure, orig_details)
    new_infil = XMLHelper.add_element(new_enclosure, "AirInfiltration")

    # Table 4.2.2(1) - Air exchange rate
    sla = 0.00036

    # Convert to other forms
    nach = Airflow.get_infiltration_ACH_from_SLA(sla, @ncfl_ag, @weather)
    ach50 = Airflow.get_infiltration_ACH50_from_SLA(sla, 0.67, @cfa, @cvolume)

    # nACH
    new_infil_meas = XMLHelper.add_element(new_infil, "AirInfiltrationMeasurement")
    sys_id = XMLHelper.add_element(new_infil_meas, "SystemIdentifier")
    XMLHelper.add_attribute(sys_id, "id", "Infiltration_ACHnatural")
    new_bldg_air_lkg = XMLHelper.add_element(new_infil_meas, "BuildingAirLeakage")
    XMLHelper.add_element(new_bldg_air_lkg, "UnitofMeasure", "ACHnatural")
    XMLHelper.add_element(new_bldg_air_lkg, "AirLeakage", nach)

    # ACH50
    new_infil_meas = XMLHelper.add_element(new_infil, "AirInfiltrationMeasurement")
    sys_id = XMLHelper.add_element(new_infil_meas, "SystemIdentifier")
    XMLHelper.add_attribute(sys_id, "id", "Infiltration_ACH50")
    XMLHelper.add_element(new_infil_meas, "HousePressure", 50)
    new_bldg_air_lkg = XMLHelper.add_element(new_infil_meas, "BuildingAirLeakage")
    XMLHelper.add_element(new_bldg_air_lkg, "UnitofMeasure", "ACH")
    XMLHelper.add_element(new_bldg_air_lkg, "AirLeakage", ach50)

    # ELA/SLA
    ela = sla * @cfa
    new_infil_meas = XMLHelper.add_element(new_infil, "AirInfiltrationMeasurement")
    sys_id = XMLHelper.add_element(new_infil_meas, "SystemIdentifier")
    XMLHelper.add_attribute(sys_id, "id", "Infiltration_ELA_SLA")
    XMLHelper.add_element(new_infil_meas, "EffectiveLeakageArea", ela)
    extension = XMLHelper.add_element(new_infil, "extension")
    XMLHelper.add_element(extension, "BuildingSpecificLeakageArea", sla)
  end

  def self.set_enclosure_air_infiltration_rated(new_enclosure, orig_details)
    new_infil = XMLHelper.add_element(new_enclosure, "AirInfiltration")
    orig_infil = orig_details.elements["Enclosure/AirInfiltration"]
    orig_mv = orig_details.elements["Systems/MechanicalVentilation"]

    # Table 4.2.2(1) - Air exchange rate

    whole_house_fan = nil
    if not orig_mv.nil?
      whole_house_fan = orig_mv.elements["VentilationFans/VentilationFan[UsedForWholeBuildingVentilation='true']"]
    end

    if not orig_infil.elements["AirInfiltrationMeasurement/BuildingAirLeakage[UnitofMeasure='ACHnatural']/AirLeakage"].nil?
      nach = Float(XMLHelper.get_value(orig_infil, "AirInfiltrationMeasurement/BuildingAirLeakage[UnitofMeasure='ACHnatural']/AirLeakage"))
      if whole_house_fan.nil? and nach < 0.30
        nach = 0.30
      end
      # Convert to other forms
      sla = Airflow.get_infiltration_SLA_from_ACH(nach, @ncfl_ag, @weather)
      ela = sla * @cfa
      ach50 = Airflow.get_infiltration_ACH50_from_SLA(sla, 0.67, @cfa, @cvolume)
    elsif not orig_infil.elements["AirInfiltrationMeasurement[HousePressure='50']/BuildingAirLeakage[UnitofMeasure='ACH']/AirLeakage"].nil?
      ach50 = Float(XMLHelper.get_value(orig_infil, "AirInfiltrationMeasurement[HousePressure='50']/BuildingAirLeakage[UnitofMeasure='ACH']/AirLeakage"))
      # Convert to other forms
      sla = Airflow.get_infiltration_SLA_from_ACH50(ach50, 0.67, @cfa, @cvolume)
      ela = sla * @cfa
      nach = Airflow.get_infiltration_ACH_from_SLA(sla, @ncfl_ag, @weather)
    end

    # nACH
    new_infil_meas = XMLHelper.add_element(new_infil, "AirInfiltrationMeasurement")
    sys_id = XMLHelper.add_element(new_infil_meas, "SystemIdentifier")
    XMLHelper.add_attribute(sys_id, "id", "Infiltration_ACHnatural")
    new_bldg_air_lkg = XMLHelper.add_element(new_infil_meas, "BuildingAirLeakage")
    XMLHelper.add_element(new_bldg_air_lkg, "UnitofMeasure", "ACHnatural")
    XMLHelper.add_element(new_bldg_air_lkg, "AirLeakage", nach)

    # ACH50
    new_infil_meas = XMLHelper.add_element(new_infil, "AirInfiltrationMeasurement")
    sys_id = XMLHelper.add_element(new_infil_meas, "SystemIdentifier")
    XMLHelper.add_attribute(sys_id, "id", "Infiltration_ACH50")
    XMLHelper.add_element(new_infil_meas, "HousePressure", 50)
    new_bldg_air_lkg = XMLHelper.add_element(new_infil_meas, "BuildingAirLeakage")
    XMLHelper.add_element(new_bldg_air_lkg, "UnitofMeasure", "ACH")
    XMLHelper.add_element(new_bldg_air_lkg, "AirLeakage", ach50)

    # ELA/SLA
    new_infil_meas = XMLHelper.add_element(new_infil, "AirInfiltrationMeasurement")
    sys_id = XMLHelper.add_element(new_infil_meas, "SystemIdentifier")
    XMLHelper.add_attribute(sys_id, "id", "Infiltration_ELA_SLA")
    XMLHelper.add_element(new_infil_meas, "EffectiveLeakageArea", ela)
    extension = XMLHelper.add_element(new_infil, "extension")
    XMLHelper.add_element(extension, "BuildingSpecificLeakageArea", sla)
  end

  def self.set_enclosure_air_infiltration_iad(new_enclosure, orig_details)
    new_infil = XMLHelper.add_element(new_enclosure, "AirInfiltration")
    orig_infil = orig_details.elements["Enclosure/AirInfiltration"]

    # Table 4.3.1(1) Configuration of Index Adjustment Design - Air exchange rate
    if ["1A", "1B", "1C", "2A", "2B", "2C"].include? @iecc_zone_2012
      ach50 = 3.0
    elsif ["3A", "3B", "3C", "4A", "4B", "4C", "5A", "5B", "5C", "6A", "6B", "6C", "7", "8"].include? @iecc_zone_2012
      ach50 = 5.0
    else
      fail "Unhandled IECC 2012 climate zone #{@iecc_zone_2012}."
    end

    # Convert to other forms
    sla = Airflow.get_infiltration_SLA_from_ACH50(ach50, 0.67, @cfa, @cvolume)
    nach = Airflow.get_infiltration_ACH_from_SLA(sla, @ncfl_ag, @weather)

    # nACH
    new_infil_meas = XMLHelper.add_element(new_infil, "AirInfiltrationMeasurement")
    sys_id = XMLHelper.add_element(new_infil_meas, "SystemIdentifier")
    XMLHelper.add_attribute(sys_id, "id", "Infiltration_ACHnatural")
    new_bldg_air_lkg = XMLHelper.add_element(new_infil_meas, "BuildingAirLeakage")
    XMLHelper.add_element(new_bldg_air_lkg, "UnitofMeasure", "ACHnatural")
    XMLHelper.add_element(new_bldg_air_lkg, "AirLeakage", nach)

    # ACH50
    new_infil_meas = XMLHelper.add_element(new_infil, "AirInfiltrationMeasurement")
    sys_id = XMLHelper.add_element(new_infil_meas, "SystemIdentifier")
    XMLHelper.add_attribute(sys_id, "id", "Infiltration_ACH50")
    XMLHelper.add_element(new_infil_meas, "HousePressure", 50)
    new_bldg_air_lkg = XMLHelper.add_element(new_infil_meas, "BuildingAirLeakage")
    XMLHelper.add_element(new_bldg_air_lkg, "UnitofMeasure", "ACH")
    XMLHelper.add_element(new_bldg_air_lkg, "AirLeakage", ach50)

    # ELA/SLA
    ela = sla * @cfa
    new_infil_meas = XMLHelper.add_element(new_infil, "AirInfiltrationMeasurement")
    sys_id = XMLHelper.add_element(new_infil_meas, "SystemIdentifier")
    XMLHelper.add_attribute(sys_id, "id", "Infiltration_ELA_SLA")
    XMLHelper.add_element(new_infil_meas, "EffectiveLeakageArea", ela)
    extension = XMLHelper.add_element(new_infil, "extension")
    XMLHelper.add_element(extension, "BuildingSpecificLeakageArea", sla)
  end

  def self.set_enclosure_attics_roofs_reference(new_enclosure, orig_details)
    new_attic_roof = XMLHelper.copy_element(new_enclosure, orig_details, "Enclosure/AtticAndRoof")

    ceiling_ufactor = FloorConstructions.get_default_ceiling_ufactor(@iecc_zone_2006)
    wall_ufactor = WallConstructions.get_default_frame_wall_ufactor(@iecc_zone_2006)

    new_attic_roof.elements.each("Attics/Attic") do |new_attic|
      attic_type = XMLHelper.get_value(new_attic, "AtticType")
      if ['unvented attic', 'vented attic'].include? attic_type
        attic_type = 'vented attic'
        new_attic.elements["AtticType"].text = attic_type
      end
      interior_adjacent_to = attic_type

      # Table 4.2.2(1) - Roofs
      new_attic.elements.each("Roofs/Roof") do |new_roof|
        new_roof.elements["RadiantBarrier"].text = false
        new_roof.elements["SolarAbsorptance"].text = 0.75
        new_roof.elements["Emittance"].text = 0.90
        if is_external_thermal_boundary(interior_adjacent_to, "ambient")
          new_roof_ins = new_roof.elements["Insulation"]
          XMLHelper.delete_element(new_roof_ins, "AssemblyEffectiveRValue")
          XMLHelper.delete_element(new_roof_ins, "Layer")
          XMLHelper.add_element(new_roof_ins, "AssemblyEffectiveRValue", 1.0 / ceiling_ufactor)
        end
      end

      # Table 4.2.2(1) - Ceilings
      new_attic.elements.each("Floors/Floor") do |new_floor|
        exterior_adjacent_to = XMLHelper.get_value(new_floor, "extension/ExteriorAdjacentTo")
        if is_external_thermal_boundary(interior_adjacent_to, exterior_adjacent_to)
          new_floor_ins = new_floor.elements["Insulation"]
          XMLHelper.delete_element(new_floor_ins, "AssemblyEffectiveRValue")
          XMLHelper.delete_element(new_floor_ins, "Layer")
          XMLHelper.add_element(new_floor_ins, "AssemblyEffectiveRValue", 1.0 / ceiling_ufactor)
        end
      end

      # Table 4.2.2(1) - Above-grade walls
      new_attic.elements.each("Walls/Wall") do |new_wall|
        exterior_adjacent_to = XMLHelper.get_value(new_wall, "extension/ExteriorAdjacentTo")
        if is_external_thermal_boundary(interior_adjacent_to, exterior_adjacent_to)
          new_wall_ins = new_wall.elements["Insulation"]
          XMLHelper.delete_element(new_wall_ins, "AssemblyEffectiveRValue")
          XMLHelper.delete_element(new_wall_ins, "Layer")
          XMLHelper.add_element(new_wall_ins, "AssemblyEffectiveRValue", 1.0 / wall_ufactor)
        end
      end

      # Table 4.2.2(1) - Attics
      if attic_type == 'vented attic'
        extension = new_attic.elements["extension"]
        if extension.nil?
          extension = XMLHelper.add_element(new_attic, "extension")
        end
        XMLHelper.delete_element(extension, "AtticSpecificLeakageArea")
        XMLHelper.add_element(extension, "AtticSpecificLeakageArea", Airflow.get_default_vented_attic_sla())
      end
    end
  end

  def self.set_enclosure_attics_roofs_rated(new_enclosure, orig_details)
    new_attic_roof = XMLHelper.copy_element(new_enclosure, orig_details, "Enclosure/AtticAndRoof")
  end

  def self.set_enclosure_attics_roofs_iad(new_enclosure, orig_details)
    set_enclosure_attics_roofs_rated(new_enclosure, orig_details)

    new_attic_roof = new_enclosure.elements["AtticAndRoof"]

    new_attic_roof.elements.each("Attics/Attic") do |new_attic|
      # Table 4.3.1(1) Configuration of Index Adjustment Design - Roofs
      sum_roof_area = 0.0
      new_attic.elements.each("Roofs/Roof") do |new_roof|
        sum_roof_area += Float(XMLHelper.get_value(new_roof, "Area"))
      end
      new_attic.elements.each("Roofs/Roof") do |new_roof|
        roof_area = Float(XMLHelper.get_value(new_roof, "Area"))
        new_roof.elements["Area"].text = 1300.0 * roof_area / sum_roof_area
      end

      # Table 4.3.1(1) Configuration of Index Adjustment Design - Ceilings
      sum_floor_area = 0.0
      new_attic.elements.each("Floors/Floor") do |new_floor|
        sum_floor_area += Float(XMLHelper.get_value(new_floor, "Area"))
      end
      new_attic.elements.each("Floors/Floor") do |new_floor|
        floor_area = Float(XMLHelper.get_value(new_floor, "Area"))
        new_floor.elements["Area"].text = 1200.0 * floor_area / sum_floor_area
      end
    end
  end

  def self.set_enclosure_foundations_reference(new_enclosure, orig_details)
    new_foundations = XMLHelper.copy_element(new_enclosure, orig_details, "Enclosure/Foundations")

    floor_ufactor = FloorConstructions.get_default_floor_ufactor(@iecc_zone_2006)
    wall_ufactor = FoundationConstructions.get_default_basement_wall_ufactor(@iecc_zone_2006)
    slab_perim_rvalue, slab_perim_depth = FoundationConstructions.get_default_slab_perimeter_rvalue_depth(@iecc_zone_2006)
    slab_under_rvalue, slab_under_width = FoundationConstructions.get_default_slab_under_rvalue_width()

    new_foundations.elements.each("Foundation") do |new_foundation|
      if XMLHelper.has_element(new_foundation, "FoundationType/Crawlspace[Vented='false']")
        new_foundation.elements["FoundationType/Crawlspace/Vented"].text = true
      end

      fnd_type = new_foundation.elements["FoundationType"]
      interior_adjacent_to = get_foundation_interior_adjacent_to(fnd_type)

      # Table 4.2.2(1) - Floors over unconditioned spaces or outdoor environment
      new_foundation.elements.each("FrameFloor") do |new_floor|
        exterior_adjacent_to = XMLHelper.get_value(new_floor, "extension/ExteriorAdjacentTo")
        if is_external_thermal_boundary(interior_adjacent_to, exterior_adjacent_to)
          new_floor_ins = new_floor.elements["Insulation"]
          XMLHelper.delete_element(new_floor_ins, "AssemblyEffectiveRValue")
          XMLHelper.delete_element(new_floor_ins, "Layer")
          XMLHelper.add_element(new_floor_ins, "AssemblyEffectiveRValue", 1.0 / floor_ufactor)
        end
      end

      # Table 4.2.2(1) - Conditioned basement walls
      new_foundation.elements.each("FoundationWall") do |new_wall|
        exterior_adjacent_to = XMLHelper.get_value(new_wall, "extension/ExteriorAdjacentTo")
        # TODO: Can this just be is_external_thermal_boundary(interior_adjacent_to, exterior_adjacent_to)?
        if interior_adjacent_to == "conditioned basement" and is_external_thermal_boundary(interior_adjacent_to, exterior_adjacent_to)
          new_wall_ins = new_wall.elements["Insulation"]
          XMLHelper.delete_element(new_wall_ins, "AssemblyEffectiveRValue")
          XMLHelper.delete_element(new_wall_ins, "Layer")
          XMLHelper.add_element(new_wall_ins, "AssemblyEffectiveRValue", 1.0 / wall_ufactor)
        end
      end

      # Table 4.2.2(1) - Foundations
      new_foundation.elements.each("Slab") do |new_slab|
        # TODO: Can this just be is_external_thermal_boundary(interior_adjacent_to, "ground")?
        if interior_adjacent_to == "living space" and is_external_thermal_boundary(interior_adjacent_to, "ground")
          new_slab.elements["PerimeterInsulationDepth"].text = slab_perim_depth
          new_slab.elements["UnderSlabInsulationWidth"].text = slab_under_width
          perim_ins = new_slab.elements["PerimeterInsulation"]
          XMLHelper.delete_element(perim_ins, "Layer")
          perim_layer = XMLHelper.add_element(perim_ins, "Layer")
          XMLHelper.add_element(perim_layer, "InstallationType", "continuous")
          XMLHelper.add_element(perim_layer, "NominalRValue", slab_perim_rvalue)
          under_ins = new_slab.elements["UnderSlabInsulation"]
          XMLHelper.delete_element(under_ins, "Layer")
          under_layer = XMLHelper.add_element(under_ins, "Layer")
          XMLHelper.add_element(under_layer, "InstallationType", "continuous")
          XMLHelper.add_element(under_layer, "NominalRValue", slab_under_rvalue)
        end
        new_slab.elements["extension/CarpetFraction"].text = 0.8
        new_slab.elements["extension/CarpetRValue"].text = 2.0
      end

      # Table 4.2.2(1) - Crawlspaces
      if XMLHelper.has_element(new_foundation, "FoundationType/Crawlspace[Vented='true']")
        extension = new_foundation.elements["extension"]
        if extension.nil?
          extension = XMLHelper.add_element(new_foundation, "extension")
        end
        XMLHelper.delete_element(extension, "CrawlspaceSpecificLeakageArea")
        XMLHelper.add_element(extension, "CrawlspaceSpecificLeakageArea", Airflow.get_default_vented_crawl_sla())
      end
    end
  end

  def self.set_enclosure_foundations_rated(new_enclosure, orig_details)
    new_foundations = XMLHelper.copy_element(new_enclosure, orig_details, "Enclosure/Foundations")

    min_crawl_vent = Airflow.get_default_vented_crawl_sla() # Reference Home vent

    new_foundations.elements.each("Foundation") do |new_foundation|
      # Table 4.2.2(1) - Crawlspaces
      if XMLHelper.has_element(new_foundation, "FoundationType/Crawlspace[Vented='true']")
        vent = Float(XMLHelper.get_value(new_foundation, "extension/CrawlspaceSpecificLeakageArea"))
        # TODO: Handle approved ground cover
        if vent < min_crawl_vent
          new_foundation.elements["extension/CrawlspaceSpecificLeakageArea"].text = min_crawl_vent
        end
      end
    end
  end

  def self.set_enclosure_foundations_iad(new_enclosure, orig_details)
    # Table 4.3.1(1) Configuration of Index Adjustment Design - Foundation
    floor_ufactor = FloorConstructions.get_default_floor_ufactor(@iecc_zone_2006)

    new_foundation = XMLHelper.add_element(new_enclosure, "Foundations/Foundation")
    sys_id = XMLHelper.add_element(new_foundation, "SystemIdentifier")
    XMLHelper.add_attribute(sys_id, "id", "Foundation_Crawlspace")
    XMLHelper.add_element(new_foundation, "FoundationType/Crawlspace/Vented", true)

    # Ceiling
    new_floor = XMLHelper.add_element(new_foundation, "FrameFloor")
    sys_id = XMLHelper.add_element(new_floor, "SystemIdentifier")
    XMLHelper.add_attribute(sys_id, "id", "Foundation_Floor")
    XMLHelper.add_element(new_floor, "Area", 1200)
    new_floor_ins = XMLHelper.add_element(new_floor, "Insulation")
    sys_id = XMLHelper.add_element(new_floor_ins, "SystemIdentifier")
    XMLHelper.add_attribute(sys_id, "id", "Foundation_Floor_Ins")
    XMLHelper.add_element(new_floor_ins, "AssemblyEffectiveRValue", 1.0 / floor_ufactor)
    extension = XMLHelper.add_element(new_floor, "extension")
    XMLHelper.add_element(extension, "ExteriorAdjacentTo", "living space")

    # Wall
    new_wall = XMLHelper.add_element(new_foundation, "FoundationWall")
    sys_id = XMLHelper.add_element(new_wall, "SystemIdentifier")
    XMLHelper.add_attribute(sys_id, "id", "Foundation_Wall")
    XMLHelper.add_element(new_wall, "Height", 2)
    XMLHelper.add_element(new_wall, "Area", 2 * 34.64 * 4)
    XMLHelper.add_element(new_wall, "Thickness", 8)
    XMLHelper.add_element(new_wall, "DepthBelowGrade", 0)
    new_wall_ins = XMLHelper.add_element(new_wall, "Insulation")
    sys_id = XMLHelper.add_element(new_wall_ins, "SystemIdentifier")
    XMLHelper.add_attribute(sys_id, "id", "Foundation_Wall_Ins")
    XMLHelper.add_element(new_wall_ins, "AssemblyEffectiveRValue", 1.0 / floor_ufactor) # FIXME
    extension = XMLHelper.add_element(new_wall, "extension")
    XMLHelper.add_element(extension, "ExteriorAdjacentTo", "ground")

    # Floor
    new_slab = XMLHelper.add_element(new_foundation, "Slab")
    sys_id = XMLHelper.add_element(new_slab, "SystemIdentifier")
    XMLHelper.add_attribute(sys_id, "id", "Foundation_Slab")
    XMLHelper.add_element(new_slab, "Area", 1200)
    XMLHelper.add_element(new_slab, "Thickness", 0)
    XMLHelper.add_element(new_slab, "ExposedPerimeter", 4 * 34.64)
    XMLHelper.add_element(new_slab, "PerimeterInsulationDepth", 0)
    XMLHelper.add_element(new_slab, "UnderSlabInsulationWidth", 0)
    XMLHelper.add_element(new_slab, "DepthBelowGrade", 0)
    new_perim_ins = XMLHelper.add_element(new_slab, "PerimeterInsulation")
    sys_id = XMLHelper.add_element(new_perim_ins, "SystemIdentifier")
    XMLHelper.add_attribute(sys_id, "id", "Foundation_Slab_Perim_Ins")
    new_perim_ins_layer = XMLHelper.add_element(new_perim_ins, "Layer")
    XMLHelper.add_element(new_perim_ins_layer, "InstallationType", "continuous")
    XMLHelper.add_element(new_perim_ins_layer, "NominalRValue", 0)
    new_under_ins = XMLHelper.add_element(new_slab, "UnderSlabInsulation")
    sys_id = XMLHelper.add_element(new_under_ins, "SystemIdentifier")
    XMLHelper.add_attribute(sys_id, "id", "Foundation_Slab_Under_Ins")
    new_under_ins_layer = XMLHelper.add_element(new_under_ins, "Layer")
    XMLHelper.add_element(new_under_ins_layer, "InstallationType", "continuous")
    XMLHelper.add_element(new_under_ins_layer, "NominalRValue", 0)
    extension = XMLHelper.add_element(new_slab, "extension")
    XMLHelper.add_element(extension, "CarpetFraction", 0)
    XMLHelper.add_element(extension, "CarpetRValue", 0)

    XMLHelper.add_element(new_foundation, "extension/CrawlspaceSpecificLeakageArea", Airflow.get_default_vented_crawl_sla())
  end

  def self.set_enclosure_rim_joists_reference(new_enclosure, orig_details)
    new_rim_joists = XMLHelper.copy_element(new_enclosure, orig_details, "Enclosure/RimJoists")
    return if new_rim_joists.nil?

    # Table 4.2.2(1) - Above-grade walls
    ufactor = WallConstructions.get_default_frame_wall_ufactor(@iecc_zone_2006)

    new_rim_joists.elements.each("RimJoist") do |new_rim_joist|
      interior_adjacent_to = XMLHelper.get_value(new_rim_joist, "InteriorAdjacentTo")
      exterior_adjacent_to = XMLHelper.get_value(new_rim_joist, "ExteriorAdjacentTo")
      if is_external_thermal_boundary(interior_adjacent_to, exterior_adjacent_to)
        insulation = new_rim_joist.elements["Insulation"]
        XMLHelper.delete_element(insulation, "AssemblyEffectiveRValue")
        XMLHelper.delete_element(insulation, "Layer")
        XMLHelper.add_element(insulation, "AssemblyEffectiveRValue", 1.0 / ufactor)
      end
    end
  end

  def self.set_enclosure_rim_joists_rated(new_enclosure, orig_details)
    new_rim_joists = XMLHelper.copy_element(new_enclosure, orig_details, "Enclosure/RimJoists")

    # Table 4.2.2(1) - Above-grade walls
    # nop
  end

  def self.set_enclosure_rim_joists_iad(new_enclosure, orig_details)
    # Table 4.3.1(1) Configuration of Index Adjustment Design - Above-grade walls
    set_enclosure_rim_joists_rated(new_enclosure, orig_details)

    orig_rim_joists = orig_details.elements["Enclosure/RimJoists"]
    return if orig_rim_joists.nil?

    orig_walls = orig_details.elements["Enclosure/Walls"]

    sum_wall_area = 0.0
    orig_rim_joists.elements.each("RimJoist") do |orig_rim_joist|
      interior_adjacent_to = XMLHelper.get_value(orig_rim_joist, "InteriorAdjacentTo")
      exterior_adjacent_to = XMLHelper.get_value(orig_rim_joist, "ExteriorAdjacentTo")
      if is_external_thermal_boundary(interior_adjacent_to, exterior_adjacent_to)
        sum_wall_area += Float(XMLHelper.get_value(orig_rim_joist, "Area"))
      end
    end
    orig_walls.elements.each("Wall") do |orig_wall|
      interior_adjacent_to = XMLHelper.get_value(orig_wall, "extension/InteriorAdjacentTo")
      exterior_adjacent_to = XMLHelper.get_value(orig_wall, "extension/ExteriorAdjacentTo")
      if is_external_thermal_boundary(interior_adjacent_to, exterior_adjacent_to)
        sum_wall_area += Float(XMLHelper.get_value(orig_wall, "Area"))
      end
    end

    new_rim_joists = new_enclosure.elements["RimJoists"]

    new_rim_joists.elements.each("RimJoist") do |new_rim_joist|
      interior_adjacent_to = XMLHelper.get_value(new_rim_joist, "InteriorAdjacentTo")
      exterior_adjacent_to = XMLHelper.get_value(new_rim_joist, "ExteriorAdjacentTo")
      if is_external_thermal_boundary(interior_adjacent_to, exterior_adjacent_to)
        rim_joist_area = Float(XMLHelper.get_value(new_rim_joist, "Area"))
        new_rim_joist.elements["Area"].text = 2360.0 * rim_joist_area / sum_wall_area
      end
    end
  end

  def self.set_enclosure_walls_reference(new_enclosure, orig_details)
    new_walls = XMLHelper.copy_element(new_enclosure, orig_details, "Enclosure/Walls")

    # Table 4.2.2(1) - Above-grade walls
    ufactor = WallConstructions.get_default_frame_wall_ufactor(@iecc_zone_2006)

    new_walls.elements.each("Wall") do |new_wall|
      interior_adjacent_to = XMLHelper.get_value(new_wall, "extension/InteriorAdjacentTo")
      exterior_adjacent_to = XMLHelper.get_value(new_wall, "extension/ExteriorAdjacentTo")
      if is_external_thermal_boundary(interior_adjacent_to, exterior_adjacent_to)
        new_wall.elements["SolarAbsorptance"].text = 0.75
        new_wall.elements["Emittance"].text = 0.90
        insulation = new_wall.elements["Insulation"]
        XMLHelper.delete_element(insulation, "AssemblyEffectiveRValue")
        XMLHelper.delete_element(insulation, "Layer")
        XMLHelper.add_element(insulation, "AssemblyEffectiveRValue", 1.0 / ufactor)
      end
    end
  end

  def self.set_enclosure_walls_rated(new_enclosure, orig_details)
    new_walls = XMLHelper.copy_element(new_enclosure, orig_details, "Enclosure/Walls")

    # Table 4.2.2(1) - Above-grade walls
    # nop
  end

  def self.set_enclosure_walls_iad(new_enclosure, orig_details)
    # Table 4.3.1(1) Configuration of Index Adjustment Design - Above-grade walls
    set_enclosure_walls_rated(new_enclosure, orig_details)

    orig_walls = orig_details.elements["Enclosure/Walls"]
    orig_rim_joists = orig_details.elements["Enclosure/RimJoists"]

    sum_wall_area = 0.0
    orig_walls.elements.each("Wall") do |orig_wall|
      interior_adjacent_to = XMLHelper.get_value(orig_wall, "extension/InteriorAdjacentTo")
      exterior_adjacent_to = XMLHelper.get_value(orig_wall, "extension/ExteriorAdjacentTo")
      if is_external_thermal_boundary(interior_adjacent_to, exterior_adjacent_to)
        sum_wall_area += Float(XMLHelper.get_value(orig_wall, "Area"))
      end
    end
    if not orig_rim_joists.nil?
      orig_rim_joists.elements.each("RimJoist") do |orig_rim_joist|
        interior_adjacent_to = XMLHelper.get_value(orig_rim_joist, "InteriorAdjacentTo")
        exterior_adjacent_to = XMLHelper.get_value(orig_rim_joist, "ExteriorAdjacentTo")
        if is_external_thermal_boundary(interior_adjacent_to, exterior_adjacent_to)
          sum_wall_area += Float(XMLHelper.get_value(orig_rim_joist, "Area"))
        end
      end
    end

    new_walls = new_enclosure.elements["Walls"]

    new_walls.elements.each("Wall") do |new_wall|
      interior_adjacent_to = XMLHelper.get_value(new_wall, "extension/InteriorAdjacentTo")
      exterior_adjacent_to = XMLHelper.get_value(new_wall, "extension/ExteriorAdjacentTo")
      if is_external_thermal_boundary(interior_adjacent_to, exterior_adjacent_to)
        wall_area = Float(XMLHelper.get_value(new_wall, "Area"))
        new_wall.elements["Area"].text = 2360.0 * wall_area / sum_wall_area
      end
    end
  end

  def self.set_enclosure_windows_reference(new_enclosure, orig_details)
    # Table 4.2.2(1) - Glazing
    ufactor, shgc = SubsurfaceConstructions.get_default_ufactor_shgc(@iecc_zone_2006)

    ag_wall_area = 0.0
    bg_wall_area = 0.0

    orig_details.elements.each("Enclosure/Walls/Wall") do |wall|
      int_adj_to = XMLHelper.get_value(wall, "extension/InteriorAdjacentTo")
      ext_adj_to = XMLHelper.get_value(wall, "extension/ExteriorAdjacentTo")
      next if not ((int_adj_to == "living space" or ext_adj_to == "living space") and int_adj_to != ext_adj_to)

      area = Float(XMLHelper.get_value(wall, "Area"))
      ag_wall_area += area
    end

    orig_details.elements.each("Enclosure/Foundations/Foundation[FoundationType/Basement/Conditioned='true']/FoundationWall") do |fwall|
      adj_to = XMLHelper.get_value(fwall, "extension/ExteriorAdjacentTo")
      next if adj_to == "living space"

      height = Float(XMLHelper.get_value(fwall, "Height"))
      bg_depth = Float(XMLHelper.get_value(fwall, "DepthBelowGrade"))
      area = Float(XMLHelper.get_value(fwall, "Area"))
      ag_wall_area += (height - bg_depth) / height * area
      bg_wall_area += bg_depth / height * area
    end

    fa = ag_wall_area / (ag_wall_area + 0.5 * bg_wall_area)
    f = 1.0 # TODO

    total_window_area = 0.18 * @cfa * fa * f

    wall_area_fracs = get_exterior_wall_area_fracs(orig_details)

    # Create new windows
    new_windows = XMLHelper.add_element(new_enclosure, "Windows")
    for orientation, azimuth in { "north" => 0, "south" => 180, "east" => 90, "west" => 270 }
      window_area = 0.25 * total_window_area # Equal distribution to N/S/E/W
      # Distribute this orientation's window area proportionally across all exterior walls
      wall_area_fracs.each do |wall, wall_area_frac|
        wall_id = wall.elements["SystemIdentifier"].attributes["id"]
        new_window = XMLHelper.add_element(new_windows, "Window")
        sys_id = XMLHelper.add_element(new_window, "SystemIdentifier")
        XMLHelper.add_attribute(sys_id, "id", "Window_#{wall_id}_#{orientation}")
        XMLHelper.add_element(new_window, "Area", window_area * wall_area_frac)
        XMLHelper.add_element(new_window, "Azimuth", azimuth)
        XMLHelper.add_element(new_window, "UFactor", ufactor)
        XMLHelper.add_element(new_window, "SHGC", shgc)
        attwall = XMLHelper.add_element(new_window, "AttachedToWall")
        attwall.attributes["idref"] = wall_id
        set_window_interior_shading_reference(new_window)
      end
    end
  end

  def self.set_window_interior_shading_reference(window)
    shade_summer, shade_winter = SubsurfaceConstructions.get_default_interior_shading_factors()

    # Table 4.2.2(1) - Glazing
    extension = window.elements["extension"]
    if extension.nil?
      extension = XMLHelper.add_element(window, "extension")
    end
    XMLHelper.delete_element(extension, "InteriorShadingFactorSummer")
    XMLHelper.add_element(extension, "InteriorShadingFactorSummer", shade_summer)
    XMLHelper.delete_element(extension, "InteriorShadingFactorWinter")
    XMLHelper.add_element(extension, "InteriorShadingFactorWinter", shade_winter)
  end

  def self.set_enclosure_windows_rated(new_enclosure, orig_details)
    new_windows = XMLHelper.add_element(new_enclosure, "Windows")

    # Table 4.2.2(1) - Glazing
    orig_details.elements.each("Enclosure/Windows/Window") do |orig_window|
      new_window = XMLHelper.add_element(new_windows, "Window")
      XMLHelper.copy_element(new_window, orig_window, "SystemIdentifier")
      XMLHelper.copy_element(new_window, orig_window, "Area")
      XMLHelper.copy_element(new_window, orig_window, "Azimuth")
      XMLHelper.copy_element(new_window, orig_window, "UFactor")
      XMLHelper.copy_element(new_window, orig_window, "SHGC")
      XMLHelper.copy_element(new_window, orig_window, "Overhangs")
      XMLHelper.copy_element(new_window, orig_window, "AttachedToWall")
      set_window_interior_shading_reference(new_window)
    end
  end

  def self.set_enclosure_windows_iad(new_enclosure, orig_details)
    # Table 4.3.1(1) Configuration of Index Adjustment Design - Glazing
    set_enclosure_windows_reference(new_enclosure, orig_details)

    new_windows = new_enclosure.elements["Windows"]

    # Calculate area-weighted averages
    sum_u_a = 0.0
    sum_shgc_a = 0.0
    sum_a = 0.0
    new_windows.elements.each("Window") do |new_window|
      window_area = Float(XMLHelper.get_value(new_window, "Area"))
      sum_a += window_area
      sum_u_a += (window_area * Float(XMLHelper.get_value(new_window, "UFactor")))
      sum_shgc_a += (window_area * Float(XMLHelper.get_value(new_window, "SHGC")))
    end
    avg_u = sum_u_a / sum_a
    avg_shgc = sum_shgc_a / sum_a

    new_windows.elements.each("Window") do |new_window|
      new_window.elements["UFactor"].text = avg_u
      new_window.elements["SHGC"].text = avg_shgc
    end
  end

  def self.set_enclosure_skylights_reference(enclosure)
    # Table 4.2.2(1) - Skylights
    # nop
  end

  def self.set_enclosure_skylights_rated(new_enclosure, orig_details)
    return if not XMLHelper.has_element(new_enclosure, "Skylights")

    new_skylights = XMLHelper.add_element(new_enclosure, "Skylights")

    # Table 4.2.2(1) - Skylights
    orig_details.elements.each("Enclosure/Skylights/Skylight") do |orig_skylight|
      new_skylight = XMLHelper.add_element(new_skylights, "Skylight")
      XMLHelper.copy_element(new_skylight, orig_skylight, "SystemIdentifier")
      XMLHelper.copy_element(new_skylight, orig_skylight, "Area")
      XMLHelper.copy_element(new_skylight, orig_skylight, "Azimuth")
      XMLHelper.copy_element(new_skylight, orig_skylight, "UFactor")
      XMLHelper.copy_element(new_skylight, orig_skylight, "SHGC")
      XMLHelper.copy_element(new_skylight, orig_skylight, "AttachedToRoof")
    end
  end

  def self.set_enclosure_skylights_iad(new_enclosure, orig_details)
    # Table 4.3.1(1) Configuration of Index Adjustment Design - Skylights
    set_enclosure_skylights_rated(new_enclosure, orig_details)
  end

  def self.set_enclosure_doors_reference(new_enclosure, orig_details)
    # Table 4.2.2(1) - Doors
    ufactor, shgc = SubsurfaceConstructions.get_default_ufactor_shgc(@iecc_zone_2006)
    door_area = SubsurfaceConstructions.get_default_door_area()

    wall_area_fracs = get_exterior_wall_area_fracs(orig_details)

    # Create new doors
    new_doors = XMLHelper.add_element(new_enclosure, "Doors")
    # Distribute door area proportionally across all exterior walls
    wall_area_fracs.each do |wall, wall_area_frac|
      wall_id = wall.elements["SystemIdentifier"].attributes["id"]
      new_door = XMLHelper.add_element(new_doors, "Door")
      sys_id = XMLHelper.add_element(new_door, "SystemIdentifier")
      XMLHelper.add_attribute(sys_id, "id", "Door_#{wall_id}")
      attwall = XMLHelper.add_element(new_door, "AttachedToWall")
      attwall.attributes["idref"] = wall_id
      XMLHelper.add_element(new_door, "Area", door_area * wall_area_frac)
      XMLHelper.add_element(new_door, "Azimuth", 0)
      XMLHelper.add_element(new_door, "RValue", 1.0 / ufactor)
    end
  end

  def self.set_enclosure_doors_rated(new_enclosure, orig_details)
    new_doors = XMLHelper.add_element(new_enclosure, "Doors")

    # Table 4.2.2(1) - Doors
    orig_details.elements.each("Enclosure/Doors/Door") do |orig_door|
      new_door = XMLHelper.add_element(new_doors, "Door")
      XMLHelper.copy_element(new_door, orig_door, "SystemIdentifier")
      XMLHelper.copy_element(new_door, orig_door, "AttachedToWall")
      XMLHelper.copy_element(new_door, orig_door, "Area")
      XMLHelper.copy_element(new_door, orig_door, "Azimuth")
      XMLHelper.copy_element(new_door, orig_door, "RValue")
    end
  end

  def self.set_enclosure_doors_iad(new_enclosure, orig_details)
    # Table 4.3.1(1) Configuration of Index Adjustment Design - Doors
    set_enclosure_doors_rated(new_enclosure, orig_details)
  end

  def self.set_systems_hvac_reference(new_systems, orig_details)
    new_hvac = XMLHelper.add_element(new_systems, "HVAC")

    # Table 4.2.2(1) - Heating systems
    # Table 4.2.2(1) - Cooling systems

    prevent_hp_and_ac = true # TODO: Eventually allow this...

    has_boiler = false
    fuel_type = nil
    heating_system = orig_details.elements["Systems/HVAC/HVACPlant/HeatingSystem"]
    heat_pump_system = orig_details.elements["Systems/HVAC/HVACPlant/HeatPump"]
    if not heating_system.nil?
      has_boiler = XMLHelper.has_element(heating_system, "HeatingSystemType/Boiler")
      fuel_type = XMLHelper.get_value(heating_system, "HeatingSystemFuel")
    elsif not heat_pump_system.nil?
      fuel_type = 'electricity'
    end

    new_hvac_plant = XMLHelper.add_element(new_hvac, "HVACPlant")

    # Heating
    heat_type = nil
    if heating_system.nil? and heat_pump_system.nil?
      if has_fuel_access(orig_details)
        heat_type = "GasFurnace"
      else
        heat_type = "HeatPump"
      end
    elsif fuel_type == 'electricity'
      heat_type = "HeatPump"
    elsif has_boiler
      heat_type = "GasBoiler"
    else
      heat_type = "GasFurnace"
    end

    # Cooling
    cool_type = "AirConditioner"
    if prevent_hp_and_ac and heat_type == "HeatPump"
      cool_type = "HeatPump"
    end

    # HeatingSystems
    if heat_type == "GasFurnace"

      # 78% AFUE gas furnace
      afue = 0.78
      heat_sys = XMLHelper.add_element(new_hvac_plant, "HeatingSystem")
      sys_id = XMLHelper.add_element(heat_sys, "SystemIdentifier")
      XMLHelper.add_attribute(sys_id, "id", "HeatingSystem")
      dist = XMLHelper.add_element(heat_sys, "DistributionSystem")
      XMLHelper.add_attribute(dist, "idref", "HVACDistribution")
      sys_type = XMLHelper.add_element(heat_sys, "HeatingSystemType")
      furnace = XMLHelper.add_element(sys_type, "Furnace")
      XMLHelper.add_element(heat_sys, "HeatingSystemFuel", "natural gas")
      XMLHelper.add_element(heat_sys, "HeatingCapacity", -1) # Use Manual J auto-sizing
      heat_eff = XMLHelper.add_element(heat_sys, "AnnualHeatingEfficiency")
      XMLHelper.add_element(heat_eff, "Units", "AFUE")
      XMLHelper.add_element(heat_eff, "Value", afue)
      XMLHelper.add_element(heat_sys, "FractionHeatLoadServed", 1.0)

    elsif heat_type == "GasBoiler"

      # 80% AFUE gas boiler
      afue = 0.80
      heat_sys = XMLHelper.add_element(new_hvac_plant, "HeatingSystem")
      sys_id = XMLHelper.add_element(heat_sys, "SystemIdentifier")
      XMLHelper.add_attribute(sys_id, "id", "HeatingSystem")
      dist = XMLHelper.add_element(heat_sys, "DistributionSystem")
      XMLHelper.add_attribute(dist, "idref", "HVACDistribution")
      sys_type = XMLHelper.add_element(heat_sys, "HeatingSystemType")
      boiler = XMLHelper.add_element(sys_type, "Boiler")
      XMLHelper.add_element(boiler, "BoilerType", "hot water")
      XMLHelper.add_element(heat_sys, "HeatingSystemFuel", "natural gas")
      XMLHelper.add_element(heat_sys, "HeatingCapacity", -1) # Use Manual J auto-sizing
      heat_eff = XMLHelper.add_element(heat_sys, "AnnualHeatingEfficiency")
      XMLHelper.add_element(heat_eff, "Units", "AFUE")
      XMLHelper.add_element(heat_eff, "Value", afue)
      XMLHelper.add_element(heat_sys, "FractionHeatLoadServed", 1.0)

    end

    # CoolingSystems
    if cool_type == "AirConditioner"

      # 13 SEER electric air conditioner
      seer = 13.0
      cool_sys = XMLHelper.add_element(new_hvac_plant, "CoolingSystem")
      sys_id = XMLHelper.add_element(cool_sys, "SystemIdentifier")
      XMLHelper.add_attribute(sys_id, "id", "CoolingSystem")
      dist = XMLHelper.add_element(cool_sys, "DistributionSystem")
      XMLHelper.add_attribute(dist, "idref", "HVACDistribution")
      XMLHelper.add_element(cool_sys, "CoolingSystemType", "central air conditioning")
      XMLHelper.add_element(cool_sys, "CoolingSystemFuel", "electricity")
      XMLHelper.add_element(cool_sys, "CoolingCapacity", -1) # Use Manual J auto-sizing
      XMLHelper.add_element(cool_sys, "FractionCoolLoadServed", 1.0)
      cool_eff = XMLHelper.add_element(cool_sys, "AnnualCoolingEfficiency")
      XMLHelper.add_element(cool_eff, "Units", "SEER")
      XMLHelper.add_element(cool_eff, "Value", seer)

    end

    # HeatPump
    if heat_type == "HeatPump"

      # 7.7 HSPF air source heat pump
      hspf = 7.7
      heat_pump = XMLHelper.add_element(new_hvac_plant, "HeatPump")
      sys_id = XMLHelper.add_element(heat_pump, "SystemIdentifier")
      XMLHelper.add_attribute(sys_id, "id", "HeatPump")
      dist = XMLHelper.add_element(heat_pump, "DistributionSystem")
      XMLHelper.add_attribute(dist, "idref", "HVACDistribution")
      XMLHelper.add_element(heat_pump, "HeatPumpType", "air-to-air")
      XMLHelper.add_element(heat_pump, "HeatingCapacity", -1) # Use Manual J auto-sizing
      XMLHelper.add_element(heat_pump, "CoolingCapacity", -1) # Use Manual J auto-sizing
      XMLHelper.add_element(heat_pump, "FractionHeatLoadServed", 1.0)
      if prevent_hp_and_ac
        XMLHelper.add_element(heat_pump, "FractionCoolLoadServed", 1.0)
        seer = 13.0
        cool_eff = XMLHelper.add_element(heat_pump, "AnnualCoolingEfficiency")
        XMLHelper.add_element(cool_eff, "Units", "SEER")
        XMLHelper.add_element(cool_eff, "Value", seer)
      end
      heat_eff = XMLHelper.add_element(heat_pump, "AnnualHeatingEfficiency")
      XMLHelper.add_element(heat_eff, "Units", "HSPF")
      XMLHelper.add_element(heat_eff, "Value", hspf)

    end

    # Table 303.4.1(1) - Thermostat
    new_hvac_control = XMLHelper.add_element(new_hvac, "HVACControl")
    sys_id = XMLHelper.add_element(new_hvac_control, "SystemIdentifier")
    XMLHelper.add_attribute(sys_id, "id", "HVACControl")
    XMLHelper.add_element(new_hvac_control, "ControlType", "manual thermostat")

    # Table 4.2.2(1) - Thermal distribution systems
    new_hvac_dist = XMLHelper.add_element(new_hvac, "HVACDistribution")
    sys_id = XMLHelper.add_element(new_hvac_dist, "SystemIdentifier")
    XMLHelper.add_attribute(sys_id, "id", "HVACDistribution")
    XMLHelper.add_element(new_hvac_dist, "DistributionSystemType/Other", "DSE")
    XMLHelper.add_element(new_hvac_dist, "AnnualHeatingDistributionSystemEfficiency", 0.8)
    XMLHelper.add_element(new_hvac_dist, "AnnualCoolingDistributionSystemEfficiency", 0.8)
  end

  def self.set_systems_hvac_rated(new_systems, orig_details)
    new_hvac = XMLHelper.add_element(new_systems, "HVAC")

    # Table 4.2.2(1) - Heating systems
    # Table 4.2.2(1) - Cooling systems

    heating_system = orig_details.elements["Systems/HVAC/HVACPlant/HeatingSystem"]
    heat_pump_system = orig_details.elements["Systems/HVAC/HVACPlant/HeatPump"]
    cooling_system = orig_details.elements["Systems/HVAC/HVACPlant/CoolingSystem"]

    new_hvac_plant = XMLHelper.add_element(new_hvac, "HVACPlant")

    dist_id = nil
    if orig_details.elements["Systems/HVAC/HVACDistribution"]
      dist_id = orig_details.elements["Systems/HVAC/HVACDistribution/SystemIdentifier"].attributes["id"]
    end

    # Heating
    heat_type = nil
    if heating_system.nil? and heat_pump_system.nil?
      if has_fuel_access(orig_details)
        heat_type = "GasFurnace" # override
      else
        heat_type = "HeatPump" # override
      end
    end

    # Cooling
    cool_type = nil
    if cooling_system.nil? and heat_pump_system.nil?
      cool_type = "AirConditioner" # override
    end

    # HeatingSystems
    if not heating_system.nil?

      # Retain heating system
      heating_system = XMLHelper.copy_element(new_hvac_plant, orig_details, "Systems/HVAC/HVACPlant/HeatingSystem")

    elsif heat_type == "GasFurnace"

      # 78% AFUE gas furnace
      afue = 0.78
      heating_system = XMLHelper.add_element(new_hvac_plant, "HeatingSystem")
      sys_id = XMLHelper.add_element(heating_system, "SystemIdentifier")
      XMLHelper.add_attribute(sys_id, "id", "HeatingSystem")
      if not dist_id.nil?
        dist = XMLHelper.add_element(heating_system, "DistributionSystem")
        XMLHelper.add_attribute(dist, "idref", dist_id)
      end
      sys_type = XMLHelper.add_element(heating_system, "HeatingSystemType")
      furnace = XMLHelper.add_element(sys_type, "Furnace")
      XMLHelper.add_element(heating_system, "HeatingSystemFuel", "natural gas")
      XMLHelper.add_element(heating_system, "HeatingCapacity", -1) # Use Manual J auto-sizing
      heat_eff = XMLHelper.add_element(heating_system, "AnnualHeatingEfficiency")
      XMLHelper.add_element(heat_eff, "Units", "AFUE")
      XMLHelper.add_element(heat_eff, "Value", afue)
      XMLHelper.add_element(heating_system, "FractionHeatLoadServed", 1.0)

    end

    # CoolingSystems
    if not cooling_system.nil?

      # Retain cooling system
      cooling_system = XMLHelper.copy_element(new_hvac_plant, orig_details, "Systems/HVAC/HVACPlant/CoolingSystem")

    elsif cool_type == "AirConditioner"

      # 13 SEER electric air conditioner
      seer = 13.0
      cooling_system = XMLHelper.add_element(new_hvac_plant, "CoolingSystem")
      sys_id = XMLHelper.add_element(cooling_system, "SystemIdentifier")
      XMLHelper.add_attribute(sys_id, "id", "CoolingSystem")
      if not dist_id.nil?
        dist = XMLHelper.add_element(cooling_system, "DistributionSystem")
        XMLHelper.add_attribute(dist, "idref", dist_id)
      end
      XMLHelper.add_element(cooling_system, "CoolingSystemType", "central air conditioning")
      XMLHelper.add_element(cooling_system, "CoolingSystemFuel", "electricity")
      XMLHelper.add_element(cooling_system, "CoolingCapacity", -1) # Use Manual J auto-sizing
      XMLHelper.add_element(cooling_system, "FractionCoolLoadServed", 1.0)
      cool_eff = XMLHelper.add_element(cooling_system, "AnnualCoolingEfficiency")
      XMLHelper.add_element(cool_eff, "Units", "SEER")
      XMLHelper.add_element(cool_eff, "Value", seer)

    end

    # HeatPump
    if not heat_pump_system.nil?

      # Retain heating system
      heat_pump_system = XMLHelper.copy_element(new_hvac_plant, orig_details, "Systems/HVAC/HVACPlant/HeatPump")

    elsif heat_type == "HeatPump"

      # 7.7 HSPF air source heat pump
      hspf = 7.7
      heat_pump = XMLHelper.add_element(new_hvac_plant, "HeatPump")
      sys_id = XMLHelper.add_element(heat_pump, "SystemIdentifier")
      if not dist_id.nil?
        dist = XMLHelper.add_element(heat_pump, "DistributionSystem")
        XMLHelper.add_attribute(dist, "idref", dist_id)
      end
      XMLHelper.add_attribute(sys_id, "id", "HeatPump")
      XMLHelper.add_element(heat_pump, "HeatPumpType", "air-to-air")
      XMLHelper.add_element(heat_pump, "HeatingCapacity", -1) # Use Manual J auto-sizing
      XMLHelper.add_element(heat_pump, "CoolingCapacity", -1) # Use Manual J auto-sizing
      XMLHelper.add_element(heat_pump, "FractionHeatLoadServed", 1.0)
      XMLHelper.add_element(heat_pump, "FractionCoolLoadServed", 1.0)
      cool_eff = XMLHelper.add_element(heat_pump, "AnnualCoolingEfficiency")
      XMLHelper.add_element(cool_eff, "Units", "SEER")
      XMLHelper.add_element(cool_eff, "Value", 13.0)
      heat_eff = XMLHelper.add_element(heat_pump, "AnnualHeatingEfficiency")
      XMLHelper.add_element(heat_eff, "Units", "HSPF")
      XMLHelper.add_element(heat_eff, "Value", hspf)

    end

    # Table 303.4.1(1) - Thermostat
    if not orig_details.elements["Systems/HVAC/HVACControl"].nil?
      orig_hvac_control = orig_details.elements["Systems/HVAC/HVACControl"]
      new_hvac_control = XMLHelper.add_element(new_hvac, "HVACControl")
      XMLHelper.copy_element(new_hvac_control, orig_hvac_control, "SystemIdentifier")
      XMLHelper.copy_element(new_hvac_control, orig_hvac_control, "ControlType")
    else
      new_hvac_control = XMLHelper.add_element(new_hvac, "HVACControl")
      sys_id = XMLHelper.add_element(new_hvac_control, "SystemIdentifier")
      XMLHelper.add_attribute(sys_id, "id", "HVACControl")
      XMLHelper.add_element(new_hvac_control, "ControlType", "manual thermostat")
    end

    # Table 4.2.2(1) - Thermal distribution systems
    # FIXME: There can be no distribution system when HVAC prescribed via above
    #        e.g., no cooling system => AC w/o ducts. Is this right?
    XMLHelper.copy_element(new_hvac, orig_details, "Systems/HVAC/HVACDistribution")
  end

  def self.set_systems_hvac_iad(new_systems, orig_details)
    # Table 4.3.1(1) Configuration of Index Adjustment Design - Heating systems
    # Table 4.3.1(1) Configuration of Index Adjustment Design - Cooling systems
    # Table 4.3.1(1) Configuration of Index Adjustment Design - Thermostat
    set_systems_hvac_reference(new_systems, orig_details)

    # Table 4.3.1(1) Configuration of Index Adjustment Design - Thermal distribution systems
    # Change DSE to 1.0
    new_hvac_dist = new_systems.elements["HVAC/HVACDistribution"]
    new_hvac_dist.elements["AnnualHeatingDistributionSystemEfficiency"].text = 1.0
    new_hvac_dist.elements["AnnualCoolingDistributionSystemEfficiency"].text = 1.0
  end

  def self.set_systems_mechanical_ventilation_reference(new_systems, orig_details, new_enclosure)
    # Table 4.2.2(1) - Whole-House Mechanical ventilation

    # Init
    fan_type = nil

    orig_whole_house_fan = orig_details.elements["Systems/MechanicalVentilation/VentilationFans/VentilationFan[UsedForWholeBuildingVentilation='true']"]

    if not orig_whole_house_fan.nil?

      fan_type = XMLHelper.get_value(orig_whole_house_fan, "FanType")

      q_tot = Airflow.get_mech_vent_whole_house_cfm(1.0, @nbeds, @cfa, '2013')

      # Calculate fan cfm for airflow rate using Reference Home infiltration
      # http://www.resnet.us/standards/Interpretation_on_Reference_Home_Air_Exchange_Rate_approved.pdf
      sla = Float(XMLHelper.get_value(new_enclosure, "AirInfiltration/extension/BuildingSpecificLeakageArea"))
      q_fan_airflow = calc_mech_vent_q_fan(q_tot, sla)

      # Calculate fan cfm for fan power using Rated Home infiltration
      # http://www.resnet.us/standards/Interpretation_on_Reference_Home_mechVent_fanCFM_approved.pdf
      if not orig_details.elements["Enclosure/AirInfiltration/AirInfiltrationMeasurement/BuildingAirLeakage[UnitofMeasure='ACHnatural']/AirLeakage"].nil?
        nach = Float(XMLHelper.get_value(orig_details, "Enclosure/AirInfiltration/AirInfiltrationMeasurement/BuildingAirLeakage[UnitofMeasure='ACHnatural']/AirLeakage"))
        sla = Airflow.get_infiltration_SLA_from_ACH(nach, @ncfl_ag, @weather)
      elsif not orig_details.elements["Enclosure/AirInfiltration/AirInfiltrationMeasurement[HousePressure='50']/BuildingAirLeakage[UnitofMeasure='ACH']/AirLeakage"].nil?
        ach50 = Float(XMLHelper.get_value(orig_details, "Enclosure/AirInfiltration/AirInfiltrationMeasurement[HousePressure='50']/BuildingAirLeakage[UnitofMeasure='ACH']/AirLeakage"))
        sla = Airflow.get_infiltration_SLA_from_ACH50(ach50, 0.67, @cfa, @cvolume)
      end
      q_fan_power = calc_mech_vent_q_fan(q_tot, sla)

      fan_power_w = nil
      if fan_type == 'supply only' or fan_type == 'exhaust only' or fan_type == 'central fan integrated supply'
        w_cfm = 0.35
        fan_power_w = w_cfm * q_fan_power
      elsif fan_type == 'balanced'
        w_cfm = 0.70
        fan_power_w = w_cfm * q_fan_power
      elsif fan_type == 'energy recovery ventilator' or fan_type == 'heat recovery ventilator'
        w_cfm = 1.00
        fan_power_w = w_cfm * q_fan_power
        fan_type = 'balanced'
      end

      new_mech_vent = XMLHelper.add_element(new_systems, "MechanicalVentilation")
      new_vent_fans = XMLHelper.add_element(new_mech_vent, "VentilationFans")
      new_vent_fan = XMLHelper.add_element(new_vent_fans, "VentilationFan")
      sys_id = XMLHelper.add_element(new_vent_fan, "SystemIdentifier")
      XMLHelper.add_attribute(sys_id, "id", "VentilationFan")
      XMLHelper.add_element(new_vent_fan, "FanType", fan_type)
      XMLHelper.add_element(new_vent_fan, "RatedFlowRate", q_fan_airflow)
      XMLHelper.add_element(new_vent_fan, "HoursInOperation", 24) # TODO: CFIS
      XMLHelper.add_element(new_vent_fan, "UsedForWholeBuildingVentilation", true)
      XMLHelper.add_element(new_vent_fan, "FanPower", fan_power_w)

    end
  end

  def self.set_systems_mechanical_ventilation_rated(new_systems, orig_details)
    # Table 4.2.2(1) - Whole-House Mechanical ventilation
    orig_vent_fan = orig_details.elements["Systems/MechanicalVentilation/VentilationFans/VentilationFan[UsedForWholeBuildingVentilation='true']"]

    if not orig_vent_fan.nil?

      new_mech_vent = XMLHelper.add_element(new_systems, "MechanicalVentilation")
      new_vent_fans = XMLHelper.add_element(new_mech_vent, "VentilationFans")
      new_vent_fan = XMLHelper.add_element(new_vent_fans, "VentilationFan")
      sys_id = XMLHelper.add_element(new_vent_fan, "SystemIdentifier")
      XMLHelper.add_attribute(sys_id, "id", "VentilationFan")
      XMLHelper.copy_element(new_vent_fan, orig_vent_fan, "FanType")
      XMLHelper.copy_element(new_vent_fan, orig_vent_fan, "RatedFlowRate")
      XMLHelper.add_element(new_vent_fan, "HoursInOperation", 24) # FIXME: Is this right?
      XMLHelper.add_element(new_vent_fan, "UsedForWholeBuildingVentilation", true)
      XMLHelper.copy_element(new_vent_fan, orig_vent_fan, "TotalRecoveryEfficiency")
      XMLHelper.copy_element(new_vent_fan, orig_vent_fan, "SensibleRecoveryEfficiency")
      XMLHelper.copy_element(new_vent_fan, orig_vent_fan, "FanPower")

    end
  end

  def self.set_systems_mechanical_ventilation_iad(new_systems, orig_details, new_enclosure)
    # Table 4.3.1(1) Configuration of Index Adjustment Design - Whole-House Mechanical ventilation fan energy
    # Table 4.3.1(1) Configuration of Index Adjustment Design - Air exchange rate

    q_tot = Airflow.get_mech_vent_whole_house_cfm(1.0, @nbeds, @cfa, '2013')

    # Calculate fan cfm for airflow rate using IAD Home infiltration
    sla = Float(XMLHelper.get_value(new_enclosure, "AirInfiltration/extension/BuildingSpecificLeakageArea"))
    q_fan_airflow = calc_mech_vent_q_fan(q_tot, sla)

    # Calculate fan cfm for fan power using Rated Home infiltration
    # http://www.resnet.us/standards/Interpretation_on_Reference_Home_mechVent_fanCFM_approved.pdf
    if not orig_details.elements["Enclosure/AirInfiltration/AirInfiltrationMeasurement/BuildingAirLeakage[UnitofMeasure='ACHnatural']/AirLeakage"].nil?
      nach = Float(XMLHelper.get_value(orig_details, "Enclosure/AirInfiltration/AirInfiltrationMeasurement/BuildingAirLeakage[UnitofMeasure='ACHnatural']/AirLeakage"))
      sla = Airflow.get_infiltration_SLA_from_ACH(nach, @ncfl_ag, @weather)
    elsif not orig_details.elements["Enclosure/AirInfiltration/AirInfiltrationMeasurement[HousePressure='50']/BuildingAirLeakage[UnitofMeasure='ACH']/AirLeakage"].nil?
      ach50 = Float(XMLHelper.get_value(orig_details, "Enclosure/AirInfiltration/AirInfiltrationMeasurement[HousePressure='50']/BuildingAirLeakage[UnitofMeasure='ACH']/AirLeakage"))
      sla = Airflow.get_infiltration_SLA_from_ACH50(ach50, 0.67, @cfa, @cvolume)
    end
    q_fan_power = calc_mech_vent_q_fan(q_tot, sla)

    w_cfm = 0.70
    fan_power_w = w_cfm * q_fan_power

    new_mech_vent = XMLHelper.add_element(new_systems, "MechanicalVentilation")
    new_vent_fans = XMLHelper.add_element(new_mech_vent, "VentilationFans")
    new_vent_fan = XMLHelper.add_element(new_vent_fans, "VentilationFan")
    sys_id = XMLHelper.add_element(new_vent_fan, "SystemIdentifier")
    XMLHelper.add_attribute(sys_id, "id", "VentilationFan")
    XMLHelper.add_element(new_vent_fan, "FanType", 'balanced')
    XMLHelper.add_element(new_vent_fan, "RatedFlowRate", q_fan_airflow)
    XMLHelper.add_element(new_vent_fan, "HoursInOperation", 24)
    XMLHelper.add_element(new_vent_fan, "UsedForWholeBuildingVentilation", true)
    XMLHelper.add_element(new_vent_fan, "FanPower", fan_power_w)
  end

  def self.set_systems_water_heater_reference(new_systems, orig_details)
    new_water_heating = XMLHelper.add_element(new_systems, "WaterHeating")

    # Table 4.2.2(1) - Service water heating systems

    orig_wh_sys = orig_details.elements["Systems/WaterHeating/WaterHeatingSystem"]

    wh_type = nil
    wh_tank_vol = nil
    wh_fuel_type = nil
    if not orig_wh_sys.nil?
      wh_type = XMLHelper.get_value(orig_wh_sys, "WaterHeaterType")
      if orig_wh_sys.elements["TankVolume"]
        wh_tank_vol = Float(XMLHelper.get_value(orig_wh_sys, "TankVolume"))
      end
      wh_fuel_type = XMLHelper.get_value(orig_wh_sys, "FuelType")
      wh_location = XMLHelper.get_value(orig_wh_sys, "Location")
    end

    if orig_wh_sys.nil?
      wh_tank_vol = 40.0
      wh_fuel_type = XMLHelper.get_value(orig_details, "Systems/HVAC/HVACPlant/HeatingSystem/HeatingSystemFuel")
      if wh_fuel_type.nil? # Electric heat pump or no heating system
        wh_fuel_type = 'electricity'
      end
      wh_location = 'conditioned space' # 301 Standard doesn't specify the location
    elsif wh_type == 'instantaneous water heater'
      wh_tank_vol = 40.0
    end
    wh_type = 'storage water heater'

    wh_ef, wh_re = get_water_heater_ef_and_re(wh_fuel_type, wh_tank_vol)
    wh_cap = Waterheater.calc_water_heater_capacity(to_beopt_fuel(wh_fuel_type), @nbeds) * 1000.0 # Btuh

    # New water heater
    new_wh_sys = XMLHelper.add_element(new_water_heating, "WaterHeatingSystem")
    sys_id = XMLHelper.add_element(new_wh_sys, "SystemIdentifier")
    XMLHelper.add_attribute(sys_id, "id", "WaterHeatingSystem")
    XMLHelper.add_element(new_wh_sys, "FuelType", wh_fuel_type)
    XMLHelper.add_element(new_wh_sys, "WaterHeaterType", wh_type)
    XMLHelper.add_element(new_wh_sys, "Location", wh_location)
    XMLHelper.add_element(new_wh_sys, "TankVolume", wh_tank_vol)
    XMLHelper.add_element(new_wh_sys, "FractionDHWLoadServed", 1.0)
    XMLHelper.add_element(new_wh_sys, "HeatingCapacity", wh_cap)
    XMLHelper.add_element(new_wh_sys, "EnergyFactor", wh_ef)
    if not wh_re.nil?
      XMLHelper.add_element(new_wh_sys, "RecoveryEfficiency", wh_re)
    end
  end

  def self.set_systems_water_heater_rated(new_systems, orig_details)
    new_water_heating = XMLHelper.add_element(new_systems, "WaterHeating")

    # Table 4.2.2(1) - Service water heating systems

    orig_wh_sys = orig_details.elements["Systems/WaterHeating/WaterHeatingSystem"]

    if not orig_wh_sys.nil?

      # New water heater
      new_wh_sys = XMLHelper.add_element(new_water_heating, "WaterHeatingSystem")
      XMLHelper.copy_element(new_wh_sys, orig_wh_sys, "SystemIdentifier")
      XMLHelper.copy_element(new_wh_sys, orig_wh_sys, "FuelType")
      XMLHelper.copy_element(new_wh_sys, orig_wh_sys, "WaterHeaterType")
      XMLHelper.copy_element(new_wh_sys, orig_wh_sys, "Location")
      XMLHelper.copy_element(new_wh_sys, orig_wh_sys, "TankVolume")
      XMLHelper.copy_element(new_wh_sys, orig_wh_sys, "FractionDHWLoadServed")
      XMLHelper.copy_element(new_wh_sys, orig_wh_sys, "HeatingCapacity")
      if not orig_wh_sys.elements["EnergyFactor"].nil?
        XMLHelper.copy_element(new_wh_sys, orig_wh_sys, "EnergyFactor")
      elsif not orig_wh_sys.elements["UniformEnergyFactor"].nil?
        wh_uef = Float(XMLHelper.get_value(orig_wh_sys, "UniformEnergyFactor"))
        wh_type = XMLHelper.get_value(orig_wh_sys, "WaterHeaterType")
        wh_fuel_type = XMLHelper.get_value(orig_wh_sys, "FuelType")
        wh_ef = Waterheater.calc_ef_from_uef(wh_uef, to_beopt_wh_type(wh_type), to_beopt_fuel(wh_fuel_type))
        XMLHelper.add_element(new_wh_sys, "EnergyFactor", wh_ef)
      end
      XMLHelper.copy_element(new_wh_sys, orig_wh_sys, "RecoveryEfficiency")

    else

      wh_type = 'storage water heater'
      wh_tank_vol = 40.0
      wh_fuel_type = XMLHelper.get_value(orig_details, "Systems/HVAC/HVACPlant/HeatingSystem/HeatingSystemFuel")
      if wh_fuel_type.nil? # Electric heat pump or no heating system
        wh_fuel_type = 'electricity'
      end
      wh_ef, wh_re = get_water_heater_ef_and_re(wh_fuel_type, wh_tank_vol)
      wh_cap = Waterheater.calc_water_heater_capacity(to_beopt_fuel(wh_fuel_type), @nbeds) * 1000.0 # Btuh
      wh_location = 'conditioned space' # 301 Standard doesn't specify the location

      # New water heater
      new_wh_sys = XMLHelper.add_element(new_water_heating, "WaterHeatingSystem")
      sys_id = XMLHelper.add_element(new_wh_sys, "SystemIdentifier")
      XMLHelper.add_attribute(sys_id, "id", "WaterHeatingSystem")
      XMLHelper.add_element(new_wh_sys, "FuelType", wh_fuel_type)
      XMLHelper.add_element(new_wh_sys, "WaterHeaterType", wh_type)
      XMLHelper.add_element(new_wh_sys, "Location", wh_location)
      XMLHelper.add_element(new_wh_sys, "TankVolume", wh_tank_vol)
      XMLHelper.add_element(new_wh_sys, "FractionDHWLoadServed", 1.0)
      XMLHelper.add_element(new_wh_sys, "HeatingCapacity", wh_cap)
      XMLHelper.add_element(new_wh_sys, "EnergyFactor", wh_ef)
      if not wh_re.nil?
        XMLHelper.add_element(new_wh_sys, "RecoveryEfficiency", wh_re)
      end

    end
  end

  def self.set_systems_water_heater_iad(new_systems, orig_details)
    # Table 4.3.1(1) Configuration of Index Adjustment Design - Service water heating systems
    set_systems_water_heater_reference(new_systems, orig_details)
  end

  def self.set_systems_water_heating_use_reference(new_systems, orig_details)
    # Table 4.2.2(1) - Service water heating systems

    new_water_heating = new_systems.elements["WaterHeating"]
    orig_water_heating = orig_details.elements["Systems/WaterHeating"]

    has_uncond_bsmnt = (not orig_details.elements["Enclosure/Foundations/FoundationType/Basement[Conditioned='false']"].nil?)
    std_pipe_length = HotWaterAndAppliances.get_default_std_pipe_length(has_uncond_bsmnt, @cfa, @ncfl)

    # New hot water distribution
    new_hw_dist = XMLHelper.add_element(new_water_heating, "HotWaterDistribution")
    if orig_water_heating.nil?
      sys_id = XMLHelper.add_element(new_hw_dist, "SystemIdentifier")
      XMLHelper.add_attribute(sys_id, "id", "HotWaterDistribution")
    else
      XMLHelper.copy_element(new_hw_dist, orig_water_heating, "HotWaterDistribution/SystemIdentifier")
    end
    sys_type = XMLHelper.add_element(new_hw_dist, "SystemType")
    standard = XMLHelper.add_element(sys_type, "Standard")
    XMLHelper.add_element(standard, "PipingLength", std_pipe_length)
    pipe_ins = XMLHelper.add_element(new_hw_dist, "PipeInsulation")
    XMLHelper.add_element(pipe_ins, "PipeRValue", 0)

    # New water fixtures
    if orig_water_heating.nil?
      # Shower Head
      new_fixture = XMLHelper.add_element(new_water_heating, "WaterFixture")
      sys_id = XMLHelper.add_element(new_fixture, "SystemIdentifier")
      XMLHelper.add_attribute(sys_id, "id", "ShowerHead")
      XMLHelper.add_element(new_fixture, "WaterFixtureType", "shower head")
      XMLHelper.add_element(new_fixture, "LowFlow", false)

      # Faucet
      new_fixture = XMLHelper.add_element(new_water_heating, "WaterFixture")
      sys_id = XMLHelper.add_element(new_fixture, "SystemIdentifier")
      XMLHelper.add_attribute(sys_id, "id", "Faucet")
      XMLHelper.add_element(new_fixture, "WaterFixtureType", "faucet")
      XMLHelper.add_element(new_fixture, "LowFlow", false)
    else
      orig_water_heating.elements.each("WaterFixture[WaterFixtureType='shower head' or WaterFixtureType='faucet']") do |orig_fixture|
        new_fixture = XMLHelper.add_element(new_water_heating, "WaterFixture")
        XMLHelper.copy_element(new_fixture, orig_fixture, "SystemIdentifier")
        XMLHelper.copy_element(new_fixture, orig_fixture, "WaterFixtureType")
        XMLHelper.add_element(new_fixture, "LowFlow", false)
      end
    end
  end

  def self.set_systems_water_heating_use_rated(new_systems, orig_details)
    # Table 4.2.2(1) - Service water heating systems

    new_water_heating = new_systems.elements["WaterHeating"]
    orig_water_heating = orig_details.elements["Systems/WaterHeating"]
    if orig_water_heating.nil?
      set_systems_water_heating_use_reference(new_systems, orig_details)
      return
    end

    orig_hw_dist = orig_water_heating.elements["HotWaterDistribution"]

    has_uncond_bsmnt = (not orig_details.elements["Enclosure/Foundations/FoundationType/Basement[Conditioned='false']"].nil?)
    std_pipe_length = HotWaterAndAppliances.get_default_std_pipe_length(has_uncond_bsmnt, @cfa, @ncfl)

    # New hot water distribution
    new_hw_dist = XMLHelper.add_element(new_water_heating, "HotWaterDistribution")
    XMLHelper.copy_element(new_hw_dist, orig_hw_dist, "SystemIdentifier")
    orig_standard = orig_hw_dist.elements["SystemType/Standard"]
    orig_recirc = orig_hw_dist.elements["SystemType/Recirculation"]
    if not orig_standard.nil?
      new_sys_type = XMLHelper.add_element(new_hw_dist, "SystemType")
      new_standard = XMLHelper.add_element(new_sys_type, "Standard")
      if orig_standard.elements["PipingLength"].nil?
        XMLHelper.add_element(new_standard, "PipingLength", std_pipe_length)
      else
        XMLHelper.copy_element(new_standard, orig_standard, "PipingLength")
      end
    elsif not orig_recirc.nil?
      new_sys_type = XMLHelper.add_element(new_hw_dist, "SystemType")
      new_recirc = XMLHelper.add_element(new_sys_type, "Recirculation")
      XMLHelper.copy_element(new_recirc, orig_recirc, "ControlType")
      if orig_recirc.elements["RecirculationPipingLoopLength"].nil?
        recirc_loop_length = HotWaterAndAppliances.get_default_recirc_loop_length(std_pipe_length)
        XMLHelper.add_element(new_recirc, "RecirculationPipingLoopLength", recirc_loop_length)
      else
        XMLHelper.copy_element(new_recirc, orig_recirc, "RecirculationPipingLoopLength")
      end
      XMLHelper.copy_element(new_recirc, orig_recirc, "BranchPipingLoopLength")
      XMLHelper.copy_element(new_recirc, orig_recirc, "PumpPower")
    end
    pipe_ins = XMLHelper.add_element(new_hw_dist, "PipeInsulation")
    XMLHelper.copy_element(pipe_ins, orig_hw_dist, "PipeInsulation/PipeRValue")
    orig_dwhr = orig_hw_dist.elements["DrainWaterHeatRecovery"]
    if not orig_dwhr.nil?
      new_dwhr = XMLHelper.add_element(new_hw_dist, "DrainWaterHeatRecovery")
      XMLHelper.copy_element(new_dwhr, orig_dwhr, "FacilitiesConnected")
      XMLHelper.copy_element(new_dwhr, orig_dwhr, "EqualFlow")
      XMLHelper.copy_element(new_dwhr, orig_dwhr, "Efficiency")
    end

    # New water fixtures
    orig_water_heating.elements.each("WaterFixture[WaterFixtureType='shower head' or WaterFixtureType='faucet']") do |orig_fixture|
      new_fixture = XMLHelper.add_element(new_water_heating, "WaterFixture")
      XMLHelper.copy_element(new_fixture, orig_fixture, "SystemIdentifier")
      XMLHelper.copy_element(new_fixture, orig_fixture, "WaterFixtureType")
      XMLHelper.copy_element(new_fixture, orig_fixture, "LowFlow")
    end
  end

  def self.set_systems_water_heating_use_iad(new_systems, orig_details)
    # Table 4.3.1(1) Configuration of Index Adjustment Design - Service water heating systems
    set_systems_water_heating_use_reference(new_systems, orig_details)
  end

  def self.set_systems_photovoltaics_reference(new_systems)
    # nop
  end

  def self.set_systems_photovoltaics_rated(new_systems, orig_details)
    return if not XMLHelper.has_element(orig_details, "Systems/Photovoltaics")

    new_pvs = XMLHelper.add_element(new_systems, "Photovoltaics")

    orig_details.elements.each("Systems/Photovoltaics/PVSystem") do |orig_pv|
      new_pv = XMLHelper.add_element(new_pvs, "PVSystem")
      XMLHelper.copy_element(new_pv, orig_pv, "SystemIdentifier")
      XMLHelper.copy_element(new_pv, orig_pv, "ModuleType")
      XMLHelper.copy_element(new_pv, orig_pv, "ArrayType")
      XMLHelper.copy_element(new_pv, orig_pv, "ArrayAzimuth")
      XMLHelper.copy_element(new_pv, orig_pv, "ArrayTilt")
      XMLHelper.copy_element(new_pv, orig_pv, "MaxPowerOutput")
      XMLHelper.copy_element(new_pv, orig_pv, "InverterEfficiency")
      XMLHelper.copy_element(new_pv, orig_pv, "SystemLossesFraction")
    end
  end

  def self.set_systems_photovoltaics_iad(new_systems)
    # 4.3.1 Index Adjustment Design (IAD)
    # Renewable Energy Systems that offset the energy consumption requirements of the Rated Home shall not be included in the IAD.
    # nop
  end

  def self.set_appliances_clothes_washer_reference(new_appliances, orig_details)
    orig_appliances = orig_details.elements["Appliances"]
    orig_washer = orig_appliances.elements["ClothesWasher"]

    cw_mef = HotWaterAndAppliances.get_clothes_washer_reference_mef()
    cw_ler = HotWaterAndAppliances.get_clothes_washer_reference_ler()
    cw_elec_rate = HotWaterAndAppliances.get_clothes_washer_reference_elec_rate()
    cw_gas_rate = HotWaterAndAppliances.get_clothes_washer_reference_gas_rate()
    cw_agc = HotWaterAndAppliances.get_clothes_washer_reference_agc()
    cw_cap = HotWaterAndAppliances.get_clothes_washer_reference_cap()

    new_washer = XMLHelper.add_element(new_appliances, "ClothesWasher")
    XMLHelper.copy_element(new_washer, orig_washer, "SystemIdentifier")
    XMLHelper.add_element(new_washer, "ModifiedEnergyFactor", cw_mef)
    XMLHelper.add_element(new_washer, "RatedAnnualkWh", cw_ler)
    XMLHelper.add_element(new_washer, "LabelElectricRate", cw_elec_rate)
    XMLHelper.add_element(new_washer, "LabelGasRate", cw_gas_rate)
    XMLHelper.add_element(new_washer, "LabelAnnualGasCost", cw_agc)
    XMLHelper.add_element(new_washer, "Capacity", cw_cap)
  end

  def self.set_appliances_clothes_washer_rated(new_appliances, orig_details)
    orig_appliances = orig_details.elements["Appliances"]
    orig_washer = orig_appliances.elements["ClothesWasher"]

    if orig_washer.elements["ModifiedEnergyFactor"].nil? and orig_washer.elements["IntegratedModifiedEnergyFactor"].nil?
      self.set_appliances_clothes_washer_reference(new_appliances, orig_details)
      return
    end

    new_washer = XMLHelper.add_element(new_appliances, "ClothesWasher")
    XMLHelper.copy_element(new_washer, orig_washer, "SystemIdentifier")
    if not orig_washer.elements["ModifiedEnergyFactor"].nil?
      XMLHelper.copy_element(new_washer, orig_washer, "ModifiedEnergyFactor")
    else
      XMLHelper.copy_element(new_washer, orig_washer, "IntegratedModifiedEnergyFactor")
    end
    XMLHelper.copy_element(new_washer, orig_washer, "RatedAnnualkWh")
    XMLHelper.copy_element(new_washer, orig_washer, "LabelElectricRate")
    XMLHelper.copy_element(new_washer, orig_washer, "LabelGasRate")
    XMLHelper.copy_element(new_washer, orig_washer, "LabelAnnualGasCost")
    XMLHelper.copy_element(new_washer, orig_washer, "Capacity")
  end

  def self.set_appliances_clothes_washer_iad(new_appliances, orig_details)
    # Table 4.3.1(1) Configuration of Index Adjustment Design - Lighting, Appliances and Miscellaneous Electric Loads (MELs)
    self.set_appliances_clothes_washer_reference(new_appliances, orig_details)
  end

  def self.set_appliances_clothes_dryer_reference(new_appliances, orig_details)
    orig_appliances = orig_details.elements["Appliances"]
    orig_dryer = orig_appliances.elements["ClothesDryer"]

    cd_fuel = XMLHelper.get_value(orig_dryer, "FuelType")
    cd_ef = HotWaterAndAppliances.get_clothes_dryer_reference_ef(to_beopt_fuel(cd_fuel))
    cd_control = HotWaterAndAppliances.get_clothes_dryer_reference_control()

    new_dryer = XMLHelper.add_element(new_appliances, "ClothesDryer")
    XMLHelper.copy_element(new_dryer, orig_dryer, "SystemIdentifier")
    XMLHelper.copy_element(new_dryer, orig_dryer, "FuelType")
    XMLHelper.add_element(new_dryer, "EnergyFactor", cd_ef)
    XMLHelper.add_element(new_dryer, "ControlType", cd_control)
  end

  def self.set_appliances_clothes_dryer_rated(new_appliances, orig_details)
    orig_appliances = orig_details.elements["Appliances"]
    orig_dryer = orig_appliances.elements["ClothesDryer"]

    if orig_dryer.elements["EnergyFactor"].nil? and orig_dryer.elements["CombinedEnergyFactor"].nil?
      self.set_appliances_clothes_dryer_reference(new_appliances, orig_details)
      return
    end

    new_dryer = XMLHelper.add_element(new_appliances, "ClothesDryer")
    XMLHelper.copy_element(new_dryer, orig_dryer, "SystemIdentifier")
    XMLHelper.copy_element(new_dryer, orig_dryer, "FuelType")
    if not orig_dryer.elements["EnergyFactor"].nil?
      XMLHelper.copy_element(new_dryer, orig_dryer, "EnergyFactor")
    else
      XMLHelper.copy_element(new_dryer, orig_dryer, "CombinedEnergyFactor")
    end
    XMLHelper.copy_element(new_dryer, orig_dryer, "ControlType")
  end

  def self.set_appliances_clothes_dryer_iad(new_appliances, orig_details)
    # Table 4.3.1(1) Configuration of Index Adjustment Design - Lighting, Appliances and Miscellaneous Electric Loads (MELs)
    self.set_appliances_clothes_dryer_reference(new_appliances, orig_details)
  end

  def self.set_appliances_dishwasher_reference(new_appliances, orig_details)
    orig_appliances = orig_details.elements["Appliances"]
    orig_dishwasher = orig_appliances.elements["Dishwasher"]

    dw_ef = HotWaterAndAppliances.get_dishwasher_reference_ef()
    dw_cap = HotWaterAndAppliances.get_dishwasher_reference_cap()

    new_dishwasher = XMLHelper.add_element(new_appliances, "Dishwasher")
    XMLHelper.copy_element(new_dishwasher, orig_dishwasher, "SystemIdentifier")
    XMLHelper.add_element(new_dishwasher, "EnergyFactor", dw_ef)
    XMLHelper.add_element(new_dishwasher, "PlaceSettingCapacity", Integer(dw_cap))
  end

  def self.set_appliances_dishwasher_rated(new_appliances, orig_details)
    orig_appliances = orig_details.elements["Appliances"]
    orig_dishwasher = orig_appliances.elements["Dishwasher"]

    if orig_dishwasher.elements["EnergyFactor"].nil? and orig_dishwasher.elements["RatedAnnualkWh"].nil?
      self.set_appliances_dishwasher_reference(new_appliances, orig_details)
      return
    end

    new_dishwasher = XMLHelper.add_element(new_appliances, "Dishwasher")
    XMLHelper.copy_element(new_dishwasher, orig_dishwasher, "SystemIdentifier")
    if not orig_dishwasher.elements["EnergyFactor"].nil?
      XMLHelper.copy_element(new_dishwasher, orig_dishwasher, "EnergyFactor")
    else
      XMLHelper.copy_element(new_dishwasher, orig_dishwasher, "RatedAnnualkWh")
    end
    XMLHelper.copy_element(new_dishwasher, orig_dishwasher, "PlaceSettingCapacity")
  end

  def self.set_appliances_dishwasher_iad(new_appliances, orig_details)
    # Table 4.3.1(1) Configuration of Index Adjustment Design - Lighting, Appliances and Miscellaneous Electric Loads (MELs)
    self.set_appliances_dishwasher_reference(new_appliances, orig_details)
  end

  def self.set_appliances_refrigerator_reference(new_appliances, orig_details)
    orig_appliances = orig_details.elements["Appliances"]
    orig_fridge = orig_appliances.elements["Refrigerator"]

    # Table 4.2.2.5(1) Lighting, Appliance and Miscellaneous Electric Loads in electric ERI Reference Homes
    refrigerator_kwh = HotWaterAndAppliances.get_refrigerator_reference_annual_kwh(@nbeds)

    new_fridge = XMLHelper.add_element(new_appliances, "Refrigerator")
    XMLHelper.copy_element(new_fridge, orig_fridge, "SystemIdentifier")
    XMLHelper.add_element(new_fridge, "RatedAnnualkWh", refrigerator_kwh)
  end

  def self.set_appliances_refrigerator_rated(new_appliances, orig_details)
    orig_appliances = orig_details.elements["Appliances"]
    orig_fridge = orig_appliances.elements["Refrigerator"]

    if orig_fridge.elements["RatedAnnualkWh"].nil?
      self.set_appliances_refrigerator_reference(new_appliances, orig_details)
      return
    end

    new_fridge = XMLHelper.add_element(new_appliances, "Refrigerator")
    XMLHelper.copy_element(new_fridge, orig_fridge, "SystemIdentifier")
    XMLHelper.copy_element(new_fridge, orig_fridge, "RatedAnnualkWh")
  end

  def self.set_appliances_refrigerator_iad(new_appliances, orig_details)
    # Table 4.3.1(1) Configuration of Index Adjustment Design - Lighting, Appliances and Miscellaneous Electric Loads (MELs)
    self.set_appliances_refrigerator_reference(new_appliances, orig_details)
  end

  def self.set_appliances_cooking_range_oven_reference(new_appliances, orig_details)
    orig_appliances = orig_details.elements["Appliances"]
    orig_range = orig_appliances.elements["CookingRange"]
    orig_oven = orig_appliances.elements["Oven"]

    is_induction = HotWaterAndAppliances.get_range_oven_reference_is_induction()
    is_convection = HotWaterAndAppliances.get_range_oven_reference_is_convection()

    new_range = XMLHelper.add_element(new_appliances, "CookingRange")
    XMLHelper.copy_element(new_range, orig_range, "SystemIdentifier")
    XMLHelper.copy_element(new_range, orig_range, "FuelType")
    XMLHelper.add_element(new_range, "IsInduction", is_induction)

    new_oven = XMLHelper.add_element(new_appliances, "Oven")
    XMLHelper.copy_element(new_oven, orig_oven, "SystemIdentifier")
    XMLHelper.add_element(new_oven, "IsConvection", is_convection)
  end

  def self.set_appliances_cooking_range_oven_rated(new_appliances, orig_details)
    orig_appliances = orig_details.elements["Appliances"]
    orig_range = orig_appliances.elements["CookingRange"]
    orig_oven = orig_appliances.elements["Oven"]

    if orig_range.elements["IsInduction"].nil?
      self.set_appliances_cooking_range_oven_reference(new_appliances, orig_details)
      return
    end

    new_range = XMLHelper.add_element(new_appliances, "CookingRange")
    XMLHelper.copy_element(new_range, orig_range, "SystemIdentifier")
    XMLHelper.copy_element(new_range, orig_range, "FuelType")
    XMLHelper.copy_element(new_range, orig_range, "IsInduction")

    new_oven = XMLHelper.add_element(new_appliances, "Oven")
    XMLHelper.copy_element(new_oven, orig_oven, "SystemIdentifier")
    XMLHelper.copy_element(new_oven, orig_oven, "IsConvection")
  end

  def self.set_appliances_cooking_range_oven_iad(new_appliances, orig_details)
    # Table 4.3.1(1) Configuration of Index Adjustment Design - Lighting, Appliances and Miscellaneous Electric Loads (MELs)
    self.set_appliances_cooking_range_oven_reference(new_appliances, orig_details)
  end

  def self.set_lighting_reference(new_lighting, orig_details)
    fFI_int, fFI_ext, fFI_grg, fFII_int, fFII_ext, fFII_grg = Lighting.get_reference_fractions()

    new_fractions = XMLHelper.add_element(new_lighting, "LightingFractions")
    extension = XMLHelper.add_element(new_fractions, "extension")
    XMLHelper.add_element(extension, "FractionQualifyingTierIFixturesInterior", fFI_int)
    XMLHelper.add_element(extension, "FractionQualifyingTierIFixturesExterior", fFI_ext)
    XMLHelper.add_element(extension, "FractionQualifyingTierIFixturesGarage", fFI_grg)
    XMLHelper.add_element(extension, "FractionQualifyingTierIIFixturesInterior", fFII_int)
    XMLHelper.add_element(extension, "FractionQualifyingTierIIFixturesExterior", fFII_ext)
    XMLHelper.add_element(extension, "FractionQualifyingTierIIFixturesGarage", fFII_grg)
  end

  def self.set_lighting_rated(new_lighting, orig_details)
    orig_lighting = orig_details.elements["Lighting"]
    orig_fractions = orig_lighting.elements["LightingFractions"]

    if orig_fractions.nil?
      self.set_lighting_reference(new_lighting, orig_details)
      return
    end

    new_fractions = XMLHelper.add_element(new_lighting, "LightingFractions")
    extension = XMLHelper.add_element(new_fractions, "extension")
    XMLHelper.copy_element(extension, orig_fractions, "extension/FractionQualifyingTierIFixturesInterior")
    XMLHelper.copy_element(extension, orig_fractions, "extension/FractionQualifyingTierIFixturesExterior")
    XMLHelper.copy_element(extension, orig_fractions, "extension/FractionQualifyingTierIFixturesGarage")
    XMLHelper.copy_element(extension, orig_fractions, "extension/FractionQualifyingTierIIFixturesInterior")
    XMLHelper.copy_element(extension, orig_fractions, "extension/FractionQualifyingTierIIFixturesExterior")
    XMLHelper.copy_element(extension, orig_fractions, "extension/FractionQualifyingTierIIFixturesGarage")

    # For rating purposes, the Rated Home shall not have qFFIL less than 0.10 (10%).
    fFI_int = Float(XMLHelper.get_value(extension, "FractionQualifyingTierIFixturesInterior"))
    fFII_int = Float(XMLHelper.get_value(extension, "FractionQualifyingTierIIFixturesInterior"))
    if fFI_int + fFII_int < 0.1
      extension.elements["FractionQualifyingTierIFixturesInterior"].text = 0.1 - fFII_int
    end
  end

  def self.set_lighting_iad(new_lighting, orig_details)
    fFI_int, fFI_ext, fFI_grg, fFII_int, fFII_ext, fFII_grg = Lighting.get_iad_fractions()

    new_fractions = XMLHelper.add_element(new_lighting, "LightingFractions")
    extension = XMLHelper.add_element(new_fractions, "extension")
    XMLHelper.add_element(extension, "FractionQualifyingTierIFixturesInterior", fFI_int)
    XMLHelper.add_element(extension, "FractionQualifyingTierIFixturesExterior", fFI_ext)
    XMLHelper.add_element(extension, "FractionQualifyingTierIFixturesGarage", fFI_grg)
    XMLHelper.add_element(extension, "FractionQualifyingTierIIFixturesInterior", fFII_int)
    XMLHelper.add_element(extension, "FractionQualifyingTierIIFixturesExterior", fFII_ext)
    XMLHelper.add_element(extension, "FractionQualifyingTierIIFixturesGarage", fFII_grg)
  end

  def self.set_ceiling_fans_reference(new_lighting, orig_details)
    return if not XMLHelper.has_element(orig_details, "Lighting/CeilingFan")

    medium_cfm = 3000.0
    fan_power_w = HVAC.get_default_ceiling_fan_power()
    quantity = HVAC.get_default_ceiling_fan_quantity(@nbeds)

    new_cf = XMLHelper.add_element(new_lighting, "CeilingFan")
    sys_id = XMLHelper.add_element(new_cf, "SystemIdentifier")
    XMLHelper.add_attribute(sys_id, "id", "CeilingFans")
    new_airflow = XMLHelper.add_element(new_cf, "Airflow")
    XMLHelper.add_element(new_airflow, "FanSpeed", "medium")
    XMLHelper.add_element(new_airflow, "Efficiency", medium_cfm / fan_power_w)
    XMLHelper.add_element(new_cf, "Quantity", Integer(quantity))
  end

  def self.set_ceiling_fans_rated(new_lighting, orig_details)
    return if not XMLHelper.has_element(orig_details, "Lighting/CeilingFan")

    medium_cfm = 3000.0
    quantity = HVAC.get_default_ceiling_fan_quantity(@nbeds)

    # Calculate average ceiling fan wattage
    sum_w = 0.0
    num_cfs = 0
    orig_details.elements.each("Lighting/CeilingFan") do |cf|
      cf_quantity = Integer(XMLHelper.get_value(cf, "Quantity"))
      num_cfs += cf_quantity
      cfm_per_w = XMLHelper.get_value(cf, "Airflow[FanSpeed='medium']/Efficiency")
      if cfm_per_w.nil?
        fan_power_w = HVAC.get_default_ceiling_fan_power()
        cfm_per_w = medium_cfm / fan_power_w
      else
        cfm_per_w = Float(cfm_per_w)
      end
      sum_w += (medium_cfm / cfm_per_w * Float(cf_quantity))
    end
    avg_w = sum_w / num_cfs

    new_cf = XMLHelper.add_element(new_lighting, "CeilingFan")
    sys_id = XMLHelper.add_element(new_cf, "SystemIdentifier")
    XMLHelper.add_attribute(sys_id, "id", "CeilingFans")
    new_airflow = XMLHelper.add_element(new_cf, "Airflow")
    XMLHelper.add_element(new_airflow, "FanSpeed", "medium")
    XMLHelper.add_element(new_airflow, "Efficiency", medium_cfm / avg_w)
    XMLHelper.add_element(new_cf, "Quantity", Integer(quantity))
  end

  def self.set_ceiling_fans_iad(new_lighting, orig_details)
    # Not described in Addendum E; use Reference Home?
    set_ceiling_fans_reference(new_lighting, orig_details)
  end

  private

  def self.get_water_heater_ef_and_re(wh_fuel_type, wh_tank_vol)
    # # Table 4.2.2(1) - Service water heating systems
    ef = nil
    re = nil
    if wh_fuel_type == 'electricity'
      ef = 0.97 - (0.00132 * wh_tank_vol)
    else
      ef = 0.67 - (0.0019 * wh_tank_vol)
      if wh_fuel_type == 'natural gas' or wh_fuel_type == 'propane'
        re = 0.76
      elsif wh_fuel_type == 'fuel oil'
        re = 0.78
      end
    end
    return ef, re
  end

  def self.has_fuel_access(orig_details)
    orig_details.elements.each("BuildingSummary/Site/FuelTypesAvailable/Fuel") do |fuel|
      fuels = ["natural gas", "fuel oil", "propane", "kerosene", "diesel",
               "anthracite coal", "bituminous coal", "coke",
               "wood", "wood pellets"]
      if fuels.include?(fuel.text)
        return true
      end
    end
    return false
  end

  def self.calc_mech_vent_q_fan(q_tot, sla)
    nl = 1000.0 * sla * @ncfl_ag**0.4 # Normalized leakage, eq. 4.4
    q_inf = nl * @weather.data.WSF * @cfa / 7.3 # Effective annual average infiltration rate, cfm, eq. 4.5a
    if q_inf > 2.0 / 3.0 * q_tot
      return q_tot - 2.0 / 3.0 * q_tot
    end

    return q_tot - q_inf
  end
end

def get_exterior_wall_area_fracs(orig_details)
  # Get individual exterior wall areas and sum
  wall_areas = {}
  wall_area_sum = 0.0
  orig_details.elements.each("Enclosure/Walls/Wall") do |wall|
    next if XMLHelper.get_value(wall, "extension/ExteriorAdjacentTo") != "ambient"
    next if XMLHelper.get_value(wall, "extension/InteriorAdjacentTo") != "living space"

    wall_area = Float(XMLHelper.get_value(wall, "Area"))
    wall_areas[wall] = wall_area
    wall_area_sum += wall_area
  end

  # Convert to fractions
  wall_area_fracs = {}
  wall_areas.each do |wall, wall_area|
    wall_area_fracs[wall] = wall_areas[wall] / wall_area_sum
  end

  return wall_area_fracs
end
