require 'openstudio'
require 'openstudio/ruleset/ShowRunnerOutput'
require 'minitest/autorun'
require 'fileutils'
require_relative '../../measures/HPXMLTranslator/measure'
require_relative '../../measures/HPXMLTranslator/resources/xmlhelper'
require_relative '../../measures/HPXMLTranslator/resources/schedules'
require_relative '../../measures/HPXMLTranslator/resources/constants'
require_relative '../../measures/HPXMLTranslator/resources/unit_conversions'
require_relative '../../measures/HPXMLTranslator/resources/hotwater_appliances'

class EnergyRatingIndexTest < Minitest::Unit::TestCase

  def test_valid_simulations
    parent_dir = File.absolute_path(File.join(File.dirname(__FILE__), ".."))
    xmldir = "#{parent_dir}/sample_files"
    Dir["#{xmldir}/valid*.xml"].sort.each do |xml|
      run_and_check(xml, parent_dir, false)
    end
  end
  
  def test_invalid_simulations
    parent_dir = File.absolute_path(File.join(File.dirname(__FILE__), ".."))
    xmldir = "#{parent_dir}/sample_files"
    Dir["#{xmldir}/invalid*.xml"].sort.each do |xml|
      run_and_check(xml, parent_dir, true)
    end
  end
  
  def test_downloading_weather
    require 'csv'
    
    parent_dir = File.absolute_path(File.join(File.dirname(__FILE__), ".."))
    cli_path = OpenStudio.getOpenStudioCLI
    command = "\"#{cli_path}\" --no-ssl \"#{File.join(File.dirname(__FILE__), "../energy_rating_index.rb")}\" --download-weather"
    system(command)
    
    num_epws_expected = File.readlines(File.join(parent_dir, "..", "weather", "data.csv")).size - 1
    num_epws_actual = Dir[File.join(parent_dir, "..", "weather", "*.epw")].count
    assert_equal(num_epws_expected, num_epws_actual)
    
    num_cache_expected = File.readlines(File.join(parent_dir, "..", "weather", "data.csv")).size - 1
    num_cache_actual = Dir[File.join(parent_dir, "..", "weather", "*.cache")].count
    assert_equal(num_cache_expected, num_cache_actual)
  end
  
  def test_resnet_ashrae_140
  
  end
  
  def test_resnet_hers_reference_home_auto_generation
    parent_dir = File.absolute_path(File.join(File.dirname(__FILE__), ".."))
    test_num = 0
    xmldir = File.join(File.dirname(__FILE__), "RESNET_Tests/4.2_Test_HERS_Reference_Home")
    Dir["#{xmldir}/*.xml"].sort.each do |xml|
      next if xml.end_with? "HERSReferenceHome.xml"
      test_num += 1
      
      # Run test
      ref_hpxml, rated_hpxml, results_csv = run_and_check(xml, parent_dir, false)
      _check_reference_home_components(ref_hpxml, test_num)
      
      # Re-simulate reference HPXML file
      FileUtils.cp(ref_hpxml, xmldir)
      ref_hpxml = "#{xmldir}/#{File.basename(ref_hpxml)}"
      ref_hpxml2, rated_hpxml2, results_csv2 = run_and_check(ref_hpxml, parent_dir, false)
      _check_e_ratio(results_csv2)
    end
  end
  
  def test_resnet_hers_method
    parent_dir = File.absolute_path(File.join(File.dirname(__FILE__), ".."))
    xmldir = File.join(File.dirname(__FILE__), "RESNET_Tests/4.3_Test_HERS_Method")
    Dir["#{xmldir}/*.xml"].sort.each do |xml|
      test_num = File.basename(xml).gsub('L100A-','').gsub('.xml','').to_i
      ref_hpxml, rated_hpxml, results_csv = run_and_check(xml, parent_dir, false)
      _check_method_results(results_csv, test_num, test_num == 2, false)
    end
  end
  
  def test_resnet_hers_method_iaf
    parent_dir = File.absolute_path(File.join(File.dirname(__FILE__), ".."))
    xmldir = File.join(File.dirname(__FILE__), "RESNET_Tests/4.3_Test_HERS_Method_IAF")
    Dir["#{xmldir}/*.xml"].sort.each do |xml|
      test_num = File.basename(xml).gsub('L100A-','').gsub('.xml','').to_i
      ref_hpxml, rated_hpxml, results_csv = run_and_check(xml, parent_dir, false, true)
      _check_method_results(results_csv, test_num, test_num == 2, true)
    end
  end
  
  def test_resnet_hers_method_proposed
    # Proposed New HERS Method Test Suite
    # Approved by RESNET Board of Directors June 16, 2016
    parent_dir = File.absolute_path(File.join(File.dirname(__FILE__), ".."))
    xmldir = File.join(File.dirname(__FILE__), "RESNET_Tests/4.3_Test_HERS_Method_Proposed")
    Dir["#{xmldir}/*.xml"].sort.each do |xml|
      if xml.include? 'AC'
        test_num = File.basename(xml).gsub('L100-AC-','').gsub('.xml','').to_i
        test_loc = 'AC'
      elsif xml.include? 'AL'
        test_num = File.basename(xml).gsub('L100-AL-','').gsub('.xml','').to_i
        test_loc = 'AL'
      end
      ref_hpxml, rated_hpxml, results_csv = run_and_check(xml, parent_dir, false)
      _check_method_proposed_results(results_csv, test_num, test_loc, test_num == 8)
    end
  end
  
  def test_resnet_hvac
    # TODO
  end
  
  def test_resnet_dse
    # TODO
  end
  
  def test_resnet_hot_water
    parent_dir = File.absolute_path(File.join(File.dirname(__FILE__), ".."))
    test_num = 0
    base_vals = {}
    mn_vals = {}
    all_results = {}
    xmldir = File.join(File.dirname(__FILE__), "RESNET_Tests/4.6_Test_Hot_Water")
    Dir["#{xmldir}/*.xml"].sort.each do |xml|
      test_num += 1
      
      # Run test
      ref_hpxml, rated_hpxml, results_csv = run_and_check(xml, parent_dir, false)
      all_results[test_num] = _get_hot_water(results_csv)
      assert_operator(all_results[test_num], :>, 0)
    end
    
    # Output results
    puts all_results
    
    # Check results
    all_results.keys.each do |test_num|
      base_val = nil
      if [2,3].include? test_num
        base_val = all_results[1]
      elsif [4,5,6,7].include? test_num
        base_val = all_results[2]
      elsif [9,10].include? test_num
        base_val = all_results[8]
      elsif [11,12,13,14].include? test_num
        base_val = all_results[9]
      end

      mn_val = nil
      if test_num >= 8
        mn_val = all_results[test_num-7]
      end
      
      _check_hot_water(test_num, all_results[test_num], base_val, mn_val)
    end
    
  end
  
  def test_resnet_hot_water_pre_addendum_a
    # Tests w/o Addendum A
    parent_dir = File.absolute_path(File.join(File.dirname(__FILE__), ".."))
    test_num = 0
    base_vals = {}
    mn_vals = {}
    all_results = {}
    xmldir = File.join(File.dirname(__FILE__), "RESNET_Tests/4.6_Test_Hot_Water_PreAddendumA")
    Dir["#{xmldir}/*.xml"].sort.each do |xml|
      test_num += 1
      
      # Run test
      ref_hpxml, rated_hpxml, results_csv = run_and_check(xml, parent_dir, false)
      all_results[test_num] = _get_hot_water(results_csv)
      assert_operator(all_results[test_num], :>, 0)
    end
    
    # Output results
    puts all_results
      
    # Check results
    all_results.keys.each do |test_num|
      base_val = nil
      if [2,3].include? test_num
        base_val = all_results[1]
      elsif [5,6].include? test_num
        base_val = all_results[4]
      end

      mn_val = nil
      if test_num >= 4
        mn_val = all_results[test_num-3]
      end
      
      _check_hot_water_pre_addendum_a(test_num, all_results[test_num], base_val, mn_val)
    end
    
  end
  
  def test_resnet_verification_building_attributes
    # TODO
  end
  
  def test_resnet_verification_mechanical_ventilation
    # TODO
  end
  
  def test_resnet_verification_appliances
    # TODO
  end
  
  def test_naseo_technical_exercises
    parent_dir = File.absolute_path(File.join(File.dirname(__FILE__), ".."))
    xmldir = "#{parent_dir}/tests/NASEO_Technical_Exercises"
    Dir["#{xmldir}/NASEO*.xml"].sort.each do |xml|
      run_and_check(xml, parent_dir, false)
    end
  end
  
  def test_running_with_cli
    # Test that these tests can be run from the OpenStudio CLI (and not just system ruby)
    parent_dir = File.absolute_path(File.join(File.dirname(__FILE__), ".."))
    
    cli_path = OpenStudio.getOpenStudioCLI
    command = "\"#{cli_path}\" --no-ssl #{File.absolute_path(__FILE__)} --name=foo"
    success = system(command)
    assert(success)
  end

  private
  
  def run_and_check(xml, parent_dir, expect_error, using_iaf=false)
    # Check input HPXML is valid
    xml = File.absolute_path(xml)
    
    # Run energy_rating_index workflow
    cli_path = OpenStudio.getOpenStudioCLI
    command = "\"#{cli_path}\" --no-ssl \"#{File.join(File.dirname(__FILE__), "../energy_rating_index.rb")}\" -x #{xml}"
    system(command)
    
    results_csv = File.join(parent_dir, "results", "ERI_Results.csv")
    if expect_error
      assert(!File.exists?(results_csv))
    else
      # Check all output files exist
      ref_hpxml = File.join(parent_dir, "results", "HERSReferenceHome.xml")
      rated_hpxml = File.join(parent_dir, "results", "HERSRatedHome.xml")
      worksheet_csv = File.join(parent_dir, "results", "ERI_Worksheet.csv")
      assert(File.exists?(ref_hpxml))
      assert(File.exists?(rated_hpxml))
      assert(File.exists?(results_csv))
      assert(File.exists?(worksheet_csv))
      if using_iaf
        iad_hpxml = File.join(parent_dir, "results", "HERSIndexAdjustmentDesign.xml")
        assert(File.exists?(iad_hpxml))
      end
      
      # Check Reference/Rated HPXMLs are valid
      _test_schema_validation(parent_dir, ref_hpxml)
      _test_schema_validation(parent_dir, rated_hpxml)
      if using_iaf
        _test_schema_validation(parent_dir, iad_hpxml)
      end
    end
  
    return ref_hpxml, rated_hpxml, results_csv
  end
  
  def _test_schema_validation(parent_dir, xml)
    # TODO: Remove this when schema validation is included with CLI calls
    schemas_dir = File.absolute_path(File.join(parent_dir, "..", "hpxml_schemas"))
    hpxml_doc = REXML::Document.new(File.read(xml))
    errors = XMLHelper.validate(hpxml_doc.to_s, File.join(schemas_dir, "HPXML.xsd"), nil)
    if errors.size > 0
      puts "#{xml}: #{errors.to_s}"
    end
    assert_equal(0, errors.size)
  end
  
  def _check_reference_home_components(ref_hpxml, test_num)
    hpxml_doc = REXML::Document.new(File.read(ref_hpxml))

    # Table 4.2.3.1(1): Acceptance Criteria for Test Cases 1 – 4
    
    epsilon = 0.0005 # 0.05%
    
    # Above-grade walls
    wall_u, wall_solar_abs, wall_emiss = _get_above_grade_walls(hpxml_doc)
    if test_num <= 3
      assert_in_delta(0.082, wall_u, 0.001)
    else
      assert_in_delta(0.060, wall_u, 0.001)
    end
    assert_equal(0.75, wall_solar_abs)
    assert_equal(0.90, wall_emiss)
    
    # Basement walls
    bsmt_wall_u = _get_basement_walls(hpxml_doc)
    if test_num == 4
      assert_in_delta(0.059, bsmt_wall_u, 0.001)
    else
      pass
    end
    
    # Above-grade floors
    floors_u = _get_above_grade_floors(hpxml_doc)
    if test_num <= 2
      assert_in_delta(0.047, floors_u, 0.001)
    else
      pass
    end
    
    # Slab insulation
    slab_r, carpet_r, exp_mas_floor_area = get_hpxml_slabs(hpxml_doc)
    if test_num >= 3
      assert_equal(0, slab_r)
    else
      pass
    end
    
    # Ceilings
    ceil_u = _get_ceilings(hpxml_doc)
    if test_num == 1 or test_num == 4
      assert_in_delta(0.030, ceil_u, 0.001)
    else
      assert_in_delta(0.035, ceil_u, 0.001)
    end
    
    # Roofs
    roof_solar_abs, roof_emiss = _get_roof(hpxml_doc)
    assert_equal(0.75, roof_solar_abs)
    assert_equal(0.90, roof_emiss)
    
    # Attic vent area
    attic_vent_area = _get_attic_vent_area(hpxml_doc)
    assert_in_epsilon(5.13, attic_vent_area, epsilon)
    
    # Crawlspace vent area
    crawl_vent_area = _get_crawl_vent_area(hpxml_doc)
    if test_num == 2
      assert_in_epsilon(10.26, crawl_vent_area, epsilon)
    else
      pass
    end
    
    # Slabs
    if test_num >= 3
      assert_in_epsilon(307.8, exp_mas_floor_area, epsilon)
      assert_equal(2.0, carpet_r)
    else
      pass
      pass
    end
    
    # Doors
    door_u, door_area = _get_doors(hpxml_doc)
    assert_equal(40, door_area)
    if test_num == 1
      assert_in_delta(0.40, door_u, 0.01)
    elsif test_num == 2
      assert_in_delta(0.65, door_u, 0.01)
    elsif test_num == 3
      assert_in_delta(1.20, door_u, 0.01)
    else
      assert_in_delta(0.35, door_u, 0.01)
    end
    
    # Windows
    win_areas, win_u, win_shgc_htg, win_shgc_clg = _get_windows(hpxml_doc)
    win_areas.values.each do |win_area|
      if test_num <= 3
        assert_in_epsilon(69.26, win_area, epsilon)
      else
        assert_in_epsilon(102.63, win_area, epsilon)
      end
    end
    if test_num == 1
      assert_in_delta(0.40, win_u, 0.01)
    elsif test_num == 2
      assert_in_delta(0.65, win_u, 0.01)
    elsif test_num == 3
      assert_in_delta(1.20, win_u, 0.01)
    else
      assert_in_delta(0.35, win_u, 0.01)
    end
    assert_in_delta(0.34, win_shgc_htg, 0.01)
    assert_in_delta(0.28, win_shgc_clg, 0.01)
    
    # SLA
    sla = _get_sla(hpxml_doc)
    assert_in_delta(0.00036, sla, 0.00001)
    
    # Internal gains
    xml_it_sens, xml_it_lat = _get_internal_gains(hpxml_doc)
    if test_num == 1
      assert_in_epsilon(55470, xml_it_sens, epsilon)
      assert_in_epsilon(13807, xml_it_lat, epsilon)
    elsif test_num == 2
      assert_in_epsilon(52794, xml_it_sens, epsilon)
      assert_in_epsilon(12698, xml_it_lat, epsilon)
    elsif test_num == 3
      assert_in_epsilon(48111, xml_it_sens, epsilon)
      assert_in_epsilon(9259, xml_it_lat, epsilon)
    else
      assert_in_epsilon(83103, xml_it_sens, epsilon)
      assert_in_epsilon(17934, xml_it_lat, epsilon)
    end
    
    # HVAC
    afue, hspf, seer, dse = _get_hvac(hpxml_doc)
    if test_num == 1 or test_num == 4
      assert_equal(0.78, afue)
    else
      assert_equal(7.7, hspf)
    end
    assert_equal(13.0, seer)
    assert_equal(0.80, dse)
    
    # Thermostat
    tstat, htg_sp, htg_setback, clg_sp, clg_setup = _get_tstat(hpxml_doc)
    assert_equal("manual", tstat)
    assert_equal(68, htg_sp)
    assert_equal(0, htg_setback)
    assert_equal(78, clg_sp)
    assert_equal(0, clg_setup)
    
    # Mechanical ventilation
    mv_kwh = _get_mech_vent(hpxml_doc)
    mv_epsilon = 0.001 # 0.1%
    if test_num == 1
      assert_in_epsilon(0.0, mv_kwh, mv_epsilon)
    elsif test_num == 2
      assert_in_epsilon(77.9, mv_kwh, mv_epsilon)
    elsif test_num == 3
      assert_in_epsilon(140.4, mv_kwh, mv_epsilon)
    else
      assert_in_epsilon(379.1, mv_kwh, mv_epsilon)
    end
    
    # Domestic hot water
    ref_pipe_l, ref_loop_l = _get_dhw(hpxml_doc)
    dhw_epsilon = 0.1 # 0.1 ft
    if test_num <= 3
      assert_in_delta(88.5, ref_pipe_l, dhw_epsilon)
      assert_in_delta(156.9, ref_loop_l, dhw_epsilon)
    else
      assert_in_delta(98.5, ref_pipe_l, dhw_epsilon)
      assert_in_delta(176.9, ref_loop_l, dhw_epsilon)
    end
           
  end
  
  def _get_above_grade_walls(hpxml_doc)
    u_factor = 0.0
    solar_abs = 0.0
    emittance = 0.0
    num = 0
    hpxml_doc.elements.each("/HPXML/Building/BuildingDetails/Enclosure/Walls/Wall") do |wall|
      u_factor += 1.0/Float(XMLHelper.get_value(wall, "Insulation/AssemblyEffectiveRValue"))
      solar_abs += Float(XMLHelper.get_value(wall, "SolarAbsorptance"))
      emittance += Float(XMLHelper.get_value(wall, "Emittance"))
      num += 1
    end
    return u_factor/num, solar_abs/num, emittance/num
  end
  
  def _get_basement_walls(hpxml_doc)
    u_factor = 0.0
    num = 0
    hpxml_doc.elements.each("/HPXML/Building/BuildingDetails/Enclosure/Foundations/Foundation[FoundationType/Basement]/FoundationWall") do |fnd_wall|
      u_factor += 1.0/Float(XMLHelper.get_value(fnd_wall, "Insulation/AssemblyEffectiveRValue"))
      num += 1
    end
    return u_factor/num
  end

  def _get_above_grade_floors(hpxml_doc)
    u_factor = 0.0
    num = 0
    hpxml_doc.elements.each("/HPXML/Building/BuildingDetails/Enclosure/Foundations/Foundation[FoundationType/Ambient|FoundationType/Crawlspace]/FrameFloor") do |amb_ceil|
      u_factor += 1.0/Float(XMLHelper.get_value(amb_ceil, "Insulation/AssemblyEffectiveRValue"))
      num += 1
    end
    return u_factor/num
  end
  
  def get_hpxml_slabs(hpxml_doc)
    r_value = 0.0
    carpet_r_value = 0.0
    exp_area = 0.0
    carpet_num = 0
    r_num = 0
    hpxml_doc.elements.each("/HPXML/Building/BuildingDetails/Enclosure/Foundations/Foundation/Slab") do |fnd_slab|
      exp_frac = 1.0 - Float(XMLHelper.get_value(fnd_slab, "extension/CarpetFraction"))
      exp_area += (Float(XMLHelper.get_value(fnd_slab, "Area")) * exp_frac)
      carpet_r_value += Float(XMLHelper.get_value(fnd_slab, "extension/CarpetRValue"))
      carpet_num += 1
      r_value += Float(XMLHelper.get_value(fnd_slab, "PerimeterInsulation/Layer[InstallationType='continuous']/NominalRValue"))
      r_num += 1
      r_value += Float(XMLHelper.get_value(fnd_slab, "UnderSlabInsulation/Layer[InstallationType='continuous']/NominalRValue"))
      r_num += 1
    end
    return r_value/r_num, carpet_r_value/carpet_num, exp_area
  end
  
  def _get_ceilings(hpxml_doc)
    u_factor = 0.0
    num = 0
    hpxml_doc.elements.each("/HPXML/Building/BuildingDetails/Enclosure/AtticAndRoof/Attics/Attic/Floors/Floor") do |attc_floor|
      u_factor += 1.0/Float(XMLHelper.get_value(attc_floor, "Insulation/AssemblyEffectiveRValue"))
      num += 1
    end
    return u_factor/num
  end
  
  def _get_roof(hpxml_doc)
    solar_abs = 0.0
    emittance = 0.0
    num = 0
    hpxml_doc.elements.each("/HPXML/Building/BuildingDetails/Enclosure/AtticAndRoof/Attics/Attic/Roofs/Roof") do |roof|
      solar_abs += Float(XMLHelper.get_value(roof, "SolarAbsorptance"))
      emittance += Float(XMLHelper.get_value(roof, "Emittance"))
      num += 1
    end
    return solar_abs/num, emittance/num
  end
  
  def _get_attic_vent_area(hpxml_doc)
    area = 0.0
    sla = 0.0
    hpxml_doc.elements.each("/HPXML/Building/BuildingDetails/Enclosure/AtticAndRoof/Attics/Attic[AtticType='vented attic']") do |attc|
      area = REXML::XPath.first(attc, "sum(Floors/Floor/Area/text())")
      sla += Float(XMLHelper.get_value(attc, "extension/AtticSpecificLeakageArea"))
    end
    return sla*area
  end
  
  def _get_crawl_vent_area(hpxml_doc)
    area = 0.0
    sla = 0.0
    hpxml_doc.elements.each("/HPXML/Building/BuildingDetails/Enclosure/Foundations/Foundation[FoundationType/Crawlspace[Vented='true']]") do |foundation|
      area = REXML::XPath.first(foundation, "sum(FrameFloor/Area/text())")
      sla += Float(XMLHelper.get_value(foundation, "extension/CrawlspaceSpecificLeakageArea"))
    end
    return sla*area
  end
  
  def _get_doors(hpxml_doc)
    area = 0.0
    u_factor = 0.0
    num = 0
    hpxml_doc.elements.each("/HPXML/Building/BuildingDetails/Enclosure/Doors/Door") do |door|
      area += Float(XMLHelper.get_value(door, "Area"))
      u_factor += 1.0/Float(XMLHelper.get_value(door, "RValue"))
      num += 1
    end
    return u_factor/num, area
  end
  
  def _get_windows(hpxml_doc)
    areas = {0=>0.0, 90=>0.0, 180=>0.0, 270=>0.0}
    u_factor = 0.0
    shgc_htg = 0.0
    shgc_clg = 0.0
    num = 0
    hpxml_doc.elements.each("/HPXML/Building/BuildingDetails/Enclosure/Windows/Window") do |win|
      azimuth = Integer(XMLHelper.get_value(win, "Azimuth"))
      areas[azimuth] += Float(XMLHelper.get_value(win, "Area"))
      u_factor += Float(XMLHelper.get_value(win, "UFactor"))
      shgc = Float(XMLHelper.get_value(win, "SHGC"))
      shading_winter = Float(XMLHelper.get_value(win, "extension/InteriorShadingFactorWinter"))
      shading_summer = Float(XMLHelper.get_value(win, "extension/InteriorShadingFactorSummer"))
      shgc_htg += (shgc * shading_winter)
      shgc_clg += (shgc * shading_summer)
      num += 1
    end
    return areas, u_factor/num, shgc_htg/num, shgc_clg/num
  end
  
  def _get_sla(hpxml_doc)
    ela = Float(XMLHelper.get_value(hpxml_doc, "/HPXML/Building/BuildingDetails/Enclosure/AirInfiltration/AirInfiltrationMeasurement/EffectiveLeakageArea"))
    area = Float(XMLHelper.get_value(hpxml_doc, "/HPXML/Building/BuildingDetails/BuildingSummary/BuildingConstruction/ConditionedFloorArea"))
    return ela / area
  end
  
  def _get_internal_gains(hpxml_doc)
  
    s = ""
    nbeds = Float(XMLHelper.get_value(hpxml_doc, "/HPXML/Building/BuildingDetails/BuildingSummary/BuildingConstruction/NumberofBedrooms"))
    eri_version = XMLHelper.get_value(hpxml_doc, "/HPXML/SoftwareInfo/extension/ERICalculation/Version")
  
    # Plug loads
    xml_pl_sens = 0.0
    xml_pl_lat = 0.0
    hpxml_doc.elements.each("/HPXML/Building/BuildingDetails/MiscLoads/PlugLoad") do |pl|
      frac_sens = Float(XMLHelper.get_value(pl, "extension/FracSensible"))
      frac_lat = Float(XMLHelper.get_value(pl, "extension/FracLatent"))
      btu = UnitConversions.convert(Float(XMLHelper.get_value(pl, "Load[Units='kWh/year']/Value")), "kWh", "Btu")
      xml_pl_sens += (frac_sens * btu)
      xml_pl_lat += (frac_lat * btu)
    end
    s += "#{xml_pl_sens} #{xml_pl_lat}\n"
    
    xml_appl_sens = 0.0
    xml_appl_lat = 0.0
    
    # Appliances: CookingRange
    hpxml_doc.elements.each("/HPXML/Building/BuildingDetails/Appliances/CookingRange") do |appl|
      cook_fuel_type = hpxml_to_beopt_fuel(XMLHelper.get_value(appl, "FuelType"))
      cook_is_induction = Boolean(XMLHelper.get_value(appl, "IsInduction"))
      oven_is_convection = Boolean(XMLHelper.get_value(appl, "../Oven/IsConvection"))
      cook_annual_kwh, cook_annual_therm, cook_frac_sens, cook_frac_lat = HotWaterAndAppliances.calc_range_oven_energy(nbeds, cook_fuel_type, cook_is_induction, oven_is_convection)
      btu = UnitConversions.convert(cook_annual_kwh, "kWh", "Btu") + UnitConversions.convert(cook_annual_therm, "therm", "Btu")
      xml_appl_sens += (cook_frac_sens * btu)
      xml_appl_lat += (cook_frac_lat * btu)
    end
    
    # Appliances: Refrigerator
    hpxml_doc.elements.each("/HPXML/Building/BuildingDetails/Appliances/Refrigerator") do |appl|
      btu = UnitConversions.convert(Float(XMLHelper.get_value(appl, "RatedAnnualkWh")), "kWh", "Btu")
      xml_appl_sens += btu
    end
    
    # Appliances: Dishwasher
    hpxml_doc.elements.each("/HPXML/Building/BuildingDetails/Appliances/Dishwasher") do |appl|
      dw_ef = Float(XMLHelper.get_value(appl, "EnergyFactor"))
      dw_cap = Float(XMLHelper.get_value(appl, "PlaceSettingCapacity"))
      dw_annual_kwh, dw_frac_sens, dw_frac_lat, dw_gpd = HotWaterAndAppliances.calc_dishwasher_energy_gpd(eri_version, nbeds, dw_ef, dw_cap)
      btu = UnitConversions.convert(dw_annual_kwh, "kWh", "Btu")
      xml_appl_sens += (dw_frac_sens * btu)
      xml_appl_lat += (dw_frac_lat * btu)
    end
    
    # Appliances: ClothesWasher
    hpxml_doc.elements.each("/HPXML/Building/BuildingDetails/Appliances/ClothesWasher") do |appl|
      cw_ler = Float(XMLHelper.get_value(appl, "RatedAnnualkWh"))
      cw_elec_rate = Float(XMLHelper.get_value(appl, "LabelElectricRate"))
      cw_gas_rate = Float(XMLHelper.get_value(appl, "LabelGasRate"))
      cw_agc = Float(XMLHelper.get_value(appl, "LabelAnnualGasCost"))
      cw_cap = Float(XMLHelper.get_value(appl, "Capacity"))
      cw_annual_kwh, cw_frac_sens, cw_frac_lat, cw_gpd = HotWaterAndAppliances.calc_clothes_washer_energy_gpd(eri_version, nbeds, cw_ler, cw_elec_rate, cw_gas_rate, cw_agc, cw_cap)
      btu = UnitConversions.convert(cw_annual_kwh, "kWh", "Btu")
      xml_appl_sens += (cw_frac_sens * btu)
      xml_appl_lat += (cw_frac_lat * btu)
    end
    
    # Appliances: ClothesDryer
    hpxml_doc.elements.each("/HPXML/Building/BuildingDetails/Appliances/ClothesDryer") do |appl|
      cd_fuel = hpxml_to_beopt_fuel(XMLHelper.get_value(appl, "FuelType"))
      cd_ef = Float(XMLHelper.get_value(appl, "EnergyFactor"))
      cd_control = XMLHelper.get_value(appl, "ControlType")
      cw_ler = Float(XMLHelper.get_value(appl, "../ClothesWasher/RatedAnnualkWh"))
      cw_cap = Float(XMLHelper.get_value(appl, "../ClothesWasher/Capacity"))
      cw_mef = Float(XMLHelper.get_value(appl, "../ClothesWasher/ModifiedEnergyFactor"))
      cd_annual_kwh, cd_annual_therm, cd_frac_sens, cd_frac_lat = HotWaterAndAppliances.calc_clothes_dryer_energy(nbeds, cd_fuel, cd_ef, cd_control, cw_ler, cw_cap, cw_mef)
      btu = UnitConversions.convert(cd_annual_kwh, "kWh", "Btu") + UnitConversions.convert(cd_annual_therm, "therm", "Btu")
      xml_appl_sens += (cd_frac_sens * btu)
      xml_appl_lat += (cd_frac_lat * btu)
    end
    
    s += "#{xml_appl_sens} #{xml_appl_lat}\n"
    
    # Water Use
    xml_water_sens = 0.0
    xml_water_lat = 0.0
    hpxml_doc.elements.each("/HPXML/Building/BuildingDetails/Systems/WaterHeating/WaterFixture") do |wf|
      xml_water_sens += Float(XMLHelper.get_value(wf, "extension/AnnualSensibleGainsBtu"))
      xml_water_lat += Float(XMLHelper.get_value(wf, "extension/AnnualLatentGainsBtu"))
    end
    s += "#{xml_water_sens} #{xml_water_lat}\n"
    
    # Occupants
    xml_occ_sens = 0.0
    xml_occ_lat = 0.0
    hpxml_doc.elements.each("/HPXML/Building/BuildingDetails/BuildingSummary/BuildingOccupancy") do |occ|
      frac_sens = Float(XMLHelper.get_value(occ, "extension/FracSensible"))
      frac_lat = Float(XMLHelper.get_value(occ, "extension/FracLatent"))
      btu = Float(XMLHelper.get_value(occ, "NumberofResidents")) * Float(XMLHelper.get_value(occ, "extension/HeatGainBtuPerPersonPerHr")) * Float(XMLHelper.get_value(occ, "extension/PersonHrsPerDay")) * 365.0
      xml_occ_sens += (frac_sens * btu)
      xml_occ_lat += (frac_lat * btu)
    end
    s += "#{xml_occ_sens} #{xml_occ_lat}\n"
    
    # Lighting
    xml_ltg_sens = 0.0
    hpxml_doc.elements.each("/HPXML/Building/BuildingDetails/Lighting") do |ltg|
      ltg_kwh = Float(XMLHelper.get_value(ltg, "extension/AnnualInteriorkWh")) + Float(XMLHelper.get_value(ltg, "extension/AnnualGaragekWh"))
      xml_ltg_sens += UnitConversions.convert(ltg_kwh, "kWh", "Btu")
    end
    s += "#{xml_ltg_sens}\n"
    
    xml_btu_sens = (xml_pl_sens + xml_appl_sens + xml_water_sens + xml_occ_sens + xml_ltg_sens)/365.0
    xml_btu_lat = (xml_pl_lat + xml_appl_lat + xml_water_lat + xml_occ_lat)/365.0
    
    return xml_btu_sens, xml_btu_lat
  end
  
  def _get_hvac(hpxml_doc)
    afue = 0.0
    hspf = 0.0
    seer = 0.0
    dse = 0.0
    num_afue = 0
    num_hspf = 0
    num_seer = 0
    num_dse = 0
    hpxml_doc.elements.each("/HPXML/Building/BuildingDetails/Systems/HVAC/HVACPlant/HeatingSystem") do |htg|
      afue += Float(XMLHelper.get_value(htg, "AnnualHeatingEfficiency[Units='AFUE']/Value"))
      num_afue += 1
    end
    hpxml_doc.elements.each("/HPXML/Building/BuildingDetails/Systems/HVAC/HVACPlant/CoolingSystem") do |clg|
      seer += Float(XMLHelper.get_value(clg, "AnnualCoolingEfficiency[Units='SEER']/Value"))
      num_seer += 1
    end
    hpxml_doc.elements.each("/HPXML/Building/BuildingDetails/Systems/HVAC/HVACPlant/HeatPump") do |hp|
      if hp.elements["AnnualHeatingEfficiency[Units='HSPF']"]
        hspf += Float(XMLHelper.get_value(hp, "AnnualHeatingEfficiency[Units='HSPF']/Value"))
        num_hspf += 1
      end
      if hp.elements["AnnualCoolingEfficiency[Units='SEER']"]
        seer += Float(XMLHelper.get_value(hp, "AnnualCoolingEfficiency[Units='SEER']/Value"))
        num_seer += 1
      end
    end
    hpxml_doc.elements.each("/HPXML/Building/BuildingDetails/Systems/HVAC/HVACDistribution") do |dist|
      dse += Float(XMLHelper.get_value(dist, "AnnualHeatingDistributionSystemEfficiency"))
      num_dse += 1
      dse += Float(XMLHelper.get_value(dist, "AnnualCoolingDistributionSystemEfficiency"))
      num_dse += 1
    end
    return afue/num_afue, hspf/num_hspf, seer/num_seer, dse/num_dse
  end
  
  def _get_tstat(hpxml_doc)
    tstat = ""
    htg_sp = 0.0
    htg_setback = 0.0
    clg_sp = 0.0
    clg_setup = 0.0
    num = 0
    hpxml_doc.elements.each("/HPXML/Building/BuildingDetails/Systems/HVAC/HVACControl") do |ctrl|
      tstat = XMLHelper.get_value(ctrl, "ControlType").gsub(" thermostat", "")
      htg_sp += Float(XMLHelper.get_value(ctrl, "SetpointTempHeatingSeason"))
      if ctrl.elements["SetbackTempHeatingSeason"]
        htg_setback += Float(XMLHelper.get_value(ctrl, "SetbackTempHeatingSeason"))
      end
      clg_sp += Float(XMLHelper.get_value(ctrl, "SetpointTempCoolingSeason"))
      if ctrl.elements["SetupTempCoolingSeason"]
        clg_setup += Float(XMLHelper.get_value(ctrl, "SetupTempCoolingSeason"))
      end
      num += 1
    end
    return tstat, htg_sp/num, htg_setback/num, clg_sp/num, clg_setup/num
  end
  
  def _get_mech_vent(hpxml_doc)
    mv_kwh = 0.0
    hpxml_doc.elements.each("/HPXML/Building/BuildingDetails/Systems/MechanicalVentilation/VentilationFans/VentilationFan[UsedForWholeBuildingVentilation='true']") do |mv|
      hours = Float(XMLHelper.get_value(mv, "HoursInOperation"))
      fan_w = Float(XMLHelper.get_value(mv, "FanPower"))
      mv_kwh += fan_w * 8.76 * hours/24.0
    end
    return mv_kwh
  end
  
  def _get_dhw(hpxml_doc)
    ref_pipe_l = 0.0
    ref_loop_l = 0.0
    hpxml_doc.elements.each("/HPXML/Building/BuildingDetails/Systems/WaterHeating/HotWaterDistribution") do |hwdist|
      if hwdist.elements["SystemType/Standard/PipingLength"]
        ref_pipe_l += Float(XMLHelper.get_value(hwdist, "SystemType/Standard/PipingLength"))
      end
      if hwdist.elements["extension/RefLoopL"]
        ref_loop_l += Float(XMLHelper.get_value(hwdist, "extension/RefLoopL"))
      end
    end
    return ref_pipe_l, ref_loop_l
  end
  
  def _check_e_ratio(results_csv)
    require 'csv'
    hers_index = nil
    CSV.foreach(results_csv) do |row|
      next if row[0] != "HERS Index"
      hers_index = Float(row[1])
      break
    end
    assert_in_epsilon(100, hers_index, 0.005)
  end
  
  def _check_method_results(results_csv, test_num, has_tankless_water_heater, using_iaf)
    require 'csv'
    values = {}
    CSV.foreach(results_csv) do |row|
      values[row[0]] = Float(row[1])
    end
    
    cooling_fuel =  {1=>'elec', 2=>'elec', 3=>'elec', 4=>'elec', 5=>'elec'}
    cooling_mepr =  {1=>10.00,  2=>10.00,  3=>10.00,  4=>10.00,  5=>10.00 }
    heating_fuel =  {1=>'elec', 2=>'elec', 3=>'gas',  4=>'elec', 5=>'gas' }
    heating_mepr =  {1=>6.80,   2=>6.80,   3=>0.78,   4=>9.85,   5=>0.96  }
    hotwater_fuel = {1=>'elec', 2=>'gas',  3=>'elec', 4=>'elec', 5=>'elec'}
    hotwater_mepr = {1=>0.88,   2=>0.82,   3=>0.88,   4=>0.88,   5=>0.88  }
    ec_x_la =       {1=>21.27,  2=>23.33,  3=>22.05,  4=>22.35,  5=>23.33 }
    
    cfa = {1=>1539, 2=>1539, 3=>1539, 4=>1539, 5=>1539}
    nbr = {1=>3,    2=>3,    3=>2,    4=>4,    5=>3}
    nst = {1=>1,    2=>1,    3=>1,    4=>1,    5=>1}
      
    _check_method_results_hers_score(test_num, values, cooling_fuel, cooling_mepr, heating_fuel, heating_mepr, hotwater_fuel, hotwater_mepr, ec_x_la, has_tankless_water_heater, using_iaf, cfa, nbr, nst)
    
  end
  
  def _check_method_proposed_results(results_csv, test_num, test_loc, has_tankless_water_heater)
    require 'csv'
    values = {}
    CSV.foreach(results_csv) do |row|
      values[row[0]] = Float(row[1])
    end
    
    if test_loc == 'AC'
      cooling_fuel =  {6=>'elec', 7=>'elec', 8=>'elec', 9=>'elec', 10=>'elec', 11=>'elec', 12=>'elec', 13=>'elec', 14=>'elec', 15=>'elec', 16=>'elec', 17=>'elec', 18=>'elec', 19=>'elec', 20=>'elec', 21=>'elec', 22=>'elec'}
      cooling_mepr =  {6=>13.00,  7=>13.00,  8=>13.00,  9=>13.00,  10=>13.00,  11=>13.00,  12=>13.00,  13=>13.00,  14=>21.00,  15=>13.00,  16=>13.00,  17=>13.00,  18=>13.00,  19=>13.00,  20=>13.00,  21=>13.00,  22=>13.00 }
      heating_fuel =  {6=>'gas',  7=>'gas',  8=>'gas',  9=>'gas',  10=>'gas',  11=>'gas',  12=>'gas',  13=>'gas',  14=>'gas',  15=>'gas',  16=>'gas',  17=>'gas',  18=>'gas',  19=>'elec', 20=>'elec', 21=>'gas',  22=>'gas' }
      heating_mepr =  {6=>0.80,   7=>0.96,   8=>0.80,   9=>0.80,   10=>0.80,   11=>0.80,   12=>0.80,   13=>0.80,   14=>0.80,   15=>0.80,   16=>0.80,   17=>0.80,   18=>0.80,   19=>8.20,   20=>12.0,   21=>0.80,   22=>0.80  }
      hotwater_fuel = {6=>'gas',  7=>'gas',  8=>'gas',  9=>'gas',  10=>'gas',  11=>'gas',  12=>'elec', 13=>'elec', 14=>'gas',  15=>'gas',  16=>'gas',  17=>'gas',  18=>'gas',  19=>'gas',  20=>'gas',  21=>'gas',  22=>'gas' }
      hotwater_mepr = {6=>0.62,   7=>0.62,   8=>0.83,   9=>0.62,   10=>0.62,   11=>0.62,   12=>0.95,   13=>2.50,   14=>0.62,   15=>0.62,   16=>0.62,   17=>0.62,   18=>0.62,   19=>0.62,   20=>0.62,   21=>0.62,   22=>0.62  }
      ec_x_la =       {6=>21.86,  7=>21.86,  8=>21.86,  9=>20.70,  10=>23.02,  11=>23.92,  12=>21.86,  13=>21.86,  14=>21.86,  15=>21.86,  16=>21.86,  17=>21.86,  18=>21.86,  19=>21.86,  20=>21.86,  21=>21.86,  22=>21.86}
    elsif test_loc == 'AL'
      cooling_fuel =  {6=>'elec', 7=>'elec', 8=>'elec', 9=>'elec', 10=>'elec', 11=>'elec', 12=>'elec', 13=>'elec', 14=>'elec', 15=>'elec', 16=>'elec', 17=>'elec', 18=>'elec', 19=>'elec', 20=>'elec', 21=>'elec', 22=>'elec'}
      cooling_mepr =  {6=>14.00,  7=>14.00,  8=>14.00,  9=>14.00,  10=>14.00,  11=>14.00,  12=>14.00,  13=>14.00,  14=>21.00,  15=>14.00,  16=>14.00,  17=>14.00,  18=>14.00,  19=>14.00,  20=>14.00,  21=>14.00,  22=>14.00 }
      heating_fuel =  {6=>'gas',  7=>'gas',  8=>'gas',  9=>'gas',  10=>'gas',  11=>'gas',  12=>'gas',  13=>'gas',  14=>'gas',  15=>'gas',  16=>'gas',  17=>'gas',  18=>'gas',  19=>'elec', 20=>'elec', 21=>'gas',  22=>'gas' }
      heating_mepr =  {6=>0.80,   7=>0.96,   8=>0.80,   9=>0.80,   10=>0.80,   11=>0.80,   12=>0.80,   13=>0.80,   14=>0.80,   15=>0.80,   16=>0.80,   17=>0.80,   18=>0.80,   19=>8.20,   20=>12.0,   21=>0.80,   22=>0.80  }
      hotwater_fuel = {6=>'gas',  7=>'gas',  8=>'gas',  9=>'gas',  10=>'gas',  11=>'gas',  12=>'elec', 13=>'elec', 14=>'gas',  15=>'gas',  16=>'gas',  17=>'gas',  18=>'gas',  19=>'gas',  20=>'gas',  21=>'gas',  22=>'gas' }
      hotwater_mepr = {6=>0.62,   7=>0.62,   8=>0.83,   9=>0.62,   10=>0.62,   11=>0.62,   12=>0.95,   13=>2.50,   14=>0.62,   15=>0.62,   16=>0.62,   17=>0.62,   18=>0.62,   19=>0.62,   20=>0.62,   21=>0.62,   22=>0.62  }
      ec_x_la =       {6=>21.86,  7=>21.86,  8=>21.86,  9=>20.70,  10=>23.02,  11=>23.92,  12=>21.86,  13=>21.86,  14=>21.86,  15=>21.86,  16=>21.86,  17=>21.86,  18=>21.86,  19=>21.86,  20=>21.86,  21=>21.86,  22=>21.86}
    end
    
    _check_method_results_hers_score(test_num, values, cooling_fuel, cooling_mepr, heating_fuel, heating_mepr, hotwater_fuel, hotwater_mepr, ec_x_la, has_tankless_water_heater, false, nil, nil, nil)
    
  end
  
  def _check_method_results_hers_score(test_num, values, cooling_fuel, cooling_mepr, heating_fuel, heating_mepr, hotwater_fuel, hotwater_mepr, ec_x_la, has_tankless_water_heater, using_iaf, cfa, nbr, nst)
                                       
    if heating_fuel[test_num] == 'gas'
      heating_a = 1.0943
      heating_b = 0.403
      heating_eec_r = 1.0 / 0.78
      heating_eec_x = 1.0 / heating_mepr[test_num]
    else
      heating_a = 2.2561
      heating_b = 0.0
      heating_eec_r = 3.413 / 7.7
      heating_eec_x = 3.413 / heating_mepr[test_num]
    end
    
    cooling_a = 3.8090
    cooling_b = 0.0
    cooling_eec_r = 3.413 / 13.0
    cooling_eec_x = 3.413 / cooling_mepr[test_num]
    
    if hotwater_fuel[test_num] == 'gas'
      hotwater_a = 1.1877
      hotwater_b = 1.013
      hotwater_eec_r = 1.0 / 0.59
    else
      hotwater_a = 0.92
      hotwater_b = 0.0
      hotwater_eec_r = 1.0 / 0.92
    end
    if not has_tankless_water_heater
      hotwater_eec_x = 1.0 / hotwater_mepr[test_num]
    else
      hotwater_eec_x = 1.0 / (hotwater_mepr[test_num] * 0.92)
    end
                                       
    heating_dse_r = values['REUL Heating (MBtu)'] / values['EC_r Heating (MBtu)'] * heating_eec_r
    cooling_dse_r = values['REUL Cooling (MBtu)'] / values['EC_r Cooling (MBtu)'] * cooling_eec_r
    hotwater_dse_r = values['REUL Hot Water (MBtu)'] / values['EC_r Hot Water (MBtu)'] * hotwater_eec_r
    
    heating_nec_x = (heating_a * heating_eec_x - heating_b) * (values['EC_x Heating (MBtu)'] * values['EC_r Heating (MBtu)'] * heating_dse_r) / (heating_eec_x * values['REUL Heating (MBtu)'])
    cooling_nec_x = (cooling_a * cooling_eec_x - cooling_b) * (values['EC_x Cooling (MBtu)'] * values['EC_r Cooling (MBtu)'] * cooling_dse_r) / (cooling_eec_x * values['REUL Cooling (MBtu)'])
    hotwater_nec_x = (hotwater_a * hotwater_eec_x - hotwater_b) * (values['EC_x Hot Water (MBtu)'] * values['EC_r Hot Water (MBtu)'] * hotwater_dse_r) / (hotwater_eec_x * values['REUL Hot Water (MBtu)'])
    
    heating_nmeul = values['REUL Heating (MBtu)'] * (heating_nec_x / values['EC_r Heating (MBtu)'])
    cooling_nmeul = values['REUL Cooling (MBtu)'] * (cooling_nec_x / values['EC_r Cooling (MBtu)'])
    hotwater_nmeul = values['REUL Hot Water (MBtu)'] * (hotwater_nec_x / values['EC_r Hot Water (MBtu)'])
    
    if using_iaf
      iaf_cfa = ((2400.0 / cfa[test_num]) ** (0.304 * values['IAD_Save (%)']))
      iaf_nbr = (1.0 + (0.069 * values['IAD_Save (%)'] * (nbr[test_num] - 3.0)))
      iaf_nst = ((2.0 / nst[test_num]) ** (0.12 * values['IAD_Save (%)']))
      iaf_rh = iaf_cfa * iaf_nbr * iaf_nst
    end
    
    tnml = heating_nmeul + cooling_nmeul + hotwater_nmeul + values['EC_x L&A (MBtu)']
    trl = values['REUL Heating (MBtu)'] + values['REUL Cooling (MBtu)'] + values['REUL Hot Water (MBtu)'] + ec_x_la[test_num]
    
    if using_iaf
      trl_iaf = trl * iaf_rh
      hers_score = 100 * tnml / trl_iaf
    else
      hers_score = 100 * tnml / trl
    end
    
    assert_operator((values['HERS Index'] - hers_score).abs / values['HERS Index'], :<, 0.005)
  end
  
  def _get_hot_water(results_csv)
    require 'csv'
    rated_dhw = nil
    CSV.foreach(results_csv) do |row|
      next if row[0] != "EC_x Hot Water (MBtu)"
      rated_dhw = Float(row[1])
      break
    end
    return rated_dhw
  end
  
  def _check_hot_water(test_num, curr_val, base_val=nil, mn_val=nil)

    # Table 4.6.2(1): Acceptance Criteria for Hot Water Tests
    min_max_abs = nil
    min_max_base_delta_percent = nil
    min_max_mn_delta_percent = nil
    if test_num == 1
      min_max_abs = [19.11, 19.73]
    elsif test_num == 2
      min_max_abs = [25.54, 26.36]
      min_max_base_delta_percent = [-34.01, -32.49]
    elsif test_num == 3
      min_max_abs = [17.03, 17.50]
      min_max_base_delta_percent = [10.74, 11.57]
    elsif test_num == 4
      min_max_abs = [24.75, 25.52]
      min_max_base_delta_percent = [3.06, 3.22]
    elsif test_num == 5
      min_max_abs = [55.43, 57.15]
      min_max_base_delta_percent = [-118.52, -115.63]
    elsif test_num == 6
      min_max_abs = [22.39, 23.09]
      min_max_base_delta_percent = [12.17, 12.51]
    elsif test_num == 7
      min_max_abs = [20.29, 20.94]
      min_max_base_delta_percent = [20.15, 20.78]
    elsif test_num == 8
      min_max_abs = [10.59, 11.03]
      min_max_mn_delta_percent = [43.35, 45.00]
    elsif test_num == 9
      min_max_abs = [13.17, 13.68]
      min_max_base_delta_percent = [-24.54, -23.47]
      min_max_mn_delta_percent = [47.26, 48.93]
    elsif test_num == 10
      min_max_abs = [8.81, 9.13]
      min_max_base_delta_percent = [16.65, 18.12]
      min_max_mn_delta_percent = [47.38, 48.74]
    elsif test_num == 11
      min_max_abs = [12.87, 13.36]
      min_max_base_delta_percent = [2.20, 2.38]
      min_max_mn_delta_percent = [46.81, 48.48]
    elsif test_num == 12
      min_max_abs = [30.19, 31.31]
      min_max_base_delta_percent = [-130.88, -127.52]
      min_max_mn_delta_percent = [44.41, 45.99]
    elsif test_num == 13
      min_max_abs = [11.90, 12.38]
      min_max_base_delta_percent = [9.38, 9.74]
      min_max_mn_delta_percent = [45.60, 47.33]
    elsif test_num == 14
      min_max_abs = [11.68, 12.14]
      min_max_base_delta_percent = [11.00, 11.40]
      min_max_mn_delta_percent = [41.32, 42.86]
    else
      fail "Unexpected test."
    end
    
    base_delta_percent = nil
    mn_delta_percent = nil
    if not min_max_base_delta_percent.nil? and not base_val.nil?
      base_delta_percent = (base_val-curr_val)/base_val*100.0 # %
    end
    if not min_max_mn_delta_percent.nil? and not mn_val.nil?
      mn_delta_percent = (mn_val-curr_val)/mn_val*100.0 # %
    end
    
    assert_operator(curr_val, :>=, min_max_abs[0])
    assert_operator(curr_val, :<=, min_max_abs[1])
    if not base_delta_percent.nil?
      assert_operator(base_delta_percent, :>=, min_max_base_delta_percent[0])
      assert_operator(base_delta_percent, :<=, min_max_base_delta_percent[1])
    end
    if not mn_delta_percent.nil?
      assert_operator(mn_delta_percent, :>=, min_max_mn_delta_percent[0])
      assert_operator(mn_delta_percent, :<=, min_max_mn_delta_percent[1])
    end
    
  end
  
  def _check_hot_water_pre_addendum_a(test_num, curr_val, base_val=nil, mn_val=nil)
    
    # Acceptance criteria from HERS Hot Water Performance Tests Excel spreadsheet
    min_max_abs = nil
    min_max_fl_delta_abs = nil
    min_max_base_delta_percent = nil
    min_max_fl_delta_percent = nil
    if test_num == 1
      min_max_abs = [18.2, 22.0]
    elsif test_num == 2
      min_max_base_delta_percent = [26.5, 32.2]
    elsif test_num == 3
      min_max_base_delta_percent = [-11.8, -6.8]
    elsif test_num == 4
      min_max_abs = [10.9, 14.4]
      min_max_fl_delta_abs = [5.5, 9.4]
      min_max_fl_delta_percent = [28.9, 45.1]
    elsif test_num == 5
      min_max_base_delta_percent = [19.1, 29.1]
    elsif test_num == 6
      min_max_base_delta_percent = [-19.5, -7.7]
    else
      fail "Unexpected test."
    end
    
    base_delta = nil
    mn_delta = nil
    fl_delta_percent = nil
    if not min_max_base_delta_percent.nil? and not base_val.nil?
      base_delta = (curr_val-base_val)/base_val*100.0 # %
    end
    if not min_max_fl_delta_abs.nil? and not mn_val.nil?
      fl_delta = mn_val-curr_val
    end
    if not min_max_fl_delta_percent.nil? and not mn_val.nil?
      fl_delta_percent = (mn_val-curr_val)/mn_val*100.0 # %
    end
    
    if not min_max_abs.nil?
      assert_operator(curr_val, :>=, min_max_abs[0])
      assert_operator(curr_val, :<=, min_max_abs[1])
    end
    if not base_delta.nil?
      assert_operator(base_delta, :>=, min_max_base_delta_percent[0])
      assert_operator(base_delta, :<=, min_max_base_delta_percent[1])
    end
    if not fl_delta.nil?
      assert_operator(fl_delta, :>=, min_max_fl_delta_abs[0])
      assert_operator(fl_delta, :<=, min_max_fl_delta_abs[1])
    end
    if not fl_delta_percent.nil?
      assert_operator(fl_delta_percent, :>=, min_max_fl_delta_percent[0])
      assert_operator(fl_delta_percent, :<=, min_max_fl_delta_percent[1])
    end
    
  end
  
end
