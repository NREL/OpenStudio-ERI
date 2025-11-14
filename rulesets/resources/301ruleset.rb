# frozen_string_literal: true

module ERI_301_Ruleset
  def self.apply_ruleset(hpxml, run_type, calc_type, weather, eri_version, iecc_version, egrid_subregion, cambium_gea, create_time)
    # Global variables
    @weather = weather
    @egrid_subregion = egrid_subregion
    @cambium_gea = cambium_gea
    @is_southern_hemisphere = (weather.header.Latitude < 0)
    @eri_version = eri_version

    # Update HPXML object based on calculation type
    if calc_type == CalcType::ReferenceHome
      hpxml = apply_reference_home_ruleset(hpxml, iecc_version: iecc_version, is_all_electric: (run_type == RunType::CO2e))
    elsif calc_type == CalcType::RatedHome
      hpxml = apply_rated_home_ruleset(hpxml)
    elsif calc_type == CalcType::IndexAdjHome
      hpxml = apply_index_adjustment_design_ruleset(hpxml)
    elsif calc_type == CalcType::IndexAdjReferenceHome
      hpxml = apply_index_adjustment_design_ruleset(hpxml)
      hpxml = apply_reference_home_ruleset(hpxml)
    end

    # Add HPXML defaults to, e.g., RatedHome.xml
    Defaults.apply(nil, hpxml, hpxml.buildings[0], @weather, convert_shared_systems: false)

    # Ensure two otherwise identical HPXML files don't differ by create time
    hpxml.header.created_date_and_time = create_time

    return hpxml
  end

  def self.apply_reference_home_ruleset(orig_hpxml, iecc_version: nil, is_all_electric: false)
    new_hpxml = create_new_hpxml(orig_hpxml)

    new_bldg = new_hpxml.buildings[0]
    orig_bldg = orig_hpxml.buildings[0]

    # BuildingSummary
    set_summary_reference(orig_bldg, new_bldg)

    # ClimateAndRiskZones
    set_climate(orig_bldg, new_bldg)

    # Enclosure
    set_enclosure_attics_reference(orig_bldg, new_bldg)
    set_enclosure_foundations_reference(orig_bldg, new_bldg)
    set_enclosure_roofs_reference(orig_bldg, new_bldg)
    set_enclosure_rim_joists_reference(orig_bldg, new_bldg)
    set_enclosure_walls_reference(orig_bldg, new_bldg)
    set_enclosure_foundation_walls_reference(orig_bldg, new_bldg)
    set_enclosure_ceilings_reference(orig_bldg, new_bldg)
    set_enclosure_floors_reference(orig_bldg, new_bldg)
    set_enclosure_slabs_reference(orig_bldg, new_bldg)
    set_enclosure_windows_reference(orig_bldg, new_bldg)
    set_enclosure_skylights_reference(orig_bldg, new_bldg)
    set_enclosure_doors_reference(orig_bldg, new_bldg)
    set_enclosure_air_infiltration_reference(orig_bldg, new_bldg)

    # Systems
    set_systems_hvac_reference(orig_bldg, new_bldg, is_all_electric: is_all_electric)
    set_systems_mechanical_ventilation_reference(orig_bldg, new_bldg, iecc_version)
    set_systems_whole_house_fan_reference(orig_bldg, new_bldg)
    set_systems_water_heating_use_reference(new_bldg)
    set_systems_water_heater_reference(orig_bldg, new_bldg, is_all_electric: is_all_electric)
    set_systems_solar_thermal_reference(orig_bldg, new_bldg)
    set_systems_photovoltaics_reference(orig_bldg, new_bldg)
    set_systems_batteries_reference(orig_bldg, new_bldg)
    set_systems_generators_reference(orig_bldg, new_bldg)

    # Appliances
    set_appliances_clothes_washer_reference(orig_bldg, new_bldg)
    set_appliances_clothes_dryer_reference(orig_bldg, new_bldg, is_all_electric: is_all_electric)
    set_appliances_dishwasher_reference(orig_bldg, new_bldg)
    set_appliances_refrigerator_reference(orig_bldg, new_bldg)
    set_appliances_dehumidifier_reference(orig_bldg, new_bldg)
    set_appliances_cooking_range_oven_reference(orig_bldg, new_bldg, is_all_electric: is_all_electric)

    # Lighting
    set_lighting_reference(orig_bldg, new_bldg)
    set_ceiling_fans_reference(orig_bldg, new_bldg)

    # MiscLoads
    set_misc_loads_reference(new_bldg)

    return new_hpxml
  end

  def self.apply_rated_home_ruleset(orig_hpxml)
    new_hpxml = create_new_hpxml(orig_hpxml)

    new_bldg = new_hpxml.buildings[0]
    orig_bldg = orig_hpxml.buildings[0]

    # BuildingSummary
    set_summary_rated(orig_bldg, new_bldg)

    # ClimateAndRiskZones
    set_climate(orig_bldg, new_bldg)

    # Enclosure
    set_enclosure_attics_rated(orig_bldg, new_bldg)
    set_enclosure_foundations_rated(orig_bldg, new_bldg)
    set_enclosure_roofs_rated(orig_bldg, new_bldg)
    set_enclosure_rim_joists_rated(orig_bldg, new_bldg)
    set_enclosure_walls_rated(orig_bldg, new_bldg)
    set_enclosure_foundation_walls_rated(orig_bldg, new_bldg)
    set_enclosure_ceilings_rated(orig_bldg, new_bldg)
    set_enclosure_floors_rated(orig_bldg, new_bldg)
    set_enclosure_slabs_rated(orig_bldg, new_bldg)
    set_enclosure_windows_rated(orig_bldg, new_bldg)
    set_enclosure_skylights_rated(orig_bldg, new_bldg)
    set_enclosure_doors_rated(orig_bldg, new_bldg)
    set_enclosure_air_infiltration_rated(orig_bldg, new_bldg)

    # Systems
    set_systems_hvac_rated(orig_bldg, new_bldg)
    set_systems_mechanical_ventilation_rated(orig_bldg, new_bldg)
    set_systems_whole_house_fan_rated(orig_bldg, new_bldg)
    set_systems_water_heating_use_rated(orig_bldg, new_bldg)
    set_systems_water_heater_rated(orig_bldg, new_bldg)
    set_systems_solar_thermal_rated(orig_bldg, new_bldg)
    set_systems_photovoltaics_rated(orig_bldg, new_bldg)
    set_systems_batteries_rated(orig_bldg, new_bldg)
    set_systems_generators_rated(orig_bldg, new_bldg)

    # Appliances
    set_appliances_clothes_washer_rated(orig_bldg, new_bldg)
    set_appliances_clothes_dryer_rated(orig_bldg, new_bldg)
    set_appliances_dishwasher_rated(orig_bldg, new_bldg)
    set_appliances_refrigerator_rated(orig_bldg, new_bldg)
    set_appliances_dehumidifier_rated(orig_bldg, new_bldg)
    set_appliances_cooking_range_oven_rated(orig_bldg, new_bldg)

    # Lighting
    set_lighting_rated(orig_bldg, new_bldg)
    set_ceiling_fans_rated(orig_bldg, new_bldg)

    # MiscLoads
    set_misc_loads_rated(new_bldg)

    return new_hpxml
  end

  def self.apply_index_adjustment_design_ruleset(orig_hpxml)
    new_hpxml = create_new_hpxml(orig_hpxml)

    new_bldg = new_hpxml.buildings[0]
    orig_bldg = orig_hpxml.buildings[0]

    remove_surfaces_from_iad(orig_bldg)

    # BuildingSummary
    set_summary_iad(orig_bldg, new_bldg)

    # ClimateAndRiskZones
    set_climate(orig_bldg, new_bldg)

    # Enclosure
    set_enclosure_attics_iad(orig_bldg, new_bldg)
    set_enclosure_foundations_iad(new_bldg)
    set_enclosure_roofs_iad(orig_bldg, new_bldg)
    set_enclosure_rim_joists_iad(orig_bldg, new_bldg)
    set_enclosure_walls_iad(orig_bldg, new_bldg)
    set_enclosure_foundation_walls_iad(new_bldg)
    set_enclosure_ceilings_iad(orig_bldg, new_bldg)
    set_enclosure_floors_iad(new_bldg)
    set_enclosure_slabs_iad(new_bldg)
    set_enclosure_windows_iad(orig_bldg, new_bldg)
    set_enclosure_skylights_iad(orig_bldg, new_bldg)
    set_enclosure_doors_iad(orig_bldg, new_bldg)
    set_enclosure_air_infiltration_iad(new_bldg)

    # Systems
    set_systems_hvac_iad(orig_bldg, new_bldg)
    set_systems_mechanical_ventilation_iad(new_bldg)
    set_systems_whole_house_fan_iad(orig_bldg, new_bldg)
    set_systems_water_heating_use_iad(new_bldg)
    set_systems_water_heater_iad(orig_bldg, new_bldg)
    set_systems_solar_thermal_iad(orig_bldg, new_bldg)
    set_systems_photovoltaics_iad(orig_bldg, new_bldg)
    set_systems_batteries_iad(orig_bldg, new_bldg)
    set_systems_generators_iad(orig_bldg, new_bldg)

    # Appliances
    set_appliances_clothes_washer_iad(orig_bldg, new_bldg)
    set_appliances_clothes_dryer_iad(orig_bldg, new_bldg)
    set_appliances_dishwasher_iad(orig_bldg, new_bldg)
    set_appliances_refrigerator_iad(orig_bldg, new_bldg)
    set_appliances_dehumidifier_iad(orig_bldg, new_bldg)
    set_appliances_cooking_range_oven_iad(orig_bldg, new_bldg)

    # Lighting
    set_lighting_iad(orig_bldg, new_bldg)
    set_ceiling_fans_iad(orig_bldg, new_bldg)

    # MiscLoads
    set_misc_loads_iad(new_bldg)

    return new_hpxml
  end

  def self.create_new_hpxml(orig_hpxml)
    new_hpxml = HPXML.new

    new_hpxml.header.xml_type = orig_hpxml.header.xml_type
    new_hpxml.header.xml_generated_by = 'OpenStudio-ERI'
    new_hpxml.header.transaction = orig_hpxml.header.transaction
    new_hpxml.header.software_program_used = orig_hpxml.header.software_program_used
    new_hpxml.header.software_program_version = orig_hpxml.header.software_program_version
    new_hpxml.header.eri_calculation_versions = [@eri_version]

    orig_bldg = orig_hpxml.buildings[0]
    new_hpxml.buildings.add(building_id: orig_bldg.building_id)
    new_bldg = new_hpxml.buildings[0]

    new_bldg.event_type = orig_bldg.event_type
    new_bldg.state_code = orig_bldg.state_code
    new_bldg.zip_code = orig_bldg.zip_code
    new_bldg.dst_observed = false
    new_bldg.header.allow_increased_fixed_capacities = true
    new_bldg.header.heat_pump_sizing_methodology = HPXML::HeatPumpSizingHERS
    new_bldg.header.natvent_days_per_week = 7
    new_bldg.header.manualj_internal_loads_sensible = 1600
    new_bldg.header.manualj_internal_loads_latent = 0
    new_bldg.header.manualj_num_occupants = orig_bldg.building_construction.number_of_bedrooms + 1
    new_bldg.header.manualj_heating_setpoint = 70
    new_bldg.header.manualj_cooling_setpoint = 75
    new_hpxml.header.temperature_capacitance_multiplier = 1.0

    new_bldg.site.available_fuels = orig_bldg.site.available_fuels
    new_bldg.site.site_type = HPXML::SiteTypeSuburban
    new_bldg.site.shielding_of_home = HPXML::ShieldingNormal

    add_emissions_scenarios(new_hpxml, new_bldg)

    return new_hpxml
  end

  def self.remove_surfaces_from_iad(orig_bldg)
    # Remove garage, multifamily buffer, and adiabatic surfaces as appropriate.

    # Garage only
    (orig_bldg.roofs + orig_bldg.floors + orig_bldg.slabs).each do |orig_surface|
      next unless [HPXML::LocationGarage].include?(orig_surface.interior_adjacent_to) ||
                  [HPXML::LocationGarage].include?(orig_surface.exterior_adjacent_to)

      orig_surface.delete
    end

    # Garage, multifamily buffer, and adiabatic
    (orig_bldg.rim_joists + orig_bldg.walls + orig_bldg.foundation_walls).each do |orig_surface|
      next unless [HPXML::LocationGarage, HPXML::LocationOtherMultifamilyBufferSpace, HPXML::LocationOtherHousingUnit].include?(orig_surface.interior_adjacent_to) ||
                  [HPXML::LocationGarage, HPXML::LocationOtherMultifamilyBufferSpace, HPXML::LocationOtherHousingUnit].include?(orig_surface.exterior_adjacent_to)

      orig_surface.delete
    end
  end

  def self.set_summary_reference(orig_bldg, new_bldg)
    # Global variables
    @bldg_type = orig_bldg.building_construction.residential_facility_type
    @cfa = orig_bldg.building_construction.conditioned_floor_area
    @nbeds = orig_bldg.building_construction.number_of_bedrooms
    @ncfl = orig_bldg.building_construction.number_of_conditioned_floors
    @ncfl_ag = orig_bldg.building_construction.number_of_conditioned_floors_above_grade

    new_bldg.building_construction.number_of_conditioned_floors = orig_bldg.building_construction.number_of_conditioned_floors
    new_bldg.building_construction.number_of_conditioned_floors_above_grade = orig_bldg.building_construction.number_of_conditioned_floors_above_grade
    new_bldg.building_construction.number_of_bedrooms = orig_bldg.building_construction.number_of_bedrooms
    new_bldg.building_construction.conditioned_floor_area = orig_bldg.building_construction.conditioned_floor_area
    new_bldg.building_construction.residential_facility_type = @bldg_type
    new_bldg.building_construction.unit_height_above_grade = 0
    new_bldg.air_infiltration.has_flue_or_chimney_in_conditioned_space = false
  end

  def self.set_summary_rated(orig_bldg, new_bldg)
    # Global variables
    @bldg_type = orig_bldg.building_construction.residential_facility_type
    @cfa = orig_bldg.building_construction.conditioned_floor_area
    @nbeds = orig_bldg.building_construction.number_of_bedrooms
    @ncfl = orig_bldg.building_construction.number_of_conditioned_floors
    @ncfl_ag = orig_bldg.building_construction.number_of_conditioned_floors_above_grade

    new_bldg.building_construction.number_of_conditioned_floors = orig_bldg.building_construction.number_of_conditioned_floors
    new_bldg.building_construction.number_of_conditioned_floors_above_grade = orig_bldg.building_construction.number_of_conditioned_floors_above_grade
    new_bldg.building_construction.number_of_bedrooms = orig_bldg.building_construction.number_of_bedrooms
    new_bldg.building_construction.conditioned_floor_area = orig_bldg.building_construction.conditioned_floor_area
    new_bldg.building_construction.residential_facility_type = @bldg_type
    new_bldg.building_construction.unit_height_above_grade = 0
    new_bldg.air_infiltration.has_flue_or_chimney_in_conditioned_space = false
  end

  def self.set_summary_iad(orig_bldg, new_bldg)
    # Global variables
    @bldg_type = orig_bldg.building_construction.residential_facility_type
    @cfa = 2400.0
    @nbeds = 3
    @ncfl = 2.0
    @ncfl_ag = 2.0

    new_bldg.building_construction.number_of_conditioned_floors = @ncfl
    new_bldg.building_construction.number_of_conditioned_floors_above_grade = @ncfl_ag
    new_bldg.building_construction.number_of_bedrooms = @nbeds
    new_bldg.building_construction.conditioned_floor_area = @cfa
    new_bldg.building_construction.residential_facility_type = @bldg_type
    new_bldg.building_construction.unit_height_above_grade = 0
    new_bldg.air_infiltration.has_flue_or_chimney_in_conditioned_space = false
  end

  def self.set_climate(orig_bldg, new_bldg)
    # Always use 2006 IECC climate zone for ERI calculation
    iecc_climate_zone, year = get_climate_zone_of_year(orig_bldg, 2006)
    new_bldg.climate_and_risk_zones.climate_zone_ieccs.add(year: year,
                                                           zone: iecc_climate_zone)
    new_bldg.climate_and_risk_zones.weather_station_id = orig_bldg.climate_and_risk_zones.weather_station_id
    new_bldg.climate_and_risk_zones.weather_station_name = orig_bldg.climate_and_risk_zones.weather_station_name
    new_bldg.climate_and_risk_zones.weather_station_epw_filepath = orig_bldg.climate_and_risk_zones.weather_station_epw_filepath
    @iecc_zone = iecc_climate_zone
  end

  def self.set_enclosure_air_infiltration_reference(orig_bldg, new_bldg)
    infil_values = Airflow.get_values_from_air_infiltration_measurements(orig_bldg, @weather)
    sla = 0.00036
    ach50 = Airflow.get_infiltration_ACH50_from_SLA(sla, infil_values[:avg_ceil_height])
    new_bldg.air_infiltration_measurements.add(id: 'Infiltration_ACH50',
                                               house_pressure: 50,
                                               unit_of_measure: HPXML::UnitsACH,
                                               air_leakage: ach50.round(2),
                                               infiltration_volume: infil_values[:volume],
                                               infiltration_height: infil_values[:height],
                                               infiltration_type: HPXML::InfiltrationTypeUnitExterior,
                                               a_ext: 1.0)
  end

  def self.set_enclosure_air_infiltration_rated(orig_bldg, new_bldg)
    infil_values = Airflow.get_values_from_air_infiltration_measurements(orig_bldg, @weather)
    ach50, a_ext = calc_rated_home_infiltration_ach50(orig_bldg)
    new_bldg.air_infiltration_measurements.add(id: 'AirInfiltrationMeasurement',
                                               house_pressure: 50,
                                               unit_of_measure: HPXML::UnitsACH,
                                               air_leakage: ach50.round(2),
                                               infiltration_volume: infil_values[:volume],
                                               infiltration_height: infil_values[:height],
                                               infiltration_type: HPXML::InfiltrationTypeUnitExterior,
                                               a_ext: a_ext.round(3)) # Aext reported solely for inspection
  end

  def self.set_enclosure_air_infiltration_iad(new_bldg)
    infil_volume = 20400
    infil_height = 17.0

    if ['1A', '1B', '1C', '2A', '2B', '2C'].include? @iecc_zone
      ach50 = 5.0
    elsif ['3A', '3B', '3C', '4A', '4B', '4C', '5A', '5B', '5C', '6A', '6B', '6C', '7', '8'].include? @iecc_zone
      ach50 = 3.0
    end
    new_bldg.air_infiltration_measurements.add(id: 'Infiltration_ACH50',
                                               house_pressure: 50,
                                               unit_of_measure: HPXML::UnitsACH,
                                               air_leakage: ach50,
                                               infiltration_volume: infil_volume,
                                               infiltration_height: infil_height,
                                               infiltration_type: HPXML::InfiltrationTypeUnitExterior,
                                               a_ext: 1.0)
  end

  def self.set_enclosure_attics_reference(orig_bldg, new_bldg)
    # Check if vented attic (or unvented attic, which will become a vented attic) exists
    orig_bldg.roofs.each do |roof|
      next unless roof.interior_adjacent_to.include? 'attic'

      new_bldg.attics.add(id: 'VentedAttic',
                          attic_type: HPXML::AtticTypeVented,
                          vented_attic_sla: Defaults.get_vented_attic_sla())
      break
    end
  end

  def self.set_enclosure_attics_rated(orig_bldg, new_bldg)
    # Preserve vented attic ventilation rate
    orig_bldg.attics.each do |orig_attic|
      next unless orig_attic.attic_type == HPXML::AtticTypeVented

      new_bldg.attics.add(id: orig_attic.id,
                          attic_type: orig_attic.attic_type,
                          vented_attic_sla: orig_attic.vented_attic_sla,
                          vented_attic_ach: orig_attic.vented_attic_ach)
    end
  end

  def self.set_enclosure_attics_iad(orig_bldg, new_bldg)
    set_enclosure_attics_rated(orig_bldg, new_bldg)
  end

  def self.set_enclosure_foundations_reference(orig_bldg, new_bldg)
    # Check if vented crawlspace (or unvented crawlspace, which will become a vented crawlspace) exists.
    orig_bldg.floors.each do |orig_floor|
      next unless orig_floor.interior_adjacent_to.include?('crawlspace') || orig_floor.exterior_adjacent_to.include?('crawlspace')

      new_bldg.foundations.add(id: 'VentedCrawlspace',
                               foundation_type: HPXML::FoundationTypeCrawlspaceVented,
                               vented_crawlspace_sla: Defaults.get_vented_crawl_sla())
      break
    end
  end

  def self.set_enclosure_foundations_rated(orig_bldg, new_bldg)
    # Preserve vented crawlspace ventilation rate.
    reference_crawlspace_sla = Defaults.get_vented_crawl_sla()
    orig_bldg.foundations.each do |orig_foundation|
      next unless orig_foundation.foundation_type == HPXML::FoundationTypeCrawlspaceVented

      vented_crawl_sla = orig_foundation.vented_crawlspace_sla
      if vented_crawl_sla.nil? || (vented_crawl_sla < reference_crawlspace_sla) # FUTURE: Allow approved ground cover
        vented_crawl_sla = reference_crawlspace_sla
      end
      new_bldg.foundations.add(id: orig_foundation.id,
                               foundation_type: orig_foundation.foundation_type,
                               vented_crawlspace_sla: vented_crawl_sla)
    end
  end

  def self.set_enclosure_foundations_iad(new_bldg)
    # Always has a vented crawlspace
    new_bldg.foundations.add(id: 'VentedCrawlspace',
                             foundation_type: HPXML::FoundationTypeCrawlspaceVented,
                             vented_crawlspace_sla: Defaults.get_vented_crawl_sla())
  end

  def self.set_enclosure_roofs_reference(orig_bldg, new_bldg)
    # Table 4.2.2(1) - Roofs
    ceiling_ufactor = get_reference_ceiling_ufactor()

    ext_thermal_bndry_roofs = orig_bldg.roofs.select { |roof| roof.is_exterior_thermal_boundary }
    sum_gross_area = ext_thermal_bndry_roofs.map { |roof| roof.area }.sum(0)
    avg_pitch = calc_area_weighted_avg(ext_thermal_bndry_roofs, :pitch, backup_value: 5)
    solar_abs = 0.75
    emittance = 0.90

    # Create insulated roofs for exterior thermal boundary surface.
    # Area is equally distributed to each direction to be consistent with walls.
    if sum_gross_area > 0.1
      new_bldg.roofs.add(id: 'RoofArea',
                         interior_adjacent_to: HPXML::LocationConditionedSpace,
                         area: sum_gross_area,
                         azimuth: nil,
                         solar_absorptance: solar_abs,
                         emittance: emittance,
                         pitch: avg_pitch,
                         insulation_assembly_r_value: (1.0 / ceiling_ufactor).round(3))
    end

    # Preserve other roofs:
    # 1. Non-thermal boundary surfaces (e.g., over garage)
    orig_bldg.roofs.each do |orig_roof|
      next if orig_roof.is_exterior_thermal_boundary

      insulation_assembly_r_value = [orig_roof.insulation_assembly_r_value, 2.3].min # uninsulated
      new_bldg.roofs.add(id: orig_roof.id,
                         interior_adjacent_to: orig_roof.interior_adjacent_to.gsub('unvented', 'vented'),
                         area: orig_roof.area,
                         azimuth: orig_roof.azimuth,
                         solar_absorptance: solar_abs,
                         emittance: emittance,
                         pitch: orig_roof.pitch,
                         insulation_id: orig_roof.insulation_id,
                         insulation_assembly_r_value: insulation_assembly_r_value)
    end
  end

  def self.set_enclosure_roofs_rated(orig_bldg, new_bldg)
    # Preserve all roofs
    orig_bldg.roofs.each do |orig_roof|
      new_bldg.roofs.add(id: orig_roof.id,
                         interior_adjacent_to: orig_roof.interior_adjacent_to,
                         area: orig_roof.area,
                         azimuth: orig_roof.azimuth,
                         solar_absorptance: orig_roof.solar_absorptance,
                         emittance: orig_roof.emittance,
                         pitch: orig_roof.pitch,
                         radiant_barrier: orig_roof.radiant_barrier,
                         radiant_barrier_grade: orig_roof.radiant_barrier_grade,
                         insulation_id: orig_roof.insulation_id,
                         insulation_assembly_r_value: orig_roof.insulation_assembly_r_value)
    end
  end

  def self.set_enclosure_roofs_iad(orig_bldg, new_bldg)
    set_enclosure_roofs_rated(orig_bldg, new_bldg)

    # Scale down roof area to 1300 sqft while maintaining ratio of attic types.
    sum_roof_area = 0.0
    new_bldg.roofs.each do |new_roof|
      sum_roof_area += new_roof.area
    end
    new_bldg.roofs.each do |new_roof|
      new_roof.area = 1300.0 * new_roof.area / sum_roof_area
    end
  end

  def self.set_enclosure_rim_joists_reference(orig_bldg, new_bldg)
    # Table 4.2.2(1) - Above-grade walls
    ufactor = get_reference_wall_ufactor()

    ext_thermal_bndry_rim_joists = orig_bldg.rim_joists.select { |rim_joist| rim_joist.is_exterior && rim_joist.is_thermal_boundary }

    ext_thermal_bndry_rim_joists_ag = ext_thermal_bndry_rim_joists.select { |rim_joist| rim_joist.interior_adjacent_to == HPXML::LocationConditionedSpace }
    sum_gross_area_ag = ext_thermal_bndry_rim_joists_ag.map { |rim_joist| rim_joist.area }.sum(0)

    ext_thermal_bndry_rim_joists_bg = ext_thermal_bndry_rim_joists.select { |rim_joist| rim_joist.interior_adjacent_to == HPXML::LocationBasementConditioned }
    sum_gross_area_bg = ext_thermal_bndry_rim_joists_bg.map { |rim_joist| rim_joist.area }.sum(0)

    solar_absorptance = 0.75
    emittance = 0.90

    # Create insulated rim joists for exterior thermal boundary surface.
    # Area is equally distributed to each direction to be consistent with walls.
    # Need to preserve above-grade vs below-grade for inferred infiltration height.
    if sum_gross_area_ag > 0
      new_bldg.rim_joists.add(id: 'RimJoistArea',
                              exterior_adjacent_to: HPXML::LocationOutside,
                              interior_adjacent_to: HPXML::LocationConditionedSpace,
                              area: sum_gross_area_ag,
                              azimuth: nil,
                              solar_absorptance: solar_absorptance,
                              emittance: emittance,
                              insulation_assembly_r_value: (1.0 / ufactor).round(3))
    end
    if sum_gross_area_bg > 0
      new_bldg.rim_joists.add(id: 'RimJoistAreaBasement',
                              exterior_adjacent_to: HPXML::LocationOutside,
                              interior_adjacent_to: HPXML::LocationBasementConditioned,
                              area: sum_gross_area_bg,
                              azimuth: nil,
                              solar_absorptance: solar_absorptance,
                              emittance: emittance,
                              insulation_assembly_r_value: (1.0 / ufactor).round(3))
    end

    # Preserve other rim joists:
    # 1. Interior thermal boundary surfaces (e.g., between conditioned basement and crawlspace)
    # 2. Exterior non-thermal boundary surfaces (e.g., between unconditioned basement and outside)
    orig_bldg.rim_joists.each do |orig_rim_joist|
      next if orig_rim_joist.is_exterior_thermal_boundary

      insulation_assembly_r_value = [orig_rim_joist.insulation_assembly_r_value, 4.0].min # uninsulated
      if orig_rim_joist.is_thermal_boundary
        insulation_assembly_r_value = (1.0 / ufactor).round(3)
      end
      new_bldg.rim_joists.add(id: orig_rim_joist.id,
                              exterior_adjacent_to: orig_rim_joist.exterior_adjacent_to.gsub('unvented', 'vented'),
                              interior_adjacent_to: orig_rim_joist.interior_adjacent_to.gsub('unvented', 'vented'),
                              area: orig_rim_joist.area,
                              azimuth: orig_rim_joist.azimuth,
                              solar_absorptance: solar_absorptance,
                              emittance: emittance,
                              insulation_id: orig_rim_joist.insulation_id,
                              insulation_assembly_r_value: insulation_assembly_r_value)
    end
  end

  def self.set_enclosure_rim_joists_rated(orig_bldg, new_bldg)
    # Preserve all rim joists
    orig_bldg.rim_joists.each do |orig_rim_joist|
      new_bldg.rim_joists.add(id: orig_rim_joist.id,
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

  def self.set_enclosure_rim_joists_iad(orig_bldg, new_bldg)
    # nop; included in above-grade walls
  end

  def self.set_enclosure_walls_reference(orig_bldg, new_bldg)
    # Table 4.2.2(1) - Above-grade walls
    ufactor = get_reference_wall_ufactor()

    ext_thermal_bndry_walls = orig_bldg.walls.select { |wall| wall.is_exterior_thermal_boundary }
    sum_ext_wall_gross_area = ext_thermal_bndry_walls.map { |wall| wall.area }.sum(0)
    other_walls = orig_bldg.walls - ext_thermal_bndry_walls

    solar_absorptance = 0.75
    emittance = 0.90

    # Create insulated walls for exterior thermal boundary surface.
    # Area is equally distributed to each direction to be able to accommodate windows,
    # which are also equally distributed.
    if sum_ext_wall_gross_area > 0.1
      new_bldg.walls.add(id: 'WallArea',
                         exterior_adjacent_to: HPXML::LocationOutside,
                         interior_adjacent_to: HPXML::LocationConditionedSpace,
                         wall_type: HPXML::WallTypeWoodStud,
                         area: sum_ext_wall_gross_area,
                         azimuth: nil,
                         solar_absorptance: solar_absorptance,
                         emittance: emittance,
                         insulation_assembly_r_value: (1.0 / ufactor).round(3))
    end

    # Create walls for Above-grade walls separating Conditioned Space Volume
    # from Unrated Heated Space, Multifamily Buffer Boundary, or Non-Freezing Space.
    if Constants::ERIVersions.index(@eri_version) >= Constants::ERIVersions.index('2022')
      common_space_walls = orig_bldg.walls.select { |wall| wall.is_conditioned && HPXML::multifamily_common_space_locations.include?(wall.exterior_adjacent_to) }
      common_space_wall_ufactor = get_reference_wall_ufactor_common_space()
      common_space_walls.each do |orig_wall|
        new_bldg.walls.add(id: orig_wall.id,
                           exterior_adjacent_to: orig_wall.exterior_adjacent_to,
                           interior_adjacent_to: HPXML::LocationConditionedSpace,
                           wall_type: orig_wall.wall_type,
                           area: orig_wall.area,
                           azimuth: orig_wall.azimuth,
                           solar_absorptance: solar_absorptance,
                           emittance: emittance,
                           insulation_id: orig_wall.insulation_id,
                           insulation_assembly_r_value: (1.0 / common_space_wall_ufactor).round(3))
      end
      other_walls -= common_space_walls
    end

    # Preserve other walls:
    # 1. Interior thermal boundary surfaces (e.g., between conditioned space and garage)
    # 2. Exterior non-thermal boundary surfaces (e.g., between garage and outside)
    other_walls.each do |orig_wall|
      if orig_wall.is_thermal_boundary
        insulation_assembly_r_value = (1.0 / ufactor).round(3)
      else
        insulation_assembly_r_value = [orig_wall.insulation_assembly_r_value, 4.0].min # uninsulated
      end
      new_bldg.walls.add(id: orig_wall.id,
                         exterior_adjacent_to: orig_wall.exterior_adjacent_to.gsub('unvented', 'vented'),
                         interior_adjacent_to: orig_wall.interior_adjacent_to.gsub('unvented', 'vented'),
                         wall_type: orig_wall.wall_type,
                         area: orig_wall.area,
                         azimuth: orig_wall.azimuth,
                         solar_absorptance: solar_absorptance,
                         emittance: emittance,
                         insulation_id: orig_wall.insulation_id,
                         insulation_assembly_r_value: insulation_assembly_r_value)
    end
  end

  def self.set_enclosure_walls_rated(orig_bldg, new_bldg)
    # Preserve all walls
    orig_bldg.walls.each do |orig_wall|
      new_bldg.walls.add(id: orig_wall.id,
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

  def self.set_enclosure_walls_iad(orig_bldg, new_bldg)
    # Table 4.3.1(1) Configuration of Index Adjustment Design - Above-grade walls
    ext_thermal_bndry_walls = orig_bldg.walls.select { |wall| wall.is_exterior_thermal_boundary }
    avg_solar_abs = calc_area_weighted_avg(ext_thermal_bndry_walls, :solar_absorptance)
    avg_emittance = calc_area_weighted_avg(ext_thermal_bndry_walls, :emittance)
    avg_r_value = calc_area_weighted_avg(ext_thermal_bndry_walls, :insulation_assembly_r_value, use_inverse: true)

    # Add 2355.52 sqft of exterior thermal boundary wall area
    new_bldg.walls.add(id: 'WallArea',
                       exterior_adjacent_to: HPXML::LocationOutside,
                       interior_adjacent_to: HPXML::LocationConditionedSpace,
                       wall_type: HPXML::WallTypeWoodStud,
                       area: 2355.52,
                       azimuth: nil,
                       solar_absorptance: avg_solar_abs.round(2),
                       emittance: avg_emittance.round(2),
                       insulation_assembly_r_value: avg_r_value.round(3))
  end

  def self.set_enclosure_foundation_walls_reference(orig_bldg, new_bldg)
    wall_rvalue = get_reference_basement_wall_rvalue()

    orig_bldg.foundation_walls.each do |orig_foundation_wall|
      # Insulated for, e.g., conditioned basement walls adjacent to ground.
      # Uninsulated for, e.g., crawlspace/unconditioned basement walls adjacent to ground.
      if orig_foundation_wall.is_thermal_boundary
        insulation_interior_r_value = wall_rvalue
        insulation_interior_distance_to_bottom = orig_foundation_wall.height
      else
        insulation_interior_r_value = 0
        insulation_interior_distance_to_bottom = 0
      end
      new_bldg.foundation_walls.add(id: orig_foundation_wall.id,
                                    exterior_adjacent_to: orig_foundation_wall.exterior_adjacent_to.gsub('unvented', 'vented'),
                                    interior_adjacent_to: orig_foundation_wall.interior_adjacent_to.gsub('unvented', 'vented'),
                                    type: orig_foundation_wall.type,
                                    height: orig_foundation_wall.height,
                                    area: orig_foundation_wall.area,
                                    azimuth: orig_foundation_wall.azimuth,
                                    thickness: orig_foundation_wall.thickness,
                                    depth_below_grade: orig_foundation_wall.depth_below_grade,
                                    insulation_id: orig_foundation_wall.insulation_id,
                                    insulation_interior_r_value: insulation_interior_r_value,
                                    insulation_interior_distance_to_top: 0,
                                    insulation_interior_distance_to_bottom: insulation_interior_distance_to_bottom,
                                    insulation_exterior_r_value: 0,
                                    insulation_exterior_distance_to_top: 0,
                                    insulation_exterior_distance_to_bottom: 0)
    end
  end

  def self.set_enclosure_foundation_walls_rated(orig_bldg, new_bldg)
    # Preserve all foundation walls
    orig_bldg.foundation_walls.each do |orig_foundation_wall|
      new_bldg.foundation_walls.add(id: orig_foundation_wall.id,
                                    exterior_adjacent_to: orig_foundation_wall.exterior_adjacent_to,
                                    interior_adjacent_to: orig_foundation_wall.interior_adjacent_to,
                                    type: orig_foundation_wall.type,
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

  def self.set_enclosure_foundation_walls_iad(new_bldg)
    # Add vented crawlspace foundation wall
    new_bldg.foundation_walls.add(id: 'FoundationWall',
                                  interior_adjacent_to: HPXML::LocationCrawlspaceVented,
                                  exterior_adjacent_to: HPXML::LocationGround,
                                  type: HPXML::FoundationWallTypeSolidConcrete,
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

  def self.set_enclosure_ceilings_reference(orig_bldg, new_bldg)
    ceiling_ufactor = get_reference_ceiling_ufactor()

    # Table 4.2.2(1) - Ceilings
    orig_bldg.floors.each do |orig_floor|
      next unless orig_floor.is_ceiling

      if orig_floor.is_thermal_boundary
        # Insulated for, e.g., ceilings between vented attic and conditioned space.
        insulation_assembly_r_value = (1.0 / ceiling_ufactor).round(3)
      else
        # Uninsulated for, e.g., ceilings between vented attic and garage.
        insulation_assembly_r_value = [orig_floor.insulation_assembly_r_value, 2.1].min # uninsulated
      end
      new_bldg.floors.add(id: orig_floor.id,
                          exterior_adjacent_to: orig_floor.exterior_adjacent_to.gsub('unvented', 'vented'),
                          interior_adjacent_to: orig_floor.interior_adjacent_to.gsub('unvented', 'vented'),
                          floor_or_ceiling: orig_floor.floor_or_ceiling,
                          floor_type: HPXML::FloorTypeWoodFrame,
                          area: orig_floor.area,
                          insulation_id: orig_floor.insulation_id,
                          insulation_assembly_r_value: insulation_assembly_r_value)
    end
  end

  def self.set_enclosure_ceilings_rated(orig_bldg, new_bldg)
    # Preserve all ceilings
    orig_bldg.floors.each do |orig_floor|
      next unless orig_floor.is_ceiling

      new_bldg.floors.add(id: orig_floor.id,
                          exterior_adjacent_to: orig_floor.exterior_adjacent_to,
                          interior_adjacent_to: orig_floor.interior_adjacent_to,
                          floor_or_ceiling: orig_floor.floor_or_ceiling,
                          floor_type: orig_floor.floor_type,
                          area: orig_floor.area,
                          insulation_id: orig_floor.insulation_id,
                          insulation_assembly_r_value: orig_floor.insulation_assembly_r_value)
    end
  end

  def self.set_enclosure_ceilings_iad(orig_bldg, new_bldg)
    set_enclosure_ceilings_rated(orig_bldg, new_bldg)

    # Scale down ceiling area to 1200 sqft while maintaining ratio of attic types.
    sum_ceiling_area = 0.0
    new_bldg.floors.each do |new_floor|
      next unless new_floor.is_ceiling

      sum_ceiling_area += new_floor.area
    end
    new_bldg.floors.each do |new_floor|
      next unless new_floor.is_ceiling

      new_floor.area = 1200.0 * new_floor.area / sum_ceiling_area
    end
  end

  def self.set_enclosure_floors_reference(orig_bldg, new_bldg)
    floor_ufactor = get_reference_floor_ufactor()

    orig_bldg.floors.each do |orig_floor|
      next unless orig_floor.is_floor

      # Insulated for, e.g., floors between conditioned space and crawlspace/unconditioned basement.
      # Uninsulated for, e.g., floors between conditioned space and conditioned basement.
      if orig_floor.is_thermal_boundary
        insulation_assembly_r_value = (1.0 / floor_ufactor).round(3)
      else
        insulation_assembly_r_value = [orig_floor.insulation_assembly_r_value, 3.1].min # uninsulated
      end

      new_bldg.floors.add(id: orig_floor.id,
                          exterior_adjacent_to: orig_floor.exterior_adjacent_to.gsub('unvented', 'vented'),
                          interior_adjacent_to: orig_floor.interior_adjacent_to.gsub('unvented', 'vented'),
                          floor_or_ceiling: orig_floor.floor_or_ceiling,
                          floor_type: HPXML::FloorTypeWoodFrame,
                          area: orig_floor.area,
                          insulation_id: orig_floor.insulation_id,
                          insulation_assembly_r_value: insulation_assembly_r_value)
    end
  end

  def self.set_enclosure_floors_rated(orig_bldg, new_bldg)
    # Preserve all floors
    orig_bldg.floors.each do |orig_floor|
      next unless orig_floor.is_floor

      new_bldg.floors.add(id: orig_floor.id,
                          exterior_adjacent_to: orig_floor.exterior_adjacent_to,
                          interior_adjacent_to: orig_floor.interior_adjacent_to,
                          floor_or_ceiling: orig_floor.floor_or_ceiling,
                          floor_type: orig_floor.floor_type,
                          area: orig_floor.area,
                          insulation_id: orig_floor.insulation_id,
                          insulation_assembly_r_value: orig_floor.insulation_assembly_r_value)
    end
  end

  def self.set_enclosure_floors_iad(new_bldg)
    floor_ufactor = get_reference_floor_ufactor()

    # Add crawlspace floor
    new_bldg.floors.add(id: 'FloorAboveCrawlspace',
                        interior_adjacent_to: HPXML::LocationConditionedSpace,
                        exterior_adjacent_to: HPXML::LocationCrawlspaceVented,
                        floor_type: HPXML::FloorTypeWoodFrame,
                        area: 1200,
                        insulation_assembly_r_value: (1.0 / floor_ufactor).round(3))
  end

  def self.set_enclosure_slabs_reference(orig_bldg, new_bldg)
    slab_perim_rvalue, slab_perim_depth = get_reference_slab_perimeter_rvalue_depth()
    slab_under_rvalue, slab_under_width = get_reference_slab_under_rvalue_width()

    orig_bldg.slabs.each do |orig_slab|
      if orig_slab.interior_adjacent_to == HPXML::LocationConditionedSpace
        # Insulated for slabs below conditioned space.
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
      if [HPXML::LocationConditionedSpace, HPXML::LocationBasementConditioned].include? orig_slab.interior_adjacent_to
        carpet_fraction = 0.8
        carpet_r_value = 2.0
      else
        carpet_fraction = 0.0
        carpet_r_value = 0.0
      end
      new_bldg.slabs.add(id: orig_slab.id,
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

  def self.set_enclosure_slabs_rated(orig_bldg, new_bldg)
    # Preserve all slabs
    orig_bldg.slabs.each do |orig_slab|
      new_bldg.slabs.add(id: orig_slab.id,
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
                         gap_insulation_r_value: orig_slab.gap_insulation_r_value,
                         under_slab_insulation_id: orig_slab.under_slab_insulation_id,
                         under_slab_insulation_r_value: orig_slab.under_slab_insulation_r_value)
    end
  end

  def self.set_enclosure_slabs_iad(new_bldg)
    # Add crawlspace slab
    new_bldg.slabs.add(id: 'Slab',
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

  def self.set_enclosure_windows_reference(orig_bldg, new_bldg)
    # Table 4.2.2(1) - Glazing
    ufactor, shgc = get_reference_glazing_ufactor_shgc()

    ag_bndry_wall_area, bg_bndry_wall_area = orig_bldg.thermal_boundary_wall_areas()
    common_wall_area = orig_bldg.common_wall_area()

    fa = ag_bndry_wall_area / (ag_bndry_wall_area + 0.5 * bg_bndry_wall_area)
    f = 1.0 - 0.44 * common_wall_area / (ag_bndry_wall_area + common_wall_area)

    # Interior shading equation is based on light curtains, 50% coverage
    shade_summer, shade_winter = Defaults.get_window_interior_shading_factors(
      HPXML::InteriorShadingTypeLightCurtains, shgc, 0.5, 0.5, nil, nil, @eri_version
    )

    fraction_operable = Defaults.get_fraction_of_windows_operable() # Default natural ventilation
    if [HPXML::ResidentialTypeApartment, HPXML::ResidentialTypeSFA].include? @bldg_type
      if (orig_bldg.fraction_of_windows_operable() <= 0) && (Constants::ERIVersions.index(@eri_version) >= Constants::ERIVersions.index('2019'))
        # Disable natural ventilation
        fraction_operable = 0.0
      end
    end

    # Create equally distributed windows
    for orientation, azimuth in { 'North' => 0, 'South' => 180, 'East' => 90, 'West' => 270 }
      new_bldg.windows.add(id: "WindowArea#{orientation}",
                           area: (0.18 * @cfa * fa * f * 0.25).round(2),
                           azimuth: azimuth,
                           ufactor: ufactor,
                           shgc: shgc,
                           interior_shading_factor_summer: shade_summer,
                           interior_shading_factor_winter: shade_winter,
                           fraction_operable: fraction_operable,
                           performance_class: HPXML::WindowClassResidential,
                           attached_to_wall_idref: new_bldg.walls[0].id)
    end
  end

  def self.set_enclosure_windows_rated(orig_bldg, new_bldg)
    # Preserve all windows
    orig_bldg.windows.each do |orig_window|
      # Interior shading equation is based on light curtains, 50% coverage
      shade_summer, shade_winter = Defaults.get_window_interior_shading_factors(
        HPXML::InteriorShadingTypeLightCurtains, orig_window.shgc, 0.5, 0.5, nil, nil, @eri_version
      )
      new_bldg.windows.add(id: orig_window.id,
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
                           performance_class: orig_window.performance_class.nil? ? HPXML::WindowClassResidential : orig_window.performance_class,
                           attached_to_wall_idref: orig_window.attached_to_wall_idref)
    end
  end

  def self.set_enclosure_windows_iad(orig_bldg, new_bldg)
    ext_thermal_bndry_windows = orig_bldg.windows.select { |window| window.is_exterior_thermal_boundary }
    ref_ufactor, ref_shgc = get_reference_glazing_ufactor_shgc()
    avg_ufactor = calc_area_weighted_avg(ext_thermal_bndry_windows, :ufactor, backup_value: ref_ufactor)
    avg_shgc = calc_area_weighted_avg(ext_thermal_bndry_windows, :shgc, backup_value: ref_shgc)

    # Interior shading equation is based on light curtains, 50% coverage
    shade_summer, shade_winter = Defaults.get_window_interior_shading_factors(
      HPXML::InteriorShadingTypeLightCurtains, ref_shgc, 0.5, 0.5, nil, nil, @eri_version
    )

    # Default natural ventilation
    fraction_operable = Defaults.get_fraction_of_windows_operable()

    # Create equally distributed windows
    for orientation, azimuth in { 'North' => 0, 'South' => 180, 'East' => 90, 'West' => 270 }
      new_bldg.windows.add(id: "WindowArea#{orientation}",
                           area: 0.18 * @cfa * 0.25,
                           azimuth: azimuth,
                           ufactor: avg_ufactor,
                           shgc: avg_shgc,
                           interior_shading_factor_summer: shade_summer,
                           interior_shading_factor_winter: shade_winter,
                           fraction_operable: fraction_operable,
                           performance_class: HPXML::WindowClassResidential,
                           attached_to_wall_idref: new_bldg.walls[0].id)
    end
  end

  def self.set_enclosure_skylights_reference(orig_bldg, new_bldg)
    # nop; No skylights
  end

  def self.set_enclosure_skylights_rated(orig_bldg, new_bldg)
    # Preserve all skylights
    orig_bldg.skylights.each do |orig_skylight|
      new_bldg.skylights.add(id: orig_skylight.id,
                             area: orig_skylight.area,
                             azimuth: orig_skylight.azimuth,
                             ufactor: orig_skylight.ufactor,
                             shgc: orig_skylight.shgc,
                             attached_to_roof_idref: orig_skylight.attached_to_roof_idref,
                             attached_to_floor_idref: orig_skylight.attached_to_floor_idref,
                             curb_area: orig_skylight.curb_area,
                             curb_assembly_r_value: orig_skylight.curb_assembly_r_value,
                             shaft_area: orig_skylight.shaft_area,
                             shaft_assembly_r_value: orig_skylight.shaft_assembly_r_value)
    end
  end

  def self.set_enclosure_skylights_iad(orig_bldg, new_bldg)
    set_enclosure_skylights_rated(orig_bldg, new_bldg)

    # Since the IAD roof/ceiling area is scaled down but skylight area is maintained,
    # it's possible that skylights no longer fit on the roof. To resolve this,
    # scale down skylight area to fit as needed.
    (new_bldg.roofs + new_bldg.floors).each do |new_roof_or_ceiling|
      new_skylight_area = new_roof_or_ceiling.skylights.map { |skylight| skylight.area }.sum(0)
      next unless new_skylight_area > new_roof_or_ceiling.area

      scaling_factor = 0.99 * new_roof_or_ceiling.area / new_skylight_area

      new_roof_or_ceiling.skylights.each do |new_skylight|
        new_skylight.area *= scaling_factor
        if not new_skylight.curb_area.nil?
          new_skylight.curb_area *= scaling_factor
        end
        if not new_skylight.shaft_area.nil?
          new_skylight.shaft_area *= scaling_factor
        end
      end
    end
  end

  def self.set_enclosure_doors_reference(orig_bldg, new_bldg)
    ufactor, _shgc = get_reference_glazing_ufactor_shgc()
    exterior_area, interior_area = get_reference_door_area(orig_bldg)

    # Create new door
    if @is_southern_hemisphere
      azimuth = 180
    else
      azimuth = 0
    end
    if exterior_area > 0.1
      new_bldg.doors.add(id: 'ExteriorDoorArea',
                         attached_to_wall_idref: new_bldg.walls.find { |w| w.is_exterior_thermal_boundary }.id,
                         area: exterior_area,
                         azimuth: azimuth,
                         r_value: (1.0 / ufactor).round(3))
    end
    if interior_area > 0.1
      new_bldg.doors.add(id: 'InteriorDoorArea',
                         attached_to_wall_idref: new_bldg.walls.find { |w| w.exterior_adjacent_to == HPXML::LocationOtherHousingUnit }.id,
                         area: interior_area,
                         azimuth: azimuth,
                         r_value: (1.0 / ufactor).round(3))
    end
  end

  def self.set_enclosure_doors_rated(orig_bldg, new_bldg)
    # Table 4.2.2(1) - Doors
    orig_bldg.doors.each do |orig_door|
      new_bldg.doors.add(id: orig_door.id,
                         attached_to_wall_idref: orig_door.attached_to_wall_idref,
                         area: orig_door.area,
                         azimuth: orig_door.azimuth,
                         r_value: orig_door.r_value)
    end
  end

  def self.set_enclosure_doors_iad(orig_bldg, new_bldg)
    # Table 4.3.1(1) Configuration of Index Adjustment Design - Doors
    ext_thermal_bndry_doors = orig_bldg.doors.select { |door| door.is_exterior_thermal_boundary }
    ref_ufactor, _ref_shgc = get_reference_glazing_ufactor_shgc()
    avg_r_value = calc_area_weighted_avg(ext_thermal_bndry_doors, :r_value, use_inverse: true, backup_value: 1.0 / ref_ufactor)
    exterior_area, interior_area = get_reference_door_area(orig_bldg)

    # Create new door (since it's impossible to preserve the Rated Home's door orientation)
    if @is_southern_hemisphere
      azimuth = 180
    else
      azimuth = 0
    end
    if exterior_area + interior_area > 0.1
      new_bldg.doors.add(id: 'DoorArea',
                         attached_to_wall_idref: new_bldg.walls.find { |w| w.is_exterior_thermal_boundary }.id,
                         area: exterior_area + interior_area,
                         azimuth: azimuth,
                         r_value: avg_r_value.round(3))
    end
  end

  def self.set_systems_hvac_reference(orig_bldg, new_bldg, is_all_electric: false)
    # Table 4.2.2(1) - Heating systems
    # Table 4.2.2(1) - Cooling systems

    has_fuel = orig_bldg.has_fuel_access()
    sum_frac_cool_load = orig_bldg.total_fraction_cool_load_served
    sum_frac_heat_load = orig_bldg.total_fraction_heat_load_served

    hvac_configurations = get_hvac_configurations(orig_bldg)

    hvac_configurations.each do |hvac_configuration|
      heating_system = hvac_configuration[:heating_system]
      cooling_system = hvac_configuration[:cooling_system]
      heat_pump = hvac_configuration[:heat_pump]

      created_hp = false
      if not heating_system.nil?
        if heating_system.is_a? HPXML::HeatingSystem
          heating_fuel = heating_system.heating_system_fuel
          fraction_heat_load_served = heating_system.fraction_heat_load_served
          heating_system_type = heating_system.heating_system_type
        elsif heating_system.is_a? HPXML::CoolingSystem # Cooling system w/ integrated heating (e.g., Room AC w/ electric resistance heating)
          heating_fuel = cooling_system.integrated_heating_system_fuel
          fraction_heat_load_served = cooling_system.integrated_heating_system_fraction_heat_load_served
          heating_system_type = cooling_system.cooling_system_type
        elsif heating_system.is_a? HPXML::HeatPump
          heating_fuel = heating_system.heat_pump_fuel
          fraction_heat_load_served = heating_system.fraction_heat_load_served
          heating_system_type = heating_system.heat_pump_type
        end
        if (heating_fuel == HPXML::FuelTypeElectricity) || is_all_electric
          if not cooling_system.nil?
            fraction_cool_load_served = cooling_system.fraction_cool_load_served
          else
            fraction_cool_load_served = 0.0
          end
          created_hp = true
          add_reference_heat_pump(orig_bldg, new_bldg, fraction_heat_load_served, fraction_cool_load_served, orig_htg_system: heating_system, orig_clg_system: cooling_system)
        elsif heating_system_type == HPXML::HVACTypeBoiler
          if heating_system.distribution_system.hydronic_type == HPXML::HydronicTypeWaterLoop
            # Maintain same fractions of heating load between boiler and heat pump
            # 301-2019 Section 4.4.7.2.1
            orig_wlhp = orig_bldg.heat_pumps.find { |hp| hp.heat_pump_type == HPXML::HVACTypeHeatPumpWaterLoopToAir }
            hp_fraction_heat_load_served = fraction_heat_load_served * (1.0 / orig_wlhp.heating_efficiency_cop)
            add_reference_heat_pump(orig_bldg, new_bldg, hp_fraction_heat_load_served, 0.0, orig_htg_system: orig_wlhp)
            fraction_heat_load_served *= (1.0 - 1.0 / orig_wlhp.heating_efficiency_cop)
          end
          add_reference_gas_boiler(orig_bldg, new_bldg, fraction_heat_load_served, orig_system: heating_system)
        else
          add_reference_gas_furnace(orig_bldg, new_bldg, fraction_heat_load_served, orig_system: heating_system)
        end
      end

      if not cooling_system.nil?
        if created_hp
          # Already created HP above
        else
          add_reference_air_conditioner(orig_bldg, new_bldg, cooling_system.fraction_cool_load_served, orig_system: cooling_system)
        end
      end

      if not heat_pump.nil?
        if heat_pump.heat_pump_type == HPXML::HVACTypeHeatPumpWaterLoopToAir
          # Already handled
        else
          add_reference_heat_pump(orig_bldg, new_bldg, heat_pump.fraction_heat_load_served, heat_pump.fraction_cool_load_served, orig_htg_system: heat_pump, orig_clg_system: heat_pump, is_all_electric: is_all_electric)
        end
      end
    end

    if has_fuel && (sum_frac_heat_load < 0.99) && (not is_all_electric) # Accommodate systems that don't quite sum to 1 due to rounding
      add_reference_gas_furnace(orig_bldg, new_bldg, (1.0 - sum_frac_heat_load).round(3))
    end
    if (sum_frac_cool_load < 0.99) # Accommodate systems that don't quite sum to 1 due to rounding
      add_reference_air_conditioner(orig_bldg, new_bldg, (1.0 - sum_frac_cool_load).round(3))
    end
    if ((not has_fuel) || is_all_electric) && (sum_frac_heat_load < 0.99) # Accommodate systems that don't quite sum to 1 due to rounding
      add_reference_heat_pump(orig_bldg, new_bldg, (1.0 - sum_frac_heat_load).round(3), 0.0)
    end

    # Table 303.4.1(1) - Thermostat
    control_type = HPXML::HVACControlTypeManual
    htg_weekday_setpoints, htg_weekend_setpoints = Defaults.get_heating_setpoint(control_type, @eri_version)
    clg_weekday_setpoints, clg_weekend_setpoints = Defaults.get_cooling_setpoint(control_type, @eri_version)
    new_bldg.hvac_controls.add(id: 'HVACControl',
                               control_type: control_type,
                               weekday_heating_setpoints: htg_weekday_setpoints,
                               weekend_heating_setpoints: htg_weekend_setpoints,
                               weekday_cooling_setpoints: clg_weekday_setpoints,
                               weekend_cooling_setpoints: clg_weekend_setpoints)

    # Distribution system
    add_reference_distribution_system(new_bldg)
  end

  def self.set_systems_hvac_rated(orig_bldg, new_bldg)
    # Table 4.2.2(1) - Heating systems
    # Table 4.2.2(1) - Cooling systems

    has_fuel = orig_bldg.has_fuel_access()
    sum_frac_cool_load = orig_bldg.total_fraction_cool_load_served
    sum_frac_heat_load = orig_bldg.total_fraction_heat_load_served

    # Retain heating system(s)
    orig_bldg.heating_systems.each do |orig_heating_system|
      if Constants::ERIVersions.index(@eri_version) >= Constants::ERIVersions.index('2019AB')
        fan_watts_per_cfm = orig_heating_system.fan_watts_per_cfm
        airflow_defect_ratio = orig_heating_system.airflow_defect_ratio
      end
      new_bldg.heating_systems.add(id: orig_heating_system.id,
                                   is_shared_system: orig_heating_system.is_shared_system,
                                   number_of_units_served: orig_heating_system.number_of_units_served,
                                   distribution_system_idref: orig_heating_system.distribution_system_idref,
                                   heating_system_type: orig_heating_system.heating_system_type,
                                   heating_system_fuel: orig_heating_system.heating_system_fuel,
                                   heating_capacity: orig_heating_system.heating_capacity,
                                   heating_efficiency_afue: orig_heating_system.heating_efficiency_afue,
                                   heating_efficiency_percent: orig_heating_system.heating_efficiency_percent,
                                   fraction_heat_load_served: orig_heating_system.fraction_heat_load_served,
                                   shared_loop_watts: orig_heating_system.shared_loop_watts,
                                   fan_coil_watts: orig_heating_system.fan_coil_watts,
                                   fan_motor_type: orig_heating_system.fan_motor_type,
                                   fan_watts_per_cfm: fan_watts_per_cfm,
                                   fan_watts: orig_heating_system.fan_watts,
                                   heating_design_airflow_cfm: orig_heating_system.heating_design_airflow_cfm,
                                   airflow_defect_ratio: airflow_defect_ratio,
                                   htg_seed_id: orig_heating_system.htg_seed_id.nil? ? orig_heating_system.id : orig_heating_system.htg_seed_id)
    end
    # Add reference heating system for residual load
    if has_fuel && (sum_frac_heat_load < 0.99) # Accommodate systems that don't quite sum to 1 due to rounding
      add_reference_gas_furnace(orig_bldg, new_bldg, (1.0 - sum_frac_heat_load).round(3))
    end

    # Retain cooling system(s)
    orig_bldg.cooling_systems.each do |orig_cooling_system|
      if Constants::ERIVersions.index(@eri_version) >= Constants::ERIVersions.index('2019AB')
        fan_watts_per_cfm = orig_cooling_system.fan_watts_per_cfm
        airflow_defect_ratio = orig_cooling_system.airflow_defect_ratio
        charge_defect_ratio = orig_cooling_system.charge_defect_ratio
      end
      if orig_cooling_system.has_integrated_heating
        htg_seed_id = orig_cooling_system.htg_seed_id.nil? ? orig_cooling_system.id : orig_cooling_system.htg_seed_id
      end
      new_bldg.cooling_systems.add(id: orig_cooling_system.id,
                                   is_shared_system: orig_cooling_system.is_shared_system,
                                   number_of_units_served: orig_cooling_system.number_of_units_served,
                                   distribution_system_idref: orig_cooling_system.distribution_system_idref,
                                   cooling_system_type: orig_cooling_system.cooling_system_type,
                                   cooling_system_fuel: orig_cooling_system.cooling_system_fuel,
                                   compressor_type: orig_cooling_system.compressor_type,
                                   cooling_capacity: orig_cooling_system.cooling_capacity,
                                   fraction_cool_load_served: orig_cooling_system.fraction_cool_load_served,
                                   cooling_efficiency_seer: orig_cooling_system.cooling_efficiency_seer,
                                   cooling_efficiency_seer2: orig_cooling_system.cooling_efficiency_seer2,
                                   cooling_efficiency_eer: orig_cooling_system.cooling_efficiency_eer,
                                   cooling_efficiency_eer2: orig_cooling_system.cooling_efficiency_eer2,
                                   cooling_efficiency_ceer: orig_cooling_system.cooling_efficiency_ceer,
                                   cooling_efficiency_kw_per_ton: orig_cooling_system.cooling_efficiency_kw_per_ton,
                                   shared_loop_watts: orig_cooling_system.shared_loop_watts,
                                   fan_coil_watts: orig_cooling_system.fan_coil_watts,
                                   fan_motor_type: orig_cooling_system.fan_motor_type,
                                   fan_watts_per_cfm: fan_watts_per_cfm,
                                   cooling_design_airflow_cfm: orig_cooling_system.cooling_design_airflow_cfm,
                                   airflow_defect_ratio: airflow_defect_ratio,
                                   charge_defect_ratio: charge_defect_ratio,
                                   clg_seed_id: orig_cooling_system.clg_seed_id.nil? ? orig_cooling_system.id : orig_cooling_system.clg_seed_id,
                                   integrated_heating_system_fuel: orig_cooling_system.integrated_heating_system_fuel,
                                   integrated_heating_system_capacity: orig_cooling_system.integrated_heating_system_capacity,
                                   integrated_heating_system_efficiency_percent: orig_cooling_system.integrated_heating_system_efficiency_percent,
                                   integrated_heating_system_fraction_heat_load_served: orig_cooling_system.integrated_heating_system_fraction_heat_load_served,
                                   equipment_type: orig_cooling_system.equipment_type,
                                   htg_seed_id: htg_seed_id)
    end
    # Add reference cooling system for residual load
    if (sum_frac_cool_load < 0.99) # Accommodate systems that don't quite sum to 1 due to rounding
      add_reference_air_conditioner(orig_bldg, new_bldg, (1.0 - sum_frac_cool_load).round(3))
    end

    # Retain heat pump(s)
    orig_bldg.heat_pumps.each do |orig_heat_pump|
      if Constants::ERIVersions.index(@eri_version) >= Constants::ERIVersions.index('2019AB')
        fan_watts_per_cfm = orig_heat_pump.fan_watts_per_cfm
        airflow_defect_ratio = orig_heat_pump.airflow_defect_ratio
        charge_defect_ratio = orig_heat_pump.charge_defect_ratio
      end
      backup_type = orig_heat_pump.backup_type
      backup_heating_fuel = orig_heat_pump.backup_heating_fuel
      backup_heating_efficiency_percent = orig_heat_pump.backup_heating_efficiency_percent
      backup_heating_efficiency_afue = orig_heat_pump.backup_heating_efficiency_afue
      backup_heating_capacity = orig_heat_pump.backup_heating_capacity
      if orig_heat_pump.backup_heating_capacity.to_f == 0 && orig_heat_pump.heat_pump_type != HPXML::HVACTypeHeatPumpWaterLoopToAir
        # Force backup heating to prevent unmet loads
        backup_type = HPXML::HeatPumpBackupTypeIntegrated
        backup_heating_fuel = HPXML::FuelTypeElectricity
        backup_heating_efficiency_percent = 1.0
        backup_heating_capacity = 1 # Non-zero value will allow backup heating capacity to be increased as needed
      end
      if [HPXML::HVACTypeHeatPumpAirToAir,
          HPXML::HVACTypeHeatPumpMiniSplit].include? orig_heat_pump.heat_pump_type
        pan_heater_control_type = HPXML::HVACPanHeaterControlTypeContinuous
      end
      # FUTURE: Eventually require GSHP compressor type when OS-HPXML modeling reflects it
      compressor_type = orig_heat_pump.compressor_type
      if orig_heat_pump.heat_pump_type == HPXML::HVACTypeHeatPumpGroundToAir && orig_heat_pump.compressor_type.nil?
        compressor_type = HPXML::HVACCompressorTypeSingleStage
      end
      compressor_lockout_temp = get_hp_compressor_lockout_temp(orig_heat_pump.heat_pump_type,
                                                               backup_heating_fuel,
                                                               compressor_type,
                                                               orig_heat_pump.compressor_lockout_temp)
      backup_heating_lockout_temp = get_hp_backup_heating_lockout_temp(orig_heat_pump.heat_pump_type)
      backup_heating_active_during_defrost = get_hp_backup_heating_active_during_defrost(orig_heat_pump.heat_pump_type, orig_heat_pump.backup_type)
      new_bldg.heat_pumps.add(id: orig_heat_pump.id,
                              is_shared_system: orig_heat_pump.is_shared_system,
                              number_of_units_served: orig_heat_pump.number_of_units_served,
                              distribution_system_idref: orig_heat_pump.distribution_system_idref,
                              heat_pump_type: orig_heat_pump.heat_pump_type,
                              heat_pump_fuel: orig_heat_pump.heat_pump_fuel,
                              compressor_type: compressor_type,
                              compressor_lockout_temp: compressor_lockout_temp,
                              heating_capacity: orig_heat_pump.heating_capacity,
                              heating_capacity_17F: orig_heat_pump.heating_capacity_17F,
                              cooling_capacity: orig_heat_pump.cooling_capacity,
                              backup_type: backup_type,
                              backup_heating_lockout_temp: backup_heating_lockout_temp,
                              backup_heating_fuel: backup_heating_fuel,
                              backup_heating_capacity: backup_heating_capacity,
                              backup_heating_efficiency_percent: backup_heating_efficiency_percent,
                              backup_heating_efficiency_afue: backup_heating_efficiency_afue,
                              backup_heating_active_during_defrost: backup_heating_active_during_defrost,
                              fraction_heat_load_served: orig_heat_pump.fraction_heat_load_served,
                              fraction_cool_load_served: orig_heat_pump.fraction_cool_load_served,
                              cooling_efficiency_seer: orig_heat_pump.cooling_efficiency_seer,
                              cooling_efficiency_seer2: orig_heat_pump.cooling_efficiency_seer2,
                              cooling_efficiency_eer: orig_heat_pump.cooling_efficiency_eer,
                              cooling_efficiency_eer2: orig_heat_pump.cooling_efficiency_eer2,
                              cooling_efficiency_ceer: orig_heat_pump.cooling_efficiency_ceer,
                              heating_efficiency_hspf: orig_heat_pump.heating_efficiency_hspf,
                              heating_efficiency_hspf2: orig_heat_pump.heating_efficiency_hspf2,
                              heating_efficiency_cop: orig_heat_pump.heating_efficiency_cop,
                              shared_loop_watts: orig_heat_pump.shared_loop_watts,
                              pump_watts_per_ton: orig_heat_pump.pump_watts_per_ton,
                              fan_motor_type: orig_heat_pump.fan_motor_type,
                              fan_watts_per_cfm: fan_watts_per_cfm,
                              heating_design_airflow_cfm: orig_heat_pump.heating_design_airflow_cfm,
                              cooling_design_airflow_cfm: orig_heat_pump.cooling_design_airflow_cfm,
                              airflow_defect_ratio: airflow_defect_ratio,
                              charge_defect_ratio: charge_defect_ratio,
                              pan_heater_control_type: pan_heater_control_type,
                              equipment_type: orig_heat_pump.equipment_type,
                              htg_seed_id: orig_heat_pump.htg_seed_id.nil? ? orig_heat_pump.id : orig_heat_pump.htg_seed_id,
                              clg_seed_id: orig_heat_pump.clg_seed_id.nil? ? orig_heat_pump.id : orig_heat_pump.clg_seed_id)
    end
    # Add reference heat pump for residual load
    if (not has_fuel) && (sum_frac_heat_load < 0.99) # Accommodate systems that don't quite sum to 1 due to rounding
      add_reference_heat_pump(orig_bldg, new_bldg, (1.0 - sum_frac_heat_load).round(3), 0.0)
    end

    # Table 303.4.1(1) - Thermostat
    if orig_bldg.hvac_controls.size > 0
      hvac_control = orig_bldg.hvac_controls[0]
      control_type = hvac_control.control_type
      hvac_control_id = hvac_control.id
    else
      control_type = HPXML::HVACControlTypeManual
      hvac_control_id = 'HVACControl'
    end
    htg_weekday_setpoints, htg_weekend_setpoints = Defaults.get_heating_setpoint(control_type, @eri_version)
    clg_weekday_setpoints, clg_weekend_setpoints = Defaults.get_cooling_setpoint(control_type, @eri_version)
    new_bldg.hvac_controls.add(id: hvac_control_id,
                               control_type: control_type,
                               weekday_heating_setpoints: htg_weekday_setpoints,
                               weekend_heating_setpoints: htg_weekend_setpoints,
                               weekday_cooling_setpoints: clg_weekday_setpoints,
                               weekend_cooling_setpoints: clg_weekend_setpoints)

    # Table 4.2.2(1) - Thermal distribution systems
    orig_bldg.hvac_distributions.each do |orig_hvac_distribution|
      new_bldg.hvac_distributions.add(id: orig_hvac_distribution.id,
                                      distribution_system_type: orig_hvac_distribution.distribution_system_type,
                                      conditioned_floor_area_served: orig_hvac_distribution.conditioned_floor_area_served,
                                      number_of_return_registers: orig_hvac_distribution.number_of_return_registers,
                                      hydronic_type: orig_hvac_distribution.hydronic_type,
                                      air_type: orig_hvac_distribution.air_type,
                                      annual_heating_dse: orig_hvac_distribution.annual_heating_dse,
                                      annual_cooling_dse: orig_hvac_distribution.annual_cooling_dse)

      new_hvac_distribution = new_bldg.hvac_distributions[-1]

      next unless orig_hvac_distribution.distribution_system_type == HPXML::HVACDistributionTypeAir

      orig_hvac_distribution.duct_leakage_measurements.each do |orig_leakage_measurement|
        # Duct leakage to outside
        new_hvac_distribution.duct_leakage_measurements.add(duct_type: orig_leakage_measurement.duct_type,
                                                            duct_leakage_units: orig_leakage_measurement.duct_leakage_units,
                                                            duct_leakage_value: orig_leakage_measurement.duct_leakage_value,
                                                            duct_leakage_total_or_to_outside: orig_leakage_measurement.duct_leakage_total_or_to_outside)
      end

      # Ducts
      orig_hvac_distribution.ducts.each do |orig_duct|
        new_hvac_distribution.ducts.add(id: orig_duct.id,
                                        duct_type: orig_duct.duct_type,
                                        duct_insulation_r_value: orig_duct.duct_insulation_r_value,
                                        duct_location: orig_duct.duct_location,
                                        duct_surface_area: orig_duct.duct_surface_area,
                                        duct_fraction_area: orig_duct.duct_fraction_area,
                                        duct_buried_insulation_level: orig_duct.duct_buried_insulation_level)
      end
    end

    # Add DSE distribution for these systems
    add_reference_distribution_system(new_bldg)
  end

  def self.set_systems_hvac_iad(orig_bldg, new_bldg)
    # Table 4.3.1(1) Configuration of Index Adjustment Design - Heating systems
    # Table 4.3.1(1) Configuration of Index Adjustment Design - Cooling systems
    # Table 4.3.1(1) Configuration of Index Adjustment Design - Thermostat

    # Note: 301-2019 Addendum B says Grade I, but it was changed to Grade III in
    # RESNET 55i.
    set_systems_hvac_reference(orig_bldg, new_bldg)

    # Change DSE to 1.0
    new_bldg.hvac_distributions.each do |new_hvac_distribution|
      new_hvac_distribution.annual_heating_dse = 1.0
      new_hvac_distribution.annual_cooling_dse = 1.0
    end
  end

  def self.set_systems_mechanical_ventilation_reference(orig_bldg, new_bldg, iecc_version = nil)
    # Table 4.2.2(1) - Whole-House Mechanical ventilation

    # Calculate fan cfm for airflow rate using Reference Home infiltration
    # https://www.resnet.us/wp-content/uploads/No.-301-2014-01-Table-4.2.21-Reference-Home-Air-Exchange-Rate.pdf
    ref_sla = 0.00036
    if ['2018', '2021'].include? iecc_version
      # IECC exception for ERI reference design ventilation rate
      q_fan_airflow = (0.01 * @cfa) + (7.5 * (@nbeds + 1))
    else
      q_tot = Airflow.get_mech_vent_qtot_cfm(@nbeds, @cfa)
      infil_height = new_bldg.air_infiltration_measurements[0].infiltration_height
      q_fan_airflow = calc_mech_vent_qfan(q_tot, ref_sla, true, 0.0, infil_height) # cfm for airflow
    end

    mech_vent_fans = orig_bldg.ventilation_fans.select { |f| f.used_for_whole_building_ventilation }

    if mech_vent_fans.empty?
      # Airflow only
      new_bldg.ventilation_fans.add(id: 'MechanicalVentilation',
                                    fan_type: HPXML::MechVentTypeBalanced, # Per RESNET 55i
                                    tested_flow_rate: q_fan_airflow.round(2),
                                    hours_in_operation: 24,
                                    fan_power: 0.0,
                                    used_for_whole_building_ventilation: true,
                                    is_shared_system: false)
    else

      # Calculate weighted-average fan W/cfm
      q_fans, q_fan_bal_remain = calc_rated_home_q_fans_by_system(orig_bldg, mech_vent_fans)
      sum_fan_w = 0.0
      sum_fan_cfm = 0.0
      q_fans.each do |fan_id, flow_rate|
        orig_vent_fan = mech_vent_fans.find { |f| f.id == fan_id }
        if [HPXML::MechVentTypeERV, HPXML::MechVentTypeHRV].include? orig_vent_fan.fan_type
          sum_fan_w += (1.00 * flow_rate)
        elsif orig_vent_fan.is_balanced
          sum_fan_w += (0.70 * flow_rate)
        else
          sum_fan_w += (0.35 * flow_rate)
        end
        sum_fan_cfm += flow_rate
      end
      sum_fan_w += 0.70 * q_fan_bal_remain
      sum_fan_cfm += q_fan_bal_remain

      # Calculate fan power
      is_balanced, frac_imbal = get_mech_vent_imbal_properties(orig_bldg.ventilation_fans)
      q_fan_power = calc_rated_home_qfan(orig_bldg, is_balanced, frac_imbal) # cfm for energy use calculation; Use Rated Home fan type
      if sum_fan_cfm > 0
        fan_power_w = sum_fan_w / sum_fan_cfm * q_fan_power
      else
        fan_power_w = 0.0
      end

      # Airflow and fan power
      new_bldg.ventilation_fans.add(id: 'MechanicalVentilation',
                                    fan_type: HPXML::MechVentTypeBalanced,
                                    tested_flow_rate: q_fan_airflow.round(2),
                                    hours_in_operation: 24,
                                    fan_power: fan_power_w.round(3),
                                    used_for_whole_building_ventilation: true,
                                    is_shared_system: false)
    end
  end

  def self.set_systems_mechanical_ventilation_rated(orig_bldg, new_bldg)
    mech_vent_fans = orig_bldg.ventilation_fans.select { |f|
      f.used_for_whole_building_ventilation &&
        (f.is_cfis_supplemental_fan || f.hours_in_operation > 0) &&
        (f.flow_rate_not_tested || f.flow_rate > 0)
    }

    q_fans, q_fan_bal_remain = calc_rated_home_q_fans_by_system(orig_bldg, mech_vent_fans)

    # Table 4.2.2(1) - Whole-House Mechanical ventilation
    mech_vent_fans.each do |orig_vent_fan|
      hours_in_operation = orig_vent_fan.hours_in_operation

      # Calculate daily-average outdoor airflow rate for fan
      if not orig_vent_fan.flow_rate_not_tested
        # Airflow measured; set to max of provided value and min Qfan requirement
        if orig_vent_fan.is_cfis_supplemental_fan
          average_oa_unit_flow_rate = [orig_vent_fan.oa_unit_flow_rate, q_fans[orig_vent_fan.id]].max
        else
          average_oa_unit_flow_rate = [orig_vent_fan.average_oa_unit_flow_rate, q_fans[orig_vent_fan.id]].max
          if average_oa_unit_flow_rate > orig_vent_fan.average_oa_unit_flow_rate
            # Increase hours in operation to try to meet requirement, per RESNET 55i
            hours_in_operation = [average_oa_unit_flow_rate / orig_vent_fan.average_oa_unit_flow_rate * hours_in_operation, 24.0].min
          end
        end
      else
        # Airflow not measured; set to min Qfan requirement
        average_oa_unit_flow_rate = q_fans[orig_vent_fan.id]
      end

      # Convert to actual fan flow rate(s)
      if not orig_vent_fan.is_shared_system
        # In-unit system
        if orig_vent_fan.is_cfis_supplemental_fan
          unit_flow_rate = average_oa_unit_flow_rate
        else
          unit_flow_rate = average_oa_unit_flow_rate * (24.0 / hours_in_operation)
        end
      else
        # Shared system
        unit_flow_rate = average_oa_unit_flow_rate * (24.0 / hours_in_operation) / (1 - orig_vent_fan.fraction_recirculation)
        if orig_vent_fan.flow_rate_not_tested
          system_flow_rate = orig_vent_fan.rated_flow_rate
        else
          unit_flow_rate_ratio = orig_vent_fan.in_unit_flow_rate / orig_vent_fan.flow_rate
          system_flow_rate = unit_flow_rate / unit_flow_rate_ratio
        end
      end

      # Calculate fan power
      if not orig_vent_fan.fan_power.nil?
        # Fan power provided
        fan_power = orig_vent_fan.fan_power
        if not orig_vent_fan.flow_rate_not_tested
          # Increase proportionally with airflow, per RESNET 55i
          fan_power = orig_vent_fan.fan_power * unit_flow_rate / orig_vent_fan.unit_flow_rate
        end
        if not orig_vent_fan.is_shared_system
          unit_fan_power = fan_power
        else
          system_fan_power = fan_power
        end
      else
        # Fan power defaulted
        if orig_vent_fan.fan_type != HPXML::MechVentTypeCFIS
          fan_w_per_cfm = Defaults.get_mech_vent_fan_efficiency(orig_vent_fan)
          if not orig_vent_fan.is_shared_system
            unit_fan_power = fan_w_per_cfm * unit_flow_rate
          else
            system_fan_power = fan_w_per_cfm * system_flow_rate
          end
        end
      end

      new_bldg.ventilation_fans.add(id: orig_vent_fan.id,
                                    is_shared_system: orig_vent_fan.is_shared_system,
                                    fan_type: orig_vent_fan.fan_type,
                                    hours_in_operation: hours_in_operation,
                                    total_recovery_efficiency: orig_vent_fan.total_recovery_efficiency,
                                    total_recovery_efficiency_adjusted: orig_vent_fan.total_recovery_efficiency_adjusted,
                                    sensible_recovery_efficiency: orig_vent_fan.sensible_recovery_efficiency,
                                    sensible_recovery_efficiency_adjusted: orig_vent_fan.sensible_recovery_efficiency_adjusted,
                                    distribution_system_idref: orig_vent_fan.distribution_system_idref,
                                    used_for_whole_building_ventilation: orig_vent_fan.used_for_whole_building_ventilation,
                                    cfis_addtl_runtime_operating_mode: orig_vent_fan.cfis_addtl_runtime_operating_mode,
                                    cfis_has_outdoor_air_control: orig_vent_fan.cfis_has_outdoor_air_control,
                                    cfis_control_type: orig_vent_fan.cfis_control_type,
                                    cfis_supplemental_fan_idref: orig_vent_fan.cfis_supplemental_fan_idref,
                                    cfis_supplemental_fan_runs_with_air_handler_fan: orig_vent_fan.cfis_supplemental_fan_runs_with_air_handler_fan)
      new_vent_fan = new_bldg.ventilation_fans[-1]
      if not orig_vent_fan.is_shared_system
        new_vent_fan.tested_flow_rate = unit_flow_rate.round(2)
        new_vent_fan.fan_power = unit_fan_power.round(3) unless unit_fan_power.nil?
      else
        new_vent_fan.rated_flow_rate = system_flow_rate.round(2)
        new_vent_fan.fan_power = system_fan_power.round(3)
        new_vent_fan.in_unit_flow_rate = unit_flow_rate.round(2)
        new_vent_fan.fraction_recirculation = orig_vent_fan.fraction_recirculation
        new_vent_fan.preheating_fuel = orig_vent_fan.preheating_fuel
        new_vent_fan.preheating_efficiency_cop = orig_vent_fan.preheating_efficiency_cop
        new_vent_fan.preheating_fraction_load_served = orig_vent_fan.preheating_fraction_load_served
        new_vent_fan.precooling_fuel = orig_vent_fan.precooling_fuel
        new_vent_fan.precooling_efficiency_cop = orig_vent_fan.precooling_efficiency_cop
        new_vent_fan.precooling_fraction_load_served = orig_vent_fan.precooling_fraction_load_served
      end
    end

    if q_fan_bal_remain > 0
      fan_power_w = 0.70 * q_fan_bal_remain
      new_bldg.ventilation_fans.add(id: 'MechanicalVentilation',
                                    fan_type: HPXML::MechVentTypeBalanced,
                                    tested_flow_rate: q_fan_bal_remain.round(2),
                                    hours_in_operation: 24,
                                    fan_power: fan_power_w.round(3),
                                    used_for_whole_building_ventilation: true,
                                    is_shared_system: false)
    end
  end

  def self.set_systems_mechanical_ventilation_iad(new_bldg)
    q_tot = Airflow.get_mech_vent_qtot_cfm(@nbeds, @cfa)

    # Calculate fan cfm
    infil_values = Airflow.get_values_from_air_infiltration_measurements(new_bldg, @weather)
    sla = Airflow.get_infiltration_SLA_from_ACH50(infil_values[:ach50], infil_values[:avg_ceil_height])
    q_fan = calc_mech_vent_qfan(q_tot, sla, true, 0.0, infil_values[:height])
    fan_power_w = 0.70 * q_fan

    new_bldg.ventilation_fans.add(id: 'MechanicalVentilation',
                                  fan_type: HPXML::MechVentTypeBalanced,
                                  tested_flow_rate: q_fan.round(2),
                                  hours_in_operation: 24,
                                  fan_power: fan_power_w.round(3),
                                  used_for_whole_building_ventilation: true,
                                  is_shared_system: false)
  end

  def self.set_systems_whole_house_fan_reference(orig_bldg, new_bldg)
    # nop
  end

  def self.set_systems_whole_house_fan_rated(orig_bldg, new_bldg)
    orig_bldg.ventilation_fans.each do |orig_vent_fan|
      next unless orig_vent_fan.used_for_seasonal_cooling_load_reduction

      new_bldg.ventilation_fans.add(id: orig_vent_fan.id,
                                    rated_flow_rate: orig_vent_fan.rated_flow_rate,
                                    fan_power: orig_vent_fan.fan_power,
                                    used_for_seasonal_cooling_load_reduction: orig_vent_fan.used_for_seasonal_cooling_load_reduction)
    end
  end

  def self.set_systems_whole_house_fan_iad(orig_bldg, new_bldg)
    # nop
  end

  def self.set_systems_water_heater_reference(orig_bldg, new_bldg, is_all_electric: false, in_conditioned_space: false)
    # Table 4.2.2(1) - Service water heating systems

    has_multiple_water_heaters = (orig_bldg.water_heating_systems.size > 1)

    orig_bldg.water_heating_systems.each do |orig_water_heater|
      tank_volume = orig_water_heater.tank_volume
      if [HPXML::WaterHeaterTypeCombiTankless, HPXML::WaterHeaterTypeTankless].include? orig_water_heater.water_heater_type
        tank_volume = 40.0
      elsif orig_water_heater.is_shared_system
        tank_volume = 40.0
      elsif has_multiple_water_heaters
        tank_volume = 40.0
      end

      # Set fuel type for combi systems
      fuel_type = orig_water_heater.fuel_type
      if is_all_electric
        fuel_type = HPXML::FuelTypeElectricity
      elsif has_multiple_water_heaters
        fuel_type = orig_bldg.predominant_water_heating_fuel()
      elsif [HPXML::WaterHeaterTypeCombiTankless, HPXML::WaterHeaterTypeCombiStorage].include? orig_water_heater.water_heater_type
        fuel_type = orig_water_heater.related_hvac_system.heating_system_fuel
      end

      energy_factor = get_reference_water_heater_ef(fuel_type, tank_volume)

      heating_capacity = Defaults.get_water_heater_heating_capacity(fuel_type, @nbeds, orig_bldg.water_heating_systems.size)

      # If 2022, reference WH is in default location, regardless of rated home location
      if Constants::ERIVersions.index(@eri_version) >= Constants::ERIVersions.index('2022')
        location = Defaults.get_water_heater_location(orig_bldg, @iecc_zone)
      else
        location = orig_water_heater.location
      end

      if in_conditioned_space
        # Hot water equipment shall be located in conditioned space.
        location = HPXML::LocationConditionedSpace
      end

      # New water heater
      new_bldg.water_heating_systems.add(id: orig_water_heater.id,
                                         is_shared_system: false,
                                         fuel_type: fuel_type,
                                         water_heater_type: HPXML::WaterHeaterTypeStorage,
                                         location: location.gsub('unvented', 'vented'),
                                         performance_adjustment: 1.0,
                                         tank_volume: tank_volume,
                                         fraction_dhw_load_served: 1.0,
                                         heating_capacity: heating_capacity.round(0),
                                         energy_factor: energy_factor,
                                         uses_desuperheater: false,
                                         temperature: Defaults.get_water_heater_temperature(@eri_version))

      break if has_multiple_water_heaters # Only add 1 reference water heater
    end

    if orig_bldg.water_heating_systems.size == 0
      add_reference_water_heater(orig_bldg, new_bldg, is_all_electric: is_all_electric)
    end
  end

  def self.set_systems_water_heater_rated(orig_bldg, new_bldg)
    # Table 4.2.2(1) - Service water heating systems

    orig_bldg.water_heating_systems.each do |orig_water_heater|
      heating_capacity = orig_water_heater.heating_capacity
      if (orig_water_heater.water_heater_type == HPXML::WaterHeaterTypeStorage) && heating_capacity.nil?
        heating_capacity = Defaults.get_water_heater_heating_capacity(orig_water_heater.fuel_type, @nbeds, orig_bldg.water_heating_systems.size)
      end

      if orig_water_heater.water_heater_type == HPXML::WaterHeaterTypeTankless
        performance_adjustment = Defaults.get_water_heater_performance_adjustment(orig_water_heater)
      else
        performance_adjustment = 1.0
      end

      uses_desuperheater = orig_water_heater.uses_desuperheater
      uses_desuperheater = false if uses_desuperheater.nil?

      if Constants::ERIVersions.index(@eri_version) >= Constants::ERIVersions.index('latest') # FIXME: Change from 'latest' when incorporated in 301 standard
        hpwh_confined_space_without_mitigation = orig_water_heater.hpwh_confined_space_without_mitigation
        hpwh_containment_volume = orig_water_heater.hpwh_containment_volume
      end

      # New water heater
      new_bldg.water_heating_systems.add(id: orig_water_heater.id,
                                         is_shared_system: orig_water_heater.is_shared_system,
                                         number_of_bedrooms_served: orig_water_heater.number_of_bedrooms_served,
                                         fuel_type: orig_water_heater.fuel_type,
                                         water_heater_type: orig_water_heater.water_heater_type,
                                         location: orig_water_heater.location,
                                         performance_adjustment: performance_adjustment,
                                         tank_volume: orig_water_heater.tank_volume,
                                         fraction_dhw_load_served: orig_water_heater.fraction_dhw_load_served,
                                         heating_capacity: heating_capacity,
                                         energy_factor: orig_water_heater.energy_factor,
                                         uniform_energy_factor: orig_water_heater.uniform_energy_factor,
                                         first_hour_rating: orig_water_heater.first_hour_rating,
                                         recovery_efficiency: orig_water_heater.recovery_efficiency,
                                         uses_desuperheater: uses_desuperheater,
                                         jacket_r_value: orig_water_heater.jacket_r_value,
                                         related_hvac_idref: orig_water_heater.related_hvac_idref,
                                         standby_loss_units: orig_water_heater.standby_loss_units,
                                         standby_loss_value: orig_water_heater.standby_loss_value,
                                         hpwh_confined_space_without_mitigation: hpwh_confined_space_without_mitigation,
                                         hpwh_containment_volume: hpwh_containment_volume,
                                         temperature: Defaults.get_water_heater_temperature(@eri_version))
    end

    if orig_bldg.water_heating_systems.size == 0
      add_reference_water_heater(orig_bldg, new_bldg)
    end
  end

  def self.set_systems_water_heater_iad(orig_bldg, new_bldg)
    # Table 4.3.1(1) Configuration of Index Adjustment Design - Service water heating systems
    set_systems_water_heater_reference(orig_bldg, new_bldg, in_conditioned_space: true)
  end

  def self.set_systems_water_heating_use_reference(new_bldg)
    # Table 4.2.2(1) - Service water heating systems

    has_uncond_bsmnt = new_bldg.has_location(HPXML::LocationBasementUnconditioned)
    has_cond_bsmnt = new_bldg.has_location(HPXML::LocationBasementConditioned)
    standard_piping_length = Defaults.get_std_pipe_length(has_uncond_bsmnt, has_cond_bsmnt, @cfa, @ncfl)

    # New hot water distribution
    new_bldg.hot_water_distributions.add(id: 'HotWaterDistribution',
                                         system_type: HPXML::DHWDistTypeStandard,
                                         pipe_r_value: 0,
                                         standard_piping_length: standard_piping_length.round(3))

    # New water fixtures
    new_bldg.water_fixtures.add(id: 'ShowerHead',
                                water_fixture_type: HPXML::WaterFixtureTypeShowerhead,
                                low_flow: false)

    # Faucet
    new_bldg.water_fixtures.add(id: 'Faucet',
                                water_fixture_type: HPXML::WaterFixtureTypeFaucet,
                                low_flow: false)
  end

  def self.set_systems_water_heating_use_rated(orig_bldg, new_bldg)
    # Table 4.2.2(1) - Service water heating systems

    if orig_bldg.hot_water_distributions.size == 0
      set_systems_water_heating_use_reference(new_bldg)
      return
    end

    # New hot water distribution
    hot_water_distribution = orig_bldg.hot_water_distributions[0]
    new_bldg.hot_water_distributions.add(id: hot_water_distribution.id,
                                         system_type: hot_water_distribution.system_type,
                                         pipe_r_value: hot_water_distribution.pipe_r_value,
                                         standard_piping_length: hot_water_distribution.standard_piping_length,
                                         recirculation_control_type: hot_water_distribution.recirculation_control_type,
                                         recirculation_piping_loop_length: hot_water_distribution.recirculation_piping_loop_length,
                                         recirculation_branch_piping_length: hot_water_distribution.recirculation_branch_piping_length,
                                         recirculation_pump_power: hot_water_distribution.recirculation_pump_power,
                                         dwhr_facilities_connected: hot_water_distribution.dwhr_facilities_connected,
                                         dwhr_equal_flow: hot_water_distribution.dwhr_equal_flow,
                                         dwhr_efficiency: hot_water_distribution.dwhr_efficiency,
                                         has_shared_recirculation: hot_water_distribution.has_shared_recirculation,
                                         shared_recirculation_number_of_bedrooms_served: hot_water_distribution.shared_recirculation_number_of_bedrooms_served,
                                         shared_recirculation_pump_power: hot_water_distribution.shared_recirculation_pump_power,
                                         shared_recirculation_control_type: hot_water_distribution.shared_recirculation_control_type)

    # New water fixtures
    orig_water_fixtures = orig_bldg.water_fixtures.select { |f| [HPXML::WaterFixtureTypeShowerhead, HPXML::WaterFixtureTypeFaucet].include? f.water_fixture_type }
    all_low_flow = orig_water_fixtures.all? { |f| f.low_flow }
    orig_water_fixtures.each do |orig_water_fixture|
      new_bldg.water_fixtures.add(id: orig_water_fixture.id,
                                  water_fixture_type: orig_water_fixture.water_fixture_type,
                                  low_flow: all_low_flow)
    end
  end

  def self.set_systems_water_heating_use_iad(new_bldg)
    # Table 4.3.1(1) Configuration of Index Adjustment Design - Service water heating systems
    set_systems_water_heating_use_reference(new_bldg)
  end

  def self.set_systems_solar_thermal_reference(orig_bldg, new_bldg)
    # nop
  end

  def self.set_systems_solar_thermal_rated(orig_bldg, new_bldg)
    return if orig_bldg.solar_thermal_systems.size == 0

    solar_thermal_system = orig_bldg.solar_thermal_systems[0]
    new_bldg.solar_thermal_systems.add(id: solar_thermal_system.id,
                                       system_type: solar_thermal_system.system_type,
                                       collector_area: solar_thermal_system.collector_area,
                                       collector_loop_type: solar_thermal_system.collector_loop_type,
                                       collector_azimuth: solar_thermal_system.collector_azimuth,
                                       collector_type: solar_thermal_system.collector_type,
                                       collector_tilt: solar_thermal_system.collector_tilt,
                                       collector_rated_optical_efficiency: solar_thermal_system.collector_rated_optical_efficiency,
                                       collector_rated_thermal_losses: solar_thermal_system.collector_rated_thermal_losses,
                                       storage_volume: solar_thermal_system.storage_volume,
                                       water_heating_system_idref: solar_thermal_system.water_heating_system_idref,
                                       solar_fraction: solar_thermal_system.solar_fraction)
  end

  def self.set_systems_solar_thermal_iad(orig_bldg, new_bldg)
    # nop
  end

  def self.set_systems_photovoltaics_reference(orig_bldg, new_bldg)
    # nop
  end

  def self.set_systems_photovoltaics_rated(orig_bldg, new_bldg)
    orig_bldg.pv_systems.each do |orig_pv_system|
      new_bldg.pv_systems.add(id: orig_pv_system.id,
                              is_shared_system: orig_pv_system.is_shared_system,
                              location: orig_pv_system.location,
                              module_type: orig_pv_system.module_type,
                              tracking: orig_pv_system.tracking,
                              array_azimuth: orig_pv_system.array_azimuth,
                              array_tilt: orig_pv_system.array_tilt,
                              max_power_output: orig_pv_system.max_power_output,
                              inverter_idref: orig_pv_system.inverter_idref,
                              system_losses_fraction: orig_pv_system.system_losses_fraction,
                              number_of_bedrooms_served: orig_pv_system.number_of_bedrooms_served)
    end
    orig_bldg.inverters.each do |orig_inverter|
      new_bldg.inverters.add(id: orig_inverter.id,
                             inverter_efficiency: orig_inverter.inverter_efficiency)
    end
  end

  def self.set_systems_photovoltaics_iad(orig_bldg, new_bldg)
    # 4.3.1 Index Adjustment Design (IAD)
    # Renewable Energy Systems that offset the energy consumption requirements of the Rated Home shall not be included in the IAD.
    # nop
  end

  def self.set_systems_batteries_reference(orig_bldg, new_bldg)
    # nop
  end

  def self.set_systems_batteries_rated(orig_bldg, new_bldg)
    if Constants::ERIVersions.index(@eri_version) >= Constants::ERIVersions.index('2022C')
      orig_bldg.batteries.each do |orig_battery|
        new_bldg.batteries.add(id: orig_battery.id,
                               is_shared_system: orig_battery.is_shared_system,
                               type: orig_battery.type,
                               location: orig_battery.location,
                               nominal_capacity_kwh: orig_battery.nominal_capacity_kwh,
                               usable_capacity_kwh: orig_battery.usable_capacity_kwh,
                               rated_power_output: orig_battery.rated_power_output,
                               round_trip_efficiency: orig_battery.round_trip_efficiency,
                               number_of_bedrooms_served: orig_battery.number_of_bedrooms_served)
      end
    end
  end

  def self.set_systems_batteries_iad(orig_bldg, new_bldg)
    # nop
  end

  def self.set_systems_generators_reference(orig_bldg, new_bldg)
    # nop
  end

  def self.set_systems_generators_rated(orig_bldg, new_bldg)
    orig_bldg.generators.each do |orig_generator|
      new_bldg.generators.add(id: orig_generator.id,
                              is_shared_system: orig_generator.is_shared_system,
                              fuel_type: orig_generator.fuel_type,
                              annual_consumption_kbtu: orig_generator.annual_consumption_kbtu,
                              annual_output_kwh: orig_generator.annual_output_kwh,
                              number_of_bedrooms_served: orig_generator.number_of_bedrooms_served)
    end
  end

  def self.set_systems_generators_iad(orig_bldg, new_bldg)
    # 4.3.1 Index Adjustment Design (IAD)
    # Renewable Energy Systems that offset the energy consumption requirements of the Rated Home shall not be included in the IAD.
    # nop
  end

  def self.set_appliances_clothes_washer_reference(orig_bldg, new_bldg)
    # Default values
    id = 'ClothesWasher'
    location = HPXML::LocationConditionedSpace

    # Override values?
    if not orig_bldg.clothes_washers.empty?
      clothes_washer = orig_bldg.clothes_washers[0]
      if not (clothes_washer.is_shared_appliance && (clothes_washer.number_of_units_served / clothes_washer.count) > 14)
        id = clothes_washer.id
        location = clothes_washer.location.gsub('unvented', 'vented')
      end
    end

    reference_values = Defaults.get_clothes_washer_values(@eri_version)
    new_bldg.clothes_washers.add(id: id,
                                 is_shared_appliance: false,
                                 location: location,
                                 integrated_modified_energy_factor: reference_values[:integrated_modified_energy_factor],
                                 rated_annual_kwh: reference_values[:rated_annual_kwh],
                                 label_electric_rate: reference_values[:label_electric_rate],
                                 label_gas_rate: reference_values[:label_gas_rate],
                                 label_annual_gas_cost: reference_values[:label_annual_gas_cost],
                                 label_usage: reference_values[:label_usage],
                                 capacity: reference_values[:capacity])
  end

  def self.set_appliances_clothes_washer_rated(orig_bldg, new_bldg)
    if orig_bldg.clothes_washers.empty?
      set_appliances_clothes_washer_reference(orig_bldg, new_bldg)
      return
    end

    clothes_washer = orig_bldg.clothes_washers[0]

    if clothes_washer.is_shared_appliance && (clothes_washer.number_of_units_served / clothes_washer.count) > 14
      set_appliances_clothes_washer_reference(orig_bldg, new_bldg)
      return
    end

    new_bldg.clothes_washers.add(id: clothes_washer.id,
                                 is_shared_appliance: clothes_washer.is_shared_appliance,
                                 water_heating_system_idref: clothes_washer.water_heating_system_idref,
                                 hot_water_distribution_idref: clothes_washer.hot_water_distribution_idref,
                                 location: clothes_washer.location,
                                 modified_energy_factor: clothes_washer.modified_energy_factor,
                                 integrated_modified_energy_factor: clothes_washer.integrated_modified_energy_factor,
                                 rated_annual_kwh: clothes_washer.rated_annual_kwh,
                                 label_electric_rate: clothes_washer.label_electric_rate,
                                 label_gas_rate: clothes_washer.label_gas_rate,
                                 label_annual_gas_cost: clothes_washer.label_annual_gas_cost,
                                 label_usage: clothes_washer.label_usage,
                                 capacity: clothes_washer.capacity)
  end

  def self.set_appliances_clothes_washer_iad(orig_bldg, new_bldg)
    set_appliances_clothes_washer_reference(orig_bldg, new_bldg)
    new_bldg.clothes_washers[0].location = HPXML::LocationConditionedSpace
  end

  def self.set_appliances_clothes_dryer_reference(orig_bldg, new_bldg, is_all_electric: false)
    # Default values
    id = 'ClothesDryer'
    location = HPXML::LocationConditionedSpace
    fuel_type = HPXML::FuelTypeElectricity

    # Override values?
    if not orig_bldg.clothes_dryers.empty?
      clothes_dryer = orig_bldg.clothes_dryers[0]
      if not (clothes_dryer.is_shared_appliance && (clothes_dryer.number_of_units_served / clothes_dryer.count) > 14)
        id = clothes_dryer.id
        location = clothes_dryer.location.gsub('unvented', 'vented')
        fuel_type = clothes_dryer.fuel_type
      end
    end

    if is_all_electric
      fuel_type = HPXML::FuelTypeElectricity
    end

    reference_values = Defaults.get_clothes_dryer_values(@eri_version, fuel_type)
    new_bldg.clothes_dryers.add(id: id,
                                is_shared_appliance: false,
                                location: location,
                                fuel_type: fuel_type,
                                combined_energy_factor: reference_values[:combined_energy_factor],
                                control_type: reference_values[:control_type],
                                is_vented: true,
                                vented_flow_rate: 0) # FUTURE: Propose dryer venting for ANSI 301
  end

  def self.set_appliances_clothes_dryer_rated(orig_bldg, new_bldg)
    if orig_bldg.clothes_dryers.empty?
      set_appliances_clothes_dryer_reference(orig_bldg, new_bldg)
      return
    end

    clothes_dryer = orig_bldg.clothes_dryers[0]

    if clothes_dryer.is_shared_appliance && (clothes_dryer.number_of_units_served / clothes_dryer.count) > 14
      set_appliances_clothes_dryer_reference(orig_bldg, new_bldg)
      return
    end

    if Constants::ERIVersions.index(@eri_version) >= Constants::ERIVersions.index('2022C')
      # Vented vs unvented dryers introduced in 301-2022 Addendum C
      is_vented = clothes_dryer.is_vented
    else
      # Dryers previously assumed to be vented (same as Reference Home)
      is_vented = true
    end

    new_bldg.clothes_dryers.add(id: clothes_dryer.id,
                                is_shared_appliance: clothes_dryer.is_shared_appliance,
                                location: clothes_dryer.location,
                                fuel_type: clothes_dryer.fuel_type,
                                energy_factor: clothes_dryer.energy_factor,
                                combined_energy_factor: clothes_dryer.combined_energy_factor,
                                control_type: clothes_dryer.control_type,
                                is_vented: is_vented,
                                vented_flow_rate: 0) # FUTURE: Propose dryer venting for ANSI 301
  end

  def self.set_appliances_clothes_dryer_iad(orig_bldg, new_bldg)
    set_appliances_clothes_dryer_reference(orig_bldg, new_bldg)
    new_bldg.clothes_dryers[0].location = HPXML::LocationConditionedSpace
  end

  def self.set_appliances_dishwasher_reference(orig_bldg, new_bldg)
    # Default values
    id = 'Dishwasher'
    location = HPXML::LocationConditionedSpace

    # Override values?
    if not orig_bldg.dishwashers.empty?
      dishwasher = orig_bldg.dishwashers[0]
      id = dishwasher.id
      location = dishwasher.location.gsub('unvented', 'vented')
    end

    reference_values = Defaults.get_dishwasher_values(@eri_version)
    new_bldg.dishwashers.add(id: id,
                             is_shared_appliance: false,
                             location: location,
                             energy_factor: reference_values[:energy_factor],
                             rated_annual_kwh: reference_values[:rated_annual_kwh],
                             place_setting_capacity: reference_values[:place_setting_capacity],
                             label_electric_rate: reference_values[:label_electric_rate],
                             label_gas_rate: reference_values[:label_gas_rate],
                             label_annual_gas_cost: reference_values[:label_annual_gas_cost],
                             label_usage: reference_values[:label_usage])
  end

  def self.set_appliances_dishwasher_rated(orig_bldg, new_bldg)
    if orig_bldg.dishwashers.empty?
      set_appliances_dishwasher_reference(orig_bldg, new_bldg)
      return
    end

    dishwasher = orig_bldg.dishwashers[0]

    new_bldg.dishwashers.add(id: dishwasher.id,
                             is_shared_appliance: dishwasher.is_shared_appliance,
                             water_heating_system_idref: dishwasher.water_heating_system_idref,
                             hot_water_distribution_idref: dishwasher.hot_water_distribution_idref,
                             location: dishwasher.location,
                             energy_factor: dishwasher.energy_factor,
                             rated_annual_kwh: dishwasher.rated_annual_kwh,
                             place_setting_capacity: dishwasher.place_setting_capacity,
                             label_electric_rate: dishwasher.label_electric_rate,
                             label_gas_rate: dishwasher.label_gas_rate,
                             label_annual_gas_cost: dishwasher.label_annual_gas_cost,
                             label_usage: dishwasher.label_usage)
  end

  def self.set_appliances_dishwasher_iad(orig_bldg, new_bldg)
    set_appliances_dishwasher_reference(orig_bldg, new_bldg)
    new_bldg.dishwashers[0].location = HPXML::LocationConditionedSpace
  end

  def self.set_appliances_refrigerator_reference(orig_bldg, new_bldg)
    # Default values
    id = 'Refrigerator'
    location = HPXML::LocationConditionedSpace

    # Override values?
    if not orig_bldg.refrigerators.empty?
      refrigerator = orig_bldg.refrigerators[0]
      id = refrigerator.id
      location = refrigerator.location.gsub('unvented', 'vented')
    end

    reference_values = Defaults.get_refrigerator_values(@nbeds)
    new_bldg.refrigerators.add(id: id,
                               location: location,
                               rated_annual_kwh: reference_values[:rated_annual_kwh])
  end

  def self.set_appliances_refrigerator_rated(orig_bldg, new_bldg)
    if orig_bldg.refrigerators.empty?
      set_appliances_refrigerator_reference(orig_bldg, new_bldg)
      return
    end

    refrigerator = orig_bldg.refrigerators[0]
    new_bldg.refrigerators.add(id: refrigerator.id,
                               location: refrigerator.location,
                               rated_annual_kwh: refrigerator.rated_annual_kwh)
  end

  def self.set_appliances_refrigerator_iad(orig_bldg, new_bldg)
    set_appliances_refrigerator_reference(orig_bldg, new_bldg)
    new_bldg.refrigerators[0].location = HPXML::LocationConditionedSpace
  end

  def self.set_appliances_dehumidifier_reference(orig_bldg, new_bldg)
    return if Constants::ERIVersions.index(@eri_version) < Constants::ERIVersions.index('2019AB')

    orig_bldg.dehumidifiers.each do |dehumidifier|
      reference_values = Defaults.get_dehumidifier_values(dehumidifier.capacity)
      new_bldg.dehumidifiers.add(id: dehumidifier.id,
                                 type: dehumidifier.type, # Per RESNET 55i
                                 capacity: dehumidifier.capacity,
                                 integrated_energy_factor: reference_values[:ief],
                                 rh_setpoint: reference_values[:rh_setpoint],
                                 fraction_served: dehumidifier.fraction_served,
                                 location: dehumidifier.location)
    end
  end

  def self.set_appliances_dehumidifier_rated(orig_bldg, new_bldg)
    return if Constants::ERIVersions.index(@eri_version) < Constants::ERIVersions.index('2019AB')

    orig_bldg.dehumidifiers.each do |dehumidifier|
      new_bldg.dehumidifiers.add(id: dehumidifier.id,
                                 type: dehumidifier.type,
                                 capacity: dehumidifier.capacity,
                                 energy_factor: dehumidifier.energy_factor,
                                 integrated_energy_factor: dehumidifier.integrated_energy_factor,
                                 rh_setpoint: 0.60,
                                 fraction_served: dehumidifier.fraction_served,
                                 location: dehumidifier.location)
    end
  end

  def self.set_appliances_dehumidifier_iad(orig_bldg, new_bldg)
    # nop
  end

  def self.set_appliances_cooking_range_oven_reference(orig_bldg, new_bldg, is_all_electric: false)
    # Default values
    range_id = 'CookingRange'
    location = HPXML::LocationConditionedSpace
    fuel_type = HPXML::FuelTypeElectricity
    oven_id = 'Oven'

    # Override values?
    if not orig_bldg.cooking_ranges.empty?
      cooking_range = orig_bldg.cooking_ranges[0]
      range_id = cooking_range.id
      location = cooking_range.location.gsub('unvented', 'vented')
      fuel_type = cooking_range.fuel_type
      oven = orig_bldg.ovens[0]
      oven_id = oven.id
    end

    if is_all_electric
      fuel_type = HPXML::FuelTypeElectricity
    end

    reference_values = Defaults.get_range_oven_values()
    new_bldg.cooking_ranges.add(id: range_id,
                                location: location,
                                fuel_type: fuel_type,
                                is_induction: reference_values[:is_induction])
    new_bldg.ovens.add(id: oven_id,
                       is_convection: reference_values[:is_convection])
  end

  def self.set_appliances_cooking_range_oven_rated(orig_bldg, new_bldg)
    if orig_bldg.cooking_ranges.empty?
      set_appliances_cooking_range_oven_reference(orig_bldg, new_bldg)
      return
    end

    cooking_range = orig_bldg.cooking_ranges[0]
    oven = orig_bldg.ovens[0]
    new_bldg.cooking_ranges.add(id: cooking_range.id,
                                location: cooking_range.location,
                                fuel_type: cooking_range.fuel_type,
                                is_induction: cooking_range.is_induction)
    new_bldg.ovens.add(id: oven.id,
                       is_convection: oven.is_convection)
  end

  def self.set_appliances_cooking_range_oven_iad(orig_bldg, new_bldg)
    set_appliances_cooking_range_oven_reference(orig_bldg, new_bldg)
    new_bldg.cooking_ranges[0].location = HPXML::LocationConditionedSpace
  end

  def self.set_lighting_reference(orig_bldg, new_bldg)
    ltg_fracs = Defaults.get_lighting_fractions()

    orig_bldg.lighting_groups.each do |orig_lg|
      fraction = ltg_fracs[[orig_lg.location, orig_lg.lighting_type]]
      next if fraction.nil?

      new_bldg.lighting_groups.add(id: orig_lg.id,
                                   location: orig_lg.location,
                                   fraction_of_units_in_location: fraction,
                                   lighting_type: orig_lg.lighting_type)
    end
  end

  def self.set_lighting_rated(orig_bldg, new_bldg)
    orig_bldg.lighting_groups.each do |orig_lg|
      next unless [HPXML::LocationInterior, HPXML::LocationExterior, HPXML::LocationGarage].include? orig_lg.location
      next unless [HPXML::LightingTypeCFL, HPXML::LightingTypeLFL, HPXML::LightingTypeLED].include? orig_lg.lighting_type

      new_bldg.lighting_groups.add(id: orig_lg.id,
                                   location: orig_lg.location,
                                   fraction_of_units_in_location: orig_lg.fraction_of_units_in_location,
                                   lighting_type: orig_lg.lighting_type)
    end
  end

  def self.set_lighting_iad(orig_bldg, new_bldg)
    orig_bldg.lighting_groups.each do |orig_lg|
      next unless [HPXML::LocationInterior, HPXML::LocationExterior, HPXML::LocationGarage].include? orig_lg.location
      next unless [HPXML::LightingTypeCFL, HPXML::LightingTypeLFL, HPXML::LightingTypeLED].include? orig_lg.lighting_type

      if [HPXML::LocationInterior, HPXML::LocationExterior].include?(orig_lg.location) && (orig_lg.lighting_type == HPXML::LightingTypeCFL)
        fraction = 0.75
      else
        fraction = 0
      end

      new_bldg.lighting_groups.add(id: orig_lg.id,
                                   location: orig_lg.location,
                                   fraction_of_units_in_location: fraction,
                                   lighting_type: orig_lg.lighting_type)
    end
  end

  def self.set_ceiling_fans_reference(orig_bldg, new_bldg)
    n_fans = orig_bldg.ceiling_fans.map { |cf| cf.count }.sum(0)
    if (Constants::ERIVersions.index(@eri_version) >= Constants::ERIVersions.index('2019')) && (n_fans < @nbeds + 1)
      # In 301-2019, no ceiling fans in Reference Home if number of ceiling fans
      # is less than Nbr + 1.
      return
    elsif n_fans < 1
      # In 301-2014, no ceiling fans in Reference Home if no ceiling fans.
      return
    end

    new_bldg.ceiling_fans.add(id: 'CeilingFans',
                              label_energy_use: Defaults.get_ceiling_fan_power(),
                              count: Defaults.get_ceiling_fan_count(@nbeds))
    new_bldg.hvac_controls[0].ceiling_fan_cooling_setpoint_temp_offset = 0.5
  end

  def self.set_ceiling_fans_rated(orig_bldg, new_bldg)
    n_fans = orig_bldg.ceiling_fans.map { |cf| cf.count }.sum(0)
    if (Constants::ERIVersions.index(@eri_version) >= Constants::ERIVersions.index('2019')) && (n_fans < @nbeds + 1)
      # In 301-2019, no ceiling fans in Reference Home if number of ceiling fans
      # is less than Nbr + 1.
      return
    elsif n_fans < 1
      # In 301-2014, no ceiling fans in Reference Home if no ceiling fans.
      return
    end

    # Calculate average ceiling fan wattage
    medium_cfm = 3000.0
    sum_w = 0.0
    num_cfs = 0
    orig_bldg.ceiling_fans.each do |orig_ceiling_fan|
      num_cfs += orig_ceiling_fan.count
      cfm_per_w = orig_ceiling_fan.efficiency
      label_energy_use = orig_ceiling_fan.label_energy_use
      if !label_energy_use.nil? # priority if both provided
        sum_w += (label_energy_use * orig_ceiling_fan.count)
      elsif !cfm_per_w.nil?
        sum_w += (medium_cfm / cfm_per_w * orig_ceiling_fan.count)
      end
    end
    avg_w = sum_w / num_cfs

    new_bldg.ceiling_fans.add(id: 'CeilingFans',
                              label_energy_use: avg_w,
                              count: Defaults.get_ceiling_fan_count(@nbeds))
    new_bldg.hvac_controls[0].ceiling_fan_cooling_setpoint_temp_offset = 0.5
  end

  def self.set_ceiling_fans_iad(orig_bldg, new_bldg)
    # Not described in Addendum E; use Reference Home?
    set_ceiling_fans_reference(orig_bldg, new_bldg)
  end

  def self.set_misc_loads_reference(new_bldg)
    # Misc
    kwh_per_year, frac_sensible, frac_latent = Defaults.get_residual_mels_values(@cfa)
    new_bldg.plug_loads.add(id: 'MiscPlugLoad',
                            plug_load_type: HPXML::PlugLoadTypeOther,
                            kwh_per_year: kwh_per_year,
                            frac_sensible: frac_sensible.round(3),
                            frac_latent: frac_latent.round(3))

    # Television
    kwh_per_year, frac_sensible, frac_latent = Defaults.get_televisions_values(@cfa, @nbeds)
    new_bldg.plug_loads.add(id: 'TelevisionPlugLoad',
                            plug_load_type: HPXML::PlugLoadTypeTelevision,
                            kwh_per_year: kwh_per_year,
                            frac_sensible: frac_sensible.round(3),
                            frac_latent: frac_latent.round(3))
  end

  def self.set_misc_loads_rated(new_bldg)
    set_misc_loads_reference(new_bldg)
  end

  def self.set_misc_loads_iad(new_bldg)
    set_misc_loads_reference(new_bldg)
  end

  private

  def self.calc_rated_home_q_fans_by_system(orig_bldg, all_mech_vent_fans)
    # Calculates the target average airflow rate for each mechanical
    # ventilation system based on their measured value (if available)
    # and the minimum continuous ventilation rate Qfan.
    mech_vent_fans = all_mech_vent_fans.select { |f| !f.is_cfis_supplemental_fan }
    supply_fans = mech_vent_fans.select { |f| f.includes_supply_air && !f.is_balanced }
    exhaust_fans = mech_vent_fans.select { |f| f.includes_exhaust_air && !f.is_balanced }
    balanced_fans = mech_vent_fans.select { |f| f.is_balanced }

    # Calculate min airflow rate requirement
    is_balanced, frac_imbal = get_mech_vent_imbal_properties(mech_vent_fans)
    min_q_fan = calc_rated_home_qfan(orig_bldg, is_balanced, frac_imbal)

    # Calculate total supply/exhaust cfm (across all mech vent systems)
    cfm_oa_supply, cfm_oa_exhaust = calc_mech_vent_supply_exhaust_cfms(mech_vent_fans, :oa)

    # Calculate min airflow rate requirement by supply vs exhaust
    min_q_fan_supply = 0.0
    min_q_fan_exhaust = 0.0
    if cfm_oa_supply == 0 && cfm_oa_exhaust == 0 # All systems are unmeasured
      min_q_fan_supply = min_q_fan if (supply_fans.size + balanced_fans.size) > 0
      min_q_fan_exhaust = min_q_fan if (exhaust_fans.size + balanced_fans.size) > 0
    elsif cfm_oa_supply > cfm_oa_exhaust
      min_q_fan_supply = [cfm_oa_supply, min_q_fan].max
      min_q_fan_exhaust = cfm_oa_exhaust * min_q_fan_supply / cfm_oa_supply
    else
      min_q_fan_exhaust = [cfm_oa_exhaust, min_q_fan].max
      min_q_fan_supply = cfm_oa_supply * min_q_fan_exhaust / cfm_oa_exhaust
    end

    # Calculate additional outdoor airflow needed to reach min_q_fan
    if balanced_fans.size > 0
      cfm_oa_addtl_balanced = [min_q_fan_supply - cfm_oa_supply, min_q_fan_exhaust - cfm_oa_exhaust].min
    else
      cfm_oa_addtl_balanced = 0
    end
    cfm_oa_addtl_supply = min_q_fan_supply - cfm_oa_supply - cfm_oa_addtl_balanced
    cfm_oa_addtl_exhaust = min_q_fan_exhaust - cfm_oa_exhaust - cfm_oa_addtl_balanced

    # Calculate target cfm for each system:

    # 1. First attribute any additional airflow needed to unmeasured systems
    q_fans = {}
    unmeasured_balanced_fans = balanced_fans.select { |f| f.flow_rate_not_tested }
    unmeasured_balanced_fans.each do |orig_vent_fan|
      q_fans[orig_vent_fan.id] = cfm_oa_addtl_balanced / unmeasured_balanced_fans.size
    end
    cfm_oa_addtl_balanced -= unmeasured_balanced_fans.map { |f| q_fans[f.id] }.sum(0.0)
    unmeasured_supply_fans = supply_fans.select { |f| f.flow_rate_not_tested }
    unmeasured_supply_fans.each do |orig_vent_fan|
      q_fans[orig_vent_fan.id] = cfm_oa_addtl_supply / unmeasured_supply_fans.size
    end
    cfm_oa_addtl_supply -= unmeasured_supply_fans.map { |f| q_fans[f.id] }.sum(0.0)
    unmeasured_exhaust_fans = exhaust_fans.select { |f| f.flow_rate_not_tested }
    unmeasured_exhaust_fans.each do |orig_vent_fan|
      q_fans[orig_vent_fan.id] = cfm_oa_addtl_exhaust / unmeasured_exhaust_fans.size
    end
    cfm_oa_addtl_exhaust -= unmeasured_exhaust_fans.map { |f| q_fans[f.id] }.sum(0.0)

    # 2. Ensure each unmeasured system is at least 15 cfm per RESNET 55i
    q_fans.each do |id, val|
      q_fans[id] = [val, 15.0].max
    end

    # 3. If additional airflow remains (i.e., no unmeasured system to attribute it to), bump up measured systems
    measured_balanced_fans = balanced_fans.select { |f| !f.flow_rate_not_tested }
    measured_balanced_fans.each do |orig_vent_fan|
      q_fans[orig_vent_fan.id] = orig_vent_fan.average_oa_unit_flow_rate + cfm_oa_addtl_balanced / measured_balanced_fans.size
    end
    measured_supply_fans = supply_fans.select { |f| !f.flow_rate_not_tested }
    measured_supply_fans.each do |orig_vent_fan|
      q_fans[orig_vent_fan.id] = orig_vent_fan.average_oa_unit_flow_rate + cfm_oa_addtl_supply / measured_supply_fans.size
    end
    measured_exhaust_fans = exhaust_fans.select { |f| !f.flow_rate_not_tested }
    measured_exhaust_fans.each do |orig_vent_fan|
      q_fans[orig_vent_fan.id] = orig_vent_fan.average_oa_unit_flow_rate + cfm_oa_addtl_exhaust / measured_exhaust_fans.size
    end

    # Set Qfan for any CFIS supplemental fans last
    all_mech_vent_fans.each do |orig_vent_fan|
      next unless orig_vent_fan.is_cfis_supplemental_fan

      parent_cfis_fan = all_mech_vent_fans.find { |f| f.cfis_supplemental_fan_idref == orig_vent_fan.id }
      q_fans[orig_vent_fan.id] = q_fans[parent_cfis_fan.id]
    end

    q_fan_bal_remain = 0
    if Constants::ERIVersions.index(@eri_version) >= Constants::ERIVersions.index('2022C')
      # Check if supplemental balanced ventilation is needed
      # This should only happen when the home has no mechanical ventilation, because
      # otherwise the existing ventilation fans would have been increased instead.
      if min_q_fan - q_fans.values.sum > 0.1
        q_fan_bal_remain = calc_rated_home_qfan(orig_bldg, true, 0.0)
      end
    end

    return q_fans, q_fan_bal_remain
  end

  def self.calc_rated_home_infiltration_ach50(orig_bldg)
    # Note: The infiltration rate returned will *include* the Aext term.
    # We separately report out the Aext in the HPXML file for inspection, but the
    # AirInfiltrationMeasurement element will use infiltration_type: 'unit exterior'
    # so as not to double-count the Aext term.
    infil_values = Airflow.get_values_from_air_infiltration_measurements(orig_bldg, @weather)

    if @bldg_type == HPXML::ResidentialTypeSFD
      a_ext = 1.0
    else
      tot_cb_area, ext_cb_area = Defaults.get_compartmentalization_boundary_areas(orig_bldg)
      a_ext = ext_cb_area / tot_cb_area

      if Constants::ERIVersions.index(@eri_version) >= Constants::ERIVersions.index('2019')
        if [HPXML::ResidentialTypeApartment, HPXML::ResidentialTypeSFA].include? @bldg_type
          cfm50 = infil_values[:ach50] * infil_values[:volume] / 60.0
          tot_cb_area, _ext_cb_area = Defaults.get_compartmentalization_boundary_areas(orig_bldg)
          if cfm50 / tot_cb_area > 0.30
            a_ext = 1.0
          end
        end
      end
    end

    ach50 = infil_values[:ach50]

    # Apply min Natural ACH?
    min_nach = nil
    mech_vent_fans = orig_bldg.ventilation_fans.select { |f| f.used_for_whole_building_ventilation }
    if mech_vent_fans.empty?
      min_nach = 0.30
    end
    if Constants::ERIVersions.index(@eri_version) >= Constants::ERIVersions.index('2022CE')
      if mech_vent_fans.any? { |f| f.fan_type == HPXML::MechVentTypeCFIS && f.cfis_addtl_runtime_operating_mode == HPXML::CFISModeNone }
        # Does not quality as Dwelling Unit Mechanical Ventilation System because it has no
        # strategy to meet remainder of ventilation target
        min_nach = 0.30
      end
    end
    if Constants::ERIVersions.index(@eri_version) >= Constants::ERIVersions.index('2019')
      has_non_exhaust_systems = mech_vent_fans.any? { |f| f.fan_type != HPXML::MechVentTypeExhaust }
      mech_vent_fans.each do |orig_vent_fan|
        if orig_vent_fan.flow_rate_not_tested || ((a_ext < 0.5) && !has_non_exhaust_systems)
          min_nach = 0.30
        end
      end
    end

    if not min_nach.nil?
      min_sla = Airflow.get_infiltration_SLA_from_ACH(min_nach, infil_values[:height], infil_values[:avg_ceil_height], @weather)
      min_ach50 = Airflow.get_infiltration_ACH50_from_SLA(min_sla, infil_values[:avg_ceil_height])
      if ach50 < min_ach50
        ach50 = min_ach50
      end
    end

    ach50 *= a_ext

    return ach50, a_ext
  end

  def self.calc_mech_vent_supply_exhaust_cfms(ventilation_fans, total_or_oa)
    cfm_supply = 0.0
    cfm_exhaust = 0.0
    ventilation_fans.each do |vent_fan|
      next unless vent_fan.used_for_whole_building_ventilation
      next if vent_fan.is_cfis_supplemental_fan
      next if vent_fan.flow_rate_not_tested

      if total_or_oa == :total
        unit_flow_rate = vent_fan.average_unit_flow_rate
      elsif total_or_oa == :oa
        unit_flow_rate = vent_fan.average_oa_unit_flow_rate
      end

      if vent_fan.includes_supply_air
        cfm_supply += unit_flow_rate
      end
      if vent_fan.includes_exhaust_air
        cfm_exhaust += unit_flow_rate
      end
    end
    return cfm_supply, cfm_exhaust
  end

  def self.get_mech_vent_imbal_properties(mech_vent_fans)
    # Returns (is_imbalanced, frac_imbalanced)
    whole_fans = mech_vent_fans.select { |f| f.used_for_whole_building_ventilation && !f.is_cfis_supplemental_fan }

    if whole_fans.count { |f| !f.is_balanced && f.hours_in_operation < 24 } > 1
      return false, 1.0 # Multiple intermittent unbalanced fans, assume imbalanced per ANSI 301-2022
    end

    unmeasured_types = whole_fans.select { |f| f.flow_rate_not_tested }
    if unmeasured_types.size > 0
      if unmeasured_types.all? { |f| f.is_balanced }
        return true, 0.0 # All types are balanced, assume balanced
      else
        return false, 1.0 # Some supply-only or exhaust-only systems, impossible to know, assume imbalanced
      end
    end

    if whole_fans.any? { |f| f.fan_type == HPXML::MechVentTypeCFIS }
      # Not possible for a CFIS system to be completely balanced, so treat as imbalanced.
      # (Though note that a CFIS system w/ a supplemental fan that runs simultaneously
      # with the air handler fan could be balanced for part of the year, but not possible
      # to know how much of the year up front.)
      return false, 1.0
    end

    cfm_total_supply, cfm_total_exhaust = calc_mech_vent_supply_exhaust_cfms(mech_vent_fans, :total)
    q_avg = (cfm_total_supply + cfm_total_exhaust) / 2.0
    if (cfm_total_supply - q_avg).abs / q_avg <= 0.1
      is_balanced = true # Supply/exhaust within 10% of average; balanced
    else
      is_balanced = false
    end
    if cfm_total_supply + cfm_total_exhaust > 0
      frac_imbal = (cfm_total_supply - cfm_total_exhaust).abs / [cfm_total_supply, cfm_total_exhaust].max
    else
      frac_imbal = 1.0
    end

    return is_balanced, frac_imbal
  end

  def self.calc_rated_home_qfan(orig_bldg, is_balanced, frac_imbal)
    infil_values = Airflow.get_values_from_air_infiltration_measurements(orig_bldg, @weather)
    ach50, _ = calc_rated_home_infiltration_ach50(orig_bldg)
    sla = Airflow.get_infiltration_SLA_from_ACH50(ach50, infil_values[:avg_ceil_height])
    q_tot = Airflow.get_mech_vent_qtot_cfm(@nbeds, @cfa)
    q_fan = calc_mech_vent_qfan(q_tot, sla, is_balanced, frac_imbal, infil_values[:height])
    return q_fan
  end

  def self.calc_mech_vent_qfan(q_tot, sla, is_balanced, frac_imbal, infil_height)
    nl = Airflow.get_infiltration_NL_from_SLA(sla, infil_height)
    q_inf = Airflow.get_mech_vent_qinf_cfm(nl, @weather, @cfa)
    a_ext = 1.0 # Use Aext=1.0 because sla reflects 'unit exterior' infiltration so it already incorporates Aext
    q_fan = Airflow.get_mech_vent_qfan_cfm(q_tot, q_inf, is_balanced, frac_imbal, a_ext, @bldg_type, @eri_version, nil)
    return q_fan
  end

  def self.get_new_distribution_id(orig_bldg, new_bldg)
    i = 0
    while true
      i += 1
      dist_id = "HVACDistributionDSE_#{i}"
      found_id = false
      (new_bldg.hvac_systems + orig_bldg.hvac_systems).each do |hvac|
        next if hvac.distribution_system_idref.nil?
        next unless hvac.distribution_system_idref == dist_id

        found_id = true
      end
      return dist_id if not found_id
    end
  end

  def self.add_reference_gas_furnace(orig_bldg, new_bldg, load_frac, orig_system: nil)
    # 78% AFUE gas furnace
    if not orig_system.nil?
      seed_id = orig_system.htg_seed_id.nil? ? orig_system.id : orig_system.htg_seed_id
      dist_id = orig_system.distribution_system.id unless orig_system.distribution_system.nil?
    end
    seed_id = 'ResidualHeating' if seed_id.nil?
    dist_id = get_new_distribution_id(orig_bldg, new_bldg) if dist_id.nil?

    airflow_defect_ratio = get_reference_hvac_airflow_defect_ratio()
    fan_watts_per_cfm = get_reference_hvac_fan_watts_per_cfm()

    new_bldg.heating_systems.add(id: "HeatingSystem#{new_bldg.heating_systems.size + 1}",
                                 distribution_system_idref: dist_id,
                                 heating_system_type: HPXML::HVACTypeFurnace,
                                 heating_system_fuel: HPXML::FuelTypeNaturalGas,
                                 heating_capacity: -1, # Use auto-sizing
                                 heating_efficiency_afue: 0.78,
                                 fraction_heat_load_served: load_frac,
                                 airflow_defect_ratio: airflow_defect_ratio,
                                 fan_watts_per_cfm: fan_watts_per_cfm,
                                 htg_seed_id: seed_id)
  end

  def self.add_reference_gas_boiler(orig_bldg, new_bldg, load_frac, orig_system: nil)
    # 80% AFUE gas boiler
    if not orig_system.nil?
      seed_id = orig_system.htg_seed_id.nil? ? orig_system.id : orig_system.htg_seed_id
      dist_id = orig_system.distribution_system.id unless orig_system.distribution_system.nil?
    end
    seed_id = 'ResidualHeating' if seed_id.nil?
    dist_id = get_new_distribution_id(orig_bldg, new_bldg) if dist_id.nil?

    new_bldg.heating_systems.add(id: "HeatingSystem#{new_bldg.heating_systems.size + 1}",
                                 is_shared_system: false,
                                 distribution_system_idref: dist_id,
                                 heating_system_type: HPXML::HVACTypeBoiler,
                                 heating_system_fuel: HPXML::FuelTypeNaturalGas,
                                 heating_capacity: -1, # Use auto-sizing
                                 heating_efficiency_afue: 0.80,
                                 fraction_heat_load_served: load_frac,
                                 htg_seed_id: seed_id)
  end

  def self.add_reference_heat_pump(orig_bldg, new_bldg, htg_load_frac, clg_load_frac, orig_htg_system: nil, orig_clg_system: nil, is_all_electric: false)
    # 7.7 HSPF (6.55 HSPF2), SEER 13 (SEER2 12.35), EER 11.3 (EER2 10.7) air source heat pump
    if not orig_htg_system.nil?
      if orig_htg_system.is_a? HPXML::CoolingSystem # Cooling system w/ integrated heating
        htg_seed_id = orig_htg_system.clg_seed_id.nil? ? orig_htg_system.id : orig_htg_system.clg_seed_id
      else
        htg_seed_id = orig_htg_system.htg_seed_id.nil? ? orig_htg_system.id : orig_htg_system.htg_seed_id
      end
      dist_id = orig_htg_system.distribution_system.id unless orig_htg_system.distribution_system.nil?
      # Handle backup
      if orig_htg_system.is_a?(HPXML::HeatPump) && orig_htg_system.is_dual_fuel && !is_all_electric
        # Dual-fuel HP in both Rated and Reference homes
        backup_type = HPXML::HeatPumpBackupTypeIntegrated
        backup_fuel = orig_htg_system.backup_heating_fuel
        backup_efficiency_afue = 0.78
        backup_capacity = -1
      end
    end
    if not orig_clg_system.nil?
      clg_seed_id = orig_clg_system.clg_seed_id.nil? ? orig_clg_system.id : orig_clg_system.clg_seed_id
    end
    htg_seed_id = 'ResidualHeating' if htg_seed_id.nil?
    clg_seed_id = 'ResidualCooling' if clg_seed_id.nil?
    dist_id = get_new_distribution_id(orig_bldg, new_bldg) if dist_id.nil?

    if backup_type.nil?
      # Standard electric backup
      backup_type = HPXML::HeatPumpBackupTypeIntegrated
      backup_fuel = HPXML::FuelTypeElectricity
      backup_efficiency_percent = 1.0
      backup_capacity = -1
    end

    airflow_defect_ratio = get_reference_hvac_airflow_defect_ratio()
    fan_watts_per_cfm = get_reference_hvac_fan_watts_per_cfm()
    charge_defect_ratio = get_reference_hvac_charge_defect_ratio()

    heat_pump_type = HPXML::HVACTypeHeatPumpAirToAir
    compressor_type = HPXML::HVACCompressorTypeSingleStage

    compressor_lockout_temp = get_hp_compressor_lockout_temp(heat_pump_type,
                                                             backup_fuel,
                                                             compressor_type)
    backup_heating_lockout_temp = get_hp_backup_heating_lockout_temp(heat_pump_type)
    backup_heating_active_during_defrost = get_hp_backup_heating_active_during_defrost(heat_pump_type, backup_type)

    new_bldg.heat_pumps.add(id: "HeatPump#{new_bldg.heat_pumps.size + 1}",
                            distribution_system_idref: dist_id,
                            heat_pump_type: heat_pump_type,
                            heat_pump_fuel: HPXML::FuelTypeElectricity,
                            compressor_type: compressor_type,
                            compressor_lockout_temp: compressor_lockout_temp,
                            cooling_capacity: -1, # Use auto-sizing
                            heating_capacity: -1, # Use auto-sizing
                            heating_capacity_17F: -1, # Use auto-sizing
                            backup_type: backup_type,
                            backup_heating_lockout_temp: backup_heating_lockout_temp,
                            backup_heating_fuel: backup_fuel,
                            backup_heating_capacity: backup_capacity,
                            backup_heating_efficiency_percent: backup_efficiency_percent,
                            backup_heating_efficiency_afue: backup_efficiency_afue,
                            backup_heating_active_during_defrost: backup_heating_active_during_defrost,
                            fraction_heat_load_served: htg_load_frac,
                            fraction_cool_load_served: clg_load_frac,
                            cooling_efficiency_seer2: 12.35,
                            cooling_efficiency_eer2: 10.7,
                            heating_efficiency_hspf2: 6.55,
                            airflow_defect_ratio: airflow_defect_ratio,
                            fan_watts_per_cfm: fan_watts_per_cfm,
                            charge_defect_ratio: charge_defect_ratio,
                            pan_heater_control_type: HPXML::HVACPanHeaterControlTypeContinuous,
                            equipment_type: HPXML::HVACEquipmentTypeSplit,
                            htg_seed_id: htg_seed_id,
                            clg_seed_id: clg_seed_id)
  end

  def self.add_reference_air_conditioner(orig_bldg, new_bldg, load_frac, orig_system: nil)
    # SEER 13 (SEER2 12.35), EER 11.3 (EER2 10.7) electric air conditioner
    if not orig_system.nil?
      seed_id = orig_system.clg_seed_id.nil? ? orig_system.id : orig_system.clg_seed_id
      dist_id = orig_system.distribution_system.id unless orig_system.distribution_system.nil?
    end
    seed_id = 'ResidualCooling' if seed_id.nil?
    dist_id = get_new_distribution_id(orig_bldg, new_bldg) if dist_id.nil?

    airflow_defect_ratio = get_reference_hvac_airflow_defect_ratio()
    fan_watts_per_cfm = get_reference_hvac_fan_watts_per_cfm()
    charge_defect_ratio = get_reference_hvac_charge_defect_ratio()

    new_bldg.cooling_systems.add(id: "CoolingSystem#{new_bldg.cooling_systems.size + 1}",
                                 distribution_system_idref: dist_id,
                                 cooling_system_type: HPXML::HVACTypeCentralAirConditioner,
                                 cooling_system_fuel: HPXML::FuelTypeElectricity,
                                 compressor_type: HPXML::HVACCompressorTypeSingleStage,
                                 cooling_capacity: -1, # Use auto-sizing
                                 fraction_cool_load_served: load_frac,
                                 cooling_efficiency_seer2: 12.35,
                                 cooling_efficiency_eer2: 10.7,
                                 airflow_defect_ratio: airflow_defect_ratio,
                                 fan_watts_per_cfm: fan_watts_per_cfm,
                                 charge_defect_ratio: charge_defect_ratio,
                                 equipment_type: HPXML::HVACEquipmentTypeSplit,
                                 clg_seed_id: seed_id)
  end

  def self.add_reference_distribution_system(new_bldg)
    new_bldg.hvac_systems.each do |hvac|
      next if hvac.distribution_system_idref.nil?
      next if new_bldg.hvac_distributions.any? { |d| d.id == hvac.distribution_system_idref }

      # Add new DSE distribution if distribution doesn't already exist
      new_bldg.hvac_distributions.add(id: hvac.distribution_system_idref,
                                      distribution_system_type: HPXML::HVACDistributionTypeDSE,
                                      annual_heating_dse: 0.8,
                                      annual_cooling_dse: 0.8)
    end
  end

  def self.add_reference_water_heater(orig_bldg, new_bldg, is_all_electric: false)
    if is_all_electric
      wh_fuel_type = HPXML::FuelTypeElectricity
    else
      wh_fuel_type = orig_bldg.predominant_heating_fuel()
    end
    wh_tank_vol = 40.0

    wh_ef = get_reference_water_heater_ef(wh_fuel_type, wh_tank_vol)
    wh_cap = Defaults.get_water_heater_heating_capacity(wh_fuel_type, @nbeds, 1)

    new_bldg.water_heating_systems.add(id: 'WaterHeatingSystem',
                                       is_shared_system: false,
                                       fuel_type: wh_fuel_type,
                                       water_heater_type: HPXML::WaterHeaterTypeStorage,
                                       location: HPXML::LocationConditionedSpace,
                                       performance_adjustment: 1.0,
                                       tank_volume: wh_tank_vol,
                                       fraction_dhw_load_served: 1.0,
                                       heating_capacity: wh_cap.round(0),
                                       energy_factor: wh_ef,
                                       uses_desuperheater: false,
                                       temperature: Defaults.get_water_heater_temperature(@eri_version))
  end

  def self.get_hvac_capacities_for_distribution_system(orig_hvac_dist)
    htg_cap = 0.0
    clg_cap = 0.0
    orig_hvac_dist.hvac_systems.each do |hvac|
      if hvac.respond_to?(:heating_capacity)
        htg_cap = hvac.heating_capacity
      end
      if hvac.respond_to?(:cooling_capacity)
        clg_cap = hvac.cooling_capacity
      end
    end
    return htg_cap, clg_cap
  end

  def self.get_reference_water_heater_ef(wh_fuel_type, wh_tank_vol)
    # Table 4.2.2(1) - Service water heating systems
    if wh_fuel_type == HPXML::FuelTypeElectricity
      ef = 0.97 - (0.00132 * wh_tank_vol)
    else
      ef = 0.67 - (0.0019 * wh_tank_vol)
    end
    return ef.round(2)
  end

  def self.get_reference_floor_ufactor()
    # Table 4.2.2(2) - Component Heat Transfer Characteristics for Reference Home
    # Floor Over Unconditioned Space U-Factor
    if ['1A', '1B', '1C', '2A', '2B', '2C'].include? @iecc_zone
      return 0.064
    elsif ['3A', '3B', '3C', '4A', '4B'].include? @iecc_zone
      return 0.047
    elsif ['4C', '5A', '5B', '5C', '6A', '6B', '6C', '7', '8'].include? @iecc_zone
      return 0.033
    end
  end

  def self.get_reference_ceiling_ufactor()
    # Table 4.2.2(2) - Component Heat Transfer Characteristics for Reference Home
    # Ceiling U-Factor
    if ['1A', '1B', '1C', '2A', '2B', '2C', '3A', '3B', '3C'].include? @iecc_zone
      return 0.035
    elsif ['4A', '4B', '4C', '5A', '5B', '5C'].include? @iecc_zone
      return 0.030
    elsif ['6A', '6B', '6C', '7', '8'].include? @iecc_zone
      return 0.026
    end
  end

  def self.get_reference_basement_wall_rvalue()
    # Table 4.2.2(2) - Component Heat Transfer Characteristics for Reference Home
    # Basement Wall Exterior R-Value per RESNET 55i
    if ['1A', '1B', '1C', '2A', '2B', '2C', '3A', '3B', '3C'].include? @iecc_zone
      return 0.0
    elsif ['4A', '4B', '4C', '5A', '5B', '5C', '6A', '6B', '6C', '7', '8'].include? @iecc_zone
      return 10.0
    end
  end

  def self.get_reference_slab_perimeter_rvalue_depth()
    # Table 4.2.2(2) - Component Heat Transfer Characteristics for Reference Home
    # Slab-on-Grade R-Value & Depth (ft)
    if ['1A', '1B', '1C', '2A', '2B', '2C', '3A', '3B', '3C'].include? @iecc_zone
      return 0.0, 0.0
    elsif ['4A', '4B', '4C', '5A', '5B', '5C'].include? @iecc_zone
      return 10.0, 2.0
    elsif ['6A', '6B', '6C', '7', '8'].include? @iecc_zone
      return 10.0, 4.0
    end
  end

  def self.get_reference_slab_under_rvalue_width()
    return 0.0, 0.0
  end

  def self.get_reference_glazing_ufactor_shgc()
    # Table 4.2.2(2) - Component Heat Transfer Characteristics for Reference Home
    # Fenestration and Opaque Door U-Factor
    # Glazed Fenestration Assembly SHGC
    if ['1A', '1B', '1C'].include? @iecc_zone
      return 1.2, 0.40
    elsif ['2A', '2B', '2C'].include? @iecc_zone
      return 0.75, 0.40
    elsif ['3A', '3B', '3C'].include? @iecc_zone
      return 0.65, 0.40
    elsif ['4A', '4B'].include? @iecc_zone
      return 0.40, 0.40
    elsif ['4C', '5A', '5B', '5C', '6A', '6B', '6C', '7', '8'].include? @iecc_zone
      return 0.35, 0.40
    end
  end

  def self.get_reference_wall_ufactor()
    # Table 4.2.2(2) - Component Heat Transfer Characteristics for Reference Home
    # Frame Wall U-Factor
    if ['1A', '1B', '1C', '2A', '2B', '2C', '3A', '3B', '3C', '4A', '4B'].include? @iecc_zone
      return 0.082
    elsif ['4C', '5A', '5B', '5C', '6A', '6B', '6C'].include? @iecc_zone
      return 0.060
    elsif ['7', '8'].include? @iecc_zone
      return 0.057
    end
  end

  def self.get_reference_wall_ufactor_common_space()
    # Table 4.2.2(2) - Component Heat Transfer Characteristics for Reference Home
    # Frame Wall U-Factor
    if ['1A', '1B', '1C', '2A', '2B', '2C'].include? @iecc_zone
      return 0.292
    elsif ['3A', '3B', '3C', '4A', '4B', '4C', '5A', '5B', '5C', '6A', '6B', '6C', '7', '8'].include? @iecc_zone
      return 0.089
    end
  end

  def self.get_reference_door_area(orig_bldg)
    if (Constants::ERIVersions.index(@eri_version) >= Constants::ERIVersions.index('2019')) && (@bldg_type == HPXML::ResidentialTypeApartment)
      total_area = 20.0 # ft2
    else
      total_area = 40.0 # ft2
    end
    if (Constants::ERIVersions.index(@eri_version) >= Constants::ERIVersions.index('2019'))
      # Calculate portion of door area that is exterior by preserving ratio from rated home
      orig_interior_area = orig_bldg.doors.select { |d| d.wall.exterior_adjacent_to == HPXML::LocationOtherHousingUnit }.map { |d| d.area }.sum(0)
      orig_exterior_area = orig_bldg.doors.select { |d| d.is_exterior_thermal_boundary }.map { |d| d.area }.sum(0)
      if orig_interior_area + orig_exterior_area <= 0
        exterior_area = total_area
        interior_area = 0.0
      else
        exterior_area = total_area * orig_exterior_area / (orig_exterior_area + orig_interior_area)
        interior_area = total_area - exterior_area
      end
      return exterior_area, interior_area
    else
      exterior_area = total_area
      interior_area = 0.0
      return exterior_area, interior_area
    end
  end

  def self.get_reference_hvac_airflow_defect_ratio()
    if Constants::ERIVersions.index(@eri_version) >= Constants::ERIVersions.index('2019AB')
      return -0.25
    else
      return 0.0
    end
  end

  def self.get_reference_hvac_fan_watts_per_cfm()
    if Constants::ERIVersions.index(@eri_version) >= Constants::ERIVersions.index('2019AB')
      return 0.58
    else
      return
    end
  end

  def self.get_reference_hvac_charge_defect_ratio()
    if Constants::ERIVersions.index(@eri_version) >= Constants::ERIVersions.index('2019AB')
      return -0.25
    else
      return 0.0
    end
  end

  def self.lookup_egrid_value(egrid_subregion, zip_column_index, output_column_index)
    if Constants::ERIVersions.index(@eri_version) >= Constants::ERIVersions.index('2019ABCD')
      zip_filepath = File.join(File.dirname(__FILE__), '..', 'data', 'egrid', 'egrid2019_summary_tables.csv')
    else
      zip_filepath = File.join(File.dirname(__FILE__), '..', 'data', 'egrid', 'egrid2012_summary_tables.csv')
    end
    CSV.foreach(zip_filepath) do |row|
      next unless row[zip_column_index] == egrid_subregion

      return row[output_column_index]
    end

    return
  end

  def self.add_emissions_scenarios(new_hpxml, new_bldg)
    if not @egrid_subregion.nil?
      new_bldg.egrid_subregion = @egrid_subregion
      new_bldg.egrid_subregion_isdefaulted = true
    end

    if not @cambium_gea.nil?
      new_bldg.cambium_region_gea = @cambium_gea
      new_bldg.cambium_region_gea_isdefaulted = true
    end

    # Fossil fuel values
    if Constants::ERIVersions.index(@eri_version) >= Constants::ERIVersions.index('2019ABC')
      if Constants::ERIVersions.index(@eri_version) >= Constants::ERIVersions.index('2019ABCD')
        # Latest values include pre-combustion for fossil fuels
        co2e_values = { HPXML::FuelTypeNaturalGas => 147.3,
                        HPXML::FuelTypeOil => 195.9,
                        HPXML::FuelTypePropane => 177.8 }
      else
        co2e_values = { HPXML::FuelTypeNaturalGas => 117.6,
                        HPXML::FuelTypeOil => 161.0,
                        HPXML::FuelTypePropane => 136.6 }
      end
      nox_values = { HPXML::FuelTypeNaturalGas => 0.0922,
                     HPXML::FuelTypeOil => 0.1300,
                     HPXML::FuelTypePropane => 0.1421 }
      so2_values = { HPXML::FuelTypeNaturalGas => 0.0006,
                     HPXML::FuelTypeOil => 0.0015,
                     HPXML::FuelTypePropane => 0.0002 }
    else # Before 301-2019 Addendum C
      co2e_values = { HPXML::FuelTypeNaturalGas => 117.6,
                      HPXML::FuelTypeOil => 159.4,
                      HPXML::FuelTypePropane => 136.4 }
      nox_values = { HPXML::FuelTypeNaturalGas => 0.093,
                     HPXML::FuelTypeOil => 0.1278,
                     HPXML::FuelTypePropane => 0.1534 }
      so2_values = { HPXML::FuelTypeNaturalGas => 0.0000,
                     HPXML::FuelTypeOil => 0.5066,
                     HPXML::FuelTypePropane => 0.0163 }
    end

    # CO2e Emissions Scenario
    if Constants::ERIVersions.index(@eri_version) >= Constants::ERIVersions.index('2019ABCD')
      # Use Cambium database for electricity
      if not @cambium_gea.nil?
        cambium_geas = ['AZNMc', 'CAMXc', 'ERCTc', 'FRCCc', 'MROEc', 'MROWc', 'NEWEc', 'NWPPc', 'NYSTc', 'RFCEc',
                        'RFCMc', 'RFCWc', 'RMPAc', 'SPNOc', 'SPSOc', 'SRMVc', 'SRMWc', 'SRSOc', 'SRTVc', 'SRVCc']
        col_num = cambium_geas.index(@cambium_gea) + 5
        cambium_filepath = File.join(File.dirname(__FILE__), '..', 'data', 'cambium', 'RESNET_2021_CO2e_GEAdata.csv')
        new_hpxml.header.emissions_scenarios.add(name: 'ANSI301',
                                                 emissions_type: 'CO2e',
                                                 elec_units: HPXML::EmissionsScenario::UnitsKgPerMWh,
                                                 elec_schedule_filepath: cambium_filepath,
                                                 elec_schedule_number_of_header_rows: 4,
                                                 elec_schedule_column_number: col_num,
                                                 natural_gas_units: HPXML::EmissionsScenario::UnitsLbPerMBtu,
                                                 natural_gas_value: co2e_values[HPXML::FuelTypeNaturalGas],
                                                 propane_units: HPXML::EmissionsScenario::UnitsLbPerMBtu,
                                                 propane_value: co2e_values[HPXML::FuelTypePropane],
                                                 fuel_oil_units: HPXML::EmissionsScenario::UnitsLbPerMBtu,
                                                 fuel_oil_value: co2e_values[HPXML::FuelTypeOil])
      end
    else # Before 301-2019 Addendum D
      # Use EPA's eGrid database for electricity
      if not @egrid_subregion.nil?
        annual_elec_co2e_value = lookup_egrid_value(@egrid_subregion, 0, 1) # lb/mWh
        new_hpxml.header.emissions_scenarios.add(name: 'ANSI301',
                                                 emissions_type: 'CO2e',
                                                 elec_units: HPXML::EmissionsScenario::UnitsLbPerMWh,
                                                 elec_value: annual_elec_co2e_value,
                                                 natural_gas_units: HPXML::EmissionsScenario::UnitsLbPerMBtu,
                                                 natural_gas_value: co2e_values[HPXML::FuelTypeNaturalGas],
                                                 propane_units: HPXML::EmissionsScenario::UnitsLbPerMBtu,
                                                 propane_value: co2e_values[HPXML::FuelTypePropane],
                                                 fuel_oil_units: HPXML::EmissionsScenario::UnitsLbPerMBtu,
                                                 fuel_oil_value: co2e_values[HPXML::FuelTypeOil])
      end
    end

    # NOx Emissions Scenario
    if not @egrid_subregion.nil?
      elec_nox_value = lookup_egrid_value(@egrid_subregion, 0, 5) # lb/mWh
      new_hpxml.header.emissions_scenarios.add(name: 'ANSI301',
                                               emissions_type: 'NOx',
                                               elec_units: HPXML::EmissionsScenario::UnitsLbPerMWh,
                                               elec_value: elec_nox_value,
                                               natural_gas_units: HPXML::EmissionsScenario::UnitsLbPerMBtu,
                                               natural_gas_value: nox_values[HPXML::FuelTypeNaturalGas],
                                               propane_units: HPXML::EmissionsScenario::UnitsLbPerMBtu,
                                               propane_value: nox_values[HPXML::FuelTypePropane],
                                               fuel_oil_units: HPXML::EmissionsScenario::UnitsLbPerMBtu,
                                               fuel_oil_value: nox_values[HPXML::FuelTypeOil])
    end

    # SO2 Emissions Scenario
    if not @egrid_subregion.nil?
      elec_so2_value = lookup_egrid_value(@egrid_subregion, 0, 7) # lb/mWh
      new_hpxml.header.emissions_scenarios.add(name: 'ANSI301',
                                               emissions_type: 'SO2',
                                               elec_units: HPXML::EmissionsScenario::UnitsLbPerMWh,
                                               elec_value: elec_so2_value,
                                               natural_gas_units: HPXML::EmissionsScenario::UnitsLbPerMBtu,
                                               natural_gas_value: so2_values[HPXML::FuelTypeNaturalGas],
                                               propane_units: HPXML::EmissionsScenario::UnitsLbPerMBtu,
                                               propane_value: so2_values[HPXML::FuelTypePropane],
                                               fuel_oil_units: HPXML::EmissionsScenario::UnitsLbPerMBtu,
                                               fuel_oil_value: so2_values[HPXML::FuelTypeOil])
    end
  end

  def self.calc_area_weighted_avg(surfaces, attribute, use_inverse: false, backup_value: nil)
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
    if not backup_value.nil?
      return backup_value
    end

    fail "Unable to calculate area-weighted avg for #{attribute}."
  end

  def self.get_hp_compressor_lockout_temp(heat_pump_type, backup_heating_fuel, compressor_type, compressor_lockout_temp = nil)
    return if heat_pump_type == HPXML::HVACTypeHeatPumpGroundToAir

    # Logic per RESNET HERS Addendum 82
    if backup_heating_fuel == HPXML::FuelTypeElectricity
      # Use user input if provided
      if not compressor_lockout_temp.nil?
        return compressor_lockout_temp
      end

      # No user input, default
      if compressor_type == HPXML::HVACCompressorTypeVariableSpeed
        return -20.0 # F
      else
        return 0.0 # F
      end
    else # Fossil fuel
      # Use RESNET prescribed value
      return 40.0 # F
    end
  end

  def self.get_hp_backup_heating_lockout_temp(heat_pump_type)
    return if heat_pump_type == HPXML::HVACTypeHeatPumpGroundToAir

    return 80.0 # F, effectively disables the lockout temp
  end

  def self.get_hp_backup_heating_active_during_defrost(heat_pump_type, backup_type)
    # Logic per RESNET HERS Addendum 82
    # For the Rated Home, backup heat should be active during defrost only if
    # the system has supplemental heating.
    # For the Reference Home, backup heat should always be active during defrost
    # because the heat pump represents a conventional ducted system.
    return if heat_pump_type == HPXML::HVACTypeHeatPumpGroundToAir

    return backup_type == HPXML::HeatPumpBackupTypeIntegrated
  end
end
