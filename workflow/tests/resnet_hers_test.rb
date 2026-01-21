# frozen_string_literal: true

# Current official RESNET HERS tests

require 'openstudio'
require_relative '../../hpxml-measures/HPXMLtoOpenStudio/resources/minitest_helper'
require_relative '../../hpxml-measures/workflow/tests/util.rb'
require 'fileutils'
require 'csv'
require 'oga'
require_relative 'util.rb'

class RESNETTest < Minitest::Test
  def setup
    @test_results_dir = File.join(File.dirname(__FILE__), 'test_results')
    FileUtils.mkdir_p @test_results_dir
    @test_files_dir = File.join(File.dirname(__FILE__), 'test_files')
    FileUtils.mkdir_p @test_files_dir
  end

  def test_resnet_ashrae_140
    test_name = 'RESNET_Test_4.1_Standard_140'
    test_results_csv = File.absolute_path(File.join(@test_results_dir, "#{test_name}.csv"))
    File.delete(test_results_csv) if File.exist? test_results_csv

    # Run simulations
    xmldir = File.join(File.dirname(__FILE__), 'RESNET_Tests/4.1_Standard_140')
    all_results = {}
    Dir["#{xmldir}/*.xml"].sort.each do |xml|
      csv_path = _run_simulation(xml, test_name)
      results = _get_csv_results([csv_path])
      htg_load, clg_load = _get_simulation_load_results(results)
      xml = File.basename(xml)
      if xml.include? 'C.xml'
        all_results[xml] = [htg_load, 'N/A']
        assert_operator(htg_load, :>, 0)
      elsif xml.include? 'L.xml'
        all_results[xml] = ['N/A', clg_load]
        assert_operator(clg_load, :>, 0)
      end
    end
    assert(all_results.size > 0)

    htg_loads, clg_loads = _write_ashrae_140_results(all_results, test_results_csv)

    # Check results if we have them all
    if all_results.size > 1
      _check_ashrae_140_results(htg_loads, clg_loads)
    end
  end

  def test_resnet_hers_reference_home_auto_generation
    version = '2022C' # Latest version that caused changes to results
    all_results = _test_resnet_hers_reference_home_auto_generation('RESNET_Test_4.2_HERS_AutoGen_Reference_Home',
                                                                   'RESNET_Tests/4.2_HERS_AutoGen_Reference_Home',
                                                                   version)

    # Check results
    all_results.each do |xml, results|
      test_num = File.basename(xml)[0, 2].to_i
      _check_reference_home_components(results, test_num, version)
    end
  end

  def test_resnet_hers_method
    version = '2019A' # Latest version that caused changes to results
    all_results = _test_resnet_hers_method('RESNET_Test_4.3_HERS_Method',
                                           'RESNET_Tests/4.3_HERS_Method')

    # Check results
    all_results.each do |xml, results|
      test_num = File.basename(xml).gsub('L100A-', '').gsub('.xml', '').to_i
      _check_method_results(results, test_num, test_num == 2, version)
    end
  end

  def test_resnet_hvac
    test_name = 'RESNET_Test_4.4_HVAC'
    test_results_csv = File.absolute_path(File.join(@test_results_dir, "#{test_name}.csv"))
    File.delete(test_results_csv) if File.exist? test_results_csv

    # Run simulations
    xmldir = File.join(File.dirname(__FILE__), 'RESNET_Tests/4.4_HVAC')
    all_results = {}
    Dir["#{xmldir}/*.xml"].sort.each do |xml|
      csv_path = _run_simulation(xml, test_name)

      is_heat = false
      if xml.include? 'HVAC2'
        is_heat = true
      end
      is_electric_heat = true
      if xml.include?('HVAC2a') || xml.include?('HVAC2b')
        is_electric_heat = false
      end
      results = _get_csv_results([csv_path])
      all_results[File.basename(xml)] = _get_simulation_hvac_energy_results(results, is_heat, is_electric_heat)
    end
    assert(all_results.size > 0)

    hvac_energy = _write_hers_hvac_results(all_results, test_results_csv)

    # Check result if we have them all
    if all_results.size > 1
      _check_hvac_test_results(hvac_energy)
    end
  end

  def test_resnet_dse
    test_name = 'RESNET_Test_4.5_DSE'
    test_results_csv = File.absolute_path(File.join(@test_results_dir, "#{test_name}.csv"))
    File.delete(test_results_csv) if File.exist? test_results_csv

    # Run simulations
    xmldir = File.join(File.dirname(__FILE__), 'RESNET_Tests/4.5_DSE')
    all_results = {}
    Dir["#{xmldir}/*.xml"].sort.each do |xml|
      csv_path = _run_simulation(xml, test_name)

      is_heat = false
      if ['HVAC3a.xml', 'HVAC3b.xml', 'HVAC3c.xml', 'HVAC3d.xml'].include? File.basename(xml)
        is_heat = true
      end
      is_electric_heat = false
      results = _get_csv_results([csv_path])
      all_results[File.basename(xml)] = _get_simulation_hvac_energy_results(results, is_heat, is_electric_heat)
    end
    assert(all_results.size > 0)

    dse_energy = _write_hers_dse_results(all_results, test_results_csv)

    # Check results if we have them all
    if all_results.size > 1
      _check_dse_test_results(dse_energy)
    end
  end

  def test_resnet_hot_water
    test_name = 'RESNET_Test_4.6_Hot_Water'
    test_results_csv = File.absolute_path(File.join(@test_results_dir, "#{test_name}.csv"))
    File.delete(test_results_csv) if File.exist? test_results_csv

    # Run simulations
    all_results = {}
    xmldir = File.join(File.dirname(__FILE__), 'RESNET_Tests/4.6_Hot_Water')
    Dir["#{xmldir}/*.xml"].sort.each do |xml|
      csv_path = _run_simulation(xml, test_name)

      results = _get_csv_results([csv_path])
      all_results[File.basename(xml)] = _get_simulation_hot_water_results(results)
      assert_operator(all_results[File.basename(xml)][0], :>, 0)
    end
    assert(all_results.size > 0)

    dhw_energy = _write_hers_hot_water_results(all_results, test_results_csv)

    # Check results if we have them all
    if all_results.size > 1
      _check_hot_water(dhw_energy)
    end
  end

  def test_resnet_multi_climate
    test_name = 'RESNET_Test_4.7_Multi_Climate'
    test_results_csv = File.absolute_path(File.join(@test_results_dir, "#{test_name}.csv"))
    File.delete(test_results_csv) if File.exist? test_results_csv

    # Run simulations
    all_results = {}
    xmldir = File.join(File.dirname(__FILE__), 'RESNET_Tests/4.7_Multi_Climate')
    Dir["#{xmldir}/*.xml"].sort.each do |xml|
      _rundir, _hpxmls, csvs = _run_workflow(xml, test_name)
      all_results[xml] = _get_csv_results([csvs[:eri_results]])
    end
    assert(all_results.size > 0)

    # Write results to csv
    keys = all_results.values[0].keys
    CSV.open(test_results_csv, 'w') do |csv|
      csv << ['Test Case'] + keys
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
