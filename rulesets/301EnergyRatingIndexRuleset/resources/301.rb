require_relative '../../../hpxml-measures/HPXMLtoOpenStudio/resources/airflow'
require_relative '../../../hpxml-measures/HPXMLtoOpenStudio/resources/constants'
require_relative '../../../hpxml-measures/HPXMLtoOpenStudio/resources/constructions'
require_relative '../../../hpxml-measures/HPXMLtoOpenStudio/resources/geometry'
require_relative '../../../hpxml-measures/HPXMLtoOpenStudio/resources/hotwater_appliances'
require_relative '../../../hpxml-measures/HPXMLtoOpenStudio/resources/hpxml'
require_relative '../../../hpxml-measures/HPXMLtoOpenStudio/resources/lighting'
require_relative '../../../hpxml-measures/HPXMLtoOpenStudio/resources/misc_loads'
require_relative '../../../hpxml-measures/HPXMLtoOpenStudio/resources/unit_conversions'
require_relative '../../../hpxml-measures/HPXMLtoOpenStudio/resources/waterheater'

class EnergyRatingIndex301Ruleset
  def self.apply_ruleset(hpxml, calc_type, weather)
    # Global variables
    @weather = weather
    @calc_type = calc_type

    # Determine building type: single family detached or attached (including multifamily)
    @is_attached_unit = false
    (hpxml.rim_joists + hpxml.walls + hpxml.foundation_walls + hpxml.frame_floors).each do |surface|
      next unless surface.exterior_adjacent_to.include? HPXML::LocationOtherHousingUnit

      @is_attached_unit = true
    end

    # Update HPXML object based on calculation type
    if calc_type == Constants.CalcTypeERIReferenceHome
      hpxml = apply_reference_home_ruleset(hpxml)
    elsif calc_type == Constants.CalcTypeERIRatedHome
      hpxml = apply_rated_home_ruleset(hpxml)
    elsif calc_type == Constants.CalcTypeERIIndexAdjustmentDesign
      hpxml = apply_index_adjustment_design_ruleset(hpxml)
    elsif calc_type == Constants.CalcTypeERIIndexAdjustmentReferenceHome
      hpxml = apply_index_adjustment_design_ruleset(hpxml)
      hpxml.to_rexml # FIXME: Needed for eRatio workaround
      hpxml = apply_reference_home_ruleset(hpxml)
    end

    return hpxml
  end

  def self.apply_reference_home_ruleset(orig_hpxml)
    new_hpxml = create_new_hpxml(orig_hpxml)

    # BuildingSummary
    set_summary_reference(orig_hpxml, new_hpxml)

    # ClimateAndRiskZones
    set_climate(orig_hpxml, new_hpxml)

    # Enclosure
    set_enclosure_air_infiltration_reference(orig_hpxml, new_hpxml)
    set_enclosure_attics_reference(orig_hpxml, new_hpxml)
    set_enclosure_foundations_reference(orig_hpxml, new_hpxml)
    set_enclosure_roofs_reference(orig_hpxml, new_hpxml)
    set_enclosure_rim_joists_reference(orig_hpxml, new_hpxml)
    set_enclosure_walls_reference(orig_hpxml, new_hpxml)
    set_enclosure_foundation_walls_reference(orig_hpxml, new_hpxml)
    set_enclosure_ceilings_reference(orig_hpxml, new_hpxml)
    set_enclosure_floors_reference(orig_hpxml, new_hpxml)
    set_enclosure_slabs_reference(orig_hpxml, new_hpxml)
    set_enclosure_windows_reference(orig_hpxml, new_hpxml)
    set_enclosure_skylights_reference(orig_hpxml, new_hpxml)
    set_enclosure_doors_reference(orig_hpxml, new_hpxml)

    # Systems
    set_systems_hvac_reference(orig_hpxml, new_hpxml)
    set_systems_mechanical_ventilation_reference(orig_hpxml, new_hpxml)
    set_systems_whole_house_fan_reference(orig_hpxml, new_hpxml)
    set_systems_water_heater_reference(orig_hpxml, new_hpxml)
    set_systems_water_heating_use_reference(orig_hpxml, new_hpxml)
    set_systems_solar_thermal_reference(orig_hpxml, new_hpxml)
    set_systems_photovoltaics_reference(orig_hpxml, new_hpxml)

    # Appliances
    set_appliances_clothes_washer_reference(orig_hpxml, new_hpxml)
    set_appliances_clothes_dryer_reference(orig_hpxml, new_hpxml)
    set_appliances_dishwasher_reference(orig_hpxml, new_hpxml)
    set_appliances_refrigerator_reference(orig_hpxml, new_hpxml)
    set_appliances_cooking_range_oven_reference(orig_hpxml, new_hpxml)

    # Lighting
    set_lighting_reference(orig_hpxml, new_hpxml)
    set_ceiling_fans_reference(orig_hpxml, new_hpxml)

    # MiscLoads
    set_misc_loads_reference(orig_hpxml, new_hpxml)

    return new_hpxml
  end

  def self.apply_rated_home_ruleset(orig_hpxml)
    new_hpxml = create_new_hpxml(orig_hpxml)

    # BuildingSummary
    set_summary_rated(orig_hpxml, new_hpxml)

    # ClimateAndRiskZones
    set_climate(orig_hpxml, new_hpxml)

    # Enclosure
    set_enclosure_air_infiltration_rated(orig_hpxml, new_hpxml)
    set_enclosure_attics_rated(orig_hpxml, new_hpxml)
    set_enclosure_foundations_rated(orig_hpxml, new_hpxml)
    set_enclosure_roofs_rated(orig_hpxml, new_hpxml)
    set_enclosure_rim_joists_rated(orig_hpxml, new_hpxml)
    set_enclosure_walls_rated(orig_hpxml, new_hpxml)
    set_enclosure_foundation_walls_rated(orig_hpxml, new_hpxml)
    set_enclosure_ceilings_rated(orig_hpxml, new_hpxml)
    set_enclosure_floors_rated(orig_hpxml, new_hpxml)
    set_enclosure_slabs_rated(orig_hpxml, new_hpxml)
    set_enclosure_windows_rated(orig_hpxml, new_hpxml)
    set_enclosure_skylights_rated(orig_hpxml, new_hpxml)
    set_enclosure_doors_rated(orig_hpxml, new_hpxml)

    # Systems
    set_systems_hvac_rated(orig_hpxml, new_hpxml)
    set_systems_mechanical_ventilation_rated(orig_hpxml, new_hpxml)
    set_systems_whole_house_fan_rated(orig_hpxml, new_hpxml)
    set_systems_water_heater_rated(orig_hpxml, new_hpxml)
    set_systems_water_heating_use_rated(orig_hpxml, new_hpxml)
    set_systems_solar_thermal_rated(orig_hpxml, new_hpxml)
    set_systems_photovoltaics_rated(orig_hpxml, new_hpxml)

    # Appliances
    set_appliances_clothes_washer_rated(orig_hpxml, new_hpxml)
    set_appliances_clothes_dryer_rated(orig_hpxml, new_hpxml)
    set_appliances_dishwasher_rated(orig_hpxml, new_hpxml)
    set_appliances_refrigerator_rated(orig_hpxml, new_hpxml)
    set_appliances_cooking_range_oven_rated(orig_hpxml, new_hpxml)

    # Lighting
    set_lighting_rated(orig_hpxml, new_hpxml)
    set_ceiling_fans_rated(orig_hpxml, new_hpxml)

    # MiscLoads
    set_misc_loads_rated(orig_hpxml, new_hpxml)

    return new_hpxml
  end

  def self.apply_index_adjustment_design_ruleset(orig_hpxml)
    new_hpxml = create_new_hpxml(orig_hpxml)

    remove_surfaces_from_iad(orig_hpxml)

    # BuildingSummary
    set_summary_iad(orig_hpxml, new_hpxml)

    # ClimateAndRiskZones
    set_climate(orig_hpxml, new_hpxml)

    # Enclosure
    set_enclosure_air_infiltration_iad(orig_hpxml, new_hpxml)
    set_enclosure_attics_iad(orig_hpxml, new_hpxml)
    set_enclosure_foundations_iad(orig_hpxml, new_hpxml)
    set_enclosure_roofs_iad(orig_hpxml, new_hpxml)
    set_enclosure_rim_joists_iad(orig_hpxml, new_hpxml)
    set_enclosure_walls_iad(orig_hpxml, new_hpxml)
    set_enclosure_foundation_walls_iad(orig_hpxml, new_hpxml)
    set_enclosure_ceilings_iad(orig_hpxml, new_hpxml)
    set_enclosure_floors_iad(orig_hpxml, new_hpxml)
    set_enclosure_slabs_iad(orig_hpxml, new_hpxml)
    set_enclosure_windows_iad(orig_hpxml, new_hpxml)
    set_enclosure_skylights_iad(orig_hpxml, new_hpxml)
    set_enclosure_doors_iad(orig_hpxml, new_hpxml)

    # Systems
    set_systems_hvac_iad(orig_hpxml, new_hpxml)
    set_systems_mechanical_ventilation_iad(orig_hpxml, new_hpxml)
    set_systems_whole_house_fan_iad(orig_hpxml, new_hpxml)
    set_systems_water_heater_iad(orig_hpxml, new_hpxml)
    set_systems_water_heating_use_iad(orig_hpxml, new_hpxml)
    set_systems_solar_thermal_iad(orig_hpxml, new_hpxml)
    set_systems_photovoltaics_iad(orig_hpxml, new_hpxml)

    # Appliances
    set_appliances_clothes_washer_iad(orig_hpxml, new_hpxml)
    set_appliances_clothes_dryer_iad(orig_hpxml, new_hpxml)
    set_appliances_dishwasher_iad(orig_hpxml, new_hpxml)
    set_appliances_refrigerator_iad(orig_hpxml, new_hpxml)
    set_appliances_cooking_range_oven_iad(orig_hpxml, new_hpxml)

    # Lighting
    set_lighting_iad(orig_hpxml, new_hpxml)
    set_ceiling_fans_iad(orig_hpxml, new_hpxml)

    # MiscLoads
    set_misc_loads_iad(orig_hpxml, new_hpxml)

    return new_hpxml
  end

  def self.create_new_hpxml(orig_hpxml)
    new_hpxml = HPXML.new

    @eri_version = orig_hpxml.header.eri_calculation_version
    @eri_version = Constants.ERIVersions[-1] if @eri_version == 'latest'

    new_hpxml.set_header(xml_type: orig_hpxml.header.xml_type,
                         xml_generated_by: 'OpenStudio-ERI',
                         transaction: orig_hpxml.header.transaction,
                         software_program_used: orig_hpxml.header.software_program_used,
                         software_program_version: orig_hpxml.header.software_program_version,
                         eri_calculation_version: @eri_version,
                         eri_design: @calc_type,
                         building_id: orig_hpxml.header.building_id,
                         event_type: orig_hpxml.header.event_type)

    return new_hpxml
  end

  def self.remove_surfaces_from_iad(orig_hpxml)
    # Remove garage surfaces and adiabatic walls.

    # Garage only
    (orig_hpxml.roofs + orig_hpxml.frame_floors + orig_hpxml.slabs).each do |orig_surface|
      next unless [HPXML::LocationGarage].include?(orig_surface.interior_adjacent_to) ||
                  [HPXML::LocationGarage].include?(orig_surface.exterior_adjacent_to)

      orig_surface.delete
    end

    # Garage and adiabatic
    (orig_hpxml.rim_joists + orig_hpxml.walls + orig_hpxml.foundation_walls).each do |orig_surface|
      next unless [HPXML::LocationGarage, HPXML::LocationOtherHousingUnit].include?(orig_surface.interior_adjacent_to) ||
                  [HPXML::LocationGarage, HPXML::LocationOtherHousingUnit].include?(orig_surface.exterior_adjacent_to)

      orig_surface.delete
    end
  end

  def self.set_summary_reference(orig_hpxml, new_hpxml)
    # Global variables
    @bldg_type = orig_hpxml.building_construction.residential_facility_type
    @cfa = orig_hpxml.building_construction.conditioned_floor_area
    @nbeds = orig_hpxml.building_construction.number_of_bedrooms
    @ncfl = orig_hpxml.building_construction.number_of_conditioned_floors
    @ncfl_ag = orig_hpxml.building_construction.number_of_conditioned_floors_above_grade
    @cvolume = orig_hpxml.building_construction.conditioned_building_volume
    @infilvolume = get_infiltration_volume(orig_hpxml)
    @has_uncond_bsmnt = orig_hpxml.has_space_type(HPXML::LocationBasementUnconditioned)

    new_hpxml.set_site(fuels: orig_hpxml.site.fuels,
                       shelter_coefficient: Airflow.get_default_shelter_coefficient())

    new_hpxml.set_building_occupancy(number_of_residents: Geometry.get_occupancy_default_num(@nbeds))

    new_hpxml.set_building_construction(number_of_conditioned_floors: orig_hpxml.building_construction.number_of_conditioned_floors,
                                        number_of_conditioned_floors_above_grade: orig_hpxml.building_construction.number_of_conditioned_floors_above_grade,
                                        number_of_bedrooms: orig_hpxml.building_construction.number_of_bedrooms,
                                        conditioned_floor_area: orig_hpxml.building_construction.conditioned_floor_area,
                                        conditioned_building_volume: orig_hpxml.building_construction.conditioned_building_volume,
                                        residential_facility_type: @bldg_type)
  end

  def self.set_summary_rated(orig_hpxml, new_hpxml)
    # Global variables
    @bldg_type = orig_hpxml.building_construction.residential_facility_type
    @cfa = orig_hpxml.building_construction.conditioned_floor_area
    @nbeds = orig_hpxml.building_construction.number_of_bedrooms
    @ncfl = orig_hpxml.building_construction.number_of_conditioned_floors
    @ncfl_ag = orig_hpxml.building_construction.number_of_conditioned_floors_above_grade
    @cvolume = orig_hpxml.building_construction.conditioned_building_volume
    @infilvolume = get_infiltration_volume(orig_hpxml)
    @has_uncond_bsmnt = orig_hpxml.has_space_type(HPXML::LocationBasementUnconditioned)

    new_hpxml.set_site(fuels: orig_hpxml.site.fuels,
                       shelter_coefficient: Airflow.get_default_shelter_coefficient())

    new_hpxml.set_building_occupancy(number_of_residents: Geometry.get_occupancy_default_num(@nbeds))

    new_hpxml.set_building_construction(number_of_conditioned_floors: orig_hpxml.building_construction.number_of_conditioned_floors,
                                        number_of_conditioned_floors_above_grade: orig_hpxml.building_construction.number_of_conditioned_floors_above_grade,
                                        number_of_bedrooms: orig_hpxml.building_construction.number_of_bedrooms,
                                        conditioned_floor_area: orig_hpxml.building_construction.conditioned_floor_area,
                                        conditioned_building_volume: orig_hpxml.building_construction.conditioned_building_volume,
                                        residential_facility_type: @bldg_type)
  end

  def self.set_summary_iad(orig_hpxml, new_hpxml)
    # Global variables
    # Table 4.3.1(1) Configuration of Index Adjustment Design - General Characteristics
    @bldg_type = orig_hpxml.building_construction.residential_facility_type
    @cfa = 2400
    @nbeds = 3
    @ncfl = 2
    @ncfl_ag = 2
    @cvolume = 20400
    @infilvolume = 20400
    @has_uncond_bsmnt = false

    new_hpxml.set_site(fuels: orig_hpxml.site.fuels,
                       shelter_coefficient: Airflow.get_default_shelter_coefficient())

    new_hpxml.set_building_occupancy(number_of_residents: Geometry.get_occupancy_default_num(@nbeds))

    new_hpxml.set_building_construction(number_of_conditioned_floors: @ncfl,
                                        number_of_conditioned_floors_above_grade: @ncfl_ag,
                                        number_of_bedrooms: @nbeds,
                                        conditioned_floor_area: @cfa,
                                        conditioned_building_volume: @cvolume,
                                        residential_facility_type: @bldg_type)
  end

  def self.set_climate(orig_hpxml, new_hpxml)
    new_hpxml.set_climate_and_risk_zones(iecc2006: orig_hpxml.climate_and_risk_zones.iecc2006,
                                         weather_station_id: orig_hpxml.climate_and_risk_zones.weather_station_id,
                                         weather_station_name: orig_hpxml.climate_and_risk_zones.weather_station_name,
                                         weather_station_wmo: orig_hpxml.climate_and_risk_zones.weather_station_wmo)
    @iecc_zone_2006 = orig_hpxml.climate_and_risk_zones.iecc2006
  end

  def self.set_enclosure_air_infiltration_reference(orig_hpxml, new_hpxml)
    # Table 4.2.2(1) - Air exchange rate
    sla = 0.00036
    ach50 = Airflow.get_infiltration_ACH50_from_SLA(sla, 0.65, @cfa, @infilvolume)

    # Air Infiltration
    new_hpxml.air_infiltration_measurements.add(id: 'Infiltration_ACH50',
                                                house_pressure: 50,
                                                unit_of_measure: HPXML::UnitsACH,
                                                air_leakage: ach50.round(2),
                                                infiltration_volume: @infilvolume)
  end

  def self.set_enclosure_air_infiltration_rated(orig_hpxml, new_hpxml)
    # Table 4.2.2(1) - Air exchange rate

    ach50 = calc_rated_home_infiltration_ach50(orig_hpxml, false)

    # Air Infiltration
    new_hpxml.air_infiltration_measurements.add(id: 'AirInfiltrationMeasurement',
                                                house_pressure: 50,
                                                unit_of_measure: HPXML::UnitsACH,
                                                air_leakage: ach50.round(2),
                                                infiltration_volume: @infilvolume)
  end

  def self.set_enclosure_air_infiltration_iad(orig_hpxml, new_hpxml)
    # Table 4.3.1(1) Configuration of Index Adjustment Design - Air exchange rate
    if ['1A', '1B', '1C', '2A', '2B', '2C'].include? @iecc_zone_2006
      ach50 = 5.0
    elsif ['3A', '3B', '3C', '4A', '4B', '4C', '5A', '5B', '5C', '6A', '6B', '6C', '7', '8'].include? @iecc_zone_2006
      ach50 = 3.0
    end

    # Air Infiltration
    new_hpxml.air_infiltration_measurements.add(id: 'Infiltration_ACH50',
                                                house_pressure: 50,
                                                unit_of_measure: HPXML::UnitsACH,
                                                air_leakage: ach50,
                                                infiltration_volume: @infilvolume)
  end

  def self.set_enclosure_attics_reference(orig_hpxml, new_hpxml)
    # Check if vented attic (or unvented attic, which will become a vented attic) exists
    orig_hpxml.roofs.each do |roof|
      next unless roof.interior_adjacent_to.include? 'attic'

      new_hpxml.attics.add(id: 'VentedAttic',
                           attic_type: HPXML::AtticTypeVented,
                           vented_attic_sla: Airflow.get_default_vented_attic_sla())
      break
    end
  end

  def self.set_enclosure_attics_rated(orig_hpxml, new_hpxml)
    # Preserve vented attic ventilation rate
    orig_hpxml.attics.each do |orig_attic|
      next unless orig_attic.attic_type == HPXML::AtticTypeVented

      new_hpxml.attics.add(id: orig_attic.id,
                           attic_type: orig_attic.attic_type,
                           vented_attic_sla: orig_attic.vented_attic_sla,
                           vented_attic_constant_ach: orig_attic.vented_attic_constant_ach)
    end
  end

  def self.set_enclosure_attics_iad(orig_hpxml, new_hpxml)
    set_enclosure_attics_rated(orig_hpxml, new_hpxml)
  end

  def self.set_enclosure_foundations_reference(orig_hpxml, new_hpxml)
    # Check if vented crawlspace (or unvented crawlspace, which will become a vented crawlspace) exists.
    orig_hpxml.frame_floors.each do |orig_frame_floor|
      next unless orig_frame_floor.interior_adjacent_to.include?('crawlspace') || orig_frame_floor.exterior_adjacent_to.include?('crawlspace')

      new_hpxml.foundations.add(id: 'VentedCrawlspace',
                                foundation_type: HPXML::FoundationTypeCrawlspaceVented,
                                vented_crawlspace_sla: Airflow.get_default_vented_crawl_sla())
      break
    end

    # Preserve unconditioned basement thermal boundary location.
    # TODO: Seems inconsistent with 301 language, but done for consistency with other software tools.
    @uncond_bsmnt_thermal_bndry = nil
    orig_hpxml.foundations.each do |orig_foundation|
      next unless orig_foundation.foundation_type == HPXML::FoundationTypeBasementUnconditioned

      new_hpxml.foundations.add(id: orig_foundation.id,
                                foundation_type: orig_foundation.foundation_type,
                                unconditioned_basement_thermal_boundary: orig_foundation.unconditioned_basement_thermal_boundary)
      @uncond_bsmnt_thermal_bndry = orig_foundation.unconditioned_basement_thermal_boundary
    end
  end

  def self.set_enclosure_foundations_rated(orig_hpxml, new_hpxml)
    # Preserve vented crawlspace ventilation rate.
    reference_crawlspace_sla = Airflow.get_default_vented_crawl_sla()
    orig_hpxml.foundations.each do |orig_foundation|
      next unless orig_foundation.foundation_type == HPXML::FoundationTypeCrawlspaceVented

      vented_crawl_sla = orig_foundation.vented_crawlspace_sla
      if vented_crawl_sla.nil? || (vented_crawl_sla < reference_crawlspace_sla) # FUTURE: Allow approved ground cover
        vented_crawl_sla = reference_crawlspace_sla
      end
      new_hpxml.foundations.add(id: orig_foundation.id,
                                foundation_type: orig_foundation.foundation_type,
                                vented_crawlspace_sla: vented_crawl_sla)
    end

    # Preserve unconditioned basement thermal boundary location.
    @uncond_bsmnt_thermal_bndry = nil
    orig_hpxml.foundations.each do |foundation|
      next unless foundation.foundation_type == HPXML::FoundationTypeBasementUnconditioned

      new_hpxml.foundations.add(id: foundation.id,
                                foundation_type: foundation.foundation_type,
                                unconditioned_basement_thermal_boundary: foundation.unconditioned_basement_thermal_boundary)
      @uncond_bsmnt_thermal_bndry = foundation.unconditioned_basement_thermal_boundary
    end
  end

  def self.set_enclosure_foundations_iad(orig_hpxml, new_hpxml)
    # Always has a vented crawlspace
    new_hpxml.foundations.add(id: 'VentedCrawlspace',
                              foundation_type: HPXML::FoundationTypeCrawlspaceVented,
                              vented_crawlspace_sla: Airflow.get_default_vented_crawl_sla())

    @uncond_bsmnt_thermal_bndry = nil
  end

  def self.set_enclosure_roofs_reference(orig_hpxml, new_hpxml)
    # Table 4.2.2(1) - Roofs
    ceiling_ufactor = Constructions.get_default_ceiling_ufactor(@iecc_zone_2006)

    ext_thermal_bndry_roofs = orig_hpxml.roofs.select { |roof| roof.is_exterior_thermal_boundary }
    sum_gross_area = ext_thermal_bndry_roofs.map { |roof| roof.area }.inject(0, :+)
    avg_pitch = calc_area_weighted_sum(ext_thermal_bndry_roofs, :pitch)
    solar_abs = 0.75
    emittance = 0.90

    # Create insulated roofs for exterior thermal boundary surface.
    # Area is equally distributed to each direction to be consistent with walls.
    if sum_gross_area > 0
      new_hpxml.roofs.add(id: 'RoofArea',
                          interior_adjacent_to: HPXML::LocationLivingSpace,
                          area: sum_gross_area,
                          azimuth: nil,
                          solar_absorptance: solar_abs,
                          emittance: emittance,
                          pitch: avg_pitch,
                          radiant_barrier: false,
                          insulation_assembly_r_value: 1.0 / ceiling_ufactor)
    end

    # Preserve other roofs:
    # 1. Non-thermal boundary surfaces (e.g., over garage)
    orig_hpxml.roofs.each do |orig_roof|
      next if orig_roof.is_exterior_thermal_boundary

      insulation_assembly_r_value = [orig_roof.insulation_assembly_r_value, 2.3].min # uninsulated
      new_hpxml.roofs.add(id: orig_roof.id,
                          interior_adjacent_to: orig_roof.interior_adjacent_to.gsub('unvented', 'vented'),
                          area: orig_roof.area,
                          azimuth: orig_roof.azimuth,
                          solar_absorptance: solar_abs,
                          emittance: emittance,
                          pitch: orig_roof.pitch,
                          radiant_barrier: false,
                          insulation_id: orig_roof.insulation_id,
                          insulation_assembly_r_value: insulation_assembly_r_value)
    end
  end

  def self.set_enclosure_roofs_rated(orig_hpxml, new_hpxml)
    # Preserve all roofs
    orig_hpxml.roofs.each do |orig_roof|
      new_hpxml.roofs.add(id: orig_roof.id,
                          interior_adjacent_to: orig_roof.interior_adjacent_to,
                          area: orig_roof.area,
                          azimuth: orig_roof.azimuth,
                          solar_absorptance: orig_roof.solar_absorptance,
                          emittance: orig_roof.emittance,
                          pitch: orig_roof.pitch,
                          radiant_barrier: orig_roof.radiant_barrier,
                          insulation_id: orig_roof.insulation_id,
                          insulation_assembly_r_value: orig_roof.insulation_assembly_r_value)
    end
  end

  def self.set_enclosure_roofs_iad(orig_hpxml, new_hpxml)
    set_enclosure_roofs_rated(orig_hpxml, new_hpxml)

    # Scale down roof area to 1300 sqft while maintaining ratio of attic types.
    sum_roof_area = 0.0
    new_hpxml.roofs.each do |new_roof|
      sum_roof_area += new_roof.area
    end
    new_hpxml.roofs.each do |new_roof|
      new_roof.area = 1300.0 * new_roof.area / sum_roof_area
    end
  end

  def self.set_enclosure_rim_joists_reference(orig_hpxml, new_hpxml)
    # Table 4.2.2(1) - Above-grade walls
    ufactor = Constructions.get_default_frame_wall_ufactor(@iecc_zone_2006)

    ext_thermal_bndry_rim_joists = orig_hpxml.rim_joists.select { |rim_joist| rim_joist.is_exterior && rim_joist.is_thermal_boundary }
    sum_gross_area = ext_thermal_bndry_rim_joists.map { |rim_joist| rim_joist.area }.inject(0, :+)
    solar_abs = 0.75
    emittance = 0.90

    # Create insulated rim joists for exterior thermal boundary surface.
    # Area is equally distributed to each direction to be consistent with walls.
    if sum_gross_area > 0
      new_hpxml.rim_joists.add(id: 'RimJoistArea',
                               exterior_adjacent_to: HPXML::LocationOutside,
                               interior_adjacent_to: HPXML::LocationLivingSpace,
                               area: sum_gross_area,
                               azimuth: nil,
                               solar_absorptance: solar_abs,
                               emittance: emittance,
                               insulation_assembly_r_value: 1.0 / ufactor)
    end

    # Preserve other rim joists:
    # 1. Interior thermal boundary surfaces (e.g., between conditioned basement and crawlspace)
    # 2. Exterior non-thermal boundary surfaces (e.g., between unconditioned basement and outside)
    orig_hpxml.rim_joists.each do |orig_rim_joist|
      next if orig_rim_joist.is_exterior_thermal_boundary

      if orig_rim_joist.is_thermal_boundary
        insulation_assembly_r_value = 1.0 / ufactor
      else
        insulation_assembly_r_value = [orig_rim_joist.insulation_assembly_r_value, 4.0].min # uninsulated
      end
      new_hpxml.rim_joists.add(id: orig_rim_joist.id,
                               exterior_adjacent_to: orig_rim_joist.exterior_adjacent_to.gsub('unvented', 'vented'),
                               interior_adjacent_to: orig_rim_joist.interior_adjacent_to.gsub('unvented', 'vented'),
                               area: orig_rim_joist.area,
                               azimuth: orig_rim_joist.azimuth,
                               solar_absorptance: solar_abs,
                               emittance: emittance,
                               insulation_id: orig_rim_joist.insulation_id,
                               insulation_assembly_r_value: insulation_assembly_r_value)
    end
  end

  def self.set_enclosure_rim_joists_rated(orig_hpxml, new_hpxml)
    # Preserve all rim joists
    orig_hpxml.rim_joists.each do |orig_rim_joist|
      new_hpxml.rim_joists.add(id: orig_rim_joist.id,
                               exterior_adjacent_to: orig_rim_joist.exterior_adjacent_to,
                               interior_adjacent_to: orig_rim_joist.interior_adjacent_to,
                               area: orig_rim_joist.area,
                               azimuth: orig_rim_joist.azimuth,
                               solar_absorptance: orig_rim_joist.solar_absorptance,
                               emittance: orig_rim_joist.emittance,
                               insulation_id: orig_rim_joist.insulation_id,
                               insulation_assembly_r_value: orig_rim_joist.insulation_assembly_r_value)
    end
  end

  def self.set_enclosure_rim_joists_iad(orig_hpxml, new_hpxml)
    # nop; included in above-grade walls
  end

  def self.set_enclosure_walls_reference(orig_hpxml, new_hpxml)
    # Table 4.2.2(1) - Above-grade walls
    ufactor = Constructions.get_default_frame_wall_ufactor(@iecc_zone_2006)

    ext_thermal_bndry_walls = orig_hpxml.walls.select { |wall| wall.is_exterior_thermal_boundary }
    sum_gross_area = ext_thermal_bndry_walls.map { |wall| wall.area }.inject(0, :+)
    solar_abs = 0.75
    emittance = 0.90

    # Create insulated walls for exterior thermal boundary surface.
    # Area is equally distributed to each direction to be able to accommodate windows,
    # which are also equally distributed.
    if sum_gross_area > 0
      new_hpxml.walls.add(id: 'WallArea',
                          exterior_adjacent_to: HPXML::LocationOutside,
                          interior_adjacent_to: HPXML::LocationLivingSpace,
                          wall_type: HPXML::WallTypeWoodStud,
                          area: sum_gross_area,
                          azimuth: nil,
                          solar_absorptance: solar_abs,
                          emittance: emittance,
                          insulation_assembly_r_value: 1.0 / ufactor)
    end

    # Preserve other walls:
    # 1. Interior thermal boundary surfaces (e.g., between living space and garage)
    # 2. Exterior non-thermal boundary surfaces (e.g., between garage and outside)
    orig_hpxml.walls.each do |orig_wall|
      next if orig_wall.is_exterior_thermal_boundary

      if orig_wall.is_thermal_boundary
        insulation_assembly_r_value = 1.0 / ufactor
      else
        insulation_assembly_r_value = [orig_wall.insulation_assembly_r_value, 4.0].min # uninsulated
      end
      new_hpxml.walls.add(id: orig_wall.id,
                          exterior_adjacent_to: orig_wall.exterior_adjacent_to.gsub('unvented', 'vented'),
                          interior_adjacent_to: orig_wall.interior_adjacent_to.gsub('unvented', 'vented'),
                          wall_type: orig_wall.wall_type,
                          area: orig_wall.area,
                          azimuth: orig_wall.azimuth,
                          solar_absorptance: solar_abs,
                          emittance: emittance,
                          insulation_id: orig_wall.insulation_id,
                          insulation_assembly_r_value: insulation_assembly_r_value)
    end
  end

  def self.set_enclosure_walls_rated(orig_hpxml, new_hpxml)
    # Preserve all walls
    orig_hpxml.walls.each do |orig_wall|
      new_hpxml.walls.add(id: orig_wall.id,
                          exterior_adjacent_to: orig_wall.exterior_adjacent_to,
                          interior_adjacent_to: orig_wall.interior_adjacent_to,
                          wall_type: orig_wall.wall_type,
                          area: orig_wall.area,
                          azimuth: orig_wall.azimuth,
                          solar_absorptance: orig_wall.solar_absorptance,
                          emittance: orig_wall.emittance,
                          insulation_id: orig_wall.insulation_id,
                          insulation_assembly_r_value: orig_wall.insulation_assembly_r_value)
    end
  end

  def self.set_enclosure_walls_iad(orig_hpxml, new_hpxml)
    # Table 4.3.1(1) Configuration of Index Adjustment Design - Above-grade walls
    ext_thermal_bndry_walls = orig_hpxml.walls.select { |wall| wall.is_exterior_thermal_boundary }
    avg_solar_abs = calc_area_weighted_sum(ext_thermal_bndry_walls, :solar_absorptance)
    avg_emittance = calc_area_weighted_sum(ext_thermal_bndry_walls, :emittance)
    avg_r_value = calc_area_weighted_sum(ext_thermal_bndry_walls, :insulation_assembly_r_value, true)

    # Add 2355.52 sqft of exterior thermal boundary wall area
    new_hpxml.walls.add(id: 'WallArea',
                        exterior_adjacent_to: HPXML::LocationOutside,
                        interior_adjacent_to: HPXML::LocationLivingSpace,
                        wall_type: HPXML::WallTypeWoodStud,
                        area: 2355.52,
                        azimuth: nil,
                        solar_absorptance: avg_solar_abs,
                        emittance: avg_emittance,
                        insulation_assembly_r_value: avg_r_value)

    # Preserve non-thermal boundary walls adjacent to attic
    orig_hpxml.walls.each do |orig_wall|
      next if orig_wall.is_thermal_boundary
      next unless [HPXML::LocationAtticVented, HPXML::LocationAtticUnvented].include? orig_wall.interior_adjacent_to

      new_hpxml.walls.add(id: orig_wall.id,
                          exterior_adjacent_to: orig_wall.exterior_adjacent_to,
                          interior_adjacent_to: orig_wall.interior_adjacent_to,
                          wall_type: orig_wall.wall_type,
                          area: orig_wall.area,
                          azimuth: orig_wall.azimuth,
                          solar_absorptance: orig_wall.solar_absorptance,
                          emittance: orig_wall.emittance,
                          insulation_id: orig_wall.insulation_id,
                          insulation_assembly_r_value: orig_wall.insulation_assembly_r_value)
    end
  end

  def self.set_enclosure_foundation_walls_reference(orig_hpxml, new_hpxml)
    wall_ufactor = Constructions.get_default_basement_wall_ufactor(@iecc_zone_2006)

    orig_hpxml.foundation_walls.each do |orig_foundation_wall|
      # Insulated for, e.g., conditioned basement walls adjacent to ground or
      # walls of unconditioned basements whose thermal boundary location is the wall.
      # Uninsulated for, e.g., crawlspace walls adjacent to ground.
      is_insulated = false
      if orig_foundation_wall.is_thermal_boundary
        is_insulated = true
      elsif [orig_foundation_wall.interior_adjacent_to, orig_foundation_wall.exterior_adjacent_to].include? HPXML::LocationBasementUnconditioned
        if @uncond_bsmnt_thermal_bndry == HPXML::FoundationThermalBoundaryWall
          is_insulated = true
        end
      end

      if is_insulated
        insulation_assembly_r_value = 1.0 / wall_ufactor
        insulation_interior_r_value = nil
        insulation_interior_distance_to_top = nil
        insulation_interior_distance_to_bottom = nil
        insulation_exterior_r_value = nil
        insulation_exterior_distance_to_top = nil
        insulation_exterior_distance_to_bottom = nil
      else
        insulation_interior_r_value = 0
        insulation_interior_distance_to_top = 0
        insulation_interior_distance_to_bottom = 0
        insulation_exterior_r_value = 0
        insulation_exterior_distance_to_top = 0
        insulation_exterior_distance_to_bottom = 0
        insulation_assembly_r_value = nil
      end
      new_hpxml.foundation_walls.add(id: orig_foundation_wall.id,
                                     exterior_adjacent_to: orig_foundation_wall.exterior_adjacent_to.gsub('unvented', 'vented'),
                                     interior_adjacent_to: orig_foundation_wall.interior_adjacent_to.gsub('unvented', 'vented'),
                                     height: orig_foundation_wall.height,
                                     area: orig_foundation_wall.area,
                                     azimuth: orig_foundation_wall.azimuth,
                                     thickness: orig_foundation_wall.thickness,
                                     depth_below_grade: orig_foundation_wall.depth_below_grade,
                                     insulation_id: orig_foundation_wall.insulation_id,
                                     insulation_interior_r_value: insulation_interior_r_value,
                                     insulation_interior_distance_to_top: insulation_interior_distance_to_top,
                                     insulation_interior_distance_to_bottom: insulation_interior_distance_to_bottom,
                                     insulation_exterior_r_value: insulation_exterior_r_value,
                                     insulation_exterior_distance_to_top: insulation_exterior_distance_to_top,
                                     insulation_exterior_distance_to_bottom: insulation_exterior_distance_to_bottom,
                                     insulation_assembly_r_value: insulation_assembly_r_value)
    end
  end

  def self.set_enclosure_foundation_walls_rated(orig_hpxml, new_hpxml)
    # Preserve all foundation walls
    orig_hpxml.foundation_walls.each do |orig_foundation_wall|
      new_hpxml.foundation_walls.add(id: orig_foundation_wall.id,
                                     exterior_adjacent_to: orig_foundation_wall.exterior_adjacent_to,
                                     interior_adjacent_to: orig_foundation_wall.interior_adjacent_to,
                                     height: orig_foundation_wall.height,
                                     area: orig_foundation_wall.area,
                                     azimuth: orig_foundation_wall.azimuth,
                                     thickness: orig_foundation_wall.thickness,
                                     depth_below_grade: orig_foundation_wall.depth_below_grade,
                                     insulation_id: orig_foundation_wall.insulation_id,
                                     insulation_interior_r_value: orig_foundation_wall.insulation_interior_r_value,
                                     insulation_interior_distance_to_top: orig_foundation_wall.insulation_interior_distance_to_top,
                                     insulation_interior_distance_to_bottom: orig_foundation_wall.insulation_interior_distance_to_bottom,
                                     insulation_exterior_r_value: orig_foundation_wall.insulation_exterior_r_value,
                                     insulation_exterior_distance_to_top: orig_foundation_wall.insulation_exterior_distance_to_top,
                                     insulation_exterior_distance_to_bottom: orig_foundation_wall.insulation_exterior_distance_to_bottom,
                                     insulation_assembly_r_value: orig_foundation_wall.insulation_assembly_r_value)
    end
  end

  def self.set_enclosure_foundation_walls_iad(orig_hpxml, new_hpxml)
    # Add vented crawlspace foundation wall
    new_hpxml.foundation_walls.add(id: 'FoundationWall',
                                   interior_adjacent_to: HPXML::LocationCrawlspaceVented,
                                   exterior_adjacent_to: HPXML::LocationGround,
                                   height: 2,
                                   area: 2 * 34.64 * 4,
                                   thickness: 8,
                                   depth_below_grade: 0,
                                   insulation_interior_r_value: 0,
                                   insulation_interior_distance_to_top: 0,
                                   insulation_interior_distance_to_bottom: 0,
                                   insulation_exterior_r_value: 0,
                                   insulation_exterior_distance_to_top: 0,
                                   insulation_exterior_distance_to_bottom: 0)
  end

  def self.set_enclosure_ceilings_reference(orig_hpxml, new_hpxml)
    ceiling_ufactor = Constructions.get_default_ceiling_ufactor(@iecc_zone_2006)

    # Table 4.2.2(1) - Ceilings
    orig_hpxml.frame_floors.each do |orig_frame_floor|
      next unless orig_frame_floor.is_ceiling

      if orig_frame_floor.is_thermal_boundary
        # Insulated for, e.g., ceilings between vented attic and living space.
        insulation_assembly_r_value = 1.0 / ceiling_ufactor
      else
        # Uninsulated for, e.g., ceilings between vented attic and garage.
        insulation_assembly_r_value = [orig_frame_floor.insulation_assembly_r_value, 2.1].min # uninsulated
      end
      new_hpxml.frame_floors.add(id: orig_frame_floor.id,
                                 exterior_adjacent_to: orig_frame_floor.exterior_adjacent_to.gsub('unvented', 'vented'),
                                 interior_adjacent_to: orig_frame_floor.interior_adjacent_to.gsub('unvented', 'vented'),
                                 area: orig_frame_floor.area,
                                 insulation_id: orig_frame_floor.insulation_id,
                                 insulation_assembly_r_value: insulation_assembly_r_value)
    end
  end

  def self.set_enclosure_ceilings_rated(orig_hpxml, new_hpxml)
    # Preserve all ceilings
    orig_hpxml.frame_floors.each do |orig_frame_floor|
      next unless orig_frame_floor.is_ceiling

      new_hpxml.frame_floors.add(id: orig_frame_floor.id,
                                 exterior_adjacent_to: orig_frame_floor.exterior_adjacent_to,
                                 interior_adjacent_to: orig_frame_floor.interior_adjacent_to,
                                 area: orig_frame_floor.area,
                                 insulation_id: orig_frame_floor.insulation_id,
                                 insulation_assembly_r_value: orig_frame_floor.insulation_assembly_r_value)
    end
  end

  def self.set_enclosure_ceilings_iad(orig_hpxml, new_hpxml)
    set_enclosure_ceilings_rated(orig_hpxml, new_hpxml)

    # Scale down ceiling area to 1200 sqft while maintaining ratio of attic types.
    sum_ceiling_area = 0.0
    new_hpxml.frame_floors.each do |new_frame_floor|
      next unless new_frame_floor.is_ceiling

      sum_ceiling_area += new_frame_floor.area
    end
    new_hpxml.frame_floors.each do |new_frame_floor|
      next unless new_frame_floor.is_ceiling

      new_frame_floor.area = 1200.0 * new_frame_floor.area / sum_ceiling_area
    end
  end

  def self.set_enclosure_floors_reference(orig_hpxml, new_hpxml)
    floor_ufactor = Constructions.get_default_floor_ufactor(@iecc_zone_2006)

    orig_hpxml.frame_floors.each do |orig_frame_floor|
      next unless orig_frame_floor.is_floor

      # Insulated for, e.g., floors between living space and crawlspace or
      # floors of unconditioned basements whose thermal boundary location is the floor.
      # Uninsulated for, e.g., floors between living space and conditioned basement.
      is_insulated = false
      if orig_frame_floor.is_thermal_boundary
        if [orig_frame_floor.interior_adjacent_to, orig_frame_floor.exterior_adjacent_to].include? HPXML::LocationBasementUnconditioned
          if @uncond_bsmnt_thermal_bndry == HPXML::FoundationThermalBoundaryFloor
            is_insulated = true
          end
        else
          is_insulated = true
        end
      end

      if is_insulated
        insulation_assembly_r_value = 1.0 / floor_ufactor
      else
        insulation_assembly_r_value = [orig_frame_floor.insulation_assembly_r_value, 3.1].min # uninsulated
      end

      new_hpxml.frame_floors.add(id: orig_frame_floor.id,
                                 exterior_adjacent_to: orig_frame_floor.exterior_adjacent_to.gsub('unvented', 'vented'),
                                 interior_adjacent_to: orig_frame_floor.interior_adjacent_to.gsub('unvented', 'vented'),
                                 area: orig_frame_floor.area,
                                 insulation_id: orig_frame_floor.insulation_id,
                                 insulation_assembly_r_value: insulation_assembly_r_value)
    end
  end

  def self.set_enclosure_floors_rated(orig_hpxml, new_hpxml)
    # Preserve all floors
    orig_hpxml.frame_floors.each do |orig_frame_floor|
      next unless orig_frame_floor.is_floor

      new_hpxml.frame_floors.add(id: orig_frame_floor.id,
                                 exterior_adjacent_to: orig_frame_floor.exterior_adjacent_to,
                                 interior_adjacent_to: orig_frame_floor.interior_adjacent_to,
                                 area: orig_frame_floor.area,
                                 insulation_id: orig_frame_floor.insulation_id,
                                 insulation_assembly_r_value: orig_frame_floor.insulation_assembly_r_value)
    end
  end

  def self.set_enclosure_floors_iad(orig_hpxml, new_hpxml)
    floor_ufactor = Constructions.get_default_floor_ufactor(@iecc_zone_2006)

    # Add crawlspace floor
    new_hpxml.frame_floors.add(id: 'FloorAboveCrawlspace',
                               interior_adjacent_to: HPXML::LocationLivingSpace,
                               exterior_adjacent_to: HPXML::LocationCrawlspaceVented,
                               area: 1200,
                               insulation_assembly_r_value: 1.0 / floor_ufactor)
  end

  def self.set_enclosure_slabs_reference(orig_hpxml, new_hpxml)
    slab_perim_rvalue, slab_perim_depth = Constructions.get_default_slab_perimeter_rvalue_depth(@iecc_zone_2006)
    slab_under_rvalue, slab_under_width = Constructions.get_default_slab_under_rvalue_width()

    orig_hpxml.slabs.each do |orig_slab|
      if orig_slab.interior_adjacent_to == HPXML::LocationLivingSpace
        # Insulated for slabs below living space.
        perimeter_insulation_depth = slab_perim_depth
        under_slab_insulation_width = slab_under_width
        perimeter_insulation_r_value = slab_perim_rvalue
        under_slab_insulation_r_value = slab_under_rvalue
      else
        # Uninsulated for all other cases.
        perimeter_insulation_depth = 0
        under_slab_insulation_width = 0
        perimeter_insulation_r_value = 0
        under_slab_insulation_r_value = 0
      end
      if [HPXML::LocationLivingSpace, HPXML::LocationBasementConditioned].include? orig_slab.interior_adjacent_to
        carpet_fraction = 0.8
        carpet_r_value = 2.0
      else
        carpet_fraction = 0.0
        carpet_r_value = 0.0
      end
      new_hpxml.slabs.add(id: orig_slab.id,
                          interior_adjacent_to: orig_slab.interior_adjacent_to.gsub('unvented', 'vented'),
                          area: orig_slab.area,
                          thickness: orig_slab.thickness,
                          exposed_perimeter: orig_slab.exposed_perimeter,
                          perimeter_insulation_depth: perimeter_insulation_depth,
                          under_slab_insulation_width: under_slab_insulation_width,
                          under_slab_insulation_spans_entire_slab: nil,
                          depth_below_grade: orig_slab.depth_below_grade,
                          carpet_fraction: carpet_fraction,
                          carpet_r_value: carpet_r_value,
                          perimeter_insulation_id: orig_slab.perimeter_insulation_id,
                          perimeter_insulation_r_value: perimeter_insulation_r_value,
                          under_slab_insulation_id: orig_slab.under_slab_insulation_id,
                          under_slab_insulation_r_value: under_slab_insulation_r_value)
    end
  end

  def self.set_enclosure_slabs_rated(orig_hpxml, new_hpxml)
    # Preserve all slabs.
    orig_hpxml.slabs.each do |orig_slab|
      new_hpxml.slabs.add(id: orig_slab.id,
                          interior_adjacent_to: orig_slab.interior_adjacent_to,
                          area: orig_slab.area,
                          thickness: orig_slab.thickness,
                          exposed_perimeter: orig_slab.exposed_perimeter,
                          perimeter_insulation_depth: orig_slab.perimeter_insulation_depth,
                          under_slab_insulation_width: orig_slab.under_slab_insulation_width,
                          under_slab_insulation_spans_entire_slab: orig_slab.under_slab_insulation_spans_entire_slab,
                          depth_below_grade: orig_slab.depth_below_grade,
                          carpet_fraction: orig_slab.carpet_fraction,
                          carpet_r_value: orig_slab.carpet_r_value,
                          perimeter_insulation_id: orig_slab.perimeter_insulation_id,
                          perimeter_insulation_r_value: orig_slab.perimeter_insulation_r_value,
                          under_slab_insulation_id: orig_slab.under_slab_insulation_id,
                          under_slab_insulation_r_value: orig_slab.under_slab_insulation_r_value)
    end
  end

  def self.set_enclosure_slabs_iad(orig_hpxml, new_hpxml)
    # Add crawlspace slab
    new_hpxml.slabs.add(id: 'Slab',
                        interior_adjacent_to: HPXML::LocationCrawlspaceVented,
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

  def self.set_enclosure_windows_reference(orig_hpxml, new_hpxml)
    # Table 4.2.2(1) - Glazing
    ufactor, shgc = Constructions.get_default_ufactor_shgc(@iecc_zone_2006)

    ag_bndry_wall_area, bg_bndry_wall_area, common_wall_area = calc_wall_areas_for_windows(orig_hpxml)

    fa = ag_bndry_wall_area / (ag_bndry_wall_area + 0.5 * bg_bndry_wall_area)
    f = 1.0 - 0.44 * common_wall_area / (ag_bndry_wall_area + common_wall_area)

    shade_summer, shade_winter = Constructions.get_default_interior_shading_factors()

    if @is_attached_unit && (orig_hpxml.fraction_of_window_area_operable() <= 0) && (Constants.ERIVersions.index(@eri_version) >= Constants.ERIVersions.index('2019')) # 2019 or newer
      # Disable natural ventilation
      fraction_operable = 0.0
    else
      # Default natural ventilation
      fraction_operable = Airflow.get_default_fraction_of_operable_window_area()
    end

    # Create equally distributed windows
    for orientation, azimuth in { 'North' => 0, 'South' => 180, 'East' => 90, 'West' => 270 }
      new_hpxml.windows.add(id: "WindowArea#{orientation}",
                            area: 0.18 * @cfa * fa * f * 0.25,
                            azimuth: azimuth,
                            ufactor: ufactor,
                            shgc: shgc,
                            interior_shading_factor_summer: shade_summer,
                            interior_shading_factor_winter: shade_winter,
                            fraction_operable: fraction_operable,
                            wall_idref: 'WallArea')
    end
  end

  def self.set_enclosure_windows_rated(orig_hpxml, new_hpxml)
    shade_summer, shade_winter = Constructions.get_default_interior_shading_factors()

    # Preserve all windows
    orig_hpxml.windows.each do |orig_window|
      new_hpxml.windows.add(id: orig_window.id,
                            area: orig_window.area,
                            azimuth: orig_window.azimuth,
                            ufactor: orig_window.ufactor,
                            shgc: orig_window.shgc,
                            overhangs_depth: orig_window.overhangs_depth,
                            overhangs_distance_to_top_of_window: orig_window.overhangs_distance_to_top_of_window,
                            overhangs_distance_to_bottom_of_window: orig_window.overhangs_distance_to_bottom_of_window,
                            interior_shading_factor_summer: shade_summer,
                            interior_shading_factor_winter: shade_winter,
                            fraction_operable: orig_window.fraction_operable,
                            wall_idref: orig_window.wall_idref)
    end
  end

  def self.set_enclosure_windows_iad(orig_hpxml, new_hpxml)
    shade_summer, shade_winter = Constructions.get_default_interior_shading_factors()
    ext_thermal_bndry_windows = orig_hpxml.windows.select { |window| window.is_exterior_thermal_boundary }
    avg_ufactor = calc_area_weighted_sum(ext_thermal_bndry_windows, :ufactor)
    avg_shgc = calc_area_weighted_sum(ext_thermal_bndry_windows, :shgc)

    # Default natural ventilation
    fraction_operable = Airflow.get_default_fraction_of_operable_window_area()

    # Create equally distributed windows
    for orientation, azimuth in { 'North' => 0, 'South' => 180, 'East' => 90, 'West' => 270 }
      new_hpxml.windows.add(id: "WindowArea#{orientation}",
                            area: 0.18 * @cfa * 0.25,
                            azimuth: azimuth,
                            ufactor: avg_ufactor,
                            shgc: avg_shgc,
                            interior_shading_factor_summer: shade_summer,
                            interior_shading_factor_winter: shade_winter,
                            fraction_operable: fraction_operable,
                            wall_idref: 'WallArea')
    end
  end

  def self.set_enclosure_skylights_reference(orig_hpxml, new_hpxml)
    # nop; No skylights
  end

  def self.set_enclosure_skylights_rated(orig_hpxml, new_hpxml)
    # Preserve all skylights
    orig_hpxml.skylights.each do |orig_skylight|
      new_hpxml.skylights.add(id: orig_skylight.id,
                              area: orig_skylight.area,
                              azimuth: orig_skylight.azimuth,
                              ufactor: orig_skylight.ufactor,
                              shgc: orig_skylight.shgc,
                              roof_idref: orig_skylight.roof_idref)
    end
  end

  def self.set_enclosure_skylights_iad(orig_hpxml, new_hpxml)
    set_enclosure_skylights_rated(orig_hpxml, new_hpxml)

    # Since the IAD roof area is scaled down but skylight area is maintained,
    # it's possible that skylights no longer fit on the roof. To resolve this,
    # scale down skylight area to fit as needed.
    new_hpxml.roofs.each do |new_roof|
      new_skylight_area = new_roof.skylights.map { |skylight| skylight.area }.inject(0, :+)
      next unless new_skylight_area > new_roof.area

      new_roof.skylights.each do |new_skylight|
        new_skylight.area = new_skylight.area * new_roof.area / new_skylight_area * 0.99
      end
    end
  end

  def self.set_enclosure_doors_reference(orig_hpxml, new_hpxml)
    # Table 4.2.2(1) - Doors
    ufactor, shgc = Constructions.get_default_ufactor_shgc(@iecc_zone_2006)

    # Create new door
    new_hpxml.doors.add(id: 'DoorAreaNorth',
                        wall_idref: 'WallArea',
                        area: Constructions.get_default_door_area(),
                        azimuth: 0,
                        r_value: 1.0 / ufactor)
  end

  def self.set_enclosure_doors_rated(orig_hpxml, new_hpxml)
    # Table 4.2.2(1) - Doors
    orig_hpxml.doors.each do |orig_door|
      new_hpxml.doors.add(id: orig_door.id,
                          wall_idref: orig_door.wall_idref,
                          area: orig_door.area,
                          azimuth: orig_door.azimuth,
                          r_value: orig_door.r_value)
    end
  end

  def self.set_enclosure_doors_iad(orig_hpxml, new_hpxml)
    # Table 4.3.1(1) Configuration of Index Adjustment Design - Doors
    ext_thermal_bndry_doors = orig_hpxml.doors.select { |door| door.is_exterior_thermal_boundary }
    avg_r_value = calc_area_weighted_sum(ext_thermal_bndry_doors, :r_value, true)

    # Create new door (since it's impossible to preserve the Rated Home's door orientation)
    # Note: Area is incorrect in table, should be “Area: Same as Energy Rating Reference Home”
    new_hpxml.doors.add(id: 'DoorAreaNorth',
                        wall_idref: 'WallArea',
                        area: Constructions.get_default_door_area(),
                        azimuth: 0,
                        r_value: avg_r_value)
  end

  def self.set_systems_hvac_reference(orig_hpxml, new_hpxml)
    # Table 4.2.2(1) - Heating systems
    # Table 4.2.2(1) - Cooling systems

    ref_hvacdist_ids = []

    has_fuel = orig_hpxml.has_fuel_access()
    sum_frac_cool_load = (orig_hpxml.cooling_systems + orig_hpxml.heat_pumps).map { |hvac| hvac.fraction_cool_load_served }.inject(0, :+)
    sum_frac_heat_load = (orig_hpxml.heating_systems + orig_hpxml.heat_pumps).map { |hvac| hvac.fraction_heat_load_served }.inject(0, :+)

    # Heating
    orig_hpxml.heating_systems.each do |orig_heating_system|
      next unless orig_heating_system.fraction_heat_load_served > 0
      next unless orig_heating_system.heating_system_fuel != HPXML::FuelTypeElectricity

      if orig_heating_system.heating_system_type == HPXML::HVACTypeBoiler
        add_reference_heating_gas_boiler(new_hpxml, ref_hvacdist_ids, orig_heating_system.fraction_heat_load_served, orig_heating_system)
      else
        add_reference_heating_gas_furnace(new_hpxml, ref_hvacdist_ids, orig_heating_system.fraction_heat_load_served, orig_heating_system)
      end
    end
    if has_fuel && (sum_frac_heat_load < 0.99) # Accommodate systems that don't quite sum to 1 due to rounding
      add_reference_heating_gas_furnace(new_hpxml, ref_hvacdist_ids, (1.0 - sum_frac_heat_load).round(3))
    end

    # Cooling
    orig_hpxml.cooling_systems.each do |orig_cooling_system|
      next unless orig_cooling_system.fraction_cool_load_served > 0

      add_reference_cooling_air_conditioner(new_hpxml, ref_hvacdist_ids, orig_cooling_system.fraction_cool_load_served, orig_cooling_system)
    end
    orig_hpxml.heat_pumps.each do |orig_heat_pump|
      next unless orig_heat_pump.fraction_cool_load_served > 0

      add_reference_cooling_air_conditioner(new_hpxml, ref_hvacdist_ids, orig_heat_pump.fraction_cool_load_served, orig_heat_pump)
    end
    if (sum_frac_cool_load < 0.99) # Accommodate systems that don't quite sum to 1 due to rounding
      add_reference_cooling_air_conditioner(new_hpxml, ref_hvacdist_ids, (1.0 - sum_frac_cool_load).round(3))
    end

    # HeatPump
    orig_hpxml.heating_systems.each do |orig_heating_system|
      next unless orig_heating_system.fraction_heat_load_served > 0
      next unless orig_heating_system.heating_system_fuel == HPXML::FuelTypeElectricity

      add_reference_heating_heat_pump(new_hpxml, ref_hvacdist_ids, orig_heating_system.fraction_heat_load_served, orig_heating_system)
    end
    orig_hpxml.heat_pumps.each do |orig_heat_pump|
      next unless orig_heat_pump.fraction_heat_load_served > 0

      add_reference_heating_heat_pump(new_hpxml, ref_hvacdist_ids, orig_heat_pump.fraction_heat_load_served, orig_heat_pump)
    end
    if (not has_fuel) && (sum_frac_heat_load < 0.99) # Accommodate systems that don't quite sum to 1 due to rounding
      add_reference_heating_heat_pump(new_hpxml, ref_hvacdist_ids, (1.0 - sum_frac_heat_load).round(3))
    end

    # Table 303.4.1(1) - Thermostat
    control_type = HPXML::HVACControlTypeManual
    if orig_hpxml.ceiling_fans.size > 0
      clg_ceiling_fan_offset = 0.5 # deg-F
    else
      clg_ceiling_fan_offset = nil
    end
    new_hpxml.hvac_controls.add(id: 'HVACControl',
                                control_type: control_type,
                                heating_setpoint_temp: HVAC.get_default_heating_setpoint(control_type)[0],
                                cooling_setpoint_temp: HVAC.get_default_cooling_setpoint(control_type)[0],
                                ceiling_fan_cooling_setpoint_temp_offset: clg_ceiling_fan_offset)

    # Distribution system
    add_reference_distribution_system(new_hpxml, ref_hvacdist_ids)
  end

  def self.set_systems_hvac_rated(orig_hpxml, new_hpxml)
    # Table 4.2.2(1) - Heating systems
    # Table 4.2.2(1) - Cooling systems

    ref_hvacdist_ids = []

    has_fuel = orig_hpxml.has_fuel_access()
    sum_frac_cool_load = (orig_hpxml.cooling_systems + orig_hpxml.heat_pumps).map { |hvac| hvac.fraction_cool_load_served }.inject(0, :+)
    sum_frac_heat_load = (orig_hpxml.heating_systems + orig_hpxml.heat_pumps).map { |hvac| hvac.fraction_heat_load_served }.inject(0, :+)

    # Retain heating system(s)
    orig_hpxml.heating_systems.each do |orig_heating_system|
      new_hpxml.heating_systems.add(id: orig_heating_system.id,
                                    distribution_system_idref: orig_heating_system.distribution_system_idref,
                                    heating_system_type: orig_heating_system.heating_system_type,
                                    heating_system_fuel: orig_heating_system.heating_system_fuel,
                                    heating_capacity: orig_heating_system.heating_capacity,
                                    heating_efficiency_afue: orig_heating_system.heating_efficiency_afue,
                                    heating_efficiency_percent: orig_heating_system.heating_efficiency_percent,
                                    fraction_heat_load_served: orig_heating_system.fraction_heat_load_served,
                                    electric_auxiliary_energy: orig_heating_system.electric_auxiliary_energy)
    end
    # Add reference heating system for residual load
    if has_fuel && (sum_frac_heat_load < 0.99) # Accommodate systems that don't quite sum to 1 due to rounding
      add_reference_heating_gas_furnace(new_hpxml, ref_hvacdist_ids, (1.0 - sum_frac_heat_load).round(3))
    end

    # Retain cooling system(s)
    orig_hpxml.cooling_systems.each do |orig_cooling_system|
      new_hpxml.cooling_systems.add(id: orig_cooling_system.id,
                                    distribution_system_idref: orig_cooling_system.distribution_system_idref,
                                    cooling_system_type: orig_cooling_system.cooling_system_type,
                                    cooling_system_fuel: orig_cooling_system.cooling_system_fuel,
                                    compressor_type: orig_cooling_system.compressor_type,
                                    cooling_capacity: orig_cooling_system.cooling_capacity,
                                    fraction_cool_load_served: orig_cooling_system.fraction_cool_load_served,
                                    cooling_efficiency_seer: orig_cooling_system.cooling_efficiency_seer,
                                    cooling_efficiency_eer: orig_cooling_system.cooling_efficiency_eer,
                                    cooling_shr: orig_cooling_system.cooling_shr)
    end
    # Add reference cooling system for residual load
    if (sum_frac_cool_load < 0.99) # Accommodate systems that don't quite sum to 1 due to rounding
      add_reference_cooling_air_conditioner(new_hpxml, ref_hvacdist_ids, (1.0 - sum_frac_cool_load).round(3))
    end

    # Retain heat pump(s)
    orig_hpxml.heat_pumps.each do |orig_heat_pump|
      new_hpxml.heat_pumps.add(id: orig_heat_pump.id,
                               distribution_system_idref: orig_heat_pump.distribution_system_idref,
                               heat_pump_type: orig_heat_pump.heat_pump_type,
                               heat_pump_fuel: orig_heat_pump.heat_pump_fuel,
                               compressor_type: orig_heat_pump.compressor_type,
                               heating_capacity: orig_heat_pump.heating_capacity,
                               heating_capacity_17F: orig_heat_pump.heating_capacity_17F,
                               cooling_capacity: orig_heat_pump.cooling_capacity,
                               cooling_shr: orig_heat_pump.cooling_shr,
                               backup_heating_fuel: orig_heat_pump.backup_heating_fuel,
                               backup_heating_capacity: orig_heat_pump.backup_heating_capacity,
                               backup_heating_efficiency_percent: orig_heat_pump.backup_heating_efficiency_percent,
                               backup_heating_efficiency_afue: orig_heat_pump.backup_heating_efficiency_afue,
                               backup_heating_switchover_temp: orig_heat_pump.backup_heating_switchover_temp,
                               fraction_heat_load_served: orig_heat_pump.fraction_heat_load_served,
                               fraction_cool_load_served: orig_heat_pump.fraction_cool_load_served,
                               cooling_efficiency_seer: orig_heat_pump.cooling_efficiency_seer,
                               cooling_efficiency_eer: orig_heat_pump.cooling_efficiency_eer,
                               heating_efficiency_hspf: orig_heat_pump.heating_efficiency_hspf,
                               heating_efficiency_cop: orig_heat_pump.heating_efficiency_cop)
    end
    # Add reference heat pump for residual load
    if (not has_fuel) && (sum_frac_heat_load < 0.99) # Accommodate systems that don't quite sum to 1 due to rounding
      add_reference_heating_heat_pump(new_hpxml, ref_hvacdist_ids, (1.0 - sum_frac_heat_load).round(3))
    end

    # Table 303.4.1(1) - Thermostat
    if orig_hpxml.ceiling_fans.size > 0
      clg_ceiling_fan_offset = 0.5 # deg-F
    else
      clg_ceiling_fan_offset = nil
    end
    if orig_hpxml.hvac_controls.size > 0
      hvac_control = orig_hpxml.hvac_controls[0]
      control_type = hvac_control.control_type
      htg_sp, htg_setback_sp, htg_setback_hrs_per_week, htg_setback_start_hr = HVAC.get_default_heating_setpoint(control_type)
      clg_sp, clg_setup_sp, clg_setup_hrs_per_week, clg_setup_start_hr = HVAC.get_default_cooling_setpoint(control_type)
      new_hpxml.hvac_controls.add(id: hvac_control.id,
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
      control_type = HPXML::HVACControlTypeManual
      new_hpxml.hvac_controls.add(id: 'HVACControl',
                                  control_type: control_type,
                                  heating_setpoint_temp: HVAC.get_default_heating_setpoint(control_type)[0],
                                  cooling_setpoint_temp: HVAC.get_default_cooling_setpoint(control_type)[0],
                                  ceiling_fan_cooling_setpoint_temp_offset: clg_ceiling_fan_offset)
    end

    # Table 4.2.2(1) - Thermal distribution systems
    orig_hpxml.hvac_distributions.each do |orig_hvac_distribution|
      # Leakage exemption?
      zero_leakage = false
      if orig_hvac_distribution.duct_leakage_testing_exemption
        if Constants.ERIVersions.index(@eri_version) < Constants.ERIVersions.index('2014AD')
          fail "ERI Version #{@eri_version} does not support duct leakage testing exemption."
        elsif Constants.ERIVersions.index(@eri_version) < Constants.ERIVersions.index('2014ADEGL')
          # Addendum D: Zero duct leakage to outside
          zero_leakage = true
        else
          # Addendum L: DSE = 0.88
          new_hpxml.hvac_distributions.add(id: orig_hvac_distribution.id,
                                           distribution_system_type: HPXML::HVACDistributionTypeDSE,
                                           annual_heating_dse: 0.88,
                                           annual_cooling_dse: 0.88)
          next
        end
      end

      new_hpxml.hvac_distributions.add(id: orig_hvac_distribution.id,
                                       distribution_system_type: orig_hvac_distribution.distribution_system_type,
                                       annual_heating_dse: orig_hvac_distribution.annual_heating_dse,
                                       annual_cooling_dse: orig_hvac_distribution.annual_cooling_dse)
      next unless orig_hvac_distribution.distribution_system_type == HPXML::HVACDistributionTypeAir

      new_hvac_distribution = new_hpxml.hvac_distributions[-1]

      if zero_leakage
        # Zero leakage
        new_hvac_distribution.duct_leakage_measurements.add(duct_type: HPXML::DuctTypeSupply,
                                                            duct_leakage_units: HPXML::UnitsCFM25,
                                                            duct_leakage_value: 0.0,
                                                            duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside)
        new_hvac_distribution.duct_leakage_measurements.add(duct_type: HPXML::DuctTypeReturn,
                                                            duct_leakage_units: HPXML::UnitsCFM25,
                                                            duct_leakage_value: 0.0,
                                                            duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside)
      else
        orig_hvac_distribution.duct_leakage_measurements.each do |orig_leakage_measurement|
          if orig_leakage_measurement.duct_leakage_total_or_to_outside == HPXML::DuctLeakageTotal
            # Total duct leakage
            if Constants.ERIVersions.index(@eri_version) < Constants.ERIVersions.index('2014ADEGL')
              fail "ERI Version #{@eri_version} does not support total duct leakage testing."
            end

            if @bldg_type == HPXML::ResidentialTypeApartment
              # Apartment
              duct_surface_area_conditioned = 0.0
              duct_surface_area_total = 0.0
              orig_hvac_distribution.ducts.each do |orig_duct|
                if [HPXML::LocationLivingSpace, HPXML::LocationBasementConditioned].include? orig_duct.duct_location
                  duct_surface_area_conditioned += orig_duct.duct_surface_area
                end
                duct_surface_area_total += orig_duct.duct_surface_area
              end
              leakage_to_outside = orig_leakage_measurement.duct_leakage_value * (1.0 - duct_surface_area_conditioned / duct_surface_area_total)
              htg_cap, clg_cap = get_hvac_capacities_for_distribution_system(orig_hvac_distribution)
              leakage_air_handler = [0.025 * 400.0 * htg_cap / 12000.0, 0.025 * 400.0 * clg_cap / 12000.0].min
              leakage_to_outside += leakage_air_handler
              leakage_to_outside = [leakage_to_outside, orig_leakage_measurement.duct_leakage_value].min
            else # Dwellings/Townhouses
              leakage_to_outside = 0.5 * orig_leakage_measurement.duct_leakage_value
            end
            new_hvac_distribution.duct_leakage_measurements.add(duct_type: HPXML::DuctTypeSupply,
                                                                duct_leakage_units: orig_leakage_measurement.duct_leakage_units,
                                                                duct_leakage_value: 0.5 * leakage_to_outside,
                                                                duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside)
            new_hvac_distribution.duct_leakage_measurements.add(duct_type: HPXML::DuctTypeReturn,
                                                                duct_leakage_units: orig_leakage_measurement.duct_leakage_units,
                                                                duct_leakage_value: 0.5 * leakage_to_outside,
                                                                duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside)
            break
          else
            # Duct leakage to outside
            new_hvac_distribution.duct_leakage_measurements.add(duct_type: orig_leakage_measurement.duct_type,
                                                                duct_leakage_units: orig_leakage_measurement.duct_leakage_units,
                                                                duct_leakage_value: orig_leakage_measurement.duct_leakage_value,
                                                                duct_leakage_total_or_to_outside: orig_leakage_measurement.duct_leakage_total_or_to_outside)
          end
        end

        orig_hvac_distribution.ducts.each do |orig_duct|
          new_hvac_distribution.ducts.add(duct_type: orig_duct.duct_type,
                                          duct_insulation_r_value: orig_duct.duct_insulation_r_value,
                                          duct_location: orig_duct.duct_location,
                                          duct_surface_area: orig_duct.duct_surface_area)
        end
      end
    end

    # Add DSE distribution for these systems
    add_reference_distribution_system(new_hpxml, ref_hvacdist_ids)
  end

  def self.set_systems_hvac_iad(orig_hpxml, new_hpxml)
    # Table 4.3.1(1) Configuration of Index Adjustment Design - Heating systems
    # Table 4.3.1(1) Configuration of Index Adjustment Design - Cooling systems
    # Table 4.3.1(1) Configuration of Index Adjustment Design - Thermostat
    set_systems_hvac_reference(orig_hpxml, new_hpxml)

    # Table 4.3.1(1) Configuration of Index Adjustment Design - Thermal distribution systems
    # Change DSE to 1.0
    new_hpxml.hvac_distributions.each do |new_hvac_distribution|
      new_hvac_distribution.annual_heating_dse = 1.0
      new_hvac_distribution.annual_cooling_dse = 1.0
    end
  end

  def self.set_systems_mechanical_ventilation_reference(orig_hpxml, new_hpxml)
    # Table 4.2.2(1) - Whole-House Mechanical ventilation

    orig_mech_vent_fan = nil

    # Check for eRatio workaround first
    eratio_fan = orig_hpxml.doc.elements["/HPXML/Building/BuildingDetails/Systems/MechanicalVentilation/VentilationFans/VentilationFan[UsedForWholeBuildingVentilation='true']/extension/OverrideVentilationFan"]
    if not eratio_fan.nil?
      orig_mech_vent_fan = HPXML::VentilationFan.new(orig_hpxml, eratio_fan)
    else
      orig_hpxml.ventilation_fans.each do |orig_ventilation_fan|
        next unless orig_ventilation_fan.used_for_whole_building_ventilation

        orig_mech_vent_fan = orig_ventilation_fan
      end
    end

    fan_type = nil
    sys_id = 'MechanicalVentilation'
    if not orig_mech_vent_fan.nil?
      fan_type = orig_mech_vent_fan.fan_type
      sys_id = orig_mech_vent_fan.id
    end

    q_tot = calc_mech_vent_q_tot()

    # Calculate fan cfm for airflow rate using Reference Home infiltration
    # https://www.resnet.us/wp-content/uploads/No.-301-2014-01-Table-4.2.21-Reference-Home-Air-Exchange-Rate.pdf
    ref_sla = 0.00036
    q_fan_airflow = calc_mech_vent_q_fan(q_tot, ref_sla, fan_type, orig_hpxml)

    if fan_type.nil?
      fan_type = HPXML::MechVentTypeExhaust
      fan_power_w = 0.0
    else
      q_fan_power = calc_rated_home_qfan(orig_hpxml, fan_type, true) # Use Rated Home fan type

      # Treat CFIS like supply ventilation
      if fan_type == HPXML::MechVentTypeCFIS
        fan_type = HPXML::MechVentTypeSupply
      end

      fan_w_per_cfm = Airflow.get_default_mech_vent_fan_power(fan_type)
      fan_power_w = fan_w_per_cfm * q_fan_power

      if (fan_type == HPXML::MechVentTypeERV) || (fan_type == HPXML::MechVentTypeHRV)
        fan_type = HPXML::MechVentTypeBalanced
      end
    end

    new_hpxml.ventilation_fans.add(id: sys_id,
                                   fan_type: fan_type,
                                   tested_flow_rate: q_fan_airflow,
                                   hours_in_operation: 24,
                                   fan_power: fan_power_w,
                                   used_for_whole_building_ventilation: true)
  end

  def self.set_systems_mechanical_ventilation_rated(orig_hpxml, new_hpxml)
    # Table 4.2.2(1) - Whole-House Mechanical ventilation
    orig_hpxml.ventilation_fans.each do |orig_ventilation_fan|
      next unless orig_ventilation_fan.used_for_whole_building_ventilation

      tested_flow_rate = orig_ventilation_fan.tested_flow_rate
      fan_power = orig_ventilation_fan.fan_power
      hours_in_operation = orig_ventilation_fan.hours_in_operation

      # Calculate min airflow rate
      min_q_fan = calc_rated_home_qfan(orig_hpxml, orig_ventilation_fan.fan_type, false)
      if tested_flow_rate.nil?
        # Calculate airflow rate based on increased infiltration rate
        tested_flow_rate = min_q_fan
        if fan_power.nil?
          fan_w_per_cfm = Airflow.get_default_mech_vent_fan_power(orig_ventilation_fan.fan_type)
          if orig_ventilation_fan.fan_type == HPXML::MechVentTypeCFIS
            # For CFIS systems, the cfm used to determine fan watts shall be the larger of
            # 400 cfm per 12 kBtu/h cooling capacity or 240 cfm per 12 kBtu/h heating capacity
            htg_cap, clg_cap = get_hvac_capacities_for_distribution_system(orig_ventilation_fan.distribution_system)
            q_fan = [400.0 * clg_cap / 12000.0, 240.0 * htg_cap / 12000.0].max
            fan_power = fan_w_per_cfm * q_fan
          else
            fan_power = fan_w_per_cfm * tested_flow_rate
          end
        end
        hours_in_operation = 24
        if tested_flow_rate <= 0
          # Where a Rated Home has mechanical ventilation but the flowrate has not been measured ...
          # and where Qfan ≤ 0 (cfm) ... Rated Home fan energy shall be zero.
          # https://www.resnet.us/wp-content/uploads/IR-301-2019-001-FanEnergyUnmeasuredMechVentilation_final.pdf
          fan_power = 0
        end
      else
        if fan_power.nil?
          fan_w_per_cfm = Airflow.get_default_mech_vent_fan_power(orig_ventilation_fan.fan_type)
        else
          fan_w_per_cfm = fan_power / tested_flow_rate
        end
        q_fan = tested_flow_rate * hours_in_operation / 24.0
        if q_fan < min_q_fan
          # First try increasing operation to meet minimum
          hours_in_operation = [min_q_fan / q_fan * hours_in_operation, 24.0].min
          q_fan = tested_flow_rate * hours_in_operation / 24.0
        end
        if q_fan < min_q_fan
          # Finally resort to increasing airflow rate
          tested_flow_rate *= min_q_fan / q_fan
          q_fan = tested_flow_rate * hours_in_operation / 24.0
        end
        fan_power = fan_w_per_cfm * tested_flow_rate
      end

      new_hpxml.ventilation_fans.add(id: orig_ventilation_fan.id,
                                     fan_type: orig_ventilation_fan.fan_type,
                                     tested_flow_rate: tested_flow_rate,
                                     hours_in_operation: hours_in_operation,
                                     total_recovery_efficiency: orig_ventilation_fan.total_recovery_efficiency,
                                     total_recovery_efficiency_adjusted: orig_ventilation_fan.total_recovery_efficiency_adjusted,
                                     sensible_recovery_efficiency: orig_ventilation_fan.sensible_recovery_efficiency,
                                     sensible_recovery_efficiency_adjusted: orig_ventilation_fan.sensible_recovery_efficiency_adjusted,
                                     fan_power: fan_power,
                                     distribution_system_idref: orig_ventilation_fan.distribution_system_idref,
                                     used_for_whole_building_ventilation: orig_ventilation_fan.used_for_whole_building_ventilation)
    end
  end

  def self.set_systems_mechanical_ventilation_iad(orig_hpxml, new_hpxml)
    # Table 4.3.1(1) Configuration of Index Adjustment Design - Whole-House Mechanical ventilation fan energy
    # Table 4.3.1(1) Configuration of Index Adjustment Design - Air exchange rate

    q_tot = calc_mech_vent_q_tot()

    # Calculate fan cfm
    sla = nil
    new_hpxml.air_infiltration_measurements.each do |new_infil_measurement|
      next unless (new_infil_measurement.unit_of_measure == HPXML::UnitsACH) && (new_infil_measurement.house_pressure == 50)

      ach50 = new_infil_measurement.air_leakage
      sla = Airflow.get_infiltration_SLA_from_ACH50(ach50, 0.65, @cfa, @infilvolume)
      break
    end
    fan_type = HPXML::MechVentTypeBalanced
    q_fan = calc_mech_vent_q_fan(q_tot, sla, fan_type, orig_hpxml)

    new_hpxml.ventilation_fans.add(id: 'MechanicalVentilation',
                                   fan_type: fan_type,
                                   tested_flow_rate: q_fan,
                                   hours_in_operation: 24,
                                   fan_power: 0.7 * q_fan,
                                   used_for_whole_building_ventilation: true)
  end

  def self.set_systems_whole_house_fan_reference(orig_hpxml, new_hpxml)
    # nop
  end

  def self.set_systems_whole_house_fan_rated(orig_hpxml, new_hpxml)
    orig_hpxml.ventilation_fans.each do |orig_ventilation_fan|
      next unless orig_ventilation_fan.used_for_seasonal_cooling_load_reduction

      new_hpxml.ventilation_fans.add(id: orig_ventilation_fan.id,
                                     rated_flow_rate: orig_ventilation_fan.rated_flow_rate,
                                     fan_power: orig_ventilation_fan.fan_power,
                                     used_for_seasonal_cooling_load_reduction: orig_ventilation_fan.used_for_seasonal_cooling_load_reduction)
    end
  end

  def self.set_systems_whole_house_fan_iad(orig_hpxml, new_hpxml)
    # nop
  end

  def self.set_systems_water_heater_reference(orig_hpxml, new_hpxml)
    # Table 4.2.2(1) - Service water heating systems

    orig_hpxml.water_heating_systems.each do |orig_water_heater|
      tank_volume = orig_water_heater.tank_volume
      if [HPXML::WaterHeaterTypeCombiTankless, HPXML::WaterHeaterTypeTankless].include? orig_water_heater.water_heater_type
        tank_volume = 40.0
      end

      # Set fuel type for combi systems
      fuel_type = orig_water_heater.fuel_type
      if [HPXML::WaterHeaterTypeCombiTankless, HPXML::WaterHeaterTypeCombiStorage].include? orig_water_heater.water_heater_type
        fuel_type = orig_water_heater.related_hvac_system.heating_system_fuel
      end

      energy_factor, recovery_efficiency = get_water_heater_ef_and_re(fuel_type, tank_volume)

      heating_capacity = Waterheater.calc_water_heater_capacity(fuel_type, @nbeds, orig_hpxml.water_heating_systems.size) * 1000.0 # Btuh

      location = orig_water_heater.location
      if [Constants.CalcTypeERIIndexAdjustmentDesign, Constants.CalcTypeERIIndexAdjustmentReferenceHome].include? @calc_type
        # Hot water equipment shall be located in conditioned space.
        location = HPXML::LocationLivingSpace
      end
      location.gsub!('unvented', 'vented')

      # New water heater
      new_hpxml.water_heating_systems.add(id: orig_water_heater.id,
                                          fuel_type: fuel_type,
                                          water_heater_type: HPXML::WaterHeaterTypeStorage,
                                          location: location,
                                          performance_adjustment: 0.0,
                                          tank_volume: tank_volume,
                                          fraction_dhw_load_served: orig_water_heater.fraction_dhw_load_served,
                                          heating_capacity: heating_capacity,
                                          energy_factor: energy_factor,
                                          recovery_efficiency: recovery_efficiency,
                                          uses_desuperheater: false,
                                          temperature: Waterheater.get_default_hot_water_temperature(@eri_version))
    end

    if orig_hpxml.water_heating_systems.size == 0
      add_reference_water_heater(orig_hpxml, new_hpxml)
    end
  end

  def self.set_systems_water_heater_rated(orig_hpxml, new_hpxml)
    # Table 4.2.2(1) - Service water heating systems

    orig_hpxml.water_heating_systems.each do |orig_water_heater|
      energy_factor = orig_water_heater.energy_factor
      if energy_factor.nil?
        if not [HPXML::WaterHeaterTypeCombiTankless, HPXML::WaterHeaterTypeCombiStorage].include? orig_water_heater.water_heater_type
          wh_uef = orig_water_heater.uniform_energy_factor
          energy_factor = Waterheater.calc_ef_from_uef(wh_uef, orig_water_heater.water_heater_type, orig_water_heater.fuel_type)
        end
      end

      heating_capacity = orig_water_heater.heating_capacity
      if (orig_water_heater.water_heater_type == HPXML::WaterHeaterTypeStorage) && heating_capacity.nil?
        heating_capacity = Waterheater.calc_water_heater_capacity(orig_water_heater.fuel_type, @nbeds, orig_hpxml.water_heating_systems.size) * 1000.0 # Btuh
      end

      if orig_water_heater.water_heater_type == HPXML::WaterHeaterTypeTankless
        performance_adjustment = Waterheater.get_tankless_cycling_derate()
      else
        performance_adjustment = 0.0
      end

      uses_desuperheater = orig_water_heater.uses_desuperheater
      uses_desuperheater = false if uses_desuperheater.nil?

      # New water heater
      new_hpxml.water_heating_systems.add(id: orig_water_heater.id,
                                          fuel_type: orig_water_heater.fuel_type,
                                          water_heater_type: orig_water_heater.water_heater_type,
                                          location: orig_water_heater.location,
                                          performance_adjustment: performance_adjustment,
                                          tank_volume: orig_water_heater.tank_volume,
                                          fraction_dhw_load_served: orig_water_heater.fraction_dhw_load_served,
                                          heating_capacity: heating_capacity,
                                          energy_factor: energy_factor,
                                          recovery_efficiency: orig_water_heater.recovery_efficiency,
                                          uses_desuperheater: uses_desuperheater,
                                          jacket_r_value: orig_water_heater.jacket_r_value,
                                          related_hvac_idref: orig_water_heater.related_hvac_idref,
                                          standby_loss: orig_water_heater.standby_loss,
                                          temperature: Waterheater.get_default_hot_water_temperature(@eri_version))
    end

    if orig_hpxml.water_heating_systems.size == 0
      add_reference_water_heater(orig_hpxml, new_hpxml)
    end
  end

  def self.set_systems_water_heater_iad(orig_hpxml, new_hpxml)
    # Table 4.3.1(1) Configuration of Index Adjustment Design - Service water heating systems
    set_systems_water_heater_reference(orig_hpxml, new_hpxml)
  end

  def self.set_systems_water_heating_use_reference(orig_hpxml, new_hpxml)
    # Table 4.2.2(1) - Service water heating systems

    standard_piping_length = HotWaterAndAppliances.get_default_std_pipe_length(@has_uncond_bsmnt, @cfa, @ncfl)

    if orig_hpxml.hot_water_distributions.size == 0
      sys_id = 'HotWaterDistribution'
    else
      sys_id = orig_hpxml.hot_water_distributions[0].id
    end

    # New hot water distribution
    new_hpxml.hot_water_distributions.add(id: sys_id,
                                          system_type: HPXML::DHWDistTypeStandard,
                                          pipe_r_value: 0,
                                          standard_piping_length: standard_piping_length)

    # New water fixtures
    if orig_hpxml.water_fixtures.size == 0
      # Shower Head
      new_hpxml.water_fixtures.add(id: 'ShowerHead',
                                   water_fixture_type: HPXML::WaterFixtureTypeShowerhead,
                                   low_flow: false)

      # Faucet
      new_hpxml.water_fixtures.add(id: 'Faucet',
                                   water_fixture_type: HPXML::WaterFixtureTypeFaucet,
                                   low_flow: false)
    else
      orig_hpxml.water_fixtures.each do |orig_water_fixture|
        next unless [HPXML::WaterFixtureTypeShowerhead, HPXML::WaterFixtureTypeFaucet].include? orig_water_fixture.water_fixture_type

        new_hpxml.water_fixtures.add(id: orig_water_fixture.id,
                                     water_fixture_type: orig_water_fixture.water_fixture_type,
                                     low_flow: false)
      end
    end
  end

  def self.set_systems_water_heating_use_rated(orig_hpxml, new_hpxml)
    # Table 4.2.2(1) - Service water heating systems

    if orig_hpxml.hot_water_distributions.size == 0
      set_systems_water_heating_use_reference(orig_hpxml, new_hpxml)
      return
    end

    # New hot water distribution
    hot_water_distribution = orig_hpxml.hot_water_distributions[0]
    new_hpxml.hot_water_distributions.add(id: hot_water_distribution.id,
                                          system_type: hot_water_distribution.system_type,
                                          pipe_r_value: hot_water_distribution.pipe_r_value,
                                          standard_piping_length: hot_water_distribution.standard_piping_length,
                                          recirculation_control_type: hot_water_distribution.recirculation_control_type,
                                          recirculation_piping_length: hot_water_distribution.recirculation_piping_length,
                                          recirculation_branch_piping_length: hot_water_distribution.recirculation_branch_piping_length,
                                          recirculation_pump_power: hot_water_distribution.recirculation_pump_power,
                                          dwhr_facilities_connected: hot_water_distribution.dwhr_facilities_connected,
                                          dwhr_equal_flow: hot_water_distribution.dwhr_equal_flow,
                                          dwhr_efficiency: hot_water_distribution.dwhr_efficiency)

    # New water fixtures
    orig_hpxml.water_fixtures.each do |orig_water_fixture|
      next unless [HPXML::WaterFixtureTypeShowerhead, HPXML::WaterFixtureTypeFaucet].include? orig_water_fixture.water_fixture_type

      new_hpxml.water_fixtures.add(id: orig_water_fixture.id,
                                   water_fixture_type: orig_water_fixture.water_fixture_type,
                                   low_flow: orig_water_fixture.low_flow)
    end
  end

  def self.set_systems_water_heating_use_iad(orig_hpxml, new_hpxml)
    # Table 4.3.1(1) Configuration of Index Adjustment Design - Service water heating systems
    set_systems_water_heating_use_reference(orig_hpxml, new_hpxml)
  end

  def self.set_systems_solar_thermal_reference(orig_hpxml, new_hpxml)
    # nop
  end

  def self.set_systems_solar_thermal_rated(orig_hpxml, new_hpxml)
    return if orig_hpxml.solar_thermal_systems.size == 0

    solar_thermal_system = orig_hpxml.solar_thermal_systems[0]
    new_hpxml.solar_thermal_systems.add(id: solar_thermal_system.id,
                                        system_type: solar_thermal_system.system_type,
                                        collector_area: solar_thermal_system.collector_area,
                                        collector_loop_type: solar_thermal_system.collector_loop_type,
                                        collector_azimuth: solar_thermal_system.collector_azimuth,
                                        collector_type: solar_thermal_system.collector_type,
                                        collector_tilt: solar_thermal_system.collector_tilt,
                                        collector_frta: solar_thermal_system.collector_frta,
                                        collector_frul: solar_thermal_system.collector_frul,
                                        storage_volume: solar_thermal_system.storage_volume,
                                        water_heating_system_idref: solar_thermal_system.water_heating_system_idref,
                                        solar_fraction: solar_thermal_system.solar_fraction)
  end

  def self.set_systems_solar_thermal_iad(orig_hpxml, new_hpxml)
    # nop
  end

  def self.set_systems_photovoltaics_reference(orig_hpxml, new_hpxml)
    # nop
  end

  def self.set_systems_photovoltaics_rated(orig_hpxml, new_hpxml)
    orig_hpxml.pv_systems.each do |orig_pv_system|
      new_hpxml.pv_systems.add(id: orig_pv_system.id,
                               location: orig_pv_system.location,
                               module_type: orig_pv_system.module_type,
                               tracking: orig_pv_system.tracking,
                               array_azimuth: orig_pv_system.array_azimuth,
                               array_tilt: orig_pv_system.array_tilt,
                               max_power_output: orig_pv_system.max_power_output,
                               inverter_efficiency: orig_pv_system.inverter_efficiency,
                               system_losses_fraction: orig_pv_system.system_losses_fraction)
    end
  end

  def self.set_systems_photovoltaics_iad(orig_hpxml, new_hpxml)
    # 4.3.1 Index Adjustment Design (IAD)
    # Renewable Energy Systems that offset the energy consumption requirements of the Rated Home shall not be included in the IAD.
    # nop
  end

  def self.set_appliances_clothes_washer_reference(orig_hpxml, new_hpxml)
    clothes_washer = orig_hpxml.clothes_washers[0]
    new_hpxml.clothes_washers.add(id: clothes_washer.id,
                                  location: HPXML::LocationLivingSpace,
                                  integrated_modified_energy_factor: HotWaterAndAppliances.get_clothes_washer_reference_imef(),
                                  rated_annual_kwh: HotWaterAndAppliances.get_clothes_washer_reference_ler(),
                                  label_electric_rate: HotWaterAndAppliances.get_clothes_washer_reference_elec_rate(),
                                  label_gas_rate: HotWaterAndAppliances.get_clothes_washer_reference_gas_rate(),
                                  label_annual_gas_cost: HotWaterAndAppliances.get_clothes_washer_reference_agc(),
                                  capacity: HotWaterAndAppliances.get_clothes_washer_reference_cap())
  end

  def self.set_appliances_clothes_washer_rated(orig_hpxml, new_hpxml)
    clothes_washer = orig_hpxml.clothes_washers[0]
    new_hpxml.clothes_washers.add(id: clothes_washer.id,
                                  location: clothes_washer.location,
                                  modified_energy_factor: clothes_washer.modified_energy_factor,
                                  integrated_modified_energy_factor: clothes_washer.integrated_modified_energy_factor,
                                  rated_annual_kwh: clothes_washer.rated_annual_kwh,
                                  label_electric_rate: clothes_washer.label_electric_rate,
                                  label_gas_rate: clothes_washer.label_gas_rate,
                                  label_annual_gas_cost: clothes_washer.label_annual_gas_cost,
                                  capacity: clothes_washer.capacity)
  end

  def self.set_appliances_clothes_washer_iad(orig_hpxml, new_hpxml)
    # Table 4.3.1(1) Configuration of Index Adjustment Design - Lighting, Appliances and Miscellaneous Electric Loads (MELs)
    set_appliances_clothes_washer_reference(orig_hpxml, new_hpxml)
  end

  def self.set_appliances_clothes_dryer_reference(orig_hpxml, new_hpxml)
    clothes_dryer = orig_hpxml.clothes_dryers[0]
    new_hpxml.clothes_dryers.add(id: clothes_dryer.id,
                                 location: HPXML::LocationLivingSpace,
                                 fuel_type: clothes_dryer.fuel_type,
                                 combined_energy_factor: HotWaterAndAppliances.get_clothes_dryer_reference_cef(clothes_dryer.fuel_type),
                                 control_type: HotWaterAndAppliances.get_clothes_dryer_reference_control())
  end

  def self.set_appliances_clothes_dryer_rated(orig_hpxml, new_hpxml)
    clothes_dryer = orig_hpxml.clothes_dryers[0]
    new_hpxml.clothes_dryers.add(id: clothes_dryer.id,
                                 location: clothes_dryer.location,
                                 fuel_type: clothes_dryer.fuel_type,
                                 energy_factor: clothes_dryer.energy_factor,
                                 combined_energy_factor: clothes_dryer.combined_energy_factor,
                                 control_type: clothes_dryer.control_type)
  end

  def self.set_appliances_clothes_dryer_iad(orig_hpxml, new_hpxml)
    # Table 4.3.1(1) Configuration of Index Adjustment Design - Lighting, Appliances and Miscellaneous Electric Loads (MELs)
    set_appliances_clothes_dryer_reference(orig_hpxml, new_hpxml)
  end

  def self.set_appliances_dishwasher_reference(orig_hpxml, new_hpxml)
    dishwasher = orig_hpxml.dishwashers[0]
    new_hpxml.dishwashers.add(id: dishwasher.id,
                              energy_factor: HotWaterAndAppliances.get_dishwasher_reference_ef(),
                              place_setting_capacity: HotWaterAndAppliances.get_dishwasher_reference_cap())
  end

  def self.set_appliances_dishwasher_rated(orig_hpxml, new_hpxml)
    dishwasher = orig_hpxml.dishwashers[0]
    new_hpxml.dishwashers.add(id: dishwasher.id,
                              energy_factor: dishwasher.energy_factor,
                              rated_annual_kwh: dishwasher.rated_annual_kwh,
                              place_setting_capacity: dishwasher.place_setting_capacity)
  end

  def self.set_appliances_dishwasher_iad(orig_hpxml, new_hpxml)
    # Table 4.3.1(1) Configuration of Index Adjustment Design - Lighting, Appliances and Miscellaneous Electric Loads (MELs)
    set_appliances_dishwasher_reference(orig_hpxml, new_hpxml)
  end

  def self.set_appliances_refrigerator_reference(orig_hpxml, new_hpxml)
    # Table 4.2.2.5(1) Lighting, Appliance and Miscellaneous Electric Loads in electric ERI Reference Homes
    refrigerator_kwh = HotWaterAndAppliances.get_refrigerator_reference_annual_kwh(@nbeds)

    refrigerator = orig_hpxml.refrigerators[0]
    new_hpxml.refrigerators.add(id: refrigerator.id,
                                location: HPXML::LocationLivingSpace,
                                rated_annual_kwh: refrigerator_kwh)
  end

  def self.set_appliances_refrigerator_rated(orig_hpxml, new_hpxml)
    refrigerator = orig_hpxml.refrigerators[0]
    new_hpxml.refrigerators.add(id: refrigerator.id,
                                location: refrigerator.location,
                                rated_annual_kwh: refrigerator.rated_annual_kwh)
  end

  def self.set_appliances_refrigerator_iad(orig_hpxml, new_hpxml)
    # Table 4.3.1(1) Configuration of Index Adjustment Design - Lighting, Appliances and Miscellaneous Electric Loads (MELs)
    set_appliances_refrigerator_reference(orig_hpxml, new_hpxml)
  end

  def self.set_appliances_cooking_range_oven_reference(orig_hpxml, new_hpxml)
    cooking_range = orig_hpxml.cooking_ranges[0]
    new_hpxml.cooking_ranges.add(id: cooking_range.id,
                                 fuel_type: cooking_range.fuel_type,
                                 is_induction: HotWaterAndAppliances.get_range_oven_reference_is_induction())

    oven = orig_hpxml.ovens[0]
    new_hpxml.ovens.add(id: oven.id,
                        is_convection: HotWaterAndAppliances.get_range_oven_reference_is_convection())
  end

  def self.set_appliances_cooking_range_oven_rated(orig_hpxml, new_hpxml)
    cooking_range = orig_hpxml.cooking_ranges[0]
    new_hpxml.cooking_ranges.add(id: cooking_range.id,
                                 fuel_type: cooking_range.fuel_type,
                                 is_induction: cooking_range.is_induction)

    oven = orig_hpxml.ovens[0]
    new_hpxml.ovens.add(id: oven.id,
                        is_convection: oven.is_convection)
  end

  def self.set_appliances_cooking_range_oven_iad(orig_hpxml, new_hpxml)
    # Table 4.3.1(1) Configuration of Index Adjustment Design - Lighting, Appliances and Miscellaneous Electric Loads (MELs)
    set_appliances_cooking_range_oven_reference(orig_hpxml, new_hpxml)
  end

  def self.set_lighting_reference(orig_hpxml, new_hpxml)
    fFI_int, fFI_ext, fFI_grg, fFII_int, fFII_ext, fFII_grg = Lighting.get_reference_fractions()

    new_hpxml.lighting_groups.add(id: 'Lighting_TierI_Interior',
                                  location: HPXML::LocationInterior,
                                  fration_of_units_in_location: fFI_int,
                                  third_party_certification: HPXML::LightingTypeTierI)
    new_hpxml.lighting_groups.add(id: 'Lighting_TierI_Exterior',
                                  location: HPXML::LocationExterior,
                                  fration_of_units_in_location: fFI_ext,
                                  third_party_certification: HPXML::LightingTypeTierI)
    new_hpxml.lighting_groups.add(id: 'Lighting_TierI_Garage',
                                  location: HPXML::LocationGarage,
                                  fration_of_units_in_location: fFI_grg,
                                  third_party_certification: HPXML::LightingTypeTierI)
    new_hpxml.lighting_groups.add(id: 'Lighting_TierII_Interior',
                                  location: HPXML::LocationInterior,
                                  fration_of_units_in_location: fFII_int,
                                  third_party_certification: HPXML::LightingTypeTierII)
    new_hpxml.lighting_groups.add(id: 'Lighting_TierII_Exterior',
                                  location: HPXML::LocationExterior,
                                  fration_of_units_in_location: fFII_ext,
                                  third_party_certification: HPXML::LightingTypeTierII)
    new_hpxml.lighting_groups.add(id: 'Lighting_TierII_Garage',
                                  location: HPXML::LocationGarage,
                                  fration_of_units_in_location: fFII_grg,
                                  third_party_certification: HPXML::LightingTypeTierII)
  end

  def self.set_lighting_rated(orig_hpxml, new_hpxml)
    fFI_int, fFI_ext, fFI_grg, fFII_int, fFII_ext, fFII_grg = nil
    orig_hpxml.lighting_groups.each do |orig_lg|
      if (orig_lg.location == HPXML::LocationInterior) && (orig_lg.third_party_certification == HPXML::LightingTypeTierI)
        fFI_int = orig_lg.fration_of_units_in_location
      elsif (orig_lg.location == HPXML::LocationExterior) && (orig_lg.third_party_certification == HPXML::LightingTypeTierI)
        fFI_ext = orig_lg.fration_of_units_in_location
      elsif (orig_lg.location == HPXML::LocationGarage) && (orig_lg.third_party_certification == HPXML::LightingTypeTierI)
        fFI_grg = orig_lg.fration_of_units_in_location
      elsif (orig_lg.location == HPXML::LocationInterior) && (orig_lg.third_party_certification == HPXML::LightingTypeTierII)
        fFII_int = orig_lg.fration_of_units_in_location
      elsif (orig_lg.location == HPXML::LocationExterior) && (orig_lg.third_party_certification == HPXML::LightingTypeTierII)
        fFII_ext = orig_lg.fration_of_units_in_location
      elsif (orig_lg.location == HPXML::LocationGarage) && (orig_lg.third_party_certification == HPXML::LightingTypeTierII)
        fFII_grg = orig_lg.fration_of_units_in_location
      end
    end

    # For rating purposes, the Rated Home shall not have qFFIL less than 0.10 (10%).
    if fFI_int + fFII_int < 0.1
      fFI_int = 0.1 - fFII_int
    end

    new_hpxml.lighting_groups.add(id: 'Lighting_TierI_Interior',
                                  location: HPXML::LocationInterior,
                                  fration_of_units_in_location: fFI_int,
                                  third_party_certification: HPXML::LightingTypeTierI)
    new_hpxml.lighting_groups.add(id: 'Lighting_TierI_Exterior',
                                  location: HPXML::LocationExterior,
                                  fration_of_units_in_location: fFI_ext,
                                  third_party_certification: HPXML::LightingTypeTierI)
    new_hpxml.lighting_groups.add(id: 'Lighting_TierI_Garage',
                                  location: HPXML::LocationGarage,
                                  fration_of_units_in_location: fFI_grg,
                                  third_party_certification: HPXML::LightingTypeTierI)
    new_hpxml.lighting_groups.add(id: 'Lighting_TierII_Interior',
                                  location: HPXML::LocationInterior,
                                  fration_of_units_in_location: fFII_int,
                                  third_party_certification: HPXML::LightingTypeTierII)
    new_hpxml.lighting_groups.add(id: 'Lighting_TierII_Exterior',
                                  location: HPXML::LocationExterior,
                                  fration_of_units_in_location: fFII_ext,
                                  third_party_certification: HPXML::LightingTypeTierII)
    new_hpxml.lighting_groups.add(id: 'Lighting_TierII_Garage',
                                  location: HPXML::LocationGarage,
                                  fration_of_units_in_location: fFII_grg,
                                  third_party_certification: HPXML::LightingTypeTierII)
  end

  def self.set_lighting_iad(orig_hpxml, new_hpxml)
    fFI_int, fFI_ext, fFI_grg, fFII_int, fFII_ext, fFII_grg = Lighting.get_iad_fractions()

    new_hpxml.lighting_groups.add(id: 'Lighting_TierI_Interior',
                                  location: HPXML::LocationInterior,
                                  fration_of_units_in_location: fFI_int,
                                  third_party_certification: HPXML::LightingTypeTierI)
    new_hpxml.lighting_groups.add(id: 'Lighting_TierI_Exterior',
                                  location: HPXML::LocationExterior,
                                  fration_of_units_in_location: fFI_ext,
                                  third_party_certification: HPXML::LightingTypeTierI)
    new_hpxml.lighting_groups.add(id: 'Lighting_TierI_Garage',
                                  location: HPXML::LocationGarage,
                                  fration_of_units_in_location: fFI_grg,
                                  third_party_certification: HPXML::LightingTypeTierI)
    new_hpxml.lighting_groups.add(id: 'Lighting_TierII_Interior',
                                  location: HPXML::LocationInterior,
                                  fration_of_units_in_location: fFII_int,
                                  third_party_certification: HPXML::LightingTypeTierII)
    new_hpxml.lighting_groups.add(id: 'Lighting_TierII_Exterior',
                                  location: HPXML::LocationExterior,
                                  fration_of_units_in_location: fFII_ext,
                                  third_party_certification: HPXML::LightingTypeTierII)
    new_hpxml.lighting_groups.add(id: 'Lighting_TierII_Garage',
                                  location: HPXML::LocationGarage,
                                  fration_of_units_in_location: fFII_grg,
                                  third_party_certification: HPXML::LightingTypeTierII)
  end

  def self.set_ceiling_fans_reference(orig_hpxml, new_hpxml)
    return if orig_hpxml.ceiling_fans.size == 0

    medium_cfm = 3000.0

    new_hpxml.ceiling_fans.add(id: 'CeilingFans',
                               efficiency: medium_cfm / HVAC.get_default_ceiling_fan_power(),
                               quantity: HVAC.get_default_ceiling_fan_quantity(@nbeds))
  end

  def self.set_ceiling_fans_rated(orig_hpxml, new_hpxml)
    return if orig_hpxml.ceiling_fans.size == 0

    medium_cfm = 3000.0

    # Calculate average ceiling fan wattage
    sum_w = 0.0
    num_cfs = 0
    orig_hpxml.ceiling_fans.each do |orig_ceiling_fan|
      num_cfs += orig_ceiling_fan.quantity
      cfm_per_w = orig_ceiling_fan.efficiency
      if cfm_per_w.nil?
        fan_power_w = HVAC.get_default_ceiling_fan_power()
        cfm_per_w = medium_cfm / fan_power_w
      end
      sum_w += (medium_cfm / cfm_per_w * orig_ceiling_fan.quantity)
    end
    avg_w = sum_w / num_cfs

    new_hpxml.ceiling_fans.add(id: 'CeilingFans',
                               efficiency: medium_cfm / avg_w,
                               quantity: HVAC.get_default_ceiling_fan_quantity(@nbeds))
  end

  def self.set_ceiling_fans_iad(orig_hpxml, new_hpxml)
    # Not described in Addendum E; use Reference Home?
    set_ceiling_fans_reference(orig_hpxml, new_hpxml)
  end

  def self.set_misc_loads_reference(orig_hpxml, new_hpxml)
    # Misc
    kWh_per_year, frac_sensible, frac_latent = MiscLoads.get_residual_mels_values(@cfa)
    new_hpxml.plug_loads.add(id: 'MiscPlugLoad',
                             plug_load_type: HPXML::PlugLoadTypeOther,
                             kWh_per_year: kWh_per_year,
                             frac_sensible: frac_sensible.round(3),
                             frac_latent: frac_latent.round(3))

    # Television
    kWh_per_year, frac_sensible, frac_latent = MiscLoads.get_televisions_values(@cfa, @nbeds)
    new_hpxml.plug_loads.add(id: 'TelevisionPlugLoad',
                             plug_load_type: HPXML::PlugLoadTypeTelevision,
                             kWh_per_year: kWh_per_year,
                             frac_sensible: frac_sensible.round(3),
                             frac_latent: frac_latent.round(3))
  end

  def self.set_misc_loads_rated(orig_hpxml, new_hpxml)
    set_misc_loads_reference(orig_hpxml, new_hpxml)
  end

  def self.set_misc_loads_iad(orig_hpxml, new_hpxml)
    set_misc_loads_reference(orig_hpxml, new_hpxml)
  end

  private

  def self.get_water_heater_ef_and_re(wh_fuel_type, wh_tank_vol)
    # # Table 4.2.2(1) - Service water heating systems
    ef = nil
    re = nil
    if wh_fuel_type == HPXML::FuelTypeElectricity
      ef = 0.97 - (0.00132 * wh_tank_vol)
    else
      ef = 0.67 - (0.0019 * wh_tank_vol)
      re = 0.78
    end
    return ef.round(2), re
  end

  def self.calc_rated_home_infiltration_ach50(orig_hpxml, use_eratio_workaround)
    air_infiltration_measurements = []
    # Check for eRatio workaround first
    if use_eratio_workaround
      orig_hpxml.doc.elements.each('/HPXML/Building/BuildingDetails/Enclosure/AirInfiltration/AirInfiltrationMeasurement/extension/OverrideAirInfiltrationMeasurement') do |infil_measurement|
        air_infiltration_measurements << HPXML::AirInfiltrationMeasurement.new(orig_hpxml, infil_measurement)
      end
    end
    if air_infiltration_measurements.empty?
      orig_hpxml.air_infiltration_measurements.each do |orig_infil_measurement|
        air_infiltration_measurements << orig_infil_measurement
      end
    end

    ach50 = nil
    air_infiltration_measurements.each do |infil_measurement|
      if infil_measurement.unit_of_measure == HPXML::UnitsACHNatural
        nach = infil_measurement.air_leakage
        sla = Airflow.get_infiltration_SLA_from_ACH(nach, calc_mech_vent_h_vert_distance() / 8.202, @weather)
        ach50 = Airflow.get_infiltration_ACH50_from_SLA(sla, 0.65, @cfa, @infilvolume)
      elsif (infil_measurement.unit_of_measure == HPXML::UnitsACH) && (infil_measurement.house_pressure == 50)
        ach50 = infil_measurement.air_leakage
      elsif (infil_measurement.unit_of_measure == HPXML::UnitsCFM) && (infil_measurement.house_pressure == 50)
        ach50 = infil_measurement.air_leakage * 60.0 / @infilvolume
      end
      break unless ach50.nil?
    end

    tot_cb_area, ext_cb_area = calc_compartmentalization_boundary_areas(orig_hpxml)
    a_ext = calc_mech_vent_Aext_ratio(tot_cb_area, ext_cb_area)

    if @is_attached_unit && (Constants.ERIVersions.index(@eri_version) >= Constants.ERIVersions.index('2019')) # 2019 or newer
      cfm50 = ach50 * @infilvolume / 60.0
      if cfm50 / tot_cb_area <= 0.30
        ach50 *= a_ext
      end
    end

    # Apply min Natural ACH?
    min_nach = nil
    has_mech_vent = false
    orig_hpxml.ventilation_fans.each do |orig_ventilation_fan|
      next unless orig_ventilation_fan.used_for_whole_building_ventilation

      has_mech_vent = true
      if orig_ventilation_fan.tested_flow_rate.nil? || ((a_ext < 0.5) && (orig_ventilation_fan.fan_type == HPXML::MechVentTypeExhaust))
        min_nach = 0.30
      end
    end

    if not has_mech_vent
      min_nach = 0.30
    end

    if not min_nach.nil?
      min_sla = Airflow.get_infiltration_SLA_from_ACH(min_nach, calc_mech_vent_h_vert_distance() / 8.202, @weather)
      min_ach50 = Airflow.get_infiltration_ACH50_from_SLA(min_sla, 0.65, @cfa, @infilvolume)
      if ach50 < min_ach50
        ach50 = min_ach50
      end
    end

    return ach50
  end

  def self.calc_rated_home_qfan(orig_hpxml, fan_type, use_eratio_workaround)
    ach50 = calc_rated_home_infiltration_ach50(orig_hpxml, use_eratio_workaround)
    sla = Airflow.get_infiltration_SLA_from_ACH50(ach50, 0.65, @cfa, @infilvolume)
    q_tot = calc_mech_vent_q_tot()
    q_fan_power = calc_mech_vent_q_fan(q_tot, sla, fan_type, orig_hpxml)
    return q_fan_power
  end

  def self.calc_mech_vent_q_tot()
    return Airflow.get_mech_vent_whole_house_cfm(1.0, @nbeds, @cfa, '2013')
  end

  def self.calc_mech_vent_q_fan(q_tot, sla, fan_type, orig_hpxml)
    h = calc_mech_vent_h_vert_distance()
    hr = 8.202
    nl = 1000.0 * sla * (h / hr)**0.4 # Normalized leakage, eq. 4.4
    q_inf = nl * @weather.data.WSF * @cfa / 7.3 # Effective annual average infiltration rate, cfm, eq. 4.5a
    if Constants.ERIVersions.index(@eri_version) >= Constants.ERIVersions.index('2019') # 2019 or newer
      tot_cb_area, ext_cb_area = calc_compartmentalization_boundary_areas(orig_hpxml)
      a_ext = calc_mech_vent_Aext_ratio(tot_cb_area, ext_cb_area)
      if [HPXML::MechVentTypeBalanced, HPXML::MechVentTypeERV, HPXML::MechVentTypeHRV].include? fan_type
        phi = 1.0
      else
        phi = q_inf / q_tot
      end
      q_fan = q_tot - phi * (q_inf * a_ext)
    else
      if @is_attached_unit # No infiltration credit for attached/multifamily
        return q_tot
      end

      if q_inf > 2.0 / 3.0 * q_tot
        q_fan = q_tot - 2.0 / 3.0 * q_tot
      else
        q_fan = q_tot - q_inf
      end
    end

    return [q_fan, 0].max
  end

  def self.calc_mech_vent_h_vert_distance()
    return Float(@ncfl_ag) * @infilvolume / @cfa # inferred vertical distance between lowest and highest above-grade points within the pressure boundary
  end

  def self.calc_mech_vent_Aext_ratio(tot_cb_area, ext_cb_area)
    if not @is_attached_unit
      return 1.0 # detached unit
    end

    return ext_cb_area / tot_cb_area
  end

  def self.calc_compartmentalization_boundary_areas(orig_hpxml)
    # Returns:
    # 1. Total Compartmentalization Boundary area (i.e., surface area surrounding infiltration volume)
    # 2. Exterior Compartmentalization Boundary area (i.e., above excluding surfaces attached to garage or other housing units)

    tot_cb_area = 0.0
    ext_cb_area = 0.0

    # Populate space_within_infil_volume hash for relevant attic/foundation space types
    space_within_infil_volume = { HPXML::LocationLivingSpace => true }
    orig_hpxml.attics.each do |orig_attic|
      next unless orig_attic.attic_type == HPXML::AtticTypeUnvented

      space_within_infil_volume[HPXML::LocationAtticUnvented] = orig_attic.within_infiltration_volume
    end
    orig_hpxml.foundations.each do |orig_foundation|
      if orig_foundation.foundation_type == HPXML::FoundationTypeBasementUnconditioned
        space_within_infil_volume[HPXML::LocationBasementUnconditioned] = orig_foundation.within_infiltration_volume
      elsif orig_foundation.foundation_type == HPXML::FoundationTypeCrawlspaceUnvented
        space_within_infil_volume[HPXML::LocationCrawlspaceUnvented] = orig_foundation.within_infiltration_volume
      end
    end

    # Get surfaces bounding infiltration volume
    space_within_infil_volume.keys.each do |space_type|
      next unless space_within_infil_volume[space_type]

      (orig_hpxml.roofs + orig_hpxml.rim_joists + orig_hpxml.walls + orig_hpxml.foundation_walls + orig_hpxml.frame_floors + orig_hpxml.slabs).each do |orig_surface|
        next unless [orig_surface.interior_adjacent_to, orig_surface.exterior_adjacent_to].include? space_type

        # Exclude surfaces between two spaces that are both within infiltration volume
        next if space_within_infil_volume[orig_surface.interior_adjacent_to] && space_within_infil_volume[orig_surface.exterior_adjacent_to]

        # Update Compartmentalization Boundary areas
        tot_cb_area += orig_surface.area
        if not (orig_surface.exterior_adjacent_to.include?(HPXML::LocationOtherHousingUnit) || (orig_surface.exterior_adjacent_to == HPXML::LocationGarage))
          ext_cb_area += orig_surface.area
        end
      end
    end

    return tot_cb_area, ext_cb_area
  end

  def self.add_reference_heating_gas_furnace(new_hpxml, ref_hvacdist_ids, load_frac, orig_system = nil)
    # 78% AFUE gas furnace
    seed_id = nil
    if not orig_system.nil?
      if [Constants.CalcTypeERIReferenceHome, Constants.CalcTypeERIIndexAdjustmentReferenceHome].include? @calc_type
        # Map reference home system back to rated home system
        seed_id = orig_system.id
      end
    end

    ref_hvacdist_ids << "HVACDistribution_DSE#{ref_hvacdist_ids.size + 1}"
    new_hpxml.heating_systems.add(id: "HeatingSystem#{new_hpxml.heating_systems.size + 1}",
                                  distribution_system_idref: ref_hvacdist_ids[-1],
                                  heating_system_type: HPXML::HVACTypeFurnace,
                                  heating_system_fuel: HPXML::FuelTypeNaturalGas,
                                  heating_capacity: -1, # Use Manual J auto-sizing
                                  heating_efficiency_afue: 0.78,
                                  fraction_heat_load_served: load_frac,
                                  seed_id: seed_id)
  end

  def self.add_reference_heating_gas_boiler(new_hpxml, ref_hvacdist_ids, load_frac, orig_system = nil)
    # 80% AFUE gas boiler
    seed_id = nil
    if not orig_system.nil?
      if [Constants.CalcTypeERIReferenceHome, Constants.CalcTypeERIIndexAdjustmentReferenceHome].include? @calc_type
        # Map reference home system back to rated home system
        seed_id = orig_system.id
      end
    end

    ref_hvacdist_ids << "HVACDistribution_DSE#{ref_hvacdist_ids.size + 1}"
    new_hpxml.heating_systems.add(id: "HeatingSystem#{new_hpxml.heating_systems.size + 1}",
                                  distribution_system_idref: ref_hvacdist_ids[-1],
                                  heating_system_type: HPXML::HVACTypeBoiler,
                                  heating_system_fuel: HPXML::FuelTypeNaturalGas,
                                  heating_capacity: -1, # Use Manual J auto-sizing
                                  heating_efficiency_afue: 0.80,
                                  fraction_heat_load_served: load_frac,
                                  seed_id: seed_id)
  end

  def self.add_reference_heating_heat_pump(new_hpxml, ref_hvacdist_ids, load_frac, orig_system = nil)
    # 7.7 HSPF air source heat pump
    seed_id = nil
    if not orig_system.nil?
      if [Constants.CalcTypeERIReferenceHome, Constants.CalcTypeERIIndexAdjustmentReferenceHome].include? @calc_type
        # Map reference home system back to rated home system
        seed_id = orig_system.id
      end
    end

    # Handle backup
    backup_fuel = nil
    backup_efficiency_percent = nil
    backup_efficiency_afue = nil
    backup_capacity = nil
    backup_switchover_temp = nil
    if (not orig_system.nil?) && orig_system.respond_to?(:backup_heating_switchover_temp) && (not orig_system.backup_heating_switchover_temp.nil?)
      # Dual-fuel HP
      if orig_system.backup_heating_fuel != HPXML::FuelTypeElectricity
        backup_fuel = orig_system.backup_heating_fuel
        backup_efficiency_afue = 0.78
        backup_capacity = -1
        backup_switchover_temp = orig_system.backup_heating_switchover_temp
      else
        # nop; backup is also 7.7 HSPF, so just model as normal heat pump w/o backup
      end
    else
      # Normal heat pump
      backup_fuel = HPXML::FuelTypeElectricity
      backup_efficiency_percent = 1.0
      backup_capacity = -1
    end

    ref_hvacdist_ids << "HVACDistribution_DSE#{ref_hvacdist_ids.size + 1}"
    new_hpxml.heat_pumps.add(id: "HeatPump#{new_hpxml.heat_pumps.size + 1}",
                             distribution_system_idref: ref_hvacdist_ids[-1],
                             heat_pump_type: HPXML::HVACTypeHeatPumpAirToAir,
                             heat_pump_fuel: HPXML::FuelTypeElectricity,
                             compressor_type: HPXML::HVACCompressorTypeSingleStage,
                             cooling_capacity: -1, # Use Manual J auto-sizing
                             heating_capacity: -1, # Use Manual J auto-sizing
                             backup_heating_fuel: backup_fuel,
                             backup_heating_capacity: backup_capacity,
                             backup_heating_efficiency_percent: backup_efficiency_percent,
                             backup_heating_efficiency_afue: backup_efficiency_afue,
                             backup_heating_switchover_temp: backup_switchover_temp,
                             fraction_heat_load_served: load_frac,
                             fraction_cool_load_served: 0.0,
                             cooling_efficiency_seer: 13.0, # Arbitrary, not used
                             heating_efficiency_hspf: 7.7,
                             seed_id: seed_id)
  end

  def self.add_reference_cooling_air_conditioner(new_hpxml, ref_hvacdist_ids, load_frac, orig_system = nil)
    # 13 SEER electric air conditioner
    seed_id = nil
    shr = nil
    if not orig_system.nil?
      if [Constants.CalcTypeERIReferenceHome, Constants.CalcTypeERIIndexAdjustmentReferenceHome].include? @calc_type
        # Map reference home system back to rated home system
        seed_id = orig_system.id
      end
      shr = orig_system.cooling_shr
    end

    ref_hvacdist_ids << "HVACDistribution_DSE#{ref_hvacdist_ids.size + 1}"
    new_hpxml.cooling_systems.add(id: "CoolingSystem#{new_hpxml.cooling_systems.size + 1}",
                                  distribution_system_idref: ref_hvacdist_ids[-1],
                                  cooling_system_type: HPXML::HVACTypeCentralAirConditioner,
                                  cooling_system_fuel: HPXML::FuelTypeElectricity,
                                  compressor_type: HPXML::HVACCompressorTypeSingleStage,
                                  cooling_capacity: -1, # Use Manual J auto-sizing
                                  fraction_cool_load_served: load_frac,
                                  cooling_efficiency_seer: 13.0,
                                  cooling_shr: shr,
                                  seed_id: seed_id)
  end

  def self.add_reference_distribution_system(new_hpxml, ref_hvacdist_ids)
    # Table 4.2.2(1) - Thermal distribution systems
    ref_hvacdist_ids.each do |ref_hvacdist_id|
      new_hpxml.hvac_distributions.add(id: ref_hvacdist_id,
                                       distribution_system_type: HPXML::HVACDistributionTypeDSE,
                                       annual_heating_dse: 0.8,
                                       annual_cooling_dse: 0.8)
    end
  end

  def self.add_reference_water_heater(orig_hpxml, new_hpxml)
    wh_fuel_type = orig_hpxml.predominant_heating_fuel()
    wh_tank_vol = 40.0

    wh_ef, wh_re = get_water_heater_ef_and_re(wh_fuel_type, wh_tank_vol)
    wh_cap = Waterheater.calc_water_heater_capacity(wh_fuel_type, @nbeds, 1) * 1000.0 # Btuh

    new_hpxml.water_heating_systems.add(id: 'WaterHeatingSystem',
                                        fuel_type: wh_fuel_type,
                                        water_heater_type: HPXML::WaterHeaterTypeStorage,
                                        location: HPXML::LocationLivingSpace, # TODO => 301 Standard doesn't specify the location
                                        performance_adjustment: 0.0,
                                        tank_volume: wh_tank_vol,
                                        fraction_dhw_load_served: 1.0,
                                        heating_capacity: wh_cap,
                                        energy_factor: wh_ef,
                                        recovery_efficiency: wh_re,
                                        uses_desuperheater: false,
                                        temperature: Waterheater.get_default_hot_water_temperature(@eri_version))
  end

  def self.get_hvac_capacities_for_distribution_system(orig_hvac_dist)
    htg_cap = 0.0
    clg_cap = 0.0
    hvac = orig_hvac_dist.hvac_systems.each do |hvac|
      if hvac.respond_to?(:heating_capacity)
        htg_cap = hvac.heating_capacity
      end
      if hvac.respond_to?(:cooling_capacity)
        clg_cap = hvac.cooling_capacity
      end
    end
    return htg_cap, clg_cap
  end

  def self.get_infiltration_volume(hpxml)
    hpxml.air_infiltration_measurements.each do |air_infiltration_measurement|
      next if air_infiltration_measurement.infiltration_volume.nil?

      return air_infiltration_measurement.infiltration_volume
    end
  end

  def self.calc_wall_areas_for_windows(orig_hpxml)
    ag_bndry_wall_area = 0.0
    bg_bndry_wall_area = 0.0
    common_wall_area = 0.0 # Excludes foundation walls

    orig_hpxml.walls.each do |orig_wall|
      if orig_wall.is_thermal_boundary
        ag_bndry_wall_area += orig_wall.area
      elsif orig_wall.exterior_adjacent_to == HPXML::LocationOtherHousingUnit
        common_wall_area += orig_wall.area
      end
    end

    orig_hpxml.rim_joists.each do |orig_rim_joist|
      if orig_rim_joist.is_thermal_boundary
        ag_bndry_wall_area += orig_rim_joist.area
      elsif orig_rim_joist.exterior_adjacent_to == HPXML::LocationOtherHousingUnit
        common_wall_area += orig_rim_joist.area
      end
    end

    orig_hpxml.foundation_walls.each do |orig_foundation_wall|
      next unless orig_foundation_wall.is_thermal_boundary

      height = orig_foundation_wall.height
      bg_depth = orig_foundation_wall.depth_below_grade
      area = orig_foundation_wall.area
      ag_bndry_wall_area += (height - bg_depth) / height * area
      bg_bndry_wall_area += bg_depth / height * area
    end

    return ag_bndry_wall_area, bg_bndry_wall_area, common_wall_area
  end
end

def calc_area_weighted_sum(surfaces, attribute, use_inverse = false)
  sum_area = 0
  sum_val_times_area = 0
  surfaces.each do |surface|
    sum_area += surface.area
    if use_inverse
      sum_val_times_area += (1.0 / surface.send(attribute) * surface.area)
    else
      sum_val_times_area += (surface.send(attribute) * surface.area)
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
