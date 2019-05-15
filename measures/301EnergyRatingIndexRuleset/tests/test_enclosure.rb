require_relative '../../../workflow/tests/minitest_helper'
require 'openstudio'
require 'openstudio/ruleset/ShowRunnerOutput'
require 'minitest/autorun'
require_relative '../measure.rb'
require 'fileutils'

class EnclosureTest < MiniTest::Test
  def test_enclosure_infiltration
    hpxml_name = "base.xml"

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

    hpxml_names = ["base-foundation-pier-beam.xml",
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

  def _test_measure(hpxml_name, calc_type)
    root_path = File.absolute_path(File.join(File.dirname(__FILE__), "..", "..", ".."))
    args_hash = {}
    args_hash['hpxml_path'] = File.join(root_path, "workflow", "sample_files", hpxml_name)
    args_hash['weather_dir'] = File.join(root_path, "weather")
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
    # show_output(result)

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
end
