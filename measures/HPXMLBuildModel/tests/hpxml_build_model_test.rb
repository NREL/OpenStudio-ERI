require_relative '../../../test/minitest_helper'
require 'openstudio'
require 'openstudio/ruleset/ShowRunnerOutput'
require 'minitest/autorun'
require_relative '../measure.rb'
require 'fileutils'

class HPXMLBuildModelTest < MiniTest::Test

  def test_invalid_hpxml_file_path
    args_hash = {}
    args_hash["hpxml_file_path"] = "./resources/audit.txt"
    args_hash["measures_dir"] = ".."
    result = _test_error_or_NA(nil, args_hash)
    assert(result.errors.size == 1)
    assert_equal("Fail", result.value.valueName)
    assert_includes(result.errors.map{ |x| x.logMessage }, "'#{File.expand_path(File.join(File.dirname(__FILE__), '..', args_hash["hpxml_file_path"]))}' does not exist or is not an .xml file.")
  end

  def test_invalid_weather_file_path
    args_hash = {}
    args_hash["hpxml_file_path"] = "./tests/CasaElena.xml"
    args_hash["weather_file_path"] = "./resources/USA_CO_Denver_Intl_AP_725650_TMY3.txt"
    args_hash["measures_dir"] = ".."
    result = _test_error_or_NA(nil, args_hash)
    assert(result.errors.size == 1)
    assert_equal("Fail", result.value.valueName)
    assert_includes(result.errors.map{ |x| x.logMessage }, "'#{File.expand_path(File.join(File.dirname(__FILE__), '..', args_hash["weather_file_path"]))}' does not exist or is not an .epw file.")
  end  
  
  def test_invalid_measures_path
    args_hash = {}
    args_hash["hpxml_file_path"] = "./tests/CasaElena.xml"
    args_hash["measures_dir"] = "../../mesaures"
    result = _test_error_or_NA(nil, args_hash)
    assert(result.errors.size == 1)
    assert_equal("Fail", result.value.valueName)
    assert_includes(result.errors.map{ |x| x.logMessage }, "'#{File.expand_path(File.join(File.dirname(__FILE__), '..', args_hash["measures_dir"]))}' does not exist.")      
  end
  
  def test_rem_based_hpxml_no_weather
    args_hash = {}
    args_hash["hpxml_file_path"] = "./tests/CasaElena.xml"
    args_hash["measures_dir"] = ".."
    doc = REXML::Document.new(File.read(File.expand_path(File.join("./measures/HPXMLBuildModel", args_hash["hpxml_file_path"]))))
    num_roofs = REXML::XPath.first(doc, "count(//Roofs/Roof)")
    num_attics = (REXML::XPath.first(doc, "count(//Attics/Attic[AtticType='venting unknown attic'])") + REXML::XPath.first(doc, "count(//Attics/Attic[AtticType='vented attic'])") + REXML::XPath.first(doc, "count(//Attics/Attic[AtticType='unvented attic'])")) * 2
    num_framefloors = REXML::XPath.first(doc, "count(//Foundation/FrameFloor)") * 2
    num_foundationwalls = REXML::XPath.first(doc, "count(//Foundation/FoundationWall)")
    num_slabs = REXML::XPath.first(doc, "count(//Foundation/Slab)")
    num_walls = (REXML::XPath.first(doc, "count(//Walls/Wall)") - 2) * 4 + REXML::XPath.first(doc, "count(//Walls/Wall)") - 1
    num_atticwalls = (REXML::XPath.first(doc, "count(//Attics/Attic[AtticType='cathedral ceiling'])") + REXML::XPath.first(doc, "count(//Attics/Attic[AtticType='cape cod'])")) * 2    
    num_surfaces = num_roofs + num_attics + num_framefloors + num_foundationwalls + num_slabs + num_walls + num_atticwalls
    expected_num_del_objects = {}
    expected_num_new_objects = {"SiteGroundTemperatureDeep"=>1, "RunPeriodControlDaylightSavingTime"=>1, "SiteGroundTemperatureBuildingSurface"=>1, "SiteWaterMainsTemperature"=>1, "WeatherFile"=>1, "Construction"=>10, "Material"=>13, "Surface"=>num_surfaces, "SubSurface"=>50, "ThermalZone"=>3, "Space"=>3, "BuildingUnit"=>1, "People"=>2, "PeopleDefinition"=>2, "SimpleGlazing"=>1, "ShadingControl"=>1}
    expected_values = {}
    result = _test_measure(nil, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)
    assert_includes(result.info.map{ |x| x.logMessage }, "Found #{File.expand_path(File.join(".", "measures", "ResidentialLocation", "resources", "USA_CO_Denver_Intl_AP_725650_TMY3.epw"))} based on lat, lng.")
  end

  def test_rem_based_hpxml_1
    args_hash = {}
    args_hash["hpxml_file_path"] = "./tests/CasaElena.xml"
    args_hash["weather_file_path"] = "../ResidentialLocation/resources/USA_CO_Denver_Intl_AP_725650_TMY3.epw"
    args_hash["measures_dir"] = ".."
    doc = REXML::Document.new(File.read(File.expand_path(File.join("./measures/HPXMLBuildModel", args_hash["hpxml_file_path"]))))
    num_roofs = REXML::XPath.first(doc, "count(//Roofs/Roof)")
    num_attics = (REXML::XPath.first(doc, "count(//Attics/Attic[AtticType='venting unknown attic'])") + REXML::XPath.first(doc, "count(//Attics/Attic[AtticType='vented attic'])") + REXML::XPath.first(doc, "count(//Attics/Attic[AtticType='unvented attic'])")) * 2
    num_framefloors = REXML::XPath.first(doc, "count(//Foundation/FrameFloor)") * 2
    num_foundationwalls = REXML::XPath.first(doc, "count(//Foundation/FoundationWall)")
    num_slabs = REXML::XPath.first(doc, "count(//Foundation/Slab)")
    num_walls = (REXML::XPath.first(doc, "count(//Walls/Wall)") - 2) * 4 + REXML::XPath.first(doc, "count(//Walls/Wall)") - 1
    num_atticwalls = (REXML::XPath.first(doc, "count(//Attics/Attic[AtticType='cathedral ceiling'])") + REXML::XPath.first(doc, "count(//Attics/Attic[AtticType='cape cod'])")) * 2
    num_surfaces = num_roofs + num_attics + num_framefloors + num_foundationwalls + num_slabs + num_walls + num_atticwalls
    expected_num_del_objects = {}
    expected_num_new_objects = {"SiteGroundTemperatureDeep"=>1, "RunPeriodControlDaylightSavingTime"=>1, "SiteGroundTemperatureBuildingSurface"=>1, "SiteWaterMainsTemperature"=>1, "WeatherFile"=>1, "Construction"=>10, "Material"=>13, "Surface"=>num_surfaces, "SubSurface"=>50, "ThermalZone"=>3, "Space"=>3, "BuildingUnit"=>1, "People"=>2, "PeopleDefinition"=>2, "SimpleGlazing"=>1, "ShadingControl"=>1}
    expected_values = {}
    result = _test_measure(nil, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)
    assert_includes(result.info.map{ |x| x.logMessage }, "Found user-specified #{File.expand_path(File.join("./measures/ResidentialLocation/resources", File.basename(args_hash["weather_file_path"])))}.")
  end
  
  def test_rem_based_hpxml_2
    args_hash = {}
    args_hash["hpxml_file_path"] = "./tests/CedarUtopian4.xml"
    args_hash["weather_file_path"] = "../ResidentialLocation/resources/USA_CO_Denver_Intl_AP_725650_TMY3.epw"
    args_hash["measures_dir"] = ".."
    doc = REXML::Document.new(File.read(File.expand_path(File.join("./measures/HPXMLBuildModel", args_hash["hpxml_file_path"]))))
    num_roofs = REXML::XPath.first(doc, "count(//Roofs/Roof)")
    num_attics = (REXML::XPath.first(doc, "count(//Attics/Attic[AtticType='venting unknown attic'])") + REXML::XPath.first(doc, "count(//Attics/Attic[AtticType='vented attic'])") + REXML::XPath.first(doc, "count(//Attics/Attic[AtticType='unvented attic'])")) * 2
    num_framefloors = REXML::XPath.first(doc, "count(//Foundation/FrameFloor)") * 2
    num_foundationwalls = REXML::XPath.first(doc, "count(//Foundation/FoundationWall)")
    num_slabs = REXML::XPath.first(doc, "count(//Foundation/Slab)")
    num_walls = REXML::XPath.first(doc, "count(//Walls/Wall)") * 4
    num_atticwalls = (REXML::XPath.first(doc, "count(//Attics/Attic[AtticType='cathedral ceiling'])") + REXML::XPath.first(doc, "count(//Attics/Attic[AtticType='cape cod'])")) * 2    
    num_surfaces = num_roofs + num_attics + num_framefloors + num_foundationwalls + num_slabs + num_walls + num_atticwalls
    expected_num_del_objects = {}
    expected_num_new_objects = {"SiteGroundTemperatureDeep"=>1, "RunPeriodControlDaylightSavingTime"=>1, "SiteGroundTemperatureBuildingSurface"=>1, "SiteWaterMainsTemperature"=>1, "WeatherFile"=>1, "Construction"=>8, "Material"=>11, "Surface"=>num_surfaces, "SubSurface"=>193, "ThermalZone"=>3, "Space"=>3, "BuildingUnit"=>1, "People"=>2, "PeopleDefinition"=>2, "SimpleGlazing"=>1, "ShadingControl"=>1}
    expected_values = {}
    result = _test_measure(nil, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)
    assert_includes(result.info.map{ |x| x.logMessage }, "Found user-specified #{File.expand_path(File.join(".", "measures", "ResidentialLocation", "resources", "USA_CO_Denver_Intl_AP_725650_TMY3.epw"))}.")
  end

  def test_rem_based_hpxml_3
    args_hash = {}
    args_hash["hpxml_file_path"] = "./tests/Crawlspace.xml"
    args_hash["weather_file_path"] = "../ResidentialLocation/resources/USA_CO_Denver_Intl_AP_725650_TMY3.epw"
    args_hash["measures_dir"] = ".."
    doc = REXML::Document.new(File.read(File.expand_path(File.join("./measures/HPXMLBuildModel", args_hash["hpxml_file_path"]))))
    num_roofs = REXML::XPath.first(doc, "count(//Roofs/Roof)")
    num_attics = (REXML::XPath.first(doc, "count(//Attics/Attic[AtticType='venting unknown attic'])") + REXML::XPath.first(doc, "count(//Attics/Attic[AtticType='vented attic'])") + REXML::XPath.first(doc, "count(//Attics/Attic[AtticType='unvented attic'])")) * 2
    num_framefloors = REXML::XPath.first(doc, "count(//Foundation/FrameFloor)") * 2
    num_foundationwalls = REXML::XPath.first(doc, "count(//Foundation/FoundationWall)")
    num_slabs = REXML::XPath.first(doc, "count(//Foundation/Slab)")
    num_walls = REXML::XPath.first(doc, "count(//Walls/Wall)") * 4
    num_atticwalls = (REXML::XPath.first(doc, "count(//Attics/Attic[AtticType='cathedral ceiling'])") + REXML::XPath.first(doc, "count(//Attics/Attic[AtticType='cape cod'])")) * 2    
    num_surfaces = num_roofs + num_attics + num_framefloors + num_foundationwalls + num_slabs + num_walls + num_atticwalls
    expected_num_del_objects = {}
    expected_num_new_objects = {"SiteGroundTemperatureDeep"=>1, "RunPeriodControlDaylightSavingTime"=>1, "SiteGroundTemperatureBuildingSurface"=>1, "SiteWaterMainsTemperature"=>1, "WeatherFile"=>1, "Construction"=>7, "Material"=>10, "Surface"=>num_surfaces, "SubSurface"=>19, "ThermalZone"=>3, "Space"=>3, "BuildingUnit"=>1, "People"=>1, "PeopleDefinition"=>1, "SimpleGlazing"=>1, "ShadingControl"=>1}
    expected_values = {}
    result = _test_measure(nil, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)
    assert_includes(result.info.map{ |x| x.logMessage }, "Found user-specified #{File.expand_path(File.join(".", "measures", "ResidentialLocation", "resources", "USA_CO_Denver_Intl_AP_725650_TMY3.epw"))}.")
  end
  
  def test_rem_based_hpxml_4
    args_hash = {}
    args_hash["hpxml_file_path"] = "./tests/Estar3Tropics.xml"
    args_hash["weather_file_path"] = "../ResidentialLocation/resources/USA_CO_Denver_Intl_AP_725650_TMY3.epw"
    args_hash["measures_dir"] = ".."
    doc = REXML::Document.new(File.read(File.expand_path(File.join("./measures/HPXMLBuildModel", args_hash["hpxml_file_path"]))))
    num_roofs = REXML::XPath.first(doc, "count(//Roofs/Roof)")
    num_attics = (REXML::XPath.first(doc, "count(//Attics/Attic[AtticType='venting unknown attic'])") + REXML::XPath.first(doc, "count(//Attics/Attic[AtticType='vented attic'])") + REXML::XPath.first(doc, "count(//Attics/Attic[AtticType='unvented attic'])")) * 2
    num_framefloors = REXML::XPath.first(doc, "count(//Foundation/FrameFloor)") * 2
    num_foundationwalls = REXML::XPath.first(doc, "count(//Foundation/FoundationWall)")
    num_slabs = REXML::XPath.first(doc, "count(//Foundation/Slab)")
    num_walls = REXML::XPath.first(doc, "count(//Walls/Wall)") * 4
    num_atticwalls = (REXML::XPath.first(doc, "count(//Attics/Attic[AtticType='cathedral ceiling'])") + REXML::XPath.first(doc, "count(//Attics/Attic[AtticType='cape cod'])")) * 2    
    num_surfaces = num_roofs + num_attics + num_framefloors + num_foundationwalls + num_slabs + num_walls + num_atticwalls
    expected_num_del_objects = {}
    expected_num_new_objects = {"SiteGroundTemperatureDeep"=>1, "RunPeriodControlDaylightSavingTime"=>1, "SiteGroundTemperatureBuildingSurface"=>1, "SiteWaterMainsTemperature"=>1, "WeatherFile"=>1, "Construction"=>7, "Material"=>10, "Surface"=>num_surfaces, "SubSurface"=>19, "ThermalZone"=>3, "Space"=>3, "BuildingUnit"=>1, "People"=>1, "PeopleDefinition"=>1, "SimpleGlazing"=>1, "ShadingControl"=>1}
    expected_values = {}
    result = _test_measure(nil, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)
    assert_includes(result.info.map{ |x| x.logMessage }, "Found user-specified #{File.expand_path(File.join(".", "measures", "ResidentialLocation", "resources", "USA_CO_Denver_Intl_AP_725650_TMY3.epw"))}.")
  end
  
  def test_rem_based_hpxml_5
    args_hash = {}
    args_hash["hpxml_file_path"] = "./tests/Estar3TropicsWoNat.xml"
    args_hash["weather_file_path"] = "../ResidentialLocation/resources/USA_CO_Denver_Intl_AP_725650_TMY3.epw"
    args_hash["measures_dir"] = ".."
    doc = REXML::Document.new(File.read(File.expand_path(File.join("./measures/HPXMLBuildModel", args_hash["hpxml_file_path"]))))
    num_roofs = REXML::XPath.first(doc, "count(//Roofs/Roof)")
    num_attics = (REXML::XPath.first(doc, "count(//Attics/Attic[AtticType='venting unknown attic'])") + REXML::XPath.first(doc, "count(//Attics/Attic[AtticType='vented attic'])") + REXML::XPath.first(doc, "count(//Attics/Attic[AtticType='unvented attic'])")) * 2
    num_framefloors = REXML::XPath.first(doc, "count(//Foundation/FrameFloor)") * 2
    num_foundationwalls = REXML::XPath.first(doc, "count(//Foundation/FoundationWall)")
    num_slabs = REXML::XPath.first(doc, "count(//Foundation/Slab)")
    num_walls = REXML::XPath.first(doc, "count(//Walls/Wall)") * 4
    num_atticwalls = (REXML::XPath.first(doc, "count(//Attics/Attic[AtticType='cathedral ceiling'])") + REXML::XPath.first(doc, "count(//Attics/Attic[AtticType='cape cod'])")) * 2    
    num_surfaces = num_roofs + num_attics + num_framefloors + num_foundationwalls + num_slabs + num_walls + num_atticwalls
    expected_num_del_objects = {}
    expected_num_new_objects = {"SiteGroundTemperatureDeep"=>1, "RunPeriodControlDaylightSavingTime"=>1, "SiteGroundTemperatureBuildingSurface"=>1, "SiteWaterMainsTemperature"=>1, "WeatherFile"=>1, "Construction"=>7, "Material"=>10, "Surface"=>num_surfaces, "SubSurface"=>19, "ThermalZone"=>3, "Space"=>3, "BuildingUnit"=>1, "People"=>1, "PeopleDefinition"=>1, "SimpleGlazing"=>1, "ShadingControl"=>1}
    expected_values = {}
    result = _test_measure(nil, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)
    assert_includes(result.info.map{ |x| x.logMessage }, "Found user-specified #{File.expand_path(File.join(".", "measures", "ResidentialLocation", "resources", "USA_CO_Denver_Intl_AP_725650_TMY3.epw"))}.")
  end
  
  def test_rem_based_hpxml_6
    args_hash = {}
    args_hash["hpxml_file_path"] = "./tests/HE-GSHP.xml"
    args_hash["weather_file_path"] = "../ResidentialLocation/resources/USA_CO_Denver_Intl_AP_725650_TMY3.epw"
    args_hash["measures_dir"] = ".."
    doc = REXML::Document.new(File.read(File.expand_path(File.join("./measures/HPXMLBuildModel", args_hash["hpxml_file_path"]))))
    num_roofs = REXML::XPath.first(doc, "count(//Roofs/Roof)")
    num_attics = (REXML::XPath.first(doc, "count(//Attics/Attic[AtticType='venting unknown attic'])") + REXML::XPath.first(doc, "count(//Attics/Attic[AtticType='vented attic'])") + REXML::XPath.first(doc, "count(//Attics/Attic[AtticType='unvented attic'])")) * 2
    num_framefloors = REXML::XPath.first(doc, "count(//Foundation/FrameFloor)") * 2
    num_foundationwalls = REXML::XPath.first(doc, "count(//Foundation/FoundationWall)")
    num_slabs = REXML::XPath.first(doc, "count(//Foundation/Slab)")
    num_walls = REXML::XPath.first(doc, "count(//Walls/Wall)") * 4
    num_atticwalls = (REXML::XPath.first(doc, "count(//Attics/Attic[AtticType='cathedral ceiling'])") + REXML::XPath.first(doc, "count(//Attics/Attic[AtticType='cape cod'])")) * 2    
    num_surfaces = num_roofs + num_attics + num_framefloors + num_foundationwalls + num_slabs + num_walls + num_atticwalls
    expected_num_del_objects = {}
    expected_num_new_objects = {"SiteGroundTemperatureDeep"=>1, "RunPeriodControlDaylightSavingTime"=>1, "SiteGroundTemperatureBuildingSurface"=>1, "SiteWaterMainsTemperature"=>1, "WeatherFile"=>1, "Construction"=>7, "Material"=>10, "Surface"=>num_surfaces, "SubSurface"=>19, "ThermalZone"=>3, "Space"=>3, "BuildingUnit"=>1, "People"=>1, "PeopleDefinition"=>1, "SimpleGlazing"=>1, "ShadingControl"=>1}
    expected_values = {}
    result = _test_measure(nil, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)
    assert_includes(result.info.map{ |x| x.logMessage }, "Found user-specified #{File.expand_path(File.join("./measures/ResidentialLocation/resources", File.basename(args_hash["weather_file_path"])))}.")
  end
  
  def test_rem_based_hpxml_7
    args_hash = {}
    args_hash["hpxml_file_path"] = "./tests/HE-RESNET.xml"
    args_hash["weather_file_path"] = "../ResidentialLocation/resources/USA_CO_Denver_Intl_AP_725650_TMY3.epw"
    args_hash["measures_dir"] = ".."
    doc = REXML::Document.new(File.read(File.expand_path(File.join("./measures/HPXMLBuildModel", args_hash["hpxml_file_path"]))))
    num_roofs = REXML::XPath.first(doc, "count(//Roofs/Roof)")
    num_attics = (REXML::XPath.first(doc, "count(//Attics/Attic[AtticType='venting unknown attic'])") + REXML::XPath.first(doc, "count(//Attics/Attic[AtticType='vented attic'])") + REXML::XPath.first(doc, "count(//Attics/Attic[AtticType='unvented attic'])")) * 2
    num_framefloors = REXML::XPath.first(doc, "count(//Foundation/FrameFloor)") * 2
    num_foundationwalls = REXML::XPath.first(doc, "count(//Foundation/FoundationWall)")
    num_slabs = REXML::XPath.first(doc, "count(//Foundation/Slab)")
    num_walls = REXML::XPath.first(doc, "count(//Walls/Wall)") * 4
    num_atticwalls = (REXML::XPath.first(doc, "count(//Attics/Attic[AtticType='cathedral ceiling'])") + REXML::XPath.first(doc, "count(//Attics/Attic[AtticType='cape cod'])")) * 2    
    num_surfaces = num_roofs + num_attics + num_framefloors + num_foundationwalls + num_slabs + num_walls + num_atticwalls
    expected_num_del_objects = {}
    expected_num_new_objects = {"SiteGroundTemperatureDeep"=>1, "RunPeriodControlDaylightSavingTime"=>1, "SiteGroundTemperatureBuildingSurface"=>1, "SiteWaterMainsTemperature"=>1, "WeatherFile"=>1, "Construction"=>7, "Material"=>10, "Surface"=>num_surfaces, "SubSurface"=>19, "ThermalZone"=>3, "Space"=>3, "BuildingUnit"=>1, "People"=>1, "PeopleDefinition"=>1, "SimpleGlazing"=>1, "ShadingControl"=>1}
    expected_values = {}
    result = _test_measure(nil, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)
    assert_includes(result.info.map{ |x| x.logMessage }, "Found user-specified #{File.expand_path(File.join(".", "measures", "ResidentialLocation", "resources", "USA_CO_Denver_Intl_AP_725650_TMY3.epw"))}.")
  end

  def test_rem_based_hpxml_8
    args_hash = {}
    args_hash["hpxml_file_path"] = "./tests/MobileHome.xml"
    args_hash["weather_file_path"] = "../ResidentialLocation/resources/USA_CO_Denver_Intl_AP_725650_TMY3.epw"
    args_hash["measures_dir"] = ".."
    result = _test_error_or_NA(nil, args_hash)
    assert(result.errors.size == 1)
    assert_equal("Fail", result.value.valueName)
    assert_includes(result.errors.map{ |x| x.logMessage }, "Residential facility type not single-family detached.")
  end
  
  def test_rem_based_hpxml_9
    args_hash = {}
    args_hash["hpxml_file_path"] = "./tests/MultiFamily2.xml"
    args_hash["weather_file_path"] = "../ResidentialLocation/resources/USA_CO_Denver_Intl_AP_725650_TMY3.epw"
    args_hash["measures_dir"] = ".."
    result = _test_error_or_NA(nil, args_hash)
    assert(result.errors.size == 1)
    assert_equal("Fail", result.value.valueName)
    assert_includes(result.errors.map{ |x| x.logMessage }, "Residential facility type not single-family detached.")
  end
  
  def test_rem_based_hpxml_10
    args_hash = {}
    args_hash["hpxml_file_path"] = "./tests/RESNET QA Test - EGWA within limit.xml"
    args_hash["weather_file_path"] = "../ResidentialLocation/resources/USA_CO_Denver_Intl_AP_725650_TMY3.epw"
    args_hash["measures_dir"] = ".."
    doc = REXML::Document.new(File.read(File.expand_path(File.join("./measures/HPXMLBuildModel", args_hash["hpxml_file_path"]))))
    num_roofs = REXML::XPath.first(doc, "count(//Roofs/Roof)")
    num_attics = (REXML::XPath.first(doc, "count(//Attics/Attic[AtticType='venting unknown attic'])") + REXML::XPath.first(doc, "count(//Attics/Attic[AtticType='vented attic'])") + REXML::XPath.first(doc, "count(//Attics/Attic[AtticType='unvented attic'])")) * 2
    num_framefloors = REXML::XPath.first(doc, "count(//Foundation/FrameFloor)") * 2
    num_foundationwalls = REXML::XPath.first(doc, "count(//Foundation/FoundationWall)")
    num_slabs = REXML::XPath.first(doc, "count(//Foundation/Slab)")
    num_walls = REXML::XPath.first(doc, "count(//Walls/Wall)") * 4
    num_atticwalls = (REXML::XPath.first(doc, "count(//Attics/Attic[AtticType='cathedral ceiling'])") + REXML::XPath.first(doc, "count(//Attics/Attic[AtticType='cape cod'])")) * 2    
    num_surfaces = num_roofs + num_attics + num_framefloors + num_foundationwalls + num_slabs + num_walls + num_atticwalls
    expected_num_del_objects = {}
    expected_num_new_objects = {"SiteGroundTemperatureDeep"=>1, "RunPeriodControlDaylightSavingTime"=>1, "SiteGroundTemperatureBuildingSurface"=>1, "SiteWaterMainsTemperature"=>1, "WeatherFile"=>1, "Construction"=>7, "Material"=>10, "Surface"=>num_surfaces, "SubSurface"=>19, "ThermalZone"=>3, "Space"=>3, "BuildingUnit"=>1, "People"=>1, "PeopleDefinition"=>1, "SimpleGlazing"=>1, "ShadingControl"=>1}
    expected_values = {}
    result = _test_measure(nil, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)
    assert_includes(result.info.map{ |x| x.logMessage }, "Found user-specified #{File.expand_path(File.join(".", "measures", "ResidentialLocation", "resources", "USA_CO_Denver_Intl_AP_725650_TMY3.epw"))}.")
  end
  
  def test_rem_based_hpxml_11
    args_hash = {}
    args_hash["hpxml_file_path"] = "./tests/SimpInput.xml"
    args_hash["weather_file_path"] = "../ResidentialLocation/resources/USA_CO_Denver_Intl_AP_725650_TMY3.epw"
    args_hash["measures_dir"] = ".."
    doc = REXML::Document.new(File.read(File.expand_path(File.join("./measures/HPXMLBuildModel", args_hash["hpxml_file_path"]))))
    num_roofs = REXML::XPath.first(doc, "count(//Roofs/Roof)")
    num_attics = (REXML::XPath.first(doc, "count(//Attics/Attic[AtticType='venting unknown attic'])") + REXML::XPath.first(doc, "count(//Attics/Attic[AtticType='vented attic'])") + REXML::XPath.first(doc, "count(//Attics/Attic[AtticType='unvented attic'])")) * 2
    num_framefloors = REXML::XPath.first(doc, "count(//Foundation/FrameFloor)") * 2
    num_foundationwalls = REXML::XPath.first(doc, "count(//Foundation/FoundationWall)")
    num_slabs = REXML::XPath.first(doc, "count(//Foundation/Slab)")
    num_walls = REXML::XPath.first(doc, "count(//Walls/Wall)") * 4
    num_atticwalls = (REXML::XPath.first(doc, "count(//Attics/Attic[AtticType='cathedral ceiling'])") + REXML::XPath.first(doc, "count(//Attics/Attic[AtticType='cape cod'])")) * 2    
    num_surfaces = num_roofs + num_attics + num_framefloors + num_foundationwalls + num_slabs + num_walls + num_atticwalls
    expected_num_del_objects = {}
    expected_num_new_objects = {"SiteGroundTemperatureDeep"=>1, "RunPeriodControlDaylightSavingTime"=>1, "SiteGroundTemperatureBuildingSurface"=>1, "SiteWaterMainsTemperature"=>1, "WeatherFile"=>1, "Construction"=>6, "Material"=>8, "Surface"=>num_surfaces, "SubSurface"=>36, "ThermalZone"=>2, "Space"=>2, "BuildingUnit"=>1, "People"=>1, "PeopleDefinition"=>1, "SimpleGlazing"=>1, "ShadingControl"=>1}
    expected_values = {}
    result = _test_measure(nil, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)
    assert_includes(result.info.map{ |x| x.logMessage }, "Found user-specified #{File.expand_path(File.join(".", "measures", "ResidentialLocation", "resources", "USA_CO_Denver_Intl_AP_725650_TMY3.epw"))}.")
  end
  
  private
  
  def _test_error_or_NA(osm_file_or_model, args_hash)
    # create an instance of the measure
    measure = HPXMLBuildModel.new

    # create an instance of a runner
    runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)

    model = get_model(File.dirname(__FILE__), osm_file_or_model)

    # get arguments
    arguments = measure.arguments(model)
    argument_map = OpenStudio::Measure.convertOSArgumentVectorToMap(arguments)

    # populate argument with specified hash value if specified
    arguments.each do |arg|
      temp_arg_var = arg.clone
      if args_hash[arg.name]
        assert(temp_arg_var.setValue(args_hash[arg.name]))
      end
      argument_map[arg.name] = temp_arg_var
    end

    # run the measure
    measure.run(model, runner, argument_map)
    result = runner.result
      
    return result
    
  end
  
  def _test_measure(osm_file_or_model, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, num_infos=0, num_warnings=0, debug=false)
    # create an instance of the measure
    measure = HPXMLBuildModel.new

    # check for standard methods
    assert(!measure.name.empty?)
    assert(!measure.description.empty?)
    assert(!measure.modeler_description.empty?)

    # create an instance of a runner
    runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)
    
    model = get_model(File.dirname(__FILE__), osm_file_or_model)

    # get the initial objects in the model
    initial_objects = get_objects(model)
    
    # get arguments
    arguments = measure.arguments(model)
    argument_map = OpenStudio::Measure.convertOSArgumentVectorToMap(arguments)

    # populate argument with specified hash value if specified
    arguments.each do |arg|
      temp_arg_var = arg.clone
      if args_hash[arg.name]
        assert(temp_arg_var.setValue(args_hash[arg.name]))
      end
      argument_map[arg.name] = temp_arg_var
    end

    # run the measure
    measure.run(model, runner, argument_map)
    result = runner.result
    
    #show_output(result)

    # assert that it ran correctly
    assert_equal("Success", result.value.valueName)
    #assert(result.info.size == num_infos)
    assert(result.info.size > 0)
    assert(result.warnings.size == num_warnings)
    
    # get the final objects in the model
    final_objects = get_objects(model)
    
    # get new and deleted objects
    obj_type_exclusions = ["ClimateZones", "Site", "YearDescription", "ScheduleDay", "ScheduleRuleset", "ScheduleRule", "ScheduleTypeLimits", "ScheduleConstant", "ZoneHVACEquipmentList", "SizingSystem", "SizingZone", "Node", "Building", "PortList", "CurveExponent", "CurveCubic"]
    all_new_objects = get_object_additions(initial_objects, final_objects, obj_type_exclusions)
    all_del_objects = get_object_additions(final_objects, initial_objects, obj_type_exclusions)
    
    # check we have the expected number of new/deleted objects
    check_num_objects(all_new_objects, expected_num_new_objects, "added")
    check_num_objects(all_del_objects, expected_num_del_objects, "deleted")

    all_new_objects.each do |obj_type, new_objects|
        new_objects.each do |new_object|
            next if not new_object.respond_to?("to_#{obj_type}")
            new_object = new_object.public_send("to_#{obj_type}").get

        end
    end
    
    return result
  end

end
