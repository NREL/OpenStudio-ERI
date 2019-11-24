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

    # Determine building type (single family attached or multifamily?)
    @is_sfa_or_mf = !hpxml_doc.elements["/HPXML/Building/BuildingDetails/Enclosure/*/*[contains(ExteriorAdjacentTo, 'other housing unit')]"].nil?

    # Update HPXML object based on calculation type
    HPXML.collapse_enclosure(hpxml_doc.elements["/HPXML/Building/BuildingDetails/Enclosure"])
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
    set_enclosure_attics_reference(orig_details, hpxml)
    set_enclosure_foundations_reference(orig_details, hpxml)
    set_enclosure_roofs_reference(orig_details, hpxml)
    set_enclosure_rim_joists_reference(orig_details, hpxml)
    set_enclosure_walls_reference(orig_details, hpxml)
    set_enclosure_foundation_walls_reference(orig_details, hpxml)
    set_enclosure_ceilings_reference(orig_details, hpxml)
    set_enclosure_floors_reference(orig_details, hpxml)
    set_enclosure_slabs_reference(orig_details, hpxml)
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
    set_enclosure_attics_rated(orig_details, hpxml)
    set_enclosure_foundations_rated(orig_details, hpxml)
    set_enclosure_roofs_rated(orig_details, hpxml)
    set_enclosure_rim_joists_rated(orig_details, hpxml)
    set_enclosure_walls_rated(orig_details, hpxml)
    set_enclosure_foundation_walls_rated(orig_details, hpxml)
    set_enclosure_ceilings_rated(orig_details, hpxml)
    set_enclosure_floors_rated(orig_details, hpxml)
    set_enclosure_slabs_rated(orig_details, hpxml)
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

    remove_surfaces_from_iad(orig_details)

    # BuildingSummary
    set_summary_iad(orig_details, hpxml)

    # ClimateAndRiskZones
    set_climate(orig_details, hpxml)

    # Enclosure
    set_enclosure_air_infiltration_iad(hpxml)
    set_enclosure_attics_iad(orig_details, hpxml)
    set_enclosure_foundations_iad(orig_details, hpxml)
    set_enclosure_roofs_iad(orig_details, hpxml)
    set_enclosure_rim_joists_iad(orig_details, hpxml)
    set_enclosure_walls_iad(orig_details, hpxml)
    set_enclosure_foundation_walls_iad(hpxml)
    set_enclosure_ceilings_iad(orig_details, hpxml)
    set_enclosure_floors_iad(hpxml)
    set_enclosure_slabs_iad(orig_details, hpxml)
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
                                   xml_generated_by: "OpenStudio-ERI",
                                   transaction: hpxml_values[:transaction],
                                   software_program_used: hpxml_values[:software_program_used],
                                   software_program_version: hpxml_values[:software_program_version],
                                   eri_calculation_version: hpxml_values[:eri_calculation_version],
                                   building_id: hpxml_values[:building_id],
                                   event_type: hpxml_values[:event_type])

    return hpxml_doc
  end

  def self.remove_surfaces_from_iad(orig_details)
    # Remove garage surfaces and adiabatic walls.

    # Roof
    orig_details.elements.each("Enclosure/Roofs/Roof") do |roof|
      roof_values = HPXML.get_roof_values(roof: roof,
                                          select: [:id, :interior_adjacent_to])
      if ["garage"].include? roof_values[:interior_adjacent_to]
        roof.parent.elements.delete roof
        delete_roof_subsurfaces(orig_details, roof_values[:id])
      end
    end

    # Rim Joist
    orig_details.elements.each("Enclosure/RimJoists/RimJoist") do |rim_joist|
      rim_joist_values = HPXML.get_rim_joist_values(rim_joist: rim_joist,
                                                    select: [:interior_adjacent_to, :exterior_adjacent_to])
      if ["garage", "other housing unit"].include? rim_joist_values[:interior_adjacent_to] or
         ["garage", "other housing unit"].include? rim_joist_values[:exterior_adjacent_to]
        rim_joist.parent.elements.delete rim_joist
      end
    end

    # Wall
    orig_details.elements.each("Enclosure/Walls/Wall") do |wall|
      wall_values = HPXML.get_wall_values(wall: wall,
                                          select: [:id, :interior_adjacent_to, :exterior_adjacent_to])
      if ["garage", "other housing unit"].include? wall_values[:interior_adjacent_to] or
         ["garage", "other housing unit"].include? wall_values[:exterior_adjacent_to]
        wall.parent.elements.delete wall
        delete_wall_subsurfaces(orig_details, wall_values[:id])
      end
    end

    # FoundationWall
    orig_details.elements.each("Enclosure/FoundationWalls/FoundationWall") do |fnd_wall|
      fnd_wall_values = HPXML.get_foundation_wall_values(foundation_wall: fnd_wall,
                                                         select: [:id, :interior_adjacent_to, :exterior_adjacent_to])
      if ["garage", "other housing unit"].include? fnd_wall_values[:interior_adjacent_to] or
         ["garage", "other housing unit"].include? fnd_wall_values[:exterior_adjacent_to]
        fnd_wall.parent.elements.delete fnd_wall
        delete_wall_subsurfaces(orig_details, fnd_wall_values[:id])
      end
    end

    # FrameFloor
    orig_details.elements.each("Enclosure/FrameFloors/FrameFloor") do |framefloor|
      framefloor_values = HPXML.get_framefloor_values(framefloor: framefloor,
                                                      select: [:interior_adjacent_to, :exterior_adjacent_to])
      if ["garage"].include? framefloor_values[:interior_adjacent_to] or
         ["garage"].include? framefloor_values[:exterior_adjacent_to]
        framefloor.parent.elements.delete framefloor
      end
    end

    # Slab
    orig_details.elements.each("Enclosure/Slabs/Slab") do |slab|
      slab_values = HPXML.get_slab_values(slab: slab,
                                          select: [:interior_adjacent_to])
      if ["garage"].include? slab_values[:interior_adjacent_to]
        slab.parent.elements.delete slab
      end
    end
  end

  def self.set_summary_reference(orig_details, hpxml)
    site = orig_details.elements["BuildingSummary/Site"]
    site_values = HPXML.get_site_values(site: site,
                                        select: [:fuels])
    construction = orig_details.elements["BuildingSummary/BuildingConstruction"]
    construction_values = HPXML.get_building_construction_values(building_construction: construction)

    # Global variables
    @cfa = construction_values[:conditioned_floor_area]
    @nbeds = construction_values[:number_of_bedrooms]
    @ncfl = construction_values[:number_of_conditioned_floors]
    @ncfl_ag = construction_values[:number_of_conditioned_floors_above_grade]
    @cvolume = construction_values[:conditioned_building_volume]
    @infilvolume = get_infiltration_volume(orig_details)
    @has_uncond_bsmnt = get_has_space_type(orig_details, "basement - unconditioned")

    HPXML.add_site(hpxml: hpxml,
                   fuels: site_values[:fuels],
                   shelter_coefficient: Airflow.get_default_shelter_coefficient())

    HPXML.add_building_occupancy(hpxml: hpxml,
                                 number_of_residents: Geometry.get_occupancy_default_num(@nbeds))

    HPXML.add_building_construction(hpxml: hpxml, **construction_values)
  end

  def self.set_summary_rated(orig_details, hpxml)
    site = orig_details.elements["BuildingSummary/Site"]
    site_values = HPXML.get_site_values(site: site,
                                        select: [:fuels])
    construction = orig_details.elements["BuildingSummary/BuildingConstruction"]
    construction_values = HPXML.get_building_construction_values(building_construction: construction)

    # Global variables
    @cfa = construction_values[:conditioned_floor_area]
    @nbeds = construction_values[:number_of_bedrooms]
    @ncfl = construction_values[:number_of_conditioned_floors]
    @ncfl_ag = construction_values[:number_of_conditioned_floors_above_grade]
    @cvolume = construction_values[:conditioned_building_volume]
    @infilvolume = get_infiltration_volume(orig_details)
    @has_uncond_bsmnt = get_has_space_type(orig_details, "basement - unconditioned")

    HPXML.add_site(hpxml: hpxml,
                   fuels: site_values[:fuels],
                   shelter_coefficient: Airflow.get_default_shelter_coefficient())

    HPXML.add_building_occupancy(hpxml: hpxml,
                                 number_of_residents: Geometry.get_occupancy_default_num(@nbeds))

    HPXML.add_building_construction(hpxml: hpxml, **construction_values)
  end

  def self.set_summary_iad(orig_details, hpxml)
    site = orig_details.elements["BuildingSummary/Site"]
    site_values = HPXML.get_site_values(site: site,
                                        select: [:fuels])

    # Global variables
    # Table 4.3.1(1) Configuration of Index Adjustment Design - General Characteristics
    @cfa = 2400
    @nbeds = 3
    @ncfl = 2
    @ncfl_ag = 2
    @cvolume = 20400
    @infilvolume = 20400
    @has_uncond_bsmnt = false

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
                                    conditioned_building_volume: @cvolume)
  end

  def self.set_climate(orig_details, hpxml)
    climate_and_risk_zones_values = HPXML.get_climate_and_risk_zones_values(climate_and_risk_zones: orig_details.elements["ClimateandRiskZones"])
    HPXML.add_climate_and_risk_zones(hpxml: hpxml, **climate_and_risk_zones_values)
    @iecc_zone_2006 = climate_and_risk_zones_values[:iecc2006]
  end

  def self.set_enclosure_air_infiltration_reference(hpxml)
    # Table 4.2.2(1) - Air exchange rate
    sla = 0.00036
    ach50 = Airflow.get_infiltration_ACH50_from_SLA(sla, 0.65, @cfa, @infilvolume)

    # Air Infiltration
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

    min_ach50 = 0.0
    if whole_house_fan.nil?
      min_nach = 0.30
      min_sla = Airflow.get_infiltration_SLA_from_ACH(min_nach, @ncfl, @weather)
      min_ach50 = Airflow.get_infiltration_ACH50_from_SLA(min_sla, 0.65, @cfa, @infilvolume)
    end

    orig_details.elements.each("Enclosure/AirInfiltration/AirInfiltrationMeasurement") do |air_infiltration_measurement|
      air_infiltration_measurement_values = HPXML.get_air_infiltration_measurement_values(air_infiltration_measurement: air_infiltration_measurement)
      if air_infiltration_measurement_values[:unit_of_measure] == 'ACHnatural'
        nach = air_infiltration_measurement_values[:air_leakage]
        sla = Airflow.get_infiltration_SLA_from_ACH(nach, @ncfl, @weather)
        # Convert to ACH50
        air_infiltration_measurement_values[:air_leakage] = Airflow.get_infiltration_ACH50_from_SLA(sla, 0.65, @cfa, @infilvolume)
        air_infiltration_measurement_values[:unit_of_measure] = 'ACH'
        air_infiltration_measurement_values[:house_pressure] = 50
      elsif air_infiltration_measurement_values[:unit_of_measure] == 'ACH' and air_infiltration_measurement_values[:house_pressure] == 50
        # nop
      elsif air_infiltration_measurement_values[:unit_of_measure] == 'CFM' and air_infiltration_measurement_values[:house_pressure] == 50
        # Convert to ACH50
        air_infiltration_measurement_values[:unit_of_measure] = "ACH"
        air_infiltration_measurement_values[:air_leakage] *= 60.0 / @infilvolume
      else
        next
      end

      if air_infiltration_measurement_values[:air_leakage] < min_ach50
        air_infiltration_measurement_values[:air_leakage] = min_ach50
      end

      # Air Infiltration
      HPXML.add_air_infiltration_measurement(hpxml: hpxml,
                                             id: "AirInfiltrationMeasurement",
                                             house_pressure: air_infiltration_measurement_values[:house_pressure],
                                             unit_of_measure: air_infiltration_measurement_values[:unit_of_measure],
                                             air_leakage: air_infiltration_measurement_values[:air_leakage],
                                             infiltration_volume: @infilvolume)
      break
    end
  end

  def self.set_enclosure_air_infiltration_iad(hpxml)
    # Table 4.3.1(1) Configuration of Index Adjustment Design - Air exchange rate
    if ["1A", "1B", "1C", "2A", "2B", "2C"].include? @iecc_zone_2006
      ach50 = 5.0
    elsif ["3A", "3B", "3C", "4A", "4B", "4C", "5A", "5B", "5C", "6A", "6B", "6C", "7", "8"].include? @iecc_zone_2006
      ach50 = 3.0
    end

    # Air Infiltration
    HPXML.add_air_infiltration_measurement(hpxml: hpxml,
                                           id: "Infiltration_ACH50",
                                           house_pressure: 50,
                                           unit_of_measure: "ACH",
                                           air_leakage: ach50,
                                           infiltration_volume: @infilvolume)
  end

  def self.set_enclosure_attics_reference(orig_details, hpxml)
    # Check if vented attic (or unvented attic, which will become a vented attic) exists
    if not orig_details.elements["Enclosure/Roofs/Roof[InteriorAdjacentTo='attic - vented' or InteriorAdjacentTo='attic - unvented']"].nil?
      HPXML.add_attic(hpxml: hpxml,
                      id: "VentedAttic",
                      attic_type: "VentedAttic",
                      vented_attic_sla: Airflow.get_default_vented_attic_sla())
    end
  end

  def self.set_enclosure_attics_rated(orig_details, hpxml)
    orig_details.elements.each("Enclosure/Attics/Attic[AtticType/Attic[Vented='true']]") do |vented_attic|
      vented_attic_values = HPXML.get_attic_values(attic: vented_attic)
      HPXML.add_attic(hpxml: hpxml, **vented_attic_values)
    end
  end

  def self.set_enclosure_attics_iad(orig_details, hpxml)
    set_enclosure_attics_rated(orig_details, hpxml)
  end

  def self.set_enclosure_foundations_reference(orig_details, hpxml)
    # Check if vented crawlspace (or unvented crawlspace, which will become a vented crawlspace) exists
    if not orig_details.elements["Enclosure/FrameFloors/FrameFloor[InteriorAdjacentTo='crawlspace - vented' or ExteriorAdjacentTo='crawlspace - vented' or InteriorAdjacentTo='crawlspace - unvented' or ExteriorAdjacentTo='crawlspace - unvented']"].nil?
      HPXML.add_foundation(hpxml: hpxml,
                           id: "VentedCrawlspace",
                           foundation_type: "VentedCrawlspace",
                           vented_crawlspace_sla: Airflow.get_default_vented_crawl_sla())
    end

    @uncond_bsmnt_thermal_bndry = nil
    # Preserve rated home thermal boundary to be consistent with other software tools
    orig_details.elements.each("Enclosure/Foundations/Foundation[FoundationType/Basement[Conditioned='false']]") do |uncond_bsmt|
      fnd_values = HPXML.get_foundation_values(foundation: uncond_bsmt)
      HPXML.add_foundation(hpxml: hpxml,
                           id: fnd_values[:id],
                           foundation_type: fnd_values[:foundation_type],
                           unconditioned_basement_thermal_boundary: fnd_values[:unconditioned_basement_thermal_boundary])
      @uncond_bsmnt_thermal_bndry = fnd_values[:unconditioned_basement_thermal_boundary]
    end
  end

  def self.set_enclosure_foundations_rated(orig_details, hpxml)
    reference_crawlspace_sla = Airflow.get_default_vented_crawl_sla()

    orig_details.elements.each("Enclosure/Foundations/Foundation[FoundationType/Crawlspace[Vented='true']]") do |vented_crawl|
      vented_crawl_values = HPXML.get_foundation_values(foundation: vented_crawl)
      if vented_crawl_values[:vented_crawlspace_sla].nil? or vented_crawl_values[:vented_crawlspace_sla] < reference_crawlspace_sla
        # FUTURE: Allow approved ground cover
        vented_crawl_values[:vented_crawlspace_sla] = reference_crawlspace_sla
      end
      HPXML.add_foundation(hpxml: hpxml, **vented_crawl_values)
    end

    @uncond_bsmnt_thermal_bndry = nil
    orig_details.elements.each("Enclosure/Foundations/Foundation[FoundationType/Basement[Conditioned='false']]") do |uncond_bsmt|
      fnd_values = HPXML.get_foundation_values(foundation: uncond_bsmt)
      HPXML.add_foundation(hpxml: hpxml,
                           id: fnd_values[:id],
                           foundation_type: fnd_values[:foundation_type],
                           unconditioned_basement_thermal_boundary: fnd_values[:unconditioned_basement_thermal_boundary])
      @uncond_bsmnt_thermal_bndry = fnd_values[:unconditioned_basement_thermal_boundary]
    end
  end

  def self.set_enclosure_foundations_iad(orig_details, hpxml)
    HPXML.add_foundation(hpxml: hpxml,
                         id: "VentedCrawlspace",
                         foundation_type: "VentedCrawlspace",
                         vented_crawlspace_sla: Airflow.get_default_vented_crawl_sla())

    @uncond_bsmnt_thermal_bndry = nil
  end

  def self.set_enclosure_roofs_reference(orig_details, hpxml)
    # Table 4.2.2(1) - Roofs
    ceiling_ufactor = Constructions.get_default_ceiling_ufactor(@iecc_zone_2006)

    roofs_values = {}
    orig_details.elements.each("Enclosure/Roofs/Roof") do |roof|
      roofs_values[roof] = HPXML.get_roof_values(roof: roof)
    end

    sum_gross_area = calc_sum_of_exterior_thermal_boundary_values(roofs_values.values)
    avg_pitch = calc_area_weighted_sum_of_exterior_thermal_boundary_values(roofs_values.values, :pitch)
    solar_abs = 0.75
    emittance = 0.90

    # Create thermal boundary roof area
    if sum_gross_area > 0
      HPXML.add_roof(hpxml: hpxml,
                     id: "RoofArea",
                     interior_adjacent_to: "living space",
                     area: sum_gross_area,
                     azimuth: nil,
                     solar_absorptance: solar_abs,
                     emittance: emittance,
                     pitch: avg_pitch,
                     radiant_barrier: false,
                     insulation_assembly_r_value: 1.0 / ceiling_ufactor)
    end

    # Preserve other roofs
    roofs_values.each do |roof, roof_values|
      next if is_exterior_thermal_boundary(roof_values)

      roof_values[:solar_absorptance] = solar_abs
      roof_values[:emittance] = emittance
      roof_values[:interior_adjacent_to].gsub!("unvented", "vented")
      if is_thermal_boundary(roof_values)
        roof_values[:insulation_assembly_r_value] = 1.0 / ceiling_ufactor
      else
        roof_values[:insulation_assembly_r_value] = 2.3 # uninsulated
      end
      roof_values[:radiant_barrier] = false
      HPXML.add_roof(hpxml: hpxml, **roof_values)
    end
  end

  def self.set_enclosure_roofs_rated(orig_details, hpxml)
    orig_details.elements.each("Enclosure/Roofs/Roof") do |roof|
      roof_values = HPXML.get_roof_values(roof: roof)
      HPXML.add_roof(hpxml: hpxml, **roof_values)
    end
  end

  def self.set_enclosure_roofs_iad(orig_details, hpxml)
    set_enclosure_roofs_rated(orig_details, hpxml)
    new_enclosure = hpxml.elements["Building/BuildingDetails/Enclosure"]

    roofs_values = {}
    new_enclosure.elements.each("Roofs/Roof") do |new_roof|
      roofs_values[new_roof] = HPXML.get_roof_values(roof: new_roof)
    end

    # Table 4.3.1(1) Configuration of Index Adjustment Design - Roofs
    sum_roof_area = 0.0
    roofs_values.each do |new_roof, new_roof_values|
      sum_roof_area += new_roof_values[:area]
    end
    roofs_values.each do |new_roof, new_roof_values|
      new_roof.elements["Area"].text = 1300.0 * new_roof_values[:area] / sum_roof_area
    end
  end

  def self.set_enclosure_rim_joists_reference(orig_details, hpxml)
    # Table 4.2.2(1) - Above-grade walls
    ufactor = Constructions.get_default_frame_wall_ufactor(@iecc_zone_2006)

    rim_joists_values = {}
    orig_details.elements.each("Enclosure/RimJoists/RimJoist") do |rim_joist|
      rim_joists_values[rim_joist] = HPXML.get_rim_joist_values(rim_joist: rim_joist)
    end

    sum_gross_area = calc_sum_of_exterior_thermal_boundary_values(rim_joists_values.values)
    solar_abs = 0.75
    emittance = 0.90

    # Create thermal boundary rim joist area
    if sum_gross_area > 0
      HPXML.add_rim_joist(hpxml: hpxml,
                          id: "RimJoistArea",
                          exterior_adjacent_to: "outside",
                          interior_adjacent_to: "living space",
                          area: sum_gross_area,
                          azimuth: nil,
                          solar_absorptance: solar_abs,
                          emittance: emittance,
                          insulation_assembly_r_value: 1.0 / ufactor)
    end

    # Preserve other rim joists
    rim_joists_values.each do |rim_joist, rim_joist_values|
      next if is_exterior_thermal_boundary(rim_joist_values)

      rim_joist_values[:solar_absorptance] = solar_abs
      rim_joist_values[:emittance] = emittance
      rim_joist_values[:interior_adjacent_to].gsub!("unvented", "vented")
      rim_joist_values[:exterior_adjacent_to].gsub!("unvented", "vented")
      if is_thermal_boundary(rim_joist_values)
        rim_joist_values[:insulation_assembly_r_value] = 1.0 / ufactor
      else
        rim_joist_values[:insulation_assembly_r_value] = 2.3 # uninsulated
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

  def self.set_enclosure_rim_joists_iad(orig_details, hpxml)
    # nop; included in above-grade walls
  end

  def self.set_enclosure_walls_reference(orig_details, hpxml)
    # Table 4.2.2(1) - Above-grade walls
    ufactor = Constructions.get_default_frame_wall_ufactor(@iecc_zone_2006)

    walls_values = {}
    orig_details.elements.each("Enclosure/Walls/Wall") do |wall|
      walls_values[wall] = HPXML.get_wall_values(wall: wall)
    end

    sum_gross_area = calc_sum_of_exterior_thermal_boundary_values(walls_values.values)
    solar_abs = 0.75
    emittance = 0.90

    # Create thermal boundary wall area
    if sum_gross_area > 0
      HPXML.add_wall(hpxml: hpxml,
                     id: "WallArea",
                     exterior_adjacent_to: "outside",
                     interior_adjacent_to: "living space",
                     wall_type: "WoodStud",
                     area: sum_gross_area,
                     azimuth: nil,
                     solar_absorptance: solar_abs,
                     emittance: emittance,
                     insulation_assembly_r_value: 1.0 / ufactor)
    end

    # Preserve other walls
    walls_values.each do |wall, wall_values|
      next if is_exterior_thermal_boundary(wall_values)

      wall_values[:solar_absorptance] = solar_abs
      wall_values[:emittance] = emittance
      wall_values[:interior_adjacent_to].gsub!("unvented", "vented")
      wall_values[:exterior_adjacent_to].gsub!("unvented", "vented")
      if is_thermal_boundary(wall_values)
        wall_values[:insulation_assembly_r_value] = 1.0 / ufactor
      else
        wall_values[:insulation_assembly_r_value] = 4.0 # uninsulated
      end
      HPXML.add_wall(hpxml: hpxml, **wall_values)
    end
  end

  def self.set_enclosure_walls_rated(orig_details, hpxml)
    # Table 4.2.2(1) - Above-grade walls
    orig_details.elements.each("Enclosure/Walls/Wall") do |wall|
      wall_values = HPXML.get_wall_values(wall: wall)
      HPXML.add_wall(hpxml: hpxml, **wall_values)
    end
  end

  def self.set_enclosure_walls_iad(orig_details, hpxml)
    # Table 4.3.1(1) Configuration of Index Adjustment Design - Above-grade walls
    walls_values = {}
    orig_details.elements.each("Enclosure/Walls/Wall") do |wall|
      walls_values[wall] = HPXML.get_wall_values(wall: wall)
    end

    avg_solar_abs = calc_area_weighted_sum_of_exterior_thermal_boundary_values(walls_values.values, :solar_absorptance)
    avg_emittance = calc_area_weighted_sum_of_exterior_thermal_boundary_values(walls_values.values, :emittance)
    avg_r_value = calc_area_weighted_sum_of_exterior_thermal_boundary_values(walls_values.values, :insulation_assembly_r_value, true)

    # Create thermal boundary wall area
    HPXML.add_wall(hpxml: hpxml,
                   id: "WallArea",
                   exterior_adjacent_to: "outside",
                   interior_adjacent_to: "living space",
                   wall_type: "WoodStud",
                   area: 2355.52,
                   azimuth: nil,
                   solar_absorptance: avg_solar_abs,
                   emittance: avg_emittance,
                   insulation_assembly_r_value: avg_r_value)

    # Preserve non-thermal boundary walls adjacent to attic
    walls_values.each do |wall, wall_values|
      next if is_thermal_boundary(wall_values)
      next unless ["attic - vented", "attic - unvented"].include? wall_values[:interior_adjacent_to]

      HPXML.add_wall(hpxml: hpxml, **wall_values)
    end
  end

  def self.set_enclosure_foundation_walls_reference(orig_details, hpxml)
    wall_ufactor = Constructions.get_default_basement_wall_ufactor(@iecc_zone_2006)

    # Table 4.2.2(1) - Conditioned basement walls
    orig_details.elements.each("Enclosure/FoundationWalls/FoundationWall") do |fwall|
      fwall_values = HPXML.get_foundation_wall_values(foundation_wall: fwall)
      if is_thermal_boundary(fwall_values) or @uncond_bsmnt_thermal_bndry == "foundation wall"
        fwall_values[:insulation_assembly_r_value] = 1.0 / wall_ufactor
        fwall_values[:insulation_r_value] = nil
      else
        fwall_values[:insulation_r_value] = 0 # uninsulated
        fwall_values[:insulation_distance_to_bottom] = 0
        fwall_values[:insulation_assembly_r_value] = nil
      end
      fwall_values[:interior_adjacent_to].gsub!("unvented", "vented")
      fwall_values[:exterior_adjacent_to].gsub!("unvented", "vented")
      HPXML.add_foundation_wall(hpxml: hpxml, **fwall_values)
    end
  end

  def self.set_enclosure_foundation_walls_rated(orig_details, hpxml)
    orig_details.elements.each("Enclosure/FoundationWalls/FoundationWall") do |fwall|
      fwall_values = HPXML.get_foundation_wall_values(foundation_wall: fwall)
      HPXML.add_foundation_wall(hpxml: hpxml, **fwall_values)
    end
  end

  def self.set_enclosure_foundation_walls_iad(hpxml)
    HPXML.add_foundation_wall(hpxml: hpxml,
                              id: "FoundationWall",
                              interior_adjacent_to: "crawlspace - vented",
                              exterior_adjacent_to: "ground",
                              height: 2,
                              area: 2 * 34.64 * 4,
                              thickness: 8,
                              depth_below_grade: 0,
                              insulation_distance_to_bottom: 0,
                              insulation_r_value: 0)
  end

  def self.set_enclosure_ceilings_reference(orig_details, hpxml)
    ceiling_ufactor = Constructions.get_default_ceiling_ufactor(@iecc_zone_2006)

    # Table 4.2.2(1) - Ceilings
    orig_details.elements.each("Enclosure/FrameFloors/FrameFloor") do |framefloor|
      framefloor_values = HPXML.get_framefloor_values(framefloor: framefloor)
      next unless hpxml_framefloor_is_ceiling(framefloor_values[:interior_adjacent_to],
                                              framefloor_values[:exterior_adjacent_to])

      if is_thermal_boundary(framefloor_values)
        framefloor_values[:insulation_assembly_r_value] = 1.0 / ceiling_ufactor
      else
        framefloor_values[:insulation_assembly_r_value] = 2.1 # uninsulated
      end
      framefloor_values[:interior_adjacent_to].gsub!("unvented", "vented")
      framefloor_values[:exterior_adjacent_to].gsub!("unvented", "vented")
      HPXML.add_framefloor(hpxml: hpxml, **framefloor_values)
    end
  end

  def self.set_enclosure_ceilings_rated(orig_details, hpxml)
    orig_details.elements.each("Enclosure/FrameFloors/FrameFloor") do |framefloor|
      framefloor_values = HPXML.get_framefloor_values(framefloor: framefloor)
      next unless hpxml_framefloor_is_ceiling(framefloor_values[:interior_adjacent_to],
                                              framefloor_values[:exterior_adjacent_to])

      HPXML.add_framefloor(hpxml: hpxml, **framefloor_values)
    end
  end

  def self.set_enclosure_ceilings_iad(orig_details, hpxml)
    set_enclosure_ceilings_rated(orig_details, hpxml)
    new_enclosure = hpxml.elements["Building/BuildingDetails/Enclosure"]

    framefloors_values = {}
    new_enclosure.elements.each("FrameFloors/FrameFloor") do |new_framefloor|
      framefloors_values[new_framefloor] = HPXML.get_framefloor_values(framefloor: new_framefloor)
    end

    # Table 4.3.1(1) Configuration of Index Adjustment Design - Ceilings
    sum_ceiling_area = 0.0
    framefloors_values.each do |new_framefloor, new_framefloor_values|
      next unless hpxml_framefloor_is_ceiling(new_framefloor_values[:interior_adjacent_to],
                                              new_framefloor_values[:exterior_adjacent_to])

      sum_ceiling_area += new_framefloor_values[:area]
    end
    framefloors_values.each do |new_framefloor, new_framefloor_values|
      next unless hpxml_framefloor_is_ceiling(new_framefloor_values[:interior_adjacent_to],
                                              new_framefloor_values[:exterior_adjacent_to])

      new_framefloor.elements["Area"].text = 1200.0 * new_framefloor_values[:area] / sum_ceiling_area
    end
  end

  def self.set_enclosure_floors_reference(orig_details, hpxml)
    floor_ufactor = Constructions.get_default_floor_ufactor(@iecc_zone_2006)

    # Table 4.2.2(1) - Floors over unconditioned spaces or outdoor environment
    orig_details.elements.each("Enclosure/FrameFloors/FrameFloor") do |framefloor|
      framefloor_values = HPXML.get_framefloor_values(framefloor: framefloor)
      next if hpxml_framefloor_is_ceiling(framefloor_values[:interior_adjacent_to],
                                          framefloor_values[:exterior_adjacent_to])

      if is_thermal_boundary(framefloor_values)
        if @uncond_bsmnt_thermal_bndry == "foundation wall"
          framefloor_values[:insulation_assembly_r_value] = 3.1 # uninsulated
        else
          framefloor_values[:insulation_assembly_r_value] = 1.0 / floor_ufactor
        end
      else
        framefloor_values[:insulation_assembly_r_value] = 3.1 # uninsulated
      end
      framefloor_values[:interior_adjacent_to].gsub!("unvented", "vented")
      framefloor_values[:exterior_adjacent_to].gsub!("unvented", "vented")
      HPXML.add_framefloor(hpxml: hpxml, **framefloor_values)
    end
  end

  def self.set_enclosure_floors_rated(orig_details, hpxml)
    orig_details.elements.each("Enclosure/FrameFloors/FrameFloor") do |framefloor|
      framefloor_values = HPXML.get_framefloor_values(framefloor: framefloor)
      next if hpxml_framefloor_is_ceiling(framefloor_values[:interior_adjacent_to],
                                          framefloor_values[:exterior_adjacent_to])

      HPXML.add_framefloor(hpxml: hpxml, **framefloor_values)
    end
  end

  def self.set_enclosure_floors_iad(hpxml)
    floor_ufactor = Constructions.get_default_floor_ufactor(@iecc_zone_2006)

    HPXML.add_framefloor(hpxml: hpxml,
                         id: "FloorAboveCrawlspace",
                         interior_adjacent_to: "living space",
                         exterior_adjacent_to: "crawlspace - vented",
                         area: 1200,
                         insulation_assembly_r_value: 1.0 / floor_ufactor)
  end

  def self.set_enclosure_slabs_reference(orig_details, hpxml)
    slab_perim_rvalue, slab_perim_depth = Constructions.get_default_slab_perimeter_rvalue_depth(@iecc_zone_2006)
    slab_under_rvalue, slab_under_width = Constructions.get_default_slab_under_rvalue_width()

    # Table 4.2.2(1) - Foundations
    orig_details.elements.each("Enclosure/Slabs/Slab") do |slab|
      slab_values = HPXML.get_slab_values(slab: slab)
      if slab_values[:interior_adjacent_to] == "living space" and is_thermal_boundary(slab_values)
        slab_values[:perimeter_insulation_depth] = slab_perim_depth
        slab_values[:under_slab_insulation_width] = slab_under_width
        slab_values[:under_slab_insulation_spans_entire_slab] = nil
        slab_values[:perimeter_insulation_r_value] = slab_perim_rvalue
        slab_values[:under_slab_insulation_r_value] = slab_under_rvalue
      else
        slab_values[:perimeter_insulation_depth] = 0
        slab_values[:under_slab_insulation_width] = 0
        slab_values[:under_slab_insulation_spans_entire_slab] = nil
        slab_values[:perimeter_insulation_r_value] = 0
        slab_values[:under_slab_insulation_r_value] = 0
      end
      if ["living space", "basement - conditioned"].include? slab_values[:interior_adjacent_to]
        slab_values[:carpet_fraction] = 0.8
        slab_values[:carpet_r_value] = 2.0
      end
      slab_values[:interior_adjacent_to].gsub!("unvented", "vented")
      new_slab = HPXML.add_slab(hpxml: hpxml, **slab_values)
    end
  end

  def self.set_enclosure_slabs_rated(orig_details, hpxml)
    orig_details.elements.each("Enclosure/Slabs/Slab") do |slab|
      slab_values = HPXML.get_slab_values(slab: slab)
      HPXML.add_slab(hpxml: hpxml, **slab_values)
    end
  end

  def self.set_enclosure_slabs_iad(orig_details, hpxml)
    HPXML.add_slab(hpxml: hpxml,
                   id: "Slab",
                   interior_adjacent_to: "crawlspace - vented",
                   area: 1200,
                   thickness: 0,
                   exposed_perimeter: 4 * 34.64,
                   perimeter_insulation_depth: 0,
                   under_slab_insulation_width: 0,
                   under_slab_insulation_spans_entire_slab: nil,
                   carpet_fraction: 0,
                   carpet_r_value: 0,
                   perimeter_insulation_r_value: 0,
                   under_slab_insulation_r_value: 0)
  end

  def self.set_enclosure_windows_reference(orig_details, hpxml)
    # Table 4.2.2(1) - Glazing
    ufactor, shgc = Constructions.get_default_ufactor_shgc(@iecc_zone_2006)

    ag_bndry_wall_area, bg_bndry_wall_area, common_wall_area = calc_wall_areas_for_windows(orig_details)

    fa = ag_bndry_wall_area / (ag_bndry_wall_area + 0.5 * bg_bndry_wall_area)
    f = 1.0 - 0.44 * common_wall_area / (ag_bndry_wall_area + common_wall_area)

    total_window_area = 0.18 * @cfa * fa * f

    shade_summer, shade_winter = Constructions.get_default_interior_shading_factors()

    # Create windows
    for orientation, azimuth in { "North" => 0, "South" => 180, "East" => 90, "West" => 270 }
      HPXML.add_window(hpxml: hpxml,
                       id: "WindowArea#{orientation}",
                       area: total_window_area * 0.25,
                       azimuth: azimuth,
                       ufactor: ufactor,
                       shgc: shgc,
                       wall_idref: "WallArea",
                       interior_shading_factor_summer: shade_summer,
                       interior_shading_factor_winter: shade_winter)
    end
  end

  def self.set_enclosure_windows_rated(orig_details, hpxml)
    # Table 4.2.2(1) - Glazing
    shade_summer, shade_winter = Constructions.get_default_interior_shading_factors()
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

    shade_summer, shade_winter = Constructions.get_default_interior_shading_factors()

    windows_values = {}
    orig_details.elements.each("Enclosure/Windows/Window") do |window|
      windows_values[window] = HPXML.get_window_values(window: window)
    end

    avg_ufactor = calc_area_weighted_sum_of_exterior_thermal_boundary_values(windows_values.values, :ufactor)
    avg_shgc = calc_area_weighted_sum_of_exterior_thermal_boundary_values(windows_values.values, :shgc)

    # Create windows
    for orientation, azimuth in { "North" => 0, "South" => 180, "East" => 90, "West" => 270 }
      HPXML.add_window(hpxml: hpxml,
                       id: "WindowArea#{orientation}",
                       area: total_window_area * 0.25,
                       azimuth: azimuth,
                       ufactor: avg_ufactor,
                       shgc: avg_shgc,
                       wall_idref: "WallArea",
                       interior_shading_factor_summer: shade_summer,
                       interior_shading_factor_winter: shade_winter)
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

    # Since the IAD roof area is scaled down but skylight area is maintained,
    # it's possible that skylights no longer fit on the roof. To resolve this,
    # scale down skylight area if needed to fit.
    hpxml.elements.each("Building/BuildingDetails/Enclosure/Roofs/Roof") do |new_roof|
      new_roof_values = HPXML.get_roof_values(roof: new_roof,
                                              select: [:id, :area])
      new_roof_id = new_roof_values[:id]
      new_skylight_area = REXML::XPath.first(hpxml, "sum(Building/BuildingDetails/Enclosure/Skylights/Skylight[AttachedToRoof/@idref='#{new_roof_id}']/Area/text())")
      if new_skylight_area > new_roof_values[:area]
        hpxml.elements.each("Building/BuildingDetails/Enclosure/Skylights/Skylight[AttachedToRoof/@idref='#{new_roof_id}']") do |new_skylight|
          new_skylight.elements["Area"].text = Float(new_skylight.elements["Area"].text) * new_roof_values[:area] / new_skylight_area * 0.99
        end
      end
    end
  end

  def self.set_enclosure_doors_reference(orig_details, hpxml)
    # Table 4.2.2(1) - Doors
    ufactor, shgc = Constructions.get_default_ufactor_shgc(@iecc_zone_2006)
    door_area = Constructions.get_default_door_area()

    # Create new door
    HPXML.add_door(hpxml: hpxml,
                   id: "DoorAreaNorth",
                   wall_idref: "WallArea",
                   area: door_area,
                   azimuth: 0,
                   r_value: 1.0 / ufactor)
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
    door_area = Constructions.get_default_door_area()

    doors_values = {}
    orig_details.elements.each("Enclosure/Doors/Door") do |door|
      doors_values[door] = HPXML.get_door_values(door: door)
    end

    avg_r_value = calc_area_weighted_sum_of_exterior_thermal_boundary_values(doors_values.values, :r_value, true)

    # Create new door (since it's impossible to preserve the Rated Home's door orientation)
    # Note: Area is incorrect in table, should be “Area: Same as Energy Rating Reference Home”
    HPXML.add_door(hpxml: hpxml,
                   id: "DoorAreaNorth",
                   wall_idref: "WallArea",
                   area: door_area,
                   azimuth: 0,
                   r_value: avg_r_value)
  end

  def self.set_systems_hvac_reference(orig_details, hpxml)
    # Table 4.2.2(1) - Heating systems
    # Table 4.2.2(1) - Cooling systems

    has_fuel = has_fuel_access(orig_details)
    ref_hvacdist_ids = []

    # Heating
    orig_details.elements.each("Systems/HVAC/HVACPlant/HeatingSystem") do |heating|
      heating_values = HPXML.get_heating_system_values(heating_system: heating)
      next unless heating_values[:heating_system_fuel] != "electricity"

      if heating_values[:heating_system_type] == "Boiler"
        add_reference_heating_gas_boiler(hpxml, ref_hvacdist_ids, heating_values)
      else
        add_reference_heating_gas_furnace(hpxml, ref_hvacdist_ids, heating_values)
      end
    end
    if orig_details.elements["Systems/HVAC/HVACPlant/HeatingSystem"].nil? and orig_details.elements["Systems/HVAC/HVACPlant/HeatPump[FractionHeatLoadServed > 0]"].nil?
      if has_fuel
        add_reference_heating_gas_furnace(hpxml, ref_hvacdist_ids)
      end
    end

    # Cooling
    orig_details.elements.each("Systems/HVAC/HVACPlant/CoolingSystem") do |cooling|
      cooling_values = HPXML.get_cooling_system_values(cooling_system: cooling)
      add_reference_cooling_air_conditioner(hpxml, ref_hvacdist_ids, cooling_values)
    end
    orig_details.elements.each("Systems/HVAC/HVACPlant/HeatPump[FractionCoolLoadServed > 0]") do |hp|
      hp_values = HPXML.get_heat_pump_values(heat_pump: hp)
      add_reference_cooling_air_conditioner(hpxml, ref_hvacdist_ids, hp_values)
    end
    if orig_details.elements["Systems/HVAC/HVACPlant/CoolingSystem"].nil? and orig_details.elements["Systems/HVAC/HVACPlant/HeatPump[FractionCoolLoadServed > 0]"].nil?
      add_reference_cooling_air_conditioner(hpxml, ref_hvacdist_ids)
    end

    # HeatPump
    orig_details.elements.each("Systems/HVAC/HVACPlant/HeatingSystem") do |heating|
      heating_values = HPXML.get_heating_system_values(heating_system: heating)
      next unless heating_values[:heating_system_fuel] == "electricity"

      add_reference_heating_heat_pump(hpxml, ref_hvacdist_ids, heating_values)
    end
    orig_details.elements.each("Systems/HVAC/HVACPlant/HeatPump[FractionHeatLoadServed > 0]") do |hp|
      hp_values = HPXML.get_heat_pump_values(heat_pump: hp)
      add_reference_heating_heat_pump(hpxml, ref_hvacdist_ids, hp_values)
    end
    if orig_details.elements["Systems/HVAC/HVACPlant/HeatingSystem"].nil? and orig_details.elements["Systems/HVAC/HVACPlant/HeatPump[FractionHeatLoadServed > 0]"].nil?
      if not has_fuel
        add_reference_heating_heat_pump(hpxml, ref_hvacdist_ids)
      end
    end

    # Table 303.4.1(1) - Thermostat
    control_type = "manual thermostat"
    if not orig_details.elements["Lighting/CeilingFan"].nil?
      clg_ceiling_fan_offset = 0.5 # deg-F
    else
      clg_ceiling_fan_offset = nil
    end
    HPXML.add_hvac_control(hpxml: hpxml,
                           id: "HVACControl",
                           control_type: control_type,
                           heating_setpoint_temp: HVAC.get_default_heating_setpoint(control_type)[0],
                           cooling_setpoint_temp: HVAC.get_default_cooling_setpoint(control_type)[0],
                           ceiling_fan_cooling_setpoint_temp_offset: clg_ceiling_fan_offset)

    # Distribution system
    add_reference_distribution_system(hpxml, ref_hvacdist_ids)
  end

  def self.set_systems_hvac_rated(orig_details, hpxml)
    # Table 4.2.2(1) - Heating systems
    # Table 4.2.2(1) - Cooling systems

    heating_system = orig_details.elements["Systems/HVAC/HVACPlant/HeatingSystem"]
    heat_pump = orig_details.elements["Systems/HVAC/HVACPlant/HeatPump"]
    cooling_system = orig_details.elements["Systems/HVAC/HVACPlant/CoolingSystem"]

    ref_hvacdist_ids = []

    # Heating
    if not heating_system.nil?
      # Retain heating system(s)
      orig_details.elements.each("Systems/HVAC/HVACPlant/HeatingSystem") do |heating|
        heating_values = HPXML.get_heating_system_values(heating_system: heating)
        HPXML.add_heating_system(hpxml: hpxml, **heating_values)
      end
    end
    if heating_system.nil? and heat_pump.nil? and has_fuel_access(orig_details)
      add_reference_heating_gas_furnace(hpxml, ref_hvacdist_ids)
    end

    # Cooling
    if not cooling_system.nil?
      # Retain cooling system(s)
      orig_details.elements.each("Systems/HVAC/HVACPlant/CoolingSystem") do |cooling|
        cooling_values = HPXML.get_cooling_system_values(cooling_system: cooling)
        HPXML.add_cooling_system(hpxml: hpxml, **cooling_values)
      end
    end
    if cooling_system.nil? and heat_pump.nil?
      add_reference_cooling_air_conditioner(hpxml, ref_hvacdist_ids)
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
      add_reference_heating_heat_pump(hpxml, ref_hvacdist_ids)
    end

    # Table 303.4.1(1) - Thermostat
    hvac_control = orig_details.elements["Systems/HVAC/HVACControl"]
    if not orig_details.elements["Lighting/CeilingFan"].nil?
      clg_ceiling_fan_offset = 0.5 # deg-F
    else
      clg_ceiling_fan_offset = nil
    end
    if not hvac_control.nil?
      hvac_control_values = HPXML.get_hvac_control_values(hvac_control: hvac_control,
                                                          select: [:id, :control_type])
      control_type = hvac_control_values[:control_type]
      htg_sp, htg_setback_sp, htg_setback_hrs_per_week, htg_setback_start_hr = HVAC.get_default_heating_setpoint(control_type)
      clg_sp, clg_setup_sp, clg_setup_hrs_per_week, clg_setup_start_hr = HVAC.get_default_cooling_setpoint(control_type)
      HPXML.add_hvac_control(hpxml: hpxml,
                             id: hvac_control_values[:id],
                             control_type: control_type,
                             heating_setpoint_temp: htg_sp,
                             heating_setback_temp: htg_setback_sp,
                             heating_setback_hours_per_week: htg_setback_hrs_per_week,
                             heating_setback_start_hour: htg_setback_start_hr,
                             cooling_setpoint_temp: clg_sp,
                             cooling_setup_temp: clg_setup_sp,
                             cooling_setup_hours_per_week: clg_setup_hrs_per_week,
                             cooling_setup_start_hour: clg_setup_start_hr,
                             ceiling_fan_cooling_setpoint_temp_offset: clg_ceiling_fan_offset)

    else
      control_type = "manual thermostat"
      HPXML.add_hvac_control(hpxml: hpxml,
                             id: "HVACControl",
                             control_type: control_type,
                             heating_setpoint_temp: HVAC.get_default_heating_setpoint(control_type)[0],
                             cooling_setpoint_temp: HVAC.get_default_cooling_setpoint(control_type)[0],
                             ceiling_fan_cooling_setpoint_temp_offset: clg_ceiling_fan_offset)
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

    # Add DSE distribution for these systems
    add_reference_distribution_system(hpxml, ref_hvacdist_ids)
  end

  def self.set_systems_hvac_iad(orig_details, hpxml)
    # Table 4.3.1(1) Configuration of Index Adjustment Design - Heating systems
    # Table 4.3.1(1) Configuration of Index Adjustment Design - Cooling systems
    # Table 4.3.1(1) Configuration of Index Adjustment Design - Thermostat
    set_systems_hvac_reference(orig_details, hpxml)

    # Table 4.3.1(1) Configuration of Index Adjustment Design - Thermal distribution systems
    # Change DSE to 1.0
    hpxml.elements.each("Building/BuildingDetails/Systems/HVAC/HVACDistribution") do |new_hvac_dist|
      new_hvac_dist.elements["AnnualHeatingDistributionSystemEfficiency"].text = 1.0
      new_hvac_dist.elements["AnnualCoolingDistributionSystemEfficiency"].text = 1.0
    end
  end

  def self.set_systems_mechanical_ventilation_reference(orig_details, hpxml)
    # Table 4.2.2(1) - Whole-House Mechanical ventilation

    # Check for eRatio workaround first
    eratio_fan = orig_details.elements["Systems/MechanicalVentilation/VentilationFans/VentilationFan[UsedForWholeBuildingVentilation='true']/extension"]
    if not eratio_fan.nil?
      vent_fan = eratio_fan.elements["OverrideVentilationFan"]
    else
      vent_fan = orig_details.elements["Systems/MechanicalVentilation/VentilationFans/VentilationFan[UsedForWholeBuildingVentilation='true']"]
    end

    fan_type = nil
    sys_id = "MechanicalVentilation"
    if not vent_fan.nil?
      vent_fan_values = HPXML.get_ventilation_fan_values(ventilation_fan: vent_fan,
                                                         select: [:id, :fan_type])
      fan_type = vent_fan_values[:fan_type]
      sys_id = vent_fan_values[:id]
    end

    q_tot = calc_mech_vent_q_tot()

    # Calculate fan cfm for airflow rate using Reference Home infiltration
    # http://www.resnet.us/standards/Interpretation_on_Reference_Home_Air_Exchange_Rate_approved.pdf
    ref_sla = 0.00036
    q_fan_airflow = calc_mech_vent_q_fan(q_tot, ref_sla)

    # Calculate fan cfm for fan power using Rated Home infiltration
    # http://www.resnet.us/standards/Interpretation_on_Reference_Home_mechVent_fanCFM_approved.pdf
    if fan_type.nil?
      fan_type = 'exhaust only'
      fan_power_w = 0.0
    else
      rated_sla = nil
      air_infiltration_measurements_values = []
      # Check for eRatio workaround first
      orig_details.elements.each("Enclosure/AirInfiltration/AirInfiltrationMeasurement/extension/OverrideAirInfiltrationMeasurement") do |air_infiltration_measurement|
        air_infiltration_measurements_values << HPXML.get_air_infiltration_measurement_values(air_infiltration_measurement: air_infiltration_measurement)
      end
      if air_infiltration_measurements_values.empty?
        orig_details.elements.each("Enclosure/AirInfiltration/AirInfiltrationMeasurement") do |air_infiltration_measurement|
          air_infiltration_measurements_values << HPXML.get_air_infiltration_measurement_values(air_infiltration_measurement: air_infiltration_measurement)
        end
      end
      air_infiltration_measurements_values.each do |air_infiltration_measurement_values|
        if air_infiltration_measurement_values[:unit_of_measure] == 'ACHnatural'
          nach = air_infiltration_measurement_values[:air_leakage]
          rated_sla = Airflow.get_infiltration_SLA_from_ACH(nach, @ncfl, @weather)
          break
        elsif air_infiltration_measurement_values[:unit_of_measure] == 'CFM' and air_infiltration_measurement_values[:house_pressure] == 50
          ach50 = air_infiltration_measurement_values[:air_leakage] * 60.0 / @infilvolume
          rated_sla = Airflow.get_infiltration_SLA_from_ACH50(ach50, 0.65, @cfa, @infilvolume)
          break
        elsif air_infiltration_measurement_values[:unit_of_measure] == 'ACH' and air_infiltration_measurement_values[:house_pressure] == 50
          ach50 = air_infiltration_measurement_values[:air_leakage]
          rated_sla = Airflow.get_infiltration_SLA_from_ACH50(ach50, 0.65, @cfa, @infilvolume)
          break
        end
      end
      q_fan_power = calc_mech_vent_q_fan(q_tot, rated_sla)

      # Treat CFIS like supply ventilation
      if fan_type == 'central fan integrated supply'
        fan_type = 'supply only'
      end

      fan_power_w = nil
      if fan_type == 'supply only' or fan_type == 'exhaust only'
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
    end

    HPXML.add_ventilation_fan(hpxml: hpxml,
                              id: sys_id,
                              fan_type: fan_type,
                              tested_flow_rate: q_fan_airflow,
                              hours_in_operation: 24,
                              fan_power: fan_power_w)
  end

  def self.set_systems_mechanical_ventilation_rated(orig_details, hpxml)
    # Table 4.2.2(1) - Whole-House Mechanical ventilation
    vent_fan = orig_details.elements["Systems/MechanicalVentilation/VentilationFans/VentilationFan[UsedForWholeBuildingVentilation='true']"]
    if not vent_fan.nil?
      vent_fan_values = HPXML.get_ventilation_fan_values(ventilation_fan: vent_fan)

      # Calculate min airflow rate
      min_q_tot = calc_mech_vent_q_tot()
      sla = nil
      hpxml.elements.each("Building/BuildingDetails/Enclosure/AirInfiltration/AirInfiltrationMeasurement") do |air_infiltration_measurement|
        air_infiltration_measurement_values = HPXML.get_air_infiltration_measurement_values(air_infiltration_measurement: air_infiltration_measurement)
        if air_infiltration_measurement_values[:unit_of_measure] == 'ACH' and air_infiltration_measurement_values[:house_pressure] == 50
          ach50 = air_infiltration_measurement_values[:air_leakage]
          sla = Airflow.get_infiltration_SLA_from_ACH50(ach50, 0.65, @cfa, @infilvolume)
          break
        end
      end
      min_q_fan = calc_mech_vent_q_fan(min_q_tot, sla)

      fan_w_per_cfm = vent_fan_values[:fan_power] / vent_fan_values[:tested_flow_rate]
      q_fan = vent_fan_values[:tested_flow_rate] * vent_fan_values[:hours_in_operation] / 24.0
      if q_fan < min_q_fan
        # First try increasing operation to meet minimum
        vent_fan_values[:hours_in_operation] = [min_q_fan / q_fan * vent_fan_values[:hours_in_operation], 24].min
        q_fan = vent_fan_values[:tested_flow_rate] * vent_fan_values[:hours_in_operation] / 24.0
      end
      if q_fan < min_q_fan
        # Finally resort to increasing airflow rate
        vent_fan_values[:tested_flow_rate] *= min_q_fan / q_fan
      end
      vent_fan_values[:fan_power] = fan_w_per_cfm * vent_fan_values[:tested_flow_rate]

      HPXML.add_ventilation_fan(hpxml: hpxml, **vent_fan_values)
    end
  end

  def self.set_systems_mechanical_ventilation_iad(orig_details, hpxml)
    # Table 4.3.1(1) Configuration of Index Adjustment Design - Whole-House Mechanical ventilation fan energy
    # Table 4.3.1(1) Configuration of Index Adjustment Design - Air exchange rate

    q_tot = calc_mech_vent_q_tot()

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
    fan_type = "balanced"
    q_fan = calc_mech_vent_q_fan(q_tot, sla)

    w_cfm = 0.70
    fan_power_w = w_cfm * q_fan

    HPXML.add_ventilation_fan(hpxml: hpxml,
                              id: "VentilationFan",
                              fan_type: fan_type,
                              tested_flow_rate: q_fan,
                              hours_in_operation: 24,
                              fan_power: fan_power_w)
  end

  def self.set_systems_water_heater_reference(orig_details, hpxml)
    # Table 4.2.2(1) - Service water heating systems

    orig_details.elements.each("Systems/WaterHeating/WaterHeatingSystem") do |wh_sys|
      wh_sys_values = HPXML.get_water_heating_system_values(water_heating_system: wh_sys)

      if ['space-heating boiler with tankless coil', 'instantaneous water heater'].include? wh_sys_values[:water_heater_type]
        wh_sys_values[:tank_volume] = 40.0
      end
      # Set fuel type for combi systems
      if ['space-heating boiler with tankless coil', 'space-heating boiler with storage tank'].include? wh_sys_values[:water_heater_type]
        wh_sys_values[:fuel_type] = Waterheater.get_combi_system_fuel(wh_sys_values[:related_hvac], orig_details)
        wh_sys_values[:related_hvac] = nil
      end

      wh_sys_values[:water_heater_type] = 'storage water heater'
      wh_sys_values[:jacket_r_value] = nil

      wh_sys_values[:energy_factor], wh_sys_values[:recovery_efficiency] = get_water_heater_ef_and_re(wh_sys_values[:fuel_type], wh_sys_values[:tank_volume])

      num_water_heaters = orig_details.elements["Systems/WaterHeating/WaterHeatingSystem"].size
      wh_sys_values[:heating_capacity] = Waterheater.calc_water_heater_capacity(to_beopt_fuel(wh_sys_values[:fuel_type]), @nbeds, num_water_heaters) * 1000.0 # Btuh

      if [Constants.CalcTypeERIIndexAdjustmentDesign, Constants.CalcTypeERIIndexAdjustmentReferenceHome].include? @calc_type
        # Hot water equipment shall be located in conditioned space.
        wh_sys_values[:location] = "living space"
      end
      wh_sys_values[:location].gsub!("unvented", "vented")

      # Ensure no desuperheater
      wh_sys_values[:uses_desuperheater] = false
      wh_sys_values[:related_hvac] = nil

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

      if wh_sys_values[:water_heater_type] == 'storage water heater' and wh_sys_values[:heating_capacity].nil?
        num_water_heaters = orig_details.elements["Systems/WaterHeating/WaterHeatingSystem"].size
        wh_sys_values[:heating_capacity] = Waterheater.calc_water_heater_capacity(to_beopt_fuel(wh_sys_values[:fuel_type]), @nbeds, num_water_heaters) * 1000.0 # Btuh
      end

      if wh_sys_values[:water_heater_type] == 'instantaneous water heater'
        wh_sys_values[:performance_adjustment] = Waterheater.get_tankless_cycling_derate()
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

    standard_piping_length = HotWaterAndAppliances.get_default_std_pipe_length(@has_uncond_bsmnt, @cfa, @ncfl)

    if water_heating.nil?
      sys_id = "HotWaterDistribution"
    else
      hw_dist_values = HPXML.get_hot_water_distribution_values(hot_water_distribution: water_heating.elements["HotWaterDistribution"],
                                                               select: [:id])
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
    washer_values = HPXML.get_clothes_washer_values(clothes_washer: orig_details.elements["Appliances/ClothesWasher"],
                                                    select: [:id])

    HPXML.add_clothes_washer(hpxml: hpxml,
                             id: washer_values[:id],
                             location: "living space",
                             integrated_modified_energy_factor: HotWaterAndAppliances.get_clothes_washer_reference_imef(),
                             rated_annual_kwh: HotWaterAndAppliances.get_clothes_washer_reference_ler(),
                             label_electric_rate: HotWaterAndAppliances.get_clothes_washer_reference_elec_rate(),
                             label_gas_rate: HotWaterAndAppliances.get_clothes_washer_reference_gas_rate(),
                             label_annual_gas_cost: HotWaterAndAppliances.get_clothes_washer_reference_agc(),
                             capacity: HotWaterAndAppliances.get_clothes_washer_reference_cap())
  end

  def self.set_appliances_clothes_washer_rated(orig_details, hpxml)
    washer_values = HPXML.get_clothes_washer_values(clothes_washer: orig_details.elements["Appliances/ClothesWasher"])

    HPXML.add_clothes_washer(hpxml: hpxml, **washer_values)
  end

  def self.set_appliances_clothes_washer_iad(orig_details, hpxml)
    # Table 4.3.1(1) Configuration of Index Adjustment Design - Lighting, Appliances and Miscellaneous Electric Loads (MELs)
    self.set_appliances_clothes_washer_reference(orig_details, hpxml)
  end

  def self.set_appliances_clothes_dryer_reference(orig_details, hpxml)
    dryer_values = HPXML.get_clothes_dryer_values(clothes_dryer: orig_details.elements["Appliances/ClothesDryer"],
                                                  select: [:id, :fuel_type])

    HPXML.add_clothes_dryer(hpxml: hpxml,
                            id: dryer_values[:id],
                            location: "living space",
                            fuel_type: dryer_values[:fuel_type],
                            combined_energy_factor: HotWaterAndAppliances.get_clothes_dryer_reference_cef(to_beopt_fuel(dryer_values[:fuel_type])),
                            control_type: HotWaterAndAppliances.get_clothes_dryer_reference_control())
  end

  def self.set_appliances_clothes_dryer_rated(orig_details, hpxml)
    dryer_values = HPXML.get_clothes_dryer_values(clothes_dryer: orig_details.elements["Appliances/ClothesDryer"])

    HPXML.add_clothes_dryer(hpxml: hpxml, **dryer_values)
  end

  def self.set_appliances_clothes_dryer_iad(orig_details, hpxml)
    # Table 4.3.1(1) Configuration of Index Adjustment Design - Lighting, Appliances and Miscellaneous Electric Loads (MELs)
    self.set_appliances_clothes_dryer_reference(orig_details, hpxml)
  end

  def self.set_appliances_dishwasher_reference(orig_details, hpxml)
    dishwasher_values = HPXML.get_dishwasher_values(dishwasher: orig_details.elements["Appliances/Dishwasher"],
                                                    select: [:id])

    HPXML.add_dishwasher(hpxml: hpxml,
                         id: dishwasher_values[:id],
                         energy_factor: HotWaterAndAppliances.get_dishwasher_reference_ef(),
                         place_setting_capacity: HotWaterAndAppliances.get_dishwasher_reference_cap())
  end

  def self.set_appliances_dishwasher_rated(orig_details, hpxml)
    dishwasher_values = HPXML.get_dishwasher_values(dishwasher: orig_details.elements["Appliances/Dishwasher"])

    HPXML.add_dishwasher(hpxml: hpxml, **dishwasher_values)
  end

  def self.set_appliances_dishwasher_iad(orig_details, hpxml)
    # Table 4.3.1(1) Configuration of Index Adjustment Design - Lighting, Appliances and Miscellaneous Electric Loads (MELs)
    self.set_appliances_dishwasher_reference(orig_details, hpxml)
  end

  def self.set_appliances_refrigerator_reference(orig_details, hpxml)
    fridge_values = HPXML.get_refrigerator_values(refrigerator: orig_details.elements["Appliances/Refrigerator"],
                                                  select: [:id])

    # Table 4.2.2.5(1) Lighting, Appliance and Miscellaneous Electric Loads in electric ERI Reference Homes
    refrigerator_kwh = HotWaterAndAppliances.get_refrigerator_reference_annual_kwh(@nbeds)

    HPXML.add_refrigerator(hpxml: hpxml,
                           id: fridge_values[:id],
                           location: "living space",
                           rated_annual_kwh: refrigerator_kwh)
  end

  def self.set_appliances_refrigerator_rated(orig_details, hpxml)
    fridge_values = HPXML.get_refrigerator_values(refrigerator: orig_details.elements["Appliances/Refrigerator"])

    HPXML.add_refrigerator(hpxml: hpxml, **fridge_values)
  end

  def self.set_appliances_refrigerator_iad(orig_details, hpxml)
    # Table 4.3.1(1) Configuration of Index Adjustment Design - Lighting, Appliances and Miscellaneous Electric Loads (MELs)
    self.set_appliances_refrigerator_reference(orig_details, hpxml)
  end

  def self.set_appliances_cooking_range_oven_reference(orig_details, hpxml)
    range_values = HPXML.get_cooking_range_values(cooking_range: orig_details.elements["Appliances/CookingRange"],
                                                  select: [:id, :fuel_type])
    oven_values = HPXML.get_oven_values(oven: orig_details.elements["Appliances/Oven"],
                                        select: [:id])

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
      re = 0.78
    end
    return ef.round(2), re
  end

  def self.has_fuel_access(orig_details)
    orig_details.elements.each("BuildingSummary/Site/FuelTypesAvailable/Fuel") do |fuel|
      if fuel.text != "electricity"
        return true
      end
    end
    return false
  end

  def self.calc_mech_vent_q_tot()
    return Airflow.get_mech_vent_whole_house_cfm(1.0, @nbeds, @cfa, '2013')
  end

  def self.calc_mech_vent_q_fan(q_tot, sla)
    if @is_sfa_or_mf # No infiltration credit for attached/multifamily
      return q_tot
    end

    vert_distance = Float(@ncfl_ag) * @infilvolume / @cfa # vertical distance between lowest and highest above-grade points within the pressure boundary
    nl = 1000.0 * sla * (vert_distance / 8.202)**0.4 # Normalized leakage, eq. 4.4
    q_inf = nl * @weather.data.WSF * @cfa / 7.3 # Effective annual average infiltration rate, cfm, eq. 4.5a
    if q_inf > 2.0 / 3.0 * q_tot
      q_fan = q_tot - 2.0 / 3.0 * q_tot
    else
      q_fan = q_tot - q_inf
    end

    return [q_fan, 0].max
  end

  def self.add_reference_heating_gas_furnace(hpxml, ref_hvacdist_ids, values = {})
    # 78% AFUE gas furnace
    load_frac = values[:fraction_heat_load_served]
    load_frac = 1.0 if load_frac.nil?
    seed_id = values[:id]
    cnt = REXML::XPath.first(hpxml, "count(Building/BuildingDetails/Systems/HVAC/HVACPlant/HeatingSystem)")
    ref_hvacdist_ids << "HVACDistribution_DSE#{ref_hvacdist_ids.size + 1}"
    heat_sys = HPXML.add_heating_system(hpxml: hpxml,
                                        id: "HeatingSystem#{cnt + 1}",
                                        distribution_system_idref: ref_hvacdist_ids[-1],
                                        heating_system_type: "Furnace",
                                        heating_system_fuel: "natural gas",
                                        heating_capacity: -1, # Use Manual J auto-sizing
                                        heating_efficiency_afue: 0.78,
                                        fraction_heat_load_served: load_frac)
    if not seed_id.nil? and [Constants.CalcTypeERIReferenceHome,
                             Constants.CalcTypeERIIndexAdjustmentReferenceHome].include? @calc_type
      # Map reference home system back to rated home system
      HPXML.add_extension(parent: heat_sys,
                          extensions: { "SeedId": seed_id })
    end
  end

  def self.add_reference_heating_gas_boiler(hpxml, ref_hvacdist_ids, values = {})
    # 80% AFUE gas boiler
    load_frac = values[:fraction_heat_load_served]
    load_frac = 1.0 if load_frac.nil?
    seed_id = values[:id]
    cnt = REXML::XPath.first(hpxml, "count(Building/BuildingDetails/Systems/HVAC/HVACPlant/HeatingSystem)")
    ref_hvacdist_ids << "HVACDistribution_DSE#{ref_hvacdist_ids.size + 1}"
    heat_sys = HPXML.add_heating_system(hpxml: hpxml,
                                        id: "HeatingSystem#{cnt + 1}",
                                        distribution_system_idref: ref_hvacdist_ids[-1],
                                        heating_system_type: "Boiler",
                                        heating_system_fuel: "natural gas",
                                        heating_capacity: -1, # Use Manual J auto-sizing
                                        heating_efficiency_afue: 0.80,
                                        fraction_heat_load_served: load_frac)
    if not seed_id.nil? and [Constants.CalcTypeERIReferenceHome,
                             Constants.CalcTypeERIIndexAdjustmentReferenceHome].include? @calc_type
      # Map reference home system back to rated home system
      HPXML.add_extension(parent: heat_sys,
                          extensions: { "SeedId": seed_id })
    end
  end

  def self.add_reference_heating_heat_pump(hpxml, ref_hvacdist_ids, values = {})
    # 7.7 HSPF air source heat pump
    load_frac = values[:fraction_heat_load_served]
    load_frac = 1.0 if load_frac.nil?
    seed_id = values[:id]
    cnt = REXML::XPath.first(hpxml, "count(Building/BuildingDetails/Systems/HVAC/HVACPlant/HeatPump)")
    ref_hvacdist_ids << "HVACDistribution_DSE#{ref_hvacdist_ids.size + 1}"
    heat_pump = HPXML.add_heat_pump(hpxml: hpxml,
                                    id: "HeatPump#{cnt + 1}",
                                    distribution_system_idref: ref_hvacdist_ids[-1],
                                    heat_pump_type: "air-to-air",
                                    heat_pump_fuel: "electricity",
                                    cooling_capacity: -1, # Use Manual J auto-sizing
                                    heating_capacity: -1, # Use Manual J auto-sizing
                                    backup_heating_fuel: "electricity",
                                    backup_heating_capacity: -1,
                                    backup_heating_efficiency_percent: 1.0,
                                    fraction_heat_load_served: load_frac,
                                    fraction_cool_load_served: 0.0,
                                    cooling_efficiency_seer: 13.0, # Arbitrary, not used
                                    heating_efficiency_hspf: 7.7)
    if not seed_id.nil? and [Constants.CalcTypeERIReferenceHome,
                             Constants.CalcTypeERIIndexAdjustmentReferenceHome].include? @calc_type
      # Map reference home system back to rated home system
      HPXML.add_extension(parent: heat_pump,
                          extensions: { "SeedId": seed_id })
    end
  end

  def self.add_reference_cooling_air_conditioner(hpxml, ref_hvacdist_ids, values = {})
    # 13 SEER electric air conditioner
    load_frac = values[:fraction_cool_load_served]
    load_frac = 1.0 if load_frac.nil?
    seed_id = values[:id]
    cnt = REXML::XPath.first(hpxml, "count(Building/BuildingDetails/Systems/HVAC/HVACPlant/CoolingSystem)")
    ref_hvacdist_ids << "HVACDistribution_DSE#{ref_hvacdist_ids.size + 1}"
    cool_sys = HPXML.add_cooling_system(hpxml: hpxml,
                                        id: "CoolingSystem#{cnt + 1}",
                                        distribution_system_idref: ref_hvacdist_ids[-1],
                                        cooling_system_type: "central air conditioner",
                                        cooling_system_fuel: "electricity",
                                        cooling_capacity: -1, # Use Manual J auto-sizing
                                        fraction_cool_load_served: load_frac,
                                        cooling_efficiency_seer: 13.0,
                                        cooling_shr: values[:cooling_shr])
    if not seed_id.nil? and [Constants.CalcTypeERIReferenceHome,
                             Constants.CalcTypeERIIndexAdjustmentReferenceHome].include? @calc_type
      # Map reference home system back to rated home system
      HPXML.add_extension(parent: cool_sys,
                          extensions: { "SeedId": seed_id })
    end
  end

  def self.add_reference_distribution_system(hpxml, ref_hvacdist_ids)
    # Table 4.2.2(1) - Thermal distribution systems
    ref_hvacdist_ids.each do |ref_hvacdist_id|
      HPXML.add_hvac_distribution(hpxml: hpxml,
                                  id: ref_hvacdist_id,
                                  distribution_system_type: "DSE",
                                  annual_heating_dse: 0.8,
                                  annual_cooling_dse: 0.8)
    end
  end

  def self.add_reference_water_heater(orig_details, hpxml)
    wh_fuel_type = get_predominant_heating_fuel(orig_details)
    wh_tank_vol = 40.0

    wh_ef, wh_re = get_water_heater_ef_and_re(wh_fuel_type, wh_tank_vol)
    wh_cap = Waterheater.calc_water_heater_capacity(to_beopt_fuel(wh_fuel_type), @nbeds, 1) * 1000.0 # Btuh

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
      heating_values = HPXML.get_heating_system_values(heating_system: heating,
                                                       select: [:heating_system_fuel, :fraction_heat_load_served])
      fuel = heating_values[:heating_system_fuel]
      if fuel_fracs[fuel].nil?
        fuel_fracs[fuel] = 0.0
      end
      fuel_fracs[fuel] += heating_values[:fraction_heat_load_served]
    end

    orig_details.elements.each("Systems/HVAC/HVACPlant/HeatPump") do |hp|
      hp_values = HPXML.get_heat_pump_values(heat_pump: hp,
                                             select: [:heat_pump_fuel, :fraction_heat_load_served])
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
      air_infiltration_measurement_values = HPXML.get_air_infiltration_measurement_values(air_infiltration_measurement: air_infiltration_measurement,
                                                                                          select: [:infiltration_volume])
      next if air_infiltration_measurement_values[:infiltration_volume].nil?

      infilvolume = air_infiltration_measurement_values[:infiltration_volume]
      break
    end

    return infilvolume
  end

  def self.calc_wall_areas_for_windows(orig_details)
    ag_bndry_wall_area = 0.0
    bg_bndry_wall_area = 0.0
    common_wall_area = 0.0 # Excludes foundation walls

    orig_details.elements.each("Enclosure/Walls/Wall") do |wall|
      wall_values = HPXML.get_wall_values(wall: wall,
                                          select: [:area, :interior_adjacent_to, :exterior_adjacent_to])
      if is_thermal_boundary(wall_values)
        ag_bndry_wall_area += wall_values[:area]
      elsif wall_values[:exterior_adjacent_to] == "other housing unit"
        common_wall_area += wall_values[:area]
      end
    end

    orig_details.elements.each("Enclosure/RimJoists/RimJoist") do |rim_joist|
      rim_joist_values = HPXML.get_rim_joist_values(rim_joist: rim_joist,
                                                    select: [:area, :interior_adjacent_to, :exterior_adjacent_to])
      if is_thermal_boundary(rim_joist_values)
        ag_bndry_wall_area += rim_joist_values[:area]
      elsif rim_joist_values[:exterior_adjacent_to] == "other housing unit"
        common_wall_area += rim_joist_values[:area]
      end
    end

    orig_details.elements.each("Enclosure/FoundationWalls/FoundationWall") do |fwall|
      fwall_values = HPXML.get_foundation_wall_values(foundation_wall: fwall,
                                                      select: [:area, :height, :depth_below_grade, :interior_adjacent_to, :exterior_adjacent_to])
      next unless is_thermal_boundary(fwall_values)

      height = fwall_values[:height]
      bg_depth = fwall_values[:depth_below_grade]
      area = fwall_values[:area]
      ag_bndry_wall_area += (height - bg_depth) / height * area
      bg_bndry_wall_area += bg_depth / height * area
    end

    return ag_bndry_wall_area, bg_bndry_wall_area, common_wall_area
  end

  def self.delete_wall_subsurfaces(orig_details, surface_id)
    orig_details.elements.each("Enclosure/*/*[AttachedToWall[@idref='#{surface_id}']]") do |subsurface|
      subsurface.parent.elements.delete subsurface
    end
  end

  def self.delete_roof_subsurfaces(orig_details, surface_id)
    orig_details.elements.each("Enclosure/*/*[AttachedToRoof[@idref='#{surface_id}']]") do |subsurface|
      subsurface.parent.elements.delete subsurface
    end
  end

  def self.get_has_space_type(orig_details, adjacent_to)
    return !orig_details.elements["Enclosure/*/*[InteriorAdjacentTo='#{adjacent_to}' or ExteriorAdjacentTo='#{adjacent_to}']"].nil?
  end
end

def calc_area_weighted_sum_of_exterior_thermal_boundary_values(surfaces_values, key, use_inverse = false)
  sum_area = 0
  sum_val_times_area = 0
  surfaces_values.each do |surface_values|
    next unless is_exterior_thermal_boundary(surface_values) or (surface_values[:interior_adjacent_to].nil? and surface_values[:exterior_adjacent_to].nil?)

    sum_area += surface_values[:area]
    if use_inverse
      sum_val_times_area += (1.0 / surface_values[key] * surface_values[:area])
    else
      sum_val_times_area += (surface_values[key] * surface_values[:area])
    end
  end
  if sum_area > 0
    if use_inverse
      return 1.0 / (sum_val_times_area / sum_area)
    else
      return sum_val_times_area / sum_area
    end
  end
  return 0
end

def calc_sum_of_exterior_thermal_boundary_values(surfaces_values)
  sum_val = 0
  surfaces_values.each do |surface_values|
    next unless is_exterior_thermal_boundary(surface_values) or (surface_values[:interior_adjacent_to].nil? and surface_values[:exterior_adjacent_to].nil?)

    sum_val += surface_values[:area]
  end
  return sum_val
end

def is_exterior_thermal_boundary(surface_values)
  return (is_thermal_boundary(surface_values) and surface_values[:exterior_adjacent_to] == "outside")
end
