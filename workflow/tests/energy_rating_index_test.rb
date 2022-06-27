# frozen_string_literal: true

require_relative '../../hpxml-measures/HPXMLtoOpenStudio/resources/minitest_helper'
require 'openstudio'
require 'openstudio/measure/ShowRunnerOutput'
require 'fileutils'
require 'csv'
require 'oga'
require_relative 'util.rb'
require_relative '../../rulesets/EnergyStarRuleset/resources/constants'
require_relative '../../hpxml-measures/HPXMLtoOpenStudio/resources/constants'
require_relative '../../hpxml-measures/HPXMLtoOpenStudio/resources/hpxml'
require_relative '../../hpxml-measures/HPXMLtoOpenStudio/resources/xmlhelper'

class EnergyRatingIndexTest < Minitest::Test
  def setup
    @test_results_dir = File.join(File.dirname(__FILE__), 'test_results')
    FileUtils.mkdir_p @test_results_dir
    @test_files_dir = File.join(File.dirname(__FILE__), 'test_files')
    FileUtils.mkdir_p @test_files_dir
  end

  def test_sample_files
    test_name = 'sample_files'
    test_results_csv = File.absolute_path(File.join(@test_results_dir, "#{test_name}.csv"))
    File.delete(test_results_csv) if File.exist? test_results_csv

    # Run simulations
    files = 'base*.xml'
    all_results = {}
    xmldir = "#{File.dirname(__FILE__)}/../sample_files"
    Dir["#{xmldir}/#{files}"].sort.each do |xml|
      rundir, _hpxmls, csvs = _run_workflow(xml, test_name)
      all_results[File.basename(xml)] = _get_csv_results([csvs[:eri_results], csvs[:co2e_results], csvs[:es_results]])

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

  def test_weather_cache
    # Move existing -cache.csv file
    weather_dir = File.join(File.dirname(__FILE__), '..', '..', 'weather')
    cache_csv = File.join(weather_dir, 'USA_CO_Denver.Intl.AP.725650_TMY3-cache.csv')
    FileUtils.mv(cache_csv, "#{cache_csv}.bak")

    command = "\"#{OpenStudio.getOpenStudioCLI}\" \"#{File.join(File.dirname(__FILE__), '..', 'energy_rating_index.rb')}\" --cache-weather"
    system(command)

    assert(File.exist?(cache_csv))

    # Restore original and cleanup
    FileUtils.mv("#{cache_csv}.bak", cache_csv)
  end

  def test_timeseries_output
    { 'hourly' => 8760,
      'daily' => 365,
      'monthly' => 12 }.each do |timeseries_frequency, n_lines|
      test_name = "#{timeseries_frequency}_output"

      # Run ERI workflow
      xml = "#{File.dirname(__FILE__)}/../sample_files/base.xml"
      _rundir, _hpxmls, csvs = _run_workflow(xml, test_name, timeseries_frequency: timeseries_frequency)

      # Check for timeseries output files
      assert(File.exist?(csvs[:rated_timeseries_results]))
      assert(File.exist?(csvs[:ref_timeseries_results]))
      assert_equal(n_lines + 2, File.read(csvs[:rated_timeseries_results]).each_line.count)
      assert_equal(n_lines + 2, File.read(csvs[:ref_timeseries_results]).each_line.count)
      assert(File.exist?(csvs[:esrat_timeseries_results]))
      assert(File.exist?(csvs[:esrd_timeseries_results]))
      assert_equal(n_lines + 2, File.read(csvs[:esrat_timeseries_results]).each_line.count)
      assert_equal(n_lines + 2, File.read(csvs[:esrd_timeseries_results]).each_line.count)
    end
  end

  def test_component_loads
    test_name = 'component_loads'

    # Run simulation
    xml = "#{File.dirname(__FILE__)}/../sample_files/base.xml"
    _rundir, _hpxmls, csvs = _run_workflow(xml, test_name, component_loads: true)

    # Check for presence of component loads
    [csvs[:rated_results], csvs[:ref_results]].each do |csv_output_path|
      component_loads = {}
      CSV.read(csv_output_path, headers: false).each do |data|
        next unless data[0].to_s.start_with? 'Component Load'

        component_loads[data[0]] = Float(data[1])
      end
      assert(component_loads.size > 0)
    end
  end

  def test_skip_simulation
    test_name = 'skip_simulation'

    # Run ERI workflow
    xml = "#{File.dirname(__FILE__)}/../sample_files/base.xml"
    _run_workflow(xml, test_name, skip_simulation: true)
  end

  def test_rated_home_only
    test_name = 'rated_home_only'

    # Run ERI workflow
    xml = "#{File.dirname(__FILE__)}/../sample_files/base.xml"
    _run_workflow(xml, test_name, rated_home_only: true)
  end

  def test_co2index_without_extra_simulation
    # Check that if we run an all-electric home, it reuses the ERI Reference Home
    # simulation results for the CO2e Reference Home, rather than running an additional
    # simulation for the CO2e Reference Home.
    test_name = 'co2index_without_extra_simulation'

    # Run ERI workflow w/ all-electric home
    xml = "#{File.dirname(__FILE__)}/../sample_files/base-hvac-air-to-air-heat-pump-1-speed.xml"
    _rundir, hpxmls, _csvs = _run_workflow(xml, test_name)

    # Check that CO2e Reference Home HPXML references ERI Reference Home
    hpxml = HPXML.new(hpxml_path: hpxmls[:co2ref])
    assert_equal(Constants.CalcTypeERIReferenceHome, hpxml.header.eri_design)

    # Run ERI workflow w/ mixed fuel home
    xml = "#{File.dirname(__FILE__)}/../sample_files/base.xml"
    _rundir, hpxmls, _csvs = _run_workflow(xml, test_name)

    # Check that CO2e Reference Home HPXML does not reference ERI Reference Home
    hpxml = HPXML.new(hpxml_path: hpxmls[:co2ref])
    assert_equal(Constants.CalcTypeCO2eReferenceHome, hpxml.header.eri_design)
  end

  def test_running_with_cli
    # Test that these tests can be run from the OpenStudio CLI (and not just system ruby)
    command = "\"#{OpenStudio.getOpenStudioCLI}\" #{File.absolute_path(__FILE__)} --name=foo"
    success = system(command)
    assert(success)
  end

  def test_release_zips
    # Check release zips successfully created
    top_dir = File.join(File.dirname(__FILE__), '..', '..')
    command = "\"#{OpenStudio.getOpenStudioCLI}\" #{File.join(top_dir, 'tasks.rb')} create_release_zips"
    system(command)
    assert_equal(2, Dir["#{top_dir}/*.zip"].size)

    # Check successful running of ERI calculation from release zips
    require 'zip'
    Zip.on_exists_proc = true
    Dir["#{top_dir}/OpenStudio-ERI*.zip"].each do |zip_path|
      Zip::File.open(zip_path) do |zip_file|
        zip_file.each do |f|
          FileUtils.mkdir_p(File.dirname(f.name)) unless File.exist?(File.dirname(f.name))
          zip_file.extract(f, f.name)
        end
      end

      # Test energy_rating_index.rb
      command = "\"#{OpenStudio.getOpenStudioCLI}\" OpenStudio-ERI/workflow/energy_rating_index.rb -x OpenStudio-ERI/workflow/sample_files/base.xml"
      system(command)
      assert(File.exist? 'OpenStudio-ERI/workflow/results/ERI_Results.csv')

      File.delete(zip_path)
      rm_path('OpenStudio-ERI')
    end
  end
end
