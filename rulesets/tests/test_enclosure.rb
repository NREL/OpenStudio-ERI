# frozen_string_literal: true

require_relative '../../hpxml-measures/HPXMLtoOpenStudio/resources/minitest_helper'
require 'openstudio'
require_relative '../main.rb'
require 'fileutils'
require_relative 'util.rb'
require_relative '../../workflow/design'

class ERIEnclosureTest < Minitest::Test
  def setup
    @root_path = File.absolute_path(File.join(File.dirname(__FILE__), '..', '..'))
    @sample_files_path = File.join(@root_path, 'workflow', 'sample_files')
    @tmp_hpxml_path = File.join(@sample_files_path, 'tmp.xml')
    @schema_validator = XMLValidator.get_xml_validator(File.join(@root_path, 'hpxml-measures', 'HPXMLtoOpenStudio', 'resources', 'hpxml_schema', 'HPXML.xsd'))
    @epvalidator = XMLValidator.get_xml_validator(File.join(@root_path, 'hpxml-measures', 'HPXMLtoOpenStudio', 'resources', 'hpxml_schematron', 'EPvalidator.sch'))
    @erivalidator = XMLValidator.get_xml_validator(File.join(@root_path, 'rulesets', 'resources', '301validator.sch'))
    @results_paths = []
  end

  def teardown
    File.delete(@tmp_hpxml_path) if File.exist? @tmp_hpxml_path
    @results_paths.each do |results_path|
      FileUtils.rm_rf(results_path) if Dir.exist? results_path
    end
    @results_paths.clear
    puts
  end

  def test_ground_conductivity
    # Test ground conductivity
    hpxml_name = 'base.xml'

    _test_ruleset(hpxml_name).each do |(_run_type, _calc_type), hpxml_bldg|
      assert_equal(1.0, hpxml_bldg.site.ground_conductivity)
    end
  end

  def test_enclosure_infiltration
    # Test w/o mech vent
    hpxml_name = 'base.xml'

    _test_ruleset(hpxml_name).each do |(_run_type, calc_type), hpxml_bldg|
      if [CalcType::RatedHome].include? calc_type
        _check_infiltration(hpxml_bldg, ach50: 9.1, height: 9.75, volume: 21600.0) # 0.3 nACH
      elsif [CalcType::ReferenceHome].include? calc_type
        _check_infiltration(hpxml_bldg, ach50: 7.09, height: 9.75, volume: 21600.0)
      elsif [CalcType::IndexAdjHome].include? calc_type
        _check_infiltration(hpxml_bldg, ach50: 3.0, height: 17.0, volume: 20400.0)
      elsif [CalcType::IndexAdjReferenceHome].include? calc_type
        _check_infiltration(hpxml_bldg, ach50: 6.67, height: 17.0, volume: 20400.0)
      end
    end

    # Test w/ mech vent
    hpxml_name = 'base-mechvent-exhaust.xml'

    _test_ruleset(hpxml_name).each do |(_run_type, calc_type), hpxml_bldg|
      if [CalcType::RatedHome].include? calc_type
        _check_infiltration(hpxml_bldg, ach50: 3.0, height: 9.75, volume: 21600.0)
      elsif [CalcType::ReferenceHome].include? calc_type
        _check_infiltration(hpxml_bldg, ach50: 7.09, height: 9.75, volume: 21600.0)
      elsif [CalcType::IndexAdjHome].include? calc_type
        _check_infiltration(hpxml_bldg, ach50: 3.0, height: 17.0, volume: 20400.0)
      elsif [CalcType::IndexAdjReferenceHome].include? calc_type
        _check_infiltration(hpxml_bldg, ach50: 6.67, height: 17.0, volume: 20400.0)
      end
    end

    # Test w/ InfiltrationHeight input provided
    hpxml_name = 'base-mechvent-exhaust.xml'
    hpxml = HPXML.new(hpxml_path: File.join(@root_path, 'workflow', 'sample_files', hpxml_name))
    hpxml_bldg = hpxml.buildings[0]
    hpxml_bldg.air_infiltration_measurements.each do |m|
      m.infiltration_height = 10.5
    end
    hpxml_name = File.basename(@tmp_hpxml_path)
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)

    _test_ruleset(hpxml_name).each do |(_run_type, calc_type), hpxml_bldg|
      if [CalcType::RatedHome].include? calc_type
        _check_infiltration(hpxml_bldg, ach50: 3.0, height: 10.5, volume: 21600.0)
      elsif [CalcType::ReferenceHome].include? calc_type
        _check_infiltration(hpxml_bldg, ach50: 7.09, height: 10.5, volume: 21600.0)
      elsif [CalcType::IndexAdjHome].include? calc_type
        _check_infiltration(hpxml_bldg, ach50: 3.0, height: 17.0, volume: 20400.0)
      elsif [CalcType::IndexAdjReferenceHome].include? calc_type
        _check_infiltration(hpxml_bldg, ach50: 6.67, height: 17.0, volume: 20400.0)
      end
    end

    # Test w/ unmeasured mech vent
    # Create derivative file for testing
    hpxml_name = 'base-mechvent-exhaust.xml'
    hpxml = HPXML.new(hpxml_path: File.join(@root_path, 'workflow', 'sample_files', hpxml_name))
    hpxml_bldg = hpxml.buildings[0]
    vent_fan = hpxml_bldg.ventilation_fans.find { |vf| vf.used_for_whole_building_ventilation }
    vent_fan.tested_flow_rate = nil
    vent_fan.flow_rate_not_tested = true
    vent_fan.hours_in_operation = 1
    vent_fan.fan_power = 1.0
    hpxml_name = File.basename(@tmp_hpxml_path)
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)

    _test_ruleset(hpxml_name).each do |(_run_type, calc_type), hpxml_bldg|
      if [CalcType::RatedHome].include? calc_type
        _check_infiltration(hpxml_bldg, ach50: 9.1, height: 9.75, volume: 21600.0) # 0.3 nACH
      elsif [CalcType::ReferenceHome].include? calc_type
        _check_infiltration(hpxml_bldg, ach50: 7.09, height: 9.75, volume: 21600.0)
      elsif [CalcType::IndexAdjHome].include? calc_type
        _check_infiltration(hpxml_bldg, ach50: 3.0, height: 17.0, volume: 20400.0)
      elsif [CalcType::IndexAdjReferenceHome].include? calc_type
        _check_infiltration(hpxml_bldg, ach50: 6.67, height: 17.0, volume: 20400.0)
      end
    end

    # Test attached dwelling where air tightness test results <= 0.30 cfm50 per ft2 of Compartmentalization Boundary
    # Create derivative file for testing
    hpxml_name = 'base-bldgtype-mf-unit.xml'
    hpxml = HPXML.new(hpxml_path: File.join(@root_path, 'workflow', 'sample_files', hpxml_name))
    hpxml_bldg = hpxml.buildings[0]
    hpxml_bldg.ventilation_fans.add(id: 'MechanicalVentilation',
                                    fan_type: HPXML::MechVentTypeSupply,
                                    tested_flow_rate: 110.0,
                                    hours_in_operation: 24.0,
                                    used_for_whole_building_ventilation: true,
                                    fan_power: 30.0,
                                    is_shared_system: false)
    hpxml_name = File.basename(@tmp_hpxml_path)
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)

    _test_ruleset(hpxml_name).each do |(_run_type, calc_type), hpxml_bldg|
      if [CalcType::RatedHome].include? calc_type
        _check_infiltration(hpxml_bldg, ach50: 0.74, height: 8.0, volume: 7200.0)
      elsif [CalcType::ReferenceHome].include? calc_type
        _check_infiltration(hpxml_bldg, ach50: 7.09, height: 8.0, volume: 7200.0)
      elsif [CalcType::IndexAdjHome].include? calc_type
        _check_infiltration(hpxml_bldg, ach50: 3.0, height: 17.0, volume: 20400.0)
      elsif [CalcType::IndexAdjReferenceHome].include? calc_type
        _check_infiltration(hpxml_bldg, ach50: 6.67, height: 17.0, volume: 20400.0)
      end
    end

    # Test attached dwelling where Aext < 0.5 and exhaust mech vent
    # Create derivative file for testing
    hpxml_name = 'base-bldgtype-mf-unit.xml'
    hpxml = HPXML.new(hpxml_path: File.join(@root_path, 'workflow', 'sample_files', hpxml_name))
    hpxml_bldg = hpxml.buildings[0]
    hpxml_bldg.ventilation_fans.add(id: 'MechanicalVentilation',
                                    fan_type: HPXML::MechVentTypeExhaust,
                                    tested_flow_rate: 110.0,
                                    hours_in_operation: 24.0,
                                    used_for_whole_building_ventilation: true,
                                    fan_power: 30.0,
                                    is_shared_system: false)
    hpxml_name = File.basename(@tmp_hpxml_path)
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)

    _test_ruleset(hpxml_name).each do |(_run_type, calc_type), hpxml_bldg|
      if [CalcType::RatedHome].include? calc_type
        _check_infiltration(hpxml_bldg, ach50: 2.43, height: 8.0, volume: 7200.0)
      elsif [CalcType::ReferenceHome].include? calc_type
        _check_infiltration(hpxml_bldg, ach50: 7.09, height: 8.0, volume: 7200.0)
      elsif [CalcType::IndexAdjHome].include? calc_type
        _check_infiltration(hpxml_bldg, ach50: 3.0, height: 17.0, volume: 20400.0)
      elsif [CalcType::IndexAdjReferenceHome].include? calc_type
        _check_infiltration(hpxml_bldg, ach50: 6.67, height: 17.0, volume: 20400.0)
      end
    end

    # Test CFIS mechanical ventilation that does not quality as a
    # Dwelling Unit Mechanical Ventilation System
    hpxml_name = 'base-mechvent-cfis-no-additional-runtime.xml'

    _test_ruleset(hpxml_name).each do |(_run_type, calc_type), hpxml_bldg|
      if [CalcType::RatedHome].include? calc_type
        _check_infiltration(hpxml_bldg, ach50: 9.1, height: 9.75, volume: 21600.0) # 0.3 nACH
      elsif [CalcType::ReferenceHome].include? calc_type
        _check_infiltration(hpxml_bldg, ach50: 7.09, height: 9.75, volume: 21600.0)
      elsif [CalcType::IndexAdjHome].include? calc_type
        _check_infiltration(hpxml_bldg, ach50: 3.0, height: 17.0, volume: 20400.0)
      elsif [CalcType::IndexAdjReferenceHome].include? calc_type
        _check_infiltration(hpxml_bldg, ach50: 6.67, height: 17.0, volume: 20400.0)
      end
    end

    # Same as above but prior to 301-2022 Addendum E
    _test_ruleset(hpxml_name, '2022C').each do |(_run_type, calc_type), hpxml_bldg|
      if [CalcType::RatedHome].include? calc_type
        _check_infiltration(hpxml_bldg, ach50: 3.0, height: 9.75, volume: 21600.0) # not 0.3 nACH
      elsif [CalcType::ReferenceHome].include? calc_type
        _check_infiltration(hpxml_bldg, ach50: 7.09, height: 9.75, volume: 21600.0)
      elsif [CalcType::IndexAdjHome].include? calc_type
        _check_infiltration(hpxml_bldg, ach50: 3.0, height: 17.0, volume: 20400.0)
      elsif [CalcType::IndexAdjReferenceHome].include? calc_type
        _check_infiltration(hpxml_bldg, ach50: 6.67, height: 17.0, volume: 20400.0)
      end
    end
  end

  def test_enclosure_roofs
    hpxml_name = 'base.xml'

    _test_ruleset(hpxml_name).each do |(_run_type, calc_type), hpxml_bldg|
      if [CalcType::RatedHome].include? calc_type
        _check_roofs(hpxml_bldg, area: 1510, rvalue: 2.3, sabs: 0.7, emit: 0.92)
      elsif [CalcType::ReferenceHome].include? calc_type
        _check_roofs(hpxml_bldg, area: 1510, rvalue: 2.3, sabs: 0.75, emit: 0.9)
      elsif [CalcType::IndexAdjHome].include? calc_type
        _check_roofs(hpxml_bldg, area: 1300, rvalue: 2.3, sabs: 0.7, emit: 0.92)
      elsif [CalcType::IndexAdjReferenceHome].include? calc_type
        _check_roofs(hpxml_bldg, area: 1300, rvalue: 2.3, sabs: 0.75, emit: 0.9)
      end
    end

    hpxml_name = 'base-atticroof-cathedral.xml'

    _test_ruleset(hpxml_name).each do |(_run_type, calc_type), hpxml_bldg|
      if [CalcType::RatedHome].include? calc_type
        _check_roofs(hpxml_bldg,  area: 1510, rvalue: 29.7, sabs: 0.7, emit: 0.92)
      elsif [CalcType::ReferenceHome].include? calc_type
        _check_roofs(hpxml_bldg,  area: 1510, rvalue: 33.33, sabs: 0.75, emit: 0.9)
      elsif [CalcType::IndexAdjHome].include? calc_type
        _check_roofs(hpxml_bldg,  area: 1300, rvalue: 29.7, sabs: 0.7, emit: 0.92)
      elsif [CalcType::IndexAdjReferenceHome].include? calc_type
        _check_roofs(hpxml_bldg,  area: 1300, rvalue: 33.33, sabs: 0.75, emit: 0.9)
      end
    end

    hpxml_name = 'base-atticroof-conditioned.xml'

    _test_ruleset(hpxml_name).each do |(_run_type, calc_type), hpxml_bldg|
      if [CalcType::RatedHome].include? calc_type
        _check_roofs(hpxml_bldg,  area: 1510, rvalue: (25.8 * 1006 + 2.3 * 504) / 1510, sabs: 0.7, emit: 0.92)
      elsif [CalcType::ReferenceHome].include? calc_type
        _check_roofs(hpxml_bldg,  area: 1510, rvalue: (33.33 * 1006 + 2.3 * 504) / 1510, sabs: 0.75, emit: 0.9)
      elsif [CalcType::IndexAdjHome].include? calc_type
        _check_roofs(hpxml_bldg,  area: 1300, rvalue: (25.8 * 1006 + 2.3 * 504) / 1510, sabs: 0.7, emit: 0.92)
      elsif [CalcType::IndexAdjReferenceHome].include? calc_type
        _check_roofs(hpxml_bldg,  area: 1300, rvalue: (33.33 * 1006 + 2.3 * 504) / 1510, sabs: 0.75, emit: 0.9)
      end
    end

    hpxml_name = 'base-atticroof-unvented-insulated-roof.xml'

    _test_ruleset(hpxml_name).each do |(_run_type, calc_type), hpxml_bldg|
      if [CalcType::RatedHome].include? calc_type
        _check_roofs(hpxml_bldg, area: 1510, rvalue: 29.4, sabs: 0.7, emit: 0.92)
      elsif [CalcType::ReferenceHome].include? calc_type
        _check_roofs(hpxml_bldg, area: 1510, rvalue: 2.3, sabs: 0.75, emit: 0.9)
      elsif [CalcType::IndexAdjHome].include? calc_type
        _check_roofs(hpxml_bldg, area: 1300, rvalue: 29.4, sabs: 0.7, emit: 0.92)
      elsif [CalcType::IndexAdjReferenceHome].include? calc_type
        _check_roofs(hpxml_bldg, area: 1300, rvalue: 2.3, sabs: 0.75, emit: 0.9)
      end
    end

    hpxml_name = 'base-atticroof-flat.xml'

    _test_ruleset(hpxml_name).each do |(_run_type, calc_type), hpxml_bldg|
      if [CalcType::RatedHome].include? calc_type
        _check_roofs(hpxml_bldg, area: 1350, rvalue: 29.7, sabs: 0.7, emit: 0.92)
      elsif [CalcType::ReferenceHome].include? calc_type
        _check_roofs(hpxml_bldg, area: 1350, rvalue: 33.33, sabs: 0.75, emit: 0.9)
      elsif [CalcType::IndexAdjHome].include? calc_type
        _check_roofs(hpxml_bldg, area: 1300, rvalue: 29.7, sabs: 0.7, emit: 0.92)
      elsif [CalcType::IndexAdjReferenceHome].include? calc_type
        _check_roofs(hpxml_bldg, area: 1300, rvalue: 33.33, sabs: 0.75, emit: 0.9)
      end
    end

    hpxml_name = 'base-bldgtype-mf-unit.xml'

    _test_ruleset(hpxml_name).each do |(_run_type, _calc_type), hpxml_bldg|
      _check_roofs(hpxml_bldg)
    end

    hpxml_name = 'base-atticroof-radiant-barrier.xml'

    _test_ruleset(hpxml_name).each do |(_run_type, calc_type), hpxml_bldg|
      if [CalcType::RatedHome].include? calc_type
        _check_roofs(hpxml_bldg, area: 1510, rvalue: 2.3, sabs: 0.7, emit: 0.92, rb_grade: 2)
      elsif [CalcType::ReferenceHome].include? calc_type
        _check_roofs(hpxml_bldg, area: 1510, rvalue: 2.3, sabs: 0.75, emit: 0.9)
      elsif [CalcType::IndexAdjHome].include? calc_type
        _check_roofs(hpxml_bldg, area: 1300, rvalue: 2.3, sabs: 0.7, emit: 0.92, rb_grade: 2)
      elsif [CalcType::IndexAdjReferenceHome].include? calc_type
        _check_roofs(hpxml_bldg, area: 1300, rvalue: 2.3, sabs: 0.75, emit: 0.9)
      end
    end
  end

  def test_enclosure_walls
    hpxml_name = 'base.xml'

    _test_ruleset(hpxml_name).each do |(_run_type, calc_type), hpxml_bldg|
      if [CalcType::RatedHome].include? calc_type
        _check_walls(hpxml_bldg, area: 1425, rvalue: (22.7 * 1200 + 4.0 * 225) / 1425, sabs: 0.7, emit: 0.92)
      elsif [CalcType::ReferenceHome].include? calc_type
        _check_walls(hpxml_bldg, area: 1425, rvalue: (16.67 * 1200 + 4.0 * 225) / 1425, sabs: 0.75, emit: 0.9)
      elsif [CalcType::IndexAdjHome].include? calc_type
        _check_walls(hpxml_bldg, area: 2355.52, rvalue: 22.7, sabs: 0.7, emit: 0.92)
      elsif [CalcType::IndexAdjReferenceHome].include? calc_type
        _check_walls(hpxml_bldg, area: 2355.52, rvalue: 16.67, sabs: 0.75, emit: 0.9)
      end
    end

    hpxml_name = 'base-atticroof-conditioned.xml'

    _test_ruleset(hpxml_name).each do |(_run_type, calc_type), hpxml_bldg|
      if [CalcType::RatedHome].include? calc_type
        _check_walls(hpxml_bldg, area: 1806, rvalue: (22.7 * 1516 + 22.3 * 240 + 4.0 * 50) / 1806, sabs: 0.7, emit: 0.92)
      elsif [CalcType::ReferenceHome].include? calc_type
        _check_walls(hpxml_bldg, area: 1806, rvalue: (16.67 * 1756 + 4.0 * 50) / 1806, sabs: 0.75, emit: 0.9)
      elsif [CalcType::IndexAdjHome].include? calc_type
        _check_walls(hpxml_bldg, area: 2355.52, rvalue: (22.7 * 1200 + 22.3 * 240) / 1440, sabs: 0.7, emit: 0.92)
      elsif [CalcType::IndexAdjReferenceHome].include? calc_type
        _check_walls(hpxml_bldg, area: 2355.52, rvalue: 16.67, sabs: 0.75, emit: 0.9)
      end
    end

    hpxml_name = 'base-bldgtype-mf-unit.xml'

    _test_ruleset(hpxml_name).each do |(_run_type, calc_type), hpxml_bldg|
      if [CalcType::RatedHome].include? calc_type
        _check_walls(hpxml_bldg, area: 980, rvalue: (22.7 * 686 + 4.0 * 294) / 980, sabs: 0.7, emit: 0.92)
      elsif [CalcType::ReferenceHome].include? calc_type
        _check_walls(hpxml_bldg, area: 980, rvalue: (16.67 * 686 + 4.0 * 294) / 980, sabs: 0.75, emit: 0.9)
      elsif [CalcType::IndexAdjHome].include? calc_type
        _check_walls(hpxml_bldg, area: 2355.52, rvalue: 22.7, sabs: 0.7, emit: 0.92)
      elsif [CalcType::IndexAdjReferenceHome].include? calc_type
        _check_walls(hpxml_bldg, area: 2355.52, rvalue: 16.67, sabs: 0.75, emit: 0.9)
      end
    end

    hpxml_name = 'base-bldgtype-mf-unit-adjacent-to-multiple.xml'

    _test_ruleset(hpxml_name, '2019').each do |(_run_type, calc_type), hpxml_bldg|
      if [CalcType::RatedHome].include? calc_type
        _check_walls(hpxml_bldg, area: 1086, rvalue: (22.7 * 986 + 4.0 * 100) / 1086, sabs: 0.7, emit: 0.92)
      elsif [CalcType::ReferenceHome].include? calc_type
        _check_walls(hpxml_bldg, area: 1086, rvalue: (16.67 * 986 + 4.0 * 100) / 1086, sabs: 0.75, emit: 0.9)
      elsif [CalcType::IndexAdjHome].include? calc_type
        _check_walls(hpxml_bldg, area: 2355.52, rvalue: 22.7, sabs: 0.7, emit: 0.92)
      elsif [CalcType::IndexAdjReferenceHome].include? calc_type
        _check_walls(hpxml_bldg, area: 2355.52, rvalue: 16.67, sabs: 0.75, emit: 0.9)
      end
    end

    _test_ruleset(hpxml_name, '2022').each do |(_run_type, calc_type), hpxml_bldg|
      if [CalcType::RatedHome].include? calc_type
        _check_walls(hpxml_bldg, area: 1086, rvalue: (22.7 * 986 + 4.0 * 100) / 1086, sabs: 0.7, emit: 0.92)
      elsif [CalcType::ReferenceHome].include? calc_type
        _check_walls(hpxml_bldg, area: 1086, rvalue: (16.67 * 686 + 4.0 * 100 + 11.24 * 300) / 1086, sabs: 0.75, emit: 0.9)
      elsif [CalcType::IndexAdjHome].include? calc_type
        _check_walls(hpxml_bldg, area: 2355.52, rvalue: 22.7, sabs: 0.7, emit: 0.92)
      elsif [CalcType::IndexAdjReferenceHome].include? calc_type
        _check_walls(hpxml_bldg, area: 2355.52, rvalue: 16.67, sabs: 0.75, emit: 0.9)
      end
    end

    hpxml_name = 'base-enclosure-garage.xml'

    _test_ruleset(hpxml_name).each do |(_run_type, calc_type), hpxml_bldg|
      if [CalcType::RatedHome].include? calc_type
        _check_walls(hpxml_bldg, area: 2098, rvalue: (22.7 * 1200 + 4.0 * 898) / 2098, sabs: 0.7, emit: 0.92)
      elsif [CalcType::ReferenceHome].include? calc_type
        _check_walls(hpxml_bldg, area: 2098, rvalue: (16.67 * 1200 + 4.0 * 898) / 2098, sabs: 0.75, emit: 0.9)
      elsif [CalcType::IndexAdjHome].include? calc_type
        _check_walls(hpxml_bldg, area: 2355.52, rvalue: 22.7, sabs: 0.7, emit: 0.92)
      elsif [CalcType::IndexAdjReferenceHome].include? calc_type
        _check_walls(hpxml_bldg, area: 2355.52, rvalue: 16.67, sabs: 0.75, emit: 0.9)
      end
    end
  end

  def test_enclosure_rim_joists
    hpxml_name = 'base.xml'

    _test_ruleset(hpxml_name).each do |(_run_type, calc_type), hpxml_bldg|
      if [CalcType::RatedHome].include? calc_type
        _check_rim_joists(hpxml_bldg, area: 116, rvalue: 13.9, sabs: 0.7, emit: 0.92)
      elsif [CalcType::ReferenceHome].include? calc_type
        _check_rim_joists(hpxml_bldg, area: 116, rvalue: 16.67, sabs: 0.75, emit: 0.9)
      else
        _check_rim_joists(hpxml_bldg)
      end
    end

    hpxml_name = 'base-foundation-multiple.xml'

    _test_ruleset(hpxml_name).each do |(_run_type, calc_type), hpxml_bldg|
      if [CalcType::RatedHome].include? calc_type
        _check_rim_joists(hpxml_bldg, area: 197, rvalue: 4.0, sabs: 0.7, emit: 0.92)
      elsif [CalcType::ReferenceHome].include? calc_type
        _check_rim_joists(hpxml_bldg, area: 197, rvalue: 4.0, sabs: 0.75, emit: 0.9)
      else
        _check_rim_joists(hpxml_bldg)
      end
    end
  end

  def test_enclosure_foundation_walls
    hpxml_name = 'base.xml'

    _test_ruleset(hpxml_name).each do |(_run_type, calc_type), hpxml_bldg|
      if [CalcType::RatedHome, CalcType::ReferenceHome].include? calc_type
        _check_foundation_walls(hpxml_bldg, area: 1200, rvalue: 10.0, ins_bottom: 8, height: 8, depth_bg: 7, type: HPXML::FoundationWallTypeSolidConcrete)
      elsif [CalcType::IndexAdjHome, CalcType::IndexAdjReferenceHome].include? calc_type
        _check_foundation_walls(hpxml_bldg, area: 277.12, height: 2, type: HPXML::FoundationWallTypeSolidConcrete)
      end
    end

    hpxml_name = 'base-foundation-conditioned-basement-wall-insulation.xml'

    _test_ruleset(hpxml_name).each do |(_run_type, calc_type), hpxml_bldg|
      if [CalcType::RatedHome].include? calc_type
        _check_foundation_walls(hpxml_bldg, area: 1200, rvalue: 18.9, ins_top: 2, ins_bottom: 16, height: 8, depth_bg: 7, type: HPXML::FoundationWallTypeConcreteBlockFoamCore)
      elsif [CalcType::ReferenceHome].include? calc_type
        _check_foundation_walls(hpxml_bldg, area: 1200, rvalue: 10.0, ins_bottom: 8, height: 8, depth_bg: 7, type: HPXML::FoundationWallTypeConcreteBlockFoamCore)
      elsif [CalcType::IndexAdjHome, CalcType::IndexAdjReferenceHome].include? calc_type
        _check_foundation_walls(hpxml_bldg, area: 277.12, height: 2, type: HPXML::FoundationWallTypeSolidConcrete)
      end
    end

    hpxml_name = 'base-foundation-unconditioned-basement.xml'

    _test_ruleset(hpxml_name).each do |(_run_type, calc_type), hpxml_bldg|
      if [CalcType::RatedHome, CalcType::ReferenceHome].include? calc_type
        _check_foundation_walls(hpxml_bldg, area: 1200, height: 8, depth_bg: 7, type: HPXML::FoundationWallTypeSolidConcrete)
      elsif [CalcType::IndexAdjHome, CalcType::IndexAdjReferenceHome].include? calc_type
        _check_foundation_walls(hpxml_bldg, area: 277.12, height: 2, type: HPXML::FoundationWallTypeSolidConcrete)
      end
    end

    hpxml_names = ['base-foundation-unvented-crawlspace.xml',
                   'base-foundation-vented-crawlspace.xml']

    hpxml_names.each do |hpxml_name|
      _test_ruleset(hpxml_name).each do |(_run_type, calc_type), hpxml_bldg|
        if [CalcType::RatedHome].include? calc_type
          _check_foundation_walls(hpxml_bldg, area: 600, rvalue: 10.0, ins_bottom: 4, height: 4, depth_bg: 3, type: HPXML::FoundationWallTypeSolidConcrete)
        elsif [CalcType::ReferenceHome].include? calc_type
          _check_foundation_walls(hpxml_bldg, area: 600, height: 4, depth_bg: 3, type: HPXML::FoundationWallTypeSolidConcrete)
        elsif [CalcType::IndexAdjHome, CalcType::IndexAdjReferenceHome].include? calc_type
          _check_foundation_walls(hpxml_bldg, area: 277.12, height: 2, type: HPXML::FoundationWallTypeSolidConcrete)
        end
      end
    end
  end

  def test_enclosure_ceilings
    hpxml_name = 'base.xml'

    _test_ruleset(hpxml_name).each do |(_run_type, calc_type), hpxml_bldg|
      if [CalcType::RatedHome].include? calc_type
        _check_ceilings(hpxml_bldg, area: 1350, rvalue: 39.3, floor_type: HPXML::FloorTypeWoodFrame)
      elsif [CalcType::ReferenceHome].include? calc_type
        _check_ceilings(hpxml_bldg, area: 1350, rvalue: 33.33, floor_type: HPXML::FloorTypeWoodFrame)
      elsif [CalcType::IndexAdjHome].include? calc_type
        _check_ceilings(hpxml_bldg, area: 1200, rvalue: 39.3, floor_type: HPXML::FloorTypeWoodFrame)
      elsif [CalcType::IndexAdjReferenceHome].include? calc_type
        _check_ceilings(hpxml_bldg, area: 1200, rvalue: 33.33, floor_type: HPXML::FloorTypeWoodFrame)
      end
    end

    hpxml_name = 'base-enclosure-garage.xml'

    _test_ruleset(hpxml_name).each do |(_run_type, calc_type), hpxml_bldg|
      if [CalcType::RatedHome].include? calc_type
        _check_ceilings(hpxml_bldg, area: 1950, rvalue: (39.3 * 1350 + 2.1 * 600) / 1950, floor_type: HPXML::FloorTypeWoodFrame)
      elsif [CalcType::ReferenceHome].include? calc_type
        _check_ceilings(hpxml_bldg, area: 1950, rvalue: (33.33 * 1350 + 2.1 * 600) / 1950, floor_type: HPXML::FloorTypeWoodFrame)
      elsif [CalcType::IndexAdjHome].include? calc_type
        _check_ceilings(hpxml_bldg, area: 1200, rvalue: 39.3, floor_type: HPXML::FloorTypeWoodFrame)
      elsif [CalcType::IndexAdjReferenceHome].include? calc_type
        _check_ceilings(hpxml_bldg, area: 1200, rvalue: 33.33, floor_type: HPXML::FloorTypeWoodFrame)
      end
    end

    hpxml_name = 'base-bldgtype-mf-unit.xml'

    _test_ruleset(hpxml_name).each do |(_run_type, calc_type), hpxml_bldg|
      if [CalcType::RatedHome].include? calc_type
        _check_ceilings(hpxml_bldg, area: 900, rvalue: 2.1, floor_type: HPXML::FloorTypeWoodFrame)
      elsif [CalcType::ReferenceHome].include? calc_type
        _check_ceilings(hpxml_bldg, area: 900, rvalue: 2.1, floor_type: HPXML::FloorTypeWoodFrame)
      elsif [CalcType::IndexAdjHome].include? calc_type
        _check_ceilings(hpxml_bldg, area: 1200, rvalue: 2.1, floor_type: HPXML::FloorTypeWoodFrame)
      elsif [CalcType::IndexAdjReferenceHome].include? calc_type
        _check_ceilings(hpxml_bldg, area: 1200, rvalue: 2.1, floor_type: HPXML::FloorTypeWoodFrame)
      end
    end

    hpxml_name = 'base-bldgtype-mf-unit-adjacent-to-multiple.xml'

    _test_ruleset(hpxml_name).each do |(_run_type, calc_type), hpxml_bldg|
      if [CalcType::RatedHome].include? calc_type
        _check_ceilings(hpxml_bldg, area: 900, rvalue: 2.1, floor_type: HPXML::FloorTypeWoodFrame)
      elsif [CalcType::ReferenceHome].include? calc_type
        _check_ceilings(hpxml_bldg, area: 900, rvalue: 2.1, floor_type: HPXML::FloorTypeWoodFrame)
      elsif [CalcType::IndexAdjHome].include? calc_type
        _check_ceilings(hpxml_bldg, area: 1200, rvalue: 2.1, floor_type: HPXML::FloorTypeWoodFrame)
      elsif [CalcType::IndexAdjReferenceHome].include? calc_type
        _check_ceilings(hpxml_bldg, area: 1200, rvalue: 2.1, floor_type: HPXML::FloorTypeWoodFrame)
      end
    end

    # Check w/ mass ceilings
    hpxml = HPXML.new(hpxml_path: File.join(@root_path, 'workflow', 'sample_files', hpxml_name))
    hpxml_bldg = hpxml.buildings[0]
    hpxml_bldg.floors.each do |floor|
      next unless floor.is_ceiling

      floor.floor_type = HPXML::FloorTypeConcrete
    end
    hpxml_name = File.basename(@tmp_hpxml_path)
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _test_ruleset(hpxml_name).each do |(_run_type, calc_type), hpxml_bldg|
      if [CalcType::RatedHome].include? calc_type
        _check_ceilings(hpxml_bldg, area: 900, rvalue: 2.1, floor_type: HPXML::FloorTypeConcrete)
      elsif [CalcType::ReferenceHome].include? calc_type
        _check_ceilings(hpxml_bldg, area: 900, rvalue: 2.1, floor_type: HPXML::FloorTypeWoodFrame)
      elsif [CalcType::IndexAdjHome].include? calc_type
        _check_ceilings(hpxml_bldg, area: 1200, rvalue: 2.1, floor_type: HPXML::FloorTypeConcrete)
      elsif [CalcType::IndexAdjReferenceHome].include? calc_type
        _check_ceilings(hpxml_bldg, area: 1200, rvalue: 2.1, floor_type: HPXML::FloorTypeWoodFrame)
      end
    end
  end

  def test_enclosure_floors
    hpxml_name = 'base-foundation-ambient.xml'

    _test_ruleset(hpxml_name).each do |(_run_type, calc_type), hpxml_bldg|
      if [CalcType::RatedHome].include? calc_type
        _check_floors(hpxml_bldg, area: 1350, rvalue: 19.4, floor_type: HPXML::FloorTypeWoodFrame)
      elsif [CalcType::ReferenceHome].include? calc_type
        _check_floors(hpxml_bldg, area: 1350, rvalue: 30.3, floor_type: HPXML::FloorTypeWoodFrame)
      elsif [CalcType::IndexAdjHome].include? calc_type
        _check_floors(hpxml_bldg, area: 1200, rvalue: 30.3, floor_type: HPXML::FloorTypeWoodFrame)
      elsif [CalcType::IndexAdjReferenceHome].include? calc_type
        _check_floors(hpxml_bldg, area: 1200, rvalue: 30.3, floor_type: HPXML::FloorTypeWoodFrame)
      end
    end

    hpxml_name = 'base-foundation-unconditioned-basement.xml'

    _test_ruleset(hpxml_name).each do |(_run_type, calc_type), hpxml_bldg|
      if [CalcType::RatedHome].include? calc_type
        _check_floors(hpxml_bldg, area: 1350, rvalue: 19.4, floor_type: HPXML::FloorTypeWoodFrame)
      elsif [CalcType::ReferenceHome].include? calc_type
        _check_floors(hpxml_bldg, area: 1350, rvalue: 30.3, floor_type: HPXML::FloorTypeWoodFrame)
      elsif [CalcType::IndexAdjHome].include? calc_type
        _check_floors(hpxml_bldg, area: 1200, rvalue: 30.3, floor_type: HPXML::FloorTypeWoodFrame)
      elsif [CalcType::IndexAdjReferenceHome].include? calc_type
        _check_floors(hpxml_bldg, area: 1200, rvalue: 30.3, floor_type: HPXML::FloorTypeWoodFrame)
      end
    end

    hpxml_name = 'base-bldgtype-mf-unit.xml'

    _test_ruleset(hpxml_name).each do |(_run_type, calc_type), hpxml_bldg|
      if [CalcType::RatedHome].include? calc_type
        _check_floors(hpxml_bldg, area: 900, rvalue: 5.3, floor_type: HPXML::FloorTypeWoodFrame)
      elsif [CalcType::ReferenceHome].include? calc_type
        _check_floors(hpxml_bldg, area: 900, rvalue: 3.1, floor_type: HPXML::FloorTypeWoodFrame)
      elsif [CalcType::IndexAdjHome].include? calc_type
        _check_floors(hpxml_bldg, area: 1200, rvalue: 30.3, floor_type: HPXML::FloorTypeWoodFrame)
      elsif [CalcType::IndexAdjReferenceHome].include? calc_type
        _check_floors(hpxml_bldg, area: 1200, rvalue: 30.3, floor_type: HPXML::FloorTypeWoodFrame)
      end
    end

    hpxml_name = 'base-bldgtype-mf-unit-adjacent-to-multiple.xml'

    _test_ruleset(hpxml_name).each do |(_run_type, calc_type), hpxml_bldg|
      if [CalcType::RatedHome].include? calc_type
        _check_floors(hpxml_bldg, area: 900, rvalue: (19.4 * 750.0 + 2.1 * 150.0) / 900.0, floor_type: HPXML::FloorTypeWoodFrame)
      elsif [CalcType::ReferenceHome].include? calc_type
        _check_floors(hpxml_bldg, area: 900, rvalue: 30.3, floor_type: HPXML::FloorTypeWoodFrame)
      elsif [CalcType::IndexAdjHome].include? calc_type
        _check_floors(hpxml_bldg, area: 1200, rvalue: 30.3, floor_type: HPXML::FloorTypeWoodFrame)
      elsif [CalcType::IndexAdjReferenceHome].include? calc_type
        _check_floors(hpxml_bldg, area: 1200, rvalue: 30.3, floor_type: HPXML::FloorTypeWoodFrame)
      end
    end

    # Check w/ mass floors
    hpxml = HPXML.new(hpxml_path: File.join(@root_path, 'workflow', 'sample_files', hpxml_name))
    hpxml_bldg = hpxml.buildings[0]
    hpxml_bldg.floors.each do |floor|
      floor.floor_type = HPXML::FloorTypeConcrete
    end
    hpxml_name = File.basename(@tmp_hpxml_path)
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _test_ruleset(hpxml_name).each do |(_run_type, calc_type), hpxml_bldg|
      if [CalcType::RatedHome].include? calc_type
        _check_floors(hpxml_bldg, area: 900, rvalue: (19.4 * 750.0 + 2.1 * 150.0) / 900.0, floor_type: HPXML::FloorTypeConcrete)
      elsif [CalcType::ReferenceHome].include? calc_type
        _check_floors(hpxml_bldg, area: 900, rvalue: 30.3, floor_type: HPXML::FloorTypeWoodFrame)
      elsif [CalcType::IndexAdjHome].include? calc_type
        _check_floors(hpxml_bldg, area: 1200, rvalue: 30.3, floor_type: HPXML::FloorTypeWoodFrame)
      elsif [CalcType::IndexAdjReferenceHome].include? calc_type
        _check_floors(hpxml_bldg, area: 1200, rvalue: 30.3, floor_type: HPXML::FloorTypeWoodFrame)
      end
    end
  end

  def test_enclosure_slabs
    hpxml_name = 'base.xml'

    _test_ruleset(hpxml_name).each do |(_run_type, calc_type), hpxml_bldg|
      if [CalcType::RatedHome].include? calc_type
        _check_slabs(hpxml_bldg, area: 1350, exp_perim: 150)
      elsif [CalcType::ReferenceHome].include? calc_type
        _check_slabs(hpxml_bldg, area: 1350, exp_perim: 150)
      elsif [CalcType::IndexAdjHome].include? calc_type
        _check_slabs(hpxml_bldg, area: 1200, exp_perim: 138.6)
      elsif [CalcType::IndexAdjReferenceHome].include? calc_type
        _check_slabs(hpxml_bldg, area: 1200, exp_perim: 138.6)
      end
    end

    hpxml_name = 'base-foundation-slab.xml'

    _test_ruleset(hpxml_name).each do |(_run_type, calc_type), hpxml_bldg|
      if [CalcType::RatedHome].include? calc_type
        _check_slabs(hpxml_bldg, area: 1350, exp_perim: 150, under_ins_width: 999, under_ins_r: 5, depth_below_grade: 0)
      elsif [CalcType::ReferenceHome].include? calc_type
        _check_slabs(hpxml_bldg, area: 1350, exp_perim: 150, perim_ins_depth: 2, perim_ins_r: 10, depth_below_grade: 0)
      elsif [CalcType::IndexAdjHome].include? calc_type
        _check_slabs(hpxml_bldg, area: 1200, exp_perim: 138.6)
      elsif [CalcType::IndexAdjReferenceHome].include? calc_type
        _check_slabs(hpxml_bldg, area: 1200, exp_perim: 138.6)
      end
    end

    hpxml_name = 'base-foundation-conditioned-basement-slab-insulation.xml'

    _test_ruleset(hpxml_name).each do |(_run_type, calc_type), hpxml_bldg|
      if [CalcType::RatedHome].include? calc_type
        _check_slabs(hpxml_bldg, area: 1350, exp_perim: 150, under_ins_width: 4, under_ins_r: 10, gap_ins_r: 5)
      elsif [CalcType::ReferenceHome].include? calc_type
        _check_slabs(hpxml_bldg, area: 1350, exp_perim: 150)
      elsif [CalcType::IndexAdjHome].include? calc_type
        _check_slabs(hpxml_bldg, area: 1200, exp_perim: 138.6)
      elsif [CalcType::IndexAdjReferenceHome].include? calc_type
        _check_slabs(hpxml_bldg, area: 1200, exp_perim: 138.6)
      end
    end
  end

  def test_enclosure_windows
    hpxml_names = ['base.xml',
                   'base-atticroof-flat.xml',
                   'base-atticroof-vented.xml']

    hpxml_names.each do |hpxml_name|
      _test_ruleset(hpxml_name, '2022C').each do |(_run_type, calc_type), hpxml_bldg|
        if [CalcType::RatedHome].include? calc_type
          _check_windows(hpxml_bldg, frac_operable: 0.67,
                                     values_by_azimuth: { 0 => { area: 108, ufactor: 0.35, shgc: 0.44, interior_shading_factor_summer: 0.8255, interior_shading_factor_winter: 0.8255 },
                                                          180 => { area: 108, ufactor: 0.35, shgc: 0.44, interior_shading_factor_summer: 0.8255, interior_shading_factor_winter: 0.8255 },
                                                          90 => { area: 72, ufactor: 0.35, shgc: 0.44, interior_shading_factor_summer: 0.8255, interior_shading_factor_winter: 0.8255 },
                                                          270 => { area: 72, ufactor: 0.35, shgc: 0.44, interior_shading_factor_summer: 0.8255, interior_shading_factor_winter: 0.8255 } })
        elsif [CalcType::ReferenceHome].include? calc_type
          _check_windows(hpxml_bldg, frac_operable: 0.67,
                                     values_by_azimuth: { 0 => { area: 89.5, ufactor: 0.35, shgc: 0.40, interior_shading_factor_summer: 0.836, interior_shading_factor_winter: 0.836 },
                                                          180 => { area: 89.5, ufactor: 0.35, shgc: 0.40, interior_shading_factor_summer: 0.836, interior_shading_factor_winter: 0.836 },
                                                          90 => { area: 89.5, ufactor: 0.35, shgc: 0.40, interior_shading_factor_summer: 0.836, interior_shading_factor_winter: 0.836 },
                                                          270 => { area: 89.5, ufactor: 0.35, shgc: 0.40, interior_shading_factor_summer: 0.836, interior_shading_factor_winter: 0.836 } })
        elsif [CalcType::IndexAdjHome].include? calc_type
          _check_windows(hpxml_bldg, frac_operable: 0.67,
                                     values_by_azimuth: { 0 => { area: 108, ufactor: 0.35, shgc: 0.44, interior_shading_factor_summer: 0.836, interior_shading_factor_winter: 0.836 },
                                                          180 => { area: 108, ufactor: 0.35, shgc: 0.44, interior_shading_factor_summer: 0.836, interior_shading_factor_winter: 0.836 },
                                                          90 => { area: 108, ufactor: 0.35, shgc: 0.44, interior_shading_factor_summer: 0.836, interior_shading_factor_winter: 0.836 },
                                                          270 => { area: 108, ufactor: 0.35, shgc: 0.44, interior_shading_factor_summer: 0.836, interior_shading_factor_winter: 0.836 } })
        elsif [CalcType::IndexAdjReferenceHome].include? calc_type
          _check_windows(hpxml_bldg, frac_operable: 0.67,
                                     values_by_azimuth: { 0 => { area: 108, ufactor: 0.35, shgc: 0.40, interior_shading_factor_summer: 0.836, interior_shading_factor_winter: 0.836 },
                                                          180 => { area: 108, ufactor: 0.35, shgc: 0.40, interior_shading_factor_summer: 0.836, interior_shading_factor_winter: 0.836 },
                                                          90 => { area: 108, ufactor: 0.35, shgc: 0.40, interior_shading_factor_summer: 0.836, interior_shading_factor_winter: 0.836 },
                                                          270 => { area: 108, ufactor: 0.35, shgc: 0.40, interior_shading_factor_summer: 0.836, interior_shading_factor_winter: 0.836 } })
        end
      end
    end

    # prior to 301-2022C: Shading coefficients are fixed values: 0.7 for summer, 0.85 for winter
    hpxml_names.each do |hpxml_name|
      _test_ruleset(hpxml_name, '2019').each do |(_run_type, calc_type), hpxml_bldg|
        if [CalcType::RatedHome].include? calc_type
          _check_windows(hpxml_bldg, frac_operable: 0.67,
                                     values_by_azimuth: { 0 => { area: 108, ufactor: 0.35, shgc: 0.44, interior_shading_factor_summer: 0.70, interior_shading_factor_winter: 0.85 },
                                                          180 => { area: 108, ufactor: 0.35, shgc: 0.44, interior_shading_factor_summer: 0.70, interior_shading_factor_winter: 0.85 },
                                                          90 => { area: 72, ufactor: 0.35, shgc: 0.44, interior_shading_factor_summer: 0.70, interior_shading_factor_winter: 0.85 },
                                                          270 => { area: 72, ufactor: 0.35, shgc: 0.44, interior_shading_factor_summer: 0.70, interior_shading_factor_winter: 0.85 } })
        elsif [CalcType::ReferenceHome].include? calc_type
          _check_windows(hpxml_bldg, frac_operable: 0.67,
                                     values_by_azimuth: { 0 => { area: 89.5, ufactor: 0.35, shgc: 0.40, interior_shading_factor_summer: 0.70, interior_shading_factor_winter: 0.85 },
                                                          180 => { area: 89.5, ufactor: 0.35, shgc: 0.40, interior_shading_factor_summer: 0.70, interior_shading_factor_winter: 0.85 },
                                                          90 => { area: 89.5, ufactor: 0.35, shgc: 0.40, interior_shading_factor_summer: 0.70, interior_shading_factor_winter: 0.85 },
                                                          270 => { area: 89.5, ufactor: 0.35, shgc: 0.40, interior_shading_factor_summer: 0.70, interior_shading_factor_winter: 0.85 } })
        elsif [CalcType::IndexAdjHome].include? calc_type
          _check_windows(hpxml_bldg, frac_operable: 0.67,
                                     values_by_azimuth: { 0 => { area: 108, ufactor: 0.35, shgc: 0.44, interior_shading_factor_summer: 0.70, interior_shading_factor_winter: 0.85 },
                                                          180 => { area: 108, ufactor: 0.35, shgc: 0.44, interior_shading_factor_summer: 0.70, interior_shading_factor_winter: 0.85 },
                                                          90 => { area: 108, ufactor: 0.35, shgc: 0.44, interior_shading_factor_summer: 0.70, interior_shading_factor_winter: 0.85 },
                                                          270 => { area: 108, ufactor: 0.35, shgc: 0.44, interior_shading_factor_summer: 0.70, interior_shading_factor_winter: 0.85 } })
        elsif [CalcType::IndexAdjReferenceHome].include? calc_type
          _check_windows(hpxml_bldg, frac_operable: 0.67,
                                     values_by_azimuth: { 0 => { area: 108, ufactor: 0.35, shgc: 0.40, interior_shading_factor_summer: 0.70, interior_shading_factor_winter: 0.85 },
                                                          180 => { area: 108, ufactor: 0.35, shgc: 0.40, interior_shading_factor_summer: 0.70, interior_shading_factor_winter: 0.85 },
                                                          90 => { area: 108, ufactor: 0.35, shgc: 0.40, interior_shading_factor_summer: 0.70, interior_shading_factor_winter: 0.85 },
                                                          270 => { area: 108, ufactor: 0.35, shgc: 0.40, interior_shading_factor_summer: 0.70, interior_shading_factor_winter: 0.85 } })
        end
      end
    end

    hpxml_names = ['base-foundation-ambient.xml',
                   'base-foundation-slab.xml',
                   'base-foundation-unconditioned-basement.xml',
                   'base-foundation-unvented-crawlspace.xml',
                   'base-foundation-vented-crawlspace.xml']

    hpxml_names.each do |hpxml_name|
      _test_ruleset(hpxml_name).each do |(_run_type, calc_type), hpxml_bldg|
        if [CalcType::RatedHome].include? calc_type
          _check_windows(hpxml_bldg, frac_operable: 0.67,
                                     values_by_azimuth: { 0 => { area: 108, ufactor: 0.35, shgc: 0.44, interior_shading_factor_summer: 0.8255, interior_shading_factor_winter: 0.8255 },
                                                          180 => { area: 108, ufactor: 0.35, shgc: 0.44, interior_shading_factor_summer: 0.8255, interior_shading_factor_winter: 0.8255 },
                                                          90 => { area: 72, ufactor: 0.35, shgc: 0.44, interior_shading_factor_summer: 0.8255, interior_shading_factor_winter: 0.8255 },
                                                          270 => { area: 72, ufactor: 0.35, shgc: 0.44, interior_shading_factor_summer: 0.8255, interior_shading_factor_winter: 0.8255 } })
        elsif [CalcType::ReferenceHome].include? calc_type
          _check_windows(hpxml_bldg, frac_operable: 0.67,
                                     values_by_azimuth: { 0 => { area: 60.75, ufactor: 0.35, shgc: 0.40, interior_shading_factor_summer: 0.836, interior_shading_factor_winter: 0.836 },
                                                          180 => { area: 60.75, ufactor: 0.35, shgc: 0.40, interior_shading_factor_summer: 0.836, interior_shading_factor_winter: 0.836 },
                                                          90 => { area: 60.75, ufactor: 0.35, shgc: 0.40, interior_shading_factor_summer: 0.836, interior_shading_factor_winter: 0.836 },
                                                          270 => { area: 60.75, ufactor: 0.35, shgc: 0.40, interior_shading_factor_summer: 0.836, interior_shading_factor_winter: 0.836 } })
        elsif [CalcType::IndexAdjHome].include? calc_type
          _check_windows(hpxml_bldg, frac_operable: 0.67,
                                     values_by_azimuth: { 0 => { area: 108, ufactor: 0.35, shgc: 0.44, interior_shading_factor_summer: 0.836, interior_shading_factor_winter: 0.836 },
                                                          180 => { area: 108, ufactor: 0.35, shgc: 0.44, interior_shading_factor_summer: 0.836, interior_shading_factor_winter: 0.836 },
                                                          90 => { area: 108, ufactor: 0.35, shgc: 0.44, interior_shading_factor_summer: 0.836, interior_shading_factor_winter: 0.836 },
                                                          270 => { area: 108, ufactor: 0.35, shgc: 0.44, interior_shading_factor_summer: 0.836, interior_shading_factor_winter: 0.836 } })
        elsif [CalcType::IndexAdjReferenceHome].include? calc_type
          _check_windows(hpxml_bldg, frac_operable: 0.67,
                                     values_by_azimuth: { 0 => { area: 108, ufactor: 0.35, shgc: 0.40, interior_shading_factor_summer: 0.836, interior_shading_factor_winter: 0.836 },
                                                          180 => { area: 108, ufactor: 0.35, shgc: 0.40, interior_shading_factor_summer: 0.836, interior_shading_factor_winter: 0.836 },
                                                          90 => { area: 108, ufactor: 0.35, shgc: 0.40, interior_shading_factor_summer: 0.836, interior_shading_factor_winter: 0.836 },
                                                          270 => { area: 108, ufactor: 0.35, shgc: 0.40, interior_shading_factor_summer: 0.836, interior_shading_factor_winter: 0.836 } })
        end
      end
    end

    hpxml_name = 'base-atticroof-cathedral.xml'
    hpxml = HPXML.new(hpxml_path: File.join(@root_path, 'workflow', 'sample_files', hpxml_name))
    hpxml_bldg = hpxml.buildings[0]
    hpxml_bldg.windows[1].area -= 12.0
    hpxml_bldg.windows[3].area -= 12.0
    hpxml_bldg.windows << hpxml_bldg.windows[-1].dup
    hpxml_bldg.windows[-1].id = "Window#{hpxml_bldg.windows.size + 1}"
    hpxml_bldg.windows[-1].area = 12.0
    hpxml_bldg.windows[-1].fraction_operable = 0.0
    hpxml_bldg.windows[-1].azimuth = 90
    hpxml_bldg.windows << hpxml_bldg.windows[-1].dup
    hpxml_bldg.windows[-1].id = "Window#{hpxml_bldg.windows.size + 1}"
    hpxml_bldg.windows[-1].azimuth = 270
    hpxml_name = File.basename(@tmp_hpxml_path)
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)

    _test_ruleset(hpxml_name).each do |(_run_type, calc_type), hpxml_bldg|
      if [CalcType::RatedHome].include? calc_type
        _check_windows(hpxml_bldg, frac_operable: (432.0 * 0.67) / (432.0 + 24.0),
                                   values_by_azimuth: { 0 => { area: 108, ufactor: 0.35, shgc: 0.44, interior_shading_factor_summer: 0.8255, interior_shading_factor_winter: 0.8255 },
                                                        180 => { area: 108, ufactor: 0.35, shgc: 0.44, interior_shading_factor_summer: 0.8255, interior_shading_factor_winter: 0.8255 },
                                                        90 => { area: 120, ufactor: 0.35, shgc: 0.44, interior_shading_factor_summer: 0.8255, interior_shading_factor_winter: 0.8255 },
                                                        270 => { area: 120, ufactor: 0.35, shgc: 0.44, interior_shading_factor_summer: 0.8255, interior_shading_factor_winter: 0.8255 } })
      elsif [CalcType::ReferenceHome].include? calc_type
        _check_windows(hpxml_bldg, frac_operable: 0.67,
                                   values_by_azimuth: { 0 => { area: 93.5, ufactor: 0.35, shgc: 0.40, interior_shading_factor_summer: 0.836, interior_shading_factor_winter: 0.836 },
                                                        180 => { area: 93.5, ufactor: 0.35, shgc: 0.40, interior_shading_factor_summer: 0.836, interior_shading_factor_winter: 0.836 },
                                                        90 => { area: 93.5, ufactor: 0.35, shgc: 0.40, interior_shading_factor_summer: 0.836, interior_shading_factor_winter: 0.836 },
                                                        270 => { area: 93.5, ufactor: 0.35, shgc: 0.40, interior_shading_factor_summer: 0.836, interior_shading_factor_winter: 0.836 } })
      elsif [CalcType::IndexAdjHome].include? calc_type
        _check_windows(hpxml_bldg, frac_operable: 0.67,
                                   values_by_azimuth: { 0 => { area: 108, ufactor: 0.35, shgc: 0.44, interior_shading_factor_summer: 0.836, interior_shading_factor_winter: 0.836 },
                                                        180 => { area: 108, ufactor: 0.35, shgc: 0.44, interior_shading_factor_summer: 0.836, interior_shading_factor_winter: 0.836 },
                                                        90 => { area: 108, ufactor: 0.35, shgc: 0.44, interior_shading_factor_summer: 0.836, interior_shading_factor_winter: 0.836 },
                                                        270 => { area: 108, ufactor: 0.35, shgc: 0.44, interior_shading_factor_summer: 0.836, interior_shading_factor_winter: 0.836 } })
      elsif [CalcType::IndexAdjReferenceHome].include? calc_type
        _check_windows(hpxml_bldg, frac_operable: 0.67,
                                   values_by_azimuth: { 0 => { area: 108, ufactor: 0.35, shgc: 0.40, interior_shading_factor_summer: 0.836, interior_shading_factor_winter: 0.836 },
                                                        180 => { area: 108, ufactor: 0.35, shgc: 0.40, interior_shading_factor_summer: 0.836, interior_shading_factor_winter: 0.836 },
                                                        90 => { area: 108, ufactor: 0.35, shgc: 0.40, interior_shading_factor_summer: 0.836, interior_shading_factor_winter: 0.836 },
                                                        270 => { area: 108, ufactor: 0.35, shgc: 0.40, interior_shading_factor_summer: 0.836, interior_shading_factor_winter: 0.836 } })
      end
    end

    hpxml_name = 'base-atticroof-conditioned.xml'

    _test_ruleset(hpxml_name).each do |(_run_type, calc_type), hpxml_bldg|
      if [CalcType::RatedHome].include? calc_type
        _check_windows(hpxml_bldg, frac_operable: (432.0 * 0.67) / (432.0 + 74.0),
                                   values_by_azimuth: { 0 => { area: 108, ufactor: 0.35, shgc: 0.44, interior_shading_factor_summer: 0.8255, interior_shading_factor_winter: 0.8255 },
                                                        180 => { area: 108, ufactor: 0.35, shgc: 0.44, interior_shading_factor_summer: 0.8255, interior_shading_factor_winter: 0.8255 },
                                                        90 => { area: 120, ufactor: 0.35, shgc: 0.44, interior_shading_factor_summer: 0.8255, interior_shading_factor_winter: 0.8255 },
                                                        270 => { area: 170, ufactor: (0.3 * 62 + 0.35 * 108) / 170, shgc: 0.44, interior_shading_factor_summer: 0.8255, interior_shading_factor_winter: 0.8255 } })
      elsif [CalcType::ReferenceHome].include? calc_type
        _check_windows(hpxml_bldg, frac_operable: 0.67,
                                   values_by_azimuth: { 0 => { area: 128.6, ufactor: 0.35, shgc: 0.40, interior_shading_factor_summer: 0.836, interior_shading_factor_winter: 0.836 },
                                                        180 => { area: 128.6, ufactor: 0.35, shgc: 0.40, interior_shading_factor_summer: 0.836, interior_shading_factor_winter: 0.836 },
                                                        90 => { area: 128.6, ufactor: 0.35, shgc: 0.40, interior_shading_factor_summer: 0.836, interior_shading_factor_winter: 0.836 },
                                                        270 => { area: 128.6, ufactor: 0.35, shgc: 0.40, interior_shading_factor_summer: 0.836, interior_shading_factor_winter: 0.836 } })
      elsif [CalcType::IndexAdjHome].include? calc_type
        _check_windows(hpxml_bldg, frac_operable: 0.67,
                                   values_by_azimuth: { 0 => { area: 108, ufactor: (0.3 * 62 + 0.35 * 444) / 506, shgc: 0.44, interior_shading_factor_summer: 0.836, interior_shading_factor_winter: 0.836 },
                                                        180 => { area: 108, ufactor: (0.3 * 62 + 0.35 * 444) / 506, shgc: 0.44, interior_shading_factor_summer: 0.836, interior_shading_factor_winter: 0.836 },
                                                        90 => { area: 108, ufactor: (0.3 * 62 + 0.35 * 444) / 506, shgc: 0.44, interior_shading_factor_summer: 0.836, interior_shading_factor_winter: 0.836 },
                                                        270 => { area: 108, ufactor: (0.3 * 62 + 0.35 * 444) / 506, shgc: 0.44, interior_shading_factor_summer: 0.836, interior_shading_factor_winter: 0.836 } })
      elsif [CalcType::IndexAdjReferenceHome].include? calc_type
        _check_windows(hpxml_bldg, frac_operable: 0.67,
                                   values_by_azimuth: { 0 => { area: 108, ufactor: 0.35, shgc: 0.40, interior_shading_factor_summer: 0.836, interior_shading_factor_winter: 0.836 },
                                                        180 => { area: 108, ufactor: 0.35, shgc: 0.40, interior_shading_factor_summer: 0.836, interior_shading_factor_winter: 0.836 },
                                                        90 => { area: 108, ufactor: 0.35, shgc: 0.40, interior_shading_factor_summer: 0.836, interior_shading_factor_winter: 0.836 },
                                                        270 => { area: 108, ufactor: 0.35, shgc: 0.40, interior_shading_factor_summer: 0.836, interior_shading_factor_winter: 0.836 } })
      end
    end

    hpxml_name = 'base-bldgtype-mf-unit.xml'

    _test_ruleset(hpxml_name).each do |(_run_type, calc_type), hpxml_bldg|
      if [CalcType::RatedHome].include? calc_type
        _check_windows(hpxml_bldg, frac_operable: 0.67,
                                   values_by_azimuth: { 0 => { area: 35.0, ufactor: 0.35, shgc: 0.44, interior_shading_factor_summer: 0.8255, interior_shading_factor_winter: 0.8255 },
                                                        180 => { area: 35.0, ufactor: 0.35, shgc: 0.44, interior_shading_factor_summer: 0.8255, interior_shading_factor_winter: 0.8255 },
                                                        270 => { area: 53.0, ufactor: 0.35, shgc: 0.44, interior_shading_factor_summer: 0.8255, interior_shading_factor_winter: 0.8255 } })
      elsif [CalcType::ReferenceHome].include? calc_type
        _check_windows(hpxml_bldg, frac_operable: 0.67,
                                   values_by_azimuth: { 0 => { area: 35.15, ufactor: 0.35, shgc: 0.40, interior_shading_factor_summer: 0.836, interior_shading_factor_winter: 0.836 },
                                                        180 => { area: 35.15, ufactor: 0.35, shgc: 0.40, interior_shading_factor_summer: 0.836, interior_shading_factor_winter: 0.836 },
                                                        90 => { area: 35.15, ufactor: 0.35, shgc: 0.40, interior_shading_factor_summer: 0.836, interior_shading_factor_winter: 0.836 },
                                                        270 => { area: 35.15, ufactor: 0.35, shgc: 0.40, interior_shading_factor_summer: 0.836, interior_shading_factor_winter: 0.836 } })
      elsif [CalcType::IndexAdjHome].include? calc_type
        _check_windows(hpxml_bldg, frac_operable: 0.67,
                                   values_by_azimuth: { 0 => { area: 108, ufactor: 0.35, shgc: 0.44, interior_shading_factor_summer: 0.836, interior_shading_factor_winter: 0.836 },
                                                        180 => { area: 108, ufactor: 0.35, shgc: 0.44, interior_shading_factor_summer: 0.836, interior_shading_factor_winter: 0.836 },
                                                        90 => { area: 108, ufactor: 0.35, shgc: 0.44, interior_shading_factor_summer: 0.836, interior_shading_factor_winter: 0.836 },
                                                        270 => { area: 108, ufactor: 0.35, shgc: 0.44, interior_shading_factor_summer: 0.836, interior_shading_factor_winter: 0.836 } })
      elsif [CalcType::IndexAdjReferenceHome].include? calc_type
        _check_windows(hpxml_bldg, frac_operable: 0.67,
                                   values_by_azimuth: { 0 => { area: 108, ufactor: 0.35, shgc: 0.40, interior_shading_factor_summer: 0.836, interior_shading_factor_winter: 0.836 },
                                                        180 => { area: 108, ufactor: 0.35, shgc: 0.40, interior_shading_factor_summer: 0.836, interior_shading_factor_winter: 0.836 },
                                                        90 => { area: 108, ufactor: 0.35, shgc: 0.40, interior_shading_factor_summer: 0.836, interior_shading_factor_winter: 0.836 },
                                                        270 => { area: 108, ufactor: 0.35, shgc: 0.40, interior_shading_factor_summer: 0.836, interior_shading_factor_winter: 0.836 } })
      end
    end

    # Create derivative file for testing w/o operable windows
    # Rated/Reference Home windows should not be operable
    hpxml = HPXML.new(hpxml_path: File.join(@root_path, 'workflow', 'sample_files', hpxml_name))
    hpxml_bldg = hpxml.buildings[0]
    hpxml_bldg.windows.each do |window|
      window.fraction_operable = 0.0
    end
    hpxml_name = File.basename(@tmp_hpxml_path)
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)

    _test_ruleset(hpxml_name).each do |(_run_type, calc_type), hpxml_bldg|
      if [CalcType::RatedHome].include? calc_type
        _check_windows(hpxml_bldg, frac_operable: 0.0,
                                   values_by_azimuth: { 0 => { area: 35.0, ufactor: 0.35, shgc: 0.44, interior_shading_factor_summer: 0.8255, interior_shading_factor_winter: 0.8255 },
                                                        180 => { area: 35.0, ufactor: 0.35, shgc: 0.44, interior_shading_factor_summer: 0.8255, interior_shading_factor_winter: 0.8255 },
                                                        270 => { area: 53.0, ufactor: 0.35, shgc: 0.44, interior_shading_factor_summer: 0.8255, interior_shading_factor_winter: 0.8255 } })
      elsif [CalcType::ReferenceHome].include? calc_type
        _check_windows(hpxml_bldg, frac_operable: 0.0,
                                   values_by_azimuth: { 0 => { area: 35.15, ufactor: 0.35, shgc: 0.40, interior_shading_factor_summer: 0.836, interior_shading_factor_winter: 0.836 },
                                                        180 => { area: 35.15, ufactor: 0.35, shgc: 0.40, interior_shading_factor_summer: 0.836, interior_shading_factor_winter: 0.836 },
                                                        90 => { area: 35.15, ufactor: 0.35, shgc: 0.40, interior_shading_factor_summer: 0.836, interior_shading_factor_winter: 0.836 },
                                                        270 => { area: 35.15, ufactor: 0.35, shgc: 0.40, interior_shading_factor_summer: 0.836, interior_shading_factor_winter: 0.836 } })
      elsif [CalcType::IndexAdjHome].include? calc_type
        _check_windows(hpxml_bldg, frac_operable: 0.67,
                                   values_by_azimuth: { 0 => { area: 108, ufactor: 0.35, shgc: 0.44, interior_shading_factor_summer: 0.836, interior_shading_factor_winter: 0.836 },
                                                        180 => { area: 108, ufactor: 0.35, shgc: 0.44, interior_shading_factor_summer: 0.836, interior_shading_factor_winter: 0.836 },
                                                        90 => { area: 108, ufactor: 0.35, shgc: 0.44, interior_shading_factor_summer: 0.836, interior_shading_factor_winter: 0.836 },
                                                        270 => { area: 108, ufactor: 0.35, shgc: 0.44, interior_shading_factor_summer: 0.836, interior_shading_factor_winter: 0.836 } })
      elsif [CalcType::IndexAdjReferenceHome].include? calc_type
        _check_windows(hpxml_bldg, frac_operable: 0.67,
                                   values_by_azimuth: { 0 => { area: 108, ufactor: 0.35, shgc: 0.40, interior_shading_factor_summer: 0.836, interior_shading_factor_winter: 0.836 },
                                                        180 => { area: 108, ufactor: 0.35, shgc: 0.40, interior_shading_factor_summer: 0.836, interior_shading_factor_winter: 0.836 },
                                                        90 => { area: 108, ufactor: 0.35, shgc: 0.40, interior_shading_factor_summer: 0.836, interior_shading_factor_winter: 0.836 },
                                                        270 => { area: 108, ufactor: 0.35, shgc: 0.40, interior_shading_factor_summer: 0.836, interior_shading_factor_winter: 0.836 } })
      end
    end

    # But in 301-2014, the Reference Home windows are still operable
    _test_ruleset(hpxml_name, '2014').each do |(_run_type, calc_type), hpxml_bldg|
      if [CalcType::RatedHome].include? calc_type
        _check_windows(hpxml_bldg, frac_operable: 0.0,
                                   values_by_azimuth: { 0 => { area: 35.0, ufactor: 0.35, shgc: 0.44, interior_shading_factor_summer: 0.7, interior_shading_factor_winter: 0.85 },
                                                        180 => { area: 35.0, ufactor: 0.35, shgc: 0.44, interior_shading_factor_summer: 0.7, interior_shading_factor_winter: 0.85 },
                                                        270 => { area: 53.0, ufactor: 0.35, shgc: 0.44, interior_shading_factor_summer: 0.7, interior_shading_factor_winter: 0.85 } })
      elsif [CalcType::ReferenceHome].include? calc_type
        _check_windows(hpxml_bldg, frac_operable: 0.67,
                                   values_by_azimuth: { 0 => { area: 35.15, ufactor: 0.35, shgc: 0.40, interior_shading_factor_summer: 0.7, interior_shading_factor_winter: 0.85 },
                                                        180 => { area: 35.15, ufactor: 0.35, shgc: 0.40, interior_shading_factor_summer: 0.7, interior_shading_factor_winter: 0.85 },
                                                        90 => { area: 35.15, ufactor: 0.35, shgc: 0.40, interior_shading_factor_summer: 0.7, interior_shading_factor_winter: 0.85 },
                                                        270 => { area: 35.15, ufactor: 0.35, shgc: 0.40, interior_shading_factor_summer: 0.7, interior_shading_factor_winter: 0.85 } })
      elsif [CalcType::IndexAdjHome].include? calc_type
        _check_windows(hpxml_bldg, frac_operable: 0.67,
                                   values_by_azimuth: { 0 => { area: 108, ufactor: 0.35, shgc: 0.44, interior_shading_factor_summer: 0.7, interior_shading_factor_winter: 0.85 },
                                                        180 => { area: 108, ufactor: 0.35, shgc: 0.44, interior_shading_factor_summer: 0.7, interior_shading_factor_winter: 0.85 },
                                                        90 => { area: 108, ufactor: 0.35, shgc: 0.44, interior_shading_factor_summer: 0.7, interior_shading_factor_winter: 0.85 },
                                                        270 => { area: 108, ufactor: 0.35, shgc: 0.44, interior_shading_factor_summer: 0.7, interior_shading_factor_winter: 0.85 } })
      elsif [CalcType::IndexAdjReferenceHome].include? calc_type
        _check_windows(hpxml_bldg, frac_operable: 0.67,
                                   values_by_azimuth: { 0 => { area: 108, ufactor: 0.35, shgc: 0.40, interior_shading_factor_summer: 0.7, interior_shading_factor_winter: 0.85 },
                                                        180 => { area: 108, ufactor: 0.35, shgc: 0.40, interior_shading_factor_summer: 0.7, interior_shading_factor_winter: 0.85 },
                                                        90 => { area: 108, ufactor: 0.35, shgc: 0.40, interior_shading_factor_summer: 0.7, interior_shading_factor_winter: 0.85 },
                                                        270 => { area: 108, ufactor: 0.35, shgc: 0.40, interior_shading_factor_summer: 0.7, interior_shading_factor_winter: 0.85 } })
      end
    end
  end

  def test_enclosure_skylights
    hpxml_name = 'base.xml'

    _test_ruleset(hpxml_name).each do |(_run_type, _calc_type), hpxml_bldg|
      _check_skylights(hpxml_bldg)
    end

    hpxml_name = 'base-enclosure-skylights.xml'

    _test_ruleset(hpxml_name).each do |(_run_type, calc_type), hpxml_bldg|
      if [CalcType::RatedHome].include? calc_type
        _check_skylights(hpxml_bldg, values_by_azimuth: { 0 => { area: 15, ufactor: 0.59, shgc: 0.55, curb_area: 0, curb_rvalue: nil, shaft_area: 60, shaft_rvalue: 6.25 },
                                                          180 => { area: 15, ufactor: 0.59, shgc: 0.55, curb_area: 0, curb_rvalue: nil, shaft_area: 60, shaft_rvalue: 6.25 } })
      elsif [CalcType::IndexAdjHome].include? calc_type
        _check_skylights(hpxml_bldg, values_by_azimuth: { 0 => { area: 15, ufactor: 0.59, shgc: 0.55, curb_area: 0, curb_rvalue: nil, shaft_area: 60, shaft_rvalue: 6.25 },
                                                          180 => { area: 15, ufactor: 0.59, shgc: 0.55, curb_area: 0, curb_rvalue: nil, shaft_area: 60, shaft_rvalue: 6.25 } })
      else
        _check_skylights(hpxml_bldg)
      end
    end

    # Test large skylight area that would create an IAD Home error if not scaled down
    # Create derivative file for testing
    hpxml = HPXML.new(hpxml_path: File.join(@root_path, 'workflow', 'sample_files', hpxml_name))
    hpxml_bldg = hpxml.buildings[0]
    hpxml_bldg.skylights.each do |skylight|
      skylight.area = 675.0
    end
    hpxml_name = File.basename(@tmp_hpxml_path)
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)

    _test_ruleset(hpxml_name).each do |(_run_type, calc_type), hpxml_bldg|
      if [CalcType::RatedHome].include? calc_type
        _check_skylights(hpxml_bldg, values_by_azimuth: { 0 => { area: 675, ufactor: 0.59, shgc: 0.55, curb_area: 0, curb_rvalue: nil, shaft_area: 60, shaft_rvalue: 6.25 },
                                                          180 => { area: 675, ufactor: 0.59, shgc: 0.55, curb_area: 0, curb_rvalue: nil, shaft_area: 60, shaft_rvalue: 6.25 } })
      elsif [CalcType::IndexAdjHome].include? calc_type
        _check_skylights(hpxml_bldg, values_by_azimuth: { 0 => { area: 594, ufactor: 0.59, shgc: 0.55, curb_area: 0, curb_rvalue: nil, shaft_area: 52.8, shaft_rvalue: 6.25 },
                                                          180 => { area: 594, ufactor: 0.59, shgc: 0.55, curb_area: 0, curb_rvalue: nil, shaft_area: 52.8, shaft_rvalue: 6.25 } })
      else
        _check_skylights(hpxml_bldg)
      end
    end

    hpxml_name = 'base-enclosure-skylights-cathedral.xml'

    _test_ruleset(hpxml_name).each do |(_run_type, calc_type), hpxml_bldg|
      if [CalcType::RatedHome].include? calc_type
        _check_skylights(hpxml_bldg, values_by_azimuth: { 0 => { area: 15, ufactor: 0.59, shgc: 0.55, curb_area: 5.25, curb_rvalue: 1.96, shaft_area: 0, shaft_rvalue: nil },
                                                          180 => { area: 15, ufactor: 0.59, shgc: 0.55, curb_area: 5.25, curb_rvalue: 1.96, shaft_area: 0, shaft_rvalue: nil } })
      elsif [CalcType::IndexAdjHome].include? calc_type
        _check_skylights(hpxml_bldg, values_by_azimuth: { 0 => { area: 15, ufactor: 0.59, shgc: 0.55, curb_area: 5.25, curb_rvalue: 1.96, shaft_area: 0, shaft_rvalue: nil },
                                                          180 => { area: 15, ufactor: 0.59, shgc: 0.55, curb_area: 5.25, curb_rvalue: 1.96, shaft_area: 0, shaft_rvalue: nil } })
      else
        _check_skylights(hpxml_bldg)
      end
    end

    # Test large skylight area that would create an IAD Home error if not scaled down
    # Create derivative file for testing
    hpxml = HPXML.new(hpxml_path: File.join(@root_path, 'workflow', 'sample_files', hpxml_name))
    hpxml_bldg = hpxml.buildings[0]
    hpxml_bldg.skylights.each do |skylight|
      skylight.area = 675.0
    end
    hpxml_name = File.basename(@tmp_hpxml_path)
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)

    _test_ruleset(hpxml_name).each do |(_run_type, calc_type), hpxml_bldg|
      if [CalcType::RatedHome].include? calc_type
        _check_skylights(hpxml_bldg, values_by_azimuth: { 0 => { area: 675, ufactor: 0.59, shgc: 0.55, curb_area: 5.25, curb_rvalue: 1.96, shaft_area: 0, shaft_rvalue: nil },
                                                          180 => { area: 675, ufactor: 0.59, shgc: 0.55, curb_area: 5.25, curb_rvalue: 1.96, shaft_area: 0, shaft_rvalue: nil } })
      elsif [CalcType::IndexAdjHome].include? calc_type
        _check_skylights(hpxml_bldg, values_by_azimuth: { 0 => { area: 643.5, ufactor: 0.59, shgc: 0.55, curb_area: 5.0, curb_rvalue: 1.96, shaft_area: 0, shaft_rvalue: nil },
                                                          180 => { area: 643.5, ufactor: 0.59, shgc: 0.55, curb_area: 5.0, curb_rvalue: 1.96, shaft_area: 0, shaft_rvalue: nil } })
      else
        _check_skylights(hpxml_bldg)
      end
    end
  end

  def test_enclosure_overhangs
    hpxml_name = 'base.xml'

    _test_ruleset(hpxml_name).each do |(_run_type, _calc_type), hpxml_bldg|
      _check_overhangs(hpxml_bldg)
    end

    hpxml_name = 'base-enclosure-overhangs.xml'

    _test_ruleset(hpxml_name).each do |(_run_type, calc_type), hpxml_bldg|
      if [CalcType::RatedHome].include? calc_type
        _check_overhangs(hpxml_bldg, [{ depth: 1.5, top: 2, bottom: 6 },
                                      { depth: 1.5, top: 2, bottom: 6 },
                                      { depth: 0.0, top: 0, bottom: 0 },
                                      { depth: 1.5, top: 2, bottom: 6 }])
      else
        _check_overhangs(hpxml_bldg)
      end
    end
  end

  def test_enclosure_doors
    hpxml_name = 'base.xml'

    _test_ruleset(hpxml_name).each do |(_run_type, calc_type), hpxml_bldg|
      if [CalcType::RatedHome].include? calc_type
        _check_doors(hpxml_bldg, values_by_azimuth: { 180 => { area: 40, rvalue: 4.4 } })
      elsif [CalcType::ReferenceHome].include? calc_type
        _check_doors(hpxml_bldg, values_by_azimuth: { 0 => { area: 40, rvalue: 2.86 } })
      elsif [CalcType::IndexAdjHome].include? calc_type
        _check_doors(hpxml_bldg, values_by_azimuth: { 0 => { area: 40, rvalue: 4.4 } })
      elsif [CalcType::IndexAdjReferenceHome].include? calc_type
        _check_doors(hpxml_bldg, values_by_azimuth: { 0 => { area: 40, rvalue: 2.86 } })
      end
    end

    # Test door w/ southern hemisphere
    hpxml_name = 'base-location-capetown-zaf.xml'

    _test_ruleset(hpxml_name).each do |(_run_type, calc_type), hpxml_bldg|
      if [CalcType::RatedHome].include? calc_type
        _check_doors(hpxml_bldg, values_by_azimuth: { 180 => { area: 40, rvalue: 4.4 } })
      elsif [CalcType::ReferenceHome].include? calc_type
        _check_doors(hpxml_bldg, values_by_azimuth: { 180 => { area: 40, rvalue: 1.54 } })
      elsif [CalcType::IndexAdjHome].include? calc_type
        _check_doors(hpxml_bldg, values_by_azimuth: { 180 => { area: 40, rvalue: 4.4 } })
      elsif [CalcType::IndexAdjReferenceHome].include? calc_type
        _check_doors(hpxml_bldg, values_by_azimuth: { 180 => { area: 40, rvalue: 1.54 } })
      end
    end

    # Test MF unit w/ exterior and interior doors
    hpxml_name = 'base-bldgtype-mf-unit-adjacent-to-multiple.xml'

    _test_ruleset(hpxml_name).each do |(_run_type, calc_type), hpxml_bldg|
      if [CalcType::RatedHome].include? calc_type
        _check_doors(hpxml_bldg, values_by_azimuth: { 180 => { area: 20, rvalue: 4.4 } })
      elsif [CalcType::ReferenceHome].include? calc_type
        _check_doors(hpxml_bldg, values_by_azimuth: { 0 => { area: 10, rvalue: 2.86 } })
      elsif [CalcType::IndexAdjHome].include? calc_type
        _check_doors(hpxml_bldg, values_by_azimuth: { 0 => { area: 20, rvalue: 4.4 } })
      elsif [CalcType::IndexAdjReferenceHome].include? calc_type
        _check_doors(hpxml_bldg, values_by_azimuth: { 0 => { area: 20, rvalue: 2.86 } })
      end
    end
  end

  def test_enclosure_attic_ventilation
    hpxml_names = ['base.xml',
                   'base-atticroof-conditioned.xml']

    hpxml_names.each do |hpxml_name|
      _test_ruleset(hpxml_name).each do |(_run_type, calc_type), hpxml_bldg|
        if [CalcType::RatedHome].include? calc_type
          _check_attic_ventilation(hpxml_bldg)
        elsif [CalcType::ReferenceHome].include? calc_type
          _check_attic_ventilation(hpxml_bldg, sla: 1.0 / 300.0)
        elsif [CalcType::IndexAdjHome].include? calc_type
          _check_attic_ventilation(hpxml_bldg)
        elsif [CalcType::IndexAdjReferenceHome].include? calc_type
          _check_attic_ventilation(hpxml_bldg, sla: 1.0 / 300.0)
        end
      end
    end

    hpxml_names = ['base-atticroof-cathedral.xml',
                   'base-atticroof-flat.xml']

    hpxml_names.each do |hpxml_name|
      _test_ruleset(hpxml_name).each do |(_run_type, _calc_type), hpxml_bldg|
        _check_attic_ventilation(hpxml_bldg)
      end
    end

    hpxml_name = 'base-atticroof-vented.xml'

    _test_ruleset(hpxml_name).each do |(_run_type, calc_type), hpxml_bldg|
      if [CalcType::RatedHome].include? calc_type
        _check_attic_ventilation(hpxml_bldg, sla: 0.003)
      elsif [CalcType::ReferenceHome].include? calc_type
        _check_attic_ventilation(hpxml_bldg, sla: 1.0 / 300.0)
      elsif [CalcType::IndexAdjHome].include? calc_type
        _check_attic_ventilation(hpxml_bldg, sla: 0.003)
      elsif [CalcType::IndexAdjReferenceHome].include? calc_type
        _check_attic_ventilation(hpxml_bldg, sla: 1.0 / 300.0)
      end
    end
  end

  def test_enclosure_crawlspace_ventilation
    hpxml_names = ['base-foundation-unvented-crawlspace.xml',
                   'base-foundation-multiple.xml']

    hpxml_names.each do |hpxml_name|
      _test_ruleset(hpxml_name).each do |(_run_type, calc_type), hpxml_bldg|
        if [CalcType::RatedHome].include? calc_type
          _check_crawlspace_ventilation(hpxml_bldg)
        else
          _check_crawlspace_ventilation(hpxml_bldg, sla: 1.0 / 150.0)
        end
      end
    end

    hpxml_names = ['base.xml',
                   'base-foundation-slab.xml',
                   'base-foundation-unconditioned-basement.xml',
                   'base-foundation-ambient.xml']

    hpxml_names.each do |hpxml_name|
      _test_ruleset(hpxml_name).each do |(_run_type, calc_type), hpxml_bldg|
        if [CalcType::RatedHome,
            CalcType::ReferenceHome].include? calc_type
          _check_crawlspace_ventilation(hpxml_bldg)
        else
          _check_crawlspace_ventilation(hpxml_bldg, sla: 1.0 / 150.0)
        end
      end
    end

    hpxml_name = 'base-foundation-vented-crawlspace.xml'

    _test_ruleset(hpxml_name).each do |(_run_type, calc_type), hpxml_bldg|
      if [CalcType::RatedHome].include? calc_type
        _check_crawlspace_ventilation(hpxml_bldg, sla: 0.00667)
      else
        _check_crawlspace_ventilation(hpxml_bldg, sla: 1.0 / 150.0)
      end
    end
  end

  def _test_ruleset(hpxml_name, version = 'latest')
    print '.'

    designs = []
    _all_run_calc_types.each do |run_type, calc_type|
      designs << Design.new(run_type: run_type,
                            calc_type: calc_type,
                            output_dir: @sample_files_path,
                            version: version)
    end

    hpxml_input_path = File.join(@sample_files_path, hpxml_name)
    success, errors, _, _, hpxml_bldgs = run_rulesets(hpxml_input_path, designs, @schema_validator, @erivalidator)

    errors.each do |s|
      puts "Error: #{s}"
    end

    # assert that it ran correctly
    assert(success)

    # validate against OS-HPXML schematron
    designs.each do |design|
      valid = @epvalidator.validate(design.hpxml_output_path)
      puts @epvalidator.errors.map { |e| e.logMessage } unless valid
      assert(valid)
      @results_paths << File.absolute_path(File.join(File.dirname(design.hpxml_output_path), '..'))
    end

    return hpxml_bldgs
  end

  def _check_infiltration(hpxml_bldg, ach50:, height:, volume:)
    assert_equal(1, hpxml_bldg.air_infiltration_measurements.size)
    air_infiltration_measurement = hpxml_bldg.air_infiltration_measurements[0]
    assert_equal(HPXML::UnitsACH, air_infiltration_measurement.unit_of_measure)
    assert_equal(50.0, air_infiltration_measurement.house_pressure)
    assert_in_epsilon(ach50, air_infiltration_measurement.air_leakage, 0.01)
    assert_in_epsilon(height, air_infiltration_measurement.infiltration_height, 0.01)
    assert_in_epsilon(volume, air_infiltration_measurement.infiltration_volume, 0.01)
  end

  def _check_roofs(hpxml_bldg, area: nil, rvalue: nil, sabs: nil, emit: nil, rb_grade: nil)
    tot_area = 0
    rvalue_x_area_values, sabs_x_area_values, emit_x_area_values = [], [], [] # Area-weighted
    hpxml_bldg.roofs.each do |roof|
      tot_area += roof.area
      rvalue_x_area_values << roof.insulation_assembly_r_value * roof.area
      sabs_x_area_values << roof.solar_absorptance * roof.area
      emit_x_area_values << roof.emittance * roof.area
      if rb_grade.nil?
        if [HPXML::LocationAtticVented, HPXML::LocationAtticUnvented].include? roof.interior_adjacent_to
          assert_equal(false, roof.radiant_barrier)
        else
          assert_nil(roof.radiant_barrier)
        end
        assert_nil(roof.radiant_barrier_grade)
      else
        assert_equal(true, roof.radiant_barrier)
        assert_equal(rb_grade, roof.radiant_barrier_grade)
      end
    end

    if area.nil?
      assert_equal(0, tot_area)
    else
      assert_in_epsilon(area, tot_area, 0.01)
    end
    if rvalue.nil?
      assert(rvalue_x_area_values.empty?)
    else
      assert_in_epsilon(rvalue, rvalue_x_area_values.sum / tot_area, 0.01)
    end
    if sabs.nil?
      assert(sabs_x_area_values.empty?)
    else
      assert_in_epsilon(sabs, sabs_x_area_values.sum / tot_area, 0.01)
    end
    if emit.nil?
      assert(emit_x_area_values.empty?)
    else
      assert_in_epsilon(emit, emit_x_area_values.sum / tot_area, 0.01)
    end
  end

  def _check_walls(hpxml_bldg, area:, rvalue:, sabs:, emit:)
    tot_area, ext_area = 0, 0
    rvalue_x_area_values, sabs_x_area_values, emit_x_area_values = [], [], [] # Area-weighted
    hpxml_bldg.walls.each do |wall|
      tot_area += wall.area
      rvalue_x_area_values << wall.insulation_assembly_r_value * wall.area
      next unless wall.is_exterior

      ext_area += wall.area
      sabs_x_area_values << wall.solar_absorptance * wall.area
      emit_x_area_values << wall.emittance * wall.area
    end
    assert_in_epsilon(area, tot_area, 0.01)
    assert_in_epsilon(rvalue, rvalue_x_area_values.sum / tot_area, 0.01)
    assert_in_epsilon(sabs, sabs_x_area_values.sum / ext_area, 0.01)
    assert_in_epsilon(emit, emit_x_area_values.sum / ext_area, 0.01)
  end

  def _check_rim_joists(hpxml_bldg, area: nil, rvalue: nil, sabs: nil, emit: nil)
    tot_area, ext_area = 0, 0
    rvalue_x_area_values, sabs_x_area_values, emit_x_area_values = [], [], [] # Area-weighted
    hpxml_bldg.rim_joists.each do |rim_joist|
      tot_area += rim_joist.area
      rvalue_x_area_values << rim_joist.insulation_assembly_r_value * rim_joist.area
      next unless rim_joist.is_exterior

      ext_area += rim_joist.area
      sabs_x_area_values << rim_joist.solar_absorptance * rim_joist.area
      emit_x_area_values << rim_joist.emittance * rim_joist.area
    end

    if area.nil?
      assert_equal(0, tot_area)
    else
      assert_in_epsilon(area, tot_area, 0.01)
    end
    if rvalue.nil?
      assert(rvalue_x_area_values.empty?)
    else
      assert_in_epsilon(rvalue, rvalue_x_area_values.sum / tot_area, 0.01)
    end
    if sabs.nil?
      assert(sabs_x_area_values.empty?)
    else
      assert_in_epsilon(sabs, sabs_x_area_values.sum / ext_area, 0.01)
    end
    if emit.nil?
      assert(emit_x_area_values.empty?)
    else
      assert_in_epsilon(emit, emit_x_area_values.sum / ext_area, 0.01)
    end
  end

  def _check_foundation_walls(hpxml_bldg, area:, rvalue: 0, ins_top: 0, ins_bottom: 0, height:, depth_bg: 0, type: nil)
    tot_area = 0
    rvalue_x_area_values, ins_top_x_area_values, ins_bottom_x_area_values = [], [], [] # Area-weighted
    height_x_area_values, depth_bg_x_area_values = [], [] # Area-weighted
    hpxml_bldg.foundation_walls.each do |foundation_wall|
      tot_area += foundation_wall.area
      if not foundation_wall.insulation_assembly_r_value.nil?
        rvalue_x_area_values << foundation_wall.insulation_assembly_r_value * foundation_wall.area
        ins_top_x_area_values << 0.0
        ins_bottom_x_area_values << foundation_wall.height * foundation_wall.area # Total wall height applies to R-value
      end
      if not foundation_wall.insulation_interior_r_value.nil?
        rvalue_x_area_values << foundation_wall.insulation_interior_r_value * foundation_wall.area
        ins_top_x_area_values << foundation_wall.insulation_interior_distance_to_top * foundation_wall.area
        ins_bottom_x_area_values << foundation_wall.insulation_interior_distance_to_bottom * foundation_wall.area
      end
      if not foundation_wall.insulation_exterior_r_value.nil?
        rvalue_x_area_values << foundation_wall.insulation_exterior_r_value * foundation_wall.area
        ins_top_x_area_values << foundation_wall.insulation_exterior_distance_to_top * foundation_wall.area
        ins_bottom_x_area_values << foundation_wall.insulation_exterior_distance_to_bottom * foundation_wall.area
      end
      height_x_area_values << foundation_wall.height * foundation_wall.area
      depth_bg_x_area_values << foundation_wall.depth_below_grade * foundation_wall.area
      if type.nil?
        assert_nil(foundation_wall.type)
      else
        assert_equal(type, foundation_wall.type)
      end
    end

    assert_in_epsilon(area, tot_area, 0.01)
    assert_in_epsilon(rvalue, rvalue_x_area_values.sum / tot_area, 0.01)
    assert_in_epsilon(ins_top, ins_top_x_area_values.sum / tot_area, 0.01)
    assert_in_epsilon(ins_bottom, ins_bottom_x_area_values.sum / tot_area, 0.01)
    assert_in_epsilon(height, height_x_area_values.sum / tot_area, 0.01)
    assert_in_epsilon(depth_bg, depth_bg_x_area_values.sum / tot_area, 0.01)
  end

  def _check_ceilings(hpxml_bldg, area:, rvalue:, floor_type: HPXML::FloorTypeWoodFrame)
    tot_area = 0
    rvalue_x_area_values = [] # Area-weighted
    hpxml_bldg.floors.each do |floor|
      next unless floor.is_ceiling

      tot_area += floor.area
      rvalue_x_area_values << floor.insulation_assembly_r_value * floor.area
      assert_equal(floor_type, floor.floor_type)
    end

    assert_in_epsilon(area, tot_area, 0.01)
    assert_in_epsilon(rvalue, rvalue_x_area_values.sum / tot_area, 0.01)
  end

  def _check_floors(hpxml_bldg, area:, rvalue:, floor_type: HPXML::FloorTypeWoodFrame)
    tot_area = 0
    rvalue_x_area_values = [] # Area-weighted
    hpxml_bldg.floors.each do |floor|
      next unless floor.is_floor

      tot_area += floor.area
      rvalue_x_area_values << floor.insulation_assembly_r_value * floor.area
      assert_equal(floor_type, floor.floor_type)
    end

    assert_in_epsilon(area, tot_area, 0.01)
    assert_in_epsilon(rvalue, rvalue_x_area_values.sum / tot_area, 0.01)
  end

  def _check_slabs(hpxml_bldg, area:, exp_perim:, perim_ins_depth: 0, perim_ins_r: 0, under_ins_width: 0,
                   under_ins_r: 0, depth_below_grade: nil, gap_ins_r: 0)
    tot_area = 0
    exp_perim_x_area_values, perim_ins_depth_x_area_values, perim_ins_r_x_area_values = [], [], [] # Area-weighted
    under_ins_width_x_area_values, under_ins_r_x_area_values, depth_bg_x_area_values = [], [], [] # Area-weighted
    gap_ins_r_x_area_values = [] # Area-weighted
    hpxml_bldg.slabs.each do |slab|
      tot_area += slab.area
      exp_perim_x_area_values << slab.exposed_perimeter * slab.area
      perim_ins_depth_x_area_values << slab.perimeter_insulation_depth * slab.area
      perim_ins_r_x_area_values << slab.perimeter_insulation_r_value * slab.area
      if not slab.under_slab_insulation_width.nil?
        under_ins_width_x_area_values << slab.under_slab_insulation_width * slab.area
      elsif slab.under_slab_insulation_spans_entire_slab
        under_ins_width_x_area_values << 999 * slab.area
      end
      under_ins_r_x_area_values << slab.under_slab_insulation_r_value * slab.area
      if not slab.depth_below_grade.nil?
        depth_bg_x_area_values << slab.depth_below_grade * slab.area
      end
      gap_ins_r_x_area_values << slab.gap_insulation_r_value * slab.area
    end

    assert_in_epsilon(area, tot_area, 0.01)
    assert_in_epsilon(exp_perim, exp_perim_x_area_values.sum / tot_area, 0.01)
    assert_in_epsilon(perim_ins_depth, perim_ins_depth_x_area_values.sum / tot_area, 0.01)
    assert_in_epsilon(perim_ins_r, perim_ins_r_x_area_values.sum / tot_area, 0.01)
    assert_in_epsilon(under_ins_width, under_ins_width_x_area_values.sum / tot_area, 0.01)
    assert_in_epsilon(under_ins_r, under_ins_r_x_area_values.sum / tot_area, 0.01)
    assert_in_epsilon(gap_ins_r, gap_ins_r_x_area_values.sum / tot_area, 0.01)
    if depth_below_grade.nil?
      assert(depth_bg_x_area_values.empty?)
    else
      assert_in_epsilon(depth_below_grade, depth_bg_x_area_values.sum / tot_area, 0.01)
    end
  end

  def _check_windows(hpxml_bldg, frac_operable:, values_by_azimuth: {})
    tot_area, operable_area = 0, 0
    azimuth_area_values = {}
    azimuth_ufactor_x_area_values, azimuth_shgc_x_area_values = {}, {} # Area-weighted
    azimuth_interior_shading_factor_summer_x_area_values, azimuth_interior_shading_factor_winter_x_area_values = {}, {} # Area-weighted
    hpxml_bldg.windows.each do |window|
      tot_area += window.area
      operable_area += (window.area * window.fraction_operable)

      # Init if needed
      azimuth_area_values[window.azimuth] = [] if azimuth_area_values[window.azimuth].nil?
      azimuth_ufactor_x_area_values[window.azimuth] = [] if azimuth_ufactor_x_area_values[window.azimuth].nil?
      azimuth_shgc_x_area_values[window.azimuth] = [] if azimuth_shgc_x_area_values[window.azimuth].nil?
      azimuth_interior_shading_factor_summer_x_area_values[window.azimuth] = [] if azimuth_interior_shading_factor_summer_x_area_values[window.azimuth].nil?
      azimuth_interior_shading_factor_winter_x_area_values[window.azimuth] = [] if azimuth_interior_shading_factor_winter_x_area_values[window.azimuth].nil?

      # Update
      azimuth_area_values[window.azimuth] << window.area
      azimuth_ufactor_x_area_values[window.azimuth] << window.ufactor * window.area
      azimuth_shgc_x_area_values[window.azimuth] << window.shgc * window.area
      azimuth_interior_shading_factor_summer_x_area_values[window.azimuth] << window.interior_shading_factor_summer * window.area
      azimuth_interior_shading_factor_winter_x_area_values[window.azimuth] << window.interior_shading_factor_winter * window.area
    end

    assert_equal(values_by_azimuth.keys.size, azimuth_area_values.size)
    assert_equal(values_by_azimuth.keys.size, azimuth_ufactor_x_area_values.size)
    assert_equal(values_by_azimuth.keys.size, azimuth_shgc_x_area_values.size)
    assert_equal(values_by_azimuth.keys.size, azimuth_interior_shading_factor_summer_x_area_values.size)
    assert_equal(values_by_azimuth.keys.size, azimuth_interior_shading_factor_winter_x_area_values.size)

    assert_in_epsilon(frac_operable, operable_area / tot_area, 0.01)

    values_by_azimuth.each do |azimuth, values|
      assert_in_epsilon(values[:area], azimuth_area_values[azimuth].sum, 0.01)
      assert_in_epsilon(values[:ufactor], azimuth_ufactor_x_area_values[azimuth].sum / azimuth_area_values[azimuth].sum, 0.01)
      assert_in_epsilon(values[:shgc], azimuth_shgc_x_area_values[azimuth].sum / azimuth_area_values[azimuth].sum, 0.01)
      assert_in_epsilon(values[:interior_shading_factor_summer], azimuth_interior_shading_factor_summer_x_area_values[azimuth].sum / azimuth_area_values[azimuth].sum, 0.01)
      assert_in_epsilon(values[:interior_shading_factor_winter], azimuth_interior_shading_factor_winter_x_area_values[azimuth].sum / azimuth_area_values[azimuth].sum, 0.01)
    end
  end

  def _check_overhangs(hpxml_bldg, all_expected_values = [])
    num_overhangs = 0
    hpxml_bldg.windows.each do |window|
      next if window.overhangs_depth.nil?

      expected_values = all_expected_values[num_overhangs]
      assert_equal(expected_values[:depth], window.overhangs_depth)
      assert_equal(expected_values[:top], window.overhangs_distance_to_top_of_window)
      assert_equal(expected_values[:bottom], window.overhangs_distance_to_bottom_of_window)
      num_overhangs += 1
    end
    assert_equal(all_expected_values.size, num_overhangs)
  end

  def _check_skylights(hpxml_bldg, values_by_azimuth: {})
    azimuth_area_values, azimuth_curb_area_values, azimuth_shaft_area_values = {}, {}, {}
    azimuth_ufactor_x_area_values, azimuth_shgc_x_area_values = {}, {} # Area-weighted
    azimuth_curb_rvalue_x_area_values, azimuth_shaft_rvalue_x_area_values = {}, {} # Area-weighted
    hpxml_bldg.skylights.each do |skylight|
      # Init if needed
      azimuth_area_values[skylight.azimuth] = [] if azimuth_area_values[skylight.azimuth].nil?
      azimuth_curb_area_values[skylight.azimuth] = [] if azimuth_curb_area_values[skylight.azimuth].nil?
      azimuth_shaft_area_values[skylight.azimuth] = [] if azimuth_shaft_area_values[skylight.azimuth].nil?
      azimuth_ufactor_x_area_values[skylight.azimuth] = [] if azimuth_ufactor_x_area_values[skylight.azimuth].nil?
      azimuth_shgc_x_area_values[skylight.azimuth] = [] if azimuth_shgc_x_area_values[skylight.azimuth].nil?
      azimuth_curb_rvalue_x_area_values[skylight.azimuth] = [] if azimuth_curb_rvalue_x_area_values[skylight.azimuth].nil?
      azimuth_shaft_rvalue_x_area_values[skylight.azimuth] = [] if azimuth_shaft_rvalue_x_area_values[skylight.azimuth].nil?

      # Update
      azimuth_area_values[skylight.azimuth] << skylight.area
      azimuth_curb_area_values[skylight.azimuth] << skylight.curb_area.to_f
      azimuth_shaft_area_values[skylight.azimuth] << skylight.shaft_area.to_f
      azimuth_ufactor_x_area_values[skylight.azimuth] << skylight.ufactor * skylight.area
      azimuth_shgc_x_area_values[skylight.azimuth] << skylight.shgc * skylight.area
      azimuth_curb_rvalue_x_area_values[skylight.azimuth] << skylight.curb_assembly_r_value.to_f * skylight.curb_area.to_f
      azimuth_shaft_rvalue_x_area_values[skylight.azimuth] << skylight.shaft_assembly_r_value.to_f * skylight.shaft_area.to_f
    end

    assert_equal(values_by_azimuth.keys.size, azimuth_area_values.size)
    assert_equal(values_by_azimuth.keys.size, azimuth_curb_area_values.size)
    assert_equal(values_by_azimuth.keys.size, azimuth_shaft_area_values.size)
    assert_equal(values_by_azimuth.keys.size, azimuth_ufactor_x_area_values.size)
    assert_equal(values_by_azimuth.keys.size, azimuth_shgc_x_area_values.size)
    assert_equal(values_by_azimuth.keys.size, azimuth_curb_rvalue_x_area_values.size)
    assert_equal(values_by_azimuth.keys.size, azimuth_shaft_rvalue_x_area_values.size)

    values_by_azimuth.each do |azimuth, values|
      assert_in_epsilon(values[:area], azimuth_area_values[azimuth].sum, 0.01)
      assert_in_epsilon(values[:curb_area], azimuth_curb_area_values[azimuth].sum, 0.01)
      assert_in_epsilon(values[:shaft_area], azimuth_shaft_area_values[azimuth].sum, 0.01)
      assert_in_epsilon(values[:ufactor], azimuth_ufactor_x_area_values[azimuth].sum / azimuth_area_values[azimuth].sum, 0.01)
      assert_in_epsilon(values[:shgc], azimuth_shgc_x_area_values[azimuth].sum / azimuth_area_values[azimuth].sum, 0.01)
      if azimuth_curb_area_values[azimuth].sum > 0
        assert_in_epsilon(values[:curb_rvalue], azimuth_curb_rvalue_x_area_values[azimuth].sum / azimuth_curb_area_values[azimuth].sum, 0.01)
      else
        assert_nil(values[:curb_rvalue])
      end
      if azimuth_shaft_area_values[azimuth].sum > 0
        assert_in_epsilon(values[:shaft_rvalue], azimuth_shaft_rvalue_x_area_values[azimuth].sum / azimuth_shaft_area_values[azimuth].sum, 0.01)
      else
        assert_nil(values[:shaft_rvalue])
      end
    end
  end

  def _check_doors(hpxml_bldg, values_by_azimuth: {})
    azimuth_area_values = {}
    azimuth_rvalue_x_area_values = {} # Area-weighted
    hpxml_bldg.doors.each do |door|
      next unless door.is_exterior_thermal_boundary

      # Init if needed
      azimuth_area_values[door.azimuth] = [] if azimuth_area_values[door.azimuth].nil?
      azimuth_rvalue_x_area_values[door.azimuth] = [] if azimuth_rvalue_x_area_values[door.azimuth].nil?

      # Update
      azimuth_area_values[door.azimuth] << door.area
      azimuth_rvalue_x_area_values[door.azimuth] << door.r_value * door.area
    end

    assert_equal(values_by_azimuth.keys.size, azimuth_area_values.size)
    assert_equal(values_by_azimuth.keys.size, azimuth_rvalue_x_area_values.size)

    values_by_azimuth.each do |azimuth, values|
      assert_in_epsilon(values[:area], azimuth_area_values[azimuth].sum, 0.01)
      assert_in_epsilon(values[:rvalue], azimuth_rvalue_x_area_values[azimuth].sum / azimuth_area_values[azimuth].sum, 0.01)
    end
  end

  def _check_attic_ventilation(hpxml_bldg, sla: nil)
    attic_sla = nil
    hpxml_bldg.attics.each do |attic|
      next unless attic.attic_type == HPXML::AtticTypeVented

      attic_sla = attic.vented_attic_sla
    end
    if sla.nil?
      assert_nil(attic_sla)
    else
      assert_in_epsilon(sla, attic_sla, 0.01)
    end
  end

  def _check_crawlspace_ventilation(hpxml_bldg, sla: nil)
    crawl_sla = nil
    hpxml_bldg.foundations.each do |foundation|
      next unless foundation.foundation_type == HPXML::FoundationTypeCrawlspaceVented

      crawl_sla = foundation.vented_crawlspace_sla
    end
    if sla.nil?
      assert_nil(crawl_sla)
    else
      assert_in_epsilon(sla, crawl_sla, 0.01)
    end
  end
end
