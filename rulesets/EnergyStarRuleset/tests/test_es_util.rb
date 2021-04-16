# frozen_string_literal: true

require_relative '../../../hpxml-measures/HPXMLtoOpenStudio/resources/minitest_helper'
require 'openstudio'
require 'openstudio/ruleset/ShowRunnerOutput'
require_relative '../measure.rb'
require 'fileutils'
require_relative '../resources/util'

class EnergyStarUtilTest < MiniTest::Test
  def setup
    @root_path = File.absolute_path(File.join(File.dirname(__FILE__), '..', '..', '..'))
  end

  def get_results_hash(hpxml)
    return { rated_facility_type: hpxml.building_construction.residential_facility_type,
             rated_cfa: hpxml.building_construction.conditioned_floor_area,
             rated_nbr: hpxml.building_construction.number_of_bedrooms }
  end

  def test_saf_single_family_detached
    hpxml = HPXML.new(hpxml_path: File.join(@root_path, 'workflow', 'sample_files', 'base-foundation-slab.xml'))
    hpxml.building_construction.conditioned_floor_area *= 2.0
    ESConstants.AllVersions.each do |es_version|
      results = get_results_hash(hpxml)
      if [ESConstants.SFNationalVer3, ESConstants.SFPacificVer3].include? es_version
        _check_saf(calc_energystar_saf(results, es_version, hpxml), 0.95)
      else
        _check_saf(calc_energystar_saf(results, es_version, hpxml), 1.0)
      end
    end
  end

  def test_saf_single_family_detached_nbeds_2
    hpxml = HPXML.new(hpxml_path: File.join(@root_path, 'workflow', 'sample_files', 'base-foundation-slab.xml'))
    hpxml.building_construction.conditioned_floor_area *= 2.0
    hpxml.building_construction.number_of_bedrooms = 2
    ESConstants.AllVersions.each do |es_version|
      results = get_results_hash(hpxml)
      if [ESConstants.SFNationalVer3, ESConstants.SFPacificVer3].include? es_version
        _check_saf(calc_energystar_saf(results, es_version, hpxml), 0.877)
      else
        _check_saf(calc_energystar_saf(results, es_version, hpxml), 1.0)
      end
    end
  end

  def test_saf_single_family_detached_nbeds_5
    hpxml = HPXML.new(hpxml_path: File.join(@root_path, 'workflow', 'sample_files', 'base-foundation-slab.xml'))
    hpxml.building_construction.conditioned_floor_area *= 2.0
    hpxml.building_construction.number_of_bedrooms = 5
    ESConstants.AllVersions.each do |es_version|
      results = get_results_hash(hpxml)
      if [ESConstants.SFNationalVer3, ESConstants.SFPacificVer3].include? es_version
        _check_saf(calc_energystar_saf(results, es_version, hpxml), 1.0)
      else
        _check_saf(calc_energystar_saf(results, es_version, hpxml), 1.0)
      end
    end
  end

  def test_saf_single_family_detached_cond_bsmt_below_grade
    hpxml = HPXML.new(hpxml_path: File.join(@root_path, 'workflow', 'sample_files', 'base.xml'))
    ESConstants.AllVersions.each do |es_version|
      results = get_results_hash(hpxml)
      if [ESConstants.SFNationalVer3, ESConstants.SFPacificVer3].include? es_version
        _check_saf(calc_energystar_saf(results, es_version, hpxml), 1.0)
      else
        _check_saf(calc_energystar_saf(results, es_version, hpxml), 1.0)
      end
    end
  end

  def test_saf_single_family_detached_cond_bsmt_above_grade
    hpxml = HPXML.new(hpxml_path: File.join(@root_path, 'workflow', 'sample_files', 'base.xml'))
    hpxml.foundation_walls.each do |fwall|
      fwall.depth_below_grade = fwall.depth_below_grade / 2.0 - 0.5
    end
    ESConstants.AllVersions.each do |es_version|
      results = get_results_hash(hpxml)
      if [ESConstants.SFNationalVer3, ESConstants.SFPacificVer3].include? es_version
        _check_saf(calc_energystar_saf(results, es_version, hpxml), 0.95)
      else
        _check_saf(calc_energystar_saf(results, es_version, hpxml), 1.0)
      end
    end
  end

  def test_saf_single_family_attached
    hpxml = HPXML.new(hpxml_path: File.join(@root_path, 'workflow', 'sample_files', 'base-bldgtype-single-family-attached.xml'))
    ESConstants.AllVersions.each do |es_version|
      results = get_results_hash(hpxml)
      if [ESConstants.SFNationalVer3, ESConstants.SFPacificVer3].include? es_version
        _check_saf(calc_energystar_saf(results, es_version, hpxml), 1.0)
      else
        _check_saf(calc_energystar_saf(results, es_version, hpxml), 1.0)
      end
    end
  end

  def test_saf_apartment_unit
    hpxml = HPXML.new(hpxml_path: File.join(@root_path, 'workflow', 'sample_files', 'base-bldgtype-multifamily.xml'))
    ESConstants.AllVersions.each do |es_version|
      results = get_results_hash(hpxml)
      if [ESConstants.SFNationalVer3, ESConstants.SFPacificVer3].include? es_version
        _check_saf(calc_energystar_saf(results, es_version, hpxml), 1.0)
      else
        _check_saf(calc_energystar_saf(results, es_version, hpxml), 1.0)
      end
    end
  end

  def test_opp_limit
    ESConstants.AllVersions.each do |es_version|
      if [ESConstants.SFNationalVer3, ESConstants.SFPacificVer3].include? es_version
        _check_opp_limit(calc_opp_eri_limit(94.5, 0.95, es_version), 5.0)
      else
        _check_opp_limit(calc_opp_eri_limit(94.5, 0.95, es_version), 0.0)
      end
    end
  end

  def _check_saf(value, expected_value)
    assert_in_epsilon(expected_value, value, 0.001)
  end

  def _check_opp_limit(value, expected_value)
    assert_in_epsilon(expected_value, value, 0.001)
  end
end
