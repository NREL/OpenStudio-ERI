# Used by energy_rating_index.rb.
# Separate ruby script to allow being called using system() on Windows.

require_relative "../measures/HPXMLtoOpenStudio/resources/meta_measure"

def get_design_name_and_dir(output_dir, run)
  design_name = ""
  run.each do |x|
    next if x.nil?

    design_name += "_" if design_name.length > 0
    design_name += x
  end
  return design_name, File.join(output_dir, design_name.gsub(' ', ''))
end

def get_output_hpxml(resultsdir, designdir)
  return File.join(resultsdir, File.basename(designdir) + ".xml")
end

def get_enabled_hourly_variables(hourly_output, hourly_output_csv)
  hourly_variables = []
  if hourly_output
    require 'csv'
    hourly_outputs_rows = CSV.read(hourly_output_csv, headers: false)
    hourly_outputs_rows.each do |hourly_output_row|
      next unless hourly_output_row[0].upcase.strip == 'TRUE'

      hourly_variables << hourly_output_row[1].upcase.strip
    end
  end
  return hourly_variables
end

def run_design(basedir, output_dir, run, resultsdir, hpxml, debug, hourly_output)
  OpenStudio::Logger.instance.standardOutLogger.setLogLevel(OpenStudio::Fatal)

  design_name, designdir = get_design_name_and_dir(output_dir, run)
  output_hpxml = get_output_hpxml(resultsdir, designdir)

  measures_dir = File.join(File.dirname(__FILE__), "../measures")
  measures = get_measures_to_run(run, hpxml, output_hpxml, hourly_output, debug, basedir, designdir)

  Dir.mkdir(designdir)

  model = OpenStudio::Model::Model.new
  runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)

  # Use print instead of puts in here (see https://stackoverflow.com/a/5044669)
  print "[#{design_name}] Creating input...\n"

  # Apply model measures
  success = apply_measures(measures_dir, measures, runner, model, true, "OpenStudio::Measure::ModelMeasure")
  report_measure_errors_warnings(runner, designdir, debug)

  if not success
    print "[#{design_name}] Creating input unsuccessful.\n"
    return output_hpxml
  end

  # Translate model
  forward_translator = OpenStudio::EnergyPlus::ForwardTranslator.new
  forward_translator.setExcludeLCCObjects(true)
  model_idf = forward_translator.translateModel(model)
  report_ft_errors_warnings(forward_translator, designdir)

  # Apply reporting measure output requests
  apply_energyplus_output_requests(measures_dir, measures, runner, model, model_idf)

  # Write model to IDF
  File.open(File.join(designdir, "in.idf"), 'w') { |f| f << model_idf.to_s }

  print "[#{design_name}] Running simulation...\n"
  run_energyplus(designdir, debug)

  print "[#{design_name}] Processing output...\n"

  # Apply measures
  runner.setLastEnergyPlusSqlFilePath(File.join(designdir, "eplusout.sql"))
  success = apply_measures(measures_dir, measures, runner, model, true, "OpenStudio::Measure::ReportingMeasure")
  report_measure_errors_warnings(runner, designdir, debug)

  if not success
    print "[#{design_name}] Processing output unsuccessful.\n"
    return output_hpxml
  end

  print "[#{design_name}] Done.\n"

  return output_hpxml
end

def get_measures_to_run(run, hpxml, output_hpxml, hourly_output, debug, basedir, designdir)
  measures = {}

  if not run[0].nil?
    # Add 301 measure to workflow
    measure_subdir = "301EnergyRatingIndexRuleset"
    args = {}
    args['calc_type'] = run[0]
    args['hpxml_input_path'] = hpxml
    args['hpxml_output_path'] = output_hpxml
    update_args_hash(measures, measure_subdir, args)
  end

  # Add HPXML translator measure to workflow
  measure_subdir = "HPXMLtoOpenStudio"
  args = {}
  args['hpxml_path'] = output_hpxml
  args['weather_dir'] = File.absolute_path(File.join(basedir, "..", "weather"))
  args['epw_output_path'] = File.join(designdir, "in.epw")
  if debug
    args['osm_output_path'] = File.join(designdir, "in.osm")
  end
  update_args_hash(measures, measure_subdir, args)

  # Add reporting measure to workflow
  hourly_variables = get_enabled_hourly_variables(hourly_output, File.join(File.dirname(__FILE__), "hourly_outputs.csv"))
  measure_subdir = "SimOutputReport"
  args = {}
  args['hpxml_path'] = output_hpxml
  args['hourly_output_fuel_consumptions'] = hourly_variables.include?("Fuel Consumptions".upcase)
  args['hourly_output_zone_temperatures'] = hourly_variables.include?("Zone Temperatures".upcase)
  args['hourly_output_total_loads'] = hourly_variables.include?("Total Loads".upcase)
  args['hourly_output_component_loads'] = hourly_variables.include?("Component Loads".upcase)
  update_args_hash(measures, measure_subdir, args)

  return measures
end

def run_energyplus(designdir, debug)
  # getEnergyPlusDirectory can be unreliable, using getOpenStudioCLI instead
  ep_path = File.absolute_path(File.join(OpenStudio.getOpenStudioCLI.to_s, '..', '..', 'EnergyPlus', 'energyplus'))
  command = "\"#{ep_path}\" -w in.epw in.idf > stdout-energyplus"
  if debug
    File.open(File.join(designdir, 'run.log'), 'a') do |f|
      f << "Executing command '#{command}' from working directory '#{designdir}'"
    end
  end
  Dir.chdir(designdir) do
    system(command, :err => IO.sysopen(File.join(designdir, 'stderr-energyplus'), 'w'))
  end
end

def report_measure_errors_warnings(runner, designdir, debug)
  # Report warnings/errors
  File.open(File.join(designdir, 'run.log'), 'w') do |f|
    if debug
      runner.result.stepInfo.each do |s|
        f << "Info: #{s}\n"
      end
    end
    runner.result.stepWarnings.each do |s|
      f << "Warning: #{s}\n"
    end
    runner.result.stepErrors.each do |s|
      f << "Error: #{s}\n"
    end
  end
end

def report_ft_errors_warnings(forward_translator, designdir)
  # Report warnings/errors
  File.open(File.join(designdir, 'run.log'), 'a') do |f|
    forward_translator.warnings.each do |s|
      f << "FT Warning: #{s.logMessage}\n"
    end
    forward_translator.errors.each do |s|
      f << "FT Error: #{s.logMessage}\n"
    end
  end
end

if ARGV.size == 7
  basedir = ARGV[0]
  output_dir = ARGV[1]
  run = ARGV[2].split("|").map { |x| (x.length == 0 ? nil : x) }
  resultsdir = ARGV[3]
  hpxml = ARGV[4]
  debug = (ARGV[5].downcase.to_s == "true")
  hourly_output = (ARGV[6].downcase.to_s == "true")
  run_design(basedir, output_dir, run, resultsdir, hpxml, debug, hourly_output)
end
