require_relative '../../../test/minitest_helper'
require 'openstudio'
require 'openstudio/ruleset/ShowRunnerOutput'
require 'minitest/autorun'
require_relative '../measure.rb'
require 'fileutils'

class ResidentialAirflowTest < MiniTest::Test

  def test_no_hvac_equip
    args_hash = {}
    expected_num_del_objects = {}
    expected_num_new_objects = {"ScheduleRuleset"=>7, "ScheduleRule"=>84, "EnergyManagementSystemProgramCallingManager"=>2, "EnergyManagementSystemProgram"=>3, "EnergyManagementSystemSensor"=>12, "EnergyManagementSystemActuator"=>5, "EnergyManagementSystemGlobalVariable"=>2, "OutputVariable"=>14, "SpaceInfiltrationDesignFlowRate"=>2, "SpaceInfiltrationEffectiveLeakageArea"=>1, "ElectricEquipmentDefinition"=>3, "ElectricEquipment"=>3, "Material"=>1, "Surface"=>6, "Space"=>1, "Construction"=>1, "ThermalZone"=>1, "SurfacePropertyConvectionCoefficients"=>6, "EnergyManagementSystemOutputVariable"=>1}
    expected_values = {"erv_priority"=>nil, "terrain_type"=>"Suburbs", "duct_location"=>nil, "infiltration_c"=>0.0696580370384, "infiltration_cs"=>0.0748809783509, "infiltration_cw"=>0.140569087655, "natvent_cs"=>0.000179260407789, "natvent_cw"=>0.000282172823794, "duct_leak_supply"=>0, "duct_leak_return"=>0, "f_oa"=>0.0368634868631, "faneff_wh"=>0.47194744, "fan_frac_to_space"=>0, "ra_duct_volume"=>0}
    _test_measure("SFD_2000sqft_2story_SL_UA_3Beds_2Baths_Denver.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 0, 4)       
  end
  
  def test_non_ducted_hvac_equipment
    args_hash = {} 
    expected_num_del_objects = {}
    expected_num_new_objects = {"ScheduleRuleset"=>7, "ScheduleRule"=>84, "EnergyManagementSystemProgramCallingManager"=>2, "EnergyManagementSystemProgram"=>3, "EnergyManagementSystemSensor"=>12, "EnergyManagementSystemActuator"=>5, "EnergyManagementSystemGlobalVariable"=>2, "OutputVariable"=>14, "SpaceInfiltrationDesignFlowRate"=>2, "SpaceInfiltrationEffectiveLeakageArea"=>1, "ElectricEquipmentDefinition"=>3, "ElectricEquipment"=>3, "Material"=>1, "Surface"=>6, "Construction"=>1, "ThermalZone"=>1, "Space"=>1, "SurfacePropertyConvectionCoefficients"=>6, "EnergyManagementSystemOutputVariable"=>1}
    expected_values = {"erv_priority"=>nil, "terrain_type"=>"Suburbs", "duct_location"=>nil, "infiltration_c"=>0.0696580370384, "infiltration_cs"=>0.0748809783509, "infiltration_cw"=>0.140569087655, "natvent_cs"=>0.000179260407789, "natvent_cw"=>0.000282172823794, "duct_leak_supply"=>0, "duct_leak_return"=>0, "f_oa"=>0.0368634868631, "faneff_wh"=>0.47194744, "fan_frac_to_space"=>0, "ra_duct_volume"=>0}
    _test_measure("SFD_2000sqft_2story_SL_UA_3Beds_2Baths_Denver_ElectricBaseboard.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 0, 3) 
  end

  def test_has_clothes_dryer
    args_hash = {}
    args_hash["has_hvac_flue"] = "true"  
    expected_num_del_objects = {}
    expected_num_new_objects = {"ScheduleRuleset"=>7, "ScheduleRule"=>84, "Surface"=>6, "EnergyManagementSystemSubroutine"=>1, "EnergyManagementSystemProgramCallingManager"=>2, "EnergyManagementSystemProgram"=>3, "EnergyManagementSystemSensor"=>21, "EnergyManagementSystemActuator"=>17, "EnergyManagementSystemGlobalVariable"=>23, "AirLoopHVACReturnPlenum"=>1, "OtherEquipmentDefinition"=>10, "OtherEquipment"=>10, "ThermalZone"=>1, "ZoneMixing"=>2, "OutputVariable"=>14, "SpaceInfiltrationDesignFlowRate"=>2, "SpaceInfiltrationEffectiveLeakageArea"=>1, "Construction"=>1, "Space"=>1, "Material"=>1, "ElectricEquipmentDefinition"=>3, "ElectricEquipment"=>3, "SurfacePropertyConvectionCoefficients"=>6, "EnergyManagementSystemOutputVariable"=>1}
    expected_values = {"erv_priority"=>nil, "terrain_type"=>"Suburbs", "duct_location"=>"unfinished attic zone", "infiltration_c"=>0.0696580370384, "infiltration_cs"=>0.0862380821416, "infiltration_cw"=>0.128435824905, "natvent_cs"=>0.000179260407789, "natvent_cw"=>0.000282172823794, "duct_leak_supply"=>0.136963386963, "duct_leak_return"=>0.1000999001, "f_oa"=>0.0368634868631, "faneff_wh"=>0.47194744, "fan_frac_to_space"=>0, "ra_duct_volume"=>90}
    _test_measure("SFD_2000sqft_2story_SL_UA_3Beds_2Baths_Denver_Furnace_CentralAC_ElecWHTank_ClothesWasher_ClothesDryer.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)
  end
    
  def test_neighbors
    args_hash = {}
    args_hash["has_hvac_flue"] = "true"     
    expected_num_del_objects = {}
    expected_num_new_objects = {"ScheduleRuleset"=>7, "ScheduleRule"=>84, "Surface"=>6, "EnergyManagementSystemSubroutine"=>1, "EnergyManagementSystemProgramCallingManager"=>2, "EnergyManagementSystemProgram"=>3, "EnergyManagementSystemSensor"=>21, "EnergyManagementSystemActuator"=>17, "EnergyManagementSystemGlobalVariable"=>23, "AirLoopHVACReturnPlenum"=>1, "OtherEquipmentDefinition"=>10, "OtherEquipment"=>10, "ThermalZone"=>1, "ZoneMixing"=>2, "OutputVariable"=>14, "SpaceInfiltrationDesignFlowRate"=>2, "SpaceInfiltrationEffectiveLeakageArea"=>1, "Construction"=>1, "Space"=>1, "Material"=>1, "ElectricEquipmentDefinition"=>3, "ElectricEquipment"=>3, "SurfacePropertyConvectionCoefficients"=>6, "EnergyManagementSystemOutputVariable"=>1}
    expected_values = {"erv_priority"=>nil, "terrain_type"=>"Suburbs", "duct_location"=>"unfinished attic zone", "infiltration_c"=>0.0696580370384, "infiltration_cs"=>0.0862380821416, "infiltration_cw"=>0.128435824905, "natvent_cs"=>0.000179260407789, "natvent_cw"=>0.0000870903777142, "duct_leak_supply"=>0.136963386963, "duct_leak_return"=>0.1000999001, "f_oa"=>0.0368634868631, "faneff_wh"=>0.47194744, "fan_frac_to_space"=>0, "ra_duct_volume"=>90}
    _test_measure("SFD_2000sqft_2story_SL_UA_3Beds_2Baths_Denver_Furnace_CentralAC_Neighbors.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 0, 1)
  end
  
  def test_mech_vent_none
    args_hash = {}
    args_hash["has_hvac_flue"] = "true"    
    args_hash["mech_vent_type"] = "none"
    expected_num_del_objects = {}
    expected_num_new_objects = {"ScheduleRuleset"=>7, "ScheduleRule"=>84, "Surface"=>6, "EnergyManagementSystemSubroutine"=>1, "EnergyManagementSystemProgramCallingManager"=>2, "EnergyManagementSystemProgram"=>3, "EnergyManagementSystemSensor"=>21, "EnergyManagementSystemActuator"=>17, "EnergyManagementSystemGlobalVariable"=>23, "AirLoopHVACReturnPlenum"=>1, "OtherEquipmentDefinition"=>10, "OtherEquipment"=>10, "ThermalZone"=>1, "ZoneMixing"=>2, "OutputVariable"=>14, "SpaceInfiltrationDesignFlowRate"=>2, "SpaceInfiltrationEffectiveLeakageArea"=>1, "Construction"=>1, "Space"=>1, "Material"=>1, "ElectricEquipmentDefinition"=>3, "ElectricEquipment"=>3, "SurfacePropertyConvectionCoefficients"=>6, "EnergyManagementSystemOutputVariable"=>1}
    expected_values = {"erv_priority"=>nil, "terrain_type"=>"Suburbs", "duct_location"=>"unfinished attic zone", "infiltration_c"=>0.0696580370384, "infiltration_cs"=>0.0862380821416, "infiltration_cw"=>0.128435824905, "natvent_cs"=>0.000179260407789, "natvent_cw"=>0.000282172823794, "duct_leak_supply"=>0.136963386963, "duct_leak_return"=>0.1000999001, "f_oa"=>0.0368634868631, "faneff_wh"=>1, "fan_frac_to_space"=>0, "ra_duct_volume"=>90}
    _test_measure("SFD_2000sqft_2story_SL_UA_3Beds_2Baths_Denver_Furnace_CentralAC.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 0, 1)   
  end  
  
  def test_mech_vent_supply
    args_hash = {}
    args_hash["has_hvac_flue"] = "true"  
    args_hash["mech_vent_type"] = Constants.VentTypeSupply
    expected_num_del_objects = {}
    expected_num_new_objects = {"ScheduleRuleset"=>7, "ScheduleRule"=>84, "Surface"=>6, "EnergyManagementSystemSubroutine"=>1, "EnergyManagementSystemProgramCallingManager"=>2, "EnergyManagementSystemProgram"=>3, "EnergyManagementSystemSensor"=>21, "EnergyManagementSystemActuator"=>17, "EnergyManagementSystemGlobalVariable"=>23, "AirLoopHVACReturnPlenum"=>1, "OtherEquipmentDefinition"=>10, "OtherEquipment"=>10, "ThermalZone"=>1, "ZoneMixing"=>2, "OutputVariable"=>14, "SpaceInfiltrationDesignFlowRate"=>2, "SpaceInfiltrationEffectiveLeakageArea"=>1, "Construction"=>1, "Space"=>1, "Material"=>1, "ElectricEquipmentDefinition"=>3, "ElectricEquipment"=>3, "SurfacePropertyConvectionCoefficients"=>6, "EnergyManagementSystemOutputVariable"=>1}
    expected_values = {"erv_priority"=>nil, "terrain_type"=>"Suburbs", "duct_location"=>"unfinished attic zone", "infiltration_c"=>0.0696580370384, "infiltration_cs"=>0.0862380821416, "infiltration_cw"=>0.128435824905, "natvent_cs"=>0.000179260407789, "natvent_cw"=>0.000282172823794, "duct_leak_supply"=>0.136963386963, "duct_leak_return"=>0.1000999001, "f_oa"=>0.0368634868631, "faneff_wh"=>0.47194744, "fan_frac_to_space"=>1, "ra_duct_volume"=>90}
    _test_measure("SFD_2000sqft_2story_SL_UA_3Beds_2Baths_Denver_Furnace_CentralAC.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 0, 1)       
  end
  
  def test_mech_vent_exhaust_ashrae_622_2013
    args_hash = {}
    args_hash["has_hvac_flue"] = "true"   
    args_hash["mech_vent_ashrae_std"] = "2013"
    expected_num_del_objects = {}
    expected_num_new_objects = {"ScheduleRuleset"=>7, "ScheduleRule"=>84, "Surface"=>6, "EnergyManagementSystemSubroutine"=>1, "EnergyManagementSystemProgramCallingManager"=>2, "EnergyManagementSystemProgram"=>3, "EnergyManagementSystemSensor"=>21, "EnergyManagementSystemActuator"=>17, "EnergyManagementSystemGlobalVariable"=>23, "AirLoopHVACReturnPlenum"=>1, "OtherEquipmentDefinition"=>10, "OtherEquipment"=>10, "ThermalZone"=>1, "ZoneMixing"=>2, "OutputVariable"=>14, "SpaceInfiltrationDesignFlowRate"=>2, "SpaceInfiltrationEffectiveLeakageArea"=>1, "Construction"=>1, "Space"=>1, "Material"=>1, "ElectricEquipmentDefinition"=>3, "ElectricEquipment"=>3, "SurfacePropertyConvectionCoefficients"=>6, "EnergyManagementSystemOutputVariable"=>1}
    expected_values = {"erv_priority"=>nil, "terrain_type"=>"Suburbs", "duct_location"=>"unfinished attic zone", "infiltration_c"=>0.0696580370384, "infiltration_cs"=>0.0862380821416, "infiltration_cw"=>0.128435824905, "natvent_cs"=>0.000179260407789, "natvent_cw"=>0.000282172823794, "duct_leak_supply"=>0.136963386963, "duct_leak_return"=>0.1000999001, "f_oa"=>0.0368634868631, "faneff_wh"=>0.47194744, "fan_frac_to_space"=>0, "ra_duct_volume"=>90}
    _test_measure("SFD_2000sqft_2story_SL_UA_3Beds_2Baths_Denver_Furnace_CentralAC.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 0, 1)    
  end
  
  def test_existing_building
    args_hash = {}
    args_hash["has_hvac_flue"] = "true"    
    args_hash["is_existing_home"] = true
    expected_num_del_objects = {}
    expected_num_new_objects = {"ScheduleRuleset"=>7, "ScheduleRule"=>84, "Surface"=>6, "EnergyManagementSystemSubroutine"=>1, "EnergyManagementSystemProgramCallingManager"=>2, "EnergyManagementSystemProgram"=>3, "EnergyManagementSystemSensor"=>21, "EnergyManagementSystemActuator"=>17, "EnergyManagementSystemGlobalVariable"=>23, "AirLoopHVACReturnPlenum"=>1, "OtherEquipmentDefinition"=>10, "OtherEquipment"=>10, "ThermalZone"=>1, "ZoneMixing"=>2, "OutputVariable"=>14, "SpaceInfiltrationDesignFlowRate"=>2, "SpaceInfiltrationEffectiveLeakageArea"=>1, "Construction"=>1, "Space"=>1, "Material"=>1, "ElectricEquipmentDefinition"=>3, "ElectricEquipment"=>3, "SurfacePropertyConvectionCoefficients"=>6, "EnergyManagementSystemOutputVariable"=>1}
    expected_values = {"erv_priority"=>nil, "terrain_type"=>"Suburbs", "duct_location"=>"unfinished attic zone", "infiltration_c"=>0.0696580370384, "infiltration_cs"=>0.0862380821416, "infiltration_cw"=>0.128435824905, "natvent_cs"=>0.000179260407789, "natvent_cw"=>0.000282172823794, "duct_leak_supply"=>0.136963386963, "duct_leak_return"=>0.1000999001, "f_oa"=>0.0368634868631, "faneff_wh"=>0.47194744, "fan_frac_to_space"=>0, "ra_duct_volume"=>90}
    _test_measure("SFD_2000sqft_2story_SL_UA_3Beds_2Baths_Denver_Furnace_CentralAC.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 0, 1)  
  end

  def test_crawl
    args_hash = {}
    args_hash["has_hvac_flue"] = "true"
    args_hash["crawl_ach"] = 0.1
    expected_num_del_objects = {}
    expected_num_new_objects = {"ScheduleRuleset"=>7, "ScheduleRule"=>84, "Surface"=>6, "EnergyManagementSystemSubroutine"=>1, "EnergyManagementSystemProgramCallingManager"=>2, "EnergyManagementSystemProgram"=>3, "EnergyManagementSystemSensor"=>21, "EnergyManagementSystemActuator"=>17, "EnergyManagementSystemGlobalVariable"=>23, "AirLoopHVACReturnPlenum"=>1, "OtherEquipmentDefinition"=>10, "OtherEquipment"=>10, "ThermalZone"=>1, "ZoneMixing"=>2, "OutputVariable"=>14, "SpaceInfiltrationDesignFlowRate"=>3, "SpaceInfiltrationEffectiveLeakageArea"=>1, "Construction"=>1, "Space"=>1, "Material"=>1, "ElectricEquipmentDefinition"=>3, "ElectricEquipment"=>3, "SurfacePropertyConvectionCoefficients"=>6, "EnergyManagementSystemOutputVariable"=>1}
    expected_values = {"erv_priority"=>nil, "terrain_type"=>"Suburbs", "duct_location"=>"crawl zone", "infiltration_c"=>0.0696580370384, "infiltration_cs"=>0.0934618423868, "infiltration_cw"=>0.108877688141, "natvent_cs"=>0.000179260407789, "natvent_cw"=>0.000282172823794, "duct_leak_supply"=>0.136963386963, "duct_leak_return"=>0.1000999001, "f_oa"=>0.0368634868631, "faneff_wh"=>0.47194744, "fan_frac_to_space"=>0, "ra_duct_volume"=>90}
    _test_measure("SFD_2000sqft_2story_CS_UA_3Beds_2Baths_Denver_Furnace_CentralAC.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 0, 1) 
  end
  
  def test_pier_beam
    args_hash = {}
    args_hash["has_hvac_flue"] = "true"
    expected_num_del_objects = {}
    expected_num_new_objects = {"ScheduleRuleset"=>7, "ScheduleRule"=>84, "Surface"=>6, "EnergyManagementSystemSubroutine"=>1, "EnergyManagementSystemProgramCallingManager"=>2, "EnergyManagementSystemProgram"=>3, "EnergyManagementSystemSensor"=>21, "EnergyManagementSystemActuator"=>17, "EnergyManagementSystemGlobalVariable"=>23, "AirLoopHVACReturnPlenum"=>1, "OtherEquipmentDefinition"=>10, "OtherEquipment"=>10, "ThermalZone"=>1, "ZoneMixing"=>2, "OutputVariable"=>14, "SpaceInfiltrationDesignFlowRate"=>3, "SpaceInfiltrationEffectiveLeakageArea"=>1, "Construction"=>1, "Space"=>1, "Material"=>1, "ElectricEquipmentDefinition"=>3, "ElectricEquipment"=>3, "SurfacePropertyConvectionCoefficients"=>6, "EnergyManagementSystemOutputVariable"=>1}
    expected_values = {"erv_priority"=>nil, "terrain_type"=>"Suburbs", "duct_location"=>"pier and beam zone", "infiltration_c"=>0.0696580370384, "infiltration_cs"=>0.0913022091975, "infiltration_cw"=>0.108877688141, "natvent_cs"=>0.000179260407789, "natvent_cw"=>0.000307490705883, "duct_leak_supply"=>0.136963386963, "duct_leak_return"=>0.1000999001, "f_oa"=>0.0368634868631, "faneff_wh"=>0.47194744, "fan_frac_to_space"=>0, "ra_duct_volume"=>90}
    _test_measure("SFD_2000sqft_2story_PB_UA_3Beds_2Baths_Denver_Furnace_CentralAC.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 0, 1) 
  end  
  
  def test_ufbasement
    args_hash = {}
    args_hash["has_hvac_flue"] = "true"
    expected_num_del_objects = {}
    expected_num_new_objects = {"ScheduleRuleset"=>7, "ScheduleRule"=>84, "Surface"=>6, "EnergyManagementSystemSubroutine"=>1, "EnergyManagementSystemProgramCallingManager"=>2, "EnergyManagementSystemProgram"=>3, "EnergyManagementSystemSensor"=>21, "EnergyManagementSystemActuator"=>17, "EnergyManagementSystemGlobalVariable"=>23, "AirLoopHVACReturnPlenum"=>1, "OtherEquipmentDefinition"=>10, "OtherEquipment"=>10, "ThermalZone"=>1, "ZoneMixing"=>2, "OutputVariable"=>14, "SpaceInfiltrationDesignFlowRate"=>3, "SpaceInfiltrationEffectiveLeakageArea"=>1, "Construction"=>1, "Space"=>1, "Material"=>1, "ElectricEquipmentDefinition"=>3, "ElectricEquipment"=>3, "SurfacePropertyConvectionCoefficients"=>6, "EnergyManagementSystemOutputVariable"=>1}
    expected_values = {"erv_priority"=>nil, "terrain_type"=>"Suburbs", "duct_location"=>"unfinished basement zone", "infiltration_c"=>0.0696580370384, "infiltration_cs"=>0.0862380821416, "infiltration_cw"=>0.128435824905, "natvent_cs"=>0.000179260407789, "natvent_cw"=>0.000282172823794, "duct_leak_supply"=>0.136963386963, "duct_leak_return"=>0.1000999001, "f_oa"=>0.000001, "faneff_wh"=>0.47194744, "fan_frac_to_space"=>0, "ra_duct_volume"=>90}
    _test_measure("SFD_2000sqft_2story_UB_UA_3Beds_2Baths_Denver_Furnace_CentralAC.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 0, 1)    
  end
  
  def test_duct_location_ufbasement
    args_hash = {}
    args_hash["has_hvac_flue"] = "true"
    args_hash["duct_location"] = Constants.BasementZone
    expected_num_del_objects = {}
    expected_num_new_objects = {"ScheduleRuleset"=>7, "ScheduleRule"=>84, "Surface"=>6, "EnergyManagementSystemSubroutine"=>1, "EnergyManagementSystemProgramCallingManager"=>2, "EnergyManagementSystemProgram"=>3, "EnergyManagementSystemSensor"=>21, "EnergyManagementSystemActuator"=>17, "EnergyManagementSystemGlobalVariable"=>23, "AirLoopHVACReturnPlenum"=>1, "OtherEquipmentDefinition"=>10, "OtherEquipment"=>10, "ThermalZone"=>1, "ZoneMixing"=>2, "OutputVariable"=>14, "SpaceInfiltrationDesignFlowRate"=>3, "SpaceInfiltrationEffectiveLeakageArea"=>1, "Construction"=>1, "Space"=>1, "Material"=>1, "ElectricEquipmentDefinition"=>3, "ElectricEquipment"=>3, "SurfacePropertyConvectionCoefficients"=>6, "EnergyManagementSystemOutputVariable"=>1}
    expected_values = {"erv_priority"=>nil, "terrain_type"=>"Suburbs", "duct_location"=>"unfinished basement zone", "infiltration_c"=>0.0696580370384, "infiltration_cs"=>0.0862380821416, "infiltration_cw"=>0.128435824905, "natvent_cs"=>0.000179260407789, "natvent_cw"=>0.000282172823794, "duct_leak_supply"=>0.136963386963, "duct_leak_return"=>0.1000999001, "f_oa"=>0.000001, "faneff_wh"=>0.47194744, "fan_frac_to_space"=>0, "ra_duct_volume"=>90}
    _test_measure("SFD_2000sqft_2story_UB_UA_3Beds_2Baths_Denver_Furnace_CentralAC.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 0, 1)    
  end
  
  def test_fbasement
    args_hash = {}
    args_hash["has_hvac_flue"] = "true"
    args_hash["finished_basement_ach"] = 0.1
    expected_num_del_objects = {}
    expected_num_new_objects = {"ScheduleRuleset"=>7, "ScheduleRule"=>84, "Surface"=>6, "EnergyManagementSystemSubroutine"=>1, "EnergyManagementSystemProgramCallingManager"=>2, "EnergyManagementSystemProgram"=>3, "EnergyManagementSystemSensor"=>21, "EnergyManagementSystemActuator"=>17, "EnergyManagementSystemGlobalVariable"=>23, "AirLoopHVACReturnPlenum"=>1, "OtherEquipmentDefinition"=>10, "OtherEquipment"=>10, "ThermalZone"=>1, "ZoneMixing"=>2, "OutputVariable"=>14, "SpaceInfiltrationDesignFlowRate"=>3, "SpaceInfiltrationEffectiveLeakageArea"=>1, "Construction"=>1, "Space"=>1, "Material"=>1, "ElectricEquipmentDefinition"=>3, "ElectricEquipment"=>3, "SurfacePropertyConvectionCoefficients"=>6, "EnergyManagementSystemOutputVariable"=>1}
    expected_values = {"erv_priority"=>nil, "terrain_type"=>"Suburbs", "duct_location"=>"finished basement zone", "infiltration_c"=>0.0463225946305, "infiltration_cs"=>0.0845493286618, "infiltration_cw"=>0.128435824905, "natvent_cs"=>0.000179260407789, "natvent_cw"=>0.000282172823794, "duct_leak_supply"=>0.136963386963, "duct_leak_return"=>0.1000999001, "f_oa"=>0.000001, "faneff_wh"=>0.47194744, "fan_frac_to_space"=>0, "ra_duct_volume"=>120}
    _test_measure("SFD_2000sqft_2story_FB_UA_3Beds_2Baths_Denver_Furnace_CentralAC.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 0, 1)    
  end  
  
  def test_duct_location_fbasement
    args_hash = {}
    args_hash["has_hvac_flue"] = "true"
    args_hash["duct_location"] = Constants.BasementZone
    expected_num_del_objects = {}
    expected_num_new_objects = {"ScheduleRuleset"=>7, "ScheduleRule"=>84, "Surface"=>6, "EnergyManagementSystemSubroutine"=>1, "EnergyManagementSystemProgramCallingManager"=>2, "EnergyManagementSystemProgram"=>3, "EnergyManagementSystemSensor"=>21, "EnergyManagementSystemActuator"=>17, "EnergyManagementSystemGlobalVariable"=>23, "AirLoopHVACReturnPlenum"=>1, "OtherEquipmentDefinition"=>10, "OtherEquipment"=>10, "ThermalZone"=>1, "ZoneMixing"=>2, "OutputVariable"=>14, "SpaceInfiltrationDesignFlowRate"=>2, "SpaceInfiltrationEffectiveLeakageArea"=>1, "Construction"=>1, "Space"=>1, "Material"=>1, "ElectricEquipmentDefinition"=>3, "ElectricEquipment"=>3, "SurfacePropertyConvectionCoefficients"=>6, "EnergyManagementSystemOutputVariable"=>1}
    expected_values = {"erv_priority"=>nil, "terrain_type"=>"Suburbs", "duct_location"=>"finished basement zone", "infiltration_c"=>0.0463225946305, "infiltration_cs"=>0.0845493286618, "infiltration_cw"=>0.128435824905, "natvent_cs"=>0.000179260407789, "natvent_cw"=>0.000282172823794, "duct_leak_supply"=>0.136963386963, "duct_leak_return"=>0.1000999001, "f_oa"=>0.000001, "faneff_wh"=>0.47194744, "fan_frac_to_space"=>0, "ra_duct_volume"=>120}
    _test_measure("SFD_2000sqft_2story_FB_UA_3Beds_2Baths_Denver_Furnace_CentralAC.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 0, 1)    
  end
  
  # def test_duct_system_eff
    # args_hash = {}
    # args_hash["dist_system_eff"] = "0.8"
    # expected_num_del_objects = {}
    # expected_num_new_objects = {"ScheduleRuleset"=>7, "ScheduleRule"=>84, "EnergyManagementSystemProgramCallingManager"=>2, "EnergyManagementSystemProgram"=>3, "EnergyManagementSystemSensor"=>12, "EnergyManagementSystemActuator"=>5, "EnergyManagementSystemGlobalVariable"=>2, "OutputVariable"=>14, "SpaceInfiltrationDesignFlowRate"=>2, "SpaceInfiltrationEffectiveLeakageArea"=>1, "ElectricEquipmentDefinition"=>3, "ElectricEquipment"=>3, "Space"=>2, "Surface"=>12, "Material"=>1, "ThermalZone"=>2, "Construction"=>1, "AirTerminalSingleDuctUncontrolled"=>1, "AirLoopHVACReturnPlenum"=>1, "SurfacePropertyConvectionCoefficients"=>6}
    # expected_values = {}
    # _test_measure("SFD_2000sqft_2story_SL_UA_3Beds_2Baths_Denver_Furnace_CentralAC.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 0, 1)
  # end

  def test_duct_location_ufattic
    args_hash = {}
    args_hash["has_hvac_flue"] = "true"
    args_hash["duct_location"] = Constants.AtticZone
    expected_num_del_objects = {}
    expected_num_new_objects = {"ScheduleRuleset"=>7, "ScheduleRule"=>84, "Surface"=>6, "EnergyManagementSystemSubroutine"=>1, "EnergyManagementSystemProgramCallingManager"=>2, "EnergyManagementSystemProgram"=>3, "EnergyManagementSystemSensor"=>21, "EnergyManagementSystemActuator"=>17, "EnergyManagementSystemGlobalVariable"=>23, "AirLoopHVACReturnPlenum"=>1, "OtherEquipmentDefinition"=>10, "OtherEquipment"=>10, "ThermalZone"=>1, "ZoneMixing"=>2, "OutputVariable"=>14, "SpaceInfiltrationDesignFlowRate"=>2, "SpaceInfiltrationEffectiveLeakageArea"=>1, "Construction"=>1, "Space"=>1, "Material"=>1, "ElectricEquipmentDefinition"=>3, "ElectricEquipment"=>3, "SurfacePropertyConvectionCoefficients"=>6, "EnergyManagementSystemOutputVariable"=>1}
    expected_values = {"erv_priority"=>nil, "terrain_type"=>"Suburbs", "duct_location"=>"unfinished attic zone", "infiltration_c"=>0.0696580370384, "infiltration_cs"=>0.0862380821416, "infiltration_cw"=>0.128435824905, "natvent_cs"=>0.000179260407789, "natvent_cw"=>0.000282172823794, "duct_leak_supply"=>0.136963386963, "duct_leak_return"=>0.1000999001, "f_oa"=>0.0368634868631, "faneff_wh"=>0.47194744, "fan_frac_to_space"=>0, "ra_duct_volume"=>90}
    _test_measure("SFD_2000sqft_2story_SL_UA_3Beds_2Baths_Denver_Furnace_CentralAC.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 0, 1)     
  end  
  
  def test_duct_location_in_living
    args_hash = {}
    args_hash["has_hvac_flue"] = "true"
    args_hash["duct_location"] = Constants.LivingZone
    expected_num_del_objects = {}
    expected_num_new_objects = {"ScheduleRuleset"=>7, "ScheduleRule"=>84, "EnergyManagementSystemProgramCallingManager"=>2, "EnergyManagementSystemProgram"=>3, "EnergyManagementSystemSensor"=>12, "EnergyManagementSystemActuator"=>5, "EnergyManagementSystemGlobalVariable"=>2, "OutputVariable"=>14, "SpaceInfiltrationDesignFlowRate"=>2, "SpaceInfiltrationEffectiveLeakageArea"=>1, "ElectricEquipmentDefinition"=>3, "ElectricEquipment"=>3, "Material"=>1, "Surface"=>6, "ThermalZone"=>1, "Construction"=>1, "AirLoopHVACReturnPlenum"=>1, "Space"=>1, "SurfacePropertyConvectionCoefficients"=>6, "EnergyManagementSystemOutputVariable"=>1}
    expected_values = {"erv_priority"=>nil, "terrain_type"=>"Suburbs", "duct_location"=>"living zone", "infiltration_c"=>0.0696580370384, "infiltration_cs"=>0.0862380821416, "infiltration_cw"=>0.128435824905, "natvent_cs"=>0.000179260407789, "natvent_cw"=>0.000282172823794, "duct_leak_supply"=>0, "duct_leak_return"=>0, "f_oa"=>0, "faneff_wh"=>0.47194744, "fan_frac_to_space"=>0, "ra_duct_volume"=>0}
    _test_measure("SFD_2000sqft_2story_SL_UA_3Beds_2Baths_Denver_Furnace_CentralAC.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 0, 1) 
  end

  # def test_duct_norm_leak_to_outside
    # args_hash = {}
    # args_hash["duct_norm_leakage_25pa"] = "8.0"
    # expected_num_del_objects = {}
    # expected_num_new_objects = {"ScheduleRuleset"=>7, "ScheduleRule"=>84, "EnergyManagementSystemProgramCallingManager"=>2, "EnergyManagementSystemProgram"=>3, "EnergyManagementSystemSensor"=>21, "EnergyManagementSystemActuator"=>17, "EnergyManagementSystemGlobalVariable"=>23, "OutputVariable"=>14, "SpaceInfiltrationDesignFlowRate"=>2, "SpaceInfiltrationEffectiveLeakageArea"=>1, "ElectricEquipmentDefinition"=>3, "ElectricEquipment"=>3, "Space"=>1, "Surface"=>6, "OtherEquipment"=>10, "OtherEquipmentDefinition"=>10, "Material"=>1, "AirLoopHVACReturnPlenum"=>1, "ThermalZone"=>1, "ZoneMixing"=>2, "Construction"=>1, "EnergyManagementSystemSubroutine"=>1, "SurfacePropertyConvectionCoefficients"=>6}
    # expected_values = {}
    # _test_measure("SFD_2000sqft_2story_SL_UA_3Beds_2Baths_Denver_Furnace_CentralAC.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 0, 1) 
  # end
  
  def test_terrain_ocean
    args_hash = {}
    args_hash["has_hvac_flue"] = "true"
    args_hash["terrain"] = Constants.TerrainOcean
    expected_num_del_objects = {}
    expected_num_new_objects = {"ScheduleRuleset"=>7, "ScheduleRule"=>84, "Surface"=>6, "EnergyManagementSystemSubroutine"=>1, "EnergyManagementSystemProgramCallingManager"=>2, "EnergyManagementSystemProgram"=>3, "EnergyManagementSystemSensor"=>21, "EnergyManagementSystemActuator"=>17, "EnergyManagementSystemGlobalVariable"=>23, "AirLoopHVACReturnPlenum"=>1, "OtherEquipmentDefinition"=>10, "OtherEquipment"=>10, "ThermalZone"=>1, "ZoneMixing"=>2, "OutputVariable"=>14, "SpaceInfiltrationDesignFlowRate"=>2, "SpaceInfiltrationEffectiveLeakageArea"=>1, "Construction"=>1, "Space"=>1, "Material"=>1, "ElectricEquipmentDefinition"=>3, "ElectricEquipment"=>3, "SurfacePropertyConvectionCoefficients"=>6, "EnergyManagementSystemOutputVariable"=>1}
    expected_values = {"erv_priority"=>nil, "terrain_type"=>"Ocean", "duct_location"=>"unfinished attic zone", "infiltration_c"=>0.0696580370384, "infiltration_cs"=>0.0862380821416, "infiltration_cw"=>0.128435824905, "natvent_cs"=>0.000179260407789, "natvent_cw"=>0.00131758439281, "duct_leak_supply"=>0.136963386963, "duct_leak_return"=>0.1000999001, "f_oa"=>0.0368634868631, "faneff_wh"=>0.47194744, "fan_frac_to_space"=>0, "ra_duct_volume"=>90}
    _test_measure("SFD_2000sqft_2story_SL_UA_3Beds_2Baths_Denver_Furnace_CentralAC.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 0, 1)      
  end

  def test_terrain_plains
    args_hash = {}
    args_hash["has_hvac_flue"] = "true"
    args_hash["terrain"] = Constants.TerrainPlains
    expected_num_del_objects = {}
    expected_num_new_objects = {"ScheduleRuleset"=>7, "ScheduleRule"=>84, "Surface"=>6, "EnergyManagementSystemSubroutine"=>1, "EnergyManagementSystemProgramCallingManager"=>2, "EnergyManagementSystemProgram"=>3, "EnergyManagementSystemSensor"=>21, "EnergyManagementSystemActuator"=>17, "EnergyManagementSystemGlobalVariable"=>23, "AirLoopHVACReturnPlenum"=>1, "OtherEquipmentDefinition"=>10, "OtherEquipment"=>10, "ThermalZone"=>1, "ZoneMixing"=>2, "OutputVariable"=>14, "SpaceInfiltrationDesignFlowRate"=>2, "SpaceInfiltrationEffectiveLeakageArea"=>1, "Construction"=>1, "Space"=>1, "Material"=>1, "ElectricEquipmentDefinition"=>3, "ElectricEquipment"=>3, "SurfacePropertyConvectionCoefficients"=>6, "EnergyManagementSystemOutputVariable"=>1}
    expected_values = {"erv_priority"=>nil, "terrain_type"=>"Country", "duct_location"=>"unfinished attic zone", "infiltration_c"=>0.0696580370384, "infiltration_cs"=>0.0862380821416, "infiltration_cw"=>0.128435824905, "natvent_cs"=>0.000179260407789, "natvent_cw"=>0.000725631873825, "duct_leak_supply"=>0.136963386963, "duct_leak_return"=>0.1000999001, "f_oa"=>0.0368634868631, "faneff_wh"=>0.47194744, "fan_frac_to_space"=>0, "ra_duct_volume"=>90}
    _test_measure("SFD_2000sqft_2story_SL_UA_3Beds_2Baths_Denver_Furnace_CentralAC.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 0, 1)  
  end
  
  def test_terrain_rural
    args_hash = {}
    args_hash["has_hvac_flue"] = "true"
    args_hash["terrain"] = Constants.TerrainRural
    expected_num_del_objects = {}
    expected_num_new_objects = {"ScheduleRuleset"=>7, "ScheduleRule"=>84, "Surface"=>6, "EnergyManagementSystemSubroutine"=>1, "EnergyManagementSystemProgramCallingManager"=>2, "EnergyManagementSystemProgram"=>3, "EnergyManagementSystemSensor"=>21, "EnergyManagementSystemActuator"=>17, "EnergyManagementSystemGlobalVariable"=>23, "AirLoopHVACReturnPlenum"=>1, "OtherEquipmentDefinition"=>10, "OtherEquipment"=>10, "ThermalZone"=>1, "ZoneMixing"=>2, "OutputVariable"=>14, "SpaceInfiltrationDesignFlowRate"=>2, "SpaceInfiltrationEffectiveLeakageArea"=>1, "Construction"=>1, "Space"=>1, "Material"=>1, "ElectricEquipmentDefinition"=>3, "ElectricEquipment"=>3, "SurfacePropertyConvectionCoefficients"=>6, "EnergyManagementSystemOutputVariable"=>1}
    expected_values = {"erv_priority"=>nil, "terrain_type"=>"Country", "duct_location"=>"unfinished attic zone", "infiltration_c"=>0.0696580370384, "infiltration_cs"=>0.0862380821416, "infiltration_cw"=>0.128435824905, "natvent_cs"=>0.000179260407789, "natvent_cw"=>0.000487953925808, "duct_leak_supply"=>0.136963386963, "duct_leak_return"=>0.1000999001, "f_oa"=>0.0368634868631, "faneff_wh"=>0.47194744, "fan_frac_to_space"=>0, "ra_duct_volume"=>90}
    _test_measure("SFD_2000sqft_2story_SL_UA_3Beds_2Baths_Denver_Furnace_CentralAC.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 0, 1)  
  end
  
  def test_terrain_city
    args_hash = {}
    args_hash["has_hvac_flue"] = "true"
    args_hash["terrain"] = Constants.TerrainCity
    expected_num_del_objects = {}
    expected_num_new_objects = {"ScheduleRuleset"=>7, "ScheduleRule"=>84, "Surface"=>6, "EnergyManagementSystemSubroutine"=>1, "EnergyManagementSystemProgramCallingManager"=>2, "EnergyManagementSystemProgram"=>3, "EnergyManagementSystemSensor"=>21, "EnergyManagementSystemActuator"=>17, "EnergyManagementSystemGlobalVariable"=>23, "AirLoopHVACReturnPlenum"=>1, "OtherEquipmentDefinition"=>10, "OtherEquipment"=>10, "ThermalZone"=>1, "ZoneMixing"=>2, "OutputVariable"=>14, "SpaceInfiltrationDesignFlowRate"=>2, "SpaceInfiltrationEffectiveLeakageArea"=>1, "Construction"=>1, "Space"=>1, "Material"=>1, "ElectricEquipmentDefinition"=>3, "ElectricEquipment"=>3, "SurfacePropertyConvectionCoefficients"=>6, "EnergyManagementSystemOutputVariable"=>1}
    expected_values = {"erv_priority"=>nil, "terrain_type"=>"City", "duct_location"=>"unfinished attic zone", "infiltration_c"=>0.0696580370384, "infiltration_cs"=>0.0862380821416, "infiltration_cw"=>0.128435824905, "natvent_cs"=>0.000179260407789, "natvent_cw"=>0.000120284736893, "duct_leak_supply"=>0.136963386963, "duct_leak_return"=>0.1000999001, "f_oa"=>0.0368634868631, "faneff_wh"=>0.47194744, "fan_frac_to_space"=>0, "ra_duct_volume"=>90}
    _test_measure("SFD_2000sqft_2story_SL_UA_3Beds_2Baths_Denver_Furnace_CentralAC.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 0, 1)  
  end

  def test_mech_vent_hrv
    args_hash = {}
    args_hash["has_hvac_flue"] = "true"
    args_hash["mech_vent_type"] = Constants.VentTypeBalanced
    args_hash["mech_vent_sensible_efficiency"] = 0.6
    expected_num_del_objects = {}
    expected_num_new_objects = {"ScheduleRuleset"=>7, "ScheduleRule"=>84, "Surface"=>6, "EnergyManagementSystemSubroutine"=>1, "EnergyManagementSystemProgramCallingManager"=>2, "EnergyManagementSystemProgram"=>3, "EnergyManagementSystemSensor"=>21, "EnergyManagementSystemActuator"=>17, "EnergyManagementSystemGlobalVariable"=>23, "AirLoopHVACReturnPlenum"=>1, "OtherEquipmentDefinition"=>10, "OtherEquipment"=>10, "ThermalZone"=>1, "ZoneMixing"=>2, "OutputVariable"=>14, "SpaceInfiltrationDesignFlowRate"=>2, "SpaceInfiltrationEffectiveLeakageArea"=>1, "Construction"=>1, "Space"=>1, "FanOnOff"=>2, "HeatExchangerAirToAirSensibleAndLatent"=>1, "ZoneHVACEnergyRecoveryVentilatorController"=>1, "ZoneHVACEnergyRecoveryVentilator"=>1, "Material"=>1, "ElectricEquipmentDefinition"=>3, "ElectricEquipment"=>3, "SurfacePropertyConvectionCoefficients"=>6, "EnergyManagementSystemOutputVariable"=>1}
    expected_values = {"erv_priority"=>1, "terrain_type"=>"Suburbs", "duct_location"=>"unfinished attic zone", "infiltration_c"=>0.0696580370384, "infiltration_cs"=>0.0862380821416, "infiltration_cw"=>0.128435824905, "natvent_cs"=>0.000179260407789, "natvent_cw"=>0.000282172823794, "duct_leak_supply"=>0.136963386963, "duct_leak_return"=>0.1000999001, "f_oa"=>0.0368634868631, "faneff_wh"=>0.47194744, "fan_frac_to_space"=>0.5, "ra_duct_volume"=>90, "hvac_priority"=>1}
    _test_measure("SFD_2000sqft_2story_SL_UA_3Beds_2Baths_Denver_Furnace_CentralAC.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 0, 1)  
  end

  def test_mech_vent_erv
    args_hash = {}
    args_hash["has_hvac_flue"] = "true"
    args_hash["mech_vent_type"] = Constants.VentTypeBalanced
    args_hash["mech_vent_total_efficiency"] = 0.48
    args_hash["mech_vent_sensible_efficiency"] = 0.72
    expected_num_del_objects = {}
    expected_num_new_objects = {"ScheduleRuleset"=>7, "ScheduleRule"=>84, "Surface"=>6, "EnergyManagementSystemSubroutine"=>1, "EnergyManagementSystemProgramCallingManager"=>2, "EnergyManagementSystemProgram"=>3, "EnergyManagementSystemSensor"=>21, "EnergyManagementSystemActuator"=>17, "EnergyManagementSystemGlobalVariable"=>23, "AirLoopHVACReturnPlenum"=>1, "OtherEquipmentDefinition"=>10, "OtherEquipment"=>10, "ThermalZone"=>1, "ZoneMixing"=>2, "OutputVariable"=>14, "SpaceInfiltrationDesignFlowRate"=>2, "SpaceInfiltrationEffectiveLeakageArea"=>1, "Construction"=>1, "Space"=>1, "FanOnOff"=>2, "HeatExchangerAirToAirSensibleAndLatent"=>1, "ZoneHVACEnergyRecoveryVentilatorController"=>1, "ZoneHVACEnergyRecoveryVentilator"=>1, "Material"=>1, "ElectricEquipmentDefinition"=>3, "ElectricEquipment"=>3, "SurfacePropertyConvectionCoefficients"=>6, "EnergyManagementSystemOutputVariable"=>1}
    expected_values = {"erv_priority"=>1, "terrain_type"=>"Suburbs", "duct_location"=>"unfinished attic zone", "infiltration_c"=>0.0696580370384, "infiltration_cs"=>0.0862380821416, "infiltration_cw"=>0.128435824905, "natvent_cs"=>0.000179260407789, "natvent_cw"=>0.000282172823794, "duct_leak_supply"=>0.136963386963, "duct_leak_return"=>0.1000999001, "f_oa"=>0.0368634868631, "faneff_wh"=>0.47194744, "fan_frac_to_space"=>0.5, "ra_duct_volume"=>90, "hvac_priority"=>1}
    _test_measure("SFD_2000sqft_2story_SL_UA_3Beds_2Baths_Denver_Furnace_CentralAC.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 0, 1)
  end

  def test_nat_vent_0_wkdy_0_wked
    args_hash = {}
    args_hash["has_hvac_flue"] = "true" 
    args_hash["nat_vent_num_weekdays"] = 0
    args_hash["nat_vent_num_weekends"] = 0
    expected_num_del_objects = {}
    expected_num_new_objects = {"ScheduleRuleset"=>7, "ScheduleRule"=>84, "Surface"=>6, "EnergyManagementSystemSubroutine"=>1, "EnergyManagementSystemProgramCallingManager"=>2, "EnergyManagementSystemProgram"=>3, "EnergyManagementSystemSensor"=>21, "EnergyManagementSystemActuator"=>17, "EnergyManagementSystemGlobalVariable"=>23, "AirLoopHVACReturnPlenum"=>1, "OtherEquipmentDefinition"=>10, "OtherEquipment"=>10, "ThermalZone"=>1, "ZoneMixing"=>2, "OutputVariable"=>14, "SpaceInfiltrationDesignFlowRate"=>2, "SpaceInfiltrationEffectiveLeakageArea"=>1, "Construction"=>1, "Space"=>1, "Material"=>1, "ElectricEquipmentDefinition"=>3, "ElectricEquipment"=>3, "SurfacePropertyConvectionCoefficients"=>6, "EnergyManagementSystemOutputVariable"=>1}
    expected_values = {"erv_priority"=>nil, "terrain_type"=>"Suburbs", "duct_location"=>"unfinished attic zone", "infiltration_c"=>0.0696580370384, "infiltration_cs"=>0.0862380821416, "infiltration_cw"=>0.128435824905, "natvent_cs"=>0.000179260407789, "natvent_cw"=>0.000282172823794, "duct_leak_supply"=>0.136963386963, "duct_leak_return"=>0.1000999001, "f_oa"=>0.0368634868631, "faneff_wh"=>0.47194744, "fan_frac_to_space"=>0, "ra_duct_volume"=>90}
    _test_measure("SFD_2000sqft_2story_SL_UA_3Beds_2Baths_Denver_Furnace_CentralAC.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 0, 1)       
  end
  
  def test_nat_vent_1_wkdy_1_wked
    args_hash = {}
    args_hash["has_hvac_flue"] = "true" 
    args_hash["nat_vent_num_weekdays"] = 1
    args_hash["nat_vent_num_weekends"] = 1
    expected_num_del_objects = {}
    expected_num_new_objects = {"ScheduleRuleset"=>7, "ScheduleRule"=>84, "Surface"=>6, "EnergyManagementSystemSubroutine"=>1, "EnergyManagementSystemProgramCallingManager"=>2, "EnergyManagementSystemProgram"=>3, "EnergyManagementSystemSensor"=>21, "EnergyManagementSystemActuator"=>17, "EnergyManagementSystemGlobalVariable"=>23, "AirLoopHVACReturnPlenum"=>1, "OtherEquipmentDefinition"=>10, "OtherEquipment"=>10, "ThermalZone"=>1, "ZoneMixing"=>2, "OutputVariable"=>14, "SpaceInfiltrationDesignFlowRate"=>2, "SpaceInfiltrationEffectiveLeakageArea"=>1, "Construction"=>1, "Space"=>1, "Material"=>1, "ElectricEquipmentDefinition"=>3, "ElectricEquipment"=>3, "SurfacePropertyConvectionCoefficients"=>6, "EnergyManagementSystemOutputVariable"=>1}
    expected_values = {"erv_priority"=>nil, "terrain_type"=>"Suburbs", "duct_location"=>"unfinished attic zone", "infiltration_c"=>0.0696580370384, "infiltration_cs"=>0.0862380821416, "infiltration_cw"=>0.128435824905, "natvent_cs"=>0.000179260407789, "natvent_cw"=>0.000282172823794, "duct_leak_supply"=>0.136963386963, "duct_leak_return"=>0.1000999001, "f_oa"=>0.0368634868631, "faneff_wh"=>0.47194744, "fan_frac_to_space"=>0, "ra_duct_volume"=>90}
    _test_measure("SFD_2000sqft_2story_SL_UA_3Beds_2Baths_Denver_Furnace_CentralAC.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 0, 1)       
  end  
  
  def test_nat_vent_2_wkdy_2_wked
    args_hash = {}
    args_hash["has_hvac_flue"] = "true" 
    args_hash["nat_vent_num_weekdays"] = 2
    args_hash["nat_vent_num_weekends"] = 2
    expected_num_del_objects = {}
    expected_num_new_objects = {"ScheduleRuleset"=>7, "ScheduleRule"=>84, "Surface"=>6, "EnergyManagementSystemSubroutine"=>1, "EnergyManagementSystemProgramCallingManager"=>2, "EnergyManagementSystemProgram"=>3, "EnergyManagementSystemSensor"=>21, "EnergyManagementSystemActuator"=>17, "EnergyManagementSystemGlobalVariable"=>23, "AirLoopHVACReturnPlenum"=>1, "OtherEquipmentDefinition"=>10, "OtherEquipment"=>10, "ThermalZone"=>1, "ZoneMixing"=>2, "OutputVariable"=>14, "SpaceInfiltrationDesignFlowRate"=>2, "SpaceInfiltrationEffectiveLeakageArea"=>1, "Construction"=>1, "Space"=>1, "Material"=>1, "ElectricEquipmentDefinition"=>3, "ElectricEquipment"=>3, "SurfacePropertyConvectionCoefficients"=>6, "EnergyManagementSystemOutputVariable"=>1}
    expected_values = {"erv_priority"=>nil, "terrain_type"=>"Suburbs", "duct_location"=>"unfinished attic zone", "infiltration_c"=>0.0696580370384, "infiltration_cs"=>0.0862380821416, "infiltration_cw"=>0.128435824905, "natvent_cs"=>0.000179260407789, "natvent_cw"=>0.000282172823794, "duct_leak_supply"=>0.136963386963, "duct_leak_return"=>0.1000999001, "f_oa"=>0.0368634868631, "faneff_wh"=>0.47194744, "fan_frac_to_space"=>0, "ra_duct_volume"=>90}
    _test_measure("SFD_2000sqft_2story_SL_UA_3Beds_2Baths_Denver_Furnace_CentralAC.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 0, 1)  
  end
  
  def test_nat_vent_4_wkdy
    args_hash = {}
    args_hash["has_hvac_flue"] = "true" 
    args_hash["nat_vent_num_weekdays"] = 4
    expected_num_del_objects = {}
    expected_num_new_objects = {"ScheduleRuleset"=>7, "ScheduleRule"=>84, "Surface"=>6, "EnergyManagementSystemSubroutine"=>1, "EnergyManagementSystemProgramCallingManager"=>2, "EnergyManagementSystemProgram"=>3, "EnergyManagementSystemSensor"=>21, "EnergyManagementSystemActuator"=>17, "EnergyManagementSystemGlobalVariable"=>23, "AirLoopHVACReturnPlenum"=>1, "OtherEquipmentDefinition"=>10, "OtherEquipment"=>10, "ThermalZone"=>1, "ZoneMixing"=>2, "OutputVariable"=>14, "SpaceInfiltrationDesignFlowRate"=>2, "SpaceInfiltrationEffectiveLeakageArea"=>1, "Construction"=>1, "Space"=>1, "Material"=>1, "ElectricEquipmentDefinition"=>3, "ElectricEquipment"=>3, "SurfacePropertyConvectionCoefficients"=>6, "EnergyManagementSystemOutputVariable"=>1}
    expected_values = {"erv_priority"=>nil, "terrain_type"=>"Suburbs", "duct_location"=>"unfinished attic zone", "infiltration_c"=>0.0696580370384, "infiltration_cs"=>0.0862380821416, "infiltration_cw"=>0.128435824905, "natvent_cs"=>0.000179260407789, "natvent_cw"=>0.000282172823794, "duct_leak_supply"=>0.136963386963, "duct_leak_return"=>0.1000999001, "f_oa"=>0.0368634868631, "faneff_wh"=>0.47194744, "fan_frac_to_space"=>0, "ra_duct_volume"=>90}
    _test_measure("SFD_2000sqft_2story_SL_UA_3Beds_2Baths_Denver_Furnace_CentralAC.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 0, 1)  
  end
  
  def test_nat_vent_5_wkdy
    args_hash = {}
    args_hash["has_hvac_flue"] = "true" 
    args_hash["nat_vent_num_weekdays"] = 5
    expected_num_del_objects = {}
    expected_num_new_objects = {"ScheduleRuleset"=>7, "ScheduleRule"=>84, "Surface"=>6, "EnergyManagementSystemSubroutine"=>1, "EnergyManagementSystemProgramCallingManager"=>2, "EnergyManagementSystemProgram"=>3, "EnergyManagementSystemSensor"=>21, "EnergyManagementSystemActuator"=>17, "EnergyManagementSystemGlobalVariable"=>23, "AirLoopHVACReturnPlenum"=>1, "OtherEquipmentDefinition"=>10, "OtherEquipment"=>10, "ThermalZone"=>1, "ZoneMixing"=>2, "OutputVariable"=>14, "SpaceInfiltrationDesignFlowRate"=>2, "SpaceInfiltrationEffectiveLeakageArea"=>1, "Construction"=>1, "Space"=>1, "Material"=>1, "ElectricEquipmentDefinition"=>3, "ElectricEquipment"=>3, "SurfacePropertyConvectionCoefficients"=>6, "EnergyManagementSystemOutputVariable"=>1}
    expected_values = {"erv_priority"=>nil, "terrain_type"=>"Suburbs", "duct_location"=>"unfinished attic zone", "infiltration_c"=>0.0696580370384, "infiltration_cs"=>0.0862380821416, "infiltration_cw"=>0.128435824905, "natvent_cs"=>0.000179260407789, "natvent_cw"=>0.000282172823794, "duct_leak_supply"=>0.136963386963, "duct_leak_return"=>0.1000999001, "f_oa"=>0.0368634868631, "faneff_wh"=>0.47194744, "fan_frac_to_space"=>0, "ra_duct_volume"=>90}
    _test_measure("SFD_2000sqft_2story_SL_UA_3Beds_2Baths_Denver_Furnace_CentralAC.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 0, 1)    
   end
   
  def test_mshp
    args_hash = {}
    args_hash["has_hvac_flue"] = "true" 
    expected_num_del_objects = {}
    expected_num_new_objects = {"ScheduleRuleset"=>7, "ScheduleRule"=>84, "EnergyManagementSystemProgramCallingManager"=>2, "EnergyManagementSystemProgram"=>3, "EnergyManagementSystemSensor"=>12, "EnergyManagementSystemActuator"=>5, "EnergyManagementSystemGlobalVariable"=>2, "OutputVariable"=>14, "SpaceInfiltrationDesignFlowRate"=>2, "SpaceInfiltrationEffectiveLeakageArea"=>1, "ElectricEquipmentDefinition"=>3, "ElectricEquipment"=>3, "Space"=>1, "ThermalZone"=>1, "Surface"=>6, "Construction"=>1, "Material"=>1, "SurfacePropertyConvectionCoefficients"=>6, "EnergyManagementSystemOutputVariable"=>1}
    expected_values = {"erv_priority"=>nil, "terrain_type"=>"Suburbs", "duct_location"=>nil, "infiltration_c"=>0.0696580370384, "infiltration_cs"=>0.0862380821416, "infiltration_cw"=>0.128435824905, "natvent_cs"=>0.000179260407789, "natvent_cw"=>0.000282172823794, "duct_leak_supply"=>0, "duct_leak_return"=>0, "f_oa"=>0, "faneff_wh"=>0.47194744, "fan_frac_to_space"=>0, "ra_duct_volume"=>0}
    _test_measure("SFD_2000sqft_2story_SL_UA_3Beds_2Baths_Denver_MSHP.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 0, 3)      
  end   
   
  def test_duct_location_frac
    args_hash = {}
    args_hash["has_hvac_flue"] = "true" 
    args_hash["duct_location"] = Constants.AtticZone
    args_hash["duct_location_frac"] = "0.5"
    expected_num_del_objects = {}
    expected_num_new_objects = {"ScheduleRuleset"=>7, "ScheduleRule"=>84, "Surface"=>6, "EnergyManagementSystemSubroutine"=>1, "EnergyManagementSystemProgramCallingManager"=>2, "EnergyManagementSystemProgram"=>3, "EnergyManagementSystemSensor"=>21, "EnergyManagementSystemActuator"=>17, "EnergyManagementSystemGlobalVariable"=>23, "AirLoopHVACReturnPlenum"=>1, "OtherEquipmentDefinition"=>10, "OtherEquipment"=>10, "ThermalZone"=>1, "ZoneMixing"=>2, "OutputVariable"=>14, "SpaceInfiltrationDesignFlowRate"=>2, "SpaceInfiltrationEffectiveLeakageArea"=>1, "Construction"=>1, "Space"=>1, "Material"=>1, "ElectricEquipmentDefinition"=>3, "ElectricEquipment"=>3, "SurfacePropertyConvectionCoefficients"=>6, "EnergyManagementSystemOutputVariable"=>1}
    expected_values = {"erv_priority"=>nil, "terrain_type"=>"Suburbs", "duct_location"=>nil, "infiltration_c"=>0.0696580370384, "infiltration_cs"=>0.0862380821416, "infiltration_cw"=>0.128435824905, "natvent_cs"=>0.000179260407789, "natvent_cw"=>0.000282172823794, "duct_leak_supply"=>0.10999050999, "duct_leak_return"=>0.1000999001, "f_oa"=>0.00989060989011, "faneff_wh"=>0.47194744, "fan_frac_to_space"=>0, "ra_duct_volume"=>90}
    _test_measure("SFD_2000sqft_2story_SL_UA_3Beds_2Baths_Denver_Furnace_CentralAC.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 0, 1)     
  end   
  
  def test_return_loss_greater_than_supply_loss
    args_hash = {}
    args_hash["has_hvac_flue"] = "true" 
    args_hash["duct_supply_frac"] = 0.067
    args_hash["duct_return_frac"] = 0.6
    expected_num_del_objects = {}
    expected_num_new_objects = {"ScheduleRuleset"=>7, "ScheduleRule"=>84, "Surface"=>6, "EnergyManagementSystemSubroutine"=>1, "EnergyManagementSystemProgramCallingManager"=>2, "EnergyManagementSystemProgram"=>3, "EnergyManagementSystemSensor"=>21, "EnergyManagementSystemActuator"=>17, "EnergyManagementSystemGlobalVariable"=>23, "AirLoopHVACReturnPlenum"=>1, "OtherEquipmentDefinition"=>10, "OtherEquipment"=>10, "ThermalZone"=>1, "ZoneMixing"=>2, "OutputVariable"=>14, "SpaceInfiltrationDesignFlowRate"=>2, "SpaceInfiltrationEffectiveLeakageArea"=>1, "Construction"=>1, "Space"=>1, "Material"=>1, "ElectricEquipmentDefinition"=>3, "ElectricEquipment"=>3, "SurfacePropertyConvectionCoefficients"=>6, "EnergyManagementSystemOutputVariable"=>1}
    expected_values = {"erv_priority"=>nil, "terrain_type"=>"Suburbs", "duct_location"=>nil, "infiltration_c"=>0.0696580370384, "infiltration_cs"=>0.0862380821416, "infiltration_cw"=>0.128435824905, "natvent_cs"=>0.000179260407789, "natvent_cw"=>0.000282172823794, "duct_leak_supply"=>0.0331322181319, "duct_leak_return"=>0.25984015984, "f_oa"=>0.226707941708, "faneff_wh"=>0.47194744, "fan_frac_to_space"=>0, "ra_duct_volume"=>90}
    _test_measure("SFD_2000sqft_2story_SL_UA_3Beds_2Baths_Denver_Furnace_CentralAC.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 0, 1)    
  end

  def test_duct_num_returns
    args_hash = {}
    args_hash["has_hvac_flue"] = "true" 
    args_hash["duct_num_returns"] = "1"
    expected_num_del_objects = {}
    expected_num_new_objects = {"ScheduleRuleset"=>7, "ScheduleRule"=>84, "Surface"=>6, "EnergyManagementSystemSubroutine"=>1, "EnergyManagementSystemProgramCallingManager"=>2, "EnergyManagementSystemProgram"=>3, "EnergyManagementSystemSensor"=>21, "EnergyManagementSystemActuator"=>17, "EnergyManagementSystemGlobalVariable"=>23, "AirLoopHVACReturnPlenum"=>1, "OtherEquipmentDefinition"=>10, "OtherEquipment"=>10, "ThermalZone"=>1, "ZoneMixing"=>2, "OutputVariable"=>14, "SpaceInfiltrationDesignFlowRate"=>2, "SpaceInfiltrationEffectiveLeakageArea"=>1, "Construction"=>1, "Space"=>1, "Material"=>1, "ElectricEquipmentDefinition"=>3, "ElectricEquipment"=>3, "SurfacePropertyConvectionCoefficients"=>6, "EnergyManagementSystemOutputVariable"=>1}
    expected_values = {"erv_priority"=>nil, "terrain_type"=>"Suburbs", "duct_location"=>nil, "infiltration_c"=>0.0696580370384, "infiltration_cs"=>0.0862380821416, "infiltration_cw"=>0.128435824905, "natvent_cs"=>0.000179260407789, "natvent_cw"=>0.000282172823794, "duct_leak_supply"=>0.136963386963, "duct_leak_return"=>0.1000999001, "f_oa"=>0.0368634868631, "faneff_wh"=>0.47194744, "fan_frac_to_space"=>0, "ra_duct_volume"=>30}
    _test_measure("SFD_2000sqft_2story_SL_UA_3Beds_2Baths_Denver_Furnace_CentralAC.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 0, 1)    
  end
  
  def test_duct_location_attic_but_no_attic
    args_hash = {}
    args_hash["has_hvac_flue"] = "true" 
    args_hash["duct_location"] = Constants.AtticZone
    expected_num_del_objects = {}
    expected_num_new_objects = {"ScheduleRuleset"=>7, "ScheduleRule"=>84, "EnergyManagementSystemProgramCallingManager"=>2, "EnergyManagementSystemProgram"=>3, "EnergyManagementSystemSensor"=>12, "EnergyManagementSystemActuator"=>5, "EnergyManagementSystemGlobalVariable"=>2, "OutputVariable"=>14, "SpaceInfiltrationDesignFlowRate"=>2, "SpaceInfiltrationEffectiveLeakageArea"=>1, "ElectricEquipmentDefinition"=>3, "ElectricEquipment"=>3, "Surface"=>6, "Construction"=>1, "AirLoopHVACReturnPlenum"=>1, "ThermalZone"=>1, "Space"=>1, "Material"=>1, "SurfacePropertyConvectionCoefficients"=>6, "EnergyManagementSystemOutputVariable"=>1}
    expected_values = {"erv_priority"=>nil, "terrain_type"=>"Suburbs", "duct_location"=>"living zone", "infiltration_c"=>0.0494876816885, "infiltration_cs"=>0.0858215829169, "infiltration_cw"=>0.128435824905, "natvent_cs"=>0.00022967739748, "natvent_cw"=>0.000319397949371, "duct_leak_supply"=>0, "duct_leak_return"=>0, "f_oa"=>0, "faneff_wh"=>0.47194744, "fan_frac_to_space"=>0, "ra_duct_volume"=>0}
    _test_measure("SFD_2000sqft_2story_SL_GRG_FR_3Beds_2Baths_Denver_Furnace_CentralAC.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 0, 1)      
  end
  
  def test_no_living_garage_attic_infiltration
    args_hash = {}
    args_hash["has_hvac_flue"] = "true" 
    args_hash["living_ach50"] = 0
    args_hash["garage_ach50"] = 0
    args_hash["unfinished_attic_sla"] = 0
    expected_num_del_objects = {}
    expected_num_new_objects = {"ScheduleRuleset"=>7, "ScheduleRule"=>84, "Surface"=>6, "EnergyManagementSystemSubroutine"=>1, "EnergyManagementSystemProgramCallingManager"=>2, "EnergyManagementSystemProgram"=>3, "EnergyManagementSystemSensor"=>21, "EnergyManagementSystemActuator"=>17, "EnergyManagementSystemGlobalVariable"=>23, "AirLoopHVACReturnPlenum"=>1, "OtherEquipmentDefinition"=>10, "OtherEquipment"=>10, "ThermalZone"=>1, "ZoneMixing"=>2, "OutputVariable"=>14, "SpaceInfiltrationDesignFlowRate"=>2, "SpaceInfiltrationEffectiveLeakageArea"=>1, "Construction"=>1, "Space"=>1, "Material"=>1, "ElectricEquipmentDefinition"=>3, "ElectricEquipment"=>3, "SurfacePropertyConvectionCoefficients"=>6, "EnergyManagementSystemOutputVariable"=>1}
    expected_values = {"erv_priority"=>nil, "terrain_type"=>"Suburbs", "duct_location"=>"unfinished attic zone", "infiltration_c"=>0.0696580370384, "infiltration_cs"=>0.0862380821416, "infiltration_cw"=>0.128435824905, "natvent_cs"=>0.000179260407789, "natvent_cw"=>0.000282172823794, "duct_leak_supply"=>0.136963386963, "duct_leak_return"=>0.1000999001, "f_oa"=>0.000001, "faneff_wh"=>0.47194744, "fan_frac_to_space"=>0, "ra_duct_volume"=>90}
    _test_measure("SFD_2000sqft_2story_SL_GRG_UA_3Beds_2Baths_Denver_Furnace_CentralAC.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 0, 1)
  end
  
  def test_garage_with_attic
    args_hash = {}
    args_hash["has_hvac_flue"] = "true"
    expected_num_del_objects = {}
    expected_num_new_objects = {"ScheduleRuleset"=>7, "ScheduleRule"=>84, "Surface"=>6, "EnergyManagementSystemSubroutine"=>1, "EnergyManagementSystemProgramCallingManager"=>2, "EnergyManagementSystemProgram"=>3, "EnergyManagementSystemSensor"=>21, "EnergyManagementSystemActuator"=>17, "EnergyManagementSystemGlobalVariable"=>23, "AirLoopHVACReturnPlenum"=>1, "OtherEquipmentDefinition"=>10, "OtherEquipment"=>10, "ThermalZone"=>1, "ZoneMixing"=>2, "OutputVariable"=>14, "SpaceInfiltrationDesignFlowRate"=>2, "SpaceInfiltrationEffectiveLeakageArea"=>2, "Construction"=>1, "Space"=>1, "Material"=>1, "ElectricEquipmentDefinition"=>3, "ElectricEquipment"=>3, "SurfacePropertyConvectionCoefficients"=>6, "EnergyManagementSystemOutputVariable"=>1}
    expected_values = {"erv_priority"=>nil, "terrain_type"=>"Suburbs", "duct_location"=>"unfinished attic zone", "infiltration_c"=>0.0696580370384, "infiltration_cs"=>0.0862380821416, "infiltration_cw"=>0.128435824905, "natvent_cs"=>0.000179260407789, "natvent_cw"=>0.000282172823794, "duct_leak_supply"=>0.136963386963, "duct_leak_return"=>0.1000999001, "f_oa"=>0.0368634868631, "faneff_wh"=>0.47194744, "fan_frac_to_space"=>0, "ra_duct_volume"=>90}
    _test_measure("SFD_2000sqft_2story_SL_GRG_UA_3Beds_2Baths_Denver_Furnace_CentralAC.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 0, 1)    
  end
    
  def test_garage_without_attic
    args_hash = {}  
    args_hash["has_hvac_flue"] = "true"
    expected_num_del_objects = {}
    expected_num_new_objects = {"ScheduleRuleset"=>7, "ScheduleRule"=>84, "Surface"=>6, "EnergyManagementSystemSubroutine"=>1, "EnergyManagementSystemProgramCallingManager"=>2, "EnergyManagementSystemProgram"=>3, "EnergyManagementSystemSensor"=>21, "EnergyManagementSystemActuator"=>17, "EnergyManagementSystemGlobalVariable"=>23, "AirLoopHVACReturnPlenum"=>1, "OtherEquipmentDefinition"=>10, "OtherEquipment"=>10, "ThermalZone"=>1, "ZoneMixing"=>2, "OutputVariable"=>14, "SpaceInfiltrationDesignFlowRate"=>2, "SpaceInfiltrationEffectiveLeakageArea"=>1, "Construction"=>1, "Space"=>1, "Material"=>1, "ElectricEquipmentDefinition"=>3, "ElectricEquipment"=>3, "SurfacePropertyConvectionCoefficients"=>6, "EnergyManagementSystemOutputVariable"=>1}
    expected_values = {"erv_priority"=>nil, "terrain_type"=>"Suburbs", "duct_location"=>"garage zone", "infiltration_c"=>0.0494876816885, "infiltration_cs"=>0.0858215829169, "infiltration_cw"=>0.128435824905, "natvent_cs"=>0.00022967739748, "natvent_cw"=>0.000319397949371, "duct_leak_supply"=>0.136963386963, "duct_leak_return"=>0.1000999001, "f_oa"=>0.0368634868631, "faneff_wh"=>0.47194744, "fan_frac_to_space"=>0, "ra_duct_volume"=>120}
    _test_measure("SFD_2000sqft_2story_SL_GRG_FR_3Beds_2Baths_Denver_Furnace_CentralAC.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 0, 1)    
  end
  
  def test_retrofit_infiltration
    args_hash = {}
    args_hash["has_hvac_flue"] = "true"
    expected_num_del_objects = {}
    expected_num_new_objects = {"ScheduleRuleset"=>7, "ScheduleRule"=>84, "Surface"=>6, "EnergyManagementSystemSubroutine"=>1, "EnergyManagementSystemProgramCallingManager"=>2, "EnergyManagementSystemProgram"=>3, "EnergyManagementSystemSensor"=>21, "EnergyManagementSystemActuator"=>17, "EnergyManagementSystemGlobalVariable"=>23, "AirLoopHVACReturnPlenum"=>1, "OtherEquipmentDefinition"=>10, "OtherEquipment"=>10, "ThermalZone"=>1, "ZoneMixing"=>2, "OutputVariable"=>14, "SpaceInfiltrationDesignFlowRate"=>2, "SpaceInfiltrationEffectiveLeakageArea"=>1, "Construction"=>1, "Space"=>1, "Material"=>1, "ElectricEquipmentDefinition"=>3, "ElectricEquipment"=>3, "SurfacePropertyConvectionCoefficients"=>6, "EnergyManagementSystemOutputVariable"=>1}
    expected_values = {"erv_priority"=>nil, "terrain_type"=>"Suburbs", "duct_location"=>"unfinished attic zone", "infiltration_c"=>0.0696580370384, "infiltration_cs"=>0.0862380821416, "infiltration_cw"=>0.128435824905, "natvent_cs"=>0.000179260407789, "natvent_cw"=>0.000282172823794, "duct_leak_supply"=>0.136963386963, "duct_leak_return"=>0.1000999001, "f_oa"=>0.0368634868631, "faneff_wh"=>0.47194744, "fan_frac_to_space"=>0, "ra_duct_volume"=>90}
    model = _test_measure("SFD_2000sqft_2story_SL_UA_3Beds_2Baths_Denver_Furnace_CentralAC.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 0, 1)
    args_hash["living_ach50"] = 3
    expected_num_del_objects = {"ScheduleRuleset"=>7, "ScheduleRule"=>84, "Surface"=>6, "EnergyManagementSystemSubroutine"=>1, "EnergyManagementSystemProgramCallingManager"=>2, "EnergyManagementSystemProgram"=>3, "EnergyManagementSystemSensor"=>21, "EnergyManagementSystemActuator"=>17, "EnergyManagementSystemGlobalVariable"=>23, "AirLoopHVACReturnPlenum"=>1, "OtherEquipmentDefinition"=>10, "OtherEquipment"=>10, "ThermalZone"=>1, "ZoneMixing"=>2, "SpaceInfiltrationDesignFlowRate"=>2, "SpaceInfiltrationEffectiveLeakageArea"=>1, "Construction"=>1, "Space"=>1, "Material"=>1, "ElectricEquipmentDefinition"=>3, "ElectricEquipment"=>3, "SurfacePropertyConvectionCoefficients"=>6, "EnergyManagementSystemOutputVariable"=>1}
    expected_num_new_objects = {"ScheduleRuleset"=>7, "ScheduleRule"=>84, "Surface"=>6, "EnergyManagementSystemSubroutine"=>1, "EnergyManagementSystemProgramCallingManager"=>2, "EnergyManagementSystemProgram"=>3, "EnergyManagementSystemSensor"=>21, "EnergyManagementSystemActuator"=>17, "EnergyManagementSystemGlobalVariable"=>23, "AirLoopHVACReturnPlenum"=>1, "OtherEquipmentDefinition"=>10, "OtherEquipment"=>10, "ThermalZone"=>1, "ZoneMixing"=>2, "SpaceInfiltrationDesignFlowRate"=>2, "SpaceInfiltrationEffectiveLeakageArea"=>1, "Construction"=>1, "Space"=>1, "Material"=>1, "ElectricEquipmentDefinition"=>3, "ElectricEquipment"=>3, "SurfacePropertyConvectionCoefficients"=>6, "EnergyManagementSystemOutputVariable"=>1}
    expected_values = {"erv_priority"=>nil, "terrain_type"=>"Suburbs", "duct_location"=>"unfinished attic zone", "infiltration_c"=>0.029853444445, "infiltration_cs"=>0.0862380821416, "infiltration_cw"=>0.128435824905, "natvent_cs"=>0.000179260407789, "natvent_cw"=>0.000282172823794, "duct_leak_supply"=>0.136963386963, "duct_leak_return"=>0.1000999001, "f_oa"=>0.0368634868631, "faneff_wh"=>0.47194744, "fan_frac_to_space"=>0, "ra_duct_volume"=>90}
    _test_measure(model, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 0, 1)     
  end
  
  def test_single_family_attached_new_construction
    num_units = 4
    args_hash = {}
    args_hash["has_hvac_flue"] = "true"
    expected_num_del_objects = {}
    expected_num_new_objects = {"ScheduleRuleset"=>num_units*7, "ScheduleRule"=>num_units*84, "EnergyManagementSystemSubroutine"=>num_units*1, "EnergyManagementSystemProgramCallingManager"=>num_units*2, "EnergyManagementSystemProgram"=>num_units*3, "EnergyManagementSystemSensor"=>num_units*21, "EnergyManagementSystemActuator"=>num_units*17, "EnergyManagementSystemGlobalVariable"=>num_units*23, "OutputVariable"=>14, "SpaceInfiltrationDesignFlowRate"=>num_units*2, "ZoneMixing"=>num_units*2, "OtherEquipment"=>num_units*10, "OtherEquipmentDefinition"=>num_units*10, "SpaceInfiltrationEffectiveLeakageArea"=>1, "Construction"=>1, "Surface"=>num_units*6, "Space"=>num_units*1, "ThermalZone"=>num_units*1, "AirLoopHVACReturnPlenum"=>num_units*1, "Material"=>1, "ElectricEquipmentDefinition"=>num_units*3, "ElectricEquipment"=>num_units*3, "SurfacePropertyConvectionCoefficients"=>num_units*6, "EnergyManagementSystemOutputVariable"=>num_units}
    expected_values = {"erv_priority"=>nil, "terrain_type"=>"Suburbs", "duct_location"=>"unfinished attic zone", "infiltration_c"=>0.0414006333313, "infiltration_cs"=>0.0603332642964, "infiltration_cw"=>0.128435824905, "natvent_cs"=>0.0000896302038946, "natvent_cw"=>0.000199526317171, "duct_leak_supply"=>0.1999000999, "duct_leak_return"=>0.1000999001, "f_oa"=>0.0998001998002, "faneff_wh"=>0.47194744, "fan_frac_to_space"=>0, "ra_duct_volume"=>33.63722}
    _test_measure("SFA_4units_1story_SL_UA_3Beds_2Baths_Denver_Furnace_CentralAC.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 0, num_units)
  end

  def test_multifamily_new_construction
    num_units = 8
    args_hash = {}
    args_hash["has_hvac_flue"] = "true"
    expected_num_del_objects = {}
    expected_num_new_objects = {"ScheduleRuleset"=>num_units*7, "ScheduleRule"=>num_units*84, "EnergyManagementSystemProgramCallingManager"=>num_units*2, "EnergyManagementSystemProgram"=>num_units*3, "EnergyManagementSystemSensor"=>num_units*12, "EnergyManagementSystemActuator"=>num_units*5, "EnergyManagementSystemGlobalVariable"=>num_units*2, "OutputVariable"=>14, "SpaceInfiltrationDesignFlowRate"=>num_units*2, "ElectricEquipmentDefinition"=>num_units*3, "ElectricEquipment"=>num_units*3, "Surface"=>num_units*6, "Material"=>1, "Space"=>num_units*1, "AirLoopHVACReturnPlenum"=>num_units*1, "ThermalZone"=>num_units*1, "Construction"=>1, "SurfacePropertyConvectionCoefficients"=>num_units*6, "EnergyManagementSystemOutputVariable"=>num_units}
    expected_values = {"erv_priority"=>nil, "terrain_type"=>"Suburbs", "duct_location"=>"unfinished attic zone", "infiltration_c"=>0.0465692660323, "infiltration_cs"=>0.0497586232311, "infiltration_cw"=>0.128435824905, "natvent_cs"=>0.0000896302038946, "natvent_cw"=>0.000199526317171, "duct_leak_supply"=>0, "duct_leak_return"=>0, "f_oa"=>0.0998001998002, "faneff_wh"=>0.47194744, "fan_frac_to_space"=>0, "ra_duct_volume"=>0}
    _test_measure("MF_8units_1story_SL_3Beds_2Baths_Denver_Furnace_CentralAC.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 0, num_units)
  end
  
  private
  
  def _test_error(osm_file_or_model, args_hash)
    # create an instance of the measure
    measure = ResidentialAirflow.new

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

    # assert that it didn't run
    assert_equal("Fail", result.value.valueName)
    assert(result.errors.size == 1)
    
    return result
  end  
  
  def _test_measure(osm_file_or_model, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, num_infos=0, num_warnings=0, debug=false)
    # create an instance of the measure
    measure = ResidentialAirflow.new

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
    
    # check that no lines exceed 100 characters
    model.to_s.each_line do |line|
      next unless line.strip.start_with?("Set", "If", "Else", "EndIf")
      assert(line.length <= 100)
    end
    
    #show_output(result)
    
    # assert that it ran correctly
    assert_equal("Success", result.value.valueName)
    assert(result.info.size == num_infos)
    assert(result.warnings.size == num_warnings)
    
    # get the final objects in the model
    final_objects = get_objects(model)
    
    # get new and deleted objects
    obj_type_exclusions = ["ScheduleDay", "ZoneHVACEquipmentList", "PortList", "Node", "SizingZone", "ScheduleConstant", "ScheduleTypeLimits", "CurveCubic", "CurveExponent"]
    all_new_objects = get_object_additions(initial_objects, final_objects, obj_type_exclusions)
    all_del_objects = get_object_additions(final_objects, initial_objects, obj_type_exclusions)
    
    # check we have the expected number of new/deleted objects
    check_num_objects(all_new_objects, expected_num_new_objects, "added")
    check_num_objects(all_del_objects, expected_num_del_objects, "deleted")
    check_unused_ems_variable(model)

    all_new_objects.each do |obj_type, new_objects|
        new_objects.each do |new_object|
            next if not new_object.respond_to?("to_#{obj_type}")
            new_object = new_object.public_send("to_#{obj_type}").get
            if obj_type == "EnergyManagementSystemSensor"
                next unless new_object.name.to_s == "#{Constants.ObjectNameDucts} ah t sens".gsub(" ","_")
                next if expected_values["duct_location"].nil?
                assert_equal(expected_values["duct_location"], new_object.keyName)
            elsif obj_type == "EnergyManagementSystemProgram"
                if new_object.name.to_s == "#{Constants.ObjectNameInfiltration} program".gsub(" ","_")
                  new_object.lines.each do |line|
                      if line.start_with? "Set c ="
                        assert_in_epsilon(expected_values["infiltration_c"], line.split(" = ")[1].to_f, 0.01)
                      elsif line.start_with? "Set Cs ="
                        assert_in_epsilon(expected_values["infiltration_cs"], line.split(" = ")[1].to_f, 0.01)
                      elsif line.start_with? "Set Cw ="
                        assert_in_epsilon(expected_values["infiltration_cw"], line.split(" = ")[1].to_f, 0.01)
                      elsif line.start_with? "Set faneff_wh ="
                        assert_in_epsilon(expected_values["faneff_wh"], line.split(" = ")[1].to_f, 0.01)                        
                      end
                  end
                elsif new_object.name.to_s == "#{Constants.ObjectNameNaturalVentilation} program".gsub(" ","_")
                  new_object.lines.each do |line|
                      if line.start_with? "Set Cs ="
                        assert_in_epsilon(expected_values["natvent_cs"], line.split(" = ")[1].to_f, 0.01)
                      elsif line.start_with? "Set Cw ="
                        assert_in_epsilon(expected_values["natvent_cw"], line.split(" = ")[1].to_f, 0.01)
                      end
                  end
                elsif new_object.name.to_s == "#{Constants.ObjectNameDucts} program".gsub(" ","_")
                  new_object.lines.each do |line|
                      duct_leak_supply_fan_equiv = "#{Constants.ObjectNameDucts} leak sup fan equiv".gsub("|","_").gsub(" ","_")
                      duct_leak_return_fan_equiv = "#{Constants.ObjectNameDucts} leak sup fan equiv".gsub("|","_").gsub(" ","_")
                      if line.start_with? "Set #{duct_leak_supply_fan_equiv} ="
                        assert_in_epsilon(expected_values["duct_leak_supply"], line.split(" = ")[1].to_f, 0.01)
                      elsif line.start_with? "Set #{duct_leak_return_fan_equiv} ="
                        assert_in_epsilon(expected_values["duct_leak_return"], line.split(" = ")[1].to_f, 0.01)
                      end
                  end                  
                end
            elsif obj_type == "EnergyManagementSystemSubroutine"
                if new_object.name.to_s == "#{Constants.ObjectNameDucts} leak subrout".gsub("|","_").gsub(" ","_")
                  new_object.lines.each do |line|
                      if line.start_with? "Set f_sup ="
                        assert_in_epsilon(expected_values["duct_leak_supply"], line.split(" = ")[1].to_f, 0.01)
                      elsif line.start_with? "Set f_ret ="
                        assert_in_epsilon(expected_values["duct_leak_return"], line.split(" = ")[1].to_f, 0.01)
                      elsif line.start_with? "Set f_OA ="
                        assert_in_epsilon(expected_values["f_oa"], line.split(" = ")[1].to_f, 0.01)
                      end
                  end
                end
            elsif obj_type == "ElectricEquipmentDefinition"
              if new_object.name.to_s == "#{Constants.ObjectNameInfiltration} house exh fan load equip"
                  assert_in_epsilon(expected_values["fan_frac_to_space"], 1-new_object.fractionLost, 0.01)
              end
            elsif obj_type == "ThermalZone"
              if new_object.name.to_s == "#{Constants.ObjectNameDucts} ret air zone"
                  assert_in_epsilon(expected_values["ra_duct_volume"], OpenStudio.convert(new_object.volume.get,"m^3","ft^3").get, 0.01)
              end
            elsif obj_type == "ZoneHVACEnergyRecoveryVentilator"
                model.getThermalZones.each do |thermal_zone|
                  cooling_seq = thermal_zone.equipmentInCoolingOrder.index new_object
                  heating_seq = thermal_zone.equipmentInHeatingOrder.index new_object
                  next if cooling_seq.nil? or heating_seq.nil?
                  assert_equal(expected_values["hvac_priority"], cooling_seq+1)
                  assert_equal(expected_values["hvac_priority"], heating_seq+1)
                end            
            end
        end
    end
    unless expected_values["terrain_type"].nil?
      assert_equal(expected_values["terrain_type"], model.getSite.terrain.to_s)
    end
    model.getThermalZones.each do |thermal_zone|
      next unless thermal_zone.name.to_s == Constants.LivingZone
      thermal_zone.equipmentInCoolingOrder.each do |equip|
        next unless equip.name.to_s.include? "erv"
        assert_equal(expected_values["erv_priority"]-1, thermal_zone.equipmentInCoolingOrder.index(equip))
      end
      thermal_zone.equipmentInHeatingOrder.each do |equip|
        next unless equip.name.to_s.include? "erv"
        assert_equal(expected_values["erv_priority"]-1, thermal_zone.equipmentInHeatingOrder.index(equip))
      end
    end
    
    return model
  end

end
