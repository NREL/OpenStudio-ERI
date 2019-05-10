require_relative '../../../workflow/tests/minitest_helper'
require 'openstudio'
require 'openstudio/ruleset/ShowRunnerOutput'
require 'minitest/autorun'
require_relative '../measure.rb'
require 'fileutils'

class LightingTest < MiniTest::Test
  def test_lighting
    hpxml_name = "base.xml"

    # Reference Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_lighting(hpxml_doc, 0.1, 0.0, 0.0, 0.0, 0.0, 0.0)

    # Rated Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_lighting(hpxml_doc, 0.5, 0.5, 0.5, 0.25, 0.25, 0.25)

    # IAD
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentDesign)
    _check_lighting(hpxml_doc, 0.75, 0.75, 0.75, 0.0, 0.0, 0.0)

    # IAD Reference
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentReferenceHome)
    _check_lighting(hpxml_doc, 0.1, 0.0, 0.0, 0.0, 0.0, 0.0)
  end

  def test_lighting_pre_addendum_g
    hpxml_name = "base-addenda-exclude-g.xml"

    # Reference Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_lighting(hpxml_doc, 0.1, 0.0, 0.0, 0.0, 0.0, 0.0)

    # Rated Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_lighting(hpxml_doc, 0.5, 0.5, 0.5, 0.25, 0.25, 0.25)

    # IAD
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentDesign)
    _check_lighting(hpxml_doc, 0.75, 0.75, 0.75, 0.0, 0.0, 0.0)

    # IAD Reference
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentReferenceHome)
    _check_lighting(hpxml_doc, 0.1, 0.0, 0.0, 0.0, 0.0, 0.0)
  end

  def test_ceiling_fans
    hpxml_name = "base-misc-ceiling-fans.xml"

    medium_cfm = 3000.0

    # Reference Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    avg_fan_w = 42.6
    _check_ceiling_fans(hpxml_doc, medium_cfm / avg_fan_w, 4)

    # Rated Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    avg_fan_w = 30.0
    _check_ceiling_fans(hpxml_doc, medium_cfm / avg_fan_w, 4)

    # IAD
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentDesign)
    avg_fan_w = 42.6
    _check_ceiling_fans(hpxml_doc, medium_cfm / avg_fan_w, 4)

    # IAD Reference
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentReferenceHome)
    avg_fan_w = 42.6
    _check_ceiling_fans(hpxml_doc, medium_cfm / avg_fan_w, 4)
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

  def _check_lighting(hpxml_doc, fFI_int, fFI_ext, fFI_grg, fFII_int, fFII_ext, fFII_grg)
    ltg = hpxml_doc.elements["/HPXML/Building/BuildingDetails/Lighting"]
    assert_in_epsilon(Float(ltg.elements["LightingGroup[ThirdPartyCertification='ERI Tier I' and Location='interior']/FractionofUnitsInLocation"].text), fFI_int, 0.01)
    assert_in_epsilon(Float(ltg.elements["LightingGroup[ThirdPartyCertification='ERI Tier I' and Location='exterior']/FractionofUnitsInLocation"].text), fFI_ext, 0.01)
    assert_in_epsilon(Float(ltg.elements["LightingGroup[ThirdPartyCertification='ERI Tier I' and Location='garage']/FractionofUnitsInLocation"].text), fFI_grg, 0.01)
    assert_in_epsilon(Float(ltg.elements["LightingGroup[ThirdPartyCertification='ERI Tier II' and Location='interior']/FractionofUnitsInLocation"].text), fFII_int, 0.01)
    assert_in_epsilon(Float(ltg.elements["LightingGroup[ThirdPartyCertification='ERI Tier II' and Location='exterior']/FractionofUnitsInLocation"].text), fFII_ext, 0.01)
    assert_in_epsilon(Float(ltg.elements["LightingGroup[ThirdPartyCertification='ERI Tier II' and Location='garage']/FractionofUnitsInLocation"].text), fFII_grg, 0.01)
  end

  def _check_ceiling_fans(hpxml_doc, cfm_per_w, quantity)
    cf = hpxml_doc.elements["/HPXML/Building/BuildingDetails/Lighting/CeilingFan"]
    if cfm_per_w.nil?
      assert_nil(cf.elements["Airflow[FanSpeed='medium']/Efficiency"])
    else
      assert_equal(Float(cf.elements["Airflow[FanSpeed='medium']/Efficiency"].text), cfm_per_w)
    end
    if quantity.nil?
      assert_nil(cf.elements["Quantity"])
    else
      assert_equal(Integer(cf.elements["Quantity"].text), quantity)
    end
  end
end
