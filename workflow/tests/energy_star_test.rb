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
require_relative '../../hpxml-measures/HPXMLtoOpenStudio/resources/hotwater_appliances'
require_relative '../../hpxml-measures/HPXMLtoOpenStudio/resources/hpxml'
require_relative '../../hpxml-measures/HPXMLtoOpenStudio/resources/hvac_sizing'
require_relative '../../hpxml-measures/HPXMLtoOpenStudio/resources/meta_measure'
require_relative '../../hpxml-measures/HPXMLtoOpenStudio/resources/misc_loads'
require_relative '../../hpxml-measures/HPXMLtoOpenStudio/resources/unit_conversions'
require_relative '../../hpxml-measures/HPXMLtoOpenStudio/resources/xmlhelper'

class EnergyStarTest < Minitest::Test
  def setup
    @test_results_dir = File.join(File.dirname(__FILE__), 'test_results')
    FileUtils.mkdir_p @test_results_dir
    @test_files_dir = File.join(File.dirname(__FILE__), 'test_files')
    FileUtils.mkdir_p @test_files_dir
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
        next if hpxml.header.state_code.nil? # Skip

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

  def test_real_homes_energystar
    test_name = 'real_homes_energystar'
    test_results_csv = File.absolute_path(File.join(@test_results_dir, "#{test_name}.csv"))
    File.delete(test_results_csv) if File.exist? test_results_csv

    # Run simulations
    all_results = {}
    xmldir = "#{File.dirname(__FILE__)}/../real_homes"
    Dir["#{xmldir}/*.xml"].sort.each do |xml|
      rundir, hpxmls, csvs = _run_workflow(xml, test_name, run_energystar: true)
      all_results[File.basename(xml)] = _get_csv_results(csvs[:eri_results], csvs[:co2e_results])

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
  end

  def test_sample_files_invalid
    xmldir = "#{File.dirname(__FILE__)}/../sample_files/invalid_files"
    test_name = 'invalid_files'

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

  def test_timeseries_output
    { 'hourly' => 8760,
      'daily' => 365,
      'monthly' => 12 }.each do |timeseries_frequency, n_lines|
      test_name = "#{timeseries_frequency}_output"

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

  def test_skip_simulation
    test_name = 'skip_simulation'

    # Run ENERGY STAR workflow
    xml = "#{File.dirname(__FILE__)}/../sample_files/base.xml"
    rundir, hpxmls, csvs = _run_workflow(xml, test_name, run_energystar: true, skip_simulation: true)
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
end
