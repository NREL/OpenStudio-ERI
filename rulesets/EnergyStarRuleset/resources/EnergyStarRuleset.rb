# frozen_string_literal: true

class EnergyStarRuleset
  def self.apply_ruleset(hpxml, calc_type)
    # Use latest version of 301-2019
    @eri_version = Constants.ERIVersions[-1]
    hpxml.header.eri_calculation_version = @eri_version

    # Update HPXML object based on ESRD configuration
    if calc_type == ESConstants.CalcTypeEnergyStarReference
      hpxml = apply_energy_star_ruleset_reference(hpxml)
    end

    return hpxml
  end

  def self.apply_energy_star_ruleset_reference(orig_hpxml)
    new_hpxml = create_new_hpxml(orig_hpxml)

    # BuildingSummary
    set_summary_reference(orig_hpxml, new_hpxml)

    # ClimateAndRiskZones
    set_climate(orig_hpxml, new_hpxml)

    # Enclosure
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
    set_enclosure_air_infiltration_reference(orig_hpxml, new_hpxml)

    # Systems
    set_systems_hvac_reference(orig_hpxml, new_hpxml)
    set_systems_mechanical_ventilation_reference(orig_hpxml, new_hpxml)
    set_systems_whole_house_fan_reference(orig_hpxml, new_hpxml)
    set_systems_water_heater_reference(orig_hpxml, new_hpxml)
    set_systems_water_heating_use_reference(orig_hpxml, new_hpxml)
    set_systems_solar_thermal_reference(orig_hpxml, new_hpxml)
    set_systems_photovoltaics_reference(orig_hpxml, new_hpxml)
    set_systems_batteries_reference(orig_hpxml, new_hpxml)
    set_systems_generators_reference(orig_hpxml, new_hpxml)

    # Appliances
    set_appliances_clothes_washer_reference(orig_hpxml, new_hpxml)
    set_appliances_clothes_dryer_reference(orig_hpxml, new_hpxml)
    set_appliances_dishwasher_reference(orig_hpxml, new_hpxml)
    set_appliances_refrigerator_reference(orig_hpxml, new_hpxml)
    set_appliances_dehumidifier_reference(orig_hpxml, new_hpxml)
    set_appliances_cooking_range_oven_reference(orig_hpxml, new_hpxml)

    # Lighting
    set_lighting_reference(orig_hpxml, new_hpxml)
    set_ceiling_fans_reference(orig_hpxml, new_hpxml)

    # MiscLoads
    set_misc_loads_reference(orig_hpxml, new_hpxml)

    return new_hpxml
  end

  def self.create_new_hpxml(orig_hpxml)
    new_hpxml = HPXML.new
    @state_code = orig_hpxml.header.state_code

    new_hpxml.header.xml_type = orig_hpxml.header.xml_type
    new_hpxml.header.xml_generated_by = File.basename(__FILE__)
    new_hpxml.header.transaction = orig_hpxml.header.transaction
    new_hpxml.header.software_program_used = orig_hpxml.header.software_program_used
    new_hpxml.header.software_program_version = orig_hpxml.header.software_program_version
    new_hpxml.header.eri_calculation_version = orig_hpxml.header.eri_calculation_version
    new_hpxml.header.energystar_calculation_version = orig_hpxml.header.energystar_calculation_version
    new_hpxml.header.building_id = orig_hpxml.header.building_id
    new_hpxml.header.event_type = orig_hpxml.header.event_type
    new_hpxml.header.state_code = orig_hpxml.header.state_code

    @program_version = orig_hpxml.header.energystar_calculation_version
    bldg_type = orig_hpxml.building_construction.residential_facility_type
    if bldg_type == HPXML::ResidentialTypeSFA
      if @program_version == ESConstants.MFNationalVer1_1
        # ESRD configured as SF National v3.1
        @program_version = ESConstants.SFNationalVer3_1
      elsif @program_version == ESConstants.MFNationalVer1_0
        # ESRD configured as SF National v3
        @program_version = ESConstants.SFNationalVer3_0
      elsif @program_version == ESConstants.MFOregonWashingtonVer1_2
        # ESRD configured as SF Oregon/Washington v3.2
        @program_version = ESConstants.SFOregonWashingtonVer3_2
      elsif @program_version.include? 'MF'
        fail "Need to handle program version '#{@program_version}'."
      end
    end

    return new_hpxml
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
    @infilheight = get_infiltration_height(orig_hpxml)
    @has_cond_bsmnt = orig_hpxml.has_location(HPXML::LocationBasementConditioned)
    @has_uncond_bsmnt = orig_hpxml.has_location(HPXML::LocationBasementUnconditioned)
    @has_crawlspace = (orig_hpxml.has_location(HPXML::LocationCrawlspaceVented) || orig_hpxml.has_location(HPXML::LocationCrawlspaceUnvented))
    @has_attic = (orig_hpxml.has_location(HPXML::LocationAtticVented) || orig_hpxml.has_location(HPXML::LocationAtticUnvented))
    @has_auto_generated_attic = false

    new_hpxml.site.fuels = orig_hpxml.site.fuels

    new_hpxml.building_construction.residential_facility_type = orig_hpxml.building_construction.residential_facility_type
    new_hpxml.building_construction.number_of_conditioned_floors = orig_hpxml.building_construction.number_of_conditioned_floors
    new_hpxml.building_construction.number_of_conditioned_floors_above_grade = orig_hpxml.building_construction.number_of_conditioned_floors_above_grade
    new_hpxml.building_construction.number_of_bedrooms = orig_hpxml.building_construction.number_of_bedrooms
    new_hpxml.building_construction.conditioned_floor_area = orig_hpxml.building_construction.conditioned_floor_area
    new_hpxml.building_construction.conditioned_building_volume = orig_hpxml.building_construction.conditioned_building_volume
  end

  def self.set_climate(orig_hpxml, new_hpxml)
    new_hpxml.climate_and_risk_zones.iecc_year = orig_hpxml.climate_and_risk_zones.iecc_year
    new_hpxml.climate_and_risk_zones.iecc_zone = orig_hpxml.climate_and_risk_zones.iecc_zone
    new_hpxml.climate_and_risk_zones.weather_station_id = orig_hpxml.climate_and_risk_zones.weather_station_id
    new_hpxml.climate_and_risk_zones.weather_station_name = orig_hpxml.climate_and_risk_zones.weather_station_name
    new_hpxml.climate_and_risk_zones.weather_station_wmo = orig_hpxml.climate_and_risk_zones.weather_station_wmo
    new_hpxml.climate_and_risk_zones.weather_station_epw_filepath = orig_hpxml.climate_and_risk_zones.weather_station_epw_filepath
    @iecc_zone = orig_hpxml.climate_and_risk_zones.iecc_zone
  end

  def self.set_enclosure_air_infiltration_reference(orig_hpxml, new_hpxml)
    # Exhibit 2 - Infiltration
    infil_air_leakage, infil_unit_of_measure = get_enclosure_air_infiltration_default(orig_hpxml)

    # Air Infiltration
    new_hpxml.air_infiltration_measurements.add(id: "Infiltration_#{infil_unit_of_measure}50",
                                                house_pressure: 50,
                                                unit_of_measure: infil_unit_of_measure,
                                                air_leakage: infil_air_leakage.round(1),
                                                infiltration_volume: @infilvolume,
                                                infiltration_height: @infilheight)
  end

  def self.set_enclosure_attics_reference(orig_hpxml, new_hpxml)
    if ESConstants.MFVersions.include? @program_version
      ceiling_type = get_ceiling_type(orig_hpxml)
      if ceiling_type == 'adiabatic'
        return # Where the Rated Unit is entirely located beneath another dwelling unit or unrated conditioned space, no attic is modeled in the Reference Design
      else
        if @program_version == ESConstants.MFNationalVer1_1
          # Attic shall only be modeled if exist. Because Duct Locations shall be configured to be 100% in conditioned space
          # Check if vented attic (or unvented attic, which will become a vented attic) exists
          if @has_attic
            new_hpxml.attics.add(id: 'VentedAttic',
                                 attic_type: HPXML::AtticTypeVented)
          end
        elsif [ESConstants.MFNationalVer1_0, ESConstants.MFOregonWashingtonVer1_2].include? @program_version
          # With or without an attic in orig_hpxml, there should be an attic in new_hpxml. Because duct Locations shall be configured to be either 100% or 75% in vented attic depending on the number of story of the unit
          new_hpxml.attics.add(id: 'VentedAttic',
                               attic_type: HPXML::AtticTypeVented)
          @has_auto_generated_attic = true unless @has_attic
        end
      end
    else
      new_hpxml.attics.add(id: 'VentedAttic',
                           attic_type: HPXML::AtticTypeVented)
      @has_auto_generated_attic = true unless @has_attic
    end
  end

  def self.set_enclosure_foundations_reference(orig_hpxml, new_hpxml)
    # Check if vented crawlspace (or unvented crawlspace, which will become a vented crawlspace) exists
    orig_hpxml.frame_floors.each do |orig_frame_floor|
      next unless orig_frame_floor.interior_adjacent_to.include?('crawlspace') || orig_frame_floor.exterior_adjacent_to.include?('crawlspace')

      new_hpxml.foundations.add(id: 'VentedCrawlspace',
                                foundation_type: HPXML::FoundationTypeCrawlspaceVented)
      break
    end

    # For unconditioned basement, set within infiltration volume input
    orig_hpxml.foundations.each do |orig_foundation|
      next unless orig_foundation.foundation_type == HPXML::FoundationTypeBasementUnconditioned

      new_hpxml.foundations.add(id: orig_foundation.id,
                                foundation_type: orig_foundation.foundation_type,
                                within_infiltration_volume: false)
    end
  end

  def self.set_enclosure_roofs_reference(orig_hpxml, new_hpxml)
    # Exhibit 2 - Roofs
    radiant_barrier_bool = get_radiant_barrier_bool(orig_hpxml)
    radiant_barrier_grade = 1 if radiant_barrier_bool

    solar_absorptance = 0.92
    emittance = 0.90

    orig_hpxml.roofs.each do |orig_roof|
      if orig_roof.interior_adjacent_to == HPXML::LocationLivingSpace
        roof_interior_adjacent_to = HPXML::LocationAtticVented
      else
        roof_interior_adjacent_to = orig_roof.interior_adjacent_to.gsub('unvented', 'vented')
      end
      # Roof surfaces are over unconditioned spaces and should not be insulated
      roof_insulation_assembly_r_value = [orig_roof.insulation_assembly_r_value, 2.3].min # uninsulated

      new_hpxml.roofs.add(id: orig_roof.id,
                          interior_adjacent_to: roof_interior_adjacent_to,
                          area: orig_roof.area,
                          azimuth: orig_roof.azimuth,
                          solar_absorptance: solar_absorptance,
                          emittance: emittance,
                          pitch: orig_roof.pitch,
                          radiant_barrier: radiant_barrier_bool,
                          radiant_barrier_grade: radiant_barrier_grade,
                          insulation_id: orig_roof.insulation_id,
                          insulation_assembly_r_value: roof_insulation_assembly_r_value)
    end

    # Add a roof above the vented attic that is newly added to Reference Design
    orig_hpxml.frame_floors.each do |orig_frame_floor|
      next unless orig_frame_floor.is_ceiling
      next unless [HPXML::LocationOtherHousingUnit, HPXML::LocationOtherHeatedSpace, HPXML::LocationOtherMultifamilyBufferSpace, HPXML::LocationOtherNonFreezingSpace].include? orig_frame_floor.exterior_adjacent_to
      next unless @has_auto_generated_attic

      # Estimate the area of the roof based on the frame floor area and pitch -- the pitch is assumed to be 5:12
      pitch = 5.0
      pitch_to_radians = Math.atan(pitch / 12.0)
      roof_area = orig_frame_floor.area / Math.cos(pitch_to_radians)

      new_hpxml.roofs.add(id: "Roof#{new_hpxml.roofs.size + 1}",
                          interior_adjacent_to: HPXML::LocationAtticVented,
                          area: roof_area,
                          azimuth: nil,
                          solar_absorptance: solar_absorptance,
                          emittance: emittance,
                          pitch: pitch,
                          radiant_barrier: radiant_barrier_bool,
                          radiant_barrier_grade: radiant_barrier_grade,
                          insulation_id: "Roof_Insulation#{new_hpxml.roofs.size + 1}",
                          insulation_assembly_r_value: 2.3) # Assumes that the roof is uninsulated
    end
  end

  def self.set_enclosure_rim_joists_reference(orig_hpxml, new_hpxml)
    ufactor = get_enclosure_walls_default_ufactor()

    ext_thermal_bndry_rim_joists = orig_hpxml.rim_joists.select { |rim_joist| rim_joist.is_exterior && rim_joist.is_thermal_boundary }

    ext_thermal_bndry_rim_joists_ag = ext_thermal_bndry_rim_joists.select { |rim_joist| rim_joist.interior_adjacent_to == HPXML::LocationLivingSpace }
    sum_gross_area_ag = ext_thermal_bndry_rim_joists_ag.map { |rim_joist| rim_joist.area }.sum(0)

    ext_thermal_bndry_rim_joists_bg = ext_thermal_bndry_rim_joists.select { |rim_joist| rim_joist.interior_adjacent_to == HPXML::LocationBasementConditioned }
    sum_gross_area_bg = ext_thermal_bndry_rim_joists_bg.map { |rim_joist| rim_joist.area }.sum(0)

    solar_absorptance = 0.75
    emittance = 0.90

    # Create insulated rim joists for exterior thermal boundary surface.
    # Area is equally distributed to each direction to be consistent with walls.
    # Need to preserve above-grade vs below-grade for inferred infiltration height.
    if sum_gross_area_ag > 0
      new_hpxml.rim_joists.add(id: 'RimJoistArea',
                               exterior_adjacent_to: HPXML::LocationOutside,
                               interior_adjacent_to: HPXML::LocationLivingSpace,
                               area: sum_gross_area_ag,
                               azimuth: nil,
                               solar_absorptance: solar_absorptance,
                               emittance: emittance,
                               insulation_assembly_r_value: (1.0 / ufactor).round(3))
    end
    if sum_gross_area_bg > 0
      new_hpxml.rim_joists.add(id: 'RimJoistAreaBasement',
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
    orig_hpxml.rim_joists.each do |orig_rim_joist|
      next if orig_rim_joist.is_exterior_thermal_boundary

      insulation_assembly_r_value = [orig_rim_joist.insulation_assembly_r_value, 4.0].min # uninsulated
      if orig_rim_joist.is_thermal_boundary
        insulation_assembly_r_value = (1.0 / ufactor).round(3)
      end
      new_hpxml.rim_joists.add(id: orig_rim_joist.id,
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

  def self.set_enclosure_walls_reference(orig_hpxml, new_hpxml)
    # Exhibit 2 - Above-grade Walls U-factor
    ufactor = get_enclosure_walls_default_ufactor()

    ext_thermal_bndry_walls = orig_hpxml.walls.select { |wall| wall.is_exterior_thermal_boundary }
    sum_gross_area = ext_thermal_bndry_walls.map { |wall| wall.area }.sum(0)

    solar_absorptance = 0.75
    emittance = 0.90

    # Create thermal boundary wall area
    if sum_gross_area > 0
      new_hpxml.walls.add(id: 'WallArea',
                          exterior_adjacent_to: HPXML::LocationOutside,
                          interior_adjacent_to: HPXML::LocationLivingSpace,
                          wall_type: HPXML::WallTypeWoodStud,
                          area: sum_gross_area,
                          azimuth: nil,
                          solar_absorptance: solar_absorptance,
                          emittance: emittance,
                          insulation_assembly_r_value: (1.0 / ufactor).round(3))
    end

    # Preserve exterior walls that are not thermal boundary walls (e.g., unconditioned attic gable walls or exterior garage walls). These walls are specified as uninsulated.
    # Preserve thermal boundary walls that are not exterior (e.g., garage wall adjacent to living space). These walls are assigned the appropriate U-factor from the Energy Star Exhibit 2 (Expanded ENERGY STAR Reference Design Definition).
    # The purpose of this is to be consistent with other software tools.
    orig_hpxml.walls.each do |orig_wall|
      next if orig_wall.is_exterior_thermal_boundary

      if ESConstants.MFVersions.include? @program_version
        insulation_assembly_r_value = [orig_wall.insulation_assembly_r_value, 4.0].min # uninsulated
        if orig_wall.is_thermal_boundary && ([HPXML::LocationOutside, HPXML::LocationGarage].include? orig_wall.exterior_adjacent_to)
          insulation_assembly_r_value = (1.0 / ufactor).round(3)
        end
      elsif ESConstants.SFVersions.include? @program_version
        insulation_assembly_r_value = [orig_wall.insulation_assembly_r_value, 4.0].min # uninsulated
        if orig_wall.is_thermal_boundary
          insulation_assembly_r_value = (1.0 / ufactor).round(3)
        end
      end

      new_hpxml.walls.add(id: orig_wall.id,
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

  def self.set_enclosure_foundation_walls_reference(orig_hpxml, new_hpxml)
    # Exhibit 2 - Foundation walls U-factor/R-value
    if ESConstants.MFVersions.include? @program_version
      fndwall_interior_ins_rvalue = get_foundation_walls_default_ufactor_or_rvalue()
    else
      fndwall_assembly_rvalue = (1.0 / get_foundation_walls_default_ufactor_or_rvalue()).round(3)
    end

    # Exhibit 2 - Conditioned basement walls
    orig_hpxml.foundation_walls.each do |orig_foundation_wall|
      # Insulated for, e.g., conditioned basement walls adjacent to ground.
      # Uninsulated for, e.g., crawlspace/unconditioned basement walls adjacent to ground.
      if orig_foundation_wall.is_thermal_boundary
        if not fndwall_assembly_rvalue.nil?
          insulation_assembly_r_value = fndwall_assembly_rvalue
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
      new_hpxml.foundation_walls.add(id: orig_foundation_wall.id,
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

  def self.set_enclosure_ceilings_reference(orig_hpxml, new_hpxml)
    ceiling_ufactor = get_reference_ceiling_ufactor()

    # Exhibit 2 - Ceilings
    orig_hpxml.frame_floors.each do |orig_frame_floor|
      next unless orig_frame_floor.is_ceiling

      if ESConstants.MFVersions.include? @program_version
        # Retain boundary condition of ceilings in the Rated Unit, including adiabatic ceilings.
        ceiling_exterior_adjacent_to = orig_frame_floor.exterior_adjacent_to.gsub('unvented', 'vented')
        if ([ESConstants.MFNationalVer1_0, ESConstants.MFOregonWashingtonVer1_2].include? @program_version) && @has_auto_generated_attic && ([HPXML::LocationOtherHousingUnit, HPXML::LocationOtherMultifamilyBufferSpace, HPXML::LocationOtherNonFreezingSpace, HPXML::LocationOtherHeatedSpace].include? orig_frame_floor.exterior_adjacent_to)
          ceiling_exterior_adjacent_to = HPXML::LocationAtticVented
        end

        insulation_assembly_r_value = [orig_frame_floor.insulation_assembly_r_value, 2.1].min # uninsulated
        if orig_frame_floor.is_thermal_boundary && ([HPXML::LocationOutside, HPXML::LocationAtticUnvented, HPXML::LocationAtticVented, HPXML::LocationGarage, HPXML::LocationCrawlspaceUnvented, HPXML::LocationCrawlspaceVented, HPXML::LocationBasementUnconditioned, HPXML::LocationOtherMultifamilyBufferSpace].include? orig_frame_floor.exterior_adjacent_to)
          # Ceilings adjacent to exterior or unconditioned space volumes (e.g., attic, garage, crawlspace, sunrooms, unconditioned basement, multifamily buffer space)
          insulation_assembly_r_value = (1.0 / ceiling_ufactor).round(3)
        end
      elsif ESConstants.SFVersions.include? @program_version
        ceiling_exterior_adjacent_to = orig_frame_floor.exterior_adjacent_to.gsub('unvented', 'vented')
        if [HPXML::LocationOtherHousingUnit, HPXML::LocationOtherMultifamilyBufferSpace, HPXML::LocationOtherNonFreezingSpace, HPXML::LocationOtherHeatedSpace].include? orig_frame_floor.exterior_adjacent_to
          ceiling_exterior_adjacent_to = HPXML::LocationAtticVented
        end

        # Changes the U-factor for a ceiling to be uninsulated if the ceiling is not a thermal boundary.
        insulation_assembly_r_value = [orig_frame_floor.insulation_assembly_r_value, 2.1].min # uninsulated
        if orig_frame_floor.is_thermal_boundary
          insulation_assembly_r_value = (1.0 / ceiling_ufactor).round(3)
        elsif [HPXML::LocationOtherHousingUnit, HPXML::LocationOtherMultifamilyBufferSpace, HPXML::LocationOtherNonFreezingSpace, HPXML::LocationOtherHeatedSpace].include? orig_frame_floor.exterior_adjacent_to
          insulation_assembly_r_value = (1.0 / ceiling_ufactor).round(3) # Becomes the ceiling adjacent to the vented attic
        end
      end

      new_hpxml.frame_floors.add(id: orig_frame_floor.id,
                                 exterior_adjacent_to: ceiling_exterior_adjacent_to,
                                 interior_adjacent_to: orig_frame_floor.interior_adjacent_to.gsub('unvented', 'vented'),
                                 area: orig_frame_floor.area,
                                 insulation_id: orig_frame_floor.insulation_id,
                                 insulation_assembly_r_value: insulation_assembly_r_value,
                                 other_space_above_or_below: orig_frame_floor.other_space_above_or_below)
    end

    # Add a frame floor between the vented attic and living space
    orig_hpxml.roofs.each do |orig_roof|
      next unless orig_roof.is_exterior_thermal_boundary
      next unless @has_auto_generated_attic

      # Estimate the area of the frame floor based on the roof area and pitch
      pitch_to_radians = Math.atan(orig_roof.pitch / 12.0)
      frame_floor_area = orig_roof.area * Math.cos(pitch_to_radians)

      new_hpxml.frame_floors.add(id: "FrameFloor#{new_hpxml.frame_floors.size + 1}",
                                 exterior_adjacent_to: HPXML::LocationAtticVented,
                                 interior_adjacent_to: HPXML::LocationLivingSpace,
                                 area: frame_floor_area,
                                 insulation_id: "FrameFloor_Insulation#{new_hpxml.frame_floors.size + 1}",
                                 insulation_assembly_r_value: (1.0 / ceiling_ufactor).round(3))
    end
  end

  def self.set_enclosure_floors_reference(orig_hpxml, new_hpxml)
    floor_ufactor = get_enclosure_floors_over_uncond_spc_default_ufactor()

    # Exhibit 2 - Floors over unconditioned spaces
    orig_hpxml.frame_floors.each do |orig_frame_floor|
      next unless orig_frame_floor.is_floor

      if ESConstants.MFVersions.include? @program_version
        insulation_assembly_r_value = [orig_frame_floor.insulation_assembly_r_value, 3.1].min # uninsulated
        if orig_frame_floor.is_thermal_boundary && ([HPXML::LocationOutside, HPXML::LocationOtherNonFreezingSpace, HPXML::LocationAtticUnvented, HPXML::LocationAtticVented, HPXML::LocationGarage, HPXML::LocationCrawlspaceUnvented, HPXML::LocationCrawlspaceVented, HPXML::LocationBasementUnconditioned, HPXML::LocationOtherMultifamilyBufferSpace].include? orig_frame_floor.exterior_adjacent_to)
          # Ceilings adjacent to outdoor environment, non-freezing space, unconditioned space volumes (e.g., attic, garage, crawlspace, sunrooms, unconditioned basement, multifamily buffer space)
          insulation_assembly_r_value = (1.0 / floor_ufactor).round(3)
        end
      elsif ESConstants.SFVersions.include? @program_version
        # Uninsulated for, e.g., floors between living space and conditioned basement.
        insulation_assembly_r_value = [orig_frame_floor.insulation_assembly_r_value, 3.1].min # uninsulated
        # Insulated for, e.g., floors between living space and crawlspace/unconditioned basement.
        if orig_frame_floor.is_thermal_boundary
          insulation_assembly_r_value = (1.0 / floor_ufactor).round(3)
        end
      end

      new_hpxml.frame_floors.add(id: orig_frame_floor.id,
                                 exterior_adjacent_to: orig_frame_floor.exterior_adjacent_to.gsub('unvented', 'vented'),
                                 interior_adjacent_to: orig_frame_floor.interior_adjacent_to.gsub('unvented', 'vented'),
                                 area: orig_frame_floor.area,
                                 insulation_id: orig_frame_floor.insulation_id,
                                 insulation_assembly_r_value: insulation_assembly_r_value,
                                 other_space_above_or_below: orig_frame_floor.other_space_above_or_below)
    end
  end

  def self.set_enclosure_slabs_reference(orig_hpxml, new_hpxml)
    slab_perim_rvalue, slab_perim_depth = get_reference_slab_perimeter_rvalue_depth()
    slab_under_rvalue, slab_under_width = get_reference_slab_under_rvalue_width()
    is_under_entire_slab_insulated = nil

    # Exhibit 2 - Foundations
    orig_hpxml.slabs.each do |orig_slab|
      if orig_slab.interior_adjacent_to == HPXML::LocationLivingSpace
        if [ESConstants.SFOregonWashingtonVer3_2, ESConstants.MFOregonWashingtonVer1_2].include? @program_version
          is_under_entire_slab_insulated = true
          # override depth of slab perimeter insulation if slab depth is provided
          slab_perim_depth = orig_slab.thickness
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

      if [HPXML::LocationLivingSpace, HPXML::LocationBasementConditioned].include? orig_slab.interior_adjacent_to
        carpet_fraction = 0.8
        carpet_r_value = 2.0
      else
        carpet_fraction = orig_slab.carpet_fraction
        carpet_r_value = orig_slab.carpet_r_value
      end
      new_hpxml.slabs.add(id: orig_slab.id,
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

  def self.set_enclosure_windows_reference(orig_hpxml, new_hpxml)
    # Exhibit 2 - Glazing

    # Calculate the ratio of the glazing area to the conditioned floor area
    ext_thermal_bndry_windows = orig_hpxml.windows.select { |window| window.wall.is_exterior_thermal_boundary }
    orig_total_win_area = ext_thermal_bndry_windows.map { |window| window.area }.sum(0)
    window_to_cfa_ratio = orig_total_win_area / @cfa

    # Default natural ventilation
    fraction_operable = Airflow.get_default_fraction_of_windows_operable()

    # Calculate the window area
    if ESConstants.SFVersions.include? @program_version
      if @has_cond_bsmnt || [HPXML::ResidentialTypeSFA, HPXML::ResidentialTypeApartment].include?(@bldg_type)
        # For homes with conditioned basements and attached homes:
        total_win_area = calc_default_total_win_area(orig_hpxml, @cfa)
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

        new_hpxml.windows.add(id: "WindowArea#{orientation}",
                              area: each_win_area.round(2),
                              azimuth: azimuth,
                              ufactor: win_ufactor,
                              shgc: win_shgc,
                              wall_idref: 'WallArea',
                              performance_class: HPXML::WindowClassResidential,
                              fraction_operable: fraction_operable)
      end
    elsif ESConstants.MFVersions.include? @program_version
      total_win_area = calc_default_total_win_area(orig_hpxml, @cfa)

      # Orientation same as Rated Unit, by percentage of area
      orig_hpxml.windows.each do |win|
        next unless win.wall.is_exterior_thermal_boundary

        win_area = win.area * total_win_area / orig_total_win_area
        win_ufactor, win_shgc = get_reference_glazing_ufactor_shgc(win)

        new_hpxml.windows.add(id: win.id,
                              area: win_area.round(2),
                              azimuth: win.azimuth,
                              ufactor: win_ufactor,
                              shgc: win_shgc,
                              wall_idref: 'WallArea',
                              performance_class: win.performance_class,
                              fraction_operable: fraction_operable)
      end
    end
  end

  def self.set_enclosure_skylights_reference(orig_hpxml, new_hpxml)
    # Exhibit 2 - Skylights
    # nop
  end

  def self.set_enclosure_doors_reference(orig_hpxml, new_hpxml)
    # Exhibit 2 - Doors
    # The door type is assumed to be opaque
    door_ufactor, door_shgc = get_default_door_ufactor_shgc()

    orig_hpxml.doors.each do |orig_door|
      new_hpxml.doors.add(id: orig_door.id,
                          wall_idref: 'WallArea',
                          area: orig_door.area,
                          azimuth: orig_door.azimuth,
                          r_value: (1.0 / door_ufactor).round(3))
    end
  end

  def self.set_systems_hvac_reference(orig_hpxml, new_hpxml)
    # Exhibit 2 - Heating and Cooling Systems
    hvac_configurations = get_hvac_configurations(orig_hpxml)

    hvac_configurations.each do |hvac_configuration|
      heating_system = hvac_configuration[:heating_system]
      cooling_system = hvac_configuration[:cooling_system]
      heat_pump = hvac_configuration[:heat_pump]
      if not heating_system.nil?
        if heating_system.heating_system_type == HPXML::HVACTypeBoiler
          add_reference_heating_boiler(orig_hpxml, new_hpxml, heating_system)
        elsif heating_system.heating_system_fuel == HPXML::FuelTypeElectricity
          if not cooling_system.nil?
            fraction_cool_load_served = cooling_system.fraction_cool_load_served
          else
            fraction_cool_load_served = 0.0
          end
          add_reference_heat_pump(orig_hpxml, new_hpxml, heating_system.fraction_heat_load_served, fraction_cool_load_served, heating_system, cooling_system)
        else
          add_reference_heating_furnace(orig_hpxml, new_hpxml, heating_system.fraction_heat_load_served, heating_system)
        end
      end
      if not cooling_system.nil?
        if (not heating_system.nil?) && (heating_system.heating_system_fuel == HPXML::FuelTypeElectricity)
          # Already created HP above
        elsif cooling_system.cooling_system_type == HPXML::HVACTypeChiller || cooling_system.cooling_system_type == HPXML::HVACTypeCoolingTower
          add_reference_cooling_chiller_or_cooling_tower(orig_hpxml, new_hpxml, cooling_system)
        else
          add_reference_cooling_air_conditioner(orig_hpxml, new_hpxml, cooling_system.fraction_cool_load_served, cooling_system)
        end
      end
      if not heat_pump.nil?
        add_reference_heat_pump(orig_hpxml, new_hpxml, heat_pump.fraction_heat_load_served, heat_pump.fraction_cool_load_served, heat_pump)
      end
    end

    # Exhibit 2 - Thermostat
    new_hpxml.hvac_controls.add(id: 'HVACControl',
                                control_type: HPXML::HVACControlTypeProgrammable)

    # Exhibit 2 - Thermal distribution systems
    remaining_cfa_served_heating = @cfa # init
    remaining_cfa_served_cooling = @cfa # init
    remaining_fracload_served_heating = 1.0 # init
    remaining_fracload_served_cooling = 1.0 # init
    orig_hpxml.hvac_systems.each do |h|
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
    orig_hpxml.hvac_distributions.each do |orig_hvac_distribution|
      new_hpxml.hvac_distributions.add(id: orig_hvac_distribution.id,
                                       distribution_system_type: orig_hvac_distribution.distribution_system_type,
                                       conditioned_floor_area_served: orig_hvac_distribution.conditioned_floor_area_served,
                                       number_of_return_registers: orig_hvac_distribution.number_of_return_registers,
                                       hydronic_type: orig_hvac_distribution.hydronic_type,
                                       air_type: orig_hvac_distribution.air_type,
                                       annual_heating_dse: orig_hvac_distribution.annual_heating_dse,
                                       annual_cooling_dse: orig_hvac_distribution.annual_cooling_dse)
      new_hvac_dist = new_hpxml.hvac_distributions[-1]

      next unless new_hvac_dist.distribution_system_type == HPXML::HVACDistributionTypeAir

      if new_hvac_dist.number_of_return_registers.nil?
        new_hvac_dist.number_of_return_registers = 1 # EPA guidance
      end
      new_hvac_dist.number_of_return_registers = [1, new_hvac_dist.number_of_return_registers].max # Ensure at least 1 register

      if new_hvac_dist.conditioned_floor_area_served.nil?
        # Estimate CFA served
        # This methodology tries to prevent the possibility of sum(CFAServed) > CFA in the ESRD,
        # which would generate an error downstream in the ENERGY STAR calcultion.
        estd_cfa_heated = @cfa
        estd_cfa_cooled = @cfa
        new_hvac_dist.hvac_systems.each do |h|
          if h.respond_to?(:fraction_heat_load_served) && h.fraction_heat_load_served.to_f > 0
            estd_cfa_heated = remaining_cfa_served_heating * h.fraction_heat_load_served / remaining_fracload_served_heating
          end
          if h.respond_to?(:fraction_cool_load_served) && h.fraction_cool_load_served.to_f > 0
            estd_cfa_cooled = remaining_cfa_served_cooling * h.fraction_cool_load_served / remaining_fracload_served_cooling
          end
        end
        new_hvac_dist.conditioned_floor_area_served = [estd_cfa_heated.to_f, estd_cfa_cooled.to_f].min
      end

      # Duct leakage to outside calculated based on conditioned floor area served
      total_duct_leakage_to_outside = calc_default_duct_leakage_to_outside(new_hvac_dist.conditioned_floor_area_served)

      [HPXML::DuctTypeSupply, HPXML::DuctTypeReturn].each do |duct_type|
        # Split the total duct leakage to outside evenly and assign it to supply ducts and return ducts
        duct_leakage_to_outside = total_duct_leakage_to_outside * 0.5

        new_hvac_dist.duct_leakage_measurements.add(duct_type: duct_type,
                                                    duct_leakage_units: HPXML::UnitsCFM25,
                                                    duct_leakage_value: duct_leakage_to_outside,
                                                    duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside)

        # ASHRAE 152 duct area calculation based on conditioned floor area served
        primary_duct_area, secondary_duct_area = HVAC.get_default_duct_surface_area(duct_type, @ncfl_ag, new_hvac_dist.conditioned_floor_area_served, new_hvac_dist.number_of_return_registers) # sqft
        total_duct_area = primary_duct_area + secondary_duct_area

        duct_location_and_surface_area = get_duct_location_and_surface_area(orig_hpxml, total_duct_area)

        duct_location_and_surface_area.each do |duct_location, duct_surface_area|
          duct_insulation_r_value = get_duct_insulation_r_value(duct_type, duct_location)
          new_hvac_dist.ducts.add(duct_type: duct_type,
                                  duct_insulation_r_value: duct_insulation_r_value,
                                  duct_location: duct_location,
                                  duct_surface_area: duct_surface_area.round(2))
        end
      end
    end
  end

  def self.set_systems_mechanical_ventilation_reference(orig_hpxml, new_hpxml)
    # Exhibit 2 - Whole-House Mechanical ventilation
    # mechanical vent fan cfm
    q_tot = 0.01 * @cfa + 7.5 * (@nbeds + 1)

    # mechanical vent fan type
    fan_type = get_systems_mechanical_ventilation_default_fan_type()
    # mechanical vent fan cfm per Watts
    fan_cfm_per_w = get_fan_cfm_per_w()

    # mechanical vent fan Watts
    fan_power_w = q_tot / fan_cfm_per_w

    new_hpxml.ventilation_fans.add(id: 'MechanicalVentilation',
                                   is_shared_system: false,
                                   fan_type: fan_type,
                                   tested_flow_rate: q_tot.round(2),
                                   hours_in_operation: 24,
                                   fan_power: fan_power_w.round(3),
                                   used_for_whole_building_ventilation: true)
  end

  def self.set_systems_whole_house_fan_reference(orig_hpxml, new_hpxml)
    # nop
  end

  def self.set_systems_water_heater_reference(orig_hpxml, new_hpxml)
    # Exhibit 2 - Service water heating systems
    orig_hpxml.water_heating_systems.each do |orig_water_heater|
      wh_type, wh_fuel_type, wh_tank_vol, energy_factor, recovery_efficiency = get_water_heater_properties(orig_water_heater)

      # New water heater
      new_hpxml.water_heating_systems.add(id: orig_water_heater.id,
                                          is_shared_system: false,
                                          fuel_type: wh_fuel_type,
                                          water_heater_type: wh_type,
                                          location: orig_water_heater.location.gsub('unvented', 'vented'),
                                          tank_volume: wh_tank_vol,
                                          fraction_dhw_load_served: orig_water_heater.fraction_dhw_load_served,
                                          energy_factor: energy_factor,
                                          recovery_efficiency: recovery_efficiency)
    end
  end

  def self.set_systems_water_heating_use_reference(orig_hpxml, new_hpxml)
    return if orig_hpxml.water_heating_systems.size == 0

    # Exhibit 2 - Service Water Heating Systems: Use the same Gallons per Day as Table 4.2.2(1) - Service water heating systems
    standard_piping_length = HotWaterAndAppliances.get_default_std_pipe_length(@has_uncond_bsmnt, @cfa, @ncfl).round(3)

    if orig_hpxml.hot_water_distributions.size == 0
      sys_id = 'HotWaterDistribution'
    else
      sys_id = orig_hpxml.hot_water_distributions[0].id
    end

    bool_low_flow = get_hot_water_distribution_low_flow()
    pipe_r_value = get_hot_water_distribution_pipe_r_value()

    orig_dist = orig_hpxml.hot_water_distributions[0]

    # New hot water distribution
    if orig_dist.has_shared_recirculation
      shared_recirculation_pump_power = orig_dist.shared_recirculation_pump_power
      if not orig_dist.shared_recirculation_motor_efficiency.nil?
        # Adjust power using motor efficiency = 0.85
        shared_recirculation_pump_power *= orig_dist.shared_recirculation_motor_efficiency / 0.85
      end

      new_hpxml.hot_water_distributions.add(id: sys_id,
                                            system_type: HPXML::DHWDistTypeStandard,
                                            pipe_r_value: pipe_r_value,
                                            standard_piping_length: standard_piping_length,
                                            has_shared_recirculation: true,
                                            shared_recirculation_number_of_units_served: orig_dist.shared_recirculation_number_of_units_served,
                                            shared_recirculation_pump_power: shared_recirculation_pump_power,
                                            shared_recirculation_control_type: orig_dist.shared_recirculation_control_type)
    else
      new_hpxml.hot_water_distributions.add(id: sys_id,
                                            system_type: HPXML::DHWDistTypeStandard,
                                            pipe_r_value: pipe_r_value,
                                            standard_piping_length: standard_piping_length)
    end

    # New water fixtures
    if orig_hpxml.water_fixtures.size == 0
      # Shower Head
      new_hpxml.water_fixtures.add(id: 'ShowerHead',
                                   water_fixture_type: HPXML::WaterFixtureTypeShowerhead,
                                   low_flow: bool_low_flow)

      # Faucet
      new_hpxml.water_fixtures.add(id: 'Faucet',
                                   water_fixture_type: HPXML::WaterFixtureTypeFaucet,
                                   low_flow: bool_low_flow)
    else
      orig_hpxml.water_fixtures.each do |orig_water_fixture|
        next unless [HPXML::WaterFixtureTypeShowerhead, HPXML::WaterFixtureTypeFaucet].include? orig_water_fixture.water_fixture_type

        new_hpxml.water_fixtures.add(id: orig_water_fixture.id,
                                     water_fixture_type: orig_water_fixture.water_fixture_type,
                                     low_flow: bool_low_flow)
      end
    end
  end

  def self.set_systems_solar_thermal_reference(orig_hpxml, new_hpxml)
    if [ESConstants.SFPacificVer3_0].include? @program_version
      if orig_hpxml.water_heating_systems.any?  { |wh| (wh.fuel_type == HPXML::FuelTypeElectricity || orig_hpxml.solar_thermal_systems.size > 0) }
        new_hpxml.solar_thermal_systems.add(id: 'SolarThermalSystem',
                                            system_type: 'hot water',
                                            solar_fraction: 0.90)
      end
    end
  end

  def self.set_systems_photovoltaics_reference(orig_hpxml, new_hpxml)
    # nop
  end

  def self.set_systems_batteries_reference(orig_hpxml, new_hpxml)
    # nop
  end

  def self.set_systems_generators_reference(orig_hpxml, new_hpxml)
    # nop
  end

  def self.set_appliances_clothes_washer_reference(orig_hpxml, new_hpxml)
    # Default values
    id = 'ClothesWasher'
    location = HPXML::LocationLivingSpace

    # Override values?
    if not orig_hpxml.clothes_washers.empty?
      clothes_washer = orig_hpxml.clothes_washers[0]
      id = clothes_washer.id
      location = clothes_washer.location.gsub('unvented', 'vented')
    end

    reference_values = HotWaterAndAppliances.get_clothes_washer_default_values(@eri_version)

    new_hpxml.clothes_washers.add(id: id,
                                  location: location,
                                  is_shared_appliance: false,
                                  integrated_modified_energy_factor: reference_values[:integrated_modified_energy_factor],
                                  rated_annual_kwh: reference_values[:rated_annual_kwh],
                                  label_electric_rate: reference_values[:label_electric_rate],
                                  label_gas_rate: reference_values[:label_gas_rate],
                                  label_annual_gas_cost: reference_values[:label_annual_gas_cost],
                                  label_usage: reference_values[:label_usage],
                                  capacity: reference_values[:capacity])
  end

  def self.set_appliances_clothes_dryer_reference(orig_hpxml, new_hpxml)
    # Default values
    id = 'ClothesDryer'
    location = HPXML::LocationLivingSpace
    fuel_type = HPXML::FuelTypeElectricity

    # Override values?
    if not orig_hpxml.clothes_dryers.empty?
      clothes_dryer = orig_hpxml.clothes_dryers[0]
      id = clothes_dryer.id
      location = clothes_dryer.location.gsub('unvented', 'vented')
      fuel_type = clothes_dryer.fuel_type
    end

    reference_values = HotWaterAndAppliances.get_clothes_dryer_default_values(@eri_version, fuel_type)

    new_hpxml.clothes_dryers.add(id: id,
                                 location: location,
                                 is_shared_appliance: false,
                                 fuel_type: fuel_type,
                                 combined_energy_factor: reference_values[:combined_energy_factor])
  end

  def self.set_appliances_dishwasher_reference(orig_hpxml, new_hpxml)
    # Default values
    id = 'Dishwasher'
    location = HPXML::LocationLivingSpace
    place_setting_capacity = 12

    # Override values?
    if not orig_hpxml.dishwashers.empty?
      dishwasher = orig_hpxml.dishwashers[0]
      id = dishwasher.id
      location = dishwasher.location.gsub('unvented', 'vented')
      place_setting_capacity = dishwasher.place_setting_capacity
    end

    if place_setting_capacity < 8
      # Compact
      new_hpxml.dishwashers.add(id: id,
                                location: location,
                                is_shared_appliance: false,
                                rated_annual_kwh: 203.0,
                                place_setting_capacity: place_setting_capacity,
                                label_electric_rate: 0.12,
                                label_gas_rate: 1.09,
                                label_annual_gas_cost: 14.20,
                                label_usage: 4.0) # 208 label cycles per year
    else
      # Standard
      new_hpxml.dishwashers.add(id: id,
                                location: location,
                                is_shared_appliance: false,
                                rated_annual_kwh: 270.0,
                                place_setting_capacity: place_setting_capacity,
                                label_electric_rate: 0.12,
                                label_gas_rate: 1.09,
                                label_annual_gas_cost: 22.23,
                                label_usage: 4.0) # 208 label cycles per year
    end
  end

  def self.set_appliances_refrigerator_reference(orig_hpxml, new_hpxml)
    # Default values
    id = 'Refrigerator'
    location = HPXML::LocationLivingSpace

    # Override values?
    if not orig_hpxml.refrigerators.empty?
      refrigerator = orig_hpxml.refrigerators[0]
      id = refrigerator.id
      location = refrigerator.location.gsub('unvented', 'vented')
    end

    new_hpxml.refrigerators.add(id: id,
                                location: location,
                                rated_annual_kwh: 423.0)
  end

  def self.set_appliances_dehumidifier_reference(orig_hpxml, new_hpxml)
    return if orig_hpxml.dehumidifiers.size == 0

    orig_hpxml.dehumidifiers.each do |dehumidifier|
      reference_values = HVAC.get_dehumidifier_default_values(dehumidifier.capacity)
      new_hpxml.dehumidifiers.add(id: dehumidifier.id,
                                  type: dehumidifier.type, # Per RESNET 55i
                                  capacity: dehumidifier.capacity,
                                  integrated_energy_factor: reference_values[:ief],
                                  rh_setpoint: reference_values[:rh_setpoint],
                                  fraction_served: dehumidifier.fraction_served,
                                  location: dehumidifier.location)
    end
  end

  def self.set_appliances_cooking_range_oven_reference(orig_hpxml, new_hpxml)
    # Default values
    range_id = 'CookingRange'
    location = HPXML::LocationLivingSpace
    fuel_type = HPXML::FuelTypeElectricity
    oven_id = 'Oven'

    # Override values?
    if not orig_hpxml.cooking_ranges.empty?
      cooking_range = orig_hpxml.cooking_ranges[0]
      range_id = cooking_range.id
      location = cooking_range.location.gsub('unvented', 'vented')
      fuel_type = cooking_range.fuel_type
      oven = orig_hpxml.ovens[0]
      oven_id = oven.id
    end

    reference_values = HotWaterAndAppliances.get_range_oven_default_values()
    new_hpxml.cooking_ranges.add(id: range_id,
                                 location: location,
                                 fuel_type: fuel_type,
                                 is_induction: reference_values[:is_induction])
    new_hpxml.ovens.add(id: oven_id,
                        is_convection: reference_values[:is_convection])
  end

  def self.set_lighting_reference(orig_hpxml, new_hpxml)
    if [ESConstants.SFNationalVer3_0, ESConstants.SFPacificVer3_0, ESConstants.SFFloridaVer3_1].include? @program_version
      fFI_int = 0.80
    else
      fFI_int = 0.90
    end
    fFI_ext = 0.0
    fFI_grg = 0.0
    fFII_int = 0.0
    fFII_ext = 0.0
    fFII_grg = 0.0

    new_hpxml.lighting_groups.add(id: "Lighting_#{HPXML::LightingTypeLED}_Interior",
                                  location: HPXML::LocationInterior,
                                  fraction_of_units_in_location: fFII_int,
                                  lighting_type: HPXML::LightingTypeLED)
    new_hpxml.lighting_groups.add(id: "Lighting_#{HPXML::LightingTypeLED}_Exterior",
                                  location: HPXML::LocationExterior,
                                  fraction_of_units_in_location: fFII_ext,
                                  lighting_type: HPXML::LightingTypeLED)
    new_hpxml.lighting_groups.add(id: "Lighting_#{HPXML::LightingTypeLED}_Garage",
                                  location: HPXML::LocationGarage,
                                  fraction_of_units_in_location: fFII_grg,
                                  lighting_type: HPXML::LightingTypeLED)
    new_hpxml.lighting_groups.add(id: "Lighting_#{HPXML::LightingTypeCFL}_Interior",
                                  location: HPXML::LocationInterior,
                                  fraction_of_units_in_location: fFI_int,
                                  lighting_type: HPXML::LightingTypeCFL)
    new_hpxml.lighting_groups.add(id: "Lighting_#{HPXML::LightingTypeCFL}_Exterior",
                                  location: HPXML::LocationExterior,
                                  fraction_of_units_in_location: fFI_ext,
                                  lighting_type: HPXML::LightingTypeCFL)
    new_hpxml.lighting_groups.add(id: "Lighting_#{HPXML::LightingTypeCFL}_Garage",
                                  location: HPXML::LocationGarage,
                                  fraction_of_units_in_location: fFI_grg,
                                  lighting_type: HPXML::LightingTypeCFL)
    new_hpxml.lighting_groups.add(id: "Lighting_#{HPXML::LightingTypeLFL}_Interior",
                                  location: HPXML::LocationInterior,
                                  fraction_of_units_in_location: 0,
                                  lighting_type: HPXML::LightingTypeLFL)
    new_hpxml.lighting_groups.add(id: "Lighting_#{HPXML::LightingTypeLFL}_Exterior",
                                  location: HPXML::LocationExterior,
                                  fraction_of_units_in_location: 0,
                                  lighting_type: HPXML::LightingTypeLFL)
    new_hpxml.lighting_groups.add(id: "Lighting_#{HPXML::LightingTypeLFL}_Garage",
                                  location: HPXML::LocationGarage,
                                  fraction_of_units_in_location: 0,
                                  lighting_type: HPXML::LightingTypeLFL)
  end

  def self.set_ceiling_fans_reference(orig_hpxml, new_hpxml)
    return if orig_hpxml.ceiling_fans.size == 0

    new_hpxml.ceiling_fans.add(id: 'CeilingFans',
                               efficiency: get_default_ceiling_fan_cfm_per_w(),
                               quantity: HVAC.get_default_ceiling_fan_quantity(@nbeds))
  end

  def self.set_misc_loads_reference(orig_hpxml, new_hpxml)
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

  def self.get_hvac_configurations(orig_hpxml)
    hvac_configurations = []
    orig_hpxml.heating_systems.each do |orig_heating_system|
      hvac_configurations << { heating_system: orig_heating_system, cooling_system: orig_heating_system.attached_cooling_system }
    end
    orig_hpxml.cooling_systems.each do |orig_cooling_system|
      # Exclude cooling systems already added to hvac_configurations
      next if hvac_configurations.any? { |config| config[:cooling_system].id == orig_cooling_system.id if not config[:cooling_system].nil? }

      hvac_configurations << { cooling_system: orig_cooling_system }
    end
    orig_hpxml.heat_pumps.each do |orig_heat_pump|
      hvac_configurations << { heat_pump: orig_heat_pump }
    end

    return hvac_configurations
  end

  def self.get_enclosure_compartmentalization_infiltration_rates()
    if ESConstants.MFVersions.include? @program_version
      return 0.30
    end

    fail 'Unexpected case.'
  end

  def self.get_radiant_barrier_bool(orig_hpxml)
    all_ducts = []
    orig_hpxml.hvac_distributions.each do |hvac_dist|
      hvac_dist.ducts.each do |duct|
        all_ducts << duct
      end
    end

    if [ESConstants.SFNationalVer3_0, ESConstants.MFNationalVer1_0].include? @program_version
      # Assumes there is > 10 linear feet of ductwork anytime there is > 0 sqft. of ductwork.
      if ['1A', '1B', '1C', '2A', '2B', '2C', '3A', '3B', '3C'].include?(@iecc_zone)
        all_ducts.each do |duct|
          if [HPXML::LocationAtticVented, HPXML::LocationAtticUnvented].include?(duct.duct_location) && duct.duct_surface_area > 0
            return true
          end
        end
      end
    elsif [ESConstants.SFPacificVer3_0].include? @program_version
      if ['HI'].include? @state_code
        # Assumes there is > 10 linear feet of ductwork anytime there is > 0 sqft. of ductwork.
        all_ducts.each do |duct|
          if [HPXML::LocationAtticVented, HPXML::LocationAtticUnvented].include?(duct.duct_location) && duct.duct_surface_area > 0
            return true
          end
        end
      elsif ['GU', 'MP'].include? @state_code
        return true
      else
        fail "Unexpected state code: #{@state_code}."
      end
    elsif [ESConstants.SFFloridaVer3_1].include? @program_version
      return true
    end

    return false
  end

  def self.get_enclosure_air_infiltration_default(orig_hpxml)
    if ESConstants.MFVersions.include? @program_version
      tot_cb_area, ext_cb_area = orig_hpxml.compartmentalization_boundary_areas()
      cfm50_per_enclosure_area = get_enclosure_compartmentalization_infiltration_rates()

      infil_air_leakage = tot_cb_area * cfm50_per_enclosure_area
      infil_unit_of_measure = HPXML::UnitsCFM

      return infil_air_leakage, infil_unit_of_measure
    elsif ESConstants.SFVersions.include? @program_version
      if [ESConstants.SFNationalVer3_0].include? @program_version
        if ['1A', '1B', '1C', '2A', '2B', '2C'].include? @iecc_zone
          infil_air_leakage = 6.0  # ACH50
        elsif ['3A', '3B', '3C', '4A', '4B'].include? @iecc_zone
          infil_air_leakage = 5.0  # ACH50
        elsif ['4C', '5A', '5B', '5C', '6A', '6B', '6C', '7'].include? @iecc_zone
          infil_air_leakage = 4.0  # ACH50
        elsif ['8'].include? @iecc_zone
          infil_air_leakage = 3.0  # ACH50
        end
      elsif [ESConstants.SFNationalVer3_1].include? @program_version
        if ['1A', '1B', '1C', '2A', '2B', '2C'].include? @iecc_zone
          infil_air_leakage = 4.0
        elsif ['3A', '3B', '3C', '4A', '4B', '4C', '5A', '5B', '5C', '6A', '6B', '6C', '7', '8'].include? @iecc_zone
          infil_air_leakage = 3.0
        end
      elsif [ESConstants.SFPacificVer3_0].include? @program_version
        infil_air_leakage = 6.0  # ACH50
      elsif [ESConstants.SFFloridaVer3_1].include? @program_version
        infil_air_leakage = 5.0  # ACH50
      elsif [ESConstants.SFOregonWashingtonVer3_2].include? @program_version
        infil_air_leakage = 3.0  # ACH50
      end
      infil_unit_of_measure = HPXML::UnitsACH

      return infil_air_leakage, infil_unit_of_measure
    end

    fail 'Unexpected case.'
  end

  def self.get_systems_mechanical_ventilation_default_fan_type()
    if ESConstants.NationalVersions.include? @program_version
      if ['1A', '1B', '1C', '2A', '2B', '2C', '3A', '3B', '3C', '4A', '4B'].include? @iecc_zone
        return HPXML::MechVentTypeSupply
      elsif ['4C', '5A', '5B', '5C', '6A', '6B', '6C', '7', '8'].include? @iecc_zone
        return HPXML::MechVentTypeExhaust
      end
    elsif [ESConstants.SFPacificVer3_0, ESConstants.SFFloridaVer3_1].include? @program_version
      return HPXML::MechVentTypeSupply
    elsif [ESConstants.SFOregonWashingtonVer3_2, ESConstants.MFOregonWashingtonVer1_2].include? @program_version
      return HPXML::MechVentTypeExhaust
    end

    fail 'Unexpected case.'
  end

  def self.get_default_door_ufactor_shgc()
    if [ESConstants.SFNationalVer3_0, ESConstants.MFNationalVer1_0, ESConstants.SFPacificVer3_0, ESConstants.SFFloridaVer3_1].include? @program_version
      return 0.21, nil
    elsif [ESConstants.SFNationalVer3_1, ESConstants.SFOregonWashingtonVer3_2, ESConstants.MFNationalVer1_1, ESConstants.MFOregonWashingtonVer1_2].include? @program_version
      return 0.17, nil
    end

    fail 'Unexpected case.'
  end

  def self.calc_default_total_win_area(orig_hpxml, cfa)
    ag_bndry_wall_area, bg_bndry_wall_area = orig_hpxml.thermal_boundary_wall_areas()
    common_wall_area = orig_hpxml.common_wall_area()
    fa = ag_bndry_wall_area / (ag_bndry_wall_area + 0.5 * bg_bndry_wall_area)
    f = 1.0 - 0.44 * common_wall_area / (ag_bndry_wall_area + common_wall_area)
    return 0.15 * cfa * fa * f
  end

  def self.get_foundation_walls_default_ufactor_or_rvalue()
    if [ESConstants.SFNationalVer3_0].include? @program_version
      if ['1A', '1B', '1C', '2A', '2B', '2C'].include? @iecc_zone
        return 0.360  # assembly U-value
      elsif ['3A', '3B', '3C'].include? @iecc_zone
        return 0.091  # assembly U-value
      elsif ['4A', '4B', '4C', '5A', '5B', '5C'].include? @iecc_zone
        return 0.059  # assembly U-value
      elsif ['6A', '6B', '6C', '7', '8'].include? @iecc_zone
        return 0.050  # assembly U-value
      end
    elsif [ESConstants.SFNationalVer3_1].include? @program_version
      if ['1A', '1B', '1C', '2A', '2B', '2C'].include? @iecc_zone
        return 0.360  # assembly U-value
      elsif ['3A', '3B', '3C'].include? @iecc_zone
        return 0.091  # assembly U-value
      elsif ['4A', '4B'].include? @iecc_zone
        return 0.059  # assembly U-value
      elsif ['4C', '5A', '5B', '5C', '6A', '6B', '6C', '7', '8'].include? @iecc_zone
        return 0.050  # assembly U-value
      end
    elsif [ESConstants.SFPacificVer3_0, ESConstants.SFFloridaVer3_1].include? @program_version
      return 0.360 # assembly U-value
    elsif [ESConstants.SFOregonWashingtonVer3_2].include? @program_version
      return 0.042 # assembly U-value
    elsif [ESConstants.MFNationalVer1_0, ESConstants.MFNationalVer1_1].include? @program_version
      if ['1A', '1B', '1C', '2A', '2B', '2C', '3A', '3B', '3C'].include? @iecc_zone
        return 0.0  # interior insulation R-value
      elsif ['4A', '4B', '4C', '5A', '5B', '5C', '6A', '6B', '6C'].include? @iecc_zone
        return 7.5  # interior insulation R-value
      elsif ['7'].include? @iecc_zone
        return 10.0  # interior insulation R-value
      elsif ['8'].include? @iecc_zone
        return 12.5  # interior insulation R-value
      end
    elsif [ESConstants.MFOregonWashingtonVer1_2].include? @program_version
      return 15.0 # interior insulation R-value
    end

    fail 'Unexpected case.'
  end

  def self.get_enclosure_walls_default_ufactor()
    if [ESConstants.SFNationalVer3_0].include? @program_version
      if ['1A', '1B', '1C', '2A', '2B', '2C', '3A', '3B', '3C', '4A', '4B'].include? @iecc_zone
        return 0.082
      elsif ['4C', '5A', '5B', '5C', '6A', '6B', '6C', '7', '8'].include? @iecc_zone
        return 0.057
      end
    elsif [ESConstants.SFNationalVer3_1].include? @program_version
      if ['1A', '1B', '1C', '2A', '2B', '2C'].include? @iecc_zone
        return 0.082
      elsif ['3A', '3B', '3C', '4A', '4B', '4C', '5A', '5B', '5C'].include? @iecc_zone
        return 0.057
      elsif ['6A', '6B', '6C', '7', '8'].include? @iecc_zone
        return 0.048
      end
    elsif [ESConstants.SFPacificVer3_0].include? @program_version
      if ['HI'].include? @state_code
        return 0.082
      elsif ['GU', 'MP'].include? @state_code
        return 0.401
      end

      fail "Unexpected state code: #{@state_code}."
    elsif [ESConstants.SFFloridaVer3_1].include? @program_version
      return 0.082
    elsif [ESConstants.SFOregonWashingtonVer3_2, ESConstants.MFOregonWashingtonVer1_2].include? @program_version
      return 0.056
    elsif [ESConstants.MFNationalVer1_0].include? @program_version
      if ['1A', '1B', '1C', '2A', '2B', '2C', '3A', '3B', '3C', '4A', '4B'].include? @iecc_zone
        return 0.089
      elsif ['4C', '5A', '5B', '5C'].include? @iecc_zone
        return 0.064
      elsif ['6A', '6B', '6C', '7'].include? @iecc_zone
        return 0.051
      elsif ['8'].include? @iecc_zone
        return 0.036
      end
    elsif [ESConstants.MFNationalVer1_1].include? @program_version
      if ['1A', '1B', '1C', '2A', '2B', '2C', '3A', '3B', '3C', '4A', '4B', '4C', '5A', '5B', '5C'].include? @iecc_zone
        return 0.064
      elsif ['6A', '6B', '6C', '7'].include? @iecc_zone
        return 0.051
      elsif ['8'].include? @iecc_zone
        return 0.036
      end
    end

    fail 'Unexpected case.'
  end

  def self.get_enclosure_floors_over_uncond_spc_default_ufactor()
    if [ESConstants.SFNationalVer3_0, ESConstants.SFNationalVer3_1].include? @program_version
      if ['1A', '1B', '1C', '2A', '2B', '2C'].include? @iecc_zone
        return 0.064
      elsif ['3A', '3B', '3C', '4A', '4B'].include? @iecc_zone
        return 0.047
      elsif ['4C', '5A', '5B', '5C', '6A', '6B', '6C'].include? @iecc_zone
        return 0.033
      elsif ['7', '8'].include? @iecc_zone
        return 0.028
      end
    elsif [ESConstants.SFPacificVer3_0].include? @program_version
      return 0.257
    elsif [ESConstants.SFFloridaVer3_1].include? @program_version
      return 0.064
    elsif [ESConstants.SFOregonWashingtonVer3_2, ESConstants.MFOregonWashingtonVer1_2].include? @program_version
      return 0.028
    elsif [ESConstants.MFNationalVer1_0].include? @program_version
      if ['1A', '1B', '1C'].include? @iecc_zone
        return 0.282
      elsif ['2A', '2B', '2C'].include? @iecc_zone
        return 0.052
      else
        return 0.033
      end
    elsif [ESConstants.MFNationalVer1_1].include? @program_version
      if ['1A', '1B', '1C'].include? @iecc_zone
        return 0.066
      else
        return 0.033
      end
    end

    fail 'Unexpected case.'
  end

  def self.get_hot_water_distribution_low_flow
    if ESConstants.MFVersions.include? @program_version
      return true
    else
      return false
    end
  end

  def self.get_hot_water_distribution_pipe_r_value
    if [ESConstants.SFOregonWashingtonVer3_2, ESConstants.MFOregonWashingtonVer1_2].include? @program_version
      return 3.0
    else
      return 0.0
    end
  end

  def self.get_water_heater_properties(orig_water_heater)
    orig_wh_fuel_type = orig_water_heater.fuel_type.nil? ? orig_water_heater.related_hvac_system.heating_system_fuel : orig_water_heater.fuel_type

    if [ESConstants.SFNationalVer3_0, ESConstants.SFNationalVer3_1, ESConstants.SFFloridaVer3_1].include? @program_version
      if [HPXML::WaterHeaterTypeTankless, HPXML::WaterHeaterTypeCombiTankless].include? orig_water_heater.water_heater_type
        if orig_wh_fuel_type == HPXML::FuelTypeElectricity
          wh_tank_vol = 60.0 # gallon
        else
          wh_tank_vol = 50.0 # gallon
        end
      else
        wh_tank_vol = orig_water_heater.tank_volume
      end

      if [HPXML::FuelTypeNaturalGas, HPXML::FuelTypePropane, HPXML::FuelTypeWoodCord, HPXML::FuelTypeWoodPellets].include? orig_wh_fuel_type
        wh_type = HPXML::WaterHeaterTypeStorage
        wh_fuel_type = HPXML::FuelTypeNaturalGas
        ef = 0.69 - (0.002 * wh_tank_vol) # EnergyStar Exhibit 2: Footnote 14
        re = 0.80
      elsif [HPXML::FuelTypeElectricity].include? orig_wh_fuel_type
        wh_type = HPXML::WaterHeaterTypeStorage
        wh_fuel_type = HPXML::FuelTypeElectricity
        ef = 0.97 - (0.001 * wh_tank_vol) # EnergyStar Exhibit 2: Footnote 14
        re = 0.98
      elsif [HPXML::FuelTypeOil].include? orig_wh_fuel_type
        wh_type = HPXML::WaterHeaterTypeStorage
        wh_fuel_type = HPXML::FuelTypeOil
        ef = 0.61 - (0.002 * wh_tank_vol) # EnergyStar Exhibit 2: Footnote 14
        re = 0.80
      end

      return wh_type, wh_fuel_type, wh_tank_vol, ef.round(2), re

    elsif [ESConstants.MFNationalVer1_0, ESConstants.MFNationalVer1_1].include? @program_version
      if [HPXML::WaterHeaterTypeTankless, HPXML::WaterHeaterTypeCombiTankless].include? orig_water_heater.water_heater_type
        if orig_wh_fuel_type == HPXML::FuelTypeElectricity
          wh_tank_vol = 60.0 # gallon
        else
          wh_tank_vol = 50.0 # gallon
        end
      else
        wh_tank_vol = orig_water_heater.tank_volume
      end

      if [HPXML::FuelTypeNaturalGas, HPXML::FuelTypePropane, HPXML::FuelTypeWoodCord, HPXML::FuelTypeWoodPellets].include? orig_wh_fuel_type
        wh_type = HPXML::WaterHeaterTypeStorage
        wh_fuel_type = HPXML::FuelTypeNaturalGas
        if wh_tank_vol <= 55
          ef = 0.67
          re = 0.80
        else
          ef = 0.77
          re = 0.80
        end
      elsif [HPXML::FuelTypeElectricity].include? orig_wh_fuel_type
        wh_type = HPXML::WaterHeaterTypeStorage
        wh_fuel_type = HPXML::FuelTypeElectricity
        ef = 0.95
        re = 0.98
      elsif [HPXML::FuelTypeOil].include? orig_wh_fuel_type
        wh_type = HPXML::WaterHeaterTypeStorage
        wh_fuel_type = HPXML::FuelTypeOil
        ef = 0.70 - (0.002 * wh_tank_vol) # EnergyStar Multifamily New Construction Exhibit 1: Footnote 10
        re = 0.80
      end

      return wh_type, wh_fuel_type, wh_tank_vol, ef.round(2), re

    elsif [ESConstants.SFPacificVer3_0].include? @program_version
      if [HPXML::WaterHeaterTypeTankless, HPXML::WaterHeaterTypeCombiTankless].include?(orig_water_heater.water_heater_type) || (orig_wh_fuel_type == HPXML::FuelTypeElectricity)
        wh_tank_vol = 50.0 # gallon
      else
        wh_tank_vol = orig_water_heater.tank_volume
      end

      if [HPXML::FuelTypeNaturalGas, HPXML::FuelTypePropane, HPXML::FuelTypeOil, HPXML::FuelTypeWoodCord, HPXML::FuelTypeWoodPellets].include? orig_wh_fuel_type
        wh_type = HPXML::WaterHeaterTypeStorage
        wh_fuel_type = HPXML::FuelTypeNaturalGas
        ef = 0.80 # Gas DHW EF for all storage tank capacities
        re = 0.80
      elsif [HPXML::FuelTypeElectricity].include? orig_wh_fuel_type
        wh_type = HPXML::WaterHeaterTypeStorage
        wh_fuel_type = HPXML::FuelTypeElectricity
        ef = 0.90
        re = 0.98
      end

      return wh_type, wh_fuel_type, wh_tank_vol, ef.round(2), re

    elsif [ESConstants.SFOregonWashingtonVer3_2, ESConstants.MFOregonWashingtonVer1_2].include? @program_version
      if [HPXML::FuelTypeNaturalGas, HPXML::FuelTypePropane, HPXML::FuelTypeWoodCord, HPXML::FuelTypeWoodPellets].include? orig_wh_fuel_type
        wh_type = HPXML::WaterHeaterTypeTankless
        wh_fuel_type = HPXML::FuelTypeNaturalGas
        wh_tank_vol = nil # instantaneous water heater
        ef = 0.91
        re = 0.80
      elsif [HPXML::FuelTypeOil, HPXML::FuelTypeElectricity].include? orig_wh_fuel_type # If Rated Home uses a system with an oil, electric, or other fuel type, model as 60 gallon electric heat pump water heater.
        wh_type = HPXML::WaterHeaterTypeHeatPump
        wh_fuel_type = HPXML::FuelTypeElectricity
        wh_tank_vol = 60.0 # gallon
        if ['4C', '5A', '5B', '5C'].include? @iecc_zone
          ef = 2.50
          re = 0.98
        elsif ['6A', '6B', '6C'].include? @iecc_zone
          ef = 2.00
          re = 0.98
        else
          fail "Unexpected iecc zone: #{@iecc_zone}."
        end
      end

      return wh_type, wh_fuel_type, wh_tank_vol, ef.round(2), re
    end

    fail 'Unexpected case.'
  end

  def self.get_default_boiler_eff(orig_system)
    fuel_type = orig_system.heating_system_fuel
    if orig_system.is_shared_system && orig_system.heating_capacity >= 300000
      if orig_system.distribution_system.hydronic_type == HPXML::HydronicTypeWaterLoop # Central Boiler w/WLHP, >= 300 KBtu/h
        return 0.89 # Et
      else # Central Boiler, >= 300 KBtu/h
        return 0.86 # Et
      end
    else
      if [ESConstants.SFNationalVer3_0, ESConstants.MFNationalVer1_0].include? @program_version
        if [HPXML::FuelTypeNaturalGas, HPXML::FuelTypePropane, HPXML::FuelTypeOil, HPXML::FuelTypeWoodCord, HPXML::FuelTypeWoodPellets].include? fuel_type
          if ['1A', '1B', '1C', '2A', '2B', '2C', '3A', '3B', '3C'].include? @iecc_zone
            return 0.80 # AFUE
          elsif ['4A', '4B', '4C', '5A', '5B', '5C', '6A', '6B', '6C', '7', '8'].include? @iecc_zone
            return 0.85 # AFUE
          end
        elsif fuel_type == HPXML::FuelTypeElectricity
          return 0.98 # AFUE
        end
      elsif [ESConstants.SFNationalVer3_1, ESConstants.MFNationalVer1_1].include? @program_version
        if [HPXML::FuelTypeNaturalGas, HPXML::FuelTypePropane, HPXML::FuelTypeWoodCord, HPXML::FuelTypeWoodPellets].include? fuel_type
          if ['1A', '1B', '1C', '2A', '2B', '2C', '3A', '3B', '3C'].include? @iecc_zone
            return 0.80 # AFUE
          elsif ['4A', '4B', '4C', '5A', '5B', '5C', '6A', '6B', '6C', '7', '8'].include? @iecc_zone
            return 0.90 # AFUE
          end
        elsif fuel_type == HPXML::FuelTypeOil
          if ['1A', '1B', '1C', '2A', '2B', '2C', '3A', '3B', '3C'].include? @iecc_zone
            return 0.80 # AFUE
          elsif ['4A', '4B', '4C', '5A', '5B', '5C', '6A', '6B', '6C', '7', '8'].include? @iecc_zone
            return 0.86 # AFUE
          end
        elsif fuel_type == HPXML::FuelTypeElectricity
          return 0.98 # AFUE
        end
      elsif [ESConstants.SFPacificVer3_0, ESConstants.SFFloridaVer3_1].include? @program_version
        if [HPXML::FuelTypeNaturalGas, HPXML::FuelTypePropane, HPXML::FuelTypeOil, HPXML::FuelTypeWoodCord, HPXML::FuelTypeWoodPellets].include? fuel_type
          return 0.80 # AFUE
        elsif fuel_type == HPXML::FuelTypeElectricity
          return 0.98 # AFUE
        end
      elsif [ESConstants.SFOregonWashingtonVer3_2, ESConstants.MFOregonWashingtonVer1_2].include? @program_version
        if [HPXML::FuelTypeNaturalGas, HPXML::FuelTypePropane, HPXML::FuelTypeWoodCord, HPXML::FuelTypeWoodPellets].include? fuel_type
          return 0.90 # AFUE
        elsif fuel_type == HPXML::FuelTypeOil
          return 0.86 # AFUE
        elsif fuel_type == HPXML::FuelTypeElectricity
          return 0.98 # AFUE
        end
      end

      fail 'Unexpected case.'
    end
  end

  def self.get_default_furnace_afue(fuel_type)
    if [ESConstants.SFNationalVer3_0, ESConstants.MFNationalVer1_0].include? @program_version
      if [HPXML::FuelTypeNaturalGas, HPXML::FuelTypePropane, HPXML::FuelTypeWoodCord, HPXML::FuelTypeWoodPellets].include? fuel_type
        if ['1A', '1B', '1C', '2A', '2B', '2C', '3A', '3B', '3C'].include? @iecc_zone
          return 0.80
        elsif ['4A', '4B', '4C', '5A', '5B', '5C', '6A', '6B', '6C', '7', '8'].include? @iecc_zone
          return 0.90
        end
      elsif fuel_type == HPXML::FuelTypeOil
        if ['1A', '1B', '1C', '2A', '2B', '2C', '3A', '3B', '3C'].include? @iecc_zone
          return 0.80
        elsif ['4A', '4B', '4C', '5A', '5B', '5C', '6A', '6B', '6C', '7', '8'].include? @iecc_zone
          return 0.85
        end
      end
    elsif [ESConstants.SFNationalVer3_1, ESConstants.MFNationalVer1_1].include? @program_version
      if [HPXML::FuelTypeNaturalGas, HPXML::FuelTypePropane, HPXML::FuelTypeWoodCord, HPXML::FuelTypeWoodPellets].include? fuel_type
        if ['1A', '1B', '1C', '2A', '2B', '2C', '3A', '3B', '3C'].include? @iecc_zone
          return 0.80
        elsif ['4A', '4B', '4C', '5A', '5B', '5C', '6A', '6B', '6C', '7', '8'].include? @iecc_zone
          return 0.95
        end
      elsif fuel_type == HPXML::FuelTypeOil
        if ['1A', '1B', '1C', '2A', '2B', '2C', '3A', '3B', '3C'].include? @iecc_zone
          return 0.80
        elsif ['4A', '4B', '4C', '5A', '5B', '5C', '6A', '6B', '6C', '7', '8'].include? @iecc_zone
          return 0.85
        end
      end
    elsif [ESConstants.SFPacificVer3_0, ESConstants.SFFloridaVer3_1].include? @program_version
      if [HPXML::FuelTypeNaturalGas, HPXML::FuelTypePropane, HPXML::FuelTypeOil, HPXML::FuelTypeWoodCord, HPXML::FuelTypeWoodPellets].include? fuel_type
        return 0.80
      end
    elsif [ESConstants.SFOregonWashingtonVer3_2, ESConstants.MFOregonWashingtonVer1_2].include? @program_version
      if [HPXML::FuelTypeNaturalGas, HPXML::FuelTypePropane, HPXML::FuelTypeWoodCord, HPXML::FuelTypeWoodPellets].include? fuel_type
        return 0.95
      elsif fuel_type == HPXML::FuelTypeOil
        return 0.85
      end
    end

    fail 'Unexpected case.'
  end

  def self.get_default_ashp_hspf()
    if ESConstants.NationalVersions.include? @program_version
      if ['1A', '1B', '1C', '2A', '2B', '2C', '3A', '3B', '3C'].include? @iecc_zone
        return 8.2
      elsif ['4A', '4B'].include? @iecc_zone
        return 8.5
      elsif ['4C', '5A', '5B', '5C'].include? @iecc_zone
        return 9.25
      elsif ['6A', '6B', '6C'].include? @iecc_zone
        return 9.5
      else
        return
      end
    elsif [ESConstants.SFPacificVer3_0, ESConstants.SFFloridaVer3_1].include? @program_version
      return 8.2
    elsif [ESConstants.SFOregonWashingtonVer3_2, ESConstants.MFOregonWashingtonVer1_2].include? @program_version
      return 9.5
    end

    fail 'Unexpected case.'
  end

  def self.get_default_heat_pump_backup_fuel()
    if ESConstants.NationalVersions.include? @program_version
      if ['1A', '1B', '1C', '2A', '2B', '2C', '3A', '3B', '3C', '4A', '4B', '4C', '5A', '5B', '5C', '6A', '6B', '6C'].include? @iecc_zone
        return HPXML::FuelTypeElectricity
      else
        return
      end
    elsif [ESConstants.SFPacificVer3_0, ESConstants.SFFloridaVer3_1, ESConstants.SFOregonWashingtonVer3_2, ESConstants.MFOregonWashingtonVer1_2].include? @program_version
      return HPXML::FuelTypeElectricity
    end

    fail 'Unexpected case.'
  end

  def self.get_default_gshp_cop()
    if [ESConstants.SFNationalVer3_0, ESConstants.MFNationalVer1_0].include? @program_version
      if ['7', '8'].include? @iecc_zone
        return 3.5
      else
        return # nop
      end
    elsif [ESConstants.SFNationalVer3_1, ESConstants.MFNationalVer1_1].include? @program_version
      if ['7', '8'].include? @iecc_zone
        return 3.6
      else
        return # nop
      end
    end

    fail 'Unexpected case.'
  end

  def self.get_default_wlhp_cop()
    return 4.2
  end

  def self.get_default_wlhp_eer()
    return 14.0
  end

  def self.get_default_chiller_kw_per_ton()
    return 0.78
  end

  def self.get_default_ac_seer()
    if [ESConstants.SFNationalVer3_0, ESConstants.MFNationalVer1_0].include? @program_version
      if ['1A', '1B', '1C', '2A', '2B', '2C', '3A', '3B', '3C'].include? @iecc_zone
        return 14.5
      elsif ['4A', '4B', '4C', '5A', '5B', '5C', '6A', '6B', '6C', '7', '8'].include? @iecc_zone
        return 13.0
      end
    elsif [ESConstants.SFNationalVer3_1, ESConstants.MFNationalVer1_1].include? @program_version
      if ['1A', '1B', '1C', '2A', '2B', '2C', '3A', '3B', '3C'].include? @iecc_zone
        return 15.0
      elsif ['4A', '4B', '4C', '5A', '5B', '5C', '6A', '6B', '6C', '7', '8'].include? @iecc_zone
        return 13.0
      end
    elsif [ESConstants.SFPacificVer3_0].include? @program_version
      return 14.5
    elsif [ESConstants.SFFloridaVer3_1].include? @program_version
      return 15.0
    elsif [ESConstants.SFOregonWashingtonVer3_2, ESConstants.MFOregonWashingtonVer1_2].include? @program_version
      return 13.0
    end

    fail 'Unexpected case.'
  end

  def self.get_default_ashp_seer()
    if [ESConstants.SFNationalVer3_0, ESConstants.MFNationalVer1_0].include? @program_version
      if not ['7', '8'].include? @iecc_zone
        return 14.5
      else
        return # nop
      end
    elsif [ESConstants.SFNationalVer3_1, ESConstants.MFNationalVer1_1].include? @program_version
      if not ['7', '8'].include? @iecc_zone
        return 15.0
      else
        return # nop
      end
    elsif [ESConstants.SFPacificVer3_0].include? @program_version
      return 14.5
    elsif [ESConstants.SFFloridaVer3_1, ESConstants.SFOregonWashingtonVer3_2, ESConstants.MFOregonWashingtonVer1_2].include? @program_version
      return 15.0
    end

    fail 'Unexpected case.'
  end

  def self.get_default_gshp_eer()
    if [ESConstants.SFNationalVer3_0, ESConstants.MFNationalVer1_0].include? @program_version
      if ['7', '8'].include? @iecc_zone
        return 16.1
      else
        return # nop
      end
    elsif [ESConstants.SFNationalVer3_1, ESConstants.MFNationalVer1_1].include? @program_version
      if ['7', '8'].include? @iecc_zone
        return 17.1
      else
        return # nop
      end
    end

    fail 'Unexpected case.'
  end

  def self.get_fan_cfm_per_w()
    if [ESConstants.SFNationalVer3_0, ESConstants.MFNationalVer1_0, ESConstants.SFPacificVer3_0, ESConstants.SFFloridaVer3_1].include? @program_version
      return 2.2
    elsif [ESConstants.SFNationalVer3_1, ESConstants.SFOregonWashingtonVer3_2, ESConstants.MFNationalVer1_1, ESConstants.MFOregonWashingtonVer1_2].include? @program_version
      return 2.8
    end

    fail 'Unexpected case.'
  end

  def self.get_foundation_type(orig_hpxml)
    adiabatic_floor_area = 0.0
    ambient_floor_area = 0.0
    crawlspace_floor_area = 0.0
    basement_floor_area = 0.0
    slab_on_grade_area = 0.0
    # calculate floor area by frame floor type
    orig_hpxml.frame_floors.each do |orig_frame_floor|
      next unless orig_frame_floor.is_floor
      next unless orig_frame_floor.interior_adjacent_to == HPXML::LocationLivingSpace

      if orig_frame_floor.exterior_adjacent_to == HPXML::LocationOtherHousingUnit
        adiabatic_floor_area += orig_frame_floor.area
      elsif orig_frame_floor.exterior_adjacent_to == HPXML::LocationOutside
        ambient_floor_area += orig_frame_floor.area
      end
    end
    # calculate floor area by slab type
    orig_hpxml.slabs.each do |orig_slab|
      if orig_slab.interior_adjacent_to == HPXML::LocationBasementConditioned || orig_slab.interior_adjacent_to == HPXML::LocationBasementUnconditioned
        basement_floor_area += orig_slab.area
      elsif orig_slab.interior_adjacent_to == HPXML::LocationCrawlspaceVented || orig_slab.interior_adjacent_to == HPXML::LocationCrawlspaceUnvented
        crawlspace_floor_area += orig_slab.area
      elsif orig_slab.interior_adjacent_to == HPXML::LocationLivingSpace
        slab_on_grade_area += orig_slab.area
      end
    end

    predominant_foundation_type = { basement: basement_floor_area, crawlspace: crawlspace_floor_area, slab: slab_on_grade_area, ambient: ambient_floor_area, adiabatic: adiabatic_floor_area }.max_by { |k, v| v }[0] # find the key of the largest area
    return predominant_foundation_type.to_s
  end

  def self.get_ceiling_type(orig_hpxml)
    total_ceiling_area = 0.0
    adiabatic_ceiling_area = 0.0
    ceiling_exterior_boundary = []
    # calculate total ceiling area and adiabatic ceiling area
    orig_hpxml.frame_floors.each do |orig_frame_floor|
      next unless orig_frame_floor.is_ceiling

      total_ceiling_area += orig_frame_floor.area

      ceiling_exterior_boundary << orig_frame_floor.exterior_adjacent_to unless ceiling_exterior_boundary.include?(orig_frame_floor.exterior_adjacent_to)

      next unless [HPXML::LocationLivingSpace, HPXML::LocationOtherHousingUnit].include? orig_frame_floor.exterior_adjacent_to

      adiabatic_ceiling_area += orig_frame_floor.area
    end

    if (total_ceiling_area == adiabatic_ceiling_area) && (total_ceiling_area > 0)
      return 'adiabatic'
    elsif ceiling_exterior_boundary.length() > 1
      return 'multi_ceiling_types'
    end
  end

  def self.get_duct_location_and_surface_area(orig_hpxml, total_duct_area)
    # EPA confirmed that duct percentages apply to ASHRAE 152 *total* duct area
    duct_location_and_surface_area = {}
    foundation_type_for_ducts = get_foundation_type(orig_hpxml)
    ceiling_type_for_ducts = get_ceiling_type(orig_hpxml)
    if [ESConstants.SFNationalVer3_0, ESConstants.SFPacificVer3_0, ESConstants.SFOregonWashingtonVer3_2].include? @program_version
      if foundation_type_for_ducts == 'basement' # basement is the only foundation type or the predominant foundation type
        if @ncfl_ag == 1
          if @has_cond_bsmnt
            duct_location_and_surface_area[HPXML::LocationBasementConditioned] = total_duct_area
          elsif @has_uncond_bsmnt
            duct_location_and_surface_area[HPXML::LocationBasementUnconditioned] = total_duct_area
          else
            fail "Could not find 'basement - conditioned' or 'basement - unconditioned' for duct location in the model."
          end
        else # two or more story above-grade
          if @has_cond_bsmnt
            duct_location_and_surface_area[HPXML::LocationBasementConditioned] = 0.5 * total_duct_area
          elsif @has_uncond_bsmnt
            duct_location_and_surface_area[HPXML::LocationBasementUnconditioned] = 0.5 * total_duct_area
          else
            fail "Could not find 'basement - conditioned' or 'basement - unconditioned' for duct location in the model."
          end
          duct_location_and_surface_area[HPXML::LocationAtticVented] = 0.5 * total_duct_area
        end
      elsif foundation_type_for_ducts == 'crawlspace' # crawlspace is the only foundation type or the predominant foundation type
        if @ncfl_ag == 1
          duct_location_and_surface_area[HPXML::LocationCrawlspaceVented] = total_duct_area
        else # two or more story above-grade
          duct_location_and_surface_area[HPXML::LocationCrawlspaceVented] = 0.5 * total_duct_area
          duct_location_and_surface_area[HPXML::LocationAtticVented] = 0.5 * total_duct_area
        end
      elsif foundation_type_for_ducts == 'ambient' # floor adjacent to ambient is the only foundation type or the predominant foundation type
        if @ncfl_ag == 1
          duct_location_and_surface_area[HPXML::LocationOutside] = total_duct_area
        else # two or more story above-grade
          duct_location_and_surface_area[HPXML::LocationOutside] = 0.5 * total_duct_area
          duct_location_and_surface_area[HPXML::LocationAtticVented] = 0.5 * total_duct_area
        end
      elsif foundation_type_for_ducts == 'adiabatic' # adiabatic floor is the only foundation type or the predominant foundation type
        duct_location_and_surface_area[HPXML::LocationAtticVented] = total_duct_area
      elsif foundation_type_for_ducts == 'slab' # slab is the only foundation type or the predominant foundation type
        if @ncfl_ag == 1
          duct_location_and_surface_area[HPXML::LocationAtticVented] = total_duct_area
        else # two or more story above-grade
          duct_location_and_surface_area[HPXML::LocationAtticVented] = 0.75 * total_duct_area
          duct_location_and_surface_area[HPXML::LocationLivingSpace] = 0.25 * total_duct_area
        end
      end
    elsif [ESConstants.SFNationalVer3_1, ESConstants.SFFloridaVer3_1, ESConstants.MFNationalVer1_1].include? @program_version
      duct_location_and_surface_area[HPXML::LocationLivingSpace] = total_duct_area # Duct location configured to be 100% in conditioned space.
    elsif [ESConstants.MFNationalVer1_0, ESConstants.MFOregonWashingtonVer1_2].include? @program_version
      if ceiling_type_for_ducts == 'adiabatic'
        duct_location_and_surface_area[HPXML::LocationLivingSpace] = total_duct_area
      else
        if @ncfl_ag == 1
          duct_location_and_surface_area[HPXML::LocationAtticVented] = total_duct_area
        else # all other unit
          duct_location_and_surface_area[HPXML::LocationAtticVented] = 0.75 * total_duct_area
          duct_location_and_surface_area[HPXML::LocationLivingSpace] = 0.25 * total_duct_area
        end
      end
    end

    if duct_location_and_surface_area.empty?
      fail 'Unexpected case.'
    end

    return duct_location_and_surface_area
  end

  def self.get_duct_insulation_r_value(duct_type, duct_location)
    if [ESConstants.SFNationalVer3_0, ESConstants.MFNationalVer1_0, ESConstants.SFPacificVer3_0].include? @program_version
      if (duct_type == HPXML::DuctTypeSupply) && [HPXML::LocationAtticUnvented, HPXML::LocationAtticVented].include?(duct_location) # Supply ducts located in unconditioned attic
        return 8.0
      elsif [HPXML::LocationLivingSpace, HPXML::LocationBasementConditioned].include?(duct_location) # Ducts in conditioned space
        return 0.0
      else # All other ducts in unconditioned space
        return 6.0
      end
    elsif [ESConstants.SFNationalVer3_1, ESConstants.SFFloridaVer3_1, ESConstants.MFNationalVer1_1].include? @program_version
      return 0.0
    elsif [ESConstants.SFOregonWashingtonVer3_2, ESConstants.MFOregonWashingtonVer1_2].include? @program_version
      if [HPXML::LocationLivingSpace, HPXML::LocationBasementConditioned].include?(duct_location) # Ducts in conditioned space
        return 0.0
      else # All ducts located in unconditioned space
        return 8.0
      end
    end
  end

  def self.calc_default_duct_leakage_to_outside(cfa)
    if [ESConstants.SFNationalVer3_1, ESConstants.SFFloridaVer3_1, ESConstants.MFNationalVer1_1].include? @program_version
      return 0.0
    else
      return [(0.04 * cfa), 40].max
    end

    fail 'Unexpected case.'
  end

  def self.add_air_distribution(orig_hpxml, orig_system)
    i = 0
    while true
      i += 1
      dist_id = "HVACDistributionDucted_#{i}"
      next if orig_hpxml.hvac_distributions.select { |d| d.id == dist_id }.size > 0

      orig_hpxml.hvac_distributions.add(id: dist_id,
                                        distribution_system_type: HPXML::HVACDistributionTypeAir,
                                        air_type: HPXML::AirTypeRegularVelocity)

      # Remove existing distribution system, if one exists
      if not orig_system.distribution_system.nil?
        orig_system.distribution_system.delete
      end

      return dist_id
    end
  end

  def self.add_reference_heating_boiler(orig_hpxml, new_hpxml, orig_system)
    afue = get_default_boiler_eff(orig_system)

    if orig_system.is_shared_system # Retain the shared boiler regardless of its heating capacity.
      heating_capacity = orig_system.heating_capacity
      number_of_units_served = orig_system.number_of_units_served

      shared_loop_watts = orig_system.shared_loop_watts
      if not orig_system.shared_loop_motor_efficiency.nil?
        # Adjust power using motor efficiency = 0.85
        shared_loop_watts *= orig_system.shared_loop_motor_efficiency / 0.85
      end
    end

    heating_capacity = -1 if heating_capacity.nil? # Use auto-sizing

    new_hpxml.heating_systems.add(id: "HeatingSystem#{new_hpxml.heating_systems.size + 1}",
                                  distribution_system_idref: orig_system.distribution_system.id,
                                  is_shared_system: orig_system.is_shared_system,
                                  number_of_units_served: number_of_units_served,
                                  heating_system_type: HPXML::HVACTypeBoiler,
                                  heating_system_fuel: orig_system.heating_system_fuel,
                                  heating_capacity: heating_capacity,
                                  shared_loop_watts: shared_loop_watts,
                                  fan_coil_watts: orig_system.fan_coil_watts,
                                  heating_efficiency_afue: afue,
                                  fraction_heat_load_served: orig_system.fraction_heat_load_served)
  end

  def self.add_reference_heating_furnace(orig_hpxml, new_hpxml, load_frac, orig_system)
    furnace_afue = get_default_furnace_afue(orig_system.heating_system_fuel)
    furnace_fuel_type = orig_system.heating_system_fuel
    if (not orig_system.distribution_system.nil?) && (orig_system.distribution_system.distribution_system_type == HPXML::HVACDistributionTypeAir)
      dist_id = orig_system.distribution_system.id
    else
      dist_id = add_air_distribution(orig_hpxml, orig_system)
    end

    new_hpxml.heating_systems.add(id: "HeatingSystem#{new_hpxml.heating_systems.size + 1}",
                                  distribution_system_idref: dist_id,
                                  heating_system_type: HPXML::HVACTypeFurnace,
                                  heating_system_fuel: furnace_fuel_type,
                                  heating_capacity: -1, # Use auto-sizing
                                  heating_efficiency_afue: furnace_afue,
                                  fraction_heat_load_served: load_frac,
                                  airflow_defect_ratio: -0.25,
                                  fan_watts_per_cfm: 0.58)
  end

  def self.add_reference_cooling_air_conditioner(orig_hpxml, new_hpxml, load_frac, orig_system)
    seer = get_default_ac_seer()
    shr = orig_system.cooling_shr
    if (not orig_system.distribution_system.nil?) && (orig_system.distribution_system.distribution_system_type == HPXML::HVACDistributionTypeAir)
      dist_id = orig_system.distribution_system.id
    else
      dist_id = add_air_distribution(orig_hpxml, orig_system)
    end

    new_hpxml.cooling_systems.add(id: "CoolingSystem#{new_hpxml.cooling_systems.size + 1}",
                                  distribution_system_idref: dist_id,
                                  cooling_system_type: HPXML::HVACTypeCentralAirConditioner,
                                  cooling_system_fuel: HPXML::FuelTypeElectricity,
                                  cooling_capacity: -1, # Use auto-sizing
                                  fraction_cool_load_served: load_frac,
                                  cooling_efficiency_seer: seer,
                                  cooling_shr: shr,
                                  charge_defect_ratio: -0.25,
                                  airflow_defect_ratio: -0.25,
                                  fan_watts_per_cfm: 0.58)
  end

  def self.add_reference_cooling_chiller_or_cooling_tower(orig_hpxml, new_hpxml, orig_system)
    if orig_system.cooling_system_type == HPXML::HVACTypeChiller
      kw_per_ton = get_default_chiller_kw_per_ton()
    end

    shared_loop_watts = orig_system.shared_loop_watts
    if not orig_system.shared_loop_motor_efficiency.nil?
      # Adjust power using motor efficiency = 0.85
      shared_loop_watts *= orig_system.shared_loop_motor_efficiency / 0.85
    end

    new_hpxml.cooling_systems.add(id: "CoolingSystem#{new_hpxml.cooling_systems.size + 1}",
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

  def self.add_reference_heat_pump(orig_hpxml, new_hpxml, heat_load_frac, cool_load_frac, orig_htg_system, orig_clg_system = nil)
    # Heat pump type and efficiency

    if orig_htg_system.is_a?(HPXML::HeatPump) && (orig_htg_system.heat_pump_type == HPXML::HVACTypeHeatPumpWaterLoopToAir)
      heat_pump_type = HPXML::HVACTypeHeatPumpWaterLoopToAir
      cop = get_default_wlhp_cop()
      eer = get_default_wlhp_eer()
      cooling_capacity = orig_htg_system.cooling_capacity
      heating_capacity = orig_htg_system.heating_capacity
      backup_heating_capacity = orig_htg_system.backup_heating_capacity
      dist_id = orig_htg_system.distribution_system.id
    else
      if ['7', '8'].include? @iecc_zone
        heat_pump_type = HPXML::HVACTypeHeatPumpGroundToAir
        cop = get_default_gshp_cop()
        eer = get_default_gshp_eer()
      else
        heat_pump_type = HPXML::HVACTypeHeatPumpAirToAir
        hspf = get_default_ashp_hspf()
        seer = get_default_ashp_seer()
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
          # Adjust power using motor efficiency = 0.85
          shared_loop_watts *= orig_htg_system.shared_loop_motor_efficiency / 0.85
        end
      end
      if (not orig_htg_system.distribution_system.nil?) && (orig_htg_system.distribution_system.distribution_system_type == HPXML::HVACDistributionTypeAir)
        dist_id = orig_htg_system.distribution_system.id
      else
        dist_id = add_air_distribution(orig_hpxml, orig_htg_system)
      end
    end

    cooling_capacity = -1 if cooling_capacity.nil? # Use auto-sizing
    heating_capacity = -1 if heating_capacity.nil? # Use auto-sizing
    backup_heating_capacity = -1 if backup_heating_capacity.nil? # Use auto-sizing

    if heat_pump_type == HPXML::HVACTypeHeatPumpAirToAir
      heat_pump_backup_fuel = get_default_heat_pump_backup_fuel()
      heat_pump_backup_type = HPXML::HeatPumpBackupTypeIntegrated unless heat_pump_backup_fuel.nil?
      heat_pump_backup_eff = 1.0 unless heat_pump_backup_fuel.nil?
      heating_capacity_17F = -1 if heating_capacity_17F.nil? # Use auto-sizing
    elsif heat_pump_type == HPXML::HVACTypeHeatPumpGroundToAir
      pump_watts_per_ton = HVAC.get_default_gshp_pump_power()
    end

    if (not orig_htg_system.nil?) && orig_htg_system.respond_to?(:cooling_shr)
      shr = orig_htg_system.cooling_shr
    end
    if (not orig_clg_system.nil?) && orig_clg_system.respond_to?(:cooling_shr)
      shr = orig_clg_system.cooling_shr
    end

    if heat_pump_type != HPXML::HVACTypeHeatPumpWaterLoopToAir
      charge_defect_ratio = -0.25
      airflow_defect_ratio = -0.25
      fan_watts_per_cfm = 0.58
    end

    new_hpxml.heat_pumps.add(id: "HeatPump#{new_hpxml.heat_pumps.size + 1}",
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
                             pump_watts_per_ton: pump_watts_per_ton,
                             cooling_shr: shr,
                             charge_defect_ratio: charge_defect_ratio,
                             airflow_defect_ratio: airflow_defect_ratio,
                             fan_watts_per_cfm: fan_watts_per_cfm,
                             shared_loop_watts: shared_loop_watts)
  end

  def self.get_default_ceiling_fan_cfm_per_w()
    return 122.0 # CFM per Watts
  end

  def self.get_reference_ceiling_ufactor()
    # Ceiling U-Factor
    if [ESConstants.SFNationalVer3_0].include? @program_version
      if ['1A', '1B', '1C', '2A', '2B', '2C', '3A', '3B', '3C'].include? @iecc_zone
        return 0.035
      elsif ['4A', '4B', '4C', '5A', '5B', '5C'].include? @iecc_zone
        return 0.030
      elsif ['6A', '6B', '6C', '7', '8'].include? @iecc_zone
        return 0.026
      end
    elsif [ESConstants.SFNationalVer3_1].include? @program_version
      if ['1A', '1B', '1C'].include? @iecc_zone
        return 0.035
      elsif ['2A', '2B', '2C', '3A', '3B', '3C'].include? @iecc_zone
        return 0.030
      elsif ['4A', '4B', '4C', '5A', '5B', '5C', '6A', '6B', '6C', '7', '8'].include? @iecc_zone
        return 0.026
      end
    elsif [ESConstants.SFPacificVer3_0].include? @program_version
      return 0.035
    elsif [ESConstants.SFFloridaVer3_1].include? @program_version
      return 0.035
    elsif [ESConstants.SFOregonWashingtonVer3_2, ESConstants.MFOregonWashingtonVer1_2].include? @program_version
      return 0.026
    elsif [ESConstants.MFNationalVer1_0].include? @program_version
      return 0.027
    elsif [ESConstants.MFNationalVer1_1].include? @program_version
      if ['1A', '1B', '1C', '2A', '2B', '2C', '3A', '3B', '3C', '4A', '4B'].include? @iecc_zone
        return 0.027
      elsif ['4C', '5A', '5B', '5C', '6A', '6B', '6C', '7', '8'].include? @iecc_zone
        return 0.021
      end
    end
  end

  def self.get_reference_slab_perimeter_rvalue_depth()
    if [ESConstants.SFNationalVer3_0, ESConstants.SFNationalVer3_1].include? @program_version
      # Table 4.2.2(2) - Component Heat Transfer Characteristics for Reference Home
      # Slab-on-Grade R-Value & Depth (ft)
      if ['1A', '1B', '1C', '2A', '2B', '2C', '3A', '3B', '3C'].include? @iecc_zone
        return 0.0, 0.0
      elsif ['4A', '4B', '4C', '5A', '5B', '5C'].include? @iecc_zone
        return 10.0, 2.0
      elsif ['6A', '6B', '6C', '7', '8'].include? @iecc_zone
        return 10.0, 4.0
      end
    elsif [ESConstants.MFNationalVer1_0, ESConstants.MFNationalVer1_1].include? @program_version
      if ['1A', '1B', '1C', '2A', '2B', '2C', '3A', '3B', '3C'].include? @iecc_zone
        return 0.0, 0.0
      elsif ['4A', '4B', '4C', '5A', '5B', '5C'].include? @iecc_zone
        return 10.0, 2.0
      elsif ['6A', '6B', '6C', '7'].include? @iecc_zone
        return 15.0, 2.0
      elsif ['8'].include? @iecc_zone
        return 20.0, 2.0
      end
    elsif [ESConstants.SFPacificVer3_0, ESConstants.SFFloridaVer3_1].include? @program_version
      return 0.0, 0.0
    elsif [ESConstants.SFOregonWashingtonVer3_2, ESConstants.MFOregonWashingtonVer1_2].include? @program_version
      return 10.0, 2.0
    end
  end

  def self.get_reference_slab_under_rvalue_width()
    if [ESConstants.SFOregonWashingtonVer3_2, ESConstants.MFOregonWashingtonVer1_2].include? @program_version
      return 10.0, nil # insulation under the entire slab
    else
      return 0.0, 0.0
    end
  end

  def self.get_reference_glazing_ufactor_shgc(orig_window)
    # Fenestration U-Factor and SHGC

    if [ESConstants.SFNationalVer3_0].include? @program_version
      if ['1A', '1B', '1C', '2A', '2B', '2C'].include? @iecc_zone
        return 0.60, 0.27
      elsif ['3A', '3B', '3C'].include? @iecc_zone
        return 0.35, 0.30
      elsif ['4A', '4B'].include? @iecc_zone
        return 0.32, 0.40
      elsif ['4C', '5A', '5B', '5C', '6A', '6B', '6C', '7', '8'].include? @iecc_zone
        return 0.30, 0.40
      end

    elsif [ESConstants.SFNationalVer3_1].include? @program_version
      if ['1A', '1B', '1C', '2A', '2B', '2C'].include? @iecc_zone
        return 0.40, 0.25
      elsif ['3A', '3B', '3C'].include? @iecc_zone
        return 0.30, 0.25
      elsif ['4A', '4B'].include? @iecc_zone
        return 0.30, 0.40
      elsif ['4C', '5A', '5B', '5C', '6A', '6B', '6C', '7', '8'].include? @iecc_zone
        return 0.27, 0.40
      end

    elsif [ESConstants.SFPacificVer3_0].include? @program_version
      return 0.60, 0.27

    elsif [ESConstants.SFFloridaVer3_1].include? @program_version
      return 0.65, 0.27

    elsif [ESConstants.SFOregonWashingtonVer3_2].include? @program_version
      return 0.27, 0.30

    elsif [ESConstants.MFNationalVer1_0].include? @program_version
      if orig_window.performance_class == HPXML::WindowClassArchitectural
        if orig_window.fraction_operable > 0
          if ['1A', '1B', '1C', '2A', '2B', '2C'].include? @iecc_zone
            return 0.65, 0.27
          elsif ['3A', '3B', '3C'].include? @iecc_zone
            return 0.60, 0.30
          elsif ['4A', '4B', '4C', '5A', '5B', '5C'].include? @iecc_zone
            return 0.45, 0.40
          elsif ['6A', '6B', '6C'].include? @iecc_zone
            return 0.43, 0.40
          elsif ['7', '8'].include? @iecc_zone
            return 0.37, 0.40
          end
        else
          if ['1A', '1B', '1C', '2A', '2B', '2C'].include? @iecc_zone
            return 0.50, 0.27
          elsif ['3A', '3B', '3C'].include? @iecc_zone
            return 0.46, 0.30
          elsif ['4A', '4B', '4C', '5A', '5B', '5C'].include? @iecc_zone
            return 0.38, 0.40
          elsif ['6A', '6B', '6C'].include? @iecc_zone
            return 0.36, 0.40
          elsif ['7', '8'].include? @iecc_zone
            return 0.29, 0.40
          end
        end
      else
        if ['1A', '1B', '1C', '2A', '2B', '2C'].include? @iecc_zone
          return 0.60, 0.27
        elsif ['3A', '3B', '3C'].include? @iecc_zone
          return 0.35, 0.30
        elsif ['4A', '4B'].include? @iecc_zone
          return 0.32, 0.40
        elsif ['4C', '5A', '5B', '5C', '6A', '6B', '6C', '7', '8'].include? @iecc_zone
          return 0.30, 0.40
        end
      end

    elsif [ESConstants.MFNationalVer1_1].include? @program_version
      if orig_window.performance_class == HPXML::WindowClassArchitectural
        if orig_window.fraction_operable > 0
          if ['1A', '1B', '1C', '2A', '2B', '2C'].include? @iecc_zone
            return 0.62, 0.25
          elsif ['3A', '3B', '3C'].include? @iecc_zone
            return 0.57, 0.25
          elsif ['4A', '4B', '4C', '5A', '5B', '5C'].include? @iecc_zone
            return 0.43, 0.40
          elsif ['6A', '6B', '6C'].include? @iecc_zone
            return 0.41, 0.40
          elsif ['7', '8'].include? @iecc_zone
            return 0.35, 0.40
          end
        else
          if ['1A', '1B', '1C', '2A', '2B', '2C'].include? @iecc_zone
            return 0.48, 0.25
          elsif ['3A', '3B', '3C'].include? @iecc_zone
            return 0.44, 0.25
          elsif ['4A', '4B', '4C', '5A', '5B', '5C'].include? @iecc_zone
            return 0.36, 0.40
          elsif ['6A', '6B', '6C'].include? @iecc_zone
            return 0.34, 0.40
          elsif ['7', '8'].include? @iecc_zone
            return 0.28, 0.40
          end
        end
      else
        if ['1A', '1B', '1C', '2A', '2B', '2C'].include? @iecc_zone
          return 0.40, 0.25
        elsif ['3A', '3B', '3C'].include? @iecc_zone
          return 0.30, 0.25
        elsif ['4A', '4B'].include? @iecc_zone
          return 0.30, 0.40
        elsif ['4C', '5A', '5B', '5C', '6A', '6B', '6C', '7', '8'].include? @iecc_zone
          return 0.27, 0.40
        end
      end

    elsif [ESConstants.MFOregonWashingtonVer1_2].include? @program_version
      if orig_window.performance_class == HPXML::WindowClassArchitectural
        if orig_window.fraction_operable > 0
          if ['4C', '5A', '5B', '5C'].include? @iecc_zone
            return 0.43, 0.30
          elsif ['6A', '6B', '6C'].include? @iecc_zone
            return 0.41, 0.30
          end
        else
          if ['4C', '5A', '5B', '5C'].include? @iecc_zone
            return 0.36, 0.30
          elsif ['6A', '6B', '6C'].include? @iecc_zone
            return 0.34, 0.30
          end
        end
      else
        return 0.27, 0.30
      end

    end
  end
end
