# frozen_string_literal: true

require_relative '../../hpxml-measures/HPXMLtoOpenStudio/resources/minitest_helper'
require 'openstudio'
require 'openstudio/measure/ShowRunnerOutput'
require 'fileutils'
require 'csv'
require 'oga'
require_relative '../../rulesets/EnergyStarRuleset/resources/constants'
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
      all_results[File.basename(xml)] = _get_csv_results(csvs[:eri_results])

      _rm_path(rundir)
    end
    assert(all_results.size > 0)

    # Write results to csv
    keys = all_results.values[0].keys
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

    # Cross-simulation tests

    # Verify that REUL Hot Water is identical across water heater types
    _test_reul(all_results, 'base.xml', 'base-dhw', 'REUL Hot Water (MBtu)')

    # Verify that REUL Heating/Cooling are identical across HVAC types
    _test_reul(all_results, 'base.xml', 'base-hvac', 'REUL Heating (MBtu)')
    _test_reul(all_results, 'base.xml', 'base-hvac', 'REUL Cooling (MBtu)')
  end

  def test_sample_files_energystar
    test_name = 'sample_files_energystar'
    test_results_csv = File.absolute_path(File.join(@test_results_dir, "#{test_name}.csv"))
    File.delete(test_results_csv) if File.exist? test_results_csv

    all_results = {}

    ESConstants.AllVersions.each do |program_version|
      # Run simulations
      version_results = {}
      files = 'base*.xml'
      xmldir = "#{File.dirname(__FILE__)}/../sample_files"
      Dir["#{xmldir}/#{files}"].sort.each do |xml|
        next unless File.exist?(xml)
        next if xml.include? 'base-version'

        if [ESConstants.SFNationalVer3_1].include? program_version
          # Run all files (MF files converted to SFA below)
        elsif [ESConstants.SFNationalVer3_0].include? program_version
          next unless xml.include?('base.xml') # One file
        elsif [ESConstants.SFPacificVer3_0].include? program_version
          next unless xml.include? 'base-location-honolulu-hi.xml' # One file
        elsif [ESConstants.SFFloridaVer3_1].include? program_version
          next unless xml.include? 'base-location-miami-fl.xml' # One file
        elsif [ESConstants.SFOregonWashingtonVer3_2].include? program_version
          next unless xml.include? 'base-location-portland-or.xml' # One file
        elsif [ESConstants.MFNationalVer1_1].include? program_version
          next unless xml.include?('base-bldgtype-multifamily') || xml.include?('base-bldgtype-single-family-attached') # All MF/SFA files
        elsif [ESConstants.MFNationalVer1_0].include? program_version
          next unless xml.include?('base-bldgtype-multifamily.xml') || xml.include?('base-bldgtype-single-family-attached.xml') # Two files
        elsif [ESConstants.MFOregonWashingtonVer1_2].include? program_version
          next unless xml.include?('base-bldgtype-multifamily-location-portland-or.xml') # One file
        else
          fail "Unhandled ENERGY STAR version: #{program_version}."
        end

        puts "Running [#{program_version}] #{File.basename(xml)}..."

        # Create derivative files for ES testing
        hpxml = HPXML.new(hpxml_path: xml)
        hpxml.header.energystar_calculation_version = program_version
        if program_version == ESConstants.MFOregonWashingtonVer1_2
          hpxml.header.state_code = 'OR'
        end
        if (program_version == ESConstants.SFNationalVer3_1) && (hpxml.building_construction.residential_facility_type == HPXML::ResidentialTypeApartment)
          # Set HPXML file to SFA so that we can test it
          hpxml.building_construction.residential_facility_type = HPXML::ResidentialTypeSFA
        end

        es_xml = File.absolute_path(File.join(xmldir, 'tmp.xml'))
        XMLHelper.write_file(hpxml.to_oga, es_xml)

        rundir, hpxmls, csvs = _run_workflow(es_xml, test_name, run_energystar: true)
        key = "[#{program_version}] #{File.basename(xml)}"
        version_results[key] = _get_csv_results(csvs[:es_results])

        File.delete(es_xml)

        _rm_path(rundir)
      end
      assert(version_results.size > 0) # Ensure every ES version was tested against at least one sample file
      all_results.merge!(version_results)
    end

    # Write results to csv
    keys = all_results.values[0].keys
    CSV.open(test_results_csv, 'w') do |csv|
      csv << ['[Version] XML'] + keys
      all_results.each_with_index do |(xml_key, results), i|
        csv_line = [xml_key]
        keys.each do |key|
          csv_line << results[key]
        end
        csv << csv_line
      end
    end
    puts "Wrote results to #{test_results_csv}."
  end

  def test_sample_files_invalid
    xmldir = "#{File.dirname(__FILE__)}/../sample_files/invalid_files"
    test_name = 'invalid_files'

    # Test against ERI workflow
    expected_error_msgs = { 'invalid-epw-filepath.xml' => ["foo.epw' could not be found."],
                            'dhw-frac-load-served.xml' => ['Expected FractionDHWLoadServed to sum to 1, but calculated sum is 1.15.'],
                            'missing-elements.xml' => ['Expected 1 element(s) for xpath: NumberofConditionedFloors [context: /HPXML/Building/BuildingDetails/BuildingSummary/BuildingConstruction]',
                                                       'Expected 1 element(s) for xpath: ConditionedFloorArea [context: /HPXML/Building/BuildingDetails/BuildingSummary/BuildingConstruction]'],
                            'hvac-frac-load-served.xml' => ['Expected FractionCoolLoadServed to sum to <= 1, but calculated sum is 1.2.',
                                                            'Expected FractionHeatLoadServed to sum to <= 1, but calculated sum is 1.1.'],
                            'hvac-ducts-leakage-to-outside-exemption-pre-addendum-d.xml' => ['ERI Version 2014A does not support duct leakage testing exemption.'],
                            'hvac-ducts-leakage-total-pre-addendum-l.xml' => ['ERI Version 2014ADEG does not support total duct leakage testing.'],
                            'enclosure-floor-area-exceeds-cfa.xml' => ['Expected ConditionedFloorArea to be greater than or equal to the sum of conditioned slab/floor areas. [context: /HPXML/Building/BuildingDetails/BuildingSummary/BuildingConstruction]'] }

    Dir["#{xmldir}/*.xml"].sort.each do |xml|
      next if xml.include? 'energy-star'

      rundir, hpxmls, csvs = _run_workflow(xml, test_name, expect_error: true, expect_error_msgs: expected_error_msgs[File.basename(xml)])
      _rm_path(rundir)
    end

    # Test against ES workflow
    expected_error_msgs = { 'energy-star-SF_Florida_3.1.xml' => ['Expected 1 element(s) for xpath: ../../../../Building/BuildingDetails/BuildingSummary/BuildingConstruction[ResidentialFacilityType[text()="single-family detached" or text()="single-family attached"]]',
                                                                 'Expected 1 element(s) for xpath: ../../../../Building/Site/Address/StateCode[text()="FL"] [context: /HPXML/SoftwareInfo/extension/EnergyStarCalculation/Version[contains(text(), "SF_Florida")]]'],
                            'energy-star-SF_National_3.0.xml' => ['Expected 1 element(s) for xpath: ../../../../Building/BuildingDetails/BuildingSummary/BuildingConstruction[ResidentialFacilityType[text()="single-family detached" or text()="single-family attached"]] [context: /HPXML/SoftwareInfo/extension/EnergyStarCalculation/Version[contains(text(), "SF_National")]]'],
                            'energy-star-SF_National_3.1.xml' => ['Expected 1 element(s) for xpath: ../../../../Building/BuildingDetails/BuildingSummary/BuildingConstruction[ResidentialFacilityType[text()="single-family detached" or text()="single-family attached"]] [context: /HPXML/SoftwareInfo/extension/EnergyStarCalculation/Version[contains(text(), "SF_National")]]'],
                            'energy-star-SF_OregonWashington_3.2.xml' => ['Expected 1 element(s) for xpath: ../../../../Building/BuildingDetails/BuildingSummary/BuildingConstruction[ResidentialFacilityType[text()="single-family detached" or text()="single-family attached"]]',
                                                                          'Expected 1 element(s) for xpath: ../../../../Building/Site/Address/StateCode[text()="OR" or text()="WA"] [context: /HPXML/SoftwareInfo/extension/EnergyStarCalculation/Version[contains(text(), "SF_OregonWashington")]]'],
                            'energy-star-SF_Pacific_3.0.xml' => ['Expected 1 element(s) for xpath: ../../../../Building/BuildingDetails/BuildingSummary/BuildingConstruction[ResidentialFacilityType[text()="single-family detached" or text()="single-family attached"]]',
                                                                 'Expected 1 element(s) for xpath: ../../../../Building/Site/Address/StateCode[text()="HI" or text()="GU" or text()="MP"] [context: /HPXML/SoftwareInfo/extension/EnergyStarCalculation/Version[contains(text(), "SF_Pacific")]]'],
                            'energy-star-MF_National_1.0.xml' => ['Expected 1 element(s) for xpath: ../../../../Building/BuildingDetails/BuildingSummary/BuildingConstruction[ResidentialFacilityType[text()="single-family attached" or text()="apartment unit"]] [context: /HPXML/SoftwareInfo/extension/EnergyStarCalculation/Version[contains(text(), "MF_National")]]'],
                            'energy-star-MF_National_1.1.xml' => ['Expected 1 element(s) for xpath: ../../../../Building/BuildingDetails/BuildingSummary/BuildingConstruction[ResidentialFacilityType[text()="single-family attached" or text()="apartment unit"]] [context: /HPXML/SoftwareInfo/extension/EnergyStarCalculation/Version[contains(text(), "MF_National")]]'],
                            'energy-star-MF_OregonWashington_1.2.xml' => ['Expected 1 element(s) for xpath: ../../../../Building/BuildingDetails/BuildingSummary/BuildingConstruction[ResidentialFacilityType[text()="single-family attached" or text()="apartment unit"]] [context: /HPXML/SoftwareInfo/extension/EnergyStarCalculation/Version[contains(text(), "MF_National")]]',
                                                                          'Expected 1 element(s) for xpath: ../../../../Building/Site/Address/StateCode[text()="OR" or text()="WA"]'] }

    Dir["#{xmldir}/*.xml"].sort.each do |xml|
      next unless xml.include? 'energy-star'

      rundir, hpxmls, csvs = _run_workflow(xml, test_name, expect_error: true, expect_error_msgs: expected_error_msgs[File.basename(xml)], run_energystar: true)
      _rm_path(rundir)
    end
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

      # Run ENERGY STAR workflow
      xml = "#{File.dirname(__FILE__)}/../sample_files/base.xml"
      rundir, hpxmls, csvs = _run_workflow(xml, test_name, timeseries_frequency: timeseries_frequency, run_energystar: true)

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

  def test_epa
    test_name = 'EPA_Tests'
    test_results_csv = File.absolute_path(File.join(@test_results_dir, "#{test_name}.csv"))
    File.delete(test_results_csv) if File.exist? test_results_csv

    # Run simulations
    xmldir = File.join(File.dirname(__FILE__), 'EPA_Tests')
    all_results = {}
    Dir["#{xmldir}/**/*.xml"].sort.each do |xml|
      rundir, hpxmls, csvs = _run_workflow(xml, test_name, run_energystar: true)
      ref_results = _get_csv_results(csvs[:ref_eri_results])
      rated_results = _get_csv_results(csvs[:rated_eri_results])

      all_results[xml] = {}
      all_results[xml]['Reference Home ERI'] = ref_results['ERI']
      all_results[xml]['Rated Home ERI'] = rated_results['ERI']
    end
    assert(all_results.size > 0)

    # Write results to csv
    keys = all_results.values[0].keys
    CSV.open(test_results_csv, 'w') do |csv|
      csv << ['[Version] XML'] + keys
      all_results.each_with_index do |(xml, results), i|
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
    all_results.each do |xml, results|
      assert_equal(results['Reference Home ERI'], results['Rated Home ERI'])
    end
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
    Dir["#{top_dir}/OpenStudio-ERI*.zip"].each do |zip|
      unzip_file = OpenStudio::UnzipFile.new(zip)
      unzip_file.extractAllFiles(OpenStudio::toPath(top_dir))
      command = "\"#{OpenStudio.getOpenStudioCLI}\" OpenStudio-ERI/workflow/energy_rating_index.rb -x OpenStudio-ERI/workflow/sample_files/base.xml"
      system(command)
      assert(File.exist? 'OpenStudio-ERI/workflow/results/ERI_Results.csv')
      File.delete(zip)
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

  def _run_ruleset(design, xml, out_xml)
    model = OpenStudio::Model::Model.new
    runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)
    measures_dir = File.join(File.dirname(__FILE__), '..', '..')

    measures = {}

    # Add 301 measure to workflow
    measure_subdir = 'rulesets/301EnergyRatingIndexRuleset'
    args = {}
    args['calc_type'] = design
    args['hpxml_input_path'] = File.absolute_path(xml)
    args['hpxml_output_path'] = out_xml
    update_args_hash(measures, measure_subdir, args)

    # Apply measures
    FileUtils.mkdir_p(File.dirname(out_xml))
    success = apply_measures(measures_dir, measures, runner, model)
    show_output(runner.result) unless success
    assert(success)
    assert(File.exist?(out_xml))

    hpxml = XMLHelper.parse_file(out_xml)
    XMLHelper.delete_element(XMLHelper.get_element(hpxml, '/HPXML/SoftwareInfo/extension/ERICalculation'), 'Design')
    XMLHelper.write_file(hpxml, out_xml)
  end

  def _run_workflow(xml, test_name, expect_error: false, expect_error_msgs: nil, timeseries_frequency: 'none', run_energystar: false, component_loads: false)
    xml = File.absolute_path(xml)

    rundir = File.join(@test_files_dir, test_name, File.basename(xml))

    timeseries = ''
    if timeseries_frequency != 'none'
      timeseries = " --#{timeseries_frequency} ALL"
    end
    comploads = ''
    if component_loads
      comploads = ' --add-component-loads'
    end

    # Run workflow
    if run_energystar
      workflow_rb = 'energy_star.rb'
    else
      workflow_rb = 'energy_rating_index.rb'
    end
    command = "\"#{OpenStudio.getOpenStudioCLI}\" \"#{File.join(File.dirname(__FILE__), "../#{workflow_rb}")}\" -x #{xml}#{timeseries}#{comploads} -o #{rundir} --debug"
    start_time = Time.now
    system(command)
    runtime = (Time.now - start_time).round(2)

    hpxmls = {}
    csvs = {}
    if not run_energystar
      hpxmls[:ref] = File.join(rundir, 'results', 'ERIReferenceHome.xml')
      hpxmls[:rated] = File.join(rundir, 'results', 'ERIRatedHome.xml')
      csvs[:eri_results] = File.join(rundir, 'results', 'ERI_Results.csv')
      csvs[:eri_worksheet] = File.join(rundir, 'results', 'ERI_Worksheet.csv')
      csvs[:rated_results] = File.join(rundir, 'results', 'ERIRatedHome.csv')
      csvs[:ref_results] = File.join(rundir, 'results', 'ERIReferenceHome.csv')
      if timeseries_frequency != 'none'
        csvs[:rated_timeseries_results] = File.join(rundir, 'results', "ERIRatedHome_#{timeseries_frequency.capitalize}.csv")
        csvs[:ref_timeseries_results] = File.join(rundir, 'results', "ERIReferenceHome_#{timeseries_frequency.capitalize}.csv")
      end
      log_dirs = [Constants.CalcTypeERIRatedHome,
                  Constants.CalcTypeERIReferenceHome,
                  Constants.CalcTypeERIIndexAdjustmentDesign,
                  Constants.CalcTypeERIIndexAdjustmentReferenceHome].map { |d| d.gsub(' ', '') }
    else
      hpxmls[:ref] = File.join(rundir, 'results', 'ESReference.xml')
      hpxmls[:rated] = File.join(rundir, 'results', 'ESRated.xml')
      hpxmls[:ref_ref] = File.join(rundir, 'ESReference', 'results', 'ERIReferenceHome.xml')
      hpxmls[:ref_rated] = File.join(rundir, 'ESReference', 'results', 'ERIRatedHome.xml')
      hpxmls[:ref_iad] = File.join(rundir, 'ESReference', 'results', 'ERIIndexAdjustmentDesign.xml')
      hpxmls[:ref_iadref] = File.join(rundir, 'ESReference', 'results', 'ERIIndexAdjustmentReferenceHome.xml')
      hpxmls[:rated_ref] = File.join(rundir, 'ESRated', 'results', 'ERIReferenceHome.xml')
      hpxmls[:rated_rated] = File.join(rundir, 'ESRated', 'results', 'ERIRatedHome.xml')
      hpxmls[:rated_iad] = File.join(rundir, 'ESRated', 'results', 'ERIIndexAdjustmentDesign.xml')
      hpxmls[:rated_iadref] = File.join(rundir, 'ESRated', 'results', 'ERIIndexAdjustmentReferenceHome.xml')
      csvs[:es_results] = File.join(rundir, 'results', 'ES_Results.csv')
      csvs[:ref_eri_results] = File.join(rundir, 'ESReference', 'results', 'ERI_Results.csv')
      csvs[:ref_eri_worksheet] = File.join(rundir, 'ESReference', 'results', 'ERI_Worksheet.csv')
      csvs[:ref_rated_results] = File.join(rundir, 'ESReference', 'results', 'ERIRatedHome.csv')
      csvs[:ref_ref_results] = File.join(rundir, 'ESReference', 'results', 'ERIReferenceHome.csv')
      csvs[:ref_iad_results] = File.join(rundir, 'ESReference', 'results', 'ERIIndexAdjustmentDesign.csv')
      csvs[:ref_iadref_results] = File.join(rundir, 'ESReference', 'results', 'ERIIndexAdjustmentReferenceHome.csv')
      csvs[:rated_eri_results] = File.join(rundir, 'ESRated', 'results', 'ERI_Results.csv')
      csvs[:rated_eri_worksheet] = File.join(rundir, 'ESRated', 'results', 'ERI_Worksheet.csv')
      csvs[:rated_rated_results] = File.join(rundir, 'ESRated', 'results', 'ERIRatedHome.csv')
      csvs[:rated_ref_results] = File.join(rundir, 'ESRated', 'results', 'ERIReferenceHome.csv')
      csvs[:rated_iad_results] = File.join(rundir, 'ESRated', 'results', 'ERIIndexAdjustmentDesign.csv')
      csvs[:rated_iadref_results] = File.join(rundir, 'ESRated', 'results', 'ERIIndexAdjustmentReferenceHome.csv')
      if timeseries_frequency != 'none'
        csvs[:rated_timeseries_results] = File.join(rundir, 'ESRated', 'results', "ERIRatedHome_#{timeseries_frequency.capitalize}.csv")
        csvs[:ref_timeseries_results] = File.join(rundir, 'ESReference', 'results', "ERIReferenceHome_#{timeseries_frequency.capitalize}.csv")
      end
      log_dirs = [File.join('ESRated', Constants.CalcTypeERIRatedHome),
                  File.join('ESRated', Constants.CalcTypeERIReferenceHome),
                  File.join('ESRated', Constants.CalcTypeERIIndexAdjustmentDesign),
                  File.join('ESRated', Constants.CalcTypeERIIndexAdjustmentReferenceHome),
                  File.join('ESReference', Constants.CalcTypeERIRatedHome),
                  File.join('ESReference', Constants.CalcTypeERIReferenceHome),
                  File.join('ESReference', Constants.CalcTypeERIIndexAdjustmentDesign),
                  File.join('ESReference', Constants.CalcTypeERIIndexAdjustmentReferenceHome)].map { |d| d.gsub(' ', '') }
      log_dirs << 'results'
    end

    if expect_error
      if expect_error_msgs.nil?
        flunk "No error message defined for #{File.basename(xml)}."
      else
        found_error_msg = false
        log_dirs.each do |log_dir|
          next unless File.exist? File.join(rundir, log_dir, 'run.log')

          run_log = File.readlines(File.join(rundir, log_dir, 'run.log')).map(&:strip)
          expect_error_msgs.each do |error_msg|
            run_log.each do |run_line|
              next unless run_line.include? error_msg

              found_error_msg = true
              break
            end
          end
        end
        assert(found_error_msg)
      end
    else
      # Check all output files exist
      hpxmls.keys.each do |k|
        assert(File.exist?(hpxmls[k]))
      end
      csvs.keys.each do |k|
        assert(File.exist?(csvs[k]))
      end

      # Check HPXMLs are valid
      _test_schema_validation(xml)
      hpxmls.keys.each do |k|
        _test_schema_validation(hpxmls[k])
      end

      # Check run.log for OS warnings
      log_dirs.each do |log_dir|
        next unless File.exist? File.join(rundir, log_dir, 'run.log')

        run_log = File.readlines(File.join(rundir, log_dir, 'run.log')).map(&:strip)
        run_log.each do |log_line|
          next unless log_line.include? 'OS Message:'

          flunk "Unexpected warning found in #{log_dir} run.log: #{log_line}"
        end
      end
    end

    return rundir, hpxmls, csvs
  end

  def _run_simulation(xml, test_name)
    measures_dir = File.join(File.dirname(__FILE__), '..', '..')
    xml = File.absolute_path(xml)
    rundir = File.join(@test_files_dir, test_name, File.basename(xml))

    measures = {}

    # Add HPXML translator measure to workflow
    measure_subdir = 'hpxml-measures/HPXMLtoOpenStudio'
    args = {}
    args['output_dir'] = File.absolute_path(rundir)
    args['hpxml_path'] = xml
    update_args_hash(measures, measure_subdir, args)

    # Add reporting measure to workflow
    measure_subdir = 'hpxml-measures/SimulationOutputReport'
    args = {}
    args['timeseries_frequency'] = 'none'
    args['include_timeseries_fuel_consumptions'] = false
    args['include_timeseries_end_use_consumptions'] = false
    args['include_timeseries_hot_water_uses'] = false
    args['include_timeseries_total_loads'] = false
    args['include_timeseries_component_loads'] = false
    args['include_timeseries_unmet_loads'] = false
    args['include_timeseries_zone_temperatures'] = false
    args['include_timeseries_airflows'] = false
    args['include_timeseries_weather'] = false
    update_args_hash(measures, measure_subdir, args)

    results = run_hpxml_workflow(rundir, measures, measures_dir)

    assert(results[:success])

    sql_path = File.join(rundir, 'eplusout.sql')
    assert(File.exist?(sql_path))

    csv_path = File.join(rundir, 'results_annual.csv')
    assert(File.exist?(csv_path))

    return sql_path, csv_path, results[:sim_time]
  end

  def _test_reul(all_results, base_xml, files_include, result_name)
    base_results = all_results[base_xml]
    return if base_results.nil?

    puts "Checking for consistent #{result_name} compared to #{base_xml}..."
    base_reul = base_results[result_name]
    all_results.each do |compare_xml, compare_results|
      next unless compare_xml.include? files_include

      if compare_results[result_name].to_s.include? ','
        compare_reul = compare_results[result_name].split(',').map(&:to_f).inject(0, :+) # sum values
      else
        compare_reul = compare_results[result_name]
      end

      assert_in_delta(base_reul, compare_reul, 0.15)
    end
  end

  def _get_simulation_load_results(csv_path)
    results = _get_csv_results(csv_path)
    htg_load = results['Load: Heating (MBtu)'].round(2)
    clg_load = results['Load: Cooling (MBtu)'].round(2)

    return htg_load, clg_load
  end

  def _get_simulation_hvac_energy_results(csv_path, is_heat, is_electric_heat)
    results = _get_csv_results(csv_path)
    if not is_heat
      hvac = UnitConversions.convert(results['End Use: Electricity: Cooling (MBtu)'], 'MBtu', 'kwh').round(2)
      hvac_fan = UnitConversions.convert(results['End Use: Electricity: Cooling Fans/Pumps (MBtu)'], 'MBtu', 'kwh').round(2)
    else
      if is_electric_heat
        hvac = UnitConversions.convert(results['End Use: Electricity: Heating (MBtu)'], 'MBtu', 'kwh').round(2)
      else
        hvac = UnitConversions.convert(results['End Use: Natural Gas: Heating (MBtu)'], 'MBtu', 'therm').round(2)
      end
      hvac_fan = UnitConversions.convert(results['End Use: Electricity: Heating Fans/Pumps (MBtu)'], 'MBtu', 'kwh').round(2)
    end

    assert_operator(hvac, :>, 0)
    assert_operator(hvac_fan, :>, 0)

    return hvac.round(2), hvac_fan.round(2)
  end

  def _test_schema_validation(xml)
    # TODO: Remove this when schema validation is included with CLI calls
    schemas_dir = File.absolute_path(File.join(File.dirname(__FILE__), '..', '..', 'hpxml-measures', 'HPXMLtoOpenStudio', 'resources'))
    hpxml_doc = XMLHelper.parse_file(xml)
    errors = XMLHelper.validate(hpxml_doc.to_xml, File.join(schemas_dir, 'HPXML.xsd'), nil)
    if errors.size > 0
      puts "#{xml}: #{errors}"
    end
    assert_equal(0, errors.size)
  end

  def _check_ashrae_140_results(htg_loads, clg_loads)
    # Proposed acceptance criteria as of 10/1/2020

    # Annual Heating Loads
    assert_operator(htg_loads['L100AC'], :<=, 60.13)
    assert_operator(htg_loads['L100AC'], :>=, 48.35)
    assert_operator(htg_loads['L110AC'], :<=, 82.94)
    assert_operator(htg_loads['L110AC'], :>=, 73.60)
    assert_operator(htg_loads['L120AC'], :<=, 47.13)
    assert_operator(htg_loads['L120AC'], :>=, 35.98)
    assert_operator(htg_loads['L130AC'], :<=, 48.60)
    assert_operator(htg_loads['L130AC'], :>=, 39.75)
    assert_operator(htg_loads['L140AC'], :<=, 51.29)
    assert_operator(htg_loads['L140AC'], :>=, 45.12)
    assert_operator(htg_loads['L150AC'], :<=, 54.17)
    assert_operator(htg_loads['L150AC'], :>=, 39.76)
    assert_operator(htg_loads['L155AC'], :<=, 56.88)
    assert_operator(htg_loads['L155AC'], :>=, 42.66)
    assert_operator(htg_loads['L160AC'], :<=, 62.04)
    assert_operator(htg_loads['L160AC'], :>=, 48.90)
    assert_operator(htg_loads['L170AC'], :<=, 74.24)
    assert_operator(htg_loads['L170AC'], :>=, 58.11)
    assert_operator(htg_loads['L200AC'], :<=, 136.02)
    assert_operator(htg_loads['L200AC'], :>=, 122.47)
    assert_operator(htg_loads['L202AC'], :<=, 145.02)
    assert_operator(htg_loads['L202AC'], :>=, 127.59)
    assert_operator(htg_loads['L302XC'], :<=, 66.77)
    assert_operator(htg_loads['L302XC'], :>=, 19.20)
    assert_operator(htg_loads['L304XC'], :<=, 54.90)
    assert_operator(htg_loads['L304XC'], :>=, 23.51)
    assert_operator(htg_loads['L322XC'], :<=, 92.60)
    assert_operator(htg_loads['L322XC'], :>=, 18.71)
    assert_operator(htg_loads['L324XC'], :<=, 56.48)
    assert_operator(htg_loads['L324XC'], :>=, 32.71)

    # Annual Heating Load Deltas
    assert_operator(htg_loads['L110AC'] - htg_loads['L100AC'], :<=, 29.68)
    assert_operator(htg_loads['L110AC'] - htg_loads['L100AC'], :>=, 17.43)
    assert_operator(htg_loads['L120AC'] - htg_loads['L100AC'], :<=, -9.47)
    assert_operator(htg_loads['L120AC'] - htg_loads['L100AC'], :>=, -15.98)
    assert_operator(htg_loads['L130AC'] - htg_loads['L100AC'], :<=, -5.88)
    assert_operator(htg_loads['L130AC'] - htg_loads['L100AC'], :>=, -12.98)
    assert_operator(htg_loads['L140AC'] - htg_loads['L100AC'], :<=, 0.37)
    assert_operator(htg_loads['L140AC'] - htg_loads['L100AC'], :>=, -12.41)
    assert_operator(htg_loads['L150AC'] - htg_loads['L100AC'], :<=, -3.30)
    assert_operator(htg_loads['L150AC'] - htg_loads['L100AC'], :>=, -10.87)
    assert_operator(htg_loads['L155AC'] - htg_loads['L150AC'], :<=, 6.40)
    assert_operator(htg_loads['L155AC'] - htg_loads['L150AC'], :>=, -0.61)
    assert_operator(htg_loads['L160AC'] - htg_loads['L100AC'], :<=, 4.55)
    assert_operator(htg_loads['L160AC'] - htg_loads['L100AC'], :>=, -1.89)
    assert_operator(htg_loads['L170AC'] - htg_loads['L100AC'], :<=, 16.25)
    assert_operator(htg_loads['L170AC'] - htg_loads['L100AC'], :>=, 8.18)
    assert_operator(htg_loads['L200AC'] - htg_loads['L100AC'], :<=, 78.90)
    assert_operator(htg_loads['L200AC'] - htg_loads['L100AC'], :>=, 71.18)
    assert_operator(htg_loads['L202AC'] - htg_loads['L200AC'], :<=, 11.25)
    assert_operator(htg_loads['L202AC'] - htg_loads['L200AC'], :>=, 3.22)
    assert_operator(htg_loads['L302XC'] - htg_loads['L100AC'], :<=, 8.79)
    assert_operator(htg_loads['L302XC'] - htg_loads['L100AC'], :>=, -31.43)
    assert_operator(htg_loads['L302XC'] - htg_loads['L304XC'], :<=, 12.03)
    assert_operator(htg_loads['L302XC'] - htg_loads['L304XC'], :>=, -4.46)
    assert_operator(htg_loads['L322XC'] - htg_loads['L100AC'], :<=, 36.23)
    assert_operator(htg_loads['L322XC'] - htg_loads['L100AC'], :>=, -33.54)
    assert_operator(htg_loads['L322XC'] - htg_loads['L324XC'], :<=, 36.30)
    assert_operator(htg_loads['L322XC'] - htg_loads['L324XC'], :>=, -14.17)

    # Annual Cooling Loads
    assert_operator(clg_loads['L100AL'], :<=, 60.45)
    assert_operator(clg_loads['L100AL'], :>=, 41.47)
    assert_operator(clg_loads['L110AL'], :<=, 62.96)
    assert_operator(clg_loads['L110AL'], :>=, 46.80)
    assert_operator(clg_loads['L120AL'], :<=, 53.32)
    assert_operator(clg_loads['L120AL'], :>=, 40.08)
    assert_operator(clg_loads['L130AL'], :<=, 43.34)
    assert_operator(clg_loads['L130AL'], :>=, 30.98)
    assert_operator(clg_loads['L140AL'], :<=, 30.42)
    assert_operator(clg_loads['L140AL'], :>=, 21.01)
    assert_operator(clg_loads['L150AL'], :<=, 75.46)
    assert_operator(clg_loads['L150AL'], :>=, 49.46)
    assert_operator(clg_loads['L155AL'], :<=, 61.64)
    assert_operator(clg_loads['L155AL'], :>=, 35.58)
    assert_operator(clg_loads['L160AL'], :<=, 70.40)
    assert_operator(clg_loads['L160AL'], :>=, 51.26)
    assert_operator(clg_loads['L170AL'], :<=, 47.73)
    assert_operator(clg_loads['L170AL'], :>=, 34.05)
    assert_operator(clg_loads['L200AL'], :<=, 75.01)
    assert_operator(clg_loads['L200AL'], :>=, 56.18)
    assert_operator(clg_loads['L202AL'], :<=, 61.74)
    assert_operator(clg_loads['L202AL'], :>=, 49.50)

    # Annual Cooling Load Deltas
    assert_operator(clg_loads['L110AL'] - clg_loads['L100AL'], :<=, 6.93)
    assert_operator(clg_loads['L110AL'] - clg_loads['L100AL'], :>=, 0.57)
    assert_operator(clg_loads['L120AL'] - clg_loads['L100AL'], :<=, -0.20)
    assert_operator(clg_loads['L120AL'] - clg_loads['L100AL'], :>=, -8.27)
    assert_operator(clg_loads['L130AL'] - clg_loads['L100AL'], :<=, -9.69)
    assert_operator(clg_loads['L130AL'] - clg_loads['L100AL'], :>=, -18.59)
    assert_operator(clg_loads['L140AL'] - clg_loads['L100AL'], :<=, -20.29)
    assert_operator(clg_loads['L140AL'] - clg_loads['L100AL'], :>=, -30.77)
    assert_operator(clg_loads['L150AL'] - clg_loads['L100AL'], :<=, 15.92)
    assert_operator(clg_loads['L150AL'] - clg_loads['L100AL'], :>=, 7.50)
    assert_operator(clg_loads['L155AL'] - clg_loads['L150AL'], :<=, -11.14)
    assert_operator(clg_loads['L155AL'] - clg_loads['L150AL'], :>=, -16.54)
    assert_operator(clg_loads['L160AL'] - clg_loads['L100AL'], :<=, 12.78)
    assert_operator(clg_loads['L160AL'] - clg_loads['L100AL'], :>=, 6.80)
    assert_operator(clg_loads['L170AL'] - clg_loads['L100AL'], :<=, -6.56)
    assert_operator(clg_loads['L170AL'] - clg_loads['L100AL'], :>=, -14.09)
    assert_operator(clg_loads['L200AL'] - clg_loads['L100AL'], :<=, 17.61)
    assert_operator(clg_loads['L200AL'] - clg_loads['L100AL'], :>=, 11.59)
    assert_operator(clg_loads['L200AL'] - clg_loads['L202AL'], :<=, 14.39)
    assert_operator(clg_loads['L200AL'] - clg_loads['L202AL'], :>=, 5.10)
  end

  def _get_reference_home_components(hpxml, test_num)
    results = {}
    hpxml = HPXML.new(hpxml_path: hpxml)

    # Above-grade walls
    wall_u, wall_solar_abs, wall_emiss, wall_area = _get_above_grade_walls(hpxml)
    results['Above-grade walls (Uo)'] = wall_u.round(3)
    results['Above-grade wall solar absorptance (α)'] = wall_solar_abs.round(2)
    results['Above-grade wall infrared emittance (ε)'] = wall_emiss.round(2)

    # Basement walls
    bsmt_wall_r = _get_basement_walls(hpxml)
    if test_num == 4
      results['Basement walls insulation R-Value'] = bsmt_wall_r.round(0)
    else
      results['Basement walls insulation R-Value'] = 'n/a'
    end
    results['Basement walls (Uo)'] = 'n/a'

    # Above-grade floors
    floors_u = _get_above_grade_floors(hpxml)
    if test_num <= 2
      results['Above-grade floors (Uo)'] = floors_u.round(3)
    else
      results['Above-grade floors (Uo)'] = 'n/a'
    end

    # Slab insulation
    slab_r, carpet_r, exp_mas_floor_area = _get_hpxml_slabs(hpxml)
    if test_num >= 3
      results['Slab insulation R-Value'] = slab_r.round(0)
    else
      results['Slab insulation R-Value'] = 'n/a'
    end

    # Ceilings
    ceil_u, ceil_area = _get_ceilings(hpxml)
    results['Ceilings (Uo)'] = ceil_u.round(3)

    # Roofs
    roof_solar_abs, roof_emiss, roof_area = _get_roofs(hpxml)
    results['Roof solar absorptance (α)'] = roof_solar_abs.round(2)
    results['Roof infrared emittance (ε)'] = roof_emiss.round(2)

    # Attic vent area
    attic_vent_area = _get_attic_vent_area(hpxml)
    results['Attic vent area (ft2)'] = attic_vent_area.round(2)

    # Crawlspace vent area
    crawl_vent_area = _get_crawl_vent_area(hpxml)
    if test_num == 2
      results['Crawlspace vent area (ft2)'] = crawl_vent_area.round(2)
    else
      results['Crawlspace vent area (ft2)'] = 'n/a'
    end

    # Slabs
    if test_num >= 3
      results['Exposed masonry floor area (ft2)'] = exp_mas_floor_area.round(1)
      results['Carpet & pad R-Value'] = carpet_r.round(1)
    else
      results['Exposed masonry floor area (ft2)'] = 'n/a'
      results['Carpet & pad R-Value'] = 'n/a'
    end

    # Doors
    door_u, door_area = _get_doors(hpxml)
    results['Door Area (ft2)'] = door_area.round(0)
    results['Door U-Factor'] = door_u.round(2)

    # Windows
    win_areas, win_u, win_shgc_htg, win_shgc_clg = _get_windows(hpxml)
    results['North window area (ft2)'] = win_areas[0].round(2)
    results['South window area (ft2)'] = win_areas[180].round(2)
    results['East window area (ft2)'] = win_areas[90].round(2)
    results['West window area (ft2)'] = win_areas[270].round(2)
    results['Window U-Factor'] = win_u.round(2)
    results['Window SHGCo (heating)'] = win_shgc_htg.round(2)
    results['Window SHGCo (cooling)'] = win_shgc_clg.round(2)

    # Infiltration
    sla, ach50 = _get_infiltration(hpxml)
    results['SLAo (ft2/ft2)'] = sla.round(5)

    # Internal gains
    xml_it_sens, xml_it_lat = _get_internal_gains(hpxml)
    results['Sensible Internal gains (Btu/day)'] = xml_it_sens.round(0)
    results['Latent Internal gains (Btu/day)'] = xml_it_lat.round(0)

    # HVAC
    afue, hspf, seer, dse = _get_hvac(hpxml)
    if (test_num == 1) || (test_num == 4)
      results['Labeled heating system rating and efficiency'] = afue.round(2)
    else
      results['Labeled heating system rating and efficiency'] = hspf.round(1)
    end
    results['Labeled cooling system rating and efficiency'] = seer.round(1)
    results['Air Distribution System Efficiency'] = dse.round(2)

    # Thermostat
    tstat, htg_sp, htg_setback, clg_sp, clg_setup = _get_tstat(hpxml)
    results['Thermostat Type'] = tstat
    results['Heating thermostat settings'] = htg_sp.round(0)
    results['Cooling thermostat settings'] = clg_sp.round(0)

    # Mechanical ventilation
    mv_kwh, mv_cfm = _get_mech_vent(hpxml)
    results['Mechanical ventilation (kWh/y)'] = mv_kwh.round(2)

    # Domestic hot water
    ref_pipe_l, ref_loop_l = _get_dhw(hpxml)
    results['DHW pipe length refPipeL'] = ref_pipe_l.round(1)
    results['DHW loop length refLoopL'] = ref_loop_l.round(1)

    return results
  end

  def _get_iad_home_components(hpxml, test_num)
    results = {}
    hpxml = HPXML.new(hpxml_path: hpxml)

    # Geometry
    results['Number of Stories'] = hpxml.building_construction.number_of_conditioned_floors
    results['Number of Bedrooms'] = hpxml.building_construction.number_of_bedrooms
    results['Conditioned Floor Area (ft2)'] = hpxml.building_construction.conditioned_floor_area
    results['Infiltration Volume (ft3)'] = hpxml.air_infiltration_measurements[0].infiltration_volume

    # Above-grade Walls
    wall_u, wall_solar_abs, wall_emiss, wall_area = _get_above_grade_walls(hpxml)
    results['Above-grade walls area (ft2)'] = wall_area
    results['Above-grade walls (Uo)'] = wall_u

    # Roof
    roof_solar_abs, roof_emiss, roof_area = _get_roofs(hpxml)
    results['Roof gross area (ft2)'] = roof_area

    # Ceilings
    ceil_u, ceil_area = _get_ceilings(hpxml)
    results['Ceiling gross projected footprint area (ft2)'] = ceil_area
    results['Ceilings (Uo)'] = ceil_u

    # Crawlspace
    crawl_vent_area = _get_crawl_vent_area(hpxml)
    results['Crawlspace vent area (ft2)'] = crawl_vent_area

    # Doors
    door_u, door_area = _get_doors(hpxml)
    results['Door Area (ft2)'] = door_area
    results['Door R-value'] = 1.0 / door_u

    # Windows
    win_areas, win_u, win_shgc_htg, win_shgc_clg = _get_windows(hpxml)
    results['North window area (ft2)'] = win_areas[0]
    results['South window area (ft2)'] = win_areas[180]
    results['East window area (ft2)'] = win_areas[90]
    results['West window area (ft2)'] = win_areas[270]
    results['Window U-Factor'] = win_u
    results['Window SHGCo (heating)'] = win_shgc_htg
    results['Window SHGCo (cooling)'] = win_shgc_clg

    # Infiltration
    sla, ach50 = _get_infiltration(hpxml)
    results['Infiltration rate (ACH50)'] = ach50

    # Mechanical Ventilation
    mv_kwh, mv_cfm = _get_mech_vent(hpxml)
    results['Mechanical ventilation rate'] = mv_cfm
    results['Mechanical ventilation'] = mv_kwh

    # HVAC
    afue, hspf, seer, dse = _get_hvac(hpxml)
    if (test_num == 1) || (test_num == 4)
      results['Labeled heating system rating and efficiency'] = afue
    else
      results['Labeled heating system rating and efficiency'] = hspf
    end
    results['Labeled cooling system rating and efficiency'] = seer

    # Thermostat
    tstat, htg_sp, htg_setback, clg_sp, clg_setup = _get_tstat(hpxml)
    results['Thermostat Type'] = tstat
    results['Heating thermostat settings'] = htg_sp
    results['Cooling thermostat settings'] = clg_sp

    return results
  end

  def _check_reference_home_components(results, test_num, version)
    # Table 4.2.3.1(1): Acceptance Criteria for Test Cases 1 - 4

    epsilon = 0.001 # 0.1%

    # Above-grade walls
    if test_num <= 3
      assert_equal(0.082, results['Above-grade walls (Uo)'])
    else
      assert_equal(0.060, results['Above-grade walls (Uo)'])
    end
    assert_equal(0.75, results['Above-grade wall solar absorptance (α)'])
    assert_equal(0.90, results['Above-grade wall infrared emittance (ε)'])

    # Basement walls
    if test_num == 4
      assert_equal(10, results['Basement walls insulation R-Value'])
    else
      assert_equal('n/a', results['Basement walls insulation R-Value'])
    end

    # Above-grade floors
    if test_num <= 2
      assert_equal(0.047, results['Above-grade floors (Uo)'])
    else
      assert_equal('n/a', results['Above-grade floors (Uo)'])
    end

    # Slab insulation
    if test_num >= 3
      assert_equal(0, results['Slab insulation R-Value'])
    else
      assert_equal('n/a', results['Slab insulation R-Value'])
    end

    # Ceilings
    if (test_num == 1) || (test_num == 4)
      assert_equal(0.030, results['Ceilings (Uo)'])
    else
      assert_equal(0.035, results['Ceilings (Uo)'])
    end

    # Roofs
    assert_equal(0.75, results['Roof solar absorptance (α)'])
    assert_equal(0.90, results['Roof infrared emittance (ε)'])

    # Attic vent area
    assert_in_epsilon(5.13, results['Attic vent area (ft2)'], epsilon)

    # Crawlspace vent area
    if test_num == 2
      assert_in_epsilon(10.26, results['Crawlspace vent area (ft2)'], epsilon)
    else
      assert_equal('n/a', results['Crawlspace vent area (ft2)'])
    end

    # Slabs
    if test_num >= 3
      assert_in_epsilon(307.8, results['Exposed masonry floor area (ft2)'], epsilon)
      assert_equal(2.0, results['Carpet & pad R-Value'])
    else
      assert_equal('n/a', results['Exposed masonry floor area (ft2)'])
      assert_equal('n/a', results['Carpet & pad R-Value'])
    end

    # Doors
    assert_equal(40, results['Door Area (ft2)'])
    if test_num == 1
      assert_equal(0.40, results['Door U-Factor'])
    elsif test_num == 2
      assert_equal(0.65, results['Door U-Factor'])
    elsif test_num == 3
      assert_equal(1.20, results['Door U-Factor'])
    else
      assert_equal(0.35, results['Door U-Factor'])
    end

    # Windows
    if test_num <= 3
      assert_in_epsilon(69.26, results['North window area (ft2)'], epsilon)
      assert_in_epsilon(69.26, results['South window area (ft2)'], epsilon)
      assert_in_epsilon(69.26, results['East window area (ft2)'], epsilon)
      assert_in_epsilon(69.26, results['West window area (ft2)'], epsilon)
    else
      assert_in_epsilon(102.63, results['North window area (ft2)'], epsilon)
      assert_in_epsilon(102.63, results['South window area (ft2)'], epsilon)
      assert_in_epsilon(102.63, results['East window area (ft2)'], epsilon)
      assert_in_epsilon(102.63, results['West window area (ft2)'], epsilon)
    end
    if test_num == 1
      assert_equal(0.40, results['Window U-Factor'])
    elsif test_num == 2
      assert_equal(0.65, results['Window U-Factor'])
    elsif test_num == 3
      assert_equal(1.20, results['Window U-Factor'])
    else
      assert_equal(0.35, results['Window U-Factor'])
    end
    assert_equal(0.34, results['Window SHGCo (heating)'])
    assert_equal(0.28, results['Window SHGCo (cooling)'])

    # Infiltration
    assert_equal(0.00036, results['SLAo (ft2/ft2)'])

    # Internal gains
    if version == '2019A'
      # Pub 002-2020 (June 2020)
      if test_num == 1
        assert_in_epsilon(55115, results['Sensible Internal gains (Btu/day)'], epsilon)
        assert_in_epsilon(13666, results['Latent Internal gains (Btu/day)'], epsilon)
      elsif test_num == 2
        assert_in_epsilon(52470, results['Sensible Internal gains (Btu/day)'], epsilon)
        assert_in_epsilon(12568, results['Latent Internal gains (Btu/day)'], epsilon)
      elsif test_num == 3
        assert_in_epsilon(47839, results['Sensible Internal gains (Btu/day)'], epsilon)
        assert_in_epsilon(9152, results['Latent Internal gains (Btu/day)'], epsilon)
      else
        assert_in_epsilon(82691, results['Sensible Internal gains (Btu/day)'], epsilon)
        assert_in_epsilon(17769, results['Latent Internal gains (Btu/day)'], epsilon)
      end
    else
      if test_num == 1
        assert_in_epsilon(55470, results['Sensible Internal gains (Btu/day)'], epsilon)
        assert_in_epsilon(13807, results['Latent Internal gains (Btu/day)'], epsilon)
      elsif test_num == 2
        assert_in_epsilon(52794, results['Sensible Internal gains (Btu/day)'], epsilon)
        assert_in_epsilon(12698, results['Latent Internal gains (Btu/day)'], epsilon)
      elsif test_num == 3
        assert_in_epsilon(48111, results['Sensible Internal gains (Btu/day)'], epsilon)
        assert_in_epsilon(9259, results['Latent Internal gains (Btu/day)'], epsilon)
      else
        assert_in_epsilon(83103, results['Sensible Internal gains (Btu/day)'], epsilon)
        assert_in_epsilon(17934, results['Latent Internal gains (Btu/day)'], epsilon)
      end
    end

    # HVAC
    if (test_num == 1) || (test_num == 4)
      assert_equal(0.78, results['Labeled heating system rating and efficiency'])
    else
      assert_equal(7.7, results['Labeled heating system rating and efficiency'])
    end
    assert_equal(13.0, results['Labeled cooling system rating and efficiency'])
    assert_equal(0.80, results['Air Distribution System Efficiency'])

    # Thermostat
    assert_equal('manual', results['Thermostat Type'])
    assert_equal(68, results['Heating thermostat settings'])
    assert_equal(78, results['Cooling thermostat settings'])

    # Mechanical ventilation
    mv_kwh_yr = nil
    if version == '2014'
      if test_num == 1
        mv_kwh_yr = 0.0
      elsif test_num == 2
        mv_kwh_yr = 77.9
      elsif test_num == 3
        mv_kwh_yr = 140.4
      else
        mv_kwh_yr = 379.1
      end
    else
      # Pub 002-2020 (June 2020)
      if test_num == 1
        mv_kwh_yr = 0.0
      elsif test_num == 2
        mv_kwh_yr = 222.1
      elsif test_num == 3
        mv_kwh_yr = 287.8
      else
        mv_kwh_yr = 762.8
      end
    end
    assert_in_epsilon(mv_kwh_yr, results['Mechanical ventilation (kWh/y)'], epsilon)

    # Domestic hot water
    dhw_epsilon = 0.1 # 0.1 ft
    if test_num <= 3
      assert_in_delta(88.5, results['DHW pipe length refPipeL'], dhw_epsilon)
      assert_in_delta(156.9, results['DHW loop length refLoopL'], dhw_epsilon)
    else
      assert_in_delta(98.5, results['DHW pipe length refPipeL'], dhw_epsilon)
      assert_in_delta(176.9, results['DHW loop length refLoopL'], dhw_epsilon)
    end

    # e-Ratio
    assert_in_delta(1, results['e-Ratio'], 0.005)
  end

  def _check_iad_home_components(results, test_num)
    epsilon = 0.0005 # 0.05%

    # Geometry
    assert_equal(2, results['Number of Stories'])
    assert_equal(3, results['Number of Bedrooms'])
    assert_equal(2400, results['Conditioned Floor Area (ft2)'])
    assert_equal(20400, results['Infiltration Volume (ft3)'])

    # Above-grade Walls
    assert_in_delta(2355.52, results['Above-grade walls area (ft2)'], 0.01)
    assert_in_delta(0.085, results['Above-grade walls (Uo)'], 0.001)

    # Roof
    assert_equal(1300, results['Roof gross area (ft2)'])

    # Ceilings
    assert_equal(1200, results['Ceiling gross projected footprint area (ft2)'])
    assert_in_delta(0.054, results['Ceilings (Uo)'], 0.01)

    # Crawlspace
    assert_in_epsilon(8, results['Crawlspace vent area (ft2)'], 0.01)

    # Doors
    assert_equal(40, results['Door Area (ft2)'])
    assert_in_delta(3.04, results['Door R-value'], 0.01)

    # Windows
    assert_in_epsilon(108.00, results['North window area (ft2)'], epsilon)
    assert_in_epsilon(108.00, results['South window area (ft2)'], epsilon)
    assert_in_epsilon(108.00, results['East window area (ft2)'], epsilon)
    assert_in_epsilon(108.00, results['West window area (ft2)'], epsilon)
    assert_in_delta(1.039, results['Window U-Factor'], 0.01)
    assert_in_delta(0.57, results['Window SHGCo (heating)'], 0.01)
    assert_in_delta(0.47, results['Window SHGCo (cooling)'], 0.01)

    # Infiltration
    if test_num != 3
      assert_equal(3.0, results['Infiltration rate (ACH50)'])
    else
      assert_equal(5.0, results['Infiltration rate (ACH50)'])
    end

    # Mechanical Ventilation
    if test_num == 1
      assert_in_delta(66.4, results['Mechanical ventilation rate'], 0.2)
      assert_in_delta(407, results['Mechanical ventilation'], 1.0)
    elsif test_num == 2
      assert_in_delta(64.2, results['Mechanical ventilation rate'], 0.2)
      assert_in_delta(394, results['Mechanical ventilation'], 1.0)
    elsif test_num == 3
      assert_in_delta(53.3, results['Mechanical ventilation rate'], 0.2)
      assert_in_delta(327, results['Mechanical ventilation'], 1.0)
    elsif test_num == 4
      assert_in_delta(57.1, results['Mechanical ventilation rate'], 0.2)
      assert_in_delta(350, results['Mechanical ventilation'], 1.0)
    end

    # HVAC
    if (test_num == 1) || (test_num == 4)
      assert_equal(0.78, results['Labeled heating system rating and efficiency'])
    else
      assert_equal(7.7, results['Labeled heating system rating and efficiency'])
    end
    assert_equal(13.0, results['Labeled cooling system rating and efficiency'])

    # Thermostat
    assert_equal('manual', results['Thermostat Type'])
    assert_equal(68, results['Heating thermostat settings'])
    assert_equal(78, results['Cooling thermostat settings'])
  end

  def _get_above_grade_walls(hpxml)
    u_factor = solar_abs = emittance = area = num = 0.0
    hpxml.walls.each do |wall|
      next unless wall.is_exterior_thermal_boundary

      u_factor += 1.0 / wall.insulation_assembly_r_value
      solar_abs += wall.solar_absorptance
      emittance += wall.emittance
      area += wall.area
      num += 1
    end
    return u_factor / num, solar_abs / num, emittance / num, area
  end

  def _get_basement_walls(hpxml)
    r_value = num = 0.0
    hpxml.foundation_walls.each do |foundation_wall|
      next unless foundation_wall.is_exterior_thermal_boundary

      r_value += foundation_wall.insulation_exterior_r_value
      r_value += foundation_wall.insulation_interior_r_value
      num += 1
    end
    return r_value / num
  end

  def _get_above_grade_floors(hpxml)
    u_factor = num = 0.0
    hpxml.frame_floors.each do |frame_floor|
      next unless frame_floor.is_floor

      u_factor += 1.0 / frame_floor.insulation_assembly_r_value
      num += 1
    end
    return u_factor / num
  end

  def _get_hpxml_slabs(hpxml)
    r_value = carpet_r_value = exp_area = carpet_num = r_num = 0.0
    hpxml.slabs.each do |slab|
      exp_area += (slab.area * (1.0 - slab.carpet_fraction))
      carpet_r_value += Float(slab.carpet_r_value)
      carpet_num += 1
      r_value += slab.perimeter_insulation_r_value
      r_num += 1
      r_value += slab.under_slab_insulation_r_value
      r_num += 1
    end
    return r_value / r_num, carpet_r_value / carpet_num, exp_area
  end

  def _get_ceilings(hpxml)
    u_factor = area = num = 0.0
    hpxml.frame_floors.each do |frame_floor|
      next unless frame_floor.is_ceiling

      u_factor += 1.0 / frame_floor.insulation_assembly_r_value
      area += frame_floor.area
      num += 1
    end
    return u_factor / num, area
  end

  def _get_roofs(hpxml)
    solar_abs = emittance = area = num = 0.0
    hpxml.roofs.each do |roof|
      solar_abs += roof.solar_absorptance
      emittance += roof.emittance
      area += roof.area
      num += 1
    end
    return solar_abs / num, emittance / num, area
  end

  def _get_attic_vent_area(hpxml)
    area = sla = 0.0
    hpxml.attics.each do |attic|
      next unless attic.attic_type == HPXML::AtticTypeVented

      sla = attic.vented_attic_sla
    end
    hpxml.frame_floors.each do |frame_floor|
      next unless frame_floor.is_ceiling && (frame_floor.exterior_adjacent_to == HPXML::LocationAtticVented)

      area += frame_floor.area
    end
    return sla * area
  end

  def _get_crawl_vent_area(hpxml)
    area = sla = 0.0
    hpxml.foundations.each do |foundation|
      next unless foundation.foundation_type == HPXML::FoundationTypeCrawlspaceVented

      sla = foundation.vented_crawlspace_sla
    end
    hpxml.frame_floors.each do |frame_floor|
      next unless frame_floor.is_floor && (frame_floor.exterior_adjacent_to == HPXML::LocationCrawlspaceVented)

      area += frame_floor.area
    end
    return sla * area
  end

  def _get_doors(hpxml)
    area = u_factor = num = 0.0
    hpxml.doors.each do |door|
      area += door.area
      u_factor += 1.0 / door.r_value
      num += 1
    end
    return u_factor / num, area
  end

  def _get_windows(hpxml)
    areas = { 0 => 0.0, 90 => 0.0, 180 => 0.0, 270 => 0.0 }
    u_factor = shgc_htg = shgc_clg = num = 0.0
    hpxml.windows.each do |window|
      areas[window.azimuth] += window.area
      u_factor += window.ufactor
      shgc = window.shgc
      shading_winter = window.interior_shading_factor_winter
      shading_summer = window.interior_shading_factor_summer
      shgc_htg += (shgc * shading_winter)
      shgc_clg += (shgc * shading_summer)
      num += 1
    end
    return areas, u_factor / num, shgc_htg / num, shgc_clg / num
  end

  def _get_infiltration(hpxml)
    air_infil = hpxml.air_infiltration_measurements[0]
    ach50 = air_infil.air_leakage
    cfa = hpxml.building_construction.conditioned_floor_area
    infil_volume = air_infil.infiltration_volume
    sla = Airflow.get_infiltration_SLA_from_ACH50(ach50, 0.65, cfa, infil_volume)
    return sla, ach50
  end

  def _get_internal_gains(hpxml)
    s = ''
    nbeds = hpxml.building_construction.number_of_bedrooms
    cfa = hpxml.building_construction.conditioned_floor_area
    eri_version = hpxml.header.eri_calculation_version
    gfa = hpxml.slabs.select { |s| s.interior_adjacent_to == HPXML::LocationGarage }.map { |s| s.area }.inject(0, :+)

    xml_pl_sens = 0.0
    xml_pl_lat = 0.0

    # Plug loads
    hpxml.plug_loads.each do |plug_load|
      btu = UnitConversions.convert(plug_load.kWh_per_year, 'kWh', 'Btu')
      xml_pl_sens += (plug_load.frac_sensible * btu)
      xml_pl_lat += (plug_load.frac_latent * btu)
      s += "#{xml_pl_sens} #{xml_pl_lat}\n"
    end

    xml_appl_sens = 0.0
    xml_appl_lat = 0.0

    # Appliances: CookingRange
    cooking_range = hpxml.cooking_ranges[0]
    cooking_range.usage_multiplier = 1.0 if cooking_range.usage_multiplier.nil?
    oven = hpxml.ovens[0]
    cr_annual_kwh, cr_annual_therm, cr_frac_sens, cr_frac_lat = HotWaterAndAppliances.calc_range_oven_energy(nbeds, cooking_range, oven)
    btu = UnitConversions.convert(cr_annual_kwh, 'kWh', 'Btu') + UnitConversions.convert(cr_annual_therm, 'therm', 'Btu')
    xml_appl_sens += (cr_frac_sens * btu)
    xml_appl_lat += (cr_frac_lat * btu)

    # Appliances: Refrigerator
    refrigerator = hpxml.refrigerators[0]
    refrigerator.usage_multiplier = 1.0 if refrigerator.usage_multiplier.nil?
    rf_annual_kwh, rf_frac_sens, rf_frac_lat = HotWaterAndAppliances.calc_refrigerator_or_freezer_energy(refrigerator)
    btu = UnitConversions.convert(rf_annual_kwh, 'kWh', 'Btu')
    xml_appl_sens += (rf_frac_sens * btu)
    xml_appl_lat += (rf_frac_lat * btu)

    # Appliances: Dishwasher
    dishwasher = hpxml.dishwashers[0]
    dishwasher.usage_multiplier = 1.0 if dishwasher.usage_multiplier.nil?
    dw_annual_kwh, dw_frac_sens, dw_frac_lat, dw_gpd = HotWaterAndAppliances.calc_dishwasher_energy_gpd(eri_version, nbeds, dishwasher)
    btu = UnitConversions.convert(dw_annual_kwh, 'kWh', 'Btu')
    xml_appl_sens += (dw_frac_sens * btu)
    xml_appl_lat += (dw_frac_lat * btu)

    # Appliances: ClothesWasher
    clothes_washer = hpxml.clothes_washers[0]
    clothes_washer.usage_multiplier = 1.0 if clothes_washer.usage_multiplier.nil?
    cw_annual_kwh, cw_frac_sens, cw_frac_lat, cw_gpd = HotWaterAndAppliances.calc_clothes_washer_energy_gpd(eri_version, nbeds, clothes_washer)
    btu = UnitConversions.convert(cw_annual_kwh, 'kWh', 'Btu')
    xml_appl_sens += (cw_frac_sens * btu)
    xml_appl_lat += (cw_frac_lat * btu)

    # Appliances: ClothesDryer
    clothes_dryer = hpxml.clothes_dryers[0]
    clothes_dryer.usage_multiplier = 1.0 if clothes_dryer.usage_multiplier.nil?
    cd_annual_kwh, cd_annual_therm, cd_frac_sens, cd_frac_lat = HotWaterAndAppliances.calc_clothes_dryer_energy(eri_version, nbeds, clothes_dryer, clothes_washer)
    btu = UnitConversions.convert(cd_annual_kwh, 'kWh', 'Btu') + UnitConversions.convert(cd_annual_therm, 'therm', 'Btu')
    xml_appl_sens += (cd_frac_sens * btu)
    xml_appl_lat += (cd_frac_lat * btu)

    s += "#{xml_appl_sens} #{xml_appl_lat}\n"

    # Water Use
    xml_water_sens, xml_water_lat = HotWaterAndAppliances.get_water_gains_sens_lat(nbeds)
    s += "#{xml_water_sens} #{xml_water_lat}\n"

    # Occupants
    xml_occ_sens = 0.0
    xml_occ_lat = 0.0
    heat_gain, hrs_per_day, frac_sens, frac_lat = Geometry.get_occupancy_default_values()
    btu = hpxml.building_occupancy.number_of_residents * heat_gain * hrs_per_day * 365.0
    xml_occ_sens += (frac_sens * btu)
    xml_occ_lat += (frac_lat * btu)
    s += "#{xml_occ_sens} #{xml_occ_lat}\n"

    # Lighting
    xml_ltg_sens = 0.0
    f_int_cfl, f_ext_cfl, f_grg_cfl, f_int_lfl, f_ext_lfl, f_grg_lfl, f_int_led, f_ext_led, f_grg_led = nil
    hpxml.lighting_groups.each do |lg|
      if (lg.lighting_type == HPXML::LightingTypeCFL) && (lg.location == HPXML::LocationInterior)
        f_int_cfl = lg.fraction_of_units_in_location
      elsif (lg.lighting_type == HPXML::LightingTypeCFL) && (lg.location == HPXML::LocationExterior)
        f_ext_cfl = lg.fraction_of_units_in_location
      elsif (lg.lighting_type == HPXML::LightingTypeCFL) && (lg.location == HPXML::LocationGarage)
        f_grg_cfl = lg.fraction_of_units_in_location
      elsif (lg.lighting_type == HPXML::LightingTypeLFL) && (lg.location == HPXML::LocationInterior)
        f_int_lfl = lg.fraction_of_units_in_location
      elsif (lg.lighting_type == HPXML::LightingTypeLFL) && (lg.location == HPXML::LocationExterior)
        f_ext_lfl = lg.fraction_of_units_in_location
      elsif (lg.lighting_type == HPXML::LightingTypeLFL) && (lg.location == HPXML::LocationGarage)
        f_grg_lfl = lg.fraction_of_units_in_location
      elsif (lg.lighting_type == HPXML::LightingTypeLED) && (lg.location == HPXML::LocationInterior)
        f_int_led = lg.fraction_of_units_in_location
      elsif (lg.lighting_type == HPXML::LightingTypeLED) && (lg.location == HPXML::LocationExterior)
        f_ext_led = lg.fraction_of_units_in_location
      elsif (lg.lighting_type == HPXML::LightingTypeLED) && (lg.location == HPXML::LocationGarage)
        f_grg_led = lg.fraction_of_units_in_location
      end
    end
    int_kwh, ext_kwh, grg_kwh = Lighting.calc_energy(eri_version, cfa, gfa, f_int_cfl, f_ext_cfl, f_grg_cfl, f_int_lfl, f_ext_lfl, f_grg_lfl, f_int_led, f_ext_led, f_grg_led)
    xml_ltg_sens += UnitConversions.convert(int_kwh + grg_kwh, 'kWh', 'Btu')
    s += "#{xml_ltg_sens}\n"

    xml_btu_sens = (xml_pl_sens + xml_appl_sens + xml_water_sens + xml_occ_sens + xml_ltg_sens) / 365.0
    xml_btu_lat = (xml_pl_lat + xml_appl_lat + xml_water_lat + xml_occ_lat) / 365.0

    return xml_btu_sens, xml_btu_lat
  end

  def _get_hvac(hpxml)
    afue = hspf = seer = dse = num_afue = num_hspf = num_seer = num_dse = 0.0
    hpxml.heating_systems.each do |heating_system|
      afue += heating_system.heating_efficiency_afue
      num_afue += 1
    end
    hpxml.cooling_systems.each do |cooling_system|
      seer += cooling_system.cooling_efficiency_seer
      num_seer += 1
    end
    hpxml.heat_pumps.each do |heat_pump|
      if not heat_pump.heating_efficiency_hspf.nil?
        hspf += heat_pump.heating_efficiency_hspf
        num_hspf += 1
      end
      if not heat_pump.cooling_efficiency_seer.nil?
        seer += heat_pump.cooling_efficiency_seer
        num_seer += 1
      end
    end
    hpxml.hvac_distributions.each do |hvac_distribution|
      dse += hvac_distribution.annual_heating_dse
      num_dse += 1
      dse += hvac_distribution.annual_cooling_dse
      num_dse += 1
    end
    return afue / num_afue, hspf / num_hspf, seer / num_seer, dse / num_dse
  end

  def _get_tstat(hpxml)
    hvac_control = hpxml.hvac_controls[0]
    tstat = hvac_control.control_type.gsub(' thermostat', '')
    htg_sp, htg_setback_sp, htg_setback_hrs_per_week, htg_setback_start_hr = HVAC.get_default_heating_setpoint(hvac_control.control_type)
    clg_sp, clg_setup_sp, clg_setup_hrs_per_week, clg_setup_start_hr = HVAC.get_default_cooling_setpoint(hvac_control.control_type)
    return tstat, htg_sp, htg_setback_sp, clg_sp, clg_setup_sp
  end

  def _get_mech_vent(hpxml)
    mv_kwh = mv_cfm = 0.0
    hpxml.ventilation_fans.each do |vent_fan|
      next unless vent_fan.used_for_whole_building_ventilation

      hours = vent_fan.hours_in_operation
      fan_w = vent_fan.fan_power
      mv_kwh += fan_w * 8.76 * hours / 24.0
      mv_cfm += vent_fan.tested_flow_rate
    end
    return mv_kwh, mv_cfm
  end

  def _get_dhw(hpxml)
    has_uncond_bsmnt = hpxml.has_location(HPXML::LocationBasementUnconditioned)
    cfa = hpxml.building_construction.conditioned_floor_area
    ncfl = hpxml.building_construction.number_of_conditioned_floors
    ref_pipe_l = HotWaterAndAppliances.get_default_std_pipe_length(has_uncond_bsmnt, cfa, ncfl)
    ref_loop_l = HotWaterAndAppliances.get_default_recirc_loop_length(ref_pipe_l)
    return ref_pipe_l, ref_loop_l
  end

  def _get_csv_results(csv)
    results = {}
    CSV.foreach(csv) do |row|
      next if row.nil? || (row.size < 2)

      if row[0] == 'ENERGY STAR Certification' # String outputs
        results[row[0]] = row[1]
      elsif row[1].include? ',' # Sum values for visualization on CI
        results[row[0]] = row[1].split(',').map(&:to_f).sum
      else
        results[row[0]] = Float(row[1])
      end
    end

    return results
  end

  def _check_method_results(results, test_num, has_tankless_water_heater, version, test_loc = nil)
    using_iaf = false

    cooling_fuel =  { 1 => 'elec', 2 => 'elec', 3 => 'elec', 4 => 'elec', 5 => 'elec' }
    cooling_mepr =  { 1 => 10.00,  2 => 10.00,  3 => 10.00,  4 => 10.00,  5 => 10.00 }
    heating_fuel =  { 1 => 'elec', 2 => 'elec', 3 => 'gas',  4 => 'elec', 5 => 'gas' }
    heating_mepr =  { 1 => 6.80,   2 => 6.80,   3 => 0.78,   4 => 9.85,   5 => 0.96  }
    hotwater_fuel = { 1 => 'elec', 2 => 'gas',  3 => 'elec', 4 => 'elec', 5 => 'elec' }
    hotwater_mepr = { 1 => 0.88,   2 => 0.82,   3 => 0.88,   4 => 0.88,   5 => 0.88 }
    if version == '2019A'
      ec_x_la = { 1 => 20.45,  2 => 22.42,  3 => 21.28,  4 => 21.40,  5 => 22.42 }
    else
      ec_x_la = { 1 => 21.27,  2 => 23.33,  3 => 22.05,  4 => 22.35,  5 => 23.33 }
    end
    cfa = { 1 => 1539, 2 => 1539, 3 => 1539, 4 => 1539, 5 => 1539 }
    nbr = { 1 => 3,    2 => 3,    3 => 2,    4 => 4,    5 => 3 }
    nst = { 1 => 1,    2 => 1,    3 => 1,    4 => 1,    5 => 1 }
    using_iaf = true if version != '2014'

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

  def _check_hvac_test_results(energy)
    # Proposed acceptance criteria as of 10/1/2020

    # Cooling cases
    assert_operator((energy['HVAC1b'] - energy['HVAC1a']) / energy['HVAC1a'] * 100, :>, -23.58)
    assert_operator((energy['HVAC1b'] - energy['HVAC1a']) / energy['HVAC1a'] * 100, :<, -18.45)

    # Gas heating cases
    assert_operator((energy['HVAC2b'] - energy['HVAC2a']) / energy['HVAC2a'] * 100, :>, -13.19)
    assert_operator((energy['HVAC2b'] - energy['HVAC2a']) / energy['HVAC2a'] * 100, :<, -12.57)

    # Electric heating cases
    assert_operator((energy['HVAC2d'] - energy['HVAC2c']) / energy['HVAC2c'] * 100, :>, -44.31)
    assert_operator((energy['HVAC2d'] - energy['HVAC2c']) / energy['HVAC2c'] * 100, :<, -14.36)
    assert_operator((energy['HVAC2e'] - energy['HVAC2c']) / energy['HVAC2c'] * 100, :>, 52.15)
    assert_operator((energy['HVAC2e'] - energy['HVAC2c']) / energy['HVAC2c'] * 100, :<, 113.11)
  end

  def _check_dse_test_results(energy)
    # Proposed acceptance criteria as of 10/1/2020

    # Heating cases
    assert_operator((energy['HVAC3b'] - energy['HVAC3a']) / energy['HVAC3a'] * 100, :>, 2.80)
    assert_operator((energy['HVAC3b'] - energy['HVAC3a']) / energy['HVAC3a'] * 100, :<, 31.10)
    assert_operator((energy['HVAC3c'] - energy['HVAC3a']) / energy['HVAC3a'] * 100, :>, 1.90)
    assert_operator((energy['HVAC3c'] - energy['HVAC3a']) / energy['HVAC3a'] * 100, :<, 6.71)
    assert_operator((energy['HVAC3d'] - energy['HVAC3a']) / energy['HVAC3a'] * 100, :>, 4.41)
    assert_operator((energy['HVAC3d'] - energy['HVAC3a']) / energy['HVAC3a'] * 100, :<, 19.91)

    # Cooling cases
    assert_operator((energy['HVAC3f'] - energy['HVAC3e']) / energy['HVAC3e'] * 100, :>, 17.34)
    assert_operator((energy['HVAC3f'] - energy['HVAC3e']) / energy['HVAC3e'] * 100, :<, 32.15)
    assert_operator((energy['HVAC3g'] - energy['HVAC3e']) / energy['HVAC3e'] * 100, :>, 5.32)
    assert_operator((energy['HVAC3g'] - energy['HVAC3e']) / energy['HVAC3e'] * 100, :<, 8.56)
    assert_operator((energy['HVAC3h'] - energy['HVAC3e']) / energy['HVAC3e'] * 100, :>, 15.84)
    assert_operator((energy['HVAC3h'] - energy['HVAC3e']) / energy['HVAC3e'] * 100, :<, 28.49)
  end

  def _get_hot_water(results_csv)
    rated_dhw = nil
    rated_recirc = nil
    rated_gpd = 0
    CSV.foreach(results_csv) do |row|
      next if row.nil? || row[0].nil?

      if ['End Use: Electricity: Hot Water (MBtu)', 'End Use: Natural Gas: Hot Water (MBtu)'].include? row[0]
        rated_dhw = Float(row[1])
      elsif row[0] == 'End Use: Electricity: Hot Water Recirc Pump (MBtu)'
        rated_recirc = Float(row[1])
      elsif row[0].start_with?('Hot Water:') && row[0].include?('(gal)')
        rated_gpd += (Float(row[1]) / 365.0)
      end
    end
    return rated_dhw, rated_recirc, rated_gpd
  end

  def _check_hot_water(energy)
    # Pub 002-2020 (June 2020)

    # Duluth MN cases
    assert_operator(energy['L100AD-HW-01'], :>, 19.34)
    assert_operator(energy['L100AD-HW-01'], :<, 19.88)
    assert_operator(energy['L100AD-HW-02'], :>, 25.76)
    assert_operator(energy['L100AD-HW-02'], :<, 26.55)
    assert_operator(energy['L100AD-HW-03'], :>, 17.20)
    assert_operator(energy['L100AD-HW-03'], :<, 17.70)
    assert_operator(energy['L100AD-HW-04'], :>, 24.94)
    assert_operator(energy['L100AD-HW-04'], :<, 25.71)
    assert_operator(energy['L100AD-HW-05'], :>, 55.93)
    assert_operator(energy['L100AD-HW-05'], :<, 57.58)
    assert_operator(energy['L100AD-HW-06'], :>, 22.61)
    assert_operator(energy['L100AD-HW-06'], :<, 23.28)
    assert_operator(energy['L100AD-HW-07'], :>, 20.51)
    assert_operator(energy['L100AD-HW-07'], :<, 21.09)

    # Miami FL cases
    assert_operator(energy['L100AM-HW-01'], :>, 10.74)
    assert_operator(energy['L100AM-HW-01'], :<, 11.24)
    assert_operator(energy['L100AM-HW-02'], :>, 13.37)
    assert_operator(energy['L100AM-HW-02'], :<, 13.87)
    assert_operator(energy['L100AM-HW-03'], :>, 8.83)
    assert_operator(energy['L100AM-HW-03'], :<, 9.33)
    assert_operator(energy['L100AM-HW-04'], :>, 13.06)
    assert_operator(energy['L100AM-HW-04'], :<, 13.56)
    assert_operator(energy['L100AM-HW-05'], :>, 30.84)
    assert_operator(energy['L100AM-HW-05'], :<, 31.55)
    assert_operator(energy['L100AM-HW-06'], :>, 12.09)
    assert_operator(energy['L100AM-HW-06'], :<, 12.59)
    assert_operator(energy['L100AM-HW-07'], :>, 11.84)
    assert_operator(energy['L100AM-HW-07'], :<, 12.34)

    # MN Delta cases
    assert_operator(energy['L100AD-HW-01'] - energy['L100AD-HW-02'], :>, -6.77)
    assert_operator(energy['L100AD-HW-01'] - energy['L100AD-HW-02'], :<, -6.27)
    assert_operator(energy['L100AD-HW-01'] - energy['L100AD-HW-03'], :>, 1.92)
    assert_operator(energy['L100AD-HW-01'] - energy['L100AD-HW-03'], :<, 2.42)
    assert_operator(energy['L100AD-HW-02'] - energy['L100AD-HW-04'], :>, 0.58)
    assert_operator(energy['L100AD-HW-02'] - energy['L100AD-HW-04'], :<, 1.08)
    assert_operator(energy['L100AD-HW-02'] - energy['L100AD-HW-05'], :>, -31.03)
    assert_operator(energy['L100AD-HW-02'] - energy['L100AD-HW-05'], :<, -30.17)
    assert_operator(energy['L100AD-HW-02'] - energy['L100AD-HW-06'], :>, 2.95)
    assert_operator(energy['L100AD-HW-02'] - energy['L100AD-HW-06'], :<, 3.45)
    assert_operator(energy['L100AD-HW-02'] - energy['L100AD-HW-07'], :>, 5.09)
    assert_operator(energy['L100AD-HW-02'] - energy['L100AD-HW-07'], :<, 5.59)

    # FL Delta cases
    assert_operator(energy['L100AM-HW-01'] - energy['L100AM-HW-02'], :>, -2.88)
    assert_operator(energy['L100AM-HW-01'] - energy['L100AM-HW-02'], :<, -2.38)
    assert_operator(energy['L100AM-HW-01'] - energy['L100AM-HW-03'], :>, 1.67)
    assert_operator(energy['L100AM-HW-01'] - energy['L100AM-HW-03'], :<, 2.17)
    assert_operator(energy['L100AM-HW-02'] - energy['L100AM-HW-04'], :>, 0.07)
    assert_operator(energy['L100AM-HW-02'] - energy['L100AM-HW-04'], :<, 0.57)
    assert_operator(energy['L100AM-HW-02'] - energy['L100AM-HW-05'], :>, -17.82)
    assert_operator(energy['L100AM-HW-02'] - energy['L100AM-HW-05'], :<, -17.32)
    assert_operator(energy['L100AM-HW-02'] - energy['L100AM-HW-06'], :>, 1.04)
    assert_operator(energy['L100AM-HW-02'] - energy['L100AM-HW-06'], :<, 1.54)
    assert_operator(energy['L100AM-HW-02'] - energy['L100AM-HW-07'], :>, 1.28)
    assert_operator(energy['L100AM-HW-02'] - energy['L100AM-HW-07'], :<, 1.78)

    # MN-FL Delta cases
    assert_operator(energy['L100AD-HW-01'] - energy['L100AM-HW-01'], :>, 8.37)
    assert_operator(energy['L100AD-HW-01'] - energy['L100AM-HW-01'], :<, 8.87)
    assert_operator(energy['L100AD-HW-02'] - energy['L100AM-HW-02'], :>, 12.26)
    assert_operator(energy['L100AD-HW-02'] - energy['L100AM-HW-02'], :<, 12.77)
    assert_operator(energy['L100AD-HW-03'] - energy['L100AM-HW-03'], :>, 8.13)
    assert_operator(energy['L100AD-HW-03'] - energy['L100AM-HW-03'], :<, 8.63)
    assert_operator(energy['L100AD-HW-04'] - energy['L100AM-HW-04'], :>, 11.75)
    assert_operator(energy['L100AD-HW-04'] - energy['L100AM-HW-04'], :<, 12.25)
    assert_operator(energy['L100AD-HW-05'] - energy['L100AM-HW-05'], :>, 25.05)
    assert_operator(energy['L100AD-HW-05'] - energy['L100AM-HW-05'], :<, 26.04)
    assert_operator(energy['L100AD-HW-06'] - energy['L100AM-HW-06'], :>, 10.35)
    assert_operator(energy['L100AD-HW-06'] - energy['L100AM-HW-06'], :<, 10.85)
    assert_operator(energy['L100AD-HW-07'] - energy['L100AM-HW-07'], :>, 8.46)
    assert_operator(energy['L100AD-HW-07'] - energy['L100AM-HW-07'], :<, 8.96)
  end

  def _check_hot_water_301_2019_pre_addendum_a(energy)
    # Acceptance Criteria for Hot Water Tests

    # Duluth MN cases
    assert_operator(energy['L100AD-HW-01'], :>, 19.11)
    assert_operator(energy['L100AD-HW-01'], :<, 19.73)
    assert_operator(energy['L100AD-HW-02'], :>, 25.54)
    assert_operator(energy['L100AD-HW-02'], :<, 26.36)
    assert_operator(energy['L100AD-HW-03'], :>, 17.03)
    assert_operator(energy['L100AD-HW-03'], :<, 17.50)
    assert_operator(energy['L100AD-HW-04'], :>, 24.75)
    assert_operator(energy['L100AD-HW-04'], :<, 25.52)
    assert_operator(energy['L100AD-HW-05'], :>, 55.43)
    assert_operator(energy['L100AD-HW-05'], :<, 57.15)
    assert_operator(energy['L100AD-HW-06'], :>, 22.39)
    assert_operator(energy['L100AD-HW-06'], :<, 23.09)
    assert_operator(energy['L100AD-HW-07'], :>, 20.29)
    assert_operator(energy['L100AD-HW-07'], :<, 20.94)

    # Miami FL cases
    assert_operator(energy['L100AM-HW-01'], :>, 10.59)
    assert_operator(energy['L100AM-HW-01'], :<, 11.03)
    assert_operator(energy['L100AM-HW-02'], :>, 13.17)
    assert_operator(energy['L100AM-HW-02'], :<, 13.68)
    assert_operator(energy['L100AM-HW-03'], :>, 8.81)
    assert_operator(energy['L100AM-HW-03'], :<, 9.13)
    assert_operator(energy['L100AM-HW-04'], :>, 12.87)
    assert_operator(energy['L100AM-HW-04'], :<, 13.36)
    assert_operator(energy['L100AM-HW-05'], :>, 30.19)
    assert_operator(energy['L100AM-HW-05'], :<, 31.31)
    assert_operator(energy['L100AM-HW-06'], :>, 11.90)
    assert_operator(energy['L100AM-HW-06'], :<, 12.38)
    assert_operator(energy['L100AM-HW-07'], :>, 11.68)
    assert_operator(energy['L100AM-HW-07'], :<, 12.14)

    # MN Delta cases
    assert_operator((energy['L100AD-HW-01'] - energy['L100AD-HW-02']) / energy['L100AD-HW-01'] * 100, :>, -34.01)
    assert_operator((energy['L100AD-HW-01'] - energy['L100AD-HW-02']) / energy['L100AD-HW-01'] * 100, :<, -32.49)
    assert_operator((energy['L100AD-HW-01'] - energy['L100AD-HW-03']) / energy['L100AD-HW-01'] * 100, :>, 10.74)
    assert_operator((energy['L100AD-HW-01'] - energy['L100AD-HW-03']) / energy['L100AD-HW-01'] * 100, :<, 11.57)
    assert_operator((energy['L100AD-HW-02'] - energy['L100AD-HW-04']) / energy['L100AD-HW-02'] * 100, :>, 3.06)
    assert_operator((energy['L100AD-HW-02'] - energy['L100AD-HW-04']) / energy['L100AD-HW-02'] * 100, :<, 3.22)
    assert_operator((energy['L100AD-HW-02'] - energy['L100AD-HW-05']) / energy['L100AD-HW-02'] * 100, :>, -118.52)
    assert_operator((energy['L100AD-HW-02'] - energy['L100AD-HW-05']) / energy['L100AD-HW-02'] * 100, :<, -115.63)
    assert_operator((energy['L100AD-HW-02'] - energy['L100AD-HW-06']) / energy['L100AD-HW-02'] * 100, :>, 12.17)
    assert_operator((energy['L100AD-HW-02'] - energy['L100AD-HW-06']) / energy['L100AD-HW-02'] * 100, :<, 12.51)
    assert_operator((energy['L100AD-HW-02'] - energy['L100AD-HW-07']) / energy['L100AD-HW-02'] * 100, :>, 20.15)
    assert_operator((energy['L100AD-HW-02'] - energy['L100AD-HW-07']) / energy['L100AD-HW-02'] * 100, :<, 20.78)

    # FL Delta cases
    assert_operator((energy['L100AM-HW-01'] - energy['L100AM-HW-02']) / energy['L100AM-HW-01'] * 100, :>, -24.54)
    assert_operator((energy['L100AM-HW-01'] - energy['L100AM-HW-02']) / energy['L100AM-HW-01'] * 100, :<, -23.44)
    assert_operator((energy['L100AM-HW-01'] - energy['L100AM-HW-03']) / energy['L100AM-HW-01'] * 100, :>, 16.65)
    assert_operator((energy['L100AM-HW-01'] - energy['L100AM-HW-03']) / energy['L100AM-HW-01'] * 100, :<, 18.12)
    assert_operator((energy['L100AM-HW-02'] - energy['L100AM-HW-04']) / energy['L100AM-HW-02'] * 100, :>, 2.20)
    assert_operator((energy['L100AM-HW-02'] - energy['L100AM-HW-04']) / energy['L100AM-HW-02'] * 100, :<, 2.38)
    assert_operator((energy['L100AM-HW-02'] - energy['L100AM-HW-05']) / energy['L100AM-HW-02'] * 100, :>, -130.88)
    assert_operator((energy['L100AM-HW-02'] - energy['L100AM-HW-05']) / energy['L100AM-HW-02'] * 100, :<, -127.52)
    assert_operator((energy['L100AM-HW-02'] - energy['L100AM-HW-06']) / energy['L100AM-HW-02'] * 100, :>, 9.38)
    assert_operator((energy['L100AM-HW-02'] - energy['L100AM-HW-06']) / energy['L100AM-HW-02'] * 100, :<, 9.74)
    assert_operator((energy['L100AM-HW-02'] - energy['L100AM-HW-07']) / energy['L100AM-HW-02'] * 100, :>, 11.00)
    assert_operator((energy['L100AM-HW-02'] - energy['L100AM-HW-07']) / energy['L100AM-HW-02'] * 100, :<, 11.40)

    # MN-FL Delta cases
    assert_operator((energy['L100AD-HW-01'] - energy['L100AM-HW-01']) / energy['L100AD-HW-01'] * 100, :>, 43.35)
    assert_operator((energy['L100AD-HW-01'] - energy['L100AM-HW-01']) / energy['L100AD-HW-01'] * 100, :<, 45.00)
    assert_operator((energy['L100AD-HW-02'] - energy['L100AM-HW-02']) / energy['L100AD-HW-02'] * 100, :>, 47.26)
    assert_operator((energy['L100AD-HW-02'] - energy['L100AM-HW-02']) / energy['L100AD-HW-02'] * 100, :<, 48.93)
    assert_operator((energy['L100AD-HW-03'] - energy['L100AM-HW-03']) / energy['L100AD-HW-03'] * 100, :>, 47.38)
    assert_operator((energy['L100AD-HW-03'] - energy['L100AM-HW-03']) / energy['L100AD-HW-03'] * 100, :<, 48.74)
    assert_operator((energy['L100AD-HW-04'] - energy['L100AM-HW-04']) / energy['L100AD-HW-04'] * 100, :>, 46.81)
    assert_operator((energy['L100AD-HW-04'] - energy['L100AM-HW-04']) / energy['L100AD-HW-04'] * 100, :<, 48.48)
    assert_operator((energy['L100AD-HW-05'] - energy['L100AM-HW-05']) / energy['L100AD-HW-05'] * 100, :>, 44.41)
    assert_operator((energy['L100AD-HW-05'] - energy['L100AM-HW-05']) / energy['L100AD-HW-05'] * 100, :<, 45.99)
    assert_operator((energy['L100AD-HW-06'] - energy['L100AM-HW-06']) / energy['L100AD-HW-06'] * 100, :>, 45.60)
    assert_operator((energy['L100AD-HW-06'] - energy['L100AM-HW-06']) / energy['L100AD-HW-06'] * 100, :<, 47.33)
    assert_operator((energy['L100AD-HW-07'] - energy['L100AM-HW-07']) / energy['L100AD-HW-07'] * 100, :>, 41.32)
    assert_operator((energy['L100AD-HW-07'] - energy['L100AM-HW-07']) / energy['L100AD-HW-07'] * 100, :<, 42.86)
  end

  def _check_hot_water_301_2014_pre_addendum_a(energy)
    # Acceptance Criteria for Hot Water Tests

    # Duluth MN cases
    assert_operator(energy['L100AD-HW-01'], :>, 18.2)
    assert_operator(energy['L100AD-HW-01'], :<, 22.0)

    # Miami FL cases
    assert_operator(energy['L100AM-HW-01'], :>, 10.9)
    assert_operator(energy['L100AM-HW-01'], :<, 14.4)

    # MN Delta cases
    assert_operator((energy['L100AD-HW-02'] - energy['L100AD-HW-01']) / energy['L100AD-HW-01'] * 100, :>, 26.5)
    assert_operator((energy['L100AD-HW-02'] - energy['L100AD-HW-01']) / energy['L100AD-HW-01'] * 100, :<, 32.2)
    assert_operator((energy['L100AD-HW-03'] - energy['L100AD-HW-01']) / energy['L100AD-HW-01'] * 100, :>, -11.8)
    assert_operator((energy['L100AD-HW-03'] - energy['L100AD-HW-01']) / energy['L100AD-HW-01'] * 100, :<, -6.8)

    # FL Delta cases
    assert_operator((energy['L100AM-HW-02'] - energy['L100AM-HW-01']) / energy['L100AM-HW-01'] * 100, :>, 19.1)
    assert_operator((energy['L100AM-HW-02'] - energy['L100AM-HW-01']) / energy['L100AM-HW-01'] * 100, :<, 29.1)
    assert_operator((energy['L100AM-HW-03'] - energy['L100AM-HW-01']) / energy['L100AM-HW-01'] * 100, :>, -19.5)
    assert_operator((energy['L100AM-HW-03'] - energy['L100AM-HW-01']) / energy['L100AM-HW-01'] * 100, :<, -7.7)

    # MN-FL Delta cases
    assert_operator(energy['L100AD-HW-01'] - energy['L100AM-HW-01'], :>, 5.5)
    assert_operator(energy['L100AD-HW-01'] - energy['L100AM-HW-01'], :<, 9.4)
    assert_operator((energy['L100AD-HW-01'] - energy['L100AM-HW-01']) / energy['L100AD-HW-01'] * 100, :>, 28.9)
    assert_operator((energy['L100AD-HW-01'] - energy['L100AM-HW-01']) / energy['L100AD-HW-01'] * 100, :<, 45.1)
  end

  def _rm_path(path)
    if Dir.exist?(path)
      FileUtils.rm_r(path)
    end
    while true
      break if not Dir.exist?(path)

      sleep(0.01)
    end
  end
end
