require_relative '../../../test/minitest_helper'
require 'openstudio'
require 'openstudio/ruleset/ShowRunnerOutput'
require 'minitest/autorun'
require_relative '../measure.rb'
require 'fileutils'

class ResidentialHotWaterHeaterHeatPumpTest < MiniTest::Test

    def osm_geo_loc
        return "SFD_2000sqft_2story_FB_GRG_UA_Denver.osm"
    end
  
    def osm_geo_beds
        return "SFD_2000sqft_2story_FB_GRG_UA_3Beds_2Baths.osm"
    end

    def osm_geo_beds_loc
        return "SFD_2000sqft_2story_FB_GRG_UA_3Beds_2Baths_Denver.osm"
    end
  
    def osm_geo_beds_loc_1_1
        return "SFD_2000sqft_2story_FB_GRG_UA_1Beds_1Baths_Denver.osm"
    end

    def osm_geo_beds_loc_2_1
        return "SFD_2000sqft_2story_FB_GRG_UA_2Beds_1Baths_Denver.osm"
    end

    def osm_geo_beds_loc_2_2
        return "SFD_2000sqft_2story_FB_GRG_UA_2Beds_2Baths_Denver.osm"
    end

    def osm_geo_beds_loc_5_3
        return "SFD_2000sqft_2story_FB_GRG_UA_5Beds_3Baths_Denver.osm"
    end
    
    def osm_geo_beds_loc_tank_elec
        return "SFD_2000sqft_2story_FB_GRG_UA_3Beds_2Baths_Denver_ElecWHTank.osm"
    end
  
    def osm_geo_beds_loc_tank_gas
        return "SFD_2000sqft_2story_FB_GRG_UA_3Beds_2Baths_Denver_GasWHTank.osm"
    end

    def osm_geo_beds_loc_tank_oil
        return "SFD_2000sqft_2story_FB_GRG_UA_3Beds_2Baths_Denver_OilWHTank.osm"
    end

    def osm_geo_beds_loc_tank_propane
        return "SFD_2000sqft_2story_FB_GRG_UA_3Beds_2Baths_Denver_PropaneWHTank.osm"
    end

    def osm_geo_beds_loc_tankless_electric
        return "SFD_2000sqft_2story_FB_GRG_UA_3Beds_2Baths_Denver_ElecWHTankless.osm"
    end

    def osm_geo_beds_loc_tankless_gas
        return "SFD_2000sqft_2story_FB_GRG_UA_3Beds_2Baths_Denver_GasWHTankless.osm"
    end

    def osm_geo_beds_loc_tankless_propane
        return "SFD_2000sqft_2story_FB_GRG_UA_3Beds_2Baths_Denver_PropaneWHTankless.osm"
    end

    def test_new_construction_50
        args_hash = {}
        expected_num_del_objects = {}
        expected_num_new_objects = {"WaterHeaterStratified"=>1, "PlantLoop"=>1, "PumpVariableSpeed"=>1, "WaterHeaterHeatPumpWrappedCondenser"=>1, "CoilWaterHeatingAirToWaterHeatPumpWrapped"=>1, "FanOnOff"=>1, "OtherEquipment"=>2, "OtherEquipmentDefinition"=>2, "EnergyManagementSystemSensor"=>9, "EnergyManagementSystemActuator"=>7, "EnergyManagementSystemTrendVariable"=>3, "EnergyManagementSystemProgram"=>2, "EnergyManagementSystemProgramCallingManager"=>1, "OutputVariable"=>16} #"ScheduleRuleset"=>2, "ScheduleConstant"=>8,
        expected_values = {"TankVolume"=>45, "Heater1Height"=>0.732, "Heater2Height"=>0.129, "TankU"=>1.13, "OnCycle"=>3, "OffCycle"=>3, "CondBottom"=>0.0870, "CondTop"=>0.560, "AirflowRate"=>0.0854, "Sensor1Height"=>0.818, "Sensor2Height"=>0.818, "Cap"=>1400, "COP"=>2.8, "SHR"=>0.88, "WBTemp"=>13.08, "FanEff"=>0.235}
        _test_measure(osm_geo_beds_loc, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 1)
    end
  
    def test_new_construction_40
        args_hash = {}
        args_hash["storage_tank_volume"] = "40"
        expected_num_del_objects = {}
        expected_num_new_objects = {"WaterHeaterStratified"=>1, "PlantLoop"=>1, "PumpVariableSpeed"=>1, "WaterHeaterHeatPumpWrappedCondenser"=>1, "CoilWaterHeatingAirToWaterHeatPumpWrapped"=>1, "FanOnOff"=>1, "OtherEquipment"=>2, "OtherEquipmentDefinition"=>2, "EnergyManagementSystemSensor"=>9, "EnergyManagementSystemActuator"=>7, "EnergyManagementSystemTrendVariable"=>3, "EnergyManagementSystemProgram"=>2, "EnergyManagementSystemProgramCallingManager"=>1, "OutputVariable"=>16} #"ScheduleRuleset"=>2, "ScheduleConstant"=>8, 
        expected_values = {"TankVolume"=>36, "Heater1Height"=>0.599, "Heater2Height"=>0.106, "TankU"=>1.35, "OnCycle"=>3, "OffCycle"=>3, "CondBottom"=>0.0712, "CondTop"=>0.458, "AirflowRate"=>0.0854, "Sensor1Height"=>0.669, "Sensor2Height"=>0.669, "Cap"=>1400, "COP"=>2.8, "SHR"=>0.88, "WBTemp"=>13.08, "FanEff"=>0.235}
        _test_measure(osm_geo_beds_loc, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 1)
    end
    
    def test_new_construction_80
        args_hash = {}
        args_hash["storage_tank_volume"] = "80"
        args_hash["max_temp"] = "110"
        args_hash["cap"] = "0.979"
        args_hash["cop"] = "2.4"
        args_hash["shr"] = "0.98"
        args_hash["airflow_rate"] = "480"
        args_hash["fan_power"] = "0.178"
        args_hash["parasitics"] = "8.5"
        args_hash["tank_ua"] = "4.0"
        expected_num_del_objects = {}
        expected_num_new_objects = {"WaterHeaterStratified"=>1, "PlantLoop"=>1, "PumpVariableSpeed"=>1, "WaterHeaterHeatPumpWrappedCondenser"=>1, "CoilWaterHeatingAirToWaterHeatPumpWrapped"=>1, "FanOnOff"=>1, "OtherEquipment"=>2, "OtherEquipmentDefinition"=>2, "EnergyManagementSystemSensor"=>6, "EnergyManagementSystemActuator"=>5, "EnergyManagementSystemTrendVariable"=>1, "EnergyManagementSystemProgram"=>2, "EnergyManagementSystemProgramCallingManager"=>1, "OutputVariable"=>16} #"ScheduleRuleset"=>2, "ScheduleConstant"=>5, 
        expected_values = {"TankVolume"=>72, "Heater1Height"=>1.131, "Heater2Height"=>0.333, "TankU"=>0.787, "OnCycle"=>8.5, "OffCycle"=>8.5, "CondBottom"=>0.01, "CondTop"=>0.865, "AirflowRate"=>0.226, "Sensor1Height"=>1.265, "Sensor2Height"=>0.466, "Cap"=>2349.6, "COP"=>2.4, "SHR"=>0.98, "WBTemp"=>13.08, "FanEff"=>0.172}
        _test_measure(osm_geo_beds_loc, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 1)
    end
  
    def test_new_construction_66
        args_hash = {}
        args_hash["storage_tank_volume"] = "66"
        args_hash["max_temp"] = "110"
        args_hash["cap"] = "0.979"
        args_hash["cop"] = "2.4"
        args_hash["shr"] = "0.98"
        args_hash["airflow_rate"] = "480"
        args_hash["fan_power"] = "0.178"
        args_hash["parasitics"] = "8.5"
        args_hash["tank_ua"] = "4.0"
        expected_num_del_objects = {}
        expected_num_new_objects = {"WaterHeaterStratified"=>1, "PlantLoop"=>1, "PumpVariableSpeed"=>1, "WaterHeaterHeatPumpWrappedCondenser"=>1, "CoilWaterHeatingAirToWaterHeatPumpWrapped"=>1, "FanOnOff"=>1, "OtherEquipment"=>2, "OtherEquipmentDefinition"=>2, "EnergyManagementSystemSensor"=>6, "EnergyManagementSystemActuator"=>5, "EnergyManagementSystemTrendVariable"=>1, "EnergyManagementSystemProgram"=>2, "EnergyManagementSystemProgramCallingManager"=>1, "OutputVariable"=>16} #"ScheduleRuleset"=>2, "ScheduleConstant"=>5, 
        expected_values = {"TankVolume"=>59.4, "Heater1Height"=>0.945, "Heater2Height"=>0.278, "TankU"=>0.926, "OnCycle"=>8.5, "OffCycle"=>8.5, "CondBottom"=>0.01, "CondTop"=>0.723, "AirflowRate"=>0.226, "Sensor1Height"=>1.056, "Sensor2Height"=>0.389, "Cap"=>2349.6, "COP"=>2.4, "SHR"=>0.98, "WBTemp"=>13.08, "FanEff"=>0.172}
        _test_measure(osm_geo_beds_loc, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 1)
    end
  
    def test_new_construction_50_living
        args_hash = {}
        args_hash["location"] = Constants.LivingZone
        expected_num_del_objects = {}
        expected_num_new_objects = {"WaterHeaterStratified"=>1, "PlantLoop"=>1, "PumpVariableSpeed"=>1, "WaterHeaterHeatPumpWrappedCondenser"=>1, "CoilWaterHeatingAirToWaterHeatPumpWrapped"=>1, "FanOnOff"=>1, "OtherEquipment"=>2, "OtherEquipmentDefinition"=>2, "EnergyManagementSystemSensor"=>9, "EnergyManagementSystemActuator"=>7, "EnergyManagementSystemTrendVariable"=>3, "EnergyManagementSystemProgram"=>2, "EnergyManagementSystemProgramCallingManager"=>1, "OutputVariable"=>16} #"ScheduleRuleset"=>2, "ScheduleConstant"=>8, 
        expected_values = {"TankVolume"=>45, "Heater1Height"=>0.732, "Heater2Height"=>0.129, "TankU"=>1.13, "OnCycle"=>3, "OffCycle"=>3, "CondBottom"=>0.0870, "CondTop"=>0.560, "AirflowRate"=>0.0854, "Sensor1Height"=>0.818, "Sensor2Height"=>0.818, "Cap"=>1400, "COP"=>2.8, "SHR"=>0.88, "WBTemp"=>13.08, "FanEff"=>0.235}
        model = _test_measure(osm_geo_beds_loc, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 1)
        _test_measure(osm_geo_beds_loc, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 1)
    end
    
    #def test_retrofit_replace_50_with_80 #TODO: replace 50 with 80 and vice versa, make sure EMS is ok
    #    args_hash = {}
    #    expected_num_del_objects = {}
    #    expected_num_new_objects = {"WaterHeaterStratified"=>1, "PlantLoop"=>1, "PumpVariableSpeed"=>1, "ScheduleRuleset"=>2, "ScheduleConstant"=>8, "WaterHeaterHeatPumpWrappedCondenser"=>1, "CoilWaterHeatingAirToWaterHeatPumpWrapped"=>1, "FanOnOff"=>1, "OtherEquipment"=>2, "OtherEquipmentDefinition"=>2, "EnergyManagementSystemSensor"=>9, "EnergyManagementSystemActuator"=>7, "EnergyManagementSystemTrendVariable"=>3, "EnergyManagementSystemProgram"=>2, "EnergyManagementSystemProgramCallingManager"=>1, "OutputVariable"=>16}
    #    expected_values = {"TankVolume"=>45, "Heater1Height"=>0.732, "Heater2Height"=>0.129, "TankU"=>1.13, "OnCycle"=>3, "OffCycle"=>3, "CondBottom"=>0.0870, "CondTop"=>0.560, "AirflowRate"=>0.0854, "Sensor1Height"=>0.818, "Sensor2Height"=>0.818, "Cap"=>1400, "COP"=>2.8, "SHR"=>0.88, "WBTemp"=>13.08, "FanEff"=>0.235}
    #    model = _test_measure(osm_geo_beds_loc, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 1)
    #    args_hash = {}
    #    args_hash["storage_tank_volume"] = "80"
    #    args_hash["max_temp"] = "110"
    #    args_hash["cap"] = "0.979"
    #    args_hash["cop"] = "2.4"
    #    args_hash["shr"] = "0.98"
    #    args_hash["airflow_rate"] = "480"
    #    args_hash["fan_power"] = "0.178"
    #    args_hash["parasitics"] = "8.5"
    #    args_hash["tank_ua"] = "4.0"
    #    expected_num_del_objects = {"WaterHeaterStratified"=>1,"ScheduleRuleset"=>1, "ScheduleConstant"=>8, "WaterHeaterHeatPumpWrappedCondenser"=>1, "CoilWaterHeatingAirToWaterHeatPumpWrapped"=>1, "FanOnOff"=>1, "OtherEquipment"=>2, "OtherEquipmentDefinition"=>2, "EnergyManagementSystemSensor"=>9, "EnergyManagementSystemActuator"=>7, "EnergyManagementSystemTrendVariable"=>3, "EnergyManagementSystemProgram"=>2, "EnergyManagementSystemProgramCallingManager"=>1, "OutputVariable"=>16}
    #    expected_num_new_objects = {"WaterHeaterStratified"=>1, "ScheduleRuleset"=>2, "ScheduleConstant"=>5, "WaterHeaterHeatPumpWrappedCondenser"=>1, "CoilWaterHeatingAirToWaterHeatPumpWrapped"=>1, "FanOnOff"=>1, "OtherEquipment"=>2, "OtherEquipmentDefinition"=>2, "EnergyManagementSystemSensor"=>6, "EnergyManagementSystemActuator"=>5, "EnergyManagementSystemTrendVariable"=>1, "EnergyManagementSystemProgram"=>2, "EnergyManagementSystemProgramCallingManager"=>1, "OutputVariable"=>16}
    #    expected_values = {"TankVolume"=>72, "Heater1Height"=>1.131, "Heater2Height"=>0.333, "TankU"=>0.787, "OnCycle"=>8.5, "OffCycle"=>8.5, "CondBottom"=>0.01, "CondTop"=>0.865, "AirflowRate"=>0.226, "Sensor1Height"=>1.265, "Sensor2Height"=>0.466, "Cap"=>2349.6, "COP"=>2.4, "SHR"=>0.98, "WBTemp"=>13.08, "FanEff"=>0.172}
    #    _test_measure(model, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 2)
    #end
    
    #def test_retrofit_replace_tank_electric
    #    args_hash = {}
    #    expected_num_del_objects = {"WaterHeaterMixed"=>1, "ScheduleRuleset"=>1}
    #    expected_num_new_objects = {"WaterHeaterStratified"=>1, "ScheduleRuleset"=>1, "ScheduleConstant"=>8, "WaterHeaterHeatPumpWrappedCondenser"=>1, "CoilWaterHeatingAirToWaterHeatPumpWrapped"=>1, "FanOnOff"=>1, "OtherEquipment"=>2, "OtherEquipmentDefinition"=>2, "EnergyManagementSystemSensor"=>9, "EnergyManagementSystemActuator"=>7, "EnergyManagementSystemTrendVariable"=>3, "EnergyManagementSystemProgram"=>2, "EnergyManagementSystemProgramCallingManager"=>1, "OutputVariable"=>9}
    #    expected_values = {"TankVolume"=>45, "Heater1Height"=>0.732, "Heater2Height"=>0.129, "TankU"=>1.13, "OnCycle"=>3, "OffCycle"=>3, "CondBottom"=>0.0870, "CondTop"=>0.560, "AirflowRate"=>0.0854, "Sensor1Height"=>0.818, "Sensor2Height"=>0.818, "Cap"=>1400, "COP"=>2.8, "SHR"=>0.88, "WBTemp"=>13.08, "FanEff"=>0.235}
    #    _test_measure(osm_geo_beds_loc_tank_elec, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 3)
    #end
  
    #def test_retrofit_replace_tank_gas
    #    args_hash = {}
    #    expected_num_del_objects = {"WaterHeaterMixed"=>1, "ScheduleRuleset"=>1}
    #    expected_num_new_objects = {"WaterHeaterStratified"=>1,"ScheduleRuleset"=>1, "ScheduleConstant"=>8, "WaterHeaterHeatPumpWrappedCondenser"=>1, "CoilWaterHeatingAirToWaterHeatPumpWrapped"=>1, "FanOnOff"=>1, "OtherEquipment"=>2, "OtherEquipmentDefinition"=>2, "EnergyManagementSystemSensor"=>9, "EnergyManagementSystemActuator"=>7, "EnergyManagementSystemTrendVariable"=>3, "EnergyManagementSystemProgram"=>2, "EnergyManagementSystemProgramCallingManager"=>1, "OutputVariable"=>9}
    #    expected_values = {"TankVolume"=>45, "Heater1Height"=>0.732, "Heater2Height"=>0.129, "TankU"=>1.13, "OnCycle"=>3, "OffCycle"=>3, "CondBottom"=>0.0870, "CondTop"=>0.560, "AirflowRate"=>0.0854, "Sensor1Height"=>0.818, "Sensor2Height"=>0.818, "Cap"=>1400, "COP"=>2.8, "SHR"=>0.88, "WBTemp"=>13.08, "FanEff"=>0.235}
    #    _test_measure(osm_geo_beds_loc_tank_gas, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 3)
    #end

    #def test_retrofit_replace_tank_oil
    #    args_hash = {}
    #    expected_num_del_objects = {"WaterHeaterMixed"=>1, "ScheduleRuleset"=>1}
    #    expected_num_new_objects = {"WaterHeaterStratified"=>1, "ScheduleRuleset"=>1, "ScheduleConstant"=>8, "WaterHeaterHeatPumpWrappedCondenser"=>1, "CoilWaterHeatingAirToWaterHeatPumpWrapped"=>1, "FanOnOff"=>1, "OtherEquipment"=>2, "OtherEquipmentDefinition"=>2, "EnergyManagementSystemSensor"=>9, "EnergyManagementSystemActuator"=>7, "EnergyManagementSystemTrendVariable"=>3, "EnergyManagementSystemProgram"=>2, "EnergyManagementSystemProgramCallingManager"=>1, "OutputVariable"=>9}
    #    expected_values = {"TankVolume"=>45, "Heater1Height"=>0.732, "Heater2Height"=>0.129, "TankU"=>1.13, "OnCycle"=>3, "OffCycle"=>3, "CondBottom"=>0.0870, "CondTop"=>0.560, "AirflowRate"=>0.0854, "Sensor1Height"=>0.818, "Sensor2Height"=>0.818, "Cap"=>1400, "COP"=>2.8, "SHR"=>0.88, "WBTemp"=>13.08, "FanEff"=>0.235}
    #    _test_measure(osm_geo_beds_loc_tank_oil, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 3)
    #end

    #def test_retrofit_replace_tank_propane
    #    args_hash = {}
    #    expected_num_del_objects = {"WaterHeaterMixed"=>1, "ScheduleRuleset"=>1}
    #    expected_num_new_objects = {"WaterHeaterStratified"=>1, "ScheduleRuleset"=>1, "ScheduleConstant"=>8, "WaterHeaterHeatPumpWrappedCondenser"=>1, "CoilWaterHeatingAirToWaterHeatPumpWrapped"=>1, "FanOnOff"=>1, "OtherEquipment"=>2, "OtherEquipmentDefinition"=>2, "EnergyManagementSystemSensor"=>9, "EnergyManagementSystemActuator"=>7, "EnergyManagementSystemTrendVariable"=>3, "EnergyManagementSystemProgram"=>2, "EnergyManagementSystemProgramCallingManager"=>1, "OutputVariable"=>9}
    #    expected_values = {"TankVolume"=>45, "Heater1Height"=>0.732, "Heater2Height"=>0.129, "TankU"=>1.13, "OnCycle"=>3, "OffCycle"=>3, "CondBottom"=>0.0870, "CondTop"=>0.560, "AirflowRate"=>0.0854, "Sensor1Height"=>0.818, "Sensor2Height"=>0.818, "Cap"=>1400, "COP"=>2.8, "SHR"=>0.88, "WBTemp"=>13.08, "FanEff"=>0.235}
    #    _test_measure(osm_geo_beds_loc_tank_propane, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 3)
    #end

    #def test_retrofit_replace_tankless_electric
    #    args_hash = {}
    #    expected_num_del_objects = {"WaterHeaterMixed"=>1, "ScheduleRuleset"=>1}
    #    expected_num_new_objects = {"WaterHeaterStratified"=>1, "ScheduleRuleset"=>1, "ScheduleConstant"=>8, "WaterHeaterHeatPumpWrappedCondenser"=>1, "CoilWaterHeatingAirToWaterHeatPumpWrapped"=>1, "FanOnOff"=>1, "OtherEquipment"=>2, "OtherEquipmentDefinition"=>2, "EnergyManagementSystemSensor"=>9, "EnergyManagementSystemActuator"=>7, "EnergyManagementSystemTrendVariable"=>3, "EnergyManagementSystemProgram"=>2, "EnergyManagementSystemProgramCallingManager"=>1, "OutputVariable"=>9}
    #    expected_values = {"TankVolume"=>45, "Heater1Height"=>0.732, "Heater2Height"=>0.129, "TankU"=>1.13, "OnCycle"=>3, "OffCycle"=>3, "CondBottom"=>0.0870, "CondTop"=>0.560, "AirflowRate"=>0.0854, "Sensor1Height"=>0.818, "Sensor2Height"=>0.818, "Cap"=>1400, "COP"=>2.8, "SHR"=>0.88, "WBTemp"=>13.08, "FanEff"=>0.235}
    #    _test_measure(osm_geo_beds_loc_tankless_electric, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 3)
    #end

    #def test_retrofit_replace_tankless_gas
    #    args_hash = {}
    #    expected_num_del_objects = {"WaterHeaterMixed"=>1, "ScheduleRuleset"=>1}
    #    expected_num_new_objects = {"WaterHeaterStratified"=>1, "ScheduleRuleset"=>1, "ScheduleConstant"=>8, "WaterHeaterHeatPumpWrappedCondenser"=>1, "CoilWaterHeatingAirToWaterHeatPumpWrapped"=>1, "FanOnOff"=>1, "OtherEquipment"=>2, "OtherEquipmentDefinition"=>2, "EnergyManagementSystemSensor"=>9, "EnergyManagementSystemActuator"=>7, "EnergyManagementSystemTrendVariable"=>3, "EnergyManagementSystemProgram"=>2, "EnergyManagementSystemProgramCallingManager"=>1, "OutputVariable"=>9}
    #    expected_values = {"TankVolume"=>45, "Heater1Height"=>0.732, "Heater2Height"=>0.129, "TankU"=>1.13, "OnCycle"=>3, "OffCycle"=>3, "CondBottom"=>0.0870, "CondTop"=>0.560, "AirflowRate"=>0.0854, "Sensor1Height"=>0.818, "Sensor2Height"=>0.818, "Cap"=>1400, "COP"=>2.8, "SHR"=>0.88, "WBTemp"=>13.08, "FanEff"=>0.235}
    #    _test_measure(osm_geo_beds_loc_tankless_gas, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 3)
    #end

    #def test_retrofit_replace_tankless_propane
    #    args_hash = {}
    #    expected_num_del_objects = {"WaterHeaterMixed"=>1, "ScheduleRuleset"=>1}
    #    expected_num_new_objects = {"WaterHeaterStratified"=>1, "ScheduleRuleset"=>1, "ScheduleConstant"=>8, "WaterHeaterHeatPumpWrappedCondenser"=>1, "CoilWaterHeatingAirToWaterHeatPumpWrapped"=>1, "FanOnOff"=>1, "OtherEquipment"=>2, "OtherEquipmentDefinition"=>2, "EnergyManagementSystemSensor"=>9, "EnergyManagementSystemActuator"=>7, "EnergyManagementSystemTrendVariable"=>3, "EnergyManagementSystemProgram"=>2, "EnergyManagementSystemProgramCallingManager"=>1, "OutputVariable"=>9}
    #    expected_values = {"TankVolume"=>45, "Heater1Height"=>0.732, "Heater2Height"=>0.129, "TankU"=>1.13, "OnCycle"=>3, "OffCycle"=>3, "CondBottom"=>0.0870, "CondTop"=>0.560, "AirflowRate"=>0.0854, "Sensor1Height"=>0.818, "Sensor2Height"=>0.818, "Cap"=>1400, "COP"=>2.8, "SHR"=>0.88, "WBTemp"=>13.08, "FanEff"=>0.235}
    #    _test_measure(osm_geo_beds_loc_tankless_propane, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 3)
    #end

    def test_argument_error_tank_volume_lt_0
        args_hash = {}
        args_hash["storage_tank_volume"] = "-10"
        result = _test_error(osm_geo_beds_loc, args_hash)
        assert_equal(result.errors.map{ |x| x.logMessage }[0], "Storage tank volume must be greater than 0.")
    end

    def test_argument_error_tank_volume_eq_0
        args_hash = {}
        args_hash["storage_tank_volume"] = "0"
        result = _test_error(osm_geo_beds_loc, args_hash)
        assert_equal(result.errors.map{ |x| x.logMessage }[0], "Storage tank volume must be greater than 0.")
    end

    def test_argument_error_setpoint_lt_0
        args_hash = {}
        args_hash["dhw_setpoint_temperature"] = -10
        result = _test_error(osm_geo_beds_loc, args_hash)
        assert_equal(result.errors.map{ |x| x.logMessage }[0], "Hot water temperature must be greater than 0 and less than 212.")
    end

    def test_argument_error_setpoint_lg_300
        args_hash = {}
        args_hash["dhw_setpoint_temperature"] = 300
        result = _test_error(osm_geo_beds_loc, args_hash)
        assert_equal(result.errors.map{ |x| x.logMessage }[0], "Hot water temperature must be greater than 0 and less than 212.")
    end

    def test_argument_error_element_capacity_lt_0
        args_hash = {}
        args_hash["element_capacity"] = "-10"
        result = _test_error(osm_geo_beds_loc, args_hash)
        assert_equal(result.errors.map{ |x| x.logMessage }[0], "Element capacity must be greater than 0.")
    end
  
    def test_argument_error_min_temp_gt_80
        args_hash = {}
        args_hash["min_temp"] = "80"
        result = _test_error(osm_geo_beds_loc, args_hash)
        assert_equal(result.errors.map{ |x| x.logMessage }[0], "Minimum temperature will prevent HPWH from running, double check inputs.")
    end
  
    def test_argument_error_max_temp_lt_0
        args_hash = {}
        args_hash["max_temp"] = "0"
        result = _test_error(osm_geo_beds_loc, args_hash)
        assert_equal(result.errors.map{ |x| x.logMessage }[0], "Maximum temperature will prevent HPWH from running, double check inputs.")
    end
  
    def test_argument_error_cap_lt_0
        args_hash = {}
        args_hash["cap"] = "-1"
        result = _test_error(osm_geo_beds_loc, args_hash)
        assert_equal(result.errors.map{ |x| x.logMessage }[0], "Rated capacity must be greater than 0.")
    end
  
    def test_argument_error_cop_lt_0
        args_hash = {}
        args_hash["cop"] = "0"
        result = _test_error(osm_geo_beds_loc, args_hash)
        assert_equal(result.errors.map{ |x| x.logMessage }[0], "Rated COP must be greater than 0.")
    end
  
    def test_argument_error_shr_lt_0
        args_hash = {}
        args_hash["shr"] = "-1"
        result = _test_error(osm_geo_beds_loc, args_hash)
        assert_equal(result.errors.map{ |x| x.logMessage }[0], "Rated sensible heat ratio must be between 0 and 1.")
    end
  
    def test_argument_error_gt_1
        args_hash = {}
        args_hash["shr"] = "2"
        result = _test_error(osm_geo_beds_loc, args_hash)
        assert_equal(result.errors.map{ |x| x.logMessage }[0], "Rated sensible heat ratio must be between 0 and 1.")
    end
  
    def test_argument_error_fan_power_lt_0
        args_hash = {}
        args_hash["fan_power"] = "-1"
        result = _test_error(osm_geo_beds_loc, args_hash)
        assert_equal(result.errors.map{ |x| x.logMessage }[0], "Fan power must be greater than 0.")
    end
  
    def test_argument_error_parasitics_lt_0
        args_hash = {}
        args_hash["parasitics"] = "-1"
        result = _test_error(osm_geo_beds_loc, args_hash)
        assert_equal(result.errors.map{ |x| x.logMessage }[0], "Parasitics must be greater than 0.")
    end
  
    def test_argument_error_tank_ua_lt_0
        args_hash = {}
        args_hash["tank_ua"] = "-1"
        result = _test_error(osm_geo_beds_loc, args_hash)
        assert_equal(result.errors.map{ |x| x.logMessage }[0], "Tank UA must be greater than 0.")
    end
  
    def test_argument_error_int_factor_lt_0
        args_hash = {}
        args_hash["int_factor"] = "-1"
        result = _test_error(osm_geo_beds_loc, args_hash)
        assert_equal(result.errors.map{ |x| x.logMessage }[0], "Interaction factor must be between 0 and 1.")
    end
  
    def test_argument_error_int_factor_gt_1
        args_hash = {}
        args_hash["int_factor"] = "2"
        result = _test_error(osm_geo_beds_loc, args_hash)
        assert_equal(result.errors.map{ |x| x.logMessage }[0], "Interaction factor must be between 0 and 1.")
    end
  
    def test_argument_error_temp_depress_gt_0
        args_hash = {}
        args_hash["temp_depress"] = "-1"
        result = _test_error(osm_geo_beds_loc, args_hash)
        assert_equal(result.errors.map{ |x| x.logMessage }[0], "Temperature depression must be greater than 0.")
    end
  
    def test_error_missing_geometry
        args_hash = {}
        result = _test_error(nil, args_hash)
        assert_equal(result.errors.map{ |x| x.logMessage }[0], "No building geometry has been defined.")
    end
  
    def test_error_missing_beds
        args_hash = {}
        result = _test_error(osm_geo_loc, args_hash)
        assert_equal(result.errors.map{ |x| x.logMessage }[0], "Could not determine number of bedrooms or bathrooms. Run the 'Add Residential Bedrooms And Bathrooms' measure first.")
    end
  
    def test_error_missing_mains_temp
        args_hash = {}
        result = _test_error(osm_geo_beds, args_hash)
        assert_equal(result.errors.map{ |x| x.logMessage }[0], "Mains water temperature has not been set.")
    end
  
    #def test_single_family_attached_new_construction
    #    num_units = 4
    #    args_hash = {}
    #    expected_num_del_objects = {}
    #    expected_num_new_objects = {"WaterHeaterMixed"=>num_units, "PlantLoop"=>num_units, "PumpVariableSpeed"=>num_units, "ScheduleRuleset"=>2*num_units}
    #    expected_values = {"TankVolume"=>num_units*50, "InputCapacity"=>num_units*4.5, "ThermalEfficiency"=>num_units*1.0, "TankUA"=>num_units*2.21, "Setpoint"=>num_units*125, "OnCycle"=>0, "OffCycle"=>0}
    #    _test_measure("SFA_4units_1story_FB_UA_3Beds_2Baths_Denver.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, num_units)
    #end

    #def test_single_family_attached_new_construction_living_zone
    #    num_units = 4
    #    args_hash = {}
    #    args_hash["location"] = Constants.LivingZone
    #    expected_num_del_objects = {}
    #    expected_num_new_objects = {"WaterHeaterMixed"=>1, "PlantLoop"=>1, "PumpVariableSpeed"=>1, "ScheduleRuleset"=>2}
    #    expected_values = {"TankVolume"=>50, "InputCapacity"=>4.5, "ThermalEfficiency"=>1.0, "TankUA"=>2.21, "Setpoint"=>125, "OnCycle"=>0, "OffCycle"=>0}
    #    _test_measure("SFA_4units_1story_FB_UA_3Beds_2Baths_Denver.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 1)
    #end  
  
    #def test_multifamily_new_construction
    #    num_units = 8
    #    args_hash = {}
    #    expected_num_del_objects = {}
    #    expected_num_new_objects = {"WaterHeaterMixed"=>num_units, "PlantLoop"=>num_units, "PumpVariableSpeed"=>num_units, "ScheduleRuleset"=>2*num_units}
    #    expected_values = {"TankVolume"=>num_units*50, "InputCapacity"=>num_units*4.5, "ThermalEfficiency"=>num_units*1.0, "TankUA"=>num_units*2.21, "Setpoint"=>num_units*125, "OnCycle"=>0, "OffCycle"=>0}
    #    _test_measure("MF_8units_1story_SL_3Beds_2Baths_Denver.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, num_units)
    #end
  
    private
  
    def _test_error(osm_file, args_hash)
        # create an instance of the measure
        measure = ResidentialHotWaterHeaterHeatPump.new

        # create an instance of a runner
        runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)

        model = get_model(File.dirname(__FILE__), osm_file)

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

        # show the output
        #show_output(result)

        # assert that it didn't run
        assert_equal("Fail", result.value.valueName)
        assert(result.errors.size == 1)
        
        return result
    end

    def _test_measure(osm_file_or_model, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, num_infos=0, num_warnings=0)
        # create an instance of the measure
        measure = ResidentialHotWaterHeaterHeatPump.new

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

        # show the output
        #show_output(result)

        # assert that it ran correctly
        assert_equal("Success", result.value.valueName)
        assert(result.info.size == num_infos)
        assert(result.warnings.size == num_warnings)
        assert(result.finalCondition.is_initialized)
        
        # get the final objects in the model
        final_objects = get_objects(model)
        
        # get new and deleted objects
        obj_type_exclusions = ["ConnectorMixer", "ConnectorSplitter", "Node", "SetpointManagerScheduled", "ScheduleDay", "PipeAdiabatic", "ScheduleTypeLimits", "SizingPlant", "CurveBiquadratic", "CurveCubic", "CurveExponent", "ScheduleRuleset", "ScheduleConstant"]
        all_new_objects = get_object_additions(initial_objects, final_objects, obj_type_exclusions)
        all_del_objects = get_object_additions(final_objects, initial_objects, obj_type_exclusions)
        
        # check we have the expected number of new/deleted objects
        check_num_objects(all_new_objects, expected_num_new_objects, "added")
        check_num_objects(all_del_objects, expected_num_del_objects, "deleted")

        actual_values_wh = {"TankVolume"=>0, "Heater1Height"=>0, "Heater2Height"=>0, "TankU"=>0, "OnCycle"=>0, "OffCycle"=>0}
        actual_values_hpwh = {"CondBottom"=>0, "CondTop"=>0, "AirflowRate"=>0, "Sensor1Height"=>0, "Sensor2Height"=>0}
        actual_values_coil = {"Cap"=>0, "COP"=>0, "SHR"=>0, "WBTemp"=>0}
        actual_values_fan = {"FanEff"=>0}
        
        num_new_whs = 0
        all_new_objects.each do |obj_type, new_objects|
            new_objects.each do |new_object|
                next if not new_object.respond_to?("to_#{obj_type}")
                new_object = new_object.public_send("to_#{obj_type}").get
                if obj_type == "WaterHeaterStratified"
                    actual_values_wh["TankVolume"] += OpenStudio.convert(new_object.tankVolume.get, "m^3", "gal").get
                    actual_values_wh["Heater1Height"] += new_object.heater1Height
                    actual_values_wh["Heater2Height"] += new_object.heater2Height
                    actual_values_wh["TankU"] += new_object.uniformSkinLossCoefficientperUnitAreatoAmbientTemperature.to_f
                    actual_values_wh["OnCycle"] += new_object.onCycleParasiticFuelConsumptionRate
                    actual_values_wh["OffCycle"] += new_object.offCycleParasiticFuelConsumptionRate
                    num_new_whs += 1
                elsif obj_type == "WaterHeaterHeatPumpWrappedCondenser"
                    actual_values_hpwh["CondBottom"] += new_object.condenserBottomLocation
                    actual_values_hpwh["CondTop"] += new_object.condenserTopLocation
                    actual_values_hpwh["AirflowRate"] += new_object.evaporatorAirFlowRate.to_f
                    actual_values_hpwh["Sensor1Height"] += new_object.controlSensor1HeightInStratifiedTank.to_f
                    actual_values_hpwh["Sensor2Height"] += new_object.controlSensor2HeightInStratifiedTank.to_f
                elsif obj_type == "CoilWaterHeatingAirToWaterHeatPumpWrapped"
                    actual_values_coil["Cap"] += new_object.ratedHeatingCapacity
                    actual_values_coil["COP"] += new_object.ratedCOP
                    actual_values_coil["SHR"] += new_object.ratedSensibleHeatRatio
                    actual_values_coil["WBTemp"] += new_object.ratedEvaporatorInletAirWetBulbTemperature
                elsif obj_type == "FanOnOff"
                    actual_values_fan["FanEff"] += new_object.fanEfficiency
                #elsif obj_type == "EnergyManagementSystemSensor"
                #
                #elsif obj_type == "EnergyManagementSystemActuator"
                # 
                #elsif obj_type == "EnergyManagementSystemProgram"
                #    if line.start_with? "Set T_dep = "
                #        assert_in_epsilon(expected_values["",line.gsub("=","*").split(
                # 
                #elsif obj_type == "EnergyManagementSystemProgramCallingManager"
                #
                #elsif obj_type =="EnergyManagementSystemTrendVariable"
                #
                #elsif obj_type == "OutputVariable"
                end
            end
        end
        
        assert_in_epsilon(expected_values["TankVolume"], actual_values_wh["TankVolume"], 0.01)
        assert_in_epsilon(expected_values["Heater1Height"], actual_values_wh["Heater1Height"], 0.01)
        assert_in_epsilon(expected_values["Heater2Height"], actual_values_wh["Heater2Height"], 0.01)
        assert_in_epsilon(expected_values["TankU"], actual_values_wh["TankU"], 0.01)
        assert_in_epsilon(expected_values["OnCycle"], actual_values_wh["OnCycle"], 0.01)
        assert_in_epsilon(expected_values["OffCycle"], actual_values_wh["OffCycle"], 0.01)
        assert_in_epsilon(expected_values["CondBottom"], actual_values_hpwh["CondBottom"], 0.01)
        assert_in_epsilon(expected_values["CondTop"], actual_values_hpwh["CondTop"], 0.01)
        assert_in_epsilon(expected_values["AirflowRate"], actual_values_hpwh["AirflowRate"], 0.01)
        assert_in_epsilon(expected_values["Sensor1Height"], actual_values_hpwh["Sensor1Height"], 0.01)
        assert_in_epsilon(expected_values["Sensor2Height"], actual_values_hpwh["Sensor2Height"], 0.01)
        assert_in_epsilon(expected_values["Cap"], actual_values_coil["Cap"], 0.01)
        assert_in_epsilon(expected_values["COP"], actual_values_coil["COP"], 0.01)
        assert_in_epsilon(expected_values["SHR"], actual_values_coil["SHR"], 0.01)
        assert_in_epsilon(expected_values["WBTemp"], actual_values_coil["WBTemp"], 0.01)
        assert_in_epsilon(expected_values["FanEff"], actual_values_fan["FanEff"], 0.01)

        return model
    end
  
end
