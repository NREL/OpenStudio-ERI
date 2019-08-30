# Used by energy_rating_index.rb.
# Separate ruby script to allow being called using system() on Windows.

require_relative "../measures/HPXMLtoOpenStudio/resources/meta_measure"

def get_designdir(output_dir, design)
  return File.join(output_dir, design.gsub(' ', ''))
end

def get_output_hpxml_path(resultsdir, designdir)
  return File.join(resultsdir, File.basename(designdir) + ".xml")
end

def run_design(basedir, output_dir, design, resultsdir, hpxml, debug, skip_validation)
  # Use print instead of puts in here (see https://stackoverflow.com/a/5044669)
  print "[#{design}] Creating input...\n"
  output_hpxml_path, designdir = create_idf(design, basedir, output_dir, resultsdir, hpxml, debug, skip_validation)

  if not designdir.nil?
    print "[#{design}] Running simulation...\n"
    run_energyplus(design, designdir)
  end

  return output_hpxml_path
end

def create_idf(design, basedir, output_dir, resultsdir, hpxml, debug, skip_validation)
  designdir = get_designdir(output_dir, design)
  Dir.mkdir(designdir)

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
  args['schemas_dir'] = File.absolute_path(File.join(basedir, "..", "measures", "HPXMLtoOpenStudio", "hpxml_schemas"))
  args['hpxml_output_path'] = output_hpxml_path
  args['skip_validation'] = skip_validation
  update_args_hash(measures, measure_subdir, args)

  # Add HPXML translator measure to workflow
  measure_subdir = "HPXMLtoOpenStudio"
  args = {}
  args['hpxml_path'] = output_hpxml_path
  args['weather_dir'] = File.absolute_path(File.join(basedir, "..", "weather"))
  args['schemas_dir'] = File.absolute_path(File.join(basedir, "..", "measures", "HPXMLtoOpenStudio", "hpxml_schemas"))
  args['epw_output_path'] = File.join(designdir, "in.epw")
  if debug
    args['osm_output_path'] = File.join(designdir, "in.osm")
  end
  args['skip_validation'] = skip_validation
  args['map_tsv_dir'] = designdir
  update_args_hash(measures, measure_subdir, args)

  # Apply measures
  success = apply_measures(measures_dir, measures, runner, model)

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
    print "[#{design}] Creating input unsuccessful.\n"
    return output_hpxml_path, nil
  end

  # Write model to IDF
  forward_translator = OpenStudio::EnergyPlus::ForwardTranslator.new
  model_idf = forward_translator.translateModel(model)
  File.open(File.join(designdir, "in.idf"), 'w') { |f| f << model_idf.to_s }

  return output_hpxml_path, designdir
end

def run_energyplus(design, designdir)
  # getEnergyPlusDirectory can be unreliable, using getOpenStudioCLI instead
  ep_path = File.absolute_path(File.join(OpenStudio.getOpenStudioCLI.to_s, '..', '..', 'EnergyPlus', 'energyplus'))
  command = "cd \"#{designdir}\" && \"#{ep_path}\" -w in.epw in.idf > stdout-energyplus"
  system(command, :err => File::NULL)
end

if ARGV.size == 7
  basedir = ARGV[0]
  output_dir = ARGV[1]
  design = ARGV[2]
  resultsdir = ARGV[3]
  hpxml = ARGV[4]
  debug = (ARGV[5].downcase.to_s == "true")
  skip_validation = (ARGV[6].downcase.to_s == "true")
  run_design(basedir, output_dir, design, resultsdir, hpxml, debug, skip_validation)
end
