# frozen_string_literal: true

require_relative '../../hpxml-measures/HPXMLtoOpenStudio/resources/minitest_helper'
require 'openstudio'
require 'openstudio/measure/ShowRunnerOutput'
require 'fileutils'
require 'csv'
require_relative 'util.rb'
require_relative '../util.rb'

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

  def test_saf
    def get_results_hash(hpxml)
      return { rated_facility_type: hpxml.building_construction.residential_facility_type,
               rated_cfa: hpxml.building_construction.conditioned_floor_area,
               rated_nbr: hpxml.building_construction.number_of_bedrooms }
    end

    def _check_saf(value, expected_value)
      assert_in_epsilon(expected_value, value, 0.001)
    end

    def _check_opp_limit(value, expected_value)
      assert_in_epsilon(expected_value, value, 0.001)
    end

    root_path = File.absolute_path(File.join(File.dirname(__FILE__), '..', '..'))

    # Single-family detached
    hpxml = HPXML.new(hpxml_path: File.join(root_path, 'workflow', 'sample_files', 'base-foundation-slab.xml'))
    hpxml.building_construction.conditioned_floor_area *= 2.0
    ESConstants.AllVersions.each do |es_version|
      results = get_results_hash(hpxml)
      if [ESConstants.SFNationalVer3_0, ESConstants.SFPacificVer3_0].include? es_version
        _check_saf(get_saf(results, es_version, hpxml), 0.95)
      else
        _check_saf(get_saf(results, es_version, hpxml), 1.0)
      end
    end

    # Single-family detached, 2 bedrooms
    hpxml = HPXML.new(hpxml_path: File.join(root_path, 'workflow', 'sample_files', 'base-foundation-slab.xml'))
    hpxml.building_construction.conditioned_floor_area *= 2.0
    hpxml.building_construction.number_of_bedrooms = 2
    ESConstants.AllVersions.each do |es_version|
      results = get_results_hash(hpxml)
      if [ESConstants.SFNationalVer3_0, ESConstants.SFPacificVer3_0].include? es_version
        _check_saf(get_saf(results, es_version, hpxml), 0.877)
      else
        _check_saf(get_saf(results, es_version, hpxml), 1.0)
      end
    end

    # Single-family detached, 5 bedrooms
    hpxml = HPXML.new(hpxml_path: File.join(root_path, 'workflow', 'sample_files', 'base-foundation-slab.xml'))
    hpxml.building_construction.conditioned_floor_area *= 2.0
    hpxml.building_construction.number_of_bedrooms = 5
    ESConstants.AllVersions.each do |es_version|
      results = get_results_hash(hpxml)
      if [ESConstants.SFNationalVer3_0, ESConstants.SFPacificVer3_0].include? es_version
        _check_saf(get_saf(results, es_version, hpxml), 1.0)
      else
        _check_saf(get_saf(results, es_version, hpxml), 1.0)
      end
    end

    # Single-family detached, conditioned basement below grade
    hpxml = HPXML.new(hpxml_path: File.join(root_path, 'workflow', 'sample_files', 'base.xml'))
    ESConstants.AllVersions.each do |es_version|
      results = get_results_hash(hpxml)
      if [ESConstants.SFNationalVer3_0, ESConstants.SFPacificVer3_0].include? es_version
        _check_saf(get_saf(results, es_version, hpxml), 1.0)
      else
        _check_saf(get_saf(results, es_version, hpxml), 1.0)
      end
    end

    # Single-family detached, conditioned basement above grade
    hpxml = HPXML.new(hpxml_path: File.join(root_path, 'workflow', 'sample_files', 'base.xml'))
    hpxml.foundation_walls.each do |fwall|
      fwall.depth_below_grade = fwall.depth_below_grade / 2.0 - 0.5
    end
    ESConstants.AllVersions.each do |es_version|
      results = get_results_hash(hpxml)
      if [ESConstants.SFNationalVer3_0, ESConstants.SFPacificVer3_0].include? es_version
        _check_saf(get_saf(results, es_version, hpxml), 0.95)
      else
        _check_saf(get_saf(results, es_version, hpxml), 1.0)
      end
    end

    # Single-family attached
    hpxml = HPXML.new(hpxml_path: File.join(root_path, 'workflow', 'sample_files', 'base-bldgtype-single-family-attached.xml'))
    ESConstants.AllVersions.each do |es_version|
      results = get_results_hash(hpxml)
      if [ESConstants.SFNationalVer3_0, ESConstants.SFPacificVer3_0].include? es_version
        _check_saf(get_saf(results, es_version, hpxml), 1.0)
      else
        _check_saf(get_saf(results, es_version, hpxml), 1.0)
      end
    end

    # Apartment unit
    hpxml = HPXML.new(hpxml_path: File.join(root_path, 'workflow', 'sample_files', 'base-bldgtype-multifamily.xml'))
    ESConstants.AllVersions.each do |es_version|
      results = get_results_hash(hpxml)
      if [ESConstants.SFNationalVer3_0, ESConstants.SFPacificVer3_0].include? es_version
        _check_saf(get_saf(results, es_version, hpxml), 1.0)
      else
        _check_saf(get_saf(results, es_version, hpxml), 1.0)
      end
    end

    # OPP Limit
    ESConstants.AllVersions.each do |es_version|
      if [ESConstants.SFNationalVer3_0, ESConstants.SFPacificVer3_0].include? es_version
        _check_opp_limit(calc_opp_eri_limit(94.5, 0.95, es_version), 5.0)
      else
        _check_opp_limit(calc_opp_eri_limit(94.5, 0.95, es_version), 0.0)
      end
    end
  end
end
