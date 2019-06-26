require_relative '../../../workflow/tests/minitest_helper'
require 'openstudio'
require 'openstudio/ruleset/ShowRunnerOutput'
require 'minitest/autorun'
require_relative '../measure.rb'
require 'fileutils'

class MechVentTest < MiniTest::Test
  def test_mech_vent
    hpxml_name = "base.xml"

    # Reference Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_mech_vent(hpxml_doc, "exhaust only", 37.0, 24, 0.0) # Should have airflow but not fan energy

    # Rated Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_mech_vent(hpxml_doc)

    # IAD
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentDesign)
    _check_mech_vent(hpxml_doc, "balanced", 60.0, 24, 42.0)

    # IAD Reference
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentReferenceHome)
    _check_mech_vent(hpxml_doc, "balanced", 34.0, 24, 42.0)
  end

  def test_mech_vent_below_ashrae_622
    # Test Rated Home:
    # For residences with Whole-House Mechanical Ventilation Systems, the measured infiltration rate
    # combined with the time-averaged Whole-House Mechanical Ventilation System rate, which shall
    # not be less than 0.03 x CFA + 7.5 x (Nbr+1) cfm

    # Create derivative file for testing
    hpxml_name = "base.xml"
    root_path = File.absolute_path(File.join(File.dirname(__FILE__), "..", "..", ".."))
    hpxml_path = File.join(root_path, "workflow", "sample_files", hpxml_name)
    hpxml_doc = REXML::Document.new(File.read(hpxml_path))

    # Remove mech vent
    mech_vent = hpxml_doc.elements["/HPXML/Building/BuildingDetails/Systems/MechanicalVentilation/VentilationFans/VentilationFan[UsedForWholeBuildingVentilation='true']"]
    mech_vent.parent.elements.delete mech_vent unless mech_vent.nil?

    # Set mech vent
    HPXML.add_ventilation_fan(hpxml: hpxml_doc.elements["/HPXML"],
                              id: "VentilationFan",
                              fan_type: "exhaust only",
                              rated_flow_rate: 1.0,
                              hours_in_operation: 1,
                              fan_power: 1.0)

    # Save new file
    hpxml_name = "base-test.xml"
    hpxml_path = File.join(root_path, "workflow", "sample_files", hpxml_name)
    XMLHelper.write_file(hpxml_doc, hpxml_path)

    # Rated Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    File.delete(hpxml_path)

    # Test that mech vent has been increased
    mech_vent = hpxml_doc.elements["/HPXML/Building/BuildingDetails/Systems/MechanicalVentilation/VentilationFans/VentilationFan[UsedForWholeBuildingVentilation='true']"]
    mech_vent_values = HPXML.get_ventilation_fan_values(ventilation_fan: mech_vent)
    assert_in_epsilon(mech_vent_values[:rated_flow_rate], 76.2, 0.01)
    assert_in_epsilon(mech_vent_values[:fan_power], 76.2, 0.01)
    assert_equal(mech_vent_values[:hours_in_operation], 24)
  end

  def test_mech_vent_exhaust
    hpxml_name = "base-mechvent-exhaust.xml"

    # Reference Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_mech_vent(hpxml_doc, "exhaust only", 37.0, 24, 26.7)

    # Rated Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_mech_vent(hpxml_doc, "exhaust only", 111.0, 24, 30.0)

    # IAD
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentDesign)
    _check_mech_vent(hpxml_doc, "balanced", 60.0, 24, 42.0)

    # IAD Reference
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentReferenceHome)
    _check_mech_vent(hpxml_doc, "balanced", 34.0, 24, 42.0)
  end

  def test_mech_vent_supply
    hpxml_name = "base-mechvent-supply.xml"

    # Reference Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_mech_vent(hpxml_doc, "supply only", 37.0, 24, 26.7)

    # Rated Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_mech_vent(hpxml_doc, "supply only", 111.0, 24, 30.0)

    # IAD
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentDesign)
    _check_mech_vent(hpxml_doc, "balanced", 60.0, 24, 42.0)

    # IAD Reference
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentReferenceHome)
    _check_mech_vent(hpxml_doc, "balanced", 34.0, 24, 42.0)
  end

  def test_mech_vent_balanced
    hpxml_name = "base-mechvent-balanced.xml"

    # Reference Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_mech_vent(hpxml_doc, "balanced", 37.0, 24, 53.3)

    # Rated Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_mech_vent(hpxml_doc, "balanced", 111.0, 24, 60.0)

    # IAD
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentDesign)
    _check_mech_vent(hpxml_doc, "balanced", 60.0, 24, 42.0)

    # IAD Reference
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentReferenceHome)
    _check_mech_vent(hpxml_doc, "balanced", 34.0, 24, 42.0)
  end

  def test_mech_vent_erv
    hpxml_name = "base-mechvent-erv.xml"

    # Reference Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_mech_vent(hpxml_doc, "balanced", 37.0, 24, 76.2)

    # Rated Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_mech_vent(hpxml_doc, "energy recovery ventilator", 111.0, 24, 60.0, 0.72, 0.48)

    # IAD
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentDesign)
    _check_mech_vent(hpxml_doc, "balanced", 60.0, 24, 42.0)

    # IAD Reference
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentReferenceHome)
    _check_mech_vent(hpxml_doc, "balanced", 34.0, 24, 42.0)
  end

  def test_mech_vent_hrv
    hpxml_name = "base-mechvent-hrv.xml"

    # Reference Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_mech_vent(hpxml_doc, "balanced", 37.0, 24, 76.2)

    # Rated Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_mech_vent(hpxml_doc, "heat recovery ventilator", 111.0, 24, 60.0, 0.72)

    # IAD
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentDesign)
    _check_mech_vent(hpxml_doc, "balanced", 60.0, 24, 42.0)

    # IAD Reference
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentReferenceHome)
    _check_mech_vent(hpxml_doc, "balanced", 34.0, 24, 42.0)
  end

  def test_mech_vent_cfis
    hpxml_name = "base-mechvent-cfis.xml"

    # Reference Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_mech_vent(hpxml_doc, "supply only", 37.0, 24, 26.7)

    # Rated Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_mech_vent(hpxml_doc, "central fan integrated supply", 330.0, 8, 300.0)

    # IAD
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentDesign)
    _check_mech_vent(hpxml_doc, "balanced", 60.0, 24, 42.0)

    # IAD Reference
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentReferenceHome)
    _check_mech_vent(hpxml_doc, "balanced", 34.0, 24, 42.0)
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
    show_output(result) unless result.value.valueName == 'Success'

    # assert that it ran correctly
    assert_equal("Success", result.value.valueName)
    assert(File.exists? args_hash['hpxml_output_path'])

    hpxml_doc = REXML::Document.new(File.read(args_hash['hpxml_output_path']))
    File.delete(args_hash['hpxml_output_path'])

    return hpxml_doc
  end

  def _check_mech_vent(hpxml_doc, fantype = nil, flowrate = nil, hours = nil, power = nil, sre = nil, tre = nil)
    mechvent = hpxml_doc.elements["/HPXML/Building/BuildingDetails/Systems/MechanicalVentilation/VentilationFans/VentilationFan[UsedForWholeBuildingVentilation='true']"]
    if not fantype.nil?
      assert_equal(fantype, mechvent.elements["FanType"].text)
      assert_in_epsilon(flowrate, Float(mechvent.elements["RatedFlowRate"].text), 0.01)
      assert_equal(hours, Float(mechvent.elements["HoursInOperation"].text))
      assert_in_epsilon(power, Float(mechvent.elements["FanPower"].text), 0.01)
      if sre.nil?
        assert_nil(mechvent.elements["SensibleRecoveryEfficiency"])
      else
        assert_equal(sre, Float(mechvent.elements["SensibleRecoveryEfficiency"].text))
      end
      if tre.nil?
        assert_nil(mechvent.elements["TotalRecoveryEfficiency"])
      else
        assert_equal(tre, Float(mechvent.elements["TotalRecoveryEfficiency"].text))
      end
    else
      assert_nil(mechvent)
    end
  end
end
