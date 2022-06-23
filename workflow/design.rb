# frozen_string_literal: true

# Separate ruby script to allow being called using system() on Windows.

require_relative '../hpxml-measures/HPXMLtoOpenStudio/resources/meta_measure'

class DesignRun
  def initialize(measures, hpxml_in_path, output_dir)
    @measures = {}
    @name = ''
    @eri_name = ''
    measures.each do |measure_name, calc_type|
      @measures[measure_name] = calc_type
      @name += '_' unless @name.empty?
      @name += calc_type.gsub(' ', '')
      @eri_name = calc_type if measure_name == '301EnergyRatingIndexRuleset'
    end
    @hpxml_in_path = hpxml_in_path
    @design_dir = File.join(output_dir, @name)
    @hpxml_out_path = File.join(output_dir, 'results', "#{@name}.xml")
    @csv_output_path = File.join(output_dir, 'results', "#{@name}.csv")
    @output_dir = output_dir
  end
  attr_accessor(:name, :measures, :hpxml_in_path, :output_dir, :eri_name,
                :design_dir, :hpxml_out_path, :csv_output_path)
end

def run_design(run, debug, timeseries_output_freq, timeseries_outputs, add_comp_loads, skip_simulation)
  measures_dir = File.join(File.dirname(__FILE__), '..')

  measures = {}

  input_hpxml = run.hpxml_in_path
  output_hpxml = run.hpxml_out_path

  run.measures.each do |measure_name, calc_type|
    # Add ruleset measure to workflow
    measure_subdir = "rulesets/#{measure_name}"
    args = {}
    args['calc_type'] = calc_type
    args['hpxml_input_path'] = input_hpxml
    args['hpxml_output_path'] = output_hpxml
    update_args_hash(measures, measure_subdir, args)
    input_hpxml = output_hpxml # Output of last measure is input for new next measure
  end

  if not skip_simulation
    # Add OS-HPXML translator measure to workflow
    measure_subdir = 'hpxml-measures/HPXMLtoOpenStudio'
    args = {}
    args['hpxml_path'] = output_hpxml
    args['output_dir'] = File.absolute_path(run.design_dir)
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
  end

  print_prefix = "[#{run.name}] "

  run_hpxml_workflow(run.design_dir, measures, measures_dir, debug: debug, print_prefix: print_prefix,
                                                             run_measures_only: skip_simulation)
end

if ARGV.size == 8
  run = DesignRun.new(eval(ARGV[0]), ARGV[1], ARGV[2])
  debug = (ARGV[3].downcase.to_s == 'true')
  timeseries_output_freq = ARGV[4]
  timeseries_outputs = ARGV[5].split('|')
  add_comp_loads = (ARGV[6].downcase.to_s == 'true')
  skip_simulation = (ARGV[7].downcase.to_s == 'true')
  run_design(run, debug, timeseries_output_freq, timeseries_outputs, add_comp_loads, skip_simulation)
end
