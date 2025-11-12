# frozen_string_literal: true

# Separate ruby script to allow being called using system() on Windows.

require_relative '../hpxml-measures/HPXMLtoOpenStudio/resources/meta_measure'
require_relative '../rulesets/resources/constants'

class Design
  def initialize(run_type:, calc_type: nil, init_calc_type: nil, output_dir: nil, version: nil, output_format: 'csv')
    @run_type = run_type
    @calc_type = calc_type
    @init_calc_type = init_calc_type
    name = calc_type.to_s.gsub(' ', '')
    if not output_dir.nil?
      @output_dir = output_dir
      output_dir = File.join(output_dir, "#{run_type}_#{version}")
      if not init_calc_type.nil?
        @init_hpxml_output_path = File.join(output_dir, 'results', "#{init_calc_type.gsub(' ', '')}.xml")
        output_dir = File.join(output_dir, init_calc_type.gsub(' ', ''))
      end
      @hpxml_output_path = File.join(output_dir, 'results', "#{name}.xml")
      @annual_output_path = File.join(output_dir, 'results', "#{name}.#{output_format}")
      if [RunType::ERI, RunType::CO2e].include? run_type
        # Only need to create hourly diagnostic output file for certain runs
        @diag_output_path = File.join(output_dir, 'results', "#{name}_Diagnostic.msgpack")
      end
      @design_dir = File.join(output_dir, name)
    end
    @version = version
    @output_format = output_format
  end
  attr_accessor(:run_type, :calc_type, :init_calc_type, :init_hpxml_output_path, :hpxml_output_path, :annual_output_path,
                :diag_output_path, :output_dir, :design_dir, :version, :output_format)
end

def run_design(design, debug, timeseries_output_freq, timeseries_outputs, add_comp_loads, output_format, diagnostic_output)
  measures_dir = File.join(File.dirname(__FILE__), '..')

  measures = {}

  # Add OS-HPXML translator measure to workflow
  measure_subdir = 'hpxml-measures/HPXMLtoOpenStudio'
  args = {}
  args['hpxml_path'] = File.absolute_path(design.hpxml_output_path)
  args['output_dir'] = File.absolute_path(design.design_dir)
  args['debug'] = debug
  args['add_component_loads'] = (add_comp_loads || timeseries_outputs.include?('componentloads'))
  args['skip_validation'] = !debug
  measures[measure_subdir] = [args]

  # Add OS-HPXML reporting measure to workflow
  measure_subdir = 'hpxml-measures/ReportSimulationOutput'
  args = {}
  args['output_format'] = output_format
  args['timeseries_frequency'] = timeseries_output_freq
  args['include_timeseries_total_consumptions'] = timeseries_outputs.include? 'total'
  args['include_timeseries_fuel_consumptions'] = timeseries_outputs.include? 'fuels'
  args['include_timeseries_end_use_consumptions'] = timeseries_outputs.include? 'enduses'
  args['include_timeseries_system_use_consumptions'] = timeseries_outputs.include? 'systemuses'
  args['include_timeseries_emissions'] = timeseries_outputs.include? 'emissions'
  args['include_timeseries_emission_fuels'] = timeseries_outputs.include? 'emissionfuels'
  args['include_timeseries_emission_end_uses'] = timeseries_outputs.include? 'emissionenduses'
  args['include_timeseries_hot_water_uses'] = timeseries_outputs.include? 'hotwater'
  args['include_timeseries_total_loads'] = timeseries_outputs.include? 'loads'
  args['include_timeseries_component_loads'] = timeseries_outputs.include? 'componentloads'
  args['include_timeseries_unmet_hours'] = timeseries_outputs.include? 'unmethours'
  args['include_timeseries_zone_temperatures'] = timeseries_outputs.include? 'temperatures'
  args['include_timeseries_zone_conditions'] = timeseries_outputs.include? 'conditions'
  args['include_timeseries_airflows'] = timeseries_outputs.include? 'airflows'
  args['include_timeseries_weather'] = timeseries_outputs.include? 'weather'
  args['annual_output_file_name'] = File.join('..', 'results', File.basename(design.annual_output_path))
  args['timeseries_output_file_name'] = File.join('..', 'results', File.basename(design.annual_output_path.gsub(".#{output_format}", "_#{timeseries_output_freq.capitalize}.#{output_format}")))
  measures[measure_subdir] = [args]

  if diagnostic_output && !design.diag_output_path.nil?
    # Add OS-HPXML reporting measure to workflow
    measure_subdir = 'hpxml-measures/ReportSimulationOutput'
    args = {}
    args['output_format'] = 'msgpack'
    args['timeseries_frequency'] = 'hourly'
    args['include_annual_total_consumptions'] = false
    args['include_timeseries_end_use_consumptions'] = true
    args['include_timeseries_system_use_consumptions'] = true
    args['include_timeseries_total_loads'] = true
    args['include_timeseries_zone_temperatures'] = true
    args['include_timeseries_weather'] = true
    args['timeseries_num_decimal_places'] = 3
    args['timeseries_output_file_name'] = File.join('..', 'results', File.basename(design.diag_output_path))
    measures[measure_subdir] << args
  end

  run_hpxml_workflow(design.design_dir, measures, measures_dir, debug: debug,
                                                                suppress_print: true)
end

if ARGV.size == 11
  run_type = ARGV[0]
  calc_type = ARGV[1]
  init_calc_type = (ARGV[2].empty? ? nil : ARGV[2])
  version = (ARGV[3].empty? ? nil : ARGV[3])
  output_dir = ARGV[4]
  debug = (ARGV[5].downcase.to_s == 'true')
  timeseries_output_freq = ARGV[6]
  timeseries_outputs = ARGV[7].split('|')
  add_comp_loads = (ARGV[8].downcase.to_s == 'true')
  output_format = ARGV[9]
  diagnostic_output = (ARGV[10].downcase.to_s == 'true')
  design = Design.new(run_type: run_type, calc_type: calc_type, init_calc_type: init_calc_type, output_dir: output_dir, version: version, output_format: output_format)
  run_design(design, debug, timeseries_output_freq, timeseries_outputs, add_comp_loads, output_format, diagnostic_output)
end
