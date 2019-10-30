require_relative '../../../workflow/tests/minitest_helper'
require 'openstudio'
require 'openstudio/ruleset/ShowRunnerOutput'
require 'minitest/autorun'
require_relative '../measure.rb'
require 'fileutils'

class EnclosureTest < MiniTest::Test
  def before_setup
    @root_path = File.absolute_path(File.join(File.dirname(__FILE__), "..", "..", ".."))
    @tmp_hpxml_path = File.join(@root_path, "workflow", "sample_files", "tmp.xml")
  end

  def after_teardown
    File.delete(@tmp_hpxml_path) if File.exists? @tmp_hpxml_path
  end

  def test_enclosure_infiltration_without_mech_vent
    hpxml_name = "base.xml"

    # Rated Home
    # For residences, without Whole-House Mechanical Ventilation Systems, the measured
    # infiltration rate but not less than 0.30 ACH
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_infiltration(hpxml_doc, 7.6)

    # Reference Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_infiltration(hpxml_doc, 7.09)

    # IAD Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentDesign)
    _check_infiltration(hpxml_doc, 3.0)

    # IAD Reference Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentReferenceHome)
    _check_infiltration(hpxml_doc, 6.67)
  end

  def test_enclosure_with_mech_vent
    # Create derivative file for testing
    hpxml_name = "base.xml"
    hpxml_doc = REXML::Document.new(File.read(File.join(@root_path, "workflow", "sample_files", hpxml_name)))

    # Add mech vent without flow rate
    HPXML.add_ventilation_fan(hpxml: hpxml_doc.elements["/HPXML"],
                              id: "MechanicalVentilation",
                              fan_type: "exhaust only",
                              tested_flow_rate: 300,
                              hours_in_operation: 24,
                              fan_power: 30.0)

    # Save new file
    hpxml_name = File.basename(@tmp_hpxml_path)
    XMLHelper.write_file(hpxml_doc, @tmp_hpxml_path)

    # Rated Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_infiltration(hpxml_doc, 3.0)

    # Reference Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_infiltration(hpxml_doc, 7.09)

    # IAD Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentDesign)
    _check_infiltration(hpxml_doc, 3.0)

    # IAD Reference Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentReferenceHome)
    _check_infiltration(hpxml_doc, 6.67)
  end

  def test_enclosure_roofs
    hpxml_name = "base.xml"

    # Rated Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_roofs(hpxml_doc, 1510, 2.3, 0.7, 0.92)

    # Reference Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_roofs(hpxml_doc, 1510, 2.3, 0.75, 0.9)

    # IAD Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentDesign)
    _check_roofs(hpxml_doc, 1300, 2.3, 0.7, 0.92)

    # IAD Reference Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentReferenceHome)
    _check_roofs(hpxml_doc, 1300, 2.3, 0.75, 0.9)

    hpxml_name = "base-atticroof-cathedral.xml"

    # Rated Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_roofs(hpxml_doc, 1510, 25.8, 0.7, 0.92)

    # Reference Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_roofs(hpxml_doc, 1510, 33.33, 0.75, 0.9)

    # IAD Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentDesign)
    _check_roofs(hpxml_doc, 1300, 25.8, 0.7, 0.92)

    # IAD Reference Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentReferenceHome)
    _check_roofs(hpxml_doc, 1300, 33.33, 0.75, 0.9)
  end

  def test_enclosure_walls
    hpxml_name = "base.xml"

    # Rated Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_walls(hpxml_doc, 1200 + 290, (23.0 + 4.0) / 2.0, 0.7, 0.92)

    # Reference Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_walls(hpxml_doc, 1200 + 290, (16.67 + 4.0) / 2.0, 0.75, 0.9)

    # IAD Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentDesign)
    _check_walls(hpxml_doc, 2355.52 + 290, (23.0 + 4.0) / 2.0, 0.7, 0.92)

    # IAD Reference Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentReferenceHome)
    _check_walls(hpxml_doc, 2355.52 + 290, (16.67 + 4.0) / 2.0, 0.75, 0.9)
  end

  def test_enclosure_rim_joists
    hpxml_name = "base.xml"

    # Rated Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_rim_joists(hpxml_doc, 116, 23.0, 0.7, 0.92)

    # Reference Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_rim_joists(hpxml_doc, 116, 16.67, 0.75, 0.9)

    # IAD Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentDesign)
    _check_rim_joists(hpxml_doc, nil, nil, nil, nil)

    # IAD Reference Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentReferenceHome)
    _check_rim_joists(hpxml_doc, nil, nil, nil, nil)
  end

  def test_enclosure_foundation_walls
    hpxml_name = "base.xml"

    # Rated Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_foundation_walls(hpxml_doc, 1200, 8.9, 8, 7)

    # Reference Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_foundation_walls(hpxml_doc, 1200, 16.95, 8, 7)

    # IAD Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentDesign)
    _check_foundation_walls(hpxml_doc, 277.12, 0, 2, 0)

    # IAD Reference Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentReferenceHome)
    _check_foundation_walls(hpxml_doc, 277.12, 0, 2, 0)
  end

  def test_enclosure_floors
    hpxml_name = "base.xml"

    # Rated Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_floors(hpxml_doc, 1350, 39.3)

    # Reference Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_floors(hpxml_doc, 1350, 33.33)

    # IAD Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentDesign)
    _check_floors(hpxml_doc, 1200 + 1200, (39.3 + 30.3) / 2.0)

    # IAD Reference Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentReferenceHome)
    _check_floors(hpxml_doc, 1200 + 1200, (33.33 + 30.3) / 2.0)
  end

  def test_enclosure_slabs
    hpxml_name = "base.xml"

    # Rated Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_slabs(hpxml_doc, 1350, 150, 0, 0, 0, 0, nil)

    # Reference Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_slabs(hpxml_doc, 1350, 150, 0, 0, 0, 0, nil)

    # IAD Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentDesign)
    _check_slabs(hpxml_doc, 1200, 138.6, 0, 0, 0, 0, nil)

    # IAD Reference Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentReferenceHome)
    _check_slabs(hpxml_doc, 1200, 138.6, 0, 0, 0, 0, nil)

    hpxml_name = "base-foundation-slab.xml"

    # Rated Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_slabs(hpxml_doc, 1350, 150, 0, 0, 999, 5, 0)

    # Reference Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_slabs(hpxml_doc, 1350, 150, 2, 10, 0, 0, 0)

    # IAD Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentDesign)
    _check_slabs(hpxml_doc, 1200, 138.6, 0, 0, 0, 0, nil)

    # IAD Reference Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentReferenceHome)
    _check_slabs(hpxml_doc, 1200, 138.6, 0, 0, 0, 0, nil)
  end

  def test_enclosure_windows
    hpxml_names = ["base.xml",
                   "base-atticroof-flat.xml",
                   "base-atticroof-vented.xml"]

    hpxml_names.each do |hpxml_name|
      # Rated Home
      hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
      _check_windows(hpxml_doc, { 0 => [54, 0.33, 0.45],
                                  180 => [54, 0.33, 0.45],
                                  90 => [36, 0.33, 0.45],
                                  270 => [36, 0.33, 0.45] })

      # Reference Home
      hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
      _check_windows(hpxml_doc, { 0 => [89.5, 0.35, 0.40],
                                  180 => [89.5, 0.35, 0.40],
                                  90 => [89.5, 0.35, 0.40],
                                  270 => [89.5, 0.35, 0.40] })

      # IAD Home
      hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentDesign)
      _check_windows(hpxml_doc, { 0 => [108, 0.33, 0.45],
                                  180 => [108, 0.33, 0.45],
                                  90 => [108, 0.33, 0.45],
                                  270 => [108, 0.33, 0.45] })

      # IAD Reference Home
      hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentReferenceHome)
      _check_windows(hpxml_doc, { 0 => [108, 0.35, 0.40],
                                  180 => [108, 0.35, 0.40],
                                  90 => [108, 0.35, 0.40],
                                  270 => [108, 0.35, 0.40] })
    end

    hpxml_names = ["base-foundation-ambient.xml",
                   "base-foundation-slab.xml",
                   "base-foundation-unconditioned-basement.xml",
                   "base-foundation-unvented-crawlspace.xml",
                   "base-foundation-vented-crawlspace.xml"]

    hpxml_names.each do |hpxml_name|
      # Rated Home
      hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
      _check_windows(hpxml_doc, { 0 => [54, 0.33, 0.45],
                                  180 => [54, 0.33, 0.45],
                                  90 => [36, 0.33, 0.45],
                                  270 => [36, 0.33, 0.45] })

      # Reference Home
      hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
      _check_windows(hpxml_doc, { 0 => [60.75, 0.35, 0.40],
                                  180 => [60.75, 0.35, 0.40],
                                  90 => [60.75, 0.35, 0.40],
                                  270 => [60.75, 0.35, 0.40] })

      # IAD Home
      hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentDesign)
      _check_windows(hpxml_doc, { 0 => [108, 0.33, 0.45],
                                  180 => [108, 0.33, 0.45],
                                  90 => [108, 0.33, 0.45],
                                  270 => [108, 0.33, 0.45] })

      # IAD Reference Home
      hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentReferenceHome)
      _check_windows(hpxml_doc, { 0 => [108, 0.35, 0.40],
                                  180 => [108, 0.35, 0.40],
                                  90 => [108, 0.35, 0.40],
                                  270 => [108, 0.35, 0.40] })
    end

    hpxml_name = "base-atticroof-cathedral.xml"

    # Rated Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_windows(hpxml_doc, { 0 => [54, 0.33, 0.45],
                                180 => [54, 0.33, 0.45],
                                90 => [66, 0.33, 0.45],
                                270 => [66, 0.33, 0.45] })

    # Reference Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_windows(hpxml_doc, { 0 => [93.5, 0.35, 0.40],
                                180 => [93.5, 0.35, 0.40],
                                90 => [93.5, 0.35, 0.40],
                                270 => [93.5, 0.35, 0.40] })

    # IAD Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentDesign)
    _check_windows(hpxml_doc, { 0 => [108, 0.33, 0.45],
                                180 => [108, 0.33, 0.45],
                                90 => [108, 0.33, 0.45],
                                270 => [108, 0.33, 0.45] })

    # IAD Reference Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentReferenceHome)
    _check_windows(hpxml_doc, { 0 => [108, 0.35, 0.40],
                                180 => [108, 0.35, 0.40],
                                90 => [108, 0.35, 0.40],
                                270 => [108, 0.35, 0.40] })

    hpxml_name = "base-atticroof-conditioned.xml"

    # Rated Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_windows(hpxml_doc, { 0 => [54, 0.33, 0.45],
                                180 => [54, 0.33, 0.45],
                                90 => [66, 0.33, 0.45],
                                270 => [66, 0.33, 0.45] })

    # Reference Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_windows(hpxml_doc, { 0 => [128.6, 0.35, 0.40],
                                180 => [128.6, 0.35, 0.40],
                                90 => [128.6, 0.35, 0.40],
                                270 => [128.6, 0.35, 0.40] })

    # IAD Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentDesign)
    _check_windows(hpxml_doc, { 0 => [108, 0.33, 0.45],
                                180 => [108, 0.33, 0.45],
                                90 => [108, 0.33, 0.45],
                                270 => [108, 0.33, 0.45] })

    # IAD Reference Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentReferenceHome)
    _check_windows(hpxml_doc, { 0 => [108, 0.35, 0.40],
                                180 => [108, 0.35, 0.40],
                                90 => [108, 0.35, 0.40],
                                270 => [108, 0.35, 0.40] })

    hpxml_name = "base-enclosure-adiabatic-surfaces.xml"

    # Rated Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_windows(hpxml_doc, { 0 => [54, 0.33, 0.45],
                                180 => [54, 0.33, 0.45],
                                90 => [36, 0.33, 0.45],
                                270 => [36, 0.33, 0.45] })

    # Reference Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_windows(hpxml_doc, { 0 => [40.7, 0.35, 0.40],
                                180 => [40.7, 0.35, 0.40],
                                90 => [40.7, 0.35, 0.40],
                                270 => [40.7, 0.35, 0.40] })

    # IAD Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentDesign)
    _check_windows(hpxml_doc, { 0 => [108, 0.33, 0.45],
                                180 => [108, 0.33, 0.45],
                                90 => [108, 0.33, 0.45],
                                270 => [108, 0.33, 0.45] })

    # IAD Reference Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentReferenceHome)
    _check_windows(hpxml_doc, { 0 => [108, 0.35, 0.40],
                                180 => [108, 0.35, 0.40],
                                90 => [108, 0.35, 0.40],
                                270 => [108, 0.35, 0.40] })
  end

  def test_enclosure_skylights
    hpxml_name = "base.xml"

    # Rated Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_skylights(hpxml_doc)

    # Reference Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_skylights(hpxml_doc)

    # IAD Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentDesign)
    _check_skylights(hpxml_doc)

    # IAD Reference Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentReferenceHome)
    _check_skylights(hpxml_doc)

    hpxml_name = "base-enclosure-skylights.xml"

    # Rated Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_skylights(hpxml_doc, { 0 => [15, 0.33, 0.45],
                                  180 => [15, 0.35, 0.47] })

    # Reference Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_skylights(hpxml_doc)

    # IAD Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentDesign)
    _check_skylights(hpxml_doc, { 0 => [15, 0.33, 0.45],
                                  180 => [15, 0.35, 0.47] })

    # IAD Reference Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentReferenceHome)
    _check_skylights(hpxml_doc)
  end

  def test_enclosure_overhangs
    hpxml_name = "base.xml"

    # Rated Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_overhangs(hpxml_doc)

    # Reference Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_overhangs(hpxml_doc)

    # IAD Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentDesign)
    _check_overhangs(hpxml_doc)

    # IAD Reference Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentReferenceHome)
    _check_overhangs(hpxml_doc)

    hpxml_name = "base-enclosure-overhangs.xml"

    # Rated Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_overhangs(hpxml_doc, [2.5, 0, 4],
                     [1.5, 2, 6],
                     [1.5, 2, 7])

    # Reference Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_overhangs(hpxml_doc)

    # IAD Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentDesign)
    _check_overhangs(hpxml_doc)

    # IAD Reference Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentReferenceHome)
    _check_overhangs(hpxml_doc)
  end

  def test_enclosure_doors
    hpxml_name = "base.xml"

    # Rated Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_doors(hpxml_doc, { 0 => [40, 4.4],
                              180 => [40, 4.4] })

    # Reference Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_doors(hpxml_doc, { 0 => [40, 2.86] })

    # IAD Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentDesign)
    _check_doors(hpxml_doc, { 0 => [20, 4.4],
                              180 => [20, 4.4] })

    # IAD Reference Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentReferenceHome)
    _check_doors(hpxml_doc, { 0 => [40, 2.86] })
  end

  def test_enclosure_attic_ventilation
    hpxml_names = ["base.xml",
                   "base-atticroof-conditioned.xml"]

    hpxml_names.each do |hpxml_name|
      # Rated Home
      hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
      _check_attic_ventilation(hpxml_doc, nil)

      # Reference Home
      hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
      _check_attic_ventilation(hpxml_doc, 1.0 / 300.0)

      # IAD Home
      hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentDesign)
      _check_attic_ventilation(hpxml_doc, nil)

      # IAD Reference Home
      hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentReferenceHome)
      _check_attic_ventilation(hpxml_doc, 1.0 / 300.0)
    end

    hpxml_names = ["base-atticroof-cathedral.xml",
                   "base-atticroof-flat.xml"]

    hpxml_names.each do |hpxml_name|
      # Rated Home
      hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
      _check_attic_ventilation(hpxml_doc, nil)

      # Reference Home
      hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
      _check_attic_ventilation(hpxml_doc, nil)

      # IAD Home
      hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentDesign)
      _check_attic_ventilation(hpxml_doc, nil)

      # IAD Reference Home
      hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentReferenceHome)
      _check_attic_ventilation(hpxml_doc, nil)
    end

    hpxml_name = "base-atticroof-vented.xml"

    # Rated Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_attic_ventilation(hpxml_doc, 0.003)

    # Reference Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_attic_ventilation(hpxml_doc, 1.0 / 300.0)

    # IAD Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentDesign)
    _check_attic_ventilation(hpxml_doc, 0.003)

    # IAD Reference Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentReferenceHome)
    _check_attic_ventilation(hpxml_doc, 1.0 / 300.0)
  end

  def test_enclosure_crawlspace_ventilation
    hpxml_names = ["base-foundation-unvented-crawlspace.xml",
                   "base-foundation-multiple.xml"]

    hpxml_names.each do |hpxml_name|
      # Rated Home
      hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
      _check_crawlspace_ventilation(hpxml_doc, nil)

      # Reference Home
      hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
      _check_crawlspace_ventilation(hpxml_doc, 1.0 / 150.0)

      # IAD Home
      hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentDesign)
      _check_crawlspace_ventilation(hpxml_doc, 1.0 / 150.0)

      # IAD Reference Home
      hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentReferenceHome)
      _check_crawlspace_ventilation(hpxml_doc, 1.0 / 150.0)
    end

    hpxml_names = ["base.xml",
                   "base-foundation-slab.xml",
                   "base-foundation-unconditioned-basement.xml",
                   "base-foundation-ambient.xml"]

    hpxml_names.each do |hpxml_name|
      # Rated Home
      hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
      _check_crawlspace_ventilation(hpxml_doc, nil)

      # Reference Home
      hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
      _check_crawlspace_ventilation(hpxml_doc, nil)

      # IAD Home
      hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentDesign)
      _check_crawlspace_ventilation(hpxml_doc, 1.0 / 150.0)

      # IAD Reference Home
      hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentReferenceHome)
      _check_crawlspace_ventilation(hpxml_doc, 1.0 / 150.0)
    end

    hpxml_name = "base-foundation-vented-crawlspace.xml"

    # Rated Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_crawlspace_ventilation(hpxml_doc, 0.00667)

    # Reference Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_crawlspace_ventilation(hpxml_doc, 1.0 / 150.0)

    # IAD Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentDesign)
    _check_crawlspace_ventilation(hpxml_doc, 1.0 / 150.0)

    # IAD Reference Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentReferenceHome)
    _check_crawlspace_ventilation(hpxml_doc, 1.0 / 150.0)
  end

  def _test_measure(hpxml_name, calc_type)
    args_hash = {}
    args_hash['hpxml_path'] = File.join(@root_path, "workflow", "sample_files", hpxml_name)
    args_hash['weather_dir'] = File.join(@root_path, "weather")
    args_hash['hpxml_output_path'] = File.join(File.dirname(__FILE__), "#{calc_type}.xml")
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
    assert_equal("Success", result.value.valueName)
    assert(File.exists? args_hash['hpxml_output_path'])

    hpxml_doc = REXML::Document.new(File.read(args_hash['hpxml_output_path']))
    File.delete(args_hash['hpxml_output_path'])

    return hpxml_doc
  end

  def _check_infiltration(hpxml_doc, ach50)
    assert_in_epsilon(ach50, Float(hpxml_doc.elements["/HPXML/Building/BuildingDetails/Enclosure/AirInfiltration/AirInfiltrationMeasurement[HousePressure='50']/BuildingAirLeakage[UnitofMeasure='ACH']/AirLeakage"].text), 0.01)
  end

  def _check_roofs(hpxml_doc, area, rvalue, sabs, emit)
    area_values = []
    rvalue_values = []
    sabs_values = []
    emit_values = []
    hpxml_doc.elements.each("/HPXML/Building/BuildingDetails/Enclosure/Roofs/Roof") do |roof|
      area_values << Float(roof.elements["Area"].text)
      rvalue_values << Float(roof.elements["Insulation/AssemblyEffectiveRValue"].text)
      sabs_values << Float(roof.elements["SolarAbsorptance"].text)
      emit_values << Float(roof.elements["Emittance"].text)
    end

    assert_in_epsilon(area, area_values.inject(:+), 0.001)
    assert_in_epsilon(rvalue, rvalue_values.inject(:+) / rvalue_values.size, 0.001)
    assert_in_epsilon(sabs, sabs_values.inject(:+) / sabs_values.size, 0.001)
    assert_in_epsilon(emit, emit_values.inject(:+) / emit_values.size, 0.001)
  end

  def _check_walls(hpxml_doc, area, rvalue, sabs, emit)
    area_values = []
    rvalue_values = []
    sabs_values = []
    emit_values = []
    hpxml_doc.elements.each("/HPXML/Building/BuildingDetails/Enclosure/Walls/Wall") do |wall|
      area_values << Float(wall.elements["Area"].text)
      rvalue_values << Float(wall.elements["Insulation/AssemblyEffectiveRValue"].text)
      sabs_values << Float(wall.elements["SolarAbsorptance"].text)
      emit_values << Float(wall.elements["Emittance"].text)
    end

    assert_in_epsilon(area, area_values.inject(:+), 0.001)
    assert_in_epsilon(rvalue, rvalue_values.inject(:+) / rvalue_values.size, 0.001)
    assert_in_epsilon(sabs, sabs_values.inject(:+) / sabs_values.size, 0.001)
    assert_in_epsilon(emit, emit_values.inject(:+) / emit_values.size, 0.001)
  end

  def _check_rim_joists(hpxml_doc, area, rvalue, sabs, emit)
    area_values = []
    rvalue_values = []
    sabs_values = []
    emit_values = []
    hpxml_doc.elements.each("/HPXML/Building/BuildingDetails/Enclosure/RimJoists/RimJoist") do |rim_joist|
      area_values << Float(rim_joist.elements["Area"].text)
      rvalue_values << Float(rim_joist.elements["Insulation/AssemblyEffectiveRValue"].text)
      sabs_values << Float(rim_joist.elements["SolarAbsorptance"].text)
      emit_values << Float(rim_joist.elements["Emittance"].text)
    end

    if area.nil?
      assert_equal(0, area_values.size)
    else
      assert_in_epsilon(area, area_values.inject(:+), 0.001)
    end
    if rvalue.nil?
      assert_equal(0, rvalue_values.size)
    else
      assert_in_epsilon(rvalue, rvalue_values.inject(:+) / rvalue_values.size, 0.001)
    end
    if sabs.nil?
      assert_equal(0, sabs_values.size)
    else
      assert_in_epsilon(sabs, sabs_values.inject(:+) / sabs_values.size, 0.001)
    end
    if emit.nil?
      assert_equal(0, emit_values.size)
    else
      assert_in_epsilon(emit, emit_values.inject(:+) / emit_values.size, 0.001)
    end
  end

  def _check_foundation_walls(hpxml_doc, area, rvalue, height, depth_below_grade)
    area_values = []
    rvalue_values = []
    height_values = []
    depth_bg_values = []
    hpxml_doc.elements.each("/HPXML/Building/BuildingDetails/Enclosure/FoundationWalls/FoundationWall") do |fnd_wall|
      area_values << Float(fnd_wall.elements["Area"].text)
      if not fnd_wall.elements["Insulation/AssemblyEffectiveRValue"].nil?
        rvalue_values << Float(fnd_wall.elements["Insulation/AssemblyEffectiveRValue"].text)
      else
        rvalue_values << Float(fnd_wall.elements["Insulation/Layer/NominalRValue"].text)
      end
      height_values << Float(fnd_wall.elements["Height"].text)
      depth_bg_values << Float(fnd_wall.elements["DepthBelowGrade"].text)
    end

    assert_in_epsilon(area, area_values.inject(:+), 0.001)
    assert_in_epsilon(rvalue, rvalue_values.inject(:+) / rvalue_values.size, 0.001)
    assert_in_epsilon(height, height_values.inject(:+) / height_values.size, 0.001)
    assert_in_epsilon(depth_below_grade, depth_bg_values.inject(:+) / depth_bg_values.size, 0.001)
  end

  def _check_floors(hpxml_doc, area, rvalue)
    area_values = []
    rvalue_values = []
    hpxml_doc.elements.each("/HPXML/Building/BuildingDetails/Enclosure/FrameFloors/FrameFloor") do |floor|
      area_values << Float(floor.elements["Area"].text)
      rvalue_values << Float(floor.elements["Insulation/AssemblyEffectiveRValue"].text)
    end

    assert_in_epsilon(area, area_values.inject(:+), 0.001)
    assert_in_epsilon(rvalue, rvalue_values.inject(:+) / rvalue_values.size, 0.001)
  end

  def _check_slabs(hpxml_doc, area, exp_perim, perim_ins_depth, perim_ins_r, under_ins_width, under_ins_r, depth_below_grade)
    area_values = []
    exp_perim_values = []
    perim_ins_depth_values = []
    perim_ins_r_values = []
    under_ins_width_values = []
    under_ins_r_values = []
    depth_bg_values = []
    hpxml_doc.elements.each("/HPXML/Building/BuildingDetails/Enclosure/Slabs/Slab") do |slab|
      area_values << Float(slab.elements["Area"].text)
      exp_perim_values << Float(slab.elements["ExposedPerimeter"].text)
      perim_ins_depth_values << Float(slab.elements["PerimeterInsulationDepth"].text)
      perim_ins_r_values << Float(slab.elements["PerimeterInsulation/Layer/NominalRValue"].text)
      if not slab.elements["UnderSlabInsulationWidth"].nil?
        under_ins_width_values << Float(slab.elements["UnderSlabInsulationWidth"].text)
      elsif slab.elements["UnderSlabInsulationSpansEntireSlab"].text == "true"
        under_ins_width_values << 999
      end
      under_ins_r_values << Float(slab.elements["UnderSlabInsulation/Layer/NominalRValue"].text)
      depth_bg_values << Float(slab.elements["DepthBelowGrade"].text) unless slab.elements["DepthBelowGrade"].nil?
    end

    assert_in_epsilon(area, area_values.inject(:+), 0.001)
    assert_in_epsilon(exp_perim, exp_perim_values.inject(:+) / exp_perim_values.size, 0.001)
    assert_in_epsilon(perim_ins_depth, perim_ins_depth_values.inject(:+) / perim_ins_depth_values.size, 0.001)
    assert_in_epsilon(perim_ins_r, perim_ins_r_values.inject(:+) / perim_ins_r_values.size, 0.001)
    assert_in_epsilon(under_ins_width, under_ins_width_values.inject(:+) / under_ins_width_values.size, 0.001)
    assert_in_epsilon(under_ins_r, under_ins_r_values.inject(:+) / under_ins_r_values.size, 0.001)
    if depth_below_grade.nil?
      assert(depth_bg_values.empty?)
    else
      assert_in_epsilon(depth_below_grade, depth_bg_values.inject(:+) / depth_bg_values.size, 0.001)
    end
  end

  def _check_windows(hpxml_doc, azimuth_values = {})
    azimuth_area_values = {}
    azimuth_ufactor_values = {}
    azimuth_shgc_values = {}
    hpxml_doc.elements.each("/HPXML/Building/BuildingDetails/Enclosure/Windows/Window") do |window|
      azimuth = Integer(window.elements["Azimuth"].text)

      # Init if needed
      azimuth_area_values[azimuth] = [] if azimuth_area_values[azimuth].nil?
      azimuth_ufactor_values[azimuth] = [] if azimuth_ufactor_values[azimuth].nil?
      azimuth_shgc_values[azimuth] = [] if azimuth_shgc_values[azimuth].nil?

      # Update
      azimuth_area_values[azimuth] << Float(window.elements["Area"].text)
      azimuth_ufactor_values[azimuth] << Float(window.elements["UFactor"].text)
      azimuth_shgc_values[azimuth] << Float(window.elements["SHGC"].text)
    end

    assert_equal(azimuth_values.keys.size, azimuth_area_values.size)
    assert_equal(azimuth_values.keys.size, azimuth_ufactor_values.size)
    assert_equal(azimuth_values.keys.size, azimuth_shgc_values.size)

    azimuth_values.each do |azimuth, values|
      area, ufactor, shgc = values
      assert_in_epsilon(area, azimuth_area_values[azimuth].inject(:+), 0.001)
      assert_in_epsilon(ufactor, azimuth_ufactor_values[azimuth].inject(:+) / azimuth_ufactor_values[azimuth].size, 0.001)
      assert_in_epsilon(shgc, azimuth_shgc_values[azimuth].inject(:+) / azimuth_shgc_values[azimuth].size, 0.001)
    end
  end

  def _check_overhangs(hpxml_doc, *overhangs)
    num_overhangs = 0
    hpxml_doc.elements.each("/HPXML/Building/BuildingDetails/Enclosure/Windows/Window") do |window|
      next if window.elements["Overhangs"].nil?

      overhang_depth, overhang_top, overhang_bottom = overhangs[num_overhangs]
      assert_equal(overhang_depth, Float(window.elements["Overhangs/Depth"].text))
      assert_equal(overhang_top, Float(window.elements["Overhangs/DistanceToTopOfWindow"].text))
      assert_equal(overhang_bottom, Float(window.elements["Overhangs/DistanceToBottomOfWindow"].text))
      num_overhangs += 1
    end
    assert_equal(overhangs.size, num_overhangs)
  end

  def _check_skylights(hpxml_doc, azimuth_values = {})
    azimuth_area_values = {}
    azimuth_ufactor_values = {}
    azimuth_shgc_values = {}
    hpxml_doc.elements.each("/HPXML/Building/BuildingDetails/Enclosure/Skylights/Skylight") do |skylight|
      azimuth = Integer(skylight.elements["Azimuth"].text)

      # Init if needed
      azimuth_area_values[azimuth] = [] if azimuth_area_values[azimuth].nil?
      azimuth_ufactor_values[azimuth] = [] if azimuth_ufactor_values[azimuth].nil?
      azimuth_shgc_values[azimuth] = [] if azimuth_shgc_values[azimuth].nil?

      # Update
      azimuth_area_values[azimuth] << Float(skylight.elements["Area"].text)
      azimuth_ufactor_values[azimuth] << Float(skylight.elements["UFactor"].text)
      azimuth_shgc_values[azimuth] << Float(skylight.elements["SHGC"].text)
    end

    assert_equal(azimuth_values.keys.size, azimuth_area_values.size)
    assert_equal(azimuth_values.keys.size, azimuth_ufactor_values.size)
    assert_equal(azimuth_values.keys.size, azimuth_shgc_values.size)

    azimuth_values.each do |azimuth, values|
      area, ufactor, shgc = values
      assert_in_epsilon(area, azimuth_area_values[azimuth].inject(:+), 0.001)
      assert_in_epsilon(ufactor, azimuth_ufactor_values[azimuth].inject(:+) / azimuth_ufactor_values[azimuth].size, 0.001)
      assert_in_epsilon(shgc, azimuth_shgc_values[azimuth].inject(:+) / azimuth_shgc_values[azimuth].size, 0.001)
    end
  end

  def _check_doors(hpxml_doc, azimuth_values = {})
    azimuth_area_values = {}
    azimuth_rvalue_values = {}
    hpxml_doc.elements.each("/HPXML/Building/BuildingDetails/Enclosure/Doors/Door") do |door|
      azimuth = Integer(door.elements["Azimuth"].text)

      # Init if needed
      azimuth_area_values[azimuth] = [] if azimuth_area_values[azimuth].nil?
      azimuth_rvalue_values[azimuth] = [] if azimuth_rvalue_values[azimuth].nil?

      # Update
      azimuth_area_values[azimuth] << Float(door.elements["Area"].text)
      azimuth_rvalue_values[azimuth] << Float(door.elements["RValue"].text)
    end

    assert_equal(azimuth_values.keys.size, azimuth_area_values.size)
    assert_equal(azimuth_values.keys.size, azimuth_rvalue_values.size)

    azimuth_values.each do |azimuth, values|
      area, rvalue = values
      assert_in_epsilon(area, azimuth_area_values[azimuth].inject(:+), 0.001)
      assert_in_epsilon(rvalue, azimuth_rvalue_values[azimuth].inject(:+) / azimuth_rvalue_values[azimuth].size, 0.001)
    end
  end

  def _check_attic_ventilation(hpxml_doc, sla)
    sla_element = hpxml_doc.elements["/HPXML/Building/BuildingDetails/Enclosure/Attics/Attic[AtticType/Attic[Vented='true']]/VentilationRate[UnitofMeasure='SLA']/Value"]
    if sla.nil?
      assert_nil(sla_element)
    else
      assert_in_epsilon(sla, Float(sla_element.text))
    end
  end

  def _check_crawlspace_ventilation(hpxml_doc, sla)
    sla_element = hpxml_doc.elements["/HPXML/Building/BuildingDetails/Enclosure/Foundations/Foundation[FoundationType/Crawlspace[Vented='true']]/VentilationRate[UnitofMeasure='SLA']/Value"]
    if sla.nil?
      assert_nil(sla_element)
    else
      assert_in_epsilon(sla, Float(sla_element.text))
    end
  end
end
