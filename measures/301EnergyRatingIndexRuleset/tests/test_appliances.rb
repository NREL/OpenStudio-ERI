require_relative '../../../workflow/tests/minitest_helper'
require 'openstudio'
require 'openstudio/ruleset/ShowRunnerOutput'
require 'minitest/autorun'
require_relative '../measure.rb'
require 'fileutils'

class ApplianceTest < MiniTest::Test
  def test_appliances_electric
    hpxml_name = "valid.xml"

    # Reference Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_clothes_washer(hpxml_doc, 0.817, nil, 704, 0.08, 0.58, 23, 2.874, "living space")
    _check_clothes_dryer(hpxml_doc, "electricity", 3.01, nil, "timer", "living space")
    _check_dishwasher(hpxml_doc, 0.46, nil, 12)
    _check_refrigerator(hpxml_doc, 709.0, "living space")
    _check_cooking_range(hpxml_doc, "electricity", false, false)

    # Rated Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_clothes_washer(hpxml_doc, 1.2, nil, 387, 0.127, 1.003, 24, 3.5, "living space")
    _check_clothes_dryer(hpxml_doc, "electricity", 3.01, nil, "timer", "living space")
    _check_dishwasher(hpxml_doc, nil, 100, 12)
    _check_refrigerator(hpxml_doc, 609.0, "living space")
    _check_cooking_range(hpxml_doc, "electricity", true, true)

    # IAD, IAD Reference
    calc_types = [Constants.CalcTypeERIIndexAdjustmentDesign,
                  Constants.CalcTypeERIIndexAdjustmentReferenceHome]
    calc_types.each do |calc_type|
      hpxml_doc = _test_measure(hpxml_name, calc_type)
      _check_clothes_washer(hpxml_doc, 0.817, nil, 704, 0.08, 0.58, 23, 2.874, "living space")
      _check_clothes_dryer(hpxml_doc, "electricity", 3.01, nil, "timer", "living space")
      _check_dishwasher(hpxml_doc, 0.46, nil, 12)
      _check_refrigerator(hpxml_doc, 691.0, "living space")
      _check_cooking_range(hpxml_doc, "electricity", false, false)
    end
  end

  def test_appliances_dryer_cef
    hpxml_name = "valid-appliances-dryer-cef.xml"

    # Reference Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_clothes_washer(hpxml_doc, 0.817, nil, 704, 0.08, 0.58, 23, 2.874, "living space")
    _check_clothes_dryer(hpxml_doc, "electricity", 3.01, nil, "timer", "living space")
    _check_dishwasher(hpxml_doc, 0.46, nil, 12)
    _check_refrigerator(hpxml_doc, 709.0, "living space")
    _check_cooking_range(hpxml_doc, "electricity", false, false)

    # Rated Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_clothes_washer(hpxml_doc, 1.2, nil, 387, 0.127, 1.003, 24, 3.5, "living space")
    _check_clothes_dryer(hpxml_doc, "electricity", nil, 2.62, "moisture", "living space")
    _check_dishwasher(hpxml_doc, nil, 100, 12)
    _check_refrigerator(hpxml_doc, 609.0, "living space")
    _check_cooking_range(hpxml_doc, "electricity", true, true)

    # IAD, IAD Reference
    calc_types = [Constants.CalcTypeERIIndexAdjustmentDesign,
                  Constants.CalcTypeERIIndexAdjustmentReferenceHome]
    calc_types.each do |calc_type|
      hpxml_doc = _test_measure(hpxml_name, calc_type)
      _check_clothes_washer(hpxml_doc, 0.817, nil, 704, 0.08, 0.58, 23, 2.874, "living space")
      _check_clothes_dryer(hpxml_doc, "electricity", 3.01, nil, "timer", "living space")
      _check_dishwasher(hpxml_doc, 0.46, nil, 12)
      _check_refrigerator(hpxml_doc, 691.0, "living space")
      _check_cooking_range(hpxml_doc, "electricity", false, false)
    end
  end

  def test_appliances_washer_imef
    hpxml_name = "valid-appliances-washer-imef.xml"

    # Reference Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_clothes_washer(hpxml_doc, 0.817, nil, 704, 0.08, 0.58, 23, 2.874, "living space")
    _check_clothes_dryer(hpxml_doc, "electricity", 3.01, nil, "timer", "living space")
    _check_dishwasher(hpxml_doc, 0.46, nil, 12)
    _check_refrigerator(hpxml_doc, 709.0, "living space")
    _check_cooking_range(hpxml_doc, "electricity", false, false)

    # Rated Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_clothes_washer(hpxml_doc, nil, 0.73, 387, 0.127, 1.003, 24, 3.5, "living space")
    _check_clothes_dryer(hpxml_doc, "electricity", 3.01, nil, "timer", "living space")
    _check_dishwasher(hpxml_doc, nil, 100, 12)
    _check_refrigerator(hpxml_doc, 609.0, "living space")
    _check_cooking_range(hpxml_doc, "electricity", true, true)

    # IAD, IAD Reference
    calc_types = [Constants.CalcTypeERIIndexAdjustmentDesign,
                  Constants.CalcTypeERIIndexAdjustmentReferenceHome]
    calc_types.each do |calc_type|
      hpxml_doc = _test_measure(hpxml_name, calc_type)
      _check_clothes_washer(hpxml_doc, 0.817, nil, 704, 0.08, 0.58, 23, 2.874, "living space")
      _check_clothes_dryer(hpxml_doc, "electricity", 3.01, nil, "timer", "living space")
      _check_dishwasher(hpxml_doc, 0.46, nil, 12)
      _check_refrigerator(hpxml_doc, 691.0, "living space")
      _check_cooking_range(hpxml_doc, "electricity", false, false)
    end
  end

  def test_appliances_diwasher_ef
    hpxml_name = "valid-appliances-dishwasher-ef.xml"

    # Reference Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_clothes_washer(hpxml_doc, 0.817, nil, 704, 0.08, 0.58, 23, 2.874, "living space")
    _check_clothes_dryer(hpxml_doc, "electricity", 3.01, nil, "timer", "living space")
    _check_dishwasher(hpxml_doc, 0.46, nil, 12)
    _check_refrigerator(hpxml_doc, 709.0, "living space")
    _check_cooking_range(hpxml_doc, "electricity", false, false)

    # Rated Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_clothes_washer(hpxml_doc, 1.2, nil, 387, 0.127, 1.003, 24, 3.5, "living space")
    _check_clothes_dryer(hpxml_doc, "electricity", 3.01, nil, "timer", "living space")
    _check_dishwasher(hpxml_doc, 0.5, nil, 8)
    _check_refrigerator(hpxml_doc, 609.0, "living space")
    _check_cooking_range(hpxml_doc, "electricity", true, true)

    # IAD, IAD Reference
    calc_types = [Constants.CalcTypeERIIndexAdjustmentDesign,
                  Constants.CalcTypeERIIndexAdjustmentReferenceHome]
    calc_types.each do |calc_type|
      hpxml_doc = _test_measure(hpxml_name, calc_type)
      _check_clothes_washer(hpxml_doc, 0.817, nil, 704, 0.08, 0.58, 23, 2.874, "living space")
      _check_clothes_dryer(hpxml_doc, "electricity", 3.01, nil, "timer", "living space")
      _check_dishwasher(hpxml_doc, 0.46, nil, 12)
      _check_refrigerator(hpxml_doc, 691.0, "living space")
      _check_cooking_range(hpxml_doc, "electricity", false, false)
    end
  end

  def test_appliances_gas
    hpxml_name = "valid-appliances-gas.xml"

    # Reference Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_clothes_washer(hpxml_doc, 0.817, nil, 704, 0.08, 0.58, 23, 2.874, "living space")
    _check_clothes_dryer(hpxml_doc, "natural gas", 2.67, nil, "timer", "living space")
    _check_dishwasher(hpxml_doc, 0.46, nil, 12)
    _check_refrigerator(hpxml_doc, 709.0, "living space")
    _check_cooking_range(hpxml_doc, "natural gas", false, false)

    # Rated Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_clothes_washer(hpxml_doc, 1.2, nil, 387, 0.127, 1.003, 24, 3.5, "living space")
    _check_clothes_dryer(hpxml_doc, "natural gas", 2.67, nil, "moisture", "living space")
    _check_dishwasher(hpxml_doc, nil, 100, 12)
    _check_refrigerator(hpxml_doc, 609.0, "living space")
    _check_cooking_range(hpxml_doc, "natural gas", false, true)

    # IAD, IAD Reference
    calc_types = [Constants.CalcTypeERIIndexAdjustmentDesign,
                  Constants.CalcTypeERIIndexAdjustmentReferenceHome]
    calc_types.each do |calc_type|
      hpxml_doc = _test_measure(hpxml_name, calc_type)
      _check_clothes_washer(hpxml_doc, 0.817, nil, 704, 0.08, 0.58, 23, 2.874, "living space")
      _check_clothes_dryer(hpxml_doc, "natural gas", 2.67, nil, "timer", "living space")
      _check_dishwasher(hpxml_doc, 0.46, nil, 12)
      _check_refrigerator(hpxml_doc, 691.0, "living space")
      _check_cooking_range(hpxml_doc, "natural gas", false, false)
    end
  end

  def test_appliances_in_basement
    hpxml_name = "valid-foundation-unconditioned-basement.xml"

    # Reference Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_clothes_washer(hpxml_doc, 0.817, nil, 704, 0.08, 0.58, 23, 2.874, "living space")
    _check_clothes_dryer(hpxml_doc, "electricity", 3.01, nil, "timer", "living space")
    _check_dishwasher(hpxml_doc, 0.46, nil, 12)
    _check_refrigerator(hpxml_doc, 709.0, "living space")
    _check_cooking_range(hpxml_doc, "electricity", false, false)

    # Rated Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_clothes_washer(hpxml_doc, 1.2, nil, 387, 0.127, 1.003, 24, 3.5, "basement - unconditioned")
    _check_clothes_dryer(hpxml_doc, "electricity", 3.01, nil, "timer", "basement - unconditioned")
    _check_dishwasher(hpxml_doc, nil, 100, 12)
    _check_refrigerator(hpxml_doc, 609.0, "basement - unconditioned")
    _check_cooking_range(hpxml_doc, "electricity", true, true)

    # IAD, IAD Reference
    calc_types = [Constants.CalcTypeERIIndexAdjustmentDesign,
                  Constants.CalcTypeERIIndexAdjustmentReferenceHome]
    calc_types.each do |calc_type|
      hpxml_doc = _test_measure(hpxml_name, calc_type)
      _check_clothes_washer(hpxml_doc, 0.817, nil, 704, 0.08, 0.58, 23, 2.874, "living space")
      _check_clothes_dryer(hpxml_doc, "electricity", 3.01, nil, "timer", "living space")
      _check_dishwasher(hpxml_doc, 0.46, nil, 12)
      _check_refrigerator(hpxml_doc, 691.0, "living space")
      _check_cooking_range(hpxml_doc, "electricity", false, false)
    end
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

  def _check_clothes_washer(hpxml_doc, mef, imef, annual_kwh, elec_rate, gas_rate, agc, cap, location)
    appl = hpxml_doc.elements["/HPXML/Building/BuildingDetails/Appliances/ClothesWasher"]
    if location.nil?
      assert_nil(appl.elements["Location"])
    else
      assert_equal(appl.elements["Location"].text, location)
    end
    if mef.nil?
      assert_nil(appl.elements["ModifiedEnergyFactor"])
    else
      assert_in_epsilon(Float(appl.elements["ModifiedEnergyFactor"].text), mef, 0.01)
    end
    if imef.nil?
      assert_nil(appl.elements["IntegratedModifiedEnergyFactor"])
    else
      assert_in_epsilon(Float(appl.elements["IntegratedModifiedEnergyFactor"].text), imef, 0.01)
    end
    if annual_kwh.nil?
      assert_nil(appl.elements["RatedAnnualkWh"])
    else
      assert_in_epsilon(Float(appl.elements["RatedAnnualkWh"].text), annual_kwh, 0.01)
    end
    if elec_rate.nil?
      assert_nil(appl.elements["LabelElectricRate"])
    else
      assert_in_epsilon(Float(appl.elements["LabelElectricRate"].text), elec_rate, 0.01)
    end
    if gas_rate.nil?
      assert_nil(appl.elements["LabelGasRate"])
    else
      assert_in_epsilon(Float(appl.elements["LabelGasRate"].text), gas_rate, 0.01)
    end
    if agc.nil?
      assert_nil(appl.elements["LabelAnnualGasCost"])
    else
      assert_in_epsilon(Float(appl.elements["LabelAnnualGasCost"].text), agc, 0.01)
    end
    if cap.nil?
      assert_nil(appl.elements["Capacity"])
    else
      assert_in_epsilon(Float(appl.elements["Capacity"].text), cap, 0.01)
    end
  end

  def _check_clothes_dryer(hpxml_doc, fuel_type, ef, cef, control, location)
    appl = hpxml_doc.elements["/HPXML/Building/BuildingDetails/Appliances/ClothesDryer"]
    if location.nil?
      assert_nil(appl.elements["Location"])
    else
      assert_equal(appl.elements["Location"].text, location)
    end
    if fuel_type.nil?
      assert_nil(appl.elements["FuelType"])
    else
      assert_equal(appl.elements["FuelType"].text, fuel_type)
    end
    if ef.nil?
      assert_nil(appl.elements["EnergyFactor"])
    else
      assert_in_epsilon(Float(appl.elements["EnergyFactor"].text), ef, 0.01)
    end
    if cef.nil?
      assert_nil(appl.elements["CombinedEnergyFactor"])
    else
      assert_in_epsilon(Float(appl.elements["CombinedEnergyFactor"].text), cef, 0.01)
    end
    if control.nil?
      assert_nil(appl.elements["ControlType"])
    else
      assert_equal(appl.elements["ControlType"].text, control)
    end
  end

  def _check_dishwasher(hpxml_doc, ef, annual_kwh, cap)
    appl = hpxml_doc.elements["/HPXML/Building/BuildingDetails/Appliances/Dishwasher"]
    if ef.nil?
      assert_nil(appl.elements["EnergyFactor"])
    else
      assert_in_epsilon(Float(appl.elements["EnergyFactor"].text), ef, 0.01)
    end
    if annual_kwh.nil?
      assert_nil(appl.elements["RatedAnnualkWh"])
    else
      assert_in_epsilon(Float(appl.elements["RatedAnnualkWh"].text), annual_kwh, 0.01)
    end
    if cap.nil?
      assert_nil(appl.elements["PlaceSettingCapacity"])
    else
      assert_in_epsilon(Float(appl.elements["PlaceSettingCapacity"].text), cap, 0.01)
    end
  end

  def _check_refrigerator(hpxml_doc, annual_kwh, location)
    appl = hpxml_doc.elements["/HPXML/Building/BuildingDetails/Appliances/Refrigerator"]
    if location.nil?
      assert_nil(appl.elements["Location"])
    else
      assert_equal(appl.elements["Location"].text, location)
    end
    assert_in_epsilon(Float(appl.elements["RatedAnnualkWh"].text), annual_kwh, 0.01)
  end

  def _check_cooking_range(hpxml_doc, fuel_type, cook_is_induction, oven_is_convection)
    cook = hpxml_doc.elements["/HPXML/Building/BuildingDetails/Appliances/CookingRange"]
    assert_equal(cook.elements["FuelType"].text, fuel_type)
    if cook_is_induction.nil?
      assert_nil(cook.elements["IsInduction"])
    else
      assert_equal(Boolean(cook.elements["IsInduction"].text), cook_is_induction)
    end
    oven = hpxml_doc.elements["/HPXML/Building/BuildingDetails/Appliances/Oven"]
    if oven_is_convection.nil?
      assert_nil(oven.elements["IsConvection"])
    else
      assert_equal(Boolean(oven.elements["IsConvection"].text), oven_is_convection)
    end
  end
end
