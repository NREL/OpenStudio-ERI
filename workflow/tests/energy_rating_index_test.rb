require 'openstudio'
require 'openstudio/ruleset/ShowRunnerOutput'
require 'minitest/autorun'
require 'fileutils'
require_relative '../../resources/xmlhelper.rb'

class EnergyRatingIndexTest < MiniTest::Test

  def test_sample_simulations
    parent_dir = File.absolute_path(File.join(File.dirname(__FILE__), ".."))
    Dir["#{parent_dir}/sample_files/*.xml"].each do |xml|
      ref_hpxml, rated_hpxml, results_csv = run_and_check(xml, parent_dir)
    end
  end
  
  def test_resnet_ashrae_140
  
  end
  
  def test_resnet_hers_reference_home_auto_generation
    parent_dir = File.absolute_path(File.join(File.dirname(__FILE__), ".."))
    test_num = 0
    xmldir = "#{parent_dir}/sample_files/RESNET_Tests/4.2_Test_HERS_Reference_Home"
    Dir["#{xmldir}/*.xml"].each do |xml|
      next if xml.end_with? "HERSReferenceHome.xml"
      test_num += 1
      
      # Run test
      ref_hpxml, rated_hpxml, results_csv = run_and_check(xml, parent_dir)
      _check_reference_home_components(ref_hpxml, test_num)
      
      # Re-simulate reference HPXML file
      FileUtils.cp(ref_hpxml, xmldir)
      ref_hpxml = "#{xmldir}/#{File.basename(ref_hpxml)}"
      ref_hpxml2, rated_hpxml2, results_csv2 = run_and_check(ref_hpxml, parent_dir)
      _check_e_ratio(results_csv2)
    end
  end
  
  def test_resnet_hers_method
  
  end
  
  def test_resnet_hers_method_proposed
    
  end
  
  def test_resnet_hvac
  
  end
  
  def test_resnet_dse
  
  end
  
  def test_resnet_hot_water
  
  end
  
  def test_resnet_verification_building_attributes
  
  end
  
  def test_resnet_verification_mechanical_ventilation
  
  end
  
  def test_resnet_verification_appliances
  
  end

  private
  
  def run_and_check(xml, parent_dir)
    os_clis = Dir["C:/openstudio-*/bin/openstudio.exe"] + Dir["/usr/bin/openstudio"] + Dir["/usr/local/bin/openstudio"]
    os_cli = os_clis[-1]
    
    # Check input HPXML is valid
    xml = File.absolute_path(xml)
    _test_schema_validation(parent_dir, xml)
  
    # Run energy_rating_index workflow
    command = "cd #{parent_dir} && \"#{os_cli}\" energy_rating_index.rb -x #{xml} --debug"
    system(command)
  
    # Check all output files exist
    ref_hpxml = File.join(parent_dir, "results", "HERSReferenceHome.xml")
    ref_osm = File.join(parent_dir, "results", "HERSReferenceHome.osm")
    rated_hpxml = File.join(parent_dir, "results", "HERSRatedHome.xml")
    rated_osm = File.join(parent_dir, "results", "HERSRatedHome.osm")
    results_csv = File.join(parent_dir, "results", "ERI_Results.csv")
    worksheet_csv = File.join(parent_dir, "results", "ERI_Worksheet.csv")
    assert(File.exists?(ref_hpxml))
    assert(File.exists?(ref_osm))
    assert(File.exists?(rated_hpxml))
    assert(File.exists?(rated_osm))
    assert(File.exists?(results_csv))
    assert(File.exists?(worksheet_csv))
  
    # Check Reference/Rated HPXMLs are valid
    _test_schema_validation(parent_dir, ref_hpxml)
    _test_schema_validation(parent_dir, rated_hpxml)
    
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
    assert_equal(errors.size, 0)
  end
  
  def _check_reference_home_components(ref_hpxml, test_num)
    hpxml_doc = REXML::Document.new(File.read(ref_hpxml))
    
    # Table 4.2.3.1(1): Acceptance Criteria for Test Cases 1 – 4
    
    epsilon = 0.0005 # 0.05%
    
    # Above-grade walls
    wall_u, wall_solar_abs, wall_emiss = _get_hpxml_above_grade_wall(hpxml_doc)
    if test_num <= 3
      assert_in_delta(0.082, wall_u, 0.001)
    else
      assert_in_delta(0.060, wall_u, 0.001)
    end
    assert_equal(0.75, wall_solar_abs)
    assert_equal(0.90, wall_emiss)
    
    # Basement walls
    bsmt_wall_u = _get_hpxml_basement_wall(hpxml_doc)
    if test_num == 4
      assert_in_delta(0.059, bsmt_wall_u, 0.001)
    else
      pass
    end
    
    # Above-grade floors
    floors_u = _get_hpxml_above_grade_floors(hpxml_doc)
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
    ceil_u = _get_hpxml_ceilings(hpxml_doc)
    if test_num == 1 or test_num == 4
      assert_in_delta(0.030, ceil_u, 0.001)
    else
      assert_in_delta(0.035, ceil_u, 0.001)
    end
    
    # Roofs
    roof_solar_abs, roof_emiss = _get_hpxml_roof(hpxml_doc)
    assert_equal(0.75, roof_solar_abs)
    assert_equal(0.90, roof_emiss)
    
    # Attic vent area
    attic_vent_area = _get_hpxml_attic_vent_area(hpxml_doc)
    assert_in_epsilon(5.13, attic_vent_area, epsilon)
    
    # Crawlspace vent area
    crawl_vent_area = _get_hpxml_crawl_vent_area(hpxml_doc)
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
    door_u, door_area = _get_hpxml_doors(hpxml_doc)
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
    win_areas, win_u, win_shgc_htg, win_shgc_clg = _get_hpxml_windows(hpxml_doc)
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
    sla = _get_hpxml_sla(hpxml_doc)
    assert_in_delta(0.00036, sla, 0.00001)
    
    # Internal gains
    it_sens, it_lat = _get_hpxml_internal_gains(hpxml_doc)
    if test_num == 1
      assert_in_epsilon(55470, it_sens, epsilon)
      assert_in_epsilon(13807, it_lat, epsilon)
    elsif test_num == 2
      assert_in_epsilon(52794, it_sens, epsilon)
      assert_in_epsilon(12698, it_lat, epsilon)
    elsif test_num == 3
      assert_in_epsilon(48111, it_sens, epsilon)
      assert_in_epsilon(9259, it_lat, epsilon)
    else
      assert_in_epsilon(83103, it_sens, epsilon)
      assert_in_epsilon(17934, it_lat, epsilon)
    end
    
    # HVAC
    afue, hspf, seer, dse = _get_hpxml_hvac(hpxml_doc)
    if test_num == 1 or test_num == 4
      assert_equal(0.78, afue)
    else
      assert_equal(7.7, hspf)
    end
    assert_equal(13.0, seer)
    assert_equal(0.80, dse)
    
    # Thermostat
    tstat, htg_sp, htg_setback, clg_sp, clg_setup = _get_hpxml_tstat(hpxml_doc)
    assert_equal("manual", tstat)
    assert_equal(68, htg_sp)
    assert_equal(0, htg_setback)
    assert_equal(78, clg_sp)
    assert_equal(0, clg_setup)
    
    # Mechanical ventilation
    mv_kwh = _get_hpxml_mech_vent(hpxml_doc)
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
    ref_pipe_l, ref_loop_l = _get_hpxml_dhw(hpxml_doc)
    dhw_epsilon = 0.1 # 0.1 ft
    if test_num <= 3
      assert_in_delta(88.5, ref_pipe_l, dhw_epsilon)
      assert_in_delta(156.9, ref_loop_l, dhw_epsilon)
    else
      assert_in_delta(98.5, ref_pipe_l, dhw_epsilon)
      assert_in_delta(176.9, ref_loop_l, dhw_epsilon)
    end
           
  end
  
  def _get_hpxml_above_grade_wall(hpxml_doc)
    u_factor = 0.0
    solar_abs = 0.0
    emittance = 0.0
    num = 0
    hpxml_doc.elements.each("//Enclosure/Walls/Wall") do |wall|
      u_factor += 1.0/Float(XMLHelper.get_value(wall, "Insulation/AssemblyEffectiveRValue"))
      solar_abs += Float(XMLHelper.get_value(wall, "SolarAbsorptance"))
      emittance += Float(XMLHelper.get_value(wall, "Emittance"))
      num += 1
    end
    return u_factor/num, solar_abs/num, emittance/num
  end
  
  def _get_hpxml_basement_wall(hpxml_doc)
    u_factor = 0.0
    num = 0
    hpxml_doc.elements.each("//Foundation[FoundationType/Basement]/FoundationWall") do |fnd_wall|
      u_factor += 1.0/Float(XMLHelper.get_value(fnd_wall, "Insulation/AssemblyEffectiveRValue"))
      num += 1
    end
    return u_factor/num
  end

  def _get_hpxml_above_grade_floors(hpxml_doc)
    u_factor = 0.0
    num = 0
    hpxml_doc.elements.each("//Foundation[FoundationType/Ambient|FoundationType/Crawlspace]/FrameFloor") do |amb_ceil|
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
    hpxml_doc.elements.each("//Slab") do |fnd_slab|
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
  
  def _get_hpxml_ceilings(hpxml_doc)
    u_factor = 0.0
    num = 0
    hpxml_doc.elements.each("//Attics/Attic/Floors/Floor") do |attc_floor|
      u_factor += 1.0/Float(XMLHelper.get_value(attc_floor, "Insulation/AssemblyEffectiveRValue"))
      num += 1
    end
    return u_factor/num
  end
  
  def _get_hpxml_roof(hpxml_doc)
    solar_abs = 0.0
    emittance = 0.0
    num = 0
    hpxml_doc.elements.each("//Attic/Roofs/Roof") do |roof|
      solar_abs += Float(XMLHelper.get_value(roof, "SolarAbsorptance"))
      emittance += Float(XMLHelper.get_value(roof, "Emittance"))
      num += 1
    end
    return solar_abs/num, emittance/num
  end
  
  def _get_hpxml_attic_vent_area(hpxml_doc)
    area = 0.0
    hpxml_doc.elements.each("//Attic/Floors/Floor") do |attc_floor|
      area += Float(XMLHelper.get_value(attc_floor, "Area"))
    end
    if area > 0
      sla = Float(XMLHelper.get_value(hpxml_doc, "//BuildingDetails/Enclosure/AirInfiltration/extension/AtticSpecificLeakageArea"))
    else
      sla = 0.0
    end
    return sla*area
  end
  
  def _get_hpxml_crawl_vent_area(hpxml_doc)
    area = 0.0
    hpxml_doc.elements.each("//Foundation[FoundationType/Crawlspace]/FrameFloor") do |crawl_ceil|
      area += Float(XMLHelper.get_value(crawl_ceil, "Area"))
    end
    if area > 0
      sla = Float(XMLHelper.get_value(hpxml_doc, "//BuildingDetails/Enclosure/AirInfiltration/extension/CrawlspaceSpecificLeakageArea"))
    else
      sla = 0.0
    end
    return sla*area
  end
  
  def _get_hpxml_doors(hpxml_doc)
    area = 0.0
    u_factor = 0.0
    num = 0
    hpxml_doc.elements.each("//Door") do |door|
      area += Float(XMLHelper.get_value(door, "Area"))
      u_factor += 1.0/Float(XMLHelper.get_value(door, "RValue"))
      num += 1
    end
    return u_factor/num, area
  end
  
  def _get_hpxml_windows(hpxml_doc)
    areas = {0=>0.0, 90=>0.0, 180=>0.0, 270=>0.0}
    u_factor = 0.0
    shgc_htg = 0.0
    shgc_clg = 0.0
    num = 0
    hpxml_doc.elements.each("//Window") do |win|
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
  
  def _get_hpxml_sla(hpxml_doc)
    ela = Float(XMLHelper.get_value(hpxml_doc, "//BuildingDetails/Enclosure/AirInfiltration/AirInfiltrationMeasurement/EffectiveLeakageArea"))
    area = Float(XMLHelper.get_value(hpxml_doc, "//BuildingDetails/BuildingSummary/BuildingConstruction/ConditionedFloorArea"))
    return ela / area
  end
  
  def _get_hpxml_internal_gains(hpxml_doc)
  
    # Plug loads
    pl_sens = 0.0
    pl_lat = 0.0
    hpxml_doc.elements.each("//PlugLoad") do |pl|
      frac_sens = Float(XMLHelper.get_value(pl, "extension/FracSensible"))
      frac_lat = Float(XMLHelper.get_value(pl, "extension/FracLatent"))
      btu = OpenStudio::convert(Float(XMLHelper.get_value(pl, "Load[Units='kWh/year']/Value")), "kWh", "Btu").get
      pl_sens += (frac_sens * btu)
      pl_lat += (frac_lat * btu)
    end
    
    # Range, ClothesWasher, ClothesDryer, Dishwasher, Refrigerator
    appl_sens = 0.0
    appl_lat = 0.0
    hpxml_doc.elements.each("//CookingRange | //ClothesWasher | //ClothesDryer | //Dishwasher | //Refrigerator") do |appl|
      frac_sens = Float(XMLHelper.get_value(appl, "extension/FracSensible"))
      frac_lat = Float(XMLHelper.get_value(appl, "extension/FracLatent"))
      if appl.elements["RatedAnnualkWh"]
        btu = OpenStudio::convert(Float(XMLHelper.get_value(appl, "RatedAnnualkWh")), "kWh", "Btu").get
      else
        btu = OpenStudio::convert(Float(XMLHelper.get_value(appl, "extension/AnnualkWh")), "kWh", "Btu").get
        if appl.elements["extension/AnnualTherm"]
          btu += OpenStudio::convert(Float(XMLHelper.get_value(appl, "extension/AnnualTherm")), "therm", "Btu").get
        end
      end
      appl_sens += (frac_sens * btu)
      appl_lat += (frac_lat * btu)
    end
    
    # FIXME: Water Use
    nbr = Integer(XMLHelper.get_value(hpxml_doc, "//NumberofBedrooms"))
    water_sens = ((-1227.0-409.0*nbr)*365.0)
    water_lat = ((1245.0+415.0*nbr)*365.0)
    
    # Occupants
    occ_sens = 0.0
    occ_lat = 0.0
    hpxml_doc.elements.each("//BuildingOccupancy") do |occ|
      frac_sens = Float(XMLHelper.get_value(occ, "extension/FracSensible"))
      frac_lat = Float(XMLHelper.get_value(occ, "extension/FracLatent"))
      btu = Float(XMLHelper.get_value(occ, "NumberofResidents")) * Float(XMLHelper.get_value(occ, "extension/HeatGainPerPerson"))
      btu = btu * 8760.0 * 16.5/24.0 # FIXME
      occ_sens += (frac_sens * btu)
      occ_lat += (frac_lat * btu)
    end
    
    # Lighting
    ltg_sens = 0.0
    hpxml_doc.elements.each("//Lighting") do |ltg|
      ltg_kwh = Float(XMLHelper.get_value(ltg, "extension/AnnualInteriorkWh")) + Float(XMLHelper.get_value(ltg, "extension/AnnualGaragekWh"))
      ltg_sens += OpenStudio::convert(ltg_kwh, "kWh", "Btu").get
    end
    
    btu_sens = pl_sens + appl_sens + water_sens + occ_sens + ltg_sens
    btu_lat = pl_lat + appl_lat + water_lat + occ_lat
    
    return btu_sens/365.0, btu_lat/365.0
  end
  
  def _get_hpxml_hvac(hpxml_doc)
    afue = 0.0
    hspf = 0.0
    seer = 0.0
    dse = 0.0
    num_afue = 0
    num_hspf = 0
    num_seer = 0
    num_dse = 0
    hpxml_doc.elements.each("//HeatingSystem") do |htg|
      afue += Float(XMLHelper.get_value(htg, "AnnualHeatingEfficiency[Units='AFUE']/Value"))
      num_afue += 1
    end
    hpxml_doc.elements.each("//CoolingSystem") do |clg|
      seer += Float(XMLHelper.get_value(clg, "AnnualCoolingEfficiency[Units='SEER']/Value"))
      num_seer += 1
    end
    hpxml_doc.elements.each("//HeatPump") do |hp|
      if hp.elements["AnnualHeatEfficiency[Units='HSPF']"]
        hspf += Float(XMLHelper.get_value(hp, "AnnualHeatEfficiency[Units='HSPF']/Value"))
        num_hspf += 1
      end
      if hp.elements["AnnualCoolEfficiency[Units='SEER']"]
        seer += Float(XMLHelper.get_value(hp, "AnnualCoolEfficiency[Units='SEER']/Value"))
        num_seer += 1
      end
    end
    hpxml_doc.elements.each("//HVACDistribution") do |dist|
      dse += Float(XMLHelper.get_value(dist, "AnnualHeatingDistributionSystemEfficiency"))
      num_dse += 1
      dse += Float(XMLHelper.get_value(dist, "AnnualCoolingDistributionSystemEfficiency"))
      num_dse += 1
    end
    return afue/num_afue, hspf/num_hspf, seer/num_seer, dse/num_dse
  end
  
  def _get_hpxml_tstat(hpxml_doc)
    tstat = ""
    htg_sp = 0.0
    htg_setback = 0.0
    clg_sp = 0.0
    clg_setup = 0.0
    num = 0
    hpxml_doc.elements.each("//HVACControl") do |ctrl|
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
  
  def _get_hpxml_mech_vent(hpxml_doc)
    mv_kwh = 0.0
    hpxml_doc.elements.each("//VentilationFan[UsedForWholeBuildingVentilation='true']") do |mv|
      hours = Float(XMLHelper.get_value(mv, "HoursInOperation"))
      fan_w = Float(XMLHelper.get_value(mv, "FanPower"))
      mv_kwh += fan_w * 8.76 * hours/24.0
    end
    return mv_kwh
  end
  
  def _get_hpxml_dhw(hpxml_doc)
    ref_pipe_l = 0.0
    ref_loop_l = 0.0
    hpxml_doc.elements.each("//HotWaterDistribution") do |hwdist|
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
    #FIXME: assert_in_epsilon(100, hers_index, 0.005) # 0.5%
  end
  
end
