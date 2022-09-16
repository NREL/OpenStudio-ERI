# frozen_string_literal: true

require 'fileutils'

def _change_eri_version(hpxml_name, version)
  # Create derivative file w/ changed ERI version
  hpxml = HPXML.new(hpxml_path: File.join(@root_path, 'workflow', 'sample_files', hpxml_name))
  hpxml.header.eri_calculation_version = version

  if Constants.ERIVersions.index(version) < Constants.ERIVersions.index('2019A')
    # Need old input for clothes dryers
    hpxml.clothes_dryers[0].control_type = HPXML::ClothesDryerControlTypeTimer
  end

  hpxml_name = File.basename(@tmp_hpxml_path)
  XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
  return hpxml_name
end

def _change_iecc_version(hpxml_name, version)
  # Create derivative file w/ changed ERI version
  hpxml = HPXML.new(hpxml_path: File.join(@root_path, 'workflow', 'sample_files', hpxml_name))
  hpxml.header.iecc_eri_calculation_version = version
  if hpxml.climate_and_risk_zones.climate_zone_ieccs.select { |z| z.year == Integer(version) }.size == 0
    hpxml.climate_and_risk_zones.climate_zone_ieccs.add(year: Integer(version),
                                                        zone: hpxml.climate_and_risk_zones.climate_zone_ieccs[0].zone)
  end

  hpxml_name = File.basename(@tmp_hpxml_path)
  XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
  return hpxml_name
end

def _all_calc_types()
  return [Constants.CalcTypeERIReferenceHome,
          Constants.CalcTypeERIRatedHome,
          Constants.CalcTypeERIIndexAdjustmentDesign,
          Constants.CalcTypeERIIndexAdjustmentReferenceHome,
          Constants.CalcTypeCO2eReferenceHome]
end

# Create derivative file for ENERGY STAR testing
def convert_to_es(hpxml_name, program_version, root_path, tmp_hpxml_path, state_code = nil)
  hpxml = HPXML.new(hpxml_path: File.join(root_path, 'workflow', 'sample_files', hpxml_name))

  # Change weather station for regional ENERGY STAR
  if [ESConstants.SFPacificVer3_0].include? program_version
    if ['HI'].include?(state_code) || state_code.nil? # if state_code isn't provided, default to HI
      hpxml.climate_and_risk_zones.climate_zone_ieccs[0].zone = '1A'
      hpxml.climate_and_risk_zones.weather_station_id = 'WeatherStation'
      hpxml.climate_and_risk_zones.weather_station_name = 'Honolulu, HI'
      hpxml.climate_and_risk_zones.weather_station_wmo = 911820
      hpxml.header.state_code = 'HI'
    elsif ['GU', 'MP'].include? state_code # For Northern Mariana Islands, use Guam weather
      hpxml.climate_and_risk_zones.climate_zone_ieccs[0].zone = '1A'
      hpxml.climate_and_risk_zones.weather_station_id = 'WeatherStation'
      hpxml.climate_and_risk_zones.weather_station_name = 'Andersen_Afb, GU'
      hpxml.climate_and_risk_zones.weather_station_wmo = 912180
      hpxml.header.state_code = 'GU'
    end
  elsif [ESConstants.SFFloridaVer3_1].include? program_version
    hpxml.climate_and_risk_zones.climate_zone_ieccs[0].zone = '1A'
    hpxml.climate_and_risk_zones.weather_station_id = 'WeatherStation'
    hpxml.climate_and_risk_zones.weather_station_name = 'Miami, FL'
    hpxml.climate_and_risk_zones.weather_station_wmo = 722020
    hpxml.header.state_code = 'FL'
  elsif [ESConstants.SFOregonWashingtonVer3_2, ESConstants.MFOregonWashingtonVer1_2].include? program_version
    hpxml.climate_and_risk_zones.climate_zone_ieccs[0].zone = '4C'
    hpxml.climate_and_risk_zones.weather_station_id = 'WeatherStation'
    hpxml.climate_and_risk_zones.weather_station_name = 'Portland, OR'
    hpxml.climate_and_risk_zones.weather_station_wmo = 726980
    hpxml.header.state_code = 'OR'
  end

  # Change program version to ENERGY STAR
  hpxml.header.energystar_calculation_version = program_version

  if ESConstants.SFVersions.include? program_version
    hpxml.building_construction.residential_facility_type = HPXML::ResidentialTypeSFA
  else
    hpxml.building_construction.residential_facility_type = HPXML::ResidentialTypeApartment
  end

  # Save new file
  XMLHelper.write_file(hpxml.to_oga, tmp_hpxml_path)
end
