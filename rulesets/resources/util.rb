# frozen_string_literal: true

def get_hvac_configurations(orig_bldg)
  hvac_configurations = []
  orig_bldg.heating_systems.each do |orig_heating_system|
    hvac_configurations << { heating_system: orig_heating_system, cooling_system: orig_heating_system.attached_cooling_system }
  end
  orig_bldg.cooling_systems.each do |orig_cooling_system|
    # Exclude cooling systems already added to hvac_configurations
    next if hvac_configurations.any? { |config| config[:cooling_system].id == orig_cooling_system.id if not config[:cooling_system].nil? }

    if orig_cooling_system.has_integrated_heating # Cooling system w/ integrated heating (e.g., Room AC w/ electric resistance heating)
      hvac_configurations << { cooling_system: orig_cooling_system, heating_system: orig_cooling_system }
    else
      hvac_configurations << { cooling_system: orig_cooling_system, heating_system: orig_cooling_system.attached_heating_system }
    end
  end
  orig_bldg.heat_pumps.each do |orig_heat_pump|
    # Exclude heat pumps already added to hvac_configurations
    next if hvac_configurations.any? { |config| config[:cooling_system].id == orig_heat_pump.id if not config[:cooling_system].nil? }
    next if hvac_configurations.any? { |config| config[:heating_system].id == orig_heat_pump.id if not config[:heating_system].nil? }

    hvac_configurations << { heat_pump: orig_heat_pump }
  end

  return hvac_configurations
end

def get_climate_zone_of_year(hpxml_bldg, iecc_year)
  # Returns the climate zone and year given a target year; if not found uses
  # an earlier year with the assumption that the climate zone has not changed.
  year = iecc_year
  while year >= 2003
    climate_zone_iecc = hpxml_bldg.climate_and_risk_zones.climate_zone_ieccs.find { |z| z.year == year }
    if not climate_zone_iecc.nil?
      return climate_zone_iecc.zone, climate_zone_iecc.year
    end

    year -= 3
  end
end
