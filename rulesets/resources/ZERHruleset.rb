# frozen_string_literal: true

require_relative 'ESruleset'

# Inherit EnergyStarRuleset and override methods as needed
class ZeroEnergyReadyHomeRuleset < EnergyStarRuleset
  def self.apply_ruleset(hpxml, calc_type)
    # Use latest version of 301-2019
    @eri_version = Constants.ERIVersions[-1]
    hpxml.header.eri_calculation_version = @eri_version

    # Update HPXML object based on ZERH reference design configuration
    if calc_type == ZERHConstants.CalcTypeZERHReference
      hpxml = apply_ruleset_reference(hpxml)
    end

    return hpxml
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
    new_hpxml.header.zerh_calculation_version = orig_hpxml.header.zerh_calculation_version
    new_hpxml.header.building_id = orig_hpxml.header.building_id
    new_hpxml.header.event_type = orig_hpxml.header.event_type
    new_hpxml.header.state_code = orig_hpxml.header.state_code
    new_hpxml.header.zip_code = orig_hpxml.header.zip_code

    @program_version = orig_hpxml.header.zerh_calculation_version

    return new_hpxml
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
      new_hpxml.walls.add(id: 'TargetHomeDesignWall',
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

      if [HPXML::ResidentialTypeSFA, HPXML::ResidentialTypeApartment].include?(@bldg_type) # FIXME: Could be a way not to override this method because of this IF statement
        insulation_assembly_r_value = [orig_wall.insulation_assembly_r_value, 4.0].min # uninsulated
        if orig_wall.is_thermal_boundary && ([HPXML::LocationOutside, HPXML::LocationGarage].include? orig_wall.exterior_adjacent_to)
          insulation_assembly_r_value = (1.0 / ufactor).round(3)
        end
      elsif [HPXML::ResidentialTypeSFD].include?(@bldg_type)
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

  def self.set_enclosure_ceilings_reference(orig_hpxml, new_hpxml)
    ceiling_ufactor = get_reference_ceiling_ufactor()

    # Exhibit 2 - Ceilings
    orig_hpxml.floors.each do |orig_floor|
      next unless orig_floor.is_ceiling

      if [ZERHConstants.Ver1].include? @program_version
        if [HPXML::ResidentialTypeSFA, HPXML::ResidentialTypeApartment].include?(@bldg_type) # FIXME: Could be a way not to override this method because of this IF statement
          # Retain boundary condition of ceilings in the Rated Unit, including adiabatic ceilings.
          ceiling_exterior_adjacent_to = orig_floor.exterior_adjacent_to.gsub('unvented', 'vented')
          if @has_auto_generated_attic && ([HPXML::LocationOtherHousingUnit, HPXML::LocationOtherMultifamilyBufferSpace, HPXML::LocationOtherNonFreezingSpace, HPXML::LocationOtherHeatedSpace].include? orig_floor.exterior_adjacent_to)
            ceiling_exterior_adjacent_to = HPXML::LocationAtticVented
          end
  
          insulation_assembly_r_value = [orig_floor.insulation_assembly_r_value, 2.1].min # uninsulated
          if orig_floor.is_thermal_boundary && ([HPXML::LocationOutside, HPXML::LocationAtticUnvented, HPXML::LocationAtticVented, HPXML::LocationGarage, HPXML::LocationCrawlspaceUnvented, HPXML::LocationCrawlspaceVented, HPXML::LocationBasementUnconditioned, HPXML::LocationOtherMultifamilyBufferSpace].include? orig_floor.exterior_adjacent_to)
            # Ceilings adjacent to exterior or unconditioned space volumes (e.g., attic, garage, crawlspace, sunrooms, unconditioned basement, multifamily buffer space)
            insulation_assembly_r_value = (1.0 / ceiling_ufactor).round(3)
          end
        elsif [HPXML::ResidentialTypeSFD].include?(@bldg_type)
          ceiling_exterior_adjacent_to = orig_floor.exterior_adjacent_to.gsub('unvented', 'vented')
          if [HPXML::LocationOtherHousingUnit, HPXML::LocationOtherMultifamilyBufferSpace, HPXML::LocationOtherNonFreezingSpace, HPXML::LocationOtherHeatedSpace].include? orig_floor.exterior_adjacent_to
            ceiling_exterior_adjacent_to = HPXML::LocationAtticVented
          end

          # Changes the U-factor for a ceiling to be uninsulated if the ceiling is not a thermal boundary.
          insulation_assembly_r_value = [orig_floor.insulation_assembly_r_value, 2.1].min # uninsulated
          if orig_floor.is_thermal_boundary
            insulation_assembly_r_value = (1.0 / ceiling_ufactor).round(3)
          elsif [HPXML::LocationOtherHousingUnit, HPXML::LocationOtherMultifamilyBufferSpace, HPXML::LocationOtherNonFreezingSpace, HPXML::LocationOtherHeatedSpace].include? orig_floor.exterior_adjacent_to
            insulation_assembly_r_value = (1.0 / ceiling_ufactor).round(3) # Becomes the ceiling adjacent to the vented attic
          end
        end
      end

      new_hpxml.floors.add(id: orig_floor.id,
                                 exterior_adjacent_to: ceiling_exterior_adjacent_to,
                                 interior_adjacent_to: orig_floor.interior_adjacent_to.gsub('unvented', 'vented'),
                                 area: orig_floor.area,
                                 insulation_id: orig_floor.insulation_id,
                                 insulation_assembly_r_value: insulation_assembly_r_value,
                                 other_space_above_or_below: orig_floor.other_space_above_or_below)
    end

    # Add a frame floor between the vented attic and living space
    orig_hpxml.roofs.each do |orig_roof|
      next unless orig_roof.is_exterior_thermal_boundary
      next unless @has_auto_generated_attic

      # Estimate the area of the frame floor based on the roof area and pitch
      pitch_to_radians = Math.atan(orig_roof.pitch / 12.0)
      frame_floor_area = orig_roof.area * Math.cos(pitch_to_radians)

      new_hpxml.floors.add(id: 'TargetHomeDesignFloor',
                           exterior_adjacent_to: HPXML::LocationAtticVented,
                           interior_adjacent_to: HPXML::LocationLivingSpace,
                           area: frame_floor_area,
                           insulation_id: 'TargetHomeDesignFloorInsulation',
                           insulation_assembly_r_value: (1.0 / ceiling_ufactor).round(3))
    end
  end

  def self.set_enclosure_floors_reference(orig_hpxml, new_hpxml)
    floor_ufactor = get_enclosure_floors_over_uncond_spc_default_ufactor()

    # Exhibit 2 - Floors over unconditioned spaces
    orig_hpxml.floors.each do |orig_floor|
      next unless orig_floor.is_floor

      if [HPXML::ResidentialTypeSFA, HPXML::ResidentialTypeApartment].include?(@bldg_type)
        insulation_assembly_r_value = [orig_floor.insulation_assembly_r_value, 3.1].min # uninsulated
        if orig_floor.is_thermal_boundary && ([HPXML::LocationOutside, HPXML::LocationOtherNonFreezingSpace, HPXML::LocationAtticUnvented, HPXML::LocationAtticVented, HPXML::LocationGarage, HPXML::LocationCrawlspaceUnvented, HPXML::LocationCrawlspaceVented, HPXML::LocationBasementUnconditioned, HPXML::LocationOtherMultifamilyBufferSpace].include? orig_floor.exterior_adjacent_to)
          # Ceilings adjacent to outdoor environment, non-freezing space, unconditioned space volumes (e.g., attic, garage, crawlspace, sunrooms, unconditioned basement, multifamily buffer space)
          insulation_assembly_r_value = (1.0 / floor_ufactor).round(3)
        end
      elsif [HPXML::ResidentialTypeSFD].include?(@bldg_type)
        # Uninsulated for, e.g., floors between living space and conditioned basement.
        insulation_assembly_r_value = [orig_floor.insulation_assembly_r_value, 3.1].min # uninsulated
        # Insulated for, e.g., floors between living space and crawlspace/unconditioned basement.
        if orig_floor.is_thermal_boundary
          insulation_assembly_r_value = (1.0 / floor_ufactor).round(3)
        end
      end

      new_hpxml.floors.add(id: orig_floor.id,
                           exterior_adjacent_to: orig_floor.exterior_adjacent_to.gsub('unvented', 'vented'),
                           interior_adjacent_to: orig_floor.interior_adjacent_to.gsub('unvented', 'vented'),
                           area: orig_floor.area,
                           insulation_id: orig_floor.insulation_id,
                           insulation_assembly_r_value: insulation_assembly_r_value,
                           other_space_above_or_below: orig_floor.other_space_above_or_below)
    end
  end

  def self.set_systems_mechanical_ventilation_reference(new_hpxml)
    # Exhibit 2 - Whole-House Mechanical ventilation
    # mechanical vent fan cfm
    q_tot = 0.01 * @cfa + 7.5 * (@nbeds + 1)

    # mechanical vent fan type
    fan_type = get_systems_mechanical_ventilation_default_fan_type()
    # mechanical vent fan cfm per Watts
    fan_cfm_per_w = get_fan_cfm_per_w()
    # mechanicla vent fan heat recovery
    fan_sre = get_mechanical_ventilation_fan_sre()

    # mechanical vent fan Watts
    fan_power_w = q_tot / fan_cfm_per_w

    new_hpxml.ventilation_fans.add(id: 'TargetHomeDesignVentilationFan',
                                   is_shared_system: false,
                                   fan_type: fan_type,
                                   tested_flow_rate: q_tot.round(2),
                                   hours_in_operation: 24,
                                   fan_power: fan_power_w.round(3),
                                   sensible_recovery_efficiency: fan_sre,
                                   used_for_whole_building_ventilation: true)
  end

  def self.set_lighting_reference(new_hpxml)
    if [ZERHConstants.Ver1].include? @program_version
      fFI_int = 0.80
    end
    fFI_ext = 0.0
    fFI_grg = 0.0
    fFII_int = 0.0
    fFII_ext = 0.0
    fFII_grg = 0.0

    new_hpxml.lighting_groups.add(id: 'TargetHomeDesignLightingGroup1',
                                  location: HPXML::LocationInterior,
                                  fraction_of_units_in_location: fFII_int,
                                  lighting_type: HPXML::LightingTypeLED)
    new_hpxml.lighting_groups.add(id: 'TargetHomeDesignLightingGroup2',
                                  location: HPXML::LocationExterior,
                                  fraction_of_units_in_location: fFII_ext,
                                  lighting_type: HPXML::LightingTypeLED)
    new_hpxml.lighting_groups.add(id: 'TargetHomeDesignLightingGroup3',
                                  location: HPXML::LocationGarage,
                                  fraction_of_units_in_location: fFII_grg,
                                  lighting_type: HPXML::LightingTypeLED)
    new_hpxml.lighting_groups.add(id: 'TargetHomeDesignLightingGroup4',
                                  location: HPXML::LocationInterior,
                                  fraction_of_units_in_location: fFI_int,
                                  lighting_type: HPXML::LightingTypeCFL)
    new_hpxml.lighting_groups.add(id: 'TargetHomeDesignLightingGroup5',
                                  location: HPXML::LocationExterior,
                                  fraction_of_units_in_location: fFI_ext,
                                  lighting_type: HPXML::LightingTypeCFL)
    new_hpxml.lighting_groups.add(id: 'TargetHomeDesignLightingGroup6',
                                  location: HPXML::LocationGarage,
                                  fraction_of_units_in_location: fFI_grg,
                                  lighting_type: HPXML::LightingTypeCFL)
    new_hpxml.lighting_groups.add(id: 'TargetHomeDesignLightingGroup7',
                                  location: HPXML::LocationInterior,
                                  fraction_of_units_in_location: 0,
                                  lighting_type: HPXML::LightingTypeLFL)
    new_hpxml.lighting_groups.add(id: 'TargetHomeDesignLightingGroup8',
                                  location: HPXML::LocationExterior,
                                  fraction_of_units_in_location: 0,
                                  lighting_type: HPXML::LightingTypeLFL)
    new_hpxml.lighting_groups.add(id: 'TargetHomeDesignLightingGroup9',
                                  location: HPXML::LocationGarage,
                                  fraction_of_units_in_location: 0,
                                  lighting_type: HPXML::LightingTypeLFL)
  end

  def self.get_radiant_barrier_bool(orig_hpxml)
    return false
  end

  def self.get_enclosure_air_infiltration_default(orig_hpxml)
    if [HPXML::ResidentialTypeSFA, HPXML::ResidentialTypeApartment].include?(@bldg_type)  # FIXME: All attached dwellings
      infil_air_leakage = 3.0  # ACH50
      infil_unit_of_measure = HPXML::UnitsACH

      return infil_air_leakage, infil_unit_of_measure
    elsif [HPXML::ResidentialTypeSFD].include?(@bldg_type)
      if [ZERHConstants.Ver1].include? @program_version
        if ['1A', '1B', '1C', '2A', '2B', '2C'].include? @iecc_zone
          infil_air_leakage = 3.0  # ACH50
        elsif ['3A', '3B', '3C', '4A', '4B'].include? @iecc_zone
          infil_air_leakage = 2.5  # ACH50
        elsif ['4C', '5A', '5B', '5C', '6A', '6B', '6C', '7'].include? @iecc_zone
          infil_air_leakage = 2.0  # ACH50
        elsif ['8'].include? @iecc_zone
          infil_air_leakage = 1.5  # ACH50
        end
      end
      infil_unit_of_measure = HPXML::UnitsACH

      return infil_air_leakage, infil_unit_of_measure
    end

    fail 'Unexpected case.'
  end

  def self.get_systems_mechanical_ventilation_default_fan_type()
    if [ZERHConstants.Ver1].include? @program_version
      if ['1A', '1B', '1C', '2A', '2B', '2C', '3A', '3B', '3C', '4A', '4B'].include? @iecc_zone
        return HPXML::MechVentTypeSupply
      elsif ['4C', '5A', '5B', '5C', '6A', '6B', '6C', '7', '8'].include? @iecc_zone
        return HPXML::MechVentTypeBalanced
      end
    end

    fail 'Unexpected case.'
  end

  def self.get_mechanical_ventilation_fan_sre()
    if [ZERHConstants.Ver1].include? @program_version
      if ['1A', '1B', '1C', '2A', '2B', '2C', '3A', '3B', '3C', '4A', '4B'].include? @iecc_zone
        return nil
      elsif ['4C', '5A', '5B', '5C', '6A', '6B', '6C', '7', '8'].include? @iecc_zone
        return 0.6
      end
    end

    fail 'Unexpected case.'
  end

  def self.get_default_door_ufactor_shgc()
    if [ZERHConstants.Ver1].include? @program_version  # The same as ESConstants.SFNationalVer3_0
      return 0.21, nil
    end

    fail 'Unexpected case.'
  end

  def self.get_foundation_walls_default_ufactor_or_rvalue()
    if [ZERHConstants.Ver1].include? @program_version
      if ['1A', '1B', '1C', '2A', '2B', '2C'].include? @iecc_zone
        return 0.360  # assembly U-value
      elsif ['3A', '3B', '3C'].include? @iecc_zone
        return 0.091  # assembly U-value
      elsif ['4A', '4B'].include? @iecc_zone
        return 0.059  # assembly U-value
      elsif ['4C', '5A', '5B', '5C', '6A', '6B', '6C', '7', '8'].include? @iecc_zone
        return 0.050  # assembly U-value
      end
    end

    fail 'Unexpected case.'
  end

  def self.get_enclosure_walls_default_ufactor()
    if [ZERHConstants.Ver1].include? @program_version
      if ['1A', '1B', '1C', '2A', '2B', '2C'].include? @iecc_zone
        return 0.084
      elsif ['3A', '3B', '3C', '4A', '4B', '4C', '5A', '5B', '5C'].include? @iecc_zone
        return 0.060
      elsif ['6A', '6B', '6C', '7', '8'].include? @iecc_zone
        return 0.045
      end
    end

    fail 'Unexpected case.'
  end

  def self.get_enclosure_floors_over_uncond_spc_default_ufactor()
    if [ZERHConstants.Ver1].include? @program_version  # The same as ESConstants.SFNationalVer3_0
      if ['1A', '1B', '1C', '2A', '2B', '2C'].include? @iecc_zone
        return 0.064
      elsif ['3A', '3B', '3C', '4A', '4B'].include? @iecc_zone
        return 0.047
      elsif ['4C', '5A', '5B', '5C', '6A', '6B', '6C'].include? @iecc_zone
        return 0.033
      elsif ['7', '8'].include? @iecc_zone
        return 0.028
      end
    end

    fail 'Unexpected case.'
  end

  def self.get_water_heater_properties(orig_water_heater)
    orig_wh_fuel_type = orig_water_heater.fuel_type.nil? ? orig_water_heater.related_hvac_system.heating_system_fuel : orig_water_heater.fuel_type

    if [ZERHConstants.Ver1].include? @program_version
      if [HPXML::WaterHeaterTypeTankless, HPXML::WaterHeaterTypeCombiTankless].include? orig_water_heater.water_heater_type
        if orig_wh_fuel_type == HPXML::FuelTypeElectricity
          wh_tank_vol = 60.0 # gallon
        else
          wh_tank_vol = 40.0 # gallon
        end
      else
        wh_tank_vol = orig_water_heater.tank_volume
      end

      if [HPXML::FuelTypeNaturalGas, HPXML::FuelTypePropane, HPXML::FuelTypeWoodCord, HPXML::FuelTypeWoodPellets].include? orig_wh_fuel_type
        wh_type = HPXML::WaterHeaterTypeStorage
        wh_fuel_type = HPXML::FuelTypeNaturalGas
        if wh_tank_vol <= 55
          ef = 0.67
        else
          ef = 0.77
        end
        re = 0.80
      elsif [HPXML::FuelTypeElectricity].include? orig_wh_fuel_type
        wh_type = HPXML::WaterHeaterTypeHeatPump
        wh_fuel_type = HPXML::FuelTypeElectricity
        if @bldg_type == HPXML::ResidentialTypeSFD
          ef = 2.0
        elsif [HPXML::ResidentialTypeSFA, HPXML::ResidentialTypeApartment].include? @bldg_type
          ef = 1.5
        end
        re = 0.98
      elsif [HPXML::FuelTypeOil].include? orig_wh_fuel_type
        wh_type = HPXML::WaterHeaterTypeStorage
        wh_fuel_type = HPXML::FuelTypeOil
        ef = 0.60
        re = 0.80
      end

      return wh_type, wh_fuel_type, wh_tank_vol, ef.round(2), re
    end

    fail 'Unexpected case.'
  end

  def self.get_default_boiler_eff(orig_system)
    if [ZERHConstants.Ver1].include? @program_version
      if [HPXML::FuelTypeNaturalGas, HPXML::FuelTypePropane, HPXML::FuelTypeOil, HPXML::FuelTypeWoodCord, HPXML::FuelTypeWoodPellets].include? fuel_type
        if ['1A', '1B', '1C', '2A', '2B', '2C'].include? @iecc_zone
          return 0.80 # AFUE
        elsif ['3A', '3B', '3C', '4A', '4B'].include? @iecc_zone
          return 0.90 # AFUE
        elsif ['4C', '5A', '5B', '5C', '6A', '6B', '6C', '7', '8'].include? @iecc_zoneo
          return 0.94 # AFUE
        end
      elsif fuel_type == HPXML::FuelTypeElectricity
        return 0.98 # AFUE
      end
    end

    fail 'Unexpected case.'
  end

  def self.get_default_furnace_afue(fuel_type)
    if [ZERHConstants.Ver1].include? @program_version
      if [HPXML::FuelTypeNaturalGas, HPXML::FuelTypePropane, HPXML::FuelTypeWoodCord, HPXML::FuelTypeWoodPellets, HPXML::FuelTypeOil].include? fuel_type
        if ['1A', '1B', '1C', '2A', '2B', '2C'].include? @iecc_zone
          return 0.80
        elsif ['3A', '3B', '3C', '4A', '4B'].include? @iecc_zone
          return 0.90
        elsif ['4C', '5A', '5B', '5C', '6A', '6B', '6C', '7', '8'].include? @iecc_zone
          return 0.94
        end
      end
    end

    fail 'Unexpected case.'
  end

  def self.get_default_ashp_hspf()
    if [ZERHConstants.Ver1].include? @program_version
      if ['1A', '1B', '1C', '2A', '2B', '2C'].include? @iecc_zone
        return 8.2
      elsif ['3A', '3B', '3C', '4A', '4B'].include? @iecc_zone
        return 9.0
      elsif ['4C', '5A', '5B', '5C', '6A', '6B', '6C', '7', '8'].include? @iecc_zone
        return 10.0
      end
    end

    fail 'Unexpected case.'
  end

  def self.get_default_gshp_cop()
    if [ZERHConstants.Ver1].include? @program_version
      if ['7', '8'].include? @iecc_zone
        return 3.6
      else
        return # nop
      end
    end

    fail 'Unexpected case.'
  end

  def self.get_default_ac_seer()
    if [ZERHConstants.Ver1].include? @program_version
      if ['1A', '1B', '1C', '2A', '2B', '2C'].include? @iecc_zone
        return 18.0
      elsif ['3A', '3B', '3C', '4A', '4B'].include? @iecc_zone
        return 15.0
      elsif ['4C', '5A', '5B', '5C', '6A', '6B', '6C', '7', '8'].include? @iecc_zone
        return 13.0
      end
    end

    fail 'Unexpected case.'
  end

  def self.get_default_ashp_seer()
    if [ZERHConstants.Ver1].include? @program_version
      if ['1A', '1B', '1C', '2A', '2B', '2C'].include? @iecc_zone
        return 18.0
      elsif ['3A', '3B', '3C', '4A', '4B'].include? @iecc_zone
        return 15.0
      elsif ['4C', '5A', '5B', '5C', '6A', '6B', '6C'].include? @iecc_zone
        return 13.0
      elsif ['7', '8'].include? @iecc_zone
        return # nop
      end
    end

    fail 'Unexpected case.'
  end

  def self.get_default_gshp_eer()
    if [ZERHConstants.Ver1].include? @program_version
      if ['7', '8'].include? @iecc_zone
        return 17.1
      else
        return # nop
      end
    end

    fail 'Unexpected case.'
  end

  def self.get_fan_cfm_per_w()
    if [ZERHConstants.Ver1].include? @program_version
      if ['1A', '1B', '1C', '2A', '2B', '2C', '3A', '3B', '3C', '4A', '4B'].include? @iecc_zone
        return 2.8
      elsif ['4C', '5A', '5B', '5C', '6A', '6B', '6C'].include? @iecc_zone
        return 1.2
      end
    end

    fail 'Unexpected case.'
  end

  def self.get_duct_location_and_surface_area(orig_hpxml, total_duct_area)
    # EPA confirmed that duct percentages apply to ASHRAE 152 *total* duct area
    duct_location_and_surface_area = {}
    if [ZERHConstants.Ver1].include? @program_version
      duct_location_and_surface_area[HPXML::LocationLivingSpace] = total_duct_area # Duct location configured to be 100% in conditioned space.
    end

    if duct_location_and_surface_area.empty?
      fail 'Unexpected case.'
    end

    return duct_location_and_surface_area
  end

  def self.get_duct_insulation_r_value(duct_type, duct_location)
    if [ZERHConstants.Ver1].include? @program_version
      return 0.0 # All ducts located in conditioned space
    end
  end

  def self.calc_default_duct_leakage_to_outside(cfa)
    if [ZERHConstants.Ver1].include? @program_version  # FIXME: As 100% of ducts is within the thermal and air barriers of the home, shouldn't it be 0? Ask Jamie and Scott
      return 0.0
    end

    fail 'Unexpected case.'
  end

  def self.get_reference_ceiling_ufactor()
    # Ceiling U-Factor
    if [ZERHConstants.Ver1].include? @program_version
      if ['1A', '1B', '1C'].include? @iecc_zone
        return 0.035
      elsif ['2A', '2B', '2C', '3A', '3B', '3C'].include? @iecc_zone
        return 0.030
      elsif ['4A', '4B', '4C', '5A', '5B', '5C', '6A', '6B', '6C', '7', '8'].include? @iecc_zone
        return 0.026
      end
    end

    fail 'Unexpected case.'
  end

  def self.get_reference_slab_perimeter_rvalue_depth()
    if [ZERHConstants.Ver1].include? @program_version
      # Slab-on-Grade R-Value & Depth (ft)
      if ['1A', '1B', '1C', '2A', '2B', '2C', '3A', '3B', '3C'].include? @iecc_zone
        return 0.0, 0.0
      elsif ['4A', '4B', '4C', '5A', '5B', '5C'].include? @iecc_zone
        return 10.0, 2.0
      elsif ['6A', '6B', '6C', '7', '8'].include? @iecc_zone
        return 10.0, 4.0
      end
    end

    fail 'Unexpected case.'
  end

  def self.get_reference_slab_under_rvalue_width()
    return 0.0, 0.0
  end

  def self.get_reference_glazing_ufactor_shgc(orig_window)
    # Fenestration U-Factor and SHGC
    if [ZERHConstants.Ver1].include? @program_version
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

    fail 'Unexpected case.'
  end
end
