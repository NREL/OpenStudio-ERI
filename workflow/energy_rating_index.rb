start_time = Time.now

require 'optparse'
require 'csv'
require 'pathname'
require 'fileutils'
require 'parallel'
require File.join(File.dirname(__FILE__), "design.rb")
require_relative "../hpxml-measures/HPXMLtoOpenStudio/resources/constants"

basedir = File.expand_path(File.dirname(__FILE__))

def rm_path(path)
  if Dir.exists?(path)
    FileUtils.rm_r(path)
  end
  while true
    break if not Dir.exists?(path)

    sleep(0.01)
  end
end

def hourly_outputs_for_run(run, hourly_outputs)
  if run == [Constants.CalcTypeERIRatedHome] or run == [Constants.CalcTypeERIReferenceHome]
    return hourly_outputs
  end

  return []
end

def run_design_direct(basedir, output_dir, run, resultsdir, hpxml, debug, hourly_outputs)
  # Calls design.rb methods directly. Should only be called from a forked
  # process. This is the fastest approach.
  design_name, designdir = get_design_name_and_dir(output_dir, run)
  rm_path(designdir)
  hourly_outputs = hourly_outputs_for_run(run, hourly_outputs)

  output_hpxml_path = run_design(basedir, output_dir, run, resultsdir, hpxml, debug, hourly_outputs)

  return output_hpxml_path, designdir
end

def run_design_spawn(basedir, output_dir, run, resultsdir, hpxml, debug, hourly_outputs)
  # Calls design.rb in a new spawned process in order to utilize multiple
  # processes. Not as efficient as calling design.rb methods directly in
  # forked processes for a couple reasons:
  # 1. There is overhead to using the CLI
  # 2. There is overhead to spawning processes vs using forked processes
  design_name, designdir = get_design_name_and_dir(output_dir, run)
  rm_path(designdir)
  output_hpxml_path = get_output_hpxml(resultsdir, designdir)
  hourly_outputs = hourly_outputs_for_run(run, hourly_outputs)

  cli_path = OpenStudio.getOpenStudioCLI
  pid = Process.spawn("\"#{cli_path}\" --no-ssl \"#{File.join(File.dirname(__FILE__), "design.rb")}\" \"#{basedir}\" \"#{output_dir}\" \"#{run.join('|')}\" \"#{resultsdir}\" \"#{hpxml}\" #{debug} \"#{hourly_outputs.join('|')}\"")

  return output_hpxml_path, designdir, pid
end

def retrieve_eri_outputs(design_name, resultsdir, debug)
  csv_path = File.join(resultsdir, "#{design_name.gsub(' ', '')}_ERI.csv")
  if not File.exists? csv_path
    return nil
  end

  output_data = {}

  csv_data = CSV.read(csv_path, headers: false)
  csv_data.each do |data|
    next if data.empty?

    key = data[0]
    key.gsub!("enduseElectricity", "elec")
    key.gsub!("enduseNaturalGas", "gas")
    key.gsub!("enduseFuelOil", "oil")
    key.gsub!("endusePropane", "propane")

    output_data[key.to_sym] = eval(data[1])
  end

  File.delete(csv_path) if not debug

  return output_data
end

def _calculate_eri(rated_output, ref_output, results_iad = nil)
  results = {}

  # ======= #
  # Heating #
  # ======= #

  results[:reul_heat] = []
  results[:coeff_heat_a] = []
  results[:coeff_heat_b] = []
  results[:eec_x_heat] = []
  results[:eec_r_heat] = []
  results[:ec_x_heat] = []
  results[:ec_r_heat] = []
  results[:dse_r_heat] = []
  results[:nec_x_heat] = []
  results[:nmeul_heat] = []

  for s in 0..rated_output[:hpxml_eec_heats].size - 1
    reul_heat = ref_output[:loadHeating][s]

    coeff_heat_a = nil
    coeff_heat_b = nil
    if rated_output[:hpxml_heat_fuels][s] == 'electricity'
      coeff_heat_a = 2.2561
      coeff_heat_b = 0.0
    elsif ['natural gas', 'fuel oil', 'propane'].include? rated_output[:hpxml_heat_fuels][s]
      coeff_heat_a = 1.0943
      coeff_heat_b = 0.4030
    end
    if coeff_heat_a.nil? or coeff_heat_b.nil?
      fail "Could not identify EEC coefficients for heating system."
    end

    eec_x_heat = rated_output[:hpxml_eec_heats][s]
    eec_r_heat = ref_output[:hpxml_eec_heats][s]

    ec_x_heat = rated_output[:elecHeating][s] + rated_output[:elecHeatingFansPumps][s] + rated_output[:gasHeating][s] + rated_output[:oilHeating][s] + rated_output[:propaneHeating][s]
    ec_r_heat = ref_output[:elecHeating][s] + ref_output[:elecHeatingFansPumps][s] + ref_output[:gasHeating][s] + ref_output[:oilHeating][s] + ref_output[:propaneHeating][s]

    dse_r_heat = reul_heat / ec_r_heat * eec_r_heat

    nec_x_heat = 0
    if eec_x_heat * reul_heat > 0
      nec_x_heat = (coeff_heat_a * eec_x_heat - coeff_heat_b) * (ec_x_heat * ec_r_heat * dse_r_heat) / (eec_x_heat * reul_heat)
    end

    nmeul_heat = 0
    if ec_r_heat > 0
      nmeul_heat = reul_heat * (nec_x_heat / ec_r_heat)
    end

    results[:reul_heat] << reul_heat
    results[:coeff_heat_a] << coeff_heat_a
    results[:coeff_heat_b] << coeff_heat_b
    results[:eec_x_heat] << eec_x_heat
    results[:eec_r_heat] << eec_r_heat
    results[:ec_x_heat] << ec_x_heat
    results[:ec_r_heat] << ec_r_heat
    results[:dse_r_heat] << dse_r_heat
    results[:nec_x_heat] << nec_x_heat
    results[:nmeul_heat] << nmeul_heat
  end

  # ======= #
  # Cooling #
  # ======= #

  results[:reul_cool] = []
  results[:coeff_cool_a] = []
  results[:coeff_cool_b] = []
  results[:eec_x_cool] = []
  results[:eec_r_cool] = []
  results[:ec_x_cool] = []
  results[:ec_r_cool] = []
  results[:dse_r_cool] = []
  results[:nec_x_cool] = []
  results[:nmeul_cool] = []

  tot_reul_cool = ref_output[:loadCooling].inject(:+)
  for s in 0..rated_output[:hpxml_eec_cools].size - 1
    reul_cool = ref_output[:loadCooling][s]

    coeff_cool_a = 3.8090
    coeff_cool_b = 0.0

    eec_x_cool = rated_output[:hpxml_eec_cools][s]
    eec_r_cool = ref_output[:hpxml_eec_cools][s]

    ec_x_cool = rated_output[:elecCooling][s] + rated_output[:elecCoolingFansPumps][s]
    ec_r_cool = ref_output[:elecCooling][s] + ref_output[:elecCoolingFansPumps][s]

    dse_r_cool = reul_cool / ec_r_cool * eec_r_cool

    nec_x_cool = 0
    if eec_x_cool * reul_cool > 0
      nec_x_cool = (coeff_cool_a * eec_x_cool - coeff_cool_b) * (ec_x_cool * ec_r_cool * dse_r_cool) / (eec_x_cool * reul_cool)
    end
    # Add whole-house fan energy to nec_x_cool per 301 (apportioned by load) and excluded from eul_la
    nec_x_cool += (rated_output[:elecWholeHouseFan] * reul_cool / tot_reul_cool)

    nmeul_cool = 0
    if ec_r_cool > 0
      nmeul_cool = reul_cool * (nec_x_cool / ec_r_cool)
    end

    results[:reul_cool] << reul_cool
    results[:coeff_cool_a] << coeff_cool_a
    results[:coeff_cool_b] << coeff_cool_b
    results[:eec_x_cool] << eec_x_cool
    results[:eec_r_cool] << eec_r_cool
    results[:ec_x_cool] << ec_x_cool
    results[:ec_r_cool] << ec_r_cool
    results[:dse_r_cool] << dse_r_cool
    results[:nec_x_cool] << nec_x_cool
    results[:nmeul_cool] << nmeul_cool
  end

  # ======== #
  # HotWater #
  # ======== #

  results[:reul_dhw] = []
  results[:coeff_dhw_a] = []
  results[:coeff_dhw_b] = []
  results[:eec_x_dhw] = []
  results[:eec_r_dhw] = []
  results[:ec_x_dhw] = []
  results[:ec_r_dhw] = []
  results[:dse_r_dhw] = []
  results[:nec_x_dhw] = []
  results[:nmeul_dhw] = []

  for s in 0..rated_output[:hpxml_eec_dhws].size - 1
    reul_dhw = ref_output[:loadHotWaterDelivered][s]

    coeff_dhw_a = nil
    coeff_dhw_b = nil
    if rated_output[:hpxml_dwh_fuels][s] == 'electricity'
      coeff_dhw_a = 0.9200
      coeff_dhw_b = 0.0
    elsif ['natural gas', 'fuel oil', 'propane'].include? rated_output[:hpxml_dwh_fuels][s]
      coeff_dhw_a = 1.1877
      coeff_dhw_b = 1.0130
    end
    if coeff_dhw_a.nil? or coeff_dhw_b.nil?
      fail "Could not identify EEC coefficients for water heating system."
    end

    eec_x_dhw = rated_output[:hpxml_eec_dhws][s]
    eec_r_dhw = ref_output[:hpxml_eec_dhws][s]

    ec_x_dhw = rated_output[:elecHotWater][s] + rated_output[:gasHotWater][s] + rated_output[:oilHotWater][s] + rated_output[:propaneHotWater][s] + rated_output[:elecHotWaterRecircPump][s] + rated_output[:elecHotWaterSolarThermalPump][s]
    ec_r_dhw = ref_output[:elecHotWater][s] + ref_output[:gasHotWater][s] + ref_output[:oilHotWater][s] + ref_output[:propaneHotWater][s] + ref_output[:elecHotWaterRecircPump][s] + ref_output[:elecHotWaterSolarThermalPump][s]

    dse_r_dhw = reul_dhw / ec_r_dhw * eec_r_dhw

    nec_x_dhw = 0
    if eec_x_dhw * reul_dhw > 0
      nec_x_dhw = (coeff_dhw_a * eec_x_dhw - coeff_dhw_b) * (ec_x_dhw * ec_r_dhw * dse_r_dhw) / (eec_x_dhw * reul_dhw)
    end

    nmeul_dhw = 0
    if ec_r_dhw > 0
      nmeul_dhw = reul_dhw * (nec_x_dhw / ec_r_dhw)
    end

    results[:reul_dhw] << reul_dhw
    results[:coeff_dhw_a] << coeff_dhw_a
    results[:coeff_dhw_b] << coeff_dhw_b
    results[:eec_x_dhw] << eec_x_dhw
    results[:eec_r_dhw] << eec_r_dhw
    results[:ec_x_dhw] << ec_x_dhw
    results[:ec_r_dhw] << ec_r_dhw
    results[:dse_r_dhw] << dse_r_dhw
    results[:nec_x_dhw] << nec_x_dhw
    results[:nmeul_dhw] << nmeul_dhw
  end

  # ===== #
  # Other #
  # ===== #

  results[:teu] = rated_output[:fuelElectricity] + 0.4 * (rated_output[:fuelNaturalGas] + rated_output[:fuelFuelOil] + rated_output[:fuelPropane])
  results[:opp] = -1 * rated_output[:elecPV]

  results[:pefrac] = 1.0
  if results[:teu] > 0
    results[:pefrac] = (results[:teu] - results[:opp]) / results[:teu]
  end

  results[:eul_la] = (rated_output[:elecLightingInterior] + rated_output[:elecLightingExterior] +
                      rated_output[:elecLightingGarage] + rated_output[:elecRefrigerator] +
                      rated_output[:elecDishwasher] + rated_output[:elecClothesWasher] +
                      rated_output[:elecClothesDryer] + rated_output[:elecPlugLoads] +
                      rated_output[:elecTelevision] + rated_output[:elecRangeOven] +
                      rated_output[:elecCeilingFan] + rated_output[:elecMechVent] +
                      rated_output[:gasClothesDryer] + rated_output[:gasRangeOven] +
                      rated_output[:oilClothesDryer] + rated_output[:oilRangeOven] +
                      rated_output[:propaneClothesDryer] + rated_output[:propaneRangeOven])

  results[:reul_la] = (ref_output[:elecLightingInterior] + ref_output[:elecLightingExterior] +
                       ref_output[:elecLightingGarage] + ref_output[:elecRefrigerator] +
                       ref_output[:elecDishwasher] + ref_output[:elecClothesWasher] +
                       ref_output[:elecClothesDryer] + ref_output[:elecPlugLoads] +
                       ref_output[:elecTelevision] + ref_output[:elecRangeOven] +
                       ref_output[:elecCeilingFan] + ref_output[:elecMechVent] +
                       ref_output[:gasClothesDryer] + ref_output[:gasRangeOven] +
                       ref_output[:oilClothesDryer] + ref_output[:oilRangeOven] +
                       ref_output[:propaneClothesDryer] + ref_output[:propaneRangeOven])

  # === #
  # ERI #
  # === #

  results[:trl] = results[:reul_heat].inject(0, :+) +
                  results[:reul_cool].inject(0, :+) +
                  results[:reul_dhw].inject(0, :+) +
                  results[:reul_la]
  results[:tnml] = results[:nmeul_heat].inject(0, :+) +
                   results[:nmeul_cool].inject(0, :+) +
                   results[:nmeul_dhw].inject(0, :+) +
                   results[:eul_la]

  if not results_iad.nil?

    # ANSI/RESNET/ICC 301-2014 Addendum E-2018 House Size Index Adjustment Factors (IAF)

    results[:iad_save] = (100.0 - results_iad[:eri]) / 100.0

    results[:iaf_cfa] = (2400.0 / rated_output[:hpxml_cfa])**(0.304 * results[:iad_save])
    results[:iaf_nbr] = 1.0 + (0.069 * results[:iad_save] * (rated_output[:hpxml_nbr] - 3.0))
    results[:iaf_ns] = (2.0 / rated_output[:hpxml_nst])**(0.12 * results[:iad_save])
    results[:iaf_rh] = results[:iaf_cfa] * results[:iaf_nbr] * results[:iaf_ns]

    results[:eri] = results[:pefrac] * results[:tnml] / (results[:trl] * results[:iaf_rh]) * 100.0

  else

    results[:eri] = results[:pefrac] * results[:tnml] / results[:trl] * 100.0

  end

  return results
end

def write_results(results, resultsdir, design_outputs, results_iad)
  ref_output = design_outputs[[Constants.CalcTypeERIReferenceHome]]

  # Results file
  results_csv = File.join(resultsdir, "ERI_Results.csv")
  results_out = []
  results_out << ["ERI", results[:eri].round(2)]
  results_out << ["REUL Heating (MBtu)", results[:reul_heat].map { |x| x.round(2) }.join(",")]
  results_out << ["REUL Cooling (MBtu)", results[:reul_cool].map { |x| x.round(2) }.join(",")]
  results_out << ["REUL Hot Water (MBtu)", results[:reul_dhw].map { |x| x.round(2) }.join(",")]
  results_out << ["EC_r Heating (MBtu)", results[:ec_r_heat].map { |x| x.round(2) }.join(",")]
  results_out << ["EC_r Cooling (MBtu)", results[:ec_r_cool].map { |x| x.round(2) }.join(",")]
  results_out << ["EC_r Hot Water (MBtu)", results[:ec_r_dhw].map { |x| x.round(2) }.join(",")]
  results_out << ["EC_x Heating (MBtu)", results[:ec_x_heat].map { |x| x.round(2) }.join(",")]
  results_out << ["EC_x Cooling (MBtu)", results[:ec_x_cool].map { |x| x.round(2) }.join(",")]
  results_out << ["EC_x Hot Water (MBtu)", results[:ec_x_dhw].map { |x| x.round(2) }.join(",")]
  results_out << ["EC_x L&A (MBtu)", results[:eul_la].round(2)]
  if not results_iad.nil?
    results_out << ["IAD_Save (%)", results[:iad_save].round(5)]
  end
  # TODO: Heating Fuel, Heating MEPR, Cooling Fuel, Cooling MEPR, Hot Water Fuel, Hot Water MEPR
  CSV.open(results_csv, "wb") { |csv| results_out.to_a.each { |elem| csv << elem } }

  # Worksheet file
  worksheet_csv = File.join(resultsdir, "ERI_Worksheet.csv")
  worksheet_out = []
  worksheet_out << ["Coeff Heating a", results[:coeff_heat_a].map { |x| x.round(4) }.join(",")]
  worksheet_out << ["Coeff Heating b", results[:coeff_heat_b].map { |x| x.round(4) }.join(",")]
  worksheet_out << ["Coeff Cooling a", results[:coeff_cool_a].map { |x| x.round(4) }.join(",")]
  worksheet_out << ["Coeff Cooling b", results[:coeff_cool_b].map { |x| x.round(4) }.join(",")]
  worksheet_out << ["Coeff Hot Water a", results[:coeff_dhw_a].map { |x| x.round(4) }.join(",")]
  worksheet_out << ["Coeff Hot Water b", results[:coeff_dhw_b].map { |x| x.round(4) }.join(",")]
  worksheet_out << ["DSE_r Heating", results[:dse_r_heat].map { |x| x.round(4) }.join(",")]
  worksheet_out << ["DSE_r Cooling", results[:dse_r_cool].map { |x| x.round(4) }.join(",")]
  worksheet_out << ["DSE_r Hot Water", results[:dse_r_dhw].map { |x| x.round(4) }.join(",")]
  worksheet_out << ["EEC_x Heating", results[:eec_x_heat].map { |x| x.round(4) }.join(",")]
  worksheet_out << ["EEC_x Cooling", results[:eec_x_cool].map { |x| x.round(4) }.join(",")]
  worksheet_out << ["EEC_x Hot Water", results[:eec_x_dhw].map { |x| x.round(4) }.join(",")]
  worksheet_out << ["EEC_r Heating", results[:eec_r_heat].map { |x| x.round(4) }.join(",")]
  worksheet_out << ["EEC_r Cooling", results[:eec_r_cool].map { |x| x.round(4) }.join(",")]
  worksheet_out << ["EEC_r Hot Water", results[:eec_r_dhw].map { |x| x.round(4) }.join(",")]
  worksheet_out << ["nEC_x Heating", results[:nec_x_heat].map { |x| x.round(4) }.join(",")]
  worksheet_out << ["nEC_x Cooling", results[:nec_x_cool].map { |x| x.round(4) }.join(",")]
  worksheet_out << ["nEC_x Hot Water", results[:nec_x_dhw].map { |x| x.round(4) }.join(",")]
  worksheet_out << ["nMEUL Heating", results[:nmeul_heat].map { |x| x.round(4) }.join(",")]
  worksheet_out << ["nMEUL Cooling", results[:nmeul_cool].map { |x| x.round(4) }.join(",")]
  worksheet_out << ["nMEUL Hot Water", results[:nmeul_dhw].map { |x| x.round(4) }.join(",")]
  if not results_iad.nil?
    worksheet_out << ["IAF CFA", results[:iaf_cfa].round(4)]
    worksheet_out << ["IAF NBR", results[:iaf_nbr].round(4)]
    worksheet_out << ["IAF NS", results[:iaf_ns].round(4)]
    worksheet_out << ["IAF RH", results[:iaf_rh].round(4)]
  end
  worksheet_out << ["Total Loads TnML", results[:tnml].round(4)]
  worksheet_out << ["Total Loads TRL", results[:trl].round(4)]
  if not results_iad.nil?
    worksheet_out << ["Total Loads TRL*IAF", (results[:trl] * results[:iaf_rh]).round(4)]
  end
  worksheet_out << ["ERI", results[:eri].round(2)]
  worksheet_out << [nil] # line break
  worksheet_out << ["Ref Home CFA", ref_output[:hpxml_cfa]]
  worksheet_out << ["Ref Home Nbr", ref_output[:hpxml_nbr]]
  if not results_iad.nil?
    worksheet_out << ["Ref Home NS", ref_output[:hpxml_nst]]
  end
  worksheet_out << ["Ref L&A resMELs", ref_output[:elecPlugLoads].round(2)]
  worksheet_out << ["Ref L&A intLgt", (ref_output[:elecLightingInterior] + ref_output[:elecLightingGarage]).round(2)]
  worksheet_out << ["Ref L&A extLgt", ref_output[:elecLightingExterior].round(2)]
  worksheet_out << ["Ref L&A Fridg", ref_output[:elecRefrigerator].round(2)]
  worksheet_out << ["Ref L&A TVs", ref_output[:elecTelevision].round(2)]
  worksheet_out << ["Ref L&A R/O", (ref_output[:elecRangeOven] + ref_output[:gasRangeOven] + ref_output[:oilRangeOven] + ref_output[:propaneRangeOven]).round(2)]
  worksheet_out << ["Ref L&A cDryer", (ref_output[:elecClothesDryer] + ref_output[:gasClothesDryer] + ref_output[:oilClothesDryer] + ref_output[:propaneClothesDryer]).round(2)]
  worksheet_out << ["Ref L&A dWash", ref_output[:elecDishwasher].round(2)]
  worksheet_out << ["Ref L&A cWash", ref_output[:elecClothesWasher].round(2)]
  worksheet_out << ["Ref L&A mechV", ref_output[:elecMechVent].round(2)]
  worksheet_out << ["Ref L&A total", results[:reul_la].round(2)]
  CSV.open(worksheet_csv, "wb") { |csv| worksheet_out.to_a.each { |elem| csv << elem } }
end

def download_epws
  weather_dir = File.join(File.dirname(__FILE__), "..", "weather")

  require 'net/http'
  require 'tempfile'

  tmpfile = Tempfile.new("epw")

  url = URI.parse("https://data.nrel.gov/files/128/tmy3s-cache-csv.zip")
  http = Net::HTTP.new(url.host, url.port)
  http.use_ssl = true
  http.verify_mode = OpenSSL::SSL::VERIFY_NONE

  params = { 'User-Agent' => 'curl/7.43.0', 'Accept-Encoding' => 'identity' }
  request = Net::HTTP::Get.new(url.path, params)
  request.content_type = 'application/zip, application/octet-stream'

  http.request request do |response|
    total = response.header["Content-Length"].to_i
    if total == 0
      fail "Did not successfully download zip file."
    end

    size = 0
    progress = 0
    open tmpfile, 'wb' do |io|
      response.read_body do |chunk|
        io.write chunk
        size += chunk.size
        new_progress = (size * 100) / total
        unless new_progress == progress
          puts "Downloading %s (%3d%%) " % [url.path, new_progress]
        end
        progress = new_progress
      end
    end
  end

  puts "Extracting weather files..."
  unzip_file = OpenStudio::UnzipFile.new(tmpfile.path.to_s)
  unzip_file.extractAllFiles(OpenStudio::toPath(weather_dir))

  num_epws_actual = Dir[File.join(weather_dir, "*.epw")].count
  puts "#{num_epws_actual} weather files are available in the weather directory."
  puts "Completed."
  exit!
end

def cache_weather
  # Process all epw files through weather.rb and serialize objects
  require_relative "../hpxml-measures/HPXMLtoOpenStudio/resources/weather"

  # OpenStudio::Logger.instance.standardOutLogger.setLogLevel(OpenStudio::Fatal)
  weather_dir = File.join(File.dirname(__FILE__), "..", "weather")
  OpenStudio::Logger.instance.standardOutLogger.setLogLevel(OpenStudio::Fatal)
  runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)
  puts "Creating cache *.csv for weather files..."
  Dir["#{weather_dir}/*.epw"].each do |epw|
    next if File.exists? epw.gsub(".epw", "-cache.csv")

    puts "Processing #{epw}..."
    model = OpenStudio::Model::Model.new
    epw_file = OpenStudio::EpwFile.new(epw)
    OpenStudio::Model::WeatherFile.setWeatherFile(model, epw_file).get
    weather = WeatherProcess.new(model, runner)
    File.open(epw.gsub(".epw", "-cache.csv"), "wb") do |file|
      weather.dump_to_csv(file)
    end

    # Also add file to data.csv
    weather_data = []
    weather_data << epw_file.wmoNumber            # wmo
    weather_data << epw_file.city                 # station_name
    weather_data << epw_file.stateProvinceRegion  # state
    weather_data << epw_file.latitude             # latitude
    weather_data << epw_file.longitude            # longitude
    weather_data << epw_file.timeZone.to_i        # timezone
    weather_data << epw_file.elevation.to_i       # elevation
    weather_data << "???"                         # class
    weather_data << File.basename(epw)            # filename
    # Write entire file again (rather than just appending new data) to prevent
    # inconsistent line endings.
    csv_data = CSV.read(File.join(weather_dir, "data.csv"))
    csv_data << weather_data
    CSV.open(File.join(weather_dir, "data.csv"), "w") do |csv|
      csv_data.each do |data|
        csv << data
      end
    end
  end
  puts "Completed."
  exit!
end

def get_versions(hpxml_path)
  versions = {}

  # Avoid REXML for performance reasons
  text = File.read(hpxml_path)
  text.gsub!("\r", "")
  text.gsub!("\n", "")

  # Check for versions
  ["ERICalculation"].each do |program|
    idx = text.index("<#{program}")
    if not idx.nil?
      idx_end = text.index(">", idx)

      str_v = "<Version"
      idx_v = text.index(str_v, idx_end + 1)
      idx_v_end = text.index(">", idx_v)

      str_v2 = "</Version>"
      idx_v2 = text.index(str_v2, idx_v)

      version = text.slice(idx_v_end + 1, idx_v2 - idx_v_end - 1)
      versions[program] = version
    end
  end

  fail "No calculations specified." if versions.empty?

  return versions
end

def calculate_eri(design_outputs, resultsdir)
  if design_outputs.keys.include? [Constants.CalcTypeERIIndexAdjustmentDesign]
    results_iad = _calculate_eri(design_outputs[[Constants.CalcTypeERIIndexAdjustmentDesign]],
                                 design_outputs[[Constants.CalcTypeERIIndexAdjustmentReferenceHome]])
  else
    results_iad = nil
  end
  results = _calculate_eri(design_outputs[[Constants.CalcTypeERIRatedHome]],
                           design_outputs[[Constants.CalcTypeERIReferenceHome]],
                           results_iad)
  write_results(results, resultsdir, design_outputs, results_iad)

  return results
end

hourly_types = ["ALL", "fuels", "enduses", "loads", "componentloads", "temperatures"]

options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: #{File.basename(__FILE__)} -x building.xml\n e.g., #{File.basename(__FILE__)} -x sample_files/base.xml\n"

  opts.on('-x', '--xml <FILE.xml>', 'HPXML file') do |t|
    options[:hpxml] = t
  end

  opts.on('-o', '--output-dir <DIR>', 'Output directory') do |t|
    options[:output_dir] = t
  end

  options[:hourly_outputs] = []
  opts.on('--hourly TYPE', hourly_types, "Request hourly output type (#{hourly_types[0..3].join(', ')}", "#{hourly_types[4..-1].join(', ')}); can be called multiple times") do |t|
    options[:hourly_outputs] << t
  end

  opts.on('-w', '--download-weather', 'Downloads all US TMY3 weather files') do |t|
    options[:epws] = t
  end

  opts.on('-c', '--cache-weather', 'Caches all weather files') do |t|
    options[:cache] = t
  end

  options[:debug] = false
  opts.on('-d', '--debug') do |t|
    options[:debug] = true
  end

  options[:version] = false
  opts.on('-v', '--version', 'Reports the workflow version') do |t|
    options[:version] = true
  end

  opts.on_tail('-h', '--help', 'Display help') do
    puts opts
    exit!
  end
end.parse!

if options[:hourly_outputs].include? "ALL"
  options[:hourly_outputs] = hourly_types[1..-1]
end

# Check for correct versions of OS
os_version = "2.9.1"
if OpenStudio.openStudioVersion != os_version
  fail "OpenStudio version #{os_version} is required."
end

if options[:version]
  workflow_version = "0.7.0"
  puts "OpenStudio-ERI v#{workflow_version}"
  puts "OpenStudio v#{OpenStudio.openStudioLongVersion}"
  puts "EnergyPlus v#{OpenStudio.energyPlusVersion}.#{OpenStudio.energyPlusBuildSHA}"
  exit!
end

if options[:epws]
  download_epws
end

if options[:cache]
  cache_weather
end

if not options[:hpxml]
  fail "HPXML argument is required. Call #{File.basename(__FILE__)} -h for usage."
end

unless (Pathname.new options[:hpxml]).absolute?
  options[:hpxml] = File.expand_path(options[:hpxml])
end
unless File.exists?(options[:hpxml]) and options[:hpxml].downcase.end_with? ".xml"
  fail "'#{options[:hpxml]}' does not exist or is not an .xml file."
end

if options[:output_dir].nil?
  options[:output_dir] = basedir # default
end
options[:output_dir] = File.expand_path(options[:output_dir])

unless Dir.exists?(options[:output_dir])
  FileUtils.mkdir_p(options[:output_dir])
end

# Create results dir
resultsdir = File.join(options[:output_dir], "results")
rm_path(resultsdir)
Dir.mkdir(resultsdir)

versions = get_versions(options[:hpxml])

# Determine designs to run
# Create list of [ERI calc_type]
runs = []
versions.each do |program, version|
  if program == "ERICalculation"
    runs << [Constants.CalcTypeERIRatedHome]
    runs << [Constants.CalcTypeERIReferenceHome]
    if ['2014AE', '2014AEG', 'latest'].include? version
      runs << [Constants.CalcTypeERIIndexAdjustmentDesign]
      runs << [Constants.CalcTypeERIIndexAdjustmentReferenceHome]
    end
    break
  end
end

# TODO: Delete all old dirs for all possible runs

# Run simulations
puts "HPXML: #{options[:hpxml]}"
if Process.respond_to?(:fork) # e.g., most Unix systems

  # Code runs in forked child processes and makes direct calls. This is the fastest
  # approach but isn't available on, e.g., Windows.

  def kill
    raise Parallel::Kill
  end

  Parallel.map(runs, in_processes: runs.size) do |run|
    output_hpxml_path, designdir = run_design_direct(basedir, options[:output_dir], run, resultsdir, options[:hpxml], options[:debug], options[:hourly_outputs])
    kill unless File.exists? File.join(designdir, "eplusout.end")
  end

else # e.g., Windows

  # Fallback. Code runs in spawned child processes in order to take advantage of
  # multiple processors.

  def kill(pids)
    pids.values.each do |pid|
      begin
        Process.kill("KILL", pid)
      rescue
      end
    end
  end

  pids = {}
  Parallel.map(runs, in_threads: runs.size) do |run|
    output_hpxml_path, designdir, pids[run] = run_design_spawn(basedir, options[:output_dir], run, resultsdir, options[:hpxml], options[:debug], options[:hourly_outputs])
    Process.wait pids[run]
    if not File.exists? File.join(designdir, "eplusout.end")
      kill(pids)
      next
    end
  end

end

# Retrieve outputs for ERI calculations
design_outputs = {}
runs.each do |run|
  design_name, designdir = get_design_name_and_dir(options[:output_dir], run)
  design_outputs[run] = retrieve_eri_outputs(design_name, resultsdir, options[:debug])

  if design_outputs[run].nil?
    puts "Errors encountered. Aborting..."
    exit!
  end
end

# Calculate and write results
versions.each do |program, version|
  if program == "ERICalculation"
    puts "Calculating ERI..."
    results = calculate_eri(design_outputs, resultsdir)
    puts "ERI: #{results[:eri].round(2)}"
  end
end

puts "Output files written to '#{File.basename(resultsdir)}' directory."
puts "Completed in #{(Time.now - start_time).round(1)} seconds."
