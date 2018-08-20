# Separate ruby script to allow the code to be called using system() on Windows

require_relative "../measures/301EnergyRatingIndexRuleset/resources/meta_measure"

def get_designdir(basedir, design)
  return File.join(basedir, design.gsub(' ',''))
end

def get_output_hpxml_path(resultsdir, designdir)
  return File.join(resultsdir, File.basename(designdir) + ".xml")
end

def run_design(basedir, design, resultsdir, hpxml, debug)
  # Use print instead of puts in here (see https://stackoverflow.com/a/5044669)
  print "[#{design}] Creating input...\n"
  output_hpxml_path, rundir = create_idf(design, basedir, resultsdir, hpxml, debug)
  
  print "[#{design}] Running simulation...\n"
  run_energyplus(design, rundir)
  
  return output_hpxml_path
end
      
def create_idf(design, basedir, resultsdir, hpxml, debug)
  designdir = get_designdir(basedir, design)
  Dir.mkdir(designdir)
  
  rundir = File.join(designdir, "run")
  Dir.mkdir(rundir)
  
  OpenStudio::Logger.instance.standardOutLogger.setLogLevel(OpenStudio::Fatal)
  
  model = OpenStudio::Model::Model.new
  runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)
  measures_dir = File.join(File.dirname(__FILE__), "../measures")
  measures = {}
  measure_subdir = "301EnergyRatingIndexRuleset"
  
  output_hpxml_path = get_output_hpxml_path(resultsdir, designdir)
  args = {}
  args['calc_type'] = design
  args['hpxml_path'] = hpxml
  args['weather_dir'] = File.absolute_path(File.join(basedir, "..", "weather"))
  #args['schemas_dir'] = File.absolute_path(File.join(basedir, "..", "hpxml_schemas"))
  args['hpxml_output_path'] = output_hpxml_path
  args['epw_output_path'] = File.join(rundir, "in.epw")
  if debug
    args['osm_output_path'] = File.join(rundir, "in.osm")
  end
  
  update_args_hash(measures, measure_subdir, args)
  success = apply_measures(measures_dir, measures, runner, model, nil, nil, false)
  
  File.open(File.join(designdir,'run.log'), 'w') do |f|
    runner.result.stepWarnings.each do |w|
      f << "Warning: #{w}\n"
    end
    runner.result.stepErrors.each do |e|
      f << "Error: #{e}\n"
    end
  end

  if not success
    fail "ERROR: Simulation unsuccessful for #{design}."
  end
  
  forward_translator = OpenStudio::EnergyPlus::ForwardTranslator.new
  model_idf = forward_translator.translateModel(model)
  File.open(File.join(rundir, "in.idf"), 'w') { |f| f << model_idf.to_s }
  
  return output_hpxml_path, rundir
end

def run_energyplus(design, rundir)
  ep_path = OpenStudio.getEnergyPlusDirectory.to_s
  if ep_path.empty? # Bug in OS, should remove at some point in the future
    # Probably run on linux w/o absolute path
    ep_path = "/usr/local/openstudio-#{OpenStudio.openStudioVersion}/EnergyPlus"
  end
  ep_path = File.join(ep_path, "energyplus")
  command = "cd #{rundir} && #{ep_path} -w in.epw in.idf > stdout-energyplus"
  system(command, :err => File::NULL)
end
      
if ARGV.size == 5
  basedir = ARGV[0]
  design = ARGV[1]
  resultsdir = ARGV[2]
  hpxml = ARGV[3]
  debug = (ARGV[4].downcase.to_s == "true")
  run_design(basedir, design, resultsdir, hpxml, debug)
end