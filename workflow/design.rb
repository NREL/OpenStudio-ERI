# frozen_string_literal: true

# Separate ruby script to allow being called using system() on Windows.

require_relative '../hpxml-measures/HPXMLtoOpenStudio/resources/meta_measure'

def get_design_dir(run)
  return File.join(run[2], run[0].gsub(' ', ''))
end

def get_output_filename(run, file_suffix = '.xml')
  return File.join(run[3], run[0].gsub(' ', '') + file_suffix)
end

def run_design(basedir, run, hpxml, debug, hourly_outputs, add_comp_loads)
  measures_dir = File.join(File.dirname(__FILE__), '..')
  designdir = get_design_dir(run)
  output_hpxml = get_output_filename(run)

  measures = {}

  # Add 301 measure to workflow
  measure_subdir = 'rulesets/301EnergyRatingIndexRuleset'
  args = {}
  args['calc_type'] = run[0]
  args['hpxml_input_path'] = run[1]
  args['hpxml_output_path'] = output_hpxml
  update_args_hash(measures, measure_subdir, args)

  # Add HPXML translator measure to workflow
  measure_subdir = 'hpxml-measures/HPXMLtoOpenStudio'
  args = {}
  args['hpxml_path'] = output_hpxml
  args['output_dir'] = File.absolute_path(designdir)
  args['debug'] = debug
  args['add_component_loads'] = (add_comp_loads || hourly_outputs.include?('componentloads'))
  args['skip_validation'] = !debug
  update_args_hash(measures, measure_subdir, args)

  # Add reporting measure to workflow
  measure_subdir = 'hpxml-measures/SimulationOutputReport'
  args = {}
  args['timeseries_frequency'] = 'hourly'
  args['include_timeseries_fuel_consumptions'] = hourly_outputs.include? 'fuels'
  args['include_timeseries_end_use_consumptions'] = hourly_outputs.include? 'enduses'
  args['include_timeseries_hot_water_uses'] = hourly_outputs.include? 'hotwater'
  args['include_timeseries_total_loads'] = hourly_outputs.include? 'loads'
  args['include_timeseries_component_loads'] = hourly_outputs.include? 'componentloads'
  args['include_timeseries_unmet_loads'] = hourly_outputs.include? 'unmetloads'
  args['include_timeseries_zone_temperatures'] = hourly_outputs.include? 'temperatures'
  args['include_timeseries_airflows'] = hourly_outputs.include? 'airflows'
  args['include_timeseries_weather'] = hourly_outputs.include? 'weather'
  update_args_hash(measures, measure_subdir, args)

  print_prefix = "[#{run[0]}] "

  results = run_hpxml_workflow(designdir, measures, measures_dir, debug: debug, print_prefix: print_prefix)

  return output_hpxml
end

if ARGV.size == 6
  basedir = ARGV[0]
  run = ARGV[1].split('|').map { |x| (x.length == 0 ? nil : x) }
  hpxml = ARGV[2]
  debug = (ARGV[3].downcase.to_s == 'true')
  hourly_outputs = ARGV[4].split('|')
  add_comp_loads = (ARGV[5].downcase.to_s == 'true')
  run_design(basedir, run, hpxml, debug, hourly_outputs, add_comp_loads)
end
