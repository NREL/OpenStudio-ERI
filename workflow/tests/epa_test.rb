# frozen_string_literal: true

require_relative '../../hpxml-measures/HPXMLtoOpenStudio/resources/minitest_helper'
require 'openstudio'
require 'openstudio/measure/ShowRunnerOutput'
require 'fileutils'
require 'csv'
require_relative 'util.rb'

class EPATest < Minitest::Test
  def setup
    @test_results_dir = File.join(File.dirname(__FILE__), 'test_results')
    FileUtils.mkdir_p @test_results_dir
    @test_files_dir = File.join(File.dirname(__FILE__), 'test_files')
    FileUtils.mkdir_p @test_files_dir
  end

  def test_epa
    test_name = 'EPA_Tests'
    test_results_csv = File.absolute_path(File.join(@test_results_dir, "#{test_name}.csv"))
    File.delete(test_results_csv) if File.exist? test_results_csv

    # Run simulations
    xmldir = File.join(File.dirname(__FILE__), 'EPA_Tests')
    all_results = {}
    Dir["#{xmldir}/**/*.xml"].sort.each do |xml|
      _rundir, _hpxmls, csvs = _run_workflow(xml, test_name)
      esrd_results = _get_csv_results([csvs[:esrd_eri_results]])
      esrat_results = _get_csv_results([csvs[:esrat_eri_results]])

      all_results[xml] = {}
      all_results[xml]['Reference Home ERI'] = esrd_results['ERI']
      all_results[xml]['Rated Home ERI'] = esrat_results['ERI']
    end
    assert(all_results.size > 0)

    # Write results to csv
    keys = all_results.values[0].keys
    CSV.open(test_results_csv, 'w') do |csv|
      csv << ['[Version] XML'] + keys
      all_results.each do |xml, results|
        es_version = xml.split('/')[-2]
        csv_line = ["[#{es_version}] #{File.basename(xml)}"]
        keys.each do |key|
          csv_line << results[key]
        end
        csv << csv_line
      end
    end
    puts "Wrote results to #{test_results_csv}."

    # Check ERI scores are equal for manually configured test homes (from EPA) and auto-generated ESRDs
    all_results.values.each do |results|
      assert_equal(results['Reference Home ERI'], results['Rated Home ERI'])
    end
  end
end
