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
    _check_ceiling_fans(hpxml_doc, 0)
    
    # Rated Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_lighting(hpxml_doc, 1645, 115, 0)
    _check_ceiling_fans(hpxml_doc, 0)
    
    # IAD
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentDesign)
    _check_lighting(hpxml_doc, 1248, 96, 0)
    _check_ceiling_fans(hpxml_doc, 0)
    
    # IAD Reference
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentReferenceHome)
    _check_lighting(hpxml_doc, 2375, 220, 0)
    _check_ceiling_fans(hpxml_doc, 0)
  end
  
  def test_lighting_pre_addendum_g
    hpxml_name = "valid-addenda-exclude-g.xml"
    
    # Reference Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_lighting(hpxml_doc, 3255, 275, 0)
    _check_ceiling_fans(hpxml_doc, 0)
    
    # Rated Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_lighting(hpxml_doc, 2410, 172, 0)
    _check_ceiling_fans(hpxml_doc, 0)
    
    # IAD
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentDesign)
    _check_lighting(hpxml_doc, 1374, 96, 0)
    _check_ceiling_fans(hpxml_doc, 0)
    
    # IAD Reference
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentReferenceHome)
    _check_lighting(hpxml_doc, 2375, 220, 0)
    _check_ceiling_fans(hpxml_doc, 0)
  end
  
  def test_ceiling_fans
    hpxml_name = "valid-misc-ceiling-fans.xml"
    
    medium_cfm = 3000.0
    hrs_per_day = 10.5
    clg_sp_offset = 0.5 # F
    monthly_temp_control = 63 # F
    
    # Reference Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    cfm_per_w = medium_cfm/42.6
    _check_ceiling_fans(hpxml_doc, 5, cfm_per_w, hrs_per_day, clg_sp_offset, monthly_temp_control)
    
    # Rated Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    cfm_per_w = medium_cfm/((medium_cfm/30.0 + medium_cfm/50.0)/2)
    _check_ceiling_fans(hpxml_doc, 5, cfm_per_w, hrs_per_day, clg_sp_offset, monthly_temp_control)
    
    # IAD
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentDesign)
    cfm_per_w = medium_cfm/42.6
    _check_ceiling_fans(hpxml_doc, 4, cfm_per_w, hrs_per_day, clg_sp_offset, monthly_temp_control)
    
    # IAD Reference
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentReferenceHome)
    cfm_per_w = medium_cfm/42.6
    _check_ceiling_fans(hpxml_doc, 4, cfm_per_w, hrs_per_day, clg_sp_offset, monthly_temp_control)
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
  
  def _check_ceiling_fans(hpxml_doc, number, cfm_per_w=nil, hrs_per_day=nil, clg_sp_offset=nil, monthly_temp_control=nil)
    ltg = hpxml_doc.elements["/HPXML/Building/BuildingDetails/Lighting"]
    num_cfs = 0
    ltg.elements.each("CeilingFan") do |cf|
      num_cfs += 1
      assert_in_epsilon(Float(cf.elements["Airflow[FanSpeed='medium']/Efficiency"].text), cfm_per_w, 0.01)
      assert_equal(Float(cf.elements["extension/HoursInOperation"].text), hrs_per_day, 0.01)
    end
    assert_equal(number, num_cfs)
    if not clg_sp_offset.nil?
      assert_equal(Float(ltg.elements["extension/CeilingFanCoolingSetpointOffset"].text), clg_sp_offset)
    end
    if not monthly_temp_control.nil?
      assert_equal(Float(ltg.elements["extension/CeilingFanMonthlyOutdoorTempControl"].text), monthly_temp_control)
    end
  end
  
end