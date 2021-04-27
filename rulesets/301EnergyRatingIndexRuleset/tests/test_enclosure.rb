# frozen_string_literal: true

require_relative '../../../hpxml-measures/HPXMLtoOpenStudio/resources/minitest_helper'
require 'openstudio'
require 'openstudio/measure/ShowRunnerOutput'
require_relative '../measure.rb'
require 'fileutils'
require_relative 'util.rb'

class ERIEnclosureTest < MiniTest::Test
  def setup
    @root_path = File.absolute_path(File.join(File.dirname(__FILE__), '..', '..', '..'))
    @tmp_hpxml_path = File.join(@root_path, 'workflow', 'sample_files', 'tmp.xml')
  end

  def teardown
    File.delete(@tmp_hpxml_path) if File.exist? @tmp_hpxml_path
  end

  def test_enclosure_infiltration
    # Test w/o mech vent
    hpxml_name = 'base.xml'

    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_infiltration(hpxml, ach50: 9.3)
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_infiltration(hpxml, ach50: 7.09)
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentDesign)
    _check_infiltration(hpxml, ach50: 3.0)
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentReferenceHome)
    _check_infiltration(hpxml, ach50: 6.67)

    # Test w/ mech vent
    hpxml_name = 'base-mechvent-exhaust.xml'

    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_infiltration(hpxml, ach50: 3.0)
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_infiltration(hpxml, ach50: 7.09)
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentDesign)
    _check_infiltration(hpxml, ach50: 3.0)
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentReferenceHome)
    _check_infiltration(hpxml, ach50: 6.67)

    # Test w/ unmeasured mech vent
    # Create derivative file for testing
    hpxml_name = 'base-mechvent-exhaust.xml'
    hpxml = HPXML.new(hpxml_path: File.join(@root_path, 'workflow', 'sample_files', hpxml_name))
    vent_fan = hpxml.ventilation_fans.select { |vf| vf.used_for_whole_building_ventilation }[0]
    vent_fan.tested_flow_rate = nil
    vent_fan.flow_rate_not_tested = true
    vent_fan.hours_in_operation = 1
    vent_fan.fan_power = 1.0
    hpxml_name = File.basename(@tmp_hpxml_path)
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)

    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_infiltration(hpxml, ach50: 9.3) # 0.3 nACH
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_infiltration(hpxml, ach50: 7.09)
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentDesign)
    _check_infiltration(hpxml, ach50: 3.0)
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentReferenceHome)
    _check_infiltration(hpxml, ach50: 6.67)

    # Test attached dwelling where airtightness test results <= 0.30 cfm50 per ft2 of Compartmentalization Boundary
    # Create derivative file for testing
    hpxml_name = 'base-bldgtype-multifamily.xml'
    hpxml = HPXML.new(hpxml_path: File.join(@root_path, 'workflow', 'sample_files', hpxml_name))
    hpxml.ventilation_fans.add(id: 'MechanicalVentilation',
                               fan_type: HPXML::MechVentTypeSupply,
                               tested_flow_rate: 110.0,
                               hours_in_operation: 24.0,
                               used_for_whole_building_ventilation: true,
                               fan_power: 30.0,
                               is_shared_system: false)
    hpxml_name = File.basename(@tmp_hpxml_path)
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)

    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_infiltration(hpxml, ach50: 0.74)
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_infiltration(hpxml, ach50: 7.09)
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentDesign)
    _check_infiltration(hpxml, ach50: 3.0)
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentReferenceHome)
    _check_infiltration(hpxml, ach50: 6.67)

    # Test attached dwelling where Aext < 0.5 and exhaust mech vent
    # Create derivative file for testing
    hpxml_name = 'base-bldgtype-multifamily.xml'
    hpxml = HPXML.new(hpxml_path: File.join(@root_path, 'workflow', 'sample_files', hpxml_name))
    hpxml.ventilation_fans.add(id: 'MechanicalVentilation',
                               fan_type: HPXML::MechVentTypeExhaust,
                               tested_flow_rate: 110.0,
                               hours_in_operation: 24.0,
                               used_for_whole_building_ventilation: true,
                               fan_power: 30.0,
                               is_shared_system: false)
    hpxml_name = File.basename(@tmp_hpxml_path)
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)

    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_infiltration(hpxml, ach50: 10.1)
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_infiltration(hpxml, ach50: 7.09)
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentDesign)
    _check_infiltration(hpxml, ach50: 3.0)
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentReferenceHome)
    _check_infiltration(hpxml, ach50: 6.67)

    # TODO: Add 301-2014 tests
    # TODO: Add tests for new 301-2019 space types HPXML file
  end

  def test_enclosure_roofs
    hpxml_name = 'base.xml'

    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_roofs(hpxml, area: 1510, rvalue: 2.3, sabs: 0.7, emit: 0.92)
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_roofs(hpxml, area: 1510, rvalue: 2.3, sabs: 0.75, emit: 0.9)
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentDesign)
    _check_roofs(hpxml, area: 1300, rvalue: 2.3, sabs: 0.7, emit: 0.92)
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentReferenceHome)
    _check_roofs(hpxml, area: 1300, rvalue: 2.3, sabs: 0.75, emit: 0.9)

    hpxml_name = 'base-atticroof-cathedral.xml'

    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_roofs(hpxml, area: 1510, rvalue: 25.8, sabs: 0.7, emit: 0.92)
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_roofs(hpxml, area: 1510, rvalue: 33.33, sabs: 0.75, emit: 0.9)
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentDesign)
    _check_roofs(hpxml, area: 1300, rvalue: 25.8, sabs: 0.7, emit: 0.92)
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentReferenceHome)
    _check_roofs(hpxml, area: 1300, rvalue: 33.33, sabs: 0.75, emit: 0.9)

    hpxml_name = 'base-atticroof-conditioned.xml'

    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_roofs(hpxml, area: 1510, rvalue: (25.8 * 1006 + 2.3 * 504) / 1510, sabs: 0.7, emit: 0.92)
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_roofs(hpxml, area: 1510, rvalue: (33.33 * 1006 + 2.3 * 504) / 1510, sabs: 0.75, emit: 0.9)
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentDesign)
    _check_roofs(hpxml, area: 1300, rvalue: (25.8 * 1006 + 2.3 * 504) / 1510, sabs: 0.7, emit: 0.92)
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentReferenceHome)
    _check_roofs(hpxml, area: 1300, rvalue: (33.33 * 1006 + 2.3 * 504) / 1510, sabs: 0.75, emit: 0.9)

    hpxml_name = 'base-atticroof-unvented-insulated-roof.xml'

    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_roofs(hpxml, area: 1510, rvalue: 25.8, sabs: 0.7, emit: 0.92)
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_roofs(hpxml, area: 1510, rvalue: 2.3, sabs: 0.75, emit: 0.9)
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentDesign)
    _check_roofs(hpxml, area: 1300, rvalue: 25.8, sabs: 0.7, emit: 0.92)
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentReferenceHome)
    _check_roofs(hpxml, area: 1300, rvalue: 2.3, sabs: 0.75, emit: 0.9)

    hpxml_name = 'base-atticroof-flat.xml'

    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_roofs(hpxml, area: 1350, rvalue: 25.8, sabs: 0.7, emit: 0.92)
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_roofs(hpxml, area: 1350, rvalue: 33.33, sabs: 0.75, emit: 0.9)
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentDesign)
    _check_roofs(hpxml, area: 1300, rvalue: 25.8, sabs: 0.7, emit: 0.92)
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentReferenceHome)
    _check_roofs(hpxml, area: 1300, rvalue: 33.33, sabs: 0.75, emit: 0.9)

    hpxml_name = 'base-bldgtype-multifamily.xml'

    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_roofs(hpxml)
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_roofs(hpxml)
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentDesign)
    _check_roofs(hpxml)
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentReferenceHome)
    _check_roofs(hpxml)

    hpxml_name = 'base-atticroof-radiant-barrier.xml'

    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_roofs(hpxml, area: 1510, rvalue: 2.3, sabs: 0.7, emit: 0.92, rb_grade: 2)
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_roofs(hpxml, area: 1510, rvalue: 2.3, sabs: 0.75, emit: 0.9)
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentDesign)
    _check_roofs(hpxml, area: 1300, rvalue: 2.3, sabs: 0.7, emit: 0.92, rb_grade: 2)
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentReferenceHome)
    _check_roofs(hpxml, area: 1300, rvalue: 2.3, sabs: 0.75, emit: 0.9)
  end

  def test_enclosure_walls
    hpxml_name = 'base.xml'

    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_walls(hpxml, area: 1490, rvalue: (23.0 * 1200 + 4.0 * 290) / 1490, sabs: 0.7, emit: 0.92)
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_walls(hpxml, area: 1490, rvalue: (16.67 * 1200 + 4.0 * 290) / 1490, sabs: 0.75, emit: 0.9)
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentDesign)
    _check_walls(hpxml, area: 2355.52, rvalue: 23.0, sabs: 0.7, emit: 0.92)
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentReferenceHome)
    _check_walls(hpxml, area: 2355.52, rvalue: 16.67, sabs: 0.75, emit: 0.9)

    hpxml_name = 'base-atticroof-conditioned.xml'

    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_walls(hpxml, area: 1806, rvalue: (23.0 * 1516 + 22.3 * 240 + 4.0 * 50) / 1806, sabs: 0.7, emit: 0.92)
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_walls(hpxml, area: 1806, rvalue: (16.67 * 1756 + 4.0 * 50) / 1806, sabs: 0.75, emit: 0.9)
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentDesign)
    _check_walls(hpxml, area: 2355.52, rvalue: (23.0 * 1200 + 22.3 * 240) / 1440, sabs: 0.7, emit: 0.92)
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentReferenceHome)
    _check_walls(hpxml, area: 2355.52, rvalue: 16.67, sabs: 0.75, emit: 0.9)

    hpxml_name = 'base-bldgtype-multifamily.xml'

    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_walls(hpxml, area: 980, rvalue: (23.0 * 686 + 4.0 * 294) / 980, sabs: 0.7, emit: 0.92)
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_walls(hpxml, area: 980, rvalue: (16.67 * 686 + 4.0 * 294) / 980, sabs: 0.75, emit: 0.9)
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentDesign)
    _check_walls(hpxml, area: 2355.52, rvalue: 23.0, sabs: 0.7, emit: 0.92)
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentReferenceHome)
    _check_walls(hpxml, area: 2355.52, rvalue: 16.67, sabs: 0.75, emit: 0.9)

    hpxml_name = 'base-bldgtype-multifamily-adjacent-to-multiple.xml'

    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_walls(hpxml, area: 1086, rvalue: (23.0 * 986 + 4.0 * 100) / 1086, sabs: 0.7, emit: 0.92)
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_walls(hpxml, area: 1086, rvalue: (16.67 * 986 + 4.0 * 100) / 1086, sabs: 0.75, emit: 0.9)
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentDesign)
    _check_walls(hpxml, area: 2355.52, rvalue: 23.0, sabs: 0.7, emit: 0.92)
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentReferenceHome)
    _check_walls(hpxml, area: 2355.52, rvalue: 16.67, sabs: 0.75, emit: 0.9)

    hpxml_name = 'base-enclosure-garage.xml'

    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_walls(hpxml, area: 1873, rvalue: (23.0 * 1200 + 4.0 * 673) / 1873, sabs: 0.7, emit: 0.92)
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_walls(hpxml, area: 1873, rvalue: (16.67 * 1200 + 4.0 * 673) / 1873, sabs: 0.75, emit: 0.9)
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentDesign)
    _check_walls(hpxml, area: 2355.52, rvalue: 23.0, sabs: 0.7, emit: 0.92)
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentReferenceHome)
    _check_walls(hpxml, area: 2355.52, rvalue: 16.67, sabs: 0.75, emit: 0.9)
  end

  def test_enclosure_rim_joists
    hpxml_name = 'base.xml'

    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_rim_joists(hpxml, area: 116, rvalue: 23.0, sabs: 0.7, emit: 0.92)
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_rim_joists(hpxml, area: 116, rvalue: 16.67, sabs: 0.75, emit: 0.9)
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentDesign)
    _check_rim_joists(hpxml)
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentReferenceHome)
    _check_rim_joists(hpxml)

    hpxml_name = 'base-foundation-multiple.xml'

    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_rim_joists(hpxml, area: 197, rvalue: 2.3, sabs: 0.7, emit: 0.92)
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_rim_joists(hpxml, area: 197, rvalue: 2.3, sabs: 0.75, emit: 0.9)
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentDesign)
    _check_rim_joists(hpxml)
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentReferenceHome)
    _check_rim_joists(hpxml)
  end

  def test_enclosure_foundation_walls
    hpxml_name = 'base.xml'

    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_foundation_walls(hpxml, area: 1200, rvalue: 8.9, ins_bottom: 8, height: 8, depth_bg: 7)
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_foundation_walls(hpxml, area: 1200, rvalue: 10.0, ins_bottom: 8, height: 8, depth_bg: 7)
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentDesign)
    _check_foundation_walls(hpxml, area: 277.12, height: 2)
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentReferenceHome)
    _check_foundation_walls(hpxml, area: 277.12, height: 2)

    hpxml_name = 'base-foundation-conditioned-basement-wall-interior-insulation.xml'

    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_foundation_walls(hpxml, area: 1200, rvalue: 18.9, ins_top: 1, ins_bottom: 16, height: 8, depth_bg: 7)
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_foundation_walls(hpxml, area: 1200, rvalue: 10.0, ins_bottom: 8, height: 8, depth_bg: 7)
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentDesign)
    _check_foundation_walls(hpxml, area: 277.12, height: 2)
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentReferenceHome)
    _check_foundation_walls(hpxml, area: 277.12, height: 2)

    hpxml_name = 'base-foundation-unconditioned-basement.xml'

    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_foundation_walls(hpxml, area: 1200, height: 8, depth_bg: 7)
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_foundation_walls(hpxml, area: 1200, height: 8, depth_bg: 7)
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentDesign)
    _check_foundation_walls(hpxml, area: 277.12, height: 2)
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentReferenceHome)
    _check_foundation_walls(hpxml, area: 277.12, height: 2)

    hpxml_names = ['base-foundation-unvented-crawlspace.xml',
                   'base-foundation-vented-crawlspace.xml']

    hpxml_names.each do |hpxml_name|
      hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
      _check_foundation_walls(hpxml, area: 600, rvalue: 8.9, ins_bottom: 4, height: 4, depth_bg: 3)
      hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
      _check_foundation_walls(hpxml, area: 600, height: 4, depth_bg: 3)
      hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentDesign)
      _check_foundation_walls(hpxml, area: 277.12, height: 2)
      hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentReferenceHome)
      _check_foundation_walls(hpxml, area: 277.12, height: 2)
    end
  end

  def test_enclosure_floors
    hpxml_name = 'base.xml'

    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_floors(hpxml, area: 1350, rvalue: 39.3)
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_floors(hpxml, area: 1350, rvalue: 33.33)
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentDesign)
    _check_floors(hpxml, area: 2400, rvalue: (39.3 * 1200 + 30.3 * 1200) / 2400)
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentReferenceHome)
    _check_floors(hpxml, area: 2400, rvalue: (33.33 * 1200 + 30.3 * 1200) / 2400)

    hpxml_name = 'base-foundation-ambient.xml'

    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_floors(hpxml, area: 2700, rvalue: (39.3 * 1350 + 18.7 * 1350) / 2700)
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_floors(hpxml, area: 2700, rvalue: (33.33 * 1350 + 30.3 * 1350) / 2700)
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentDesign)
    _check_floors(hpxml, area: 2400, rvalue: (39.3 * 1200 + 30.3 * 1200) / 2400)
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentReferenceHome)
    _check_floors(hpxml, area: 2400, rvalue: (33.33 * 1200 + 30.3 * 1200) / 2400)

    hpxml_name = 'base-enclosure-garage.xml'

    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_floors(hpxml, area: 1950, rvalue: (39.3 * 1350 + 2.1 * 600) / 1950)
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_floors(hpxml, area: 1950, rvalue: (33.33 * 1350 + 2.1 * 600) / 1950)
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentDesign)
    _check_floors(hpxml, area: 2400, rvalue: (39.3 * 1200 + 30.3 * 1200) / 2400)
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentReferenceHome)
    _check_floors(hpxml, area: 2400, rvalue: (33.33 * 1200 + 30.3 * 1200) / 2400)

    hpxml_name = 'base-foundation-unconditioned-basement.xml'

    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_floors(hpxml, area: 2700, rvalue: (39.3 * 1350 + 18.7 * 1350) / 2700)
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_floors(hpxml, area: 2700, rvalue: (33.33 * 1350 + 30.3 * 1350) / 2700)
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentDesign)
    _check_floors(hpxml, area: 2400, rvalue: (39.3 * 1200 + 30.3 * 1200) / 2400)
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentReferenceHome)
    _check_floors(hpxml, area: 2400, rvalue: (33.33 * 1200 + 30.3 * 1200) / 2400)

    hpxml_name = 'base-bldgtype-multifamily.xml'

    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_floors(hpxml, area: 1800, rvalue: 2.1)
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_floors(hpxml, area: 1800, rvalue: 2.1)
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentDesign)
    _check_floors(hpxml, area: 2400, rvalue: (2.1 * 1200 + 30.3 * 1200) / 2400)
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentReferenceHome)
    _check_floors(hpxml, area: 2400, rvalue: (2.1 * 1200 + 30.3 * 1200) / 2400)

    hpxml_name = ['base-bldgtype-multifamily-adjacent-to-multiple.xml']

    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_floors(hpxml, area: 1800, rvalue: (18.7 * 750 + 2.1 * 1050) / 1800)
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_floors(hpxml, area: 1800, rvalue: (30.3 * 900 + 2.1 * 900) / 1800)
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentDesign)
    _check_floors(hpxml, area: 2400, rvalue: (2.1 * 1200 + 30.3 * 1200) / 2400)
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentReferenceHome)
    _check_floors(hpxml, area: 2400, rvalue: (2.1 * 1200 + 30.3 * 1200) / 2400)
  end

  def test_enclosure_slabs
    hpxml_name = 'base.xml'

    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_slabs(hpxml, area: 1350, exp_perim: 150)
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_slabs(hpxml, area: 1350, exp_perim: 150)
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentDesign)
    _check_slabs(hpxml, area: 1200, exp_perim: 138.6)
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentReferenceHome)
    _check_slabs(hpxml, area: 1200, exp_perim: 138.6)

    hpxml_name = 'base-foundation-slab.xml'

    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_slabs(hpxml, area: 1350, exp_perim: 150, under_ins_width: 999, under_ins_r: 5, depth_below_grade: 0)
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_slabs(hpxml, area: 1350, exp_perim: 150, perim_ins_depth: 2, perim_ins_r: 10, depth_below_grade: 0)
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentDesign)
    _check_slabs(hpxml, area: 1200, exp_perim: 138.6)
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentReferenceHome)
    _check_slabs(hpxml, area: 1200, exp_perim: 138.6)

    hpxml_name = 'base-foundation-conditioned-basement-slab-insulation.xml'

    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_slabs(hpxml, area: 1350, exp_perim: 150, under_ins_width: 4, under_ins_r: 10)
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_slabs(hpxml, area: 1350, exp_perim: 150)
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentDesign)
    _check_slabs(hpxml, area: 1200, exp_perim: 138.6)
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentReferenceHome)
    _check_slabs(hpxml, area: 1200, exp_perim: 138.6)
  end

  def test_enclosure_windows
    hpxml_names = ['base.xml',
                   'base-atticroof-flat.xml',
                   'base-atticroof-vented.xml']

    hpxml_names.each do |hpxml_name|
      hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
      _check_windows(hpxml, frac_operable: 0.67,
                            values_by_azimuth: { 0 => { area: 108, ufactor: 0.33, shgc: 0.45 },
                                                 180 => { area: 108, ufactor: 0.33, shgc: 0.45 },
                                                 90 => { area: 72, ufactor: 0.33, shgc: 0.45 },
                                                 270 => { area: 72, ufactor: 0.33, shgc: 0.45 } })
      hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
      _check_windows(hpxml, frac_operable: 0.67,
                            values_by_azimuth: { 0 => { area: 89.5, ufactor: 0.35, shgc: 0.40 },
                                                 180 => { area: 89.5, ufactor: 0.35, shgc: 0.40 },
                                                 90 => { area: 89.5, ufactor: 0.35, shgc: 0.40 },
                                                 270 => { area: 89.5, ufactor: 0.35, shgc: 0.40 } })
      hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentDesign)
      _check_windows(hpxml, frac_operable: 0.67,
                            values_by_azimuth: { 0 => { area: 108, ufactor: 0.33, shgc: 0.45 },
                                                 180 => { area: 108, ufactor: 0.33, shgc: 0.45 },
                                                 90 => { area: 108, ufactor: 0.33, shgc: 0.45 },
                                                 270 => { area: 108, ufactor: 0.33, shgc: 0.45 } })
      hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentReferenceHome)
      _check_windows(hpxml, frac_operable: 0.67,
                            values_by_azimuth: { 0 => { area: 108, ufactor: 0.35, shgc: 0.40 },
                                                 180 => { area: 108, ufactor: 0.35, shgc: 0.40 },
                                                 90 => { area: 108, ufactor: 0.35, shgc: 0.40 },
                                                 270 => { area: 108, ufactor: 0.35, shgc: 0.40 } })
    end

    hpxml_names = ['base-foundation-ambient.xml',
                   'base-foundation-slab.xml',
                   'base-foundation-unconditioned-basement.xml',
                   'base-foundation-unvented-crawlspace.xml',
                   'base-foundation-vented-crawlspace.xml']

    hpxml_names.each do |hpxml_name|
      hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
      _check_windows(hpxml, frac_operable: 0.67,
                            values_by_azimuth: { 0 => { area: 108, ufactor: 0.33, shgc: 0.45 },
                                                 180 => { area: 108, ufactor: 0.33, shgc: 0.45 },
                                                 90 => { area: 72, ufactor: 0.33, shgc: 0.45 },
                                                 270 => { area: 72, ufactor: 0.33, shgc: 0.45 } })
      hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
      _check_windows(hpxml, frac_operable: 0.67,
                            values_by_azimuth: { 0 => { area: 60.75, ufactor: 0.35, shgc: 0.40 },
                                                 180 => { area: 60.75, ufactor: 0.35, shgc: 0.40 },
                                                 90 => { area: 60.75, ufactor: 0.35, shgc: 0.40 },
                                                 270 => { area: 60.75, ufactor: 0.35, shgc: 0.40 } })
      hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentDesign)
      _check_windows(hpxml, frac_operable: 0.67,
                            values_by_azimuth: { 0 => { area: 108, ufactor: 0.33, shgc: 0.45 },
                                                 180 => { area: 108, ufactor: 0.33, shgc: 0.45 },
                                                 90 => { area: 108, ufactor: 0.33, shgc: 0.45 },
                                                 270 => { area: 108, ufactor: 0.33, shgc: 0.45 } })
      hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentReferenceHome)
      _check_windows(hpxml, frac_operable: 0.67,
                            values_by_azimuth: { 0 => { area: 108, ufactor: 0.35, shgc: 0.40 },
                                                 180 => { area: 108, ufactor: 0.35, shgc: 0.40 },
                                                 90 => { area: 108, ufactor: 0.35, shgc: 0.40 },
                                                 270 => { area: 108, ufactor: 0.35, shgc: 0.40 } })
    end

    hpxml_name = 'base-atticroof-cathedral.xml'

    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    frac_operable = (432.0 * 0.67) / (432.0 + 24.0)
    _check_windows(hpxml, frac_operable: frac_operable,
                          values_by_azimuth: { 0 => { area: 108, ufactor: 0.33, shgc: 0.45 },
                                               180 => { area: 108, ufactor: 0.33, shgc: 0.45 },
                                               90 => { area: 120, ufactor: 0.33, shgc: 0.45 },
                                               270 => { area: 120, ufactor: 0.33, shgc: 0.45 } })
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_windows(hpxml, frac_operable: 0.67,
                          values_by_azimuth: { 0 => { area: 93.5, ufactor: 0.35, shgc: 0.40 },
                                               180 => { area: 93.5, ufactor: 0.35, shgc: 0.40 },
                                               90 => { area: 93.5, ufactor: 0.35, shgc: 0.40 },
                                               270 => { area: 93.5, ufactor: 0.35, shgc: 0.40 } })
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentDesign)
    _check_windows(hpxml, frac_operable: 0.67,
                          values_by_azimuth: { 0 => { area: 108, ufactor: 0.33, shgc: 0.45 },
                                               180 => { area: 108, ufactor: 0.33, shgc: 0.45 },
                                               90 => { area: 108, ufactor: 0.33, shgc: 0.45 },
                                               270 => { area: 108, ufactor: 0.33, shgc: 0.45 } })
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentReferenceHome)
    _check_windows(hpxml, frac_operable: 0.67,
                          values_by_azimuth: { 0 => { area: 108, ufactor: 0.35, shgc: 0.40 },
                                               180 => { area: 108, ufactor: 0.35, shgc: 0.40 },
                                               90 => { area: 108, ufactor: 0.35, shgc: 0.40 },
                                               270 => { area: 108, ufactor: 0.35, shgc: 0.40 } })

    hpxml_name = 'base-atticroof-conditioned.xml'

    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    frac_operable = (432.0 * 0.67) / (432.0 + 74.0)
    _check_windows(hpxml, frac_operable: frac_operable,
                          values_by_azimuth: { 0 => { area: 108, ufactor: 0.33, shgc: 0.45 },
                                               180 => { area: 108, ufactor: 0.33, shgc: 0.45 },
                                               90 => { area: 120, ufactor: 0.33, shgc: 0.45 },
                                               270 => { area: 170, ufactor: (0.3 * 62 + 0.33 * 108) / 170, shgc: 0.45 } })
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_windows(hpxml, frac_operable: 0.67,
                          values_by_azimuth: { 0 => { area: 128.6, ufactor: 0.35, shgc: 0.40 },
                                               180 => { area: 128.6, ufactor: 0.35, shgc: 0.40 },
                                               90 => { area: 128.6, ufactor: 0.35, shgc: 0.40 },
                                               270 => { area: 128.6, ufactor: 0.35, shgc: 0.40 } })
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentDesign)
    _check_windows(hpxml, frac_operable: 0.67,
                          values_by_azimuth: { 0 => { area: 108, ufactor: (0.3 * 62 + 0.33 * 444) / 506, shgc: 0.45 },
                                               180 => { area: 108, ufactor: (0.3 * 62 + 0.33 * 444) / 506, shgc: 0.45 },
                                               90 => { area: 108, ufactor: (0.3 * 62 + 0.33 * 444) / 506, shgc: 0.45 },
                                               270 => { area: 108, ufactor: (0.3 * 62 + 0.33 * 444) / 506, shgc: 0.45 } })
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentReferenceHome)
    _check_windows(hpxml, frac_operable: 0.67,
                          values_by_azimuth: { 0 => { area: 108, ufactor: 0.35, shgc: 0.40 },
                                               180 => { area: 108, ufactor: 0.35, shgc: 0.40 },
                                               90 => { area: 108, ufactor: 0.35, shgc: 0.40 },
                                               270 => { area: 108, ufactor: 0.35, shgc: 0.40 } })

    hpxml_name = 'base-bldgtype-multifamily.xml'

    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_windows(hpxml, frac_operable: 0.67,
                          values_by_azimuth: { 0 => { area: 35.0, ufactor: 0.33, shgc: 0.45 },
                                               180 => { area: 35.0, ufactor: 0.33, shgc: 0.45 },
                                               270 => { area: 53.0, ufactor: 0.33, shgc: 0.45 } })
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_windows(hpxml, frac_operable: 0.67,
                          values_by_azimuth: { 0 => { area: 35.15, ufactor: 0.35, shgc: 0.40 },
                                               180 => { area: 35.15, ufactor: 0.35, shgc: 0.40 },
                                               90 => { area: 35.15, ufactor: 0.35, shgc: 0.40 },
                                               270 => { area: 35.15, ufactor: 0.35, shgc: 0.40 } })
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentDesign)
    _check_windows(hpxml, frac_operable: 0.67,
                          values_by_azimuth: { 0 => { area: 108, ufactor: 0.33, shgc: 0.45 },
                                               180 => { area: 108, ufactor: 0.33, shgc: 0.45 },
                                               90 => { area: 108, ufactor: 0.33, shgc: 0.45 },
                                               270 => { area: 108, ufactor: 0.33, shgc: 0.45 } })
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentReferenceHome)
    _check_windows(hpxml, frac_operable: 0.67,
                          values_by_azimuth: { 0 => { area: 108, ufactor: 0.35, shgc: 0.40 },
                                               180 => { area: 108, ufactor: 0.35, shgc: 0.40 },
                                               90 => { area: 108, ufactor: 0.35, shgc: 0.40 },
                                               270 => { area: 108, ufactor: 0.35, shgc: 0.40 } })

    # Create derivative file for testing w/o operable windows
    # Rated/Reference Home windows should not be operable
    hpxml = HPXML.new(hpxml_path: File.join(@root_path, 'workflow', 'sample_files', hpxml_name))
    hpxml.windows.each do |window|
      window.fraction_operable = 0.0
    end
    hpxml_name = File.basename(@tmp_hpxml_path)
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)

    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_windows(hpxml, frac_operable: 0.0,
                          values_by_azimuth: { 0 => { area: 35.0, ufactor: 0.33, shgc: 0.45 },
                                               180 => { area: 35.0, ufactor: 0.33, shgc: 0.45 },
                                               270 => { area: 53.0, ufactor: 0.33, shgc: 0.45 } })
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_windows(hpxml, frac_operable: 0.0,
                          values_by_azimuth: { 0 => { area: 35.15, ufactor: 0.35, shgc: 0.40 },
                                               180 => { area: 35.15, ufactor: 0.35, shgc: 0.40 },
                                               90 => { area: 35.15, ufactor: 0.35, shgc: 0.40 },
                                               270 => { area: 35.15, ufactor: 0.35, shgc: 0.40 } })
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentDesign)
    _check_windows(hpxml, frac_operable: 0.67,
                          values_by_azimuth: { 0 => { area: 108, ufactor: 0.33, shgc: 0.45 },
                                               180 => { area: 108, ufactor: 0.33, shgc: 0.45 },
                                               90 => { area: 108, ufactor: 0.33, shgc: 0.45 },
                                               270 => { area: 108, ufactor: 0.33, shgc: 0.45 } })
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentReferenceHome)
    _check_windows(hpxml, frac_operable: 0.67,
                          values_by_azimuth: { 0 => { area: 108, ufactor: 0.35, shgc: 0.40 },
                                               180 => { area: 108, ufactor: 0.35, shgc: 0.40 },
                                               90 => { area: 108, ufactor: 0.35, shgc: 0.40 },
                                               270 => { area: 108, ufactor: 0.35, shgc: 0.40 } })

    # But in 301-2014, the Reference Home windows are still operable
    hpxml_name = _change_eri_version(hpxml_name, '2014')

    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_windows(hpxml, frac_operable: 0.0,
                          values_by_azimuth: { 0 => { area: 35.0, ufactor: 0.33, shgc: 0.45 },
                                               180 => { area: 35.0, ufactor: 0.33, shgc: 0.45 },
                                               270 => { area: 53.0, ufactor: 0.33, shgc: 0.45 } })
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_windows(hpxml, frac_operable: 0.67,
                          values_by_azimuth: { 0 => { area: 35.15, ufactor: 0.35, shgc: 0.40 },
                                               180 => { area: 35.15, ufactor: 0.35, shgc: 0.40 },
                                               90 => { area: 35.15, ufactor: 0.35, shgc: 0.40 },
                                               270 => { area: 35.15, ufactor: 0.35, shgc: 0.40 } })
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentDesign)
    _check_windows(hpxml, frac_operable: 0.67,
                          values_by_azimuth: { 0 => { area: 108, ufactor: 0.33, shgc: 0.45 },
                                               180 => { area: 108, ufactor: 0.33, shgc: 0.45 },
                                               90 => { area: 108, ufactor: 0.33, shgc: 0.45 },
                                               270 => { area: 108, ufactor: 0.33, shgc: 0.45 } })
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentReferenceHome)
    _check_windows(hpxml, frac_operable: 0.67,
                          values_by_azimuth: { 0 => { area: 108, ufactor: 0.35, shgc: 0.40 },
                                               180 => { area: 108, ufactor: 0.35, shgc: 0.40 },
                                               90 => { area: 108, ufactor: 0.35, shgc: 0.40 },
                                               270 => { area: 108, ufactor: 0.35, shgc: 0.40 } })
  end

  def test_enclosure_skylights
    hpxml_name = 'base.xml'

    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_skylights(hpxml)
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_skylights(hpxml)
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentDesign)
    _check_skylights(hpxml)
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentReferenceHome)
    _check_skylights(hpxml)

    hpxml_name = 'base-enclosure-skylights.xml'

    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_skylights(hpxml, values_by_azimuth: { 0 => { area: 15, ufactor: 0.33, shgc: 0.45 },
                                                 180 => { area: 15, ufactor: 0.35, shgc: 0.47 } })
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_skylights(hpxml)
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentDesign)
    _check_skylights(hpxml, values_by_azimuth: { 0 => { area: 15, ufactor: 0.33, shgc: 0.45 },
                                                 180 => { area: 15, ufactor: 0.35, shgc: 0.47 } })
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentReferenceHome)
    _check_skylights(hpxml)

    # Test large skylight area that would create an IAD Home error if not handled
    # Create derivative file for testing
    hpxml = HPXML.new(hpxml_path: File.join(@root_path, 'workflow', 'sample_files', hpxml_name))
    hpxml.skylights.each do |skylight|
      skylight.area = 700.0
    end
    hpxml_name = File.basename(@tmp_hpxml_path)
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)

    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_skylights(hpxml, values_by_azimuth: { 0 => { area: 700, ufactor: 0.33, shgc: 0.45 },
                                                 180 => { area: 700, ufactor: 0.35, shgc: 0.47 } })
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_skylights(hpxml)
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentDesign)
    _check_skylights(hpxml, values_by_azimuth: { 0 => { area: 643.5, ufactor: 0.33, shgc: 0.45 },
                                                 180 => { area: 643.5, ufactor: 0.35, shgc: 0.47 } })
  end

  def test_enclosure_overhangs
    hpxml_name = 'base.xml'

    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_overhangs(hpxml)
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_overhangs(hpxml)
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentDesign)
    _check_overhangs(hpxml)
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentReferenceHome)
    _check_overhangs(hpxml)

    hpxml_name = 'base-enclosure-overhangs.xml'

    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_overhangs(hpxml, [{ depth: 2.5, top: 0, bottom: 4 },
                             { depth: 0.0, top: 1, bottom: 5 },
                             { depth: 1.5, top: 2, bottom: 6 },
                             { depth: 1.5, top: 2, bottom: 7 }])
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_overhangs(hpxml)
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentDesign)
    _check_overhangs(hpxml)
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentReferenceHome)
    _check_overhangs(hpxml)
  end

  def test_enclosure_doors
    hpxml_name = 'base.xml'

    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_doors(hpxml, values_by_azimuth: { 0 => { area: 40, rvalue: 4.4 },
                                             180 => { area: 40, rvalue: 4.4 } })
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_doors(hpxml, values_by_azimuth: { 0 => { area: 40, rvalue: 2.86 } })
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentDesign)
    _check_doors(hpxml, values_by_azimuth: { 0 => { area: 40, rvalue: 4.4 } })
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentReferenceHome)
    _check_doors(hpxml, values_by_azimuth: { 0 => { area: 40, rvalue: 2.86 } })

    # Test MF unit w/ exterior door
    hpxml_name = 'base-bldgtype-multifamily.xml'

    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_doors(hpxml, values_by_azimuth: { 180 => { area: 20, rvalue: 4.4 } })
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_doors(hpxml, values_by_azimuth: { 0 => { area: 20, rvalue: 2.86 } })
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentDesign)
    _check_doors(hpxml, values_by_azimuth: { 0 => { area: 20, rvalue: 4.4 } })
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentReferenceHome)
    _check_doors(hpxml, values_by_azimuth: { 0 => { area: 20, rvalue: 2.86 } })

    # Test MF unit w/ interior door
    hpxml = HPXML.new(hpxml_path: File.join(@root_path, 'workflow', 'sample_files', hpxml_name))
    hpxml.doors.each do |door|
      door.wall_idref = 'WallOther'
    end
    hpxml_name = File.basename(@tmp_hpxml_path)
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)

    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_doors(hpxml)
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_doors(hpxml)
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentDesign)
    _check_doors(hpxml)
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentReferenceHome)
    _check_doors(hpxml)
  end

  def test_enclosure_attic_ventilation
    hpxml_names = ['base.xml',
                   'base-atticroof-conditioned.xml']

    hpxml_names.each do |hpxml_name|
      hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
      _check_attic_ventilation(hpxml)
      hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
      _check_attic_ventilation(hpxml, sla: 1.0 / 300.0)
      hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentDesign)
      _check_attic_ventilation(hpxml)
      hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentReferenceHome)
      _check_attic_ventilation(hpxml, sla: 1.0 / 300.0)
    end

    hpxml_names = ['base-atticroof-cathedral.xml',
                   'base-atticroof-flat.xml']

    hpxml_names.each do |hpxml_name|
      hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
      _check_attic_ventilation(hpxml)
      hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
      _check_attic_ventilation(hpxml)
      hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentDesign)
      _check_attic_ventilation(hpxml)
      hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentReferenceHome)
      _check_attic_ventilation(hpxml)
    end

    hpxml_name = 'base-atticroof-vented.xml'

    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_attic_ventilation(hpxml, sla: 0.003)
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_attic_ventilation(hpxml, sla: 1.0 / 300.0)
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentDesign)
    _check_attic_ventilation(hpxml, sla: 0.003)
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentReferenceHome)
    _check_attic_ventilation(hpxml, sla: 1.0 / 300.0)
  end

  def test_enclosure_crawlspace_ventilation
    hpxml_names = ['base-foundation-unvented-crawlspace.xml',
                   'base-foundation-multiple.xml']

    hpxml_names.each do |hpxml_name|
      hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
      _check_crawlspace_ventilation(hpxml)
      hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
      _check_crawlspace_ventilation(hpxml, sla: 1.0 / 150.0)
      hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentDesign)
      _check_crawlspace_ventilation(hpxml, sla: 1.0 / 150.0)
      hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentReferenceHome)
      _check_crawlspace_ventilation(hpxml, sla: 1.0 / 150.0)
    end

    hpxml_names = ['base.xml',
                   'base-foundation-slab.xml',
                   'base-foundation-unconditioned-basement.xml',
                   'base-foundation-ambient.xml']

    hpxml_names.each do |hpxml_name|
      hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
      _check_crawlspace_ventilation(hpxml)
      hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
      _check_crawlspace_ventilation(hpxml)
      hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentDesign)
      _check_crawlspace_ventilation(hpxml, sla: 1.0 / 150.0)
      hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentReferenceHome)
      _check_crawlspace_ventilation(hpxml, sla: 1.0 / 150.0)
    end

    hpxml_name = 'base-foundation-vented-crawlspace.xml'

    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_crawlspace_ventilation(hpxml, sla: 0.00667)
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_crawlspace_ventilation(hpxml, sla: 1.0 / 150.0)
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentDesign)
    _check_crawlspace_ventilation(hpxml, sla: 1.0 / 150.0)
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentReferenceHome)
    _check_crawlspace_ventilation(hpxml, sla: 1.0 / 150.0)
  end

  def _test_measure(hpxml_name, calc_type)
    args_hash = {}
    args_hash['hpxml_input_path'] = File.join(@root_path, 'workflow', 'sample_files', hpxml_name)
    args_hash['calc_type'] = calc_type

    # create an instance of the measure
    measure = EnergyRatingIndex301Measure.new

    # create an instance of a runner
    runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)

    model = OpenStudio::Model::Model.new

    # get arguments
    arguments = measure.arguments(model)
    argument_map = OpenStudio::Measure.convertOSArgumentVectorToMap(arguments)

    # populate argument with specified hash value if specified
    arguments.each do |arg|
      temp_arg_var = arg.clone
      if args_hash.has_key?(arg.name)
        assert(temp_arg_var.setValue(args_hash[arg.name]))
      end
      argument_map[arg.name] = temp_arg_var
    end

    # run the measure
    measure.run(model, runner, argument_map)
    result = runner.result

    # show the output
    show_output(result) unless result.value.valueName == 'Success'

    # assert that it ran correctly
    assert_equal('Success', result.value.valueName)

    return measure.new_hpxml
  end

  def _check_infiltration(hpxml, ach50:)
    assert_equal(1, hpxml.air_infiltration_measurements.size)
    air_infiltration_measurement = hpxml.air_infiltration_measurements[0]
    assert_equal(HPXML::UnitsACH, air_infiltration_measurement.unit_of_measure)
    assert_equal(50.0, air_infiltration_measurement.house_pressure)
    assert_in_epsilon(ach50, air_infiltration_measurement.air_leakage, 0.01)
  end

  def _check_roofs(hpxml, area: nil, rvalue: nil, sabs: nil, emit: nil, rb_grade: nil)
    area_values = []
    rvalue_x_area_values = [] # Area-weighted
    sabs_x_area_values = [] # Area-weighted
    emit_x_area_values = [] # Area-weighted
    hpxml.roofs.each do |roof|
      area_values << roof.area
      rvalue_x_area_values << roof.insulation_assembly_r_value * roof.area
      sabs_x_area_values << roof.solar_absorptance * roof.area
      emit_x_area_values << roof.emittance * roof.area
      if rb_grade.nil?
        assert_equal(false, roof.radiant_barrier)
        assert_nil(roof.radiant_barrier_grade)
      else
        assert_equal(true, roof.radiant_barrier)
        assert_equal(rb_grade, roof.radiant_barrier_grade)
      end
    end

    if area.nil?
      assert(area_values.empty?)
    else
      assert_in_epsilon(area, area_values.inject(:+), 0.001)
    end
    if rvalue.nil?
      assert(rvalue_x_area_values.empty?)
    else
      assert_in_epsilon(rvalue, rvalue_x_area_values.inject(:+) / area_values.inject(:+), 0.001)
    end
    if sabs.nil?
      assert(sabs_x_area_values.empty?)
    else
      assert_in_epsilon(sabs, sabs_x_area_values.inject(:+) / area_values.inject(:+), 0.001)
    end
    if emit.nil?
      assert(emit_x_area_values.empty?)
    else
      assert_in_epsilon(emit, emit_x_area_values.inject(:+) / area_values.inject(:+), 0.001)
    end
  end

  def _check_walls(hpxml, area:, rvalue:, sabs:, emit:)
    area_values = []
    rvalue_x_area_values = [] # Area-weighted
    sabs_x_area_values = [] # Area-weighted
    emit_x_area_values = [] # Area-weighted
    hpxml.walls.each do |wall|
      area_values << wall.area
      rvalue_x_area_values << wall.insulation_assembly_r_value * wall.area
      sabs_x_area_values << wall.solar_absorptance * wall.area
      emit_x_area_values << wall.emittance * wall.area
    end
    assert_in_epsilon(area, area_values.inject(:+), 0.001)
    assert_in_epsilon(rvalue, rvalue_x_area_values.inject(:+) / area_values.inject(:+), 0.001)
    assert_in_epsilon(sabs, sabs_x_area_values.inject(:+) / area_values.inject(:+), 0.001)
    assert_in_epsilon(emit, emit_x_area_values.inject(:+) / area_values.inject(:+), 0.001)
  end

  def _check_rim_joists(hpxml, area: nil, rvalue: nil, sabs: nil, emit: nil)
    area_values = []
    rvalue_x_area_values = [] # Area-weighted
    sabs_x_area_values = [] # Area-weighted
    emit_x_area_values = [] # Area-weighted
    hpxml.rim_joists.each do |rim_joist|
      area_values << rim_joist.area
      rvalue_x_area_values << rim_joist.insulation_assembly_r_value * rim_joist.area
      sabs_x_area_values << rim_joist.solar_absorptance * rim_joist.area
      emit_x_area_values << rim_joist.emittance * rim_joist.area
    end

    if area.nil?
      assert(area_values.empty?)
    else
      assert_in_epsilon(area, area_values.inject(:+), 0.001)
    end
    if rvalue.nil?
      assert(rvalue_x_area_values.empty?)
    else
      assert_in_epsilon(rvalue, rvalue_x_area_values.inject(:+) / area_values.inject(:+), 0.001)
    end
    if sabs.nil?
      assert(sabs_x_area_values.empty?)
    else
      assert_in_epsilon(sabs, sabs_x_area_values.inject(:+) / area_values.inject(:+), 0.001)
    end
    if emit.nil?
      assert(emit_x_area_values.empty?)
    else
      assert_in_epsilon(emit, emit_x_area_values.inject(:+) / area_values.inject(:+), 0.001)
    end
  end

  def _check_foundation_walls(hpxml, area:, rvalue: 0, ins_top: 0, ins_bottom: 0, height:, depth_bg: 0)
    area_values = []
    rvalue_x_area_values = [] # Area-weighted
    ins_top_x_area_values = [] # Area-weighted
    ins_bottom_x_area_values = [] # Area-weighted
    height_x_area_values = [] # Area-weighted
    depth_bg_x_area_values = [] # Area-weighted
    hpxml.foundation_walls.each do |foundation_wall|
      area_values << foundation_wall.area
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
    end

    assert_in_epsilon(area, area_values.inject(:+), 0.001)
    assert_in_epsilon(rvalue, rvalue_x_area_values.inject(:+) / area_values.inject(:+), 0.001)
    assert_in_epsilon(ins_top, ins_top_x_area_values.inject(:+) / area_values.inject(:+), 0.001)
    assert_in_epsilon(ins_bottom, ins_bottom_x_area_values.inject(:+) / area_values.inject(:+), 0.001)
    assert_in_epsilon(height, height_x_area_values.inject(:+) / area_values.inject(:+), 0.001)
    assert_in_epsilon(depth_bg, depth_bg_x_area_values.inject(:+) / area_values.inject(:+), 0.001)
  end

  def _check_floors(hpxml, area:, rvalue:)
    area_values = []
    rvalue_x_area_values = [] # Area-weighted
    hpxml.frame_floors.each do |frame_floor|
      area_values << frame_floor.area
      rvalue_x_area_values << frame_floor.insulation_assembly_r_value * frame_floor.area
    end

    assert_in_epsilon(area, area_values.inject(:+), 0.001)
    assert_in_epsilon(rvalue, rvalue_x_area_values.inject(:+) / area_values.inject(:+), 0.001)
  end

  def _check_slabs(hpxml, area:, exp_perim:, perim_ins_depth: 0, perim_ins_r: 0, under_ins_width: 0,
                   under_ins_r: 0, depth_below_grade: nil)
    area_values = []
    exp_perim_x_area_values = [] # Area-weighted
    perim_ins_depth_x_area_values = [] # Area-weighted
    perim_ins_r_x_area_values = [] # Area-weighted
    under_ins_width_x_area_values = [] # Area-weighted
    under_ins_r_x_area_values = [] # Area-weighted
    depth_bg_x_area_values = [] # Area-weighted
    hpxml.slabs.each do |slab|
      area_values << slab.area
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
    end

    assert_in_epsilon(area, area_values.inject(:+), 0.001)
    assert_in_epsilon(exp_perim, exp_perim_x_area_values.inject(:+) / area_values.inject(:+), 0.001)
    assert_in_epsilon(perim_ins_depth, perim_ins_depth_x_area_values.inject(:+) / area_values.inject(:+), 0.001)
    assert_in_epsilon(perim_ins_r, perim_ins_r_x_area_values.inject(:+) / area_values.inject(:+), 0.001)
    assert_in_epsilon(under_ins_width, under_ins_width_x_area_values.inject(:+) / area_values.inject(:+), 0.001)
    assert_in_epsilon(under_ins_r, under_ins_r_x_area_values.inject(:+) / area_values.inject(:+), 0.001)
    if depth_below_grade.nil?
      assert(depth_bg_x_area_values.empty?)
    else
      assert_in_epsilon(depth_below_grade, depth_bg_x_area_values.inject(:+) / area_values.inject(:+), 0.001)
    end
  end

  def _check_windows(hpxml, frac_operable:, values_by_azimuth: {})
    area_total = 0.0
    area_operable = 0.0
    azimuth_area_values = {}
    azimuth_ufactor_x_area_values = {} # Area-weighted
    azimuth_shgc_x_area_values = {} # Area-weighted
    hpxml.windows.each do |window|
      area_total += window.area
      area_operable += (window.area * window.fraction_operable)

      # Init if needed
      azimuth_area_values[window.azimuth] = [] if azimuth_area_values[window.azimuth].nil?
      azimuth_ufactor_x_area_values[window.azimuth] = [] if azimuth_ufactor_x_area_values[window.azimuth].nil?
      azimuth_shgc_x_area_values[window.azimuth] = [] if azimuth_shgc_x_area_values[window.azimuth].nil?

      # Update
      azimuth_area_values[window.azimuth] << window.area
      azimuth_ufactor_x_area_values[window.azimuth] << window.ufactor * window.area
      azimuth_shgc_x_area_values[window.azimuth] << window.shgc * window.area
    end

    assert_equal(values_by_azimuth.keys.size, azimuth_area_values.size)
    assert_equal(values_by_azimuth.keys.size, azimuth_ufactor_x_area_values.size)
    assert_equal(values_by_azimuth.keys.size, azimuth_shgc_x_area_values.size)

    assert_in_epsilon(frac_operable, area_operable / area_total, 0.001)

    values_by_azimuth.each do |azimuth, values|
      assert_in_epsilon(values[:area], azimuth_area_values[azimuth].inject(:+), 0.001)
      assert_in_epsilon(values[:ufactor], azimuth_ufactor_x_area_values[azimuth].inject(:+) / azimuth_area_values[azimuth].inject(:+), 0.001)
      assert_in_epsilon(values[:shgc], azimuth_shgc_x_area_values[azimuth].inject(:+) / azimuth_area_values[azimuth].inject(:+), 0.001)
    end
  end

  def _check_overhangs(hpxml, all_expected_values = [])
    num_overhangs = 0
    hpxml.windows.each do |window|
      next if window.overhangs_depth.nil?

      expected_values = all_expected_values[num_overhangs]
      assert_equal(expected_values[:depth], window.overhangs_depth)
      assert_equal(expected_values[:top], window.overhangs_distance_to_top_of_window)
      assert_equal(expected_values[:bottom], window.overhangs_distance_to_bottom_of_window)
      num_overhangs += 1
    end
    assert_equal(all_expected_values.size, num_overhangs)
  end

  def _check_skylights(hpxml, values_by_azimuth: {})
    azimuth_area_values = {}
    azimuth_ufactor_x_area_values = {} # Area-weighted
    azimuth_shgc_x_area_values = {} # Area-weighted
    hpxml.skylights.each do |skylight|
      # Init if needed
      azimuth_area_values[skylight.azimuth] = [] if azimuth_area_values[skylight.azimuth].nil?
      azimuth_ufactor_x_area_values[skylight.azimuth] = [] if azimuth_ufactor_x_area_values[skylight.azimuth].nil?
      azimuth_shgc_x_area_values[skylight.azimuth] = [] if azimuth_shgc_x_area_values[skylight.azimuth].nil?

      # Update
      azimuth_area_values[skylight.azimuth] << skylight.area
      azimuth_ufactor_x_area_values[skylight.azimuth] << skylight.ufactor * skylight.area
      azimuth_shgc_x_area_values[skylight.azimuth] << skylight.shgc * skylight.area
    end

    assert_equal(values_by_azimuth.keys.size, azimuth_area_values.size)
    assert_equal(values_by_azimuth.keys.size, azimuth_ufactor_x_area_values.size)
    assert_equal(values_by_azimuth.keys.size, azimuth_shgc_x_area_values.size)

    values_by_azimuth.each do |azimuth, values|
      assert_in_epsilon(values[:area], azimuth_area_values[azimuth].inject(:+), 0.001)
      assert_in_epsilon(values[:ufactor], azimuth_ufactor_x_area_values[azimuth].inject(:+) / azimuth_area_values[azimuth].inject(:+), 0.001)
      assert_in_epsilon(values[:shgc], azimuth_shgc_x_area_values[azimuth].inject(:+) / azimuth_area_values[azimuth].inject(:+), 0.001)
    end
  end

  def _check_doors(hpxml, values_by_azimuth: {})
    azimuth_area_values = {}
    azimuth_rvalue_x_area_values = {} # Area-weighted
    hpxml.doors.each do |door|
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
      assert_in_epsilon(values[:area], azimuth_area_values[azimuth].inject(:+), 0.001)
      assert_in_epsilon(values[:rvalue], azimuth_rvalue_x_area_values[azimuth].inject(:+) / azimuth_area_values[azimuth].inject(:+), 0.01)
    end
  end

  def _check_attic_ventilation(hpxml, sla: nil)
    attic_sla = nil
    hpxml.attics.each do |attic|
      next unless attic.attic_type == HPXML::AtticTypeVented

      attic_sla = attic.vented_attic_sla
    end
    if sla.nil?
      assert_nil(attic_sla)
    else
      assert_in_epsilon(sla, attic_sla, 0.001)
    end
  end

  def _check_crawlspace_ventilation(hpxml, sla: nil)
    crawl_sla = nil
    hpxml.foundations.each do |foundation|
      next unless foundation.foundation_type == HPXML::FoundationTypeCrawlspaceVented

      crawl_sla = foundation.vented_crawlspace_sla
    end
    if sla.nil?
      assert_nil(crawl_sla)
    else
      assert_in_epsilon(sla, crawl_sla, 0.001)
    end
  end
end
