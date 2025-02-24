# frozen_string_literal: true

require 'fileutils'

def _change_eri_version(hpxml_name, version)
  # Create derivative file w/ changed ERI version
  hpxml = HPXML.new(hpxml_path: File.join(@root_path, 'workflow', 'sample_files', hpxml_name))
  hpxml_bldg = hpxml.buildings[0]
  hpxml.header.eri_calculation_version = version
  if Constants::ERIVersions.index(version) >= Constants::ERIVersions.index('2019ABCD')
    hpxml.header.co2index_calculation_version = version
  else
    hpxml.header.co2index_calculation_version = nil # CO2 Index can't be calculated
  end

  if Constants::ERIVersions.index(version) < Constants::ERIVersions.index('2019A')
    # Need old input for clothes dryers
    hpxml_bldg.clothes_dryers[0].control_type = HPXML::ClothesDryerControlTypeTimer
  end

  hpxml_name = File.basename(@tmp_hpxml_path)
  XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
  return hpxml_name
end

def _change_iecc_version(hpxml_name, version)
  # Create derivative file w/ changed ERI version
  hpxml = HPXML.new(hpxml_path: File.join(@root_path, 'workflow', 'sample_files', hpxml_name))
  hpxml.header.iecc_eri_calculation_version = version

  hpxml_name = File.basename(@tmp_hpxml_path)
  XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
  return hpxml_name
end

def _all_calc_types()
  return [Constants::CalcTypeERIReferenceHome,
          Constants::CalcTypeERIRatedHome,
          Constants::CalcTypeERIIndexAdjustmentDesign,
          Constants::CalcTypeERIIndexAdjustmentReferenceHome,
          Constants::CalcTypeCO2eReferenceHome]
end

# Create derivative file for ENERGY STAR and Zero Energy Ready Home program testing
def convert_to_es_zerh(hpxml_name, program_version, root_path, tmp_hpxml_path, state_code = nil)
  hpxml = HPXML.new(hpxml_path: File.join(root_path, 'workflow', 'sample_files', hpxml_name))
  hpxml_bldg = hpxml.buildings[0]

  # Change weather station for regional ENERGY STAR
  if [ESConstants::SFPacificVer3_0].include? program_version
    if ['HI'].include?(state_code) || state_code.nil? # if state_code isn't provided, default to HI
      hpxml_bldg.climate_and_risk_zones.climate_zone_ieccs[0].zone = '1A'
      hpxml_bldg.climate_and_risk_zones.weather_station_id = 'WeatherStation'
      hpxml_bldg.climate_and_risk_zones.weather_station_name = 'Honolulu, HI'
      hpxml_bldg.climate_and_risk_zones.weather_station_wmo = 911820
      hpxml_bldg.state_code = 'HI'
    elsif ['GU', 'MP'].include? state_code # For Northern Mariana Islands, use Guam weather
      hpxml_bldg.climate_and_risk_zones.climate_zone_ieccs[0].zone = '1A'
      hpxml_bldg.climate_and_risk_zones.weather_station_id = 'WeatherStation'
      hpxml_bldg.climate_and_risk_zones.weather_station_name = 'Andersen_Afb, GU'
      hpxml_bldg.climate_and_risk_zones.weather_station_wmo = 912180
      hpxml_bldg.state_code = 'GU'
    end
  elsif [ESConstants::SFFloridaVer3_1].include? program_version
    hpxml_bldg.climate_and_risk_zones.climate_zone_ieccs[0].zone = '1A'
    hpxml_bldg.climate_and_risk_zones.weather_station_id = 'WeatherStation'
    hpxml_bldg.climate_and_risk_zones.weather_station_name = 'Miami, FL'
    hpxml_bldg.climate_and_risk_zones.weather_station_wmo = 722020
    hpxml_bldg.state_code = 'FL'
  elsif [ESConstants::SFOregonWashingtonVer3_2, ESConstants::MFOregonWashingtonVer1_2].include? program_version
    hpxml_bldg.climate_and_risk_zones.climate_zone_ieccs[0].zone = '4C'
    hpxml_bldg.climate_and_risk_zones.weather_station_id = 'WeatherStation'
    hpxml_bldg.climate_and_risk_zones.weather_station_name = 'Portland, OR'
    hpxml_bldg.climate_and_risk_zones.weather_station_wmo = 726980
    hpxml_bldg.state_code = 'OR'
  end

  # Change program version to ENERGY STAR or Zero Energy Ready Home
  hpxml.header.energystar_calculation_version = nil
  hpxml.header.zerh_calculation_version = nil
  if ESConstants::AllVersions.include? program_version
    hpxml.header.energystar_calculation_version = program_version
  elsif ZERHConstants::AllVersions.include? program_version
    hpxml.header.zerh_calculation_version = program_version
  end
  if [*ESConstants::SFVersions, *ZERHConstants::SFVersions].include? program_version
    if hpxml_bldg.building_construction.residential_facility_type == HPXML::ResidentialTypeApartment
      hpxml_bldg.building_construction.residential_facility_type = HPXML::ResidentialTypeSFA
    end
  else
    if hpxml_bldg.building_construction.residential_facility_type == HPXML::ResidentialTypeSFD
      hpxml_bldg.building_construction.residential_facility_type = HPXML::ResidentialTypeApartment
    end
  end
  if [HPXML::ResidentialTypeSFA,
      HPXML::ResidentialTypeApartment].include? hpxml_bldg.building_construction.residential_facility_type
    # Need to have at least one attached surface
    hpxml_bldg.walls.add(id: 'TinyAttachedWall',
                         wall_type: HPXML::WallTypeWoodStud,
                         area: 0.0001,
                         solar_absorptance: 0.7,
                         emittance: 0.92,
                         interior_adjacent_to: HPXML::LocationConditionedSpace,
                         exterior_adjacent_to: HPXML::LocationOtherHousingUnit,
                         insulation_assembly_r_value: 99)
  end

  # Save new file
  XMLHelper.write_file(hpxml.to_doc, tmp_hpxml_path)
end
