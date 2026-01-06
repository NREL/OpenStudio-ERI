# frozen_string_literal: true

# Other RESNET tests (mostly tests for older versions of 301)

require 'openstudio'
require_relative '../../hpxml-measures/HPXMLtoOpenStudio/resources/minitest_helper'
require_relative '../../hpxml-measures/workflow/tests/util.rb'
require 'openstudio/measure/ShowRunnerOutput'
require 'fileutils'
require 'csv'
require 'oga'
require_relative 'util.rb'

class RESNETOtherTest < Minitest::Test
  def setup
    @test_results_dir = File.join(File.dirname(__FILE__), 'test_results')
    FileUtils.mkdir_p @test_results_dir
    @test_files_dir = File.join(File.dirname(__FILE__), 'test_files')
    FileUtils.mkdir_p @test_files_dir
  end

  def test_resnet_hers_reference_home_auto_generation_301_2019_pre_addendum_a
    version = '2019'
    all_results = _test_resnet_hers_reference_home_auto_generation('RESNET_Test_Other_HERS_AutoGen_Reference_Home_301_2019_PreAddendumA',
                                                                   'RESNET_Tests/Other_HERS_AutoGen_Reference_Home_301_2019_PreAddendumA',
                                                                   version)

    # Check results
    all_results.each do |xml, results|
      test_num = File.basename(xml)[0, 2].to_i
      _check_reference_home_components(results, test_num, version)
    end
  end

  def test_resnet_hers_reference_home_auto_generation_301_2014
    # Older test w/ 301-2014 mechanical ventilation acceptance criteria
    version = '2014'
    all_results = _test_resnet_hers_reference_home_auto_generation('RESNET_Test_Other_HERS_AutoGen_Reference_Home_301_2014',
                                                                   'RESNET_Tests/Other_HERS_AutoGen_Reference_Home_301_2014',
                                                                   version)

    # Check results
    all_results.each do |xml, results|
      test_num = File.basename(xml)[0, 2].to_i
      _check_reference_home_components(results, test_num, version)
    end
  end

  def test_resnet_hers_iad_home_auto_generation
    test_name = 'RESNET_Test_Other_HERS_AutoGen_IAD_Home'
    test_results_csv = File.absolute_path(File.join(@test_results_dir, "#{test_name}.csv"))
    File.delete(test_results_csv) if File.exist? test_results_csv

    # Run simulations
    all_results = {}
    xmldir = File.join(File.dirname(__FILE__), 'RESNET_Tests/Other_HERS_AutoGen_IAD_Home')
    Dir["#{xmldir}/*.xml"].sort.each do |xml|
      _rundir, hpxmls, _csvs = _run_workflow(xml, test_name, skip_simulation: true)
      test_num = File.basename(xml)[0, 2].to_i
      all_results[File.basename(xml)] = _get_iad_home_components(hpxmls[:iad], test_num)
    end
    assert(all_results.size > 0)

    # Write results to CSV
    CSV.open(test_results_csv, 'w') do |csv|
      # Write the header row with filenames
      header = ['Component'] + all_results.keys
      csv << header

      # Dynamically get the first file's components
      first_file = all_results.keys.first

      # Iterate over the components in the first file
      all_results[first_file].keys.each do |component|
        # Gather results from all files for the current component
        row = [component] + all_results.keys.map { |file| all_results[file][component] }
        csv << row
      end
    end
    puts "Wrote results to #{test_results_csv}."

    # Check results
    all_results.each do |xml, results|
      test_num = File.basename(xml)[0, 2].to_i
      _check_iad_home_components(results, test_num)
    end
  end

  def test_resnet_hers_method_301_2019_pre_addendum_a
    all_results = _test_resnet_hers_method('RESNET_Test_Other_HERS_Method_301_2019_PreAddendumA',
                                           'RESNET_Tests/Other_HERS_Method_301_2019_PreAddendumA')

    # Check results
    all_results.each do |xml, results|
      test_num = File.basename(xml).gsub('L100A-', '').gsub('.xml', '').to_i
      _check_method_results(results, test_num, test_num == 2, '2019')
    end
  end

  def test_resnet_hers_method_301_2014_pre_addendum_e
    # Tests before 301-2019 Addendum E (IAF) was in place
    all_results = _test_resnet_hers_method('RESNET_Test_Other_HERS_Method_301_2014_PreAddendumE',
                                           'RESNET_Tests/Other_HERS_Method_301_2014_PreAddendumE')

    # Check results
    all_results.each do |xml, results|
      test_num = File.basename(xml).gsub('L100A-', '').gsub('.xml', '').to_i
      _check_method_results(results, test_num, test_num == 2, '2014')
    end
  end

  def test_resnet_hot_water_301_2019_pre_addendum_a
    # Tests w/o 301-2019 Addendum A
    test_name = 'RESNET_Test_Other_Hot_Water_301_2019_PreAddendumA'
    test_results_csv = File.absolute_path(File.join(@test_results_dir, "#{test_name}.csv"))
    File.delete(test_results_csv) if File.exist? test_results_csv

    # Run simulations
    all_results = {}
    xmldir = File.join(File.dirname(__FILE__), 'RESNET_Tests/Other_Hot_Water_301_2019_PreAddendumA')
    Dir["#{xmldir}/*.xml"].sort.each do |xml|
      csv_path = _run_simulation(xml, test_name)

      results = _get_csv_results([csv_path])
      all_results[File.basename(xml)] = _get_simulation_hot_water_results(results)
      assert_operator(all_results[File.basename(xml)][0], :>, 0)
    end
    assert(all_results.size > 0)

    dhw_energy = _write_hers_hot_water_results(all_results, test_results_csv)

    # Check results
    _check_hot_water_301_2019_pre_addendum_a(dhw_energy)
  end

  def test_resnet_hot_water_301_2014_pre_addendum_a
    # Tests w/o 301-2014 Addendum A
    test_name = 'RESNET_Test_Other_Hot_Water_301_2014_PreAddendumA'
    test_results_csv = File.absolute_path(File.join(@test_results_dir, "#{test_name}.csv"))
    File.delete(test_results_csv) if File.exist? test_results_csv

    # Run simulations
    all_results = {}
    xmldir = File.join(File.dirname(__FILE__), 'RESNET_Tests/Other_Hot_Water_301_2014_PreAddendumA')
    Dir["#{xmldir}/*.xml"].sort.each do |xml|
      csv_path = _run_simulation(xml, test_name)

      results = _get_csv_results([csv_path])
      all_results[File.basename(xml)] = _get_simulation_hot_water_results(results)
      assert_operator(all_results[File.basename(xml)][0], :>, 0)
    end
    assert(all_results.size > 0)

    dhw_energy = _write_hers_hot_water_results(all_results, test_results_csv)

    # Check results
    _check_hot_water_301_2014_pre_addendum_a(dhw_energy)
  end
end
