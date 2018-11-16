# Used by energy_rating_index.rb.
# Separate ruby script to allow being called using system() on Windows.

require_relative "../measures/HPXMLtoOpenStudio/resources/meta_measure"

def get_designdir(basedir, design)
  return File.join(basedir, design.gsub(' ', ''))
end

def get_output_hpxml_path(resultsdir, designdir)
  return File.join(resultsdir, File.basename(designdir) + ".xml")
end

def run_design(basedir, design, resultsdir, hpxml, debug, skip_validation)
  # Use print instead of puts in here (see https://stackoverflow.com/a/5044669)
  print "[#{design}] Creating input...\n"
  output_hpxml_path, rundir = create_idf(design, basedir, resultsdir, hpxml, debug, skip_validation)

  print "[#{design}] Running simulation...\n"
  run_energyplus(design, rundir)

  return output_hpxml_path
end

def create_idf(design, basedir, resultsdir, hpxml, debug, skip_validation)
  designdir = get_designdir(basedir, design)
  Dir.mkdir(designdir)

  rundir = File.join(designdir, "run")
  Dir.mkdir(rundir)

  OpenStudio::Logger.instance.standardOutLogger.setLogLevel(OpenStudio::Fatal)

  output_hpxml_path = get_output_hpxml_path(resultsdir, designdir)

  model = OpenStudio::Model::Model.new
  runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)
  measures_dir = File.join(File.dirname(__FILE__), "../measures")

  measures = {}

  # Add 301 measure to workflow
  measure_subdir = "301EnergyRatingIndexRuleset"
  args = {}
  args['calc_type'] = design
  args['hpxml_path'] = hpxml
  args['weather_dir'] = File.absolute_path(File.join(basedir, "..", "weather"))
  # args['schemas_dir'] = File.absolute_path(File.join(basedir, "..", "hpxml_schemas"))
  args['hpxml_output_path'] = output_hpxml_path
  args['skip_validation'] = skip_validation
  update_args_hash(measures, measure_subdir, args)

  # Add HPXML translator measure to workflow
  measure_subdir = "HPXMLtoOpenStudio"
  args = {}
  args['hpxml_path'] = output_hpxml_path
  args['weather_dir'] = File.absolute_path(File.join(basedir, "..", "weather"))
  # args['schemas_dir'] = File.absolute_path(File.join(basedir, "..", "hpxml_schemas"))
  args['epw_output_path'] = File.join(rundir, "in.epw")
  if debug
    args['osm_output_path'] = File.join(rundir, "in.osm")
  end
  args['skip_validation'] = skip_validation
  update_args_hash(measures, measure_subdir, args)

  # Apply measures
  success = apply_measures(measures_dir, measures, runner, model, nil, nil, true)

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

  if not success
    fail "Simulation unsuccessful for #{design}."
  end

  # Write model to IDF
  forward_translator = OpenStudio::EnergyPlus::ForwardTranslator.new
  model_idf = forward_translator.translateModel(model)
  File.open(File.join(rundir, "in.idf"), 'w') { |f| f << model_idf.to_s }

  return output_hpxml_path, rundir
end

def run_energyplus(design, rundir)
  # getEnergyPlusDirectory can be unreliable, using getOpenStudioCLI instead
  ep_path = File.absolute_path(File.join(OpenStudio.getOpenStudioCLI.to_s, '..', '..', 'EnergyPlus', 'energyplus'))
  command = "cd #{rundir} && #{ep_path} -w in.epw in.idf > stdout-energyplus"
  system(command, :err => File::NULL)
end

if ARGV.size == 6
  basedir = ARGV[0]
  design = ARGV[1]
  resultsdir = ARGV[2]
  hpxml = ARGV[3]
  debug = (ARGV[4].downcase.to_s == "true")
  skip_validation = (ARGV[5].downcase.to_s == "true")
  run_design(basedir, design, resultsdir, hpxml, debug, skip_validation)
end
