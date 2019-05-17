require_relative 'minitest_helper'
require 'openstudio'
require 'openstudio/ruleset/ShowRunnerOutput'
require 'minitest/autorun'
require 'fileutils'
require 'csv'
require_relative '../../measures/HPXMLtoOpenStudio/measure'
require_relative '../../measures/HPXMLtoOpenStudio/resources/xmlhelper'
require_relative '../../measures/HPXMLtoOpenStudio/resources/schedules'
require_relative '../../measures/HPXMLtoOpenStudio/resources/constants'
require_relative '../../measures/HPXMLtoOpenStudio/resources/unit_conversions'
require_relative '../../measures/HPXMLtoOpenStudio/resources/hotwater_appliances'

class EnergyRatingIndexTest < Minitest::Test
  def before_setup
    @test_results_dir = File.join(File.dirname(__FILE__), "test_results")
    FileUtils.mkdir_p @test_results_dir
  end

  def test_sample_files
    test_results_csv = File.absolute_path(File.join(@test_results_dir, "sample_files.csv"))
    File.delete(test_results_csv) if File.exists? test_results_csv

    this_dir = File.absolute_path(File.join(File.dirname(__FILE__), ".."))

    # Run simulations
    files = "base*.xml"
    all_results = {}
    xmldir = "#{this_dir}/sample_files"
    Dir["#{xmldir}/#{files}"].sort.each do |xml|
      hpxmls, results_csv, runtime = run_eri_and_check(xml, this_dir)
      all_results[File.basename(xml)] = _get_method_results(results_csv)
      all_results[File.basename(xml)]["Workflow Runtime (s)"] = runtime
    end
    assert(all_results.size > 0)

    # Write results to csv
    keys = all_results.values[0].keys
    CSV.open(test_results_csv, "w") do |csv|
      csv << ["XML"] + keys
      all_results.each_with_index do |(xml, results), i|
        csv_line = [File.basename(xml)]
        keys.each do |key|
          csv_line << results[key]
        end
        csv << csv_line
      end
    end
    puts "Wrote results to #{test_results_csv}."

    # Cross-simulation tests

    # Verify that REUL Hot Water is identical across water heater types
    base_results = all_results["base.xml"]
    compare_xmls = ["base-dhw-tank-gas.xml",
                    "base-dhw-tank-oil.xml",
                    "base-dhw-tank-propane.xml",
                    "base-dhw-tank-heat-pump.xml",
                    "base-dhw-tankless-electric.xml",
                    "base-dhw-tankless-gas.xml",
                    "base-dhw-multiple.xml"]
    if not base_results.nil?
      base_reul_dhw = base_results["REUL Hot Water (MBtu)"]
      compare_xmls.each do |compare_xml|
        compare_results = all_results[compare_xml]
        next if compare_results.nil?

        if compare_xml == "base-dhw-multiple.xml"
          compare_reul_dhw = compare_results["REUL Hot Water (MBtu)"].split(",").map(&:to_f).inject(0, :+) # sum values
        else
          compare_reul_dhw = compare_results["REUL Hot Water (MBtu)"]
        end
        assert_in_epsilon(base_reul_dhw, compare_reul_dhw, 0.01)
      end
    end

    # TODO: Verify that REUL Heating & REUL Cooling are identical across HVAC types
  end

  def test_invalid_xmls
    expected_error_msgs = { 'bad-wmo.xml' => ["Weather station WMO '999999' could not be found in weather/data.csv."],
                            'dhw-frac-load-served.xml' => ["Expected FractionDHWLoadServed to sum to 1, but calculated sum is 1.15."],
                            'missing-elements.xml' => ["Expected [1] element(s) but found 0 element(s) for xpath: /HPXML/Building/BuildingDetails/BuildingSummary/BuildingConstruction/NumberofConditionedFloors",
                                                       "Expected [1] element(s) but found 0 element(s) for xpath: /HPXML/Building/BuildingDetails/BuildingSummary/BuildingConstruction/ConditionedFloorArea"],
                            'hvac-frac-load-served.xml' => ["Expected FractionCoolLoadServed to sum to 1, but calculated sum is 1.2.",
                                                            "Expected FractionHeatLoadServed to sum to 1, but calculated sum is 1.1."] }

    this_dir = File.absolute_path(File.join(File.dirname(__FILE__), ".."))
    xmldir = "#{this_dir}/sample_files/invalid_files"
    Dir["#{xmldir}/*.xml"].sort.each do |xml|
      run_eri_and_check(xml, this_dir, true, expected_error_msgs[File.basename(xml)])
    end
  end

  def test_downloading_weather
    this_dir = File.absolute_path(File.join(File.dirname(__FILE__), ".."))
    cli_path = OpenStudio.getOpenStudioCLI
    command = "\"#{cli_path}\" --no-ssl \"#{File.join(File.dirname(__FILE__), "..", "energy_rating_index.rb")}\" --download-weather"
    system(command)

    num_epws_expected = File.readlines(File.join(this_dir, "..", "weather", "data.csv")).size - 1
    num_epws_actual = Dir[File.join(this_dir, "..", "weather", "*.epw")].count
    assert_equal(num_epws_expected, num_epws_actual)

    num_cache_expected = File.readlines(File.join(this_dir, "..", "weather", "data.csv")).size - 1
    num_cache_actual = Dir[File.join(this_dir, "..", "weather", "*.cache")].count
    assert_equal(num_cache_expected, num_cache_actual)
  end

  def test_resnet_ashrae_140
    test_results_csv = File.absolute_path(File.join(@test_results_dir, "RESNET_Test_4.1_Standard_140.csv"))
    File.delete(test_results_csv) if File.exists? test_results_csv

    this_dir = File.absolute_path(File.join(File.dirname(__FILE__), ".."))

    # Run simulations
    xmldir = File.join(File.dirname(__FILE__), "RESNET_Tests/4.1_Standard_140")
    all_results = []
    Dir["#{xmldir}/*.xml"].sort.each do |xml|
      _test_schema_validation(this_dir, xml)
      sql_path, sim_time = run_straight_sim(xml, this_dir)
      htg_load, clg_load = _get_simulation_load_results(sql_path)
      if xml.include? "C.xml"
        all_results << [xml, htg_load, sim_time]
        assert_operator(htg_load, :>, 0)
      elsif xml.include? "L.xml"
        all_results << [xml, clg_load, sim_time]
        assert_operator(clg_load, :>, 0)
      end
    end
    assert(all_results.size > 0)

    # Write results to csv
    CSV.open(test_results_csv, "w") do |csv|
      csv << ["Test", "Annual Load [MMBtu]", "Simulation Runtime [s]"]
      all_results.each do |results|
        next unless results[0].include? "C.xml"

        csv << results
      end
      all_results.each do |results|
        next unless results[0].include? "L.xml"

        csv << results
      end
    end
    puts "Wrote results to #{test_results_csv}."

    # Check results
    # TODO: Currently not implemented since E+ does not pass test criteria
  end

  def test_resnet_hers_reference_home_auto_generation
    test_results_csv = File.absolute_path(File.join(@test_results_dir, "RESNET_Test_4.2_HERS_AutoGen_Reference_Home.csv"))
    File.delete(test_results_csv) if File.exists? test_results_csv

    this_dir = File.absolute_path(File.join(File.dirname(__FILE__), ".."))

    # Run simulations
    all_results = {}
    xmldir = File.join(File.dirname(__FILE__), "RESNET_Tests/4.2_HERS_AutoGen_Reference_Home")
    Dir["#{xmldir}/*.xml"].sort.each do |xml|
      next if xml.end_with? "ERIReferenceHome.xml"

      hpxmls, results_csv, runtime = run_eri_and_check(xml, this_dir)
      test_num = File.basename(xml)[0, 2].to_i
      all_results[File.basename(xml)] = _get_reference_home_components(hpxmls[:ref], test_num)

      # Re-simulate reference HPXML file
      FileUtils.cp(hpxmls[:ref], xmldir)
      hpxmls[:ref] = "#{xmldir}/#{File.basename(hpxmls[:ref])}"
      hpxmls, results_csv, runtime = run_eri_and_check(hpxmls[:ref], this_dir)
      eri = _get_eri(results_csv)
      all_results[File.basename(xml)]["e-Ratio"] = eri / 100.0
    end
    assert(all_results.size > 0)

    # Write results to csv
    CSV.open(test_results_csv, "w") do |csv|
      csv << ["Component", "Test 1 Results", "Test 2 Results", "Test 3 Results", "Test 4 Results"]
      all_results["01-L100.xml"].keys.each do |component|
        csv << [component,
                all_results["01-L100.xml"][component],
                all_results["02-L100.xml"][component],
                all_results["03-L304.xml"][component],
                all_results["04-L324.xml"][component]]
      end
    end
    puts "Wrote results to #{test_results_csv}."

    # Check results
    all_results.each do |xml, results|
      test_num = File.basename(xml)[0, 2].to_i
      _check_reference_home_components(results, test_num)
    end
  end

  def test_resnet_hers_iad_home_auto_generation
    test_results_csv = File.absolute_path(File.join(@test_results_dir, "RESNET_Test_Other_HERS_AutoGen_IAD_Home.csv"))
    File.delete(test_results_csv) if File.exists? test_results_csv

    this_dir = File.absolute_path(File.join(File.dirname(__FILE__), ".."))

    # Run simulations
    all_results = {}
    xmldir = File.join(File.dirname(__FILE__), "RESNET_Tests/Other_HERS_AutoGen_IAD_Home")
    Dir["#{xmldir}/*.xml"].sort.each do |xml|
      hpxmls, results_csv, runtime = run_eri_and_check(xml, this_dir)
      test_num = File.basename(xml)[0, 2].to_i
      all_results[File.basename(xml)] = _get_iad_home_components(hpxmls[:iad], test_num)
    end
    assert(all_results.size > 0)

    # Write results to csv
    CSV.open(test_results_csv, "w") do |csv|
      csv << ["Component", "Test 1 Results", "Test 2 Results", "Test 3 Results", "Test 4 Results"]
      all_results["01-L100.xml"].keys.each do |component|
        csv << [component,
                all_results["01-L100.xml"][component],
                all_results["02-L100.xml"][component],
                all_results["03-L304.xml"][component],
                all_results["04-L324.xml"][component]]
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
    test_results_csv = File.absolute_path(File.join(@test_results_dir, "RESNET_Test_4.3_HERS_Method.csv"))
    File.delete(test_results_csv) if File.exists? test_results_csv

    this_dir = File.absolute_path(File.join(File.dirname(__FILE__), ".."))

    # Run simulations
    all_results = {}
    xmldir = File.join(File.dirname(__FILE__), "RESNET_Tests/4.3_HERS_Method")
    Dir["#{xmldir}/*.xml"].sort.each do |xml|
      test_num = File.basename(xml).gsub('L100A-', '').gsub('.xml', '').to_i
      hpxmls, results_csv, runtime = run_eri_and_check(xml, this_dir)
      all_results[xml] = _get_method_results(results_csv)
    end
    assert(all_results.size > 0)

    # Write results to csv
    keys = all_results.values[0].keys
    CSV.open(test_results_csv, "w") do |csv|
      csv << ["Test Case"] + keys
      all_results.each_with_index do |(xml, results), i|
        csv_line = [File.basename(xml)]
        keys.each do |key|
          csv_line << results[key]
        end
        csv << csv_line
      end
    end
    puts "Wrote results to #{test_results_csv}."

    # Check results
    all_results.each do |xml, results|
      test_num = File.basename(xml).gsub('L100A-', '').gsub('.xml', '').to_i
      _check_method_results(results, test_num, test_num == 2, false)
    end
  end

  def test_resnet_hers_method_iaf
    test_results_csv = File.absolute_path(File.join(@test_results_dir, "RESNET_Test_Other_HERS_Method_IAF.csv"))
    File.delete(test_results_csv) if File.exists? test_results_csv

    this_dir = File.absolute_path(File.join(File.dirname(__FILE__), ".."))

    # Run simulations
    all_results = {}
    xmldir = File.join(File.dirname(__FILE__), "RESNET_Tests/Other_HERS_Method_IAF")
    Dir["#{xmldir}/*.xml"].sort.each do |xml|
      test_num = File.basename(xml).gsub('L100A-', '').gsub('.xml', '').to_i
      hpxmls, results_csv, runtime = run_eri_and_check(xml, this_dir)
      all_results[xml] = _get_method_results(results_csv)
    end
    assert(all_results.size > 0)

    # Write results to csv
    keys = all_results.values[0].keys
    CSV.open(test_results_csv, "w") do |csv|
      csv << ["Test Case"] + keys
      all_results.each_with_index do |(xml, results), i|
        csv_line = [File.basename(xml)]
        keys.each do |key|
          csv_line << results[key]
        end
        csv << csv_line
      end
    end
    puts "Wrote results to #{test_results_csv}."

    # Check results
    all_results.each do |xml, results|
      test_num = File.basename(xml).gsub('L100A-', '').gsub('.xml', '').to_i
      _check_method_results(results, test_num, test_num == 2, true)
    end
  end

  def test_resnet_hers_method_proposed
    # Proposed New Method Test Suite (Approved by RESNET Board of Directors June 16, 2016)
    test_results_csv = File.absolute_path(File.join(@test_results_dir, "RESNET_Test_Other_HERS_Method_Proposed.csv"))
    File.delete(test_results_csv) if File.exists? test_results_csv

    this_dir = File.absolute_path(File.join(File.dirname(__FILE__), ".."))

    # Run simulations
    all_results = {}
    this_dir = File.absolute_path(File.join(File.dirname(__FILE__), ".."))
    xmldir = File.join(File.dirname(__FILE__), "RESNET_Tests/Other_HERS_Method_Proposed")
    Dir["#{xmldir}/*.xml"].sort.each do |xml|
      hpxmls, results_csv, runtime = run_eri_and_check(xml, this_dir)
      all_results[xml] = _get_method_results(results_csv)
    end
    assert(all_results.size > 0)

    # Write results to csv
    keys = all_results.values[0].keys
    CSV.open(test_results_csv, "w") do |csv|
      csv << ["Test Case"] + keys
      all_results.each_with_index do |(xml, results), i|
        csv_line = [File.basename(xml)]
        keys.each do |key|
          csv_line << results[key]
        end
        csv << csv_line
      end
    end
    puts "Wrote results to #{test_results_csv}."

    # Check results
    all_results.each do |xml, results|
      if xml.include? 'AC'
        test_num = File.basename(xml).gsub('L100-AC-', '').gsub('.xml', '').to_i
        test_loc = 'AC'
      elsif xml.include? 'AL'
        test_num = File.basename(xml).gsub('L100-AL-', '').gsub('.xml', '').to_i
        test_loc = 'AL'
      end
      _check_method_proposed_results(results, test_num, test_loc, test_num == 8)
    end
  end

  def test_resnet_hers_method_proposed_task_group
    # HERS Consistency Task Group files
    test_results_csv = File.absolute_path(File.join(@test_results_dir, "RESNET_Test_Other_HERS_Method_Task_Group.csv"))
    File.delete(test_results_csv) if File.exists? test_results_csv

    # Run simulations
    this_dir = File.absolute_path(File.join(File.dirname(__FILE__), ".."))
    all_results = {}
    xmldir = File.join(File.dirname(__FILE__), "RESNET_Tests/Other_HERS_Method_Task_Group")
    Dir["#{xmldir}/*.xml"].sort.each do |xml|
      hpxmls, results_csv, runtime = run_eri_and_check(xml, this_dir)
      all_results[File.basename(xml)] = _get_method_results(results_csv)
    end
    assert(all_results.size > 0)

    # Write results to csv
    keys = all_results.values[0].keys
    CSV.open(test_results_csv, "w") do |csv|
      csv << ["XML"] + keys
      all_results.each_with_index do |(xml, results), i|
        csv_line = [File.basename(xml)]
        keys.each do |key|
          csv_line << results[key]
        end
        csv << csv_line
      end
    end
    puts "Wrote results to #{test_results_csv}."

    # Check results
    all_results.each do |xml, results|
      if xml.include? 'CO'
        test_num = File.basename(xml).gsub('L100A-CO-', '').gsub('.xml', '').to_i
        test_loc = 'CO'
      elsif xml.include? 'LV'
        test_num = File.basename(xml).gsub('L100A-LV-', '').gsub('.xml', '').to_i
        test_loc = 'LV'
      end
      _check_method_task_group_results(results, test_num, test_loc, test_num == 2)
    end
  end

  def test_resnet_hvac
    test_results_csv = File.absolute_path(File.join(@test_results_dir, "RESNET_Test_4.4_HVAC.csv"))
    File.delete(test_results_csv) if File.exists? test_results_csv

    this_dir = File.absolute_path(File.join(File.dirname(__FILE__), ".."))

    # Run simulations
    xmldir = File.join(File.dirname(__FILE__), "RESNET_Tests/4.4_HVAC")
    all_results = {}
    Dir["#{xmldir}/*.xml"].sort.each do |xml|
      _test_schema_validation(this_dir, xml)
      sql_path, sim_time = run_straight_sim(xml, this_dir)

      is_heat = false
      if xml.include? 'HVAC2'
        is_heat = true
      end

      is_electric_heat = true
      if xml.include? 'HVAC2a' or xml.include? 'HVAC2b'
        is_electric_heat = false
      end

      hvac, hvac_fan = _get_simulation_hvac_energy_results(sql_path, is_heat, is_electric_heat)
      all_results[File.basename(xml)] = [hvac, hvac_fan]
    end
    assert(all_results.size > 0)

    # Write results to csv
    CSV.open(test_results_csv, "w") do |csv|
      csv << ["Test Case", "HVAC (kWh or therm)", "HVAC Fan (kWh)"]
      all_results.each_with_index do |(xml, results), i|
        csv << [xml, results[0], results[1]]
      end
    end
    puts "Wrote results to #{test_results_csv}."

    # Check results
    all_results.each_with_index do |(xml, results), i|
      base_results = nil
      if xml == 'HVAC1b.xml'
        base_results = all_results['HVAC1a.xml']
      elsif xml == 'HVAC2b.xml'
        base_results = all_results['HVAC2a.xml']
      elsif ['HVAC2d.xml', 'HVAC2e.xml'].include? xml
        base_results = all_results['HVAC2c.xml']
      end
      next if base_results.nil?

      _check_hvac_test_results(xml, results, base_results)
    end
  end

  def test_resnet_dse
    test_results_csv = File.absolute_path(File.join(@test_results_dir, "RESNET_Test_4.5_DSE.csv"))
    File.delete(test_results_csv) if File.exists? test_results_csv

    this_dir = File.absolute_path(File.join(File.dirname(__FILE__), ".."))

    # Run simulations
    xmldir = File.join(File.dirname(__FILE__), "RESNET_Tests/4.5_DSE")
    all_results = {}
    Dir["#{xmldir}/*.xml"].sort.each do |xml|
      _test_schema_validation(this_dir, xml)
      sql_path, sim_time = run_straight_sim(xml, this_dir)

      is_heat = false
      if ['HVAC3a.xml', 'HVAC3b.xml', 'HVAC3c.xml', 'HVAC3d.xml'].include? File.basename(xml)
        is_heat = true
      end

      is_electric_heat = false

      hvac, hvac_fan = _get_simulation_hvac_energy_results(sql_path, is_heat, is_electric_heat)
      all_results[File.basename(xml)] = [hvac, hvac_fan]
    end
    assert(all_results.size > 0)

    # Write results to csv
    CSV.open(test_results_csv, "w") do |csv|
      csv << ["Test Case", "Heat/Cool (kWh or therm)", "HVAC Fan (kWh)"]
      all_results.each_with_index do |(xml, results), i|
        next unless ['HVAC3a.xml', 'HVAC3e.xml'].include? xml

        csv << [xml, results[0], results[1]]
      end
      all_results.each_with_index do |(xml, results), i|
        next if ['HVAC3a.xml', 'HVAC3e.xml'].include? xml

        csv << [xml, results[0], results[1]]
      end
    end
    puts "Wrote results to #{test_results_csv}."

    # Check results
    all_results.each_with_index do |(xml, results), i|
      base_results = nil
      if ['HVAC3b.xml', 'HVAC3c.xml', 'HVAC3d.xml'].include? xml
        base_results = all_results['HVAC3a.xml']
      elsif ['HVAC3f.xml', 'HVAC3g.xml', 'HVAC3h.xml'].include? xml
        base_results = all_results['HVAC3e.xml']
      end
      next if base_results.nil?

      _check_dse_test_results(xml, results, base_results)
    end
  end

  def test_resnet_hot_water
    test_results_csv = File.absolute_path(File.join(@test_results_dir, "RESNET_Test_4.6_Hot_Water.csv"))
    File.delete(test_results_csv) if File.exists? test_results_csv

    this_dir = File.absolute_path(File.join(File.dirname(__FILE__), ".."))

    # Run simulations
    base_vals = {}
    mn_vals = {}
    all_results = {}
    xmldir = File.join(File.dirname(__FILE__), "RESNET_Tests/4.6_Hot_Water")
    Dir["#{xmldir}/*.xml"].sort.each do |xml|
      hpxmls, results_csv, runtime = run_eri_and_check(xml, this_dir)
      all_results[xml] = _get_hot_water(results_csv)
      assert_operator(all_results[xml], :>, 0)
    end
    assert(all_results.size > 0)

    # Write results to csv
    # TODO: Break out recirculation pump energy
    CSV.open(test_results_csv, "w") do |csv|
      csv << ["Test Case", "DHW Energy (therms)"]
      all_results.each_with_index do |(xml, result), i|
        csv << [File.basename(xml), result * 10.0]
      end
    end
    puts "Wrote results to #{test_results_csv}."

    # Check results
    all_results.each_with_index do |(xml, result), i|
      test_num = i + 1

      base_val = nil
      if [2, 3].include? test_num
        base_val = all_results[1]
      elsif [4, 5, 6, 7].include? test_num
        base_val = all_results[2]
      elsif [9, 10].include? test_num
        base_val = all_results[8]
      elsif [11, 12, 13, 14].include? test_num
        base_val = all_results[9]
      end

      mn_val = nil
      if test_num >= 8
        mn_val = all_results[test_num - 7]
      end

      _check_hot_water(test_num, result, base_val, mn_val)
    end
  end

  def test_resnet_hot_water_pre_addendum_a
    # Tests w/o Addendum A
    test_results_csv = File.absolute_path(File.join(@test_results_dir, "RESNET_Test_Other_Hot_Water_PreAddendumA.csv"))
    File.delete(test_results_csv) if File.exists? test_results_csv

    this_dir = File.absolute_path(File.join(File.dirname(__FILE__), ".."))

    # Run simulations
    base_vals = {}
    mn_vals = {}
    all_results = {}
    xmldir = File.join(File.dirname(__FILE__), "RESNET_Tests/Other_Hot_Water_PreAddendumA")
    Dir["#{xmldir}/*.xml"].sort.each do |xml|
      hpxmls, results_csv, runtime = run_eri_and_check(xml, this_dir)
      all_results[xml] = _get_hot_water(results_csv)
      assert_operator(all_results[xml], :>, 0)
    end
    assert(all_results.size > 0)

    # Write results to csv
    CSV.open(test_results_csv, "w") do |csv|
      csv << ["Test Case", "DHW Energy (therms)"]
      all_results.each_with_index do |(xml, result), i|
        csv << [File.basename(xml), result * 10.0]
      end
    end
    puts "Wrote results to #{test_results_csv}."

    # Check results
    all_results.each_with_index do |(xml, result), i|
      test_num = i + 1

      base_val = nil
      if [2, 3].include? test_num
        base_val = all_results[1]
      elsif [5, 6].include? test_num
        base_val = all_results[4]
      end

      mn_val = nil
      if test_num >= 4
        mn_val = all_results[test_num - 3]
      end

      _check_hot_water_pre_addendum_a(test_num, result, base_val, mn_val)
    end
  end

  def test_resnet_verification_building_attributes
    # TODO
  end

  def test_resnet_verification_mechanical_ventilation
    # TODO
  end

  def test_resnet_verification_appliances
    # TODO
  end

  def test_naseo_technical_exercises
    test_results_csv = File.absolute_path(File.join(@test_results_dir, "naseo_technical_exercises.csv"))
    File.delete(test_results_csv) if File.exists? test_results_csv

    this_dir = File.absolute_path(File.join(File.dirname(__FILE__), ".."))

    # Run simulations
    all_results = {}
    xmldir = "#{this_dir}/tests/NASEO_Technical_Exercises"
    Dir["#{xmldir}/NASEO*.xml"].sort.each do |xml|
      hpxmls, results_csv, runtime = run_eri_and_check(xml, this_dir)
      all_results[File.basename(xml)] = _get_method_results(results_csv)
      all_results[File.basename(xml)]["Workflow Runtime (s)"] = runtime
    end
    assert(all_results.size > 0)

    # Write results to csv
    keys = all_results.values[0].keys
    CSV.open(test_results_csv, "w") do |csv|
      csv << ["XML"] + keys
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

  def test_running_with_cli
    # Test that these tests can be run from the OpenStudio CLI (and not just system ruby)
    this_dir = File.absolute_path(File.join(File.dirname(__FILE__), ".."))

    cli_path = OpenStudio.getOpenStudioCLI
    command = "\"#{cli_path}\" --no-ssl #{File.absolute_path(__FILE__)} --name=foo"
    success = system(command)
    assert(success)
  end

  private

  def run_eri_and_check(xml, this_dir, expect_error = false, expect_error_msgs = nil)
    # Check input HPXML is valid
    xml = File.absolute_path(xml)

    # Run energy_rating_index workflow
    cli_path = OpenStudio.getOpenStudioCLI
    command = "\"#{cli_path}\" --no-ssl \"#{File.join(File.dirname(__FILE__), "../energy_rating_index.rb")}\" -x #{xml}"
    start_time = Time.now
    system(command)
    runtime = (Time.now - start_time).round(2)

    using_iaf = false
    File.open(xml, 'r').each do |line|
      if line.strip.downcase.start_with? "<version>"
        if line.include? '2014AE' or line.include? '2014AEG'
          using_iaf = true
        end
        break
      end
    end

    hpxmls = {}
    hpxmls[:ref] = File.join(this_dir, "results", "ERIReferenceHome.xml")
    hpxmls[:rated] = File.join(this_dir, "results", "ERIRatedHome.xml")
    results_csv = File.join(this_dir, "results", "ERI_Results.csv")
    worksheet_csv = File.join(this_dir, "results", "ERI_Worksheet.csv")
    if expect_error
      assert(!File.exists?(hpxmls[:ref]))
      assert(!File.exists?(hpxmls[:rated]))
      assert(!File.exists?(results_csv))
      assert(!File.exists?(worksheet_csv))

      if not expect_error_msgs.nil?
        run_log = File.readlines(File.join(this_dir, "ERIRatedHome", "run.log")).map(&:strip)
        expect_error_msgs.each do |error_msg|
          found_error_msg = false
          run_log.each do |run_line|
            next unless run_line.include? error_msg

            found_error_msg = true
            break
          end
          assert(found_error_msg)
        end
      end

    else
      # Check all output files exist
      assert(File.exists?(hpxmls[:ref]))
      assert(File.exists?(hpxmls[:rated]))
      assert(File.exists?(results_csv))
      assert(File.exists?(worksheet_csv))
      if using_iaf
        hpxmls[:iad] = File.join(this_dir, "results", "ERIIndexAdjustmentDesign.xml")
        assert(File.exists?(hpxmls[:iad]))
        hpxmls[:iadref] = File.join(this_dir, "results", "ERIIndexAdjustmentReferenceHome.xml")
        assert(File.exists?(hpxmls[:iadref]))
      end

      # Check HPXMLs are valid
      _test_schema_validation(this_dir, xml)
      _test_schema_validation(this_dir, hpxmls[:ref])
      _test_schema_validation(this_dir, hpxmls[:rated])
      if using_iaf
        _test_schema_validation(this_dir, hpxmls[:iad])
        _test_schema_validation(this_dir, hpxmls[:iadref])
      end
    end

    return hpxmls, results_csv, runtime
  end

  def run_straight_sim(xml, this_dir)
    require_relative '../../measures/HPXMLtoOpenStudio/resources/meta_measure'

    puts "Running #{xml}..."

    xml = File.absolute_path(xml)

    rundir = File.join(this_dir, "SimulationHome")
    _rm_path(rundir)
    Dir.mkdir(rundir)

    model = OpenStudio::Model::Model.new
    runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)

    args = {}
    args['weather_dir'] = File.absolute_path(File.join(File.dirname(xml), "weather"))
    args['skip_validation'] = false
    args['epw_output_path'] = File.absolute_path(File.join(rundir, "in.epw"))
    args['osm_output_path'] = File.absolute_path(File.join(rundir, "in.osm"))
    args['hpxml_path'] = xml

    # Add measure to workflow
    measures = {}
    measure_subdir = "HPXMLtoOpenStudio"
    update_args_hash(measures, measure_subdir, args)

    # Apply measure
    measures_dir = File.join(this_dir, "../measures")
    success = apply_measures(measures_dir, measures, runner, model)

    # Report warnings/errors
    File.open(File.join(rundir, 'run.log'), 'w') do |f|
      runner.result.stepWarnings.each do |s|
        f << "Warning: #{s}\n"
      end
      runner.result.stepErrors.each do |s|
        f << "Error: #{s}\n"
      end
    end
    assert(success)

    # Write model to IDF
    forward_translator = OpenStudio::EnergyPlus::ForwardTranslator.new
    model_idf = forward_translator.translateModel(model)
    File.open(File.join(rundir, "in.idf"), 'w') { |f| f << model_idf.to_s }

    # Run EnergyPlus
    ep_path = File.absolute_path(File.join(OpenStudio.getOpenStudioCLI.to_s, '..', '..', 'EnergyPlus', 'energyplus'))
    command = "cd #{rundir} && #{ep_path} -w in.epw in.idf > stdout-energyplus"
    start_time = Time.now
    system(command, :err => File::NULL)
    sim_time = (Time.now - start_time).round(1)
    puts "Completed #{File.basename(args['hpxml_path'])} simulation in #{sim_time}s."

    sql_path = File.join(rundir, "eplusout.sql")
    assert(File.exists?(sql_path))

    return sql_path, sim_time
  end

  def _get_simulation_load_results(sql_path)
    # Obtain heating/cooling loads
    sqlFile = OpenStudio::SqlFile.new(sql_path, false)

    # Space Heating Load
    query = "SELECT Value FROM TabularDataWithStrings WHERE ReportName='EnergyMeters' AND TableName='Annual and Peak Values - Other' AND RowName='Heating:EnergyTransfer' AND ColumnName='Annual Value' AND Units='GJ'"
    htg_load = UnitConversions.convert(sqlFile.execAndReturnFirstDouble(query).get, "GJ", "MBtu")

    # Space Cooling Load
    query = "SELECT Value FROM TabularDataWithStrings WHERE ReportName='EnergyMeters' AND TableName='Annual and Peak Values - Other' AND RowName='Cooling:EnergyTransfer' AND ColumnName='Annual Value' AND Units='GJ'"
    clg_load = UnitConversions.convert(sqlFile.execAndReturnFirstDouble(query).get, "GJ", "MBtu")

    sqlFile.close

    return htg_load.round(2), clg_load.round(2)
  end

  def _get_simulation_hvac_energy_results(sql_path, is_heat, is_electric_heat)
    # Obtain heating/cooling loads
    sqlFile = OpenStudio::SqlFile.new(sql_path, false)

    if not is_heat
      # Cool
      query = "SELECT Value FROM TabularDataWithStrings WHERE ReportName='AnnualBuildingUtilityPerformanceSummary' AND TableName='End Uses' AND RowName='Cooling' AND ColumnName='Electricity' AND Units='GJ'"
      hvac = UnitConversions.convert(sqlFile.execAndReturnFirstDouble(query).get, "GJ", "kWh")

      # Cool Fan
      query = "SELECT Value FROM TabularDataWithStrings WHERE ReportName='AnnualBuildingUtilityPerformanceSummary' AND TableName='End Uses' AND RowName='Fans' AND ColumnName='Electricity' AND Units='GJ'"
      hvac_fan = UnitConversions.convert(sqlFile.execAndReturnFirstDouble(query).get, "GJ", "kWh")
    else
      # Heat
      if not is_electric_heat
        query = "SELECT Value FROM TabularDataWithStrings WHERE ReportName='AnnualBuildingUtilityPerformanceSummary' AND TableName='End Uses' AND RowName='Heating' AND ColumnName='Natural Gas' AND Units='GJ'"
        hvac = UnitConversions.convert(sqlFile.execAndReturnFirstDouble(query).get, "GJ", "therm")
      else
        query = "SELECT Value FROM TabularDataWithStrings WHERE ReportName='AnnualBuildingUtilityPerformanceSummary' AND TableName='End Uses' AND RowName='Heating' AND ColumnName='Electricity' AND Units='GJ'"
        hvac = UnitConversions.convert(sqlFile.execAndReturnFirstDouble(query).get, "GJ", "kWh")
      end

      # Heat Fan
      query = "SELECT Value FROM TabularDataWithStrings WHERE ReportName='AnnualBuildingUtilityPerformanceSummary' AND TableName='End Uses' AND RowName='Fans' AND ColumnName='Electricity' AND Units='GJ'"
      hvac_fan = UnitConversions.convert(sqlFile.execAndReturnFirstDouble(query).get, "GJ", "kWh")
    end

    sqlFile.close

    return hvac.round(2), hvac_fan.round(2)
  end

  def _test_schema_validation(this_dir, xml)
    # TODO: Remove this when schema validation is included with CLI calls
    schemas_dir = File.absolute_path(File.join(this_dir, "..", "measures", "HPXMLtoOpenStudio", "hpxml_schemas"))
    hpxml_doc = REXML::Document.new(File.read(xml))
    errors = XMLHelper.validate(hpxml_doc.to_s, File.join(schemas_dir, "HPXML.xsd"), nil)
    if errors.size > 0
      puts "#{xml}: #{errors.to_s}"
    end
    assert_equal(0, errors.size)
  end

  def _get_reference_home_components(hpxml, test_num)
    results = {}
    hpxml_doc = REXML::Document.new(File.read(hpxml))

    # Above-grade walls
    wall_u, wall_solar_abs, wall_emiss, wall_area = _get_above_grade_walls(hpxml_doc)
    results["Above-grade walls (Uo)"] = wall_u
    results["Above-grade wall solar absorptance (α)"] = wall_solar_abs
    results["Above-grade wall infrared emittance (ε)"] = wall_emiss

    # Basement walls
    bsmt_wall_u = _get_basement_walls(hpxml_doc)
    if test_num == 4
      results["Basement walls (Uo)"] = bsmt_wall_u
    else
      results["Basement walls (Uo)"] = "n/a"
    end

    # Above-grade floors
    floors_u = _get_above_grade_floors(hpxml_doc)
    if test_num <= 2
      results["Above-grade floors (Uo)"] = floors_u
    else
      results["Above-grade floors (Uo)"] = "n/a"
    end

    # Slab insulation
    slab_r, carpet_r, exp_mas_floor_area = get_hpxml_slabs(hpxml_doc)
    if test_num >= 3
      results["Slab insulation R-Value"] = slab_r
    else
      results["Slab insulation R-Value"] = "n/a"
    end

    # Ceilings
    ceil_u, ceil_area = _get_ceilings(hpxml_doc)
    results["Ceilings (Uo)"] = ceil_u

    # Roofs
    roof_solar_abs, roof_emiss, roof_area = _get_roof(hpxml_doc)
    results["Roof solar absorptance (α)"] = roof_solar_abs
    results["Roof infrared emittance (ε)"] = roof_emiss

    # Attic vent area
    attic_vent_area = _get_attic_vent_area(hpxml_doc)
    results["Attic vent area (ft2)"] = attic_vent_area

    # Crawlspace vent area
    crawl_vent_area = _get_crawl_vent_area(hpxml_doc)
    if test_num == 2
      results["Crawlspace vent area (ft2)"] = crawl_vent_area
    else
      results["Crawlspace vent area (ft2)"] = "n/a"
    end

    # Slabs
    if test_num >= 3
      results["Exposed masonry floor area (ft2)"] = exp_mas_floor_area
      results["Carpet & pad R-Value"] = carpet_r
    else
      results["Exposed masonry floor area (ft2)"] = "n/a"
      results["Carpet & pad R-Value"] = "n/a"
    end

    # Doors
    door_u, door_area = _get_doors(hpxml_doc)
    results["Door Area (ft2)"] = door_area
    results["Door U-Factor"] = door_u

    # Windows
    win_areas, win_u, win_shgc_htg, win_shgc_clg = _get_windows(hpxml_doc)
    results["North window area (ft2)"] = win_areas[0]
    results["South window area (ft2)"] = win_areas[180]
    results["East window area (ft2)"] = win_areas[90]
    results["West window area (ft2)"] = win_areas[270]
    results["Window U-Factor"] = win_u
    results["Window SHGCo (heating)"] = win_shgc_htg
    results["Window SHGCo (cooling)"] = win_shgc_clg

    # Infiltration
    sla, ach50 = _get_infiltration(hpxml_doc)
    results["SLAo (ft2/ft2)"] = sla

    # Internal gains
    xml_it_sens, xml_it_lat = _get_internal_gains(hpxml_doc)
    results["Sensible Internal gains (Btu/day)"] = xml_it_sens
    results["Latent Internal gains (Btu/day)"] = xml_it_lat

    # HVAC
    afue, hspf, seer, dse = _get_hvac(hpxml_doc)
    if test_num == 1 or test_num == 4
      results["Labeled heating system rating and efficiency"] = afue
    else
      results["Labeled heating system rating and efficiency"] = hspf
    end
    results["Labeled cooling system rating and efficiency"] = seer
    results["Air Distribution System Efficiency"] = dse

    # Thermostat
    tstat, htg_sp, htg_setback, clg_sp, clg_setup = _get_tstat(hpxml_doc)
    results["Thermostat Type"] = tstat
    results["Heating thermostat settings"] = htg_sp
    results["Cooling thermostat settings"] = clg_sp

    # Mechanical ventilation
    mv_kwh, mv_cfm = _get_mech_vent(hpxml_doc)
    results["Mechanical ventilation (kWh/y)"] = mv_kwh

    # Domestic hot water
    ref_pipe_l, ref_loop_l = _get_dhw(hpxml_doc)
    results["DHW pipe length refPipeL"] = ref_pipe_l
    results["DHW loop length refLoopL"] = ref_loop_l

    return results
  end

  def _get_iad_home_components(hpxml, test_num)
    results = {}
    hpxml_doc = REXML::Document.new(File.read(hpxml))

    # Geometry
    nstories, nbeds, cfa, infil_volume = _get_geometry_values(hpxml_doc)
    results["Number of Stories"] = nstories
    results["Number of Bedrooms"] = nbeds
    results["Conditioned Floor Area (ft2)"] = cfa
    results["Infiltration Volume (ft3)"] = infil_volume

    # Above-grade Walls
    wall_u, wall_solar_abs, wall_emiss, wall_area = _get_above_grade_walls(hpxml_doc)
    results["Above-grade walls area (ft2)"] = wall_area
    results["Above-grade walls (Uo)"] = wall_u

    # Roof
    roof_solar_abs, roof_emiss, roof_area = _get_roof(hpxml_doc)
    results["Roof gross area (ft2)"] = roof_area

    # Ceilings
    ceil_u, ceil_area = _get_ceilings(hpxml_doc)
    results["Ceiling gross projected footprint area (ft2)"] = ceil_area
    results["Ceilings (Uo)"] = ceil_u

    # Crawlspace
    crawl_vent_area = _get_crawl_vent_area(hpxml_doc)
    results["Crawlspace vent area (ft2)"] = crawl_vent_area

    # Doors
    door_u, door_area = _get_doors(hpxml_doc)
    results["Door Area (ft2)"] = door_area
    results["Door R-value"] = 1.0 / door_u

    # Windows
    win_areas, win_u, win_shgc_htg, win_shgc_clg = _get_windows(hpxml_doc)
    results["North window area (ft2)"] = win_areas[0]
    results["South window area (ft2)"] = win_areas[180]
    results["East window area (ft2)"] = win_areas[90]
    results["West window area (ft2)"] = win_areas[270]
    results["Window U-Factor"] = win_u
    results["Window SHGCo (heating)"] = win_shgc_htg
    results["Window SHGCo (cooling)"] = win_shgc_clg

    # Infiltration
    sla, ach50 = _get_infiltration(hpxml_doc)
    results["Infiltration rate (ACH50)"] = ach50

    # Mechanical Ventilation
    mv_kwh, mv_cfm = _get_mech_vent(hpxml_doc)
    results["Mechanical ventilation rate"] = mv_cfm
    results["Mechanical ventilation"] = mv_kwh

    # HVAC
    afue, hspf, seer, dse = _get_hvac(hpxml_doc)
    if test_num == 1 or test_num == 4
      results["Labeled heating system rating and efficiency"] = afue
    else
      results["Labeled heating system rating and efficiency"] = hspf
    end
    results["Labeled cooling system rating and efficiency"] = seer

    # Thermostat
    tstat, htg_sp, htg_setback, clg_sp, clg_setup = _get_tstat(hpxml_doc)
    results["Thermostat Type"] = tstat
    results["Heating thermostat settings"] = htg_sp
    results["Cooling thermostat settings"] = clg_sp

    return results
  end

  def _check_reference_home_components(results, test_num)
    # Table 4.2.3.1(1): Acceptance Criteria for Test Cases 1 - 4

    epsilon = 0.0005 # 0.05%

    # Above-grade walls
    if test_num <= 3
      assert_in_delta(0.082, results["Above-grade walls (Uo)"], 0.001)
    else
      assert_in_delta(0.060, results["Above-grade walls (Uo)"], 0.001)
    end
    assert_equal(0.75, results["Above-grade wall solar absorptance (α)"])
    assert_equal(0.90, results["Above-grade wall infrared emittance (ε)"])

    # Basement walls
    if test_num == 4
      assert_in_delta(0.059, results["Basement walls (Uo)"], 0.001)
    end

    # Above-grade floors
    if test_num <= 2
      assert_in_delta(0.047, results["Above-grade floors (Uo)"], 0.001)
    end

    # Slab insulation
    if test_num >= 3
      assert_equal(0, results["Slab insulation R-Value"])
    end

    # Ceilings
    if test_num == 1 or test_num == 4
      assert_in_delta(0.030, results["Ceilings (Uo)"], 0.001)
    else
      assert_in_delta(0.035, results["Ceilings (Uo)"], 0.001)
    end

    # Roofs
    assert_equal(0.75, results["Roof solar absorptance (α)"])
    assert_equal(0.90, results["Roof infrared emittance (ε)"])

    # Attic vent area
    assert_in_epsilon(5.13, results["Attic vent area (ft2)"], epsilon)

    # Crawlspace vent area
    if test_num == 2
      assert_in_epsilon(10.26, results["Crawlspace vent area (ft2)"], epsilon)
    end

    # Slabs
    if test_num >= 3
      assert_in_epsilon(307.8, results["Exposed masonry floor area (ft2)"], epsilon)
      assert_equal(2.0, results["Carpet & pad R-Value"])
    end

    # Doors
    assert_equal(40, results["Door Area (ft2)"])
    if test_num == 1
      assert_in_delta(0.40, results["Door U-Factor"], 0.01)
    elsif test_num == 2
      assert_in_delta(0.65, results["Door U-Factor"], 0.01)
    elsif test_num == 3
      assert_in_delta(1.20, results["Door U-Factor"], 0.01)
    else
      assert_in_delta(0.35, results["Door U-Factor"], 0.01)
    end

    # Windows
    if test_num <= 3
      assert_in_epsilon(69.26, results["North window area (ft2)"], epsilon)
      assert_in_epsilon(69.26, results["South window area (ft2)"], epsilon)
      assert_in_epsilon(69.26, results["East window area (ft2)"], epsilon)
      assert_in_epsilon(69.26, results["West window area (ft2)"], epsilon)
    else
      assert_in_epsilon(102.63, results["North window area (ft2)"], epsilon)
      assert_in_epsilon(102.63, results["South window area (ft2)"], epsilon)
      assert_in_epsilon(102.63, results["East window area (ft2)"], epsilon)
      assert_in_epsilon(102.63, results["West window area (ft2)"], epsilon)
    end
    if test_num == 1
      assert_in_delta(0.40, results["Window U-Factor"], 0.01)
    elsif test_num == 2
      assert_in_delta(0.65, results["Window U-Factor"], 0.01)
    elsif test_num == 3
      assert_in_delta(1.20, results["Window U-Factor"], 0.01)
    else
      assert_in_delta(0.35, results["Window U-Factor"], 0.01)
    end
    assert_in_delta(0.34, results["Window SHGCo (heating)"], 0.01)
    assert_in_delta(0.28, results["Window SHGCo (cooling)"], 0.01)

    # Infiltration
    assert_in_delta(0.00036, results["SLAo (ft2/ft2)"], 0.00001)

    # Internal gains
    if test_num == 1
      assert_in_epsilon(55470, results["Sensible Internal gains (Btu/day)"], epsilon)
      assert_in_epsilon(13807, results["Latent Internal gains (Btu/day)"], epsilon)
    elsif test_num == 2
      assert_in_epsilon(52794, results["Sensible Internal gains (Btu/day)"], epsilon)
      assert_in_epsilon(12698, results["Latent Internal gains (Btu/day)"], epsilon)
    elsif test_num == 3
      assert_in_epsilon(48111, results["Sensible Internal gains (Btu/day)"], epsilon)
      assert_in_epsilon(9259, results["Latent Internal gains (Btu/day)"], epsilon)
    else
      assert_in_epsilon(83103, results["Sensible Internal gains (Btu/day)"], epsilon)
      assert_in_epsilon(17934, results["Latent Internal gains (Btu/day)"], epsilon)
    end

    # HVAC
    if test_num == 1 or test_num == 4
      assert_equal(0.78, results["Labeled heating system rating and efficiency"])
    else
      assert_equal(7.7, results["Labeled heating system rating and efficiency"])
    end
    assert_equal(13.0, results["Labeled cooling system rating and efficiency"])
    assert_equal(0.80, results["Air Distribution System Efficiency"])

    # Thermostat
    assert_equal("manual", results["Thermostat Type"])
    assert_equal(68, results["Heating thermostat settings"])
    assert_equal(78, results["Cooling thermostat settings"])

    # Mechanical ventilation
    mv_epsilon = 0.001 # 0.1%
    if test_num == 1
      assert_in_epsilon(0.0, results["Mechanical ventilation (kWh/y)"], mv_epsilon)
    elsif test_num == 2
      assert_in_epsilon(77.9, results["Mechanical ventilation (kWh/y)"], mv_epsilon)
    elsif test_num == 3
      assert_in_epsilon(140.4, results["Mechanical ventilation (kWh/y)"], mv_epsilon)
    else
      assert_in_epsilon(379.1, results["Mechanical ventilation (kWh/y)"], mv_epsilon)
    end

    # Domestic hot water
    dhw_epsilon = 0.1 # 0.1 ft
    if test_num <= 3
      assert_in_delta(88.5, results["DHW pipe length refPipeL"], dhw_epsilon)
      assert_in_delta(156.9, results["DHW loop length refLoopL"], dhw_epsilon)
    else
      assert_in_delta(98.5, results["DHW pipe length refPipeL"], dhw_epsilon)
      assert_in_delta(176.9, results["DHW loop length refLoopL"], dhw_epsilon)
    end

    # e-Ratio
    assert_in_delta(1, results["e-Ratio"], 0.0075) # FIXME: Should be 0.005
  end

  def _check_iad_home_components(results, test_num)
    epsilon = 0.0005 # 0.05%

    # Geometry
    assert_equal(2, results["Number of Stories"])
    assert_equal(3, results["Number of Bedrooms"])
    assert_equal(2400, results["Conditioned Floor Area (ft2)"])
    assert_equal(20400, results["Infiltration Volume (ft3)"])

    # Above-grade Walls
    assert_in_delta(2355.52, results["Above-grade walls area (ft2)"], 0.01)
    assert_in_delta(0.085, results["Above-grade walls (Uo)"], 0.001)

    # Roof
    assert_equal(1300, results["Roof gross area (ft2)"])

    # Ceilings
    assert_equal(1200, results["Ceiling gross projected footprint area (ft2)"])
    assert_in_delta(0.054, results["Ceilings (Uo)"], 0.01)

    # Crawlspace
    assert_in_epsilon(8, results["Crawlspace vent area (ft2)"], 0.01)

    # Doors
    assert_equal(40, results["Door Area (ft2)"])
    assert_in_delta(3.04, results["Door R-value"], 0.01)

    # Windows
    assert_in_epsilon(108.00, results["North window area (ft2)"], epsilon)
    assert_in_epsilon(108.00, results["South window area (ft2)"], epsilon)
    assert_in_epsilon(108.00, results["East window area (ft2)"], epsilon)
    assert_in_epsilon(108.00, results["West window area (ft2)"], epsilon)
    assert_in_delta(1.039, results["Window U-Factor"], 0.01)
    assert_in_delta(0.57, results["Window SHGCo (heating)"], 0.01)
    assert_in_delta(0.47, results["Window SHGCo (cooling)"], 0.01)

    # Infiltration
    if test_num != 3
      assert_equal(3.0, results["Infiltration rate (ACH50)"])
    else
      assert_equal(5.0, results["Infiltration rate (ACH50)"])
    end

    # Mechanical Ventilation
    if test_num == 1
      assert_in_delta(66.4, results["Mechanical ventilation rate"], 0.2)
      assert_in_delta(407, results["Mechanical ventilation"], 1.0)
    elsif test_num == 2
      assert_in_delta(64.2, results["Mechanical ventilation rate"], 0.2)
      assert_in_delta(394, results["Mechanical ventilation"], 1.0)
    elsif test_num == 3
      assert_in_delta(53.3, results["Mechanical ventilation rate"], 0.2)
      assert_in_delta(327, results["Mechanical ventilation"], 1.0)
    elsif test_num == 4
      assert_in_delta(57.1, results["Mechanical ventilation rate"], 0.2)
      assert_in_delta(350, results["Mechanical ventilation"], 1.0)
    end

    # HVAC
    if test_num == 1 or test_num == 4
      assert_equal(0.78, results["Labeled heating system rating and efficiency"])
    else
      assert_equal(7.7, results["Labeled heating system rating and efficiency"])
    end
    assert_equal(13.0, results["Labeled cooling system rating and efficiency"])

    # Thermostat
    assert_equal("manual", results["Thermostat Type"])
    assert_equal(68, results["Heating thermostat settings"])
    assert_equal(78, results["Cooling thermostat settings"])
  end

  def _get_geometry_values(hpxml_doc)
    nstories = Integer(XMLHelper.get_value(hpxml_doc, "/HPXML/Building/BuildingDetails/BuildingSummary/BuildingConstruction/NumberofConditionedFloors"))
    nbeds = Integer(XMLHelper.get_value(hpxml_doc, "/HPXML/Building/BuildingDetails/BuildingSummary/BuildingConstruction/NumberofBedrooms"))
    cfa = Float(XMLHelper.get_value(hpxml_doc, "/HPXML/Building/BuildingDetails/BuildingSummary/BuildingConstruction/ConditionedFloorArea"))
    infil_volume = Float(XMLHelper.get_value(hpxml_doc, "/HPXML/Building/BuildingDetails/Enclosure/AirInfiltration/AirInfiltrationMeasurement/InfiltrationVolume"))
    return nstories, nbeds, cfa, infil_volume
  end

  def _get_above_grade_walls(hpxml_doc)
    u_factor = 0.0
    solar_abs = 0.0
    emittance = 0.0
    num = 0
    hpxml_doc.elements.each("/HPXML/Building/BuildingDetails/Enclosure/Walls/Wall") do |wall|
      u_factor += 1.0 / Float(XMLHelper.get_value(wall, "Insulation/AssemblyEffectiveRValue"))
      solar_abs += Float(XMLHelper.get_value(wall, "SolarAbsorptance"))
      emittance += Float(XMLHelper.get_value(wall, "Emittance"))
      num += 1
    end
    area = 0.0
    hpxml_doc.elements.each("/HPXML/Building/BuildingDetails/Enclosure/Walls/Wall | /HPXML/Building/BuildingDetails/Enclosure/RimJoists/RimJoist") do |wall|
      area += Float(XMLHelper.get_value(wall, "Area"))
    end
    return u_factor / num, solar_abs / num, emittance / num, area
  end

  def _get_basement_walls(hpxml_doc)
    u_factor = 0.0
    num = 0
    hpxml_doc.elements.each("/HPXML/Building/BuildingDetails/Enclosure/Foundations/Foundation[FoundationType/Basement]/FoundationWall") do |fnd_wall|
      u_factor += 1.0 / Float(XMLHelper.get_value(fnd_wall, "Insulation/AssemblyEffectiveRValue"))
      num += 1
    end
    return u_factor / num
  end

  def _get_above_grade_floors(hpxml_doc)
    u_factor = 0.0
    num = 0
    hpxml_doc.elements.each("/HPXML/Building/BuildingDetails/Enclosure/Foundations/Foundation[FoundationType/Ambient|FoundationType/Crawlspace]/FrameFloor") do |amb_ceil|
      u_factor += 1.0 / Float(XMLHelper.get_value(amb_ceil, "Insulation/AssemblyEffectiveRValue"))
      num += 1
    end
    return u_factor / num
  end

  def get_hpxml_slabs(hpxml_doc)
    r_value = 0.0
    carpet_r_value = 0.0
    exp_area = 0.0
    carpet_num = 0
    r_num = 0
    hpxml_doc.elements.each("/HPXML/Building/BuildingDetails/Enclosure/Foundations/Foundation/Slab") do |fnd_slab|
      exp_frac = 1.0 - Float(XMLHelper.get_value(fnd_slab, "extension/CarpetFraction"))
      exp_area += (Float(XMLHelper.get_value(fnd_slab, "Area")) * exp_frac)
      carpet_r_value += Float(XMLHelper.get_value(fnd_slab, "extension/CarpetRValue"))
      carpet_num += 1
      r_value += Float(XMLHelper.get_value(fnd_slab, "PerimeterInsulation/Layer[InstallationType='continuous']/NominalRValue"))
      r_num += 1
      r_value += Float(XMLHelper.get_value(fnd_slab, "UnderSlabInsulation/Layer[InstallationType='continuous']/NominalRValue"))
      r_num += 1
    end
    return r_value / r_num, carpet_r_value / carpet_num, exp_area
  end

  def _get_ceilings(hpxml_doc)
    u_factor = 0.0
    area = 0.0
    num = 0
    hpxml_doc.elements.each("/HPXML/Building/BuildingDetails/Enclosure/Attics/Attic/Floors/Floor") do |attc_floor|
      u_factor += 1.0 / Float(XMLHelper.get_value(attc_floor, "Insulation/AssemblyEffectiveRValue"))
      area += Float(XMLHelper.get_value(attc_floor, "Area"))
      num += 1
    end
    return u_factor / num, area
  end

  def _get_roof(hpxml_doc)
    solar_abs = 0.0
    emittance = 0.0
    area = 0.0
    num = 0
    hpxml_doc.elements.each("/HPXML/Building/BuildingDetails/Enclosure/Attics/Attic/Roofs/Roof") do |roof|
      solar_abs += Float(XMLHelper.get_value(roof, "SolarAbsorptance"))
      emittance += Float(XMLHelper.get_value(roof, "Emittance"))
      area += Float(XMLHelper.get_value(roof, "Area"))
      num += 1
    end
    return solar_abs / num, emittance / num, area
  end

  def _get_attic_vent_area(hpxml_doc)
    area = 0.0
    sla = 0.0
    hpxml_doc.elements.each("/HPXML/Building/BuildingDetails/Enclosure/Attics/Attic") do |attc|
      area = REXML::XPath.first(attc, "sum(Floors/Floor/Area/text())")
      sla += XMLHelper.get_value(attc, "AtticType/Attic[Vented='true']/SpecificLeakageArea").to_f
    end
    return sla * area
  end

  def _get_crawl_vent_area(hpxml_doc)
    area = 0.0
    sla = 0.0
    hpxml_doc.elements.each("/HPXML/Building/BuildingDetails/Enclosure/Foundations/Foundation") do |foundation|
      area = REXML::XPath.first(foundation, "sum(FrameFloor/Area/text())")
      sla = XMLHelper.get_value(foundation, "FoundationType/Crawlspace[Vented='true']/SpecificLeakageArea").to_f
    end
    return sla * area
  end

  def _get_doors(hpxml_doc)
    area = 0.0
    u_factor = 0.0
    num = 0
    hpxml_doc.elements.each("/HPXML/Building/BuildingDetails/Enclosure/Doors/Door") do |door|
      area += Float(XMLHelper.get_value(door, "Area"))
      u_factor += 1.0 / Float(XMLHelper.get_value(door, "RValue"))
      num += 1
    end
    return u_factor / num, area
  end

  def _get_windows(hpxml_doc)
    areas = { 0 => 0.0, 90 => 0.0, 180 => 0.0, 270 => 0.0 }
    u_factor = 0.0
    shgc_htg = 0.0
    shgc_clg = 0.0
    num = 0
    hpxml_doc.elements.each("/HPXML/Building/BuildingDetails/Enclosure/Windows/Window") do |win|
      azimuth = Integer(XMLHelper.get_value(win, "Azimuth"))
      areas[azimuth] += Float(XMLHelper.get_value(win, "Area"))
      u_factor += Float(XMLHelper.get_value(win, "UFactor"))
      shgc = Float(XMLHelper.get_value(win, "SHGC"))
      shading_winter = Float(XMLHelper.get_value(win, "extension/InteriorShadingFactorWinter"))
      shading_summer = Float(XMLHelper.get_value(win, "extension/InteriorShadingFactorSummer"))
      shgc_htg += (shgc * shading_winter)
      shgc_clg += (shgc * shading_summer)
      num += 1
    end
    return areas, u_factor / num, shgc_htg / num, shgc_clg / num
  end

  def _get_infiltration(hpxml_doc)
    ach50 = Float(XMLHelper.get_value(hpxml_doc, "/HPXML/Building/BuildingDetails/Enclosure/AirInfiltration/AirInfiltrationMeasurement[HousePressure='50']/BuildingAirLeakage[UnitofMeasure='ACH']/AirLeakage"))
    cfa = Float(XMLHelper.get_value(hpxml_doc, "/HPXML/Building/BuildingDetails/BuildingSummary/BuildingConstruction/ConditionedFloorArea"))
    infil_volume = Float(XMLHelper.get_value(hpxml_doc, "/HPXML/Building/BuildingDetails/Enclosure/AirInfiltration/AirInfiltrationMeasurement/InfiltrationVolume"))
    sla = Airflow.get_infiltration_SLA_from_ACH50(ach50, 0.65, cfa, infil_volume)
    return sla, ach50
  end

  def _get_internal_gains(hpxml_doc)
    s = ""
    nbeds = Float(XMLHelper.get_value(hpxml_doc, "/HPXML/Building/BuildingDetails/BuildingSummary/BuildingConstruction/NumberofBedrooms"))
    cfa = Float(XMLHelper.get_value(hpxml_doc, "/HPXML/Building/BuildingDetails/BuildingSummary/BuildingConstruction/ConditionedFloorArea"))
    eri_version = XMLHelper.get_value(hpxml_doc, "/HPXML/SoftwareInfo/extension/ERICalculation/Version")
    gfa = Float(hpxml_doc.elements["sum(/HPXML/Building/BuildingDetails/Enclosure/Garages/Garage/Slabs/Slab/Area/text())"])

    xml_pl_sens = 0.0
    xml_pl_lat = 0.0

    # Plug loads: Televisions
    annual_kwh, frac_sens, frac_lat = MiscLoads.get_televisions_values(cfa, nbeds)
    btu = UnitConversions.convert(annual_kwh, "kWh", "Btu")
    xml_pl_sens += (frac_sens * btu)
    xml_pl_lat += (frac_lat * btu)
    s += "#{xml_pl_sens} #{xml_pl_lat}\n"

    # Plug loads: Residual
    annual_kwh, frac_sens, frac_lat = MiscLoads.get_residual_mels_values(cfa)
    btu = UnitConversions.convert(annual_kwh, "kWh", "Btu")
    xml_pl_sens += (frac_sens * btu)
    xml_pl_lat += (frac_lat * btu)
    s += "#{xml_pl_sens} #{xml_pl_lat}\n"

    xml_appl_sens = 0.0
    xml_appl_lat = 0.0

    # Appliances: CookingRange
    hpxml_doc.elements.each("/HPXML/Building/BuildingDetails/Appliances/CookingRange") do |appl|
      cook_fuel_type = to_beopt_fuel(XMLHelper.get_value(appl, "FuelType"))
      cook_is_induction = Boolean(XMLHelper.get_value(appl, "IsInduction"))
      oven_is_convection = Boolean(XMLHelper.get_value(appl, "../Oven/IsConvection"))
      cook_annual_kwh, cook_annual_therm, cook_frac_sens, cook_frac_lat = HotWaterAndAppliances.calc_range_oven_energy(nbeds, cook_fuel_type, cook_is_induction, oven_is_convection)
      btu = UnitConversions.convert(cook_annual_kwh, "kWh", "Btu") + UnitConversions.convert(cook_annual_therm, "therm", "Btu")
      xml_appl_sens += (cook_frac_sens * btu)
      xml_appl_lat += (cook_frac_lat * btu)
    end

    # Appliances: Refrigerator
    hpxml_doc.elements.each("/HPXML/Building/BuildingDetails/Appliances/Refrigerator") do |appl|
      btu = UnitConversions.convert(Float(XMLHelper.get_value(appl, "RatedAnnualkWh")), "kWh", "Btu")
      xml_appl_sens += btu
    end

    # Appliances: Dishwasher
    hpxml_doc.elements.each("/HPXML/Building/BuildingDetails/Appliances/Dishwasher") do |appl|
      dw_ef = Float(XMLHelper.get_value(appl, "EnergyFactor"))
      dw_cap = Float(XMLHelper.get_value(appl, "PlaceSettingCapacity"))
      dw_annual_kwh, dw_frac_sens, dw_frac_lat, dw_gpd = HotWaterAndAppliances.calc_dishwasher_energy_gpd(eri_version, nbeds, dw_ef, dw_cap)
      btu = UnitConversions.convert(dw_annual_kwh, "kWh", "Btu")
      xml_appl_sens += (dw_frac_sens * btu)
      xml_appl_lat += (dw_frac_lat * btu)
    end

    # Appliances: ClothesWasher
    hpxml_doc.elements.each("/HPXML/Building/BuildingDetails/Appliances/ClothesWasher") do |appl|
      cw_ler = Float(XMLHelper.get_value(appl, "RatedAnnualkWh"))
      cw_elec_rate = Float(XMLHelper.get_value(appl, "LabelElectricRate"))
      cw_gas_rate = Float(XMLHelper.get_value(appl, "LabelGasRate"))
      cw_agc = Float(XMLHelper.get_value(appl, "LabelAnnualGasCost"))
      cw_cap = Float(XMLHelper.get_value(appl, "Capacity"))
      cw_annual_kwh, cw_frac_sens, cw_frac_lat, cw_gpd = HotWaterAndAppliances.calc_clothes_washer_energy_gpd(eri_version, nbeds, cw_ler, cw_elec_rate, cw_gas_rate, cw_agc, cw_cap)
      btu = UnitConversions.convert(cw_annual_kwh, "kWh", "Btu")
      xml_appl_sens += (cw_frac_sens * btu)
      xml_appl_lat += (cw_frac_lat * btu)
    end

    # Appliances: ClothesDryer
    hpxml_doc.elements.each("/HPXML/Building/BuildingDetails/Appliances/ClothesDryer") do |appl|
      cd_fuel = to_beopt_fuel(XMLHelper.get_value(appl, "FuelType"))
      cd_ef = Float(XMLHelper.get_value(appl, "EnergyFactor"))
      cd_control = XMLHelper.get_value(appl, "ControlType")
      cw_ler = Float(XMLHelper.get_value(appl, "../ClothesWasher/RatedAnnualkWh"))
      cw_cap = Float(XMLHelper.get_value(appl, "../ClothesWasher/Capacity"))
      cw_mef = Float(XMLHelper.get_value(appl, "../ClothesWasher/ModifiedEnergyFactor"))
      cd_annual_kwh, cd_annual_therm, cd_frac_sens, cd_frac_lat = HotWaterAndAppliances.calc_clothes_dryer_energy(nbeds, cd_fuel, cd_ef, cd_control, cw_ler, cw_cap, cw_mef)
      btu = UnitConversions.convert(cd_annual_kwh, "kWh", "Btu") + UnitConversions.convert(cd_annual_therm, "therm", "Btu")
      xml_appl_sens += (cd_frac_sens * btu)
      xml_appl_lat += (cd_frac_lat * btu)
    end

    s += "#{xml_appl_sens} #{xml_appl_lat}\n"

    # Water Use
    xml_water_sens, xml_water_lat = HotWaterAndAppliances.get_fixtures_gains_sens_lat(nbeds)
    s += "#{xml_water_sens} #{xml_water_lat}\n"

    # Occupants
    xml_occ_sens = 0.0
    xml_occ_lat = 0.0
    hpxml_doc.elements.each("/HPXML/Building/BuildingDetails/BuildingSummary/BuildingOccupancy") do |occ|
      num_occ = Float(XMLHelper.get_value(occ, "NumberofResidents"))
      heat_gain, hrs_per_day, frac_sens, frac_lat = Geometry.get_occupancy_default_values()
      btu = num_occ * heat_gain * hrs_per_day * 365.0
      xml_occ_sens += (frac_sens * btu)
      xml_occ_lat += (frac_lat * btu)
    end
    s += "#{xml_occ_sens} #{xml_occ_lat}\n"

    # Lighting
    xml_ltg_sens = 0.0
    hpxml_doc.elements.each("/HPXML/Building/BuildingDetails/Lighting") do |ltg|
      fFI_int = Float(XMLHelper.get_value(ltg, "LightingGroup[ThirdPartyCertification='ERI Tier I' and Location='interior']/FractionofUnitsInLocation"))
      fFI_ext = Float(XMLHelper.get_value(ltg, "LightingGroup[ThirdPartyCertification='ERI Tier I' and Location='exterior']/FractionofUnitsInLocation"))
      fFI_grg = Float(XMLHelper.get_value(ltg, "LightingGroup[ThirdPartyCertification='ERI Tier I' and Location='garage']/FractionofUnitsInLocation"))
      fFII_int = Float(XMLHelper.get_value(ltg, "LightingGroup[ThirdPartyCertification='ERI Tier II' and Location='interior']/FractionofUnitsInLocation"))
      fFII_ext = Float(XMLHelper.get_value(ltg, "LightingGroup[ThirdPartyCertification='ERI Tier II' and Location='exterior']/FractionofUnitsInLocation"))
      fFII_grg = Float(XMLHelper.get_value(ltg, "LightingGroup[ThirdPartyCertification='ERI Tier II' and Location='garage']/FractionofUnitsInLocation"))
      int_kwh, ext_kwh, grg_kwh = Lighting.calc_lighting_energy(eri_version, cfa, gfa, fFI_int, fFI_ext, fFI_grg, fFII_int, fFII_ext, fFII_grg)
      xml_ltg_sens += UnitConversions.convert(int_kwh + grg_kwh, "kWh", "Btu")
    end
    s += "#{xml_ltg_sens}\n"

    xml_btu_sens = (xml_pl_sens + xml_appl_sens + xml_water_sens + xml_occ_sens + xml_ltg_sens) / 365.0
    xml_btu_lat = (xml_pl_lat + xml_appl_lat + xml_water_lat + xml_occ_lat) / 365.0

    return xml_btu_sens, xml_btu_lat
  end

  def _get_hvac(hpxml_doc)
    afue = 0.0
    hspf = 0.0
    seer = 0.0
    dse = 0.0
    num_afue = 0
    num_hspf = 0
    num_seer = 0
    num_dse = 0
    hpxml_doc.elements.each("/HPXML/Building/BuildingDetails/Systems/HVAC/HVACPlant/HeatingSystem") do |htg|
      afue += Float(XMLHelper.get_value(htg, "AnnualHeatingEfficiency[Units='AFUE']/Value"))
      num_afue += 1
    end
    hpxml_doc.elements.each("/HPXML/Building/BuildingDetails/Systems/HVAC/HVACPlant/CoolingSystem") do |clg|
      seer += Float(XMLHelper.get_value(clg, "AnnualCoolingEfficiency[Units='SEER']/Value"))
      num_seer += 1
    end
    hpxml_doc.elements.each("/HPXML/Building/BuildingDetails/Systems/HVAC/HVACPlant/HeatPump") do |hp|
      if hp.elements["AnnualHeatingEfficiency[Units='HSPF']"]
        hspf += Float(XMLHelper.get_value(hp, "AnnualHeatingEfficiency[Units='HSPF']/Value"))
        num_hspf += 1
      end
      if hp.elements["AnnualCoolingEfficiency[Units='SEER']"]
        seer += Float(XMLHelper.get_value(hp, "AnnualCoolingEfficiency[Units='SEER']/Value"))
        num_seer += 1
      end
    end
    hpxml_doc.elements.each("/HPXML/Building/BuildingDetails/Systems/HVAC/HVACDistribution") do |dist|
      dse += Float(XMLHelper.get_value(dist, "AnnualHeatingDistributionSystemEfficiency"))
      num_dse += 1
      dse += Float(XMLHelper.get_value(dist, "AnnualCoolingDistributionSystemEfficiency"))
      num_dse += 1
    end
    return afue / num_afue, hspf / num_hspf, seer / num_seer, dse / num_dse
  end

  def _get_tstat(hpxml_doc)
    control = hpxml_doc.elements["/HPXML/Building/BuildingDetails/Systems/HVAC/HVACControl"]
    control_type = XMLHelper.get_value(control, "ControlType")
    tstat = control_type.gsub(" thermostat", "")
    htg_sp, htg_setback_sp, htg_setback_hrs_per_week, htg_setback_start_hr = HVAC.get_default_heating_setpoint(control_type)
    clg_sp, clg_setup_sp, clg_setup_hrs_per_week, clg_setup_start_hr = HVAC.get_default_cooling_setpoint(control_type)
    return tstat, htg_sp, htg_setback_sp, clg_sp, clg_setup_sp
  end

  def _get_mech_vent(hpxml_doc)
    mv_kwh = 0.0
    mv_cfm = 0.0
    hpxml_doc.elements.each("/HPXML/Building/BuildingDetails/Systems/MechanicalVentilation/VentilationFans/VentilationFan[UsedForWholeBuildingVentilation='true']") do |mv|
      hours = Float(XMLHelper.get_value(mv, "HoursInOperation"))
      fan_w = Float(XMLHelper.get_value(mv, "FanPower"))
      mv_kwh += fan_w * 8.76 * hours / 24.0
      mv_cfm += Float(XMLHelper.get_value(mv, "RatedFlowRate"))
    end
    return mv_kwh, mv_cfm
  end

  def _get_dhw(hpxml_doc)
    has_uncond_bsmnt = (not hpxml_doc.elements["/HPXML/Building/BuildingDetails/Enclosure/Foundations/FoundationType/Basement[Conditioned='false']"].nil?)
    cfa = Float(XMLHelper.get_value(hpxml_doc, "/HPXML/Building/BuildingDetails/BuildingSummary/BuildingConstruction/ConditionedFloorArea"))
    ncfl = Float(XMLHelper.get_value(hpxml_doc, "/HPXML/Building/BuildingDetails/BuildingSummary/BuildingConstruction/NumberofConditionedFloors"))
    ref_pipe_l = HotWaterAndAppliances.get_default_std_pipe_length(has_uncond_bsmnt, cfa, ncfl)
    ref_loop_l = HotWaterAndAppliances.get_default_recirc_loop_length(ref_pipe_l)
    return ref_pipe_l, ref_loop_l
  end

  def _get_eri(results_csv)
    CSV.foreach(results_csv) do |row|
      next if row[0] != "ERI"

      return Float(row[1])
    end
  end

  def _get_method_results(results_csv)
    results = {}
    CSV.foreach(results_csv) do |row|
      if row[1].include? "," # Occurs if, e.g., multiple HVAC
        results[row[0]] = row[1]
      else
        results[row[0]] = Float(row[1])
      end
    end

    return results
  end

  def _check_method_results(results, test_num, has_tankless_water_heater, using_iaf)
    cooling_fuel =  { 1 => 'elec', 2 => 'elec', 3 => 'elec', 4 => 'elec', 5 => 'elec' }
    cooling_mepr =  { 1 => 10.00,  2 => 10.00,  3 => 10.00,  4 => 10.00,  5 => 10.00 }
    heating_fuel =  { 1 => 'elec', 2 => 'elec', 3 => 'gas',  4 => 'elec', 5 => 'gas' }
    heating_mepr =  { 1 => 6.80,   2 => 6.80,   3 => 0.78,   4 => 9.85,   5 => 0.96  }
    hotwater_fuel = { 1 => 'elec', 2 => 'gas',  3 => 'elec', 4 => 'elec', 5 => 'elec' }
    hotwater_mepr = { 1 => 0.88,   2 => 0.82,   3 => 0.88,   4 => 0.88,   5 => 0.88  }
    ec_x_la =       { 1 => 21.27,  2 => 23.33,  3 => 22.05,  4 => 22.35,  5 => 23.33 }

    cfa = { 1 => 1539, 2 => 1539, 3 => 1539, 4 => 1539, 5 => 1539 }
    nbr = { 1 => 3,    2 => 3,    3 => 2,    4 => 4,    5 => 3 }
    nst = { 1 => 1,    2 => 1,    3 => 1,    4 => 1,    5 => 1 }

    _check_method_results_eri(test_num, results, cooling_fuel, cooling_mepr, heating_fuel, heating_mepr, hotwater_fuel, hotwater_mepr, ec_x_la, has_tankless_water_heater, using_iaf, cfa, nbr, nst)
  end

  def _check_method_proposed_results(results, test_num, test_loc, has_tankless_water_heater)
    if test_loc == 'AC'
      cooling_fuel =  { 6 => 'elec', 7 => 'elec', 8 => 'elec', 9 => 'elec', 10 => 'elec', 11 => 'elec', 12 => 'elec', 13 => 'elec', 14 => 'elec', 15 => 'elec', 16 => 'elec', 17 => 'elec', 18 => 'elec', 19 => 'elec', 20 => 'elec', 21 => 'elec', 22 => 'elec' }
      cooling_mepr =  { 6 => 13.00,  7 => 13.00,  8 => 13.00,  9 => 13.00,  10 => 13.00,  11 => 13.00,  12 => 13.00,  13 => 13.00,  14 => 21.00,  15 => 13.00,  16 => 13.00,  17 => 13.00,  18 => 13.00,  19 => 13.00,  20 => 13.00,  21 => 13.00,  22 => 13.00 }
      heating_fuel =  { 6 => 'gas',  7 => 'gas',  8 => 'gas',  9 => 'gas',  10 => 'gas',  11 => 'gas',  12 => 'gas',  13 => 'gas',  14 => 'gas',  15 => 'gas',  16 => 'gas',  17 => 'gas',  18 => 'gas',  19 => 'elec', 20 => 'elec', 21 => 'gas',  22 => 'gas' }
      heating_mepr =  { 6 => 0.80,   7 => 0.96,   8 => 0.80,   9 => 0.80,   10 => 0.80,   11 => 0.80,   12 => 0.80,   13 => 0.80,   14 => 0.80,   15 => 0.80,   16 => 0.80,   17 => 0.80,   18 => 0.80,   19 => 8.20,   20 => 12.0,   21 => 0.80,   22 => 0.80  }
      hotwater_fuel = { 6 => 'gas',  7 => 'gas',  8 => 'gas',  9 => 'gas',  10 => 'gas',  11 => 'gas',  12 => 'elec', 13 => 'elec', 14 => 'gas',  15 => 'gas',  16 => 'gas',  17 => 'gas',  18 => 'gas',  19 => 'gas',  20 => 'gas',  21 => 'gas',  22 => 'gas' }
      hotwater_mepr = { 6 => 0.62,   7 => 0.62,   8 => 0.83,   9 => 0.62,   10 => 0.62,   11 => 0.62,   12 => 0.95,   13 => 2.50,   14 => 0.62,   15 => 0.62,   16 => 0.62,   17 => 0.62,   18 => 0.62,   19 => 0.62,   20 => 0.62,   21 => 0.62,   22 => 0.62  }
      ec_x_la =       { 6 => 21.86,  7 => 21.86,  8 => 21.86,  9 => 20.70,  10 => 23.02,  11 => 23.92,  12 => 21.86,  13 => 21.86,  14 => 21.86,  15 => 21.86,  16 => 21.86,  17 => 21.86,  18 => 21.86,  19 => 21.86,  20 => 21.86,  21 => 21.86,  22 => 21.86 }
    elsif test_loc == 'AL'
      cooling_fuel =  { 6 => 'elec', 7 => 'elec', 8 => 'elec', 9 => 'elec', 10 => 'elec', 11 => 'elec', 12 => 'elec', 13 => 'elec', 14 => 'elec', 15 => 'elec', 16 => 'elec', 17 => 'elec', 18 => 'elec', 19 => 'elec', 20 => 'elec', 21 => 'elec', 22 => 'elec' }
      cooling_mepr =  { 6 => 14.00,  7 => 14.00,  8 => 14.00,  9 => 14.00,  10 => 14.00,  11 => 14.00,  12 => 14.00,  13 => 14.00,  14 => 21.00,  15 => 14.00,  16 => 14.00,  17 => 14.00,  18 => 14.00,  19 => 14.00,  20 => 14.00,  21 => 14.00,  22 => 14.00 }
      heating_fuel =  { 6 => 'gas',  7 => 'gas',  8 => 'gas',  9 => 'gas',  10 => 'gas',  11 => 'gas',  12 => 'gas',  13 => 'gas',  14 => 'gas',  15 => 'gas',  16 => 'gas',  17 => 'gas',  18 => 'gas',  19 => 'elec', 20 => 'elec', 21 => 'gas',  22 => 'gas' }
      heating_mepr =  { 6 => 0.80,   7 => 0.96,   8 => 0.80,   9 => 0.80,   10 => 0.80,   11 => 0.80,   12 => 0.80,   13 => 0.80,   14 => 0.80,   15 => 0.80,   16 => 0.80,   17 => 0.80,   18 => 0.80,   19 => 8.20,   20 => 12.0,   21 => 0.80,   22 => 0.80  }
      hotwater_fuel = { 6 => 'gas',  7 => 'gas',  8 => 'gas',  9 => 'gas',  10 => 'gas',  11 => 'gas',  12 => 'elec', 13 => 'elec', 14 => 'gas',  15 => 'gas',  16 => 'gas',  17 => 'gas',  18 => 'gas',  19 => 'gas',  20 => 'gas',  21 => 'gas',  22 => 'gas' }
      hotwater_mepr = { 6 => 0.62,   7 => 0.62,   8 => 0.83,   9 => 0.62,   10 => 0.62,   11 => 0.62,   12 => 0.95,   13 => 2.50,   14 => 0.62,   15 => 0.62,   16 => 0.62,   17 => 0.62,   18 => 0.62,   19 => 0.62,   20 => 0.62,   21 => 0.62,   22 => 0.62  }
      ec_x_la =       { 6 => 21.86,  7 => 21.86,  8 => 21.86,  9 => 20.70,  10 => 23.02,  11 => 23.92,  12 => 21.86,  13 => 21.86,  14 => 21.86,  15 => 21.86,  16 => 21.86,  17 => 21.86,  18 => 21.86,  19 => 21.86,  20 => 21.86,  21 => 21.86,  22 => 21.86 }
    end

    _check_method_results_eri(test_num, results, cooling_fuel, cooling_mepr, heating_fuel, heating_mepr, hotwater_fuel, hotwater_mepr, ec_x_la, has_tankless_water_heater, false, nil, nil, nil)
  end

  def _check_method_task_group_results(results, test_num, test_loc, has_tankless_water_heater)
    cooling_fuel =  { 1 => 'elec', 2 => 'elec', 3 => 'elec', 4 => 'elec', 5 => 'elec', 6 => 'elec', 7 => 'elec', 8 => 'elec', 9 => 'elec', 10 => 'elec', 11 => 'elec', 12 => 'elec' }
    cooling_mepr =  { 1 => 10.00,  2 => 10.00,  3 => 10.00,  4 => 10.00,  5 => 10.00,  6 => 10.00,  7 => 10.00,  8 => 10.00,  9 => 10.00,  10 => 10.00,  11 => 10.00,  12 => 10.00  }
    heating_fuel =  { 1 => 'elec', 2 => 'elec', 3 => 'gas',  4 => 'elec', 5 => 'gas',  6 => 'elec', 7 => 'elec', 8 => 'elec', 9 => 'elec', 10 => 'elec', 11 => 'elec', 12 => 'elec' }
    heating_mepr =  { 1 => 6.80,   2 => 6.80,   3 => 0.78,   4 => 9.85,   5 => 0.96,   6 => 6.80,   7 => 6.80,   8 => 6.80,   9 => 6.80,   10 => 6.80,   11 => 6.80,   12 => 6.80   }
    hotwater_fuel = { 1 => 'elec', 2 => 'gas',  3 => 'elec', 4 => 'elec', 5 => 'elec', 6 => 'elec', 7 => 'elec', 8 => 'elec', 9 => 'elec', 10 => 'elec', 11 => 'elec', 12 => 'elec' }
    hotwater_mepr = { 1 => 0.88,   2 => 0.82,   3 => 0.88,   4 => 0.88,   5 => 0.88,   6 => 0.88,   7 => 0.88,   8 => 0.88,   9 => 0.88,   10 => 0.88,   11 => 0.88,   12 => 0.88   }
    ec_x_la =       { 1 => 21.27,  2 => 23.33,  3 => 22.05,  4 => 22.35,  5 => 23.33,  6 => 21.27,  7 => 21.27,  8 => 21.27,  9 => 21.27,  10 => 21.27,  11 => 21.27,  12 => 21.27  }

    _check_method_results_eri(test_num, results, cooling_fuel, cooling_mepr, heating_fuel, heating_mepr, hotwater_fuel, hotwater_mepr, ec_x_la, has_tankless_water_heater, false, nil, nil, nil)
  end

  def _check_method_results_eri(test_num, results, cooling_fuel, cooling_mepr, heating_fuel, heating_mepr, hotwater_fuel, hotwater_mepr, ec_x_la, has_tankless_water_heater, using_iaf, cfa, nbr, nst)
    if heating_fuel[test_num] == 'gas'
      heating_a = 1.0943
      heating_b = 0.403
      heating_eec_r = 1.0 / 0.78
      heating_eec_x = 1.0 / heating_mepr[test_num]
    else
      heating_a = 2.2561
      heating_b = 0.0
      heating_eec_r = 3.413 / 7.7
      heating_eec_x = 3.413 / heating_mepr[test_num]
    end

    cooling_a = 3.8090
    cooling_b = 0.0
    cooling_eec_r = 3.413 / 13.0
    cooling_eec_x = 3.413 / cooling_mepr[test_num]

    if hotwater_fuel[test_num] == 'gas'
      hotwater_a = 1.1877
      hotwater_b = 1.013
      hotwater_eec_r = 1.0 / 0.59
    else
      hotwater_a = 0.92
      hotwater_b = 0.0
      hotwater_eec_r = 1.0 / 0.92
    end
    if not has_tankless_water_heater
      hotwater_eec_x = 1.0 / hotwater_mepr[test_num]
    else
      hotwater_eec_x = 1.0 / (hotwater_mepr[test_num] * 0.92)
    end

    heating_dse_r = results['REUL Heating (MBtu)'] / results['EC_r Heating (MBtu)'] * heating_eec_r
    cooling_dse_r = results['REUL Cooling (MBtu)'] / results['EC_r Cooling (MBtu)'] * cooling_eec_r
    hotwater_dse_r = results['REUL Hot Water (MBtu)'] / results['EC_r Hot Water (MBtu)'] * hotwater_eec_r

    heating_nec_x = (heating_a * heating_eec_x - heating_b) * (results['EC_x Heating (MBtu)'] * results['EC_r Heating (MBtu)'] * heating_dse_r) / (heating_eec_x * results['REUL Heating (MBtu)'])
    cooling_nec_x = (cooling_a * cooling_eec_x - cooling_b) * (results['EC_x Cooling (MBtu)'] * results['EC_r Cooling (MBtu)'] * cooling_dse_r) / (cooling_eec_x * results['REUL Cooling (MBtu)'])
    hotwater_nec_x = (hotwater_a * hotwater_eec_x - hotwater_b) * (results['EC_x Hot Water (MBtu)'] * results['EC_r Hot Water (MBtu)'] * hotwater_dse_r) / (hotwater_eec_x * results['REUL Hot Water (MBtu)'])

    heating_nmeul = results['REUL Heating (MBtu)'] * (heating_nec_x / results['EC_r Heating (MBtu)'])
    cooling_nmeul = results['REUL Cooling (MBtu)'] * (cooling_nec_x / results['EC_r Cooling (MBtu)'])
    hotwater_nmeul = results['REUL Hot Water (MBtu)'] * (hotwater_nec_x / results['EC_r Hot Water (MBtu)'])

    if using_iaf
      iaf_cfa = ((2400.0 / cfa[test_num])**(0.304 * results['IAD_Save (%)']))
      iaf_nbr = (1.0 + (0.069 * results['IAD_Save (%)'] * (nbr[test_num] - 3.0)))
      iaf_nst = ((2.0 / nst[test_num])**(0.12 * results['IAD_Save (%)']))
      iaf_rh = iaf_cfa * iaf_nbr * iaf_nst
    end

    tnml = heating_nmeul + cooling_nmeul + hotwater_nmeul + results['EC_x L&A (MBtu)']
    trl = results['REUL Heating (MBtu)'] + results['REUL Cooling (MBtu)'] + results['REUL Hot Water (MBtu)'] + ec_x_la[test_num]

    if using_iaf
      trl_iaf = trl * iaf_rh
      eri = 100 * tnml / trl_iaf
    else
      eri = 100 * tnml / trl
    end

    assert_operator((results['ERI'] - eri).abs / results['ERI'], :<, 0.005)
  end

  def _check_hvac_test_results(xml, results, base_results)
    percent_min = nil
    percent_max = nil

    # Table 4.4.4.1(2): Air Conditioning System Acceptance Criteria
    if xml == 'HVAC1b.xml'
      percent_min = -21.2
      percent_max = -17.4
    end

    # Table 4.4.4.2(2): Gas Heating System Acceptance Criteria
    if xml == 'HVAC2b.xml'
      percent_min = -13.3
      percent_max = -11.6
    end

    # Table 4.4.4.2(4): Electric Heating System Acceptance Criteria
    if xml == 'HVAC2d.xml'
      percent_min = -29.0
      percent_max = -16.7
    elsif xml == 'HVAC2e.xml'
      percent_min = 41.8
      percent_max = 80.8
    end

    if xml == 'HVAC2b.xml'
      curr_val = results[0] / 10.0 + results[1] / 293.0
      base_val = base_results[0] / 10.0 + base_results[1] / 293.0
    else
      curr_val = results[0] + results[1]
      base_val = base_results[0] + base_results[1]
    end

    percent_change = (curr_val - base_val) / base_val * 100.0

    # FIXME: Test checks currently disabled
    # assert_operator(percent_change, :>=, percent_min)
    # assert_operator(percent_change, :<=, percent_max)
  end

  def _check_dse_test_results(xml, results, base_results)
    percent_min = nil
    percent_max = nil

    # Table 4.5.3(2): Heating Energy DSE Comparison Test Acceptance Criteria
    if xml == 'HVAC3b.xml'
      percent_min = 21.4
      percent_max = 31.4
    elsif xml == 'HVAC3c.xml'
      percent_min = 2.5
      percent_max = 12.5
    elsif xml == 'HVAC3d.xml'
      percent_min = 15.0
      percent_max = 25.0
    end

    # Table 4.5.4(2): Cooling Energy DSE Comparison Test Acceptance Criteria
    if xml == 'HVAC3f.xml'
      percent_min = 26.2
      percent_max = 36.2
    elsif xml == 'HVAC3g.xml'
      percent_min = 6.5
      percent_max = 16.5
    elsif xml == 'HVAC3h.xml'
      percent_min = 21.1
      percent_max = 31.1
    end

    if ['HVAC3b.xml', 'HVAC3c.xml', 'HVAC3d.xml'].include? xml
      curr_val = results[0] / 10.0 + results[1] / 293.0
      base_val = base_results[0] / 10.0 + base_results[1] / 293.0
    else
      curr_val = results[0] + results[1]
      base_val = base_results[0] + base_results[1]
    end

    percent_change = (curr_val - base_val) / base_val * 100.0

    # FIXME: Test checks currently disabled
    # assert_operator(percent_change, :>=, percent_min)
    # assert_operator(percent_change, :<=, percent_max)
  end

  def _get_hot_water(results_csv)
    rated_dhw = nil
    CSV.foreach(results_csv) do |row|
      next if row[0] != "EC_x Hot Water (MBtu)"

      rated_dhw = Float(row[1])
      break
    end
    return rated_dhw
  end

  def _check_hot_water(test_num, curr_val, base_val = nil, mn_val = nil)
    # Table 4.6.2(1): Acceptance Criteria for Hot Water Tests
    min_max_abs = nil
    min_max_base_delta_percent = nil
    min_max_mn_delta_percent = nil
    if test_num == 1
      min_max_abs = [19.11, 19.73]
    elsif test_num == 2
      min_max_abs = [25.54, 26.36]
      min_max_base_delta_percent = [-34.01, -32.49]
    elsif test_num == 3
      min_max_abs = [17.03, 17.50]
      min_max_base_delta_percent = [10.74, 11.57]
    elsif test_num == 4
      min_max_abs = [24.75, 25.52]
      min_max_base_delta_percent = [3.06, 3.22]
    elsif test_num == 5
      min_max_abs = [55.43, 57.15]
      min_max_base_delta_percent = [-118.52, -115.63]
    elsif test_num == 6
      min_max_abs = [22.39, 23.09]
      min_max_base_delta_percent = [12.17, 12.51]
    elsif test_num == 7
      min_max_abs = [20.29, 20.94]
      min_max_base_delta_percent = [20.15, 20.78]
    elsif test_num == 8
      min_max_abs = [10.59, 11.03]
      min_max_mn_delta_percent = [43.35, 45.00]
    elsif test_num == 9
      min_max_abs = [13.17, 13.68]
      min_max_base_delta_percent = [-24.54, -23.47]
      min_max_mn_delta_percent = [47.26, 48.93]
    elsif test_num == 10
      min_max_abs = [8.81, 9.13]
      min_max_base_delta_percent = [16.65, 18.12]
      min_max_mn_delta_percent = [47.38, 48.74]
    elsif test_num == 11
      min_max_abs = [12.87, 13.36]
      min_max_base_delta_percent = [2.20, 2.38]
      min_max_mn_delta_percent = [46.81, 48.48]
    elsif test_num == 12
      min_max_abs = [30.19, 31.31]
      min_max_base_delta_percent = [-130.88, -127.52]
      min_max_mn_delta_percent = [44.41, 45.99]
    elsif test_num == 13
      min_max_abs = [11.90, 12.38]
      min_max_base_delta_percent = [9.38, 9.74]
      min_max_mn_delta_percent = [45.60, 47.33]
    elsif test_num == 14
      min_max_abs = [11.68, 12.14]
      min_max_base_delta_percent = [11.00, 11.40]
      min_max_mn_delta_percent = [41.32, 42.86]
    else
      fail "Unexpected test."
    end

    base_delta_percent = nil
    mn_delta_percent = nil
    if not min_max_base_delta_percent.nil? and not base_val.nil?
      base_delta_percent = (base_val - curr_val) / base_val * 100.0 # %
    end
    if not min_max_mn_delta_percent.nil? and not mn_val.nil?
      mn_delta_percent = (mn_val - curr_val) / mn_val * 100.0 # %
    end

    assert_operator(curr_val, :>=, min_max_abs[0])
    assert_operator(curr_val, :<=, min_max_abs[1])
    if not base_delta_percent.nil?
      assert_operator(base_delta_percent, :>=, min_max_base_delta_percent[0])
      assert_operator(base_delta_percent, :<=, min_max_base_delta_percent[1])
    end
    if not mn_delta_percent.nil?
      assert_operator(mn_delta_percent, :>=, min_max_mn_delta_percent[0])
      assert_operator(mn_delta_percent, :<=, min_max_mn_delta_percent[1])
    end
  end

  def _check_hot_water_pre_addendum_a(test_num, curr_val, base_val = nil, mn_val = nil)
    # Acceptance criteria from Hot Water Performance Tests Excel spreadsheet
    min_max_abs = nil
    min_max_fl_delta_abs = nil
    min_max_base_delta_percent = nil
    min_max_fl_delta_percent = nil
    if test_num == 1
      min_max_abs = [18.2, 22.0]
    elsif test_num == 2
      min_max_base_delta_percent = [26.5, 32.2]
    elsif test_num == 3
      min_max_base_delta_percent = [-11.8, -6.8]
    elsif test_num == 4
      min_max_abs = [10.9, 14.4]
      min_max_fl_delta_abs = [5.5, 9.4]
      min_max_fl_delta_percent = [28.9, 45.1]
    elsif test_num == 5
      min_max_base_delta_percent = [19.1, 29.1]
    elsif test_num == 6
      min_max_base_delta_percent = [-19.5, -7.7]
    else
      fail "Unexpected test."
    end

    base_delta = nil
    mn_delta = nil
    fl_delta_percent = nil
    if not min_max_base_delta_percent.nil? and not base_val.nil?
      base_delta = (curr_val - base_val) / base_val * 100.0 # %
    end
    if not min_max_fl_delta_abs.nil? and not mn_val.nil?
      fl_delta = mn_val - curr_val
    end
    if not min_max_fl_delta_percent.nil? and not mn_val.nil?
      fl_delta_percent = (mn_val - curr_val) / mn_val * 100.0 # %
    end

    if not min_max_abs.nil?
      assert_operator(curr_val, :>=, min_max_abs[0])
      assert_operator(curr_val, :<=, min_max_abs[1])
    end
    if not base_delta.nil?
      assert_operator(base_delta, :>=, min_max_base_delta_percent[0])
      assert_operator(base_delta, :<=, min_max_base_delta_percent[1])
    end
    if not fl_delta.nil?
      assert_operator(fl_delta, :>=, min_max_fl_delta_abs[0])
      assert_operator(fl_delta, :<=, min_max_fl_delta_abs[1])
    end
    if not fl_delta_percent.nil?
      assert_operator(fl_delta_percent, :>=, min_max_fl_delta_percent[0])
      assert_operator(fl_delta_percent, :<=, min_max_fl_delta_percent[1])
    end
  end

  def _rm_path(path)
    if Dir.exists?(path)
      FileUtils.rm_r(path)
    end
    while true
      break if not Dir.exists?(path)

      sleep(0.01)
    end
  end
end
