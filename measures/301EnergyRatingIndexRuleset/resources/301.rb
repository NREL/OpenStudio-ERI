require_relative "../../HPXMLtoOpenStudio/measure"
require_relative "../../HPXMLtoOpenStudio/resources/airflow"
require_relative "../../HPXMLtoOpenStudio/resources/constants"
require_relative "../../HPXMLtoOpenStudio/resources/constructions"
require_relative "../../HPXMLtoOpenStudio/resources/geometry"
require_relative "../../HPXMLtoOpenStudio/resources/hotwater_appliances"
require_relative "../../HPXMLtoOpenStudio/resources/lighting"
require_relative "../../HPXMLtoOpenStudio/resources/unit_conversions"
require_relative "../../HPXMLtoOpenStudio/resources/waterheater"
require_relative "../../HPXMLtoOpenStudio/resources/hpxml"

class EnergyRatingIndex301Ruleset
  def self.apply_ruleset(hpxml_doc, calc_type, weather)
    # Global variables
    @weather = weather
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

  def self.create_new_doc(hpxml_doc)
    hpxml_values = HPXML.get_hpxml_values(hpxml: hpxml_doc.elements["/HPXML"])

    hpxml_doc = HPXML.create_hpxml(xml_type: hpxml_values[:xml_type],
                                   xml_generated_by: hpxml_values[:xml_generated_by],
                                   transaction: hpxml_values[:transaction],
                                   software_program_used: "OpenStudio-ERI workflow",
                                   software_program_version: "X.X",
                                   eri_calculation_version: hpxml_values[:eri_calculation_version],
                                   building_id: hpxml_values[:building_id],
                                   event_type: hpxml_values[:event_type])

    return hpxml_doc
  end

  def self.set_summary_reference(orig_details, hpxml)
    site = orig_details.elements["BuildingSummary/Site"]
    site_values = HPXML.get_site_values(site: site)
    building_construction = orig_details.elements["BuildingSummary/BuildingConstruction"]
    building_construction_values = HPXML.get_building_construction_values(building_construction: building_construction)

    # Global variables
    @cfa = building_construction_values[:conditioned_floor_area]
    @nbeds = building_construction_values[:number_of_bedrooms]
    @ncfl = building_construction_values[:number_of_conditioned_floors]
    @ncfl_ag = building_construction_values[:number_of_conditioned_floors_above_grade]
    @cvolume = building_construction_values[:conditioned_building_volume]
    @infilvolume = get_infiltration_volume(orig_details)
    @garage_present = building_construction_values[:garage_present]

    HPXML.add_site(hpxml: hpxml,
                   fuels: site_values[:fuels],
                   shelter_coefficient: Airflow.get_default_shelter_coefficient())

    HPXML.add_building_occupancy(hpxml: hpxml,
                                 number_of_residents: Geometry.get_occupancy_default_num(@nbeds))

    HPXML.add_building_construction(hpxml: hpxml, **building_construction_values)
  end

  def self.set_summary_rated(orig_details, hpxml)
    site = orig_details.elements["BuildingSummary/Site"]
    site_values = HPXML.get_site_values(site: site)
    building_construction = orig_details.elements["BuildingSummary/BuildingConstruction"]
    building_construction_values = HPXML.get_building_construction_values(building_construction: building_construction)

    # Global variables
    @cfa = building_construction_values[:conditioned_floor_area]
    @nbeds = building_construction_values[:number_of_bedrooms]
    @ncfl = building_construction_values[:number_of_conditioned_floors]
    @ncfl_ag = building_construction_values[:number_of_conditioned_floors_above_grade]
    @cvolume = building_construction_values[:conditioned_building_volume]
    @infilvolume = get_infiltration_volume(orig_details)
    @garage_present = building_construction_values[:garage_present]

    HPXML.add_site(hpxml: hpxml,
                   fuels: site_values[:fuels],
                   shelter_coefficient: Airflow.get_default_shelter_coefficient())

    HPXML.add_building_occupancy(hpxml: hpxml,
                                 number_of_residents: Geometry.get_occupancy_default_num(@nbeds))

    HPXML.add_building_construction(hpxml: hpxml, **building_construction_values)
  end

  def self.set_summary_iad(orig_details, hpxml)
    site = orig_details.elements["BuildingSummary/Site"]
    site_values = HPXML.get_site_values(site: site)

    # Global variables
    # Table 4.3.1(1) Configuration of Index Adjustment Design - General Characteristics
    @cfa = 2400
    @nbeds = 3
    @ncfl = 2
    @ncfl_ag = 2
    @cvolume = 20400
    @infilvolume = 20400
    @garage_present = false

    HPXML.add_site(hpxml: hpxml,
                   fuels: site_values[:fuels],
                   shelter_coefficient: Airflow.get_default_shelter_coefficient())

    HPXML.add_building_occupancy(hpxml: hpxml,
                                 number_of_residents: Geometry.get_occupancy_default_num(@nbeds))

    HPXML.add_building_construction(hpxml: hpxml,
                                    number_of_conditioned_floors: @ncfl,
                                    number_of_conditioned_floors_above_grade: @ncfl_ag,
                                    number_of_bedrooms: @nbeds,
                                    conditioned_floor_area: @cfa,
                                    conditioned_building_volume: @cvolume,
                                    garage_present: @garage_present)
  end

  def self.set_climate(orig_details, hpxml)
    orig_details.elements.each("ClimateandRiskZones/ClimateZoneIECC") do |climate_zone_iecc|
      climate_zone_iecc_values = HPXML.get_climate_zone_iecc_values(climate_zone_iecc: climate_zone_iecc)
      HPXML.add_climate_zone_iecc(hpxml: hpxml, **climate_zone_iecc_values)
      if climate_zone_iecc_values[:year] == 2006
        @iecc_zone_2006 = climate_zone_iecc_values[:climate_zone]
      elsif climate_zone_iecc_values[:year] == 2012
        @iecc_zone_2012 = climate_zone_iecc_values[:climate_zone]
      end
    end

    weather_station = orig_details.elements["ClimateandRiskZones/WeatherStation"]
    weather_station_values = HPXML.get_weather_station_values(weather_station: weather_station)
    HPXML.add_weather_station(hpxml: hpxml, **weather_station_values)
  end

  def self.set_enclosure_air_infiltration_reference(hpxml)
    # Table 4.2.2(1) - Air exchange rate
    sla = 0.00036
    ach50 = Airflow.get_infiltration_ACH50_from_SLA(sla, 0.65, @cfa, @infilvolume)

    # ACH50
    HPXML.add_air_infiltration_measurement(hpxml: hpxml,
                                           id: "Infiltration_ACH50",
                                           house_pressure: 50,
                                           unit_of_measure: "ACH",
                                           air_leakage: ach50,
                                           infiltration_volume: @infilvolume)
  end

  def self.set_enclosure_air_infiltration_rated(orig_details, hpxml)
    # Table 4.2.2(1) - Air exchange rate

    whole_house_fan = orig_details.elements["Systems/MechanicalVentilation/VentilationFans/VentilationFan[UsedForWholeBuildingVentilation='true']"]

    ach50 = nil
    orig_details.elements.each("Enclosure/AirInfiltration/AirInfiltrationMeasurement") do |air_infiltration_measurement|
      air_infiltration_measurement_values = HPXML.get_air_infiltration_measurement_values(air_infiltration_measurement: air_infiltration_measurement)
      if air_infiltration_measurement_values[:unit_of_measure] == 'ACHnatural'
        nach = air_infiltration_measurement_values[:air_leakage]
        if whole_house_fan.nil? and nach < 0.30
          nach = 0.30
        end
        sla = Airflow.get_infiltration_SLA_from_ACH(nach, @ncfl, @weather)
        ach50 = Airflow.get_infiltration_ACH50_from_SLA(sla, 0.65, @cfa, @infilvolume)
        break
      elsif air_infiltration_measurement_values[:unit_of_measure] == 'ACH' and air_infiltration_measurement_values[:house_pressure] == 50
        ach50 = air_infiltration_measurement_values[:air_leakage]
        break
      end
    end

    # ACH50
    HPXML.add_air_infiltration_measurement(hpxml: hpxml,
                                           id: "Infiltration_ACH50",
                                           house_pressure: 50,
                                           unit_of_measure: "ACH",
                                           air_leakage: ach50,
                                           infiltration_volume: @infilvolume)
  end

  def self.set_enclosure_air_infiltration_iad(hpxml)
    # Table 4.3.1(1) Configuration of Index Adjustment Design - Air exchange rate
    if ["1A", "1B", "1C", "2A", "2B", "2C"].include? @iecc_zone_2012
      ach50 = 5.0
    elsif ["3A", "3B", "3C", "4A", "4B", "4C", "5A", "5B", "5C", "6A", "6B", "6C", "7", "8"].include? @iecc_zone_2012
      ach50 = 3.0
    else
      fail "Unhandled IECC 2012 climate zone #{@iecc_zone_2012}."
    end

    # ACH50
    HPXML.add_air_infiltration_measurement(hpxml: hpxml,
                                           id: "Infiltration_ACH50",
                                           house_pressure: 50,
                                           unit_of_measure: "ACH",
                                           air_leakage: ach50,
                                           infiltration_volume: @infilvolume)
  end

  def self.set_enclosure_attics_roofs_reference(orig_details, hpxml)
    ceiling_ufactor = FloorConstructions.get_default_ceiling_ufactor(@iecc_zone_2006)
    wall_ufactor = WallConstructions.get_default_frame_wall_ufactor(@iecc_zone_2006)

    orig_details.elements.each("Enclosure/Attics/Attic") do |attic|
      attic_values = HPXML.get_attic_values(attic: attic)
      if attic_values[:attic_type] == 'UnventedAttic'
        attic_values[:attic_type] = 'VentedAttic'
      end
      interior_adjacent_to = get_attic_adjacent_to(attic_values[:attic_type])

      if attic_values[:attic_type] == 'VentedAttic'
        attic_values[:specific_leakage_area] = Airflow.get_default_vented_attic_sla()
      end

      new_attic = HPXML.add_attic(hpxml: hpxml, **attic_values)

      # Table 4.2.2(1) - Roofs
      attic.elements.each("Roofs/Roof") do |roof|
        roof_values = HPXML.get_attic_roof_values(roof: roof)
        roof_values[:solar_absorptance] = 0.75
        roof_values[:emittance] = 0.90
        if is_external_thermal_boundary(interior_adjacent_to, "outside")
          roof_values[:insulation_assembly_r_value] = 1.0 / ceiling_ufactor
        end
        HPXML.add_attic_roof(attic: new_attic, **roof_values)
      end

      # Table 4.2.2(1) - Ceilings
      attic.elements.each("Floors/Floor") do |floor|
        floor_values = HPXML.get_attic_floor_values(floor: floor)
        if is_external_thermal_boundary(interior_adjacent_to, floor_values[:adjacent_to])
          floor_values[:insulation_assembly_r_value] = 1.0 / ceiling_ufactor
        end
        HPXML.add_attic_floor(attic: new_attic, **floor_values)
      end

      # Table 4.2.2(1) - Above-grade walls
      attic.elements.each("Walls/Wall") do |wall|
        wall_values = HPXML.get_attic_wall_values(wall: wall)
        if is_external_thermal_boundary(interior_adjacent_to, wall_values[:adjacent_to])
          wall_values[:insulation_assembly_r_value] = 1.0 / wall_ufactor
        end
        HPXML.add_attic_wall(attic: new_attic, **wall_values)
      end
    end
  end

  def self.set_enclosure_attics_roofs_rated(orig_details, hpxml)
    orig_details.elements.each("Enclosure/Attics/Attic") do |attic|
      attic_values = HPXML.get_attic_values(attic: attic)

      if attic_values[:attic_type] == 'VentedAttic'
        if attic_values[:specific_leakage_area].nil?
          attic_values[:specific_leakage_area] = Airflow.get_default_vented_attic_sla()
        end
      end

      new_attic = HPXML.add_attic(hpxml: hpxml, **attic_values)

      attic.elements.each("Roofs/Roof") do |roof|
        roof_values = HPXML.get_attic_roof_values(roof: roof)
        HPXML.add_attic_roof(attic: new_attic, **roof_values)
      end

      attic.elements.each("Floors/Floor") do |floor|
        floor_values = HPXML.get_attic_floor_values(floor: floor)
        HPXML.add_attic_floor(attic: new_attic, **floor_values)
      end

      attic.elements.each("Walls/Wall") do |wall|
        wall_values = HPXML.get_attic_wall_values(wall: wall)
        HPXML.add_attic_wall(attic: new_attic, **wall_values)
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
        new_roof_values = HPXML.get_attic_roof_values(roof: new_roof)
        sum_roof_area += new_roof_values[:area]
      end
      new_attic.elements.each("Roofs/Roof") do |new_roof|
        new_roof_values = HPXML.get_attic_roof_values(roof: new_roof)
        roof_area = new_roof_values[:area]
        new_roof.elements["Area"].text = 1300.0 * roof_area / sum_roof_area
      end

      # Table 4.3.1(1) Configuration of Index Adjustment Design - Ceilings
      sum_floor_area = 0.0
      new_attic.elements.each("Floors/Floor") do |new_floor|
        new_floor_values = HPXML.get_attic_floor_values(floor: new_floor)
        sum_floor_area += new_floor_values[:area]
      end
      new_attic.elements.each("Floors/Floor") do |new_floor|
        new_floor_values = HPXML.get_attic_floor_values(floor: new_floor)
        floor_area = new_floor_values[:area]
        new_floor.elements["Area"].text = 1200.0 * floor_area / sum_floor_area
      end
    end
  end

  def self.set_enclosure_foundations_reference(orig_details, hpxml)
    floor_ufactor = FloorConstructions.get_default_floor_ufactor(@iecc_zone_2006)
    wall_ufactor = FoundationConstructions.get_default_basement_wall_ufactor(@iecc_zone_2006)
    slab_perim_rvalue, slab_perim_depth = FoundationConstructions.get_default_slab_perimeter_rvalue_depth(@iecc_zone_2006)
    slab_under_rvalue, slab_under_width = FoundationConstructions.get_default_slab_under_rvalue_width()

    orig_details.elements.each("Enclosure/Foundations/Foundation") do |foundation|
      foundation_values = HPXML.get_foundation_values(foundation: foundation)
      if foundation_values[:foundation_type] == "UnventedCrawlspace"
        foundation_values[:foundation_type] = "VentedCrawlspace"
      end
      interior_adjacent_to = get_foundation_adjacent_to(foundation_values[:foundation_type])

      if foundation_values[:foundation_type] == "VentedCrawlspace"
        foundation_values[:specific_leakage_area] = Airflow.get_default_vented_crawl_sla()
      end

      new_foundation = HPXML.add_foundation(hpxml: hpxml, **foundation_values)

      # Table 4.2.2(1) - Floors over unconditioned spaces or outdoor environment
      foundation.elements.each("FrameFloor") do |floor|
        floor_values = HPXML.get_frame_floor_values(floor: floor)
        if is_external_thermal_boundary(interior_adjacent_to, floor_values[:adjacent_to])
          floor_values[:insulation_assembly_r_value] = 1.0 / floor_ufactor
        end
        HPXML.add_frame_floor(foundation: new_foundation, **floor_values)
      end

      # Table 4.2.2(1) - Conditioned basement walls
      foundation.elements.each("FoundationWall") do |fwall|
        fwall_values = HPXML.get_foundation_wall_values(foundation_wall: fwall)
        # TODO: Can this just be is_external_thermal_boundary(interior_adjacent_to, exterior_adjacent_to)?
        if interior_adjacent_to == "basement - conditioned" and is_external_thermal_boundary(interior_adjacent_to, fwall_values[:adjacent_to])
          fwall_values[:insulation_assembly_r_value] = 1.0 / wall_ufactor
        end
        HPXML.add_foundation_wall(foundation: new_foundation, **fwall_values)
      end

      # Table 4.2.2(1) - Foundations
      foundation.elements.each("Slab") do |slab|
        slab_values = HPXML.get_slab_values(slab: slab)
        # TODO: Can this just be is_external_thermal_boundary(interior_adjacent_to, "ground")?
        if interior_adjacent_to == "living space" and is_external_thermal_boundary(interior_adjacent_to, "ground")
          slab_values[:perimeter_insulation_depth] = slab_perim_depth
          slab_values[:under_slab_insulation_width] = slab_under_width
          slab_values[:perimeter_insulation_r_value] = slab_perim_rvalue
          slab_values[:under_slab_insulation_r_value] = slab_under_rvalue
        end
        slab_values[:carpet_fraction] = 0.8
        slab_values[:carpet_r_value] = 2.0
        new_slab = HPXML.add_slab(foundation: new_foundation, **slab_values)
      end
    end
  end

  def self.set_enclosure_foundations_rated(orig_details, hpxml)
    min_crawlspace_sla = Airflow.get_default_vented_crawl_sla() # Reference Home vent

    orig_details.elements.each("Enclosure/Foundations/Foundation") do |foundation|
      foundation_values = HPXML.get_foundation_values(foundation: foundation)

      if foundation_values[:foundation_type] == "VentedCrawlspace"
        # Table 4.2.2(1) - Crawlspaces
        if foundation_values[:specific_leakage_area].nil?
          foundation_values[:specific_leakage_area] = Airflow.get_default_vented_crawl_sla()
        end
        # TODO: Handle approved ground cover
        if foundation_values[:specific_leakage_area] < min_crawlspace_sla
          foundation_values[:specific_leakage_area] = min_crawlspace_sla
        end
      end

      new_foundation = HPXML.add_foundation(hpxml: hpxml, **foundation_values)

      foundation.elements.each("FrameFloor") do |floor|
        floor_values = HPXML.get_frame_floor_values(floor: floor)
        HPXML.add_frame_floor(foundation: new_foundation, **floor_values)
      end

      foundation.elements.each("FoundationWall") do |fwall|
        fwall_values = HPXML.get_foundation_wall_values(foundation_wall: fwall)
        HPXML.add_foundation_wall(foundation: new_foundation, **fwall_values)
      end

      foundation.elements.each("Slab") do |slab|
        slab_values = HPXML.get_slab_values(slab: slab)
        HPXML.add_slab(foundation: new_foundation, **slab_values)
      end
    end
  end

  def self.set_enclosure_foundations_iad(hpxml)
    # Table 4.3.1(1) Configuration of Index Adjustment Design - Foundation
    floor_ufactor = FloorConstructions.get_default_floor_ufactor(@iecc_zone_2006)

    new_foundation = HPXML.add_foundation(hpxml: hpxml,
                                          id: "Foundation_Crawlspace",
                                          foundation_type: "VentedCrawlspace",
                                          specific_leakage_area: Airflow.get_default_vented_crawl_sla())

    # Ceiling
    HPXML.add_frame_floor(foundation: new_foundation,
                          id: "Foundation_Floor",
                          adjacent_to: "living space",
                          area: 1200,
                          insulation_id: "Foundation_Floor_Ins",
                          insulation_assembly_r_value: 1.0 / floor_ufactor)

    # Wall
    HPXML.add_foundation_wall(foundation: new_foundation,
                              id: "Foundation_Wall",
                              height: 2,
                              area: 2 * 34.64 * 4,
                              thickness: 8,
                              depth_below_grade: 0,
                              adjacent_to: "ground",
                              insulation_id: "Foundation_Wall_Ins",
                              insulation_assembly_r_value: 1.0 / floor_ufactor) # FIXME

    # Floor
    HPXML.add_slab(foundation: new_foundation,
                   id: "Foundation_Slab",
                   area: 1200,
                   thickness: 0,
                   exposed_perimeter: 4 * 34.64,
                   perimeter_insulation_depth: 0,
                   under_slab_insulation_width: 0,
                   depth_below_grade: 0,
                   carpet_fraction: 0,
                   carpet_r_value: 0,
                   perimeter_insulation_id: "Foundation_Slab_Perim_Ins",
                   perimeter_insulation_r_value: 0,
                   under_slab_insulation_id: "Foundation_Slab_Under_Ins",
                   under_slab_insulation_r_value: 0)
  end

  def self.set_enclosure_rim_joists_reference(orig_details, hpxml)
    # Table 4.2.2(1) - Above-grade walls
    ufactor = WallConstructions.get_default_frame_wall_ufactor(@iecc_zone_2006)

    orig_details.elements.each("Enclosure/RimJoists/RimJoist") do |rim_joist|
      rim_joist_values = HPXML.get_rim_joist_values(rim_joist: rim_joist)
      if is_external_thermal_boundary(rim_joist_values[:interior_adjacent_to], rim_joist_values[:exterior_adjacent_to])
        rim_joist_values[:insulation_assembly_r_value] = 1.0 / ufactor
      end
      HPXML.add_rim_joist(hpxml: hpxml, **rim_joist_values)
    end
  end

  def self.set_enclosure_rim_joists_rated(orig_details, hpxml)
    orig_details.elements.each("Enclosure/RimJoists/RimJoist") do |rim_joist|
      rim_joist_values = HPXML.get_rim_joist_values(rim_joist: rim_joist)
      HPXML.add_rim_joist(hpxml: hpxml, **rim_joist_values)
    end

    # Table 4.2.2(1) - Above-grade walls
    # nop
  end

  def self.get_iad_sum_external_wall_area(walls, rim_joists)
    sum_wall_area = 0.0

    walls.elements.each("Wall") do |wall|
      wall_values = HPXML.get_wall_values(wall: wall)
      if is_external_thermal_boundary(wall_values[:interior_adjacent_to], wall_values[:exterior_adjacent_to])
        sum_wall_area += wall_values[:area]
      end
    end

    if not rim_joists.nil?
      rim_joists.elements.each("RimJoist") do |rim_joist|
        rim_joist_values = HPXML.get_rim_joist_values(rim_joist: rim_joist)
        if ["basement - unconditioned", "basement - conditioned"].include? rim_joist_values[:interior_adjacent_to]
          # IAD home has crawlspace
          rim_joist_values[:interior_adjacent_to] = "crawlspace - vented"
        end
        if is_external_thermal_boundary(rim_joist_values[:interior_adjacent_to], rim_joist_values[:exterior_adjacent_to])
          sum_wall_area += rim_joist_values[:area]
        end
      end
    end

    return sum_wall_area
  end

  def self.set_enclosure_rim_joists_iad(orig_details, hpxml)
    # Table 4.3.1(1) Configuration of Index Adjustment Design - Above-grade walls
    set_enclosure_rim_joists_rated(orig_details, hpxml)

    rim_joists = orig_details.elements["Enclosure/RimJoists"]
    return if rim_joists.nil?

    walls = orig_details.elements["Enclosure/Walls"]

    sum_wall_area = get_iad_sum_external_wall_area(walls, rim_joists)

    hpxml.elements.each("Building/BuildingDetails/Enclosure/RimJoists/RimJoist") do |new_rim_joist|
      new_rim_joist_values = HPXML.get_rim_joist_values(rim_joist: new_rim_joist)
      interior_adjacent_to = new_rim_joist_values[:interior_adjacent_to]
      if ["basement - unconditioned", "basement - conditioned"].include? interior_adjacent_to
        # IAD home has crawlspace
        interior_adjacent_to = "crawlspace - vented"
        new_rim_joist.elements["InteriorAdjacentTo"].text = interior_adjacent_to
      end
      exterior_adjacent_to = new_rim_joist_values[:exterior_adjacent_to]
      if is_external_thermal_boundary(interior_adjacent_to, exterior_adjacent_to)
        rim_joist_area = new_rim_joist_values[:area]
        new_rim_joist.elements["Area"].text = 2355.52 * rim_joist_area / sum_wall_area
      end
    end
  end

  def self.set_enclosure_walls_reference(orig_details, hpxml)
    # Table 4.2.2(1) - Above-grade walls
    ufactor = WallConstructions.get_default_frame_wall_ufactor(@iecc_zone_2006)

    orig_details.elements.each("Enclosure/Walls/Wall") do |wall|
      wall_values = HPXML.get_wall_values(wall: wall)
      if is_external_thermal_boundary(wall_values[:interior_adjacent_to], wall_values[:exterior_adjacent_to])
        wall_values[:solar_absorptance] = 0.75
        wall_values[:emittance] = 0.90
        wall_values[:insulation_assembly_r_value] = 1.0 / ufactor
      end
      HPXML.add_wall(hpxml: hpxml, **wall_values)
    end
  end

  def self.set_enclosure_walls_rated(orig_details, hpxml)
    orig_details.elements.each("Enclosure/Walls/Wall") do |wall|
      wall_values = HPXML.get_wall_values(wall: wall)
      HPXML.add_wall(hpxml: hpxml, **wall_values)
    end

    # Table 4.2.2(1) - Above-grade walls
    # nop
  end

  def self.set_enclosure_walls_iad(orig_details, hpxml)
    # Table 4.3.1(1) Configuration of Index Adjustment Design - Above-grade walls
    set_enclosure_walls_rated(orig_details, hpxml)

    walls = orig_details.elements["Enclosure/Walls"]
    rim_joists = orig_details.elements["Enclosure/RimJoists"]

    sum_wall_area = get_iad_sum_external_wall_area(walls, rim_joists)

    hpxml.elements.each("Building/BuildingDetails/Enclosure/Walls/Wall") do |new_wall|
      new_wall_values = HPXML.get_wall_values(wall: new_wall)
      interior_adjacent_to = new_wall_values[:interior_adjacent_to]
      exterior_adjacent_to = new_wall_values[:exterior_adjacent_to]
      if is_external_thermal_boundary(interior_adjacent_to, exterior_adjacent_to)
        wall_area = new_wall_values[:area]
        new_wall.elements["Area"].text = 2355.52 * wall_area / sum_wall_area
      end
    end
  end

  def self.set_enclosure_windows_reference(orig_details, hpxml)
    # Table 4.2.2(1) - Glazing
    ufactor, shgc = SubsurfaceConstructions.get_default_ufactor_shgc(@iecc_zone_2006)

    ag_wall_area = 0.0
    bg_wall_area = 0.0

    orig_details.elements.each("Enclosure/Walls/Wall") do |wall|
      wall_values = HPXML.get_wall_values(wall: wall)
      next if not is_external_thermal_boundary(wall_values[:interior_adjacent_to], wall_values[:exterior_adjacent_to])

      ag_wall_area += wall_values[:area]
    end

    orig_details.elements.each("Enclosure/RimJoists/RimJoist") do |rim_joist|
      rim_joist_values = HPXML.get_rim_joist_values(rim_joist: rim_joist)
      next if not is_external_thermal_boundary(rim_joist_values[:interior_adjacent_to], rim_joist_values[:exterior_adjacent_to])

      ag_wall_area += rim_joist_values[:area]
    end

    orig_details.elements.each("Enclosure/Foundations/Foundation[FoundationType/Basement/Conditioned='true']/FoundationWall") do |fwall|
      fwall_values = HPXML.get_foundation_wall_values(foundation_wall: fwall)
      next if not is_external_thermal_boundary("basement - conditioned", fwall_values[:adjacent_to])

      height = fwall_values[:height]
      bg_depth = fwall_values[:depth_below_grade]
      area = fwall_values[:area]
      ag_wall_area += (height - bg_depth) / height * area
      bg_wall_area += bg_depth / height * area
    end

    fa = ag_wall_area / (ag_wall_area + 0.5 * bg_wall_area)
    f = 1.0 # TODO

    total_window_area = 0.18 * @cfa * fa * f

    wall_area_fracs = get_exterior_wall_area_fracs(orig_details)

    shade_summer, shade_winter = SubsurfaceConstructions.get_default_interior_shading_factors()

    # Create new windows
    for orientation, azimuth in { "north" => 0, "south" => 180, "east" => 90, "west" => 270 }
      window_area = 0.25 * total_window_area # Equal distribution to N/S/E/W
      # Distribute this orientation's window area proportionally across all exterior walls
      wall_area_fracs.each do |wall, wall_area_frac|
        wall_id = HPXML.get_id(wall)
        HPXML.add_window(hpxml: hpxml,
                         id: "Window_#{wall_id}_#{orientation}",
                         area: window_area * wall_area_frac,
                         azimuth: azimuth,
                         ufactor: ufactor,
                         shgc: shgc,
                         wall_idref: wall_id,
                         interior_shading_factor_summer: shade_summer,
                         interior_shading_factor_winter: shade_winter)
      end
    end
  end

  def self.set_enclosure_windows_rated(orig_details, hpxml)
    # Table 4.2.2(1) - Glazing
    shade_summer, shade_winter = SubsurfaceConstructions.get_default_interior_shading_factors()
    orig_details.elements.each("Enclosure/Windows/Window") do |window|
      window_values = HPXML.get_window_values(window: window)
      window_values[:interior_shading_factor_summer] = shade_summer
      window_values[:interior_shading_factor_winter] = shade_winter
      new_window = HPXML.add_window(hpxml: hpxml, **window_values)
    end
  end

  def self.set_enclosure_windows_iad(orig_details, hpxml)
    # Table 4.3.1(1) Configuration of Index Adjustment Design - Glazing
    total_window_area = 0.18 * @cfa

    wall_area_fracs = get_exterior_wall_area_fracs(orig_details)

    shade_summer, shade_winter = SubsurfaceConstructions.get_default_interior_shading_factors()

    # Calculate area-weighted averages
    sum_u_a = 0.0
    sum_shgc_a = 0.0
    sum_a = 0.0
    orig_details.elements.each("Enclosure/Windows/Window") do |new_window|
      new_window_values = HPXML.get_window_values(window: new_window)
      window_area = new_window_values[:area]
      sum_a += window_area
      sum_u_a += (window_area * new_window_values[:ufactor])
      sum_shgc_a += (window_area * new_window_values[:shgc])
    end
    avg_u = sum_u_a / sum_a
    avg_shgc = sum_shgc_a / sum_a

    # Create new windows
    for orientation, azimuth in { "north" => 0, "south" => 180, "east" => 90, "west" => 270 }
      window_area = 0.25 * total_window_area # Equal distribution to N/S/E/W
      # Distribute this orientation's window area proportionally across all exterior walls
      wall_area_fracs.each do |wall, wall_area_frac|
        wall_id = HPXML.get_id(wall)
        HPXML.add_window(hpxml: hpxml,
                         id: "Window_#{wall_id}_#{orientation}",
                         area: window_area * wall_area_frac,
                         azimuth: azimuth,
                         ufactor: avg_u,
                         shgc: avg_shgc,
                         wall_idref: wall_id,
                         interior_shading_factor_summer: shade_summer,
                         interior_shading_factor_winter: shade_winter)
      end
    end
  end

  def self.set_enclosure_skylights_reference(hpxml)
    # Table 4.2.2(1) - Skylights
    # nop
  end

  def self.set_enclosure_skylights_rated(orig_details, hpxml)
    # Table 4.2.2(1) - Skylights
    orig_details.elements.each("Enclosure/Skylights/Skylight") do |skylight|
      skylight_values = HPXML.get_skylight_values(skylight: skylight)
      HPXML.add_skylight(hpxml: hpxml, **skylight_values)
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

      HPXML.add_door(hpxml: hpxml,
                     id: "Door_#{wall_id}",
                     wall_idref: wall_id,
                     area: door_area * wall_area_frac,
                     azimuth: 0,
                     r_value: 1.0 / ufactor)
    end
  end

  def self.set_enclosure_doors_rated(orig_details, hpxml)
    # Table 4.2.2(1) - Doors
    orig_details.elements.each("Enclosure/Doors/Door") do |door|
      door_values = HPXML.get_door_values(door: door)
      HPXML.add_door(hpxml: hpxml, **door_values)
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
    orig_details.elements.each("Systems/HVAC/HVACPlant/HeatingSystem") do |heating|
      heating_values = HPXML.get_heating_system_values(heating_system: heating)
      next unless heating_values[:heating_system_fuel] != "electricity"

      if heating_values[:heating_system_type] == "Boiler"
        add_reference_heating_gas_boiler(hpxml, heating_values[:fraction_heat_load_served], heating_values[:id])
      else
        add_reference_heating_gas_furnace(hpxml, heating_values[:fraction_heat_load_served], heating_values[:id])
      end
    end
    if orig_details.elements["Systems/HVAC/HVACPlant/HeatingSystem"].nil? and orig_details.elements["Systems/HVAC/HVACPlant/HeatPump[FractionHeatLoadServed > 0]"].nil?
      if has_fuel
        add_reference_heating_gas_furnace(hpxml)
      end
    end

    # Cooling
    orig_details.elements.each("Systems/HVAC/HVACPlant/CoolingSystem") do |cooling|
      cooling_values = HPXML.get_cooling_system_values(cooling_system: cooling)
      add_reference_cooling_air_conditioner(hpxml, cooling_values[:fraction_cool_load_served], cooling_values[:id])
    end
    orig_details.elements.each("Systems/HVAC/HVACPlant/HeatPump[FractionCoolLoadServed > 0]") do |hp|
      hp_values = HPXML.get_heat_pump_values(heat_pump: hp)
      add_reference_cooling_air_conditioner(hpxml, hp_values[:fraction_cool_load_served], hp_values[:id])
    end
    if orig_details.elements["Systems/HVAC/HVACPlant/CoolingSystem"].nil? and orig_details.elements["Systems/HVAC/HVACPlant/HeatPump[FractionCoolLoadServed > 0]"].nil?
      add_reference_cooling_air_conditioner(hpxml)
    end

    # HeatPump
    orig_details.elements.each("Systems/HVAC/HVACPlant/HeatingSystem") do |heating|
      heating_values = HPXML.get_heating_system_values(heating_system: heating)
      next unless heating_values[:heating_system_fuel] == "electricity"

      add_reference_heating_heat_pump(hpxml, heating_values[:fraction_heat_load_served], heating_values[:id])
    end
    orig_details.elements.each("Systems/HVAC/HVACPlant/HeatPump[FractionHeatLoadServed > 0]") do |hp|
      hp_values = HPXML.get_heat_pump_values(heat_pump: hp)
      add_reference_heating_heat_pump(hpxml, hp_values[:fraction_heat_load_served], hp_values[:id])
    end
    if orig_details.elements["Systems/HVAC/HVACPlant/HeatingSystem"].nil? and orig_details.elements["Systems/HVAC/HVACPlant/HeatPump[FractionHeatLoadServed > 0]"].nil?
      if not has_fuel
        add_reference_heating_heat_pump(hpxml)
      end
    end

    # Table 303.4.1(1) - Thermostat
    HPXML.add_hvac_control(hpxml: hpxml,
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
      orig_details.elements.each("Systems/HVAC/HVACPlant/HeatingSystem") do |heating|
        heating_values = HPXML.get_heating_system_values(heating_system: heating)
        HPXML.add_heating_system(hpxml: hpxml, **heating_values)
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
      orig_details.elements.each("Systems/HVAC/HVACPlant/CoolingSystem") do |cooling|
        cooling_values = HPXML.get_cooling_system_values(cooling_system: cooling)
        HPXML.add_cooling_system(hpxml: hpxml, **cooling_values)
      end
    end
    if cooling_system.nil? and heat_pump.nil?
      add_reference_cooling_air_conditioner(hpxml)
      added_reference_cooling = true
    end

    # HeatPump
    if not heat_pump.nil?
      # Retain heat pump(s)
      orig_details.elements.each("Systems/HVAC/HVACPlant/HeatPump") do |hp|
        hp_values = HPXML.get_heat_pump_values(heat_pump: hp)
        HPXML.add_heat_pump(hpxml: hpxml, **hp_values)
      end
    end
    if heating_system.nil? and heat_pump.nil? and not has_fuel_access(orig_details)
      add_reference_heating_heat_pump(hpxml)
      added_reference_heating = true
    end

    # Table 303.4.1(1) - Thermostat
    hvac_control = orig_details.elements["Systems/HVAC/HVACControl"]
    if not hvac_control.nil?
      hvac_control_values = HPXML.get_hvac_control_values(hvac_control: hvac_control)
      HPXML.add_hvac_control(hpxml: hpxml, **hvac_control_values)
    else
      HPXML.add_hvac_control(hpxml: hpxml,
                             id: "HVACControl",
                             control_type: "manual thermostat")
    end

    # Table 4.2.2(1) - Thermal distribution systems
    orig_details.elements.each("Systems/HVAC/HVACDistribution") do |dist|
      dist_values = HPXML.get_hvac_distribution_values(hvac_distribution: dist)
      new_hvac_dist = HPXML.add_hvac_distribution(hpxml: hpxml, **dist_values)
      if dist_values[:distribution_system_type] == "AirDistribution"
        new_air_dist = new_hvac_dist.elements["DistributionSystemType/AirDistribution"]
        dist.elements.each("DistributionSystemType/AirDistribution/DuctLeakageMeasurement") do |duct_leakage_measurement|
          duct_leakage_measurement_values = HPXML.get_duct_leakage_measurement_values(duct_leakage_measurement: duct_leakage_measurement)
          HPXML.add_duct_leakage_measurement(air_distribution: new_air_dist, **duct_leakage_measurement_values)
        end
        dist.elements.each("DistributionSystemType/AirDistribution/Ducts") do |ducts|
          ducts_values = HPXML.get_ducts_values(ducts: ducts)
          HPXML.add_ducts(air_distribution: new_air_dist, **ducts_values)
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

    vent_fan = orig_details.elements["Systems/MechanicalVentilation/VentilationFans/VentilationFan[UsedForWholeBuildingVentilation='true']"]
    return if vent_fan.nil?

    vent_fan_values = HPXML.get_ventilation_fan_values(ventilation_fan: vent_fan)

    fan_type = vent_fan_values[:fan_type]

    q_tot = Airflow.get_mech_vent_whole_house_cfm(1.0, @nbeds, @cfa, '2013')

    # Calculate fan cfm for airflow rate using Reference Home infiltration
    # http://www.resnet.us/standards/Interpretation_on_Reference_Home_Air_Exchange_Rate_approved.pdf
    sla = 0.00036
    q_fan_airflow = calc_mech_vent_q_fan(q_tot, sla, @ncfl * 8.2)

    # Calculate fan cfm for fan power using Rated Home infiltration
    # http://www.resnet.us/standards/Interpretation_on_Reference_Home_mechVent_fanCFM_approved.pdf
    orig_details.elements.each("Enclosure/AirInfiltration/AirInfiltrationMeasurement") do |air_infiltration_measurement|
      air_infiltration_measurement_values = HPXML.get_air_infiltration_measurement_values(air_infiltration_measurement: air_infiltration_measurement)
      if air_infiltration_measurement_values[:unit_of_measure] == 'ACHnatural'
        nach = air_infiltration_measurement_values[:air_leakage]
        sla = Airflow.get_infiltration_SLA_from_ACH(nach, @ncfl, @weather)
        break
      elsif air_infiltration_measurement_values[:unit_of_measure] == 'ACH' and air_infiltration_measurement_values[:house_pressure] == 50
        ach50 = air_infiltration_measurement_values[:air_leakage]
        sla = Airflow.get_infiltration_SLA_from_ACH50(ach50, 0.65, @cfa, @infilvolume)
        break
      end
    end
    q_fan_power = calc_mech_vent_q_fan(q_tot, sla, @ncfl * 8.2)

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

    HPXML.add_ventilation_fan(hpxml: hpxml,
                              id: HPXML.get_id(vent_fan),
                              fan_type: fan_type,
                              rated_flow_rate: q_fan_airflow,
                              hours_in_operation: 24, # TODO: CFIS
                              fan_power: fan_power_w,
                              distribution_system_idref: vent_fan_values[:distribution_system_idref])
  end

  def self.set_systems_mechanical_ventilation_rated(orig_details, hpxml)
    # Table 4.2.2(1) - Whole-House Mechanical ventilation
    vent_fan = orig_details.elements["Systems/MechanicalVentilation/VentilationFans/VentilationFan[UsedForWholeBuildingVentilation='true']"]
    if not vent_fan.nil?
      vent_fan_values = HPXML.get_ventilation_fan_values(ventilation_fan: vent_fan)
      HPXML.add_ventilation_fan(hpxml: hpxml, **vent_fan_values)
    end
  end

  def self.set_systems_mechanical_ventilation_iad(orig_details, hpxml)
    # Table 4.3.1(1) Configuration of Index Adjustment Design - Whole-House Mechanical ventilation fan energy
    # Table 4.3.1(1) Configuration of Index Adjustment Design - Air exchange rate

    q_tot = Airflow.get_mech_vent_whole_house_cfm(1.0, @nbeds, @cfa, '2013')

    # Calculate fan cfm
    sla = nil
    hpxml.elements.each("Building/BuildingDetails/Enclosure/AirInfiltration/AirInfiltrationMeasurement") do |air_infiltration_measurement|
      air_infiltration_measurement_values = HPXML.get_air_infiltration_measurement_values(air_infiltration_measurement: air_infiltration_measurement)
      if air_infiltration_measurement_values[:unit_of_measure] == 'ACH' and air_infiltration_measurement_values[:house_pressure] == 50
        ach50 = air_infiltration_measurement_values[:air_leakage]
        sla = Airflow.get_infiltration_SLA_from_ACH50(ach50, 0.65, @cfa, @infilvolume)
        break
      end
    end
    q_fan = calc_mech_vent_q_fan(q_tot, sla, 17.0)

    w_cfm = 0.70
    fan_power_w = w_cfm * q_fan

    HPXML.add_ventilation_fan(hpxml: hpxml,
                              id: "VentilationFan",
                              fan_type: "balanced",
                              rated_flow_rate: q_fan,
                              hours_in_operation: 24,
                              fan_power: fan_power_w)
  end

  def self.set_systems_water_heater_reference(orig_details, hpxml)
    # Table 4.2.2(1) - Service water heating systems

    orig_details.elements.each("Systems/WaterHeating/WaterHeatingSystem") do |wh_sys|
      wh_sys_values = HPXML.get_water_heating_system_values(water_heating_system: wh_sys)

      if wh_sys_values[:water_heater_type] == 'instantaneous water heater'
        wh_sys_values[:tank_volume] = 40.0
      end
      wh_sys_values[:water_heater_type] = 'storage water heater'

      wh_sys_values[:energy_factor], wh_sys_values[:recovery_efficiency] = get_water_heater_ef_and_re(wh_sys_values[:fuel_type], wh_sys_values[:tank_volume])
      wh_sys_values[:heating_capacity] = Waterheater.calc_water_heater_capacity(to_beopt_fuel(wh_sys_values[:fuel_type]), @nbeds) * 1000.0 # Btuh

      # New water heater
      HPXML.add_water_heating_system(hpxml: hpxml, **wh_sys_values)
    end

    if orig_details.elements["Systems/WaterHeating/WaterHeatingSystem"].nil?
      add_reference_water_heater(orig_details, hpxml)
    end
  end

  def self.set_systems_water_heater_rated(orig_details, hpxml)
    # Table 4.2.2(1) - Service water heating systems

    orig_details.elements.each("Systems/WaterHeating/WaterHeatingSystem") do |wh_sys|
      wh_sys_values = HPXML.get_water_heating_system_values(water_heating_system: wh_sys)

      if wh_sys_values[:energy_factor].nil?
        wh_uef = wh_sys_values[:uniform_energy_factor]
        wh_sys_values[:energy_factor] = Waterheater.calc_ef_from_uef(wh_uef, to_beopt_wh_type(wh_sys_values[:water_heater_type]), to_beopt_fuel(wh_sys_values[:fuel_type]))
        wh_sys_values[:uniform_energy_factor] = nil
      end

      # New water heater
      HPXML.add_water_heating_system(hpxml: hpxml, **wh_sys_values)
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

    water_heating = orig_details.elements["Systems/WaterHeating"]

    has_uncond_bsmnt = (not orig_details.elements["Enclosure/Foundations/FoundationType/Basement[Conditioned='false']"].nil?)
    standard_piping_length = HotWaterAndAppliances.get_default_std_pipe_length(has_uncond_bsmnt, @cfa, @ncfl)

    if water_heating.nil?
      sys_id = "HotWaterDistribution"
    else
      hw_dist_values = HPXML.get_hot_water_distribution_values(hot_water_distribution: water_heating.elements["HotWaterDistribution"])
      sys_id = hw_dist_values[:id]
    end

    # New hot water distribution
    HPXML.add_hot_water_distribution(hpxml: hpxml,
                                     id: sys_id,
                                     system_type: "Standard",
                                     pipe_r_value: 0,
                                     standard_piping_length: standard_piping_length)

    # New water fixtures
    if water_heating.nil?
      # Shower Head
      HPXML.add_water_fixture(hpxml: hpxml,
                              id: "ShowerHead",
                              water_fixture_type: "shower head",
                              low_flow: false)

      # Faucet
      HPXML.add_water_fixture(hpxml: hpxml,
                              id: "Faucet",
                              water_fixture_type: "faucet",
                              low_flow: false)
    else
      water_heating.elements.each("WaterFixture[WaterFixtureType='shower head' or WaterFixtureType='faucet']") do |fixture|
        fixture_values = HPXML.get_water_fixture_values(water_fixture: fixture)
        fixture_values[:low_flow] = false
        HPXML.add_water_fixture(hpxml: hpxml, **fixture_values)
      end
    end
  end

  def self.set_systems_water_heating_use_rated(orig_details, hpxml)
    # Table 4.2.2(1) - Service water heating systems

    water_heating = orig_details.elements["Systems/WaterHeating"]
    if water_heating.nil?
      set_systems_water_heating_use_reference(orig_details, hpxml)
      return
    end

    hw_dist = water_heating.elements["HotWaterDistribution"]
    hw_dist_values = HPXML.get_hot_water_distribution_values(hot_water_distribution: hw_dist)

    has_uncond_bsmnt = (not orig_details.elements["Enclosure/Foundations/FoundationType/Basement[Conditioned='false']"].nil?)
    std_pipe_length = HotWaterAndAppliances.get_default_std_pipe_length(has_uncond_bsmnt, @cfa, @ncfl)
    recirc_pipe_length = HotWaterAndAppliances.get_default_recirc_loop_length(std_pipe_length)

    if hw_dist_values[:system_type] == "Standard" and hw_dist_values[:standard_piping_length].nil?
      hw_dist_values[:standard_piping_length] = std_pipe_length
    elsif hw_dist_values[:system_type] == "Recirculation" and hw_dist_values[:recirculation_piping_length].nil?
      hw_dist_values[:recirculation_piping_length] = recirc_pipe_length
    end

    # New hot water distribution
    HPXML.add_hot_water_distribution(hpxml: hpxml, **hw_dist_values)

    # New water fixtures
    water_heating.elements.each("WaterFixture[WaterFixtureType='shower head' or WaterFixtureType='faucet']") do |fixture|
      fixture_values = HPXML.get_water_fixture_values(water_fixture: fixture)
      HPXML.add_water_fixture(hpxml: hpxml, **fixture_values)
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
    orig_details.elements.each("Systems/Photovoltaics/PVSystem") do |pv|
      pv_values = HPXML.get_pv_system_values(pv_system: pv)
      HPXML.add_pv_system(hpxml: hpxml, **pv_values)
    end
  end

  def self.set_systems_photovoltaics_iad(hpxml)
    # 4.3.1 Index Adjustment Design (IAD)
    # Renewable Energy Systems that offset the energy consumption requirements of the Rated Home shall not be included in the IAD.
    # nop
  end

  def self.set_appliances_clothes_washer_reference(orig_details, hpxml)
    washer_values = HPXML.get_clothes_washer_values(clothes_washer: orig_details.elements["Appliances/ClothesWasher"])

    HPXML.add_clothes_washer(hpxml: hpxml,
                             id: washer_values[:id],
                             location: "living space",
                             modified_energy_factor: HotWaterAndAppliances.get_clothes_washer_reference_mef(),
                             rated_annual_kwh: HotWaterAndAppliances.get_clothes_washer_reference_ler(),
                             label_electric_rate: HotWaterAndAppliances.get_clothes_washer_reference_elec_rate(),
                             label_gas_rate: HotWaterAndAppliances.get_clothes_washer_reference_gas_rate(),
                             label_annual_gas_cost: HotWaterAndAppliances.get_clothes_washer_reference_agc(),
                             capacity: HotWaterAndAppliances.get_clothes_washer_reference_cap())
  end

  def self.set_appliances_clothes_washer_rated(orig_details, hpxml)
    washer_values = HPXML.get_clothes_washer_values(clothes_washer: orig_details.elements["Appliances/ClothesWasher"])

    if washer_values[:modified_energy_factor].nil? and washer_values[:integrated_modified_energy_factor].nil?
      self.set_appliances_clothes_washer_reference(orig_details, hpxml)
      return
    end

    HPXML.add_clothes_washer(hpxml: hpxml, **washer_values)
  end

  def self.set_appliances_clothes_washer_iad(orig_details, hpxml)
    # Table 4.3.1(1) Configuration of Index Adjustment Design - Lighting, Appliances and Miscellaneous Electric Loads (MELs)
    self.set_appliances_clothes_washer_reference(orig_details, hpxml)
  end

  def self.set_appliances_clothes_dryer_reference(orig_details, hpxml)
    dryer_values = HPXML.get_clothes_dryer_values(clothes_dryer: orig_details.elements["Appliances/ClothesDryer"])

    cd_ef = HotWaterAndAppliances.get_clothes_dryer_reference_ef(to_beopt_fuel(dryer_values[:fuel_type]))
    cd_control = HotWaterAndAppliances.get_clothes_dryer_reference_control()

    HPXML.add_clothes_dryer(hpxml: hpxml,
                            id: dryer_values[:id],
                            location: "living space",
                            fuel_type: dryer_values[:fuel_type],
                            energy_factor: cd_ef,
                            control_type: cd_control)
  end

  def self.set_appliances_clothes_dryer_rated(orig_details, hpxml)
    dryer_values = HPXML.get_clothes_dryer_values(clothes_dryer: orig_details.elements["Appliances/ClothesDryer"])

    if dryer_values[:energy_factor].nil? and dryer_values[:combined_energy_factor].nil?
      self.set_appliances_clothes_dryer_reference(orig_details, hpxml)
      return
    end

    HPXML.add_clothes_dryer(hpxml: hpxml, **dryer_values)
  end

  def self.set_appliances_clothes_dryer_iad(orig_details, hpxml)
    # Table 4.3.1(1) Configuration of Index Adjustment Design - Lighting, Appliances and Miscellaneous Electric Loads (MELs)
    self.set_appliances_clothes_dryer_reference(orig_details, hpxml)
  end

  def self.set_appliances_dishwasher_reference(orig_details, hpxml)
    dishwasher_values = HPXML.get_dishwasher_values(dishwasher: orig_details.elements["Appliances/Dishwasher"])

    HPXML.add_dishwasher(hpxml: hpxml,
                         id: dishwasher_values[:id],
                         energy_factor: HotWaterAndAppliances.get_dishwasher_reference_ef(),
                         place_setting_capacity: HotWaterAndAppliances.get_dishwasher_reference_cap())
  end

  def self.set_appliances_dishwasher_rated(orig_details, hpxml)
    dishwasher_values = HPXML.get_dishwasher_values(dishwasher: orig_details.elements["Appliances/Dishwasher"])

    if dishwasher_values[:energy_factor].nil? and dishwasher_values[:rated_annual_kwh].nil?
      self.set_appliances_dishwasher_reference(orig_details, hpxml)
      return
    end

    HPXML.add_dishwasher(hpxml: hpxml, **dishwasher_values)
  end

  def self.set_appliances_dishwasher_iad(orig_details, hpxml)
    # Table 4.3.1(1) Configuration of Index Adjustment Design - Lighting, Appliances and Miscellaneous Electric Loads (MELs)
    self.set_appliances_dishwasher_reference(orig_details, hpxml)
  end

  def self.set_appliances_refrigerator_reference(orig_details, hpxml)
    fridge_values = HPXML.get_refrigerator_values(refrigerator: orig_details.elements["Appliances/Refrigerator"])

    # Table 4.2.2.5(1) Lighting, Appliance and Miscellaneous Electric Loads in electric ERI Reference Homes
    refrigerator_kwh = HotWaterAndAppliances.get_refrigerator_reference_annual_kwh(@nbeds)

    HPXML.add_refrigerator(hpxml: hpxml,
                           id: fridge_values[:id],
                           location: "living space",
                           rated_annual_kwh: refrigerator_kwh)
  end

  def self.set_appliances_refrigerator_rated(orig_details, hpxml)
    fridge_values = HPXML.get_refrigerator_values(refrigerator: orig_details.elements["Appliances/Refrigerator"])

    if fridge_values[:rated_annual_kwh].nil?
      self.set_appliances_refrigerator_reference(orig_details, hpxml)
      return
    end

    HPXML.add_refrigerator(hpxml: hpxml, **fridge_values)
  end

  def self.set_appliances_refrigerator_iad(orig_details, hpxml)
    # Table 4.3.1(1) Configuration of Index Adjustment Design - Lighting, Appliances and Miscellaneous Electric Loads (MELs)
    self.set_appliances_refrigerator_reference(orig_details, hpxml)
  end

  def self.set_appliances_cooking_range_oven_reference(orig_details, hpxml)
    range_values = HPXML.get_cooking_range_values(cooking_range: orig_details.elements["Appliances/CookingRange"])
    oven_values = HPXML.get_oven_values(oven: orig_details.elements["Appliances/Oven"])

    HPXML.add_cooking_range(hpxml: hpxml,
                            id: range_values[:id],
                            fuel_type: range_values[:fuel_type],
                            is_induction: HotWaterAndAppliances.get_range_oven_reference_is_induction())

    HPXML.add_oven(hpxml: hpxml,
                   id: oven_values[:id],
                   is_convection: HotWaterAndAppliances.get_range_oven_reference_is_convection())
  end

  def self.set_appliances_cooking_range_oven_rated(orig_details, hpxml)
    range_values = HPXML.get_cooking_range_values(cooking_range: orig_details.elements["Appliances/CookingRange"])
    oven_values = HPXML.get_oven_values(oven: orig_details.elements["Appliances/Oven"])

    if range_values[:is_induction].nil?
      self.set_appliances_cooking_range_oven_reference(orig_details, hpxml)
      return
    end

    HPXML.add_cooking_range(hpxml: hpxml, **range_values)

    HPXML.add_oven(hpxml: hpxml, **oven_values)
  end

  def self.set_appliances_cooking_range_oven_iad(orig_details, hpxml)
    # Table 4.3.1(1) Configuration of Index Adjustment Design - Lighting, Appliances and Miscellaneous Electric Loads (MELs)
    self.set_appliances_cooking_range_oven_reference(orig_details, hpxml)
  end

  def self.set_lighting_reference(orig_details, hpxml)
    fFI_int, fFI_ext, fFI_grg, fFII_int, fFII_ext, fFII_grg = Lighting.get_reference_fractions()

    HPXML.add_lighting(hpxml: hpxml,
                       fraction_tier_i_interior: fFI_int,
                       fraction_tier_i_exterior: fFI_ext,
                       fraction_tier_i_garage: fFI_grg,
                       fraction_tier_ii_interior: fFII_int,
                       fraction_tier_ii_exterior: fFII_ext,
                       fraction_tier_ii_garage: fFII_grg)
  end

  def self.set_lighting_rated(orig_details, hpxml)
    lighting = orig_details.elements["Lighting"]
    lighting_values = HPXML.get_lighting_values(lighting: lighting)

    fFI_int, fFI_ext, fFI_grg, fFII_int, fFII_ext, fFII_grg = Lighting.get_reference_fractions()

    if lighting_values[:fraction_tier_i_interior].nil?
      lighting_values[:fraction_tier_i_interior] = fFI_int
    end
    if lighting_values[:fraction_tier_i_exterior].nil?
      lighting_values[:fraction_tier_i_exterior] = fFI_ext
    end
    if lighting_values[:fraction_tier_i_garage].nil?
      lighting_values[:fraction_tier_i_garage] = fFI_grg
    end
    if lighting_values[:fraction_tier_ii_interior].nil?
      lighting_values[:fraction_tier_ii_interior] = fFII_int
    end
    if lighting_values[:fraction_tier_ii_exterior].nil?
      lighting_values[:fraction_tier_ii_exterior] = fFII_ext
    end
    if lighting_values[:fraction_tier_ii_garage].nil?
      lighting_values[:fraction_tier_ii_garage] = fFII_grg
    end

    # For rating purposes, the Rated Home shall not have qFFIL less than 0.10 (10%).
    if lighting_values[:fraction_tier_i_interior] + lighting_values[:fraction_tier_ii_interior] < 0.1
      lighting_values[:fraction_tier_i_interior] = 0.1 - lighting_values[:fraction_tier_ii_interior]
    end

    HPXML.add_lighting(hpxml: hpxml, **lighting_values)
  end

  def self.set_lighting_iad(orig_details, hpxml)
    fFI_int, fFI_ext, fFI_grg, fFII_int, fFII_ext, fFII_grg = Lighting.get_iad_fractions()

    HPXML.add_lighting(hpxml: hpxml,
                       fraction_tier_i_interior: fFI_int,
                       fraction_tier_i_exterior: fFI_ext,
                       fraction_tier_i_garage: fFI_grg,
                       fraction_tier_ii_interior: fFII_int,
                       fraction_tier_ii_exterior: fFII_ext,
                       fraction_tier_ii_garage: fFII_grg)
  end

  def self.set_ceiling_fans_reference(orig_details, hpxml)
    return if orig_details.elements["Lighting/CeilingFan"].nil?

    medium_cfm = 3000.0

    HPXML.add_ceiling_fan(hpxml: hpxml,
                          id: "CeilingFans",
                          efficiency: medium_cfm / HVAC.get_default_ceiling_fan_power(),
                          quantity: HVAC.get_default_ceiling_fan_quantity(@nbeds))
  end

  def self.set_ceiling_fans_rated(orig_details, hpxml)
    return if orig_details.elements["Lighting/CeilingFan"].nil?

    medium_cfm = 3000.0

    # Calculate average ceiling fan wattage
    sum_w = 0.0
    num_cfs = 0
    orig_details.elements.each("Lighting/CeilingFan") do |cf|
      cf_values = HPXML.get_ceiling_fan_values(ceiling_fan: cf)
      cf_quantity = cf_values[:quantity]
      num_cfs += cf_quantity
      cfm_per_w = cf_values[:efficiency]
      if cfm_per_w.nil?
        fan_power_w = HVAC.get_default_ceiling_fan_power()
        cfm_per_w = medium_cfm / fan_power_w
      end
      sum_w += (medium_cfm / cfm_per_w * cf_quantity)
    end
    avg_w = sum_w / num_cfs

    HPXML.add_ceiling_fan(hpxml: hpxml,
                          id: "CeilingFans",
                          efficiency: medium_cfm / avg_w,
                          quantity: HVAC.get_default_ceiling_fan_quantity(@nbeds))
  end

  def self.set_ceiling_fans_iad(orig_details, hpxml)
    # Not described in Addendum E; use Reference Home?
    set_ceiling_fans_reference(orig_details, hpxml)
  end

  def self.set_misc_loads_reference(hpxml)
    # Misc
    HPXML.add_plug_load(hpxml: hpxml,
                        id: "MiscPlugLoad",
                        plug_load_type: "other")

    # Television
    HPXML.add_plug_load(hpxml: hpxml,
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

  def self.calc_mech_vent_q_fan(q_tot, sla, vert_distance)
    nl = 1000.0 * sla * (vert_distance / 8.2)**0.4 # Normalized leakage, eq. 4.4
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
                                        distribution_system_idref: "HVACDistribution_DSE_80",
                                        heating_system_type: "Furnace",
                                        heating_system_fuel: "natural gas",
                                        heating_capacity: -1, # Use Manual J auto-sizing
                                        heating_efficiency_units: "AFUE",
                                        heating_efficiency_value: 0.78,
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
                                        distribution_system_idref: "HVACDistribution_DSE_80",
                                        heating_system_type: "Boiler",
                                        heating_system_fuel: "natural gas",
                                        heating_capacity: -1, # Use Manual J auto-sizing
                                        heating_efficiency_units: "AFUE",
                                        heating_efficiency_value: 0.80,
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
                                    distribution_system_idref: "HVACDistribution_DSE_80",
                                    heat_pump_type: "air-to-air",
                                    heat_pump_fuel: "electricity",
                                    cooling_capacity: -1, # Use Manual J auto-sizing
                                    fraction_heat_load_served: load_frac,
                                    fraction_cool_load_served: 0.0,
                                    cooling_efficiency_units: "SEER",
                                    cooling_efficiency_value: 13.0, # Arbitrary, not used
                                    heating_efficiency_units: "HSPF",
                                    heating_efficiency_value: 7.7)
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
                                        distribution_system_idref: "HVACDistribution_DSE_80",
                                        cooling_system_type: "central air conditioning",
                                        cooling_system_fuel: "electricity",
                                        cooling_capacity: -1, # Use Manual J auto-sizing
                                        fraction_cool_load_served: load_frac,
                                        cooling_efficiency_units: "SEER",
                                        cooling_efficiency_value: 13.0)
    if not seed_id.nil? and [Constants.CalcTypeERIReferenceHome,
                             Constants.CalcTypeERIIndexAdjustmentReferenceHome].include? @calc_type
      # Map reference home system back to rated home system
      HPXML.add_extension(parent: cool_sys,
                          extensions: { "SeedId": seed_id })
    end
  end

  def self.add_reference_distribution_system(hpxml)
    # Table 4.2.2(1) - Thermal distribution systems
    HPXML.add_hvac_distribution(hpxml: hpxml,
                                id: "HVACDistribution_DSE_80",
                                distribution_system_type: "DSE",
                                annual_heating_dse: 0.8,
                                annual_cooling_dse: 0.8)
  end

  def self.add_reference_water_heater(orig_details, hpxml)
    wh_fuel_type = get_predominant_heating_fuel(orig_details)
    wh_tank_vol = 40.0

    wh_ef, wh_re = get_water_heater_ef_and_re(wh_fuel_type, wh_tank_vol)
    wh_cap = Waterheater.calc_water_heater_capacity(to_beopt_fuel(wh_fuel_type), @nbeds) * 1000.0 # Btuh

    HPXML.add_water_heating_system(hpxml: hpxml,
                                   id: 'WaterHeatingSystem',
                                   fuel_type: wh_fuel_type,
                                   water_heater_type: 'storage water heater',
                                   location: 'living space', # TODO: 301 Standard doesn't specify the location
                                   tank_volume: wh_tank_vol,
                                   fraction_dhw_load_served: 1.0,
                                   heating_capacity: wh_cap,
                                   energy_factor: wh_ef,
                                   recovery_efficiency: wh_re)
  end

  def self.get_predominant_heating_fuel(orig_details)
    fuel_fracs = {}

    orig_details.elements.each("Systems/HVAC/HVACPlant/HeatingSystem") do |heating|
      heating_values = HPXML.get_heating_system_values(heating_system: heating)
      fuel = heating_values[:heating_system_fuel]
      if fuel_fracs[fuel].nil?
        fuel_fracs[fuel] = 0.0
      end
      fuel_fracs[fuel] += heating_values[:fraction_heat_load_served]
    end

    orig_details.elements.each("Systems/HVAC/HVACPlant/HeatPump") do |hp|
      hp_values = HPXML.get_heat_pump_values(heat_pump: hp)
      fuel = hp_values[:heat_pump_fuel]
      if fuel_fracs[fuel].nil?
        fuel_fracs[fuel] = 0.0
      end
      fuel_fracs[fuel] += hp_values[:fraction_heat_load_served]
    end

    return "electricity" if fuel_fracs.empty?

    return fuel_fracs.key(fuel_fracs.values.max)
  end

  def self.get_infiltration_volume(orig_details)
    infilvolume = nil
    orig_details.elements.each("Enclosure/AirInfiltration/AirInfiltrationMeasurement") do |air_infiltration_measurement|
      air_infiltration_measurement_values = HPXML.get_air_infiltration_measurement_values(air_infiltration_measurement: air_infiltration_measurement)
      next if air_infiltration_measurement_values[:infiltration_volume].nil?

      infilvolume = air_infiltration_measurement_values[:infiltration_volume]
      break
    end

    return infilvolume
  end
end

def get_exterior_wall_area_fracs(orig_details)
  # Get individual exterior wall areas and sum
  wall_areas = {}
  orig_details.elements.each("Enclosure/Walls/Wall") do |wall|
    wall_values = HPXML.get_wall_values(wall: wall)
    next if wall_values[:exterior_adjacent_to] != "outside"
    next if wall_values[:interior_adjacent_to] != "living space"

    wall_areas[wall] = wall_values[:area]
  end
  wall_area_sum = wall_areas.values.inject { |sum, n| sum + n }

  # Convert to fractions
  wall_area_fracs = {}
  wall_areas.each do |wall, wall_area|
    wall_area_fracs[wall] = wall_areas[wall] / wall_area_sum
  end

  return wall_area_fracs
end
