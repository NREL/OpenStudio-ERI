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
require_relative "../../HPXMLtoOpenStudio/resources/hpxml"

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
    @garage_present = Boolean(XMLHelper.get_value(building, "BuildingDetails/BuildingSummary/BuildingConstruction/GaragePresent"))
    @iecc_zone_2006 = XMLHelper.get_value(building, "BuildingDetails/ClimateandRiskZones/ClimateZoneIECC[Year='2006']/ClimateZone")
    @iecc_zone_2012 = XMLHelper.get_value(building, "BuildingDetails/ClimateandRiskZones/ClimateZoneIECC[Year='2012']/ClimateZone")
    @calc_type = calc_type

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
    new_climate = XMLHelper.add_element(new_details, "ClimateandRiskZones")
    set_climate(new_climate, orig_details)

    # Enclosure
    new_enclosure = XMLHelper.add_element(new_details, "Enclosure")
    set_enclosure_air_infiltration_reference(new_enclosure)
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

    # MiscLoads
    new_misc_loads = XMLHelper.add_element(new_details, "MiscLoads")
    set_misc_loads_reference(new_misc_loads)
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
    new_climate = XMLHelper.add_element(new_details, "ClimateandRiskZones")
    set_climate(new_climate, orig_details)

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

    # MiscLoads
    new_misc_loads = XMLHelper.add_element(new_details, "MiscLoads")
    set_misc_loads_rated(new_misc_loads)
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
    new_climate = XMLHelper.add_element(new_details, "ClimateandRiskZones")
    set_climate(new_climate, orig_details)

    # Enclosure
    new_enclosure = XMLHelper.add_element(new_details, "Enclosure")
    set_enclosure_air_infiltration_iad(new_enclosure)
    set_enclosure_attics_roofs_iad(new_enclosure, orig_details)
    set_enclosure_foundations_iad(new_enclosure)
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

    # MiscLoads
    new_misc_loads = XMLHelper.add_element(new_details, "MiscLoads")
    set_misc_loads_iad(new_misc_loads)
  end

  def self.set_summary_reference(new_summary, orig_details)
    orig_fuel_types_available = orig_details.elements["BuildingSummary/Site/FuelTypesAvailable"]
    fuels = XMLHelper.get_values(orig_fuel_types_available, "Fuel")
    HPXML.add_site(building_summary: new_summary,
                   fuels: fuels,
                   shelter_coefficient: Airflow.get_default_shelter_coefficient())

    HPXML.add_building_occupancy(building_summary: new_summary,
                                 number_of_residents: Geometry.get_occupancy_default_num(@nbeds))

    HPXML.add_building_construction(building_summary: new_summary,
                                    number_of_conditioned_floors: Integer(@ncfl),
                                    number_of_conditioned_floors_above_grade: Integer(@ncfl_ag),
                                    number_of_bedrooms: Integer(@nbeds),
                                    conditioned_floor_area: @cfa,
                                    conditioned_building_volume: @cvolume,
                                    garage_present: @garage_present)
  end

  def self.set_summary_rated(new_summary, orig_details)
    orig_fuel_types_available = orig_details.elements["BuildingSummary/Site/FuelTypesAvailable"]
    fuels = XMLHelper.get_values(orig_fuel_types_available, "Fuel")
    HPXML.add_site(building_summary: new_summary,
                   fuels: fuels,
                   shelter_coefficient: Airflow.get_default_shelter_coefficient())

    HPXML.add_building_occupancy(building_summary: new_summary,
                                 number_of_residents: Geometry.get_occupancy_default_num(@nbeds))

    HPXML.add_building_construction(building_summary: new_summary,
                                    number_of_conditioned_floors: Integer(@ncfl),
                                    number_of_conditioned_floors_above_grade: Integer(@ncfl_ag),
                                    number_of_bedrooms: Integer(@nbeds),
                                    conditioned_floor_area: @cfa,
                                    conditioned_building_volume: @cvolume,
                                    garage_present: @garage_present)
  end

  def self.set_summary_iad(new_summary, orig_details)
    # Table 4.3.1(1) Configuration of Index Adjustment Design - General Characteristics
    @cfa = 2400
    @nbeds = 3
    @ncfl = 2
    @ncfl_ag = 2
    @cvolume = 20400
    @garage_present = false

    orig_fuel_types_available = orig_details.elements["BuildingSummary/Site/FuelTypesAvailable"]
    fuels = XMLHelper.get_values(orig_fuel_types_available, "Fuel")
    HPXML.add_site(building_summary: new_summary,
                   fuels: fuels,
                   shelter_coefficient: Airflow.get_default_shelter_coefficient())

    HPXML.add_building_occupancy(building_summary: new_summary,
                                 number_of_residents: Geometry.get_occupancy_default_num(@nbeds))

    HPXML.add_building_construction(building_summary: new_summary,
                                    number_of_conditioned_floors: Integer(@ncfl),
                                    number_of_conditioned_floors_above_grade: Integer(@ncfl_ag),
                                    number_of_bedrooms: Integer(@nbeds),
                                    conditioned_floor_area: @cfa,
                                    conditioned_building_volume: @cvolume,
                                    garage_present: @garage_present)
  end

  def self.set_climate(new_climate, orig_details)
    orig_details.elements.each("ClimateandRiskZones/ClimateZoneIECC") do |orig_climate_zone|
      HPXML.add_climate_zone_iecc(climate_and_risk_zones: new_climate,
                                  year: XMLHelper.get_value(orig_climate_zone, "Year"),
                                  climate_zone: XMLHelper.get_value(orig_climate_zone, "ClimateZone"))
    end
    orig_weather_station = orig_details.elements["ClimateandRiskZones/WeatherStation"]
    HPXML.add_weather_station(climate_and_risk_zones: new_climate,
                              id: orig_weather_station.elements["SystemIdentifiersInfo"].attributes["id"],
                              name: XMLHelper.get_value(orig_weather_station, "Name"),
                              wmo: XMLHelper.get_value(orig_weather_station, "WMO"))
  end

  def self.set_enclosure_air_infiltration_reference(new_enclosure)
    new_infil = XMLHelper.add_element(new_enclosure, "AirInfiltration")

    # Table 4.2.2(1) - Air exchange rate
    sla = 0.00036

    # Convert to other forms
    nach = Airflow.get_infiltration_ACH_from_SLA(sla, @ncfl_ag, @weather)
    ach50 = Airflow.get_infiltration_ACH50_from_SLA(sla, 0.67, @cfa, @cvolume)

    # nACH
    HPXML.add_air_infiltration_measurement(air_infiltration: new_infil,
                                           id: "Infiltration_ACHnatural",
                                           unit_of_measure: "ACHnatural",
                                           air_leakage: nach)

    # ACH50
    HPXML.add_air_infiltration_measurement(air_infiltration: new_infil,
                                           id: "Infiltration_ACH50",
                                           house_pressure: 50,
                                           unit_of_measure: "ACH",
                                           air_leakage: ach50)

    # ELA/SLA
    ela = sla * @cfa
    HPXML.add_air_infiltration_measurement(air_infiltration: new_infil,
                                           id: "Infiltration_ELA_SLA",
                                           effective_leakage_area: ela)

    HPXML.add_extension(parent: new_infil,
                        extensions: {"BuildingSpecificLeakageArea": sla})
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
    HPXML.add_air_infiltration_measurement(air_infiltration: new_infil,
                                           id: "Infiltration_ACHnatural",
                                           unit_of_measure: "ACHnatural",
                                           air_leakage: nach)

    # ACH50
    HPXML.add_air_infiltration_measurement(air_infiltration: new_infil,
                                           id: "Infiltration_ACH50",
                                           house_pressure: 50,
                                           unit_of_measure: "ACH",
                                           air_leakage: ach50)

    # ELA/SLA
    HPXML.add_air_infiltration_measurement(air_infiltration: new_infil,
                                           id: "Infiltration_ELA_SLA",
                                           effective_leakage_area: ela)

    HPXML.add_extension(parent: new_infil,
                        extensions: {"BuildingSpecificLeakageArea": sla})
  end

  def self.set_enclosure_air_infiltration_iad(new_enclosure)
    new_infil = XMLHelper.add_element(new_enclosure, "AirInfiltration")

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
    HPXML.add_air_infiltration_measurement(air_infiltration: new_infil,
                                           id: "Infiltration_ACHnatural",
                                           unit_of_measure: "ACHnatural",
                                           air_leakage: nach)

    # ACH50
    HPXML.add_air_infiltration_measurement(air_infiltration: new_infil,
                                           id: "Infiltration_ACH50",
                                           house_pressure: 50,
                                           unit_of_measure: "ACH",
                                           air_leakage: ach50)

    # ELA/SLA
    ela = sla * @cfa
    HPXML.add_air_infiltration_measurement(air_infiltration: new_infil,
                                           id: "Infiltration_ELA_SLA",
                                           effective_leakage_area: ela)

    HPXML.add_extension(parent: new_infil,
                        extensions: {"BuildingSpecificLeakageArea": sla})
  end

  def self.set_enclosure_attics_roofs_reference(new_enclosure, orig_details)
    new_attics = XMLHelper.add_element(new_enclosure, "Attics")

    ceiling_ufactor = FloorConstructions.get_default_ceiling_ufactor(@iecc_zone_2006)
    wall_ufactor = WallConstructions.get_default_frame_wall_ufactor(@iecc_zone_2006)

    orig_details.elements.each("Enclosure/Attics/Attic") do |orig_attic|
      attic_type = XMLHelper.get_value(orig_attic, "AtticType")
      if ['unvented attic', 'vented attic'].include? attic_type
        attic_type = 'vented attic'
      end
      interior_adjacent_to = get_attic_adjacent_to(attic_type)

      new_attic = HPXML.add_attic(attics: new_attics,
                                  id: XMLHelper.get_id(orig_attic),
                                  attic_type: attic_type)

      # Table 4.2.2(1) - Roofs
      new_roofs = XMLHelper.add_element(new_attic, "Roofs")
      orig_attic.elements.each("Roofs/Roof") do |orig_roof|
        new_roof = HPXML.add_roof(roofs: new_roofs,
                                  id: XMLHelper.get_id(orig_roof),
                                  area: XMLHelper.get_value(orig_roof, "Area"),
                                  solar_absorptance: 0.75,
                                  emittance: 0.90,
                                  pitch: XMLHelper.get_value(orig_roof, "Pitch"),
                                  radiant_barrier: XMLHelper.get_value(orig_roof, "RadiantBarrier"))
        orig_roof_ins = orig_roof.elements["Insulation"]
        assembly_effective_r_value = XMLHelper.get_value(orig_roof_ins, "AssemblyEffectiveRValue")
        if is_external_thermal_boundary(interior_adjacent_to, "outside")
          assembly_effective_r_value = 1.0 / ceiling_ufactor
        end
        HPXML.add_insulation(parent: new_roof,
                             id: XMLHelper.get_id(orig_roof_ins),
                             assembly_effective_r_value: assembly_effective_r_value)
      end

      # Table 4.2.2(1) - Ceilings
      new_floors = XMLHelper.add_element(new_attic, "Floors")
      orig_attic.elements.each("Floors/Floor") do |orig_floor|
        exterior_adjacent_to = XMLHelper.get_value(orig_floor, "AdjacentTo")
        new_floor = HPXML.add_floor(floors: new_floors,
                                    id: XMLHelper.get_id(orig_floor),
                                    adjacent_to: exterior_adjacent_to,
                                    area: XMLHelper.get_value(orig_floor, "Area"))
        orig_floor_ins = orig_floor.elements["Insulation"]
        assembly_effective_r_value = XMLHelper.get_value(orig_floor_ins, "AssemblyEffectiveRValue")
        if is_external_thermal_boundary(interior_adjacent_to, exterior_adjacent_to)
          assembly_effective_r_value = 1.0 / ceiling_ufactor
        end
        HPXML.add_insulation(parent: new_floor,
                             id: XMLHelper.get_id(orig_floor_ins),
                             assembly_effective_r_value: assembly_effective_r_value)
      end

      # Table 4.2.2(1) - Above-grade walls
      new_walls = XMLHelper.add_element(new_attic, "Walls")
      orig_attic.elements.each("Walls/Wall") do |orig_wall|
        exterior_adjacent_to = XMLHelper.get_value(orig_wall, "AdjacentTo")
        new_wall = HPXML.add_wall(walls: new_walls,
                                  id: XMLHelper.get_id(orig_wall), 
                                  adjacent_to: exterior_adjacent_to,
                                  wall_type: XMLHelper.get_child_name(orig_wall, "WallType"),
                                  area: XMLHelper.get_value(orig_wall, "Area"),
                                  solar_absorptance: XMLHelper.get_value(orig_wall, "SolarAbsorptance"),
                                  emittance: XMLHelper.get_value(orig_wall, "Emittance"))
        orig_wall_ins = orig_wall.elements["Insulation"]
        assembly_effective_r_value = XMLHelper.get_value(orig_wall_ins, "AssemblyEffectiveRValue")
        if is_external_thermal_boundary(interior_adjacent_to, exterior_adjacent_to)
          assembly_effective_r_value = 1.0 / wall_ufactor
        end
        HPXML.add_insulation(parent: new_wall,
                             id: XMLHelper.get_id(orig_wall_ins),
                             assembly_effective_r_value: assembly_effective_r_value)
      end

      # Table 4.2.2(1) - Attics
      if attic_type == 'vented attic'
        HPXML.add_extension(parent: new_attic,
                            extensions: {"AtticSpecificLeakageArea": Airflow.get_default_vented_attic_sla()})
      end

    end
  end

  def self.set_enclosure_attics_roofs_rated(new_enclosure, orig_details)
    new_attics = XMLHelper.add_element(new_enclosure, "Attics")

    orig_details.elements.each("Enclosure/Attics/Attic") do |orig_attic|
      
      new_attic = HPXML.add_attic(attics: new_attics,
                                  id: XMLHelper.get_id(orig_attic),
                                  attic_type: XMLHelper.get_value(orig_attic, "AtticType"))
      
      new_roofs = XMLHelper.add_element(new_attic, "Roofs")
      orig_attic.elements.each("Roofs/Roof") do |orig_roof|
        new_roof = HPXML.add_roof(roofs: new_roofs,
                                  id: XMLHelper.get_id(orig_roof),
                                  area: XMLHelper.get_value(orig_roof, "Area"),
                                  azimuth: XMLHelper.get_value(orig_roof, "Azimuth"),
                                  solar_absorptance: XMLHelper.get_value(orig_roof, "SolarAbsorptance"),
                                  emittance: XMLHelper.get_value(orig_roof, "Emittance"),
                                  pitch: XMLHelper.get_value(orig_roof, "Pitch"),
                                  radiant_barrier: XMLHelper.get_value(orig_roof, "RadiantBarrier"))
        orig_roof_ins = orig_roof.elements["Insulation"]
        HPXML.add_insulation(parent: new_roof,
                             id: XMLHelper.get_id(orig_roof_ins),
                             assembly_effective_r_value: XMLHelper.get_value(orig_roof_ins, "AssemblyEffectiveRValue"))
      end

      new_floors = XMLHelper.add_element(new_attic, "Floors")
      orig_attic.elements.each("Floors/Floor") do |orig_floor|
        new_floor = HPXML.add_floor(floors: new_floors,
                                    id: XMLHelper.get_id(orig_floor),
                                    adjacent_to: XMLHelper.get_value(orig_floor, "AdjacentTo"),
                                    area: XMLHelper.get_value(orig_floor, "Area"))
        orig_floor_ins = orig_floor.elements["Insulation"]
        HPXML.add_insulation(parent: new_floor,
                             id: XMLHelper.get_id(orig_floor_ins),
                             assembly_effective_r_value: XMLHelper.get_value(orig_floor_ins, "AssemblyEffectiveRValue"))
      end

      new_walls = XMLHelper.add_element(new_attic, "Walls")
      orig_attic.elements.each("Walls/Wall") do |orig_wall|
        new_wall = HPXML.add_wall(walls: new_walls,
                                  id: XMLHelper.get_id(orig_wall),
                                  exterior_adjacent_to: XMLHelper.get_value(orig_wall, "ExteriorAdjacentTo"),
                                  interior_adjacent_to: XMLHelper.get_value(orig_wall, "InteriorAdjacentTo"),
                                  adjacent_to: XMLHelper.get_value(orig_wall, "AdjacentTo"),
                                  wall_type: XMLHelper.get_child_name(orig_wall, "WallType"),
                                  area: XMLHelper.get_value(orig_wall, "Area"),
                                  azimuth: XMLHelper.get_value(orig_wall, "Azimuth"),
                                  solar_absorptance: XMLHelper.get_value(orig_wall, "SolarAbsorptance"),
                                  emittance: XMLHelper.get_value(orig_wall, "Emittance"))
        orig_wall_ins = orig_wall.elements["Insulation"]
        HPXML.add_insulation(parent: new_wall,
                             id: XMLHelper.get_id(orig_wall_ins),
                             assembly_effective_r_value: XMLHelper.get_value(orig_wall_ins, "AssemblyEffectiveRValue"))
      end

    end
  end

  def self.set_enclosure_attics_roofs_iad(new_enclosure, orig_details)
    set_enclosure_attics_roofs_rated(new_enclosure, orig_details)

    new_enclosure.elements.each("Attics/Attic") do |new_attic|
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
    new_foundations = XMLHelper.add_element(new_enclosure, "Foundations")

    floor_ufactor = FloorConstructions.get_default_floor_ufactor(@iecc_zone_2006)
    wall_ufactor = FoundationConstructions.get_default_basement_wall_ufactor(@iecc_zone_2006)
    slab_perim_rvalue, slab_perim_depth = FoundationConstructions.get_default_slab_perimeter_rvalue_depth(@iecc_zone_2006)
    slab_under_rvalue, slab_under_width = FoundationConstructions.get_default_slab_under_rvalue_width()

    orig_details.elements.each("Enclosure/Foundations/Foundation") do |orig_foundation|
      foundation_type = nil
      if XMLHelper.has_element(orig_foundation, "FoundationType/SlabOnGrade")
        foundation_type = "SlabOnGrade"
      elsif XMLHelper.has_element(orig_foundation, "FoundationType/Basement[Conditioned='false']")
        foundation_type = "UnconditionedBasement"
      elsif XMLHelper.has_element(orig_foundation, "FoundationType/Basement[Conditioned='true']")
        foundation_type = "ConditionedBasement"
      elsif XMLHelper.has_element(orig_foundation, "FoundationType/Crawlspace[Vented='false']")
        foundation_type = "UnventedCrawlspace"
      elsif XMLHelper.has_element(orig_foundation, "FoundationType/Crawlspace[Vented='true']")
        foundation_type = "VentedCrawlspace"
      end
      if foundation_type == "UnventedCrawlspace"
        foundation_type = "VentedCrawlspace"
      end
      interior_adjacent_to = get_foundation_adjacent_to(orig_foundation.elements["FoundationType"])

      new_foundation = HPXML.add_foundation(foundations: new_foundations,
                                            id: XMLHelper.get_id(orig_foundation),
                                            foundation_type: foundation_type)

      # Table 4.2.2(1) - Floors over unconditioned spaces or outdoor environment
      orig_foundation.elements.each("FrameFloor") do |orig_floor|
        exterior_adjacent_to = XMLHelper.get_value(orig_floor, "AdjacentTo")
        new_floor = HPXML.add_frame_floor(foundation: new_foundation,
                                    id: XMLHelper.get_id(orig_floor),
                                    adjacent_to: exterior_adjacent_to,
                                    area: XMLHelper.get_value(orig_floor, "Area"))
        orig_floor_ins = orig_floor.elements["Insulation"]
        assembly_effective_r_value = XMLHelper.get_value(orig_floor_ins, "AssemblyEffectiveRValue")
        if is_external_thermal_boundary(interior_adjacent_to, exterior_adjacent_to)
          assembly_effective_r_value = 1.0 / floor_ufactor
        end
        HPXML.add_insulation(parent: new_floor,
                             id: XMLHelper.get_id(orig_floor_ins),
                             assembly_effective_r_value: assembly_effective_r_value)
      end

      # Table 4.2.2(1) - Conditioned basement walls
      orig_foundation.elements.each("FoundationWall") do |orig_wall|
        exterior_adjacent_to = XMLHelper.get_value(orig_wall, "AdjacentTo")
        new_wall = HPXML.add_foundation_wall(foundation: new_foundation,
                                             id: XMLHelper.get_id(orig_wall),
                                             height: XMLHelper.get_value(orig_wall, "Height"),
                                             area: XMLHelper.get_value(orig_wall, "Area"),
                                             thickness: XMLHelper.get_value(orig_wall, "Thickness"),
                                             depth_below_grade: XMLHelper.get_value(orig_wall, "DepthBelowGrade"),
                                             adjacent_to: exterior_adjacent_to)
        orig_wall_ins = orig_wall.elements["Insulation"]
        assembly_effective_r_value = XMLHelper.get_value(orig_wall_ins, "AssemblyEffectiveRValue")
        # TODO: Can this just be is_external_thermal_boundary(interior_adjacent_to, exterior_adjacent_to)?
        if interior_adjacent_to == "basement - conditioned" and is_external_thermal_boundary(interior_adjacent_to, exterior_adjacent_to)
          assembly_effective_r_value = 1.0 / wall_ufactor
        end
        HPXML.add_insulation(parent: new_wall,
                             id: XMLHelper.get_id(orig_wall_ins),
                             assembly_effective_r_value: assembly_effective_r_value)
      end

      # Table 4.2.2(1) - Foundations
      orig_foundation.elements.each("Slab") do |orig_slab|
        orig_perim_ins = orig_slab.elements["PerimeterInsulation"]
        orig_under_ins = orig_slab.elements["UnderSlabInsulation"]
        # TODO: Can this just be is_external_thermal_boundary(interior_adjacent_to, "ground")?
        if not ( interior_adjacent_to == "living space" and is_external_thermal_boundary(interior_adjacent_to, "ground") )
          slab_perim_depth = XMLHelper.get_value(orig_slab, "PerimeterInsulationDepth")
          slab_under_width = XMLHelper.get_value(orig_slab, "UnderSlabInsulationWidth")
          perim_ins_layer = orig_perim_ins.elements["Layer"]
          slab_perim_rvalue = XMLHelper.get_value(perim_ins_layer, "NominalRValue")
          under_ins_layer = orig_under_ins.elements["Layer"]
          slab_under_rvalue = XMLHelper.get_value(under_ins_layer, "NominalRValue")
        end
        new_slab = HPXML.add_slab(foundation: new_foundation,
                                  id: XMLHelper.get_id(orig_slab),
                                  area: XMLHelper.get_value(orig_slab, "Area"),
                                  thickness: XMLHelper.get_value(orig_slab, "Thickness"),
                                  exposed_perimeter: XMLHelper.get_value(orig_slab, "ExposedPerimeter"),
                                  perimeter_insulation_depth: slab_perim_depth,
                                  under_slab_insulation_width: slab_under_width,
                                  depth_below_grade: XMLHelper.get_value(orig_slab, "DepthBelowGrade"))
        perim_ins = HPXML.add_perimeter_insulation(slab: new_slab,
                                                   id: XMLHelper.get_id(orig_perim_ins))
        HPXML.add_layer(insulation: perim_ins,
                        installation_type: "continuous",
                        nominal_r_value: slab_perim_rvalue)
        under_ins = HPXML.add_under_slab_insulation(slab: new_slab,
                                                    id: XMLHelper.get_id(orig_under_ins))
        HPXML.add_layer(insulation: under_ins,
                        installation_type: "continuous",
                        nominal_r_value: slab_under_rvalue)
        HPXML.add_extension(parent: new_slab,
                            extensions: {"CarpetFraction": 0.8,
                                         "CarpetRValue": 2.0})
      end

      # Table 4.2.2(1) - Crawlspaces
      if foundation_type == "VentedCrawlspace"
        HPXML.add_extension(parent: new_foundation,
                            extensions: {"CrawlspaceSpecificLeakageArea": Airflow.get_default_vented_crawl_sla()})
      end
    end
  end

  def self.set_enclosure_foundations_rated(new_enclosure, orig_details)
    new_foundations = XMLHelper.add_element(new_enclosure, "Foundations")

    min_crawl_vent = Airflow.get_default_vented_crawl_sla() # Reference Home vent

    orig_details.elements.each("Enclosure/Foundations/Foundation") do |orig_foundation|
      foundation_type = nil
      if XMLHelper.has_element(orig_foundation, "FoundationType/SlabOnGrade")
        foundation_type = "SlabOnGrade"
      elsif XMLHelper.has_element(orig_foundation, "FoundationType/Basement[Conditioned='false']")
        foundation_type = "UnconditionedBasement"
      elsif XMLHelper.has_element(orig_foundation, "FoundationType/Basement[Conditioned='true']")
        foundation_type = "ConditionedBasement"
      elsif XMLHelper.has_element(orig_foundation, "FoundationType/Crawlspace[Vented='false']")
        foundation_type = "UnventedCrawlspace"
      elsif XMLHelper.has_element(orig_foundation, "FoundationType/Crawlspace[Vented='true']")
        foundation_type = "VentedCrawlspace"
        # Table 4.2.2(1) - Crawlspaces
        vent = Float(XMLHelper.get_value(orig_foundation, "extension/CrawlspaceSpecificLeakageArea"))
        # TODO: Handle approved ground cover
        if vent < min_crawl_vent
          vent = min_crawl_vent
        end
      end

      new_foundation = HPXML.add_foundation(foundations: new_foundations,
                                            id: XMLHelper.get_id(orig_foundation),
                                            foundation_type: foundation_type)

      orig_foundation.elements.each("FrameFloor") do |orig_floor|
        new_floor = HPXML.add_frame_floor(foundation: new_foundation,
                                    id: XMLHelper.get_id(orig_floor),
                                    adjacent_to: XMLHelper.get_value(orig_floor, "AdjacentTo"),
                                    area: XMLHelper.get_value(orig_floor, "Area"))
        orig_floor_ins = orig_floor.elements["Insulation"]
        HPXML.add_insulation(parent: new_floor,
                              id: XMLHelper.get_id(orig_floor_ins),
                              assembly_effective_r_value: XMLHelper.get_value(orig_floor_ins, "AssemblyEffectiveRValue"))
      end

      orig_foundation.elements.each("FoundationWall") do |orig_wall|
        new_wall = HPXML.add_foundation_wall(foundation: new_foundation,
                                             id: XMLHelper.get_id(orig_wall),
                                             height: XMLHelper.get_value(orig_wall, "Height"),
                                             area: XMLHelper.get_value(orig_wall, "Area"),
                                             thickness: XMLHelper.get_value(orig_wall, "Thickness"),
                                             depth_below_grade: XMLHelper.get_value(orig_wall, "DepthBelowGrade"),
                                             adjacent_to: XMLHelper.get_value(orig_wall, "AdjacentTo"))
        orig_wall_ins = orig_wall.elements["Insulation"]
        HPXML.add_insulation(parent: new_wall,
                             id: XMLHelper.get_id(orig_wall_ins),
                             assembly_effective_r_value: XMLHelper.get_value(orig_wall_ins, "AssemblyEffectiveRValue"))
      end

      orig_foundation.elements.each("Slab") do |orig_slab|
        orig_perim_ins = orig_slab.elements["PerimeterInsulation"]
        orig_under_ins = orig_slab.elements["UnderSlabInsulation"]
        perim_ins_layer = orig_perim_ins.elements["Layer"]
        under_ins_layer = orig_under_ins.elements["Layer"]
        new_slab = HPXML.add_slab(foundation: new_foundation,
                                  id: XMLHelper.get_id(orig_slab),
                                  area: XMLHelper.get_value(orig_slab, "Area"),
                                  thickness: XMLHelper.get_value(orig_slab, "Thickness"),
                                  exposed_perimeter: XMLHelper.get_value(orig_slab, "ExposedPerimeter"),
                                  perimeter_insulation_depth: XMLHelper.get_value(orig_slab, "PerimeterInsulationDepth"),
                                  under_slab_insulation_width: XMLHelper.get_value(orig_slab, "UnderSlabInsulationWidth"),
                                  depth_below_grade: XMLHelper.get_value(orig_slab, "DepthBelowGrade"))
        perim_ins = HPXML.add_perimeter_insulation(slab: new_slab,
                                                   id: XMLHelper.get_id(orig_perim_ins))
        HPXML.add_layer(insulation: perim_ins,
                        installation_type: "continuous",
                        nominal_r_value: XMLHelper.get_value(perim_ins_layer, "NominalRValue"))
        under_ins = HPXML.add_under_slab_insulation(slab: new_slab,
                                                    id: XMLHelper.get_id(orig_under_ins))
        HPXML.add_layer(insulation: under_ins,
                        installation_type: "continuous",
                        nominal_r_value: XMLHelper.get_value(under_ins_layer, "NominalRValue"))
        HPXML.add_extension(parent: new_slab,
                            extensions: {"CarpetFraction": XMLHelper.get_value(orig_slab, "extension/CarpetFraction"),
                                         "CarpetRValue": XMLHelper.get_value(orig_slab, "extension/CarpetRValue")})

      end
      HPXML.add_extension(parent: new_foundation,
                          extensions: {"CrawlspaceSpecificLeakageArea": vent})
    end
  end

  def self.set_enclosure_foundations_iad(new_enclosure)
    # Table 4.3.1(1) Configuration of Index Adjustment Design - Foundation
    floor_ufactor = FloorConstructions.get_default_floor_ufactor(@iecc_zone_2006)

    new_foundations = XMLHelper.add_element(new_enclosure, "Foundations")
    new_foundation = HPXML.add_foundation(foundations: new_foundations,
                                          id: "Foundation_Crawlspace",
                                          foundation_type: "VentedCrawlspace")

    # Ceiling
    new_floor = HPXML.add_frame_floor(foundation: new_foundation,
                                      id: "Foundation_Floor",
                                      adjacent_to: "living space",
                                      area: 1200)
    HPXML.add_insulation(parent: new_floor,
                         id: "Foundation_Floor_Ins",
                         assembly_effective_r_value: 1.0 / floor_ufactor)

    # Wall
    new_wall = HPXML.add_foundation_wall(foundation: new_foundation,
                                         id: "Foundation_Wall",
                                         height: 2,
                                         area: 2 * 34.64 * 4,
                                         thickness: 8,
                                         depth_below_grade: 0,
                                         adjacent_to: "ground")
    HPXML.add_insulation(parent: new_wall,
                         id: "Foundation_Wall_Ins",
                         assembly_effective_r_value: 1.0 / floor_ufactor) # FIXME

    # Floor
    new_slab = HPXML.add_slab(foundation: new_foundation,
                              id: "Foundation_Slab",
                              area: 1200,
                              thickness: 0,
                              exposed_perimeter: 4 * 34.64,
                              perimeter_insulation_depth: 0,
                              under_slab_insulation_width: 0,
                              depth_below_grade: 0)
    new_perim_ins = HPXML.add_perimeter_insulation(slab: new_slab,
                                                   id: "Foundation_Slab_Perim_Ins")
    HPXML.add_layer(insulation: new_perim_ins,
                    installation_type: "continuous",
                    nominal_r_value: 0)

    new_under_ins = HPXML.add_under_slab_insulation(slab: new_slab,
                                                    id: "Foundation_Slab_Under_Ins")
    HPXML.add_layer(insulation: new_under_ins,
                    installation_type: "continuous",
                    nominal_r_value: 0)

    HPXML.add_extension(parent: new_slab,
                        extensions: {"CarpetFraction": 0,
                                     "CarpetRValue": 0})
    HPXML.add_extension(parent: new_foundation,
                        extensions: {"CrawlspaceSpecificLeakageArea": Airflow.get_default_vented_crawl_sla()})
  end

  def self.set_enclosure_rim_joists_reference(new_enclosure, orig_details)
    return if not XMLHelper.has_element(orig_details, "Enclosure/RimJoists")

    new_rim_joists = XMLHelper.add_element(new_enclosure, "RimJoists")

    # Table 4.2.2(1) - Above-grade walls
    ufactor = WallConstructions.get_default_frame_wall_ufactor(@iecc_zone_2006)

    orig_details.elements.each("Enclosure/RimJoists/RimJoist") do |orig_rim_joist|
      interior_adjacent_to = XMLHelper.get_value(orig_rim_joist, "InteriorAdjacentTo")
      exterior_adjacent_to = XMLHelper.get_value(orig_rim_joist, "ExteriorAdjacentTo")
      new_rim_joist = HPXML.add_rim_joist(rim_joists: new_rim_joists,
                                          id: XMLHelper.get_id(orig_rim_joist),
                                          exterior_adjacent_to: exterior_adjacent_to,
                                          interior_adjacent_to: interior_adjacent_to,
                                          area: XMLHelper.get_value(orig_rim_joist, "Area"))
      orig_rim_joist_ins = orig_rim_joist.elements["Insulation"]
      assembly_effective_r_value = XMLHelper.get_value(orig_rim_joist_ins, "AssemblyEffectiveRValue")
      if is_external_thermal_boundary(interior_adjacent_to, exterior_adjacent_to)
        assembly_effective_r_value = 1.0 / ufactor
      end
      HPXML.add_insulation(parent: new_rim_joist,
                           id: XMLHelper.get_id(orig_rim_joist_ins),
                           assembly_effective_r_value: assembly_effective_r_value)
    end
  end

  def self.set_enclosure_rim_joists_rated(new_enclosure, orig_details)
    return if not XMLHelper.has_element(orig_details, "Enclosure/RimJoists")

    new_rim_joists = XMLHelper.add_element(new_enclosure, "RimJoists")

    orig_details.elements.each("Enclosure/RimJoists/RimJoist") do |orig_rim_joist|
      interior_adjacent_to = XMLHelper.get_value(orig_rim_joist, "InteriorAdjacentTo")
      exterior_adjacent_to = XMLHelper.get_value(orig_rim_joist, "ExteriorAdjacentTo")
      new_rim_joist = HPXML.add_rim_joist(rim_joists: new_rim_joists,
                                          id: XMLHelper.get_id(orig_rim_joist),
                                          exterior_adjacent_to: exterior_adjacent_to,
                                          interior_adjacent_to: interior_adjacent_to,
                                          area: XMLHelper.get_value(orig_rim_joist, "Area"))
      orig_rim_joist_ins = orig_rim_joist.elements["Insulation"]
      HPXML.add_insulation(parent: new_rim_joist,
                           id: XMLHelper.get_id(orig_rim_joist_ins),
                           assembly_effective_r_value: XMLHelper.get_value(orig_rim_joist_ins, "AssemblyEffectiveRValue"))
    end

    # Table 4.2.2(1) - Above-grade walls
    # nop
  end

  def self.get_iad_sum_external_wall_area(orig_walls, orig_rim_joists)
    sum_wall_area = 0.0

    orig_walls.elements.each("Wall") do |orig_wall|
      interior_adjacent_to = XMLHelper.get_value(orig_wall, "InteriorAdjacentTo")
      exterior_adjacent_to = XMLHelper.get_value(orig_wall, "ExteriorAdjacentTo")
      if is_external_thermal_boundary(interior_adjacent_to, exterior_adjacent_to)
        sum_wall_area += Float(XMLHelper.get_value(orig_wall, "Area"))
      end
    end

    if not orig_rim_joists.nil?
      orig_rim_joists.elements.each("RimJoist") do |orig_rim_joist|
        interior_adjacent_to = XMLHelper.get_value(orig_rim_joist, "InteriorAdjacentTo")
        if ["basement - unconditioned", "basement - conditioned"].include? interior_adjacent_to
          # IAD home has crawlspace
          interior_adjacent_to = "crawlspace - vented"
        end
        exterior_adjacent_to = XMLHelper.get_value(orig_rim_joist, "ExteriorAdjacentTo")
        if is_external_thermal_boundary(interior_adjacent_to, exterior_adjacent_to)
          sum_wall_area += Float(XMLHelper.get_value(orig_rim_joist, "Area"))
        end
      end
    end

    return sum_wall_area
  end

  def self.set_enclosure_rim_joists_iad(new_enclosure, orig_details)
    # Table 4.3.1(1) Configuration of Index Adjustment Design - Above-grade walls
    set_enclosure_rim_joists_rated(new_enclosure, orig_details)

    orig_rim_joists = orig_details.elements["Enclosure/RimJoists"]
    return if orig_rim_joists.nil?

    orig_walls = orig_details.elements["Enclosure/Walls"]

    sum_wall_area = get_iad_sum_external_wall_area(orig_walls, orig_rim_joists)

    new_rim_joists = new_enclosure.elements["RimJoists"]

    new_rim_joists.elements.each("RimJoist") do |new_rim_joist|
      interior_adjacent_to = XMLHelper.get_value(new_rim_joist, "InteriorAdjacentTo")
      if ["basement - unconditioned", "basement - conditioned"].include? interior_adjacent_to
        # IAD home has crawlspace
        interior_adjacent_to = "crawlspace - vented"
        new_rim_joist.elements["InteriorAdjacentTo"].text = interior_adjacent_to
      end
      exterior_adjacent_to = XMLHelper.get_value(new_rim_joist, "ExteriorAdjacentTo")
      if is_external_thermal_boundary(interior_adjacent_to, exterior_adjacent_to)
        rim_joist_area = Float(XMLHelper.get_value(new_rim_joist, "Area"))
        new_rim_joist.elements["Area"].text = 2360.0 * rim_joist_area / sum_wall_area
      end
    end
  end

  def self.set_enclosure_walls_reference(new_enclosure, orig_details)
    new_walls = XMLHelper.add_element(new_enclosure, "Walls")

    # Table 4.2.2(1) - Above-grade walls
    ufactor = WallConstructions.get_default_frame_wall_ufactor(@iecc_zone_2006)

    orig_details.elements.each("Enclosure/Walls/Wall") do |orig_wall|
      exterior_adjacent_to = XMLHelper.get_value(orig_wall, "ExteriorAdjacentTo")
      interior_adjacent_to = XMLHelper.get_value(orig_wall, "InteriorAdjacentTo")      
      solar_absorptance = XMLHelper.get_value(orig_wall, "SolarAbsorptance")
      emittance = XMLHelper.get_value(orig_wall, "Emittance")
      orig_wall_ins = orig_wall.elements["Insulation"]
      assembly_effective_r_value = XMLHelper.get_value(orig_wall_ins, "AssemblyEffectiveRValue")
      if is_external_thermal_boundary(interior_adjacent_to, exterior_adjacent_to)
        solar_absorptance = 0.75
        emittance = 0.90
        assembly_effective_r_value = 1.0 / ufactor
      end
      new_wall = HPXML.add_wall(walls: new_walls,
                                id: XMLHelper.get_id(orig_wall),
                                exterior_adjacent_to: exterior_adjacent_to,
                                interior_adjacent_to: interior_adjacent_to,
                                wall_type: XMLHelper.get_child_name(orig_wall, "WallType"),
                                area: XMLHelper.get_value(orig_wall, "Area"),
                                azimuth: XMLHelper.get_value(orig_wall, "Azimuth"),
                                solar_absorptance: solar_absorptance,
                                emittance: emittance)
      HPXML.add_insulation(parent: new_wall,
                           id: XMLHelper.get_id(orig_wall_ins),
                           assembly_effective_r_value: assembly_effective_r_value)
    end
  end

  def self.set_enclosure_walls_rated(new_enclosure, orig_details)
    new_walls = XMLHelper.add_element(new_enclosure, "Walls")

    orig_details.elements.each("Enclosure/Walls/Wall") do |orig_wall|
      new_wall = HPXML.add_wall(walls: new_walls,
                                id: XMLHelper.get_id(orig_wall),
                                exterior_adjacent_to: XMLHelper.get_value(orig_wall, "ExteriorAdjacentTo"),
                                interior_adjacent_to: XMLHelper.get_value(orig_wall, "InteriorAdjacentTo"),
                                wall_type: XMLHelper.get_child_name(orig_wall, "WallType"),
                                area: XMLHelper.get_value(orig_wall, "Area"),
                                azimuth: XMLHelper.get_value(orig_wall, "Azimuth"),
                                solar_absorptance: XMLHelper.get_value(orig_wall, "SolarAbsorptance"),
                                emittance: XMLHelper.get_value(orig_wall, "Emittance"))
      orig_wall_ins = orig_wall.elements["Insulation"]
      assembly_effective_r_value = XMLHelper.get_value(orig_wall_ins, "AssemblyEffectiveRValue")
      HPXML.add_insulation(parent: new_wall,
                           id: XMLHelper.get_id(orig_wall_ins),
                           assembly_effective_r_value: assembly_effective_r_value)
    end

    # Table 4.2.2(1) - Above-grade walls
    # nop
  end

  def self.set_enclosure_walls_iad(new_enclosure, orig_details)
    # Table 4.3.1(1) Configuration of Index Adjustment Design - Above-grade walls
    set_enclosure_walls_rated(new_enclosure, orig_details)

    orig_walls = orig_details.elements["Enclosure/Walls"]
    orig_rim_joists = orig_details.elements["Enclosure/RimJoists"]

    sum_wall_area = get_iad_sum_external_wall_area(orig_walls, orig_rim_joists)

    new_walls = new_enclosure.elements["Walls"]

    new_walls.elements.each("Wall") do |new_wall|
      interior_adjacent_to = XMLHelper.get_value(new_wall, "InteriorAdjacentTo")
      exterior_adjacent_to = XMLHelper.get_value(new_wall, "ExteriorAdjacentTo")
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
      int_adj_to = XMLHelper.get_value(wall, "InteriorAdjacentTo")
      ext_adj_to = XMLHelper.get_value(wall, "ExteriorAdjacentTo")
      next if not ((int_adj_to == "living space" or ext_adj_to == "living space") and int_adj_to != ext_adj_to)

      area = Float(XMLHelper.get_value(wall, "Area"))
      ag_wall_area += area
    end

    orig_details.elements.each("Enclosure/Foundations/Foundation[FoundationType/Basement/Conditioned='true']/FoundationWall") do |fwall|
      adj_to = XMLHelper.get_value(fwall, "AdjacentTo")
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
        wall_id = XMLHelper.get_id(wall)
        new_window = HPXML.add_window(windows: new_windows,
                                      id: "Window_#{wall_id}_#{orientation}",
                                      area: window_area * wall_area_frac,
                                      azimuth: azimuth,
                                      ufactor: ufactor,
                                      shgc: shgc,
                                      idref: wall_id)

        set_window_interior_shading_reference(new_window)
      end
    end
  end

  def self.set_window_interior_shading_reference(window)
    shade_summer, shade_winter = SubsurfaceConstructions.get_default_interior_shading_factors()

    # Table 4.2.2(1) - Glazing
    HPXML.add_extension(parent: window,
                        extensions: {"InteriorShadingFactorSummer": shade_summer,
                                     "InteriorShadingFactorWinter": shade_winter})
  end

  def self.set_enclosure_windows_rated(new_enclosure, orig_details)
    new_windows = XMLHelper.add_element(new_enclosure, "Windows")

    # Table 4.2.2(1) - Glazing
    orig_details.elements.each("Enclosure/Windows/Window") do |orig_window|
      new_window = HPXML.add_window(windows: new_windows,
                                    id: XMLHelper.get_id(orig_window),
                                    area: XMLHelper.get_value(orig_window, "Area"),
                                    azimuth: XMLHelper.get_value(orig_window, "Azimuth"),
                                    ufactor: XMLHelper.get_value(orig_window, "UFactor"),
                                    shgc: XMLHelper.get_value(orig_window, "SHGC"),
                                    overhangs_depth: XMLHelper.get_value(orig_window, "Overhangs/Depth"),
                                    overhangs_distance_to_top_of_window: XMLHelper.get_value(orig_window, "Overhangs/DistanceToTopOfWindow"),
                                    overhangs_distance_to_bottom_of_window: XMLHelper.get_value(orig_window, "Overhangs/DistanceToBottomOfWindow"),
                                    idref: XMLHelper.get_idref(orig_window, "AttachedToWall"))

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
    return if not XMLHelper.has_element(orig_details, "Enclosure/Skylights")

    new_skylights = XMLHelper.add_element(new_enclosure, "Skylights")

    # Table 4.2.2(1) - Skylights
    orig_details.elements.each("Enclosure/Skylights/Skylight") do |orig_skylight|
      new_skylight = HPXML.add_skylight(skylights: new_skylights,
                                        id: XMLHelper.get_id(orig_skylight),
                                        area: XMLHelper.get_value(orig_skylight, "Area"),
                                        azimuth: XMLHelper.get_value(orig_skylight, "Azimuth"),
                                        ufactor: XMLHelper.get_value(orig_skylight, "UFactor"),
                                        shgc: XMLHelper.get_value(orig_skylight, "SHGC"),
                                        idref: XMLHelper.get_idref(orig_skylight, "AttachedToRoof"))
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
      wall_id = XMLHelper.get_id(wall)

      new_door = HPXML.add_door(doors: new_doors,
                                id: "Door_#{wall_id}",
                                idref: wall_id,
                                area: door_area * wall_area_frac,
                                azimuth: 0,
                                r_value: 1.0 / ufactor)
    end
  end

  def self.set_enclosure_doors_rated(new_enclosure, orig_details)
    new_doors = XMLHelper.add_element(new_enclosure, "Doors")

    # Table 4.2.2(1) - Doors
    orig_details.elements.each("Enclosure/Doors/Door") do |orig_door|
      new_door = HPXML.add_door(doors: new_doors,
                                id: XMLHelper.get_id(orig_door),
                                idref: XMLHelper.get_idref(orig_door, "AttachedToWall"),
                                area: XMLHelper.get_value(orig_door, "Area"),
                                azimuth: XMLHelper.get_value(orig_door, "Azimuth"),
                                r_value: XMLHelper.get_value(orig_door, "RValue"))
    end
  end

  def self.set_enclosure_doors_iad(new_enclosure, orig_details)
    # Table 4.3.1(1) Configuration of Index Adjustment Design - Doors
    set_enclosure_doors_rated(new_enclosure, orig_details)
  end

  def self.set_systems_hvac_reference(new_systems, orig_details)
    new_hvac = XMLHelper.add_element(new_systems, "HVAC")
    new_hvac_plant = XMLHelper.add_element(new_hvac, "HVACPlant")

    # Table 4.2.2(1) - Heating systems
    # Table 4.2.2(1) - Cooling systems

    has_fuel = has_fuel_access(orig_details)

    # Heating
    orig_details.elements.each("Systems/HVAC/HVACPlant/HeatingSystem") do |orig_heating|
      fuel_type = XMLHelper.get_value(orig_heating, "HeatingSystemFuel")
      next unless fuel_type != "electricity"

      load_frac = Float(XMLHelper.get_value(orig_heating, "FractionHeatLoadServed"))
      sys_id = XMLHelper.get_id(orig_heating)
      if XMLHelper.has_element(orig_heating, "HeatingSystemType/Boiler")
        add_reference_heating_gas_boiler(new_hvac_plant, load_frac, sys_id)
      else
        add_reference_heating_gas_furnace(new_hvac_plant, load_frac, sys_id)
      end
    end
    if orig_details.elements["Systems/HVAC/HVACPlant/HeatingSystem"].nil? and orig_details.elements["Systems/HVAC/HVACPlant/HeatPump[FractionHeatLoadServed > 0]"].nil?
      if has_fuel
        add_reference_heating_gas_furnace(new_hvac_plant)
      end
    end

    # Cooling
    orig_details.elements.each("Systems/HVAC/HVACPlant/CoolingSystem") do |orig_cooling|
      load_frac = Float(XMLHelper.get_value(orig_cooling, "FractionCoolLoadServed"))
      sys_id = XMLHelper.get_id(orig_cooling)
      add_reference_cooling_air_conditioner(new_hvac_plant, load_frac, sys_id)
    end
    orig_details.elements.each("Systems/HVAC/HVACPlant/HeatPump[FractionCoolLoadServed > 0]") do |orig_hp|
      load_frac = Float(XMLHelper.get_value(orig_hp, "FractionCoolLoadServed"))
      sys_id = XMLHelper.get_id(orig_hp)
      add_reference_cooling_air_conditioner(new_hvac_plant, load_frac, sys_id)
    end
    if orig_details.elements["Systems/HVAC/HVACPlant/CoolingSystem"].nil? and orig_details.elements["Systems/HVAC/HVACPlant/HeatPump[FractionCoolLoadServed > 0]"].nil?
      add_reference_cooling_air_conditioner(new_hvac_plant)
    end

    # HeatPump
    orig_details.elements.each("Systems/HVAC/HVACPlant/HeatingSystem") do |orig_heating|
      fuel_type = XMLHelper.get_value(orig_heating, "HeatingSystemFuel")
      next unless fuel_type == "electricity"

      load_frac = Float(XMLHelper.get_value(orig_heating, "FractionHeatLoadServed"))
      sys_id = XMLHelper.get_id(orig_heating)
      add_reference_heating_heat_pump(new_hvac_plant, load_frac, sys_id)
    end
    orig_details.elements.each("Systems/HVAC/HVACPlant/HeatPump[FractionHeatLoadServed > 0]") do |orig_hp|
      load_frac = Float(XMLHelper.get_value(orig_hp, "FractionHeatLoadServed"))
      sys_id = XMLHelper.get_id(orig_hp)
      add_reference_heating_heat_pump(new_hvac_plant, load_frac, sys_id)
    end
    if orig_details.elements["Systems/HVAC/HVACPlant/HeatingSystem"].nil? and orig_details.elements["Systems/HVAC/HVACPlant/HeatPump[FractionHeatLoadServed > 0]"].nil?
      if not has_fuel
        add_reference_heating_heat_pump(new_hvac_plant)
      end
    end

    # Table 303.4.1(1) - Thermostat
    new_hvac_control = HPXML.add_hvac_control(hvac: new_hvac,
                                              id: "HVACControl",
                                              control_type: "manual thermostat")

    # Distribution system
    add_reference_distribution_system(new_hvac)
  end

  def self.set_systems_hvac_rated(new_systems, orig_details)
    new_hvac = XMLHelper.add_element(new_systems, "HVAC")

    # Table 4.2.2(1) - Heating systems
    # Table 4.2.2(1) - Cooling systems

    heating_system = orig_details.elements["Systems/HVAC/HVACPlant/HeatingSystem"]
    heat_pump = orig_details.elements["Systems/HVAC/HVACPlant/HeatPump"]
    cooling_system = orig_details.elements["Systems/HVAC/HVACPlant/CoolingSystem"]

    new_hvac_plant = XMLHelper.add_element(new_hvac, "HVACPlant")

    # Heating
    added_reference_heating = false
    if not heating_system.nil?
      # Retain heating system(s)
      orig_details.elements.each("Systems/HVAC/HVACPlant/HeatingSystem") do |orig_heating|
        if XMLHelper.has_element(orig_heating, "DistributionSystem")
          distribution_system_id = XMLHelper.get_idref(orig_heating, "DistributionSystem")
        end
        heat_sys = HPXML.add_heating_system(hvac_plant: new_hvac_plant,
                                            id: XMLHelper.get_id(orig_heating),
                                            idref: distribution_system_id,
                                            heating_system_type: XMLHelper.get_child_name(orig_heating, "HeatingSystemType"),
                                            heating_system_fuel: XMLHelper.get_value(orig_heating, "HeatingSystemFuel"),
                                            heating_capacity: XMLHelper.get_value(orig_heating, "HeatingCapacity"),
                                            annual_heating_efficiency_units: XMLHelper.get_value(orig_heating, "AnnualHeatingEfficiency/Units"),
                                            annual_heating_efficiency_value: XMLHelper.get_value(orig_heating, "AnnualHeatingEfficiency/Value"),
                                            fraction_heat_load_served: XMLHelper.get_value(orig_heating, "FractionHeatLoadServed")) 
      end
    end
    if heating_system.nil? and heat_pump.nil? and has_fuel_access(orig_details)
      add_reference_heating_gas_furnace(new_hvac_plant)
      added_reference_heating = true
    end

    # Cooling
    added_reference_cooling = false
    if not cooling_system.nil?
      # Retain cooling system(s)
      orig_details.elements.each("Systems/HVAC/HVACPlant/CoolingSystem") do |orig_cooling|
        if XMLHelper.has_element(orig_cooling, "DistributionSystem")
          distribution_system_id = XMLHelper.get_idref(orig_cooling, "DistributionSystem")
        end
        cool_sys = HPXML.add_cooling_system(hvac_plant: new_hvac_plant,
                                            id: XMLHelper.get_id(orig_cooling),
                                            idref: distribution_system_id,
                                            cooling_system_type: XMLHelper.get_value(orig_cooling, "CoolingSystemType"),
                                            cooling_system_fuel: XMLHelper.get_value(orig_cooling, "CoolingSystemFuel"),
                                            cooling_capacity: XMLHelper.get_value(orig_cooling, "CoolingCapacity"),
                                            fraction_cool_load_served: XMLHelper.get_value(orig_cooling, "FractionCoolLoadServed"),
                                            annual_cooling_efficiency_units: XMLHelper.get_value(orig_cooling, "AnnualCoolingEfficiency/Units"),
                                            annual_cooling_efficiency_value: XMLHelper.get_value(orig_cooling, "AnnualCoolingEfficiency/Value"))
      end
    end
    if cooling_system.nil? and heat_pump.nil?
      add_reference_cooling_air_conditioner(new_hvac_plant)
      added_reference_cooling = true
    end

    # HeatPump
    if not heat_pump.nil?
      # Retain heat pump(s)
      orig_details.elements.each("Systems/HVAC/HVACPlant/HeatPump") do |orig_hp|
        if XMLHelper.has_element(orig_hp, "DistributionSystem")
          distribution_system_id = XMLHelper.get_idref(orig_hp, "DistributionSystem")
        end
        heat_pump = HPXML.add_heat_pump(hvac_plant: new_hvac_plant,
                                        id: XMLHelper.get_id(orig_hp),
                                        idref: distribution_system_id,
                                        heat_pump_type: XMLHelper.get_value(orig_hp, "HeatPumpType"),
                                        heating_capacity: XMLHelper.get_value(orig_hp, "HeatingCapacity"),
                                        cooling_capacity: XMLHelper.get_value(orig_hp, "CoolingCapacity"),
                                        fraction_heat_load_served: XMLHelper.get_value(orig_hp, "FractionHeatLoadServed"),
                                        fraction_cool_load_served: XMLHelper.get_value(orig_hp, "FractionCoolLoadServed"),
                                        annual_heating_efficiency_units: XMLHelper.get_value(orig_hp, "AnnualHeatingEfficiency/Units"),
                                        annual_heating_efficiency_value: XMLHelper.get_value(orig_hp, "AnnualHeatingEfficiency/Value"),
                                        annual_cooling_efficiency_units: XMLHelper.get_value(orig_hp, "AnnualCoolingEfficiency/Units"),
                                        annual_cooling_efficiency_value: XMLHelper.get_value(orig_hp, "AnnualCoolingEfficiency/Value"))
      end
    end
    if heating_system.nil? and heat_pump.nil? and not has_fuel_access(orig_details)
      add_reference_heating_heat_pump(new_hvac_plant)
      added_reference_heating = true
    end

    # Table 303.4.1(1) - Thermostat
    if not orig_details.elements["Systems/HVAC/HVACControl"].nil?
      orig_hvac_control = orig_details.elements["Systems/HVAC/HVACControl"]
      new_hvac_control = HPXML.add_hvac_control(hvac: new_hvac,
                                                id: XMLHelper.get_id(orig_hvac_control),
                                                control_type: XMLHelper.get_value(orig_hvac_control, "ControlType"))
    else
      new_hvac_control = HPXML.add_hvac_control(hvac: new_hvac,
                                                id: "HVACControl",
                                                control_type: "manual thermostat")
    end

    # Table 4.2.2(1) - Thermal distribution systems
    orig_details.elements.each("Systems/HVAC/HVACDistribution") do |orig_dist|
      other = orig_dist.elements["DistributionSystemType/Other"]
      distribution_system_type = nil
      unless other.nil?
        distribution_system_type = other.text
      end
      new_hvac_dist = HPXML.add_hvac_distribution(hvac: new_hvac,
                                                  id: XMLHelper.get_id(orig_dist),
                                                  distribution_system_type: distribution_system_type,
                                                  annual_heating_distribution_system_efficiency: XMLHelper.get_value(orig_dist, "AnnualHeatingDistributionSystemEfficiency"),
                                                  annual_cooling_distribution_system_efficiency: XMLHelper.get_value(orig_dist, "AnnualCoolingDistributionSystemEfficiency"))
      orig_air_dist = orig_dist.elements["DistributionSystemType/AirDistribution"]
      unless orig_air_dist.nil?
        new_air_dist = XMLHelper.add_element(new_hvac_dist, "DistributionSystemType/AirDistribution")
        orig_dist.elements.each("DistributionSystemType/AirDistribution/DuctLeakageMeasurement") do |orig_duct_leakage_measurement|
          orig_duct_leakage = orig_duct_leakage_measurement.elements["DuctLeakage"]
          HPXML.add_duct_leakage_measurement(air_distribution: new_air_dist,
                                            duct_type: XMLHelper.get_value(orig_duct_leakage_measurement, "DuctType"),
                                            duct_leakage_units: XMLHelper.get_value(orig_duct_leakage, "Units"),
                                            duct_leakage_value: XMLHelper.get_value(orig_duct_leakage, "Value"),
                                            duct_leakage_total_or_to_outside: XMLHelper.get_value(orig_duct_leakage, "TotalOrToOutside"))
        end
        orig_dist.elements.each("DistributionSystemType/AirDistribution/Ducts") do |orig_ducts|                                           
          HPXML.add_ducts(air_distribution: new_air_dist,
                          duct_type: XMLHelper.get_value(orig_ducts, "DuctType"),
                          duct_insulation_r_value: XMLHelper.get_value(orig_ducts, "DuctInsulationRValue"),
                          duct_location: XMLHelper.get_value(orig_ducts, "DuctLocation"),
                          duct_surface_area: XMLHelper.get_value(orig_ducts, "DuctSurfaceArea"))
        end
      end
    end
    if added_reference_heating or added_reference_cooling
      # Add DSE distribution for these systems
      add_reference_distribution_system(new_hvac)
    end
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

    orig_vent_fan = orig_details.elements["Systems/MechanicalVentilation/VentilationFans/VentilationFan[UsedForWholeBuildingVentilation='true']"]

    if not orig_vent_fan.nil?

      fan_type = XMLHelper.get_value(orig_vent_fan, "FanType")

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
      new_vent_fan = HPXML.add_ventilation_fan(ventilation_fans: new_vent_fans,
                                               id: "VentilationFan",
                                               fan_type: fan_type,
                                               rated_flow_rate: q_fan_airflow,
                                               hours_in_operation: 24, # TODO: CFIS
                                               used_for_whole_building_ventilation: true,
                                               fan_power: fan_power_w,
                                               idref: XMLHelper.get_idref(orig_vent_fan, "AttachedToHVACDistributionSystem"))
    end
  end

  def self.set_systems_mechanical_ventilation_rated(new_systems, orig_details)
    # Table 4.2.2(1) - Whole-House Mechanical ventilation
    orig_vent_fan = orig_details.elements["Systems/MechanicalVentilation/VentilationFans/VentilationFan[UsedForWholeBuildingVentilation='true']"]

    if not orig_vent_fan.nil?

      new_mech_vent = XMLHelper.add_element(new_systems, "MechanicalVentilation")
      new_vent_fans = XMLHelper.add_element(new_mech_vent, "VentilationFans")
      new_vent_fan = HPXML.add_ventilation_fan(ventilation_fans: new_vent_fans,
                                               id: "VentilationFan",
                                               fan_type: XMLHelper.get_value(orig_vent_fan, "FanType"),
                                               rated_flow_rate: XMLHelper.get_value(orig_vent_fan, "RatedFlowRate"),
                                               hours_in_operation: 24, # FIXME: Is this right?
                                               used_for_whole_building_ventilation: true,
                                               total_recovery_efficiency: XMLHelper.get_value(orig_vent_fan, "TotalRecoveryEfficiency"),
                                               sensible_recovery_efficiency: XMLHelper.get_value(orig_vent_fan, "SensibleRecoveryEfficiency"),
                                               fan_power: XMLHelper.get_value(orig_vent_fan, "FanPower"),
                                               idref: XMLHelper.get_idref(orig_vent_fan, "AttachedToHVACDistributionSystem"))
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
    new_vent_fan = HPXML.add_ventilation_fan(ventilation_fans: new_vent_fans,
                                             id: "VentilationFan",
                                             fan_type: "balanced",
                                             rated_flow_rate: q_fan_airflow,
                                             hours_in_operation: 24,
                                             used_for_whole_building_ventilation: true,
                                             fan_power: fan_power_w)
  end

  def self.set_systems_water_heater_reference(new_systems, orig_details)
    new_water_heating = XMLHelper.add_element(new_systems, "WaterHeating")

    # Table 4.2.2(1) - Service water heating systems

    orig_wh_sys = orig_details.elements["Systems/WaterHeating/WaterHeatingSystem"]

    wh_type = nil
    wh_tank_vol = nil
    wh_fuel_type = nil
    wh_sys_id = "WaterHeatingSystem"
    if not orig_wh_sys.nil?
      wh_type = XMLHelper.get_value(orig_wh_sys, "WaterHeaterType")
      if orig_wh_sys.elements["TankVolume"]
        wh_tank_vol = Float(XMLHelper.get_value(orig_wh_sys, "TankVolume"))
      end
      wh_fuel_type = XMLHelper.get_value(orig_wh_sys, "FuelType")
      wh_location = XMLHelper.get_value(orig_wh_sys, "Location")
      wh_sys_id = XMLHelper.get_id(orig_wh_sys)
    end

    if orig_wh_sys.nil?
      wh_tank_vol = 40.0
      wh_fuel_type = XMLHelper.get_value(orig_details, "Systems/HVAC/HVACPlant/HeatingSystem/HeatingSystemFuel")
      if wh_fuel_type.nil? # Electric heat pump or no heating system
        wh_fuel_type = 'electricity'
      end
      wh_location = 'living space' # 301 Standard doesn't specify the location
    elsif wh_type == 'instantaneous water heater'
      wh_tank_vol = 40.0
    end
    wh_type = 'storage water heater'

    wh_ef, wh_re = get_water_heater_ef_and_re(wh_fuel_type, wh_tank_vol)
    wh_cap = Waterheater.calc_water_heater_capacity(to_beopt_fuel(wh_fuel_type), @nbeds) * 1000.0 # Btuh

    # New water heater
    new_wh_sys = HPXML.add_water_heating_system(water_heating: new_water_heating,
                                                id: wh_sys_id,
                                                fuel_type: wh_fuel_type,
                                                water_heater_type: wh_type,
                                                location: wh_location,
                                                tank_volume: wh_tank_vol,
                                                fraction_dhw_load_served: 1.0,
                                                heating_capacity: wh_cap,
                                                energy_factor: wh_ef,
                                                recovery_efficiency: wh_re)
  end

  def self.set_systems_water_heater_rated(new_systems, orig_details)
    new_water_heating = XMLHelper.add_element(new_systems, "WaterHeating")

    # Table 4.2.2(1) - Service water heating systems

    orig_wh_sys = orig_details.elements["Systems/WaterHeating/WaterHeatingSystem"]

    if not orig_wh_sys.nil?
      wh_ef = XMLHelper.get_value(orig_wh_sys, "EnergyFactor")
      wh_uef = XMLHelper.get_value(orig_wh_sys, "UniformEnergyFactor")
      if wh_ef.nil? and not wh_uef.nil?
        wh_uef = Float(XMLHelper.get_value(orig_wh_sys, "UniformEnergyFactor"))
        wh_type = XMLHelper.get_value(orig_wh_sys, "WaterHeaterType")
        wh_fuel_type = XMLHelper.get_value(orig_wh_sys, "FuelType")
        wh_ef = Waterheater.calc_ef_from_uef(wh_uef, to_beopt_wh_type(wh_type), to_beopt_fuel(wh_fuel_type))
      end

      # New water heater
      new_wh_sys = HPXML.add_water_heating_system(water_heating: new_water_heating,
                                                  id: XMLHelper.get_id(orig_wh_sys),
                                                  fuel_type: XMLHelper.get_value(orig_wh_sys, "FuelType"),
                                                  water_heater_type: XMLHelper.get_value(orig_wh_sys, "WaterHeaterType"),
                                                  location: XMLHelper.get_value(orig_wh_sys, "Location"),
                                                  tank_volume: XMLHelper.get_value(orig_wh_sys, "TankVolume"),
                                                  fraction_dhw_load_served: XMLHelper.get_value(orig_wh_sys, "FractionDHWLoadServed"),
                                                  heating_capacity: XMLHelper.get_value(orig_wh_sys, "HeatingCapacity"),
                                                  energy_factor: wh_ef,
                                                  recovery_efficiency: XMLHelper.get_value(orig_wh_sys, "RecoveryEfficiency"))
    else

      wh_type = 'storage water heater'
      wh_tank_vol = 40.0
      wh_fuel_type = XMLHelper.get_value(orig_details, "Systems/HVAC/HVACPlant/HeatingSystem/HeatingSystemFuel")
      if wh_fuel_type.nil? # Electric heat pump or no heating system
        wh_fuel_type = 'electricity'
      end
      wh_ef, wh_re = get_water_heater_ef_and_re(wh_fuel_type, wh_tank_vol)
      wh_cap = Waterheater.calc_water_heater_capacity(to_beopt_fuel(wh_fuel_type), @nbeds) * 1000.0 # Btuh
      wh_location = 'living space' # 301 Standard doesn't specify the location

      # New water heater
      new_wh_sys = HPXML.add_water_heating_system(water_heating: new_water_heating,
                                                  id: "WaterHeatingSystem",
                                                  fuel_type: wh_fuel_type,
                                                  water_heater_type: wh_type,
                                                  location: wh_location,
                                                  tank_volume: wh_tank_vol,
                                                  fraction_dhw_load_served: 1.0,
                                                  heating_capacity: wh_cap,
                                                  energy_factor: wh_ef,
                                                  recovery_efficiency: wh_re)
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

    sys_id = nil
    if orig_water_heating.nil?
      sys_id = "HotWaterDistribution"
    else
      orig_hw_dist = orig_water_heating.elements["HotWaterDistribution"]
      sys_id = XMLHelper.get_id(orig_hw_dist)
    end

    # New hot water distribution
    new_hw_dist = HPXML.add_hot_water_distribution(water_heating: new_water_heating,
                                                   id: sys_id,
                                                   system_type: "Standard",
                                                   pipe_r_value: 0,
                                                   standard_piping_length: std_pipe_length)

    # New water fixtures
    if orig_water_heating.nil?
      # Shower Head
      new_fixture = HPXML.add_water_fixture(water_heating: new_water_heating,
                                            id: "ShowerHead",
                                            water_fixture_type: "shower head",
                                            low_flow: false)

      # Faucet
      new_fixture = HPXML.add_water_fixture(water_heating: new_water_heating,
                                            id: "Faucet",
                                            water_fixture_type: "faucet",
                                            low_flow: false)
    else
      orig_water_heating.elements.each("WaterFixture[WaterFixtureType='shower head' or WaterFixtureType='faucet']") do |orig_fixture|
        new_fixture = HPXML.add_water_fixture(water_heating: new_water_heating,
                                              id: XMLHelper.get_id(orig_fixture),
                                              water_fixture_type: XMLHelper.get_value(orig_fixture, "WaterFixtureType"),
                                              low_flow: false)
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
    recirc_loop_length = HotWaterAndAppliances.get_default_recirc_loop_length(std_pipe_length)    
    orig_standard = orig_hw_dist.elements["SystemType/Standard"]
    orig_recirc = orig_hw_dist.elements["SystemType/Recirculation"]
    if not orig_standard.nil?
      unless orig_standard.elements["PipingLength"].nil?
        std_pipe_length = XMLHelper.get_value(orig_standard, "PipingLength")
      end
    elsif not orig_recirc.nil?
      unless orig_recirc.elements["RecirculationPipingLoopLength"].nil?
        recirc_loop_length = XMLHelper.get_value(orig_recirc, "RecirculationPipingLoopLength")
      end
    end
    pipe_ins = orig_hw_dist.elements["PipeInsulation"]
    orig_dwhr = orig_hw_dist.elements["DrainWaterHeatRecovery"]

    # New hot water distribution
    new_hw_dist = HPXML.add_hot_water_distribution(water_heating: new_water_heating,
                                                   id: XMLHelper.get_id(orig_hw_dist),
                                                   system_type: XMLHelper.get_child_name(orig_hw_dist, "SystemType"),
                                                   pipe_r_value: XMLHelper.get_value(pipe_ins, "PipeRValue"),
                                                   standard_piping_length: std_pipe_length,
                                                   recirculation_control_type: XMLHelper.get_value(orig_recirc, "ControlType"),
                                                   recirculation_piping_loop_length: recirc_loop_length,
                                                   recirculation_branch_piping_loop_length: XMLHelper.get_value(orig_recirc, "BranchPipingLoopLength"),
                                                   recirculation_pump_power: XMLHelper.get_value(orig_recirc, "PumpPower"),
                                                   drain_water_heat_recovery_facilities_connected: XMLHelper.get_value(orig_dwhr, "FacilitiesConnected"),
                                                   drain_water_heat_recovery_equal_flow: XMLHelper.get_value(orig_dwhr, "EqualFlow"),
                                                   drain_water_heat_recovery_efficiency: XMLHelper.get_value(orig_dwhr, "Efficiency"))

    # New water fixtures
    orig_water_heating.elements.each("WaterFixture[WaterFixtureType='shower head' or WaterFixtureType='faucet']") do |orig_fixture|
      new_fixture = HPXML.add_water_fixture(water_heating: new_water_heating,
                                            id: XMLHelper.get_id(orig_fixture),
                                            water_fixture_type: XMLHelper.get_value(orig_fixture, "WaterFixtureType"),
                                            low_flow: XMLHelper.get_value(orig_fixture, "LowFlow"))
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
      new_pv = HPXML.add_pv_system(photovoltaics: new_pvs,
                                   id: XMLHelper.get_id(orig_pv),
                                   module_type: XMLHelper.get_value(orig_pv, "ModuleType"),
                                   array_type: XMLHelper.get_value(orig_pv, "ArrayType"),
                                   array_azimuth: XMLHelper.get_value(orig_pv, "ArrayAzimuth"),
                                   array_tilt: XMLHelper.get_value(orig_pv, "ArrayTilt"),
                                   max_power_output: XMLHelper.get_value(orig_pv, "MaxPowerOutput"),
                                   inverter_efficiency: XMLHelper.get_value(orig_pv, "InverterEfficiency"),
                                   system_losses_fraction: XMLHelper.get_value(orig_pv, "SystemLossesFraction"))
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

    new_washer = HPXML.add_clothes_washer(appliances: new_appliances,
                                          id: XMLHelper.get_id(orig_washer),
                                          location: "living space",
                                          modified_energy_factor: HotWaterAndAppliances.get_clothes_washer_reference_mef(),
                                          rated_annual_kwh: HotWaterAndAppliances.get_clothes_washer_reference_ler(),
                                          label_electric_rate: HotWaterAndAppliances.get_clothes_washer_reference_elec_rate(),
                                          label_gas_rate: HotWaterAndAppliances.get_clothes_washer_reference_gas_rate(),
                                          label_annual_gas_cost: HotWaterAndAppliances.get_clothes_washer_reference_agc(),
                                          capacity: HotWaterAndAppliances.get_clothes_washer_reference_cap())
  end

  def self.set_appliances_clothes_washer_rated(new_appliances, orig_details)
    orig_appliances = orig_details.elements["Appliances"]
    orig_washer = orig_appliances.elements["ClothesWasher"]

    if orig_washer.elements["ModifiedEnergyFactor"].nil? and orig_washer.elements["IntegratedModifiedEnergyFactor"].nil?
      self.set_appliances_clothes_washer_reference(new_appliances, orig_details)
      return
    end

    new_washer = HPXML.add_clothes_washer(appliances: new_appliances,
                                          id: XMLHelper.get_id(orig_washer),
                                          location: XMLHelper.get_value(orig_washer, "Location"),
                                          modified_energy_factor: XMLHelper.get_value(orig_washer, "ModifiedEnergyFactor"),
                                          integrated_modified_energy_factor: XMLHelper.get_value(orig_washer, "IntegratedModifiedEnergyFactor"),
                                          rated_annual_kwh: XMLHelper.get_value(orig_washer, "RatedAnnualkWh"),
                                          label_electric_rate: XMLHelper.get_value(orig_washer, "LabelElectricRate"),
                                          label_gas_rate: XMLHelper.get_value(orig_washer, "LabelGasRate"),
                                          label_annual_gas_cost: XMLHelper.get_value(orig_washer, "LabelAnnualGasCost"),
                                          capacity: XMLHelper.get_value(orig_washer, "Capacity"))
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

    new_dryer = HPXML.add_clothes_dryer(appliances: new_appliances,
                                        id: XMLHelper.get_id(orig_dryer),
                                        location: "living space",
                                        fuel_type: cd_fuel,
                                        energy_factor: cd_ef,
                                        control_type: cd_control)
  end

  def self.set_appliances_clothes_dryer_rated(new_appliances, orig_details)
    orig_appliances = orig_details.elements["Appliances"]
    orig_dryer = orig_appliances.elements["ClothesDryer"]

    if orig_dryer.elements["EnergyFactor"].nil? and orig_dryer.elements["CombinedEnergyFactor"].nil?
      self.set_appliances_clothes_dryer_reference(new_appliances, orig_details)
      return
    end

    new_dryer = HPXML.add_clothes_dryer(appliances: new_appliances,
                                        id: XMLHelper.get_id(orig_dryer),
                                        location: XMLHelper.get_value(orig_dryer, "Location"),
                                        fuel_type: XMLHelper.get_value(orig_dryer, "FuelType"),
                                        energy_factor: XMLHelper.get_value(orig_dryer, "EnergyFactor"),
                                        combined_energy_factor: XMLHelper.get_value(orig_dryer, "CombinedEnergyFactor"),
                                        control_type: XMLHelper.get_value(orig_dryer, "ControlType"))
  end

  def self.set_appliances_clothes_dryer_iad(new_appliances, orig_details)
    # Table 4.3.1(1) Configuration of Index Adjustment Design - Lighting, Appliances and Miscellaneous Electric Loads (MELs)
    self.set_appliances_clothes_dryer_reference(new_appliances, orig_details)
  end

  def self.set_appliances_dishwasher_reference(new_appliances, orig_details)
    orig_appliances = orig_details.elements["Appliances"]
    orig_dishwasher = orig_appliances.elements["Dishwasher"]

    new_dishwasher = HPXML.add_dishwasher(appliances: new_appliances,
                                          id: XMLHelper.get_id(orig_dishwasher),
                                          energy_factor: HotWaterAndAppliances.get_dishwasher_reference_ef(),
                                          place_setting_capacity: Integer(HotWaterAndAppliances.get_dishwasher_reference_cap()))
  end

  def self.set_appliances_dishwasher_rated(new_appliances, orig_details)
    orig_appliances = orig_details.elements["Appliances"]
    orig_dishwasher = orig_appliances.elements["Dishwasher"]

    if orig_dishwasher.elements["EnergyFactor"].nil? and orig_dishwasher.elements["RatedAnnualkWh"].nil?
      self.set_appliances_dishwasher_reference(new_appliances, orig_details)
      return
    end

    new_dishwasher = HPXML.add_dishwasher(appliances: new_appliances,
                                          id: XMLHelper.get_id(orig_dishwasher),
                                          energy_factor: XMLHelper.get_value(orig_dishwasher, "EnergyFactor"),
                                          rated_annual_kwh: XMLHelper.get_value(orig_dishwasher, "RatedAnnualkWh"),
                                          place_setting_capacity: XMLHelper.get_value(orig_dishwasher, "PlaceSettingCapacity"))
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

    new_fridge = HPXML.add_refrigerator(appliances: new_appliances,
                                        id: XMLHelper.get_id(orig_fridge),
                                        location: "living space",
                                        rated_annual_kwh: refrigerator_kwh)
  end

  def self.set_appliances_refrigerator_rated(new_appliances, orig_details)
    orig_appliances = orig_details.elements["Appliances"]
    orig_fridge = orig_appliances.elements["Refrigerator"]

    if orig_fridge.elements["RatedAnnualkWh"].nil?
      self.set_appliances_refrigerator_reference(new_appliances, orig_details)
      return
    end

    new_fridge = HPXML.add_refrigerator(appliances: new_appliances,
                                        id: XMLHelper.get_id(orig_fridge),
                                        location: XMLHelper.get_value(orig_fridge, "Location"),
                                        rated_annual_kwh: XMLHelper.get_value(orig_fridge, "RatedAnnualkWh"))
  end

  def self.set_appliances_refrigerator_iad(new_appliances, orig_details)
    # Table 4.3.1(1) Configuration of Index Adjustment Design - Lighting, Appliances and Miscellaneous Electric Loads (MELs)
    self.set_appliances_refrigerator_reference(new_appliances, orig_details)
  end

  def self.set_appliances_cooking_range_oven_reference(new_appliances, orig_details)
    orig_appliances = orig_details.elements["Appliances"]
    orig_range = orig_appliances.elements["CookingRange"]
    orig_oven = orig_appliances.elements["Oven"]

    new_range = HPXML.add_cooking_range(appliances: new_appliances,
                                        id: XMLHelper.get_id(orig_range),
                                        fuel_type: XMLHelper.get_value(orig_range, "FuelType"),
                                        is_induction: HotWaterAndAppliances.get_range_oven_reference_is_induction())

    new_oven = HPXML.add_oven(appliances: new_appliances,
                              id: XMLHelper.get_id(orig_oven),
                              is_convection: HotWaterAndAppliances.get_range_oven_reference_is_convection())
  end

  def self.set_appliances_cooking_range_oven_rated(new_appliances, orig_details)
    orig_appliances = orig_details.elements["Appliances"]
    orig_range = orig_appliances.elements["CookingRange"]
    orig_oven = orig_appliances.elements["Oven"]

    if orig_range.elements["IsInduction"].nil?
      self.set_appliances_cooking_range_oven_reference(new_appliances, orig_details)
      return
    end

    new_range = HPXML.add_cooking_range(appliances: new_appliances,
                                        id: XMLHelper.get_id(orig_range),
                                        fuel_type: XMLHelper.get_value(orig_range, "FuelType"),
                                        is_induction: XMLHelper.get_value(orig_range, "IsInduction"))

    new_oven = HPXML.add_oven(appliances: new_appliances,
                              id: XMLHelper.get_id(orig_oven),
                              is_convection: XMLHelper.get_value(orig_oven, "IsConvection"))
  end

  def self.set_appliances_cooking_range_oven_iad(new_appliances, orig_details)
    # Table 4.3.1(1) Configuration of Index Adjustment Design - Lighting, Appliances and Miscellaneous Electric Loads (MELs)
    self.set_appliances_cooking_range_oven_reference(new_appliances, orig_details)
  end

  def self.set_lighting_reference(new_lighting, orig_details)
    fFI_int, fFI_ext, fFI_grg, fFII_int, fFII_ext, fFII_grg = Lighting.get_reference_fractions()

    new_fractions = HPXML.add_lighting_fractions(lighting: new_lighting,
                                                 fraction_qualifying_tier_i_fixtures_interior: fFI_int,
                                                 fraction_qualifying_tier_i_fixtures_exterior: fFI_ext,
                                                 fraction_qualifying_tier_i_fixtures_garage: fFI_grg,
                                                 fraction_qualifying_tier_ii_fixtures_interior: fFII_int,
                                                 fraction_qualifying_tier_ii_fixtures_exterior: fFII_ext,
                                                 fraction_qualifying_tier_ii_fixtures_garage: fFII_grg)
  end

  def self.set_lighting_rated(new_lighting, orig_details)
    orig_lighting = orig_details.elements["Lighting"]
    orig_fractions = orig_lighting.elements["LightingFractions"]

    if orig_fractions.nil?
      self.set_lighting_reference(new_lighting, orig_details)
      return
    end

    extension = orig_fractions.elements["extension"]

    # For rating purposes, the Rated Home shall not have qFFIL less than 0.10 (10%).
    fFI_int = Float(XMLHelper.get_value(extension, "FractionQualifyingTierIFixturesInterior"))
    fFII_int = Float(XMLHelper.get_value(extension, "FractionQualifyingTierIIFixturesInterior"))
    if fFI_int + fFII_int < 0.1
      fFI_int = 0.1 - fFII_int
    end

    new_fractions = HPXML.add_lighting_fractions(lighting: new_lighting,
                                                 fraction_qualifying_tier_i_fixtures_interior: fFI_int,
                                                 fraction_qualifying_tier_i_fixtures_exterior: XMLHelper.get_value(extension, "FractionQualifyingTierIFixturesExterior"),
                                                 fraction_qualifying_tier_i_fixtures_garage: XMLHelper.get_value(extension, "FractionQualifyingTierIFixturesGarage"),
                                                 fraction_qualifying_tier_ii_fixtures_interior: XMLHelper.get_value(extension, "FractionQualifyingTierIIFixturesInterior"),
                                                 fraction_qualifying_tier_ii_fixtures_exterior: XMLHelper.get_value(extension, "FractionQualifyingTierIIFixturesExterior"),
                                                 fraction_qualifying_tier_ii_fixtures_garage: XMLHelper.get_value(extension, "FractionQualifyingTierIIFixturesGarage"))
  end

  def self.set_lighting_iad(new_lighting, orig_details)
    fFI_int, fFI_ext, fFI_grg, fFII_int, fFII_ext, fFII_grg = Lighting.get_iad_fractions()

    new_fractions = HPXML.add_lighting_fractions(lighting: new_lighting,
                                                 fraction_qualifying_tier_i_fixtures_interior: fFI_int,
                                                 fraction_qualifying_tier_i_fixtures_exterior: fFI_ext,
                                                 fraction_qualifying_tier_i_fixtures_garage: fFI_grg,
                                                 fraction_qualifying_tier_ii_fixtures_interior: fFII_int,
                                                 fraction_qualifying_tier_ii_fixtures_exterior: fFII_ext,
                                                 fraction_qualifying_tier_ii_fixtures_garage: fFII_grg)
  end

  def self.set_ceiling_fans_reference(new_lighting, orig_details)
    return if not XMLHelper.has_element(orig_details, "Lighting/CeilingFan")

    orig_cf = orig_details.elements["Lighting/CeilingFan"]
    medium_cfm = 3000.0

    new_cf = HPXML.add_ceiling_fan(lighting: new_lighting,
                                   id: "CeilingFans",
                                   fan_speed: "medium",
                                   efficiency: medium_cfm / HVAC.get_default_ceiling_fan_power(),
                                   quantity: Integer(HVAC.get_default_ceiling_fan_quantity(@nbeds)))
  end

  def self.set_ceiling_fans_rated(new_lighting, orig_details)
    return if not XMLHelper.has_element(orig_details, "Lighting/CeilingFan")

    medium_cfm = 3000.0

    # Calculate average ceiling fan wattage
    sum_w = 0.0
    num_cfs = 0
    orig_details.elements.each("Lighting/CeilingFan") do |orig_cf|
      cf_quantity = Integer(XMLHelper.get_value(orig_cf, "Quantity"))
      num_cfs += cf_quantity
      cfm_per_w = XMLHelper.get_value(orig_cf, "Airflow[FanSpeed='medium']/Efficiency")
      if cfm_per_w.nil?
        fan_power_w = HVAC.get_default_ceiling_fan_power()
        cfm_per_w = medium_cfm / fan_power_w
      else
        cfm_per_w = Float(cfm_per_w)
      end
      sum_w += (medium_cfm / cfm_per_w * Float(cf_quantity))
    end
    avg_w = sum_w / num_cfs

    new_cf = HPXML.add_ceiling_fan(lighting: new_lighting,
                                   id: "CeilingFans",
                                   fan_speed: "medium",
                                   efficiency: medium_cfm / avg_w,
                                   quantity: Integer(HVAC.get_default_ceiling_fan_quantity(@nbeds)))
  end

  def self.set_ceiling_fans_iad(new_lighting, orig_details)
    # Not described in Addendum E; use Reference Home?
    set_ceiling_fans_reference(new_lighting, orig_details)
  end

  def self.set_misc_loads_reference(new_misc_loads)
    # Misc
    misc = HPXML.add_plug_load(misc_loads: new_misc_loads,
                               id: "MiscPlugLoad",
                               plug_load_type: "other")

    # Television
    tv = HPXML.add_plug_load(misc_loads: new_misc_loads,
                             id: "TelevisionPlugLoad",
                             plug_load_type: "TV other")
  end

  def self.set_misc_loads_rated(new_misc_loads)
    set_misc_loads_reference(new_misc_loads)
  end

  def self.set_misc_loads_iad(new_misc_loads)
    set_misc_loads_reference(new_misc_loads)
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

  def self.add_reference_heating_gas_furnace(new_hvac_plant, load_frac = 1.0, seed_id = nil)
    # 78% AFUE gas furnace
    cnt = new_hvac_plant.elements["count(HeatingSystem)"]
    heat_sys = HPXML.add_heating_system(hvac_plant: new_hvac_plant,
                                        id: "HeatingSystem#{cnt + 1}",
                                        idref: "HVACDistribution_DSE_80",
                                        heating_system_type: "Furnace",
                                        heating_system_fuel: "natural gas",
                                        heating_capacity: -1, # Use Manual J auto-sizing
                                        annual_heating_efficiency_units: "AFUE",
                                        annual_heating_efficiency_value: 0.78,
                                        fraction_heat_load_served: load_frac)
    if not seed_id.nil? and [Constants.CalcTypeERIReferenceHome,
                             Constants.CalcTypeERIIndexAdjustmentReferenceHome].include? @calc_type
      # Map reference home system back to rated home system
      HPXML.add_extension(parent: heat_sys,
                          extensions: {"SeedId": seed_id})
    end
  end

  def self.add_reference_heating_gas_boiler(new_hvac_plant, load_frac = 1.0, seed_id = nil)
    # 80% AFUE gas boiler
    cnt = new_hvac_plant.elements["count(HeatingSystem)"]
    heat_sys = HPXML.add_heating_system(hvac_plant: new_hvac_plant,
                                        id: "HeatingSystem#{cnt + 1}",
                                        idref: "HVACDistribution_DSE_80",
                                        heating_system_type: "Boiler",
                                        heating_system_fuel: "natural gas",
                                        heating_capacity: -1, # Use Manual J auto-sizing
                                        annual_heating_efficiency_units: "AFUE",
                                        annual_heating_efficiency_value: 0.80,
                                        fraction_heat_load_served: load_frac)
    if not seed_id.nil? and [Constants.CalcTypeERIReferenceHome,
                             Constants.CalcTypeERIIndexAdjustmentReferenceHome].include? @calc_type
      # Map reference home system back to rated home system
      HPXML.add_extension(parent: heat_sys,
                          extensions: {"SeedId": seed_id})
    end
  end

  def self.add_reference_heating_heat_pump(new_hvac_plant, load_frac = 1.0, seed_id = nil)
    # 7.7 HSPF air source heat pump
    cnt = new_hvac_plant.elements["count(HeatPump)"]
    heat_pump = HPXML.add_heat_pump(hvac_plant: new_hvac_plant,
                                    id: "HeatPump#{cnt + 1}",
                                    idref: "HVACDistribution_DSE_80",
                                    heat_pump_type: "air-to-air",
                                    cooling_capacity: -1, # Use Manual J auto-sizing
                                    fraction_heat_load_served: load_frac,
                                    fraction_cool_load_served: 0.0,
                                    annual_cooling_efficiency_units: "SEER",
                                    annual_cooling_efficiency_value: 13.0, # Arbitrary, not used
                                    annual_heating_efficiency_units: "HSPF",
                                    annual_heating_efficiency_value: 7.7)
    if not seed_id.nil? and [Constants.CalcTypeERIReferenceHome,
                             Constants.CalcTypeERIIndexAdjustmentReferenceHome].include? @calc_type
      # Map reference home system back to rated home system
      HPXML.add_extension(parent: heat_pump,
                          extensions: {"SeedId": seed_id})
    end
  end

  def self.add_reference_cooling_air_conditioner(new_hvac_plant, load_frac = 1.0, seed_id = nil)
    # 13 SEER electric air conditioner
    cnt = new_hvac_plant.elements["count(CoolingSystem)"]
    cool_sys = HPXML.add_cooling_system(hvac_plant: new_hvac_plant,
                                        id: "CoolingSystem#{cnt + 1}",
                                        idref: "HVACDistribution_DSE_80",
                                        cooling_system_type: "central air conditioning",
                                        cooling_system_fuel: "electricity",
                                        cooling_capacity: -1, # Use Manual J auto-sizing
                                        fraction_cool_load_served: load_frac,
                                        annual_cooling_efficiency_units: "SEER",
                                        annual_cooling_efficiency_value: 13.0)
    if not seed_id.nil? and [Constants.CalcTypeERIReferenceHome,
                             Constants.CalcTypeERIIndexAdjustmentReferenceHome].include? @calc_type
      # Map reference home system back to rated home system
      HPXML.add_extension(parent: cool_sys,
                          extensions: {"SeedId": seed_id})
    end
  end

  def self.add_reference_distribution_system(new_hvac)
    # Table 4.2.2(1) - Thermal distribution systems
    new_hvac_dist = HPXML.add_hvac_distribution(hvac: new_hvac,
                                                id: "HVACDistribution_DSE_80",
                                                distribution_system_type: "DSE",
                                                annual_heating_distribution_system_efficiency: 0.8,
                                                annual_cooling_distribution_system_efficiency: 0.8)
  end
end

def get_exterior_wall_area_fracs(orig_details)
  # Get individual exterior wall areas and sum
  wall_areas = {}
  wall_area_sum = 0.0
  orig_details.elements.each("Enclosure/Walls/Wall") do |wall|
    next if XMLHelper.get_value(wall, "ExteriorAdjacentTo") != "outside"
    next if XMLHelper.get_value(wall, "InteriorAdjacentTo") != "living space"

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
