# frozen_string_literal: true

require_relative '../../../workflow/tests/minitest_helper'
require 'openstudio'
require 'openstudio/ruleset/ShowRunnerOutput'
require 'minitest/autorun'
require_relative '../measure.rb'
require 'fileutils'

class EnclosureTest < MiniTest::Test
  def before_setup
    @root_path = File.absolute_path(File.join(File.dirname(__FILE__), '..', '..', '..'))
    @tmp_hpxml_path = File.join(@root_path, 'workflow', 'sample_files', 'tmp.xml')
  end

  def after_teardown
    File.delete(@tmp_hpxml_path) if File.exist? @tmp_hpxml_path
  end

  def test_enclosure_infiltration
    hpxml_name = 'base.xml'

    # Rated Home
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_infiltration(hpxml, 9.3)

    # Reference Home
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_infiltration(hpxml, 7.09)

    # IAD Home
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentDesign)
    _check_infiltration(hpxml, 3.0)

    # IAD Reference Home
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentReferenceHome)
    _check_infiltration(hpxml, 6.67)

    hpxml_name = 'base-mechvent-exhaust.xml'

    # Rated Home
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_infiltration(hpxml, 3.0)

    # Reference Home
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_infiltration(hpxml, 7.09)

    # IAD Home
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentDesign)
    _check_infiltration(hpxml, 3.0)

    # IAD Reference Home
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentReferenceHome)
    _check_infiltration(hpxml, 6.67)
  end

  def test_enclosure_roofs
    hpxml_name = 'base.xml'

    # Rated Home
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_roofs(hpxml, 1510, 2.3, 0.7, 0.92)

    # Reference Home
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_roofs(hpxml, 1510, 2.3, 0.75, 0.9)

    # IAD Home
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentDesign)
    _check_roofs(hpxml, 1300, 2.3, 0.7, 0.92)

    # IAD Reference Home
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentReferenceHome)
    _check_roofs(hpxml, 1300, 2.3, 0.75, 0.9)

    hpxml_name = 'base-atticroof-cathedral.xml'

    # Rated Home
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_roofs(hpxml, 1510, 25.8, 0.7, 0.92)

    # Reference Home
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_roofs(hpxml, 1510, 33.33, 0.75, 0.9)

    # IAD Home
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentDesign)
    _check_roofs(hpxml, 1300, 25.8, 0.7, 0.92)

    # IAD Reference Home
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentReferenceHome)
    _check_roofs(hpxml, 1300, 33.33, 0.75, 0.9)

    hpxml_name = 'base-atticroof-conditioned.xml'

    # Rated Home
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_roofs(hpxml, 1510, (25.8 * 1006 + 2.3 * 504) / 1510, 0.7, 0.92)

    # Reference Home
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_roofs(hpxml, 1510, (33.33 * 1006 + 2.3 * 504) / 1510, 0.75, 0.9)

    # IAD Home
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentDesign)
    _check_roofs(hpxml, 1300, (25.8 * 1006 + 2.3 * 504) / 1510, 0.7, 0.92)

    # IAD Reference Home
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentReferenceHome)
    _check_roofs(hpxml, 1300, (33.33 * 1006 + 2.3 * 504) / 1510, 0.75, 0.9)

    hpxml_name = 'base-atticroof-unvented-insulated-roof.xml'

    # Rated Home
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_roofs(hpxml, 1510, 25.8, 0.7, 0.92)

    # Reference Home
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_roofs(hpxml, 1510, 2.3, 0.75, 0.9)

    # IAD Home
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentDesign)
    _check_roofs(hpxml, 1300, 25.8, 0.7, 0.92)

    # IAD Reference Home
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentReferenceHome)
    _check_roofs(hpxml, 1300, 2.3, 0.75, 0.9)

    hpxml_name = 'base-atticroof-flat.xml'

    # Rated Home
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_roofs(hpxml, 1350, 25.8, 0.7, 0.92)

    # Reference Home
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_roofs(hpxml, 1350, 33.33, 0.75, 0.9)

    # IAD Home
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentDesign)
    _check_roofs(hpxml, 1300, 25.8, 0.7, 0.92)

    # IAD Reference Home
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentReferenceHome)
    _check_roofs(hpxml, 1300, 33.33, 0.75, 0.9)

    # hpxml_name = 'base-enclosure-adiabatic-surfaces.xml'

    # Rated Home
    # hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    # _check_roofs(hpxml, nil, nil, nil, nil)

    # Reference Home
    # hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    # _check_roofs(hpxml, nil, nil, nil, nil)

    # IAD Home
    # hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentDesign)
    # _check_roofs(hpxml, nil, nil, nil, nil)

    # IAD Reference Home
    # hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentReferenceHome)
    # _check_roofs(hpxml, nil, nil, nil, nil)
  end

  def test_enclosure_walls
    hpxml_name = 'base.xml'

    # Rated Home
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_walls(hpxml, 1490, (23.0 * 1200 + 4.0 * 290) / 1490, 0.7, 0.92)

    # Reference Home
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_walls(hpxml, 1490, (16.67 * 1200 + 4.0 * 290) / 1490, 0.75, 0.9)

    # IAD Home
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentDesign)
    _check_walls(hpxml, 2645.52, (23.0 * 2355.52 + 4.0 * 290) / 2645.52, 0.7, 0.92)

    # IAD Reference Home
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentReferenceHome)
    _check_walls(hpxml, 2645.52, (16.67 * 2355.52 + 4.0 * 290) / 2645.52, 0.75, 0.9)

    hpxml_name = 'base-atticroof-conditioned.xml'

    # Rated Home
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_walls(hpxml, 1806, (23.0 * 1516 + 22.3 * 240 + 4.0 * 50) / 1806, 0.7, 0.92)

    # Reference Home
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_walls(hpxml, 1806, (16.67 * 1756 + 4.0 * 50) / 1806, 0.75, 0.9)

    # IAD Home
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentDesign)
    _check_walls(hpxml, 2405.52, ((23.0 * 1200 + 22.3 * 240) / 1440 * 2355.52 + 4.0 * 50) / 2405.52, 0.7, 0.92)

    # IAD Reference Home
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentReferenceHome)
    _check_walls(hpxml, 2405.52, (16.67 * 2355.52 + 4.0 * 50) / 2405.52, 0.75, 0.9)

    # hpxml_name = 'base-enclosure-adiabatic-surfaces.xml'

    # Rated Home
    # hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    # _check_walls(hpxml, 1200, (23.0 * 420 + 4.0 * 780) / 1200, 0.7, 0.92)

    # Reference Home
    # hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    # _check_walls(hpxml, 1200, (16.67 * 420 + 4.0 * 780) / 1200, 0.75, 0.9)

    # IAD Home
    # hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentDesign)
    # _check_walls(hpxml, 2355.52, 23.0, 0.7, 0.92)

    # IAD Reference Home
    # hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentReferenceHome)
    # _check_walls(hpxml, 2355.52, 16.67, 0.75, 0.9)

    hpxml_name = 'base-enclosure-garage.xml'

    # Rated Home
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_walls(hpxml, 1760, (23.0 * 1200 + 4.0 * 560) / 1760, 0.7, 0.92)

    # Reference Home
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_walls(hpxml, 1760, (16.67 * 1200 + 4.0 * 560) / 1760, 0.75, 0.9)

    # IAD Home
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentDesign)
    _check_walls(hpxml, 2355.52, 23.0, 0.7, 0.92)

    # IAD Reference Home
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentReferenceHome)
    _check_walls(hpxml, 2355.52, 16.67, 0.75, 0.9)
  end

  def test_enclosure_rim_joists
    hpxml_name = 'base.xml'

    # Rated Home
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_rim_joists(hpxml, 116, 23.0, 0.7, 0.92)

    # Reference Home
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_rim_joists(hpxml, 116, 16.67, 0.75, 0.9)

    # IAD Home
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentDesign)
    _check_rim_joists(hpxml, nil, nil, nil, nil)

    # IAD Reference Home
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentReferenceHome)
    _check_rim_joists(hpxml, nil, nil, nil, nil)

    hpxml_name = 'base-foundation-multiple.xml'

    # Rated Home
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_rim_joists(hpxml, 197, 2.3, 0.7, 0.92)

    # Reference Home
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_rim_joists(hpxml, 197, 2.3, 0.75, 0.9)

    # IAD Home
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentDesign)
    _check_rim_joists(hpxml, nil, nil, nil, nil)

    # IAD Reference Home
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentReferenceHome)
    _check_rim_joists(hpxml, nil, nil, nil, nil)
  end

  def test_enclosure_foundation_walls
    hpxml_name = 'base.xml'

    # Rated Home
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_foundation_walls(hpxml, 1200, 8.9, 0, 8, 8, 7)

    # Reference Home
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_foundation_walls(hpxml, 1200, 16.95, 0, 8, 8, 7)

    # IAD Home
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentDesign)
    _check_foundation_walls(hpxml, 277.12, 0, 0, 0, 2, 0)

    # IAD Reference Home
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentReferenceHome)
    _check_foundation_walls(hpxml, 277.12, 0, 0, 0, 2, 0)

    hpxml_name = 'base-foundation-conditioned-basement-wall-interior-insulation.xml'

    # Rated Home
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_foundation_walls(hpxml, 1200, 18.9, 1, 16, 8, 7)

    # Reference Home
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_foundation_walls(hpxml, 1200, 16.95, 0, 8, 8, 7)

    # IAD Home
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentDesign)
    _check_foundation_walls(hpxml, 277.12, 0, 0, 0, 2, 0)

    # IAD Reference Home
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentReferenceHome)
    _check_foundation_walls(hpxml, 277.12, 0, 0, 0, 2, 0)

    hpxml_name = 'base-foundation-unconditioned-basement.xml'

    # Rated Home
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_foundation_walls(hpxml, 1200, 0, 0, 0, 8, 7)

    # Reference Home
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_foundation_walls(hpxml, 1200, 0, 0, 0, 8, 7)

    # IAD Home
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentDesign)
    _check_foundation_walls(hpxml, 277.12, 0, 0, 0, 2, 0)

    # IAD Reference Home
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentReferenceHome)
    _check_foundation_walls(hpxml, 277.12, 0, 0, 0, 2, 0)

    hpxml_name = 'base-foundation-unconditioned-basement-wall-insulation.xml'

    # Rated Home
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_foundation_walls(hpxml, 1200, 8.9, 0, 4, 8, 7)

    # Reference Home
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_foundation_walls(hpxml, 1200, 16.95, 0, 8, 8, 7)

    # IAD Home
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentDesign)
    _check_foundation_walls(hpxml, 277.12, 0, 0, 0, 2, 0)

    # IAD Reference Home
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentReferenceHome)
    _check_foundation_walls(hpxml, 277.12, 0, 0, 0, 2, 0)

    hpxml_names = ['base-foundation-unvented-crawlspace.xml',
                   'base-foundation-vented-crawlspace.xml']

    hpxml_names.each do |hpxml_name|
      # Rated Home
      hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
      _check_foundation_walls(hpxml, 600, 8.9, 0, 4, 4, 3)

      # Reference Home
      hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
      _check_foundation_walls(hpxml, 600, 0, 0, 0, 4, 3)

      # IAD Home
      hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentDesign)
      _check_foundation_walls(hpxml, 277.12, 0, 0, 0, 2, 0)

      # IAD Reference Home
      hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentReferenceHome)
      _check_foundation_walls(hpxml, 277.12, 0, 0, 0, 2, 0)
    end
  end

  def test_enclosure_floors
    hpxml_name = 'base.xml'

    # Rated Home
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_floors(hpxml, 1350, 39.3)

    # Reference Home
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_floors(hpxml, 1350, 33.33)

    # IAD Home
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentDesign)
    _check_floors(hpxml, 2400, (39.3 * 1200 + 30.3 * 1200) / 2400)

    # IAD Reference Home
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentReferenceHome)
    _check_floors(hpxml, 2400, (33.33 * 1200 + 30.3 * 1200) / 2400)

    hpxml_name = 'base-foundation-ambient.xml'

    # Rated Home
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_floors(hpxml, 2700, (39.3 * 1350 + 18.7 * 1350) / 2700)

    # Reference Home
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_floors(hpxml, 2700, (33.33 * 1350 + 30.3 * 1350) / 2700)

    # IAD Home
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentDesign)
    _check_floors(hpxml, 2400, (39.3 * 1200 + 30.3 * 1200) / 2400)

    # IAD Reference Home
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentReferenceHome)
    _check_floors(hpxml, 2400, (33.33 * 1200 + 30.3 * 1200) / 2400)

    hpxml_name = 'base-enclosure-garage.xml'

    # Rated Home
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_floors(hpxml, 1950, (39.3 * 1350 + 2.1 * 600) / 1950)

    # Reference Home
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_floors(hpxml, 1950, (33.33 * 1350 + 2.1 * 600) / 1950)

    # IAD Home
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentDesign)
    _check_floors(hpxml, 2400, (39.3 * 1200 + 30.3 * 1200) / 2400)

    # IAD Reference Home
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentReferenceHome)
    _check_floors(hpxml, 2400, (33.33 * 1200 + 30.3 * 1200) / 2400)

    hpxml_name = 'base-foundation-unconditioned-basement.xml'

    # Rated Home
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_floors(hpxml, 2700, (39.3 * 1350 + 18.7 * 1350) / 2700)

    # Reference Home
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_floors(hpxml, 2700, (33.33 * 1350 + 30.3 * 1350) / 2700)

    # IAD Home
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentDesign)
    _check_floors(hpxml, 2400, (39.3 * 1200 + 30.3 * 1200) / 2400)

    # IAD Reference Home
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentReferenceHome)
    _check_floors(hpxml, 2400, (33.33 * 1200 + 30.3 * 1200) / 2400)

    hpxml_name = 'base-foundation-unconditioned-basement-wall-insulation.xml'

    # Rated Home
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_floors(hpxml, 2700, (39.3 * 1350 + 2.1 * 1350) / 2700)

    # Reference Home
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_floors(hpxml, 2700, (33.33 * 1350 + 2.1 * 1350) / 2700)

    # IAD Home
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentDesign)
    _check_floors(hpxml, 2400, (39.3 * 1200 + 30.3 * 1200) / 2400)

    # IAD Reference Home
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentReferenceHome)
    _check_floors(hpxml, 2400, (33.33 * 1200 + 30.3 * 1200) / 2400)
  end

  def test_enclosure_slabs
    hpxml_name = 'base.xml'

    # Rated Home
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_slabs(hpxml, 1350, 150, 0, 0, 0, 0, nil)

    # Reference Home
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_slabs(hpxml, 1350, 150, 0, 0, 0, 0, nil)

    # IAD Home
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentDesign)
    _check_slabs(hpxml, 1200, 138.6, 0, 0, 0, 0, nil)

    # IAD Reference Home
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentReferenceHome)
    _check_slabs(hpxml, 1200, 138.6, 0, 0, 0, 0, nil)

    hpxml_name = 'base-foundation-slab.xml'

    # Rated Home
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_slabs(hpxml, 1350, 150, 0, 0, 999, 5, 0)

    # Reference Home
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_slabs(hpxml, 1350, 150, 2, 10, 0, 0, 0)

    # IAD Home
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentDesign)
    _check_slabs(hpxml, 1200, 138.6, 0, 0, 0, 0, nil)

    # IAD Reference Home
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentReferenceHome)
    _check_slabs(hpxml, 1200, 138.6, 0, 0, 0, 0, nil)

    hpxml_name = 'base-foundation-conditioned-basement-slab-insulation.xml'

    # Rated Home
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_slabs(hpxml, 1350, 150, 0, 0, 4, 10, nil)

    # Reference Home
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_slabs(hpxml, 1350, 150, 0, 0, 0, 0, nil)

    # IAD Home
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentDesign)
    _check_slabs(hpxml, 1200, 138.6, 0, 0, 0, 0, nil)

    # IAD Reference Home
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentReferenceHome)
    _check_slabs(hpxml, 1200, 138.6, 0, 0, 0, 0, nil)
  end

  def test_enclosure_windows
    hpxml_names = ['base.xml',
                   'base-atticroof-flat.xml',
                   'base-atticroof-vented.xml']

    hpxml_names.each do |hpxml_name|
      # Rated Home
      hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
      _check_windows(hpxml, { 0 => [108, 0.33, 0.45],
                              180 => [108, 0.33, 0.45],
                              90 => [72, 0.33, 0.45],
                              270 => [72, 0.33, 0.45] })

      # Reference Home
      hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
      _check_windows(hpxml, { 0 => [89.5, 0.35, 0.40],
                              180 => [89.5, 0.35, 0.40],
                              90 => [89.5, 0.35, 0.40],
                              270 => [89.5, 0.35, 0.40] })

      # IAD Home
      hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentDesign)
      _check_windows(hpxml, { 0 => [108, 0.33, 0.45],
                              180 => [108, 0.33, 0.45],
                              90 => [108, 0.33, 0.45],
                              270 => [108, 0.33, 0.45] })

      # IAD Reference Home
      hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentReferenceHome)
      _check_windows(hpxml, { 0 => [108, 0.35, 0.40],
                              180 => [108, 0.35, 0.40],
                              90 => [108, 0.35, 0.40],
                              270 => [108, 0.35, 0.40] })
    end

    hpxml_names = ['base-foundation-ambient.xml',
                   'base-foundation-slab.xml',
                   'base-foundation-unconditioned-basement.xml',
                   'base-foundation-unvented-crawlspace.xml',
                   'base-foundation-vented-crawlspace.xml']

    hpxml_names.each do |hpxml_name|
      # Rated Home
      hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
      _check_windows(hpxml, { 0 => [108, 0.33, 0.45],
                              180 => [108, 0.33, 0.45],
                              90 => [72, 0.33, 0.45],
                              270 => [72, 0.33, 0.45] })

      # Reference Home
      hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
      _check_windows(hpxml, { 0 => [60.75, 0.35, 0.40],
                              180 => [60.75, 0.35, 0.40],
                              90 => [60.75, 0.35, 0.40],
                              270 => [60.75, 0.35, 0.40] })

      # IAD Home
      hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentDesign)
      _check_windows(hpxml, { 0 => [108, 0.33, 0.45],
                              180 => [108, 0.33, 0.45],
                              90 => [108, 0.33, 0.45],
                              270 => [108, 0.33, 0.45] })

      # IAD Reference Home
      hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentReferenceHome)
      _check_windows(hpxml, { 0 => [108, 0.35, 0.40],
                              180 => [108, 0.35, 0.40],
                              90 => [108, 0.35, 0.40],
                              270 => [108, 0.35, 0.40] })
    end

    hpxml_name = 'base-atticroof-cathedral.xml'

    # Rated Home
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_windows(hpxml, { 0 => [108, 0.33, 0.45],
                            180 => [108, 0.33, 0.45],
                            90 => [120, 0.33, 0.45],
                            270 => [120, 0.33, 0.45] })

    # Reference Home
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_windows(hpxml, { 0 => [93.5, 0.35, 0.40],
                            180 => [93.5, 0.35, 0.40],
                            90 => [93.5, 0.35, 0.40],
                            270 => [93.5, 0.35, 0.40] })

    # IAD Home
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentDesign)
    _check_windows(hpxml, { 0 => [108, 0.33, 0.45],
                            180 => [108, 0.33, 0.45],
                            90 => [108, 0.33, 0.45],
                            270 => [108, 0.33, 0.45] })

    # IAD Reference Home
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentReferenceHome)
    _check_windows(hpxml, { 0 => [108, 0.35, 0.40],
                            180 => [108, 0.35, 0.40],
                            90 => [108, 0.35, 0.40],
                            270 => [108, 0.35, 0.40] })

    hpxml_name = 'base-atticroof-conditioned.xml'

    # Rated Home
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_windows(hpxml, { 0 => [108, 0.33, 0.45],
                            180 => [108, 0.33, 0.45],
                            90 => [120, 0.33, 0.45],
                            270 => [170, (0.3 * 62 + 0.33 * 108) / 170, 0.45] })

    # Reference Home
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_windows(hpxml, { 0 => [128.6, 0.35, 0.40],
                            180 => [128.6, 0.35, 0.40],
                            90 => [128.6, 0.35, 0.40],
                            270 => [128.6, 0.35, 0.40] })

    # IAD Home
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentDesign)
    _check_windows(hpxml, { 0 => [108, (0.3 * 62 + 0.33 * 444) / 506, 0.45],
                            180 => [108, (0.3 * 62 + 0.33 * 444) / 506, 0.45],
                            90 => [108, (0.3 * 62 + 0.33 * 444) / 506, 0.45],
                            270 => [108, (0.3 * 62 + 0.33 * 444) / 506, 0.45] })

    # IAD Reference Home
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentReferenceHome)
    _check_windows(hpxml, { 0 => [108, 0.35, 0.40],
                            180 => [108, 0.35, 0.40],
                            90 => [108, 0.35, 0.40],
                            270 => [108, 0.35, 0.40] })

    # hpxml_name = 'base-enclosure-adiabatic-surfaces.xml'

    # Rated Home
    # hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    # _check_windows(hpxml, { 0 => [37.8, 0.33, 0.45],
    #                        180 => [37.8, 0.33, 0.45],
    #                        90 => [25.2, 0.33, 0.45],
    #                        270 => [25.2, 0.33, 0.45] })

    # Reference Home
    # hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    # _check_windows(hpxml, { 0 => [43.4, 0.35, 0.40],
    #                        180 => [43.4, 0.35, 0.40],
    #                        90 => [43.4, 0.35, 0.40],
    #                        270 => [43.4, 0.35, 0.40] })

    # IAD Home
    # hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentDesign)
    # _check_windows(hpxml, { 0 => [108, 0.33, 0.45],
    #                        180 => [108, 0.33, 0.45],
    #                        90 => [108, 0.33, 0.45],
    #                        270 => [108, 0.33, 0.45] })

    # IAD Reference Home
    # hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentReferenceHome)
    # _check_windows(hpxml, { 0 => [108, 0.35, 0.40],
    #                        180 => [108, 0.35, 0.40],
    #                        90 => [108, 0.35, 0.40],
    #                        270 => [108, 0.35, 0.40] })
  end

  def test_enclosure_skylights
    hpxml_name = 'base.xml'

    # Rated Home
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_skylights(hpxml)

    # Reference Home
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_skylights(hpxml)

    # IAD Home
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentDesign)
    _check_skylights(hpxml)

    # IAD Reference Home
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentReferenceHome)
    _check_skylights(hpxml)

    hpxml_name = 'base-enclosure-skylights.xml'

    # Rated Home
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_skylights(hpxml, { 0 => [45, 0.33, 0.45],
                              180 => [45, 0.35, 0.47] })

    # Reference Home
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_skylights(hpxml)

    # IAD Home
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentDesign)
    _check_skylights(hpxml, { 0 => [45, 0.33, 0.45],
                              180 => [45, 0.35, 0.47] })

    # IAD Reference Home
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

    # Rated Home
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_skylights(hpxml, { 0 => [700, 0.33, 0.45],
                              180 => [700, 0.35, 0.47] })

    # Reference Home
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_skylights(hpxml)

    # IAD Home
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentDesign)
    _check_skylights(hpxml, { 0 => [643.5, 0.33, 0.45],
                              180 => [643.5, 0.35, 0.47] })
  end

  def test_enclosure_overhangs
    hpxml_name = 'base.xml'

    # Rated Home
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_overhangs(hpxml)

    # Reference Home
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_overhangs(hpxml)

    # IAD Home
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentDesign)
    _check_overhangs(hpxml)

    # IAD Reference Home
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentReferenceHome)
    _check_overhangs(hpxml)

    hpxml_name = 'base-enclosure-overhangs.xml'

    # Rated Home
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_overhangs(hpxml, [2.5, 0, 4],
                     [1.5, 2, 6],
                     [1.5, 2, 7])

    # Reference Home
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_overhangs(hpxml)

    # IAD Home
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentDesign)
    _check_overhangs(hpxml)

    # IAD Reference Home
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentReferenceHome)
    _check_overhangs(hpxml)
  end

  def test_enclosure_doors
    hpxml_name = 'base.xml'

    # Rated Home
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_doors(hpxml, { 0 => [40, 4.4],
                          180 => [40, 4.4] })

    # Reference Home
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_doors(hpxml, { 0 => [40, 2.86] })

    # IAD Home
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentDesign)
    _check_doors(hpxml, { 0 => [40, 4.4] })

    # IAD Reference Home
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentReferenceHome)
    _check_doors(hpxml, { 0 => [40, 2.86] })
  end

  def test_enclosure_attic_ventilation
    hpxml_names = ['base.xml',
                   'base-atticroof-conditioned.xml']

    hpxml_names.each do |hpxml_name|
      # Rated Home
      hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
      _check_attic_ventilation(hpxml, nil)

      # Reference Home
      hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
      _check_attic_ventilation(hpxml, 1.0 / 300.0)

      # IAD Home
      hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentDesign)
      _check_attic_ventilation(hpxml, nil)

      # IAD Reference Home
      hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentReferenceHome)
      _check_attic_ventilation(hpxml, 1.0 / 300.0)
    end

    hpxml_names = ['base-atticroof-cathedral.xml',
                   'base-atticroof-flat.xml']

    hpxml_names.each do |hpxml_name|
      # Rated Home
      hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
      _check_attic_ventilation(hpxml, nil)

      # Reference Home
      hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
      _check_attic_ventilation(hpxml, nil)

      # IAD Home
      hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentDesign)
      _check_attic_ventilation(hpxml, nil)

      # IAD Reference Home
      hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentReferenceHome)
      _check_attic_ventilation(hpxml, nil)
    end

    hpxml_name = 'base-atticroof-vented.xml'

    # Rated Home
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_attic_ventilation(hpxml, 0.003)

    # Reference Home
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_attic_ventilation(hpxml, 1.0 / 300.0)

    # IAD Home
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentDesign)
    _check_attic_ventilation(hpxml, 0.003)

    # IAD Reference Home
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentReferenceHome)
    _check_attic_ventilation(hpxml, 1.0 / 300.0)
  end

  def test_enclosure_crawlspace_ventilation
    hpxml_names = ['base-foundation-unvented-crawlspace.xml',
                   'base-foundation-multiple.xml']

    hpxml_names.each do |hpxml_name|
      # Rated Home
      hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
      _check_crawlspace_ventilation(hpxml, nil)

      # Reference Home
      hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
      _check_crawlspace_ventilation(hpxml, 1.0 / 150.0)

      # IAD Home
      hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentDesign)
      _check_crawlspace_ventilation(hpxml, 1.0 / 150.0)

      # IAD Reference Home
      hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentReferenceHome)
      _check_crawlspace_ventilation(hpxml, 1.0 / 150.0)
    end

    hpxml_names = ['base.xml',
                   'base-foundation-slab.xml',
                   'base-foundation-unconditioned-basement.xml',
                   'base-foundation-ambient.xml']

    hpxml_names.each do |hpxml_name|
      # Rated Home
      hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
      _check_crawlspace_ventilation(hpxml, nil)

      # Reference Home
      hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
      _check_crawlspace_ventilation(hpxml, nil)

      # IAD Home
      hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentDesign)
      _check_crawlspace_ventilation(hpxml, 1.0 / 150.0)

      # IAD Reference Home
      hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentReferenceHome)
      _check_crawlspace_ventilation(hpxml, 1.0 / 150.0)
    end

    hpxml_name = 'base-foundation-vented-crawlspace.xml'

    # Rated Home
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_crawlspace_ventilation(hpxml, 0.00667)

    # Reference Home
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_crawlspace_ventilation(hpxml, 1.0 / 150.0)

    # IAD Home
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentDesign)
    _check_crawlspace_ventilation(hpxml, 1.0 / 150.0)

    # IAD Reference Home
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentReferenceHome)
    _check_crawlspace_ventilation(hpxml, 1.0 / 150.0)
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

  def _check_infiltration(hpxml, ach50)
    assert_equal(1, hpxml.air_infiltration_measurements.size)
    air_infiltration_measurement = hpxml.air_infiltration_measurements[0]
    assert_equal(HPXML::UnitsACH, air_infiltration_measurement.unit_of_measure)
    assert_equal(50.0, air_infiltration_measurement.house_pressure)
    assert_in_epsilon(ach50, air_infiltration_measurement.air_leakage, 0.01)
  end

  def _check_roofs(hpxml, area, rvalue, sabs, emit)
    area_values = []
    rvalue_x_area_values = [] # Area-weighted
    sabs_x_area_values = [] # Area-weighted
    emit_x_area_values = [] # Area-weighted
    hpxml.roofs.each do |roof|
      area_values << roof.area
      rvalue_x_area_values << roof.insulation_assembly_r_value * roof.area
      sabs_x_area_values << roof.solar_absorptance * roof.area
      emit_x_area_values << roof.emittance * roof.area
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

  def _check_walls(hpxml, area, rvalue, sabs, emit)
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

  def _check_rim_joists(hpxml, area, rvalue, sabs, emit)
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

  def _check_foundation_walls(hpxml, area, rvalue, ins_top, ins_bottom, height, depth_below_grade)
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
    assert_in_epsilon(depth_below_grade, depth_bg_x_area_values.inject(:+) / area_values.inject(:+), 0.001)
  end

  def _check_floors(hpxml, area, rvalue)
    area_values = []
    rvalue_x_area_values = [] # Area-weighted
    hpxml.frame_floors.each do |frame_floor|
      area_values << frame_floor.area
      rvalue_x_area_values << frame_floor.insulation_assembly_r_value * frame_floor.area
    end

    assert_in_epsilon(area, area_values.inject(:+), 0.001)
    assert_in_epsilon(rvalue, rvalue_x_area_values.inject(:+) / area_values.inject(:+), 0.001)
  end

  def _check_slabs(hpxml, area, exp_perim, perim_ins_depth, perim_ins_r, under_ins_width, under_ins_r, depth_below_grade)
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

  def _check_windows(hpxml, azimuth_values = {})
    azimuth_area_values = {}
    azimuth_ufactor_x_area_values = {} # Area-weighted
    azimuth_shgc_x_area_values = {} # Area-weighted
    hpxml.windows.each do |window|
      azimuth =

        # Init if needed
        azimuth_area_values[window.azimuth] = [] if azimuth_area_values[window.azimuth].nil?
      azimuth_ufactor_x_area_values[window.azimuth] = [] if azimuth_ufactor_x_area_values[window.azimuth].nil?
      azimuth_shgc_x_area_values[window.azimuth] = [] if azimuth_shgc_x_area_values[window.azimuth].nil?

      # Update
      azimuth_area_values[window.azimuth] << window.area
      azimuth_ufactor_x_area_values[window.azimuth] << window.ufactor * window.area
      azimuth_shgc_x_area_values[window.azimuth] << window.shgc * window.area
    end

    assert_equal(azimuth_values.keys.size, azimuth_area_values.size)
    assert_equal(azimuth_values.keys.size, azimuth_ufactor_x_area_values.size)
    assert_equal(azimuth_values.keys.size, azimuth_shgc_x_area_values.size)

    azimuth_values.each do |azimuth, values|
      area, ufactor, shgc = values
      assert_in_epsilon(area, azimuth_area_values[azimuth].inject(:+), 0.001)
      assert_in_epsilon(ufactor, azimuth_ufactor_x_area_values[azimuth].inject(:+) / azimuth_area_values[azimuth].inject(:+), 0.001)
      assert_in_epsilon(shgc, azimuth_shgc_x_area_values[azimuth].inject(:+) / azimuth_area_values[azimuth].inject(:+), 0.001)
    end
  end

  def _check_overhangs(hpxml, *overhangs)
    num_overhangs = 0
    hpxml.windows.each do |window|
      next if window.overhangs_depth.nil?

      overhang_depth, overhang_top, overhang_bottom = overhangs[num_overhangs]
      assert_equal(overhang_depth, window.overhangs_depth)
      assert_equal(overhang_top, window.overhangs_distance_to_top_of_window)
      assert_equal(overhang_bottom, window.overhangs_distance_to_bottom_of_window)
      num_overhangs += 1
    end
    assert_equal(overhangs.size, num_overhangs)
  end

  def _check_skylights(hpxml, azimuth_values = {})
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

    assert_equal(azimuth_values.keys.size, azimuth_area_values.size)
    assert_equal(azimuth_values.keys.size, azimuth_ufactor_x_area_values.size)
    assert_equal(azimuth_values.keys.size, azimuth_shgc_x_area_values.size)

    azimuth_values.each do |azimuth, values|
      area, ufactor, shgc = values
      assert_in_epsilon(area, azimuth_area_values[azimuth].inject(:+), 0.001)
      assert_in_epsilon(ufactor, azimuth_ufactor_x_area_values[azimuth].inject(:+) / azimuth_area_values[azimuth].inject(:+), 0.001)
      assert_in_epsilon(shgc, azimuth_shgc_x_area_values[azimuth].inject(:+) / azimuth_area_values[azimuth].inject(:+), 0.001)
    end
  end

  def _check_doors(hpxml, azimuth_values = {})
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

    assert_equal(azimuth_values.keys.size, azimuth_area_values.size)
    assert_equal(azimuth_values.keys.size, azimuth_rvalue_x_area_values.size)

    azimuth_values.each do |azimuth, values|
      area, rvalue = values
      assert_in_epsilon(area, azimuth_area_values[azimuth].inject(:+), 0.001)
      assert_in_epsilon(rvalue, azimuth_rvalue_x_area_values[azimuth].inject(:+) / azimuth_area_values[azimuth].inject(:+), 0.001)
    end
  end

  def _check_attic_ventilation(hpxml, sla)
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

  def _check_crawlspace_ventilation(hpxml, sla)
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
