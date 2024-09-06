def get_climate_zone_of_year(hpxml_bldg, iecc_year)
  # Returns the climate zone of the given year; if not found
  # uses an earlier year with the assumption that the climate zone
  # has not changed.
  year = iecc_year
  while year >= 2003
    climate_zone_iecc = hpxml_bldg.climate_and_risk_zones.climate_zone_ieccs.find { |z| z.year == year }
    if not climate_zone_iecc.nil?
      return climate_zone_iecc
    end
    year -= 3
  end
  return nil
end