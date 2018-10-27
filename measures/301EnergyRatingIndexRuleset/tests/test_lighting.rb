require 'openstudio'
require 'openstudio/ruleset/ShowRunnerOutput'
require 'minitest/autorun'
require_relative '../measure.rb'
require 'fileutils'

class LightingTest < MiniTest::Test

  def test_lighting
    hpxml_name = "valid.xml"
    
    # Reference Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_lighting(hpxml_doc, 3255, 275, 0)
    
    # Rated Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_lighting(hpxml_doc, 1645, 115, 0)
    
    # IAD
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentDesign)
    _check_lighting(hpxml_doc, 1248, 96, 0)
    
    # IAD Reference
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentReferenceHome)
    _check_lighting(hpxml_doc, 2375, 220, 0)
  end
  
  def test_lighting_pre_addendum_g
    hpxml_name = "valid-addenda-exclude-g.xml"
    
    # Reference Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_lighting(hpxml_doc, 3255, 275, 0)
    
    # Rated Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_lighting(hpxml_doc, 2410, 172, 0)
    
    # IAD
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentDesign)
    _check_lighting(hpxml_doc, 1374, 96, 0)
    
    # IAD Reference
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentReferenceHome)
    _check_lighting(hpxml_doc, 2375, 220, 0)
  end
  
  def test_ceiling_fans
    hpxml_name = "valid-misc-ceiling-fans.xml"
    
    clg_sp_offset =  # F
    monthly_temp_control =  # F
    
    # Reference Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_ceiling_fans(hpxml_doc, 42.6*10.5*365*5/1000, 0.5, 63)
    
    # Rated Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_ceiling_fans(hpxml_doc, 80.0*10.5*365*5/1000, 0.5, 63)
    
    # IAD
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentDesign)
    _check_ceiling_fans(hpxml_doc, 42.6*10.5*365*4/1000, 0.5, 63)
    
    # IAD Reference
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentReferenceHome)
    _check_ceiling_fans(hpxml_doc, 42.6*10.5*365*4/1000, 0.5, 63)
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

  def _check_lighting(hpxml_doc, interior_kwh, exterior_kwh, garage_kwh)
    ltg = hpxml_doc.elements["/HPXML/Building/BuildingDetails/Lighting/LightingFractions"]
    assert_in_epsilon(Float(ltg.elements["extension/AnnualInteriorkWh"].text), interior_kwh, 0.01)
    assert_in_epsilon(Float(ltg.elements["extension/AnnualExteriorkWh"].text), exterior_kwh, 0.01)
    assert_in_epsilon(Float(ltg.elements["extension/AnnualGaragekWh"].text), garage_kwh, 0.01)
  end
  
  def _check_ceiling_fans(hpxml_doc, kWh=nil, clg_sp_offset=nil, monthly_temp_control=nil)
    cf = hpxml_doc.elements["/HPXML/Building/BuildingDetails/Lighting/CeilingFan"]
    if not kWh.nil?
      assert_in_epsilon(Float(cf.elements["extension/AnnualkWh"].text), kWh, 0.01)
    end
    if not clg_sp_offset.nil?
      assert_equal(Float(cf.elements["extension/CoolingSetpointOffset"].text), clg_sp_offset)
    end
    if not monthly_temp_control.nil?
      assert_equal(Float(cf.elements["extension/MonthlyOutdoorTempControl"].text), monthly_temp_control)
    end
  end
  
end