# frozen_string_literal: true

require 'openstudio'
require_relative '../../hpxml-measures/HPXMLtoOpenStudio/resources/minitest_helper'
require 'fileutils'
require 'csv'
require_relative 'util.rb'
require_relative '../util.rb'

class ESDENHTest < Minitest::Test
  def setup
    @root_path = File.absolute_path(File.join(File.dirname(__FILE__), '..', '..'))
    @sample_files_path = File.join(@root_path, 'workflow', 'sample_files')
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
      esrd_results = _get_csv_results([csvs[:esref_eri_results]])
      esrat_results = _get_csv_results([csvs[:esrat_eri_results]])

      all_results[xml] = {}
      all_results[xml]['Reference Home ERI'] = esrd_results['ES ERI']
      all_results[xml]['Rated Home ERI'] = esrat_results['ES ERI']
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
    def get_results_hash(hpxml_bldg)
      return { rated_facility_type: hpxml_bldg.building_construction.residential_facility_type,
               rated_cfa: hpxml_bldg.building_construction.conditioned_floor_area,
               rated_nbr: hpxml_bldg.building_construction.number_of_bedrooms }
    end

    saf_affected_versions = [ES::SFNationalVer3_0, ES::SFPacificVer3_0, DENH::Ver1]

    # Single-family detached
    hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base-foundation-slab.xml'))
    hpxml_bldg = hpxml.buildings[0]
    hpxml_bldg.building_construction.conditioned_floor_area *= 2.0
    [*ES::AllVersions, *DENH::AllVersions].each do |es_version|
      results = get_results_hash(hpxml_bldg)
      if saf_affected_versions.include? es_version
        assert_in_epsilon(0.95, get_saf(results, es_version, hpxml_bldg), 0.001)
      else
        assert_equal(1.0, get_saf(results, es_version, hpxml_bldg))
      end
    end

    # Single-family detached, 2 bedrooms
    hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base-foundation-slab.xml'))
    hpxml_bldg = hpxml.buildings[0]
    hpxml_bldg.building_construction.conditioned_floor_area *= 2.0
    hpxml_bldg.building_construction.number_of_bedrooms = 2
    [*ES::AllVersions, *DENH::AllVersions].each do |es_version|
      results = get_results_hash(hpxml_bldg)
      if saf_affected_versions.include? es_version
        assert_in_epsilon(0.877, get_saf(results, es_version, hpxml_bldg), 0.001)
      else
        assert_equal(1.0, get_saf(results, es_version, hpxml_bldg))
      end
    end

    # Single-family detached, 5 bedrooms
    hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base-foundation-slab.xml'))
    hpxml_bldg = hpxml.buildings[0]
    hpxml_bldg.building_construction.conditioned_floor_area *= 2.0
    hpxml_bldg.building_construction.number_of_bedrooms = 5
    [*ES::AllVersions, *DENH::AllVersions].each do |es_version|
      results = get_results_hash(hpxml_bldg)
      assert_equal(1.0, get_saf(results, es_version, hpxml_bldg))
    end

    # Single-family detached, conditioned basement below grade
    hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base.xml'))
    hpxml_bldg = hpxml.buildings[0]
    [*ES::AllVersions, *DENH::AllVersions].each do |es_version|
      results = get_results_hash(hpxml_bldg)
      assert_equal(1.0, get_saf(results, es_version, hpxml_bldg))
    end

    # Single-family detached, conditioned basement above grade
    hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base.xml'))
    hpxml_bldg = hpxml.buildings[0]
    hpxml_bldg.foundation_walls.each do |fwall|
      fwall.depth_below_grade = fwall.depth_below_grade / 2.0 - 0.5
    end
    [*ES::AllVersions, *DENH::AllVersions].each do |es_version|
      results = get_results_hash(hpxml_bldg)
      if saf_affected_versions.include? es_version
        assert_in_epsilon(0.95, get_saf(results, es_version, hpxml_bldg), 0.001)
      else
        assert_equal(1.0, get_saf(results, es_version, hpxml_bldg))
      end
    end

    # Single-family attached
    hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base-bldgtype-sfa-unit.xml'))
    hpxml_bldg = hpxml.buildings[0]
    [*ES::AllVersions, *DENH::AllVersions].each do |es_version|
      results = get_results_hash(hpxml_bldg)
      assert_equal(1.0, get_saf(results, es_version, hpxml_bldg))
    end

    # Apartment unit
    hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base-bldgtype-mf-unit.xml'))
    hpxml_bldg = hpxml.buildings[0]
    [*ES::AllVersions, *DENH::AllVersions].each do |es_version|
      results = get_results_hash(hpxml_bldg)
      assert_equal(1.0, get_saf(results, es_version, hpxml_bldg))
    end
  end

  def test_opp_limit
    opp_limit_affected_versions = [ES::SFNationalVer3_0, ES::SFPacificVer3_0, DENH::Ver1]

    # On-site Power Production limit
    [*ES::AllVersions, *DENH::AllVersions].each do |es_version|
      if opp_limit_affected_versions.include? es_version
        assert_equal(5.0, calc_opp_eri_limit(94.5, 0.95, es_version))
      else
        assert_equal(0.0, calc_opp_eri_limit(94.5, 0.95, es_version))
      end
    end
  end
end
