# frozen_string_literal: true

require_relative '../../hpxml-measures/HPXMLtoOpenStudio/resources/minitest_helper'
require 'openstudio'
require 'openstudio/measure/ShowRunnerOutput'
require 'fileutils'
require 'csv'
require 'oga'
require_relative 'util.rb'
require_relative '../../hpxml-measures/HPXMLtoOpenStudio/resources/constants'
require_relative '../../hpxml-measures/HPXMLtoOpenStudio/resources/hotwater_appliances'
require_relative '../../hpxml-measures/HPXMLtoOpenStudio/resources/hpxml'
require_relative '../../hpxml-measures/HPXMLtoOpenStudio/resources/hvac_sizing'
require_relative '../../hpxml-measures/HPXMLtoOpenStudio/resources/meta_measure'
require_relative '../../hpxml-measures/HPXMLtoOpenStudio/resources/misc_loads'
require_relative '../../hpxml-measures/HPXMLtoOpenStudio/resources/unit_conversions'
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
      rundir, hpxmls, csvs = _run_workflow(xml, test_name)
      all_results[File.basename(xml)] = _get_csv_results(csvs[:eri_results], csvs[:co2_results])

      _rm_path(rundir)
    end
    assert(all_results.size > 0)

    # Write results to csv
    keys = []
    all_results.each do |xml, xml_results|
      xml_results.keys.each do |key|
        next if keys.include? key

        keys << key
      end
    end
    CSV.open(test_results_csv, 'w') do |csv|
      csv << ['XML'] + keys
      all_results.each_with_index do |(xml, results), i|
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
    cache_csv = File.join(weather_dir, 'US_CO_Boulder_AMY_2012-cache.csv')
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
      rundir, hpxmls, csvs = _run_workflow(xml, test_name, timeseries_frequency: timeseries_frequency)

      # Check for timeseries output files
      assert(File.exist?(csvs[:rated_timeseries_results]))
      assert(File.exist?(csvs[:ref_timeseries_results]))
      assert_equal(n_lines + 2, File.read(csvs[:rated_timeseries_results]).each_line.count)
      assert_equal(n_lines + 2, File.read(csvs[:ref_timeseries_results]).each_line.count)
    end
  end

  def test_component_loads
    test_name = 'component_loads'

    # Run simulation
    xml = "#{File.dirname(__FILE__)}/../sample_files/base.xml"
    rundir, hpxmls, csvs = _run_workflow(xml, test_name, component_loads: true)

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

  def test_resnet_ashrae_140
    test_name = 'RESNET_Test_4.1_Standard_140'
    test_results_csv = File.absolute_path(File.join(@test_results_dir, "#{test_name}.csv"))
    File.delete(test_results_csv) if File.exist? test_results_csv

    # Run simulations
    xmldir = File.join(File.dirname(__FILE__), 'RESNET_Tests/4.1_Standard_140')
    all_results = []
    Dir["#{xmldir}/*.xml"].sort.each do |xml|
      _test_schema_validation(xml)
      sql_path, csv_path, sim_time = _run_simulation(xml, test_name)
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
      _check_reference_home_components(results, test_num, '2019A')
    end
  end

  def test_resnet_hers_reference_home_auto_generation_301_2019_pre_addendum_a
    all_results = _test_resnet_hers_reference_home_auto_generation('RESNET_Test_Other_HERS_AutoGen_Reference_Home_301_2019_PreAddendumA',
                                                                   'RESNET_Tests/Other_HERS_AutoGen_Reference_Home_301_2019_PreAddendumA')

    # Check results
    all_results.each do |xml, results|
      test_num = File.basename(xml)[0, 2].to_i
      _check_reference_home_components(results, test_num, '2019')
    end
  end

  def test_resnet_hers_reference_home_auto_generation_301_2014
    # Older test w/ 301-2014 mechanical ventilation acceptance criteria
    all_results = _test_resnet_hers_reference_home_auto_generation('RESNET_Test_Other_HERS_AutoGen_Reference_Home_301_2014',
                                                                   'RESNET_Tests/Other_HERS_AutoGen_Reference_Home_301_2014')

    # Check results
    all_results.each do |xml, results|
      test_num = File.basename(xml)[0, 2].to_i
      _check_reference_home_components(results, test_num, '2014')
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

  def test_resnet_hers_method
    all_results = _test_resnet_hers_method('RESNET_Test_4.3_HERS_Method',
                                           'RESNET_Tests/4.3_HERS_Method')

    # Check results
    all_results.each do |xml, results|
      test_num = File.basename(xml).gsub('L100A-', '').gsub('.xml', '').to_i
      _check_method_results(results, test_num, test_num == 2, '2019A')
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

  def test_resnet_hvac
    test_name = 'RESNET_Test_4.4_HVAC'
    test_results_csv = File.absolute_path(File.join(@test_results_dir, "#{test_name}.csv"))
    File.delete(test_results_csv) if File.exist? test_results_csv

    # Run simulations
    xmldir = File.join(File.dirname(__FILE__), 'RESNET_Tests/4.4_HVAC')
    all_results = {}
    Dir["#{xmldir}/*.xml"].sort.each do |xml|
      _test_schema_validation(xml)
      sql_path, csv_path, sim_time = _run_simulation(xml, test_name)

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
      all_results.each_with_index do |(xml, results), i|
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
      _test_schema_validation(xml)
      sql_path, csv_path, sim_time = _run_simulation(xml, test_name)

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
      all_results.each_with_index do |(xml, results), i|
        next unless ['HVAC3a.xml', 'HVAC3e.xml'].include? xml

        csv << [xml, results[0], results[1]]
        test_name = File.basename(xml, File.extname(xml))
        dhw_energy[test_name] = results[0] / 10.0 + results[1] / 293.08
      end
      all_results.each_with_index do |(xml, results), i|
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

  private

  def _test_resnet_hot_water(test_name, dir_name)
    test_results_csv = File.absolute_path(File.join(@test_results_dir, "#{test_name}.csv"))
    File.delete(test_results_csv) if File.exist? test_results_csv

    # Run simulations
    base_vals = {}
    mn_vals = {}
    all_results = {}
    xmldir = File.join(File.dirname(__FILE__), dir_name)
    Dir["#{xmldir}/*.xml"].sort.each do |xml|
      _test_schema_validation(xml)
      out_xml = File.join(@test_files_dir, File.basename(xml))
      _run_ruleset(Constants.CalcTypeERIRatedHome, xml, out_xml)
      sql_path, csv_path, sim_time = _run_simulation(out_xml, test_name)

      all_results[File.basename(xml)] = _get_hot_water(csv_path)
      assert_operator(all_results[File.basename(xml)][0], :>, 0)

      File.delete(out_xml)
    end
    assert(all_results.size > 0)

    # Write results to csv
    dhw_energy = {}
    CSV.open(test_results_csv, 'w') do |csv|
      csv << ['Test Case', 'DHW Energy (therms)', 'Recirc Pump (kWh)', 'GPD']
      all_results.each_with_index do |(xml, result), i|
        rated_dhw, rated_recirc, rated_gpd = result
        csv << [xml, (rated_dhw * 10.0).round(2), (rated_recirc * 293.08).round(2), rated_gpd.round(2)]
        test_name = File.basename(xml, File.extname(xml))
        dhw_energy[test_name] = rated_dhw + rated_recirc
      end
    end
    puts "Wrote results to #{test_results_csv}."

    return dhw_energy
  end

  def _test_resnet_hers_reference_home_auto_generation(test_name, dir_name)
    test_results_csv = File.absolute_path(File.join(@test_results_dir, "#{test_name}.csv"))
    File.delete(test_results_csv) if File.exist? test_results_csv

    # Run simulations
    all_results = {}
    xmldir = File.join(File.dirname(__FILE__), dir_name)
    Dir["#{xmldir}/*.xml"].sort.each do |xml|
      out_xml = File.join(@test_files_dir, test_name, File.basename(xml), File.basename(xml))
      _run_ruleset(Constants.CalcTypeERIReferenceHome, xml, out_xml)
      test_num = File.basename(xml)[0, 2].to_i
      all_results[File.basename(xml)] = _get_reference_home_components(out_xml, test_num)

      # Update HPXML to override mech vent fan power for eRatio test
      new_hpxml = HPXML.new(hpxml_path: out_xml)
      new_hpxml.ventilation_fans.each do |vent_fan|
        next unless vent_fan.used_for_whole_building_ventilation

        if (vent_fan.fan_type == HPXML::MechVentTypeSupply) || (vent_fan.fan_type == HPXML::MechVentTypeExhaust)
          vent_fan.fan_power = 0.35 * vent_fan.tested_flow_rate
        elsif vent_fan.fan_type == HPXML::MechVentTypeBalanced
          vent_fan.fan_power = 0.70 * vent_fan.tested_flow_rate
        elsif (vent_fan.fan_type == HPXML::MechVentTypeERV) || (vent_fan.fan_type == HPXML::MechVentTypeHRV)
          vent_fan.fan_power = 1.00 * vent_fan.tested_flow_rate
        elsif vent_fan.fan_type == HPXML::MechVentTypeCFIS
          vent_fan.fan_power = 0.50 * vent_fan.tested_flow_rate
        end
      end
      XMLHelper.write_file(new_hpxml.to_oga, out_xml)

      rundir, hpxmls, csvs = _run_workflow(out_xml, test_name)
      worksheet_results = _get_csv_results(csvs[:eri_worksheet])
      all_results[File.basename(xml)]['e-Ratio'] = worksheet_results['Total Loads TnML'] / worksheet_results['Total Loads TRL']
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

    return all_results
  end

  def _test_resnet_hers_method(test_name, dir_name)
    test_results_csv = File.absolute_path(File.join(@test_results_dir, "#{test_name}.csv"))
    File.delete(test_results_csv) if File.exist? test_results_csv

    # Run simulations
    all_results = {}
    xmldir = File.join(File.dirname(__FILE__), dir_name)
    Dir["#{xmldir}/*.xml"].sort.each do |xml|
      rundir, hpxmls, csvs = _run_workflow(xml, test_name)
      all_results[xml] = _get_csv_results(csvs[:eri_results])
      all_results[xml].delete('EC_x Dehumid (MBtu)') # Not yet included in RESNET spreadsheet
    end
    assert(all_results.size > 0)

    # Write results to csv
    keys = all_results.values[0].keys
    CSV.open(test_results_csv, 'w') do |csv|
      csv << ['Test Case'] + keys
      all_results.each_with_index do |(xml, results), i|
        csv_line = [File.basename(xml)]
        keys.each do |key|
          csv_line << results[key]
        end
        csv << csv_line
      end
    end
    puts "Wrote results to #{test_results_csv}."

    return all_results
  end
end
