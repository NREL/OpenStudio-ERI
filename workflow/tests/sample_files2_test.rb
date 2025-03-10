# frozen_string_literal: true

require_relative '../../hpxml-measures/HPXMLtoOpenStudio/resources/minitest_helper'
require 'openstudio'
require 'openstudio/measure/ShowRunnerOutput'
require 'fileutils'
require 'csv'
require 'oga'
require_relative 'util.rb'
require_relative '../../rulesets/resources/constants'
require_relative '../../hpxml-measures/HPXMLtoOpenStudio/resources/constants'
require_relative '../../hpxml-measures/HPXMLtoOpenStudio/resources/hpxml'
require_relative '../../hpxml-measures/HPXMLtoOpenStudio/resources/xmlhelper'

class SampleFilesTest1 < Minitest::Test
  def setup
    @test_results_dir = File.join(File.dirname(__FILE__), 'test_results')
    FileUtils.mkdir_p @test_results_dir
    @test_files_dir = File.join(File.dirname(__FILE__), 'test_files')
    FileUtils.mkdir_p @test_files_dir
  end

  def test_sample_files
    test_name = 'sample_files2'
    test_results_csv = File.absolute_path(File.join(@test_results_dir, "#{test_name}.csv"))
    File.delete(test_results_csv) if File.exist? test_results_csv

    # Run simulations
    files = 'base*.xml'
    all_results = {}
    xmldir = "#{File.dirname(__FILE__)}/../sample_files"
    start = false
    Dir["#{xmldir}/#{files}"].sort.each do |xml|
      start = true if xml.include? 'base-hvac-air-to-air-heat-pump-1-speed.xml'
      next unless start # Run second half of the sample files

      diagnostic_output = !xml.include?('base-versions') # Don't bother testing these
      rundir, _hpxmls, csvs = _run_workflow(xml, test_name, diagnostic_output: diagnostic_output)
      all_results[File.basename(xml)] = _get_csv_results([csvs[:eri_results],
                                                          csvs[:co2e_results],
                                                          csvs[:es_results],
                                                          csvs[:zerh_results],
                                                          csvs[:iecc_eri_results]])

      _rm_path(rundir)
    end
    assert(all_results.size > 0)

    # Write results to csv
    keys = []
    all_results.values.each do |xml_results|
      xml_results.keys.each do |key|
        next if keys.include? key

        keys << key
      end
    end
    CSV.open(test_results_csv, 'w') do |csv|
      csv << ['XML'] + keys
      all_results.each do |xml, results|
        csv_line = [File.basename(xml)]
        keys.each do |key|
          csv_line << results[key]
        end
        csv << csv_line
      end
    end
    puts "Wrote results to #{test_results_csv}."
  end
end
