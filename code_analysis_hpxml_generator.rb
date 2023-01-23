# frozen_string_literal: true

# 2021-09-05 updates: - updated DHW length - Updated lighting to es to be LED - updated DHW location
$VERBOSE = nil # Prevents ruby warnings, see https://github.com/NREL/OpenStudio/issues/4301

def create_test_hpxmls
  this_dir = File.dirname(__FILE__)
  tests_dir = File.join(this_dir, 'workflow/tests')

  programs = [
    'EnergyStar',
    'EnergyStarNextGen',
    '2021IECC'
  ]
  locations = [
    'CZ1_HI_Honolulu',
    'CZ1_FL_Miami',
    'CZ2_LA_Baton',
    'CZ2_TX_Houston-Bush',
    'CZ2_AL_Mobile-Rgnl',
    'CZ2_AZ_Phoenix-Sky',
    'CZ2_TX_San',
    'CZ2_GA_Savannah',
    'CZ2_FL_Tampa',
    'CZ2_CA_Tucson',
    'CZ3_AL_Montgomery-Dannelly',
    'CZ3_AL_Birmingham',
    'CZ3_GA_Atlanta-Hartsfield-Jackson',
    'CZ3_SC_Charleston',
    'CZ3_NC_Charlotte-Douglas',
    'CZ3_SC_Columbia',
    'CZ3_TX_Dallas-Fort',
    'CZ3_TX_El',
    'CZ3_MS_Jackson',
    'CZ3_AZ_Kingman',
    'CZ3_NV_Las',
    'CZ3_AR_Little',
    'CZ3_CA_Los',
    'CZ3_NM_Lubbock',
    'CZ3_GA_Macon-Middle',
    'CZ3_TN_Memphis',
    'CZ3_LA_Monroe',
    'CZ3_OK_Oklahoma',
    'CZ3_UT_Saint',
    'CZ3_CA_San',
    'CZ3_LA_Shreveport',
    'CZ3_AR_Shreveport',
    'CZ3_MS_Tupelo',
    'CZ3_TX_Wichita',
    'CZ3_NC_Wilmington',
    'CZ4_NM_Albuquerque',
    'CZ4_TX_Amarillo',
    'CZ4_OK_Amarillo',
    'CZ4_MD_Baltimore-Washington',
    'CZ4_DC_Baltimore-Washington',
    'CZ4_WV_Charleston-Yeager',
    'CZ4_GA_Chattanooga-Lovell',
    'CZ4_OH_Cincinnati',
    'CZ4_IN_Evansville',
    'CZ4_KY_Lexington-Bluegrass',
    'CZ4_TN_Nashville',
    'CZ4_NY_New',
    'CZ4_NJ_Newark',
    'CZ4_PA_Philadelphia',
    'CZ4_AZ_Prescott-Love',
    'CZ4_NC_Raleigh-Durham',
    'CZ4_VA_Richmond',
    'CZ4_CA_Sacramento',
    'CZ4_AR_Springfield',
    'CZ4_MO_St',
    'CZ4_IL_St',
    'CZ4_KS_Topeka-Phillip',
    'CZ4_CO_Trinidad-Las',
    'CZ4_DE_Wilmington-New',
    'CZ4C_CA_Arcata',
    'CZ4C_OR_Portland',
    'CZ4C_WA_Seattle-Tacoma',
    'CZ5_NJ_Allentown-Lehigh',
    'CZ5_ID_Boise',
    'CZ5_MA_Boston-Logan',
    'CZ5_CO_Colorado',
    'CZ5_OH_Columbus-Port',
    'CZ5_IA_Des',
    'CZ5_WV_Elkins-Randolph',
    'CZ5_NC_Elkins-Randolph',
    'CZ5_AZ_Flagstaff-Pulliam',
    'CZ5_NM_Flagstaff-Pulliam',
    'CZ5_KS_Goodland-Renner',
    'CZ5_PA_Harrisburg',
    'CZ5_CT_Hartford-Bradley',
    'CZ5_IN_Indianapolis',
    'CZ5_MO_Kirksville',
    'CZ5_MI_Lansing-Capital',
    'CZ5_NH_Manchester',
    'CZ5_NE_Omaha',
    'CZ5_IL_Peoria-Greater',
    'CZ5_RI_Providence-T',
    'CZ5_OR_Redmond-Roberts',
    'CZ5_NV_Reno-Tahoe',
    'CZ5_CA_Reno-Tahoe',
    'CZ5_UT_Salt',
    'CZ5_WY_Scottsbluff-W',
    'CZ5_SD_Sioux',
    'CZ5_WA_Spokane',
    'CZ5_NY_Albany',
    'CZ6_MI_Alpena',
    'CZ6_NY_Binghamton-Edwin',
    'CZ6_ND_Bismarck',
    'CZ6_PA_Bradford',
    'CZ6_VT_Burlington',
    'CZ6_WY_Cheyenne',
    'CZ6_NH_Concord',
    'CZ6_CO_Eagle',
    'CZ6_CA_Eagle',
    'CZ6_MT_Helena',
    'CZ6_WA_Kalispell-Glacier',
    'CZ6_WI_Madison-Dane',
    'CZ6_IA_Mason',
    'CZ6_MN_Minneapolis-St',
    'CZ6_SD_Pierre',
    'CZ6_ID_Pocatello',
    'CZ6_ME_Portland',
    'CZ6_UT_Vernal',
    'CZ7_AK_Anchorage',
    'CZ7_ME_Caribou',
    'CZ7_MN_Duluth',
    'CZ7_WI_Duluth',
    'CZ7_CO_Gunnison',
    'CZ7_WY_Jackson',
    'CZ7_ND_Minot',
    'CZ7_MI_Sault',
    'CZ8_AK_Fairbanks'
  ]
  home_types = [
    'gas_cond_bsmt',
    'elec_cond_bsmt',
    'gas_slab',
    'elec_slab',
    'gas_uncond_bsmt',
    'elec_uncond_bsmt',
    'gas_vented_crawl',
    'elec_vented_crawl'
  ]

  hpxml_files = []
  programs.each do |program|
    locations.each do |location|
      home_types.each do |home_type|
        hpxml_file = "Code_Analysis/#{program}/#{location}_#{home_type}.xml"
        if (program == 'EnergyStarNextGen') && (home_type.include? 'elec')
          hpxml_files << hpxml_file
        else
          hpxml_files << hpxml_file
        end
      end
    end
  end

  puts "Generating #{hpxml_files.size} HPXML files..."

  hpxml_files.each do |hpxml_file|
    begin
      print '.'
      hpxml = HPXML.new
      set_hpxml_header(hpxml_file, hpxml)
      set_hpxml_site(hpxml_file, hpxml)
      set_hpxml_building_construction(hpxml_file, hpxml)
      set_hpxml_building_occupancy(hpxml_file, hpxml)
      set_hpxml_climate_and_risk_zones(hpxml_file, hpxml)
      set_hpxml_attics(hpxml_file, hpxml)
      set_hpxml_foundations(hpxml_file, hpxml)
      set_hpxml_roofs(hpxml_file, hpxml)
      set_hpxml_rim_joists(hpxml_file, hpxml)
      set_hpxml_walls(hpxml_file, hpxml)
      set_hpxml_foundation_walls(hpxml_file, hpxml)
      set_hpxml_floors(hpxml_file, hpxml)
      set_hpxml_slabs(hpxml_file, hpxml)
      set_hpxml_windows(hpxml_file, hpxml)
      set_hpxml_doors(hpxml_file, hpxml)
      set_hpxml_air_infiltration_measurements(hpxml_file, hpxml)
      set_hpxml_heating_systems(hpxml_file, hpxml)
      set_hpxml_cooling_systems(hpxml_file, hpxml)
      set_hpxml_heat_pumps(hpxml_file, hpxml)
      set_hpxml_hvac_controls(hpxml_file, hpxml)
      set_hpxml_hvac_distributions(hpxml_file, hpxml)
      set_hpxml_ventilation_fans(hpxml_file, hpxml)
      set_hpxml_water_heating_systems(hpxml_file, hpxml)
      set_hpxml_hot_water_distribution(hpxml_file, hpxml)
      set_hpxml_water_fixtures(hpxml_file, hpxml)
      set_hpxml_clothes_washer(hpxml_file, hpxml)
      set_hpxml_clothes_dryer(hpxml_file, hpxml)
      set_hpxml_dishwasher(hpxml_file, hpxml)
      set_hpxml_refrigerator(hpxml_file, hpxml)
      set_hpxml_cooking_range(hpxml_file, hpxml)
      set_hpxml_oven(hpxml_file, hpxml)
      set_hpxml_lighting(hpxml_file, hpxml)
      set_hpxml_plug_loads(hpxml_file, hpxml)

      hpxml_doc = hpxml.to_oga()

      hpxml_path = File.join(tests_dir, hpxml_file)

      FileUtils.mkdir_p(File.dirname(hpxml_path))
      XMLHelper.write_file(hpxml_doc, hpxml_path)

      # Validate file against HPXML schema
      xsd_path = File.join(File.dirname(__FILE__), 'hpxml-measures', 'HPXMLtoOpenStudio', 'resources', 'hpxml_schema', 'HPXML.xsd')
      errors, _ = XMLValidator.validate_against_schema(hpxml_path, xsd_path)
      if errors.size > 0
        fail errors.to_s
      end

      # Check for additional errors
      errors = hpxml.check_for_errors()
      if errors.size > 0
        fail "ERRORS: #{errors}"
      end
    rescue Exception => e
      puts "\n#{e}\n#{e.backtrace.join('\n')}"
      puts "\nError: Did not successfully generate #{derivative}."
      exit!
    end
  end
end

def set_hpxml_header(hpxml_file, hpxml)
  hpxml.header.xml_type = 'HPXML'
  hpxml.header.xml_generated_by = 'ES_homes_generator.rb'
  hpxml.header.transaction = 'create'
  hpxml.header.building_id = 'MyBuilding'
  hpxml.header.event_type = 'proposed workscope'
  hpxml.header.created_date_and_time = Time.new(2000, 1, 1).strftime('%Y-%m-%dT%H:%M:%S%:z') # Hard-code to prevent diffs
  hpxml.header.energystar_calculation_version = ESConstants.SFNationalVer3_1
  hpxml.header.eri_calculation_version = 'latest'

  # set up state code for CZ4C
  if hpxml_file.include?('CZ4C_')
    hpxml.header.state_code = File.basename(hpxml_file)[5..6]
  elsif hpxml.header.state_code = File.basename(hpxml_file)[4..5]
  end

  if hpxml_file.include?('CZ3_AL_Birmingham')
    hpxml.header.zip_code = '35201'
  elsif hpxml_file.include?('CZ3_AL_Montgomery-Dannelly')
    hpxml.header.zip_code = '36101'
  elsif hpxml_file.include?('CZ1_HI_Honolulu')
    hpxml.header.zip_code = '96801'
  elsif hpxml_file.include?('CZ1_FL_Miami')
    hpxml.header.zip_code = '33101'
  elsif hpxml_file.include?('CZ2_LA_Baton')
    hpxml.header.zip_code = '70801'
  elsif hpxml_file.include?('CZ2_TX_Houston-Bush')
    hpxml.header.zip_code = '77001'
  elsif hpxml_file.include?('CZ2_AZ_Phoenix-Sky')
    hpxml.header.zip_code = '85001'
  elsif hpxml_file.include?('CZ3_CA_San')
    hpxml.header.zip_code = '94102'
  elsif hpxml_file.include?('CZ2_GA_Savannah')
    hpxml.header.zip_code = '31401'
  elsif hpxml_file.include?('CZ2_FL_Tampa')
    hpxml.header.zip_code = '33601'
  elsif hpxml_file.include?('CZ2_CA_Tucson')
    hpxml.header.zip_code = '92225'
  elsif hpxml_file.include?('CZ3_GA_Atlanta-Hartsfield-Jackson')
    hpxml.header.zip_code = '30301'
  elsif hpxml_file.include?('CZ3_SC_Charleston')
    hpxml.header.zip_code = '29401'
  elsif hpxml_file.include?('CZ3_NC_Charlotte-Douglas')
    hpxml.header.zip_code = '28201'
  elsif hpxml_file.include?('CZ3_SC_Columbia')
    hpxml.header.zip_code = '29201'
  elsif hpxml_file.include?('CZ3_TX_Dallas-Fort')
    hpxml.header.zip_code = '75201'
  elsif hpxml_file.include?('CZ3_TX_El')
    hpxml.header.zip_code = '79835'
  elsif hpxml_file.include?('CZ3_MS_Jackson')
    hpxml.header.zip_code = '39201'
  elsif hpxml_file.include?('CZ3_AZ_Kingman')
    hpxml.header.zip_code = '86401'
  elsif hpxml_file.include?('CZ3_NV_Las')
    hpxml.header.zip_code = '89044'
  elsif hpxml_file.include?('CZ3_AR_Little')
    hpxml.header.zip_code = '72201'
  elsif hpxml_file.include?('CZ3_CA_Los')
    hpxml.header.zip_code = '90001'
  elsif hpxml_file.include?('CZ3_NM_Lubbock')
    hpxml.header.zip_code = '79401'
  elsif hpxml_file.include?('CZ3_GA_Macon-Middle')
    hpxml.header.zip_code = '31201'
  elsif hpxml_file.include?('CZ3_TN_Memphis')
    hpxml.header.zip_code = '37501'
  elsif hpxml_file.include?('CZ3_LA_Monroe')
    hpxml.header.zip_code = '71201'
  elsif hpxml_file.include?('CZ3_OK_Oklahoma')
    hpxml.header.zip_code = '73101'
  elsif hpxml_file.include?('CZ3_UT_Saint')
    hpxml.header.zip_code = '84770'
  elsif hpxml_file.include?('CZ2_TX_San')
    hpxml.header.zip_code = '78201'
  elsif hpxml_file.include?('CZ3_LA_Shreveport')
    hpxml.header.zip_code = '71101'
  elsif hpxml_file.include?('CZ3_AR_Shreveport')
    hpxml.header.zip_code = '71101'
  elsif hpxml_file.include?('CZ3_MS_Tupelo')
    hpxml.header.zip_code = '38801'
  elsif hpxml_file.include?('CZ3_TX_Wichita')
    hpxml.header.zip_code = '76301'
  elsif hpxml_file.include?('CZ3_NC_Wilmington')
    hpxml.header.zip_code = '28401'
  elsif hpxml_file.include?('CZ4_NM_Albuquerque')
    hpxml.header.zip_code = '87101'
  elsif hpxml_file.include?('CZ4_TX_Amarillo')
    hpxml.header.zip_code = '79101'
  elsif hpxml_file.include?('CZ4_OK_Amarillo')
    hpxml.header.zip_code = '79101'
  elsif hpxml_file.include?('CZ4_MD_Baltimore-Washington')
    hpxml.header.zip_code = '21201'
  elsif hpxml_file.include?('CZ4_DC_Baltimore-Washington')
    hpxml.header.zip_code = '21201'
  elsif hpxml_file.include?('CZ4_WV_Charleston-Yeager')
    hpxml.header.zip_code = '25301'
  elsif hpxml_file.include?('CZ4_GA_Chattanooga-Lovell')
    hpxml.header.zip_code = '30736'
  elsif hpxml_file.include?('CZ4_OH_Cincinnati')
    hpxml.header.zip_code = '45201'
  elsif hpxml_file.include?('CZ4_IN_Evansville')
    hpxml.header.zip_code = '47701'
  elsif hpxml_file.include?('CZ4_KY_Lexington-Bluegrass')
    hpxml.header.zip_code = '40502'
  elsif hpxml_file.include?('CZ4_TN_Nashville')
    hpxml.header.zip_code = '37201'
  elsif hpxml_file.include?('CZ4_NY_New')
    hpxml.header.zip_code = '10001'
  elsif hpxml_file.include?('CZ4_NJ_Newark')
    hpxml.header.zip_code = '07101'
  elsif hpxml_file.include?('CZ4_PA_Philadelphia')
    hpxml.header.zip_code = '19019'
  elsif hpxml_file.include?('CZ4_AZ_Prescott-Love')
    hpxml.header.zip_code = '86301'
  elsif hpxml_file.include?('CZ4_NC_Raleigh-Durham')
    hpxml.header.zip_code = '27601'
  elsif hpxml_file.include?('CZ4_VA_Richmond')
    hpxml.header.zip_code = '23173'
  elsif hpxml_file.include?('CZ4_CA_Sacramento')
    hpxml.header.zip_code = '94203'
  elsif hpxml_file.include?('CZ4_AR_Springfield')
    hpxml.header.zip_code = '72756'
  elsif hpxml_file.include?('CZ4_MO_St')
    hpxml.header.zip_code = '63101'
  elsif hpxml_file.include?('CZ4_IL_St')
    hpxml.header.zip_code = '63101'
  elsif hpxml_file.include?('CZ4_KS_Topeka-Phillip')
    hpxml.header.zip_code = '66601'
  elsif hpxml_file.include?('CZ4_CO_Trinidad-Las')
    hpxml.header.zip_code = '81082'
  elsif hpxml_file.include?('CZ4_DE_Wilmington-New')
    hpxml.header.zip_code = '19801'
  elsif hpxml_file.include?('CZ4C_CA_Arcata')
    hpxml.header.zip_code = '95521'
  elsif hpxml_file.include?('CZ4C_OR_Portland')
    hpxml.header.zip_code = '97086'
  elsif hpxml_file.include?('CZ4C_WA_Seattle-Tacoma')
    hpxml.header.zip_code = '98101'
  elsif hpxml_file.include?('CZ5_NY_Albany')
    hpxml.header.zip_code = '12202'
  elsif hpxml_file.include?('CZ5_NJ_Allentown-Lehigh')
    hpxml.header.zip_code = '18101'
  elsif hpxml_file.include?('CZ5_ID_Boise')
    hpxml.header.zip_code = '83702'
  elsif hpxml_file.include?('CZ5_MA_Boston-Logan')
    hpxml.header.zip_code = '02108'
  elsif hpxml_file.include?('CZ5_CO_Colorado')
    hpxml.header.zip_code = '80902'
  elsif hpxml_file.include?('CZ5_OH_Columbus-Port')
    hpxml.header.zip_code = '43081'
  elsif hpxml_file.include?('CZ5_IA_Des')
    hpxml.header.zip_code = '50307'
  elsif hpxml_file.include?('CZ5_AZ_Flagstaff-Pulliam')
    hpxml.header.zip_code = '86001'
  elsif hpxml_file.include?('CZ5_NM_Flagstaff-Pulliam')
    hpxml.header.zip_code = '86001'
  elsif hpxml_file.include?('CZ5_KS_Goodland-Renner')
    hpxml.header.zip_code = '67735'
  elsif hpxml_file.include?('CZ5_PA_Harrisburg')
    hpxml.header.zip_code = '17101'
  elsif hpxml_file.include?('CZ5_CT_Hartford-Bradley')
    hpxml.header.zip_code = '06101'
  elsif hpxml_file.include?('CZ5_IN_Indianapolis')
    hpxml.header.zip_code = '46201'
  elsif hpxml_file.include?('CZ5_MO_Kirksville')
    hpxml.header.zip_code = '63501'
  elsif hpxml_file.include?('CZ5_MI_Lansing-Capital')
    hpxml.header.zip_code = '48906'
  elsif hpxml_file.include?('CZ5_NH_Manchester')
    hpxml.header.zip_code = '03101'
  elsif hpxml_file.include?('CZ5_NE_Omaha')
    hpxml.header.zip_code = '68102'
  elsif hpxml_file.include?('CZ5_IL_Peoria-Greater')
    hpxml.header.zip_code = '61602'
  elsif hpxml_file.include?('CZ5_RI_Providence-T')
    hpxml.header.zip_code = '02903'
  elsif hpxml_file.include?('CZ5_OR_Redmond-Roberts')
    hpxml.header.zip_code = '97756'
  elsif hpxml_file.include?('CZ5_NV_Reno-Tahoe')
    hpxml.header.zip_code = '89501'
  elsif hpxml_file.include?('CZ5_CA_Reno-Tahoe')
    hpxml.header.zip_code = '89501'
  elsif hpxml_file.include?('CZ5_UT_Salt')
    hpxml.header.zip_code = '84150'
  elsif hpxml_file.include?('CZ5_WY_Scottsbluff-W')
    hpxml.header.zip_code = '69361'
  elsif hpxml_file.include?('CZ5_SD_Sioux')
    hpxml.header.zip_code = '51101'
  elsif hpxml_file.include?('CZ5_WA_Spokane')
    hpxml.header.zip_code = '99201'
  elsif hpxml_file.include?('CZ6_MI_Alpena')
    hpxml.header.zip_code = '49707'
  elsif hpxml_file.include?('CZ6_NY_Binghamton-Edwin')
    hpxml.header.zip_code = '13901'
  elsif hpxml_file.include?('CZ6_ND_Bismarck')
    hpxml.header.zip_code = '58501'
  elsif hpxml_file.include?('CZ6_PA_Bradford')
    hpxml.header.zip_code = '16701'
  elsif hpxml_file.include?('CZ6_VT_Burlington')
    hpxml.header.zip_code = '05401'
  elsif hpxml_file.include?('CZ6_WY_Cheyenne')
    hpxml.header.zip_code = '82001'
  elsif hpxml_file.include?('CZ6_NH_Concord')
    hpxml.header.zip_code = '03301'
  elsif hpxml_file.include?('CZ6_MT_Helena')
    hpxml.header.zip_code = '59601'
  elsif hpxml_file.include?('CZ6_WA_Kalispell-Glacier')
    hpxml.header.zip_code = '99224'
  elsif hpxml_file.include?('CZ6_WI_Madison-Dane')
    hpxml.header.zip_code = '53703'
  elsif hpxml_file.include?('CZ6_IA_Mason')
    hpxml.header.zip_code = '50401'
  elsif hpxml_file.include?('CZ6_MN_Minneapolis-St')
    hpxml.header.zip_code = '55401'
  elsif hpxml_file.include?('CZ6_SD_Pierre')
    hpxml.header.zip_code = '57501'
  elsif hpxml_file.include?('CZ6_ID_Pocatello')
    hpxml.header.zip_code = '83201'
  elsif hpxml_file.include?('CZ6_ME_Portland')
    hpxml.header.zip_code = '04101'
  elsif hpxml_file.include?('CZ6_UT_Vernal')
    hpxml.header.zip_code = '84078'
  elsif hpxml_file.include?('CZ7_AK_Anchorage')
    hpxml.header.zip_code = '99501'
  elsif hpxml_file.include?('CZ7_ME_Caribou')
    hpxml.header.zip_code = '04736'
  elsif hpxml_file.include?('CZ7_MN_Duluth')
    hpxml.header.zip_code = '55802'
  elsif hpxml_file.include?('CZ7_WI_Duluth')
    hpxml.header.zip_code = '55802'
  elsif hpxml_file.include?('CZ7_CO_Gunnison')
    hpxml.header.zip_code = '81230'
  elsif hpxml_file.include?('CZ7_WY_Jackson')
    hpxml.header.zip_code = '83001'
  elsif hpxml_file.include?('CZ7_ND_Minot')
    hpxml.header.zip_code = '58701'
  elsif hpxml_file.include?('CZ7_MI_Sault')
    hpxml.header.zip_code = '49783'
  elsif hpxml_file.include?('CZ8_AK_Fairbanks')
    hpxml.header.zip_code = '99701'
  elsif hpxml_file.include?('CZ6_CO_Eagle')
    hpxml.header.zip_code = '81631'
  elsif hpxml_file.include?('CZ6_CA_Eagle')
    hpxml.header.zip_code = '90042'
  elsif hpxml_file.include?('CZ5_WV_Elkins-Randolph')
    hpxml.header.zip_code = '26241'
  elsif hpxml_file.include?('CZ5_NC_Elkins-Randolph')
    hpxml.header.zip_code = '28621'
  elsif hpxml_file.include?('CZ2_AL_Mobile-Rgnl')
    hpxml.header.zip_code = '36601'
  elsif hpxml_file.include?('CZ2_MS_Mobile-Rgnl')
    hpxml.header.zip_code = '39563'
  end
end

def set_hpxml_site(hpxml_file, hpxml)
  if hpxml_file.include?('elec')
    hpxml.site.fuels = [HPXML::FuelTypeElectricity]
  else
    hpxml.site.fuels = [HPXML::FuelTypeElectricity, HPXML::FuelTypeNaturalGas]
  end
end

def set_hpxml_building_construction(hpxml_file, hpxml)
  if ['EnergyStar', '2021IECC'].any? { |program| hpxml_file.include? program }
    hpxml.building_construction.residential_facility_type = HPXML::ResidentialTypeSFD
    hpxml.building_construction.number_of_conditioned_floors = 2
    hpxml.building_construction.number_of_conditioned_floors_above_grade = 2
    hpxml.building_construction.number_of_bedrooms = 3
    hpxml.building_construction.conditioned_floor_area = 2376
    if hpxml_file.include?('_cond_bsmt')
      footprint_area = (hpxml.building_construction.conditioned_floor_area / hpxml.building_construction.number_of_conditioned_floors)
      hpxml.building_construction.number_of_conditioned_floors += 1
      hpxml.building_construction.conditioned_floor_area += footprint_area
    end
    hpxml.building_construction.conditioned_building_volume = 8.5 * hpxml.building_construction.conditioned_floor_area
  end
end

def set_hpxml_building_occupancy(hpxml_file, hpxml) # ignore this section
  if hpxml_file.include?('HERS_AutoGen') || hpxml_file.include?('HERS_Method') || hpxml_file.include?('Hot_Water')
    hpxml.building_occupancy.number_of_residents = nil
  end
end

def set_hpxml_climate_and_risk_zones(hpxml_file, hpxml) # generic section, shouldn't change between IECC and EPA
  hpxml.climate_and_risk_zones.climate_zone_ieccs.add(year: 2006)
  hpxml.climate_and_risk_zones.weather_station_id = 'WeatherStation'
  if hpxml_file.include?('CZ1_HI_Honolulu')
    hpxml.climate_and_risk_zones.climate_zone_ieccs[0].zone = '1A'
    hpxml.climate_and_risk_zones.weather_station_name = 'Honolulu'
    hpxml.climate_and_risk_zones.weather_station_epw_filepath = 'USA_HI_Honolulu.Intl.AP.911820_TMY3.epw'
  elsif hpxml_file.include?('CZ1_FL_Miami')
    hpxml.climate_and_risk_zones.climate_zone_ieccs[0].zone = '1A'
    hpxml.climate_and_risk_zones.weather_station_name = 'Miami'
    hpxml.climate_and_risk_zones.weather_station_epw_filepath = 'USA_FL_Miami.Intl.AP.722020_TMY3.epw'
  elsif hpxml_file.include?('CZ5_NY_Albany')
    hpxml.climate_and_risk_zones.climate_zone_ieccs[0].zone = '5A'
    hpxml.climate_and_risk_zones.weather_station_name = 'Albany'
    hpxml.climate_and_risk_zones.weather_station_epw_filepath = 'USA_NY_Albany.County.AP.725180_TMY3.epw'
  elsif hpxml_file.include?('CZ4_NM_Albuquerque')
    hpxml.climate_and_risk_zones.climate_zone_ieccs[0].zone = '4A'
    hpxml.climate_and_risk_zones.weather_station_name = 'Albuquerque'
    hpxml.climate_and_risk_zones.weather_station_epw_filepath = 'USA_NM_Albuquerque.Intl.AP.723650_TMY3.epw'
  elsif hpxml_file.include?('CZ2_MS_Mobile-Rgnl')
    hpxml.climate_and_risk_zones.climate_zone_ieccs[0].zone = '2A'
    hpxml.climate_and_risk_zones.weather_station_name = 'Mobile-Rgnl'
    hpxml.climate_and_risk_zones.weather_station_epw_filepath = 'USA_AL_Mobile-Rgnl.AP.722230_TMY3.epw'
  elsif hpxml_file.include?('CZ3_AL_Birmingham')
    hpxml.climate_and_risk_zones.climate_zone_ieccs[0].zone = '3A'
    hpxml.climate_and_risk_zones.weather_station_name = 'Birmingham'
    hpxml.climate_and_risk_zones.weather_station_epw_filepath = 'USA_AL_Birmingham.Muni.AP.722280_TMY3.epw'
  elsif hpxml_file.include?('CZ3_AL_Montgomery-Dannelly')
    hpxml.climate_and_risk_zones.climate_zone_ieccs[0].zone = '3A'
    hpxml.climate_and_risk_zones.weather_station_name = 'Montgomery-Dannelly'
    hpxml.climate_and_risk_zones.weather_station_epw_filepath = 'USA_AL_Montgomery-Dannelly.Field.722260_TMY3.epw'
  elsif hpxml_file.include?('CZ2_LA_Baton')
    hpxml.climate_and_risk_zones.climate_zone_ieccs[0].zone = '2A'
    hpxml.climate_and_risk_zones.weather_station_name = 'Baton'
    hpxml.climate_and_risk_zones.weather_station_epw_filepath = 'USA_LA_Baton.Rouge-Ryan.AP.722317_TMY3.epw'
  elsif hpxml_file.include?('CZ2_TX_Houston-Bush')
    hpxml.climate_and_risk_zones.climate_zone_ieccs[0].zone = '2A'
    hpxml.climate_and_risk_zones.weather_station_name = 'Houston-Bush'
    hpxml.climate_and_risk_zones.weather_station_epw_filepath = 'USA_TX_Houston-Bush.Intercontinental.AP.722430_TMY3.epw'
  elsif hpxml_file.include?('CZ2_AL_Mobile-Rgnl')
    hpxml.climate_and_risk_zones.climate_zone_ieccs[0].zone = '2A'
    hpxml.climate_and_risk_zones.weather_station_name = 'Mobile-Rgnl'
    hpxml.climate_and_risk_zones.weather_station_epw_filepath = 'USA_AL_Mobile-Rgnl.AP.722230_TMY3.epw'
  elsif hpxml_file.include?('CZ2_AZ_Phoenix-Sky')
    hpxml.climate_and_risk_zones.climate_zone_ieccs[0].zone = '2A'
    hpxml.climate_and_risk_zones.weather_station_name = 'Phoenix-Sky'
    hpxml.climate_and_risk_zones.weather_station_epw_filepath = 'USA_AZ_Phoenix-Sky.Harbor.Intl.AP.722780_TMY3.epw'
  elsif hpxml_file.include?('CZ2_TX_San')
    hpxml.climate_and_risk_zones.climate_zone_ieccs[0].zone = '2A'
    hpxml.climate_and_risk_zones.weather_station_name = 'San'
    hpxml.climate_and_risk_zones.weather_station_epw_filepath = 'USA_TX_San.Antonio-Stinson.AP.722523_TMY3.epw'
  elsif hpxml_file.include?('CZ2_GA_Savannah')
    hpxml.climate_and_risk_zones.climate_zone_ieccs[0].zone = '2A'
    hpxml.climate_and_risk_zones.weather_station_name = 'Savannah'
    hpxml.climate_and_risk_zones.weather_station_epw_filepath = 'USA_GA_Savannah.Intl.AP.722070_TMY3.epw'
  elsif hpxml_file.include?('CZ2_FL_Tampa')
    hpxml.climate_and_risk_zones.climate_zone_ieccs[0].zone = '2A'
    hpxml.climate_and_risk_zones.weather_station_name = 'Tampa'
    hpxml.climate_and_risk_zones.weather_station_epw_filepath = 'USA_FL_Tampa.Intl.AP.722110_TMY3.epw'
  elsif hpxml_file.include?('CZ2_CA_Tucson')
    hpxml.climate_and_risk_zones.climate_zone_ieccs[0].zone = '2A'
    hpxml.climate_and_risk_zones.weather_station_name = 'Tucson'
    hpxml.climate_and_risk_zones.weather_station_epw_filepath = 'USA_AZ_Tucson.Intl.AP.722740_TMY3.epw'
  elsif hpxml_file.include?('CZ3_GA_Atlanta-Hartsfield-Jackson')
    hpxml.climate_and_risk_zones.climate_zone_ieccs[0].zone = '3A'
    hpxml.climate_and_risk_zones.weather_station_name = 'Atlanta-Hartsfield-Jackson'
    hpxml.climate_and_risk_zones.weather_station_epw_filepath = 'USA_GA_Atlanta-Hartsfield-Jackson.Intl.AP.722190_TMY3.epw'
  elsif hpxml_file.include?('CZ3_SC_Charleston')
    hpxml.climate_and_risk_zones.climate_zone_ieccs[0].zone = '3A'
    hpxml.climate_and_risk_zones.weather_station_name = 'Charleston'
    hpxml.climate_and_risk_zones.weather_station_epw_filepath = 'USA_SC_Charleston.Intl.AP.722080_TMY3.epw'
  elsif hpxml_file.include?('CZ3_NC_Charlotte-Douglas')
    hpxml.climate_and_risk_zones.climate_zone_ieccs[0].zone = '3A'
    hpxml.climate_and_risk_zones.weather_station_name = 'Charlotte-Douglas'
    hpxml.climate_and_risk_zones.weather_station_epw_filepath = 'USA_NC_Charlotte-Douglas.Intl.AP.723140_TMY3.epw'
  elsif hpxml_file.include?('CZ3_SC_Columbia')
    hpxml.climate_and_risk_zones.climate_zone_ieccs[0].zone = '3A'
    hpxml.climate_and_risk_zones.weather_station_name = 'Columbia'
    hpxml.climate_and_risk_zones.weather_station_epw_filepath = 'USA_SC_Columbia.Metro.AP.723100_TMY3.epw'
  elsif hpxml_file.include?('CZ3_TX_Dallas-Fort')
    hpxml.climate_and_risk_zones.climate_zone_ieccs[0].zone = '3A'
    hpxml.climate_and_risk_zones.weather_station_name = 'Dallas-Fort'
    hpxml.climate_and_risk_zones.weather_station_epw_filepath = 'USA_TX_Dallas-Fort.Worth.Intl.AP.722590_TMY3.epw'
  elsif hpxml_file.include?('CZ3_TX_El')
    hpxml.climate_and_risk_zones.climate_zone_ieccs[0].zone = '3A'
    hpxml.climate_and_risk_zones.weather_station_name = 'El'
    hpxml.climate_and_risk_zones.weather_station_epw_filepath = 'USA_TX_El.Paso.Intl.AP.722700_TMY3.epw'
  elsif hpxml_file.include?('CZ3_MS_Jackson')
    hpxml.climate_and_risk_zones.climate_zone_ieccs[0].zone = '3A'
    hpxml.climate_and_risk_zones.weather_station_name = 'Jackson'
    hpxml.climate_and_risk_zones.weather_station_epw_filepath = 'USA_MS_Jackson.Intl.AP.722350_TMY3.epw'
  elsif hpxml_file.include?('CZ3_AZ_Kingman')
    hpxml.climate_and_risk_zones.climate_zone_ieccs[0].zone = '3A'
    hpxml.climate_and_risk_zones.weather_station_name = 'Kingman'
    hpxml.climate_and_risk_zones.weather_station_epw_filepath = 'USA_AZ_Kingman.AWOS.723700_TMY3.epw'
  elsif hpxml_file.include?('CZ3_NV_Las')
    hpxml.climate_and_risk_zones.climate_zone_ieccs[0].zone = '3A'
    hpxml.climate_and_risk_zones.weather_station_name = 'Las'
    hpxml.climate_and_risk_zones.weather_station_epw_filepath = 'USA_NV_Las.Vegas-McCarran.Intl.AP.723860_TMY3.epw'
  elsif hpxml_file.include?('CZ3_AR_Little')
    hpxml.climate_and_risk_zones.climate_zone_ieccs[0].zone = '3A'
    hpxml.climate_and_risk_zones.weather_station_name = 'Little'
    hpxml.climate_and_risk_zones.weather_station_epw_filepath = 'USA_AR_Little.Rock-Adams.Field.723403_TMY3.epw'
  elsif hpxml_file.include?('CZ3_CA_Los')
    hpxml.climate_and_risk_zones.climate_zone_ieccs[0].zone = '3A'
    hpxml.climate_and_risk_zones.weather_station_name = 'Los'
    hpxml.climate_and_risk_zones.weather_station_epw_filepath = 'USA_CA_Los.Angeles.Intl.AP.722950_TMY3.epw'
  elsif hpxml_file.include?('CZ3_NM_Lubbock')
    hpxml.climate_and_risk_zones.climate_zone_ieccs[0].zone = '3A'
    hpxml.climate_and_risk_zones.weather_station_name = 'Lubbock'
    hpxml.climate_and_risk_zones.weather_station_epw_filepath = 'USA_TX_Lubbock.Intl.AP.722670_TMY3.epw'
  elsif hpxml_file.include?('CZ3_GA_Macon-Middle')
    hpxml.climate_and_risk_zones.climate_zone_ieccs[0].zone = '3A'
    hpxml.climate_and_risk_zones.weather_station_name = 'Macon-Middle'
    hpxml.climate_and_risk_zones.weather_station_epw_filepath = 'USA_GA_Macon-Middle.Georgia.Rgnl.AP.722170_TMY3.epw'
  elsif hpxml_file.include?('CZ3_TN_Memphis')
    hpxml.climate_and_risk_zones.climate_zone_ieccs[0].zone = '3A'
    hpxml.climate_and_risk_zones.weather_station_name = 'Memphis'
    hpxml.climate_and_risk_zones.weather_station_epw_filepath = 'USA_TN_Memphis.Intl.AP.723340_TMY3.epw'
  elsif hpxml_file.include?('CZ3_LA_Monroe')
    hpxml.climate_and_risk_zones.climate_zone_ieccs[0].zone = '3A'
    hpxml.climate_and_risk_zones.weather_station_name = 'Monroe'
    hpxml.climate_and_risk_zones.weather_station_epw_filepath = 'USA_LA_Monroe.Rgnl.AP.722486_TMY3.epw'
  elsif hpxml_file.include?('CZ3_OK_Oklahoma')
    hpxml.climate_and_risk_zones.climate_zone_ieccs[0].zone = '3A'
    hpxml.climate_and_risk_zones.weather_station_name = 'Oklahoma'
    hpxml.climate_and_risk_zones.weather_station_epw_filepath = 'USA_OK_Oklahoma.City-Tinker.AFB.723540_TMY3.epw'
  elsif hpxml_file.include?('CZ3_UT_Saint')
    hpxml.climate_and_risk_zones.climate_zone_ieccs[0].zone = '3A'
    hpxml.climate_and_risk_zones.weather_station_name = 'Saint'
    hpxml.climate_and_risk_zones.weather_station_epw_filepath = 'USA_UT_Saint.George.AWOS.724754_TMY3.epw'
  elsif hpxml_file.include?('CZ3_CA_San')
    hpxml.climate_and_risk_zones.climate_zone_ieccs[0].zone = '3A'
    hpxml.climate_and_risk_zones.weather_station_name = 'San'
    hpxml.climate_and_risk_zones.weather_station_epw_filepath = 'USA_CA_San.Francisco.Intl.AP.724940_TMY3.epw'
  elsif hpxml_file.include?('CZ3_LA_Shreveport')
    hpxml.climate_and_risk_zones.climate_zone_ieccs[0].zone = '3A'
    hpxml.climate_and_risk_zones.weather_station_name = 'Shreveport'
    hpxml.climate_and_risk_zones.weather_station_epw_filepath = 'USA_LA_Shreveport.Downtown.722484_TMY3.epw'
  elsif hpxml_file.include?('CZ3_AR_Shreveport')
    hpxml.climate_and_risk_zones.climate_zone_ieccs[0].zone = '3A'
    hpxml.climate_and_risk_zones.weather_station_name = 'Shreveport'
    hpxml.climate_and_risk_zones.weather_station_epw_filepath = 'USA_LA_Shreveport.Downtown.722484_TMY3.epw'
  elsif hpxml_file.include?('CZ3_MS_Tupelo')
    hpxml.climate_and_risk_zones.climate_zone_ieccs[0].zone = '3A'
    hpxml.climate_and_risk_zones.weather_station_name = 'Tupelo'
    hpxml.climate_and_risk_zones.weather_station_epw_filepath = 'USA_MS_Tupelo.Muni-C.D.Lemons.AP.723320_TMY3.epw'
  elsif hpxml_file.include?('CZ3_TX_Wichita')
    hpxml.climate_and_risk_zones.climate_zone_ieccs[0].zone = '3A'
    hpxml.climate_and_risk_zones.weather_station_name = 'Wichita'
    hpxml.climate_and_risk_zones.weather_station_epw_filepath = 'USA_TX_Wichita.Falls.Muni.AP.723510_TMY3.epw'
  elsif hpxml_file.include?('CZ3_NC_Wilmington')
    hpxml.climate_and_risk_zones.climate_zone_ieccs[0].zone = '3A'
    hpxml.climate_and_risk_zones.weather_station_name = 'Wilmington'
    hpxml.climate_and_risk_zones.weather_station_epw_filepath = 'USA_NC_Wilmington.Intl.AP.723013_TMY3.epw'
  elsif hpxml_file.include?('CZ4_NM_Albuquerque')
    hpxml.climate_and_risk_zones.climate_zone_ieccs[0].zone = '4A'
    hpxml.climate_and_risk_zones.weather_station_name = 'Albuquerque'
    hpxml.climate_and_risk_zones.weather_station_epw_filepath = 'USA_NM_Albuquerque.Intl.AP.723650_TMY3.epw'
  elsif hpxml_file.include?('CZ4_TX_Amarillo')
    hpxml.climate_and_risk_zones.climate_zone_ieccs[0].zone = '4A'
    hpxml.climate_and_risk_zones.weather_station_name = 'Amarillo'
    hpxml.climate_and_risk_zones.weather_station_epw_filepath = 'USA_TX_Amarillo.Intl.AP.723630_TMY3.epw'
  elsif hpxml_file.include?('CZ4_OK_Amarillo')
    hpxml.climate_and_risk_zones.climate_zone_ieccs[0].zone = '4A'
    hpxml.climate_and_risk_zones.weather_station_name = 'Amarillo'
    hpxml.climate_and_risk_zones.weather_station_epw_filepath = 'USA_TX_Amarillo.Intl.AP.723630_TMY3.epw'
  elsif hpxml_file.include?('CZ4_MD_Baltimore-Washington')
    hpxml.climate_and_risk_zones.climate_zone_ieccs[0].zone = '4A'
    hpxml.climate_and_risk_zones.weather_station_name = 'Baltimore-Washington'
    hpxml.climate_and_risk_zones.weather_station_epw_filepath = 'USA_MD_Baltimore-Washington.Intl.AP.724060_TMY3.epw'
  elsif hpxml_file.include?('CZ4_DC_Baltimore-Washington')
    hpxml.climate_and_risk_zones.climate_zone_ieccs[0].zone = '4A'
    hpxml.climate_and_risk_zones.weather_station_name = 'Baltimore-Washington'
    hpxml.climate_and_risk_zones.weather_station_epw_filepath = 'USA_MD_Baltimore-Washington.Intl.AP.724060_TMY3.epw'
  elsif hpxml_file.include?('CZ4_WV_Charleston-Yeager')
    hpxml.climate_and_risk_zones.climate_zone_ieccs[0].zone = '4A'
    hpxml.climate_and_risk_zones.weather_station_name = 'Charleston-Yeager'
    hpxml.climate_and_risk_zones.weather_station_epw_filepath = 'USA_WV_Charleston-Yeager.AP.724140_TMY3.epw'
  elsif hpxml_file.include?('CZ4_GA_Chattanooga-Lovell')
    hpxml.climate_and_risk_zones.climate_zone_ieccs[0].zone = '4A'
    hpxml.climate_and_risk_zones.weather_station_name = 'Chattanooga-Lovell'
    hpxml.climate_and_risk_zones.weather_station_epw_filepath = 'USA_TN_Chattanooga-Lovell.Field.AP.723240_TMY3.epw'
  elsif hpxml_file.include?('CZ4_OH_Cincinnati')
    hpxml.climate_and_risk_zones.climate_zone_ieccs[0].zone = '4A'
    hpxml.climate_and_risk_zones.weather_station_name = 'Cincinnati'
    hpxml.climate_and_risk_zones.weather_station_epw_filepath = 'USA_OH_Cincinnati.Muni.AP-Lunken.Field.724297_TMY3.epw'
  elsif hpxml_file.include?('CZ4_IN_Evansville')
    hpxml.climate_and_risk_zones.climate_zone_ieccs[0].zone = '4A'
    hpxml.climate_and_risk_zones.weather_station_name = 'Evansville'
    hpxml.climate_and_risk_zones.weather_station_epw_filepath = 'USA_IN_Evansville.Rgnl.AP.724320_TMY3.epw'
  elsif hpxml_file.include?('CZ4_KY_Lexington-Bluegrass')
    hpxml.climate_and_risk_zones.climate_zone_ieccs[0].zone = '4A'
    hpxml.climate_and_risk_zones.weather_station_name = 'Lexington-Bluegrass'
    hpxml.climate_and_risk_zones.weather_station_epw_filepath = 'USA_KY_Lexington-Bluegrass.AP.724220_TMY3.epw'
  elsif hpxml_file.include?('CZ4_TN_Nashville')
    hpxml.climate_and_risk_zones.climate_zone_ieccs[0].zone = '4A'
    hpxml.climate_and_risk_zones.weather_station_name = 'Nashville'
    hpxml.climate_and_risk_zones.weather_station_epw_filepath = 'USA_TN_Nashville.Intl.AP.723270_TMY3.epw'
  elsif hpxml_file.include?('CZ4_NY_New')
    hpxml.climate_and_risk_zones.climate_zone_ieccs[0].zone = '4A'
    hpxml.climate_and_risk_zones.weather_station_name = 'New'
    hpxml.climate_and_risk_zones.weather_station_epw_filepath = 'USA_NY_New.York-J.F.Kennedy.Intl.AP.744860_TMY3.epw'
  elsif hpxml_file.include?('CZ4_NJ_Newark')
    hpxml.climate_and_risk_zones.climate_zone_ieccs[0].zone = '4A'
    hpxml.climate_and_risk_zones.weather_station_name = 'Newark'
    hpxml.climate_and_risk_zones.weather_station_epw_filepath = 'USA_NJ_Newark.Intl.AP.725020_TMY3.epw'
  elsif hpxml_file.include?('CZ4_PA_Philadelphia')
    hpxml.climate_and_risk_zones.climate_zone_ieccs[0].zone = '4A'
    hpxml.climate_and_risk_zones.weather_station_name = 'Philadelphia'
    hpxml.climate_and_risk_zones.weather_station_epw_filepath = 'USA_PA_Philadelphia.Intl.AP.724080_TMY3.epw'
  elsif hpxml_file.include?('CZ4_AZ_Prescott-Love')
    hpxml.climate_and_risk_zones.climate_zone_ieccs[0].zone = '4A'
    hpxml.climate_and_risk_zones.weather_station_name = 'Prescott-Love'
    hpxml.climate_and_risk_zones.weather_station_epw_filepath = 'USA_AZ_Prescott-Love.Field.723723_TMY3.epw'
  elsif hpxml_file.include?('CZ4_NC_Raleigh-Durham')
    hpxml.climate_and_risk_zones.climate_zone_ieccs[0].zone = '4A'
    hpxml.climate_and_risk_zones.weather_station_name = 'Raleigh-Durham'
    hpxml.climate_and_risk_zones.weather_station_epw_filepath = 'USA_NC_Raleigh-Durham.Intl.AP.723060_TMY3.epw'
  elsif hpxml_file.include?('CZ4_VA_Richmond')
    hpxml.climate_and_risk_zones.climate_zone_ieccs[0].zone = '4A'
    hpxml.climate_and_risk_zones.weather_station_name = 'Richmond'
    hpxml.climate_and_risk_zones.weather_station_epw_filepath = 'USA_VA_Richmond.Intl.AP.724010_TMY3.epw'
  elsif hpxml_file.include?('CZ4_CA_Sacramento')
    hpxml.climate_and_risk_zones.climate_zone_ieccs[0].zone = '4A'
    hpxml.climate_and_risk_zones.weather_station_name = 'Sacramento'
    hpxml.climate_and_risk_zones.weather_station_epw_filepath = 'USA_CA_Sacramento.Metro.AP.724839_TMY3.epw'
  elsif hpxml_file.include?('CZ4_AR_Springfield')
    hpxml.climate_and_risk_zones.climate_zone_ieccs[0].zone = '4A'
    hpxml.climate_and_risk_zones.weather_station_name = 'Springfield'
    hpxml.climate_and_risk_zones.weather_station_epw_filepath = 'USA_MO_Springfield.Rgnl.AP.724400_TMY3.epw'
  elsif hpxml_file.include?('CZ4_MO_St')
    hpxml.climate_and_risk_zones.climate_zone_ieccs[0].zone = '4A'
    hpxml.climate_and_risk_zones.weather_station_name = 'St'
    hpxml.climate_and_risk_zones.weather_station_epw_filepath = 'USA_MO_St.Louis-Lambert.Intl.AP.724340_TMY3.epw'
  elsif hpxml_file.include?('CZ4_IL_St')
    hpxml.climate_and_risk_zones.climate_zone_ieccs[0].zone = '4A'
    hpxml.climate_and_risk_zones.weather_station_name = 'St'
    hpxml.climate_and_risk_zones.weather_station_epw_filepath = 'USA_MO_St.Louis-Lambert.Intl.AP.724340_TMY3.epw'
  elsif hpxml_file.include?('CZ4_KS_Topeka-Phillip')
    hpxml.climate_and_risk_zones.climate_zone_ieccs[0].zone = '4A'
    hpxml.climate_and_risk_zones.weather_station_name = 'Topeka-Phillip'
    hpxml.climate_and_risk_zones.weather_station_epw_filepath = 'USA_KS_Topeka-Phillip.Billard.Muni.AP.724560_TMY3.epw'
  elsif hpxml_file.include?('CZ4_CO_Trinidad-Las')
    hpxml.climate_and_risk_zones.climate_zone_ieccs[0].zone = '4A'
    hpxml.climate_and_risk_zones.weather_station_name = 'Trinidad-Las'
    hpxml.climate_and_risk_zones.weather_station_epw_filepath = 'USA_CO_Trinidad-Las.Animas.County.AP.724645_TMY3.epw'
  elsif hpxml_file.include?('CZ4_DE_Wilmington-New')
    hpxml.climate_and_risk_zones.climate_zone_ieccs[0].zone = '4A'
    hpxml.climate_and_risk_zones.weather_station_name = 'Wilmington-New'
    hpxml.climate_and_risk_zones.weather_station_epw_filepath = 'USA_DE_Wilmington-New.Castle.County.AP.724089_TMY3.epw'
  elsif hpxml_file.include?('CZ4C_CA_Arcata')
    hpxml.climate_and_risk_zones.climate_zone_ieccs[0].zone = '4C'
    hpxml.climate_and_risk_zones.weather_station_name = 'Arcata'
    hpxml.climate_and_risk_zones.weather_station_epw_filepath = 'USA_CA_Arcata.AP.725945_TMY3.epw'
  elsif hpxml_file.include?('CZ4C_OR_Portland')
    hpxml.climate_and_risk_zones.climate_zone_ieccs[0].zone = '4C'
    hpxml.climate_and_risk_zones.weather_station_name = 'Portland'
    hpxml.climate_and_risk_zones.weather_station_epw_filepath = 'USA_OR_Portland.Intl.AP.726980_TMY3.epw'
  elsif hpxml_file.include?('CZ4C_WA_Seattle-Tacoma')
    hpxml.climate_and_risk_zones.climate_zone_ieccs[0].zone = '4C'
    hpxml.climate_and_risk_zones.weather_station_name = 'Seattle-Tacoma'
    hpxml.climate_and_risk_zones.weather_station_epw_filepath = 'USA_WA_Seattle-Tacoma.Intl.AP.727930_TMY3.epw'
  elsif hpxml_file.include?('CZ5_NY_Albany')
    hpxml.climate_and_risk_zones.climate_zone_ieccs[0].zone = '5A'
    hpxml.climate_and_risk_zones.weather_station_name = 'Albany'
    hpxml.climate_and_risk_zones.weather_station_epw_filepath = 'USA_NY_Albany.County.AP.725180_TMY3.epw'
  elsif hpxml_file.include?('CZ5_NJ_Allentown-Lehigh')
    hpxml.climate_and_risk_zones.climate_zone_ieccs[0].zone = '5A'
    hpxml.climate_and_risk_zones.weather_station_name = 'Allentown-Lehigh'
    hpxml.climate_and_risk_zones.weather_station_epw_filepath = 'USA_PA_Allentown-Lehigh.Valley.Intl.AP.725170_TMY3.epw'
  elsif hpxml_file.include?('CZ5_ID_Boise')
    hpxml.climate_and_risk_zones.climate_zone_ieccs[0].zone = '5A'
    hpxml.climate_and_risk_zones.weather_station_name = 'Boise'
    hpxml.climate_and_risk_zones.weather_station_epw_filepath = 'USA_ID_Boise.Air.Terminal.726810_TMY3.epw'
  elsif hpxml_file.include?('CZ5_MA_Boston-Logan')
    hpxml.climate_and_risk_zones.climate_zone_ieccs[0].zone = '5A'
    hpxml.climate_and_risk_zones.weather_station_name = 'Boston-Logan'
    hpxml.climate_and_risk_zones.weather_station_epw_filepath = 'USA_MA_Boston-Logan.Intl.AP.725090_TMY3.epw'
  elsif hpxml_file.include?('CZ5_CO_Colorado')
    hpxml.climate_and_risk_zones.climate_zone_ieccs[0].zone = '5A'
    hpxml.climate_and_risk_zones.weather_station_name = 'Colorado'
    hpxml.climate_and_risk_zones.weather_station_epw_filepath = 'USA_CO_Colorado.Springs-Peterson.Field.724660_TMY3.epw'
  elsif hpxml_file.include?('CZ5_OH_Columbus-Port')
    hpxml.climate_and_risk_zones.climate_zone_ieccs[0].zone = '5A'
    hpxml.climate_and_risk_zones.weather_station_name = 'Columbus-Port'
    hpxml.climate_and_risk_zones.weather_station_epw_filepath = 'USA_OH_Columbus-Port.Columbus.Intl.AP.724280_TMY3.epw'
  elsif hpxml_file.include?('CZ5_IA_Des')
    hpxml.climate_and_risk_zones.climate_zone_ieccs[0].zone = '5A'
    hpxml.climate_and_risk_zones.weather_station_name = 'Des'
    hpxml.climate_and_risk_zones.weather_station_epw_filepath = 'USA_IA_Des.Moines.Intl.AP.725460_TMY3.epw'
  elsif hpxml_file.include?('CZ5_WV_Elkins-Randolph')
    hpxml.climate_and_risk_zones.climate_zone_ieccs[0].zone = '5A'
    hpxml.climate_and_risk_zones.weather_station_name = 'Elkins-Randolph'
    hpxml.climate_and_risk_zones.weather_station_epw_filepath = 'USA_WV_Elkins-Randolph.County.AP.724170_TMY3.epw'
  elsif hpxml_file.include?('CZ5_NC_Elkins-Randolph')
    hpxml.climate_and_risk_zones.climate_zone_ieccs[0].zone = '5A'
    hpxml.climate_and_risk_zones.weather_station_name = 'Elkins-Randolph'
    hpxml.climate_and_risk_zones.weather_station_epw_filepath = 'USA_WV_Elkins-Randolph.County.AP.724170_TMY3.epw'
  elsif hpxml_file.include?('CZ5_AZ_Flagstaff-Pulliam')
    hpxml.climate_and_risk_zones.climate_zone_ieccs[0].zone = '5A'
    hpxml.climate_and_risk_zones.weather_station_name = 'Flagstaff-Pulliam'
    hpxml.climate_and_risk_zones.weather_station_epw_filepath = 'USA_AZ_Flagstaff-Pulliam.AP.723755_TMY3.epw'
  elsif hpxml_file.include?('CZ5_NM_Flagstaff-Pulliam')
    hpxml.climate_and_risk_zones.climate_zone_ieccs[0].zone = '5A'
    hpxml.climate_and_risk_zones.weather_station_name = 'Flagstaff-Pulliam'
    hpxml.climate_and_risk_zones.weather_station_epw_filepath = 'USA_AZ_Flagstaff-Pulliam.AP.723755_TMY3.epw'
  elsif hpxml_file.include?('CZ5_KS_Goodland-Renner')
    hpxml.climate_and_risk_zones.climate_zone_ieccs[0].zone = '5A'
    hpxml.climate_and_risk_zones.weather_station_name = 'Goodland-Renner'
    hpxml.climate_and_risk_zones.weather_station_epw_filepath = 'USA_KS_Goodland-Renner.Field.724650_TMY3.epw'
  elsif hpxml_file.include?('CZ5_PA_Harrisburg')
    hpxml.climate_and_risk_zones.climate_zone_ieccs[0].zone = '5A'
    hpxml.climate_and_risk_zones.weather_station_name = 'Harrisburg'
    hpxml.climate_and_risk_zones.weather_station_epw_filepath = 'USA_PA_Harrisburg.Intl.AP.725115_TMY3.epw'
  elsif hpxml_file.include?('CZ5_CT_Hartford-Bradley')
    hpxml.climate_and_risk_zones.climate_zone_ieccs[0].zone = '5A'
    hpxml.climate_and_risk_zones.weather_station_name = 'Hartford-Bradley'
    hpxml.climate_and_risk_zones.weather_station_epw_filepath = 'USA_CT_Hartford-Bradley.Intl.AP.725080_TMY3.epw'
  elsif hpxml_file.include?('CZ5_IN_Indianapolis')
    hpxml.climate_and_risk_zones.climate_zone_ieccs[0].zone = '5A'
    hpxml.climate_and_risk_zones.weather_station_name = 'Indianapolis'
    hpxml.climate_and_risk_zones.weather_station_epw_filepath = 'USA_IN_Indianapolis.Intl.AP.724380_TMY3.epw'
  elsif hpxml_file.include?('CZ5_MO_Kirksville')
    hpxml.climate_and_risk_zones.climate_zone_ieccs[0].zone = '5A'
    hpxml.climate_and_risk_zones.weather_station_name = 'Kirksville'
    hpxml.climate_and_risk_zones.weather_station_epw_filepath = 'USA_MO_Kirksville.Muni.AP.724455_TMY3.epw'
  elsif hpxml_file.include?('CZ5_MI_Lansing-Capital')
    hpxml.climate_and_risk_zones.climate_zone_ieccs[0].zone = '5A'
    hpxml.climate_and_risk_zones.weather_station_name = 'Lansing-Capital'
    hpxml.climate_and_risk_zones.weather_station_epw_filepath = 'USA_MI_Lansing-Capital.City.AP.725390_TMY3.epw'
  elsif hpxml_file.include?('CZ5_NH_Manchester')
    hpxml.climate_and_risk_zones.climate_zone_ieccs[0].zone = '5A'
    hpxml.climate_and_risk_zones.weather_station_name = 'Manchester'
    hpxml.climate_and_risk_zones.weather_station_epw_filepath = 'USA_NH_Manchester.Muni.AP.743945_TMY3.epw'
  elsif hpxml_file.include?('CZ5_NE_Omaha')
    hpxml.climate_and_risk_zones.climate_zone_ieccs[0].zone = '5A'
    hpxml.climate_and_risk_zones.weather_station_name = 'Omaha'
    hpxml.climate_and_risk_zones.weather_station_epw_filepath = 'USA_NE_Omaha.WSFO.725530_TMY3.epw'
  elsif hpxml_file.include?('CZ5_IL_Peoria-Greater')
    hpxml.climate_and_risk_zones.climate_zone_ieccs[0].zone = '5A'
    hpxml.climate_and_risk_zones.weather_station_name = 'Peoria-Greater'
    hpxml.climate_and_risk_zones.weather_station_epw_filepath = 'USA_IL_Peoria-Greater.Peoria.AP.725320_TMY3.epw'
  elsif hpxml_file.include?('CZ5_RI_Providence-T')
    hpxml.climate_and_risk_zones.climate_zone_ieccs[0].zone = '5A'
    hpxml.climate_and_risk_zones.weather_station_name = 'Providence-T'
    hpxml.climate_and_risk_zones.weather_station_epw_filepath = 'USA_RI_Providence-T.F.Green.State.AP.725070_TMY3.epw'
  elsif hpxml_file.include?('CZ5_OR_Redmond-Roberts')
    hpxml.climate_and_risk_zones.climate_zone_ieccs[0].zone = '5A'
    hpxml.climate_and_risk_zones.weather_station_name = 'Redmond-Roberts'
    hpxml.climate_and_risk_zones.weather_station_epw_filepath = 'USA_OR_Redmond-Roberts.Field.726835_TMY3.epw'
  elsif hpxml_file.include?('CZ5_NV_Reno-Tahoe')
    hpxml.climate_and_risk_zones.climate_zone_ieccs[0].zone = '5A'
    hpxml.climate_and_risk_zones.weather_station_name = 'Reno-Tahoe'
    hpxml.climate_and_risk_zones.weather_station_epw_filepath = 'USA_NV_Reno-Tahoe.Intl.AP.724880_TMY3.epw'
  elsif hpxml_file.include?('CZ5_CA_Reno-Tahoe')
    hpxml.climate_and_risk_zones.climate_zone_ieccs[0].zone = '5A'
    hpxml.climate_and_risk_zones.weather_station_name = 'Reno-Tahoe'
    hpxml.climate_and_risk_zones.weather_station_epw_filepath = 'USA_NV_Reno-Tahoe.Intl.AP.724880_TMY3.epw'
  elsif hpxml_file.include?('CZ5_UT_Salt')
    hpxml.climate_and_risk_zones.climate_zone_ieccs[0].zone = '5A'
    hpxml.climate_and_risk_zones.weather_station_name = 'Salt'
    hpxml.climate_and_risk_zones.weather_station_epw_filepath = 'USA_UT_Salt.Lake.City.Intl.AP.725720_TMY3.epw'
  elsif hpxml_file.include?('CZ5_WY_Scottsbluff-W')
    hpxml.climate_and_risk_zones.climate_zone_ieccs[0].zone = '5A'
    hpxml.climate_and_risk_zones.weather_station_name = 'Scottsbluff-W'
    hpxml.climate_and_risk_zones.weather_station_epw_filepath = 'USA_NE_Scottsbluff-W.B.Heilig.Field.725660_TMY3.epw'
  elsif hpxml_file.include?('CZ5_SD_Sioux')
    hpxml.climate_and_risk_zones.climate_zone_ieccs[0].zone = '5A'
    hpxml.climate_and_risk_zones.weather_station_name = 'Sioux'
    hpxml.climate_and_risk_zones.weather_station_epw_filepath = 'USA_IA_Sioux.City-Sioux.Gateway.AP.725570_TMY3.epw'
  elsif hpxml_file.include?('CZ5_WA_Spokane')
    hpxml.climate_and_risk_zones.climate_zone_ieccs[0].zone = '5A'
    hpxml.climate_and_risk_zones.weather_station_name = 'Spokane'
    hpxml.climate_and_risk_zones.weather_station_epw_filepath = 'USA_WA_Spokane.Intl.AP.727850_TMY3.epw'
  elsif hpxml_file.include?('CZ6_MI_Alpena')
    hpxml.climate_and_risk_zones.climate_zone_ieccs[0].zone = '6A'
    hpxml.climate_and_risk_zones.weather_station_name = 'Alpena'
    hpxml.climate_and_risk_zones.weather_station_epw_filepath = 'USA_MI_Alpena.County.Rgnl.AP.726390_TMY3.epw'
  elsif hpxml_file.include?('CZ6_NY_Binghamton-Edwin')
    hpxml.climate_and_risk_zones.climate_zone_ieccs[0].zone = '6A'
    hpxml.climate_and_risk_zones.weather_station_name = 'Binghamton-Edwin'
    hpxml.climate_and_risk_zones.weather_station_epw_filepath = 'USA_NY_Binghamton-Edwin.A.Link.Field.725150_TMY3.epw'
  elsif hpxml_file.include?('CZ6_ND_Bismarck')
    hpxml.climate_and_risk_zones.climate_zone_ieccs[0].zone = '6A'
    hpxml.climate_and_risk_zones.weather_station_name = 'Bismarck'
    hpxml.climate_and_risk_zones.weather_station_epw_filepath = 'USA_ND_Bismarck.Muni.AP.727640_TMY3.epw'
  elsif hpxml_file.include?('CZ6_PA_Bradford')
    hpxml.climate_and_risk_zones.climate_zone_ieccs[0].zone = '6A'
    hpxml.climate_and_risk_zones.weather_station_name = 'Bradford'
    hpxml.climate_and_risk_zones.weather_station_epw_filepath = 'USA_PA_Bradford.Rgnl.AP.725266_TMY3.epw'
  elsif hpxml_file.include?('CZ6_VT_Burlington')
    hpxml.climate_and_risk_zones.climate_zone_ieccs[0].zone = '6A'
    hpxml.climate_and_risk_zones.weather_station_name = 'Burlington'
    hpxml.climate_and_risk_zones.weather_station_epw_filepath = 'USA_VT_Burlington.Intl.AP.726170_TMY3.epw'
  elsif hpxml_file.include?('CZ6_WY_Cheyenne')
    hpxml.climate_and_risk_zones.climate_zone_ieccs[0].zone = '6A'
    hpxml.climate_and_risk_zones.weather_station_name = 'Cheyenne'
    hpxml.climate_and_risk_zones.weather_station_epw_filepath = 'USA_WY_Cheyenne.Muni.AP.725640_TMY3.epw'
  elsif hpxml_file.include?('CZ6_NH_Concord')
    hpxml.climate_and_risk_zones.climate_zone_ieccs[0].zone = '6A'
    hpxml.climate_and_risk_zones.weather_station_name = 'Concord'
    hpxml.climate_and_risk_zones.weather_station_epw_filepath = 'USA_NH_Concord.Muni.AP.726050_TMY3.epw'
  elsif hpxml_file.include?('CZ6_CO_Eagle')
    hpxml.climate_and_risk_zones.climate_zone_ieccs[0].zone = '6A'
    hpxml.climate_and_risk_zones.weather_station_name = 'Eagle'
    hpxml.climate_and_risk_zones.weather_station_epw_filepath = 'USA_CO_Eagle.County.Rgnl.AP.724675_TMY3.epw'
  elsif hpxml_file.include?('CZ6_CA_Eagle')
    hpxml.climate_and_risk_zones.climate_zone_ieccs[0].zone = '6A'
    hpxml.climate_and_risk_zones.weather_station_name = 'Eagle'
    hpxml.climate_and_risk_zones.weather_station_epw_filepath = 'USA_CO_Eagle.County.Rgnl.AP.724675_TMY3.epw'
  elsif hpxml_file.include?('CZ6_MT_Helena')
    hpxml.climate_and_risk_zones.climate_zone_ieccs[0].zone = '6A'
    hpxml.climate_and_risk_zones.weather_station_name = 'Helena'
    hpxml.climate_and_risk_zones.weather_station_epw_filepath = 'USA_MT_Helena.Rgnl.AP.727720_TMY3.epw'
  elsif hpxml_file.include?('CZ6_WA_Kalispell-Glacier')
    hpxml.climate_and_risk_zones.climate_zone_ieccs[0].zone = '6A'
    hpxml.climate_and_risk_zones.weather_station_name = 'Kalispell-Glacier'
    hpxml.climate_and_risk_zones.weather_station_epw_filepath = 'USA_MT_Kalispell-Glacier.Park.Intl.AP.727790_TMY3.epw'
  elsif hpxml_file.include?('CZ6_WI_Madison-Dane')
    hpxml.climate_and_risk_zones.climate_zone_ieccs[0].zone = '6A'
    hpxml.climate_and_risk_zones.weather_station_name = 'Madison-Dane'
    hpxml.climate_and_risk_zones.weather_station_epw_filepath = 'USA_WI_Madison-Dane.County.Rgnl.AP.726410_TMY3.epw'
  elsif hpxml_file.include?('CZ6_IA_Mason')
    hpxml.climate_and_risk_zones.climate_zone_ieccs[0].zone = '6A'
    hpxml.climate_and_risk_zones.weather_station_name = 'Mason'
    hpxml.climate_and_risk_zones.weather_station_epw_filepath = 'USA_IA_Mason.City.Muni.AP.725485_TMY3.epw'
  elsif hpxml_file.include?('CZ6_MN_Minneapolis-St')
    hpxml.climate_and_risk_zones.climate_zone_ieccs[0].zone = '6A'
    hpxml.climate_and_risk_zones.weather_station_name = 'Minneapolis-St'
    hpxml.climate_and_risk_zones.weather_station_epw_filepath = 'USA_MN_Minneapolis-St.Paul.Intl.AP.726580_TMY3.epw'
  elsif hpxml_file.include?('CZ6_SD_Pierre')
    hpxml.climate_and_risk_zones.climate_zone_ieccs[0].zone = '6A'
    hpxml.climate_and_risk_zones.weather_station_name = 'Pierre'
    hpxml.climate_and_risk_zones.weather_station_epw_filepath = 'USA_SD_Pierre.Muni.AP.726686_TMY3.epw'
  elsif hpxml_file.include?('CZ6_ID_Pocatello')
    hpxml.climate_and_risk_zones.climate_zone_ieccs[0].zone = '6A'
    hpxml.climate_and_risk_zones.weather_station_name = 'Pocatello'
    hpxml.climate_and_risk_zones.weather_station_epw_filepath = 'USA_ID_Pocatello.Muni.AP.725780_TMY3.epw'
  elsif hpxml_file.include?('CZ6_ME_Portland')
    hpxml.climate_and_risk_zones.climate_zone_ieccs[0].zone = '6A'
    hpxml.climate_and_risk_zones.weather_station_name = 'Portland'
    hpxml.climate_and_risk_zones.weather_station_epw_filepath = 'USA_ME_Portland.Intl.Jetport.726060_TMY3.epw'
  elsif hpxml_file.include?('CZ6_UT_Vernal')
    hpxml.climate_and_risk_zones.climate_zone_ieccs[0].zone = '6A'
    hpxml.climate_and_risk_zones.weather_station_name = 'Vernal'
    hpxml.climate_and_risk_zones.weather_station_epw_filepath = 'USA_UT_Vernal.AP.725705_TMY3.epw'
  elsif hpxml_file.include?('CZ7_AK_Anchorage')
    hpxml.climate_and_risk_zones.climate_zone_ieccs[0].zone = '7'
    hpxml.climate_and_risk_zones.weather_station_name = 'Anchorage'
    hpxml.climate_and_risk_zones.weather_station_epw_filepath = 'USA_AK_Anchorage.Intl.AP.702730_TMY3.epw'
  elsif hpxml_file.include?('CZ7_ME_Caribou')
    hpxml.climate_and_risk_zones.climate_zone_ieccs[0].zone = '7'
    hpxml.climate_and_risk_zones.weather_station_name = 'Caribou'
    hpxml.climate_and_risk_zones.weather_station_epw_filepath = 'USA_ME_Caribou.Muni.AP.727120_TMY3.epw'
  elsif hpxml_file.include?('CZ7_MN_Duluth')
    hpxml.climate_and_risk_zones.climate_zone_ieccs[0].zone = '7'
    hpxml.climate_and_risk_zones.weather_station_name = 'Duluth'
    hpxml.climate_and_risk_zones.weather_station_epw_filepath = 'USA_MN_Duluth.Intl.AP.727450_TMY3.epw'
  elsif hpxml_file.include?('CZ7_WI_Duluth')
    hpxml.climate_and_risk_zones.climate_zone_ieccs[0].zone = '7'
    hpxml.climate_and_risk_zones.weather_station_name = 'Duluth'
    hpxml.climate_and_risk_zones.weather_station_epw_filepath = 'USA_MN_Duluth.Intl.AP.727450_TMY3.epw'
  elsif hpxml_file.include?('CZ7_CO_Gunnison')
    hpxml.climate_and_risk_zones.climate_zone_ieccs[0].zone = '7'
    hpxml.climate_and_risk_zones.weather_station_name = 'Gunnison'
    hpxml.climate_and_risk_zones.weather_station_epw_filepath = 'USA_CO_Gunnison.County.AWOS.724677_TMY3.epw'
  elsif hpxml_file.include?('CZ7_WY_Jackson')
    hpxml.climate_and_risk_zones.climate_zone_ieccs[0].zone = '7'
    hpxml.climate_and_risk_zones.weather_station_name = 'Jackson'
    hpxml.climate_and_risk_zones.weather_station_epw_filepath = 'USA_WY_Jackson.Hole.AP.725776_TMY3.epw'
  elsif hpxml_file.include?('CZ7_ND_Minot')
    hpxml.climate_and_risk_zones.climate_zone_ieccs[0].zone = '7'
    hpxml.climate_and_risk_zones.weather_station_name = 'Minot'
    hpxml.climate_and_risk_zones.weather_station_epw_filepath = 'USA_ND_Minot.AFB.727675_TMY3.epw'
  elsif hpxml_file.include?('CZ7_MI_Sault')
    hpxml.climate_and_risk_zones.climate_zone_ieccs[0].zone = '7'
    hpxml.climate_and_risk_zones.weather_station_name = 'Sault'
    hpxml.climate_and_risk_zones.weather_station_epw_filepath = 'USA_MI_Sault.Ste.Marie-Sanderson.Field.727340_TMY3.epw'
  elsif hpxml_file.include?('CZ8_AK_Fairbanks')
    hpxml.climate_and_risk_zones.climate_zone_ieccs[0].zone = '8'
    hpxml.climate_and_risk_zones.weather_station_name = 'Fairbanks'
    hpxml.climate_and_risk_zones.weather_station_epw_filepath = 'USA_AK_Fairbanks.Intl.AP.702610_TMY3.epw'

  end
end

def set_hpxml_air_infiltration_measurements(hpxml_file, hpxml)
  if hpxml_file.include?('EnergyStar')
    if hpxml_file.include?('CZ1') || hpxml_file.include?('CZ2')
      ach50 = 3
    elsif hpxml_file.include?('CZ3') || hpxml_file.include?('CZ4_') || hpxml_file.include?('CZ4C_') || hpxml_file.include?('CZ5') || hpxml_file.include?('CZ6')
      ach50 = 3
    elsif hpxml_file.include?('CZ7') || hpxml_file.include?('CZ8')
      ach50 = 3
    end
  elsif hpxml_file.include?('2021IECC')
    if hpxml_file.include?('CZ1') || hpxml_file.include?('CZ2')
      ach50 = 5
    elsif hpxml_file.include?('CZ3') || hpxml_file.include?('CZ4_') || hpxml_file.include?('CZ4C_') || hpxml_file.include?('CZ5') || hpxml_file.include?('CZ6')
      ach50 = 3
    elsif hpxml_file.include?('CZ7') || hpxml_file.include?('CZ8')
      ach50 = 3
    end
  end
  hpxml.air_infiltration_measurements.clear
  hpxml.air_infiltration_measurements.add(id: 'InfiltrationMeasurement',
                                          unit_of_measure: HPXML::UnitsACH,
                                          house_pressure: 50,
                                          air_leakage: ach50,
                                          infiltration_volume: hpxml.building_construction.conditioned_building_volume)
end

def set_hpxml_attics(hpxml_file, hpxml)
  if ['EnergyStar', '2021IECC'].any? { |program| hpxml_file.include? program }
    hpxml.attics.clear
    hpxml.attics.add(id: 'VentedAttic',
                     attic_type: HPXML::AtticTypeVented,
                     vented_attic_sla: (1.0 / 300.0).round(6))
  end
end

def set_hpxml_foundations(hpxml_file, hpxml) # not available in the spreadsheet
  if ['EnergyStar', '2021IECC'].any? { |program| hpxml_file.include? program }
    if hpxml_file.include?('vented_crawl')
      hpxml.foundations.clear
      hpxml.foundations.add(id: 'VentedCrawlspace',
                            foundation_type: HPXML::FoundationTypeCrawlspaceVented,
                            vented_crawlspace_sla: (1.0 / 150.0).round(6))
    end
    if hpxml_file.include?('uncond_bsmt')
      hpxml.foundations.clear
      hpxml.foundations.add(id: 'unconditionedBasement',
                            foundation_type: HPXML::FoundationTypeBasementUnconditioned,
                            within_infiltration_volume: false)
    end
  end
end

def set_hpxml_roofs(hpxml_file, hpxml)
  if ['EnergyStar', '2021IECC'].any? { |program| hpxml_file.include? program }
    rb_grade = nil
    area = 1485
    insulation_assembly_r_value = (1 / 0.502).round(3)
    hpxml.roofs.clear
    hpxml.roofs.add(id: 'Roof',
                    interior_adjacent_to: HPXML::LocationAtticVented,
                    area: area,
                    solar_absorptance: 0.92,
                    emittance: 0.9,
                    pitch: 9,
                    radiant_barrier: !rb_grade.nil?,
                    radiant_barrier_grade: rb_grade,
                    insulation_assembly_r_value: insulation_assembly_r_value)
  end
end

def set_hpxml_rim_joists(hpxml_file, hpxml)
  if hpxml_file.include?('EnergyStar')
    if hpxml_file.include?('CZ1') || hpxml_file.include?('CZ2')
      assembly_r = 13.0000.round(3)
    end
    if hpxml_file.include?('CZ3')
      assembly_r = 20.0000.round(3)
    end
    if hpxml_file.include?('CZ4_') || hpxml_file.include?('CZ4C_') || hpxml_file.include?('CZ5') || hpxml_file.include?('CZ6') || hpxml_file.include?('CZ7') || hpxml_file.include?('CZ8')
      assembly_r = 25.0000.round(3)
    end
    hpxml.rim_joists.clear
    hpxml.rim_joists.add(id: 'RimJoist',
                         exterior_adjacent_to: HPXML::LocationOutside,
                         interior_adjacent_to: HPXML::LocationLivingSpace,
                         area: 152,
                         solar_absorptance: 0.75,
                         emittance: 0.9,
                         insulation_assembly_r_value: assembly_r)

    if hpxml_file.include?('_cond_bsmt')
      interior_adjacent_to = HPXML::LocationBasementConditioned
      if hpxml_file.include?('CZ1') || hpxml_file.include?('CZ2')
        assembly_r = 13.0000.round(3)
      elsif hpxml_file.include?('CZ3')
        assembly_r = 20.0000.round(3)
      elsif hpxml_file.include?('CZ4_') || hpxml_file.include?('CZ4C_') || hpxml_file.include?('CZ5') || hpxml_file.include?('CZ6') || hpxml_file.include?('CZ7') || hpxml_file.include?('CZ8')
        assembly_r = 25.0000.round(3)
      end

    elsif hpxml_file.include?('vented_crawl')
      interior_adjacent_to = HPXML::LocationCrawlspaceVented
      if hpxml_file.include?('CZ1') || hpxml_file.include?('CZ2')
        assembly_r = 13.0000.round(3)
      elsif hpxml_file.include?('CZ3')
        assembly_r = 20.0000.round(3)
      elsif hpxml_file.include?('CZ4_') || hpxml_file.include?('CZ4C_') || hpxml_file.include?('CZ5') || hpxml_file.include?('CZ6') || hpxml_file.include?('CZ7') || hpxml_file.include?('CZ8')
        assembly_r = 25.0000.round(3)
      end

    elsif hpxml_file.include?('uncond_bsmt')
      interior_adjacent_to = HPXML::LocationBasementUnconditioned
      if hpxml_file.include?('CZ1') || hpxml_file.include?('CZ2')
        assembly_r = 13.0000.round(3)
      elsif hpxml_file.include?('CZ3')
        assembly_r = 20.0000.round(3)
      elsif hpxml_file.include?('CZ4_') || hpxml_file.include?('CZ4C_') || hpxml_file.include?('CZ5') || hpxml_file.include?('CZ6') || hpxml_file.include?('CZ7') || hpxml_file.include?('CZ8')
        assembly_r = 25.0000.round(3)
      end
    elsif hpxml_file.include?('slab')
      interior_adjacent_to = nil
    end
    if not interior_adjacent_to.nil?
      hpxml.rim_joists.add(id: 'RimJoistFoundation',
                           exterior_adjacent_to: HPXML::LocationOutside,
                           interior_adjacent_to: interior_adjacent_to,
                           area: 152,
                           solar_absorptance: 0.75,
                           emittance: 0.9,
                           insulation_assembly_r_value: assembly_r)
    end
  elsif hpxml_file.include?('2021IECC')
    if hpxml_file.include?('CZ1') || hpxml_file.include?('CZ2') || hpxml_file.include?('CZ3')
      assembly_r = 13.0000.round(3)
    end
    if hpxml_file.include?('CZ4_') || hpxml_file.include?('CZ4C_') || hpxml_file.include?('CZ5') || hpxml_file.include?('CZ6') || hpxml_file.include?('CZ7') || hpxml_file.include?('CZ8')
      assembly_r = 25.0000.round(3)
    end
    hpxml.rim_joists.clear
    hpxml.rim_joists.add(id: 'RimJoist',
                         exterior_adjacent_to: HPXML::LocationOutside,
                         interior_adjacent_to: HPXML::LocationLivingSpace,
                         area: 152,
                         solar_absorptance: 0.75,
                         emittance: 0.9,
                         insulation_assembly_r_value: assembly_r)
    if hpxml_file.include?('_cond_bsmt')
      interior_adjacent_to = HPXML::LocationBasementConditioned
      if hpxml_file.include?('CZ1') || hpxml_file.include?('CZ2') || hpxml_file.include?('CZ3')
        assembly_r = 13.0000.round(3)
      elsif hpxml_file.include?('CZ4_') || hpxml_file.include?('CZ4C_') || hpxml_file.include?('CZ5') || hpxml_file.include?('CZ6') || hpxml_file.include?('CZ7') || hpxml_file.include?('CZ8')
        assembly_r = 25.0000.round(3)
      end
    elsif hpxml_file.include?('vented_crawl')
      interior_adjacent_to = HPXML::LocationCrawlspaceVented
      if hpxml_file.include?('CZ1') || hpxml_file.include?('CZ2') || hpxml_file.include?('CZ3')
        assembly_r = 13.0000.round(3)
      elsif hpxml_file.include?('CZ4_') || hpxml_file.include?('CZ4C_') || hpxml_file.include?('CZ5') || hpxml_file.include?('CZ6') || hpxml_file.include?('CZ7') || hpxml_file.include?('CZ8')
        assembly_r = 25.0000.round(3)
      end
    elsif hpxml_file.include?('uncond_bsmt')
      interior_adjacent_to = HPXML::LocationBasementUnconditioned
      if hpxml_file.include?('CZ1') || hpxml_file.include?('CZ2') || hpxml_file.include?('CZ3')
        assembly_r = 13.0000.round(3)
      elsif hpxml_file.include?('CZ4_') || hpxml_file.include?('CZ4C_') || hpxml_file.include?('CZ5') || hpxml_file.include?('CZ6') || hpxml_file.include?('CZ7') || hpxml_file.include?('CZ8')
        assembly_r = 25.0000.round(3)
      end
    elsif hpxml_file.include?('slab')
      interior_adjacent_to = nil
    end
    if not interior_adjacent_to.nil?
      hpxml.rim_joists.add(id: 'RimJoistFoundation',
                           exterior_adjacent_to: HPXML::LocationOutside,
                           interior_adjacent_to: interior_adjacent_to,
                           area: 152,
                           solar_absorptance: 0.75,
                           emittance: 0.9,
                           insulation_assembly_r_value: assembly_r)
    end
  end
end

def set_hpxml_walls(hpxml_file, hpxml)
  if hpxml_file.include?('EnergyStar')
    if hpxml_file.include?('CZ1') || hpxml_file.include?('CZ2')
      assembly_r = (1 / 0.07958).round(3)
    end
    if hpxml_file.include?('CZ3')
      assembly_r = (1 / 0.056106).round(3)
    end
    if hpxml_file.include?('CZ4_') || hpxml_file.include?('CZ4C_') || hpxml_file.include?('CZ5') || hpxml_file.include?('CZ6') || hpxml_file.include?('CZ7') || hpxml_file.include?('CZ8')
      assembly_r = (1 / 0.043909).round(3)
    end
    hpxml.walls.clear
    hpxml.walls.add(id: 'Wall',
                    exterior_adjacent_to: HPXML::LocationOutside,
                    interior_adjacent_to: HPXML::LocationLivingSpace,
                    wall_type: HPXML::WallTypeWoodStud,
                    area: 2584,
                    solar_absorptance: 0.75,
                    emittance: 0.9,
                    insulation_assembly_r_value: assembly_r)
  elsif hpxml_file.include?('2021IECC')
    if hpxml_file.include?('CZ1') || hpxml_file.include?('CZ2')
      assembly_r = (1 / 0.09925).round(3)
    end
    if hpxml_file.include?('CZ3')
      assembly_r = (1 / 0.076044).round(3)
    end
    if hpxml_file.include?('CZ4_') || hpxml_file.include?('CZ4C_') || hpxml_file.include?('CZ5') || hpxml_file.include?('CZ6') || hpxml_file.include?('CZ7') || hpxml_file.include?('CZ8')
      assembly_r = (1 / 0.048725).round(3)
    end
    hpxml.walls.clear
    hpxml.walls.add(id: 'Wall',
                    exterior_adjacent_to: HPXML::LocationOutside,
                    interior_adjacent_to: HPXML::LocationLivingSpace,
                    wall_type: HPXML::WallTypeWoodStud,
                    area: 2584,
                    solar_absorptance: 0.75,
                    emittance: 0.9,
                    insulation_assembly_r_value: assembly_r)
  end
end

def set_hpxml_foundation_walls(hpxml_file, hpxml) # not available in IECC spreadsheet
  if hpxml_file.include?('EnergyStar')
    perimeter = 1216 / 8
    if hpxml_file.include?('vented_crawl')
      hpxml.foundation_walls.clear
      assembly_r = 2.604
      hpxml.foundation_walls.add(id: 'FoundationWall',
                                 exterior_adjacent_to: HPXML::LocationGround,
                                 interior_adjacent_to: HPXML::LocationCrawlspaceVented,
                                 height: 4.0,
                                 area: perimeter * 4.0,
                                 thickness: 8,
                                 depth_below_grade: 2.0,
                                 insulation_assembly_r_value: assembly_r,)
    elsif hpxml_file.include?('_cond_bsmt')
      if hpxml_file.include?('CZ1') || hpxml_file.include?('CZ2')
        assembly_r = 2.604
      end
      if hpxml_file.include?('CZ3') || hpxml_file.include?('CZ4_')
        assembly_r = (1.0 / 0.096).round(3)
      end
      if hpxml_file.include?('CZ5') || hpxml_file.include?('CZ4C_') || hpxml_file.include?('CZ6') || hpxml_file.include?('CZ7') || hpxml_file.include?('CZ8')
        assembly_r = (1.0 / 0.083).round(3)
      end
      hpxml.foundation_walls.clear
      hpxml.foundation_walls.add(id: 'FoundationWall',
                                 exterior_adjacent_to: HPXML::LocationGround,
                                 interior_adjacent_to: HPXML::LocationBasementConditioned,
                                 height: 8.0,
                                 area: perimeter * 8.0,
                                 thickness: 8,
                                 depth_below_grade: 8.0,
                                 insulation_assembly_r_value: assembly_r,)
    elsif hpxml_file.include?('uncond_bsmt')
      hpxml.foundation_walls.clear
      assembly_r = 2.604
      hpxml.foundation_walls.add(id: 'FoundationWall',
                                 exterior_adjacent_to: HPXML::LocationGround,
                                 interior_adjacent_to: HPXML::LocationBasementUnconditioned,
                                 height: 8.0,
                                 area: perimeter * 8.0,
                                 thickness: 8,
                                 depth_below_grade: 6.0,
                                 insulation_assembly_r_value: assembly_r)
    end
  elsif hpxml_file.include?('2021IECC')
    perimeter = 1216 / 8
    if hpxml_file.include?('vented_crawl')
      hpxml.foundation_walls.clear
      assembly_r = 2.604
      hpxml.foundation_walls.add(id: 'FoundationWall',
                                 exterior_adjacent_to: HPXML::LocationGround,
                                 interior_adjacent_to: HPXML::LocationCrawlspaceVented,
                                 height: 4.0,
                                 area: perimeter * 4.0,
                                 thickness: 8,
                                 depth_below_grade: 2.0,
                                 insulation_interior_r_value: 0,
                                 insulation_interior_distance_to_top: 0,
                                 insulation_interior_distance_to_bottom: 0,
                                 insulation_exterior_r_value: 0,
                                 insulation_exterior_distance_to_top: 0,
                                 insulation_exterior_distance_to_bottom: 0)
    elsif hpxml_file.include?('_cond_bsmt')
      if hpxml_file.include?('CZ1') || hpxml_file.include?('CZ2')
        assembly_r = 2.604
      end
      if hpxml_file.include?('CZ3') || hpxml_file.include?('CZ4_')
        assembly_r = (1.0 / 0.09625).round(3)
      end
      if hpxml_file.include?('CZ5') || hpxml_file.include?('CZ4C_') || hpxml_file.include?('CZ6') || hpxml_file.include?('CZ7') || hpxml_file.include?('CZ8')
        assembly_r = (1.0 / 0.082769).round(3)
      end
      hpxml.foundation_walls.clear
      hpxml.foundation_walls.add(id: 'FoundationWall',
                                 exterior_adjacent_to: HPXML::LocationGround,
                                 interior_adjacent_to: HPXML::LocationBasementConditioned,
                                 height: 8.0,
                                 area: perimeter * 8.0,
                                 thickness: 8,
                                 depth_below_grade: 6.0,
                                 insulation_assembly_r_value: assembly_r)
    elsif hpxml_file.include?('uncond_bsmt')
      hpxml.foundation_walls.clear
      if hpxml_file.include?('CZ1') || hpxml_file.include?('CZ2')
        assembly_r = 0
      end
      if hpxml_file.include?('CZ3') || hpxml_file.include?('CZ4_')
        assembly_r = (1.0 / 0.09625).round(3)
      end
      if hpxml_file.include?('CZ5') || hpxml_file.include?('CZ4C_') || hpxml_file.include?('CZ6')
        assembly_r = (1.0 / 0.082769).round(3)
      end
      hpxml.foundation_walls.add(id: 'FoundationWall',
                                 exterior_adjacent_to: HPXML::LocationGround,
                                 interior_adjacent_to: HPXML::LocationBasementUnconditioned,
                                 height: 8.0,
                                 area: perimeter * 8.0,
                                 thickness: 8,
                                 depth_below_grade: 6.0,
                                 insulation_interior_r_value: 0,
                                 insulation_interior_distance_to_top: 0,
                                 insulation_interior_distance_to_bottom: 0,
                                 insulation_exterior_r_value: 0,
                                 insulation_exterior_distance_to_top: 0,
                                 insulation_exterior_distance_to_bottom: 0)
    end
  end
end

def set_hpxml_floors(hpxml_file, hpxml) # to
  if hpxml_file.include?('EnergyStar')
    # Ceiling
    area = 1188
    exterior_adjacent_to = HPXML::LocationAtticVented
    if hpxml_file.include?('CZ1')
      ceiling_assembly_r = 28.4259
    end
    if hpxml_file.include?('CZ2') || hpxml_file.include?('CZ3')
      ceiling_assembly_r = 38.7714
    end
    if hpxml_file.include?('CZ4_') || hpxml_file.include?('CZ4C_') || hpxml_file.include?('CZ5') || hpxml_file.include?('CZ6') || hpxml_file.include?('CZ7') || hpxml_file.include?('CZ8')
      ceiling_assembly_r = 42.4869
    end

    hpxml.floors.add(id: 'Ceiling',
                     exterior_adjacent_to: exterior_adjacent_to,
                     interior_adjacent_to: HPXML::LocationLivingSpace,
                     area: area,
                     insulation_assembly_r_value: ceiling_assembly_r)
    # Floor
    if hpxml_file.include?('vented_crawl')
      if hpxml_file.include?('CZ1') || hpxml_file.include?('CZ2')
        floor_assembly_r = 14.9053
      end
      if hpxml_file.include?('CZ3') || hpxml_file.include?('CZ4_')
        floor_assembly_r = 20.0274
      end
      if hpxml_file.include?('CZ5') || hpxml_file.include?('CZ4C_') || hpxml_file.include?('CZ6')
        floor_assembly_r = 28.9517
      end
      if hpxml_file.include?('CZ7') || hpxml_file.include?('CZ8')
        floor_assembly_r = 33.8454
      end
      hpxml.floors.add(id: 'Floor',
                       exterior_adjacent_to: HPXML::LocationCrawlspaceVented,
                       interior_adjacent_to: HPXML::LocationLivingSpace,
                       area: area,
                       insulation_assembly_r_value: floor_assembly_r)
    elsif hpxml_file.include?('uncond_bsmt')
      if hpxml_file.include?('CZ1') || hpxml_file.include?('CZ2')
        floor_assembly_r = 14.9053
      end
      if hpxml_file.include?('CZ3') || hpxml_file.include?('CZ4_')
        floor_assembly_r = 20.0274
      end
      if hpxml_file.include?('CZ5') || hpxml_file.include?('CZ4C_') || hpxml_file.include?('CZ6')
        floor_assembly_r = 28.9517
      end
      if hpxml_file.include?('CZ7') || hpxml_file.include?('CZ8')
        floor_assembly_r = 33.8454
      end
      hpxml.floors.add(id: 'Floor',
                             exterior_adjacent_to: HPXML::LocationBasementUnconditioned,
                             interior_adjacent_to: HPXML::LocationLivingSpace,
                             area: area,
                             insulation_assembly_r_value: floor_assembly_r)
    end
  elsif hpxml_file.include?('2021IECC')
    # Ceiling
    area = 1188
    exterior_adjacent_to = HPXML::LocationAtticVented
    if hpxml_file.include?('CZ1')
      ceiling_assembly_r = (1.0 / 0.0356106).round(3)
    end
    if hpxml_file.include?('CZ2') || hpxml_file.include?('CZ3')
      ceiling_assembly_r = (1.0 / 0.026125).round(3)
    end
    if hpxml_file.include?('CZ4_') || hpxml_file.include?('CZ4C_') || hpxml_file.include?('CZ5') || hpxml_file.include?('CZ6') || hpxml_file.include?('CZ7') || hpxml_file.include?('CZ8')
      ceiling_assembly_r = (1.0 / 0.023859).round(3)
    end
    hpxml.floors.add(id: 'Ceiling',
                     exterior_adjacent_to: exterior_adjacent_to,
                     interior_adjacent_to: HPXML::LocationLivingSpace,
                     area: area,
                     insulation_assembly_r_value: ceiling_assembly_r)
    # Floor
    if hpxml_file.include?('vented_crawl')
      if hpxml_file.include?('CZ1') || hpxml_file.include?('CZ2')
        floor_assembly_r = (1.0 / 0.0720).round(3)
      end
      if hpxml_file.include?('CZ3') || hpxml_file.include?('CZ4_')
        floor_assembly_r = (1.0 / 0.054686).round(3)
      end
      if hpxml_file.include?('CZ5') || hpxml_file.include?('CZ4C_') || hpxml_file.include?('CZ6')
        floor_assembly_r = (1.0 / 0.0395858).round(3)
      end
      if hpxml_file.include?('CZ7') || hpxml_file.include?('CZ8')
        floor_assembly_r = (1.0 / 0.034706).round(3)
      end
      hpxml.floors.add(id: 'Floor',
                       exterior_adjacent_to: HPXML::LocationCrawlspaceVented,
                       interior_adjacent_to: HPXML::LocationLivingSpace,
                       area: area,
                       insulation_assembly_r_value: floor_assembly_r)
    elsif hpxml_file.include?('uncond_bsmt')
      if hpxml_file.include?('CZ1') || hpxml_file.include?('CZ2')
        floor_assembly_r = (1.0 / 0.07152).round(3)
      end
      if hpxml_file.include?('CZ3') || hpxml_file.include?('CZ4_')
        floor_assembly_r = (1.0 / 0.054686).round(3)
      end
      if hpxml_file.include?('CZ5') || hpxml_file.include?('CZ4C_') || hpxml_file.include?('CZ6')
        floor_assembly_r = (1.0 / 0.0395858).round(3)
      end
      if hpxml_file.include?('CZ7') || hpxml_file.include?('CZ8')
        floor_assembly_r = (1.0 / 0.034706).round(3)
      end
      hpxml.floors.add(id: 'Floor',
                       exterior_adjacent_to: HPXML::LocationBasementUnconditioned,
                       interior_adjacent_to: HPXML::LocationLivingSpace,
                       area: area,
                       insulation_assembly_r_value: floor_assembly_r)
    end
  end
end

def set_hpxml_slabs(hpxml_file, hpxml)
  if hpxml_file.include?('EnergyStar')
    exposed_perimeter = 152
    area = 1188
    if hpxml_file.include?('slab')
      interior_adjacent_to = HPXML::LocationLivingSpace
      depth_below_grade = 0
      carpet_fraction = 0.8
      thickness = 4
      name = 'Slab'
      carpet_r_value = 1.23
      if hpxml_file.include?('CZ1') || hpxml_file.include?('CZ2')
        perimeter_insulation_depth = 0
        perimeter_insulation_r = 0
      end
      if hpxml_file.include?('CZ3')
        perimeter_insulation_depth = 2
        perimeter_insulation_r = 10
      end
      if hpxml_file.include?('CZ4_') || hpxml_file.include?('CZ4C_') || hpxml_file.include?('CZ5') || hpxml_file.include?('CZ6') || hpxml_file.include?('CZ7') || hpxml_file.include?('CZ8')
        perimeter_insulation_depth = 4
        perimeter_insulation_r = 10
      end
    elsif hpxml_file.include?('vented_crawl')
      interior_adjacent_to = HPXML::LocationCrawlspaceVented
      depth_below_grade = nil
      carpet_fraction = 0.0
      thickness = 0
      name = 'DirtFloor'
      carpet_r_value = 0
      if hpxml_file.include?('CZ1') || hpxml_file.include?('CZ2')
        perimeter_insulation_depth = 0
        perimeter_insulation_r = 0
      end
      if hpxml_file.include?('CZ3')
        perimeter_insulation_depth = 0
        perimeter_insulation_r = 0
      end
      if hpxml_file.include?('CZ4_') || hpxml_file.include?('CZ4C_') || hpxml_file.include?('CZ5') || hpxml_file.include?('CZ6') || hpxml_file.include?('CZ7') || hpxml_file.include?('CZ8')
        perimeter_insulation_depth = 0
        perimeter_insulation_r = 0
      end
    elsif hpxml_file.include?('_cond_bsmt')
      interior_adjacent_to = HPXML::LocationBasementConditioned
      depth_below_grade = nil
      carpet_fraction = 0.8
      thickness = 4
      name = 'Slab'
      carpet_r_value = 1.23
      if hpxml_file.include?('CZ1') || hpxml_file.include?('CZ2')
        perimeter_insulation_depth = 0
        perimeter_insulation_r = 0
      end
      if hpxml_file.include?('CZ3')
        perimeter_insulation_depth = 2
        perimeter_insulation_r = 10
      end
      if hpxml_file.include?('CZ4_') || hpxml_file.include?('CZ4C_') || hpxml_file.include?('CZ5') || hpxml_file.include?('CZ6') || hpxml_file.include?('CZ7') || hpxml_file.include?('CZ8')
        perimeter_insulation_depth = 4
        perimeter_insulation_r = 10
      end
    elsif hpxml_file.include?('uncond_bsmt')
      interior_adjacent_to = HPXML::LocationBasementUnconditioned
      depth_below_grade = nil
      carpet_fraction = 0.0
      thickness = 4
      name = 'Slab'
      carpet_r_value = 0
      if hpxml_file.include?('CZ1') || hpxml_file.include?('CZ2')
        perimeter_insulation_depth = 0
        perimeter_insulation_r = 0
      end
      if hpxml_file.include?('CZ3')
        perimeter_insulation_depth = 0
        perimeter_insulation_r = 0
      end
      if hpxml_file.include?('CZ4_') || hpxml_file.include?('CZ4C_') || hpxml_file.include?('CZ5') || hpxml_file.include?('CZ6') || hpxml_file.include?('CZ7') || hpxml_file.include?('CZ8')
        perimeter_insulation_depth = 0
        perimeter_insulation_r = 0
      end
    else
      return
    end
    hpxml.slabs.clear
    hpxml.slabs.add(id: name,
                    interior_adjacent_to: interior_adjacent_to,
                    depth_below_grade: depth_below_grade,
                    area: area,
                    thickness: thickness,
                    exposed_perimeter: exposed_perimeter,
                    perimeter_insulation_depth: perimeter_insulation_depth,
                    under_slab_insulation_width: 0,
                    under_slab_insulation_spans_entire_slab: nil,
                    perimeter_insulation_r_value: perimeter_insulation_r,
                    under_slab_insulation_r_value: 0,
                    carpet_fraction: carpet_fraction,
                    carpet_r_value: carpet_r_value) # updated
  elsif hpxml_file.include?('2021IECC')
    exposed_perimeter = 152
    area = 1188
    if hpxml_file.include?('slab')
      interior_adjacent_to = HPXML::LocationLivingSpace
      depth_below_grade = 0
      carpet_fraction = 0.8
      thickness = 4
      name = 'Slab'
      carpet_r_value = 1.23
      if hpxml_file.include?('CZ1') || hpxml_file.include?('CZ2')
        perimeter_insulation_depth = 0
        perimeter_insulation_r = 0
      end
      if hpxml_file.include?('CZ3')
        perimeter_insulation_depth = 2
        perimeter_insulation_r = 10
      end
      if hpxml_file.include?('CZ4_') || hpxml_file.include?('CZ4C_') || hpxml_file.include?('CZ5') || hpxml_file.include?('CZ6') || hpxml_file.include?('CZ7') || hpxml_file.include?('CZ8')
        perimeter_insulation_depth = 4
        perimeter_insulation_r = 10
      end
    elsif hpxml_file.include?('vented_crawl')
      interior_adjacent_to = HPXML::LocationCrawlspaceVented
      depth_below_grade = nil
      carpet_fraction = 0.0
      thickness = 0
      name = 'DirtFloor'
      carpet_r_value = 0
      if hpxml_file.include?('CZ1') || hpxml_file.include?('CZ2')
        perimeter_insulation_depth = 0
        perimeter_insulation_r = 0
      end
      if hpxml_file.include?('CZ3')
        perimeter_insulation_depth = 0
        perimeter_insulation_r = 0
      end
      if hpxml_file.include?('CZ4_') || hpxml_file.include?('CZ4C_') || hpxml_file.include?('CZ5') || hpxml_file.include?('CZ6') || hpxml_file.include?('CZ7') || hpxml_file.include?('CZ8')
        perimeter_insulation_depth = 0
        perimeter_insulation_r = 0
      end
    elsif hpxml_file.include?('_cond_bsmt')
      interior_adjacent_to = HPXML::LocationBasementConditioned
      depth_below_grade = nil
      carpet_fraction = 0.8
      thickness = 4
      name = 'Slab'
      carpet_r_value = 1.23
      if hpxml_file.include?('CZ1') || hpxml_file.include?('CZ2')
        perimeter_insulation_depth = 0
        perimeter_insulation_r = 0
      end
      if hpxml_file.include?('CZ3')
        perimeter_insulation_depth = 2
        perimeter_insulation_r = 10
      end
      if hpxml_file.include?('CZ4_') || hpxml_file.include?('CZ4C_') || hpxml_file.include?('CZ5') || hpxml_file.include?('CZ6') || hpxml_file.include?('CZ7') || hpxml_file.include?('CZ8')
        perimeter_insulation_depth = 4
        perimeter_insulation_r = 10
      end
    elsif hpxml_file.include?('uncond_bsmt')
      interior_adjacent_to = HPXML::LocationBasementUnconditioned
      depth_below_grade = nil
      carpet_fraction = 0.0
      thickness = 4
      name = 'Slab'
      carpet_r_value = 0
      if hpxml_file.include?('CZ1') || hpxml_file.include?('CZ2')
        perimeter_insulation_depth = 0
        perimeter_insulation_r = 0
      end
      if hpxml_file.include?('CZ3')
        perimeter_insulation_depth = 0
        perimeter_insulation_r = 0
      end
      if hpxml_file.include?('CZ4_') || hpxml_file.include?('CZ4C_') || hpxml_file.include?('CZ5') || hpxml_file.include?('CZ6') || hpxml_file.include?('CZ7') || hpxml_file.include?('CZ8')
        perimeter_insulation_depth = 0
        perimeter_insulation_r = 0
      end
    else
      return
    end
    hpxml.slabs.clear
    hpxml.slabs.add(id: name,
                    interior_adjacent_to: interior_adjacent_to,
                    depth_below_grade: depth_below_grade,
                    area: area,
                    thickness: thickness,
                    exposed_perimeter: exposed_perimeter,
                    perimeter_insulation_depth: perimeter_insulation_depth,
                    under_slab_insulation_width: 0,
                    under_slab_insulation_spans_entire_slab: nil,
                    perimeter_insulation_r_value: perimeter_insulation_r,
                    under_slab_insulation_r_value: 0,
                    carpet_fraction: carpet_fraction,
                    carpet_r_value: carpet_r_value) # updated
  end
end

def set_hpxml_windows(hpxml_file, hpxml)
  if hpxml_file.include?('EnergyStar')
    if hpxml_file.include?('CZ1')
      ufactor = 0.40
      shgc = 0.25
    elsif hpxml_file.include?('CZ2')
      ufactor = 0.40
      shgc = 0.25
    elsif hpxml_file.include?('CZ3')
      ufactor = 0.30
      shgc = 0.25
    elsif hpxml_file.include?('CZ4_')
      ufactor = 0.30
      shgc = 0.40
    elsif hpxml_file.include?('CZ4C_')
      ufactor = 0.27
      shgc = 0.40
    elsif hpxml_file.include?('CZ5')
      ufactor = 0.27
      shgc = 0.40
    elsif hpxml_file.include?('CZ6')
      ufactor = 0.27
      shgc = 0.40
    elsif hpxml_file.include?('CZ7')
      ufactor = 0.27
      shgc = 0.40
    elsif hpxml_file.include?('CZ8')
      ufactor = 0.27
      shgc = 0.40
    end
  elsif hpxml_file.include?('2021IECC')
    if hpxml_file.include?('CZ1')
      ufactor = 0.40
      shgc = 0.25
    elsif hpxml_file.include?('CZ2')
      ufactor = 0.40
      shgc = 0.25
    elsif hpxml_file.include?('CZ3')
      ufactor = 0.30
      shgc = 0.25
    elsif hpxml_file.include?('CZ4_')
      ufactor = 0.30
      shgc = 0.40
    elsif hpxml_file.include?('CZ4C_')
      ufactor = 0.30
      shgc = 0.40
    elsif hpxml_file.include?('CZ5')
      ufactor = 0.30
      shgc = 0.40
    elsif hpxml_file.include?('CZ6')
      ufactor = 0.30
      shgc = 0.40
    elsif hpxml_file.include?('CZ7')
      ufactor = 0.30
      shgc = 0.40
    elsif hpxml_file.include?('CZ8')
      ufactor = 0.30
      shgc = 0.40
    end
  end

  cfa = hpxml.building_construction.conditioned_floor_area
  ag_bndry_wall_area, bg_bndry_wall_area = hpxml.thermal_boundary_wall_areas()
  common_wall_area = hpxml.common_wall_area()
  fa = ag_bndry_wall_area / (ag_bndry_wall_area + 0.5 * bg_bndry_wall_area)
  f = 1.0 - 0.44 * common_wall_area / (ag_bndry_wall_area + common_wall_area)
  tot_window_area = 0.15 * cfa * fa * f

  if ['EnergyStar', '2021IECC'].any? { |program| hpxml_file.include? program }
    windows = { 'WindowsNorth' => [0, (tot_window_area / 4.0).round(2), 'Wall'],
                'WindowsEast' => [90, (tot_window_area / 4.0).round(2), 'Wall'],
                'WindowsSouth' => [180, (tot_window_area / 4.0).round(2), 'Wall'],
                'WindowsWest' => [270, (tot_window_area / 4.0).round(2), 'Wall'] }
  end

  hpxml.windows.clear
  windows.each do |window_name, window_values|
    azimuth, area, wall = window_values
    hpxml.windows.add(id: window_name,
                      area: area,
                      azimuth: azimuth,
                      ufactor: ufactor,
                      shgc: shgc,
                      fraction_operable: 0.67,
                      wall_idref: wall,
                      performance_class: HPXML::WindowClassResidential)
  end
end

def set_hpxml_skylights(hpxml_file, hpxml)
end

def set_hpxml_doors(hpxml_file, hpxml)
  if hpxml_file.include?('EnergyStar')
    if hpxml_file.include?('CZ1')
      r_value = (1.0 / 0.1701).round(3)
    end
    if hpxml_file.include?('CZ2')
      r_value = (1.0 / 0.1701).round(3)
    end
    if hpxml_file.include?('CZ3') || hpxml_file.include?('CZ4_') || hpxml_file.include?('CZ4C_') || hpxml_file.include?('CZ5') || hpxml_file.include?('CZ6') || hpxml_file.include?('CZ7') || hpxml_file.include?('CZ8')
      r_value = (1.0 / 0.1701).round(3)
    end
  elsif hpxml_file.include?('2021IECC')
    if hpxml_file.include?('CZ1')
      r_value = (1.0 / 0.5).round(3)
    end
    if hpxml_file.include?('CZ2')
      r_value = (1.0 / 0.4).round(3)
    end
    if hpxml_file.include?('CZ3') || hpxml_file.include?('CZ4_') || hpxml_file.include?('CZ4C_') || hpxml_file.include?('CZ5') || hpxml_file.include?('CZ6') || hpxml_file.include?('CZ7') || hpxml_file.include?('CZ8')
      r_value = (1.0 / 0.3003).round(3)
    end
  end

  doors = { 'Door1' => [0, 21, 'Wall'],
            'Door2' => [180, 21, 'Wall'] }
  hpxml.doors.clear
  doors.each do |door_name, door_values|
    azimuth, area, wall = door_values
    hpxml.doors.add(id: door_name,
                    wall_idref: wall,
                    area: area,
                    azimuth: azimuth,
                    r_value: r_value)
  end
end

def set_hpxml_heating_systems(hpxml_file, hpxml)
  if hpxml_file.include?('EnergyStar')
    if hpxml_file.include?('_elec_')
      return
    elsif hpxml_file.include?('CZ1') || hpxml_file.include?('CZ2') || hpxml_file.include?('CZ3')
      afue = 0.80
    elsif hpxml_file.include?('CZ4_')
      afue = 0.90
    elsif hpxml_file.include?('CZ5') || hpxml_file.include?('CZ4C_') || hpxml_file.include?('CZ6') || hpxml_file.include?('CZ7') || hpxml_file.include?('CZ8')
      afue = 0.95
    end
    fan_watts_per_cfm = 0.52
    airflow_defect_ratio = -0.2
  elsif hpxml_file.include?('2021IECC')
    if hpxml_file.include?('_elec_')
      return
    elsif hpxml_file.include?('CZ1') || hpxml_file.include?('CZ2') || hpxml_file.include?('CZ3') || hpxml_file.include?('CZ4_') || hpxml_file.include?('CZ4C_') || hpxml_file.include?('CZ5') || hpxml_file.include?('CZ6') || hpxml_file.include?('CZ7') || hpxml_file.include?('CZ8')
      afue = 0.80
    end
    fan_watts_per_cfm = 0.58
    airflow_defect_ratio = -0.25
  end

  hpxml.heating_systems.clear
  hpxml.heating_systems.add(id: 'HeatingSystem',
                            distribution_system_idref: 'HVACDistribution',
                            heating_system_type: HPXML::HVACTypeFurnace,
                            heating_system_fuel: HPXML::FuelTypeNaturalGas,
                            heating_capacity: -1,
                            heating_efficiency_afue: afue,
                            fraction_heat_load_served: 1,
                            fan_watts_per_cfm: fan_watts_per_cfm,
                            airflow_defect_ratio: airflow_defect_ratio)
end

def set_hpxml_cooling_systems(hpxml_file, hpxml)
  if hpxml_file.include?('EnergyStar')
    if hpxml_file.include?('_elec_')
      return
    elsif hpxml_file.include?('CZ5') || hpxml_file.include?('CZ4C_') || hpxml_file.include?('CZ6') || hpxml_file.include?('CZ7') || hpxml_file.include?('CZ8')
      seer = 14
    elsif hpxml_file.include?('CZ1') || hpxml_file.include?('CZ2') || hpxml_file.include?('CZ3') || hpxml_file.include?('CZ4_')
      seer = 16
    end
    fan_watts_per_cfm = 0.52
    airflow_defect_ratio = -0.2
    charge_defect_ratio = -0.25
  elsif hpxml_file.include?('2021IECC')
    if hpxml_file.include?('_elec_')
      return
    elsif hpxml_file.include?('AZ') || hpxml_file.include?('CA') || hpxml_file.include?('NV') || hpxml_file.include?('NM') ||
          hpxml_file.include?('AL') || hpxml_file.include?('NV') || hpxml_file.include?('AR') || hpxml_file.include?('DE') ||
          hpxml_file.include?('FL') || hpxml_file.include?('GA') || hpxml_file.include?('HI') || hpxml_file.include?('LA') ||
          hpxml_file.include?('MD') || hpxml_file.include?('MD') || hpxml_file.include?('MS') ||
          hpxml_file.include?('OK') || hpxml_file.include?('SC') || hpxml_file.include?('TN') || hpxml_file.include?('TX') ||
          hpxml_file.include?('VA')
      seer = 15
    else 
      seer = 14
    end
    fan_watts_per_cfm = 0.58
    airflow_defect_ratio = -0.25
    charge_defect_ratio = -0.25
  end

  hpxml.cooling_systems.clear
  hpxml.cooling_systems.add(id: 'CoolingSystem',
                            distribution_system_idref: 'HVACDistribution',
                            cooling_system_type: HPXML::HVACTypeCentralAirConditioner,
                            cooling_system_fuel: HPXML::FuelTypeElectricity,
                            cooling_capacity: -1,
                            fraction_cool_load_served: 1,
                            cooling_efficiency_seer: seer,
                            fan_watts_per_cfm: fan_watts_per_cfm,
                            airflow_defect_ratio: airflow_defect_ratio,
                            charge_defect_ratio: charge_defect_ratio)
end

def set_hpxml_heat_pumps(hpxml_file, hpxml)
  if hpxml_file.include?('EnergyStar')
    if hpxml_file.include?('_gas_')
      return
    elsif hpxml_file.include?('CZ5') || hpxml_file.include?('CZ4C_') || hpxml_file.include?('CZ6') || hpxml_file.include?('CZ7') || hpxml_file.include?('CZ8')
      seer = 16
      hspf = 9.2
      if hpxml_file.include? 'NextGen'
      	seer = 16
      	hspf = 9.5
      	compressor_type = 'variable speed'
      end
    elsif hpxml_file.include?('CZ1') || hpxml_file.include?('CZ2') || hpxml_file.include?('CZ3') || hpxml_file.include?('CZ4_')
      seer = 16
      hspf = 9.2
      if hpxml_file.include? 'NextGen'
      	compressor_type = 'two stage'
      end
    end
    if hpxml_file.include? 'NextGen'
    	fan_watts_per_cfm = 0.45
    	airflow_defect_ratio = -0.075
    	charge_defect_ratio = 0
    else
    	fan_watts_per_cfm = 0.52
    	airflow_defect_ratio = -0.2
    	charge_defect_ratio = -0.25
    end
  elsif hpxml_file.include?('2021IECC')
    if hpxml_file.include?('_gas_')
      return
    elsif hpxml_file.include?('CZ5') || hpxml_file.include?('CZ4C_') || hpxml_file.include?('CZ6') || hpxml_file.include?('CZ7') || hpxml_file.include?('CZ8')
      seer = 15
      hspf = 8.8
    elsif hpxml_file.include?('CZ1') || hpxml_file.include?('CZ2') || hpxml_file.include?('CZ3') || hpxml_file.include?('CZ4_')
      seer = 15
      hspf = 8.8
    end
    fan_watts_per_cfm = 0.58
    airflow_defect_ratio = -0.25
    charge_defect_ratio = -0.25
  end

  hpxml.heat_pumps.clear
  hpxml.heat_pumps.add(id: 'HeatPump',
                        distribution_system_idref: 'HVACDistribution',
                        heat_pump_type: HPXML::HVACTypeHeatPumpAirToAir,
                        heat_pump_fuel: HPXML::FuelTypeElectricity,
            compressor_type: compressor_type,
                        cooling_capacity: -1,
                        heating_capacity: -1,
                        backup_type: HPXML::HeatPumpBackupTypeIntegrated,
                        backup_heating_fuel: HPXML::FuelTypeElectricity,
                        backup_heating_capacity: -1,
                        backup_heating_efficiency_percent: 1.0,
                        fraction_heat_load_served: 1,
                        fraction_cool_load_served: 1,
                        heating_efficiency_hspf: hspf,
                        cooling_efficiency_seer: seer,
                        fan_watts_per_cfm: fan_watts_per_cfm,
                        airflow_defect_ratio: airflow_defect_ratio,
                        charge_defect_ratio: charge_defect_ratio)
end

def set_hpxml_hvac_controls(hpxml_file, hpxml)
  if ['EnergyStar', '2021IECC'].any? { |program| hpxml_file.include? program }
    hpxml.hvac_controls.clear
    hpxml.hvac_controls.add(id: 'HVACControl',
                            control_type: HPXML::HVACControlTypeProgrammable)
  end
end

def set_hpxml_hvac_distributions(hpxml_file, hpxml)
  # Type
  if hpxml_file.include?('EnergyStar')
    duct_leakage_value = 0
  elsif hpxml_file.include?('2021IECC')
    tot_cfm25 = (4.0 * hpxml.building_construction.conditioned_floor_area / 100.0).round
    duct_leakage_value = tot_cfm25 * 0.5
  end
  
  hpxml.hvac_distributions.clear
  hpxml.hvac_distributions.add(id: 'HVACDistribution',
                                distribution_system_type: HPXML::HVACDistributionTypeAir,
                                air_type: HPXML::AirTypeRegularVelocity)
  # Leakage
  hpxml.hvac_distributions[0].duct_leakage_measurements.clear
  hpxml.hvac_distributions[0].duct_leakage_measurements.add(duct_type: HPXML::DuctTypeSupply,
                                                            duct_leakage_units: HPXML::UnitsCFM25,
                                                            duct_leakage_value: duct_leakage_value,
                                                            duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside)
  hpxml.hvac_distributions[0].duct_leakage_measurements.add(duct_type: HPXML::DuctTypeReturn,
                                                            duct_leakage_units: HPXML::UnitsCFM25,
                                                            duct_leakage_value: duct_leakage_value,
                                                            duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside)

  # Ducts
  if hpxml_file.include?('EnergyStar')
    if hpxml_file.include?('slab')
      supply_duct_multiplier = 0.75
      return_duct_multiplier = 0.75
      location_1 = HPXML::LocationLivingSpace
      location_2 = HPXML::LocationLivingSpace
      supply_r = 0
      return_r = 0
    end
    if hpxml_file.include?('vented_crawl')
      supply_duct_multiplier = 0.75
      return_duct_multiplier = 0.75
      location_1 = HPXML::LocationLivingSpace
      location_2 = HPXML::LocationLivingSpace
      supply_r = 0
      return_r = 0
    end
    if hpxml_file.include?('uncond_bsmt')
      supply_duct_multiplier = 0.75
      return_duct_multiplier = 0.75
      location_1 = HPXML::LocationLivingSpace
      location_2 = HPXML::LocationLivingSpace
      supply_r = 0
      return_r = 0
    end
    if hpxml_file.include?('_cond_bsmt')
      supply_duct_multiplier = 0.75
      return_duct_multiplier = 0.75
      location_1 = HPXML::LocationLivingSpace
      location_2 = HPXML::LocationLivingSpace
      supply_r = 0
      return_r = 0
    end
    supply_area_1 = 486
    supply_area_2 = (486 * (1 - supply_duct_multiplier)).round
    return_area_1 = 90
    return_area_2 = (90 * (1 - return_duct_multiplier)).round

    hpxml.hvac_distributions[0].ducts.clear
    hpxml.hvac_distributions[0].ducts.add(id: "SupplyDuct",
                                          duct_type: HPXML::DuctTypeSupply,
                                          duct_insulation_r_value: supply_r,
                                          duct_location: location_1,
                                          duct_surface_area: supply_area_1)
    hpxml.hvac_distributions[0].ducts.add(id: "ReturnDuct",
                                          duct_type: HPXML::DuctTypeReturn,
                                          duct_insulation_r_value: return_r,
                                          duct_location: location_1,
                                          duct_surface_area: return_area_1)
  elsif hpxml_file.include?('2021IECC')
    if hpxml_file.include?('slab')
      supply_duct_multiplier = 0.75
      return_duct_multiplier = 0.75
      location_1 = HPXML::LocationAtticVented
      location_2 = HPXML::LocationLivingSpace
      supply_r = 8
      return_r = 6
    end
    if hpxml_file.include?('vented_crawl')
      supply_duct_multiplier = 0.5
      return_duct_multiplier = 0.5
      location_1 = HPXML::LocationAtticVented
      location_2 = HPXML::LocationCrawlspaceVented
      supply_r = 8
      return_r = 6
    end
    if hpxml_file.include?('uncond_bsmt')
      supply_duct_multiplier = 0.5
      return_duct_multiplier = 0.5
      location_1 = HPXML::LocationAtticVented
      location_2 = HPXML::LocationBasementUnconditioned
      supply_r = 8
      return_r = 6
    end
    if hpxml_file.include?('_cond_bsmt')
      supply_duct_multiplier = 0.5
      return_duct_multiplier = 0.5
      location_1 = HPXML::LocationAtticVented
      location_2 = HPXML::LocationBasementConditioned
      supply_r = 8
      return_r = 6
    end
    supply_area_1 = (486 * supply_duct_multiplier).round
    supply_area_2 = (486 * (1 - supply_duct_multiplier)).round
    return_area_1 = (90 * return_duct_multiplier).round
    return_area_2 = (90 * (1 - return_duct_multiplier)).round

    hpxml.hvac_distributions[0].ducts.clear
    hpxml.hvac_distributions[0].ducts.add(id: "SupplyDuct1",
                                          duct_type: HPXML::DuctTypeSupply,
                                          duct_insulation_r_value: supply_r,
                                          duct_location: location_1,
                                          duct_surface_area: supply_area_1)
    hpxml.hvac_distributions[0].ducts.add(id: "SupplyDuct2",
                                          duct_type: HPXML::DuctTypeSupply,
                                          duct_insulation_r_value: supply_r,
                                          duct_location: location_2,
                                          duct_surface_area: supply_area_2)
    hpxml.hvac_distributions[0].ducts.add(id: "ReturnDuct1",
                                          duct_type: HPXML::DuctTypeReturn,
                                          duct_insulation_r_value: return_r,
                                          duct_location: location_1,
                                          duct_surface_area: return_area_1)
    hpxml.hvac_distributions[0].ducts.add(id: "ReturnDuct2",
                                          duct_type: HPXML::DuctTypeReturn,
                                          duct_insulation_r_value: return_r,
                                          duct_location: location_2,
                                          duct_surface_area: return_area_2)
  end

  # CFA served
  if hpxml.hvac_distributions.size == 1
    hpxml.hvac_distributions[0].conditioned_floor_area_served = hpxml.building_construction.conditioned_floor_area
  end

  # Return registers
  hpxml.hvac_distributions[0].number_of_return_registers = 1
  # hpxml.hvac_distributions.each do |hvac_distribution|
  # next unless hvac_distribution.distribution_system_type == HPXML::HVACDistributionTypeAir

  # hvac_distribution.number_of_return_registers = hpxml.building_construction.number_of_conditioned_floors
  # end
end

def set_hpxml_ventilation_fans(hpxml_file, hpxml)
  if hpxml_file.include?('EnergyStar')
    if hpxml_file.include?('CZ1') || hpxml_file.include?('CZ2') || hpxml_file.include?('CZ3') || hpxml_file.include?('CZ4_')
      fan_type = HPXML::MechVentTypeSupply
      cfm_per_w = 2.9
      attached_to = 'HVACDistribution'
    end
    if hpxml_file.include?('CZ5') || hpxml_file.include?('CZ4C_') || hpxml_file.include?('CZ6') || hpxml_file.include?('CZ7') || hpxml_file.include?('CZ8')
      fan_type = HPXML::MechVentTypeExhaust
      cfm_per_w = 2.8
      attached_to = 'HVACDistribution'
    end
  elsif hpxml_file.include?('2021IECC')
    if hpxml_file.include?('CZ1') || hpxml_file.include?('CZ2') || hpxml_file.include?('CZ3') || hpxml_file.include?('CZ4')
      fan_type = HPXML::MechVentTypeSupply ## updated ventilation type and efficacy
      cfm_per_w = 2.9
      attached_to = 'HVACDistribution'
    end
    if hpxml_file.include?('CZ5') || hpxml_file.include?('CZ4C_') || hpxml_file.include?('CZ6') || hpxml_file.include?('CZ7') || hpxml_file.include?('CZ8')
      fan_type = HPXML::MechVentTypeExhaust ## updated ventilation type and efficacy
      cfm_per_w = 2.8
      attached_to = 'HVACDistribution'
    end
  end

  tested_flow_rate = (0.01 * hpxml.building_construction.conditioned_floor_area + 7.5 * (hpxml.building_construction.number_of_bedrooms + 1)).round(2)
  hpxml.ventilation_fans.clear
  hpxml.ventilation_fans.add(id: 'MechanicalVentilation',
                              fan_type: fan_type,
                              tested_flow_rate: tested_flow_rate,
                              hours_in_operation: 24,
                              distribution_system_idref: attached_to,
                              fan_power: (tested_flow_rate / cfm_per_w).round(3),
                              used_for_whole_building_ventilation: true,
                              is_shared_system: false)
end

def set_hpxml_water_heating_systems(hpxml_file, hpxml)
  if hpxml_file.include?('vented_crawl') || hpxml_file.include?('slab')
    location = HPXML::LocationLivingSpace
  elsif hpxml_file.include?('uncond_bsmt')
    location = HPXML::LocationLivingSpace
  elsif hpxml_file.include?('_cond_bsmt')
    location = HPXML::LocationLivingSpace
  end

  hpxml.water_heating_systems.clear
  if hpxml_file.include?('_gas_')
    if hpxml_file.include? 'EnergyStar'
      energy_factor = 0.9
    elsif hpxml_file.include? '2021IECC'
      energy_factor = 0.82
    end
    hpxml.water_heating_systems.add(id: 'WaterHeater',
                                    is_shared_system: false,
                                    fuel_type: HPXML::FuelTypeNaturalGas,
                                    water_heater_type: HPXML::WaterHeaterTypeTankless,
                                    location: location,
                                    fraction_dhw_load_served: 1,
                                    energy_factor: energy_factor)
  else
    if hpxml_file.include? 'EnergyStarNextGen'
      energy_factor = 3.39
    elsif hpxml_file.include? 'EnergyStar'
      energy_factor = 2.06
    elsif hpxml_file.include? '2021IECC'
      energy_factor = 2.0
    end
    hpxml.water_heating_systems.add(id: 'WaterHeater',
                                    is_shared_system: false,
                                    fuel_type: HPXML::FuelTypeElectricity,
                                    water_heater_type: HPXML::WaterHeaterTypeHeatPump,
                                    location: location,
                                    tank_volume: 60,
                                    fraction_dhw_load_served: 1,
                                    energy_factor: energy_factor)
  end
end

def set_hpxml_hot_water_distribution(hpxml_file, hpxml)
  if ['EnergyStar', '2021IECC'].any? { |program| hpxml_file.include? program }
    # Standard
    if hpxml_file.include?('slab') || hpxml_file.include?('vented_crawl')
      piping_length = 89.28.round(2)
    elsif hpxml_file.include?('cond_bsmt') || hpxml_file.include?('uncond_bsmt')
      piping_length = 94.28.round(2)
    end
    hpxml.hot_water_distributions.clear
    hpxml.hot_water_distributions.add(id: 'HotWaterDstribution',
                                      system_type: HPXML::DHWDistTypeStandard,
                                      pipe_r_value: 0.0)
  end

  has_uncond_bsmnt = false
  hpxml.foundation_walls.each do |foundation_wall|
    next unless [foundation_wall.interior_adjacent_to, foundation_wall.exterior_adjacent_to].include? HPXML::LocationBasementUnconditioned

    has_uncond_bsmnt = true
  end
  cfa = hpxml.building_construction.conditioned_floor_area
  ncfl = hpxml.building_construction.number_of_conditioned_floors
  piping_length = HotWaterAndAppliances.get_default_std_pipe_length(has_uncond_bsmnt, cfa, ncfl)

  if hpxml.hot_water_distributions.size > 0
    if hpxml.hot_water_distributions[0].system_type == HPXML::DHWDistTypeStandard
      hpxml.hot_water_distributions[0].standard_piping_length = piping_length.round(3)
    elsif hpxml.hot_water_distributions[0].system_type == HPXML::DHWDistTypeRecirc
      hpxml.hot_water_distributions[0].recirculation_piping_length = HotWaterAndAppliances.get_default_recirc_loop_length(piping_length).round(3)
    end
  end
end

def set_hpxml_water_fixtures(hpxml_file, hpxml)
  if ['EnergyStar', '2021IECC'].any? { |program| hpxml_file.include? program }
    # Standard
    hpxml.water_fixtures.clear
    hpxml.water_fixtures.add(id: 'WaterFixture',
                             water_fixture_type: HPXML::WaterFixtureTypeShowerhead,
                             low_flow: false)
    hpxml.water_fixtures.add(id: 'WaterFixture2',
                             water_fixture_type: HPXML::WaterFixtureTypeFaucet,
                             low_flow: false)
  end
end

def set_hpxml_clothes_washer(hpxml_file, hpxml)
  if ['EnergyStar', '2021IECC'].any? { |program| hpxml_file.include? program }

    default_values = HotWaterAndAppliances.get_clothes_washer_default_values(get_eri_version(hpxml))
    hpxml.clothes_washers.clear
    hpxml.clothes_washers.add(id: 'ClothesWasher',
                              is_shared_appliance: false,
                              location: HPXML::LocationLivingSpace,
                              integrated_modified_energy_factor: default_values[:integrated_modified_energy_factor],
                              rated_annual_kwh: default_values[:rated_annual_kwh],
                              label_electric_rate: default_values[:label_electric_rate],
                              label_gas_rate: default_values[:label_gas_rate],
                              label_annual_gas_cost: default_values[:label_annual_gas_cost],
                              label_usage: default_values[:label_usage],
                              capacity: default_values[:capacity]) # these are all correct for IECC 2021
  end
end

def set_hpxml_clothes_dryer(hpxml_file, hpxml)
  if ['EnergyStar', '2021IECC'].any? { |program| hpxml_file.include? program }
    # Standard electric
    default_values = HotWaterAndAppliances.get_clothes_dryer_default_values(get_eri_version(hpxml), HPXML::FuelTypeElectricity)
    hpxml.clothes_dryers.clear
    hpxml.clothes_dryers.add(id: 'ClothesDryer',
                             is_shared_appliance: false,
                             location: HPXML::LocationLivingSpace,
                             fuel_type: HPXML::FuelTypeElectricity,
                             control_type: default_values[:control_type], # this may need to be checked, didn't find an input in the xml file
                             combined_energy_factor: default_values[:combined_energy_factor])
  end
end

def set_hpxml_dishwasher(hpxml_file, hpxml)
  if hpxml_file.include?('EnergyStar')
    place_setting_capacity = 12
    rated_annual_kwh = 270
    label_electric_rate = 0.12
    label_gas_rate = 1.09
    label_annual_gas_cost = 22.23
    label_usage = 208 / 52
  elsif hpxml_file.include?('2021IECC')
    place_setting_capacity = 12
    rated_annual_kwh = 307
    label_electric_rate = 0.12
    label_gas_rate = 1.09
    label_annual_gas_cost = 22.32
    label_usage = 208 / 52
  end

  hpxml.dishwashers.clear
  hpxml.dishwashers.add(id: 'Dishwasher',
                        is_shared_appliance: false,
                        location: HPXML::LocationLivingSpace,
                        place_setting_capacity: place_setting_capacity,
                        rated_annual_kwh: rated_annual_kwh,
                        label_electric_rate: label_electric_rate,
                        label_gas_rate: label_gas_rate,
                        label_annual_gas_cost: label_annual_gas_cost,
                        label_usage: label_usage)
end

def set_hpxml_refrigerator(hpxml_file, hpxml)
  if hpxml_file.include?('EnergyStar')
    rated_annual_kwh = 450
  elsif hpxml_file.include?('2021IECC')
    rated_annual_kwh = 491
  end

  hpxml.refrigerators.clear
  hpxml.refrigerators.add(id: 'Refrigerator',
                          location: HPXML::LocationLivingSpace,
                          rated_annual_kwh: rated_annual_kwh)
end

def set_hpxml_cooking_range(hpxml_file, hpxml)
  if hpxml_file.include? 'NextGen'
  	is_induction = true
  elsif ['EnergyStar', '2021IECC'].any? { |program| hpxml_file.include? program }
    default_values = HotWaterAndAppliances.get_range_oven_default_values()
    is_induction = default_values[:is_induction]
  end
  if hpxml_file.include?('gas')
    # Standard gas
    hpxml.cooking_ranges.clear
    hpxml.cooking_ranges.add(id: 'Range',
                              location: HPXML::LocationLivingSpace,
                              fuel_type: HPXML::FuelTypeNaturalGas,
                              is_induction: is_induction)
  else
    # Standard electric
    hpxml.cooking_ranges.clear
    hpxml.cooking_ranges.add(id: 'Range',
                              location: HPXML::LocationLivingSpace,
                              fuel_type: HPXML::FuelTypeElectricity,
                              is_induction: is_induction)
  end
end

def set_hpxml_oven(hpxml_file, hpxml)
  if ['EnergyStar', '2021IECC'].any? { |program| hpxml_file.include? program }
    default_values = HotWaterAndAppliances.get_range_oven_default_values()
    hpxml.ovens.clear
    hpxml.ovens.add(id: 'Oven',
                    is_convection: default_values[:is_convection])
  end
end

def set_hpxml_lighting(hpxml_file, hpxml)
  if hpxml_file.include?('EnergyStar')
    ltg_fracs = { [HPXML::LocationInterior, HPXML::LightingTypeLED] => 1.0,
                  [HPXML::LocationExterior, HPXML::LightingTypeLED] => 1.0,
                  [HPXML::LocationGarage, HPXML::LightingTypeLED] => 1.0,
                  [HPXML::LocationInterior, HPXML::LightingTypeCFL] => 0,
                  [HPXML::LocationExterior, HPXML::LightingTypeCFL] => 0,
                  [HPXML::LocationGarage, HPXML::LightingTypeCFL] => 0,
                  [HPXML::LocationInterior, HPXML::LightingTypeLFL] => 0,
                  [HPXML::LocationExterior, HPXML::LightingTypeLFL] => 0,
                  [HPXML::LocationGarage, HPXML::LightingTypeLFL] => 0 }
  elsif hpxml_file.include?('2021IECC')
    ltg_fracs = { [HPXML::LocationInterior, HPXML::LightingTypeLED] => 0,
                  [HPXML::LocationExterior, HPXML::LightingTypeLED] => 0,
                  [HPXML::LocationGarage, HPXML::LightingTypeLED] => 0,
                  [HPXML::LocationInterior, HPXML::LightingTypeCFL] => 1.0,
                  [HPXML::LocationExterior, HPXML::LightingTypeCFL] => 1.0,
                  [HPXML::LocationGarage, HPXML::LightingTypeCFL] => 1.0,
                  [HPXML::LocationInterior, HPXML::LightingTypeLFL] => 0,
                  [HPXML::LocationExterior, HPXML::LightingTypeLFL] => 0,
                  [HPXML::LocationGarage, HPXML::LightingTypeLFL] => 0 }
  else
    ltg_fracs = Lighting.get_default_fractions()
  end

  hpxml.lighting_groups.clear
  ltg_fracs.each_with_index do |(key, fraction), i|
    location, lighting_type = key
    hpxml.lighting_groups.add(id: "LightingGroup#{i + 1}",
                              location: location,
                              fraction_of_units_in_location: fraction,
                              lighting_type: lighting_type)
  end
end

def set_hpxml_plug_loads(hpxml_file, hpxml)
  hpxml.plug_loads.clear
end

def get_eri_version(hpxml)
  eri_version = hpxml.header.eri_calculation_version
  eri_version = Constants.ERIVersions[-1] if (eri_version == 'latest' || eri_version.nil?)
  return eri_version
end

require 'oga'
require_relative 'hpxml-measures/HPXMLtoOpenStudio/resources/constants'
require_relative 'hpxml-measures/HPXMLtoOpenStudio/resources/hotwater_appliances'
require_relative 'hpxml-measures/HPXMLtoOpenStudio/resources/hpxml'
require_relative 'hpxml-measures/HPXMLtoOpenStudio/resources/lighting'
require_relative 'hpxml-measures/HPXMLtoOpenStudio/resources/xmlhelper'
require_relative 'hpxml-measures/HPXMLtoOpenStudio/resources/xmlvalidator'
require_relative 'hpxml-measures/HPXMLtoOpenStudio/resources/version'
require_relative 'rulesets/resources/constants'

create_test_hpxmls

puts "\nDone."
