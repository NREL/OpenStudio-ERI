# frozen_string_literal: true

# Used by energy_rating_index.rb.
# Separate ruby script to allow being called using system() on Windows.

require_relative '../hpxml-measures/HPXMLtoOpenStudio/resources/meta_measure'

def get_design_name_and_dir(output_dir, run)
  design_name = ''
  run.each do |x|
    next if x.nil?

    design_name += '_' if design_name.length > 0
    design_name += x
  end
  return design_name, File.join(output_dir, design_name.gsub(' ', ''))
end

def get_output_hpxml(resultsdir, designdir)
  return File.join(resultsdir, File.basename(designdir) + '.xml')
end

def run_design(basedir, output_dir, run, resultsdir, hpxml, debug, hourly_outputs)
  measures_dir = File.join(File.dirname(__FILE__), '..')
  design_name, designdir = get_design_name_and_dir(output_dir, run)
  output_hpxml = get_output_hpxml(resultsdir, designdir)

  measures = {}

  if not run[0].nil?
    # Add 301 measure to workflow
    measure_subdir = 'rulesets/301EnergyRatingIndexRuleset'
    args = {}
    args['calc_type'] = run[0]
    args['hpxml_input_path'] = hpxml
    args['hpxml_output_path'] = output_hpxml
    update_args_hash(measures, measure_subdir, args)
  end

  # Add HPXML translator measure to workflow
  measure_subdir = 'hpxml-measures/HPXMLtoOpenStudio'
  args = {}
  args['hpxml_path'] = output_hpxml
  args['output_dir'] = File.absolute_path(designdir)
  args['debug'] = debug
  args['skip_validation'] = false
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
  args['include_timeseries_zone_temperatures'] = hourly_outputs.include? 'temperatures'
  args['include_timeseries_airflows'] = hourly_outputs.include? 'airflows'
  args['include_timeseries_weather'] = hourly_outputs.include? 'weather'
  update_args_hash(measures, measure_subdir, args)

  results = run_hpxml_workflow(designdir, hpxml, measures, measures_dir, debug: debug,
                                                                         print_prefix: "[#{design_name}] ")

  return output_hpxml
end

if ARGV.size == 7
  basedir = ARGV[0]
  output_dir = ARGV[1]
  run = ARGV[2].split('|').map { |x| (x.length == 0 ? nil : x) }
  resultsdir = ARGV[3]
  hpxml = ARGV[4]
  debug = (ARGV[5].downcase.to_s == 'true')
  hourly_outputs = ARGV[6].split('|')
  run_design(basedir, output_dir, run, resultsdir, hpxml, debug, hourly_outputs)
end
