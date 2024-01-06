# frozen_string_literal: true

# Current official RESNET HERS tests

require_relative '../../hpxml-measures/HPXMLtoOpenStudio/resources/minitest_helper'
require 'openstudio'
require 'openstudio/measure/ShowRunnerOutput'
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
    all_results = []
    Dir["#{xmldir}/*.xml"].sort.each do |xml|
      csv_path = _run_simulation(xml, test_name)
      htg_load, clg_load = _get_simulation_load_results(csv_path)
      xml = File.basename(xml)
      if xml.include? 'C.xml'
        all_results << [xml, htg_load, 'N/A']
        assert_operator(htg_load, :>, 0)
      elsif xml.include? 'L.xml'
        all_results << [xml, 'N/A', clg_load]
        assert_operator(clg_load, :>, 0)
      end
    end
    assert(all_results.size > 0)

    # Write results to csv
    htg_loads = {}
    clg_loads = {}
    CSV.open(test_results_csv, 'w') do |csv|
      csv << ['Test', 'Annual Heating Load [MMBtu]', 'Annual Cooling Load [MMBtu]']
      all_results.each do |results|
        next unless results[0].include? 'C.xml'

        csv << results
        test_name = File.basename(results[0], File.extname(results[0]))
        htg_loads[test_name] = results[1]
      end
      all_results.each do |results|
        next unless results[0].include? 'L.xml'

        csv << results
        test_name = File.basename(results[0], File.extname(results[0]))
        clg_loads[test_name] = results[2]
      end
    end
    puts "Wrote results to #{test_results_csv}."

    # Check results
    _check_ashrae_140_results(htg_loads, clg_loads)
  end

  def test_resnet_hers_reference_home_auto_generation
    all_results = _test_resnet_hers_reference_home_auto_generation('RESNET_Test_4.2_HERS_AutoGen_Reference_Home',
                                                                   'RESNET_Tests/4.2_HERS_AutoGen_Reference_Home')

    # Check results
    all_results.each do |xml, results|
      test_num = File.basename(xml)[0, 2].to_i
      _check_reference_home_components(results, test_num, '2022')
    end
  end

  def test_resnet_hers_method
    all_results = _test_resnet_hers_method('RESNET_Test_4.3_HERS_Method',
                                           'RESNET_Tests/4.3_HERS_Method')

    # Check results
    all_results.each do |xml, results|
      test_num = File.basename(xml).gsub('L100A-', '').gsub('.xml', '').to_i
      _check_method_results(results, test_num, test_num == 2, '2019A')
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
      hvac, hvac_fan = _get_simulation_hvac_energy_results(csv_path, is_heat, is_electric_heat)
      all_results[File.basename(xml)] = [hvac, hvac_fan]
    end
    assert(all_results.size > 0)

    # Write results to csv
    hvac_energy = {}
    CSV.open(test_results_csv, 'w') do |csv|
      csv << ['Test Case', 'HVAC (kWh or therm)', 'HVAC Fan (kWh)']
      all_results.each do |xml, results|
        csv << [xml, results[0], results[1]]
        test_name = File.basename(xml, File.extname(xml))
        if xml.include?('HVAC2a') || xml.include?('HVAC2b')
          hvac_energy[test_name] = results[0] / 10.0 + results[1] / 293.08
        else
          hvac_energy[test_name] = results[0] + results[1]
        end
      end
    end
    puts "Wrote results to #{test_results_csv}."

    # Check results
    _check_hvac_test_results(hvac_energy)
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
      hvac, hvac_fan = _get_simulation_hvac_energy_results(csv_path, is_heat, is_electric_heat)
      all_results[File.basename(xml)] = [hvac, hvac_fan]
    end
    assert(all_results.size > 0)

    # Write results to csv
    dhw_energy = {}
    CSV.open(test_results_csv, 'w') do |csv|
      csv << ['Test Case', 'Heat/Cool (kWh or therm)', 'HVAC Fan (kWh)']
      all_results.each do |xml, results|
        next unless ['HVAC3a.xml', 'HVAC3e.xml'].include? xml

        csv << [xml, results[0], results[1]]
        test_name = File.basename(xml, File.extname(xml))
        dhw_energy[test_name] = results[0] / 10.0 + results[1] / 293.08
      end
      all_results.each do |xml, results|
        next if ['HVAC3a.xml', 'HVAC3e.xml'].include? xml

        csv << [xml, results[0], results[1]]
        test_name = File.basename(xml, File.extname(xml))
        dhw_energy[test_name] = results[0] / 10.0 + results[1] / 293.08
      end
    end
    puts "Wrote results to #{test_results_csv}."

    # Check results
    _check_dse_test_results(dhw_energy)
  end

  def test_resnet_hot_water
    dhw_energy = _test_resnet_hot_water('RESNET_Test_4.6_Hot_Water',
                                        'RESNET_Tests/4.6_Hot_Water')

    # Check results
    _check_hot_water(dhw_energy)
  end
end
