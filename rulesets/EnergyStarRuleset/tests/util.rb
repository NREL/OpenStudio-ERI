# frozen_string_literal: true

require 'fileutils'

# Create derivative file for ENERGY STAR testing
def convert_to_es(hpxml_name, program_version, root_path, tmp_hpxml_path, state_code = nil)
  hpxml = HPXML.new(hpxml_path: File.join(root_path, 'workflow', 'sample_files', hpxml_name))

  # Change weather station for regional ENERGY STAR
  if [ESConstants.SFPacificVer3].include? program_version
    if ['HI'].include?(state_code) || state_code.nil? # if state_code isn't provided, default to HI
      hpxml.climate_and_risk_zones.iecc_zone = '1A'
      hpxml.climate_and_risk_zones.weather_station_id = 'WeatherStation'
      hpxml.climate_and_risk_zones.weather_station_name = 'Honolulu, HI'
      hpxml.climate_and_risk_zones.weather_station_wmo = 911820
      hpxml.header.state_code = 'HI'
    elsif ['GU', 'MP'].include? state_code # For Northern Mariana Islands, use Guam weather
      hpxml.climate_and_risk_zones.iecc_zone = '1A'
      hpxml.climate_and_risk_zones.weather_station_id = 'WeatherStation'
      hpxml.climate_and_risk_zones.weather_station_name = 'Andersen_Afb, GU'
      hpxml.climate_and_risk_zones.weather_station_wmo = 912180
      hpxml.header.state_code = 'GU'
    end
  elsif [ESConstants.SFFloridaVer3_1].include? program_version
    hpxml.climate_and_risk_zones.iecc_zone = '1A'
    hpxml.climate_and_risk_zones.weather_station_id = 'WeatherStation'
    hpxml.climate_and_risk_zones.weather_station_name = 'Miami, FL'
    hpxml.climate_and_risk_zones.weather_station_wmo = 722020
    hpxml.header.state_code = 'FL'
  elsif [ESConstants.SFOregonWashingtonVer3_2, ESConstants.MFOregonWashingtonVer1_2_2019].include? program_version
    hpxml.climate_and_risk_zones.iecc_zone = '4C'
    hpxml.climate_and_risk_zones.weather_station_id = 'WeatherStation'
    hpxml.climate_and_risk_zones.weather_station_name = 'Portland, OR'
    hpxml.climate_and_risk_zones.weather_station_wmo = 726980
    hpxml.header.state_code = 'OR'
  end

  # Change program version to ENERGY STAR
  hpxml.header.energystar_calculation_version = program_version

  # Use SFA for all tests, since it runs with both SF and MF versions of ENERGY STAR
  hpxml.building_construction.residential_facility_type = HPXML::ResidentialTypeSFA

  # Save new file
  XMLHelper.write_file(hpxml.to_oga, tmp_hpxml_path)
end
