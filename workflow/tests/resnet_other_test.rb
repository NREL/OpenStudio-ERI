# frozen_string_literal: true

# Other RESNET tests (mostly tests for older versions of 301)

require_relative '../../hpxml-measures/HPXMLtoOpenStudio/resources/minitest_helper'
require 'openstudio'
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
      out_xml = File.join(@test_files_dir, test_name, File.basename(xml), File.basename(xml))
      _run_ruleset(Constants.CalcTypeERIIndexAdjustmentDesign, xml, out_xml)
      test_num = File.basename(xml)[0, 2].to_i
      all_results[File.basename(xml)] = _get_iad_home_components(out_xml, test_num)
    end
    assert(all_results.size > 0)

    # Write results to csv
    CSV.open(test_results_csv, 'w') do |csv|
      csv << ['Component', 'Test 1 Results', 'Test 2 Results', 'Test 3 Results', 'Test 4 Results']
      all_results['01-L100.xml'].keys.each do |component|
        csv << [component,
                all_results['01-L100.xml'][component],
                all_results['02-L100.xml'][component],
                all_results['03-L304.xml'][component],
                all_results['04-L324.xml'][component]]
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
    dhw_energy = _test_resnet_hot_water('RESNET_Test_Other_Hot_Water_301_2019_PreAddendumA',
                                        'RESNET_Tests/Other_Hot_Water_301_2019_PreAddendumA')

    # Check results
    _check_hot_water_301_2019_pre_addendum_a(dhw_energy)
  end

  def test_resnet_hot_water_301_2014_pre_addendum_a
    # Tests w/o 301-2014 Addendum A
    dhw_energy = _test_resnet_hot_water('RESNET_Test_Other_Hot_Water_301_2014_PreAddendumA',
                                        'RESNET_Tests/Other_Hot_Water_301_2014_PreAddendumA')

    # Check results
    _check_hot_water_301_2014_pre_addendum_a(dhw_energy)
  end
end
