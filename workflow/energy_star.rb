# frozen_string_literal: true

start_time = Time.now

args = ARGV.dup
ARGV.clear

require 'optparse'
require 'csv'
require 'pathname'
require 'fileutils'
require 'parallel'
require 'oga'
require File.join(File.dirname(__FILE__), 'design.rb')
require File.join(File.dirname(__FILE__), 'util.rb')
require_relative '../rulesets/EnergyStarRuleset/resources/constants'
require_relative '../rulesets/EnergyStarRuleset/resources/util'
require_relative '../hpxml-measures/HPXMLtoOpenStudio/resources/constants'
require_relative '../hpxml-measures/HPXMLtoOpenStudio/resources/hpxml'
require_relative '../hpxml-measures/HPXMLtoOpenStudio/resources/version'
require_relative '../hpxml-measures/HPXMLtoOpenStudio/resources/xmlhelper'

basedir = File.expand_path(File.dirname(__FILE__))

def get_es_version(hpxml_path)
  hpxml_doc = XMLHelper.parse_file(hpxml_path)
  es_version = XMLHelper.get_value(hpxml_doc, '/HPXML/SoftwareInfo/extension/EnergyStarCalculation/Version', :string)
  if es_version.nil?
    fail 'EnergyStarCalculation/Version not specified.'
  end
  if not ESConstants.AllVersions.include?(es_version)
    fail "Unexpected EnergyStarCalculation/Version: '#{es_version}'."
  end
  return es_version
end

def generate_es_hpxml(options, resultsdir, calc_type)
  measures_dir = File.join(File.dirname(__FILE__), '..')
  es_hpxml = File.join(resultsdir, "#{calc_type.gsub(' ', '')}.xml")

  measures = {}

  # Add EnergyStar measure to workflow
  measure_subdir = 'rulesets/EnergyStarRuleset'
  args = {}
  args['calc_type'] = calc_type
  args['hpxml_input_path'] = options[:hpxml]
  args['hpxml_output_path'] = es_hpxml
  update_args_hash(measures, measure_subdir, args)

  OpenStudio::Logger.instance.standardOutLogger.setLogLevel(OpenStudio::Fatal)
  os_log = OpenStudio::StringStreamLogSink.new
  os_log.setLogLevel(OpenStudio::Warn)

  model = OpenStudio::Model::Model.new
  runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)

  success = apply_measures(measures_dir, measures, runner, model, false, 'OpenStudio::Measure::ModelMeasure')
  report_measure_errors_warnings(runner, resultsdir, options[:debug])
  report_os_warnings(os_log, resultsdir)

  if not success
    print "Creating #{calc_type.gsub(' ', '')}.xml unsuccessful.\n"
    print "See #{File.join(resultsdir, 'run.log')} for details.\n"
    exit!
  end

  return es_hpxml
end

def write_es_results(resultsdir, esrd_results, rated_results, rated_results_wo_opp, target_eri, saf, passes)
  esrd_eri = esrd_results[:eri].round(0)
  target_eri = target_eri.round(0)
  rated_eri = rated_results[:eri].round(0)
  rated_wo_opp_eri = rated_results_wo_opp[:eri].round(0)

  if rated_wo_opp_eri - rated_eri > esrd_eri - target_eri
    fail 'Unexpected error.'
  end

  results_csv = File.join(resultsdir, 'ES_Results.csv')
  results_out = []
  results_out << ['Reference Home ERI', esrd_eri]
  if saf.nil?
    results_out << ['SAF (Size Adjustment Factor)', 'N/A']
  else
    results_out << ['SAF (Size Adjustment Factor)', saf.round(3)]
  end
  results_out << ['SAF Adjusted ERI Target', target_eri]
  results_out << [nil] # line break
  results_out << ['Rated Home ERI', rated_eri]
  results_out << ['Rated Home ERI w/o OPP', rated_wo_opp_eri]
  results_out << [nil] # line break
  if passes
    results_out << ['ENERGY STAR Certification', 'PASS']
  else
    results_out << ['ENERGY STAR Certification', 'FAIL']
  end
  CSV.open(results_csv, 'wb') { |csv| results_out.to_a.each { |elem| csv << elem } }
end

# Check for correct versions of OS
Version.check_openstudio_version()

options = process_arguments(File.basename(__FILE__), args, basedir)

resultsdir = setup_resultsdir(options)

es_version = get_es_version(options[:hpxml])

# Generate ESReference.xml and ESRated.xml
esrd_hpxml = generate_es_hpxml(options, resultsdir, ESConstants.CalcTypeEnergyStarReference)
rated_hpxml = generate_es_hpxml(options, resultsdir, ESConstants.CalcTypeEnergyStarRated)

esrd_dir = File.join(options[:output_dir], ESConstants.CalcTypeEnergyStarReference.gsub(' ', ''))
esrd_resultsdir = File.join(esrd_dir, 'results')
rm_path(esrd_dir)
Dir.mkdir(esrd_dir)

esrated_dir = File.join(options[:output_dir], ESConstants.CalcTypeEnergyStarRated.gsub(' ', ''))
esrated_resultsdir = File.join(esrated_dir, 'results')
rm_path(esrated_dir)
Dir.mkdir(esrated_dir)

# Create list of designs to run: [ERI calc_type, HPXML, output_dir, results_dir]
runs = []
runs << [Constants.CalcTypeERIRatedHome, esrd_hpxml, esrd_dir, esrd_resultsdir]
runs << [Constants.CalcTypeERIReferenceHome, esrd_hpxml, esrd_dir, esrd_resultsdir]
runs << [Constants.CalcTypeERIIndexAdjustmentDesign, esrd_hpxml, esrd_dir, esrd_resultsdir]
runs << [Constants.CalcTypeERIIndexAdjustmentReferenceHome, esrd_hpxml, esrd_dir, esrd_resultsdir]
runs << [Constants.CalcTypeERIRatedHome, rated_hpxml, esrated_dir, esrated_resultsdir]
runs << [Constants.CalcTypeERIReferenceHome, rated_hpxml, esrated_dir, esrated_resultsdir]
runs << [Constants.CalcTypeERIIndexAdjustmentDesign, rated_hpxml, esrated_dir, esrated_resultsdir]
runs << [Constants.CalcTypeERIIndexAdjustmentReferenceHome, rated_hpxml, esrated_dir, esrated_resultsdir]

# Run simulations
run_simulations(runs, options, basedir)

puts 'Calculating ENERGY STAR...'

# Calculate ES Reference ERI
esrd_outputs = retrieve_outputs(runs[0..3], options)
esrd_results = calculate_eri(esrd_outputs, esrd_resultsdir)

# Calculate Size-Adjusted ERI for Energy Star Reference Homes
saf = calc_energystar_saf(esrd_results, es_version, esrd_hpxml)
target_eri = esrd_results[:eri] * saf

# Calculate ES Rated ERI, w/ On-site Power Production (OPP) restriction as appropriate
opp_reduction_limit = calc_opp_eri_limit(esrd_results[:eri], saf, es_version)
rated_outputs = retrieve_outputs(runs[4..7], options)
rated_results = calculate_eri(rated_outputs, esrated_resultsdir, opp_reduction_limit: opp_reduction_limit)

if rated_results[:eri].round(0) <= target_eri.round(0)
  passes = true
else
  passes = false
end

# Calculate ES Rated ERI w/o OPP for extra information
rated_results_wo_opp = calculate_eri(rated_outputs, esrated_resultsdir, opp_reduction_limit: 0.0)

write_es_results(resultsdir, esrd_results, rated_results, rated_results_wo_opp, target_eri, saf, passes)

if passes
  puts 'ENERGY STAR Certification: PASS'
else
  puts 'ENERGY STAR Certification: FAIL'
end

puts "Output files written to #{resultsdir}"
puts "Completed in #{(Time.now - start_time).round(1)}s."
