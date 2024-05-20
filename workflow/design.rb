# frozen_string_literal: true

# Separate ruby script to allow being called using system() on Windows.

pust "START design.rb"
require_relative '../hpxml-measures/HPXMLtoOpenStudio/resources/meta_measure'

class Design
  def initialize(calc_type: nil, init_calc_type: nil, output_dir: nil, iecc_version: nil, output_format: 'csv')
    @calc_type = calc_type
    @init_calc_type = init_calc_type
    name = calc_type.to_s.gsub(' ', '')
    if not iecc_version.nil?
      name = name.gsub('ERI', 'IECC_ERI')
    end
    if not init_calc_type.nil?
      name = init_calc_type.gsub(' ', '') + '_' + name
    end
    if not output_dir.nil?
      @output_dir = output_dir
      @hpxml_output_path = File.join(output_dir, 'results', "#{name}.xml")
      @annual_output_path = File.join(output_dir, 'results', "#{name}.#{output_format}")
      @design_dir = File.join(output_dir, name)
      if not init_calc_type.nil?
        @init_hpxml_output_path = File.join(output_dir, 'results', "#{init_calc_type.gsub(' ', '')}.xml")
      end
    end
    @iecc_version = iecc_version
    @output_format = output_format
  end
  attr_accessor(:calc_type, :init_calc_type, :init_hpxml_output_path, :hpxml_output_path, :annual_output_path,
                :output_dir, :design_dir, :iecc_version, :output_format)
end

def run_design(design, debug, timeseries_output_freq, timeseries_outputs, add_comp_loads, output_format)
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
  args['include_timeseries_airflows'] = timeseries_outputs.include? 'airflows'
  args['include_timeseries_weather'] = timeseries_outputs.include? 'weather'
  args['annual_output_file_name'] = File.join('..', 'results', File.basename(design.annual_output_path))
  args['timeseries_output_file_name'] = File.join('..', 'results', File.basename(design.annual_output_path.gsub(".#{output_format}", "_#{timeseries_output_freq.capitalize}.#{output_format}")))
  update_args_hash(measures, measure_subdir, args)

  run_hpxml_workflow(design.design_dir, measures, measures_dir, debug: debug,
                                                                suppress_print: true)
end

if ARGV.size == 9
  puts ARGV.to_s
  calc_type = ARGV[0]
  init_calc_type = (ARGV[1].empty? ? nil : ARGV[1])
  iecc_version = (ARGV[2].empty? ? nil : ARGV[2])
  output_dir = ARGV[3]
  debug = (ARGV[4].downcase.to_s == 'true')
  timeseries_output_freq = ARGV[5]
  timeseries_outputs = ARGV[6].split('|')
  add_comp_loads = (ARGV[7].downcase.to_s == 'true')
  output_format = ARGV[8]
  design = Design.new(calc_type: calc_type, init_calc_type: init_calc_type, output_dir: output_dir, iecc_version: iecc_version, output_format: output_format)
  run_design(design, debug, timeseries_output_freq, timeseries_outputs, add_comp_loads, output_format)
end
puts "END design.rb"
