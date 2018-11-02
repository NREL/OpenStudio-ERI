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
    _check_clothes_washer(hpxml_doc, 78.0, 4.484, 0.2729, 0.0315)
    _check_clothes_dryer(hpxml_doc, "electricity", 1120.0, 0, 0.1350, 0.0150)
    _check_dishwasher(hpxml_doc, 202.0, 5.097, 0.3003, 0.3003)
    _check_refrigerator(hpxml_doc, 709.0)
    _check_cooking_range(hpxml_doc, "electricity", false, false)
    
    # Rated Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_clothes_washer(hpxml_doc, 64.7, 1.919, 0.3*0.9, 0.3*0.1)
    _check_clothes_dryer(hpxml_doc, "electricity", 1043.5, 0, 0.15*0.9, 0.15*0.1)
    _check_dishwasher(hpxml_doc, 115.1, 0.143, 0.6*0.5, 0.6*0.5)
    _check_refrigerator(hpxml_doc, 609.0)
    _check_cooking_range(hpxml_doc, "electricity", true, true)
    
    # IAD, IAD Reference
    calc_types = [Constants.CalcTypeERIIndexAdjustmentDesign,
                  Constants.CalcTypeERIIndexAdjustmentReferenceHome]
    calc_types.each do |calc_type|
      hpxml_doc = _test_measure(hpxml_name, calc_type)
      _check_clothes_washer(hpxml_doc, 68.0, 3.889, 0.2722, 0.0315)
      _check_clothes_dryer(hpxml_doc, "electricity", 971.0, 0, 0.1350, 0.0150)
      _check_dishwasher(hpxml_doc, 171.0, 4.317, 0.3003,	0.3003)
      _check_refrigerator(hpxml_doc, 691.0)
      _check_cooking_range(hpxml_doc, "electricity", false, false)
    end
  end
  
  def test_appliances_dryer_cef
    hpxml_name = "valid-appliances-dryer-cef.xml"
    
    # Reference Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_clothes_washer(hpxml_doc, 78.0, 4.484, 0.2729, 0.0315)
    _check_clothes_dryer(hpxml_doc, "electricity", 1120.0, 0, 0.1350, 0.0150)
    _check_dishwasher(hpxml_doc, 202.0, 5.097, 0.3003, 0.3003)
    _check_refrigerator(hpxml_doc, 709.0)
    _check_cooking_range(hpxml_doc, "electricity", false, false)
    
    # Rated Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_clothes_washer(hpxml_doc, 64.7, 1.919, 0.3*0.9, 0.3*0.1)
    _check_clothes_dryer(hpxml_doc, "electricity", 1043.5, 0, 0.15*0.9, 0.15*0.1)
    _check_dishwasher(hpxml_doc, 115.1, 0.143, 0.6*0.5, 0.6*0.5)
    _check_refrigerator(hpxml_doc, 609.0)
    _check_cooking_range(hpxml_doc, "electricity", true, true)
    
    # IAD, IAD Reference
    calc_types = [Constants.CalcTypeERIIndexAdjustmentDesign,
                  Constants.CalcTypeERIIndexAdjustmentReferenceHome]
    calc_types.each do |calc_type|
      hpxml_doc = _test_measure(hpxml_name, calc_type)
      _check_clothes_washer(hpxml_doc, 68.0, 3.889, 0.2722, 0.0315)
      _check_clothes_dryer(hpxml_doc, "electricity", 971.0, 0, 0.1350, 0.0150)
      _check_dishwasher(hpxml_doc, 171.0, 4.317, 0.3003,	0.3003)
      _check_refrigerator(hpxml_doc, 691.0)
      _check_cooking_range(hpxml_doc, "electricity", false, false)
    end
  end
  
  def test_appliances_washer_imef
    hpxml_name = "valid-appliances-washer-imef.xml"
    
    # Reference Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_clothes_washer(hpxml_doc, 78.0, 4.484, 0.2729, 0.0315)
    _check_clothes_dryer(hpxml_doc, "electricity", 1120.0, 0, 0.1350, 0.0150)
    _check_dishwasher(hpxml_doc, 202.0, 5.097, 0.3003, 0.3003)
    _check_refrigerator(hpxml_doc, 709.0)
    _check_cooking_range(hpxml_doc, "electricity", false, false)
    
    # Rated Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_clothes_washer(hpxml_doc, 64.7, 1.919, 0.3*0.9, 0.3*0.1)
    _check_clothes_dryer(hpxml_doc, "electricity", 1043.5, 0, 0.15*0.9, 0.15*0.1)
    _check_dishwasher(hpxml_doc, 115.1, 0.143, 0.6*0.5, 0.6*0.5)
    _check_refrigerator(hpxml_doc, 609.0)
    _check_cooking_range(hpxml_doc, "electricity", true, true)
    
    # IAD, IAD Reference
    calc_types = [Constants.CalcTypeERIIndexAdjustmentDesign,
                  Constants.CalcTypeERIIndexAdjustmentReferenceHome]
    calc_types.each do |calc_type|
      hpxml_doc = _test_measure(hpxml_name, calc_type)
      _check_clothes_washer(hpxml_doc, 68.0, 3.889, 0.2722, 0.0315)
      _check_clothes_dryer(hpxml_doc, "electricity", 971.0, 0, 0.1350, 0.0150)
      _check_dishwasher(hpxml_doc, 171.0, 4.317, 0.3003,	0.3003)
      _check_refrigerator(hpxml_doc, 691.0)
      _check_cooking_range(hpxml_doc, "electricity", false, false)
    end
  end
  
  def test_appliances_gas
    hpxml_name = "valid-appliances-gas.xml"
    
    # Reference Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_clothes_washer(hpxml_doc, 78.0, 4.484, 0.2729, 0.0315)
    _check_clothes_dryer(hpxml_doc, "natural gas", 87.8, 40.0, 0.1336, 0.0166)
    _check_dishwasher(hpxml_doc, 202.0, 5.097, 0.3003, 0.3003)
    _check_refrigerator(hpxml_doc, 709.0)
    _check_cooking_range(hpxml_doc, "natural gas", false, false)
    
    # Rated Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_clothes_washer(hpxml_doc, 64.7, 1.919, 0.3*0.9, 0.3*0.1)
    _check_clothes_dryer(hpxml_doc, "natural gas", 73.0, 33.1, 0.15*0.9, 0.15*0.1)
    _check_dishwasher(hpxml_doc, 115.1, 0.143, 0.6*0.5, 0.6*0.5)
    _check_refrigerator(hpxml_doc, 609.0)
    _check_cooking_range(hpxml_doc, "natural gas", false, true)
    
    # IAD, IAD Reference
    calc_types = [Constants.CalcTypeERIIndexAdjustmentDesign,
                  Constants.CalcTypeERIIndexAdjustmentReferenceHome]
    calc_types.each do |calc_type|
      hpxml_doc = _test_measure(hpxml_name, calc_type)
      _check_clothes_washer(hpxml_doc, 68.0, 3.889, 0.2722, 0.0315)
      _check_clothes_dryer(hpxml_doc, "natural gas", 76.1, 34.7, 0.1336,	0.0165)
      _check_dishwasher(hpxml_doc, 171.0, 4.317, 0.3003,	0.3003)
      _check_refrigerator(hpxml_doc, 691.0)
      _check_cooking_range(hpxml_doc, "natural gas", false, false)
    end
  end
  
  def test_appliances_reference_elec
    hpxml_name = "valid-appliances-reference-elec.xml"
    
    # Reference Home, Rated Home
    calc_types = [Constants.CalcTypeERIReferenceHome, 
                  Constants.CalcTypeERIRatedHome] 
    calc_types.each do |calc_type|
      hpxml_doc = _test_measure(hpxml_name, calc_type)
      _check_clothes_washer(hpxml_doc, 78.0, 4.484, 0.2729, 0.0315)
      _check_clothes_dryer(hpxml_doc, "electricity", 1120.0, 0, 0.1350, 0.0150)
      _check_dishwasher(hpxml_doc, 202.0, 5.097, 0.3003, 0.3003)
      _check_refrigerator(hpxml_doc, 709.0)
      _check_cooking_range(hpxml_doc, "electricity", false, false)
    end
    
    # IAD, IAD Reference
    calc_types = [Constants.CalcTypeERIIndexAdjustmentDesign,
                  Constants.CalcTypeERIIndexAdjustmentReferenceHome]
    calc_types.each do |calc_type|
      hpxml_doc = _test_measure(hpxml_name, calc_type)
      _check_clothes_washer(hpxml_doc, 68.0, 3.889, 0.2722, 0.0315)
      _check_clothes_dryer(hpxml_doc, "electricity", 971.0, 0, 0.1350, 0.0150)
      _check_dishwasher(hpxml_doc, 171.0, 4.317, 0.3003,	0.3003)
      _check_refrigerator(hpxml_doc, 691.0)
      _check_cooking_range(hpxml_doc, "electricity", false, false)
    end
  end
  
  def test_appliances_reference_gas
    hpxml_name = "valid-appliances-reference-gas.xml"
    
    # Reference Home, Rated Home
    calc_types = [Constants.CalcTypeERIReferenceHome, 
                  Constants.CalcTypeERIRatedHome]
    calc_types.each do |calc_type|
      hpxml_doc = _test_measure(hpxml_name, calc_type)
      _check_clothes_washer(hpxml_doc, 78.0, 4.484, 0.2729, 0.0315)
      _check_clothes_dryer(hpxml_doc, "natural gas", 87.8, 40.0, 0.1336, 0.0166)
      _check_dishwasher(hpxml_doc, 202.0, 5.097, 0.3003, 0.3003)
      _check_refrigerator(hpxml_doc, 709.0)
      _check_cooking_range(hpxml_doc, "natural gas", false, false)
    end

    # IAD, IAD Reference
    calc_types = [Constants.CalcTypeERIIndexAdjustmentDesign,
                  Constants.CalcTypeERIIndexAdjustmentReferenceHome]
    calc_types.each do |calc_type|
      hpxml_doc = _test_measure(hpxml_name, calc_type)
      _check_clothes_washer(hpxml_doc, 68.0, 3.889, 0.2722, 0.0315)
      _check_clothes_dryer(hpxml_doc, "natural gas", 76.1, 34.7, 0.1336,	0.0165)
      _check_dishwasher(hpxml_doc, 171.0, 4.317, 0.3003,	0.3003)
      _check_refrigerator(hpxml_doc, 691.0)
      _check_cooking_range(hpxml_doc, "natural gas", false, false)
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
    measure = EnergyRatingIndex301.new
    
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

  def _check_clothes_washer(hpxml_doc, annual_kwh, hw_gpd, frac_sens, frac_lat)
    appl = hpxml_doc.elements["/HPXML/Building/BuildingDetails/Appliances/ClothesWasher"]
    assert_in_epsilon(Float(appl.elements["extension/AnnualkWh"].text), annual_kwh, 0.01)
    assert_in_epsilon(Float(appl.elements["extension/HotWaterGPD"].text), hw_gpd, 0.01)
    assert_in_epsilon(Float(appl.elements["extension/FracSensible"].text), frac_sens, 0.01)
    assert_in_epsilon(Float(appl.elements["extension/FracLatent"].text), frac_lat, 0.01)
  end
  
  def _check_clothes_dryer(hpxml_doc, fuel_type, annual_kwh, annual_therm, frac_sens, frac_lat)
    appl = hpxml_doc.elements["/HPXML/Building/BuildingDetails/Appliances/ClothesDryer"]
    assert_equal(appl.elements["FuelType"].text, fuel_type)
    assert_in_epsilon(Float(appl.elements["extension/AnnualkWh"].text), annual_kwh, 0.01)
    assert_in_epsilon(Float(appl.elements["extension/AnnualTherm"].text), annual_therm, 0.01)
    assert_in_epsilon(Float(appl.elements["extension/FracSensible"].text), frac_sens, 0.01)
    assert_in_epsilon(Float(appl.elements["extension/FracLatent"].text), frac_lat, 0.01)
  end
  
  def _check_dishwasher(hpxml_doc, annual_kwh, hw_gpd, frac_sens, frac_lat)
    appl = hpxml_doc.elements["/HPXML/Building/BuildingDetails/Appliances/Dishwasher"]
    assert_in_epsilon(Float(appl.elements["extension/AnnualkWh"].text), annual_kwh, 0.01)
    assert_in_epsilon(Float(appl.elements["extension/HotWaterGPD"].text), hw_gpd, 0.01)
    assert_in_epsilon(Float(appl.elements["extension/FracSensible"].text), frac_sens, 0.01)
    assert_in_epsilon(Float(appl.elements["extension/FracLatent"].text), frac_lat, 0.01)
  end
  
  def _check_refrigerator(hpxml_doc, annual_kwh)
    appl = hpxml_doc.elements["/HPXML/Building/BuildingDetails/Appliances/Refrigerator"]
    assert_in_epsilon(Float(appl.elements["RatedAnnualkWh"].text), annual_kwh, 0.01)
  end
  
  def _check_cooking_range(hpxml_doc, fuel_type, cook_is_induction, oven_is_convection)
    cook = hpxml_doc.elements["/HPXML/Building/BuildingDetails/Appliances/CookingRange"]
    assert_equal(cook.elements["FuelType"].text, fuel_type)
    if not cook_is_induction.nil?
      assert_equal(Boolean(cook.elements["IsInduction"].text), cook_is_induction)
    end
    oven = hpxml_doc.elements["/HPXML/Building/BuildingDetails/Appliances/Oven"]
    if not oven_is_convection.nil?
      assert_equal(Boolean(oven.elements["IsConvection"].text), oven_is_convection)
    end
  end
  
end