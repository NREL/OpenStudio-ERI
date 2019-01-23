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

    # Global variables
    @weather = weather
    orig_building_construction = building.elements["BuildingDetails/BuildingSummary/BuildingConstruction"]
    orig_building_construction_values = HPXML.get_building_construction_values(building_construction: orig_building_construction)
    @cfa = Float(orig_building_construction_values[:conditioned_floor_area])
    @nbeds = Float(orig_building_construction_values[:number_of_bedrooms])
    @ncfl = Float(orig_building_construction_values[:number_of_conditioned_floors])
    @ncfl_ag = Float(orig_building_construction_values[:number_of_conditioned_floors_above_grade])
    @cvolume = Float(orig_building_construction_values[:conditioned_building_volume])
    @garage_present = Boolean(orig_building_construction_values[:garage_present])
    @iecc_zone_2006 = XMLHelper.get_value(building, "BuildingDetails/ClimateandRiskZones/ClimateZoneIECC[Year='2006']/ClimateZone")
    @iecc_zone_2012 = XMLHelper.get_value(building, "BuildingDetails/ClimateandRiskZones/ClimateZoneIECC[Year='2012']/ClimateZone")
    @calc_type = calc_type

    # Update HPXML object based on calculation type
    if calc_type == Constants.CalcTypeERIReferenceHome
      hpxml_doc = apply_reference_home_ruleset(hpxml_doc)
    elsif calc_type == Constants.CalcTypeERIRatedHome
      hpxml_doc = apply_rated_home_ruleset(hpxml_doc)
    elsif calc_type == Constants.CalcTypeERIIndexAdjustmentDesign
      hpxml_doc = apply_index_adjustment_design_ruleset(hpxml_doc)
    elsif calc_type == Constants.CalcTypeERIIndexAdjustmentReferenceHome
      hpxml_doc = apply_index_adjustment_design_ruleset(hpxml_doc)
      hpxml_doc = apply_reference_home_ruleset(hpxml_doc)
    end

    return hpxml_doc
  end

  def self.create_new_doc(hpxml_doc)
    xml_transaction_header_information_values = HPXML.get_xml_transaction_header_information_values(xml_transaction_header_information: hpxml_doc.elements["/HPXML/XMLTransactionHeaderInformation"])
    software_info_values = HPXML.get_software_info_values(software_info: hpxml_doc.elements["/HPXML/SoftwareInfo"])
    building_values = HPXML.get_building_values(building: hpxml_doc.elements["/HPXML/Building"])
    project_status_values = HPXML.get_project_status_values(project_status: hpxml_doc.elements["/HPXML/Building/ProjectStatus"])

    hpxml_doc = HPXML.create_hpxml(xml_type: xml_transaction_header_information_values[:xml_type],
                                   xml_generated_by: xml_transaction_header_information_values[:xml_generated_by],
                                   transaction: xml_transaction_header_information_values[:transaction],
                                   software_program_used: software_info_values[:software_program_used],
                                   software_program_version: software_info_values[:software_program_version],
                                   eri_calculation_version: software_info_values[:eri_calculation_version],
                                   building_id: building_values[:id],
                                   event_type: project_status_values[:event_type])

    return hpxml_doc
  end

  def self.apply_reference_home_ruleset(hpxml_doc)
    orig_details = hpxml_doc.elements["/HPXML/Building/BuildingDetails"]
    hpxml_doc = create_new_doc(hpxml_doc)
    hpxml = hpxml_doc.elements["HPXML"]

    # BuildingSummary
    set_summary_reference(orig_details, hpxml)

    # ClimateAndRiskZones
    set_climate(orig_details, hpxml)

    # Enclosure
    set_enclosure_air_infiltration_reference(hpxml)
    set_enclosure_attics_roofs_reference(orig_details, hpxml)
    set_enclosure_foundations_reference(orig_details, hpxml)
    set_enclosure_rim_joists_reference(orig_details, hpxml)
    set_enclosure_walls_reference(orig_details, hpxml)
    set_enclosure_windows_reference(orig_details, hpxml)
    set_enclosure_skylights_reference(hpxml)
    set_enclosure_doors_reference(orig_details, hpxml)

    # Systems
    set_systems_hvac_reference(orig_details, hpxml)
    set_systems_mechanical_ventilation_reference(orig_details, hpxml)
    set_systems_water_heater_reference(orig_details, hpxml)
    set_systems_water_heating_use_reference(orig_details, hpxml)
    set_systems_photovoltaics_reference(hpxml)

    # Appliances
    set_appliances_clothes_washer_reference(orig_details, hpxml)
    set_appliances_clothes_dryer_reference(orig_details, hpxml)
    set_appliances_dishwasher_reference(orig_details, hpxml)
    set_appliances_refrigerator_reference(orig_details, hpxml)
    set_appliances_cooking_range_oven_reference(orig_details, hpxml)

    # Lighting
    set_lighting_reference(orig_details, hpxml)
    set_ceiling_fans_reference(orig_details, hpxml)

    # MiscLoads
    set_misc_loads_reference(hpxml)

    return hpxml_doc
  end

  def self.apply_rated_home_ruleset(hpxml_doc)
    orig_details = hpxml_doc.elements["/HPXML/Building/BuildingDetails"]
    hpxml_doc = create_new_doc(hpxml_doc)
    hpxml = hpxml_doc.elements["HPXML"]

    # BuildingSummary
    set_summary_rated(orig_details, hpxml)

    # ClimateAndRiskZones
    set_climate(orig_details, hpxml)

    # Enclosure
    set_enclosure_air_infiltration_rated(orig_details, hpxml)
    set_enclosure_attics_roofs_rated(orig_details, hpxml)
    set_enclosure_foundations_rated(orig_details, hpxml)
    set_enclosure_rim_joists_rated(orig_details, hpxml)
    set_enclosure_walls_rated(orig_details, hpxml)
    set_enclosure_windows_rated(orig_details, hpxml)
    set_enclosure_skylights_rated(orig_details, hpxml)
    set_enclosure_doors_rated(orig_details, hpxml)

    # Systems
    set_systems_hvac_rated(orig_details, hpxml)
    set_systems_mechanical_ventilation_rated(orig_details, hpxml)
    set_systems_water_heater_rated(orig_details, hpxml)
    set_systems_water_heating_use_rated(orig_details, hpxml)
    set_systems_photovoltaics_rated(orig_details, hpxml)

    # Appliances
    set_appliances_clothes_washer_rated(orig_details, hpxml)
    set_appliances_clothes_dryer_rated(orig_details, hpxml)
    set_appliances_dishwasher_rated(orig_details, hpxml)
    set_appliances_refrigerator_rated(orig_details, hpxml)
    set_appliances_cooking_range_oven_rated(orig_details, hpxml)

    # Lighting
    set_lighting_rated(orig_details, hpxml)
    set_ceiling_fans_rated(orig_details, hpxml)

    # MiscLoads
    set_misc_loads_rated(hpxml)

    return hpxml_doc
  end

  def self.apply_index_adjustment_design_ruleset(hpxml_doc)
    orig_details = hpxml_doc.elements["/HPXML/Building/BuildingDetails"]
    hpxml_doc = create_new_doc(hpxml_doc)
    hpxml = hpxml_doc.elements["HPXML"]

    # BuildingSummary
    set_summary_iad(orig_details, hpxml)

    # ClimateAndRiskZones
    set_climate(orig_details, hpxml)

    # Enclosure
    set_enclosure_air_infiltration_iad(hpxml)
    set_enclosure_attics_roofs_iad(orig_details, hpxml)
    set_enclosure_foundations_iad(hpxml)
    set_enclosure_rim_joists_iad(orig_details, hpxml)
    set_enclosure_walls_iad(orig_details, hpxml)
    set_enclosure_windows_iad(orig_details, hpxml)
    set_enclosure_skylights_iad(orig_details, hpxml)
    set_enclosure_doors_iad(orig_details, hpxml)

    # Systems
    set_systems_hvac_iad(orig_details, hpxml)
    set_systems_mechanical_ventilation_iad(orig_details, hpxml)
    set_systems_water_heater_iad(orig_details, hpxml)
    set_systems_water_heating_use_iad(orig_details, hpxml)
    set_systems_photovoltaics_iad(hpxml)

    # Appliances
    set_appliances_clothes_washer_iad(orig_details, hpxml)
    set_appliances_clothes_dryer_iad(orig_details, hpxml)
    set_appliances_dishwasher_iad(orig_details, hpxml)
    set_appliances_refrigerator_iad(orig_details, hpxml)
    set_appliances_cooking_range_oven_iad(orig_details, hpxml)

    # Lighting
    set_lighting_iad(orig_details, hpxml)
    set_ceiling_fans_iad(orig_details, hpxml)

    # MiscLoads
    set_misc_loads_iad(hpxml)

    return hpxml_doc
  end

  def self.set_summary_reference(orig_details, hpxml)
    orig_site = orig_details.elements["BuildingSummary/Site"]
    orig_site_values = HPXML.get_site_values(site: orig_site)
    HPXML.add_site(hpxml: hpxml,
                   fuels: orig_site_values[:fuels],
                   shelter_coefficient: Airflow.get_default_shelter_coefficient())
    HPXML.add_building_occupancy(hpxml: hpxml,
                                 number_of_residents: Geometry.get_occupancy_default_num(@nbeds))

    HPXML.add_building_construction(hpxml: hpxml,
                                    number_of_conditioned_floors: Integer(@ncfl),
                                    number_of_conditioned_floors_above_grade: Integer(@ncfl_ag),
                                    number_of_bedrooms: Integer(@nbeds),
                                    conditioned_floor_area: @cfa,
                                    conditioned_building_volume: @cvolume,
                                    garage_present: @garage_present)
  end

  def self.set_summary_rated(orig_details, hpxml)
    orig_site = orig_details.elements["BuildingSummary/Site"]
    orig_site_values = HPXML.get_site_values(site: orig_site)
    HPXML.add_site(hpxml: hpxml,
                   fuels: orig_site_values[:fuels],
                   shelter_coefficient: Airflow.get_default_shelter_coefficient())
    HPXML.add_building_occupancy(hpxml: hpxml,
                                 number_of_residents: Geometry.get_occupancy_default_num(@nbeds))
    HPXML.add_building_construction(hpxml: hpxml,
                                    number_of_conditioned_floors: Integer(@ncfl),
                                    number_of_conditioned_floors_above_grade: Integer(@ncfl_ag),
                                    number_of_bedrooms: Integer(@nbeds),
                                    conditioned_floor_area: @cfa,
                                    conditioned_building_volume: @cvolume,
                                    garage_present: @garage_present)
  end

  def self.set_summary_iad(orig_details, hpxml)
    # Table 4.3.1(1) Configuration of Index Adjustment Design - General Characteristics
    @cfa = 2400
    @nbeds = 3
    @ncfl = 2
    @ncfl_ag = 2
    @cvolume = 20400
    @garage_present = false

    orig_site = orig_details.elements["BuildingSummary/Site"]
    orig_site_values = HPXML.get_site_values(site: orig_site)
    HPXML.add_site(hpxml: hpxml,
                   fuels: orig_site_values[:fuels],
                   shelter_coefficient: Airflow.get_default_shelter_coefficient())
    HPXML.add_building_occupancy(hpxml: hpxml,
                                 number_of_residents: Geometry.get_occupancy_default_num(@nbeds))
    HPXML.add_building_construction(hpxml: hpxml,
                                    number_of_conditioned_floors: Integer(@ncfl),
                                    number_of_conditioned_floors_above_grade: Integer(@ncfl_ag),
                                    number_of_bedrooms: Integer(@nbeds),
                                    conditioned_floor_area: @cfa,
                                    conditioned_building_volume: @cvolume,
                                    garage_present: @garage_present)
  end

  def self.set_climate(orig_details, hpxml)
    orig_details.elements.each("ClimateandRiskZones/ClimateZoneIECC") do |orig_climate_zone|
      orig_climate_zone_values = HPXML.get_climate_zone_iecc_values(climate_zone_iecc: orig_climate_zone)
      HPXML.add_climate_zone_iecc(hpxml: hpxml,
                                  year: orig_climate_zone_values[:year],
                                  climate_zone: orig_climate_zone_values[:climate_zone])
    end
    orig_weather_station = orig_details.elements["ClimateandRiskZones/WeatherStation"]
    orig_weather_station_values = HPXML.get_weather_station_values(weather_station: orig_weather_station)
    HPXML.add_weather_station(hpxml: hpxml,
                              id: orig_weather_station_values[:id],
                              name: orig_weather_station_values[:name],
                              wmo: orig_weather_station_values[:wmo])
  end

  def self.set_enclosure_air_infiltration_reference(hpxml)
    # Table 4.2.2(1) - Air exchange rate
    sla = 0.00036

    # Convert to other forms
    nach = Airflow.get_infiltration_ACH_from_SLA(sla, @ncfl_ag, @weather)
    ach50 = Airflow.get_infiltration_ACH50_from_SLA(sla, 0.67, @cfa, @cvolume)

    # nACH
    HPXML.add_air_infiltration_measurement(hpxml: hpxml,
                                           id: "Infiltration_ACHnatural",
                                           unit_of_measure: "ACHnatural",
                                           air_leakage: nach)

    # ACH50
    HPXML.add_air_infiltration_measurement(hpxml: hpxml,
                                           id: "Infiltration_ACH50",
                                           house_pressure: 50,
                                           unit_of_measure: "ACH",
                                           air_leakage: ach50)

    # ELA/SLA
    ela = sla * @cfa
    HPXML.add_air_infiltration_measurement(hpxml: hpxml,
                                           id: "Infiltration_ELA_SLA",
                                           effective_leakage_area: ela)

    HPXML.add_extension(parent: hpxml.elements["Building/BuildingDetails/Enclosure/AirInfiltration"],
                        extensions: { "BuildingSpecificLeakageArea": sla })
  end

  def self.set_enclosure_air_infiltration_rated(orig_details, hpxml)
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
    HPXML.add_air_infiltration_measurement(hpxml: hpxml,
                                           id: "Infiltration_ACHnatural",
                                           unit_of_measure: "ACHnatural",
                                           air_leakage: nach)

    # ACH50
    HPXML.add_air_infiltration_measurement(hpxml: hpxml,
                                           id: "Infiltration_ACH50",
                                           house_pressure: 50,
                                           unit_of_measure: "ACH",
                                           air_leakage: ach50)

    # ELA/SLA
    HPXML.add_air_infiltration_measurement(hpxml: hpxml,
                                           id: "Infiltration_ELA_SLA",
                                           effective_leakage_area: ela)

    HPXML.add_extension(parent: hpxml.elements["Building/BuildingDetails/Enclosure/AirInfiltration"],
                        extensions: { "BuildingSpecificLeakageArea": sla })
  end

  def self.set_enclosure_air_infiltration_iad(hpxml)
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
    HPXML.add_air_infiltration_measurement(hpxml: hpxml,
                                           id: "Infiltration_ACHnatural",
                                           unit_of_measure: "ACHnatural",
                                           air_leakage: nach)

    # ACH50
    HPXML.add_air_infiltration_measurement(hpxml: hpxml,
                                           id: "Infiltration_ACH50",
                                           house_pressure: 50,
                                           unit_of_measure: "ACH",
                                           air_leakage: ach50)

    # ELA/SLA
    ela = sla * @cfa
    HPXML.add_air_infiltration_measurement(hpxml: hpxml,
                                           id: "Infiltration_ELA_SLA",
                                           effective_leakage_area: ela)

    HPXML.add_extension(parent: hpxml.elements["Building/BuildingDetails/Enclosure/AirInfiltration"],
                        extensions: { "BuildingSpecificLeakageArea": sla })
  end

  def self.set_enclosure_attics_roofs_reference(orig_details, hpxml)
    ceiling_ufactor = FloorConstructions.get_default_ceiling_ufactor(@iecc_zone_2006)
    wall_ufactor = WallConstructions.get_default_frame_wall_ufactor(@iecc_zone_2006)

    orig_details.elements.each("Enclosure/Attics/Attic") do |orig_attic|
      orig_attic_values = HPXML.get_attic_values(attic: orig_attic)
      attic_type = orig_attic_values[:attic_type]
      if ['unvented attic', 'vented attic'].include? attic_type
        attic_type = 'vented attic'
      end
      interior_adjacent_to = get_attic_adjacent_to(attic_type)
      new_attic = HPXML.add_attic(hpxml: hpxml,
                                  id: HPXML.get_id(orig_attic),
                                  attic_type: attic_type)

      # Table 4.2.2(1) - Roofs
      orig_attic.elements.each("Roofs/Roof") do |orig_roof|
        orig_roof_values = HPXML.get_roof_values(roof: orig_roof)
        new_roof = HPXML.add_attic_roof(attic: new_attic,
                                        id: orig_roof_values[:id],
                                        area: orig_roof_values[:area],
                                        solar_absorptance: 0.75,
                                        emittance: 0.90,
                                        pitch: orig_roof_values[:pitch],
                                        radiant_barrier: orig_roof_values[:radiant_barrier])
        orig_roof_ins = orig_roof.elements["Insulation"]
        orig_roof_ins_values = HPXML.get_insulation_values(insulation: orig_roof_ins)
        assembly_effective_r_value = orig_roof_ins_values[:assembly_effective_r_value]
        if is_external_thermal_boundary(interior_adjacent_to, "outside")
          assembly_effective_r_value = 1.0 / ceiling_ufactor
        end
        HPXML.add_insulation(parent: new_roof,
                             id: orig_roof_ins_values[:id],
                             assembly_effective_r_value: assembly_effective_r_value)
      end

      # Table 4.2.2(1) - Ceilings
      orig_attic.elements.each("Floors/Floor") do |orig_floor|
        orig_floor_values = HPXML.get_floor_values(floor: orig_floor)
        exterior_adjacent_to = orig_floor_values[:adjacent_to]
        new_floor = HPXML.add_attic_floor(attic: new_attic,
                                          id: orig_floor_values[:id],
                                          adjacent_to: exterior_adjacent_to,
                                          area: orig_floor_values[:area])
        orig_floor_ins = orig_floor.elements["Insulation"]
        orig_floor_ins_values = HPXML.get_insulation_values(insulation: orig_floor_ins)
        assembly_effective_r_value = orig_floor_ins_values[:assembly_effective_r_value]
        if is_external_thermal_boundary(interior_adjacent_to, exterior_adjacent_to)
          assembly_effective_r_value = 1.0 / ceiling_ufactor
        end
        HPXML.add_insulation(parent: new_floor,
                             id: orig_floor_ins_values[:id],
                             assembly_effective_r_value: assembly_effective_r_value)
      end

      # Table 4.2.2(1) - Above-grade walls
      orig_attic.elements.each("Walls/Wall") do |orig_wall|
        orig_wall_values = HPXML.get_wall_values(wall: orig_wall)
        exterior_adjacent_to = orig_wall_values[:adjacent_to]
        new_wall = HPXML.add_attic_wall(attic: new_attic,
                                        id: orig_wall_values[:id],
                                        adjacent_to: exterior_adjacent_to,
                                        wall_type: orig_wall_values[:wall_type],
                                        area: orig_wall_values[:area],
                                        solar_absorptance: orig_wall_values[:solar_absorptance],
                                        emittance: orig_wall_values[:emittance])
        orig_wall_ins = orig_wall.elements["Insulation"]
        orig_wall_ins_values = HPXML.get_insulation_values(insulation: orig_wall_ins)
        assembly_effective_r_value = orig_wall_ins_values[:assembly_effective_r_value]
        if is_external_thermal_boundary(interior_adjacent_to, exterior_adjacent_to)
          assembly_effective_r_value = 1.0 / wall_ufactor
        end
        HPXML.add_insulation(parent: new_wall,
                             id: orig_wall_ins_values[:id],
                             assembly_effective_r_value: assembly_effective_r_value)
      end

      # Table 4.2.2(1) - Attics
      if attic_type == 'vented attic'
        HPXML.add_extension(parent: new_attic,
                            extensions: { "AtticSpecificLeakageArea": Airflow.get_default_vented_attic_sla() })
      end
    end
  end

  def self.set_enclosure_attics_roofs_rated(orig_details, hpxml)
    orig_details.elements.each("Enclosure/Attics/Attic") do |orig_attic|
      orig_attic_values = HPXML.get_attic_values(attic: orig_attic)
      new_attic = HPXML.add_attic(hpxml: hpxml,
                                  id: orig_attic_values[:id],
                                  attic_type: orig_attic_values[:attic_type])

      orig_attic.elements.each("Roofs/Roof") do |orig_roof|
        orig_roof_values = HPXML.get_roof_values(roof: orig_roof)
        new_roof = HPXML.add_attic_roof(attic: new_attic,
                                        id: orig_roof_values[:id],
                                        area: orig_roof_values[:area],
                                        azimuth: orig_roof_values[:azimuth],
                                        solar_absorptance: orig_roof_values[:solar_absorptance],
                                        emittance: orig_roof_values[:emittance],
                                        pitch: orig_roof_values[:pitch],
                                        radiant_barrier: orig_roof_values[:radiant_barrier])
        orig_roof_ins = orig_roof.elements["Insulation"]
        orig_roof_ins_values = HPXML.get_insulation_values(insulation: orig_roof_ins)
        HPXML.add_insulation(parent: new_roof,
                             id: orig_roof_ins_values[:id],
                             assembly_effective_r_value: orig_roof_ins_values[:assembly_effective_r_value])
      end

      orig_attic.elements.each("Floors/Floor") do |orig_floor|
        orig_floor_values = HPXML.get_floor_values(floor: orig_floor)
        new_floor = HPXML.add_attic_floor(attic: new_attic,
                                          id: orig_floor_values[:id],
                                          adjacent_to: orig_floor_values[:adjacent_to],
                                          area: orig_floor_values[:area])
        orig_floor_ins = orig_floor.elements["Insulation"]
        orig_floor_ins_values = HPXML.get_insulation_values(insulation: orig_floor_ins)
        HPXML.add_insulation(parent: new_floor,
                             id: orig_floor_ins_values[:id],
                             assembly_effective_r_value: orig_floor_ins_values[:assembly_effective_r_value])
      end

      orig_attic.elements.each("Walls/Wall") do |orig_wall|
        orig_wall_values = HPXML.get_wall_values(wall: orig_wall)
        new_wall = HPXML.add_attic_wall(attic: new_attic,
                                        id: orig_wall_values[:id],
                                        exterior_adjacent_to: orig_wall_values[:exterior_adjacent_to],
                                        interior_adjacent_to: orig_wall_values[:interior_adjacent_to],
                                        adjacent_to: orig_wall_values[:adjacent_to],
                                        wall_type: orig_wall_values[:wall_type],
                                        area: orig_wall_values[:area],
                                        azimuth: orig_wall_values[:azimuth],
                                        solar_absorptance: orig_wall_values[:solar_absorptance],
                                        emittance: orig_wall_values[:emittance])
        orig_wall_ins = orig_wall.elements["Insulation"]
        orig_wall_ins_values = HPXML.get_insulation_values(insulation: orig_wall_ins)
        HPXML.add_insulation(parent: new_wall,
                             id: orig_wall_ins_values[:id],
                             assembly_effective_r_value: orig_wall_ins_values[:assembly_effective_r_value])
      end
    end
  end

  def self.set_enclosure_attics_roofs_iad(orig_details, hpxml)
    set_enclosure_attics_roofs_rated(orig_details, hpxml)

    new_enclosure = hpxml.elements["Building/BuildingDetails/Enclosure"]
    new_enclosure.elements.each("Attics/Attic") do |new_attic|
      # Table 4.3.1(1) Configuration of Index Adjustment Design - Roofs
      sum_roof_area = 0.0
      new_attic.elements.each("Roofs/Roof") do |new_roof|
        new_roof_values = HPXML.get_roof_values(roof: new_roof)
        sum_roof_area += Float(new_roof_values[:area])
      end
      new_attic.elements.each("Roofs/Roof") do |new_roof|
        new_roof_values = HPXML.get_roof_values(roof: new_roof)
        roof_area = Float(new_roof_values[:area])
        new_roof.elements["Area"].text = 1300.0 * roof_area / sum_roof_area
      end

      # Table 4.3.1(1) Configuration of Index Adjustment Design - Ceilings
      sum_floor_area = 0.0
      new_attic.elements.each("Floors/Floor") do |new_floor|
        new_floor_values = HPXML.get_floor_values(floor: new_floor)
        sum_floor_area += Float(new_floor_values[:area])
      end
      new_attic.elements.each("Floors/Floor") do |new_floor|
        new_floor_values = HPXML.get_floor_values(floor: new_floor)
        floor_area = Float(new_floor_values[:area])
        new_floor.elements["Area"].text = 1200.0 * floor_area / sum_floor_area
      end
    end
  end

  def self.set_enclosure_foundations_reference(orig_details, hpxml)
    floor_ufactor = FloorConstructions.get_default_floor_ufactor(@iecc_zone_2006)
    wall_ufactor = FoundationConstructions.get_default_basement_wall_ufactor(@iecc_zone_2006)
    slab_perim_rvalue, slab_perim_depth = FoundationConstructions.get_default_slab_perimeter_rvalue_depth(@iecc_zone_2006)
    slab_under_rvalue, slab_under_width = FoundationConstructions.get_default_slab_under_rvalue_width()

    orig_details.elements.each("Enclosure/Foundations/Foundation") do |orig_foundation|
      orig_foundation_values = HPXML.get_foundation_values(foundation: orig_foundation)

      foundation_type = orig_foundation_values[:foundation_type]
      if foundation_type == "UnventedCrawlspace"
        foundation_type = "VentedCrawlspace"
      end
      interior_adjacent_to = get_foundation_adjacent_to(orig_foundation.elements["FoundationType"])

      new_foundation = HPXML.add_foundation(hpxml: hpxml,
                                            id: HPXML.get_id(orig_foundation),
                                            foundation_type: foundation_type)

      # Table 4.2.2(1) - Floors over unconditioned spaces or outdoor environment
      orig_foundation.elements.each("FrameFloor") do |orig_floor|
        orig_floor_values = HPXML.get_floor_values(floor: orig_floor)
        exterior_adjacent_to = orig_floor_values[:adjacent_to]
        new_floor = HPXML.add_frame_floor(foundation: new_foundation,
                                          id: orig_floor_values[:id],
                                          adjacent_to: exterior_adjacent_to,
                                          area: orig_floor_values[:area])
        orig_floor_ins = orig_floor.elements["Insulation"]
        orig_floor_ins_values = HPXML.get_insulation_values(insulation: orig_floor_ins)
        assembly_effective_r_value = orig_floor_ins_values[:assembly_effective_r_value]
        if is_external_thermal_boundary(interior_adjacent_to, exterior_adjacent_to)
          assembly_effective_r_value = 1.0 / floor_ufactor
        end
        HPXML.add_insulation(parent: new_floor,
                             id: orig_floor_ins_values[:id],
                             assembly_effective_r_value: assembly_effective_r_value)
      end

      # Table 4.2.2(1) - Conditioned basement walls
      orig_foundation.elements.each("FoundationWall") do |orig_fwall|
        orig_fwall_values = HPXML.get_foundation_wall_values(foundation_wall: orig_fwall)
        exterior_adjacent_to = orig_fwall_values[:adjacent_to]
        new_wall = HPXML.add_foundation_wall(foundation: new_foundation,
                                             id: orig_fwall_values[:id],
                                             height: orig_fwall_values[:height],
                                             area: orig_fwall_values[:area],
                                             thickness: orig_fwall_values[:thickness],
                                             depth_below_grade: orig_fwall_values[:depth_below_grade],
                                             adjacent_to: exterior_adjacent_to)
        orig_fwall_ins = orig_fwall.elements["Insulation"]
        orig_fwall_ins_values = HPXML.get_insulation_values(insulation: orig_fwall_ins)
        assembly_effective_r_value = orig_fwall_ins_values[:assembly_effective_r_value]
        # TODO: Can this just be is_external_thermal_boundary(interior_adjacent_to, exterior_adjacent_to)?
        if interior_adjacent_to == "basement - conditioned" and is_external_thermal_boundary(interior_adjacent_to, exterior_adjacent_to)
          assembly_effective_r_value = 1.0 / wall_ufactor
        end
        HPXML.add_insulation(parent: new_wall,
                             id: orig_fwall_ins_values[:id],
                             assembly_effective_r_value: assembly_effective_r_value)
      end

      # Table 4.2.2(1) - Foundations
      orig_foundation.elements.each("Slab") do |orig_slab|
        orig_slab_values = HPXML.get_slab_values(slab: orig_slab)
        orig_perim_ins = orig_slab.elements["PerimeterInsulation"]
        orig_under_ins = orig_slab.elements["UnderSlabInsulation"]
        # TODO: Can this just be is_external_thermal_boundary(interior_adjacent_to, "ground")?
        if not ( interior_adjacent_to == "living space" and is_external_thermal_boundary(interior_adjacent_to, "ground"))
          slab_perim_depth = orig_slab_values[:perimeter_insulation_depth]
          slab_under_width = orig_slab_values[:under_slab_insulation_width]
          perim_ins_layer = orig_perim_ins.elements["Layer"]
          perim_ins_layer_values = HPXML.get_layer_values(layer: perim_ins_layer)
          slab_perim_rvalue = perim_ins_layer_values[:nominal_r_value]
          under_ins_layer = orig_under_ins.elements["Layer"]
          under_ins_layer_values = HPXML.get_layer_values(layer: under_ins_layer)
          slab_under_rvalue = under_ins_layer_values[:nominal_r_value]
        end
        new_slab = HPXML.add_slab(foundation: new_foundation,
                                  id: orig_slab_values[:id],
                                  area: orig_slab_values[:area],
                                  thickness: orig_slab_values[:thickness],
                                  exposed_perimeter: orig_slab_values[:exposed_perimeter],
                                  perimeter_insulation_depth: slab_perim_depth,
                                  under_slab_insulation_width: slab_under_width,
                                  depth_below_grade: orig_slab_values[:depth_below_grade])
        perim_ins = HPXML.add_perimeter_insulation(slab: new_slab,
                                                   id: HPXML.get_id(orig_perim_ins))
        HPXML.add_layer(insulation: perim_ins,
                        installation_type: "continuous",
                        nominal_r_value: slab_perim_rvalue)
        under_ins = HPXML.add_under_slab_insulation(slab: new_slab,
                                                    id: HPXML.get_id(orig_under_ins))
        HPXML.add_layer(insulation: under_ins,
                        installation_type: "continuous",
                        nominal_r_value: slab_under_rvalue)
        HPXML.add_extension(parent: new_slab,
                            extensions: { "CarpetFraction": 0.8,
                                          "CarpetRValue": 2.0 })
      end

      # Table 4.2.2(1) - Crawlspaces
      if foundation_type == "VentedCrawlspace"
        HPXML.add_extension(parent: new_foundation,
                            extensions: { "CrawlspaceSpecificLeakageArea": Airflow.get_default_vented_crawl_sla() })
      end
    end
  end

  def self.set_enclosure_foundations_rated(orig_details, hpxml)
    min_crawl_vent = Airflow.get_default_vented_crawl_sla() # Reference Home vent

    orig_details.elements.each("Enclosure/Foundations/Foundation") do |orig_foundation|
      orig_foundation_values = HPXML.get_foundation_values(foundation: orig_foundation)

      foundation_type = orig_foundation_values[:foundation_type]
      if foundation_type == "VentedCrawlspace"
        # Table 4.2.2(1) - Crawlspaces
        vent = Float(orig_foundation_values[:crawlspace_specific_leakage_area])
        # TODO: Handle approved ground cover
        if vent < min_crawl_vent
          vent = min_crawl_vent
        end
      end

      new_foundation = HPXML.add_foundation(hpxml: hpxml,
                                            id: orig_foundation_values[:id],
                                            foundation_type: foundation_type)

      orig_foundation.elements.each("FrameFloor") do |orig_floor|
        orig_floor_values = HPXML.get_floor_values(floor: orig_floor)
        new_floor = HPXML.add_frame_floor(foundation: new_foundation,
                                          id: orig_floor_values[:id],
                                          adjacent_to: orig_floor_values[:adjacent_to],
                                          area: orig_floor_values[:area])
        orig_floor_ins = orig_floor.elements["Insulation"]
        orig_floor_ins_values = HPXML.get_insulation_values(insulation: orig_floor_ins)
        HPXML.add_insulation(parent: new_floor,
                             id: orig_floor_ins_values[:id],
                             assembly_effective_r_value: orig_floor_ins_values[:assembly_effective_r_value])
      end

      orig_foundation.elements.each("FoundationWall") do |orig_fwall|
        orig_fwall_values = HPXML.get_foundation_wall_values(foundation_wall: orig_fwall)
        new_wall = HPXML.add_foundation_wall(foundation: new_foundation,
                                             id: orig_fwall_values[:id],
                                             height: orig_fwall_values[:height],
                                             area: orig_fwall_values[:area],
                                             thickness: orig_fwall_values[:thickness],
                                             depth_below_grade: orig_fwall_values[:depth_below_grade],
                                             adjacent_to: orig_fwall_values[:adjacent_to])
        orig_fwall_ins = orig_fwall.elements["Insulation"]
        orig_fwall_ins_values = HPXML.get_insulation_values(insulation: orig_fwall_ins)
        HPXML.add_insulation(parent: new_wall,
                             id: orig_fwall_ins_values[:id],
                             assembly_effective_r_value: orig_fwall_ins_values[:assembly_effective_r_value])
      end

      orig_foundation.elements.each("Slab") do |orig_slab|
        orig_slab_values = HPXML.get_slab_values(slab: orig_slab)
        orig_perim_ins = orig_slab.elements["PerimeterInsulation"]
        orig_under_ins = orig_slab.elements["UnderSlabInsulation"]
        perim_ins_layer = orig_perim_ins.elements["Layer"]
        perim_ins_layer_values = HPXML.get_layer_values(layer: perim_ins_layer)
        under_ins_layer = orig_under_ins.elements["Layer"]
        under_ins_layer_values = HPXML.get_layer_values(layer: under_ins_layer)
        new_slab = HPXML.add_slab(foundation: new_foundation,
                                  id: orig_slab_values[:id],
                                  area: orig_slab_values[:area],
                                  thickness: orig_slab_values[:thickness],
                                  exposed_perimeter: orig_slab_values[:exposed_perimeter],
                                  perimeter_insulation_depth: orig_slab_values[:perimeter_insulation_depth],
                                  under_slab_insulation_width: orig_slab_values[:under_slab_insulation_width],
                                  depth_below_grade: orig_slab_values[:depth_below_grade])
        perim_ins = HPXML.add_perimeter_insulation(slab: new_slab,
                                                   id: HPXML.get_id(orig_perim_ins))
        HPXML.add_layer(insulation: perim_ins,
                        installation_type: "continuous",
                        nominal_r_value: perim_ins_layer_values[:nominal_r_value])
        under_ins = HPXML.add_under_slab_insulation(slab: new_slab,
                                                    id: HPXML.get_id(orig_under_ins))
        HPXML.add_layer(insulation: under_ins,
                        installation_type: "continuous",
                        nominal_r_value: under_ins_layer_values[:nominal_r_value])
        HPXML.add_extension(parent: new_slab,
                            extensions: { "CarpetFraction": orig_slab_values[:carpet_fraction],
                                          "CarpetRValue": orig_slab_values[:carpet_r_value] })
      end
      HPXML.add_extension(parent: new_foundation,
                          extensions: { "CrawlspaceSpecificLeakageArea": vent })
    end
  end

  def self.set_enclosure_foundations_iad(hpxml)
    # Table 4.3.1(1) Configuration of Index Adjustment Design - Foundation
    floor_ufactor = FloorConstructions.get_default_floor_ufactor(@iecc_zone_2006)

    new_foundation = HPXML.add_foundation(hpxml: hpxml,
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
                        extensions: { "CarpetFraction": 0,
                                      "CarpetRValue": 0 })
    HPXML.add_extension(parent: new_foundation,
                        extensions: { "CrawlspaceSpecificLeakageArea": Airflow.get_default_vented_crawl_sla() })
  end

  def self.set_enclosure_rim_joists_reference(orig_details, hpxml)
    return if not XMLHelper.has_element(orig_details, "Enclosure/RimJoists")

    # Table 4.2.2(1) - Above-grade walls
    ufactor = WallConstructions.get_default_frame_wall_ufactor(@iecc_zone_2006)

    orig_details.elements.each("Enclosure/RimJoists/RimJoist") do |orig_rim_joist|
      orig_rim_joist_values = HPXML.get_rim_joist_values(rim_joist: orig_rim_joist)
      interior_adjacent_to = orig_rim_joist_values[:interior_adjacent_to]
      exterior_adjacent_to = orig_rim_joist_values[:exterior_adjacent_to]
      new_rim_joist = HPXML.add_rim_joist(hpxml: hpxml,
                                          id: orig_rim_joist_values[:id],
                                          exterior_adjacent_to: exterior_adjacent_to,
                                          interior_adjacent_to: interior_adjacent_to,
                                          area: orig_rim_joist_values[:area])
      orig_rim_joist_ins = orig_rim_joist.elements["Insulation"]
      orig_rim_joist_ins_values = HPXML.get_insulation_values(insulation: orig_rim_joist_ins)
      assembly_effective_r_value = orig_rim_joist_ins_values[:assembly_effective_r_value]
      if is_external_thermal_boundary(interior_adjacent_to, exterior_adjacent_to)
        assembly_effective_r_value = 1.0 / ufactor
      end
      HPXML.add_insulation(parent: new_rim_joist,
                           id: HPXML.get_id(orig_rim_joist_ins),
                           assembly_effective_r_value: assembly_effective_r_value)
    end
  end

  def self.set_enclosure_rim_joists_rated(orig_details, hpxml)
    return if not XMLHelper.has_element(orig_details, "Enclosure/RimJoists")

    orig_details.elements.each("Enclosure/RimJoists/RimJoist") do |orig_rim_joist|
      orig_rim_joist_values = HPXML.get_rim_joist_values(rim_joist: orig_rim_joist)
      interior_adjacent_to = orig_rim_joist_values[:interior_adjacent_to]
      exterior_adjacent_to = orig_rim_joist_values[:exterior_adjacent_to]
      new_rim_joist = HPXML.add_rim_joist(hpxml: hpxml,
                                          id: orig_rim_joist_values[:id],
                                          exterior_adjacent_to: exterior_adjacent_to,
                                          interior_adjacent_to: interior_adjacent_to,
                                          area: orig_rim_joist_values[:area])
      orig_rim_joist_ins = orig_rim_joist.elements["Insulation"]
      orig_rim_joist_ins_values = HPXML.get_insulation_values(insulation: orig_rim_joist_ins)
      HPXML.add_insulation(parent: new_rim_joist,
                           id: orig_rim_joist_ins_values[:id],
                           assembly_effective_r_value: orig_rim_joist_ins_values[:assembly_effective_r_value])
    end

    # Table 4.2.2(1) - Above-grade walls
    # nop
  end

  def self.get_iad_sum_external_wall_area(orig_walls, orig_rim_joists)
    sum_wall_area = 0.0

    orig_walls.elements.each("Wall") do |orig_wall|
      orig_wall_values = HPXML.get_wall_values(wall: orig_wall)
      interior_adjacent_to = orig_wall_values[:interior_adjacent_to]
      exterior_adjacent_to = orig_wall_values[:exterior_adjacent_to]
      if is_external_thermal_boundary(interior_adjacent_to, exterior_adjacent_to)
        sum_wall_area += Float(orig_wall_values[:area])
      end
    end

    if not orig_rim_joists.nil?
      orig_rim_joists.elements.each("RimJoist") do |orig_rim_joist|
        orig_rim_joist_values = HPXML.get_rim_joist_values(rim_joist: orig_rim_joist)
        interior_adjacent_to = orig_rim_joist_values[:interior_adjacent_to]
        if ["basement - unconditioned", "basement - conditioned"].include? interior_adjacent_to
          # IAD home has crawlspace
          interior_adjacent_to = "crawlspace - vented"
        end
        exterior_adjacent_to = orig_rim_joist_values[:exterior_adjacent_to]
        if is_external_thermal_boundary(interior_adjacent_to, exterior_adjacent_to)
          sum_wall_area += Float(orig_rim_joist_values[:area])
        end
      end
    end

    return sum_wall_area
  end

  def self.set_enclosure_rim_joists_iad(orig_details, hpxml)
    # Table 4.3.1(1) Configuration of Index Adjustment Design - Above-grade walls
    set_enclosure_rim_joists_rated(orig_details, hpxml)

    orig_rim_joists = orig_details.elements["Enclosure/RimJoists"]
    return if orig_rim_joists.nil?

    orig_walls = orig_details.elements["Enclosure/Walls"]

    sum_wall_area = get_iad_sum_external_wall_area(orig_walls, orig_rim_joists)

    new_rim_joists = hpxml.elements["Building/BuildingDetails/Enclosure/RimJoists"]
    new_rim_joists.elements.each("RimJoist") do |new_rim_joist|
      new_rim_joist_values = HPXML.get_rim_joist_values(rim_joist: new_rim_joist)
      interior_adjacent_to = new_rim_joist_values[:interior_adjacent_to]
      if ["basement - unconditioned", "basement - conditioned"].include? interior_adjacent_to
        # IAD home has crawlspace
        interior_adjacent_to = "crawlspace - vented"
        new_rim_joist.elements["InteriorAdjacentTo"].text = interior_adjacent_to
      end
      exterior_adjacent_to = new_rim_joist_values[:exterior_adjacent_to]
      if is_external_thermal_boundary(interior_adjacent_to, exterior_adjacent_to)
        rim_joist_area = Float(new_rim_joist_values[:area])
        new_rim_joist.elements["Area"].text = 2360.0 * rim_joist_area / sum_wall_area
      end
    end
  end

  def self.set_enclosure_walls_reference(orig_details, hpxml)
    # Table 4.2.2(1) - Above-grade walls
    ufactor = WallConstructions.get_default_frame_wall_ufactor(@iecc_zone_2006)

    orig_details.elements.each("Enclosure/Walls/Wall") do |orig_wall|
      orig_wall_values = HPXML.get_wall_values(wall: orig_wall)
      exterior_adjacent_to = orig_wall_values[:exterior_adjacent_to]
      interior_adjacent_to = orig_wall_values[:interior_adjacent_to]
      solar_absorptance = orig_wall_values[:solar_absorptance]
      emittance = orig_wall_values[:emittance]
      orig_wall_ins = orig_wall.elements["Insulation"]
      orig_wall_ins_values = HPXML.get_insulation_values(insulation: orig_wall_ins)
      assembly_effective_r_value = orig_wall_ins_values[:assembly_effective_r_value]
      if is_external_thermal_boundary(interior_adjacent_to, exterior_adjacent_to)
        solar_absorptance = 0.75
        emittance = 0.90
        assembly_effective_r_value = 1.0 / ufactor
      end
      new_wall = HPXML.add_wall(hpxml: hpxml,
                                id: orig_wall_values[:id],
                                exterior_adjacent_to: exterior_adjacent_to,
                                interior_adjacent_to: interior_adjacent_to,
                                wall_type: orig_wall_values[:wall_type],
                                area: orig_wall_values[:area],
                                azimuth: orig_wall_values[:azimuth],
                                solar_absorptance: solar_absorptance,
                                emittance: emittance)
      HPXML.add_insulation(parent: new_wall,
                           id: orig_wall_ins_values[:id],
                           assembly_effective_r_value: assembly_effective_r_value)
    end
  end

  def self.set_enclosure_walls_rated(orig_details, hpxml)
    orig_details.elements.each("Enclosure/Walls/Wall") do |orig_wall|
      orig_wall_values = HPXML.get_wall_values(wall: orig_wall)
      new_wall = HPXML.add_wall(hpxml: hpxml,
                                id: orig_wall_values[:id],
                                exterior_adjacent_to: orig_wall_values[:exterior_adjacent_to],
                                interior_adjacent_to: orig_wall_values[:interior_adjacent_to],
                                wall_type: orig_wall_values[:wall_type],
                                area: orig_wall_values[:area],
                                azimuth: orig_wall_values[:azimuth],
                                solar_absorptance: orig_wall_values[:solar_absorptance],
                                emittance: orig_wall_values[:emittance])
      orig_wall_ins = orig_wall.elements["Insulation"]
      orig_wall_ins_values = HPXML.get_insulation_values(insulation: orig_wall_ins)
      HPXML.add_insulation(parent: new_wall,
                           id: orig_wall_ins_values[:id],
                           assembly_effective_r_value: orig_wall_ins_values[:assembly_effective_r_value])
    end

    # Table 4.2.2(1) - Above-grade walls
    # nop
  end

  def self.set_enclosure_walls_iad(orig_details, hpxml)
    # Table 4.3.1(1) Configuration of Index Adjustment Design - Above-grade walls
    set_enclosure_walls_rated(orig_details, hpxml)

    orig_walls = orig_details.elements["Enclosure/Walls"]
    orig_rim_joists = orig_details.elements["Enclosure/RimJoists"]

    sum_wall_area = get_iad_sum_external_wall_area(orig_walls, orig_rim_joists)

    new_walls = hpxml.elements["Building/BuildingDetails/Enclosure/Walls"]
    new_walls.elements.each("Wall") do |new_wall|
      new_wall_values = HPXML.get_wall_values(wall: new_wall)
      interior_adjacent_to = new_wall_values[:interior_adjacent_to]
      exterior_adjacent_to = new_wall_values[:exterior_adjacent_to]
      if is_external_thermal_boundary(interior_adjacent_to, exterior_adjacent_to)
        wall_area = Float(new_wall_values[:area])
        new_wall.elements["Area"].text = 2360.0 * wall_area / sum_wall_area
      end
    end
  end

  def self.set_enclosure_windows_reference(orig_details, hpxml)
    # Table 4.2.2(1) - Glazing
    ufactor, shgc = SubsurfaceConstructions.get_default_ufactor_shgc(@iecc_zone_2006)

    ag_wall_area = 0.0
    bg_wall_area = 0.0

    orig_details.elements.each("Enclosure/Walls/Wall") do |orig_wall|
      orig_wall = HPXML.get_wall_values(wall: orig_wall)
      int_adj_to = orig_wall[:interior_adjacent_to]
      ext_adj_to = orig_wall[:exterior_adjacent_to]
      next if not ((int_adj_to == "living space" or ext_adj_to == "living space") and int_adj_to != ext_adj_to)

      area = Float(orig_wall[:area])
      ag_wall_area += area
    end

    orig_details.elements.each("Enclosure/Foundations/Foundation[FoundationType/Basement/Conditioned='true']/FoundationWall") do |orig_fwall|
      orig_fwall_values = HPXML.get_foundation_wall_values(foundation_wall: orig_fwall)
      adj_to = orig_fwall_values[:adjacent_to]
      next if adj_to == "living space"

      height = Float(orig_fwall_values[:height])
      bg_depth = Float(orig_fwall_values[:depth_below_grade])
      area = Float(orig_fwall_values[:area])
      ag_wall_area += (height - bg_depth) / height * area
      bg_wall_area += bg_depth / height * area
    end

    fa = ag_wall_area / (ag_wall_area + 0.5 * bg_wall_area)
    f = 1.0 # TODO

    total_window_area = 0.18 * @cfa * fa * f

    wall_area_fracs = get_exterior_wall_area_fracs(orig_details)

    # Create new windows
    for orientation, azimuth in { "north" => 0, "south" => 180, "east" => 90, "west" => 270 }
      window_area = 0.25 * total_window_area # Equal distribution to N/S/E/W
      # Distribute this orientation's window area proportionally across all exterior walls
      wall_area_fracs.each do |wall, wall_area_frac|
        wall_id = HPXML.get_id(wall)
        new_window = HPXML.add_window(hpxml: hpxml,
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
                        extensions: { "InteriorShadingFactorSummer": shade_summer,
                                      "InteriorShadingFactorWinter": shade_winter })
  end

  def self.set_enclosure_windows_rated(orig_details, hpxml)
    # Table 4.2.2(1) - Glazing
    orig_details.elements.each("Enclosure/Windows/Window") do |orig_window|
      orig_window_values = HPXML.get_window_values(window: orig_window)
      new_window = HPXML.add_window(hpxml: hpxml,
                                    id: orig_window_values[:id],
                                    area: orig_window_values[:area],
                                    azimuth: orig_window_values[:azimuth],
                                    ufactor: orig_window_values[:ufactor],
                                    shgc: orig_window_values[:shgc],
                                    overhangs_depth: orig_window_values[:overhangs_depth],
                                    overhangs_distance_to_top_of_window: orig_window_values[:overhangs_distance_to_top_of_window],
                                    overhangs_distance_to_bottom_of_window: orig_window_values[:overhangs_distance_to_bottom_of_window],
                                    idref: orig_window_values[:idref])

      set_window_interior_shading_reference(new_window)
    end
  end

  def self.set_enclosure_windows_iad(orig_details, hpxml)
    # Table 4.3.1(1) Configuration of Index Adjustment Design - Glazing
    set_enclosure_windows_reference(orig_details, hpxml)

    new_windows = hpxml.elements["Building/BuildingDetails/Enclosure/Windows"]

    # Calculate area-weighted averages
    sum_u_a = 0.0
    sum_shgc_a = 0.0
    sum_a = 0.0
    new_windows.elements.each("Window") do |new_window|
      new_window_values = HPXML.get_window_values(window: new_window)
      window_area = Float(new_window_values[:area])
      sum_a += window_area
      sum_u_a += (window_area * Float(new_window_values[:ufactor]))
      sum_shgc_a += (window_area * Float(new_window_values[:shgc]))
    end
    avg_u = sum_u_a / sum_a
    avg_shgc = sum_shgc_a / sum_a

    new_windows.elements.each("Window") do |new_window|
      new_window.elements["UFactor"].text = avg_u
      new_window.elements["SHGC"].text = avg_shgc
    end
  end

  def self.set_enclosure_skylights_reference(hpxml)
    # Table 4.2.2(1) - Skylights
    # nop
  end

  def self.set_enclosure_skylights_rated(orig_details, hpxml)
    return if not XMLHelper.has_element(orig_details, "Enclosure/Skylights")

    # Table 4.2.2(1) - Skylights
    orig_details.elements.each("Enclosure/Skylights/Skylight") do |orig_skylight|
      orig_skylight_values = HPXML.get_skylight_values(skylight: orig_skylight)
      new_skylight = HPXML.add_skylight(hpxml: hpxml,
                                        id: orig_skylight_values[:id],
                                        area: orig_skylight_values[:area],
                                        azimuth: orig_skylight_values[:azimuth],
                                        ufactor: orig_skylight_values[:ufactor],
                                        shgc: orig_skylight_values[:shgc],
                                        idref: orig_skylight_values[:idref])
    end
  end

  def self.set_enclosure_skylights_iad(orig_details, hpxml)
    # Table 4.3.1(1) Configuration of Index Adjustment Design - Skylights
    set_enclosure_skylights_rated(orig_details, hpxml)
  end

  def self.set_enclosure_doors_reference(orig_details, hpxml)
    # Table 4.2.2(1) - Doors
    ufactor, shgc = SubsurfaceConstructions.get_default_ufactor_shgc(@iecc_zone_2006)
    door_area = SubsurfaceConstructions.get_default_door_area()

    wall_area_fracs = get_exterior_wall_area_fracs(orig_details)

    # Create new doors
    # Distribute door area proportionally across all exterior walls
    wall_area_fracs.each do |wall, wall_area_frac|
      wall_id = HPXML.get_id(wall)

      new_door = HPXML.add_door(hpxml: hpxml,
                                id: "Door_#{wall_id}",
                                idref: wall_id,
                                area: door_area * wall_area_frac,
                                azimuth: 0,
                                r_value: 1.0 / ufactor)
    end
  end

  def self.set_enclosure_doors_rated(orig_details, hpxml)
    # Table 4.2.2(1) - Doors
    orig_details.elements.each("Enclosure/Doors/Door") do |orig_door|
      orig_door_values = HPXML.get_door_values(door: orig_door)
      new_door = HPXML.add_door(hpxml: hpxml,
                                id: orig_door_values[:id],
                                idref: orig_door_values[:idref],
                                area: orig_door_values[:area],
                                azimuth: orig_door_values[:azimuth],
                                r_value: orig_door_values[:r_value])
    end
  end

  def self.set_enclosure_doors_iad(orig_details, hpxml)
    # Table 4.3.1(1) Configuration of Index Adjustment Design - Doors
    set_enclosure_doors_rated(orig_details, hpxml)
  end

  def self.set_systems_hvac_reference(orig_details, hpxml)
    # Table 4.2.2(1) - Heating systems
    # Table 4.2.2(1) - Cooling systems

    has_fuel = has_fuel_access(orig_details)

    # Heating
    orig_details.elements.each("Systems/HVAC/HVACPlant/HeatingSystem") do |orig_heating|
      orig_heating_values = HPXML.get_heating_system_values(heating_system: orig_heating)
      next unless orig_heating_values[:heating_system_fuel] != "electricity"

      if XMLHelper.has_element(orig_heating, "HeatingSystemType/Boiler")
        add_reference_heating_gas_boiler(hpxml, Float(orig_heating_values[:fraction_heat_load_served]), orig_heating_values[:id])
      else
        add_reference_heating_gas_furnace(hpxml, Float(orig_heating_values[:fraction_heat_load_served]), orig_heating_values[:id])
      end
    end
    if orig_details.elements["Systems/HVAC/HVACPlant/HeatingSystem"].nil? and orig_details.elements["Systems/HVAC/HVACPlant/HeatPump[FractionHeatLoadServed > 0]"].nil?
      if has_fuel
        add_reference_heating_gas_furnace(hpxml)
      end
    end

    # Cooling
    orig_details.elements.each("Systems/HVAC/HVACPlant/CoolingSystem") do |orig_cooling|
      orig_cooling_values = HPXML.get_cooling_system_values(cooling_system: orig_cooling)
      add_reference_cooling_air_conditioner(hpxml, Float(orig_cooling_values[:fraction_cool_load_served]), orig_cooling_values[:id])
    end
    orig_details.elements.each("Systems/HVAC/HVACPlant/HeatPump[FractionCoolLoadServed > 0]") do |orig_hp|
      orig_hp_values = HPXML.get_heat_pump_values(heat_pump: orig_hp)
      add_reference_cooling_air_conditioner(hpxml, orig_hp_values[:fraction_cool_load_served], orig_hp_values[:id])
    end
    if orig_details.elements["Systems/HVAC/HVACPlant/CoolingSystem"].nil? and orig_details.elements["Systems/HVAC/HVACPlant/HeatPump[FractionCoolLoadServed > 0]"].nil?
      add_reference_cooling_air_conditioner(hpxml)
    end

    # HeatPump
    orig_details.elements.each("Systems/HVAC/HVACPlant/HeatingSystem") do |orig_heating|
      orig_heating_values = HPXML.get_heating_system_values(heating_system: orig_heating)
      next unless orig_heating_values[:heating_system_fuel] == "electricity"

      add_reference_heating_heat_pump(hpxml, orig_heating_values[:fraction_heat_load_served], orig_heating_values[:id])
    end
    orig_details.elements.each("Systems/HVAC/HVACPlant/HeatPump[FractionHeatLoadServed > 0]") do |orig_hp|
      orig_hp_values = HPXML.get_heat_pump_values(heat_pump: orig_hp)
      add_reference_heating_heat_pump(hpxml, orig_hp_values[:fraction_heat_load_served], orig_hp_values[:id])
    end
    if orig_details.elements["Systems/HVAC/HVACPlant/HeatingSystem"].nil? and orig_details.elements["Systems/HVAC/HVACPlant/HeatPump[FractionHeatLoadServed > 0]"].nil?
      if not has_fuel
        add_reference_heating_heat_pump(hpxml)
      end
    end

    # Table 303.4.1(1) - Thermostat
    new_hvac_control = HPXML.add_hvac_control(hpxml: hpxml,
                                              id: "HVACControl",
                                              control_type: "manual thermostat")

    # Distribution system
    add_reference_distribution_system(hpxml)
  end

  def self.set_systems_hvac_rated(orig_details, hpxml)
    # Table 4.2.2(1) - Heating systems
    # Table 4.2.2(1) - Cooling systems

    heating_system = orig_details.elements["Systems/HVAC/HVACPlant/HeatingSystem"]
    heat_pump = orig_details.elements["Systems/HVAC/HVACPlant/HeatPump"]
    cooling_system = orig_details.elements["Systems/HVAC/HVACPlant/CoolingSystem"]

    # Heating
    added_reference_heating = false
    if not heating_system.nil?
      # Retain heating system(s)
      orig_details.elements.each("Systems/HVAC/HVACPlant/HeatingSystem") do |orig_heating|
        orig_heating_values = HPXML.get_heating_system_values(heating_system: orig_heating)
        heat_sys = HPXML.add_heating_system(hpxml: hpxml,
                                            id: orig_heating_values[:id],
                                            idref: orig_heating_values[:idref],
                                            heating_system_type: orig_heating_values[:heating_system_type],
                                            heating_system_fuel: orig_heating_values[:heating_system_fuel],
                                            heating_capacity: orig_heating_values[:heating_capacity],
                                            annual_heating_efficiency_units: orig_heating_values[:annual_heating_efficiency_units],
                                            annual_heating_efficiency_value: orig_heating_values[:annual_heating_efficiency_value],
                                            fraction_heat_load_served: orig_heating_values[:fraction_heat_load_served])
      end
    end
    if heating_system.nil? and heat_pump.nil? and has_fuel_access(orig_details)
      add_reference_heating_gas_furnace(hpxml)
      added_reference_heating = true
    end

    # Cooling
    added_reference_cooling = false
    if not cooling_system.nil?
      # Retain cooling system(s)
      orig_details.elements.each("Systems/HVAC/HVACPlant/CoolingSystem") do |orig_cooling|
        orig_cooling_values = HPXML.get_cooling_system_values(cooling_system: orig_cooling)
        cool_sys = HPXML.add_cooling_system(hpxml: hpxml,
                                            id: orig_cooling_values[:id],
                                            idref: orig_cooling_values[:idref],
                                            cooling_system_type: orig_cooling_values[:cooling_system_type],
                                            cooling_system_fuel: orig_cooling_values[:cooling_system_fuel],
                                            cooling_capacity: orig_cooling_values[:cooling_capacity],
                                            fraction_cool_load_served: orig_cooling_values[:fraction_cool_load_served],
                                            annual_cooling_efficiency_units: orig_cooling_values[:annual_cooling_efficiency_units],
                                            annual_cooling_efficiency_value: orig_cooling_values[:annual_cooling_efficiency_value])
      end
    end
    if cooling_system.nil? and heat_pump.nil?
      add_reference_cooling_air_conditioner(hpxml)
      added_reference_cooling = true
    end

    # HeatPump
    if not heat_pump.nil?
      # Retain heat pump(s)
      orig_details.elements.each("Systems/HVAC/HVACPlant/HeatPump") do |orig_hp|
        orig_hp_values = HPXML.get_heat_pump_values(heat_pump: orig_hp)
        heat_pump = HPXML.add_heat_pump(hpxml: hpxml,
                                        id: orig_hp_values[:id],
                                        idref: orig_hp_values[:idref],
                                        heat_pump_type: orig_hp_values[:heat_pump_type],
                                        heat_pump_fuel: orig_hp_values[:heat_pump_fuel],
                                        heating_capacity: orig_hp_values[:heating_capacity],
                                        cooling_capacity: orig_hp_values[:cooling_capacity],
                                        fraction_heat_load_served: orig_hp_values[:fraction_heat_load_served],
                                        fraction_cool_load_served: orig_hp_values[:fraction_cool_load_served],
                                        annual_heating_efficiency_units: orig_hp_values[:annual_heating_efficiency_units],
                                        annual_heating_efficiency_value: orig_hp_values[:annual_heating_efficiency_value],
                                        annual_cooling_efficiency_units: orig_hp_values[:annual_cooling_efficiency_units],
                                        annual_cooling_efficiency_value: orig_hp_values[:annual_cooling_efficiency_value])
      end
    end
    if heating_system.nil? and heat_pump.nil? and not has_fuel_access(orig_details)
      add_reference_heating_heat_pump(hpxml)
      added_reference_heating = true
    end

    # Table 303.4.1(1) - Thermostat
    if not orig_details.elements["Systems/HVAC/HVACControl"].nil?
      orig_hvac_control = orig_details.elements["Systems/HVAC/HVACControl"]
      orig_hvac_control_values = HPXML.get_hvac_control_values(hvac_control: orig_hvac_control)
      new_hvac_control = HPXML.add_hvac_control(hpxml: hpxml,
                                                id: orig_hvac_control_values[:id],
                                                control_type: orig_hvac_control_values[:control_type])
    else
      new_hvac_control = HPXML.add_hvac_control(hpxml: hpxml,
                                                id: "HVACControl",
                                                control_type: "manual thermostat")
    end

    # Table 4.2.2(1) - Thermal distribution systems
    orig_details.elements.each("Systems/HVAC/HVACDistribution") do |orig_dist|
      orig_dist_values = HPXML.get_hvac_distribution_values(hvac_distribution: orig_dist)
      new_hvac_dist = HPXML.add_hvac_distribution(hpxml: hpxml,
                                                  id: orig_dist_values[:id],
                                                  distribution_system_type: orig_dist_values[:distribution_system_type],
                                                  annual_heating_distribution_system_efficiency: orig_dist_values[:annual_heating_distribution_system_efficiency],
                                                  annual_cooling_distribution_system_efficiency: orig_dist_values[:annual_cooling_distribution_system_efficiency])
      if orig_dist_values[:distribution_system_type] == "AirDistribution"
        new_air_dist = new_hvac_dist.elements["DistributionSystemType/AirDistribution"]
        orig_dist.elements.each("DistributionSystemType/AirDistribution/DuctLeakageMeasurement") do |orig_duct_leakage_measurement|
          orig_duct_leakage_measurement_values = HPXML.get_duct_leakage_measurement_values(duct_leakage_measurement: orig_duct_leakage_measurement)
          HPXML.add_duct_leakage_measurement(air_distribution: new_air_dist,
                                             duct_type: orig_duct_leakage_measurement_values[:duct_type],
                                             duct_leakage_units: orig_duct_leakage_measurement_values[:duct_leakage_units],
                                             duct_leakage_value: orig_duct_leakage_measurement_values[:duct_leakage_value],
                                             duct_leakage_total_or_to_outside: orig_duct_leakage_measurement_values[:duct_leakage_total_or_to_outside])
        end
        orig_dist.elements.each("DistributionSystemType/AirDistribution/Ducts") do |orig_ducts|
          orig_ducts_values = HPXML.get_ducts_values(ducts: orig_ducts)
          HPXML.add_ducts(air_distribution: new_air_dist,
                          duct_type: orig_ducts_values[:duct_type],
                          duct_insulation_r_value: orig_ducts_values[:duct_insulation_r_value],
                          duct_location: orig_ducts_values[:duct_location],
                          duct_surface_area: orig_ducts_values[:duct_surface_area])
        end
      end
    end
    if added_reference_heating or added_reference_cooling
      # Add DSE distribution for these systems
      add_reference_distribution_system(hpxml)
    end
  end

  def self.set_systems_hvac_iad(orig_details, hpxml)
    # Table 4.3.1(1) Configuration of Index Adjustment Design - Heating systems
    # Table 4.3.1(1) Configuration of Index Adjustment Design - Cooling systems
    # Table 4.3.1(1) Configuration of Index Adjustment Design - Thermostat
    set_systems_hvac_reference(orig_details, hpxml)

    # Table 4.3.1(1) Configuration of Index Adjustment Design - Thermal distribution systems
    # Change DSE to 1.0
    new_hvac_dist = hpxml.elements["Building/BuildingDetails/Systems/HVAC/HVACDistribution"]
    new_hvac_dist.elements["AnnualHeatingDistributionSystemEfficiency"].text = 1.0
    new_hvac_dist.elements["AnnualCoolingDistributionSystemEfficiency"].text = 1.0
  end

  def self.set_systems_mechanical_ventilation_reference(orig_details, hpxml)
    # Table 4.2.2(1) - Whole-House Mechanical ventilation

    # Init
    fan_type = nil

    orig_vent_fan = orig_details.elements["Systems/MechanicalVentilation/VentilationFans/VentilationFan[UsedForWholeBuildingVentilation='true']"]

    if not orig_vent_fan.nil?

      fan_type = XMLHelper.get_value(orig_vent_fan, "FanType")

      q_tot = Airflow.get_mech_vent_whole_house_cfm(1.0, @nbeds, @cfa, '2013')

      # Calculate fan cfm for airflow rate using Reference Home infiltration
      # http://www.resnet.us/standards/Interpretation_on_Reference_Home_Air_Exchange_Rate_approved.pdf
      sla = Float(XMLHelper.get_value(hpxml.elements["Building/BuildingDetails/Enclosure/AirInfiltration"], "extension/BuildingSpecificLeakageArea"))
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

      new_vent_fan = HPXML.add_ventilation_fan(hpxml: hpxml,
                                               id: "VentilationFan",
                                               fan_type: fan_type,
                                               rated_flow_rate: q_fan_airflow,
                                               hours_in_operation: 24, # TODO: CFIS
                                               used_for_whole_building_ventilation: true,
                                               fan_power: fan_power_w,
                                               idref: HPXML.get_idref(orig_vent_fan, "AttachedToHVACDistributionSystem"))
    end
  end

  def self.set_systems_mechanical_ventilation_rated(orig_details, hpxml)
    # Table 4.2.2(1) - Whole-House Mechanical ventilation
    orig_vent_fan = orig_details.elements["Systems/MechanicalVentilation/VentilationFans/VentilationFan[UsedForWholeBuildingVentilation='true']"]
    orig_vent_fan_values = HPXML.get_ventilation_fan_values(ventilation_fan: orig_vent_fan)

    if not orig_vent_fan.nil?
      new_vent_fan = HPXML.add_ventilation_fan(hpxml: hpxml,
                                               id: "VentilationFan",
                                               fan_type: orig_vent_fan_values[:fan_type],
                                               rated_flow_rate: orig_vent_fan_values[:rated_flow_rate],
                                               hours_in_operation: 24, # FIXME: Is this right?
                                               used_for_whole_building_ventilation: true,
                                               total_recovery_efficiency: orig_vent_fan_values[:total_recovery_efficiency],
                                               sensible_recovery_efficiency: orig_vent_fan_values[:sensible_recovery_efficiency],
                                               fan_power: orig_vent_fan_values[:fan_power],
                                               idref: orig_vent_fan_values[:idref])
    end
  end

  def self.set_systems_mechanical_ventilation_iad(orig_details, hpxml)
    # Table 4.3.1(1) Configuration of Index Adjustment Design - Whole-House Mechanical ventilation fan energy
    # Table 4.3.1(1) Configuration of Index Adjustment Design - Air exchange rate

    q_tot = Airflow.get_mech_vent_whole_house_cfm(1.0, @nbeds, @cfa, '2013')

    # Calculate fan cfm for airflow rate using IAD Home infiltration
    sla = Float(XMLHelper.get_value(hpxml.elements["Building/BuildingDetails/Enclosure/AirInfiltration"], "extension/BuildingSpecificLeakageArea"))
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

    new_vent_fan = HPXML.add_ventilation_fan(hpxml: hpxml,
                                             id: "VentilationFan",
                                             fan_type: "balanced",
                                             rated_flow_rate: q_fan_airflow,
                                             hours_in_operation: 24,
                                             used_for_whole_building_ventilation: true,
                                             fan_power: fan_power_w)
  end

  def self.set_systems_water_heater_reference(orig_details, hpxml)
    # Table 4.2.2(1) - Service water heating systems

    orig_details.elements.each("Systems/WaterHeating/WaterHeatingSystem") do |orig_wh_sys|
      orig_wh_sys_values = HPXML.get_water_heating_system_values(water_heating_system: orig_wh_sys)

      if orig_wh_sys_values[:water_heater_type] == 'instantaneous water heater'
        wh_tank_vol = 40.0
      else
        wh_tank_vol = Float(orig_wh_sys_values[:tank_volume])
      end
      wh_fuel_type = orig_wh_sys_values[:fuel_type]

      wh_ef, wh_re = get_water_heater_ef_and_re(orig_wh_sys_values[:fuel_type], wh_tank_vol)
      wh_cap = Waterheater.calc_water_heater_capacity(to_beopt_fuel(wh_fuel_type), @nbeds) * 1000.0 # Btuh

      # New water heater
      new_wh_sys = HPXML.add_water_heating_system(hpxml: hpxml,
                                                  id: orig_wh_sys_values[:id],
                                                  fuel_type: wh_fuel_type,
                                                  water_heater_type: 'storage water heater',
                                                  location: orig_wh_sys_values[:location],
                                                  tank_volume: wh_tank_vol,
                                                  fraction_dhw_load_served: orig_wh_sys_values[:fraction_dhw_load_served],
                                                  heating_capacity: wh_cap,
                                                  energy_factor: wh_ef,
                                                  recovery_efficiency: wh_re)
    end

    if orig_details.elements["Systems/WaterHeating/WaterHeatingSystem"].nil?
      add_reference_water_heater(orig_details, hpxml)
    end
  end

  def self.set_systems_water_heater_rated(orig_details, hpxml)
    # Table 4.2.2(1) - Service water heating systems

    orig_wh_sys = orig_details.elements["Systems/WaterHeating/WaterHeatingSystem"]

    orig_details.elements.each("Systems/WaterHeating/WaterHeatingSystem") do |orig_wh_sys|
      orig_wh_sys_values = HPXML.get_water_heating_system_values(water_heating_system: orig_wh_sys)

      wh_ef = orig_wh_sys_values[:energy_factor]
      wh_fuel_type = orig_wh_sys_values[:fuel_type]
      wh_type = orig_wh_sys_values[:water_heater_type]
      if wh_ef.nil?
        wh_uef = Float(orig_wh_sys_values[:uniform_energy_factor])
        wh_ef = Waterheater.calc_ef_from_uef(wh_uef, to_beopt_wh_type(wh_type), to_beopt_fuel(wh_fuel_type))
      end

      # New water heater
      new_wh_sys = HPXML.add_water_heating_system(hpxml: hpxml,
                                                  id: orig_wh_sys_values[:id],
                                                  fuel_type: wh_fuel_type,
                                                  water_heater_type: wh_type,
                                                  location: orig_wh_sys_values[:location],
                                                  tank_volume: orig_wh_sys_values[:tank_volume],
                                                  fraction_dhw_load_served: orig_wh_sys_values[:fraction_dhw_load_served],
                                                  heating_capacity: orig_wh_sys_values[:heating_capacity],
                                                  energy_factor: wh_ef,
                                                  recovery_efficiency: orig_wh_sys_values[:recovery_efficiency])
    end

    if orig_details.elements["Systems/WaterHeating/WaterHeatingSystem"].nil?
      add_reference_water_heater(orig_details, hpxml)
    end
  end

  def self.set_systems_water_heater_iad(orig_details, hpxml)
    # Table 4.3.1(1) Configuration of Index Adjustment Design - Service water heating systems
    set_systems_water_heater_reference(orig_details, hpxml)
  end

  def self.set_systems_water_heating_use_reference(orig_details, hpxml)
    # Table 4.2.2(1) - Service water heating systems

    orig_water_heating = orig_details.elements["Systems/WaterHeating"]

    has_uncond_bsmnt = (not orig_details.elements["Enclosure/Foundations/FoundationType/Basement[Conditioned='false']"].nil?)
    std_pipe_length = HotWaterAndAppliances.get_default_std_pipe_length(has_uncond_bsmnt, @cfa, @ncfl)

    sys_id = nil
    if orig_water_heating.nil?
      sys_id = "HotWaterDistribution"
    else
      orig_hw_dist = orig_water_heating.elements["HotWaterDistribution"]
      orig_hw_dist_values = HPXML.get_hot_water_distribution_values(hot_water_distribution: orig_hw_dist)
      sys_id = orig_hw_dist_values[:id]
    end

    # New hot water distribution
    new_hw_dist = HPXML.add_hot_water_distribution(hpxml: hpxml,
                                                   id: sys_id,
                                                   system_type: "Standard",
                                                   pipe_r_value: 0,
                                                   standard_piping_length: std_pipe_length)

    # New water fixtures
    if orig_water_heating.nil?
      # Shower Head
      new_fixture = HPXML.add_water_fixture(hpxml: hpxml,
                                            id: "ShowerHead",
                                            water_fixture_type: "shower head",
                                            low_flow: false)

      # Faucet
      new_fixture = HPXML.add_water_fixture(hpxml: hpxml,
                                            id: "Faucet",
                                            water_fixture_type: "faucet",
                                            low_flow: false)
    else
      orig_water_heating.elements.each("WaterFixture[WaterFixtureType='shower head' or WaterFixtureType='faucet']") do |orig_fixture|
        orig_fixture_values = HPXML.get_water_fixture_values(water_fixture: orig_fixture)
        new_fixture = HPXML.add_water_fixture(hpxml: hpxml,
                                              id: orig_fixture_values[:id],
                                              water_fixture_type: orig_fixture_values[:water_fixture_type],
                                              low_flow: false)
      end
    end
  end

  def self.set_systems_water_heating_use_rated(orig_details, hpxml)
    # Table 4.2.2(1) - Service water heating systems

    orig_water_heating = orig_details.elements["Systems/WaterHeating"]
    if orig_water_heating.nil?
      set_systems_water_heating_use_reference(orig_details, hpxml)
      return
    end

    orig_hw_dist = orig_water_heating.elements["HotWaterDistribution"]
    orig_hw_dist_values = HPXML.get_hot_water_distribution_values(hot_water_distribution: orig_hw_dist)

    has_uncond_bsmnt = (not orig_details.elements["Enclosure/Foundations/FoundationType/Basement[Conditioned='false']"].nil?)
    std_pipe_length = HotWaterAndAppliances.get_default_std_pipe_length(has_uncond_bsmnt, @cfa, @ncfl)
    recirc_loop_length = HotWaterAndAppliances.get_default_recirc_loop_length(std_pipe_length)
    orig_standard = orig_hw_dist.elements["SystemType/Standard"]
    orig_recirc = orig_hw_dist.elements["SystemType/Recirculation"]
    if not orig_standard.nil?
      unless orig_standard.elements["PipingLength"].nil?
        std_pipe_length = orig_hw_dist_values[:standard_piping_length]
      end
    elsif not orig_recirc.nil?
      unless orig_recirc.elements["RecirculationPipingLoopLength"].nil?
        recirc_loop_length = orig_hw_dist_values[:recirculation_piping_loop_length]
      end
    end

    # New hot water distribution
    new_hw_dist = HPXML.add_hot_water_distribution(hpxml: hpxml,
                                                   id: orig_hw_dist_values[:id],
                                                   system_type: orig_hw_dist_values[:system_type],
                                                   pipe_r_value: orig_hw_dist_values[:pipe_r_value],
                                                   standard_piping_length: std_pipe_length,
                                                   recirculation_control_type: orig_hw_dist_values[:recirculation_control_type],
                                                   recirculation_piping_loop_length: recirc_loop_length,
                                                   recirculation_branch_piping_loop_length: orig_hw_dist_values[:recirculation_branch_piping_loop_length],
                                                   recirculation_pump_power: orig_hw_dist_values[:recirculation_pump_power],
                                                   drain_water_heat_recovery_facilities_connected: orig_hw_dist_values[:drain_water_heat_recovery_facilities_connected],
                                                   drain_water_heat_recovery_equal_flow: orig_hw_dist_values[:drain_water_heat_recovery_equal_flow],
                                                   drain_water_heat_recovery_efficiency: orig_hw_dist_values[:drain_water_heat_recovery_efficiency])

    # New water fixtures
    orig_water_heating.elements.each("WaterFixture[WaterFixtureType='shower head' or WaterFixtureType='faucet']") do |orig_fixture|
      orig_fixture_values = HPXML.get_water_fixture_values(water_fixture: orig_fixture)
      new_fixture = HPXML.add_water_fixture(hpxml: hpxml,
                                            id: orig_fixture_values[:id],
                                            water_fixture_type: orig_fixture_values[:water_fixture_type],
                                            low_flow: orig_fixture_values[:low_flow])
    end
  end

  def self.set_systems_water_heating_use_iad(orig_details, hpxml)
    # Table 4.3.1(1) Configuration of Index Adjustment Design - Service water heating systems
    set_systems_water_heating_use_reference(orig_details, hpxml)
  end

  def self.set_systems_photovoltaics_reference(hpxml)
    # nop
  end

  def self.set_systems_photovoltaics_rated(orig_details, hpxml)
    return if not XMLHelper.has_element(orig_details, "Systems/Photovoltaics")

    orig_details.elements.each("Systems/Photovoltaics/PVSystem") do |orig_pv|
      orig_pv_values = HPXML.get_pv_system_values(pv_system: orig_pv)
      new_pv = HPXML.add_pv_system(hpxml: hpxml,
                                   id: orig_pv_values[:id],
                                   module_type: orig_pv_values[:module_type],
                                   array_type: orig_pv_values[:array_type],
                                   array_azimuth: orig_pv_values[:array_azimuth],
                                   array_tilt: orig_pv_values[:array_tilt],
                                   max_power_output: orig_pv_values[:max_power_output],
                                   inverter_efficiency: orig_pv_values[:inverter_efficiency],
                                   system_losses_fraction: orig_pv_values[:system_losses_fraction])
    end
  end

  def self.set_systems_photovoltaics_iad(hpxml)
    # 4.3.1 Index Adjustment Design (IAD)
    # Renewable Energy Systems that offset the energy consumption requirements of the Rated Home shall not be included in the IAD.
    # nop
  end

  def self.set_appliances_clothes_washer_reference(orig_details, hpxml)
    orig_appliances = orig_details.elements["Appliances"]
    orig_washer = orig_appliances.elements["ClothesWasher"]

    new_washer = HPXML.add_clothes_washer(hpxml: hpxml,
                                          id: HPXML.get_id(orig_washer),
                                          location: "living space",
                                          modified_energy_factor: HotWaterAndAppliances.get_clothes_washer_reference_mef(),
                                          rated_annual_kwh: HotWaterAndAppliances.get_clothes_washer_reference_ler(),
                                          label_electric_rate: HotWaterAndAppliances.get_clothes_washer_reference_elec_rate(),
                                          label_gas_rate: HotWaterAndAppliances.get_clothes_washer_reference_gas_rate(),
                                          label_annual_gas_cost: HotWaterAndAppliances.get_clothes_washer_reference_agc(),
                                          capacity: HotWaterAndAppliances.get_clothes_washer_reference_cap())
  end

  def self.set_appliances_clothes_washer_rated(orig_details, hpxml)
    orig_appliances = orig_details.elements["Appliances"]
    orig_washer = orig_appliances.elements["ClothesWasher"]
    orig_washer_values = HPXML.get_clothes_washer_values(clothes_washer: orig_washer)

    if orig_washer.elements["ModifiedEnergyFactor"].nil? and orig_washer.elements["IntegratedModifiedEnergyFactor"].nil?
      self.set_appliances_clothes_washer_reference(orig_details, hpxml)
      return
    end

    new_washer = HPXML.add_clothes_washer(hpxml: hpxml,
                                          id: orig_washer_values[:id],
                                          location: orig_washer_values[:location],
                                          modified_energy_factor: orig_washer_values[:modified_energy_factor],
                                          integrated_modified_energy_factor: orig_washer_values[:integrated_modified_energy_factor],
                                          rated_annual_kwh: orig_washer_values[:rated_annual_kwh],
                                          label_electric_rate: orig_washer_values[:label_electric_rate],
                                          label_gas_rate: orig_washer_values[:label_gas_rate],
                                          label_annual_gas_cost: orig_washer_values[:label_annual_gas_cost],
                                          capacity: orig_washer_values[:capacity])
  end

  def self.set_appliances_clothes_washer_iad(orig_details, hpxml)
    # Table 4.3.1(1) Configuration of Index Adjustment Design - Lighting, Appliances and Miscellaneous Electric Loads (MELs)
    self.set_appliances_clothes_washer_reference(orig_details, hpxml)
  end

  def self.set_appliances_clothes_dryer_reference(orig_details, hpxml)
    orig_appliances = orig_details.elements["Appliances"]
    orig_dryer = orig_appliances.elements["ClothesDryer"]
    orig_dryer_values = HPXML.get_clothes_dryer_values(clothes_dryer: orig_dryer)

    cd_fuel = orig_dryer_values[:fuel_type]
    cd_ef = HotWaterAndAppliances.get_clothes_dryer_reference_ef(to_beopt_fuel(cd_fuel))
    cd_control = HotWaterAndAppliances.get_clothes_dryer_reference_control()

    new_dryer = HPXML.add_clothes_dryer(hpxml: hpxml,
                                        id: orig_dryer_values[:id],
                                        location: "living space",
                                        fuel_type: cd_fuel,
                                        energy_factor: cd_ef,
                                        control_type: cd_control)
  end

  def self.set_appliances_clothes_dryer_rated(orig_details, hpxml)
    orig_appliances = orig_details.elements["Appliances"]
    orig_dryer = orig_appliances.elements["ClothesDryer"]
    orig_dryer_values = HPXML.get_clothes_dryer_values(clothes_dryer: orig_dryer)

    if orig_dryer.elements["EnergyFactor"].nil? and orig_dryer.elements["CombinedEnergyFactor"].nil?
      self.set_appliances_clothes_dryer_reference(orig_details, hpxml)
      return
    end

    new_dryer = HPXML.add_clothes_dryer(hpxml: hpxml,
                                        id: orig_dryer_values[:id],
                                        location: orig_dryer_values[:location],
                                        fuel_type: orig_dryer_values[:fuel_type],
                                        energy_factor: orig_dryer_values[:energy_factor],
                                        combined_energy_factor: orig_dryer_values[:combined_energy_factor],
                                        control_type: orig_dryer_values[:control_type])
  end

  def self.set_appliances_clothes_dryer_iad(orig_details, hpxml)
    # Table 4.3.1(1) Configuration of Index Adjustment Design - Lighting, Appliances and Miscellaneous Electric Loads (MELs)
    self.set_appliances_clothes_dryer_reference(orig_details, hpxml)
  end

  def self.set_appliances_dishwasher_reference(orig_details, hpxml)
    orig_appliances = orig_details.elements["Appliances"]
    orig_dishwasher = orig_appliances.elements["Dishwasher"]

    new_dishwasher = HPXML.add_dishwasher(hpxml: hpxml,
                                          id: HPXML.get_id(orig_dishwasher),
                                          energy_factor: HotWaterAndAppliances.get_dishwasher_reference_ef(),
                                          place_setting_capacity: Integer(HotWaterAndAppliances.get_dishwasher_reference_cap()))
  end

  def self.set_appliances_dishwasher_rated(orig_details, hpxml)
    orig_appliances = orig_details.elements["Appliances"]
    orig_dishwasher = orig_appliances.elements["Dishwasher"]
    orig_dishwasher_values = HPXML.get_dishwasher_values(dishwasher: orig_dishwasher)

    if orig_dishwasher.elements["EnergyFactor"].nil? and orig_dishwasher.elements["RatedAnnualkWh"].nil?
      self.set_appliances_dishwasher_reference(orig_details, hpxml)
      return
    end

    new_dishwasher = HPXML.add_dishwasher(hpxml: hpxml,
                                          id: orig_dishwasher_values[:id],
                                          energy_factor: orig_dishwasher_values[:energy_factor],
                                          rated_annual_kwh: orig_dishwasher_values[:rated_annual_kwh],
                                          place_setting_capacity: orig_dishwasher_values[:place_setting_capacity])
  end

  def self.set_appliances_dishwasher_iad(orig_details, hpxml)
    # Table 4.3.1(1) Configuration of Index Adjustment Design - Lighting, Appliances and Miscellaneous Electric Loads (MELs)
    self.set_appliances_dishwasher_reference(orig_details, hpxml)
  end

  def self.set_appliances_refrigerator_reference(orig_details, hpxml)
    orig_appliances = orig_details.elements["Appliances"]
    orig_fridge = orig_appliances.elements["Refrigerator"]
    orig_fridge_values = HPXML.get_refrigerator_values(refrigerator: orig_fridge)

    # Table 4.2.2.5(1) Lighting, Appliance and Miscellaneous Electric Loads in electric ERI Reference Homes
    refrigerator_kwh = HotWaterAndAppliances.get_refrigerator_reference_annual_kwh(@nbeds)

    new_fridge = HPXML.add_refrigerator(hpxml: hpxml,
                                        id: orig_fridge_values[:id],
                                        location: "living space",
                                        rated_annual_kwh: refrigerator_kwh)
  end

  def self.set_appliances_refrigerator_rated(orig_details, hpxml)
    orig_appliances = orig_details.elements["Appliances"]
    orig_fridge = orig_appliances.elements["Refrigerator"]
    orig_fridge_values = HPXML.get_refrigerator_values(refrigerator: orig_fridge)

    if orig_fridge.elements["RatedAnnualkWh"].nil?
      self.set_appliances_refrigerator_reference(orig_details, hpxml)
      return
    end

    new_fridge = HPXML.add_refrigerator(hpxml: hpxml,
                                        id: orig_fridge_values[:id],
                                        location: orig_fridge_values[:location],
                                        rated_annual_kwh: orig_fridge_values[:rated_annual_kwh])
  end

  def self.set_appliances_refrigerator_iad(orig_details, hpxml)
    # Table 4.3.1(1) Configuration of Index Adjustment Design - Lighting, Appliances and Miscellaneous Electric Loads (MELs)
    self.set_appliances_refrigerator_reference(orig_details, hpxml)
  end

  def self.set_appliances_cooking_range_oven_reference(orig_details, hpxml)
    orig_appliances = orig_details.elements["Appliances"]
    orig_range = orig_appliances.elements["CookingRange"]
    orig_range_values = HPXML.get_cooking_range_values(cooking_range: orig_range)
    orig_oven = orig_appliances.elements["Oven"]
    orig_oven_values = HPXML.get_oven_values(oven: orig_oven)

    new_range = HPXML.add_cooking_range(hpxml: hpxml,
                                        id: orig_range_values[:id],
                                        fuel_type: orig_range_values[:fuel_type],
                                        is_induction: HotWaterAndAppliances.get_range_oven_reference_is_induction())

    new_oven = HPXML.add_oven(hpxml: hpxml,
                              id: orig_oven_values[:id],
                              is_convection: HotWaterAndAppliances.get_range_oven_reference_is_convection())
  end

  def self.set_appliances_cooking_range_oven_rated(orig_details, hpxml)
    orig_appliances = orig_details.elements["Appliances"]
    orig_range = orig_appliances.elements["CookingRange"]
    orig_range_values = HPXML.get_cooking_range_values(cooking_range: orig_range)
    orig_oven = orig_appliances.elements["Oven"]
    orig_oven_values = HPXML.get_oven_values(oven: orig_oven)

    if orig_range.elements["IsInduction"].nil?
      self.set_appliances_cooking_range_oven_reference(orig_details, hpxml)
      return
    end

    new_range = HPXML.add_cooking_range(hpxml: hpxml,
                                        id: orig_range_values[:id],
                                        fuel_type: orig_range_values[:fuel_type],
                                        is_induction: orig_range_values[:is_induction])

    new_oven = HPXML.add_oven(hpxml: hpxml,
                              id: orig_oven_values[:id],
                              is_convection: orig_oven_values[:is_convection])
  end

  def self.set_appliances_cooking_range_oven_iad(orig_details, hpxml)
    # Table 4.3.1(1) Configuration of Index Adjustment Design - Lighting, Appliances and Miscellaneous Electric Loads (MELs)
    self.set_appliances_cooking_range_oven_reference(orig_details, hpxml)
  end

  def self.set_lighting_reference(orig_details, hpxml)
    fFI_int, fFI_ext, fFI_grg, fFII_int, fFII_ext, fFII_grg = Lighting.get_reference_fractions()

    new_fractions = HPXML.add_lighting_fractions(hpxml: hpxml,
                                                 fraction_qualifying_tier_i_fixtures_interior: fFI_int,
                                                 fraction_qualifying_tier_i_fixtures_exterior: fFI_ext,
                                                 fraction_qualifying_tier_i_fixtures_garage: fFI_grg,
                                                 fraction_qualifying_tier_ii_fixtures_interior: fFII_int,
                                                 fraction_qualifying_tier_ii_fixtures_exterior: fFII_ext,
                                                 fraction_qualifying_tier_ii_fixtures_garage: fFII_grg)
  end

  def self.set_lighting_rated(orig_details, hpxml)
    orig_lighting = orig_details.elements["Lighting"]
    orig_fractions = orig_lighting.elements["LightingFractions"]
    orig_fractions_values = HPXML.get_lighting_fractions_values(lighting_fractions: orig_fractions)

    if orig_fractions.nil?
      self.set_lighting_reference(orig_details, hpxml)
      return
    end

    # For rating purposes, the Rated Home shall not have qFFIL less than 0.10 (10%).
    fFI_int = Float(orig_fractions_values[:fraction_qualifying_tier_i_fixtures_interior])
    fFII_int = Float(orig_fractions_values[:fraction_qualifying_tier_ii_fixtures_interior])
    if fFI_int + fFII_int < 0.1
      fFI_int = 0.1 - fFII_int
    end

    new_fractions = HPXML.add_lighting_fractions(hpxml: hpxml,
                                                 fraction_qualifying_tier_i_fixtures_interior: fFI_int,
                                                 fraction_qualifying_tier_i_fixtures_exterior: orig_fractions_values[:fraction_qualifying_tier_i_fixtures_exterior],
                                                 fraction_qualifying_tier_i_fixtures_garage: orig_fractions_values[:fraction_qualifying_tier_i_fixtures_garage],
                                                 fraction_qualifying_tier_ii_fixtures_interior: fFII_int,
                                                 fraction_qualifying_tier_ii_fixtures_exterior: orig_fractions_values[:fraction_qualifying_tier_ii_fixtures_exterior],
                                                 fraction_qualifying_tier_ii_fixtures_garage: orig_fractions_values[:fraction_qualifying_tier_ii_fixtures_garage])
  end

  def self.set_lighting_iad(orig_details, hpxml)
    fFI_int, fFI_ext, fFI_grg, fFII_int, fFII_ext, fFII_grg = Lighting.get_iad_fractions()

    new_fractions = HPXML.add_lighting_fractions(hpxml: hpxml,
                                                 fraction_qualifying_tier_i_fixtures_interior: fFI_int,
                                                 fraction_qualifying_tier_i_fixtures_exterior: fFI_ext,
                                                 fraction_qualifying_tier_i_fixtures_garage: fFI_grg,
                                                 fraction_qualifying_tier_ii_fixtures_interior: fFII_int,
                                                 fraction_qualifying_tier_ii_fixtures_exterior: fFII_ext,
                                                 fraction_qualifying_tier_ii_fixtures_garage: fFII_grg)
  end

  def self.set_ceiling_fans_reference(orig_details, hpxml)
    return if not XMLHelper.has_element(orig_details, "Lighting/CeilingFan")

    orig_cf = orig_details.elements["Lighting/CeilingFan"]
    medium_cfm = 3000.0

    new_cf = HPXML.add_ceiling_fan(hpxml: hpxml,
                                   id: "CeilingFans",
                                   fan_speed: "medium",
                                   efficiency: medium_cfm / HVAC.get_default_ceiling_fan_power(),
                                   quantity: Integer(HVAC.get_default_ceiling_fan_quantity(@nbeds)))
  end

  def self.set_ceiling_fans_rated(orig_details, hpxml)
    return if not XMLHelper.has_element(orig_details, "Lighting/CeilingFan")

    medium_cfm = 3000.0

    # Calculate average ceiling fan wattage
    sum_w = 0.0
    num_cfs = 0
    orig_details.elements.each("Lighting/CeilingFan") do |orig_cf|
      orig_cf_values = HPXML.get_ceiling_fan_values(ceiling_fan: orig_cf)
      cf_quantity = Integer(orig_cf_values[:quantity])
      num_cfs += cf_quantity
      cfm_per_w = orig_cf_values[:efficiency]
      if orig_cf_values[:fan_speed] == "medium"
        cfm_per_w = Float(cfm_per_w)
      else
        fan_power_w = HVAC.get_default_ceiling_fan_power()
        cfm_per_w = medium_cfm / fan_power_w
      end
      sum_w += (medium_cfm / cfm_per_w * Float(cf_quantity))
    end
    avg_w = sum_w / num_cfs

    new_cf = HPXML.add_ceiling_fan(hpxml: hpxml,
                                   id: "CeilingFans",
                                   fan_speed: "medium",
                                   efficiency: medium_cfm / avg_w,
                                   quantity: Integer(HVAC.get_default_ceiling_fan_quantity(@nbeds)))
  end

  def self.set_ceiling_fans_iad(orig_details, hpxml)
    # Not described in Addendum E; use Reference Home?
    set_ceiling_fans_reference(orig_details, hpxml)
  end

  def self.set_misc_loads_reference(hpxml)
    # Misc
    misc = HPXML.add_plug_load(hpxml: hpxml,
                               id: "MiscPlugLoad",
                               plug_load_type: "other")

    # Television
    tv = HPXML.add_plug_load(hpxml: hpxml,
                             id: "TelevisionPlugLoad",
                             plug_load_type: "TV other")
  end

  def self.set_misc_loads_rated(hpxml)
    set_misc_loads_reference(hpxml)
  end

  def self.set_misc_loads_iad(hpxml)
    set_misc_loads_reference(hpxml)
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
               "coal", "coke", "wood", "wood pellets"]
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

  def self.add_reference_heating_gas_furnace(hpxml, load_frac = 1.0, seed_id = nil)
    # 78% AFUE gas furnace
    cnt = hpxml.elements["Building/BuildingDetails/Systems/HVAC/HVACPlant/count(HeatingSystem)"]
    if cnt.nil?
      cnt = 0
    end
    heat_sys = HPXML.add_heating_system(hpxml: hpxml,
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
                          extensions: { "SeedId": seed_id })
    end
  end

  def self.add_reference_heating_gas_boiler(hpxml, load_frac = 1.0, seed_id = nil)
    # 80% AFUE gas boiler
    cnt = hpxml.elements["Building/BuildingDetails/Systems/HVAC/HVACPlant/count(HeatingSystem)"]
    if cnt.nil?
      cnt = 0
    end
    heat_sys = HPXML.add_heating_system(hpxml: hpxml,
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
                          extensions: { "SeedId": seed_id })
    end
  end

  def self.add_reference_heating_heat_pump(hpxml, load_frac = 1.0, seed_id = nil)
    # 7.7 HSPF air source heat pump
    cnt = hpxml.elements["Building/BuildingDetails/Systems/HVAC/HVACPlant/count(HeatPump)"]
    if cnt.nil?
      cnt = 0
    end
    heat_pump = HPXML.add_heat_pump(hpxml: hpxml,
                                    id: "HeatPump#{cnt + 1}",
                                    idref: "HVACDistribution_DSE_80",
                                    heat_pump_type: "air-to-air",
                                    heat_pump_fuel: "electricity",
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
                          extensions: { "SeedId": seed_id })
    end
  end

  def self.add_reference_cooling_air_conditioner(hpxml, load_frac = 1.0, seed_id = nil)
    # 13 SEER electric air conditioner
    cnt = hpxml.elements["Building/BuildingDetails/Systems/HVAC/HVACPlant/count(CoolingSystem)"]
    if cnt.nil?
      cnt = 0
    end
    cool_sys = HPXML.add_cooling_system(hpxml: hpxml,
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
                          extensions: { "SeedId": seed_id })
    end
  end

  def self.add_reference_distribution_system(hpxml)
    # Table 4.2.2(1) - Thermal distribution systems
    new_hvac_dist = HPXML.add_hvac_distribution(hpxml: hpxml,
                                                id: "HVACDistribution_DSE_80",
                                                distribution_system_type: "DSE",
                                                annual_heating_distribution_system_efficiency: 0.8,
                                                annual_cooling_distribution_system_efficiency: 0.8)
  end

  def self.add_reference_water_heater(orig_details, hpxml)
    wh_fuel_type = get_predominant_heating_fuel(orig_details)
    wh_tank_vol = 40.0

    wh_ef, wh_re = get_water_heater_ef_and_re(wh_fuel_type, wh_tank_vol)
    wh_cap = Waterheater.calc_water_heater_capacity(to_beopt_fuel(wh_fuel_type), @nbeds) * 1000.0 # Btuh

    new_wh_sys = HPXML.add_water_heating_system(hpxml: hpxml,
                                                id: 'WaterHeatingSystem',
                                                fuel_type: wh_fuel_type,
                                                water_heater_type: 'storage water heater',
                                                location: 'living space', # 301 Standard doesn't specify the location
                                                tank_volume: wh_tank_vol,
                                                fraction_dhw_load_served: 1.0,
                                                heating_capacity: wh_cap,
                                                energy_factor: wh_ef,
                                                recovery_efficiency: wh_re)
  end

  def self.get_predominant_heating_fuel(orig_details)
    fuel_fracs = {}

    orig_details.elements.each("Systems/HVAC/HVACPlant/HeatingSystem") do |heating_system|
      fuel = XMLHelper.get_value(heating_system, "HeatingSystemFuel")
      load_frac = Float(XMLHelper.get_value(heating_system, "FractionHeatLoadServed"))
      if fuel_fracs[fuel].nil?
        fuel_fracs[fuel] = 0.0
      end
      fuel_fracs[fuel] += load_frac
    end

    orig_details.elements.each("Systems/HVAC/HVACPlant/HeatPump") do |heat_pump|
      fuel = XMLHelper.get_value(heat_pump, "HeatPumpFuel")
      load_frac = Float(XMLHelper.get_value(heat_pump, "FractionHeatLoadServed"))
      if fuel_fracs[fuel].nil?
        fuel_fracs[fuel] = 0.0
      end
      fuel_fracs[fuel] += load_frac
    end

    return "electricity" if fuel_fracs.empty?

    return fuel_fracs.key(fuel_fracs.values.max)
  end
end

def get_exterior_wall_area_fracs(orig_details)
  # Get individual exterior wall areas and sum
  wall_areas = {}
  wall_area_sum = 0.0
  orig_details.elements.each("Enclosure/Walls/Wall") do |orig_wall|
    orig_wall_values = HPXML.get_wall_values(wall: orig_wall)
    next if orig_wall_values[:exterior_adjacent_to] != "outside"
    next if orig_wall_values[:interior_adjacent_to] != "living space"

    wall_area = Float(orig_wall_values[:area])
    wall_areas[orig_wall] = wall_area
    wall_area_sum += wall_area
  end

  # Convert to fractions
  wall_area_fracs = {}
  wall_areas.each do |wall, wall_area|
    wall_area_fracs[wall] = wall_areas[wall] / wall_area_sum
  end

  return wall_area_fracs
end
