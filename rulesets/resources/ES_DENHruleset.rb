# frozen_string_literal: true

module ES_DENH_Ruleset
  def self.apply_ruleset(hpxml, calc_type, program_version, eri_version, lookup_program_data)
    @eri_version = eri_version
    hpxml.header.eri_calculation_versions = [@eri_version]
    hpxml.header.co2index_calculation_versions = nil
    hpxml.header.iecc_eri_calculation_versions = nil
    hpxml.header.energystar_calculation_versions = nil
    hpxml.header.denh_calculation_versions = nil

    @program_version = program_version

    if [ES::SFNationalVer3_3, ES::SFNationalVer3_2, ES::MFNationalVer1_3,
        ES::MFNationalVer1_2, DENH::SFVer2, DENH::MFVer2].include? @program_version
      # Use Year=2021 for Reference Home configuration
      iecc_climate_zone_year = 2021
    elsif [DENH::Ver1].include? @program_version
      # Use Year=2015 for Reference Home configuration
      iecc_climate_zone_year = 2015
    elsif [ES::SFNationalVer3_1, ES::MFNationalVer1_1, ES::SFOregonWashingtonVer3_2,
           ES::MFOregonWashingtonVer1_2].include? @program_version
      # Use Year=2012 for Reference Home configuration
      iecc_climate_zone_year = 2012
    elsif [ES::SFNationalVer3_0, ES::SFPacificVer3_0, ES::SFFloridaVer3_1,
           ES::MFNationalVer1_0].include? @program_version
      # Use Year=2006 for Reference Home configuration
      iecc_climate_zone_year = 2006
    else
      fail "Need to handle IECC climate zone mapping for program version '#{@program_version}'."
    end
    @iecc_zone, _year = get_climate_zone_of_year(hpxml.buildings[0], iecc_climate_zone_year)
    @lookup_program_data = lookup_program_data

    # Update HPXML object based on ESRD configuration
    if calc_type == InitCalcType::TargetHome
      hpxml = apply_ruleset_reference(hpxml)
    end

    return hpxml
  end

  def self.apply_ruleset_reference(orig_hpxml)
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
    set_systems_hvac_reference(orig_bldg, new_bldg)
    set_systems_mechanical_ventilation_reference(new_bldg)
    set_systems_whole_house_fan_reference(orig_bldg, new_bldg)
    set_systems_water_heater_reference(orig_bldg, new_bldg)
    set_systems_water_heating_use_reference(orig_bldg, new_bldg)
    set_systems_solar_thermal_reference(orig_bldg, new_bldg)
    set_systems_photovoltaics_reference(orig_bldg, new_bldg)
    set_systems_batteries_reference(orig_bldg, new_bldg)
    set_systems_generators_reference(orig_bldg, new_bldg)

    # Appliances
    set_appliances_clothes_washer_reference(orig_bldg, new_bldg)
    set_appliances_clothes_dryer_reference(orig_bldg, new_bldg)
    set_appliances_dishwasher_reference(orig_bldg, new_bldg)
    set_appliances_refrigerator_reference(orig_bldg, new_bldg)
    set_appliances_dehumidifier_reference(orig_bldg, new_bldg)
    set_appliances_cooking_range_oven_reference(orig_bldg, new_bldg)

    # Lighting
    set_lighting_reference(new_bldg)
    set_ceiling_fans_reference(orig_bldg, new_bldg)

    # MiscLoads
    set_misc_loads_reference(orig_bldg, new_bldg)

    return new_hpxml
  end

  def self.create_new_hpxml(orig_hpxml)
    new_hpxml = HPXML.new

    new_hpxml.header.xml_type = orig_hpxml.header.xml_type
    new_hpxml.header.xml_generated_by = File.basename(__FILE__)
    new_hpxml.header.transaction = orig_hpxml.header.transaction
    new_hpxml.header.software_program_used = orig_hpxml.header.software_program_used
    new_hpxml.header.software_program_version = orig_hpxml.header.software_program_version
    new_hpxml.header.eri_calculation_versions = orig_hpxml.header.eri_calculation_versions

    orig_bldg = orig_hpxml.buildings[0]
    new_hpxml.buildings.add(building_id: orig_bldg.building_id)
    new_bldg = new_hpxml.buildings[0]

    new_bldg.event_type = orig_bldg.event_type
    new_bldg.state_code = orig_bldg.state_code
    new_bldg.zip_code = orig_bldg.zip_code

    return new_hpxml
  end

  def self.set_summary_reference(orig_bldg, new_bldg)
    # Global variables
    @state_code = orig_bldg.state_code
    @bldg_type = orig_bldg.building_construction.residential_facility_type
    @cfa = orig_bldg.building_construction.conditioned_floor_area
    @nbeds = orig_bldg.building_construction.number_of_bedrooms
    @ncfl = orig_bldg.building_construction.number_of_conditioned_floors
    @ncfl_ag = orig_bldg.building_construction.number_of_conditioned_floors_above_grade
    @cvolume = orig_bldg.building_construction.conditioned_building_volume
    @infilvolume = get_infiltration_volume(orig_bldg)
    @infilheight = get_infiltration_height(orig_bldg)
    @has_cond_bsmnt = orig_bldg.has_location(HPXML::LocationBasementConditioned)
    @has_uncond_bsmnt = orig_bldg.has_location(HPXML::LocationBasementUnconditioned)
    @has_auto_generated_attic = false

    new_bldg.site.available_fuels = orig_bldg.site.available_fuels

    new_bldg.building_construction.residential_facility_type = orig_bldg.building_construction.residential_facility_type
    new_bldg.building_construction.number_of_conditioned_floors = orig_bldg.building_construction.number_of_conditioned_floors
    new_bldg.building_construction.number_of_conditioned_floors_above_grade = orig_bldg.building_construction.number_of_conditioned_floors_above_grade
    new_bldg.building_construction.number_of_bedrooms = orig_bldg.building_construction.number_of_bedrooms
    new_bldg.building_construction.conditioned_floor_area = orig_bldg.building_construction.conditioned_floor_area
    new_bldg.building_construction.conditioned_building_volume = orig_bldg.building_construction.conditioned_building_volume
  end

  def self.set_climate(orig_bldg, new_bldg)
    # Set 2006 IECC zone for downstream ERI calculation
    iecc_climate_zone, year = get_climate_zone_of_year(orig_bldg, 2006)
    new_bldg.climate_and_risk_zones.climate_zone_ieccs.add(year: year,
                                                           zone: iecc_climate_zone)
    new_bldg.climate_and_risk_zones.weather_station_id = orig_bldg.climate_and_risk_zones.weather_station_id
    new_bldg.climate_and_risk_zones.weather_station_name = orig_bldg.climate_and_risk_zones.weather_station_name
    new_bldg.climate_and_risk_zones.weather_station_wmo = orig_bldg.climate_and_risk_zones.weather_station_wmo
    new_bldg.climate_and_risk_zones.weather_station_epw_filepath = orig_bldg.climate_and_risk_zones.weather_station_epw_filepath
  end

  def self.set_enclosure_air_infiltration_reference(orig_bldg, new_bldg)
    # Exhibit 2 - Infiltration
    infil_air_leakage, infil_unit_of_measure = get_enclosure_air_infiltration_default(orig_bldg)

    # Air Infiltration
    new_bldg.air_infiltration_measurements.add(id: 'TargetInfiltration',
                                               house_pressure: 50,
                                               unit_of_measure: infil_unit_of_measure,
                                               air_leakage: infil_air_leakage.round(2),
                                               infiltration_volume: @infilvolume,
                                               infiltration_height: @infilheight)
  end

  def self.set_enclosure_attics_reference(orig_bldg, new_bldg)
    has_attic = (orig_bldg.has_location(HPXML::LocationAtticVented) || orig_bldg.has_location(HPXML::LocationAtticUnvented))

    vented_attic = lookup_reference_value('vented_attic', @bldg_type)
    vented_attic = lookup_reference_value('vented_attic') if vented_attic.nil?

    set_vented_attic = false
    if vented_attic == 'if has attic or duct location'
      # A vented unconditioned attic shall only be modeled in the Multifamily Reference Design where attics (of any type)
      # exist in the Rated Unit or when specified as the Duct Location in the Thermal Distribution Systems section
      if has_attic
        set_vented_attic = true
      else
        duct_locations = get_duct_location_areas(orig_bldg, 1.0).keys
        if duct_locations.include? HPXML::LocationAtticVented
          set_vented_attic = true
        end
      end
    elsif vented_attic == 'always'
      set_vented_attic = true
    else
      fail 'Unexpected case.'
    end

    if set_vented_attic
      new_bldg.attics.add(id: 'TargetVentedAttic',
                          attic_type: HPXML::AtticTypeVented)
      @has_auto_generated_attic = true unless has_attic
    end
  end

  def self.set_enclosure_foundations_reference(orig_bldg, new_bldg)
    # Check if vented crawlspace (or unvented crawlspace, which will become a vented crawlspace) exists
    orig_bldg.floors.each do |orig_floor|
      next unless orig_floor.interior_adjacent_to.include?('crawlspace') || orig_floor.exterior_adjacent_to.include?('crawlspace')

      new_bldg.foundations.add(id: 'TargetVentedCrawlspace',
                               foundation_type: HPXML::FoundationTypeCrawlspaceVented)
      break
    end

    # For unconditioned basement, set within infiltration volume input
    orig_bldg.foundations.each do |orig_foundation|
      next unless orig_foundation.foundation_type == HPXML::FoundationTypeBasementUnconditioned

      new_bldg.foundations.add(id: orig_foundation.id,
                               foundation_type: orig_foundation.foundation_type,
                               within_infiltration_volume: false)
    end
  end

  def self.set_enclosure_roofs_reference(orig_bldg, new_bldg)
    # Exhibit 2 - Roofs
    radiant_barrier_bool = get_radiant_barrier_bool(orig_bldg)
    radiant_barrier_grade = 1 if radiant_barrier_bool
    ceiling_ufactor = lookup_reference_value('ceiling_ufactor')

    solar_absorptance = lookup_reference_value('roof_solar_abs')
    emittance = lookup_reference_value('roof_emittance')
    default_roof_pitch = 5.0 # assume 5:12 pitch
    has_vented_attic = (new_bldg.attics.select { |a| a.attic_type == HPXML::AtticTypeVented }.size > 0)

    orig_bldg.roofs.each do |orig_roof|
      roof_pitch = orig_roof.pitch
      roof_interior_adjacent_to = orig_roof.interior_adjacent_to.gsub('unvented', 'vented')
      if orig_roof.interior_adjacent_to == HPXML::LocationConditionedSpace && has_vented_attic
        roof_interior_adjacent_to = HPXML::LocationAtticVented
        roof_pitch = default_roof_pitch if roof_pitch == 0
      end
      if roof_interior_adjacent_to != HPXML::LocationConditionedSpace
        insulation_assembly_r_value = [orig_roof.insulation_assembly_r_value, 2.3].min # uninsulated
      else
        insulation_assembly_r_value = (1.0 / ceiling_ufactor).round(3)
      end

      new_bldg.roofs.add(id: orig_roof.id,
                         interior_adjacent_to: roof_interior_adjacent_to,
                         area: orig_roof.area,
                         azimuth: orig_roof.azimuth,
                         solar_absorptance: solar_absorptance,
                         emittance: emittance,
                         pitch: roof_pitch,
                         radiant_barrier: radiant_barrier_bool,
                         radiant_barrier_grade: radiant_barrier_grade,
                         insulation_id: orig_roof.insulation_id,
                         insulation_assembly_r_value: insulation_assembly_r_value)
    end

    # Add a roof above the vented attic that is newly added to Reference Design
    if @has_auto_generated_attic
      orig_bldg.floors.each do |orig_floor|
        next unless orig_floor.is_ceiling
        next unless multifamily_adjacent_locations.include? orig_floor.exterior_adjacent_to

        # Estimate the area of the roof based on the floor area and pitch
        pitch_to_radians = Math.atan(default_roof_pitch / 12.0)
        roof_area = orig_floor.area / Math.cos(pitch_to_radians)

        new_bldg.roofs.add(id: "TargetRoof#{new_bldg.roofs.size + 1}",
                           interior_adjacent_to: HPXML::LocationAtticVented,
                           area: roof_area,
                           azimuth: nil,
                           solar_absorptance: solar_absorptance,
                           emittance: emittance,
                           pitch: default_roof_pitch,
                           radiant_barrier: radiant_barrier_bool,
                           radiant_barrier_grade: radiant_barrier_grade,
                           insulation_id: "TargetRoof#{new_bldg.roofs.size + 1}Insulation",
                           insulation_assembly_r_value: 2.3) # Assumes that the roof is uninsulated
      end
    end
  end

  def self.set_enclosure_rim_joists_reference(orig_bldg, new_bldg)
    ufactor = get_enclosure_walls_default_ufactor()

    ext_thermal_bndry_rim_joists = orig_bldg.rim_joists.select { |rim_joist| rim_joist.is_exterior && rim_joist.is_thermal_boundary }

    ext_thermal_bndry_rim_joists_ag = ext_thermal_bndry_rim_joists.select { |rim_joist| rim_joist.interior_adjacent_to == HPXML::LocationConditionedSpace }
    sum_gross_area_ag = ext_thermal_bndry_rim_joists_ag.map { |rim_joist| rim_joist.area }.sum(0)

    ext_thermal_bndry_rim_joists_bg = ext_thermal_bndry_rim_joists.select { |rim_joist| rim_joist.interior_adjacent_to == HPXML::LocationBasementConditioned }
    sum_gross_area_bg = ext_thermal_bndry_rim_joists_bg.map { |rim_joist| rim_joist.area }.sum(0)

    solar_absorptance = lookup_reference_value('walls_solar_abs')
    emittance = lookup_reference_value('walls_emittance')

    # Create insulated rim joists for exterior thermal boundary surface.
    # Area is equally distributed to each direction to be consistent with walls.
    # Need to preserve above-grade vs below-grade for inferred infiltration height.
    if sum_gross_area_ag > 0
      new_bldg.rim_joists.add(id: 'TargetRimJoist',
                              exterior_adjacent_to: HPXML::LocationOutside,
                              interior_adjacent_to: HPXML::LocationConditionedSpace,
                              area: sum_gross_area_ag,
                              azimuth: nil,
                              solar_absorptance: solar_absorptance,
                              emittance: emittance,
                              insulation_assembly_r_value: (1.0 / ufactor).round(3))
    end
    if sum_gross_area_bg > 0
      new_bldg.rim_joists.add(id: 'TargetRimJoistBasement',
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

      if orig_rim_joist.is_thermal_boundary && (not multifamily_adjacent_locations.include?(orig_rim_joist.exterior_adjacent_to))
        insulation_assembly_r_value = (1.0 / ufactor).round(3)
      else
        insulation_assembly_r_value = [orig_rim_joist.insulation_assembly_r_value, 4.0].min # uninsulated
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

  def self.set_enclosure_walls_reference(orig_bldg, new_bldg)
    # Exhibit 2 - Above-grade Walls U-factor
    ufactor = get_enclosure_walls_default_ufactor()

    ext_thermal_bndry_walls = orig_bldg.walls.select { |wall| wall.is_exterior_thermal_boundary }
    sum_gross_area = ext_thermal_bndry_walls.map { |wall| wall.area }.sum(0)

    solar_absorptance = lookup_reference_value('walls_solar_abs')
    emittance = lookup_reference_value('walls_emittance')

    # Create thermal boundary wall area
    if sum_gross_area > 0
      new_bldg.walls.add(id: 'TargetWall',
                         exterior_adjacent_to: HPXML::LocationOutside,
                         interior_adjacent_to: HPXML::LocationConditionedSpace,
                         wall_type: HPXML::WallTypeWoodStud,
                         area: sum_gross_area,
                         azimuth: nil,
                         solar_absorptance: solar_absorptance,
                         emittance: emittance,
                         insulation_assembly_r_value: (1.0 / ufactor).round(3))
    end

    # Preserve exterior walls that are not thermal boundary walls (e.g., unconditioned attic gable walls or exterior garage walls). These walls are specified as uninsulated.
    # Preserve thermal boundary walls that are not exterior (e.g., garage wall adjacent to conditioned space). These walls are assigned the appropriate U-factor from the Energy Star Exhibit 2 (Expanded ENERGY STAR Reference Design Definition).
    # The purpose of this is to be consistent with other software tools.
    orig_bldg.walls.each do |orig_wall|
      next if orig_wall.is_exterior_thermal_boundary

      if orig_wall.is_thermal_boundary && (not multifamily_adjacent_locations.include?(orig_wall.exterior_adjacent_to))
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

  def self.set_enclosure_foundation_walls_reference(orig_bldg, new_bldg)
    # Exhibit 2 - Foundation walls U-factor/R-value
    fndwall_assembly_uvalue = lookup_reference_value('foundation_walls_ufactor')
    fndwall_interior_ins_rvalue = lookup_reference_value('foundation_walls_rvalue')

    # Exhibit 2 - Conditioned basement walls
    orig_bldg.foundation_walls.each do |orig_foundation_wall|
      # Insulated for, e.g., conditioned basement walls adjacent to ground.
      # Uninsulated for, e.g., crawlspace/unconditioned basement walls adjacent to ground.
      if orig_foundation_wall.is_thermal_boundary
        if not fndwall_assembly_uvalue.nil?
          insulation_assembly_r_value = (1.0 / fndwall_assembly_uvalue).round(3)
        elsif not fndwall_interior_ins_rvalue.nil?
          insulation_interior_r_value = fndwall_interior_ins_rvalue
          insulation_interior_distance_to_top = 0
          insulation_interior_distance_to_bottom = orig_foundation_wall.height
          insulation_exterior_r_value = 0
          insulation_exterior_distance_to_top = 0
          insulation_exterior_distance_to_bottom = 0
        end
      else
        # uninsulated
        insulation_interior_r_value = 0
        insulation_interior_distance_to_top = 0
        insulation_interior_distance_to_bottom = 0
        insulation_exterior_r_value = 0
        insulation_exterior_distance_to_top = 0
        insulation_exterior_distance_to_bottom = 0
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
                                    insulation_interior_distance_to_top: insulation_interior_distance_to_top,
                                    insulation_interior_distance_to_bottom: insulation_interior_distance_to_bottom,
                                    insulation_exterior_r_value: insulation_exterior_r_value,
                                    insulation_exterior_distance_to_top: insulation_exterior_distance_to_top,
                                    insulation_exterior_distance_to_bottom: insulation_exterior_distance_to_bottom,
                                    insulation_assembly_r_value: insulation_assembly_r_value)
    end
  end

  def self.set_enclosure_ceilings_reference(orig_bldg, new_bldg)
    ceiling_ufactor = lookup_reference_value('ceiling_ufactor')

    # Exhibit 2 - Ceilings
    orig_bldg.floors.each do |orig_floor|
      next unless orig_floor.is_ceiling

      if orig_floor.is_thermal_boundary && (not multifamily_adjacent_locations.include?(orig_floor.exterior_adjacent_to))
        insulation_assembly_r_value = (1.0 / ceiling_ufactor).round(3)
      else
        insulation_assembly_r_value = [orig_floor.insulation_assembly_r_value, 2.1].min # uninsulated
      end

      ceiling_exterior_adjacent_to = orig_floor.exterior_adjacent_to.gsub('unvented', 'vented')
      if @has_auto_generated_attic && multifamily_adjacent_locations.include?(orig_floor.exterior_adjacent_to)
        ceiling_exterior_adjacent_to = HPXML::LocationAtticVented
        insulation_assembly_r_value = (1.0 / ceiling_ufactor).round(3)
      end

      new_bldg.floors.add(id: orig_floor.id,
                          exterior_adjacent_to: ceiling_exterior_adjacent_to,
                          interior_adjacent_to: orig_floor.interior_adjacent_to.gsub('unvented', 'vented'),
                          floor_or_ceiling: orig_floor.floor_or_ceiling,
                          floor_type: orig_floor.floor_type,
                          area: orig_floor.area,
                          insulation_id: orig_floor.insulation_id,
                          insulation_assembly_r_value: insulation_assembly_r_value)
    end

    # Add a floor between the vented attic and conditioned space
    if @has_auto_generated_attic
      orig_bldg.roofs.each do |orig_roof|
        next unless orig_roof.is_exterior_thermal_boundary

        # Estimate the area of the floor based on the roof area and pitch
        pitch_to_radians = Math.atan(orig_roof.pitch / 12.0)
        floor_area = orig_roof.area * Math.cos(pitch_to_radians)

        new_bldg.floors.add(id: "TargetFloor#{new_bldg.floors.size + 1}",
                            exterior_adjacent_to: HPXML::LocationAtticVented,
                            interior_adjacent_to: HPXML::LocationConditionedSpace,
                            floor_type: HPXML::FloorTypeWoodFrame,
                            area: floor_area,
                            insulation_id: "TargetFloor#{new_bldg.floors.size + 1}Insulation",
                            insulation_assembly_r_value: (1.0 / ceiling_ufactor).round(3))
      end
    end
  end

  def self.set_enclosure_floors_reference(orig_bldg, new_bldg)
    # Exhibit 2 - Floors over unconditioned spaces
    orig_bldg.floors.each do |orig_floor|
      next unless orig_floor.is_floor

      subtype = orig_floor.floor_type == HPXML::FloorTypeConcrete ? 'mass' : 'wood'
      floor_ufactor = lookup_reference_value('floors_ufactor', subtype)
      floor_ufactor = lookup_reference_value('floors_ufactor') if floor_ufactor.nil?

      subtype = orig_floor.exterior_adjacent_to
      floor_insulated = lookup_reference_value('floors_insulated', subtype)
      floor_insulated = true if floor_insulated.nil?

      if orig_floor.is_thermal_boundary && floor_insulated
        # This is meant to apply to floors over unconditioned spaces, non-freezing spaces, unrated heated spaces, multifamily buffer boundaries, or the outdoor environment
        insulation_assembly_r_value = (1.0 / floor_ufactor).round(3)
      else
        insulation_assembly_r_value = [orig_floor.insulation_assembly_r_value, 3.1].min # uninsulated
      end

      new_bldg.floors.add(id: orig_floor.id,
                          exterior_adjacent_to: orig_floor.exterior_adjacent_to.gsub('unvented', 'vented'),
                          interior_adjacent_to: orig_floor.interior_adjacent_to.gsub('unvented', 'vented'),
                          floor_or_ceiling: orig_floor.floor_or_ceiling,
                          floor_type: orig_floor.floor_type,
                          area: orig_floor.area,
                          insulation_id: orig_floor.insulation_id,
                          insulation_assembly_r_value: insulation_assembly_r_value)
    end
  end

  def self.set_enclosure_slabs_reference(orig_bldg, new_bldg)
    slab_perim_rvalue = lookup_reference_value('slab_perimeter_ins_rvalue')
    slab_perim_depth = lookup_reference_value('slab_perimeter_ins_depth')
    slab_under_rvalue = lookup_reference_value('slab_under_ins_rvalue')
    slab_under_width = lookup_reference_value('slab_under_ins_width')
    is_under_entire_slab_insulated = nil

    # Exhibit 2 - Foundations
    orig_bldg.slabs.each do |orig_slab|
      if orig_slab.interior_adjacent_to == HPXML::LocationConditionedSpace
        if slab_under_width >= 999
          is_under_entire_slab_insulated = true
          slab_under_width = nil
        end
        if (not slab_perim_rvalue.nil?) && slab_perim_depth.nil?
          slab_perim_depth = orig_slab.thickness.nil? ? 4.0 : orig_slab.thickness
        end
        perimeter_insulation_depth = slab_perim_depth
        under_slab_insulation_width = slab_under_width
        perimeter_insulation_r_value = slab_perim_rvalue
        under_slab_insulation_r_value = slab_under_rvalue
      else
        perimeter_insulation_depth = 0
        under_slab_insulation_width = 0
        perimeter_insulation_r_value = 0
        under_slab_insulation_r_value = 0
      end

      if [HPXML::LocationConditionedSpace, HPXML::LocationBasementConditioned].include? orig_slab.interior_adjacent_to
        carpet_fraction = 0.8
        carpet_r_value = 2.0
      else
        carpet_fraction = orig_slab.carpet_fraction
        carpet_r_value = orig_slab.carpet_r_value
      end
      new_bldg.slabs.add(id: orig_slab.id,
                         interior_adjacent_to: orig_slab.interior_adjacent_to.gsub('unvented', 'vented'),
                         area: orig_slab.area,
                         thickness: orig_slab.thickness,
                         exposed_perimeter: orig_slab.exposed_perimeter,
                         perimeter_insulation_depth: perimeter_insulation_depth,
                         under_slab_insulation_width: under_slab_insulation_width,
                         under_slab_insulation_spans_entire_slab: is_under_entire_slab_insulated,
                         depth_below_grade: orig_slab.depth_below_grade,
                         carpet_fraction: carpet_fraction,
                         carpet_r_value: carpet_r_value,
                         perimeter_insulation_id: orig_slab.perimeter_insulation_id,
                         perimeter_insulation_r_value: perimeter_insulation_r_value,
                         under_slab_insulation_id: orig_slab.under_slab_insulation_id,
                         under_slab_insulation_r_value: under_slab_insulation_r_value)
    end
  end

  def self.set_enclosure_windows_reference(orig_bldg, new_bldg)
    # Exhibit 2 - Glazing

    # Calculate the ratio of the glazing area to the conditioned floor area
    ext_thermal_bndry_windows = orig_bldg.windows.select { |window| window.wall.is_exterior_thermal_boundary }
    orig_total_win_area = ext_thermal_bndry_windows.map { |window| window.area }.sum(0)
    window_to_cfa_ratio = orig_total_win_area / @cfa

    # Preserve operable window fraction for natural ventilation
    fraction_operable = orig_bldg.fraction_of_windows_operable()

    window_area = lookup_reference_value('window_area')

    wall = new_bldg.walls.find { |w| w.interior_adjacent_to == HPXML::LocationConditionedSpace && w.exterior_adjacent_to == HPXML::LocationOutside }

    # Calculate the window area
    if window_area == 'same as rated, with exceptions'
      if @has_cond_bsmnt || [HPXML::ResidentialTypeSFA, HPXML::ResidentialTypeApartment].include?(@bldg_type)
        # For homes with conditioned basements and attached homes:
        total_win_area = calc_default_total_win_area(orig_bldg, @cfa)
        each_win_area = total_win_area * 0.25 # equally distributed to North, East, South, and West
      else
        if window_to_cfa_ratio < 0.15
          each_win_area = orig_total_win_area * 0.25 # Same as Rated Home (equally distributed to North, East, South, and West)
        else
          each_win_area = 0.15 * @cfa * 0.25 # 15% of the conditioned floor area (equally distributed to North, East, South, and West)
        end
      end

      # Windows equally distributed to North, East, South, and West
      win_ufactor, win_shgc = get_reference_glazing_ufactor_shgc(nil)
      for orientation, azimuth in { 'North' => 0, 'South' => 180, 'East' => 90, 'West' => 270 }
        next if each_win_area <= 0.1

        new_bldg.windows.add(id: "TargetWindow#{orientation}",
                             area: each_win_area.round(2),
                             azimuth: azimuth,
                             ufactor: win_ufactor,
                             shgc: win_shgc,
                             attached_to_wall_idref: wall.id,
                             performance_class: HPXML::WindowClassResidential,
                             fraction_operable: fraction_operable)
      end
    elsif window_area == '0.15 x CFA x FA x F'
      total_win_area = calc_default_total_win_area(orig_bldg, @cfa)

      # Orientation same as Rated Unit, by percentage of area
      orig_bldg.windows.each do |win|
        next unless win.wall.is_exterior_thermal_boundary

        win_area = win.area * total_win_area / orig_total_win_area
        win_ufactor, win_shgc = get_reference_glazing_ufactor_shgc(win)

        new_bldg.windows.add(id: win.id,
                             area: win_area.round(2),
                             azimuth: win.azimuth,
                             ufactor: win_ufactor,
                             shgc: win_shgc,
                             attached_to_wall_idref: wall.id,
                             performance_class: win.performance_class.nil? ? HPXML::WindowClassResidential : win.performance_class,
                             fraction_operable: fraction_operable)
      end
    else
      fail 'Unexpected case.'
    end
  end

  def self.set_enclosure_skylights_reference(orig_bldg, new_bldg)
    # Exhibit 2 - Skylights
    # nop
  end

  def self.set_enclosure_doors_reference(orig_bldg, new_bldg)
    # Exhibit 2 - Doors
    # The door type is assumed to be opaque
    door_ufactor = lookup_reference_value('door_ufactor')

    wall = new_bldg.walls.find { |w| w.interior_adjacent_to == HPXML::LocationConditionedSpace && w.exterior_adjacent_to == HPXML::LocationOutside }

    orig_bldg.doors.each do |orig_door|
      new_bldg.doors.add(id: orig_door.id,
                         attached_to_wall_idref: wall.id,
                         area: orig_door.area,
                         azimuth: orig_door.azimuth,
                         r_value: (1.0 / door_ufactor).round(3))
    end
  end

  def self.set_systems_hvac_reference(orig_bldg, new_bldg)
    # Exhibit 2 - Heating and Cooling Systems
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

        if heating_system_type == HPXML::HVACTypeBoiler && heating_fuel != HPXML::FuelTypeElectricity
          add_reference_boiler(new_bldg, heating_system)
        elsif heating_fuel == HPXML::FuelTypeElectricity
          if not cooling_system.nil?
            fraction_cool_load_served = cooling_system.fraction_cool_load_served
          else
            fraction_cool_load_served = 0.0
          end
          created_hp = true
          add_reference_heat_pump(orig_bldg, new_bldg, fraction_heat_load_served, fraction_cool_load_served, heating_system)
        else
          add_reference_furnace(orig_bldg, new_bldg, fraction_heat_load_served, heating_system, heating_fuel)
        end
      end

      if not cooling_system.nil?
        if created_hp
          # Already created HP above
        elsif cooling_system.is_a?(HPXML::CoolingSystem) && (cooling_system.cooling_system_type == HPXML::HVACTypeChiller || cooling_system.cooling_system_type == HPXML::HVACTypeCoolingTower)
          add_reference_chiller_or_cooling_tower(new_bldg, cooling_system)
        else
          add_reference_air_conditioner(orig_bldg, new_bldg, cooling_system.fraction_cool_load_served, cooling_system)
        end
      end

      if not heat_pump.nil?
        add_reference_heat_pump(orig_bldg, new_bldg, heat_pump.fraction_heat_load_served, heat_pump.fraction_cool_load_served, heat_pump)
      end
    end

    # Exhibit 2 - Thermostat
    new_bldg.hvac_controls.add(id: 'TargetHVACControl',
                               control_type: HPXML::HVACControlTypeProgrammable)

    # Exhibit 2 - Thermal distribution systems
    remaining_cfa_served_heating = @cfa # init
    remaining_cfa_served_cooling = @cfa # init
    remaining_fracload_served_heating = 1.0 # init
    remaining_fracload_served_cooling = 1.0 # init
    num_ducts = 0
    orig_bldg.hvac_systems.each do |h|
      next if h.distribution_system_idref.nil?

      if h.respond_to?(:fraction_heat_load_served) && h.fraction_heat_load_served.to_f > 0
        remaining_cfa_served_heating -= h.distribution_system.conditioned_floor_area_served.to_f
        remaining_fracload_served_heating -= h.fraction_heat_load_served
      end
      if h.respond_to?(:fraction_cool_load_served) && h.fraction_cool_load_served.to_f > 0
        remaining_cfa_served_cooling -= h.distribution_system.conditioned_floor_area_served.to_f
        remaining_fracload_served_cooling -= h.fraction_cool_load_served
      end
    end
    orig_bldg.hvac_distributions.each do |orig_hvac_distribution|
      new_bldg.hvac_distributions.add(id: orig_hvac_distribution.id,
                                      distribution_system_type: orig_hvac_distribution.distribution_system_type,
                                      conditioned_floor_area_served: orig_hvac_distribution.conditioned_floor_area_served,
                                      number_of_return_registers: orig_hvac_distribution.number_of_return_registers,
                                      hydronic_type: orig_hvac_distribution.hydronic_type,
                                      air_type: orig_hvac_distribution.air_type,
                                      annual_heating_dse: orig_hvac_distribution.annual_heating_dse,
                                      annual_cooling_dse: orig_hvac_distribution.annual_cooling_dse)
      new_hvac_dist = new_bldg.hvac_distributions[-1]

      next unless new_hvac_dist.distribution_system_type == HPXML::HVACDistributionTypeAir

      if new_hvac_dist.number_of_return_registers.nil?
        new_hvac_dist.number_of_return_registers = 1 # EPA guidance
      end
      new_hvac_dist.number_of_return_registers = [1, new_hvac_dist.number_of_return_registers].max # Ensure at least 1 register

      if new_hvac_dist.conditioned_floor_area_served.nil?
        # Estimate CFA served
        # This methodology tries to prevent the possibility of sum(CFAServed) > CFA in the ESRD,
        # which would generate an error downstream in the ENERGY STAR calculation.
        estd_cfa_heated = @cfa
        estd_cfa_cooled = @cfa
        new_hvac_dist.hvac_systems.each do |h|
          if h.respond_to?(:fraction_heat_load_served) && h.fraction_heat_load_served.to_f > 0
            estd_cfa_heated = remaining_cfa_served_heating * [h.fraction_heat_load_served / remaining_fracload_served_heating, 1.0].min
          end
          if h.respond_to?(:fraction_cool_load_served) && h.fraction_cool_load_served.to_f > 0
            estd_cfa_cooled = remaining_cfa_served_cooling * [h.fraction_cool_load_served / remaining_fracload_served_cooling, 1.0].min
          end
        end
        new_hvac_dist.conditioned_floor_area_served = [estd_cfa_heated.to_f, estd_cfa_cooled.to_f].min
      end

      # Duct leakage to outside calculated based on conditioned floor area served
      total_duct_lto_cfm25 = calc_default_duct_lto_cfm25(new_hvac_dist.conditioned_floor_area_served)

      [HPXML::DuctTypeSupply, HPXML::DuctTypeReturn].each do |duct_type|
        # Split the total duct leakage to outside evenly and assign it to supply ducts and return ducts
        duct_lto_cfm25 = total_duct_lto_cfm25 * 0.5

        new_hvac_dist.duct_leakage_measurements.add(duct_type: duct_type,
                                                    duct_leakage_units: HPXML::UnitsCFM25,
                                                    duct_leakage_value: duct_lto_cfm25,
                                                    duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside)

        # ASHRAE 152 duct area calculation based on conditioned floor area served
        primary_duct_area, secondary_duct_area = Defaults.get_duct_surface_area(duct_type, nil, @ncfl, @ncfl_ag, new_hvac_dist.conditioned_floor_area_served, new_hvac_dist.number_of_return_registers) # sqft
        total_duct_area = primary_duct_area + secondary_duct_area

        duct_location_areas = get_duct_location_areas(orig_bldg, total_duct_area)

        duct_location_areas.each do |duct_location, duct_surface_area|
          num_ducts += 1
          duct_insulation_r_value = get_duct_insulation_r_value(duct_type, duct_location)
          new_hvac_dist.ducts.add(id: "TargetDuct#{num_ducts}",
                                  duct_type: duct_type,
                                  duct_insulation_r_value: duct_insulation_r_value,
                                  duct_location: duct_location,
                                  duct_surface_area: duct_surface_area.round(2))
        end
      end
    end
  end

  def self.set_systems_mechanical_ventilation_reference(new_bldg)
    # Exhibit 2 - Whole-House Mechanical ventilation
    fan_cfm = 0.01 * @cfa + 7.5 * (@nbeds + 1) # cfm
    fan_type = lookup_reference_value('mechanical_ventilation_fan_type')
    fan_cfm_per_w = lookup_reference_value('mechanical_ventilation_fan_cfm_per_w')
    fan_sre = lookup_reference_value('mechanical_ventilation_fan_sre')
    fan_asre = lookup_reference_value('mechanical_ventilation_fan_asre')
    fan_power_w = fan_cfm / fan_cfm_per_w

    new_bldg.ventilation_fans.add(id: 'TargetVentilationFan',
                                  is_shared_system: false,
                                  fan_type: fan_type,
                                  tested_flow_rate: fan_cfm.round(2),
                                  hours_in_operation: 24,
                                  fan_power: fan_power_w.round(3),
                                  sensible_recovery_efficiency: fan_sre,
                                  sensible_recovery_efficiency_adjusted: fan_asre,
                                  used_for_whole_building_ventilation: true)
  end

  def self.set_systems_whole_house_fan_reference(orig_bldg, new_bldg)
    # nop
  end

  def self.set_systems_water_heater_reference(orig_bldg, new_bldg)
    # Exhibit 2 - Service water heating systems
    orig_bldg.water_heating_systems.each do |orig_water_heater|
      wh_type, wh_fuel_type, wh_tank_vol, ef, uef, fhr = get_water_heater_properties(orig_water_heater)

      # New water heater
      new_bldg.water_heating_systems.add(id: orig_water_heater.id,
                                         is_shared_system: orig_water_heater.is_shared_system,
                                         number_of_bedrooms_served: orig_water_heater.number_of_bedrooms_served,
                                         fuel_type: wh_fuel_type,
                                         water_heater_type: wh_type,
                                         location: orig_water_heater.location.gsub('unvented', 'vented'),
                                         tank_volume: wh_tank_vol,
                                         fraction_dhw_load_served: orig_water_heater.fraction_dhw_load_served,
                                         energy_factor: ef,
                                         uniform_energy_factor: uef,
                                         first_hour_rating: fhr)
    end
  end

  def self.set_systems_water_heating_use_reference(orig_bldg, new_bldg)
    return if orig_bldg.water_heating_systems.size == 0

    # Exhibit 2 - Service Water Heating Systems: Use the same Gallons per Day as Table 4.2.2(1) - Service water heating systems
    standard_piping_length = Defaults.get_std_pipe_length(@has_uncond_bsmnt, @has_cond_bsmnt, @cfa, @ncfl).round(3)

    if orig_bldg.hot_water_distributions.size == 0
      sys_id = 'HotWaterDistribution'
    else
      sys_id = orig_bldg.hot_water_distributions[0].id
    end

    bool_low_flow = lookup_reference_value('hot_water_distribution_low_flow')

    has_shared_water_heater = orig_bldg.water_heating_systems.count { |wh| wh.is_shared_system && wh.fraction_dhw_load_served > 0 } > 0
    if has_shared_water_heater
      pipe_r_value = lookup_reference_value('hot_water_distribution_pipe_r_value', 'shared water heater')
    else
      pipe_r_value = lookup_reference_value('hot_water_distribution_pipe_r_value', 'in-unit water heater')
    end
    pipe_r_value = lookup_reference_value('hot_water_distribution_pipe_r_value') if pipe_r_value.nil?

    orig_dist = orig_bldg.hot_water_distributions[0]

    # New hot water distribution
    if orig_dist.has_shared_recirculation
      shared_recirculation_pump_power = orig_dist.shared_recirculation_pump_power
      if not orig_dist.shared_recirculation_motor_efficiency.nil?
        # Adjust power using motor efficiency
        shared_recirculation_pump_power *= orig_dist.shared_recirculation_motor_efficiency / lookup_reference_value('shared_motor_efficiency')
      end

      new_bldg.hot_water_distributions.add(id: sys_id,
                                           system_type: HPXML::DHWDistTypeStandard,
                                           pipe_r_value: pipe_r_value,
                                           standard_piping_length: standard_piping_length,
                                           has_shared_recirculation: true,
                                           shared_recirculation_number_of_bedrooms_served: orig_dist.shared_recirculation_number_of_bedrooms_served,
                                           shared_recirculation_pump_power: shared_recirculation_pump_power,
                                           shared_recirculation_control_type: orig_dist.shared_recirculation_control_type)
    else
      new_bldg.hot_water_distributions.add(id: sys_id,
                                           system_type: HPXML::DHWDistTypeStandard,
                                           pipe_r_value: pipe_r_value,
                                           standard_piping_length: standard_piping_length)
    end

    # New water fixtures
    if orig_bldg.water_fixtures.size == 0
      # Shower Head
      new_bldg.water_fixtures.add(id: 'TargetWaterFixture1',
                                  water_fixture_type: HPXML::WaterFixtureTypeShowerhead,
                                  low_flow: bool_low_flow)

      # Faucet
      new_bldg.water_fixtures.add(id: 'TargetWaterFixture2',
                                  water_fixture_type: HPXML::WaterFixtureTypeFaucet,
                                  low_flow: bool_low_flow)
    else
      orig_bldg.water_fixtures.each do |orig_water_fixture|
        next unless [HPXML::WaterFixtureTypeShowerhead, HPXML::WaterFixtureTypeFaucet].include? orig_water_fixture.water_fixture_type

        new_bldg.water_fixtures.add(id: orig_water_fixture.id,
                                    water_fixture_type: orig_water_fixture.water_fixture_type,
                                    low_flow: bool_low_flow)
      end
    end
  end

  def self.set_systems_solar_thermal_reference(orig_bldg, new_bldg)
    if orig_bldg.water_heating_systems.any? { |wh| (wh.fuel_type == HPXML::FuelTypeElectricity || orig_bldg.solar_thermal_systems.size > 0) }
      solar_fraction = lookup_reference_value('water_heater_solar_fraction', 'electricity or solar')
    else
      solar_fraction = lookup_reference_value('water_heater_solar_fraction', 'other')
    end
    solar_fraction = lookup_reference_value('water_heater_solar_fraction') if solar_fraction.nil?

    if not solar_fraction.nil?
      new_bldg.solar_thermal_systems.add(id: 'TargetSolarThermalSystem',
                                         system_type: 'hot water',
                                         solar_fraction: solar_fraction)
    end
  end

  def self.set_systems_photovoltaics_reference(orig_bldg, new_bldg)
    # nop
  end

  def self.set_systems_batteries_reference(orig_bldg, new_bldg)
    # nop
  end

  def self.set_systems_generators_reference(orig_bldg, new_bldg)
    # nop
  end

  def self.set_appliances_clothes_washer_reference(orig_bldg, new_bldg)
    # Override efficiency values equal to "Std 2018-Present" Standard if clothes washer present in the Rated Home
    if not orig_bldg.clothes_washers.empty?
      clothes_washer = orig_bldg.clothes_washers[0]
      id = clothes_washer.id
      location = clothes_washer.location.gsub('unvented', 'vented')

      integrated_modified_energy_factor = lookup_reference_value('clothes_washer_imef', 'clothes washer present')
      rated_annual_kwh = lookup_reference_value('clothes_washer_ler', 'clothes washer present')
      label_electric_rate = lookup_reference_value('clothes_washer_elec_rate', 'clothes washer present')
      label_gas_rate = lookup_reference_value('clothes_washer_gas_rate', 'clothes washer present')
      label_annual_gas_cost = lookup_reference_value('clothes_washer_ghwc', 'clothes washer present')
      label_usage = lookup_reference_value('clothes_washer_lcy', 'clothes washer present')
      capacity = lookup_reference_value('clothes_washer_capacity', 'clothes washer present')
    end

    # Default values same as Energy Rating Reference Home, as defined by ANSI/RESNET/ICC 301
    id = 'ClothesWasher' if id.nil?
    location = HPXML::LocationConditionedSpace if location.nil?
    reference_values = Defaults.get_clothes_washer_values(@eri_version)
    integrated_modified_energy_factor = reference_values[:integrated_modified_energy_factor] if integrated_modified_energy_factor.nil?
    rated_annual_kwh = reference_values[:rated_annual_kwh] if rated_annual_kwh.nil?
    label_electric_rate = reference_values[:label_electric_rate] if label_electric_rate.nil?
    label_gas_rate = reference_values[:label_gas_rate] if label_gas_rate.nil?
    label_annual_gas_cost = reference_values[:label_annual_gas_cost] if label_annual_gas_cost.nil?
    label_usage = reference_values[:label_usage] * 52 if label_usage.nil?
    capacity = reference_values[:capacity] if capacity.nil?

    new_bldg.clothes_washers.add(id: id,
                                 location: location,
                                 is_shared_appliance: false,
                                 integrated_modified_energy_factor: integrated_modified_energy_factor,
                                 rated_annual_kwh: rated_annual_kwh,
                                 label_electric_rate: label_electric_rate,
                                 label_gas_rate: label_gas_rate,
                                 label_annual_gas_cost: label_annual_gas_cost,
                                 label_usage: label_usage / 52,
                                 capacity: capacity)
  end

  def self.set_appliances_clothes_dryer_reference(orig_bldg, new_bldg)
    # Default values
    id = 'ClothesDryer'
    location = HPXML::LocationConditionedSpace
    fuel_type = HPXML::FuelTypeElectricity

    # Override values?
    if not orig_bldg.clothes_dryers.empty?
      clothes_dryer = orig_bldg.clothes_dryers[0]
      id = clothes_dryer.id
      location = clothes_dryer.location.gsub('unvented', 'vented')
      fuel_type = clothes_dryer.fuel_type
    end

    new_bldg.clothes_dryers.add(id: id,
                                location: location,
                                is_shared_appliance: false,
                                fuel_type: fuel_type,
                                combined_energy_factor: lookup_reference_value('clothes_dryer_cef'))
  end

  def self.set_appliances_dishwasher_reference(orig_bldg, new_bldg)
    # Default values
    id = 'Dishwasher'
    location = HPXML::LocationConditionedSpace
    place_setting_capacity = 12

    # Override values?
    if not orig_bldg.dishwashers.empty?
      dishwasher = orig_bldg.dishwashers[0]
      id = dishwasher.id
      location = dishwasher.location.gsub('unvented', 'vented')
      place_setting_capacity = dishwasher.place_setting_capacity
    end

    subtype = place_setting_capacity < 8 ? 'compact' : 'standard'

    new_bldg.dishwashers.add(id: id,
                             location: location,
                             is_shared_appliance: false,
                             rated_annual_kwh: lookup_reference_value('dishwasher_ler', subtype),
                             place_setting_capacity: place_setting_capacity,
                             label_electric_rate: lookup_reference_value('dishwasher_elec_rate', subtype),
                             label_gas_rate: lookup_reference_value('dishwasher_gas_rate', subtype),
                             label_annual_gas_cost: lookup_reference_value('dishwasher_ghwc', subtype),
                             label_usage: lookup_reference_value('dishwasher_lcy', subtype) / 52.0)
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
      if @nbeds <= 2
        subtype = '1-2 bedrooms, refrigerator present'
      elsif @nbeds <= 4
        subtype = '3-4 bedrooms, refrigerator present'
      else
        subtype = '5+ bedrooms, refrigerator present'
      end
    end

    rated_annual_kwh = lookup_reference_value('refrigerator_rated_annual_kwh')
    rated_annual_kwh = lookup_reference_value('refrigerator_rated_annual_kwh', subtype) if rated_annual_kwh.nil?
    rated_annual_kwh = Defaults.get_refrigerator_values(@nbeds)[:rated_annual_kwh] if rated_annual_kwh.nil?

    new_bldg.refrigerators.add(id: id,
                               location: location,
                               rated_annual_kwh: rated_annual_kwh)
  end

  def self.set_appliances_dehumidifier_reference(orig_bldg, new_bldg)
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

  def self.set_appliances_cooking_range_oven_reference(orig_bldg, new_bldg)
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

    new_bldg.cooking_ranges.add(id: range_id,
                                location: location,
                                fuel_type: fuel_type,
                                is_induction: lookup_reference_value('range_induction'))
    new_bldg.ovens.add(id: oven_id,
                       is_convection: lookup_reference_value('oven_convection'))
  end

  def self.set_lighting_reference(new_bldg)
    new_bldg.lighting_groups.add(id: 'TargetLightingGroup1',
                                 location: HPXML::LocationInterior,
                                 fraction_of_units_in_location: lookup_reference_value('lighting_tier2_int'),
                                 lighting_type: HPXML::LightingTypeLED)
    new_bldg.lighting_groups.add(id: 'TargetLightingGroup2',
                                 location: HPXML::LocationExterior,
                                 fraction_of_units_in_location: lookup_reference_value('lighting_tier2_ext'),
                                 lighting_type: HPXML::LightingTypeLED)
    new_bldg.lighting_groups.add(id: 'TargetLightingGroup3',
                                 location: HPXML::LocationGarage,
                                 fraction_of_units_in_location: lookup_reference_value('lighting_tier2_grg'),
                                 lighting_type: HPXML::LightingTypeLED)
    new_bldg.lighting_groups.add(id: 'TargetLightingGroup4',
                                 location: HPXML::LocationInterior,
                                 fraction_of_units_in_location: lookup_reference_value('lighting_tier1_int'),
                                 lighting_type: HPXML::LightingTypeCFL)
    new_bldg.lighting_groups.add(id: 'TargetLightingGroup5',
                                 location: HPXML::LocationExterior,
                                 fraction_of_units_in_location: lookup_reference_value('lighting_tier1_ext'),
                                 lighting_type: HPXML::LightingTypeCFL)
    new_bldg.lighting_groups.add(id: 'TargetLightingGroup6',
                                 location: HPXML::LocationGarage,
                                 fraction_of_units_in_location: lookup_reference_value('lighting_tier1_grg'),
                                 lighting_type: HPXML::LightingTypeCFL)
    new_bldg.lighting_groups.add(id: 'TargetLightingGroup7',
                                 location: HPXML::LocationInterior,
                                 fraction_of_units_in_location: 0,
                                 lighting_type: HPXML::LightingTypeLFL)
    new_bldg.lighting_groups.add(id: 'TargetLightingGroup8',
                                 location: HPXML::LocationExterior,
                                 fraction_of_units_in_location: 0,
                                 lighting_type: HPXML::LightingTypeLFL)
    new_bldg.lighting_groups.add(id: 'TargetLightingGroup9',
                                 location: HPXML::LocationGarage,
                                 fraction_of_units_in_location: 0,
                                 lighting_type: HPXML::LightingTypeLFL)
  end

  def self.set_ceiling_fans_reference(orig_bldg, new_bldg)
    return if orig_bldg.ceiling_fans.size == 0

    new_bldg.ceiling_fans.add(id: 'TargetCeilingFan',
                              efficiency: lookup_reference_value('ceiling_fan_cfm_per_w'),
                              count: Defaults.get_ceiling_fan_count(@nbeds))
  end

  def self.set_misc_loads_reference(orig_bldg, new_bldg)
    # nop
  end

  private

  def self.get_infiltration_volume(hpxml)
    hpxml.air_infiltration_measurements.each do |air_infiltration_measurement|
      next if air_infiltration_measurement.infiltration_volume.nil?

      return air_infiltration_measurement.infiltration_volume
    end
  end

  def self.get_infiltration_height(hpxml)
    hpxml.air_infiltration_measurements.each do |air_infiltration_measurement|
      next if air_infiltration_measurement.infiltration_height.nil?

      return air_infiltration_measurement.infiltration_height
    end
    return
  end

  def self.get_radiant_barrier_bool(orig_bldg)
    all_ducts = []
    orig_bldg.hvac_distributions.each do |hvac_dist|
      hvac_dist.ducts.each do |duct|
        all_ducts << duct
      end
    end

    ducts_in_uncond_attic = false
    all_ducts.each do |duct|
      if [HPXML::LocationAtticVented, HPXML::LocationAtticUnvented].include?(duct.duct_location) &&
         (!duct.duct_surface_area.to_f.zero? || !duct.duct_fraction_area.to_f.zero?)
        ducts_in_uncond_attic = true
      end
    end
    if ducts_in_uncond_attic
      has_radiant_barrier = lookup_reference_value('radiant_barrier', "#{@state_code}, ducts in unconditioned attic")
      has_radiant_barrier = lookup_reference_value('radiant_barrier', 'ducts in unconditioned attic') if has_radiant_barrier.nil?
    end
    has_radiant_barrier = lookup_reference_value('radiant_barrier', @state_code) if has_radiant_barrier.nil?
    has_radiant_barrier = lookup_reference_value('radiant_barrier') if has_radiant_barrier.nil?

    return has_radiant_barrier
  end

  def self.get_enclosure_air_infiltration_default(orig_bldg)
    infil_air_leakage_cfm50_per_sqft = lookup_reference_value('infil_air_leakage_cfm50_per_sqft', @bldg_type)
    infil_air_leakage_cfm50_per_sqft = lookup_reference_value('infil_air_leakage_cfm50_per_sqft') if infil_air_leakage_cfm50_per_sqft.nil?

    infil_air_leakage_ach50 = lookup_reference_value('infil_air_leakage_ach50', @bldg_type)
    infil_air_leakage_ach50 = lookup_reference_value('infil_air_leakage_ach50') if infil_air_leakage_ach50.nil?

    if not infil_air_leakage_cfm50_per_sqft.nil?
      tot_cb_area, _ext_cb_area = Defaults.get_compartmentalization_boundary_areas(orig_bldg)
      infil_air_leakage = tot_cb_area * infil_air_leakage_cfm50_per_sqft
      infil_unit_of_measure = HPXML::UnitsCFM
    elsif not infil_air_leakage_ach50.nil?
      infil_unit_of_measure = HPXML::UnitsACH
      infil_air_leakage = infil_air_leakage_ach50
    end

    return infil_air_leakage, infil_unit_of_measure
  end

  def self.calc_default_total_win_area(orig_bldg, cfa)
    ag_bndry_wall_area, bg_bndry_wall_area = orig_bldg.thermal_boundary_wall_areas()
    common_wall_area = orig_bldg.common_wall_area()
    fa = ag_bndry_wall_area / (ag_bndry_wall_area + 0.5 * bg_bndry_wall_area)
    f = 1.0 - 0.44 * common_wall_area / (ag_bndry_wall_area + common_wall_area)

    return 0.15 * cfa * fa * f
  end

  def self.get_enclosure_walls_default_ufactor()
    walls_ufactor = lookup_reference_value('walls_ufactor', @state_code)
    walls_ufactor = lookup_reference_value('walls_ufactor') if walls_ufactor.nil?

    return walls_ufactor
  end

  def self.get_water_heater_properties(orig_water_heater)
    tankless_types = [HPXML::WaterHeaterTypeTankless, HPXML::WaterHeaterTypeCombiTankless]

    orig_wh_fuel_type = orig_water_heater.fuel_type.nil? ? orig_water_heater.related_hvac_system.heating_system_fuel : orig_water_heater.fuel_type
    subtype = get_lookup_fuel(orig_wh_fuel_type)
    wh_fuel_type = lookup_reference_value('water_heater_fuel_type', subtype)
    wh_fuel_type = lookup_reference_value('water_heater_fuel_type') if wh_fuel_type.nil?

    wh_type = lookup_reference_value('water_heater_type', subtype)

    if not tankless_types.include? wh_type
      if tankless_types.include? orig_water_heater.water_heater_type
        wh_tank_vol = lookup_reference_value('water_heater_volume', "#{subtype}, tankless->tank")
      end
      wh_tank_vol = lookup_reference_value('water_heater_volume', subtype) if wh_tank_vol.nil?
      wh_tank_vol = orig_water_heater.tank_volume if wh_tank_vol.nil?
    end

    wh_eff_units = lookup_reference_value('water_heater_eff_units')

    if not wh_tank_vol.nil?
      eff_subtype = wh_tank_vol <= 55 ? "#{subtype}, <= 55 gal" : "#{subtype}, > 55 gal"
      wh_eff_fixed = lookup_reference_value('water_heater_eff_fixed', eff_subtype)
    end
    wh_eff_fixed = lookup_reference_value('water_heater_eff_fixed', "#{subtype}, #{@bldg_type}") if wh_eff_fixed.nil?
    wh_eff_fixed = lookup_reference_value('water_heater_eff_fixed', subtype) if wh_eff_fixed.nil?
    wh_eff_variable = lookup_reference_value('water_heater_eff_variable', subtype)
    wh_eff = wh_eff_fixed + wh_eff_variable.to_f * wh_tank_vol.to_f
    if wh_eff_units.upcase == 'UEF'
      uef = wh_eff
      if [HPXML::WaterHeaterTypeStorage, HPXML::WaterHeaterTypeHeatPump].include? wh_type
        # Use rated home FHR if provided, else 63, per EPA
        fhr = orig_water_heater.first_hour_rating
        fhr = 63.0 if fhr.nil?
      end
    elsif wh_eff_units.upcase == 'EF'
      ef = wh_eff
    else
      fail 'Unexpected case.'
    end

    return wh_type, wh_fuel_type, wh_tank_vol, ef, uef, fhr
  end

  def self.get_default_boiler_efficiency(orig_system, fuel_type)
    if orig_system.is_shared_system && orig_system.heating_capacity >= 300000
      if orig_system.distribution_system.hydronic_type == HPXML::HydronicTypeWaterLoop # Central Boiler w/WLHP, >= 300 KBtu/h
        boiler_eff = lookup_reference_value('hvac_central_boiler_wlhp_et')
      else # Central Boiler, >= 300 KBtu/h
        boiler_eff = lookup_reference_value('hvac_central_boiler_et')
      end
    else
      subtype = get_lookup_fuel(fuel_type)
      boiler_eff = lookup_reference_value('hvac_boiler_afue', subtype)
    end

    return boiler_eff
  end

  def self.get_default_furnace_afue(fuel_type)
    subtype = get_lookup_fuel(fuel_type)
    furnace_afue = lookup_reference_value('hvac_furnace_afue', subtype)
    furnace_afue = lookup_reference_value('hvac_furnace_afue') if furnace_afue.nil?

    return furnace_afue
  end

  def self.get_predominant_foundation_type(orig_bldg)
    floor_areas = { 'basement' => 0.0,
                    'crawlspace' => 0.0,
                    'slab' => 0.0,
                    'ambient' => 0.0,
                    'adiabatic' => 0.0 }

    # calculate floor area by floor type
    orig_bldg.floors.each do |orig_floor|
      next unless orig_floor.is_floor
      next unless orig_floor.interior_adjacent_to == HPXML::LocationConditionedSpace

      if [HPXML::LocationOtherHousingUnit].include? orig_floor.exterior_adjacent_to
        floor_areas['adiabatic'] += orig_floor.area
      elsif [HPXML::LocationOutside].include? orig_floor.exterior_adjacent_to
        floor_areas['ambient'] += orig_floor.area
      elsif [HPXML::LocationBasementConditioned, HPXML::LocationBasementUnconditioned].include? orig_floor.exterior_adjacent_to
        floor_areas['basement'] += orig_floor.area
      elsif [HPXML::LocationCrawlspaceVented, HPXML::LocationCrawlspaceUnvented].include? orig_floor.exterior_adjacent_to
        floor_areas['crawlspace'] += orig_floor.area
      end
    end

    # calculate floor area by slab type
    orig_bldg.slabs.each do |orig_slab|
      next unless orig_slab.interior_adjacent_to == HPXML::LocationConditionedSpace

      floor_areas['slab'] += orig_slab.area
    end

    return floor_areas.max_by { |_k, v| v }[0] # find the key of the largest area
  end

  def self.is_ceiling_fully_adiabatic(orig_bldg)
    orig_bldg.floors.each do |orig_floor|
      next unless orig_floor.is_ceiling
      next unless orig_floor.interior_adjacent_to == HPXML::LocationConditionedSpace
      next unless orig_floor.exterior_adjacent_to != HPXML::LocationOtherHousingUnit

      return false # Found a thermal boundary ceiling not adjacent to other housing unit
    end
    orig_bldg.roofs.each do |orig_roof|
      next unless orig_roof.interior_adjacent_to == HPXML::LocationConditionedSpace

      return false # Found a thermal boundary roof (which, by definition, is adjacent to outside)
    end

    return true
  end

  def self.get_duct_location_areas(orig_bldg, total_duct_area)
    # EPA confirmed that duct percentages apply to ASHRAE 152 *total* duct area
    duct_location_areas = {}
    predominant_foundation_type = get_predominant_foundation_type(orig_bldg)

    nstory = @ncfl_ag == 1 ? '1' : '2'

    duct_fractions = lookup_reference_value('duct_location_fractions', "#{predominant_foundation_type} foundation, #{nstory} story")
    duct_fractions = lookup_reference_value('duct_location_fractions', "#{predominant_foundation_type} foundation") if duct_fractions.nil?
    if is_ceiling_fully_adiabatic(orig_bldg)
      duct_fractions = lookup_reference_value('duct_location_fractions', 'adiabatic ceiling') if duct_fractions.nil?
    end
    duct_fractions = lookup_reference_value('duct_location_fractions', "#{nstory} story") if duct_fractions.nil?
    duct_fractions = lookup_reference_value('duct_location_fractions') if duct_fractions.nil?

    fail 'Unexpected case.' if duct_fractions.nil?

    duct_fractions.split(',').each do |data|
      loc, frac = data.split('=').map(&:strip)
      if loc == 'attic'
        duct_location_areas[HPXML::LocationAtticVented] = Float(frac) * total_duct_area
      elsif loc == 'crawlspace'
        duct_location_areas[HPXML::LocationCrawlspaceVented] = Float(frac) * total_duct_area
      elsif loc == 'basement' && @has_cond_bsmnt
        duct_location_areas[HPXML::LocationBasementConditioned] = Float(frac) * total_duct_area
      elsif loc == 'basement' && @has_uncond_bsmnt
        duct_location_areas[HPXML::LocationBasementUnconditioned] = Float(frac) * total_duct_area
      elsif loc == 'outside'
        duct_location_areas[HPXML::LocationOutside] = Float(frac) * total_duct_area
      elsif loc == 'conditioned'
        duct_location_areas[HPXML::LocationConditionedSpace] = Float(frac) * total_duct_area
      else
        fail "Unexpected duct location: #{loc}."
      end
    end

    return duct_location_areas
  end

  def self.get_duct_insulation_r_value(duct_type, duct_location)
    if (duct_type == HPXML::DuctTypeSupply) && [HPXML::LocationAtticUnvented, HPXML::LocationAtticVented].include?(duct_location)
      # Supply ducts located in unconditioned attic
      duct_rvalue = lookup_reference_value('duct_unconditioned_r_value', 'supply, attic')
    end
    if not [HPXML::LocationConditionedSpace, HPXML::LocationBasementConditioned].include?(duct_location)
      # Ducts in unconditioned space
      duct_rvalue = lookup_reference_value('duct_unconditioned_r_value', 'other') if duct_rvalue.nil?
    end
    duct_rvalue = 0.0 if duct_rvalue.nil?

    return duct_rvalue
  end

  def self.calc_default_duct_lto_cfm25(cfa)
    duct_lto_cfm25_per_100sqft = lookup_reference_value('duct_lto_cfm25_per_100sqft')
    duct_lto_cfm25_min = lookup_reference_value('duct_lto_cfm25_min')

    duct_lto_cfm25 = (duct_lto_cfm25_per_100sqft * cfa / 100.0)
    if not duct_lto_cfm25_min.nil?
      duct_lto_cfm25 = [duct_lto_cfm25, duct_lto_cfm25_min].max
    end

    return duct_lto_cfm25
  end

  def self.add_air_distribution(orig_bldg, orig_system)
    i = 0
    while true
      i += 1
      dist_id = "TargetHVACDistribution#{i}"
      next if orig_bldg.hvac_distributions.select { |d| d.id == dist_id }.size > 0

      orig_bldg.hvac_distributions.add(id: dist_id,
                                       distribution_system_type: HPXML::HVACDistributionTypeAir,
                                       air_type: HPXML::AirTypeRegularVelocity)

      # Remove existing distribution system, if one exists
      if not orig_system.distribution_system.nil?
        orig_system.distribution_system.delete
      end

      return dist_id
    end
  end

  def self.add_reference_boiler(new_bldg, orig_system)
    if orig_system.is_shared_system
      # Retain the shared boiler regardless of its heating capacity
      heating_capacity = orig_system.heating_capacity
      number_of_units_served = orig_system.number_of_units_served

      shared_loop_watts = orig_system.shared_loop_watts
      if not orig_system.shared_loop_motor_efficiency.nil?
        # Adjust power using motor efficiency
        shared_loop_watts *= orig_system.shared_loop_motor_efficiency / lookup_reference_value('shared_motor_efficiency')
      end
    end

    heating_capacity = -1 if heating_capacity.nil? # Use auto-sizing

    heating_system_fuel = get_furnace_boiler_fuel(orig_system.heating_system_fuel)
    heating_efficiency_afue = get_default_boiler_efficiency(orig_system, heating_system_fuel)

    new_bldg.heating_systems.add(id: "TargetHeatingSystem#{new_bldg.heating_systems.size + 1}",
                                 distribution_system_idref: orig_system.distribution_system.id,
                                 is_shared_system: orig_system.is_shared_system,
                                 number_of_units_served: number_of_units_served,
                                 heating_system_type: HPXML::HVACTypeBoiler,
                                 heating_system_fuel: heating_system_fuel,
                                 heating_capacity: heating_capacity,
                                 shared_loop_watts: shared_loop_watts,
                                 fan_coil_watts: orig_system.fan_coil_watts,
                                 heating_efficiency_afue: heating_efficiency_afue,
                                 fraction_heat_load_served: orig_system.fraction_heat_load_served)
  end

  def self.add_reference_furnace(orig_bldg, new_bldg, load_frac, orig_system, heating_fuel)
    heating_system_fuel = get_furnace_boiler_fuel(heating_fuel)
    furnace_afue = get_default_furnace_afue(heating_system_fuel)

    if (not orig_system.distribution_system.nil?) && (orig_system.distribution_system.distribution_system_type == HPXML::HVACDistributionTypeAir)
      dist_id = orig_system.distribution_system.id
    else
      dist_id = add_air_distribution(orig_bldg, orig_system)
    end

    hvac_installation = get_hvac_installation_quality()

    new_bldg.heating_systems.add(id: "TargetHeatingSystem#{new_bldg.heating_systems.size + 1}",
                                 distribution_system_idref: dist_id,
                                 heating_system_type: HPXML::HVACTypeFurnace,
                                 heating_system_fuel: heating_system_fuel,
                                 heating_capacity: -1, # Use auto-sizing
                                 heating_efficiency_afue: furnace_afue,
                                 fraction_heat_load_served: load_frac,
                                 airflow_defect_ratio: hvac_installation[:airflow_defect_ratio],
                                 fan_watts_per_cfm: hvac_installation[:fan_watts_per_cfm])
  end

  def self.add_reference_air_conditioner(orig_bldg, new_bldg, load_frac, orig_system)
    seer = lookup_reference_value('hvac_ac_seer')
    eer = lookup_reference_value('hvac_ac_eer')
    compressor_type = lookup_reference_value('hvac_ac_compressor')
    if (not orig_system.distribution_system.nil?) && (orig_system.distribution_system.distribution_system_type == HPXML::HVACDistributionTypeAir)
      dist_id = orig_system.distribution_system.id
    else
      dist_id = add_air_distribution(orig_bldg, orig_system)
    end

    hvac_installation = get_hvac_installation_quality()

    new_bldg.cooling_systems.add(id: "TargetCoolingSystem#{new_bldg.cooling_systems.size + 1}",
                                 distribution_system_idref: dist_id,
                                 cooling_system_type: HPXML::HVACTypeCentralAirConditioner,
                                 cooling_system_fuel: HPXML::FuelTypeElectricity,
                                 cooling_capacity: -1, # Use auto-sizing
                                 fraction_cool_load_served: load_frac,
                                 cooling_efficiency_seer: seer,
                                 cooling_efficiency_eer: eer,
                                 compressor_type: compressor_type,
                                 charge_defect_ratio: hvac_installation[:charge_defect_ratio],
                                 airflow_defect_ratio: hvac_installation[:airflow_defect_ratio],
                                 fan_watts_per_cfm: hvac_installation[:fan_watts_per_cfm])
  end

  def self.add_reference_chiller_or_cooling_tower(new_bldg, orig_system)
    if orig_system.cooling_system_type == HPXML::HVACTypeChiller
      kw_per_ton = lookup_reference_value('hvac_chiller_kw_per_ton')
    end

    shared_loop_watts = orig_system.shared_loop_watts
    if not orig_system.shared_loop_motor_efficiency.nil?
      # Adjust power using motor efficiency
      shared_loop_watts *= orig_system.shared_loop_motor_efficiency / lookup_reference_value('shared_motor_efficiency')
    end

    new_bldg.cooling_systems.add(id: "TargetCoolingSystem#{new_bldg.cooling_systems.size + 1}",
                                 is_shared_system: orig_system.is_shared_system,
                                 number_of_units_served: orig_system.number_of_units_served,
                                 distribution_system_idref: orig_system.distribution_system.id,
                                 cooling_system_type: orig_system.cooling_system_type,
                                 cooling_system_fuel: orig_system.cooling_system_fuel,
                                 cooling_capacity: orig_system.cooling_capacity,
                                 fraction_cool_load_served: orig_system.fraction_cool_load_served,
                                 cooling_efficiency_kw_per_ton: kw_per_ton,
                                 shared_loop_watts: shared_loop_watts,
                                 fan_coil_watts: orig_system.fan_coil_watts)
  end

  def self.add_reference_heat_pump(orig_bldg, new_bldg, heat_load_frac, cool_load_frac, orig_htg_system)
    # Heat pump type and efficiency
    is_shared_system = false
    if orig_htg_system.is_a?(HPXML::HeatPump) && (orig_htg_system.heat_pump_type == HPXML::HVACTypeHeatPumpWaterLoopToAir)
      heat_pump_type = HPXML::HVACTypeHeatPumpWaterLoopToAir
      cop = lookup_reference_value('hvac_wlhp_cop')
      eer = lookup_reference_value('hvac_wlhp_eer')
      cooling_capacity = orig_htg_system.cooling_capacity
      heating_capacity = orig_htg_system.heating_capacity
      backup_heating_capacity = orig_htg_system.backup_heating_capacity
      dist_id = orig_htg_system.distribution_system.id
    else
      if orig_htg_system.is_a? HPXML::HeatPump
        heat_pump_type = lookup_reference_value('hvac_hp_type', orig_htg_system.heat_pump_type)
      end
      heat_pump_type = lookup_reference_value('hvac_hp_type') if heat_pump_type.nil?
      if heat_pump_type == HPXML::HVACTypeHeatPumpGroundToAir
        cop = lookup_reference_value('hvac_gshp_cop')
        eer = lookup_reference_value('hvac_gshp_eer')
      elsif heat_pump_type == HPXML::HVACTypeHeatPumpAirToAir
        hspf = lookup_reference_value('hvac_ashp_hspf')
        seer = lookup_reference_value('hvac_ashp_seer')
        eer = lookup_reference_value('hvac_ashp_eer')
        compressor_type = lookup_reference_value('hvac_ashp_compressor')
      end
      if orig_htg_system.is_shared_system && orig_htg_system.is_a?(HPXML::HeatPump) &&
         (orig_htg_system.heat_pump_type == HPXML::HVACTypeHeatPumpGroundToAir) &&
         (heat_pump_type == HPXML::HVACTypeHeatPumpGroundToAir)
        # Rated home has a GSHP w/ shared loop and ESRD is being configured with a GSHP,
        # so make it a GSHP w/ shared loop too
        is_shared_system = true
        number_of_units_served = orig_htg_system.number_of_units_served

        shared_loop_watts = orig_htg_system.shared_loop_watts
        if not orig_htg_system.shared_loop_motor_efficiency.nil?
          # Adjust power using motor efficiency
          shared_loop_watts *= orig_htg_system.shared_loop_motor_efficiency / lookup_reference_value('shared_motor_efficiency')
        end
      end
      if (not orig_htg_system.distribution_system.nil?) && (orig_htg_system.distribution_system.distribution_system_type == HPXML::HVACDistributionTypeAir)
        dist_id = orig_htg_system.distribution_system.id
      else
        dist_id = add_air_distribution(orig_bldg, orig_htg_system)
      end
    end

    cooling_capacity = -1 if cooling_capacity.nil? # Use auto-sizing
    heating_capacity = -1 if heating_capacity.nil? # Use auto-sizing
    backup_heating_capacity = -1 if backup_heating_capacity.nil? # Use auto-sizing

    if heat_pump_type == HPXML::HVACTypeHeatPumpAirToAir
      heat_pump_backup_type = HPXML::HeatPumpBackupTypeIntegrated
      heat_pump_backup_fuel = HPXML::FuelTypeElectricity
      if orig_htg_system.is_a?(HPXML::HeatPump) && (not orig_htg_system.backup_heating_fuel.nil?)
        heat_pump_backup_fuel = orig_htg_system.backup_heating_fuel
      end
      if heat_pump_backup_fuel == HPXML::FuelTypeElectricity
        heat_pump_backup_eff = 1.0
      else
        heat_pump_backup_eff = get_default_furnace_afue(heat_pump_backup_fuel)
      end
      heating_capacity_17F = -1 # Use auto-sizing
    elsif heat_pump_type == HPXML::HVACTypeHeatPumpGroundToAir
      pump_watts_per_ton = Defaults.get_gshp_pump_power()
    end

    hvac_installation = {}
    if heat_pump_type != HPXML::HVACTypeHeatPumpWaterLoopToAir
      hvac_installation = get_hvac_installation_quality()
    end

    new_bldg.heat_pumps.add(id: "TargetHeatPump#{new_bldg.heat_pumps.size + 1}",
                            is_shared_system: is_shared_system,
                            number_of_units_served: number_of_units_served,
                            distribution_system_idref: dist_id,
                            heat_pump_type: heat_pump_type,
                            heat_pump_fuel: HPXML::FuelTypeElectricity,
                            cooling_capacity: cooling_capacity,
                            heating_capacity: heating_capacity,
                            heating_capacity_17F: heating_capacity_17F,
                            backup_type: heat_pump_backup_type,
                            backup_heating_fuel: heat_pump_backup_fuel,
                            backup_heating_capacity: backup_heating_capacity,
                            backup_heating_efficiency_percent: heat_pump_backup_eff,
                            fraction_heat_load_served: heat_load_frac,
                            fraction_cool_load_served: cool_load_frac,
                            cooling_efficiency_seer: seer,
                            cooling_efficiency_eer: eer,
                            heating_efficiency_hspf: hspf,
                            heating_efficiency_cop: cop,
                            compressor_type: compressor_type,
                            pump_watts_per_ton: pump_watts_per_ton,
                            charge_defect_ratio: hvac_installation[:charge_defect_ratio],
                            airflow_defect_ratio: hvac_installation[:airflow_defect_ratio],
                            fan_watts_per_cfm: hvac_installation[:fan_watts_per_cfm],
                            shared_loop_watts: shared_loop_watts)
  end

  def self.get_hvac_installation_quality()
    return { charge_defect_ratio: lookup_reference_value('hvac_charge_defect_ratio'),
             airflow_defect_ratio: lookup_reference_value('hvac_airflow_defect_ratio'),
             fan_watts_per_cfm: lookup_reference_value('hvac_fan_watts_per_cfm') }
  end

  def self.get_reference_glazing_ufactor_shgc(orig_window)
    subtype = HPXML::WindowClassResidential
    unless orig_window.nil?
      if orig_window.performance_class == HPXML::WindowClassArchitectural
        if orig_window.fraction_operable > 0
          subtype = HPXML::WindowClassArchitectural + ', operable'
        else
          subtype = HPXML::WindowClassArchitectural + ', fixed'
        end
      end
    end

    window_ufactor = lookup_reference_value('window_ufactor', subtype)
    window_ufactor = lookup_reference_value('window_ufactor') if window_ufactor.nil?
    window_shgc = lookup_reference_value('window_shgc', subtype)
    window_shgc = lookup_reference_value('window_shgc') if window_shgc.nil?

    return window_ufactor, window_shgc
  end

  def self.get_furnace_boiler_fuel(fuel)
    subtype = get_lookup_fuel(fuel)
    heating_system_fuel = lookup_reference_value('hvac_heating_fuel', subtype)
    return heating_system_fuel
  end

  def self.get_lookup_fuel(fuel)
    if [HPXML::FuelTypeElectricity, HPXML::FuelTypeOil].include? fuel
      return fuel
    else
      return HPXML::FuelTypeNaturalGas
    end
  end

  def self.multifamily_adjacent_locations
    return [HPXML::LocationOtherHousingUnit,
            HPXML::LocationOtherHeatedSpace,
            HPXML::LocationOtherMultifamilyBufferSpace,
            HPXML::LocationOtherNonFreezingSpace]
  end

  def self.lookup_reference_value(value_type, subtype = nil)
    @lookup_program_data.each do |row|
      next unless row['type'] == value_type
      next unless row['subtype'] == subtype

      value = row[@iecc_zone]
      return nil if value.nil?

      begin
        return Float(value)
      rescue
        if value.upcase == 'TRUE'
          return true
        elsif value.upcase == 'FALSE'
          return false
        else
          return value
        end
      end
    end

    return
  end
end
