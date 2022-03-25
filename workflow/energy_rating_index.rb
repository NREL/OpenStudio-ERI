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
require_relative '../hpxml-measures/HPXMLtoOpenStudio/resources/constants'
require_relative '../hpxml-measures/HPXMLtoOpenStudio/resources/hpxml'
require_relative '../hpxml-measures/HPXMLtoOpenStudio/resources/version'
require_relative '../hpxml-measures/HPXMLtoOpenStudio/resources/xmlhelper'

basedir = File.expand_path(File.dirname(__FILE__))

def get_eri_version(hpxml_path)
  hpxml_doc = XMLHelper.parse_file(hpxml_path)
  eri_version = XMLHelper.get_value(hpxml_doc, '/HPXML/SoftwareInfo/extension/ERICalculation/Version', :string)
  if eri_version.nil?
    fail 'ERICalculation/Version not specified.'
  end
  if (eri_version != 'latest') && (not Constants.ERIVersions.include?(eri_version))
    fail "Unexpected ERICalculation/Version: '#{eri_version}'."
  end

  return eri_version
end

# Check for correct versions of OS
Version.check_openstudio_version()

options = process_arguments(File.basename(__FILE__), args, basedir)

resultsdir = setup_resultsdir(options)

eri_version = get_eri_version(options[:hpxml])

# Create list of designs to run: [calc_type, HPXML, output_dir, results_dir]
runs = []
runs << [Constants.CalcTypeERIRatedHome, options[:hpxml], options[:output_dir], resultsdir]
runs << [Constants.CalcTypeERIReferenceHome, options[:hpxml], options[:output_dir], resultsdir]
if (eri_version == 'latest') || (Constants.ERIVersions.index(eri_version) >= Constants.ERIVersions.index('2014AE'))
  runs << [Constants.CalcTypeERIIndexAdjustmentDesign, options[:hpxml], options[:output_dir], resultsdir]
  runs << [Constants.CalcTypeERIIndexAdjustmentReferenceHome, options[:hpxml], options[:output_dir], resultsdir]
end
calc_co2e_index = false
if (eri_version == 'latest') || (Constants.ERIVersions.index(eri_version) >= Constants.ERIVersions.index('2019ABCD'))
  calc_co2e_index = true
end
if calc_co2e_index
  # Additional CO2e Reference Home (i.e., all-electric ERI Reference Home)
  runs << [Constants.CalcTypeCO2eReferenceHome, options[:hpxml], options[:output_dir], resultsdir]
end

run_simulations(runs, options, basedir)

design_outputs = retrieve_outputs(runs, options)
if calc_co2e_index
  # CO2e Rated Home is same as ERI Rated Home
  design_outputs[Constants.CalcTypeCO2eRatedHome] = design_outputs[Constants.CalcTypeERIRatedHome].dup
end

# Calculate and write results
if calc_co2e_index
  puts 'Calculating ERI & CO2e Index...'
else
  puts 'Calculating ERI...'
end
results = calculate_eri(design_outputs, resultsdir, eri_version: eri_version)
puts "ERI: #{results[:eri].round(2)}"
if calc_co2e_index
  if not results[:co2eindex].nil?
    puts "CO2e Index: #{results[:co2eindex].round(2)}"
  else
    puts 'CO2e Index: N/A'
  end
end

puts "Output files written to #{resultsdir}"
puts "Completed in #{(Time.now - start_time).round(1)}s."
