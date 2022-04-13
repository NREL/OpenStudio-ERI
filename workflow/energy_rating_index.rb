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

def get_eri_version(hpxml_doc)
  eri_version = XMLHelper.get_value(hpxml_doc, '/HPXML/SoftwareInfo/extension/ERICalculation/Version', :string)
  if eri_version.nil?
    fail 'ERICalculation/Version not specified.'
  end
  if (eri_version != 'latest') && (not Constants.ERIVersions.include?(eri_version))
    fail "Unexpected ERICalculation/Version: '#{eri_version}'."
  end

  return eri_version
end

def is_eri_ref_all_electric(hpxml_doc)
  ['HeatingSystemFuel',
   'CoolingSystemFuel',
   'HeatPumpFuel',
   'BackupSystemFuel',
   'FuelType'].each do |fuel_name|
    if XMLHelper.has_element(hpxml_doc, "//#{fuel_name}[text() != 'electricity']")
      return false
    end
  end
  if not XMLHelper.has_element(hpxml_doc, '//HeatingSystem | //HeatPump')
    # No heating system, ERI Reference will get gas furnace
    return false
  end

  return true
end

def duplicate_output_files(eri_ref_home_run, co2_ref_home_run, resultsdir)
  # Duplicate E+ output directory
  FileUtils.cp_r(get_design_dir(eri_ref_home_run), get_design_dir(co2_ref_home_run))

  # Duplicate results files
  eri_ref_home_filename = get_output_filename(eri_ref_home_run, '')
  co2_ref_home_filename = get_output_filename(co2_ref_home_run, '')
  Dir["#{resultsdir}/*.*"].each do |results_file|
    next unless results_file.start_with? eri_ref_home_filename

    FileUtils.cp(results_file, results_file.gsub(eri_ref_home_filename, co2_ref_home_filename))
  end
end

# Check for correct versions of OS
Version.check_openstudio_version()

options = process_arguments(File.basename(__FILE__), args, basedir)

resultsdir = setup_resultsdir(options)

hpxml_doc = XMLHelper.parse_file(options[:hpxml])
eri_version = get_eri_version(hpxml_doc)

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
  # All-electric ERI Reference Home
  eri_ref_home_is_electric = is_eri_ref_all_electric(hpxml_doc)
  co2_ref_home_run = [Constants.CalcTypeCO2eReferenceHome, options[:hpxml], options[:output_dir], resultsdir]
  if not eri_ref_home_is_electric
    # Additional CO2e Reference Home run only needed if different than ERI Reference Home
    runs << co2_ref_home_run
  end
end

run_simulations(runs, options, basedir)

if not options[:skip_simulation]
  design_outputs = retrieve_outputs(runs, options)
  if calc_co2e_index
    # CO2e Rated Home is same as ERI Rated Home
    design_outputs[Constants.CalcTypeCO2eRatedHome] = design_outputs[Constants.CalcTypeERIRatedHome].dup
    if eri_ref_home_is_electric
      design_outputs[Constants.CalcTypeCO2eReferenceHome] = design_outputs[Constants.CalcTypeERIReferenceHome].dup

      # Duplicate output files too
      eri_ref_home_run = runs.select { |r| r[0] == Constants.CalcTypeERIReferenceHome }[0]
      duplicate_output_files(eri_ref_home_run, co2_ref_home_run, resultsdir)
    end
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
end

puts "Output files written to #{resultsdir}"
puts "Completed in #{(Time.now - start_time).round(1)}s."
