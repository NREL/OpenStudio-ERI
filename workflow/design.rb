# frozen_string_literal: true

# Separate ruby script to allow being called using system() on Windows.

require_relative '../hpxml-measures/HPXMLtoOpenStudio/resources/meta_measure'

class Design
  def initialize(calc_type:, init_calc_type: nil, output_dir:)
    @calc_type = calc_type
    @init_calc_type = init_calc_type
    @output_dir = output_dir
    name = calc_type.gsub(' ', '')
    if not init_calc_type.nil?
      name = init_calc_type.gsub(' ', '') + '_' + name
    end
    @hpxml_output_path = File.join(output_dir, 'results', "#{name}.xml")
    @csv_output_path = File.join(output_dir, 'results', "#{name}.csv")
    @design_dir = File.join(output_dir, name)
  end
  attr_accessor(:calc_type, :init_calc_type, :hpxml_output_path, :csv_output_path,
                :output_dir, :design_dir)
end

def run_design(design, debug, timeseries_output_freq, timeseries_outputs, add_comp_loads,
               design_num, num_designs)
  measures_dir = File.join(File.dirname(__FILE__), '..')

  measures = {}

  # Add OS-HPXML translator measure to workflow
  measure_subdir = 'hpxml-measures/HPXMLtoOpenStudio'
  args = {}
  args['hpxml_path'] = design.hpxml_output_path
  args['output_dir'] = File.absolute_path(design.design_dir)
  args['debug'] = debug
  args['add_component_loads'] = (add_comp_loads || timeseries_outputs.include?('componentloads'))
  args['skip_validation'] = !debug
  update_args_hash(measures, measure_subdir, args)

  # Add OS-HPXML reporting measure to workflow
  measure_subdir = 'hpxml-measures/ReportSimulationOutput'
  args = {}
  args['timeseries_frequency'] = timeseries_output_freq
  args['include_timeseries_total_consumptions'] = timeseries_outputs.include? 'total'
  args['include_timeseries_fuel_consumptions'] = timeseries_outputs.include? 'fuels'
  args['include_timeseries_end_use_consumptions'] = timeseries_outputs.include? 'enduses'
  args['include_timeseries_emissions'] = timeseries_outputs.include? 'emissions'
  args['include_timeseries_emission_fuels'] = timeseries_outputs.include? 'emissionfuels'
  args['include_timeseries_emission_end_uses'] = timeseries_outputs.include? 'emissionenduses'
  args['include_timeseries_hot_water_uses'] = timeseries_outputs.include? 'hotwater'
  args['include_timeseries_total_loads'] = timeseries_outputs.include? 'loads'
  args['include_timeseries_component_loads'] = timeseries_outputs.include? 'componentloads'
  args['include_timeseries_unmet_hours'] = timeseries_outputs.include? 'unmethours'
  args['include_timeseries_zone_temperatures'] = timeseries_outputs.include? 'temperatures'
  args['include_timeseries_airflows'] = timeseries_outputs.include? 'airflows'
  args['include_timeseries_weather'] = timeseries_outputs.include? 'weather'
  update_args_hash(measures, measure_subdir, args)

  print "[#{design_num}/#{num_designs}] Running #{File.basename(design.hpxml_output_path)}...\n"
  run_hpxml_workflow(design.design_dir, measures, measures_dir, debug: debug,
                                                                suppress_print: true)
end

if ARGV.size == 9
  calc_type = ARGV[0]
  init_calc_type = (ARGV[1].empty? ? nil : ARGV[1])
  output_dir = ARGV[2]
  design = Design.new(calc_type: calc_type, init_calc_type: init_calc_type, output_dir: output_dir)
  debug = (ARGV[3].downcase.to_s == 'true')
  timeseries_output_freq = ARGV[4]
  timeseries_outputs = ARGV[5].split('|')
  add_comp_loads = (ARGV[6].downcase.to_s == 'true')
  design_num = ARGV[7].to_i
  num_designs = ARGV[8].to_i
  run_design(design, debug, timeseries_output_freq, timeseries_outputs, add_comp_loads,
             design_num, num_designs)
end
