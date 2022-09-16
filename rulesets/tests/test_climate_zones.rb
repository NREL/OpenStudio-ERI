# frozen_string_literal: true

require_relative '../../hpxml-measures/HPXMLtoOpenStudio/resources/minitest_helper'
require_relative '../main.rb'
require 'fileutils'
require_relative 'util.rb'

class ClimateZonesTest < MiniTest::Test
  def setup
    @root_path = File.absolute_path(File.join(File.dirname(__FILE__), '..', '..'))
    @tmp_hpxml_path = File.join(@root_path, 'workflow', 'sample_files', 'tmp.xml')
  end

  def teardown
    File.delete(@tmp_hpxml_path) if File.exist? @tmp_hpxml_path
  end

  def test_eri
    _all_calc_types.each do |calc_type|
      hpxml = _test_ruleset('base.xml', calc_type)
      _check_climate_zone(hpxml, year: 2006, zone: '5B')
    end
  end

  def test_iecc_eri
    IECCConstants.AllVersions.each do |iecc_version|
      _all_calc_types.each do |calc_type|
        hpxml_name = _change_iecc_version('base.xml', iecc_version)
        hpxml = _test_ruleset(hpxml_name, calc_type, iecc_version)
        _check_climate_zone(hpxml, year: Integer(iecc_version), zone: '5B')
      end
    end
  end

  def _test_ruleset(hpxml_name, calc_type, iecc_version = nil)
    require_relative '../../workflow/design'
    designs = [Design.new(calc_type: calc_type, iecc_version: iecc_version)]

    hpxml_input_path = File.join(@root_path, 'workflow', 'sample_files', hpxml_name)
    success, errors, _, _, hpxml = run_rulesets(hpxml_input_path, designs)

    errors.each do |s|
      puts "Error: #{s}"
    end

    # assert that it ran correctly
    assert_equal(true, success)

    return hpxml
  end

  def _check_climate_zone(hpxml, year:, zone:)
    assert_equal(1, hpxml.climate_and_risk_zones.climate_zone_ieccs.size)
    cz = hpxml.climate_and_risk_zones.climate_zone_ieccs[0]
    assert_equal(year, cz.year)
    assert_equal(zone, cz.zone)
  end
end
