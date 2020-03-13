require_relative '../../../workflow/tests/minitest_helper'
require 'openstudio'
require 'openstudio/ruleset/ShowRunnerOutput'
require 'minitest/autorun'
require_relative '../measure.rb'
require 'fileutils'

class ApplianceTest < MiniTest::Test
  def before_setup
    @root_path = File.absolute_path(File.join(File.dirname(__FILE__), '..', '..', '..'))
  end

  def test_appliances_electric
    hpxml_name = 'base.xml'

    # Reference Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_clothes_washer(hpxml_doc, nil, 0.331, 704, 0.08, 0.58, 23, 2.874, HPXML::LocationLivingSpace)
    _check_clothes_dryer(hpxml_doc, HPXML::FuelTypeElectricity, nil, 2.62, HPXML::ClothesDryerControlTypeTimer, HPXML::LocationLivingSpace)
    _check_dishwasher(hpxml_doc, 0.46, nil, 12)
    _check_refrigerator(hpxml_doc, 691.0, HPXML::LocationLivingSpace)
    _check_cooking_range(hpxml_doc, HPXML::FuelTypeElectricity, false, false)

    # Rated Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_clothes_washer(hpxml_doc, 0.8, nil, 700, 0.1, 0.6, 25.0, 3.0, HPXML::LocationLivingSpace)
    _check_clothes_dryer(hpxml_doc, HPXML::FuelTypeElectricity, 2.95, nil, HPXML::ClothesDryerControlTypeTimer, HPXML::LocationLivingSpace)
    _check_dishwasher(hpxml_doc, nil, 450, 12)
    _check_refrigerator(hpxml_doc, 650.0, HPXML::LocationLivingSpace)
    _check_cooking_range(hpxml_doc, HPXML::FuelTypeElectricity, false, false)

    # IAD, IAD Reference
    calc_types = [Constants.CalcTypeERIIndexAdjustmentDesign,
                  Constants.CalcTypeERIIndexAdjustmentReferenceHome]
    calc_types.each do |calc_type|
      hpxml_doc = _test_measure(hpxml_name, calc_type)
      _check_clothes_washer(hpxml_doc, nil, 0.331, 704, 0.08, 0.58, 23, 2.874, HPXML::LocationLivingSpace)
      _check_clothes_dryer(hpxml_doc, HPXML::FuelTypeElectricity, nil, 2.62, HPXML::ClothesDryerControlTypeTimer, HPXML::LocationLivingSpace)
      _check_dishwasher(hpxml_doc, 0.46, nil, 12)
      _check_refrigerator(hpxml_doc, 691.0, HPXML::LocationLivingSpace)
      _check_cooking_range(hpxml_doc, HPXML::FuelTypeElectricity, false, false)
    end
  end

  def test_appliances_dryer_cef_washer_imef_dishwasher_ef
    hpxml_name = 'base-appliances-modified.xml'

    # Reference Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_clothes_washer(hpxml_doc, nil, 0.331, 704, 0.08, 0.58, 23, 2.874, HPXML::LocationLivingSpace)
    _check_clothes_dryer(hpxml_doc, HPXML::FuelTypeElectricity, nil, 2.62, HPXML::ClothesDryerControlTypeTimer, HPXML::LocationLivingSpace)
    _check_dishwasher(hpxml_doc, 0.46, nil, 12)
    _check_refrigerator(hpxml_doc, 691.0, HPXML::LocationLivingSpace)
    _check_cooking_range(hpxml_doc, HPXML::FuelTypeElectricity, false, false)

    # Rated Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_clothes_washer(hpxml_doc, nil, 0.73, 700, 0.1, 0.6, 25.0, 3.0, HPXML::LocationLivingSpace)
    _check_clothes_dryer(hpxml_doc, HPXML::FuelTypeElectricity, nil, 2.62, HPXML::ClothesDryerControlTypeMoisture, HPXML::LocationLivingSpace)
    _check_dishwasher(hpxml_doc, 0.5, nil, 12)
    _check_refrigerator(hpxml_doc, 650.0, HPXML::LocationLivingSpace)
    _check_cooking_range(hpxml_doc, HPXML::FuelTypeElectricity, false, false)

    # IAD, IAD Reference
    calc_types = [Constants.CalcTypeERIIndexAdjustmentDesign,
                  Constants.CalcTypeERIIndexAdjustmentReferenceHome]
    calc_types.each do |calc_type|
      hpxml_doc = _test_measure(hpxml_name, calc_type)
      _check_clothes_washer(hpxml_doc, nil, 0.331, 704, 0.08, 0.58, 23, 2.874, HPXML::LocationLivingSpace)
      _check_clothes_dryer(hpxml_doc, HPXML::FuelTypeElectricity, nil, 2.62, HPXML::ClothesDryerControlTypeTimer, HPXML::LocationLivingSpace)
      _check_dishwasher(hpxml_doc, 0.46, nil, 12)
      _check_refrigerator(hpxml_doc, 691.0, HPXML::LocationLivingSpace)
      _check_cooking_range(hpxml_doc, HPXML::FuelTypeElectricity, false, false)
    end
  end

  def test_appliances_gas
    hpxml_name = 'base-appliances-gas.xml'

    # Reference Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_clothes_washer(hpxml_doc, nil, 0.331, 704, 0.08, 0.58, 23, 2.874, HPXML::LocationLivingSpace)
    _check_clothes_dryer(hpxml_doc, HPXML::FuelTypeNaturalGas, nil, 2.32, HPXML::ClothesDryerControlTypeTimer, HPXML::LocationLivingSpace)
    _check_dishwasher(hpxml_doc, 0.46, nil, 12)
    _check_refrigerator(hpxml_doc, 691.0, HPXML::LocationLivingSpace)
    _check_cooking_range(hpxml_doc, HPXML::FuelTypeNaturalGas, false, false)

    # Rated Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_clothes_washer(hpxml_doc, 0.8, nil, 700, 0.1, 0.6, 25.0, 3.0, HPXML::LocationLivingSpace)
    _check_clothes_dryer(hpxml_doc, HPXML::FuelTypeNaturalGas, 2.67, nil, HPXML::ClothesDryerControlTypeMoisture, HPXML::LocationLivingSpace)
    _check_dishwasher(hpxml_doc, nil, 450, 12)
    _check_refrigerator(hpxml_doc, 650.0, HPXML::LocationLivingSpace)
    _check_cooking_range(hpxml_doc, HPXML::FuelTypeNaturalGas, false, false)

    # IAD, IAD Reference
    calc_types = [Constants.CalcTypeERIIndexAdjustmentDesign,
                  Constants.CalcTypeERIIndexAdjustmentReferenceHome]
    calc_types.each do |calc_type|
      hpxml_doc = _test_measure(hpxml_name, calc_type)
      _check_clothes_washer(hpxml_doc, nil, 0.331, 704, 0.08, 0.58, 23, 2.874, HPXML::LocationLivingSpace)
      _check_clothes_dryer(hpxml_doc, HPXML::FuelTypeNaturalGas, nil, 2.32, HPXML::ClothesDryerControlTypeTimer, HPXML::LocationLivingSpace)
      _check_dishwasher(hpxml_doc, 0.46, nil, 12)
      _check_refrigerator(hpxml_doc, 691.0, HPXML::LocationLivingSpace)
      _check_cooking_range(hpxml_doc, HPXML::FuelTypeNaturalGas, false, false)
    end
  end

  def test_appliances_in_basement
    hpxml_name = 'base-foundation-unconditioned-basement.xml'

    # Reference Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_clothes_washer(hpxml_doc, nil, 0.331, 704, 0.08, 0.58, 23, 2.874, HPXML::LocationLivingSpace)
    _check_clothes_dryer(hpxml_doc, HPXML::FuelTypeElectricity, nil, 2.62, HPXML::ClothesDryerControlTypeTimer, HPXML::LocationLivingSpace)
    _check_dishwasher(hpxml_doc, 0.46, nil, 12)
    _check_refrigerator(hpxml_doc, 691.0, HPXML::LocationLivingSpace)
    _check_cooking_range(hpxml_doc, HPXML::FuelTypeElectricity, false, false)

    # Rated Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_clothes_washer(hpxml_doc, 0.8, nil, 700, 0.1, 0.6, 25.0, 3.0, HPXML::LocationBasementUnconditioned)
    _check_clothes_dryer(hpxml_doc, HPXML::FuelTypeElectricity, 2.95, nil, HPXML::ClothesDryerControlTypeTimer, HPXML::LocationBasementUnconditioned)
    _check_dishwasher(hpxml_doc, nil, 450, 12)
    _check_refrigerator(hpxml_doc, 650.0, HPXML::LocationBasementUnconditioned)
    _check_cooking_range(hpxml_doc, HPXML::FuelTypeElectricity, false, false)

    # IAD, IAD Reference
    calc_types = [Constants.CalcTypeERIIndexAdjustmentDesign,
                  Constants.CalcTypeERIIndexAdjustmentReferenceHome]
    calc_types.each do |calc_type|
      hpxml_doc = _test_measure(hpxml_name, calc_type)
      _check_clothes_washer(hpxml_doc, nil, 0.331, 704, 0.08, 0.58, 23, 2.874, HPXML::LocationLivingSpace)
      _check_clothes_dryer(hpxml_doc, HPXML::FuelTypeElectricity, nil, 2.62, HPXML::ClothesDryerControlTypeTimer, HPXML::LocationLivingSpace)
      _check_dishwasher(hpxml_doc, 0.46, nil, 12)
      _check_refrigerator(hpxml_doc, 691.0, HPXML::LocationLivingSpace)
      _check_cooking_range(hpxml_doc, HPXML::FuelTypeElectricity, false, false)
    end
  end

  def _test_measure(hpxml_name, calc_type)
    args_hash = {}
    args_hash['hpxml_input_path'] = File.join(@root_path, 'workflow', 'sample_files', hpxml_name)
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
    assert_equal('Success', result.value.valueName)
    assert(File.exist? args_hash['hpxml_output_path'])

    hpxml_doc = REXML::Document.new(File.read(args_hash['hpxml_output_path']))
    File.delete(args_hash['hpxml_output_path'])

    return hpxml_doc
  end

  def _check_clothes_washer(hpxml_doc, mef, imef, annual_kwh, elec_rate, gas_rate, agc, cap, location)
    appl = hpxml_doc.elements['/HPXML/Building/BuildingDetails/Appliances/ClothesWasher']
    if location.nil?
      assert_nil(appl.elements['Location'])
    else
      assert_equal(appl.elements['Location'].text, location)
    end
    if mef.nil?
      assert_nil(appl.elements['ModifiedEnergyFactor'])
    else
      assert_in_epsilon(Float(appl.elements['ModifiedEnergyFactor'].text), mef, 0.01)
    end
    if imef.nil?
      assert_nil(appl.elements['IntegratedModifiedEnergyFactor'])
    else
      assert_in_epsilon(Float(appl.elements['IntegratedModifiedEnergyFactor'].text), imef, 0.01)
    end
    if annual_kwh.nil?
      assert_nil(appl.elements['RatedAnnualkWh'])
    else
      assert_in_epsilon(Float(appl.elements['RatedAnnualkWh'].text), annual_kwh, 0.01)
    end
    if elec_rate.nil?
      assert_nil(appl.elements['LabelElectricRate'])
    else
      assert_in_epsilon(Float(appl.elements['LabelElectricRate'].text), elec_rate, 0.01)
    end
    if gas_rate.nil?
      assert_nil(appl.elements['LabelGasRate'])
    else
      assert_in_epsilon(Float(appl.elements['LabelGasRate'].text), gas_rate, 0.01)
    end
    if agc.nil?
      assert_nil(appl.elements['LabelAnnualGasCost'])
    else
      assert_in_epsilon(Float(appl.elements['LabelAnnualGasCost'].text), agc, 0.01)
    end
    if cap.nil?
      assert_nil(appl.elements['Capacity'])
    else
      assert_in_epsilon(Float(appl.elements['Capacity'].text), cap, 0.01)
    end
  end

  def _check_clothes_dryer(hpxml_doc, fuel_type, ef, cef, control, location)
    appl = hpxml_doc.elements['/HPXML/Building/BuildingDetails/Appliances/ClothesDryer']
    if location.nil?
      assert_nil(appl.elements['Location'])
    else
      assert_equal(appl.elements['Location'].text, location)
    end
    if fuel_type.nil?
      assert_nil(appl.elements['FuelType'])
    else
      assert_equal(appl.elements['FuelType'].text, fuel_type)
    end
    if ef.nil?
      assert_nil(appl.elements['EnergyFactor'])
    else
      assert_in_epsilon(Float(appl.elements['EnergyFactor'].text), ef, 0.01)
    end
    if cef.nil?
      assert_nil(appl.elements['CombinedEnergyFactor'])
    else
      assert_in_epsilon(Float(appl.elements['CombinedEnergyFactor'].text), cef, 0.01)
    end
    if control.nil?
      assert_nil(appl.elements['ControlType'])
    else
      assert_equal(appl.elements['ControlType'].text, control)
    end
  end

  def _check_dishwasher(hpxml_doc, ef, annual_kwh, cap)
    appl = hpxml_doc.elements['/HPXML/Building/BuildingDetails/Appliances/Dishwasher']
    if ef.nil?
      assert_nil(appl.elements['EnergyFactor'])
    else
      assert_in_epsilon(Float(appl.elements['EnergyFactor'].text), ef, 0.01)
    end
    if annual_kwh.nil?
      assert_nil(appl.elements['RatedAnnualkWh'])
    else
      assert_in_epsilon(Float(appl.elements['RatedAnnualkWh'].text), annual_kwh, 0.01)
    end
    if cap.nil?
      assert_nil(appl.elements['PlaceSettingCapacity'])
    else
      assert_in_epsilon(Float(appl.elements['PlaceSettingCapacity'].text), cap, 0.01)
    end
  end

  def _check_refrigerator(hpxml_doc, annual_kwh, location)
    appl = hpxml_doc.elements['/HPXML/Building/BuildingDetails/Appliances/Refrigerator']
    if location.nil?
      assert_nil(appl.elements['Location'])
    else
      assert_equal(appl.elements['Location'].text, location)
    end
    assert_in_epsilon(Float(appl.elements['RatedAnnualkWh'].text), annual_kwh, 0.01)
  end

  def _check_cooking_range(hpxml_doc, fuel_type, cook_is_induction, oven_is_convection)
    cook = hpxml_doc.elements['/HPXML/Building/BuildingDetails/Appliances/CookingRange']
    assert_equal(cook.elements['FuelType'].text, fuel_type)
    if cook_is_induction.nil?
      assert_nil(cook.elements['IsInduction'])
    else
      assert_equal(Boolean(cook.elements['IsInduction'].text), cook_is_induction)
    end
    oven = hpxml_doc.elements['/HPXML/Building/BuildingDetails/Appliances/Oven']
    if oven_is_convection.nil?
      assert_nil(oven.elements['IsConvection'])
    else
      assert_equal(Boolean(oven.elements['IsConvection'].text), oven_is_convection)
    end
  end
end
